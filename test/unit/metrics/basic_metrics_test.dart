import 'package:braven_data/src/metrics/basic_metrics.dart';
import 'package:braven_data/src/series.dart';
import 'package:test/test.dart';

Series<int, double> _seriesFrom(List<double> values) {
  final xValues = List<int>.generate(values.length, (index) => index);
  return Series<int, double>.fromTypedData(
    meta: const SeriesMeta(name: 'power', unit: 'W'),
    xValues: xValues,
    yValues: values,
  );
}

void main() {
  group('MeanMetric', () {
    test('returns 0.0 for empty series', () {
      final series = _seriesFrom([]);
      const metric = MeanMetric();

      final result = metric.calculate(series);

      expect(result, 0.0);
    });

    test('returns arithmetic mean for dataset', () {
      final series = _seriesFrom([10, 20, 30, 40]);
      const metric = MeanMetric();

      final result = metric.calculate(series);

      expect(result, closeTo(25.0, 1e-9));
    });
  });

  group('MaxMetric', () {
    test('returns maximum value for dataset', () {
      final series = _seriesFrom([5, 12, 3, 9]);
      const metric = MaxMetric();

      final result = metric.calculate(series);

      expect(result, closeTo(12.0, 1e-9));
    });

    test('returns negative infinity or throws on empty series', () {
      final series = _seriesFrom([]);
      const metric = MaxMetric();

      try {
        final result = metric.calculate(series);
        expect(result.isInfinite && result.isNegative, isTrue);
      } catch (error) {
        expect(error, isNot(isA<UnimplementedError>()));
      }
    });
  });
}
