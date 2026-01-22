# Quickstart: CSV Processing Pipeline

**Feature**: 002-csv-processing-pipeline  
**Date**: 2026-01-22

## Overview

This guide shows how to use the CSV Processing Pipeline to:
1. Load a CSV file into a DataFrame
2. Extract Series for processing
3. Apply aggregation and smoothing
4. Output chart-ready data

---

## Basic Usage

### 1. Define a Schema

```dart
import 'package:braven_data/braven_data.dart';

// Define how to parse your CSV
final schema = CsvSchema(
  xColumn: 'timestamp',
  xType: XValueType.iso8601,
  columns: [
    ColumnDef(name: 'power', type: FieldType.float64, unit: 'W'),
    ColumnDef(name: 'heart_rate', type: FieldType.int64, unit: 'bpm'),
    ColumnDef(name: 'speed', type: FieldType.float64, unit: 'm/s'),
  ],
);
```

### 2. Load CSV Data

```dart
// From file
final df = await CsvLoader.load('data/cycling_activity.csv', schema);

// Or from string content
final df = CsvLoader.loadString(csvContent, schema);

// Check what we loaded
print('Rows: ${df.rowCount}');
print('Columns: ${df.columnNames}');
```

### 3. Extract a Series

```dart
// Extract power data as a Series
final powerSeries = df.toSeries(
  'power',
  meta: SeriesMeta(name: 'Power', unit: 'W'),
);

print('Points: ${powerSeries.length}');
print('First X: ${powerSeries.getX(0)}');  // 0.0 (normalized)
print('First Y: ${powerSeries.getY(0)}');  // 245.0 (watts)
```

---

## Processing Data

### Apply Rolling Average (30s Smoothing)

```dart
// Create a processing pipeline
final pipeline = PipelineBuilder<double, double>()
    .rolling(
      WindowSpec.rollingDuration(Duration(seconds: 30)),
      SeriesReducer.mean,
    );

// Execute to get smoothed series
final smoothedPower = pipeline.execute(powerSeries);
```

### Calculate Scalar Metrics

```dart
// Normalized Power for the whole ride
final np = powerSeries.compute(NormalizedPowerMetric());
print('Normalized Power: ${np.toStringAsFixed(1)} W');

// Variability Index
final vi = powerSeries.compute(VariabilityIndexMetric());
print('Variability Index: ${vi.toStringAsFixed(2)}');

// Simple average
final avgPower = powerSeries.compute(MeanMetric());
print('Average Power: ${avgPower.toStringAsFixed(1)} W');
```

---

## Output for Charts

### Convert to ChartDataPoint[]

```dart
// Basic conversion
final chartPoints = smoothedPower.toChartDataPoints();

// With metadata (for error bars, tooltips)
final richPoints = smoothedPower.toChartDataPoints(
  includeMinMax: true,
  includeTimestamp: true,
);

// Use with BravenChartPlus
chart.add(LineSeries(data: chartPoints));
```

### Alternative Output Formats

```dart
// As list of maps
final mapList = smoothedPower.toMapList();
// [{'x': 0.0, 'y': 245.3}, {'x': 1.0, 'y': 248.1}, ...]

// As tuples
final tuples = smoothedPower.toTuples();
// [(0.0, 245.3), (1.0, 248.1), ...]
```

---

## Complete Example: Garmin Data Analysis

```dart
import 'package:braven_data/braven_data.dart';

Future<void> analyzeRide(String csvPath) async {
  // 1. DEFINE SCHEMA for Garmin FIT export
  final schema = CsvSchema(
    xColumn: 'timestamp',
    xType: XValueType.iso8601,
    columns: [
      ColumnDef(name: 'power', type: FieldType.float64),
      ColumnDef(name: 'heart_rate', type: FieldType.int64),
      ColumnDef(name: 'cadence', type: FieldType.int64),
      ColumnDef(name: 'speed', type: FieldType.float64),
      ColumnDef(name: 'altitude', type: FieldType.float64),
    ],
  );

  // 2. LOAD DATA
  final df = await CsvLoader.load(csvPath, schema);
  print('Loaded ${df.rowCount} data points');

  // 3. EXTRACT SERIES
  final power = df.toSeries('power', meta: SeriesMeta(name: 'Power', unit: 'W'));
  final hr = df.toSeries('heart_rate', meta: SeriesMeta(name: 'HR', unit: 'bpm'));

  // 4. CALCULATE METRICS
  final np = power.compute(NormalizedPowerMetric());
  final avgPower = power.compute(MeanMetric());
  final vi = power.compute(VariabilityIndexMetric());
  final maxHr = hr.compute(MaxMetric());

  print('--- Ride Summary ---');
  print('Normalized Power: ${np.toStringAsFixed(0)} W');
  print('Average Power: ${avgPower.toStringAsFixed(0)} W');
  print('Variability Index: ${vi.toStringAsFixed(2)}');
  print('Max Heart Rate: ${maxHr.toStringAsFixed(0)} bpm');

  // 5. CREATE CHART SERIES (30s smoothed)
  final smoothedPower = PipelineBuilder<double, double>()
      .rolling(
        WindowSpec.rollingDuration(Duration(seconds: 30)),
        SeriesReducer.mean,
      )
      .execute(power);

  final smoothedHr = PipelineBuilder<double, double>()
      .rolling(
        WindowSpec.rollingDuration(Duration(seconds: 5)),
        SeriesReducer.mean,
      )
      .execute(hr);

  // 6. OUTPUT FOR CHART
  final powerChartData = smoothedPower.toChartDataPoints();
  final hrChartData = smoothedHr.toChartDataPoints();

  print('Generated ${powerChartData.length} chart points for power');
  print('Generated ${hrChartData.length} chart points for heart rate');

  // Ready to pass to BravenChartPlus!
}
```

---

## Handling Different X-Value Formats

### ISO 8601 Timestamps (Most Common)

```dart
CsvSchema(
  xColumn: 'timestamp',
  xType: XValueType.iso8601,
  // ...
)
// Input: "2025-10-26T13:23:17Z"
// Output: 0.0, 1.0, 2.0, ... (elapsed seconds)
```

### Epoch Timestamps

```dart
// Seconds
CsvSchema(xColumn: 'time', xType: XValueType.epochSeconds, ...)
// Input: 1698325397 → normalized to elapsed

// Milliseconds
CsvSchema(xColumn: 'time_ms', xType: XValueType.epochMillis, ...)
// Input: 1698325397000 → ÷1000 → normalized
```

### Already Elapsed Time

```dart
CsvSchema(xColumn: 'elapsed_s', xType: XValueType.elapsedSeconds, ...)
// Input: 0, 1, 2, 3, ... → used directly
```

### No X Column (Use Row Index)

```dart
CsvSchema(
  xColumn: null,  // or omit
  xType: XValueType.rowIndex,
  // ...
)
// Output: 0, 1, 2, 3, ... (row numbers)
```

---

## Window Alignment Examples

### Trailing Average (Default for Rolling)

```dart
// Point at T=30 represents average of T=0 to T=30
WindowSpec.rollingDuration(
  Duration(seconds: 30),
  alignment: WindowAlignment.end,  // default
)
```

### Centered Window (Signal Processing)

```dart
// Point at T=30 represents average of T=15 to T=45
WindowSpec.rollingDuration(
  Duration(seconds: 30),
  alignment: WindowAlignment.center,
)
```

### Leading Window (Fixed Bins)

```dart
// Point at T=0 represents bin from T=0 to T=60
WindowSpec.fixedDuration(
  Duration(minutes: 1),
  alignment: WindowAlignment.start,  // default for fixed
)
```

---

## Error Handling

```dart
try {
  final df = await CsvLoader.load('data.csv', schema);
} on FormatException catch (e) {
  print('CSV parsing error: $e');
} on ArgumentError catch (e) {
  print('Schema error: $e');
}

// Check for missing columns
if (!df.columnNames.contains('power')) {
  throw ArgumentError('CSV missing required "power" column');
}
```

---

## Next Steps

- See [data-model.md](data-model.md) for entity details
- See [contracts/api.dart](contracts/api.dart) for full API reference
- See [spec.md](spec.md) for requirements and acceptance criteria
