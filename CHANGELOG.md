## 0.7.0

*   **Phase 3: Cleanup (Auto-Persistence)**:
    *   Introduced `PersistAtom<T>` (alias for `PersistedAtom`) with improved API.
    *   Added explicit `storage`, `fromString`, and `toJson` parameters to `PersistAtom` for better control over serialization.
    *   Implemented `SharedPrefsStorage` to support Flutter's `SharedPreferences` as an easy-to-use persistence backend.
    *   Exposed `_innerSet` as protected to allow custom atoms to update state without triggering side-effects during rehydration.
    *   **Phase 4: Beyond Magic (Smart Caching)**:
        - Introduced `AtomFamily<K, T>` to manage collections of keyed atoms and prevent manual map management.
    *   **Phase 2 Completion (Nano Forms)**:
        - Introduced `FieldAtom<T>` for pure, reactive form validation.
        - Added `FormAtom` to aggregate multiple fields and track whole-form validity.
        - Included built-in `Validators` (`required`, `email`, `minLength`).
    *   **Phase 1 Completion (Nano Test Utilities)**: Added `NanoTester<T>` and `Atom.tester` utility to `package:nano/test.dart` for simplified emission tracking and event loop management in tests.

## 0.6.0

*   **New Feature: Batch Updates & Glitch Prevention**:
    *   Introduced `Nano.batch(() { ... })` to group multiple atom updates into a single notification cycle.
    *   Implemented a glitch prevention mechanism that defers updates of dependent atoms (computed/reactions) until the batch is flushed, ensuring topological consistency.
*   **New Feature: Persistence**:
    *   Added `PersistedAtom<T>` for automatic state persistence.
    *   Added `Nano.storage` interface (defaults to `InMemoryStorage`) to support swappable storage backends (e.g., SharedPreferences, Hive).
*   **New Feature: Collection Extensions**:
    *   Added ergonomic extensions for `Atom<List>`, `Atom<Set>`, and `Atom<Map>` (`.add()`, `.remove()`, `.clear()`, `.put()`) that perform immutable updates.
*   **Improvement: AsyncAtom Safety**:
    *   `AsyncAtom` now tracks sessions to handle race conditions (only the latest `track` call updates the state).
    *   State updates in `AsyncAtom` are now automatically wrapped in `Nano.action` for Strict Mode compliance.
*   **Improvement: ComputedAtom Optimization**:
    *   Enhanced dependency tracking with a diffing strategy to avoid unnecessary unsubscribe/resubscribe operations.
*   **Deprecation**: `SelectorAtom` is now deprecated. Use `computed(() => selector(parent.value))` or `atom.select(selector)` instead.

## 0.5.0

*   **Breaking Change: `toAtom()` Standardization**: Modified `toAtom()` extension to use named parameters (`label`, `meta`) instead of positional ones for consistency with other `Atom` constructors.
*   **Improvement: Robust Strict Mode**:
    *   Wrapped `StreamAtom`, `DebouncedAtom`, and `NanoLogic.bindStream` listeners in `Nano.action` to prevent strict mode violations in asynchronous callbacks.
    *   Ensured DevTools state restoration is wrapped in an action.
*   **Improvement: Memory Management**: `NanoLogic` now properly disposes its internal `status` and `error` atoms, preventing leaks in the debug registry.
*   **Improvement: Scoped DI Delegation**: `Scope` now supports nested registries. A child `Scope` can resolve dependencies registered in its parent's `Scope`.
*   **Improvement: Circular Dependency Detection**: `Registry.get<T>()` now detects circular dependencies and throws a `NanoException` with a clear chain of the conflicting types.
*   **Improvement: DX & Errors**:
    *   Significantly enhanced error messages for Strict Mode and `onInit` side-effect violations with "Good vs Bad" code examples.
    *   Exported `NanoConfig` from the main `nano.dart` library.
*   **Performance**: Optimized `Registry` to cache lazy singletons more efficiently after the first resolution.

## 0.1.0

*   **New Feature: `Action`-Based Architecture**: Introduced `NanoAction` for a more structured way to manage state changes.
*   **New Feature: Time-Travel Debugging**: Added a "History" tab to the DevTools extension with the ability to revert state.
*   **New Feature: `DebouncedAtom`**: A new `Atom` that automatically debounces value updates.
*   **New Feature: `.watch()` Extension**: A new extension method on `ValueListenable` for more concise UI code.
*   **Improvement: Safer `Atom` API**: Overridden the `value` setter in `Atom` to prevent bugs.
*   **Fix**: Fixed a bug where `Atom` extensions bypassed observer notifications.
*   **Fix**: Resolved an issue where `NanoView` would crash if no `Scope` was found.
*   **Documentation**:
    *   Added a guide on creating custom `Atom`s to `NANO_GUIDE.md`.
    *   Improved the documentation for `ComputedAtom`, `AsyncAtom`, and `NanoView`.
    *   Updated `README.md` with the new features and examples.
*   **Tests**:
    *   Added a test suite for the core library.
    *   Added a widget test to ensure `NanoView` fails gracefully without a `Scope`.
    *   Added tests for `DebouncedAtom`.
    *   Updated tests for the example app to use the new `Action`-based architecture.
*   **DevTools**:
    *   Enhanced the DevTools extension to use a `TabBarView` for "Atoms" and "History".
    *   The "Atoms" view now uses a `DataTable` for a more structured display.

## 0.0.1

*   Initial release.
