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
    throw UnimplementedError();
  }
}

/// Extension methods for converting Series to chart-ready output.
extension SeriesChartOutput<TX, TY extends num> on Series<TX, TY> {
  /// Convert this Series to a list of ChartDataPoints.
  List<ChartDataPoint> toChartDataPoints({
    bool includeMinMax = false,
    bool includeTimestamp = false,
  }) {
    throw UnimplementedError();
  }

  /// Convert to a generic list of maps for flexible output.
  List<Map<String, dynamic>> toMapList() {
    throw UnimplementedError();
  }

  /// Convert to tuples for compact representation.
  List<(double, double)> toTuples() {
    throw UnimplementedError();
  }
}
