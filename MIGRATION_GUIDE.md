# 🪐 Nano Migration Guide

## 0.5.0 Migration

### `toAtom()` Syntax Change
The `toAtom()` extension has been standardized to use named parameters for better clarity and future extensibility.

**Before:**
```dart
final count = 0.toAtom('counter');
```

**After:**
```dart
final count = 0.toAtom(label: 'counter');
```

**Fix:** You can use a global find & replace or `sed`:
```bash
sed -i "s/\.toAtom('\([^']*\)')/\.toAtom(label: '\1')/g" lib/**/*.dart
```

---


This guide describes how to migrate your existing Flutter project to Nano using the automated refactoring tools.

## 🚀 Automated Refactoring

Nano provides custom lint rules and fixes to help you migrate from common state management patterns.

### 1. Setup
Add `nano_lints` and `custom_lint` to your project's `dev_dependencies`:

```yaml
dev_dependencies:
  custom_lint: ^0.8.0
  nano_lints:
    path: path/to/nano/packages/nano_lints # Or git/pub
```

Enable the plugin in `analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    - custom_lint
```

### 2. Available Rules

| Rule | Targeted Pattern | Suggestions |
| :--- | :--- | :--- |
| `refactor_to_nano` | `StatefulWidget` with `setState` | Refactors to `NanoLogic` + `NanoView`. |
| `migrate_from_provider` | `Provider`, `Consumer`, `context.read<T>()` | Refactors to `context.read<T>()` (Nano version) or `Registry`. |
| `migrate_from_signals` | `signal(val)`, `computed(...)` | Refactors to `val.toAtom()` or `ComputedAtom`. |
| `avoid_nested_watch` | Nested `Watch` widgets | Suggests using tuple syntax `(a, b).watch(...)`. |
| `suggest_nano_action` | Complex logic in UI callbacks | Suggests creating a `NanoAction` and dispatching it. |
| `avoid_atom_outside_logic` | `Atom` created outside `NanoLogic`/`Service` | Enforces proper state encapsulation. |
| `logic_naming_convention` | `NanoLogic` classes not ending in "Logic" | Enforces naming convention. |

### 3. Running a Dry-Run
To see what would be changed without applying the changes permanently, use the provided dry-run script:

```bash
# From the root of your project
/path/to/nano/nano_dry_run.sh
```

### 4. Applying Changes
When you are ready to migrate, run:

```bash
dart run custom_lint --fix
```

## 🛠️ Manual Refactoring Tips

- **Atomic State**: Break down large state objects into individual `Atom`s in your `NanoLogic`.
- **Surgical Rebuilds**: Use `atom.watch((context, value) => ...)` instead of rebuilding the whole widget tree.
- **Tuple Watch**: For multiple atoms, use `(atom1, atom2).watch((context, v1, v2) => ...)` to avoid nesting.
- **Dependency Injection**: Register services in the `Scope` modules and access them via `context.read<T>()` or `registry.get<T>()`.
- **Actions**: For complex UI callbacks (>2 state updates), create a `NanoAction` and dispatch it to keep logic in `NanoLogic`.


## 🤖 Structural Linting
The migration tool uses **Structural Linting**, which means it detects patterns based on code structure rather than strict typing. This allows it to work without requiring `provider` or `signals` as dependencies in your project.
