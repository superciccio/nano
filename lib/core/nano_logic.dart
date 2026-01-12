import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nano/core/nano_action.dart';
import 'package:nano/core/nano_core.dart' show Nano, Atom;

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
abstract class NanoLogic<P> extends ChangeNotifier with DiagnosticableTreeMixin {
  final List<StreamSubscription> _subscriptions = [];

  /// The current status of the logic (loading, success, error, empty).
  final status = Atom<NanoStatus>(NanoStatus.loading);

  /// Holds the error object if status is [NanoStatus.error].
  final error = Atom<Object?>(null);

  /// Called immediately after the Logic is created.
  /// Use this for async initialization (fetching data, etc).
  void onInit(P params) {}

  bool _initialized = false;

  /// Internal method to ensure onInit is called only once.
  void initialize(P params) {
    if (_initialized) return;
    _initialized = true;
    onInit(params);
  }

  /// Called when an [NanoAction] is dispatched from the UI.
  void onAction(NanoAction action) {}

  /// Dispatches an [NanoAction] to the logic.
  void dispatch(NanoAction action) {
    onAction(action);
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
      (data) => atom.set(data),
      onError: (e, s) {
        Nano.observer.onError(atom, e, s);
      },
    );
    _subscriptions.add(sub);
  }

  @override
  void dispose() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}
