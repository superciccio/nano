import 'package:flutter/material.dart';

class VanillaCounter extends StatefulWidget {
  const VanillaCounter({super.key});

  @override
  State<VanillaCounter> createState() => _VanillaCounterState();
}

class _VanillaCounterState extends State<VanillaCounter> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vanilla Flutter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        heroTag: 'vanilla_fab',
        child: const Icon(Icons.add),
      ),
    );
  }
}
