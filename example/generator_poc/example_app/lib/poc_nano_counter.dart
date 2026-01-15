import 'package:flutter/material.dart';
import 'package:nano/nano.dart';
import 'package:nano_annotations/nano_annotations.dart';
import 'nano_observed.dart';

part 'poc_nano_counter.g.dart';

// PoC Nano: "SwiftUI-style" Simplicity

// 1. Logic: Clean, Annotated
@nano
class PocCounterLogic extends NanoLogic with _$PocCounterLogic {
  @state
  int count = 0;

  void increment() {
    count++; // Just standard Dart mutation!
  }
}

class PocNanoCounter extends StatelessWidget {
  const PocNanoCounter({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. Setup: Still need scope/DI (can be lifted up), but here for isolation.
    return Scope(
      modules: [NanoLazy(() => PocCounterLogic())],
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    // 3. View: Observed wrapper, implicit tracking
    return NanoObserved(
      builder: (context) {
        // "Hooks-like" or "Context-read" access
        final logic = context.use<PocCounterLogic>();

        return Scaffold(
          appBar: AppBar(title: const Text('PoC Generated Nano')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text('You have pushed the button this many times:'),
                // 4. Usage: Direct property access! No .watch()
                Text(
                  '${logic.count}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: logic.increment,
            tooltip: 'Increment',
            heroTag: 'poc_fab',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
