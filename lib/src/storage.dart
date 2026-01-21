import 'dart:typed_data';

/// Storage abstraction for columnar series data.
abstract class SeriesStorage<TX, TY> {
  int get length;

  TX getX(int index);
  TY getY(int index);

  SeriesStorage<TX, TY> copy();
}

/// Stores numeric series values using typed-data buffers when possible.
///
/// The constructor normalizes numeric lists into `Float64List` or `Int64List`
/// for efficient storage. Use this storage when you want compact, fast numeric
/// access and predictable memory layout.
class TypedDataStorage<TX, TY> implements SeriesStorage<TX, TY> {
  TypedDataStorage({
    required List<TX> xValues,
    required List<TY> yValues,
  })  : _xValues = _ensureNumericStorage<TX>(xValues, 'xValues'),
        _yValues = _ensureNumericStorage<TY>(yValues, 'yValues') {
    if (_xValues.length != _yValues.length) {
      throw ArgumentError(
        'xValues and yValues must have the same length for TypedDataStorage.',
      );
    }
  }

  final List<TX> _xValues;
  final List<TY> _yValues;

  @override
  int get length => _xValues.length;

  @override
  TX getX(int index) => _xValues[index];

  @override
  TY getY(int index) => _yValues[index];

  @override
  SeriesStorage<TX, TY> copy() => TypedDataStorage<TX, TY>(
        xValues: List<TX>.from(_xValues),
        yValues: List<TY>.from(_yValues),
      );
}

/// Stores series values in standard Dart lists.
///
/// Use this storage when values are not strictly numeric or when list
/// semantics (such as mixed types) are required.
class ListStorage<TX, TY> implements SeriesStorage<TX, TY> {
  ListStorage({
    required List<TX> xValues,
    required List<TY> yValues,
  })  : _xValues = List<TX>.from(xValues),
        _yValues = List<TY>.from(yValues) {
    if (_xValues.length != _yValues.length) {
      throw ArgumentError(
        'xValues and yValues must have the same length for ListStorage.',
      );
    }
  }

  final List<TX> _xValues;
  final List<TY> _yValues;

  @override
  int get length => _xValues.length;

  @override
  TX getX(int index) => _xValues[index];

  @override
  TY getY(int index) => _yValues[index];

  @override
  SeriesStorage<TX, TY> copy() => ListStorage<TX, TY>(
        xValues: List<TX>.from(_xValues),
        yValues: List<TY>.from(_yValues),
      );
}

/// Storage for aggregated interval data using a structure-of-arrays layout.
///
/// Each X value maps to a minimum, maximum, and mean value for the interval.
class IntervalStorage<TX> implements SeriesStorage<TX, double> {
  IntervalStorage({
    required List<TX> xValues,
    required List<double> minValues,
    required List<double> maxValues,
    required List<double> meanValues,
  })  : _xValues = _ensureNumericStorage<TX>(xValues, 'xValues'),
        _minValues = _ensureDoubleStorage(minValues),
        _maxValues = _ensureDoubleStorage(maxValues),
        _meanValues = _ensureDoubleStorage(meanValues) {
    final length = _xValues.length;
    if (_minValues.length != length || _maxValues.length != length || _meanValues.length != length) {
      throw ArgumentError(
        'All value arrays must have the same length for IntervalStorage.',
      );
    }
  }

  final List<TX> _xValues;
  final List<double> _minValues;
  final List<double> _maxValues;
  final List<double> _meanValues;

  @override
  int get length => _xValues.length;

  @override
  TX getX(int index) => _xValues[index];

  double getMin(int index) => _minValues[index];

  double getMax(int index) => _maxValues[index];

  double getMean(int index) => _meanValues[index];

  @override
  double getY(int index) => _meanValues[index];

  @override
  IntervalStorage<TX> copy() => IntervalStorage<TX>(
        xValues: List<TX>.from(_xValues),
        minValues: List<double>.from(_minValues),
        maxValues: List<double>.from(_maxValues),
        meanValues: List<double>.from(_meanValues),
      );
}

List<T> _ensureNumericStorage<T>(List<T> values, String name) {
  if (values is Float64List || values is Int64List) {
    return values;
  }
  if (values is List<double>) {
    return Float64List.fromList(values.cast<double>()) as List<T>;
  }
  if (values is List<int>) {
    return Int64List.fromList(values.cast<int>()) as List<T>;
  }
  throw ArgumentError(
    '$name must contain numeric values (double or int) for typed storage.',
  );
}

List<double> _ensureDoubleStorage(List<double> values) {
  if (values is Float64List) {
    return values;
  }
  return Float64List.fromList(values);
}
