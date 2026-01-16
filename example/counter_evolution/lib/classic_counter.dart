import 'package:flutter/material.dart';
import 'package:nano/nano.dart';
import 'services.dart';

class ClassicCounterLogic extends NanoLogic {
  final ServiceA serviceA;
  final ServiceB serviceB;
  final ServiceC serviceC;

  ClassicCounterLogic(this.serviceA, this.serviceB, this.serviceC);

  final count = Atom(0, label: 'Classic.count');

  void increment() {
    final newValue = serviceC.calculate(count.value);
    count.value = newValue;
    serviceB.log('Classic incremented to $newValue');
  }
}

class ClassicCounter extends StatelessWidget {
  const ClassicCounter({super.key});

  @override
  Widget build(BuildContext context) {
    return NanoView(
      // ⚠️ Verbose Injection: You must manually get() each dependency.
      create: (r) => ClassicCounterLogic(r.get(), r.get(), r.get()),
      builder: (context, logic) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Classic Nano (Manual)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                logic.count.watch((context, value) {
                  return Text('${logic.serviceA.prefix}$value', style: const TextStyle(fontSize: 32));
                }),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: logic.increment,
                  child: const Text('Increment'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}