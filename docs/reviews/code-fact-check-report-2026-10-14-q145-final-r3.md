Commit: 29b807dc

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q145 (branch fix/q145-ancestor-vanish, HEAD 29b807dc)
**Scope:** `git diff main...HEAD` code + docs/thoughts (scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, test/scripts/dev-cycle.bats, docs/thoughts/failure-patterns.md) and commit messages `git log main..HEAD`; docs/reviews artifacts excluded. Final confirming pass, replicate r3 of k=3.
**Checked:** 2026-10-14 (executions 2026-10-15T04:48Z to 04:52Z UTC)
**Total claims checked:** 27
**Summary:** 20 verified, 4 mostly accurate, 0 stale, 1 incorrect, 2 unverifiable

Execution environment: GNU findutils 4.9.0 (`/usr/bin/find`; bash resolves `find` to `/usr/bin/find`, interactive zsh's `find` is bfs 4.1.1 and was not used), uid 1000 (non-root, so `chmod 000` denies reads). All runs from an archive copy (`git archive HEAD | tar -x`) at `/home/node/.claude/jobs/00bcf178/tmp/q145/review/final-r3/src` (cwd for the tests) or under the scratch dir; every command ran under `timeout` and none is left running. Captured logs (all under `/home/node/.claude/jobs/00bcf178/tmp/q145/review/final-r3/logs/`):

- `probe-findutils.log`: `timeout 120 bash final-r3/probe.sh final-r3/probe`, cwd scratch, exit 0, 2026-10-15T04:48:42Z (race of files vs directories with and without `-ignore_readdir_race`, linked DIR live and dangling, missing start, permission, link loops, dangling link).
- `probe-stat-xtype.log`: bash loop over `-type f`, `-size`, `-perm`, `-links` before `-exec rm` and `-xtype f`, cwd `final-r3/probe2`, exit 0, 2026-10-15T04:49Z.
- `test-head.log`: `timeout 500 env LC_ALL=C bats --filter 'Q-145' test/scripts/build-loop-check.bats`, cwd `final-r3/src`, exit 0, 2026-10-15T04:49:29Z.
- `mutants.log`: `timeout 590 bash final-r3/mutants.sh` (7 mutant copies, each running the same bats command), exit 0 overall, 2026-10-15T04:50:01Z to 04:50:25Z.
- `test-instrumented.log` + `shim-trace.log`: the same bats command in a copy whose shim also appends each listing's rc, SHIM_* values and whether `fired` existed, cwd `final-r3/inst`, exit 0, 2026-10-15T04:50:54Z.
- `stderr-scope.out` / `stderr-scope.err`: `timeout 20 bash -c 'n=0; f() {...}; f x 2>/dev/null || f x 2>/dev/null || f x || echo ...'`, exit 0, 2026-10-15T04:52:03Z.

Hallucination log `docs/reviews/hallucination-patterns.md` read; no logged pattern matches any claim here.

---

## Claim 1: "FP-173 2026-10-14 symptom:find-over-shared-ancestor-dir-exits-nonzero-when-another-process-deletes-an-entry-mid-listing-gate-flakes-under-parallel-load cause:overbroad-guard fix:narrow-the-guard ref:d2dc88c9"

**Location:** `docs/thoughts/failure-patterns.md:315`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the symptom matches the reproduced failure, that both vocabulary terms are defined, and that ref d2dc88c9 exists on the branch and contains the fix; does not establish that "narrow-the-guard" is the best category for a retry (taxonomy judgment, not checkable).
**Legibility-target:** for-orchestrator-synthesis

The vocabulary is defined: `| 8 | \`overbroad-guard\` | the check was correct but rejected legitimate input as well |` (`docs/thoughts/failure-patterns.md:68`) and `| 12 | \`narrow-the-guard\` | keep the check, shrink what it rejects |` (`:93`). d2dc88c9 is in `git log main..HEAD` ("retry the top-level listing when a directory vanishes mid-listing"). The symptom reproduces: main's lib under the test's shim fails the walk with `/usr/bin/find: '/tmp/bats-run-mKlpJS/test/1/vic2': No such file or directory` (`mutants.log`, mutant `main`).

**Evidence:** `docs/thoughts/failure-patterns.md:68`, `docs/thoughts/failure-patterns.md:93`, `docs/thoughts/failure-patterns.md:315`, `final-r3/logs/mutants.log`

---

## Claim 2: "The one exception is the top-level listing of ancestors and config dirs (config_seeds): an entry that vanishes between find's readdir and its stat (another process's temp file in /tmp) is skipped, or the listing is retried, up to three tries, since a name no longer there holds nothing to load"

**Location:** `scripts/lib/dev-cycle-read.sh:828-832`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skip-or-retry mechanism and the three-try bound; does not establish the rationale for an entry deleted and re-created with the gap spanning find's stat, which is skipped although a name is there again to load (disclosed only at `:1557-1561`).
**Legibility-target:** for-author

Mechanism verified: the call is `top_files fl "${tops[@]}" 2>/dev/null || top_files fl "${tops[@]}" 2>/dev/null || top_files fl "${tops[@]}" || return 1` (`scripts/lib/dev-cycle-read.sh:1563`), and the probe shows a vanished file skipped (`== race kind=file irr rc=0`) while a vanished directory fails a try (`== race kind=dir irr rc=1`) (`probe-findutils.log`). The rationale "a name no longer there holds nothing to load" does not hold for a non-atomic save whose gap spans the stat: under `-ignore_readdir_race` that file is skipped silently with exit 0 and the listing is used, although the file exists again afterwards (paraphrased — no quote available because this is a timing consequence of `-ignore_readdir_race` combined with the success path at `:1563`, not a single line). The config_seeds comment names this case; the walk-level header does not. Precise version: add "(not covered: a file deleted and re-created with the gap spanning find's stat; config_seeds' comment)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:826-834`, `scripts/lib/dev-cycle-read.sh:1557-1563`, `final-r3/logs/probe-findutils.log`

---

## Claim 3: "only an error-free listing is used, so any error that persists across the tries still fails the walk (Q-145)"

**Location:** `scripts/lib/dev-cycle-read.sh:832-834`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that a failed try leaves no partial listing in `fl` and that three failed tries return 1 from config_seeds (walk fails) for a permission error, a missing top and a top dropped from find's start points; does not establish behaviour of errors in the other seed listings (unchanged find -L calls).
**Legibility-target:** for-orchestrator-synthesis

`nul_list` empties the array on any failure: `[[ ${#nl_a[@]} -gt 0 && "${nl_a[-1]}" == rc=0 ]] || { nl_a=(); return 1; }` (`scripts/lib/dev-cycle-read.sh:1646`); top_files' recheck empties it too: `[[ -d "$tf_d" ]] || { local -n tf_a="$1"; tf_a=(); return 1; }` (`:1592`); after the third failure `|| return 1` (`:1563`). Executed: the shim trace shows three listings with `rc=1` for the unreadable top, three `rc=1` for `rmtop=1`, three `rc=0` for `rmtop=drop`, each case ending in `want walk failed` passing (`shim-trace.log`, `test-head.log` ok).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1563`, `scripts/lib/dev-cycle-read.sh:1590-1593`, `scripts/lib/dev-cycle-read.sh:1646`, `test/scripts/build-loop-check.bats:765-775`, `final-r3/logs/shim-trace.log`, `final-r3/logs/test-head.log`

---

## Claim 4a: "config_seeds NAME: ... It returns 1 when a find, grep, realpath or lower_all fails; the top-level listing (top_files) fails it only when all three of its tries fail"

**Location:** `scripts/lib/dev-cycle-read.sh:1507-1509`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each `|| return 1` in the complete config_seeds body (`:1511-1579`) and the three-try chain; does not establish the python3 plugin-list read, which falls back rather than failing and which the header does not claim.
**Legibility-target:** for-orchestrator-synthesis

The returns are: the three `find -L` listings (`nul_list fl find -L "${fr[@]}" ... || return 1`, `:1537-1541`), the top-level chain (`:1563`), `lower_all` with its count check (`[[ ${#fl[@]} -eq 0 ]] || nul_list lo lower_all "${fl[@]}" && [[ ${#lo[@]} -eq ${#fl[@]} ]] || return 1`, `:1564`), `with_at fl "${cx[@]}" || return 1` (`:1570`; with_at runs `grep -lZF -e @`, `:1367`) and the `xargs ... realpath -mz` count check (`:1573`). The python3 read uses `if nul_list fl python3 ...; then ... else ... fi` (`:1529-1535`), not a return.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1507-1579`, `scripts/lib/dev-cycle-read.sh:1362-1368`

---

## Claim 4b: "(an entry that vanishes mid-listing fails one: Q-145)"

**Location:** `scripts/lib/dev-cycle-read.sh:1509-1510`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which vanishing entries fail a try; does not establish anything about the other listings.
**Legibility-target:** for-author

A vanishing file does not fail a try: the probe gives `== race kind=file irr rc=0` and the test's file case logs a single `0` per walk (`shim-trace.log`: `rc=0 once= rmtop= fired_before=n`). Only a vanished directory (`== race kind=dir irr rc=1`), or a file that vanishes after find's own stat but before `-xtype`'s (`pre=[-size -100k] irr=[-ignore_readdir_race] rc=1`, `probe-stat-xtype.log`), fails one. Precise version: "a directory entry that vanishes mid-listing fails one".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1509-1510`, `final-r3/logs/probe-findutils.log`, `final-r3/logs/probe-stat-xtype.log`, `final-r3/logs/shim-trace.log`

---

## Claim 5: "Each ancestor below no reader root is a top (/tmp, when a root lies under it), and other processes' files come and go there: an entry find's readdir named can be gone when find stats it, and find then reports ENOENT and exits 1 (Q-145)."

**Location:** `scripts/lib/dev-cycle-read.sh:1545-1548`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the top-selection loop and find's behaviour without `-ignore_readdir_race`; does not establish which roots exist in production.
**Legibility-target:** for-orchestrator-synthesis

The loop adds an ancestor only when no root contains it: `for q in "${rs[@]}"; do [[ "$d" != "$q" && "$d" != "$q"/* ]] || in=1; done` then `[[ -n "$in" || ... ]] || { os_s[a$d]=1; [[ ! -d "$d" ]] || tops+=("$d"); ...}` (`scripts/lib/dev-cycle-read.sh:1518-1519`). Without the flag a raced file gives `/usr/bin/find: 'top/vic1': No such file or directory` and `== race kind=file noirr rc=1` (`probe-findutils.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1511-1520`, `final-r3/logs/probe-findutils.log`

---

## Claim 6: "top_files skips such a file (-ignore_readdir_race), but findutils 4.9 still reports a directory that vanished that way (a session's mktemp -d), so a failed listing is run again, up to three times in all, the first two with stderr dropped."

**Location:** `scripts/lib/dev-cycle-read.sh:1549-1552`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers findutils 4.9.0's file-vs-directory behaviour under the flag and the three-call chain; does not establish behaviour of other findutils versions.
**Legibility-target:** for-orchestrator-synthesis

Probe: `== race kind=file irr rc=0` (no message) vs `/usr/bin/find: 'top/vic1': No such file or directory` ... `== race kind=dir irr rc=1` (`probe-findutils.log`). The chain is quoted in Claim 2 (`:1563`). In the test's directory case the trace shows `rc=1 once=1 ... fired_before=n` then `rc=0 once=1 ... fired_before=y`, with empty stderr asserted (`test/scripts/build-loop-check.bats:760`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1549-1552`, `scripts/lib/dev-cycle-read.sh:1563`, `final-r3/logs/probe-findutils.log`, `final-r3/logs/shim-trace.log`

---

## Claim 7: the first two calls' `2>/dev/null` drops only those tries' stderr (brief item 4; comment "the first two with stderr dropped")

**Location:** `scripts/lib/dev-cycle-read.sh:1563`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash redirection scope on each function call in the `||` chain; does not establish that the third try's message is asserted by the test (it is not; the test asserts empty stderr only for the clean cases).
**Legibility-target:** for-orchestrator-synthesis

A redirection on a simple command (here a function call) applies to that command only: the same shape `f x 2>/dev/null || f x 2>/dev/null || f x` printed only `try 3 err` on stderr and `all failed n=3` on stdout (`stderr-scope.err`, `stderr-scope.out`). The mutant that drops both redirections fails the test with `/usr/bin/find: '.../vic2': No such file or directory` on stderr (`mutants.log`, mutant `keepstderr`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1563`, `final-r3/logs/stderr-scope.out`, `final-r3/logs/stderr-scope.err`, `final-r3/logs/mutants.log`

---

## Claim 8: "Only a listing that completes without any error is used, so a retry never hides an existing file: an error that persists across the three tries (a permission error, a link loop, a missing top, a top that is no longer a directory) fails the walk; a transient one of any kind is retried away, its message dropped."

**Location:** `scripts/lib/dev-cycle-read.sh:1552-1556`
**Type:** Error-handling / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the retry itself adds no hiding (a used listing is always one complete exit-0 find plus a passing recheck) and that each named error is persistent and reported with exit 1; does not establish that `-ignore_readdir_race` hides nothing (a delete-and-re-create spanning the stat is skipped, disclosed at `:1557-1561`), and "transient ... retried away" holds only when a later try succeeds.
**Legibility-target:** for-orchestrator-synthesis

`fl` is replaced only by a successful `nul_list` (`mapfile -d '' nl_a ...` with the `rc=0` sentinel, `scripts/lib/dev-cycle-read.sh:1646`) and emptied on failure (Claim 3). Probes on 4.9.0: `/usr/bin/find: 'top': Permission denied` / `== perm denied rc=1`; `/usr/bin/find: 'top/l2': Too many levels of symbolic links` ... `== link loops inside top rc=1`; `/usr/bin/find: 'top': No such file or directory` / `== missing start rc=1`; dropped top caught by the recheck (`rc=0` three times, walk failed; `shim-trace.log`). A top that is itself a loop link never becomes a top (`selfl -d: no`; tops require `-d`, `:1519`, `:1523`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1519-1523`, `scripts/lib/dev-cycle-read.sh:1563`, `scripts/lib/dev-cycle-read.sh:1590-1593`, `scripts/lib/dev-cycle-read.sh:1646`, `final-r3/logs/probe-findutils.log`, `final-r3/logs/shim-trace.log`

---

## Claim 9: "Not covered, as with any directory read: a file renamed in during the listing (readdir leaves a name added mid-read unspecified), or one deleted and re-created there (a non-atomic save), which find may not see, or now skips when the gap spans its stat (i2 security F1)"

**Location:** `scripts/lib/dev-cycle-read.sh:1556-1560`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers POSIX readdir's unspecified result for entries added after opendir and the skip that follows from `-ignore_readdir_race` when the stat lands in the gap; does not establish timing probabilities, and the re-create skip was reasoned from the probed ENOENT skip rather than raced directly.
**Legibility-target:** for-orchestrator-synthesis

POSIX readdir: whether an entry added or removed after opendir is returned is unspecified (paraphrased — no quote available because the source is the external POSIX spec, not this repo). The skip follows from the flag: a name readdir returned whose stat gets ENOENT is skipped with exit 0 (`== race kind=file irr rc=0`, `probe-findutils.log`), so a file absent at the stat instant and present again later is omitted from a listing that is then used (`:1563`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1556-1563`, `final-r3/logs/probe-findutils.log`

---

## Claim 10: "before Q-145 such a gap failed the walk only when it fell between find's readdir and its stat."

**Location:** `scripts/lib/dev-cycle-read.sh:1560-1561`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers main's listing (`nul_list fl find -H "${tops[@]}" -maxdepth 1 '(' -xtype f -o -xtype l ')' -print0 || return 1`, main `scripts/lib/dev-cycle-read.sh:1539`) and when its stat errors; does not establish main's behaviour for a gap spanning readdir (file silently missed, which b9f1d2d1's body states).
**Legibility-target:** for-author

Main had no `-ignore_readdir_race`, so it failed exactly when readdir had named the file and find's stat landed inside the delete/re-create gap (ENOENT, exit 1; `noirr` probe rc=1). A gap that falls wholly between readdir and the stat does not fail main: the stat finds the re-created file (paraphrased — no quote available because this is a timing consequence of main's find line, not a quoted behaviour). The mechanism (main failed closed on a stat ENOENT) and conclusion (only in a narrow window) are right; the window is misnamed. Precise version: "failed the walk only when the gap spanned its stat, after readdir had named the file" — the same case the branch now skips, which the current wording obscures.

**Evidence:** main `scripts/lib/dev-cycle-read.sh:1535-1542` (main's line numbers), `scripts/lib/dev-cycle-read.sh:1556-1561`, `final-r3/logs/probe-findutils.log`

---

## Claim 11: "top_files NAME DIR...: array NAME gets the files and links (-xtype f or l) directly in each DIR, read through nul_list; find also prints a DIR that is itself a link (at depth 0, where -xtype sees the link: -H follows it only to list its entries), so such a DIR is in NAME too."

**Location:** `scripts/lib/dev-cycle-read.sh:1580-1583`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listing for a plain DIR and a linked DIR with a live target on findutils 4.9.0; does not establish whether a linked DIR in NAME can ever pass config_seeds' isstart (a config dir's basename is not an instruction name; not traced further).
**Legibility-target:** for-orchestrator-synthesis

Code: `nul_list "$1" find -H "${@:2}" -maxdepth 1 -ignore_readdir_race '(' -xtype f -o -xtype l ')' -print0 || return 1` (`scripts/lib/dev-cycle-read.sh:1591`). Probe with `top -> tgt` holding `AGENTS.md` and `x`: output `top`, `top/x`, `top/AGENTS.md`, `== live linked DIR rc=0` (`probe-findutils.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1580-1593`, `final-r3/logs/probe-findutils.log`

---

## Claim 12: "An entry gone between find's readdir and its stat of a file is skipped (-ignore_readdir_race, GNU find)."

**Location:** `scripts/lib/dev-cycle-read.sh:1583-1584`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a regular file vanishing after readdir with no earlier stat by find; does not establish a file vanishing after find's own stat but before `-xtype`'s (reported with exit 1 even under the flag: `pre=[-size -100k] irr=[-ignore_readdir_race] rc=1`), which the comment does not claim.
**Legibility-target:** for-orchestrator-synthesis

`== race kind=file irr rc=0` with no message (`probe-findutils.log`); the test's file case logs `0` for every walk (`shim-trace.log`). Flag at `scripts/lib/dev-cycle-read.sh:1591` (quoted in Claim 11).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1591`, `final-r3/logs/probe-findutils.log`, `final-r3/logs/probe-stat-xtype.log`, `final-r3/logs/shim-trace.log`

---

## Claim 13: "It fails, with NAME empty, when find reports any error (a directory entry that vanished included: config_seeds retries, Q-145) or a DIR is no longer a directory after the listing: one that vanished under a find that skips a missing start point silently, or a linked DIR whose target vanished, which find 4.9 lists as the link itself and exits 0 (i1 fact-check 6a)."

**Location:** `scripts/lib/dev-cycle-read.sh:1585-1589`
**Type:** Error-handling / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both failure branches and the dangling-linked-DIR behaviour on findutils 4.9.0; does not establish that the test pins "NAME empty" on the recheck branch (a mutant that returns 1 without emptying passes the Q-145 test, harmlessly, since config_seeds discards `fl` after the third failure).
**Legibility-target:** for-orchestrator-synthesis

Find-error branch: `|| return 1` after nul_list, which empties (`:1591`, `:1646`). Recheck branch: `for tf_d in "${@:2}"; do [[ -d "$tf_d" ]] || { local -n tf_a="$1"; tf_a=(); return 1; }; done` (`:1592`). Probe after removing the link target: output `top` only, `== linked DIR target vanished rc=0 ; -d top: no` (`probe-findutils.log`). The silent-skip case is simulated by `SHIM_RMTOP=drop`; the `norecheck` mutant fails at `want walk failed` (`test/scripts/build-loop-check.bats:771`, `mutants.log`). Mutant `noempty` passed (`mutants.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1585-1593`, `scripts/lib/dev-cycle-read.sh:1646`, `final-r3/logs/probe-findutils.log`, `final-r3/logs/mutants.log`

---

## Claim 14: "a shim adds, to the -H top-level listing only, a clause that runs at the first entry of the fixture's ancestor and deletes every other vic* there."

**Location:** `test/scripts/build-loop-check.bats:725-727`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the shim's argument rewriting and the clause's effect; does not establish anything about non-`-H` find calls (exec'd unchanged).
**Legibility-target:** for-author

The clause is `'(' -path "$a/*" -exec sh -c 'for f in "\$1"/vic*; do [ "\$f" = "\$2" ] || rm -rf "\$f"; done' sh "$a" {} ';' -false ')' -o "\$@"` (`test/scripts/build-loop-check.bats:742`). `-path "$a/*"` matches every entry of `$a` (and the depth-0 start point `$a/.claude`), so the clause runs at every such entry, not only the first; after the first run it can still delete the first-visited victim when a later entry is visited. The effect the comment relies on holds, and the test's own check says "at most the first-visited victim is left" (`:752`). `-H only` verified: `[[ "\${1:-}" == -H ]] || exec "$real" "\$@"` (`:738`), and each walk logs exactly one listing (`shim-trace.log`). Precise version: "a clause that runs at each entry of the fixture's ancestor, the first time deleting every other vic* there".

**Evidence:** `test/scripts/build-loop-check.bats:724-744`, `test/scripts/build-loop-check.bats:752`, `final-r3/logs/shim-trace.log`

---

## Claim 15: "find read all their names before that first visit, so it stats each deleted one later and gets ENOENT."

**Location:** `test/scripts/build-loop-check.bats:727-728`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers findutils 4.9.0 (fts reads a directory's entries before visiting them); does not establish other find implementations (bfs not tested).
**Legibility-target:** for-orchestrator-synthesis

Without the flag, the same clause shape yields `top/vic2`, `/usr/bin/find: 'top/vic1': No such file or directory`, `top/a0`, `/usr/bin/find: 'top/vic3': No such file or directory`: names deleted at the first visit are still visited later and their stat fails (`probe-findutils.log`). Main's lib under the real test shows the same for `vic1`-`vic4` (`mutants.log`, mutant `main`).

**Evidence:** `test/scripts/build-loop-check.bats:742`, `final-r3/logs/probe-findutils.log`, `final-r3/logs/mutants.log`

---

## Claim 16: "The shim logs each listing's exit status. With SHIM_ONCE it races only on the first listing of a walk. With SHIM_RMTOP it instead removes the ancestor's .claude, a top config_seeds already found to be a directory, first; SHIM_RMTOP=drop also drops it from the start points ... which leaves top_files' -d recheck to catch it. (SHIM_*, not T_*: the shim reads them, not imps.)" plus ":773 find reports the missing top (1); with it dropped, find succeeds (0) and the recheck fails each try."

**Location:** `test/scripts/build-loop-check.bats:728-733`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the shim's knobs as exercised by this test (one walk per `imps` call, `fired` removed before each SHIM_ONCE call); does not establish "first listing of a walk" for a caller that does not clear `$a/shim/fired`, since the marker persists across calls.
**Legibility-target:** for-orchestrator-synthesis

Shim lines: `[[ -z "\${SHIM_RMTOP:-}" || ! -d "$a/.claude" ]] || rmdir "$a/.claude" || exit 9` (`:739`), the drop filter (`:740`), `if [[ -n "\${SHIM_ONCE:-}" && -e "$a/shim/fired" ]]; then "$real" "\${args[@]}" "\$@"` (`:741`), `rc=\$?; echo "\$rc" >> "$a/shim/log"; exit "\$rc"` (`:743`). imps reads only `T_*` variables (`test/scripts/build-loop-check.bats:23-25`). `$a/.claude` becomes a top via `[[ -z "${os_s[c$d]+set}" && -d "$d" ]] || continue; ... tops+=("$d")` (`scripts/lib/dev-cycle-read.sh:1523`). Trace: SHIM_ONCE run `rc=1 ... fired_before=n` then `rc=0 ... fired_before=y`; `rmtop=1` three `rc=1`; `rmtop=drop` three `rc=0` (`shim-trace.log`).

**Evidence:** `test/scripts/build-loop-check.bats:20-29`, `test/scripts/build-loop-check.bats:736-744`, `test/scripts/build-loop-check.bats:773`, `scripts/lib/dev-cycle-read.sh:1522-1524`, `final-r3/logs/shim-trace.log`

---

## Claim 17: the assertions: file case "no listing fails and none is retried" (log all `0`); directory case "the first listing fails and the retry ... completes; the failed try's message is dropped" (`1 0`, empty stderr); unreadable top and `SHIM_RMTOP=1` `1 1 1`; `drop` `0 0 0`

**Location:** `test/scripts/build-loop-check.bats:747-775`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the actual log contents in both walks for every case; does not establish stderr content in the three-failure cases (not asserted).
**Legibility-target:** for-orchestrator-synthesis

The full trace per walk: file case one line `rc=0`; directory case exactly `rc=1`, `rc=0`; each failure case exactly three lines, so `head -2`/`head -3` hide no extra entries (`shim-trace.log`). Assertions: `! grep -qvx 0 "$a/shim/log"` (`:754`), `[ "$(head -2 "$a/shim/log" | tr '\n' ' ')" = "1 0 " ]` (`:762`), `[ "$(head -3 ...)" = "1 1 1 " ]` (`:769`), and the `drop`/`1` ternary (`:774`).

**Evidence:** `test/scripts/build-loop-check.bats:747-775`, `final-r3/logs/shim-trace.log`, `final-r3/logs/test-head.log`

---

## Claim 18: the test passes at HEAD and fails against main's lib and the mutants (no retry, no -ignore_readdir_race, no recheck in top_files)

**Location:** `test/scripts/build-loop-check.bats:724`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four named mutants plus two extra (stderr kept on all tries; two tries only), each applied with an exact-once string replacement; does not establish detection of a recheck that fails without emptying NAME (survives; see Claim 13).
**Legibility-target:** for-orchestrator-synthesis

HEAD: `ok 1 ...` exit 0 (`test-head.log`). Mutants, all `not ok 1`: `main` (walk failed, `find: '.../vic2': No such file or directory`), `noretry` (directory case, walk failed), `noirr` (`a listing failed: 1` / `0`), `norecheck` (`want: walk: failed` at `:771`), `keepstderr` (stderr non-empty), `twotries` (`want three failed tries: 1 1`); `noempty` passed (`mutants.log`).

**Evidence:** `test/scripts/build-loop-check.bats:724-777`, `final-r3/mutants.sh`, `final-r3/logs/test-head.log`, `final-r3/logs/mutants.log`

---

## Claim 19a: ba5d2d1d "ancestor listing skips entries that vanish mid-listing" / "-ignore_readdir_race ... skips only an ENOENT on a name readdir returned" / "the vanished entries are skipped"

**Location:** commit ba5d2d1d (message)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the subject's and body's claim that vanished entries in general are skipped; does not establish anything beyond findutils 4.9.0. Superseded in-branch by d2dc88c9, which states the directory case correctly; current code and comments do not repeat it.
**Legibility-target:** for-author

A directory entry that vanishes is reported with exit 1 even under the flag: `/usr/bin/find: 'top/vic1': No such file or directory` ... `== race kind=dir irr rc=1` (`probe-findutils.log`), which is why the `noretry` mutant fails (`mutants.log`). Lands in history as written if the branch is merged rather than squashed; no code fix needed.

**Evidence:** `git show ba5d2d1d`, `final-r3/logs/probe-findutils.log`, `final-r3/logs/mutants.log`

---

## Claim 19b: ba5d2d1d "Probed on findutils 4.9.0: a permission error, a link loop and a missing start point are still reported with exit 1, and a dangling link is still listed by -xtype l."

**Location:** commit ba5d2d1d (message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named case under `-H -maxdepth 1 -ignore_readdir_race`; does not establish `find -L` behaviour (the commit says it was not probed).
**Legibility-target:** for-orchestrator-synthesis

`== perm denied rc=1`, `== link loops inside top rc=1`, `== missing start rc=1`, and `top/dang` printed in the dangling case (`probe-findutils.log`).

**Evidence:** `git show ba5d2d1d`, `final-r3/logs/probe-findutils.log`

---

## Claim 20a: d2dc88c9 "-ignore_readdir_race skips a vanished file but still reports a directory that vanished between readdir and stat (and a file that vanished between find's stat and -xtype's), with exit 1" ... "a persistent error (permission denied, link loop, missing top) fails all three and the walk, with the last try's message" ... "Mutation-checked: main's lib, no retry, no -ignore_readdir_race, and no -d recheck each fail the test."

**Location:** commit d2dc88c9 (message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the findutils behaviours and the mutation results at HEAD; does not establish the mutation results at d2dc88c9 itself (its test differs from HEAD's; re-verified only at HEAD).
**Legibility-target:** for-orchestrator-synthesis

Directory: `== race kind=dir irr rc=1`; file after find's stat: `pre=[-size -100k] irr=[-ignore_readdir_race] rc=1` with `No such file or directory` messages, versus `pre=[-type f] irr=[-ignore_readdir_race] rc=0` when find has not stat'd first (`probe-stat-xtype.log`). Last try's message: Claim 7. Mutants: Claim 18.

**Evidence:** `git show d2dc88c9`, `final-r3/logs/probe-findutils.log`, `final-r3/logs/probe-stat-xtype.log`, `final-r3/logs/mutants.log`

---

## Claim 20b: d2dc88c9 "under the observed load a single try's directory race was rare (2 of ~240 tests in one run)"

**Location:** commit d2dc88c9 (message)
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing beyond noting that the prior rubric records the two failing tests (43, 45); does not establish the rate.
**Legibility-target:** for-orchestrator-synthesis

Needs the original run's log; the rubric records "failed tests 43 and 45 with `find: '/tmp/tmp.Hblz7Uiz3O': No such file or directory`" (`docs/reviews/code-review-rubric-2026-10-14-fix-q145-ancestor-vanish.md:11`), consistent but not the run itself.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-14-fix-q145-ancestor-vanish.md:11`

---

## Claim 21: 0d573a7b "the -d recheck also catches a linked top whose target vanished, which find 4.9 lists as the link itself with exit 0"

**Location:** commit 0d573a7b (message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the find behaviour and that `[[ -d ]]` is false for the dangling link; does not establish a test for this case (none drives a dangling linked top).
**Legibility-target:** for-orchestrator-synthesis

`top` printed, `== linked DIR target vanished rc=0 ; -d top: no` (`probe-findutils.log`); recheck at `scripts/lib/dev-cycle-read.sh:1592` (quoted in Claim 13).

**Evidence:** `git show 0d573a7b`, `scripts/lib/dev-cycle-read.sh:1592`, `final-r3/logs/probe-findutils.log`

---

## Claim 22a: b9f1d2d1 "the -d recheck moves from the config_seeds call site into top_files, which empties NAME and fails when a DIR is no longer a directory ... the recheck is now retried like any other failure" / "the listing comment names a non-atomic save (delete, then re-create) as not covered, as on main when the gap spans readdir" / "mutants (main's lib, no retry, no -ignore_readdir_race, no recheck) each fail the Q-145 test" / "costs two extra maxdepth-1 listings when a top really is gone"

**Location:** commit b9f1d2d1 (message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the recheck's location and retry, the comment's content, the mutants and the listing count at HEAD; does not establish the 238/238 figure (Claim 22b).
**Legibility-target:** for-orchestrator-synthesis

Recheck in top_files (`:1592`), retried (`drop` case: three `rc=0` listings then walk failed, `shim-trace.log`, which is also the "two extra listings"). Comment: "or one deleted and re-created there (a non-atomic save)" (`scripts/lib/dev-cycle-read.sh:1558-1559`). On main a gap spanning readdir leaves the name out of the listing with no error (paraphrased — no quote available because this is readdir semantics applied to main's find line, Claim 10). Mutants: Claim 18.

**Evidence:** `git show b9f1d2d1`, `scripts/lib/dev-cycle-read.sh:1556-1563`, `scripts/lib/dev-cycle-read.sh:1590-1593`, `final-r3/logs/shim-trace.log`, `final-r3/logs/mutants.log`

---

## Claim 22b: b9f1d2d1 "Affected suites 238/238"

**Location:** commit b9f1d2d1 (message)
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing executed; does not establish the suites' pass state at HEAD.
**Legibility-target:** for-orchestrator-synthesis

Not re-run: the brief asks to run only the Q-145 filter and warns the health check may be running concurrently under high load. The prior rubric records the same figure (`docs/reviews/code-review-rubric-2026-10-14-fix-q145-ancestor-vanish.md:20`). Would need the affected suites run at b9f1d2d1 or HEAD.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-14-fix-q145-ancestor-vanish.md:20`

---

## Claim 23: 29b807dc "find prints it: at depth 0 -xtype sees the link (re-probed: a linked top with a live target prints as itself and then its entries, exit 0). The header now says so."

**Location:** commit 29b807dc (message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the probe result and the header text; does not establish other findutils versions.
**Legibility-target:** for-orchestrator-synthesis

`top`, `top/x`, `top/AGENTS.md`, `== live linked DIR rc=0` (`probe-findutils.log`); header: "find also prints a DIR that is itself a link (at depth 0, where -xtype sees the link ...)" (`scripts/lib/dev-cycle-read.sh:1581-1582`).

**Evidence:** `git show 29b807dc`, `scripts/lib/dev-cycle-read.sh:1580-1583`, `final-r3/logs/probe-findutils.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 19a** (commit ba5d2d1d): says vanished entries are skipped; findutils 4.9.0 still reports a vanished directory (exit 1). Corrected by d2dc88c9; history only, so act on it only if the branch is squashed.

### Stale
- (none)

### Mostly Accurate
- **Claim 2** (`scripts/lib/dev-cycle-read.sh:828-832`): the walk-level header's "a name no longer there holds nothing to load" leaves out the delete-and-re-create case spanning the stat, which is skipped although the file exists again; point to config_seeds' "not covered" note.
- **Claim 4b** (`scripts/lib/dev-cycle-read.sh:1509-1510`): "an entry that vanishes mid-listing fails one" should say a *directory* entry; a vanished file fails no try.
- **Claim 10** (`scripts/lib/dev-cycle-read.sh:1560-1561`): main failed when the gap *spanned its stat* after readdir named the file, not when it "fell between readdir and stat" (a gap wholly in that window does not fail main). That is exactly the case the branch now skips.
- **Claim 14** (`test/scripts/build-loop-check.bats:725-727`): the clause runs at every entry of the ancestor (and at `$a/.claude`), not only the first; the first run does the deleting.

### Unverifiable
- **Claim 20b** (commit d2dc88c9): "2 of ~240 tests" needs the original run log.
- **Claim 22b** (commit b9f1d2d1): "Affected suites 238/238" needs the affected suites run (not done, per brief and concurrent health check).

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved to the OUTPUT PATH below, structured per the code-fact-check skill, first line `Commit: 29b807dc`.
- Answered: yes. All six brief items checked, by execution where possible (findutils probes, HEAD test, 7 mutants, shim trace); 0 behavioural defects in code; 1 Incorrect confined to a superseded commit message; 4 wording imprecisions.
- Out of scope: running the full affected suites (brief limits execution to the Q-145 filter; health check may be running concurrently); docs/reviews artifacts (context only); the unchanged `find -L` listings.
- Escalate: Claim 10's wording hides that the newly skipped case (delete-and-re-create spanning the stat) is exactly the case main failed closed on. The comment's "or now skips" line discloses the skip, so this is wording, but the security critic may want to confirm the trade is accepted. Mutant `noempty` survives: the "NAME empty" half of the recheck branch is not pinned by a test. It is harmless today because config_seeds discards `fl` on failure.
- Decisions I made: kept execution logs under the scratch dir, not docs/reviews/execution-logs, because the brief limits temp files to the scratch dir; verdicted commit messages even though they are immutable history, marking them for-author only where a squash would matter.
