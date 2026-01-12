import 'package:flutter/material.dart';
import 'package:nano/nano.dart';

// --- Custom Observer for Analytics ---
class AnalyticsObserver extends NanoObserver {
  @override
  void onChange(Atom atom, dynamic oldValue, dynamic newValue) {
    if (atom.meta.containsKey('analytics')) {
      final eventName = atom.meta['analytics'] as String;
      debugPrint('ANALYTICS: Sending event "$eventName" with value: $newValue');
      // In real app: FirebaseAnalytics.instance.logEvent(name: eventName, parameters: {'value': newValue});
    }
  }

  @override
  void onError(Atom atom, Object error, StackTrace stack) {
    debugPrint('ANALYTICS: Error in ${atom.label}: $error');
  }
}

// --- Logic ---
class AnalyticsExampleLogic extends NanoLogic<void> {
  // Atom with analytics metadata
  final counter = 0.toAtom('counter', {'analytics': 'counter_changed'});

  // Async atom
  final data = AsyncAtom<String>(label: 'dataLoader');

  void increment() => counter.increment();

  Future<void> loadData() async {
    // Simulate network request
    data.track(Future.delayed(const Duration(seconds: 2), () => 'Loaded Data!'));
  }
}

// --- Page ---
class AnalyticsExamplePage extends StatelessWidget {
  const AnalyticsExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return NanoView<AnalyticsExampleLogic, void>(
      create: (reg) => AnalyticsExampleLogic(),
      builder: (context, logic) {
        return Scaffold(
          appBar: AppBar(title: const Text('Analytics & Ergonomics')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Use AtomBuilder (alias for Watch)
                AtomBuilder(
                  atom: logic.counter,
                  builder: (context, count) => Text(
                    'Count: $count',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: logic.increment,
                  child: const Text('Increment (Logs Analytics)'),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: logic.loadData,
                  child: const Text('Load Data'),
                ),
                const SizedBox(height: 20),
                // Use AsyncAtomBuilder for easier async handling
                AsyncAtomBuilder(
                  atom: logic.data,
                  idle: (context) => const Text('Press button to load'),
                  loading: (context) => const CircularProgressIndicator(),
                  data: (context, data) => Text(
                    data,
                    style: const TextStyle(color: Colors.green, fontSize: 18),
                  ),
                  error: (context, error) => Text(
                    'Error: $error',
                    style: const TextStyle(color: Colors.red),
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

void main() {
  // Setup Composite Observer
  Nano.observer = CompositeObserver([
    // Keep the default debug printer
    Nano.observer,
    // Add our analytics observer
    AnalyticsObserver(),
  ]);

  runApp(const MaterialApp(home: AnalyticsExamplePage()));
}
