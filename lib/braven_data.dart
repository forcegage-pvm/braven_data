/// Scientific data input, aggregation, and processing library.
///
/// This library provides high-performance data structures and algorithms
/// for scientific data visualization, including:
///
/// - TypedData-backed storage (Float64List, Int64List) for efficient memory usage
/// - `Series<TX, TY>` containers for strongly-typed data sequences
/// - Aggregation engine for downsampling (target: 100k points -> 1k points in <50ms)
/// - Pipeline API for scientific transformations (Normalized Power, etc.)
///
/// This is a pure Dart library with no Flutter dependencies, enabling:
/// - Independent testing without Flutter test harness overhead
/// - Performance benchmarking with standalone Dart scripts
/// - Potential future extraction to a separate package
library;

export 'src/aggregation.dart';
export 'src/algorithms.dart';
export 'src/analysis/distribution.dart';
// CSV processing pipeline exports (placeholder).
export 'src/csv/csv.dart';
// DataFrame layer exports.
export 'src/dataframe/dataframe.dart';
export 'src/engine.dart';
// FIT ingestion exports.
export 'src/fit/fit.dart';
// Metrics layer exports.
export 'src/metrics/metrics.dart';
// Output layer exports.
export 'src/output/output.dart';
export 'src/pipeline.dart';
export 'src/series.dart';
export 'src/storage.dart';
