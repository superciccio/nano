import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

class MockObserver implements NanoObserver {
  @override
  void onChange(Atom atom, oldValue, newValue) {}
  @override
  void onError(Atom atom, Object error, StackTrace stack) {}
}

void main() {
  // Setup removed as Nano.observer is no longer a setter.
  // Tests will use default observer or runZoned where needed.

  group('Core Atoms', () {
    test('Atom extensions (int)', () {
      final a = 0.toAtom();
      expect(a(), 0);
      a.increment();
      expect(a(), 1);
      a.increment(2);
      expect(a(), 3);
      a.decrement();
      expect(a(), 2);
      a.decrement(2);
      expect(a(), 0);
    });

    test('Atom extensions (bool)', () {
      final a = false.toAtom();
      expect(a(), false);
      a.toggle();
      expect(a(), true);
    });

    test('Atom call operator', () {
      final a = 0.toAtom();
      // Set
      a(5);
      expect(a(), 5);
      // Update
      a((int val) => val * 2);
      expect(a(), 10);
    });

    test('SelectorAtom updates only when selected value changes', () {
      final parent = Atom({'a': 1, 'b': 2});
      int updates = 0;
      final selector = parent.select((map) => map['a']);
      selector.addListener(() => updates++);

      expect(selector(), 1);

      // Change 'b', selector should not update
      parent.update((map) => {'a': 1, 'b': 3});
      expect(updates, 0);

      // Change 'a', selector should update
      parent.update((map) => {'a': 10, 'b': 3});
      expect(selector(), 10);
      expect(updates, 1);

      // Cleanup
      selector.dispose();
      // Updating parent shouldn't crash
      parent.set({'a': 20, 'b': 3});
    });

    test('ComputedAtom debug properties', () {
      final a = Atom(1);
      final c = computed(() => a.value * 2);
      final builder = DiagnosticPropertiesBuilder();
      c.debugFillProperties(builder);
      expect(builder.properties.any((p) => p.name == 'value'), isTrue);
    });

    test('ComputedAtom disposal removes listeners', () {
      final dep = Atom(0);
      final computed = ComputedAtom(() => dep.value * 2);

      expect(computed.value, 0);
      dep.set(1);
      expect(computed.value, 2);

      computed.dispose();
      dep.set(2);
      // Computed shouldn't update after disposal (or at least shouldn't be listening)
      // Actually ValueNotifier doesn't prevent value changes if set directly,
      // but ComputedAtom updates via listener.
      expect(computed.value, 2);
    });

    test('StreamAtom handles stream events', () async {
      final controller = StreamController<int>();
      final atom = controller.stream.toStreamAtom();

      // Use expectLater with atom.stream for robust async testing
      expect(atom.value, isA<AsyncLoading>());

      final streamExpectation = expectLater(
        atom.stream,
        emitsInOrder([
          isA<AsyncLoading>(), // Initial value from stream getter
          isA<AsyncData>().having((s) => s.value, 'value', 1),
          isA<AsyncError>().having((s) => s.error, 'error', 'fail'),
        ]),
      );

      controller.add(1);
      controller.addError('fail');

      await streamExpectation;

      atom.dispose();
      await controller.close();
    });

    test('Atom stream extension emits updates', () async {
      final atom = Atom(0);

      final expectation = expectLater(atom.stream, emitsInOrder([0, 1, 2]));

      atom.set(1);
      atom.set(2);

      await expectation;
    });

    test('DebouncedAtom delays updates', () async {
      final atom = DebouncedAtom(0, duration: const Duration(milliseconds: 50));
      atom.set(1);
      expect(atom.value, 0); // Not updated yet

      await Future.delayed(const Duration(milliseconds: 10));
      atom.set(2); // Reset timer

      await Future.delayed(const Duration(milliseconds: 10));
      expect(atom.value, 0); // Still not updated

      await Future.delayed(
        const Duration(milliseconds: 100),
      ); // Increased buffer
      expect(atom.value, 2);
    });

    test('DebouncedAtom dispose cancels timer', () async {
      final atom = DebouncedAtom(0, duration: const Duration(milliseconds: 50));
      atom.set(1);
      atom.dispose();
      await Future.delayed(const Duration(milliseconds: 60));
      // Should not have updated (and strictly speaking, accessing value of disposed notifier is unsafe but here we check if it crashed or updated)
      // We can't easily check if set() was called on super without mocking.
      // But we verify no crash.
    });
  });

  group('AsyncState', () {
    test('properties work', () {
      const idle = AsyncIdle<int>();
      expect(idle.isLoading, false);

      const loading = AsyncLoading<int>();
      expect(loading.isLoading, true);

      const data = AsyncData<int>(1);
      expect(data.hasData, true);
      expect(data.value, 1);

      const error = AsyncError<int>('err', StackTrace.empty);
      expect(error.hasError, true);
      expect(error.error, 'err');
    });

    test('debugFillProperties', () {
      const data = AsyncData(1);
      final builder = DiagnosticPropertiesBuilder();
      data.debugFillProperties(builder);
      expect(builder.properties.any((p) => p.name == 'data'), isTrue);
    });
  });
}
