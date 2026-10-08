Commit: ae08688c

# Security Review — feat/build-loop-u2b1a1 (final confirming pass)

**Scope:** `git diff main...HEAD` at ae08688c (open_shared/anybrief, check_branch and marker_kind under a broken config, check_brief's `--no-textconv`)
**Date:** 2026-10-08
**Based on:** Stage 1 code-fact-check r1-r3 (`docs/reviews/code-fact-check-report-build-loop-u2b1a1-r{1,2,3}.md`), as summarised in the shared brief
**Probes:** executed in throwaway repos under `/tmp/secu2b1a1-*` with this branch's scripts and main's scripts (`git archive main`); git 2.39.5.

## Trust Boundary Map

```
B1: loop-written .git config (log.*, gpg.*, grep.*, diff.*) → git log / git grep / rev-list in the reader → --status / --check-brief / --check-branch lines
B2: loop-written object store (loose objects, packs, info/grafts, commit-graph) → git cat-file / git grep / rev-list → open_shared, check_brief, marker_kind
B3: loop-written refs/heads/<branch> and its commits → check_branch, marker_kind → LOOP, SHA, DATE fields
B4: reader stdout lines → orchestrator (collect, dispatch) → docs/working/questions.md, cycle docs (Done list)
```

Input sources:

```
S1: .git/config (common git dir)        — runtime-mutable (any loop, same uid) — UNTRUSTED for exec sinks and for every value it can change
S2: objects, info/grafts, commit-graph  — runtime-mutable (any loop)           — UNTRUSTED for content and parentage; trusted for nothing hash-addressed without re-hashing
S3: branch refs and branch commits      — runtime-mutable (any loop)           — UNTRUSTED (content, message, signature headers)
S4: main's first-parent commits         — written by the orchestrator/gate/user — trusted for which commit main is; their object bytes are S2
S5: environment set by build-loop.sh    — code-constant (GIT_NO_REPLACE_OBJECTS, core.useReplaceRefs=false, GIT_LITERAL_PATHSPECS) — trusted
```

Everything this unit reads comes from S1-S3, which any loop can write. `--status` deliberately has no state gate (that is U2b1a2's `--check`), so its readers must either be robust to planted state or fail closed; the diff moves two reads (marker_kind's message, check_branch's count/date) from misread to fail-closed, and closes one exec sink (textconv), but leaves a sibling exec sink on the same lines (F1).

## Findings

#### F1. Repo-config `gpg.program` still runs in check_brief's and check_branch's `git log`, and its output reaches `--check-brief`'s commit field

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:421-423`, `scripts/lib/dev-cycle-read.sh:448`
**Boundary:** B1, B4
**Move:** 12 (sweep every call site of an engaged primitive), 3
**Confidence:** High on the mechanism (executed); Medium on exposure (depends on the orchestrator running with more privilege than a loop, e.g. on the host per Q-121)
**Legibility-target:** for-author
**New or pre-existing:** pre-existing on main; this unit reduces it (marker_kind's `git log -1 --format=%B` call is gone, and check_branch's new DATE regex stops the injection into `--status`'s DATE field) but leaves it on the very line it hardens for textconv.

**Evidence:**
```
  # --no-textconv: -G greps the diff, and a repo-local textconv driver would run.
  c="$(git log -1 --format=%H --first-parent --diff-merges=first-parent -s --no-textconv -G'^Status: ' "$MAIN_SHA" -- "$a")"
  [[ -n "$c" ]] || c="$(git log -1 --format=%H "$MAIN_SHA" -- "$a")"
```
```
      && d="$(git log -1 --format=%cs "$sha" 2>/dev/null)" && [[ "$d" =~ ^$DIGIT{4}-$DIGIT{2}-$DIGIT{2}$ ]]; then echo "ok $a $sha $n $d"
```

With `log.showSignature=true` and `gpg.program=<loop script>` planted in the shared config, any shown commit carrying a `gpgsig` header makes `git log` run the loop's program in the reader's process. Executed: a loop tip with a crafted `gpgsig` header made `--status` run the program once on this branch (check_branch :448; the line then reads `skip …: its commit count or date could not be read`) versus twice on main (check_branch + marker_kind, with `ok INJECTED-LINE` landing in DATE). A signed Status commit on main made `--status` run it once (check_brief :422) and made `dev-cycle.sh --check-brief` print `ok <brief> done ok INJECTED-LINE` followed by the SHA on a second line: the program's text enters the commit field the dev cycle copies into its Done list (B4). The comment added at :421 names "a repo-local textconv driver would run" as the reason for the flag while the same call still runs a repo-local signature program; `gpg.ssh.program`/`gpg.x509.program` are the same sink.

**Recommendation:** add `--no-show-signature` to the three `git log` calls (:422, :423, :448; git 2.39 accepts it, checked) and validate `c` as a full hex object id (or empty) before echoing, as check_branch now does for `d`. U2b1a2's state gate refuses `gpg.*`/`log.showSignature` only for `--check`; `--status` and the dev-cycle readers need the in-line fix.

#### F2. Forged objects in the shared object store are read as main's content by every reader, including open_shared (a shared branch can go uncounted)

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:467-474` (open_shared), and every main read (check_brief, brief_fields via main_entry)
**Boundary:** B2
**Move:** 1, 11
**Confidence:** High on the mechanism (executed on git's side); the full `--status` path was not run with a forged object
**Legibility-target:** for-orchestrator-synthesis
**New or pre-existing:** pre-existing; architectural, not introduced here. open_shared is output-identical to main's shared_branches (Stage 1).

**Evidence:**
```
  list="$(git grep --no-color -l -E '^Status: open'$'\r''?$' "$MAIN_SHA" -- docs/working/briefs/)" || rc=$?
```

Git does not re-hash objects on ordinary reads. Executed: overwriting the loose object of a committed `Status: open\nBranch: a` blob with a zlib stream for `Status: done\nBranch: b` made `git cat-file blob HEAD:f.md` print the forged text and `git grep -l '^Status: open' HEAD` exit 1 with no warning. So a loop can make one of two open briefs naming the same branch read done (or name another branch), and open_shared no longer lists the branch: the other brief reads `ok` and is collected or dispatched. Row 293's premise ("the unreadable brief skips in its own --status line") does not cover a brief that reads cleanly but wrongly. The same forgery reaches Status, Branch, Policy, settings and D8's answers, and `--main-log` does not see it because main's ref does not move. Packs are forgeable the same way (same uid, files can be replaced).

**Recommendation:** out of this unit's reach; escalate to the plan (F25/F51 rows): the gate's reads of main need an integrity check the uid cannot forge (re-hash each blob read, e.g. `git cat-file blob X | git hash-object --stdin` compared with X, as D6's snippet does for the gate code), or a statement that object-store forgery is accepted as F19-class.

#### F3. `log.follow=true` changes which commit check_brief names

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:422-423`
**Boundary:** B1, B4
**Move:** 2
**Confidence:** High (executed)
**Legibility-target:** for-author
**New or pre-existing:** pre-existing (the line is main's plus `--no-textconv`).

**Evidence:** as F1's first excerpt.

Executed: brief set to done at s2, then moved into `closed/` at s3. `--check-brief` on the closed path names s3 (as the contract says: "a move into closed/, which adds the file whole"); with `log.follow=true` planted it names s2; adding `diff.renames=copies` also gives s2. Both are real main commits that changed the brief's Status, so no property beyond the contract's choice breaks; rated Low, not Medium, for that reason. A loop can still steer the Done list's commit.

**Recommendation:** pass `--no-follow` (accepted by git 2.39, checked) on both calls, alongside F1's flag.

#### F4. Grafts (and, untested, a forged commit-graph) still steer rev-list in check_branch and marker_kind under `--status`

**Severity:** Informational
**Location:** `scripts/build-loop.sh:288`, `:297`; `scripts/lib/dev-cycle-read.sh:447`
**Boundary:** B2, B3
**Move:** 11
**Confidence:** High for grafts (executed); untested for commit-graph
**Legibility-target:** for-orchestrator-synthesis
**New or pre-existing:** pre-existing (main used the same rev-list calls).

**Evidence:**
```
  if ! p="$(git rev-list --parents -n 1 "$1" 2>/dev/null)" || ! msg="$(git cat-file commit "$1" 2>/dev/null | tr -d '\000')"; then
```

`GIT_NO_REPLACE_OBJECTS` does not disable `info/grafts`. Executed: grafting a `handoff: ready` tip to no parent gives `skip …: it has no parent`; grafting it onto main gives `skip …: it changes files`. Both fail closed, and every reachable outcome (e.g. a non-empty commit reading as a marker via a same-tree graft parent) is one the loop could produce by committing an empty marker itself. No cross-loop gain found. Since marker_kind now takes parents from rev-list (graft-aware) and the message from cat-file (graft-blind), the two reads can describe different commits; harmless here, but U2b1a2's state gate list (info/grafts) should also name `objects/info/commit-graph`/`core.commitGraph`, which carries parent data git trusts without reading the object.

**Recommendation:** none for this unit; carry commit-graph to U2b1a2's state gate review.

#### F5. A repo-wide broken config now skips every brief's `--status` line

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:446-450`
**Boundary:** B1, B4
**Move:** 3
**Confidence:** High (the branch's row-307 test, and P1 above)
**Legibility-target:** for-orchestrator-synthesis
**New or pre-existing:** new behaviour, intended by row 307.

**Evidence:**
```
    else echo "skip $a: its commit count or date could not be read"; fi
```

One planted `log.date bogus` (or a gpg.program producing output, F1) turns every brief with a branch into `skip`, so the cycle collects and dispatches nothing. That is fail-closed (no misread reaches a merge or dispatch), and the reason text is a fixed string, so nothing loop-controlled reaches questions.md through it. Noted so the synthesis does not count it as a regression.

## Untested bypass candidates

- open_shared: a forged pack (rather than a loose object), and an `objects/info/alternates` entry supplying a deleted blob: not run; F2's loose-object case shows the class.
- marker_kind / check_branch: a forged `objects/info/commit-graph` giving the tip other parents: not built (file-format effort); listed in F4.
- check_brief: `diff.algorithm`/`diff.indentHeuristic` changing which lines `-G` sees as added or removed: not run; low value since `-G` matches any added or removed `^Status: ` line.

## Endorsement Claims

- **Claim:** check_branch's new DATE check turns a `git log` output carrying extra lines (planted gpg.program text) into a `skip` line instead of passing it into `--status`'s DATE field.
  **Location:** `scripts/lib/dev-cycle-read.sh:447-450`
  **Evidence:** executed
  **Verified:** P1: on main the line read `… working <sha> ok INJECTED-LINE 0`; on ae08688c it read `skip <brief>: Branch: its commit count or date could not be read`.
  **Not verified:** the `--check-branch` caller in the dev-cycle skill when a valid-looking date is printed along with a program that still runs (F1).
  **route: code-fact-check**

- **Claim:** with `--no-textconv`, a textconv driver from `.git/info/attributes`, `diff.external`, `diff.<driver>.command` and `core.fsmonitor` programs did not run during `--status` or `--check-brief` on a brief whose Status line changed in main's history.
  **Location:** `scripts/lib/dev-cycle-read.sh:422`; open_shared's `git grep` at `:467`
  **Evidence:** executed
  **Verified:** P5: all four planted programs, with `*.md diff=x` in `info/attributes`; none appended to the run log; outputs normal.
  **Not verified:** `gpg.program` under `log.showSignature` (runs: F1); signed commits on the fallback call at `:423`.
  **route: code-fact-check**

- **Claim:** marker_kind's message read goes through `git cat-file commit` under build-loop.sh's exported `GIT_NO_REPLACE_OBJECTS=1` and `core.useReplaceRefs=false`, so a replace ref does not change the subject it parses, and under the script's `set -o pipefail` a failed cat-file answers `bad its commit could not be read`.
  **Location:** `scripts/build-loop.sh:117-118`, `:288-290`
  **Evidence:** read-static
  **Verified:** read the exports at :117-118, `set -euo pipefail` at :85, and marker_kind from :281 to :308; it is called only in `kind="$(marker_kind "$sha")"` (:338), which inherits pipefail.
  **Not verified:** grafts and commit-graph, which the env does not disable (F4); forged objects (F2).
  **route: code-fact-check**

- **Claim:** open_shared sets OPEN_SHARED=error, which skips every open brief, when main_by_name fails or git grep exits above 1, and the source-time `OPEN_SHARED=""` assignment means an inherited environment value is not used.
  **Location:** `scripts/lib/dev-cycle-read.sh:461-477`
  **Evidence:** read-static
  **Verified:** read open_shared whole and status_line's two uses (build-loop.sh:326-327).
  **Not verified:** a grep exit of 0/1 over forged or missing objects (F2; row 293).

## Primitive sweep

Primitive: program execution driven by repo config (gpg.program, textconv, diff.external, fsmonitor) through git calls in the diff scope

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:422` git log -G | S1, S4 | `--no-textconv` | F1 (gpg.program runs, executed); textconv cleared (P5) |
| `scripts/lib/dev-cycle-read.sh:423` git log fallback | S1, S2 | none | F1 (same flag set missing; not separately executed) |
| `scripts/lib/dev-cycle-read.sh:447` rev-list --count | S1, S2, S3 | none needed | cleared: rev-list runs no config program; grafts → F4 |
| `scripts/lib/dev-cycle-read.sh:448` git log %cs | S1, S3 | DATE regex (new) | F1 (program runs; output injection now stopped) |
| `scripts/lib/dev-cycle-read.sh:467` git grep (open_shared) | S1, S2 | `--no-color`, no `--textconv` | cleared for exec (P5); content forgery → F2 |
| `scripts/build-loop.sh:288` rev-list --parents, cat-file commit | S2, S3 | GIT_NO_REPLACE_OBJECTS | cleared for exec; grafts → F4 |
| `scripts/build-loop.sh:294` cat-file commit (NUL check) | S2, S3 | as above | cleared |
| `scripts/build-loop.sh:297` rev-parse ^{tree} | S2, S3 | as above | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | gpg.program still runs in check_brief's and check_branch's git log; injects into --check-brief's commit field (pre-existing, reduced here) | Medium | B1, B4 | `dev-cycle-read.sh:421-423, 448` | High |
| 2 | Forged objects read as main's content; open_shared can leave a shared branch uncounted (pre-existing, architectural) | Medium | B2 | `dev-cycle-read.sh:467-474` | High (git side) |
| 3 | log.follow changes check_brief's commit (pre-existing) | Low | B1, B4 | `dev-cycle-read.sh:422-423` | High |
| 4 | Grafts (and, untested, commit-graph) steer rev-list; fails closed (pre-existing) | Informational | B2, B3 | `build-loop.sh:288, 297`; `dev-cycle-read.sh:447` | High |
| 5 | Broken config now skips every brief (new, intended, fail-closed) | Informational | B1, B4 | `dev-cycle-read.sh:446-450` | High |

## Overall Assessment

This unit moves `--status` in the right direction: under planted config the LOOP and DATE reads now fail closed instead of misreading (a `ready` tip no longer reads `working`, and loop-controlled text no longer reaches DATE), and textconv no longer runs. Nothing here is a regression against main. The one thing worth fixing in place is F1: the line the unit hardens against textconv still runs a repo-config `gpg.program` and passes its output into `--check-brief`'s commit field; `--no-show-signature` (plus `--no-follow` for F3) and a hex check on `c` close both. F2 is not this unit's to fix, but it undercuts the premise that reading from main's commit is reading trusted bytes, and the plan should name it before U2b1a2's gate relies on the same reads. No findings within the code paths read rise above Medium; endorsement claims are pending execution verification where marked.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your task names, structured per your skill, with a `Commit: ae08688c` line at the top.
- Answered: yes
- Out of scope: U2b1a2's `--check` and state gate code (only its stated key list was consulted for F1/F4)
- Escalate: F2 (object-store forgery is not covered by any F-row; the gate's reads of main are not hash-verified) to the plan owner; F4's commit-graph item to U2b1a2's state-gate review.
