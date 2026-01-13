import 'dart:async'; // Add async import for runZoned

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:nano/core/nano_config.dart'; // Import NanoConfig
import 'package:nano/core/nano_core.dart';
import 'package:nano/core/nano_di.dart'
    show Registry, NanoException, NanoFactory, NanoLazy;
import 'package:nano/core/nano_logic.dart' show NanoLogic, NanoStatus;
import 'package:nano/core/nano_middleware.dart'; // Import Middleware

/// The Dependency Injection Container.
///
/// Wrap your App (or a specific feature) in this widget to provide dependencies.
///
/// Example:
/// ```dart
/// Scope(
///   config: NanoConfig(observer: MyObserver()),
///   modules: [
///     AuthService(),
///     Database(),
///   ],
///   child: MyApp(),
/// )
/// ```
class Scope extends StatefulWidget {
  final List<Object> modules;
  final Widget child;
  final NanoConfig? config;

  const Scope({
    super.key,
    required this.modules,
    required this.child,
    this.config,
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
      final parentScope = context
          .dependOnInheritedWidgetOfExactType<_InheritedScope>();
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
    Nano.init();
    for (var m in widget.modules) {
      if (m is NanoFactory) {
        _registry.registerFactoryDynamic(m.type, (r) => m.create(r) as Object);
      } else if (m is NanoLazy) {
        _registry.registerLazySingletonDynamic(
          m.type,
          (r) => m.create(r) as Object,
        );
      } else {
        _registry.register(m);
      }
    }
  }

  @override
  void didUpdateWidget(Scope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.modules, widget.modules) ||
        oldWidget.config != widget.config) {
      _registry.clear();
      _registerModules();
    }
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

/// The Smart View Widget.
///
/// 1. Creates your [NanoLogic] using the [Registry].
/// 2. Manages Lifecycle (`onInit`, `dispose`).
///
/// By default, it listens to the entire [NanoLogic] (via `notifyListeners`).
/// For surgical rebuilds, use [Watch].
///
/// Example:
/// ```dart
/// NanoView<CounterLogic, void>(
///   create: (reg) => CounterLogic(),
///   builder: (context, logic) {
///     return Text('${logic.counter.value}');
///   },
/// )
/// ```
class NanoView<T extends NanoLogic<P>, P> extends StatefulWidget {
  /// Factory to create the [NanoLogic]. Injects the [Registry] for DI.
  final T Function(Registry reg) create;

  /// The UI Builder.
  final Widget Function(BuildContext context, T logic) builder;

  /// Parameters to pass to logic.onInit
  final P? params;

  /// Optional builder for loading state. If not provided, the main [builder]
  /// will be used during the loading state.
  final Widget Function(BuildContext context)? loading;

  /// Optional builder for error state
  final Widget Function(BuildContext context, Object? error)? error;

  /// Optional builder for empty state
  final Widget Function(BuildContext context)? empty;

  /// Whether to automatically dispose the logic when the view is disposed.
  /// Defaults to true.
  final bool autoDispose;

  /// Whether the view should rebuild whenever the logic notifies listeners.
  ///
  /// - `true` (Default): Coarse updates. The entire [builder] runs on every change.
  ///   Best for small views or when you don't want to use [Watch] everywhere.
  /// - `false`: Surgical updates. The [builder] runs ONLY when [status] changes.
  ///   You MUST use [Watch] or `.watch()` inside the builder to react to other atoms.
  ///   Highly recommended for massive lists or complex screens.
  final bool rebuildOnUpdate;

  const NanoView({
    super.key,
    required this.create,
    required this.builder,
    this.params,
    this.loading,
    this.error,
    this.empty,
    this.autoDispose = true,
    this.rebuildOnUpdate = true,
  });

  @override
  State<NanoView<T, P>> createState() => _NanoViewState<T, P>();
}

class _NanoViewState<T extends NanoLogic<P>, P> extends State<NanoView<T, P>> {
  T? _logic;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    // This makes the logic object (CounterLogic / DogLogic)
    // show up as a property when you select the View widget!
    properties.add(DiagnosticsProperty('logic', _logic));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize Logic if not already done.
    // We do this here to ensure 'context' (and Scope) is available.
    if (_logic == null) {
      _initLogic();
    }
  }

  void _initLogic() {
    try {
      final registry = Scope.of(context);
      final config = Scope.configOf(context);

      // We run the creation and initialization in the zone 
      // so that if they access Nano.observer immediately, it works.
      runZoned(() {
        _logic = widget.create(registry);
        // We force cast params to P because if P is non-nullable,
        // the user MUST have provided params (checked statically or runtime failure).
        // But if P is dynamic/void/nullable, null is fine.
        _logic!.initialize(widget.params as P);
      }, zoneValues: {#nanoConfig: config});
    } catch (e, s) {
      Nano.observer.onError(
        Atom(null, label: 'NanoViewInit<${T.toString()}>'),
        e,
        s,
      );
      rethrow;
    }
  }

  void _disposeLogic() {
    if (widget.autoDispose) {
      _logic?.dispose();
    }
    _logic = null;
  }

  @override
  void dispose() {
    _disposeLogic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_logic == null) return const SizedBox.shrink(); // Safety guard

    // Encapsulate the status-based builder logic
    Widget buildContent() {
      return Watch<NanoStatus>(
        _logic!.status,
        builder: (context, status) {
          return switch (status) {
            NanoStatus.loading =>
              widget.loading?.call(context) ?? widget.builder(context, _logic!),
            NanoStatus.success => widget.builder(context, _logic!),
            NanoStatus.error =>
              widget.error?.call(context, _logic!.error.value) ??
                  const SizedBox.shrink(),
            NanoStatus.empty =>
              widget.empty?.call(context) ?? const SizedBox.shrink(),
          };
        },
      );
    }

    final config = Scope.configOf(context);
    // We wrap the build in runZoned so that any closures created (e.g. onPressed)
    // capture the zone with the config.
    return runZoned(
      () {
        if (widget.rebuildOnUpdate) {
          return ListenableBuilder(
            listenable: _logic!,
            builder: (context, _) => buildContent(),
          );
        } else {
          return buildContent();
        }
      },
      zoneValues: {#nanoConfig: config},
    );
  }
}

/// Surgical rebuilds.
///
/// Only rebuilds this widget when the specific [ValueListenable] (usually an
/// [Atom] or [ComputedAtom]) changes.
///
/// This widget is highly optimized. It is a [StatefulWidget] that listens
/// directly to the atom, avoiding the overhead of extra widget layers like
/// `ValueListenableBuilder`.
///
/// Example:
/// ```dart
/// Watch(logic.counter, builder: (context, value) {
///   return Text('$value');
/// })
/// ```
class Watch<T> extends StatefulWidget {
  /// The [ValueListenable] (usually an [Atom] or [ComputedAtom]) to watch.
  final ValueListenable<T> atom;

  /// The UI Builder.
  final Widget Function(BuildContext context, T value) builder;

  const Watch(this.atom, {super.key, required this.builder});

  @override
  State<Watch<T>> createState() => _WatchState<T>();
}

class _WatchState<T> extends State<Watch<T>> {
  @override
  void initState() {
    super.initState();
    widget.atom.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(Watch<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.atom != widget.atom) {
      oldWidget.atom.removeListener(_handleChange);
      widget.atom.addListener(_handleChange);
    }
  }

  @override
  void dispose() {
    widget.atom.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.atom.value);
  }
}

/// Batched rebuilds for multiple atoms.
///
/// This widget is highly optimized. It listens directly to the list of atoms
/// and rebuilds only once even if multiple atoms change in the same batch.
class WatchMany extends StatefulWidget {
  /// The list of [ValueListenable] (atoms) to watch.
  final List<ValueListenable> atoms;

  /// The UI Builder.
  final Widget Function(BuildContext context) builder;

  const WatchMany(this.atoms, {super.key, required this.builder});

  @override
  State<WatchMany> createState() => _WatchManyState();
}

class _WatchManyState extends State<WatchMany> {
  @override
  void initState() {
    super.initState();
    for (final atom in widget.atoms) {
      atom.addListener(_handleChange);
    }
  }

  @override
  void didUpdateWidget(WatchMany oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.atoms, widget.atoms)) {
      for (final atom in oldWidget.atoms) {
        atom.removeListener(_handleChange);
      }
      for (final atom in widget.atoms) {
        atom.addListener(_handleChange);
      }
    }
  }

  @override
  void dispose() {
    for (final atom in widget.atoms) {
      atom.removeListener(_handleChange);
    }
    super.dispose();
  }

  void _handleChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}

/// Ergonomic extensions for [BuildContext].
extension NanoContextExtension on BuildContext {
  /// Reads a dependency of type [T] from the nearest [Scope].
  ///
  /// Short for `Scope.of(this).get<T>()`.
  T read<T>() => Scope.of(this).get<T>();
}

/// Ergonomic extensions for any [ValueListenable] to create a [Watch] widget.
extension ValueListenableWatcher<T> on ValueListenable<T> {
  /// Creates a [Watch] widget from this [ValueListenable].
  ///
  /// Example:
  /// ```dart
  /// logic.counter.watch((context, value) {
  ///   return Text('$value');
  /// })
  /// ```
  Widget watch(Widget Function(BuildContext context, T value) builder) {
    return Watch<T>(this, builder: builder);
  }
}

/// Ergonomic extensions for Tuple (Record) of 2 [ValueListenable]s.
extension NanoTuple2Extension<T1, T2>
    on (ValueListenable<T1>, ValueListenable<T2>) {
  /// Watches both atoms and rebuilds when either changes.
  ///
  /// Example:
  /// ```dart
  /// (count, name).watch((context, c, n) {
  ///   return Text('$n: $c');
  /// })
  /// ```
  Widget watch(Widget Function(BuildContext context, T1 v1, T2 v2) builder) {
    return WatchMany([
      this.$1,
      this.$2,
    ], builder: (context) => builder(context, this.$1.value, this.$2.value));
  }
}

/// Ergonomic extensions for Tuple (Record) of 3 [ValueListenable]s.
extension NanoTuple3Extension<T1, T2, T3>
    on (ValueListenable<T1>, ValueListenable<T2>, ValueListenable<T3>) {
  /// Watches all 3 atoms and rebuilds when any changes.
  Widget watch(
    Widget Function(BuildContext context, T1 v1, T2 v2, T3 v3) builder,
  ) {
    return WatchMany(
      [this.$1, this.$2, this.$3],
      builder: (context) =>
          builder(context, this.$1.value, this.$2.value, this.$3.value),
    );
  }
}

/// Ergonomic extensions for [ValueListenable] of [AsyncState].
extension AsyncAtomWidgetExtension<T> on ValueListenable<AsyncState<T>> {
  /// Watches the [AsyncState] and builds widgets based on the state.
  Widget when({
    required Widget Function(BuildContext context, T data) data,
    required Widget Function(BuildContext context, Object error) error,
    required Widget Function(BuildContext context) loading,
    Widget Function(BuildContext context)? idle,
  }) {
    return watch((context, state) {
      return state.map(
        data: (d) => data(context, d),
        error: (e) => error(context, e),
        loading: () => loading(context),
        idle: () => idle?.call(context) ?? loading(context),
      );
    });
  }
}

/// A simplified builder for [Atom]s. Alias for [Watch].
///
/// Example:
/// ```dart
/// AtomBuilder(
///   atom: count,
///   builder: (context, value) => Text('$value'),
/// )
/// ```
class AtomBuilder<T> extends Watch<T> {
  const AtomBuilder({
    super.key,
    required ValueListenable<T> atom,
    required super.builder,
  }) : super(atom);
}

/// A specialized builder for [AsyncAtom] (or any `ValueListenable<AsyncState<T>>`).
///
/// Simplifies handling of loading, error, and data states without nested maps.
///
/// Example:
/// ```dart
/// AsyncAtomBuilder(
///   atom: userAtom,
///   data: (context, user) => UserProfile(user),
///   loading: (context) => const CircularProgressIndicator(),
///   error: (context, error) => ErrorText(error),
/// )
/// ```
class AsyncAtomBuilder<T> extends StatelessWidget {
  final ValueListenable<AsyncState<T>> atom;
  final Widget Function(BuildContext context, T data) data;
  final Widget Function(BuildContext context, Object error) error;
  final Widget Function(BuildContext context) loading;
  final Widget Function(BuildContext context)? idle;

  const AsyncAtomBuilder({
    super.key,
    required this.atom,
    required this.data,
    required this.error,
    required this.loading,
    this.idle,
  });

  @override
  Widget build(BuildContext context) {
    return Watch<AsyncState<T>>(
      atom,
      builder: (context, state) {
        return state.map(
          data: (d) => data(context, d),
          error: (e) => error(context, e),
          loading: () => loading(context),
          idle: () => idle?.call(context) ?? loading(context),
        );
      },
    );
  }
}
