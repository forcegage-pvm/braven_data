# API Proposal: FIT File Support

**Feature**: 003-fit-file  
**Date**: 2026-01-22  
**Status**: Draft

## Overview

Introduce `FitLoader` and `FitSchema` to decode FIT files into `DataFrame`s using `dart_fit_decoder`, with a clear path to `Series` extraction.

## Proposed Types

### FitMessageType

```dart
enum FitMessageType {
  records,
  laps,
  sessions,
}
```

### FitSchema

```dart
enum FitMissingColumnBehavior {
  skip,
  error,
}

class FitSchema {
  /// Explicit column definitions to apply.
  final List<ColumnDef> columns;

  /// Optional overrides for developer fields (type/unit hints).
  final List<ColumnDef> developerFields;

  /// Optional X column name used for series extraction (default: "timestamp").
  final String xColumn;

  /// How to interpret X values (default: ISO 8601).
  final XValueType xType;

  /// How to handle a column that is explicitly defined but missing in the FIT file.
  final FitMissingColumnBehavior onMissingColumn;

  const FitSchema({
    this.columns = const [],
    this.developerFields = const [],
    this.xColumn = 'timestamp',
    this.xType = XValueType.iso8601,
    this.onMissingColumn = FitMissingColumnBehavior.skip,
  });
}
```

### FitLoader

```dart
class FitLoader {
  /// Load FIT content from bytes and return a DataFrame for the message type.
  static DataFrame loadBytes(
    Uint8List bytes,
    FitMessageType messageType, {
    FitSchema? schema,
  });

  /// Load FIT content from a file path and return a DataFrame for the message type.
  static Future<DataFrame> load(
    String path,
    FitMessageType messageType, {
    FitSchema? schema,
  });
}
```

## Behavior Notes

- `FitLoader` extracts the targeted message type into a `DataFrame`.
- For `records`, all developer fields are auto-derived and included as columns.
- When explicit `ColumnDef` entries conflict with auto-derived fields:
  - Explicit definitions override type/unit.
  - Auto-derived definitions fill in missing columns.
- Column naming should follow snake_case and prefer FIT field names.
- `FitSchema.xColumn` is used by `DataFrame.toSeries()`.
- Missing explicit columns are **skipped by default**; set `onMissingColumn` to `error` to fail fast.

## Example Usage

```dart
final schema = FitSchema(
  columns: const [
    ColumnDef(name: 'power', type: FieldType.float64, unit: 'W'),
    ColumnDef(name: 'heart_rate', type: FieldType.int64, unit: 'bpm'),
  ],
  developerFields: const [
    ColumnDef(name: 'core_temp', type: FieldType.float64, unit: 'C'),
  ],
);

final df = await FitLoader.load('ride.fit', FitMessageType.records, schema: schema);
final power = df.toSeries('power');
```

## Open Questions

- Developer field naming conventions (raw FIT name vs normalized)?
- Type inference for developer fields when metadata is incomplete?
- Default unit mappings for standard FIT fields?
