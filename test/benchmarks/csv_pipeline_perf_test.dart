import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:braven_data/src/aggregation.dart';
import 'package:braven_data/src/csv/column_def.dart';
import 'package:braven_data/src/csv/delimited_schema.dart';
import 'package:braven_data/src/csv/field_type.dart';
import 'package:braven_data/src/csv/loader.dart';
import 'package:braven_data/src/csv/x_value_type.dart';
import 'package:braven_data/src/dataframe/dataframe.dart';
import 'package:braven_data/src/output/chart_data_point.dart';
import 'package:test/test.dart';

void main() {
  group('CSV pipeline performance', () {
    test('SC-001: load 10,000-row CSV + extract Series < 500ms', () {
      final schema = _schema();
      final csv = _buildCsv(rowCount: 10000);

      final stopwatch = Stopwatch()..start();
      final dataframe = DelimitedLoader.loadString(csv, schema);
      final series = dataframe.toSeries('power');
      stopwatch.stop();

      expect(series.length, 10000);
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    test('SC-002: full pipeline < 1 second for 3600 points', () {
      final schema = _schema();
      final csv = _buildCsv(rowCount: 3600);

      final stopwatch = Stopwatch()..start();
      final dataframe = DelimitedLoader.loadString(csv, schema);
      final series = dataframe.toSeries('power');
      final aggregated = series.aggregate(
        AggregationSpec<double>(
          window: WindowSpec.rollingDuration(const Duration(seconds: 30)),
          reducer: SeriesReducer.mean,
        ),
      );
      final points = aggregated.toChartDataPoints();
      stopwatch.stop();

      expect(points, isNotEmpty);
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('SC-003: memory usage ≤ 3x raw data size', () {
      const rowCount = 100000;
      const bytesPerValue = 8;
      const columnCount = 2;
      const rawValueBytes = rowCount * bytesPerValue * columnCount;

      final schema = _schema();
      final csv = _buildCsv(rowCount: rowCount);
      final csvBytes = utf8.encode(csv).length;
      final rawBytes = max(rawValueBytes, csvBytes);
      final allowedBytes = rawBytes * 3;

      final rssBefore = ProcessInfo.currentRss;
      final dataframe = DelimitedLoader.loadString(csv, schema);
      final series = dataframe.toSeries('power');
      final aggregated = series.aggregate(
        AggregationSpec<double>(
          window: WindowSpec.rollingDuration(const Duration(seconds: 30)),
          reducer: SeriesReducer.mean,
        ),
      );
      final points = aggregated.toChartDataPoints();
      final rssAfter = ProcessInfo.currentRss;

      expect(points, isNotEmpty);

      final delta = max(0, rssAfter - rssBefore);
      expect(delta, lessThanOrEqualTo(allowedBytes));
    });
  });
}

DelimitedSchema _schema() {
  return DelimitedSchema(
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
}

String _buildCsv({required int rowCount}) {
  final buffer = StringBuffer()..writeln('timestamp,power');
  final start = DateTime.utc(2025, 10, 26, 7, 32, 46);
  for (var i = 0; i < rowCount; i++) {
    final timestamp = _formatTimestamp(start.add(Duration(seconds: i)));
    final power = 150 + (i % 200);
    buffer.writeln('$timestamp,$power');
  }
  return buffer.toString();
}

String _formatTimestamp(DateTime value) {
  final date = _twoDigits(value.year, width: 4);
  final month = _twoDigits(value.month);
  final day = _twoDigits(value.day);
  final hour = _twoDigits(value.hour);
  final minute = _twoDigits(value.minute);
  final second = _twoDigits(value.second);
  return '$date-$month-${day}T$hour:$minute:$second+00:00';
}

String _twoDigits(int value, {int width = 2}) {
  return value.toString().padLeft(width, '0');
}
