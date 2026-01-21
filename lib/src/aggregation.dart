/// Aggregation window specifications for downsampling and rendering.
sealed class WindowSpec {
  const WindowSpec._();

  factory WindowSpec.fixed(num size) => FixedWindowSpec(size);

  factory WindowSpec.rolling(num size) => RollingWindowSpec(size);

  factory WindowSpec.pixelAligned(double pixelDensity) => PixelAlignedWindowSpec(pixelDensity);
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
  const AggregationSpec({required this.window, required this.reducer});

  final WindowSpec window;
  final SeriesReducer<dynamic> reducer;
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

void _validateValues(List<double> values) {
  if (values.isEmpty) {
    throw ArgumentError('values must not be empty.');
  }
}
