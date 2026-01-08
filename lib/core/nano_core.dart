import 'package:flutter/foundation.dart';
import 'package:nano/core/debug_service.dart';

/// Global configuration for Nano.
class Nano {
  /// Set this in your main() to capture logs (e.g., NanoObserver()).
  static NanoObserver observer = _DefaultObserver();

  /// Initialize Nano for debugging. Usually called by Scope.
  static void init() {
    NanoDebugService.init();
  }
}

/// Interface for intercepting state changes and errors.
/// Useful for logging to Console, Sentry, Crashlytics, etc.
abstract class NanoObserver {
  /// Called whenever an [Atom] or [ComputedAtom] changes its value.
  void onChange(String label, dynamic oldValue, dynamic newValue);

  /// Called whenever an error occurs (e.g., in [AsyncAtom] or [NanoLogic.bindStream]).
  void onError(String label, Object error, StackTrace stack);
}

/// Default observer that prints to console in debug mode.
class _DefaultObserver implements NanoObserver {
  @override
  void onChange(String label, dynamic oldValue, dynamic newValue) {
    if (kDebugMode) {
      debugPrint('?? NANO [$label]: $oldValue -> $newValue');
    }
  }

  @override
  void onError(String label, Object error, StackTrace stack) {
    debugPrint('?? NANO ERROR [$label]: $error');
    if (kDebugMode) debugPrint(stack.toString());
  }
}

/// The atomic unit of state.
/// Wraps a [ValueNotifier] with extra powers:
/// 1. Logging via [NanoObserver].
/// 2. Helper methods like [update].
///
/// Example:
/// ```dart
/// final count = Atom(0, label: 'counter');
/// count.set(10);
/// count.update((v) => v + 1);
/// ```
class Atom<T> extends ValueNotifier<T> with Diagnosticable {
  final String? label;
  Atom(super.value, {this.label}) {
    NanoDebugService.registerAtom(this);
  }
  void set(T newValue) {
    if (value == newValue) return;
    Nano.observer.onChange(label ?? 'Atom<${T.toString()}>', value, newValue);
    value = newValue;
  }

  void update(T Function(T current) fn) {
    set(fn(value));
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('label', label, defaultValue: null));
    properties.add(DiagnosticsProperty('value', value));
  }

  @override
  void dispose() {
    NanoDebugService.unregisterAtom(this);
    super.dispose();
  }
}

class ComputedAtom<T> extends ValueNotifier<T> with Diagnosticable {
  final String? label;
  final T Function() selector;
  final List<ValueListenable> dependencies;
  ComputedAtom(this.dependencies, this.selector, {this.label})
    : super(selector()) {
    for (final dep in dependencies) {
      dep.addListener(_update);
    }
  }
  void _update() {
    final newValue = selector();
    if (value == newValue) return;
    Nano.observer.onChange(
      label ?? 'ComputedAtom<${T.toString()}>',
      value,
      newValue,
    );
    value = newValue;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('label', label, defaultValue: null));
    properties.add(DiagnosticsProperty('value', value));
  }

  @override
  void dispose() {
    for (final dep in dependencies) {
      dep.removeListener(_update);
    }
    super.dispose();
  }
}

sealed class AsyncState<T> with Diagnosticable {
  const AsyncState();
  bool get isLoading => this is AsyncLoading;
  bool get hasError => this is AsyncError;
  bool get hasData => this is AsyncData;
  T? get dataOrNull =>
      this is AsyncData<T> ? (this as AsyncData<T>).data : null;
  Object? get errorOrNull =>
      this is AsyncError<T> ? (this as AsyncError<T>).error : null;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('isLoading', isLoading));
    properties.add(DiagnosticsProperty('hasError', hasError));
    properties.add(DiagnosticsProperty('hasData', hasData));
  }
}

class AsyncIdle<T> extends AsyncState<T> {
  const AsyncIdle();
}

class AsyncLoading<T> extends AsyncState<T> {
  const AsyncLoading();
}

class AsyncData<T> extends AsyncState<T> {
  final T data;
  const AsyncData(this.data);
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('data', data));
  }
}

class AsyncError<T> extends AsyncState<T> {
  final Object error;
  final StackTrace stackTrace;
  const AsyncError(this.error, this.stackTrace);
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('error', error));
  }
}

class AsyncAtom<T> extends Atom<AsyncState<T>> {
  int _session = 0;

  AsyncAtom({AsyncState<T> initial = const AsyncIdle(), String? label})
    : super(initial, label: label);

  Future<void> track(Future<T> future) async {
    final currentSession = ++_session;
    set(AsyncLoading<T>());

    try {
      final data = await future;
      // Race Condition Check: Only update if we are still the latest session.
      if (_session == currentSession) {
        set(AsyncData<T>(data));
      }
    } catch (e, s) {
      if (_session == currentSession) {
        set(AsyncError<T>(e, s));
        Nano.observer.onError(label ?? 'AsyncAtom<${T.toString()}>', e, s);
      }
    }
  }
}

/// A specialized Atom that selects a part of another Atom's state.
///
/// It only notifies listeners when the selected value changes.
class SelectorAtom<T, R> extends Atom<R> {
  final Atom<T> parent;
  final R Function(T) selector;
  late VoidCallback _remover;

  SelectorAtom(this.parent, this.selector, {String? label})
    : super(
        selector(parent.value),
        label: label ?? '${parent.label ?? "Atom"}.select',
      ) {
    void listener() {
      final newValue = selector(parent.value);
      if (newValue != value) {
        set(newValue);
      }
    }

    parent.addListener(listener);
    _remover = () => parent.removeListener(listener);
  }

  @override
  void dispose() {
    _remover();
    super.dispose();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<T>('parentValue', parent.value));
    properties.add(DiagnosticsProperty<R>('selectedValue', value));
    properties.add(
      StringProperty('selector', 'derived from ${parent.runtimeType}'),
    );
  }
}

extension AtomSelectorExtension<T> on Atom<T> {
  /// Selects a specific part [R] of the state [T].
  ///
  /// The resulting [Atom<R>] will only notify when [R] changes.
  Atom<R> select<R>(R Function(T) selector, {String? label}) {
    return SelectorAtom<T, R>(this, selector, label: label);
  }
}

/// Ergonomic extensions for [Atom] of type [int].
extension AtomIntExtension on Atom<int> {
  /// Increments the value by [amount].
  void increment([int amount = 1]) => value += amount;

  /// Decrements the value by [amount].
  void decrement([int amount = 1]) => value -= amount;
}

/// Ergonomic extensions for [Atom] of type [bool].
extension AtomBoolExtension on Atom<bool> {
  /// Toggles the boolean value.
  void toggle() => value = !value;
}
