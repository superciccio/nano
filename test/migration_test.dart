import 'package:flutter/material.dart';

// This is a fake provider usage for testing the structural lint
class MyProviderWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final myValue = Provider.of<String>(context);
    
    return Consumer<String>(
      builder: (context, value, child) {
        return Text(value);
      },
    );
  }
}

// This is a fake signals usage
void testSignals() {
  final mySignal = signal(0);
  final myComputed = computed(() => mySignal.value * 2);
}

// Mocking some names so the file is syntactically valid enough for the analyzer
class Provider {
  static T of<T>(BuildContext context) => throw UnimplementedError();
}
class Consumer<T> extends StatelessWidget {
  final Widget Function(BuildContext, T, Widget?) builder;
  Consumer({required this.builder});
  @override
  Widget build(BuildContext context) => throw UnimplementedError();
}
dynamic signal(dynamic val) => val;
dynamic computed(dynamic fn) => fn;
