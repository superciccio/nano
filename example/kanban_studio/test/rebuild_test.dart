import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';
import 'package:kanban_studio/logic.dart';
import 'package:kanban_studio/main.dart';

// Local wrapper removed in favor of NanoBuildSpy

void main() {
  testWidgets('Verify surgical rebuilds in Kanban Studio', (tester) async {
    final logic = KanbanLogic();

    // We can't easily inject a tracker INSIDE the TaskCard without modifying main.dart
    // heavily or using a custom builder.
    // However, we recently observed that typing in a card logic-driven field
    // does NOT rebuild the card widget itself because they bind to FieldAtoms directly
    // within the children (TextField).

    // Let's verifying the "Board Page" rebuilds.
    int pageRebuilds = 0;

    await tester.pumpWidget(
      Scope(
        modules: [logic],
        child: MaterialApp(
          home: NanoBuildSpy(
            label: "BoardPage",
            onBuild: (c) => pageRebuilds = c,
            child: const KanbanBoardPage(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(pageRebuilds, 1, reason: "Initial render");

    // 1. Toggle Search
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    // The KanbanBoardPage itself (the scaffold wrapper) might rebuild or not
    // depending on where the watch is.
    // We moved the watch INSIDE the NanoPage parameters.
    // So NanoPage rebuilds?
    // KanbanBoardPage is a StatelessWidget that returns NanoView.
    // NanoView builder returns NanoPage.
    // Logic.isSearchOpen changes.
    // NanoView has rebuildOnUpdate: false.
    // So the `builder` of NanoView is NOT called again.
    // BUT, we have `logic.isSearchOpen.watch(...)` inside the parameters?
    // NO, we have `NanoPage(title: logic.isSearchOpen.watch(...))`.
    // Wait, `watch` returns a Widget.
    // `NanoPage` constructor takes `dynamic title`.
    // If we pass a Widget to `title`, NanoPage puts it in AppBar.
    // That Widget IS the Watch widget.
    // So `KanbanBoardPage` does NOT rebuild.
    // `NanoView` does NOT rebuild.
    // `NanoPage` does NOT rebuild.
    // Only the `Watch` widget inside the AppBar rebuilds its child (the Text).

    expect(pageRebuilds, 1, reason: "Toggling search should be surgical");

    // 2. Type in search
    // There are many TextFields (one per task card + search bar).
    // The search bar has a specific hint "Search tasks...".
    final searchField = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == "Search tasks...");

    await tester.enterText(searchField, "mod");
    await tester.pumpAndSettle();

    // Typing updates `searchQuery`.
    // `filteredTasks` updates.
    // Columns watch `filteredTasks`.
    // Columns rebuild their ListViews.
    // But `KanbanBoardPage` (the root of this screen) should NOT rebuild.

    expect(pageRebuilds, 1, reason: "Searching should be surgical");

    // 3. Close search
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(pageRebuilds, 1, reason: "Closing search should be surgical");

    // 4. Add a new Task (Surgical Update)
    // Find the 'Add' button in the 'TODO' column.
    // TODO is the 2nd column (index 1 in TaskStatus.values).
    final addIcon = find.byIcon(Icons.add).at(1);
    await tester.tap(addIcon);
    await tester.pumpAndSettle();

    // Verify "New Task" appears
    expect(find.text("New Task"), findsOneWidget,
        reason: "New task should appear in UI");

    // Verify BoardPage did NOT rebuild (still surgical)
    expect(pageRebuilds, 1,
        reason: "Adding a task should not rebuild the Board Page");

    // 5. Delete the task
    // Find the delete icon for the new task. It's the last one in the list usually.
    // Easier: find the delete button that is a descendant of the Column containing the "New Task" TextField.
    final deleteIcon = find.descendant(
        of: find
            .ancestor(
                of: find.widgetWithText(TextField, "New Task"),
                matching: find.byType(
                    Container) // The task card container or immediate parent
                )
            .first,
        matching: find.byIcon(Icons.delete_outline));

    // Scroll to it if off-screen (Kanban board is wide)
    await tester.scrollUntilVisible(deleteIcon, 500,
        scrollable: find.byType(Scrollable).first);

    await tester.tap(deleteIcon);
    await tester.pumpAndSettle();

    expect(find.text("New Task"), findsNothing,
        reason: "Task should be deleted");
    expect(pageRebuilds, 1,
        reason: "Deleting a task should not rebuild the Board Page");
  });
}
