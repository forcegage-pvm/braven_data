# Research: CSV Processing Pipeline

**Feature**: 002-csv-processing-pipeline  
**Date**: 2026-01-22  
**Status**: Complete

## Overview

This document resolves all technical decisions required before implementation. All items marked "NEEDS CLARIFICATION" in the plan have been researched and resolved.

---

## 1. CSV Parsing Strategy

### Decision
Manual implementation using `dart:convert` (LineSplitter) + String.split(',')

### Rationale
- **Pure Dart requirement**: No third-party packages allowed per constitution
- **Simplicity**: CSV format is straightforward; RFC 4180 compliance not required for our use case
- **Performance**: Direct string manipulation is faster than regex-based parsing
- **Control**: Handle edge cases (quoted fields, embedded commas) incrementally as needed

### Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| `csv` package (pub.dev) | Violates pure Dart constraint |
| Regex-based parsing | Slower, harder to debug |
| Character-by-character state machine | Over-engineered for current needs |

### Implementation Notes
```dart
// Core parsing approach
final lines = content.split('\n');
final headers = lines.first.split(',');
for (final line in lines.skip(1)) {
  final values = line.split(',');
  // Map to columns...
}
```

---

## 2. DateTime Parsing Strategy

### Decision
Use `DateTime.parse()` for ISO 8601, manual conversion for epoch formats

### Rationale
- `DateTime.parse()` handles ISO 8601 natively (no package needed)
- Epoch formats are simple integer division
- Auto-detection via pattern matching (see spec Q4 resolution)

### Format Detection Heuristics

| Pattern | Detection Rule | Conversion |
|---------|----------------|------------|
| ISO 8601 | Contains 'T' and '-' | `DateTime.parse()` |
| Epoch seconds | Integer 1e9 - 2e9 range | `DateTime.fromMillisecondsSinceEpoch(v * 1000)` |
| Epoch milliseconds | Integer 1e12 - 2e12 range | `DateTime.fromMillisecondsSinceEpoch(v)` |
| Elapsed seconds | Incrementing from ~0 | Direct use as X value |
| Row index | No X column specified | Use row number |

### Implementation Notes
```dart
double parseXValue(String value, XValueType type) {
  switch (type) {
    case XValueType.iso8601:
      return DateTime.parse(value).millisecondsSinceEpoch / 1000.0;
    case XValueType.epochSeconds:
      return double.parse(value);
    case XValueType.epochMillis:
      return double.parse(value) / 1000.0;
    case XValueType.elapsedSeconds:
      return double.parse(value);
    case XValueType.rowIndex:
      throw StateError('rowIndex handled at loader level');
  }
}
```

---

## 3. X-Value Normalization

### Decision
First data point becomes X=0.0; all subsequent points are relative elapsed seconds

### Rationale
- Chart rendering needs relative positioning, not absolute timestamps
- Preserves original timestamp in Series metadata for reconstruction
- Consistent with gaps_and_enhancements.md Q1 decision

### Implementation Notes
```dart
// During series extraction
final firstTimestamp = rawTimestamps.first;
final normalizedX = rawTimestamps.map((t) => t - firstTimestamp).toList();

// Store original for metadata
series.meta.originalStartTime = DateTime.fromMillisecondsSinceEpoch(
  (firstTimestamp * 1000).round()
);
```

---

## 4. DataFrame Internal Storage

### Decision
`Map<String, List<dynamic>>` with typed accessor methods

### Rationale
- Columnar storage enables efficient typed array extraction
- Map provides O(1) column lookup by name
- Generic List allows mixed types before typed extraction
- Typed accessors (`get<T>()`) provide compile-time safety at access point

### Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| Row-based List<Map> | Poor cache locality, inefficient for column operations |
| Strongly typed Map<String, TypedData> | Over-constrains schema flexibility |
| Separate class per column type | Explosion of types, harder to extend |

### Implementation Notes
```dart
class DataFrame {
  final Map<String, List<dynamic>> _columns;
  
  List<T> get<T>(String name) => _columns[name]!.cast<T>();
  
  int get rowCount => _columns.values.first.length;
}
```

---

## 5. ChartDataPoint Structure

### Decision
Local copy of structure in braven_data (no package dependency)

### Rationale
- braven_data is a pure Dart package; cannot depend on Flutter-based braven_charts
- Structure is simple and stable (per spec assumption)
- Generic output methods (`toMapList()`, `toRecords()`) provide alternatives

### Structure (from gaps_and_enhancements.md)
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

## 6. Duration-Based Window Calculation

### Decision
Convert Duration to point count based on assumed sample rate (from X values)

### Rationale
- Duration-based windows are more intuitive for users ("30 seconds")
- Sample rate inferred from first two X values: `rate = 1 / (x[1] - x[0])`
- Window point count: `duration.inSeconds * rate`

### Edge Cases

| Scenario | Handling |
|----------|----------|
| Irregular sampling | Use median interval from first 10 points |
| Single point | Window size = 1 |
| Duration < sample interval | Window size = 1 with warning |

### Implementation Notes
```dart
int windowSizeFromDuration(Duration duration, Series series) {
  if (series.length < 2) return 1;
  final interval = series.getX(1) - series.getX(0);
  return (duration.inSeconds / interval).round().clamp(1, series.length);
}
```

---

## 7. WindowAlignment Implementation

### Decision
Output X value based on alignment enum: start, center, or end of window

### Rationale
- Matches gaps_and_enhancements.md Q5.2 decision
- Rolling defaults to `end` (trailing average - standard for power metrics)
- Fixed defaults to `start` (bin labeling convention)

### Implementation Notes
```dart
double alignedX(int windowStart, int windowEnd, WindowAlignment align) {
  switch (align) {
    case WindowAlignment.start:
      return series.getX(windowStart);
    case WindowAlignment.center:
      return (series.getX(windowStart) + series.getX(windowEnd - 1)) / 2;
    case WindowAlignment.end:
      return series.getX(windowEnd - 1);
  }
}
```

---

## 8. SeriesMetric Interface Design

### Decision
Abstract class with single `calculate(Series)` method returning generic `T`

### Rationale
- Matches reference implementation in power_metrics.dart
- Simple interface enables user extensions
- Generic return type supports various output types (double, record, etc.)

### Interface
```dart
abstract class SeriesMetric<T> {
  const SeriesMetric();
  
  T calculate(Series<dynamic, double> series);
}
```

---

## Summary of Decisions

| Topic | Decision |
|-------|----------|
| CSV parsing | Manual split-based, no packages |
| DateTime parsing | DateTime.parse() + manual epoch |
| X normalization | Relative to first point |
| DataFrame storage | Map<String, List<dynamic>> |
| ChartDataPoint | Local copy, no dependency |
| Duration windows | Convert to point count via sample rate |
| Window alignment | Enum-based X calculation |
| SeriesMetric | Abstract class with calculate() |

---

**All technical decisions resolved. Ready for Phase 1 design.**
