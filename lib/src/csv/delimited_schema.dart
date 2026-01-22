import '../schema/data_schema.dart';
import 'column_def.dart';
import 'x_value_type.dart';

/// Describes how delimited text data should be parsed into columns.
class DelimitedSchema implements DataSchema {
  /// Column name for X values. Null when using row index.
  @override
  final String? xColumn;

  /// How to interpret X values.
  @override
  final XValueType xType;

  /// Optional format for custom X parsing.
  final String? xFormat;

  /// Column definitions for Y values.
  @override
  final List<ColumnDef> columns;

  /// Whether the first row contains headers.
  final bool hasHeader;

  /// Column delimiter character.
  final String delimiter;

  /// Creates a delimited schema that describes how to parse columns.
  ///
  /// Throws [ArgumentError] if [xType] requires an [xColumn] and none is
  /// provided, if no [columns] are defined, or if column names are not unique.
  DelimitedSchema({
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
