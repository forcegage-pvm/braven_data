import '../series.dart';
import 'series_metric.dart';

class NormalizedPowerMetric extends SeriesMetric<double> {
  NormalizedPowerMetric({this.windowSize = const Duration(seconds: 30)});

  final Duration windowSize;

  @override
  double calculate(Series<dynamic, double> series) {
    throw UnimplementedError(
        'NormalizedPowerMetric.calculate not implemented yet.');
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
    throw UnimplementedError('XPowerMetric.calculate not implemented yet.');
  }
}

class VariabilityIndexMetric extends SeriesMetric<double> {
  const VariabilityIndexMetric();

  @override
  double calculate(Series<dynamic, double> series) {
    throw UnimplementedError(
        'VariabilityIndexMetric.calculate not implemented yet.');
  }
}
