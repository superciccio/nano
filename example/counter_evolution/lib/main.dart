import 'package:flutter/material.dart';
import 'package:nano/nano.dart';
import 'classic_counter.dart';
import 'modern_counter.dart';
import 'services.dart';

void main() {
  runApp(
    Scope(
      modules: [
        ServiceA(),
        ServiceB(),
        ServiceC(),
      ],
      child: const MaterialApp(home: EvolutionScreen()),
    ),
  );
}

class EvolutionScreen extends StatelessWidget {
  const EvolutionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nano Evolution')),
      body: const Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Padding(
                 padding: EdgeInsets.all(16.0),
                 child: Text(
                   'This example demonstrates how Classic and Modern Nano can coexist in the same application.',
                   textAlign: TextAlign.center,
                 ),
               ),
               SizedBox(height: 20),
               ClassicCounter(),
               SizedBox(height: 20),
               Icon(Icons.arrow_downward),
               SizedBox(height: 20),
               ModernCounter(),
            ],
          ),
        ),
      ),
    );
  }
}
