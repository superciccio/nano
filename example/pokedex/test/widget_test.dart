import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';
import '../lib/pokedex_logic.dart';
import 'package:nano/nano.dart';

// Mock Service
class MockPokedexService implements PokedexService {
  @override
  Future<Pokemon> fetchPokemon(String name) async {
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate net

    if (name == 'pikachu') {
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
      throw 'Pokemon "$name" not found!';
    }
  }
}

void main() {
  testWidgets('Pokedex UI starts in idle state', (WidgetTester tester) async {
    await tester.pumpWidget(
      Scope(
        modules: [
          NanoFactory<PokedexService>((_) => MockPokedexService()),
        ],
        child: const PokedexApp(),
      ),
    );

    expect(find.text('Nano Pokedex'), findsOneWidget);
    expect(find.text('Search for a Pokemon to begin!'), findsOneWidget);
  });

  testWidgets('Search updates state and UI', (WidgetTester tester) async {
    await tester.pumpWidget(
      Scope(
        modules: [
          NanoFactory<PokedexService>((_) => MockPokedexService()),
        ],
        child: const PokedexApp(),
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
