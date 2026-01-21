import 'package:braven_data/src/aggregation.dart';
import 'package:test/test.dart';

void main() {
  group('WindowSpec', () {
    test('creates fixed window with size', () {
      final spec = WindowSpec.fixed(30);

      expect(spec, isA<FixedWindowSpec>());
      expect((spec as FixedWindowSpec).size, 30);
    });

    test('creates rolling window with size', () {
      final spec = WindowSpec.rolling(15.5);

      expect(spec, isA<RollingWindowSpec>());
      expect((spec as RollingWindowSpec).size, 15.5);
    });

    test('creates pixel-aligned window with density', () {
      final spec = WindowSpec.pixelAligned(1.25);

      expect(spec, isA<PixelAlignedWindowSpec>());
      expect((spec as PixelAlignedWindowSpec).pixelDensity, 1.25);
    });

    test('throws for non-positive size', () {
      expect(() => WindowSpec.fixed(0), throwsArgumentError);
      expect(() => WindowSpec.rolling(-1), throwsArgumentError);
    });

    test('throws for invalid pixel density', () {
      expect(() => WindowSpec.pixelAligned(0), throwsArgumentError);
      expect(() => WindowSpec.pixelAligned(-2), throwsArgumentError);
      expect(() => WindowSpec.pixelAligned(double.nan), throwsArgumentError);
      expect(
        () => WindowSpec.pixelAligned(double.infinity),
        throwsArgumentError,
      );
    });
  });
}
