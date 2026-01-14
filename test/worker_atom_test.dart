import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

/// Top-level function for WorkerAtom verification to ensure sendability.
int heavyTask(int input) {
  return input * 2;
}

/// Top-level function that throws for verification.
int errorTask(int input) {
  throw Exception('Boom');
}

void main() {
  group('WorkerAtom', () {
    test('executes task in background and returns AsyncData', () async {
      final source = Atom(10);
      final worker = WorkerAtom<int, int>(source, heavyTask);

      expect(worker.value.isLoading, true);

      // We need to wait for the isolate to complete and the microtask to flush
      await Future.delayed(const Duration(milliseconds: 50));

      expect(worker.value.hasData, true);
      expect(worker.value.dataOrNull, 20);
    });

    test('re-runs when source changes', () async {
      final source = Atom(10);
      final worker = WorkerAtom<int, int>(source, heavyTask);

      // Wait for initial run
      await Future.delayed(const Duration(milliseconds: 50));
      expect(worker.value.dataOrNull, 20);

      // Change source
      source.value = 50;
      expect(worker.value.isLoading, true);

      // Wait for second run
      await Future.delayed(const Duration(milliseconds: 50));
      expect(worker.value.dataOrNull, 100);
    });

    test('handles errors in worker task', () async {
      final source = Atom(0);
      final worker = WorkerAtom<int, int>(source, errorTask);

      await Future.delayed(const Duration(milliseconds: 50));

      expect(worker.value.hasError, true);
      expect(worker.value.errorOrNull.toString(), contains('Boom'));
    });

    test('disposes listener on dispose', () async {
      final source = Atom(1);
      final worker = WorkerAtom<int, int>(source, heavyTask);

      await Future.delayed(const Duration(milliseconds: 50));
      expect(worker.value.dataOrNull, 2);

      worker.dispose();

      source.value = 10;
      await Future.delayed(const Duration(milliseconds: 50));

      // Should NOT have updated
      expect(worker.value.dataOrNull, 2);
    });
  });
}
