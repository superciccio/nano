import 'package:flutter/foundation.dart';
import 'package:nano/core/nano_core.dart';

/// Disposes a reaction.
typedef ReactionDisposer = void Function();

/// Runs [effect] immediately and whenever any [Atom] accessed within it changes.
///
/// Returns a [ReactionDisposer] to stop the reaction.
///
/// Example:
/// ```dart
/// final disposer = autorun(() {
///   print(count.value);
/// });
/// ```
ReactionDisposer autorun(void Function() effect) {
  final reaction = _Reaction(effect);
  reaction.schedule();
  return reaction.dispose;
}

/// Runs [sideEffect] whenever the value returned by [tracker] changes.
///
/// Returns a [ReactionDisposer] to stop the reaction.
///
/// Example:
/// ```dart
/// reaction(
///   () => count.value,
///   (count) => print('Count changed to $count'),
/// );
/// ```
ReactionDisposer reaction<T>(
  T Function() tracker,
  void Function(T value) sideEffect, {
  bool fireImmediately = false,
}) {
  final reaction = _Reaction(() {
    // This is effectively a computed, but simplified
    // We track inside here
  });

  // Actually, reaction is different from autorun.
  // It tracks `tracker`, and executes `sideEffect` when `tracker` result changes.

  T? previousValue;
  bool firstRun = true;

  final r = _Reaction(() {
    final newValue = tracker();
    if (!firstRun) {
      if (newValue != previousValue) {
        sideEffect(newValue);
      }
    } else if (fireImmediately) {
      sideEffect(newValue);
    }
    previousValue = newValue;
    firstRun = false;
  });

  r.schedule();
  return r.dispose;
}

class _Reaction implements NanoDerivation {
  final void Function() _onInvalidate;
  final Set<Atom> _observing = {};
  bool _disposed = false;

  _Reaction(this._onInvalidate);

  void schedule() {
    if (_disposed) return;

    // Cleanup old dependencies
    for (final atom in _observing) {
      atom.removeListener(schedule);
    }
    _observing.clear();

    // Run in tracking context
    Nano.track(this, _onInvalidate);
  }

  @override
  void addDependency(Atom atom) {
    if (_disposed) return;
    if (_observing.add(atom)) {
      atom.addListener(schedule);
    }
  }

  void dispose() {
    _disposed = true;
    for (final atom in _observing) {
      atom.removeListener(schedule);
    }
    _observing.clear();
  }
}
