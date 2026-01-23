import 'package:braven_data/braven_data.dart';
import 'package:test/test.dart';

void main() {
  group('DistributionCalculator', () {
    test('calculates correct time and work for simple integer step list', () {
      // 0, 10, 25, 30, 0
      // 1-second interval assumed
      final xValues = <int>[0, 1, 2, 3, 4];
      final yValues = <double>[0.0, 10.0, 25.0, 30.0, 0.0];

      final series = Series<int, double>.fromTypedData(
        meta: const SeriesMeta(name: 'Power', unit: 'W'),
        xValues: xValues,
        yValues: yValues,
      );

      // Band width 20. 0-20, 20-40.
      final result = DistributionCalculator.calculate(
        series,
        20.0,
        minVal: 0,
        maxGap: 5.0,
      );

      // Durations:
      // T=0 (0W) -> T=1 (10W): 1s duration, value 0 (Band 0-20)
      // T=1 (10W) -> T=2 (25W): 1s duration, value 10 (Band 0-20)
      // T=2 (25W) -> T=3 (30W): 1s duration, value 25 (Band 20-40)
      // T=3 (30W) -> T=4 (0W): 1s duration, value 30 (Band 20-40)
      // Total: Band 0-20: 2s. Band 20-40: 2s.

      expect(result.timeInBand['0-20'], equals(2.0));
      expect(result.timeInBand['20-40'], equals(2.0));

      // Work:
      // Band 0-20: (0W * 1s) + (10W * 1s) = 10 J
      // Band 20-40: (25W * 1s) + (30W * 1s) = 55 J
      expect(result.workInBand['0-20'], equals(10.0));
      expect(result.workInBand['20-40'], equals(55.0));
    });

    test('merges results correctly', () {
      final res1 = DistributionResult({'0-20': 10.0}, {'0-20': 100.0});
      final res2 = DistributionResult({'0-20': 5.0, '20-40': 5.0}, {'0-20': 50.0, '20-40': 150.0});

      final merged = DistributionCalculator.merge([res1, res2]);

      expect(merged.timeInBand['0-20'], equals(15.0));
      expect(merged.timeInBand['20-40'], equals(5.0));
      expect(merged.workInBand['0-20'], equals(150.0));
      expect(merged.workInBand['20-40'], equals(150.0));
    });
  });
}
