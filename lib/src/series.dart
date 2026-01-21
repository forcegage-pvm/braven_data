import 'aggregation.dart';
import 'storage.dart';

/// Primary container for a sequence of data points.
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

  factory Series.fromTypedData({
    String? id,
    required SeriesMeta meta,
    required List<TX> xValues,
    required List<TY> yValues,
    SeriesStats? stats,
  }) {
    final storage = TypedDataStorage<TX, TY>(
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

  final String id;
  final SeriesMeta meta;
  final SeriesStats? stats;
  final SeriesStorage<dynamic, dynamic> _storage;

  int get length => _storage.length;

  TX getX(int index) => _storage.getX(index) as TX;

  TY getY(int index) => _storage.getY(index) as TY;

  Series<TX, TY> aggregate(AggregationSpec<TX> spec) {
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
    final seriesLength = length;

    for (var start = 0; start < seriesLength; start += windowSize) {
      final end = (start + windowSize) > seriesLength
          ? seriesLength
          : start + windowSize;
      if (start >= end) {
        break;
      }

      aggregatedX.add(getX(start));
      final windowValues = <TY>[];
      for (var i = start; i < end; i++) {
        windowValues.add(getY(i));
      }

      final reducer = spec.reducer as SeriesReducer<TY>;
      final reduced = reducer.reduce(windowValues);
      aggregatedY.add(reduced);
    }

    final storage = TypedDataStorage<TX, TY>(
      xValues: aggregatedX,
      yValues: aggregatedY,
    );

    return Series<TX, TY>(
      id: _generateId(),
      meta: meta,
      storage: storage,
      stats: null,
    );
  }

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

/// Value objects for series metadata and statistics.
class SeriesMeta {
  const SeriesMeta({
    required this.name,
    this.unit,
  });

  final String name;
  final String? unit;
}

class SeriesStats {
  const SeriesStats({
    required this.min,
    required this.max,
    required this.mean,
    required this.count,
  });

  final num min;
  final num max;
  final num mean;
  final int count;
}
