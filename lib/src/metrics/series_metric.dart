import '../series.dart';

/// Abstract interface for computing scalar values from a Series.
abstract class SeriesMetric<T> {
  const SeriesMetric();

  T calculate(Series<dynamic, double> series);
}

/// Extension method for convenient computation.
extension SeriesMetricCompute<TX> on Series<TX, double> {
  T compute<T>(SeriesMetric<T> metric) => metric.calculate(this);
}
