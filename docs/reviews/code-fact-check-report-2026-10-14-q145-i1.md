Commit: 3a8164d5

# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-q145, branch fix/q145-ancestor-vanish)
**Scope:** branch diff `main...HEAD` (ba5d2d1d, 3a8164d5): `docs/thoughts/failure-patterns.md`, `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, plus both commit messages
**Checked:** 2026-10-14
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 18
**Summary:** 12 verified, 2 mostly accurate, 0 stale, 4 incorrect, 0 unverifiable

**Headline:** at HEAD, `-ignore_readdir_race` in GNU findutils 4.9.0 skips a depth-1 *file* that vanishes mid-listing but **not** a depth-1 *directory*. A vanished subdirectory of a top, such as a session's `mktemp -d` dir in /tmp, is still reported with ENOENT and exit 1, so the walk still fails closed (P3, T2). The comments and the commit subject say every vanished entry is skipped (Claims 2a, 3, 5a, 15). The new test uses only file victims, so it passes. The direction of this error is fail-closed: no file is hidden, but the flake class is only partly fixed.

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first. Every logged entry is a measured value quoted from an artifact set, or a file-to-symbol link, that the artifacts do not contain. No claim here matches one. The closest is Claim 13, which cites test line numbers from another branch's gate runs; it is checked against the Q-145 record below.

Execution environment: GNU findutils 4.9.0 (`/usr/bin/find --version`), bash, bats. All probes ran under `timeout` in the scratch dir `/home/node/.claude/jobs/00bcf178/tmp/q145/review/fc/` (abbreviated `$FC` below). Captured output is in `$FC/logs/`. No process of mine was left running (the bats processes for wt-q110 and wt-dev-cycle visible in `ps` belong to other sessions). This review did not modify the worktree's tracked files. **Note:** at about 04:15Z, after these test copies were taken, *uncommitted* edits to `scripts/lib/dev-cycle-read.sh` and `test/scripts/dev-cycle.bats` appeared in the worktree from another process: a `top_files` helper with up to three retries, and comments citing the directory case found here. This report checks commit 3a8164d5 only, not those edits. `$FC/copy-head` was checked byte-identical to `git show 3a8164d5:` for both the lib and the test file. The before/after test runs used copies of `scripts/` and `test/` under `$FC/copy-{head,main,norecheck,norace}`:
- `head`: HEAD as is.
- `main`: `git show main:scripts/lib/dev-cycle-read.sh` dropped in.
- `norecheck`: HEAD minus the single `for d in "${tops[@]}"; do [[ -d "$d" ]] || return 1; done` line.
- `norace`: HEAD minus `-ignore_readdir_race` on the `find -H` line.

The diffs against HEAD were checked to be exactly one line each.

Executed provenance (each `cd` named, exit code, UTC timestamp):
- **P1**: `timeout 60 $FC/probe1.sh $FC/s1 > $FC/logs/probe1.log 2>&1`. Run from cwd `$FC`, exit 0, 2026-10-15T04:08:15Z. It covers find's behavior with a missing start point, an unreadable top, link-loop entries, a dangling link, a dangling symlink start point, a vanished entry (with and without the option), EACCES on an entry's stat, and EACCES through a link.
- **P2**: `timeout 60 $FC/probe2.sh $FC/s2 > $FC/logs/probe2.log 2>&1`. Run from cwd `$FC`, exit 0, 2026-10-15T04:09:24Z. It covers a top removed, or replaced, at its own depth-0 visit, before find reads its entries.
- **P3**: `timeout 60 $FC/probe3.sh $FC/s3 > $FC/logs/probe3.log 2>&1`. Run from cwd `$FC`, exit 0, 2026-10-15T04:15:43Z. It covers depth-1 *directory* entries versus *file* entries that vanish between readdir and their visit, with and without the option.
- **T2**: in `$FC/copy-headdir` (copy-head, with the test's victims made directories: `mkdir "$a/vic$i"` and `rm -rf`, three lines changed), the same bats command with `TMPDIR=$FC/tmp-headdir`. Started 2026-10-15T04:16:08Z, exit 1, log `$FC/logs/test-headdir.log`.
- **T1**: `cd $FC/copy-$v && TMPDIR=$FC/tmp-$v timeout 300 env LC_ALL=C bats --filter 'ancestor listing skips an entry that vanishes' test/scripts/build-loop-check.bats > $FC/logs/test-$v.log 2>&1`, for each variant, started 2026-10-15T04:10:19Z. Exit codes: head 0, main 1, norecheck 1, norace 1.

---

## Claim 1: FP-173 "cause:overbroad-guard fix:narrow-the-guard ref:ba5d2d1d" and commit 3a8164d5's "reuses the overbroad-guard / narrow-the-guard vocabulary"

**Location:** `docs/thoughts/failure-patterns.md:315`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the two tags already exist in the file and that the ref names the fix commit; does not establish that "overbroad-guard" is the best classification.
**Legibility-target:** for-orchestrator-synthesis

The entry reads `- **FP-173** 2026-10-14 symptom:find-over-shared-ancestor-dir-exits-nonzero-... cause:overbroad-guard fix:narrow-the-guard ref:ba5d2d1d` (`docs/thoughts/failure-patterns.md:315`). Counting other uses of each tag gives 9 lines with `cause:overbroad-guard` and 13 with `fix:narrow-the-guard` (paraphrased — no quote available because this is a grep count over the file). So both tags are reused vocabulary, not new. `ba5d2d1d` is the branch's fix commit (`git log main..HEAD`).

**Evidence:** `docs/thoughts/failure-patterns.md:315`, `git log main..HEAD`

---

## Claim 2a: "The one exception is the top-level listing of ancestors and config dirs (config_seeds): an entry that vanishes between find's readdir and its stat (another process's temp file in /tmp) is skipped, not an error, since a name no longer there holds nothing to load"

**Location:** `scripts/lib/dev-cycle-read.sh:828-831`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers GNU findutils 4.9.0, with depth-1 file and directory entries of a top vanishing mid-listing, through the lib's real call in the bats fixture. Also covers that only the `find -H` listing gained the option. Does not establish other findutils versions or other entry types (FIFOs, sockets).
**Legibility-target:** for-author

The claim holds for a vanished file and fails for a vanished directory. Only one find carries the option. The one `find -H` call in `scripts/lib/` is `nul_list fl find -H "${tops[@]}" -maxdepth 1 -ignore_readdir_race '(' -xtype f -o -xtype l ')' -print0 || return 1` (`scripts/lib/dev-cycle-read.sh:1554`). The tree listings keep `|| return 1` without it, for example `nul_list fl find -L "${fr[@]}" '(' -type f -o -type l ')' -iname '*.md' -print0 || return 1` (`scripts/lib/dev-cycle-read.sh:1534`).

P3, with the option:
- Vanished depth-1 files: `r/vic2`, `r/a0`, `rc=0`, and no diagnostic.
- Vanished depth-1 directories: `/usr/bin/find: 'r/vic4': No such file or directory` (also vic1 and vic3), `rc=1`, identical to the run without the option.

T2 shows the same through the lib. With directory victims, HEAD's test fails at line 745 with `tree: walk: failed` and `/usr/bin/find: '.../test/1/vic2': No such file or directory` (`$FC/logs/test-headdir.log`). A session's `mktemp -d` directory in /tmp that is removed mid-listing therefore still fails the walk. One of Q-145's recorded failures is `find: '/tmp/tmp.JTuucY5EGl'` (`docs/working/questions-archive.md:2663`), and the record does not say whether that was a file or a directory. The error leaves the walk fail-closed, so nothing is hidden. But a reader is told that a vanished entry is never an error, and for a directory it is.

**Evidence:** `scripts/lib/dev-cycle-read.sh:828-832`, `scripts/lib/dev-cycle-read.sh:1533-1539`, `scripts/lib/dev-cycle-read.sh:1553-1558`, `$FC/logs/probe3.log`, `$FC/logs/test-headdir.log`, `docs/working/questions-archive.md:2663`

---

## Claim 2b: "every other error there still fails the walk (Q-145)"

**Location:** `scripts/lib/dev-cycle-read.sh:831-832`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers EACCES (top, entry stat, link target), ELOOP, and a missing or vanished top, on 4.9.0. Does not establish error classes not probed (EIO, ENOTDIR, EOVERFLOW).
**Legibility-target:** for-orchestrator-synthesis

P1 output:
- Unreadable top: `'noperm': Permission denied`, `rc=1`.
- Link loop: `'loop/l2': Too many levels of symbolic links`, `rc=1`.
- Missing start point: `'gone': No such file or directory`, `rc=1`.
- Entry stat EACCES: `'rx/e': Permission denied`, `rc=1`.

T1 head passes the test's three fail-closed cases. More errors fail than the claim says, since vanished directories fail too (Claim 2a). That only makes this half stronger.

**Evidence:** `scripts/lib/dev-cycle-read.sh:831-832`, `$FC/logs/probe1.log`, `$FC/logs/test-head.log`

---

## Claim 3: "returns 1 when a find, grep, realpath or lower_all fails, but for an entry of a top-level directory that vanishes mid-listing, which it skips (Q-145)."

**Location:** `scripts/lib/dev-cycle-read.sh:1505-1507`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the full body of config_seeds (`:1508-1571`), the nul_list contract (`:1624`), and the entry-type behavior from P3/T2; does not establish c1_seeds' or outside_seeds' return conditions.
**Legibility-target:** for-author

The carve-out is too broad. config_seeds skips a vanished *file* entry of a top, but it still returns 1 for a vanished *directory* entry (P3 `rc=1`; T2 `walk: failed`, `$FC/logs/test-headdir.log`). This is the part that makes the verdict Incorrect. Separately, the list of return-1 causes now leaves one out: the recheck added right after the listing, `for d in "${tops[@]}"; do [[ -d "$d" ]] || return 1; done` (`scripts/lib/dev-cycle-read.sh:1555`), returns 1 when no command failed at all. The trigger is a top that is no longer a directory, for example a symlinked top whose target was removed. find exits 0 in that case (P1: `dangling symlink as start point, race` → `topl`, `rc=0`). The recheck is reached whenever find succeeds: nul_list returns 0 only when `"${nl_a[-1]}" == rc=0` (`:1624`). A precise version would add "or a top is no longer a directory after the listing". The header's existing omissions (`with_at`, a grep wrapper) predate this branch.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1505-1507`, `scripts/lib/dev-cycle-read.sh:1553-1557`, `scripts/lib/dev-cycle-read.sh:1624`, `$FC/logs/probe1.log`

---

## Claim 4: "Every ancestor is a top, /tmp too, where other processes' files come and go"

**Location:** `scripts/lib/dev-cycle-read.sh:1542-1543`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers how tops are built from reader-root ancestors and config dirs; does not establish which ancestors exist on any given host.
**Legibility-target:** for-author

Only ancestors that lie below no reader root and that are directories become tops:

```bash
# scripts/lib/dev-cycle-read.sh:1514-1516
      d="${d%/*}"; d="${d:-/}"; in=""
      for q in "${rs[@]}"; do [[ "$d" != "$q" && "$d" != "$q"/* ]] || in=1; done
      [[ -n "$in" || -n "${os_s[a$d]+set}" ]] || { os_s[a$d]=1; [[ ! -d "$d" ]] || tops+=("$d"); cf+=("${d%/}/.claude"); }
```
(excerpt ends :1516; enclosing config_seeds() continues to :1571 — read)

"/tmp too" holds only when a reader root lies under /tmp, as bats fixtures and Q-145's flakes do. This sits in a code comment, and the general item (2) text at `:1475-1476` states the "lies below no root" rule, so a reader is unlikely to be misled. A precise version: "every ancestor of a reader root that lies below no root is a top (/tmp when a root is under it)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1508-1522`, `scripts/lib/dev-cycle-read.sh:1475-1476`

---

## Claim 5a: "-ignore_readdir_race (GNU find): an entry that is gone when find stats it (ENOENT, after readdir named it) is skipped silently instead of failing the walk (Q-145). It holds no file a reader could load"

**Location:** `scripts/lib/dev-cycle-read.sh:1543-1546`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers GNU findutils 4.9.0 with `-H -maxdepth 1 ... -xtype` as the lib calls it, for file and directory entries. Does not establish other findutils versions, or why fts treats directories differently (the source was not read).
**Legibility-target:** for-author

For a file entry the claim holds. P1 `vanish, race` gives `r/vic2`, `rc=0`, and no diagnostic, while `vanish, norace` gives `'r/vic4': No such file or directory`, `rc=1`. For a directory entry it does not hold. P3 `vanished depth-1 dir entries, -ignore_readdir_race` gives `'r/vic4': No such file or directory` (also vic1 and vic3), `rc=1`. That is the same as without the option. Through the lib, T2 fails the walk. A precise version would say: "a *file* (or link) that is gone when find stats it is skipped; a subdirectory of a top that vanishes is still reported with ENOENT by findutils 4.9 and fails the walk".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1543-1546`, `scripts/lib/dev-cycle-read.sh:1554`, `$FC/logs/probe1.log`, `$FC/logs/probe3.log`, `$FC/logs/test-headdir.log`

---

## Claim 5b: "a skip needs ENOENT on the name itself: a permission error, a link loop or any other error still fails"

**Location:** `scripts/lib/dev-cycle-read.sh:1546-1547`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers EACCES on a top, EACCES on an entry's own stat (an r-but-not-x directory), EACCES on a link's target path, and ELOOP, on 4.9.0. Does not establish error classes not probed ("any other error" is extrapolated from the probed set). ENOENT on the name is necessary for a skip but not sufficient (Claim 5a).
**Legibility-target:** for-orchestrator-synthesis

P1 output with the option:
- EACCES on an entry's stat: `'rx/e': Permission denied`, `rc=1`.
- A link whose target lies behind an unsearchable directory: `'t2/l': Permission denied`, `rc=1`.
- Loop entries: `Too many levels of symbolic links`, `rc=1`.
- Unreadable top: `'noperm': Permission denied`, `rc=1`.

ENOENT on a link's *target* is not skipped either: the link is listed as dangling (Claim 7).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1546-1547`, `$FC/logs/probe1.log`

---

## Claim 6a: "as does a vanished top, which findutils 4.9 still reports"

**Location:** `scripts/lib/dev-cycle-read.sh:1547-1548`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a top whose name is gone (a missing start point), a top removed between its depth-0 visit and the read of its entries, and a top that is a symlink whose target is gone. Does not establish versions other than 4.9.0.
**Legibility-target:** for-author

For a top whose name is gone, 4.9.0 reports it even with the option. P1 `missing start, race` gives `/usr/bin/find: 'gone': No such file or directory`, `rc=1`. P2 shows the same for a top removed at its own visit, after find has seen it but before it opens it: `'top': No such file or directory`, `rc=1`. That holds although the installed 4.9.0 man page says of the option: "This also applies to files or directories whose names are given on the command line" (`man find`, `-ignore_readdir_race`). The binary does not do what its manual says here, and the comment follows the binary. That is correct.

Tops can be symlinks. `IMPORT_CONFIGS` adds `"${p%/}/.claude"` for each home both as written and resolved (`scripts/lib/dev-cycle-read.sh:1255`), and `CLAUDE_CONFIG_DIR` as written (`:1256`). For a top that is a symlink to a directory whose target vanished, 4.9.0 does **not** report anything. P1 `dangling symlink as start point, race` → `topl`, `rc=0`, and the same without the option. find lists the link itself as an `-xtype l` file and exits 0. Only the `-d` recheck catches that case (Claim 6b). So the reported-by-4.9 half holds for a missing name but not for a top reached through a link. A precise version: "a vanished top, which findutils 4.9 reports when its name is gone (not when it is a link whose directory is gone), and which the -d recheck below catches in any version". The mechanism the comment gives for the link case is wrong. Its conclusion, that the walk still fails, holds because of the recheck.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1547-1549`, `scripts/lib/dev-cycle-read.sh:1253-1256`, `$FC/logs/probe1.log`, `$FC/logs/probe2.log`

---

## Claim 6b: "and the -d recheck below catches in any version (a version that also skips a missing start point)"

**Location:** `scripts/lib/dev-cycle-read.sh:1548-1549`, `scripts/lib/dev-cycle-read.sh:1555`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the recheck is reached after any successful listing, that it fails a top which is missing (or a dangling link) at recheck time, and that the test's `drop` case depends on it. Does not establish the case of a top that vanishes during the listing and is recreated before the recheck, under a hypothetical find that silently skips a missing start point. 4.9.0 reports that case itself: P2 replaced-top gives `rc=0` with the new file listed, because the replacement was there when find opened it.
**Legibility-target:** for-orchestrator-synthesis

Reachability: `nul_list fl find -H ... || return 1` returns 0 only when find exited 0 (`nl_a[-1] == rc=0`, `scripts/lib/dev-cycle-read.sh:1624`). Control then falls to `for d in "${tops[@]}"; do [[ -d "$d" ]] || return 1; done` (`:1555`). `[[ -d ]]` follows links, so a dangling symlinked top fails too. Sufficiency, by mutation: with the recheck line removed (`norecheck`), T1 fails at the `drop` case. In the log, test line 755 fails `want walk failed` with output `walk: ok` (`$FC/logs/test-norecheck.log`). The HEAD copy passes. So without the recheck, a top dropped from the start points goes unnoticed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1553-1557`, `scripts/lib/dev-cycle-read.sh:1624`, `$FC/logs/test-norecheck.log`, `$FC/logs/test-head.log`, `$FC/logs/probe1.log`

---

## Claim 7: (commit ba5d2d1d) "-ignore_readdir_race (GNU findutils), which skips only an ENOENT on a name readdir returned. Probed on findutils 4.9.0: a permission error, a link loop and a missing start point are still reported with exit 1, and a dangling link is still listed by -xtype l."

**Location:** commit `ba5d2d1d` (message body, paragraph 2); code `scripts/lib/dev-cycle-read.sh:1554`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers findutils 4.9.0 for each listed case. "Skips only an ENOENT on a name readdir returned" is true as an upper bound, but not every such ENOENT is skipped: a vanished directory entry is not (Claim 5a, which carries that defect). Does not establish the dangling-link listing under `-L` (the commit says it was not probed and leaves the `-L` listings unchanged).
**Legibility-target:** for-orchestrator-synthesis

P1, all with the option:
- Permission error: `'noperm': Permission denied`, `rc=1`.
- Link loop: `Too many levels of symbolic links`, `rc=1`.
- Missing start point: `'gone': No such file or directory`, `rc=1`.
- Dangling link: `dangling listed, race` → `top/dang`, `rc=0`.

"Only" holds for the cases probed (Claim 5b).

**Evidence:** `git show ba5d2d1d`, `$FC/logs/probe1.log`

---

## Claim 8: (commit ba5d2d1d) "A -d recheck of every top after the listing fails the walk on a top that vanished even under a find that skipped a missing start point."

**Location:** commit `ba5d2d1d`; code `scripts/lib/dev-cycle-read.sh:1555`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 6b. Does not establish the vanish-then-recreate window.
**Legibility-target:** for-orchestrator-synthesis

The test's `T_RMTOP=drop` simulates such a find by removing the top from the start points. HEAD fails the walk there and `norecheck` does not (T1). The code is quoted in Claim 6b.

**Evidence:** `test/scripts/build-loop-check.bats:753-756`, `$FC/logs/test-head.log`, `$FC/logs/test-norecheck.log`

---

## Claim 9: "A file renamed in during the listing may be missed, as with any directory read (readdir leaves a name added mid-read unspecified); before Q-145 the rename's vanished temp name failed the walk only when find had read it." (also in commit ba5d2d1d's Notes)

**Location:** `scripts/lib/dev-cycle-read.sh:1550-1552`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the POSIX readdir semantics and the fact that an ENOENT arises only for a name readdir returned. Does not establish how often a rename-in (for example an editor's atomic save of an ancestor's instruction file) coincides with a gate walk, and does not cover a temp file that lives in a different directory, which leaves no vanished name in the top at all.
**Legibility-target:** for-orchestrator-synthesis

POSIX `readdir()` says that if a file is added to or removed from the directory after `opendir()`, whether readdir returns an entry for it is unspecified (paraphrased — no quote available because the POSIX text is an external spec read from memory; the sandbox has no network egress). find stats only names that readdir returned. T1 `norace`/`main` show ENOENT only for `vic*` names that find had already read (`$FC/logs/test-main.log`). So a temp name that was renamed away produced an ENOENT, and a failed walk, only if readdir had returned that name before the rename. The new code turns that case into a skip. The comment says plainly that the trade gives up an unreliable detector, which is accurate.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1550-1552`, `$FC/logs/test-main.log`

---

## Claim 10: Test comment "The race, made deterministic with the real find: a shim adds, to the -H top-level listing only, a clause that runs at the first entry of the fixture's ancestor and deletes every other vic* there. find read all their names before that first visit, so it stats each deleted one later and gets ENOENT."

**Location:** `test/scripts/build-loop-check.bats:725-728`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the shim adds its clause only to the lib's single `find -H` call, that the real find runs, that the names were read before the first visit, and that the arg split is sound for that call. Does not establish determinism under a find that reads a directory incrementally between visits (GNU 4.9.0's fts reads it all first, as observed). Does not cover directory victims: every `vic*` is a file (`echo > "$a/vic$i"`, `:743`), and the same test with directory victims fails at HEAD (T2).
**Legibility-target:** for-orchestrator-synthesis

The shim passes every call except one starting with `-H` straight to the real find: `[[ "\${1:-}" == -H ]] || exec "$real" "\$@"` (`test/scripts/build-loop-check.bats:736`). `scripts/lib/` has exactly one `find -H` call (`:1554`, grep). The split `while [[ \$# -gt 0 && "\$1" != '(' ]]` (`:738`) stops at the first literal `(`. In the lib's call, everything before that `(` is start points, `-maxdepth 1` and `-ignore_readdir_race` (the same holds on main without the option). The start points are always absolute paths, because `IMPORT_ROOTS` entries are realpath'd or required to be `/*` and config dirs are absolute (`scripts/lib/dev-cycle-read.sh:1238-1256`), so none can equal `(`. The new expression `( -path "$a/*" -exec ... -false ) -o ( -xtype f -o -xtype l ) -print0` keeps the original meaning, since `-a` binds tighter than `-o`. The clause ends in `-false`, so the visited entry is still listed.

"Read all names before the first visit": T1 `main`/`norace` report `No such file or directory` for three of `vic1..vic4` and print the fourth (`$FC/logs/test-main.log`). find had those names in hand after they were deleted. The `compgen` check at `:747-748` also guards against a silent no-race run. If `$a` were spelled differently from the start points, `-path "$a/*"` would never match, and that check would fail the test loudly.

**Evidence:** `test/scripts/build-loop-check.bats:724-750`, `scripts/lib/dev-cycle-read.sh:1554`, `$FC/logs/test-main.log`, `$FC/logs/test-norace.log`

---

## Claim 11: Test comment "With T_RMTOP it instead removes the ancestor's .claude, a top config_seeds already found to be a directory, first; T_RMTOP=drop also drops it from the start points, as a find that skipped a missing start point silently would, which leaves the -d recheck to catch it."

**Location:** `test/scripts/build-loop-check.bats:728-731`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `T_RMTOP=1` and `drop` paths and whether they are fail-closed. Does not establish anything about the permission case beyond `walk failed`.
**Legibility-target:** for-orchestrator-synthesis

`$a/.claude` is created by `mkdir -p` before each run (`:755`). So `config_seeds`' `-d "$d"` test (`scripts/lib/dev-cycle-read.sh:1520`) adds it to the tops before find runs. The shim then runs `rmdir "$a/.claude"` (`:737`), and with `drop` it leaves `$a/.claude` out of `args` (`:738`). Mutation: `norecheck` fails exactly the `drop` case (`walk: ok`, `$FC/logs/test-norecheck.log`). So `drop` does exercise the recheck, and `T_RMTOP=1` is caught by find's own missing-start-point error.

**Evidence:** `test/scripts/build-loop-check.bats:737-738`, `test/scripts/build-loop-check.bats:751-757`, `scripts/lib/dev-cycle-read.sh:1516-1520`, `$FC/logs/test-norecheck.log`

---

## Claim 12: (commit ba5d2d1d) "The new build-loop-check test ... checks both walks: the vanished entries are skipped and the ancestor's instruction file is still read; an unreadable top, a removed top, and a removed top dropped from find's start points all still fail the walk. Before the fix the test fails with the flake's exact message."

**Location:** commit `ba5d2d1d`; `test/scripts/build-loop-check.bats:724-759`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test on HEAD and against main's lib in a scratch copy. "Exact message" means the same find diagnostic form (`find: '<path>': No such file or directory`), on the fixture's own path rather than the historical `/tmp/bats-run-*` path. Does not establish the full suite's status (only this test was run). "The vanished entries are skipped" holds for the test's file victims only; directory victims are not skipped (T2, Claim 2a).
**Legibility-target:** for-orchestrator-synthesis

Both walks: `for w in tree main` (`:742`, `:752`). On the instruction file, `want docs/a.md imported` follows from the ancestor's `CLAUDE.local.md` holding `@repo/docs/a.md` (`:733`). T1 head: `ok 1`. T1 main: `not ok 1` at line 745, with `tree: walk: failed` and `/usr/bin/find: '.../test/1/vic2': No such file or directory` (`$FC/logs/test-main.log`). That is the same diagnostic Q-145 quotes, `find: '/tmp/bats-run-*/bats.PID.out': No such file or directory` (`docs/working/questions-archive.md:2663`).

**Evidence:** `test/scripts/build-loop-check.bats:724-759`, `docs/working/questions-archive.md:2657-2668`, `$FC/logs/test-head.log`, `$FC/logs/test-main.log`

---

## Claim 13: (commit ba5d2d1d) "An entry another process deletes between find's readdir and its stat (a bats output file or a session temp file in /tmp) made find report ENOENT and exit 1, so the walk failed closed and the gate refused: the build-loop-check 968 and build-loop-merge 1059/1061 flakes under parallel load."

**Location:** commit `ba5d2d1d` (paragraph 1)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the mechanism, reproduced as ENOENT then exit 1 then walk failed, and agreement with the Q-145 record. Does not establish that the historical flakes at those test line numbers were reproduced here (they ran on `feat/q102-parallel-gates`, and line numbers drift). It also does not establish that the fix removes them all: `bats.PID.out` is a file, which is now skipped, but whether `/tmp/tmp.JTuucY5EGl` was a `mktemp` file or a `mktemp -d` directory is unrecorded, and a directory is still not skipped.
**Legibility-target:** for-orchestrator-synthesis

The mechanism is reproduced by T1 `main` (Claim 12). Q-145 records the same failures: "`find: '/tmp/bats-run-*/bats.PID.out': No such file or directory` ... and `find: '/tmp/tmp.JTuucY5EGl'` (another session's temp file), in build-loop-check 968 and build-loop-merge 1059/1061" (`docs/working/questions-archive.md:2663`). Confidence is medium only because the line-number attribution rests on that record, not on a rerun.

**Evidence:** `docs/working/questions-archive.md:2657-2668`, `$FC/logs/test-main.log`

---

## Claim 14: (commit ba5d2d1d Notes) "scope kept to the top-level listing named in Q-145. The find -L listings of config-dir trees (rules, prompts, projects) keep failing on a vanished entry"

**Location:** commit `ba5d2d1d`; `scripts/lib/dev-cycle-read.sh:1533-1539`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the three `-L` listings carry no `-ignore_readdir_race` and keep `|| return 1`. Does not establish their behavior under the option (not probed by the author or here).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/lib/dev-cycle-read.sh:1534-1536
  if [[ ${#fr[@]} -gt 0 ]]; then nul_list fl find -L "${fr[@]}" '(' -type f -o -type l ')' -iname '*.md' -print0 || return 1; ...
  if [[ ${#pr[@]} -gt 0 ]]; then nul_list fl find -L "${pr[@]}" '(' -type f -o -type l ')' -iname '*.md' -print0 || return 1; ...
  if [[ ${#mr[@]} -gt 0 ]]; then
```
(excerpt ends :1536; enclosing block continues to :1539 with the `mr` `find -L ... -name MEMORY.md -print0 || return 1` — read)

Without the option, a vanished entry is reported with exit 1 (P1 `vanish, norace`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1533-1539`, `$FC/logs/probe1.log`

---

## Claim 15: (commit ba5d2d1d subject) "fix(dev-cycle-read): ancestor listing skips entries that vanish mid-listing (Q-145)"

**Location:** commit `ba5d2d1d` (subject line)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers file and directory entries on findutils 4.9.0. Does not establish other versions.
**Legibility-target:** for-author

The listing skips vanished *file* entries (P1, T1 head). It still fails on vanished *directory* entries: P3 `rc=1`, and T2 fails with `walk: failed` (`$FC/logs/test-headdir.log`). The subject and the body's "skips only an ENOENT on a name readdir returned" describe a fix wider than the one shipped. The body names a "session temp file in /tmp" as a cause, and a session's temp *directory* is not covered.

**Evidence:** `git show ba5d2d1d`, `$FC/logs/probe3.log`, `$FC/logs/test-headdir.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2a** (`scripts/lib/dev-cycle-read.sh:828-831`): "an entry that vanishes ... is skipped, not an error" is true only for files. A vanished subdirectory of a top (a `mktemp -d` dir in /tmp) is still reported (ENOENT, exit 1) under `-ignore_readdir_race` on 4.9.0 and fails the walk. Fix the code, as the uncommitted retry appears to attempt, or narrow the comment.
- **Claim 3** (`scripts/lib/dev-cycle-read.sh:1505-1507`): config_seeds' "but for an entry ... that vanishes mid-listing, which it skips" overclaims for the same reason. It also leaves out the new return-1 cause (a top that is no longer a directory, via the `-d` recheck).
- **Claim 5a** (`scripts/lib/dev-cycle-read.sh:1543-1546`): "an entry that is gone when find stats it ... is skipped silently" is true for files and links only; directories are still reported by 4.9.0.
- **Claim 15** (commit `ba5d2d1d` subject): "skips entries that vanish mid-listing" overclaims; vanished directory entries still fail the walk. The test (file victims only) cannot catch this. A directory-victim variant fails at HEAD (T2).

### Stale
(none)

### Mostly Accurate
- **Claim 4** (`scripts/lib/dev-cycle-read.sh:1542-1543`): "Every ancestor is a top" should read "every ancestor that is a directory and lies below no reader root"; /tmp is a top only when a root lies under it.
- **Claim 6a** (`scripts/lib/dev-cycle-read.sh:1547-1548`): "a vanished top, which findutils 4.9 still reports" is true when a top's name is gone. A top that is a symlink to a directory whose target is gone is not reported by 4.9.0 (exit 0, the link listed as `-xtype l`); only the `-d` recheck catches it. Say so, or drop "which findutils 4.9 still reports" and rest the claim on the recheck. The installed 4.9.0 man page contradicts the binary on start points, and the comment rightly follows the binary.

### Unverifiable
(none)

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved to /workspace/.claude/wt-q145/docs/reviews/code-fact-check-report-2026-10-14-q145-i1.md, structured per the code-fact-check skill, first line `Commit: 3a8164d5`, header including `**Replication:** k=1 (loop pass, decision 031)`.
- Answered: yes. All 8 caller-named claim groups were checked, with probes of GNU find 4.9.0 and runs of the new test against HEAD, main's lib, two single-line mutants, and a directory-victim variant.
- Out of scope: the full build-loop-check suite and the health gate were not run (no claim cites them); the `-L` listings' behavior under the option.
- Escalate: (1) HEAD's fix is incomplete. GNU find 4.9.0's `-ignore_readdir_race` does not skip a vanished depth-1 *directory*, so the Q-145 flake persists for `mktemp -d`-style churn in /tmp. This fails closed (no hidden file), but the comments, the config_seeds header, and the commit subject claim a full skip. Add a directory-victim case to the test. (2) The worktree carries uncommitted lib/test edits (a retry wrapper) from another process, which this report did not review; a re-review is needed if they are committed. (3) The security-relevant residue is Claim 6a: symlinked tops whose target vanished are caught only by the `-d` recheck, so that line must not be removed as redundant with find's own error. The recheck's own window (a top gone and recreated between listing and recheck) matters only for a find that skips a missing start point; 4.9.0 does not.
- Decisions I made: verdicted the directory gap as Incorrect, not Mostly accurate, because the stated mechanism ("an entry that is gone ... is skipped") is refuted for a whole entry class that Q-145's failures can include. Execution logs live in the scratch dir, not in `docs/reviews/execution-logs/`, per the caller's instruction to edit only this report. Claim 6a was kept as one claim because the comment does not separate a top whose name is gone from a symlinked top whose target is gone. It is Mostly accurate rather than Incorrect because the case the comment names is right and the fail-closed conclusion holds.
