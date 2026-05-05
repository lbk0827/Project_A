# README.md

Codex working guidelines for this project. Merge with task-specific instructions as needed.

**Tradeoff:** These guidelines prefer correctness and clarity over raw speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Do not assume. Surface uncertainty early. Clarify tradeoffs.**

Before implementing:
- State assumptions explicitly.
- If requirements are ambiguous, list possible interpretations and confirm.
- If a simpler approach exists, propose it.
- If something is unclear, pause and ask a focused question.

## 2. Simplicity First

**Write the minimum code that solves the requested problem.**

- Do not add features that were not requested.
- Avoid abstractions for one-time use.
- Do not add configurability unless requested.
- Do not add defensive handling for impossible scenarios.
- If the solution feels overbuilt, simplify it.

Self-check: "Would a senior engineer call this overcomplicated?" If yes, reduce complexity.

## 3. Surgical Changes

**Change only what is necessary for the request.**

When editing existing code:
- Do not modify unrelated code, comments, or formatting.
- Do not refactor healthy code without request.
- Match the project's existing conventions.
- If unrelated issues are noticed, mention them separately instead of changing them.

When your changes create cleanup work:
- Remove imports/variables/functions made unused by your own change.
- Do not remove pre-existing dead code unless asked.

Diff test: every changed line should map directly to the user request.

## 4. Goal-Driven Execution

**Define success criteria and verify outcomes.**

Translate tasks into checkable goals:
- "Add validation" -> "Add failing tests for invalid inputs, then make them pass"
- "Fix bug" -> "Reproduce with a test or clear repro steps, then verify fix"
- "Refactor X" -> "Confirm behavior parity and test pass before/after"

For multi-step work, use a brief plan:

```text
1. [Step] -> verify: [check]
2. [Step] -> verify: [check]
3. [Step] -> verify: [check]
```

Strong criteria reduce rework and unnecessary back-and-forth.

## 5. Codex Session Notes

- This README is project guidance, not a guaranteed global system rule.
- In each new conversation, explicitly ask Codex to follow this README (or paste/link key parts) for best consistency.
- Higher-priority instructions (system/developer/tool policies) override this file when conflicts exist.

---

**These guidelines are working if:** diffs stay focused, overengineering decreases, and clarification happens before implementation mistakes.
