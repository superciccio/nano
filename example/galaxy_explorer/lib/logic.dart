import 'dart:async';
import 'dart:math';
import 'dart:ui'; // For Color
import 'package:nano/nano.dart';

// -----------------------------------------------------------------------------
// 1. Resource Node (The "Leaf" - High Frequency Data)
// -----------------------------------------------------------------------------
class ResourceNode {
  final String name;
  final double max;
  final double generationRate; // Amount per tick

  // The high-frequency value
  late final value = Atom<double>(0.0);

  ResourceNode(this.name, {this.max = 1000.0, this.generationRate = 0.5});

  void tick() {
    if (value.value < max) {
      value.value = min(max, value.value + generationRate);
    }
  }

  void boost() {
    value.value = min(max, value.value + (max * 0.1)); // Boost 10%
  }
}

// -----------------------------------------------------------------------------
// 2. Planet Logic (The "Node" - Aggregator)
// -----------------------------------------------------------------------------
class PlanetLogic extends NanoLogic {
  final String id;
  late final name = Atom<String>("");
  late final type = Atom<String>("Unknown");

  // Physics & Visuals
  final double orbitRadius;
  final double orbitSpeed;
  final Color color;
  late final angle = Atom<double>(0.0);

  // Resources map
  final Map<String, ResourceNode> resources;

  PlanetLogic({
    required this.id,
    required String initialName,
    required String initialType,
    required this.orbitRadius,
    required this.orbitSpeed,
    required this.color,
    double initialAngle = 0.0,
    Map<String, ResourceNode>? initialResources,
  }) : resources =
           initialResources ??
           {
             'Oxygen': ResourceNode('Oxygen', max: 500, generationRate: 0.2),
             'Fuel': ResourceNode('Fuel', max: 2000, generationRate: 0.8),
             'Minerals': ResourceNode(
               'Minerals',
               max: 800,
               generationRate: 0.4,
             ),
           } {
    name.value = initialName;
    type.value = initialType;
    angle.value = initialAngle;
  }

  void tick() {
    // 1. Update Resources
    for (var resource in resources.values) {
      resource.tick();
    }
    // 2. Update Orbit Physics
    // Speed is in radians per tick
    angle.value = (angle.value + orbitSpeed) % (2 * pi);
  }
}

// -----------------------------------------------------------------------------
// 3. Universe Logic (The "Root" - Ticker System)
// -----------------------------------------------------------------------------
class UniverseLogic extends NanoLogic {
  Timer? _ticker;

  // Navigation State
  final activePlanet = Atom<PlanetLogic?>(null);

  // The Data
  final planets = Atom<List<PlanetLogic>>([]);

  // Computed Universe Totals (Aggregating live data)
  late final totalOxygen = ComputedAtom<double>(() {
    double sum = 0;
    // Note: This establishes dependencies on EVERY planet's oxygen atom.
    // In a massive universe, this would be expensive.
    // Here it demonstrates Nano's ability to handle complex trees.
    for (var p in planets.value) {
      sum += p.resources['Oxygen']?.value.value ?? 0;
    }
    return sum;
  });

  UniverseLogic() {
    _init();
  }

  void _init() {
    // Generate some planets with Orbits!
    planets.value = [
      PlanetLogic(
        id: '1',
        initialName: 'Xylos',
        initialType: 'Gas Giant',
        orbitRadius: 100,
        orbitSpeed: 0.005,
        initialAngle: 0.0,
        color: const Color(0xFFFFA500), // Orange
        initialResources: {
          'Oxygen': ResourceNode('Oxygen', generationRate: 1.5),
          'Fuel': ResourceNode('Fuel', generationRate: 2.0, max: 5000),
        },
      ),
      PlanetLogic(
        id: '2',
        initialName: 'Terra Nova',
        initialType: 'Habitable',
        orbitRadius: 160,
        orbitSpeed: 0.008,
        initialAngle: 2.0,
        color: const Color(0xFF00BFFF), // Blue
        initialResources: {
          'Oxygen': ResourceNode('Oxygen', generationRate: 0.1),
          'Fuel': ResourceNode('Fuel'),
        },
      ),
      PlanetLogic(
        id: '3',
        initialName: 'Kryon',
        initialType: 'Ice World',
        orbitRadius: 220,
        orbitSpeed: 0.003,
        initialAngle: 4.0,
        color: const Color(0xFFE0FFFF), // Cyan-ish
      ),
      PlanetLogic(
        id: '4',
        initialName: 'Magmos',
        initialType: 'Lava World',
        orbitRadius: 300,
        orbitSpeed: 0.006,
        initialAngle: 1.0,
        color: const Color(0xFFFF4500), // Red-Orange
      ),
      PlanetLogic(
        id: '5',
        initialName: 'Aether',
        initialType: 'Nebula Cloud',
        orbitRadius: 380,
        orbitSpeed: 0.002,
        initialAngle: 5.5,
        color: const Color(0xFF9370DB), // Purple
      ),
    ];

    // Start the Game Loop (60 ticks per second)
    _ticker = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
    status.value = NanoStatus.success;
  }

  void _tick() {
    // Update the simulation WITHOUT triggering UI rebuilds for the list structure
    // (Notice we don't change 'planets.value', we change inner atoms)
    for (var planet in planets.value) {
      planet.tick();
    }
  }

  void selectPlanet(PlanetLogic planet) {
    activePlanet.value = planet;
  }

  void closePlanet() {
    activePlanet.value = null;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
