# Quickstart: Braven Data

## Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  braven_data:
    path: ../braven_data # Or published version
```

## Basic Usage

### 1. Ingest Data

```dart
import 'package:braven_data/braven_data.dart';
import 'dart:typed_data';

void main() {
  // Create raw data containers (optimized)
  final xData = Int64List.fromList([1000, 2000, 3000, 4000]); // microsecond timestamps
  final yData = Float64List.fromList([10.0, 15.5, 12.0, double.nan]); // Values

  // Create Series
  final series = Series.fromTypedData(
    id: 'sensor_1',
    x: xData,
    y: yData,
    meta: SeriesMeta(name: 'Sensor Voltage', unit: 'V'),
  );

  print('Loaded ${series.length} points');
}
```

### 2. Aggregation Pipeline

```dart
  // Define 1-second fixed windows (assuming X is microseconds)
  final window = WindowSpec.fixed(1000000);

  // Aggregate using Mean reducer
  final aggSeries = series.aggregate(
    AggregationSpec(
      window: window,
      reducer: Reducers.mean,
    ),
  );

  print('Downsampled to ${aggSeries.length} points');
```

## Advanced: Normalized Power Calculation

```dart
  final npPipeline = Pipeline()
    .rolling(WindowSpec.fixed(30 * 1000000), Reducers.mean) // 30s SMA
    .map((v) => pow(v, 4))
    .collapse(Reducers.mean)
    .map((v) => pow(v, 0.25));

  final normalizedPower = npPipeline.executeScalar(series);
  print('NP: $normalizedPower');
```

## Storage Types

| Storage Type                       | Backing                     | Use Case                    |
| ---------------------------------- | --------------------------- | --------------------------- |
| `TypedDataStorage<double, double>` | `Float64List` x2            | Default for numeric data    |
| `TypedDataStorage<int, double>`    | `Int64List` + `Float64List` | Time-series with timestamps |
| `ListStorage<TX, TY>`              | `List<TX>` + `List<TY>`     | Flexible fallback           |
| `IntervalStorage`                  | SoA arrays                  | Aggregated/downsampled data |

## Sentinel Values

Missing data is represented by sentinels for performance:

| Type         | Sentinel               | Check          |
| ------------ | ---------------------- | -------------- |
| `double`     | `double.nan`           | `.isNaN`       |
| `int` (time) | `-9223372036854775808` | `== Int64.min` |
