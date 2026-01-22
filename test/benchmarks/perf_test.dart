import 'dart:typed_data';

import 'package:test/test.dart';

import 'perf.dart' as perf;

void main() {
  group('perf data generation', () {
    test('creates double and float64 lists', () {
      final doubles = perf.generateDoubleList(5);
      final float64 = perf.generateFloat64List(5);

      expect(doubles, hasLength(5));
      expect(float64, hasLength(5));
      expect(float64, isA<Float64List>());
    });

    test('creates int and int64 lists', () {
      final ints = perf.generateIntList(5);
      final int64 = perf.generateInt64List(5);

      expect(ints, hasLength(5));
      expect(int64, hasLength(5));
      expect(int64, isA<Int64List>());
    });

    test('random indices are within bounds', () {
      final indices = perf.generateRandomIndices(10, 20, seed: 7);
      expect(indices, hasLength(20));
      for (final index in indices) {
        expect(index, inInclusiveRange(0, 9));
      }
    });
  });

  group('benchmark execution', () {
    test('runBenchmark returns a result', () {
      final result = perf.runBenchmark(
        'noop',
        () {},
        warmupRuns: 0,
        iterations: 1,
      );

      expect(result.name, 'noop');
      expect(result.averageMicroseconds, greaterThanOrEqualTo(0));
    });

    test('runAllBenchmarks returns labeled results', () {
      final results = perf.runAllBenchmarks(
        length: 128,
        randomAccessCount: 128,
        warmupRuns: 0,
        iterations: 1,
      );

      expect(results, isNotEmpty);
      expect(
        results.map((result) => result.name),
        contains('Float64List sequential'),
      );
      expect(
        results.map((result) => result.name),
        contains('Int64List random'),
      );
    });

    test('runAllBenchmarks validates inputs', () {
      expect(
        () => perf.runAllBenchmarks(length: 0),
        throwsArgumentError,
      );
      expect(
        () => perf.runAllBenchmarks(randomAccessCount: 0),
        throwsArgumentError,
      );
    });

    test('runTenMillionPointIngestionBenchmarks returns labeled results', () {
      final results = perf.runTenMillionPointIngestionBenchmarks(
        length: 512,
        randomAccessCount: 128,
        warmupRuns: 0,
        iterations: 1,
      );

      expect(results, hasLength(3));
      expect(
        results.map((result) => result.name),
        contains('Series ingestion (512 points)'),
      );
      expect(
        results.map((result) => result.name),
        contains('Series access sequential (512 points)'),
      );
      expect(
        results.map((result) => result.name),
        contains('Series access random (128 samples)'),
      );
    });

    test('runTenMillionPointIngestionBenchmarks validates inputs', () {
      expect(
        () => perf.runTenMillionPointIngestionBenchmarks(length: 0),
        throwsArgumentError,
      );
      expect(
        () => perf.runTenMillionPointIngestionBenchmarks(randomAccessCount: 0),
        throwsArgumentError,
      );
      expect(
        () => perf.runTenMillionPointIngestionBenchmarks(iterations: 0),
        throwsArgumentError,
      );
    });
  });
}
