import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nano/core/nano_core.dart' show Nano, Atom;

/// Base class for your Business Logic (ViewModel).
///
/// Extends [ChangeNotifier] so you can use `notifyListeners()` if you prefer
/// coarse-grained updates over Atoms.
///
/// Example:
/// ```dart
/// class CounterLogic extends NanoLogic {
///   final counter = Atom(0);
///
///   void increment() => counter.update((v) => v + 1);
/// }
/// ```
abstract class NanoLogic extends ChangeNotifier with DiagnosticableTreeMixin {
  final List<StreamSubscription> _subscriptions = [];

  /// Called immediately after the Logic is created.
  /// Use this for async initialization (fetching data, etc).
  void onInit() {}

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
        Nano.observer.onError(atom.label ?? 'StreamBinding', e, s);
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
