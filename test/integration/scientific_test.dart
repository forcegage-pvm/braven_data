import 'package:braven_data/src/aggregation.dart';
import 'package:braven_data/src/algorithms.dart';
import 'package:braven_data/src/pipeline.dart';
import 'package:braven_data/src/series.dart';
import 'package:test/test.dart';

void main() {
  group('Scientific integration', () {
    test('Normalized Power matches independent formula', () {
      final values = _realisticPowerValues();
      final series = _makeSeries(values);
      const windowSize = 30;

      final calculator = NormalizedPowerCalculator<int>(windowSize: windowSize);
      final result = calculator.calculate(series);

      final pipeline = PipelineBuilder<int, double>()
          .rolling(WindowSpec.rolling(windowSize), SeriesReducer.mean)
          .map(pow4)
          .collapse(SeriesReducer.mean);
      final transformed = series.transform(pipeline);
      expect(transformed.length, 1);

      final meanPower4FromPipeline = transformed.getY(0);
      final meanPower4Expected = _mean(
        _rollingMean(values, windowSize).map(pow4).toList(),
      );
      expect(meanPower4FromPipeline, closeTo(meanPower4Expected, 1e-9));

      final expected = root4(meanPower4Expected);
      expect(result, closeTo(expected, 1e-9));
    });

    test('Variability Index equals NP divided by average power', () {
      final values = _realisticPowerValues();
      final series = _makeSeries(values);
      const windowSize = 30;

      final calculator =
          VariabilityIndexCalculator<int>(windowSize: windowSize);
      final result = calculator.calculate(series);

      final expectedNp = root4(
        _mean(_rollingMean(values, windowSize).map(pow4).toList()),
      );
      final averagePower =
          _mean(values.map((value) => value.toDouble()).toList());
      final expected = expectedNp / averagePower;

      expect(result, closeTo(expected, 1e-9));
    });
  });
}

Series<int, double> _makeSeries(List<num> values) {
  return Series<int, double>.fromTypedData(
    meta: const SeriesMeta(name: 'power', unit: 'watts'),
    xValues: List<int>.generate(values.length, (index) => index),
    yValues: values.map((value) => value.toDouble()).toList(),
    stats: null,
  );
}

List<double> _rollingMean(List<num> values, int windowSize) {
  final means = <double>[];
  for (var start = 0; start + windowSize <= values.length; start++) {
    var sum = 0.0;
    for (var i = start; i < start + windowSize; i++) {
      sum += values[i].toDouble();
    }
    means.add(sum / windowSize);
  }
  return means;
}

List<double> _realisticPowerValues() {
  return <double>[
    180,
    190,
    205,
    220,
    235,
    250,
    265,
    280,
    295,
    310,
    300,
    290,
    275,
    260,
    245,
    230,
    215,
    200,
    210,
    225,
    240,
    255,
    270,
    285,
    300,
    315,
    330,
    345,
    360,
    340,
    320,
    300,
    280,
    260,
    240,
    220,
    200,
    190,
    210,
    230,
  ];
}

double _mean(List<double> values) {
  var sum = 0.0;
  for (final value in values) {
    sum += value;
  }
  return sum / values.length;
}
