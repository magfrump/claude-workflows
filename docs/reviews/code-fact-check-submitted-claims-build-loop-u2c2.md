Commit: 8786f8fc

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2c2 (branch feat/build-loop-u2c2)
**Scope:** Stage 2.5 submitted claims only (security-reviewer S1-S7, performance-reviewer P1-P5) against `scripts/lib/dev-cycle-read.sh` and `scripts/build-loop.sh` at 8786f8fc. No fresh harvesting; numbering continues from the merged report's claim 49.
**Checked:** 2026-10-10
**Total claims checked:** 12
**Summary:** 11 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 8 entries) read first. No submitted claim matches a logged pattern.

**Execution provenance (applies to every `executed` claim below).** Each probe is one `set -eu` script that makes its own `fcsub-XXXX` dir with `mktemp` and removes it at the end. Its git fixtures have `HOME` inside that dir, `GIT_CONFIG_GLOBAL=/dev/null` and a `pwd` guard. The scripts and their logs are in `/tmp/claude-1000/-workspace/843b51ad-a12f-4e61-b040-53f5def15aef/scratchpad/u2c2-review/`, as `fcsub-*.sh` and `fcsub-logs/*.log`. Each was run as `bash <script> > fcsub-logs/<name>.log 2>&1` from that directory. Lib calls `cd` into the fixture repo or into `/workspace/.claude/wt-build-loop-u2c2`, read-only. The timing probes `fcsub-perf-{real,tree,fail,check}.sh` re-run the performance critic's `perff-probe-*.sh` unchanged except for the temp prefix. Host: 16 cores, load 0.03-0.75, 11 registered worktrees (the fixture for `--check` has 1), bash 5.2.15. "Main's lib" is `git show main:scripts/lib/dev-cycle-read.sh`.

| Log | Started | Exit |
|---|---|---|
| `fcsub-logs/sec.log` (`fcsub-sec.sh`) | 2026-10-10T10:25:05-07:00 | 0 |
| `fcsub-logs/perf-fork.log` (`fcsub-perf-fork.sh`) | 2026-10-10T10:25:46-07:00 | 0 |
| `fcsub-logs/perf-real.log` (`fcsub-perf-real.sh`) | 2026-10-10T10:26:05-07:00 | 0 |
| `fcsub-logs/perf-tree.log` (`fcsub-perf-tree.sh`) | 2026-10-10T10:27:36-07:00 | 0 |
| `fcsub-logs/perf-fail.log` (`fcsub-perf-fail.sh`) | 2026-10-10T10:27:53-07:00 | 0 |
| `fcsub-logs/perf-check.log` (`fcsub-perf-check.sh`) | 2026-10-10T10:28:11-07:00 | 0 |
| `fcsub-logs/bats.log` (`fcsub-bats.sh`: `TMPDIR="$T" bats -f '…F3, row 602|prompt_marks marks a live prompt|key on the config dirs' test/scripts/build-loop-check.bats`, cwd the worktree) | 2026-10-10T10:28:41-07:00 | 0 (3 of 3 ok) |

An earlier run of `fcsub-sec.sh` exited 1 partway through. My probe leaked its lib-selection variable, so the S3 section ran main's lib, which runs need_root above the cache check. I fixed the probe, re-ran it, and removed the leftover dir. The log above is from the re-run.

---

## Submitted Claims

## Claim 50: "prompt_marks marks a live entry only when its real path lies below a reader root, compared as a literal whole-component prefix"

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:1392-1396`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers prompt_marks' live (non-`//`) branch over IMPORT_ROOTS as import_readers builds it: the root test is a quoted literal prefix followed by `/`, an entry whose real path equals its own path returns unmarked, and roots spelled with `*`, `?` or `[x]` match only themselves. Does not establish the `//` (dangling) branch, which marks without a root test by design. Does not establish behaviour with an empty or `/` line in IMPORT_ROOTS, which import_readers refuses (`:1178`) and which I did not inject, or what the walks do with the marks afterwards (Claim 51).

The test is:

```bash
# scripts/lib/dev-cycle-read.sh:1392-1396
  if [[ "$l" == //* ]]; then l="${l#/}"; lp="${lp#/}"
  else
    b="$(realpath -e -- "$l")" || return 1; [[ "$b" != "$l" ]] || return 0
    while IFS= read -r p; do [[ "$b" != "$p"/* ]] || in=1; done <<<"$IMPORT_ROOTS"; [[ -n "$in" ]] || return 0
  fi
```
(excerpt ends :1396; prompt_marks continues to :1405, read: below the test it only builds the bases and appends to the caller's arrays)

`"$p"` is quoted, so it matches literally, and the `/` that follows it forces a whole-component prefix.

Executed (`sec.log` section S1). With roots `$T/a/b`, `$T/g/r*`, `$T/q/r?` and `$T/br/[x]`:
- `l1 → $T/a/bc/k.md`: none.
- `l2 → $T/a/b/docs/k.md`: `docs/a.md`.
- `l3 → $T/g/rX/k.md`: none.
- `l4 → $T/q/rZ/k.md`: none.
- `l5 → $T/br/x/k.md`: none.
- an entry whose real path is its own path: none (early return).

The suite's test "prompt_marks marks a live prompt link's names only when its real path lies below a reader root" passed (`bats.log`, ok 2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1390-1405`, `scripts/lib/dev-cycle-read.sh:1170-1180`, `fcsub-logs/sec.log`, `fcsub-logs/bats.log`

---

## Claim 51: "F3 is closed for a link chain in another worktree and for a config-dir link into ROOT_REAL, in both walks"

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:1390-1405` (call sites `:1663`, `:1800`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these shapes, each in both the main and tree walks: a 2-hop and a 3-hop relative symlink chain in another registered worktree whose target there holds older bytes, and a config-dir command link (under `$HOME/.claude` and under `CLAUDE_CONFIG_DIR`) into ROOT_REAL's file. Does not establish a link under a symlinked directory in another root (known issue A5, settled), a root reached through a bind-mount alias, or chains that leave every reader root. It also does not show that the config-dir shape was ever open: main's lib already reports it imported, so for that shape the result confirms no regression, not a fix.

Both walks call prompt_marks on each outside entry with a prompt dir:

```bash
# scripts/lib/dev-cycle-read.sh:1663
    rq=(); outside_proj out work && { [[ "$f" != /* || -z "${pdir[$f]+set}" ]] || prompt_marks pdir pext out "$f" rq; } || { IMPORTED=error; return 1; }
```
```bash
# scripts/lib/dev-cycle-read.sh:1800
    rq=(); outside_proj out work && { [[ "$f" != /* || -z "${pdir[$f]+set}" ]] || prompt_marks pdir pext out "$f" rq; } || { IMPORTED_MAIN=error; return 1; }
```
After each call, the names in `rq` are queued again (`:1665`, `:1804-1809`).

Executed (`sec.log` section S2):

| Shape | This branch, main / tree | Main's lib, main / tree |
|---|---|---|
| Chain `side3/.claude/commands/k.md → ../../docs/l.md → t.md` | imported / imported | - / - (F3 open) |
| 3-hop chain via `docs/m.md → l.md → t.md` | imported / imported | not run |
| `$HOME/.claude/commands/k.md` → ROOT_REAL's `docs/t.md` | imported / imported | imported / imported |
| `CLAUDE_CONFIG_DIR/commands/k.md` → ROOT_REAL's `docs/t.md` | imported / imported | imported / imported |

The suite's F3 test (row 602) passed (`bats.log`, ok 1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1660-1666`, `scripts/lib/dev-cycle-read.sh:1798-1809`, `fcsub-logs/sec.log`, `fcsub-logs/bats.log`

---

## Claim 52: "readers_root never lets a walk read the checkout or list the registry from an unchecked cwd; a double cache hit answers for ROOT_REAL's own walk"

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:833`, `:1626-1631`, `:1702-1706`
**Type:** Invariant / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both walks entered from a wrong cwd after one good walk, under each of these: a double hit, a walk-cache miss, a change to the reader roots, reader homes, CLAUDE_CONFIG_DIR or managed dir, import_reset, a memoized refusal, and an unset ROOT_REAL. It also checks that a double hit runs no external command. Does not establish the parser's or import_home's reads of non-checkout paths (HOME's realpath, getent), which run before need_root on a memo miss and touch neither the checkout nor the registry. Does not cover a caller that sets ROOT_REAL to a directory other than the one it walked.

```bash
# scripts/lib/dev-cycle-read.sh:833
readers_root() { { [[ -n "${ROOT_REAL:-}" ]] && import_home && import_readers_key && [[ "$IMPORT_READERS_DONE" == "$IMPORT_READERS_KEY" && -n "$IMPORT_ROOTS" ]]; } || need_root; }
```
```bash
# scripts/lib/dev-cycle-read.sh:1626-1631
  readers_root
  import_readers || { IMPORTED_DONE=""; IMPORTED=error; return 1; }
  # The roots never hold an empty line, so the blank line ends them.
  [[ "$IMPORTED_DONE" == "$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"$'\n\n'"$IMPORT_CONFIGS" ]] && { [[ "$IMPORTED" != error ]]; return; }
  need_root  # below the cache check, as in main_imports
```
(excerpt ends :1631; imported_names continues to :1686, read)

The flow is:
- The registry listing (`git worktree list`, `:1170`) is reached only on a memo miss in import_readers, and a memo miss fails readers_root's test, so need_root runs first.
- The memo key leads with ROOT_REAL (`:1146`).
- Every checkout read in the walks follows the `need_root` below each walk's cache check (`:1631`, `:1706`).

Executed (`sec.log` section S3), main and tree walks alike:
- The double hit from `$T/other` returned `TRUTH_WHY=imported` for ROOT_REAL's `docs/a.md`.
- Each of these exited 1 with need_root's message: walk miss, reader-roots change, reader-homes change, config change, managed change, import_reset, refusal memo and unset root.
- With `PATH` set to a shim dir (git, realpath and find log and exit 99), a double hit printed no shim line and returned the cached answer.

**Evidence:** `scripts/lib/dev-cycle-read.sh:833`, `scripts/lib/dev-cycle-read.sh:1144-1206`, `scripts/lib/dev-cycle-read.sh:1623-1631`, `scripts/lib/dev-cycle-read.sh:1698-1706`, `scripts/lib/dev-cycle-read.sh:163-167`, `fcsub-logs/sec.log`

---

## Claim 53: "floor gives the same answer with and without $4 when $4 is lower($1)"

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:1925-1952`; `scripts/build-loop.sh:671`, `:843-844`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers floor's whole decision (early rules, gate code, docs/thoughts, docs/working, docs/reviews, the import rule and the ancestor rule) when `$4` equals lower($1), and build-loop.sh's call, whose `$4` is lower_all's output for a path pathform has already admitted. Does not establish agreement when `$4` differs from lower($1). Such a `$4` cannot come from build-loop.sh: lower_all keeps a trailing newline and `$(lower …)` drops it, but nrules' pathform denies every newline path before srules runs. It also does not cover a fork failure inside lower, which only the no-`$4` call can hit and which refuses.

```bash
# scripts/lib/dev-cycle-read.sh:1926-1928
  local lp="${4-}" d
  FLOOR_WHY=""
  [[ -n "$lp" ]] || lp="$(lower "$1")" || { FLOOR_WHY="the path could not be lower-cased"; return 0; }
```
(excerpt ends :1928; floor continues to :1952, read: nothing below reads `$1`, only `lp`, `$2` and `$3`)

The caller passes the lowered path as `$4`:

```bash
# scripts/build-loop.sh:671
  if [[ -z "$5" ]] && floor "$2" "$1" "$4" "$3"; then DENY="$FLOOR_WHY"; return 0; fi
```
`srules "$stem" "$p" "${lps[$i]}" "${ss[$i]}" "$co"` (`scripts/build-loop.sh:844`) runs only when nrules set no DENY, and nrules' first test is `if ! pathform "$6"; then DENY=…` (`scripts/build-loop.sh:609`).

Executed (`sec.log` section S4): 24 paths, each floored with lower_all's output and without `$4`, gave `S4 total=24 diff=0`. The paths covered every early rule, mixed case, `.md` ancestors, an imported name, the gate code and own files.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1925-1952`, `scripts/build-loop.sh:606-610`, `scripts/build-loop.sh:668-671`, `scripts/build-loop.sh:841-845`, `fcsub-logs/sec.log`

---

## Claim 54: "walk_has matches literally; a newline in the path can only over-match"

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:1844-1847`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers walk_has on both arms (main → IMPORTED_MAIN, anything else → IMPORTED) with glob, extglob, bracket and backslash metacharacters and with embedded, leading and trailing newlines. Does not establish that every caller lowers its LP first (Claim 53 covers floor), or what walk_has returns on a failed walk's list (contract item 6 forbids asking then).

```bash
# scripts/lib/dev-cycle-read.sh:1844-1847
walk_has() {
  if [[ "$1" == main ]]; then local -n wh_l=IMPORTED_MAIN; else local -n wh_l=IMPORTED; fi
  [[ "$wh_l" == *$'\n'"$2"$'\n'* ]]
}
```
The operand `"$2"` is quoted, so it is literal. The list is newline-delimited, so an LP holding a newline can match only by spanning two entries (over-match). It can never fail to match an entry it names, because no entry holds a newline.

Executed (`sec.log` section S5). The list was `\ndocs/a.md\nclaude.md\na*b\n`, with the same results on both arms:
- `docs/a.md`: has.
- `docs/a.md\nclaude.md`: has (over-match).
- `a*b`: has (the literal entry).
- No match: `*`, `docs/*`, `docs/a.m?`, `[d]ocs/a.md`, `@(docs/a.md)`, `a\*b`, `aXb`, `docs/a.md*`, `docs/a.md/`, `ocs/a.md`, the empty string, `claude.md\n` and `\ndocs/a.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1840-1847`, `fcsub-logs/sec.log`

---

## Claim 55: "Both walks walk again without import_reset after a HOME or IMPORT_MANAGED_DIR change"

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:1144-1147`, `:1198-1199`, `:1629`, `:1704`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers HOME changes that alter the effective homes (another dir, a trailing slash, the passwd home) and IMPORT_MANAGED_DIR changes, in both walks, counted by walks actually run. Does not establish a re-walk when HOME changes but resolves to the same homes: from HOME set to the passwd home, to HOME unset. That case is a cache hit, and correct, since IMPORT_HOMES and IMPORT_CONFIGS are unchanged. Also not covered: a change to a config dir's contents within one decision, which is in no key (contract item 4's import_reset per decision covers it).

The memo key holds HOME (through IMPORT_HOME_DONE) and IMPORT_MANAGED_DIR:

```bash
# scripts/lib/dev-cycle-read.sh:1144-1148
import_readers_key() {
  local a="${ROOT_REAL:-}" b="$IMPORT_HOME_DONE" c="$IMPORT_READER_ROOTS" d="$IMPORT_READER_HOMES" e="$IMPORT_READER_WHY"
  local f="${CLAUDE_CONFIG_DIR+x}${CLAUDE_CONFIG_DIR-}" g="$IMPORT_MANAGED_DIR"
  IMPORT_READERS_KEY="${#a}:$a ${#b}:$b ${#c}:$c ${#d}:$d ${#e}:$e ${#f}:$f ${#g}:$g"
}
```
IMPORT_CONFIGS is rebuilt from the homes and the managed dir:

```bash
# scripts/lib/dev-cycle-read.sh:1198-1199
  for p in "${rs_h[@]}"; do [[ "$p" != /* ]] || IMPORT_CONFIGS+="${p%/}/.claude"$'\n'; done
  IMPORT_CONFIGS+="${CLAUDE_CONFIG_DIR:+$CLAUDE_CONFIG_DIR$'\n'}$IMPORT_MANAGED_DIR"
```
Each walk's cache key ends with `$IMPORT_CONFIGS` (`:1629`, `:1704`).

Executed (`sec.log` section S6), with outside_seeds wrapped to count walks. Main and tree gave the same sequence:

| Step | Result | Walks run |
|---|---|---|
| Start | `h1 e: -` | 1 |
| HOME set to h2 | `h2 e: imported` | 2 |
| Before the managed-dir change | `m: -` | 2 |
| IMPORT_MANAGED_DIR changed | `m: imported` | 3 |
| HOME given a trailing slash | walked again | 4 |
| HOME set to the passwd home | walked again | 5 |
| HOME unset (same effective home) | cache hit, answer unchanged | 5 |

**Evidence:** `scripts/lib/dev-cycle-read.sh:1087-1093`, `scripts/lib/dev-cycle-read.sh:1144-1206`, `scripts/lib/dev-cycle-read.sh:1629`, `scripts/lib/dev-cycle-read.sh:1704`, `fcsub-logs/sec.log`

---

## Claim 56: "No gate caller relies on floor's need_root exit for an early-rule refusal"

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:326-329`, `:860-870`; `scripts/dev-cycle.sh:126`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every current floor call site in `scripts/` (one: build-loop.sh srules) and the setup that precedes it: cd to the toplevel and ROOT_REAL set before any mode runs, with no later `cd` in that shell. It also covers the fact that early-rule refusals return a refusal, not a pass, from a wrong cwd or an unset ROOT_REAL. Does not establish a future floor caller (U3's `--merge`). dev-cycle.sh does not call floor; its `:126` only sets ROOT_REAL for truthrule and truthwalk.

The executed grep for floor calls in `scripts/` (`sec.log` section S7) found exactly one:

```bash
# scripts/build-loop.sh:671
  if [[ -z "$5" ]] && floor "$2" "$1" "$4" "$3"; then DENY="$FLOOR_WHY"; return 0; fi
```
Setup runs before any mode:

```bash
# scripts/build-loop.sh:326-329
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not inside a git repository" >&2; exit 1; }
cd "$ROOT"
# shellcheck disable=SC2034  # read by the lib's file rules
ROOT_REAL="$(pwd -P)"
```
The only other `cd` lines in build-loop.sh are inside subshells: `:218`, inside `$(...)`, and `:563`, inside `( … )` (paraphrased — no quote available because the claim covers the absence of other `cd` calls, established by `grep -n 'cd '`).

Executed: from a wrong cwd, floor refused with its early-rule reason and did not exit, for six paths: `CLAUDE.md`, `.x/y`, `docs/thoughts/a`, `scripts/lib/a`, `docs/working/x` and `docs/reviews/x`. With ROOT_REAL unset, `CLAUDE.md` also refused with "an instruction or prompt file…" (`sec.log` section S7).

**Evidence:** `scripts/build-loop.sh:326-329`, `scripts/build-loop.sh:671`, `scripts/build-loop.sh:860-870`, `scripts/dev-cycle.sh:122-126`, `fcsub-logs/sec.log`

---

## Claim 57: "The per-path goal holds on the final code: --check over a 400-path fixture ~4x faster than main's lib, a cached floor call 11-14x faster over this repository"

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:1925-1952` (floor); `scripts/build-loop.sh:671`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--check` end to end on the 1-worktree fixture (3 interleaved pairs) and cached floor with `$4` over this repository with 11 worktrees (2 runs per lib). Does not establish `--check` timed end to end against this repository, or any timing under load.

The ~4x part reproduces. `--check` took 0.68 / 0.68 / 0.68 s on this branch against 2.77 / 2.70 / 2.83 s on main's code, which is 3.97x to 4.16x (`perf-check.log`).

The "11-14x" for cached floor does not reproduce:
- This branch: 1.019 and 1.007 ms/path.
- Main's lib: 10.790 and 10.704 ms/path in the "$4 passed" column, 8.465 and 8.540 in the "no $4" column (`perf-real.log`).

Main's floor ignores a fourth argument (`git show main:…` `:1828-1832`: `lp="$(lower "$1")"` with `need_root` above it), so its two columns are the same workload. The fair ratio is therefore 8.3x to 10.7x. The critic's 11-14x divides by main's higher column only. Its own same-workload main column (8.634 / 11.736 ms) gives 8.4x to 11.5x.

The precise version is "about 8-11x". The mechanism is right: main forks need_root's `pwd -P` and lower per path, and this branch forks neither (Claim 59). The conclusion holds too: the per-path goal is met by a wide margin.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1925-1928`, `scripts/build-loop.sh:671`, `fcsub-logs/perf-real.log`, `fcsub-logs/perf-check.log`

---

## Claim 58: "After the B1 fix, prompt_marks marks 0 of 9 live entries per walk over this repository, and the main walk's time matches main's lib"

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:1392-1396`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this repository's state at 2026-10-10 10:26 (11 worktrees, `CLAUDE_CONFIG_DIR=/home/node/.claude`), both walks' prompt_marks census and 3 interleaved main-walk timing pairs. Does not establish other hosts or registries, where links into a root would be marked by design, or the tree walk's time against main's.

prompt_marks' live branch returns before marking unless the real path differs and lies below a root (quoted in Claim 50).

Executed census, the same for each walk (`perf-real.log`): `live=9 (realpath same=3, differs-out-of-roots=6, differs-in-root=0) requeued=0`. Both walks gave `listbytes=80855`.

Main-walk times: this branch 3.04 / 2.93 / 3.03 s, main's lib 2.98 / 4.22 / 2.95 s. The 4.22 is a single outlier, and the other pairs agree within 0.1 s. Both libs list 1,811 lines.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1390-1405`, `fcsub-logs/perf-real.log`

---

## Claim 59: "readers_root and a cached floor call with $4 fork nothing (xtrace)"

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:833`, `:1925-1952`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers readers_root on a memo hit and floor with `$4` on a path that reaches the cached main walk and the ancestor loop, both at depth-0 shell work with no external command. Does not establish floor without `$4`, which forks lower's `$(printf | tr)` (3 subshell lines and a `tr` call in my run). It also does not cover floor after a failed walk, which forks walk_why's `$(...)` and, on a readers refusal, need_root's `pwd -P`.

readers_root (quoted in Claim 52) is `[[ ]]` tests plus import_home's key compare and import_readers_key's string building. floor with `$4` skips the `lower` call (`:1928`, quoted in Claim 53).

Executed with two independent detectors (`perf-fork.log`): xtrace with `PS4` showing `$BASH_SUBSHELL`, and `PATH` set to a dir of shims that log any external call.

| Call | xtrace lines | Subshell lines | Shim calls |
|---|---|---|---|
| readers_root | 42 | 0 | 0 |
| cached floor with `$4` | 3872 | 0 | 0 |

The critic's own xtrace re-run (`perf-fail.log`, `perf-real.log`) agrees: 0 subshell lines and 0 `++` lines for both.

**Evidence:** `scripts/lib/dev-cycle-read.sh:833`, `scripts/lib/dev-cycle-read.sh:1087-1090`, `scripts/lib/dev-cycle-read.sh:1144-1148`, `scripts/lib/dev-cycle-read.sh:1925-1952`, `fcsub-logs/perf-fork.log`, `fcsub-logs/perf-real.log`, `fcsub-logs/perf-fail.log`

---

## Claim 60: "The tree walk's cached call is fork-free since need_root moved below its cache check (imported_names ~0.41 ms vs ~1.0 ms on main)"

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:1623-1631`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a cached imported_names call (and a cached `truthwalk tree` with a lowered path) over this repository, 11 worktrees, two runs each. Does not establish the uncached walk's cost, or isimported's tree path, which still runs need_root and lower per call (`:1836-1838`).

Main's order puts need_root first. This is paraphrased from `git show main:scripts/lib/dev-cycle-read.sh:1556-1559`, because that file is not in the worktree: there, `need_root` runs before `import_readers` and the cache test. This branch runs readers_root, which forks nothing on a memo hit, and puts need_root below the cache test (`:1626-1631`, quoted in Claim 52).

Executed:
- Fork check (`perf-fork.log`): a cached imported_names showed 0 subshell lines and 0 shim calls on this branch, against 1 subshell line on main's lib (need_root's `$(pwd -P)`). A cached `truthwalk tree` showed 0 subshell lines and 0 shim calls on this branch, against 5 and a `tr` call on main's lib.
- Timing (`perf-tree.log`): cached imported_names took 0.4076 / 0.4085 ms on this branch against 0.9423 / 0.9512 ms on main (2.3x). Cached `truthwalk tree` took 0.83 / 0.80 ms against 4.49 / 4.37 ms.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1623-1631`, `scripts/lib/dev-cycle-read.sh:1881-1887`, `fcsub-logs/perf-fork.log`, `fcsub-logs/perf-tree.log`

---

## Claim 61: "The new failure reasons cost less per path than main's lib on every failure measured (budget, readers refusal)"

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:1943` (floor), `:808-826` (walk_why), `:833` (readers_root)
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two failures the critic measured: `IMPORT_OUT_MAX=1000` and an `IMPORT_READER_WHY` refusal, cached floor with `$4` over 400 paths, 11 worktrees, two runs. Does not establish other failure kinds (link, start, seeds, copies). Note that the `IMPORT_OUT_MAX=1000` failure records WHY as `read skills/code-fact-check/SKILL.md` (the per-file budget trips in import_file) rather than `budget`, so it times the `read` sentence.

```bash
# scripts/lib/dev-cycle-read.sh:1943
    if [[ "$TRUTH_WHY" == walk ]]; then FLOOR_WHY="the default branch's instruction files could not be walked for @ imports: $(walk_why "$IMPORTED_MAIN_WHY")"
```

Executed (`perf-fail.log`):

| Failure | This branch (ms/path) | Main's lib (ms/path) |
|---|---|---|
| Budget run | 1.565 / 1.502 | 4.115 / 4.154 |
| Readers refusal | 1.992 / 2.000 | 3.271 / 3.121 |

walk_why's `$(...)` costs 0.50-0.52 ms per call.

**Evidence:** `scripts/lib/dev-cycle-read.sh:808-826`, `scripts/lib/dev-cycle-read.sh:833`, `scripts/lib/dev-cycle-read.sh:1941-1944`, `fcsub-logs/perf-fail.log`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 57** (`scripts/lib/dev-cycle-read.sh:1925-1952`): the cached-floor speedup re-measures at 8.3-10.7x, not 11-14x. Main's floor ignores `$4`, so the critic's "$4 passed" main column is the same workload as its no-`$4` column (8.6-11.7 ms). State "about 8-11x". The ~4x `--check` figure reproduces (3.97-4.16x).

### Unverifiable
(none)
