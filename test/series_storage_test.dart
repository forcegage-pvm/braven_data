import 'package:braven_data/src/storage.dart';
import 'package:test/test.dart';

class _FakeStorage implements SeriesStorage<int, double> {
  _FakeStorage(this._xValues, this._yValues);

  final List<int> _xValues;
  final List<double> _yValues;

  @override
  int get length => _xValues.length;

  @override
  int getX(int index) => _xValues[index];

  @override
  double getY(int index) => _yValues[index];

  @override
  SeriesStorage<int, double> copy() => _FakeStorage(
        List<int>.from(_xValues),
        List<double>.from(_yValues),
      );
}

void main() {
  group('SeriesStorage', () {
    test('provides length, accessors, and copy', () {
      final storage = _FakeStorage([1, 2], [1.5, 2.5]);

      expect(storage.length, 2);
      expect(storage.getX(1), 2);
      expect(storage.getY(0), 1.5);

      final copy = storage.copy();
      expect(copy, isA<SeriesStorage<int, double>>());
      expect(copy.length, 2);
      expect(copy.getX(0), 1);
      expect(copy.getY(1), 2.5);
    });
  });
}
