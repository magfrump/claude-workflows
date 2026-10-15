Commit: 29b807dc

# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-q145, branch fix/q145-ancestor-vanish)
**Scope:** `git diff main...HEAD` at 29b807dc. Code and docs/thoughts only: scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, test/scripts/dev-cycle.bats, docs/thoughts/failure-patterns.md. Also the commit messages in `git log main..HEAD`. The docs/reviews artifacts were excluded (context only).
**Checked:** 2026-10-14
**Total claims checked:** 23
**Summary:** 18 verified, 4 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Execution provenance, shared by every `executed` claim. Every command ran under `timeout` with `LC_ALL=C` and GNU findutils 4.9.0 (`/usr/bin/find`; bats resolves `find` to `/usr/bin/find`), as uid 1000. Logs are under SCRATCH=`/home/node/.claude/jobs/00bcf178/tmp/q145/review/final-r2/`:
- **E1 (HEAD test):** cwd `SCRATCH/copy` (`git archive HEAD`). Ran `timeout 900 env LC_ALL=C bats --filter 'Q-145' test/scripts/build-loop-check.bats` at 2026-10-14T21:47:55-07:00. Exit 0 (`ok 1`). Log: `SCRATCH/logs/head-test.log`.
- **E2 (mutants):** each in its own copy `SCRATCH/m-<name>`, same command, started 2026-10-14T21:48 (in `logs/mutants-start.txt`). Every mutant exited 1. Logs: `SCRATCH/logs/m-<name>.log`.
  - `main`: main's lib.
  - `noretry`: a single `top_files` call.
  - `norace`: no `-ignore_readdir_race`.
  - `nod`: no `-d` recheck loop in top_files.
  - `nodrop`: three tries with no `2>/dev/null`.
  - `two`: two tries.
- **E3 (find/top_files probes):** `timeout 60 SCRATCH/probe.sh SCRATCH/p1 SCRATCH/copy/scripts/lib/dev-cycle-read.sh` at 21:49:27, exit 0. Log: `SCRATCH/logs/probe.log`.
- **E4:** `timeout 60 SCRATCH/probe2.sh SCRATCH/p2 <lib>` at 21:51:03, exit 0. Log: `SCRATCH/logs/probe2.log`.
- **E5:** the stat-to-xtype window with and without the flag, at 21:51:14 and 21:52:07. Logs: `SCRATCH/logs/probe3.log`, `SCRATCH/logs/probe4.log`.
- **E6:** `timeout 600 env LC_ALL=C bats --filter 'sourcing the reader lib defines its functions' test/scripts/dev-cycle.bats` in `SCRATCH/copy` at 21:51:03. Exit 0. Log: `SCRATCH/logs/dev-cycle-defs.log`.

`docs/reviews/hallucination-patterns.md` was read. No logged pattern matches any claim below.

---

## Claim 1: FP-173 "find-over-shared-ancestor-dir-exits-nonzero-when-another-process-deletes-an-entry-mid-listing-gate-flakes-under-parallel-load cause:overbroad-guard fix:narrow-the-guard ref:d2dc88c9"

**Location:** `docs/thoughts/failure-patterns.md:315`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers three things: the symptom (a find over a shared ancestor exits nonzero when an entry is deleted mid-listing, so the walk fails), the use of existing taxonomy words, and that the ref exists on the branch. It does not establish that the classification is the best one, or that d2dc88c9 stays reachable from main after a squash merge.

The symptom reproduces against main's lib. E2 `main` fails with `/usr/bin/find: '.../vic2': No such file or directory` and `walk: failed` (`logs/m-main.log`). The vocabulary exists: `| 8 | \`overbroad-guard\` |` at `docs/thoughts/failure-patterns.md:68` and `| 12 | \`narrow-the-guard\` | keep the check, shrink what it rejects |` at `:93`. `d2dc88c9` is in `git log main..HEAD`.

**Evidence:** `docs/thoughts/failure-patterns.md:68`, `docs/thoughts/failure-patterns.md:93`, `docs/thoughts/failure-patterns.md:315`, `SCRATCH/logs/m-main.log`

---

## Claim 2: "The one exception is the top-level listing of ancestors and config dirs (config_seeds): an entry that vanishes between find's readdir and its stat ... is skipped, or the listing is retried, up to three tries ...; only an error-free listing is used, so any error that persists across the tries still fails the walk (Q-145)."

**Location:** `scripts/lib/dev-cycle-read.sh:828-834`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers several things: config_seeds' top-level listing being the place where a mid-listing vanish is tolerated (a file is skipped; a directory triggers a retry); the cap of three tries; and that an error present on all three tries fails the walk. It does not establish "only" for errors that are not persistent: three different transient errors in a row also fail the walk, which this sentence does not exclude (see Claim 7). It also does not establish that no other seed listing in the lib tolerates errors (the python plugin-list fallback at `:1528-1533` predates this change and is not a find, grep or realpath).

The call site is `top_files fl "${tops[@]}" 2>/dev/null || top_files fl "${tops[@]}" 2>/dev/null || top_files fl "${tops[@]}" || return 1` (`:1563`). E1 passes. Its log values cover each case: files skipped with log all `0`; directory retried with `1 0`; unreadable or missing top failing with `1 1 1`; dropped top failing with `0 0 0`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:828-834`, `scripts/lib/dev-cycle-read.sh:1563`, `SCRATCH/logs/head-test.log`

---

## Claim 3a: "config_seeds NAME ... returns 1 when a find, grep, realpath or lower_all fails; the top-level listing (top_files) fails it only when all three of its tries fail"

**Location:** `scripts/lib/dev-cycle-read.sh:1507-1510`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every `return 1` in config_seeds `:1511-1578`, read in full: the find -L listings, the top_files chain, `lower_all` with its count check, `with_at`, and the xargs `realpath` with its count check. It also covers the three-try semantics. It does not establish with_at's internal failure modes, which were not traced. The python `installed_plugins.json` read falls back silently and correctly is not named.

The three-try semantics follow from `:1563` (quoted in Claim 2). Killing the third try is detected: E2 `two` fails with `want three failed tries: 1\n1` (`logs/m-two.log`). The other return-1 sites, quoted:
- `nul_list fl find -L "${fr[@]}" ... || return 1` (`:1536`)
- `[[ ${#lo[@]} -eq ${#fl[@]} ]] || return 1` (`:1564`)
- `with_at fl "${cx[@]}" || return 1` (`:1570`)
- `realpath -mz -- && [[ ${#rl[@]} -eq ${#cx[@]} ]] || return 1` (`:1573`, excerpt; enclosing `config_seeds()` continues to `:1578`, read)

**Evidence:** `scripts/lib/dev-cycle-read.sh:1507-1578`, `SCRATCH/logs/m-two.log`

---

## Claim 3b: "(an entry that vanishes mid-listing fails one: Q-145)"

**Location:** `scripts/lib/dev-cycle-read.sh:1509-1510`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers which vanished entries fail a try. It does not establish anything beyond findutils 4.9.0.

Only a vanished **directory** entry fails a try. A vanished file is skipped and fails nothing, as the branch's own test asserts with `! grep -qvx 0 "$a/shim/log"` (`test/scripts/build-loop-check.bats:754`). E1 passes that assertion. E3 case j has three vanished dirs reported and two vanished files skipped silently, `rc=1` (`logs/probe.log`). Precise version: "a directory entry that vanishes mid-listing fails one".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1509-1510`, `test/scripts/build-loop-check.bats:747-754`, `SCRATCH/logs/probe.log`

---

## Claim 4: "Each ancestor below no reader root is a top (/tmp, when a root lies under it) ... an entry find's readdir named can be gone when find stats it, and find then reports ENOENT and exits 1 (Q-145)."

**Location:** `scripts/lib/dev-cycle-read.sh:1545-1548`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers how tops are built: ancestors outside every root that are directories (`/` included), plus config dirs. It also covers ENOENT with exit 1 from find without the flag. It does not establish whether every such ancestor is shared with other processes in practice.

`for q in "${rs[@]}"; do [[ "$d" != "$q" && "$d" != "$q"/* ]] || in=1; done` then `[[ -n "$in" || ... ]] || { os_s[a$d]=1; [[ ! -d "$d" ]] || tops+=("$d"); cf+=("${d%/}/.claude"); }` (`:1518-1519`). ENOENT with exit 1 without the flag: E5 `## without` prints `No such file or directory`, `rc=1` (`logs/probe3.log`). E2 `main` fails the same way.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1514-1522`, `SCRATCH/logs/probe3.log`, `SCRATCH/logs/m-main.log`

---

## Claim 5: "top_files skips such a file (-ignore_readdir_race), but findutils 4.9 still reports a directory that vanished that way (a session's mktemp -d), so a failed listing is run again, up to three times in all, the first two with stderr dropped."

**Location:** `scripts/lib/dev-cycle-read.sh:1549-1552`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers findutils 4.9.0's handling of a vanished file and a vanished directory under `-ignore_readdir_race`, and the shape of the retry. It does not establish that "(a session's mktemp -d)" was the real source of the original flake; that is historical.

E3 case j (`logs/probe.log`) prints `.../race/f1`, then `'.../race/d1': No such file or directory` and the same for d2 and d3, with `rc=1`. f2 and f3 were skipped silently. The mutants pin each mechanism:
- E2 `norace` fails at the file case (`a listing failed: 1`).
- E2 `noretry` fails at the directory case, reporting only the `vicN` dirs.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1549-1552`, `scripts/lib/dev-cycle-read.sh:1563`, `scripts/lib/dev-cycle-read.sh:1591`, `SCRATCH/logs/probe.log`, `SCRATCH/logs/m-norace.log`, `SCRATCH/logs/m-noretry.log`

---

## Claim 6: "Only a listing that completes without any error is used, so a retry never hides an existing file: an error that persists across the three tries (a permission error, a link loop, a missing top, a top that is no longer a directory) fails the walk"

**Location:** `scripts/lib/dev-cycle-read.sh:1552-1555`
**Type:** Error-handling / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the following:
- A failed try leaves nothing in `fl`.
- The used `fl` comes wholly from one try that succeeded.
- Each of the four named persistent errors fails all three tries.

It does not establish what a single clean listing can miss on its own (rename-in, delete-and-recreate: Claim 8), or a top swapped for a link to another directory mid-listing, which the `-d` recheck accepts.

`nul_list` replaces its target wholesale and empties it on failure: `mapfile -d '' nl_a < <("$@" && printf rc=0 || printf rc=1); [[ ... "${nl_a[-1]}" == rc=0 ]] || { nl_a=(); return 1; }` (`:1646`). The recheck also empties on failure: `{ local -n tf_a="$1"; tf_a=(); return 1; }` (`:1592`). E3 case i (`logs/probe.log`) gives:
- `nope rc=1 n=0`
- `loop rc=1 n=0`
- `real+loop rc=1 n=0` (a good DIR plus a bad one yields nothing)
- `lnk2 rc=1 n=0`

The named errors: E3 cases e, g and h each give `rc=1` (missing start point, `Too many levels of symbolic links`, `Permission denied`). E1 asserts `1 1 1` for an unreadable top and a removed top, and `0 0 0` for a dropped one.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1646`, `scripts/lib/dev-cycle-read.sh:1590-1593`, `SCRATCH/logs/probe.log`, `SCRATCH/logs/head-test.log`

---

## Claim 7: "a transient one of any kind is retried away, its message dropped."

**Location:** `scripts/lib/dev-cycle-read.sh:1555-1556`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers transient errors on tries 1 and 2 when a later try is clean. It does not cover transient errors on all three tries. Those fail the walk, and the third try's message reaches stderr.

From `:1563`, a transient error is retried away only when a later try among the three completes cleanly. Three consecutive transient failures, such as a fresh directory race on each try, return 1 with the third try's message shown. The third try has no `2>/dev/null` (`top_files fl "${tops[@]}" || return 1`, the tail of `:1563`). config_seeds' header (`:1508-1510`, Claim 3a) states this precisely. This sentence states it as unconditional. Precise version: "a transient one is retried away when a later try completes, its message dropped".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1555-1556`, `scripts/lib/dev-cycle-read.sh:1563`

---

## Claim 8: "Not covered, as with any directory read: a file renamed in during the listing (readdir leaves a name added mid-read unspecified), or one deleted and re-created there (a non-atomic save), which find may not see, or now skips when the gap spans its stat (i2 security F1); before Q-145 such a gap failed the walk only when it fell between find's readdir and its stat."

**Location:** `scripts/lib/dev-cycle-read.sh:1556-1561`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers three things: that HEAD now silently skips a file absent at its stat; that main failed on the same file (ENOENT, exit 1); and the POSIX readdir rule as a reference. The "only when" about main is a necessary condition, read as "the absence interval began after readdir and included the stat". It does not establish timings for real editors' saves, and the rename-in case was not executed.

HEAD skips the file: E3 case j (vanished files skipped, `logs/probe.log`) and E5 `## with` `rc=0` (`logs/probe3.log`). Main errored on it: E5 `## without` `rc=1`, and E2 `main`. The readdir rule is POSIX `readdir()` ("If a file is removed from or added to the directory after the most recent call to opendir() or rewinddir(), whether a subsequent call to readdir() returns an entry for that file is unspecified"); paraphrased — no quote available because it is an external standard, not repo code.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1556-1561`, `SCRATCH/logs/probe.log`, `SCRATCH/logs/probe3.log`, `SCRATCH/logs/m-main.log`

---

## Claim 9: "the first two with stderr dropped" (as implemented by `2>/dev/null` on the first two calls only)

**Location:** `scripts/lib/dev-cycle-read.sh:1563`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the redirection's reach. Each `2>/dev/null` binds to its own simple command in the `||` list, so the third call and the rest of config_seeds keep stderr. It does not establish what callers further up do with config_seeds' stderr.

E4 case m runs the same three-call chain on an unreadable dir. Exactly one `find: '.../unr': Permission denied` reaches stderr, from the third try (`logs/probe2.log`). Mutant E2 `nodrop` fails the test's `[ -z "$stderr" ]` with the dropped messages visible (`logs/m-nodrop.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1563`, `SCRATCH/logs/probe2.log`, `SCRATCH/logs/m-nodrop.log`

---

## Claim 10: "top_files NAME DIR...: array NAME gets the files and links (-xtype f or l) directly in each DIR, read through nul_list; find also prints a DIR that is itself a link (at depth 0, where -xtype sees the link: -H follows it only to list its entries), so such a DIR is in NAME too."

**Location:** `scripts/lib/dev-cycle-read.sh:1580-1583`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers what NAME holds for a plain DIR, for a linked DIR with a live target, and for a caller-local NAME (nameref). It does not establish how config_seeds' isstart treats the linked DIR's own path once it is in `fl`.

`nul_list "$1" find -H "${@:2}" -maxdepth 1 -ignore_readdir_race '(' -xtype f -o -xtype l ')' -print0` (`:1591`). E3 case c prints `.../lnk` and then `.../lnk/a.md`, `rc=0`. Through the lib, E3 case i gives `lnk rc=0 n=2 [.../lnk .../lnk/a.md]`. With a caller-local array, `nested-local rc=0 n=1 [.../real/a.md]` (`logs/probe.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1580-1593`, `SCRATCH/logs/probe.log`

---

## Claim 11: "An entry gone between find's readdir and its stat of a file is skipped (-ignore_readdir_race, GNU find). It fails, with NAME empty, when find reports any error (a directory entry that vanished included ...) or a DIR is no longer a directory after the listing: one that vanished under a find that skips a missing start point silently, or a linked DIR whose target vanished, which find 4.9 lists as the link itself and exits 0"

**Location:** `scripts/lib/dev-cycle-read.sh:1583-1589`
**Type:** Error-handling / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each cited findutils 4.9.0 behaviour and the failure contract. It does not establish that any find in use skips a missing start point silently. GNU 4.9.0 does not: E3 case e reports it with `rc=1`, so that branch is defensive. It is exercised only through the test's `drop` shim.

The behaviours, from E3, E4 and E5 (`logs/probe.log`, `logs/probe2.log`, `logs/probe4.log`):
- Vanished file skipped: E3 case j.
- Vanished directory reported: E3 case j, `rc=1`.
- Linked DIR with vanished target: E3 case d prints `.../lnk2`, `rc=0`. Through the lib, `lnk2 rc=1 n=0`.
- Dangling link still listed: E4 case l.

The recheck is quoted in Claim 6. Removing it is detected: E2 `nod` gives `want: walk: failed` / `walk: ok` in the SHIM_RMTOP loop (`logs/m-nod.log`). That loop can only be the `drop` iteration, since find reports a missing start point (E3 case e).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1583-1593`, `SCRATCH/logs/probe.log`, `SCRATCH/logs/probe2.log`, `SCRATCH/logs/m-nod.log`

---

## Claim 12: "a shim adds, to the -H top-level listing only, a clause ... find read all their names before that first visit, so it stats each deleted one later and gets ENOENT. The shim logs each listing's exit status."

**Location:** `test/scripts/build-loop-check.bats:725-729`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers four things: that only the `-H` listing is shimmed; that the deleted names were read before deletion (find reports them by name); that the log records one status per `-H` call; and that the `-H` call is unique in the lib. It does not establish fts internals beyond what that observed output implies.

The shim's first line is `[[ "\${1:-}" == -H ]] || exec "$real" "\$@"` (`:737`), and `rc=\$?; echo "\$rc" >> "$a/shim/log"` (`:742`). `grep -n 'find -H'` over `scripts/lib/*.sh` and `scripts/*.sh` finds only `:1591`. Against main's lib (E2 `main`), find prints ENOENT for `vic1` to `vic4` by name, so it had read each name before the clause deleted it.

**Evidence:** `test/scripts/build-loop-check.bats:735-743`, `scripts/lib/dev-cycle-read.sh:1591`, `SCRATCH/logs/m-main.log`

---

## Claim 13: "a clause that runs at the first entry of the fixture's ancestor and deletes every other vic* there"

**Location:** `test/scripts/build-loop-check.bats:726-727`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers when the clause runs. It does not change the race's effect on the files case: the first run is the one that matters.

The clause is `'(' -path "$a/*" -exec sh -c 'for f in "\$1"/vic*; do [ "\$f" = "\$2" ] || rm -rf "\$f"; done' sh "$a" {} ';' -false ')' -o "\$@"` (`:741`, excerpt; the shim continues to `:743`, read). Nothing limits it to the first entry. It runs at every visited entry under `$a`, including those under the `$a/.claude` top. Later runs delete the first-visited victim too, which is why `:752-753` asserts only an upper bound (`-le 1`). E4 case n shows a `-path ... -exec ... -false` clause running once per depth-1 entry (`visits=3` for 3 entries, `logs/probe2.log`). Precise version: "a clause that runs at each entry under the fixture's ancestor; the first run deletes every other vic*".

**Evidence:** `test/scripts/build-loop-check.bats:741`, `test/scripts/build-loop-check.bats:752-753`, `SCRATCH/logs/probe2.log`

---

## Claim 14: "With SHIM_ONCE it races only on the first listing of a walk. With SHIM_RMTOP it instead removes the ancestor's .claude, a top config_seeds already found to be a directory, first; SHIM_RMTOP=drop also drops it from the start points, as a find that skipped a missing start point silently would, which leaves top_files' -d recheck to catch it. (SHIM_*, not T_*: the shim reads them, not imps.)"

**Location:** `test/scripts/build-loop-check.bats:729-733`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each knob's effect and the T_ convention. It does not establish that the race clause is skipped under SHIM_RMTOP. It is still added (`fired` exists and SHIM_ONCE is unset), but with no `vic*` present it deletes nothing, so "instead" holds in effect.

The knobs, from `:738-741`:
- `[[ -z "\${SHIM_RMTOP:-}" || ! -d "$a/.claude" ]] || rmdir "$a/.claude" || exit 9` removes the top before find runs.
- The arg loop drops `$a/.claude` when `SHIM_RMTOP == drop`.
- `if [[ -n "\${SHIM_ONCE:-}" && -e "$a/shim/fired" ]]; then "$real" ...` skips the race clause once `fired` is set. `fired` is cleared before each `imps`, and each `imps` call runs one walk (`if { [[ "$w" == main ]] && main_imports; } || { [[ "$w" == tree ]] && imported_names; }`, `:27`).

config_seeds adds a top only after `-d` (`:1519`, `:1523`). imps reads the `T_` variables, e.g. `[[ -z "${T_READER_ROOTS+set}" ]] || ...` (`:23`). E1 passes, and E2 `nod` shows the drop case caught only by the recheck.

**Evidence:** `test/scripts/build-loop-check.bats:20-28`, `test/scripts/build-loop-check.bats:735-743`, `scripts/lib/dev-cycle-read.sh:1519`, `SCRATCH/logs/head-test.log`, `SCRATCH/logs/m-nod.log`

---

## Claim 15: Test assertions and inline comments. Shim log `0` (files), `1 0` (directory retry), `1 1 1` (unreadable top, removed top), `0 0 0` (dropped top). "Files: -ignore_readdir_race skips each, so no listing fails and none is retried", "the failed try's message is dropped", "find reports the missing top (1); with it dropped, find succeeds (0) and the recheck fails each try". The test fails against main's lib and the mutants.

**Location:** `test/scripts/build-loop-check.bats:747-774`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the test passing at HEAD and each listed mutant failing at the expected assertion. It does not establish full-suite results (Claim 17) or reliability under the concurrent health-check load beyond this one run.

E1 passes. Each E2 mutant fails at the assertion for its mechanism:
- `main` and `noretry`: `[ -z "$stderr" ]` with ENOENT messages (`:750` and `:760`).
- `norace`: `a listing failed: 1` (`:754`).
- `nod`: `want walk failed` (`:771`).
- `nodrop`: stderr not empty (`:760`).
- `two`: `want three failed tries: 1 1` (`:769`).

**Evidence:** `test/scripts/build-loop-check.bats:724-777`, `SCRATCH/logs/head-test.log`, `SCRATCH/logs/m-main.log`, `SCRATCH/logs/m-noretry.log`, `SCRATCH/logs/m-norace.log`, `SCRATCH/logs/m-nod.log`, `SCRATCH/logs/m-nodrop.log`, `SCRATCH/logs/m-two.log`

---

## Claim 16: (commit b9f1d2d1) "the -d recheck moves from the config_seeds call site into top_files, which empties NAME and fails when a DIR is no longer a directory ...; the recheck is now retried like any other failure", "the listing comment names a non-atomic save ... as not covered, as on main when the gap spans readdir", "The test's vanished-top cases now assert three tries each (`1 1 1`; `0 0 0` ...)", "mutants (main's lib, no retry, no -ignore_readdir_race, no recheck) each fail the Q-145 test", and the Note's cost of two extra listings

**Location:** commit b9f1d2d1 message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the listed body claims at HEAD. The test and code are unchanged since b9f1d2d1 apart from comment-only 29b807dc. It does not cover "Affected suites 238/238" (Claim 17).

The recheck sits in top_files (`:1592`) and nowhere at the call site (`:1563`). The test asserts `1 1 1` and `0 0 0` (`:769`, `:774`). The four named mutants fail (E2). The two extra listings follow from three tries on a persistent recheck failure (log `0 0 0`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1563`, `scripts/lib/dev-cycle-read.sh:1592`, `test/scripts/build-loop-check.bats:769-774`, `SCRATCH/logs/m-*.log`

---

## Claim 17: (commit b9f1d2d1) "Affected suites 238/238"

**Location:** commit b9f1d2d1 message
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Not checked. It does not establish anything about suites other than the Q-145 test (E1) and the dev-cycle lib-definitions test (E6), which both pass.

Re-running the affected suites under the current load (19+) was out of proportion for a final confirming pass, and the health check may be running against the worktree. Verifying this needs a full affected-suite run at 29b807dc.

**Evidence:** `SCRATCH/logs/head-test.log`, `SCRATCH/logs/dev-cycle-defs.log`

---

## Claim 18: (commit 29b807dc) "find prints it: at depth 0 -xtype sees the link (re-probed: a linked top with a live target prints as itself and then its entries, exit 0) ... comment-only; the lite finding's claim that the DIR is not in the array is wrong"

**Location:** commit 29b807dc message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the probe result, the DIR being in the array, and the commit being comment-only. It does not establish behaviour under `-L`.

E3 case c prints `.../lnk` and then `.../lnk/a.md`, `rc=0`. Through the lib, `lnk rc=0 n=2 [.../lnk .../lnk/a.md]` (`logs/probe.log`). `git show 29b807dc` has no changed non-comment lines (the filtered diff is empty).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1580-1583`, `SCRATCH/logs/probe.log`

---

## Claim 19: (commit d2dc88c9) "Probed on findutils 4.9.0: -ignore_readdir_race skips a vanished file but still reports a directory that vanished between readdir and stat (and a file that vanished between find's stat and -xtype's), with exit 1", "Only a listing that completes without any error is used ...; a persistent error ... fails all three and the walk, with the last try's message"

**Location:** commit d2dc88c9 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the probes and the last-message behaviour on 4.9.0. The stat-to-xtype part holds only when find itself stats the entry (forced here with `-printf '%s'`). When the earlier predicate uses fts's d_type (`-type f`), the same deletion is skipped silently. top_files' expression has no predicate before `-xtype`. It does not cover the historical test-43/45 observation.

E5 `probe4.log`: `size=2`, then `'.../k/f1': No such file or directory`, `rc=1`. With `-type f` in place of `-printf`, the result is `rc=0` and no message (`probe3.log` `## with`; `probe2.log` case k). The directory and file halves are as in Claim 5. Only the last message gets through, per E4 case m (Claim 9).

**Evidence:** `SCRATCH/logs/probe2.log`, `SCRATCH/logs/probe3.log`, `SCRATCH/logs/probe4.log`, `SCRATCH/logs/probe.log`

---

## Claim 20: (commit ba5d2d1d) subject "ancestor listing skips entries that vanish mid-listing" and body "config_seeds lists every ancestor of each reader root and every config dir at depth 1"

**Location:** commit ba5d2d1d message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the commit message as history. It does not ask for a rewrite: later commits in the same branch (d2dc88c9 and 0d573a7b) correct both points, and the rubric records C7 for commit-body wording.

Two points are imprecise. First, only ancestors below no reader root are tops (`:1518-1519`, Claim 4). Second, at that commit a vanished *directory* entry was still reported (E3 case j), so "skips entries" held for files only. d2dc88c9's message says so.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1514-1522`, `SCRATCH/logs/probe.log`

---

## Claim 21: (commit ba5d2d1d) "Probed on findutils 4.9.0: a permission error, a link loop and a missing start point are still reported with exit 1, and a dangling link is still listed by -xtype l. ... Before the fix the test fails with the flake's exact message."

**Location:** commit ba5d2d1d message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the four find behaviours on 4.9.0, and the failure against main matching the flake's message form (`find: '<path>': No such file or directory`). It does not compare against the original flake log.

E3 cases h, g and e each give `rc=1`. E4 case l lists `.../l/dang`, `rc=0`. E2 `main` gives `/usr/bin/find: '.../vic2': No such file or directory`.

**Evidence:** `SCRATCH/logs/probe.log`, `SCRATCH/logs/probe2.log`, `SCRATCH/logs/m-main.log`

---

## Claim 22: (commit 0d573a7b) "comment-only" with its listed corrections

**Location:** commit 0d573a7b message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the commit touching only comment lines in `scripts/lib/dev-cycle-read.sh`. Its content claims are covered by Claims 3a, 4 and 11. It does not re-verify 0d573a7b's intermediate state.

`git show 0d573a7b -- scripts/lib/dev-cycle-read.sh`, filtered to non-comment `+`/`-` lines, is empty.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1507-1510`, `scripts/lib/dev-cycle-read.sh:1545`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
None.

### Mostly Accurate
- **Claim 3b** (`scripts/lib/dev-cycle-read.sh:1509-1510`): "an entry that vanishes mid-listing fails one". Only a vanished *directory* entry fails a try; a vanished file is skipped. Say "a directory entry".
- **Claim 7** (`scripts/lib/dev-cycle-read.sh:1555-1556`): "a transient one of any kind is retried away". This holds only when a later try is clean; three transient failures in a row fail the walk with the third message. Add "when a later try completes".
- **Claim 13** (`test/scripts/build-loop-check.bats:726-727`): the shim clause runs at every entry under the ancestor (and its .claude), not only the first; the first run does the deleting.
- **Claim 20** (commit ba5d2d1d): "every ancestor" and "skips entries" are both corrected by later commits on the branch. History only, no action.

### Unverifiable
- **Claim 17** (commit b9f1d2d1): "Affected suites 238/238". Needs a full affected-suite run at 29b807dc.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved to the OUTPUT PATH below, structured per the code-fact-check skill, first line `Commit: 29b807dc`.
- Answered: yes. All six focus areas were checked, with execution for the find behaviours, the retry and stderr scope, the test and six mutants.
- Out of scope: the full affected-suite run (load, and a concurrent health check); the docs/reviews artifacts, as instructed.
- Escalate: nothing. No finding hides an existing file. The three Mostly accurate comment items are wording only.
- Decisions I made: I counted the d2dc88c9 stat-to-xtype parenthetical as Verified. It holds when find stats the entry itself, and my first `-type f` probe, which reads d_type, gave a false negative. I treated the SHIM_RMTOP "instead" as accurate in effect, because the still-added race clause has no victims to delete.
