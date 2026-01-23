// Example: Distribution Analysis across multiple datasets (Power Zones)
//
// Demonstrates:
// 1. Loading multiple Series from real FIT files.
// 2. Calculating Time-in-Zone and Work-in-Zone.
// 3. Merging results across files.
// 4. Outputting distribution Series.

import 'dart:io';

import 'package:braven_data/braven_data.dart';

Future<void> main() async {
  print('--- Distribution Analysis Example (Real Data) ---');

  // Paths to FIT files
  final files = [
    'specs/_base/003-fit-file/joubertjp.2020-12-05-16-16-30-219Z.GarminPush.74900175025.fit',
    'specs/_base/003-fit-file/tp-2023646.2025-10-26-13-23-16-784Z.GarminPing.AAAAAGj-IMQ_uYSx.FIT',
  ];

  final results = <DistributionResult>[];
  const bandWidth = 20.0;
  const minVal = 0.0;

  for (final path in files) {
    if (!File(path).existsSync()) {
      print('Skipping (not found): $path');
      continue;
    }

    try {
      print('\nLoading: $path');
      final df = await FitLoader.load(path, FitMessageType.records);

      // Try to find power column (case-insensitive usually, but library is string-key based)
      // Standard FIT field is 'power'.
      if (!df.columnNames.contains('power')) {
        print('Warning: No "power" column found in $path. Columns: ${df.columnNames}');
        continue;
      }

      final series = df.toSeries('power');
      print('  Points: ${series.length}');

      final result = DistributionCalculator.calculate(
        series,
        bandWidth,
        minVal: minVal,
        maxGap: 10.0, // Allow up to 10s gaps
      );

      results.add(result);
      _printDistribution('File Summary', result);
    } catch (e) {
      print('Error processing $path: $e');
    }
  }

  if (results.isEmpty) {
    print('No results to merge.');
    return;
  }

  // Merge results
  final totalResult = DistributionCalculator.merge(results);
  _printDistribution('Total (Merged) Summary', totalResult);

  // Convert to Series for visualization output
  final timeSeries = totalResult.toTimeSeries();
  print('\nConverted to Series: ${timeSeries.meta.name}');
  if (timeSeries.length > 0) {
    print('X-Axis (Bands): ${timeSeries.getX(0)} ... ${timeSeries.getX(timeSeries.length - 1)}');
    print('Y-Axis (Seconds): ${timeSeries.getY(0).round()} ... ${timeSeries.getY(timeSeries.length - 1).round()}');
  }
}

void _printDistribution(String label, DistributionResult result) {
  print('\n--- $label ---');
  print('Band (W) \t Time (min) \t Work (kJ)');

  final series = result.toTimeSeries();
  final workSeries = result.toWorkSeries();

  for (var i = 0; i < series.length; i++) {
    final band = series.getX(i);
    final seconds = series.getY(i);
    final workJ = workSeries.getY(i);

    // Only print if significant duration or work
    if (seconds > 0) {
      print('$band \t ${(seconds / 60).toStringAsFixed(1)} \t\t ${(workJ / 1000).toStringAsFixed(1)}');
    }
  }
}
