Commit: f56ba3f5

# Security Review — feat/build-loop-u2b3b1 (U2b3b1, the reader settings), final confirming pass

**Scope:** `git diff main...HEAD` (8ed86432, 1ece139d, f56ba3f5): scripts/lib/dev-cycle-read.sh, scripts/build-loop.sh, scripts/dev-cycle.sh, docs/dev-cycle.md, three bats files
**Date:** 2026-10-09
**Based on:** the Stage 1 merged fact-check (k=3; docs/reviews/code-fact-check-report-build-loop-u2b3b1-final-r{1,2,3}.md) as summarised in the brief
**Role:** security-final. Threat model: main's commit is the trust anchor; loops write any working tree and their own branches; a hostile same-uid loop writing refs or the registry is a Q-103 residual.

## Trust Boundary Map

```
B1: [main's docs/dev-cycle.md "Reader roots:/Reader homes:"] → [main_file + SETTINGS_AWK → reader_settings (exact line, readerform, once)] → [IMPORT_READER_ROOTS/HOMES or IMPORT_READER_WHY]
B2: [shared refs origin/HEAD, main|master]                   → [main_by_name (fails closed since 1ece139d)]                            → [MAIN_SHA read by B1]
B3: [worktree registry (git worktree list), written by container AND host sessions] → [import_readers: rs_m = first record; G8 re-spelling under each caller root] → [IMPORT_ROOTS → IMPORT_AWK projection]
B4: [the host the walk runs on (ROOT_REAL, HOME)]            → [import_readers' leading root and home]                                  → [which spellings of the repository count as readers]
B5: [memo IMPORT_READERS_DONE (refusal cached)]              → [import_targets' memo test + IMPORT_READER_WHY check (new in 1ece139d)] → [roots the parser uses]
```

```
S1: main's reader lines        — deploy-time (merge to main only) — trusted for reader modelling; validated to NAMECHARS before shell/realpath sinks
S2: refs                       — runtime-mutable by loops — UNTRUSTED for choosing the settings commit (redirect case settled: Q-103 residual row)
S3: worktree registry          — runtime-mutable; host sessions and container sessions both register, each in its own spelling — UNTRUSTED for root selection
S4: environment IMPORT_READER_* — request-time — UNTRUSTED; cleared on source, WHY reset by reader_settings
S5: execution host (container vs ~/claude-workflows on the host, Q-121/Q-123) — deploy-time — trusted, but the model must hold on either
```

What enters: main's settings text (S1) chosen through refs (S2), joined with a registry both sides write (S3), evaluated on whichever host runs the walk (S5). The branch assumes the walk always runs in the container: the settings name only host spellings, and G8 re-spells only worktrees registered beneath the walk side's main worktree. Both fail-open findings below are that assumption.

## Findings

#### F1. A walk run on the host drops `@/workspace/...`: main's settings name only the host spelling

**Severity:** Medium
**Location:** `docs/dev-cycle.md:24-35`; `scripts/lib/dev-cycle-read.sh:1026-1032` (where the roots are built)
**Boundary:** B4, B1, B3
**Move:** 5 (invert the model: which readers does it leave out?), 1
**Confidence:** Medium (executed; reachable once a session on the host runs `--check-fix` or the gate, which Q-121/Q-123 describe; no instruction file on main imports an absolute `/workspace` path today)

Evidence (docs/dev-cycle.md:24-26):
```
Reader roots: /home/magfrump/claude-workflows

Reader homes: /home/magfrump
```
Evidence (lib:1026-1031):
```
  [[ ${#rs_w[@]} -eq 0 ]] || rs_m="${rs_w[0]}"
  [[ -z "$IMPORT_READER_ROOTS" ]] || mapfile -t rs_c <<<"$IMPORT_READER_ROOTS"
  rs_r=("$ROOT_REAL" "${rs_w[@]}")
  for rs_cr in "${rs_c[@]}"; do
    [[ -n "$rs_cr" ]] || continue
    rs_r+=("$rs_cr"); for p in "${rs_w[@]}"; do [[ -z "$rs_m" || "$p" != "$rs_m"/* ]] || rs_r+=("$rs_cr${p#"$rs_m"}"); done
```
On the host, git lists the main worktree as `/home/magfrump/claude-workflows`, and ROOT_REAL is the same path. The caller roots name only that path again. Container-registered worktrees appear as `/workspace/.claude/...`, but `/workspace` itself is no root. `@/workspace/docs/x.md` is the spelling plan line 286 calls "the spelling every container session resolves", and a host walk drops it, so the floor and `--check-fix` let docs/x.md through while every container session imports it. U2b3a closed this hole for gate worktrees in the container. The branch now models the host from the container, but the reverse direction is still open. Executed (probe `security-final/p1.sh`: repo at `$T/h/cw` as the host side, `$T/c/cw` as the container spelling, a worktree registered as `$T/c/cw/.claude/wt-k`, main's settings naming `$T/h/cw` only):
```
A (host gate, settings name host only):
ok docs/a.md                                   <- @$T/c/cw/docs/a.md, dropped
skip docs/b.md: an instruction file names it   <- registered worktree spelling, caught
A2 (settings add container spelling):
skip docs/a.md: an instruction file names it ...
skip docs/b.md: an instruction file names it ...
```
This is not a regression, because main had no readers at all. But docs/dev-cycle.md:28 says the lines "name the readers the self-merge floor and `--check-fix` model besides this checkout". On the host, "this checkout" is the host spelling, so the container is not modelled. The plan's U2b3b1 bullet ("homes of sessions the container cannot see") shows the container-only assumption.

**Recommendation:** Name both spellings on main, with no code change (0 code lines): `Reader roots: /home/magfrump/claude-workflows /workspace` and `Reader homes: /home/magfrump /home/node`. import_readers drops the duplicate of ROOT_REAL and of the running home, and the A2 run shows the fix works. Then reword docs/dev-cycle.md:28-31 as "every spelling of the main checkout on the container and the host".

Legibility-target: docs/dev-cycle.md:28-35 and the plan's U2b3b1 sub-bullet ("homes of sessions the container cannot see") should say the lists name every host's spelling, not only the host the container cannot see.

#### F2. G8 re-spells only worktrees registered beneath the walk side's main worktree; worktrees the other side registered are not re-spelled

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:1026-1032`
**Boundary:** B3
**Move:** 5, 11 (bypass of the G8 matcher `"$p" != "$rs_m"/*`)
**Confidence:** Medium (executed; requires a worktree a host session registered, and an import on main into it through the container spelling)

Evidence (lib:1031): `rs_r+=("$rs_cr"); for p in "${rs_w[@]}"; do [[ -z "$rs_m" || "$p" != "$rs_m"/* ]] || rs_r+=("$rs_cr${p#"$rs_m"}"); done`

The matcher maps registered worktrees from rs_m (the walk side's main worktree) to each caller root. Nothing maps the other way. A worktree a host session registers is listed as `/home/magfrump/claude-workflows/.claude/wt-x`, which is not beneath `/workspace`. The container walk therefore never adds `/workspace/.claude/wt-x`, the path a container session reads through the bind mount. An import `@/workspace/.claude/wt-x/docs/n.md` then reads as the dot path `.claude/wt-x/docs/n.md`, not `docs/n.md`. This is the gap override row 533 (G8) recorded, in the opposite direction. Adding `/workspace` to Reader roots (F1) does not close it, because the matcher only tests prefixes against rs_m. Executed (probe `security-final/p2.sh`, gate side `$T/h/cw`, Reader roots `$T/c/cw`, worktree registered as `$T/c/cw/.claude/wt-k`):
```
ok docs/b.md                                  <- @$T/h/cw/.claude/wt-k/docs/b.md, dropped
skip docs/c.md: an instruction file names it  <- @$T/c/cw/.claude/wt-k/docs/c.md, caught
```
**Recommendation:** Re-spell beneath every spelling of the main worktree (rs_m and each caller root) under every other one. For each worktree p and each pair of spellings (a, b) with p beneath a, add `b${p#a}`. That costs about 2 lines, and the unit is at 397. If the cap forbids it, record it as a known exception beside row 533, routed to U2b3b2 (whose C1 seeds read other roots' checkouts anyway).

Legibility-target: the import_readers header (lib:975-979, "beneath each such entry, every registered worktree that lies beneath the main worktree (the first record)") should say "registered in the walk side's spelling".

#### F3. Stale fail-open wording left after 1ece139d (doc only)

**Severity:** Informational
**Location:** `docs/working/plan-build-loop-handoff.md:301` (per the fact-check); lib:794-796
**Boundary:** B2, B3
**Move:** 2 (assumed behaviour in prose)
**Confidence:** High (Stage 1 fact-check, k=3)

Evidence (fact-check, Stale): plan:301 "without main by name ... the lists stay empty" (since 1ece139d both walks fail). Lib:794-796, import_targets' superset comment, lists the roots without the G8 re-spelled worktrees. A reader who trusts the plan would conclude that a missing main fails open, and the code no longer does that. No security impact in code.

**Recommendation:** Correct both while touching docs for F1. Fold "a file the fence reader refuses" into dev-cycle.sh:56-60.

Legibility-target: plan:301; lib:794-796.

## Endorsement Claims

- **Claim:** With no default branch found by name, `--check-fix` answers `skip ...: the reader settings of docs/dev-cycle.md cannot be used (no default branch was found by name...` for each path tested, not `ok`.
  **Location:** `scripts/lib/dev-cycle-read.sh:600-604`, `scripts/dev-cycle.sh:186-194`
  **Evidence:** read-static (plus the bats case at test/scripts/dev-cycle.bats:1420-1423, which the Stage 1 fact-check ran in its 220/220)
  **Verified:** read reader_settings' first branch and check_fix's two walk-failure arms. IMPORT_READER_WHY makes import_readers return 1 at lib:1020 before the registry is read.
  **Not verified:** the same message through build-loop.sh, which exits earlier at line 302 without main by name (so the floor arm is not reached there).
  **route: code-fact-check**

- **Claim:** import_targets returns 1 whenever IMPORT_READER_WHY is set, whether or not a memo is current (the i1 F2 fix).
  **Location:** `scripts/lib/dev-cycle-read.sh:1065`
  **Evidence:** read-static (the fact-check executed it both ways)
  **Verified:** the check sits after the roots/homes choice and before any parser fork.
  **Not verified:** a future U2b3b2 outside-seed caller that sets IMPORT_READER_WHY after a memo was taken (the memo key includes WHY at lib:1007-1008, so the key changes).
  **route: code-fact-check**

- **Claim:** In both probes the settings text reached realpath only as NAMECHARS paths after `--`, and malformed lines produced `readers malformed` rather than a partial list.
  **Location:** `scripts/lib/dev-cycle-read.sh:576-583, 616-635`
  **Evidence:** executed (p1, p2 here; the fact-check's 32-case probe)
  **Verified:** valid lists were taken whole. A malformed list clears both lists at :632.
  **Not verified:** multibyte input to SETTINGS_AWK's tolower/gsub under a non-C caller locale (main_file runs awk under `env LC_ALL=C`, :544).

## Untested bypass candidates

- G8 matcher with a registry first record that is a bare repository directory (no main worktree): not probed. A bare first record has no checkout to alias, so the gap is narrower.
- A worktree registered under a caller-root spelling that differs only by a trailing `/` or a symlinked component (`realpath` folds it later, but the `"$rs_m"/*` prefix test runs on the spelled form): not probed.
- Reader homes on the host direction (`@~/...` resolved under /home/node by container sessions while a host walk uses /home/magfrump): not probed. For `~/../../workspace/...` both homes sit at depth 2, so the result is the same. A deeper home would differ.

## Primitive sweep

Primitive: path construction / realpath / git object read
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `lib:544` git cat-file blob "$MAIN_SHA:$f" | S2, f constant | main_by_name (fails closed) | cleared; redirect is the settled Q-103 row |
| `lib:1031` `"$rs_cr${p#"$rs_m"}"` | S1 + S3 | readerform on S1; one-directional prefix test | F2 (under-models the reverse direction) |
| `lib:1028` `rs_r=("$ROOT_REAL" "${rs_w[@]}")` | S5 + S3 | none needed | F1 (the other host's main spelling is absent unless S1 names it) |
| realpath -mz -- over the roots (import_readers) | S1, S3 | `--`, absolute and not-/ checks | cleared |
| `lib:1065` import_targets refusal | S4 reset, B5 | IMPORT_READER_WHY | cleared (i1 F2 fixed) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | A host-side walk drops `@/workspace/...`; settings name only the host spelling | Medium | B4, B1 | `docs/dev-cycle.md:24-26`, `lib:1028-1031` | Medium |
| 2 | G8 re-spelling is one-directional; worktrees the other side registered are not re-spelled | Low | B3 | `lib:1031` | Medium |
| 3 | Stale wording on the no-main and superset paths | Informational | B2, B3 | `plan:301`, `lib:794-796` | High |

## Overall Assessment

1ece139d closed both i1 fail-opens it took on. With no main found by name, reader_settings now fails closed, and import_targets refuses whenever IMPORT_READER_WHY is set. No new fail-open entered with the fix. What remains is a modelling asymmetry the branch leaves: the reader set is built only from the container's point of view. F1 is fixable with no code change, by naming `/workspace` (and `/home/node`) in main's settings lines. F2 needs about 2 lines, or a recorded exception next to override row 533. Neither is a regression against main, which modelled no host readers. F1 is the most important item, because `@/workspace/docs/x.md` is the exact import U2b3a set out to catch, and it reopens whenever a walk runs on the host. There are no findings on the floor and refusal paths read. The endorsement claims are pending execution verification where marked.

## Goal-Alignment Note

The unit's goal is that both import walks model the host readers that main's docs/dev-cycle.md names. Read narrowly, it meets that goal: the named readers are modelled, and malformed or missing settings fail closed. The user's own motive (Q-121, Q-123: sessions sometimes run on the host) is broader. It means the walk itself may run on the host, and then the container becomes the unseen reader. F1 keeps the goal's spirit, needs no code-line budget, and belongs in this unit. F2 can go either way under the 400-line cap.
