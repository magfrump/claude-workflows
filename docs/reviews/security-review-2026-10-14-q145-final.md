Commit: c4bab9ca

# Security Review — fix/q145-ancestor-vanish (final confirming pass)

**Scope:** `git diff main...HEAD` in worktree `/workspace/.claude/wt-q145` at c4bab9ca (`scripts/lib/dev-cycle-read.sh` `config_seeds` and the new `top_files`; `test/scripts/build-loop-check.bats`; `test/scripts/dev-cycle.bats`; `docs/thoughts/failure-patterns.md`; docs/reviews excluded)
**Date:** 2026-10-14
**Based on:** the final-pass code fact-check (k=3 at 29b807dc, most-severe-wins: 0 code defects; 1 Incorrect on the immutable ba5d2d1d message; comment wording fixed in c4bab9ca); the prior security review `docs/reviews/security-review-2026-10-14-q145.md` (iteration 2, at 0d573a7b); the rubric `docs/reviews/code-review-rubric-2026-10-14-fix-q145-ancestor-vanish.md`; and `docs/reviews/override-log.md` rows 828-833.

Units read in full before filing: `outside_seeds` (:1503-1507), `config_seeds` (:1513-1582), `top_files` (:1593-1596), `nul_list` (:1649), `lower_all` (:1654), `c1_seeds` (:1600-1626, for the sibling find call sites), and both new bats tests (`build-loop-check.bats:724-777`, `:779-788`). Experiments ran against a `git archive HEAD` copy under `/home/node/.claude/jobs/00bcf178/tmp/q145/review/sec-final/` (`p/p1.sh` → `p/p1.log`; `p/bats.log`) on `/usr/bin/find` (GNU findutils 4.9.0). Each ran under `timeout`, and no probe process was left running (checked with `pgrep`).

## Trust Boundary Map

```
B1: [other processes' entries in a top dir (/tmp, ~/.claude, an ancestor's .claude)] → [find -H -maxdepth 1 -ignore_readdir_race inside top_files, three-try chain (:1566, :1594)] → [fl: the walk's top-level seed list]
B2 (moved): [top directory paths (IMPORT_ROOTS ancestors, IMPORT_CONFIGS)]        → [-d at build (:1521, :1525); -d recheck now inside each top_files try (:1595)] → [find start points trusted as directories]
B3: [fl seed list]                                                                 → [lower_all + isstart + with_at + realpath filter (:1567-1581)]                 → [outside_seeds → walks → self-merge floor]
```

B2 is `(moved)`. Since the prior review, the `-d` recheck runs inside `top_files` after each find (b9f1d2d1), not once after the whole chain. A recheck failure is now one failed try, so it can be retried, where before it failed the walk at once. B1 and B3 are as before.

Input-source classification:

```
S1: entries in a top dir (names, types, presence over time)
      — runtime-mutable (every local user for /tmp; same uid for ~/.claude)
      — UNTRUSTED toward completeness of the seed list (an absence lets a merge through);
        no exec/parse sink here (names reach only find output, lower_all, isstart, with_at, realpath)
S2: tops (ancestors of IMPORT_ROOTS below no root; IMPORT_CONFIGS config dirs)
      — runtime-mutable (worktree registry loop-writable; what each path resolves to can change
        under whoever can write its parent)
      — UNTRUSTED toward which directory a path names at listing time; trusted for argv shape
        (absolute paths only: prior review endorsement 2, unchanged by this diff)
S3: retry count (3), find flags, the 2>/dev/null placement
      — code-constant — trusted
```

What enters from outside is the momentary contents of shared directories (S1) and which directory each top path names (S2). The diff assumes two things. First, that a name find read but could not stat holds nothing to load. Second, that one find run plus a `-d` recheck that both succeed is a complete snapshot. The second assumption held in every probe. The first holds against an adversary but not for a benign non-atomic save (Finding 1, acknowledged).

## Status of prior findings (iteration 2, 0d573a7b)

| Prior | Status at c4bab9ca | Basis |
|---|---|---|
| F1 Medium: a delete-and-re-create save is skipped when its gap spans find's stat | **Acknowledged; mechanism unchanged.** Carried below as Finding 1 | Comment `:1559-1564` now names the case; override-log row 828 (Acknowledged, revisit trigger set). Code path identical (`-ignore_readdir_race` still at `:1594`) |
| F2 Info: the retry absorbs any transient error; the comment overstated fail-closed | **Fixed** | `:831-834` now reads "any error that persists across the tries still fails the walk"; `:1555-1559` says transient errors are retried away and their messages dropped |
| F3 Info: hostile churn can fail all three tries (fail-closed DoS) | **Accepted (Won't-Fix), unchanged** | override-log row 829; this pass: 2 of 300 single tries failed under 40-file/40-dir churn (`p1.log` `churn`) |

## Findings

#### 1. A non-atomic rewrite of an existing top-level instruction file is skipped silently when its gap spans find's stat (prior F1, acknowledged)

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:1594`; comment `:1559-1564`
**Boundary:** B1 (feeding B3)
**Move:** 4 (TOCTOU), 3 (error path)
**Confidence:** Low (that it is ever hit; the mechanism is High)
**Legibility-target:** merge reviewer confirming that the residual the fix opens is a recorded decision, not an oversight
**Status:** Acknowledged (override-log row 828); not a new issue

**Evidence:**
```
  local tf_d; nul_list "$1" find -H "${@:2}" -maxdepth 1 -ignore_readdir_race '(' -xtype f -o -xtype l ')' -print0 || return 1
```
```
  # shown). Not covered, as with any directory read: a file renamed in during
  # the listing (readdir leaves a name added mid-read unspecified), or one
  # deleted and re-created there (a non-atomic save), which find may not see, or
  # now skips when the gap spans its stat (i2 security F1); before Q-145 such a
  # gap failed the walk when it was still open at find's stat of the name
  # readdir had returned, and was missed silently when it spanned the readdir.
```

This is unchanged from iteration 2. An unlink-then-create save whose gap catches find's stat of that name is now skipped with exit 0, so the first try is used, no retry runs, and the file is missing from `fl` for that walk. On main the same timing failed the walk. Moving the recheck (b9f1d2d1) does not touch this path, because the recheck tests only the DIR arguments, not entries. An adversary gains nothing from it: anyone who can unlink the file can keep it absent for the whole walk or create it after the merge, and main missed both. The floor rule keeps the severity at Medium. Confidence stays Low, since the window is microseconds to milliseconds on one file that must hold an `@` import.

**Recommendation:** No further action needed for this merge. It is documented in code and in the override log, with a revisit trigger. Dropping `-ignore_readdir_race` and relying on the retry alone remains the way to close it if the trigger ever fires.

#### 2. A try that fails only at the -d recheck prints nothing, so a walk failing that way has no message; the comment says the third try's message is shown

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1595`, `:1566`; comment `:1557-1559`
**Boundary:** B2
**Move:** 3 (error path)
**Confidence:** High (executed)
**Legibility-target:** operator diagnosing a walk that failed; maintainer reading the three-try contract

**Evidence:**
```
  for tf_d in "${@:2}"; do [[ -d "$tf_d" ]] || { local -n tf_a="$1"; tf_a=(); return 1; }; done
```
```
  # walk; a transient one of any kind is retried away when a later try is clean,
  # its message dropped (three in a row fail the walk, the third's message
  # shown). Not covered, as with any directory read: a file renamed in during
```
`p/p1.log` (the three-try chain exactly as `:1566` runs it, tops = a real dir plus a linked top whose target is gone):
```
chain-deadlink: [chain=1] n=0
chain-unreadable: [find: '.../t1/ur': Permission denied
chain=1] n=0
```

The fail-closed property holds. The walk fails, the array is empty, and the existing bats case `SHIM_RMTOP=drop` (`build-loop-check.bats:770-775`) pins the `0 0 0` find exits with a failed walk. But when the persistent failure is a top that is no longer a directory (a linked config dir whose target is gone, or a top replaced by a file), find exits 0 silently and the recheck writes nothing. So the third try leaves no message, and the walk reports failure with no cause. The comment's "the third's message shown" holds only for failures find reports. This is diagnostic only; nothing is hidden.

**Recommendation:** Optional. Have the recheck print one line before returning, such as `printf 'top_files: %s: not a directory\n' "$tf_d" >&2`. The `2>/dev/null` on tries 1-2 drops it like find's messages, so only the third try's shows. Otherwise reword the comment to "the third's message shown, if find gave one".

## Answers to the review brief

**Does moving the recheck into the retried helper loosen anything?** No, not within what was read and probed. Before b9f1d2d1, a recheck failure after the chain was terminal. Now it is one failed try, and a later try whose find and recheck both pass is used. That later listing is still one complete find run over directories that were directories when the recheck ran, which is the same "transient error, later clean snapshot" semantics accepted for find's own errors (prior F2, now worded correctly at `:1555-1559`). The comment lists "a top that is no longer a directory" among the persistent errors. A persistent non-directory top still fails all three tries (`p1.log` `chain-deadlink`; bats `SHIM_RMTOP=drop`). The find-then-recheck window inside one try is the same as it was with the recheck after the chain, because in both designs the recheck follows the find that produced the used listing. It is listed below as untested.

**Is only an error-free listing used, with no stale data carried across tries?** Read and executed: `nul_list` empties NAME on any non-zero exit or missing trailing NUL (`:1649`). `top_files` empties it again on a recheck failure (`:1595`, pinned by `build-loop-check.bats:779-788`, `dead: failed, 0 left`). `mapfile` replaces the array on success. The two namerefs (`nl_a` in nul_list, `tf_a` in top_files) both resolve `fl` to `config_seeds`' local, because `top_files` declares only `tf_d` before calling nul_list. The one call site passes `fl` (`rg top_files`: `:1566` only, plus tests).

**Can a skip or retry hide a file that exists throughout the listing?** Not observed. Probe `p1.log` `churn` ran 300 single `top_files` tries on a dir holding a steady instruction-named file while a background loop created and removed 40 files and 40 dirs per cycle: 298 clean, 2 failed (the vanished-dir report the retry exists for), and the steady file was **missing from 0 of the 298 clean listings**. `-ignore_readdir_race` acts only on ENOENT at the entry's stat, and a continuously present name does not produce one. The prior pass's p1 also showed it masks no EACCES, ELOOP or missing-start-point error.

**Option order and stderr:** `find -H DIR -maxdepth 1 -ignore_readdir_race ( ... )` emits no "global option after argument" warning (`p1.log` `real: rc=0` with empty stderr). `2>/dev/null` binds to each `top_files` call only. The third try's find message reaches stderr (`chain-unreadable`).

**Tests:** both new tests pass on the archive copy (`p/bats.log`: `ok 1`, `ok 2`, exit 0). The `dev-cycle.bats` change only adds `top_files` to the declared-function list.

### Untested bypass candidates (move 11, guardrail: skip + three-try retry + per-try -d recheck)

1. **A top swapped for a regular file during find's run and restored before the recheck.** find lists the file as itself and exits 0 (`p1.log` `file-top`: find exits 0, the recheck fails it when the swap persists), and the recheck then passes, so that try's listing holds only the top path and none of its entries. Not tested: it needs a sub-millisecond rename pair on the top. Reasoned: the swap needs rename rights in the top's parent (same uid for `~/.claude`; nobody but root for `/tmp` itself), and such a party can change the contents after the walk anyway. Main had no recheck at all and listed a file top silently, so this is narrower than main.
2. **A linked top whose target is removed and restored inside one try** (carried from the prior review). Same reasoning and same parties as 1.
3. **Delete-and-re-create of an entry between readdir and stat** (Finding 1). Reasoned; not reproduced with a re-create step.
4. **ESTALE / EIO, findutils builds other than 4.9.0, or a `find` on PATH that is not GNU** (the lib calls bare `find`; on this host it resolves to `/usr/bin/find`). Not available here.

Tested this pass: the steady file under churn (0 misses in 298), the recheck on a file top and a dead linked top, missing and unreadable tops through the full chain, stderr of the option order, array emptiness after failure (bats r3 test).

Because candidates remain untested, the skip + retry + recheck guardrail as a whole does not appear in Endorsement Claims.

## Endorsement Claims

- **Claim:** Over 300 tries under concurrent churn of 40 files and 40 directories, every `top_files` listing that returned 0 contained the continuously present file in the same directory.
  **Location:** `scripts/lib/dev-cycle-read.sh:1593-1596`
  **Evidence:** executed
  **Verified:** `p/p1.sh` section 7 on `/usr/bin/find` 4.9.0 against the c4bab9ca archive copy: `churn: clean=298 failed=2 missing-steady-file=0`.
  **Not verified:** the same property on a config-dir top reached through a symlink (`-H` start point) under churn, and through the full `config_seeds` chain rather than `top_files` alone.
  **route: code-fact-check**
- **Claim:** The three-try chain at `:1566` returns 1 with `fl` empty when a top is persistently unreadable or persistently a dangling link. It prints find's message once in the first case and nothing in the second.
  **Location:** `scripts/lib/dev-cycle-read.sh:1566`, `:1595`
  **Evidence:** executed
  **Verified:** `p/p1.sh` sections 5-6, `chain-deadlink: [chain=1] n=0`, `chain-unreadable: [find: ... Permission denied chain=1] n=0`.
  **Not verified:** the walk-level outcome of the dangling-link case for a config dir (bats covers the missing-top and dropped-start-point variants, `build-loop-check.bats:770-775`, not a dangling linked `.claude`).
  **route: code-fact-check**
- **Claim:** Within `config_seeds`, the only caller of `top_files` passes `fl`, whose name collides with neither `top_files`' locals (`tf_d`, `tf_a`) nor `nul_list`'s (`nl_a`).
  **Location:** `scripts/lib/dev-cycle-read.sh:1566`, `:1594-1595`, `:1649`
  **Evidence:** read-static
  **Verified:** `rg -n top_files scripts test hooks skills` shows one lib call site; `config_seeds` declares `fl` local at `:1514`.
  **Not verified:** callers sourcing the lib from outside these directories (none found by the grep, which did not cover `archive/`).

## Primitive sweep

Primitive: filesystem listing via `find` (process exec with path arguments; directory read)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:1594` (`top_files`, called up to 3x at `:1566`) | S1 entries, S2 tops | absolute tops; clean-exit and trailing-NUL check (`nul_list`); per-try `-d` recheck (`:1595`) | Finding 1 (acknowledged), Finding 2 (Informational) |
| `:1539` find -L rules | S2 (`$d/rules`) | `nul_list` exit check | cleared: unchanged by the diff; still fails on any vanished entry |
| `:1540` find -L prompt dirs / plugin installPaths | S2, installed_plugins.json installPath | `/*` + `-d` (`:1535`) | cleared: unchanged by the diff |
| `:1542` find -L projects MEMORY.md | S2 | `nul_list` exit check | cleared: unchanged by the diff |
| `c1_seeds` → `root_starts` (`:1607`), find -P | IMPORT_OTHER roots | `nul_list` exit check | not analyzed: outside the diff, unchanged |
| test shim `build-loop-check.bats:736-744` (`-exec sh -c ... rm -rf`) | fixture paths under `$BATS_TEST_TMPDIR` | `-path "$a/*"`; removes only `"$1"/vic*` | cleared: test-only |
| test `build-loop-check.bats:779-788` (`top_files` direct) | fixture paths under `$BATS_TEST_TMPDIR` | none needed | cleared: test-only |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Non-atomic rewrite of a top-level instruction file skipped when its gap spans find's stat (prior F1, acknowledged, row 828) | Medium | B1→B3 | `scripts/lib/dev-cycle-read.sh:1594` | Low |
| 2 | A try that fails only at the -d recheck is silent, so the walk fails with no message; the comment says the third try's message is shown | Informational | B2 | `:1595`, `:1557-1559` | High |

## Overall Assessment

The posture is unchanged from iteration 2 and slightly improved. Prior F2 is fixed, and prior F1 and F3 are recorded decisions in code and in the override log. Moving the `-d` recheck into the retried helper does not loosen the property. Every listing the walk uses is one find run that reported no error, followed by a recheck that passed. A persistent non-directory top still fails all three tries, and failed tries leave nothing in `fl` (executed and pinned by the new unit test). The only new item is diagnostic (Finding 2): a recheck-only failure is silent. The single most important thing for the merge decision is to confirm that row 828's acceptance of Finding 1 stands; nothing new blocks. The code paths read contain no new findings above Informational. The endorsement claims routed to code-fact-check await execution verification, and the guardrail as a whole stays out of the endorsements because of the untested sub-millisecond swap candidates listed above.

## Goal-Alignment Note

The PR aims to stop the gate flaking when another process deletes an entry mid-listing, without letting a skip or retry hide an existing instruction file. The flake half is met: a vanished file is skipped, a vanished directory costs one retry, and the bats race test shows a clean walk with the failed try's message dropped. The security half is met for every adversarial case examined and for continuously present files under churn (0 misses in 298 clean listings). The one benign exception is a file that is absent at the instant of find's stat because of a delete-and-re-create save (Finding 1). It is now named in the code comment and accepted in override row 828, and main had a comparable silent window when the gap spanned readdir. Nothing in the final commits (b9f1d2d1 through c4bab9ca) moves the branch away from that goal.
