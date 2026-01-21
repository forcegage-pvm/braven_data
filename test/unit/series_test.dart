import 'dart:typed_data';

import 'package:braven_data/src/aggregation.dart';
import 'package:braven_data/src/series.dart';
import 'package:braven_data/src/storage.dart';
import 'package:test/test.dart';

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

  group('Series.fromTypedData', () {
    test('creates a series from typed data lists', () {
      final series = Series<int, double>.fromTypedData(
        meta: const SeriesMeta(name: 'Speed', unit: 'm/s'),
        xValues: Int64List.fromList([1, 2]),
        yValues: Float64List.fromList([3.0, 4.0]),
      );

      expect(series.length, 2);
      expect(series.getX(0), 1);
      expect(series.getY(1), 4.0);
      expect(series.stats, isNull);
    });

    test('uses a custom id when provided', () {
      final series = Series<int, double>.fromTypedData(
        id: 'custom-id',
        meta: const SeriesMeta(name: 'Cadence'),
        xValues: [1, 2],
        yValues: [90.0, 95.0],
      );

      expect(series.id, 'custom-id');
    });

    test('auto-generates a unique id when omitted', () {
      final seriesA = Series<int, double>.fromTypedData(
        meta: const SeriesMeta(name: 'Power', unit: 'w'),
        xValues: [1],
        yValues: [200.0],
      );
      final seriesB = Series<int, double>.fromTypedData(
        meta: const SeriesMeta(name: 'Power', unit: 'w'),
        xValues: [2],
        yValues: [220.0],
      );

      expect(seriesA.id, isNotEmpty);
      expect(seriesB.id, isNotEmpty);
      expect(seriesA.id, isNot(seriesB.id));
    });

    test('preserves provided stats', () {
      const stats = SeriesStats(min: 1, max: 3, mean: 2, count: 3);

      final series = Series<int, double>.fromTypedData(
        meta: const SeriesMeta(name: 'Elevation', unit: 'm'),
        xValues: [1, 2, 3],
        yValues: [1.0, 2.0, 3.0],
        stats: stats,
      );

      expect(series.stats, stats);
    });
  });

  group('Series.slice', () {
    test('returns a subset with start and end', () {
      final series = Series<int, double>(
        id: 'series-5',
        meta: const SeriesMeta(name: 'Speed', unit: 'm/s'),
        storage: ListStorage<int, double>(
          xValues: [1, 2, 3, 4],
          yValues: [10.0, 20.0, 30.0, 40.0],
        ),
      );

      final slice = series.slice(1, 3);

      expect(slice.id, isNot(series.id));
      expect(slice.meta, same(series.meta));
      expect(slice.stats, isNull);
      expect(slice.length, 2);
      expect(slice.getX(0), 2);
      expect(slice.getY(1), 30.0);
    });

    test('defaults end to length when omitted', () {
      final series = Series<int, double>(
        id: 'series-6',
        meta: const SeriesMeta(name: 'Cadence'),
        storage: ListStorage<int, double>(
          xValues: [1, 2, 3],
          yValues: [90.0, 95.0, 100.0],
        ),
      );

      final slice = series.slice(1);

      expect(slice.length, 2);
      expect(slice.getX(0), 2);
      expect(slice.getY(1), 100.0);
    });

    test('supports empty slice', () {
      final series = Series<int, double>(
        id: 'series-7',
        meta: const SeriesMeta(name: 'Power', unit: 'w'),
        storage: ListStorage<int, double>(
          xValues: [1, 2],
          yValues: [200.0, 220.0],
        ),
      );

      final slice = series.slice(1, 1);

      expect(slice.length, 0);
    });

    test('supports full slice', () {
      final series = Series<int, double>(
        id: 'series-8',
        meta: const SeriesMeta(name: 'Elevation', unit: 'm'),
        storage: ListStorage<int, double>(
          xValues: [1, 2, 3],
          yValues: [1.0, 2.0, 3.0],
        ),
      );

      final slice = series.slice(0, series.length);

      expect(slice.length, series.length);
      expect(slice.getX(2), 3);
      expect(slice.getY(0), 1.0);
    });

    test('throws RangeError for invalid bounds', () {
      final series = Series<int, double>(
        id: 'series-9',
        meta: const SeriesMeta(name: 'Heart Rate', unit: 'bpm'),
        storage: ListStorage<int, double>(
          xValues: [1, 2],
          yValues: [100.0, 110.0],
        ),
      );

      expect(() => series.slice(-1, 1), throwsA(isA<RangeError>()));
      expect(() => series.slice(0, 3), throwsA(isA<RangeError>()));
      expect(() => series.slice(2, 1), throwsA(isA<RangeError>()));
    });
  });

  group('Series.aggregate', () {
    test('aggregates fixed windows with mean reducer', () {
      final series = Series<int, double>(
        id: 'series-10',
        meta: const SeriesMeta(name: 'Speed', unit: 'm/s'),
        storage: ListStorage<int, double>(
          xValues: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
          yValues: [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0],
        ),
      );

      final aggregated = series.aggregate(
        AggregationSpec<int>(
          window: FixedWindowSpec(3),
          reducer: SeriesReducer.mean,
        ),
      );

      expect(aggregated.length, 4);
      expect(aggregated.getX(0), 1);
      expect(aggregated.getX(1), 4);
      expect(aggregated.getX(2), 7);
      expect(aggregated.getX(3), 10);
      expect(aggregated.getY(0), 2.0);
      expect(aggregated.getY(1), closeTo(5.0, 1e-9));
      expect(aggregated.getY(2), 8.0);
      expect(aggregated.getY(3), 10.0);
      expect(aggregated.meta, same(series.meta));
    });

    test('handles partial window with max reducer', () {
      final series = Series<int, double>(
        id: 'series-11',
        meta: const SeriesMeta(name: 'Power', unit: 'w'),
        storage: ListStorage<int, double>(
          xValues: [1, 2, 3, 4, 5],
          yValues: [100.0, 150.0, 120.0, 180.0, 160.0],
        ),
      );

      final aggregated = series.aggregate(
        AggregationSpec<int>(
          window: FixedWindowSpec(2),
          reducer: SeriesReducer.max,
        ),
      );

      expect(aggregated.length, 3);
      expect(aggregated.getX(0), 1);
      expect(aggregated.getX(1), 3);
      expect(aggregated.getX(2), 5);
      expect(aggregated.getY(0), 150.0);
      expect(aggregated.getY(1), 180.0);
      expect(aggregated.getY(2), 160.0);
    });
  });
}
