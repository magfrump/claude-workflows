# Scope Exception: entry-point-consistency-test

## Issue

The test `test/entry-point-consistency.bats` correctly detects that `CLAUDE.md`
lists `bug-diagnosis.md` in its workflow section, but `AGENTS.md` and `GEMINI.md`
do not. This is a genuine inconsistency — not a test bug.

## Why not fixed here

The file scope constraint for this task only allows creating/modifying
`test/entry-point-consistency.bats` and `docs/working/` files. Adding
`bug-diagnosis.md` to `AGENTS.md` and `GEMINI.md` would require modifying
those files, which is out of scope.

## Recommended fix

Add the following line to both `AGENTS.md` and `GEMINI.md` in their
`## Cross-project Workflows` section:

```
- **bug-diagnosis.md** — Lightweight hypothesis-test debugging loop: reproduce → isolate → hypothesize → test → fix → verify. Use for bugs in known areas of code where rapid iteration beats upfront research.
```

After that fix, the test should pass.
