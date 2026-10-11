Commit: 4b863735

# API Consistency Review — feat/build-loop-u3d (U3d, final confirming pass)

**Scope:** `git diff main...HEAD -- scripts test` in /workspace/.claude/wt-build-loop-u3d (scripts/build-loop.sh, test/scripts/build-loop-dispatch.bats), base main 12913760; plus the plan's step 7 as-built note (B7)
**Date:** 2026-10-10
**Based on:** Stage 1 fact-check k=3 at 4b863735 (docs/reviews/code-fact-check-report-u3d-final-r{1,2,3}.md, summary in the shared brief); iteration-2 report docs/reviews/api-consistency-review-2026-10-10-u3d-i2.md

Probe provenance: one probe, `p1.sh` in `/tmp/claude-1000/-workspace/a5f5e272-7757-42c2-8d1d-5c819728d807/scratchpad/u3d-fin-apicons/`, under `set -eu` in its own `mktemp -d /tmp/claude-1000/u3d-rev-apicons-XXXX` (pwd checked before `git init`), hermetic git env as the suite's fixture, every run under `timeout`; the dir was removed (no `u3d-rev-apicons-*` left; the background `flock` was killed and waited). It ran: (A) a directory planted at `.git/build-loop-dispatch.lock`, `--start` twice; (B) the lock file `chmod 000`; (C) a held lock with a non-brief path and a real brief; (D) `--start`, a `handoff: stopped: stalled` marker, then `--prompt` twice and `--status`. The suite `test/scripts/build-loop-dispatch.bats` ran green (4/4) at 4b863735.

## Iteration-2 fixes, checked

| i2 # | Fix | Verdict |
|---|---|---|
| 1 (B1) | A marker tip lets `--prompt` replace the lock without `--steal` (`scripts/build-loop.sh:1310`) | Fixed for the plan's flows (probe D: `stopped` marker → `--prompt` exit 0; suite test 4 covers `blocked`). New issue: the exemption holds until the re-dispatched loop's first commit, so a second `--prompt` also succeeds (Finding 1). |
| 2 (B5) | `--steal` usage text (`:369-371`) | Fixed: `--steal goes with --prompt, given once`, the shape of `--approved goes with --merge` / `... given once` (:355-356); tested (suite :44). |
| 3 (B6/B3) | `readerform` replaces `absform` for `--dir`, the default DIR and an existing worktree's path (`:368`, `:1308`, `:1315`) | Fixed: one predicate, the lib's (`scripts/lib/dev-cycle-read.sh:598`); `absform` is gone. |
| 4 (B7) | Plan as-built note (`docs/working/plan-build-loop-handoff.md:320`) | Present and accurate to the code, but the before-code text it contradicts (D1 :39-40, Dispatch :216-217, F44 :162, T40 :382) is unchanged and the note does not say it supersedes them (Finding 3). |
| 5 | `dispatched N` without BRIEF | Unchanged (informational, plan-fixed); the override row covers it. |
| 6 | wt_of beside land's parser | Unchanged; override row (row 663 trigger judged). Not re-raised. |

## Baseline Conventions

As in iteration 2 (build-loop.sh header :6-330, parser :340-375, mode block :1353-1399): verdict word first, then BRIEF; refusals `refuse BRIEF: WHY` (exit 2), `skip BRIEF: WHY` (exit 2), `refuse state WHAT: WHY` (exit 2); usage errors on stderr `WHY (usage: ...)` exit 1. There is **one refusal class**: the script has no retry-able vs permanent split in exit codes or line shapes. `--merge`'s transient refusals ("the default branch moved after the check, or could not be updated; it was left as it is", :1236; "the git state changed after the check", :1233) print as `refuse BRIEF: WHY`, exit 2, the same as permanent ones (`the brief's policy is review`, :1383). A caller tells them apart only by WHY prose. The plan's precedent for retry is a caller rule, not a script code: F49 "retry a pending land first (D13)" (plan :167).

## Name-Pattern Audit

New public names since iteration 2 (the rest unchanged from the i2 audit, all Consistent but `dispatched N` Informational):

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `refuse BRIEF: another --start or --prompt is running in this repository (its lock could not be taken)` | refusal line | `refuse BRIEF: the default branch moved after the check, ...`, `refuse state WHAT: WHY` | `scripts/build-loop.sh:1236,1233,431` | Consistent shape and exit (2); per-brief, not `refuse state` (right: the state gate is about planted state). Its WHY is also printed for permanent causes (Finding 2). |
| `build-loop-dispatch.lock` | file in git common dir | `index.lock`, `HEAD.lock` (git's own `*.lock`); no script-owned file in `.git` before | none — searched `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh` for `.lock` / git-common-dir writes | New category; `build-loop-` prefix scopes it to the script. Note: git's own `*.lock` files mean "a writer holds this"; git removes them, this one persists (a flock target, never removed). Harmless to git (no ref or config is named so). Informational, not filed. |
| `--steal goes with --prompt, given once` | usage text | `--approved goes with --merge`; `--approved takes one question ID ..., given once` | `scripts/build-loop.sh:355-356` | Consistent |
| `DISPATCH_CAP`, `STEAL_AGE` | constants | `NAMECHARS`, `GATE_CODE`, `STATE_KEYS_RE` (upper-case globals) | `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh` | Consistent |

## Findings

#### 1. The marker exemption also lets a second --prompt take the worktree of a loop it just re-dispatched (the tip is still the marker), with the same `dispatched N`

**Severity:** Inconsistent
**Location:** `scripts/build-loop.sh:1310` (dispatch, :1290-1328, read whole; `steal`, :1269-1286)
**Move:** 9 (idempotency and retry semantics), 3 (consumer contract)
**Confidence:** High (executed)
**Legibility-target:** U4's orchestrator author; the plan's F44 reader

Evidence:
```bash
# scripts/build-loop.sh:1309-1310
    # A marker at the tip: the loop has ended (D3), so its lock is replaced without --steal (i2 api-consistency 1).
    elif [[ -n "$WT_LOCK" && "${STATUS[loop]}" == working ]] && ! steal; then x="$STEAL_WHY"
```
```
# header :302-303
#             hours ago, or the tip is a handoff marker (the loop has ended);
#             then it is locked again with a new reason.
```
Executed (p1.sh, D): `--start` → ok; commit `handoff: stopped: stalled` in the worktree; `--prompt` → `ok ... feat/x .../wt-2026-10-01-x`, `dispatched 1`, exit 0 (the i2 fix, correct); a second `--prompt` immediately after → again `ok ...`, `dispatched 1`, exit 0. Between a re-dispatch and the new loop's first commit the tip is still the marker, so "the loop has ended" is false for the lock the first `--prompt` just wrote, and nothing else refuses: the flock serializes the two runs but does not refuse the second, and `Dispatched:` lives on main and is written only at the orchestrator's next chore commit (plan :218), so N repeats and the cap does not count the duplicate. F44 ("two agents in one worktree after re-dispatch", plan :162) was covered by the lock alone; for a marker tip it now is not. Honest-path reach: two orchestrator sessions each re-dispatching the same answered `blocked` brief (sessions share /workspace), or one orchestrator retrying a `--prompt` whose Agent launch it believes failed. Before B1 the second run refused (and the first did too, the i2 problem); the fix traded a false refusal for a false ok.

**Recommendation:** Exempt a marker tip only when the marker is newer than the lock: take the lock without `--steal` when the tip is a marker and its commit time is at or after the time the lock reason ends with (a lock written after the marker is a newer dispatch, so treat it as `working`); a lock reason without a parseable time keeps today's marker rule or refuses (author's call, state it). Add the second-`--prompt` case to suite test 4 and one clause to the header. Alternative if the author prefers no time comparison: U4 must hold "re-dispatched, no commit yet" state itself, and the plan's F44 row should say the lock no longer covers it.

#### 2. The dispatch-lock refusal is one shape for a retry-able and a permanent cause, and names "another --start or --prompt is running" for both

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1391-1395`
**Move:** 4 (error consistency), 9 (retry semantics)
**Confidence:** High (executed)
**Legibility-target:** U4's orchestrator (how it treats a `--start`/`--prompt` refusal)

Evidence:
```bash
# scripts/build-loop.sh:1391-1395 (the start|prompt arm, :1389-1398, read whole)
    # One dispatch at a time in the repository, from the worktree listing to the
    # printed ok (i2 security 1: two runs could both add or steal); a second refuses.
    if ! { exec 9>> "$(git rev-parse --path-format=absolute --git-common-dir)/build-loop-dispatch.lock" && flock -n 9; } 2>/dev/null; then
      echo "refuse ${ARGS[0]}: another --start or --prompt is running in this repository (its lock could not be taken)"; exit 2
    fi
```
Executed (p1.sh): a held lock (C) → `refuse ...: another --start or --prompt is running in this repository (its lock could not be taken)`, exit 2: retry-able, correct. A directory at the lock path (A, run twice) and a `chmod 000` lock file (B) → the same line, exit 2, every time: permanent until a human acts, but worded as contention. The fact-check rated the wording "mostly accurate, fails closed" (all three replicates); the API consequence is what U4 does with it. The script's convention (Baseline) is one refusal class with prose WHY, so a new exit code would break precedent; but then the WHY is U4's only classifier, and this WHY tells a retrying orchestrator to wait for a run that does not exist, forever. Also under contention the line precedes `status_fields`, so a path that is not a brief prints `refuse ...: another ... is running` instead of its usual `skip ...: not a build brief` (probe C); harmless for an orchestrator that passes only briefs.

**Recommendation:** Split the two causes: `exec 9>> ...` failing → `refuse BRIEF: the dispatch lock file GITDIR/build-loop-dispatch.lock could not be opened` (permanent); `flock -n` failing → today's text (retry-able). Then state the retry contract in the header's --start/--prompt paragraph in one sentence U4 can encode, e.g. "every refusal leaves nothing behind, so a caller may re-run at its next wakeup; only 'another --start or --prompt is running' and '... under 2 hours old' can clear without a change to the repository", and keep those WHY texts fixed (a test already pins each verbatim).

#### 3. The B7 as-built note sits in step 7 while the plan's D1, Dispatch interface, F44 and T40 still state the pre-B1 contract

**Severity:** Minor
**Location:** `docs/working/plan-build-loop-handoff.md:40,162,217,382` against `:320`
**Move:** 3 (documentation drift)
**Confidence:** High

Evidence:
```
# plan :217
- `--prompt BRIEF [--steal]` → the brief must be `open`, with its branch present and `Dispatched:` under 4. Prints the prompt; adds a worktree only if the branch has none; refuses a locked worktree unless `--steal` and the tip is over 2 hours old.
```
```
# plan :320 (as-built note, excerpt; the bullet continues with the flock, --dir, output and suite)
... a lock is taken without `--steal` when the tip is a handoff marker (the loop has ended), and with `--steal` only when both the lock reason's time and the tip's commit time are over 2 hours old; ...
```
The note is accurate to the code (lock reason, create-only update-ref, marker rule, flock, readerform, output lines). But D1 :39-40 (lock reason `"<session> <UTC time>"`, "refuses a worktree still locked ... unless `--steal` and the tip is over 2 hours old"), the Dispatch bullets :216-217 (no `--dir` on `--prompt`, `worktree add -b`, no marker exemption, no `ok BRIEF BRANCH DIR` line), F44 :162 and T40 :382 are unchanged, and unlike U2b3's note (:307, "Supersedes the before-code paragraph where they differ") this one does not say it supersedes them. U4's author reads the "Script interface" section first; it contradicts the note on the marker rule, which is the one U4's re-dispatch flows (:62-64) depend on.

**Recommendation:** Add "Supersedes D1's lock reason and the Dispatch bullets where they differ" to the note, or point :217 at it (`as built: see step 7, U3d`). Whatever Finding 1 settles goes in the same note.

## What Looks Good

- **B5** matches the parser's existing placement/repeat wording exactly, and is tested.
- **B6/B3**: one path predicate (`readerform`) for `--dir`, the default directory and an existing worktree's path; no second copy to drift.
- **B1** restores the plan's routine re-dispatch flows (`blocked` answered, review [3], `stopped` [1]) without `--steal`, verified by the suite and probe D; `--steal` stays the exceptional path for a `working` tip.
- **The dispatch lock** is held from before `status_fields` to the printed ok (the fact-check verified release at exit), refuses rather than waits (`flock -n`: a dispatch never hangs the orchestrator), uses the existing `refuse BRIEF: WHY` / exit 2 shape, and the header's "Writes nothing but" list names the lock file.
- **B10**: a failed add now carries git's first line, so the one refusal whose cause is outside the script is diagnosable.
- `DISPATCH_CAP` feeds both the refusal and the prompt's "dispatch N of at most 4", so the two cannot disagree.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Marker exemption lets a second `--prompt` take a just-re-dispatched loop's worktree (same `dispatched N`) | Inconsistent | `scripts/build-loop.sh:1310` | High |
| 2 | Dispatch-lock refusal: same WHY for held lock (retry-able) and unopenable file (permanent); no stated retry contract for U4 | Minor | `scripts/build-loop.sh:1391-1395` | High |
| 3 | B7 note does not supersede the plan's D1 / Dispatch / F44 / T40 text it contradicts | Minor | `docs/working/plan-build-loop-handoff.md:217,320` | High |

## Overall Assessment

The i2 fixes are in and consistent with the script's conventions: `--steal`'s usage text, one path predicate, the dispatch lock's refusal shape and exit, and an accurate as-built note. One contract issue remains, introduced by B1: "a marker at the tip means the loop has ended" stays true only until the re-dispatched loop's first commit, so a second `--prompt` in that window is an ok with the same N and the lock no longer guards F44 for marker tips (Finding 1, executed); a lock-time vs marker-time comparison fixes it in place. For U4, the dispatch refusals follow the script's one-class precedent (exit 2, prose WHY), which works only if the retry-able WHYs are distinct and named; today the lock refusal's WHY also covers a permanent cause (Finding 2). Finding 3 is a plan edit.

## Goal-Alignment Note

The goal is a dispatch interface U4's orchestrator can drive through a loop's life, including restarts and retries. Finding 1 bears directly on that goal (a duplicate loop in one worktree on the honest retry path); Findings 2 and 3 are what U4 needs to read the interface correctly (which refusals to retry, and which document is the contract). None blocks the start path.
