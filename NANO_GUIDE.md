# Nano AI Guide 🤖

This document provides a technical reference for LLMs working with the Nano state management library.

## Core API Reference

### 1. `Atom<T>`
```dart
class Atom<T> extends ValueNotifier<T> {
  final String? label;
  Atom(T initialValue, {this.label});
  void set(T newValue); // Replaces value
  void update(T Function(T current) fn); // Transform from current
}
```

### 2. `ComputedAtom<T>`
Derived state that reacts to other `Atoms`.
```dart
class ComputedAtom<T> extends ValueNotifier<T> {
  ComputedAtom(List<ValueListenable> dependencies, T Function() selector);
}
```

### 3. `AsyncAtom<T>`
Manages async state: `AsyncIdle`, `AsyncLoading`, `AsyncData`, `AsyncError`.
Tracks sessions to prevent race conditions (latest `track` wins).
```dart
class AsyncAtom<T> extends Atom<AsyncState<T>> {
  Future<void> track(Future<T> future);
}
```

### 4. `SelectorAtom<T, R>`
Optimized atom that only notifies when the derived value changes.
```dart
final nameAtom = userAtom.select((user) => user.name);
```

### 5. `NanoLogic`
Base class for logic. Use `bindStream` to link streams to atoms.
```dart
abstract class NanoLogic extends ChangeNotifier {
  void onInit();
  void bindStream<T>(Stream<T> stream, Atom<T> atom);
}
```

## Dependency Injection (Smart)

- **Eager**: `Scope(modules: [MyService()])`
- **Lazy**: `Scope(modules: [NanoLazy((r) => MyService())])`
- **Factory**: `Scope(modules: [NanoFactory((r) => MyLogic())])`

## Architectural Rules

1. **State as Atoms**: Individual properties should be `Atoms`. Use `notifyListeners()` only for aggregate or legacy updates.
2. **Dependency Injection**: Use `Scope` at the top of the feature. Access dependencies via `reg.get<T>()` in the `View.create` factory.
3. **Rebuilds**:
   - `View` = Rebuilds entire sub-tree when `notifyListeners()` is called.
   - `Watch` = Rebuilds only its builder when the specific atom changes.
4. **Lifecycle**: Initialize async work in `onInit()`. `View` automatically calls `dispose()` on the logic.

## Best Practices

- **Labels**: Always provide a `label` to `Atoms` for debug logging.
- **Surgicality**: Favor `Watch` for high-frequency updates (e.g., text input, animations).
- **Sealed States**: Use `switch` statements on `asyncAtom.value` for exhaustive UI state handling.
