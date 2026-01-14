import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rick_and_morty/main.dart';
import 'package:rick_and_morty/rm_logic.dart';
import 'package:nano/nano.dart';

// Mock Logic
class MockRMLogic extends RMLogic {
  @override
  Future<void> fetchCharacters() async {
    await characters.track(() async {
      await Future.delayed(const Duration(milliseconds: 50));
      return [
        Character(
          id: 1,
          name: 'Rick Sanchez',
          status: 'Alive',
          species: 'Human',
          image: 'https://example.com/rick.png',
          episodeUrls: ['https://rickandmortyapi.com/api/episode/1'],
        ),
      ];
    }());
  }

  @override
  Future<void> fetchEpisodes(Character character) async {
    await character.episodes.track(() async {
      await Future.delayed(const Duration(milliseconds: 50));
      return [
        Episode(name: 'Pilot', episodeCode: 'S01E01', airDate: 'Dec 2, 2013'),
      ];
    }());
  }
}

void main() {
  testWidgets('R&M: Select character and load episodes', (WidgetTester tester) async {
    // Inject Mock via NanoView
    await tester.pumpWidget(
      NanoView(
        create: (_) => MockRMLogic(),
        builder: (ctx, logic) => const MaterialApp(home: CharacterListScreen()),
      ),
    );

    // Initial load
    await tester.pump(); // Start fetchCharacters
    await tester.pump(const Duration(milliseconds: 100)); // Finish fetch

    expect(find.text('Rick Sanchez'), findsOneWidget);

    // Tap character
    await tester.tap(find.text('Rick Sanchez'));
    await tester.pump(); // Select and start fetchEpisodes

    // Check loading in detail view
    // The detail view appears immediately when `selected` is not null
    expect(find.text('EPISODES APPEARANCES'), findsOneWidget);

    // Wait for episodes
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Pilot'), findsOneWidget);
    expect(find.text('S01E01'), findsOneWidget);
  });
}
