import 'output/window_alignment.dart';
import 'series.dart';

/// Aggregation window specifications for downsampling and rendering.
sealed class WindowSpec {
  const WindowSpec._();

  factory WindowSpec.fixed(num size) => FixedWindowSpec(size);

  factory WindowSpec.rolling(num size) => RollingWindowSpec(size);

  factory WindowSpec.fixedDuration(Duration duration) =>
      FixedDurationWindowSpec(duration);

  factory WindowSpec.rollingDuration(Duration duration) =>
      RollingDurationWindowSpec(duration);

  factory WindowSpec.pixelAligned(double pixelDensity) =>
      PixelAlignedWindowSpec(pixelDensity);
}

/// Reduces a list of values into a single value.
abstract class SeriesReducer<T> {
  const SeriesReducer();

  T reduce(List<T> values);

  /// Built-in reducers for double values.
  static SeriesReducer<double> get mean => const MeanReducer();
  static SeriesReducer<double> get max => const MaxReducer();
  static SeriesReducer<double> get min => const MinReducer();
  static SeriesReducer<double> get sum => const SumReducer();
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

  final WindowSpec window;
  final SeriesReducer<dynamic> reducer;
  final WindowAlignment alignment;
}

/// Non-overlapping fixed-size window.
///
/// Each window contains `size` consecutive points.
class FixedWindowSpec extends WindowSpec {
  FixedWindowSpec(this.size) : super._() {
    _validateSize(size, 'size');
  }

  final num size;
}

/// Sliding window that moves through data.
///
/// Each step advances by one element, producing overlapping windows.
class RollingWindowSpec extends WindowSpec {
  RollingWindowSpec(this.size) : super._() {
    _validateSize(size, 'size');
  }

  final num size;
}

/// Fixed-duration window based on time spans.
///
/// Converts a [duration] into a point count using inferred sample rate.
class FixedDurationWindowSpec extends WindowSpec {
  FixedDurationWindowSpec(this.duration) : super._() {
    _validateDuration(duration, 'duration');
  }

  final Duration duration;

  int pointCountForSeries<TX, TY>(Series<TX, TY> series) {
    final sampleRate = inferredSampleRateHz(series);
    return _durationPointCount(duration, sampleRate);
  }

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

  final Duration duration;

  int pointCountForSeries<TX, TY>(Series<TX, TY> series) {
    final sampleRate = inferredSampleRateHz(series);
    return _durationPointCount(duration, sampleRate);
  }

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

  final seconds =
      duration.inMicroseconds / Duration.microsecondsPerSecond.toDouble();
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
