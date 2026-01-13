import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

void main() {
  group('Reactions', () {
    test('autorun runs immediately and tracks dependencies', () {
      final count = 0.toAtom();
      int runs = 0;
      int lastValue = -1;

      final disposer = autorun(() {
        runs++;
        lastValue = count.value;
      });

      expect(runs, 1);
      expect(lastValue, 0);

      count.increment();
      expect(runs, 2);
      expect(lastValue, 1);

      disposer();

      count.increment();
      expect(runs, 2); // Should not run again
    });

    test('reaction runs only when tracker output changes', () {
      final count = 0.toAtom();
      int sideEffectRuns = 0;
      int? lastEffectValue;

      final disposer = reaction(
        () => count.value,
        (val) {
          sideEffectRuns++;
          lastEffectValue = val;
        },
      );

      // Does not run immediately by default
      expect(sideEffectRuns, 0);

      count.increment();
      expect(sideEffectRuns, 1);
      expect(lastEffectValue, 1);

      // Same value should not trigger
      count.set(1);
      expect(sideEffectRuns, 1);

      disposer();
      count.increment();
      expect(sideEffectRuns, 1);
    });

    test('reaction fireImmediately works', () {
      final count = 10.toAtom();
      int runs = 0;

      final disposer = reaction(
        () => count.value,
        (_) => runs++,
        fireImmediately: true,
      );

      expect(runs, 1);
      disposer();
    });

    test('autorun handles dynamic dependencies', () {
      final switchAtom = true.toAtom();
      final a = 1.toAtom();
      final b = 2.toAtom();
      int runs = 0;

      final disposer = autorun(() {
        runs++;
        if (switchAtom.value) {
          a.value;
        } else {
          b.value;
        }
      });

      expect(runs, 1);

      // Initially depends on switchAtom and a
      a.value = 10;
      expect(runs, 2);

      b.value = 20;
      expect(runs, 2); // b is not tracked yet

      // Switch to b
      switchAtom.value = false;
      expect(runs, 3);

      // Now depends on switchAtom and b (a should be dropped)
      b.value = 30;
      expect(runs, 4);

      a.value = 40;
      expect(runs, 4); // a should be ignored

      disposer();
    });
  });
}
