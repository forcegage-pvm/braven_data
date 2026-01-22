import 'dart:io';

import 'package:braven_data/braven_data.dart';
import 'package:dart_fit_decoder/dart_fit_decoder.dart' as fit_decoder;
import 'package:test/test.dart';

void main() {
  group('FitLoader', () {
    const fitPath = 'specs/_base/003-fit-file/joubertjp.2020-12-05-16-16-30-219Z.GarminPush.74900175025.fit';

    test('loads record messages into DataFrame', () async {
      final file = File(fitPath);
      if (!file.existsSync()) {
        fail('Missing FIT fixture at $fitPath');
      }

      final df = await FitLoader.load(file.path, FitMessageType.records);
      expect(df.rowCount, greaterThan(0));
      expect(df.columnNames, contains('timestamp'));
    });

    test('developer fields are included when present', () async {
      final file = File(fitPath);
      if (!file.existsSync()) {
        fail('Missing FIT fixture at $fitPath');
      }

      final bytes = file.readAsBytesSync();
      final fitFile = fit_decoder.FitDecoder(bytes).decode();
      final records = fitFile.getRecordMessages();

      final devFieldNames = <String>{};
      for (final record in records) {
        for (final devField in record.developerFields) {
          devFieldNames.add(_developerFieldName(devField));
        }
      }

      final df = await FitLoader.load(file.path, FitMessageType.records);

      for (final name in devFieldNames) {
        expect(df.columnNames, contains(name));
      }
    });

    test('skips missing explicit columns by default', () async {
      final file = File(fitPath);
      if (!file.existsSync()) {
        fail('Missing FIT fixture at $fitPath');
      }

      final schema = FitSchema(
        columns: [
          ColumnDef(name: 'non_existent_column', type: FieldType.float64),
        ],
        onMissingColumn: FitMissingColumnBehavior.skip,
      );

      final df = await FitLoader.load(
        file.path,
        FitMessageType.records,
        schema: schema,
      );

      expect(df.columnNames, isNot(contains('non_existent_column')));
    });

    test('errors on missing explicit columns when configured', () async {
      final file = File(fitPath);
      if (!file.existsSync()) {
        fail('Missing FIT fixture at $fitPath');
      }

      final schema = FitSchema(
        columns: [
          ColumnDef(name: 'non_existent_column', type: FieldType.float64),
        ],
        onMissingColumn: FitMissingColumnBehavior.error,
      );

      expect(
        () => FitLoader.load(file.path, FitMessageType.records, schema: schema),
        throwsArgumentError,
      );
    });
  });
}

String _developerFieldName(fit_decoder.DeveloperField field) {
  if (field.name != null && field.name!.isNotEmpty) {
    return field.name!;
  }
  return 'dev_field_${field.fieldNumber}_${field.developerDataIndex}';
}
