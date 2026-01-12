import 'dart:async';

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
  static const _sentinel = Object();

  final String? label;
  Atom(super.value, {this.label}) {
    NanoDebugService.registerAtom(this);
  }

  @override
  set value(T newValue) {
    set(newValue);
  }

  void set(T newValue) {
    if (value == newValue) return;
    Nano.observer.onChange(label ?? 'Atom<${T.toString()}>', value, newValue);
    super.value = newValue;
  }

  void update(T Function(T current) fn) {
    set(fn(value));
  }

  /// Ergonomic shortcut to get/set the value.
  ///
  /// Example:
  /// ```dart
  /// final count = 0.toAtom();
  /// print(count()); // Same as count.value
  /// count(10); // Same as count.set(10)
  /// count((c) => c + 1); // Same as count.update((c) => c + 1)
  /// ```
  T call([dynamic newValue = _sentinel]) {
    if (!identical(newValue, _sentinel)) {
      if (newValue is T Function(T)) {
        update(newValue);
      } else {
        set(newValue);
      }
    }
    return value;
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

/// A read-only [Atom] that computes its value from other [Atom]s.
///
/// The `ComputedAtom` automatically listens to its dependencies and updates
/// its own value when any of them change.
///
/// Example:
/// ```dart
/// final count = Atom(10);
/// final doubleCount = ComputedAtom([count], () => count.value * 2);
///
/// print(doubleCount.value); // 20
/// count.set(20);
/// print(doubleCount.value); // 40
/// ```
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

/// Represents the state of an asynchronous operation.
sealed class AsyncState<T> with Diagnosticable {
  const AsyncState();
  bool get isLoading => this is AsyncLoading;
  bool get hasError => this is AsyncError;
  bool get hasData => this is AsyncData;
  T? get dataOrNull =>
      this is AsyncData<T> ? (this as AsyncData<T>).data : null;
  Object? get errorOrNull =>
      this is AsyncError<T> ? (this as AsyncError<T>).error : null;

  Object? get error => errorOrNull;
  T? get value => dataOrNull;

  /// Ergonomic mapping of async states.
  R map<R>({
    required R Function(T data) data,
    required R Function() loading,
    required R Function(Object error) error,
    required R Function() idle,
  }) {
    if (this is AsyncData<T>) return data((this as AsyncData<T>).data);
    if (this is AsyncError<T>) return error((this as AsyncError<T>).error);
    if (this is AsyncIdle<T>) return idle();
    return loading();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('isLoading', isLoading));
    properties.add(DiagnosticsProperty('hasError', hasError));
    properties.add(DiagnosticsProperty('hasData', hasData));
  }
}

/// The initial state before any operation has started.
class AsyncIdle<T> extends AsyncState<T> {
  const AsyncIdle();
}

/// The state while the asynchronous operation is in progress.
class AsyncLoading<T> extends AsyncState<T> {
  const AsyncLoading();
}

/// The state when the asynchronous operation has completed successfully.
class AsyncData<T> extends AsyncState<T> {
  final T data;
  const AsyncData(this.data);
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('data', data));
  }
}

/// The state when the asynchronous operation has failed.
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

/// An [Atom] that manages the state of an asynchronous operation.
///
/// It automatically handles loading, data, and error states.
/// Use the `track` method to wrap a `Future`.
///
/// Example:
/// ```dart
/// final searchResults = AsyncAtom<List<String>>();
///
/// void search(String query) {
///   searchResults.track(api.search(query));
/// }
///
/// // In the UI, you can use a switch statement on `searchResults.value`
/// // to display the appropriate widget for each state (loading, data, error).
/// ```
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

/// An [Atom] that manages the state of a [Stream].
class StreamAtom<T> extends Atom<AsyncState<T>> {
  StreamSubscription<T>? _subscription;

  StreamAtom(
    Stream<T> stream, {
    AsyncState<T> initial = const AsyncLoading(),
    String? label,
  }) : super(initial, label: label) {
    _subscription = stream.listen(
      (data) => set(AsyncData<T>(data)),
      onError: (e, s) {
        set(AsyncError<T>(e, s));
        Nano.observer.onError(label ?? 'StreamAtom<$T>', e, s);
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// An [Atom] that automatically debounces its value.
///
/// When the value is set, it will wait for the specified [duration] before
/// actually updating the value and notifying listeners. If the value is set
/// again within the duration, the timer will be reset.
class DebouncedAtom<T> extends Atom<T> {
  final Duration duration;
  Timer? _debounce;

  DebouncedAtom(super.value, {required this.duration, super.label});

  @override
  void set(T newValue) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(duration, () {
      super.set(newValue);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
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
extension StreamNanoExtension<T> on Stream<T> {
  /// Converts a [Stream] into a [StreamAtom].
  StreamAtom<T> toStreamAtom({AsyncState<T> initial = const AsyncLoading(), String? label}) =>
      StreamAtom<T>(this, initial: initial, label: label);
}

/// Ergonomic extensions for [Atom] of type [int].
extension AtomIntExtension on Atom<int> {
  /// Increments the value by [amount].
  void increment([int amount = 1]) => set(value + amount);

  /// Decrements the value by [amount].
  void decrement([int amount = 1]) => set(value - amount);
}

/// Ergonomic extensions for [Atom] of type [bool].
extension AtomBoolExtension on Atom<bool> {
  /// Toggles the boolean value.
  void toggle() => set(!value);
}

/// Ergonomic extensions for any object to create an Atom.
extension NanoObjectExtension<T> on T {
  /// Creates an [Atom] from this value.
  ///
  /// Example:
  /// ```dart
  /// final count = 0.toAtom('count');
  /// ```
  Atom<T> toAtom([String? label]) => Atom<T>(this, label: label);
}

/// Extension to convert a [ValueListenable] into a [Stream].
extension ValueListenableStreamExtension<T> on ValueListenable<T> {
  /// Returns a [Stream] that emits the current value and subsequent updates.
  Stream<T> get stream {
    late StreamController<T> controller;
    VoidCallback? listener;

    void onData() {
      controller.add(value);
    }

    controller = StreamController<T>.broadcast(
      onListen: () {
        controller.add(value);
        listener = onData;
        addListener(listener!);
      },
      onCancel: () {
        if (listener != null) {
          removeListener(listener!);
          listener = null;
        }
      },
    );
    return controller.stream;
  }
}

/// Ergonomic extensions for [Atom] of type [List].
extension AtomListExtension<E> on Atom<List<E>> {
  /// Adds [element] to the list.
  void add(E element) => set([...value, element]);

  /// Adds all [elements] to the list.
  void addAll(Iterable<E> elements) => set([...value, ...elements]);

  /// Removes [element] from the list.
  void remove(E element) => set([...value]..remove(element));

  /// Clears the list.
  void clear() => set([]);
}

/// Ergonomic extensions for [Atom] of type [Set].
extension AtomSetExtension<E> on Atom<Set<E>> {
  /// Adds [element] to the set.
  void add(E element) => set({...value, element});

  /// Adds all [elements] to the set.
  void addAll(Iterable<E> elements) => set({...value, ...elements});

  /// Removes [element] from the set.
  void remove(E element) => set({...value}..remove(element));

  /// Clears the set.
  void clear() => set({});
}

/// Ergonomic extensions for [Atom] of type [Map].
extension AtomMapExtension<K, V> on Atom<Map<K, V>> {
  /// Adds [key]:[val] to the map.
  void put(K key, V val) => set({...value, key: val});

  /// Adds all entries from [other] to the map.
  void putAll(Map<K, V> other) => set({...value, ...other});

  /// Removes [key] from the map.
  void remove(K key) => set({...value}..remove(key));

  /// Clears the map.
  void clear() => set({});
}
