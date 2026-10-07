Commit: 1898d21c
# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u2a3`, branch `feat/build-loop-u2a3`)
**Scope:** `git diff main...HEAD` at 1898d21c (base 62d366a7): comments in `scripts/lib/dev-cycle-read.sh`, test names and comments in `test/scripts/build-loop-check.bats` and `test/scripts/dev-cycle.bats`, known issue A5, plan F11 and the U2a3/U2a3c/U2b bullets, the rubric's split-decision and Loop 2 sections, override-log rows added since 0170f16a, and commit messages since 0170f16a (2b22a082, 5c57d367, 0032ed5a, dfeeb85d, 1898d21c). Commits before 0170f16a: pointers only (their Accepted-immutable override rows stand). Role `cfc2f`, pass `i2`, replicate 2 of 3.
**Checked:** 2026-10-06 (probes ran 2026-10-07T03:31Z-03:41Z UTC)
**Total claims checked:** 37
**Summary:** 28 verified, 5 mostly accurate, 0 stale, 4 incorrect, 0 unverifiable

Scratch: `/tmp/u2a3-cfc2f-i2-x7bC` (`$S` below). Every probe ran under `timeout`, with `TMPDIR=$S` for bats, in repos under `$S`; mutants were made in archive copies (`$S/tree-HEAD`, `$S/tree-2b22a082`, from `git archive`), never in the worktree. No background processes were started. Hallucination-pattern log read: no claim below matches a logged pattern, and none of the Incorrect verdicts is a fabricated symbol, so the log is not updated.

Libraries compared in the fail-closed probes: `$S/libs/head.sh` (HEAD's lib), `$S/libs/cc.sh` (`git show cc1aa864:scripts/lib/dev-cycle-read.sh`, the pre-split walk), and `$S/libs/mainalone.sh` (HEAD with all three checkout reads removed: the two listings replaced by `recs=(); low=()`, the `! -L "$p"` half of the link-text check removed, and the `:608` probe removed). "Main alone" below means that third lib.

---

## Claim 1: rubric split decision: "C2 ... fixed. A 160000 parent fails the walk like a 120000 one." "C4 ... fixed (`mapfile -d /` from a process substitution)." "C7 ... test 15: `want ... imported` after each failure, and a one-letter link two levels up." "C8 ... steps over `/` with `${c%/*}`." "C10 (nul_list partial array): fixed (emptied on failure)."

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md:6-17`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the code facts these five dispositions name; does not establish that the dispositions of C3, C9 and C12 (override rows) are right on the merits.

`scripts/lib/dev-cycle-read.sh:607`: `c="$p"; while [[ "$c" == */* ]]; do c="${c%/*}"; [[ ! "${ent[$c]:-}" =~ ^1[26]0000$ ]] || { IMPORTED_MAIN=error; return 1; }; done` (C2, C8). `:589`: `mapfile -t -d / parts < <(printf '%s' "$out")` (C4). `:517`: `... || { nl_a=(); return 1; }` (C10). Test 15 (`test/scripts/build-loop-check.bats:281-304`) follows each `want walk failed` with `want deep/... imported` and has `ln -s deep l && printf 'see @l/inner/i.md\n'` (C7). The suite passed.

Command: `TMPDIR=$S timeout 600 bats test/scripts/build-loop-check.bats`, cwd the worktree, exit 0, 2026-10-07T03:31:18Z, 16/16 ok.

**Evidence:** `scripts/lib/dev-cycle-read.sh:517`, `:589`, `:607`; `test/scripts/build-loop-check.bats:281-304`; `/tmp/u2a3-cfc2f-i2-x7bC/logs/blc.log`

---

## Claim 2: rubric Loop 2 rows E1-E6: "Test: test 3 stages CLAUDE.local.md; mutant killed." "Ignored instruction files fail the walk (35 in /workspace's own checkout)". "`160000) continue`, any other type fails the walk." "fixture `zz<LF>CLAUDE.md`; a 67 KB link under `ulimit -f 0` with XFSZ ignored ... isolated from the new index check; both mutants killed."

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md:31-36`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the code and test facts in E1, E2, E4, E5 and E6; does not establish that the index listing leaves the other shape tests pinned (it does not: Claim 23).

E1: `test/scripts/build-loop-check.bats:61` `git add -f CLAUDE.local.md; imps main docs/guide.md; want walk failed`. The mutant that replaces `:562` with `recs=()` fails test 3 only. E2: `git ls-files -z --others -- ':(glob,icase)**/*.md'` in /workspace, filtered by INSTRUCTION_FILE or `.claude/rules/`, gives 35 names, all under `devcontainer-config/claude-home/`, and `git check-ignore` reports all 35 as ignored (`.gitignore:52`). Each such name is a `t:` candidate that `:570` fails (`[[ "${cand[i]:0:1}" == m ]] || return 1`); probe scenario `ignored-rules` answers `failed`. E4: `:597-598` (Claim 19). E5: the here-string mutant at `:589` fails test 10 only, and the newline mutant at `:563` fails test 7 only. E6: the U2a3c bullet carries architecture L2 Findings 1 and 5 (Claim 9).

Commands (cwd `$S`, 2026-10-07T03:33:09Z): `./runm.sh $S/m-index`, `./runm.sh $S/m-herestr`, `./runm.sh $S/m-newline`. Each exits 1 because a test fails, which is the expected result. /workspace listing at about 03:36Z, exit 0.

**Evidence:** `scripts/lib/dev-cycle-read.sh:561-570`, `test/scripts/build-loop-check.bats:61`, `:148`, `:222-226`; `/tmp/u2a3-cfc2f-i2-x7bC/m-index.out`, `/tmp/u2a3-cfc2f-i2-x7bC/m-herestr.out`, `/tmp/u2a3-cfc2f-i2-x7bC/m-newline.out` (with `.diff`), `/tmp/u2a3-cfc2f-i2-x7bC/logs/ws-starts.txt`, `/tmp/u2a3-cfc2f-i2-x7bC/logs/probe.log`

---

## Claim 3: override row: "The parent-link loop ... is O(L x depth): a deep 64 KB `a/a/.../x.md` token takes 9-16 s ... Slow, never fail-open; only text committed to main reaches it after the split."

**Location:** `docs/reviews/override-log.md:386`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one 64 KB token at depth 32000 on this host and the input source of `:607`; does not establish the "one long segment is now 0.27-1 s" sub-figure (not run).

`:607` runs only for `p` read from `out`, and `out` is built from main's blob (`git cat-file blob "$MAIN_SHA:$f" | import_targets`) or main's link text (`:578-596`), so only text committed to main reaches it. A `CLAUDE.md` holding `@` followed by `a/` 32000 times and `x.md` took 11.82 s and answered `ok`.

Command: `timeout 300 $S/probe4.sh`, cwd `$S`, exit 0, 2026-10-07T03:40:15Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:575-608`; `/tmp/u2a3-cfc2f-i2-x7bC/probe4.sh`, `/tmp/u2a3-cfc2f-i2-x7bC/logs/probe4.log`

---

## Claim 4: override row: "the lib does not set GIT_NO_REPLACE_OBJECTS; build-loop.sh exports it"

**Location:** `docs/reviews/override-log.md:387`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where the variable is set; does not test the listed bypass candidates (GIT_INDEX_FILE, fsmonitor, replace refs, sparse checkout), which the row defers.

`grep -n GIT_NO_REPLACE_OBJECTS` finds only `scripts/build-loop.sh:118` (`export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1`) and nothing in the lib (paraphrased, no quote available because the claim is about an absence of matches).

**Evidence:** `scripts/build-loop.sh:118`, `scripts/lib/dev-cycle-read.sh` (no match)

---

## Claim 5: override row: "In a clean linked worktree `.git` is a file, so an instruction file importing `@.git` now fails the walk (pre-split it answered ok)"

**Location:** `docs/reviews/override-log.md:389`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `@.git` in a primary checkout and in a linked worktree, for HEAD and cc1aa864; does not verify the ~0.27 ms process-substitution figure.

Probe: main's `CLAUDE.md` holds `see @.git`. In the primary checkout HEAD and cc1aa864 both answer `ok: .git`. In a linked worktree HEAD answers `failed` and cc1aa864 answers `ok: .git`. HEAD's `:608` probe fails there because `.git` exists but is not a directory.

Command: `timeout 300 $S/probe4.sh`, cwd `$S`, exit 0, 2026-10-07T03:40:15Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:608`; `/tmp/u2a3-cfc2f-i2-x7bC/logs/probe4.log`

---

## Claim 6: override rows from 2b22a082 (C3, C9, C12): "After the split U2a3 reads no checkout content (a path there is only probed and fails the walk if present)"

**Location:** `docs/reviews/override-log.md:383-385`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the C3 row's description of the probe; does not re-measure C9's timing (loop 2 iteration 1 Claim 33 has it).

No checkout file content is read. A path main lacks is probed at `:608`, but a plain directory there passes (`[[ -d "$p" && ! -L "$p" && -z "$(blocker "$p" dir)" ]] || ...`), so "fails the walk if present" should say "unless it is a plain directory". Probe `lacked-plain-dir` answers `ok`. This repeats loop 2 iteration 1 Claim 32. The rows are Defer/Won't-Fix and the wording does not change their trigger.

**Evidence:** `scripts/lib/dev-cycle-read.sh:608`; `/tmp/u2a3-cfc2f-i2-x7bC/logs/probe.log` (`lacked-plain-dir`)

---

## Claim 7a: A5: "closes A2 and A3's symlinked-file half for the self-merge floor (symlinked start files and targets on main are followed, `.claude/rules/` at any depth starts, and odd names, link text that is empty, absolute, leaves the repo, holds a newline or NUL or has a `..` after a symlink, an imported path main lacks under a directory main stores as a symlink or gitlink fail it)"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the main-side shapes listed; does not establish that the tests isolate each refusal (Claim 23 shows three are no longer pinned).

`:569` admits `.claude/rules/*.md` and `*/.claude/rules/*.md`. The 120000 arm (`:578-596`) follows link text and refuses empty, newline, absolute and leaving text, a NUL (`tr -cd '\0' | wc -c`), and a `..` after a link. `:607` fails under a 120000/160000 parent. Probe3 isolates each refusal with the index synced to main and no checkout files: empty link text and NUL link text answer `failed` on HEAD. Tests 6, 7, 12 and 15 pass.

Command: `timeout 120 $S/probe3.sh`, cwd `$S`, exit 0, 2026-10-07T03:38:58Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:565-608`; `/tmp/u2a3-cfc2f-i2-x7bC/logs/probe3.log`, `/tmp/u2a3-cfc2f-i2-x7bC/logs/blc.log`

---

## Claim 7b: A5: "Until U2a3c the walk reads main's commit only and fails closed on the checkout: a start file main lacks (untracked, ignored, or only in the checkout's index), a link in link text, or anything but a plain directory at an imported path main lacks fails the walk"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** The Incorrect part is "a link in link text ... fails the walk". The start-file and plain-directory parts are Verified (Claims 12 and 17). This verdict does not establish a fail-open relative to main alone: Claim 12 found none.

A checkout link inside link text only sets a flag: `:593` `[[ "${ent[$p]:-}" != 120000 && ! -L "$p" ]] || lk=1`. The walk fails only when a `..` follows: `:591` `[[ "$c" != .. || -z "$lk" ]] || { IMPORTED_MAIN=error; return 1; }`. Probe2 case A: main stores `CLAUDE.md -> ld/i.md` with `ld/` a plain directory. When the checkout swaps `ld` for a link to `other/`, whose `i.md` imports `../docs/e.md`, HEAD still answers `ok: ld/i.md`. Case B is `ld/../docs/n.md` with a checkout link `ld`, and it answers `failed`. The lib's own wording at `:457-458` is precise: "has a .. after a symlink (on main or in the checkout)". This phrase was added to A5 in dfeeb85d. A reader could take it to mean the gate refuses a checkout whose directories along link text were swapped for links. It does not: those paths are read from main's blobs.

Command: `timeout 120 $S/probe2.sh`, cwd `$S`, exit 0, 2026-10-07T03:36:05Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:587-596`, `docs/working/known-issues-dev-cycle.md:18`; `/tmp/u2a3-cfc2f-i2-x7bC/probe2.sh`, `/tmp/u2a3-cfc2f-i2-x7bC/logs/probe2.log`

---

## Claim 7c: A5: "A developer checkout with ignored instruction files (here, `devcontainer-config/claude-home/`) therefore always fails it; the gate needs a fresh worktree until U2a3c."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers /workspace's checkout as of 03:36Z and the code path that fails it; does not run `main_imports` inside /workspace's shared checkout. The path was inferred from `:561`/`:570` and the `ignored-rules` probe.

The 35 start-shaped untracked names in /workspace are all ignored and all sit under `devcontainer-config/claude-home/` (Claim 2). `untracked_md` lists ignored files (`:515` `git ls-files -z --others` without `--exclude-standard`), and `:570` fails on any such start.

**Evidence:** `scripts/lib/dev-cycle-read.sh:515`, `:570`; `/tmp/u2a3-cfc2f-i2-x7bC/logs/ws-starts.txt`, `/tmp/u2a3-cfc2f-i2-x7bC/logs/probe.log`

---

## Claim 7d: A5: "a path main lacks that the checkout does not hold is recorded but not walked." / "Not covered: start files under a symlinked directory or in a submodule or untracked nested repo (neither `ls-tree -r` nor `ls-files --others` enters one), other names one file has on a case-insensitive checkout, and absolute imports into the repo."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the absent-path record and the untracked-nested-repo gap. Two further cases are not established: Claude Code's behavior (the three untraced shapes) and the case-insensitive-filesystem gap, which was not run on such a filesystem.

`:602` records the path before the main-lacks branch: `IMPORTED_MAIN+="$(lower "$p")"$'\n'`. `:608` passes when `[[ ! -e "$p" && ! -L "$p" ]]`, and nothing queues it. Probe `lacked-absent` answers `ok: docs/new.md`. Probe `untracked-nested-repo` answers `ok` without the nested `CLAUDE.md`'s import on all three libs. A related shape: `core.ignorecase=true` on a case-sensitive filesystem hides an untracked `claude.md` from `ls-files --others` (probe `ignorecase-untracked-variant`, `ok` on all three libs). That falls under the "case-insensitive" gap and the loop 2 bypass row (`override-log.md:387`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:599-608`; `/tmp/u2a3-cfc2f-i2-x7bC/logs/probe.log`

---

## Claim 8: plan F11: "a doubled name, a name holding a newline, link text that is empty, absolute, leaves the repo, holds a newline or NUL or has a `..` after a symlink, or an imported path main lacks under a directory main stores as a symlink or gitlink fails the walk ... Until U2a3c it fails closed on the checkout: a start file main lacks (untracked, ignored, or only in the checkout's index), or anything but a plain directory at an imported path main lacks, fails the walk, so the gate needs a fresh worktree (U2b) ... Gaps: known issue A5 (... three shapes untraced against Claude Code)."

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusals and the checkout fail-closed list as code facts; does not establish U2a3c's future behavior ("only appends").

These match `:555-570`, `:578-598` and `:607-608`, and probes `untracked-start`, `index-only-start`, `ignored-rules`, `checkout-file-at-lacked` and `checkout-link-at-lacked` answer `failed` (paraphrased, no quote available because the claim spans the whole of `main_imports`, which Claims 12 and 17 quote). F11 omits the `..` after a checkout link, but its main list already names "a `..` after a symlink".

**Evidence:** `scripts/lib/dev-cycle-read.sh:546-611`; `/tmp/u2a3-cfc2f-i2-x7bC/logs/probe.log`

---

## Claim 9: plan U2a3 and U2a3c bullets: "started from main's instruction files and `.claude/rules/` ... fails closed on the checkout (a start file main lacks, or anything but a plain directory at an imported path main lacks)"; U2a3c: "One drain loop run over two seedings ... every phase-2 item passes one admission check ... (U2a3 L2 architecture F1, F5)."

**Location:** `docs/working/plan-build-loop-handoff.md:276-277`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the U2a3 bullet against the code and the U2a3c bullet's citation; does not verify U2a3c, which is not built.

The U2a3 bullet matches `:565-570` and `:608`. `architecture-review-review-2026-10-06-L2-build-loop-u2a3.md:150` (Finding 1: "every phase-2 item passes one admission predicate") and `:154` (Finding 5: "Build it as one drain loop over two seedings") are the cited sources.

**Evidence:** `scripts/lib/dev-cycle-read.sh:565-570`, `:608`; `docs/reviews/architecture-review-review-2026-10-06-L2-build-loop-u2a3.md:150`, `:154`

---

## Claim 10: plan U2b bullet: "a fresh worktree at MAIN_SHA, since until U2a3c the walk fails on any start file main lacks, ignored ones included, and on checkout content at paths main lacks."

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two failure causes named; does not establish that a fresh worktree is free of other failures (Claim 5: `@.git` fails in any linked worktree).

The start-file half is exact (`:570`; probe `ignored-rules`). "Checkout content at paths main lacks" is broader than the code. A plain directory there passes even when it holds files (`:608` first clause; probe `lacked-plain-dir`). The precise version: "anything but a plain directory at a path main lacks".

**Evidence:** `scripts/lib/dev-cycle-read.sh:570`, `:608`; `/tmp/u2a3-cfc2f-i2-x7bC/logs/probe.log`

---

## Claim 11: header Inputs: "and so does main_imports (it reads the checkout only to fail, until U2a3c, so the gate needs a fresh worktree; the block above IMPORTED= lists each case; it needs resolve_main to have found main by name)"

**Location:** `scripts/lib/dev-cycle-read.sh:29-35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers "reads the checkout only to fail" (every checkout read can only add a failure) and the main-by-name precondition. The block's list omits two runtime failures, the index listing and an unmodelled record type (Claim 16), and this verdict does not cover them.

Reading the code: the checkout is consulted at `:561-563` (listings: only add `t:` candidates, which `:570` fails, or `return 1`), `:593` (`! -L "$p"`: only sets `lk`, which can only fail at `:591`) and `:608` (only fails). Run: across the 22 probe states, whenever HEAD answers `ok` its import set equals main alone's (Claim 12). `:552` `main_by_name || return 1`, and test 4's no-main case answers `failed`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:552`, `:561-570`, `:589-593`, `:608`; `/tmp/u2a3-cfc2f-i2-x7bC/logs/probe.log`

---

## Claim 12: block comment: the refusal list ("a doubled name, a name holding a newline, symlink text that is empty, absolute, leaves the repo, holds a newline or a NUL, or has a .. after a symlink (on main or in the checkout), an imported path main lacks that lies under a directory main stores as a symlink or gitlink, or that the checkout holds as anything but a plain directory (the root itself included), and a start file main lacks (untracked, ignored, or in the checkout's index) fail the walk, so isimported main answers imported for every path. Checkout files are not walked until U2a3c, so the walk fails closed on them.")

**Location:** `scripts/lib/dev-cycle-read.sh:452-466`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed refusal and the fail-closed invariant against main alone and against cc1aa864 over 22 checkout states and 4 link states. It does not prove the invariant for every possible state; the static argument in Claim 11 covers the rest. It also does not cover the git-hardening bypasses the loop 2 row defers to U2b.

Probe results: HEAD answered `ok` in 12 states. In every one of them its recorded set contained every path main alone and cc1aa864 recorded (no `MISS` line). The `failed` states are the ones the comment names: untracked start, index-only start (also with the working-tree copy deleted, and with skip-worktree), ignored rules file, a start on another branch's index, a checkout file or link at a path main lacks, and `@.` (the root). In the root case `blocker . dir` prints `./`, because `realpath -e .` is `$ROOT_REAL`, not `$ROOT_REAL/.`. cc1aa864 recorded more paths than HEAD only where HEAD fails, for example `untracked-start` cc=`docs/x.md`. That is the fail-closed direction. Isolated shape refusals: Claim 7a.

```bash
# scripts/lib/dev-cycle-read.sh:606-608
      # Main lacks p: under a link or gitlink main stores, or in the checkout as anything but a plain directory, fail.
      c="$p"; while [[ "$c" == */* ]]; do c="${c%/*}"; [[ ! "${ent[$c]:-}" =~ ^1[26]0000$ ]] || { IMPORTED_MAIN=error; return 1; }; done
      [[ -d "$p" && ! -L "$p" && -z "$(blocker "$p" dir)" ]] || [[ ! -e "$p" && ! -L "$p" ]] || { IMPORTED_MAIN=error; return 1; }
```
(excerpt ends :608; enclosing read loop closes at :609, drain loop at :610, `main_imports` at :611 — read)

Command: `timeout 300 $S/probe.sh`, cwd `$S`, exit 0, 2026-10-07T03:35:30Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:546-611`, `:110-121`; `/tmp/u2a3-cfc2f-i2-x7bC/probe.sh`, `/tmp/u2a3-cfc2f-i2-x7bC/logs/probe.log`

---

## Claim 13: block comment: "A start file answers imported only when an import reaches it ... Not covered (known issue A5): start files under a symlinked directory or in a submodule or untracked nested repo, other names one file has on a case-insensitive checkout, absolute imports, and three shapes A5 lists as untraced against Claude Code."

**Location:** `scripts/lib/dev-cycle-read.sh:466-469`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the start-file answer (test 3: `CLAUDE.md -`) and the nested-repo gap (probe); does not trace Claude Code's own behavior.

`:571` seeds `seen` and the queue but never writes a start into `IMPORTED_MAIN`; only `:602` writes, for imported paths. Test 3 asserts `want CLAUDE.md -`. A5 lists exactly three untraced shapes. `import_targets` drops absolute paths (`:500` `"$t" != /*`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:500`, `:571`, `:602`; `test/scripts/build-loop-check.bats:58`; `docs/working/known-issues-dev-cycle.md:18`; `/tmp/u2a3-cfc2f-i2-x7bC/logs/probe.log`

---

## Claim 14: cache sentence: "IMPORTED_MAIN reads "error" until a walk succeeds; the result is cached for the commit, MAIN_BY_NAME and root in IMPORTED_MAIN_DONE, so a caller whose checkout changes between calls sets IMPORTED_MAIN_DONE="" to walk again."

**Location:** `scripts/lib/dev-cycle-read.sh:470-472`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the key and the value after return. It does not cover the transient `$'\n'` value that `IMPORTED_MAIN` holds mid-walk (`:574`); the existing errexit override row covers that, and every drain-loop failure resets the value to error before it returns.

`:550-551`: `[[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }` then `IMPORTED_MAIN=error; IMPORTED_MAIN_DONE=...`. Test 16 passes. It checks a new commit, a failed walk staying failed, and `MAIN_BY_NAME=""`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:550-551`, `:574`; `test/scripts/build-loop-check.bats:306-315`; `/tmp/u2a3-cfc2f-i2-x7bC/logs/blc.log`

---

## Claim 15: "nul_list NAME CMD...: array NAME gets CMD's NUL-split output, or is emptied and 1 unless CMD exited 0 and its output ended in NUL."

**Location:** `scripts/lib/dev-cycle-read.sh:516`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers empty, terminated, unterminated and failing output; does not cover a CMD whose own stdout contains the literal `rc=0` as its last field (not probed).

Run results: `printf "p\0q\0"` gives rc 0 and 2 elements. `printf "p\0q"` gives rc 1 and the array emptied. `false` gives rc 1 and the array emptied. `printf ""` gives rc 0 and an empty array, so empty output also succeeds, though it does not end in NUL. Precise version: "unless CMD exited 0 and its output is empty or ends in NUL". Every caller treats an empty listing as valid, so nothing is misread.

Command: `timeout 30 env LC_ALL=C bash -c '...nul_list...' _ $S/tree-HEAD/scripts/lib/dev-cycle-read.sh`, cwd `$S`, exit 0, 2026-10-07T03:40:47Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:517`; `/tmp/u2a3-cfc2f-i2-x7bC/logs/nul_list.log`

---

## Claim 16: return-1 comment: "returns 1, with IMPORTED_MAIN set to "error", ... when main is not found by name, the commit's tree or the untracked list cannot be listed whole (nul_list), a tree record does not parse, a name is listed twice ... or holds a newline, the lower-cased start list comes back short, a start file main lacks exists, a blob cannot be read, symlink text it follows is empty, absolute, leaves the repo, holds a newline or a NUL, or has a .. after a symlink, or an imported path main lacks lies under a directory main stores as a symlink or gitlink or exists in the checkout as anything but a plain directory below the root; need_root exits instead."

**Location:** `scripts/lib/dev-cycle-read.sh:536-545`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `return 1` in `main_imports` (`:546-611`). It does not establish that the two omitted paths are reachable through normal git.

Every listed cause maps to a `return 1`. Two code paths are missing from the list:
1. `:562` `nul_list recs env GIT_LITERAL_PATHSPECS=0 git ls-files -z --cached -- ':(glob,icase)**/*.md' || return 1`. The checkout's tracked list is a third listing, but the comment names only "the commit's tree or the untracked list". In practice a broken index fails `:561` first.
2. `:598` `*) IMPORTED_MAIN=error; return 1 ;;`, an unmodelled record type. git canonicalizes tree modes on read. Raw trees with modes 100664 and 100600 list as `100644 blob`, and 644 and 0 list as `160000 commit`, so `ls-tree -r` never yields another type and the arm is defensive.

The precise version adds "the checkout's tracked list" to the listings and "a record of another type" to the causes.

Command: `$S/p-mode` raw-tree probe (`git hash-object -t tree --literally` + `git ls-tree -r -z`), cwd `$S/p-mode`, exit 0, about 03:34Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:536-545`, `:546-611`; probe output reproduced in this claim's prose (no log file: run inline; rerun with the command above)

---

## Claim 17: index listing: start files the checkout's index tracks but main lacks fail the walk (`:561-563`, `:570`)

**Location:** `scripts/lib/dev-cycle-read.sh:561-570`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers index-only starts: staged, staged then deleted from the working tree, skip-worktree, and a checkout on another branch. It does not cover GIT_INDEX_FILE, which the U2b row defers.

`:563` `[[ -n "${ent[$f]+set}" ]] || cand+=("t:$f")` and `:570` `[[ "${cand[i]:0:1}" == m ]] || return 1`. Probes `index-only-start`, `index-only-start-wt-deleted`, `index-only-skip-worktree` and `on-other-branch-with-new-start` all answer `failed` on HEAD and `ok` on cc1aa864 without the start's import. The `m-index` mutant fails test 3.

**Evidence:** `scripts/lib/dev-cycle-read.sh:561-570`; `/tmp/u2a3-cfc2f-i2-x7bC/logs/probe.log`, `/tmp/u2a3-cfc2f-i2-x7bC/m-index.out`

---

## Claim 18: link-text split and comment: "realpath -s reads x/.. as nothing, but the kernel follows a symlink x first: a .. after a symlink on main or in the checkout fails." (`mapfile -t -d / parts < <(printf '%s' "$out")`)

**Location:** `scripts/lib/dev-cycle-read.sh:587-596`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a `..` after a link on main or in the checkout and link text past 64 KiB; does not establish that a checkout link without a following `..` fails (it does not: Claim 7b).

Test 15 passes. The here-string revert fails test 10 (Claim 2). Probe2 case B answers `failed`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:587-596`; `/tmp/u2a3-cfc2f-i2-x7bC/m-herestr.out`, `/tmp/u2a3-cfc2f-i2-x7bC/logs/probe2.log`

---

## Claim 19: `160000) continue ;;  # a gitlink: its files are not main's` / `*) IMPORTED_MAIN=error; return 1 ;;`

**Location:** `scripts/lib/dev-cycle-read.sh:597-598`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the arms as written. It does not establish test coverage: no test pins the `*)` arm, and the `*) continue` revert mutant (`m-gitcont`) passes 16/16. git's mode canonicalization makes the arm unreachable from a real tree (Claim 16).

`./runm.sh $S/m-gitcont`, cwd `$S`, exit 0 (all pass), 2026-10-07T03:33:09Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:597-598`; `/tmp/u2a3-cfc2f-i2-x7bC/m-gitcont.out`, `/tmp/u2a3-cfc2f-i2-x7bC/m-gitcont.diff`

---

## Claim 20: parent check: "Main lacks p: under a link or gitlink main stores, or in the checkout as anything but a plain directory, fail." (`${c%/*}` loop, `^1[26]0000$`)

**Location:** `scripts/lib/dev-cycle-read.sh:606-608`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every proper ancestor of `p` (the loop strips one component per step until no `/` remains) and the two modes. It does not establish the cost, which the O(L x depth) row covers (Claim 3).

Quoted in Claim 12. Test 12 (gitlink parent) and test 15 (link parents, including a one-letter link two levels up) pass. Probes `checkout-file-at-lacked` and `checkout-link-at-lacked` answer `failed`, and `lacked-plain-dir` answers `ok`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:606-608`; `/tmp/u2a3-cfc2f-i2-x7bC/logs/blc.log`, `/tmp/u2a3-cfc2f-i2-x7bC/logs/probe.log`

---

## Claim 21: isimported: "A failed main walk, or a walk name that is neither, answers imported (0), so a caller testing it with `if` refuses; a caller that words a failed walk runs main_imports first. Run it in the caller's shell: the walk exits through need_root and caches its result."

**Location:** `scripts/lib/dev-cycle-read.sh:612-616`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `main` and unknown-name arms; does not re-verify the `tree` arm (U2a2's).

`:622` `main) main_imports || return 0; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]] ;;` and `*) return 0 ;;`. Tests 2, 8 and 14 pass, including under `set -eu` without pipefail.

**Evidence:** `scripts/lib/dev-cycle-read.sh:617-626`; `/tmp/u2a3-cfc2f-i2-x7bC/logs/blc.log`

---

## Claim 22: test 3: "main's instruction files start it; a working-tree edit does not count; an untracked start or a checkout file at a path main lacks fails it until U2a3c"

**Location:** `test/scripts/build-loop-check.bats:46-62`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the name's claims and the index-only line at `:61`, which the name does not mention; does not establish that each failure is isolated, since `:59` and `:60` could each also be caught by the other check. The `m-index` mutant pins `:61`.

Body: `:59` docs/new.md file gives `walk failed`, `:60` untracked CLAUDE.local.md gives `walk failed`, and `:61` `git add -f` gives `walk failed`. Test 3 passes, and `m-index` fails it.

**Evidence:** `test/scripts/build-loop-check.bats:46-62`; `/tmp/u2a3-cfc2f-i2-x7bC/m-index.out`

---

## Claim 23: tests 5, 9 and 12 pin their shape refusals: "a name the tree lists twice, or any name holding a newline, fails the walk" (`:102-113`); "fails on symlink text holding a NUL" (`:196-200`); "empty link text below the top level" (`:250-254`)

**Location:** `test/scripts/build-loop-check.bats:82`, `:175`, `:240`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether these tests still fail when the named check is removed. HEAD's code does refuse all three shapes (probe3, Claim 7a), so this verdict says nothing against the lib. The doubled-name part of test 5 is still pinned: `m-dup` fails test 5 through the first `docs/a.md` case at `:88`.

dfeeb85d added the index listing (`:562`). These three tests build main with `git update-ref refs/heads/main "$(git commit-tree ...)"` (`:109`, `:199`, `:253`) and leave the index at an older commit. That index holds a `CLAUDE.md` the new tree lacks, so every walk after those lines fails as an index-only start, whatever the shape. Three mutants pass all 16 tests at HEAD:
- `m-treenl`: the tree-name newline half of `:557` removed.
- `m-nul`: the `|| [[ "$i" -ne 0 ]]` NUL count removed.
- `m-empty`: the `-z "$out"` empty check removed.

The same mutants on 2b22a082's tree fail tests 5, 9 and 12 respectively. Combining each with `m-index` (the index listing removed) makes them fail tests 5, 9 and 12 again at HEAD, which confirms the index check is the mask. In probe3 (index synced to main, no checkout files) HEAD refuses empty and NUL link text, and `m-empty` and `m-nul` answer `ok: sub` and `ok: docs/rules.mdzzz`. The fix the commit itself used for the new link case is `rm -r docs; git read-tree main` at `:224`. Only that one case got it. dfeeb85d says it is "isolated from the new index check".

Commands (cwd `$S`): `./runm.sh $S/m-{treenl,nul,empty}` (exit 0, 03:38:17Z), `./runm.sh $S/m-* 2b22a082` saved as `old-m-*` (exit 1, fails 5 / 9 / 12, 03:38:00Z), `./runm.sh $S/c-*` (exit 1, fails 3+5 / 3+9 / 3+12, 03:38:38Z), `timeout 120 $S/probe3.sh` (exit 0, 03:38:58Z).

**Evidence:** `test/scripts/build-loop-check.bats:102-113`, `:196-200`, `:250-254`, `:224`; `scripts/lib/dev-cycle-read.sh:557`, `:583`, `:586`; `/tmp/u2a3-cfc2f-i2-x7bC/m-treenl.out`, `/tmp/u2a3-cfc2f-i2-x7bC/m-nul.out`, `/tmp/u2a3-cfc2f-i2-x7bC/m-empty.out`, `/tmp/u2a3-cfc2f-i2-x7bC/old-m-treenl.out`, `/tmp/u2a3-cfc2f-i2-x7bC/old-m-nul.out`, `/tmp/u2a3-cfc2f-i2-x7bC/old-m-empty.out`, `/tmp/u2a3-cfc2f-i2-x7bC/c-treenl.out`, `/tmp/u2a3-cfc2f-i2-x7bC/c-nul.out`, `/tmp/u2a3-cfc2f-i2-x7bC/c-empty.out`, `/tmp/u2a3-cfc2f-i2-x7bC/logs/probe3.log`

---

## Claim 24: test 7 comment: "An untracked name holding a newline fails the walk." (fixture `zz<LF>CLAUDE.md`)

**Location:** `test/scripts/build-loop-check.bats:147-151`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listing newline check at `:563`; does not cover the tree-name newline check (Claim 23).

The `m-newline` mutant (check removed from `:563`) fails test 7 only. The fixture is not start-shaped: `${f##*/}` keeps `zz<LF>` and INSTRUCTION_FILE is anchored, so only `:563` refuses it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:563`, `:569`; `/tmp/u2a3-cfc2f-i2-x7bC/m-newline.out`

---

## Claim 25: test 9 name: "main walk fails on symlink text holding a NUL, on a checkout symlink or file at a path main lacks, and on an untracked start"

**Location:** `test/scripts/build-loop-check.bats:175`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the body sets up; the NUL part's pinning is Claim 23.

The body has a checkout symlink at a path main lacks (`:186` `ln -s rules.md docs/lt.md`), untracked starts (`:188`, `:191`) and a plain directory that passes (`:194`). It has no regular checkout file at an imported path main lacks. That case is in test 3 (`:59`). Either "or file" should go, or test 9 should add one.

**Evidence:** `test/scripts/build-loop-check.bats:175-201`, `:59`

---

## Claim 26: test 10 comment: "Link text past 64 KiB with a .. after main's link l, under ulimit -f 0: the .. check reads it whole (loop 1 C4; XFSZ ignored, so a failed temp write returns, as a full disk does)."

**Location:** `test/scripts/build-loop-check.bats:222-226`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the size and that the case pins the split; does not establish behavior with default XFSZ handling (the shell would be killed, which the comment does not claim).

The text is 270 × 254 + 9 = 68,589 bytes (67 KiB, computed with python3), and `l` is a 120000 link on main. `git read-tree main` at `:224` isolates the case from the index check. The `m-herestr` mutant fails test 10.

**Evidence:** `test/scripts/build-loop-check.bats:222-226`; `/tmp/u2a3-cfc2f-i2-x7bC/m-herestr.out`

---

## Claim 27: remaining test names (tests 4, 6, 8, 11, 13, 14, 15, 16) assert what they say

**Location:** `test/scripts/build-loop-check.bats:64`, `:115`, `:163`, `:229`, `:260`, `:271`, `:281`, `:306`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that each body exercises its named case and passes. Mutation was not run for each named check, so only test 12's gitlink half, the cases in Claims 22-26, and test 15 (killed by the parent mutants in loop 2 iteration 1 Claim 20) are known to be isolated.

All 16 pass. Test 12's gitlink case keeps `CLAUDE.md` on main, so the index check does not mask it (paraphrased, no quote available because the claim spans eight test bodies, each read in full).

**Evidence:** `test/scripts/build-loop-check.bats:64-316`; `/tmp/u2a3-cfc2f-i2-x7bC/logs/blc.log`

---

## Claim 28: dev-cycle.bats: the sourcing test lists `main_imports`, `nul_list`, `IMPORTED_MAIN` and `IMPORTED_MAIN_DONE`

**Location:** `test/scripts/dev-cycle.bats:1086`, `:1090`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the names being defined at source time; does not cover the test's "calls neither git nor perl" half beyond its passing.

The five suites (dev-cycle, build-loop-read, build-loop-check, fixture-git-env, `test/fixture-hermeticity.bats`) give 114 ok, 0 not ok.

Command: `TMPDIR=$S timeout 900 bats test/scripts/dev-cycle.bats test/scripts/build-loop-read.bats test/scripts/build-loop-check.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats`, cwd the worktree, exit 0, 2026-10-07T03:32:10Z.

**Evidence:** `test/scripts/dev-cycle.bats:1086`, `:1090`; `/tmp/u2a3-cfc2f-i2-x7bC/logs/five.log`

---

## Claim 29: dfeeb85d E1, E2, E3, E4, E6: "The walk now also lists the checkout's tracked .md files; a start-shaped one main lacks fails the walk, as an untracked or ignored one does. Until U2a3c the gate therefore needs a fresh worktree (E2): header, A5, F11 and the U2b bullet say so." "a gitlink continues and any other type fails the walk" "dev-cycle.bats lists nul_list" "the plan's U2a3c bullet carries architecture F1 and F5"

**Location:** commit dfeeb85d (body)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these bullets; E5 is Claims 30a/30b. "E7-E10: override rows": the rows exist (`override-log.md:386-389`), but they landed in 0032ed5a, not in this commit, and the message does not say otherwise.

See Claims 17, 11, 7c, 8, 10, 19, 28 and 9.

**Evidence:** `scripts/lib/dev-cycle-read.sh:32-34`, `:561-570`, `:597-598`; `docs/working/known-issues-dev-cycle.md:18`; `docs/working/plan-build-loop-handoff.md:126`, `:277`, `:279`; `test/scripts/dev-cycle.bats:1086`

---

## Claim 30a: dfeeb85d E5: "test 7's newline fixture is a start name"

**Location:** commit dfeeb85d (body, E5)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk's classification of `zz<LF>CLAUDE.md`; does not judge the fixture choice, which is correct for its purpose.

The fixture was chosen because it is not a start. Test-strategy L2 G1 says "That name is not a start, because the basename regex is anchored and `${f##*/}` keeps the `zz<LF>` prefix, so only :562 refuses it" (`docs/reviews/test-strategy-review-2026-10-06-L2-build-loop-u2a3.md:29`). The `m-newline` mutant fails test 7. If the name were a start, `:570` would still fail the walk and the mutant would survive. This message is immutable, so an Accepted-immutable row is the route.

**Evidence:** `scripts/lib/dev-cycle-read.sh:569-570`; `docs/reviews/test-strategy-review-2026-10-06-L2-build-loop-u2a3.md:29`; `/tmp/u2a3-cfc2f-i2-x7bC/m-newline.out`

---

## Claim 30b: dfeeb85d E5: "tests 9 and 3 renamed for the split"

**Location:** commit dfeeb85d (body, E5)
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the `@test` lines changed by dfeeb85d; does not concern test 3's body, which dfeeb85d extended (`:61`).

`git diff 2b22a082 dfeeb85d -- test/scripts/build-loop-check.bats` changes one `@test` line, test 9's. Test 3's name is the same at 5c57d367 and dfeeb85d (paraphrased, no quote available because the claim is about which lines a diff touches). Test 3 got a new body line, and its name does not mention the index-only start that line tests.

**Evidence:** `test/scripts/build-loop-check.bats:46`, `:61`, `:175`; `git diff 2b22a082 dfeeb85d -- test/scripts/build-loop-check.bats`

---

## Claim 31: dfeeb85d figures: "Tests: build-loop-check.bats 16; 114 across the five suites. Mutants of the index listing, the link-text split (here-string revert) and the newline check each fail. 400 changed code lines against main."

**Location:** commit dfeeb85d (body, Tests paragraph)
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts, the line total and my constructions of the three mutants. It does not establish that the other shape checks stay pinned after this commit (Claim 23).

`grep -c '^@test'` over the five suites at dfeeb85d gives 114, and 16 for build-loop-check. Both runs pass (Claims 1, 28). `git diff --numstat main...dfeeb85d -- . ':!docs'` gives 113+9, 272+2 and 2+2, a total of 400 (the same at HEAD). Mutants: `m-index` fails 3, `m-herestr` fails 10, `m-newline` fails 7.

**Evidence:** `/tmp/u2a3-cfc2f-i2-x7bC/logs/five.log`, `/tmp/u2a3-cfc2f-i2-x7bC/m-index.out`, `/tmp/u2a3-cfc2f-i2-x7bC/m-herestr.out`, `/tmp/u2a3-cfc2f-i2-x7bC/m-newline.out`

---

## Claim 32: 2b22a082 figures: "build-loop-check.bats 16; 114 across the five suites. ... 392 changed code lines against main."

**Location:** commit 2b22a082 (body, Tests paragraph)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts and line total. For the six named mutants and the headline, see loop 2 iteration 1 Claims 15, 16 and 20 and the Accepted-immutable row at `override-log.md:388` (pointer only). That pass found the here-string revert survived at 2b22a082, and dfeeb85d pinned it.

`grep -c '^@test'` at 2b22a082 gives 16 and 114. The numstat total is 111+9 + 266+2 + 2+2 = 392.

**Evidence:** `git show 2b22a082:<suite>`, `git diff --numstat main...2b22a082 -- . ':!docs'`; `docs/reviews/code-fact-check-report-build-loop-u2a3-L2.md:337-348`

---

## Claim 33: docs(reviews) commits: 5c57d367 and 1898d21c "fix-drift output ... (no findings)"; 0032ed5a "U2a3 loop 2 iteration 1 fact-check, critic reports, rubric and override rows"

**Location:** commits 5c57d367, 0032ed5a, 1898d21c
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what each commit adds; does not re-run the fix-drift reviewer.

`docs/reviews/lite-review-fix-drift-build-loop-u2a3-split.txt` and `...-L2i1.txt` each read `lite-review [fix-drift]: FINDINGS: NONE`. 0032ed5a adds the L2 fact-check, five critic reports, the rubric's Loop 2 section and four override rows (`git show --stat`).

**Evidence:** `docs/reviews/lite-review-fix-drift-build-loop-u2a3-split.txt:1`, `docs/reviews/lite-review-fix-drift-build-loop-u2a3-L2i1.txt:1`; `git show --stat 0032ed5a`

---

## Claims Requiring Attention

### Incorrect
- **Claim 7b** (`docs/working/known-issues-dev-cycle.md:18`): "a link in link text ... fails the walk". Only a `..` after a checkout link fails it. A checkout link with no `..` after it answers `ok` (probe2 case A). Reword to "a `..` after a checkout link in link text".
- **Claim 23** (`test/scripts/build-loop-check.bats:109`, `:199`, `:253`): since dfeeb85d's index listing, tests 5 (tree-name newline), 9 (NUL link text) and 12 (empty link text) fail as index-only starts. The stale index holds `CLAUDE.md`. Mutants removing each check pass 16/16 at HEAD; at 2b22a082 they were killed. Add `git read-tree main` after those `update-ref` lines, as `:224` does.
- **Claim 30a** (commit dfeeb85d): "test 7's newline fixture is a start name". It is deliberately not a start. Immutable: Accepted-immutable row.
- **Claim 30b** (commit dfeeb85d): "tests 9 and 3 renamed". Only test 9's name changed. Immutable: same row.

### Mostly Accurate
- **Claim 6** (`docs/reviews/override-log.md:383`): "fails the walk if present" should say "unless it is a plain directory" (repeat of loop 2 i1 Claim 32).
- **Claim 10** (`docs/working/plan-build-loop-handoff.md:279`): "checkout content at paths main lacks" should be "anything but a plain directory".
- **Claim 15** (`scripts/lib/dev-cycle-read.sh:516`): empty output also succeeds ("empty or ended in NUL").
- **Claim 16** (`scripts/lib/dev-cycle-read.sh:536-545`): two `return 1` causes are missing, the index listing (`:562`) and an unmodelled record type (`:598`, unreachable through git's mode canonicalization).
- **Claim 25** (`test/scripts/build-loop-check.bats:175`): test 9 has no regular checkout file at a path main lacks (that case is in test 3).

### Unverifiable
- (none)

## Escalations

- `test/scripts/build-loop-check.bats:109`, `:199`, `:253` → implementer and test-strategy: three refusals (`:557` tree-name newline half, `:583` NUL count, `:586` empty text) are unpinned at HEAD. dfeeb85d's index listing masks them, and the HEAD code is correct. This is the one item a reviewer might weigh as blocking for a "final confirming" pass: the next edit to the 120000 arm could drop either check silently. Suggested fix, at most 3 lines: `git read-tree main` after each of those `update-ref`s, then re-run `m-treenl`, `m-nul` and `m-empty` (diffs in `$S/m-*.diff`).
- `docs/working/known-issues-dev-cycle.md:18` → implementer: "a link in link text" overstates the refusal (Claim 7b).
- `scripts/lib/dev-cycle-read.sh:536-545` → implementer: add the tracked-list failure and the other-record-type arm to the return-1 list, or note that the `*)` arm is defensive (Claim 16). `:598` → test-strategy (informational): the `*)` arm cannot be reached through git plumbing, which is why `m-gitcont` survives. That is acceptable, but the rubric's E4 "Fixed" has no test.
- commit dfeeb85d → rubric author: one Accepted-immutable row for Claims 30a and 30b.
- Fail-closed question (task item 1): over 22 checkout states and 4 link states, no state answered `ok` while missing an import that main alone or cc1aa864 records. No escalation.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A code-fact-check report verdicting every checkable claim in the U2a3 diff's comments, docs and commit messages, saved at the path given below."
- **Answered:** Items 1-6 of the task. The lib comments are checked against the full `main_imports` unit, with the fail-closed contract probed against main alone and cc1aa864 (no miss found). Also checked: the index listing, the `160000`/`*)` arms, the mapfile split and the parent loop; A5, F11 and the U2a3/U2a3c/U2b bullets; the figures and named mutants of dfeeb85d and 2b22a082 (all re-run); the test names, with three false passes found (Claim 23); and the rubric's split and Loop 2 sections and the loop 2 override rows.
- **Out of scope:** Claude Code's own loading behavior (A5's three untraced shapes); U2a3b's parser and fail-closed changes; commits before 0170f16a beyond pointers to their Accepted-immutable rows; the five non-fact-check critic reports' own findings.
- **Escalate:** the tests 5/9/12 masking (Claim 23) to the implementer before merge-readiness is decided; the A5 wording (7b) and the return-1 list (16) as wording fixes; one Accepted-immutable row for dfeeb85d (30a, 30b).
