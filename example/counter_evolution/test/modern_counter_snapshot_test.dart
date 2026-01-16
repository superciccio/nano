import 'package:flutter_test/flutter_test.dart';
import 'package:counter_evolution/modern_counter.dart';
import 'package:counter_evolution/services.dart';
import 'package:nano_test_utils/nano_test_utils.dart';

void main() {
  test('ModernCounterLogic snapshot test', () async {
    // 1. Setup Logic
    final logic = ModernCounterLogic(ServiceA(), ServiceB(), ServiceC());

    // 2. Initialize Harness
    final harness = NanoTestHarness(logic);

    // 3. Record Flow
    await harness.record((logic) async {
      logic.increment();
      logic.increment();
    });

    // 4. Verify Snapshot (Automatic File Management)
    // This will create/check test/goldens/counter_increment.json
    harness.expectSnapshot('counter_increment');
  });
}