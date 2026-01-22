/// Defines column data types for Y-value columns in CSV data.
enum FieldType {
  /// 64-bit floating point values stored as Float64List.
  float64,

  /// 64-bit integer values stored as Int64List.
  int64,

  /// String values stored as `List<String>`.
  string,
}
