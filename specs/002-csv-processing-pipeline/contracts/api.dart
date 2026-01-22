// ============================================================================
// API Contract: CSV Processing Pipeline
// Feature: 002-csv-processing-pipeline
// Date: 2026-01-22
// Status: Design Contract (not implementation)
// ============================================================================
//
// This file defines the PUBLIC API surface for the CSV Processing Pipeline.
// Implementation must match these signatures exactly.
//
// ============================================================================

// ---------------------------------------------------------------------------
// SECTION 1: CSV INGESTION LAYER
// ---------------------------------------------------------------------------

/// Defines how X-axis values should be interpreted and converted.
enum XValueType {
  /// ISO 8601 timestamp string (e.g., "2025-10-26T13:23:17Z")
  iso8601,

  /// Unix timestamp in seconds (e.g., 1698325397)
  epochSeconds,

  /// Unix timestamp in milliseconds (e.g., 1698325397000)
  epochMillis,

  /// Already expressed as elapsed seconds from start (e.g., 0, 1, 2, 3)
  elapsedSeconds,

  /// Elapsed time in milliseconds from start
  elapsedMillis,

  /// Use row number as X value (0, 1, 2, ...)
  rowIndex,
}

/// Supported data types for CSV columns.
enum FieldType {
  /// 64-bit floating point (stored as Float64List)
  float64,

  /// 64-bit integer (stored as Int64List)
  int64,

  /// String values (stored as List<String>)
  string,
}

/// Defines a single column in the CSV schema.
class ColumnDef {
  /// Column header name (must match CSV header exactly)
  final String name;

  /// Data type for parsing and storage
  final FieldType type;

  /// Value to use when cell is empty/null (default: NaN for float64, 0 for int64)
  final dynamic defaultValue;

  /// Optional unit annotation (e.g., "W", "bpm", "m/s")
  final String? unit;

  const ColumnDef({
    required this.name,
    required this.type,
    this.defaultValue,
    this.unit,
  });
}

/// Defines the complete structure for parsing a CSV file.
class CsvSchema {
  /// Column name containing X-axis values (null = use rowIndex)
  final String? xColumn;

  /// How to parse/interpret X-axis values
  final XValueType xType;

  /// Y-value column definitions
  final List<ColumnDef> columns;

  /// Whether first row contains headers (default: true)
  final bool hasHeader;

  /// Column separator character (default: ',')
  final String delimiter;

  const CsvSchema({
    this.xColumn,
    required this.xType,
    required this.columns,
    this.hasHeader = true,
    this.delimiter = ',',
  });
}

/// Loads CSV files into DataFrame structures.
abstract class CsvLoader {
  /// Load a CSV file synchronously from string content.
  ///
  /// [content] - Raw CSV string content
  /// [schema] - Schema defining how to parse the CSV
  ///
  /// Returns a [DataFrame] with typed columnar storage.
  /// Throws [FormatException] if CSV structure doesn't match schema.
  static DataFrame loadString(String content, CsvSchema schema) {
    throw UnimplementedError();
  }

  /// Load a CSV file asynchronously from a file path.
  ///
  /// [path] - Path to the CSV file
  /// [schema] - Schema defining how to parse the CSV
  ///
  /// Returns a [Future<DataFrame>] with typed columnar storage.
  static Future<DataFrame> load(String path, CsvSchema schema) async {
    throw UnimplementedError();
  }
}

// ---------------------------------------------------------------------------
// SECTION 2: DATAFRAME
// ---------------------------------------------------------------------------

/// Columnar container for parsed CSV data.
///
/// Provides type-safe access to columns and Series extraction.
class DataFrame {
  /// Number of data rows (excludes header)
  int get rowCount => throw UnimplementedError();

  /// List of all column names
  List<String> get columnNames => throw UnimplementedError();

  /// Get a column's values with compile-time type safety.
  ///
  /// [T] - Expected type (double, int, or String)
  /// [columnName] - Name of the column to retrieve
  ///
  /// Throws [ArgumentError] if column doesn't exist.
  List<T> get<T>(String columnName) => throw UnimplementedError();

  /// Get the X-axis values as elapsed seconds from start.
  ///
  /// First value is always 0.0; subsequent values are relative.
  List<double> getXValues() => throw UnimplementedError();

  /// Extract a Series from this DataFrame.
  ///
  /// [yColumn] - Name of the Y-value column
  /// [meta] - Optional metadata for the Series
  ///
  /// Returns a [Series<double, double>] with normalized X values.
  Series<double, double> toSeries(String yColumn, {SeriesMeta? meta}) {
    throw UnimplementedError();
  }
}

// ---------------------------------------------------------------------------
// SECTION 3: CHART OUTPUT LAYER
// ---------------------------------------------------------------------------

/// Output structure compatible with BravenChartPlus.
///
/// This is a local copy of the chart library's data structure,
/// allowing braven_data to remain a pure Dart package without
/// Flutter dependencies.
class ChartDataPoint {
  /// X-axis value (typically elapsed seconds)
  final double x;

  /// Y-axis value
  final double y;

  /// Optional: Original absolute timestamp
  final DateTime? timestamp;

  /// Optional: Label for tooltips/annotations
  final String? label;

  /// Optional: Additional data (min, max, count, stdDev, etc.)
  final Map<String, dynamic>? metadata;

  const ChartDataPoint({
    required this.x,
    required this.y,
    this.timestamp,
    this.label,
    this.metadata,
  });
}

/// Extension methods for converting Series to chart-ready output.
extension SeriesChartOutput<TX, TY extends num> on Series<TX, TY> {
  /// Convert this Series to a list of ChartDataPoints.
  ///
  /// [includeMinMax] - If true and Series has interval data, include
  ///                   min/max in metadata
  /// [includeTimestamp] - If true, include original DateTime in each point
  ///
  /// Returns a [List<ChartDataPoint>] ready for BravenChartPlus.
  List<ChartDataPoint> toChartDataPoints({
    bool includeMinMax = false,
    bool includeTimestamp = false,
  }) {
    throw UnimplementedError();
  }

  /// Convert to a generic list of maps for flexible output.
  ///
  /// Returns [List<Map<String, dynamic>>] with 'x' and 'y' keys.
  List<Map<String, dynamic>> toMapList() => throw UnimplementedError();

  /// Convert to tuples for compact representation.
  ///
  /// Returns [List<(double, double)>] of (x, y) pairs.
  List<(double, double)> toTuples() => throw UnimplementedError();
}

// ---------------------------------------------------------------------------
// SECTION 4: WINDOW ALIGNMENT
// ---------------------------------------------------------------------------

/// Specifies where output points align relative to their aggregation window.
enum WindowAlignment {
  /// X value = start of window (for fixed bins, histograms)
  start,

  /// X value = center of window (for signal processing)
  center,

  /// X value = end of window (for trailing averages, default)
  end,
}

// ---------------------------------------------------------------------------
// SECTION 5: DURATION-BASED WINDOWS (EXTENSIONS TO EXISTING)
// ---------------------------------------------------------------------------

/// Extension to WindowSpec for duration-based specifications.
extension DurationWindowSpec on WindowSpec {
  /// Create a fixed (non-overlapping) window with duration.
  ///
  /// [duration] - Window size as Duration
  /// [alignment] - Where to place output X value (default: start)
  static WindowSpec fixedDuration(
    Duration duration, {
    WindowAlignment alignment = WindowAlignment.start,
  }) {
    throw UnimplementedError();
  }

  /// Create a rolling (overlapping) window with duration.
  ///
  /// [duration] - Window size as Duration
  /// [alignment] - Where to place output X value (default: end)
  static WindowSpec rollingDuration(
    Duration duration, {
    WindowAlignment alignment = WindowAlignment.end,
  }) {
    throw UnimplementedError();
  }
}

// ---------------------------------------------------------------------------
// SECTION 6: SERIES METRIC INTERFACE
// ---------------------------------------------------------------------------

/// Interface for computing scalar values from an entire Series.
///
/// Implement this interface to create custom metrics that can be
/// used with the pipeline's compute() method.
///
/// Example:
/// ```dart
/// class MaxPowerMetric implements SeriesMetric<double> {
///   const MaxPowerMetric();
///
///   @override
///   double calculate(Series<dynamic, double> series) {
///     return series.yValues.reduce(max);
///   }
/// }
/// ```
abstract class SeriesMetric<T> {
  const SeriesMetric();

  /// Calculate a single value from the entire series.
  ///
  /// [series] - The input series to analyze
  ///
  /// Returns a scalar value of type [T].
  T calculate(Series<dynamic, double> series);
}

/// Normalized Power metric for cycling power data.
///
/// Algorithm: 30s SMA → pow(4) → mean → root(4)
class NormalizedPowerMetric implements SeriesMetric<double> {
  final Duration windowSize;

  const NormalizedPowerMetric({
    this.windowSize = const Duration(seconds: 30),
  });

  @override
  double calculate(Series<dynamic, double> series) {
    throw UnimplementedError();
  }
}

/// xPower metric using exponential weighted moving average.
///
/// Algorithm: 25s EWMA → pow(4) → mean → root(4)
class XPowerMetric implements SeriesMetric<double> {
  final Duration windowSize;
  final double? alpha;

  const XPowerMetric({
    this.windowSize = const Duration(seconds: 25),
    this.alpha,
  });

  @override
  double calculate(Series<dynamic, double> series) {
    throw UnimplementedError();
  }
}

/// Variability Index: NP / Average Power
class VariabilityIndexMetric implements SeriesMetric<double> {
  const VariabilityIndexMetric();

  @override
  double calculate(Series<dynamic, double> series) {
    throw UnimplementedError();
  }
}

// ---------------------------------------------------------------------------
// SECTION 7: PIPELINE EXTENSIONS
// ---------------------------------------------------------------------------

/// Extension methods for computing metrics on Series.
extension SeriesMetricCompute<TX> on Series<TX, double> {
  /// Compute a scalar metric from this series.
  ///
  /// [metric] - The SeriesMetric implementation to use
  ///
  /// Returns the computed scalar value.
  T compute<T>(SeriesMetric<T> metric) => metric.calculate(this);
}

// ---------------------------------------------------------------------------
// PLACEHOLDER: Referenced types from Sprint 001
// ---------------------------------------------------------------------------

// These types already exist in lib/src/ - shown here for contract completeness

class Series<TX, TY> {
  final String id;
  final SeriesMeta meta;
  Series({required this.id, required this.meta});
}

class SeriesMeta {
  final String name;
  final String? unit;
  const SeriesMeta({required this.name, this.unit});
}

abstract class WindowSpec {
  factory WindowSpec.fixed(num size) => throw UnimplementedError();
  factory WindowSpec.rolling(num size) => throw UnimplementedError();
}
