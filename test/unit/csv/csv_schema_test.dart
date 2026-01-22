// @orchestra-task: 2
@Tags(['tdd-red'])
library;

import 'package:braven_data/src/csv/field_type.dart';
import 'package:braven_data/src/csv/x_value_type.dart';
import 'package:test/test.dart';

// Stub - will be replaced by import when implementation exists.
class ColumnDef {
  final String name;
  final FieldType type;
  final dynamic defaultValue;
  final String? unit;

  const ColumnDef({
    required this.name,
    required this.type,
    this.defaultValue,
    this.unit,
  });
}

// Stub - will be replaced by import when implementation exists.
class CsvSchema {
  final String? xColumn;
  final XValueType xType;
  final String? xFormat;
  final List<ColumnDef> columns;
  final bool hasHeader;
  final String delimiter;

  const CsvSchema({
    this.xColumn,
    required this.xType,
    this.xFormat,
    required this.columns,
    this.hasHeader = true,
    this.delimiter = ',',
  });
}

XValueType _nonConstXType(XValueType value) => value;

void main() {
  group('CsvSchema', () {
    test('construction with valid xColumn, xType, and columns succeeds', () {
      const schema = CsvSchema(
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
        const ColumnDef(name: 'power', type: FieldType.float64),
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
      const schema = CsvSchema(
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
        const ColumnDef(name: 'power', type: FieldType.float64),
        const ColumnDef(name: 'power', type: FieldType.int64),
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
      const schema = CsvSchema(
        xType: XValueType.rowIndex,
        columns: [
          ColumnDef(name: 'power', type: FieldType.float64),
        ],
      );
      expect(schema.hasHeader, isTrue);
    });

    test('default delimiter is comma', () {
      const schema = CsvSchema(
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
            const ColumnDef(name: 'power', type: FieldType.float64),
          ],
        );
        expect(schema.xType, value);
      }
    });
  });
}
