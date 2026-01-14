import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

class AsyncInitSideEffectLogic extends NanoLogic<void> {
  bool caughtSideEffectError = false;
  final atom = Atom(0, label: 'test_atom');

  @override
  void onInit(void params) {
    _runAsync();
  }

  Future<void> _runAsync() async {
    await Future.delayed(Duration.zero);
    try {
      atom.value = 1;
    } catch (e) {
      if (e.toString().contains('Side-effect Violation (Asynchronous)')) {
        caughtSideEffectError = true;
      } else {
        rethrow;
      }
    }
  }
}

class SyncInitSideEffectLogic extends NanoLogic<void> {
  Object? caughtError;
  final atom = Atom(0, label: 'test_atom');

  @override
  void onInit(void params) {
    try {
      atom.value = 1;
    } catch (e) {
      caughtError = e;
    }
  }
}

void main() {
  test(
      'onInit should throw Synchronous violation if state is updated during onInit',
      () {
    final logic = SyncInitSideEffectLogic();
    logic.initialize(null);
    expect(logic.caughtError.toString(),
        contains('Side-effect Violation (Synchronous)'));
  });

  test(
      'onInit should throw Asynchronous violation if state is updated after await',
      () async {
    final logic = AsyncInitSideEffectLogic();
    logic.initialize(null);

    // Wait for the async part of logic.onInit to run
    await Future.delayed(Duration(milliseconds: 10));

    expect(logic.caughtSideEffectError, true,
        reason: 'Should have caught Asynchronous Side-effect Violation');
  });

  test(
      'Registry.get should not throw but might warn (verified via code coverage) after await',
      () async {
    // This is hard to verify via automated test (requires intercepting debugPrint),
    // but we can ensure it doesn't crash.
    final registry = Registry();
    registry.register("hello");

    runZoned(() async {
      final ctx = NanoInitContext();
      ctx.invalidate(); // Simulate end of synchronous phase

      await runZoned(() async {
        final val = registry.get<String>();
        expect(val, "hello");
      }, zoneValues: {#nanoInitContext: ctx});
    });
  });
}
