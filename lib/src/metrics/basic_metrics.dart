import '../series.dart';
import 'series_metric.dart';

/// Computes the arithmetic mean of a series.
class MeanMetric extends SeriesMetric<double> {
  /// Creates a mean metric instance.
  const MeanMetric();

  /// Returns the mean value, or 0.0 when the series is empty.
  @override
  double calculate(Series<dynamic, double> series) {
    if (series.length == 0) {
      return 0.0;
    }

    var sum = 0.0;
    for (var i = 0; i < series.length; i++) {
      sum += series.getY(i);
    }
    return sum / series.length;
  }
}

/// Computes the maximum value in a series.
class MaxMetric extends SeriesMetric<double> {
  /// Creates a max metric instance.
  const MaxMetric();

  /// Returns the maximum value, or negative infinity when the series is empty.
  @override
  double calculate(Series<dynamic, double> series) {
    if (series.length == 0) {
      return double.negativeInfinity;
    }

    var maxValue = series.getY(0);
    for (var i = 1; i < series.length; i++) {
      final value = series.getY(i);
      if (value > maxValue) {
        maxValue = value;
      }
    }
    return maxValue;
  }
}
