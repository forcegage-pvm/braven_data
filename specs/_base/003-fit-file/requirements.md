# Requirements: FIT File Support

**Feature**: 003-fit-file  
**Date**: 2026-01-22  
**Status**: Draft

## Overview

Implement FIT ingestion using `dart_fit_decoder` to produce `DataFrame` outputs and a `Series` adapter. FIT files contain multiple message types; we must extract **records**, **laps**, and **sessions** as `DataFrame`s via `FitLoader` and provide a clear path to `Series` extraction.

## Core Requirements

### FR-001 FIT Decoder Integration

- Use `dart_fit_decoder` to parse FIT files.
- Support loading from file path and from bytes.

### FR-002 Message Extraction

- Extract the following message types as `DataFrame` objects:
  - `records`
  - `laps`
  - `sessions`

### FR-003 Records Developer Fields

- For `records`, include **all developer fields** as columns in the resulting `DataFrame`.
- Developer fields must be auto-derived from the FIT metadata and included alongside standard fields.

### FR-004 Column Definitions

- Support explicit column definitions (e.g., `ColumnDef(name: 'power', type: FieldType.float64, unit: 'W')`).
- Merge explicit column definitions with auto-derived fields:
  - Explicit definitions take precedence for type/unit when both exist.
  - Auto-derived fields fill in the rest.

### FR-005 Schema Model

- Define a FIT-specific schema (`FitSchema`) that describes:
  - Which message type is targeted (`records`, `laps`, `sessions`).
  - Explicit column definitions.
  - Optional unit overrides or type hints.

### FR-006 DataFrame Consistency

- All extracted `DataFrame`s must:
  - Preserve message order from the FIT file.
  - Use consistent column naming (snake_case, matching FIT field names where possible).
  - Include X-value handling suitable for `Series` extraction (e.g., `timestamp` mapped to elapsed seconds).

### FR-007 FIT-to-Series Adapter

- Provide an adapter to extract `Series` from FIT-derived `DataFrame`s, consistent with existing `DataFrame.toSeries()` behavior.

## Non-Functional Requirements

### NFR-001 Performance

- Parsing 1-hour FIT files (≈3600 records) should complete in under 1s on a typical dev machine.

### NFR-002 Memory

- In-memory footprint should not exceed 3x raw data size, consistent with existing CSV pipeline constraints.

## Open Questions

- Field naming conventions for developer fields (exact FIT name vs normalized)?
- How to handle missing/unknown developer field types?
- Default unit mapping for common FIT fields (power, heart_rate, speed, cadence)?
