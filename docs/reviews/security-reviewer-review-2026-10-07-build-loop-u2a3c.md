Commit: 21b35ebf

# Security Review — feat/build-loop-u2a3c (review-fix loop iteration 2)

**Scope:** `git diff main...HEAD` (main e5d0f838, HEAD 21b35ebf): `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`, A5, plan F11/U2a3c/U2b, new override-log rows
**Date:** 2026-10-07
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2a3c.md` (Commit 21b35ebf, k=1), shared context `u2a3c-i2-shared.md`

Provenance: probes ran in `/tmp/u2a3c-i2-sec-1lHa` (bash 5.2, git 2.39, uid 1000) against copies of the lib at HEAD (`lib-head.sh`), at 27364085 (`lib-273.sh`) and on main (`lib-main.sh`), each in a fresh throwaway repo built by `harness.sh` (hermetic git env, HOME inside the scratch dir). Nothing ran in the worktree except read-only `git show`/`git diff`/`grep`. Note: the worktree held **uncommitted** edits to `docs/working/known-issues-dev-cycle.md` and `docs/working/plan-build-loop-handoff.md` while this pass ran (not mine). This review is of the committed 21b35ebf; those edits were not reviewed.

No HALT patterns matched.

## Trust Boundary Map

```
B1: [checkout files main lacks: untracked/ignored/index-only starts, imported paths, .git/ files (S2,S3)] → [main_checkout ENT MEMO PATH, then capped_read < "$f"]  → [import_targets → IMPORTED_MAIN]   (new)
B2: [main's commit: ls-tree records, 100644/100755 blobs, 120000 link text (S1)]                        → [record regex, git cat-file | capped_read; symlink arm]  → [import_targets / queue]   (moved: blobs now capped)
B3: [parser stdout (S7)]                                                                                 → [import_work: strip "/N" trailer, charge IMPORT_WORK_MAX]  → [IMPORTED_MAIN record, queue/tq]   (new)
B4: [git listings of the checkout (S4, shaped by S5)]                                                    → [checkout_md (any stderr fails), nul_list, lower_all]    → [phase-2 seeds]   (moved)
B5: [IMPORTED_MAIN + IMPORTED_MAIN_DONE cache]                                                           → [caller contract in lib comment / A5 / U2b bullet]       → [U2a4 floor, U2b --check (future callers)]
```

| Label | Source | Mutability | Trust (per sink class) |
|---|---|---|---|
| S1 | main's commit (trees, blobs, link text) | runtime-mutable (anything merged; crafted trees modelled) | UNTRUSTED for walk shape and parse cost; trusted as the authority on what main stores |
| S2 | checkout working-tree files main lacks (untracked, ignored incl. third-party trees such as node_modules, index-only) | request-time (the branch's session writes them) | UNTRUSTED for read, parse and cost sinks |
| S3 | checkout `.git/` contents (`.git/info/*`, config, packs, sockets) | request-time (writable by the session) | UNTRUSTED for read and parse sinks; config also an exec sink for git (U2b) |
| S4 | git binary output (`ls-files`, `ls-tree`, `cat-file`) | runtime | trusted for format only when S5 is clean |
| S5 | git environment and config (`GIT_INDEX_FILE`, `GIT_WORK_TREE`, fsmonitor, replace refs), HOME | deploy-time from the caller (U2b) | UNTRUSTED toward listing completeness until U2b's wrapper; a fail-open source if inherited |
| S6 | `IMPORT_WORK_MAX`, `IMPORT_OUT_MAX`, 4194305 cap | code-constant | trusted |
| S7 | `import_targets` stdout | derived from S1/S2/S3 | UNTRUSTED toward the trailer parse (content-derived names) |

What crosses: phase 2 moves checkout bytes (S2, S3) into the parser for the first time, gated only by `main_checkout`; main's blobs now pass the same 4 MiB cap; the parser's stdout now carries a control line (`/N`) that bash must separate from content-derived names. Every added read can only add names to `IMPORTED_MAIN` (more refusals), and every failure returns 1 with `IMPORTED_MAIN=error`, which `isimported` answers as imported, so the fail-open class is confined to (a) a file a session loads that the walk does not read, (b) bytes read that differ from the session's, and (c) a stale cached answer. I probed each of these and found no fail-open in the code. The one boundary that got weaker is B5, the documented caller contract.

## Findings

#### 1. The caller contract that prevents a stale-cache fail-open was dropped from A5 and the U2b bullet in the rebase, while three settled rows still name those docs as their mitigation

**Severity:** Medium
**Location:** `docs/working/known-issues-dev-cycle.md:18` (A5), `docs/working/plan-build-loop-handoff.md:279` (U2b bullet), `docs/reviews/override-log.md:439-441`; the rule now lives only at `scripts/lib/dev-cycle-read.sh:486-489`
**Boundary:** B5
**Move:** 1 (trace the trust boundaries), 3 (error path / stale state)
**Confidence:** High that the text is absent at 21b35ebf (`git show HEAD:docs/working/known-issues-dev-cycle.md | grep -c IMPORTED_MAIN_DONE` gives `0`; the plan gives `0` for `IMPORTED_MAIN_DONE\|GIT_INDEX_FILE`). Medium on impact: no caller exists until U2a4.
**Legibility-target:** docs

The cache key holds no checkout state (`[[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]]`, lib:790), and phase 2 now reads checkout contents. If a caller walks once and then the checkout gains an import (`CLAUDE.local.md` gains `@t.md`), `isimported main t.md` answers `-` from the stale walk. That is a fail-open, and the HEAD cache test pins it: expected output `- - z.sh`, build-loop-check.bats:338. The settled row (override-log:439) defers this on the strength of "Comment, A5 and the U2b bullet now say the caller clears IMPORTED_MAIN_DONE after any checkout change". The 3e58eb9c resolution kept main's A5/U2b text, so at 21b35ebf only the lib comment says it (fact-check Claims 1-3). The same resolution dropped the U2b bullet's other two obligations: "a git that prints nothing on stderr for `ls-files`" (now enforced by `checkout_md` itself, so moot) and "the git environment the override log hands the caller (`GIT_INDEX_FILE`, `GIT_WORK_TREE`, fsmonitor, sparse checkout, `core.ignoreCase`, replace refs)". That last one matters more now. An inherited `GIT_INDEX_FILE` or an fsmonitor/untracked-cache answer that hides an untracked start makes phase 2 seed nothing for it, with walk ok (override row 387's untested candidate). U2a4 and U2b, the first callers, are planned from A5 and the U2b bullet, not from a lib comment or the override log. The settled row's premise (its mitigation) has changed, which is why this is re-filed.

**Recommendation:** Restore the three items in A5's not-covered list (cache-clear, FIFO start, snapshot/TOCTOU) and the U2b bullet's "owes the walk" clause, git-environment list included, at a commit, or amend rows 439-441 to cite where the rule now lives. An uncommitted working-tree edit seen during this pass appears to restore this text. Re-verify it once committed.

#### 2. The 27364085→HEAD change for an absent path under a checkout directory link can be observed through main's symlink arm (fact-check Claim 32 says it is masked), and no test covers it

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:721-742` (main_checkout ancestor loop), `:826-840` (symlink arm emits one resolved name and no prefix candidates)
**Boundary:** B1, B2
**Move:** 3 (error path), 5 (enumerate what the check does not cover)
**Confidence:** High (executed)

Claim 32 says the `ldir/nx.md` change (2 → 1) "is not observable through the walk, because the link itself (`ldir`) is always a prefix candidate". That holds for `@` tokens. It does not hold for a link main stores, because the symlink arm hands `realpath -ms` output to the loop as a single name. Probe `p1b.sh`: main stores `CLAUDE.md` = `@L` and `L -> ldir/nx.md`; the checkout has untracked `ldir -> realdir` and no `realdir/nx.md`. At 27364085 the result was `walk: ok` with `ldir/x.md: -`. At HEAD it is `walk: failed`, everything imported. The direction is fail-closed. 27364085's answer was also correct here, since a session following `L` finds nothing. So this is a false refusal in an unusual layout, not a security defect. With the target present (`p1.sh`), both versions fail. No HEAD test pins the shape.

**Recommendation:** Correct Claim 32's scope note. Optionally pin `p1b` as a test (`want walk failed`) so the stricter answer is deliberate.

## Endorsement Claims

- **Claim:** A checkout file under the top-level `.git` directory that an import names is read and its imports are recorded, resolved against its own directory.
  **Location:** `scripts/lib/dev-cycle-read.sh:806-857`
  **Evidence:** executed
  **Verified:** `p2.sh`: main's `CLAUDE.md` = `@.git/info/notes.md`, and the checkout's `.git/info/notes.md` = `@secret.md`. Result: `walk: ok`, `.git/info/notes.md: imported`, and `IMPORTED_MAIN` holds `.git/info/secret.md` (the relative name resolves from `.git/info`, as Claude Code's `dirname(importer)` would). `main_checkout` returned 2 for `.git` and `.git/info` and 0 for the file.
  **Not verified:** a linked worktree's gitfile `.git` as an ancestor (`.git/x` → 2 by the plain-file-ancestor rule, read-static only), and `.git/` sockets (`fsmonitor--daemon.ipc`), expected 1 by reasoning.
  **route: code-fact-check**

- **Claim:** In the checkout arm, a file larger than 4194304 bytes is parsed only up to 4194305 bytes (an import past the cap is not recorded), and a file under 4 MiB is parsed whole, matching Claude Code's traced byte-limit skip (`nH=4194304`, `totalBytes>nH` → skipped; U2a3b L2-i2 fact-check Claim 18).
  **Location:** `scripts/lib/dev-cycle-read.sh:703,821`
  **Evidence:** executed
  **Verified:** `p3.sh`: `big.md` (4,194,310 `a` bytes, then `@late.md`) gave `late.md: -`. `exact.md` (4,194,303 bytes ending `@end.md`) gave `end.md: imported`. Walk ok.
  **Not verified:** a file of exactly 4,194,304 or 4,194,305 bytes with the import on its last bytes, and Claude Code versions after 2.1.292.
  **route: code-fact-check**

- **Claim:** `import_work` accepts the parser's trailer only as a whole last line `/N` of digits, and strips nothing else. Since `put` never prints a name starting with `/`, content-derived names are not taken for the trailer.
  **Location:** `scripts/lib/dev-cycle-read.sh:669-678`, `:592-593`
  **Evidence:** read-static, plus the suite test the fact-check executed (Claim 15: `docs/12` → failed, `a.md\nb/12x` → failed, budget 30 → failed at 31)
  **Verified:** read the full function and `put`. Bypass candidates traced: a last name ending `/123` with no trailer (requires a preceding newline or a whole-output match, so it fails), a trailer glued to a name, and an over-budget total. All three return 1.
  **Not verified:** awk implementations other than mawk printing END output after `exit 3` (fact-check Claim 14 covers mawk only). On other awks a missing trailer fails closed.
  **route: code-fact-check**

- **Claim:** Each `return 1` in `main_imports` after line 791 leaves `IMPORTED_MAIN` as `error`. The seeding returns (`:795-807`) precede `IMPORTED_MAIN=$'\n'` (`:815`), and every drain-loop return (`:822-853`) sets `IMPORTED_MAIN=error` first.
  **Location:** `scripts/lib/dev-cycle-read.sh:786-858`
  **Evidence:** read-static
  **Verified:** read the whole function and listed each return.
  **Not verified:** `isimported`'s caller under `set -e` outside `if` (U2a4, not yet written).
  **route: code-fact-check**

- **Claim (scoped, no routing):** `main_checkout`'s `set +u` is scoped by `local -`, declared first on the same `local` line. Inside its scope only `rawfile` and `plaindir` run, and they read `${ROOT_REAL:-}` and `$1`, so an unset variable there makes them answer not-plain, which returns 1. Evidence: read-static (lib:721-742, :103, :106), and fact-check Claim 20 executed the option restore. Not verified: bash < 5.0.

`main_checkout` and `capped_read`'s drain are guardrails with untested bypass candidates (below), so I make no endorsement claim for either.

## Untested bypass candidates

| Guard | Candidate input | Why untested / expected outcome |
|---|---|---|
| `main_checkout` | a checkout directory replaced by a bind mount or other mount (realpath equals the path, so it reads as plain) | not reproducible without privileges. Expected: walked as plain, matching what a session reads, so no fail-open |
| `main_checkout` | an ancestor swapped between its memo entry (`pok`) and the leaf check | TOCTOU, a settled row |
| `main_checkout` | a hard link in the checkout to a file outside the repo | reads its content and only adds names. No disclosure path: nothing prints `IMPORTED_MAIN` yet (`grep` over scripts/skills/hooks found no consumer) |
| `capped_read` drain | gate run where `/proc` is absent or masked (Q-125/Q-127 sandbox): on Linux, bash's `[[ -p /dev/stdin ]]` stats `/dev/stdin` → `/proc/self/fd/0` | `unshare` was refused here. Expected: no drain, so a main blob over 4 MiB plus the pipe buffer makes `git cat-file` exit 141 and the walk fails closed. Draining unconditionally at the blob call site (it is always a pipe) would remove the dependency |
| checkout listing (B4) | `GIT_INDEX_FILE`, fsmonitor or untracked cache hiding an untracked start | settled for U2b (override row 387). It is a fail-open if inherited. See Finding 1 for the lost handoff text |
| `IMPORT_WORK_MAX` | third-party instruction-named files in ignored trees (node_modules `AGENTS.md`/`SKILL.md`) spending the walk-wide bound | fail-closed (the gate refuses), and the walk does not say which file spent the budget. Per-start cost for ignored trees is a settled row; /workspace measured 8,110 (fact-check Claim 33) |

## Primitive sweep

Primitive: file read of a repo path chosen by repo text (path traversal / read sink)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:760` `capped_read < "$f"` (tree walk) | S2 | `inrepo_here` (blocker + `-f`), 4 MiB cap | cleared: unchanged guard; only the reader changed (`head -- "$f"` → redirect) |
| `:821` `capped_read < "$f"` (checkout arm) | S2, S3 | `main_checkout` = 0 (readable plain file, plain searchable ancestors, no main link/gitlink ancestor) | cleared, apart from the untested candidates above. Probes p1/p1b/p2/p3 |
| `:823` `git cat-file blob "$MAIN_SHA:$f" \| capped_read` | S1 | `ent[$f]` ∈ {100644,100755} | cleared: object read, no filesystem path |
| `:828-829` `git cat-file blob` ×2 (symlink arm, uncapped) | S1 | mode 120000 | cleared for security (not parsed; text rejected on newline, NUL, absolute or `..` after a link). The uncapped read is a perf item, escalated by the fact-check |
| `:837` `-L "$p"` probes | S1 link text | `realpath -ms` relative to ROOT_REAL | cleared: stat only, no read |
| `:731-738` `rawfile`/`plaindir` (`realpath -e`) | S2, S3 | none needed (stat/resolve only) | cleared |

Primitive: process exec with repo-derived data: `python3 -I` and `awk` take repo text on stdin and paths through `env` (`:657-667`), unchanged except `IT_WORK`, which comes from S6 arithmetic. Cleared.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | The caller contract (clear the cache after checkout changes; the git-environment handoff) was dropped from A5 and U2b in the rebase, while override rows 439-441 cite them | Medium | B5 | `known-issues-dev-cycle.md:18`, `plan-build-loop-handoff.md:279`, `override-log.md:439-441` | High (absence) / Medium (impact) |
| 2 | The `ldir/nx.md` 2→1 change shows through main's symlink arm (Claim 32 says masked). Fail-closed, untested | Informational | B1, B2 | `dev-cycle-read.sh:721-742,826-840` | High |

## Overall Assessment

I found no fail-open in the code paths read. Every new read (checkout files, `.git/` files, capped blobs) can only add names or fail the walk to `error`. The trailer parse cannot take a content-derived name for its `/N` line. The 4 MiB cap matches Claude Code's traced byte-limit skip at the boundary I probed. The `.git` change and the stricter `main_checkout` answers move toward refusal. The new walk-failure paths (IMPORT_WORK_MAX, a drain skipped without `/proc`) are fail-closed availability costs. The single most important thing to fix is documentation: at 21b35ebf the rule that keeps the cache from failing open is written only in a lib comment, and the docs the first callers will plan from no longer state it, nor the git-environment obligations. Fixing that is a doc commit, not an architectural change. There are no findings within the code paths read. The endorsement claims are pending execution verification, except the three marked executed.

## Goal-Alignment Note

The user's goal is to land U2a3c once its review-fix loop is clean. This pass found no code defect that blocks it. Finding 1 is a doc regression from the rebase resolution that undercuts three settled override rows. It is cheap to fix and appears to be in progress, uncommitted, in the worktree. Finding 2 is a correction to the fact-check's scope note plus an optional test. Neither calls for another code iteration.
