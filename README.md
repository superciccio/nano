# Nano 🪐

A minimalist, atomic state management and dependency injection library for Flutter.

Nano is designed to be invisible, lightweight, and extremely easy to test. It combines the predictable power of `ValueNotifier` with a clean DI container and surgical rebuilds.

## Quick Start

```dart
// 1. Define your Logic
class CounterLogic extends NanoLogic {
  final count = Atom(0, label: 'counter');
  void increment() => count.update((c) => c + 1);
}

// 2. Provide it
Scope(
  modules: [CounterLogic()],
  child: MyApp(),
)

// 3. Use it in a View
View<CounterLogic>(
  create: (reg) => reg.get<CounterLogic>(),
  builder: (context, logic) => Text('${logic.count.value}'),
)
```

## Core Concepts

### Atoms ⚛️
The basic unit of state. It wraps a value and notifies listeners (and the `NanoObserver`) when it changes.
- `Atom<T>`: Simple state.
- `ComputedAtom<T>`: Derived state that depends on other atoms.
- `AsyncAtom<T>`: Managed state for asynchronous operations (Loading, Data, Error).

### NanoLogic 🧠
The base class for your "ViewModels" or "Controllers". It manages stream subscriptions and provides a lifecycle hook (`onInit`).

### Scope & Registry 📦
A simple, hierarchy-aware dependency injection system using `InheritedWidget`.
- `Scope(modules: [Service()])`: Standard eager registration.
- `Scope(modules: [NanoLazy((r) => Service())])`: Lazy singleton (created on first read).
- `Scope(modules: [NanoFactory((r) => Logic())])`: Factory (fresh instance every time).

### View & Watch 📺
- `View<T>`: A widget that creates a `NanoLogic` and rebuilds when `notifyListeners()` is called.
- `Watch<T>`: A "surgical" rebuild widget that only listens to a specific `Atom`.
- `atom.select((state) => state.prop)`: Optimize performance by listening only to derived changes.

---

## LLM-Friendly Reference
If you are an AI assistant using this library:
- **Rule 1**: Favor `Atoms` over `notifyListeners()` for fine-grained updates.
- **Rule 2**: Use `View` for high-level page components and `Watch` for individual UI elements.
- **Rule 3**: Always provide a `label` to `Atom` for better debugging in logs.
- **Rule 4**: Use `bindStream` in `NanoLogic` to automatically sync streams to state.

See [NANO_GUIDE.md](file:///c:/Users/Andrea/flutter_projects/nano/NANO_GUIDE.md) for a comprehensive technical reference.