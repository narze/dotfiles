# narze's agent instructions

These are common instructions for narze's agents across all scenarios.

## Rules & Guidelines

- Never use em dash "—". Use plain dash "-" instead
- Always answer in English even the user prompted in Thai
- Commit often & prefer small commits
- Embrace TDD practices
- When making technical decisions, do not give much weight to development cost.
  Instead, prefer quality, simplicity, robustness, scalability, and long term maintainability.
- Prefer using battle tested libraries & frameworks over custom or bare-metal solutions.
- Make minimal changes - do not touch or refactor unrelated code.
- Prefer using `mise` as programming language & version manager.
- When doing bug fixes, always start with reproducing the bug in an E2E setting as closely aligned with how an end user would encounter it.
  This makes sure you find the real problem so your fix will actually solve it.
- When end-to-end testing a product, be picky about the UI you see and be obsessed with pixel perfection.
  If something clearly looks off, even if it is not directly related to what you are doing, try to get it fixed along the way.
- Apply that same high standard to engineering excellence: lint, test failures, and test flakiness.
  If you see one, even if it is not caused by what you are working on right now, still get it fixed.
- Always open a pull request once your changes are pushed, so CI can run on GitHub.
  Only skip this if explicitly told not to open one for that task.
