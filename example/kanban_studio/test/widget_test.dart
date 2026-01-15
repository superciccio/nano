// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:nano/nano.dart';
import 'package:kanban_studio/main.dart';
import 'package:kanban_studio/logic.dart';

void main() {
  testWidgets('Kanban studio smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      Scope(
        modules: [NanoLazy((_) => KanbanLogic())],
        child: const KanbanApp(),
      ),
    );

    // Verify that our header is present.
    expect(find.text('Nano Kanban Studio'), findsOneWidget);
  });
}
