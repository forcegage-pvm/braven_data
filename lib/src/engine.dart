import 'aggregation.dart';
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
    if (window is! FixedWindowSpec) {
      throw UnimplementedError(
        'Only FixedWindowSpec is supported for aggregation right now.',
      );
    }

    final windowSizeRaw = window.size;
    if (windowSizeRaw % 1 != 0) {
      throw ArgumentError('Fixed window size must be an integer value.');
    }
    final windowSize = windowSizeRaw.toInt();
    if (windowSize <= 0) {
      throw ArgumentError('Fixed window size must be >= 1.');
    }

    final aggregatedX = <TX>[];
    final aggregatedY = <TY>[];
    final seriesLength = series.length;

    for (var start = 0; start < seriesLength; start += windowSize) {
      final end = (start + windowSize) > seriesLength ? seriesLength : start + windowSize;
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
}
