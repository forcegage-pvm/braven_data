import 'dart:typed_data';

import 'aggregation.dart';
import 'engine.dart';
import 'pipeline.dart';
import 'storage.dart';

/// Primary container for a sequence of data points.
///
/// A `Series` owns typed storage for X/Y values plus metadata. It validates
/// storage types at construction to keep reads type-safe.
///
/// Example:
/// ```dart
/// final series = Series<int, double>.fromTypedData(
///   meta: const SeriesMeta(name: 'Power', unit: 'W'),
///   xValues: [0, 1, 2],
///   yValues: [120.0, 130.0, 125.0],
/// );
/// ```
class Series<TX, TY> {
  static int _idCounter = 0;

  Series({
    required this.id,
    required this.meta,
    required SeriesStorage<dynamic, dynamic> storage,
    this.stats,
  }) : _storage = storage {
    _validateStorageTypes(storage);
  }

  /// Creates a `Series` backed by typed-data storage.
  ///
  /// When `id` is not provided, a unique identifier is generated.
  factory Series.fromTypedData({
    String? id,
    required SeriesMeta meta,
    required List<TX> xValues,
    required List<TY> yValues,
    SeriesStats? stats,
  }) {
    final storage = _canUseTypedStorage(xValues, yValues)
        ? TypedDataStorage<TX, TY>(
            xValues: xValues,
            yValues: yValues,
          )
        : ListStorage<TX, TY>(
            xValues: xValues,
            yValues: yValues,
          );
    final resolvedId = id ?? _generateId();
    return Series<TX, TY>(
      id: resolvedId,
      meta: meta,
      storage: storage,
      stats: stats,
    );
  }

  /// Unique identifier for this series.
  final String id;

  /// Metadata describing this series (name, unit).
  final SeriesMeta meta;

  /// Optional precomputed statistics for this series.
  final SeriesStats? stats;

  final SeriesStorage<dynamic, dynamic> _storage;

  /// The number of data points in this series.
  int get length => _storage.length;

  /// Returns the X value at the specified [index].
  ///
  /// Throws [RangeError] if [index] is out of bounds.
  TX getX(int index) => _storage.getX(index) as TX;

  /// Returns the Y value at the specified [index].
  ///
  /// Throws [RangeError] if [index] is out of bounds.
  TY getY(int index) => _storage.getY(index) as TY;

  /// Applies a transformation pipeline to this series.
  ///
  /// The returned series reflects all pipeline steps applied to this series.
  Series<TX, TY> transform(Pipeline<TX, TY> pipeline) {
    return pipeline.execute(this);
  }

  /// Aggregates this series into windowed values using [spec].
  ///
  /// The reducer in [spec] is applied over fixed windows of the series.
  Series<TX, TY> aggregate(AggregationSpec<TX> spec) {
    final result = AggregationEngine.aggregate(this, spec);
    final storage = TypedDataStorage<TX, TY>(
      xValues: result.xValues,
      yValues: result.yValues,
    );

    return Series<TX, TY>(
      id: _generateId(),
      meta: meta,
      storage: storage,
      stats: null,
    );
  }

  /// Returns a new series containing values in the range `[start, end)`.
  ///
  /// Throws a [RangeError] when the indices are invalid.
  Series<TX, TY> slice(int start, [int? end]) {
    final resolvedEnd = end ?? length;
    if (start < 0) {
      throw RangeError.range(start, 0, length, 'start');
    }
    if (resolvedEnd > length) {
      throw RangeError.range(resolvedEnd, 0, length, 'end');
    }
    if (start > resolvedEnd) {
      throw RangeError('start ($start) must be <= end ($resolvedEnd).');
    }

    final xValues = <TX>[];
    final yValues = <TY>[];
    for (var i = start; i < resolvedEnd; i++) {
      xValues.add(getX(i));
      yValues.add(getY(i));
    }

    final storage = TypedDataStorage<TX, TY>(
      xValues: xValues,
      yValues: yValues,
    );

    return Series<TX, TY>(
      id: _generateId(),
      meta: meta,
      storage: storage,
      stats: null,
    );
  }

  static String _generateId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    _idCounter += 1;
    return 'series-$timestamp-$_idCounter';
  }

  void _validateStorageTypes(SeriesStorage<dynamic, dynamic> storage) {
    final count = storage.length;
    for (var i = 0; i < count; i++) {
      final xValue = storage.getX(i);
      final yValue = storage.getY(i);
      if (xValue is! TX) {
        throw ArgumentError(
          'Series storage value at index $i is not a ${TX.toString()} for X.',
        );
      }
      if (yValue is! TY) {
        throw ArgumentError(
          'Series storage value at index $i is not a ${TY.toString()} for Y.',
        );
      }
    }
  }
}

bool _canUseTypedStorage<TX, TY>(List<TX> xValues, List<TY> yValues) {
  return _isNumericList(xValues) && _isNumericList(yValues);
}

bool _isNumericList<T>(List<T> values) {
  return values is Float64List || values is Int64List || values is List<double> || values is List<int>;
}

/// Describes a series with a name and optional unit.
class SeriesMeta {
  const SeriesMeta({
    required this.name,
    this.unit,
  });

  /// The display name of the series.
  final String name;

  /// The unit of measurement for the series values (e.g., 'W', 'bpm').
  final String? unit;
}

/// Precomputed statistics for a series.
///
/// The values are expected to reflect the underlying data at the time they
/// were computed and are not automatically updated.
class SeriesStats {
  const SeriesStats({
    required this.min,
    required this.max,
    required this.mean,
    required this.count,
  });

  /// The minimum value in the series.
  final num min;

  /// The maximum value in the series.
  final num max;

  /// The arithmetic mean (average) of the series values.
  final num mean;

  /// The number of data points used to compute these statistics.
  final int count;
}
