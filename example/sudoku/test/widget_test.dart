import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';
import 'package:sudoku/main.dart';
import 'package:sudoku/sudoku_logic.dart';

void main() {
  testWidgets('Sudoku smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      Scope(
        modules: [
          NanoLazy((_) => SudokuLogic()),
        ],
        child: const SudokuApp(),
      ),
    );

    // Verify Title
    expect(find.text('Nano Sudoku'), findsOneWidget);
    
    // Verify Grid (81 cells)
    // Finding GestureDetector or Container might be ambiguous.
    // Finding empty cells vs filled cells.
    // Initial easy difficulty has ~30 holes, so ~51 numbers.
    // Let's just find the Numpad buttons 1-9
    for (var i = 1; i <= 9; i++) {
      expect(find.widgetWithText(ElevatedButton, '$i'), findsOneWidget);
    }

    // Test Interaction
    // 1. Find an empty cell (value 0, text '')
    // This is hard to find reliably with text '' without matching everything.
    
    // Let's just check Difficulty dropdown exists
    expect(find.text('EASY'), findsOneWidget);
    await tester.tap(find.text('EASY'));
    await tester.pumpAndSettle();
    expect(find.text('MEDIUM'), findsOneWidget);
    await tester.tap(find.text('MEDIUM').last);
    await tester.pumpAndSettle();
    expect(find.text('MEDIUM'), findsOneWidget);
  });
}
