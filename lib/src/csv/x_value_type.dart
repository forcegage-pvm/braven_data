/// Defines how X-axis values in CSV files are interpreted.
///
/// These values indicate how to parse or derive the X value for each row.
enum XValueType {
  /// ISO 8601 timestamp string (e.g., 2025-10-26T13:23:17Z).
  iso8601,

  /// Unix timestamp in seconds.
  epochSeconds,

  /// Unix timestamp in milliseconds.
  epochMillis,

  /// Elapsed seconds from the start of the series.
  elapsedSeconds,

  /// Elapsed milliseconds from the start of the series.
  elapsedMillis,

  /// Use row index (0, 1, 2, ...) as the X value.
  rowIndex,

  /// User-provided parser callback determines the X value.
  custom,
}
