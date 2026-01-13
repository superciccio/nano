import 'package:flutter/material.dart';
import 'package:nano/nano.dart';

class IncrementAction extends NanoAction {}

class CounterLogic extends NanoLogic<void> {
  final counter = Atom(0);

  @override
  void onAction(NanoAction action) {
    if (action is IncrementAction) {
      counter.update((v) => v + 1);
    }
  }
}

class StrictModeExample extends StatelessWidget {
  const StrictModeExample({super.key});

  @override
  Widget build(BuildContext context) {
    return NanoView<CounterLogic, void>(
      create: (reg) => CounterLogic(),
      builder: (context, logic) {
        return Column(
          children: [
            AtomBuilder(
              atom: logic.counter,
              builder: (context, value) {
                return Text('Counter: $value');
              },
            ),
            TextButton(
              onPressed: () {
                logic.dispatch(IncrementAction());
              },
              child: const Text('Increment'),
            ),
            TextButton(
              onPressed: () {
                NanoConfig.strictMode = true;
                logic.counter.value++;
              },
              child: const Text('Increment without action'),
            ),
          ],
        );
      },
    );
  }
}
