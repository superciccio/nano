import 'package:flutter/material.dart';
import 'package:nano/nano.dart';
import 'rm_logic.dart';

void main() {
  runApp(
    Scope(
      modules: [
        RickAndMortyService(),
      ],
      child: const RickAndMortyApp(),
    ),
  );
}

class RickAndMortyApp extends StatelessWidget {
  const RickAndMortyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rick & Morty DB',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF24282F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF97ce4c), // Portal Green
          secondary: Color(0xFF00b5cc), // Hair Blue
        ),
      ),
      home: const CharacterListScreen(),
    );
  }
}

class CharacterListScreen extends StatelessWidget {
  const CharacterListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return NanoView(
      create: (reg) => RMLogic(reg.get()),
      builder: (context, logic) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Dimension Hopper'),
            actions: [
              // Show loading spinner in AppBar if fetching characters
              Watch(
                logic.characters,
                builder: (context, state) {
                   if (state.isLoading) {
                     return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                   }
                   return const SizedBox.shrink();
                }
              ),
            ],
          ),
          body: Row(
            children: [
              // List View
              Expanded(
                flex: 2,
                child: AsyncAtomBuilder<List<Character>>(
                  atom: logic.characters,
                  loading: (context) {
                    final data = logic.characters.value.dataOrNull;
                    if (data != null && data.isNotEmpty) {
                      return _buildList(context, logic, data, isLoadingMore: true);
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                  error: (context, error) => Center(child: Text('Error: $error')),
                  idle: (context) => const SizedBox.shrink(),
                  data: (context, chars) => _buildList(context, logic, chars),
                ),
              ),

              // Detail View
              Watch(
                logic.selectedCharacter,
                builder: (context, selected) {
                  if (selected != null) {
                    return Expanded(
                      flex: 3,
                      child: Container(
                        color: Colors.black12,
                        child: _CharacterDetail(character: selected),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(BuildContext context, RMLogic logic, List<Character> chars, {bool isLoadingMore = false}) {
     // We need to watch selectedCharacter to highlight rows
     return Watch(
       logic.selectedCharacter,
       builder: (context, selected) {
         return ListView.builder(
            itemCount: chars.length + 1,
            itemBuilder: (context, index) {
              if (index == chars.length) {
                if (isLoadingMore) return const Center(child: CircularProgressIndicator());
                return TextButton(
                  onPressed: logic.fetchCharacters,
                  child: const Text('Load More...'),
                );
              }

              final char = chars[index];
              final isSelected = selected?.id == char.id;

              return ListTile(
                selected: isSelected,
                selectedTileColor: Colors.white10,
                leading: CircleAvatar(backgroundImage: NetworkImage(char.image)),
                title: Text(char.name),
                subtitle: Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _statusColor(char.status),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('${char.status} - ${char.species}'),
                  ],
                ),
                onTap: () {
                  logic.selectCharacter(char);
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ['Wubba Lubba Dub Dub!', 'Get Schwifty!', 'I turned myself into a Pickle!', 'Aw jeez, Rick!']
                            .elementAt(char.id % 4),
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      duration: const Duration(milliseconds: 1500),
                      backgroundColor: const Color(0xFF97ce4c),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              );
            },
          );
       }
     );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Alive': return Colors.green;
      case 'Dead': return Colors.red;
      default: return Colors.grey;
    }
  }
}

class _CharacterDetail extends StatelessWidget {
  final Character character;
  const _CharacterDetail({required this.character});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.network(character.image, height: 200, fit: BoxFit.cover, width: double.infinity),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(character.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        ),
        const Divider(),
        const Text("EPISODES APPEARANCES", style: TextStyle(color: Colors.grey)),

        Expanded(
          child: AsyncAtomBuilder<List<Episode>>(
            atom: character.episodes,
            loading: (context) => const Center(child: CircularProgressIndicator()),
            error: (context, error) => Center(child: Text('$error')),
            // If idle, it means we haven't fetched yet.
            // The logic calls fetchEpisodes when selected, so it should be loading or data immediately.
            // But let's handle idle just in case.
            idle: (context) => const Center(child: CircularProgressIndicator()),
            data: (context, episodes) {
              if (episodes.isEmpty) return const Center(child: Text("No episodes found?"));

              return ListView.builder(
                itemCount: episodes.length,
                itemBuilder: (context, index) {
                  final ep = episodes[index];
                  return ListTile(
                    leading: Text(ep.episodeCode, style: const TextStyle(color: Color(0xFF97ce4c))),
                    title: Text(ep.name),
                    trailing: Text(ep.airDate),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}