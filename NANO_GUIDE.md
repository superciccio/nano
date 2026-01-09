# Nano AI Guide 🤖

> **SYSTEM PROMPT:** Use this document as the ground truth for generating, analyzing, and refactoring Nano code.

Nano is a minimalist, atomic state management and dependency injection library for Flutter. It combines `ValueNotifier` (Atoms) with a clean Service Locator (Registry) and lifecycle-aware Logic components.

## 1. Core Primitives

### `Atom<T>`
The fundamental unit of state. Wraps a `ValueNotifier` with logging and helper methods.

**Signature:**
```dart
class Atom<T> extends ValueNotifier<T> {
  Atom(T value, {String? label});

  // Get value
  T call();

  // Set value
  T call(T newValue);

  // Update value
  T call(T Function(T) updater);

  void set(T newValue);
  void update(T Function(T current) fn);
}
```

**Extensions (Syntactic Sugar):**
- `.toAtom([label])`: Converts any value to an Atom.
- `.increment([amount])`: For `Atom<int>`.
- `.decrement([amount])`: For `Atom<int>`.
- `.toggle()`: For `Atom<bool>`.
- `.select<R>(selector)`: Creates a `SelectorAtom` derived from the parent.
- `.stream`: Converts the Atom (or any `ValueListenable`) into a `Stream<T>` that emits current value and subsequent updates.

## 1.1 Creating Custom Atoms

You can create your own specialized `Atom`s by extending the base `Atom` class. This is useful for adding custom logic to the state update process.

The most important method to override is `set(T newValue)`. When overriding `set`, make sure to call `super.set(newValue)` to trigger the actual state update and notify listeners.

**Example: A `DebouncedAtom`**

Here is the implementation of `DebouncedAtom`, which is included in the library. It delays updates by a given duration, which is useful for features like search-as-you-type.

```dart
import 'dart:async';

class DebouncedAtom<T> extends Atom<T> {
  final Duration duration;
  Timer? _debounce;

  DebouncedAtom(T value, {required this.duration, String? label})
      : super(value, label: label);

  @override
  void set(T newValue) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(duration, () {
      super.set(newValue); // The actual update happens here
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
```

### A Note on Safety: The `value` Setter

The base `Atom` class overrides the standard `ValueNotifier.value` setter to ensure that all state changes, whether through `atom.value = ...` or `atom.set(...)`, are routed through our custom logic. This guarantees that the `NanoObserver` is always notified.

```dart
class Atom<T> extends ValueNotifier<T> {
  // ...
  @override
  set value(T newValue) {
    // Ensures our custom logic is always called
    set(newValue);
  }

  void set(T newValue) {
    if (value == newValue) return;
    Nano.observer.onChange(label, value, newValue);
    super.value = newValue; // Calls the original ValueNotifier setter
  }
  // ...
}
```

### `ComputedAtom<T>`
Derived state that automatically updates when dependencies change.

**Signature:**
```dart
class ComputedAtom<T> extends ValueNotifier<T> {
  ComputedAtom(List<ValueListenable> dependencies, T Function() selector, {String? label});
}
```

### `AsyncAtom<T>`
Manages asynchronous state (`AsyncIdle`, `AsyncLoading`, `AsyncData`, `AsyncError`). Handles race conditions automatically (latest `track` wins).

**Signature:**
```dart
class AsyncAtom<T> extends Atom<AsyncState<T>> {
  Future<void> track(Future<T> future);
}
```

**States:**
- `AsyncIdle`
- `AsyncLoading`
- `AsyncData<T>` (access data via `.data`)
- `AsyncError` (access error via `.error`, `.stackTrace`)

### `NanoLogic<P>`
Base class for Business Logic Components (BLoC/ViewModel).

**Key Features:**
- `onInit(P params)`: Lifecycle hook.
- `status`: `Atom<NanoStatus>` (loading, success, error, empty).
- `error`: `Atom<Object?>`.
- `bindStream(stream, atom)`: Auto-manages stream subscriptions.
- `dispose()`: Auto-called by `NanoView`.

**NanoStatus Enum:**
- `loading`: Initial state or active loading.
- `success`: Operation completed successfully.
- `error`: Operation failed.
- `empty`: No data available.

## 2. Dependency Injection

### `Scope`
InheritedWidget that provides the `Registry` to the tree.

**Usage:**
```dart
Scope(
  modules: [
    AuthService(), // Eager singleton
    NanoLazy((r) => Database()), // Lazy singleton
    NanoFactory((r) => LoginLogic()), // Factory
  ],
  child: MyApp(),
)
```

### `Registry`
Service locator accessible via `Scope.of(context)` or `context.read<T>()`.

## 3. UI Components

### `NanoView<T, P>`
Smart widget that binds `NanoLogic` to the UI.

**Features:**
- **Auto-Injection**: Uses `create` factory to inject Logic.
- **Auto-Lifecycle**: Calls `onInit` and `dispose`.
- **State Switching**: Automatically switches UI based on `logic.status` if `loading`, `error`, or `empty` builders are provided.
- **Auto-Dispose**: Controls logic disposal via `autoDispose` parameter (defaults to `true`).

**Signature:**
```dart
NanoView<MyLogic, MyParams>(
  params: myParams,
  create: (reg) => reg.get<MyLogic>(),
  builder: (context, logic) => MyWidget(),
  loading: (context) => Loader(), // Optional
  error: (context, err) => ErrorView(err), // Optional
  autoDispose: false, // Optional: Keep logic alive after view disposal
)
```

### `Watch<T>`
Surgical rebuild widget. Only rebuilds its child when the specific atom changes.

**Usage:**
```dart
Watch(logic.count, builder: (context, value) => Text('$value'))
```

## 4. Coding Rules & Patterns

**Rule 1: Atomic State**
- **Do:** Use `Atom<T>` for individual fields.
- **Do:** Use `ComputedAtom` for derived state.
- **Don't:** Rely solely on `notifyListeners()` (unless migrating legacy code).

**Rule 2: Surgical Rebuilds**
- **Do:** Use `Watch` for high-frequency updates (inputs, timers, animations).
- **Do:** Use `NanoView` for page-level state switching.

**Rule 3: Logic Lifecycle**
- **Do:** Initialize async data in `onInit()`.
- **Do:** Use `bindStream` for streams to avoid memory leaks.

**Rule 4: DI & Testing**
- **Do:** Use `Registry` (via `reg.get<T>()`) in `NanoView.create`.
- **Do:** Use `Scope` to mock dependencies in tests by providing mock modules.

**Rule 5: Async Safety**
- **Do:** Use `AsyncAtom.track(future)` to automatically handle loading/error states and race conditions.
- **Do:** Use Dart Pattern Matching (switch) on `AsyncState` subclasses OR use the `.when()` extension.

## 5. Example Snippet

```dart
class UserLogic extends NanoLogic<String> {
  final user = AsyncAtom<User>();

  @override
  void onInit(String userId) {
    // Auto-handles loading, error, and race conditions
    user.track(fetchUser(userId));
  }
}

class UserPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NanoView<UserLogic, String>(
      params: 'user_123',
      create: (r) => UserLogic(),
      builder: (context, logic) {
        // Surgical watch on async state using .when()
        return logic.user.when(
          loading: (context) => CircularProgressIndicator(),
          error: (context, error) => Text('Error: $error'),
          data: (context, data) => Text('User: ${data.name}'),
        );
      },
    );
  }
}
```
