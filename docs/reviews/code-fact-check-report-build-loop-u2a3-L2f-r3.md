Commit: 1898d21c
# Code Fact-Check Report

**Repository:** claude-workflows, worktree `/workspace/.claude/wt-build-loop-u2a3`, branch `feat/build-loop-u2a3`
**Scope:** `git diff main...HEAD` at 1898d21c (base main 62d366a7): `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`, `docs/working/known-issues-dev-cycle.md` (A5), `docs/working/plan-build-loop-handoff.md` (F11, U2a3/U2a3c/U2b bullets), the rubric's split and Loop 2 sections, the override rows added since 0170f16a, and the commits 2b22a082..1898d21c. Role cfc2f, pass i2 (loop 2 final confirming pass, replicate r3).
**Checked:** 2026-10-07 (UTC; 2026-10-06 local)
**Total claims checked:** 38
**Summary:** 29 verified, 5 mostly accurate, 0 stale, 3 incorrect, 1 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, five entries, all measured-figure or file-to-symbol fabrications). No claim here matches a logged pattern. No Incorrect verdict below is a fabricated symbol, so the log needs no new entry. This pass writes only this report.

## Execution provenance

Scratch dir `S=/tmp/u2a3-cfc2f-i2-aiLl`. Every log is under `$S/logs/`. Git 2.39.5, bash 5, LC_ALL=C in probes. The probe harness `$S/h.sh` copies the suite's `imps` helper verbatim (prints `walk: ok|failed`, then `PATH: imported|-`). Probe repos sit under `$S/r-*`. The lib under probe is `$S/copy/scripts/lib/dev-cycle-read.sh`, from `git archive HEAD`. `$S/lib-2b.sh` and `$S/lib-cc1.sh` come from `git show 2b22a082:` and `git show cc1aa864:`. No background processes were started.

| Run | Command | cwd | Exit | Time (UTC) | Output |
|---|---|---|---|---|---|
| X1 | `TMPDIR=$(mktemp -d $S/t-XXXX) timeout 900 bats test/scripts/dev-cycle.bats test/scripts/build-loop-read.bats test/scripts/build-loop-check.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats` (+ `bats --count` per file: 75, 19, 16, 2, 2) | worktree | 0 | 03:31:14Z | `$S/logs/suites.out` (1..114, 114 ok) |
| X2 | same five suites | `$S/full-2b` (`git archive 2b22a082`) | 0 | 03:37:37Z | `$S/logs/suites-2b.out` (1..114, 114 ok, build-loop-check 16) |
| X3 | `$S/runmut.sh BASE NAME OLD NEW` (an exact single replacement in a copy's lib with `python3 -I $S/mut.py`, then `bats test/scripts/build-loop-check.bats` in that copy) | `$S/mut-NAME` | per row | 03:36:00Z-03:37:07Z; splitnone 03:38:18Z; fileok ~03:44Z | `$S/logs/mutants.summary`, `$S/logs/mut-NAME.out` |
| X4 | `bash $S/probes1.sh` (root import, odd modes, index-only start, gitlink start, doubled blob+tree name in both orders) | `$S` | 0 | 03:41:36Z | `$S/logs/probes1.out` |
| X5 | `bash $S/probes2.sh` (@.git in a linked worktree, index-only start at 2b22a082 vs HEAD, nul_list edges, nested repo, symlinked dir) | `$S` | 0 | 03:40:29Z | `$S/logs/probes2.out` |
| X6 | `bash $S/probes3.sh` (a checkout link in link text) | `$S` | 0 | 03:40:44Z | `$S/logs/probes3.out` |
| X7 | `timeout 200 bash $S/probes4.sh` (deep-token timing) | `$S` | 0 | 03:41:10Z | `$S/logs/probes4.out` |
| X8 | `bash $S/probes5.sh` (an ignored start file) | `$S` | 0 | 03:43:02Z | `$S/logs/probes5.out` |
| X9 | `git diff --numstat main...REV -- . ':!docs'` summed for 2b22a082, dfeeb85d, HEAD | worktree | 0 | 03:43:35Z | `$S/logs/numstat.out` |
| X10 | here-string vs process-substitution loop, 2000 iterations x3 | `$S` | 0 | 03:42:34Z | `$S/logs/procsub.out` |

Mutant table (X3; "killed" = the suite exits 1):

| Mutant | Base | Edit | Result |
|---|---|---|---|
| 2b-untstart / h-untstart | 2b / HEAD | start refusal `\|\| return 1` → `\|\| continue` | killed by 3, 9, 11 |
| 2b-probe / h-probe | 2b / HEAD | checkout probe line → `true` | killed by 3, 9, 12 |
| 2b-gitlink / h-gitlink | 2b / HEAD | `^1[26]0000$` → `^120000$` | killed by 12 |
| 2b-parentimm / h-parentimm | 2b / HEAD | parent `while` → `if` (immediate parent only) | killed by 15 |
| 2b-plaindir / h-plaindir | 2b / HEAD | drop the plain-directory clause | killed by 9 |
| 2b-linksplit | 2b | `mapfile -t -d / parts < <(...)` → `IFS=/ read -ra parts <<<"$out"` | **survives** (all 16 pass) |
| 2b-splitnone | 2b | split → `parts=()` | killed by 15 |
| h-linksplit | HEAD | here-string revert | killed by 10 |
| h-index | HEAD | drop the `--cached` listing (`recs=()`) | killed by 3 |
| h-newline | HEAD | drop the checkout-name newline check | killed by 7 |
| h-starrm | HEAD | `*) IMPORTED_MAIN=error; return 1` → `*) continue` | **survives** |
| h-gitlinkcont | HEAD | `160000) continue` → fail | **survives** |
| h-fileok | HEAD | also allow a plain checkout file at a path main lacks | killed by 3 only |

---

## Claim 1: Rubric, split dispositions: "C2 ... A 160000 parent fails the walk like a 120000 one"; "C4 ... fixed (`mapfile -d /` from a process substitution)"; "C8 ... steps over `/` with `${c%/*}`"; "C10 (nul_list partial array): fixed (emptied on failure)"; "C1 ... An untracked start fails the walk until U2a3c"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md:9-17`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five code-facing dispositions at HEAD. It does not establish U2a3c's future behaviour or the C3, C9 and C12 override rows' rationale.

- C2: `[[ ! "${ent[$c]:-}" =~ ^1[26]0000$ ]] || { IMPORTED_MAIN=error; return 1; }` (`scripts/lib/dev-cycle-read.sh:607`). The h-gitlink mutant is killed by test 12.
- C4: `mapfile -t -d / parts < <(printf '%s' "$out")` (`:589`). No `<<<` remains in `:546-611`.
- C8: `c="$p"; while [[ "$c" == */* ]]; do c="${c%/*}"; ...` (`:607`).
- C10: `|| { nl_a=(); return 1; }` (`:517`). In X5, `false` and a listing with no final NUL each leave `n=0`.
- C1: `[[ "${cand[i]:0:1}" == m ]] || return 1` (`:570`). The h-untstart mutant is killed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:517`, `:570`, `:589`, `:607`; `$S/logs/mutants.summary`; `$S/logs/probes2.out`

---

## Claim 2: Rubric E1: "The walk also lists the checkout's tracked .md files; one main lacks is a start main lacks and fails the walk. Test: test 3 stages CLAUDE.local.md; mutant killed."

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md:33`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the index listing, its use as a start-candidate source, the test-3 assertion and the mutant. It does not establish behaviour under GIT_INDEX_FILE or a sparse index (row 387, deferred to U2b).

The code is `nul_list recs env GIT_LITERAL_PATHSPECS=0 git ls-files -z --cached -- ':(glob,icase)**/*.md' || return 1` (`:562`), then `[[ -n "${ent[$f]+set}" ]] || cand+=("t:$f")` (`:563`). Test 3 runs `git add -f CLAUDE.local.md; imps main docs/guide.md; want walk failed` (`test/scripts/build-loop-check.bats:61`). h-index is killed by test 3 only.

X5 shows the index-only start passing at 2b22a082 and failing at HEAD: `2b22a082: walk: ok docs/private.md: -`, then `HEAD: walk: failed docs/private.md: imported`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:561-571`; `test/scripts/build-loop-check.bats:61`; `$S/logs/mut-h-index.out`; `$S/logs/probes2.out`

---

## Claim 3a: Rubric E4/E5: "`160000) continue`, any other type fails the walk"; "test-strategy's patch (fixture `zz<LF>CLAUDE.md`; a 67 KB link under `ulimit -f 0` with XFSZ ignored), isolated from the new index check; both mutants killed"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md:36-37`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the case arms, the fixture shapes, the 67 KB size and the two mutant kills. It does not establish that any test reaches the `*)` arm or the `160000) continue` arm (both mutants survive; Claim 19).

The arms are `160000) continue ;;  # a gitlink: its files are not main's` and `*) IMPORTED_MAIN=error; return 1 ;;` (`:597-598`).

The link text is `x="$(for i in $(seq 270); do printf '%0250d/../' 0; done)l/../t.md"` (`test/scripts/build-loop-check.bats:223`). It is 270 x 254 + 9 = 68,589 bytes, about 67.0 KiB. It runs after `git read-tree main`, so the index matches main and no `t:` candidate fires. h-linksplit is killed by test 10 and h-newline by test 7.

**Evidence:** `scripts/lib/dev-cycle-read.sh:597-598`; `test/scripts/build-loop-check.bats:148-152`, `:222-226`; `$S/logs/mutants.summary`

---

## Claim 3b: Rubric E2: "Ignored instruction files fail the walk (35 in /workspace's own checkout)"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md:34`
**Type:** Behavioral / Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the mechanism: an ignored start file fails the walk. It does not establish the figure 35, which needs a listing of /workspace's own checkout, outside this pass's permitted tree.

X8 created an ignored `home/.claude/CLAUDE.md`, with `home/` in `.gitignore`. Result: `ignored start: walk: failed docs/a.md: imported x.sh: imported`. `.gitignore:52` holds `devcontainer-config/claude-home/`. Run inside this worktree, the walk answers `walk ok` with 0 untracked or ignored start-shaped files (`$S/logs/worktree-walk.out`). The count 35 for /workspace was not run, because the shared context restricts work to the worktree.

**Evidence:** `.gitignore:52`; `scripts/lib/dev-cycle-read.sh:515`; `$S/logs/probes5.out`; `$S/logs/worktree-walk.out`

---

## Claim 4: Override row (E7): "The parent-link loop ... is O(L x depth): a deep 64 KB `a/a/.../x.md` token takes 9-16 s (one long segment is now 0.27-1 s) ... Slow, never fail-open; only text committed to main reaches it after the split."

**Location:** `docs/reviews/override-log.md:386`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the complexity, both timings on this host, and that only tokens from main's blobs or link text reach `:607`. It does not establish timings on other hosts.

The loop `c="${c%/*}"` copies up to L bytes per step, once per `/` (`:607`). `p` comes only from `out`, which is main's blob through `import_targets` (`:579`) or main's link text (`:584-596`).

X7 results: a 65,530-byte CLAUDE.md holding `@a/a/.../x.md` took 11.66 s (walk ok). One 65,000-byte segment took 0.29 s.

**Evidence:** `scripts/lib/dev-cycle-read.sh:579-609`; `$S/logs/probes4.out`

---

## Claim 5: Override row (E8): "the lib does not set GIT_NO_REPLACE_OBJECTS; build-loop.sh exports it"

**Location:** `docs/reviews/override-log.md:387`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both greps. It does not establish whether replace refs or grafts can mislead the walk (untested; deferred to U2b).

`grep GIT_NO_REPLACE_OBJECTS scripts/lib/dev-cycle-read.sh` finds nothing (paraphrased — no quote available because the claim covers absence of code). `scripts/build-loop.sh:118` has `export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1`.

**Evidence:** `scripts/build-loop.sh:118`

---

## Claim 6: Override row (E10): "a start file only in the checkout's index then passed [at 2b22a082]; fixed in the loop 2 iteration 1 fix commit"

**Location:** `docs/reviews/override-log.md:388`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the before/after behaviour for an index-only CLAUDE.local.md. It does not re-verdict 2b22a082's D13 sentence (Accepted-immutable).

X5: `2b22a082: walk: ok docs/private.md: -`, then `HEAD: walk: failed docs/private.md: imported`.

**Evidence:** `$S/logs/probes2.out`; `scripts/lib/dev-cycle-read.sh:562-563`

---

## Claim 7: Override row (E9): "In a clean linked worktree `.git` is a file, so an instruction file importing `@.git` now fails the walk (pre-split it answered ok); ... one process substitution measured ~0.27 ms"

**Location:** `docs/reviews/override-log.md:389`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers HEAD vs cc1aa864 on `@.git` in a fresh linked worktree, and the cost of one process substitution on this host. It does not establish costs on other hosts.

X5 first lists `-rw-r--r-- ... .git`, then `HEAD: walk: failed x.sh: imported` and `cc1aa864: walk: ok x.sh: -`. The cause at HEAD: `.git` is a path main lacks that is neither a plain directory nor absent (`:608`). X10 measured about 0.32 ms per `mapfile < <(printf ...)` against about 0.007 ms for the here-string, the same order as ~0.27 ms.

**Evidence:** `scripts/lib/dev-cycle-read.sh:608`; `$S/logs/probes2.out`; `$S/logs/procsub.out`

---

## Claim 8a: A5: "symlinked start files and targets on main are followed, `.claude/rules/` at any depth starts, and ... link text that is empty, absolute, leaves the repo, holds a newline or NUL or has a `..` after a symlink, an imported path main lacks under a directory main stores as a symlink or gitlink fail it"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named shape against tests and mutants. It does not establish the "odd names" (doubled-name) atom for a name doubled as a blob and a tree (Claim 13b).

- Symlinks: test 6 follows `CLAUDE.md -> real.md` and a two-link chain to `docs/c3.md`.
- Rules at any depth: test 6 reaches `pkg/.claude/rules/docs/bom.md`.
- Link text: test 7 covers trailing newline, absolute, empty and `../outside`. Test 9 covers NUL. Test 15 covers `..` after a symlink (h-parentimm is killed by 15).
- Gitlink parent: test 12 (h-gitlink is killed).

All five suites pass (X1).

**Evidence:** `test/scripts/build-loop-check.bats:115-137`, `:139-161`, `:175-201`, `:240-258`, `:281-304`; `$S/logs/suites.out`; `$S/logs/mutants.summary`

---

## Claim 8b: A5: "a start file main lacks (untracked, ignored, or only in the checkout's index) ... or anything but a plain directory at an imported path main lacks fails the walk ..., and a path main lacks that the checkout does not hold is recorded but not walked. A developer checkout with ignored instruction files (here, `devcontainer-config/claude-home/`) therefore always fails it"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers untracked, ignored and index-only starts (one deleted from the work tree included), plain-directory and absent targets, and the claude-home ignore rule. It does not establish starts that the listings never enter (nested repos, symlinked directories, unsearchable directories), which A5 lists as not covered or which override rows defer.

The refusal is `[[ "${cand[i]:0:1}" == m ]] || return 1` (`:570`). Probe results:

- Untracked: test 3 and test 11.
- Ignored: X8, `walk: failed`.
- Index-only: test 3. X4 P4 also fails when the index entry's file is deleted from the work tree (`AD d/AGENTS.md` ... `walk: failed`).
- Plain directory: X4 P5 shows `docs/a.md` and `sub` as plain directories, walk ok, both recorded `imported`.
- Absent: test 3, where `docs/new.md` absent answers `imported` and walk ok.

**Evidence:** `scripts/lib/dev-cycle-read.sh:561-573`, `:608`; `.gitignore:52`; `$S/logs/probes1.out`; `$S/logs/probes5.out`

---

## Claim 8c: A5: "Until U2a3c the walk ... fails closed on the checkout: ... a link in link text ... fails the walk"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a checkout symlink at a component of link text that main stores, on two shapes: with and without a later `..`. It does not establish what Claude Code loads beyond a kernel read of the path.

The code does not fail on a checkout link in link text as such. It sets a flag, `[[ "${ent[$p]:-}" != 120000 && ! -L "$p" ]] || lk=1` (`:593`), and fails only when a `..` follows, via `[[ "$c" != .. || -z "$lk" ]] || { IMPORTED_MAIN=error; return 1; }` (`:591`). A target main lacks under a checkout link also fails, through `blocker` (`:608`).

In X6, main stores `CLAUDE.md -> x/y.md` with `x/` a directory. The checkout replaces `x` with `x -> other`. The walk answers `walk: ok docs/a.md: imported docs/evil.md: -`, while the kernel reads CLAUDE.md as `other @../docs/evil.md`. With link text `x/../t.md` the same checkout link fails the walk (`walk: failed`).

The precise version: "a `..` after a checkout link in link text, or a checkout link at or above an imported path main lacks, fails the walk". A checkout link elsewhere in link text whose target main stores is read from main. That falls under "a working-tree edit does not count" and the fresh-worktree requirement. The lib comment (`:458-459`, "has a .. after a symlink (on main or in the checkout)") is accurate. Only A5's added phrase is too broad (added in dfeeb85d).

**Evidence:** `scripts/lib/dev-cycle-read.sh:589-596`, `:605-608`; `$S/logs/probes3.out`

---

## Claim 8d: A5 "Not covered: start files under a symlinked directory or in a submodule or untracked nested repo (neither `ls-tree -r` nor `ls-files --others` enters one), other names one file has on a case-insensitive checkout, and absolute imports into the repo"; the three untraced shapes' walk-side halves ("the walk uses the target's", "the walk is lexical")

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk's side of each gap. It does not establish what Claude Code does for any of them (A5 marks them untraced, and no host probe was run).

- Untracked nested repo holding `CLAUDE.md`: X5 gives `walk: ok docs/n.md: -`.
- Untracked symlink to a directory holding `CLAUDE.md`: X5 gives `walk: ok lnkdir/x.md: -`.
- A gitlink at a start name: X4 P6 gives walk ok.
- Absolute imports are dropped: `[[ -n "$t" && "$t" != "~"* && "$t" != /* ]] || continue` (`:500`).
- Link imports resolve from the target's directory: queued `out` is the target, and `d="${f%/*}"` is the target's directory (`:577`, `:595`).
- `@` tokens use `realpath -ms` (`:501`), which is lexical.

**Evidence:** `scripts/lib/dev-cycle-read.sh:500-502`, `:577`, `:595`; `$S/logs/probes2.out`; `$S/logs/probes1.out`

---

## Claim 9: F11: "Floor item 1 walks main's commit (`main_imports`, U2a3: NUL-safe listings, symlinks on main followed, `.claude/rules/` at any depth as starts; a doubled name, a name holding a newline, link text ... or an imported path main lacks under a directory main stores as a symlink or gitlink fails the walk, so floor refuses every path). Until U2a3c it fails closed on the checkout: a start file main lacks (untracked, ignored, or only in the checkout's index), or anything but a plain directory at an imported path main lacks, fails the walk, so the gate needs a fresh worktree (U2b) ..."

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed shape (same evidence as Claims 8a, 8b), the `-z` listings and the gap list. It does not establish the "doubled name" atom for a blob/tree doubled name (Claim 13b), or the future U2a3c, U2a4 and U2b behaviour.

The listings are `git ls-tree -r -z` (`:553`), `ls-files -z --others` (`:515`) and `ls-files -z --cached` (`:562`), each split on NUL by `nul_list`. The gap list matches A5 and the lib's not-covered list (`:466-469`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:515`, `:553-573`; `$S/logs/suites.out`

---

## Claim 10: Plan bullets: U2a3 "started from main's instruction files and `.claude/rules/`. It refuses ... and fails closed on the checkout (a start file main lacks, or anything but a plain directory at an imported path main lacks)"; U2a3c "(U2a3 L2 architecture F1, F5)"; U2b "a fresh worktree at MAIN_SHA, since until U2a3c the walk fails on any start file main lacks, ignored ones included, and on checkout content at paths main lacks"

**Location:** `docs/working/plan-build-loop-handoff.md:276-279`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the U2a3 and U2b bullets' code claims and U2a3c's references. It does not establish U2a3c's or U2b's future designs, and excludes the blob/tree doubled-name atom (Claim 13b).

- U2a3 bullet: same evidence as Claims 8a, 8b.
- U2a3c: `architecture-review-review-2026-10-06-L2-build-loop-u2a3.md` has "#### 1. The checks that admit checkout input sit at two separate inline sites ..." and "#### 5. What phase 2 would share: the main index, `seen` and the drain loop itself".
- U2b: X8 shows that an ignored start fails.

**Evidence:** `docs/reviews/architecture-review-review-2026-10-06-L2-build-loop-u2a3.md:32`, `:122`; `$S/logs/probes5.out`

---

## Claim 11: Header Inputs paragraph: "and so does main_imports (it reads the checkout only to fail, until U2a3c, so the gate needs a fresh worktree; the block above IMPORTED= lists each case; it needs resolve_main to have found main by name)"

**Location:** `scripts/lib/dev-cycle-read.sh:29-35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every checkout read in main_imports: two listings, `-L` in the link-text loop, and `-d`/`-e`/`-L`/`blocker` at `:608`. Each can only add a failure, and none reads checkout content. It does not establish that the listings see every checkout file (nested repos, symlinked or unsearchable directories: A5 and override rows).

The checkout reads are:

- `untracked_md` and the `--cached` listing (`:561-563`). They feed only `t:` candidates, which `:570` turns into `return 1`.
- `! -L "$p"` (`:593`). It only sets `lk`, which can only fail at `:591`.
- `[[ -d "$p" && ! -L "$p" && -z "$(blocker "$p" dir)" ]] || [[ ! -e "$p" && ! -L "$p" ]] || { IMPORTED_MAIN=error; return 1; }` (`:608`).

Blob reads come from `git cat-file blob "$MAIN_SHA:$f"` (`:579`, `:583-584`). `main_by_name || return 1` is at `:552`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:546-611`

---

## Claim 12: Block comment: "it starts at every instruction file stored there (and every .md under a .claude/rules/ directory at any depth ...) and follows an import into the file main stores at that path, whatever its name; a symlink there is followed to the path its text names. An imported path main lacks is recorded and not read."

**Location:** `scripts/lib/dev-cycle-read.sh:452-457`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers start selection (any-case `.md`, INSTRUCTION_FILE on the lower-cased basename, `.claude/rules/` at any depth), following into any name main stores, and record-without-read. It does not establish starts under symlinked directories (not covered).

Start selection is `if [[ "${f##*/}" =~ $INSTRUCTION_FILE || "$f" == .claude/rules/*.md || "$f" == */.claude/rules/*.md ]]` (`:569`), where bash `*` also matches `/`. The record step is `IMPORTED_MAIN+="$(lower "$p")"$'\n'` (`:602`). A path is queued only `if [[ -n "${ent[$p]+set}" ]]` (`:605`). Tests 3 and 6 pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:567-573`, `:600-609`; `$S/logs/suites.out`

---

## Claim 13a: Block comment refusal list (all but the doubled-name atom): "a name holding a newline, symlink text that is empty, absolute, leaves the repo, holds a newline or a NUL, or has a .. after a symlink (on main or in the checkout), an imported path main lacks that lies under a directory main stores as a symlink or gitlink, or that the checkout holds as anything but a plain directory (the root itself included), and a start file main lacks (untracked, ignored, or in the checkout's index) fail the walk, so isimported main answers imported for every path. ... A start file answers imported only when an import reaches it"

**Location:** `scripts/lib/dev-cycle-read.sh:457-466`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed shape, the root case, and the start-file answer. It does not establish the doubled-name atom (13b).

Each shape maps to a `return 1` (`:557`, `:563`, `:570`, `:583-586`, `:591`, `:596`, `:607`, `:608`), and each is pinned by a test or mutant (X1, X3). The root case: X4 P1 (`@.`) gives `walk: failed`, because `blocker . dir` prints `./`: `plaindir` compares `realpath -e .` with `$ROOT_REAL/.` (`:100`). For the start-file answer, test 3 asserts `CLAUDE.md -`. Start files enter `seen` (`:571`) but not `IMPORTED_MAIN`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:100`, `:110-121`, `:553-609`; `$S/logs/probes1.out`; `$S/logs/mutants.summary`

---

## Claim 13b: Block comment (also F11 `:126`, the U2a3 bullet `:276`, A5's "odd names"): "a doubled name ... fail[s] the walk", which the fail-closed contract relies on; override row `docs/reviews/override-log.md:379`: "A name main stores as both a blob and a tree fails the walk closed"

**Location:** `scripts/lib/dev-cycle-read.sh:457-458`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a root tree that lists `l` twice, as a symlink and as a tree, in both orders, walked in a fresh `git worktree add` checkout of main. It does not establish what Claude Code loads beyond the kernel read of the imported path, or how such a tree could reach main in practice: it needs a non-canonical tree object (`git hash-object -t tree --literally`), which `git fsck` flags as `duplicateEntries`. Git does not fsck incoming objects by default (`receive.fsckObjects` is off).

The doubled-name check sees only full paths: `[[ -z "${ent[$f]+set}" && "$f" != *$'\n'* ]] || return 1` (`:557`). A name stored once as a blob and once as a tree is printed by `ls-tree -r` as two different paths (`l` and `l/x.md`), so the check never fires.

- **Blob-first** (what `git mktree` writes): `git cat-file blob main:l/x.md` fails, and the walk fails closed. Row 379 holds for this order.
- **Tree-first** (non-canonical; X4 P2): `ls-tree -r` lists `l/x.md`, then `120000 ... l`. `main:l/x.md` resolves into the tree (`benign`). A fresh worktree writes `l -> docs`, and the kernel reads `l/x.md` as `evil @secret.md`. CLAUDE.md imports `@l/x.md`, yet the walk answers `walk: ok l/x.md: imported docs/x.md: - docs/secret.md: -`.

This is a fail-open against the walk's own contract: main alone, checked out fresh, makes `docs/secret.md` load. The walk did the same at cc1aa864 (same `:557` logic, unchanged by the split), so it is not a regression. It is new evidence against row 379's "fails the walk closed", which was probed only in the canonical order. A fix could refuse any `ls-tree -r` name that is also a proper prefix of another name; the loop already walks every ancestor of a path main lacks.

**Evidence:** `scripts/lib/dev-cycle-read.sh:553-560`, `:579`, `:600-609`; `docs/reviews/override-log.md:379`; `$S/logs/probes1.out`; `$S/probes1.sh`

---

## Claim 14: Block comment: "Not covered (known issue A5): start files under a symlinked directory or in a submodule or untracked nested repo, other names one file has on a case-insensitive checkout, absolute imports, and three shapes A5 lists as untraced against Claude Code."

**Location:** `scripts/lib/dev-cycle-read.sh:466-469`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers agreement with A5 and the walk-side behaviour (Claim 8d). It does not establish Claude Code's side.

The list matches A5's "Not covered" list item for item, and A5 names the three untraced shapes. Executed evidence is the same as Claim 8d.

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`; `$S/logs/probes2.out`

---

## Claim 15: Cache sentence: "IMPORTED_MAIN reads "error" until a walk succeeds; the result is cached for the commit, MAIN_BY_NAME and root in IMPORTED_MAIN_DONE, so a caller whose checkout changes between calls sets IMPORTED_MAIN_DONE="" to walk again."

**Location:** `scripts/lib/dev-cycle-read.sh:470-472`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the key, the reset and the cached failure as observed by a caller between calls. It does not establish the mid-walk value (`$'\n'` is set at `:574` before the walk ends; row on errexit-off is settled).

The cache is `[[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }`, followed by `IMPORTED_MAIN=error; IMPORTED_MAIN_DONE=...` (`:550-551`). Every `return 1` after `:574` sets `error` first (`:579-608`). Test 16 asserts `- docs/b.md x.sh x.sh - y.sh`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:474`, `:550-551`, `:574-608`; `test/scripts/build-loop-check.bats:306-315`; `$S/logs/suites.out`

---

## Claim 16: nul_list: "array NAME gets CMD's NUL-split output, or is emptied and 1 unless CMD exited 0 and its output ended in NUL."

**Location:** `scripts/lib/dev-cycle-read.sh:516`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers empty output, output with no final NUL, a failing CMD and a normal listing. It does not establish behaviour for a CMD killed by a signal mid-write.

The code is `mapfile -d '' nl_a < <("$@" && printf rc=0 || printf rc=1); [[ ${#nl_a[@]} -gt 0 && "${nl_a[-1]}" == rc=0 ]] || { nl_a=(); return 1; }; unset 'nl_a[-1]'`. X5 results: `empty: rc=0 n=0`, `no-final-NUL: rc=1 n=0`, `false: rc=1 n=0`, `two: rc=0 n=2`. Empty output succeeds, which the walk needs, since an empty untracked list is normal, even though empty output does not "end in NUL". The precise version: "unless CMD exited 0 and its output was empty or ended in NUL".

**Evidence:** `scripts/lib/dev-cycle-read.sh:517`; `$S/logs/probes2.out`

---

## Claim 17: Return-1 comment: "returns 1, with IMPORTED_MAIN set to "error" ... when main is not found by name, the commit's tree or the untracked list cannot be listed whole (nul_list), a tree record does not parse, a name is listed twice ... or holds a newline, the lower-cased start list comes back short, a start file main lacks exists, a blob cannot be read, symlink text ... or an imported path main lacks lies under a directory main stores as a symlink or gitlink or exists in the checkout as anything but a plain directory below the root; need_root exits instead."

**Location:** `scripts/lib/dev-cycle-read.sh:536-545`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the map from every `return 1` in `:546-611` to the list. It does not establish the I2-C2-style causes in `import_targets` and `lower` (fixed in U2a3b, stacked).

Every listed cause is real and fails. The list misses two causes in the code:

1. The checkout index listing, `nul_list recs env GIT_LITERAL_PATHSPECS=0 git ls-files -z --cached ... || return 1` (`:562`). The comment names only "the commit's tree or the untracked list".
2. The unmodelled record-type arm, `*) IMPORTED_MAIN=error; return 1 ;;` (`:598`). X4 P3 shows `ls-tree` printing even `--literally` modes 100664/100640 as `100644`, so the arm is unreachable through today's listing. It is still a path in the code.

"a start file main lacks exists" is also loose. X4 P4 fails on an index entry whose file was deleted from the work tree (`AD d/AGENTS.md`). The precise wording is "is listed (untracked, ignored or in the index)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:552-608`; `$S/logs/probes1.out`

---

## Claim 18: Link-text comments: "$(...) drops NULs, so they are counted first; the x keeps trailing newlines, which $(...) would also drop" and "realpath -s reads x/.. as nothing, but the kernel follows a symlink x first: a .. after a symlink on main or in the checkout fails" (with the `mapfile -t -d /` split)

**Location:** `scripts/lib/dev-cycle-read.sh:581-594`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers NUL counting, newline preservation, `..` after a link on main or in the checkout, and the split reading long text whole. It does not establish Claude Code's resolution of `@` tokens (A5 untraced).

- NUL counting: `tr -cd '\0' | wc -c` with `[[ "$i" -ne 0 ]]` (`:583`); test 9 covers it.
- Trailing newline: `&& printf x` then `out="${out%x}"` (`:584-585`); test 7 covers it.
- `..` after a link: test 15, on main and checkout-only. h-parentimm and 2b-splitnone are killed by 15.
- Long text: h-linksplit is killed by test 10.
- X6's second shape fails as described.

**Evidence:** `scripts/lib/dev-cycle-read.sh:580-596`; `$S/logs/mutants.summary`; `$S/logs/probes3.out`

---

## Claim 19: `160000) continue ;;  # a gitlink: its files are not main's` and `*) IMPORTED_MAIN=error; return 1 ;;`

**Location:** `scripts/lib/dev-cycle-read.sh:597-598`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the arms' behaviour: a gitlink start reads nothing with walk ok, and any other type fails. It does not establish test coverage. No test reaches either arm: h-gitlinkcont (fail on a gitlink) and h-starrm (`*) continue`) both survive the suite. `*)` is unreachable through `ls-tree -r`'s canonical modes (X4 P3).

X4 P6 (gitlink stored as `CLAUDE.md`) gives `walk: ok CLAUDE.md: imported y.sh: -`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:578-599`; `$S/logs/probes1.out`; `$S/logs/mut-h-gitlinkcont.out`; `$S/logs/mut-h-starrm.out`

---

## Claim 20: Parent-check comment: "Main lacks p: under a link or gitlink main stores, or in the checkout as anything but a plain directory, fail." (with `c="$p"; while [[ "$c" == */* ]]; do c="${c%/*}"; [[ ! "${ent[$c]:-}" =~ ^1[26]0000$ ]] ...`)

**Location:** `scripts/lib/dev-cycle-read.sh:606-608`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every proper ancestor (120000 or 160000 in `ent`), the checkout probe and the plain-directory allowance. It does not establish the root case's wording here: the root is a plain directory but fails, as the block comment says (`:462`).

`ent` holds only `ls-tree -r` leaves, so ancestors match only links or gitlinks. The regex matches exactly 120000 and 160000. Mutants gitlink (12), parentimm (15), probe (3, 9, 12) and plaindir (9) are each killed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:600-609`; `$S/logs/mutants.summary`

---

## Claim 21: New index listing: start files the checkout's index tracks but main lacks fail the walk

**Location:** `scripts/lib/dev-cycle-read.sh:561-570`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers top-level and nested names, any case (`:(glob,icase)**/*.md`), and the exact-name exclusion of paths main stores. It does not establish a differently cased duplicate of a path main stores on a case-insensitive filesystem (A5).

`[[ -n "${ent[$f]+set}" ]] || cand+=("t:$f")` (`:563`). Test 3 covers top-level CLAUDE.local.md and X4 P4 covers nested `d/AGENTS.md`. h-index is killed. X4 P4b: a non-start `notes.md` staged in the index leaves the walk ok, so only start-shaped names fail.

**Evidence:** `scripts/lib/dev-cycle-read.sh:561-573`; `$S/logs/probes1.out`; `$S/logs/mut-h-index.out`

---

## Claim 22: isimported: "Whether path $2 (any case) is imported, by the walk $1 names: tree or main. A failed main walk, or a walk name that is neither, answers imported (0), so a caller testing it with `if` refuses; ... Run it in the caller's shell: the walk exits through need_root and caches its result."

**Location:** `scripts/lib/dev-cycle-read.sh:612-616`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the main, tree and unknown arms and the lower-casing on both sides. It does not establish a failing `lower` (fixed in U2a3b).

The arm is `main) main_imports || return 0; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]]`, with `*) return 0` (`:622-624`). Tests 2, 8 and 14 assert `imported` under `if`. Test 3 asserts `Docs/Imported.md imported`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:617-626`; `$S/logs/suites.out`

---

## Claim 23a: Test 9 name: "main walk fails on symlink text holding a NUL, on a checkout symlink or file at a path main lacks, and on an untracked start"

**Location:** `test/scripts/build-loop-check.bats:175`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what test 9's assertions pin. It does not establish the other suite tests.

Test 9 asserts a checkout symlink at a path main lacks (`docs/lt.md`), untracked starts and a NUL link. It never puts a regular checkout file at an imported path main lacks. The h-fileok mutant, which lets a plain file pass there, is killed by test 3 only, and test 9 passes under it. The precise name drops "or file", or the test adds a regular file at `docs/lt.md`.

**Evidence:** `test/scripts/build-loop-check.bats:175-201`; `$S/logs/mut-h-fileok.out`

---

## Claim 23b: The other new test names and comments (tests 3-8, 10-16)

**Location:** `test/scripts/build-loop-check.bats:46-315`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each name's listed cases against its `want` lines and the mutant kills. It does not establish coverage of `160000) continue` or `*)` (Claim 19), or test 15's ".. after a plain directory" through `ld/../evil.md`. There `ld` is absent on main and in the checkout, so `AGENTS.md -> docs/../docs/n.md` is the case that exercises it.

Every named case has a matching assertion. Test 10's link comment matches its fixture (Claim 3a). Test 12's "Empty symlink text in sub/" fails at `-z "$out"` (`:586`). Test 16's output string matches its sequence. All 16 pass (X1).

**Evidence:** `test/scripts/build-loop-check.bats:46-315`; `$S/logs/suites.out`; `$S/logs/mutants.summary`

---

## Claim 24: dev-cycle.bats inventory lists `main_imports nul_list` and `IMPORTED_MAIN IMPORTED_MAIN_DONE`

**Location:** `test/scripts/dev-cycle.bats:1086-1090`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the names exist once the lib is sourced. It does not establish that the inventory is exhaustive.

`main_imports` is defined at `:546`, `nul_list` at `:517`, and both variables at `:474`. dev-cycle.bats passes 75/75 (X1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:474`, `:517`, `:546`; `$S/logs/suites.out`

---

## Claim 25: Commit 2b22a082: "build-loop-check.bats 16; 114 across the five suites. ... 392 changed code lines against main."

**Location:** commit 2b22a082 (body, Tests paragraph)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at 2b22a082, with the five suites read as dev-cycle, build-loop-read, build-loop-check, fixture-git-env and fixture-hermeticity. It does not establish other suite lists.

X2 gives 1..114, all ok, with build-loop-check at 16. X9 gives `2b22a082: 379+13=392`.

**Evidence:** `$S/logs/suites-2b.out`; `$S/logs/numstat.out`

---

## Claim 26: Commit 2b22a082: "Mutants of the untracked-start refusal, the checkout probe, the gitlink match, the parent loop (immediate parent only), the plain-directory allowance and the link-text split each fail."

**Location:** commit 2b22a082 (body, Tests paragraph)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the six mutant families at 2b22a082. It does not establish the commit author's exact mutant constructions.

Five families are killed at 2b22a082: untstart (3, 9, 11), probe (3, 9, 12), gitlink (12), parentimm (15) and plaindir (9). For the link-text split, dropping the split (`parts=()`) is killed by 15. Reverting C4's own fix to the here-string (`IFS=/ read -ra parts <<<"$out"`) survives all 16. The mutant that tests the change this commit made was not pinned until dfeeb85d (h-linksplit killed by 10). Commit message, immutable: pointer only, with dfeeb85d's E5 as the fix.

**Evidence:** `$S/logs/mut-2b-linksplit.out`; `$S/logs/mut-2b-splitnone.out`; `$S/logs/mutants.summary`

---

## Claim 27: Commit 2b22a082 behavioral claims: "C2 fixed: an imported path under a gitlink main stores fails"; "C4 fixed: ... (no here-string left in main_imports)"; "C8: the parent loop steps over "/" (was O(L^2))"; "C10: nul_list empties its array on failure"; "the untracked parts of the "follows", cycle and .MD tests move to U2a3c; new cases for a gitlink parent and a checkout file at a path main lacks"

**Location:** commit 2b22a082 (body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named change against the 2b22a082 tree and the test-name diff from 0170f16a. Its headline and D13 sentence are covered by override row `docs/reviews/override-log.md:388` (Accepted-immutable), and are only pointed to here.

The 0170f16a→2b22a082 test-name diff drops "the checkout's files" from test 6, drops "tracked or untracked" from test 11 and the "untracked file" cycle from test 13, and adds "a path under a gitlink" (test 12) and "a checkout file at a path main lacks" (test 3). `grep '<<<'` over `$S/lib-2b.sh` main_imports finds none (paraphrased — no quote available because the claim covers absence of code). The other code claims are the same as Claim 1.

**Evidence:** `$S/lib-2b.sh`; `$S/logs/mutants.summary`; `$S/logs/probes2.out`

---

## Claim 28: Commit dfeeb85d: "Tests: build-loop-check.bats 16; 114 across the five suites. Mutants of the index listing, the link-text split (here-string revert) and the newline check each fail. 400 changed code lines against main."

**Location:** commit dfeeb85d (body)
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at HEAD (dfeeb85d's code is identical: X9 shows 400 at both) and the three mutants. It does not establish that every unlisted arm is pinned (Claim 19).

X1 gives 114 ok with build-loop-check at 16. Mutants: h-index is killed by 3, h-linksplit by 10 and h-newline by 7. X9 gives `dfeeb85d: 387+13=400`.

**Evidence:** `$S/logs/suites.out`; `$S/logs/mutants.summary`; `$S/logs/numstat.out`

---

## Claim 29a: Commit dfeeb85d behavioral claims: E1 "The walk now also lists the checkout's tracked .md files; a start-shaped one main lacks fails the walk"; E2 "header, A5, F11 and the U2b bullet say so"; E4 "a gitlink continues and any other type fails the walk"; E3 "dev-cycle.bats lists nul_list"; E5 "a 67 KB link under ulimit -f 0 with XFSZ ignored pins the link-text split (isolated from the new index check)"; E6 "the plan's U2a3c bullet carries architecture F1 and F5"

**Location:** commit dfeeb85d (body)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each item against the 0032ed5a→dfeeb85d diff and the HEAD runs. It excludes the test-rename and "start name" phrases (29b, 29c).

The fresh-worktree sentence appears at `:32-33` in the header, in A5, in F11 and at `:279` in U2b. Other evidence: Claims 2, 3a, 10, 19, 24.

**Evidence:** `scripts/lib/dev-cycle-read.sh:32-33`, `:561-563`, `:597-598`; `docs/working/plan-build-loop-handoff.md:126`, `:277`, `:279`; `$S/logs/mutants.summary`

---

## Claim 29b: Commit dfeeb85d: "tests 9 and 3 renamed for the split"

**Location:** commit dfeeb85d (body, E5)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `@test` names at 0032ed5a vs dfeeb85d. It does not establish what the author meant by "3".

Diffing the two commits' `@test` lines changes only test 9, from "... and on a checkout symlink it would read" to "..., on a checkout symlink or file at a path main lacks, and on an untracked start". Test 3's name is unchanged in dfeeb85d; it was renamed in 2b22a082. dfeeb85d's only change to test 3 is the added `git add -f CLAUDE.local.md` line. Commit message, immutable: an Accepted-immutable row is the expected disposition.

**Evidence:** `diff <(git -C $W show 0032ed5a:test/scripts/build-loop-check.bats | grep '^@test') <(git -C $W show dfeeb85d:... )` (cwd `$S`, diff exit 1 = differences found, 03:46:39Z) → `$S/logs/testnames.out` (one changed line, `9c9`); `test/scripts/build-loop-check.bats:46`, `:175`

---

## Claim 29c: Commit dfeeb85d: "test 7's newline fixture is a start name"

**Location:** commit dfeeb85d (body, E5)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers how the code classifies `zz<LF>CLAUDE.md`. It does not establish any other fixture.

The fixture's second line is a start name. The whole name, though, is not start-shaped to the code: `${f##*/}` is `zz<LF>claude.md`, which `^...$` does not match. Under h-newline, which drops the newline check, the walk answers `walk: ok`. The test therefore pins the newline check (`:563`) and not a start refusal. The precise version: "a name whose part after the newline is a start name".

**Evidence:** `test/scripts/build-loop-check.bats:148-152`; `$S/logs/mut-h-newline.out`

---

## Claim 30: docs(reviews) commits 0032ed5a, 5c57d367, 1898d21c: "fact-check, critic reports, rubric and override rows"; "fix-drift output ... (no findings)"

**Location:** commits 0032ed5a, 5c57d367, 1898d21c
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the files each commit adds and their headers. It does not re-verdict the reports' contents.

`lite-review-fix-drift-build-loop-u2a3-split.txt` and `-L2i1.txt` each read `lite-review [fix-drift]: FINDINGS: NONE`. 0032ed5a adds the six L2 reports (each `Commit: 5c57d367`), the rubric section and override rows. The rubric's "33 claims: 20 Verified, 11 Mostly accurate, 1 Stale, 0 Incorrect, 1 Unverifiable" matches the L2 report's Summary line.

**Evidence:** `docs/reviews/lite-review-fix-drift-build-loop-u2a3-split.txt:1`, `docs/reviews/lite-review-fix-drift-build-loop-u2a3-L2i1.txt:1`, `docs/reviews/code-fact-check-report-build-loop-u2a3-L2.md:1-8`

---

## Claims Requiring Attention

### Incorrect
- **Claim 13b** (`scripts/lib/dev-cycle-read.sh:457-458`, `:557`; also F11, U2a3 bullet, A5, override row `docs/reviews/override-log.md:379`): a non-canonical tree listing a name as a tree before a symlink makes the walk answer ok while a fresh worktree loads an import it never records (`docs/secret.md: -`). This is a fail-open. Refuse an `ls-tree -r` name that is a proper prefix of another listed name, and revisit row 379.
- **Claim 8c** (`docs/working/known-issues-dev-cycle.md:18`): "a link in link text ... fails the walk". Only a `..` after a checkout link fails, or a link at or above a target main lacks. Reword to match the lib comment.
- **Claim 29b** (commit dfeeb85d): "tests 9 and 3 renamed" is wrong; only test 9 was renamed. Commit message: Accepted-immutable.

### Mostly Accurate
- **Claim 16** (`scripts/lib/dev-cycle-read.sh:516`): empty output also succeeds ("was empty or ended in NUL").
- **Claim 17** (`scripts/lib/dev-cycle-read.sh:536-545`): add the index listing (`:562`) and the unmodelled record type (`:598`); "exists" should be "is listed".
- **Claim 23a** (`test/scripts/build-loop-check.bats:175`): test 9 pins no regular checkout file at a path main lacks.
- **Claim 26** (commit 2b22a082): the here-string revert of C4's fix survived at 2b22a082 (pinned since dfeeb85d).
- **Claim 29c** (commit dfeeb85d): the fixture's post-newline half is a start name. The whole name is not.

### Unverifiable
- **Claim 3b** (rubric `:34`): "35 in /workspace's own checkout" needs a listing of /workspace, outside this pass's permitted tree.

## Escalations

- `scripts/lib/dev-cycle-read.sh:557` (and `docs/reviews/override-log.md:379`). Addressee: security-reviewer (also the author). A tree-first doubled blob/tree name fails open in a fresh worktree (Claim 13b, X4 P2, executed). This is new evidence against row 379's "fails the walk closed".
- `docs/working/known-issues-dev-cycle.md:18`. Addressee: author. The "a link in link text" phrase (Claim 8c, X6).
- `scripts/lib/dev-cycle-read.sh:597-598`. Addressee: test-strategy critic. No test reaches `160000) continue` or `*)`; both mutants survive. `*)` cannot be reached through `ls-tree -r` (X4 P3), so only the gitlink arm is pinnable, for example a gitlink stored at a start name with walk ok (X4 P6).
- `test/scripts/build-loop-check.bats:175`. Addressee: test-strategy critic. Test 9's name claims a regular checkout file case it does not assert (h-fileok).

## Goal-Alignment Note

**Success criterion (restated verbatim):** A code-fact-check report verdicting every checkable claim in the U2a3 diff's comments, docs and commit messages, saved at the path given below.

**Answered:** Yes. 38 claims cover all six focus areas:

1. The lib comments: Claims 11-22. The fail-closed hunt found one main-side fail-open, the tree-first doubled blob/tree name (13b), and no checkout state that answers ok while missing an import main alone or cc1aa864 would catch, beyond the documented and settled gaps.
2. The index listing, the case arms, the split and the parent loop: Claims 18-21.
3. A5, F11, U2a3, U2a3c and U2b: Claims 8a-10.
4. Commits since 0170f16a, with every figure re-run (114 at 2b22a082 and at HEAD; 392 and 400 lines) and every named mutant constructed: Claims 25-30.
5. Test names: Claims 23a-23b.
6. Rubric and new override rows: Claims 1-7.

Five suites pass at HEAD (114/114).

**Out of scope:** What Claude Code itself loads (no host probe); U2a3b's parser and lower failure arms; U2a3c, U2a4 and U2b future behaviour; /workspace's own checkout (the "35" figure); commit messages before 0170f16a, which have override rows (pointers only).

**Escalate:** Claim 13b (a fail-open of low likelihood: it needs a crafted non-canonical tree object in main's history) to security-reviewer and the author before merge-readiness is decided. Claims 8c and 17 are doc wording. Claims 19 and 23a are test-coverage gaps.
