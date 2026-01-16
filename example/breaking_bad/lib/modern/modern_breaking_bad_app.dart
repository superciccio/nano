import 'package:flutter/material.dart';
import 'package:nano/nano.dart';
import '../breaking_bad_logic.dart'; // For QuoteService, Quote
import 'modern_breaking_bad_logic.dart';

class ModernBreakingBadApp extends StatelessWidget {
  const ModernBreakingBadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Modern Breaking Bad',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1a1a1a),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF369457),
          secondary: Color(0xFFeeb902),
        ),
      ),
      home: Scope(
        modules: [
          QuoteService(),
          // StatsLogic needs to be shared, so it's singleton here.
          NanoLazy((_) => ModernStatsLogic()), 
        ],
        child: const ModernMainScreen(),
      ),
    );
  }
}

class ModernMainScreen extends StatelessWidget {
  const ModernMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modern Bad Quotes'),
        backgroundColor: Colors.black,
        actions: const [
          SizedBox(width: 300, child: ModernCharacterCounterWidget()),
        ],
      ),
      body: const Center(
        child: ModernQuoteView(),
      ),
    );
  }
}

class ModernCharacterCounterWidget extends NanoStatelessWidget {
  const ModernCharacterCounterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = context.use<ModernStatsLogic>();
    
    return Wrap(
      spacing: 8,
      children: [
        _CounterChip(label: '⚖️', count: logic.saulCount, color: Colors.orange),
        _CounterChip(label: '⚗️', count: logic.jesseCount, color: Colors.yellow),
        _CounterChip(label: '🕶️', count: logic.waltCount, color: Colors.green),
      ],
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

// Using NanoComponent for the QuoteView to self-contain its logic creation
class ModernQuoteView extends NanoComponent {
  const ModernQuoteView({super.key});

  @override
  List<Object> get modules => [
    NanoLazy((r) => ModernQuoteLogic(r.get(), r.get()))
  ];

  @override
  Widget view(BuildContext context) {
    final logic = context.use<ModernQuoteLogic>();
    final state = logic.quote.value; // Access value to subscribe

    return switch (state) {
       AsyncLoading() => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF369457)),
              const SizedBox(height: 16),
              Text(
                ['Cooking...', 'Applying Science...', 'Calling Saul...', 'Treading lightly...']
                    .elementAt(DateTime.now().microsecond % 4),
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
       AsyncError(:final error) => Column(
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
       AsyncData(:final data) => Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '"${data.quote}"',
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
                  '- ${data.author}',
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
       _ => Column( // Idle
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
    };
  }
}
