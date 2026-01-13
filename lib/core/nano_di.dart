import 'package:flutter/foundation.dart';

/// A simple registry to hold your dependencies.
///
/// Used by [Scope] to provide dependencies to [View].
///
/// Example:
/// ```dart
/// final registry = Registry();
/// registry.register<AuthService>(AuthService());
/// final auth = registry.get<AuthService>();
/// ```
class Registry with Diagnosticable {
  Registry? _parent;
  Registry? get parent => _parent;
  set parent(Registry? value) => _parent = value;
  final Map<Type, Object> _services = {};
  final Map<Type, Object Function(Registry)> _factories = {};
  final Map<Type, Object Function(Registry)> _lazySingletons = {};

  /// [Internal] Stack of types currently being resolved to detect circular dependencies.
  final List<Type> _lookupStack = [];

  Registry({Registry? parent}) : _parent = parent;

  /// Registers an [instance] of type [T].
  void register<T>(T instance) {
    final type = T != dynamic && T != Object ? T : instance.runtimeType;
    _services[type] = instance as Object;
  }

  /// Registers a factory that creates a new instance of [T] every time.
  void registerFactory<T>(T Function(Registry) factory) {
    _factories[T] = (r) => factory(r) as Object;
  }

  /// Registers a factory with explicit [type].
  void registerFactoryDynamic(Type type, Object Function(Registry) factory) {
    _factories[type] = factory;
  }

  /// Registers a lazy singleton that is created on first read.
  void registerLazySingleton<T>(T Function(Registry) factory) {
    _lazySingletons[T] = (r) => factory(r) as Object;
  }

  /// Registers a lazy singleton with explicit [type].
  void registerLazySingletonDynamic(
    Type type,
    Object Function(Registry) factory,
  ) {
    _lazySingletons[type] = factory;
  }

  /// Retrieves the registered instance of type [T].
  ///
  /// Throws [NanoException] if the type is not registered.
  T get<T>() {
    if (_lookupStack.contains(T)) {
      throw NanoException(
        "Circular dependency detected while resolving '${T.toString()}'.\n"
        "👉 Chain: ${_lookupStack.join(' -> ')} -> ${T.toString()}",
      );
    }

    _lookupStack.add(T);
    try {
      // 1. Check existing instances
      if (_services.containsKey(T)) {
        return _services[T] as T;
      }

      // 2. Check Factories (create new)
      if (_factories.containsKey(T)) {
        return _factories[T]!(this) as T;
      }

      // 3. Check Lazy Singletons (create, cache, return)
      if (_lazySingletons.containsKey(T)) {
        final instance = _lazySingletons[T]!(this);
        _services[T] = instance; // Cache it!
        _lazySingletons.remove(T); // Optimization: remove from lazy map
        return instance as T;
      }

      // 4. Try Parent
      if (parent != null) {
        return parent!.get<T>();
      }

      throw NanoException(
        "Service of type '${T.toString()}' not found in the current Scope.\n"
        "👉 Fix: Ensure you added '${T.toString()}' to the 'modules' list in your Scope widget.",
      );
    } finally {
      _lookupStack.removeLast();
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    for (final entry in _services.entries) {
      properties.add(DiagnosticsProperty(entry.key.toString(), entry.value));
    }
    for (final key in _factories.keys) {
      properties.add(DiagnosticsProperty('Factory<$key>', 'Function'));
    }
    for (final key in _lazySingletons.keys) {
      properties.add(DiagnosticsProperty('Lazy<$key>', 'Pending...'));
    }
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      'Registry(services: ${_services.keys}, factories: ${_factories.keys}, lazy: ${_lazySingletons.keys})';
}

/// Specialized exception for Nano-related errors.
class NanoException implements Exception {
  final String message;
  NanoException(this.message);
  @override
  String toString() => "NanoException: $message";
}

/// Wrapper for Factory registration (new instance every time).
class NanoFactory<T> {
  final T Function(Registry) create;
  Type get type => T;
  NanoFactory(this.create);
}

/// Wrapper for Lazy Singleton registration (created on first read).
class NanoLazy<T> {
  final T Function(Registry) create;
  Type get type => T;
  NanoLazy(this.create);
}
