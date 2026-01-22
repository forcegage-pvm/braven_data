import 'package:braven_data/src/csv/column_def.dart';
import 'package:braven_data/src/csv/csv_schema.dart';
import 'package:braven_data/src/csv/field_type.dart';
import 'package:braven_data/src/csv/x_value_type.dart';
import 'package:braven_data/src/dataframe/dataframe.dart';
import 'package:test/test.dart';

void main() {
  group('DataFrame', () {
    test('rowCount returns number of data rows', () {
      final schema = CsvSchema(
        xColumn: 'time',
        xType: XValueType.epochSeconds,
        columns: [
          ColumnDef(name: 'power', type: FieldType.float64),
        ],
      );

      final frame = DataFrame(
        {
          'time': [100.0, 101.0],
          'power': [200.5, 210.0],
        },
        schema,
      );

      expect(frame.rowCount, 2);
    });

    test('columnNames includes all columns', () {
      final schema = CsvSchema(
        xColumn: 'time',
        xType: XValueType.epochSeconds,
        columns: [
          ColumnDef(name: 'power', type: FieldType.float64),
        ],
      );

      final frame = DataFrame(
        {
          'time': [100.0],
          'power': [200.5],
        },
        schema,
      );

      expect(frame.columnNames, containsAll(['time', 'power']));
    });

    test('get<T> returns typed column data', () {
      final schema = CsvSchema(
        xColumn: 'time',
        xType: XValueType.epochSeconds,
        columns: [
          ColumnDef(name: 'power', type: FieldType.float64),
        ],
      );

      final frame = DataFrame(
        {
          'time': [100.0, 101.0],
          'power': [200.5, 210.0],
        },
        schema,
      );

      final values = frame.get<double>('power');
      expect(values, [200.5, 210.0]);
    });

    test('get<T> throws for unknown column', () {
      final schema = CsvSchema(
        xColumn: 'time',
        xType: XValueType.epochSeconds,
        columns: [
          ColumnDef(name: 'power', type: FieldType.float64),
        ],
      );

      final frame = DataFrame(
        {
          'time': [100.0],
          'power': [200.5],
        },
        schema,
      );

      expect(() => frame.get<double>('missing'), throwsArgumentError);
    });

    test('getXValues returns X column as doubles', () {
      final schema = CsvSchema(
        xColumn: 'time',
        xType: XValueType.epochSeconds,
        columns: [
          ColumnDef(name: 'power', type: FieldType.float64),
        ],
      );

      final frame = DataFrame(
        {
          'time': [100.0, 101.0],
          'power': [200.5, 210.0],
        },
        schema,
      );

      expect(frame.getXValues(), [0.0, 1.0]);
    });

    test('getXValues returns row indices when xType is rowIndex', () {
      final schema = CsvSchema(
        xType: XValueType.rowIndex,
        columns: [
          ColumnDef(name: 'power', type: FieldType.float64),
        ],
      );

      final frame = DataFrame(
        {
          'power': [200.5, 210.0, 220.0],
        },
        schema,
      );

      expect(frame.getXValues(), [0.0, 1.0, 2.0]);
    });
  });
}
