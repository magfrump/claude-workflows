Commit: adc8a176

# Architecture Review — feat/build-loop-u4b2, iteration 2

**Scope:** `git diff main...HEAD` at adc8a176 (9777c1ff, adc8a176): `skills/dev-cycle/SKILL.md` (steps 6-10, Flow, description), `test/scripts/build-loop-orchestrator.bats` (one test). Context read: SKILL.md in full; `scripts/build-loop.sh` header :1-520 and `loop_prompt` :1673-1695, cycle_rules :1968-1980; `scripts/dev-cycle.sh` :58-78; `scripts/lib/dev-cycle-read.sh` ANSWER_AWK :2060-2120; plan D1-D14 and the U4b2 bullet.
**Date:** 2026-10-13
**Based on:** `docs/reviews/code-fact-check-report-2026-10-13-u4b2-i1.md` (iteration 1, at 9777c1ff; its reds A1-A4 are fixed at adc8a176 per the rubric) and the shared brief `u4b2-i2/shared.md`.

Scope check: in scope. The diff changes a data model (the brief's machine lines `Asked:`, `Applied:`, `Dispatched:`, `Policy:`, `Paths:`, `Branch:`; the record's `## Iteration` block; four new questions-entry slug classes) and a cross-cutting concern (the orchestrator loop's control flow over the gate scripts). The skill text is the program the orchestrator executes, so its contracts with the scripts are module boundaries.

Trust-boundary cross-reference: active. Map read from `docs/reviews/security-review-2026-10-13-u4b1-final.md` (Commit: `ea59b0c3`) — security review predates this diff; boundary may be stale. Its B1 (loop-writable `.git/config` → `hg` + `--state` → the orchestrator's git, worktree add included) and B3 (script output and exit → the D6 Rule's stop wording → whether the iteration continues, files, dispatches) are cited where findings touch them.

## Dependency Map

The orchestrator (SKILL.md, executed by the model) sits above two gate scripts, which it reaches only through the D6 block, and git, which it reaches only through `hg`:

- SKILL.md → `build-loop.sh` (`--status`, `--marker`, `--check`, `--merge`, `--cycle-diff`, `--land-cycle`, `--start`, `--prompt`, `--settings`) → lib `dev-cycle-read.sh` (GATE_CODE, ANSWER_AWK, floor, FENCE_AWK).
- SKILL.md → `dev-cycle.sh` (`--check-answer`, `--check-brief`, `--check-path`, `--check-write`, `--check-fix`) → the same lib.
- `build-loop.sh --start/--prompt` → `loop_prompt` → the build loop subagent, which writes only its branch and markers; the orchestrator reads them back through `--status`/`--marker`.

Dependency direction is correct: the skill depends on the scripts' documented headers; the scripts know nothing of the skill except prose cross-references in comments (one now stale, finding 8). The new state the loop carries is spread over six stores, which is the frame for most findings below:

| Fact | Where it lives | Who judges it |
|---|---|---|
| Brief status, branch, policy, paths | brief on main (`Status:`, `Branch:`, `Policy:`, `Paths:`) | `--status`, `--check`, `--check-brief` |
| Asked-at-TIP for blocked/stopped/capped | brief `Asked:` + questions entry | `--cycle-diff` (form and binding) |
| Asked-at-TIP for merge entries | questions-entry heading only (`merge-STEM-SHA12`) | nobody; found by heading search |
| Answer acted on | brief `Applied:` | nobody (unjudged) |
| Dispatch count (the cap) | brief `Dispatched:`, written by the orchestrator in a second land, bridged by session memory | `--status`/`--start` read it; `--cycle-diff` does not judge it |
| Which loops are live and mine; landed-a-`Main at:` flag; `--answered` IDs | session memory only | nobody |
| Stall timer | record `7.` prose lines, one file per local day | nobody |
| Loop liveness | worktree lock reason (dispatch time), branch tip and date | `--prompt`/`--steal` |

## Findings

#### 1. Blocked-entry answers go through a three-option reader built for another question class

**Severity:** Coupling
**Location:** `skills/dev-cycle/SKILL.md:503-510`; `scripts/lib/dev-cycle-read.sh:2070-2081`; `scripts/build-loop.sh:1685-1689` (loop_prompt)
**Move:** 5 (interface segregation), 7 (coupling surface)
**Confidence:** High (reader behaviour, read in full); Medium (that the skill routes `unrecognized` on a blocked entry to "record and final message", not re-dispatch)
**Legibility-target:** orchestrator

Evidence: the skill reads every answer through one call, "`[1]`, `[2]` and `[3]` read as `keep`, `drop` and `done`", then "`open`: wait; ... A `skip` or `unrecognized`: the record and the final message. - A blocked entry, answered: step 10 re-dispatches the brief, naming the ID." The reader: `if (substr(s, 1, 3) == "[3]") return "done"` / `if (!match(s, /^(1|2|3|keep|drop|done)/)) return "unrecognized"`. The loop prompt asks for open-ended option spaces: "No clear winner, no option surviving the hard constraints, or a fact only the user has: end with a blocked marker" and "the question ... as plain prose and an options table" (no cap at three options).

`--check-answer` is the keep-or-drop reader whose question class this diff removed from step 6 (the header still says "for a keep-or-drop-or-done question", `scripts/dev-cycle.sh:61`). It now serves five entry classes whose option meanings differ (merge: [1] merge, [3] changes needed; stopped: [1] re-dispatch; capped: [1] keep open; blocked: the loop's own). A blocked question with a fourth option, a lettered table, or a fact answer ("use port 8080") reads `unrecognized`, so D2's async Path B never resumes: the brief sits blocked and the user is asked again each iteration. The mapping of option numbers to actions lives only in skill prose, keyed on slug prefix.

**Recommendation:** For blocked entries, route on Status alone (any non-`open`, non-`skip` result, `unrecognized` included, means answered, and the loop reads the answer text itself via the "Answered for you" line). Longer term, give `--check-answer` a mode that reports "answered" without classifying the option, and rename the keep/drop/done reader's doc to the entry classes it now serves.

#### 2. The dispatch cap's counter is persisted after the dispatch, through a second land, from session memory

**Severity:** Coupling
**Location:** `skills/dev-cycle/SKILL.md:642-646`, `:655-659`; `scripts/build-loop.sh:467-468`; plan D1 (`docs/working/plan-build-loop-handoff.md:39-42`)
**Move:** 2 (responsibility), 7 (coupling)
**Confidence:** High
**Legibility-target:** orchestrator

Evidence: the script prints "N: the brief's Dispatched: count plus one, for the caller to write on the brief"; the skill: "Write `Dispatched: N` on the brief (the old line replaced; none yet: a new line at its end)" and "Then land again as step 9 does (1 to 5): the briefs' `Dispatched:` lines and the record's `10.` line. A stop here leaves those lines unlanded: the session keeps each brief's N and the next iteration writes them with its own; a session that ends first loses them, and the brief's count on main then reads one low per lost line (a Q-103 residual)." Plan D1: `--start` "increments the brief's `Dispatched:` count" and "The count lives on the brief, read from main, so a restart does not reset it (F45)."

The script that enforces the cap (`DISPATCH_CAP=4`) does not own its counter: it reads a line the orchestrator writes after the irreversible side effect, in a land that `--cycle-diff` does not judge (fact-check claim 16: `Applied:`/`Dispatched:` pass unjudged), bridged across a failed land only by the model's memory. The failure direction is fail-open on a safety bound (under-count), and the whole second land per iteration (a second `--state`, `--cycle-diff`, commit, `--land-cycle`, and a second exposure to MAIN_WT's cleanliness, finding 9) exists only to persist this counter and an informational `10.` line. This is also a drift from D1 as approved.

**Recommendation:** Make the counter write-ahead: in step 8/9 write `Dispatched: N+1` for each brief step 10 will dispatch, land it in the one land, then have `--start`/`--prompt` accept the already-incremented count (e.g. `--dispatch N`, refusing unless main's line is exactly N and N ≤ cap). A failed dispatch then over-counts (fail-closed) and the second land disappears; the `10.` outcome can go in the next iteration's record. Alternatively record the D1 change as a decision and have `--cycle-diff` judge `Dispatched:` as monotone +1.

#### 3. A stall-stopped loop is re-dispatched without asking when its stop's bookkeeping is lost (D13's "failed land is retried" not carried)

**Severity:** Coupling
**Location:** `skills/dev-cycle/SKILL.md:59-66` (Rules, stop), `:467-470` (working), `:638-641` (step 10 `--steal`); plan D13 (`plan-build-loop-handoff.md:104`)
**Move:** 2, 7
**Confidence:** Medium (static; traced across steps, not executed)
**Legibility-target:** orchestrator

Evidence: step 7: "unless its TIP has not moved in two hours of iterations (the record's `7.` lines): then stop its task by ID and file it as `stopped`, reason "stalled" (D1). Any other (its subagent ended with no marker, or an ended session's) goes to step 10 for `--prompt`." Step 10: "One whose tip is no marker (step 7's working ones, and a stalled loop stopped there): `--prompt BRIEF --steal`". The Rules: "Each stop ends the iteration there, with no record ... A stop after step 0.3 removes WT as step 0.3 does (with `--force`, which discards WT's uncommitted edits; its branch stays)." Plan D13: "A failed land is retried before the next iteration's step 7, so `Asked:` state is never re-derived from a main that lacks it (F49)."

Step 7 performs irreversible actions (TaskStop, `--merge` moving main) before land 1; their records (the `stopped-STEM-N` entry and its `Q-NNN@TIP` on `Asked:`) live only in WT until the land. A stop at land 1 discards them. Next iteration the loop's tip is still not a marker and its subagent has ended, so it is an "any other" working brief and step 10 steals and re-dispatches it, the opposite of the stalled decision the user was to make. The skill has no retry of a stopped iteration's branch (the branch stays, but nothing reads it), so D13's guarantee is replaced by re-derivation.

**Recommendation:** Either implement D13's retry (step 0: if the previous iteration's `chore/dev-cycle-*` branch holds a committed but unlanded record, land it first), or make the stall decision durable outside WT before acting on it (e.g. file and land before TaskStop, or have the orchestrator record "stalled at TIP" somewhere step 7 reads from main). State the choice as a decision-log row.

#### 4. Correctness-bearing state lives only in the session's memory

**Severity:** Coupling
**Location:** `skills/dev-cycle/SKILL.md:467-470`, `:634-641`, `:656-658`, `:244-246`, `:602-603`; `scripts/build-loop.sh:462-463`, `:484-487`
**Move:** 7
**Confidence:** Medium
**Legibility-target:** orchestrator

Evidence: "One whose subagent this session started still runs on"; "Fill free slots (`--settings`' `slots` less the loops this session runs)"; "the session keeps each brief's N"; step 0.2's "once this session has landed a `Main at:` line"; "`--answered Q-NNN` for each answer the user gave this session". The lock reason the script writes carries no session: "locked with the reason "build-loop dispatch of STEM at TIP, UTC TIME"" (plan D1 specified `"<session> <UTC time>"`). `--steal` takes a lock when "that time and the tip's commit time are both over 2 hours ago".

The design is a `/loop` session that runs for days, so context compaction is expected (the global instructions name it). Losing "this session started it" misroutes a live loop that was dispatched over two hours ago and last committed over two hours ago (exactly the stalled case) to `--prompt --steal`, which succeeds without the TaskStop step 7 would have done: two agents in one worktree on one branch. Losing a kept N under-counts the cap (finding 2); losing the slot count over-dispatches. The `--answered` loss fails closed (a refusal), which is the right direction; the others are not.

**Recommendation:** Persist the session-scoped facts where a later iteration (or a restarted session) can read them: put a session ID in the lock reason (as D1 specified) so "mine and live" is read from git, and list task IDs per dispatched brief in the record's `10.` line. Prefer fail-closed defaults where memory is the only source (unknown ownership of a working loop: treat as live, do not steal).

#### 5. The self-merge checkout precondition is owned by the caller, outside the Rules' call-location rule

**Severity:** Coupling
**Location:** `skills/dev-cycle/SKILL.md:471-478`; Rules `:47-48`, `:64-65`; `scripts/build-loop.sh:318-345`
**Move:** 3 (module boundary), 7
**Confidence:** High
**Legibility-target:** orchestrator

Evidence: step 7: "`--merge BRIEF --expect TIP`, run from a gate checkout, not WT: `hg -C MAIN_WT worktree add --detach GT refs/heads/main`, GT at `.claude/wt-dev-cycle-gate-DATE-HHMM` in MAIN_WT, made for this one call and removed after it as step 0.3 removes WT". The Rules: "Every `build-loop.sh` and `dev-cycle.sh` call runs from WT (step 0's first two, from MAIN_WT)"; and "A stop after step 0.3 removes WT as step 0.3 does". The header: "a self-merge brief needs --check run from a clean checkout of the default branch's commit".

The script's precondition (a pristine checkout at main) is satisfied by the orchestrator manufacturing one per call, which leaks the floor's internals (it reads a checkout) into the skill and gives GT a lifecycle the Rules do not cover: GT is a third call location the Rules' "every call runs from WT" does not list, a stop during the `--merge` call (timeout, exit 1) removes WT but nothing names GT, and two self-merge briefs in one iteration reuse one `DATE-HHMM` name with no "name taken" rule as step 0.3 has. A leftover GT is a registered worktree, which step 0.3 notes "joins the import walks' reader set".

**Recommendation:** Smallest fix: add GT to the Rules' call-location sentence and to the stop clause ("a stop removes WT and any GT"), and give GT a per-call suffix. Structural option: let `--merge` create and remove its own detached checkout of main's commit (the script already owns "the gate's own merge repository").
**Security implication:** moving the `worktree add` from the orchestrator's `hg` into the script relocates a crossing of `B1` (loop-writable `.git/config` → `hg` + `--state` → the orchestrator's git, worktree add) from `docs/reviews/security-review-2026-10-13-u4b1-final.md` (Commit: `ea59b0c3`) — security review predates this diff; boundary may be stale. A checkout runs filters the repo config names; the script's hardening would have to cover it. Defer that variant to a combined architecture/security pass.

#### 6. Two bindings from a brief to its questions entries, one of them unjudged

**Severity:** Coupling
**Location:** `skills/dev-cycle/SKILL.md:463-464`, `:479-483`, `:500-505`, `:517-518`; `scripts/build-loop.sh:228-235`
**Move:** 3, 7
**Confidence:** Medium
**Legibility-target:** orchestrator

Evidence: "A brief already asked about at TIP (an item on its `Asked:` line ends `@TIP`, or WT's questions files hold its merge entry's heading below) only has its answers read." "Add `Q-NNN@TIP` to the brief's `Asked:` line" (blocked/stopped/capped). "one call with the IDs of every brief's `Asked:` items and merge entries, less those on its `Applied:` line." `--cycle-diff` requires each added `Asked:` item to name an entry "whose heading (after " · ") is WORDS-STEM-N", so `merge-STEM-SHA12` cannot go on `Asked:` (interim design call 3).

The script's `Asked:` grammar shaped the skill's data model into two indices: blocked/stopped/capped entries are bound by an `Asked:` item that `--cycle-diff` checks (once, by one brief, entry filed in the same change), while merge entries are bound by a heading search in WT's questions files that no script checks, and the acted-on set (`Applied:`) is judged by nobody. A merge entry filed twice for one TIP, or an `Applied:` line dropped by the orchestrator's slip, passes the land; the binding protections row 745 built for `Asked:` do not reach the entry class that moves main.

**Recommendation:** Extend `--cycle-diff`'s `Asked:` item grammar to accept `merge-STEM-SHA12` and `merge-gate-STEM-SHA12` headings (binding SHA12 to the item's `@SHA`), put merge entries on `Asked:` like the rest, and have `--cycle-diff` judge `Applied:` as append-only with items drawn from `Asked:`.

#### 7. Step 7 and step 10 route on free-text WHYs the header does not classify

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:489-492`, `:647-649`; `scripts/build-loop.sh:111-124`, `:953-991`, `:497-501`
**Move:** 7 (control coupling)
**Confidence:** Medium
**Legibility-target:** orchestrator

Evidence: "A `--marker` skip (row 701) whose WHY says the tip is no such marker, or that a read failed, is recorded and read again next iteration; any other WHY (the body breaks the marker rules or is too large) is filed as `stopped`". Code WHYs include "skip $a: the brief is not read", "its marker could not be read", "its marker's body could not be read", "its marker is $n bytes, over the $MARKER_MAX-byte cap". For `--prompt` the header does define the class: "Of the rule refusals, only two can clear with no change to the repository".

Retry-versus-file is a control decision taken by matching prose the script is free to reword; `--status`-style skips ("not read") are read failures only by interpretation. This sits on `B3` (script output → stop wording → whether the iteration continues, files, dispatches) of `docs/reviews/security-review-2026-10-13-u4b1-final.md` (Commit: `ea59b0c3`; predates this diff; boundary may be stale). `--prompt`'s retryable texts are a header contract; `--marker`'s are not.

**Recommendation:** Have the header name `--marker`'s transient WHYs as a closed list (as `--prompt` does), or prefix skips with a class token (`skip-retry` / `skip-bad`), and route on that.

#### 8. Script constants and cross-references duplicated in prose without a pin

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:650` (cap), `:640-641` (steal age), `:539-546` (brief line rules); `scripts/build-loop.sh:1595`, `:1968-1972`
**Move:** 7
**Confidence:** High
**Legibility-target:** maintainer

Evidence: skill: "A brief `--status` read with DISPATCHED 4 (the cap, D1) is never dispatched again"; "takes the lock only once both it and the tip are over two hours old"; code: `DISPATCH_CAP=4; STEAL_AGE=7200`. The gate's own comment still names the removed step: "Step 6 only appends IDs to a brief's first Asked: line ... as step 6's keep-or-drop-STEM-N" (`scripts/build-loop.sh:1968-1972`; also header `:234`, `scripts/lib/dev-cycle-read.sh:2035`).

The diff adds a good pin for GATE_CODE (the new bats test) but not for the cap, which the skill matches by literal value: if the cap changes, the skill's `capped-` entry never fires and `--start`'s refusal becomes an `agent` entry instead. Step 8's brief-shape rules restate `--check-brief`'s skip set by hand. The script comments that cite skill step numbers went stale with this diff's renumbering (step 6 → step 7, keep-or-drop gone).

**Recommendation:** Have `--status` print the cap or a `capped` flag (removing the literal), or add a GATE_CODE-style test pinning "DISPATCHED 4" to DISPATCH_CAP; update the three step-6/keep-or-drop references in the scripts.

#### 9. The Rules' stop clause assumes one land per iteration

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:59-60`, `:655-659`
**Move:** 2
**Confidence:** Medium
**Legibility-target:** orchestrator

Evidence: Rules: "Each stop ends the iteration there, with no record (its `Main at:` would move the next SINCE)". Step 10: "Then land again as step 9 does (1 to 5) ... A stop here leaves those lines unlanded". Step 9: "`Main at:` = MAIN, the commit this iteration started from".

With two lands, a stop in the second one happens after the record has landed, so "with no record" no longer describes it; and since `Main at:` is now the iteration's start commit, the clause's rationale (a landed record would move SINCE past unread commits) no longer holds for either land. The orchestrator executing the Rules gets two incompatible descriptions of what a stop leaves behind.

**Recommendation:** Reword the stop clause to "with no further land", and state the second-land case there (or remove the second land per finding 2).

#### 10. The land and self-merge are gated on the cleanliness of a checkout the orchestrator does not own

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:622-624`; `scripts/build-loop.sh:252-256`, `:425-433`
**Move:** 7
**Confidence:** Medium
**Legibility-target:** user

Evidence: "While MAIN_WT has main checked out, the land fast-forwards it, and refuses while it has tracked edits or is mid-merge: a stop, which the final message explains." MAIN_WT is "the session's starting checkout ... which the cycle reads but never commits in".

The orchestrator's every land (twice per iteration) and every self-merge depend on a shared checkout other sessions and the user edit. With main checked out there and a tracked edit present, each iteration stops at land 1 and dispatches nothing; nothing distinguishes this benign wait from a fault, and each stop files an entry or final-message note. This is D7's design adopted here, not new, but the two-land loop doubles the exposure.

**Recommendation:** Treat "MAIN_WT dirty" as a wait state (one deduplicated entry, retried next wakeup) rather than a stop, or recommend running the orchestrator from a MAIN_WT not on main.

#### 11. The stall timer is read from record prose

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:467-469`, `:572`
**Move:** 7
**Confidence:** Medium
**Legibility-target:** orchestrator

Evidence: "unless its TIP has not moved in two hours of iterations (the record's `7.` lines)"; template: "7. collect: <per brief: STEM LOOP TIP, and what was done>"; "one file per day".

The D1 stall rule's clock is free-form prose in a record split per local day, read by the model (from WT or main, unstated). `--status` prints the tip's DATE at day granularity only, so no machine source carries the time. Workable, but it is the one timer in the design with no script behind it.

**Recommendation:** Have `--status` print the tip's commit time (UTC, minutes) so the stall rule reads "tip older than 2 hours and lock older than 2 hours", the same pair `--steal` uses.

## What Looks Good

- The gate scripts remain the single choke point for everything that reaches main: `--cycle-diff` before the commit, `--land-cycle` judging the merge copy, `--merge`/`--approved` for loop work. Steps 9.3-9.5 defer to the header's list rather than re-specifying it.
- The GATE_CODE copy in step 7 is pinned to the lib by the new bats test, the right pattern for a rule that must exist in both prose and code.
- `Main at:` as the iteration's start commit, with the next SINCE read from main, makes the record a monotone cursor over main's history; `--main-log`'s classes keep chore and gate merges separable from foreign ones.
- Answers are read from main only (D8), and the orchestrator's merge of a reviewed entry binds the full TIP the entry names, not the live tip.
- Briefs land before dispatch, so a loop's brief, `Asked:` state and policy lines are read by the loop and `--status` from the same commit.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Blocked answers read through the 3-option keep/drop/done reader; a 4th option or fact answer reads `unrecognized` and never resumes | Coupling | `SKILL.md:503-510`; lib `:2070-2081` | High / Medium |
| 2 | Dispatch cap counter written after the dispatch via a second, unjudged land, bridged by memory; drifts from D1 | Coupling | `SKILL.md:642-646, 655-659` | High |
| 3 | Stall-stop bookkeeping lost on a land-1 stop; next iteration steals and re-dispatches; D13 retry not carried | Coupling | `SKILL.md:59-66, 467-470, 638-641` | Medium |
| 4 | Loop ownership, slot count, kept N held only in session memory; lock carries no session; compaction can steal a live loop | Coupling | `SKILL.md:467-470, 634-641` | Medium |
| 5 | GT checkout owned by the caller; Rules' call-location and stop clauses omit it; name reuse | Coupling | `SKILL.md:471-478, 47-48, 64-65` | High |
| 6 | Merge entries bound by heading search, not `Asked:`; `Applied:` unjudged | Coupling | `SKILL.md:463-464, 500-518` | Medium |
| 7 | `--marker` skips routed on unclassified free-text WHY | Minor | `SKILL.md:489-492` | Medium |
| 8 | Cap and steal age duplicated unpinned; script comments cite removed step 6 | Minor | `SKILL.md:650`; `build-loop.sh:1968-1972` | High |
| 9 | Rules' stop clause ("with no record") inconsistent with the two-land design | Minor | `SKILL.md:59-60, 655-659` | Medium |
| 10 | Land and self-merge gated on MAIN_WT's cleanliness; dirty main stops every iteration | Informational | `SKILL.md:622-624` | Medium |
| 11 | Stall timer read from record prose; no machine time source | Informational | `SKILL.md:467-469` | Medium |

## Overall Assessment

The change keeps the system's main structural invariant intact: the skill decides, the scripts judge, and nothing reaches main except through `--cycle-diff`/`--land-cycle`/`--merge`. The weaknesses are in the state model around that invariant. The loop's control facts are spread over six stores, and the ones the scripts do not judge (`Dispatched:`, `Applied:`, merge-entry binding, loop ownership, the stall timer) are exactly where the failure modes concentrate: under-counted caps, re-dispatch without asking, and a live loop stolen after compaction. All are fixable in place. The most important structural concern is finding 2: the cap's counter is written after the side effect it bounds. Making it write-ahead removes the second land per iteration, which also shrinks findings 3, 9 and 10. Finding 1 is the most user-visible: as written, D2's async Path B can dead-end on any blocked question that is not a three-option choice.

## Goal-Alignment Note

Success criterion: "An architecture review saved at the given path, structured per the architecture-review skill." Met: saved at `docs/reviews/architecture-review-2026-10-13-u4b2-i2.md` in the worktree, with the skill's header, Dependency Map, Findings (Severity, Location, Move, Confidence, plus the brief's verbatim Evidence and Legibility-target), What Looks Good, Summary Table and Overall Assessment, and the trust-boundary cross-reference applied (findings 5 and 7). Covered the brief's focus list: state model (Dependency Map table; findings 2, 3, 4, 6, 11), script-rule duplication (7, 8), the two-lands design (2, 9, 10), the per-call gate worktree (5), and step-flow coherence with D1-D14 and U4b1's Rules and step 0 (2 vs D1, 3 vs D13, 4 vs D1's lock reason, 9 vs the Rules). Limits: all findings are static readings, none executed; findings 3 and 4 are traced across steps and rated Medium; D4's "Review handoff: pull request" path is absent from the skill but outside the U4b2 bullet, so not filed.
