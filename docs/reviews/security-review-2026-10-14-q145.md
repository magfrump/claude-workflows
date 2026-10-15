Commit: 0d573a7b

# Security Review — fix/q145-ancestor-vanish (iteration 2)

**Scope:** `git diff main...HEAD` in worktree `/workspace/.claude/wt-q145` (scripts/lib/dev-cycle-read.sh `config_seeds`, new `top_files`; test/scripts/build-loop-check.bats; test/scripts/dev-cycle.bats; docs/thoughts/failure-patterns.md)
**Date:** 2026-10-14
**Based on:** docs/reviews/code-fact-check-report-2026-10-14-q145-i2.md (0 Incorrect, 17 Verified, 6 Mostly accurate)

Units read in full before filing: `outside_seeds` (:1501-1505), `config_seeds` (:1510-1578), `top_files` (:1584), `nul_list` (:1637), plus `import_readers` (:1206-1262, origin of IMPORT_ROOTS / IMPORT_CONFIGS) and `isstart` / `INSTRUCTION_FILE` (:701, :714). Probes ran on `/usr/bin/find` (GNU findutils 4.9.0) in `/home/node/.claude/jobs/00bcf178/tmp/q145/review/sec/` (`p1.sh`/`p1.log`, `p2.sh`/`p2.log`), each under `timeout`; no probe process is left running.

## Trust Boundary Map

```
B1: [other processes' entries in a top dir (/tmp, ~/.claude, an ancestor's .claude)] → [find -H readdir + stat, -ignore_readdir_race, 3-try retry (top_files, :1561, :1584)] → [fl: the walk's top-level seed list]
B2: [top directory paths (IMPORT_ROOTS ancestors, IMPORT_CONFIGS)]                    → [-d check at build (:1517, :1521) and -d recheck after listing (:1562)]      → [find start points / tops trusted as directories]
B3: [fl seed list]                                                                     → [lower_all + isstart + with_at + realpath filter (:1563-1576)]                → [outside_seeds → walks → self-merge floor (gate)]
```

B1 is where the diff acts: it changes what an error in the listing means (skip, or retry) on the way from shared, writable directories into the gate's seed list. B2 is extended by the new recheck (`(new)` for the :1562 half). B3 is unchanged; it is where a missed seed turns into a gate that lets a change to an imported repo file through.

Input-source classification:

```
S1: entries in a top dir (names, types, presence over time)
      — runtime-mutable (any process with write access to that dir: every local user for /tmp, same uid for ~/.claude)
      — UNTRUSTED toward the completeness of the seed list (an absence there lets a merge through);
        not a sink for exec/parse in this unit (names only reach find output, lower_all, isstart, grep -l, realpath)
S2: tops: ancestors of IMPORT_ROOTS (git worktree list + caller roots, realpath'd and raw spellings) and IMPORT_CONFIGS
      (absolute homes' .claude, CLAUDE_CONFIG_DIR if absolute, /etc/claude-code)
      — runtime-mutable (worktree registry is loop-writable: Q-103 residual; the paths' targets can be swapped by
        whoever can write the parent dir)
      — UNTRUSTED toward which directory a path resolves to at listing time; trusted for argv shape
        (import_readers rejects a non-absolute root, home or CLAUDE_CONFIG_DIR, :1235, :1218), so no start point can
        parse as a find option or expression
S3: retry count (3) and find flags
      — code-constant — trusted
```

Summary: what enters from outside is the momentary contents of shared directories (S1) and which directory each top path names (S2). The diff's new assumption is that an entry find saw by name but could not stat "holds nothing to load", and that an error-free try is a complete listing. The second holds for findutils 4.9.0 on the cases probed; the first holds for an adversary (who gains nothing they lacked) but not for an innocent non-atomic rewrite (Finding 1).

## Findings

#### 1. A non-atomic rewrite of an existing top-level instruction file now gives a silent omission where main failed closed

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:1584`, `:1561`; comment `:1556-1559`
**Boundary:** B1 (feeding B3)
**Move:** 4 (TOCTOU), 3 (error path)
**Confidence:** Low (that it is ever hit; the mechanism itself is High)
**Legibility-target:** merge reviewer weighing the residual window the fix opens

**Evidence:**
```
top_files() { nul_list "$1" find -H "${@:2}" -maxdepth 1 -ignore_readdir_race '(' -xtype f -o -xtype l ')' -print0; }
```
```
    top_files fl "${tops[@]}" 2>/dev/null || top_files fl "${tops[@]}" 2>/dev/null || top_files fl "${tops[@]}" || return 1
```
```
  # itself and exits 0 (i1 fact-check 6a). A file renamed in during the
  # listing may be missed, as with any directory read (readdir leaves a name
  # added mid-read unspecified); before Q-145 the rename's vanished temp name
  # failed the walk only when find had happened to read it.
```

A writer that replaces a file by unlink (or rename-away) followed by create — vim with `backupcopy=no`, `rm && cp`, some sync tools — leaves a gap in which the name does not exist. If find's readdir returned the old name and find's stat lands in that gap, on main `find` reported ENOENT and the walk failed closed (the gate refused). With `-ignore_readdir_race` the entry is skipped, find exits 0, the first try is used and no retry runs, so a file that existed before and after the listing is missing from `fl`. If that file is a top-level instruction file holding an `@` import into the repo (for example `~/.claude/CLAUDE.md`, a config top on every host, or `/tmp/CLAUDE.local.md` when a root lies under /tmp), its imports are not seeded for that walk, and the gate can pass a merge that changes an imported file. The fact-check flags the same thing (Claim 9 scope, Claim 5 residue). The comment names only the rename-in case.

Who gains: an adversary does not. Anyone who can unlink the file can delete it for the whole walk and restore it afterwards, which main never caught either, or create it after the merge. So this widens only the accidental window, by the sub-window between find's readdir of that name and its stat. main already had a similar silent-miss window (readdir after the unlink and before the create returns neither name). The floor rule sets the severity: it is a concrete mechanism in a reachable environment, a benign editor save during a gate run. Practical likelihood is very low: a window of microseconds to milliseconds, on one file, that has to hold an `@` import.

**Recommendation:** At minimum, name this case next to the rename-in sentence (":1556-1559": "a file deleted and recreated between find's readdir and its stat is skipped, not reported") so the residual is a recorded decision. To close the sub-window rather than document it, drop `-ignore_readdir_race` and rely on the retry: any vanished entry then fails that try, and a later clean try reads the recreated name. The cost is that file churn in /tmp or ~/.claude can make all three tries fail more often (see Finding 3 for the rate under hostile churn). That is the original flake, now capped by three tries.

#### 2. The retry absorbs any transient error, not only a vanished entry, and its diagnostics are dropped; the comment says otherwise

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1561`; comments `:830-833`, `:1550-1553`
**Boundary:** B1
**Move:** 3 (error path)
**Confidence:** High
**Legibility-target:** maintainer reading the fail-closed contract; operator diagnosing a failed walk

**Evidence:**
```
    top_files fl "${tops[@]}" 2>/dev/null || top_files fl "${tops[@]}" 2>/dev/null || top_files fl "${tops[@]}" || return 1
```
```
# is used, so any other error there still fails the walk (Q-145). A seed
```

The `||` chain retries on any non-zero exit: a transient EACCES (a chmod flipped back), a transient ELOOP, or a briefly missing top is retried away. Its message goes to `/dev/null` when it happens on try 1 or 2. This does not violate the security property. `nul_list` empties the array on any failure and `mapfile` replaces it on success (`:1637`), so the listing used is one complete find run that reported nothing. It is a valid snapshot, and "the error went away" equals "the directory changed before the snapshot". The loss is diagnostic only: a recurring transient error (for example, a flapping permission on a config dir) leaves no trace unless it hits all three tries. The header claim "any other error there still fails the walk" holds only for an error that persists across three tries (fact-check 1b).

**Recommendation:** Reword to "any other error that persists across the three tries still fails the walk". If transient errors should be visible, keep tries 1 and 2's stderr in a variable and print it only when the walk later fails, or under a debug variable. Optional.

#### 3. Hostile directory churn in a world-writable top can still fail all three tries (fail-closed DoS of the gate; pre-existing, narrowed)

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1561`
**Boundary:** B1
**Move:** 8 (a million of these)
**Confidence:** High (executed)
**Legibility-target:** merge reviewer deciding whether fail-closed under hostile load is acceptable

**Evidence:**
```
    top_files fl "${tops[@]}" 2>/dev/null || top_files fl "${tops[@]}" 2>/dev/null || top_files fl "${tops[@]}" || return 1
```

findutils 4.9 still reports a directory that vanished between readdir and stat (fact-check Claim 4), so any local user who can write in a top (/tmp, when a reader root lies under it) can churn `mkdir`/`rmdir` there to fail each try. Probe `p2.sh`: 16 churners in a 300-file top, 60 three-try runs: 48 tries failed, and 5 runs (8%) failed all three, which fails the walk. The outcome is fail-closed: the gate refuses merges, and no file is hidden. On main a single hit failed the walk, so the diff makes this strictly harder. It needs a co-tenant on the host with a reader root under a shared directory. It is availability only, so it does not meet the floor rule's "security property violated" bar: the property under review is completeness, which holds.

**Recommendation:** Accept as fail-closed (no change). If gates ever run with reader roots under a multi-user /tmp, prefer moving the roots (or `TMPDIR`) to a per-user directory over adding retries.

## Answers to the specific questions

1. **Can an attacker in an ancestor dir use the skip or the retry to hide an instruction file a reader then loads?** Not in a way that adds capability. The walk is a snapshot. Anyone who can make a file vanish at stat time (they need unlink or rename rights, and the sticky /tmp requires ownership) can keep it absent for the whole walk, or create it after the merge, and main misses both. Racing a rename to make a file vanish exactly at stat and reappear gives them the same outcome as deleting it for the whole walk, with more effort. The retry gives no extra attempts at anything useful: each try is an independent full listing, a failed try contributes nothing (`nul_list` resets the array), and a clean try is a valid snapshot. Forcing three failures is feasible (Finding 3) and fails closed. The one genuine new gap is accidental, not adversarial (Finding 1). Untested: an adversary using an fs where readdir returns an unmodified entry zero times under concurrent modification (POSIX forbids; tmpfs and ext4 honour it). Not probed.
2. **Does `-ignore_readdir_race` suppress any error class beyond ENOENT?** On 4.9.0, none of the classes probed (`p1.log`, each run with and without the option, identical output and `rc=1`): EACCES on an entry's stat (top not searchable), EACCES on readdir (top not readable), EACCES on a link target's stat during `-xtype`, ELOOP on a self-loop entry, and ENOENT on a missing start point. The option also does not suppress ENOENT for a vanished directory at depth 1 (fact-check Claim 4) or for a file stat'd before `-xtype` (Claim 17). Untested: ESTALE (NFS), EIO, and findutils versions other than 4.9.0, or bfs if `find` resolves to it (the lib calls bare `find`, so PATH decides; a bfs alias in an interactive shell does not apply to the script).
3. **Is the -d recheck sufficient for a top replaced by a symlink to another directory mid-walk?** It checks directoriness, not identity, so such a swap passes. `p1.log` `linked-top`: find -H lists the target's entries under the link's name and exits 0. That is not a hiding path. The listing shows what the path named when find opened it, which is what a reader opening the path at that moment would load. The swap needs write access to the top's parent: the same uid for ~/.claude, or any local user creating an absent `/tmp/.claude`. Such a party can equally change the contents after the walk. One residue is not covered: the `rules/`, `commands/`, `projects/` subtree listings (:1536-1540) run before the top listing, so a swap between them yields a mixed snapshot. That is pre-existing and outside the diff. A linked top whose target vanishes and returns between find's open and the recheck is not caught (fact-check Claim 5/8 residue). Main had no recheck at all, so the recheck is a strict improvement.
4. **Is dropping stderr on the first two tries a problem?** Only for diagnostics (Finding 2). A persistent error still prints exactly one message, from try 3 (fact-check Claim 5, R5 `stderr=[... Permission denied]`).

### Untested bypass candidates (move 11, guardrail: skip + retry + -d recheck)

- **Linked top whose target is removed and restored inside the listing** (find lists the link at depth 0, exits 0, recheck passes after the restore). Not tested because it needs sub-millisecond timing on a rename of a directory target. Reasoned: it gives the same omission as Finding 1, for a whole top, but only same-uid parties can do it, and they gain nothing over a post-walk change.
- **Delete-and-recreate of a file between readdir and stat** (Finding 1). Reasoned from fact-check R3/R5 (a vanished file is skipped silently with `rc=0`); not reproduced with a recreate step.
- **ESTALE / EIO / other findutils builds.** Not available on this host.

Tested (dispositioned above): error-class suppression (p1), forced triple failure (p2), top swapped for a link to another directory (p1 `linked-top`), and a transient error followed by a clean try (static, via `nul_list` :1637).

Because candidates remain untested, the skip + retry + recheck guardrail as a whole does not appear in Endorsement Claims.

## Endorsement Claims

- **Claim:** On GNU findutils 4.9.0, `top_files`' expression with `-ignore_readdir_race` still exits 1 for EACCES (entry stat, readdir, link-target stat), ELOOP at depth 1, and a missing start point, with output identical to the run without the option.
  **Location:** `scripts/lib/dev-cycle-read.sh:1584`
  **Evidence:** executed
  **Verified:** `p1.sh` on `/usr/bin/find` 4.9.0, both variants per case, log in `p1.log`.
  **Not verified:** these error classes raised inside the walk itself (only the unreadable-top case is in the bats test, `build-loop-check.bats:766-768`), and ESTALE/EIO.
  **route: code-fact-check**
- **Claim:** Every top passed to `find -H` begins with `/`, so no top can be parsed as a find option or expression.
  **Location:** `scripts/lib/dev-cycle-read.sh:1514-1521`, `:1235`, `:1218`, `:1256`
  **Evidence:** read-static
  **Verified:** ancestors are prefixes of roots that pass `[[ "$p" == /* ... ]]` (:1235) or are realpath'd. Config dirs are `${p%/}/.claude` for `p == /*` (:1256), CLAUDE_CONFIG_DIR is gated on `== /*` (:1218), and IMPORT_MANAGED_DIR is a literal.
  **Not verified:** the caller-supplied IMPORT_READER_ROOTS/HOMES strings before :1235 (their producer in reader_settings).
  **route: code-fact-check**
- **Claim:** A failed `top_files` try leaves nothing in `fl` that a later try or the code after :1561 can read.
  **Location:** `scripts/lib/dev-cycle-read.sh:1637`
  **Evidence:** read-static (backed by fact-check Claim 5, executed)
  **Verified:** `nul_list` runs `{ nl_a=(); return 1; }` on any non-zero exit or missing trailing NUL, and `mapfile` replaces the array on success.
  **Not verified:** `with_at`'s handling when `fl` is reused at :1567 (outside the diff).

## Primitive sweep

Primitive: filesystem listing via `find` (process exec with path arguments; directory read)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:1584` (`top_files`, called 3x at :1561) | S1 entries, S2 tops | absolute tops (:1235/:1218/:1256); clean-exit check (`nul_list`); -d recheck (:1562) | Finding 1 (skip of a recreated file), Findings 2-3 (Informational) |
| `:1536` find -L rules | S2 (`$d/rules`) | `nul_list` exit check | cleared: unchanged by diff; still fails on any vanished entry (fact-check 1a scope) |
| `:1537` find -L prompt dirs / plugin paths | S2, installed_plugins.json installPath | `/*` + `-d` check (:1532) | cleared: unchanged by diff |
| `:1539` find -L projects MEMORY.md | S2 | `nul_list` exit check | cleared: unchanged by diff |
| test shim `build-loop-check.bats:735-744` (`-exec sh -c ... rm -rf`) | test fixture paths under `$BATS_TEST_TMPDIR` | `-path "$a/*"` | cleared: test-only, deletes only `vic*` in the fixture dir |

`c1_seeds`' `root_starts` uses `find -P` (outside the diff, unchanged) and is not analyzed here.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Non-atomic rewrite of an existing top-level instruction file is skipped silently (main failed closed) | Medium | B1→B3 | `scripts/lib/dev-cycle-read.sh:1584`, `:1561` | Low |
| 2 | Retry absorbs any transient error and drops its message; comment overstates fail-closed | Informational | B1 | `:1561`, `:830-833` | High |
| 3 | Hostile dir churn can fail all three tries (fail-closed DoS; narrowed vs main) | Informational | B1 | `:1561` | High |

## Overall Assessment

The change is sound in its central claim. The listing it uses is always one complete find run that reported no error. `-ignore_readdir_race` does not mask EACCES, ELOOP or a missing start point on 4.9.0, and the new `-d` recheck closes a gap main had (a linked top whose target vanished was listed as the link and passed). An adversary with write access to a shared top gains no hiding capability they lacked on main, because the walk is a snapshot they can always outwait. The forced-failure DoS remains fail-closed and is harder than before. The one real regression is narrow and accidental (Finding 1): a delete-then-create rewrite whose gap catches find's stat is now skipped instead of failing the walk. The single most important thing is to decide that explicitly. Either record it in the comment beside the rename-in residual, or drop `-ignore_readdir_race` and let the three-try retry absorb vanished files too, at the cost of more retries under churn. All findings are fixable in place; none is architectural. No findings within the code paths read rise above Medium; endorsement claims pending execution verification where routed.

Side note for the fact-check (Claim 10): on 4.9.0, `find -H LINK -maxdepth 1 ... -xtype l` lists a linked top's own path whenever the top is a link, target present or not (`p1.log` `linked-top`, target present: `.../t3l .../t3l/inst.md rc=0`), not only when it dangles. This is harmless here, because a config dir path ending `.claude` fails `isstart` (`INSTRUCTION_FILE`, :701). It is pre-existing.

## Goal-Alignment Note

The PR's goal is to stop the gate flaking under parallel load without letting a skip or retry hide an existing instruction file. The diff meets the flake half (fact-check R1/R2 mutants) and meets the security half for every adversarial case examined. It does not fully meet the stated property "a skip ... must never hide an existing instruction file" for one benign timing case (Finding 1), where the file exists before and after the listing but not at find's stat. The merge decision turns on whether that residual is accepted and documented (it is no wider than readdir's own unspecified window) or closed by dropping the race option in favour of retries alone.
