import 'package:braven_data/src/algorithms.dart';
import 'package:braven_data/src/series.dart';
import 'package:test/test.dart';

void main() {
  group('Domain algorithms', () {
    test('Normalized Power follows formula', () {
      final series = _makeSeries([0, 1, 2, 3], [100, 200, 300, 400]);
      final calculator = NormalizedPowerCalculator<int>(windowSize: 2);

      final result = calculator.calculate(series);

      final rollingMeans = _rollingMean(series, 2);
      final meanPower4 =
          _mean(rollingMeans.map((value) => pow4(value)).toList());
      final expected = root4(meanPower4);

      expect(result, closeTo(expected, 1e-9));
    });

    test('xPower uses exponential mean', () {
      final series = _makeSeries([0, 1, 2, 3], [100, 200, 300, 400]);
      final calculator = xPowerCalculator<int>(windowSize: 3, alpha: 0.5);

      final result = calculator.calculate(series);

      final windowed = _rollingWindows(series, 3);
      final ewmaValues = windowed.map((window) => _ewma(window, 0.5)).toList();
      final meanPower4 = _mean(ewmaValues.map(pow4).toList());
      final expected = root4(meanPower4);

      expect(result, closeTo(expected, 1e-9));
    });

    test('Variability Index is NP divided by average power', () {
      final series = _makeSeries([0, 1, 2, 3], [100, 200, 300, 400]);
      final calculator = VariabilityIndexCalculator<int>(windowSize: 2);

      final result = calculator.calculate(series);

      final rollingMeans = _rollingMean(series, 2);
      final meanPower4 =
          _mean(rollingMeans.map((value) => pow4(value)).toList());
      final normalizedPower = root4(meanPower4);
      final averagePower = _mean([100.0, 200.0, 300.0, 400.0]);
      final expected = normalizedPower / averagePower;

      expect(result, closeTo(expected, 1e-9));
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

List<double> _rollingMean(Series<int, double> series, int windowSize) {
  final values = <double>[];
  for (var start = 0; start + windowSize <= series.length; start++) {
    var sum = 0.0;
    for (var i = start; i < start + windowSize; i++) {
      sum += series.getY(i);
    }
    values.add(sum / windowSize);
  }
  return values;
}

List<List<double>> _rollingWindows(Series<int, double> series, int windowSize) {
  final windows = <List<double>>[];
  for (var start = 0; start + windowSize <= series.length; start++) {
    final window = <double>[];
    for (var i = start; i < start + windowSize; i++) {
      window.add(series.getY(i));
    }
    windows.add(window);
  }
  return windows;
}

double _ewma(List<double> values, double alpha) {
  var current = values.first;
  for (var index = 1; index < values.length; index++) {
    current += alpha * (values[index] - current);
  }
  return current;
}

double _mean(List<double> values) {
  var sum = 0.0;
  for (final value in values) {
    sum += value;
  }
  return sum / values.length;
}
