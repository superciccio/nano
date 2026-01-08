import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

void main() {
  group('NanoLogic', () {
    test('onInit is called', () {
      final logic = _MockLogic();
      expect(logic.onInitCalled, false);
      logic.onInit();
      expect(logic.onInitCalled, true);
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
      Nano.observer = observer;

      logic.bindStream(controller.stream, atom);

      controller.addError('test error');
      await Future.delayed(Duration.zero);

      expect(observer.lastErrorLabel, 'error_atom');
      expect(observer.lastError.toString(), 'test error');

      await controller.close();
    });
  });
}

class _MockLogic extends NanoLogic {
  bool onInitCalled = false;
  @override
  void onInit() {
    onInitCalled = true;
  }
}

class _MockObserver implements NanoObserver {
  String? lastErrorLabel;
  Object? lastError;

  @override
  void onChange(String label, oldValue, newValue) {}

  @override
  void onError(String label, Object error, StackTrace stack) {
    lastErrorLabel = label;
    lastError = error;
  }
}
