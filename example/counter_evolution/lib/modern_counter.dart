import 'package:flutter/material.dart';
import 'package:nano/nano.dart';
import 'package:nano_annotations/nano_annotations.dart';
import 'services.dart';

part 'modern_counter.g.dart';

@nano
abstract class _ModernCounterLogic extends NanoLogic {
  final ServiceA serviceA;
  final ServiceB serviceB;
  final ServiceC serviceC;

  _ModernCounterLogic(this.serviceA, this.serviceB, this.serviceC);

  @state
  int count = 0;

  void increment() {
    count = serviceC.calculate(count);
    serviceB.log('Modern incremented to $count');
  }
}

// ⚠️ Constructor Boilerplate (Unavoidable with current Generator):
class ModernCounterLogic extends _ModernCounterLogic with _$ModernCounterLogic {
  ModernCounterLogic(super.serviceA, super.serviceB, super.serviceC);
}

// ✅ Clean Component: No wrapper, no boilerplate build method.
class ModernCounter extends NanoComponent {
  const ModernCounter({super.key});

  @override
  List<Object> get modules => [
    NanoLazy((r) => ModernCounterLogic(r.get(), r.get(), r.get()))
  ];

  @override
  Widget view(BuildContext context) {
    final logic = context.use<ModernCounterLogic>();
    
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Modern Nano (Generated)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('${logic.serviceA.prefix}${logic.count}', style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: logic.increment,
              child: const Text('Increment'),
            ),
          ],
        ),
      ),
    );
  }
}
