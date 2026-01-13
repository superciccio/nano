// ignore_for_file: avoid_atom_outside_logic
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';
import 'dart:async';

// --- Graph Logic ---

class Node {
  final int layer;
  final int index;
  late final Atom<int> atom;
  late final ReactionDisposer? _disposer;

  // Input Node
  Node.input(this.layer, this.index) : _disposer = null {
    atom = 0.toAtom(label: 'Node-$layer-$index');
  }

  // Computed Node (Simulated manually for raw perf testing, or using autorun)
  Node.computed(this.layer, this.index, List<Node> dependencies) {
    atom = 0.toAtom(label: 'Node-$layer-$index');

    // We use autorun to simulate a ComputedAtom effect.
    // In a real spreadsheet, this would be the cell formula.
    _disposer = autorun(() {
      int sum = 0;
      for (final dep in dependencies) {
        sum += dep.atom.value;
      }
      atom.value = sum;
    });
  }

  void dispose() {
    _disposer?.call();
    atom.dispose();
  }
}

class GraphBenchmark {
  final int layers;
  final int width;
  final List<List<Node>> graph = [];

  GraphBenchmark(this.layers, this.width);

  void build() {
    // Layer 0: Inputs
    graph.add(List.generate(width, (i) => Node.input(0, i)));

    // Layer 1..N: Computed
    for (int l = 1; l < layers; l++) {
      final layerNodes = <Node>[];
      for (int i = 0; i < width; i++) {
        // Dependencies: Each node depends on node [i] and node [(i+1)%width] from previous layer
        final prevLayer = graph[l - 1];
        final deps = [prevLayer[i], prevLayer[(i + 1) % width]];
        layerNodes.add(Node.computed(l, i, deps));
      }
      graph.add(layerNodes);
    }
  }

  void updateInput(int index) {
    graph[0][index].atom.increment();
  }

  void updateAllInputs() {
    Nano.batch(() {
      for (var node in graph[0]) {
        node.atom.increment();
      }
    });
  }

  void dispose() {
    for (final layer in graph) {
      for (final node in layer) {
        node.dispose();
      }
    }
  }
}

class SilentObserver implements NanoObserver {
  @override
  void onChange(Atom atom, dynamic oldValue, dynamic newValue) {}

  @override
  void onError(Atom atom, Object error, StackTrace stack) {}
}

// --- Benchmark Runner ---

void main() {
  test(
    'Graph Logic Benchmark: 10 Layers x 10 Width (100 Nodes)',
    () {
      final config = NanoConfig(observer: SilentObserver());

      runZoned(() {
        print('--- LOGIC BENCHMARK: 10 Layers x 10 Width (100 Nodes) ---');

        final benchmark = GraphBenchmark(10, 10);

        final setupSw = Stopwatch()..start();
        benchmark.build();
        setupSw.stop();
        print('Graph Build Time: ${setupSw.elapsedMilliseconds}ms');

        // Warmup
        print('Warming up JIT...');
        for (int i = 0; i < 100; i++) {
          benchmark.updateInput(i % 10);
        }

        // Measure Propagation
        final sw = Stopwatch();

        sw.start();
        for (int i = 0; i < 1000; i++) {
          benchmark.updateInput(i % 10);
        }
        sw.stop();
        print(
          '1000 Single Input Updates: ${sw.elapsedMilliseconds}ms (${(sw.elapsedMilliseconds / 1000).toStringAsFixed(3)}ms/op)',
        );

        sw.reset();

        sw.start();
        for (int i = 0; i < 100; i++) {
          benchmark.updateAllInputs();
        }
        sw.stop();
        print(
          '100 Full Graph Updates: ${sw.elapsedMilliseconds}ms (${(sw.elapsedMilliseconds / 100).toStringAsFixed(3)}ms/op)',
        );

        benchmark.dispose();
      }, zoneValues: {#nanoConfig: config});
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
