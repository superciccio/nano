import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

void main() {
  group('AtomListExtension', () {
    test('add updates list immutably', () {
      final atom = [1, 2].toAtom();
      final originalList = atom.value;

      atom.add(3);

      expect(atom.value, [1, 2, 3]);
      expect(atom.value, isNot(same(originalList)));
    });

    test('addAll updates list immutably', () {
      final atom = [1, 2].toAtom();
      atom.addAll([3, 4]);

      expect(atom.value, [1, 2, 3, 4]);
    });

    test('remove updates list immutably', () {
      final atom = [1, 2, 3].toAtom();
      atom.remove(2);

      expect(atom.value, [1, 3]);
    });

    test('clear updates list immutably', () {
      final atom = [1, 2].toAtom();
      atom.clear();

      expect(atom.value, isEmpty);
    });
  });

  group('AtomSetExtension', () {
    test('add updates set immutably', () {
      final atom = {1, 2}.toAtom();
      final originalSet = atom.value;

      atom.add(3);

      expect(atom.value, {1, 2, 3});
      expect(atom.value, isNot(same(originalSet)));
    });

    test('addAll updates set immutably', () {
      final atom = {1, 2}.toAtom();
      atom.addAll({3, 4});

      expect(atom.value, {1, 2, 3, 4});
    });

    test('remove updates set immutably', () {
      final atom = {1, 2, 3}.toAtom();
      atom.remove(2);

      expect(atom.value, {1, 3});
    });

    test('clear updates set immutably', () {
      final atom = {1, 2}.toAtom();
      atom.clear();

      expect(atom.value, isEmpty);
    });
  });

  group('AtomMapExtension', () {
    test('put updates map immutably', () {
      final atom = {'a': 1}.toAtom();
      final originalMap = atom.value;

      atom.put('b', 2);

      expect(atom.value, {'a': 1, 'b': 2});
      expect(atom.value, isNot(same(originalMap)));
    });

    test('putAll updates map immutably', () {
      final atom = {'a': 1}.toAtom();
      atom.putAll({'b': 2, 'c': 3});

      expect(atom.value, {'a': 1, 'b': 2, 'c': 3});
    });

    test('remove updates map immutably', () {
      final atom = {'a': 1, 'b': 2}.toAtom();
      atom.remove('a');

      expect(atom.value, {'b': 2});
    });

    test('clear updates map immutably', () {
      final atom = {'a': 1}.toAtom();
      atom.clear();

      expect(atom.value, isEmpty);
    });
  });
}
