/// Aggregation window specifications for downsampling and rendering.
sealed class WindowSpec {
  const WindowSpec._();

  factory WindowSpec.fixed(num size) => FixedWindowSpec(size);

  factory WindowSpec.rolling(num size) => RollingWindowSpec(size);

  factory WindowSpec.pixelAligned(double pixelDensity) =>
      PixelAlignedWindowSpec(pixelDensity);
}

/// Non-overlapping fixed-size window.
class FixedWindowSpec extends WindowSpec {
  FixedWindowSpec(this.size) : super._() {
    _validateSize(size, 'size');
  }

  final num size;
}

/// Sliding window that moves through data.
class RollingWindowSpec extends WindowSpec {
  RollingWindowSpec(this.size) : super._() {
    _validateSize(size, 'size');
  }

  final num size;
}

/// Pixel-aligned dynamic window for rendering.
class PixelAlignedWindowSpec extends WindowSpec {
  PixelAlignedWindowSpec(this.pixelDensity) : super._() {
    if (pixelDensity.isNaN || pixelDensity.isInfinite || pixelDensity <= 0) {
      throw ArgumentError('pixelDensity must be a positive finite value.');
    }
  }

  final double pixelDensity;
}

void _validateSize(num size, String name) {
  if (size.isNaN || size.isInfinite || size <= 0) {
    throw ArgumentError('$name must be a positive finite value.');
  }
}
