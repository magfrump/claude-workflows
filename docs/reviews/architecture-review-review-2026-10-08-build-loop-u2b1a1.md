Commit: ae08688c

# Architecture Review: feat/build-loop-u2b1a1 (final confirming pass)

**Scope:** `git diff main...HEAD` (HEAD ae08688c): `scripts/lib/dev-cycle-read.sh`, `scripts/build-loop.sh`, `scripts/dev-cycle.sh` (header only), tests and plan/questions docs read for context
**Date:** 2026-10-08
**Based on:** Stage 1 fact-check replicates `docs/reviews/code-fact-check-report-build-loop-u2b1a1-r{1,2,3}.md` (as summarised in the shared brief); override log rows 273, 298, 307, 323, 387, and rows 493-495 (read from `feat/build-loop-u2b1a` / `feat/build-loop-u2b1a2`)

**Scope check:** in scope. Module structure (brief enumeration moves from `build-loop.sh` into the lib) and public API (new lib exports `open_shared`, `OPEN_SHARED`, `anybrief`; `check_branch`'s output contract gains a skip read by two scripts; `dev-cycle.sh --check-branch`'s documented output changes). Tests and docs changes were read only for context.

**Trust-boundary cross-reference:** the newest `docs/reviews/security-review-*.md` is `security-review-2026-10-02-digest-pass38.md` (another unit, predates this diff). None of the findings below moves a trust-boundary crossing, so no labels are cited.

## Dependency Map

- `scripts/build-loop.sh` and `scripts/dev-cycle.sh` each source `scripts/lib/dev-cycle-read.sh`; the lib knows neither script. That direction is unchanged.
- **Moved:** `shared_branches`/`SHARED_BRANCHES` (build-loop.sh) is now `open_shared`/`OPEN_SHARED` in the lib. It depends on lib internals only: `main_by_name`, `MAIN_SHA`, `anybrief`, `brief_fields` (and through it `main_entry`), `lower`. Its only consumer is `status_line` in build-loop.sh. On U2b1a2, `check_line` reaches it through `status_line`, and the `check` mode primes it once in the main shell.
- **Shared contract changed:** the lib's `check_branch` now prints `skip NAME: its commit count or date could not be read`. Two consumers read it. build-loop.sh's `status_line` turns it into `skip BRIEF: Branch: ...`. dev-cycle.sh passes it through `--check-branch` to the dev-cycle skill, which reads any skip as "shows no work".
- **Stays in the script:** `marker_kind` (build-loop.sh only) now reads the raw commit object with `cat-file` and gets parents from `rev-list --parents`.
- **Hardening:** spread across the script environment (build-loop.sh's `GIT_CONFIG_*` pair, `GIT_NO_REPLACE_OBJECTS`), one per-call flag in the lib (`--no-textconv` in `check_brief`) and per-call failure checks (`check_branch`, `marker_kind`). The process-wide `harden` is U2b1a2's, and one lib `git_harden` is deferred to U3b (row 495).

## Findings

#### F1. `OPEN_SHARED` caches on emptiness alone, not keyed to the main it was computed from, unlike the lib's own cache convention; the header contract does not name it

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:453-477` (open_shared, whole function read); compare `:592-594`, `:966`; header `:25-26`
**Move:** 3 (module boundary), 7 (coupling)
**Confidence:** High
**Legibility-target:** for-author
**Evidence:**
```
OPEN_SHARED=""
open_shared() {
  local f list b rc=0
  local -A count=() BRIEF=()  # a local BRIEF: the caller's stays as it was
  [[ -z "$OPEN_SHARED" ]] || return 0
  if ! main_by_name; then OPEN_SHARED=error; return; fi
```
and the lib's existing cache:
```
IMPORTED=error; IMPORTED_DONE=""; IMPORTED_MAIN=error; IMPORTED_MAIN_DONE=""
import_reset() { IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""; }
...
  IMPORTED_MAIN=error; IMPORTED_MAIN_DONE="$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"
```
and the header: `The caller runs resolve_main once per process (a second call re-reads main)`.

The lib already has a convention for per-process caches. The walk's result is keyed on the inputs it was computed from (`MAIN_SHA $MAIN_BY_NAME $ROOT_REAL`), and `import_reset` is the one documented invalidation (contract item 4). `open_shared` follows neither. Its comment says "once per process, from MAIN_SHA", but nothing ties the cached value to MAIN_SHA. A second `resolve_main`, which the header explicitly allows, would leave a stale list. A call made before `resolve_main` succeeds stores `error` for the rest of the process, so every open brief would skip. Neither case happens today: build-loop.sh runs `resolve_main` once at `:119`, before any mode. But the lib now exports a stateful function whose correctness depends on caller ordering the header does not state. The header block (`:1-77`, "the one statement" of caller duties) does not mention `open_shared`, its once-per-process cache, or "call it in the caller's shell". Today only the function's own comment documents that.

**Recommendation:** Key the cache the way the walk does: keep `OPEN_SHARED_AT="$MAIN_SHA $MAIN_BY_NAME"` and recompute when it differs, which also stops a pre-`resolve_main` `error` from sticking. Alternatively, clear it in `import_reset` or `resolve_main`. Also add one header sentence: `open_shared` reads main's commit, caches per process, and must be called in the caller's shell.

#### F2. `check_branch`'s new skip mixes a process-wide environment fault with a per-name refusal, and the two consumers draw different conclusions from it

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:436-451` (check_branch, whole function read); consumers `scripts/build-loop.sh:330-335` and `skills/dev-cycle/SKILL.md:320-321`
**Move:** 3 (module boundary: shared output contract), 7 (coupling)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis
**Evidence:**
```
    elif n="$(git rev-list --count "$MAIN_SHA..$sha" 2>/dev/null)" && [[ "$n" =~ ^$DIGIT+$ ]] \
      && d="$(git log -1 --format=%cs "$sha" 2>/dev/null)" && [[ "$d" =~ ^$DIGIT{4}-$DIGIT{2}-$DIGIT{2}$ ]]; then echo "ok $a $sha $n $d"
    else echo "skip $a: its commit count or date could not be read"; fi
```
dev-cycle skill: `"Shows no work": --check-branch prints absent, skips the name (recorded), prints a count of 0, ...`

Row 307's fix is right for build-loop.sh: a skip there holds no slot and moves nothing. But `check_branch` is shared, and in dev-cycle.sh's caller a skip means "shows no work". That routes the brief to a `you: judgment` keep-or-drop question. A broken `log.*` (or `grep.patternType`) config fails the date read for every branch, so one environment fault becomes one spurious keep-or-drop question per open brief, which costs the user attention (the binding budget). The cause is that the output vocabulary has one word, `skip`, for two kinds of answer: "this name is refused" (per argument) and "git cannot read anything here" (per process). The skill already has a path for the second kind: "A check that exits non-zero ... is recorded, and the step that needed it stops." Before this change the line was a malformed `ok` (worse), so this is a net improvement. It still leaves the shared contract with one meaning that two callers read in two ways.

**Recommendation:** Treat a failed count or date read on an existing ref as process-level. Either exit non-zero (matching the skill's existing "check that exits non-zero" path), or use a distinct reason that the dev-cycle skill excludes from "shows no work". If neither change is wanted in this unit, add an override row that names the dev-cycle consequence, so the next dev-cycle unit inherits the decision.

#### F3. Fail-closed handling of git's environment is spread over call sites: a per-call `--no-textconv`, per-call read checks, and a raw object parse

**Severity:** Informational (settled: row 495, Defer to U3b; the in-tree pattern is Coupling-class)
**Location:** `scripts/lib/dev-cycle-read.sh:421-423` (check_brief, whole function `:388-424` read), `:446-449`; `scripts/build-loop.sh:281-308` (marker_kind, whole function read)
**Move:** 4 (layering: where hardening lives), 7
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Evidence:**
```
  # --no-textconv: -G greps the diff, and a repo-local textconv driver would run.
  c="$(git log -1 --format=%H --first-parent --diff-merges=first-parent -s --no-textconv -G'^Status: ' "$MAIN_SHA" -- "$a")"
  [[ -n "$c" ]] || c="$(git log -1 --format=%H "$MAIN_SHA" -- "$a")"
```
```
  if ! p="$(git rev-list --parents -n 1 "$1" 2>/dev/null)" || ! msg="$(git cat-file commit "$1" 2>/dev/null | tr -d '\000')"; then
```

This unit protects against repo config in three different ways at three sites. `check_brief` adds a flag at the call. `check_branch` detects failure and skips. `marker_kind` bypasses the formatter by parsing the raw object. Because the lib is shared, the per-call flag protects dev-cycle.sh too. The read checks protect only these reads. Other `git log` calls in the lib and in dev-cycle.sh (`check_brief`'s two log reads, `dev-cycle.sh:252, 255, 295, 424`) remain exposed to the same `log.*` breakage. The fact-check notes that under `log.date bogus`, `check_brief`'s log fails, `--check-brief` exits 128, and inside `--status` the Status commit comes back empty. So each new hazard needs another per-site patch, and the next git call added to the lib has to remember all three. This is the structure row 495 records and defers ("one `git_harden` in the lib for both scripts", trigger U3b's D6 snippet). It is not re-raised as Coupling here.

Record gap: rows 493-495 exist on `feat/build-loop-u2b1a` and `feat/build-loop-u2b1a2`, but not in this branch's `docs/reviews/override-log.md`. If U2b1a1 lands first, as planned, main carries the per-call `--no-textconv` without the row that defers its consolidation until U2b1a2 lands. If U2b1a2 stalls, the deferral exists only on an unmerged branch.

**Recommendation:** No code change in this unit. Either carry row 495 (and 493-494, which describe reads this unit ships) into this branch's override log, or name in the merge message that they land with U2b1a2. When U3b builds `git_harden`, fold `--no-textconv` into it (`diff.*.textconv` refused or neutralised once) and decide whether `check_brief`'s log reads join row 307's skip-on-failure.

#### F4. Two strategies for one invariant (row 307); `marker_kind` reads one commit from two sources

**Severity:** Informational
**Location:** `scripts/build-loop.sh:281-308` (marker_kind, whole function read); `scripts/lib/dev-cycle-read.sh:446-449`
**Move:** 2 (responsibility), 7
**Confidence:** Medium
**Legibility-target:** for-author
**Evidence:**
```
  if [[ "$msg" == *$'\n\n'* ]]; then msg="${msg#*$'\n\n'}"; else msg=""; fi
  read -ra p <<<"$p"; subj="${msg%%$'\n'*}"
  [[ "$subj" == handoff:* ]] || { echo working; return; }
  if [[ "$(git cat-file commit "$1" | tr -cd '\000' | wc -c)" -gt 0 ]]; then echo "bad it holds a NUL byte"; return; fi
```

To answer "a broken config must not misread", `marker_kind` avoids the config (raw `cat-file`) and `check_branch` detects the failure (`git log` + skip). Each choice is defensible: `%cs` in the committer's own zone is awkward to parse in shell, while message text is easy. Still, the reason for the split lives only in the code. Inside `marker_kind`, the parents come from `rev-list --parents`, which follows `info/grafts`, while the message comes from the raw object, which does not. Under a graft, the parent-count and tree-equality checks therefore judge a different commit shape from the one whose message was read. The function also reads the object twice: once with NULs stripped, and once to count them. Grafts are routed to U3b's `--state` (row 273), and U2b1a2's state gate refuses `info/grafts` for `--check`, so this changes nothing today.

**Recommendation:** Optional: take the parents from the same raw header (`parent` lines before the first blank line), so one read answers every question, and add one comment line on why `check_branch` skips rather than bypassing. Otherwise leave as is; row 273 covers the graft case.

## What Looks Good

- **Row 298 closed with the boundary intact:** enumeration moved into the lib, but `git grep` still only narrows the candidates, and every brief is read through `brief_fields`/`main_entry`. The second read path that row 298 objected to is gone, not relocated.
- **Row 323 closed fully:** `anybrief` replaces all three hand-written `isbrief || isclosed` sites, including the one in the moved function, so the lib has one definition of "a brief path".
- **Correct dependency direction:** the moved function depends only on lib internals and knows nothing of build-loop.sh. The script side became simpler: `status_line` just calls `open_shared`, and the lazy-init idiom now lives with its state.
- **Caller state protected:** the `local -A BRIEF=()` shadow keeps `open_shared` from overwriting the caller's `BRIEF`, so the function is safe to call from inside `status_line` between `check_brief` and `brief_fields`.
- **One consumer of the representation:** on U2b1a2, `check_line` reuses `status_line` rather than re-implementing the shared-branch test, so `OPEN_SHARED`'s encoding (newline-delimited lower-case names, or `error`) is matched in one place.
- **Fail-closed, not misread:** `marker_kind`'s failed read now answers `bad`, never `working`, and `check_branch` no longer emits an `ok` line with a missing field. Both now return answers that callers already handle.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | `OPEN_SHARED` cache not keyed to MAIN_SHA (unlike `IMPORTED_MAIN_DONE`); a pre-`resolve_main` `error` sticks; header contract silent | Minor | `scripts/lib/dev-cycle-read.sh:453-477` | High |
| F2 | `check_branch`'s read-failure skip is process-wide but reads as per-name; dev-cycle turns it into a keep-or-drop question per brief | Minor | `scripts/lib/dev-cycle-read.sh:446-449`; `skills/dev-cycle/SKILL.md:320` | Medium |
| F3 | Hardening spread over call sites (per-call `--no-textconv`, per-read skips, raw parse); settled by row 495, but that row is not on this branch | Informational (settled) | `scripts/lib/dev-cycle-read.sh:421-423`; `scripts/build-loop.sh:288` | High |
| F4 | Row 307 met two ways; `marker_kind` takes parents (graft-aware) and message (raw) from two sources and reads the object twice | Informational | `scripts/build-loop.sh:281-308` | Medium |

## Overall Assessment

The unit improves the structure. It closes rows 298 and 323 as their revisit triggers asked, keeps the script → lib dependency direction, and moves stateful enumeration next to the brief reader it depends on, without opening a second read path. No Structural or Coupling finding is new. The one Coupling-class pattern, hardening applied per call site rather than at one seam, is the deferral settled by row 495. That row should travel with this unit or be named in its merge message, because U2b1a1 lands before U2b1a2, which carries it. The most important fix in place is F1. The lib now exports a once-per-process cache that ignores its own precedent of keying on `MAIN_SHA`/`MAIN_BY_NAME` with a documented reset. That is latent today, but cheap to align. F2 is a cross-caller contract question to route rather than block on, since the change already fixed a worse output (an `ok` line missing its date).

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your task names, structured per your skill, with a `Commit: ae08688c` line at the top.
- Answered: yes
- Out of scope: the correctness of `check_brief` under `log.date bogus` (fact-check note; mentioned only as structural context in F3); plan-doc staleness at `docs/working/plan-build-loop-handoff.md:281` (fact-check Stale, U2b1a2's content); U2b1a2's `harden` and state gate themselves.
- Escalate: F2 (does an environment-wide read failure in `check_branch` belong in the dev-cycle skill's "shows no work"?) for the orchestrator to route or settle with an override row; F3's record gap (rows 493-495 are absent from this branch's override log while U2b1a1 lands first).
