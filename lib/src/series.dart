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
