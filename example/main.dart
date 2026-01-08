import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nano/nano.dart';

void main() {
  runApp(const MyApp());
}

// 1. Define Logic with Typed Parameters
class WeatherLogic extends NanoLogic<String> {
  // Use Atom Call Magic!
  final temperature = Atom(0, label: 'temp');
  final condition = Atom('Sunny', label: 'condition');

  @override
  void onInit(String city) {
    fetchWeather(city);
  }

  Future<void> fetchWeather(String city) async {
    // Set status to loading using Call Magic
    status(NanoStatus.loading);

    // Simulate network request
    await Future.delayed(const Duration(seconds: 2));

    final random = Random();
    if (random.nextBool()) {
      // Success
      temperature(20 + random.nextInt(15)); // Set value
      condition(['Sunny', 'Cloudy', 'Rainy'][random.nextInt(3)]);
      status(NanoStatus.success);
    } else {
      // Error
      error('Failed to fetch weather for $city');
      status(NanoStatus.error);
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scope(
      modules: [
        // Register Logic Factory
        NanoFactory((r) => WeatherLogic()),
      ],
      child: const MaterialApp(
        home: WeatherPage(),
      ),
    );
  }
}

class WeatherPage extends StatelessWidget {
  const WeatherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nano Weather')),
      // 2. NanoView with Surgical State Switching
      body: Center(
        child: NanoView<WeatherLogic, String>(
          create: (r) => r.get<WeatherLogic>(),
          params: 'London', // Passed to onInit

          // Optional: Custom Loading Widget
          loading: (context) => const CircularProgressIndicator(),

          // Optional: Custom Error Widget
          error: (context, err) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              Text('Error: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.read<WeatherLogic>().fetchWeather('London'),
                child: const Text('Retry'),
              ),
            ],
          ),

          // Success Builder
          builder: (context, logic) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Surgical Watch
                Watch(logic.condition, builder: (context, cond) {
                  return Text(cond, style: Theme.of(context).textTheme.headlineMedium);
                }),
                Watch(logic.temperature, builder: (context, temp) {
                  return Text('${temp}°C', style: Theme.of(context).textTheme.displayLarge);
                }),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => logic.fetchWeather('London'),
                  child: const Text('Refresh'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
