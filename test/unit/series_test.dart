import 'package:test/test.dart';

import 'package:braven_data/src/series.dart';

void main() {
  group('SeriesMeta', () {
    test('stores name and optional unit', () {
      const meta = SeriesMeta(name: 'Altitude', unit: 'm');

      expect(meta.name, 'Altitude');
      expect(meta.unit, 'm');
    });

    test('allows a null unit for dimensionless data', () {
      const meta = SeriesMeta(name: 'Cadence');

      expect(meta.name, 'Cadence');
      expect(meta.unit, isNull);
    });
  });

  group('SeriesStats', () {
    test('stores summary statistics', () {
      const stats = SeriesStats(min: 1, max: 5, mean: 3, count: 4);

      expect(stats.min, 1);
      expect(stats.max, 5);
      expect(stats.mean, 3);
      expect(stats.count, 4);
    });

    test('accepts zero count values', () {
      const stats = SeriesStats(min: 0, max: 0, mean: 0, count: 0);

      expect(stats.count, 0);
    });
  });
}
