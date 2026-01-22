import 'package:braven_data/src/aggregation.dart';
import 'package:braven_data/src/engine.dart';
import 'package:braven_data/src/output/window_alignment.dart';
import 'package:braven_data/src/series.dart';
import 'package:test/test.dart';

AggregationResult<double, double> aggregateRollingDuration(
  Series<double, double> series,
  RollingDurationWindowSpec window, {
  WindowAlignment alignment = WindowAlignment.end,
}) {
  return AggregationEngine.aggregate(
    series,
    AggregationSpec<double>(
      window: window,
      reducer: SeriesReducer.mean,
      alignment: alignment,
    ),
  );
}

Series<double, double> _buildPowerSeries(int length) {
  final xValues = List<double>.generate(length, (index) => index.toDouble());
  final yValues = List<double>.generate(length, (index) => index + 1.0);
  return Series<double, double>.fromTypedData(
    meta: const SeriesMeta(name: 'Power'),
    xValues: xValues,
    yValues: yValues,
  );
}

void main() {
  group('Rolling duration window aggregation', () {
    test('30-second rolling mean produces smoothed series', () {
      final series = _buildPowerSeries(60);

      final result = aggregateRollingDuration(
        series,
        RollingDurationWindowSpec(const Duration(seconds: 30)),
      );

      expect(result.yValues.length, series.length);
      expect(result.yValues[0], closeTo(1.0, 1e-9));
      expect(result.yValues[1], closeTo(1.5, 1e-9));
      expect(result.yValues[29], closeTo(15.5, 1e-9));
      expect(result.yValues[30], closeTo(16.5, 1e-9));
      expect(result.yValues[59], closeTo(45.5, 1e-9));
    });

    test('alignment options change output X values', () {
      final series = _buildPowerSeries(60);
      final window = RollingDurationWindowSpec(const Duration(seconds: 30));

      final startAligned = aggregateRollingDuration(
        series,
        window,
        alignment: WindowAlignment.start,
      );
      final centerAligned = aggregateRollingDuration(
        series,
        window,
        alignment: WindowAlignment.center,
      );
      final endAligned = aggregateRollingDuration(
        series,
        window,
        alignment: WindowAlignment.end,
      );

      expect(startAligned.xValues[29], isNot(centerAligned.xValues[29]));
      expect(centerAligned.xValues[29], isNot(endAligned.xValues[29]));
      expect(startAligned.xValues[29], isNot(endAligned.xValues[29]));
    });

    test('early points use partial windows', () {
      final series = _buildPowerSeries(10);

      final result = aggregateRollingDuration(
        series,
        RollingDurationWindowSpec(const Duration(seconds: 30)),
      );

      expect(result.yValues[0], closeTo(1.0, 1e-9));
      expect(result.yValues[1], closeTo(1.5, 1e-9));
      expect(result.yValues[2], closeTo(2.0, 1e-9));
    });
  });
}
