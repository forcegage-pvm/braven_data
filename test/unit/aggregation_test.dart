import 'package:braven_data/src/aggregation.dart';
import 'package:test/test.dart';

void main() {
  group('WindowSpec', () {
    test('creates fixed window with size', () {
      final spec = WindowSpec.fixed(30);

      expect(spec, isA<FixedWindowSpec>());
      expect((spec as FixedWindowSpec).size, 30);
    });

    test('creates rolling window with size', () {
      final spec = WindowSpec.rolling(15.5);

      expect(spec, isA<RollingWindowSpec>());
      expect((spec as RollingWindowSpec).size, 15.5);
    });

    test('creates pixel-aligned window with density', () {
      final spec = WindowSpec.pixelAligned(1.25);

      expect(spec, isA<PixelAlignedWindowSpec>());
      expect((spec as PixelAlignedWindowSpec).pixelDensity, 1.25);
    });

    test('throws for non-positive size', () {
      expect(() => WindowSpec.fixed(0), throwsArgumentError);
      expect(() => WindowSpec.rolling(-1), throwsArgumentError);
    });

    test('throws for invalid pixel density', () {
      expect(() => WindowSpec.pixelAligned(0), throwsArgumentError);
      expect(() => WindowSpec.pixelAligned(-2), throwsArgumentError);
      expect(() => WindowSpec.pixelAligned(double.nan), throwsArgumentError);
      expect(
        () => WindowSpec.pixelAligned(double.infinity),
        throwsArgumentError,
      );
    });
  });

  group('SeriesReducer', () {
    test('provides built-in reducers via static accessors', () {
      expect(SeriesReducer.mean, isA<MeanReducer>());
      expect(SeriesReducer.max, isA<MaxReducer>());
      expect(SeriesReducer.min, isA<MinReducer>());
      expect(SeriesReducer.sum, isA<SumReducer>());
    });

    test('mean reducer calculates arithmetic mean', () {
      final reducer = SeriesReducer.mean;

      expect(reducer.reduce([1.0, 3.0, 5.0]), 3.0);
      expect(reducer.reduce([2.0, 2.0]), 2.0);
    });

    test('max reducer selects maximum value', () {
      final reducer = SeriesReducer.max;

      expect(reducer.reduce([1.0, 7.5, 3.0]), 7.5);
      expect(reducer.reduce([-4.0, -2.0, -9.0]), -2.0);
    });

    test('min reducer selects minimum value', () {
      final reducer = SeriesReducer.min;

      expect(reducer.reduce([1.0, 7.5, 3.0]), 1.0);
      expect(reducer.reduce([-4.0, -2.0, -9.0]), -9.0);
    });

    test('sum reducer totals values', () {
      final reducer = SeriesReducer.sum;

      expect(reducer.reduce([1.0, 2.0, 3.0]), 6.0);
      expect(reducer.reduce([-1.5, 2.5]), 1.0);
    });

    test('reducers return single element unchanged', () {
      expect(SeriesReducer.mean.reduce([4.25]), 4.25);
      expect(SeriesReducer.max.reduce([4.25]), 4.25);
      expect(SeriesReducer.min.reduce([4.25]), 4.25);
      expect(SeriesReducer.sum.reduce([4.25]), 4.25);
    });

    test('reducers throw for empty input', () {
      expect(() => SeriesReducer.mean.reduce([]), throwsArgumentError);
      expect(() => SeriesReducer.max.reduce([]), throwsArgumentError);
      expect(() => SeriesReducer.min.reduce([]), throwsArgumentError);
      expect(() => SeriesReducer.sum.reduce([]), throwsArgumentError);
    });
  });

  group('AggregationSpec', () {
    test('stores window and reducer', () {
      final window = WindowSpec.fixed(10);
      final reducer = SeriesReducer.mean;

      final spec = AggregationSpec<int>(window: window, reducer: reducer);

      expect(spec.window, same(window));
      expect(spec.reducer, isA<MeanReducer>());
    });

    test('supports all window variants', () {
      final fixed = AggregationSpec<int>(
        window: WindowSpec.fixed(5),
        reducer: SeriesReducer.mean,
      );
      final rolling = AggregationSpec<int>(
        window: WindowSpec.rolling(2.5),
        reducer: SeriesReducer.max,
      );
      final pixelAligned = AggregationSpec<int>(
        window: WindowSpec.pixelAligned(1.5),
        reducer: SeriesReducer.min,
      );

      expect(fixed.window, isA<FixedWindowSpec>());
      expect(rolling.window, isA<RollingWindowSpec>());
      expect(pixelAligned.window, isA<PixelAlignedWindowSpec>());
    });

    test('supports built-in reducers', () {
      final mean = AggregationSpec<int>(
        window: WindowSpec.fixed(1),
        reducer: SeriesReducer.mean,
      );
      final max = AggregationSpec<int>(
        window: WindowSpec.fixed(1),
        reducer: SeriesReducer.max,
      );
      final min = AggregationSpec<int>(
        window: WindowSpec.fixed(1),
        reducer: SeriesReducer.min,
      );
      final sum = AggregationSpec<int>(
        window: WindowSpec.fixed(1),
        reducer: SeriesReducer.sum,
      );

      expect(mean.reducer, isA<MeanReducer>());
      expect(max.reducer, isA<MaxReducer>());
      expect(min.reducer, isA<MinReducer>());
      expect(sum.reducer, isA<SumReducer>());
    });
  });
}
