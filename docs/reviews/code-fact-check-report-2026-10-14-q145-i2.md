Commit: 0d573a7b

# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-q145, branch fix/q145-ancestor-vanish)
**Scope:** `git diff main...HEAD` at 0d573a7b: `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`, `docs/thoughts/failure-patterns.md`, and the messages of commits d2dc88c9 and 0d573a7b (ba5d2d1d and 3a8164d5 were checked in iteration 1)
**Checked:** 2026-10-14
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 23
**Summary:** 17 verified, 6 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Every claim also carries a `**Legibility-target:**` line naming the reader the claim is written for.

Execution provenance. All runs used a copy of the worktree at `/home/node/.claude/jobs/00bcf178/tmp/q145/review/fc2/wt`, re-initialised as a standalone git repo so that nothing touched the worktree's index. Mutants are sibling copies (`m_main`, `m_noretry`, `m_norace`, `m_nod`, `m_nodrop`, `m_dump`). Captured output is under `/home/node/.claude/jobs/00bcf178/tmp/q145/review/fc2/logs/` (abbreviated `LOGS/` below). Probes ran under `/usr/bin/find` (GNU findutils 4.9.0). Times are UTC on 2026-10-15, which is still 2026-10-14 in the commit time zone (-0700).

| Run | Command (cwd) | Exit | Time | Output |
|---|---|---|---|---|
| R1 HEAD test | `LC_ALL=C bats --filter 'Q-145' test/scripts/build-loop-check.bats` (`fc2/wt`) | 0 | 04:19:59Z | `LOGS/head.txt` |
| R2 mutants | same command in `fc2/m_{main,noretry,norace,nod,nodrop}` | 1 each | 04:21:00Z | `LOGS/mut-*.txt` |
| R3 race probe | `timeout 120 ./race-probe.sh` (`fc2`) | 0 | 04:22:02Z | `LOGS/race-probe.txt` |
| R4 stat-then-xtype probe | `timeout 60 ./probe3.sh` (`fc2`) | 0 | 04:22:22Z | `LOGS/probe3.txt` |
| R5 instrumented test | R1's command in `fc2/m_dump` (the test plus `echo DUMP ... >&3` lines; no lib change) | 0 | 04:22:42Z | `LOGS/dump.txt` |
| R6 loop/dangling probe | inline `bash -c` over `fc2/probe` | 0 | ~04:23Z | `LOGS/loop-probe.txt` |
| R7 function list | `LC_ALL=C bats --filter 'sourcing the reader lib defines its functions' test/scripts/dev-cycle.bats` in `fc2/wt` (exit 0) and `fc2/m_main` (exit 1) | 0 / 1 | 04:24:08Z | `LOGS/devcycle-fnlist*.txt` |

An unlogged probe in this session (zsh, at about 04:21Z) also ran a missing start point, a linked top whose target was gone, and an unreadable top. Its output is quoted in Claims 6 and 7.

## Iteration 1 findings at HEAD

| i1 claim | i1 verdict | At 0d573a7b |
|---|---|---|
| 2a (walk header: a vanished entry "is skipped") | Incorrect | Resolved. The header now reads "is skipped, or the listing is retried" (Claim 1a) |
| 3 (config_seeds header: "which it skips") | Incorrect | Resolved (Claim 2) |
| 4 ("Every ancestor is a top") | Mostly accurate | Resolved. Now "Each ancestor below no reader root is a top" (Claim 3) |
| 5a (top comment: skip covers any vanished entry) | Incorrect | Resolved. A directory is retried, not skipped (Claim 4) |
| 6a (vanished linked top "reported") | Mostly accurate | Resolved. The comment now says find 4.9 lists the link and exits 0, and the -d recheck catches it (Claim 8) |
| 15 (ba5d2d1d subject "skips entries that vanish") | Incorrect | Superseded, not rewritten. ba5d2d1d's subject and body stay in history. d2dc88c9's message records that a vanished directory is still reported and adds the retry (Claim 17) |

---

## Claim 1a: "an entry that vanishes between find's readdir and its stat (another process's temp file in /tmp) is skipped, or the listing is retried, up to three tries, since a name no longer there holds nothing to load; only an error-free listing is used"

**Location:** `scripts/lib/dev-cycle-read.sh:829-833`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a maintainer reading the walk's fail-closed contract
**Scope:** Covers what the one top-level listing does on GNU findutils 4.9.0: it skips a vanished file or link, retries the listing when a vanished directory is reported, and uses only a listing that exited 0. Does not establish other findutils versions, or the find -L tree listings (rules, prompts, projects), which still fail on any vanished entry.

The call site is `top_files fl "${tops[@]}" 2>/dev/null || top_files fl "${tops[@]}" 2>/dev/null || top_files fl "${tops[@]}" || return 1` (`scripts/lib/dev-cycle-read.sh:1561`). top_files is `nul_list "$1" find -H "${@:2}" -maxdepth 1 -ignore_readdir_race '(' -xtype f -o -xtype l ')' -print0` (`:1584`). nul_list is `mapfile -d '' nl_a < <("$@" && printf rc=0 || printf rc=1); [[ ${#nl_a[@]} -gt 0 && "${nl_a[-1]}" == rc=0 ]] || { nl_a=(); return 1; }; unset 'nl_a[-1]'` (`:1637`). So a try succeeds only when find exits 0. R5 logged each listing's exit status. The file case logged `log=[0 ]`, one clean listing, and all four victims were deleted (`vic=0`). The directory case logged `log=[1 0 ]` (`LOGS/dump.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1561`, `:1584`, `:1637`; `LOGS/dump.txt`, `LOGS/race-probe.txt`

---

## Claim 1b: "so any other error there still fails the walk (Q-145)"

**Location:** `scripts/lib/dev-cycle-read.sh:833`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** a security reviewer relying on fail-closed
**Scope:** Covers errors that persist across three tries. Does not hold for a transient error of any kind (EACCES, ELOOP, a briefly missing top): the retry absorbs it as long as one of the three tries completes cleanly.

The `||` chain at `:1561` retries on any non-zero exit, not only ENOENT. So "any other error ... fails the walk" holds only for an error that is still there on all three tries. The security property still holds, because the listing used is a complete find run that reported no error (Claim 5). Precise version: "any other error that persists across the three tries still fails the walk".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1561`

---

## Claim 2: "returns 1 when a find, grep, realpath or lower_all fails (the top-level listing, top_files, after three tries, for an entry that vanishes mid-listing: Q-145), or a top is no longer a directory after it."

**Location:** `scripts/lib/dev-cycle-read.sh:1506-1509`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** a caller of config_seeds (outside_seeds)
**Scope:** Covers the two new return-1 paths: top_files failing three times (`:1561`) and the -d recheck (`:1562`). Does not establish the pre-existing paths. Note that the three tries apply to every top_files failure, not only to a vanished entry, and the python3 plugin-list failure falls back rather than returning 1 (`:1528-1533`, outside the diff).

The two paths are `top_files ... || return 1` (`:1561`) and `for d in "${tops[@]}"; do [[ -d "$d" ]] || return 1; done` (`:1562`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1506-1509`, `:1510-1577`

---

## Claim 3: "Each ancestor below no reader root is a top (/tmp, when a root lies under it) ... an entry find's readdir named can be gone when find stats it, and find then reports ENOENT and exits 1 (Q-145)"

**Location:** `scripts/lib/dev-cycle-read.sh:1544-1547`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a maintainer of config_seeds
**Scope:** Covers how tops are built and find's behaviour without the option. Does not establish that every ancestor exists (only a directory joins tops).

Tops are built by `for q in "${rs[@]}"; do [[ "$d" != "$q" && "$d" != "$q"/* ]] || in=1; done` followed by `[[ -n "$in" || ... ]] || { os_s[a$d]=1; [[ ! -d "$d" ]] || tops+=("$d"); ... }` (`:1516-1517`). R3 ran without `-ignore_readdir_race` (`f-others-no`) and got `/usr/bin/find: 'B/f-others-no/v2': No such file or directory` and `rc=1`. Iteration 1's Claim 4 is resolved.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1511-1519`; `LOGS/race-probe.txt`

---

## Claim 4: "top_files' -ignore_readdir_race skips such a file, but findutils 4.9 still reports a directory that vanished that way (a session's mktemp -d)"

**Location:** `scripts/lib/dev-cycle-read.sh:1547-1549`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a maintainer deciding whether the retry can be removed
**Scope:** Covers findutils 4.9.0 with the lib's exact expression, for files, links and directories deleted after readdir. Does not establish that the CI flake's entry was a mktemp -d directory (see Claim 16).

R3 with the option set: files deleted by another process gave `rc=0` with no message (`f-others-yes`), and so did links (`l-others-yes`). Directories gave `/usr/bin/find: 'B/d-others-yes/v2': No such file or directory` and `rc=1` (`d-others-yes`). A directory deleted at its own visit is reported too, twice per entry (`d-self-yes`).

**Evidence:** `LOGS/race-probe.txt`; `scripts/lib/dev-cycle-read.sh:1584`

---

## Claim 5: "a failed listing is run again, up to three times in all, the first two with stderr dropped. Only a listing that completes without any error is used, so a retry never hides an existing file"

**Location:** `scripts/lib/dev-cycle-read.sh:1549-1551`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a security reviewer of the self-merge floor
**Scope:** Covers three things. A failed try leaves `fl` empty. A successful try replaces `fl` entirely. The redirections drop only tries 1 and 2's stderr. Does not establish completeness against a file that is unlinked and recreated (or renamed in) during the successful try, or a linked top whose target directory vanishes and returns during it. In both cases the clean listing omits a name that exists afterwards. That is the same window the comment's last sentence (`:1556-1559`) names for a file renamed in, and a single error-free run without retries has the same window.

On partial contents: nul_list runs `mapfile -d '' nl_a`, which replaces the array, and on any failure runs `{ nl_a=(); return 1; }` (`:1637`). So a failed try leaves nothing in `fl` that a later try could inherit, and a success leaves exactly that run's entries. The redirections are `top_files fl "${tops[@]}" 2>/dev/null || top_files fl "${tops[@]}" 2>/dev/null || top_files fl "${tops[@]}"` (`:1561`). Each `2>/dev/null` applies to one call, process substitution included. R5's unreadable-top case logged `log=[1 1 1 ]` with exactly one message on stderr: `stderr=[/usr/bin/find: 'T/test/1/.claude': Permission denied]`. That is the third try's. In the `nodrop` mutant (`2>/dev/null` removed), the directory case leaked `find: '.../vic2': No such file or directory` and the test failed (`LOGS/mut-nodrop.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1561`, `:1637`; `LOGS/dump.txt`, `LOGS/mut-nodrop.txt`

---

## Claim 6: "a permission error, a link loop or a missing top fails every try and the walk"

**Location:** `scripts/lib/dev-cycle-read.sh:1551-1553`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a security reviewer
**Scope:** Covers persistent errors on findutils 4.9.0: an unreadable top, a self-referential link at depth 1, a top that is a link loop, and a missing start point. Does not cover a transient error (Claim 1b).

R6: a self-loop at depth 1 gave `Too many levels of symbolic links` and `self-loop at depth1 rc=1`. A top that is a loop gave `top-is-loop rc=1`. A dangling link is still listed with `dangling rc=0`. In the unlogged zsh probe, a missing start point gave `No such file or directory` with `rc=1` both with and without the option, and an unreadable top gave `Permission denied` with `rc=1`. R5 shows both cases inside the walk. The unreadable top logged `[1 1 1 ]`. In the T_RMTOP=1 case the log was not reset after the unreadable-top case, so its `[1 1 1 1 1 1 ]` is three earlier tries plus three more, each with `No such file or directory`.

**Evidence:** `LOGS/loop-probe.txt`, `LOGS/dump.txt`

---

## Claim 7: "the -d recheck fails a top that is no longer a directory: one that vanished under a find that skipped a missing start point silently"

**Location:** `scripts/lib/dev-cycle-read.sh:1553-1555`, `:1562`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a maintainer porting to another findutils
**Scope:** Covers the recheck catching a top dropped from find's start points (T_RMTOP=drop). Does not establish that any findutils release skips a missing start point silently: 4.9.0 does not (Claim 6), so on this host the clause is defence in depth.

R5 T_RMTOP=drop added one clean listing (`... 0 ]`) with empty stderr, and the walk failed. In the `nod` mutant (recheck removed), the test failed at that case with `want: walk: failed` and `walk: ok` (`LOGS/mut-nod.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1562`; `LOGS/dump.txt`, `LOGS/mut-nod.txt`

---

## Claim 8: "or a linked top whose target vanished, which find 4.9 lists as the link itself and exits 0 (i1 fact-check 6a)"

**Location:** `scripts/lib/dev-cycle-read.sh:1555-1556`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a maintainer porting to another findutils
**Scope:** Covers find's output and the recheck catching it (`[[ -d link ]]` follows the link, so it is false once the target is gone). Does not establish a test for this case (none of the Q-145 cases makes a linked top), or a target that vanishes and returns during the listing (Claim 5's residue).

In the unlogged zsh probe, `find -H .../lt -maxdepth 1 -ignore_readdir_race ...` on a link whose target directory had been removed printed `.../probe/lt` and `rc=0`. The cited "i1 fact-check 6a" exists (iteration 1 report, Claim 6a). Iteration 1's Claim 6a is resolved.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1562`; `docs/reviews/code-fact-check-report-2026-10-14-q145-i1.md:173-189`

---

## Claim 9: "A file renamed in during the listing may be missed, as with any directory read ... before Q-145 the rename's vanished temp name failed the walk only when find had happened to read it."

**Location:** `scripts/lib/dev-cycle-read.sh:1556-1559`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** a security reviewer weighing the residual window
**Scope:** Covers the renamed-in case, unchanged since iteration 1's Claim 9. Does not name the similar delete-and-recreate case (a non-atomic rewrite of an ancestor's CLAUDE.md), which the race option now skips silently when find's stat lands in the gap. Before the change, that case failed the walk only if find hit the gap.

paraphrased — no quote available because this is POSIX readdir semantics (an entry added or removed after opendir may or may not be returned), not code in this repo.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1556-1559`, `:1584`

---

## Claim 10: "top_files NAME DIR...: array NAME gets the files and links (-xtype f or l, links followed only as DIRs: -H) directly in each DIR ... an entry gone between find's readdir and its stat of a file is skipped ... It fails when find reports any error, a vanished directory entry included"

**Location:** `scripts/lib/dev-cycle-read.sh:1579-1583`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a caller of top_files
**Scope:** Covers the skip and failure semantics (verified in R3 and R5). Does not hold strictly for "directly in each DIR": when a DIR is a link whose target is gone, find -H lists the DIR argument itself (depth 0) and exits 0 (Claim 8).

The skip and failure halves are confirmed by Claims 4 and 5. The depth-0 exception is the one config_seeds' recheck exists to catch. Precise version: "...directly in each DIR (or the DIR itself, when it is a link whose target is gone)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1584`; `LOGS/race-probe.txt`

---

## Claim 11: Test header comment: the shim "deletes every other vic* ... find read all their names before that first visit ... The shim logs each listing's exit status. With T_ONCE it races only on the first listing of a walk ... T_RMTOP=drop also drops it from the start points"

**Location:** `test/scripts/build-loop-check.bats:725-732`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a future editor of the test
**Scope:** Covers the shim's behaviour (`:736-743`). Does not establish behaviour under any find other than the PATH one bats resolves (`/usr/bin/find`).

The shim's T_ONCE branch is `if [[ -n "\${T_ONCE:-}" && -e "$a/shim/fired" ]]; then "$real" ...; else touch "$a/shim/fired"; ...` (`:741-742`), and the logging line is `rc=\$?; echo "\$rc" >> "$a/shim/log"` (`:743`). `config_seeds` runs once per walk (the walks cache: `imported_names` at `scripts/lib/dev-cycle-read.sh:1710`, `main_imports` at `:1786`), and top_files is the lib's only `find -H` (grep). So every log line is one try. R5 confirms this: `[0 ]` for files and `[1 0 ]` for directories.

**Evidence:** `test/scripts/build-loop-check.bats:734-745`; `LOGS/dump.txt`

---

## Claim 12: "Files: -ignore_readdir_race skips each, so no listing fails and none is retried."

**Location:** `test/scripts/build-loop-check.bats:746`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a future editor of the test
**Scope:** Covers both walks. The assertion `! grep -qvx 0 "$a/shim/log"` would also pass on a missing log, but `:752`'s victim count independently shows that the shim ran.

R5 logged `DUMP file tree log=[0 ] vic=0` and `DUMP file main log=[0 ] vic=0`. In the `norace` mutant, this assertion failed with `a listing failed: 1 / 0`.

**Evidence:** `test/scripts/build-loop-check.bats:746-754`; `LOGS/dump.txt`, `LOGS/mut-norace.txt`

---

## Claim 13: "Directories: findutils still reports one, so the first listing fails and the retry, without the race, completes; the failed try's message is dropped."

**Location:** `test/scripts/build-loop-check.bats:755-756`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a future editor of the test
**Scope:** Covers both walks. The `head -2` assertion (`:761`) is not vacuous: the log holds exactly two lines.

R5 logged `DUMP dir tree log=[1 0 ]` and `DUMP dir main log=[1 0 ]`, and `[ -z "$stderr" ]` held. A one-line log would give `"1 "`, not `"1 0 "`. The `noretry` mutant failed here (`:759`) with `find: '.../vic2': No such file or directory`.

**Evidence:** `test/scripts/build-loop-check.bats:755-762`; `LOGS/dump.txt`, `LOGS/mut-noretry.txt`

---

## Claim 14: The `head -3 ... = "1 1 1 "` assertion pins three failed tries for an unreadable top

**Location:** `test/scripts/build-loop-check.bats:767-768`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a merge reviewer judging test strength
**Scope:** Covers the unreadable-top case. The log is reset just before it (`rm -f "$a/shim/log"`, `:767`), and R5 shows exactly three lines. Does not cover the T_RMTOP cases: they assert no log, and the log is not reset before them.

R5 logged `DUMP perm tree log=[1 1 1 ]` and `DUMP perm main log=[1 1 1 ]`.

**Evidence:** `test/scripts/build-loop-check.bats:766-773`; `LOGS/dump.txt`

---

## Claim 15: "Any other error in the same listing fails closed, after three tries: an unreadable top, and a top that vanished."

**Location:** `test/scripts/build-loop-check.bats:764-765`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a future editor of the test
**Scope:** Covers the unreadable top and T_RMTOP=1 (three failed tries each). Does not hold for T_RMTOP=drop: there, one clean try succeeds and the -d recheck fails the walk.

R5's drop rows end in `... 0 ]` with empty stderr. Precise version: "...after three tries (an unreadable top, a removed top), or through the -d recheck (a removed top find skipped)".

**Evidence:** `test/scripts/build-loop-check.bats:769-772`; `LOGS/dump.txt`

---

## Claim 16: (commit d2dc88c9) "The affected suites run after ba5d2d1d still failed build-loop-check tests 43 and 45 with `find: '/tmp/tmp.XXXX': No such file or directory`, a session's mktemp -d directory" and Notes "(2 of ~240 tests in one run)"

**Location:** commit d2dc88c9 message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** a merge reviewer weighing how often the race happens
**Scope:** Covers the run log `/home/node/.claude/jobs/00bcf178/tmp/q145/suites.log`. It is a ba5d2d1d-era run: its test 41 carries ba5d2d1d's title, "skips an entry ... and still fails closed". Does not establish test 45's message, or that the vanished name was a directory.

The log has `1..238`, and the only failures are `not ok 43` and `not ok 45`. Test 43's output has `find: '/tmp/tmp.Hblz7Uiz3O': No such file or directory`. Test 45's entry shows only the failed `[ -z "$stderr" ]` line and none of its stderr. So "43 and 45 with `find: ...`" is confirmed for 43 only. "A session's mktemp -d directory" is an inference. A file that find stat'd before its -xtype stat is also reported under the option (Claim 17), and a bare `tmp.XXXX` name fits `mktemp` as well as `mktemp -d`. "2 of ~240" matches 2 of 238.

**Evidence:** `/home/node/.claude/jobs/00bcf178/tmp/q145/suites.log:8`, `:51-60`

---

## Claim 17: (commit d2dc88c9) "Probed on findutils 4.9.0: -ignore_readdir_race skips a vanished file but still reports a directory that vanished between readdir and stat (and a file that vanished between find's stat and -xtype's), with exit 1."

**Location:** commit d2dc88c9 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a maintainer deciding whether the retry can be removed
**Scope:** Covers 4.9.0. For the stat-to-xtype case, find's stat was forced with `-printf '%s'`. Does not establish when find stats an entry on its own before -xtype: with no forced stat, a file deleted just before its own -xtype was skipped silently (`f-self-yes`, `rc=0`).

R4, with the option set, a stat forced, and then self-delete: `size=1`, then `/usr/bin/find: 'B/f-self-yes/v3': No such file or directory` and `rc=1`. Links behave the same (`l-self-yes`). The directory half is confirmed by Claim 4.

**Evidence:** `LOGS/probe3.txt`, `LOGS/race-probe.txt`

---

## Claim 18: (commit d2dc88c9) "a persistent error (permission denied, link loop, missing top) fails all three and the walk, with the last try's message. The -d recheck of the tops stays."

**Location:** commit d2dc88c9 message
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a merge reviewer
**Scope:** Same coverage as Claims 5 and 6. Does not cover transient errors (Claim 1b).

R5 shows one `Permission denied` message after `[1 1 1 ]`. `:1562` keeps the recheck.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1561-1562`; `LOGS/dump.txt`, `LOGS/loop-probe.txt`

---

## Claim 19: (commit d2dc88c9) "Mutation-checked: main's lib, no retry, no -ignore_readdir_race, and no -d recheck each fail the test."

**Location:** commit d2dc88c9 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a merge reviewer judging test strength
**Scope:** Covers the four named mutants plus a fifth (stderr not dropped). Does not establish detection of a mutant that keeps a failed try's partial output. nul_list's reset makes that impossible without editing nul_list.

R2 failures, one per mutant. Main's lib failed at the file case (`:749`) with four ENOENT messages. No retry failed at the directory case (`:759`). No -ignore_readdir_race failed at the file log assertion (`:753`). No -d recheck failed at T_RMTOP=drop (`:770`). The extra `nodrop` mutant failed at `:759`. R1 (HEAD) passed.

**Evidence:** `LOGS/head.txt`, `LOGS/mut-main.txt`, `LOGS/mut-noretry.txt`, `LOGS/mut-norace.txt`, `LOGS/mut-nod.txt`, `LOGS/mut-nodrop.txt`

---

## Claim 20: (commit 0d573a7b) "comment-only ... Each ancestor below no reader root is a top, not every ancestor; the -d recheck also catches a linked top whose target vanished ...; config_seeds' header names the recheck as a return-1 cause." Notes: "2a, 5a and 15 ... were already addressed by d2dc88c9"

**Location:** commit 0d573a7b message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** a merge reviewer
**Scope:** Covers the commit's diff and the i1 mapping. Does not hold for i1 Claim 15: it is a commit subject (ba5d2d1d), and d2dc88c9 supersedes it in history without changing it.

`git show --stat 0d573a7b` lists only `scripts/lib/dev-cycle-read.sh | 20 +++++++++++---------`. Every +/- line is a `#` comment (a grep for non-comment changed lines is empty). The three listed edits are present (Claims 2, 3, 8).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1506-1509`, `:1542-1559`

---

## Claim 21: dev-cycle.bats function list adds `top_files`

**Location:** `test/scripts/dev-cycle.bats:1115`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a future editor of the lib
**Scope:** Covers the lib defining `top_files` when sourced. Does not establish anything beyond the list check.

R7 passes at HEAD. Against main's lib it fails with `missing top_files`.

**Evidence:** `test/scripts/dev-cycle.bats:1106-1121`; `LOGS/devcycle-fnlist.txt`, `LOGS/devcycle-fnlist-mainlib.txt`

---

## Claim 22: FP-173 "... cause:overbroad-guard fix:narrow-the-guard ref:ba5d2d1d"

**Location:** `docs/thoughts/failure-patterns.md:315`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** a future session matching failure patterns
**Scope:** Covers the vocabulary (verified in i1 Claim 1) and the ref. Does not hold for the ref as the complete fix: ba5d2d1d skips files only, and d2dc88c9 adds the directory retry.

A reader who follows `ref:ba5d2d1d` gets the incomplete fix. Precise version: `ref:ba5d2d1d,d2dc88c9`, or a later ref.

**Evidence:** `docs/thoughts/failure-patterns.md:315`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 1b** (`scripts/lib/dev-cycle-read.sh:833`): "any other error ... fails the walk" holds only for an error that persists across all three tries. The retry absorbs a transient one.
- **Claim 10** (`scripts/lib/dev-cycle-read.sh:1579-1583`): top_files also lists a DIR argument itself when it is a link whose target is gone.
- **Claim 15** (`test/scripts/build-loop-check.bats:764`): the T_RMTOP=drop case fails through the -d recheck after one clean try, not after three tries.
- **Claim 16** (commit d2dc88c9): only test 43's message is in the log, and "mktemp -d directory" is an inference.
- **Claim 20** (commit 0d573a7b): i1 Claim 15 (a commit subject) is superseded in history, not addressed.
- **Claim 22** (`docs/thoughts/failure-patterns.md:315`): the ref names only the files-only first fix.

### Unverifiable
(none)

## Goal-Alignment Note

The PR's goal is to stop the gate flaking when another process deletes an entry mid-listing, without letting the walk miss an existing instruction file. At HEAD the documentation matches the code on the point that matters for security. The listing used is always one complete find run that exited 0. nul_list empties the array on failure and replaces it on success, so no failed try's partial output survives (Claim 5). A persistent permission error, link loop or missing top fails all three tries, and the -d recheck covers a skipped or linked top (Claims 6-8). The test is not vacuous: its log holds exactly one line per try, and each of the five mutants fails it (Claims 13, 14, 19). All Incorrect findings from iteration 1 are resolved in the lib comments. The remaining findings are wording, plus one residue a merge reviewer should see stated: a transient error of any kind is now retried away (Claim 1b), and a file deleted and recreated during the listing can be missed (Claims 5 and 9). Neither lets the walk use an errored listing. Both are the general readdir window rather than something the retry adds.
