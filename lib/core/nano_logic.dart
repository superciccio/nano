/// {@category Logic}
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nano/core/nano_action.dart';
import 'package:nano/core/nano_core.dart'
    show Nano, Atom, NanoLogicBase, NanoInitContext;
import 'package:nano/core/nano_reaction.dart';

/// Possible states for a [NanoLogic].
enum NanoStatus { loading, success, error, empty }

/// Base class for your Business Logic (ViewModel).
///
/// It can be used in two ways:
/// 1. With methods that can be called directly from the UI.
/// 2. With Actions that can be dispatched from the UI.
///
/// Using Actions can help to create a more structured and testable codebase.
///
/// Example with methods:
/// ```dart
/// class CounterLogic extends NanoLogic<void> {
///   final counter = Atom(0);
///   void increment() => counter.update((v) => v + 1);
/// }
/// ```
///
/// Example with Actions:
/// ```dart
/// class IncrementAction extends NanoAction {}
///
/// class CounterLogic extends NanoLogic<void> {
///   final counter = Atom(0);
///
///   @override
///   void onAction(NanoAction action) {
///     if (action is IncrementAction) {
///       counter.update((v) => v + 1);
///     }
///   }
/// }
/// ```
abstract class NanoLogic<P> extends ChangeNotifier
    with DiagnosticableTreeMixin
    implements NanoLogicBase {
  final List<StreamSubscription> _subscriptions = [];
  final List<ReactionDisposer> _disposers = [];

  /// The current status of the logic (loading, success, error, empty).
  final status = Atom<NanoStatus>(NanoStatus.loading);

  /// Holds the error object if status is [NanoStatus.error].
  final error = Atom<Object?>(null);

  /// Called immediately after the Logic is created.
  /// Use this for field initialization and dependency setup.
  ///
  /// **CRITICAL**: This method must be SYNCHRONOUS. Do not use `async` or `await`
  /// here, as any work after an `await` will leak out of the initialization
  /// context and side-effect protection.
  ///
  /// NOTE: Updating atoms (side-effects) is forbidden here.
  void onInit(P params) {}

  /// Called after [onInit] in a microtask.
  /// Use this for side-effects (state updates, navigation, etc).
  void onReady() {}

  bool _initialized = false;

  bool _isInitializing = false;
  bool get isInitializing => _isInitializing;

  /// Internal method to ensure onInit and onReady are called correctly.
  void initialize(P params) {
    if (_initialized) return;
    _initialized = true;

    // Phase 1: Synchronous Init (Field setup)
    final initContext = NanoInitContext();
    _isInitializing = true;
    try {
      runZoned(
        () => onInit(params),
        zoneValues: {
          #nanoLogic: this,
          #nanoInitContext: initContext,
        },
      );
    } finally {
      _isInitializing = false;
      initContext.invalidate();
    }

    // Phase 2: Asynchronous Ready (Side-effects)
    Future.microtask(() {
      runZoned(() => onReady(), zoneValues: {#nanoLogic: this});
    });
  }

  @override
  void initializeDynamic(dynamic params) => initialize(params as P);

  /// Called when an [NanoAction] is dispatched from the UI.
  void onAction(NanoAction action) {}

  /// Dispatches an [NanoAction] to the logic.
  void dispatch(NanoAction action) {
    Nano.action(() => onAction(action));
  }

  /// Helper to bind a [Stream] (e.g., from Drift or Firebase) to an [Atom].
  ///
  /// Handles subscription lifecycle automatically.
  ///
  /// Example:
  /// ```dart
  /// class UserLogic extends NanoLogic {
  ///   final user = Atom<User?>(null);
  ///
  ///   UserLogic(Stream<User?> userStream) {
  ///     bindStream(userStream, user);
  ///   }
  /// }
  /// ```
  void bindStream<T>(Stream<T> stream, Atom<T> atom) {
    final sub = stream.listen(
      (data) => Nano.action(() => atom.set(data)),
      onError: (e, s) {
        Nano.action(() => Nano.observer.onError(atom, e, s));
      },
    );
    _subscriptions.add(sub);
  }

  /// Runs [effect] immediately and whenever any [Atom] accessed within it changes.
  /// The reaction is automatically disposed when this [NanoLogic] is disposed.
  void auto(void Function() effect, {String? label}) {
    _disposers.add(autorun(effect, label: label));
  }

  /// Runs [sideEffect] whenever the value returned by [tracker] changes.
  /// The reaction is automatically disposed when this [NanoLogic] is disposed.
  void react<T>(
    T Function() tracker,
    void Function(T value) sideEffect, {
    bool fireImmediately = false,
  }) {
    _disposers.add(reaction<T>(
      tracker,
      sideEffect,
      fireImmediately: fireImmediately,
    ));
  }

  final List<VoidCallback> _bindings = [];

  /// Helper to bind a [Listenable] (e.g., ValueNotifier, TextEditingController)
  /// to an action or effect.
  ///
  /// The [listener] is automatically removed when the logic is disposed.
  ///
  /// Example:
  /// ```dart
  /// bind(myController, () {
  ///   // This runs in an action automatically
  ///   myAtom.value = myController.text;
  /// });
  /// ```
  void bind(Listenable target, VoidCallback listener) {
    void safeListener() {
      Nano.action(listener);
    }

    target.addListener(safeListener);
    _bindings.add(() => target.removeListener(safeListener));
  }

  @override
  @mustCallSuper
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();

    for (final disposer in _disposers) {
      disposer();
    }
    _disposers.clear();

    for (final unbind in _bindings) {
      unbind();
    }
    _bindings.clear();

    status.dispose();
    error.dispose();
    super.dispose();
  }
}
