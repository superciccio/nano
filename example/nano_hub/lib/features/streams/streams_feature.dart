import 'package:flutter/material.dart';
import 'package:nano_hub/core/demo_registry.dart';
import 'package:nano_hub/features/streams/streams_view.dart';

class StreamsFeature {
  static void register() {
    DemoRegistry.register(
      DemoModule(
        id: 'streams',
        title: 'Real-time Data',
        description: 'ResourceAtom lifecycle & Isolate Workers.',
        icon: Icons.speed,
        builder: SensorStreamView(),
        version: 'v0.7.0',
      ),
    );
  }
}
