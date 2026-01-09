import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';
import 'package:nano_example/search/search_example.dart';
import 'package:nano_example/shopping/shopping_example.dart';

void main() {
  group('SearchPage', () {
    testWidgets('renders initial state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scope(
            modules: [SearchLogic(SearchService())],
            child: const SearchPage(),
          ),
        ),
      );

      expect(find.text('Async Search'), findsOneWidget);
      expect(find.text('Type to search...'), findsOneWidget);
    });

    testWidgets('searches and shows results', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scope(
            modules: [SearchLogic(SearchService())],
            child: const SearchPage(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'apple');
      await tester.pump(); // Update text
      await tester.pump(const Duration(milliseconds: 600)); // Debounce
      await tester.pump(const Duration(milliseconds: 1100)); // Service delay

      expect(find.text('Apple'), findsOneWidget);
    });

    testWidgets('shows error state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scope(
            modules: [SearchLogic(SearchService())],
            child: const SearchPage(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'error');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 1100));

      expect(find.textContaining('Error:'), findsOneWidget);
    });
  });

  group('ShoppingPage', () {
    testWidgets('adds and removes items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scope(
            modules: [ShoppingLogic()],
            child: const ShoppingPage(),
          ),
        ),
      );

      expect(find.text('Cart is empty'), findsOneWidget);

      // Add item
      await tester.tap(find.widgetWithIcon(IconButton, Icons.add_shopping_cart).first);
      await tester.pump();

      expect(find.text('Cart is empty'), findsNothing);
      // Quantity is '1', but badge also shows '1'.
      expect(find.text('1'), findsAtLeastNWidgets(1));

      // Increment
      await tester.tap(find.widgetWithIcon(IconButton, Icons.add).first);
      await tester.pump();
      expect(find.text('2'), findsAtLeastNWidgets(1));

      // Decrement
      await tester.tap(find.widgetWithIcon(IconButton, Icons.remove).first);
      await tester.pump();
      expect(find.text('1'), findsAtLeastNWidgets(1));

      // Remove
      await tester.tap(find.widgetWithIcon(IconButton, Icons.remove).first);
      await tester.pump();
      expect(find.text('Cart is empty'), findsOneWidget);
    });

    testWidgets('checkout clears cart', (tester) async {
        await tester.pumpWidget(
        MaterialApp(
          home: Scope(
            modules: [ShoppingLogic()],
            child: const ShoppingPage(),
          ),
        ),
      );

      await tester.tap(find.widgetWithIcon(IconButton, Icons.add_shopping_cart).first);
      await tester.pump();
      expect(find.text('Cart is empty'), findsNothing);

      await tester.tap(find.text('Checkout'));
      await tester.pump();
      expect(find.text('Cart is empty'), findsOneWidget);
    });
  });
}
