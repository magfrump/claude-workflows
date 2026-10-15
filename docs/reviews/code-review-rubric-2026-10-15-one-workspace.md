Commit: a54bb3b0

# Code Review Rubric

**Scope:** `fix/cc-isolated-one-workspace`, `5e6e9266..a54bb3b0` (full branch; iteration 1, `--loop-pass`) | **Reviewed:** 2026-10-15 | **Status: 🟡 fixes pending re-review** — 0 red; 4 amber fixed in the iteration-1 fix commit, awaiting the next pass

Reports: `code-fact-check-report-2026-10-15-one-workspace.md` (k=1), `security-review-2026-10-15-one-workspace.md`, `api-consistency-review-2026-10-15-one-workspace.md`, `performance-review-2026-10-15-one-workspace.md`. Delivery mode: inline-diff-only. Plan: `docs/working/plan-2026-10-15-cc-isolated-one-workspace.md`.

---

## 🔴 Must Fix

None. (Fact-check's two Incorrects are a comment and a plan claim, 🟡 under tier policy T; api-consistency found no Breaking change.)

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | `--profile` took its next word unchecked: `--profile '#' --bless` ran a bless (exit 0), `--profile '#' B` opened B; the new comment ("a note's later words can never act as flags") and plan F5 ("covered already") claimed otherwise. Pre-existing behaviour, in scope by those claims. `devcontainer-config/cc-isolated.sh:770-782` | Security | Medium | security F1 + fact-check (Incorrect, plan F5) + api-consistency F7 | for-author | — | ✅ Fixed (iteration-1 fix commit) | A `--profile` value starting with `#` (pasted note) or `-` (a swallowed flag) is a usage error, exit 2; bats case fails on 5e6e9266; plan F5 corrected |
| A2 | install.sh comment says each note is "on the line below"; it is printed above. `devcontainer-config/install.sh:610` | Docs | Incorrect (comment) | fact-check | for-author | — | ✅ Fixed | — |
| A3 | The `--help` header and the guides' copyable blocks still end in `# note`; `cc-isolated --bless  # …` / `--list  # …` pasted into default zsh worked (the stray word was ignored) and now exit 2. `guides/cc-isolated-usage.md:20-35`, `cc-isolated.sh:6-17`, `guides/devcontainer-setup.md:47-48,79-81,114,153,174`, `guides/cc-isolated-usage.md:564,592,626` | API consistency | Inconsistent (High) | api-consistency F1 + security info 3 | for-author | #848 (this unit closes it) | ✅ Fixed for the `--help` header (descriptions on their own lines) and the guide's command reference (a table); 🟡 Acknowledged for the rest | The remaining blocks are example `--register`/launch lines; each now fails safe (exit 2 naming the value, nothing written) and the guide paragraph says to copy the command, not the note. Revisit trigger: the next edit to any of those blocks, or a user report of the exit-2 note error; logged in override-log.md |
| A4 | `init-firewall.sh:347-349` comment still says "the last positional becomes the workspace" (outside the diff) | Docs | Stale | fact-check | for-author | — | ✅ Fixed | Comment-only |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | `--help` header omitted "before `--`" and the `-- '#x'` escape | fact-check (Mostly accurate) + api-consistency F2 | Minor | for-author | — | Fixed |
| C2 | "before any check or action runs": the host-tool hash check runs at load, before main; the parse error still precedes its refusal | fact-check | Mostly accurate | for-author | — | Fixed (comment now says "before main's first refusal (the host-tool check) or any action") |
| C3 | "used to drop everything after `--`, opening $PWD": only when no workspace came before `--` | fact-check | Mostly accurate | for-author | — | Fixed |
| C4 | Guide "names the values": a pasted note's error names only the `#` word | fact-check | Mostly accurate | for-author | — | Fixed ("names the offending value") |
| C5 | Commit a54bb3b0 says "Four reds"; the locale reds are six across three suites, all pre-existing (pass under LC_ALL=C.UTF-8) | fact-check | Mostly accurate | for-author | — | Won't-Fix in history (not amended); corrected in the fix commit's Notes |
| C6 | The pasted-note hint printed on every two-workspace error, where a real zsh note is always caught first by the `#` check | api-consistency F5 | Minor | for-author | — | Fixed: the `#` refusals carry the zsh hint; two workspaces name "a pasted line with a trailing note, or a path with an unquoted space" (the brief asks the message to suggest a stray comment) |
| C7 | Message wording differs from cc-push's "one checkout at a time"; cc-isolated refuses `'' -- B`, cc-push accepts it | api-consistency F3 + fact-check | Minor | for-orchestrator-synthesis | — | Won't-Fix (cc-isolated's message names both values, as the brief asks; an empty first workspace is not a real form) |
| C8 | cc-push does not refuse a `#` word: `cc-push # --yes` reads the note's later words as flags, then fails at `find_checkout` (nothing pushed) | api-consistency F4 + security | Informational | for-author | — | Defer: outside this unit (host tool, its own trailer); asked in the report |
| C9 | Three usage-error shapes in cc-isolated; the new helper duplicates cc-push's `usage_die` | api-consistency F6 | Informational | for-author | — | Won't-Fix (cc-push's copy is a separate host tool; sharing code across them is a trust-manifest change) |
| C10 | Older messages print values raw (`unknown flag: $1`, `resolve_workspace`): ESC bytes reach the terminal if the user types `$'…'` | security info 2 + api-consistency F6 | Informational | for-author | — | Defer, pre-existing; revisit trigger: the next change to those messages |
| C11 | New tests cost 1.4 s of a 57 s file, each under 1 s | performance | Informational | for-orchestrator-synthesis | — | No action |

## ⏭️ Skipped Core Critics

None. Contextual: none triggered (tests changed with source; 6 files, under 500 lines; no manifests or UI; no module-structure change).

## 🧩 Composition check

- `cc-isolated.sh:770-782` (security F1, fact-check plan-F5 Incorrect, api-consistency F7): distinct sources, one defect each states completely (the unchecked `--profile` value) → `distinct defects` by construction (no unstated root).
- Guides/`--help` notes (api-consistency F1, security info 3): same finding stated twice → merged into A3; no composed row.

## Considered overrides

- #848 (`fix/rebuild-hint-recreate`, install.sh Next steps notes and "rebuilds"): its revisit trigger fired; closed by this unit.
- #836 (`guides/cc-isolated-usage.md:25` "REBUILD"): the line already says RECREATE; carried into the new table unchanged.
- #830, #847 (rebuild_hint wording, `--probe-only` loop on a provenance failure): not touched by this diff.
