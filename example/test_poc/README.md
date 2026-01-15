# Nano Test PoC: Snapshot Testing

This directory demonstrates a "Snapshot Testing" approach for Nano Logic, enabling developers to verify complex state transitions with minimal code.

## The Concept

Instead of writing dozens of explicit assertions:
```dart
expect(logic.status.value, 'loading');
expect(logic.items.value, isEmpty);
// ... wait ...
expect(logic.status.value, 'success');
```

You record the entire session and compare it against a "Golden" history:
```dart
await harness.record((logic) async {
  logic.login();
  await harness.settled();
  logic.addToCart('Apple');
});

harness.verifyMatches(goldenJson);
```

## Pros & Cons

### Pros
1.  **Extreme Velocity:** You can write a test for a complex user flow (Login -> Browse -> Checkout) in minutes.
2.  **Regression Safety:** The snapshot captures *everything*. If a side-effect (like a loading spinner not turning off, or a stray error flag) happens, the snapshot diff will catch it. You don't need to remember to assert every single field.
3.  **Readable History:** The JSON output serves as documentation for exactly how the state evolves over time.
4.  **Implicit Async Handling:** The harness handles waiting for `AsyncAtom`s, reducing flakiness and `Future.delayed` hacks.

### Cons
1.  **Fragility:** Like UI Goldens, if you change an internal implementation detail (e.g., an intermediate state you didn't care about), the test fails.
2.  **Merge Conflicts:** If multiple developers update the same flow, resolving conflicts in a large JSON file can be painful.
3.  **"Blind" Approval:** Developers might just run `update_goldens` without verifying the output is actually correct, cementing bugs into the baseline.

## Roadmap to Reality

To make this PoC a production-ready testing library for Nano, the following tasks are required:

### 1. Robust Serialization
*   **Task:** Implement a comprehensive `StateEncoder`.
*   **Details:** The current PoC uses simple `toString()` or `toJson()`. We need to handle:
    *   Circular references.
    *   Non-primitive types (DateTime, Enums, Custom Objects) automatically.
    *   Masking sensitive data (passwords).

### 2. File System Integration
*   **Task:** Implement real Golden File management.
*   **Details:**
    *   `harness.verify(id)` should look for `test/goldens/{id}.json`.
    *   Add a flag `--update-goldens` to automatically overwrite the file with the new result.
    *   Ensure cross-platform consistency (line endings, path separators).

### 3. Generator Integration
*   **Task:** Generate the `Harness` classes automatically.
*   **Details:**
    *   Annotate logic with `@NanoTest`.
    *   Generate a `UserFlowHarness` that automatically mocks dependencies (using `mockito` or `mocktail`) and injects them into the Logic.
    *   Generate typed helper methods (e.g., `harness.verifyState(StateEnum.loading)`).

### 4. Diffing Tooling
*   **Task:** Improve failure messages.
*   **Details:** When a snapshot fails, printing two giant JSON blobs is unhelpful. We need a smart diff tool that prints:
    ```
    Mismatch at step 4:
    - status: "loading"
    + status: "error"
    ```

### 5. Async Stability
*   **Task:** Harden the `settled()` logic.
*   **Details:** Ensure it correctly tracks:
    *   `AsyncAtom` loading states.
    *   `DebouncedAtom` timers.
    *   Microtasks and standard Futures.
    *   Timeout safety (throw if logic hangs).
