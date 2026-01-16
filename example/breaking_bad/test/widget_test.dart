import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:breaking_bad/main.dart';
import 'package:breaking_bad/breaking_bad_logic.dart';
import 'package:nano/nano.dart';
import 'package:nano_test_utils/nano_test_utils.dart';

// Mock Service
class MockQuoteService implements QuoteService {
  @override
  Future<Quote> fetchQuote() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 50));
    return Quote(quote: 'Better Call Saul!', author: 'Saul Goodman');
  }
}

void main() {
  // ✅ CLEANER: Using nanoTestWidgets removes Scope boilerplate
  nanoTestWidgets(
    'Global Counter updates when Quote is fetched (Modern Style)',
    overrides: [
      // Override the service with our mock
      NanoFactory<QuoteService>((_) => MockQuoteService()),
      // Use real logic
      NanoLazy((_) => StatsLogic()),
    ],
    builder: () => const BreakingBadApp(),
    verify: (tester) async {
      // Initial state
      expect(find.text('GET QUOTE'), findsOneWidget);
      expect(find.text('⚖️ 1'), findsNothing);

      // Trigger action
      await tester.tap(find.text('GET QUOTE'));
      
      // ✅ RELIABLE: pumpSettled auto-waits for Nano's async logic to finish
      // No more manual Duration(milliseconds: 100) hacks!
      await tester.pumpSettled();

      // Verify UI update
      expect(find.text('"Better Call Saul!"'), findsOneWidget);
      expect(find.text('- Saul Goodman'), findsOneWidget);

      // ✅ STATE-DRIVEN FINDING: 
      // Verify that the UI is actually watching the correct atom.
      // This is more robust than just checking for the string '⚖️ 1'.
      final statsLogic = tester.read<StatsLogic>();
      expect(find.atom(statsLogic.saulCount), findsOneWidget);
      expect(statsLogic.saulCount.value, 1);
      
      // Verify Logic Integration (Counter in AppBar)
      expect(find.text('⚖️ 1'), findsOneWidget);
    },
  );
}
