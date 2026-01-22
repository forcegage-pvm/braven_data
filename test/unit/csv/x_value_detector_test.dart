library;

import 'package:braven_data/src/csv/x_value_detector.dart';
import 'package:braven_data/src/csv/x_value_type.dart';
import 'package:test/test.dart';

void main() {
  group('XValueDetector.detect', () {
    group('ISO 8601 detection', () {
      test('detects full ISO 8601 with timezone', () {
        final result = XValueDetector.detect([
          '2025-10-26T13:23:17Z',
          '2025-10-26T13:23:18Z',
        ]);
        expect(result, XValueType.iso8601);
      });

      test('detects ISO 8601 without timezone', () {
        final result = XValueDetector.detect([
          '2025-10-26T13:23:17',
          '2025-10-26T13:23:18',
        ]);
        expect(result, XValueType.iso8601);
      });
    });

    group('epoch seconds detection', () {
      test('detects Unix timestamp in seconds', () {
        final result = XValueDetector.detect([
          '1698325397',
          '1698325400',
          '1698325403',
        ]);
        expect(result, XValueType.epochSeconds);
      });
    });

    group('epoch milliseconds detection', () {
      test('detects Unix timestamp in milliseconds', () {
        final result = XValueDetector.detect([
          '1698325397000',
          '1698325398000',
          '1698325399000',
        ]);
        expect(result, XValueType.epochMillis);
      });
    });

    group('elapsed seconds detection', () {
      test('detects incrementing integers from zero', () {
        final result = XValueDetector.detect([
          '0',
          '1',
          '2',
          '3',
        ]);
        expect(result, XValueType.elapsedSeconds);
      });
    });

    group('ambiguous values and fallbacks', () {
      test('falls back to rowIndex for unrecognized format', () {
        final result = XValueDetector.detect([
          'abc',
          'def',
          'ghi',
        ]);
        expect(result, XValueType.rowIndex);
      });

      test('handles mixed format sample gracefully', () {
        final result = XValueDetector.detect([
          '2025-10-26T13:23:17Z',
          '1698325397',
        ]);
        expect(result, XValueType.rowIndex);
      });

      test('falls back when values are out of known ranges', () {
        final result = XValueDetector.detect([
          '9999999999',
          '10000000000',
        ]);
        expect(result, XValueType.rowIndex);
      });
    });
  });
}
