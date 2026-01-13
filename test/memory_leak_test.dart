import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

void main() {
  group('Memory Leak Prevention', () {
    test('NanoLogic should dispose its internal atoms (status, error)', () {
      final initialCount = NanoDebugService.registeredAtomCount;

      final logic = _TestLogic();

      // Each NanoLogic has 2 atoms: status and error
      expect(NanoDebugService.registeredAtomCount, initialCount + 2);

      logic.dispose();

      // They should be removed from the registry
      expect(NanoDebugService.registeredAtomCount, initialCount);
    });
  });
}

class _TestLogic extends NanoLogic<void> {}
