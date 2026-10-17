# Research and plan: the import guard test covers the root CLAUDE.md

Brief: `docs/working/briefs/2026-10-17-claude-md-import-guard.md` (at 2fad41c1).
Date: 2026-10-17. Workflow: research-plan-implement, no plan gate; divergent design inline.

## Findings

- `test/agents-gemini-sync.bats` test 3 ("AGENTS.md and the global instructions have no
  @-imports") loops over `AGENTS.md` and `global-instructions/CLAUDE.md` only. The root
  `CLAUDE.md` (added 83b653d2, reworded 4272a32b) claims this test checks it. The claim is
  false at 2fad41c1.
- The header comment above `find_imports` (lines 30-35) still says Claude Code loads
  `AGENTS.md` as project instructions. Since 4272a32b the root `CLAUDE.md` exists, so Claude
  Code loads it and not `AGENTS.md`. `AGENTS.md` is still the entry point for other agents
  (and `GEMINI.md` mirrors it), so the rule still applies to it.
- The root `CLAUDE.md` has no `@` imports today: `find_imports CLAUDE.md` returns 1 (no
  match). Its only `@`-adjacent text is inside code spans, which the finder strips.
- Nothing else references the test's name (rg over the repo), so renaming it is safe.
  `scripts/lib/dev-cycle-read.sh` and the known-issues doc mention the file, not the test name.

## Design (divergent design, seeded with H1-H4, S1-S11 and the brief)

| Option | What | S3 (one code path) | H2 (failure named) | Size (S8/S9) |
|---|---|---|---|---|
| A | Factor the loop into `check_no_imports FILE...`; add the root `CLAUDE.md` to the list; the firing case and a missing-file case call the same helper | one path; the firing case exercises the real check | yes, names the file | about +25 lines, one revert |
| B | A separate `@test` for the root `CLAUDE.md` only | two copies of the loop body | yes | similar, but duplicates logic |
| C | Glob every `CLAUDE.md` in the repo | one path | yes | widens scope to fixture or nested files the brief does not name; S9 says minimal |

A dominates: B restates the check (S3), C widens scope with no motive (S5, S9). Decision: A.
No hook, gate or launcher changes (H1 untouched); the check stays deterministic (H4).

## Plan

1. In `test/agents-gemini-sync.bats`, add `ROOT_CLAUDE="$REPO_ROOT/CLAUDE.md"` in `setup()`.
2. Rewrite the header comment: the root `CLAUDE.md` is what Claude Code loads as project
   instructions here (4272a32b); `AGENTS.md` is held to the rule because other agents read
   it as their entry point; the global file loads in every project.
3. Add `check_no_imports FILE...`: for each file, fail with "<file> is missing or
   unreadable" if `[ -r ]` is false, and fail with the file name and the matches if
   `find_imports` matches. Returns non-zero on any failure.
4. Test 3 becomes "AGENTS.md, the root CLAUDE.md and the global instructions have no
   @-imports", calling `check_no_imports` on the three files.
5. New test: a scratch copy of the root `CLAUDE.md` with one `@./x.md` line appended is
   reported (non-zero status, output names the scratch file and the `@./x.md` line); a
   missing path fails with the missing-or-unreadable message.
6. Doc change: the root `CLAUDE.md`'s parenthetical ("`test/agents-gemini-sync.bats`
   checks") becomes true after step 4, so it is left as is. Decision log row 65 is not edited.
7. Verify: `bats test/agents-gemini-sync.bats`, `scripts/hermeticity-lint --root .`, and a
   mutation (drop the root file from the list, add an import to the root file in a scratch
   copy of the test setup) to show the new list entry is load-bearing.

Out of scope (brief): `find_imports` grammar, `AGENTS.md`, `GEMINI.md`,
`global-instructions/CLAUDE.md`.

Paths touched: `test/agents-gemini-sync.bats`, this doc, the brief's Status line.
