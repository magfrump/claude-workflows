Commit: 4dc84ce4

# Security Review — feat/build-loop-u1c, final confirming pass (iteration 3)

**Scope:** `git diff main...feat/build-loop-u1c` at 4dc84ce4 (scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh header, scripts/dev-cycle.sh comment, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats); focus on fix commit 4dc84ce4 (X1 git grep in shared_branches, A12 task-box fold)
**Date:** 2026-10-05
**Based on:** docs/reviews/code-fact-check-report-build-loop-u1c.md (merged k=3, Stage 1), its escalations to this critic; override-log rows dated 2026-10-05 (196–296)

## Trust Boundary Map

```
B1:       [docs/constraints.md blob on main]          → [FENCE_AWK + CONSTRAINTS_AWK :164-186] → [CONSTRAINTS_LINE "ok N-hard": the planned dispatch condition]
B2:       [brief blobs on main, briefs/ and closed/]  → [git grep :306 → isbrief → brief_fields] → [SHARED_BRANCHES → F31 skip :333]
B3 (new): [git config: repo .git/config (shared with loop worktrees), ~/.gitconfig, caller env]
                                                       → [git grep's own option parsing :306, `|| true`] → [the B2 candidate list]
B4:       [loop branch tip commit]                    → [check_branch, marker_kind :276-296]     → [LOOP field: ready/blocked/stopped/working]
B5:       [--status BRIEF... arguments]               → [check_brief (pathform, isbrief, blocker, main_entry)] → [the queried brief's fields]
```

| Label | Source | Mutability | Trust classification (per sink) |
|---|---|---|---|
| S1 | docs/constraints.md on main | runtime-mutable (any commit landing on main) | UNTRUSTED toward the dispatch-condition sink (count and success-line rule); its text is prompt content, not exec |
| S2 | brief blobs on main | runtime-mutable | UNTRUSTED toward branch-name, policy and F31 sinks |
| S3 | repo `.git/config` | runtime-mutable, writable by any loop (worktrees share `/workspace/.git`, plan line 33) | UNTRUSTED toward any read that decides a guard; the script already treats it so for core.useReplaceRefs (`:107-111`) |
| S4 | `~/.gitconfig` | uid-writable (loops run as the user's uid), and the user's honest config | UNTRUSTED toward guard-deciding reads; an honest value such as `color.ui=always` must not change a guard |
| S5 | caller environment (`GIT_CONFIG_PARAMETERS`, `GIT_CONFIG_COUNT`, `GIT_*_PATHSPECS`) | deploy-time for the orchestrator's process | trusted (rows 276, 280; Q-115) |
| S6 | loop branch tip commit objects | request-time (loop-written) | UNTRUSTED (all sinks) |
| S7 | --status argument paths | orchestrator-supplied | untrusted for path sinks; gated by check_brief |

What crosses: main's committed text (S1, S2) decides the constraints line and the F31 set; loop-written commits (S6) decide the LOOP field; and, new in 4dc84ce4, git's config (S3/S4) now decides whether the F31 candidate list is read at all, because `git grep`'s output format is config-driven and its failure is swallowed. The diff's assumption is that `git grep -l` output is a plain path list whenever it exits; that assumption does not hold under S3/S4.

## Findings

#### 1. F31's shared-branch skip turns off silently under `color.ui`/`color.grep=always` or any `git grep` error, so two open briefs naming one branch both read `ok` (with different policies)

**Severity:** Medium
**Location:** `scripts/build-loop.sh:306` (enclosing `shared_branches()` :301-315, consumed at `status_line()` :318 and :333)
**Boundary:** B3 → B2
**Move:** #3 (error path), #11 (guardrail bypass), #1 (runtime-mutable ⇒ compromise-reachable)
**Confidence:** High (executed)
**Legibility-target:** for-author

**Evidence** (verbatim):
```
   306	  list="$(git grep -l -E '^Status: open'$'\r''?$' "$MAIN_SHA" -- docs/working/briefs/ || true)"
   307	  while IFS= read -r f; do
   308	    f="${f#"$MAIN_SHA":}"
   309	    if ! isbrief "${f/closed\//}" || ! brief_fields "$f"; then continue; fi
```
(excerpt ends :309; enclosing `shared_branches()` continues to :315 — read: the set is built only from names that pass `isbrief`, and `SHARED_BRANCHES=$'\n'` is set unconditionally at :313, so an empty list yields an empty-but-computed set that `status_line` :318 never recomputes.)

With colour forced, `git grep -l` prints `ESC[35mSHA:docs/...` (verified with `od -c`), so the `${f#"$MAIN_SHA":}` strip fails, `isbrief` refuses every name, and the set is empty. When `git grep` exits 128 (a malformed `grep.threads`, `color.ui=bogus`), `|| true` turns the failure into the same empty set; git's `fatal:` goes to stderr, but stdout carries `ok` lines and the exit is 0, which the header (:77) defines as "every line printed". Probe (fixture: two open briefs on main, `Branch: feat/x`, one with `Policy: self-merge`, settings policy self-merge):

| Config | Result |
|---|---|
| default | both `skip …: another open brief … names the same branch` |
| repo `color.ui=always` | `ok …a.md open self-merge feat/x …` and `ok …b.md open review feat/x …` |
| repo `color.grep=always` | same two `ok` lines |
| **global** `~/.gitconfig` `[color] ui = always` (GIT_CONFIG_GLOBAL unset) | same two `ok` lines |
| repo `grep.threads=-1` or `=abc` | `fatal:` on stderr; same two `ok` lines, exit 0 |
| repo `color.ui=bogus` | `fatal:` ×5 on stderr; same two `ok` lines |

Impact: F31 (plan row 146, "covered", T28) exists so that one branch is never dispatched or judged under two briefs. When it turns off, the probe shows the same branch reported under brief a with `self-merge` and under brief b with `review`; whatever the loop leaves on `feat/x` is then eligible for the more permissive policy of whichever brief the orchestrator picks — a policy-laundering path the guard was written to close. Who controls the trigger: (i) the user's own honest global config — `color.ui=always` is a documented, not-rare setting, and this is the "honest path" the plan (line 33) promises to make safe; (ii) any loop, since loops run as the uid and share `/workspace/.git/config`. The trust model in rows 276/280/281 trusts the caller's *environment* (`git -c`, `GIT_CONFIG_COUNT`), not repo or global config files — the script's own comment at :108 treats repo config as hostile for exactly this reason — so those rows do not cover this; the premise differs. Planned `--state` (T42: `core.fsmonitor`, filters, hooks, `refs/replace/`, `info/attributes`) lists no `color.*` or `grep.*` key and does not read `~/.gitconfig` at all, so F51 does not close it either. Not High: F31 needs two open briefs naming one branch on main (itself an authoring slip), and U1c's `--status` is read by a gate that is still planned (U3/U4). Floor rule applies: a named mechanism in a reachable (honest) environment.

**Recommendation:** Pass `--no-color` to this `git grep` (verified: it beats `color.ui`/`color.grep=always`), and replace `|| true` with an explicit exit check — 0 → list, 1 → no open brief, anything else → F31 unknown, so every open brief skips with a WHY (e.g. "open briefs on the default branch could not be compared"). Add a T28 case with `git config color.ui always` and one with `grep.threads=-1` (the suite sets `GIT_CONFIG_GLOBAL=/dev/null`, so neither shape is reachable from today's tests).

#### 2. No other config- or environment-dependent bypass of the git grep was found; one further fail-closed effect noted

**Severity:** Informational
**Location:** `scripts/build-loop.sh:306`, `:112`
**Boundary:** B3
**Move:** #11
**Confidence:** High (executed)
**Legibility-target:** for-orchestrator-synthesis

**Evidence** (verbatim):
```
   112	export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1
```
Every candidate below was run against the two-brief fixture (results in the bypass table). Only `color.ui`, `color.grep` (=always) and any config value that makes `git grep` exit 128 change the F31 set; all are Finding 1. `GIT_GLOB_PATHSPECS=1` or `GIT_ICASE_PATHSPECS=1` from the caller conflict with the exported literal setting, so *every* git read fails and both briefs skip with "the tree of the default branch could not be read" — fail-closed, and caller env is trusted anyway (row 276). A missing blob for an unrelated brief makes `git grep` print `error:` and still exit 0 with the other matches (per-file, row 293's family).

**Recommendation:** None beyond Finding 1.

### Task-box fold at `:175` (Q-112 [1], row 290) — no finding

```
   175	{ s = $0; sub(/^([^a-zA-Z]|\[[ xX]\])*/, "", s); s = tolower(s); gsub(/[^a-z0123456789]/, "", s) }
```
Executed against `--settings` with `- H1: a` / `  success: b` plus one probe line: `- [x]  H2:`, `- [X] h2:`, `# H2:`, four-space-indented `H2:`, `H 2:`, `\H2:`, `[H2](#h):`, `<!-- H2: -->`, BOM-prefixed `H2:` and `H2 x` all read `unreadable` (fail-closed). Still `ok 1-hard`: `- [x ] H2:`, `- [ x] H2:`, `- [y] H2:`, `- (x) H2:`, `x H2:`. Every residue shape puts a letter before the ID — the letter-prefix family row 290 names (`Hard H2:`, `a. H2:`) — and none of them is a GFM task box (GFM accepts only `[ ]`, `[x]`, `[X]`), so they render as literal text. I judge them covered by row 290 under Q-112 [1], not a new shape (agreeing with fact-check r1/r2). `<b>H2</b>:` is refused earlier by FENCE_AWK. The fold's side effect — ordinary lines like `- [x] S3 bucket moved` now read unreadable — is availability only and fails closed.

## Untested bypass candidates

- **`log.showSignature=true` with a GPG-signed marker tip** (`marker_kind` :280, `git log -1 --format=%B`): no gpg in the sandbox. Expected direction is fail-closed (extra lines before the subject read as `working`), not verified.
- **A marker commit with an `encoding` header** (git log re-encodes `%B` to UTF-8): not built. A loop can write an honest `handoff: ready` anyway, so no escalation is apparent; listed for completeness.
- **`core.fsmonitor` / hooks during the tree grep**: not exercised; a tree-ish grep should not touch the index or run hooks, and T42 owns planted state.

## Endorsement Claims

- **Claim:** With repo config `grep.patternType=fixed|perl`, `grep.extendedRegexp=false`, `grep.fullName=true`, `grep.lineNumber=true`, `grep.column=true`, `core.bigFileThreshold=1`, `core.quotePath=true`, `submodule.recurse=true`, `grep.fallbackToNoIndex=true`, `color.grep.filename=red` or `core.attributesFile=/nonexistent`, the two-brief fixture still prints both F31 skips.
  **Location:** `scripts/build-loop.sh:306`
  **Evidence:** executed
  **Verified:** each key set in the fixture's `.git/config` in turn, `--status` run on both briefs, git 2.39.5
  **Not verified:** the same keys set in `~/.gitconfig` or `/etc/gitconfig` (same parser, untested), and newer git versions
  **route: code-fact-check**
- **Claim:** A `diff=x` textconv or a `binary -text` attribute in `.git/info/attributes` for `*.md` leaves the F31 result unchanged (`git grep` without `--textconv` reads raw blobs).
  **Location:** `scripts/build-loop.sh:306`
  **Evidence:** executed
  **Verified:** both attribute files planted, `--status` printed both skips
  **Not verified:** a `.gitattributes` committed on main itself
  **route: code-fact-check**
- **Claim:** Under repo `color.ui=always`, the --status line for a marked branch carries no ESC byte and reads `ready`; among the --status git calls, only the `git grep` at `:306` was colour-sensitive in the probe.
  **Location:** `scripts/build-loop.sh:276-296`, `:336-351`
  **Evidence:** executed
  **Verified:** one-brief fixture with a `handoff: ready` tip, `od -c` of the output line (0 ESC bytes)
  **Not verified:** check_brief's `git log -G` path under `color.diff=always` (its `--format=%H` output was not inspected separately)
  **route: code-fact-check**

## Primitive sweep

Primitive: git subprocess whose output decides a guard (config-sensitive parse)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:306` `git grep -l` | S2 content, S3/S4 config | none against colour or error (`|| true`) | Finding 1 |
| `scripts/build-loop.sh:279` `git rev-list --parents -n 1` | S6 | SHA from show-ref | cleared — plain output under color.ui=always (probe) |
| `scripts/build-loop.sh:280` `git log -1 --format=%B` | S6 | SHA | cleared for colour (probe); signature/encoding listed as untested |
| `scripts/build-loop.sh:282` `git cat-file commit` | S6 | SHA | cleared — plumbing, no colour |
| `scripts/build-loop.sh:285` `git rev-parse --verify` | S6 | SHA | cleared — plumbing |
| `scripts/build-loop.sh:131` `git cat-file blob` (main_file) | S1 | main_entry blob check | cleared — plumbing |
| lib `check_branch` show-ref / rev-list / `log --format=%cs` | S2 branch name | NAMECHARS + check-ref-format | cleared — `ready` line printed plain under color.ui=always; DATE content is row 274 |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | F31 fails open under forced colour (repo or global config) or a git grep error; both briefs print `ok`, one self-merge | Medium | B3→B2 | `scripts/build-loop.sh:306` | High |
| 2 | No other config/env bypass of the git grep; GIT_GLOB/ICASE pathspecs fail closed | Informational | B3 | `scripts/build-loop.sh:306`, `:112` | High |

## Overall Assessment

4dc84ce4's X1 fix trades a per-brief read for one `git grep`, and in doing so moves the F31 guard onto a porcelain output format that the user's or a loop's git config controls, with errors swallowed by `|| true`. The result is a guard that turns off silently in an honest environment (`color.ui=always` in `~/.gitconfig`) and reports two `ok` lines with different policies for one branch. The fix is in place and small: `--no-color` plus an exit-code check that fails closed (every open brief skips) on anything but 0 or 1, with a T28 case for each. This is not covered by rows 276/280/281 (they trust the caller's environment, not config files) or by the planned T42 key list. The task-box fold at `:175` behaves as Q-112 [1] and row 290 describe; its residue is the letter-prefix family. Apart from Finding 1, there are no findings within the code paths read; endorsement claims are pending execution verification.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved at the output path your task names, structured per your skill, with a `Commit: 4dc84ce4` first line.
- Answered: yes — escalation assessed with executed probes, other git-grep bypasses enumerated, task-box fold placed against row 290
- Out of scope: the planned U3/U4 gate's own use of --status; marker encoding/signature shapes (listed as untested)
- Escalate: Finding 1 to the orchestrator for tiering — it is a fail-open of a "covered" F-row, reachable from an honest global config, and no override row covers it; also suggest adding `color.*`/`grep.*` keys and `~/.gitconfig` to U3b's `--state` scope (T42)
- Questions I would have asked: none
- Decisions I made: treated repo and global git config as untrusted (S3/S4), distinct from the caller environment that rows 276/280 trust, following the script's own comment at :107-111; judged the `[x ]`/`[y]`/`(x)` residue as row 290's letter-prefix family
