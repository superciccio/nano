import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nano/core/nano_core.dart';
import 'package:nano/core/nano_di.dart' show Registry;
import 'package:nano/core/nano_logic.dart' show NanoLogic, NanoStatus;
import 'scope.dart';
import 'watch.dart';

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
  final Widget? Function(BuildContext context)? loading;

  /// Optional builder for error state
  final Widget? Function(BuildContext context, Object? error)? error;

  /// Optional builder for empty state
  final Widget? Function(BuildContext context)? empty;

  /// Whether to automatically dispose the logic when the view is disposed.
  /// Defaults to true.
  final bool autoDispose;

  /// Whether the view should rebuild whenever the logic notifies listeners.
  ///
  /// - `true` (Default): Coarse updates. The entire [builder] runs on every change.
  ///   Best for small views or when you don't want to use [Watch] everywhere.
  /// - `false`: Surgical updates. The [builder] runs ONLY when `status` changes.
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
    properties.add(DiagnosticsProperty('logic', _logic));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_logic == null) {
      _initLogic();
    }
  }

  void _initLogic() {
    try {
      final registry = Scope.of(context);
      final config = Scope.configOf(context);

      runZoned(() {
        _logic = widget.create(registry);
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
    if (_logic == null) return const SizedBox.shrink();

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

/// Abstract base class for views that use a [NanoLogic].
///
/// This is a convenience wrapper around [NanoView] that reduces boilerplate for
/// creating stateless screens with Logic.
///
/// **Usage:**
/// ```dart
/// class MyPage extends View<MyLogic, void> {
///   @override
///   MyLogic create(reg) => MyLogic();
///
///   @override
///   Widget buildView(context, logic) {
///     return Text(logic.state.value);
///   }
/// }
/// ```
abstract class View<T extends NanoLogic<P>, P> extends StatelessWidget {
  const View({super.key});

  /// Factory to create the logic.
  T create(Registry reg);

  /// Builds the UI with the logic.
  Widget buildView(BuildContext context, T logic);

  /// Optional builder for loading state.
  Widget? buildLoading(BuildContext context) => null;

  /// Optional builder for error state.
  Widget? buildError(BuildContext context, Object? error) => null;

  /// Optional parameters for logic initialization.
  P? get params => null;

  @override
  Widget build(BuildContext context) {
    return NanoView<T, P>(
      create: create,
      params: params,
      builder: buildView,
      loading: buildLoading,
      error: buildError,
    );
  }
}
