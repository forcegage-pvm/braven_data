import 'package:braven_data/braven_data.dart';
import 'package:test/test.dart';

void main() {
  group('Public API exports', () {
    test('can access exported types', () {
      final listStorage = ListStorage<double, double>(
        xValues: <double>[1, 2],
        yValues: <double>[10, 20],
      );
      expect(listStorage.length, 2);
      expect(listStorage.getX(0), 1);
      expect(listStorage.getY(1), 20);

      final typedStorage = TypedDataStorage<double, double>(
        xValues: <double>[1, 2],
        yValues: <double>[10, 20],
      );
      expect(typedStorage.copy().length, 2);

      final intervalStorage = IntervalStorage<double>(
        xValues: <double>[1, 2],
        minValues: <double>[0, 5],
        maxValues: <double>[20, 25],
        meanValues: <double>[10, 15],
      );
      expect(intervalStorage.getMin(0), 0);
      expect(intervalStorage.getMax(1), 25);
      expect(intervalStorage.getMean(0), 10);

      const meta = SeriesMeta(name: 'power', unit: 'w');
      const stats = SeriesStats(min: 10, max: 20, mean: 15, count: 2);
      final series = Series<double, double>.fromTypedData(
        meta: meta,
        xValues: <double>[1, 2, 3, 4],
        yValues: <double>[200, 220, 210, 205],
        stats: stats,
      );
      expect(series.length, 4);

      double identity(double value) => value;
      final Mapper<double> mapper = identity;
      final pipeline = PipelineBuilder<double, double>().map(mapper).collapse(SeriesReducer.mean);
      final average = pipeline.executeScalar(series);
      expect(average, closeTo(208.75, 0.001));

      final aggregated = AggregationEngine.aggregate(
        series,
        AggregationSpec<double>(
          window: WindowSpec.fixed(2),
          reducer: SeriesReducer.mean,
        ),
      );
      expect(aggregated, isA<AggregationResult<double, double>>());
      expect(aggregated.xValues.length, 2);
      expect(aggregated.yValues.length, 2);

      final normalizedPower = NormalizedPowerCalculator<double>(windowSize: 2).calculate(series);
      expect(normalizedPower, greaterThan(0));

      final xPower = xPowerCalculator<double>(windowSize: 2, alpha: 0.5).calculate(series);
      expect(xPower, greaterThan(0));

      final variabilityIndex = VariabilityIndexCalculator<double>(windowSize: 2).calculate(series);
      expect(variabilityIndex, greaterThan(0));
    });
  });
}
