import 'package:flutter/material.dart';
import 'package:nano/nano.dart';

class MyCounterManualLogic extends NanoLogic<void> {
  final counter = 0.toAtom();
  void increment() => counter.increment();
}

class MyCounterManual extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NanoView<MyCounterManualLogic, void>(
      create: (_) => MyCounterManualLogic(),
      builder: (context, logic) {
        return logic.counter.watch((context, value) {
          return Text('$value');
        });
      },
    );
  }
}
