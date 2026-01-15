import 'package:flutter/material.dart';
import 'package:nano/nano.dart';
import 'breaking_bad_logic.dart';

void main() {
  runApp(
    Scope(
      modules: [
        QuoteService(),
        // Eager singleton for StatsLogic so it persists across screen rebuilds if needed,
        // though here it's fine as a lazy singleton if accessed correctly.
        // Let's make it a standard singleton (instance) or NanoLazy.
        // Since we want to share the SAME instance between CharacterCounterWidget and QuoteView,
        // we should register it as a singleton.
        NanoLazy((_) => StatsLogic()),
      ],
      child: const BreakingBadApp(),
    ),
  );
}

class BreakingBadApp extends StatelessWidget {
  const BreakingBadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Breaking Bad Quotes',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1a1a1a),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF369457), // Breaking Bad Green
          secondary: Color(0xFFeeb902), // Yellow Lab Suits
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bad Quotes'),
        backgroundColor: Colors.black,
        actions: const [
          SizedBox(width: 300, child: CharacterCounterWidget()),
        ],
      ),
      body: const Center(
        child: QuoteView(),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Detached Widget (The "Character Counter" in AppBar)
// -----------------------------------------------------------------------------
class CharacterCounterWidget extends StatelessWidget {
  const CharacterCounterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // We use the existing StatsLogic from the scope
    return NanoView<StatsLogic, void>(
      create: (reg) => reg.get<StatsLogic>(),
      // We don't want to dispose StatsLogic when this widget is removed/rebuilt
      // because it's shared with QuoteLogic.
      autoDispose: false,
      builder: (context, logic) {
        return (logic.saulCount, logic.jesseCount, logic.waltCount).watch((context, saul, jesse, walt) {
           return Wrap(
            spacing: 8,
            children: [
              _CounterChip(label: '⚖️', count: saul, color: Colors.orange),
              _CounterChip(label: '⚗️', count: jesse, color: Colors.yellow),
              _CounterChip(label: '🕶️', count: walt, color: Colors.green),
            ],
          );
        });
      },
    );
  }
}

class _CounterChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CounterChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '$label $count',
        style: const TextStyle(fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Main Content (The Quote View)
// -----------------------------------------------------------------------------
class QuoteView extends StatelessWidget {
  const QuoteView({super.key});

  @override
  Widget build(BuildContext context) {
    return NanoView(
      create: (reg) => QuoteLogic(
        reg.get<QuoteService>(),
        reg.get<StatsLogic>(),
      ),
      builder: (context, logic) {
        return AsyncAtomBuilder<Quote>(
          atom: logic.quote,
          loading: (context) => const CircularProgressIndicator(color: Color(0xFF369457)),
          error: (context, error) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               const Icon(Icons.error, color: Colors.red),
               Text(error.toString()),
               const SizedBox(height: 16),
               ElevatedButton(
                 onPressed: logic.fetchQuote,
                 child: const Text('TRY AGAIN'),
               )
            ],
          ),
          idle: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tap to cook!',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: logic.fetchQuote,
                icon: const Icon(Icons.science),
                label: const Text('GET QUOTE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF369457),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
          data: (context, quote) => Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '"${quote.quote}"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'serif',
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '- ${quote.author}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF369457),
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton.icon(
                  onPressed: logic.fetchQuote,
                  icon: const Icon(Icons.refresh),
                  label: const Text('ANOTHER ONE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF369457),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}