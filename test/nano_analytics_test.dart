import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

// Mock Observer for testing
class MockObserver implements NanoObserver {
  final List<String> logs = [];

  @override
  void onChange(Atom atom, dynamic oldValue, dynamic newValue) {
    logs.add('onChange: ${atom.label ?? "NoLabel"} ($oldValue -> $newValue)');
    if (atom.meta.containsKey('analytics_event')) {
      logs.add('Analytics: ${atom.meta['analytics_event']}');
    }
  }

  @override
  void onError(Atom atom, Object error, StackTrace stack) {
    logs.add('onError: ${atom.label ?? "NoLabel"} ($error)');
  }
}

void main() {
  group('Analytics & Observer', () {
    late MockObserver mockObserver;
    late NanoObserver originalObserver;

    setUp(() {
      mockObserver = MockObserver();
      originalObserver = Nano.observer;
      Nano.observer = mockObserver;
    });

    tearDown(() {
      Nano.observer = originalObserver;
    });

    test('Atom transmits meta data to observer', () {
      final atom = Atom(0, label: 'counter', meta: {'analytics_event': 'counter_update'});

      atom.value = 1;

      expect(mockObserver.logs, contains('onChange: counter (0 -> 1)'));
      expect(mockObserver.logs, contains('Analytics: counter_update'));
    });

    test('CompositeObserver delegates to all observers', () {
      final observer1 = MockObserver();
      final observer2 = MockObserver();
      final composite = CompositeObserver([observer1, observer2]);

      Nano.observer = composite;

      final atom = Atom(0, label: 'test');
      atom.value = 1;

      expect(observer1.logs, contains('onChange: test (0 -> 1)'));
      expect(observer2.logs, contains('onChange: test (0 -> 1)'));
    });
  });

  group('Flutter Ergonomics', () {
    testWidgets('AtomBuilder rebuilds on change', (tester) async {
      final atom = Atom(0);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: AtomBuilder<int>(
            atom: atom,
            builder: (context, value) => Text('$value'),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      atom.value = 1;
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('AsyncAtomBuilder handles states', (tester) async {
      final atom = AsyncAtom<String>();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: AsyncAtomBuilder<String>(
            atom: atom,
            loading: (context) => const Text('Loading'),
            data: (context, data) => Text('Data: $data'),
            error: (context, error) => Text('Error: $error'),
          ),
        ),
      );

      // Initial state is Idle, which falls back to Loading if not provided
      expect(find.text('Loading'), findsOneWidget);

      // Loading
      atom.set(const AsyncLoading());
      await tester.pump();
      expect(find.text('Loading'), findsOneWidget);

      // Data
      atom.set(const AsyncData('Success'));
      await tester.pump();
      expect(find.text('Data: Success'), findsOneWidget);

      // Error
      atom.set(const AsyncError('Fail', StackTrace.empty));
      await tester.pump();
      expect(find.text('Error: Fail'), findsOneWidget);
    });
  });
}
