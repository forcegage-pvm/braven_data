import 'dart:math' as math;

import 'aggregation.dart';
import 'pipeline.dart';
import 'series.dart';

/// Raises a value to the fourth power.
double pow4(double value) => math.pow(value, 4).toDouble();

/// Raises a value to the quarter power (fourth root).
double root4(double value) => math.pow(value, 0.25).toDouble();

/// Computes cycling Normalized Power (NP).
///
/// Algorithm: rolling 30s mean → power(4) → mean → power(0.25).
///
/// Example:
/// ```dart
/// final np = NormalizedPowerCalculator<int>(windowSize: 30).calculate(series);
/// ```
class NormalizedPowerCalculator<TX> {
  NormalizedPowerCalculator({this.windowSize = 30});

  final int windowSize;

  double calculate(Series<TX, double> series) {
    final pipeline = PipelineBuilder<TX, double>()
        .rolling(WindowSpec.rolling(windowSize), SeriesReducer.mean)
        .map(pow4)
        .collapse(SeriesReducer.mean);

    final meanPower4 = pipeline.executeScalar(series);
    return root4(meanPower4);
  }
}

/// Computes xPower using an exponential weighted moving average.
///
/// Algorithm: EWMA → power(4) → mean → power(0.25).
// ignore: camel_case_types
class xPowerCalculator<TX> {
  xPowerCalculator({
    this.windowSize = 25,
    double? alpha,
    double? timeConstantSeconds,
  })  : _alpha = alpha,
        _timeConstantSeconds = timeConstantSeconds;

  final int windowSize;
  final double? _alpha;
  final double? _timeConstantSeconds;

  double calculate(Series<TX, double> series) {
    final alpha = _alpha ?? _alphaFromTimeConstant(_timeConstantSeconds ?? 25);
    final pipeline = PipelineBuilder<TX, double>()
        .rolling(
          WindowSpec.rolling(windowSize),
          ExponentialMeanReducer(alpha: alpha),
        )
        .map(pow4)
        .collapse(SeriesReducer.mean);

    final meanPower4 = pipeline.executeScalar(series);
    return root4(meanPower4);
  }
}

/// Computes Variability Index (VI) = Normalized Power / Average Power.
class VariabilityIndexCalculator<TX> {
  VariabilityIndexCalculator({this.windowSize = 30});

  final int windowSize;

  double calculate(Series<TX, double> series) {
    final normalizedPower =
        NormalizedPowerCalculator<TX>(windowSize: windowSize).calculate(series);
    final averagePower = PipelineBuilder<TX, double>()
        .collapse(SeriesReducer.mean)
        .executeScalar(series);

    if (averagePower == 0) {
      throw StateError('Average power is zero; VI is undefined.');
    }

    return normalizedPower / averagePower;
  }
}

/// Exponential weighted moving average reducer for rolling windows.
class ExponentialMeanReducer extends SeriesReducer<double> {
  ExponentialMeanReducer({required this.alpha}) {
    _validateAlpha(alpha);
  }

  final double alpha;

  @override
  double reduce(List<double> values) {
    if (values.isEmpty) {
      throw ArgumentError('values must not be empty.');
    }

    var current = values.first;
    for (var index = 1; index < values.length; index++) {
      final value = values[index];
      current += alpha * (value - current);
    }
    return current;
  }
}

double _alphaFromTimeConstant(double timeConstantSeconds) {
  if (timeConstantSeconds.isNaN ||
      timeConstantSeconds.isInfinite ||
      timeConstantSeconds <= 0) {
    throw ArgumentError('timeConstantSeconds must be a positive finite value.');
  }
  return 1 - math.exp(-1 / timeConstantSeconds);
}

void _validateAlpha(double alpha) {
  if (alpha.isNaN || alpha.isInfinite || alpha <= 0 || alpha > 1) {
    throw ArgumentError('alpha must be > 0 and <= 1.');
  }
}
