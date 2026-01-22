import '../csv/column_def.dart';
import '../csv/csv_schema.dart';
import '../csv/x_value_parser.dart';
import '../csv/x_value_type.dart';
import '../series.dart';

/// Columnar data container derived from CSV inputs.
class DataFrame {
  DataFrame(Map<String, List<dynamic>> columns, this.schema) : columns = Map<String, List<dynamic>>.unmodifiable(columns);

  final Map<String, List<dynamic>> columns;
  final CsvSchema schema;

  /// The number of rows in this dataframe.
  int get rowCount => columns.isEmpty ? 0 : columns.values.first.length;

  /// The names of all columns in this dataframe.
  List<String> get columnNames => columns.keys.toList(growable: false);

  /// Returns the data for [columnName] as a typed list.
  ///
  /// Throws [ArgumentError] if [columnName] does not exist.
  List<T> get<T>(String columnName) {
    final column = columns[columnName];
    if (column == null) {
      throw ArgumentError('Unknown column: $columnName');
    }
    return List<T>.from(column);
  }

  /// Returns the parsed X values based on the schema's X-value configuration.
  ///
  /// If `xType` is [XValueType.rowIndex], returns sequential indices.
  /// Otherwise, parses the X column according to the schema's `xType`.
  ///
  /// Throws [ArgumentError] if `xColumn` is required but not set.
  List<double> getXValues() {
    if (schema.xType == XValueType.rowIndex) {
      return List<double>.generate(rowCount, (index) => index.toDouble());
    }
    final xColumn = schema.xColumn;
    if (xColumn == null) {
      throw ArgumentError('xColumn required when xType is not rowIndex');
    }
    final values = get<dynamic>(xColumn).map((value) => value.toString()).toList(growable: false);
    return XValueParser.parseColumn(values, schema.xType);
  }
}

extension DataFrameSeriesExtraction on DataFrame {
  /// Extracts a series from this dataframe.
  Series<double, double> toSeries(String yColumn, {SeriesMeta? meta}) {
    final column = columns[yColumn];
    if (column == null) {
      throw ArgumentError('Unknown column: $yColumn');
    }

    final resolvedMeta = meta ?? _metaForColumn(yColumn);
    final xValues = getXValues();
    final yValues = List<double>.from(column);

    return Series<double, double>.fromTypedData(
      meta: resolvedMeta,
      xValues: xValues,
      yValues: yValues,
    );
  }

  SeriesMeta _metaForColumn(String columnName) {
    ColumnDef? matched;
    for (final column in schema.columns) {
      if (column.name == columnName) {
        matched = column;
        break;
      }
    }

    if (matched == null) {
      return SeriesMeta(name: columnName);
    }

    return SeriesMeta(name: columnName, unit: matched.unit);
  }
}
