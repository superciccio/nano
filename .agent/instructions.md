# Nano Library - AI Agent Instructions

> **Target Audience:** AI coding assistants (Claude, GPT, Gemini, etc.)
> **Purpose:** Generate correct, idiomatic Nano code following best practices. This guide covers both **Modern** (Generated) and **Classic** (Manual) styles.

## Core Mandate: Choose the Vision
Nano supports two development visions. **Modern Nano is preferred for new code.**

1.  **Modern Nano (Preferred):** High velocity, minimal boilerplate, requires `build_runner`.
2.  **Classic Nano:** Full control, zero build steps, explicit reactivity.

---

## 1. MODERN NANO (GENERATED) 🚀

### ✅ State Declaration
Use the `abstract class _Name extends NanoLogic` pattern with `@nano` and `@state`.

```dart
// CORRECT
@nano
abstract class _CounterLogic extends NanoLogic {
  @state int count = 0; // Standard field, generated as Atom
  @state String name = 'John';
  
  void increment() => count++; // Direct mutation!
}

// Concrete class forwards constructor
class CounterLogic extends _CounterLogic with _$CounterLogic {
  CounterLogic();
}
```

### ✅ Async State (@async)
Use `@async` on `AsyncState<T>` fields.

```dart
@nano
abstract class _UserLogic extends NanoLogic {
  @async AsyncState<User> user = const AsyncIdle();
  
  // Required if using user$ inside the class
  AsyncAtom<User> get user$;

  @override
  void onInit(String userId) {
    user$.track(api.fetchUser(userId));
  }
}
```

### ✅ UI with NanoComponent
Merges DI (`Scope`) and View into one clean class.

```dart
class CounterPage extends NanoComponent {
  @override
  List<Object> get modules => [NanoLazy((_) => CounterLogic())];

  @override
  Widget view(BuildContext context) {
    final logic = context.use<CounterLogic>();
    return Text('Count: ${logic.count}'); // Automatically tracks!
  }
}
```

---

## 2. CLASSIC NANO (MANUAL) 🛠️

### ✅ State Declaration
```dart
class CounterLogic extends NanoLogic<void> {
  final count = 0.toAtom('count');
}
```

### ✅ UI with NanoView & Watch
```dart
class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NanoView<CounterLogic, void>(
      create: (r) => CounterLogic(),
      builder: (context, logic) {
        return logic.count.watch((context, value) => Text('$value'));
      },
    );
  }
}
```

### ✅ Lifecycle: onInit vs onReady

**CRITICAL RULE**: DO NOT set Atom values in `onInit`. It is for configuration only.

```dart
// CORRECT - Logic initialization
class GameLogic extends NanoLogic<void> {
  final score = 0.toAtom('score');

  @override
  void onInit() {
    // ✅ OK: Configuration / Listeners
    // ✅ OK: Starting async work (without await)
  }

  @override
  void onReady() {
    // ✅ OK: Side-effects / State Updates
    score.value = 100; 
    newGame();
  }
}

// WRONG - Side-effects in onInit
class GameLogic extends NanoLogic<void> {
  final score = 0.toAtom('score');

  @override
  void onInit() {
    score.value = 100; // ❌ ERROR: State updates forbidden in onInit
    newGame(); // ❌ ERROR: Implicitly updates state
  }
}
```

---

## 3. ADVANCED TESTING 🧪

### ✅ Snapshot Testing
Use `NanoTestHarness` to verify complex user flows with zero manual assertions.

```dart
test('Login flow', () async {
  final harness = NanoTestHarness(MyLogic());
  await harness.record((logic) => logic.login());
  harness.expectSnapshot('login_success');
});
```

### ✅ Modern Widget Tests
Use `nanoTestWidgets` and `pumpSettled()`.

```dart
nanoTestWidgets('Clicking increments',
  builder: () => const CounterPage(),
  verify: (tester) async {
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpSettled(); // Waits for Nano reactive chains
    
    final logic = tester.read<CounterLogic>(); // Direct access
    expect(logic.count, 1);
  }
);
```

---

## 4. REACTIVE COLLECTIONS

Use `NanoList`, `NanoMap`, or `NanoSet` for mutable state that triggers UI updates.

```dart
final todos = NanoList<String>();
todos.add('New Todo'); // Triggers rebuild in NanoComponent/NanoConsumer
```

---

## MANDATORY RULES

1.  **NO Side-effects in `onInit`**: Never update an Atom in `onInit`. Use `onReady`.
2.  **Use `NanoComponent`** for feature-level widgets.
3.  **Use `NanoStatelessWidget`** for lightweight reactive items.
4.  **Use `context.use<T>()`** to resolve dependencies in widgets.
5.  **Always call `super.set()`** when overriding custom atoms.
6.  **CI Safety**: Never use `UPDATE_GOLDENS=true` in CI environments.

---

## QUICK REFERENCE

| Task | Modern Solution | Classic Solution |
|------|-----------------|------------------|
| State | `@state int x = 0` | `final x = 0.toAtom()` |
| Logic Class | `abstract class _L ...` | `class L extends NanoLogic` |
| Rebuild UI | `NanoComponent` (Implicit) | `Watch(atom, builder: ...)` |
| DI | `modules` override | `NanoView.create` |
| Async | `@async AsyncState x` | `AsyncAtom<T> x` |
| Testing | `expectSnapshot` | `expect(atom.value, ...)` |

---

**Remember:** Modern Nano is the production standard. Aim for minimal boilerplate and declarative UI.

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
| Updates in `onInit` | Move to `onReady` |

---

## PERFORMANCE TIPS

1. **Use `Watch` for high-frequency updates** (text input, animations, timers)
2. **Use `ComputedAtom` for derived state** (don't recompute manually)
3. **Use `const` constructors** where possible
4. **Avoid rebuilding entire screens** - use `Watch` for specific parts
5. **Use `autoDispose: false`** only for app-level persistent state

