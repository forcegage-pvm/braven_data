import '../dataframe/dataframe.dart';
import 'column_def.dart';
import 'csv_schema.dart';
import 'field_type.dart';
import 'parser.dart';
import 'x_value_type.dart';

/// Loads CSV content into a [DataFrame] using a [CsvSchema].
class CsvLoader {
  static DataFrame loadString(String content, CsvSchema schema) {
    if (content.trim().isEmpty) {
      throw const FormatException('CSV content is empty');
    }

    final lines = CsvParser.splitLines(content);
    if (lines.isEmpty) {
      throw const FormatException('CSV content is empty');
    }

    var lineIndex = 0;
    List<String>? headers;

    if (schema.hasHeader) {
      headers = CsvParser.parseFields(lines.first, delimiter: schema.delimiter);
      lineIndex = 1;
      if (schema.xColumn != null && !headers.contains(schema.xColumn)) {
        throw ArgumentError('xColumn not found in headers');
      }
    }

    final columns = _initializeColumns(schema, headers);
    for (; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];
      if (line.isEmpty && lineIndex == lines.length - 1) {
        continue;
      }
      final fields = CsvParser.parseFields(line, delimiter: schema.delimiter);
      _processRow(fields, schema, headers, columns);
    }

    return DataFrame(columns, schema);
  }

  static Map<String, List<dynamic>> _initializeColumns(
    CsvSchema schema,
    List<String>? headers,
  ) {
    final columns = <String, List<dynamic>>{};

    if (schema.hasHeader) {
      if (headers == null) {
        return columns;
      }
      if (schema.xType != XValueType.rowIndex) {
        final xName = schema.xColumn;
        if (xName != null) {
          columns[xName] = <dynamic>[];
        }
      }
      for (final column in schema.columns) {
        if (headers.contains(column.name)) {
          columns[column.name] = <dynamic>[];
        }
      }
      return columns;
    }

    if (schema.xType != XValueType.rowIndex) {
      final xName = schema.xColumn;
      if (xName != null) {
        columns[xName] = <dynamic>[];
      }
    }
    for (final column in schema.columns) {
      columns[column.name] = <dynamic>[];
    }

    return columns;
  }

  static void _processRow(
    List<String> fields,
    CsvSchema schema,
    List<String>? headers,
    Map<String, List<dynamic>> columns,
  ) {
    if (schema.hasHeader) {
      if (headers == null) {
        throw const FormatException('Missing headers');
      }
      if (fields.length != headers.length) {
        throw const FormatException('Column count mismatch');
      }
      for (var i = 0; i < headers.length; i++) {
        final name = headers[i];
        final columnDef = _findColumnDef(schema, name);
        if (columnDef == null && name != schema.xColumn) {
          continue;
        }
        final value = _parseValue(fields[i], columnDef);
        if (columns.containsKey(name)) {
          columns[name]!.add(value);
        }
      }
      return;
    }

    final expectedCount = _expectedFieldCount(schema, fields.length);
    if (expectedCount != fields.length) {
      throw const FormatException('Column count mismatch');
    }

    var offset = 0;
    if (schema.xType == XValueType.rowIndex &&
        schema.xColumn == null &&
        fields.length == schema.columns.length + 1) {
      offset = 1;
    }

    var fieldIndex = 0;
    if (schema.xType != XValueType.rowIndex) {
      final xName = schema.xColumn;
      if (xName != null) {
        columns[xName]!.add(fields[fieldIndex]);
        fieldIndex++;
      }
    }

    for (final column in schema.columns) {
      final value = _parseValue(fields[fieldIndex + offset], column);
      columns[column.name]!.add(value);
      fieldIndex++;
    }
  }

  static int _expectedFieldCount(CsvSchema schema, int actual) {
    final baseCount = schema.columns.length +
        (schema.xType != XValueType.rowIndex && schema.xColumn != null ? 1 : 0);
    if (schema.xType == XValueType.rowIndex && schema.xColumn == null) {
      if (actual == baseCount || actual == baseCount + 1) {
        return actual;
      }
    }
    return baseCount;
  }

  static ColumnDef? _findColumnDef(CsvSchema schema, String name) {
    for (final column in schema.columns) {
      if (column.name == name) {
        return column;
      }
    }
    return null;
  }

  static dynamic _parseValue(String raw, ColumnDef? columnDef) {
    if (columnDef == null) {
      return raw;
    }
    if (raw.isEmpty) {
      if (columnDef.defaultValue != null) {
        return columnDef.defaultValue;
      }
      return null;
    }
    switch (columnDef.type) {
      case FieldType.float64:
        final parsed = double.tryParse(raw);
        return parsed ?? double.nan;
      case FieldType.int64:
        final parsed = int.tryParse(raw);
        if (parsed != null) {
          return parsed;
        }
        if (columnDef.defaultValue != null) {
          return columnDef.defaultValue;
        }
        throw FormatException('Invalid int value: $raw');
      case FieldType.string:
        return raw;
    }
  }
}
