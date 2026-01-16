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
  AsyncAtom({bool keepPreviousData = true}); // Default: true (Sticky Data)
  Future<void> track(Future<T> future);
}
```

**"Sticky Data" (keepPreviousData):**
By default, `AsyncAtom` retains the last successful data during loading and even error states. This prevents UI flickering when refreshing data. Access this data via `.dataOrNull` (or `.value` in legacy code).

**States:**
- `AsyncIdle`
- `AsyncLoading`
- `AsyncData<T>` (access data via `.data`)
- `AsyncError` (access error via `.error`, `.stackTrace`)

### `PersistAtom<T>` (aliased to `PersistedAtom`)
An `Atom` that automatically persists its value to a storage backend (default: `InMemoryStorage`).

**Signature:**
```dart
class PersistAtom<T> extends Atom<T> {
  PersistAtom(T initial, {
    required String key,
    T Function(String)? fromString,
    String Function(T)? toJson, // New in 0.7.0
    NanoStorage? storage,      // New in 0.7.0
    String? label,
  });
}
```

**Setup Storage:**
By default, persistence is in-memory. To use real storage (e.g., SharedPreferences), implement `NanoStorage` and provide it via `Scope`:

```dart
class SharedPrefsStorage implements NanoStorage {
  // Implement read/write/delete...
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final storage = SharedPrefsStorage(prefs);

  runApp(Scope(
    config: NanoConfig(storage: storage),
    modules: [...],
    child: MyApp(),
  ));
}
```

### `AtomFamily<K, T>`
A factory for atoms indexed by a key. This is useful for managing collections of state (e.g., users by ID) without manual map management.

> [!IMPORTANT]
> **Avoid Global Families**: Like Atoms, families should be encapsulated within a `NanoLogic` or registered in a `Scope`. Do not define them as global variables.

**Example: Inside NanoLogic**
```dart
class ProfileLogic extends NanoLogic<void> {
  // The family is owned and encapsulated by this logic
  final profileFamily = AtomFamily<int, AsyncAtom<User>>((id) {
    return AsyncAtom<User>(label: 'user_$id')..track(fetchUser(id));
  });

  // Accessing a specific atom
  AsyncAtom<User> getUser(int id) => profileFamily(id);
}
```

### Time Control: Debounce & Throttle
Any atom can be transformed into a time-aware atom using extensions.

```dart
// Debounce: Wait 300ms after the LAST update before notifying
final searchAtom = Atom('').debounce(Duration(milliseconds: 300));

// Throttle: Update at most once every 300ms
final scrollAtom = Atom(0.0).throttle(Duration(milliseconds: 300));
```

### `WorkerAtom<P, R>`
Offloads heavy computations to a background isolate. This is essential for maintaining 60/120 FPS when processing large datasets.

```dart
final heavyResults = WorkerAtom<List<Data>, List<Result>>(
  source: rawDataAtom,
  worker: (data) => performComplexCalculation(data), // Runs in Isolate
);

// Use in UI like any AsyncAtom
heavyResults.when(
  data: (context, results) => ListView(...),
  loading: (context) => CircularProgressIndicator(),
  error: (context, error) => ErrorWidget(error),
);
```

### `ResourceAtom<T>`
Manages resources that require explicit cleanup (e.g., Stream subscriptions, Sockets, Timers).

```dart
final chatAtom = ResourceAtom<List<Message>>((ref) {
  final sub = socket.messages.listen((msg) => ...);
  
  // Register cleanup that runs when the atom is disposed
  ref.onDispose(() => sub.cancel());
  
  return []; // Initial value
});
```

### Scope Overrides (Testing)
You can mock dependencies in a specific subtree by using the `overrides` parameter in `Scope`. Overrides take precedence over `modules`.

```dart
testWidgets('My Test', (tester) async {
  await tester.pumpWidget(
    Scope(
      modules: [RealApiService()],
      overrides: [MockApiService()], // This will be resolved instead of the real one
      child: MyApp(),
    ),
  );
});
```

**Signature:**
```dart
class AtomFamily<K, T extends Atom> {
  AtomFamily(T Function(K key) factory);

  /// Returns the atom for [key], creating it if necessary.
  T call(K key);

  /// Removes an entry from the cache.
  void remove(K key);
}
```

### `NanoLogic<P>`
Base class for Business Logic Components (BLoC/ViewModel).

**Key Features:**
- `onInit(P params)`: Lifecycle hook.
- `status`: `Atom<NanoStatus>` (loading, success, error, empty).
- `error`: `Atom<Object?>`.
- `bind(Listenable, listener)`: Auto-manages subscriptions (e.g., `TextEditingController`).
- `bindStream(stream, atom)`: Auto-manages stream subscriptions.
- `dispose()`: Auto-called by `NanoView`.

**NanoStatus Enum:**
- `loading`: Initial state or active loading.
- `success`: Operation completed successfully.
- `error`: Operation failed.
- `empty`: No data available.

## 2. Modern Nano (Generated) 🚀

Modern Nano uses code generation to provide a "SwiftUI-like" developer experience. It eliminates the need for manual `Atom` definitions and explicit `.watch()` calls.

### `@nano` & `@state`
Annotate your logic base class with `@nano`. Use `@state` for standard fields.

```dart
@nano
abstract class _UserLogic extends NanoLogic {
  @state String name = '';
  @state int age = 0;
  
  void birthday() => age++; // Direct mutation!
}

class UserLogic extends _UserLogic with _$UserLogic {
  UserLogic();
}
```

**Generated Features:**
- **Property Unwrapping**: The generator creates a private `Atom` and overrides the field getter/setter to use it.
- **Atom Access**: Use the `$` suffix to access the underlying Atom instance (e.g., `name$`).

### `@async` (AsyncAtom)
For asynchronous state, use `@async` on a field of type `AsyncState<T>`.

```dart
@nano
abstract class _QuoteLogic extends NanoLogic {
  @async AsyncState<Quote> quote = const AsyncIdle();
  
  // Required: abstract getter if you want to use quote$ inside this class
  AsyncAtom<Quote> get quote$;

  void fetch() => quote$.track(api.getQuote());
}
```

### `NanoComponent`
A self-contained widget that combines Dependency Injection (`Scope`) and a reactive View.

```dart
class ProfilePage extends NanoComponent {
  @override
  List<Object> get modules => [NanoLazy((_) => UserLogic())];

  @override
  Widget view(BuildContext context) {
    final logic = context.use<UserLogic>();
    return Text('Name: ${logic.name}'); // Automatically tracks usage!
  }
}
```

### Reactive Collections
Built-in mutable collections that trigger UI updates automatically without needing to replace the whole collection.

- `NanoList<E>`
- `NanoMap<K, V>`
- `NanoSet<E>`

```dart
final items = NanoList<String>();
items.add('A'); // UI re-renders automatically
```

## 3. Dependency Injection

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

## 8. Nano Compose DSL 🎨

The Nano Compose DSL allows you to build declarative, concise layouts without the nesting hell of standard Flutter widgets.

### `NanoLayout` & `NanoStack`

Instead of nesting `Padding`, `Column`, `SingleChildScrollView`, and manually adding `SizedBox` for spacing, define your layout properties in `NanoLayout`.

```dart
// OLD: Nested Hell
Padding(
  padding: EdgeInsets.all(16),
  child: SingleChildScrollView(
    child: Column(
      children: [
        Header(),
        SizedBox(height: 8),
        Body(),
        SizedBox(height: 8),
        Footer(),
      ],
    ),
  ),
)

// NEW: Linear & Clean
NanoStack(
  layout: NanoLayout(
    padding: EdgeInsets.all(16),
    spacing: 8,
    scrollable: true,
  ),
  children: [
    Header(),
    Body(),
    Footer(),
  ],
)
```

### `NanoPage`

A shorthand for `Scaffold` + `AppBar`.

```dart
NanoPage(
  title: 'My Profile',
  actions: [IconButton(icon: Icon(Icons.logout), onPressed: logout)],
  body: NanoStack(
    layout: NanoLayout.all(16, spacing: 20),
    children: [...],
  ),
)
```

## 9. Advanced Testing 🧪

Nano provides powerful tools for high-velocity and regression-safe testing.

### Snapshot Testing
Record entire user flows and verify them against a "Golden" JSON state history.

```dart
test('Search flow', () async {
  final harness = NanoTestHarness(SearchLogic());
  
  await harness.record((logic) async {
    logic.updateQuery('Flutter');
    await harness.settled(); // Wait for async results
  });

  harness.expectSnapshot('search_results');
});
```

**Workflow:**
1. **Creation**: Run test once to generate `test/goldens/search_results.json`.
2. **Regression**: Subsequent runs fail if logic changes.
3. **Update**: Run with `--dart-define=UPDATE_GOLDENS=true` to accept new changes.

### `NanoWidgetTester` Helpers
Extensions for `WidgetTester` to make integration tests cleaner.

- `tester.pumpSettled()`: Deterministically waits for all Nano async operations to finish.
- `tester.read<T>()`: Resolves a Logic/Service from the active Scope.
- `find.atom(atom)`: Verifies if any widget in the tree is watching a specific atom.

```dart
nanoTestWidgets('Clicking updates count',
  builder: () => const MyPage(),
  verify: (tester) async {
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpSettled();
    
    final logic = tester.read<MyLogic>();
    expect(logic.count, 1);
    expect(find.atom(logic.count$), findsOneWidget);
  },
);
```

## 10. DevTools Extension

Nano includes a powerful DevTools extension to help you debug your application.

**Features:**
- **Atom Inspector**: View the real-time state of all registered Atoms.
- **State History**: Track the history of state changes with timestamps.
- **Time Travel**: Revert your application state to any previous point in time.

To use the DevTools extension, simply run your application in debug mode and open the Flutter DevTools.

## 11. Static Analysis & Lints (`nano_lints`)

The `nano_lints` package provides a set of custom lint rules to help you write correct and idiomatic Nano code.

**Available Rules:**
- `avoid_atom_outside_logic`: Ensures that Atoms are only created inside `NanoLogic` or `Service` classes.
- `logic_naming_convention`: Enforces that `NanoLogic` classes are named with a `Logic` suffix.
- `refactor_to_nano`: Suggests refactoring `StatefulWidget`s to `NanoComponent`s.
- `migrate_from_provider`: Helps migrate from the `provider` package to Nano.
- `migrate_from_signals`: Helps migrate from the `signals` package to Nano.
- `avoid_nested_watch`: Prevents nesting `Watch` widgets and suggests using tuple syntax.
- `suggest_nano_action`: Suggests creating a `NanoAction` for complex UI callbacks.

To use the lints, add `nano_lints` and `custom_lint` to your `dev_dependencies` in `pubspec.yaml` and enable the plugin in `analysis_options.yaml`.
