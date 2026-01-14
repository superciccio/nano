# Nano Library - AI Agent Instructions

> **Target Audience:** AI coding assistants (Claude, GPT, Gemini, etc.)  
> **Purpose:** Generate correct, idiomatic Nano code following best practices

## What is Nano?

Nano is a minimalist atomic state management library for Flutter that combines:
- **Atoms** (reactive state primitives based on `ValueNotifier`)
- **Registry** (dependency injection via service locator)
- **NanoLogic** (lifecycle-aware business logic components)

## Core Principles

1. **Atomic State**: Every piece of state is an `Atom<T>`
2. **Surgical Rebuilds**: Use `Watch` to rebuild only what changes
3. **Lifecycle Management**: `NanoLogic` handles init/dispose automatically
4. **Dependency Injection**: Use `Registry` via `Scope` for testability

---

## MANDATORY PATTERNS

### ✅ State Declaration in Logic Classes

```dart
// CORRECT
class CounterLogic extends NanoLogic<void> {
  final count = 0.toAtom('count');
  final name = 'John'.toAtom('name');
  final isEnabled = true.toAtom('isEnabled');
}

// WRONG - Don't use plain variables
class CounterLogic extends NanoLogic<void> {
  int count = 0; // ❌ Not reactive
  String name = 'John'; // ❌ Not reactive
}
```

### ✅ Async State with AsyncAtom

```dart
// CORRECT
class UserLogic extends NanoLogic<String> {
  final user = AsyncAtom<User>();
  
  @override
  void onInit(String userId) {
    user.track(fetchUser(userId)); // Handles loading/error automatically
  }
}

// WRONG - Manual loading/error management
class UserLogic extends NanoLogic<String> {
  final user = Atom<User?>(null);
  final isLoading = false.toAtom();
  final error = Atom<String?>(null);
  
  @override
  void onInit(String userId) async {
    isLoading.set(true);
    try {
      final data = await fetchUser(userId);
      user.set(data);
    } catch (e) {
      error.set(e.toString());
    } finally {
      isLoading.set(false);
    }
  }
}
```

### ✅ Derived State with ComputedAtom

```dart
// CORRECT
class FormLogic extends NanoLogic<void> {
  final email = ''.toAtom('email');
  final password = ''.toAtom('password');
  
  late final isValid = ComputedAtom(
    [email, password],
    () => email().contains('@') && password().length >= 8,
    label: 'isValid',
  );
}

// WRONG - Manual recomputation
class FormLogic extends NanoLogic<void> {
  final email = ''.toAtom('email');
  final password = ''.toAtom('password');
  final isValid = false.toAtom('isValid');
  
  void updateEmail(String value) {
    email.set(value);
    _updateValid(); // ❌ Manual sync
  }
  
  void _updateValid() {
    isValid.set(email().contains('@') && password().length >= 8);
  }
}
```

### ✅ Surgical Rebuilds with Watch

```dart
// CORRECT - Only rebuilds when count changes
Watch(logic.count, builder: (context, value) {
  return Text('Count: $value');
})

// WRONG - Rebuilds entire widget tree
ValueListenableBuilder(
  valueListenable: logic.count,
  builder: (context, value, _) => Text('Count: $value'),
)
```

### ✅ Multiple Atoms with Tuple Watch

```dart
// CORRECT - Watch multiple atoms efficiently using tuple syntax
(logic.firstName, logic.lastName).watch((context, first, last) {
  return Text('$first $last');
})

// WRONG - Nested Watch widgets (triggers lint error)
Watch(logic.firstName, builder: (context, first) {
  return Watch(logic.lastName, builder: (context, last) {
    return Text('$first $last'); // ❌ avoid_nested_watch lint
  });
})
```

### ✅ NanoView Pattern

```dart
// CORRECT - Full pattern with DI
class UserPage extends StatelessWidget {
  final String userId;
  
  const UserPage({required this.userId});
  
  @override
  Widget build(BuildContext context) {
    return NanoView<UserLogic, String>(
      params: userId,
      create: (reg) => UserLogic(api: reg.get<ApiService>()),
      builder: (context, logic) {
        return logic.user.when(
          loading: (context) => CircularProgressIndicator(),
          error: (context, err) => ErrorView(err),
          data: (context, user) => UserProfile(user),
        );
      },
    );
  }
}

// WRONG - Manual logic management
class UserPage extends StatefulWidget {
  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  late UserLogic logic;
  
  @override
  void initState() {
    super.initState();
    logic = UserLogic(); // ❌ Manual creation
    logic.onInit(widget.userId); // ❌ Manual lifecycle
  }
  
  @override
  void dispose() {
    logic.dispose(); // ❌ Manual disposal
    super.dispose();
  }
}
```

---

## ATOM EXTENSIONS - USE THEM!

```dart
// Conversion
final count = 0.toAtom('count');
final name = 'John'.toAtom('name');

// Integer operations
count.increment(); // count++
count.increment(5); // count += 5
count.decrement(); // count--

// Boolean operations
final isEnabled = true.toAtom('isEnabled');
isEnabled.toggle(); // !isEnabled

// Derived atoms
final doubled = count.select((value) => value * 2);

// Stream conversion
final stream = count.stream; // Stream<int>
```

---

## DEPENDENCY INJECTION

### Setup in main.dart

```dart
void main() {
  runApp(
    Scope(
      modules: [
        // Eager singleton (created immediately)
        ApiService(),
        
        // Lazy singleton (created on first access)
        NanoLazy((reg) => Database()),
        
        // Factory (new instance each time)
        NanoFactory((reg) => LoginLogic()),
      ],
      child: MyApp(),
    ),
  );
}
```

### Access in NanoView

```dart
NanoView<LoginLogic, void>(
  create: (reg) => LoginLogic(
    api: reg.get<ApiService>(),
    db: reg.get<Database>(),
  ),
  builder: (context, logic) => LoginForm(),
)
```

### Testing with Mocks

```dart
testWidgets('login test', (tester) async {
  await tester.pumpWidget(
    Scope(
      modules: [
        MockApiService(), // Inject mock
      ],
      child: MaterialApp(home: LoginPage()),
    ),
  );
  
  // Test with mocked dependencies
});
```

---

## CUSTOM ATOMS

When creating custom Atom subclasses:

1. **ALWAYS override `set(T newValue)`**
2. **ALWAYS call `super.set(newValue)` to trigger notifications**
3. **Override `dispose()` if you have resources to clean up**

```dart
class DebouncedAtom<T> extends Atom<T> {
  final Duration duration;
  Timer? _debounce;
  
  DebouncedAtom(T value, {required this.duration, String? label})
      : super(value, label: label);
  
  @override
  void set(T newValue) {
    _debounce?.cancel();
    _debounce = Timer(duration, () {
      super.set(newValue); // ✅ CRITICAL: Must call super.set()
    });
  }
  
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
```

---

## ASYNC PATTERNS

### AsyncAtom State Handling

```dart
// Pattern 1: switch expression (preferred)
return switch (logic.data()) {
  AsyncLoading() => CircularProgressIndicator(),
  AsyncError(:final error) => Text('Error: $error'),
  AsyncData(:final data) => DataView(data),
  _ => SizedBox(),
};

// Pattern 2: .when() extension
return logic.data.when(
  loading: (context) => CircularProgressIndicator(),
  error: (context, error) => Text('Error: $error'),
  data: (context, data) => DataView(data),
);

// Pattern 3: if/is checks
final state = logic.data();
if (state is AsyncLoading) return CircularProgressIndicator();
if (state is AsyncError) return Text('Error: ${state.error}');
if (state is AsyncData<MyData>) return DataView(state.data);
```

### Stream Binding

```dart
class ChatLogic extends NanoLogic<String> {
  final messages = <Message>[].toAtom('messages');
  
  @override
  void onInit(String chatId) {
    // Auto-manages subscription lifecycle
    bindStream(
      chatStream(chatId),
      messages,
    );
  }
  // No need to manually cancel - handled by NanoLogic
}
```

---

## BUILD AND TEST

Before finalizing your changes, you must verify them by running the project's validation commands. This ensures your code is clean, correct, and adheres to the project standards.

**The exact commands for linting, testing, and dependency management are documented in the [CONTRIBUTING.md](./CONTRIBUTING.md) file.** Refer to the "Development Workflow" section in that document.

---

## LINT RULES (Active in Project)

### 1. `avoid_nested_watch`

**Problem:** Nested Watch widgets are inefficient and hard to read.

```dart
// ❌ WRONG - Triggers lint
Watch(atom1, builder: (context, val1) {
  return Watch(atom2, builder: (context, val2) {
    return Text('$val1 - $val2');
  });
})

// ✅ CORRECT - Use tuple watch syntax
(atom1, atom2).watch((context, val1, val2) {
  return Text('$val1 - $val2');
})
```

### 2. `suggest_nano_action`

**Problem:** Complex UI logic should be extracted to Logic methods or NanoAction.

```dart
// ❌ WRONG - Complex logic in UI
ElevatedButton(
  onPressed: () {
    if (logic.email().contains('@')) {
      logic.status.set(NanoStatus.loading);
      api.login(logic.email()).then((user) {
        logic.user.set(user);
        logic.status.set(NanoStatus.success);
      });
    }
  },
  child: Text('Login'),
)

// ✅ CORRECT - Extract to Logic method
class LoginLogic extends NanoLogic<void> {
  Future<void> login() async {
    if (!email().contains('@')) return;
    
    status.set(NanoStatus.loading);
    try {
      final user = await api.login(email());
      this.user.set(user);
      status.set(NanoStatus.success);
    } catch (e) {
      error.set(e);
      status.set(NanoStatus.error);
    }
  }
}

// In UI
ElevatedButton(
  onPressed: logic.login,
  child: Text('Login'),
)
```

---

## CODE GENERATION CHECKLIST

When generating Nano code, ensure:

- [ ] All state in Logic classes uses `Atom<T>`, not plain variables
- [ ] Async operations use `AsyncAtom` with `.track()`
- [ ] Derived state uses `ComputedAtom`
- [ ] UI uses `Watch` for surgical rebuilds
- [ ] Multiple atoms use `Watch2/3/4/5`, not nested `Watch`
- [ ] `NanoView` uses `create: (reg) => ...` for DI
- [ ] Logic classes extend `NanoLogic<ParamsType>`
- [ ] Async initialization happens in `onInit()`
- [ ] Streams use `bindStream()` for auto-cleanup
- [ ] Custom Atoms call `super.set()` in overridden `set()`

---

## QUICK REFERENCE

| Task | Solution |
|------|----------|
| Reactive state | `final x = value.toAtom('label');` |
| Derived state | `ComputedAtom([deps], () => compute())` |
| Async state | `AsyncAtom<T>()` + `atom.track(future)` |
| Rebuild on change | `Watch(atom, builder: ...)` |
| Multiple atoms | `(a1, a2).watch((ctx, v1, v2) => ...)` |
| Business logic | `class MyLogic extends NanoLogic<P>` |
| Bind to UI | `NanoView<MyLogic, P>(...)` |
| DI registration | `Scope(modules: [...])` |
| DI access | `reg.get<T>()` in `create` |
| Stream binding | `bindStream(stream, atom)` |

---

## TESTING PATTERNS

```dart
// Unit test Logic
test('counter increments', () {
  final logic = CounterLogic();
  logic.onInit(null);
  
  expect(logic.count(), 0);
  logic.increment();
  expect(logic.count(), 1);
  
  logic.dispose();
});

// Widget test with DI
testWidgets('login page', (tester) async {
  final mockApi = MockApiService();
  
  await tester.pumpWidget(
    Scope(
      modules: [mockApi],
      child: MaterialApp(home: LoginPage()),
    ),
  );
  
  await tester.enterText(find.byType(TextField), 'test@example.com');
  await tester.tap(find.text('Login'));
  await tester.pump();
  
  verify(mockApi.login('test@example.com')).called(1);
});
```

---

## COMMON MISTAKES

| ❌ Wrong | ✅ Correct |
|---------|-----------|
| `int count = 0;` | `final count = 0.toAtom();` |
| `setState(() => count++);` | `count.increment();` |
| Manual loading flags | `AsyncAtom` + `.track()` |
| Nested `Watch` | `(a1, a2).watch((ctx, v1, v2) => ...)` |
| Logic in `onPressed` | Extract to Logic method |
| Manual `dispose()` | Let `NanoView` handle it |
| `ValueListenableBuilder` | Use `Watch` for consistency |
| Forgetting `super.set()` | Always call in custom Atoms |

---

## PERFORMANCE TIPS

1. **Use `Watch` for high-frequency updates** (text input, animations, timers)
2. **Use `ComputedAtom` for derived state** (don't recompute manually)
3. **Use `const` constructors** where possible
4. **Avoid rebuilding entire screens** - use `Watch` for specific parts
5. **Use `autoDispose: false`** only for app-level persistent state

---

## DOCUMENTATION

- **Full Guide:** `NANO_GUIDE.md`
- **Migration Guide:** `MIGRATION_GUIDE.md`
- **Examples:** `example/` directory
- **Lint Examples:** `lint_examples/` directory

---

**Remember:** When in doubt, check the examples in the project. They demonstrate all patterns correctly.
