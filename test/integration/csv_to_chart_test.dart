import 'dart:io';

import 'package:braven_data/src/aggregation.dart';
import 'package:braven_data/src/csv/column_def.dart';
import 'package:braven_data/src/csv/csv_schema.dart';
import 'package:braven_data/src/csv/field_type.dart';
import 'package:braven_data/src/csv/loader.dart';
import 'package:braven_data/src/csv/x_value_type.dart';
import 'package:braven_data/src/dataframe/dataframe.dart';
import 'package:braven_data/src/output/chart_data_point.dart';
import 'package:braven_data/src/series.dart';
import 'package:test/test.dart';

void main() {
  group('CSV to chart integration', () {
    test('loads Garmin CSV and produces chart-ready output', () {
      final csvFile = _findGarminCsvFile();
      final content = csvFile.readAsStringSync();

      final schema = CsvSchema(
        hasHeader: true,
        delimiter: ',',
        xColumn: 'timestamp',
        xType: XValueType.iso8601,
        columns: <ColumnDef>[
          ColumnDef(
            name: 'power',
            type: FieldType.float64,
            defaultValue: 0.0,
            unit: 'watts',
          ),
        ],
      );

      final dataframe = CsvLoader.loadString(content, schema);
      final series = dataframe.toSeries(
        'power',
        meta: const SeriesMeta(name: 'power', unit: 'watts'),
      );

      final aggregated = series.aggregate(
        AggregationSpec<double>(
          window: WindowSpec.rollingDuration(const Duration(seconds: 30)),
          reducer: SeriesReducer.mean,
        ),
      );

      final points = aggregated.toChartDataPoints(includeMinMax: true);

      expect(points, isNotEmpty);
      expect(points.length, aggregated.length);
      expect(aggregated.length, greaterThan(0));
      expect(aggregated.length, lessThanOrEqualTo(series.length));
      for (var i = 0; i < points.length; i++) {
        final point = points[i];
        expect(point.isValid, isTrue);
        if (i > 0) {
          expect(point.x, greaterThan(points[i - 1].x));
        }
      }
    });
  });
}

File _findGarminCsvFile() {
  final dataDir = Directory('specs/_base/002-data-enchancements/data');
  if (!dataDir.existsSync()) {
    fail('Garmin sample data directory not found: ${dataDir.path}');
  }

  final csvFiles = dataDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.toLowerCase().endsWith('.csv'))
      .toList();

  if (csvFiles.isEmpty) {
    fail('No Garmin CSV files found under ${dataDir.path}');
  }

  return csvFiles.first;
}
