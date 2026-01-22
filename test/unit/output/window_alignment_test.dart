// @orchestra-task: 6
@Tags(['tdd-red'])
library;

import 'package:braven_data/src/output/window_alignment.dart';
import 'package:test/test.dart';

double alignWindowX(
  List<double> windowX,
  WindowAlignment alignment,
) {
  throw UnimplementedError('Duration-based window alignment not implemented.');
}

void main() {
  group('WindowAlignment', () {
    test('start aligns to first X in window', () {
      final aligned = alignWindowX(
        [10.0, 20.0, 30.0],
        WindowAlignment.start,
      );

      expect(aligned, 10.0);
    });

    test('center aligns to midpoint of first and last X', () {
      final aligned = alignWindowX(
        [10.0, 20.0, 30.0],
        WindowAlignment.center,
      );

      expect(aligned, 20.0);
    });

    test('end aligns to last X in window', () {
      final aligned = alignWindowX(
        [10.0, 20.0, 30.0],
        WindowAlignment.end,
      );

      expect(aligned, 30.0);
    });
  });
}
