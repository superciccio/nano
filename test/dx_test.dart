import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

void main() {
  group('DX & Ergonomics', () {
    test('toAtom should support named parameters', () {
      final atom = 0.toAtom(label: 'test_atom');
      expect(atom.label, 'test_atom');
    });

    test('Strict Mode error message should be helpful', () {
      NanoConfig.strictMode = true;
      final atom = Atom(0);

      try {
        atom.value = 1;
        fail('Should have thrown an error');
      } catch (e) {
        expect(e.toString(), contains('Nano.action'));
        expect(e.toString(), contains('logic.dispatch(Increment())'));
      } finally {
        NanoConfig.strictMode = false;
      }
    });

    test('onInit side-effect error message should be helpful', () {
      final atom = Atom(0);
      final logic = _SideEffectLogic(atom);

      try {
        logic.initialize(null);
        fail('Should have thrown an error');
      } catch (e) {
        expect(e.toString(), contains('microtask'));
        expect(e.toString().toLowerCase(), contains('side-effect'));
      }
    });
    group('AsyncState Extensions', () {
      test('AsyncState.map handles all cases', () {
        const state = AsyncData<int>(10);
        final result = state.map(
          data: (d) => 'data $d',
          loading: () => 'loading',
          error: (e) => 'error',
          idle: () => 'idle',
        );
        expect(result, 'data 10');
      });
    });
  });
}

class _SideEffectLogic extends NanoLogic<void> {
  final Atom<int> atom;
  _SideEffectLogic(this.atom);

  @override
  void onInit(void params) {
    atom.value = 10; // Illegal side effect
  }
}
