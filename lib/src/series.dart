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
