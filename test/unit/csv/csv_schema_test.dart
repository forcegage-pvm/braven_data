import 'package:braven_data/src/csv/column_def.dart';
import 'package:braven_data/src/csv/csv_schema.dart';
import 'package:braven_data/src/csv/field_type.dart';
import 'package:braven_data/src/csv/x_value_type.dart';
import 'package:test/test.dart';

XValueType _nonConstXType(XValueType value) => value;

void main() {
  group('CsvSchema', () {
    test('construction with valid xColumn, xType, and columns succeeds', () {
      final schema = CsvSchema(
        xColumn: 'timestamp',
        xType: XValueType.iso8601,
        columns: [
          ColumnDef(name: 'power', type: FieldType.float64),
        ],
      );
      expect(schema.xColumn, 'timestamp');
      expect(schema.xType, XValueType.iso8601);
      expect(schema.columns.length, 1);
    });

    test('xColumn null with non-rowIndex xType throws ArgumentError', () {
      final xType = _nonConstXType(XValueType.epochSeconds);
      final columns = [
        ColumnDef(name: 'power', type: FieldType.float64),
      ];
      expect(
        () => CsvSchema(
          xType: xType,
          columns: columns,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('xColumn null with xType.rowIndex succeeds', () {
      final schema = CsvSchema(
        xType: XValueType.rowIndex,
        columns: [
          ColumnDef(name: 'power', type: FieldType.float64),
        ],
      );
      expect(schema.xColumn, isNull);
      expect(schema.xType, XValueType.rowIndex);
    });

    test('empty columns list throws ArgumentError', () {
      final xType = _nonConstXType(XValueType.rowIndex);
      final columns = <ColumnDef>[];
      expect(
        () => CsvSchema(
          xType: xType,
          columns: columns,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('duplicate column names throws ArgumentError', () {
      final xType = _nonConstXType(XValueType.rowIndex);
      final columns = [
        ColumnDef(name: 'power', type: FieldType.float64),
        ColumnDef(name: 'power', type: FieldType.int64),
      ];
      expect(
        () => CsvSchema(
          xType: xType,
          columns: columns,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('default hasHeader is true', () {
      final schema = CsvSchema(
        xType: XValueType.rowIndex,
        columns: [
          ColumnDef(name: 'power', type: FieldType.float64),
        ],
      );
      expect(schema.hasHeader, isTrue);
    });

    test('default delimiter is comma', () {
      final schema = CsvSchema(
        xType: XValueType.rowIndex,
        columns: [
          ColumnDef(name: 'power', type: FieldType.float64),
        ],
      );
      expect(schema.delimiter, ',');
    });

    test('xType accepts all XValueType enum values', () {
      for (final value in XValueType.values) {
        final schema = CsvSchema(
          xType: value,
          xColumn: value == XValueType.rowIndex ? null : 'x',
          columns: [
            ColumnDef(name: 'power', type: FieldType.float64),
          ],
        );
        expect(schema.xType, value);
      }
    });
  });
}
