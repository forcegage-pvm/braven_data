import 'x_value_type.dart';

/// Utilities for parsing and normalizing X-axis values.
class XValueParser {
  /// Parses a single X value into elapsed seconds.
  static double parseValue(
    String value,
    XValueType type, {
    double? baseEpoch,
  }) {
    switch (type) {
      case XValueType.iso8601:
        final millis = DateTime.parse(value).millisecondsSinceEpoch.toDouble();
        if (baseEpoch != null) {
          return (millis - baseEpoch) / 1000.0;
        }
        return millis / 1000.0;
      case XValueType.epochSeconds:
        final seconds = double.parse(value);
        if (baseEpoch != null) {
          return seconds - baseEpoch;
        }
        return seconds;
      case XValueType.epochMillis:
        final millis = double.parse(value);
        if (baseEpoch != null) {
          return (millis - baseEpoch) / 1000.0;
        }
        return millis / 1000.0;
      case XValueType.elapsedSeconds:
        final seconds = double.parse(value);
        if (baseEpoch != null) {
          return seconds - baseEpoch;
        }
        return seconds;
      case XValueType.elapsedMillis:
        final millis = double.parse(value);
        if (baseEpoch != null) {
          return (millis - baseEpoch) / 1000.0;
        }
        return millis / 1000.0;
      case XValueType.rowIndex:
        return double.parse(value);
      case XValueType.custom:
        throw UnsupportedError('Custom X parsing is not supported.');
    }
  }

  /// Parses a column of values and normalizes them relative to the first.
  static List<double> parseColumn(List<String> values, XValueType type) {
    if (type == XValueType.custom) {
      throw UnsupportedError('Custom X parsing is not supported.');
    }
    if (type == XValueType.rowIndex) {
      return List<double>.generate(
        values.length,
        (index) => index.toDouble(),
      );
    }
    if (values.isEmpty) {
      return <double>[];
    }

    final baseValue = values.first;
    final baseEpoch = _baseEpochForType(baseValue, type);

    return values
        .map((value) => parseValue(value, type, baseEpoch: baseEpoch))
        .toList();
  }

  static double _baseEpochForType(String value, XValueType type) {
    switch (type) {
      case XValueType.iso8601:
        return DateTime.parse(value).millisecondsSinceEpoch.toDouble();
      case XValueType.epochSeconds:
        return double.parse(value);
      case XValueType.epochMillis:
        return double.parse(value);
      case XValueType.elapsedSeconds:
        return double.parse(value);
      case XValueType.elapsedMillis:
        return double.parse(value);
      case XValueType.rowIndex:
      case XValueType.custom:
        return 0.0;
    }
  }
}
