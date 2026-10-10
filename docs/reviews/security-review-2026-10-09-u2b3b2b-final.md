Commit: 8f99fcaf

# Security Review — feat/build-loop-u2b3b2b, final confirming pass (main...8f99fcaf)

**Scope:** `git diff main...HEAD -- scripts test`. Read in full in `scripts/lib/dev-cycle-read.sh`: `root_starts`, `with_at`, `outside_seeds`, `outside_proj`, `outside_ok`, `import_outside`, `import_file`, `import_readers`, `import_targets`' header, `nul_list`, `lower_all`, `isstart`, `prompt_bases`, both walks (`imported_names`, `main_imports`), the walk header (lines 717-764) and contract items 1-9.
**Date:** 2026-10-09
**Based on:** shared brief `u2b3b2b-final/shared.md`; merged fact-check `code-fact-check-report-build-loop-u2b3b2b-final.md` (Claim 21 known, not re-reported); my earlier reports `security-review-2026-10-09-u2b3b2b.md` and `-i2.md`.

Probe harness: scratchpad `u2b3b2b-fsec-probe.sh` (P1-P6) and `u2b3b2b-fsec-probe2.sh` (a sparse file). Each sources the branch lib in a throwaway repo under `/tmp/u2b3b2b-fsec-*`, with `HOME` in the temp dir, `CLAUDE_CONFIG_DIR` unset, `IMPORT_MANAGED_DIR=/nonexistent/managed` and `LC_ALL=C`. All temp dirs were removed; no probe process remains.

## Trust Boundary Map

The floor fails open when a walk misses a file a session loads and still reports ok. A failed or stalled walk refuses (fail-closed).

```
B1:         [other reader roots' trees (find -P)]       → [root_starts → isstart(whole path) → with_at / -L → byte skip] → [C1 seeds]
B2:         [config dirs, ancestors (find -L / -H)]     → [isstart / dir rules → with_at / L1 link rule (realpath -m)]  → [config seeds]
B3 (moved): [seed file bytes]                           → [with_at: outside_ok, then grep -lZF @, status 0/1 only]     → [os_at keep-set]
B4:         [seed list]                                 → [walk seed loop: outside_ok, else skipped]                    → [walk queue → IMPORTED / IMPORTED_MAIN]
```

Input sources:

```
S1: other worktrees' files (loop worktrees, main checkout) — request-time — UNTRUSTED toward availability and filter decisions;
      honest content is the fail-open concern (its imports only add refusals)
S2: ~/.claude, $CLAUDE_CONFIG_DIR, IMPORT_MANAGED_DIR, ancestors — runtime-mutable (same uid) — honest content trusted;
      hostile rewrite is a Q-103 residual
S3: CLAUDE_CONFIG_DIR / IMPORT_MANAGED_DIR values — deploy-time for the caller — trusted (relative config dir fails the walk)
```

B3 moved since iteration 2: `with_at` now filters through `outside_ok` before grep reads anything, and any grep status above 1 fails the walk. B4 is unchanged, but this pass shows that it decides the outcome for link seeds (F1).

## Findings

#### F1. A seed that is a dangling link into a reader root is dropped, so its target's repo path is not imported, while the same link reached through an import is projected

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:1287-1290, 1297` (config listings: `find -L ... -type f`, `find -H ... -xtype f`), `:1454` and `:1535` (the walks' seed loops: `outside_ok "$p" ... || continue`); contrast `outside_proj` at `:1199-1209`
**Boundary:** B2, B1, B4
**Move:** 5 (invert the model: what the seed rule does not cover), 11 (bypass of the link rule)
**Confidence:** High on the mechanism (executed). Low to medium on likelihood: it needs an honest dangling link under a config dir or in another worktree whose target a branch then creates or restores.
**Legibility-target:** for-author (the `outside_seeds` header, "reached through a link (import_outside projects its real path)", and the walk header's U2b3b2a final security F1 sentence)

Evidence (code):
```
if [[ ${#fr[@]} -gt 0 ]]; then nul_list fl find -L "${fr[@]}" -type f -iname '*.md' -print0 || return 1; ...
nul_list fl find -H "${tops[@]}" -maxdepth 1 -xtype f -print0 || return 1
p="${f:1}"; outside_ok "$p" && [[ "$seen" != *$'\n'"$p"$'\n'* ]] || continue        # imported_names :1454
p="${f:1}"; [[ -z "${seen[$p]+set}" ]] && outside_ok "$p" || continue               # main_imports :1535
```
Under `find -L`, a dangling link has type `l`, and `-xtype f` under `-H` is false for it, so config listings never see it. A C1 dangling link is listed (`-type l`) and kept (`-L`), but the walks' seed loops then skip it through `outside_ok`, with no projection. An import of the same name goes through `outside_proj`, which projects a rejected // name through `realpath -m` exactly so that "a link into another root's checkout that lacks main's file reads as the repo path" (U2b3b2a final security F1).

Evidence (executed, `u2b3b2b-fsec-probe.sh`):
```
== P1: ~/.claude/rules/r.md is a dangling link to ROOT_REAL/docs/new.md (main lacks it; a branch would add it)
seeds ok (0)
walk: ok
docs/new.md: -          (tree)
walk: ok
docs/new.md: -          (main)
-- control: the same dangling link reached as an import (~/.claude/CLAUDE.md: @~/.claude/rules/r.md)
docs/new.md: imported   (tree, main)
-- control: the target exists (link not dangling)
docs/new.md: imported   (tree, main)
== P2: ~/.claude/CLAUDE.md is a dangling link into another worktree that lacks main's docs/bar.md
seeds ok (0)
docs/bar.md: -          (tree, main)
-- control: the side worktree holds docs/bar.md
docs/bar.md: imported   (tree, main)
== P3: C1 dangling link: another worktree's .claude/rules/r.md -> ROOT_REAL/docs/new.md (absent)
seeds ok (1)
  f/tmp/u2b3b2b-fsec-DMv1/p3side/.claude/rules/r.md
docs/new.md: -          (tree, main)
-- control: target present
docs/new.md: imported   (tree, main)
```
Scenario: the user keeps `~/.claude/rules/r.md -> /workspace/docs/new.md` (or a `CLAUDE.md` link into the main checkout) while the target is absent or the main checkout lags main. A self-merge that adds or changes `docs/new.md` passes the floor, because neither walk names it. Once the main checkout holds the file, every session loads it as a user rule. This is the U2b3b2a F1 class, carried over to seeds, which do not get the projection imports get. It is not a regression against main, which seeded nothing. It is a gap in this unit's own stated rule: seeds "reached through a link" are kept so that their real path is projected.

**Recommendation:** List dangling links too (`find -L ... '(' -type f -o -type l ')'`, and `-xtype l` with `-H` for the top-level files, filtered by `isstart`). Then, in both walks' seed loops, send a seed that `outside_ok` rejects to the same `realpath -m` projection `outside_proj` applies, for example by appending `//$p` to a projection list, rather than `continue`. Add P1 and P3 as tests. If you would rather not fix it, name the case beside A5 in the walk header.

#### F2. Iteration-2 findings N1 and N2: fixed

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1219-1225`
**Boundary:** B3, B1
**Move:** re-run of the iteration-2 probes
**Confidence:** High (executed)
**Legibility-target:** none; this is a status record

Evidence (P4):
```
grep: memory exhausted
walk: failed
docs/bar.md: imported        (tree and main, under ulimit -v 400000)
-- N2 check: CLAUDE.md -> /dev/zero and -> FIFO
walk: ok
docs/bar.md: imported
  (0 s)                      (both)
```
`with_at` reads only paths `outside_ok` admits, and `[ $? -le 1 ]` turns a fatal grep error into a failed walk. A C1 link to a device or a FIFO stays out of grep. The walks' `outside_ok` then skips it with no read. A sparse 20 GiB C1 start (`truncate -s 20G`) cost no measurable time (`u2b3b2b-fsec-probe2.sh`), because grep skips holes. A dense, @-free large regular file is still read whole by grep, where the parent read 4 MiB. That is bounded by disk the loop must actually write, and it is fail-slow, not fail-open.

### Untested bypass candidates

- A file churned between `outside_ok` and grep in `with_at`, made to vanish (status 2: walk fails, fail-closed; an availability lever for a loop) or swapped for a FIFO (the header's named swap stall). Not probed: it is a race of a class the header already names.
- A config tree link to `/` or to a huge tree (`find -L` walks it all). Not probed: the user must create it.
- A wider form of fact-check Claim 21, in which the whole-path and inner-path prompt bases differ while both classes are `p`. Traced statically for a root nested under `ROOT_REAL/.claude/` (this repository's layout): the extra bases are the nested root and its ancestor holding `.claude`, and the parser's join under every root already yields both. I found no wider form, but did not probe it. P5 (a same-bytes nested `CLAUDE.md` with a `../` import) answered `imported` in both walks.

## Endorsement Claims

- **Claim:** `with_at` fails the walk on any grep status above 1 and never opens a path `outside_ok` rejects.
  **Location:** `scripts/lib/dev-cycle-read.sh:1219-1225`
  **Evidence:** executed
  **Verified:** P4 above (ENOMEM gives `walk: failed`; /dev/zero and FIFO links give 0 s and `walk: ok`), and a read of the function. `xargs` returns 123 when a batch exits 1, and `nul_list` requires status 0.
  **Not verified:** grep killed by a signal mid-batch on this commit (the i2 Q3 probe showed `xargs rc=123` on the parent's form).
  **route: code-fact-check**
- **Claim:** The L1 link rule keeps an @-free config seed exactly when its `realpath -m` differs from its path and lies below an `IMPORT_ROOTS` entry, which holds both spelled and real forms of each root.
  **Location:** `scripts/lib/dev-cycle-read.sh:1307-1312`, `import_readers` at `:1096-1104`
  **Evidence:** executed (P6: an @-free rule through a linked dir below no root gives `seeds ok (0)`; P1 control: a live link into ROOT_REAL gives `imported`)
  **Verified:** both directions on one root each.
  **Not verified:** a dangling target (F1), and a root that only a host spelling names.
  **route: code-fact-check**
- Scoped prose: C1 listing never runs git in another root. `root_starts` is `find -P` piped to `instruction_names` (read-static, `:1213`), so the core.fsmonitor exec surface named in the header is not reachable from these seeds.

## Primitive sweep

Primitive: process exec reading seed paths (blocking reads, error-status policy)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `dev-cycle-read.sh:1213` find -P \| instruction_names | S1 | absolute root, pipefail | cleared; dangling links listed (F1 is in the walk loop) |
| `dev-cycle-read.sh:1224` xargs sh -c grep (with_at) | S1, S2 | outside_ok, status 0/1 only | cleared (F2) |
| `dev-cycle-read.sh:1280` python3 -I json | S2 | fixed program, parse failure falls back to the whole cache | cleared (i1 endorsement holds) |
| `dev-cycle-read.sh:1287-1290` find -L | S2 | -type f | F1 (dangling links unlisted); link loops fail closed (named) |
| `dev-cycle-read.sh:1297` find -H -xtype f | S2 | maxdepth 1 | F1 (dangling top-level link unlisted) |
| `dev-cycle-read.sh:1307` xargs realpath -mz | S2 | `--`, count check | cleared |
| `dev-cycle-read.sh:1314` realpath -mz roots | S3 (registry) | count implicit via loop | cleared |
| `dev-cycle-read.sh:1329` lower_all | S1 | nul_list, count check | cleared |
| `dev-cycle-read.sh:1340` xargs sha1sum -z | S1 | outside_ok, non-link, rawfile, count check | cleared (Claim 21's skip condition is the fact-check's) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | Dangling-link seed into a reader root dropped; its target is not imported (imports get `outside_proj`, seeds do not) | Medium | B2, B1, B4 | `dev-cycle-read.sh:1287-1297, 1454, 1535` | High (mechanism) |
| F2 | Iteration-2 N1 and N2 fixed | Informational | B3, B1 | `dev-cycle-read.sh:1219-1225` | High |

## Overall Assessment

The iteration-2 fix closes both earlier findings, as P4 shows. `with_at` now fails closed on grep errors and never reads devices or FIFOs. The C1 listing still runs no git in another root. One fail-open path remains outside the known Claim 21. A seed that is a dangling link into a reader root is never projected (F1). The config listings omit it, and the walks' seed loops skip a C1 one, whereas an import of the same link is projected by `outside_proj` under U2b3b2a's F1 rule. The mechanism is executed. The trigger, an honest dangling user link whose target a branch then creates, is uncommon. The fix is small and in place: list dangling links, and send seeds `outside_ok` rejects through the existing projection. F1 is the one thing to address, or else to name. Within the code paths read there are no other findings. The endorsement claims marked `route: code-fact-check` await execution verification.

## Goal-Alignment Note

- Success criterion (restated verbatim): a markdown report saved at the path your dispatch names, structured per your skill, with a Goal-Alignment Note.
- Answered: yes. The whole branch was reviewed for fail-open paths, hangs and new read/exec surfaces, with probes. N1 and N2 are confirmed fixed. One new Medium (F1) is in the unit's own link-seed rule. It is a seed-side gap of the class U2b3b2a closed for imports, and the fix is small enough to land before this unit, together with the Claim 21 fix.
- Out of scope: review artifacts under `docs/reviews/`; Claim 21 (known); the commit-message wording (Claim 38b).
- Escalate: F1, to the orchestrator: fix it with Claim 21, or name it in the walk header.
