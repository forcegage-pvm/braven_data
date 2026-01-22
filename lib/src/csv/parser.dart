/// Low-level CSV parsing utilities.
class CsvParser {
  /// Splits content into lines handling LF, CRLF, and mixed line endings.
  static List<String> splitLines(String content) {
    if (content.isEmpty) {
      return <String>[''];
    }
    var normalized = content.replaceAll('\r\n', '\n');
    normalized = normalized.replaceAll('\r', '\n');
    final lines = normalized.split('\n');
    if (lines.isNotEmpty && lines.last.isEmpty) {
      lines.removeLast();
    }
    return lines;
  }

  /// Parses a CSV line into fields with RFC 4180 quoting rules.
  static List<String> parseFields(String line, {String delimiter = ','}) {
    final fields = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (inQuotes) {
        if (char == '"') {
          final isEscapedQuote = i + 1 < line.length && line[i + 1] == '"';
          if (isEscapedQuote) {
            buffer.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          buffer.write(char);
        }
      } else {
        if (char == '"' && buffer.isEmpty) {
          inQuotes = true;
        } else if (char == delimiter) {
          fields.add(buffer.toString());
          buffer.clear();
        } else {
          buffer.write(char);
        }
      }
    }

    fields.add(buffer.toString());
    return fields;
  }
}
