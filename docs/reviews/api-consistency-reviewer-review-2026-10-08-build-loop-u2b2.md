Commit: c10b972a

# API Consistency Review — feat/build-loop-u2b2 (U2b2, the gate's checkout), iteration 1

**Scope:** `git diff main...HEAD` on `feat/build-loop-u2b2` (scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, docs/working/known-issues-dev-cycle.md, docs/working/plan-build-loop-handoff.md)
**Date:** 2026-10-08
**Based on:** docs/reviews/code-fact-check-report-build-loop-u2b2.md (Stage 1, k=1: 20 claims, 12 Verified, 8 Mostly accurate, 0 Incorrect)

## Baseline Conventions

The consumer-facing surface is `--check`'s output grammar (header of `scripts/build-loop.sh`, lines ~78-148), which the orchestrator (U3/U4) and build loops will parse:

- **Run-wide refusals** print `refuse state WHAT: WHY` and exit 2 before any brief is read (`state_gate`, `default_gate`, and `refuse state gate: WHY` for `gate_repo`). A config value that cannot be read gets its own WHY (`refuse state $f: it could not be read (git config exit $rc)`, build-loop.sh:236), separate from a key that is set (build-loop.sh:238).
- **Per-brief verdicts** are exactly one of `ok BRIEF TIP TREE`, `refuse BRIEF: WHY`, `skip BRIEF: WHY`, with path/deny lines only after `ok` or the K-of-N refusal. Exit 2 when any verdict is not ok.
- **WHY wording:** lower-case clause, "the default branch" (never "main") in output, `its` always refers to the brief (`its branch $br does not exist`, `its branch $br moved or could not be read again`, `its branch $br has no commit the default branch lacks`, build-loop.sh:662-666). A `; ` inside WHY already occurs (`the brief is $st on the default branch; only an open brief merges`, :661). Where a value mismatches, both sides are printed (`the tip of $br is $sha, not the expected $EXPECT`, :667).
- **Helper return convention:** a `*_gate` function returns 1 on failure; a reason travels in a `*_WHY` global when the caller formats the line (`main_file` sets `FILE_WHY`, :280-296; `nrules` sets `DENY`, :569).
- **The plan's consumer contract:** a loop runs `--check` "as an advisory dry run" (plan :28, :83; T19 prompt line "`--check` is advisory; the orchestrator's run decides", :234, :340).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `checkout_gate` | function | `state_gate`, `default_gate`, `gate_repo` | `scripts/build-loop.sh:230,258,514` | Consistent — `<thing>_gate`, returns 1 on failure |
| `CHECKOUT_WHY` | global | `FILE_WHY`, `TRUTH_WHY`, `DENY` | `scripts/build-loop.sh:282,569,584` | Consistent — `<THING>_WHY` reason global, emptied on success |
| `refuse BRIEF: a self-merge brief needs --check run from a clean checkout of the default branch's commit; WHY` | output line | `refuse BRIEF: the brief is STATE on the default branch; only an open brief merges`, `refuse BRIEF: K of N changed paths refused ...`, `refuse state WHAT: WHY` | `scripts/build-loop.sh:661-707`, header :94-126 | Consistent in prefix and `; ` use; sub-WHY pronouns diverge (F3) |
| CHECKOUT_WHY sub-reasons (`its HEAD is not ...`, `its index marks ...`, `core.X is V or unreadable (...)`, `$v is set, ...`, `it holds an untracked nested repository ...`, `a gitlink is checked out with files ...`, `a file's checked-out bytes are not ...`, listing failures) | WHY strings | state_gate WHYs, check_line WHYs | `scripts/build-loop.sh:233-265,661-707` | Mostly consistent; "or unreadable" merges two conditions (F4); `its` referent shifts (F3) |
| `pol` (local, 4th `status_line` field) | local | `st`, `br`, `loop`, `sha` | `scripts/build-loop.sh:657-659` | Consistent — reads the documented POLICY field of `--status` |
| test helpers `sm`, `coref`, `cook`, `CO`, `IDX`, `STAT` | test-local | `chk`, `gated`, `nref`, `NOWN`, `NFORM` | `test/scripts/build-loop-check.bats:1251-1451` | Consistent — short helpers plus upper-case expected-WHY constants |

No new CLI flag, exit code or line shape is added.

## Findings

#### F1. A loop's advisory `--check` on a self-merge brief can no longer dry-run anything: it always stops at the checkout refusal

**Severity:** Inconsistent
**Location:** `scripts/build-loop.sh:668-670` (check_line), `:725-726` (check mode); `docs/working/plan-build-loop-handoff.md:28, :83, :284`
**Move:** 3 (trace the consumer contract)
**Confidence:** High
**Legibility-target:** for-author

Evidence (code): `if [[ "$pol" == self-merge && -n "$CHECKOUT_WHY" ]]; then echo "refuse $a: a self-merge brief needs --check run from a clean checkout of the default branch's commit; $CHECKOUT_WHY"; return` — placed before `merge_result`, the diff-tree and the N rules. Evidence (plan): "The loop still runs `--check` itself as an advisory dry run" (:28); "A review brief does not read the checkout, so a loop's advisory run from its branch still works" (:284).

A build loop runs from its own worktree with HEAD at its branch tip, never MAIN_SHA, so under self-merge policy every advisory run on its own (self-merge) brief now gets `its HEAD is not the default branch's commit ...` and never learns whether its branch conflicts or which paths the N rules deny — the information the dry run exists to give, and the policy (hands-off self-merge) where the loop most needs it before reporting `ready`. The new test confirms the shape (`git checkout -q --detach HEAD~1; coref "its HEAD is not ..."`). The plan's U2b2 note records the review-brief case only; plan :28/:83 and the T19 prompt line still promise an advisory dry run without the self-merge caveat. Not Breaking: no built consumer parses this yet (U3/U4 are unbuilt).

**Recommendation:** Choose and document one: (a) run the checkout check after the merge and N rules, turning a would-be `ok` (or adding to a K-of-N refusal) into the checkout refusal, so a loop still sees conflicts and denies; or (b) keep the order and say in the help text, plan :28/:83 and the T19 prompt line that a loop's advisory run on a self-merge brief reports only the checkout refusal (and how a loop should dry-run instead, e.g. from a clean main worktree).

#### F2. The help text's and lib contract's account of the new refusal is incomplete or overbroad

**Severity:** Minor
**Location:** `scripts/build-loop.sh:112-126` (help), `scripts/lib/dev-cycle-read.sh:55-57` (caller contract, under item 3)
**Move:** 3 (documentation drift)
**Confidence:** High (fact-check Claims 3a, 10)
**Legibility-target:** for-author

Evidence (help): "a repo-local GIT_* variable set (GIT_INDEX_FILE, GIT_WORK_TREE...), core.symlinks false, core.ignoreCase or core.sparseCheckout true, an index entry marked skip-worktree, assume-unchanged or unmerged, ..." Evidence (code): `[[ "$v" == GIT_CONFIG* || "$v" == GIT_NO_REPLACE_OBJECTS || "$v" == GIT_PREFIX || ...` exempts three families; `CHECKOUT_WHY="${v%% *} is ${r%%:*} or unreadable ..."`; `"a file on the default branch has a newline in its name"`; `"its untracked files could not be listed"`; `"the default branch's tree could not be listed"`. Evidence (lib): "The walk does not check items 2 and 3; build-loop.sh's checkout_gate does for --check (U2b2)".

The header is the one place consumers learn which WHYs exist, and the existing `refuse BRIEF` paragraph does list its could-not-be-computed cases; the new paragraph omits the exemptions, the unreadable-config and listing-failure refusals and the newline-name refusal. In the lib, the sentence sits under item 3 but claims item 2 too, while item 2's fsmonitor and replace refs are enforced by `harden`/`state_gate`, not `checkout_gate`, and the check runs once per run and only when policy is self-merge (Claim 10). Item 4, which `check_line` now satisfies, is not annotated.

**Recommendation:** Add the exemptions and the could-not-be-read/listed and newline cases to the help paragraph; in the lib, move the note to follow items 2-4 and say which parts `harden`/the state gate cover and that `checkout_gate` runs only for self-merge, once per `--check`.

#### F3. `its` in the new sub-reasons refers to the checkout, where every other `refuse BRIEF` WHY uses `its` for the brief

**Severity:** Minor
**Location:** `scripts/build-loop.sh:612, 622, 624, 629` (CHECKOUT_WHY strings) as composed at :669
**Move:** 2 (naming against the grain)
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: `its` = the brief in `refuse $a: its branch $br ...` used in `scripts/build-loop.sh:662,665,666`

Evidence: composed line `refuse BRIEF: a self-merge brief needs --check run from a clean checkout of the default branch's commit; its HEAD is not the default branch's commit SHA`. Read in that line, the nearest antecedent of `its` is "the default branch's commit", and by the existing convention it is the brief; neither is meant. `its index marks entries ...`, `its index or tracked files differ ...` and `its untracked files could not be listed` read the same way.

**Recommendation:** Name the subject: "the checkout's HEAD is ...", "the checkout's index ...", "the checkout holds an untracked nested repository" (and update the bats constants `IDX`, `STAT`).

#### F4. "is V or unreadable" and "... or could not be listed" merge a refusal with a read failure, unlike the state gate

**Severity:** Minor
**Location:** `scripts/build-loop.sh:614-618, 620-622`
**Move:** 4 (error consistency)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence: `CHECKOUT_WHY="${v%% *} is ${r%%:*} or unreadable (${r#*: })"` and `"its index marks entries skip-worktree, assume-unchanged or unmerged, or could not be listed"`. The state gate's precedent splits them: `refuse state $f: it could not be read (git config exit $rc)` (:236) vs `refuse state $line: set in $f, ...` (:238). A reader (human or orchestrator) told `core.symlinks is false or unreadable` cannot tell whether to flip a setting or repair a config file; `rc` is known at that point.

**Recommendation:** Emit `core.X could not be read (git config exit N)` when `rc > 1` and `core.X is V (...)` otherwise; likewise split the ls-files failure from the flagged-entries case.

#### F5. Known issue A5 still lists nested repositories and case-insensitive checkouts as "Not covered"

**Severity:** Informational
**Location:** `docs/working/known-issues-dev-cycle.md:18` (row A5)
**Move:** 3 (documentation drift)
**Confidence:** High (fact-check Claim 1)
**Legibility-target:** for-author

Evidence: "Not covered: start files under a symlinked directory or in a submodule or untracked nested repo ..., other names one file has on a case-insensitive checkout, and checkout conversions ..." followed by the new sentence "U2b2: `build-loop.sh --check` refuses a self-merge brief unless its checkout is clean at main with `core.symlinks` true and every regular file main stores hashes, unfiltered, to main's blob". The U2b2 sentence does not mention that `checkout_gate` also refuses an untracked nested repo, a populated gitlink and `core.ignoreCase` true.

**Recommendation:** Extend the U2b2 sentence to name those three, scoped "for a self-merge brief under `--check`" (the walk alone still does not cover them).

#### F6. A run-wide condition reported per brief; the parse token and the HEAD value

**Severity:** Informational
**Location:** `scripts/build-loop.sh:725-726, 669, 612`
**Move:** 1/4 (baseline, error consistency)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Evidence: `if [[ "$POLICY" == self-merge ]]; then checkout_gate || true; fi` (once per run) vs the per-brief `refuse $a: a self-merge brief needs --check run from a clean checkout ...`; and `"its HEAD is not the default branch's commit $MAIN_SHA"`. The condition is environmental like `refuse state ...`, but printing it per brief is justified because review briefs in the same run pass, and it keeps the one-verdict-per-brief contract. The orchestrator will need to tell "rerun from a clean main checkout" apart from brief-specific refusals; today it can only do that by matching the fixed prefix text, which the header quotes but does not call stable. Unlike the `--expect` line (:667), the HEAD WHY prints the expected commit but not the actual HEAD.

**Recommendation:** State in the header that the prefix up to `; ` is fixed for parsers; optionally print the actual HEAD (`its HEAD is X, not the default branch's commit Y`).

## What Looks Good

- `checkout_gate`/`CHECKOUT_WHY` follow the existing `_gate` and `_WHY` naming and return conventions exactly.
- The refusal keeps the one-verdict-line-per-brief shape, the `refuse BRIEF: WHY` prefix and exit 2; no new flag, line type or exit code, so a parser written to the U2b1b grammar still classifies every line.
- Policy gating is symmetric: `checkout_gate` runs only when `--settings` policy is self-merge, and the refusal fires only when `--status`'s POLICY field (which already requires that) is self-merge, so `--status` output predicts which briefs are exposed.
- Output says "the default branch", matching every other `--check` line; the lib contract item 4 is now honoured by `import_reset` at the top of `check_line`.
- Tests pin each WHY string verbatim through constants, so wording changes surface as test diffs.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| F1 | Loop's advisory `--check` on a self-merge brief always stops at the checkout refusal; plan still promises a dry run | Inconsistent | `scripts/build-loop.sh:668-670`; plan :28, :83, :284 | High |
| F2 | Help text omits exemptions/read-failure/newline WHYs; lib note under item 3 overclaims item 2 | Minor | `scripts/build-loop.sh:112-126`; `scripts/lib/dev-cycle-read.sh:55-57` | High |
| F3 | `its` refers to the checkout, against the `its` = brief convention | Minor | `scripts/build-loop.sh:612,622,624,629` | Medium |
| F4 | "or unreadable"/"or could not be listed" merge refusal and read failure, unlike state_gate | Minor | `scripts/build-loop.sh:614-622` | Medium |
| F5 | A5 "Not covered" list not updated for nested repos, gitlinks, ignoreCase | Informational | `docs/working/known-issues-dev-cycle.md:18` | High |
| F6 | Run-wide condition per brief: state the prefix as a parse token; print actual HEAD | Informational | `scripts/build-loop.sh:612,669,725` | Medium |

## Overall Assessment

The new refusal fits the existing `--check` grammar well: same prefix, same exit code, same naming conventions, and policy gating consistent with `--status`. The one consumer-contract issue is F1: placing the checkout check before the merge means the plan's advisory dry run from a loop's branch yields nothing useful for self-merge briefs, which the plan text still promises; it needs either a reorder or an explicit, documented change to the loop's contract before U3/U4 build on it. F2-F5 are wording and documentation fixes in place; no finding suggests the author skipped the existing conventions.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u2b2/docs/reviews/api-consistency-reviewer-review-2026-10-08-build-loop-u2b2.md (first line `Commit: c10b972a`), structured per the critic skill.
- Answered: yes — the new refusal line and WHY strings compared with the --check grammar and the lib contract; the planned consumers (orchestrator, loop advisory runs) traced in the plan.
- Out of scope: whether the checkout checks are sufficient or bypassable (security), the hash-object cost on large trees (performance).
- Escalate: F1 is a contract decision (reorder vs document) that touches the plan's design point 1 and T19; worth routing to the author before U3.
- Decisions I made: rated F1 Inconsistent rather than Breaking because no built consumer parses --check yet; no probe run, since the behaviour follows directly from check_line's order and the branch's own test (detached HEAD~1 refuses).
