import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

void main() {
  test('Atom removeListener after dispose should not throw', () {
    final atom = Atom(0);
    void listener() {}
    atom.addListener(listener);

    atom.dispose();

    // This currently throws "A ValueAtom<int> was used after being disposed."
    // in debug/test mode because ChangeNotifier.removeListener checks _debugDisposed.
    expect(() => atom.removeListener(listener), returnsNormally);
  });
}
