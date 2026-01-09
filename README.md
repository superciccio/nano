# Nano 🪐

**The invisible state management library for Flutter.**

Nano is designed to be **minimalist**, **atomic**, and **testable**. It combines the simplicity of `ValueNotifier` with a clean Dependency Injection system and surgical rebuilds.

---

## ✨ Why Nano?

- **Atomic**: State is broken down into small, independent `Atom`s.
- **Surgical**: `.watch()` extension rebuilds only what changed.
- **Smart**: `NanoView` handles Loading/Error/Empty states automatically.
- **Clean**: Dependency Injection via `Scope` and `Registry` is built-in.
- **Action-Based**: Optional `Action`s provide a structured way to manage state changes.
- **Time-Travel Debugging**: The DevTools extension allows you to inspect and revert state changes.
- **Magic**: Syntactic sugar makes code concise (`count()`, `count(5)`, `count.increment()`).

## 🚀 Quick Start

### 1. The Logic (`NanoLogic`)
Create your business logic. Use `Atom` for state and `Action`s for events.

```dart
// 1. Define your actions
class Increment extends NanoAction {}

// 2. Create your logic
class CounterLogic extends NanoLogic<void> {
  // Sugar: .toAtom() creates an Atom<int>
  final count = 0.toAtom('count');

  @override
  void onAction(NanoAction action) {
    if (action is Increment) {
      count.increment();
    }
  }
}
```

### 2. The Injection (`Scope`)
Wrap your app (or feature) in a `Scope`.

```dart
void main() {
  runApp(
    Scope(
      modules: [
        // Factory: New instance every time
        NanoFactory((r) => CounterLogic()),
      ],
      child: MyApp(),
    ),
  );
}
```

### 3. The View (`NanoView`)
Bind logic to UI. `NanoView` handles creation and disposal.

```dart
class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NanoView<CounterLogic, void>(
      create: (reg) => reg.get<CounterLogic>(), // Inject!
      builder: (context, logic) {
        return Scaffold(
          // Surgical: Only this Text rebuilds!
          body: logic.count.watch((context, value) {
            return Text('Count: $value');
          }),
          floatingActionButton: FloatingActionButton(
            onPressed: () => logic.dispatch(Increment()), // Dispatch an action
            child: Icon(Icons.add),
          ),
        );
      },
    );
  }
}
```

## 🍬 Syntactic Sugar

Nano loves clean code.

| Operation | Standard | Nano Sugar |
| :--- | :--- | :--- |
| **Create** | `Atom<int>(0)` | `0.toAtom()` |
| **Get** | `atom.value` | `atom()` |
| **Set** | `atom.set(5)` | `atom(5)` |
| **Update** | `atom.update((x) => x + 1)` | `atom((x) => x + 1)` |
| **Watch** | `Watch(atom, builder: ...)` | `atom.watch(...)` |
| **Watch Many** | Nested `Watch` widgets | `(atom1, atom2).watch(...)` |
| **Math** | `atom.value++` | `atom.increment()` |
| **Bool** | `atom.value = !atom.value` | `atom.toggle()` |

## 🛠️ DevTools Extension

Nano comes with a powerful DevTools extension to make debugging a breeze.

- **Atoms View**: Inspect the live state of all registered `Atom`s in your application.
- **History View**: See a timeline of all state changes.
- **Time-Travel**: Revert to any previous state by clicking the "Revert" button next to a state change in the history view.

## 🤖 AI / LLM Usage

Are you an AI? **Read `NANO_GUIDE.md`**.
It contains the full technical specification, API signatures, and architectural rules designed specifically for code generation and analysis.

## 📦 Installation

```yaml
dependencies:
  nano:
    path: ./ # Or git url
```

## 📄 License

MIT
