Commit: 722c2e10

# Code Review Rubric: feat/build-loop-u4a

**Scope:** full branch, `git diff main...HEAD` (main 774a0eef; first pass of the loop). Delivery mode: self-read (shared brief and diff file on disk).
**Iteration 1** (`--loop-pass`, k=1 fact-check, full core panel + architecture). No behavioral red, so no short-circuit. Stage 2.5 skipped (loop pass): three security endorsement claims (the CAS / fast-forward move, the judged tree and parents with no hooks, HEAD's commit not the index) stay *pending execution verification* for the final pass. The session's process exited mid-Stage 2; the security, API-consistency and architecture critics were resumed from their transcripts on an unchanged branch.
**Reports:** `docs/reviews/code-fact-check-report-2026-10-13-u4a-i1.md`, `security-review-2026-10-13-u4a-i1.md`, `performance-review-2026-10-13-u4a-i1.md`, `api-consistency-review-2026-10-13-u4a-i1.md`, `architecture-review-2026-10-13-u4a-i1.md`.

## 🔴 Must Fix

None.

## 🟡 Must Address

| ID | Finding | Source | Severity | Evidence | Status |
|---|---|---|---|---|---|
| A1 | The Asked: rule checks only the IDs a brief held, not the ones added: appending another question's (answered) ID, or a first Asked: line naming one, passes, and --check-answer matches by ID alone, so that answer is applied to this brief (row 745's reuse). | security F1 (probes P1, P2) | Medium | `scripts/build-loop.sh` cycle_rules, `[[ "${an[$f]}" == "${ao[$f]}" \|\| "${an[$f]}" == "${ao[$f]}, "* ]]` | Fixed: asked_rule requires each added item to name an entry the questions files gain |
| A2 | --land-cycle lands docs/dev-cycle.md, docs/constraints.md, instruction files and dot paths unjudged; --merge refuses them under self-merge and --check-fix refuses them for in-cycle fixes. | security F2 (probe P4) | Medium | `case "$p" in ... *) continue ;;` | Fixed: truthrule's classes but `cycle` refuse in cycle_rules |
| A3 | `--expect` names main's commit under --land-cycle but the brief tip under --check/--merge; a caller passing the tip by analogy gets a misleading remedy. | api-consistency 1 | Inconsistent | `[[ "$EXPECT" == "$MAIN_SHA" ]]` | Fixed: `--main SHA` |

## 🟢 Consider

| ID | Finding | Source | Status |
|---|---|---|---|
| A4 | A brief deleted, or renamed to another file name, drops its Asked: IDs with no refusal. | security F3, fact-check claim 3 | Fixed (asked_rule) |
| A5 | Shared refusals say "index" / "stage again" under --land-cycle; the questions guard only matters for --cycle-diff. | api-consistency 2, architecture 2 and 6, security F5 | Fixed: guard moved into cycle_diff; cycle_rules takes SIDE (index / merge) |
| A6 | The header's --land-cycle refusal list omits read failures. | api-consistency 3, fact-check claim 9 | Fixed |
| A7 | `landed` line fields undocumented; comment BRANCH vs header B; reflog text. | api-consistency 4 | Fixed |
| A8 | Plan's script interface lacks --land-cycle; row 674's `entry` line is promised in the split note but not built. | api-consistency 5, architecture 7 | Fixed in the plan (as-built note: row 674 to U4b) |
| A9 | land_cycle repeats check_line's compute steps without its blob-presence check (store_check covers it, unsaid). | architecture 1 | Fixed (comment) |
| A10 | Chore merge message has no single definition beside gate_msg. | architecture 3 | Fixed: chore_msg |
| A11 | VERDICT has two producers; land_cycle set four of six keys; RAW_* reuse after cycle_rules unstated. | architecture 4 | Fixed: all keys set; comment |
| A12 | Header's Asked: wording; asked() comment vs brief_fields. | fact-check claims 3, 13 | Fixed |
| A13 | `lower` forked per path; brief reads per changed brief. | performance 1, 2 | Won't-Fix (override rows) |
| A14 | Combined usage error. | api-consistency 6 | Won't-Fix (override row) |
| A15 | New rules have no caller yet; U4b must name them. | api-consistency 7 | Defer to U4b (override row) |
| A16 | dev-cycle.sh keeps its own record glob. | architecture 5 | Defer (override row) |
| A17 | SKILL.md still lands via pr-prep. | architecture 7 | Defer to U4b (override row) |
| A18 | asked() vs brief_fields: no bypass. | security F4 | Won't-Fix (override row) |
| A19 | isrecord's "one per day" is orchestrator behaviour. | fact-check claim 19b | Defer to U4b (override row) |
| A20 | 722c2e10 cites row 749 under "no hooks run". | fact-check claim 24b | Won't-Fix (override row) |

## ⏭️ Skipped Core Critics

None.

## 🧩 Composition check

- `scripts/build-loop.sh` cycle_rules Asked: block (A1, A4, fact-check claims 3, 13; security, fact-check): distinct defects: A1 (added IDs) and A4 (dropped by deletion) are separate predicates on the same rule, each stated whole.
- `scripts/build-loop.sh` cycle_rules wording and guard (A5, A6; api, architecture, security, fact-check): distinct defects (wording vs placement), each stated whole.

## Considered overrides

- Rows 719, 722, 725, 745, 747, 749, 752, 753 (U3b2/U3c hand-offs to U4): answered by this unit; 745 more fully after A1/A4; 749's commit-side half stays U4b's (row 2026-10-13, claim 24b).

**Status:** iteration 1 found no red; 3 ambers fixed. Next: iteration 2 (`--loop-pass`, range 722c2e10..HEAD).
