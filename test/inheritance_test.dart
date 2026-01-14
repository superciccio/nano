import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

void main() {
  test('Atom should implement ValueListenable but NOT extend ValueNotifier',
      () {
    final atom = Atom(0);

    expect(atom, isA<ValueListenable<int>>());
    expect(atom is ValueNotifier, isFalse,
        reason: 'Atom should not extend ValueNotifier (Leaky Abstraction fix)');
  });

  test(
      'ComputedAtom should implement ValueListenable but NOT extend ValueNotifier',
      () {
    final a = Atom(1);
    final c = ComputedAtom(() => a.value * 2);

    expect(c, isA<ValueListenable<int>>());
    expect(c is ValueNotifier, isFalse,
        reason: 'ComputedAtom should not extend ValueNotifier');
  });

  test('FieldAtom should still work correctly', () {
    final field = FieldAtom<int>(0, label: 'test');
    expect(field.value, 0);
    field.set(10);
    expect(field.value, 10);
  });
}
