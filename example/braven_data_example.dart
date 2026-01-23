/// braven_data example app
///
/// This example demonstrates the key features of the braven_data package:
/// 1. Loading CSV data with schema definition
/// 2. Extracting Series from DataFrame
/// 3. Applying rolling window aggregation
/// 4. Calculating scalar metrics (NormalizedPower, VariabilityIndex)
/// 5. Converting to chart-ready output
/// 6. Custom metric implementation
/// 7. FIT file loading (records, laps, sessions)
///
/// Run with: dart run example/braven_data_example.dart
library;

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:braven_data/braven_data.dart';

Future<void> main() async {
  print('═' * 60);
  print(' braven_data Examples');
  print('═' * 60);
  print('');

  exampleLoadCsvData();
  exampleSeriesOperations();
  exampleRollingAggregation();
  exampleScalarMetrics();
  exampleChartOutput();
  exampleCustomMetric();
  exampleXValueAutoDetection();
  await exampleFitLoading();
  await exampleDistributionAnalysis();

  print('');
  print('═' * 60);
  print(' All examples completed successfully!');
  print('═' * 60);
}

// ============================================================================
// Example 1: Loading CSV Data
// ============================================================================

void exampleLoadCsvData() {
  print('┌─────────────────────────────────────────────────────────┐');
  print('│ Example 1: Loading CSV Data                             │');
  print('└─────────────────────────────────────────────────────────┘');

  // Define schema for cycling power data
  final schema = DelimitedSchema(
    xColumn: 'timestamp',
    xType: XValueType.iso8601,
    columns: [
      ColumnDef(name: 'power', type: FieldType.float64, unit: 'W'),
      ColumnDef(name: 'heart_rate', type: FieldType.int64, unit: 'bpm'),
      ColumnDef(name: 'cadence', type: FieldType.int64, unit: 'rpm'),
      ColumnDef(name: 'speed', type: FieldType.float64, unit: 'm/s'),
    ],
  );

  // Sample CSV data (simulating a 10-second cycling segment)
  const csvContent = '''
timestamp,power,heart_rate,cadence,speed
2024-01-15T10:00:00Z,245,142,85,8.5
2024-01-15T10:00:01Z,252,143,87,8.6
2024-01-15T10:00:02Z,248,144,86,8.5
2024-01-15T10:00:03Z,255,145,88,8.7
2024-01-15T10:00:04Z,261,146,89,8.8
2024-01-15T10:00:05Z,258,147,88,8.7
2024-01-15T10:00:06Z,250,148,86,8.6
2024-01-15T10:00:07Z,242,147,84,8.4
2024-01-15T10:00:08Z,238,146,83,8.3
2024-01-15T10:00:09Z,245,145,85,8.5
''';

  // Load the CSV
  final dataFrame = DelimitedLoader.loadString(csvContent, schema);

  print('  Loaded DataFrame:');
  print('    Rows: ${dataFrame.rowCount}');
  print('    Columns: ${dataFrame.columnNames.join(", ")}');
  print('');

  // Access column data
  final powerColumn = dataFrame.get<double>('power');
  print('  First 5 power values: ${powerColumn.take(5).map((v) => "${v}W").join(", ")}');
  print('');
}

// ============================================================================
// Example 2: Series Operations
// ============================================================================

void exampleSeriesOperations() {
  print('┌─────────────────────────────────────────────────────────┐');
  print('│ Example 2: Series Operations                            │');
  print('└─────────────────────────────────────────────────────────┘');

  // Create a Series from raw data
  final series = _createSamplePowerSeries(100);

  print('  Created Series:');
  print('    ID: ${series.id}');
  print('    Length: ${series.length} points');
  print('    Meta: ${series.meta.name} (${series.meta.unit})');
  print('');

  // Access individual points
  print('  First 5 points:');
  for (var i = 0; i < 5; i++) {
    print('    [$i] x=${series.getX(i).toStringAsFixed(1)}, y=${series.getY(i).toStringAsFixed(1)}');
  }
  print('');

  // Basic statistics using iteration
  var sum = 0.0;
  var maxVal = double.negativeInfinity;
  var minVal = double.infinity;
  for (var i = 0; i < series.length; i++) {
    final y = series.getY(i);
    sum += y;
    if (y > maxVal) maxVal = y;
    if (y < minVal) minVal = y;
  }
  final mean = sum / series.length;

  print('  Basic Stats (manual):');
  print('    Min: ${minVal.toStringAsFixed(1)} W');
  print('    Max: ${maxVal.toStringAsFixed(1)} W');
  print('    Mean: ${mean.toStringAsFixed(1)} W');
  print('');
}

// ============================================================================
// Example 3: Rolling Aggregation (Smoothing)
// ============================================================================

void exampleRollingAggregation() {
  print('┌─────────────────────────────────────────────────────────┐');
  print('│ Example 3: Rolling Aggregation (Smoothing)              │');
  print('└─────────────────────────────────────────────────────────┘');

  // Create noisy power data (1Hz for 60 seconds)
  final rawSeries = _createNoisyPowerSeries(60, basePower: 200, noiseAmplitude: 50);

  print('  Raw Series: ${rawSeries.length} points');

  // Apply 5-second rolling average (duration-based)
  final smoothed5 = rawSeries.aggregate(
    AggregationSpec(
      window: WindowSpec.rollingDuration(const Duration(seconds: 5)),
      reducer: SeriesReducer.mean,
    ),
  );

  // Apply 10-second rolling average
  final smoothed10 = rawSeries.aggregate(
    AggregationSpec(
      window: WindowSpec.rollingDuration(const Duration(seconds: 10)),
      reducer: SeriesReducer.mean,
    ),
  );

  print('  5-second rolling mean: ${smoothed5.length} points');
  print('  10-second rolling mean: ${smoothed10.length} points');
  print('');

  // Compare variance reduction
  final rawVariance = _calculateVariance(rawSeries);
  final smooth5Variance = _calculateVariance(smoothed5);
  final smooth10Variance = _calculateVariance(smoothed10);

  print('  Variance comparison (lower = smoother):');
  print('    Raw data:          ${rawVariance.toStringAsFixed(1)}');
  print('    5-sec rolling:     ${smooth5Variance.toStringAsFixed(1)} (${(100 * smooth5Variance / rawVariance).toStringAsFixed(0)}% of raw)');
  print('    10-sec rolling:    ${smooth10Variance.toStringAsFixed(1)} (${(100 * smooth10Variance / rawVariance).toStringAsFixed(0)}% of raw)');
  print('');
}

// ============================================================================
// Example 4: Scalar Metrics
// ============================================================================

void exampleScalarMetrics() {
  print('┌─────────────────────────────────────────────────────────┐');
  print('│ Example 4: Scalar Metrics                               │');
  print('└─────────────────────────────────────────────────────────┘');

  // Create realistic cycling power data (30 minutes at 1Hz)
  final powerSeries = _createRealisticPowerSeries(1800);

  print('  Power data: ${powerSeries.length} points (30 minutes @ 1Hz)');
  print('');

  // Calculate metrics using the SeriesMetric interface
  final avgPower = powerSeries.compute(const MeanMetric());
  final maxPower = powerSeries.compute(const MaxMetric());
  final normalizedPower = powerSeries.compute(NormalizedPowerMetric());
  final variabilityIndex = powerSeries.compute(const VariabilityIndexMetric());

  print('  Cycling Metrics:');
  print('    Average Power:     ${avgPower.toStringAsFixed(1)} W');
  print('    Max Power:         ${maxPower.toStringAsFixed(0)} W');
  print('    Normalized Power:  ${normalizedPower.toStringAsFixed(1)} W');
  print('    Variability Index: ${variabilityIndex.toStringAsFixed(3)}');
  print('');

  // Explain the metrics
  print('  Interpretation:');
  print('    • NP > Avg indicates variable effort (intervals, hills)');
  print('    • VI = NP/Avg, higher = more variable');
  print('    • VI near 1.0 = steady-state effort');
  print('    • VI > 1.1 = variable/interval workout');
  print('');
}

// ============================================================================
// Example 5: Chart Output
// ============================================================================

void exampleChartOutput() {
  print('┌─────────────────────────────────────────────────────────┐');
  print('│ Example 5: Chart Output                                 │');
  print('└─────────────────────────────────────────────────────────┘');

  // Create sample series
  final series = _createSamplePowerSeries(20);

  // Convert to ChartDataPoint list
  final chartPoints = series.toChartDataPoints();

  print('  Basic ChartDataPoints:');
  for (var i = 0; i < min(3, chartPoints.length); i++) {
    final p = chartPoints[i];
    print('    [$i] x=${p.x.toStringAsFixed(1)}, y=${p.y.toStringAsFixed(1)}');
  }
  print('    ...');
  print('');

  // Convert with min/max metadata (for error bars)
  final richPoints = series.toChartDataPoints(includeMinMax: true);

  print('  Rich ChartDataPoints (with metadata):');
  for (var i = 0; i < min(3, richPoints.length); i++) {
    final p = richPoints[i];
    print('    [$i] x=${p.x.toStringAsFixed(1)}, y=${p.y.toStringAsFixed(1)}, meta=${p.metadata}');
  }
  print('    ...');
  print('');

  // Alternative output formats
  final mapList = series.toMapList();
  final tuples = series.toTuples();

  print('  Alternative formats:');
  print('    toMapList(): ${mapList.take(2).toList()}...');
  print('    toTuples():  ${tuples.take(2).toList()}...');
  print('');
}

// ============================================================================
// Example 6: Custom Metric
// ============================================================================

void exampleCustomMetric() {
  print('┌─────────────────────────────────────────────────────────┐');
  print('│ Example 6: Custom Metric                                │');
  print('└─────────────────────────────────────────────────────────┘');

  final series = _createSamplePowerSeries(100);

  // Use custom RMS metric
  final rms = series.compute(const RmsMetric());
  final mean = series.compute(const MeanMetric());

  print('  Custom RMS (Root Mean Square) Metric:');
  print('    RMS:  ${rms.toStringAsFixed(2)}');
  print('    Mean: ${mean.toStringAsFixed(2)}');
  print('    Ratio RMS/Mean: ${(rms / mean).toStringAsFixed(3)}');
  print('');

  // Use custom percentile metric
  final p50 = series.compute(const PercentileMetric(0.50));
  final p90 = series.compute(const PercentileMetric(0.90));
  final p95 = series.compute(const PercentileMetric(0.95));

  print('  Custom Percentile Metric:');
  print('    P50 (median): ${p50.toStringAsFixed(1)}');
  print('    P90:          ${p90.toStringAsFixed(1)}');
  print('    P95:          ${p95.toStringAsFixed(1)}');
  print('');
}

// ============================================================================
// Example 7: X-Value Auto-Detection
// ============================================================================

void exampleXValueAutoDetection() {
  print('┌─────────────────────────────────────────────────────────┐');
  print('│ Example 7: X-Value Auto-Detection                       │');
  print('└─────────────────────────────────────────────────────────┘');

  // Test different timestamp formats
  final testCases = <String, List<String>>{
    'ISO 8601': ['2024-01-15T10:00:00Z', '2024-01-15T10:00:01Z', '2024-01-15T10:00:02Z'],
    'Epoch seconds': ['1705312800', '1705312801', '1705312802'],
    'Epoch millis': ['1705312800000', '1705312801000', '1705312802000'],
    'Elapsed seconds': ['0.0', '1.0', '2.0', '3.0', '4.0'],
  };

  print('  Auto-detection results:');
  for (final entry in testCases.entries) {
    final detected = XValueDetector.detect(entry.value);
    print('    ${entry.key.padRight(16)} → $detected');
  }
  print('');
}

// ============================================================================
// Example 8: FIT File Loading
// ============================================================================

Future<void> exampleFitLoading() async {
  print('┌─────────────────────────────────────────────────────────┐');
  print('│ Example 8: FIT File Loading                             │');
  print('└─────────────────────────────────────────────────────────┘');

  const fitPath = 'specs/_base/003-fit-file/joubertjp.2020-12-05-16-16-30-219Z.GarminPush.74900175025.fit';
  final fitFile = File(fitPath);
  if (!fitFile.existsSync()) {
    print('  FIT file not found at $fitPath');
    print('');
    return;
  }

  final records = await FitLoader.load(
    fitFile.path,
    FitMessageType.records,
  );

  print('  Records DataFrame:');
  print('    Rows: ${records.rowCount}');
  print('    Columns: ${records.columnNames.take(10).join(", ")}${records.columnNames.length > 10 ? "..." : ""}');

  final powerValues = records.columns['power'];
  if (powerValues != null && powerValues.isNotEmpty) {
    print('    First 5 power values: ${powerValues.take(5).map((v) => (v as num).toStringAsFixed(1)).join(", ")}');
  }

  print('');
  if (records.columnNames.contains('power')) {
    final powerSeries = records.toSeries('power', meta: const SeriesMeta(name: 'Power', unit: 'W'));
    if (powerSeries.length < 2) {
      print('  Not enough power samples to compute rolling metrics.');
      print('');
    } else {
      // Use duration-based rolling window (supported by AggregationEngine)
      const windowDuration = Duration(seconds: 30);
      final rollingNpSeries = powerSeries.aggregate(
        AggregationSpec(
          window: WindowSpec.rollingDuration(windowDuration),
          // Use standard NP reducer from library
          reducer: SeriesReducer.normalizedPower,
        ),
      );

      final normalizedPower = _computeNormalizedPowerFromRollingValues(rollingNpSeries);

      // Also Calculate xPower using standard reducer
      // For rolling xPower, we might want a similar rolling window
      final rollingXPowerSeries = powerSeries.aggregate(AggregationSpec(
        window: WindowSpec.rollingDuration(windowDuration),
        // xPower specific reducer
        reducer: SeriesReducer.xPower(timeConstantSeconds: 25),
      ));
      final xPower = _computeNormalizedPowerFromRollingValues(rollingXPowerSeries);

      if (rollingNpSeries.length == 0) {
        print('  Not enough power samples for a 30s rolling window.');
        print('');
      } else {
        print('  Power Series:');
        print('    Samples: ${powerSeries.length}');
        print('    30s Rolling NP Points: ${rollingNpSeries.length}');
        print('    Normalized Power (SeriesReducer): ${normalizedPower.toStringAsFixed(1)} W');
        print('    xPower (SeriesReducer): ${xPower.toStringAsFixed(1)} W');
        print('');
      }
    }
  } else {
    print('  Power column not found in FIT records.');
    print('');
  }

  final laps = await FitLoader.load(
    fitFile.path,
    FitMessageType.laps,
  );
  print('  Laps DataFrame:');
  print('    Rows: ${laps.rowCount}');
  print('    Columns: ${laps.columnNames.join(", ")}');
  print('');

  final sessions = await FitLoader.load(
    fitFile.path,
    FitMessageType.sessions,
  );
  print('  Sessions DataFrame:');
  print('    Rows: ${sessions.rowCount}');
  print('    Columns: ${sessions.columnNames.join(", ")}');
  print('');
}

// ============================================================================
// Custom Metrics
// ============================================================================

/// Root Mean Square metric - useful for AC power analysis
class RmsMetric implements SeriesMetric<double> {
  const RmsMetric();

  @override
  double calculate(Series<dynamic, double> series) {
    var sumSquares = 0.0;
    for (var i = 0; i < series.length; i++) {
      final v = series.getY(i);
      sumSquares += v * v;
    }
    return sqrt(sumSquares / series.length);
  }
}

/// Percentile metric - returns the value at a given percentile
class PercentileMetric implements SeriesMetric<double> {
  final double percentile;

  const PercentileMetric(this.percentile) : assert(percentile >= 0 && percentile <= 1);

  @override
  double calculate(Series<dynamic, double> series) {
    final values = <double>[];
    for (var i = 0; i < series.length; i++) {
      values.add(series.getY(i));
    }
    values.sort();

    final index = ((values.length - 1) * percentile).round();
    return values[index];
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Creates a simple power series with incrementing values
Series<double, double> _createSamplePowerSeries(int count) {
  final xValues = Float64List.fromList(
    List<double>.generate(count, (i) => i.toDouble()),
  );
  final yValues = Float64List.fromList(
    List<double>.generate(count, (i) => 200.0 + (i % 20) * 3),
  );

  return Series<double, double>.fromTypedData(
    id: 'power_sample',
    xValues: xValues,
    yValues: yValues,
    meta: const SeriesMeta(name: 'Power', unit: 'W'),
  );
}

/// Creates noisy power data simulating real cycling
Series<double, double> _createNoisyPowerSeries(
  int count, {
  double basePower = 200,
  double noiseAmplitude = 30,
}) {
  final random = Random(42); // Fixed seed for reproducibility
  final xValues = Float64List.fromList(
    List<double>.generate(count, (i) => i.toDouble()),
  );
  final yValues = Float64List.fromList(
    List<double>.generate(
      count,
      (i) => basePower + (random.nextDouble() - 0.5) * 2 * noiseAmplitude,
    ),
  );

  return Series<double, double>.fromTypedData(
    id: 'power_noisy',
    xValues: xValues,
    yValues: yValues,
    meta: const SeriesMeta(name: 'Power', unit: 'W'),
  );
}

/// Creates realistic cycling power data with intervals
Series<double, double> _createRealisticPowerSeries(int count) {
  final random = Random(123);
  final xValues = List<double>.generate(count, (i) => i.toDouble());
  final yValues = <double>[];

  for (var i = 0; i < count; i++) {
    // Simulate varying effort with intervals
    double basePower;
    final minute = i ~/ 60;

    if (minute % 5 == 4) {
      // Every 5th minute is a hard interval
      basePower = 280;
    } else if (minute % 5 == 0) {
      // Recovery after interval
      basePower = 150;
    } else {
      // Steady state
      basePower = 200;
    }

    // Add realistic noise
    final noise = (random.nextDouble() - 0.5) * 40;
    yValues.add(max(0, basePower + noise));
  }

  return Series<double, double>.fromTypedData(
    id: 'power_realistic',
    xValues: Float64List.fromList(xValues),
    yValues: Float64List.fromList(yValues),
    meta: const SeriesMeta(name: 'Power', unit: 'W'),
  );
}

/// Calculate variance of a series
double _calculateVariance(Series<double, double> series) {
  var sum = 0.0;
  for (var i = 0; i < series.length; i++) {
    sum += series.getY(i);
  }
  final mean = sum / series.length;

  var sumSquaredDiff = 0.0;
  for (var i = 0; i < series.length; i++) {
    final diff = series.getY(i) - mean;
    sumSquaredDiff += diff * diff;
  }
  return sumSquaredDiff / series.length;
}

/// Computes Normalized Power from rolling window values.
///
/// Applies power(4) → mean → power(0.25) across the rolling output.
/// Skips NaN values (from null power readings).
double _computeNormalizedPowerFromRollingValues(Series<double, double> rollingSeries) {
  if (rollingSeries.length == 0) {
    return 0.0;
  }

  var sumPower4 = 0.0;
  var validCount = 0;
  for (var i = 0; i < rollingSeries.length; i++) {
    final value = rollingSeries.getY(i);
    if (!value.isNaN && !value.isInfinite) {
      sumPower4 += pow4(value);
      validCount++;
    }
  }

  if (validCount == 0) {
    return 0.0;
  }

  final meanPower4 = sumPower4 / validCount;
  return root4(meanPower4);
}

// ============================================================================
// Example 9: Distribution Analysis
// ============================================================================

Future<void> exampleDistributionAnalysis() async {
  print('┌─────────────────────────────────────────────────────────┐');
  print('│ Example 9: Distribution Analysis (Zones)                │');
  print('└─────────────────────────────────────────────────────────┘');

  // Use the FIT file from Example 8 if available
  const fitPath = 'specs/_base/003-fit-file/joubertjp.2020-12-05-16-16-30-219Z.GarminPush.74900175025.fit';
  final fitFile = File(fitPath);

  if (!fitFile.existsSync()) {
    print('  FIT file not found at $fitPath');
    // Fallback to generated data
    print('  Generating synthetic data for demonstration...');
    final syntheticData = _createRealisticPowerSeries(3600); // 1 hour
    _runDistributionOnSeries(syntheticData);
    return;
  }

  print('  Loading FIT file: $fitPath');
  // Load FIT records
  final df = await FitLoader.load(fitPath, FitMessageType.records);

  if (df.columnNames.contains('power')) {
    final powerSeries = df.toSeries('power', meta: const SeriesMeta(name: 'Power', unit: 'W'));
    print('  Power Series loaded: ${powerSeries.length} points.');
    _runDistributionOnSeries(powerSeries);
  } else {
    print('  No power column found in FIT file.');
  }
  print('');
}

void _runDistributionOnSeries(Series<dynamic, double> series) {
  // 20W bands
  final result = DistributionCalculator.calculate(
    series,
    20.0,
    minVal: 0,
    maxGap: 5.0,
  );

  print('  Distribution calculated (20W bands).');

  final timeSeries = result.toTimeSeries(name: 'Time in Zone');

  print('  Top 5 occurring bands:');

  // Sort by duration descending to finding most popular zones
  final entries = result.timeInBand.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

  for (final entry in entries.take(5)) {
    final work = result.workInBand[entry.key] ?? 0;
    print('    Band ${entry.key} W: ${(entry.value / 60).toStringAsFixed(1)} min, ${(work / 1000).toStringAsFixed(1)} kJ');
  }

  print('');
  print('  Converted to Series (for charting):');
  if (timeSeries.length > 0) {
    print('    X-Axis (Bands):   ${timeSeries.getX(0)} ... ${timeSeries.getX(timeSeries.length - 1)}');
    print('    Y-Axis (Seconds): ${timeSeries.getY(0).round()} ... ${timeSeries.getY(timeSeries.length - 1).round()}');
  }
}
