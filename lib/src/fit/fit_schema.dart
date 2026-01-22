import '../csv/column_def.dart';
import '../csv/x_value_type.dart';
import '../schema/data_schema.dart';

/// FIT message types supported for extraction.
enum FitMessageType {
  records,
  laps,
  sessions,
}

/// Behavior when an explicit column is missing in the FIT file.
enum FitMissingColumnBehavior {
  skip,
  error,
}

/// Schema configuration for FIT extraction.
class FitSchema implements DataSchema {
  /// Explicit column definitions to apply.
  @override
  final List<ColumnDef> columns;

  /// Optional overrides for developer fields (type/unit hints).
  final List<ColumnDef> developerFields;

  /// Optional X column name used for series extraction (default: "timestamp").
  @override
  final String? xColumn;

  /// How to interpret X values (default: ISO 8601).
  @override
  final XValueType xType;

  /// How to handle missing explicit columns.
  final FitMissingColumnBehavior onMissingColumn;

  const FitSchema({
    this.columns = const [],
    this.developerFields = const [],
    this.xColumn = 'timestamp',
    this.xType = XValueType.iso8601,
    this.onMissingColumn = FitMissingColumnBehavior.skip,
  });
}
