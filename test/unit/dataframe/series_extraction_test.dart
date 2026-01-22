// @orchestra-task: 4
@Tags(['tdd-red'])
library;

import 'package:braven_data/src/csv/column_def.dart';
import 'package:braven_data/src/csv/csv_schema.dart';
import 'package:braven_data/src/csv/field_type.dart';
import 'package:braven_data/src/csv/x_value_type.dart';
import 'package:braven_data/src/series.dart';
import 'package:test/test.dart';

class DataFrame {
  DataFrame(this.columns, this.schema);

  final Map<String, List<dynamic>> columns;
  final CsvSchema schema;
}

extension DataFrameSeriesExtraction on DataFrame {
  Series<double, double> toSeries(String yColumn, {SeriesMeta? meta}) {
    throw UnimplementedError();
  }
}

void main() {
  group('DataFrame.toSeries', () {
    test('toSeries extracts Y column with X as elapsed seconds', () {
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
          'power': [200.0, 210.0],
        },
        schema,
      );

      final series = frame.toSeries('power');
      expect(series.length, 2);
      expect(series.getX(0), 0.0);
      expect(series.getX(1), 1.0);
      expect(series.getY(0), 200.0);
      expect(series.getY(1), 210.0);
    });

    test('toSeries normalizes X values relative to first point', () {
      final schema = CsvSchema(
        xColumn: 'time',
        xType: XValueType.elapsedSeconds,
        columns: [
          ColumnDef(name: 'power', type: FieldType.float64),
        ],
      );

      final frame = DataFrame(
        {
          'time': [5.0, 6.5],
          'power': [200.0, 210.0],
        },
        schema,
      );

      final series = frame.toSeries('power');
      expect(series.getX(0), 0.0);
      expect(series.getX(1), 1.5);
    });

    test('toSeries preserves row order (non-monotonic X allowed)', () {
      final schema = CsvSchema(
        xColumn: 'time',
        xType: XValueType.epochSeconds,
        columns: [
          ColumnDef(name: 'power', type: FieldType.float64),
        ],
      );

      final frame = DataFrame(
        {
          'time': [100.0, 90.0],
          'power': [200.0, 210.0],
        },
        schema,
      );

      final series = frame.toSeries('power');
      expect(series.getX(0), 0.0);
      expect(series.getX(1), -10.0);
    });

    test('toSeries throws for unknown yColumn', () {
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
          'power': [200.0],
        },
        schema,
      );

      expect(() => frame.toSeries('missing'), throwsArgumentError);
    });

    test('toSeries uses provided SeriesMeta', () {
      final schema = CsvSchema(
        xColumn: 'time',
        xType: XValueType.epochSeconds,
        columns: [
          ColumnDef(name: 'power', type: FieldType.float64),
        ],
      );

      const meta = SeriesMeta(name: 'Power', unit: 'W');
      final frame = DataFrame(
        {
          'time': [100.0],
          'power': [200.0],
        },
        schema,
      );

      final series = frame.toSeries('power', meta: meta);
      expect(series.meta.name, 'Power');
      expect(series.meta.unit, 'W');
    });

    test('toSeries auto-generates SeriesMeta from column name if not provided', () {
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
          'power': [200.0],
        },
        schema,
      );

      final series = frame.toSeries('power');
      expect(series.meta.name, 'power');
      expect(series.meta.unit, isNull);
    });
  });
}
