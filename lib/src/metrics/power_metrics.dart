import '../algorithms.dart';
import '../series.dart';
import 'series_metric.dart';

class NormalizedPowerMetric extends SeriesMetric<double> {
  NormalizedPowerMetric({this.windowSize = const Duration(seconds: 30)});

  final Duration windowSize;

  @override
  double calculate(Series<dynamic, double> series) {
    if (series.length == 0) {
      return 0.0;
    }

    final sampleWindow = windowSize.inSeconds;
    if (sampleWindow <= 0) {
      throw ArgumentError('windowSize must be at least 1 second.');
    }

    final rollingMeans = <double>[];
    for (var index = 0; index < series.length; index++) {
      final start = (index - sampleWindow + 1).clamp(0, index);
      var sum = 0.0;
      for (var i = start; i <= index; i++) {
        sum += series.getY(i);
      }
      final count = index - start + 1;
      rollingMeans.add(sum / count);
    }

    var meanPower4 = 0.0;
    for (final value in rollingMeans) {
      meanPower4 += pow4(value);
    }
    meanPower4 /= rollingMeans.length;

    return root4(meanPower4);
  }
}

class XPowerMetric extends SeriesMetric<double> {
  XPowerMetric({
    this.windowSize = const Duration(seconds: 25),
    double? alpha,
  }) : alpha = alpha ?? 1 / (windowSize.inSeconds + 1);

  final Duration windowSize;
  final double alpha;

  @override
  double calculate(Series<dynamic, double> series) {
    if (series.length == 0) {
      return 0.0;
    }

    var previous = series.getY(0);
    final smoothed = <double>[previous];
    for (var i = 1; i < series.length; i++) {
      previous = alpha * series.getY(i) + (1 - alpha) * previous;
      smoothed.add(previous);
    }

    var meanPower4 = 0.0;
    for (final value in smoothed) {
      meanPower4 += pow4(value);
    }
    meanPower4 /= smoothed.length;

    return root4(meanPower4);
  }
}

class VariabilityIndexMetric extends SeriesMetric<double> {
  const VariabilityIndexMetric();

  @override
  double calculate(Series<dynamic, double> series) {
    if (series.length == 0) {
      return 0.0;
    }

    var sum = 0.0;
    for (var i = 0; i < series.length; i++) {
      sum += series.getY(i);
    }
    final averagePower = sum / series.length;
    if (averagePower == 0) {
      return 0.0;
    }

    final normalizedPower = NormalizedPowerMetric().calculate(series);
    return normalizedPower / averagePower;
  }
}
