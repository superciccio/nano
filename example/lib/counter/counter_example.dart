import 'package:flutter/material.dart';
import 'package:nano/nano.dart';

// Logic
class CounterLogic extends NanoLogic<void> {
  // Use .toAtom() extension sugar
  final count = 0.toAtom('count');
  final history = Atom<List<int>>([], label: 'history');

  // Computed Atom: derived from count
  late final isEven = ComputedAtom(
    [count],
    () => count.value.isEven,
    label: 'isEven',
  );

  // Computed Atom: derived from count
  late final doubleCount = ComputedAtom(
    [count],
    () => count.value * 2,
    label: 'doubleCount',
  );

  void increment() {
    // Save to history before updating
    history.update((list) => [...list, count.value]);

    // Use .increment() extension sugar
    count.increment();
  }

  void decrement() {
    history.update((list) => [...list, count.value]);
    count.decrement();
  }

  void reset() {
    history.update((list) => [...list, count.value]);
    count(0); // Using call operator to set
  }
}

// Page
class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return NanoView<CounterLogic, void>(
      create: (r) => CounterLogic(),
      builder: (context, logic) {
        return Scaffold(
          appBar: AppBar(title: const Text('Sugar Counter')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('You have pushed the button this many times:'),

                // Watch count
                Watch(logic.count, builder: (context, val) {
                  return Text(
                    '$val',
                    style: Theme.of(context).textTheme.displayLarge,
                  );
                }),

                const SizedBox(height: 20),

                // Watch computed
                Watch(logic.isEven, builder: (context, even) {
                  return Text(
                    even ? 'EVEN' : 'ODD',
                    style: TextStyle(
                      color: even ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  );
                }),

                const SizedBox(height: 10),

                Watch(logic.doubleCount, builder: (context, doubleVal) {
                  return Text('Doubled: $doubleVal');
                }),

                const SizedBox(height: 20),

                // Watch complex object (List)
                Watch(logic.history, builder: (context, hist) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'History: ${hist.join(', ')}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }),
              ],
            ),
          ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: 'reset',
                onPressed: logic.reset,
                child: const Icon(Icons.refresh),
              ),
              const SizedBox(height: 10),
              FloatingActionButton(
                heroTag: 'decrement',
                onPressed: logic.decrement,
                child: const Icon(Icons.remove),
              ),
              const SizedBox(height: 10),
              FloatingActionButton(
                heroTag: 'increment',
                onPressed: logic.increment,
                child: const Icon(Icons.add),
              ),
            ],
          ),
        );
      },
    );
  }
}
