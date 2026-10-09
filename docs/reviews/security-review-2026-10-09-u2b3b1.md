Commit: 8ed86432

# Security Review — feat/build-loop-u2b3b1 (U2b3b1, the reader settings), iteration 1

**Scope:** `git diff main...HEAD` in /workspace/.claude/wt-build-loop-u2b3b1 (scripts/lib/dev-cycle-read.sh, scripts/build-loop.sh, scripts/dev-cycle.sh, docs/dev-cycle.md, three bats files)
**Date:** 2026-10-09
**Based on:** docs/reviews/code-fact-check-report-build-loop-u2b3b1.md (17 claims, 0 Incorrect; one Stale at lib:771-773)
**Role:** security

## Trust Boundary Map

```
B1: [main's commit: docs/dev-cycle.md "Reader roots:/Reader homes:"] → [main_file + FENCE_AWK + SETTINGS_AWK → reader_settings: exact-line, readerform, dedup] → [IMPORT_READER_ROOTS/HOMES or IMPORT_READER_WHY]
B2: [shared refs: refs/remotes/origin/HEAD, refs/heads/main|master] → [resolve_main / main_by_name (dev-cycle.sh: no state_gate/default_gate)] → [MAIN_SHA, the commit B1 reads]
B3: [worktree registry in the shared common dir (git worktree list)] → [import_readers: first record = main worktree, re-spelled under each caller root (new)] → [IMPORT_ROOTS → IMPORT_AWK projection]
B4: [process environment] → [lib sourcing clears IMPORT_READER_*; reader_settings resets IMPORT_READER_WHY] → [reader lists]
B5: [import_readers memo (IMPORT_READERS_DONE, refusal now cached)] → [import_targets' "memo current?" test] → [roots/homes the parser projects with]
```

Input sources:

```
S1: main's docs/dev-cycle.md reader lines — deploy-time (only a merge to main changes it;
    the floor's truthrule refuses docs/dev-cycle.md at lib:1358) — trusted for reader
    modelling; untrusted-shaped toward shell/realpath/output sinks (it is still file text),
    so it is validated to NAMECHARS before use.
S2: refs/remotes/origin/HEAD and refs/heads/main — runtime-mutable by any process sharing
    the common dir, including a loop using ordinary git (`git remote set-head`,
    `git update-ref`) — UNTRUSTED for selecting the settings commit unless gated
    (build-loop --check gates it; dev-cycle.sh does not).
S3: worktree registry — runtime-mutable by loops (`git worktree add` is ordinary loop
    behaviour; rewriting entries is the Q-103 residual) — UNTRUSTED for root selection;
    an added root only widens the model except for dot paths (lib comment at :990-992).
S4: environment (IMPORT_READER_ROOTS/HOMES/WHY) — request-time — UNTRUSTED; cleared.
S5: working tree docs/dev-cycle.md — loop-writable — UNTRUSTED; not read by reader_settings.
```

What enters: settings text from main (S1), selected via refs (S2), combined with the registry (S3). The diff assumes the commit main_by_name names is the default branch's; build-loop.sh's --check enforces that with state_gate/default_gate, dev-cycle.sh's --check-fix does not.

## Findings

#### F1. --check-fix drops the host readers when origin/HEAD is redirected or main is absent (fail open for the new guarantee)

**Severity:** Medium
**Location:** `scripts/dev-cycle.sh:190-192`, `scripts/lib/dev-cycle-read.sh:606`, `scripts/lib/dev-cycle-read.sh:512-514`
**Boundary:** B2 → B1
**Move:** 1 (trust boundaries, runtime-mutable ⇒ compromise-reachable), 5 (invert the access model)
**Confidence:** Medium (the mechanism is executed below; whether a loop writing refs/remotes/origin/HEAD is in-model or a Q-103 residual is the user's call)

Evidence (dev-cycle.sh:190-192):
```
resolve_main || [[ -n "$CHECK" ]] || { echo "Could not resolve a default branch (tried origin/HEAD, main, master, the current branch)" >&2; exit 1; }
# The reader lists the import walk takes, from main's settings (the lib's caller
# contract item 9); without main found by name they stay empty.
reader_settings
```
Evidence (lib:606): `if ! main_by_name; then READERS_LINE="readers none: no default branch found by name"; return 0; fi`
Evidence (lib:512): `origin_head="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"`

resolve_main takes origin/HEAD's branch first and maps it to `refs/heads/<name>`, with MAIN_BY_NAME=1. build-loop.sh --check refuses an origin/HEAD naming anything but origin/main|master (state_gate) and a mismatched one (default_gate) before reader_settings. dev-cycle.sh runs neither gate, so a loop that points origin/HEAD at its own branch (`git remote set-head origin <loop-branch>` plus the remote-tracking ref) makes reader_settings read the loop branch's docs/dev-cycle.md. With the reader lines dropped there, the tree walk models no host reader. The same happens when main cannot be found by name: reader_settings leaves the lists empty with no IMPORT_READER_WHY, so --check-fix answers instead of failing closed. Executed (probe p2, temp repo, CLAUDE.md importing `@/h/cw/docs/foo.md`, main naming `Reader roots: /h/cw`):
```
baseline: skip docs/foo.md: an instruction file names it after an @ ... file it instead
origin/HEAD->loopb: ok docs/foo.md
settings: readers none: no line starts "Reader roots:" or "Reader homes:"
no main: ok docs/foo.md
```
This is not a regression against main (main had no host readers), but the dev-cycle.sh header now says "The walk also models the host readers the default branch's docs/dev-cycle.md names", and the redirect defeats that claim. The impact is that an instruction-reachable doc gets an in-cycle fix as non-instruction documentation. The floor (build-loop.sh --check) is not affected.

**Recommendation:** For --check-fix, apply the same default-branch checks build-loop.sh --check uses (origin/HEAD naming only origin/main|master, matching MAIN) before reader_settings. Without main found by name, have reader_settings set IMPORT_READER_WHY so the walk fails closed (or document both limits in the dev-cycle.sh header and the Q-103 residual list).

Legibility-target: dev-cycle.sh header --check-fix paragraph (lines 53-59) and the lib's reader_settings comment ("Without main found by name there is no settings source, so the lists stay empty") should name the fail-open consequence for --check-fix.

#### F2. import_targets outside a walk still falls back to ROOT_REAL alone and ignores IMPORT_READER_WHY (latent for U2b3b2)

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:771-773`, `scripts/lib/dev-cycle-read.sh:1064-1069`
**Boundary:** B5
**Move:** 3 (error path)
**Confidence:** Medium

Evidence (lib:1068-1069):
```
  import_readers_key
  [[ -z "$IMPORT_READERS_DONE" || "$IMPORT_READERS_DONE" != "$IMPORT_READERS_KEY" ]] || { roots="$IMPORT_ROOTS"; homes="$IMPORT_HOMES"; }
```
When the memo is current and holds a refusal, roots is empty and the parser fails (fact-check: rc=1, fail closed). When no memo is current, for example a caller that has not run import_readers yet, the parser projects with ROOT_REAL and this process's home only. It never checks IMPORT_READER_WHY, so a refused settings file does not stop it. All three current callers (lib:1203, 1278, 1280) run inside a walk after import_readers (lib:1185, 1235), so this cannot be reached today. The fact-check already marks the comment at :771-773 Stale. U2b3b2's outside-start caller is the consumer to watch.

**Recommendation:** Have import_targets return 1 when IMPORT_READER_WHY is set, whatever the memo holds, and update the :771-773 comment. Alternatively, record in U2b3b2's brief that every new caller must run import_readers first.

Legibility-target: lib:771-773 comment.

#### F3. Re-spelling multiplies loop-creatable roots toward the IMPORT_WORK bound (availability only)

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1029-1037`, comment at `:751-752`
**Boundary:** B3
**Move:** 8 (a million of these)
**Confidence:** Medium

Evidence: `rs_r+=("$rs_cr"); for p in "${rs_w[@]}"; do [[ -z "$rs_m" || "$p" != "$rs_m"/* ]] || rs_r+=("$rs_cr${p#"$rs_m"}"); done`

Each caller root adds one root per worktree registered beneath the main worktree, and a loop can register worktrees with ordinary `git worktree add`. With one alias the ~570-root bound is reached at about half the worktree count it took before. The result fails closed (the floor refuses everything), so the cost is availability, not under-modelling. The comment at :751-752 already notes the doubling.

**Recommendation:** None needed now. If more aliases are named, have the walk refusal's WHY mention the root count so a prune is the obvious remedy.

## Endorsement Claims

- **Claim:** reader_settings rejects every probed malformed or out-of-alphabet form of the reader lines with a malformed verdict (both walks then fail), and never yields a partial list.
  **Location:** `scripts/lib/dev-cycle-read.sh:602-641`
  **Evidence:** executed
  **Verified:** probe p1 via `build-loop.sh --settings` on temp repos. Tab separator, `*` glob, `..`, `/`, `//`, lower-case key, NBSP after the colon, trailing blank, duplicate entry, HTML-comment wrapper, indented line, continuation line, trailing `/`, and `None`: all gave `readers malformed`. CR line endings and EOF-terminated lines were accepted as documented. The lists are cleared when `why` is set (:635).
  **Not verified:** non-ASCII letters that tolower/gsub in the C-locale awk might fold into the key (multibyte case folding in SETTINGS_AWK).
  **route: code-fact-check**

- **Claim:** A malformed settings line on main makes --check-fix answer "the import walk failed" for every path, and neither a working-tree fix nor the environment (IMPORT_READER_WHY=, IMPORT_READER_ROOTS=/x) changes that.
  **Location:** `scripts/dev-cycle.sh:192`, `scripts/lib/dev-cycle-read.sh:600-606, 1025`
  **Evidence:** executed
  **Verified:** probe p3 (three invocations, all `skip ...: the instruction-file import walk failed`).
  **Not verified:** the same refusal through build-loop.sh --check's floor (main walk). The bats suite covers it, but this review did not run it.
  **route: code-fact-check**

- **Claim:** A worktree registered beneath the main worktree is re-spelled under the caller root, so an absolute import spelled through the host alias into that worktree is caught.
  **Location:** `scripts/lib/dev-cycle-read.sh:1029-1037`
  **Evidence:** executed
  **Verified:** probe p3, worktree `.wt/a`, CLAUDE.md importing `@/h/cw/.wt/a/docs/foo.md`, run from that worktree → `skip docs/foo.md: an instruction file names it ...`.
  **Not verified:** a bare-repo layout, where the first porcelain record is the bare directory and not a main worktree.

- **Claim:** Settings text reaches no shell expansion, realpath option position or printed output. Paths pass readerform (NAMECHARS only), are split by `read -ra` (no globbing), and are passed after `realpath -mz --`. WHY strings carry only line numbers and entry indices.
  **Location:** `scripts/lib/dev-cycle-read.sh:579-583, 617-628, 1046`
  **Evidence:** read-static
  **Verified:** read reader_settings, readerform and import_readers end to end.
  **Not verified:** the scrub applied to READERS_LINE on the --settings print path (build-loop.sh:739).

- **Claim:** In build-loop.sh, reader_settings runs before any import walk, and the only gates that run first (state_gate, default_gate) read no instruction files.
  **Location:** `scripts/build-loop.sh:297-305`
  **Evidence:** read-static
  **Verified:** read state_gate (:255-281), default_gate (:283-294) and the call order.
  **Not verified:** whether read_settings itself triggers a walk before the mode dispatch in the --check path.

## Untested bypass candidates

- Registry-planted dot-nested root (S3, Q-103 residual): a loop rewriting a registry entry so that a re-spelled root sits dot-nested inside another root, which "can hide only dot paths" (lib:990-992). Not tested: this is outside the diff's new surface and settled as a residual.
- Unicode letters that C-locale awk `tolower` leaves unchanged but that render like the key. Each would be either ignored (no key match, so no reader is added) or malformed. Not probed.

## Primitive sweep

Primitive: path construction / realpath / git object read
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `lib:544` git cat-file blob "$MAIN_SHA:$f" | S2 (MAIN_SHA), f constant | main_entry, main_by_name | F1 (MAIN_SHA selectable via origin/HEAD in dev-cycle.sh) |
| `lib:1037` `"$rs_cr${p#"$rs_m"}"` | S1 + S3 | readerform on S1; `/`-root check at :1043,1049 | cleared: only widens roots, fail-closed bound (F3) |
| `lib:1046` realpath -mz -- | S1, S3 | `--`, absolute check | cleared |
| `lib:1069` roots fallback | S5 memo state | memo key | F2 |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | --check-fix drops host readers under an origin/HEAD redirect or with no main by name | Medium | B2→B1 | `scripts/dev-cycle.sh:190-192`, `lib:606` | Medium |
| 2 | import_targets' no-memo fallback ignores IMPORT_READER_WHY (latent; U2b3b2) | Low | B5 | `lib:1068-1069`, `lib:771-773` | Medium |
| 3 | Re-spelling multiplies loop-creatable roots toward the work bound | Informational | B3 | `lib:1029-1037` | Medium |

## Overall Assessment

The settings reader is tight. Every malformed form probed fails both walks closed, the settings text reaches no unsafe sink, and the refusal is memoized fail-closed. The floor (build-loop.sh --check) is not affected by anything found here. The one substantive gap is F1: dev-cycle.sh trusts whichever commit main_by_name selects, and it runs neither the state_gate nor the default_gate, so a redirected origin/HEAD, or a missing main, silently removes the host readers from --check-fix. That is fixable in place by reusing build-loop.sh's default-branch checks or by failing closed. There are no findings within the floor code paths read. Endorsement claims are pending execution verification where marked.

## Goal-Alignment Note

The unit's goal is that both import walks model the host readers named on main. F1 shows the --check-fix half holds only while the default branch is selected honestly. That gap is within this unit's scope (H4 carried --check-fix into U2b3b1), not U2b3b2's. F2 belongs with U2b3b2's outside-start caller and should be carried there rather than fixed here.
