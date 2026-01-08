import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

void main() {
  group('Atom', () {
    test('initial value is set correctly', () {
      final atom = Atom(10);
      expect(atom.value, 10);
    });

    test('set updates value and notifies listeners', () {
      final atom = Atom(10);
      int callCount = 0;
      atom.addListener(() => callCount++);

      atom.set(20);
      expect(atom.value, 20);
      expect(callCount, 1);
    });

    test('update helper works', () {
      final atom = Atom(10);
      atom.update((v) => v + 5);
      expect(atom.value, 15);
    });

    test('set does nothing if value is same', () {
      final atom = Atom(10);
      int callCount = 0;
      atom.addListener(() => callCount++);

      atom.set(10);
      expect(callCount, 0);
    });
  });

  group('ComputedAtom', () {
    test('computes initial value', () {
      final a = Atom(2);
      final b = Atom(3);
      final computed = ComputedAtom([a, b], () => a.value * b.value);

      expect(computed.value, 6);
    });

    test('updates when dependencies change', () {
      final a = Atom(2);
      final b = Atom(3);
      final computed = ComputedAtom([a, b], () => a.value * b.value);

      a.set(4);
      expect(computed.value, 12);

      b.set(5);
      expect(computed.value, 20);
    });

    test('notifies listeners only on value change', () {
      final a = Atom(2);
      // Logic that returns constant regardless of a
      final computed = ComputedAtom([a], () => 10);

      int callCount = 0;
      computed.addListener(() => callCount++);

      a.set(3);
      expect(callCount, 0); // Value stayed 10
    });

    test('dispose removes listeners from dependencies', () {
      final a = Atom(2);
      final computed = ComputedAtom([a], () => a.value * 2);

      computed.dispose();
      a.set(3);

      // We can't easily check internal listeners, but we verify it doesn't crash
      expect(computed.value, 4); // Should NOT have updated to 6
    });
  });

  group('AsyncAtom', () {
    test('initial state is Idle', () {
      final asyncAtom = AsyncAtom<int>();
      expect(asyncAtom.value, isA<AsyncIdle<int>>());
    });

    test('track updates state to Loading then Data', () async {
      final asyncAtom = AsyncAtom<int>();

      final future = Future.delayed(Duration(milliseconds: 10), () => 42);
      final trackFuture = asyncAtom.track(future);

      expect(asyncAtom.value, isA<AsyncLoading<int>>());

      await trackFuture;
      expect(asyncAtom.value, isA<AsyncData<int>>());
      expect((asyncAtom.value as AsyncData<int>).data, 42);
    });

    test('track updates state to Error on failure', () async {
      final asyncAtom = AsyncAtom<int>();

      final future = Future.delayed(
        Duration(milliseconds: 10),
        () => throw Exception('fail'),
      );
      await asyncAtom.track(future);

      expect(asyncAtom.value, isA<AsyncError<int>>());
      expect(
        (asyncAtom.value as AsyncError<int>).error.toString(),
        contains('fail'),
      );
    });
  });
}
