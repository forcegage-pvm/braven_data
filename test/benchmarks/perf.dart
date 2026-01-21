import 'dart:math';
import 'dart:typed_data';

const int _defaultLength = 200000;
const int _defaultRandomAccessCount = 200000;
const int _defaultWarmupRuns = 2;
const int _defaultIterations = 5;

double _doubleSink = 0.0;
int _intSink = 0;

class BenchmarkResult {
  const BenchmarkResult(this.name, this.averageMicroseconds);

  final String name;
  final double averageMicroseconds;

  double get averageMilliseconds => averageMicroseconds / 1000.0;
}

List<double> generateDoubleList(int length) {
  return List<double>.generate(length, (index) => index * 0.5);
}

Float64List generateFloat64List(int length) {
  final values = Float64List(length);
  for (var i = 0; i < length; i++) {
    values[i] = i * 0.5;
  }
  return values;
}

List<int> generateIntList(int length) {
  return List<int>.generate(length, (index) => index);
}

Int64List generateInt64List(int length) {
  final values = Int64List(length);
  for (var i = 0; i < length; i++) {
    values[i] = i;
  }
  return values;
}

List<int> generateRandomIndices(int length, int count, {int seed = 42}) {
  final random = Random(seed);
  return List<int>.generate(count, (_) => random.nextInt(length));
}

double sumSequentialDoubles(List<double> values) {
  var sum = 0.0;
  for (var i = 0; i < values.length; i++) {
    sum += values[i];
  }
  _doubleSink = sum;
  return sum;
}

double sumRandomDoubles(List<double> values, List<int> indices) {
  var sum = 0.0;
  for (var i = 0; i < indices.length; i++) {
    sum += values[indices[i]];
  }
  _doubleSink = sum;
  return sum;
}

int sumSequentialInts(List<int> values) {
  var sum = 0;
  for (var i = 0; i < values.length; i++) {
    sum += values[i];
  }
  _intSink = sum;
  return sum;
}

int sumRandomInts(List<int> values, List<int> indices) {
  var sum = 0;
  for (var i = 0; i < indices.length; i++) {
    sum += values[indices[i]];
  }
  _intSink = sum;
  return sum;
}

BenchmarkResult runBenchmark(
  String name,
  void Function() action, {
  int warmupRuns = _defaultWarmupRuns,
  int iterations = _defaultIterations,
}) {
  for (var i = 0; i < warmupRuns; i++) {
    action();
  }

  var totalMicros = 0;
  for (var i = 0; i < iterations; i++) {
    final stopwatch = Stopwatch()..start();
    action();
    stopwatch.stop();
    totalMicros += stopwatch.elapsedMicroseconds;
  }

  final averageMicros = totalMicros / iterations;
  return BenchmarkResult(name, averageMicros.toDouble());
}

List<BenchmarkResult> runAllBenchmarks({
  int length = _defaultLength,
  int randomAccessCount = _defaultRandomAccessCount,
  int warmupRuns = _defaultWarmupRuns,
  int iterations = _defaultIterations,
}) {
  if (length <= 0) {
    throw ArgumentError.value(length, 'length', 'Must be positive.');
  }
  if (randomAccessCount <= 0) {
    throw ArgumentError.value(
      randomAccessCount,
      'randomAccessCount',
      'Must be positive.',
    );
  }

  final doubleList = generateDoubleList(length);
  final float64List = generateFloat64List(length);
  final intList = generateIntList(length);
  final int64List = generateInt64List(length);
  final indices = generateRandomIndices(length, randomAccessCount);

  return <BenchmarkResult>[
    runBenchmark(
      'List<double> sequential',
      () => sumSequentialDoubles(doubleList),
      warmupRuns: warmupRuns,
      iterations: iterations,
    ),
    runBenchmark(
      'Float64List sequential',
      () => sumSequentialDoubles(float64List),
      warmupRuns: warmupRuns,
      iterations: iterations,
    ),
    runBenchmark(
      'List<double> random',
      () => sumRandomDoubles(doubleList, indices),
      warmupRuns: warmupRuns,
      iterations: iterations,
    ),
    runBenchmark(
      'Float64List random',
      () => sumRandomDoubles(float64List, indices),
      warmupRuns: warmupRuns,
      iterations: iterations,
    ),
    runBenchmark(
      'List<int> sequential',
      () => sumSequentialInts(intList),
      warmupRuns: warmupRuns,
      iterations: iterations,
    ),
    runBenchmark(
      'Int64List sequential',
      () => sumSequentialInts(int64List),
      warmupRuns: warmupRuns,
      iterations: iterations,
    ),
    runBenchmark(
      'List<int> random',
      () => sumRandomInts(intList, indices),
      warmupRuns: warmupRuns,
      iterations: iterations,
    ),
    runBenchmark(
      'Int64List random',
      () => sumRandomInts(int64List, indices),
      warmupRuns: warmupRuns,
      iterations: iterations,
    ),
  ];
}

void main() {
  final results = runAllBenchmarks();
  for (final result in results) {
    final ms = result.averageMilliseconds.toStringAsFixed(2);
    print('${result.name}: ${ms}ms');
  }
  if (_doubleSink == double.negativeInfinity && _intSink == -1) {
    print('ignore');
  }
}
