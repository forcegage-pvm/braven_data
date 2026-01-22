import '../csv/column_def.dart';
import '../csv/csv_schema.dart';
import '../csv/x_value_parser.dart';
import '../csv/x_value_type.dart';
import '../series.dart';

/// Columnar data container derived from CSV inputs.
class DataFrame {
  DataFrame(Map<String, List<dynamic>> columns, this.schema)
      : columns = Map<String, List<dynamic>>.unmodifiable(columns);

  final Map<String, List<dynamic>> columns;
  final CsvSchema schema;

  int get rowCount => columns.isEmpty ? 0 : columns.values.first.length;

  List<String> get columnNames => columns.keys.toList(growable: false);

  List<T> get<T>(String columnName) {
    final column = columns[columnName];
    if (column == null) {
      throw ArgumentError('Unknown column: $columnName');
    }
    return List<T>.from(column);
  }

  List<double> getXValues() {
    if (schema.xType == XValueType.rowIndex) {
      return List<double>.generate(rowCount, (index) => index.toDouble());
    }
    final xColumn = schema.xColumn;
    if (xColumn == null) {
      throw ArgumentError('xColumn required when xType is not rowIndex');
    }
    final values = get<dynamic>(xColumn)
        .map((value) => value.toString())
        .toList(growable: false);
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
