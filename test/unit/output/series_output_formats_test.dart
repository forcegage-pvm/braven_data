// @orchestra-task: 8
// ignore_for_file: unnecessary_library_name
@Tags(['tdd-red'])
library;

import 'package:braven_data/src/output/chart_data_point.dart';
import 'package:braven_data/src/series.dart';
import 'package:test/test.dart';

void main() {
  group('SeriesChartOutput alternative formats', () {
    test('toMapList returns maps with x/y keys', () {
      final series = Series<double, double>.fromTypedData(
        meta: const SeriesMeta(name: 'Power', unit: 'W'),
        xValues: const [0.0, 1.0],
        yValues: const [120.0, 130.0],
      );

      final maps = series.toMapList();

      expect(maps, hasLength(2));
      expect(maps[0]['x'], 0.0);
      expect(maps[0]['y'], 120.0);
      expect(maps[1]['x'], 1.0);
      expect(maps[1]['y'], 130.0);
    });

    test('toTuples returns list of (x, y) pairs', () {
      final series = Series<double, double>.fromTypedData(
        meta: const SeriesMeta(name: 'Power', unit: 'W'),
        xValues: const [0.0, 1.0],
        yValues: const [120.0, 130.0],
      );

      final tuples = series.toTuples();

      expect(tuples, hasLength(2));
      expect(tuples[0], (0.0, 120.0));
      expect(tuples[1], (1.0, 130.0));
    });
  });
}
