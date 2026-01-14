import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex/main.dart';
import 'package:pokedex/pokedex_logic.dart';
import 'package:nano/nano.dart';

class MockPokedexLogic extends PokedexLogic {
  @override
  Future<void> findPokemon(String query) async {
    // Simulate finding pokemon by updating the AsyncAtom
    await pokemon.track(() async {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate net

      if (query == 'pikachu') {
        return Pokemon(
          id: 25,
          name: 'pikachu',
          height: 4,
          weight: 60,
          spriteUrl: 'https://example.com/pikachu.png',
          types: ['electric'],
          flavorText: 'Pika Pika!',
          isLegendary: false,
        );
      } else {
        throw 'Pokemon "$query" not found!';
      }
    }());
  }
}

void main() {
  testWidgets('Pokedex UI starts in idle state', (WidgetTester tester) async {
    await tester.pumpWidget(const PokedexApp());

    expect(find.text('Nano Pokedex'), findsOneWidget);
    expect(find.text('Search for a Pokemon to begin!'), findsOneWidget);
  });

  testWidgets('Search updates state and UI', (WidgetTester tester) async {
    final logic = MockPokedexLogic();

    await tester.pumpWidget(
      NanoView(
        create: (_) => logic, // Inject mock logic
        builder: (context, logic) {
          return MaterialApp(home: const PokedexHome());
        },
      ),
    );

    // Initial State
    expect(find.text('Search for a Pokemon to begin!'), findsOneWidget);

    // Enter text and submit
    await tester.enterText(find.byType(TextField), 'pikachu');
    await tester.testTextInput.receiveAction(TextInputAction.done);

    // Check loading
    await tester.pump(); // Start future (AsyncAtom transitions to loading immediately)
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Finish future
    await tester.pump(const Duration(milliseconds: 150));

    // Check Success
    expect(find.text('#25 PIKACHU'), findsOneWidget);
    expect(find.text('ELECTRIC'), findsOneWidget);
    expect(find.text('Pika Pika!'), findsOneWidget);
  });
}
