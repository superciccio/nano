import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

void main() {
  test('Nano.batch defers notifications', () {
    final atom1 = 0.toAtom(label: 'atom1');
    final atom2 = 0.toAtom(label: 'atom2');

    int callCount1 = 0;
    int callCount2 = 0;

    atom1.addListener(() => callCount1++);
    atom2.addListener(() => callCount2++);

    Nano.batch(() {
      atom1.value = 1;
      atom1.value = 2; // Should only notify once with final value
      atom2.value = 10;

      expect(callCount1, 0);
      expect(callCount2, 0);
    });

    expect(callCount1, 1);
    expect(callCount2, 1);
    expect(atom1.value, 2);
    expect(atom2.value, 10);
  });
}
