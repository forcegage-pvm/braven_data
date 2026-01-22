import '../series.dart';
import 'series_metric.dart';

class MeanMetric extends SeriesMetric<double> {
  const MeanMetric();

  @override
  double calculate(Series<dynamic, double> series) {
    throw UnimplementedError('MeanMetric.calculate not implemented yet.');
  }
}

class MaxMetric extends SeriesMetric<double> {
  const MaxMetric();

  @override
  double calculate(Series<dynamic, double> series) {
    throw UnimplementedError('MaxMetric.calculate not implemented yet.');
  }
}
