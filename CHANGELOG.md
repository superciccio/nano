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
