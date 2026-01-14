import 'package:flutter/material.dart';
import 'package:nano_hub/core/demo_registry.dart';
import 'package:nano_hub/features/persistence/persistence_view.dart';

class PersistenceFeature {
  static void register() {
    DemoRegistry.register(
      DemoModule(
        id: 'persistence',
        title: 'Auto-Persistence',
        description: 'PersistAtom with automatic storage sync.',
        icon: Icons.save_outlined,
        builder: SettingsView(),
        version: 'v0.7.0',
      ),
    );
  }
}
