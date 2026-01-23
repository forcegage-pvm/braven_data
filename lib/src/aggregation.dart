import 'dart:math' as math;

import 'output/window_alignment.dart';
import 'series.dart';

/// Aggregation window specifications for downsampling and rendering.
sealed class WindowSpec {
  const WindowSpec._();

  /// Creates a non-overlapping fixed-size window with [size] points.
  factory WindowSpec.fixed(num size) => FixedWindowSpec(size);

  /// Creates a sliding window with [size] points that overlaps.
  factory WindowSpec.rolling(num size) => RollingWindowSpec(size);

  /// Creates a fixed-duration window based on time [duration].
  factory WindowSpec.fixedDuration(Duration duration) => FixedDurationWindowSpec(duration);

  /// Creates a rolling-duration window based on time [duration].
  factory WindowSpec.rollingDuration(Duration duration) => RollingDurationWindowSpec(duration);

  /// Creates a pixel-aligned window for rendering at [pixelDensity].
  factory WindowSpec.pixelAligned(double pixelDensity) => PixelAlignedWindowSpec(pixelDensity);
}

/// Reduces a list of values into a single value.
abstract class SeriesReducer<T> {
  const SeriesReducer();

  /// Reduces [values] to a single output value.
  ///
  /// Implementations may throw if [values] is empty or contains invalid data.
  T reduce(List<T> values);

  /// Built-in reducers for double values.
  static SeriesReducer<double> get mean => const MeanReducer();
  static SeriesReducer<double> get max => const MaxReducer();
  static SeriesReducer<double> get min => const MinReducer();
  static SeriesReducer<double> get sum => const SumReducer();
  static SeriesReducer<double> get normalizedPower => const NormalizedPowerReducer();

  /// Returns an xPower reducer with optional time constant or alpha.
  ///
  /// [alpha] is the smoothing factor (0 < alpha <= 1).
  /// [timeConstantSeconds] is used to calculate alpha if [alpha] is not provided.
  /// Standard xPower uses ~25s time constant.
  ///
  /// Since reducers are stateless with respect to window duration, [timeConstantSeconds]
  /// assumes a 1Hz sample rate roughly or you must provide the correct [alpha].
  static SeriesReducer<double> xPower({double? alpha, double timeConstantSeconds = 25.0}) {
    if (alpha != null) {
      return XPowerReducer(alpha: alpha);
    }
    final calculatedAlpha = 1.0 - math.exp(-1.0 / timeConstantSeconds);
    return XPowerReducer(alpha: calculatedAlpha);
  }
}

/// Configuration for aggregating a series.
///
/// Combines a windowing strategy with a reducer that collapses each window
/// into a single output value.
class AggregationSpec<TX> {
  const AggregationSpec({
    required this.window,
    required this.reducer,
    this.alignment = WindowAlignment.end,
  });

  /// The windowing strategy to apply.
  final WindowSpec window;

  /// The reducer function that collapses window values.
  final SeriesReducer<dynamic> reducer;

  /// The alignment strategy for window X values (default: end).
  final WindowAlignment alignment;
}

/// Non-overlapping fixed-size window.
///
/// Each window contains `size` consecutive points.
class FixedWindowSpec extends WindowSpec {
  FixedWindowSpec(this.size) : super._() {
    _validateSize(size, 'size');
  }

  /// Number of points per fixed window.
  final num size;
}

/// Sliding window that moves through data.
///
/// Each step advances by one element, producing overlapping windows.
class RollingWindowSpec extends WindowSpec {
  RollingWindowSpec(this.size) : super._() {
    _validateSize(size, 'size');
  }

  /// Number of points per rolling window.
  final num size;
}

/// Fixed-duration window based on time spans.
///
/// Converts a [duration] into a point count using inferred sample rate.
class FixedDurationWindowSpec extends WindowSpec {
  FixedDurationWindowSpec(this.duration) : super._() {
    _validateDuration(duration, 'duration');
  }

  /// Duration represented by each window.
  final Duration duration;

  /// Converts [duration] to a point count based on the series sample rate.
  int pointCountForSeries<TX, TY>(Series<TX, TY> series) {
    final sampleRate = inferredSampleRateHz(series);
    return _durationPointCount(duration, sampleRate);
  }

  /// Infers the sample rate (Hz) from the series X-value deltas.
  double inferredSampleRateHz<TX, TY>(Series<TX, TY> series) {
    return _inferSampleRateHz(series);
  }
}

/// Rolling-duration window based on time spans.
///
/// Converts a [duration] into a point count using inferred sample rate.
class RollingDurationWindowSpec extends WindowSpec {
  RollingDurationWindowSpec(this.duration) : super._() {
    _validateDuration(duration, 'duration');
  }

  /// Duration represented by each rolling window.
  final Duration duration;

  /// Converts [duration] to a point count based on the series sample rate.
  int pointCountForSeries<TX, TY>(Series<TX, TY> series) {
    final sampleRate = inferredSampleRateHz(series);
    return _durationPointCount(duration, sampleRate);
  }

  /// Infers the sample rate (Hz) from the series X-value deltas.
  double inferredSampleRateHz<TX, TY>(Series<TX, TY> series) {
    return _inferSampleRateHz(series);
  }
}

/// Pixel-aligned dynamic window for rendering.
///
/// This window size is derived from `pixelDensity` and is typically used for
/// visualization downsampling.
class PixelAlignedWindowSpec extends WindowSpec {
  PixelAlignedWindowSpec(this.pixelDensity) : super._() {
    if (pixelDensity.isNaN || pixelDensity.isInfinite || pixelDensity <= 0) {
      throw ArgumentError('pixelDensity must be a positive finite value.');
    }
  }

  /// Target pixel density used to derive window size.
  final double pixelDensity;
}

/// Arithmetic mean reducer for double values.
///
/// Throws an [ArgumentError] when [values] is empty.
class MeanReducer extends SeriesReducer<double> {
  const MeanReducer();

  @override
  double reduce(List<double> values) {
    _validateValues(values);
    if (values.length == 1) {
      return values.first;
    }

    var sum = 0.0;
    for (final value in values) {
      sum += value;
    }
    return sum / values.length;
  }
}

/// Maximum reducer for double values.
///
/// Returns the largest value in the window. Throws when [values] is empty.
class MaxReducer extends SeriesReducer<double> {
  const MaxReducer();

  @override
  double reduce(List<double> values) {
    _validateValues(values);
    if (values.length == 1) {
      return values.first;
    }

    var current = values.first;
    for (var index = 1; index < values.length; index++) {
      final value = values[index];
      if (value > current) {
        current = value;
      }
    }
    return current;
  }
}

/// Minimum reducer for double values.
///
/// Returns the smallest value in the window. Throws when [values] is empty.
class MinReducer extends SeriesReducer<double> {
  const MinReducer();

  @override
  double reduce(List<double> values) {
    _validateValues(values);
    if (values.length == 1) {
      return values.first;
    }

    var current = values.first;
    for (var index = 1; index < values.length; index++) {
      final value = values[index];
      if (value < current) {
        current = value;
      }
    }
    return current;
  }
}

/// Sum reducer for double values.
///
/// Returns the arithmetic sum of the window. Throws when [values] is empty.
class SumReducer extends SeriesReducer<double> {
  const SumReducer();

  @override
  double reduce(List<double> values) {
    _validateValues(values);
    if (values.length == 1) {
      return values.first;
    }

    var sum = 0.0;
    for (final value in values) {
      sum += value;
    }
    return sum;
  }
}

/// Normalized Power reducer.
///
/// Calculates (mean(values^4))^0.25. Skips NaN/Infinity.
class NormalizedPowerReducer extends SeriesReducer<double> {
  const NormalizedPowerReducer();

  @override
  double reduce(List<double> values) {
    if (values.isEmpty) {
      throw ArgumentError('values must not be empty.');
    }

    var sumPower4 = 0.0;
    var count = 0;
    for (final value in values) {
      if (!value.isNaN && !value.isInfinite) {
        sumPower4 += math.pow(value, 4).toDouble();
        count++;
      }
    }

    if (count == 0) {
      return double.nan;
    }

    return math.pow(sumPower4 / count, 0.25).toDouble();
  }
}

/// xPower reducer using Exponential Weighted Moving Average (EWMA).
///
/// Applies EWMA to the window values, then (mean(values^4))^0.25.
class XPowerReducer extends SeriesReducer<double> {
  const XPowerReducer({required this.alpha});

  final double alpha;

  @override
  double reduce(List<double> values) {
    if (values.isEmpty) {
      throw ArgumentError('values must not be empty.');
    }

    // Apply EWMA smoothing to the window
    var currentEwma = values.first;
    var sumPower4 = 0.0;
    var count = 0;

    // Treat first value as initial EWMA seed
    if (currentEwma.isFinite) {
      sumPower4 += math.pow(currentEwma, 4).toDouble();
      count++;
    }

    for (var i = 1; i < values.length; i++) {
      final val = values[i];
      if (val.isNaN || val.isInfinite) continue;

      currentEwma = alpha * val + (1 - alpha) * currentEwma;
      sumPower4 += math.pow(currentEwma, 4).toDouble();
      count++;
    }

    if (count == 0) {
      return double.nan;
    }

    return math.pow(sumPower4 / count, 0.25).toDouble();
  }
}

void _validateSize(num size, String name) {
  if (size.isNaN || size.isInfinite || size <= 0) {
    throw ArgumentError('$name must be a positive finite value.');
  }
}

void _validateDuration(Duration duration, String name) {
  if (duration <= Duration.zero) {
    throw ArgumentError('$name must be a positive duration.');
  }
}

void _validateValues(List<double> values) {
  if (values.isEmpty) {
    throw ArgumentError('values must not be empty.');
  }
}

double _inferSampleRateHz<TX, TY>(Series<TX, TY> series) {
  if (series.length < 2) {
    throw ArgumentError('Series must contain at least 2 points.');
  }

  final deltas = <double>[];
  for (var i = 0; i < series.length - 1; i++) {
    final current = _asDouble(series.getX(i));
    final next = _asDouble(series.getX(i + 1));
    final delta = next - current;
    if (delta <= 0 || delta.isNaN || delta.isInfinite) {
      throw ArgumentError('Series X values must be strictly increasing.');
    }
    deltas.add(delta);
  }

  final medianDelta = _median(deltas);
  if (medianDelta <= 0) {
    throw ArgumentError('Cannot infer sample rate from non-positive deltas.');
  }
  return 1.0 / medianDelta;
}

int _durationPointCount(Duration duration, double sampleRateHz) {
  if (sampleRateHz <= 0 || sampleRateHz.isNaN || sampleRateHz.isInfinite) {
    throw ArgumentError('Sample rate must be a positive finite value.');
  }

  final seconds = duration.inMicroseconds / Duration.microsecondsPerSecond.toDouble();
  final count = (seconds * sampleRateHz).round();
  return count < 1 ? 1 : count;
}

double _median(List<double> values) {
  if (values.isEmpty) {
    throw ArgumentError('values must not be empty.');
  }

  final sorted = List<double>.from(values)..sort();
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) {
    return sorted[mid];
  }

  return (sorted[mid - 1] + sorted[mid]) / 2.0;
}

double _asDouble(dynamic value) {
  if (value is num) {
    final resolved = value.toDouble();
    if (resolved.isNaN || resolved.isInfinite) {
      throw ArgumentError('Series X values must be finite numbers.');
    }
    return resolved;
  }
  throw ArgumentError('Series X values must be numeric.');
}
