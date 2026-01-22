# Tasks: CSV Processing Pipeline

**Input**: Design documents from `/specs/002-csv-processing-pipeline/`  
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, contracts/api.dart ✓  
**Tests**: TDD approach - write tests FIRST, verify they FAIL, then implement  
**Organization**: Tasks grouped by user story for independent implementation and testing

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions
- **Source**: `lib/src/` with subdirectories (csv/, dataframe/, output/, metrics/)
- **Tests**: `test/unit/` with subdirectories matching source structure
- **Integration**: `test/integration/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create directory structure and base enums/types used across all stories

- [ ] T001 Create source directory structure: `lib/src/csv/`, `lib/src/dataframe/`, `lib/src/output/`, `lib/src/metrics/`
- [ ] T002 Create test directory structure: `test/unit/csv/`, `test/unit/dataframe/`, `test/unit/output/`, `test/unit/metrics/`, `test/integration/`
- [ ] T003 [P] Create `XValueType` enum in `lib/src/csv/x_value_type.dart`
- [ ] T004 [P] Create `FieldType` enum in `lib/src/csv/field_type.dart`
- [ ] T005 [P] Create `WindowAlignment` enum in `lib/src/output/window_alignment.dart`
- [ ] T006 Update `lib/braven_data.dart` to export new modules (empty initially, exports added as modules complete)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core types that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Foundation Tests (TDD)

- [ ] T007 [P] Write unit tests for `ColumnDef` in `test/unit/csv/column_def_test.dart` (validation, construction, defaults)
- [ ] T008 [P] Write unit tests for `CsvSchema` in `test/unit/csv/csv_schema_test.dart` (validation rules, builder pattern)

### Foundation Implementation

- [ ] T009 [P] Implement `ColumnDef` class in `lib/src/csv/column_def.dart` (name, type, defaultValue, unit)
- [ ] T010 Implement `CsvSchema` class in `lib/src/csv/schema.dart` (imports XValueType, FieldType from T003/T004; defines xColumn, xType, columns, hasHeader, delimiter)
- [ ] T011 [P] Create barrel export file `lib/src/csv/csv.dart` exporting all CSV types
- [ ] T012 Verify T007-T008 tests pass with `dart test test/unit/csv/`

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Load CSV and Extract Series (Priority: P1) 🎯 MVP

**Goal**: Load CSV file → DataFrame → Extract typed Series with normalized X values

**Independent Test**: Load real Garmin CSV file, verify power column accessible as Series<double, double> with correct values

### Tests for User Story 1 (TDD - Write FIRST, verify FAIL)

- [ ] T013 [P] [US1] Write parser unit tests in `test/unit/csv/parser_test.dart` (line splitting, field parsing, quoted values, empty values, non-monotonic timestamps preserved)
- [ ] T014 [P] [US1] Write X-value parsing tests in `test/unit/csv/x_value_parser_test.dart` (ISO 8601, epoch seconds, epoch millis, elapsed, rowIndex)
- [ ] T015 [P] [US1] Write CsvLoader tests in `test/unit/csv/loader_test.dart` (loadString, schema validation, error handling, malformed numeric values → NaN/default)
- [ ] T016 [P] [US1] Write DataFrame tests in `test/unit/dataframe/dataframe_test.dart` (construction, get<T>, getXValues, columnNames, rowCount)
- [ ] T017 [P] [US1] Write Series extraction tests in `test/unit/dataframe/series_extraction_test.dart` (toSeries, X normalization, metadata)

### Implementation for User Story 1

- [ ] T018 [P] [US1] Implement CSV parser utilities in `lib/src/csv/parser.dart` (line splitting, field parsing)
- [ ] T019 [P] [US1] Implement X-value parser in `lib/src/csv/x_value_parser.dart` (all XValueType conversions)
- [ ] T020 [US1] Implement `DataFrame` class in `lib/src/dataframe/dataframe.dart` (columnar storage, typed accessors)
- [ ] T021 [US1] Implement `CsvLoader` class in `lib/src/csv/loader.dart` (loadString, load async)
- [ ] T022 [US1] Add `toSeries()` method to DataFrame in `lib/src/dataframe/dataframe.dart` (X normalization, zero-copy)
- [ ] T023 [US1] Update barrel exports: `lib/src/csv/csv.dart`, create `lib/src/dataframe/dataframe.dart` barrel
- [ ] T024 [US1] Update `lib/braven_data.dart` to export csv and dataframe modules
- [ ] T025 [US1] Verify T013-T017 tests pass with `dart test test/unit/csv/ test/unit/dataframe/`
- [ ] T026 [US1] Run `dart analyze` and fix all issues in new files

**Checkpoint**: User Story 1 complete - CSV files can be loaded and Series extracted

---

## Phase 4: User Story 2 - Apply Rolling Window Aggregation (Priority: P2)

**Goal**: Apply duration-based rolling windows with configurable alignment to Series data

**Independent Test**: Apply 30s rolling mean to power Series, verify output has smoothed values with correct alignment

**Dependencies**: Builds on existing `WindowSpec` and `AggregationEngine` from Sprint 001

### Tests for User Story 2 (TDD - Write FIRST, verify FAIL)

- [ ] T027 [P] [US2] Write WindowAlignment tests in `test/unit/output/window_alignment_test.dart` (start, center, end behavior)
- [ ] T028 [P] [US2] Write duration window tests in `test/unit/aggregation_duration_test.dart` (Duration→point count conversion, sample rate inference)
- [ ] T029 [P] [US2] Write rolling window integration tests in `test/unit/aggregation_rolling_test.dart` (30s window, alignment options)

### Implementation for User Story 2

- [ ] T030 [US2] Extend `WindowSpec` with `fixedDuration()` and `rollingDuration()` factory methods in `lib/src/aggregation.dart`
- [ ] T031 [US2] Implement sample rate inference from Series X values in `lib/src/aggregation.dart`
- [ ] T032 [US2] Integrate `WindowAlignment` into `AggregationEngine` in `lib/src/engine.dart`
- [ ] T033 [US2] Update `lib/braven_data.dart` to export `WindowAlignment`
- [ ] T034 [US2] Verify T027-T029 tests pass with `dart test test/unit/output/ test/unit/aggregation_duration_test.dart test/unit/aggregation_rolling_test.dart`
- [ ] T035 [US2] Run `dart analyze` and fix all issues in modified files

**Checkpoint**: User Story 2 complete - Duration-based windowing with alignment works

---

## Phase 5: User Story 3 - Generate Chart-Ready Output (Priority: P3)

**Goal**: Convert processed Series to ChartDataPoint[] compatible with BravenChartPlus

**Independent Test**: Call toChartDataPoints() on a Series, verify List<ChartDataPoint> returned with proper structure

### Tests for User Story 3 (TDD - Write FIRST, verify FAIL)

- [ ] T036 [P] [US3] Write ChartDataPoint tests in `test/unit/output/chart_data_point_test.dart` (construction, equality, metadata)
- [ ] T037 [P] [US3] Write Series extension tests in `test/unit/output/series_chart_output_test.dart` (toChartDataPoints, includeMinMax, includeTimestamp)
- [ ] T038 [P] [US3] Write alternative output tests in `test/unit/output/series_output_formats_test.dart` (toMapList, toTuples)

### Implementation for User Story 3

- [ ] T039 [P] [US3] Implement `ChartDataPoint` class in `lib/src/output/chart_data_point.dart` (x, y, timestamp, label, metadata)
- [ ] T040 [US3] Implement `SeriesChartOutput` extension in `lib/src/output/series_chart_output.dart` (toChartDataPoints)
- [ ] T040a [US3] Implement aggregated metadata propagation in `lib/src/output/series_chart_output.dart` (min/max/count from IntervalStorage → ChartDataPoint.metadata per FR-017)
- [ ] T041 [US3] Implement alternative output methods in `lib/src/output/series_chart_output.dart` (toMapList, toTuples)
- [ ] T042 [US3] Create barrel export `lib/src/output/output.dart`
- [ ] T043 [US3] Update `lib/braven_data.dart` to export output module
- [ ] T044 [US3] Verify T036-T038 tests pass with `dart test test/unit/output/`
- [ ] T045 [US3] Run `dart analyze` and fix all issues in new files

**Checkpoint**: User Story 3 complete - Series can be converted to chart-ready format

---

## Phase 6: User Story 4 - Calculate Scalar Metrics (Priority: P4)

**Goal**: Compute summary statistics (NP, VI, xPower) via SeriesMetric<T> interface

**Independent Test**: Compute NormalizedPower on known dataset, compare against manually calculated value

**Dependencies**: Existing algorithms (npPowerCalculator, xPowerCalculator) from Sprint 001

### Tests for User Story 4 (TDD - Write FIRST, verify FAIL)

- [ ] T046 [P] [US4] Write SeriesMetric interface tests in `test/unit/metrics/series_metric_test.dart` (interface contract, custom metric)
- [ ] T047 [P] [US4] Write NormalizedPowerMetric tests in `test/unit/metrics/power_metrics_test.dart` (known input/output values)
- [ ] T048 [P] [US4] Write XPowerMetric tests in `test/unit/metrics/power_metrics_test.dart` (EWMA behavior, known values)
- [ ] T049 [P] [US4] Write VariabilityIndexMetric tests in `test/unit/metrics/power_metrics_test.dart` (NP/AvgPower ratio)
- [ ] T050 [P] [US4] Write basic metric tests (MeanMetric, MaxMetric) in `test/unit/metrics/basic_metrics_test.dart`

### Implementation for User Story 4

- [ ] T051 [P] [US4] Define `SeriesMetric<T>` interface in `lib/src/metrics/series_metric.dart`
- [ ] T052 [P] [US4] Implement `MeanMetric` and `MaxMetric` in `lib/src/metrics/basic_metrics.dart`
- [ ] T053 [US4] Implement `NormalizedPowerMetric` in `lib/src/metrics/power_metrics.dart` (wraps existing algorithm)
- [ ] T054 [US4] Implement `XPowerMetric` in `lib/src/metrics/power_metrics.dart` (wraps existing algorithm)
- [ ] T055 [US4] Implement `VariabilityIndexMetric` in `lib/src/metrics/power_metrics.dart`
- [ ] T056 [US4] Add `compute<T>(SeriesMetric<T>)` extension method on Series in `lib/src/metrics/series_metric.dart`
- [ ] T057 [US4] Create barrel export `lib/src/metrics/metrics.dart`
- [ ] T058 [US4] Update `lib/braven_data.dart` to export metrics module
- [ ] T059 [US4] Verify T046-T050 tests pass with `dart test test/unit/metrics/`
- [ ] T060 [US4] Run `dart analyze` and fix all issues in new files

**Checkpoint**: User Story 4 complete - Scalar metrics can be computed from Series

---

## Phase 7: User Story 5 - Handle Multiple X-Value Formats (Priority: P5)

**Goal**: Auto-detect X-value format from value patterns when schema doesn't specify explicit type

**Independent Test**: Load CSVs with different timestamp formats (ISO, epoch, elapsed), verify all normalize correctly

**Note**: Core parsing already implemented in US1; this adds auto-detection layer

### Tests for User Story 5 (TDD - Write FIRST, verify FAIL)

- [ ] T061 [P] [US5] Write auto-detection tests in `test/unit/csv/x_value_detector_test.dart` (pattern matching for all formats)
- [ ] T062 [P] [US5] Write mixed format edge case tests in `test/unit/csv/x_value_detector_test.dart` (ambiguous values, fallbacks)

### Implementation for User Story 5

- [ ] T063 [US5] Implement `XValueDetector` class in `lib/src/csv/x_value_detector.dart` (pattern-based format detection)
- [ ] T064 [US5] Integrate auto-detection into `CsvLoader` when `xType` is not explicitly specified in `lib/src/csv/loader.dart`
- [ ] T065 [US5] Update barrel exports in `lib/src/csv/csv.dart`
- [ ] T066 [US5] Verify T061-T062 tests pass with `dart test test/unit/csv/x_value_detector_test.dart`
- [ ] T067 [US5] Run `dart analyze` and fix all issues

**Checkpoint**: User Story 5 complete - Multiple X-value formats handled transparently

---

## Phase 8: Integration & Polish

**Purpose**: End-to-end validation and cross-cutting improvements

### Integration Tests

- [ ] T068 [P] Write end-to-end pipeline test in `test/integration/csv_to_chart_test.dart` (Load Garmin CSV → 30s rolling mean → ChartDataPoint[])
- [ ] T069 [P] Write performance benchmark test in `test/benchmarks/csv_pipeline_perf_test.dart` (verify SC-001, SC-002; SC-003 memory via ProcessInfo.currentRss before/after load)

### Documentation & Quality

- [ ] T070 [P] Add dartdoc comments to all public APIs (verify with `dart doc --validate`)
- [ ] T071 Run full test suite: `dart test`
- [ ] T072 Run `dart analyze` on entire project - must show "No issues found!"
- [ ] T073 Run quickstart.md validation: manually verify code examples work
- [ ] T074 Update README.md with new CSV processing capabilities

### Cleanup

- [ ] T075 Review and refactor any code smells identified during implementation
- [ ] T076 Verify all success criteria from spec.md are met (SC-001 through SC-007)

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1: Setup ──────────────────────────────────────────────────────▶ [No deps]
    │
    ▼
Phase 2: Foundational ───────────────────────────────────────────────▶ [Blocks all stories]
    │
    ├──────────────────────────────────────────────────────────────────▶ Phase 3: US1 (P1) 🎯 MVP
    │                                                                           │
    ├──────────────────────────────────────────────────────────────────▶ Phase 4: US2 (P2)
    │                                                                           │
    ├──────────────────────────────────────────────────────────────────▶ Phase 5: US3 (P3)
    │                                                                           │
    ├──────────────────────────────────────────────────────────────────▶ Phase 6: US4 (P4)
    │                                                                           │
    └──────────────────────────────────────────────────────────────────▶ Phase 7: US5 (P5)
                                                                                │
                                                                                ▼
                                                                        Phase 8: Integration
```

### User Story Dependencies

| Story | Depends On | Can Parallelize With |
|-------|-----------|---------------------|
| US1 (P1) | Phase 2 only | US2, US3, US4, US5 (after Phase 2) |
| US2 (P2) | Phase 2 only | US1, US3, US4, US5 (after Phase 2) |
| US3 (P3) | Phase 2, needs Series (US1 for real data) | US2, US4, US5 |
| US4 (P4) | Phase 2, needs Series | US1, US2, US3, US5 |
| US5 (P5) | US1 (extends loader) | — |

### Within Each Phase

1. **Tests FIRST**: Write all tests marked [P] in parallel, verify they FAIL
2. **Implementation**: Complete in dependency order
3. **Validation**: Run tests, run analyzer
4. **Checkpoint**: Verify phase complete before next

### Parallel Opportunities per Phase

**Phase 1 (Setup)**:
- T003, T004, T005 can run in parallel (different enum files)

**Phase 2 (Foundation)**:
- T007, T008 can run in parallel (different test files)
- T009, T011 can run in parallel after tests written

**Phase 3 (US1)**:
- T013, T014, T015, T016, T017 can run in parallel (different test files)
- T018, T019 can run in parallel (different source files)

**Phases 4-7**:
- All test tasks within each phase can run in parallel
- Implementation tasks follow test completion

**Phase 8**:
- T068, T069, T070 can run in parallel

---

## Task Count Summary

| Phase | Description | Task Count |
|-------|-------------|------------|
| Phase 1 | Setup | 6 |
| Phase 2 | Foundational | 6 |
| Phase 3 | US1 - CSV Loading (MVP) | 14 |
| Phase 4 | US2 - Rolling Windows | 9 |
| Phase 5 | US3 - Chart Output | 11 |
| Phase 6 | US4 - Scalar Metrics | 15 |
| Phase 7 | US5 - Format Detection | 7 |
| Phase 8 | Integration & Polish | 9 |
| **TOTAL** | | **77** |

### Tasks per User Story

| User Story | Priority | Task Count | Independent? |
|------------|----------|------------|--------------|
| US1 | P1 (MVP) | 14 | ✅ Yes |
| US2 | P2 | 9 | ✅ Yes |
| US3 | P3 | 11 | ✅ Yes |
| US4 | P4 | 15 | ✅ Yes |
| US5 | P5 | 7 | Depends on US1 |

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (6 tasks)
2. Complete Phase 2: Foundational (6 tasks)
3. Complete Phase 3: User Story 1 (14 tasks)
4. **STOP and VALIDATE**: Run integration test with real Garmin CSV
5. ✅ MVP Deliverable: CSV → DataFrame → Series

### Incremental Delivery

| Increment | Phases | Cumulative Value |
|-----------|--------|------------------|
| MVP | 1 + 2 + 3 | CSV loading, Series extraction |
| +US2 | + 4 | Duration-based rolling windows |
| +US3 | + 5 | Chart-ready output |
| +US4 | + 6 | Scalar metrics (NP, xP, VI) |
| +US5 | + 7 | Auto-detect timestamp formats |
| Complete | + 8 | Fully validated, documented |

### Success Criteria Mapping

| Criterion | Validated In | Phase |
|-----------|-------------|-------|
| SC-001 (10K rows < 500ms) | T069 | 8 |
| SC-002 (Full pipeline < 1s) | T069 | 8 |
| SC-003 (Memory ≤ 3x) | T069 | 8 |
| SC-004 (Garmin CSV test passes) | T068 | 8 |
| SC-005 (Custom metric < 20 lines) | T046 | 6 |
| SC-006 (Duration windows correct) | T028, T029 | 4 |
| SC-007 (Zero analyze warnings) | T026, T035, T045, T060, T067, T072 | All |

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks in same phase
- [Story] label maps task to specific user story for traceability
- Each user story is independently completable and testable
- TDD: Verify tests FAIL before implementing
- Commit after each task or logical group
- Run `dart analyze` after each phase - must show "No issues found!"
- Stop at any checkpoint to validate story independently
