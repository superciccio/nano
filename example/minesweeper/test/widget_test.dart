import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';
import 'package:minesweeper/main.dart';
import 'package:minesweeper/minesweeper_logic.dart';

void main() {
  testWidgets('Minesweeper smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      Scope(
        modules: [
          NanoLazy((_) => MinesweeperLogic()),
        ],
        child: const MinesweeperApp(),
      ),
    );

    // Verify Title
    expect(find.text('Nano Minesweeper'), findsOneWidget);
    
    // Verify Grid Cells
    // Default 9x9? No, logic defaults 10x10.
    // Let's check logic default: 10x10.
    // 100 cells.
    // Finding by type GestureDetector is ambiguous but should find at least one.
    expect(find.byType(GestureDetector), findsAtLeastNWidgets(10));

    // Interact
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump();

    // Reset
    await tester.tap(find.byIcon(Icons.sentiment_satisfied));
    await tester.pump();
  });
}
