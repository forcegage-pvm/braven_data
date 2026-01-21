# braven_data

High-performance scientific data input, aggregation, and processing library for Dart.

[![Dart](https://img.shields.io/badge/Dart-3.10%2B-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/license-MIT-purple.svg)](LICENSE)

## Status

This package is under active development. APIs may evolve until the first stable release.

## Features

- **Efficient Storage**: Columnar storage using `Float64List`/`Int64List` with ~8 bytes per point
- **High Performance**: Aggregate 100k points to 1k points in <50ms
- **Type Safety**: Generic `Series<TX, TY>` with strict typing
- **Scientific Algorithms**: Built-in Normalized Power, xPower, Variability Index
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

### Ingest Data

```dart
import 'package:braven_data/braven_data.dart';
import 'dart:typed_data';

void main() {
  // Create raw data containers (optimized)
  final xData = Int64List.fromList([1000, 2000, 3000, 4000]);
  final yData = Float64List.fromList([10.0, 15.5, 12.0, 8.5]);

  // Create Series
  final series = Series.fromTypedData(
    id: 'sensor_1',
    x: xData,
    y: yData,
    meta: SeriesMeta(name: 'Voltage', unit: 'V'),
  );

  print('Loaded ${series.length} points');
}
```

### Aggregate Data

```dart
// Define 1-second fixed windows
final window = WindowSpec.fixed(1000000); // microseconds

// Aggregate using Mean reducer
final aggregated = series.aggregate(
  AggregationSpec(window: window, reducer: Reducers.mean),
);

print('Downsampled to ${aggregated.length} points');
```

### Calculate Normalized Power

```dart
final npPipeline = Pipeline()
  .rolling(WindowSpec.fixed(30 * 1000000), Reducers.mean) // 30s SMA
  .map((v) => pow(v, 4))
  .collapse(Reducers.mean)
  .map((v) => pow(v, 0.25));

final np = npPipeline.executeScalar(powerSeries);
print('Normalized Power: $np');
```

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

| Operation                  | Performance |
| -------------------------- | ----------- |
| 10M point ingestion        | ~400ms      |
| 100k → 1k aggregation      | ~30ms       |
| Random access (1000 reads) | <1ms        |

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

- API proposal: [specs/data_input_api_proposal.md](specs/data_input_api_proposal.md)
- Data model: [specs/data-model.md](specs/data-model.md)
- Plan: [specs/plan.md](specs/plan.md)

```

## License

MIT License - see [LICENSE](LICENSE) for details.
```
