import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';
import 'dart:async';

void main() {
  test(
    'WorkerAtom should not trigger excessive updates when source emits multiple states',
    () async {
      final controller = StreamController<double>();
      final source = StreamAtom<double>(controller.stream, label: 'source');

      int workCount = 0;
      final worker = WorkerAtom<AsyncState<double>, String>(source, (state) {
        workCount++;
        return "Count: $workCount (State: $state)";
      }, label: 'worker');

      List<AsyncState<String>> states = [];
      worker.addListener(() {
        states.add(worker.value);
      });

      // 1. Initial emission - source emits AsyncLoading
      // 2. We add data - source emits AsyncData
      controller.add(10.0);

      await Future.delayed(const Duration(milliseconds: 500));

      print("Work count: $workCount");
      print("States recorded: ${states.length}");
      for (var s in states) {
        print("  - $s");
      }

      controller.close();
    },
  );
}
