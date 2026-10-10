Commit: 007e867f

# Security Review — feat/build-loop-u2b3b2c (final confirming pass)

**Scope:** `git diff main...HEAD` (main 8e550626, HEAD 007e867f; commits f7e1bea2, 8976fbdf, c69f352f, 007e867f). Read whole in `scripts/lib/dev-cycle-read.sh`: import_readers (IMPORT_OTHER), root_copies, prompt_marks, outside_seeds, config_seeds, c1_seeds, with_at, outside_ok, outside_proj, import_outside, import_file, prompt_bases, prompt_dir, imported_names, main_imports (the 120000 arm included), main_checkout, plus the walk doc block and header items. Tests: the seven U2b3b2c tests and the C1 test in `test/scripts/build-loop-check.bats`.
**Date:** 2026-10-09
**Based on:** code-fact-check replicates r1-r3 at 007e867f (`docs/reviews/code-fact-check-report-build-loop-u2b3b2c-final-r{1,2,3}.md`, as summarized in the orchestrator's shared brief, with its two escalations), and my i1 report `docs/reviews/security-review-2026-10-09-u2b3b2c-i1.md`.

All probes ran in a scratch harness: copies of the lib and `test/lib/build-loop-fixtures.bash`, plus a probe `.bats` built on the suite's `imps`/`want` helpers. Each fixture repo is a throwaway repo under `$BATS_TEST_TMPDIR`. Prototype fixes were applied only to the scratch copy of the lib. Timings over `/workspace` came from read-only walks.

## Trust Boundary Map

```
B1: [other reader root's file tree (a loop's own worktree)] → [root_copies: outside_ok / -L / realpath -m both sides / sha1sum] → [walk queue]
B2: [dangling link (another root's copy, C1 seed, config seed)] → [//PATH queue entry → outside_proj realpath -m → prompt_marks] → [projected repo names, pdir/pext]
B3: [live prompt link (C1 or config seed)] → [import_outside: target bytes with prompt_bases; IMPORT_WHOLE projection of the real path] → [projected repo name, read plain]
B4: [ROOT_REAL checkout (clean at MAIN_SHA, contract item 2)] → [rawfile test + sha1sum] → [byte-equal skip of a copy; C1 skip]
B5: [worktree registry] → [import_readers realpath, -d, dedupe] → [IMPORT_OTHER]
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | another registered worktree's files, links and directory links | runtime-mutable (a loop writes its own worktree at any time) | UNTRUSTED for import-set decisions (path, kind, skip) and for availability |
| S2 | dangling or live prompt links (C1 seeds, config seeds, root_copies' `//` copies) | runtime-mutable | UNTRUSTED for path and kind decisions |
| S3 | ROOT_REAL's file bytes | deploy-time per decision (item 2) | trusted for the byte-equal comparison under item 2 only |
| S4 | worktree registry | runtime-mutable (Q-103 residual) | UNTRUSTED for root completeness (unchanged here) |
| S5 | parser output names (repo-relative, `//`) | derived from S1/S3 text | UNTRUSTED for path construction; repo-relative join only |

**What crosses.** Whether a name is protected now depends on three decisions:
- **The copy filter (B1).** The pair `outside_ok` / `-L` decides which copies are read. A copy that is neither readable nor a final-component link is dropped.
- **The prompt kind of a dangling projection (B2).** prompt_marks marks this kind only when the projected name is popped later.
- **The live-link projection (B3).** It is never marked as a prompt.

Each decision leaves one fail-open edge, all three confirmed by execution (Findings 1-3).

## Findings

#### 1. A dangling prompt link's projected name that the walk has already read is never re-read with the link's bases (escalation r1, confirmed and widened)

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:1308-1316` (prompt_marks), `:1578`, `:1585-1588` (imported_names), `:1706`, `:1715` (main_imports)
**Boundary:** B2
**Move:** 11 (bypass enumeration on prompt_marks), 4 (order of check and use); executed
**Confidence:** High for the mechanism (executed). The exploit is Medium-likelihood: it needs the future-state model U2b3b2b final F1 accepted, where a dangling link's target appears in the link's root.

**Evidence:**
```
    [[ -n "${pm_p[$p]+set}" ]] || pm_p[$p]="$(lower "$p")" || return 1
    pm_x[$p]="${pm_x[$p]:+${pm_x[$p]}$'\n'}$b"
```
```
      if [[ -f "$p" && "$seen" != *$'\n'"$p"$'\n'* ]] && inrepo_here "$p"; then seen+="$p"$'\n'; queue+=("$p"); fi
```
```
      nm+=("$p"); [[ -z "${seen[$p]+set}" ]] || continue
```
(The first excerpt is the body of prompt_marks' read loop, which ends with `done < <(printf '%s\n' "$pm_o")` and `}`. The second is in imported_names' name loop and the third in main_imports' name loop. Both loops go on to root_copies.)

prompt_marks sets `pdir`/`pext` for each projected name. Those marks only take effect when the name is popped *after* the marking. Nothing re-queues a name that `seen` already holds. The override row names this as an exception, but plain layouts reach it, in both walks:

| Probe | Layout | Tree walk | Main walk |
|---|---|---|---|
| PA (the r1 escalation) | AGENTS.md imports `docs/t.md`; side holds a dangling `.claude/commands/k.md -> ../../docs/t.md`; `docs/t.md` holds `@top.md` | `top.md: imported` (the `//` seed pops before `docs/t.md`) | `top.md: -` (phase 1 reads `docs/t.md` plain before phase 2's `//` entry) |
| PB | Same link, but to `docs/CLAUDE.md`, a start | `top.md: -` (starts pop before seeds) | `top.md: -` |
| PG | ROOT_REAL's `.claude/commands/x.md` (a prompt start, `@top2.md`) is already read; side holds a dangling nested `sub/.claude/commands/k.md -> ../../../.claude/commands/x.md` | `sub/top2.md: -` | `sub/top2.md: -` |

PG matters because `pdir` was already set: the name is a prompt here, so only `pext`'s new bases (side/sub, the link's own directory) are lost. The exploit: a self-merge edits `top.md` (or `sub/top2.md`). Once side's link target appears (side merges main), a session in side running `/k` loads it.

**Assessment of the orchestrator's fix shape ("re-queue an already-read name when prompt_marks marks it"):** sufficient, given three conditions:
1. **It runs in both walks.** PB shows the tree walk is affected too, not only the main walk.
2. **It fires on every mark.** It must fire whenever pext grows, which happens on every prompt_marks call, not only when `pdir` is newly set. Otherwise PG stays open.
3. **It re-queues through the normal arms.** In the main walk, a `seen` name goes back on `queue`, so the `case` reads main's blob or the checkout with the new `xs`.

`cmp` does not need resetting. Other roots' copies of the name are not what the link's root loads: that root lacks the file (dangling), or for a live link, import_outside reads that root's bytes itself. Termination holds because each `//` entry pops once.

I prototyped this in the scratch lib:
- prompt_marks appends each marked name to `PM_RQ`.
- After the prompt_marks call, the tree walk runs `[[ "$seen" != *$'\n'"$p"$'\n'* ]] || queue+=("$p")` and the main walk runs `[[ -z "${seen[$p]+set}" ]] || queue+=("$p")` for each.

Results:
- PA, PB and PG all turn `imported` in both walks.
- All 15 `U2b3b2` tests stay green.

After the fix, a re-queued name that main stores as a symlink fails the main walk through the 120000 arm (`[[ ${#xs[@]} -eq 0 ]]`). That is fail-closed, as the walk doc already names.

**Recommendation:** Land the re-queue under conditions 1-3, add PA, PB and PG as tests (red on 007e867f), and drop the "one the walk already read is not read again" exception from the walk doc block (`:756`), prompt_marks' comment (`:1306`) and the override row.

#### 2. A copy below a linked directory whose target lacks the file is dropped, with no projection (escalation r2, confirmed)

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:1280-1281`, `:1266-1267` (root_copies and its comment)
**Boundary:** B1, B2
**Move:** 11, 5 (what the filter does not cover is default-skip); executed
**Confidence:** Medium. It is executed, but the exploit needs another root holding a directory link that its tree differs from main's by, plus the same target-appears model as Finding 1.

**Evidence:**
```
      if outside_ok "$r/$p"; then ps+=("$p"); cs+=("$r/$p")
      elif [[ -L "$r/$p" ]]; then qs+=("/$r/$p"); qn+=("$p"); fi
```
```
# when one fails or lower does. Not covered: a copy below a dangling linked
# directory in that root, which is skipped (A5's class). The cost: about 11 ms
```
(The first excerpt is root_copies' inner loop over roots, closed by `done` twice on the next lines. The second is two lines from its doc comment, which continues with the cost note.)

The fallback tests only the final component (`-L`). A name whose copy is absent behind a linked *ancestor* is dropped silently. Probe PD: AGENTS.md imports `docs/a.md`, main holds `real/a.md`, and side holds `docs -> real` with `real/a.md` absent.

| Variant | Tree walk | Main walk |
|---|---|---|
| Live directory link, target lacks the file | `real/a.md: -` | `real/a.md: -` |
| Dangling directory link (`docs -> real`, `real` absent) | `real/a.md: -` | `real/a.md: -` |
| Control: dangling file link `docs/a.md -> ../real/a.md` | `real/a.md: imported` | `real/a.md: imported` |

The comment names only the dangling-directory case, so the live-directory case is an unnamed fail-open (r2's Mostly accurate). Once side gains `real/a.md`, a session there loads `docs/a.md` through the link as `real/a.md`, which a self-merge could have edited.

The fix is cheap. One batched `realpath -m` over the (root, name) pairs that are neither admitted nor a link closes both rows, and with them root_copies' share of A5. GNU `realpath -m` resolves dangling and live ancestor links alike, and returned normally on a planted `loopd -> loopd` loop (probe PH: walk ok). Queue `//ROOT/NAME` for each pair whose real path differs. I prototyped it on top of Finding 1's prototype (`else ab+=("$r/$p"); an+=("$p"); fi`, then `nul_list rl xargs -0r -a <(printf '%s\0' "${ab[@]}") realpath -mz --`, and a comparison loop):
- PD's first two rows turn `imported`.
- The 15 `U2b3b2` tests stay green.
- Both walks over `/workspace` give the same name count as the branch lib, at 2.4-2.7 s against 2.45-3.77 s (noise dominates).

**Recommendation:** Add the batched realpath fallback and PD as a test, and drop the "dangling linked directory" not-covered sentence. If the skip is kept instead, the comment and the walk doc's named exceptions must name the live-directory case too.

#### 3. A live prompt link's projected repo name is read plain, so the import that ROOT_REAL's bytes at that name resolve against the session is missed (sibling of i1 F1; predates this diff)

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:1198` (import_outside's projection), `:1578`/`:1706` (prompt_marks gated on `//`)
**Boundary:** B3
**Move:** 11; executed
**Confidence:** Medium. It is executed and needs only another root at an older commit of a file main's copy changed. The exposure predates U2b3b2c, but this unit's stated goal is reading a prompt link's projected names as prompts, and that goal covers only the dangling half.

**Evidence:**
```
  if [[ "$r" != "$1" ]]; then b="$(printf '%s\n' "$r" | IMPORT_WHOLE=1 import_targets /)" && import_work b w || return 1; fi
```
```
    outside_proj out work && { [[ "$f" != //* || -z "${pdir[$f]+set}" ]] || prompt_marks pdir pext out "$f"; } || { IMPORTED=error; return 1; }
```
(The first excerpt is from import_outside, which then prints `a`, `b` and the work trailer. The second is from imported_names' read step, followed by the empty-output check and the name loop; main_imports `:1706` is the same.)

In probe PC, main's `docs/t.md` holds `@top.md`, while side (at an older state) holds `docs/t.md` = `old` and a live `.claude/commands/k.md -> ../../docs/t.md`. Both walks answer `top.md: -` and `docs/top.md: imported`. The walk reads the C1 seed `k.md` through import_outside, so side's bytes get the prompt bases. The projected `docs/t.md` is read plain from ROOT_REAL or main, and root_copies reads side's differing copy plain too. ROOT_REAL's bytes are never read with the session's top level.

When side merges main, `/k` loads main's `docs/t.md` as a prompt and resolves `@top.md` at side's top level. A self-merge that edited `top.md` passed the floor. My i1 F1 said a live link's names "are followed". That holds only when the side's bytes equal main's (the i1 P3 fixture).

**Recommendation:** Treat the IMPORT_WHOLE projection of a `pdir` entry the same way as a dangling one. When `f` is absolute, `pdir[$f]` is set and its real path differs, run prompt_marks over the projection's names, which over-marks the target's own imports, an over-refusal only. Use Finding 1's re-queue, and pass prompt_marks the link's spelling, since it strips one `/` from a `//` key. If this is deferred, name it in the walk doc's exceptions and route it to U2c.

#### 4. Another worktree can fail every main walk with one dangling prompt link to a name main stores as a symlink (fail-closed; named)

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1678-1680` (the 120000 arm)
**Boundary:** B2
**Move:** 3, 8; executed
**Confidence:** High

**Evidence:**
```
      120000)  # a symlink: its text names the file read, as one more import
        # A prompt's names resolve against the session, not its target's directory: not modelled.
        [[ ${#xs[@]} -eq 0 ]] || { IMPORTED_MAIN=error; return 1; }
```
(The arm goes on to read and check the link text through `:1702`.)

In probe PE, main stores `docs/l.md -> t.md`, and side plants a dangling `.claude/commands/k.md -> ../../docs/l.md`. The main walk reports `walk: failed`. The walk doc names this exception ("one main stores as a symlink fails the main walk"). It belongs to the accepted fail-closed class: one loop's worktree can hold every self-merge back (i1 security F3). Finding 1's re-queue widens it to names already read, which is still fail-closed. The tree walk answers `docs/t.md: -` here, because its inrepo_here does not follow the link. The gate does not rely on that answer.

**Recommendation:** None beyond keeping the named exception. List it with the other hostile-worktree fail-closed cases if those are ever enumerated for the operator.

## Untested bypass candidates

- A sparse or multi-GB plain copy with ROOT_REAL holding a plain file at the name: sha1sum reads it whole, which stalls the walk (availability only, fail-closed). Not run, to avoid disk and CPU load.
- A copy swapped between `outside_ok` or `-f` and sha1sum, or for a FIFO: this stalls or fails the walk (the documented point-in-time class). Traced, not run.
- A bind-mount alias of ROOT_REAL registered as a worktree: it lands in IMPORT_OTHER and its copies compare equal (an over-read at most). Needs mount privileges, so not run.
- A dangling prompt link whose nested `.claude/` bases come from an upper-case `.CLAUDE` spelling: prompt_bases matches the component `.claude` in the lower-cased path, so it should be read. Not probed.

## Endorsement Claims

- **Claim:** i1 F2 is fixed. A copy with this checkout's bytes, reached through a live directory link in another root, is read and its real path projected.
  **Location:** `scripts/lib/dev-cycle-read.sh:1286-1288`
  **Evidence:** executed
  **Verified:** The test at `build-loop-check.bats:776` is green on 007e867f. root_copies batches realpath over both `ps` and `cs` (`"${rl[n + i]}" == "${cs[i]}"`), so a link anywhere on the copy's path fails the skip.
  **Not verified:** a copy whose path changes from plain to linked between the realpath batch and the sha1sum batch.
  **route: code-fact-check**
- **Claim:** i1 F1 is fixed for a projected name not read before the link's entry pops. The name is read as a prompt with the link's own directory and its prompt bases, nested `.claude/` included.
  **Location:** `scripts/lib/dev-cycle-read.sh:1308-1316`, `:1573`, `:1670`
  **Evidence:** executed
  **Verified:** The test at `build-loop-check.bats:786` is green (`top.md` and `sub/top2.md` imported in both walks), and probe PA's tree walk gives `top.md: imported`.
  **Not verified:** names already read when the entry pops (Finding 1) and live links (Finding 3).
  **route: code-fact-check**
- **Claim:** i1 F3 is fixed. root_copies' realpath and sha1sum run in xargs batches, and a short result fails the walk.
  **Location:** `scripts/lib/dev-cycle-read.sh:1286`, `:1292`
  **Evidence:** read-static
  **Verified:** Both calls go through `nul_list rl xargs -0r -a <(...)` with a count check.
  **Not verified:** an xargs batch split on a list of over 128 KiB in this environment.
- **Claim:** A byte-equal plain copy whose `..` name leaves its root is followed. The skip loses nothing in the case root_copies' comment calls the reason for reading per root.
  **Location:** `scripts/lib/dev-cycle-read.sh:1286-1294`
  **Evidence:** executed
  **Verified:** In probe PF, `docs/CLAUDE.md` holds `@../../o.md` with equal bytes in a worktree two levels deeper. The `o.md` there imports `docs/deep/z.md`, and both walks answer `docs/deep/z.md: imported`.
  **Not verified:** a `~/` name in an equal-bytes copy under a home that only the copy's root has.
  **route: code-fact-check**
- **Claim:** Under contract item 2, C1's skip depends on root_copies. Every ROOT_REAL plain start of the same kind is in the queue that root_copies is first called with (`queue` for the tree walk; `queue` and `tq` for the main walk), and root_copies compares `ROOT/NAME` with the innermost root, which c1_seeds' `ir` names.
  **Location:** `scripts/lib/dev-cycle-read.sh:1447` (c1_seeds skip), `:1567`, `:1663`
  **Evidence:** read-static, plus the C1 test (`build-loop-check.bats:724`) green
  **Verified:** c1_seeds' innermost root `q` is drawn from IMPORT_OTHER, the same list root_copies iterates, so `"$q/$ir"` is the candidate path.
  **Not verified:** the tree walk outside the gate, where a start inrepo_here rejects but rawfile accepts would be skipped by C1 and never compared.
  **route: code-fact-check**
- **Claim:** The outside_seeds split keeps the seed set: config seeds first, then C1, with one newline check over both.
  **Location:** `scripts/lib/dev-cycle-read.sh:1324-1331`
  **Evidence:** executed (fact-check: the same 9 seeds before and after the split over /workspace)
  **Verified:** The skip's dropped `outside_ok` term is implied by with_at's admission of every non-link candidate.
  **Not verified:** a C1 candidate removed between with_at and the skip test, which now joins the seeds where it was skipped before. outside_ok then drops it in the walk loop.

## Primitive sweep

Primitive: path construction plus file read, hash and realpath over paths built from S1, S2 and S5.

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `dev-cycle-read.sh:1280` `outside_ok "$r/$p"` | S4, S5 | `p` not absolute or `//`; `r` newline-free | cleared |
| `:1281` `-L "$r/$p"` → `//` queue | S1 | final-component test only | Finding 2 |
| `:1286` `xargs realpath -mz` over `ps`, `cs` | S1, S5 | `--`, batching, count check | cleared (i1 F2 and F3 fixed) |
| `:1292` `xargs sha1sum -z` | S1, S3 | `--`, batching, count check | cleared; point-in-time (Untested) |
| `:1296` `lower "${qs[i]}"` | S1 | none needed | cleared |
| `:1309` `prompt_bases` on the link path | S2 | whole-component `.claude` match | cleared; Finding 1 for when it applies |
| `:1560` / `:1656` seed `-L "$p"` → `//PATH` | S2 | outside_ok, then `-L` | cleared (dangling); Finding 3 (live) |
| `:1221-1231` outside_proj `realpath -mz` + projection | S1, S2 | newline check, work budget | cleared |
| `:1193-1199` import_outside `realpath -ez`, capped_read, projection | S1, S2 | 4 MiB cap, budget | Finding 3 (projection kind) |
| `:1678-1702` main 120000 arm | S2 via pdir/pext | refuses a prompt symlink | Finding 4 (fail-closed) |
| c1_seeds `rawfile "${ir[i]}"` | S3 | rawfile | cleared under item 2 (Endorsement 5) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Dangling prompt projection not re-read once read (main: PA; both: PB, PG) | Medium | B2 | `dev-cycle-read.sh:1308-1316,1578,1706` | High |
| 2 | Copy below a live or dangling linked directory dropped, no projection | Medium | B1, B2 | `dev-cycle-read.sh:1280-1281` | Medium |
| 3 | Live prompt link's projected name read plain (predates this diff; PC) | Medium | B3 | `dev-cycle-read.sh:1198,1578,1706` | Medium |
| 4 | Dangling prompt link to a main symlink fails every main walk | Informational | B2 | `dev-cycle-read.sh:1678-1680` | High |

## Overall Assessment

The unit's core mechanism is sound within the paths read and probed. Both walks read other roots' copies when bytes differ or the name is absent, and they project dangling copies. My i1 F2, F3 and F4 are fixed, and F1 is fixed for the order its test covers. A failed comparison fails closed, and the C1 skip and the seed split preserve coverage under item 2.

Three Medium fail-open edges remain, each fixable in place:
- **Finding 1, the most important.** prompt_marks' marks are order-dependent. The orchestrator's re-queue fix is sufficient if it covers both walks and fires on every mark, including names `pdir` already holds.
- **Finding 2.** root_copies' fallback ignores linked ancestors. One batched `realpath -m` closes it.
- **Finding 3.** The live-link counterpart of the dangling-prompt projection is missing.

Prototypes of the Finding 1 and 2 fixes pass the 15 `U2b3b2` tests, close their probes, and leave the /workspace name count and timing unchanged within noise. No new fail-closed class was found beyond Finding 4's named one. Outside these findings: no findings within the code paths read; endorsement claims pending execution verification.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to /workspace/.claude/wt-build-loop-u2b3b2c/docs/reviews/security-review-2026-10-09-u2b3b2c-final.md, structured per the security-reviewer skill, with `Commit: 007e867f` as its first line."
- **Answered:**
  - Both escalations were confirmed by execution. Escalation r1 is Finding 1, which reaches the tree walk too and which the fix shape covers under the stated conditions. Escalation r2 is Finding 2, with a validated fix.
  - prompt_marks and pext were examined for the bases, the link's own directory, the re-marking order and the 120000 arm (Findings 1 and 4).
  - root_copies' skip conditions (prompt names, a link on either side, equal bytes; Endorsements 1 and 4) and the C1 skip's reliance on root_copies (Endorsement 5) hold within the paths read.
  - The outside_seeds split is equivalent (Endorsement 6).
  - Fail-closed paths a hostile worktree controls: Finding 4 is the only one, and it is named. A planted link loop does not fail the walks (PH).
  - The i1 fixes are confirmed (Endorsements 1-3).
- **Out of scope:** the comment and test-title drift the fact-check owns (bats :724, :767, :777-778; lib :757-762, :1176-1178, :1208-1211, :1413-1414), except where it is security-relevant (Finding 2's not-covered sentence), and override rows 580-589.
- **Escalate:** none at HALT level. Findings 1-3 are Medium fail-opens for the loop. Finding 3 predates this unit and can be routed to U2c if not fixed here.
- **Decisions:** whether Finding 3 lands in this unit or is named and routed to U2c (orchestrator's call).
