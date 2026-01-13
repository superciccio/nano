import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';
import 'dart:async';

// --- Shared Components ---

class GridLogic extends NanoLogic<void> {
  late final List<Atom<int>> grid;

  @override
  void onInit(void params) {
    grid = List.generate(
      10000,
      (i) => 0.toAtom(label: 'Cell-$i'),
    );
  }

  void updateAll() {
    Nano.batch(() {
      for (int i = 0; i < 10000; i++) {
        grid[i].increment();
      }
    });
    notifyListeners();
  }
}

class CoarseGrid extends StatelessWidget {
  final GridLogic logic;
  final VoidCallback onBuild;

  const CoarseGrid({Key? key, required this.logic, required this.onBuild}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    onBuild(); // Track root rebuilds
    debugPrint('CoarseGrid Build! Version: ${Nano.version}');
    return SingleChildScrollView(
      child: Column(
        children: List.generate(
          10000,
          (i) => Text('${logic.grid[i].value}'),
        ),
      ),
    );
  }
}

class SurgicalGrid extends StatelessWidget {
  final GridLogic logic;
  final VoidCallback onBuild;

  const SurgicalGrid({Key? key, required this.logic, required this.onBuild}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    onBuild(); // Track root rebuilds (should only happen once)
    debugPrint('SurgicalGrid Build! Version: ${Nano.version}');
    return SingleChildScrollView(
      child: Column(
        children: List.generate(
          10000,
          (i) => Watch(logic.grid[i], builder: (context, value) => Text('$value')),
        ),
      ),
    );
  }
}

class SurgicalListView extends StatelessWidget {
  final GridLogic logic;
  final VoidCallback onBuild;

  const SurgicalListView({Key? key, required this.logic, required this.onBuild}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    onBuild(); // Track root rebuilds (should only happen once)
    debugPrint('SurgicalListView Build! Version: ${Nano.version}');
    return ListView.builder(
      itemCount: 10000,
      itemBuilder: (context, i) => Watch(logic.grid[i], builder: (context, value) => Text('$value')),
    );
  }
}

class SilentObserver implements NanoObserver {
  const SilentObserver();
  @override
  void onChange(Atom atom, dynamic oldValue, dynamic newValue) {}
  @override
  void onError(Atom atom, Object error, StackTrace stack) {}
}

void main() {


  testWidgets('Benchmark: Coarse vs Surgical (10,000 Widgets)', (tester) async {
    final config = NanoConfig(observer: const SilentObserver());
    
    await runZoned(() async {
      Nano.reset();
      
      tester.view.physicalSize = const Size(2000, 300000);
      addTearDown(() => tester.view.resetPhysicalSize());
      
      final logic = GridLogic();
      logic.initialize(null);

      int rootBuilds = 0;
      final sw = Stopwatch();

      debugPrint('\n--- SCENARIO A: COARSE (rebuildOnUpdate: true) ---');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Scope(
              modules: [],
              child: NanoView<GridLogic, void>(
                create: (_) => logic,
                autoDispose: false,
                rebuildOnUpdate: true,
                builder: (context, l) => CoarseGrid(logic: l, onBuild: () => rootBuilds++),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      debugPrint('Initial rootBuilds: $rootBuilds');

      rootBuilds = 0;
      sw.start();
      logic.updateAll();
      debugPrint('Updated atoms. Version: ${Nano.version}');
      await tester.pump();
      sw.stop();
      debugPrint('Coarse Global Update Time: ${sw.elapsedMilliseconds}ms');
      debugPrint('Coarse Root Rebuilds: $rootBuilds');
      expect(rootBuilds, 1); // Grid logic notifies once, root rebuilds once

      debugPrint('\n--- SCENARIO B: SURGICAL (rebuildOnUpdate: false) ---');
      rootBuilds = 0;
      sw.reset();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Scope(
              modules: [],
              child: NanoView<GridLogic, void>(
                create: (_) => logic,
                autoDispose: false,
                rebuildOnUpdate: false,
                builder: (context, l) => SurgicalGrid(logic: l, onBuild: () => rootBuilds++),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      debugPrint('Initial rootBuilds (Surgical): $rootBuilds');

      rootBuilds = 0;
      sw.start();
      logic.updateAll();
      debugPrint('Updated atoms (Surgical). Version: ${Nano.version}');
      await tester.pump();
      sw.stop();
      debugPrint('Surgical Global Update Time: ${sw.elapsedMilliseconds}ms');
      debugPrint('Surgical Root Rebuilds: $rootBuilds');
      expect(rootBuilds, 0); // Root should NOT rebuild

      debugPrint('\n--- SCENARIO C: SURGICAL LISTVIEW (rebuildOnUpdate: false) ---');
      rootBuilds = 0;
      sw.reset();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Scope(
              modules: [],
              child: NanoView<GridLogic, void>(
                create: (_) => logic,
                autoDispose: false,
                rebuildOnUpdate: false,
                builder: (context, l) => SurgicalListView(logic: l, onBuild: () => rootBuilds++),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      debugPrint('Initial rootBuilds (ListView): $rootBuilds');

      rootBuilds = 0;
      sw.start();
      logic.updateAll();
      debugPrint('Updated atoms (ListView). Version: ${Nano.version}');
      await tester.pump();
      sw.stop();
      debugPrint('Surgical ListView Update Time: ${sw.elapsedMilliseconds}ms');
      debugPrint('Surgical ListView Root Rebuilds: $rootBuilds');
      expect(rootBuilds, 0);

      debugPrint('\n--- SCENARIO D: SURGICAL LISTVIEW (Normal Viewport 800x600) ---');
      tester.view.physicalSize = const Size(800, 600);
      rootBuilds = 0;
      sw.reset();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Scope(
              modules: [],
              child: NanoView<GridLogic, void>(
                create: (_) => logic,
                autoDispose: false,
                rebuildOnUpdate: false,
                builder: (context, l) => SurgicalListView(logic: l, onBuild: () => rootBuilds++),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      debugPrint('Initial rootBuilds (Normal ListView): $rootBuilds');

      rootBuilds = 0;
      sw.start();
      logic.updateAll();
      debugPrint('Updated atoms (Normal ListView). Version: ${Nano.version}');
      await tester.pump();
      sw.stop();
      debugPrint('Surgical Normal ListView Update Time: ${sw.elapsedMilliseconds}ms');
      debugPrint('Surgical Normal ListView Root Rebuilds: $rootBuilds');
      expect(rootBuilds, 0);

      logic.dispose();
    }, zoneValues: {#nanoConfig: config});
  }, timeout: const Timeout(Duration(minutes: 5)));
}
