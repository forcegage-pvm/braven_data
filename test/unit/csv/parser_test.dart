// @orchestra-task: 4
@Tags(['tdd-red'])
library;

import 'package:test/test.dart';

class CsvParser {
  static List<String> splitLines(String content) => [];

  static List<String> parseFields(String line, {String delimiter = ','}) => [];
}

void main() {
  group('CsvParser.splitLines', () {
    test('splitLines handles LF line endings', () {
      const content = 'a,b\nc,d\ne,f';
      final lines = CsvParser.splitLines(content);
      expect(lines, ['a,b', 'c,d', 'e,f']);
    });

    test('splitLines handles CRLF line endings', () {
      const content = 'a,b\r\nc,d\r\ne,f';
      final lines = CsvParser.splitLines(content);
      expect(lines, ['a,b', 'c,d', 'e,f']);
    });

    test('splitLines handles mixed line endings', () {
      const content = 'a,b\r\nc,d\ne,f\r\n';
      final lines = CsvParser.splitLines(content);
      expect(lines, ['a,b', 'c,d', 'e,f']);
    });
  });

  group('CsvParser.parseFields', () {
    test('parseFields splits by delimiter', () {
      final fields = CsvParser.parseFields('a,b,c');
      expect(fields, ['a', 'b', 'c']);
    });

    test('parseFields handles quoted values with commas', () {
      final fields = CsvParser.parseFields('"a,b",c');
      expect(fields, ['a,b', 'c']);
    });

    test('parseFields handles escaped quotes inside quoted values', () {
      final fields = CsvParser.parseFields('"a""b",c');
      expect(fields, ['a"b', 'c']);
    });

    test('parseFields handles empty values', () {
      final fields = CsvParser.parseFields('a,,c,');
      expect(fields, ['a', '', 'c', '']);
    });

    test('parseFields handles custom delimiter', () {
      final fields = CsvParser.parseFields('a|b|c', delimiter: '|');
      expect(fields, ['a', 'b', 'c']);
    });
  });
}
