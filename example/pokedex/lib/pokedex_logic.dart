import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nano/nano.dart';

// -----------------------------------------------------------------------------
// Service
// -----------------------------------------------------------------------------
class PokedexService {
  Future<Pokemon> fetchPokemon(String name) async {
    final response = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon/$name'));
    if (response.statusCode == 404) {
      throw 'Pokemon "$name" not found!';
    }

    final data = json.decode(response.body);

    final speciesUrl = data['species']['url'];
    final speciesResponse = await http.get(Uri.parse(speciesUrl));
    final speciesData = json.decode(speciesResponse.body);

    String flavor = "No description available.";
    for (var entry in speciesData['flavor_text_entries']) {
      if (entry['language']['name'] == 'en') {
        flavor = entry['flavor_text'].replaceAll('\n', ' ');
        break;
      }
    }

    String? animated;
    try {
      animated = data['sprites']['versions']['generation-v']['black-white']['animated']['front_default'];
    } catch (_) {}

    return Pokemon(
      id: data['id'],
      name: data['name'],
      height: data['height'],
      weight: data['weight'],
      spriteUrl: data['sprites']['front_default'] ?? '',
      animatedSpriteUrl: animated,
      types: (data['types'] as List).map((t) => t['type']['name'] as String).toList(),
      flavorText: flavor,
      isLegendary: speciesData['is_legendary'] ?? false,
    );
  }
}

// -----------------------------------------------------------------------------
// Models
// -----------------------------------------------------------------------------
class Pokemon {
  final int id;
  final String name;
  final int height;
  final int weight;
  final String spriteUrl;
  final String? animatedSpriteUrl;
  final List<String> types;
  final String flavorText;
  final bool isLegendary;

  Pokemon({
    required this.id,
    required this.name,
    required this.height,
    required this.weight,
    required this.spriteUrl,
    this.animatedSpriteUrl,
    required this.types,
    required this.flavorText,
    required this.isLegendary,
  });
}

// -----------------------------------------------------------------------------
// Logic
// -----------------------------------------------------------------------------
class PokedexLogic extends NanoLogic<void> {
  final PokedexService _service;

  PokedexLogic(this._service);

  // AsyncAtom usage
  final pokemon = AsyncAtom<Pokemon>(label: 'pokemon');

  // Cache
  final _cache = <String, Pokemon>{};

  // Computed Theme Color based on Type
  late final themeColor = computed(() {
    return pokemon.value.map(
      data: (data) {
        if (data.types.isEmpty) return Colors.red;
        switch (data.types.first) {
          case 'fire': return Colors.orange;
          case 'water': return Colors.blue;
          case 'grass': return Colors.green;
          case 'electric': return Colors.yellow[700]!;
          case 'psychic': return Colors.purple;
          case 'ice': return Colors.cyan;
          case 'dragon': return Colors.indigo;
          case 'dark': return Colors.grey[800]!;
          case 'fairy': return Colors.pink;
          case 'fighting': return Colors.red[900]!;
          case 'poison': return Colors.deepPurple;
          case 'ground': return Colors.brown;
          case 'rock': return Colors.grey;
          case 'bug': return Colors.lightGreen;
          case 'ghost': return Colors.deepPurple[900]!;
          case 'steel': return Colors.blueGrey;
          default: return Colors.red;
        }
      },
      loading: () => Colors.red, // Default during load or keep previous?
      error: (_) => Colors.red,
      idle: () => Colors.red,
    );
  }, label: 'themeColor');

  Future<void> findPokemon(String query) async {
    if (query.trim().isEmpty) return;

    final name = query.trim().toLowerCase();

    // Check Cache
    if (_cache.containsKey(name)) {
      pokemon.set(AsyncData(_cache[name]!));
      return;
    }

    // Use track() with an immediate async function execution
    await pokemon.track(() async {
      final newPokemon = await _service.fetchPokemon(name);
      _cache[name] = newPokemon;
      return newPokemon;
    }());
  }
}