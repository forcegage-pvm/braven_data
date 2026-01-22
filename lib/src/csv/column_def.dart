import 'field_type.dart';

/// Defines a Y-value column in CSV data.
class ColumnDef {
  /// Column name.
  final String name;

  /// Data type for column values.
  final FieldType type;

  /// Default value used when data is missing.
  final dynamic defaultValue;

  /// Optional unit annotation.
  final String? unit;

  ColumnDef({
    required this.name,
    required this.type,
    this.defaultValue,
    this.unit,
  }) {
    if (name.isEmpty) {
      throw ArgumentError('Column name cannot be empty');
    }

    if (!_isDefaultValueValid(type, defaultValue)) {
      throw ArgumentError('Default value type does not match FieldType');
    }
  }

  static bool _isDefaultValueValid(FieldType type, dynamic value) {
    if (value == null) {
      return true;
    }
    switch (type) {
      case FieldType.float64:
        return value is double;
      case FieldType.int64:
        return value is int;
      case FieldType.string:
        return value is String;
    }
  }
}
