Commit: dbb15ec6

# Critics, pass 2: Q-092 unit 1 (q092a)

**Scope:** `git diff 1a831ffe..dbb15ec6` in `wt-u1` (branch fix/q092a-drop-deny-option); commits b973e678, dbb15ec6. Earlier commits are committed context.
**Date:** 2026-10-15
**Based on:** `code-fact-check-report-q092a-2026-10-15.md`, `code-fact-check-report-q092a-pass2-2026-10-15.md`, pass-1 rubric `code-review-rubric-2026-10-15-fix-q092a-drop-deny-option.md`
**Roles:** performance-reviewer, api-consistency-reviewer, architecture-review (in that order)

What the delta changes: hook header comments only (`--permissions` description, ROLE paragraph, residual list, SETTINGS SOURCES, rule table); tests (stdout-test comment, a new pipeline / bracket / `?` deny test, the NUL `--permissions` test, the `Bash(ls *)` rule-table test); plan rows F3, F6, F6b, F10. No executable line of the hook changed (`git diff 1a831ffe..dbb15ec6 -- hooks/` touches only `#` lines).

Suite: `timeout 600 bats test/auto-approve-allowed-commands.bats` → 43/43 ok, 0 `not ok` (executed at dbb15ec6).

---

## 1. Performance Review — q092a pass 2

### Data Flow and Hot Paths

The hook runs once per Bash tool call (hot in the sense of per-call, but each call handles one command string and three small settings files). The delta changes no executable code, so the per-call path is unchanged from 1a831ffe. The pass-1 bench (85.6 → 85.9 ms over 20 runs) still applies. The one new test adds about 5 hook runs to the suite, which is CI-only cost.

### Findings

No findings.

### Endorsements (evidence-gated)

- The delta changes no executable line of the hook, so pass 1's per-call measurement still stands. [read: hooks/auto-approve-allowed-commands.sh: every hunk of `git diff 1a831ffe..dbb15ec6 -- hooks/` begins with `#`]

### Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | none | — | — | — |

### Overall Assessment

The delta has no performance surface: it changes comments and tests only.

---

## 2. API Consistency Review — q092a pass 2

### Baseline Conventions

The hook's public surface is its CLI (`--debug`, `--permissions JSON`), its stdout contract (the allow JSON or nothing), and the settings files it reads. The delta changes none of these. It changes one help line: `--permissions` "Use custom allow rules instead of the settings files' allow lists". That line now matches `load_rules` at this commit, which skips settings-file `A` records when `CUSTOM_PERMISSIONS` is set but still reads `D` records (`hooks/auto-approve-allowed-commands.sh:273-279`, read in full, lines 265-288).

### Name-Pattern Audit

The diff introduces no new public names: no flags, fields, keys or exported functions. The new test titles follow the file's existing `rule table: …` and `a … deny rule …` naming.

### Findings

No findings.

Pass-1 items checked against the rubric:
- A1 (NUL test cannot tell a split from a drop): resolved. The test now uses `'["Bash(zz)\u0000Bash(curl:*)"]'`, so a split would approve `curl x`.
- A2 (`Bash(ls *)` "approves nothing"): resolved. The header row and paragraph now say "literal prefix", and the test pins `ls * -la` approved and `ls -la` refused.
- C6 (`--deny` swallowed): Won't-Fix per #123. Still true at this commit, still no caller.

### What Looks Good

- The `--permissions` help line now states exactly what the option replaces (allow lists only), which matches `load_rules`.
- The rule-table test name ("is a literal prefix, not a glob") now describes what it asserts.

### Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | none | — | — | — |

### Overall Assessment

The delta changes no consumer-facing contract. The one wording change brings the help text into line with the code.

---

## 3. Architecture Review — Skipped

**Reason:** The diff does not change module structure, public APIs, data models, or cross-cutting concerns. It changes comments, tests and a plan document only. No executable line of the hook changed.

**Files reviewed for scope:** `hooks/auto-approve-allowed-commands.sh` (comment lines only), `test/auto-approve-allowed-commands.bats`, `docs/working/plan-q092-drop-hook-deny-reader.md`, `docs/reviews/*` (review artifacts).

**Trigger categories evaluated:**
- Module structure: no
- Public APIs: no (the `--permissions` help text changed; its behaviour did not)
- Data models: no
- Cross-cutting concerns: no

If the orchestrator or user believes a structural review is still warranted, re-invoke with an explicit scope or rationale.

---

## Goal-Alignment Note

Goal: land Q-092 as two stacked units, each reviewed clean. For unit 1's pass-2 delta, all three lenses come back clean. The delta fixes pass-1's documentation and test-precision items (A1, A2, A3, A4, C2, C3, C4, C5, C7) and changes no executable code. So nothing here blocks unit 1 from merging into the unit-2 stack. These critics did not re-verify the fact-check-owned items, only that the cited lines now say what the rubric records.
