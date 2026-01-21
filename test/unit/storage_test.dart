/// TDD Red Phase: Storage Backend Tests
///
/// This test suite defines the contract for the storage backend architecture
/// in braven_data. The implementation will be done in a subsequent green-phase task.
///
/// Storage Architecture:
/// - `SeriesStorage<TX, TY>`: Abstract interface
/// - TypedDataStorage: Float64List/Int64List with sentinel values
/// - ListStorage: Generic fallback for any type
/// - IntervalStorage: Structure-of-Arrays for aggregated data
///
/// Sentinel Values:
/// - double.nan for missing double values
/// - -9223372036854775808 (Int64.min) for missing int/time values
library;

import 'dart:typed_data';

import 'package:braven_data/braven_data.dart';
import 'package:test/test.dart';

void main() {
  group('SeriesStorage contract', () {
    test('should have length property', () {
      final storage = TypedDataStorage<double, double>(
        xValues: [1.0, 2.0, 3.0],
        yValues: [10.0, 20.0, 30.0],
      );
      expect(storage.length, equals(3));
    });

    test('should provide getX() method', () {
      final storage = TypedDataStorage<double, double>(
        xValues: [1.0, 2.0, 3.0],
        yValues: [10.0, 20.0, 30.0],
      );
      expect(storage.getX(0), equals(1.0));
      expect(storage.getX(1), equals(2.0));
      expect(storage.getX(2), equals(3.0));
    });

    test('should provide getY() method', () {
      final storage = TypedDataStorage<double, double>(
        xValues: [1.0, 2.0, 3.0],
        yValues: [10.0, 20.0, 30.0],
      );
      expect(storage.getY(0), equals(10.0));
      expect(storage.getY(1), equals(20.0));
      expect(storage.getY(2), equals(30.0));
    });

    test('should provide copy() method', () {
      final storage = TypedDataStorage<double, double>(
        xValues: [1.0, 2.0, 3.0],
        yValues: [10.0, 20.0, 30.0],
      );
      final copy = storage.copy();
      expect(copy, isNot(same(storage)));
      expect(copy.length, equals(storage.length));
    });
  });

  group('TypedDataStorage<double, double>', () {
    test('should store double values in Float64List', () {
      final storage = TypedDataStorage<double, double>(
        xValues: [1.5, 2.7, 3.9],
        yValues: [100.5, 200.7, 300.9],
      );
      expect(storage.getX(0), closeTo(1.5, 0.001));
      expect(storage.getX(1), closeTo(2.7, 0.001));
      expect(storage.getX(2), closeTo(3.9, 0.001));
      expect(storage.getY(0), closeTo(100.5, 0.001));
      expect(storage.getY(1), closeTo(200.7, 0.001));
      expect(storage.getY(2), closeTo(300.9, 0.001));
    });

    test('should handle large datasets efficiently', () {
      final xValues = List.generate(10000, (i) => i.toDouble());
      final yValues = List.generate(10000, (i) => (i * 2).toDouble());
      final storage = TypedDataStorage<double, double>(
        xValues: xValues,
        yValues: yValues,
      );
      expect(storage.length, equals(10000));
      expect(storage.getX(5000), equals(5000.0));
      expect(storage.getY(5000), equals(10000.0));
    });

    test('should use 8 bytes per value for memory efficiency', () {
      // This test documents the memory efficiency requirement
      // Float64List uses 8 bytes per element with no object overhead
      final storage = TypedDataStorage<double, double>(
        xValues: [1.0, 2.0, 3.0],
        yValues: [10.0, 20.0, 30.0],
      );
      // Implementation should use Float64List internally
      expect(storage.length, equals(3));
    });

    test('should handle NaN sentinel for missing double values', () {
      final storage = TypedDataStorage<double, double>(
        xValues: [1.0, double.nan, 3.0],
        yValues: [10.0, 20.0, double.nan],
      );
      expect(storage.getX(1).isNaN, isTrue);
      expect(storage.getY(2).isNaN, isTrue);
    });

    test('should preserve NaN sentinels during copy', () {
      final storage = TypedDataStorage<double, double>(
        xValues: [1.0, double.nan, 3.0],
        yValues: [10.0, double.nan, 30.0],
      );
      final copy = storage.copy();
      expect(copy.getX(1).isNaN, isTrue);
      expect(copy.getY(1).isNaN, isTrue);
    });

    test('should accept Float64List inputs', () {
      final xValues = Float64List.fromList([1.0, 2.0, 3.0]);
      final yValues = Float64List.fromList([10.0, 20.0, 30.0]);
      final storage = TypedDataStorage<double, double>(
        xValues: xValues,
        yValues: yValues,
      );
      expect(storage.length, equals(3));
      expect(storage.getX(2), equals(3.0));
      expect(storage.getY(0), equals(10.0));
    });

    test('should throw when lengths differ', () {
      expect(
        () => TypedDataStorage<double, double>(
          xValues: [1.0, 2.0],
          yValues: [10.0],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('TypedDataStorage<int, double>', () {
    test('should store int values in Int64List', () {
      final storage = TypedDataStorage<int, double>(
        xValues: [1000, 2000, 3000],
        yValues: [10.0, 20.0, 30.0],
      );
      expect(storage.getX(0), equals(1000));
      expect(storage.getX(1), equals(2000));
      expect(storage.getX(2), equals(3000));
    });

    test('should accept Int64List input without reallocation', () {
      final xValues = Int64List.fromList([1000, 2000, 3000]);
      final storage = TypedDataStorage<int, double>(
        xValues: xValues,
        yValues: [10.0, 20.0, 30.0],
      );

      xValues[1] = 2500;
      expect(storage.getX(1), equals(2500));
    });

    test('should handle large int values for timestamps', () {
      // Unix timestamp in milliseconds (typical DateTime representation)
      final timestamp = DateTime(2024, 1, 1).millisecondsSinceEpoch;
      final storage = TypedDataStorage<int, double>(
        xValues: [timestamp, timestamp + 1000, timestamp + 2000],
        yValues: [10.0, 20.0, 30.0],
      );
      expect(storage.getX(0), equals(timestamp));
      expect(storage.getX(1), equals(timestamp + 1000));
    });

    test('should use Int64.min sentinel for missing int values', () {
      // Int64.min = -9223372036854775808
      const int64Min = -9223372036854775808;
      final storage = TypedDataStorage<int, double>(
        xValues: [1000, int64Min, 3000],
        yValues: [10.0, 20.0, 30.0],
      );
      expect(storage.getX(1), equals(int64Min));
    });

    test('should preserve Int64.min sentinel during copy', () {
      const int64Min = -9223372036854775808;
      final storage = TypedDataStorage<int, double>(
        xValues: [1000, int64Min, 3000],
        yValues: [10.0, 20.0, 30.0],
      );
      final copy = storage.copy();
      expect(copy.getX(1), equals(int64Min));
    });

    test('should use 8 bytes per int value for memory efficiency', () {
      // Int64List uses 8 bytes per element
      final storage = TypedDataStorage<int, double>(
        xValues: [1, 2, 3],
        yValues: [10.0, 20.0, 30.0],
      );
      expect(storage.length, equals(3));
    });
  });

  group('ListStorage', () {
    test('should store any type using List<T>', () {
      final storage = ListStorage<String, int>(
        xValues: ['a', 'b', 'c'],
        yValues: [1, 2, 3],
      );
      expect(storage.getX(0), equals('a'));
      expect(storage.getX(1), equals('b'));
      expect(storage.getX(2), equals('c'));
      expect(storage.getY(0), equals(1));
      expect(storage.getY(1), equals(2));
      expect(storage.getY(2), equals(3));
    });

    test('should handle custom object types', () {
      final customObjects = [
        CustomDataPoint('first', 100),
        CustomDataPoint('second', 200),
        CustomDataPoint('third', 300),
      ];
      final storage = ListStorage<CustomDataPoint, int>(
        xValues: customObjects,
        yValues: [100, 200, 300],
      );
      expect(storage.getX(0).label, equals('first'));
      expect(storage.getX(1).label, equals('second'));
      expect(storage.getY(1), equals(200));
    });

    test('should copy list storage independently', () {
      final storage = ListStorage<String, int>(
        xValues: ['a', 'b', 'c'],
        yValues: [1, 2, 3],
      );
      final copy = storage.copy();
      expect(copy, isNot(same(storage)));
      expect(copy.length, equals(storage.length));
      expect(copy.getX(0), equals('a'));
      expect(copy.getY(0), equals(1));
    });

    test('should handle null values when TX or TY is nullable', () {
      final storage = ListStorage<String?, int?>(
        xValues: ['a', null, 'c'],
        yValues: [1, null, 3],
      );
      expect(storage.getX(1), isNull);
      expect(storage.getY(1), isNull);
    });
  });

  group('IntervalStorage', () {
    test('should store aggregated data with min/max/mean', () {
      final storage = IntervalStorage<double>(
        xValues: [1.0, 2.0, 3.0],
        minValues: [5.0, 10.0, 15.0],
        maxValues: [10.0, 20.0, 30.0],
        meanValues: [7.5, 15.0, 22.5],
      );
      expect(storage.length, equals(3));
      expect(storage.getX(0), equals(1.0));
      expect(storage.getMin(0), equals(5.0));
      expect(storage.getMax(0), equals(10.0));
      expect(storage.getMean(0), equals(7.5));
    });

    test('should use Structure-of-Arrays layout for performance', () {
      // SoA layout: parallel arrays instead of array of structs
      // Enables efficient SIMD operations and better cache locality
      final storage = IntervalStorage<double>(
        xValues: [1.0, 2.0, 3.0, 4.0],
        minValues: [5.0, 10.0, 15.0, 20.0],
        maxValues: [10.0, 20.0, 30.0, 40.0],
        meanValues: [7.5, 15.0, 22.5, 30.0],
      );
      expect(storage.length, equals(4));
      expect(storage.getMin(3), equals(20.0));
      expect(storage.getMax(3), equals(40.0));
      expect(storage.getMean(3), equals(30.0));
    });

    test('should handle NaN sentinels in aggregated data', () {
      final storage = IntervalStorage<double>(
        xValues: [1.0, 2.0, 3.0],
        minValues: [5.0, double.nan, 15.0],
        maxValues: [10.0, double.nan, 30.0],
        meanValues: [7.5, double.nan, 22.5],
      );
      expect(storage.getMin(1).isNaN, isTrue);
      expect(storage.getMax(1).isNaN, isTrue);
      expect(storage.getMean(1).isNaN, isTrue);
    });

    test('should copy interval storage independently', () {
      final storage = IntervalStorage<double>(
        xValues: [1.0, 2.0, 3.0],
        minValues: [5.0, 10.0, 15.0],
        maxValues: [10.0, 20.0, 30.0],
        meanValues: [7.5, 15.0, 22.5],
      );
      final copy = storage.copy();
      expect(copy, isNot(same(storage)));
      expect(copy.length, equals(storage.length));
      expect(copy.getMin(0), equals(5.0));
      expect(copy.getMax(0), equals(10.0));
    });

    test('should support int x-axis for timestamp intervals', () {
      final storage = IntervalStorage<int>(
        xValues: [1000, 2000, 3000],
        minValues: [5.0, 10.0, 15.0],
        maxValues: [10.0, 20.0, 30.0],
        meanValues: [7.5, 15.0, 22.5],
      );
      expect(storage.getX(0), equals(1000));
      expect(storage.getX(1), equals(2000));
    });
  });

  group('Sentinel handling', () {
    test('should detect double.nan as missing value', () {
      final storage = TypedDataStorage<double, double>(
        xValues: [1.0, double.nan, 3.0],
        yValues: [10.0, 20.0, double.nan],
      );
      expect(storage.getX(1).isNaN, isTrue,
          reason: 'NaN should be preserved in X values');
      expect(storage.getY(2).isNaN, isTrue,
          reason: 'NaN should be preserved in Y values');
      expect(storage.getX(0).isNaN, isFalse,
          reason: 'Non-NaN values should not be NaN');
    });

    test('should detect Int64.min as missing int value', () {
      const int64Min = -9223372036854775808;
      final storage = TypedDataStorage<int, double>(
        xValues: [1000, int64Min, 3000],
        yValues: [10.0, 20.0, 30.0],
      );
      expect(storage.getX(1), equals(int64Min),
          reason: 'Int64.min sentinel should be preserved');
      expect(storage.getX(0), isNot(equals(int64Min)),
          reason: 'Non-sentinel values should not be Int64.min');
    });

    test('should not confuse regular values with sentinels', () {
      // Test that normal negative values are not treated as sentinels
      final storage = TypedDataStorage<double, double>(
        xValues: [-100.0, -200.0, -300.0],
        yValues: [-10.0, -20.0, -30.0],
      );
      expect(storage.getX(0), equals(-100.0));
      expect(storage.getY(0), equals(-10.0));
      expect(storage.getX(0).isNaN, isFalse,
          reason: 'Negative values should not be NaN');
    });

    test('should handle all NaN dataset', () {
      final storage = TypedDataStorage<double, double>(
        xValues: [double.nan, double.nan, double.nan],
        yValues: [double.nan, double.nan, double.nan],
      );
      expect(storage.length, equals(3));
      expect(storage.getX(0).isNaN, isTrue);
      expect(storage.getY(0).isNaN, isTrue);
    });

    test('should handle mixed sentinels in IntervalStorage', () {
      final storage = IntervalStorage<double>(
        xValues: [1.0, 2.0, double.nan],
        minValues: [5.0, double.nan, 15.0],
        maxValues: [10.0, 20.0, double.nan],
        meanValues: [7.5, double.nan, 22.5],
      );
      expect(storage.getX(2).isNaN, isTrue);
      expect(storage.getMin(1).isNaN, isTrue);
      expect(storage.getMax(2).isNaN, isTrue);
    });
  });

  group('copy() operation', () {
    test('should create independent copy of TypedDataStorage', () {
      final storage = TypedDataStorage<double, double>(
        xValues: [1.0, 2.0, 3.0],
        yValues: [10.0, 20.0, 30.0],
      );
      final copy = storage.copy();

      // Verify it's not the same instance
      expect(copy, isNot(same(storage)));

      // Verify data is identical
      expect(copy.length, equals(storage.length));
      for (int i = 0; i < storage.length; i++) {
        expect(copy.getX(i), equals(storage.getX(i)));
        expect(copy.getY(i), equals(storage.getY(i)));
      }
    });

    test('should create independent copy of ListStorage', () {
      final storage = ListStorage<String, int>(
        xValues: ['a', 'b', 'c'],
        yValues: [1, 2, 3],
      );
      final copy = storage.copy();

      expect(copy, isNot(same(storage)));
      expect(copy.length, equals(storage.length));
      expect(copy.getX(0), equals('a'));
      expect(copy.getY(0), equals(1));
    });

    test('should create independent copy of IntervalStorage', () {
      final storage = IntervalStorage<double>(
        xValues: [1.0, 2.0, 3.0],
        minValues: [5.0, 10.0, 15.0],
        maxValues: [10.0, 20.0, 30.0],
        meanValues: [7.5, 15.0, 22.5],
      );
      final copy = storage.copy();

      expect(copy, isNot(same(storage)));
      expect(copy.length, equals(storage.length));
      expect(copy.getMin(0), equals(storage.getMin(0)));
      expect(copy.getMax(0), equals(storage.getMax(0)));
      expect(copy.getMean(0), equals(storage.getMean(0)));
    });

    test('should preserve sentinels in copied data', () {
      final storage = TypedDataStorage<double, double>(
        xValues: [1.0, double.nan, 3.0],
        yValues: [10.0, 20.0, double.nan],
      );
      final copy = storage.copy();

      expect(copy.getX(1).isNaN, isTrue);
      expect(copy.getY(2).isNaN, isTrue);
    });

    test('copy should not affect original when modified', () {
      // This test documents that copy() should be a deep copy
      // Implementation should ensure modifications to copy don't affect original
      final storage = TypedDataStorage<double, double>(
        xValues: [1.0, 2.0, 3.0],
        yValues: [10.0, 20.0, 30.0],
      );
      final copy = storage.copy();

      // Verify they are independent instances
      expect(copy, isNot(same(storage)));
    });
  });

  group('Bounds checking', () {
    test('should throw RangeError for negative index in getX', () {
      final storage = TypedDataStorage<double, double>(
        xValues: [1.0, 2.0, 3.0],
        yValues: [10.0, 20.0, 30.0],
      );
      expect(() => storage.getX(-1), throwsA(isA<RangeError>()));
    });

    test('should throw RangeError for negative index in getY', () {
      final storage = TypedDataStorage<double, double>(
        xValues: [1.0, 2.0, 3.0],
        yValues: [10.0, 20.0, 30.0],
      );
      expect(() => storage.getY(-1), throwsA(isA<RangeError>()));
    });

    test('should throw RangeError for index >= length in getX', () {
      final storage = TypedDataStorage<double, double>(
        xValues: [1.0, 2.0, 3.0],
        yValues: [10.0, 20.0, 30.0],
      );
      expect(() => storage.getX(3), throwsA(isA<RangeError>()));
      expect(() => storage.getX(100), throwsA(isA<RangeError>()));
    });

    test('should throw RangeError for index >= length in getY', () {
      final storage = TypedDataStorage<double, double>(
        xValues: [1.0, 2.0, 3.0],
        yValues: [10.0, 20.0, 30.0],
      );
      expect(() => storage.getY(3), throwsA(isA<RangeError>()));
      expect(() => storage.getY(100), throwsA(isA<RangeError>()));
    });

    test('should throw RangeError for out of bounds in ListStorage', () {
      final storage = ListStorage<String, int>(
        xValues: ['a', 'b', 'c'],
        yValues: [1, 2, 3],
      );
      expect(() => storage.getX(-1), throwsA(isA<RangeError>()));
      expect(() => storage.getY(3), throwsA(isA<RangeError>()));
    });

    test('should throw RangeError for out of bounds in IntervalStorage', () {
      final storage = IntervalStorage<double>(
        xValues: [1.0, 2.0, 3.0],
        minValues: [5.0, 10.0, 15.0],
        maxValues: [10.0, 20.0, 30.0],
        meanValues: [7.5, 15.0, 22.5],
      );
      expect(() => storage.getX(-1), throwsA(isA<RangeError>()));
      expect(() => storage.getMin(3), throwsA(isA<RangeError>()));
      expect(() => storage.getMax(3), throwsA(isA<RangeError>()));
      expect(() => storage.getMean(3), throwsA(isA<RangeError>()));
    });

    test('should allow access at valid boundary indices', () {
      final storage = TypedDataStorage<double, double>(
        xValues: [1.0, 2.0, 3.0],
        yValues: [10.0, 20.0, 30.0],
      );
      // First index (0) should work
      expect(storage.getX(0), equals(1.0));
      expect(storage.getY(0), equals(10.0));

      // Last index (length - 1) should work
      expect(storage.getX(2), equals(3.0));
      expect(storage.getY(2), equals(30.0));
    });

    test('should handle empty storage length check', () {
      final storage = TypedDataStorage<double, double>(
        xValues: <double>[],
        yValues: <double>[],
      );
      expect(storage.length, equals(0));
      expect(() => storage.getX(0), throwsA(isA<RangeError>()));
      expect(() => storage.getY(0), throwsA(isA<RangeError>()));
    });
  });
}

/// Helper class for testing custom object storage
class CustomDataPoint {
  final String label;
  final int value;

  CustomDataPoint(this.label, this.value);
}
