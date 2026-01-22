import 'package:braven_data/src/metrics/series_metric.dart';
import 'package:braven_data/src/series.dart';
import 'package:test/test.dart';

class _LengthMetric extends SeriesMetric<double> {
  const _LengthMetric();

  @override
  double calculate(Series<dynamic, double> series) => series.length.toDouble();
}

class _StringMetric extends SeriesMetric<String> {
  const _StringMetric();

  @override
  String calculate(Series<dynamic, double> series) => 'ok';
}

class _CapturingMetric extends SeriesMetric<int> {
  Series<dynamic, double>? captured;

  @override
  int calculate(Series<dynamic, double> series) {
    captured = series;
    return series.length;
  }
}

Series<int, double> _seriesFrom(List<double> values) {
  final xValues = List<int>.generate(values.length, (index) => index);
  return Series<int, double>.fromTypedData(
    meta: const SeriesMeta(name: 'power', unit: 'W'),
    xValues: xValues,
    yValues: values,
  );
}

void main() {
  group('SeriesMetric contract', () {
    test('calculate accepts Series<dynamic, double>', () {
      final series = _seriesFrom([1, 2, 3]);
      final metric = _CapturingMetric();

      final result = metric.calculate(series);

      expect(result, 3);
      expect(metric.captured, same(series));
      expect(metric, isA<SeriesMetric<int>>());
    });

    test('compute returns generic result type', () {
      final series = _seriesFrom([10, 20]);
      const metric = _StringMetric();

      final result = series.compute(metric);

      expect(result, 'ok');
      expect(result, isA<String>());
    });
  });

  group('Custom metric extensibility (SC-005)', () {
    test('custom metric implements SeriesMetric and works with compute', () {
      final series = _seriesFrom([3, 6, 9, 12]);
      const metric = _LengthMetric();

      final result = series.compute(metric);

      expect(result, 4.0);
    });
  });
}
