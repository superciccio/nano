// ignore_for_file: avoid_atom_outside_logic
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nano/core/debug_service.dart';
import 'package:nano/core/nano_config.dart';
import 'package:nano/core/nano_persistence.dart';

abstract class NanoLogicBase {
  bool get isInitializing;
}

/// [Internal] Context used to track the validity of the synchronous 'onInit' phase.
class NanoInitContext {
  bool _isValid = true;
  bool get isValid => _isValid;

  /// Invalidates this context, identifying the end of the synchronous phase.
  void invalidate() => _isValid = false;
}

/// Interface for complex state that can be serialized/deserialized.
/// Required for robust DevTools time travel with complex models.
abstract interface class NanoSerializable {
  /// Converts this object to a JSON-serializable map.
  Map<String, dynamic> toJson();
}

/// Global configuration for Nano.
class Nano {
  /// Set this in your main() to capture logs (e.g., NanoObserver()).
  /// The default observer used when no configuration is found in the Zone.
  static final NanoObserver _defaultObserver = _DefaultObserver();

  /// Returns the current [NanoObserver].
  ///
  /// It looks for a [NanoConfig] in the current [Zone].
  /// If not found, it returns the default observer.
  static NanoObserver get observer {
    final config = Zone.current[#nanoConfig] as NanoConfig?;
    return config?.observer ?? _defaultObserver;
  }

  /// Returns the list of active middlewares.
  static List<NanoMiddleware> get middlewares {
    final config = Zone.current[#nanoConfig] as NanoConfig?;
    return config?.middlewares ?? [];
  }

  static NanoLogicBase? get logic => Zone.current[#nanoLogic] as NanoLogicBase?;

  /// The default storage used when no configuration is found.
  static final NanoStorage _defaultStorage = InMemoryStorage();

  /// Returns the current [NanoStorage].
  static NanoStorage get storage {
    final config = Zone.current[#nanoConfig] as NanoConfig?;
    return config?.storage ?? _defaultStorage;
  }

  /// [Internal] Returns the current [NanoInitContext].
  static NanoInitContext? get initContext =>
      Zone.current[#nanoInitContext] as NanoInitContext?;

  /// [Internal] A flag to check if an action is running.
  static bool _isInAction = false;

  /// [Internal] Returns true if an action is running.
  static bool get isInAction => _isInAction;

  /// [Internal] Global version incremented on every atom change.
  static int _version = 0;

  /// [Internal] Returns the current global version.
  static int get version => _version;

  /// [Test Only] Resets Nano global state for testing.
  @visibleForTesting
  static void reset() {
    _version = 0;
    _isInAction = false;
    // observer and middlewares are now derived from Zone or default immutable instances.
    // We cannot "clear" them globally.
  }

  static Map<String, dynamic>? _savedState;

  /// [Developer-Only] Backups the current state of all registered atoms.
  /// Used to simulate state persistence across Hot Restarts.
  static void backupState() {
    if (!kDebugMode) return;
    final state = <String, dynamic>{};
    for (final atom in NanoDebugService.registeredAtoms) {
      if (atom.label != null) {
        final val = atom.value;
        if (val is NanoSerializable) {
          state[atom.label!] = val.toJson();
        } else if (val is int ||
            val is double ||
            val is bool ||
            val is String) {
          state[atom.label!] = val;
        }
      }
    }
    _savedState = state;
  }

  /// [Developer-Only] Restores the previously backed-up state.
  static void restoreState() {
    if (!kDebugMode || _savedState == null) return;
    action('restoreState', () {
      for (final atom in NanoDebugService.registeredAtoms) {
        if (atom.label != null && _savedState!.containsKey(atom.label)) {
          final savedVal = _savedState![atom.label];
          if (atom.fromJson != null && savedVal is Map<String, dynamic>) {
            atom.value = atom.fromJson!(savedVal);
          } else {
            try {
              atom.value = savedVal;
            } catch (_) {
              // Skip if types don't match or other issues
            }
          }
        }
      }
    });
  }

  /// [Internal] Starts an action.
  static void _actionStart(String name) {
    _isInAction = true;
    for (final middleware in middlewares) {
      middleware.onActionStart(name);
    }
  }

  /// [Internal] Ends an action.
  static void _actionEnd(String name) {
    for (final middleware in middlewares) {
      middleware.onActionEnd(name);
    }
    _isInAction = false;
  }

  /// Runs [fn] as an action.
  /// Actions are used to batch state updates and provide a label for debugging.
  static void action(dynamic nameOrFn, [void Function()? fn]) {
    final String name;
    final void Function() actualFn;

    if (nameOrFn is String) {
      name = nameOrFn;
      actualFn = fn!;
    } else {
      name = 'anonymous_action';
      actualFn = nameOrFn as void Function();
    }

    _actionStart(name);
    try {
      untracked(actualFn);
    } finally {
      _actionEnd(name);
    }
  }

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

  /// Runs [fn] without tracking any dependencies.
  static T untracked<T>(T Function() fn) {
    if (_derivationStack.isEmpty) return fn();
    final prevStack = List<NanoDerivation>.from(_derivationStack);
    _derivationStack.clear();
    try {
      return fn();
    } finally {
      _derivationStack.addAll(prevStack);
    }
  }

  /// [Internal] Batch depth counter.
  static int _batchDepth = 0;

  /// [Internal] Pending atoms to notify.
  static final List<Atom> _pendingNotifications = [];

  /// [Internal] Set of atoms currently flushing in the batch.
  static final Set<Atom> _flushingAtoms = {};

  /// [Internal] Returns true if Nano is currently flushing a batch.
  static bool get isFlushing => _flushingAtoms.isNotEmpty;

  /// [Internal] Returns true if the given atom is currently in the flush queue.
  static bool isFlushingAtom(Atom atom) => _flushingAtoms.contains(atom);

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
        final pending = List<Atom>.from(_pendingNotifications);
        _pendingNotifications.clear();

        // Reset flags first to ensure consistency
        for (final atom in pending) {
          atom._isPending = false;
        }

        // Add to flushing set for glitch prevention checks
        _flushingAtoms.addAll(pending);

        try {
          // Then notify
          for (final atom in pending) {
            // Remove current from flushing set so dependents don't wait on it
            _flushingAtoms.remove(atom);

            // Since `_batchDepth` is 0, this will trigger actual listeners.
            atom._notifyBatch();
          }
        } finally {
          _flushingAtoms.clear();
        }
      }
    }
  }

  /// Initialize Nano for debugging. Usually called by Scope.
  static void init() {
    // Middleware injection is now handled by Scope and NanoConfig.
    NanoDebugService.init();
  }
}

/// Interface for anything that depends on Atoms (Computed, Reaction).
abstract class NanoDerivation {
  String get debugLabel;
  Iterable<Atom> get dependencies;
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

/// Interface for intercepting the lifecycle of an action.
/// Useful for analytics, performance profiling, and logging.
abstract class NanoMiddleware {
  /// Called when an action starts.
  void onActionStart(String name);

  /// Called when an action ends.
  void onActionEnd(String name);
}

/// Default observer that prints to console in debug mode.
class _DefaultObserver implements NanoObserver {
  @override
  void onChange(Atom atom, dynamic oldValue, dynamic newValue) {
    if (kDebugMode) {
      debugPrint(
        '?? NANO [${atom.label ?? atom.runtimeType}]: $oldValue -> $newValue',
      );
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
/// Implements [ValueListenable] with extra powers:
/// 1. Logging via [NanoObserver].
/// 2. Helper methods like [update].
///
/// Example:
/// ```dart
/// final count = Atom(0, label: 'counter');
/// count.set(10);
/// count.update((v) => v + 1);
/// ```
abstract class Atom<T> extends ChangeNotifier
    with Diagnosticable
    implements ValueListenable<T> {
  static const _sentinel = Object();

  @override
  T get value;
  set value(T newValue);

  String? get label;
  Map<String, dynamic> get meta;
  T Function(Map<String, dynamic>)? get fromJson;

  void set(T newValue);

  /// Creates a derived [ComputedAtom] that selects a sub-field from this atom.
  /// It only notifies when the selected value actually changes.
  Atom<R> select<R>(R Function(T value) selector, {String? label}) {
    return computed(() => selector(value),
        label: label ?? '${this.label ?? 'Atom'}.select');
  }

  /// [Internal] Flag to track if this atom is already pending notification in the current batch.
  bool _isPending = false;
  bool _disposed = false;

  factory Atom(T initial,
      {String? label,
      Map<String, dynamic> meta,
      T Function(Map<String, dynamic>)? fromJson}) = ValueAtom<T>;

  /// Internal constructor for subclasses.
  @protected
  Atom.internal();

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // Internal helper for batching
  void _notifyBatch() {
    if (Nano._batchDepth > 0) {
      if (!_isPending) {
        _isPending = true;
        Nano._pendingNotifications.add(this);
      }
    } else {
      notifyListeners();
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
}

/// A concrete [Atom] that holds a mutable value.
class ValueAtom<T> extends Atom<T> {
  T _value;

  @override
  final String? label;
  @override
  final Map<String, dynamic> meta;
  @override
  final T Function(Map<String, dynamic>)? fromJson;

  ValueAtom(T initial, {this.label, this.meta = const {}, this.fromJson})
      : _value = initial,
        super.internal() {
    NanoDebugService.registerAtom(this);
  }

  @override
  T get value {
    Nano.reportRead(this);
    return _value;
  }

  @override
  set value(T newValue) => set(newValue);

  @override
  void set(T newValue) {
    if (_value == newValue) return;

    final initContext = Nano.initContext;
    final isAsyncInit = initContext != null && !initContext.isValid;

    if (Nano.logic?.isInitializing == true || isAsyncInit) {
      final violationType = isAsyncInit ? 'Asynchronous' : 'Synchronous';
      throw '''
[Nano] Side-effect Violation ($violationType)
--------------------------------------------
You are updating an Atom (${label ?? runtimeType}) during 'onInit'.
State updates are forbidden in 'onInit' to ensure predictable initialization.
${isAsyncInit ? '⚠️ DETECTED ASYNC WORK: This update happened after an await in onInit.' : ''}

✅ Fix (Use onReady):
@override
void onReady() {
  ${label ?? 'atom'}.value = newValue;
}

✅ Fix (Use microtask if absolutely necessary):
@override
void onInit(params) {
  Future.microtask(() => ${label ?? 'atom'}.value = newValue);
}
''';
    }

    if (NanoConfig.strictMode && !Nano.isInAction) {
      throw '''
[Nano] Strict Mode Violation
---------------------------
You are updating an Atom (${label ?? runtimeType}) outside of an action.
Actions are required in strict mode to ensure state traceability.

✅ Good (Dispatching an Action):
// 1. Define an Action
class Increment extends NanoAction {}

// 2. Handle it in your Logic
@override
void onAction(NanoAction action) {
  if (action is Increment) counter.value++;
}

// 3. Dispatch from UI
logic.dispatch(Increment());

✅ Use Nano.action (for one-off logic):
Nano.action(() {
  atom.value++;
});

❌ Bad:
atom.value++;
''';
    }

    final oldValue = _value;
    _value = newValue;
    Nano.observer.onChange(this, oldValue, newValue);
    _notifyBatch();
  }

  /// Internal setter to bypass the [set] method (and its overrides).
  void _innerSet(T newValue) {
    _value = newValue;
    _notifyBatch();
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
class ComputedAtom<T> extends Atom<T> implements NanoDerivation {
  @override
  String get debugLabel => label ?? 'ComputedAtom';

  @override
  Iterable<Atom> get dependencies => _observing;

  final T Function() _selector;
  T? _actualValue;
  bool _hasValue = false;

  @override
  T get value {
    Nano.reportRead(this);
    if (_isDirty) {
      _compute();
    }
    return _actualValue as T;
  }

  @override
  set value(T _) => throw UnsupportedError('ComputedAtom is read-only');

  @override
  final String? label;

  @override
  Map<String, dynamic> get meta => const {};

  @override
  T Function(Map<String, dynamic>)? get fromJson => null;

  Set<Atom> _observing = {};
  Set<Atom>? _newObserving;
  bool _isDirty = true;
  bool _isActive = false;

  ComputedAtom(this._selector, {this.label}) : super.internal() {
    _isDirty = true;
    NanoDebugService.registerDerivation(this);
    // Initial compute to establish initial value and dependencies
    _compute();
  }

  void _innerSet(T newValue) {
    _actualValue = newValue;
    _hasValue = true;
    _notifyBatch();
  }

  @override
  void set(T newValue) => throw UnsupportedError('ComputedAtom is read-only');

  @override
  void addListener(VoidCallback listener) {
    _activate();
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    _deactivateIfNeeded();
  }

  void _activate() {
    if (!_isActive) {
      _isActive = true;
      if (_isDirty) {
        _compute();
      }
    }
  }

  void _deactivateIfNeeded() {
    if (!hasListeners && _isActive) {
      _isActive = false;
      _stopObserving();
    }
  }

  void _stopObserving() {
    for (final atom in _observing) {
      atom.removeListener(_handleDependencyChange);
    }
    _observing.clear();
    _isDirty = true;
  }

  void _handleDependencyChange() {
    if (!_isDirty) {
      _isDirty = true;
      if (_isActive) {
        _compute(); // Eager update when active to ensure surgical notifications
      }
    }
  }

  void _compute() {
    if (_disposed) return;
    if (Nano.isFlushing) {
      for (final atom in _observing) {
        if (Nano.isFlushingAtom(atom)) return;
      }
    }

    final previousNewObserving = _newObserving;
    _newObserving = {};

    try {
      final newValue = Nano.track(this, _selector);

      // Diffing Strategy:
      // 1. Unsubscribe from atoms in _observing that are NOT in _newObserving
      for (final atom in _observing) {
        if (!_newObserving!.contains(atom)) {
          atom.removeListener(_handleDependencyChange);
        }
      }

      _observing = _newObserving!;
      _isDirty = false;

      if (!_hasValue || _actualValue != newValue) {
        final oldValue = _hasValue ? _actualValue : Atom._sentinel;
        Nano.observer.onChange(this, oldValue, newValue);
        _innerSet(newValue);
      }
    } finally {
      _newObserving = previousNewObserving;
    }
  }

  @override
  void addDependency(Atom atom) {
    if (_newObserving != null && _newObserving!.add(atom)) {
      if (!_observing.contains(atom)) {
        atom.addListener(_handleDependencyChange);
      }
    }
  }

  @override
  void update(T Function(T current) fn) {
    throw UnsupportedError('ComputedAtom is read-only');
  }

  @override
  T call([dynamic newValue = Atom._sentinel]) {
    return value;
  }

  @override
  void dispose() {
    NanoDebugService.unregisterDerivation(this);
    _stopObserving();
    super.dispose();
  }
}

/// Creates a [ComputedAtom] that automatically tracks all [Atom]s accessed within [selector].
ComputedAtom<T> computed<T>(T Function() selector, {String? label}) {
  return ComputedAtom<T>(selector, label: label);
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
class AsyncAtom<T> extends ValueAtom<AsyncState<T>> {
  int _session = 0;

  AsyncAtom({AsyncState<T> initial = const AsyncIdle(), String? label})
      : super(initial, label: label);

  Future<void> track(Future<T> future) {
    final currentSession = ++_session;
    Nano.action(() => set(AsyncLoading<T>()));

    return future.then((data) {
      if (_session == currentSession) {
        Nano.action(() => set(AsyncData<T>(data)));
      }
    }).catchError((e, s) {
      if (_session == currentSession) {
        Nano.action(() {
          set(AsyncError<T>(e, s));
          Nano.observer.onError(this, e, s);
        });
      }
    });
  }
}

/// An [Atom] that manages the state of a [Stream].
class StreamAtom<T> extends ValueAtom<AsyncState<T>> {
  StreamSubscription<T>? _subscription;

  StreamAtom(
    Stream<T> stream, {
    AsyncState<T> initial = const AsyncLoading(),
    String? label,
  }) : super(initial, label: label) {
    _subscription = stream.listen(
      (data) => Nano.action(() => set(AsyncData<T>(data))),
      onError: (e, s) {
        Nano.action(() {
          set(AsyncError<T>(e, s));
          Nano.observer.onError(this, e, s);
        });
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
class DebouncedAtom<T> extends ValueAtom<T> {
  final Duration duration;
  Timer? _debounce;

  DebouncedAtom(super.value, {required this.duration, super.label});

  @override
  void set(T newValue) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(duration, () {
      Nano.action(() => super.set(newValue));
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

/// An [Atom] that automatically throttles its value.
///
/// Ensures that updates are performed at most once per [duration].
class ThrottledAtom<T> extends ValueAtom<T> {
  final Duration duration;
  Timer? _timer;
  T? _pendingValue;
  bool _isThrottling = false;

  ThrottledAtom(super.value, {required this.duration, super.label});

  @override
  void set(T newValue) {
    if (_isThrottling) {
      _pendingValue = newValue;
      return;
    }

    Nano.action(() => super.set(newValue));
    _isThrottling = true;
    _timer = Timer(duration, () {
      _isThrottling = false;
      if (_pendingValue != null) {
        set(_pendingValue as T);
        _pendingValue = null;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// A handle for registering disposers within a [ResourceAtom].
class ResourceRef {
  final void Function(void Function() disposer) _onDispose;
  ResourceRef(this._onDispose);

  /// Registers a [disposer] that will be called when the [ResourceAtom] is disposed.
  void onDispose(void Function() disposer) => _onDispose(disposer);
}

/// An [Atom] that manages the lifecycle of an external resource.
///
/// It provides a [ResourceRef] to its factory for registering cleanup logic.
class ResourceAtom<T> extends ValueAtom<T> {
  final List<void Function()> _disposers = [];

  ResourceAtom._(super.value, {super.label});

  factory ResourceAtom(T Function(ResourceRef ref) factory, {String? label}) {
    final ds = <void Function()>[];
    final initialValue = factory(ResourceRef(ds.add));
    final atom = ResourceAtom._(initialValue, label: label);
    atom._disposers.addAll(ds);
    return atom;
  }

  @override
  void dispose() {
    for (final d in _disposers) {
      try {
        d();
      } catch (e, s) {
        Nano.observer.onError(this, e, s);
      }
    }
    super.dispose();
  }
}

/// Ergonomic extensions for time-based atom transformations.
extension AtomTimeControlExtension<T> on Atom<T> {
  /// Returns a new [Atom] that debounces updates from this atom.
  Atom<T> debounce(Duration duration) {
    final debounced = DebouncedAtom<T>(value, duration: duration);
    addListener(() => debounced.set(value));
    return debounced;
  }

  /// Returns a new [Atom] that throttles updates from this atom.
  Atom<T> throttle(Duration duration) {
    final throttled = ThrottledAtom<T>(value, duration: duration);
    addListener(() => throttled.set(value));
    return throttled;
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
class PersistedAtom<T> extends ValueAtom<T> {
  final String key;
  final NanoStorage? _customStorage;
  final T Function(String)? fromString;
  final String Function(T)? toJson;

  /// The storage backend to use for this atom.
  /// Falls back to [Nano.storage] if not provided.
  NanoStorage get storage => _customStorage ?? Nano.storage;

  PersistedAtom(
    super.initial, {
    required this.key,
    this.fromString,
    this.toJson,
    NanoStorage? storage,
    super.label,
    super.meta,
  }) : _customStorage = storage {
    _load();
  }

  Future<void> _load() async {
    try {
      final stored = await storage.read(key);
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
    if (value == newValue) return;
    super.set(newValue);
    _save(newValue);
  }

  Future<void> _save(T val) async {
    try {
      await storage.write(key, _encode(val));
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
    if (toJson != null) return toJson!(val);
    return val.toString();
  }
}

/// Alias for [PersistedAtom] for a more concise API.
typedef PersistAtom<T> = PersistedAtom<T>;

@Deprecated(
    'Use computed(() => selector(parent.value)) or atom.select() instead')
class SelectorAtom<T, R> extends ComputedAtom<R> {
  SelectorAtom(Atom<T> parent, R Function(T) selector, {String? label})
      : super(() => selector(parent.value), label: label);
}

extension AtomSelectorExtension<T> on Atom<T> {
  /// Selects a specific part [R] of the state [T].
  ///
  /// The resulting [Atom<R>] will only notify when [R] changes.
  Atom<R> select<R>(R Function(T) selector, {String? label}) {
    return computed(
      () => selector(value),
      label: label ?? '${this.label ?? "Atom"}.select',
    );
  }
}

extension StreamNanoExtension<T> on Stream<T> {
  /// Converts a [Stream] into a [StreamAtom].
  StreamAtom<T> toStreamAtom({
    AsyncState<T> initial = const AsyncLoading(),
    String? label,
  }) =>
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
  /// Converts any value to an [Atom].
  ///
  /// Example:
  /// ```dart
  /// final count = 0.toAtom(label: 'count');
  /// ```
  Atom<T> toAtom({String? label, Map<String, dynamic> meta = const {}}) =>
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

/// A factory for [Atom]s indexed by a key of type [K].
///
/// Use this to manage collections of atoms (e.g., one AsyncAtom per user ID)
/// without manual map management.
class AtomFamily<K, T extends Atom> {
  final T Function(K key) _factory;
  final Map<K, T> _cache = {};

  AtomFamily(this._factory);

  /// Returns the atom associated with [key].
  /// Creates it using the factory if it doesn't already exist in the cache.
  T call(K key) {
    return _cache.putIfAbsent(key, () => _factory(key));
  }

  /// Removes the atom associated with [key] from the cache.
  /// Note: This does not automatically dispose the atom if it's a [ResourceAtom].
  void remove(K key) => _cache.remove(key);

  /// Clears all atoms from the cache.
  void clear() => _cache.clear();

  /// Returns all currently cached keys.
  Iterable<K> get keys => _cache.keys;

  /// Returns all currently cached atoms.
  Iterable<T> get values => _cache.values;
}
