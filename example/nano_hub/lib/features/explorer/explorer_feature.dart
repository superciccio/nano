import 'package:flutter/material.dart';
import 'package:nano_hub/core/demo_registry.dart';
import 'package:nano_hub/features/explorer/explorer_view.dart';

class ExplorerFeature {
  static void register() {
    DemoRegistry.register(
      DemoModule(
        id: 'explorer',
        title: 'Device Explorer',
        description: 'AtomFamily for dynamic keyed state.',
        icon: Icons.explore_outlined,
        builder: ExplorerView(),
        version: 'v0.7.0',
      ),
    );
  }
}
