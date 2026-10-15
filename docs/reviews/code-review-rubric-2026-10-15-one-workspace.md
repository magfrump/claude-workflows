Commit: 85973b7a
Loop closed at 85973b7a

# Code Review Rubric

**Scope:** `fix/cc-isolated-one-workspace`, `5e6e9266..HEAD` (iteration 1: independent critics on a54bb3b0; iteration 2 and final: INLINE SELF-REVIEW by the builder, see below) | **Reviewed:** 2026-10-15 | **Status: 🟢 PASSES (self-review caveat)** — 0 red, 0 open amber (A3 acknowledged with a revisit trigger); single-sample review; absence of findings is not an attestation, and the last two passes are the builder's own

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

## Iterations 2 and final: inline self-review (critics stalled)

The iteration-2 fact-check agent stalled (no output after ~06:03, stopped), its one re-dispatch (tighter brief, probes capped at 300 s) produced no report in 30 minutes and was stopped by the coordinator, who reported that nested critic agents hang in this session and told the builder not to spawn more. **The iteration-2 pass and the final confirming pass therefore ran inline, by the builder, on 5a821383 and its follow-up.** This is self-review: the same model that wrote the change checked it, so it is weaker than independent critics and k=3 replication did not happen. The iteration-2 security, api-consistency and performance critics were never dispatched (they wait on Stage 1). Evidence used: the stopped re-run's probe logs (`/home/node/.claude/jobs/00bcf178/tmp/one-ws/cfc-i2b/exitcodes.log`, `probes.log`, `bats.log`: every refused form exits 2 with the expected message; the targeted bats tests pass), plus the builder's own reads and runs.

| Pass | Checked | Result |
|---|---|---|
| Fact-check (inline) | --help header vs parser; comments on `arg_usage_error`, `pasted_note_error`, `two_workspaces`, the `--profile` and `\#*)` cases, the `--` block; guide table vs the old block (14 command rows before, 14 after); guide paragraph; install.sh/init-firewall.sh comments; commit 5a821383 and this rubric's Fixed statuses; plan F5; override-log row | One imprecision: the header's "Before `--`, a second workspace, or a word starting with '#'…" read as if a second workspace after `--` were allowed → **S1, Fixed** in the iteration-2 commit. Everything else matched the code |
| Security (inline) | Every mode's grammar (launch, `--probe-only`, `--register`/`--profile`, `--bless`, `--list`, `--help`, `--`); a note's words reaching flags via `--profile` (now refused) or after `--` (two_workspaces, exit 2); `-- '#'` (exit 1 from resolve_workspace, no action); usage errors before the host-tool refusal; %q on new values; no egress profile name starts with `-` or `#` (egress/*.txt), so the `--profile` refusal blocks no real profile; install.sh lines | No new finding. **S2 (Consider, Won't-Fix):** if the whole install.sh block is pasted, its prose lines with an apostrophe ("a project's", "a session's") open a quote and the result is a "command not found", never a cc-isolated run; the block's heading says to copy the command lines only |
| API consistency (inline) | New errors use `ERROR:` + hints + usage on stderr + exit 2 (decision log #58), raised before any refusal (row 71); `--profile` messages match the existing "--profile needs a value" wording; the header's new layout is not parsed by any test or script (`rg` for its old lines) | No new finding |
| Performance | Not re-run; iteration 1 found nothing and the fix adds one `case` per `--profile` | — |

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| S1 | --help header sentence scoped "a second workspace" to before `--` | inline fact-check (self-review) | Minor | for-author | — | Fixed |
| S2 | Pasting install.sh's whole Next-steps block: prose lines with apostrophes open a quote (harmless "command not found") | inline security (self-review) | Informational | for-author | — | Won't-Fix |

## ⏭️ Skipped Core Critics

Iteration 1: none. Iterations 2 and final: security, api-consistency and performance were not run as independent critics (critic agents stalled; replaced by the inline self-review above). Contextual: none triggered (tests changed with source; 6 files, under 500 lines; no manifests or UI; no module-structure change).

## 🧩 Composition check

- `cc-isolated.sh:770-782` (security F1, fact-check plan-F5 Incorrect, api-consistency F7): distinct sources, one defect each states completely (the unchecked `--profile` value) → `distinct defects` by construction (no unstated root).
- Guides/`--help` notes (api-consistency F1, security info 3): same finding stated twice → merged into A3; no composed row.

## Considered overrides

- #848 (`fix/rebuild-hint-recreate`, install.sh Next steps notes and "rebuilds"): its revisit trigger fired; closed by this unit.
- #836 (`guides/cc-isolated-usage.md:25` "REBUILD"): the line already says RECREATE; carried into the new table unchanged.
- #830, #847 (rebuild_hint wording, `--probe-only` loop on a provenance failure): not touched by this diff.
