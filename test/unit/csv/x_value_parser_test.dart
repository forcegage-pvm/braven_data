// @orchestra-task: 4
@Tags(['tdd-red'])
library;

import 'package:braven_data/src/csv/x_value_type.dart';
import 'package:test/test.dart';

class XValueParser {
  static double parseValue(
    String value,
    XValueType type, {
    double? baseEpoch,
  }) =>
      0.0;

  static List<double> parseColumn(List<String> values, XValueType type) => [];
}

void main() {
  group('XValueParser.parseValue', () {
    test('parseValue iso8601 converts to elapsed seconds from first value', () {
      final base = DateTime.parse('2025-10-26T13:23:17Z')
          .millisecondsSinceEpoch
          .toDouble();
      const value = '2025-10-26T13:23:18Z';
      final result = XValueParser.parseValue(
        value,
        XValueType.iso8601,
        baseEpoch: base,
      );
      expect(result, 1.0);
    });

    test('parseValue epochSeconds converts to elapsed seconds from first value',
        () {
      final result = XValueParser.parseValue(
        '101',
        XValueType.epochSeconds,
        baseEpoch: 100,
      );
      expect(result, 1.0);
    });

    test('parseValue epochMillis divides by 1000 then to elapsed', () {
      final result = XValueParser.parseValue(
        '1000',
        XValueType.epochMillis,
        baseEpoch: 0,
      );
      expect(result, 1.0);
    });

    test('parseValue elapsedSeconds uses value directly', () {
      final result = XValueParser.parseValue(
        '12.5',
        XValueType.elapsedSeconds,
      );
      expect(result, 12.5);
    });

    test('parseValue elapsedMillis divides by 1000', () {
      final result = XValueParser.parseValue(
        '1500',
        XValueType.elapsedMillis,
      );
      expect(result, 1.5);
    });

    test('parseValue rowIndex returns row number as double', () {
      final result = XValueParser.parseValue('3', XValueType.rowIndex);
      expect(result, 3.0);
    });

    test('parseValue custom throws unsupported', () {
      expect(
        () => XValueParser.parseValue('42', XValueType.custom),
        throwsUnsupportedError,
      );
    });
  });

  group('XValueParser.parseColumn', () {
    test('parseColumn normalizes all values relative to first', () {
      final values = ['100', '101', '102'];
      final result = XValueParser.parseColumn(values, XValueType.epochSeconds);
      expect(result, [0.0, 1.0, 2.0]);
    });

    test('parseColumn preserves non-monotonic timestamps (does NOT sort)', () {
      final values = ['100', '99', '101'];
      final result = XValueParser.parseColumn(values, XValueType.epochSeconds);
      expect(result, [0.0, -1.0, 1.0]);
    });
  });
}
