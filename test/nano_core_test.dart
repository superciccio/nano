import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

class TestObserver extends NanoObserver {
  int changes = 0;
  @override
  void onChange(String label, oldValue, newValue) {
    changes++;
  }

  @override
  void onError(String label, Object error, StackTrace stack) {}
}

void main() {
  group('Atom', () {
    test('initial value is correct', () {
      final atom = Atom(0);
      expect(atom.value, 0);
    });

    test('set updates value and notifies observer', () {
      final observer = TestObserver();
      Nano.observer = observer;

      final atom = Atom(0);
      atom.set(1);

      expect(atom.value, 1);
      expect(observer.changes, 1);
    });

    test('update updates value and notifies observer', () {
      final observer = TestObserver();
      Nano.observer = observer;

      final atom = Atom(0);
      atom.update((value) => value + 1);

      expect(atom.value, 1);
      expect(observer.changes, 1);
    });

    test('callable updates value and notifies observer', () {
      final observer = TestObserver();
      Nano.observer = observer;

      final atom = Atom(0);
      atom(1);

      expect(atom.value, 1);
      expect(observer.changes, 1);
    });

    test('value setter updates value and notifies observer', () {
      final observer = TestObserver();
      Nano.observer = observer;

      final atom = Atom(0);
      atom.value = 1;

      expect(atom.value, 1);
      expect(observer.changes, 1);
    });
  });

  group('AtomIntExtension', () {
    test('increment updates value and notifies observer', () {
      final observer = TestObserver();
      Nano.observer = observer;

      final atom = Atom(0);
      atom.increment();

      expect(atom.value, 1);
      expect(observer.changes, 1);
    });

    test('decrement updates value and notifies observer', () {
      final observer = TestObserver();
      Nano.observer = observer;

      final atom = Atom(0);
      atom.decrement();

      expect(atom.value, -1);
      expect(observer.changes, 1);
    });
  });

  group('AtomBoolExtension', () {
    test('toggle updates value and notifies observer', () {
      final observer = TestObserver();
      Nano.observer = observer;

      final atom = Atom(false);
      atom.toggle();

      expect(atom.value, true);
      expect(observer.changes, 1);
    });
  });

  group('DebouncedAtom', () {
    test('value is not updated immediately', () {
      final atom = DebouncedAtom(0, duration: const Duration(milliseconds: 100));
      atom.set(1);
      expect(atom.value, 0);
    });

    test('value is updated after duration', () async {
      final atom = DebouncedAtom(0, duration: const Duration(milliseconds: 100));
      atom.set(1);
      await Future.delayed(const Duration(milliseconds: 150));
      expect(atom.value, 1);
    });

    test('timer is reset if set is called again', () async {
      final atom = DebouncedAtom(0, duration: const Duration(milliseconds: 100));
      atom.set(1);
      await Future.delayed(const Duration(milliseconds: 50));
      atom.set(2);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(atom.value, 0);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(atom.value, 2);
    });

    test('dispose cancels timer', () async {
      final atom = DebouncedAtom(0, duration: const Duration(milliseconds: 100));
      atom.set(1);
      atom.dispose();
      await Future.delayed(const Duration(milliseconds: 150));
      expect(atom.value, 0);
    });
  });
}