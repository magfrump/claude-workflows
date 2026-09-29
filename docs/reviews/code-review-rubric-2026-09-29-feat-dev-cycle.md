Commit: 89a3d3b

# Code Review Rubric

**Scope:** feat/dev-cycle vs main at 89a3d3b (scripts/dev-cycle.sh, test/dev-cycle.bats, skills/dev-cycle, docs/roadmap.md, decision-tree row 12, README, guides/skill-creation.md, log row 67) | **Reviewed:** 2026-09-29 | **Status: 🔴 → fixed** — one High security finding and several behavioural bugs fixed in the next commit. Final confirming passes run per unit after the size-gate split (see below).

Pipeline: Stage 1 k=3 fact-check (opus) → security, performance, api-consistency, architecture-review (opus) in parallel → synthesis. Delivery mode: self-read. Considered overrides: no prior overrides matched this diff.

Size gate: the fixed unit came to 531 changed code lines against main (cap 400, pr-prep 1a). It was split in /away mode without asking, and the split is recorded in the commit Notes and here. The units are `feat/dev-cycle-digest` (script and tests) and `feat/dev-cycle` stacked on it (skill and docs).

---

## 🔴 Must Fix

| # | Finding | Source | Status |
|---|---|---|---|
| R1 | A remote default branch named like an option (`--output=<path>`) reached `git log` via origin/HEAD and truncated a file, despite the "read-only" header. Probe-confirmed | security-reviewer #1 (High) | ✅ Fixed: the branch resolves to a commit hash; names starting with `-` are rejected; regression test fails on the old script |

## 🟡 Must Address

| # | Finding | Source | Status |
|---|---|---|---|
| A1 | `--since` is a bare date, so git reads it as the current time of day; merges earlier on the record day are dropped | fact-check ×3; api F3 | ✅ Fixed (midnight); test |
| A2 | Log rows print only the first "revisit" match, so row 67's trigger is missing and row 53 is cut at 400 chars | fact-check ×3; performance #3 | ✅ Fixed (capitalised "Revisit" preferred, whole cell); test |
| A3 | A `questions.sh open` failure is shown as "None open." | fact-check r3; api F1 | ✅ Fixed (failure reported); test |
| A4 | A master-only repo exits 128; a relative invocation from a subdirectory fails | fact-check ×3; api F2 | ✅ Fixed (main/master/current-branch fallback; SCRIPT_DIR resolved before the cd); tests |
| A5 | The date seed does nothing: every cycle samples the same merge positions | fact-check r2 (r1, r3 test-gap notes) | ✅ Fixed (seed = sha256 of the date); test fails under the old seed |
| A6 | Revisit triggers ignore the window: 79% of the digest, ~45 verdicts per cycle | performance #1 | ✅ Fixed: after a cycle record, only changed records and new rows print in full; the rest carry forward; test |
| A7 | Nothing makes the skill wait for the background health check before step 4 | performance #2 | ✅ Fixed (wait before step 4) |
| A8 | The window start depends on step 7 and silently falls back to 14 days | architecture Coupling #1 | ✅ Fixed: the digest prints the window's source; the skill explains the fallback |
| A9 | Step 1 named `archive-working-docs.sh`, which moves tracked docs into a gitignored archive | architecture Coupling #2 | ✅ Fixed (removed; list merged-task docs instead) |
| A10 | The roadmap restates questions.md state, and ideas have a third home | architecture Coupling #3 | ✅ Fixed (Next points at Q-IDs); backlog question filed as Q-099, interim [1] |
| A11 | The skill runs `scripts/dev-cycle.sh` and bare `questions.sh` in any project (same-name shadowing) | security #2; api F4 | ✅ Fixed (installed path first, never-follow line) |
| A12 | Repo text in the digest reaches the agent as instructions | security #3 | ✅ Fixed (evidence-not-instructions rule; only existing tests run) |
| A13 | Roadmap: Q-092 does not wait on a sandbox | fact-check ×3 | ✅ Fixed |

## 🟢 Consider

| # | Finding | Status |
|---|---|---|
| C1 | No roadmap template exists | ✅ Fixed (template inline in the skill) |
| C2 | "seven steps" (actually 0–7); guide rationale not in the guide's own terms | ✅ Fixed |
| C3 | Row 67 "nothing reading them" / count wording; Q-074 condition; host-tools wording; conflict types | ✅ Fixed |
| C4 | "code-fact-check at k=1" (k belongs to code-review) | ✅ Fixed |
| C5 | Description trigger "what next" too broad; row 12 vs description | ✅ Fixed (description ≤250; triggers aligned) |
| C6 | Merge list shows 30 of N without saying so; commit count label | ✅ Fixed |
| C7 | Test lives in test/, not test/scripts/ | ✅ Fixed |
| C8 | Same-day second cycle overwrites the record | ✅ Addressed (update in place) |
| C9 | Parsing questions.sh columns; control chars; `--since V` form; per-file git log | 🟢 Won't-Fix (override log) |
| C10 | Immutable commit-message claims in 1f8ed13 ("date-seeded", "every revisit trigger", "works in any repo") | 🟢 Accepted-immutable (below) |
