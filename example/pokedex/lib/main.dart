import 'package:flutter/material.dart';
import 'package:nano/nano.dart';
import 'pokedex_logic.dart';

void main() {
  runApp(const PokedexApp());
}

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return NanoView(
      create: (reg) => PokedexLogic(),
      builder: (context, logic) {
        return Watch(
          logic.themeColor,
          builder: (context, color) {
            return MaterialApp(
              title: 'Nano Pokedex',
              theme: ThemeData(
                primarySwatch: Colors.red,
                colorScheme: ColorScheme.fromSeed(seedColor: color),
                useMaterial3: true,
              ),
              home: const PokedexHome(),
            );
          },
        );
      },
    );
  }
}

class PokedexHome extends StatelessWidget {
  const PokedexHome({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = context.read<PokedexLogic>();

    // Fix: We can't assign a Widget (Watch) to appBar which expects PreferredSizeWidget.
    // AppBar implements PreferredSizeWidget.
    // We can just wrap the specific properties inside AppBar with Watch,
    // OR wrap the Scaffold itself if we want to rebuild the whole scaffold (easiest for theme).

    // However, PokedexApp already watches themeColor and updates the Theme.
    // So the Scaffold's AppBar will automatically pick up the primary color from the Theme!
    // We don't need to manually watch logic.themeColor here for AppBar color unless we want to force it.
    // But let's assume we want explicitly dynamic AppBar background.

    // Solution: Use PreferredSize wrapper to satisfy type system if we must wrap the whole AppBar.
    // Better Solution: Use AtomBuilder/Watch INSIDE the AppBar properties.

    // BUT AppBar properties like backgroundColor take a Color, not a Widget.
    // So we CANNOT use Watch inside backgroundColor: Watch(...)

    // So we MUST wrap the AppBar.
    // PreferredSize(preferredSize: Size.fromHeight(kToolbarHeight), child: Watch(..., builder: () => AppBar(...)))

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Watch(
          logic.themeColor,
          builder: (context, color) {
            return AppBar(
              title: const Text('Nano Pokedex'),
              backgroundColor: color,
              foregroundColor: Colors.white,
            );
          }
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search Pokemon (e.g. pikachu)',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onSubmitted: (value) => logic.findPokemon(value),
            ),
          ),
          Expanded(
            child: AsyncAtomBuilder<Pokemon>(
              atom: logic.pokemon,
              loading: (context) => const Center(child: CircularProgressIndicator()),
              error: (context, error) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(error.toString(), style: const TextStyle(fontSize: 18)),
                  ],
                ),
              ),
              idle: (context) => const Center(
                child: Text(
                  'Search for a Pokemon to begin!',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
              data: (context, pokemon) {
                // Here we can use the logic.themeColor for specific highlights
                return Watch(
                  logic.themeColor,
                  builder: (context, color) => _buildPokemonDetail(pokemon, color)
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPokemonDetail(Pokemon pokemon, Color color) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Center(
              child: Image.network(
                pokemon.animatedSpriteUrl ?? pokemon.spriteUrl,
                height: 180,
                width: 180,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 64),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            '#${pokemon.id} ${pokemon.name.toUpperCase()}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: pokemon.types.map((t) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                t.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )).toList(),
          ),

          if (pokemon.isLegendary)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: const Text(
                'LEGENDARY',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              pokemon.flavorText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 16),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat('Height', '${pokemon.height / 10} m'),
                _buildStat('Weight', '${pokemon.weight / 10} kg'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
