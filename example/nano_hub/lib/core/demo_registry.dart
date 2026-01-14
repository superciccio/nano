import 'package:flutter/material.dart';

/// Represents a single demo module in the Nano Hub.
class DemoModule {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Widget builder;
  final String version;

  const DemoModule({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.builder,
    required this.version,
  });
}

/// A central registry for all demo modules.
/// This allows for easy extensibility in future versions.
class DemoRegistry {
  static final List<DemoModule> _modules = [];

  static void register(DemoModule module) {
    print("?? REGISTRY: Registering ${module.id}");
    if (!_modules.any((m) => m.id == module.id)) {
      _modules.add(module);
    }
  }

  static List<DemoModule> get modules => List.unmodifiable(_modules);

  static DemoModule? findById(String id) =>
      _modules.firstWhere((m) => m.id == id);
}
