// ignore_for_file: suggest_nano_action
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

class TestLogic extends NanoLogic<void> {
  final count = Atom(0);
  final notifier = ValueNotifier<int>(0);

  void setupBind() {
    bind(notifier, () {
      count.value = notifier.value;
    });
  }
}

void main() {
  group('Nano v0.7.1 Features', () {
    group('AsyncAtom (Sticky Data)', () {
      test('should keep previous data by default during loading and error',
          () async {
        final atom = AsyncAtom<String>(keepPreviousData: true);
        final completer1 = Completer<String>();

        // 1. Start loading (no data yet)
        final future1 = atom.track(completer1.future);
        expect(atom.value, isA<AsyncLoading<String>>());
        expect(atom.value.dataOrNull, null);

        // 2. Resolve data
        completer1.complete('Hello');
        await future1;
        expect(atom.value, isA<AsyncData<String>>());
        expect(atom.value.dataOrNull, 'Hello');

        // 3. Start loading again (should keep 'Hello')
        final completer2 = Completer<String>();
        final future2 = atom.track(completer2.future);
        expect(atom.value, isA<AsyncLoading<String>>());
        expect(atom.value.dataOrNull, 'Hello');

        // 4. Fail (should keep 'Hello')
        completer2.completeError('Fail');
        try {
          await future2;
        } catch (_) {}

        expect(atom.value, isA<AsyncError<String>>());
        expect(atom.value.dataOrNull, 'Hello'); // Sticky!
        expect((atom.value as AsyncError).previousData, 'Hello');
      });

      test('should clear previous data correctly if keepPreviousData is false',
          () async {
        final atom = AsyncAtom<String>(keepPreviousData: false);
        final completer1 = Completer<String>();

        // 1. Load & Data
        atom.track(completer1.future);
        completer1.complete('Data');
        await Future.microtask(() {});
        expect(atom.value.dataOrNull, 'Data');

        // 2. Reload (should clear)
        final completer2 = Completer<String>();
        atom.track(completer2.future);

        expect(atom.value, isA<AsyncLoading<String>>());
        expect(atom.value.dataOrNull, null); // Cleared!
      });
    });

    group('NanoLogic.bind', () {
      test('should bind and unbind correctly', () {
        final logic = TestLogic();
        logic.initialize(null);
        logic.setupBind();

        // 1. Initial State
        expect(logic.count.value, 0);

        // 2. Update notifier -> Update atom
        logic.notifier.value = 10;
        expect(logic.count.value, 10);

        // 3. Dispose logic -> Should unbind
        logic.dispose();
        logic.notifier.value = 20;

        // Atom should NOT update (because logic is disposed, but also subscription cancelled)
        // If listener was still active, it would try to set a disposed atom or at least run.
        // We verify the side effect count didn't change (if we could check that easily).
        // Since count atom is likely disposed, setting it might throw or do nothing.
        // But more importantly, we want to ensure no errors happen.

        // Atom should NOT update because listener is removed
        expect(logic.count.value, 10);
      });
    });
  });
}
