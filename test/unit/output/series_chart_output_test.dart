// @orchestra-task: 8
// ignore_for_file: unnecessary_library_name
@Tags(['tdd-red'])
library;

import 'package:braven_data/src/output/chart_data_point.dart';
import 'package:braven_data/src/series.dart';
import 'package:test/test.dart';

void main() {
  group('SeriesChartOutput.toChartDataPoints', () {
    test('converts series values into chart points', () {
      final series = Series<double, double>.fromTypedData(
        meta: const SeriesMeta(name: 'Power', unit: 'W'),
        xValues: const [0.0, 1.0, 2.0],
        yValues: const [120.0, 130.0, 125.0],
      );

      final points = series.toChartDataPoints();

      expect(points, hasLength(3));
      expect(points[0].x, 0.0);
      expect(points[0].y, 120.0);
      expect(points[1].x, 1.0);
      expect(points[1].y, 130.0);
      expect(points[2].x, 2.0);
      expect(points[2].y, 125.0);
    });

    test('includeMinMax adds aggregated metadata to each point', () {
      const stats = SeriesStats(
        min: 100.0,
        max: 150.0,
        mean: 125.0,
        count: 3,
      );
      final series = Series<double, double>.fromTypedData(
        meta: const SeriesMeta(name: 'Power', unit: 'W'),
        xValues: const [0.0, 1.0, 2.0],
        yValues: const [120.0, 130.0, 125.0],
        stats: stats,
      );

      final points = series.toChartDataPoints(includeMinMax: true);

      for (final point in points) {
        expect(point.metadata, isNotNull);
        expect(point.metadata!['min'], stats.min);
        expect(point.metadata!['max'], stats.max);
        expect(point.metadata!['count'], stats.count);
      }
    });

    test('includeTimestamp attaches original DateTime values', () {
      final start = DateTime.utc(2025, 10, 26, 13, 23, 17);
      final timestamps = <DateTime>[
        start,
        start.add(const Duration(seconds: 1)),
        start.add(const Duration(seconds: 2)),
      ];
      final series = Series<DateTime, double>.fromTypedData(
        meta: const SeriesMeta(name: 'Power', unit: 'W'),
        xValues: timestamps,
        yValues: const [120.0, 130.0, 125.0],
      );

      final points = series.toChartDataPoints(includeTimestamp: true);

      expect(points[0].timestamp, timestamps[0]);
      expect(points[1].timestamp, timestamps[1]);
      expect(points[2].timestamp, timestamps[2]);
      expect(points[0].x, 0.0);
      expect(points[1].x, 1.0);
      expect(points[2].x, 2.0);
    });
  });
}
