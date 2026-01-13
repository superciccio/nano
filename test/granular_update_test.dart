import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

// Helper to disable logging for performance tests
class SilentObserver implements NanoObserver {
  @override
  void onChange(Atom atom, dynamic oldValue, dynamic newValue) {}
  @override
  void onError(Atom atom, Object error, StackTrace stack) {}
}

void main() {
  test('Granular Updates Benchmark: Scattered vs Row', () {
    Nano.observer = SilentObserver();

    final int rows = 100;
    final int cols = 100;
    // Create 10,000 atoms
    final grid = List.generate(
      rows,
      (r) => List.generate(cols, (c) => 0.toAtom(label: 'Cell-$r-$c')),
    );

    // Ensure we have listeners or else notifyListeners might be too cheap (no-op)
    // In real app, widgets listen.
    for (var row in grid) {
      for (var atom in row) {
        atom.addListener(() {}); // Dummy listener
      }
    }

    final random = Random(42);
    final stopwatch = Stopwatch();

    // 1. Scattered Updates: Update 1000 random cells
    // This tests the overhead of "finding" and adding unique atoms to the batch list.
    stopwatch.start();
    Nano.batch(() {
      for (int i = 0; i < 1000; i++) {
        final r = random.nextInt(rows);
        final c = random.nextInt(cols);
        grid[r][c].increment();
      }
    });
    stopwatch.stop();
    print(
      'Scattered Updates (1000 random): ${stopwatch.elapsedMicroseconds}µs',
    );

    stopwatch.reset();

    // 2. Row Updates: Update 100 cells in the same row
    // This tests localized updates.
    stopwatch.start();
    Nano.batch(() {
      for (int c = 0; c < cols; c++) {
        grid[50][c].increment();
      }
    });
    stopwatch.stop();
    print('Row Update (100 contiguous): ${stopwatch.elapsedMicroseconds}µs');

    stopwatch.reset();

    // 3. Same Cell Repeated Updates
    // This tests the dirty flag deduplication efficiency.
    // Update same cell 1000 times. Should only add to list once.
    stopwatch.start();
    Nano.batch(() {
      final cell = grid[0][0];
      for (int i = 0; i < 1000; i++) {
        cell.increment();
      }
    });
    stopwatch.stop();
    print(
      'Single Cell Repeated (1000 times): ${stopwatch.elapsedMicroseconds}µs',
    );
  });
}
