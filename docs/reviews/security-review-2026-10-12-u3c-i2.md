Commit: 74deb04e

# Security Review: feat/build-loop-u3c, iteration 2 (full branch)

**Scope:** `git diff main...HEAD` (main = dafc0e74, HEAD = 74deb04e): `scripts/build-loop.sh` (--cycle-diff, QKEYS_AWK, QDIFF_AWK, ROADMAP_AWK, cyc_blob, cycle_diff, raw_records and its three migrated callers), `scripts/health-check.sh` (take_lock), T38/T43 tests, the plan bullet and override rows.
**Date:** 2026-10-12
**Based on:** `docs/reviews/code-fact-check-report-2026-10-12-u3c-i2.md` (33 claims, 0 Incorrect; 4 Mostly accurate: 2, 15, 28, 30). Its executed claims are taken as the record of what the code does; this review does not re-verify them.

No HALT escalation: no pattern on the escalation list matches.

## Trust Boundary Map

```
B1 (new): [orchestrator worktree's staged index]           → [diff-index --cached → raw_records → cyc_blob → QKEYS/QDIFF/ROADMAP awk] → [ok / refuse, read by U4 before the chore commit]
B2 (new): [orchestrator HEAD and its history]               → [git merge-base HEAD MAIN_SHA]                                         → [BASE: the comparison baseline]
B3 (new): [--answered argv, written by the orchestrator]    → [QDIFF_AWK ok[] exemption]                                             → [a changed or pre-answered entry passes]
B4 (new): [chore branch + main's concurrent commits]        → [3-way merge at land: NOT re-checked]                                  → [main's questions files → check_answer → --approved / Asked:]
B5 (new): [shared common git dir: health-check.lock]        → [take_lock plain-file test → flock(1) open]                            → [one health check per repository]
B6 (new): [caller environment: HEALTH_CHECK_LOCK_HELD]      → [take_lock early return]                                               → [run skips the lock]
B7 (moved): [git --raw -z listings (gate repository)]       → [raw_records: regex + NUL count]                                       → [check_line, log_class chore/answers, cycle_diff]
```

Input-source classification:

```
S1: staged index blobs (questions, roadmap, idea log)  — request-time (orchestrator, or any same-uid writer of its worktree)
                                                          — UNTRUSTED for the answer-reading sink (check_answer/--approved)
S2: HEAD and the chore branch's history                — runtime-mutable (orchestrator)
                                                          — UNTRUSTED for base selection; bounded only by being an ancestor of S3
S3: MAIN_SHA                                           — re-hashed by state_start (store_check --main)
                                                          — trusted as the anchor; BASE's own objects are not re-hashed (header says so)
S4: --answered IDs                                     — request-time (orchestrator argv)
                                                          — format-validated (^Q-[0-9]+$); trusted only as the orchestrator's declaration,
                                                            UNTRUSTED as evidence the user answered
S5: main's commits after BASE (user answers, step 7's merges)
                                                       — runtime-mutable — trusted content (user / gated merges), but its
                                                            composition with S1 at land is unchecked (B4)
S6: <common-dir>/health-check.lock path                — runtime-mutable by every session sharing the common dir (build loops included)
                                                          — UNTRUSTED for open/flock (FIFO, symlink, held lock)
S7: HEALTH_CHECK_LOCK_HELD                             — caller environment — untrusted; sink is availability/serialization only
S8: git --raw -z output                                — produced by hardened git (gate_git / git_harden)
                                                          — trusted for shape once raw_records' regex and NUL count pass
S9: PATH (flock, bash)                                 — caller environment — pre-existing trust, unchanged by this diff
```

What enters from outside: the orchestrator's staged index (S1), its choice of HEAD (S2) and its own `--answered` list (S4) decide what --cycle-diff compares and exempts; the health-check lock path (S6) is writable by every worktree session. The diff assumes that what --cycle-diff judges (the chore branch's diff against the fork point) is what check_answer later reads on main. That assumption fails at B4: the landed file is a 3-way merge of the chore side with main's concurrent commits, and nothing re-checks the merge result.

## Findings

#### F1. A clean merge of a --cycle-diff-ok chore branch can turn the user's "drop" into "keep" (the check judges the branch's diff, not what lands)

**Severity:** Medium
**Location:** `scripts/build-loop.sh:1806-1860` (cycle_diff; base at `:1808`), `scripts/build-loop.sh:1738-1773` (QKEYS_AWK / QDIFF_AWK); reader `scripts/lib/dev-cycle-read.sh:2058-2148` (ANSWER_AWK, check_answer)
**Boundary:** B4 (with B1, B2)
**Move:** #4 (TOCTOU: check on the branch, use on the merge result), #11 (guardrail bypass)
**Confidence:** High on the mechanism (executed); Medium on how reachable it is under the stated threat model

**Weakness.** --cycle-diff compares the staged index with BASE = merge-base(HEAD, MAIN_SHA). It proves that the chore side changes no entry's key lines. But check_answer reads the 3-way merge of that side with whatever main gained since BASE. Body lines are free on the chore side. Fence lines and `#`/`##`/`###` headings are body lines, but they decide which lines of the merged file check_answer reads. A chore side can add a balanced fence pair around body-only lines. In its own index that changes no key line, so --cycle-diff prints `ok`. If the user's answer, committed on main during the cycle, falls between those two fence lines, git merges the two sides cleanly (non-adjacent hunks) and the user's answer line is fenced in the result. check_answer then reads the entry's next answer-labelled line.

**Preconditions.**
- The chore branch lands by merge while main holds a user answer committed after BASE. The plan expects this ("a user's answer commit can land while it runs").
- The fence pair straddles the line where the user inserted the answer.
- For a flip to `keep`, the entry already holds a later answer-labelled line on BASE, such as a stale earlier answer or a recorded recommendation. Without one, the hidden answer reads `unrecognized`, which is fail-safe for `--approved`.

The fence pair need not be deliberate: an orchestrator adding a fenced code sample to an entry's body is an ordinary edit, and only the position of the user's line decides the outcome.

**Impact.** On the probe below, main read `drop Q-007` after the user's answer and `keep Q-007` after the chore merge. The entry's heading is `Q-007 · merge-x-0123456789ab`, so `--approved Q-007` would accept it for that brief's tip. No `--answered` was passed and no key line was changed on the chore side. --main-log would class the merge as chore if its tree is merge-tree's clean merge, so the main-log audit does not flag it either. This is the laundering F42 and F33 name, reached through composition rather than a direct edit.

**Evidence (executed).** `scratchpad/sec-u3c-i2/probe-merge.sh` ran on a fixture repo under `scratchpad/sec-u3c-i2/p-c5do`, with the worktree's `build-loop.sh` and `dev-cycle.sh`:

```
base read: open Q-007
cycle-diff on chore index: ok|
main after user answer: drop Q-007
Auto-merging docs/working/questions.md
merge clean
main after chore merge: keep Q-007
```

The merged entry, verbatim:

````
### Q-007 · merge-x-0123456789ab
**Needs:** you: judgment · **Opened:** 2026-10-12 · **Status:** ANSWERED

Which?
```
Notes A.
Notes B.
Q-007: [2]
Notes C.
Notes D.
```

**Answered earlier (stale):** keep
````

**Fix (either).**
- (a) Judge what lands. When main has moved, run the questions rule with MAIN_SHA as the old side and merge-tree(MAIN_SHA, the index's tree) as the new side, and refuse a conflicted or non-clean merge.
- (b) Make cycle_diff refuse when the questions files differ between BASE and MAIN_SHA, telling the orchestrator to merge main into the chore branch first. The user's lines are then on BASE, and fencing them is a key-line change. U4's land must also move main only from the checked MAIN_SHA (compare-and-swap, as --merge's land does), or re-run the check.

Option (b) is a few lines and keeps the rule's current reading. Either way, add this probe as a T38 case.

#### F2. `--answered` is the orchestrator's own assertion, and nothing records it

**Severity:** Low
**Location:** `scripts/build-loop.sh:489-494` (argument parse), `:1766` (QDIFF_AWK BEGIN, `ok[]`), `:1863` (`-v ids="${ANSWERED[*]}"`)
**Boundary:** B3
**Move:** #5 (invert the access-control model)
**Confidence:** High

**Weakness.** The rule's only exemption comes from argv written by the party it constrains. Any ID passed with `--answered` may flip Status, rewrite or reorder answer lines, or file an entry pre-answered. That includes a `merge-STEM-SHA12` entry, which is the exact F33 shape. The header's framing ("catches the orchestrator's own slip") is consistent with this. The plan's F42 row ("The orchestrator launders … covered: `--cycle-diff --answered`") reads stronger than the mechanism supports.

**Preconditions.** An orchestrator that passes an ID the user did not answer in-session, by error (a mis-typed or copied list) or by intent.

**Impact.** The laundering is unbounded and invisible after the fact: neither --cycle-diff's output nor the chore commit carries the exempted IDs.

**Fix.** The binding belongs to U4. Have --cycle-diff print the IDs it exempted (for example `ok answered Q-…`), and have the chore commit or cycle record carry them, so the user and --main-log's digest can see which answers came from a session rather than from main. Narrow F42's "covered" wording to "slip, with an audit trail".

#### F3. The health-check lock is a cross-worktree availability lever: no timeout, and fail-closed on a planted path

**Severity:** Low
**Location:** `scripts/health-check.sh:1106-1121` (take_lock)
**Boundary:** B5
**Move:** #8 (scale/DoS), #4 (TOCTOU between the plain-file test and flock's open)
**Confidence:** High (from reading; the fact-check's E1, E4 and E8 executed the lock's normal paths)

**Weakness.** Every session sharing the common git dir can affect every other session's health check through one path.
- **A held lock.** A holder that never releases makes every other run wait forever: the second `flock -o "$lk"` has no `-w`. Before this unit, a hung health check stalled only its own caller.
- **A planted non-plain file.** A FIFO or symlink at the lock path makes every run exit 1 with "not a plain file". This is fail-closed, but every gate goes red.
- **A race.** The `-L` / `-f` test and flock(1)'s open are separate steps. A FIFO swapped in between makes flock's open block, a hang rather than a refusal. A symlink swapped in makes flock create the target as an empty file. It does not truncate, and a same-uid racer could create that file anyway.

**Preconditions.** A same-uid process with write access to the common dir (a build loop, or a stuck health check). This is the Q-103 same-uid writer class, so it adds no new capability. The new part is that one stuck or hostile run now blocks the orchestrator's gate too.

**Impact.** Availability only. The lock guards resource contention, not integrity.

**Fix.**
- Give the blocking flock a bound (`-w N`, with a message naming the lock and an exit status distinct from a failing check), so the orchestrator sees a stop rather than a hang.
- Optionally pass `-n`-style open semantics for the FIFO race (open the lock with `O_NONBLOCK` via `exec {fd}<>` in a subshell and test `-f` on the descriptor), or accept the race as Q-103 class and say so in the take_lock comment.

U4 should also read a timed-out health check as a stop.

#### F4. The check-to-commit binding rests on a plain `git commit`, which runs hooks from the shared common dir

**Severity:** Informational (a U4 hand-off; the code in this diff is not wrong)
**Location:** `docs/reviews/override-log.md:747` (the U4 duty row), `scripts/build-loop.sh:183-215` (header: "which takes the index as is")
**Boundary:** B1
**Move:** #4 (TOCTOU)
**Confidence:** Medium

**Weakness.** Override row 747 binds U4 to commit the index "as --cycle-diff read it". The planned trigger text says the commit is a "plain `git commit`". A plain commit outside the script's git_harden runs `pre-commit` and `prepare-commit-msg` hooks from `<common-dir>/hooks` (or `core.hooksPath`). Every worktree session can write that directory, and a hook can re-stage files after the check. The scripts' own git carries `core.hooksPath=/dev/null` (HARDEN, `scripts/lib/dev-cycle-read.sh:349`); the orchestrator's commit would not.

**Preconditions.** A planted hook (the Q-103 writer class), or a legitimately installed hook that formats staged markdown.

**Impact.** The landed questions file differs from the one judged.

**Fix (U4).**
- Have --cycle-diff print the index's tree id (`git write-tree`), and commit exactly that tree (`commit-tree`, or a commit with HARDEN's `-c core.hooksPath=/dev/null`).
- Then compare the new commit's tree with the printed id.
- Add this to row 747's revisit text.

## Untested bypass candidates (move #11, the questions rule)

These were enumerated against the questions guardrail. F1 and F2 are the tested bypasses. The fact-check's E2 tested unfencing, heading removal, swapped Needs lines, a duplicate heading and a trailing-tab Status; all refused or were fail-safe. These were traced by reading only, or left untested:
- **Criss-cross history** (`git merge-base` prints one of several bases): the same class as F1, since the recursive merge uses a virtual base. Not executed.
- **Intent-to-add index entries** for a questions file absent on BASE: traced as consistent (neither `diff-index --cached` nor `git commit` carries the content). Not executed.
- **A brief's `Asked:` line re-pointed at an old ID already answered keep**: the brief is an "other path" (row 722, deferred to U4). It re-binds an existing answer rather than forging one, and `--approved`'s heading binding does not apply to `Asked:`. Not executed; belongs to U4's step 9.
- **The roadmap rule:** a brief named outside Done can be "moved to Done at `closed/`" without the brief file moving. The rule checks only that the name survives (interim call (b)). This is a semantics gap, not an answer laundering.

Because the questions rule has untested candidates and a confirmed bypass (F1), it does not appear in the Endorsement Claims.

## Endorsement Claims

- **Claim:** `raw_records` returns non-zero on any record whose meta field fails the regex, and when the NUL count is not twice the record count. Each of its four callers turns that into a refusal or the `other` class, never an accept.
  **Location:** `scripts/build-loop.sh:973-980`, `:1316`, `:1702`, `:1709`, `:1811-1813`
  **Evidence:** read-static
  **Verified:** read raw_records whole and each call site's `||` branch: check_line prints `refuse … could not be read`; log_class's chore and answers branches `return 0` with CLASS still `other`; cycle_diff prints `refuse index:`. The fact-check's claim 2 adds the chore loop's one behaviour change (an incomplete record now reads as other).
  **Not verified:** git output that carries a NUL inside a path field under `-z` (git does not emit one; not executed).
  **route: code-fact-check**
- **Claim:** cycle_diff reads staged content only from index blob ids and BASE objects. It reads no working-tree file, so an unstaged edit in the orchestrator's worktree does not change its verdict.
  **Location:** `scripts/build-loop.sh:1799-1860`
  **Evidence:** read-static
  **Verified:** every read in cycle_diff and cyc_blob is `git diff-index --cached`, `gate_git cat-file blob <id>` or `gate_git cat-file blob "$base:$f"`. The fact-check's claim 3 concurs.
  **Not verified:** what U4's commit takes (F4); the merge result (F1).
  **route: code-fact-check**
- **Claim:** take_lock runs the health check as flock(1)'s child with the lock descriptor closed (`-o`), so a process the run leaves behind does not hold the lock.
  **Location:** `scripts/health-check.sh:1115`, `:1118`
  **Evidence:** read-static (the fact-check executed it: E4 found 0 lock descriptors in the runner, and E6's m2 mutant fails T43 on the leftover-process case)
  **Verified:** read take_lock whole and the fact-check's E4 and E6 logs as cited.
  **Not verified:** a flock(1) killed with SIGKILL while its child runs (the child then runs unlocked and a second run can start).
  **route: code-fact-check**
- **Claim:** the `--answered` arguments reach awk only after `^Q-[0123456789]+$` validation, so `-v ids=` (which interprets backslash escapes) receives no escape sequence or separator other than single spaces.
  **Location:** `scripts/build-loop.sh:489-494`, `:1863`
  **Evidence:** read-static
  **Verified:** read the parse loop and the awk call.
  **Not verified:** none further within this flow; this is a minor positive.

## Primitive sweep

```
Primitive: process exec / re-exec
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/health-check.sh:1115` flock -n -E 75 -o "$lk" bash "$REPO_ROOT/scripts/health-check.sh" "$@" | S6 lk, S9 PATH | plain-file test (racy) | F3 (lock path race / DoS); script path is REPO_ROOT from BASH_SOURCE, cleared (row 682: health-check.sh is neither gate code nor floor, pre-existing) |
| `scripts/health-check.sh:1118` flock -o "$lk" bash … (blocking) | S6, S9 | same | F3 (no timeout) |

Primitive: file open / path construction
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/health-check.sh:1113` lk="$d/health-check.lock" | S6 (d from git rev-parse --git-common-dir) | `-L` / `-e && ! -f` | F3 (TOCTOU to flock's open) |
| `scripts/build-loop.sh:1803` gate_git cat-file blob "$id" > "$3" | S1 (id, hex by raw_records regex) | regex + mode 100644 | cleared: id validated, OUT is a fixed $GATE_TMP name |
| `scripts/build-loop.sh:1841` gate_git cat-file blob "$base:$f" | S2/S3 (base hex), f constant | ls-tree mode 100644 | cleared |
| `scripts/build-loop.sh:1810` git diff-index --cached … "$base" | S2 (base) | merge-base output | cleared: a revision argument, not a path; refuses on any stderr |

Primitive: interpreter fed data (awk)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:1829` awk "$ROADMAP_AWK" "$t.o" "$t.n" | S1 (file contents, data only) | program constant | cleared: contents are records, never program text |
| `scripts/build-loop.sh:1846` awk -v f="${f##*/}" "$FENCE_AWK$QKEYS_AWK" | S1, f constant | program constant | cleared |
| `scripts/build-loop.sh:1863` awk -v ids="${ANSWERED[*]}" "$QDIFF_AWK" | S4 | ^Q-[0-9]+$ | cleared (Endorsement 4) |
```

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | A clean merge of a --cycle-diff-ok chore branch fences the user's answer; check_answer reads a stale `keep` (executed: drop → keep, no --answered) | Medium | B4 (B1, B2) | `scripts/build-loop.sh:1806-1860` | High (mechanism) / Medium (reach) |
| 2 | `--answered` is self-asserted by the constrained party and recorded nowhere | Low | B3 | `scripts/build-loop.sh:489-494`, `:1863` | High |
| 3 | Shared health-check lock: indefinite wait, fail-closed on a planted path, FIFO race at open | Low | B5 | `scripts/health-check.sh:1106-1121` | High |
| 4 | Check-to-commit binding via a plain `git commit` runs shared-dir hooks (U4 hand-off) | Informational | B1 | `docs/reviews/override-log.md:747` | Medium |

## Overall Assessment

The unit's local checks hold where they were read and tested. raw_records fails closed at every caller. QKEYS_AWK delimits entries and selects a superset of the lines ANSWER_AWK reads, and iteration 1's ordering hole (A1) is closed. The lock does not leak its descriptor. The one real gap is architectural but small to fix. --cycle-diff certifies the chore branch's diff against the fork point, while the answer that `--approved` and `Asked:` trust is read from the merge result on main. Body-level fence and heading lines on the chore side can re-scope the user's concurrent answer lines in that merge, without touching a key line on either side (F1, executed). Make cycle_diff refuse when main has changed the questions files since BASE (merge main in first), and have U4 land only from the checked MAIN_SHA. Alternatively, judge the merge-tree result directly. F2 and F4 are U4 hand-offs that turn the check from a slip-catcher into an auditable one: record the `--answered` IDs, and commit exactly the tree that was checked. F3 is availability within the Q-103 same-uid class and wants a timeout. Assessment: no blocking issue other than F1; the endorsement claims are pending execution verification.
