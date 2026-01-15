import 'package:flutter/material.dart';
import 'package:nano/nano.dart';
import 'package:nano_annotations/nano_annotations.dart';
import 'nano_consumer.dart';

part 'poc_nano_counter.g.dart';

// PoC Nano: "SwiftUI-style" Simplicity with Build Runner

// 1. Logic: Private base class containing the state and logic
//    User writes standard Dart code.
@nano
abstract class _PocCounterLogic extends NanoLogic {
  @state
  int count = 0;

  void increment() {
    count++; // Accesses the overridden 'count' in the concrete class
  }
}

// 2. The concrete public class that users interact with
//    Generated mixin intercepts the fields.
class PocCounterLogic = _PocCounterLogic with _$PocCounterLogic;

class PocNanoCounter extends StatelessWidget {
  const PocNanoCounter({super.key});

  @override
  Widget build(BuildContext context) {
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
    // 3. View: NanoConsumer provides implicit tracking.
    return NanoConsumer(
      builder: (context) {
        // 4. Usage:
        //    - Resolve logic via context
        //    - Access properties directly (no .value, no .watch)
        final logic = context.use<PocCounterLogic>();

        return Scaffold(
          appBar: AppBar(title: const Text('PoC Generated Nano')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text('You have pushed the button this many times:'),
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
