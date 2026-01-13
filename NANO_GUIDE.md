# Nano AI Guide 🤖

> **SYSTEM PROMPT:** Use this document as the ground truth for generating, analyzing, and refactoring Nano code.

Nano is a minimalist, atomic state management and dependency injection library for Flutter. It combines `ValueNotifier` (Atoms) with a clean Service Locator (Registry) and lifecycle-aware Logic components.

## 1. Core Primitives

### `Atom<T>`
The fundamental unit of state. Wraps a `ValueNotifier` with logging and helper methods.

**Signature:**
```dart
class Atom<T> extends ValueNotifier<T> {
  Atom(T value, {String? label, Map<String, dynamic> meta = const {}});

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
- `.toAtom([label, meta])`: Converts any value to an Atom.
- `.increment([amount])`: For `Atom<int>`.
- `.decrement([amount])`: For `Atom<int>`.
- `.toggle()`: For `Atom<bool>`.
- `.add(item)`: For `Atom<List>` and `Atom<Set>` (immutable update).
- `.remove(item)`: For `Atom<List>`, `Atom<Set>`, and `Atom<Map>` (immutable update).
- `.clear()`: For `Atom<List>`, `Atom<Set>`, and `Atom<Map>` (immutable update).
- `.put(key, value)`: For `Atom<Map>` (immutable update).
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

### `PersistedAtom<T>`
An `Atom` that automatically persists its value to a storage backend (default: `InMemoryStorage`).

**Signature:**
```dart
class PersistedAtom<T> extends Atom<T> {
  PersistedAtom(T value, {
    required String key,
    T Function(String)? fromString,
    String Function(T)? toStringEncoder,
    String? label,
  });
}
```

**Setup Storage:**
By default, persistence is in-memory. To use real storage (e.g., SharedPreferences), implement `NanoStorage` and assign it in `main()`:

```dart
class SharedPrefsStorage implements NanoStorage {
  // Implement read/write/delete...
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Nano.storage = SharedPrefsStorage(); // Assign before app starts
  runApp(MyApp());
}
```

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

### `Watch<T>` / `AtomBuilder<T>`
Surgical rebuild widget. Only rebuilds its child when the specific atom changes. `AtomBuilder` is an alias for `Watch` with a more standard Flutter builder name.

**Usage:**
```dart
AtomBuilder(atom: logic.count, builder: (context, value) => Text('$value'))
```

### `AsyncAtomBuilder<T>`
Specialized widget for `AsyncAtom` that simplifies state handling.

**Usage:**
```dart
AsyncAtomBuilder(
  atom: logic.user,
  loading: (context) => Loader(),
  error: (context, error) => ErrorText(error),
  data: (context, user) => UserProfile(user),
)
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
- **Don't:** Update atoms directly in `onInit()`. `onInit` should be free of side-effects. Schedule a microtask to update state after `onInit` has completed.

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
  final title = Atom('');

  @override
  void onInit(String userId) {
    // Good: Fetch initial data.
    user.track(fetchUser(userId));

    // Bad: Don't update state directly.
    // title.value = 'User Profile'; // This will throw an error.

    // Good: Schedule a microtask to update state after onInit.
    Future.microtask(() {
      title.value = 'User Profile';
    });
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

## 6. Strict Mode

To help you write more robust and predictable code, Nano provides a "Strict Mode". When enabled, it enforces that all state modifications are made inside an `NanoAction`. This helps to prevent accidental state changes and makes your code easier to debug.

**Enabling Strict Mode**

To enable strict mode, set the `strictMode` flag in your `main` function:

```dart
void main() {
  NanoConfig.strictMode = true;
  runApp(MyApp());
}
```

**How it works**

When strict mode is enabled, any attempt to modify an `Atom` outside of an `NanoAction` will throw a runtime exception. This also includes updating an atom inside `onInit`. This helps you to identify and fix potential issues early in the development process.

**Correct Usage with Strict Mode**

When strict mode is enabled, you should use `NanoAction` to modify your state.

```dart
class IncrementAction extends NanoAction {}

class CounterLogic extends NanoLogic<void> {
  final counter = Atom(0);

  @override
  void onAction(NanoAction action) {
    if (action is IncrementAction) {
      counter.update((v) => v + 1);
    }
  }
}

// In your UI:
logic.dispatch(IncrementAction());
```

## 7. Batch Updates & Glitch Prevention

Nano provides a `Nano.batch()` utility to group multiple state updates into a single notification cycle. This improves performance and ensures topological consistency (glitch prevention) for dependent atoms.

**Usage:**

```dart
Nano.batch(() {
  atom1.value = 10;
  atom2.value = 20;
  // Listeners are NOT notified yet.
});
// Listeners are notified exactly once here.
```

If `atom3` depends on `atom1` and `atom2` (via `ComputedAtom`), it will only recompute once after the batch completes, preventing intermediate "glitch" states.
```
