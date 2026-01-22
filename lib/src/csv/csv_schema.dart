import 'column_def.dart';
import 'x_value_type.dart';

/// Describes how CSV data should be parsed into columns.
class CsvSchema {
  /// Column name for X values. Null when using row index.
  final String? xColumn;

  /// How to interpret X values.
  final XValueType xType;

  /// Optional format for custom X parsing.
  final String? xFormat;

  /// Column definitions for Y values.
  final List<ColumnDef> columns;

  /// Whether the first row contains headers.
  final bool hasHeader;

  /// Column delimiter character.
  final String delimiter;

  CsvSchema({
    this.xColumn,
    required this.xType,
    this.xFormat,
    required List<ColumnDef> columns,
    this.hasHeader = true,
    this.delimiter = ',',
  }) : columns = List<ColumnDef>.unmodifiable(columns) {
    if (xType != XValueType.rowIndex && xColumn == null) {
      throw ArgumentError('xColumn required when xType is not rowIndex');
    }
    if (columns.isEmpty) {
      throw ArgumentError('At least one column definition required');
    }
    final names = <String>{};
    for (final column in columns) {
      if (!names.add(column.name)) {
        throw ArgumentError('Column names must be unique');
      }
    }
  }
}
