import 'package:flutter/material.dart';
import 'package:nano/nano.dart';

// Actions
class Increment extends NanoAction {}

class Decrement extends NanoAction {}

class Reset extends NanoAction {}

// Logic
class CounterLogic extends NanoLogic<dynamic> {
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

  @override
  void onAction(NanoAction action) {
    history.update((list) => [...list, count.value]);
    if (action is Increment) {
      count.increment();
    } else if (action is Decrement) {
      count.decrement();
    } else if (action is Reset) {
      count(0);
    }
  }
}

// Page
class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return NanoView<CounterLogic, dynamic>(
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
                logic.count.watch((context, val) {
                  return Text(
                    '$val',
                    style: Theme.of(context).textTheme.displayLarge,
                  );
                }),

                const SizedBox(height: 20),

                // Watch computed
                logic.isEven.watch((context, even) {
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

                logic.doubleCount.watch((context, doubleVal) {
                  return Text('Doubled: $doubleVal');
                }),

                const SizedBox(height: 20),

                // Watch complex object (List)
                logic.history.watch((context, hist) {
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
                onPressed: () => logic.dispatch(Reset()),
                child: const Icon(Icons.refresh),
              ),
              const SizedBox(height: 10),
              FloatingActionButton(
                heroTag: 'decrement',
                onPressed: () => logic.dispatch(Decrement()),
                child: const Icon(Icons.remove),
              ),
              const SizedBox(height: 10),
              FloatingActionButton(
                heroTag: 'increment',
                onPressed: () => logic.dispatch(Increment()),
                child: const Icon(Icons.add),
              ),
            ],
          ),
        );
      },
    );
  }
}
