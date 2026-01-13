import 'dart:math';
import 'package:nano/nano.dart';
import 'dart:async';

// --- Primitives ---
class Point {
  final double x, y;
  const Point(this.x, this.y);

  double dist(Point other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return sqrt(dx * dx + dy * dy);
  }

  @override
  String toString() => '(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})';
}

// --- Logic Classes ---

/// Represents a single entity in the simulation.
class Unit {
  final int id;
  final Atom<Point> position;
  final Atom<int> level;
  final Atom<double> nearestNeighborDist;

  // To cleanup reaction
  late final ReactionDisposer _disposer;

  Unit(this.id, Point startPos, Atom<List<Unit>> allUnits)
    : position = startPos.toAtom(label: 'Unit-$id-Pos'),
      level = 1.toAtom(label: 'Unit-$id-Lvl'),
      nearestNeighborDist = 0.0.toAtom(label: 'Unit-$id-Dist') {
    // Reactive Logic: Always keep nearestNeighborDist updated
    _disposer = autorun(() {
      final units = allUnits.value; // Track list changes
      final currentPos = position.value; // Track my pos

      double min = double.infinity;

      for (final other in units) {
        if (other == this) continue;
        // Track other's pos
        final d = currentPos.dist(other.position.value);
        if (d < min) min = d;
      }

      // Update state (only if changed, handled by Atom)
      if (min != double.infinity) {
        nearestNeighborDist.value = min;
      }
    });
  }

  void move(double dx, double dy) {
    position.value = Point(position.value.x + dx, position.value.y + dy);
  }

  void levelUp() {
    level.increment();
  }

  void dispose() {
    _disposer(); // Kill reaction
    position.dispose();
    level.dispose();
    nearestNeighborDist.dispose();
  }
}

/// Global Controller collecting stats.
class GlobalStats extends NanoLogic<void> {
  final Atom<List<Unit>> _unitsSource;

  // Derived state
  late final totalLevels = 0.toAtom(label: 'Global-TotalLevels');
  late final averageDistance = 0.0.toAtom(label: 'Global-AvgDist');

  ReactionDisposer? _disposer;

  GlobalStats(this._unitsSource);

  @override
  void onInit(void params) {
    // React to any change in the simulation to update stats
    _disposer = autorun(() {
      final units = _unitsSource.value;

      int levels = 0;
      double totalDist = 0.0;

      for (final u in units) {
        levels += u.level.value; // Track level changes
        totalDist += u.nearestNeighborDist.value; // Track dist changes
      }

      totalLevels.value = levels;
      averageDistance.value = units.isEmpty ? 0.0 : totalDist / units.length;

      debugLog(
        'STATS UPDATED: Levels=$levels, AvgDist=${averageDistance.value.toStringAsFixed(2)}',
      );
    });
  }

  @override
  void dispose() {
    _disposer?.call();
    super.dispose();
  }
}

/// Team Leader managing the units.
class TeamLeader extends NanoLogic<void> {
  final units = Atom<List<Unit>>([], label: 'Team-Units');
  final random = Random(42); // Seed for deterministic benchmark

  @override
  void onInit(void params) {
    debugLog('TeamLeader Initialized');
  }

  void spawnUnits(int count) {
    final current = [...units.value];
    for (int i = 0; i < count; i++) {
      final id = current.length + 1;
      final pos = Point(random.nextDouble() * 100, random.nextDouble() * 100);
      current.add(Unit(id, pos, units)); // Pass the atom itself for tracking
    }
    units.value = current;
    debugLog('Spawned $count units. Total: ${units.value.length}');
  }

  void removeRandomUnits(int count) {
    final current = [...units.value];
    for (int i = 0; i < count; i++) {
      if (current.isNotEmpty) {
        final index = random.nextInt(current.length);
        final removed = current.removeAt(index);
        removed.dispose(); // Cleanup!
      }
    }
    units.value = current;
    debugLog('Removed $count units. Total: ${units.value.length}');
  }

  void tick() {
    // Batch update: Move everyone slightly
    for (final unit in units.value) {
      unit.move(
        (random.nextDouble() - 0.5) * 2,
        (random.nextDouble() - 0.5) * 2,
      );
    }
  }

  void triggerLevelUps(int count) {
    final list = units.value;
    for (int i = 0; i < count; i++) {
      list[random.nextInt(list.length)].levelUp();
    }
  }

  @override
  void dispose() {
    for (final u in units.value) u.dispose();
    super.dispose();
  }
}

class SilentObserver implements NanoObserver {
  @override
  void onChange(Atom atom, dynamic oldValue, dynamic newValue) {}

  @override
  void onError(Atom atom, Object error, StackTrace stack) {
    print('ERROR in ${atom.label}: $error');
  }
}

// --- Utils ---
void debugLog(String msg) {
  // Using print for CLI output
  print('[${DateTime.now().toIso8601String().substring(11, 19)}] $msg');
}

// --- Main Benchmark ---
void main() {
  final config = NanoConfig(observer: SilentObserver());

  runZoned(() {
    debugLog('--- STARTING STRESS TEST ---');
    final stopwatch = Stopwatch()..start();

    // 1. Setup Nodes
    final leader = TeamLeader();
    leader.initialize(null);

    final stats = GlobalStats(leader.units);
    stats.initialize(null);

    // 2. Spawn 50 Units
    measure('Spawn 50', () {
      leader.spawnUnits(50);
    });

    // 3. Tick Loop (Concurrent Mutations)
    measure('Tick 10 Times', () {
      for (int i = 0; i < 10; i++) {
        leader.tick();
      }
    });

    // 4. Dynamic Resource Management
    measure('Add 10 Units', () {
      leader.spawnUnits(10);
    });

    measure('Tick 5 Times (60 Units)', () {
      for (int i = 0; i < 5; i++) {
        leader.tick();
      }
    });

    measure('Remove 20 Units', () {
      leader.removeRandomUnits(20);
    });

    measure('Tick 5 Times (40 Units)', () {
      for (int i = 0; i < 5; i++) {
        leader.tick();
      }
    });

    // 5. State Propagation (Level Ups)
    measure('Level Up 50 times', () {
      leader.triggerLevelUps(50);
    });

    debugLog('--- FINISHED in ${stopwatch.elapsedMilliseconds}ms ---');

    leader.dispose();
    stats.dispose();
  }, zoneValues: {#nanoConfig: config});
}

void measure(String label, void Function() task) {
  final sw = Stopwatch()..start();
  task();
  sw.stop();
  debugLog('BENCHMARK [$label]: ${sw.elapsedMilliseconds}ms');

  if (sw.elapsedMilliseconds > 500) {
    debugLog('WARNING: High latency detected in $label');
  }
}
