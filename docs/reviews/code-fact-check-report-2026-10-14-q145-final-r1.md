Commit: 29b807dc

# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-q145, branch fix/q145-ancestor-vanish)
**Scope:** `git diff main...HEAD` at 29b807dc: scripts/lib/dev-cycle-read.sh (walk header, config_seeds, top_files; nul_list read), test/scripts/build-loop-check.bats (Q-145 test), test/scripts/dev-cycle.bats (function list), docs/thoughts/failure-patterns.md (FP-173), and commit messages `git log main..HEAD`. docs/reviews artifacts excluded (context only). Final confirming pass, replicate r1 of k=3.
**Checked:** 2026-10-14
**Total claims checked:** 26
**Summary:** 19 verified, 3 mostly accurate, 0 stale, 1 incorrect, 3 unverifiable

Execution environment for every `executed` claim: GNU findutils 4.9.0 (`/usr/bin/find`), bash 5.2.15, run as uid node from a `git archive HEAD` copy at `S/copy`, where `S=/home/node/.claude/jobs/00bcf178/tmp/q145/review/final-r1`; host load average ~16-20 during the runs. All logs are under `S/logs/`; the probe scripts are under `S/`. Times are UTC. No tracked file in the worktree was modified; the copy's lib was restored to HEAD after the mutant runs (`cmp` against the worktree lib passed, `S/logs/mutants.out` last line).

Execution runs referenced below:

- **E1 (test at HEAD):** `cd S/copy && LC_ALL=C timeout 900 bats --filter 'Q-145' test/scripts/build-loop-check.bats`, exit 0 (`ok 1`), 2026-10-15T04:48:07Z-04:48:18Z. Output: `S/logs/test-head.out`.
- **E2 (find probes):** `timeout 120 S/probe-find.sh` (fixtures under `S/probe`; deleter `S/del-others.sh`), exit 0, 2026-10-15T04:48:31Z. Output: `S/logs/probe-find.out`.
- **E3 (probes: links at depth 1, `2>/dev/null` scoping):** `timeout 60 S/probe-find2.sh`, exit 0, 2026-10-15T04:49:42Z. Output: `S/logs/probe-find2.out`.
- **E4 (mutants):** `timeout 1500 S/mutants.sh`: the Q-145 test against main's lib and five mutants of HEAD's lib (noretry, norace, norecheck, keepstderr, tworetry), exit 0 (script), 2026-10-15T04:49:42Z-04:50:10Z. Output: `S/logs/mutants.out`.
- **E5 (instrumented test):** a scratch-copy-only copy of the Q-145 test that prints each shim log to fd 3 after each imps call; `LC_ALL=C timeout 300 bats test/scripts/q145instr.bats` in `S/copy`, exit 0, 2026-10-15T04:50:27Z. Output: `S/logs/instr.out`.
- **E6 (stat-then-xtype probe):** `timeout 60 S/probe-find3.sh` plus two follow-up invocations appended to the same log (one without `-ignore_readdir_race`, one with a stat forced by `-printf 'size=%s\n'` before the self-delete), exit 0/1 as logged, 2026-10-15T04:51-04:52Z. Output: `S/logs/probe-find3.out`.

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 8 entries) read first; no claim below matches a logged pattern (none concern findutils, stderr handling, retries or readdir).

---

## Claim 1: "FP-173 2026-10-14 symptom:find-over-shared-ancestor-dir-exits-nonzero-when-another-process-deletes-an-entry-mid-listing-gate-flakes-under-parallel-load cause:overbroad-guard fix:narrow-the-guard ref:d2dc88c9"

**Location:** `docs/thoughts/failure-patterns.md:315`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the entry's schema fields, the vocabulary terms existing in the file, and the ref resolving to the branch's retry commit; does not establish that `ref:d2dc88c9` stays reachable if the branch is squash-merged rather than merged.

Both vocabulary terms exist: `| 8 | \`overbroad-guard\` | the check was correct but rejected legitimate input as well |` (`docs/thoughts/failure-patterns.md:68`) and `| 12 | \`narrow-the-guard\` | keep the check, shrink what it rejects |` (`:93`). `d2dc88c9` is the branch commit "retry the top-level listing when a directory vanishes mid-listing (Q-145)" (`git log main..HEAD`). The symptom matches the behaviour reproduced in E4 against main's lib: `/usr/bin/find: '/tmp/bats-run-45h5Wy/test/1/vic2': No such file or directory` with `tree: walk: failed`.

**Evidence:** `docs/thoughts/failure-patterns.md:68`, `docs/thoughts/failure-patterns.md:93`, `docs/thoughts/failure-patterns.md:315`, `S/logs/mutants.out`

---

## Claim 2: "The one exception is the top-level listing of ancestors and config dirs (config_seeds): an entry that vanishes between find's readdir and its stat (another process's temp file in /tmp) is skipped, or the listing is retried, up to three tries, since a name no longer there holds nothing to load; only an error-free listing is used, so any error that persists across the tries still fails the walk (Q-145)."

**Location:** `scripts/lib/dev-cycle-read.sh:828-834`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the top listing is the only seed listing that retries (the other config_seeds finds still `|| return 1` once), that a vanished file is skipped and a vanished directory retried, and that a persistent error fails the walk; does not establish the "nothing to load" rationale for a name deleted and re-created during the gap (disclosed as not covered in the listing comment, Claim 8).

The other seed finds in config_seeds still fail on one error: `nul_list fl find -L "${fr[@]}" '(' -type f -o -type l ')' -iname '*.md' -print0 || return 1` (`scripts/lib/dev-cycle-read.sh:1537`; likewise `:1538`, `:1540`). Only the top listing retries: `top_files fl "${tops[@]}" 2>/dev/null || top_files fl "${tops[@]}" 2>/dev/null || top_files fl "${tops[@]}" || return 1` (`:1563`). Executed: E5 shows a vanished file needs no retry (`LOG[tree] 0`), a vanished directory one (`LOG[tree] 1 0`), and a persistent permission error fails all three (`LOG[tree perm] 1 1 1`, walk failed).

**Evidence:** `scripts/lib/dev-cycle-read.sh:828-834`, `scripts/lib/dev-cycle-read.sh:1537-1541`, `scripts/lib/dev-cycle-read.sh:1563`, `S/logs/instr.out`

---

## Claim 3a: "config_seeds NAME ... returns 1 when a find, grep, realpath or lower_all fails; the top-level listing (top_files) fails it only when all three of its tries fail"

**Location:** `scripts/lib/dev-cycle-read.sh:1508-1510`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the top_files clause (three tries, return 1 only after the third fails) and the find/realpath/lower_all `|| return 1` sites in config_seeds; does not establish the pre-existing "grep" clause beyond noting with_at's failure propagates (`with_at fl "${cx[@]}" || return 1`, `:1569`), nor that python3's failure returns 1 (it does not: it falls back to the cache dirs, `:1532-1533`, pre-existing and not claimed otherwise).

Read the whole unit (`:1511-1579`). The three-try chain ends `|| return 1` (`:1563`); `lower_all` failure returns 1 (`[[ ${#fl[@]} -eq 0 ]] || nul_list lo lower_all "${fl[@]}" && [[ ${#lo[@]} -eq ${#fl[@]} ]] || return 1`, `:1564`); realpath through xargs returns 1 (`nul_list rl xargs -0r -a <(printf '%s\0' "${cx[@]}") realpath -mz -- && [[ ${#rl[@]} -eq ${#cx[@]} ]] || return 1`, `:1572`). Executed: E4's `tworetry` mutant (two tries) fails the test at the `1 1 1` assertion (`want three failed tries: 1 / 1`), so the test pins exactly three tries.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1508-1579`, `S/logs/mutants.out`

---

## Claim 3b: "(an entry that vanishes mid-listing fails one: Q-145)"

**Location:** `scripts/lib/dev-cycle-read.sh:1509-1510`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers which vanishing entries fail a try under top_files' actual expression; does not establish behaviour on findutils versions other than 4.9.0.

Under top_files' expression a vanished *file* fails no try: it is skipped, and the shim log for the file case is `0` (E5: `LOG[tree] 0`; E2 probe t1: only `vic2` printed, `rc=0`). Only a vanished *directory* fails a try (E2 probe t2: `find: '.../t2/vic1': No such file or directory`, `rc=1`; E5: `LOG[tree] 1 0`). Precise version: "a directory entry that vanishes mid-listing fails one". The listing comment at `:1549-1551` already says this correctly; only this parenthetical over-generalises.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1509-1510`, `scripts/lib/dev-cycle-read.sh:1549-1551`, `S/logs/probe-find.out`, `S/logs/instr.out`

---

## Claim 4: "Each ancestor below no reader root is a top (/tmp, when a root lies under it), and other processes' files come and go there: an entry find's readdir named can be gone when find stats it, and find then reports ENOENT and exits 1 (Q-145)."

**Location:** `scripts/lib/dev-cycle-read.sh:1545-1548`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers which ancestors become tops and the ENOENT/exit-1 behaviour without `-ignore_readdir_race`; does not establish that config dirs (`.claude`) are tops by the same rule (they are, by a separate loop, `:1521-1522`).

Tops are added only when no root contains the ancestor: `for q in "${rs[@]}"; do [[ "$d" != "$q" && "$d" != "$q"/* ]] || in=1; done` then `[[ -n "$in" || -n "${os_s[a$d]+set}" ]] || { os_s[a$d]=1; [[ ! -d "$d" ]] || tops+=("$d"); cf+=("${d%/}/.claude"); }` (`:1518-1519`). Executed: E2 probe t1b (no flag) prints `/usr/bin/find: '.../t1b/vic4': No such file or directory` (and vic1, vic3) with `rc=1`; E4 main's lib reproduces it in the walk.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1513-1522`, `S/logs/probe-find.out`, `S/logs/mutants.out`

---

## Claim 5: "top_files skips such a file (-ignore_readdir_race), but findutils 4.9 still reports a directory that vanished that way (a session's mktemp -d)"

**Location:** `scripts/lib/dev-cycle-read.sh:1549-1550`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers findutils 4.9.0 with top_files' exact expression; does not establish later findutils versions or the "session's mktemp -d" provenance of the original flake.

E2 probe t1 (`-ignore_readdir_race`, files deleted at the first visit): only `.../t1/vic2` printed, no message, `rc=0`. E2 probe t2 (same, three directories): `find: '.../t2/vic1': No such file or directory`, `find: '.../t2/vic3': No such file or directory`, `rc=1`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1591`, `S/logs/probe-find.out`

---

## Claim 6: "so a failed listing is run again, up to three times in all, the first two with stderr dropped"

**Location:** `scripts/lib/dev-cycle-read.sh:1551-1552`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the try count and that each `2>/dev/null` binds only to its own call (the third try's stderr reaches the caller); does not establish what the caller does with that stderr.

```bash
# scripts/lib/dev-cycle-read.sh:1563
    top_files fl "${tops[@]}" 2>/dev/null || top_files fl "${tops[@]}" 2>/dev/null || top_files fl "${tops[@]}" || return 1
```

A redirection binds to its simple command, so each `2>/dev/null` covers only that call. Executed (E3): `f 1 1 2>/dev/null || f 2 1 2>/dev/null || f 3 1` prints only `err-3`, `rc=1`; with the second call succeeding, nothing is printed, `rc=0`. nul_list's process substitution (`mapfile -d '' nl_a < <("$@" && printf rc=0 || printf rc=1)`, `:1646`) inherits the call's stderr, so find's message is dropped too: E1 asserts `[ -z "$stderr" ]` after a failed first try and passes, and E4's `keepstderr` mutant fails exactly there (`find: '.../vic2': No such file or directory` in stderr).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1563`, `scripts/lib/dev-cycle-read.sh:1646`, `S/logs/probe-find2.out`, `S/logs/test-head.out`, `S/logs/mutants.out`

---

## Claim 7: "Only a listing that completes without any error is used, so a retry never hides an existing file: an error that persists across the three tries (a permission error, a link loop, a missing top, a top that is no longer a directory) fails the walk; a transient one of any kind is retried away, its message dropped."

**Location:** `scripts/lib/dev-cycle-read.sh:1552-1556`
**Type:** Behavioral / Error-handling / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that a failed try leaves NAME empty and is overwritten by the next, that the used listing is from a try with find exit 0 and every DIR still a directory, and each named persistent error failing every try; does not establish that an error-free listing is complete (the `-ignore_readdir_race` skip and readdir semantics can omit a re-created or renamed-in file: disclosed in Claim 8), and does not establish errors find 4.9 swallows itself.

A failed try empties NAME: nul_list does `{ nl_a=(); return 1; }` (`:1646`) and top_files' recheck does `{ local -n tf_a="$1"; tf_a=(); return 1; }` (`:1592`), so `fl` after the chain holds only a successful try's listing. Executed per named error (E2, each with `-ignore_readdir_race`): permission (t6) `Permission denied`, `rc=1`; link loop inside a top (t5) `Too many levels of symbolic links`, `rc=1`, and a looping top (t5loopa) the same; missing top (`nonexist`) `No such file or directory`, `rc=1`; top replaced by a file (t7) is printed with `rc=0`, so only the recheck catches it (`[[ -d "$tf_d" ]]`, `:1592`). Also an entry the top cannot stat (t9, top mode 444) `Permission denied`, `rc=1`. Walk-level: E5 `LOG[tree perm] 1 1 1`, `LOG[tree rmtop=1] 1 1 1`, `LOG[tree rmtop=drop] 0 0 0`, each `walk failed`. Transient case: E5 `LOG[tree] 1 0` with empty stderr (E1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1563`, `scripts/lib/dev-cycle-read.sh:1590-1593`, `scripts/lib/dev-cycle-read.sh:1646`, `S/logs/probe-find.out`, `S/logs/instr.out`, `S/logs/test-head.out`

---

## Claim 8: "Not covered, as with any directory read: a file renamed in during the listing (readdir leaves a name added mid-read unspecified), or one deleted and re-created there (a non-atomic save), which find may not see, or now skips when the gap spans its stat (i2 security F1)"

**Location:** `scripts/lib/dev-cycle-read.sh:1556-1560`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the skip of a file absent at find's stat under `-ignore_readdir_race` (the delete-and-re-create half) and the readdir rule as recalled; does not establish the POSIX text from a fetched source (no network egress; the readdir rule is recalled: whether readdir returns an entry for a file added or removed after opendir is unspecified), and does not establish a deterministic re-create probe (the skip of an absent-at-stat file is what E2 t1 shows).

E2 probe t1: files deleted after readdir and absent at the stat are skipped silently with `rc=0` under `-ignore_readdir_race`; a file re-created after that stat would therefore be missing from an error-free listing that is then used, which is the disclosed gap. (paraphrased — no quote available because the claim concerns timing windows of a concurrent writer, not a code line; the code it rests on is the `-ignore_readdir_race` flag at `:1591`.)

**Evidence:** `scripts/lib/dev-cycle-read.sh:1556-1560`, `scripts/lib/dev-cycle-read.sh:1591`, `S/logs/probe-find.out`

---

## Claim 9: "before Q-145 such a gap failed the walk only when it fell between find's readdir and its stat."

**Location:** `scripts/lib/dev-cycle-read.sh:1560-1561`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers main's listing (`nul_list fl find -H "${tops[@]}" -maxdepth 1 '(' -xtype f -o -xtype l ')' -print0 || return 1`, no `-ignore_readdir_race`, no retry) failing on ENOENT at the stat; does not establish main's behaviour for a directory entry (not listed by `-xtype f/l` in either version).

On main, a delete-and-re-create gap fails the walk when the file is absent at find's stat but was present at readdir, i.e. when the gap *began* after readdir and was *still open* at the stat (E2 probe t1b without the flag: `No such file or directory`, `rc=1`; E4 main's lib: walk failed). A gap lying wholly between readdir and the stat (file back before the stat) causes no error. "fell between find's readdir and its stat" reads most naturally as the whole gap inside that window, which is the one case that did not fail. Precise version: "only when it began after find's readdir and was still open at its stat".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1560-1561`, `S/main-lib.sh` (main's config_seeds listing), `S/logs/probe-find.out`, `S/logs/mutants.out`

---

## Claim 10: "top_files NAME DIR...: array NAME gets the files and links (-xtype f or l) directly in each DIR, read through nul_list; find also prints a DIR that is itself a link (at depth 0, where -xtype sees the link: -H follows it only to list its entries), so such a DIR is in NAME too."

**Location:** `scripts/lib/dev-cycle-read.sh:1580-1583`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers NAME's content for plain DIRs, linked DIRs, and depth-1 files, links to files, dangling links and links to directories; does not establish "-H follows it only to list its entries" beyond this expression (under -H the start point's stat is also the target's, which no predicate here reads).

```bash
# scripts/lib/dev-cycle-read.sh:1590-1593
top_files() {
  local tf_d; nul_list "$1" find -H "${@:2}" -maxdepth 1 -ignore_readdir_race '(' -xtype f -o -xtype l ')' -print0 || return 1
  for tf_d in "${@:2}"; do [[ -d "$tf_d" ]] || { local -n tf_a="$1"; tf_a=(); return 1; }; done
}
```

Executed (E2): linked DIR t4link prints `.../t4link` then `.../t4link/a`, `rc=0`; plain DIR t4tgt prints only `.../t4tgt/a`. E3: at depth 1 a real file, a dangling link and a link to a file are printed, a link to a directory (`ld`) and a subdirectory are not, `rc=0`, identically with and without `-ignore_readdir_race` (so the flag does not drop a dangling link).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1580-1593`, `S/logs/probe-find.out`, `S/logs/probe-find2.out`

---

## Claim 11: "An entry gone between find's readdir and its stat of a file is skipped (-ignore_readdir_race, GNU find)."

**Location:** `scripts/lib/dev-cycle-read.sh:1583-1584`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers files under top_files' expression on findutils 4.9.0; does not establish the case where find has already stat'ed the file before -xtype (E6: with a forced `-printf '%s'` stat first, a self-deleted file is reported, `rc=1`), which top_files' expression does not trigger (E6 first case, no prior stat-needing predicate: silent, `rc=0`).

E2 t1: `rc=0`, no message. E6: `-type f -exec unlink-self {} ';' -xtype f` with the flag: `rc=0`; same without the flag: `No such file or directory`, `rc=1`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1591`, `S/logs/probe-find.out`, `S/logs/probe-find3.out`

---

## Claim 12: "It fails, with NAME empty, when find reports any error (a directory entry that vanished included: config_seeds retries, Q-145) or a DIR is no longer a directory after the listing: one that vanished under a find that skips a missing start point silently, or a linked DIR whose target vanished, which find 4.9 lists as the link itself and exits 0 (i1 fact-check 6a)."

**Location:** `scripts/lib/dev-cycle-read.sh:1585-1589`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both failure branches emptying NAME (nul_list on find exit ≠ 0; the recheck on any non-directory DIR) and the dangling-linked-DIR behaviour; does not establish a real find that skips a missing start point silently (findutils 4.9 reports it even with the flag, E2 `nonexist`, `rc=1`; the case is simulated by the test's `SHIM_RMTOP=drop`).

nul_list: `[[ ${#nl_a[@]} -gt 0 && "${nl_a[-1]}" == rc=0 ]] || { nl_a=(); return 1; }` (`:1646`). Recheck: `[[ -d "$tf_d" ]] || { local -n tf_a="$1"; tf_a=(); return 1; }` (`:1592`). E2 t4dang: `.../t4dang` printed, `rc=0`, so only the recheck fails it. E4 `norecheck` mutant fails the test at the `SHIM_RMTOP="$m"` line with `walk: ok`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1585-1593`, `scripts/lib/dev-cycle-read.sh:1646`, `S/logs/probe-find.out`, `S/logs/mutants.out`

---

## Claim 13: "The race, made deterministic with the real find: a shim adds, to the -H top-level listing only, a clause that runs at the first entry of the fixture's ancestor and deletes every other vic* there. find read all their names before that first visit, so it stats each deleted one later and gets ENOENT. The shim logs each listing's exit status."

**Location:** `test/scripts/build-loop-check.bats:725-728`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the shim intercepting only `find -H` (the lib has one `find -H` call, `:1591`), the deletion clause, the names-read-before-visit behaviour and the per-call exit log; does not establish that the clause runs *only* at the first entry (it runs at every entry under the ancestor, deleting whatever vic* remain, which the "at most the first-visited victim is left" assertion tolerates).

Shim: `[[ "\${1:-}" == -H ]] || exec "$real" "\$@"` and `rc=\$?; echo "\$rc" >> "$a/shim/log"; exit "\$rc"` (`test/scripts/build-loop-check.bats:738`, `:743`). `grep -n 'find -H'` over `scripts/lib/*.sh` finds only `:1591` in non-comment code. Names read before the first visit: E4 main's lib reports `vic2`, `vic4`, `vic1`, `vic3` as `No such file or directory` (deleted after readdir, stat'd later).

**Evidence:** `test/scripts/build-loop-check.bats:725-743`, `scripts/lib/dev-cycle-read.sh:1591`, `S/logs/mutants.out`

---

## Claim 14: "With SHIM_ONCE it races only on the first listing of a walk. With SHIM_RMTOP it instead removes the ancestor's .claude, a top config_seeds already found to be a directory, first; SHIM_RMTOP=drop also drops it from the start points, as a find that skipped a missing start point silently would, which leaves top_files' -d recheck to catch it. (SHIM_*, not T_*: the shim reads them, not imps.)"

**Location:** `test/scripts/build-loop-check.bats:729-733`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each knob's effect as observed in the per-call logs; does not establish behaviour if a walk ever made more than one `-H` listing (E5 shows exactly one per walk today).

SHIM_ONCE: `if [[ -n "\${SHIM_ONCE:-}" && -e "$a/shim/fired" ]]; then "$real" "\${args[@]}" "\$@"` else `touch "$a/shim/fired"` and race (`:741-742`); `fired` is removed before each imps call. SHIM_RMTOP: `rmdir "$a/.claude"` before find runs (`:739`); drop: `[[ "\${SHIM_RMTOP:-}" == drop && "\$1" == "$a/.claude" ]] || args+=("\$1")` (`:740`). imps reads only `T_READER_ROOTS`, `T_READER_HOMES`, `T_MANAGED`, `T_SETTINGS` (`:23-26`). E5: `LOG[tree rmtop=1] 1 1 1`, `LOG[tree rmtop=drop] 0 0 0`; E4 `norecheck` fails at the drop case.

**Evidence:** `test/scripts/build-loop-check.bats:20-28`, `test/scripts/build-loop-check.bats:729-743`, `S/logs/instr.out`, `S/logs/mutants.out`

---

## Claim 15: Test assertions and comments: "Files: -ignore_readdir_race skips each, so no listing fails and none is retried" (log `0`); "Directories: findutils still reports one, so the first listing fails and the retry, without the race, completes; the failed try's message is dropped" (`1 0`, empty stderr); "Any other error in the same listing fails closed, after three tries" (`1 1 1`); "find reports the missing top (1); with it dropped, find succeeds (0) and the recheck fails each try" (`0 0 0`); and that the test fails against main's lib and the no-retry, no-`-ignore_readdir_race` and no-recheck mutants

**Location:** `test/scripts/build-loop-check.bats:724-777`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the test passing at HEAD, the exact per-call logs for every case in both walks, and each named mutant (plus two extra: stderr kept, two tries) failing; does not establish run-to-run stability under heavier load (one run each).

E1: `ok 1`. E5 logs for both walks: `0`, `1 0`, `1 1 1` (perm), `1 1 1` (rmtop=1), `0 0 0` (drop) — exactly the asserted prefixes and no extra lines. E4: main's lib fails at line 750 (`tree: walk: failed`, ENOENT messages); noretry at line 760 (dir case, walk failed); norace at line 754 (`a listing failed: 1 / 0`); norecheck at line 771 (`walk: ok`); keepstderr at line 760 (stderr non-empty); tworetry at line 769 (`want three failed tries: 1 / 1`). The `! grep -qvx 0` check would pass on an empty log, but the preceding race check (`compgen -G "$a/vic*" | wc -l` ≤ 1) fails if the shim never ran.

**Evidence:** `test/scripts/build-loop-check.bats:724-777`, `S/logs/test-head.out`, `S/logs/instr.out`, `S/logs/mutants.out`

---

## Claim 16a: (commit ba5d2d1d) "Probed on findutils 4.9.0: a permission error, a link loop and a missing start point are still reported with exit 1, and a dangling link is still listed by -xtype l. ... Before the fix the test fails with the flake's exact message."

**Location:** commit ba5d2d1d message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the four probe results and the main-lib failure message of today's test; does not establish that the test as of ba5d2d1d (since revised) failed the same way.

E2: t6 `Permission denied` rc=1; t5 `Too many levels of symbolic links` rc=1; `nonexist` rc=1 (with flag). E3: `dang` listed with the flag. E4 main's lib: `/usr/bin/find: '/tmp/bats-run-45h5Wy/test/1/vic2': No such file or directory`.

**Evidence:** commit ba5d2d1d, `S/logs/probe-find.out`, `S/logs/probe-find2.out`, `S/logs/mutants.out`

---

## Claim 16b: (commit ba5d2d1d) "config_seeds lists every ancestor of each reader root and every config dir at depth 1"

**Location:** commit ba5d2d1d message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers which ancestors are tops in main's and HEAD's config_seeds; does not establish anything about the config-dir half (accurate).

Only ancestors inside no reader root are tops: `[[ -n "$in" || -n "${os_s[a$d]+set}" ]] || { ...; [[ ! -d "$d" ]] || tops+=("$d"); ... }` (`scripts/lib/dev-cycle-read.sh:1519`). Precise version: "every ancestor below no reader root"; 0d573a7b corrected the code comment, the commit message itself is history.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1513-1522`, commit 0d573a7b

---

## Claim 16c: (commit ba5d2d1d) "The listing now passes -ignore_readdir_race (GNU findutils), which skips only an ENOENT on a name readdir returned." with the test claim "the vanished entries are skipped"

**Location:** commit ba5d2d1d message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the implied mechanism that the flag skips an ENOENT on any name readdir returned; does not apply to HEAD's code, which handles the directory case by retry (d2dc88c9), and the "only" bound (no non-ENOENT error is skipped) is accurate.

findutils 4.9.0 still reports an ENOENT on a readdir-returned *directory* name with the flag: E2 t2 `find: '.../t2/vic1': No such file or directory`, `rc=1`. Known and superseded: d2dc88c9's message states the directory case, and the i1 rubric's R1 records it as fixed. No code action; it is a history-only inaccuracy.

**Evidence:** commit ba5d2d1d, commit d2dc88c9, `S/logs/probe-find.out`

---

## Claim 16d: (commit ba5d2d1d) "the build-loop-check 968 and build-loop-merge 1059/1061 flakes under parallel load"

**Location:** commit ba5d2d1d message
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers nothing about the historical runs; does not establish which tests flaked.

The cited flakes come from past suite runs whose logs are not in the scope (paraphrased — no quote available because the claim concerns historical CI/local run output not stored in the repository). Would need the original run logs.

**Evidence:** commit ba5d2d1d

---

## Claim 17a: (commit d2dc88c9) "Probed on findutils 4.9.0: -ignore_readdir_race skips a vanished file but still reports a directory that vanished between readdir and stat (and a file that vanished between find's stat and -xtype's), with exit 1. ... a persistent error (permission denied, link loop, missing top) fails all three and the walk, with the last try's message. ... Mutation-checked: main's lib, no retry, no -ignore_readdir_race, and no -d recheck each fail the test."

**Location:** commit d2dc88c9 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the probe results (the stat-then-xtype case only when find has stat'ed the file first), the three-try failure with the third try's stderr surfacing, and the mutants against today's test; does not establish the mutants against the test as of d2dc88c9.

E2 t1/t2 (file skipped, directory reported). E6: with a stat forced by `-printf 'size=%s\n'` then a self-delete, `find: '.../t/f4': No such file or directory`, `rc=1`; without a prior stat (`-type f`, which uses readdir's d_type) the same race is silent, `rc=0`, so the parenthetical holds only where find stats first (top_files' expression does not). Last try's message: Claim 6 (E3). Mutants: E4.

**Evidence:** commit d2dc88c9, `S/logs/probe-find.out`, `S/logs/probe-find3.out`, `S/logs/probe-find2.out`, `S/logs/mutants.out`

---

## Claim 17b: (commit d2dc88c9) "still failed build-loop-check tests 43 and 45 with `find: '/tmp/tmp.XXXX': No such file or directory`" and Notes "(2 of ~240 tests in one run)"

**Location:** commit d2dc88c9 message
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers nothing about the historical run; does not establish the failure counts.

(paraphrased — no quote available because the claim reports a past suite run's output that is not stored in the repository.) Would need that run's log.

**Evidence:** commit d2dc88c9

---

## Claim 18a: (commit b9f1d2d1) "the -d recheck moves from the config_seeds call site into top_files, which empties NAME and fails when a DIR is no longer a directory ... the recheck is now retried like any other failure ... The test's vanished-top cases now assert three tries each (`1 1 1`; `0 0 0` for the dropped top, which the recheck fails) ... mutants (main's lib, no retry, no -ignore_readdir_race, no recheck) each fail the Q-145 test ... moving the recheck into the retried helper costs two extra maxdepth-1 listings when a top really is gone"

**Location:** commit b9f1d2d1 message
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the recheck's location and effect, the retry of a recheck failure, the asserted logs, the mutants and the three-listing cost; does not establish the other bulleted review-ID mappings (A2, C1-C6) beyond the code/comment text they name, which Claims 1, 3a, 8, 14 check.

The call site has no recheck: `top_files fl "${tops[@]}" 2>/dev/null || ... || return 1` (`scripts/lib/dev-cycle-read.sh:1563`); top_files has it (`:1592`). E5 `LOG[tree rmtop=drop] 0 0 0` (three listings, each failed by the recheck). E4 mutants.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1563`, `scripts/lib/dev-cycle-read.sh:1590-1593`, `S/logs/instr.out`, `S/logs/mutants.out`

---

## Claim 18b: (commit b9f1d2d1) "Affected suites 238/238"

**Location:** commit b9f1d2d1 message
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers nothing about the full affected suites; does not establish their pass count at b9f1d2d1 or HEAD.

Not re-run: the brief restricts execution to the Q-145 filter and a repo health check may be running concurrently against the worktree (paraphrased — no quote available because this is a test-run count, not code). Would need the affected suites run at HEAD.

**Evidence:** commit b9f1d2d1

---

## Claim 19: (commit 0d573a7b) "Each ancestor below no reader root is a top, not every ancestor; the -d recheck also catches a linked top whose target vanished, which find 4.9 lists as the link itself with exit 0; config_seeds' header names the recheck as a return-1 cause." (comment-only)

**Location:** commit 0d573a7b message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the commit's description of its own change at 0d573a7b and the dangling-linked-top behaviour; does not establish that HEAD's config_seeds header still names the recheck (b9f1d2d1 folded it into top_files' failure: "fails it only when all three of its tries fail", `:1509`).

At 0d573a7b the header read `# returns 1 when a find, grep, realpath or lower_all fails (the top-level ... or a top is no longer a directory after it.` (`git show 0d573a7b:scripts/lib/dev-cycle-read.sh`, lines 1506-1509). Dangling linked top: E2 t4dang `rc=0`, link printed.

**Evidence:** commit 0d573a7b, `scripts/lib/dev-cycle-read.sh:1508-1510`, `S/logs/probe-find.out`

---

## Claim 20: (commit 29b807dc) "find prints it: at depth 0 -xtype sees the link (re-probed: a linked top with a live target prints as itself and then its entries, exit 0). The header now says so."

**Location:** commit 29b807dc message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the probe result and that the diff only rewrites the top_files header (5 lines, comment-only); does not establish anything beyond findutils 4.9.0.

E2 t4link: `.../t4link`, then `.../t4link/a`, `rc=0`. `git show 29b807dc` changes only comment lines of the top_files header (`scripts/lib/dev-cycle-read.sh:1580-1583`).

**Evidence:** commit 29b807dc, `scripts/lib/dev-cycle-read.sh:1580-1583`, `S/logs/probe-find.out`

---

## Claims Requiring Attention

### Incorrect
- **Claim 16c** (commit ba5d2d1d): says `-ignore_readdir_race` skips an ENOENT on any name readdir returned; findutils 4.9.0 still reports a vanished directory. Already superseded by d2dc88c9 and fixed in code. Commit history only, nothing to change.

### Stale
- None.

### Mostly Accurate
- **Claim 3b** (`scripts/lib/dev-cycle-read.sh:1509-1510`): "an entry that vanishes mid-listing fails one" should be "a directory entry ..."; a vanished file fails no try.
- **Claim 9** (`scripts/lib/dev-cycle-read.sh:1560-1561`): "fell between find's readdir and its stat" should be "began after find's readdir and was still open at its stat"; a gap wholly inside that window caused no error on main.
- **Claim 16b** (commit ba5d2d1d): "every ancestor" should be "every ancestor below no reader root" (the code comment was already corrected in 0d573a7b).

### Unverifiable
- **Claim 16d** (commit ba5d2d1d): needs the historical run logs that show the flake test numbers.
- **Claim 17b** (commit d2dc88c9): needs the historical run log (tests 43/45, 2 of ~240).
- **Claim 18b** (commit b9f1d2d1): needs a run of the affected suites at HEAD; this pass ran only the Q-145 filter.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved to the OUTPUT PATH below, structured per the code-fact-check skill, first line `Commit: 29b807dc`.
- Answered: yes. All six focus areas were checked, and every behavioural claim was confirmed by running it (the test at HEAD, findutils probes, main's lib and five mutants, and per-call shim logs).
- Out of scope: the full affected suites (Claim 18b), because the brief limits execution to the Q-145 filter and the health check may be running at the same time. Also out of scope: the docs/reviews artifacts, which the brief excludes.
- Escalate: nothing. The security property holds as stated. Only a listing with no errors is used, and every persistent error tried fails all three tries and the walk. The only ways an existing file can be missed are a rename-in and a delete-and-re-create, and both are disclosed.
- Decisions I made: I verdicted the d2dc88c9 parenthetical (stat-then-xtype) Verified after a first probe that looked like a refutation. That probe used `-type f`, which reads d_type and does not stat. With a forced stat, the claim reproduces. I verdicted Claim 9 Mostly accurate rather than Verified because I took "fell between" to mean the whole gap lies inside the window.
