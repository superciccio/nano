import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

void main() {
  group('AsyncAtom Error Handling', () {
    test('track catches exception and updates state to AsyncError', () async {
      final atom = AsyncAtom<String>();
      final exception = Exception('something went wrong');

      // We don't await track here because it handles the future internally
      // but we wait for the microtasks to complete.
      await atom.track(Future.error(exception));

      expect(atom.value, isA<AsyncError<String>>());
      final errorState = atom.value as AsyncError<String>;
      expect(errorState.error, exception);
      expect(atom.value.hasError, isTrue);
      expect(atom.value.isLoading, isFalse);
    });

    test('track notifies NanoObserver on error', () async {
      final observer = _CapturingObserver();
      final config = NanoConfig(observer: observer);

      final atom = AsyncAtom<String>(label: 'error_atom');
      final exception = Exception('boom');

      await runZoned(() => atom.track(Future.error(exception)),
          zoneValues: {#nanoConfig: config});

      expect(observer.lastErrorLabel, 'error_atom');
      expect(observer.lastError, exception);
    });
  });

  group('Registry Error Handling', () {
    test(
      'get throws NanoException with helpful message for missing service',
      () {
        final registry = Registry();

        expect(
          () => registry.get<int>(),
          throwsA(
            isA<NanoException>().having(
              (e) => e.message,
              'message',
              contains("Service of type 'int' not found"),
            ),
          ),
        );
      },
    );
  });
}

class _CapturingObserver extends NanoObserver {
  String? lastErrorLabel;
  Object? lastError;

  @override
  void onChange(Atom atom, dynamic oldValue, dynamic newValue) {}

  @override
  void onError(Atom atom, Object error, StackTrace stack) {
    lastErrorLabel = atom.label;
    lastError = error;
  }
}
