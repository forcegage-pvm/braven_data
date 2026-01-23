import '../series.dart';

/// Holds the results of a distribution analysis (Time and Work per band).
class DistributionResult {
  /// Map of Band Label -> Total Duration (seconds)
  final Map<String, double> timeInBand;

  /// Map of Band Label -> Total Work (Joules)
  final Map<String, double> workInBand;

  DistributionResult(this.timeInBand, this.workInBand);

  /// Converts the time distribution to a Series.
  Series<String, double> toTimeSeries({
    String name = 'Time in Zone',
    String unit = 's',
  }) {
    final sortedKeys = _sortKeys(timeInBand.keys);
    return Series<String, double>.fromTypedData(
      meta: SeriesMeta(name: name, unit: unit),
      xValues: sortedKeys,
      yValues: sortedKeys.map((k) => timeInBand[k]!).toList(),
    );
  }

  /// Converts the work distribution to a Series.
  Series<String, double> toWorkSeries({
    String name = 'Work in Zone',
    String unit = 'J',
  }) {
    final sortedKeys = _sortKeys(workInBand.keys);
    return Series<String, double>.fromTypedData(
      meta: SeriesMeta(name: name, unit: unit),
      xValues: sortedKeys,
      yValues: sortedKeys.map((k) => workInBand[k]!).toList(),
    );
  }

  /// Sorts keys numerically based on the start value of the band "100-120".
  List<String> _sortKeys(Iterable<String> keys) {
    final list = keys.toList();
    list.sort((a, b) {
      final startA = int.tryParse(a.split('-').first) ?? 0;
      final startB = int.tryParse(b.split('-').first) ?? 0;
      return startA.compareTo(startB);
    });
    return list;
  }
}

/// Analyzes series data into frequency/work distributions.
class DistributionCalculator {
  /// Calculates time-in-zone and work-in-zone.
  ///
  /// [bandWidth] defines the size of each bucket (e.g. 20 Watts).
  /// [minVal] defines the start of the lowest bucket (default 0).
  /// [maxGap] defines the maximum gap in seconds between points to accumulate time (default 5.0).
  ///
  /// Supports Series with X as [DateTime] or [num] (seconds).
  static DistributionResult calculate(
    Series<dynamic, num> series,
    double bandWidth, {
    num minVal = 0,
    double maxGap = 5.0,
  }) {
    final timeMap = <String, double>{};
    final workMap = <String, double>{};

    if (series.length < 2) {
      return DistributionResult(timeMap, workMap);
    }

    // Pre-calculate duration between points
    for (var i = 0; i < series.length - 1; i++) {
      final x1 = series.getX(i);
      final x2 = series.getX(i + 1);
      final y = series.getY(i).toDouble();

      double duration = 0.0;
      if (x1 is DateTime && x2 is DateTime) {
        duration = x2.difference(x1).inMicroseconds / 1000000.0;
      } else if (x1 is num && x2 is num) {
        duration = (x2 - x1).toDouble();
      }

      // Skip gaps or negative time (unsorted data?)
      if (duration <= 0 || duration > maxGap) {
        continue;
      }

      // Determine Band
      if (y.isNaN || y.isInfinite || y < minVal) continue;

      final bandIndex = ((y - minVal) / bandWidth).floor();
      final bandStart = (minVal + bandIndex * bandWidth).toInt();
      final bandEnd = (minVal + (bandIndex + 1) * bandWidth).toInt();
      final key = '$bandStart-$bandEnd';

      timeMap[key] = (timeMap[key] ?? 0) + duration;
      workMap[key] = (workMap[key] ?? 0) + (y * duration);
    }

    return DistributionResult(timeMap, workMap);
  }

  /// Merges multiple results into one (summing values).
  static DistributionResult merge(List<DistributionResult> results) {
    final totalTime = <String, double>{};
    final totalWork = <String, double>{};

    for (final res in results) {
      for (final entry in res.timeInBand.entries) {
        totalTime[entry.key] = (totalTime[entry.key] ?? 0) + entry.value;
      }
      for (final entry in res.workInBand.entries) {
        totalWork[entry.key] = (totalWork[entry.key] ?? 0) + entry.value;
      }
    }

    return DistributionResult(totalTime, totalWork);
  }
}
