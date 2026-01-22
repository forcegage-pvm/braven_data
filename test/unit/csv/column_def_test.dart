import 'package:braven_data/src/csv/column_def.dart';
import 'package:braven_data/src/csv/field_type.dart';
import 'package:test/test.dart';

void main() {
  group('ColumnDef', () {
    test('construction with valid name and type succeeds', () {
      final def = ColumnDef(name: 'power', type: FieldType.float64);
      expect(def.name, 'power');
      expect(def.type, FieldType.float64);
    });

    test('construction with empty name throws ArgumentError', () {
      expect(
        () => ColumnDef(name: '', type: FieldType.int64),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('optional unit parameter is stored correctly', () {
      final def = ColumnDef(
        name: 'cadence',
        type: FieldType.int64,
        unit: 'rpm',
      );
      expect(def.unit, 'rpm');
    });

    test('optional defaultValue parameter is stored correctly', () {
      final def = ColumnDef(
        name: 'speed',
        type: FieldType.float64,
        defaultValue: 0.0,
      );
      expect(def.defaultValue, 0.0);
    });

    test('defaultValue type mismatch throws ArgumentError', () {
      expect(
        () => ColumnDef(
          name: 'altitude',
          type: FieldType.float64,
          defaultValue: 'bad',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
