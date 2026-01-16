import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nano/core/nano_config.dart';
import 'package:nano/core/nano_core.dart';
import 'package:nano/core/debug_service.dart';
import 'package:nano/core/nano_di.dart'
    show Registry, NanoException, NanoFactory, NanoLazy;
import 'package:nano/core/nano_middleware.dart';

/// The Dependency Injection Container.
///
/// Wrap your App (or a specific feature) in this widget to provide dependencies.
///
/// Example:
/// ```dart
/// Scope(
///   config: NanoConfig(observer: MyObserver()),
///   modules: [
///     AuthService(), // Singleton (Eager)
///     NanoLazy((r) => Database()), // Singleton (Lazy)
///     NanoFactory((r) => LoginLogic()), // Factory (New instance per request)
///   ],
///   child: MyApp(),
/// )
/// ```
class Scope extends StatefulWidget {
  final List<Object> modules;
  final List<Object>? overrides;
  final Widget child;
  final NanoConfig? config;

  const Scope({
    super.key,
    required this.modules,
    required this.child,
    this.config,
    this.overrides,
  });

  @override
  State<Scope> createState() => _ScopeState();

  /// Explicit lookup for dependencies from the given [context].
  static Registry of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_InheritedScope>();
    if (scope == null) {
      throw NanoException(
        "No Scope found in the widget tree.\n"
        "👉 Fix: Wrap your MaterialApp or Feature in a Scope(modules: [...], child: ...)",
      );
    }
    return scope.registry;
  }

  /// Explicit lookup for configuration from the given [context].
  static NanoConfig? configOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_InheritedScope>();
    return scope?.config;
  }
}

class _ScopeState extends State<Scope> {
  late Registry _registry;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Find parent scope
    Registry? parentRegistry;
    try {
      final parentScope =
          context.dependOnInheritedWidgetOfExactType<_InheritedScope>();
      parentRegistry = parentScope?.registry;
    } catch (_) {}

    if (!_initialized) {
      _registry = Registry(parent: parentRegistry);
      _registerModules();
      _initialized = true;
    } else {
      _registry.parent = parentRegistry;
    }
  }

  void _registerModules() {
    Nano.init(); // Initialize Core
    NanoDebugService.init(); // Initialize DevTools Extensions
    for (var m in widget.modules) {
      _registerItem(m);
    }

    if (widget.overrides != null) {
      for (var o in widget.overrides!) {
        _registerItem(o);
      }
    }
  }

  void _registerItem(dynamic m) {
    // 1. Factories: Created every time .get() is called
    if (m is NanoFactory) {
      _registry.registerFactoryDynamic(m.type, (r) => m.create(r) as Object);
    }
    // 2. Lazy Singletons: Created only when first requested
    else if (m is NanoLazy) {
      _registry.registerLazySingletonDynamic(
        m.type,
        (r) => m.create(r) as Object,
      );
    }
    // 3. Eager Singletons: Created immediately
    else {
      _registry.register(m);
    }
  }

  @override
  void didUpdateWidget(Scope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.modules, widget.modules) ||
        !listEquals(oldWidget.overrides, widget.overrides) ||
        oldWidget.config != widget.config) {
      _registry.dispose();
      _registerModules();
    }
  }

  @override
  @override
  void dispose() {
    _registry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const SizedBox.shrink();

    // Calculate effective config (Inject TimelineMiddleware in debug)
    NanoConfig? effectiveConfig = widget.config;
    if (kDebugMode) {
      final middlewares = effectiveConfig?.middlewares ?? [];
      final hasTimeline = middlewares.any((m) => m is TimelineMiddleware);

      if (!hasTimeline) {
        effectiveConfig = NanoConfig(
          observer: effectiveConfig?.observer,
          storage: effectiveConfig?.storage,
          middlewares: [...middlewares, TimelineMiddleware()],
        );
      } else if (effectiveConfig == null) {
        // Should catch above, but explicit null handling
        effectiveConfig = NanoConfig(middlewares: [TimelineMiddleware()]);
      }
    }

    return _InheritedScope(
      registry: _registry,
      config: effectiveConfig ?? widget.config,
      child: widget.child,
    );
  }
}

class _InheritedScope extends InheritedWidget {
  final Registry registry;
  final NanoConfig? config;

  const _InheritedScope({
    required this.registry,
    this.config,
    required super.child,
  });

  @override
  bool updateShouldNotify(_InheritedScope oldWidget) =>
      registry != oldWidget.registry || config != oldWidget.config;
}
