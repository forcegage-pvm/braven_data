# braven_data API Reference

This document provides a comprehensive reference for the `braven_data` library, a high-performance scientific data processing toolkit for Dart. It covers the core components, their methods, and usage patterns.

## Table of Contents

1.  [Core Concepts](#core-concepts)
2.  [Series](#series)
3.  [DataFrame](#dataframe)
4.  [CSV Loading](#csv-loading)
5.  [FIT Loading](#fit-loading)
6.  [Aggregation Engine](#aggregation-engine)
7.  [Pipeline](#pipeline)
8.  [Metrics](#metrics)
9.  [Output](#output)

---

## Core Concepts

`braven_data` is designed for efficient handling of time-series and scientific data. The architecture revolves around:

- **Typed Storage**: Using `Float64List`, `Int64List`, and other typed buffers for memory efficiency.
- **Series**: The fundamental unit of data, representing a sequence of X/Y pairs.
- **Pipeline**: A fluent API for transforming and aggregating data steps.
- **Aggregation**: High-performance downsampling and windowing.

---

## Series

`Series<TX, TY>` is the primary container for data. It manages typed storage for X (domain) and Y (range) values.

### Class: `Series<TX, TY>`

#### Constructors

```dart
// Create from typed lists (automatically selects storage backend)
factory Series.fromTypedData({
  String? id,                // Optional unique ID (auto-generated if null)
  required SeriesMeta meta,  // Metadata (name, unit)
  required List<TX> xValues, // List of X values
  required List<TY> yValues, // List of Y values
  SeriesStats? stats,        // Optional precomputed stats
})
```

#### Properties

- `id` (`String`): Unique identifier.
- `meta` (`SeriesMeta`): Metadata including name and unit.
- `stats` (`SeriesStats?`): Precomputed statistics (min, max, mean, count).
- `length` (`int`): Number of data points.

#### Methods

- `TX getX(int index)`: Returns the X value at the specified index.
- `TY getY(int index)`: Returns the Y value at the specified index.
- `Series<TX, TY> transform(Pipeline<TX, TY> pipeline)`: Applies a transformation pipeline.
- `Series<TX, TY> aggregate(AggregationSpec<TX> spec)`: Aggregates the series into windowed values.
- `Series<TX, TY> slice(int start, [int? end])`: Returns a subset of the series.

#### Example

```dart
final series = Series<double, double>.fromTypedData(
  meta: const SeriesMeta(name: 'Power', unit: 'W'),
  xValues: [0.0, 1.0, 2.0],
  yValues: [100.0, 200.0, 150.0],
);

print(series.getY(1)); // 200.0
```

### Class: `SeriesMeta`

Describes the series.

- `name` (`String`): Display name.
- `unit` (`String?`): Unit of measurement (e.g., 'W', 'bpm').

---

## DataFrame

`DataFrame` is a columnar container derived from tabular sources (CSV, FIT).

### Class: `DataFrame`

#### Properties

- `rowCount` (`int`): Number of rows.
- `columnNames` (`List<String>`): Names of available columns.
- `schema` (`DataSchema`): The schema used to parse the data.

#### Methods

- `List<T> get<T>(String columnName)`: Returns column data as a typed list.
- `List<double> getXValues()`: Returns parsed X values based on the schema configuration.
- `Series<double, double> toSeries(String yColumn, {SeriesMeta? meta})`: Extracts a column as a `Series`.

#### Example

```dart
final df = DelimitedLoader.loadString(csvContent, schema);
final powerSeries = df.toSeries('power');
```

---

## CSV Loading

Provides tools for parsing delimited text files.

### Class: `DelimitedLoader`

#### Methods

- `static DataFrame loadString(String content, DelimitedSchema schema, {String? delimiter})`: Parses a CSV string.

### Class: `DelimitedSchema`

Defines the structure of a CSV file.

- `xColumn` (`String?`): Name of the column representing the X axis.
- `xType` (`XValueType`): format of the X column (e.g., `iso8601`, `epochSeconds`).
- `columns` (`List<ColumnDef>`): Definitions for value columns.
- `delimiter` (`String`): Field separator (default `,`).
- `hasHeader` (`bool`): Whether the file contains a header row (default `true`).

#### Example

```dart
final schema = DelimitedSchema(
  xColumn: 'timestamp',
  xType: XValueType.iso8601,
  columns: [
    ColumnDef(name: 'power', type: FieldType.float64, unit: 'W'),
  ],
);
final df = DelimitedLoader.loadString(csvString, schema);
```

---

## FIT Loading

Provides tools for parsing Garmin FIT files.

### Class: `FitLoader`

#### Methods

- `static Future<DataFrame> load(String path, FitMessageType messageType, {FitSchema? schema})`: Loads a FIT file from disk.
- `static DataFrame loadBytes(Uint8List bytes, FitMessageType messageType, {FitSchema? schema})`: Loads FIT content from memory.

### Enum: `FitMessageType`

- `records`: Time-series record messages.
- `laps`: Lap summary messages.
- `sessions`: Session summary messages.

#### Example

```dart
final records = await FitLoader.load('activity.fit', FitMessageType.records);
final powerSeries = records.toSeries('power');
```

---

## Aggregation Engine

Handles data reduction and windowing.

### Class: `AggregationEngine`

- `static AggregationResult<TX, TY> aggregate(Series<TX, TY> series, AggregationSpec<TX> spec)`: Performs aggregation.

### Class: `AggregationSpec<TX>`

Configuration for aggregation.

- `window` (`WindowSpec`): The windowing strategy.
- `reducer` (`SeriesReducer`): The reduction function.
- `alignment` (`WindowAlignment`): X-axis alignment (start, center, end).

### Class: `WindowSpec`

- `fixed(num size)`: Non-overlapping fixed point count.
- `rolling(num size)`: Overlapping sliding window (points).
- `fixedDuration(Duration duration)`: Non-overlapping time (requires inferred sample rate).
- `rollingDuration(Duration duration)`: Overlapping time window.
- `pixelAligned(double pixelDensity)`: For visualization.

### Class: `SeriesReducer`

Abstract base for reduction logic.

- `SeriesReducer.mean`: Arithmetic mean.
- `SeriesReducer.max`: Maximum value.
- `SeriesReducer.min`: Minimum value.
- `SeriesReducer.sum`: Sum of values.

Custom reducers can be implemented by extending `SeriesReducer<T>`.

#### Example

```dart
// 30-second rolling average
final smoothed = series.aggregate(
  AggregationSpec(
    window: WindowSpec.rollingDuration(const Duration(seconds: 30)),
    reducer: SeriesReducer.mean,
  ),
);
```

---

## Pipeline

A fluent API for chaining transformations.

### Class: `PipelineBuilder<TX, TY>`

#### Methods

- `map(Mapper<TY> mapper)`: Element-wise transformation.
- `window(WindowSpec window, SeriesReducer<TY> reducer)`: Non-overlapping aggregation.
- `rolling(WindowSpec window, SeriesReducer<TY> reducer)`: Rolling aggregation.
- `collapse(SeriesReducer<TY> reducer)`: Reduces entire series to a scalar.
- `execute(Series<TX, TY> input)`: returns transformed `Series`.
- `executeScalar(Series<TX, TY> input)`: returns single value.

#### Example

```dart
// Calculate NP manually: Window -> Pow4 -> Mean -> Root4
final meanPower4 = PipelineBuilder<double, double>()
    .rolling(WindowSpec.rolling(30), SeriesReducer.mean)
    .map((v) => pow(v, 4).toDouble())
    .collapse(SeriesReducer.mean)
    .executeScalar(series);
final np = pow(meanPower4, 0.25);
```

---

## Algorithms & Advanced Calculations

`braven_data` includes specialized calculators and architectural support for custom algorithms.

### Dedicated Calculators

These classes encapsulate complex pipeline operations for common scientific metrics.

#### `NormalizedPowerCalculator`

Computes Normalized Power (NP) using a 4th-power weighted rolling average.

- **Constructor**: `NormalizedPowerCalculator({int windowSize = 30})`
- **Method**: `double calculate(Series<TX, double> series)`

#### `xPowerCalculator`

Computes xPower using an Exponential Weighted Moving Average (EWMA) instead of a simple rolling mean.

- **Constructor**: `xPowerCalculator({int windowSize = 25, double? alpha, double? timeConstantSeconds})`
- **Method**: `double calculate(Series<TX, double> series)`

#### `VariabilityIndexCalculator`

Computes the ratio of Normalized Power to Average Power.

- **Constructor**: `VariabilityIndexCalculator({int windowSize = 30})`
- **Method**: `double calculate(Series<TX, double> series)`

### Custom Reducers

You can implement custom aggregation logic by extending `SeriesReducer<T>`. This is useful for specialized statistical operations or filtering invalid data within windows.

#### Example: NaN-Aware Mean Reducer

```dart
class NanAwareMeanReducer extends SeriesReducer<double> {
  const NanAwareMeanReducer();

  @override
  double reduce(List<double> values) {
    var sum = 0.0;
    var count = 0;
    for (final value in values) {
      if (value.isFinite) {
        sum += value;
        count++;
      }
    }
    return count == 0 ? double.nan : sum / count;
  }
}

// Usage
final cleanSeries = series.aggregate(
  AggregationSpec(
    window: WindowSpec.rolling(5),
    reducer: const NanAwareMeanReducer(),
  ),
);
```

#### Example: 4th-Power Window Reducer (Custom NP)

```dart
class NormalizedPowerWindowReducer extends SeriesReducer<double> {
  const NormalizedPowerWindowReducer();

  @override
  double reduce(List<double> values) {
    if (values.isEmpty) return 0.0;

    var sumPower4 = 0.0;
    for (final value in values) {
      sumPower4 += pow(value, 4);
    }
    // Return 4th power average (root taken later)
    return sumPower4 / values.length;
  }
}
```

---

## Utilities

Helper tools for data parsing and detection.

### `XValueDetector`

Automatically detects the format of X-axis values (timestamps, numbers) from string samples.

- **Method**: `static XValueType detect(List<String> sampleValues)`
- **Returns**: `XValueType` (iso8601, epochSeconds, rowIndex, etc.)

#### Supported Types:

- **ISO 8601**: `2024-01-01T12:00:00Z`
- **Epoch Seconds**: `1704110400`
- **Epoch Millis**: `1704110400000`
- **Elapsed Seconds**: `0.0`, `1.5`, `3.0`

### `SeriesStorage`

The low-level backing store for `Series` data. `Series` automatically selects the best storage implementation, but you can interact with these directly if needed.

- **`TypedDataStorage`**: Uses `Float64List` / `Int64List`. Optimized for numeric data.
- **`ListStorage`**: Uses standard `List`. Used for mixed types or strings.

---

## Metrics

Standard algorithms for cycling and scientific data.

### Classes

- `NormalizedPowerMetric`: Calculates NP (30s rolling average).
- `XPowerMetric`: Calculates xPower (EWMA smoothing).
- `VariabilityIndexMetric`: Calculates NP / Average Power.
- `MeanMetric`, `MaxMetric`: Basic statistics.
- `MetricCalculator`: Generic interface.

#### Example

```dart
final np = series.compute(NormalizedPowerMetric());
```

---

## Analysis

Tools for statistical distributions and bucketing.

### Class: `DistributionCalculator`

Calculates frequency and work distributions (histograms) for a series.

#### Methods

- `static DistributionResult calculate(Series<dynamic, num> series, double bandWidth, {num minVal = 0, double maxGap = 5.0})`: Bucketizes the series into bands of `bandWidth`.
- `static DistributionResult merge(List<DistributionResult> results)`: Merges multiple distribution results (summing time and work).

### Class: `DistributionResult`

Container for distribution analysis results.

#### Properties

- `timeInBand`: Map of `Band Label -> Total Duration (seconds)`.
- `workInBand`: Map of `Band Label -> Total Work (Joules)`.

#### Methods

- `toTimeSeries({String name, String unit})`: Converts time distribution to a sorted Series.
- `toWorkSeries({String name, String unit})`: Converts work distribution to a sorted Series.

---

## Output

Utilities for exporting data for visualization.

### Extension: `SeriesChartOutput`

Adds methods to `Series`:

- `toChartDataPoints({bool includeMinMax, bool includeTimestamp})`: Returns `List<ChartDataPoint>`.
- `toMapList()`: Returns `List<Map<String, dynamic>>`.
- `toTuples()`: Returns `List<(double, double)>`.

### Class: `ChartDataPoint`

Structure compatible with charting libraries.

- `x` (`double`)
- `y` (`double`)
- `timestamp` (`DateTime?`)
- `metadata` (`Map?`)

---
