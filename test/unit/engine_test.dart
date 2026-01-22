import 'package:braven_data/src/aggregation.dart';
import 'package:braven_data/src/engine.dart';
import 'package:braven_data/src/series.dart';
import 'package:braven_data/src/storage.dart';
import 'package:test/test.dart';

class RecordingReducer extends SeriesReducer<double> {
  const RecordingReducer(this.calls);

  final List<List<double>> calls;

  @override
  double reduce(List<double> values) {
    calls.add(List<double>.from(values));
    return values.first;
  }
}

void main() {
  group('AggregationEngine.aggregate', () {
    test('aggregates fixed windows with mean reducer', () {
      final series = Series<int, double>(
        id: 'series-1',
        meta: const SeriesMeta(name: 'Speed', unit: 'm/s'),
        storage: ListStorage<int, double>(
          xValues: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
          yValues: [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0],
        ),
      );

      final result = AggregationEngine.aggregate(
        series,
        AggregationSpec<int>(
          window: FixedWindowSpec(3),
          reducer: SeriesReducer.mean,
        ),
      );

      expect(result.xValues, [1, 4, 7, 10]);
      expect(
        result.yValues,
        [2.0, closeTo(5.0, 1e-9), 8.0, 10.0],
      );
    });

    test('handles partial window with max reducer', () {
      final series = Series<int, double>(
        id: 'series-2',
        meta: const SeriesMeta(name: 'Power', unit: 'w'),
        storage: ListStorage<int, double>(
          xValues: [1, 2, 3, 4, 5],
          yValues: [100.0, 150.0, 120.0, 180.0, 160.0],
        ),
      );

      final result = AggregationEngine.aggregate(
        series,
        AggregationSpec<int>(
          window: FixedWindowSpec(2),
          reducer: SeriesReducer.max,
        ),
      );

      expect(result.xValues, [1, 3, 5]);
      expect(result.yValues, [150.0, 180.0, 160.0]);
    });

    test('calls reducer with window values', () {
      final calls = <List<double>>[];
      final series = Series<int, double>(
        id: 'series-3',
        meta: const SeriesMeta(name: 'Cadence'),
        storage: ListStorage<int, double>(
          xValues: [1, 2, 3, 4],
          yValues: [90.0, 95.0, 100.0, 105.0],
        ),
      );

      final result = AggregationEngine.aggregate(
        series,
        AggregationSpec<int>(
          window: FixedWindowSpec(2),
          reducer: RecordingReducer(calls),
        ),
      );

      expect(result.xValues, [1, 3]);
      expect(result.yValues, [90.0, 100.0]);
      expect(
        calls,
        [
          [90.0, 95.0],
          [100.0, 105.0],
        ],
      );
    });

    test('throws for non-fixed window spec', () {
      final series = Series<int, double>(
        id: 'series-4',
        meta: const SeriesMeta(name: 'Elevation', unit: 'm'),
        storage: ListStorage<int, double>(
          xValues: [1, 2, 3],
          yValues: [1.0, 2.0, 3.0],
        ),
      );

      expect(
        () => AggregationEngine.aggregate(
          series,
          AggregationSpec<int>(
            window: RollingWindowSpec(2),
            reducer: SeriesReducer.mean,
          ),
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('throws for non-integer window size', () {
      final series = Series<int, double>(
        id: 'series-5',
        meta: const SeriesMeta(name: 'Speed', unit: 'm/s'),
        storage: ListStorage<int, double>(
          xValues: [1, 2, 3],
          yValues: [1.0, 2.0, 3.0],
        ),
      );

      expect(
        () => AggregationEngine.aggregate(
          series,
          AggregationSpec<int>(
            window: FixedWindowSpec(2.5),
            reducer: SeriesReducer.mean,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws for non-positive window size', () {
      final series = Series<int, double>(
        id: 'series-6',
        meta: const SeriesMeta(name: 'Heart Rate', unit: 'bpm'),
        storage: ListStorage<int, double>(
          xValues: [1, 2, 3],
          yValues: [100.0, 110.0, 120.0],
        ),
      );

      expect(
        () => AggregationEngine.aggregate(
          series,
          AggregationSpec<int>(
            window: FixedWindowSpec(0),
            reducer: SeriesReducer.mean,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
