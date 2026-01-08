import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:nano/core/nano_core.dart';
import 'package:nano/core/nano_di.dart'
    show Registry, NanoException, NanoFactory, NanoLazy;
import 'package:nano/core/nano_logic.dart' show NanoLogic;

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
class Scope extends InheritedWidget {
  final Registry _registry = Registry();

  Scope({super.key, required List<Object> modules, required super.child}) {
    Nano.init();
    for (var m in modules) {
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

  /// Explicit lookup for dependencies from the given [context].
  ///
  /// Throws [NanoException] if no [Scope] is found in the widget tree.
  static Registry of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<Scope>();
    if (scope == null) {
      throw NanoException(
        "No Scope found in the widget tree.\n"
        "👉 Fix: Wrap your MaterialApp or Feature in a Scope(modules: [...], child: ...)",
      );
    }
    return scope._registry;
  }

  @override
  bool updateShouldNotify(Scope oldWidget) => true;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('registry', _registry));
  }
}

/// The Smart View Widget.
///
/// 1. Creates your [NanoLogic] using the [Registry].
/// 2. Manages Lifecycle (`onInit`, `dispose`).
/// 3. Rebuilds automatically if [keys] change.
///
/// By default, it listens to the entire [NanoLogic] (via `notifyListeners`).
/// For surgical rebuilds, use [Watch].
///
/// Example:
/// ```dart
/// ```dart
/// NanoView<CounterLogic>(
///   create: (reg) => CounterLogic(),
///   builder: (context, logic) {
///     return Text('${logic.counter.value}');
///   },
/// )
/// ```
class NanoView<T extends NanoLogic> extends StatefulWidget {
  /// Factory to create the [NanoLogic]. Injects the [Registry] for DI.
  final T Function(Registry reg) create;

  /// The UI Builder.
  final Widget Function(BuildContext context, T logic) builder;

  /// If provided, the Logic will be destroyed and recreated whenever
  /// any value in this list changes (e.g., `[userId, currency]`).
  const NanoView({super.key, required this.create, required this.builder});

  @override
  State<NanoView<T>> createState() => _NanoViewState<T>();
}

class _NanoViewState<T extends NanoLogic> extends State<NanoView<T>> {
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
      _logic!.onInit();
    } catch (e, s) {
      Nano.observer.onError('NanoViewInit<${T.toString()}>', e, s);
      rethrow;
    }
  }

  void _disposeLogic() {
    _logic?.dispose();
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
      builder: (context, _) => widget.builder(context, _logic!),
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

/// Ergonomic extensions for [BuildContext].
extension NanoContextExtension on BuildContext {
  /// Reads a dependency of type [T] from the nearest [Scope].
  ///
  /// Short for `Scope.of(context).get<T>()`.
  T read<T>() => Scope.of(this).get<T>();
}
