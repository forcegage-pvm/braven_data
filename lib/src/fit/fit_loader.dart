import 'dart:io';
import 'dart:typed_data';

import 'package:dart_fit_decoder/dart_fit_decoder.dart' as fit_decoder;

import '../csv/column_def.dart';
import '../csv/field_type.dart';
import '../csv/x_value_type.dart';
import '../dataframe/dataframe.dart';
import 'fit_schema.dart';

/// Loads FIT content into a [DataFrame] using [FitSchema].
class FitLoader {
  /// Load FIT content from bytes and return a DataFrame for the message type.
  static DataFrame loadBytes(
    Uint8List bytes,
    FitMessageType messageType, {
    FitSchema? schema,
  }) {
    final decoder = fit_decoder.FitDecoder(bytes);
    final fitFile = decoder.decode();

    final messages = _selectMessages(fitFile, messageType);
    final resolvedSchema = schema ?? const FitSchema();
    final columns = _buildColumns(messages, resolvedSchema, messageType);

    return DataFrame(columns, resolvedSchema);
  }

  /// Load FIT content from a file path and return a DataFrame for the message type.
  static Future<DataFrame> load(
    String path,
    FitMessageType messageType, {
    FitSchema? schema,
  }) async {
    final bytes = await File(path).readAsBytes();
    return loadBytes(bytes, messageType, schema: schema);
  }

  static List<fit_decoder.FitDataMessage> _selectMessages(
    fit_decoder.FitFile fitFile,
    FitMessageType messageType,
  ) {
    switch (messageType) {
      case FitMessageType.records:
        return fitFile.getRecordMessages();
      case FitMessageType.laps:
        return fitFile.getLapMessages();
      case FitMessageType.sessions:
        return fitFile.getSessionMessages();
    }
  }

  static Map<String, List<dynamic>> _buildColumns(
    List<fit_decoder.FitDataMessage> messages,
    FitSchema schema,
    FitMessageType messageType,
  ) {
    final explicit = _explicitColumnMap(schema);
    final columnDefs = <String, ColumnDef>{}..addAll(explicit);
    final discovered = <String>{};

    for (final message in messages) {
      for (final field in message.fields) {
        final name = field.name;
        if (name == null || name.isEmpty) {
          continue;
        }
        discovered.add(name);
        columnDefs.putIfAbsent(
          name,
          () => ColumnDef(
            name: name,
            type: _inferFieldType(field.baseType, field.scaledValue),
            unit: field.units,
          ),
        );
      }

      if (messageType == FitMessageType.records || message.developerFields.isNotEmpty) {
        for (final devField in message.developerFields) {
          final name = _developerFieldName(devField);
          if (name == null) {
            continue;
          }
          discovered.add(name);
          columnDefs.putIfAbsent(
            name,
            () => ColumnDef(
              name: name,
              type: _inferDeveloperFieldType(devField),
              unit: devField.units,
            ),
          );
        }
      }
    }

    final missing = explicit.keys.where((name) => !discovered.contains(name)).toList();
    if (missing.isNotEmpty && schema.onMissingColumn == FitMissingColumnBehavior.error) {
      throw ArgumentError('Missing columns in FIT file: ${missing.join(", ")}');
    }

    if (missing.isNotEmpty && schema.onMissingColumn == FitMissingColumnBehavior.skip) {
      for (final name in missing) {
        columnDefs.remove(name);
      }
    }

    final xColumn = schema.xColumn;
    if (xColumn != null) {
      columnDefs[xColumn] = ColumnDef(
        name: xColumn,
        type: _xColumnFieldType(schema.xType),
      );
    }

    final columns = <String, List<dynamic>>{};
    for (final name in columnDefs.keys) {
      columns[name] = <dynamic>[];
    }

    DateTime? lastTimestamp;
    for (final message in messages) {
      final values = message.toMap();
      final rawTimestamp = message.timestamp;
      if (schema.xColumn != null) {
        final resolvedTimestamp = rawTimestamp ?? lastTimestamp ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
        values[schema.xColumn!] = _normalizeTimestamp(schema.xType, resolvedTimestamp);
        if (rawTimestamp != null) {
          lastTimestamp = rawTimestamp;
        }
      }

      for (final entry in columns.entries) {
        final name = entry.key;
        final rawValue = values[name];
        final columnDef = columnDefs[name];
        entry.value.add(_normalizeValue(columnDef, rawValue));
      }
    }

    return columns;
  }

  static Map<String, ColumnDef> _explicitColumnMap(FitSchema schema) {
    final map = <String, ColumnDef>{};
    for (final column in schema.columns) {
      map[column.name] = column;
    }
    for (final column in schema.developerFields) {
      map[column.name] = column;
    }
    return map;
  }

  static String? _developerFieldName(fit_decoder.DeveloperField field) {
    if (field.name != null && field.name!.isNotEmpty) {
      return field.name;
    }
    return 'dev_field_${field.fieldNumber}_${field.developerDataIndex}';
  }

  static FieldType _inferFieldType(fit_decoder.FitBaseType baseType, dynamic value) {
    if (baseType.isString) {
      return FieldType.string;
    }
    if (value is double) {
      return FieldType.float64;
    }
    if (value is num) {
      return FieldType.int64;
    }
    return FieldType.string;
  }

  static FieldType _inferDeveloperFieldType(fit_decoder.DeveloperField field) {
    final baseType = fit_decoder.FitBaseTypes.getById(field.baseTypeId);
    if (baseType != null && baseType.isString) {
      return FieldType.string;
    }
    final value = field.scaledValue;
    if (value is double) {
      return FieldType.float64;
    }
    if (value is num) {
      return FieldType.int64;
    }
    return FieldType.string;
  }

  static dynamic _normalizeValue(ColumnDef? def, dynamic value) {
    if (def == null) {
      return value;
    }
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value.toIso8601String();
    }

    switch (def.type) {
      case FieldType.float64:
        if (value is num) {
          return value.toDouble();
        }
        return double.tryParse(value.toString());
      case FieldType.int64:
        if (value is num) {
          return value.toInt();
        }
        return int.tryParse(value.toString());
      case FieldType.string:
        return value.toString();
    }
  }

  static FieldType _xColumnFieldType(XValueType type) {
    switch (type) {
      case XValueType.iso8601:
        return FieldType.string;
      case XValueType.epochSeconds:
      case XValueType.epochMillis:
      case XValueType.elapsedSeconds:
      case XValueType.elapsedMillis:
      case XValueType.rowIndex:
      case XValueType.custom:
        return FieldType.float64;
    }
  }

  static dynamic _normalizeTimestamp(XValueType type, DateTime timestamp) {
    switch (type) {
      case XValueType.iso8601:
        return timestamp.toIso8601String();
      case XValueType.epochSeconds:
      case XValueType.elapsedSeconds:
        return timestamp.millisecondsSinceEpoch / 1000.0;
      case XValueType.epochMillis:
      case XValueType.elapsedMillis:
        return timestamp.millisecondsSinceEpoch.toDouble();
      case XValueType.rowIndex:
        return null;
      case XValueType.custom:
        return timestamp.toIso8601String();
    }
  }
}
