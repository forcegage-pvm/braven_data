import 'package:braven_data/src/csv/column_def.dart';
import 'package:braven_data/src/csv/delimited_schema.dart';
import 'package:braven_data/src/csv/field_type.dart';
import 'package:braven_data/src/csv/loader.dart';
import 'package:braven_data/src/csv/x_value_type.dart';
import 'package:test/test.dart';

void main() {
  group('DelimitedLoader.loadString', () {
    test('loadString parses valid CSV into DataFrame', () {
      const content = 'time,hr,power\n100,150,200.5\n101,155,210.0';
      final schema = DelimitedSchema(
        xColumn: 'time',
        xType: XValueType.epochSeconds,
        columns: [
          ColumnDef(name: 'hr', type: FieldType.int64),
          ColumnDef(name: 'power', type: FieldType.float64),
        ],
      );

      final frame = DelimitedLoader.loadString(content, schema);
      expect(frame.rowCount, 2);
      expect(frame.columns['hr'], [150, 155]);
      expect(frame.columns['power'], [200.5, 210.0]);
    });

    test('loadString respects hasHeader flag', () {
      const content = '100,200.5\n101,210.0';
      final schema = DelimitedSchema(
        xType: XValueType.rowIndex,
        hasHeader: false,
        columns: [
          ColumnDef(name: 'power', type: FieldType.float64),
        ],
      );

      final frame = DelimitedLoader.loadString(content, schema);
      expect(frame.rowCount, 2);
      expect(frame.columns['power'], [200.5, 210.0]);
    });

    test('loadString uses correct delimiter from schema', () {
      const content = 'time;power\n100;200.5';
      final schema = DelimitedSchema(
        xColumn: 'time',
        xType: XValueType.epochSeconds,
        delimiter: ';',
        columns: [
          ColumnDef(name: 'power', type: FieldType.float64),
        ],
      );

      final frame = DelimitedLoader.loadString(content, schema);
      expect(frame.columns['power'], [200.5]);
    });

    test('loadString allows delimiter override', () {
      const content = 'time|power\n100|200.5';
      final schema = DelimitedSchema(
        xColumn: 'time',
        xType: XValueType.epochSeconds,
        columns: [
          ColumnDef(name: 'power', type: FieldType.float64),
        ],
      );

      final frame = DelimitedLoader.loadString(
        content,
        schema,
        delimiter: '|',
      );
      expect(frame.columns['power'], [200.5]);
    });

    test('loadString throws on empty content', () {
      final schema = DelimitedSchema(
        xColumn: 'time',
        xType: XValueType.epochSeconds,
        columns: [
          ColumnDef(name: 'power', type: FieldType.float64),
        ],
      );

      expect(() => DelimitedLoader.loadString('', schema), throwsFormatException);
    });

    test('loadString throws on column count mismatch', () {
      const content = 'time,power\n100\n101,210.0';
      final schema = DelimitedSchema(
        xColumn: 'time',
        xType: XValueType.epochSeconds,
        columns: [
          ColumnDef(name: 'power', type: FieldType.float64),
        ],
      );

      expect(
        () => DelimitedLoader.loadString(content, schema),
        throwsFormatException,
      );
    });

    test('loadString converts malformed numbers to NaN', () {
      const content = 'time,power\n100,not-a-number';
      final schema = DelimitedSchema(
        xColumn: 'time',
        xType: XValueType.epochSeconds,
        columns: [
          ColumnDef(name: 'power', type: FieldType.float64),
        ],
      );

      final frame = DelimitedLoader.loadString(content, schema);
      final value = frame.columns['power']![0] as double;
      expect(value.isNaN, isTrue);
    });

    test('loadString uses defaultValue for empty cells', () {
      const content = 'time,power\n100,';
      final schema = DelimitedSchema(
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

      final frame = DelimitedLoader.loadString(content, schema);
      expect(frame.columns['power'], [0.0]);
    });

    test('loadString validates schema xColumn exists in headers', () {
      const content = 'timestamp,power\n100,200.0';
      final schema = DelimitedSchema(
        xColumn: 'time',
        xType: XValueType.epochSeconds,
        columns: [
          ColumnDef(name: 'power', type: FieldType.float64),
        ],
      );

      expect(
        () => DelimitedLoader.loadString(content, schema),
        throwsArgumentError,
      );
    });
  });
}
