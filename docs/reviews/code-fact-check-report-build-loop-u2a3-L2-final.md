Commit: 1898d21c
# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u2a3`, branch `feat/build-loop-u2a3`)
**Scope:** `git diff main...HEAD` at 1898d21c (base main 62d366a7), loop 2 final confirming pass: comments in `scripts/lib/dev-cycle-read.sh`; test names and comments in `test/scripts/build-loop-check.bats` and `test/scripts/dev-cycle.bats`; known issue A5; plan F11 and the U2a3, U2a3c and U2b bullets; the rubric's split-decision and Loop 2 sections; the override-log rows added since 0170f16a; the messages of 2b22a082, 5c57d367, 0032ed5a, dfeeb85d and 1898d21c. Merged from replicates `code-fact-check-report-build-loop-u2a3-L2f-r1.md`, `-r2.md`, `-r3.md` (role `cfc2f`, pass `i2`) by most-severe-wins with annotation union; no claim or evidence was added in the merge.
**Checked:** 2026-10-06
**Total claims checked:** 56
**Summary:** 40 verified, 8 mostly accurate, 0 stale, 7 incorrect, 1 unverifiable
**Commit:** 1898d21c
**Replication:** k=3

Merge notes. Clusters are emitted at the finest granularity any replicate used, so a sentence one replicate split (r3's rubric E1/E2/E4-E5 rows, A5's checkout atoms, the doubled-name atom; r1's tests 5/9/12 and test 7/10 comments; r1/r2's dfeeb85d E5 atoms) is one row per atom. A replicate that verdicted only the enclosing compound carries its verdict onto each atom row marked `(compound)`. Where a replicate's own prose or Scope places its compound verdict's severity on one specific atom, that row takes the verdict at its severity and says so (rows 2a, 9c); on the sibling atoms the compound verdict is recorded but does not decide, and the atom's explicit verdicts decide (rows 2b, 2c, 9b). Replicate scratch roots: r1 `/tmp/u2a3-cfc2f-i2-avmk`, r2 `/tmp/u2a3-cfc2f-i2-x7bC`, r3 `/tmp/u2a3-cfc2f-i2-aiLl`; each replicate's execution provenance (commands, cwd, exit, UTC timestamps 2026-10-07T03:31Z-03:46Z) is in its own report header and is not repeated here. Across replicates: the five suites pass at HEAD, 114/114 (r1 X1, r2 Claim 28, r3 X1).

---

## Claim 1: rubric split dispositions: "C2 (gitlink parent): fixed. A 160000 parent fails the walk like a 120000 one." / "C4 ... fixed (`mapfile -d /` from a process substitution)." / "C7 ... test 15 ..." / "C8 ... steps over `/` with `${c%/*}`" / "C10 (nul_list partial array): fixed (emptied on failure)." / "C1 ... An untracked start fails the walk until U2a3c"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md:9-17`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the code claims against lib :517, :589 and :607 (r1); it does not establish that C10's emptying is pinned by any test: the nlemptyarr mutant survives (r1 X3), and the rubric does not claim that it is.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish that the dispositions of C3, C9 and C12 (override rows) are right on the merits"; C7 checked: test 15 follows each `want walk failed` with `want deep/... imported` and has a one-letter link two levels up · r3: "does not establish U2a3c's future behaviour"; C1 checked via `:570`, h-untstart killed

The quoted code (r1): `c="$p"; while [[ "$c" == */* ]]; do c="${c%/*}"; [[ ! "${ent[$c]:-}" =~ ^1[26]0000$ ]] || { IMPORTED_MAIN=error; return 1; }; done` (`scripts/lib/dev-cycle-read.sh:607`), `mapfile -t -d / parts < <(printf '%s' "$out")` (`:589`), and nul_list's `|| { nl_a=(); return 1; }` (`:517`). Mutants gitlinkpar (fails test 12), herestring (fails test 10) and parent1 (fails test 15) are killed; the nul_list probe prints `no-trailing-NUL rc=1 n=0` and `fail rc=1 n=0`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:517`, `scripts/lib/dev-cycle-read.sh:589`, `scripts/lib/dev-cycle-read.sh:607`, `/tmp/u2a3-cfc2f-i2-avmk/mutants.txt`, `/tmp/u2a3-cfc2f-i2-avmk/probes/nul_list.txt`

---

## Claim 2a: rubric Loop 2 row E1 author note: "The walk also lists the checkout's tracked .md files; one main lacks is a start main lacks and fails the walk. Test: test 3 stages CLAUDE.local.md; mutant killed."

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md:31`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers E1's mechanism sentence and its test note (r1); it does not establish the critics' severity calls.
**Replicate verdicts:** r1=Mostly accurate (compound; r1's prose places it on E1's mechanism sentence) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: "Only a start-shaped tracked `.md` fails ... Precise version: 'a start-shaped one main lacks'" · r2: the mutant replacing `:562` with `recs=()` fails test 3 only · r3: "does not establish behaviour under GIT_INDEX_FILE or a sparse index (row 387, deferred to U2b)"; X5 shows the index-only start passing at 2b22a082 and failing at HEAD; r3 Claim 21: "a non-start `notes.md` staged in the index leaves the walk ok, so only start-shaped names fail"

E1's test note is right: the index mutant fails test 3 (r1). E1's mechanism sentence is too broad: the code reads `[[ "${cand[i]:0:1}" == m ]] || return 1` inside the `if [[ "${f##*/}" =~ $INSTRUCTION_FILE || ... .claude/rules/*.md ...` branch (`scripts/lib/dev-cycle-read.sh:569-570`), so a tracked non-start `.md` main lacks leaves the walk ok (paraphrased — no quote available because r1 cites its X4 shapes P4 probe output in summary form).

**Evidence:** `scripts/lib/dev-cycle-read.sh:561-573`, `/tmp/u2a3-cfc2f-i2-avmk/mutants.txt`, `/tmp/u2a3-cfc2f-i2-avmk/probes/shapes.txt`

---

## Claim 2b: rubric Loop 2 row E2: "Ignored instruction files fail the walk (35 in /workspace's own checkout)"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md:32`
**Type:** Behavioral / Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the mechanism: an ignored start file fails the walk (r3); it does not establish the figure 35, which needs a listing of /workspace's own checkout, outside r3's permitted tree.
**Replicate verdicts:** r1=Mostly accurate (compound; severity placed on E1, not E2) · r2=Verified (compound) · r3=Unverifiable
**Replicate annotations:** r1: "the probe counts 35 start-shaped untracked or ignored `.md` files under `devcontainer-config/claude-home`, and the walk fails there (X5)" · r2: "gives 35 names, all under `devcontainer-config/claude-home/`, and `git check-ignore` reports all 35 as ignored (`.gitignore:52`)"; probe `ignored-rules` answers `failed` · r3: the count was not run "because the shared context restricts work to the worktree"; in this worktree the walk answers `walk ok` with 0 such files

r3's X8 created an ignored `home/.claude/CLAUDE.md`, with `home/` in `.gitignore`: `ignored start: walk: failed docs/a.md: imported x.sh: imported`. `.gitignore:52` holds `devcontainer-config/claude-home/`. The Unverifiable verdict is a scope limit of r3, not a contrary finding: r1 and r2 each executed the /workspace count and got 35 (annotations).

**Evidence:** `.gitignore:52`, `scripts/lib/dev-cycle-read.sh:515`, `/tmp/u2a3-cfc2f-i2-aiLl/logs/probes5.out`, `/tmp/u2a3-cfc2f-i2-aiLl/logs/worktree-walk.out`, `/tmp/u2a3-cfc2f-i2-avmk/workspace-walk.txt`, `/tmp/u2a3-cfc2f-i2-x7bC/logs/ws-starts.txt`

---

## Claim 2c: rubric Loop 2 rows E4/E5: "`160000) continue`, any other type fails the walk"; "fixture `zz<LF>CLAUDE.md`; a 67 KB link under `ulimit -f 0` with XFSZ ignored ... isolated from the new index check; both mutants killed"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md:34-35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the case arms, the fixture shapes, the 67 KB size and the two mutant kills (r3); it does not establish that any test reaches the `*)` arm or the `160000) continue` arm (both mutants survive).
**Replicate verdicts:** r1=Mostly accurate (compound; severity placed on E1, not E4/E5) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: "E5 matches the runs: the fixture is `zz<LF>CLAUDE.md`, the link is 68,589 bytes (about 67 KiB), and both mutants are killed (untrnl fails test 7, herestring fails test 10)" · r2: here-string mutant at `:589` fails test 10 only, newline mutant at `:563` fails test 7 only

The arms are `160000) continue ;;  # a gitlink: its files are not main's` and `*) IMPORTED_MAIN=error; return 1 ;;` (`scripts/lib/dev-cycle-read.sh:597-598`). The link text is `x="$(for i in $(seq 270); do printf '%0250d/../' 0; done)l/../t.md"` (`test/scripts/build-loop-check.bats:223`), 270 x 254 + 9 = 68,589 bytes, run after `git read-tree main`. h-linksplit is killed by test 10 and h-newline by test 7 (r3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:597-598`, `test/scripts/build-loop-check.bats:148-152`, `test/scripts/build-loop-check.bats:222-226`, `/tmp/u2a3-cfc2f-i2-aiLl/logs/mutants.summary`

---

## Claim 2d: rubric Loop 2 row E6: the U2a3c bullet carries architecture L2 Findings 1 and 5

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md:36`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers E6's citation (r2, within its E1-E6 compound); it does not verify U2a3c, which is not built.
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=— · single-replicate detection
**Replicate annotations:** none

r2: "E6: the U2a3c bullet carries architecture L2 Findings 1 and 5 (Claim 9)", where its Claim 9 cites `architecture-review-review-2026-10-06-L2-build-loop-u2a3.md:150` (Finding 1) and `:154` (Finding 5).

**Evidence:** `docs/working/plan-build-loop-handoff.md:277`, `docs/reviews/architecture-review-review-2026-10-06-L2-build-loop-u2a3.md:150`

---

## Claim 3: earlier commit messages (fbeae280 through 0170f16a): pointers to their Accepted-immutable override rows

**Location:** `docs/reviews/override-log.md:380-382`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** A pointer only (r1): the earlier messages are not re-verdicted; their findings sit in the Accepted-immutable rows at `override-log.md:380-382` and :388.
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

Rows :380 (4f087967 and 34edec56), :382 (e7b5d7ed and c42f017f) and :388 (2b22a082) are present (paraphrased — no quote available because this is a pointer list, per r1).

**Evidence:** `docs/reviews/override-log.md:380-388`

---

## Claim 4: override row (C3, Defer): "After the split U2a3 reads no checkout content (a path there is only probed and fails the walk if present), so nothing it would read is lost"

**Location:** `docs/reviews/override-log.md:383`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim that no checkout file's content is read, and what the probe does (r1); it does not establish the claim about Claude Code's same-uid access (a host claim).
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=—
**Replicate annotations:** r2: "does not re-measure C9's timing"; "This repeats loop 2 iteration 1 Claim 32. The rows are Defer/Won't-Fix and the wording does not change their trigger."; probe `lacked-plain-dir` answers `ok`

Every read is `git cat-file blob "$MAIN_SHA:$f"` (`scripts/lib/dev-cycle-read.sh:579`, `:583-584`). But "fails the walk if present" is too broad; a present plain directory passes the probe:

```bash
# scripts/lib/dev-cycle-read.sh:608
      [[ -d "$p" && ! -L "$p" && -z "$(blocker "$p" dir)" ]] || [[ ! -e "$p" && ! -L "$p" ]] || { IMPORTED_MAIN=error; return 1; }
```

The plaindir mutant fails test 9 (r1 X3). Precise version: "fails the walk if present as anything but a plain directory".

**Evidence:** `scripts/lib/dev-cycle-read.sh:561-562`, `scripts/lib/dev-cycle-read.sh:579-593`, `scripts/lib/dev-cycle-read.sh:608`, `/tmp/u2a3-cfc2f-i2-avmk/m-plaindir.out`, `/tmp/u2a3-cfc2f-i2-x7bC/logs/probe.log`

---

## Claim 5: override row (E7): "a deep 64 KB `a/a/.../x.md` token takes 9-16 s (one long segment is now 0.27-1 s) ... Slow, never fail-open; only text committed to main reaches it after the split"

**Location:** `docs/reviews/override-log.md:386`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers one 65,524-byte `a/` token on this machine and where the loop's input comes from (r1); it does not establish the timing on other hardware, or the "0.27-1 s" one-segment figure (not re-run by r1).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: 11.82 s, `ok`; "does not establish the 'one long segment is now 0.27-1 s' sub-figure (not run)" · r3: 11.66 s (walk ok); "One 65,000-byte segment took 0.29 s"; "does not establish timings on other hosts"

r1's two runs took 11.36 s and 8.63 s, both `ok`. The loop's `p` comes only from `out` (`done < <(printf '%s\n' "$out")`, `scripts/lib/dev-cycle-read.sh:609`), built from a main blob through `import_targets` (`:579`) or main's link text (`:583-596`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:579-609`, `/tmp/u2a3-cfc2f-i2-avmk/probes/perf.txt`, `/tmp/u2a3-cfc2f-i2-x7bC/logs/probe4.log`, `/tmp/u2a3-cfc2f-i2-aiLl/logs/probes4.out`

---

## Claim 6: override row (E8): "the lib does not set GIT_NO_REPLACE_OBJECTS; build-loop.sh exports it"

**Location:** `docs/reviews/override-log.md:387`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where the variable is set (r2); it does not test the listed bypass candidates (GIT_INDEX_FILE, fsmonitor, replace refs, sparse checkout), which the row defers.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish that build-loop.sh's export reaches a future U2a4/U2b caller of `main_imports`" · r3: "does not establish whether replace refs or grafts can mislead the walk (untested; deferred to U2b)"

`grep -n GIT_NO_REPLACE_OBJECTS` finds only `scripts/build-loop.sh:118` (`export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1`) and nothing in the lib (paraphrased — no quote available because the claim is about an absence of matches).

**Evidence:** `scripts/build-loop.sh:118`

---

## Claim 7: override row (E10): "a start file only in the checkout's index then passed; fixed in the loop 2 iteration 1 fix commit"

**Location:** `docs/reviews/override-log.md:388`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the before and after of the index listing (r1); it does not cover the row's D13 half (an Accepted-immutable commit-message row, not re-verdicted).
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified
**Replicate annotations:** r3: X5 `2b22a082: walk: ok docs/private.md: -`, then `HEAD: walk: failed docs/private.md: imported`

The index mutant replaces lib :562 with `recs=()`; with it, test 3's line `git add -f CLAUDE.local.md; imps main docs/guide.md; want walk failed` fails (r1 X3). At HEAD, X4 shapes P5 (an index-only `.claude/rules/x.md`) prints `failed docs/r.md:imp`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:562-563`, `test/scripts/build-loop-check.bats:61`, `/tmp/u2a3-cfc2f-i2-avmk/m-index.out`, `/tmp/u2a3-cfc2f-i2-aiLl/logs/probes2.out`

---

## Claim 8: override row (E9): "In a clean linked worktree `.git` is a file, so an instruction file importing `@.git` now fails the walk (pre-split it answered ok)"

**Location:** `docs/reviews/override-log.md:389`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `@.git` from a main checkout and from a linked worktree, with HEAD's lib and with cc1aa864's (r1); it does not establish the row's C9 timing figure.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not verify the ~0.27 ms process-substitution figure" · r3: X10 "measured about 0.32 ms per `mapfile < <(printf ...)` against about 0.007 ms for the here-string, the same order as ~0.27 ms"; "does not establish costs on other hosts"

`dotgit.sh` printed: main checkout, HEAD `ok` and cc1aa864 `ok`; linked worktree, HEAD `failed` and cc1aa864 `ok`. The failure comes from the probe at lib :608 (quoted in Claim 4): `.git` exists and is not a directory (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:608`, `/tmp/u2a3-cfc2f-i2-avmk/probes/dotgit.txt`, `/tmp/u2a3-cfc2f-i2-x7bC/logs/probe4.log`, `/tmp/u2a3-cfc2f-i2-aiLl/logs/procsub.out`

---

## Claim 9a: A5, main side (all but the doubled-name atom, Claim 13b): "symlinked start files and targets on main are followed, `.claude/rules/` at any depth starts, and odd names, link text that is empty, absolute, leaves the repo, holds a newline or NUL or has a `..` after a symlink, an imported path main lacks under a directory main stores as a symlink or gitlink fail it"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk's behaviour for each listed shape (r1); it does not establish that the suite pins each refusal (three are unpinned: Claims 24, 26a, 28a), or anything about Claude Code's own loading.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish that the tests isolate each refusal"; probe3 isolates empty and NUL link text, `failed` on HEAD · r3: "does not establish the 'odd names' (doubled-name) atom for a name doubled as a blob and a tree (Claim 13b)"

Code per shape (r1): starts at lib :569; symlinks in the `120000)` arm at :580-596; odd names :555-557; link text :583-586 and :591; parents :607 (paraphrased — no quote available because r1 lists line mappings, not quotes). Isolated X4 probes with the index equal to main show `HEAD nullink ... index=main: failed` and `HEAD emptylink ... index=main: failed`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:553-610`, `/tmp/u2a3-cfc2f-i2-avmk/bats-five.txt`, `/tmp/u2a3-cfc2f-i2-avmk/probes/mask.txt`, `/tmp/u2a3-cfc2f-i2-avmk/probes/treenl.txt`

---

## Claim 9b: A5, checkout: "a start file main lacks (untracked, ignored, or only in the checkout's index) ... or anything but a plain directory at an imported path main lacks fails the walk"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers untracked, ignored and index-only starts (one deleted from the work tree included) and plain-directory targets (r3); it does not establish starts that the listings never enter (nested repos, symlinked directories, unsearchable directories), which A5 lists as not covered or which override rows defer.
**Replicate verdicts:** r1=Mostly accurate (compound; severity placed on the link-in-link-text atom, Claim 9c) · r2=Incorrect (compound; severity placed on the link-in-link-text atom, Claim 9c) · r3=Verified
**Replicate annotations:** r1: "The start-file half and the plain-directory half hold (X3: untrstart, index, probe and plaindir are killed; X5 covers the ignored case)"; "does not establish failure for checkout edits to files main stores ... deliberately not read" · r2: "The start-file and plain-directory parts are Verified (Claims 12 and 17)"

The refusal is `[[ "${cand[i]:0:1}" == m ]] || return 1` (`scripts/lib/dev-cycle-read.sh:570`). Untracked: tests 3 and 11; ignored: X8 `walk: failed`; index-only: test 3, and X4 P4 fails when the index entry's file is deleted from the work tree; plain directory: X4 P5 walk ok (r3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:561-573`, `scripts/lib/dev-cycle-read.sh:608`, `/tmp/u2a3-cfc2f-i2-aiLl/logs/probes1.out`, `/tmp/u2a3-cfc2f-i2-aiLl/logs/probes5.out`

---

## Claim 9c: A5, checkout: "a link in link text ... fails the walk"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a checkout symlink at a component of link text that main stores, on two shapes: with and without a later `..` (r3); it does not establish what Claude Code loads beyond a kernel read of the path.
**Replicate verdicts:** r1=Mostly accurate (compound; r1's prose places it on this atom) · r2=Incorrect (compound; r2's Scope places it on this atom) · r3=Incorrect
**Replicate annotations:** r1: "A link in link text fails only when a `..` follows it"; X4 shapes P2 prints `ok ld/i.md:imp`; "Precise version: 'a link in the checkout followed by a `..` in link text'" · r2: "This verdict does not establish a fail-open relative to main alone: Claim 12 found none"; probe2 case A answers `ok: ld/i.md`, case B `failed`; "This phrase was added to A5 in dfeeb85d" · r3: "The lib comment (`:458-459`, 'has a .. after a symlink (on main or in the checkout)') is accurate. Only A5's added phrase is too broad (added in dfeeb85d)."

The code sets a flag, `[[ "${ent[$p]:-}" != 120000 && ! -L "$p" ]] || lk=1` (`scripts/lib/dev-cycle-read.sh:593`), and fails only when a `..` follows, via `[[ "$c" != .. || -z "$lk" ]] || { IMPORTED_MAIN=error; return 1; }` (`:591`). In r3's X6, main stores `CLAUDE.md -> x/y.md` with `x/` a directory and the checkout replaces `x` with `x -> other`: `walk: ok docs/a.md: imported docs/evil.md: -`, while the kernel reads CLAUDE.md as `other @../docs/evil.md`. Precise version (r3): "a `..` after a checkout link in link text, or a checkout link at or above an imported path main lacks, fails the walk".

**Evidence:** `scripts/lib/dev-cycle-read.sh:589-596`, `scripts/lib/dev-cycle-read.sh:605-608`, `/tmp/u2a3-cfc2f-i2-aiLl/logs/probes3.out`, `/tmp/u2a3-cfc2f-i2-x7bC/logs/probe2.log`, `/tmp/u2a3-cfc2f-i2-avmk/probes/shapes.txt`

---

## Claim 9d: A5: "A developer checkout with ignored instruction files (here, `devcontainer-config/claude-home/`) therefore always fails it; the gate needs a fresh worktree until U2a3c."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers /workspace's checkout as of 03:36Z and the code path that fails it (r2); it does not run `main_imports` inside /workspace's shared checkout.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: "The /workspace walk printed `walk failed` and the fresh clone at main printed `walk ok` (X5)"; "does not establish behaviour in a checkout whose ignored files are later removed" · r3: ignored start via X8; `.gitignore:52`

The 35 start-shaped untracked names in /workspace are all ignored and all under `devcontainer-config/claude-home/`. `untracked_md` lists ignored files (`:515` `git ls-files -z --others` without `--exclude-standard`), and `:570` fails on any such start (r2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:515`, `scripts/lib/dev-cycle-read.sh:570`, `/tmp/u2a3-cfc2f-i2-x7bC/logs/ws-starts.txt`, `/tmp/u2a3-cfc2f-i2-avmk/workspace-walk.txt`, `/tmp/u2a3-cfc2f-i2-avmk/fresh-walk.txt`

---

## Claim 9e: A5: "a path main lacks that the checkout does not hold is recorded but not walked"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers /workspace's checkout as of the run and a fresh clone at main (r1, compound); it does not establish behaviour in a checkout whose ignored files are later removed.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: "`:602` records the path before the main-lacks branch: `IMPORTED_MAIN+=\"$(lower \"$p\")\"$'\n'`. `:608` passes when `[[ ! -e \"$p\" && ! -L \"$p\" ]]`, and nothing queues it"; probe `lacked-absent` answers `ok: docs/new.md` · r3: test 3, `docs/new.md` absent answers `imported` and walk ok

Test 3 imports `docs/new.md`, which neither main nor the checkout holds, and gets `walk ok` with `docs/new.md: imported`; X4 shapes P2's `ld/i.md` is also recorded (`:imp`) and not walked (r1; paraphrased — no quote available because r1 summarizes test output).

**Evidence:** `scripts/lib/dev-cycle-read.sh:600-609`, `test/scripts/build-loop-check.bats:54-57`, `/tmp/u2a3-cfc2f-i2-avmk/probes/shapes.txt`

---

## Claim 9f: A5: "Not covered: start files under a symlinked directory or in a submodule or untracked nested repo (neither `ls-tree -r` nor `ls-files --others` enters one), other names one file has on a case-insensitive checkout, and absolute imports into the repo"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk's side of each gap (r3); it does not establish what Claude Code does for any of them (A5 marks them untraced, and no host probe was run).
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: case-insensitive gap "not run on such a filesystem"; "`core.ignorecase=true` on a case-sensitive filesystem hides an untracked `claude.md` from `ls-files --others` (probe `ignorecase-untracked-variant`, `ok` on all three libs). That falls under the 'case-insensitive' gap and the loop 2 bypass row (`override-log.md:387`)."

r3: untracked nested repo gives `walk: ok docs/n.md: -`; untracked symlink to a directory gives `walk: ok lnkdir/x.md: -`; absolute imports are dropped by `[[ -n "$t" && "$t" != "~"* && "$t" != /* ]] || continue` (`scripts/lib/dev-cycle-read.sh:500`); `@` tokens use `realpath -ms` (`:501`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:500-502`, `scripts/lib/dev-cycle-read.sh:577`, `/tmp/u2a3-cfc2f-i2-aiLl/logs/probes2.out`, `/tmp/u2a3-cfc2f-i2-x7bC/logs/probe.log`

---

## Claim 10: plan F11 (all but the doubled-name atom, Claim 13b): main-side refusal list, "Until U2a3c it fails closed on the checkout: a start file main lacks (untracked, ignored, or only in the checkout's index), or anything but a plain directory at an imported path main lacks, fails the walk, so the gate needs a fresh worktree (U2b)", NUL-safe listings, gaps list

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed shape, the `-z` listings and the gap list (r3); it does not establish the "doubled name" atom for a blob/tree doubled name (Claim 13b), or the future U2a3c, U2a4 and U2b behaviour.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "F11's checkout list leaves out A5's 'a link in link text' (Claim 8b) and so is accurate" · r2: "F11 omits the `..` after a checkout link, but its main list already names 'a `..` after a symlink'"; probes `untracked-start`, `index-only-start`, `ignored-rules`, `checkout-file-at-lacked`, `checkout-link-at-lacked` answer `failed`

The listings are `git ls-tree -r -z` (`scripts/lib/dev-cycle-read.sh:553`), `ls-files -z --others` (`:515`) and `ls-files -z --cached` (`:562`), each split on NUL by `nul_list`; the gap list matches A5 and the lib's not-covered list (`:466-469`) (r3; paraphrased — no quote available because r3 summarizes the gap-list comparison).

**Evidence:** `scripts/lib/dev-cycle-read.sh:515`, `scripts/lib/dev-cycle-read.sh:553-573`, `/tmp/u2a3-cfc2f-i2-aiLl/logs/suites.out`, `/tmp/u2a3-cfc2f-i2-x7bC/logs/probe.log`

---

## Claim 11a: plan U2a3 bullet: "started from main's instruction files and `.claude/rules/`. It refuses ... and fails closed on the checkout (a start file main lacks, or anything but a plain directory at an imported path main lacks)."

**Location:** `docs/working/plan-build-loop-handoff.md:276`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the bullet's description of the code (r1); it does not cover the U2a3c bullet (`:277`), which describes an unbuilt unit, nor (r3) the blob/tree doubled-name atom (Claim 13b).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: matches `:565-570` and `:608` · r3: "excludes the blob/tree doubled-name atom (Claim 13b)"

The evidence is the same as for Claims 9a and 10: the code lines cited there, the killed mutants and the isolated probes (r1; paraphrased — no quote available because r1 points to its other claims).

**Evidence:** `scripts/lib/dev-cycle-read.sh:553-608`, `/tmp/u2a3-cfc2f-i2-avmk/mutants.txt`, `/tmp/u2a3-cfc2f-i2-avmk/probes/mask.txt`

---

## Claim 11b: plan U2a3c bullet: "One drain loop run over two seedings ... every phase-2 item passes one admission check ... (U2a3 L2 architecture F1, F5)."

**Location:** `docs/working/plan-build-loop-handoff.md:277`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the U2a3c bullet's citation (r2); it does not verify U2a3c, which is not built.
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1: "U2a3c's design is not checkable" (`git branch --list 'feat/build-loop-u2a3*'` shows only u2a3, u2a3-src and u2a3b) · r3: cites `architecture-review-review-2026-10-06-L2-build-loop-u2a3.md:32` ("#### 1. The checks that admit checkout input sit at two separate inline sites ...") and `:122` ("#### 5. What phase 2 would share ...")

`architecture-review-review-2026-10-06-L2-build-loop-u2a3.md:150` (Finding 1: "every phase-2 item passes one admission predicate") and `:154` (Finding 5: "Build it as one drain loop over two seedings") are the cited sources (r2).

**Evidence:** `docs/reviews/architecture-review-review-2026-10-06-L2-build-loop-u2a3.md:150`, `docs/reviews/architecture-review-review-2026-10-06-L2-build-loop-u2a3.md:154`

---

## Claim 11c: plan U2b bullet: "a fresh worktree at MAIN_SHA, since until U2a3c the walk fails on any start file main lacks, ignored ones included, and on checkout content at paths main lacks"

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two failure causes named (r2); it does not establish that a fresh worktree is free of other failures (`@.git` fails in any linked worktree, Claim 8).
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Verified (compound)
**Replicate annotations:** r1: "Only an *imported* path main lacks is probed (`:605-608`)"; X4 shapes P4 untracked `notes.txt` and `other/readme.md` print `ok docs/a.md:imp`; "Precise version: 'anything but a plain directory at an imported path main lacks'" · r3: "U2b: X8 shows that an ignored start fails"

The start-file half is exact (`scripts/lib/dev-cycle-read.sh:570`; probe `ignored-rules`). "Checkout content at paths main lacks" is broader than the code: a plain directory there passes even when it holds files (`:608` first clause; probe `lacked-plain-dir`). Precise version: "anything but a plain directory at a path main lacks" (r2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:570`, `scripts/lib/dev-cycle-read.sh:605-608`, `/tmp/u2a3-cfc2f-i2-x7bC/logs/probe.log`, `/tmp/u2a3-cfc2f-i2-avmk/probes/shapes.txt`

---

## Claim 12: lib header, Inputs: "and so does main_imports (it reads the checkout only to fail, until U2a3c, so the gate needs a fresh worktree; the block above IMPORTED= lists each case; it needs resolve_main to have found main by name)"

**Location:** `scripts/lib/dev-cycle-read.sh:29-35`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every checkout read in `main_imports` (r1); it does not establish that the block comment lists the listing-failure causes; the return-1 comment does, in part (Claim 16).
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r2: "The block's list omits two runtime failures, the index listing and an unmodelled record type (Claim 16), and this verdict does not cover them"; across 22 probe states HEAD's `ok` import set equals main alone's · r3: "does not establish that the listings see every checkout file (nested repos, symlinked or unsearchable directories: A5 and override rows)"

"Reads the checkout only to fail" holds: the untracked and index listings (`:561-563`), `! -L "$p"` in the link-text loop (`:593`, which only sets `lk`) and the probe (`:608`) can only end in `return 1` or have no effect. "Needs resolve_main": `main_by_name || return 1` (`:552`). "Lists each case" is slightly short: the block (`:457-464`) does not name the failures of the checkout's listings themselves, `nul_list recs untracked_md || return 1` and the `--cached` listing's `|| return 1` (`:561-562`) (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:32-35`, `scripts/lib/dev-cycle-read.sh:457-464`, `scripts/lib/dev-cycle-read.sh:552-608`

---

## Claim 13a: block comment: "it starts at every instruction file stored there (and every .md under a .claude/rules/ directory at any depth ...) and follows an import into the file main stores at that path, whatever its name; a symlink there is followed to the path its text names. An imported path main lacks is recorded and not read."

**Location:** `scripts/lib/dev-cycle-read.sh:452-457`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers start selection (any-case `.md`, INSTRUCTION_FILE on the lower-cased basename, `.claude/rules/` at any depth), following into any name main stores, and record-without-read (r3); it does not establish starts under symlinked directories (not covered).
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=Verified
**Replicate annotations:** r1: "Recorded and not read: lines `:602` (`IMPORTED_MAIN+=...`) and `:605-608` (no queue push for a path main lacks)"

Start selection is `if [[ "${f##*/}" =~ $INSTRUCTION_FILE || "$f" == .claude/rules/*.md || "$f" == */.claude/rules/*.md ]]` (`scripts/lib/dev-cycle-read.sh:569`); the record step is `IMPORTED_MAIN+="$(lower "$p")"$'\n'` (`:602`); a path is queued only `if [[ -n "${ent[$p]+set}" ]]` (`:605`). Tests 3 and 6 pass (r3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:567-573`, `scripts/lib/dev-cycle-read.sh:600-609`, `/tmp/u2a3-cfc2f-i2-aiLl/logs/suites.out`

---

## Claim 13b: block comment "a doubled name ... fail[s] the walk" (also A5's "odd names", F11 `:126`, the U2a3 bullet `:276`, and override row `docs/reviews/override-log.md:379`: "A name main stores as both a blob and a tree fails the walk closed")

**Location:** `scripts/lib/dev-cycle-read.sh:457-458`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a root tree that lists `l` twice, as a symlink and as a tree, in both orders, walked in a fresh `git worktree add` checkout of main (r3); it does not establish what Claude Code loads beyond the kernel read of the imported path, or how such a tree could reach main in practice: it needs a non-canonical tree object (`git hash-object -t tree --literally`), which `git fsck` flags as `duplicateEntries`; git does not fsck incoming objects by default.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Incorrect
**Replicate annotations:** r1: test 5 sub-case 1 (`docs/a.md` listed twice, `:84-89`) "does pin the duplicate check" · r2: "The doubled-name part of test 5 is still pinned: `m-dup` fails test 5 through the first `docs/a.md` case at `:88`" · r3: "The walk did the same at cc1aa864 (same `:557` logic, unchanged by the split), so it is not a regression"; "a fail-open of low likelihood: it needs a crafted non-canonical tree object in main's history"; suggested fix: "refuse any `ls-tree -r` name that is also a proper prefix of another name"

The doubled-name check sees only full paths: `[[ -z "${ent[$f]+set}" && "$f" != *$'\n'* ]] || return 1` (`scripts/lib/dev-cycle-read.sh:557`). A name stored once as a blob and once as a tree is printed by `ls-tree -r` as two different paths (`l` and `l/x.md`), so the check never fires. Blob-first (what `git mktree` writes): the walk fails closed, and row 379 holds for this order. Tree-first (non-canonical; X4 P2): `main:l/x.md` resolves into the tree, a fresh worktree writes `l -> docs`, the kernel reads `l/x.md` as `evil @secret.md`, yet the walk answers `walk: ok l/x.md: imported docs/x.md: - docs/secret.md: -` (r3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:553-560`, `scripts/lib/dev-cycle-read.sh:579`, `scripts/lib/dev-cycle-read.sh:600-609`, `docs/reviews/override-log.md:379`, `/tmp/u2a3-cfc2f-i2-aiLl/logs/probes1.out`, `/tmp/u2a3-cfc2f-i2-aiLl/probes1.sh`

---

## Claim 13c: block comment refusal list (all but the doubled-name atom): "a name holding a newline, symlink text that is empty, absolute, leaves the repo, holds a newline or a NUL, or has a .. after a symlink (on main or in the checkout), an imported path main lacks that lies under a directory main stores as a symlink or gitlink, or that the checkout holds as anything but a plain directory (the root itself included), and a start file main lacks (untracked, ignored, or in the checkout's index) fail the walk ... A start file answers imported only when an import reaches it"

**Location:** `scripts/lib/dev-cycle-read.sh:457-466`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed behaviour at HEAD (r1); it does not establish that the suite pins the tree-name newline, link-text NUL and empty-text refusals (Claims 24, 26a, 28a), and does not cover the failing-sed/grep/lower cases, which are fixed in U2a3b (stacked).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: root case "`blocker . dir` prints `./`, because `realpath -e .` is `$ROOT_REAL`, not `$ROOT_REAL/.`"; failed states are the ones the comment names · r3: "does not establish the doubled-name atom (13b)"; X4 P1 (`@.`) gives `walk: failed`

Root included: X4 shapes P1 (`@.` and `@docs/..`) each print `failed`; "(on main or in the checkout)": the chklnk mutant (`! -L` dropped) fails test 15; start file main lacks: untrstart and index mutants killed; start answers imported only when reached: test 3's `CLAUDE.md -` (r1; paraphrased — no quote available because r1 summarizes probe and mutant outputs).

**Evidence:** `scripts/lib/dev-cycle-read.sh:102`, `scripts/lib/dev-cycle-read.sh:110-120`, `scripts/lib/dev-cycle-read.sh:567-573`, `scripts/lib/dev-cycle-read.sh:600-609`, `/tmp/u2a3-cfc2f-i2-avmk/probes/shapes.txt`, `/tmp/u2a3-cfc2f-i2-avmk/mutants.txt`

---

## Claim 13d: the fail-closed contract: "Checkout files are not walked until U2a3c, so the walk fails closed on them" (is there a state where the walk answers ok but misses an import that main alone, or the pre-split walk at cc1aa864, would catch?)

**Location:** `scripts/lib/dev-cycle-read.sh:464-465`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the diff from cc1aa864 to HEAD and the probed checkout shapes, and establishes no such state (r1); it does not cover the documented gaps (A5's not-covered list), checkout edits to files main stores (by design), git-environment bypasses (the U2b Defer row), or failing sed/grep/lower (U2a3b).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: "over 22 checkout states and 4 link states, no state answered `ok` while missing an import that main alone or cc1aa864 records"; "does not prove the invariant for every possible state" · r3: "no checkout state that answers ok while missing an import main alone or cc1aa864 would catch, beyond the documented and settled gaps"; the one fail-open r3 found is main-side, not a checkout state (Claim 13b)

The main side is unchanged apart from added refusals (`:607` gitlink parent, `:598` `*)` failing); every cc1aa864 path that read checkout content now fails; the new index listing only appends to `cand` (`[[ -n "${ent[$f]+set}" ]] || cand+=("t:$f")`, `scripts/lib/dev-cycle-read.sh:563`) (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:546-611`, `/tmp/u2a3-cfc2f-i2-avmk/probes/shapes.txt`, `/tmp/u2a3-cfc2f-i2-avmk/probes/dotgit.txt`, `/tmp/u2a3-cfc2f-i2-x7bC/logs/probe.log`

---

## Claim 13e: block comment: "Not covered (known issue A5): start files under a symlinked directory or in a submodule or untracked nested repo, other names one file has on a case-insensitive checkout, absolute imports, and three shapes A5 lists as untraced against Claude Code."

**Location:** `scripts/lib/dev-cycle-read.sh:466-469`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the start-file answer (test 3: `CLAUDE.md -`) and the nested-repo gap (probe) (r2); it does not trace Claude Code's own behavior.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** r1 (Claim 9, F11): "The gaps list matches the lib's 'Not covered' sentence (`:466-469`)" · r3: "The list matches A5's 'Not covered' list item for item"

`:571` seeds `seen` and the queue but never writes a start into `IMPORTED_MAIN`; only `:602` writes. `import_targets` drops absolute paths (`scripts/lib/dev-cycle-read.sh:500` `"$t" != /*`). A5 lists exactly three untraced shapes (r2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:500`, `scripts/lib/dev-cycle-read.sh:571`, `scripts/lib/dev-cycle-read.sh:602`, `test/scripts/build-loop-check.bats:58`, `/tmp/u2a3-cfc2f-i2-x7bC/logs/probe.log`

---

## Claim 14: "IMPORTED_MAIN reads "error" until a walk succeeds; the result is cached for the commit, MAIN_BY_NAME and root in IMPORTED_MAIN_DONE, so a caller whose checkout changes between calls sets IMPORTED_MAIN_DONE="" to walk again."

**Location:** `scripts/lib/dev-cycle-read.sh:470-472`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cache key and the failed-walk reuse (r1); it does not establish IMPORTED_MAIN's value mid-walk: it is set to `$'\n'` at :574, before the queue drains (settled by override row B10).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none beyond the shared mid-walk-value caveat (r1+r2+r3: the transient `$'\n'` at `:574` is covered by the settled errexit row)

`[[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }` then `IMPORTED_MAIN=error; IMPORTED_MAIN_DONE="$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"` (`scripts/lib/dev-cycle-read.sh:550-551`). Every `return 1` after :574 sets `IMPORTED_MAIN=error` first. Test 16 passes (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:550-610`, `test/scripts/build-loop-check.bats:306-315`, `/tmp/u2a3-cfc2f-i2-avmk/bats-five.txt`

---

## Claim 15: "nul_list NAME CMD...: array NAME gets CMD's NUL-split output, or is emptied and 1 unless CMD exited 0 and its output ended in NUL."

**Location:** `scripts/lib/dev-cycle-read.sh:516`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers nul_list's return value and array contents for empty, unterminated, terminated, failing and forged-tail output (r1); it does not establish that any test pins the emptying (the nlemptyarr mutant survives).
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2: "does not cover a CMD whose own stdout contains the literal `rc=0` as its last field (not probed)"; "Every caller treats an empty listing as valid, so nothing is misread" · r3: "does not establish behaviour for a CMD killed by a signal mid-write"

r1's probe printed `empty-output rc=0 n=0`, `no-trailing-NUL rc=1 n=0`, `trailing-NUL rc=0 n=2 [a b]`, `fail rc=1 n=0`, `forged-tail rc=1 n=0 []`. Empty output from a successful command returns 0 though it did not "end in NUL". Precise version: "unless CMD exited 0 and its output was empty or ended in NUL".

**Evidence:** `scripts/lib/dev-cycle-read.sh:517`, `/tmp/u2a3-cfc2f-i2-avmk/probes/nul_list.txt`, `/tmp/u2a3-cfc2f-i2-avmk/m-nlemptyarr.out`

---

## Claim 16: return-1 comment lists every cause: "when main is not found by name, the commit's tree or the untracked list cannot be listed whole (nul_list), a tree record does not parse, a name is listed twice ... or holds a newline, the lower-cased start list comes back short, a start file main lacks exists, a blob cannot be read, symlink text ... or an imported path main lacks lies under a directory main stores as a symlink or gitlink or exists in the checkout as anything but a plain directory below the root; need_root exits instead"

**Location:** `scripts/lib/dev-cycle-read.sh:536-545`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each `return 1` in `main_imports` (:546-611, read whole) against the list (r1); it does not establish behaviour when sed, grep or lower fail (fixed in U2a3b, stacked).
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2: "does not establish that the two omitted paths are reachable through normal git"; "In practice a broken index fails `:561` first"; raw modes 644 and 0 list as `160000 commit` · r3: "'a start file main lacks exists' is also loose. X4 P4 fails on an index entry whose file was deleted from the work tree ... The precise wording is 'is listed (untracked, ignored or in the index)'"

Two code paths are not named: the index listing, `nul_list recs env GIT_LITERAL_PATHSPECS=0 git ls-files -z --cached -- ':(glob,icase)**/*.md' || return 1` (`scripts/lib/dev-cycle-read.sh:562`), and the unmodelled record type, `*) IMPORTED_MAIN=error; return 1 ;;` (`:598`). The second is not reachable through `git ls-tree`: a tree written with mode 100664 is listed as `100644` (r1 X4 oddmode probes). Precise version: add "the checkout's index cannot be listed whole" and "a tree record has a type it does not model".

**Evidence:** `scripts/lib/dev-cycle-read.sh:536-545`, `scripts/lib/dev-cycle-read.sh:552-608`, `/tmp/u2a3-cfc2f-i2-avmk/probes/oddmode.txt`, `/tmp/u2a3-cfc2f-i2-avmk/probes/oddmode2.txt`, `/tmp/u2a3-cfc2f-i2-aiLl/logs/probes1.out`

---

## Claim 17: index listing: start files the checkout's index tracks but main lacks fail the walk

**Location:** `scripts/lib/dev-cycle-read.sh:561-570`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers index-only starts: staged, staged then deleted from the working tree, skip-worktree, and a checkout on another branch (r2); it does not cover GIT_INDEX_FILE, which the U2b row defers.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not establish a differently cased duplicate of a path main stores on a case-insensitive filesystem (A5)"; X4 P4b: "a non-start `notes.md` staged in the index leaves the walk ok, so only start-shaped names fail"

`:563` `[[ -n "${ent[$f]+set}" ]] || cand+=("t:$f")` and `:570` `[[ "${cand[i]:0:1}" == m ]] || return 1` (`scripts/lib/dev-cycle-read.sh`). Probes `index-only-start`, `index-only-start-wt-deleted`, `index-only-skip-worktree` and `on-other-branch-with-new-start` answer `failed` on HEAD and `ok` on cc1aa864 without the start's import; `m-index` fails test 3 (r2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:561-570`, `/tmp/u2a3-cfc2f-i2-x7bC/logs/probe.log`, `/tmp/u2a3-cfc2f-i2-x7bC/m-index.out`

---

## Claim 18: link-text comments and split: "$(...) drops NULs, so they are counted first; the x keeps trailing newlines ..." / "realpath -s reads x/.. as nothing, but the kernel follows a symlink x first: a .. after a symlink on main or in the checkout fails." with `mapfile -t -d / parts < <(printf '%s' "$out")`

**Location:** `scripts/lib/dev-cycle-read.sh:581-596`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a `..` after a link on main or in the checkout and link text past 64 KiB (r2); it does not establish that a checkout link without a following `..` fails (it does not: Claim 9c).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish how Claude Code resolves a `..` in an `@` token (A5 lists that as untraced)"; dotdot fails tests 10 and 15, chklnk fails 15; "`mapfile -t -d /` splits like the old `IFS=/ read -ra` for text without a newline" · r3: NUL counting `tr -cd '\0' | wc -c` (`:583`) and trailing-newline `printf x` (`:584-585`) comments checked; h-parentimm and 2b-splitnone killed by 15

Test 15 passes; the here-string revert fails test 10; probe2 case B (`ld/../docs/n.md` with a checkout link `ld`) answers `failed` (r2; paraphrased — no quote available because r2 summarizes test and probe outcomes).

**Evidence:** `scripts/lib/dev-cycle-read.sh:587-596`, `/tmp/u2a3-cfc2f-i2-x7bC/m-herestr.out`, `/tmp/u2a3-cfc2f-i2-x7bC/logs/probe2.log`, `/tmp/u2a3-cfc2f-i2-avmk/mutants.txt`

---

## Claim 19: `160000) continue ;;  # a gitlink: its files are not main's` / `*) IMPORTED_MAIN=error; return 1 ;;`

**Location:** `scripts/lib/dev-cycle-read.sh:597-598`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the arms' behaviour: a gitlink start reads nothing with walk ok, and any other type fails (r3); it does not establish test coverage: no test reaches either arm (h-gitlinkcont and h-starrm both survive), and `*)` is unreachable through `ls-tree -r`'s canonical modes.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: the starcont mutant (`*)` → `continue`) survives; "A path under it fails through `:607` (the gitlinkpar mutant fails test 12)" · r2: "the `*) continue` revert mutant (`m-gitcont`) passes 16/16"

X4 P6 (gitlink stored as `CLAUDE.md`) gives `walk: ok CLAUDE.md: imported y.sh: -` (r3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:578-599`, `/tmp/u2a3-cfc2f-i2-aiLl/logs/probes1.out`, `/tmp/u2a3-cfc2f-i2-aiLl/logs/mut-h-gitlinkcont.out`, `/tmp/u2a3-cfc2f-i2-aiLl/logs/mut-h-starrm.out`, `/tmp/u2a3-cfc2f-i2-x7bC/m-gitcont.out`, `/tmp/u2a3-cfc2f-i2-avmk/m-starcont.out`

---

## Claim 20: "Main lacks p: under a link or gitlink main stores, or in the checkout as anything but a plain directory, fail." with the `${c%/*}` loop and `^1[26]0000$`

**Location:** `scripts/lib/dev-cycle-read.sh:606-608`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every proper ancestor of `p`, for modes 120000 and 160000, and the probe (r1); it does not establish behaviour under an unsearchable checkout directory: it reads as absent, per the C3 Defer row.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish the cost, which the O(L x depth) row covers" · r3: "does not establish the root case's wording here: the root is a plain directory but fails, as the block comment says (`:462`)"

The loop `c="$p"; while [[ "$c" == */* ]]; do c="${c%/*}"; ...` visits every prefix before a `/`; `^1[26]0000$` matches exactly 120000 and 160000. Mutants parent1 (test 15), gitlinkpar (12), probe (3, 9, 12) and plaindir (9) are killed (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:600-609`, `/tmp/u2a3-cfc2f-i2-avmk/mutants.txt`

---

## Claim 21: isimported: "A failed main walk, or a walk name that is neither, answers imported (0), so a caller testing it with `if` refuses; a caller that words a failed walk runs main_imports first. Run it in the caller's shell: the walk exits through need_root and caches its result."

**Location:** `scripts/lib/dev-cycle-read.sh:612-616`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `main`, `tree` and default arms (r1); it does not establish errexit behaviour inside `main_imports` when called under `||` (settled override row).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not re-verify the `tree` arm (U2a2's)"; passes "under `set -eu` without pipefail" · r3: "does not establish a failing `lower` (fixed in U2a3b)"

The arm reads `main) main_imports || return 0; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]] ;;` and the default is `*) return 0 ;;` (`scripts/lib/dev-cycle-read.sh:622-624`). Tests 2, 8 and 14 pass (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:617-626`, `/tmp/u2a3-cfc2f-i2-avmk/bats-five.txt`

---

## Claim 22: test 3 name "main's instruction files start it; a working-tree edit does not count; an untracked start or a checkout file at a path main lacks fails it until U2a3c"

**Location:** `test/scripts/build-loop-check.bats:46-62`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the name's claims and the index-only line at `:61`, which the name does not mention (r2); it does not establish that each failure is isolated, since `:59` and `:60` could each also be caught by the other check. The `m-index` mutant pins `:61`.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: "does not cover ignored starts (not in this test; X5 covers them)"; index, untrstart and probe mutants each fail test 3

Body: `:59` docs/new.md file gives `walk failed`, `:60` untracked CLAUDE.local.md gives `walk failed`, and `:61` `git add -f` gives `walk failed`. Test 3 passes, and `m-index` fails it (r2).

**Evidence:** `test/scripts/build-loop-check.bats:46-62`, `/tmp/u2a3-cfc2f-i2-x7bC/m-index.out`

---

## Claim 23: remaining U2a3 test names (tests 4, 6, 8, 11, 13, 14, 15, 16) assert what they say

**Location:** `test/scripts/build-loop-check.bats:64`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers tests at :64, :115, :163, :229, :260, :271, :281 and :306 (r1); it does not establish that each named sub-shape is the cause of its failure, except where a mutant isolates it: untrstart for test 11; parent1 and chklnk for test 15.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: Confidence Medium; "Mutation was not run for each named check" · r3: "does not establish ... test 15's '.. after a plain directory' through `ld/../evil.md`. There `ld` is absent on main and in the checkout, so `AGENTS.md -> docs/../docs/n.md` is the case that exercises it"

All pass. In these tests the index holds only files that the rewritten main also stores, or main is not rewritten, so the index-only masking of Claims 24, 26a and 28a does not apply (r1; paraphrased — no quote available because r1 summarizes eight test bodies).

**Evidence:** `test/scripts/build-loop-check.bats:64-80`, `test/scripts/build-loop-check.bats:115-137`, `test/scripts/build-loop-check.bats:163-173`, `test/scripts/build-loop-check.bats:229-315`, `/tmp/u2a3-cfc2f-i2-avmk/bats-five.txt`

---

## Claim 24: test 5 comments: "A start file listed twice (a symlink first, which git reads), and a plain file listed twice: each fails the walk rather than reading one copy." / "A name holding a newline is not modelled, so it fails the walk: a plain one, and one shaped so each half looks like an ls-tree record"

**Location:** `test/scripts/build-loop-check.bats:91-113`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether these sub-cases test the refusal they name (r1): each passes for an unrelated reason. Sub-case 1 (`docs/a.md` listed twice, :84-89) is unaffected and does pin the duplicate check; the lib's refusals themselves are correct.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect (compound) · r3=Verified (compound)
**Replicate annotations:** r2: "The same mutants on 2b22a082's tree fail tests 5, 9 and 12 respectively. Combining each with `m-index` ... makes them fail tests 5, 9 and 12 again at HEAD, which confirms the index check is the mask"; "HEAD's code does refuse all three shapes ... so this verdict says nothing against the lib"

Since dfeeb85d added the index listing (`scripts/lib/dev-cycle-read.sh:562-563`), the checkout index in this test still holds `CLAUDE.md` from `commit_all claude` (:84). The rewritten main trees at :94, :97 and :108 lack it, so every one of those walks fails at `[[ "${cand[i]:0:1}" == m ]] || return 1` (:570) before the shape is reached. The treenl mutant (newline half of :557 dropped) survives the suite, 16/16; in isolation HEAD prints `failed` and treenl prints `ok docs/d.md imported`; the dup mutant prints `index-as-test: failed | index=main: ok` (r1).

**Evidence:** `test/scripts/build-loop-check.bats:82-113`, `scripts/lib/dev-cycle-read.sh:557`, `scripts/lib/dev-cycle-read.sh:562-570`, `/tmp/u2a3-cfc2f-i2-avmk/m-treenl.out`, `/tmp/u2a3-cfc2f-i2-avmk/probes/treenl.txt`, `/tmp/u2a3-cfc2f-i2-avmk/probes/mask.txt`, `/tmp/u2a3-cfc2f-i2-x7bC/c-treenl.out`

---

## Claim 25a: test 7 comment: "An untracked name holding a newline fails the walk." (fixture `zz<LF>CLAUDE.md`)

**Location:** `test/scripts/build-loop-check.bats:147-151`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listing newline check at `:563` (r2); it does not cover the tree-name newline check (Claim 24).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: "In this test's loop the checkout index holds `AGENTS.md` and `..x.md`, so no index-only start masks it"

The `m-newline` mutant (check removed from `:563`) fails test 7 only. The fixture is not start-shaped: `${f##*/}` keeps `zz<LF>` and INSTRUCTION_FILE is anchored, so only `:563` refuses it (r2; paraphrased — no quote available because r2 summarizes mutant output).

**Evidence:** `scripts/lib/dev-cycle-read.sh:563`, `scripts/lib/dev-cycle-read.sh:569`, `/tmp/u2a3-cfc2f-i2-x7bC/m-newline.out`

---

## Claim 25b: test 7 comment: "Symlink text with a trailing newline, an absolute one, none, or one leaving the repo: the walk fails."

**Location:** `test/scripts/build-loop-check.bats:153`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the asserted outcomes (r1); it does not establish which check fails the `''` (none) case.
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=Verified (compound)
**Replicate annotations:** r1: "The `''` text case at the top level fails even under the emptytext mutant, through the root probe (`@` text \"\" resolves to `.`). So the empty check is pinned nowhere (Claim 26)"

Test 7 passes in r1's X1 with these assertions; the empty-text case's cause is the root probe, not `:586` (r1; paraphrased — no quote available because r1 summarizes mutant output).

**Evidence:** `test/scripts/build-loop-check.bats:139-161`, `/tmp/u2a3-cfc2f-i2-avmk/m-untrnl.out`, `/tmp/u2a3-cfc2f-i2-avmk/m-emptytext.out`

---

## Claim 26a: test 9 NUL part: name "main walk fails on symlink text holding a NUL ..." and comment "Symlink text holding a NUL: $(...) would drop it and follow another name."

**Location:** `test/scripts/build-loop-check.bats:196-200`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the NUL sub-case only (r1); the test's other sub-cases (parent link, checkout symlink, untracked and unreadable starts, plain directory) are pinned (probe and plaindir fail test 9, untrstart fails 9).
**Replicate verdicts:** r1=Incorrect · r2=Incorrect (compound) · r3=Mostly accurate (compound)
**Replicate annotations:** r2: `m-nul` passes 16/16 at HEAD, fails test 9 on 2b22a082's tree, and fails 3+9 combined with `m-index`; probe3 `m-nul` answers `ok: docs/rules.mdzzz` · r3 (Claim 18): "NUL counting ... test 9 covers it"

The new main tree at :198 (`AGENTS.md` link + `docs-rules.md`) lacks `CLAUDE.md`, which the checkout index still tracks from :179, so the walk fails at lib :570 before the link arm runs. The nulcount mutant (lib :583 `|| [[ "$i" -ne 0 ]]` dropped) survives the suite; in `mask.txt` it prints `index-as-test: failed | index=main: ok docs/rules.md:-`, and HEAD prints `failed` in both columns (r1).

**Evidence:** `test/scripts/build-loop-check.bats:175-201`, `scripts/lib/dev-cycle-read.sh:583-584`, `/tmp/u2a3-cfc2f-i2-avmk/m-nulcount.out`, `/tmp/u2a3-cfc2f-i2-avmk/probes/mask.txt`, `/tmp/u2a3-cfc2f-i2-x7bC/m-nul.out`

---

## Claim 26b: test 9 name, other part: "... on a checkout symlink or file at a path main lacks, and on an untracked start"

**Location:** `test/scripts/build-loop-check.bats:175`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the body sets up (r2); the NUL part's pinning is Claim 26a.
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=Mostly accurate (compound)
**Replicate annotations:** r1 (Claim 25 Scope): the checkout-symlink, untracked and unreadable start and plain-directory sub-cases "are pinned" · r3: "The h-fileok mutant, which lets a plain file pass there, is killed by test 3 only, and test 9 passes under it"

The body has a checkout symlink at a path main lacks (`:186` `ln -s rules.md docs/lt.md`), untracked starts (`:188`, `:191`) and a plain directory that passes (`:194`). It has no regular checkout file at an imported path main lacks; that case is in test 3 (`:59`). Either "or file" should go, or test 9 should add one (r2).

**Evidence:** `test/scripts/build-loop-check.bats:175-201`, `test/scripts/build-loop-check.bats:59`, `/tmp/u2a3-cfc2f-i2-aiLl/logs/mut-h-fileok.out`

---

## Claim 27a: test 10 name: "returns, not exits, when main's tree or the untracked list cannot be listed ...; reads a list past 64 KiB under ulimit -f 0"

**Location:** `test/scripts/build-loop-check.bats:203`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed cases (r1); the index listing's own failure (lib :562) has no separate case; a corrupt index fails the untracked listing first.
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=Verified (compound)
**Replicate annotations:** none

The `[ "$status" -eq 0 ]` checks pin "returns, not exits"; lowshort fails test 10 (the tr case) (r1; paraphrased — no quote available because r1 summarizes mutant output).

**Evidence:** `test/scripts/build-loop-check.bats:203-227`, `/tmp/u2a3-cfc2f-i2-avmk/mutants.txt`

---

## Claim 27b: test 10 comment: "Link text past 64 KiB with a .. after main's link l, under ulimit -f 0: the .. check reads it whole (loop 1 C4; XFSZ ignored, so a failed temp write returns, as a full disk does)."

**Location:** `test/scripts/build-loop-check.bats:222-226`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the size and that the case pins the split (r2); it does not establish behavior with default XFSZ handling (the shell would be killed, which the comment does not claim).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: herestring and dotdot each fail test 10; "The link case calls `git read-tree main` and `rm -r docs` first (:224), so the index check cannot mask it"

The text is 270 x 254 + 9 = 68,589 bytes (67 KiB), and `l` is a 120000 link on main. `git read-tree main` at `:224` isolates the case from the index check. The `m-herestr` mutant fails test 10 (r2; paraphrased — no quote available because r2 summarizes the fixture arithmetic).

**Evidence:** `test/scripts/build-loop-check.bats:222-226`, `/tmp/u2a3-cfc2f-i2-x7bC/m-herestr.out`

---

## Claim 28a: test 12 empty-text part: name "... empty link text below the top level ..." and comment "Empty symlink text in sub/ would name sub/ itself, a plain directory here."

**Location:** `test/scripts/build-loop-check.bats:250-254`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the empty-text sub-case only (r1); the dangling-link, link-directory and gitlink sub-cases are pinned (probe and gitlinkpar fail test 12).
**Replicate verdicts:** r1=Incorrect · r2=Incorrect (compound) · r3=Verified (compound)
**Replicate annotations:** r2: `m-empty` passes 16/16 at HEAD, fails test 12 on 2b22a082's tree, and fails 3+12 combined with `m-index`; probe3 `m-empty` answers `ok: sub` · r3 (Claim 23b): "Test 12's 'Empty symlink text in sub/' fails at `-z \"$out\"` (`:586`)"

The tree at :253 holds only `sub/AGENTS.md`, while the checkout index tracks `CLAUDE.md` (:243), so the walk fails at lib :570. The emptytext mutant survives; `mask.txt` shows `emptytext emptylink index-as-test: failed | index=main: ok docs/x.md:-` against HEAD's `failed` in both columns. With Claim 25b, the empty-text refusal (lib :586) is pinned by no test (r1).

**Evidence:** `test/scripts/build-loop-check.bats:240-258`, `scripts/lib/dev-cycle-read.sh:586`, `/tmp/u2a3-cfc2f-i2-avmk/m-emptytext.out`, `/tmp/u2a3-cfc2f-i2-avmk/probes/mask.txt`, `/tmp/u2a3-cfc2f-i2-x7bC/m-empty.out`

---

## Claim 28b: test 12 other parts (dangling link, link directory, gitlink parent)

**Location:** `test/scripts/build-loop-check.bats:240`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each name's listed cases against its `want` lines and the mutant kills (r3, compound over tests 3-8 and 10-16); it does not establish coverage of `160000) continue` or `*)`.
**Replicate verdicts:** r1=— · r2=— · r3=Verified (compound) · single-replicate detection
**Replicate annotations:** r1 (Claim 26 Scope): "The dangling-link, link-directory and gitlink sub-cases are pinned (probe and gitlinkpar fail test 12)" · r2 (Claim 27): "Test 12's gitlink case keeps `CLAUDE.md` on main, so the index check does not mask it"

Every named case has a matching assertion and all 16 tests pass; h-gitlink is killed by test 12 and h-probe by 3, 9 and 12 (r3; paraphrased — no quote available because r3 summarizes its mutant table).

**Evidence:** `test/scripts/build-loop-check.bats:240-258`, `/tmp/u2a3-cfc2f-i2-aiLl/logs/mutants.summary`

---

## Claim 29: dev-cycle.bats "sourcing the reader lib defines its functions and calls neither git nor perl" (list extended with `main_imports`, `nul_list`, `IMPORTED_MAIN`, `IMPORTED_MAIN_DONE`)

**Location:** `test/scripts/dev-cycle.bats:1077-1094`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the names are defined at source time (r1); it does not establish their behaviour.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not cover the test's 'calls neither git nor perl' half beyond its passing" · r3: "does not establish that the inventory is exhaustive"

The test passes; `nul_list` is defined at lib :517 and the variables at :474 (r1; paraphrased — no quote available because r1 cites definitions by line).

**Evidence:** `test/scripts/dev-cycle.bats:1077-1094`, `scripts/lib/dev-cycle-read.sh:474`, `/tmp/u2a3-cfc2f-i2-avmk/bats-five.txt`

---

## Claim 30a: commit 2b22a082 figures: "build-loop-check.bats 16; 114 across the five suites. ... 392 changed code lines against main."

**Location:** commit 2b22a082 (body, Tests paragraph)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at 2b22a082, with the five suites read as dev-cycle, build-loop-read, build-loop-check, fixture-git-env and fixture-hermeticity (r3); it does not establish other suite lists.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: X2 "Exit 1 with 113 ok. The one failure is build-loop-read test 79, which reads the repo's own `docs/dev-cycle.md`, and the archive left out `docs/`"; 19/19 after `docs/` was extracted

X2 gives 1..114, all ok, with build-loop-check at 16. X9 gives `2b22a082: 379+13=392` (r3).

**Evidence:** `/tmp/u2a3-cfc2f-i2-aiLl/logs/suites-2b.out`, `/tmp/u2a3-cfc2f-i2-aiLl/logs/numstat.out`, `test/scripts/build-loop-check.bats:46`

---

## Claim 30b: commit 2b22a082: "Mutants of the untracked-start refusal, the checkout probe, the gitlink match, the parent loop (immediate parent only), the plain-directory allowance and the link-text split each fail."

**Location:** commit 2b22a082 (body, Tests paragraph)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the six mutant families at 2b22a082 (r3); it does not establish the commit author's exact mutant constructions.
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=Mostly accurate
**Replicate annotations:** r1: "The six named mutants were run at HEAD, where these lines are unchanged from 2b22a082"; r1 used dotdot for the link-text split · r2 (Claim 32 Scope): "That pass found the here-string revert survived at 2b22a082, and dfeeb85d pinned it"

Five families are killed at 2b22a082: untstart (3, 9, 11), probe (3, 9, 12), gitlink (12), parentimm (15) and plaindir (9). For the link-text split, dropping the split (`parts=()`) is killed by 15, but reverting C4's own fix to the here-string (`IFS=/ read -ra parts <<<"$out"`) survives all 16; that mutant was not pinned until dfeeb85d (r3).

**Evidence:** `/tmp/u2a3-cfc2f-i2-aiLl/logs/mut-2b-linksplit.out`, `/tmp/u2a3-cfc2f-i2-aiLl/logs/mut-2b-splitnone.out`, `/tmp/u2a3-cfc2f-i2-aiLl/logs/mutants.summary`, `scripts/lib/dev-cycle-read.sh:589`

---

## Claim 30c: commit 2b22a082 behavioral claims: "C2 fixed ..."; "C4 fixed: ... (no here-string left in main_imports)"; "C8: the parent loop steps over "/" (was O(L^2))"; "C10: nul_list empties its array on failure"; "the untracked parts of the "follows", cycle and .MD tests move to U2a3c; new cases for a gitlink parent and a checkout file at a path main lacks"

**Location:** commit 2b22a082 (body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named change against the 2b22a082 tree and the test-name diff from 0170f16a (r3); its headline and D13 sentence are covered by override row `docs/reviews/override-log.md:388` (Accepted-immutable) and only pointed to.
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none

The 0170f16a to 2b22a082 test-name diff drops "the checkout's files" from test 6, "tracked or untracked" from test 11 and the "untracked file" cycle from test 13, and adds "a path under a gitlink" (test 12) and "a checkout file at a path main lacks" (test 3). `grep '<<<'` over 2b22a082's `main_imports` finds none (r3; paraphrased — no quote available because the claim covers absence of code).

**Evidence:** `/tmp/u2a3-cfc2f-i2-aiLl/lib-2b.sh`, `/tmp/u2a3-cfc2f-i2-aiLl/logs/mutants.summary`, `scripts/lib/dev-cycle-read.sh:607`

---

## Claim 31a: commit dfeeb85d E1-E4, E6: "The walk now also lists the checkout's tracked .md files; a start-shaped one main lacks fails the walk, as an untracked or ignored one does. Until U2a3c the gate therefore needs a fresh worktree (E2): header, A5, F11 and the U2b bullet say so." / "a gitlink continues and any other type fails the walk" / "dev-cycle.bats lists nul_list" / "the plan's U2a3c bullet carries architecture F1 and F5"

**Location:** commit dfeeb85d (body)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these bullets (r2); E5 is Claims 31b, 31d and 31e. "E7-E10: override rows": the rows exist (`override-log.md:386-389`), but they landed in 0032ed5a, not in this commit, and the message does not say otherwise.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: X4 P5 and test 3 fail for an index-only start · r3: "The fresh-worktree sentence appears at `:32-33` in the header, in A5, in F11 and at `:279` in U2b"

See Claims 17, 12, 9d, 10, 11c, 19, 29 and 11b for the per-item evidence (r2; paraphrased — no quote available because r2 points to its other claims).

**Evidence:** `scripts/lib/dev-cycle-read.sh:32-34`, `scripts/lib/dev-cycle-read.sh:561-570`, `scripts/lib/dev-cycle-read.sh:597-598`, `docs/working/plan-build-loop-handoff.md:277`, `test/scripts/dev-cycle.bats:1086`

---

## Claim 31b: commit dfeeb85d E5: "a 67 KB link under ulimit -f 0 with XFSZ ignored pins the link-text split (isolated from the new index check)"

**Location:** commit dfeeb85d (body, E5)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the item against the 0032ed5a to dfeeb85d diff and the HEAD runs (r3, compound with E1-E4 and E6); it excludes the test-rename and "start name" phrases (Claims 31d, 31e).
**Replicate verdicts:** r1=— · r2=— · r3=Verified (compound) · single-replicate detection
**Replicate annotations:** r2 (Claim 23): "The fix the commit itself used for the new link case is `rm -r docs; git read-tree main` at `:224`. Only that one case got it."

h-linksplit is killed by test 10 (r3 Claim 3a; paraphrased — no quote available because r3 points to its mutant table).

**Evidence:** `test/scripts/build-loop-check.bats:222-226`, `/tmp/u2a3-cfc2f-i2-aiLl/logs/mutants.summary`

---

## Claim 31c: commit dfeeb85d figures: "Tests: build-loop-check.bats 16; 114 across the five suites. Mutants of the index listing, the link-text split (here-string revert) and the newline check each fail. 400 changed code lines against main."

**Location:** commit dfeeb85d (body, Tests paragraph)
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts, the line total and r2's constructions of the three mutants; it does not establish that the other shape checks stay pinned after this commit (Claims 24, 26a, 28a).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "HEAD's code and tests equal dfeeb85d's, because 1898d21c touches only `docs/reviews/`"

`grep -c '^@test'` over the five suites at dfeeb85d gives 114, and 16 for build-loop-check. `git diff --numstat main...dfeeb85d -- . ':!docs'` gives 113+9, 272+2 and 2+2, a total of 400 (the same at HEAD). Mutants: `m-index` fails 3, `m-herestr` fails 10, `m-newline` fails 7 (r2).

**Evidence:** `/tmp/u2a3-cfc2f-i2-x7bC/logs/five.log`, `/tmp/u2a3-cfc2f-i2-x7bC/m-index.out`, `/tmp/u2a3-cfc2f-i2-x7bC/m-herestr.out`, `/tmp/u2a3-cfc2f-i2-x7bC/m-newline.out`, `test/scripts/build-loop-check.bats:46`

---

## Claim 31d: commit dfeeb85d E5: "test 7's newline fixture is a start name"

**Location:** commit dfeeb85d (body, E5)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers how the lib classifies `zz<LF>CLAUDE.md` (r1); it does not affect the test's value: the fixture pins the newline check because it is *not* a start.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Mostly accurate
**Replicate annotations:** r2: test-strategy L2 G1 already said "That name is not a start" (`docs/reviews/test-strategy-review-2026-10-06-L2-build-loop-u2a3.md:29`); "This message is immutable, so an Accepted-immutable row is the route" · r3: "The fixture's second line is a start name. The whole name, though, is not start-shaped to the code"; precise version "a name whose part after the newline is a start name"

The lib tests `"${f##*/}" =~ $INSTRUCTION_FILE` (`scripts/lib/dev-cycle-read.sh:569`). `${f##*/}` of `zz<LF>claude.md` is the whole name, and the `^`-anchored regex does not match it; in bash 5.2.15 `[[ $'zz\nclaude.md' =~ $INSTRUCTION_FILE ]]` prints `nomatch`. Under the untrnl mutant the walk is `ok`. A start name would have failed at :570 regardless (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:442`, `scripts/lib/dev-cycle-read.sh:567-570`, `/tmp/u2a3-cfc2f-i2-avmk/m-untrnl.out`

---

## Claim 31e: commit dfeeb85d E5: "tests 9 and 3 renamed for the split"

**Location:** commit dfeeb85d (body, E5)
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the `@test` lines changed by dfeeb85d (r2); it does not concern test 3's body, which dfeeb85d extended (`:61`).
**Replicate verdicts:** r1=Mostly accurate · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r1: "Test 3 gained an assertion (:61), but its name is unchanged since 2b22a082" · r3: executed diff of `@test` lines 0032ed5a vs dfeeb85d, one changed line `9c9`; "Test 3's name ... was renamed in 2b22a082"; "does not establish what the author meant by '3'"; Accepted-immutable row expected

`git diff 2b22a082 dfeeb85d -- test/scripts/build-loop-check.bats` changes one `@test` line, test 9's. Test 3's name is the same at 5c57d367 and dfeeb85d (r2; paraphrased — no quote available because the claim is about which lines a diff touches).

**Evidence:** `test/scripts/build-loop-check.bats:46`, `test/scripts/build-loop-check.bats:61`, `test/scripts/build-loop-check.bats:175`, `/tmp/u2a3-cfc2f-i2-aiLl/logs/testnames.out`

---

## Claim 32: docs(reviews) commits 5c57d367, 0032ed5a, 1898d21c: "fix-drift output ... (no findings)" / "fact-check, critic reports, rubric and override rows"

**Location:** commit 1898d21c (and 5c57d367, 0032ed5a)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each commit's file list against its message (r1); it does not re-verdict the reports' contents.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not re-run the fix-drift reviewer" · r3: the rubric's "33 claims: 20 Verified, 11 Mostly accurate, 1 Stale, 0 Incorrect, 1 Unverifiable" matches the L2 report's Summary line

1898d21c adds `lite-review-fix-drift-build-loop-u2a3-L2i1.txt`, which reads `lite-review [fix-drift]: FINDINGS: NONE (14544 out-tokens)`. 0032ed5a adds the L2 fact-check, five critic reports, 29 rubric lines and 4 override rows. 5c57d367 adds `lite-review-fix-drift-build-loop-u2a3-split.txt` (r1; paraphrased — no quote available because the claim is about commit file lists).

**Evidence:** `docs/reviews/lite-review-fix-drift-build-loop-u2a3-L2i1.txt:1`, `docs/reviews/lite-review-fix-drift-build-loop-u2a3-split.txt:1`

---

## Claims Requiring Attention

### Incorrect
- **Claim 9c** (`docs/working/known-issues-dev-cycle.md:18`): A5's "a link in link text ... fails the walk" is too broad; only a `..` after a checkout link (or a checkout link at or above an imported path main lacks) fails. Reword to match the lib comment. (r2+r3 Incorrect, r1 Mostly accurate.)
- **Claim 13b** (`scripts/lib/dev-cycle-read.sh:457-458`, `:557`; also A5, F11 `:126`, U2a3 bullet `:276`, `override-log.md:379`): a non-canonical tree listing a name as a tree before a symlink makes the walk answer ok while a fresh worktree loads an import it never records. Not a regression vs cc1aa864. (r3 only; r1/r2 compound Verified.)
- **Claim 24** (`test/scripts/build-loop-check.bats:91-113`): test 5's duplicate-start, duplicate-plain and tree-name-newline sub-cases fail on the index-only `CLAUDE.md` (lib :570); the treenl mutant survives. Fix: `git read-tree main` after the `update-ref` lines, as `:224` does.
- **Claim 26a** (`test/scripts/build-loop-check.bats:196-200`): the NUL-link case fails on the index-only `CLAUDE.md`; the nulcount mutant survives. Same fix.
- **Claim 28a** (`test/scripts/build-loop-check.bats:250-254`): the empty-link-text case fails on the index-only `CLAUDE.md`; the emptytext mutant survives, and no test pins lib :586. Same fix.
- **Claim 31d** (commit dfeeb85d): `zz<LF>CLAUDE.md` is not a start name to the lib. Commit message: Accepted-immutable.
- **Claim 31e** (commit dfeeb85d): only test 9 was renamed. Commit message: Accepted-immutable.

### Stale
- (none)

### Mostly Accurate
- **Claim 2a** (rubric `:31`): E1's "one main lacks is a start main lacks" should say "a start-shaped one main lacks".
- **Claim 4** (`docs/reviews/override-log.md:383`): "fails the walk if present" should say "if present as anything but a plain directory".
- **Claim 11c** (`docs/working/plan-build-loop-handoff.md:279`): "checkout content at paths main lacks" should say "anything but a plain directory at an imported path main lacks".
- **Claim 12** (`scripts/lib/dev-cycle-read.sh:29-35`): the block above IMPORTED= does not list the checkout listings' own failures.
- **Claim 15** (`scripts/lib/dev-cycle-read.sh:516`): a successful command with empty output also returns 0.
- **Claim 16** (`scripts/lib/dev-cycle-read.sh:536-545`): the return-1 comment omits the index listing (`:562`) and the unmodelled record type (`:598`); "exists" should be "is listed".
- **Claim 26b** (`test/scripts/build-loop-check.bats:175`): test 9 has no regular checkout file at a path main lacks.
- **Claim 30b** (commit 2b22a082): the here-string revert of C4's fix survived at 2b22a082 (pinned since dfeeb85d).

### Unverifiable
- **Claim 2b** (rubric `:32`): "35 in /workspace's own checkout" was outside r3's permitted tree; r1 and r2 each executed the count and got 35.

## Escalations

- `test/scripts/build-loop-check.bats:91-113`, `:196-200`, `:250-254` (r2 cites the `update-ref` lines `:109`, `:199`, `:253`) → **test-strategy; implementer/author; rubric author.** Raised by r1+r2. Since dfeeb85d's index listing (lib `:562-563`), three refusals are unpinned at HEAD: tree-name newline (`:557`), link-text NUL (`:583`), empty link text (`:586`); each sub-case's checkout index still tracks a `CLAUDE.md` the rewritten main lacks, so the walk fails at `:570` first. Suggested fix (r1+r2): `git read-tree main` (and drop `CLAUDE.md`) after each `update-ref`, then re-run the three mutants. r2: "the one item a reviewer might weigh as blocking for a 'final confirming' pass"; r1: keeps the unit at 400 changed lines. (Claims 24, 26a, 28a.)
- `scripts/lib/dev-cycle-read.sh:557` and `docs/reviews/override-log.md:379` → **security-reviewer; author.** Raised by r3. Tree-first doubled blob/tree name fails open in a fresh worktree (executed, X4 P2); new evidence against row 379's "fails the walk closed"; r3 asks for it before merge-readiness is decided. (Claim 13b.)
- `docs/working/known-issues-dev-cycle.md:18` → **author (wording).** Raised by r1+r2+r3. "a link in link text" overstates the refusal. (Claim 9c.)
- `scripts/lib/dev-cycle-read.sh:536-545` → **author/implementer (wording).** Raised by r1+r2+r3. Add the tracked-list failure and the other-record-type arm, or note the `*)` arm is defensive. (Claim 16.)
- `docs/working/plan-build-loop-handoff.md:279` → **author (wording).** Raised by r1. (Claim 11c.)
- `scripts/lib/dev-cycle-read.sh:597-598` → **test-strategy (informational).** Raised by r2+r3. No test reaches `160000) continue` or `*)`; both mutants survive; `*)` is unreachable through `ls-tree -r`, so only the gitlink arm is pinnable (r3: a gitlink stored at a start name, walk ok, X4 P6); r2: "the rubric's E4 'Fixed' has no test". (Claim 19.)
- `test/scripts/build-loop-check.bats:175` → **test-strategy.** Raised by r3. Test 9's name claims a regular checkout file case it does not assert (h-fileok). (Claim 26b.)
- commit dfeeb85d → **rubric author.** Raised by r1+r2+r3. One Accepted-immutable row for the E5 phrases. (Claims 31d, 31e.)

Recorded non-escalations: r1 "None for security. Claim 21 found no state where HEAD answers ok and misses an import that main alone or cc1aa864 would catch"; r2 "Fail-closed question (task item 1): ... No escalation". Both concern checkout states; r3's main-side finding (Claim 13b) is escalated above.

## Verdict stability

- **Total clusters:** 56 (40 Verified, 8 Mostly accurate, 0 Stale, 7 Incorrect, 1 Unverifiable).
- **Single-replicate clusters:** 5 (2d r2; 3 r1; 28b r3; 30c r3; 31b r3), all Verified.
- **Multi-replicate clusters:** 51; all reporting replicates agreed on 37; 14 disagreed.
- **Agreement rate:** 37/51 = 72.5% over multi-replicate clusters (42/56 = 75.0% counting single-replicate clusters as agreed). Two of the 14 disagreements (2c, 9b) differ only through a compound verdict whose severity the replicate placed on a sibling atom; excluding them, 39/51 = 76.5%.
- **Disagreeing clusters** (per-replicate verdicts):
  - 2a rubric E1: r1=Mostly accurate (compound) · r2=Verified (compound) · r3=Verified → Mostly accurate
  - 2b rubric E2: r1=Mostly accurate (compound) · r2=Verified (compound) · r3=Unverifiable → Unverifiable
  - 2c rubric E4/E5: r1=Mostly accurate (compound) · r2=Verified (compound) · r3=Verified → Verified
  - 9b A5 checkout start-file/plain-dir: r1=Mostly accurate (compound) · r2=Incorrect (compound) · r3=Verified → Verified
  - 9c A5 link in link text: r1=Mostly accurate (compound) · r2=Incorrect (compound) · r3=Incorrect → Incorrect
  - 11c U2b bullet: r1=Mostly accurate · r2=Mostly accurate · r3=Verified (compound) → Mostly accurate
  - 12 lib header Inputs: r1=Mostly accurate · r2=Verified · r3=Verified → Mostly accurate
  - 13b doubled name: r1=Verified (compound) · r2=Verified (compound) · r3=Incorrect → Incorrect
  - 24 test 5 comments: r1=Incorrect · r2=Incorrect (compound) · r3=Verified (compound) → Incorrect
  - 26a test 9 NUL: r1=Incorrect · r2=Incorrect (compound) · r3=Mostly accurate (compound) → Incorrect
  - 28a test 12 empty text: r1=Incorrect · r2=Incorrect (compound) · r3=Verified (compound) → Incorrect
  - 30b 2b22a082 mutants: r1=Verified (compound) · r2=— · r3=Mostly accurate → Mostly accurate
  - 31d dfeeb85d "start name": r1=Incorrect · r2=Incorrect · r3=Mostly accurate → Incorrect
  - 31e dfeeb85d "tests 9 and 3 renamed": r1=Mostly accurate · r2=Incorrect · r3=Incorrect → Incorrect
- Of the 7 Incorrect clusters, 1 is single-replicate-detected in substance (13b, r3 only); each of the other 6 had two replicates at Incorrect (counting compound verdicts the replicate placed on that atom).
