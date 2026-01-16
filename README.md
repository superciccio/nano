# Nano 🪐

![Coverage](https://img.shields.io/badge/coverage-90%25-brightgreen)

**The invisible state management library for Flutter.**

Nano is designed to be **minimalist**, **atomic**, and **testable**. It combines the simplicity of `ValueNotifier` with a clean Dependency Injection system and surgical rebuilds.

---

## ✨ Choose Your Style

Nano supports two development styles. Both share the same high-performance engine.

### 1. Modern Nano (Generated) 🚀
**Best for: Maximum velocity and minimal boilerplate.** Uses code generation to hide Atoms and automate UI tracking.

```dart
@nano
abstract class _CounterLogic extends NanoLogic {
  @state int count = 0;
  void increment() => count++;
}

class CounterPage extends NanoComponent {
  @override
  List<Object> get modules => [NanoLazy((_) => CounterLogic())];

  @override
  Widget view(context) {
    final logic = context.use<CounterLogic>();
    return Text('Count: ${logic.count}'); // Automatically tracks usage!
  }
}
```

### 2. Classic Nano (Manual) 🛠️
**Best for: Full control and zero build steps.** Uses explicit Atoms and standard widgets.

```dart
class CounterLogic extends NanoLogic {
  final count = Atom(0);
  void increment() => count.value++;
}

class CounterPage extends StatelessWidget {
  @override
  Widget build(context) {
    return NanoView<CounterLogic, void>(
      create: (r) => CounterLogic(),
      builder: (context, logic) {
        return logic.count.watch((context, value) => Text('Count: $value'));
      },
    );
  }
}
```

---

## ✨ Why Nano?

- **Atomic**: State is broken down into small, independent `Atom`s.
- **Surgical**: Rebuilds only what changed, either implicitly (Modern) or explicitly (Classic).
- **Component-Based**: `NanoComponent` merges DI and View into a single, clean class.
- **Reactive Collections**: Built-in `NanoList`, `NanoMap`, and `NanoSet` for mutable state.
- **Snapshot Testing**: Record and verify complex user flows with zero manual assertions.
- **Time-Travel Debugging**: DevTools extension to inspect and revert state changes.

## 🍬 Syntactic Sugar

Nano loves clean code.

| Operation | Classic | Modern (Generated) |
| :--- | :--- | :--- |
| **Logic** | `final count = Atom(0)` | `@state int count = 0` |
| **Mutation** | `count.value++` | `count++` |
| **Read** | `count.value` | `count` |
| **UI** | `logic.count.watch(...)` | `logic.count` (inside `NanoComponent`) |
| **Async** | `final data = AsyncAtom()` | `@async AsyncState data = ...` |

## ⚡ Advanced Features

### Reactive Collections
Use mutable collections that trigger UI updates automatically.

```dart
final todos = NanoList<String>();
todos.add('New Item'); // UI updates automatically!
```

### Snapshot Testing
Test complex flows by comparing state history against a "Golden" JSON.

```dart
test('Login flow', () async {
  final harness = NanoTestHarness(MyLogic());
  await harness.record((logic) => logic.login());
  harness.expectSnapshot('login_success');
});
```

## 🛠️ DevTools Extension

Nano comes with a powerful DevTools extension to make debugging a breeze.

- **Atoms View**: Inspect the live state of all registered `Atom`s.
- **History View**: See a timeline of all state changes.
- **Time-Travel**: Revert to any previous state with one click.

## 🤖 AI / LLM Usage

Are you an AI? **Read `NANO_GUIDE.md`**.
It contains the full technical specification, API signatures, and architectural rules designed specifically for code generation and analysis.

## 📦 Installation

```yaml
dependencies:
  nano:
    path: ./
  nano_annotations:
    path: ./packages/nano_annotations

dev_dependencies:
  build_runner: ^2.4.6
  nano_generator:
    path: ./packages/nano_generator
  nano_test_utils:
    path: ./packages/nano_test_utils
```

## 📄 License

MIT
