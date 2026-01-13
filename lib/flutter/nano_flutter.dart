import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:nano/core/nano_core.dart';
import 'package:nano/core/nano_di.dart'
    show Registry, NanoException, NanoFactory, NanoLazy;
import 'package:nano/core/nano_logic.dart' show NanoLogic, NanoStatus;

/// The Dependency Injection Container.
///
/// Wrap your App (or a specific feature) in this widget to provide dependencies.
///
/// Example:
/// ```dart
/// Scope(
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

  const Scope({super.key, required this.modules, required this.child});

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
    // If modules changed, we might need to re-register?
    // In many DI libs, changing modules on the fly is not supported or creates a new registry.
    // For now, let's assume modules are static for the lifetime of the scope
    // or at least that we don't support dynamic module updates without a new state.
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const SizedBox.shrink();
    return _InheritedScope(registry: _registry, child: widget.child);
  }
}

class _InheritedScope extends InheritedWidget {
  final Registry registry;

  const _InheritedScope({required this.registry, required super.child});

  @override
  bool updateShouldNotify(_InheritedScope oldWidget) =>
      registry != oldWidget.registry;
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

  const NanoView({
    super.key,
    required this.create,
    required this.builder,
    this.params,
    this.loading,
    this.error,
    this.empty,
    this.autoDispose = true,
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
      _logic = widget.create(registry);
      // We force cast params to P because if P is non-nullable,
      // the user MUST have provided params (checked statically or runtime failure).
      // But if P is dynamic/void/nullable, null is fine.
      _logic!.initialize(widget.params as P);
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

    // Default: Listens to the whole Logic for coarse updates (notifyListeners)
    return ListenableBuilder(
      listenable: _logic!,
      builder: (context, _) {
        // Watch the status and switch surgically
        return Watch<NanoStatus>(
          _logic!.status,
          builder: (context, status) {
            return switch (status) {
              NanoStatus.loading =>
                widget.loading?.call(context) ??
                    widget.builder(context, _logic!),
              NanoStatus.success => widget.builder(context, _logic!),
              NanoStatus.error =>
                widget.error?.call(context, _logic!.error.value) ??
                    const SizedBox.shrink(),
              NanoStatus.empty =>
                widget.empty?.call(context) ?? const SizedBox.shrink(),
            };
          },
        );
      },
    );
  }
}

/// Surgical rebuilds.
///
/// Only rebuilds this widget when the specific [Atom] (or any [ValueListenable]) changes.
///
/// Example:
/// ```dart
/// Watch(logic.counter, builder: (context, value) {
///   return Text('$value');
/// })
/// ```
class Watch<T> extends StatelessWidget {
  /// The [ValueListenable] (usually an [Atom] or [ComputedAtom]) to watch.
  final ValueListenable<T> atom;

  /// The UI Builder.
  final Widget Function(BuildContext context, T value) builder;

  const Watch(this.atom, {super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      valueListenable: atom,
      builder: (context, value, _) => builder(context, value),
    );
  }
}

/// Batched rebuilds for multiple atoms.
class WatchMany extends StatelessWidget {
  /// The list of [ValueListenable] (atoms) to watch.
  final List<ValueListenable> atoms;

  /// The UI Builder.
  final Widget Function(BuildContext context) builder;

  const WatchMany(this.atoms, {super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(atoms),
      builder: (context, _) => builder(context),
    );
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
