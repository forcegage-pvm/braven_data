import 'aggregation.dart';
import 'series.dart';

/// Value mapper for pipeline transformations.
typedef Mapper<T> = T Function(T value);

/// Fluent interface for building series transformation pipelines.
///
/// Pipelines are immutable builders: each call returns a new pipeline with the
/// additional step applied.
abstract class Pipeline<TX, TY> {
  /// Applies [mapper] to each Y value in the series.
  Pipeline<TX, TY> map(Mapper<TY> mapper);

  /// Applies [reducer] over non-overlapping windows defined by [window].
  Pipeline<TX, TY> window(WindowSpec window, SeriesReducer<TY> reducer);

  /// Applies [reducer] over rolling windows defined by [window].
  Pipeline<TX, TY> rolling(WindowSpec window, SeriesReducer<TY> reducer);

  /// Collapses the series into a single scalar value using [reducer].
  Pipeline<TX, TY> collapse(SeriesReducer<TY> reducer);

  /// Executes the pipeline and returns a transformed series.
  Series<TX, TY> execute(Series<TX, TY> input);

  /// Executes the pipeline and returns a scalar value.
  TY executeScalar(Series<TX, TY> input);
}

/// Concrete pipeline builder implementation.
///
/// Example:
/// ```dart
/// final pipeline = PipelineBuilder<int, double>()
///     .map((value) => value * 1.05)
///     .rolling(WindowSpec.rolling(30), SeriesReducer.mean);
/// final output = pipeline.execute(series);
/// ```
class PipelineBuilder<TX, TY> implements Pipeline<TX, TY> {
  /// Creates an empty pipeline builder.
  PipelineBuilder() : _steps = const [];

  PipelineBuilder._(this._steps);

  final List<_PipelineStep<TX, TY>> _steps;

  /// Applies [mapper] to each Y value in the series.
  @override
  Pipeline<TX, TY> map(Mapper<TY> mapper) {
    _ensureNotCollapsed();
    return PipelineBuilder<TX, TY>._(
      [..._steps, _MapStep<TX, TY>(mapper)],
    );
  }

  /// Applies [reducer] over non-overlapping windows defined by [window].
  @override
  Pipeline<TX, TY> window(WindowSpec window, SeriesReducer<TY> reducer) {
    _ensureNotCollapsed();
    return PipelineBuilder<TX, TY>._(
      [..._steps, _WindowStep<TX, TY>(window, reducer)],
    );
  }

  /// Applies [reducer] over rolling windows defined by [window].
  @override
  Pipeline<TX, TY> rolling(WindowSpec window, SeriesReducer<TY> reducer) {
    _ensureNotCollapsed();
    return PipelineBuilder<TX, TY>._(
      [..._steps, _RollingStep<TX, TY>(window, reducer)],
    );
  }

  /// Collapses the series into a single scalar value using [reducer].
  @override
  Pipeline<TX, TY> collapse(SeriesReducer<TY> reducer) {
    _ensureNotCollapsed();
    return PipelineBuilder<TX, TY>._(
      [..._steps, _CollapseStep<TX, TY>(reducer)],
    );
  }

  /// Executes the pipeline and returns a transformed series.
  @override
  Series<TX, TY> execute(Series<TX, TY> input) {
    var current = input;
    for (final step in _steps) {
      if (step is _MapStep<TX, TY>) {
        current = _applyMap(current, step.mapper);
      } else if (step is _WindowStep<TX, TY>) {
        current = _applyWindow(current, step.window, step.reducer);
      } else if (step is _RollingStep<TX, TY>) {
        current = _applyRolling(current, step.window, step.reducer);
      } else if (step is _CollapseStep<TX, TY>) {
        final scalar = _applyCollapse(current, step.reducer);
        return _seriesFromScalar(current, scalar);
      }
    }
    return current;
  }

  /// Executes the pipeline and returns a scalar value.
  @override
  TY executeScalar(Series<TX, TY> input) {
    var current = input;
    for (final step in _steps) {
      if (step is _MapStep<TX, TY>) {
        current = _applyMap(current, step.mapper);
      } else if (step is _WindowStep<TX, TY>) {
        current = _applyWindow(current, step.window, step.reducer);
      } else if (step is _RollingStep<TX, TY>) {
        current = _applyRolling(current, step.window, step.reducer);
      } else if (step is _CollapseStep<TX, TY>) {
        return _applyCollapse(current, step.reducer);
      }
    }
    throw StateError('Pipeline has no collapse reducer.');
  }

  void _ensureNotCollapsed() {
    if (_steps.any((step) => step is _CollapseStep<TX, TY>)) {
      throw StateError('Cannot add steps after collapse().');
    }
  }

  Series<TX, TY> _applyMap(Series<TX, TY> input, Mapper<TY> mapper) {
    final xValues = <TX>[];
    final yValues = <TY>[];
    for (var i = 0; i < input.length; i++) {
      xValues.add(input.getX(i));
      yValues.add(mapper(input.getY(i)));
    }
    return Series<TX, TY>.fromTypedData(
      meta: input.meta,
      xValues: xValues,
      yValues: yValues,
      stats: null,
    );
  }

  Series<TX, TY> _applyRolling(
    Series<TX, TY> input,
    WindowSpec window,
    SeriesReducer<TY> reducer,
  ) {
    if (input.length == 0) {
      return Series<TX, TY>.fromTypedData(
        meta: input.meta,
        xValues: <TX>[],
        yValues: <TY>[],
        stats: null,
      );
    }

    if (window is FixedWindowSpec) {
      return _applyFixedRolling(input, window, reducer);
    }
    if (window is RollingWindowSpec) {
      return _applySlidingRolling(input, window, reducer);
    }

    throw UnimplementedError('PixelAlignedWindowSpec is not supported yet.');
  }

  Series<TX, TY> _applyWindow(
    Series<TX, TY> input,
    WindowSpec window,
    SeriesReducer<TY> reducer,
  ) {
    if (input.length == 0) {
      return Series<TX, TY>.fromTypedData(
        meta: input.meta,
        xValues: <TX>[],
        yValues: <TY>[],
        stats: null,
      );
    }

    if (window is FixedWindowSpec) {
      return _applyFixedRolling(input, window, reducer);
    }

    if (window is PixelAlignedWindowSpec) {
      throw UnimplementedError('PixelAlignedWindowSpec is not supported yet.');
    }

    throw ArgumentError('window() requires FixedWindowSpec.');
  }

  Series<TX, TY> _applyFixedRolling(
    Series<TX, TY> input,
    FixedWindowSpec window,
    SeriesReducer<TY> reducer,
  ) {
    final windowSize = _resolveWindowSize(window.size, 'Fixed window size');
    final xValues = <TX>[];
    final yValues = <TY>[];
    final count = input.length;

    for (var start = 0; start < count; start += windowSize) {
      final end = (start + windowSize) > count ? count : start + windowSize;
      if (start >= end) {
        break;
      }
      xValues.add(input.getX(start));
      final windowValues = <TY>[];
      for (var i = start; i < end; i++) {
        windowValues.add(input.getY(i));
      }
      yValues.add(reducer.reduce(windowValues));
    }

    return Series<TX, TY>.fromTypedData(
      meta: input.meta,
      xValues: xValues,
      yValues: yValues,
      stats: null,
    );
  }

  Series<TX, TY> _applySlidingRolling(
    Series<TX, TY> input,
    RollingWindowSpec window,
    SeriesReducer<TY> reducer,
  ) {
    final windowSize = _resolveWindowSize(window.size, 'Rolling window size');
    final xValues = <TX>[];
    final yValues = <TY>[];
    final count = input.length;

    if (windowSize > count) {
      return Series<TX, TY>.fromTypedData(
        meta: input.meta,
        xValues: <TX>[],
        yValues: <TY>[],
        stats: null,
      );
    }

    for (var start = 0; start + windowSize <= count; start++) {
      final end = start + windowSize;
      xValues.add(input.getX(start));
      final windowValues = <TY>[];
      for (var i = start; i < end; i++) {
        windowValues.add(input.getY(i));
      }
      yValues.add(reducer.reduce(windowValues));
    }

    return Series<TX, TY>.fromTypedData(
      meta: input.meta,
      xValues: xValues,
      yValues: yValues,
      stats: null,
    );
  }

  TY _applyCollapse(Series<TX, TY> input, SeriesReducer<TY> reducer) {
    if (input.length == 0) {
      throw StateError('Cannot collapse an empty series.');
    }
    final values = <TY>[];
    for (var i = 0; i < input.length; i++) {
      values.add(input.getY(i));
    }
    return reducer.reduce(values);
  }

  Series<TX, TY> _seriesFromScalar(Series<TX, TY> input, TY value) {
    if (input.length == 0) {
      throw StateError('Cannot create scalar series from empty input.');
    }
    return Series<TX, TY>.fromTypedData(
      meta: input.meta,
      xValues: <TX>[input.getX(0)],
      yValues: <TY>[value],
      stats: null,
    );
  }
}

sealed class _PipelineStep<TX, TY> {
  const _PipelineStep();
}

final class _MapStep<TX, TY> extends _PipelineStep<TX, TY> {
  const _MapStep(this.mapper);

  final Mapper<TY> mapper;
}

final class _RollingStep<TX, TY> extends _PipelineStep<TX, TY> {
  const _RollingStep(this.window, this.reducer);

  final WindowSpec window;
  final SeriesReducer<TY> reducer;
}

final class _WindowStep<TX, TY> extends _PipelineStep<TX, TY> {
  const _WindowStep(this.window, this.reducer);

  final WindowSpec window;
  final SeriesReducer<TY> reducer;
}

final class _CollapseStep<TX, TY> extends _PipelineStep<TX, TY> {
  const _CollapseStep(this.reducer);

  final SeriesReducer<TY> reducer;
}

int _resolveWindowSize(num size, String label) {
  if (size % 1 != 0) {
    throw ArgumentError('$label must be an integer value.');
  }
  final resolved = size.toInt();
  if (resolved <= 0) {
    throw ArgumentError('$label must be >= 1.');
  }
  return resolved;
}
