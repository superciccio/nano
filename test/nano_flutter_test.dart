import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

void main() {
  group('Scope', () {
    testWidgets('provides dependencies to descendants', (tester) async {
      final service = MockService();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Scope(modules: [service], child: _ScopeChecker()),
        ),
      );

      expect(find.text('found'), findsOneWidget);
    });

    testWidgets('throws NanoException when Scope is missing', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            try {
              Scope.of(context);
              return const Text('success', textDirection: TextDirection.ltr);
            } on NanoException catch (e) {
              return Text(e.message, textDirection: TextDirection.ltr);
            }
          },
        ),
      );

      expect(
        find.textContaining('No Scope found in the widget tree'),
        findsOneWidget,
      );
    });
  });

  group('NanoView', () {
    testWidgets('creates logic and calls onInit', (tester) async {
      final logic = _MockLogic();
      await tester.pumpWidget(
        Scope(
          modules: [],
          child: NanoView<_MockLogic, dynamic>(
            create: (reg) => logic,
            params: null,
            builder: (context, logic) => Text(
              logic.onInitCalled ? 'inited' : 'nope',
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
      );

      expect(find.text('inited'), findsOneWidget);
    });

    testWidgets('NanoView disposes logic by default', (tester) async {
      final logic = _MockLogic();
      await tester.pumpWidget(
        Scope(
          modules: [],
          child: NanoView<_MockLogic, dynamic>(
            create: (reg) => logic,
            builder: (context, logic) => const SizedBox(),
          ),
        ),
      );

      // Trigger disposal by pumping a different widget
      await tester.pumpWidget(const SizedBox());

      expect(logic.isDisposed, true);
    });

    testWidgets('NanoView does NOT dispose logic if autoDispose: false',
        (tester) async {
      final logic = _MockLogic();
      await tester.pumpWidget(
        Scope(
          modules: [],
          child: NanoView<_MockLogic, dynamic>(
            create: (reg) => logic,
            autoDispose: false,
            builder: (context, logic) => const SizedBox(),
          ),
        ),
      );

      // Trigger disposal by pumping a different widget
      await tester.pumpWidget(const SizedBox());

      expect(logic.isDisposed, false);
    });

    testWidgets('rebuilds when logic notifies listeners', (tester) async {
      final logic = _MockLogic();
      // Logic status is loading by default, set to success for this test
      logic.status.set(NanoStatus.success);

      await tester.pumpWidget(
        Scope(
          modules: [],
          child: NanoView<_MockLogic, dynamic>(
            create: (reg) => logic,
            params: null,
            builder: (context, logic) =>
                Text('count: ${logic.count}', textDirection: TextDirection.ltr),
          ),
        ),
      );

      expect(find.text('count: 0'), findsOneWidget);

      logic.increment();
      await tester.pump();
      expect(find.text('count: 1'), findsOneWidget);
    });

    testWidgets('throws exception when Scope is missing', (tester) async {
      // Build a test app that our exception should bubble up through
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: NanoView<_MockLogic, void>(
          create: (_) => _MockLogic(),
          builder: (_, _) => const Text('Success'),
        ),
      ));

      // The exception should be a NanoException
      expect(tester.takeException(), isA<NanoException>());
    });
  });

  group('Watch', () {
    testWidgets('rebuilds surgically when atom changes', (tester) async {
      final atom = Atom(0);
      int buildCount = 0;

      await tester.pumpWidget(
        Watch(
          atom,
          builder: (context, value) {
            buildCount++;
            return Text('value: $value', textDirection: TextDirection.ltr);
          },
        ),
      );

      expect(find.text('value: 0'), findsOneWidget);
      expect(buildCount, 1);

      atom.set(1);
      await tester.pump();
      expect(find.text('value: 1'), findsOneWidget);
      expect(buildCount, 2);
    });

    testWidgets('.watch() extension rebuilds surgically', (tester) async {
      final atom = Atom(0);
      int buildCount = 0;

      await tester.pumpWidget(
        atom.watch(
          (context, value) {
            buildCount++;
            return Text('value: $value', textDirection: TextDirection.ltr);
          },
        ),
      );

      expect(find.text('value: 0'), findsOneWidget);
      expect(buildCount, 1);

      atom.set(1);
      await tester.pump();
      expect(find.text('value: 1'), findsOneWidget);
      expect(buildCount, 2);
    });
  });

  group('AsyncAtomWidgetExtension', () {
    testWidgets('.when() handles states correctly', (tester) async {
      final asyncAtom = AsyncAtom<String>();

      Widget buildTestWidget() {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: asyncAtom.when(
            idle: (context) => const Text('idle'),
            loading: (context) => const Text('loading'),
            data: (context, data) => Text('data: $data'),
            error: (context, error) => Text('error: $error'),
          ),
        );
      }

      // Initial state is Idle
      await tester.pumpWidget(buildTestWidget());
      expect(find.text('idle'), findsOneWidget);

      // Loading
      asyncAtom.set(const AsyncLoading());
      await tester.pump();
      expect(find.text('loading'), findsOneWidget);

      // Data
      asyncAtom.set(const AsyncData('test'));
      await tester.pump();
      expect(find.text('data: test'), findsOneWidget);

      // Error
      asyncAtom.set(AsyncError('fail', StackTrace.empty));
      await tester.pump();
      expect(find.text('error: fail'), findsOneWidget);
    });

    testWidgets('.when() uses loading for idle if idle not provided',
        (tester) async {
      final asyncAtom = AsyncAtom<String>();

      Widget buildTestWidget() {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: asyncAtom.when(
            // No idle builder provided
            loading: (context) => const Text('loading'),
            data: (context, data) => Text('data: $data'),
            error: (context, error) => Text('error: $error'),
          ),
        );
      }

      // Initial state is Idle, should fall back to loading
      await tester.pumpWidget(buildTestWidget());
      expect(find.text('loading'), findsOneWidget);
    });
  });

  testWidgets('context.read<T>() works', (tester) async {
    final logic = _MockLogic();
    await tester.pumpWidget(
      Scope(
        modules: [logic],
        child: Builder(
          builder: (context) {
            final l = context.read<_MockLogic>();
            return Text(
              'found: ${l.runtimeType}',
              textDirection: TextDirection.ltr,
            );
          },
        ),
      ),
    );

    expect(find.text('found: _MockLogic'), findsOneWidget);
  });

  group('WatchMany', () {
    testWidgets('tuple 2 watches rebuild when either changes', (tester) async {
      final a1 = Atom(1);
      final a2 = Atom(2);

      await tester.pumpWidget(
        (a1, a2).watch((context, v1, v2) {
          return Text('$v1-$v2', textDirection: TextDirection.ltr);
        }),
      );

      expect(find.text('1-2'), findsOneWidget);

      a1.set(10);
      await tester.pump();
      expect(find.text('10-2'), findsOneWidget);

      a2.set(20);
      await tester.pump();
      expect(find.text('10-20'), findsOneWidget);
    });

    testWidgets('tuple 3 watches rebuild when any changes', (tester) async {
      final a1 = Atom(1);
      final a2 = Atom(2);
      final a3 = Atom(3);

      await tester.pumpWidget(
        (a1, a2, a3).watch((context, v1, v2, v3) {
          return Text('$v1-$v2-$v3', textDirection: TextDirection.ltr);
        }),
      );

      expect(find.text('1-2-3'), findsOneWidget);

      a3.set(30);
      await tester.pump();
      expect(find.text('1-2-30'), findsOneWidget);
    });
  });

  group('NanoView builders', () {
    testWidgets('shows loading builder when status is loading', (tester) async {
      final logic = _MockLogic();
      logic.status.set(NanoStatus.loading);

      await tester.pumpWidget(
        Scope(
          modules: [],
          child: NanoView<_MockLogic, dynamic>(
            create: (reg) => logic,
            loading: (context) => const Text('Loading...', textDirection: TextDirection.ltr),
            builder: (context, logic) => const Text('Content', textDirection: TextDirection.ltr),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
      expect(find.text('Content'), findsNothing);
    });

    testWidgets('shows empty builder when status is empty', (tester) async {
      final logic = _MockLogic();
      logic.status.set(NanoStatus.empty);

      await tester.pumpWidget(
        Scope(
          modules: [],
          child: NanoView<_MockLogic, dynamic>(
            create: (reg) => logic,
            empty: (context) => const Text('Empty', textDirection: TextDirection.ltr),
            builder: (context, logic) => const Text('Content', textDirection: TextDirection.ltr),
          ),
        ),
      );

      expect(find.text('Empty'), findsOneWidget);
    });

    testWidgets('shows error builder when status is error', (tester) async {
      final logic = _MockLogic();
      logic.status.set(NanoStatus.error);
      logic.error.set('Something wrong');

      await tester.pumpWidget(
        Scope(
          modules: [],
          child: NanoView<_MockLogic, dynamic>(
            create: (reg) => logic,
            error: (context, err) => Text('Error: $err', textDirection: TextDirection.ltr),
            builder: (context, logic) => const Text('Content', textDirection: TextDirection.ltr),
          ),
        ),
      );

      expect(find.text('Error: Something wrong'), findsOneWidget);
    });

    testWidgets('NanoView create is called once', (tester) async {
      int createCount = 0;
      final logic = _MockLogic();

      await tester.pumpWidget(
        Scope(
          modules: [],
          child: NanoView<_MockLogic, dynamic>(
            create: (reg) {
              createCount++;
              return logic;
            },
            builder: (context, logic) => const SizedBox(),
          ),
        ),
      );

      expect(createCount, 1);

      await tester.pump();
      expect(createCount, 1);
    });
  });
}

class MockService {}

class _ScopeChecker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final registry = Scope.of(context);
    registry.get<MockService>();
    return Text('found', textDirection: TextDirection.ltr);
  }
}

class _MockLogic extends NanoLogic<dynamic> {
  bool onInitCalled = false;
  int count = 0;
  bool isDisposed = false;

  @override
  void onInit(dynamic params) {
    onInitCalled = true;
  }

  void increment() {
    count++;
    notifyListeners();
  }

  @override
  void dispose() {
    isDisposed = true;
    super.dispose();
  }
}
