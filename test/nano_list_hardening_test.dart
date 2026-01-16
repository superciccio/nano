import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

void main() {
  group('NanoList Hardening', () {
    test('Standard mutations trigger reactivity', () {
      final list = NanoList<String>();
      int reactionCount = 0;
      
      autorun(() {
        list.length; // Track length
        reactionCount++;
      });

      expect(reactionCount, 1);

      list.add('A');
      expect(reactionCount, 2);
      expect(list, ['A']);

      list.remove('A');
      expect(reactionCount, 3);
      expect(list, isEmpty);
    });

    test('Non-nullable type safety (Regression check)', () {
      // This failed previously because ListMixin.add sets length= which fills with nulls
      final list = NanoList<int>();
      expect(() => list.add(1), returnsNormally);
      expect(() => list.addAll([2, 3, 4]), returnsNormally);
      expect(list, [1, 2, 3, 4]);
    });

    test('Fine-grained index tracking', () {
      final list = NanoList<int>([10, 20]);
      int? valueAt0;
      int reactionCount = 0;

      autorun(() {
        valueAt0 = list[0];
        reactionCount++;
      });

      expect(valueAt0, 10);
      expect(reactionCount, 1);

      // Update index 1: reaction for index 0 should NOT run if Nano were extremely fine-grained,
      // but currently NanoList uses a single signal for simplicity. 
      // Let's verify current behavior.
      list[1] = 99;
      expect(reactionCount, 2); 

      list[0] = 100;
      expect(valueAt0, 100);
      expect(reactionCount, 3);
    });

    test('Sorting and Reordering', () {
      final list = NanoList<int>([3, 1, 2]);
      int reactionCount = 0;
      
      autorun(() {
        list.first;
        reactionCount++;
      });

      list.sort();
      expect(list, [1, 2, 3]);
      // sort() calls internal mutations multiple times.
      // Currently, it triggers multiple notifications.
      expect(reactionCount, greaterThan(1));

      final countBeforeShuffle = reactionCount;
      list.shuffle();
      expect(reactionCount, greaterThan(countBeforeShuffle));
    });

    test('Batching multiple operations', () {
      final list = NanoList<int>();
      int reactionCount = 0;
      
      autorun(() {
        list.length;
        reactionCount++;
      });

      Nano.batch(() {
        list.add(1);
        list.add(2);
        list.add(3);
      });

      // Should only trigger ONCE for the whole batch
      expect(reactionCount, 2);
      expect(list.length, 3);
    });

    test('Iterators track reads', () {
      final list = NanoList<int>([1, 2, 3]);
      int sum = 0;
      int reactionCount = 0;

      autorun(() {
        sum = list.fold(0, (a, b) => a + b);
        reactionCount++;
      });

      expect(sum, 6);
      
      list.add(4);
      expect(sum, 10);
      expect(reactionCount, 2);
    });
  });
}
