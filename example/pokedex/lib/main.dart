import 'package:flutter/material.dart';
import 'package:nano/nano.dart';
import 'pokedex_logic.dart';

void main() {
  runApp(
    Scope(
      modules: [
        PokedexService(),
      ],
      child: const PokedexApp(),
    ),
  );
}

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return NanoView(
      create: (reg) => PokedexLogic(reg.get()),
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
              home: PokedexHome(logic: logic),
            );
          },
        );
      },
    );
  }
}

class PokedexHome extends StatelessWidget {
  final PokedexLogic logic;

  const PokedexHome({super.key, required this.logic});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDC0A2D), // Classic Pokedex Red
      appBar: AppBar(
        title: const Text('NANO POKEDEX', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Decorative Lights
          _buildTopLights(),
          
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              decoration: BoxDecoration(
                color: const Color(0xFFDEDEDE), // Off-white body panel
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey[800]!, width: 3),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
              ),
              child: Column(
                children: [
                  // Screen Bezel
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF232323), // Dark bezel
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF98CB98), // GameBoy Green Screen
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.black54, width: 2),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: AsyncAtomBuilder<Pokemon>(
                            atom: logic.pokemon,
                            loading: (context) => const Center(
                              child: Text('ANALYZING...', style: TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                            error: (context, error) => _buildErrorScreen(error),
                            idle: (context) => const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.catching_pokemon, size: 48, color: Colors.black54),
                                  SizedBox(height: 8),
                                  Text('WAITING FOR INPUT', style: TextStyle(fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                                ],
                              ),
                            ),
                            data: (context, pokemon) {
                              return _buildPokemonDetail(pokemon);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Controls Area
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.black12,
                            hintText: 'ENTER NAME...',
                            hintStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                            prefixIcon: const Icon(Icons.search, color: Colors.black54),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (value) => logic.findPokemon(value),
                        ),
                        const SizedBox(height: 16),
                        _buildDpadAndButtons(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopLights() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue[400],
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)],
            ),
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                _smallLight(Colors.red),
                const SizedBox(width: 8),
                _smallLight(Colors.yellow),
                const SizedBox(width: 8),
                _smallLight(Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallLight(Color color) {
    return Container(
      width: 15, height: 15,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.black26, width: 1),
      ),
    );
  }

  Widget _buildDpadAndButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // D-Pad Placeholder
        SizedBox(
          width: 80, height: 80,
          child: Stack(
            children: [
              Align(alignment: Alignment.center, child: Container(width: 80, height: 25, color: Colors.black87)),
              Align(alignment: Alignment.center, child: Container(width: 25, height: 80, color: Colors.black87)),
              Align(alignment: Alignment.center, child: Container(width: 15, height: 15, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black12))),
            ],
          ),
        ),
        // Action Buttons
        Row(
          children: [
            Column(
              children: [
              SizedBox(width: 60, height: 10, child: DecoratedBox(decoration: BoxDecoration(color: Colors.red[900], borderRadius: BorderRadius.circular(5)))),
              const SizedBox(width: 8),
              SizedBox(width: 60, height: 10, child: DecoratedBox(decoration: BoxDecoration(color: Colors.blue[900], borderRadius: BorderRadius.circular(5)))),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorScreen(Object? error) {
    // Extract message for cleaner display
    final message = (error ?? 'Unknown Error').toString().replaceAll('Exception:', '').replaceAll('Pokemon', '').trim();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.black87),
            const SizedBox(height: 12),
            const Text(
              'ERR_NOT_FOUND',
              style: TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              message.isNotEmpty ? message : 'UNKNOWN SIGNAL',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPokemonDetail(Pokemon pokemon) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.network(
              pokemon.animatedSpriteUrl ?? pokemon.spriteUrl,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 64, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Text(
              'No. ${pokemon.id.toString().padLeft(3, '0')}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(
              pokemon.name.toUpperCase(),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: pokemon.types.map((t) => Chip(
                label: Text(t.toUpperCase(), style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.white)),
                backgroundColor: Colors.black87,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),
            const Divider(color: Colors.black54, thickness: 1, height: 24),
            Text(
              pokemon.flavorText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('HT: ${pokemon.height / 10}m', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                  Text('WT: ${pokemon.weight / 10}kg', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
