import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

void main() {
  group('NanoLogic', () {
    test('initialize calls onInit once', () {
      final logic = _MockLogic();
      expect(logic.onInitCalled, false);

      logic.initialize(null);
      expect(logic.onInitCalled, true);
      expect(logic.onInitCallCount, 1);

      // Call again should not trigger onInit
      logic.initialize(null);
      expect(logic.onInitCallCount, 1);
    });

    test('bindStream updates atom and handles lifecycle', () async {
      final controller = StreamController<int>();
      final atom = Atom(0);
      final logic = _MockLogic();

      logic.bindStream(controller.stream, atom);

      controller.add(10);
      await Future.delayed(Duration.zero);
      expect(atom.value, 10);

      logic.dispose();
      controller.add(20);
      await Future.delayed(Duration.zero);
      expect(atom.value, 10); // Should NOT have updated after dispose

      await controller.close();
    });

    test('bindStream handles errors via Nano.observer', () async {
      final controller = StreamController<int>();
      final atom = Atom(0, label: 'error_atom');
      final logic = _MockLogic();

      final observer = _MockObserver();
      final config = NanoConfig(observer: observer);

      // Run bindStream in zoned context so it picks up the observer
      runZoned(() {
        logic.bindStream(controller.stream, atom);
      }, zoneValues: {#nanoConfig: config});

      controller.addError('test error');
      await Future.delayed(Duration.zero);

      expect(observer.lastErrorLabel, 'error_atom');
      expect(observer.lastError.toString(), 'test error');

      await controller.close();
    });
  });
}

class _MockLogic extends NanoLogic<dynamic> {
  bool onInitCalled = false;
  int onInitCallCount = 0;

  @override
  void onInit(dynamic params) {
    onInitCalled = true;
    onInitCallCount++;
  }
}

class _MockObserver implements NanoObserver {
  String? lastErrorLabel;
  Object? lastError;

  @override
  void onChange(Atom atom, oldValue, newValue) {}

  @override
  void onError(Atom atom, Object error, StackTrace stack) {
    lastErrorLabel = atom.label;
    lastError = error;
  }
}
