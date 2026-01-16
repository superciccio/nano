---
description: Fix a broken build or failing tests by analyzing output and applying targeted fixes.
---

1. **Analyze the Failure**: Run the failing command (e.g., `flutter test`, `dart analyze`, or `dart run build_runner build`) to capture the specific error message and stack trace.
2. **Locate the Error**: Identify the file, line number, and nature of the error from the output.
3. **Inspect Code**: Use `view_file` to read the failing code and its immediate context.
4. **Formulate Fix**:
    *   If it's a **Compilation Error**: Fix typos, imports, or type mismatches.
    *   If it's a **Test Failure**: checks the `expect` vs `actual` values and adjust the test or the logic.
    *   If it's a **Lint Error**: Apply the recommended quick-fix or refactor.
5. **Apply Fix**: Use `replace_file_content` or `multi_replace_file_content` to apply the correction.
6. **Verify**: Rerun the original command to confirm the fix works.
