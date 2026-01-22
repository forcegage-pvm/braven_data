// @orchestra-task: 2
@Tags(['tdd-red'])
library;

import 'package:braven_data/src/csv/field_type.dart';
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

void main() {
  group('ColumnDef', () {
    test('construction with valid name and type succeeds', () {
      const def = ColumnDef(name: 'power', type: FieldType.float64);
      expect(def.name, 'power');
      expect(def.type, FieldType.float64);
    });

    test('construction with empty name throws ArgumentError', () {
      expect(
        () => const ColumnDef(name: '', type: FieldType.int64),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('optional unit parameter is stored correctly', () {
      const def = ColumnDef(
        name: 'cadence',
        type: FieldType.int64,
        unit: 'rpm',
      );
      expect(def.unit, 'rpm');
    });

    test('optional defaultValue parameter is stored correctly', () {
      const def = ColumnDef(
        name: 'speed',
        type: FieldType.float64,
        defaultValue: 0.0,
      );
      expect(def.defaultValue, 0.0);
    });

    test('defaultValue type mismatch throws ArgumentError', () {
      expect(
        () => const ColumnDef(
          name: 'altitude',
          type: FieldType.float64,
          defaultValue: 'bad',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
