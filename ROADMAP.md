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
