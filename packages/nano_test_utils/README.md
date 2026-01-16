# Nano Test Utils

Utilities for testing Nano logic and widgets with a focus on "Snapshot Testing".

## NanoTestHarness

The `NanoTestHarness` allows you to record the state transitions of your `NanoLogic` and verify them against "Golden" JSON files.

### Usage

```dart
test('My complex flow', () async {
  final logic = MyLogic();
  final harness = NanoTestHarness(logic);

  await harness.record((logic) async {
    logic.doSomething();
    logic.doSomethingElse();
  });

  harness.expectSnapshot('my_flow_name');
});
```

### Golden File Management

- **Creation:** The first time a test runs, if the golden file doesn't exist in `test/goldens/`, it will be created automatically.
- **Verification:** On subsequent runs, the harness compares the new recording with the saved JSON.
- **Updating:** If you intentionally change your logic, run the test with:
  ```bash
  flutter test --dart-define=UPDATE_GOLDENS=true
  ```

### CI / Continuous Integration

⚠️ **CRITICAL: Protection Against "Lazy Updates"**

In a CI environment (GitHub Actions, etc.), the `--dart-define=UPDATE_GOLDENS=true` flag should **never** be used.

1. **Source of Truth:** This ensures that the code in the repository is always verified against the established baseline.
2. **Review Process:** If a logic change is intentional, the developer must run the update command **locally**, verify the resulting JSON diff is correct, and **commit the updated JSON file** as part of their Pull Request.
3. **Audit Trail:** This makes logic changes visible during code review, as reviewers can see exactly how the state transitions have evolved in the JSON diff.
