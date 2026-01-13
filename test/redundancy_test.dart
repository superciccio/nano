import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

void main() {
  test('ComputedAtom avoids redundant updates in batch', () {
    final a = 1.toAtom('a');
    final b = 2.toAtom('b');

    int computeCount = 0;

    // c = a + b
    final c = ComputedAtom<int>(
      [a, b],
      () {
        computeCount++;
        return a.value + b.value;
      },
      label: 'c',
    );

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

    // We strictly want ONLY 1 re-computation for the batch, so total should be 1 (init) + 1 (update) = 2.
    // If it is 3, we have redundancy.
    expect(computeCount, 2, reason: 'ComputedAtom re-evaluated multiple times during batch');
  });
}
