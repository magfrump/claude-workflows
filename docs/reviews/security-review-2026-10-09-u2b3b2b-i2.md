Commit: 39f64d62

# Security Review — feat/build-loop-u2b3b2b, iteration 2 (fix range 1c820663..39f64d62)

**Scope:** `git diff 1c820663..39f64d62`. Read in full in `scripts/lib/dev-cycle-read.sh`: `outside_seeds`, `root_starts`, `outside_proj`, `outside_ok`, `import_outside`, `import_targets` and IMPORT_AWK (`scan`, `names`, `quoted`, `splice`, `emit`, `put`), `rawfile`, `isstart`, `instruction_names`, `nul_list`, `lower_all`, the seed loops of `imported_names` and `main_imports`, the walk header (lines 717-762), and caller contract item 4.
**Date:** 2026-10-09
**Based on:** shared brief `u2b3b2b-i2/shared.md`; iteration-1 report `security-review-2026-10-09-u2b3b2b.md` and the iteration-1 rubric. No iteration-2 code fact-check was available to this review.

> **No code fact-check report provided for this iteration.** The code's comments were checked against probes, below, not by a fact-check.

Probe harness: `/tmp/claude-1000/-workspace/7705a73b-d526-48c8-9948-70a1335d5801/scratchpad/u2b3b2b-sec2-probe.sh` (Q1-Q8), `u2b3b2b-sec2-probe3.sh` (the Q4 detail). Each sources the branch lib in a throwaway repo under `/tmp/u2b3b2b-sec2-*`, with `HOME` in the temp dir, `CLAUDE_CONFIG_DIR` unset, `IMPORT_MANAGED_DIR=/nonexistent/managed` and `LC_ALL=C`. The parent lib (`1c820663`) is extracted to `u2b3b2b-sec2-lib0.sh` for comparison. All temp dirs were removed and no probe process remains. `grep` in the walks is GNU grep 3.8 (`/usr/bin/grep`).

## Trust Boundary Map

The floor fails open when a walk drops a file a session loads and the walk still reports ok. A failed walk, or one that stalls, refuses the merge (fail-closed), at a cost to availability.

```
B1:        [other reader roots' working trees (find -P)] → [root_starts → isstart(innermost-root path) → @/link filter → rawfile+sha1sum skip] → [walk seeds (C1)]
B2:        [config dirs, ancestors (find -L / find -H)]  → [isstart / dir rules → @/link filter (grep, realpath -m)]                    → [walk seeds]
B3 (new):  [seed file bytes]                             → [xargs sh -c 'grep -lsZF -e @ ...; [ $? -le 2 ]']                         → [os_at keep-set: a seed missing from it is dropped]
B4:        [seed text in the walk]                       → [import_targets parser]                                                  → [IMPORTED / IMPORTED_MAIN]
```

Input-source classification:

```
S1: other worktrees' files (loop worktrees, the main checkout) — request-time (a loop writes its own worktree)
      — UNTRUSTED toward availability and toward filter decisions (a loop chooses size, type and link targets);
        its imports only add refusals, so honest content is the fail-open concern
S2: ~/.claude, $CLAUDE_CONFIG_DIR, IMPORT_MANAGED_DIR, ancestors — runtime-mutable (same uid); hostile rewrite is a Q-103 residual
S3: process resource limits / memory state of the gate (RLIMIT_AS, overcommit) — deploy-time — trusted, but not controlled by the lib
S4: CLAUDE_CONFIG_DIR env — deploy-time for the caller — trusted toward availability (a relative value now fails the walk)
```

The fix adds B3. A grep pass now decides which seeds the walk reads at all. Before the fix, every listed seed reached `outside_ok` and the capped parser. Now a seed that grep does not list as holding `@` is dropped, unless it is a link. B3's error policy (status 2 is accepted) and its reads (grep opens what a C1 link points at) are the new surface.

## Findings

#### N1. A fatal grep error (status 2) in the @ filter silently drops every seed after it in the batch, and the walk reports ok

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:1290` (config seeds), `:1314` (C1 seeds); the comment at `:1237-1239`
**Boundary:** B3, B1, B2
**Move:** 3 (error path), 11 (bypass of the filter)
**Confidence:** Medium. The mechanism is executed. The trigger needs an allocation to fail inside grep. That happens under RLIMIT_AS (`ulimit -v`), under `vm.overcommit_memory=2`, or with a newline-free file larger than RAM plus swap under the default heuristic. A loop can write such a file in its own worktree. An honest one under a config dir is unlikely.
**Legibility-target:** walk header line 754 ("Any seed listing find, grep or sha1sum cannot complete fails the walk") and the `outside_seeds` comment at lines 1238-1239 ("an unreadable file is skipped, as outside_ok skips it")

Evidence:
```
nul_list fl xargs -0r -a <(printf '%s\0' "${cx[@]}") sh -c 'grep -lsZF -e @ -- "$@"; [ $? -le 2 ]' sh || return 1
```
GNU grep returns 2 for any error, not only for an unreadable file. On a fatal error such as `memory exhausted` it exits at once, and the files after the failing one in that invocation are never searched. Each line of a newline-free file is held whole in grep's buffer. Executed (Q3, a 300 MB newline-free file, then a file holding `@`, under `ulimit -v 120000`):
```
grep: memory exhausted
grep=2
xargs rc=0
```
Nothing was listed, so the later `@` file would be dropped. End to end (`u2b3b2b-sec2-probe3.sh`): another worktree holds `CLAUDE.md` (300 MB of `a`, no newline) and `CLAUDE.{a..f}.md`, each `n: @docs/<n>.md`. Under `ulimit -v 400000`:
```
grep: memory exhausted
outside_seeds: ok (5)
tree walk: ok
docs/c.md: -
docs/e.md: -
main docs/c.md: -
main docs/e.md: -
```
Without the limit, all six answer `imported` (`outside_seeds: ok (7)`). The two files find listed after the large one are lost in both walks, and both walks report ok. The parent lib (1c820663) read each C1 seed only through `capped_read` (4 MiB), so this is a regression the fix range introduced. A loop that writes the large file can make another session's `CLAUDE.*.md` imports invisible to every gate, for as long as the limit holds. The `-s` flag does not hide the message, so `memory exhausted` also reaches the walk's stderr.

**Recommendation:** Don't treat status 2 as "unreadable". First keep only the seeds `outside_ok` admits, plus the links (in bash, with no fork). Then run grep over those and accept status 0 or 1 only, so any grep error fails the walk. A seed that becomes unreadable between the test and grep then fails closed, as `import_outside` already does. Add Q3/Q4 as a test, for example with a `grep` shim on PATH that exits 2 after the first file.

#### N2. A C1 start that links to a FIFO or a character device (/dev/zero) stalls both walks with no end: grep follows the link, which `outside_ok` would have skipped

**Severity:** Low (fail-closed; availability)
**Location:** `scripts/lib/dev-cycle-read.sh:1211` (`root_starts` lists `-type l`), `:1314` (grep follows it)
**Boundary:** B1, B3
**Move:** 8 (cost per invocation), 3 (error path)
**Confidence:** High (executed)
**Legibility-target:** walk header lines 758-759 ("a seed swapped for a FIFO stalls it, as a checkout file can")

Evidence (Q1, Q2; walk under `timeout 20`):
```
== Q1: other worktree holds CLAUDE.md -> /dev/zero (a link: kept, grep reads it), plus sub/CLAUDE.md importing docs/bar.md
exit 124
  (20 s)
exit 124
  (21 s)
== Q2: other worktree holds CLAUDE.md -> a FIFO (static link, not a swap)
exit 124
  (21 s)
```
On the parent lib, the same trees give `walk: ok` and `docs/bar.md: imported` in 0 s. There, `outside_ok` (`-f`) rejected the link before any read. A loop that runs `ln -s /dev/zero CLAUDE.md` in its own worktree now hangs every other loop's gate. This is a lasting state, not a race. No caller in `scripts/` runs the walks under a timeout. The header names only a seed *swapped* for a FIFO after admission.

**Recommendation:** Apply N1's fix, which also resolves N2: grep reads only what `outside_ok` admits, and a link is kept without being read. Otherwise, name a static link to a FIFO or device in another root in the header beside the swap case.

#### N3. Iteration-1 findings: status after the fix

**Severity:** Informational
**Location:** header `:747-762`, `outside_seeds` comment `:1212-1243`
**Boundary:** B1, B2
**Move:** re-run of the iteration-1 probes
**Confidence:** High (executed)
**Legibility-target:** none; this is a status record

- **F1** (routed to U2b3b2c, now named in the header): reproduced unchanged. Q8/P1 gives `docs/notes.md: imported`, `docs/bar.md: -`, with `walk: ok` in both walks. The header names the route accurately.
- **F2** (named exception, A5): reproduced unchanged. Q8/P3 (a symlinked `.claude/rules` dir) gives `docs/bar.md: -` in both walks. The header and the comment name it.
- **F3** (named): the header now names an unreadable directory in any registered worktree. Its general sentence "Any seed listing find, grep or sha1sum cannot complete fails the walk" does not hold for grep (N1).
- **F4** (named in the comment through contract item 2): Q8/P8 still skips the same-bytes copy (`docs/bar.md: -`). The comment now gives the premise.
- **F5** (fixed): `2>/dev/null` is on the python3 call at line 1270 (read-static).

### Untested bypass candidates

- An allocation failure under the default overcommit heuristic with no rlimit, which needs a newline-free file larger than RAM plus swap (about 23 GB here). It was not run because of the disk and time cost. N1's Confidence rests on the rlimit case.
- A seed that grows between the grep pass and the walk's read, from having no `@` to holding one. This is a time-of-check-to-time-of-use window, the same class as the existing "read as it then is" exception. It is not new in kind, and it was not probed.
- A UTF-16 seed (Q5): `@` bytes are present, so the filter keeps it. The parser then yields no name, because NUL becomes a space. That behaviour predates this fix and is outside the filter.

## Endorsement Claims

- **Claim:** The parser yields a relative or `//` name only after an ASCII `@` byte. The pre-parse transforms (NUL and Unicode spaces to a space, UTF-8 "replace" decoding) never create an `@`, so a seed holding no `@` byte and reached through no link yields no name, apart from `import_outside`'s real-path projection.
  **Location:** `scripts/lib/dev-cycle-read.sh:938-949, 1124-1141, 1169-1176`
  **Evidence:** read-static
  **Verified:** `scan` continues unless `substr(line, i, 1) == "@"`. `names`/`quoted` run only from `scan`. `splice` text is scanned the same way. The sed list maps to a space only. Python's decode replaces with U+FFFD.
  **Not verified:** Claude Code's own mention reader accepting a non-ASCII at-sign (for example U+FF20), which the parser does not model either.
  **route: code-fact-check**
- **Claim:** The filter keeps a config seed reached through a linked directory even when it holds no `@`, and keeps a C1 link with no `@` that points into ROOT_REAL. Both still answer `imported`.
  **Location:** `scripts/lib/dev-cycle-read.sh:1290-1293, 1316-1317`
  **Evidence:** executed
  **Verified:** In Q5, `~/.claude/rules` links to a dir holding a link to `docs/bar.md`, and another worktree's `.claude/rules/x.md` links to `docs/bar.md`. Both walks answer `docs/bar.md: imported`. Invalid UTF-8 before the `@` under `C.UTF-8` also gives `imported`, and GNU grep lists files with a NUL or invalid bytes before the `@` in both locales.
  **Not verified:** a config dir spelled through a linked home whose seeds sit in the real-path spelling only.
- **Claim:** The same-bytes skip does not apply when ROOT_REAL's copy is a link or sits under a linked directory, so the other root's copy is read.
  **Location:** `scripts/lib/dev-cycle-read.sh:1320`
  **Evidence:** executed
  **Verified:** Q6, both variants: the tree walk gives `walk: ok`, `docs/bar.md: imported`. The main walk fails (fail-closed, the checkout's link rule). With a plain equal copy the file is skipped and still `imported` through ROOT_REAL's copy.
  **Not verified:** an untracked nested repo in ROOT_REAL (left to contract item 2: N3/F4).
- **Claim:** A relative `CLAUDE_CONFIG_DIR` fails both walks, and an empty one acts as unset.
  **Location:** `scripts/lib/dev-cycle-read.sh:1247-1251`
  **Evidence:** executed
  **Verified:** Q7. `rel/dir` gives `walk: failed`, `docs/unrelated.md: imported` in both walks. `''` gives `walk: ok`.
  **Not verified:** a caller that changes CLAUDE_CONFIG_DIR between walks without `import_reset` (contract item 4 now names this).
- Scoped prose: `pdir[$p]="$(lower "$p")" || return 1` returns while `IMPORTED`/`IMPORTED_MAIN` still read `error`, which is set before the seed loop (lines 1418, 1475), so a failure here leaves `isimported` answering imported. Read-static. Reusing `os_at` between the config and C1 phases only adds keys, so it cannot drop a seed. Read-static.

## Primitive sweep

Primitive: process exec reading seed paths (blocking reads, error-status policy)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `dev-cycle-read.sh:1211` find -P \| instruction_names (root_starts) | S1 | absolute root, pipefail | cleared; lists `-type l` without a target check (feeds N2) |
| `dev-cycle-read.sh:1290` xargs grep (config seeds) | S2 | find -L `-type f` / `-xtype f` only | N1 (status 2 accepted); no device/FIFO stall, since inputs are regular files at listing time |
| `dev-cycle-read.sh:1292` realpath -mz (config seeds) | S2 | `--`, absolute | cleared |
| `dev-cycle-read.sh:1314` xargs grep (C1 seeds) | S1 | none before the read | N1, N2 |
| `dev-cycle-read.sh:1323` xargs sha1sum -z | S1 | `outside_ok`, non-link, rawfile | cleared; xargs status 123 on any failure fails the walk (Q3: signal gives `xargs rc=123`) |
| `dev-cycle-read.sh:1266` python3 -I | S2 | fixed program, stderr now silenced | cleared (i1 endorsement holds) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| N1 | Fatal grep error (status 2, e.g. ENOMEM) drops every later seed in the batch; walk reports ok | Medium | B3, B1, B2 | `dev-cycle-read.sh:1290, 1314` | Medium |
| N2 | C1 link to a FIFO or /dev/zero hangs both walks with no end (parent: 0 s) | Low | B1, B3 | `dev-cycle-read.sh:1211, 1314` | High |
| N3 | Iteration-1 F1-F5 status: F1/F2 named and reproduced, F3/F4 named, F5 fixed | Informational | B1, B2 | header `:747-762` | High |

## Overall Assessment

The fix range keeps the iteration-1 properties. Paths reach argv absolute or after `--`, a relative config dir now fails closed, and the routed and named exceptions (F1, F2, F4) are stated accurately. The new @ filter is sound in its rule: only an `@` byte or a link can yield a name, by reading and by probes. Its error policy is not. `[ $? -le 2 ]` treats every grep error as "this file is unreadable". A fatal error makes grep stop mid-batch and drop the files it had not reached, with the walk still reporting ok (N1). Because grep now opens C1 links that `outside_ok` would have skipped, a link to /dev/zero or a FIFO in any worktree hangs every gate (N2). One in-place fix closes both: grep only what `outside_ok` admits, keep links without reading them, and accept grep status 0 or 1 only. N1 matters most, because it is the one fail-open path the fix range added. There are no further findings within the code paths read. Endorsement claims marked `route: code-fact-check` await execution verification.

## Goal-Alignment Note

The unit's goal is to start both walks at every outside instruction file a session loads, with the walks a superset that fails closed. The iteration-1 fixes serve the performance goal (85 seeds, about 3 s) without dropping a seed in the honest case, as Q5, Q6 and the suite's unchanged 1177 names show. N1 breaks "fails closed" for the filter's error path, and N2 trades the filter's speed for a durable stall a loop can cause. Both sit in the 12 lines the filter added and both have the same small fix, so they should be fixed before this unit lands rather than routed. N3 confirms that the iteration-1 routing and naming took effect as the rubric records.
