# braven_data

High-performance scientific data input, aggregation, and processing library for Dart.

[![Dart](https://img.shields.io/badge/Dart-3.10%2B-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/license-MIT-purple.svg)](LICENSE)

## Status

This package is under active development. APIs may evolve until the first stable release.

## Features

- **CSV Processing**: Load CSV files with automatic timestamp parsing and type conversion
- **DataFrame Support**: Tabular data with typed column access and Series extraction
- **Efficient Storage**: Columnar storage using `Float64List`/`Int64List` with ~8 bytes per point
- **High Performance**: Load 10K rows in <500ms, aggregate 100k points to 1k in <50ms
- **Type Safety**: Generic `Series<TX, TY>` with strict typing
- **Scientific Algorithms**: Built-in Normalized Power, xPower, Variability Index
- **Duration Windows**: Time-based rolling aggregation (30-second smoothing, etc.)
- **Chart Output**: Convert Series to `ChartDataPoint[]` for visualization libraries
- **Custom Metrics**: Extensible `SeriesMetric` interface for domain-specific calculations
- **Fluent Pipeline API**: Chain transformations with `.map().rolling().collapse()`
- **Pure Dart**: No Flutter dependencies - works everywhere Dart runs

## Requirements

- Dart SDK 3.10+
- No third-party dependencies

## Installation

```yaml
dependencies:
  braven_data:
    git:
      url: https://github.com/yourusername/braven_data.git
```

## Quick Start

### Load CSV Data

```dart
import 'package:braven_data/braven_data.dart';

void main() {
  // Define schema for your CSV format
  final schema = CsvSchema(
    xColumn: 'timestamp',
    xType: XValueType.iso8601,  // Parses ISO 8601 timestamps
    columns: [
      ColumnDef(name: 'power', type: FieldType.float64, unit: 'W'),
      ColumnDef(name: 'heart_rate', type: FieldType.int64, unit: 'bpm'),
      ColumnDef(name: 'speed', type: FieldType.float64, unit: 'm/s'),
    ],
  );

  // Load CSV content
  final csvContent = '''
timestamp,power,heart_rate,speed
2024-01-15T10:00:00Z,250,145,8.5
2024-01-15T10:00:01Z,255,147,8.6
2024-01-15T10:00:02Z,248,146,8.4
''';

  final dataFrame = CsvLoader.loadString(csvContent, schema);
  print('Loaded ${dataFrame.rowCount} rows');
  print('Columns: ${dataFrame.columnNames}');
}
```

### Extract Series from DataFrame

```dart
// Extract power column as a Series
final powerSeries = dataFrame.toSeries(
  'power',
  meta: SeriesMeta(name: 'Power', unit: 'W'),
);

print('Series has ${powerSeries.length} points');
print('First value: ${powerSeries.getY(0)} W');
```

### Apply Rolling Average (Smoothing)

```dart
// Apply 30-second rolling average for smooth power curve
final smoothedPower = powerSeries.aggregate(
  AggregationSpec(
    window: WindowSpec.rollingDuration(Duration(seconds: 30)),
    reducer: SeriesReducer.mean,
  ),
);

print('Smoothed series: ${smoothedPower.length} points');
```

### Convert to Chart-Ready Output

```dart
// Convert to ChartDataPoint[] for visualization
final chartPoints = smoothedPower.toChartDataPoints();

// With metadata for error bars and tooltips
final richPoints = smoothedPower.toChartDataPoints(
  includeMinMax: true,
);

for (final point in richPoints.take(3)) {
  print('x: ${point.x}, y: ${point.y}, meta: ${point.metadata}');
}
```

### Calculate Scalar Metrics

```dart
// Compute metrics on the Series
final avgPower = powerSeries.compute(MeanMetric());
final maxPower = powerSeries.compute(MaxMetric());
final np = powerSeries.compute(NormalizedPowerMetric());
final vi = powerSeries.compute(VariabilityIndexMetric());

print('Average Power: ${avgPower.toStringAsFixed(1)} W');
print('Max Power: ${maxPower.toStringAsFixed(0)} W');
print('Normalized Power: ${np.toStringAsFixed(1)} W');
print('Variability Index: ${vi.toStringAsFixed(2)}');
```

---

## CSV Processing

### Supported X-Value Formats

| XValueType       | Description                   | Example                |
| ---------------- | ----------------------------- | ---------------------- |
| `iso8601`        | ISO 8601 timestamps           | `2024-01-15T10:00:00Z` |
| `epochSeconds`   | Unix timestamp (seconds)      | `1705312800`           |
| `epochMillis`    | Unix timestamp (milliseconds) | `1705312800000`        |
| `elapsedSeconds` | Seconds from start            | `0.0, 1.0, 2.0, ...`   |
| `rowIndex`       | Row number as X value         | `0, 1, 2, 3, ...`      |

### Auto-Detection

```dart
// Let the library detect the X-value format
final sampleValues = ['2025-01-01T00:00:00Z', '2025-01-01T00:00:01Z'];
final detectedType = XValueDetector.detect(sampleValues);
print('Detected format: $detectedType');
```

### Column Types

| FieldType | Dart Type | Use Case               |
| --------- | --------- | ---------------------- |
| `float64` | `double`  | Power, speed, altitude |
| `int64`   | `int`     | Heart rate, cadence    |
| `string`  | `String`  | Labels, categories     |

---

## Series & Aggregation

### Create Series Directly

```dart
import 'dart:typed_data';

// Create raw data containers (optimized)
final xData = Int64List.fromList([1000, 2000, 3000, 4000]);
final yData = Float64List.fromList([10.0, 15.5, 12.0, 8.5]);

// Create Series
final series = Series<int, double>.fromTypedData(
  id: 'sensor_1',
  xValues: xData,
  yValues: yData,
  meta: SeriesMeta(name: 'Voltage', unit: 'V'),
);

print('Loaded ${series.length} points');
```

### Window Types

```dart
// Fixed windows (point-based)
final fixedWindow = WindowSpec.fixed(100);  // 100 points per window

// Rolling windows (point-based)
final rollingWindow = WindowSpec.rolling(30);  // 30-point trailing

// Duration-based windows (time-aware)
final durationWindow = WindowSpec.rollingDuration(
  Duration(seconds: 30),
);
```

### Aggregate Data

```dart
// Aggregate using Mean reducer
final window = WindowSpec.rollingDuration(Duration(seconds: 30));
final aggregated = series.aggregate(
  AggregationSpec(window: window, reducer: SeriesReducer.mean),
);

print('Downsampled to ${aggregated.length} points');
```

---

## Metrics

### Built-in Metrics

```dart
// Basic statistics
final mean = series.compute(MeanMetric());
final max = series.compute(MaxMetric());

// Power-specific metrics
final np = series.compute(NormalizedPowerMetric());
final xp = series.compute(XPowerMetric());
final vi = series.compute(VariabilityIndexMetric());
```

### Custom Metrics

Implement your own metrics in under 20 lines:

```dart
class RmsMetric implements SeriesMetric<double> {
  const RmsMetric();

  @override
  double calculate(Series<dynamic, double> series) {
    var sumSquares = 0.0;
    for (var i = 0; i < series.length; i++) {
      final v = series.getY(i);
      sumSquares += v * v;
    }
    return sqrt(sumSquares / series.length);
  }
}

// Use it
final rms = series.compute(RmsMetric());
```

---

## Chart Output

### Output Formats

```dart
// ChartDataPoint list (for charting libraries)
final chartPoints = series.toChartDataPoints();

// With min/max metadata for error bars
final richPoints = series.toChartDataPoints(includeMinMax: true);

// As list of maps
final mapList = series.toMapList();
// [{'x': 0.0, 'y': 245.3}, {'x': 1.0, 'y': 248.1}, ...]

// As tuples
final tuples = series.toTuples();
// [(0.0, 245.3), (1.0, 248.1), ...]
```

### ChartDataPoint Structure

```dart
class ChartDataPoint {
  final double x;              // X-axis value
  final double y;              // Y-axis value
  final DateTime? timestamp;   // Original timestamp
  final String? label;         // Tooltip label
  final Map<String, dynamic>? metadata;  // min, max, count, etc.
}
```

---

## Complete Example: Analyze Cycling Data

```dart
import 'dart:io';
import 'package:braven_data/braven_data.dart';

Future<void> main() async {
  // 1. Define schema for Garmin CSV export
  final schema = CsvSchema(
    xColumn: 'timestamp',
    xType: XValueType.iso8601,
    columns: [
      ColumnDef(name: 'power', type: FieldType.float64),
      ColumnDef(name: 'heart_rate', type: FieldType.int64),
      ColumnDef(name: 'cadence', type: FieldType.int64),
      ColumnDef(name: 'speed', type: FieldType.float64),
    ],
  );

  // 2. Load the CSV file
  final csvContent = await File('ride.csv').readAsString();
  final df = CsvLoader.loadString(csvContent, schema);
  print('Loaded ${df.rowCount} data points');

  // 3. Extract power Series
  final power = df.toSeries('power');

  // 4. Apply 30-second smoothing
  final smoothed = power.aggregate(
    AggregationSpec(
      window: WindowSpec.rollingDuration(Duration(seconds: 30)),
      reducer: SeriesReducer.mean,
    ),
  );

  // 5. Calculate metrics
  print('Average Power: ${power.compute(MeanMetric()).toStringAsFixed(1)} W');
  print('Normalized Power: ${power.compute(NormalizedPowerMetric()).toStringAsFixed(1)} W');
  print('Variability Index: ${power.compute(VariabilityIndexMetric()).toStringAsFixed(2)}');

  // 6. Convert to chart data
  final chartData = smoothed.toChartDataPoints(includeMinMax: true);
  print('Chart points: ${chartData.length}');
}
```

---

## Storage Types

| Type                               | Backing                     | Use Case          |
| ---------------------------------- | --------------------------- | ----------------- |
| `TypedDataStorage<double, double>` | `Float64List` × 2           | Numeric data      |
| `TypedDataStorage<int, double>`    | `Int64List` + `Float64List` | Time-series       |
| `ListStorage<TX, TY>`              | `List<TX>` + `List<TY>`     | Flexible fallback |
| `IntervalStorage`                  | Structure-of-Arrays         | Aggregated data   |

## Sentinel Values

Missing data uses sentinels for performance (no null checks):

| Type     | Sentinel     | Check                     |
| -------- | ------------ | ------------------------- |
| `double` | `double.nan` | `.isNaN`                  |
| `int`    | `Int64.min`  | `== -9223372036854775808` |

## Performance

Benchmarked on typical hardware:

| Operation                      | Performance |
| ------------------------------ | ----------- |
| Load 10K row CSV + extract     | <500ms      |
| Full CSV→Chart pipeline (3600) | <1s         |
| Memory overhead                | ≤3x raw     |
| 100k → 1k aggregation          | ~30ms       |
| Random access (1000 reads)     | <1ms        |

## Development

```bash
# Get dependencies
dart pub get

# Run tests
dart test

# Run analyzer
dart analyze

# Run benchmarks
dart run test/benchmarks/perf.dart
```

## Documentation

- CSV Pipeline: [specs/002-csv-processing-pipeline/quickstart.md](specs/002-csv-processing-pipeline/quickstart.md)
- Data Model: [specs/002-csv-processing-pipeline/data-model.md](specs/002-csv-processing-pipeline/data-model.md)
- API Specification: [specs/002-csv-processing-pipeline/spec.md](specs/002-csv-processing-pipeline/spec.md)

## License

MIT License - see [LICENSE](LICENSE) for details.
