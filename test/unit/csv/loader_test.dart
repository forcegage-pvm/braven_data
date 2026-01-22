// @orchestra-task: 4
@Tags(['tdd-red'])
library;

import 'package:braven_data/src/csv/column_def.dart';
import 'package:braven_data/src/csv/csv_schema.dart';
import 'package:braven_data/src/csv/field_type.dart';
import 'package:braven_data/src/csv/x_value_type.dart';
import 'package:test/test.dart';

class DataFrame {
  DataFrame(this.columns, this.schema);

  final Map<String, List<dynamic>> columns;
  final CsvSchema schema;

  int get rowCount => columns.isEmpty ? 0 : columns.values.first.length;
}

class CsvLoader {
  static DataFrame loadString(String content, CsvSchema schema) {
    throw UnimplementedError();
  }
}

void main() {
  group('CsvLoader.loadString', () {
    test('loadString parses valid CSV into DataFrame', () {
      const content = 'time,hr,power\n100,150,200.5\n101,155,210.0';
      final schema = CsvSchema(
        xColumn: 'time',
        xType: XValueType.epochSeconds,
        columns: [
          ColumnDef(name: 'hr', type: FieldType.int64),
          ColumnDef(name: 'power', type: FieldType.float64),
        ],
      );

      final frame = CsvLoader.loadString(content, schema);
      expect(frame.rowCount, 2);
      expect(frame.columns['hr'], [150, 155]);
      expect(frame.columns['power'], [200.5, 210.0]);
    });

    test('loadString respects hasHeader flag', () {
      const content = '100,200.5\n101,210.0';
      final schema = CsvSchema(
        xType: XValueType.rowIndex,
        hasHeader: false,
        columns: [
          ColumnDef(name: 'power', type: FieldType.float64),
        ],
      );

      final frame = CsvLoader.loadString(content, schema);
      expect(frame.rowCount, 2);
      expect(frame.columns['power'], [200.5, 210.0]);
    });

    test('loadString uses correct delimiter from schema', () {
      const content = 'time;power\n100;200.5';
      final schema = CsvSchema(
        xColumn: 'time',
        xType: XValueType.epochSeconds,
        delimiter: ';',
        columns: [
          ColumnDef(name: 'power', type: FieldType.float64),
        ],
      );

      final frame = CsvLoader.loadString(content, schema);
      expect(frame.columns['power'], [200.5]);
    });

    test('loadString throws on empty content', () {
      final schema = CsvSchema(
        xColumn: 'time',
        xType: XValueType.epochSeconds,
        columns: [
          ColumnDef(name: 'power', type: FieldType.float64),
        ],
      );

      expect(() => CsvLoader.loadString('', schema), throwsFormatException);
    });

    test('loadString throws on column count mismatch', () {
      const content = 'time,power\n100\n101,210.0';
      final schema = CsvSchema(
        xColumn: 'time',
        xType: XValueType.epochSeconds,
        columns: [
          ColumnDef(name: 'power', type: FieldType.float64),
        ],
      );

      expect(
        () => CsvLoader.loadString(content, schema),
        throwsFormatException,
      );
    });

    test('loadString converts malformed numbers to NaN', () {
      const content = 'time,power\n100,not-a-number';
      final schema = CsvSchema(
        xColumn: 'time',
        xType: XValueType.epochSeconds,
        columns: [
          ColumnDef(name: 'power', type: FieldType.float64),
        ],
      );

      final frame = CsvLoader.loadString(content, schema);
      final value = frame.columns['power']![0] as double;
      expect(value.isNaN, isTrue);
    });

    test('loadString uses defaultValue for empty cells', () {
      const content = 'time,power\n100,';
      final schema = CsvSchema(
        xColumn: 'time',
        xType: XValueType.epochSeconds,
        columns: [
          ColumnDef(
            name: 'power',
            type: FieldType.float64,
            defaultValue: 0.0,
          ),
        ],
      );

      final frame = CsvLoader.loadString(content, schema);
      expect(frame.columns['power'], [0.0]);
    });

    test('loadString validates schema xColumn exists in headers', () {
      const content = 'timestamp,power\n100,200.0';
      final schema = CsvSchema(
        xColumn: 'time',
        xType: XValueType.epochSeconds,
        columns: [
          ColumnDef(name: 'power', type: FieldType.float64),
        ],
      );

      expect(
        () => CsvLoader.loadString(content, schema),
        throwsArgumentError,
      );
    });
  });
}
