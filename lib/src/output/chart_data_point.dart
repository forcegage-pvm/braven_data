import '../series.dart';

/// Output structure compatible with BravenChartPlus.
///
/// This is a local copy of the chart library's data structure,
/// allowing braven_data to remain a pure Dart package without
/// Flutter dependencies.
class ChartDataPoint {
  /// X-axis value (typically elapsed seconds).
  final double x;

  /// Y-axis value.
  final double y;

  /// Optional: Original absolute timestamp.
  final DateTime? timestamp;

  /// Optional: Label for tooltips/annotations.
  final String? label;

  /// Optional: Additional data (min, max, count, stdDev, etc.).
  final Map<String, dynamic>? metadata;

  const ChartDataPoint({
    required this.x,
    required this.y,
    this.timestamp,
    this.label,
    this.metadata,
  });

  /// Returns true when both x and y are finite values.
  bool get isValid => x.isFinite && y.isFinite;

  /// Returns a copy of this point with overridden fields.
  ChartDataPoint copyWith({
    double? x,
    double? y,
    DateTime? timestamp,
    String? label,
    Map<String, dynamic>? metadata,
  }) {
    return ChartDataPoint(
      x: x ?? this.x,
      y: y ?? this.y,
      timestamp: timestamp ?? this.timestamp,
      label: label ?? this.label,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is ChartDataPoint &&
        other.x == x &&
        other.y == y &&
        other.timestamp == timestamp &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(x, y, timestamp, label);
}

/// Extension methods for converting Series to chart-ready output.
extension SeriesChartOutput<TX, TY extends num> on Series<TX, TY> {
  /// Convert this Series to a list of ChartDataPoints.
  List<ChartDataPoint> toChartDataPoints({
    bool includeMinMax = false,
    bool includeTimestamp = false,
  }) {
    final points = <ChartDataPoint>[];
    final stats = this.stats;
    final includeStats = includeMinMax && stats != null;
    final baseMetadata = includeStats
        ? <String, dynamic>{
            'min': stats.min,
            'max': stats.max,
            'count': stats.count,
          }
        : null;

    DateTime? origin;
    for (var i = 0; i < length; i++) {
      final xValue = getX(i);
      final yValue = getY(i);
      DateTime? timestamp;
      double xDouble;

      if (xValue is DateTime) {
        origin ??= xValue;
        xDouble = xValue.difference(origin).inMicroseconds /
            Duration.microsecondsPerSecond;
        if (includeTimestamp) {
          timestamp = xValue;
        }
      } else if (xValue is num) {
        xDouble = xValue.toDouble();
      } else {
        throw ArgumentError('Series X value must be num or DateTime.');
      }

      final metadata =
          baseMetadata == null ? null : Map<String, dynamic>.from(baseMetadata);
      points.add(
        ChartDataPoint(
          x: xDouble,
          y: yValue.toDouble(),
          timestamp: timestamp,
          metadata: metadata,
        ),
      );
    }

    return points;
  }

  /// Convert to a generic list of maps for flexible output.
  List<Map<String, dynamic>> toMapList() {
    final maps = <Map<String, dynamic>>[];
    DateTime? origin;

    for (var i = 0; i < length; i++) {
      final xValue = getX(i);
      final yValue = getY(i);
      double xDouble;

      if (xValue is DateTime) {
        origin ??= xValue;
        xDouble = xValue.difference(origin).inMicroseconds /
            Duration.microsecondsPerSecond;
      } else if (xValue is num) {
        xDouble = xValue.toDouble();
      } else {
        throw ArgumentError('Series X value must be num or DateTime.');
      }

      maps.add(<String, dynamic>{
        'x': xDouble,
        'y': yValue.toDouble(),
      });
    }

    return maps;
  }

  /// Convert to tuples for compact representation.
  List<(double, double)> toTuples() {
    final tuples = <(double, double)>[];
    DateTime? origin;

    for (var i = 0; i < length; i++) {
      final xValue = getX(i);
      final yValue = getY(i);
      double xDouble;

      if (xValue is DateTime) {
        origin ??= xValue;
        xDouble = xValue.difference(origin).inMicroseconds /
            Duration.microsecondsPerSecond;
      } else if (xValue is num) {
        xDouble = xValue.toDouble();
      } else {
        throw ArgumentError('Series X value must be num or DateTime.');
      }

      tuples.add((xDouble, yValue.toDouble()));
    }

    return tuples;
  }
}
