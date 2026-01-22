import 'dart:math';

import 'package:braven_data/src/metrics/power_metrics.dart';
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

List<double> _simpleMovingAverage(List<double> values, int windowSize) {
  if (values.isEmpty) {
    return <double>[];
  }
  final result = <double>[];
  for (var i = 0; i < values.length; i++) {
    final start = max(0, i - windowSize + 1);
    var sum = 0.0;
    for (var j = start; j <= i; j++) {
      sum += values[j];
    }
    result.add(sum / (i - start + 1));
  }
  return result;
}

List<double> _ewma(List<double> values, double alpha) {
  if (values.isEmpty) {
    return <double>[];
  }
  final result = <double>[];
  var previous = values.first;
  result.add(previous);
  for (var i = 1; i < values.length; i++) {
    previous = alpha * values[i] + (1 - alpha) * previous;
    result.add(previous);
  }
  return result;
}

double _normalizedPowerReference(List<double> values, int windowSize) {
  if (values.isEmpty) {
    return 0.0;
  }
  final sma = _simpleMovingAverage(values, windowSize);
  final fourthPowers = sma.map((value) => pow(value, 4)).toList();
  final mean = fourthPowers.reduce((a, b) => a + b) / fourthPowers.length;
  return pow(mean, 0.25).toDouble();
}

double _xPowerReference(List<double> values, double alpha) {
  if (values.isEmpty) {
    return 0.0;
  }
  final smooth = _ewma(values, alpha);
  final fourthPowers = smooth.map((value) => pow(value, 4)).toList();
  final mean = fourthPowers.reduce((a, b) => a + b) / fourthPowers.length;
  return pow(mean, 0.25).toDouble();
}

void main() {
  group('NormalizedPowerMetric', () {
    test('returns 0.0 for empty series', () {
      final series = _seriesFrom([]);
      final metric = NormalizedPowerMetric();

      final result = metric.calculate(series);

      expect(result, 0.0);
    });

    test('matches reference algorithm for known dataset', () {
      final values = <double>[
        ...List<double>.filled(30, 100),
        ...List<double>.filled(30, 200),
      ];
      final series = _seriesFrom(values);
      final metric = NormalizedPowerMetric();
      final expected = _normalizedPowerReference(values, 30);

      final result = metric.calculate(series);

      expect(result, closeTo(expected, 1e-9));
    });

    test('constant power yields expected normalized power', () {
      final values = List<double>.filled(60, 200.0);
      final series = _seriesFrom(values);
      final metric = NormalizedPowerMetric();

      final result = metric.calculate(series);

      expect(result, closeTo(200.0, 1e-9));
    });
  });

  group('XPowerMetric', () {
    test('uses default alpha for 25s window', () {
      final metric = XPowerMetric();

      expect(metric.alpha, closeTo(1 / 26, 1e-12));
      expect(metric.windowSize, const Duration(seconds: 25));
    });

    test('returns 0.0 for empty series', () {
      final series = _seriesFrom([]);
      final metric = XPowerMetric();

      final result = metric.calculate(series);

      expect(result, 0.0);
    });

    test('matches reference algorithm for known dataset', () {
      final values = <double>[
        ...List<double>.filled(10, 100),
        ...List<double>.filled(10, 200),
        ...List<double>.filled(10, 300),
        ...List<double>.filled(10, 150),
        ...List<double>.filled(10, 250),
        ...List<double>.filled(10, 200),
      ];
      final series = _seriesFrom(values);
      final metric = XPowerMetric();
      final expected = _xPowerReference(values, 1 / 26);

      final result = metric.calculate(series);

      expect(result, closeTo(expected, 1e-9));
    });
  });

  group('VariabilityIndexMetric', () {
    test('returns 1.0 for constant power', () {
      final values = List<double>.filled(60, 200.0);
      final series = _seriesFrom(values);
      const metric = VariabilityIndexMetric();

      final result = metric.calculate(series);

      expect(result, closeTo(1.0, 1e-9));
    });
  });
}
