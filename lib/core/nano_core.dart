import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nano/core/debug_service.dart';
import 'package:nano/core/nano_persistence.dart';

/// Global configuration for Nano.
class Nano {
  /// Set this in your main() to capture logs (e.g., NanoObserver()).
  static NanoObserver observer = _DefaultObserver();

  /// Global storage backend for [PersistedAtom].
  static NanoStorage storage = InMemoryStorage();

  /// [Internal] Stack of currently executing derivations (reactions/computeds)
  /// that want to track dependencies.
  static final List<NanoDerivation> _derivationStack = [];

  /// [Internal] Reports an atom read to the current derivation.
  static void reportRead(Atom atom) {
    if (_derivationStack.isNotEmpty) {
      _derivationStack.last.addDependency(atom);
    }
  }

  /// [Internal] Runs [fn] inside a tracking context.
  static T track<T>(NanoDerivation derivation, T Function() fn) {
    _derivationStack.add(derivation);
    try {
      return fn();
    } finally {
      _derivationStack.removeLast();
    }
  }

  /// [Internal] Batch depth counter.
  static int _batchDepth = 0;

  /// [Internal] Pending atoms to notify.
  static final Set<Atom> _pendingNotifications = {};

  /// Batches notifications for state updates.
  ///
  /// Changes to [Atom]s inside the [fn] will not trigger listeners immediately.
  /// Instead, they will be collected and notified once the batch completes.
  ///
  /// This is useful for performance when updating multiple atoms at once,
  /// or when updating a single atom multiple times (only the last value is notified).
  ///
  /// Example:
  /// ```dart
  /// Nano.batch(() {
  ///   atom1.value = 1;
  ///   atom2.value = 2;
  /// });
  /// // Listeners are notified here.
  /// ```
  static void batch(void Function() fn) {
    _batchDepth++;
    try {
      fn();
    } finally {
      _batchDepth--;
      if (_batchDepth == 0) {
        final pending = _pendingNotifications.toList();
        _pendingNotifications.clear();
        for (final atom in pending) {
          // We must manually call the listener notification logic.
          // Since we overrode notifyListeners to be suppressed, we need a way
          // to force it or bypass the check.
          //
          // However, since `_batchDepth` is now 0, calling `notifyListeners`
          // on the atom will work normally!
          atom.notifyListeners();
        }
      }
    }
  }

  /// Initialize Nano for debugging. Usually called by Scope.
  static void init() {
    NanoDebugService.init();
  }
}

/// Interface for anything that depends on Atoms (Computed, Reaction).
abstract class NanoDerivation {
  void addDependency(Atom atom);
}

/// Interface for intercepting state changes and errors.
/// Useful for logging to Console, Sentry, Crashlytics, etc.
abstract class NanoObserver {
  /// Called whenever an [Atom] or [ComputedAtom] changes its value.
  void onChange(Atom atom, dynamic oldValue, dynamic newValue);

  /// Called whenever an error occurs (e.g., in [AsyncAtom] or [NanoLogic.bindStream]).
  void onError(Atom atom, Object error, StackTrace stack);
}

/// Default observer that prints to console in debug mode.
class _DefaultObserver implements NanoObserver {
  @override
  void onChange(Atom atom, dynamic oldValue, dynamic newValue) {
    if (kDebugMode) {
      debugPrint('?? NANO [${atom.label ?? atom.runtimeType}]: $oldValue -> $newValue');
    }
  }

  @override
  void onError(Atom atom, Object error, StackTrace stack) {
    debugPrint('?? NANO ERROR [${atom.label ?? atom.runtimeType}]: $error');
    if (kDebugMode) debugPrint(stack.toString());
  }
}

/// A composite observer that delegates to multiple observers.
class CompositeObserver implements NanoObserver {
  final List<NanoObserver> observers;

  CompositeObserver(this.observers);

  @override
  void onChange(Atom atom, dynamic oldValue, dynamic newValue) {
    for (final observer in observers) {
      observer.onChange(atom, oldValue, newValue);
    }
  }

  @override
  void onError(Atom atom, Object error, StackTrace stack) {
    for (final observer in observers) {
      observer.onError(atom, error, stack);
    }
  }

  /// Adds an observer to the list.
  void addObserver(NanoObserver observer) => observers.add(observer);

  /// Removes an observer from the list.
  void removeObserver(NanoObserver observer) => observers.remove(observer);
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
  final Map<String, dynamic> meta;

  Atom(super.value, {this.label, this.meta = const {}}) {
    NanoDebugService.registerAtom(this);
  }

  @override
  T get value {
    Nano.reportRead(this);
    return super.value;
  }

  @override
  set value(T newValue) {
    set(newValue);
  }

  void set(T newValue) {
    if (value == newValue) return;
    Nano.observer.onChange(this, value, newValue);
    super.value = newValue;
  }

  /// Internal setter to bypass the [set] method (and its overrides).
  void _innerSet(T newValue) {
    super.value = newValue;
  }

  @override
  void notifyListeners() {
    if (Nano._batchDepth > 0) {
      Nano._pendingNotifications.add(this);
    } else {
      super.notifyListeners();
    }
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
class ComputedAtom<T> extends Atom<T> {
  final T Function() selector;
  final List<ValueListenable> dependencies;

  ComputedAtom(
    this.dependencies,
    this.selector, {
    super.label,
    super.meta,
  }) : super(selector()) {
    for (final dep in dependencies) {
      dep.addListener(_update);
    }
  }

  void _update() {
    final newValue = selector();
    if (value == newValue) return;
    Nano.observer.onChange(this, value, newValue);
    _innerSet(newValue);
  }

  @override
  void set(T newValue) {
    throw UnsupportedError('ComputedAtom is read-only');
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
        Nano.observer.onError(this, e, s);
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
        Nano.observer.onError(this, e, s);
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

/// An [Atom] that persists its value to storage.
///
/// It requires a [key] to identify the value in storage.
/// By default, it uses [Nano.storage] (InMemoryStorage), but you can
/// configure it to use SharedPreferences, Hive, etc.
///
/// Only supports basic types (int, double, bool, String) or objects that
/// can be serialized to/from String.
class PersistedAtom<T> extends Atom<T> {
  final String key;
  final T Function(String)? fromString;
  final String Function(T)? toStringEncoder;

  PersistedAtom(
    super.value, {
    required this.key,
    this.fromString,
    this.toStringEncoder,
    super.label,
    super.meta,
  }) {
    _load();
  }

  Future<void> _load() async {
    try {
      final stored = await Nano.storage.read(key);
      if (stored != null) {
        final val = _decode(stored);
        if (val != value) {
          _innerSet(val);
        }
      }
    } catch (e, s) {
      Nano.observer.onError(this, e, s);
    }
  }

  @override
  void set(T newValue) {
    super.set(newValue);
    _save(newValue);
  }

  Future<void> _save(T val) async {
    try {
      await Nano.storage.write(key, _encode(val));
    } catch (e, s) {
      Nano.observer.onError(this, e, s);
    }
  }

  T _decode(String stored) {
    if (fromString != null) return fromString!(stored);
    if (T == int) return int.parse(stored) as T;
    if (T == double) return double.parse(stored) as T;
    if (T == bool) return (stored == 'true') as T;
    if (T == String) return stored as T;
    throw UnimplementedError(
      'PersistedAtom<$T> requires `fromString` for complex types.',
    );
  }

  String _encode(T val) {
    if (toStringEncoder != null) return toStringEncoder!(val);
    return val.toString();
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
  Atom<T> toAtom([String? label, Map<String, dynamic> meta = const {}]) =>
      Atom<T>(this, label: label, meta: meta);
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
