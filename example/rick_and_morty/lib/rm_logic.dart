import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nano/nano.dart';

// -----------------------------------------------------------------------------
// Service
// -----------------------------------------------------------------------------
class RickAndMortyService {
  Future<List<Character>> fetchCharacters(int page) async {
    final response = await http.get(
      Uri.parse('https://rickandmortyapi.com/api/character/?page=$page'),
    );

    final data = json.decode(response.body);
    final results = data['results'] as List;

    return results.map((c) => Character(
      id: c['id'],
      name: c['name'],
      status: c['status'],
      species: c['species'],
      image: c['image'],
      episodeUrls: List<String>.from(c['episode']),
    )).toList();
  }

  Future<List<Episode>> fetchEpisodes(List<String> episodeUrls) async {
    final ids = episodeUrls.map((url) {
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
  }
}

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
  final RickAndMortyService _service;

  RMLogic(this._service);

  // Main List State
  final characters = AsyncAtom<List<Character>>(label: 'characters');

  final selectedCharacter = Atom<Character?>(null, label: 'selected');
  final page = Atom<int>(1, label: 'page');

  Future<void> fetchCharacters() async {
    await characters.track(() async {
      final currentPage = page.value;
      final newChars = await _service.fetchCharacters(currentPage);

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

    await character.episodes.track(_service.fetchEpisodes(character.episodeUrls));
  }

  void selectCharacter(Character c) {
    selectedCharacter.value = c;
    fetchEpisodes(c);
  }

  @override
  void onReady() {
    fetchCharacters();
  }
}