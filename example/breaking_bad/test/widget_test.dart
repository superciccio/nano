import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';
import '../lib/breaking_bad_logic.dart';
import 'package:nano/nano.dart';

// Mock Service
class MockQuoteService implements QuoteService {
  @override
  Future<Quote> fetchQuote() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return Quote(quote: 'Better Call Saul!', author: 'Saul Goodman');
  }
}

void main() {
  testWidgets('Global Counter updates when Quote is fetched', (WidgetTester tester) async {
    // "Gold Standard": Use Scope to inject mocks
    await tester.pumpWidget(
      Scope(
        modules: [
          // Override the service with our mock
          NanoFactory<QuoteService>((_) => MockQuoteService()),
          // Use real logic, it's what we are testing integration with
          NanoLazy((_) => StatsLogic()),
        ],
        child: const BreakingBadApp(),
      ),
    );

    // Initial state: No quotes yet
    expect(find.text('GET QUOTE'), findsOneWidget);
    
    // Counter should be empty/invisible initially
    expect(find.text('⚖️ 1'), findsNothing);

    // Trigger action
    await tester.tap(find.text('GET QUOTE'));
    await tester.pump(); // Start async action (loading)
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    await tester.pump(const Duration(milliseconds: 100)); // Finish async

    // Verify UI update
    expect(find.text('"Better Call Saul!"'), findsOneWidget);
    expect(find.text('- Saul Goodman'), findsOneWidget);

    // Verify Logic Integration (Counter in AppBar)
    // "Saul Goodman" contains "Saul", so saulCount should increment.
    expect(find.text('⚖️ 1'), findsOneWidget);
  });
}