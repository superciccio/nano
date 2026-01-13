import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

// --- Components ---

class GridController extends NanoLogic<void> {
  // 100x100 grid of atoms
  late final List<List<Atom<int>>> grid;
  final int rows = 100;
  final int cols = 100;

  @override
  void onInit(void params) {
    grid = List.generate(
      rows,
      (r) => List.generate(cols, (c) => 0.toAtom(label: 'Cell-$r-$c')),
    );
  }

  void updateCell(int r, int c) {
    grid[r][c].increment();
  }

  void updateRow(int r) {
    Nano.batch(() {
      for (int c = 0; c < cols; c++) {
        grid[r][c].increment();
      }
    });
  }

  void updateAll() {
    Nano.batch(() {
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          grid[r][c].increment();
        }
      }
    });
  }
}

class CellWidget extends StatelessWidget {
  final Atom<int> atom;
  final VoidCallback onBuild;

  const CellWidget({Key? key, required this.atom, required this.onBuild})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AtomBuilder(
      atom: atom,
      builder: (context, value) {
        onBuild();
        return Text('$value');
      },
    );
  }
}

class SilentObserver implements NanoObserver {
  @override
  void onChange(Atom atom, dynamic oldValue, dynamic newValue) {}

  @override
  void onError(Atom atom, Object error, StackTrace stack) {
    print('Error in atom ${atom.label}: $error');
  }
}

void main() {
  testWidgets(
    'UI Stress Test: 10,000 Reactive Widgets',
    (tester) async {
      Nano.observer = SilentObserver();

      // 1. Setup
      final controller = GridController();
      controller.initialize(null);

      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: List.generate(
                  controller.rows,
                  (r) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                        controller.cols,
                        (c) => CellWidget(
                          atom: controller.grid[r][c],
                          onBuild: () => buildCount++,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Allow initial build to settle
      await tester.pumpAndSettle();
      print('Initial Build Complete. Total Builds: $buildCount');
      expect(buildCount, equals(10000)); // 100x100
      buildCount = 0; // Reset counter

      final stopwatch = Stopwatch();

      // 2. Single Cell Update
      stopwatch.start();
      controller.updateCell(50, 50);
      await tester.pump(); // Trigger frame
      stopwatch.stop();

      print('Single Cell Update Time: ${stopwatch.elapsedMilliseconds}ms');
      expect(buildCount, equals(1)); // Only 1 widget should rebuild
      buildCount = 0;
      stopwatch.reset();

      // 3. Row Update (100 cells)
      stopwatch.start();
      controller.updateRow(50);
      await tester.pump();
      stopwatch.stop();

      print('Row Update (100 cells) Time: ${stopwatch.elapsedMilliseconds}ms');
      expect(buildCount, equals(100));
      buildCount = 0;
      stopwatch.reset();

      // 4. Global Update (10,000 cells)
      // This is the heavy one.
      stopwatch.start();
      controller.updateAll();
      await tester.pump();
      stopwatch.stop();

      print(
        'Full Grid Update (10,000 cells) Time: ${stopwatch.elapsedMilliseconds}ms',
      );
      expect(buildCount, equals(10000));

      // Cleanup
      controller.dispose();
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
