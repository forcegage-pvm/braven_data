import 'aggregation.dart';
import 'output/window_alignment.dart';
import 'series.dart';

/// Result of aggregating a series into windowed values.
///
/// Each entry in [xValues] corresponds to the aggregated value in [yValues].
class AggregationResult<TX, TY> {
  const AggregationResult({
    required this.xValues,
    required this.yValues,
  });

  final List<TX> xValues;
  final List<TY> yValues;
}

/// Aggregation engine for series windowing and reduction.
///
/// Example:
/// ```dart
/// final result = AggregationEngine.aggregate(
///   series,
///   AggregationSpec(window: WindowSpec.fixed(5), reducer: SeriesReducer.mean),
/// );
/// ```
class AggregationEngine {
  const AggregationEngine._();

  /// Aggregates [series] into windowed values described by [spec].
  ///
  /// Currently only [FixedWindowSpec] windows are supported.
  static AggregationResult<TX, TY> aggregate<TX, TY>(
    Series<TX, TY> series,
    AggregationSpec<TX> spec,
  ) {
    final window = spec.window;
    if (window is FixedWindowSpec) {
      final windowSizeRaw = window.size;
      if (windowSizeRaw % 1 != 0) {
        throw ArgumentError('Fixed window size must be an integer value.');
      }
      final windowSize = windowSizeRaw.toInt();
      if (windowSize <= 0) {
        throw ArgumentError('Fixed window size must be >= 1.');
      }
      return _aggregateFixed(series, spec, windowSize);
    }

    if (window is FixedDurationWindowSpec) {
      final windowSize = window.pointCountForSeries(series);
      return _aggregateFixed(series, spec, windowSize);
    }

    if (window is RollingDurationWindowSpec) {
      return _aggregateRollingDuration(series, spec, window);
    }

    throw UnimplementedError(
      'Only fixed and duration-based rolling windows are supported for '
      'aggregation right now.',
    );
  }
}

double alignWindowX(List<double> windowX, WindowAlignment alignment) {
  if (windowX.isEmpty) {
    throw ArgumentError('windowX must not be empty.');
  }

  switch (alignment) {
    case WindowAlignment.start:
      return windowX.first;
    case WindowAlignment.center:
      return (windowX.first + windowX.last) / 2.0;
    case WindowAlignment.end:
      return windowX.last;
  }
}

AggregationResult<TX, TY> _aggregateFixed<TX, TY>(
  Series<TX, TY> series,
  AggregationSpec<TX> spec,
  int windowSize,
) {
  if (windowSize <= 0) {
    throw ArgumentError('Window size must be >= 1.');
  }

  final aggregatedX = <TX>[];
  final aggregatedY = <TY>[];
  final seriesLength = series.length;

  for (var start = 0; start < seriesLength; start += windowSize) {
    final end =
        (start + windowSize) > seriesLength ? seriesLength : start + windowSize;
    if (start >= end) {
      break;
    }

    aggregatedX.add(series.getX(start));
    final windowValues = <TY>[];
    for (var i = start; i < end; i++) {
      windowValues.add(series.getY(i));
    }

    final reducer = spec.reducer as SeriesReducer<TY>;
    final reduced = reducer.reduce(windowValues);
    aggregatedY.add(reduced);
  }

  return AggregationResult<TX, TY>(
    xValues: aggregatedX,
    yValues: aggregatedY,
  );
}

AggregationResult<TX, TY> _aggregateRollingDuration<TX, TY>(
  Series<TX, TY> series,
  AggregationSpec<TX> spec,
  RollingDurationWindowSpec window,
) {
  final seriesLength = series.length;
  if (seriesLength == 0) {
    return AggregationResult<TX, TY>(xValues: const [], yValues: const []);
  }

  final resolvedWindowSize = window.pointCountForSeries(series);
  final windowSize = resolvedWindowSize < 1 ? 1 : resolvedWindowSize;
  final aggregatedX = <TX>[];
  final aggregatedY = <TY>[];
  final reducer = spec.reducer as SeriesReducer<TY>;
  final sampleX = series.getX(0);

  for (var endIndex = 0; endIndex < seriesLength; endIndex++) {
    var startIndex = endIndex - windowSize + 1;
    if (startIndex < 0) {
      startIndex = 0;
    }

    final windowValues = <TY>[];
    final windowX = <double>[];
    for (var i = startIndex; i <= endIndex; i++) {
      windowValues.add(series.getY(i));
      windowX.add(_asDoubleX(series.getX(i)));
    }

    final reduced = reducer.reduce(windowValues);
    aggregatedY.add(reduced);

    final alignedX = alignWindowX(windowX, spec.alignment);
    aggregatedX.add(_convertAlignedX(alignedX, sampleX));
  }

  return AggregationResult<TX, TY>(
    xValues: aggregatedX,
    yValues: aggregatedY,
  );
}

double _asDoubleX<TX>(TX value) {
  if (value is num) {
    final resolved = value.toDouble();
    if (resolved.isNaN || resolved.isInfinite) {
      throw ArgumentError('Series X values must be finite numbers.');
    }
    return resolved;
  }
  throw ArgumentError('Series X values must be numeric.');
}

TX _convertAlignedX<TX>(double aligned, TX sampleValue) {
  if (sampleValue is int) {
    return aligned.round() as TX;
  }
  if (sampleValue is double) {
    return aligned as TX;
  }
  if (sampleValue is num) {
    return aligned as TX;
  }
  throw ArgumentError('Series X values must be numeric.');
}
