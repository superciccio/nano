# 🗺️ Nano Evolution Roadmap

This document outlines the strategic roadmap for evolving the `nano` library, prioritizing developer experience and explicit, robust features.

## 🚀 Phase 1: Developer Joy (Nano Test Matchers)

**Goal**: Make testing reactive state delightful and expressive.
**Artifact**: `package:nano/test.dart`.

### Tasks
- [x] **Design Matcher API**:
    - `emits(value)` checks for a single next value.
    - `emitsInOrder([v1, v2])` checks a sequence.
- [ ] **Implement `NanoTester`**:
    - A utility to pump the event loop and capture atom emissions without boilerplate.
    - `await user.emit(Loading, Data(User))`.
- [ ] **Integration** (Pending Approval):
    - Verify `barbutov2` logic with new matchers to prove usability.

### Example
```dart
test('Login flow', () async {
  final logic = LoginLogic();
  
  expect(
    logic.user, 
    emitsInOrder([
      isAsyncIdle,
      isAsyncLoading,
      hasData(User('Andrea')),
    ])
  );
  
  logic.login();
});
```

---

## ⚡ Phase 2: Feature Power (Nano Forms)

**Goal**: Make form validation pure, reactive, and reusable.
**Target**: `barbutov2` Login and "Edit Intervento" screens.

### Tasks
- [x] **Core Components**:
    - `FieldAtom<T>`: Holds value, error message, and `validate()` method.
    - `FormAtom`: Aggregates fields and computes overall `isValid`.
- [x] **Validators**:
    - Built-in library: `required`, `email`, `minLength`, `max`.
    - Custom validator support (lambda functions).
- [ ] **Refactor Barbutov2** (Pending Approval):
    - Replace `TextEditingController` logic in `HistoryLogic` (or new logic) with `NanoForms`.

### Example
```dart
final email = FieldAtom('', [Validators.required, Validators.email]);
final password = FieldAtom('', [Validators.minLength(8)]);
final form = FormAtom([email, password]);

// In UI
TextField(
  errorText: email.error, 
  onChanged: email.set
);
```

---

## 🧹 Phase 3: Cleanup (Auto-Persistence)

**Goal**: Remove boilerplate for simple state storage.
**Target**: `barbutov2` Settings (Theme, Language).

### Tasks
- [ ] **`PersistAtom<T>`**:
    - Wraps `Atom<T>`.
    - Requires `key` and `Storage` interface.
- [ ] **Storage Interface**:
    - `write(key, value)`, `read(key)`, `delete(key)`.
    - Default implementation for `SharedPreferences`.
- [ ] **Refactor Barbutov2** (Pending Approval):
    - Migrate `ThemeMode` state to `PersistAtom`.

### Example
```dart
// Auto-loads on creation, auto-saves on set
final theme = PersistAtom('theme_key', ThemeMode.system);
```

---

## 🔮 Phase 4: Beyond Magic (Future Concepts)

**Goal**: Powerful features inspired by Riverpod/MobX but kept **explicit** (No `build_runner`, No magic globals).

### 1. Smart Caching (Explicit Families)
- **Problem**: Fetching data for dynamic IDs (e.g., `User(1)`, `User(2)`) without manual Map management.
- **Solution**: `AtomCache<Key, Atom<T>>`.
    ```dart
    final userCache = AtomCache((id) => AsyncAtom.track(fetchUser(id)));
    
    // Usage: Explicitly asking for a specific atom
    final user1 = userCache(1);
    ```

### 2. Time Control (Transformers)
- **Problem**: Search inputs spamming the API.
- **Solution**: Explicit method extensions for atoms.
    ```dart
    final search = Atom('');
    // Returns a ReadOnlyAtom that updates at most every 500ms
    final debouncedSearch = search.debounce(500.ms);
    ```

### 3. Parallel Power (Isolate Atoms)
- **Problem**: Heavy filtering logic freezing UI.
- **Solution**: `WorkerAtom` that runs `computed` logic in a `compute()` definition.
    ```dart
    // Logic runs in background, result synced to main thread
    final filtered = WorkerAtom((read) {
        final list = read(allItems);
        return list.where((i) => heavyCheck(i)).toList();
    });
    ```

### 4. Precision Selectors (.select)
- **Problem**: Widget rebuilds when *any* part of a large object changes (e.g., `User`), even if you only display `user.name`.
- **Solution**: `atom.select()` returns a derived atom that checks equality on the sub-field.
    ```dart
    final user = Atom(User(name: 'Andrea', age: 30));
    // ONLY updates when name changes, ignores age
    final nameAtom = user.select((u) => u.name);
    ```

### 5. Scope Overrides (Testing & Previews)
- **Problem**: Testing a Widget in isolation (Storybook) often requires mocking global state.
- **Solution**: `NanoScope` widget that intercepts atom lookups.
    ```dart
    NanoScope(
      overrides: [
        userAtom.overrideWithValue(MockUser()),
      ],
      child: UserProfile(),
    );
    ```

### 6. Smart Refresh (Async Retries)
- **Problem**: "Pull to Refresh" usually requires manually re-calling the repository method.
- **Solution**: `AsyncAtom` remembers the last `track`'s future generator.
    ```dart
    // In UI
    RefreshIndicator(
      onRefresh: () => myData.refresh(), // Re-runs the last tracking logic
      child: ...
    )
    ```

### 7. Resource Atoms (Auto-Dispose)
- **Problem**: Managing StreamSubscriptions or WebSockets that need to close when the Atom is no longer needed.
- **Solution**: `ResourceAtom` with a `ref.onDispose` hook.
    ```dart
    final streamAtom = ResourceAtom((addDisposer) {
        final sub = stream.listen(...);
        addDisposer(() => sub.cancel()); // Auto-closes
        return sub;
    });
    ```

### 8. Nano Clusters (Isolated Contexts)
- **Problem**: Building a Super App where "Mini Apps" need completely isolated state but share a core.
- **Solution**: `NanoContainer` instances that can be nested or peered.
    ```dart
    final core = NanoContainer();
    final miniApp = core.fork(); // Inherits core atoms but has its own memory
    ```

### 9. State Replay (Hot Restart Persistence)
- **Problem**: Hot Restart kills all state. Iterating on complex deep-link flows is painful.
- **Solution**: A dev-only hook that serializes the *entire atomic graph* to a temp file before shutdown and rehydrates it on startup.
    - Result: **Hot Restart feels like Hot Reload** but for Logic.

### 10. Remote Inspector (WebSocket Server)
- **Problem**: Debugging a bug that only happens on a physical device in the field (no USB).
- **Solution**: Embed a tiny `NanoServer`.
    - `telnet 192.168.1.5 8080`
    - `> ls atoms`
    - `> get user`
    - `> set theme "dark"`
