import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

void main() {
  group('AtomFamily', () {
    test('memoizes atoms by key', () {
      final family = AtomFamily<int, Atom<String>>((id) => Atom('User $id'));

      final user1 = family(1);
      final user1Again = family(1);
      final user2 = family(2);

      expect(user1, same(user1Again));
      expect(user1, isNot(same(user2)));
      expect(user1.value, 'User 1');
      expect(user2.value, 'User 2');
    });

    test('works with AsyncAtom', () async {
      final family = AtomFamily<int, AsyncAtom<String>>((id) {
        return AsyncAtom<String>(label: 'user_$id')
          ..track(Future.value('Data $id'));
      });

      final atom1 = family(1);
      expect(atom1.label, 'user_1');

      await Future.delayed(Duration.zero);
      expect(atom1.value.dataOrNull, 'Data 1');
    });

    test('remove() clears specific entry', () {
      int creations = 0;
      final family = AtomFamily<int, Atom<int>>((id) {
        creations++;
        return Atom(id);
      });

      final a1 = family(1);
      expect(creations, 1);

      family.remove(1);
      final a2 = family(1);
      expect(creations, 2);
      expect(a1, isNot(same(a2)));
    });

    test('clear() resets everything', () {
      final family = AtomFamily<int, Atom<int>>((id) => Atom(id));

      family(1);
      family(2);
      expect(family.keys.length, 2);

      family.clear();
      expect(family.keys, isEmpty);
    });

    test('exposes keys and values', () {
      final family = AtomFamily<int, Atom<int>>((id) => Atom(id));
      family(1);
      family(2);

      expect(family.keys, containsAll([1, 2]));
      expect(family.values.map((a) => a.value), containsAll([1, 2]));
    });
  });
}
