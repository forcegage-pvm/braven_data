// ignore_for_file: unnecessary_library_name
library;

import 'package:braven_data/src/output/chart_data_point.dart';
import 'package:test/test.dart';

void main() {
  group('ChartDataPoint', () {
    test('stores required x/y fields', () {
      const point = ChartDataPoint(x: 1.5, y: 2.5);

      expect(point.x, 1.5);
      expect(point.y, 2.5);
    });

    test('stores optional timestamp, label, and metadata', () {
      final timestamp = DateTime.utc(2025, 10, 26, 13, 23, 17);
      final metadata = <String, dynamic>{'min': 120.0, 'max': 150.0};
      final point = ChartDataPoint(
        x: 0.0,
        y: 125.0,
        timestamp: timestamp,
        label: 'avg',
        metadata: metadata,
      );

      expect(point.timestamp, timestamp);
      expect(point.label, 'avg');
      expect(point.metadata, metadata);
    });

    test('equality ignores metadata differences', () {
      final timestamp = DateTime.utc(2025, 10, 26, 13, 23, 17);
      final pointA = ChartDataPoint(
        x: 1.0,
        y: 2.0,
        timestamp: timestamp,
        label: 'a',
        metadata: const {'min': 1.0},
      );
      final pointB = ChartDataPoint(
        x: 1.0,
        y: 2.0,
        timestamp: timestamp,
        label: 'a',
        metadata: const {'min': 0.5},
      );

      expect(pointA, equals(pointB));
      expect(pointA == pointB, isTrue);
    });

    test('hashCode matches value-based equality', () {
      final timestamp = DateTime.utc(2025, 10, 26, 13, 23, 17);
      final pointA = ChartDataPoint(
        x: 1.0,
        y: 2.0,
        timestamp: timestamp,
        label: 'a',
        metadata: const {'min': 1.0},
      );
      final pointB = ChartDataPoint(
        x: 1.0,
        y: 2.0,
        timestamp: timestamp,
        label: 'a',
        metadata: const {'min': 0.5},
      );

      expect(pointA.hashCode, pointB.hashCode);
    });

    test('isValid is true only for finite values', () {
      const validPoint = ChartDataPoint(x: 1.0, y: 2.0);
      const nanPoint = ChartDataPoint(x: double.nan, y: 2.0);
      const infinityPoint = ChartDataPoint(x: 1.0, y: double.infinity);

      expect(validPoint.isValid, isTrue);
      expect(nanPoint.isValid, isFalse);
      expect(infinityPoint.isValid, isFalse);
    });

    test('copyWith creates an updated copy', () {
      final point = ChartDataPoint(
        x: 1.0,
        y: 2.0,
        timestamp: DateTime.utc(2025, 1, 1),
        label: 'original',
        metadata: const {'min': 1.0},
      );

      final updated = point.copyWith(y: 3.0, label: 'updated');

      expect(updated.x, 1.0);
      expect(updated.y, 3.0);
      expect(updated.label, 'updated');
      expect(updated.timestamp, point.timestamp);
      expect(updated.metadata, point.metadata);
    });
  });
}
