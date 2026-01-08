import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';
import 'package:nano_example/counter/counter_example.dart';

void main() {
  group('CounterLogic', () {
    late CounterLogic logic;

    setUp(() {
      Nano.init(); // Initialize Nano for debug logs if needed
      logic = CounterLogic();
    });

    tearDown(() {
      logic.dispose();
    });

    test('initial state is correct', () {
      expect(logic.count.value, 0);
      expect(logic.history.value, isEmpty);
      expect(logic.isEven.value, isTrue);
      expect(logic.doubleCount.value, 0);
    });

    test('increment updates count, history, and computed', () {
      logic.increment();

      expect(logic.count.value, 1);
      expect(logic.history.value, [0]);
      expect(logic.isEven.value, isFalse);
      expect(logic.doubleCount.value, 2);

      logic.increment();

      expect(logic.count.value, 2);
      expect(logic.history.value, [0, 1]);
      expect(logic.isEven.value, isTrue);
      expect(logic.doubleCount.value, 4);
    });

    test('decrement updates count and history', () {
      logic.decrement();

      expect(logic.count.value, -1);
      expect(logic.history.value, [0]);
    });

    test('reset clears count but keeps history trail', () {
      logic.increment(); // 1
      logic.increment(); // 2
      logic.reset();

      expect(logic.count.value, 0);
      expect(logic.history.value, [0, 1, 2]);
    });
  });
}
