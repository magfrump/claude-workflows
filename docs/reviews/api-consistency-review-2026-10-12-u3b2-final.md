Commit: 4afdd68b

# API Consistency Review: `feat/build-loop-u3b2` (`--main-log SINCE`), final confirming pass

**Scope:** full branch `main...4afdd68b` (`b5f21758..4afdd68b`). Covers `scripts/build-loop.sh` (header, usage, Exit, gate_msg, ANSWERS_AWK, clean_merge, log_class, main_log, the `main-log` case), the `scripts/lib/dev-cycle-read.sh` back-pointer, tests 9-10 in `test/scripts/build-loop-orchestrator.bats`, the plan's U3b2 "As built" note, and the override rows dated 2026-10-12 for `feat/build-loop-u3b2`. Review reports under `docs/reviews/` are history, not under review.
**Date:** 2026-10-12
**Based on:** the stage-1 merged summary of `docs/reviews/code-fact-check-report-2026-10-12-u3b2-final-r{1,2,3}.md` (k=3; no behavioural Incorrect). Prior: `api-consistency-review-2026-10-12-u3b2-i{1,2}.md`; rubric `code-review-rubric-2026-10-12-feat-build-loop-u3b2.md` (D1-D13, E1-E8).

## Baseline Conventions

The baseline is unchanged from iterations 1 and 2 (`api-consistency-review-2026-10-12-u3b2-i1.md`, "Baseline Conventions"):

- **Modes** are `--word` flags in one `case`. A malformed argument is a usage error: exit 1, stderr only, with a message of the form `--MODE takes ...`. A full commit id is checked by the same regex everywhere. For example, `--expect` says "--expect takes a full 40- or 64-hex commit id" (`scripts/build-loop.sh:460`).
- **Output lines** start with a keyword, space-separated, and free text comes last. `-` marks an absent value. A refusal starts `refuse <fixed token or BRIEF>: WHY`. Exit 2 means a refusal or a non-ok verdict; any exit other than 0 or 2 means nothing was decided.
- **Gated modes** call `state_start` (or `gate_start`). Read modes do not.
- **Message writers and readers** are defined once (row 662's pattern). Today that is `gate_msg`, which both land and log_class call (`:1374`, `:1461`, `:1664`).
- **Landing commits on main** follow pr-prep's local merge, `git merge --no-ff <branch> -F <message-file>` (`workflows/pr-prep.md:26`). Every first-parent merge on main uses the subject shape `Merge branch 'B': summary` (`git log main --first-parent --merges`).

## Name-Pattern Audit

No name changed after iteration 2. This table re-confirms the whole surface at HEAD.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--main-log SINCE` | CLI mode | `--state`, `--marker BRIEF`, `--check BRIEF...`; hyphenated: dev-cycle.sh `--check-answer`, `--check-branch` | `scripts/build-loop.sh:446-453`, `scripts/dev-cycle.sh:112` | Consistent. It is a hyphenated `--noun-noun` mode with one positional argument, and the usage text matches `--expect`'s wording. |
| `gate_msg` | function | `status_line`, `check_line`, `marker_kind` | `scripts/build-loop.sh:769`, `:851`, `:1254` | Consistent. It is a snake_case noun_noun name for a helper that produces text. |
| `log_class`, `main_log`, `clean_merge` | functions | `status_fields`/`status_line`, `state_start`/`gate_start` | `scripts/build-loop.sh:851`, `:1220-1227` | Consistent. `main_log` mirrors the mode name, as `status_line` does `--status`. |
| `ANSWERS_AWK` | awk constant | `ANSWER_AWK`, `FENCE_AWK`, `CONSTRAINTS_AWK` | `scripts/lib/dev-cycle-read.sh:2022`, `:270`; `scripts/build-loop.sh:644` | Consistent in shape. It sits one letter away from the lib's `ANSWER_AWK`. The back-pointer comments in both files (D6) keep the two linked. |
| `gate`, `chore`, `answers`, `other` | output class words | `ok`, `skip`, `refuse`, `merged` (verdict words) | `scripts/build-loop.sh` header `:60-200` | New category. They are lower-case single words like the verdicts, and D13 names them. |
| `main MAIN N` / `main MAIN -` | output line | `dispatched N`; `-` for absent BRANCH/SHA/DATE | `scripts/build-loop.sh:76`, `:811` | Consistent (i2 audit). |
| `refuse main-log: WHY` | refusal line | `refuse state WHAT: WHY`, `refuse BRIEF: WHY` | `scripts/build-loop.sh:1223-1225` | Consistent. A fixed token sets it apart from `refuse state` (i1 audit). |

## Findings

#### 1. Which `Main at:` line is SINCE when a record is updated in place is unstated; the wrong pick re-reads an already-judged `other` and stops dispatch again

**Severity:** Minor
**Location:** `scripts/build-loop.sh:138-141` (header); `docs/reviews/override-log.md:719` (hand-off row); `docs/working/plan-build-loop-handoff.md:259` (step 9 writes `Main at:`)
**Move:** 3 (consumer contract), 8 (cardinality of a field the consumer reads)
**Confidence:** Medium
**Legibility-target:** U4 implementer (step 1's SINCE read and step 9's record write)

The header names SINCE as one value:

> `#             orchestrator runs it at the start of each iteration with the last` (`scripts/build-loop.sh:139`)
> `#             record's "Main at:" commit), after --state's gate but its caller` (`:140`)

The hand-off row spells out how many `Branch:` lines a record can hold, but says nothing on `Main at:`:

> `a record updated in place over several iterations of a day gathers one Branch: line per iteration, any of which counts` (`docs/reviews/override-log.md:719`)

Step 9 writes a `Main at:` line each iteration:

> `- **Step 9, close**: today's step 7, plus `Main at:` and the SHAs of the merges this iteration made, ...` (`docs/working/plan-build-loop-handoff.md:259`)

If a record is updated in place, it gathers one `Main at:` line per iteration, just as it gathers `Branch:` lines. For `Branch:`, any line counts. For `Main at:`, only the newest is right. If U4 takes the first line (a natural `grep -m1` or awk `exit`), SINCE sits before an `other` that an earlier iteration already filed as a judgment entry. `main_log` lists every first-parent commit after SINCE, so that `other` is printed again and dispatch stops again (exit 2). Test 9 shows that an older SINCE re-lists everything after it (`ml "$A" 2 "main $T 2 ... other $O docs: x ... other $T answer"`). The result fails closed, but it is a false stop that repeats every iteration until the record changes, which costs the attention budget. Row 719 defers the record format to U4, so this is a gap in the hand-off text, not in the code.

**Recommendation:** Add one clause to row 719 or to the plan's U3b2 note: "SINCE is the newest `Main at:` line of the newest record on main (one per iteration when a record is updated in place)". Alternatively, have U4 rewrite the line in place. Either way, U4's T-case should include a record that holds two `Main at:` lines.

#### 2. `Main at:` reuses a record field that decision-log row 68 cut, with no row recording its return for build-loop records

**Severity:** Informational
**Location:** `scripts/build-loop.sh:139-140`; `docs/decisions/log.md:91` (row 68); `test/scripts/dev-cycle.bats:127`; `docs/working/plan-build-loop-handoff.md:325`
**Move:** 3 (documentation drift), 7 (one name, two meanings over time)
**Confidence:** High
**Legibility-target:** future reader of the decision log, and the U4 implementer who writes the record template

Precedent: `Main at:` was the dev cycle's carry-forward handshake field, used in `docs/decisions/log.md:91` and `docs/working/questions-archive.md:1856-1860`.

> `Carry-forward and the `Main at:` handshake are cut, so every trigger is judged every cycle (Q-101 [1])` (`docs/decisions/log.md:91`)
> `    [[ "$output" != *"Carried forward"* && "$output" != *"Main at:"* ]]` (`test/scripts/dev-cycle.bats:127`)

D13 and the `--main-log` header bring the field name back for a new reader: the orchestrator's SINCE, not dev-cycle.sh's digest. The two uses do not clash in code. dev-cycle.sh ignores the line, and its test pins that. But a reader who checks the decision log finds the field marked as cut, and no row says that build-loop records bring it back with another meaning. The plan's note also carries a doubled colon:

> `The first iteration has no record with Main at:: it bootstraps by running --main-log with a full id off main's history` (`docs/working/plan-build-loop-handoff.md:325`)

**Recommendation:** When U4 writes the record template, add a decision-log row or a plan clause: "`Main at:` returns as the orchestrator's SINCE (D13). dev-cycle.sh still ignores it (row 68)." Change `Main at::` to `` `Main at:`: `` in the plan note.

### Re-checked and not re-filed

- **Row 719's chore landing rule matches the existing landing path.** I ran a probe (`/tmp/u3b2rv-apif-XXXX`, removed) in which a `git merge --no-ff --no-edit` of `chore/dev-cycle-2026-10-12` gave the subject `Merge branch 'chore/dev-cycle-2026-10-12'`. Its record was CRLF-terminated (`Branch: chore/dev-cycle-2026-10-12\r`) and read as `chore`. Exit 2 came from the other-side commit: `other ... other-side`, `chore ... Merge branch 'chore/dev-cycle-2026-10-12'`, `exit=2`. pr-prep's `-F <message-file>` form with `Merge branch 'B': summary` matches the `:` tail.
- **Bootstrap (E7).** An all-zero SINCE printed `main <MAIN> -`, then `refuse main-log: 0000000000000000000000000000000000000000 is not on the default branch's first-parent history at <MAIN>`, then `exit=2`, as the plan note and row 726 say. A 64-hex SINCE in a SHA-1 repository reads the same way (refuse, exit 2) rather than as a usage error. This is consistent with the "not on that history" wording, and U4 only passes ids that git printed.
- **gate_msg's writer/reader symmetry.** land passes `"${2-}"`, which is empty for self-merge (`:1746` calls `land "$AUTH" "$APPROVED"`, and APPROVED is set only with `--approved`, `:464`). The reader's `Build-loop-approved: (Q-[0123456789]+)` matches the writer's `--approved` regex `^Q-[0123456789]+$`.
- The rows already ruled were not re-filed: D8 (three raw readers), D10 (record name), D11 (chore's other paths), D12 (caller pairs), D13 and row 726 (other on this repo; cost; the order of `--state` and `--main-log`), E2/row 727 (answers trusts content), and row 728 (store writes). The stale numbers in rows 726 and 728 are fact-check findings in the stage-1 summary. They are text, not contract, so they are not repeated here.

## What Looks Good

- **One message definition (row 662).** `gate_msg` is the only producer, and log_class compares bytes with it (`cmp -s "$GATE_TMP/want" "$GATE_TMP/m"`). The comment on `gate_msg` warns that the reader parses the same shape.
- **Usage parity.** The SINCE check reuses `--expect`'s full-id regex. Its message, "--main-log takes one full 40- or 64-hex commit id", reads like `--expect`'s.
- **Line grammar.** `main MAIN N|-` comes first, even before a refusal. Each class line follows: `CLASS SHA SUBJECT`, with SUBJECT last, display only, and `-` when empty. A fixed-token refusal ends it. Exit codes are documented once in the Exit section (`for --main-log no other line`; `--main-log's other or refuse line`) and in the plan note. The pieces agree.
- **The hand-off text names every writer obligation:** `--no-ff`, git's default merge, no hand-resolved conflict, the subject tail, the record path and mode, the `Branch:` line, and the bootstrap. The header and the plan note agree clause for clause, and they match what the probe produced.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| 1 | Which `Main at:` line is SINCE in an in-place record is unstated. The wrong pick re-reads a judged `other` and stops dispatch again | Minor | `scripts/build-loop.sh:139-140`; `docs/reviews/override-log.md:719`; plan `:259` | Medium |
| 2 | `Main at:` reuses a field that log row 68 cut, and no row records its return; the plan note has a doubled colon | Informational | `docs/decisions/log.md:91`; plan `:325` | High |

## Overall Assessment

At 4afdd68b, the `--main-log` surface is consistent with the script's conventions. Its mode name, usage message, line grammar, refusal token, exit codes and single-definition message all follow the existing patterns. The header, the plan's "As built" note and the U4 hand-off rows agree with each other and with the code, as probed. Neither finding needs a code change. Both are hand-off text about the `Main at:` field. SINCE is read from that field, but this branch does not define it: the plan defers the field to U4's step 9. Both findings fail closed, a false stop at worst, and can be fixed in place in row 719, the plan note or U4's record template. Nothing here blocks merge.

## Goal-Alignment Note

Success criterion: "An API-consistency review saved to docs/reviews/api-consistency-review-2026-10-12-u3b2-final.md in the worktree, per the api-consistency-reviewer skill." Met.

- **File.** The review is at that path, and its first line is `Commit: 4afdd68b`.
- **Sections.** It has the skill's sections: header with Based on, baseline, name-pattern audit, findings in the template, What Looks Good, summary table and overall assessment.
- **Findings format.** Every finding carries Severity, Location, Move, Confidence and a Legibility-target line. Evidence is quoted verbatim from the cited file:line or from probe output.
- **Precedent rule.** Finding 2 is name-shaped, since it is about reusing the field name, so it carries a `Precedent:` line. Finding 1 is about a field's cardinality, not its name, so the rule does not apply.
- **Recorded rows.** Ruled rows (D1-D13, E1-E8, and the override rows dated 2026-10-12) were not re-filed. Finding 1 extends row 719 with a fact that the row's text omits. It does not dispute the row's reasoning.
- **Probes.** The probe ran under `/tmp/u3b2rv-apif-` with `set -eu`, its own mktemp, a pwd check, `timeout`, and git config isolated to `/dev/null`. The first run stopped early under `set -e`, and I removed its directory (`/tmp/u3b2rv-apif-YHqq`) by name. The second run removed its own directory. Nothing is left running, and nothing matches `/tmp/u3b2rv-apif-*`.
- **Writes.** I wrote only this file.
