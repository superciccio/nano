import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

void main() {
  test('ComputedAtom avoids redundant updates in batch', () {
    final a = 1.toAtom(label: 'a');
    final b = 2.toAtom(label: 'b');

    int computeCount = 0;

    // c = a + b
    final c = ComputedAtom<int>(() {
      computeCount++;
      return a.value + b.value;
    }, label: 'c');

    // Initial computation happens on creation
    expect(computeCount, 1);
    expect(c.value, 3);

    // Batch update both A and B
    Nano.batch(() {
      a.value = 10;
      b.value = 20;
    });

    // Expectation:
    // Without optimization: a->notify->c (calc 2), b->notify->c (calc 3). Total = 3.
    // With optimization: a->notify->defer, b->notify->c (calc 2). Total = 2.

    expect(c.value, 30);

    // We want specifically 2 computations: 1 (init) + 1 (update)
    // The force read in the middle is now cached thanks to Nano.version tagging.
    expect(
      computeCount,
      2,
      reason: 'ComputedAtom re-evaluated multiple times during batch',
    );
  });
}
