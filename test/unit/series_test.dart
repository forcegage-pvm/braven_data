import 'package:test/test.dart';

import 'package:braven_data/src/series.dart';
import 'package:braven_data/src/storage.dart';

void main() {
  group('SeriesMeta', () {
    test('stores name and optional unit', () {
      const meta = SeriesMeta(name: 'Altitude', unit: 'm');

      expect(meta.name, 'Altitude');
      expect(meta.unit, 'm');
    });

    test('allows a null unit for dimensionless data', () {
      const meta = SeriesMeta(name: 'Cadence');

      expect(meta.name, 'Cadence');
      expect(meta.unit, isNull);
    });
  });

  group('SeriesStats', () {
    test('stores summary statistics', () {
      const stats = SeriesStats(min: 1, max: 5, mean: 3, count: 4);

      expect(stats.min, 1);
      expect(stats.max, 5);
      expect(stats.mean, 3);
      expect(stats.count, 4);
    });

    test('accepts zero count values', () {
      const stats = SeriesStats(min: 0, max: 0, mean: 0, count: 0);

      expect(stats.count, 0);
    });
  });

  group('Series', () {
    test('delegates accessors and exposes properties', () {
      final storage = ListStorage<int, double>(
        xValues: [1, 2],
        yValues: [3.0, 4.0],
      );
      const meta = SeriesMeta(name: 'Altitude', unit: 'm');
      const stats = SeriesStats(min: 3, max: 4, mean: 3.5, count: 2);

      final series = Series<int, double>(
        id: 'series-1',
        meta: meta,
        storage: storage,
        stats: stats,
      );

      expect(series.id, 'series-1');
      expect(series.meta, meta);
      expect(series.stats, stats);
      expect(series.length, 2);
      expect(series.getX(0), 1);
      expect(series.getY(1), 4.0);
    });

    test('allows null stats for lazy computation', () {
      final storage = ListStorage<int, double>(
        xValues: [10],
        yValues: [20.0],
      );

      final series = Series<int, double>(
        id: 'series-2',
        meta: const SeriesMeta(name: 'Speed', unit: 'm/s'),
        storage: storage,
      );

      expect(series.stats, isNull);
    });

    test('validates runtime type compatibility for x values', () {
      final storage = ListStorage<int, double>(
        xValues: [1],
        yValues: [2.0],
      );

      expect(
        () => Series<double, double>(
          id: 'series-3',
          meta: const SeriesMeta(name: 'Elevation', unit: 'm'),
          storage: storage,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('validates runtime type compatibility for y values', () {
      final storage = ListStorage<int, int>(
        xValues: [1],
        yValues: [2],
      );

      expect(
        () => Series<int, double>(
          id: 'series-4',
          meta: const SeriesMeta(name: 'Count'),
          storage: storage,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
