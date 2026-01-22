# Data Model: CSV Processing Pipeline

**Feature**: 002-csv-processing-pipeline  
**Date**: 2026-01-22  
**Status**: Complete

## Entity Relationship Diagram

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  CsvSchema  │────▶│  CsvLoader  │────▶│  DataFrame  │
└─────────────┘     └─────────────┘     └─────────────┘
       │                                       │
       ▼                                       ▼
┌─────────────┐                         ┌─────────────┐
│  ColumnDef  │                         │   Column    │
└─────────────┘                         └─────────────┘
       │                                       │
       ▼                                       ▼
┌─────────────┐                         ┌─────────────┐
│  XValueType │                         │ Series<X,Y> │
└─────────────┘                         └─────────────┘
                                               │
                                               ▼
                                        ┌─────────────┐
                                        │ChartDataPoint│
                                        └─────────────┘
```

---

## Entities

### 1. XValueType (Enum)

Defines how X-axis values should be interpreted.

| Value            | Description                   | Conversion                      |
| ---------------- | ----------------------------- | ------------------------------- |
| `iso8601`        | ISO 8601 timestamp string     | Parse → epoch → elapsed seconds |
| `epochSeconds`   | Unix timestamp (seconds)      | Direct → elapsed seconds        |
| `epochMillis`    | Unix timestamp (milliseconds) | ÷1000 → elapsed seconds         |
| `elapsedSeconds` | Already elapsed seconds       | Direct use                      |
| `elapsedMillis`  | Elapsed milliseconds          | ÷1000 → elapsed seconds         |
| `rowIndex`       | No X column; use row number   | 0, 1, 2, ...                    |
| `custom`         | User-provided parser          | Callback function               |

```dart
enum XValueType {
  iso8601,
  epochSeconds,
  epochMillis,
  elapsedSeconds,
  elapsedMillis,
  rowIndex,
  custom,
}
```

---

### 2. FieldType (Enum)

Supported data types for Y-value columns.

| Value     | Dart Type | Storage      |
| --------- | --------- | ------------ |
| `float64` | double    | Float64List  |
| `int64`   | int       | Int64List    |
| `string`  | String    | List<String> |

```dart
enum FieldType {
  float64,
  int64,
  string,
}
```

---

### 3. ColumnDef (Value Object)

Defines a single column in the CSV schema.

| Field          | Type      | Required | Description                        |
| -------------- | --------- | -------- | ---------------------------------- |
| `name`         | String    | ✅       | Column header name                 |
| `type`         | FieldType | ✅       | Data type for parsing              |
| `defaultValue` | dynamic   | ❌       | Value for missing/null cells       |
| `unit`         | String?   | ❌       | Unit annotation (e.g., "W", "bpm") |

```dart
class ColumnDef {
  final String name;
  final FieldType type;
  final dynamic defaultValue;
  final String? unit;

  const ColumnDef({
    required this.name,
    required this.type,
    this.defaultValue,
    this.unit,
  });
}
```

**Validation Rules**:

- `name` must not be empty
- `defaultValue` must match `type` (e.g., double for float64)

---

### 4. CsvSchema (Aggregate Root)

Defines the complete structure for parsing a CSV file.

| Field       | Type            | Required | Description                                |
| ----------- | --------------- | -------- | ------------------------------------------ |
| `xColumn`   | String?         | ❌       | Column name for X values (null = rowIndex) |
| `xType`     | XValueType      | ✅       | How to parse X values                      |
| `xFormat`   | String?         | ❌       | Custom format pattern (for xType.custom)   |
| `columns`   | List<ColumnDef> | ✅       | Y-value column definitions                 |
| `hasHeader` | bool            | ❌       | First row is headers (default: true)       |
| `delimiter` | String          | ❌       | Column separator (default: ',')            |

```dart
class CsvSchema {
  final String? xColumn;
  final XValueType xType;
  final String? xFormat;
  final List<ColumnDef> columns;
  final bool hasHeader;
  final String delimiter;

  const CsvSchema({
    this.xColumn,
    required this.xType,
    this.xFormat,
    required this.columns,
    this.hasHeader = true,
    this.delimiter = ',',
  });
}
```

**Validation Rules**:

- If `xType` is not `rowIndex`, `xColumn` must be provided
- `columns` must not be empty
- All column names must be unique

---

### 5. DataFrame (Entity)

Columnar container for parsed CSV data.

| Field         | Type              | Description                  |
| ------------- | ----------------- | ---------------------------- |
| `_columns`    | Map<String, List> | Internal columnar storage    |
| `schema`      | CsvSchema         | Original parsing schema      |
| `rowCount`    | int               | Number of data rows          |
| `columnNames` | List<String>      | All column names including X |

```dart
class DataFrame {
  final Map<String, List<dynamic>> _columns;
  final CsvSchema schema;

  int get rowCount;
  List<String> get columnNames;

  List<T> get<T>(String columnName);
  List<double> getXValues();

  Series<double, double> toSeries(String yColumn, {SeriesMeta? meta});
}
```

**Lifecycle**:

1. Created by `CsvLoader.load()`
2. Immutable after creation
3. Series extracted via `toSeries()`

---

### 6. ChartDataPoint (Value Object)

Output structure compatible with BravenChartPlus.

| Field       | Type                  | Required | Description                    |
| ----------- | --------------------- | -------- | ------------------------------ |
| `x`         | double                | ✅       | X-axis value (elapsed seconds) |
| `y`         | double                | ✅       | Y-axis value                   |
| `timestamp` | DateTime?             | ❌       | Original absolute timestamp    |
| `label`     | String?               | ❌       | Tooltip/annotation text        |
| `metadata`  | Map<String, dynamic>? | ❌       | Extra data (min, max, count)   |

```dart
class ChartDataPoint {
  final double x;
  final double y;
  final DateTime? timestamp;
  final String? label;
  final Map<String, dynamic>? metadata;

  const ChartDataPoint({
    required this.x,
    required this.y,
    this.timestamp,
    this.label,
    this.metadata,
  });
}
```

---

### 7. WindowAlignment (Enum)

Specifies where output points align relative to their window.

| Value    | Description               | Use Case                    |
| -------- | ------------------------- | --------------------------- |
| `start`  | X = first point in window | Fixed bins, histograms      |
| `center` | X = midpoint of window    | Signal processing           |
| `end`    | X = last point in window  | Trailing averages (default) |

```dart
enum WindowAlignment {
  start,
  center,
  end,
}
```

---

### 8. SeriesMetric<T> (Interface)

Contract for scalar metric calculations.

```dart
abstract class SeriesMetric<T> {
  const SeriesMetric();

  /// Calculate a single value from the entire series
  T calculate(Series<dynamic, double> series);
}
```

**Built-in Implementations**:

- `NormalizedPowerMetric` → double
- `XPowerMetric` → double
- `VariabilityIndexMetric` → double
- `MeanMetric` → double
- `MaxMetric` → double

---

## Relationships

| From      | To             | Relationship | Cardinality |
| --------- | -------------- | ------------ | ----------- |
| CsvSchema | ColumnDef      | contains     | 1:N         |
| CsvSchema | XValueType     | uses         | 1:1         |
| CsvLoader | CsvSchema      | requires     | 1:1         |
| CsvLoader | DataFrame      | produces     | 1:1         |
| DataFrame | Series         | extracts     | 1:N         |
| Series    | ChartDataPoint | converts to  | 1:N         |
| Series    | SeriesMetric   | computed by  | N:M         |

---

## State Transitions

### DataFrame Lifecycle

```
[Not Loaded] ──CsvLoader.load()──▶ [Loaded] ──toSeries()──▶ [Series Extracted]
                                       │
                                       └──get<T>()──▶ [Column Accessed]
```

### Series Processing

```
[Raw Series] ──transform(pipeline)──▶ [Processed Series] ──toChartDataPoints()──▶ [Chart Ready]
      │                                        │
      └──compute(metric)──▶ [Scalar Value]    └──aggregate(spec)──▶ [Aggregated Series]
```

---

## Data Volume Assumptions

| Scenario                     | Rows    | Columns | Memory (Est.) |
| ---------------------------- | ------- | ------- | ------------- |
| 1-hour activity (1Hz)        | 3,600   | 10      | ~600 KB       |
| 10-hour activity             | 36,000  | 10      | ~6 MB         |
| 60-hour ultra event          | 216,000 | 10      | ~35 MB        |
| High-freq burst (1kHz, 2min) | 120,000 | 5       | ~10 MB        |

All scenarios fit comfortably in memory per spec constraints.
