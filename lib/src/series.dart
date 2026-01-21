import 'storage.dart';

/// Primary container for a sequence of data points.
class Series<TX, TY> {
  Series({
    required this.id,
    required this.meta,
    required SeriesStorage<dynamic, dynamic> storage,
    this.stats,
  }) : _storage = storage {
    _validateStorageTypes(storage);
  }

  final String id;
  final SeriesMeta meta;
  final SeriesStats? stats;
  final SeriesStorage<dynamic, dynamic> _storage;

  int get length => _storage.length;

  TX getX(int index) => _storage.getX(index) as TX;

  TY getY(int index) => _storage.getY(index) as TY;

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
