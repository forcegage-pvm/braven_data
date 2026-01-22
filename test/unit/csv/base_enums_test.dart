import 'dart:io';

import 'package:braven_data/src/csv/field_type.dart';
import 'package:braven_data/src/csv/x_value_type.dart';
import 'package:braven_data/src/output/window_alignment.dart';
import 'package:test/test.dart';

void main() {
  group('directory structure', () {
    test('source directories exist with expected files', () {
      expect(Directory('lib/src/csv').existsSync(), isTrue);
      expect(File('lib/src/csv/x_value_type.dart').existsSync(), isTrue);
      expect(File('lib/src/csv/field_type.dart').existsSync(), isTrue);

      expect(Directory('lib/src/dataframe').existsSync(), isTrue);
      expect(File('lib/src/dataframe/.gitkeep').existsSync(), isTrue);

      expect(Directory('lib/src/output').existsSync(), isTrue);
      expect(File('lib/src/output/window_alignment.dart').existsSync(), isTrue);

      expect(Directory('lib/src/metrics').existsSync(), isTrue);
      expect(File('lib/src/metrics/.gitkeep').existsSync(), isTrue);
    });

    test('test directories exist', () {
      expect(Directory('test/unit/csv').existsSync(), isTrue);
      expect(Directory('test/unit/dataframe').existsSync(), isTrue);
      expect(Directory('test/unit/output').existsSync(), isTrue);
      expect(Directory('test/unit/metrics').existsSync(), isTrue);
      expect(Directory('test/integration').existsSync(), isTrue);
    });
  });

  group('base enums', () {
    test('XValueType includes all expected values', () {
      expect(
        XValueType.values,
        equals(const [
          XValueType.iso8601,
          XValueType.epochSeconds,
          XValueType.epochMillis,
          XValueType.elapsedSeconds,
          XValueType.elapsedMillis,
          XValueType.rowIndex,
          XValueType.custom,
        ]),
      );
    });

    test('FieldType includes all expected values', () {
      expect(
        FieldType.values,
        equals(const [
          FieldType.float64,
          FieldType.int64,
          FieldType.string,
        ]),
      );
    });

    test('WindowAlignment includes all expected values', () {
      expect(
        WindowAlignment.values,
        equals(const [
          WindowAlignment.start,
          WindowAlignment.center,
          WindowAlignment.end,
        ]),
      );
    });
  });

  group('braven_data exports placeholder', () {
    test('braven_data.dart contains CSV placeholder comments', () {
      final content = File('lib/braven_data.dart').readAsStringSync();
      expect(
        content.contains('CSV processing pipeline exports (placeholder).'),
        isTrue,
      );
    });
  });
}
