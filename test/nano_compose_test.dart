import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

class MockLogic extends NanoLogic<void> {
  final count = Atom(0);
  final isValid = Atom(false);
  final field = FieldAtom("");

  void increment() => count.update((v) => v + 1);
}

void main() {
  testWidgets('NanoCompose functional syntax verification', (tester) async {
    final logic = MockLogic();

    await tester.pumpWidget(
      Scope(
        modules: [logic],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              final l = context.logic<MockLogic>();

              return NanoPage(
                title: 'Test',
                body: NanoStack(
                  layout: const NanoLayout(spacing: 20, scrollable: true),
                  children: [
                    l.count.text(format: (v) => 'Count: $v').center(),
                    l.field.textField(label: 'Field'),
                    l.isValid.button('Action', onPressed: () {}),
                    'Clear'.textButton(onPressed: () {}),
                  ],
                ).padding(),
              );
            },
          ),
        ),
      ),
    );

    // Initial check
    expect(find.text('Count: 0'), findsOneWidget);
    expect(find.text('Field'), findsOneWidget);

    // Verify button is disabled (isValid is false)
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    // Update state
    logic.increment();
    logic.isValid.set(true);
    await tester.pump();

    // Verify reactivity
    expect(find.text('Count: 1'), findsOneWidget);
    final buttonEnabled =
        tester.widget<FilledButton>(find.byType(FilledButton));
    expect(buttonEnabled.onPressed, isNotNull);

    // Verify layout (NanoStack spacing)
    // First child is at (10, 10 + AppBarHeight) due to padding
    // Second child should be 20px below first child's bottom
  });
}
