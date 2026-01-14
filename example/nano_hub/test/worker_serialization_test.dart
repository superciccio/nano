import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';
import 'dart:async';

class FeatureWithUnsendableState {
  final controller = StreamController<double>();

  late final source = StreamAtom<double>(controller.stream, label: 'source');

  static String staticWorker(AsyncState<double> state) {
    return "Processed: $state";
  }

  late final workerAtom = WorkerAtom<AsyncState<double>, String>(
    source,
    staticWorker,
    label: 'workerAtom',
  );

  void trigger() {
    controller.add(10.5);
  }

  void dispose() {
    controller.close();
  }
}

void main() {
  test(
    'WorkerAtom should not capture the parent class when using a static worker',
    () async {
      final feature = FeatureWithUnsendableState();

      feature.trigger();

      // Wait for result with a timeout
      bool success = false;
      for (int i = 0; i < 20; i++) {
        if (feature.workerAtom.value.hasData) {
          success = true;
          break;
        }
        if (feature.workerAtom.value.hasError) {
          break;
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (feature.workerAtom.value.hasError) {
        final error = feature.workerAtom.value.errorOrNull.toString();
        print("VERIFIED FAILURE: $error");
        fail("WorkerAtom failed with error: $error");
      }

      expect(
        success,
        true,
        reason: "WorkerAtom should have completed with data",
      );
      print("SUCCESS: ${feature.workerAtom.value.dataOrNull}");

      feature.dispose();
    },
  );
}
