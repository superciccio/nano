import 'package:nano/core/nano_core.dart';
import 'package:nano/core/debug_service.dart';

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
ReactionDisposer autorun(void Function() effect, {String? label}) {
  final reaction = _Reaction(effect, label: label);
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
  String? label,
}) {
  // Actually, reaction is different from autorun.
  // It tracks `tracker`, and executes `sideEffect` when `tracker` result changes.

  T? previousValue;
  bool firstRun = true;

  final r = _Reaction(() {
    final newValue = tracker();
    if (firstRun) {
      if (fireImmediately) {
        sideEffect(newValue);
      }
    } else if (newValue != previousValue) {
      sideEffect(newValue);
    }
    previousValue = newValue;
    firstRun = false;
  }, label: label);

  r.schedule();
  return r.dispose;
}

class _Reaction implements NanoDerivation {
  final void Function() _onInvalidate;
  final String? label;

  @override
  String get debugLabel => label ?? 'Reaction';

  @override
  Iterable<Atom> get dependencies => _observing;

  Set<Atom> _observing = {};
  Set<Atom>? _newObserving; // Temporary set for new run
  bool _disposed = false;

  _Reaction(this._onInvalidate, {this.label}) {
    NanoDebugService.registerDerivation(this);
  }

  void schedule() {
    if (_disposed) return;

    // Glitch Prevention
    if (Nano.isFlushing) {
      for (final atom in _observing) {
        if (Nano.isFlushingAtom(atom)) {
          return;
        }
      }
    }

    // Prepare for new tracking (handle recursion)
    final previousNewObserving = _newObserving;
    _newObserving = {};

    // Run in tracking context
    try {
      Nano.track(this, _onInvalidate);

      // Diffing Strategy:
      // 1. Unsubscribe from atoms in _observing that are NOT in _newObserving
      // Note: We access _newObserving (the current one) safely here.
      for (final atom in _observing) {
        if (!_newObserving!.contains(atom)) {
          atom.removeListener(schedule);
        }
      }

      // Swap sets: _observing becomes the set we just built
      _observing = _newObserving!;
    } finally {
      // Restore previous state (pop stack)
      _newObserving = previousNewObserving;
    }
  }

  @override
  void addDependency(Atom atom) {
    if (_disposed) return;

    // We are running inside Nano.track, so _newObserving is not null.
    if (_newObserving!.add(atom)) {
      // If it wasn't already in the OLD set, we need to listen.
      // If it WAS in the OLD set, we are already listening, so do nothing (Optimization!).
      if (!_observing.contains(atom)) {
        atom.addListener(schedule);
      }
    }
  }

  void dispose() {
    _disposed = true;
    NanoDebugService.unregisterDerivation(this);
    for (final atom in _observing) {
      atom.removeListener(schedule);
    }
    _observing.clear();
    _newObserving = null;
  }
}
