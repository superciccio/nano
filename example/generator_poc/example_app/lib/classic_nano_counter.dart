import 'package:flutter/material.dart';
import 'package:nano/nano.dart';

// Classic Nano: Manual Boilerplate

class ClassicCounterLogic extends NanoLogic {
  // Boilerplate: Defining Atom
  final count = Atom(0, label: 'ClassicCounter.count');

  // Boilerplate: Helper method
  void increment() {
    count.value++;
  }
}

class ClassicNanoCounter extends StatelessWidget {
  const ClassicNanoCounter({super.key});

  @override
  Widget build(BuildContext context) {
    // Boilerplate: Setup Logic & View
    return NanoView<ClassicCounterLogic, void>(
      create: (_) => ClassicCounterLogic(),
      builder: (context, logic) {
        return Scaffold(
          appBar: AppBar(title: const Text('Classic Nano')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text('You have pushed the button this many times:'),
                // Boilerplate: Explicit Watch
                logic.count.watch((context, value) {
                  return Text(
                    '$value',
                    style: Theme.of(context).textTheme.headlineMedium,
                  );
                }),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            // Accessing method
            onPressed: logic.increment,
            tooltip: 'Increment',
            heroTag: 'classic_fab',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
