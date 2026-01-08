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

  @override
  void onInit(dynamic params) {
    onInitCalled = true;
  }

  void increment() {
    count++;
    notifyListeners();
  }
}
