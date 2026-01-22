# Implementation Plan: CSV Processing Pipeline

**Branch**: `002-csv-processing-pipeline` | **Date**: 2026-01-22 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-csv-processing-pipeline/spec.md`

## Summary

Complete the braven_data package end-to-end data flow: CSV file ingestion → DataFrame columnar storage → Series extraction → Duration-based windowing → Chart-ready output (ChartDataPoint[]). This sprint builds on Sprint 001's core Series/Pipeline infrastructure to add CSV parsing, multiple X-value format support, and BravenChartPlus-compatible output.

## Technical Context

**Language/Version**: Dart 3.10+ (Pure Dart, no Flutter SDK)  
**Primary Dependencies**: dart:core, dart:typed_data, dart:collection, dart:convert (CSV parsing)  
**Storage**: In-memory columnar buffers (Float64List, Int64List)  
**Testing**: dart test (unit tests in test/unit/)  
**Target Platform**: Cross-platform Dart library (no platform-specific code)  
**Project Type**: Single Dart package (lib/src/ structure)  
**Performance Goals**: 
- Load 10,000-row CSV in <500ms
- Full pipeline (CSV → aggregate → chart output) in <1s for 3600 points
- Memory ≤3x raw data size for 100K points  
**Constraints**: 
- No third-party packages (pure Dart only)
- Files must fit in memory (no streaming)
- Single-threaded (no isolates this sprint)  
**Scale/Scope**: 
- Typical: 3,600 points (1-hour activity at 1Hz)
- Max: 200,000 points (60-hour event)
- High-frequency burst: 120,000 points (1kHz for 2 minutes)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Applicability | Status | Notes |
|-----------|--------------|--------|-------|
| I. Test-First Development | ✅ REQUIRED | ⏳ PENDING | All new classes need unit tests; TDD approach for CSV parsing |
| II. Performance First | ✅ REQUIRED | ✅ PASS | Columnar storage (Float64List) ensures 60fps-compatible data structures; no setState concerns (library, not UI) |
| III. Architectural Integrity | ✅ REQUIRED | ✅ PASS | Pure Dart, no platform-specific APIs, SOLID principles |
| IV. Requirements Compliance | ✅ REQUIRED | ⏳ PENDING | tasks.md tracking during implementation |
| V. API Consistency | ✅ REQUIRED | ✅ PASS | Following existing Series/Pipeline API patterns |
| VI. Documentation | ✅ REQUIRED | ⏳ PENDING | All public APIs need dartdoc |
| VII. Simplicity (KISS) | ✅ REQUIRED | ✅ PASS | Minimal dependencies, low-level typed arrays |

**Gate Status**: ✅ PASS - No blocking violations. Pending items are implementation-phase requirements.

## Project Structure

### Documentation (this feature)

```
specs/002-csv-processing-pipeline/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (API contracts)
│   └── api.dart         # Public API surface
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```
lib/
├── braven_data.dart         # Package exports
└── src/
    ├── aggregation.dart     # [EXISTS] WindowSpec, SeriesReducer
    ├── algorithms.dart      # [EXISTS] NP/xPower calculators
    ├── engine.dart          # [EXISTS] AggregationEngine
    ├── pipeline.dart        # [EXISTS] PipelineBuilder
    ├── series.dart          # [EXISTS] Series<TX,TY>
    ├── storage.dart         # [EXISTS] TypedDataStorage, IntervalStorage
    ├── csv/                  # [NEW] CSV ingestion layer
    │   ├── schema.dart       # CsvSchema, ColumnDef, XValueType
    │   ├── loader.dart       # CsvLoader.load()
    │   └── parser.dart       # Internal CSV parsing utilities
    ├── dataframe/            # [NEW] DataFrame support
    │   └── dataframe.dart    # DataFrame class
    ├── output/               # [NEW] Chart output layer
    │   ├── chart_data_point.dart  # ChartDataPoint structure
    │   └── series_chart_output.dart  # Series.toChartDataPoints() extension
    └── metrics/              # [NEW] SeriesMetric interface
        ├── series_metric.dart    # SeriesMetric<T> interface
        └── power_metrics.dart    # NP, xPower, VI as SeriesMetric

test/
├── unit/
│   ├── aggregation_test.dart   # [EXISTS]
│   ├── engine_test.dart        # [EXISTS]
│   ├── series_test.dart        # [EXISTS]
│   ├── storage_test.dart       # [EXISTS]
│   ├── csv/                    # [NEW]
│   │   ├── schema_test.dart
│   │   ├── loader_test.dart
│   │   └── parser_test.dart
│   ├── dataframe_test.dart     # [NEW]
│   ├── output_test.dart        # [NEW]
│   └── metrics_test.dart       # [NEW]
└── integration/                # [NEW]
    └── csv_to_chart_test.dart  # End-to-end pipeline test
```

**Structure Decision**: Single package with modular subdirectories under `lib/src/`. New code organized by domain (csv/, dataframe/, output/, metrics/) to maintain separation of concerns while preserving the flat test structure.

## Complexity Tracking

*No constitution violations requiring justification.*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (none) | — | — |

## Phase 0: Research Findings

See [research.md](research.md) for detailed analysis.

**Key Decisions**:
1. CSV parsing: Manual implementation using dart:convert's LineSplitter + split(',')
2. DateTime parsing: DateTime.parse() for ISO 8601, manual epoch conversion
3. X-value normalization: First timestamp becomes 0.0, all others relative
4. DataFrame storage: Map<String, List<dynamic>> with typed accessors
5. ChartDataPoint: Local copy of structure (no package dependency)

## Phase 1: Design Artifacts

- [data-model.md](data-model.md) - Entity definitions and relationships
- [contracts/api.dart](contracts/api.dart) - Public API surface
- [quickstart.md](quickstart.md) - Usage examples

---

**Next Step**: Run `/speckit.tasks` to generate implementation task breakdown.

