Commit: e02d056b

# Security Review — feat/build-loop-u2b1b, final confirming pass (full branch)

**Scope:** `git diff main...HEAD` (cc9b69d3, 809df345, a382a3f8, e02d056b): `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh` (two comment edits), `test/scripts/build-loop-check.bats`; read for context: `pathform`, `writable`, `isstart`, `truthrule`, `main_entry`, `brief_fields`, `check_brief`, `check_branch`, `open_shared`, `resolve_main`, `nul_list`, `lower_all` (lib)
**Date:** 2026-10-08
**Based on:** Stage 1 fact-check summary (k=3, e02d056b: suites pass, every carried fix's mutant fails its test); iteration 1-2 rubric `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1b.md`; override-log rows 509-520
**Probes:** `scratchpad/u2b1b-i3/sec/p1.sh` (fixture repo under the scratch dir; `set -eu`, mktemp in-script, pwd check before `git init`)

## Trust Boundary Map

```
B1: [loop-written branch tip TIP: commits, trees, blob ids (S1)] → [merge_result: merge-base, cat-file -e, merge-tree in GATE_TMP's repo] → [TREE, the merge the verdict names]
B2: [changed paths/modes/blob ids from diff-tree -z in the gate repo (S1)] → [regex parse, blob presence batch-check, pathform, mode rule, own-brief rule, lower_all + truthrule words + briefs/cycles prefix] → [DENY rows and the ok / K-of-N verdict the orchestrator trusts]
B3: [main's copy of the brief (S2)] → [own_blob: first Status: line open→done, hash-object --no-filters in the gate repo] → [the one blob id the own brief may take]
B4: [repo-local state: config, config.worktree, info/attributes, grafts, shallow, refs/replace, origin/HEAD, refs/heads/{main,master} (S3)] → [state_gate (before resolve_main), default_gate (after)] → [MAIN / MAIN_SHA as the trusted base]
B5: [environment and system/global config (S4)] → [harden's GIT_CONFIG_COUNT pairs, GIT_CONFIG_GLOBAL=/dev/null, GIT_CONFIG_NOSYSTEM=1 (new), GATE_ENV's env -u of --local-env-vars] → [every gate git call]
```

| Label | Source | Mutability | Trust (per sink) |
|---|---|---|---|
| S1 | branch tip objects and everything diff-tree derives from them | loop-written | UNTRUSTED toward the merge verdict, path classification, object presence |
| S2 | main's brief blob | on main (reviewed) | trusted for content; its read's status untrusted toward the equality sink (fixed iteration 1) |
| S3 | repo-local git state and refs | runtime-mutable by any same-uid process | UNTRUSTED toward "which commit is main" and toward any git call that reads it; refused by B4 before objects are read |
| S4 | caller environment (GIT_CONFIG_PARAMETERS, TMPDIR, GIT_ATTR_SOURCE) | caller-set | trusted by design (`build-loop.sh:185-186`: "The caller's own environment is trusted") |
| S5 | GATE_TMP's files | same-uid writable during the run | Q-103 residual (R8, row 509, decided; code under it unchanged since iteration 1) |

Everything the gate judges enters at B1/B2 from the loop's branch. The branch adds B2 whole (the N rules), routes the diff-tree read into the gate repository (A16), adds GIT_CONFIG_NOSYSTEM at B5 (A17), and closes B1's missing-object read (R6) and B4's ambiguous default branch (R7). No boundary is removed.

## Verification of the carried fixes

**R6 holds.** `merge_result` (`scripts/build-loop.sh:520-530`, read whole):
```
  bases="$(gate_git merge-base --all "$MAIN_SHA" "$1")" || rc=$?
  [[ "$rc" -le 1 ]] || return 2
  # shellcheck disable=SC2086  # one commit id per word
  for b in "$MAIN_SHA" "$1" $bases; do gate_git cat-file -e "$b^{tree}" || return 2; done
  rc=0; out="$(gate_git merge-tree --write-tree --no-messages "$MAIN_SHA" "$1")" || rc=$?
  [[ "$rc" -le 1 && "${out%%$'\n'*}" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]] || return 2
```
`gate_git` (`:510-515`) returns 3 on any stderr, which every caller reads as failure (`rc -le 1` fails for 3). A missing subtree or blob that merge-tree passes by id is caught downstream: diff-tree -r fails on a missing subtree (`:599`), and the batch-check (`:615-618`) refuses a new regular file whose object is absent or not a blob. Stage 1: both R6 guards' double mutant and the missing-blob mutant fail their tests. Honest-path fix; complete.

**R7 holds.** `default_gate` (`:241-251`) refuses both `refs/heads/main` and `refs/heads/master` present, and an origin/HEAD naming anything but `origin/$MAIN`; it runs at `:260` after `main_by_name`, before any brief is read. Traced cases: origin/HEAD→origin/master with only local main (refused: names origin/master, MAIN=main); origin/HEAD→origin/main with only local master (refused); main naming a tree plus master (refused: show-ref --verify sees both refs; the D4 test pins it). `state_gate` (`:230-233`) already refuses origin/HEAD at any third branch, so an `origin/<x>` plus local `<x>` pair cannot satisfy default_gate's equality. Stage 1: R7 mutant fails. Complete.

**A16/A17 hold.** diff-tree runs in the gate repository with `--ignore-submodules=none` (`:599`); `GIT_CONFIG_NOSYSTEM=1` is exported at `:198` before the first git call (`:216`). Every gate call goes through `gate_git`, whose environment is `GATE_ENV` (`:499-505`): every `--local-env-vars` name but `GIT_CONFIG*` and `GIT_NO_REPLACE_OBJECTS` unset (so `GIT_COMMON_DIR`, `GIT_GRAFT_FILE`, `GIT_SHALLOW_FILE`, `GIT_INDEX_FILE`, `GIT_WORK_TREE` cannot point back), `GIT_DIR` at a fresh dir whose config holds only `repositoryformatversion` and `objectformat`, no `info/`, `modules/` or `shallow`, and cwd an empty `work/`. The repo's config, `info/attributes`, checkout `.gitattributes`, `.git/modules/*` and system/global config are therefore not reachable from a gate call (outside R8's race). Stage 1: the A17 and merge-tree-in-real-repo mutants fail their tests.

**Gate git call inventory (the "can any gate git call read repo config" question).** Six calls run through `gate_git`: merge-base (`:522`), cat-file -e (`:525`), merge-tree (`:526`), diff-tree (`:599`), cat-file --batch-check (`:615`), hash-object (`:542`). The one read on the --check path that is not a gate call and touches the merge's inputs is own_blob's `git cat-file blob "$MAIN_SHA:$1"` (`:540`, `:542`) in the real repository: it applies no filter or textconv, reads main's (not the loop's) object, and runs after state_gate refused planted keys; config planted after the state gate is row 494's existing deferral. No finding.

## N-rule bypass enumeration (move #11)

| # | Candidate | Dispatch | Outcome |
|---|---|---|---|
| 1 | Case variant of a cycle file / constraints doc (`Docs/Roadmap.md`, `docs/CONSTRAINTS.md`, `docs/working/Questions.md`) | Tested (T14; traced `:620`, `:565-570`) | denied: lower_all then truthrule cycle/settings/user |
| 2 | Case variant of a parent directory (`DOCS/working/briefs/x.md`, `docs/working/Cycles/n.md`) | Traced | denied: lower-cased path hits the `^docs/working/(briefs|cycles)/` arm `:569` |
| 3 | Rename a cycle file out (or the own brief into closed/) | Tested (T11, T15) | denied: `--no-renames` gives the D side |
| 4 | Own brief: mode change, a second line changed, Status at a fenced line, `dropped`, trailing byte, CRLF kept | Tested (T15) | denied except the exact first-Status open→done, mode kept; CRLF variant passes only with its CR |
| 5 | Own brief at another spelling (case, closed/) | Traced | the exact-match arm `:558` misses; the lower-cased spelling is anybrief → cycle → denied |
| 6 | Another open brief's Status edited by this branch | Tested (T14, `$o`) | denied (cycle) |
| 7 | Symlink, gitlink on either side, type change, gitlink hidden by `submodule.*.ignore=all` in repo config and `.gitmodules` | Tested (T12) | denied: mode regex `:557`; diff-tree in gate repo |
| 8 | `.github/`, `.gitattributes`, non-ASCII, newline, leading `-`, space | Tested (T13) | denied by pathform; printed as `?` unless in NAMECHARS |
| 9 | A cycle file's name used as a **directory** (`docs/roadmap.md/f`, `docs/constraints.md/f`, `docs/dev-cycle.md/f`, `docs/working/questions.md/f`) or `docs/working/cycles` as a **file**, each absent on main | **Executed** (p1.sh dirs) | **passes** — Finding 1 |
| 10 | `docs/roadmap.md.` (trailing dot: one file on NTFS) | Executed on Linux (passes as a distinct path); Windows checkout not tested | Untested bypass candidates |
| 11 | instr/dot words shadowing cycle (`docs/working/briefs/CLAUDE.md`, `docs/working/cycles/.x`) | Tested (iteration 2 P4; T14) | denied via the `*)` arm; invariant stated at `:562-564` and in truthrule's comment |
| 12 | Honest own-brief edit (Status open→done only) | Executed (p1.sh own) | `ok … / path … M <brief>`, exit 0 |

### Untested bypass candidates

- **NTFS trailing dot or space** (`docs/roadmap.md.`, `docs/roadmap.md `): pathform refuses the space; the trailing dot passes and is a distinct path on Linux (executed). On a Windows checkout Git for Windows' path validation is expected to refuse checking such a path out rather than alias it to `docs/roadmap.md`; not tested here (no Windows host). Hostile-loop class.
- **Object sources beyond loose objects** (alternates, packs, multi-pack-index): the gate repo shares the real `objects/` (`:505`). Already routed (row 492, trigger U3; row 511 names alternates, packs and the MIDX). Not re-litigated.

## Findings

#### 1. A cycle file's name taken as a directory (or `docs/working/cycles` as a file) passes the N rules when main lacks it

**Severity:** Low
**Location:** `scripts/build-loop.sh:565-570`; `scripts/lib/dev-cycle-read.sh:204-207`
**Boundary:** B2
**Move:** #11 (enumerate bypasses), #5 (invert the model)
**Confidence:** High (executed)
**Class:** hostile-loop (an honest loop has no reason to create these; reachable by honest error only in a repo that lacks the file)

**Evidence** (code; `nrules` continues to `:572`):
```
    truthrule "$7" || true
    case "$TRUTH_WHY" in
      cycle|settings) DENY="one of the dev cycle's own files" ;;
      user) DENY="the user's constraints doc, which every loop prompt carries" ;;
      *) [[ ! "$7" =~ ^docs/working/(briefs|cycles)/ ]] || DENY="one of the dev cycle's own files" ;;
    esac
```
```
writable() {
  [[ "$1" =~ ^docs/roadmap\.md$|^docs/working/(questions|questions-archive|idea-log)\.md$ \
    || "$1" =~ ^docs/working/cycles/cycle-$DIGIT{4}-$DIGIT{2}-$DIGIT{2}\.md$ ]] || anybrief "$1"
}
```
**Evidence** (executed, p1.sh dirs, a main holding only the brief):
```
ok docs/working/briefs/2026-10-01-x.md bd591020061c55b4cd398de962de295477c71bab aebdd21ff3e7d5dec0a9a742f2b321f73a2f9c2c
path docs/working/briefs/2026-10-01-x.md A docs/constraints.md/f
path docs/working/briefs/2026-10-01-x.md A docs/dev-cycle.md/f
path docs/working/briefs/2026-10-01-x.md A docs/roadmap.md.
path docs/working/briefs/2026-10-01-x.md A docs/roadmap.md/f
path docs/working/briefs/2026-10-01-x.md A docs/working/cycles
path docs/working/briefs/2026-10-01-x.md A docs/working/questions.md/f
```
The cycle-file words are anchored at `$` (a file), and the briefs/cycles arm needs the trailing `/`, so a path that *claims a cycle file's name as a directory*, or `docs/working/cycles` as a regular file, is not denied. When main already holds the file, the branch must delete it to do this and the D side is denied, so the reach is limited to cycle files main lacks. The effect is availability, and it fails closed: a `docs/constraints.md/` tree makes `--settings` print `constraints unreadable` (main_entry `notfile`), so nothing dispatches; a `docs/dev-cycle.md/` tree turns self-merge off; a `docs/roadmap.md/` or `cycles` file blocks the cycle's own later write. No file a loop prompt or the gate reads as truth changes content. Every such path is printed as a `path` line, so a reviewer of the K-of-N output sees it. Rated Low, not Medium: the floor rule needs a security property violated, and here the N rules' protected content (the cycle's own files' bytes) is never written; only their future creation is obstructed, and fail-closed.

**Recommendation:** Optional, before U3's `--merge` makes the verdict land: deny a lower-cased path that has a protected file's name as a proper prefix component (`docs/roadmap.md/`, `docs/dev-cycle.md/`, `docs/constraints.md/`, `docs/working/{questions,questions-archive,idea-log}.md/`) and `docs/working/{briefs,cycles}` itself, or record it as a Won't-Fix row naming the fail-closed effect. Either is acceptable for this advisory unit.

**Legibility-target:** the orchestrator/user reading the override log at U3 (`--merge` turns the advisory ok into a landing), and the next maintainer of `writable`/nrules' prefix arm.

#### 2. (Concurrence, Informational) The A15 test pins only "state gate before main_by_name refuses", not "before resolve_main reads an object"

**Severity:** Informational
**Location:** `test/scripts/build-loop-check.bats:1588` (test); code `scripts/build-loop.sh:256-258`
**Boundary:** B4
**Move:** #3 (error path)
**Confidence:** High (Stage 1 r2 executed the mutant; code order read here)
**Class:** honest-path test gap; no code defect

**Evidence** (code is correctly ordered):
```
# --check refuses planted state before any git call reads an object (resolve_main does).
if [[ "$MODE" == check ]]; then state_gate || exit 2; fi
resolve_main || true
```
Stage 1 r2: a mutant moving `state_gate` just after `resolve_main` passes the A15 test, because resolve_main falls back to the current branch when main's commit is missing. The security weight is small today: the object reads resolve_main makes (`show-ref`, `rev-parse ^{commit}`) run no command under any of the keys STATE_KEYS_RE lists, and the promisor's lazy fetch is already stopped by `GIT_ALLOW_PROTOCOL=none` (`:198`). The test name overstates what it pins; the order itself holds.

**Recommendation:** Rename the test to what it pins, or add a probe that distinguishes the orders (e.g., a planted key plus main present, asserting no line from a resolve_main-dependent check precedes the refusal). Already escalated to the orchestrator by Stage 1.

**Legibility-target:** the orchestrator (Stage 1 escalation) and the next editor of the A15 test.

## Endorsement Claims

- **Claim:** A missing main, tip or merge-base tree, any stderr from a gate git call, or a new regular file whose blob is absent or not a blob makes `--check` refuse the brief (exit 2) rather than print ok.
  **Location:** `scripts/build-loop.sh:510-530`, `:599-618`
  **Evidence:** read-static (executed by Stage 1's mutants and the R6 test)
  **Verified:** read `gate_git`, `merge_result`, `check_line` through `:628`; each failure returns non-zero into the `case "$rc"` at `:592-596` or a `refuse` echo.
  **Not verified:** a corrupt (present but undecodable) blob at an *unchanged* path that merge-tree passes by id and diff-tree does not list.
  **route: code-fact-check**

- **Claim:** Under both policies the brief's own file passes only as an `M` record with equal old and new modes whose new blob id equals main's copy with its first unfenced `Status: open` line rewritten to `Status: done` (CR kept).
  **Location:** `scripts/build-loop.sh:536-543`, `:558-560`
  **Evidence:** executed (p1.sh own: exit 0, one path line) plus read-static
  **Verified:** read own_blob and the nrules arm; executed the honest edit; T15's five deny variants and CRLF variant read.
  **Not verified:** a brief whose first `Status:` line on main is not the one brief_fields read (both use FENCE_AWK + first `^Status:`; drift fails closed per row on own_blob duplication).
  **route: code-fact-check**

- **Claim:** A record with mode other than 000000/100644/100755 on either side (symlink, gitlink, tree-typed entry) is denied, including a gitlink that `submodule.<name>.ignore=all` in repo config and `.gitmodules` would hide from diff-tree in the real repository.
  **Location:** `scripts/build-loop.sh:557`, `:599`
  **Evidence:** read-static (T12 executed by Stage 1)
  **Verified:** the mode regex and diff-tree's flags and repository (`gate_git`).
  **Not verified:** a mode git normalises on write (100664) appearing in an old tree on main — expected denied by the regex, not executed.
  **route: code-fact-check**

- **Claim:** No gate git call (`:522`, `:525`, `:526`, `:542`, `:599`, `:615`) reads the repository's config, config.worktree, info/attributes, checkout `.gitattributes`, `.git/modules/*`, global or system config, absent a writer racing GATE_TMP (R8).
  **Location:** `scripts/build-loop.sh:188-198`, `:497-515`
  **Evidence:** read-static (A17, merge-tree-in-real-repo and R9 mutants executed by Stage 1)
  **Verified:** GATE_ENV construction, gate repo contents, every gate_git call site in the diff.
  **Not verified:** caller-set `GIT_CONFIG_PARAMETERS`/`GIT_ATTR_SOURCE` (S4, trusted by design) and the shared object directory's alternates/MIDX (row 492).
  **route: code-fact-check**

- **Claim:** `--check` exits 2 before reading any brief when both `main` and `master` exist or origin/HEAD names a branch other than the one resolve_main took.
  **Location:** `scripts/build-loop.sh:241-251`, `:260`
  **Evidence:** read-static (R7 mutant executed by Stage 1; D4 test)
  **Verified:** default_gate whole and its call position after `main_by_name`.
  **Not verified:** a `refs/heads/main` that is a symbolic ref to another branch (hostile-loop, the Q-103 "moving main itself" residual).
  **route: code-fact-check**

(No endorsement is made of the cycle-file rule as a whole: Finding 1 and an untested candidate stand against it.)

## Primitive sweep

Primitive: process exec with interpolated arguments (git, perl, awk) in the diff

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `build-loop.sh:500` `git rev-parse --local-env-vars` (unquoted loop) | git's own fixed list | none needed | cleared — names only |
| `build-loop.sh:522` merge-base `$MAIN_SHA "$1"` | S3 (show-ref hash), S1 (check_branch's hex sha) | hex from show-ref/rev-parse; re-read at `:586-588` | cleared |
| `build-loop.sh:525` cat-file -e over unquoted `$bases` | merge-base stdout (S1-derived ids) | gate_git stderr/exit check; words are full ids | cleared — no option-shaped word reachable from git's output |
| `build-loop.sh:526` merge-tree | S3, S1 | as `:522` | cleared |
| `build-loop.sh:540`, `:542` cat-file blob `"$MAIN_SHA:$1"` | S2; `$1` the brief arg | check_brief pathform + anybrief before status_line returns ok | cleared |
| `build-loop.sh:542` perl `-pe` with `N` env | awk `n + 0` (integer) | `[[ "$n" -gt 0 ]]` | cleared — program text constant |
| `build-loop.sh:599` diff-tree `$MAIN_SHA "$tree"` | S3, merge_result's regex-checked id | `:527` hex regex | cleared |
| `build-loop.sh:615` cat-file --batch-check stdin | ids from `:603` hex regex | regex | cleared |
| `build-loop.sh:642` `rm -rf -- "$GATE_TMP"` | mktemp -d (S4 TMPDIR) | `--`; assignment fails under `set -e` before the trap is set | cleared |
| `build-loop.sh:622-627` printed paths | S1 | shown only when every byte is in NAMECHARS, else `?`; output scrubbed | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence | Class |
|---|---------|----------|----------|----------|------------|-------|
| 1 | Cycle-file name as a directory (or `cycles` as a file) passes when main lacks it; fail-closed availability only | Low | B2 | `scripts/build-loop.sh:565-570` | High | hostile-loop |
| 2 | A15 test pins less than its name (concurs with Stage 1) | Informational | B4 | `test/scripts/build-loop-check.bats:1588` | High | honest-path test gap |

## Overall Assessment

On the code paths read and the probes run, no honest-path change gets past the N rules: case variants (of files and of parent directories), renames, mode and type changes (including a gitlink hidden by `ignore=all`), path forms, the own brief's exact open→done rule, other briefs, cycle files and the constraints doc are all denied, and the honest Status-only edit passes. No gate git call reads repo config, attributes, a submodule repository, or global/system config outside R8's decided race. R6 and R7 hold, and their mutants fail their tests (Stage 1). The one new gap (Finding 1) is a hostile-loop shape whose only effect is to obstruct a cycle file main does not yet have, fail-closed and printed in the path lines; it can be fixed in place with a prefix-component rule or recorded as a Won't-Fix row before U3. Nothing here is red or behavioral amber for this advisory unit. Endorsement claims are pending execution verification (routed to code-fact-check); the clean verdict extends only to the paths read.

## Goal-Alignment Note

The user goal is landing U2b1b after a clean review-fix loop. This pass finds no red and no honest-path amber. Finding 1 (Low, hostile-loop) is a disposition decision: fix it now (a few lines in nrules' `*)` arm plus a T14 case) or record a Won't-Fix/Defer row with trigger U3 `--merge`. Finding 2 repeats Stage 1's escalation. Neither needs to block the merge under the plan's honest-path threat scope.
