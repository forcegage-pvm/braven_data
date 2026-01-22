import '../csv/column_def.dart';
import '../csv/x_value_type.dart';

/// Base interface for data schemas used by DataFrame.
abstract class DataSchema {
  /// Column name for X values. Null when using row index.
  String? get xColumn;

  /// How to interpret X values.
  XValueType get xType;

  /// Column definitions for Y values.
  List<ColumnDef> get columns;
}
