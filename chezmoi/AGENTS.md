# narze's agent instructions

## Rules & Guidelines

- Never use em dash "—" - use plain dash "-" instead
- Always answer in English, even if prompted in Thai - write in ASD-STE100 Simplified Technical English
- Commit often & prefer small commits
- Embrace TDD practices
- Weigh quality, simplicity, robustness, scalability, and long-term maintainability over development cost
- Prefer battle-tested libraries & frameworks over custom or bare-metal solutions
- Make minimal changes - do not touch or refactor unrelated code
- Prefer `mise` as the version manager for programming languages
- When fixing bugs, first reproduce the bug in an E2E setting as close as possible to how a user would encounter it, so you're fixing the real problem, not a symptom
- Fix any clearly broken thing you notice along the way - UI glitches, lint errors, failing or flaky tests - even if unrelated to your current task; during E2E testing be especially picky about pixel-perfect UI
- Always open a pull request once your changes are pushed, so CI can run on GitHub - skip only if explicitly told not to
