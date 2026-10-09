Commit: 3d2d8c44
# Code Fact-Check Report

**Repository:** /workspace (worktree `/workspace/.claude/wt-build-loop-u2b3a`, branch `feat/build-loop-u2b3a`)
**Scope:** full branch, `git diff main...HEAD -- scripts test`, plus plan step 5's U2b3a bullet and U2b3b carried sub-bullet (claims only), the brief's claims 1-5, and commit 3d2d8c44's message; iteration 1-2 rubric items re-checked as fixed, not re-filed
**Checked:** 2026-10-08 (probe clock 2026-10-09T04:20-04:27Z)
**Replication:** replicate 3 of k=3 (final confirming pass)
**Total claims checked:** 42
**Summary:** 41 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

I read the hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 5 entries). No claim below matches a logged pattern. The one Mostly accurate verdict (Claim 16) is a missing qualifier, not a fabrication. I did not update the log.

### Probe log (executed provenance)

Each probe is a single `set -eu` script. It creates its own `mktemp -d /tmp/u2b3a3-fc3-XXXX` directory and checks `pwd -P` before any `git init` or `git worktree add`. Every process ran under `timeout`. The scripts are in `$S = /tmp/claude-1000/-workspace/53eaab1e-c162-42ac-afd9-547bb673cbb3/scratchpad/u2b3a3-fc3/`, and their captured output is in `$S/logs/`. `lib-head.sh` and `lib-main.sh` are `git show` copies of `scripts/lib/dev-cycle-read.sh` at 3d2d8c44 and at main. P1 used `git show 5516c6e6:` for the old lib. After the runs, no `/tmp/u2b3a3-fc3-*` directory or process was left, `/workspace` still lists 24 worktrees, and the worktree's `git status --porcelain` is empty.

| ID | Command | cwd | Exit | Time (UTC) | Output |
|---|---|---|---|---|---|
| P1 | `bash $S/p1-tests.sh`: `bats -f U2b3a build-loop-check.bats` on a `git archive 3d2d8c44` copy, then on the same copy with the lib swapped to 5516c6e6 and to main; also the dev-cycle.bats sourced-definitions test at HEAD and with main's lib | temp dir | 0 (HEAD 8/8 ok; 5516c6e6: tests 3,4,5,6,8 red; main: 8/8 red; sourced-defs ok at HEAD, red with main's lib) | 04:20:45-04:20:52 | `$S/logs/p1-{head,old,main}-u2b3a.txt`, `p1-{head,main}-sourced.txt`, `$S/p1-run.txt` |
| P2 | `bash $S/p2-workspace.sh $S/lib-{head,main}.sh {0,1} 0` (both walks over /workspace: roots, distinct names, summed work trailers via an import_work wrapper, 100 cached isimported calls each; ONE=1 pins IMPORT_ROOTS to ROOT_REAL) | /workspace (read-only) | 0 | 04:21:48 | `$S/logs/p2.txt` |
| P2b | `bash $S/p2-workspace.sh $S/lib-head.sh 0 {536,556}` (24 real roots plus 536 or 556 synthetic roots `/workspace/.claude/wt-synth-NNNN`) | /workspace (read-only) | 0 | 04:22:31 | `$S/logs/p2-570.txt` |
| P3 | `bash $S/p3-bound.sh $S/lib-head.sh` (time for import_targets to spend one 50,000,000 per-file bound on four 40,000-line shapes, at 1 and 24 roots) | temp repo | 0 | 04:23:15 | `$S/logs/p3-bound.txt` |
| P4 | `bash $S/p4-unit.sh $S/lib-head.sh` (import_readers and parser edge cases in a temp repo with a worktree at `.claude/wt-a`; PATH shims count git and realpath forks) | temp repo | 0 | 04:24:29 | `$S/logs/p4-unit.txt` |
| P5 | `bash $S/p5-misc.sh $S/lib-head.sh` ×3 (24 realpath forks against one `realpath -mz`; import_targets after import_readers with ROOT_REAL empty) | temp repo | 0 | 04:25:06 | `$S/logs/p5-misc.txt` |
| P6 | `TMPDIR=$(mktemp -d /tmp/u2b3a3-fc3-XXXX) timeout 900 bats test/scripts/build-loop-check.bats test/scripts/dev-cycle.bats` | worktree (HEAD 3d2d8c44) | 0 (192/192 ok) | 04:26:10 | `$S/logs/p6-full.txt` |

---

## Claim 1: "a cached isimported over /workspace is back to 3 ms" (rubric A3), and the brief's "Over this repo (/workspace, 24 registered roots) both walks give main's 128 names"

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b3a.md:21`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers /workspace's checkout and main as of the probe time: the root count, both walks' distinct name sets compared with main's lib, and the cached isimported time for one absent path. It does not cover other checkouts, a loaded machine, or uncached walk time.

P2 HEAD output (quoted from `$S/logs/p2.txt`): `tree: rc=0 roots=24 names=128 work=330570 ms=1089`, `main: rc=0 roots=24 names=128 work=330570 ms=1197`, `cached isimported main: 3026 us/call`, `cached isimported tree: 2871 us/call`, and `tree and main name sets identical`. Main's lib also gives `names=128`, and a `cmp` of HEAD's and main's sorted tree name sets printed `head==main names`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1193-1202`, `$S/logs/p2.txt`

---

## Claim 2: Plan U2b3a bullet: "`import_readers` ... sets the root list from ROOT_REAL, every `git worktree list --porcelain -z` path (spelled and real, prunable ones included) and the caller's `IMPORT_READER_ROOTS`; it fails the walk on a listing failure, a path holding a newline, a relative path, or `/`. ... prints it relative to each root holding it, but an outer root whose path down to a nested holding root has a dot component ... The reader set is memoized until import_reset ...; sourcing the lib clears the caller lists"

**Location:** `docs/working/plan-build-loop-handoff.md:289-292`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each listed behaviour against HEAD's lib, and the bullet's history note that printing only the longest root's spelling hid `sub/x.md`. It does not cover the U2b3b sub-bullets.

The listing is `nul_list rs_l git worktree list --porcelain -z || return 1` (`scripts/lib/dev-cycle-read.sh:898`). The refusals are `[[ "$p" == /* && "$p" != *$'\n'* && -n "${p//\//}" ]] || return 1` (`:906`) and `[[ -n "${rs_real[i]//\//}" && "${rs_real[i]}" != *$'\n'* ]] || return 1` (`:913`). P4 printed `root / refused`, `root // refused`, `root /x/.. refused` and `root rel refused`. Test 5 checks the listing failure through a git shim, and test 7 checks a worktree path holding a newline (P6: all ok). The dotnest rule is Claim 19. For the history note, P1 ran the HEAD test file against 5516c6e6's lib (the longest-root projection), and the nested-root test failed at its first assertion: `want: sub/x.md: imported` / `sub/x.md: -` (`$S/logs/p1-old-u2b3a.txt`). The memo and the clearing are Claims 25 and 6.

**Evidence:** `scripts/lib/dev-cycle-read.sh:891-927`, `test/scripts/build-loop-check.bats:1756-1780`, `$S/logs/p4-unit.txt`, `$S/logs/p1-old-u2b3a.txt`

---

## Claim 3: Plan U2b3b carried sub-bullet: "... import_targets falls back to ROOT_REAL alone without a current memo (i2 N3) ...; the dotnest table is rebuilt in every parser process (performance i2 F2, row)"

**Location:** `docs/working/plan-build-loop-handoff.md:299`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two behavioural statements and whether the cited override rows exist. It does not judge whether U2b3b should take these items.

P4 step j: with `IMPORT_READER_ROOTS=/host/cw` and no memo, `@/host/cw/a.md` printed nothing. After `import_readers` it printed `a`…`a.md`. That is the fallback at `:933`: `[[ -z "$IMPORT_READERS_DONE" || "$IMPORT_READERS_DONE" != "$IMPORT_READERS_KEY" ]] || { roots="$IMPORT_ROOTS"; homes="$IMPORT_HOMES"; }`. The dotnest table is built in awk's `BEGIN` (`:822-823`), and import_targets runs one awk per call (`:953-954`). The override rows for i1 F4, i1 F5, i2 N2, i2 N3 and perf i2 F2 are present among this branch's rows in the brief's `overrides.txt`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:928-955`, `:815-827`, `$S/logs/p4-unit.txt`

---

## Claim 4: "Both walks also read the repository's worktree registry (import_readers)."

**Location:** `scripts/lib/dev-cycle-read.sh:42`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both walks' entry. It does not establish that any other lib function reads the registry.

`imported_names` calls `import_readers || { IMPORTED_DONE=""; IMPORTED=error; return 1; }` (`:1049`), and `main_imports` calls `import_readers || { IMPORTED_MAIN_DONE=""; IMPORTED_MAIN=error; return 1; }` (`:1099`). Both run before the cache check. Test 5's git shim, which fails only `git worktree`, makes both walks report `walk failed` (P6 ok).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1045-1052`, `:1094-1101`, `test/scripts/build-loop-check.bats:1793-1798`

---

## Claim 5: Contract item 4: "... neither walk's cache key holds them (both hold import_readers' roots and homes, so HOME and IMPORT_READER_* need no reset; the worktree registry is read again after a reset or when one of those changes, so set them before a decision's first walk: item 9)."

**Location:** `scripts/lib/dev-cycle-read.sh:64-68`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the re-read triggers (reset, HOME change, caller-list change) and the walk keys. It does not cover a change of the current directory without a ROOT_REAL change; need_root stops that case.

The memo key is `"${#a}:$a ${#b}:$b ${#c}:$c ${#d}:$d"` over ROOT_REAL, `IMPORT_HOME_DONE` and the two caller lists (`:888-889`). The walk keys are `"$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"` (`:1051`) and `"$MAIN_SHA $MAIN_BY_NAME $IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"` (`:1100`). P4 results: `forks=0` on a repeat call, `after-change-forks=2` after `IMPORT_READER_ROOTS=/z`, `after-reset-forks=2`, and `forks=3` after a HOME change (b, b2). A worktree added mid-decision gave `0` hits before `import_reset` and `1` after (b3). Test 8 checks the same behaviour through isimported (P6 ok).

**Evidence:** `scripts/lib/dev-cycle-read.sh:887-897`, `:1049-1052`, `:1099-1101`, `$S/logs/p4-unit.txt`

---

## Claim 6: Contract item 9: "Set IMPORT_READER_ROOTS and IMPORT_READER_HOMES after sourcing the lib (which clears them) and before a decision's first walk ... never from the environment: each is newline-separated absolute paths"

**Location:** `scripts/lib/dev-cycle-read.sh:85-89`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers "sourcing clears them" and the format the lib accepts. It does not cover the prescriptive parts (settings from main, U2b3b), because no caller sets the lists yet: grep over `scripts/` finds IMPORT_READER_* only in the lib.

The lib sets `IMPORT_READER_ROOTS=""; IMPORT_READER_HOMES=""` at source time (`:883`). In P4 step k2, inherited values `/inh` printed `[][]` after sourcing. Test 3's inherited-env row reads `docs/h.md -` (P6 ok). On 5516c6e6 that row was red: `want: docs/h.md: -` / `docs/h.md: imported` (P1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:883`, `test/scripts/build-loop-check.bats:1748-1751`, `$S/logs/p4-unit.txt`, `$S/logs/p1-old-u2b3a.txt`

---

## Claim 7: imported_names comment: "~/ against every reader home, and drops paths outside every reader root: import_readers ... returns 1 ... when ... import_readers or the parser ... fails ... One result is cached, for the root in IMPORTED_DONE, keyed on import_readers's roots (ROOT_REAL first) and homes; a call for another reader set recomputes it, and a cached error returns 1 again."

**Location:** `scripts/lib/dev-cycle-read.sh:570-577`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the key, the recompute and the failure on an import_readers failure. It does not re-check the comment's older clauses (start listing, budget), which this branch did not change.

```bash
# scripts/lib/dev-cycle-read.sh:1049-1052
  import_readers || { IMPORTED_DONE=""; IMPORTED=error; return 1; }
  # The roots never hold an empty line, so the blank line ends them.
  [[ "$IMPORTED_DONE" == "$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES" ]] && { [[ "$IMPORTED" != error ]]; return; }
  IMPORTED_DONE="$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"; IMPORTED=error
```
(excerpt ends :1052; enclosing imported_names() continues to :1078 — read)

A cached error returns 1 through `[[ "$IMPORTED" != error ]]`. P4 step a shows ROOT_REAL listed first in IMPORT_ROOTS. Test 8's `tree a0 -` then `tree a1 imported` shows a recompute when the reader set changes (P6 ok).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1045-1078`, `test/scripts/build-loop-check.bats:1824-1845`

---

## Claim 8: main_imports comment: "the result is cached for the commit, MAIN_BY_NAME and import_readers's roots and homes in IMPORTED_MAIN_DONE, never the checkout ... a cached error returns 1 again."

**Location:** `scripts/lib/dev-cycle-read.sh:607-611`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the key's parts. It does not cover MAIN_SHA's freshness, which predates this branch.

`IMPORTED_MAIN_DONE="$MAIN_SHA $MAIN_BY_NAME $IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"` (`:1101`), and the hit returns `[[ "$IMPORTED_MAIN" != error ]]` (`:1100`). Test 8's main rows `a0 -`, `a1 imported`, `h1 -`, `h2 imported` pass (P6).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1094-1101`, `test/scripts/build-loop-check.bats:1843-1844`

---

## Claim 9: "import_reset: the next call of either walk walks again (caller contract item 4)."

**Location:** `scripts/lib/dev-cycle-read.sh:617-618`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both walk keys and the reader memo. It does not cover IMPORT_HOME_DONE, which is keyed on HOME and needs no reset.

`import_reset() { IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""; IMPORT_READERS_DONE=""; }` (`:618`). In P4 b3 the registry was re-read after the reset (`0`, then `1`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:618`, `$S/logs/p4-unit.txt`

---

## Claim 10: "the parser's work (the candidate and comment-splice characters it scans, each resolved spelling it joins, which for a relative name carries a root, so a longer root buys less, and one unit per reader root for each spelling it projects ..."

**Location:** `scripts/lib/dev-cycle-read.sh:625-628`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the per-projected-spelling charge and the join charge. It does not cover the uncharged dotnest table build in BEGIN, which is override-deferred (perf i2 F2).

`work += nr; if (work > wmax) exit 3` (`:755`) runs after the `tried` check, so it runs once per distinct spelling. P4 step g: `@/abc` gave trailer `/24` at 1 root and `/32` at 3 roots. Four candidates (`/`, `/a`, `/ab`, `/abc`) cost 10 in emit and 10 in put, plus 4×nr. That is 24 at 1 root and 32 at 3, exactly as measured.

**Evidence:** `scripts/lib/dev-cycle-read.sh:712-761`, `$S/logs/p4-unit.txt`

---

## Claim 11: "the unit of its per-file bound of 50,000,000, about 0.1-5 s here with one root and about 9 s with 24, by the name's shape"

**Location:** `scripts/lib/dev-cycle-read.sh:628-630`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers four 40,000-line adversarial shapes at 1 and 24 roots on this machine. It does not establish the 0.1 s lower end (my shapes were all heavy), worse shapes, or timings under load.

P3 output (`$S/logs/p3-bound.txt`). At 1 root: `slashuniq ms=3148`, `plain ms=2247`, `abs ms=5304`, `tilde ms=4166`. At 24 roots: `slashuniq ms=9338`, `plain ms=2762`, `abs ms=6170`, `tilde ms=6656`. Every run returned rc=1 because the bound was spent. The worst case is 5.3 s at one root and 9.3 s at 24, which matches "about 5" and "about 9".

**Evidence:** `scripts/lib/dev-cycle-read.sh:826`, `$S/p3-bound.sh`, `$S/logs/p3-bound.txt`

---

## Claim 12: "/workspace's walks spend about 330,600 each over its 24 reader roots (8,200 with one; 2026-10-08)."

**Location:** `scripts/lib/dev-cycle-read.sh:632`
**Type:** Performance / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers HEAD's parser over /workspace at the probe time, with IMPORT_ROOTS pinned to ROOT_REAL for the one-root figure. It does not cover future changes to the repo.

P2: `work=330570` for each walk at `roots=24`, and `work=8240` for each walk at `roots=1` (`$S/logs/p2.txt`). Main's lib gives 8110.

**Evidence:** `$S/logs/p2.txt`

---

## Claim 13: "That work grows with the square of the root count (each relative name is joined once per root, and each join is projected against every root), so the honest walks spend this bound near 570 roots and then fail closed"

**Location:** `scripts/lib/dev-cycle-read.sh:633-636`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the mechanism and the order of magnitude, measured with 31-character synthetic roots. It does not give an exact root count: the threshold moves with root length.

The mechanism is in the code. Each root runs a join, `for (r = 1; r <= nr; r++) for (i = 0; i <= nd; i++) put(roots[r] "/" dirs[i] "/" c)` (`:729`), and each put charges `work += nr` (`:755`). P2b measured `roots=560 ... work=46308650` and `roots=580 ... work=49469850`, both passing. Extrapolating, the bound is spent at about 583 roots with these spellings. "near 570" is within that margin, and prior perf i2 measured 47.5M at 560. Below about 100 roots the linear join charge still dominates (24 roots: 40× the one-root work, not 576×), but the stated "grows with the square" holds asymptotically.

**Evidence:** `scripts/lib/dev-cycle-read.sh:729`, `:755`, `$S/logs/p2-570.txt`

---

## Claim 14: import_targets "also reads ... import_readers' IMPORT_ROOTS and IMPORT_HOMES when its memo key is current (else ROOT_REAL alone and import_home's home: a call outside a walk)"

**Location:** `scripts/lib/dev-cycle-read.sh:654-657`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the selection between the memo and the fallback. It does not cover a memo computed for an empty ROOT_REAL; Claim 16 covers that case.

`roots="${ROOT_REAL:-}"` and `homes="$IMPORT_HOME"$'\n'"$IMPORT_HOME_REAL"` are replaced by the memo only when `IMPORT_READERS_DONE` equals the current key (`:929-933`). P4 step j: `nomemo-rc=0` with no output for `/host/cw/a.md`, then output `a`…`a.md` once the memo is current.

**Evidence:** `scripts/lib/dev-cycle-read.sh:928-955`, `$S/logs/p4-unit.txt`

---

## Claim 15: Superset statement: "it is kept only when it lies below a reader root (import_readers: ROOT_REAL, every registered worktree, the caller's IMPORT_READER_ROOTS), and printed relative to each root holding it but an outer one whose path down to a nested root holding it has a dot component (the parser's dotnest ...). A relative name is resolved against each root's copy of its directory ... and a ~/ name is joined to each reader home ..., in spelled and real forms. Known exceptions ...: a session in a checkout or under a home import_readers does not list"

**Location:** `scripts/lib/dev-cycle-read.sh:681-694`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers keep, project and dotnest for absolute, relative and ~/ names. It does not re-check the older exception list (case-insensitive file systems, approved external includes, decoding), which this branch did not change.

P4 step i used roots `/r`, `/r/.claude/w`, `/r/sub` and `/r/a.b`. It printed `x.md` but not `.claude/w/x.md`, both `sub/y.md` and `y.md`, and both `a.b/z.md` and `z.md`. So only the dot-component outer spelling is dropped. Tests 1-4 (absolute into another worktree, relative re-entry, caller roots and homes, non-dot nesting) pass at HEAD (P6). P4 step a lists a symlinked caller root once when its real path is already a root, and lists both spellings otherwise (`:915-917`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:721-760`, `:858-927`, `$S/logs/p4-unit.txt`

---

## Claim 16: "It returns 1 when sed, python3, awk or import_home fails, when ROOT_REAL is empty, when a ~/ name appears and the home is not absolute ..."

**Location:** `scripts/lib/dev-cycle-read.sh:701-702`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers import_targets with an empty ROOT_REAL, with and without a reader memo. It does not show that any caller reaches the memo case: both walks run need_root, which exits on an empty ROOT_REAL, before import_readers.

Without a memo the claim holds. The parser runs `nr = split(ENVIRON["IT_ROOTS"], roots, "\n"); if (nr == 0 || roots[1] == "") exit 2` (`:820`), and P4 step f printed `awk-rc=2` and `it-rc=1`. The memo case differs. import_readers skips a blank entry (`[[ -n "$p" ]] || continue`, `:905`), so when ROOT_REAL is empty it succeeds and memoizes the registry's roots under a key that holds the empty ROOT_REAL. A later import_targets then uses those roots. P5 printed `readers rc=0 roots=[/tmp/.../repo]`, then `a` and `it-rc=0`. The parser's real condition is an empty first reader root. The precise version is "when ROOT_REAL is empty (unless import_readers ran for the empty root: its first root is then the registry's)". Another option is for import_readers to refuse an empty ROOT_REAL. The sentence predates this branch, but import_readers changed its truth. Impact is low because no caller reaches this case.

**Evidence:** `scripts/lib/dev-cycle-read.sh:820`, `:899-909`, `:929-933`, `$S/logs/p4-unit.txt`, `$S/logs/p5-misc.txt`

---

## Claim 17: emit: "~/ joins the home directory ..., for each reader home (the home of this process first), each in its spelled and real forms"; `if (substr(homes[1], 1, 1) != "/") exit 4`

**Location:** `scripts/lib/dev-cycle-read.sh:718-725`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the exit-4 rule keyed on the first home and the join over every non-empty home. It does not cover how Claude Code reads an empty HOME, which is outside this repo.

P4 step h gave `IT_HOMES=$'rel\n/r'` → `awk-rc=4`, and `$'/r\nrel'` → `a` printed and `awk-rc=0`. The empty entry is skipped by `if (homes[i] != "")` (`:723`). P4 a prints IMPORT_HOMES as own home then `/host`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:712-730`, `$S/logs/p4-unit.txt`

---

## Claim 18: "A session in any checkout resolves the name against its own copy of the directory, so a .. can re-enter a sibling or nested worktree (U2b3a)."

**Location:** `scripts/lib/dev-cycle-read.sh:727-729`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers registered worktrees, both nested and sibling. It does not cover unregistered checkouts, which are a named exception.

`for (r = 1; r <= nr; r++) for (i = 0; i <= nd; i++) put(roots[r] "/" dirs[i] "/" c)` (`:729`). Test 2 (`@.claude/wt-b/docs/n.md`, `@../side/docs/s.md` read from a gate worktree) passes at HEAD and is red on main's lib (P1, P6).

**Evidence:** `scripts/lib/dev-cycle-read.sh:729`, `test/scripts/build-loop-check.bats:1728-1739`, `$S/logs/p1-main-u2b3a.txt`

---

## Claim 19: put: "Relative to every root holding it, but an outer root whose path down to a nested root holding it has a dot component (dotnest) ... while a root nested at any other path (a stale registry entry at sub/) must not take the outer path from the walk ... The loop over the roots is charged as work too"

**Location:** `scripts/lib/dev-cycle-read.sh:747-760`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the projection loop, the dotnest test and the charge. It does not cover roots spelled through different symlinks that do not textually nest; those are projected per spelling.

```awk
# scripts/lib/dev-cycle-read.sh:755-760
  work += nr; if (work > wmax) exit 3
  nho = 0; for (i = 1; i <= nr; i++) if (index(out, pre[i]) == 1 && length(out) > length(pre[i])) h[++nho] = i
  for (i = 1; i <= nho; i++) {
    for (j = 1; j <= nho; j++) if ((h[i], h[j]) in dotnest) break
    if (j > nho) show(substr(out, length(pre[h[i]]) + 1))
  }
```
(excerpt ends :760; enclosing put() ends :761 — read)

P4 step i and test 4 (stale `sub/` entry and caller root at `sub/`) confirm it. Test 4 was red on 5516c6e6 (P1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:731-761`, `test/scripts/build-loop-check.bats:1756-1780`, `$S/logs/p4-unit.txt`

---

## Claim 20: BEGIN: "IT_ROOTS and IT_HOMES: newline-separated, ROOT_REAL and the home of this process first (import_readers)"; exit 2 on an empty first root; dotnest built here

**Location:** `scripts/lib/dev-cycle-read.sh:819-824`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the order import_readers produces and the BEGIN checks. It does not cover the fallback path's order, which is ROOT_REAL alone.

P4 step a's IMPORT_ROOTS starts with the repo's ROOT_REAL, and IMPORT_HOMES starts with `$T/home`. Step f gives `awk-rc=2` on `IT_ROOTS=`. The dotnest condition is `index("/" substr(pre[j], length(pre[i]) + 1), "/.")` (`:823`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:815-827`, `$S/logs/p4-unit.txt`

---

## Claim 21: "IMPORT_ROOTS holds ROOT_REAL, every path git worktree list registers for this repository (prunable ones too: a host path such as /home/magfrump/cw-egress-verify) and IMPORT_READER_ROOTS; IMPORT_HOMES holds import_home's two spellings and IMPORT_READER_HOMES. Each is newline-separated, ROOT_REAL or this process's home first, and lists every entry as written and as realpath -m reads it, once."

**Location:** `scripts/lib/dev-cycle-read.sh:859-865`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the list contents, order and deduplication. It does not establish that the host path stays registered.

`/workspace`'s porcelain listing holds `worktree /home/magfrump/cw-egress-verify` followed by `prunable gitdir file points to non-existent location`. The parse `[[ "$p" != "worktree "* ]] || rs_r+=("${p#worktree }")` (`:899`) takes every `worktree` record whatever its other lines say. Deduplication uses `rs_seen[$t$p]` (`:916-917`). P4 a lists the symlink `lnk`, whose real path is ROOT_REAL, only as spelled.

**Evidence:** `scripts/lib/dev-cycle-read.sh:898-919`, `$S/logs/p4-unit.txt`

---

## Claim 22: "IMPORT_READER_ROOTS and IMPORT_READER_HOMES are the caller's (contract item 9): newline-separated absolute paths, blank lines skipped, for the host checkout Q-123 names and the host HOME ... Sourcing the lib clears them, so the environment never sets them."

**Location:** `scripts/lib/dev-cycle-read.sh:865-869`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers blank-line skipping, clearing and the Q-123 reference. It does not cover how U2b3b will fill the lists.

P4 a passed `$'\n$T/lnk\n\n/host/cw\n'` and `$'\n/host\n'` and got `rc=0` with no empty entries. Test 5's `T_READER_ROOTS=$'/a\n\n/b\n'` gives `walk ok`. Q-123 ("host-checkout-common-dir") asks whether the host's `~/claude-workflows` is the same repository as `/workspace` (`docs/working/questions-archive.md:2084-2087`). Clearing is Claim 6.

**Evidence:** `scripts/lib/dev-cycle-read.sh:900-908`, `test/scripts/build-loop-check.bats:1793`, `$S/logs/p4-unit.txt`

---

## Claim 23: "The parser prints a name relative to every root holding it but a dot-nested outer one (its comment says why), so a root can add names and hide only dot paths."

**Location:** `scripts/lib/dev-cycle-read.sh:869-871`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the projection: an added root can only omit an outer spelling holding a dot component. It does not establish that dot paths are harmless to every consumer; the Won't-Fix override row covers that.

`show` runs for every holding root except when `(h[i], h[j]) in dotnest` (`:758-759`), and dotnest requires a `/.` component between the roots (`:823`). The omitted outer spelling therefore always has a component starting with `.`. P4 i shows the non-dot `a.b` nesting keeps both spellings.

**Evidence:** `scripts/lib/dev-cycle-read.sh:755-760`, `:822-823`, `$S/logs/p4-unit.txt`

---

## Claim 24: "It returns 1 when import_home or the listing fails, or a root or a caller's home is not absolute, holds a newline, or is / alone as written or as realpath reads it ... This process's own home is kept as the parser takes it (a relative one fails only a ~/ name), but one holding a newline is read as empty, which fails only a ~/ name too."

**Location:** `scripts/lib/dev-cycle-read.sh:871-876`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each listed refusal and both own-home cases. It does not cover a caller list entry holding a newline, which cannot exist because the lists are newline-split. Registry paths are covered by test 7.

P4 e refused `/`, `//`, `/x/..` and `rel` as both home and root. P4 c with `HOME=relhome` gave `H:relhome`, `tilde-rc=1` and `plain-rc=0`. P4 d with a newline HOME and `/host` gave `H:[` / `/host]`, an empty first entry, and `tilde-rc=1`. The code is `[[ "$p" != *$'\n'* ]] || p=""` (`:921`). Tests 5-7 pass at HEAD. Tests 5 and 6 were red on 5516c6e6 (P1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:893-925`, `$S/logs/p4-unit.txt`, `$S/logs/p1-old-u2b3a.txt`

---

## Claim 25: "The result is memoized in IMPORT_READERS_DONE, keyed on ROOT_REAL, HOME and the caller's two lists, until import_reset (contract item 4): the registry is read once per decision, so one decision sees one root set and a cache hit forks nothing here"

**Location:** `scripts/lib/dev-cycle-read.sh:877-880`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers memo hits, recompute triggers and fork counts in import_readers. It does not cover forks elsewhere in a cached walk (need_root's `$(pwd -P)`), which the claim scopes out with "here".

P4 b: `forks=0` on the second call (PATH shims log every git and realpath call). On a hit, import_home returns at `[[ "$IMPORT_HOME_DONE" != "$key" ]] || return 0` (`:853`) without forking. Test 8's `tree w1 -` confirms one registry read per decision. It was red on 5516c6e6 (P1: `want: tree w1: -`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:851-857`, `:891-897`, `$S/logs/p4-unit.txt`

---

## Claim 26: "Not covered: a hostile loop can rewrite the worktree registry in the shared common dir, dropping a root (a Q-103 residual)."

**Location:** `scripts/lib/dev-cycle-read.sh:881-882`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the reference and the mechanism (the registry is read from git). It does not judge the residual's acceptability.

The registry comes from `git worktree list` (`:898`), which reads the common dir. "Q-103 residual" is the repo's established label for hostile-loop cases (`docs/working/questions-archive.md:2352`: "R8 ... is a Q-103 residual (row 509)"), and the plan bullet `docs/working/plan-build-loop-handoff.md:292` carries the same residual.

**Evidence:** `scripts/lib/dev-cycle-read.sh:898`, `docs/working/plan-build-loop-handoff.md:292`

---

## Claim 27: "import_readers_key: IMPORT_READERS_KEY, the key import_readers memoizes on (after import_home), each part led by its length so no part can run into the next."

**Location:** `scripts/lib/dev-cycle-read.sh:884-890`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the key's injectivity over its four parts. It does not cover the walk keys, which use a different separator (Claim 30).

`IMPORT_READERS_KEY="${#a}:$a ${#b}:$b ${#c}:$c ${#d}:$d"` (`:889`). Each part is read by its length prefix, so the encoding is injective. The `(after import_home)` ordering holds at both callers: `:893-894` and `:930-932`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:887-890`

---

## Claim 28: "resolved in one realpath call (a fork per root cost 14 ms over 24 roots)."

**Location:** `scripts/lib/dev-cycle-read.sh:902-903`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers 24 `realpath -m` forks against one batched call over /workspace's registry on this machine. It does not reproduce the original measurement's conditions.

P5 (three runs): `forks: 12955 us` / `11646 us` / `11872 us` against `batched: 1132 us` / `988 us` / `1199 us`. That is 12-13 ms against the claimed 14 ms, within run-to-run variation for a historical figure.

**Evidence:** `scripts/lib/dev-cycle-read.sh:910`, `$S/logs/p5-misc.txt`

---

## Claim 29: "This process's own homes come first, kept as the parser reads them."

**Location:** `scripts/lib/dev-cycle-read.sh:920-923`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers order and deduplication against the caller's homes. It does not cover IMPORT_HOME's own derivation, which predates this branch.

The code is `rs_h=(); for p in "$IMPORT_HOME" "$IMPORT_HOME_REAL"; do ...` and then `for p in "${rs_ho[@]}"; do [[ "$p" == "${rs_h[0]}" || "$p" == "${rs_h[1]-}" ]] || rs_h+=("$p"); done` (`:921-923`). P4 a and d show the own home first.

**Evidence:** `scripts/lib/dev-cycle-read.sh:920-925`, `$S/logs/p4-unit.txt`

---

## Claim 30: "The roots never hold an empty line, so the blank line ends them."

**Location:** `scripts/lib/dev-cycle-read.sh:1050`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers IMPORT_ROOTS as import_readers builds it. It does not cover IMPORT_HOMES, which can start with an empty entry. That does not matter here, because the first `\n\n` is unambiguous.

Blank entries are skipped (`[[ -n "$p" ]] || continue`, `:905`), and a realpath of `/` alone or one holding a newline is refused (`:913`). No root entry is empty and none holds a newline, so the first blank line ends the roots.

**Evidence:** `scripts/lib/dev-cycle-read.sh:904-913`, `:1051`

---

## Claim 31: truthrule: "the parser's dotnest omits only such paths: keep the two equal"

**Location:** `scripts/lib/dev-cycle-read.sh:1220`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the equivalence: every spelling dotnest omits is a path truthrule refuses as `dot`. It does not cover truthrule's earlier words (case, instr), which return first with a different TRUTH_WHY but still refuse.

An omitted spelling is `substr(out, length(pre[i]) + 1)` for an outer root i that has a nested holding root j with a `/.` component between them (`:823`). That spelling begins with the inner root's relative path, so `"/$1" == */.*` (`:1220`) matches. Test 4's last assertions pin `.claude/wt-a/sub/y.md dot` and `docs/.wt/a/q.md dot` (P6 ok).

**Evidence:** `scripts/lib/dev-cycle-read.sh:822-823`, `:1216-1220`, `test/scripts/build-loop-check.bats:1777-1779`

---

## Claim 32: imps comment: "T_READER_ROOTS and T_READER_HOMES, when set, become the caller's IMPORT_READER_ROOTS and IMPORT_READER_HOMES after the lib is sourced (it clears them)."

**Location:** `test/scripts/build-loop-check.bats:16-17`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the imps helper only. Other helpers do not honour T_READER_*, which is override-deferred (api i2 N5).

`[[ -z "${T_READER_ROOTS+set}" ]] || IMPORT_READER_ROOTS="$T_READER_ROOTS"` follows `source "$1"` (`:20-21`). Test 3's T_READER rows read imported (P6 ok).

**Evidence:** `test/scripts/build-loop-check.bats:18-25`

---

## Claim 33: Test "both walks read an absolute name into another worktree of the repo as that repo path, as the gate runs from its own worktree (U2b3a)"

**Location:** `test/scripts/build-loop-check.bats:1717-1726`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers what the test checks (both walks from a `../gate` worktree, with a control path) and that it is red on main. It does not cover the host alias (U2b3b).

It writes `See @<main checkout>/docs/abs.md`, runs both walks from `../gate`, and wants `docs/abs.md imported` and `docs/other.md -`. It is ok at HEAD and `not ok 1` with main's lib (P1).

**Evidence:** `test/scripts/build-loop-check.bats:1717-1726`, `$S/logs/p1-main-u2b3a.txt`

---

## Claim 34: Test "both walks resolve a relative name against every worktree's directory, so it can re-enter a nested or sibling worktree (U2b3a; rows 425, 432)"

**Location:** `test/scripts/build-loop-check.bats:1728-1739`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the nested (`.claude/wt-b`) and sibling (`../side` from wt-b) shapes and the test's red on main. It does not cover deeper `..` chains.

The comment "From the main checkout, .claude/wt-b/ is a nested worktree; from wt-b, ../side/ is its sibling" matches the fixture. From the gate, `docs/n.md` resolves only through the main root's projection into the wt-b root, and `docs/s.md` only through wt-b's `..`. It is ok at HEAD and red on main (P1).

**Evidence:** `test/scripts/build-loop-check.bats:1728-1739`, `$S/logs/p1-main-u2b3a.txt`

---

## Claim 35: Test "the caller's reader roots and homes add the host checkout's spellings, and the environment does not set them (...)"

**Location:** `test/scripts/build-loop-check.bats:1741-1754`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the baseline, the T_READER row and the inherited-env row in both walks. It does not cover a caller list holding several entries; test 5 has one.

It is red on 5516c6e6 at the inherited-env row (`want: docs/h.md: -` / `docs/h.md: imported`, P1), which matches the rubric's "A2 test red on 5516c6e6". It is ok at HEAD.

**Evidence:** `test/scripts/build-loop-check.bats:1741-1754`, `$S/logs/p1-old-u2b3a.txt`

---

## Claim 36: Test "a root nested in another at a non-dot path keeps the outer path's names: a stale registry entry or a caller root inside the repo (...)"; comment "A worktree at sub/ whose directory was then removed: git lists it as prunable."

**Location:** `test/scripts/build-loop-check.bats:1756-1780`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the stale-entry case, the caller-root case (as written and through a symlink, after pruning) and the truthrule pin. It does not cover a live, non-stale worktree at a non-dot path.

The test asserts the registry lists `worktree $r/sub` before walking. It is red on 5516c6e6 at `want: sub/x.md: imported` / `sub/x.md: -` (P1), the A1 defect. It is ok at HEAD.

**Evidence:** `test/scripts/build-loop-check.bats:1756-1780`, `$S/logs/p1-old-u2b3a.txt`

---

## Claim 37: Test "both walks fail closed on a reader root or home they cannot model, and when git worktree list fails (...)"; comment "Blank lines between entries are skipped, not refused."

**Location:** `test/scripts/build-loop-check.bats:1782-1799`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers eight refused shapes, the blank-line case and the listing failure, in both walks. It does not cover a realpath failure.

The git shim `[ "$1" = worktree ] && exit 1` fails only the listing. The test is red on 5516c6e6 at `want: walk: failed` / `walk: ok` (P1: the `/x/..` home, G3), and ok at HEAD.

**Evidence:** `test/scripts/build-loop-check.bats:1782-1799`, `$S/logs/p1-old-u2b3a.txt`

---

## Claim 38: Test "a HOME holding a newline fails a walk only when a ~/ name needs it, as a relative HOME does (...)"; comment "The walk fails, and a failed walk answers imported for every path (fail closed)."

**Location:** `test/scripts/build-loop-check.bats:1801-1813`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the newline-HOME case in both walks. The relative-HOME comparison in the name is confirmed by P4 c, not by this test.

It is red on 5516c6e6 (`want: walk: ok` / `walk: failed`, P1: G2) and ok at HEAD. isimported answers imported on a failed walk through `main_imports || return 0` (`scripts/lib/dev-cycle-read.sh:1198`).

**Evidence:** `test/scripts/build-loop-check.bats:1801-1813`, `scripts/lib/dev-cycle-read.sh:1193-1202`, `$S/logs/p4-unit.txt`

---

## Claim 39: Test "a worktree path holding a newline fails both walks (U2b3a)"

**Location:** `test/scripts/build-loop-check.bats:1815-1822`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the case where git accepts the path (it did here: no skip). It is not a regression guard against 5516c6e6, where it also passes. It is red only against main.

It reads `ok 7` at HEAD and at 5516c6e6, and `not ok 7` on main (P1). The refusal is `"$p" != *$'\n'*` (`:906`).

**Evidence:** `test/scripts/build-loop-check.bats:1815-1822`, `$S/logs/p1-{head,old,main}-u2b3a.txt`

---

## Claim 40: Test "both walk caches key on the reader set, which is read once until import_reset (...)"; comment "A worktree added mid-decision is seen only after import_reset."

**Location:** `test/scripts/build-loop-check.bats:1824-1845`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the caller-list key rows in both walks and the mid-decision registry row for tree. Main's `w1` is not asserted, because the worktree already exists by then.

It is red on 5516c6e6 at `want: tree w1: -` (P1: the per-call reader set, A3) and ok at HEAD.

**Evidence:** `test/scripts/build-loop-check.bats:1824-1845`, `$S/logs/p1-old-u2b3a.txt`

---

## Claim 41: dev-cycle.bats "sourcing the reader lib defines its functions and calls neither git nor perl" (now listing import_readers, import_readers_key and the five new variables)

**Location:** `test/scripts/dev-cycle.bats:1101-1118`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers definition and no-git-at-source. It does not assert that the caller lists are cleared; Claim 6 and test 3 do.

It is ok at HEAD and red with main's lib (P1: `p1-main-sourced.txt` rc=1). The definitions are at `:883`, `:887` and `:891`.

**Evidence:** `test/scripts/dev-cycle.bats:1101-1118`, `$S/logs/p1-head-sourced.txt`, `$S/logs/p1-main-sourced.txt`

---

## Claim 42: Commit 3d2d8c44: "Notes: text and test changes only, besides the rename."

**Location:** commit `3d2d8c44` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `git diff c9197fd2 3d2d8c44 -- scripts`. It does not cover the test or plan hunks, which the message lists.

Paraphrased (no quote available, because the claim is about the absence of code changes across a diff): after filtering comment lines out of the diff, only the rename of `readers_key`/`READERS_KEY` to `import_readers_key`/`IMPORT_READERS_KEY` remains, plus a trailing comment on truthrule's dot line. A grep for `reader_set|readers_key|READERS_KEY|IT_ROOT\b|IT_HOME_REAL|homereal|longest` over `scripts test` finds no stale names.

**Evidence:** `scripts/lib/dev-cycle-read.sh:884-933`, `:1220`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
None.

### Mostly Accurate
- **Claim 16** (`scripts/lib/dev-cycle-read.sh:701-702`): "returns 1 ... when ROOT_REAL is empty" fails if import_readers has already memoized for an empty ROOT_REAL. It skips the blank root, so import_targets then uses the registry's first root and returns 0 (P5). No caller reaches this, because need_root exits first. Tighten to "an empty first reader root", or have import_readers refuse an empty ROOT_REAL. Low impact.

### Unverifiable
None.

### Iteration 1-2 rubric items re-checked
These are fixed, not re-filed. A1 (Claims 19 and 36), A2 (6, 35), A3 (25, 40, 1), G2 (24, 38), G3 (24, 37), G5 (10), G7 (20), G10 (41), B1 (15, 31), B2 (5, 6, 11, 12, 36), H1 (13), H3 (27, 4). P6 runs the full suites at HEAD: 192/192 ok.

---

## Goal-Alignment Note

- **Success criterion (verbatim):** A markdown report saved to the output path below, structured per the code-fact-check skill, with `Commit: 3d2d8c44` as its first line.
- **Answered:** Brief claims 1-5, all fully checked, most by execution. import_readers' listing, refusals, own-home handling, memo and Q-103 wording. The parser's per-root and per-home resolution, the exit-4 and exit-2 rules, dotnest and the `work += nr` charge. The header's Inputs line, contract items 4 and 9, the superset statement and the IMPORT_WORK_MAX figures (re-measured: 330,570 and 8,240 work; 5.3 s and 9.3 s per bound; the bound still holds at 580 roots). Every U2b3a test and the sourced-definitions test, run against 5516c6e6 and main. /workspace's 24 roots, the 128 names and the ~3 ms cached isimported. The result is 41 Verified and 1 Mostly accurate (Claim 16, low impact, a path no caller reaches).
- **Out of scope:** U2b3b and U2c behaviour, and the override rows the brief lists as settled. The prescriptive halves of contract item 9 are also out of scope, because no caller sets the lists yet.
- **Escalate:** nothing blocking. Claim 16 is a comment-precision item, or a one-line guard, for the orchestrator to classify.
- **Decisions I made:** I ran both walks read-only over `/workspace` (cwd `/workspace`) for brief claim 5, because the claim is about that checkout. I measured the root-count threshold with 31-character synthetic roots. I kept probe logs in my scratch dir, because the brief allows only this report in the worktree.
