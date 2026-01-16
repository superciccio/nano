---
description: Update project documentation by analyzing recent code changes.
---

1. **Analyze Changes**:
    *   Run `git log -n 1 --stat` to see the most recent commit and changed files.
    *   Run `git diff HEAD~1 HEAD` (or similar) to inspect the actual code changes.
    *   Identify deeply what changed: New features? API changes? Deprecations?
2. **Identify Target Documents**:
    *   **Core Logic**: If `lib/` changed, check `README.md` and `NANO_GUIDE.md`.
    *   **Agent Rules**: If patterns changed, check `.agent/instructions.md`.
    *   **Public API**: If public classes/methods changed, check `CHANGELOG.md`.
3. **Draft Updates**:
    *   Read the current content of the target documents.
    *   Formulate precise updates that reflect the code changes.
    *   *Constraint*: Do not hallucinate features. Only document what is in the diff.
4. **Apply Updates**:
    *   Use `multi_replace_file_content` to apply the changes.
5. **Verify**:
    *   Read back the changed sections to ensure flow and accuracy.
