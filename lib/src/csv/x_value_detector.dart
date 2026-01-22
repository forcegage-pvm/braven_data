import 'x_value_type.dart';

/// Detects the X-value format from sample strings.
class XValueDetector {
  /// Detects the XValueType from a sample of string values.
  static XValueType detect(List<String> sampleValues) {
    if (sampleValues.isEmpty) {
      return XValueType.rowIndex;
    }

    final values = sampleValues.map((value) => value.trim()).toList();
    if (values.any((value) => value.isEmpty)) {
      return XValueType.rowIndex;
    }

    if (_allMatchIso8601(values)) {
      return XValueType.iso8601;
    }

    if (_allMatchEpochMillis(values)) {
      return XValueType.epochMillis;
    }

    if (_allMatchEpochSeconds(values)) {
      return XValueType.epochSeconds;
    }

    if (_allMatchElapsedSeconds(values)) {
      return XValueType.elapsedSeconds;
    }

    return XValueType.rowIndex;
  }

  static bool _allMatchIso8601(List<String> values) {
    final regex = RegExp(
      r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})?$',
    );
    for (final value in values) {
      if (!regex.hasMatch(value)) {
        return false;
      }
      try {
        DateTime.parse(value);
      } on FormatException {
        return false;
      }
    }
    return true;
  }

  static bool _allMatchEpochMillis(List<String> values) {
    const minEpochMillis = 1000000000000;
    const maxEpochMillis = 2000000000000;
    for (final value in values) {
      final millis = _parseInt(value);
      if (millis == null || millis < minEpochMillis || millis > maxEpochMillis) {
        return false;
      }
      if (value.length != 13) {
        return false;
      }
    }
    return true;
  }

  static bool _allMatchEpochSeconds(List<String> values) {
    const minEpochSeconds = 1000000000;
    const maxEpochSeconds = 2000000000;
    for (final value in values) {
      final seconds = _parseInt(value);
      if (seconds == null || seconds < minEpochSeconds || seconds > maxEpochSeconds) {
        return false;
      }
      if (value.length != 10) {
        return false;
      }
    }
    return true;
  }

  static bool _allMatchElapsedSeconds(List<String> values) {
    var minValue = double.infinity;
    var maxValue = double.negativeInfinity;
    for (final value in values) {
      final seconds = _parseInt(value);
      if (seconds == null || seconds < 0) {
        return false;
      }
      if (seconds < minValue) {
        minValue = seconds.toDouble();
      }
      if (seconds > maxValue) {
        maxValue = seconds.toDouble();
      }
    }

    if (minValue > 1) {
      return false;
    }

    return maxValue <= 10000000;
  }

  static int? _parseInt(String value) {
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return null;
    }
    return int.tryParse(value);
  }
}
