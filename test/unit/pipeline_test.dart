import 'package:test/test.dart';

import 'package:braven_data/src/aggregation.dart';
import 'package:braven_data/src/pipeline.dart';
import 'package:braven_data/src/series.dart';

void main() {
  group('PipelineBuilder', () {
    test('supports fluent chaining', () {
      final pipeline = PipelineBuilder<int, double>()
          .map((value) => value + 1)
          .rolling(WindowSpec.fixed(2), SeriesReducer.mean)
          .collapse(SeriesReducer.sum);

      expect(pipeline, isA<Pipeline<int, double>>());
      expect(pipeline, isA<PipelineBuilder<int, double>>());
    });

    test('map transforms values', () {
      final series = _makeSeries([0, 1, 2], [1.0, 2.0, 3.0]);
      final pipeline = PipelineBuilder<int, double>().map((value) => value * 2);

      final result = pipeline.execute(series);

      expect(result.length, 3);
      expect(result.getX(0), 0);
      expect(result.getX(1), 1);
      expect(result.getX(2), 2);
      expect(result.getY(0), 2.0);
      expect(result.getY(1), 4.0);
      expect(result.getY(2), 6.0);
    });

    test('fixed rolling windows reduce values', () {
      final series = _makeSeries([0, 1, 2, 3, 4], [1, 2, 3, 4, 5]);
      final pipeline = PipelineBuilder<int, double>().rolling(
        WindowSpec.fixed(2),
        SeriesReducer.mean,
      );

      final result = pipeline.execute(series);

      expect(result.length, 3);
      expect(result.getX(0), 0);
      expect(result.getX(1), 2);
      expect(result.getX(2), 4);
      expect(result.getY(0), closeTo(1.5, 1e-9));
      expect(result.getY(1), closeTo(3.5, 1e-9));
      expect(result.getY(2), closeTo(5.0, 1e-9));
    });

    test('rolling windows slide across values', () {
      final series = _makeSeries([0, 1, 2, 3], [1, 2, 3, 4]);
      final pipeline = PipelineBuilder<int, double>().rolling(
        WindowSpec.rolling(3),
        SeriesReducer.sum,
      );

      final result = pipeline.execute(series);

      expect(result.length, 2);
      expect(result.getX(0), 0);
      expect(result.getX(1), 1);
      expect(result.getY(0), 6.0);
      expect(result.getY(1), 9.0);
    });

    test('collapse returns scalar value', () {
      final series = _makeSeries([0, 1, 2], [1, 2, 3]);
      final pipeline = PipelineBuilder<int, double>()
          .map((value) => value * 2)
          .collapse(SeriesReducer.sum);

      final result = pipeline.executeScalar(series);

      expect(result, 12.0);
    });

    test('executeScalar throws without collapse', () {
      final series = _makeSeries([0, 1], [1, 2]);
      final pipeline = PipelineBuilder<int, double>().map((value) => value + 1);

      expect(() => pipeline.executeScalar(series), throwsStateError);
    });

    test('rolling with non-integer window size throws', () {
      final series = _makeSeries([0, 1], [1, 2]);
      final pipeline = PipelineBuilder<int, double>().rolling(
        WindowSpec.fixed(1.5),
        SeriesReducer.sum,
      );

      expect(() => pipeline.execute(series), throwsArgumentError);
    });

    test('pixel aligned window is not supported', () {
      final series = _makeSeries([0, 1], [1, 2]);
      final pipeline = PipelineBuilder<int, double>().rolling(
        WindowSpec.pixelAligned(2.0),
        SeriesReducer.sum,
      );

      expect(() => pipeline.execute(series), throwsUnimplementedError);
    });
  });
}

Series<int, double> _makeSeries(List<int> xValues, List<num> yValues) {
  return Series<int, double>.fromTypedData(
    meta: const SeriesMeta(name: 'series'),
    xValues: xValues,
    yValues: yValues.map((value) => value.toDouble()).toList(),
    stats: null,
  );
}
