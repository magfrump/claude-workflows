Commit: 1898d21c
# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u2a3`, branch `feat/build-loop-u2a3`)
**Scope:** `git diff main...HEAD` at 1898d21c (base main 62d366a7), loop 2 final confirming pass: comments in `scripts/lib/dev-cycle-read.sh`; test names and comments in `test/scripts/build-loop-check.bats` and `test/scripts/dev-cycle.bats`; `docs/working/known-issues-dev-cycle.md` A5; `docs/working/plan-build-loop-handoff.md` F11 and the U2a3, U2a3c and U2b bullets; the rubric's split-decision and Loop 2 sections; the override-log rows added since 0170f16a; the messages of 2b22a082, 5c57d367, 0032ed5a, dfeeb85d and 1898d21c (earlier commits: pointers to their override rows only)
**Checked:** 2026-10-06
**Replication:** k=3, this is replicate r1 (role `cfc2f`, pass `i2`, scratch `/tmp/u2a3-cfc2f-i2-avmk`)
**Total claims checked:** 38 (36 numbered, with 8a/8b/8c split)
**Summary:** 26 verified, 8 mostly accurate, 0 stale, 4 incorrect, 0 unverifiable

Execution provenance for every `executed` claim. All commands ran with TMPDIR=`/tmp/u2a3-cfc2f-i2-avmk` (`$S`). Timestamps are UTC on 2026-10-07, which is 2026-10-06 local.

- **X1** `TMPDIR=$S timeout 1500 bats test/scripts/dev-cycle.bats test/scripts/build-loop-read.bats test/scripts/build-loop-check.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats`. Ran in cwd `/workspace/.claude/wt-build-loop-u2a3` at 03:31:11Z. Exit 0, 114 ok, 0 not ok. Output: `$S/bats-five.txt`.
- **X2** The same five suites at 2b22a082, from `git archive 2b22a082 scripts test` extracted to `$S/at-2b22`. Ran in cwd `$S/at-2b22` at 03:40:42Z. Exit 1 with 113 ok. The one failure is build-loop-read test 79, which reads the repo's own `docs/dev-cycle.md`, and the archive left out `docs/`. After `docs/` was extracted, the rerun of build-loop-read.bats at 03:41:27Z exited 0 with 19/19. Outputs: `$S/bats-five-2b22.txt`, `$S/bats-blr-2b22.txt`.
- **X3** Mutants. `$S/mutate.sh NAME PERL` copies `scripts/` and `test/` to `$S/m-NAME/`, edits the copy's lib with `perl -0pi`, and runs the copy's `bats test/scripts/build-loop-check.bats` from cwd `$S/m-NAME`. Started at 03:33:48Z (`$S/mutants.ts`). Summary in `$S/mutants.txt`; per-mutant diffs in `$S/m-NAME.diff`, outputs in `$S/m-NAME.out`. Results, as exit code and failing tests:
  - Killed: dup (1: 5), index (1: 3), herestring (1: 10), untrnl (1: 7), gitlinkpar (1: 12), untrstart (1: 3 9 11), probe (1: 3 9 12), parent1 (1: 15), plaindir (1: 9), dotdot (1: 10 15), chklnk (1: 15), lowshort (1: 10).
  - **Survived** (exit 0, 16/16): treenl (lib :557 newline half dropped), nulcount (lib :583 `|| [[ "$i" -ne 0 ]]` dropped), emptytext (lib :586 `-z "$out" ||` dropped), starcont (lib :598 `*)` → `continue`), nlemptyarr (nul_list's `nl_a=()` dropped).
- **X4** Probes under `$S/probes/`. Each script is self-contained and writes its own output file. All exited 0.
  - `mask.sh` at 03:35:52Z → `mask.txt`
  - `treenl.sh` at 03:36:21Z → `treenl.txt`
  - `oddmode.sh` / `oddmode2.sh` at 03:36:53Z / 03:38:13Z → `oddmode.txt`, `oddmode2.txt`
  - nul_list probe at 03:37:01Z → `nul_list.txt`
  - `shapes.sh` at 03:38:41Z → `shapes.txt`
  - `perf.sh` at 03:39:27Z → `perf.txt`
  - `dotgit.sh` at 03:39:55Z → `dotgit.txt`
- **X5** Ignored start files in a developer checkout. A walk in cwd `/workspace` with HEAD's lib, at 03:34:42Z, exit 0, printed `walk failed`: `$S/workspace-walk.txt`. A walk in a fresh `git clone --branch main /workspace $S/fresh`, at 03:34:48Z, exit 0, printed `main 1` / `walk ok`: `$S/fresh-walk.txt`. Both runs only read; neither wrote to /workspace.
- **X6** `git diff --numstat main...<rev> -- . ':!docs'` for 2b22a082, dfeeb85d and HEAD. Output is quoted in Claim 31.

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). The suspect pattern is a mis-stated test tally ("All 85 tests", "mode1-equiv 33"). Claims 31 and 35 executed the tallies, and they match. No Incorrect verdict below is a fabricated symbol or API, so the log gets no new entry.

---

## Claim 1: rubric split section: "C2 (gitlink parent): fixed. A 160000 parent fails the walk like a 120000 one." / "C4 ... fixed (`mapfile -d /` from a process substitution)." / "C8 ... steps over `/` with `${c%/*}`" / "C10 (nul_list partial array): fixed (emptied on failure)."

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md:10-17`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four code claims against lib :517, :589 and :607. It does not establish that C10's emptying is pinned by any test: the nlemptyarr mutant survives (X3). The rubric does not claim that it is.

The quoted code: `c="$p"; while [[ "$c" == */* ]]; do c="${c%/*}"; [[ ! "${ent[$c]:-}" =~ ^1[26]0000$ ]] || { IMPORTED_MAIN=error; return 1; }; done` (`scripts/lib/dev-cycle-read.sh:607`), `mapfile -t -d / parts < <(printf '%s' "$out")` (`:589`), and nul_list's `|| { nl_a=(); return 1; }` (`:517`). The mutant results:

- gitlinkpar (`^120000$`) fails test 12.
- herestring (the old `IFS=/ read -ra parts <<<"$out"`) fails test 10.
- parent1 (immediate parent only) fails test 15.

The X4 nul_list probe shows the emptying: `no-trailing-NUL rc=1 n=0` and `fail rc=1 n=0`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:517`, `scripts/lib/dev-cycle-read.sh:589`, `scripts/lib/dev-cycle-read.sh:607`, `/tmp/u2a3-cfc2f-i2-avmk/mutants.txt`, `/tmp/u2a3-cfc2f-i2-avmk/probes/nul_list.txt`

---

## Claim 2: rubric Loop 2 rows E1, E2, E4, E5 (author notes)

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md:31-35`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each author note's claim about the code and tests. It does not establish the critics' severity calls, and does not establish that E5's patch left the earlier refusal tests independent of the new index check (they are not: Claims 24-26).

The notes check out against the code and the runs:

- E2's "35 in /workspace's own checkout": the probe counts 35 start-shaped untracked or ignored `.md` files under `devcontainer-config/claude-home`, and the walk fails there (X5).
- E4 matches the code: `160000) continue ;;` then `*) IMPORTED_MAIN=error; return 1 ;;` (`scripts/lib/dev-cycle-read.sh:597-598`).
- E5 matches the runs: the fixture is `zz<LF>CLAUDE.md`, the link is 68,589 bytes (about 67 KiB), and both mutants are killed (untrnl fails test 7, herestring fails test 10; X3).
- E1's test note is right: the index mutant fails test 3.

E1's mechanism sentence is too broad: "one main lacks is a start main lacks and fails the walk". Only a start-shaped tracked `.md` fails. The code reads `[[ "${cand[i]:0:1}" == m ]] || return 1` inside the `if [[ "${f##*/}" =~ $INSTRUCTION_FILE || ... .claude/rules/*.md ...` branch (`scripts/lib/dev-cycle-read.sh:569-570`; excerpt ends :570, the enclosing `for` continues to :573, read). A tracked `other/readme.md` that main lacks is a non-start candidate and leaves the walk ok (X4 shapes P4 shows an untracked one; the arm is the same for a tracked one). Precise version: "a start-shaped one main lacks".

**Evidence:** `scripts/lib/dev-cycle-read.sh:561-573`, `scripts/lib/dev-cycle-read.sh:597-598`, `/tmp/u2a3-cfc2f-i2-avmk/workspace-walk.txt`, `/tmp/u2a3-cfc2f-i2-avmk/mutants.txt`, `/tmp/u2a3-cfc2f-i2-avmk/probes/shapes.txt`

---

## Claim 3: override row (C3, Defer): "After the split U2a3 reads no checkout content (a path there is only probed and fails the walk if present), so nothing it would read is lost"

**Location:** `docs/reviews/override-log.md:383`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim that no checkout file's content is read, and what the probe does. It does not establish the claim about Claude Code's same-uid access (a host claim).

The walk never opens a checkout file. Every read is `git cat-file blob "$MAIN_SHA:$f"` (`scripts/lib/dev-cycle-read.sh:579`, `:583-584`). The checkout is touched only by `-L` tests (`:593`), the listings (`:561-562`) and the probe (`:608`). But "fails the walk if present" is too broad. A plain directory that is present passes the probe:

```bash
# scripts/lib/dev-cycle-read.sh:608
      [[ -d "$p" && ! -L "$p" && -z "$(blocker "$p" dir)" ]] || [[ ! -e "$p" && ! -L "$p" ]] || { IMPORTED_MAIN=error; return 1; }
```

The plaindir mutant fails test 9 (X3). Precise version: "fails the walk if present as anything but a plain directory".

**Evidence:** `scripts/lib/dev-cycle-read.sh:561-562`, `scripts/lib/dev-cycle-read.sh:579-593`, `scripts/lib/dev-cycle-read.sh:608`, `/tmp/u2a3-cfc2f-i2-avmk/m-plaindir.out`

---

## Claim 4: override row: "a deep 64 KB `a/a/.../x.md` token takes 9-16 s ... Slow, never fail-open; only text committed to main reaches it after the split"

**Location:** `docs/reviews/override-log.md:386`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers one 65,524-byte `a/` token on this machine and where the loop's input comes from. It does not establish the timing on other hardware, or the "0.27-1 s" one-segment figure (not re-run).

`perf.sh` (X4) committed `CLAUDE.md` holding `see @a/a/.../x.md` (32,760 `a/` segments). Two runs took 11.36 s and 8.63 s, and both printed `ok`. That is at or just under the row's band. The loop's `p` comes only from `out` (`done < <(printf '%s\n' "$out")`, `scripts/lib/dev-cycle-read.sh:609`). `out` comes from a main blob through `import_targets` (`:579`) or from main's link text (`:583-596`), so only text committed to main reaches it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:579-609`, `/tmp/u2a3-cfc2f-i2-avmk/probes/perf.txt`

---

## Claim 5: override row: "the lib does not set GIT_NO_REPLACE_OBJECTS; build-loop.sh exports it"

**Location:** `docs/reviews/override-log.md:387`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two files named. It does not establish that build-loop.sh's export reaches a future U2a4/U2b caller of `main_imports`.

`grep -n GIT_NO_REPLACE_OBJECTS` finds `scripts/build-loop.sh:118: export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1` and no hit in `scripts/lib/dev-cycle-read.sh` (paraphrased — no quote available because the claim covers absence of code in the lib).

**Evidence:** `scripts/build-loop.sh:118`

---

## Claim 6: override row: "a start file only in the checkout's index then passed; fixed in the loop 2 iteration 1 fix commit"

**Location:** `docs/reviews/override-log.md:388`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the before and after of the index listing. It does not cover the row's D13 half (an Accepted-immutable commit-message row, not re-verdicted).

The index mutant replaces lib :562 with `recs=()`, which is 2b22a082's behaviour for the index. With it, test 3's new line (`git add -f CLAUDE.local.md; imps main docs/guide.md; want walk failed`) fails (X3), so such a start passed before dfeeb85d. At HEAD, X4 shapes P5 (an index-only `.claude/rules/x.md`) prints `failed docs/r.md:imp`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:562-563`, `test/scripts/build-loop-check.bats:61`, `/tmp/u2a3-cfc2f-i2-avmk/m-index.out`, `/tmp/u2a3-cfc2f-i2-avmk/probes/shapes.txt`

---

## Claim 7: override row: "In a clean linked worktree `.git` is a file, so an instruction file importing `@.git` now fails the walk (pre-split it answered ok)"

**Location:** `docs/reviews/override-log.md:389`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `@.git` from a main checkout and from a linked worktree, with HEAD's lib and with cc1aa864's. It does not establish the row's C9 timing figure.

`dotgit.sh` (X4) printed:

- main checkout: HEAD `ok`, cc1aa864 `ok`
- linked worktree: HEAD `failed`, cc1aa864 `ok`

The failure comes from the probe at lib :608 (quoted in Claim 3): there `.git` exists and is not a directory.

**Evidence:** `scripts/lib/dev-cycle-read.sh:608`, `/tmp/u2a3-cfc2f-i2-avmk/probes/dotgit.txt`

---

## Claim 8a: A5, main side: "symlinked start files and targets on main are followed, `.claude/rules/` at any depth starts, and odd names, link text that is empty, absolute, leaves the repo, holds a newline or NUL or has a `..` after a symlink, an imported path main lacks under a directory main stores as a symlink or gitlink fail it"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk's behaviour for each listed shape. It does not establish that the suite pins each refusal (three are unpinned: Claims 24-26), or anything about Claude Code's own loading.

The code handles each shape:

- Starts: lib :569 matches INSTRUCTION_FILE or `.claude/rules/*.md` at any depth.
- Symlinks: the `120000)` arm at :580-596.
- Odd names: :555-557.
- Link text: :583-586 and :591.
- Parents: :607.

The behaviour was executed. Test 6 follows symlinks and `pkg/.claude/rules/`. The isolated X4 probes show each refusal failing at HEAD with the index equal to main: `mask.txt` lines `HEAD nullink ... index=main: failed` and `HEAD emptylink ... index=main: failed`, and `treenl.txt` `failed`. The killed mutants are listed in X3.

**Evidence:** `scripts/lib/dev-cycle-read.sh:553-610`, `/tmp/u2a3-cfc2f-i2-avmk/bats-five.txt`, `/tmp/u2a3-cfc2f-i2-avmk/probes/mask.txt`, `/tmp/u2a3-cfc2f-i2-avmk/probes/treenl.txt`

---

## Claim 8b: A5: "Until U2a3c the walk ... fails closed on the checkout: a start file main lacks (untracked, ignored, or only in the checkout's index), a link in link text, or anything but a plain directory at an imported path main lacks fails the walk"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three checkout shapes listed. It does not establish failure for checkout edits to files main stores. Those are deliberately not read (test 3: "a working-tree edit does not count").

The start-file half and the plain-directory half hold (X3: untrstart, index, probe and plaindir are killed; X5 covers the ignored case). The middle item is too broad. A link in link text fails only when a `..` follows it:

```bash
# scripts/lib/dev-cycle-read.sh:590-594
        for c in "${parts[@]}"; do
          [[ "$c" != .. || -z "$lk" ]] || { IMPORTED_MAIN=error; return 1; }
          p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${p:+$p/}$c" 2>/dev/null)" || p=..
          [[ "${ent[$p]:-}" != 120000 && ! -L "$p" ]] || lk=1
        done
```

(excerpt ends :594; the enclosing `120000)` arm continues to :596 — read)

X4 shapes P2 puts the text `ld/i.md` on main and `ld -> deep` only in the checkout, with no `deep/i.md`. It prints `ok ld/i.md:imp`. The walk fails only when the link's target holds the file (P3, through the probe). Main's own links in link text are followed: test 6's chain `GEMINI.md -> docs/c1.md -> c2.md` is `walk ok`. Precise version: "a link in the checkout followed by a `..` in link text".

**Evidence:** `scripts/lib/dev-cycle-read.sh:589-596`, `scripts/lib/dev-cycle-read.sh:608`, `/tmp/u2a3-cfc2f-i2-avmk/probes/shapes.txt`

---

## Claim 8c: A5: "A developer checkout with ignored instruction files (here, `devcontainer-config/claude-home/`) therefore always fails it; the gate needs a fresh worktree until U2a3c." / "a path main lacks that the checkout does not hold is recorded but not walked"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers /workspace's checkout as of the run and a fresh clone at main. It does not establish behaviour in a checkout whose ignored files are later removed.

The /workspace walk printed `walk failed` and the fresh clone at main printed `walk ok` (X5). `untracked_md` uses `--others` without `--exclude-standard` (`scripts/lib/dev-cycle-read.sh:515`), so ignored files are listed. For the second sentence: test 3 imports `docs/new.md`, which neither main nor the checkout holds, and gets `walk ok` with `docs/new.md: imported`. The X4 shapes P2 path `ld/i.md` is also recorded (`:imp`) and not walked.

**Evidence:** `scripts/lib/dev-cycle-read.sh:515`, `scripts/lib/dev-cycle-read.sh:600-609`, `test/scripts/build-loop-check.bats:54-57`, `/tmp/u2a3-cfc2f-i2-avmk/workspace-walk.txt`, `/tmp/u2a3-cfc2f-i2-avmk/fresh-walk.txt`

---

## Claim 9: plan F11 (U2a3 row of the failure-mode table)

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the main-side refusal list, the checkout list (start file main lacks; anything but a plain directory at an imported path main lacks) and the gaps list against lib :452-469. It does not establish U2a4's floor or U2a3c, which are not built.

F11's checkout list leaves out A5's "a link in link text" (Claim 8b) and so is accurate. "NUL-safe listings": every listing uses `-z` with `nul_list` (`scripts/lib/dev-cycle-read.sh:553`, `:561-562`). The refusal list matches the code and runs cited in Claims 8a and 8c. The gaps list matches the lib's "Not covered" sentence (`:466-469`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:452-469`, `scripts/lib/dev-cycle-read.sh:553-608`, `/tmp/u2a3-cfc2f-i2-avmk/mutants.txt`

---

## Claim 10: plan U2a3 bullet: "started from main's instruction files and `.claude/rules/`. It refuses ... (a doubled name, a name holding a newline, symlink text that is empty, absolute, leaves the repo, holds a newline or NUL or has a `..` after a symlink, an imported path main lacks under a directory main stores as a symlink or gitlink), ... and fails closed on the checkout (a start file main lacks, or anything but a plain directory at an imported path main lacks)."

**Location:** `docs/working/plan-build-loop-handoff.md:276`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the bullet's description of the code. It does not cover the U2a3c bullet (`:277`), which describes an unbuilt unit: `git branch --list 'feat/build-loop-u2a3*'` shows only u2a3, u2a3-src and u2a3b, so U2a3c's design is not checkable.

The evidence is the same as for Claims 8a and 9: the code lines cited there, the killed mutants and the isolated probes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:553-608`, `/tmp/u2a3-cfc2f-i2-avmk/mutants.txt`, `/tmp/u2a3-cfc2f-i2-avmk/probes/mask.txt`

---

## Claim 11: plan U2b bullet: "a fresh worktree at MAIN_SHA, since until U2a3c the walk fails on any start file main lacks, ignored ones included, and on checkout content at paths main lacks"

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stated reasons. It does not establish U2b's design.

The start-file half holds (X5). "Checkout content at paths main lacks" is too broad. Only an *imported* path main lacks is probed (`scripts/lib/dev-cycle-read.sh:605-608`), and a plain directory there passes. X4 shapes P4 leaves an untracked `notes.txt` and `other/readme.md`, which main lacks and nothing imports, and prints `ok docs/a.md:imp`. Precise version: "anything but a plain directory at an imported path main lacks".

**Evidence:** `scripts/lib/dev-cycle-read.sh:605-608`, `/tmp/u2a3-cfc2f-i2-avmk/probes/shapes.txt`

---

## Claim 12: lib header, Inputs: "and so does main_imports (it reads the checkout only to fail, until U2a3c, so the gate needs a fresh worktree; the block above IMPORTED= lists each case; it needs resolve_main to have found main by name)"

**Location:** `scripts/lib/dev-cycle-read.sh:32-35`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every checkout read in `main_imports`. It does not establish that the block comment lists the listing-failure causes; the return-1 comment does, in part (Claim 16).

"Reads the checkout only to fail" holds. Each checkout read can only end in `return 1` or have no effect:

- the untracked and index listings (`:561-563`)
- `! -L "$p"` in the link-text loop (`:593`, which only sets `lk`)
- the probe (`:608`)

"Needs resolve_main ...": `main_by_name || return 1` (`:552`), and test 4's trunk case. "Lists each case" is slightly short. The block (`:457-464`) names the shapes: a start file main lacks, a newline name, a checkout link before `..`, and anything but a plain directory. It does not name the failures of the checkout's listings themselves: `nul_list recs untracked_md || return 1` and the `--cached` listing's `|| return 1` (`:561-562`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:32-35`, `scripts/lib/dev-cycle-read.sh:457-464`, `scripts/lib/dev-cycle-read.sh:552-608`

---

## Claim 13: block comment above IMPORTED=: start set, "follows an import into the file main stores at that path, whatever its name", "An imported path main lacks is recorded and not read", the refusal list "(on main or in the checkout)", "(the root itself included)", "a start file main lacks (untracked, ignored, or in the checkout's index)", "A start file answers imported only when an import reaches it"

**Location:** `scripts/lib/dev-cycle-read.sh:452-466`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed behaviour at HEAD. It does not establish that the suite pins the tree-name newline, link-text NUL and empty-text refusals (Claims 24-26), and does not cover the failing-sed/grep/lower cases, which are fixed in U2a3b (stacked).

How each part was checked:

- Root included: X4 shapes P1 (`@.` and `@docs/..`) each print `failed`. `blocker "." dir` prints `./`, because `plaindir .` compares `realpath -e .` with `"$ROOT_REAL/."` (`:102`, `:117-118`).
- Start file main lacks: killed mutants (untrstart and index), X5 for the ignored case, and P5.
- "(on main or in the checkout)": the chklnk mutant (`! -L` dropped) fails test 15.
- Recorded and not read: lines `:602` (`IMPORTED_MAIN+=...`) and `:605-608` (no queue push for a path main lacks).
- Start answers imported only when reached: test 3's `CLAUDE.md -`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:102`, `scripts/lib/dev-cycle-read.sh:110-120`, `scripts/lib/dev-cycle-read.sh:567-573`, `scripts/lib/dev-cycle-read.sh:600-609`, `/tmp/u2a3-cfc2f-i2-avmk/probes/shapes.txt`, `/tmp/u2a3-cfc2f-i2-avmk/mutants.txt`

---

## Claim 14: "IMPORTED_MAIN reads "error" until a walk succeeds; the result is cached for the commit, MAIN_BY_NAME and root in IMPORTED_MAIN_DONE, so a caller whose checkout changes between calls sets IMPORTED_MAIN_DONE="" to walk again."

**Location:** `scripts/lib/dev-cycle-read.sh:470-472`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cache key and the failed-walk reuse. It does not establish IMPORTED_MAIN's value mid-walk: it is set to `$'\n'` at :574, before the queue drains. Settled by override row B10 (errexit off and IMPORTED_MAIN set before the walk ends).

The code reads `[[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }` and then `IMPORTED_MAIN=error; IMPORTED_MAIN_DONE="$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"` (`:550-551`). Every `return 1` after :574 sets `IMPORTED_MAIN=error` first (`:579, :584, :586, :591, :596, :598, :607, :608`). Test 16 passes in X1: a new commit walks again, a failed walk stays failed, and `MAIN_BY_NAME=""` walks again.

**Evidence:** `scripts/lib/dev-cycle-read.sh:550-610`, `test/scripts/build-loop-check.bats:306-315`, `/tmp/u2a3-cfc2f-i2-avmk/bats-five.txt`

---

## Claim 15: "nul_list NAME CMD...: array NAME gets CMD's NUL-split output, or is emptied and 1 unless CMD exited 0 and its output ended in NUL."

**Location:** `scripts/lib/dev-cycle-read.sh:516`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers nul_list's return value and array contents for empty, unterminated, terminated, failing and forged-tail output. It does not establish that any test pins the emptying (the nlemptyarr mutant survives).

The X4 nul_list probe printed:

- `empty-output rc=0 n=0`
- `no-trailing-NUL rc=1 n=0`
- `trailing-NUL rc=0 n=2 [a b]`
- `fail rc=1 n=0`
- `forged-tail rc=1 n=0 []`

So empty output from a successful command returns 0, though it did not "end in NUL". Precise version: "unless CMD exited 0 and its output was empty or ended in NUL". The empty case is the correct answer for an empty listing.

**Evidence:** `scripts/lib/dev-cycle-read.sh:517`, `/tmp/u2a3-cfc2f-i2-avmk/probes/nul_list.txt`, `/tmp/u2a3-cfc2f-i2-avmk/m-nlemptyarr.out`

---

## Claim 16: return-1 comment lists every cause: "when main is not found by name, the commit's tree or the untracked list cannot be listed whole (nul_list), a tree record does not parse, a name is listed twice ... or holds a newline, the lower-cased start list comes back short, a start file main lacks exists, a blob cannot be read, symlink text ... or an imported path main lacks lies under a directory main stores as a symlink or gitlink or exists in the checkout as anything but a plain directory below the root; need_root exits instead"

**Location:** `scripts/lib/dev-cycle-read.sh:536-545`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each `return 1` in `main_imports` (:546-611, read whole) against the list. It does not establish behaviour when sed, grep or lower fail (fixed in U2a3b, stacked).

Every listed cause maps to a `return 1`. Two code paths are not named:

1. The index listing, `nul_list recs env GIT_LITERAL_PATHSPECS=0 git ls-files -z --cached -- ':(glob,icase)**/*.md' || return 1` (`:562`). The comment names only "the untracked list".
2. The unmodelled record type that dfeeb85d added, `*) IMPORTED_MAIN=error; return 1 ;;` (`:598`).

The second is not reachable through `git ls-tree`: a tree written with mode 100664, by `mktree` or raw with `hash-object --literally`, is listed as `100644` (X4 `oddmode.txt`, `oddmode2.txt`). Precise version: add "the checkout's index cannot be listed whole" and "a tree record has a type it does not model".

**Evidence:** `scripts/lib/dev-cycle-read.sh:536-545`, `scripts/lib/dev-cycle-read.sh:552-608`, `/tmp/u2a3-cfc2f-i2-avmk/probes/oddmode.txt`, `/tmp/u2a3-cfc2f-i2-avmk/probes/oddmode2.txt`

---

## Claim 17: link-text split and its comment: "realpath -s reads x/.. as nothing, but the kernel follows a symlink x first: a .. after a symlink on main or in the checkout fails." with `mapfile -t -d / parts < <(printf '%s' "$out")`

**Location:** `scripts/lib/dev-cycle-read.sh:587-594`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `..` check for main and checkout links, and that the split reads text past 64 KiB when temp writes fail. It does not establish how Claude Code resolves a `..` in an `@` token (A5 lists that as untraced).

The code is quoted in Claim 8b. The mutant results:

- dotdot fails tests 10 and 15.
- chklnk (checkout `-L` dropped) fails test 15.
- herestring fails test 10. That is the 68,589-byte link under `ulimit -f 0` with `trap "" XFSZ`, after `git read-tree main` isolates it from the index check (`test/scripts/build-loop-check.bats:223-226`).

`mapfile -t -d /` splits like the old `IFS=/ read -ra` for text without a newline. Newlines are already refused at `:586`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:586-596`, `test/scripts/build-loop-check.bats:222-226`, `/tmp/u2a3-cfc2f-i2-avmk/mutants.txt`

---

## Claim 18: `160000) continue ;;  # a gitlink: its files are not main's` / `*) IMPORTED_MAIN=error; return 1 ;;`

**Location:** `scripts/lib/dev-cycle-read.sh:597-598`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what each arm does. It does not establish that the `*)` arm is reachable (git canonicalizes modes on listing; X4 oddmode probes) or tested (the starcont mutant survives).

The code reads exactly as quoted. The `case` dispatches on `"${ent[$f]}"`, the six-octal mode taken from ls-tree (`:555`, `:558`). A queued gitlink (a start named `*.md` stored as 160000, or an import of the gitlink path itself) yields no imports. A path under it fails through `:607` (the gitlinkpar mutant fails test 12).

**Evidence:** `scripts/lib/dev-cycle-read.sh:555-558`, `scripts/lib/dev-cycle-read.sh:578-599`, `scripts/lib/dev-cycle-read.sh:607`, `/tmp/u2a3-cfc2f-i2-avmk/probes/oddmode2.txt`, `/tmp/u2a3-cfc2f-i2-avmk/m-starcont.out`

---

## Claim 19: "Main lacks p: under a link or gitlink main stores, or in the checkout as anything but a plain directory, fail." with the `${c%/*}` loop and `^1[26]0000$`

**Location:** `scripts/lib/dev-cycle-read.sh:606-608`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every proper ancestor of `p`, for modes 120000 and 160000, and the probe. It does not establish behaviour under an unsearchable checkout directory: it reads as absent, per the C3 Defer row.

The loop `c="$p"; while [[ "$c" == */* ]]; do c="${c%/*}"; ...` visits every prefix before a `/`. It is equivalent to cc1aa864's per-index loop, plus the 160000 match. `^1[26]0000$` matches exactly 120000 and 160000. An unset entry, `${ent[$c]:-}` = "", does not match. The mutant results: parent1 fails test 15, gitlinkpar fails test 12, probe fails tests 3, 9 and 12, plaindir fails test 9 (X3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:600-609`, `/tmp/u2a3-cfc2f-i2-avmk/mutants.txt`

---

## Claim 20: isimported: "A failed main walk, or a walk name that is neither, answers imported (0), so a caller testing it with `if` refuses; a caller that words a failed walk runs main_imports first. Run it in the caller's shell: the walk exits through need_root and caches its result."

**Location:** `scripts/lib/dev-cycle-read.sh:612-616`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `main`, `tree` and default arms. It does not establish errexit behaviour inside `main_imports` when called under `||` (settled override row).

The arm reads `main) main_imports || return 0; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]] ;;` and the default is `*) return 0 ;;` (`:622-624`). Tests 2, 8 and 14 pass in X1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:617-626`, `/tmp/u2a3-cfc2f-i2-avmk/bats-five.txt`

---

## Claim 21: the fail-closed contract: "Checkout files are not walked until U2a3c, so the walk fails closed on them" and "a path main lacks that the checkout does not hold is recorded and not walked". Is there a main tree or checkout state where the walk answers ok but misses an import that main alone, or the pre-split walk at cc1aa864, would catch?

**Location:** `scripts/lib/dev-cycle-read.sh:464-465`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the diff from cc1aa864 to HEAD and the probed checkout shapes. It establishes no such state. It does not cover the documented gaps (A5's not-covered list), checkout edits to files main stores (by design), git-environment bypasses (the U2b Defer row), or failing sed/grep/lower (U2a3b).

Static comparison (`git diff cc1aa864 HEAD -- scripts/lib/dev-cycle-read.sh`, read whole):

- The main side is unchanged apart from added refusals: the gitlink parent at :607, and `*)` failing at :598.
- The link-text split is equivalent for newline-free text (Claim 17).
- The parent loop visits the same prefixes (Claim 19).
- Every cc1aa864 path that read checkout content now fails. At cc1aa864, a `t:` item that `inrepo_here` accepts is a plain file; at HEAD, `-e` holds and `-d` fails, so the probe fails. An untracked start now fails at :570.
- The paths cc1aa864 skipped (absent, or a plain directory) are skipped the same way at HEAD.

The new index listing only appends to `cand` (`[[ -n "${ent[$f]+set}" ]] || cand+=("t:$f")`, :563). Reusing `low` for the untracked list (:561) is safe. `mapfile` clears the array when `cand` is non-empty. When `cand` is empty, main stores no `.md` files, so every untracked `.md` would be in `cand`, and `low` must be empty too.

Executed: X4 shapes P1-P5 and `dotgit.sh` (the only state where HEAD and cc1aa864 differ is a new failure). X5 covers the ignored files.

**Evidence:** `scripts/lib/dev-cycle-read.sh:546-611`, `/tmp/u2a3-cfc2f-i2-avmk/probes/shapes.txt`, `/tmp/u2a3-cfc2f-i2-avmk/probes/dotgit.txt`, `/tmp/u2a3-cfc2f-i2-avmk/workspace-walk.txt`

---

## Claim 22: test 3 name "main's instruction files start it; a working-tree edit does not count; an untracked start or a checkout file at a path main lacks fails it until U2a3c"

**Location:** `test/scripts/build-loop-check.bats:46`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test asserts. Its index-only start line (:61) is untold in the name but asserted. The scope does not cover ignored starts (not in this test; X5 covers them).

Lines :59-61 assert `walk failed` and `docs/guide.md imported` for `docs/new.md` present, an untracked `CLAUDE.local.md`, and the same file staged. The mutant results: index fails 3, untrstart fails 3, probe fails 3 (X3).

**Evidence:** `test/scripts/build-loop-check.bats:46-62`, `/tmp/u2a3-cfc2f-i2-avmk/mutants.txt`

---

## Claim 23: test 7 comments: "An untracked name holding a newline fails the walk." / "Symlink text with a trailing newline, an absolute one, none, or one leaving the repo: the walk fails."

**Location:** `test/scripts/build-loop-check.bats:147`, `test/scripts/build-loop-check.bats:153`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the asserted outcomes. It does not establish which check fails the `''` (none) case.

The newline fixture `zz<LF>CLAUDE.md` is pinned: the untrnl mutant fails test 7. In this test's loop the checkout index holds `AGENTS.md` and `..x.md`, so no index-only start masks it. The `''` text case at the top level fails even under the emptytext mutant, through the root probe (`@` text "" resolves to `.`; Claim 13). So the empty check is pinned nowhere (Claim 26).

**Evidence:** `test/scripts/build-loop-check.bats:139-161`, `/tmp/u2a3-cfc2f-i2-avmk/m-untrnl.out`, `/tmp/u2a3-cfc2f-i2-avmk/m-emptytext.out`

---

## Claim 24: test 5 comments: "A start file listed twice (a symlink first, which git reads), and a plain file listed twice: each fails the walk rather than reading one copy." / "A name holding a newline is not modelled, so it fails the walk: a plain one, and one shaped so each half looks like an ls-tree record"

**Location:** `test/scripts/build-loop-check.bats:91-113`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether these sub-cases test the refusal they name. Each passes for an unrelated reason. Sub-case 1 (`docs/a.md` listed twice, :84-89) is unaffected and does pin the duplicate check. The lib's refusals themselves are correct (Claim 8a).

Since dfeeb85d added the index listing (`scripts/lib/dev-cycle-read.sh:562-563`), the checkout index in this test still holds `CLAUDE.md` from `commit_all claude` (:84). The rewritten main trees at :94, :97 and :108 lack it, so every one of those walks fails at `[[ "${cand[i]:0:1}" == m ]] || return 1` (:570) before the shape is reached. The runs show this:

- The treenl mutant (newline half of :557 dropped) survives the suite, 16/16 (X3).
- In isolation, with an empty index and no checkout files, HEAD prints `failed` and treenl prints `ok docs/d.md imported` (`treenl.txt`).
- For the duplicate start, the dup mutant prints `index-as-test: failed | index=main: ok` (`mask.txt`).

The assertions `want walk failed` hold, but they do not test the shapes these comments name.

**Evidence:** `test/scripts/build-loop-check.bats:82-113`, `scripts/lib/dev-cycle-read.sh:557`, `scripts/lib/dev-cycle-read.sh:562-570`, `/tmp/u2a3-cfc2f-i2-avmk/m-treenl.out`, `/tmp/u2a3-cfc2f-i2-avmk/probes/treenl.txt`, `/tmp/u2a3-cfc2f-i2-avmk/probes/mask.txt`

---

## Claim 25: test 9 name "main walk fails on symlink text holding a NUL ..." and comment "Symlink text holding a NUL: $(...) would drop it and follow another name."

**Location:** `test/scripts/build-loop-check.bats:175`, `test/scripts/build-loop-check.bats:196-200`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the NUL sub-case only. The test's other sub-cases (parent link, checkout symlink, untracked and unreadable starts, plain directory) are pinned (probe and plaindir fail test 9, untrstart fails 9).

The new main tree at :198 (`AGENTS.md` link + `docs-rules.md`) lacks `CLAUDE.md`, which the checkout index still tracks from :179. The walk therefore fails at lib :570 before the link arm runs. The nulcount mutant (lib :583 `|| [[ "$i" -ne 0 ]]` dropped) survives the suite (X3). In `mask.txt` it prints `index-as-test: failed | index=main: ok docs/rules.md:-`, and HEAD prints `failed` in both columns.

**Evidence:** `test/scripts/build-loop-check.bats:175-201`, `scripts/lib/dev-cycle-read.sh:583-584`, `/tmp/u2a3-cfc2f-i2-avmk/m-nulcount.out`, `/tmp/u2a3-cfc2f-i2-avmk/probes/mask.txt`

---

## Claim 26: test 12 name "... empty link text below the top level ..." and comment "Empty symlink text in sub/ would name sub/ itself, a plain directory here."

**Location:** `test/scripts/build-loop-check.bats:240`, `test/scripts/build-loop-check.bats:250-254`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the empty-text sub-case only. The dangling-link, link-directory and gitlink sub-cases are pinned (probe and gitlinkpar fail test 12).

The tree at :253 holds only `sub/AGENTS.md`, while the checkout index tracks `CLAUDE.md` (:243). The walk fails at lib :570. The emptytext mutant survives (X3), and `mask.txt` shows `emptytext emptylink index-as-test: failed | index=main: ok docs/x.md:-` against HEAD's `failed` in both columns. With Claim 23, the empty-text refusal (lib :586) is pinned by no test.

**Evidence:** `test/scripts/build-loop-check.bats:240-258`, `scripts/lib/dev-cycle-read.sh:586`, `/tmp/u2a3-cfc2f-i2-avmk/m-emptytext.out`, `/tmp/u2a3-cfc2f-i2-avmk/probes/mask.txt`

---

## Claim 27: test 10 name and comments: "returns, not exits, when main's tree or the untracked list cannot be listed ...; reads a list past 64 KiB under ulimit -f 0" and "Link text past 64 KiB with a .. after main's link l, under ulimit -f 0: the .. check reads it whole"

**Location:** `test/scripts/build-loop-check.bats:203`, `test/scripts/build-loop-check.bats:222`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed cases. The index listing's own failure (lib :562) has no separate case; a corrupt index fails the untracked listing first.

The `[ "$status" -eq 0 ]` checks pin "returns, not exits". The mutant results: lowshort fails test 10 (the tr case), herestring fails 10, dotdot fails 10 (X3). The link case calls `git read-tree main` and `rm -r docs` first (:224), so the index check cannot mask it.

**Evidence:** `test/scripts/build-loop-check.bats:203-227`, `/tmp/u2a3-cfc2f-i2-avmk/mutants.txt`

---

## Claim 28: remaining U2a3 test names (tests 4, 6, 8, 11, 13, 14, 15, 16) assert what they say

**Location:** `test/scripts/build-loop-check.bats:64`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers tests at :64, :115, :163, :229, :260, :271, :281 and :306. It does not establish that each named sub-shape is the cause of its failure, except where a mutant isolates it: untrstart for test 11; parent1 and chklnk for test 15.

All pass (X1). In these tests the index holds only files that the rewritten main also stores, or main is not rewritten, so the index-only masking of Claims 24-26 does not apply. Checked per test:

- test 4: blob removed from `main:CLAUDE.md`, and the index tracks `CLAUDE.md`.
- test 8: `AGENTS.md`.
- test 14: `CLAUDE.md`.
- test 15: every main is a `commit_all`.
- test 16: the cache answers are asserted whatever the cause of failure.

**Evidence:** `test/scripts/build-loop-check.bats:64-80`, `test/scripts/build-loop-check.bats:115-137`, `test/scripts/build-loop-check.bats:163-173`, `test/scripts/build-loop-check.bats:229-315`, `/tmp/u2a3-cfc2f-i2-avmk/bats-five.txt`

---

## Claim 29: dev-cycle.bats "sourcing the reader lib defines its functions and calls neither git nor perl" (list extended with `main_imports`, `nul_list`, `IMPORTED_MAIN`, `IMPORTED_MAIN_DONE`)

**Location:** `test/scripts/dev-cycle.bats:1077`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the names are defined at source time. It does not establish their behaviour.

The test passes in X1. `nul_list` is defined at lib :517, and the variables at :474.

**Evidence:** `test/scripts/dev-cycle.bats:1077-1094`, `scripts/lib/dev-cycle-read.sh:474`, `/tmp/u2a3-cfc2f-i2-avmk/bats-five.txt`

---

## Claim 30: dfeeb85d behavioural claims (E1-E4, E6): "The walk now also lists the checkout's tracked .md files; a start-shaped one main lacks fails the walk, as an untracked or ignored one does." / "a gitlink continues and any other type fails the walk" / "dev-cycle.bats lists nul_list" / "the plan's U2a3c bullet carries architecture F1 and F5"

**Location:** `dfeeb85d` (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed E-items against the diff `2b22a082..dfeeb85d`. It does not cover E5 (Claims 32 and 33) or the figures (Claim 31).

The diff matches each item:

- The `--cached` listing was added (lib :562-563).
- `160000) continue` and `*)` fail (:597-598).
- The dev-cycle.bats list gains `nul_list`.
- The plan's U2a3c bullet (`plan-build-loop-handoff.md:277`) names "one admission check" and "One drain loop run over two seedings".

X4 P5 and test 3 fail for an index-only start (Claim 6).

**Evidence:** `scripts/lib/dev-cycle-read.sh:562-563`, `scripts/lib/dev-cycle-read.sh:597-598`, `docs/working/plan-build-loop-handoff.md:277`, `/tmp/u2a3-cfc2f-i2-avmk/probes/shapes.txt`

---

## Claim 31: dfeeb85d figures: "Tests: build-loop-check.bats 16; 114 across the five suites. Mutants of the index listing, the link-text split (here-string revert) and the newline check each fail. 400 changed code lines against main."

**Location:** `dfeeb85d` (commit message)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts and the three named mutants at HEAD. HEAD's code and tests equal dfeeb85d's, because 1898d21c touches only `docs/reviews/`. It does not establish the mutants' results in other suites.

`grep -c '^@test'` at dfeeb85d gives 75 + 19 + 16 + 2 + 2 = 114, and X1 reports 114 ok. X6 gives this output for `main...dfeeb85d`:

```
113	9	scripts/lib/dev-cycle-read.sh
272	2	test/scripts/build-loop-check.bats
2	2	test/scripts/dev-cycle.bats
```

That sums to 400, and HEAD gives the same. The mutant results: index fails 3, herestring fails 10, untrnl (the untracked-list newline check) fails 7 (X3).

**Evidence:** `test/scripts/build-loop-check.bats:46`, `/tmp/u2a3-cfc2f-i2-avmk/bats-five.txt`, `/tmp/u2a3-cfc2f-i2-avmk/mutants.txt`

---

## Claim 32: dfeeb85d E5: "test 7's newline fixture is a start name"

**Location:** `dfeeb85d` (commit message)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers how the lib classifies `zz<LF>CLAUDE.md`. It does not affect the test's value: the fixture pins the newline check because it is *not* a start.

The lib tests `"${f##*/}" =~ $INSTRUCTION_FILE` (`scripts/lib/dev-cycle-read.sh:569`). `${f##*/}` of `zz<LF>claude.md` is the whole name, and the `^`-anchored regex does not match it. Executed in bash 5.2.15: `[[ $'zz\nclaude.md' =~ $INSTRUCTION_FILE ]]` prints `nomatch`. Under the untrnl mutant the walk is `ok` (`m-untrnl.out`: `walk: ok`, `docs/x.md: -`). A start name would have failed at :570 regardless.

**Evidence:** `scripts/lib/dev-cycle-read.sh:442`, `scripts/lib/dev-cycle-read.sh:567-570`, `/tmp/u2a3-cfc2f-i2-avmk/m-untrnl.out`

---

## Claim 33: dfeeb85d E5: "tests 9 and 3 renamed for the split"

**Location:** `dfeeb85d` (commit message)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the `@test` lines changed by `2b22a082..dfeeb85d`.

`git diff 2b22a082 dfeeb85d -- test/scripts/build-loop-check.bats | grep '^[-+]@test'` shows one rename, test 9 (:175). Test 3 gained an assertion (:61), but its name is unchanged since 2b22a082 (paraphrased — no quote available because the claim covers the absence of a renamed line in a diff).

**Evidence:** `test/scripts/build-loop-check.bats:46`, `test/scripts/build-loop-check.bats:175`

---

## Claim 34: 2b22a082 figures: "build-loop-check.bats 16; 114 across the five suites. Mutants of the untracked-start refusal, the checkout probe, the gitlink match, the parent loop (immediate parent only), the plain-directory allowance and the link-text split each fail. 392 changed code lines against main."

**Location:** `2b22a082` (commit message)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the suites run at 2b22a082 and the line count. The six named mutants were run at HEAD, where these lines are unchanged from 2b22a082. It does not re-verdict the message's headline or the D13 sentence (Accepted-immutable row, `override-log.md:388`).

X2 gives 114 at 2b22a082: 113 ok plus build-loop-read 19/19 once `docs/` is present. X6 for `main...2b22a082` gives 111+9, 266+2 and 2+2, which is 392. At HEAD (X3), untrstart, probe, gitlinkpar, parent1, plaindir and dotdot each fail at least one test.

**Evidence:** `/tmp/u2a3-cfc2f-i2-avmk/bats-five-2b22.txt`, `/tmp/u2a3-cfc2f-i2-avmk/bats-blr-2b22.txt`, `/tmp/u2a3-cfc2f-i2-avmk/mutants.txt`

---

## Claim 35: docs(reviews) commits 5c57d367, 0032ed5a, 1898d21c: "fix-drift output ... (no findings)" / "fact-check, critic reports, rubric and override rows"

**Location:** `1898d21c` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each commit's file list against its message. It does not re-verdict the reports' contents.

1898d21c adds `lite-review-fix-drift-build-loop-u2a3-L2i1.txt`, which reads `lite-review [fix-drift]: FINDINGS: NONE (14544 out-tokens)`. 0032ed5a adds the L2 fact-check, five critic reports, 29 rubric lines and 4 override rows (`git show --stat`). 5c57d367 adds `lite-review-fix-drift-build-loop-u2a3-split.txt` (paraphrased — no quote available because the claim is about commit file lists).

**Evidence:** `docs/reviews/lite-review-fix-drift-build-loop-u2a3-L2i1.txt:1`

---

## Claim 36: earlier commit messages (fbeae280 through 0170f16a)

**Location:** `docs/reviews/override-log.md:380-382`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This is a pointer only. The earlier messages are not re-verdicted; their findings sit in the Accepted-immutable rows at `override-log.md:380-382` and :388, per the task.

Rows :380 (4f087967 and 34edec56), :382 (e7b5d7ed and c42f017f) and :388 (2b22a082) are present (paraphrased — no quote available because this is a pointer list).

**Evidence:** `docs/reviews/override-log.md:380-388`

---

## Claims Requiring Attention

### Incorrect
- **Claim 24** (`test/scripts/build-loop-check.bats:91-113`): The duplicate-start, duplicate-other and newline-in-tree sub-cases fail on the index-only `CLAUDE.md` (lib :570), not on the shapes they name. The treenl mutant survives. Fix: `git read-tree main` (or drop `CLAUDE.md` from index and checkout) before those sub-cases, as test 10 does at :224.
- **Claim 25** (`test/scripts/build-loop-check.bats:196-200`): The NUL-link case fails on the index-only `CLAUDE.md`. The nulcount mutant survives. Same fix.
- **Claim 26** (`test/scripts/build-loop-check.bats:250-254`): The empty-link-text case fails on the index-only `CLAUDE.md`. The emptytext mutant survives, and no test pins lib :586's empty check. Same fix.
- **Claim 32** (dfeeb85d message): `zz<LF>CLAUDE.md` is not a start name to the lib, which is why it isolates the newline check. A commit message, so Accepted-immutable is the likely disposition.

### Mostly Accurate
- **Claim 2** (rubric :31): E1's "one main lacks is a start main lacks" should say "a start-shaped one main lacks".
- **Claim 3** (`override-log.md:383`): "fails the walk if present" should say "if present as anything but a plain directory".
- **Claim 8b** (A5, `known-issues-dev-cycle.md:18`): "a link in link text" fails the walk only when a `..` follows it.
- **Claim 11** (U2b bullet, `plan-build-loop-handoff.md:279`): "checkout content at paths main lacks" should say "anything but a plain directory at an imported path main lacks".
- **Claim 12** (lib :32-35): the block above IMPORTED= does not list the checkout listings' own failures.
- **Claim 15** (lib :516): a successful command with empty output also returns 0.
- **Claim 16** (lib :536-545): the return-1 comment omits the index listing (:562) and the unmodelled record type (:598).
- **Claim 33** (dfeeb85d message): only test 9 was renamed.

## Escalations

- `test/scripts/build-loop-check.bats:91-113`, `:196-200`, `:250-254` → **test-strategy / author.** Since dfeeb85d's index listing (lib :562-563), three of the lib's refusals are unpinned: a newline in a tree name (:557), a NUL in link text (:583) and empty link text (:586). Each sub-case's checkout index still tracks a `CLAUDE.md` that the rewritten main lacks, so the walk fails at :570 first. Three mutants survive the whole suite. Appending `git read-tree main` and removing `CLAUDE.md` onto each sub-case's existing `update-ref` line keeps the unit at 400 changed lines: these lines are already additions against main.
- `docs/working/known-issues-dev-cycle.md:18` and `docs/working/plan-build-loop-handoff.md:279` → **author (wording).** See Claims 8b and 11.
- `scripts/lib/dev-cycle-read.sh:536-545` → **author (wording).** See Claim 16.
- None for security. Claim 21 found no state where HEAD answers ok and misses an import that main alone or cc1aa864 would catch.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A code-fact-check report verdicting every checkable claim in the U2a3 diff's comments, docs and commit messages, saved at the path given below."
- **Answered:**
  - All six focus areas are verdicted, with executed evidence:
    - the lib comments and the fail-closed contract (Claims 12-21)
    - the index listing, record-type arms, link-text split and parent loop (16-19)
    - A5, F11 and the plan bullets (8a-11)
    - the commit messages since 0170f16a, with figures and named mutants run (30-35)
    - the test names, where three false passes were found (22-29)
    - the rubric and override rows (1-7)
  - The interim contract holds: no ok-but-missed import against main alone or cc1aa864 was found.
  - The merge-relevant result is the three unpinned refusals introduced by test masking in dfeeb85d. They are test weaknesses, not code defects.
- **Out of scope:** Claude Code's own loading behaviour (A5's untraced shapes). U2a3c's design, which is unbuilt. Failing sed/grep/lower (U2a3b, stacked). Git-environment hardening (U2b Defer row).
- **Escalate:** the test-masking item above, to the rubric author and test-strategy for this final pass.
