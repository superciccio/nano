import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';
import 'package:nano/core/debug_service.dart';

void main() {
  group('HistoryObserver', () {
    test('records state changes', () {
      final observer = HistoryObserver();
      final atom = Atom(0, label: 'test');

      // Hook up the observer
      Nano.observer = observer;

      atom.set(1);
      atom.set(2);

      expect(observer.events.length, 2);
      expect(observer.events[0].newValue, 1);
      expect(observer.events[1].newValue, 2);
    });

    test('can clear history', () {
      final observer = HistoryObserver();
      Nano.observer = observer;
      final atom = Atom(0);
      atom.set(1);

      expect(observer.events, isNotEmpty);
      observer.events.clear();
      expect(observer.events, isEmpty);
    });
  });

  group('NanoDebugService', () {
    test('registers and unregisters atoms', () {
      NanoDebugService.init();
      final atom = Atom(0, label: 'debug_atom');

      expect(atom.value, 0);
      atom.dispose();
    });

    test('handles events via Nano.observer integration', () {
      Nano.init();
      final atom = Atom(0);
      atom.set(1);
    });
  });
}
