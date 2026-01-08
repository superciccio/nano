# Nano 🪐

**The invisible state management library for Flutter.**

Nano is designed to be **minimalist**, **atomic**, and **testable**. It combines the simplicity of `ValueNotifier` with a clean Dependency Injection system and surgical rebuilds.

---

## ✨ Why Nano?

- **Atomic**: State is broken down into small, independent `Atom`s.
- **Surgical**: `Watch` only rebuilds what changed.
- **Smart**: `NanoView` handles Loading/Error/Empty states automatically.
- **Clean**: Dependency Injection via `Scope` and `Registry` is built-in.
- **Magic**: Syntactic sugar makes code concise (`count()`, `count(5)`, `count.increment()`).

## 🚀 Quick Start

### 1. The Logic (`NanoLogic`)
Create your business logic. Use `Atom` for state.

```dart
class CounterLogic extends NanoLogic<void> {
  // Sugar: .toAtom() creates an Atom<int>
  final count = 0.toAtom('count');

  // Magic: .increment() is an extension on Atom<int>
  void increment() => count.increment();
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
          body: Watch(logic.count, builder: (context, value) {
            return Text('Count: $value');
          }),
          floatingActionButton: FloatingActionButton(
            onPressed: logic.increment, // Call logic
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
| **Math** | `atom.value++` | `atom.increment()` |
| **Bool** | `atom.value = !atom.value` | `atom.toggle()` |

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
