# braven_data: Gaps & Enhancements Specification

**Created**: 2026-01-21  
**Status**: DRAFT  
**Source**: Analysis of `data_input_api_proposal.md`, `csv_test_scenario.dart`, reference implementations, and Sprint 001 implementation

## Overview

This document captures all features proposed in the original design documents that were **not implemented** in Sprint 001. These represent the remaining work to achieve full API parity with the vision.

## Primary Use Case: CSV → Processing → Chart

The core data flow for braven_data is:

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────────┐
│  1. INGEST      │────▶│  2. PROCESS      │────▶│  3. OUTPUT          │
│                 │     │                  │     │                     │
│  CSV File       │     │  Aggregation     │     │  ChartDataPoint[]   │
│  (Raw Records)  │     │  Metrics         │     │  (Render-Ready)     │
│                 │     │  Windowing       │     │                     │
└─────────────────┘     └──────────────────┘     └─────────────────────┘
     DataFrame              Series<TX,TY>           List<ChartDataPoint>
```

**Example**: A Garmin cycling CSV with power, heart rate, GPS at 1Hz → smooth/aggregate → render on BravenChartPlus.

### Sample Input Data

File: `data/tp-2023646.2025-10-26-13-23-16-784Z.GarminPing.AAAAAGj-IMQ_uYSx_core_records.csv`

| Column               | Type     | Description                  |
| -------------------- | -------- | ---------------------------- |
| `timestamp`          | DateTime | ISO 8601 with timezone (1Hz) |
| `power`              | double   | Watts (cycling power)        |
| `heart_rate`         | int      | BPM                          |
| `cadence`            | int      | RPM                          |
| `speed`              | double   | m/s                          |
| `altitude`           | double   | meters                       |
| `temperature`        | int      | °C ambient                   |
| `latitude/longitude` | double   | GPS coordinates              |
| `core_temperature`   | double   | Body core temp sensor        |
| `skin_temperature`   | double   | Skin temp sensor             |

### Processing Requirements

| Chart                | Source Column | Processing                    | Output         |
| -------------------- | ------------- | ----------------------------- | -------------- |
| Power Curve (smooth) | `power`       | 30s rolling mean              | Smoothed line  |
| Power (raw)          | `power`       | None or 1s bins               | All points     |
| Heart Rate           | `heart_rate`  | 5s rolling mean               | Smoothed HR    |
| NP Intensity         | `power`       | 30s SMA → pow4 → mean → root4 | NP curve       |
| Altitude Profile     | `altitude`    | None                          | Raw altitude   |
| Speed                | `speed`       | 10s rolling mean              | Smoothed speed |

**Scalar Metrics** (single values):

- Normalized Power (NP)
- Average Power
- Variability Index (VI)
- Max Power (peak)
- Total Distance

### Output Target: BravenChartPlus

**Reference**: [chart_data_point.dart](reference_implementations/chart_data_point.dart)

```dart
class ChartDataPoint {
  final double x;              // REQUIRED: X-axis value
  final double y;              // REQUIRED: Y-axis value
  final DateTime? timestamp;   // Optional: Original timestamp
  final String? label;         // Optional: For tooltips
  final Map<String, dynamic>? metadata;  // Optional: Extra data (min/max/stdDev)
  final SegmentStyle? segmentStyle;      // Optional: Line styling
  final PointStyle? pointStyle;          // Optional: Point styling
}
```

---

## Reference Implementations

The following working prototypes are included for implementation guidance:

| File                                                                                                         | Purpose              | Key Features                                                           |
| ------------------------------------------------------------------------------------------------------------ | -------------------- | ---------------------------------------------------------------------- |
| [csv_test_scenario.dart](csv_test_scenario.dart)                                                             | API usage sketch     | Schema, DataFrame, SeriesPipeline, multi-reducer aggregation           |
| [reference_implementations/csv_ingestion_example.dart](reference_implementations/csv_ingestion_example.dart) | End-to-end ingestion | DelimitedLoader mock, DataFrame, rolling pipeline, metric calculations |
| [reference_implementations/power_metrics.dart](reference_implementations/power_metrics.dart)                 | Domain algorithms    | SeriesMetric interface, NP/xPower/VI metrics, SMA/EWMA primitives      |
| [reference_implementations/chart_data_point.dart](reference_implementations/chart_data_point.dart)           | Chart output target  | ChartDataPoint structure from BravenChartPlus                          |

---

## 1. CSV Ingestion Layer

**Priority**: HIGH  
**Proposal Reference**: §6 Data Ingestion & Transformation

### 1.1 DelimitedSchema

Column-level schema definition for typed CSV parsing.

**Reference**: [csv_ingestion_example.dart](reference_implementations/csv_ingestion_example.dart) lines 12-22

```dart
class DelimitedSchema {
  final String dateColumn;        // X-axis column (often timestamp)
  final String dateFormat;        // e.g., 'ISO8601'
  final List<ColumnDef> columns;  // Dependent variable definitions

  const DelimitedSchema({
    required this.dateColumn,
    this.dateFormat = 'ISO8601',
    required this.columns,
  });
}
```

**Alternative signature** from csv_test_scenario.dart:

```dart
class DelimitedSchema {
  final String xColumn;           // Generic independent variable
  final DataType xType;           // Type of X column
  final List<ColumnDef> columns;
}
```

**Design Decision**: Support BOTH patterns - `dateColumn` for time-series (common case) and `xColumn + xType` for generic scientific data.

### 1.2 ColumnDef

Individual column definition with type and optional metadata.

**Reference**: [csv_ingestion_example.dart](reference_implementations/csv_ingestion_example.dart) lines 24-28

```dart
class ColumnDef {
  final String name;
  final FieldType type;

  const ColumnDef(this.name, this.type);
}
```

**Extended version** with optional metadata:

```dart
class ColumnDef {
  final String name;
  final DataType type;
  final dynamic defaultValue;  // For missing data (sentinels)
  final String? unit;          // Optional unit annotation

  const ColumnDef({
    required this.name,
    required this.type,
    this.defaultValue,
    this.unit,
  });
}
```

### 1.3 DataType / FieldType Enum

Supported data types for schema definition.

**Reference**: [csv_ingestion_example.dart](reference_implementations/csv_ingestion_example.dart) line 30

```dart
// Simple version (from reference impl)
enum FieldType { float, integer, string }

// Full version (for production)
enum DataType {
  float32,    // Single precision (rendering)
  float64,    // Double precision (computation)
  int32,      // Integer values
  int64,      // Timestamps, large integers
  timestamp,  // ISO 8601 datetime strings → DateTime
  string,     // Categorical/text data
  boolean,    // Flag fields
}
```

**Design Decision**: Use `FieldType` for simple cases, `DataType` when precision matters.

### 1.4 DelimitedLoader

Async streaming CSV parser with schema validation.

```dart
abstract class DelimitedLoader {
  /// Load CSV file into a DataFrame structure
  static Future<DataFrame> load(
    String path,
    DelimitedSchema schema, {
    String delimiter = ',',
    bool hasHeader = true,
    int? skipRows,
  });

  /// Stream-based loading for large files
  static Stream<DataRow> stream(
    String path,
    DelimitedSchema schema,
  );
}
```

### 1.5 DataFrame

Tabular data container with column-oriented access.

**Reference**: [csv_ingestion_example.dart](reference_implementations/csv_ingestion_example.dart) lines 33-38

```dart
/// Columnar store - no per-row objects
class DataFrame {
  final Map<String, List<dynamic>> _columns;

  DataFrame(this._columns);

  /// Type-safe column access
  List<T> get<T>(String columnName) => _columns[columnName] as List<T>;

  /// Number of rows
  int get rowCount => _columns.values.first.length;

  /// Column names
  List<String> get columnNames => _columns.keys.toList();
}
```

**Extended version** with richer API:

```dart
class DataFrame {
  /// Access column by name (operator syntax)
  Column operator [](String name);

  /// Type-safe generic accessor
  List<T> get<T>(String columnName);

  /// Get the X-axis column (from schema.xColumn)
  Column get xColumn;

  /// Iterate rows (lazy, for streaming)
  Iterable<DataRow> get rows;
}

class Column<T> {
  final String name;
  final DataType type;
  final List<T> values;  // Or typed array for numerics
}
```

### 1.6 Series.fromColumns()

Extract Series from DataFrame columns with zero-copy semantics.

```dart
extension SeriesFromDataFrame<TX, TY> on Series<TX, TY> {
  /// Create Series from DataFrame columns
  static Series<TX, TY> fromColumns({
    required String id,
    required Column<TX> x,
    required Column<TY> y,
    AxisDomain<TX>? xDomain,
    AxisDomain<TY>? yDomain,
    SeriesMeta? meta,
  });
}
```

---

## 2. Domain Metadata System

**Priority**: MEDIUM  
**Proposal Reference**: §2A The Series (Logical)

### 2.1 AxisDomain

Semantic domain definition for axes with units and constraints.

```dart
class AxisDomain<T> {
  final String? label;
  final String? unit;
  final Range<T>? limits;  // Optional min/max constraints

  /// Time-based domain (seconds, milliseconds, microseconds)
  factory AxisDomain.time({TimeUnit unit = TimeUnit.seconds});

  /// Numeric domain with optional unit
  factory AxisDomain.numeric({String? unit, Range<double>? limits});

  /// Logarithmic domain (e.g., frequency in Hz)
  factory AxisDomain.log({String? unit, double base = 10});

  /// Categorical domain (discrete values)
  factory AxisDomain.categorical(List<String> categories);
}
```

### 2.2 TimeUnit Enum

```dart
enum TimeUnit {
  nanoseconds,
  microseconds,
  milliseconds,
  seconds,
  minutes,
  hours,
}
```

### 2.3 Range

Generic range type for domain limits.

```dart
class Range<T extends Comparable<T>> {
  final T min;
  final T max;

  Range(this.min, this.max);

  bool contains(T value);
  T clamp(T value);
}
```

---

## 3. Point Type Hierarchy

**Priority**: LOW  
**Proposal Reference**: §2C The Point Varieties

### 3.1 RawPoint

Simple (x, y) coordinate.

```dart
class RawPoint<TX, TY> {
  final TX x;
  final TY y;

  const RawPoint(this.x, this.y);
}
```

### 3.2 IntervalPoint

Aggregated bin with statistics for error bars/candlesticks.

```dart
class IntervalPoint<TX, TY extends num> {
  final TX xStart;
  final TX xEnd;
  final TY mean;
  final TY min;
  final TY max;
  final TY? stdDev;
  final int count;  // Number of source points

  /// Midpoint of the interval
  TX get xMid;
}
```

### 3.3 DistributionPoint

Quantile-based point for box plots.

```dart
class DistributionPoint<TX, TY extends num> {
  final TX x;
  final TY median;   // q50
  final TY q25;      // First quartile
  final TY q75;      // Third quartile
  final TY min;      // Whisker min (or q05)
  final TY max;      // Whisker max (or q95)
  final List<TY>? outliers;
}
```

---

## 4. Rendering Contract

**Priority**: HIGH  
**Proposal Reference**: §4 The Render-Ready Contract

### 4.1 RenderReadyData

GPU-optimized buffers for direct rendering.

```dart
class RenderReadyData {
  /// Float32 arrays for GPU upload or Canvas path
  final Float32List xCoordinates;
  final Float32List yCoordinates;

  /// Optional error band buffers
  final Float32List? yMin;
  final Float32List? yMax;

  /// Optional point flags (quality, status, selection)
  final Int8List? flags;

  /// Number of points
  int get length => xCoordinates.length;
}
```

### 4.2 Pipeline.toRenderSeries()

Convert pipeline output to render-ready format.

```dart
extension RenderOutput<TX, TY> on Pipeline<TX, TY> {
  /// Execute pipeline and convert to render-ready format
  RenderReadyData toRenderSeries(Series<TX, TY> input);
}
```

---

## 5. Window Enhancements

**Priority**: HIGH  
**Proposal Reference**: §3 Aggregation

### 5.1 Duration-Based Windows

Current implementation uses count-based windows. Need duration-based for time-series.

**Reference**: [csv_ingestion_example.dart](reference_implementations/csv_ingestion_example.dart) lines 47-87

```dart
sealed class WindowSpec {
  // EXISTING (count-based)
  factory WindowSpec.fixed(int size);
  factory WindowSpec.rolling(int size, {int step = 1});

  // NEW (duration-based) - from reference impl
  factory WindowSpec.fixedDuration(Duration duration);
  factory WindowSpec.rollingDuration(Duration duration, {Duration? step});

  // NEW (adaptive)
  factory WindowSpec.pixelAligned(double pixels, Range<TX> visibleRange);
  factory WindowSpec.distinctX();  // Group by unique X values
}
```

**Rolling Pipeline** from reference:

```dart
class RollingPipeline {
  final Series<dynamic, double> source;
  final Duration window;
  final WindowAlignment align;

  RollingPipeline(this.source, this.window, this.align);

  /// Apply a Reducer to the rolling window to create a new Series
  Series<double, double> reduce(SeriesReducer<double> reducer) {
    final inputY = source.storage.yAsList;
    final int winSize = window.inSeconds;
    final outY = <double>[];
    final outX = <double>[];

    // Trailing Window Logic
    for (int i = 0; i < inputY.length; i++) {
      final int start = max(0, i - winSize + 1);
      final int end = i + 1;
      final windowData = inputY.sublist(start, end);
      outY.add(reducer.reduce(windowData));
      outX.add(i.toDouble());
    }

    return ConcreteSeries(
        id: '${source.id}_rolling_$winSize', xData: outX, yData: outY);
  }
  start,   // Point T represents [T, T+Size]
  center,  // Point T represents [T-Size/2, T+Size/2]
  end,     // Point T represents [T-Size, T] (trailing, real-time default)
}
```

Update WindowSpec to accept alignment:

```dart
factory WindowSpec.rolling(
  int size, {
  int step = 1,
  WindowAlignment alignment = WindowAlignment.end,
});
```

---

## 6. Additional Reducers

**Priority**: MEDIUM  
**Proposal Reference**: §3.3 Extensible Metric System

### 6.1 Missing Built-in Reducers

```dart
abstract class SeriesReducer<T> {
  // EXISTING
  static const mean = MeanReducer();
  static const max = MaxReducer();
  static const min = MinReducer();
  static const sum = SumReducer();

  // NEW - OHLC support
  static const first = FirstReducer();
  static const last = LastReducer();

  // NEW - Distribution
  static SeriesReducer<double> quantile(double p);  // e.g., quantile(0.95)
  static const median = MedianReducer();  // quantile(0.5) shorthand

  // NEW - Variability
  static const stdDev = StdDevReducer();
  static const variance = VarianceReducer();

  // NEW - Count
  static const count = CountReducer();
}
```

### 6.2 Multi-Reducer Aggregation

Compute multiple statistics in a single pass.

```dart
class MultiReducerSpec {
  final Set<SeriesReducer> reducers;

  MultiReducerSpec(this.reducers);
}

// Returns IntervalPoint with all computed stats
Series<TX, IntervalPoint<TX, TY>> aggregateMulti(
  Series<TX, TY> input,
  WindowSpec window,
  MultiReducerSpec reducers,
);
```

---

## 7. Downsampling: LTTB

**Priority**: MEDIUM  
**Proposal Reference**: §3 Binning vs. Downsampling

### 7.1 LTTB Algorithm

Largest Triangle Three Buckets - visually faithful reduction.

```dart
abstract class Downsampler<TX, TY> {
  Series<TX, TY> downsample(Series<TX, TY> input, int targetPoints);
}

class LTTBDownsampler<TX extends num, TY extends num>
    implements Downsampler<TX, TY> {
  @override
  Series<TX, TY> downsample(Series<TX, TY> input, int targetPoints);
}
```

### 7.2 Pipeline Integration

```dart
extension DownsampleOperator<TX, TY> on Pipeline<TX, TY> {
  /// Reduce to N points using LTTB algorithm
  Pipeline<TX, TY> downsample(int targetPoints);
}
```

---

## 8. Multi-Resolution Pyramid

**Priority**: LOW  
**Proposal Reference**: §5A High-Frequency Sensor

### 8.1 SeriesPyramid

Hierarchical LOD structure for zoom-based rendering.

```dart
class SeriesPyramid<TX, TY> {
  /// Access level by index (0 = raw, higher = more aggregated)
  Series<TX, TY> getLevel(int level);

  /// Get appropriate level for pixel density
  Series<TX, TY> getLevelForPixels(double availablePixels, Range<TX> range);

  /// Number of levels
  int get levelCount;

  /// Build pyramid from raw series
  factory SeriesPyramid.build(
    Series<TX, TY> raw, {
    List<int> levelSizes,  // e.g., [1000, 100, 10] points per level
    SeriesReducer reducer = SeriesReducer.mean,
  });
}
```

---

## 9. Metrics Interface

**Priority**: LOW  
**Proposal Reference**: §3.3 The Metric Interface

### 9.1 SeriesMetric

Scalar calculation over entire series.

**Reference**: [power_metrics.dart](reference_implementations/power_metrics.dart) lines 16-21

```dart
/// The plugin interface for any scientific calculation
abstract class SeriesMetric<T> {
  const SeriesMetric();

  /// Calculate single value for entire series
  T calculate(Series<dynamic, double> series);
}
```

### 9.2 Built-in Metrics (from reference implementation)

**Reference**: [power_metrics.dart](reference_implementations/power_metrics.dart) lines 27-90

```dart
/// Normalized Power (NP)®
/// Algorithm: Mean of 4th powers of 30s-smoothed data, 4th rooted.
class NormalizedPowerMetric implements SeriesMetric<double> {
  final Duration windowSize;

  const NormalizedPowerMetric({this.windowSize = const Duration(seconds: 30)});

  @override
  double calculate(Series<dynamic, double> series) {
    final rawData = series.storage.yAsList;
    if (rawData.isEmpty) return 0.0;

    // 1. Smooth (SMA)
    final smoothed = _calculateSMA(rawData, windowSize.inSeconds);

    // 2. Weight (Pow 4)
    double sum4th = 0.0;
    for (final val in smoothed) {
      sum4th += pow(val, 4);
    }

    // 3. Average
    final avg4th = sum4th / smoothed.length;

    // 4. Scale (Root 4)
    return pow(avg4th, 0.25).toDouble();
  }
}

/// xPower
/// Algorithm: Mean of 4th powers of 25s-EWMA-smoothed data, 4th rooted.
class XPowerMetric implements SeriesMetric<double> {
  const XPowerMetric();

  @override
  double calculate(Series<dynamic, double> series) {
    final rawData = series.storage.yAsList;
    if (rawData.isEmpty) return 0.0;

    // 1. Smooth (EWMA) - Alpha ~ 1/26 for 25s window
    const alpha = 1.0 / 26.0;
    final smoothed = _calculateEWMA(rawData, alpha);

    // 2-4. Weight, Average, Scale
    double sum4th = 0.0;
    for (final val in smoothed) sum4th += pow(val, 4);
    return pow(sum4th / smoothed.length, 0.25).toDouble();
  }
}

/// Variability Index (VI) = NP / AveragePower
class VariabilityIndexMetric implements SeriesMetric<double> {
  const VariabilityIndexMetric();

  @override
  double calculate(Series<dynamic, double> series) {
    final rawData = series.storage.yAsList;
    if (rawData.isEmpty) return 0.0;

    final np = const NormalizedPowerMetric().calculate(series);
    final ap = rawData.reduce((a, b) => a + b) / rawData.length;

    if (ap == 0) return 0.0;
    return np / ap;
  }
}
```

### 9.3 Primitive Algorithms (SMA, EWMA)

**Reference**: [power_metrics.dart](reference_implementations/power_metrics.dart) lines 96-120

```dart
/// Simple Moving Average
List<double> _calculateSMA(List<double> data, int period) {
  final sma = <double>[];
  for (int i = 0; i < data.length; i++) {
    double sum = 0.0;
    int count = 0;
    final int start = max(0, i - period + 1);
    for (int j = start; j <= i; j++) {
      sum += data[j];
      count++;
    }
    sma.add(count > 0 ? sum / count : 0.0);
  }
  return sma;
}

/// Exponentially Weighted Moving Average
List<double> _calculateEWMA(List<double> data, double alpha) {
  final ewma = <double>[];
  if (data.isEmpty) return ewma;

  double current = data.first;
  ewma.add(current);

  for (int i = 1; i < data.length; i++) {
    current = alpha * data[i] + (1 - alpha) * current;
    ewma.add(current);
  }
  return ewma;
}
```

**Note**: These primitives already exist in Sprint 001's `algorithms.dart` as part of the calculators. The SeriesMetric interface provides a cleaner abstraction layer.

---

## 10. Series Factory Enhancements

**Priority**: MEDIUM  
**Proposal Reference**: §10 Sample API Usage

### 10.1 Series.fromLists()

Alternative factory with domain metadata.

```dart
extension SeriesFactories<TX, TY> on Series<TX, TY> {
  /// Create from parallel lists with domain metadata
  static Series<TX, TY> fromLists({
    required String id,
    required List<TX> x,
    required List<TY> y,
    AxisDomain<TX>? xDomain,
    AxisDomain<TY>? yDomain,
    SeriesMeta? meta,
  });
}
```

---

## 11. SeriesPipeline Enhancements

**Priority**: HIGH  
**Proposal Reference**: Reference implementations

### 11.1 Fluent Pipeline with Metric Computation

**Reference**: [csv_ingestion_example.dart](reference_implementations/csv_ingestion_example.dart) lines 40-53

```dart
class SeriesPipeline {
  final Series<dynamic, double> _source;

  SeriesPipeline(this._source);

  /// Apply a metric calculation (Scalar output)
  T compute<T>(SeriesMetric<T> metric) {
    return metric.calculate(_source);
  }

  /// Create a Rolling Window Pipeline (Series output)
  RollingPipeline rolling({
    required Duration window,
    WindowAlignment align = WindowAlignment.end,
  }) {
    return RollingPipeline(_source, window, align);
  }
}
```

### 11.2 Domain-Specific Extensions

**Reference**: [csv_ingestion_example.dart](reference_implementations/csv_ingestion_example.dart) lines 89-94

```dart
/// Extension to add "Syntax Sugar" for Power Metrics
extension PowerCalculations on SeriesPipeline {
  double calculateNormalizedPower() => compute(const NormalizedPowerMetric());
  double calculateXPower() => compute(const XPowerMetric());
  double calculateVariabilityIndex() => compute(const VariabilityIndexMetric());
}
```

**Usage**:

```dart
final pipeline = SeriesPipeline(powerSeries);

// Direct metric calculation
final np = pipeline.calculateNormalizedPower();

// Or via explicit metric
final vi = pipeline.compute(const VariabilityIndexMetric());
```

### 11.3 Rolling Pipeline with Named Reducers

**Reference**: [csv_ingestion_example.dart](reference_implementations/csv_ingestion_example.dart) lines 230-250

```dart
// Generate rolling average curve
final rollingAvg30 = pipeline
    .rolling(window: const Duration(seconds: 30))
    .reduce(const MeanReducer());

// Generate rolling NP curve (intensity)
final rollingNP30 = pipeline
    .rolling(window: const Duration(seconds: 30))
    .reduce(const NormalizedPowerReducer());
```

### 11.4 Gap vs Current Implementation

| Feature       | Current (PipelineBuilder)   | Proposed (SeriesPipeline)  |
| ------------- | --------------------------- | -------------------------- |
| Constructor   | `PipelineBuilder<TX, TY>()` | `SeriesPipeline(series)`   |
| Window type   | Count-based                 | Duration-based             |
| Alignment     | Not supported               | `WindowAlignment.end`      |
| Scalar output | `executeScalar()`           | `compute(metric)`          |
| Series output | `execute(series)`           | `rolling(...).reduce(...)` |
| Extensions    | None                        | Domain-specific sugar      |

**Design Decision**: Enhance existing `PipelineBuilder` or create new `SeriesPipeline` wrapper? Consider backwards compatibility.

---

## 12. Chart Output Layer (BravenChartPlus Integration)

**Priority**: HIGH  
**Proposal Reference**: Primary use case requirement

### 12.1 The Transformation Challenge

**Current `Series<TX, TY>`** stores:

- `xValues: List<TX>` (e.g., Int64 timestamps in milliseconds)
- `yValues: List<TY>` (e.g., Float64 power values)

**BravenChartPlus** expects:

- `List<ChartDataPoint>` with `x: double`, `y: double`, optional `timestamp: DateTime`

### 12.2 Series to ChartDataPoint Conversion

```dart
/// Convert processed Series to chart-ready format
extension ChartOutput<TX extends num, TY extends num> on Series<TX, TY> {
  /// Convert to BravenChartPlus data points
  List<ChartDataPoint> toChartDataPoints({
    /// Convert X values to elapsed time from first point (seconds)
    bool useElapsedTime = true,

    /// Include original timestamp in each point (for tooltips)
    bool includeTimestamp = true,

    /// Optional label for all points (series name)
    String? seriesLabel,

    /// X-axis time unit (when useElapsedTime = true)
    TimeUnit xUnit = TimeUnit.seconds,
  }) {
    final firstX = length > 0 ? getX(0) : 0;

    return List.generate(length, (i) {
      final rawX = getX(i);
      final x = useElapsedTime
          ? (rawX - firstX).toDouble() / xUnit.divisor
          : rawX.toDouble();

      return ChartDataPoint(
        x: x,
        y: getY(i).toDouble(),
        timestamp: includeTimestamp
            ? DateTime.fromMillisecondsSinceEpoch(rawX.toInt())
            : null,
        label: seriesLabel,
      );
    });
  }
}
```

### 12.3 DataFrame to Chart Series (High-Level API)

```dart
/// High-level convenience: DataFrame → Chart Series
extension ChartDataFrameOutput on DataFrame {
  /// Extract a column as chart-ready points with optional processing
  List<ChartDataPoint> toChartSeries(
    String yColumn, {
    /// Apply rolling mean smoothing
    Duration? smooth,

    /// Target point count for LTTB downsampling
    int? downsampleTo,

    /// Include min/max in metadata for error bands
    bool includeMinMax = false,

    /// Series label
    String? label,
  });
}
```

### 12.4 Multi-Series Extraction

One CSV produces multiple chart series:

```dart
final table = await DelimitedLoader.load('garmin.csv', schema);

// Extract multiple series for different chart panels
final powerPoints = table.toChartSeries(
  'power',
  smooth: Duration(seconds: 30),
  label: 'Power (30s avg)',
);

final hrPoints = table.toChartSeries(
  'heart_rate',
  smooth: Duration(seconds: 5),
  label: 'Heart Rate',
);

final altitudePoints = table.toChartSeries(
  'altitude',  // Raw, no smoothing
  label: 'Altitude',
);
```

### 12.5 Error Bands / Min-Max Metadata

For aggregated data showing variability:

```dart
ChartDataPoint(
  x: 60.0,           // 60 seconds elapsed
  y: 200.0,          // Mean power in window
  metadata: {
    'yMin': 150.0,   // Min in window
    'yMax': 280.0,   // Max in window
    'stdDev': 35.0,  // Standard deviation
    'count': 30,     // Points in window
  },
)
```

This enables rendering error bands or confidence intervals in BravenChartPlus.

### 12.6 Downsampling for Large Datasets

A 4-hour ride at 1Hz = 14,400 points. Options:

| Strategy      | Method              | Use Case              |
| ------------- | ------------------- | --------------------- |
| Fixed binning | 1 point per 10s     | Scientific accuracy   |
| LTTB          | Visual preservation | Sparklines, overviews |
| Pixel-aligned | Match screen width  | Responsive rendering  |

```dart
extension Downsampling on List<ChartDataPoint> {
  /// LTTB downsampling to target point count
  List<ChartDataPoint> downsample(int targetPoints);

  /// Fixed time binning
  List<ChartDataPoint> binByDuration(Duration binSize, SeriesReducer reducer);
}
```

---

## 13. Open Design Questions

The following questions require resolution before implementation:

### Q1: X-Axis Time Representation ✅ RESOLVED

For time-series charting, what should `ChartDataPoint.x` contain?

**Decision**: **Option B - Elapsed time with configurable TimeUnit**

- Default: elapsed seconds from first data point (preserves gaps)
- Fractional seconds for sub-second precision (10kHz data → 0.0, 0.0001, ...)
- `timestamp` field preserves original absolute DateTime for tooltips
- Configurable `TimeUnit` for very long datasets (minutes/hours)

```dart
enum TimeUnit {
  milliseconds,  // High-frequency data
  seconds,       // Default for most use cases
  minutes,       // Multi-hour datasets
  hours,         // Multi-day datasets
}

series.toChartDataPoints(
  useElapsedTime: true,
  timeUnit: TimeUnit.seconds,  // Default
)
```

**Status**: ✅ DECIDED (2026-01-22)

### Q2: Package Dependency Direction ✅ RESOLVED

Should `braven_data` depend on `braven_charts`, or vice versa?

**Decision**: **No external dependencies, local type copy + generic output**

1. **braven_charts** has NO dependency on braven_data
2. **braven_data** has NO dependency on braven_charts
3. **braven_data** includes a local copy of `ChartDataPoint` at `lib/src/chart_data_point.dart`
   - Source: `specs/_base/002-data-enchancements/reference_implementations/chart_data_point.dart`
   - If braven_charts changes ChartDataPoint, manual sync required
4. **Generic output** mechanisms for other consumers:

```dart
// Typed output for BravenChartPlus
List<ChartDataPoint> toChartDataPoints();

// Generic output for any consumer
List<Map<String, dynamic>> toMapList();  // [{x: 0.0, y: 200.0, timestamp: ...}]
List<({double x, double y})> toRecords(); // Dart 3 records
Iterable<(double, double)> toTuples();    // Minimal tuple iteration
```

**Rationale**: Core of ChartDataPoint is just `(double x, double y)`. No need for complex dependency management. Manual sync is acceptable for a stable, rarely-changing type.

**Status**: ✅ DECIDED (2026-01-22)

### Q3: Streaming vs Batch Processing ✅ RESOLVED

For very large files (10M+ points), support streaming?

**Decision**: **Batch only, streaming out of scope for now**

- Typical use case: Single activity files (even 60-hour events ≈ 200K rows)
- Live streaming from devices: Out of scope (braven_charts handles direct streaming)
- This package is a **data pre-processor**, not a real-time streaming engine

**However**: Data structures MUST be efficient for high-frequency datasets:

| Scenario         | Sample Rate | Duration | Points  | Memory (Float64) |
| ---------------- | ----------- | -------- | ------- | ---------------- |
| Cycling activity | 1 Hz        | 8 hours  | 28,800  | ~450 KB          |
| Long event       | 1 Hz        | 60 hours | 216,000 | ~3.4 MB          |
| High-freq burst  | 1 kHz       | 2 min    | 120,000 | ~1.9 MB          |

**Efficiency requirements** (already met by Sprint 001):

- `TypedDataStorage` using `Float64List`/`Int64List` ✓
- No object-per-point overhead ✓
- Cache-friendly columnar layout ✓
- ~16 bytes per point (8 bytes X + 8 bytes Y)

**Future**: If live streaming from devices is needed, spec separately.

**Status**: ✅ DECIDED (2026-01-22)

### Q4: X-Value Parsing Strategy ✅ RESOLVED

X-axis values in CSVs can be ANY format - not just ISO8601 timestamps.

**Decision**: **Parse during load with explicit schema OR smart auto-detection**

**Supported X-Value Types:**

| Type             | Example                      | Internal Storage           |
| ---------------- | ---------------------------- | -------------------------- |
| `iso8601`        | `"2025-10-26T13:23:17Z"`     | epoch μs → elapsed seconds |
| `epochSeconds`   | `1698325397`                 | direct → elapsed seconds   |
| `epochMillis`    | `1698325397000`              | ÷1000 → elapsed seconds    |
| `elapsedSeconds` | `0, 1, 2, 3...`              | direct (already elapsed)   |
| `elapsedMillis`  | `0, 1000, 2000...`           | ÷1000 → elapsed seconds    |
| `rowIndex`       | (none - use row #)           | row number as X            |
| `custom`         | `"10:23:17"`, `"2025/10/26"` | user-provided parser       |

**Schema-Based (Explicit):**

```dart
DelimitedSchema(
  xColumn: 'timestamp',
  xType: XValueType.iso8601,  // explicit type
  xFormat: null,              // for custom: DateFormat pattern
)
```

**Auto-Detection Heuristics (Fallback):**

1. Matches ISO8601 pattern (`\d{4}-\d{2}-\d{2}T`) → `iso8601`
2. Integer in epoch range (1e9 to 2e9) → `epochSeconds`
3. Integer in epoch-millis range (1e12 to 2e12) → `epochMillis`
4. Incrementing integers starting near 0 → `elapsedSeconds`
5. Contains `:` but no date separators → time-only (elapsed from midnight)
6. Fallback → `rowIndex`

**Internal Canonical Form:**

- Always store X as `Float64List` of elapsed seconds from first point
- Preserve original first timestamp in `Series` metadata for absolute time reconstruction

**Status**: ✅ DECIDED (2026-01-22)

### Q5: IntervalStorage vs ChartDataPoint Metadata ✅ RESOLVED

How to represent aggregated windows?

**Decision**: **Option A - Keep typed `IntervalStorage` internally, convert at output**

**Internal Representation (Type-Safe):**

```dart
/// Rich interval data with full statistics
class IntervalStorage {
  final Float64List xMidpoints;  // window center
  final Float64List yValues;     // aggregated value (mean, sum, etc.)
  final Float64List? yMin;       // optional: min in window
  final Float64List? yMax;       // optional: max in window
  final Int32List? sampleCount;  // optional: points per window
}
```

**Output Conversion (At Boundary):**

```dart
List<ChartDataPoint> toChartDataPoints({
  bool includeMinMax = false,  // pack into metadata
  TimeUnit xUnit = TimeUnit.seconds,
}) {
  return [
    for (var i = 0; i < length; i++)
      ChartDataPoint(
        x: xMidpoints[i] / xUnit.divisor,
        y: yValues[i],
        metadata: includeMinMax ? {
          'min': yMin?[i],
          'max': yMax?[i],
          'count': sampleCount?[i],
        } : null,
      ),
  ];
}
```

**Why Option A:**

- Type-safe internals (no `Map<String, dynamic>` until the very end)
- Efficient columnar storage during processing
- Conversion happens once at output boundary
- Chart layer decides what metadata it wants

**Status**: ✅ DECIDED (2026-01-22)

---

## Implementation Priority Matrix

| Feature                           | Priority | Complexity | Dependencies     | Reference                  |
| --------------------------------- | -------- | ---------- | ---------------- | -------------------------- |
| **Chart Output Layer**            | **HIGH** | **Medium** | Series           | **chart_data_point.dart**  |
| Series.toChartDataPoints()        | HIGH     | Low        | ChartDataPoint   | chart_data_point.dart      |
| DataFrame.toChartSeries()         | HIGH     | Medium     | DataFrame, Chart | chart_data_point.dart      |
| Duration-Based Windows            | HIGH     | Medium     | None             | csv_ingestion_example.dart |
| DelimitedSchema + DelimitedLoader | HIGH     | High       | DataFrame        | csv_ingestion_example.dart |
| DataFrame                         | HIGH     | Medium     | DataType         | csv_ingestion_example.dart |
| SeriesPipeline.compute()          | HIGH     | Low        | SeriesMetric     | csv_ingestion_example.dart |
| SeriesMetric interface            | HIGH     | Low        | None             | power_metrics.dart         |
| RollingPipeline                   | HIGH     | Medium     | WindowAlignment  | csv_ingestion_example.dart |
| WindowAlignment                   | MEDIUM   | Low        | None             | csv_ingestion_example.dart |
| Additional Reducers               | MEDIUM   | Low        | None             | power_metrics.dart         |
| Series.fromColumns()              | MEDIUM   | Low        | DataFrame        | csv_test_scenario.dart     |
| Power Extensions                  | MEDIUM   | Low        | SeriesMetric     | csv_ingestion_example.dart |
| LTTB Downsampler                  | MEDIUM   | Medium     | None             | proposal                   |
| Multi-Reducer                     | MEDIUM   | Medium     | IntervalPoint    | csv_test_scenario.dart     |
| AxisDomain                        | MEDIUM   | Low        | None             | proposal                   |
| IntervalPoint                     | LOW      | Low        | None             | proposal                   |
| DistributionPoint                 | LOW      | Low        | None             | proposal                   |
| SeriesPyramid                     | LOW      | High       | None             | proposal                   |

---

## Suggested Sprint Structure

### Sprint 002: CSV Ingestion & Chart Output

**Goal**: Complete the end-to-end data flow from CSV to chart-ready output.

1. `FieldType` / `DataType` enum
2. `ColumnDef` class
3. `DelimitedSchema` class
4. `DataFrame` class with columnar storage
5. `DelimitedLoader.load()` static method
6. `Series.fromColumns()` factory
7. `Series.toChartDataPoints()` extension
8. `DataFrame.toChartSeries()` convenience method
9. Integration test with sample Garmin CSV → ChartDataPoint[]

### Sprint 003: Pipeline Enhancements & Metrics

**Goal**: Align pipeline API with reference implementations.

1. `SeriesMetric<T>` interface in `lib/src/metrics.dart`
2. `NormalizedPowerMetric`, `XPowerMetric`, `VariabilityIndexMetric` implementations
3. `SeriesPipeline` wrapper class with `compute()` method
4. Duration-based `WindowSpec` factories (`.fixedDuration()`, `.rollingDuration()`)
5. `WindowAlignment` enum (start, center, end)
6. `RollingPipeline` class with alignment support
7. Power calculation extension methods
8. Update existing algorithms to use SeriesMetric interface

### Sprint 004: Advanced Features

**Goal**: Additional processing and rendering features.

1. `AxisDomain<T>` class
2. Additional reducers (first, last, stdDev, quantile)
3. Multi-reducer aggregation (returns IntervalPoint)
4. LTTB downsampling algorithm
5. IntervalPoint / DistributionPoint types
6. `DelimitedLoader.stream()` for large files

### Sprint 005 (Optional): LOD System

**Goal**: Handle very large datasets.

1. `SeriesPyramid` class
2. Automatic level-of-detail selection
3. Zoom-based data fetching

---

## Test Data Available

The project includes real-world test data in `data/`:

```
data/tp-2023646.2025-10-26-13-23-16-784Z.GarminPing.AAAAAGj-IMQ_uYSx_core_records.csv
```

This can be used for integration testing of the CSV ingestion layer.

---

## 12. Real-World Usage Example

**Reference**: [csv_ingestion_example.dart](reference_implementations/csv_ingestion_example.dart) lines 201-260

Complete end-to-end workflow demonstrating the target API:

```dart
void main() async {
  // A. DEFINE SCHEMA
  // Matches: data/tp-2023646...core_records.csv
  const schema = DelimitedSchema(dateColumn: 'timestamp', columns: [
    ColumnDef('power', FieldType.float),
    ColumnDef('heart_rate', FieldType.integer),
  ]);

  // B. LOAD DATA
  final table = await DelimitedLoader.load('garmin_data.csv', schema);
  print("Loaded DataFrame with ${table.get('power').length} rows.");

  // C. EXTRACT SERIES
  final timeBuffer = table
      .get<DateTime>('timestamp')
      .map((dt) => dt.millisecondsSinceEpoch.toDouble())
      .toList();

  final powerSeries = Series.fromTypedData(
    id: 'cycling_power',
    xValues: timeBuffer,
    yValues: table.get<double>('power'),
  );

  // D. APPLY SCIENTIFIC CALCULATIONS (SCALARS)
  final pipeline = SeriesPipeline(powerSeries);
  final np = pipeline.calculateNormalizedPower();
  print('Metric: Normalized Power (NP): ${np.toStringAsFixed(1)} W');

  // E. GENERATE PLOTTING DATA (SERIES)
  // "I want to see the 30s average power curve over time"

  // Rolling 30s Average
  final rollingAvg30 = pipeline
      .rolling(window: const Duration(seconds: 30))
      .reduce(const MeanReducer());

  print("Generated '${rollingAvg30.id}' with ${rollingAvg30.length} points.");

  // Rolling 30s NP (Intensity curve)
  final rollingNP30 = pipeline
      .rolling(window: const Duration(seconds: 30))
      .reduce(const NormalizedPowerReducer());

  print("Generated '${rollingNP30.id}' with ${rollingNP30.length} points.");
}
```

---

## 15. Additional Scientific Features (from Chat History)

**Source**: Original conversation (pre-repository move) - captured in `chat-history.md`

These features were discussed in the original API design session but were not included in earlier sections of this spec:

### 15.1 Quality Flags

Per-point data quality annotations for scientific rigor.

**Priority**: LOW  
**Use Case**: Lab data, sensor streams with calibration issues

```dart
/// Quality flag for individual data points
enum PointQuality {
  valid,      // Normal measurement
  missing,    // Data gap (sensor dropout)
  outlier,    // Statistically anomalous (auto-detected or manual)
  censored,   // Below/above detection limits (LOD/LOQ)
  estimated,  // Interpolated or modeled value
}

/// Optional quality layer on Series
class QualityFlags {
  final Int8List flags;  // One byte per point

  bool isValid(int index) => flags[index] == PointQuality.valid.index;
  List<int> get invalidIndices => [...];
}
```

### 15.2 Weighted Metrics

Handle heterogeneous data with varying importance/reliability.

**Priority**: LOW  
**Use Case**: Combining data from sensors with different sample rates or confidence levels

```dart
class WeightedMeanReducer extends SeriesReducer<double> {
  final List<double> weights;

  const WeightedMeanReducer(this.weights);

  @override
  double reduce(List<double> values) {
    var sum = 0.0;
    var weightSum = 0.0;
    for (var i = 0; i < values.length; i++) {
      sum += values[i] * weights[i];
      weightSum += weights[i];
    }
    return sum / weightSum;
  }
}
```

### 15.3 Unit Conversion

Axis-level unit transforms with automatic label updates.

**Priority**: MEDIUM  
**Use Case**: Display data in user-preferred units (m/s ↔ km/h, Celsius ↔ Fahrenheit)

```dart
abstract class UnitConverter {
  double convert(double value);
  String get fromUnit;
  String get toUnit;
}

class SpeedConverter implements UnitConverter {
  // m/s → km/h: value * 3.6
  @override
  double convert(double value) => value * 3.6;

  @override
  String get fromUnit => 'm/s';
  @override
  String get toUnit => 'km/h';
}

extension UnitConversion<TX, TY extends num> on Series<TX, TY> {
  Series<TX, double> convertUnits(UnitConverter converter);
}
```

### 15.4 Savitzky-Golay Filter

Polynomial smoothing that preserves peak shapes.

**Priority**: LOW  
**Use Case**: Scientific signal processing (better than moving average for spectral data)

```dart
class SavitzkyGolayFilter {
  final int windowSize;  // Must be odd
  final int polynomialOrder;

  const SavitzkyGolayFilter({
    this.windowSize = 5,
    this.polynomialOrder = 2,
  });

  List<double> apply(List<double> input);
}

extension SmoothingOperators<TX> on Pipeline<TX, double> {
  Pipeline<TX, double> savitzkyGolay({
    int windowSize = 5,
    int polynomialOrder = 2,
  });
}
```

### 15.5 Additional Reducers

Missing statistical reducers for comprehensive analysis.

**Priority**: MEDIUM

```dart
/// Median Absolute Deviation - robust dispersion measure
class MADReducer extends SeriesReducer<double> {
  @override
  double reduce(List<double> values) {
    final sorted = [...values]..sort();
    final median = sorted[sorted.length ~/ 2];
    final deviations = values.map((v) => (v - median).abs()).toList()..sort();
    return deviations[deviations.length ~/ 2];
  }
}

/// First/Last for OHLC data
class FirstReducer<T> extends SeriesReducer<T> {
  @override
  T reduce(List<T> values) => values.first;
}

class LastReducer<T> extends SeriesReducer<T> {
  @override
  T reduce(List<T> values) => values.last;
}

/// Count points in window
class CountReducer extends SeriesReducer<int> {
  @override
  int reduce(List<dynamic> values) => values.length;
}

/// Quantile reducer
class QuantileReducer extends SeriesReducer<double> {
  final double percentile;  // 0.0 - 1.0

  const QuantileReducer(this.percentile);

  @override
  double reduce(List<double> values) {
    final sorted = [...values]..sort();
    final index = (percentile * (sorted.length - 1)).round();
    return sorted[index];
  }
}
```

### 15.6 Group-By Aggregation

Aggregate by category, time-bucket, or axis ranges.

**Priority**: MEDIUM  
**Use Case**: "Show average power per lap", "Group by altitude zone"

```dart
extension GroupByOperations<TX, TY> on Series<TX, TY> {
  /// Group by time buckets (e.g., every 5 minutes)
  Map<TX, Series<TX, TY>> groupByTime(Duration bucket);

  /// Group by category column (requires DataFrame context)
  Map<String, Series<TX, TY>> groupByCategory(String categoryColumn);

  /// Group by Y value ranges (e.g., power zones)
  Map<Range<TY>, Series<TX, TY>> groupByRange(List<Range<TY>> ranges);
}
```

### 15.7 Range Query Indexing

Binary search / interval tree for fast zoomed range queries.

**Priority**: LOW  
**Use Case**: Large datasets with interactive zoom (millions of points)

```dart
/// Indexed series with O(log n) range lookups
class IndexedSeries<TX extends Comparable<TX>, TY> {
  final Series<TX, TY> _data;
  final List<int> _sortedXIndices;  // Pre-computed sort order

  /// Get indices for points in range [start, end)
  (int startIdx, int endIdx) getRange(TX start, TX end);

  /// Get series slice for visible range
  Series<TX, TY> sliceRange(TX start, TX end);
}
```

---

## 16. Implementation Priority Summary

| Priority   | Features                                                                                                                                                      |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **HIGH**   | CSV Layer (§1), Duration Windows (§5), Chart Output (§12), X-Value Parsing (Q4)                                                                               |
| **MEDIUM** | Domain Metadata (§2), Additional Reducers (§6, §15.5), Unit Conversion (§15.3), Group-By (§15.6)                                                              |
| **LOW**    | Point Types (§3), LTTB (§7), Pyramid (§8), SeriesMetric (§9), Quality Flags (§15.1), Weighted Metrics (§15.2), Savitzky-Golay (§15.4), Range Indexing (§15.7) |

---

## References

### Design Documents

- [data_input_api_proposal.md](../../001-data-input/data_input_api_proposal.md) - Original comprehensive design
- [spec.md](../../001-data-input/spec.md) - Sprint 001 specification
- [tasks.md](../../001-data-input/tasks.md) - Sprint 001 task breakdown
- [chat-history.md](chat-history.md) - Original conversation (pre-repository)

### Reference Implementations (in this folder)

- [csv_test_scenario.dart](csv_test_scenario.dart) - API usage sketch (schema, pipeline, multi-reducer)
- [reference_implementations/csv_ingestion_example.dart](reference_implementations/csv_ingestion_example.dart) - End-to-end CSV ingestion with DataFrame, SeriesPipeline, rolling windows
- [reference_implementations/power_metrics.dart](reference_implementations/power_metrics.dart) - SeriesMetric interface, NP/xPower/VI implementations, SMA/EWMA algorithms

### Test Data

- [data/tp-2023646...csv](../../data/tp-2023646.2025-10-26-13-23-16-784Z.GarminPing.AAAAAGj-IMQ_uYSx_core_records.csv) - Real Garmin cycling data for integration tests
