/// Abstract API Contract for Braven Data
library;

abstract class Series<TX, TY> {
  String get id;
  SeriesMeta get meta;
  int get length;

  TX getX(int index);
  TY getY(int index);

  /// Returns a subset of the series
  Series<TX, TY> slice(int start, [int? end]);

  /// Applies a pipeline of transformations
  Series<TX, TY> transform(Pipeline<TX, TY> pipeline);

  /// Aggregates the series based on specifications
  Series<TX, TY> aggregate(AggregationSpec<TX> spec);
}

abstract class SeriesStorage<TX, TY> {
  int get length;
  TX getX(int index);
  TY getY(int index);
  SeriesStorage<TX, TY> copy();
}

abstract class SeriesMeta {
  String get name;
  String? get unit;
}

abstract class SeriesStats {
  num get min;
  num get max;
  num get mean;
  int get count;
}

abstract class Reducer<T> {
  T reduce(List<T> values);
}

typedef Mapper<T> = T Function(T value);

abstract class Pipeline<TX, TY> {
  Pipeline<TX, TY> map(Mapper<TY> mapper);
  Pipeline<TX, TY> rolling(WindowSpec window, Reducer<TY> reducer);
  Pipeline<TX, TY> collapse(Reducer<TY> reducer);
  Series<TX, TY> execute(Series<TX, TY> input);
  TY executeScalar(Series<TX, TY> input);
}

abstract class WindowSpec {
  /// Fixed-size windows
  factory WindowSpec.fixed(num size) => throw UnimplementedError();

  /// Rolling/sliding windows
  factory WindowSpec.rolling(num size) => throw UnimplementedError();

  /// Pixel-aligned windows for rendering
  factory WindowSpec.pixelAligned(double pixelDensity) => throw UnimplementedError();
}

abstract class AggregationSpec<TX> {
  WindowSpec get window;
  Reducer get reducer;
}

/// Built-in reducers
abstract class Reducers {
  static Reducer<double> get mean => throw UnimplementedError();
  static Reducer<double> get max => throw UnimplementedError();
  static Reducer<double> get min => throw UnimplementedError();
  static Reducer<double> get sum => throw UnimplementedError();
}
