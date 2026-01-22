# Feature Specification: CSV Processing Pipeline

**Feature Branch**: `002-csv-processing-pipeline`  
**Created**: 2026-01-22  
**Status**: Draft  
**Input**: User description: "data-structure-enhancements"  
**Source**: [gaps_and_enhancements.md](../_base/002-data-enchancements/gaps_and_enhancements.md)

## Executive Summary

This feature completes the braven_data package by implementing the end-to-end data flow: **CSV file → Processing → Chart-ready output**. Sprint 001 established core Series storage and aggregation. This sprint adds CSV ingestion, DataFrame support, duration-based windowing, and chart output conversion—enabling users to load scientific data files, apply processing pipelines, and produce render-ready chart data for BravenChartPlus.

---

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Load CSV and Extract Series (Priority: P1)

A data analyst has a CSV file containing cycling performance data (power, heart rate, speed) recorded at 1Hz. They want to load this file into the braven_data library and extract individual data series for each metric column.

**Why this priority**: This is the foundational capability—without CSV loading, no subsequent processing is possible. It unblocks all downstream features.

**Independent Test**: Can be fully tested by loading a real Garmin CSV file and verifying that the power column is accessible as a typed Series with correct values.

**Acceptance Scenarios**:

1. **Given** a CSV file with timestamp and power columns, **When** the user defines a schema and loads the file, **Then** a DataFrame is created with typed columns accessible by name.
2. **Given** a DataFrame with a 'power' column, **When** the user extracts it as a Series, **Then** they receive a Series<double, double> with X values as elapsed seconds and Y values as power readings.
3. **Given** a CSV with ISO 8601 timestamps, **When** loading with an iso8601 X-type schema, **Then** timestamps are parsed and converted to elapsed seconds from the first record.

---

### User Story 2 - Apply Rolling Window Aggregation (Priority: P2)

A sports scientist wants to smooth noisy power data by applying a 30-second rolling average to create a readable power curve for visualization.

**Why this priority**: Rolling window aggregation is the core processing operation that transforms raw data into chart-ready format. It directly enables the primary use case.

**Independent Test**: Can be tested by applying a 30s rolling mean to a power Series and verifying the output has smoothed values with correct alignment.

**Acceptance Scenarios**:

1. **Given** a power Series with 1Hz data, **When** applying a 30-second rolling window with mean reducer, **Then** output Series has the same length with each point representing the 30s trailing average.
2. **Given** a rolling window operation, **When** specifying WindowAlignment.center, **Then** each output point represents the average of values 15s before and after that point.
3. **Given** a Series with 3600 points (1 hour), **When** applying duration-based windowing, **Then** window boundaries are computed from actual time values, not point counts.

---

### User Story 3 - Generate Chart-Ready Output (Priority: P3)

A developer integrating with BravenChartPlus needs to convert processed Series data into ChartDataPoint objects that the charting library can render directly.

**Why this priority**: This is the output boundary that delivers value to the rendering layer. Without this, processed data cannot be visualized.

**Independent Test**: Can be tested by calling toChartDataPoints() on a Series and verifying the returned list contains properly structured ChartDataPoint objects.

**Acceptance Scenarios**:

1. **Given** a processed Series, **When** calling toChartDataPoints(), **Then** a List<ChartDataPoint> is returned with x/y values from the Series.
2. **Given** an aggregated Series with min/max metadata, **When** calling toChartDataPoints(includeMinMax: true), **Then** each point's metadata map contains 'min' and 'max' keys.
3. **Given** a Series with original timestamps, **When** converting to chart points, **Then** each ChartDataPoint optionally includes the original DateTime in its timestamp field.

---

### User Story 4 - Calculate Scalar Metrics (Priority: P4)

A coach wants to calculate summary statistics for an entire workout—Normalized Power, Variability Index, and Average Power—displayed in a stats panel alongside the chart.

**Why this priority**: Scalar metrics complement visualization by providing single summary values. The calculation algorithms already exist; this adds the formal SeriesMetric interface for extensibility.

**Independent Test**: Can be tested by computing NormalizedPower on a known dataset and comparing against expected values calculated manually.

**Acceptance Scenarios**:

1. **Given** a power Series, **When** calling powerSeries.compute(NormalizedPowerMetric()), **Then** a single double value representing NP is returned.
2. **Given** the SeriesMetric interface, **When** implementing a custom metric, **Then** it can be passed to series.compute() and executed without modifying library code.
3. **Given** a Series, **When** computing multiple metrics, **Then** each metric calculation operates independently on the same source data.

---

### User Story 5 - Handle Multiple X-Value Formats (Priority: P5)

A researcher has CSV files from different instruments—some use ISO 8601 timestamps, others use elapsed milliseconds, and some use row indices. They want a single loading mechanism that handles all formats.

**Why this priority**: Real-world data comes in varied formats. Smart parsing reduces friction and errors during data import.

**Independent Test**: Can be tested by loading CSVs with different timestamp formats and verifying all are correctly normalized to elapsed seconds.

**Acceptance Scenarios**:

1. **Given** a CSV with ISO 8601 timestamps, **When** loading with xType: XValueType.iso8601, **Then** timestamps are parsed and normalized to elapsed seconds.
2. **Given** a CSV with epoch milliseconds, **When** loading with xType: XValueType.epochMillis, **Then** values are divided by 1000 and normalized.
3. **Given** a CSV with no explicit X column, **When** loading with xType: XValueType.rowIndex, **Then** row numbers (0, 1, 2...) are used as X values.
4. **Given** a CSV with ambiguous timestamp format, **When** auto-detection is enabled, **Then** the system correctly identifies the format based on value patterns.

---

### Edge Cases

- What happens when a CSV column contains null/empty values?
  - System uses the column's defaultValue from schema, or NaN for numeric columns.
- How does the system handle a rolling window larger than the data length?
  - Returns a Series where early points use all available data (partial windows).
- What if the user requests a column that doesn't exist in the CSV?
  - Throws a descriptive error during DataFrame construction.
- How does the system handle non-monotonic timestamps?
  - Preserves order as-is; X values reflect data order, not sorted time.

---

## Requirements _(mandatory)_

### Functional Requirements

#### CSV Ingestion Layer

- **FR-001**: System MUST support defining CSV schemas with column names and data types
- **FR-002**: System MUST parse CSV files into columnar DataFrame structures
- **FR-003**: System MUST support these column data types: float64, int64, string
- **FR-004**: System MUST handle missing values with configurable defaults
- **FR-005**: System MUST parse X-axis values in multiple formats: ISO 8601, epoch seconds, epoch milliseconds, elapsed seconds, row index

#### DataFrame & Series Extraction

- **FR-006**: DataFrame MUST provide type-safe column access by name
- **FR-007**: DataFrame MUST report row count and column names
- **FR-008**: System MUST allow extracting Series from DataFrame columns with zero-copy semantics (Series backed by same Float64List view when extracting numeric columns)
- **FR-009**: Series X values MUST be normalized to elapsed seconds from the first data point

#### Duration-Based Windowing

- **FR-010**: System MUST support duration-based window specifications (e.g., 30 seconds, 5 minutes)
- **FR-011**: System MUST support window alignment options: start, center, end
- **FR-012**: Rolling windows MUST default to trailing alignment (WindowAlignment.end)
- **FR-013**: Fixed windows MUST default to leading alignment (WindowAlignment.start)

#### Chart Output Layer

- **FR-014**: Series MUST provide a toChartDataPoints() method returning List<ChartDataPoint>
- **FR-015**: ChartDataPoint output MUST include x and y as required fields
- **FR-016**: ChartDataPoint output MUST support optional timestamp, label, and metadata fields
- **FR-017**: Aggregated data MUST be convertible to ChartDataPoint with min/max/count in metadata

#### Metrics Interface

- **FR-018**: System MUST define a SeriesMetric<T> interface for scalar calculations
- **FR-019**: System MUST provide built-in metrics: NormalizedPowerMetric, XPowerMetric, VariabilityIndexMetric
- **FR-020**: Custom metrics MUST be implementable without modifying library source

### Key Entities

- **DelimitedSchema**: Defines the structure of a delimited text file—X column, X type, and list of Y columns with their data types
- **DataFrame**: Columnar container holding parsed CSV data; provides typed access to columns by name
- **Series<TX, TY>**: Time-indexed data sequence with X and Y values; the primary unit of processing
- **ChartDataPoint**: Output structure compatible with BravenChartPlus; contains x, y, and optional metadata
- **SeriesMetric<T>**: Interface for computing a single scalar value from an entire Series (e.g., NP = 245 watts)
- **WindowSpec**: Configuration for windowing operations; supports count-based and duration-based windows
- **WindowAlignment**: Enum specifying where output points align relative to their window (start, center, end)

---

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: Users can load a 10,000-row CSV file and extract a Series in under 500ms
- **SC-002**: The complete pipeline (load CSV → rolling aggregate → chart output) executes in under 1 second for 1-hour (3600 points) datasets
- **SC-003**: Memory usage for a 100,000-point dataset does not exceed 3x the raw data size (demonstrating efficient columnar storage)
- **SC-004**: All reference implementation test cases from gaps_and_enhancements.md pass (Garmin CSV → power curve → ChartDataPoint[])
- **SC-005**: Users can implement a custom SeriesMetric in under 20 lines of code and integrate it without library modifications
- **SC-006**: Duration-based windows produce correct results verified against manually calculated values for a known dataset
- **SC-007**: Zero "dart analyze" warnings or errors in all new code

---

## Assumptions

1. CSV files are well-formed with consistent column counts per row
2. All numeric columns contain valid numeric data (non-numeric values treated as missing)
3. Timestamp columns use consistent format within a single file
4. Files fit in memory (streaming/chunked loading is out of scope for this sprint)
5. BravenChartPlus ChartDataPoint structure is stable and will not change during implementation

---

## Dependencies

- Sprint 001 implementation (Series, TypedDataStorage, SeriesReducer, PipelineBuilder)
- Reference implementations in specs/\_base/002-data-enchancements/reference_implementations/
- Sample test data: data/tp-2023646...core_records.csv

---

## Out of Scope

- Live streaming data ingestion
- Network-based data loading (only local files)
- Complex CSV dialects (multi-character delimiters, nested quotes)
- Integration with BravenChartPlus rendering code (only output format compatibility)
- Savitzky-Golay filtering (deferred to future sprint)
- Multi-resolution pyramid caching (deferred to future sprint)
- LTTB downsampling (deferred to future sprint per priority matrix)

---

## References

- [gaps_and_enhancements.md](../_base/002-data-enchancements/gaps_and_enhancements.md) - Comprehensive gap analysis and design decisions
- [chart_data_point.dart](../_base/002-data-enchancements/reference_implementations/chart_data_point.dart) - Target output structure
- [csv_ingestion_example.dart](../_base/002-data-enchancements/reference_implementations/csv_ingestion_example.dart) - Reference implementation
- [power_metrics.dart](../_base/002-data-enchancements/reference_implementations/power_metrics.dart) - Metric interface examples
