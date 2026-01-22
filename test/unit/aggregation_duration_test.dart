import 'package:braven_data/src/aggregation.dart';
import 'package:braven_data/src/series.dart';
import 'package:test/test.dart';

Series<double, double> _seriesFromSeconds(List<double> seconds) {
  final values = List<double>.generate(seconds.length, (index) => index + 1.0);
  return Series<double, double>.fromTypedData(
    meta: const SeriesMeta(name: 'Signal'),
    xValues: seconds,
    yValues: values,
  );
}

void main() {
  group('Duration window conversion', () {
    test('30-second window at 1Hz uses 30 points', () {
      final seconds = List<double>.generate(120, (index) => index.toDouble());
      final series = _seriesFromSeconds(seconds);
      final spec = FixedDurationWindowSpec(const Duration(seconds: 30));

      final pointCount = spec.pointCountForSeries(series);

      expect(pointCount, 30);
    });

    test('5-minute window at 10Hz uses 3000 points', () {
      final seconds = List<double>.generate(
        5000,
        (index) => index * 0.1,
      );
      final series = _seriesFromSeconds(seconds);
      final spec = FixedDurationWindowSpec(const Duration(minutes: 5));

      final pointCount = spec.pointCountForSeries(series);

      expect(pointCount, 3000);
    });

    test('infers sample rate from X value deltas', () {
      final seconds = List<double>.generate(50, (index) => index * 0.1);
      final series = _seriesFromSeconds(seconds);
      final spec = FixedDurationWindowSpec(const Duration(seconds: 1));

      final sampleRate = spec.inferredSampleRateHz(series);

      expect(sampleRate, closeTo(10.0, 1e-9));
    });
  });
}
