// @orchestra-task: 6
@Tags(['tdd-red'])
library;

import 'package:braven_data/src/output/window_alignment.dart';
import 'package:braven_data/src/series.dart';
import 'package:test/test.dart';

class DurationWindowSpec {
  DurationWindowSpec(this.duration);

  final Duration duration;
}

Series<int, double> aggregateRollingDuration(
  Series<int, double> series,
  DurationWindowSpec window, {
  WindowAlignment alignment = WindowAlignment.end,
}) {
  throw UnimplementedError('Rolling duration-based aggregation missing.');
}

Series<int, double> _buildPowerSeries(int length) {
  final xValues = List<int>.generate(length, (index) => index);
  final yValues = List<double>.generate(length, (index) => index + 1.0);
  return Series<int, double>.fromTypedData(
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
        DurationWindowSpec(const Duration(seconds: 30)),
      );

      expect(result.length, series.length);
      expect(result.getY(0), closeTo(1.0, 1e-9));
      expect(result.getY(1), closeTo(1.5, 1e-9));
      expect(result.getY(29), closeTo(15.5, 1e-9));
      expect(result.getY(30), closeTo(16.5, 1e-9));
      expect(result.getY(59), closeTo(45.5, 1e-9));
    });

    test('alignment options change output X values', () {
      final series = _buildPowerSeries(60);
      final window = DurationWindowSpec(const Duration(seconds: 30));

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

      expect(startAligned.getX(29), isNot(centerAligned.getX(29)));
      expect(centerAligned.getX(29), isNot(endAligned.getX(29)));
      expect(startAligned.getX(29), isNot(endAligned.getX(29)));
    });

    test('early points use partial windows', () {
      final series = _buildPowerSeries(10);

      final result = aggregateRollingDuration(
        series,
        DurationWindowSpec(const Duration(seconds: 30)),
      );

      expect(result.getY(0), closeTo(1.0, 1e-9));
      expect(result.getY(1), closeTo(1.5, 1e-9));
      expect(result.getY(2), closeTo(2.0, 1e-9));
    });
  });
}
