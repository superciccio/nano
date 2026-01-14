import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:nano/nano.dart';

// -----------------------------------------------------------------------------
// Models
// -----------------------------------------------------------------------------
class Episode {
  final String name;
  final String episodeCode;
  final String airDate;

  Episode({required this.name, required this.episodeCode, required this.airDate});
}

class Character {
  final int id;
  final String name;
  final String status;
  final String species;
  final String image;
  final List<String> episodeUrls;

  // Nested Fetched Data: Use AsyncAtom for episodes
  // This allows each character to independently manage its episodes loading state
  final episodes = AsyncAtom<List<Episode>>(label: 'episodes');

  Character({
    required this.id,
    required this.name,
    required this.status,
    required this.species,
    required this.image,
    required this.episodeUrls,
  });
}

// -----------------------------------------------------------------------------
// Logic
// -----------------------------------------------------------------------------
class RMLogic extends NanoLogic<void> {
  // Main List State
  final characters = AsyncAtom<List<Character>>(label: 'characters');

  final selectedCharacter = Atom<Character?>(null, label: 'selected');
  final page = Atom<int>(1, label: 'page');

  Future<void> fetchCharacters() async {
    // We want to append if it's not the first page, but AsyncAtom replaces value.
    // So for pagination, we handle it slightly differently or merge.
    // For simplicity in this demo, let's just replace or handle the merge inside track.

    // If we are loading more, we don't want to clear existing data.
    // AsyncAtom supports sticky data, so the UI will show previous data while loading.

    // However, we need to know if we are appending.
    // Let's assume simple pagination where we append.

    await characters.track(() async {
      final currentPage = page.value;

      final response = await http.get(
        Uri.parse('https://rickandmortyapi.com/api/character/?page=$currentPage'),
      );

      final data = json.decode(response.body);
      final results = data['results'] as List;

      final newChars = results.map((c) => Character(
        id: c['id'],
        name: c['name'],
        status: c['status'],
        species: c['species'],
        image: c['image'],
        episodeUrls: List<String>.from(c['episode']),
      )).toList();

      page.update((p) => p + 1);

      // Merge with existing if we have them
      final currentList = characters.value.dataOrNull ?? [];
      return [...currentList, ...newChars];
    }());
  }

  // Nested Fetch: Get episodes for a specific character
  Future<void> fetchEpisodes(Character character) async {
    // If we already have data, don't refetch (basic cache)
    if (character.episodes.value.hasData) return;

    await character.episodes.track(() async {
      // API supports batch fetch: https://rickandmortyapi.com/api/episode/1,2,3
      final ids = character.episodeUrls.map((url) {
        final uri = Uri.parse(url);
        return uri.pathSegments.last;
      }).join(',');

      final response = await http.get(
        Uri.parse('https://rickandmortyapi.com/api/episode/$ids'),
      );

      final data = json.decode(response.body);

      List<dynamic> list;
      if (data is List) {
        list = data;
      } else {
        // If only 1 episode, API returns object not list
        list = [data];
      }

      return list.map((e) => Episode(
        name: e['name'],
        episodeCode: e['episode'],
        airDate: e['air_date'],
      )).toList();
    }());
  }

  void selectCharacter(Character c) {
    selectedCharacter.value = c;
    fetchEpisodes(c);
  }

  @override
  void onInit(void params) {
    fetchCharacters();
  }
}
