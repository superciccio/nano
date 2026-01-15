import 'package:flutter/material.dart';
import 'dart:math'; // For cos, sin, pi
import 'package:nano/nano.dart';
import 'logic.dart';

void main() {
  runApp(const GalaxyApp());
}

class GalaxyApp extends StatelessWidget {
  const GalaxyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scope(
      // 👈 FIX: Register the Logic in the Scope so children can find it
      modules: [UniverseLogic()],
      child: MaterialApp(
        title: 'Nano Galaxy Explorer',
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.cyan,
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF0B0D12),
          cardColor: const Color(0xFF1E222D),
        ),
        home: const GalaxyScreen(),
      ),
    );
  }
}

class GalaxyScreen extends StatelessWidget {
  const GalaxyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We access logic via context or inherit it
    final logic = context.read<UniverseLogic>();

    return NanoPage(
      title: Row(
        children: [
          const Icon(Icons.public, color: Colors.cyanAccent),
          const SizedBox(width: 8),
          const Text("Universe Map"),
          const Spacer(),
          // Surgical Update: Universe Total Oxygen
          // This updates 60 times a second but only this Text widget rebuilds!
          const Icon(Icons.air, size: 16, color: Colors.blueGrey),
          const SizedBox(width: 4),
          logic.totalOxygen.watch((context, total) {
            return Text(
              total.toStringAsFixed(0),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            );
          }),
        ],
      ),
      body: Stack(
        children: [
          // 1. The Galaxy Map (Always visible in background)
          const GalaxyMap(),

          // 2. The Planet Detail Overlay (Slide in)
          logic.activePlanet.watch((context, active) {
            if (active == null) return const SizedBox.shrink();

            // In a real app we'd use a Navigator or AnimatedPositioned
            // Here we use a simple full-screen overlay for simplicity
            return Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: PlanetDetailView(planet: active),
            );
          }),
        ],
      ),
    );
  }
}

class GalaxyMap extends StatelessWidget {
  const GalaxyMap({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = context.read<UniverseLogic>();

    return logic.planets.watch((context, planets) {
      if (planets.isEmpty) return const SizedBox();

      return LayoutBuilder(
        builder: (context, constraints) {
          final center = Offset(
            constraints.maxWidth / 2,
            constraints.maxHeight / 2,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Orbital Rings (Background)
              CustomPaint(
                painter: GalaxyOrbitPainter(planets: planets, center: center),
              ),

              // 2. The Sun (Center)
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.yellow.withValues(alpha: 0.6),
                        blurRadius: 50,
                        spreadRadius: 20,
                      ),
                    ],
                    gradient: RadialGradient(
                      colors: [Colors.white, Colors.orange, Colors.red],
                      stops: const [0.1, 0.4, 1.0],
                    ),
                  ),
                ),
              ),

              // 3. Planets (Positioned)
              for (var planet in planets)
                planet.angle.watch((context, angle) {
                  // Polar to Cartesian conversion
                  // dx = r * cos(theta)
                  // dy = r * sin(theta)
                  final dx = center.dx + planet.orbitRadius * cos(angle);
                  final dy = center.dy + planet.orbitRadius * sin(angle);

                  return Positioned(
                    left: dx - 20, // Center the 40px widget
                    top: dy - 20,
                    child: _InteractivePlanet(planet: planet),
                  );
                }),
            ],
          );
        },
      );
    });
  }
}

class GalaxyOrbitPainter extends CustomPainter {
  final List<PlanetLogic> planets;
  final Offset center;

  GalaxyOrbitPainter({required this.planets, required this.center});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var planet in planets) {
      canvas.drawCircle(center, planet.orbitRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant GalaxyOrbitPainter oldDelegate) => false;
}

class _InteractivePlanet extends StatelessWidget {
  final PlanetLogic planet;
  const _InteractivePlanet({required this.planet});

  @override
  Widget build(BuildContext context) {
    final universe = context.read<UniverseLogic>();

    return GestureDetector(
      onTap: () => universe.selectPlanet(planet),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: planet.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: planet.color.withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.8),
            width: 2,
          ),
        ),
        child: Center(
          child: planet.resources['Oxygen']!.value.watch((context, val) {
            // Tiny indicator of life/activity
            return Container(
              width: 4 + (val / 500 * 10).clamp(0, 10),
              height: 4 + (val / 500 * 10).clamp(0, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ),
    );
  }
}

class PlanetCard extends StatelessWidget {
  final PlanetLogic planet;
  const PlanetCard({super.key, required this.planet});

  @override
  Widget build(BuildContext context) {
    final universe = context.read<UniverseLogic>();
    return Card(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: () => universe.selectPlanet(planet),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Static Name (or slowly changing)
              planet.name.watch(
                (context, name) => Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Text(
                planet.type.value,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
              const Spacer(),

              // Dynamic Resource Preview (Oxygen)
              _ResourceRowMini(
                icon: Icons.air,
                color: Colors.cyanAccent,
                resource: planet.resources['Oxygen']!,
              ),
              const SizedBox(height: 4),
              _ResourceRowMini(
                icon: Icons.local_fire_department,
                color: Colors.orangeAccent,
                resource: planet.resources['Fuel'] ?? ResourceNode('MISSING'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResourceRowMini extends StatelessWidget {
  final IconData icon;
  final Color color;
  final ResourceNode resource;

  const _ResourceRowMini({
    required this.icon,
    required this.color,
    required this.resource,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        // SURGICAL UPDATE: Nested Watch
        resource.value.watch((context, val) {
          return Text(
            val.toStringAsFixed(1),
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          );
        }),
      ],
    );
  }
}

class PlanetDetailView extends StatelessWidget {
  final PlanetLogic planet;
  const PlanetDetailView({super.key, required this.planet});

  @override
  Widget build(BuildContext context) {
    final universe = context.read<UniverseLogic>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => universe.closePlanet(),
        ),
        title: planet.name.watch((context, name) => Text(name)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Demo: Rename planet
              planet.name.value = "${planet.name.value} Prime";
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Header
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue.shade900, Colors.purple.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.blueAccent, blurRadius: 20),
                ],
              ),
              child: const Icon(Icons.public, size: 60, color: Colors.white),
            ),
          ),
          const SizedBox(height: 32),

          Text(
            "RESOURCES",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Resource Monitors
          ...planet.resources.entries.map((e) {
            return _ResourceMonitorTile(name: e.key, node: e.value);
          }),
        ],
      ),
    );
  }
}

class _ResourceMonitorTile extends StatelessWidget {
  final String name;
  final ResourceNode node;
  const _ResourceMonitorTile({required this.name, required this.node});

  @override
  Widget build(BuildContext context) {
    // We only watch the node value here
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2335),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  "+${node.generationRate}/tick",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // The Value Display (Updates heavily)
          node.value.watch((context, val) {
            final pct = (val / node.max).clamp(0.0, 1.0);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  val.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 20,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 100,
                  height: 4,
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: Colors.black,
                    valueColor: const AlwaysStoppedAnimation(Colors.cyanAccent),
                  ),
                ),
              ],
            );
          }),

          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.bolt, color: Colors.yellowAccent),
            onPressed: node.boost,
          ),
        ],
      ),
    );
  }
}
