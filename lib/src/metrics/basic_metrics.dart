import '../series.dart';
import 'series_metric.dart';

class MeanMetric extends SeriesMetric<double> {
  const MeanMetric();

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

class MaxMetric extends SeriesMetric<double> {
  const MaxMetric();

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
