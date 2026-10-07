Commit: 0bb98f27
# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u2a3`, branch `feat/build-loop-u2a3`)
**Scope:** `git diff main...HEAD` (base 62d366a7, HEAD 0bb98f27): `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`, `docs/working/known-issues-dev-cycle.md` (A5), `docs/working/plan-build-loop-handoff.md` (F11, U2a3/U2a3c/U2b bullets), the rubric's Loop 2 sections and the override rows added since 0170f16a, and commit messages 0170f16a..0bb98f27. Loop 2 iteration 3 (final confirming pass), replicate cfc3 (role `cfc3`, pass `i3`).
**Checked:** 2026-10-06 (probe clock 2026-10-07T04:03Z-04:13Z UTC)
**Total claims checked:** 39
**Summary:** 37 verified, 2 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`); no claim here matches a logged pattern, and no fabricated symbol was found.

Execution environment for every `executed` claim: scratch dir `/tmp/u2a3-cfc3-i3-irp4` (TMPDIR set to it or to a `run-XXXX` child); captured output under `/tmp/u2a3-cfc3-i3-irp4/logs/`. Helpers: `w.sh` (sources the worktree lib, runs `resolve_main`, sets ROOT_REAL, prints `walk: ok|failed` and `isimported main` per path), `mut.sh NAME OLD NEW` (copies HEAD's lib and tests into `mut/NAME`, applies one exact-once substitution to the copy, runs `bats build-loop-check.bats`), `mut-old.sh` (the same against a given revision's lib/tests). The worktree file was never edited.

Baseline runs:
- `TMPDIR=/tmp/u2a3-cfc3-i3-irp4 timeout 900 bats test/scripts/build-loop-check.bats` · cwd worktree · exit 0 · 2026-10-07T04:03:19Z · 17 ok · `logs/blc.txt`.
- dev-cycle.bats (75 ok), build-loop-read.bats (19 ok), fixture-git-env.bats (2 ok), test/fixture-hermeticity.bats (2 ok), each `TMPDIR=$(mktemp -d .../run-XXXX) timeout 1500 bats <suite>` · cwd worktree · each exit 0 · 2026-10-07T04:03:38Z-04:04:18Z · `logs/suites-rc.txt`, `logs/<suite>.txt`. Total 115.

---

## Claim 1: Rubric Loop 2 iteration 2: F1 "passed the doubled-name check: walk ok while a checkout writes the link ... Not a regression (same at cc1aa864)"; F2 "Three refusals masked since dfeeb85d's index listing ... tests 5, 9, 12"; F5 "The two listings are now one `--cached --others` call"; the override row "main:l/x.md read the tree's blob while a checkout writes the link"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md:31-35`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers F1's pre-fix fail-open (at 664c18fe and cc1aa864), the checkout writing the link, F2's masking of three mutants under 664c18fe's tests, and F5's single listing; does not establish the rubric's severity labels or the reviewer-attribution lists.

F1: test 17 from HEAD run against 664c18fe's lib fails at `want walk failed` with `walk: ok` / `docs/secret.md: -` (`logs/mut-old-lib-new-test17.txt`), and against cc1aa864's lib the same test prints `walk: ok` / `docs/secret.md: -` (`logs/mut-cc1-test17.txt`), so "not a regression" holds. In the same crafted tree, `git checkout -qf main` writes `l -> docs` while `git cat-file blob main:l/x.md` prints `plain` (`logs/mut-batch3.txt`). F2: the lib at 664c18fe with each of three mutants (tree-name newline check dropped, NUL count disabled, empty-text check dropped) passes all 16 of 664c18fe's tests (`logs/mut-old-treenl.txt`, `mut-old-nulcount.txt`, `mut-old-emptytext.txt`: 16 ok each), so those refusals were masked; at HEAD the same mutants fail tests 5, 9 and 12 (Claim 33). F5: `scripts/lib/dev-cycle-read.sh:566` reads `nul_list recs env GIT_LITERAL_PATHSPECS=0 git ls-files -z --cached --others -- ':(glob,icase)**/*.md' || return 1`.

Commands: `bash mut-old.sh old-lib-new-test17 664c18fe "" "" 0bb98f27` (exit 0 of the driver, bats rc=1), `bash mut-old.sh old-{treenl,nulcount,emptytext} 664c18fe ...` (bats rc=0 each) · cwd scratch · 2026-10-07T04:09:26Z; `bash probe-rubric.sh` (cc1aa864 run) · exit 0 · 2026-10-07T04:10:38Z; `bash mut-batch3.sh` · exit 0 · 2026-10-07T04:12:08Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:564-566`, `test/scripts/build-loop-check.bats:306-311`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-old-lib-new-test17.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-cc1-test17.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-rubric.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-batch3.txt`

---

## Claim 2: Rubric Loop 2 iteration 1: E1 (a start file only in the checkout's index was neither walked nor failed; now fails; "test 3 stages CLAUDE.local.md; mutant killed"), E2 ("35 in /workspace's own checkout"), E4 (`160000) continue`, any other type fails), E5 (fixture `zz<LF>CLAUDE.md`, a 67 KB link under `ulimit -f 0` with XFSZ ignored, "both mutants killed")

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md:49-53`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four rows' claims about the code and tests at HEAD and the current count of start-shaped untracked/ignored .md files in /workspace; does not establish the count at the time the row was written beyond its agreement with today's count.

E1: a mutant dropping `--cached` from `:566` fails test 3 at `git add -f CLAUDE.local.md; imps main docs/guide.md; want walk failed` with `walk: ok` (`logs/mut-indexhalf.txt`). E2: `git -C /workspace ls-files -z --others -- ':(glob,icase)**/*.md'` filtered to instruction-file and `.claude/rules/` names counts 35 (`logs/probe-rubric.txt`), the first being `devcontainer-config/claude-home/CLAUDE.md` (`logs/probe-own2.txt`). E4: `:601-602` read `160000) continue ;;  # a gitlink: its files are not main's` / `*) IMPORTED_MAIN=error; return 1 ;;`. E5: test 7 writes `printf 'x\n' > "zz"$'\n'"CLAUDE.md"` (`test/scripts/build-loop-check.bats:140`); test 10's link text is 270 x 254 + 9 = 68,589 bytes (66.98 KiB) and runs under `trap "" XFSZ; ulimit -f 0` (`:213-215`); the newline-check mutant fails test 7 (`logs/mut-checkoutnl.txt`) and the here-string revert (`mapfile -t -d / parts <<<"$out"`) fails test 10 (`logs/mut-herestring.txt`).

Commands: `bash mut-batch2.sh` · exit 0 · 2026-10-07T04:10:03Z; `bash mut-batch3.sh` · exit 0 · 2026-10-07T04:12:08Z; `bash probe-rubric.sh` · exit 0 · 2026-10-07T04:10:38Z; `$S/mut.sh indexhalf ...` · 2026-10-07T04:03:55Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:566-574`, `scripts/lib/dev-cycle-read.sh:601-602`, `test/scripts/build-loop-check.bats:140`, `test/scripts/build-loop-check.bats:211-216`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-indexhalf.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-checkoutnl.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-herestring.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-rubric.txt`

---

## Claim 3: Override row: "the lib does not set GIT_NO_REPLACE_OBJECTS; build-loop.sh exports it"

**Location:** `docs/reviews/override-log.md:387`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where the variable is set in the lib and build-loop.sh; does not establish whether replace refs can bypass the walk (the row's own Defer).

`grep -n GIT_NO_REPLACE_OBJECTS` over both files hits only `scripts/build-loop.sh:118`: `export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1`; the lib has no match (paraphrased — no quote available because the claim covers absence of code in the lib, no grep results).

**Evidence:** `scripts/build-loop.sh:118`, `scripts/lib/dev-cycle-read.sh` (no match), `/tmp/u2a3-cfc3-i3-irp4/logs/probe-rubric.txt`

---

## Claim 4: Override row: "In a clean linked worktree `.git` is a file, so an instruction file importing `@.git` now fails the walk"

**Location:** `docs/reviews/override-log.md:389`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a scratch repo whose AGENTS.md imports `@.git`, walked from its main checkout and from a linked worktree; does not establish the C9 cost figure in the same row.

In the linked worktree the walk prints `walk: failed` / `x.md: imported`; in the main checkout (where `.git` is a plain directory) `walk: ok` / `x.md: -` (`logs/probe-rubric.txt`). The failing arm is `:612`: `[[ -d "$p" && ! -L "$p" && -z "$(blocker "$p" dir)" ]] || [[ ! -e "$p" && ! -L "$p" ]] || { IMPORTED_MAIN=error; return 1; }`.

Command: `bash /tmp/u2a3-cfc3-i3-irp4/probe-rubric.sh` · cwd scratch · exit 0 · 2026-10-07T04:10:38Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:612`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-rubric.txt`

---

## Claim 5: Override row: "the `*)` record-type arm is unreachable (ls-tree canonicalises modes)"

**Location:** `docs/reviews/override-log.md:393`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers crafted trees with modes 100664 and 70000 written by `git hash-object -t tree --literally`; does not exhaust every 6-digit mode.

A start file stored with mode `100664` lists as `100644 blob ... CLAUDE.md` and the walk reads it (`walk: ok`, `docs/secret.md: imported`); one stored with mode `70000` lists as `160000 commit ... CLAUDE.md` and takes the gitlink arm (`logs/probe-craft.txt`, P7, P8). A mode-100644 entry naming a tree object reaches the walk as `100644 blob` and fails at `git cat-file blob` (P10: `walk: failed`), not at `*)`.

Command: `bash /tmp/u2a3-cfc3-i3-irp4/probe-craft.sh` · cwd scratch · exit 0 · 2026-10-07T04:07:46Z (rerun with per-repo blobs).

**Evidence:** `scripts/lib/dev-cycle-read.sh:582-603`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-craft.txt`

---

## Claim 6: Override row: dfeeb85d's "tests 9 and 3 renamed" — "(only test 9)"

**Location:** `docs/reviews/override-log.md:395`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `@test` names at 2b22a082 and dfeeb85d; does not re-verdict dfeeb85d's message (Accepted-immutable).

`diff` of the `@test` lines between 2b22a082 and dfeeb85d shows one change, test 9 (`logs/probe-rubric.txt`: `< ... on a checkout symlink it would read` / `> ... on a checkout symlink or file at a path main lacks, and on an untracked start`).

Command: `bash probe-rubric.sh` · exit 0 · 2026-10-07T04:10:38Z.

**Evidence:** `test/scripts/build-loop-check.bats:165`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-rubric.txt`

---

## Claim 7: A5: the walk follows symlinked start files and targets on main, starts `.claude/rules/` at any depth, and fails on "a name listed twice or as both a file and a directory, a name holding a newline", link text "that is empty, absolute, leaves the repo, holds a newline or NUL or has a `..` after a symlink", and "an imported path main lacks under a directory main stores as a symlink or gitlink"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed refusal (each has a mutant that the suite kills) and the follow/start behaviour of test 6; does not establish how Claude Code itself resolves the three untraced shapes A5 lists.

Mutants at HEAD each fail a named test: doubled name (dupname, test 5), file-and-directory (ancestor, test 17), tree-name newline (treenl, test 5), empty text (test 12), absolute text (test 7), leaves the repo (test 7), `..` after a symlink (lk, tests 10 and 15), NUL count (test 9), gitlink parent (test 12), parent loop limited to the immediate parent (test 15) (Claims 29, 33). The code: `:561` `[[ -z "${ent[$f]+set}" && "$f" != *$'\n'* ]] || return 1`; `:565` the ancestor pass; `:590` `if [[ -z "$out" || "$out" == *$'\n'* || "$out" == /* ]]`; `:595` `[[ "$c" != .. || -z "$lk" ]] || { IMPORTED_MAIN=error; return 1; }`; `:600` the leaves-repo check; `:611` `[[ ! "${ent[$c]:-}" =~ ^1[26]0000$ ]]`. Extra crafted shapes all fail: a slash-named root entry `l/x.md` beside a symlink `l` (P6c), a gitlink `sub` beside a tree `sub` (P9), two trees named `docs` with the start or the target in the second (P5, P5b, P5c) (`logs/probe-craft.txt`, `logs/probe-craft2.txt`).

Commands: `bash probe-craft.sh`, `bash probe-craft2.sh` · cwd scratch · exit 0 · 2026-10-07T04:07:37Z-04:08Z; mutant batches as in Claims 2 and 33.

**Evidence:** `scripts/lib/dev-cycle-read.sh:561-565`, `scripts/lib/dev-cycle-read.sh:587-600`, `scripts/lib/dev-cycle-read.sh:611`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-craft.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-craft2.txt`

---

## Claim 8: A5: "Until U2a3c the walk reads main's commit only and fails closed on the checkout: a start file main lacks (untracked, ignored, or only in the checkout's index), a `..` after a checkout link in link text, or anything but a plain directory at an imported path main lacks fails the walk ..., and a path main lacks that the checkout does not hold is recorded but not walked. A developer checkout with ignored instruction files (here, `devcontainer-config/claude-home/`) therefore always fails it"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers untracked, ignored (including inside an ignored directory and under `.claude/rules/` at depth), index-only and index-only-deleted starts, checkout links in link text, FIFOs, files, symlinks and the root at imported paths main lacks, and /workspace's ignored files; does not establish what U2a3c will do.

Probes: an untracked `.claude/rules/x.md`, `pkg/.claude/rules/sub/y.md` and an ignored `ign/CLAUDE.md` each fail the walk (`logs/probe-rules.txt`); an index-only `CLAUDE.local.md` deleted from the checkout fails it (P1); a FIFO at an imported path main lacks fails it and, removed, the walk is ok with the path unread (P3); an import of the root fails it (P2) (`logs/probe-craft.txt`). `:574` `[[ "${cand[i]:0:1}" == m ]] || return 1  # main lacks it: not walked until U2a3c`; `:597` sets `lk` on `! -L "$p"` too (mutant lkcheckoutL fails test 15). /workspace holds 35 start-shaped untracked/ignored files under `devcontainer-config/claude-home/` (Claim 2), each of which `:574` refuses.

Commands: `bash probe-rules.sh` · exit 0 · 2026-10-07T04:12Z; `bash probe-craft.sh` · exit 0 · 2026-10-07T04:07:46Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:566-577`, `scripts/lib/dev-cycle-read.sh:597`, `scripts/lib/dev-cycle-read.sh:612`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-rules.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-craft.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-lkcheckoutL.txt`

---

## Claim 9: A5 "Not covered: start files under a symlinked directory or in a submodule or untracked nested repo (neither `ls-tree -r` nor `ls-files --others` enters one), other names one file has on a case-insensitive checkout, absolute imports into the repo, and checkout conversions ..."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the parenthetical (executed) and the completeness of the list against this pass's probes (crafted trees via `hash-object --literally`, non-canonical modes, slash-named entries, doubled trees, root and `.git` imports, FIFOs, deleted index entries, ignored directories, this repo's own main); does not establish completeness against Claude Code's real loader (no host probe) or against filesystems other than Linux ext4/overlay.

`ls-files -z --cached --others` in a repo with `lnk -> real` and an untracked nested repo lists only `real/CLAUDE.md` (not `lnk/CLAUDE.md`, not `nested/CLAUDE.md`), and a main whose `.claude/rules` is a symlink to `../shared` walks ok with `shared/secret.md: -` (`logs/probe-misc.txt`): the symlinked-directory gap as stated. No probe found a tree or checkout state, beyond these and the settled rows, where the walk answers ok and misses an import a fresh checkout of main would load: every crafted shape above failed closed (Claims 7, 8).

Command: `bash probe-misc.sh` · cwd scratch · exit 0 · 2026-10-07T04:10:21Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:557`, `scripts/lib/dev-cycle-read.sh:566`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-misc.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-craft.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-craft2.txt`

---

## Claim 10: F11: "Floor item 1 walks main's commit (`main_imports`, U2a3: NUL-safe listings, symlinks on main followed, `.claude/rules/` at any depth as starts; a doubled name, a name holding a newline, link text that is ..., or an imported path main lacks under a directory main stores as a symlink or gitlink fails the walk ...). Until U2a3c it fails closed on the checkout ... so the gate needs a fresh worktree (U2b) ... Gaps: known issue A5 (...)"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers F11's statements against the code and A5 (the shapes listed fail; NUL-safe listings via `nul_list` with `-z`; the gaps match A5); does not treat F11's refusal list as exhaustive (it names the file-and-directory shape only under "a doubled name", which the crafted tree of test 17 is at the tree-object level, while a slash-named entry beside a link is refused but not named), and does not establish U2a3c's future behaviour.

`:557` `nul_list recs git ls-tree -r -z --full-tree "$MAIN_SHA" || return 1` and `:566` (`ls-files -z`) are the NUL-safe listings; the shapes are those of Claim 7; the checkout half matches Claim 8; the gaps list matches A5's (Claim 9).

**Evidence:** `scripts/lib/dev-cycle-read.sh:557-612`, `docs/working/known-issues-dev-cycle.md:18`

---

## Claim 11: U2a3 plan bullet: "an import walk that reads main's commit, started from main's instruction files and `.claude/rules/`. It refuses the tree and link shapes it does not model (...) ... and fails closed on the checkout (a start file main lacks, or anything but a plain directory at an imported path main lacks)"

**Location:** `docs/working/plan-build-loop-handoff.md:276`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the bullet's description of the code at HEAD (same shapes as F11); does not verify the historical references (Q-119, carried rows), and the same non-exhaustiveness note as Claim 10 applies.

The start rule is `:573` `if [[ "${f##*/}" =~ $INSTRUCTION_FILE || "$f" == .claude/rules/*.md || "$f" == */.claude/rules/*.md ]]`; refusals as in Claims 7 and 8.

**Evidence:** `scripts/lib/dev-cycle-read.sh:571-577`, `scripts/lib/dev-cycle-read.sh:611-612`

---

## Claim 12: U2b plan bullet: "until U2a3c the walk fails on any start file main lacks, ignored ones included, and on anything but a plain directory at an imported path main lacks; U2b is to refuse (not built yet; the walk does not check this) a checkout whose `.gitattributes` sets `working-tree-encoding` or `filter` ..., or whose `core.symlinks` is false"

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk's current behaviour and the absence of an attribute/config check in the lib and build-loop.sh; does not establish U2b's future refusal.

Ignored starts fail (Claim 8, `logs/probe-rules.txt`). `grep -n 'gitattributes\|core.symlinks\|working-tree-encoding'` over the lib and `scripts/build-loop.sh` finds only an unrelated comment at `:259` ("a .git* part such as .gitattributes") (paraphrased — no quote available because the claim covers absence of code). No script outside the lib calls `main_imports` or `isimported main` (grep over `scripts/`, no hits).

**Evidence:** `scripts/lib/dev-cycle-read.sh:259`, `scripts/lib/dev-cycle-read.sh:574`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-rules.txt`

---

## Claim 13: Header Inputs: main_imports reads the default branch's commit, "it reads the checkout only to fail, until U2a3c, so the gate needs a fresh worktree; the block above IMPORTED= lists each case; it needs resolve_main to have found main by name"

**Location:** `scripts/lib/dev-cycle-read.sh:29-35`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every checkout read in `main_imports` (the index/untracked listing, `-L` in the link-text loop, the `-d`/`-e`/`blocker` probe) and the `main_by_name` guard; does not establish that the gate's caller provides a fresh worktree (U2b's).

The checkout reads are `:566-567` (listing; adds nothing to the result, a start main lacks returns 1 at `:574`), `:597` (only sets `lk`, which can only fail), and `:612` (records nothing, fails or passes). Nothing read from the checkout is appended to `IMPORTED_MAIN`, which `:606` fills only from `out` (main's blob or link text). `:556` `main_by_name || return 1`, and `:253` `main_by_name() { [[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]]; }`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:253`, `scripts/lib/dev-cycle-read.sh:550-615`

---

## Claim 14: Block comment: "it starts at every instruction file stored there (and every .md under a .claude/rules/ directory at any depth ...) and follows an import into the file main stores at that path, whatever its name; a symlink there is followed to the path its text names. An imported path main lacks is recorded and not read."

**Location:** `scripts/lib/dev-cycle-read.sh:452-457`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers start selection, following into any name main stores, chained symlinks, and recording without reading; does not establish that INSTRUCTION_FILE matches Claude Code's own loader list.

Test 6 passes with `docs/c3.md` reached through `GEMINI.md -> docs/c1.md -> c2.md`, `.claude/rules/` and `pkg/.claude/rules/` starts, and `docs/a+b.md` (100755) (`logs/blc.txt`, ok 6). `:609` `if [[ -n "${ent[$p]+set}" ]]; then queue+=("$p"); continue; fi` follows only names main stores; a name main lacks is appended at `:606` and never queued. Test 3's `docs/new.md` (main lacks, checkout lacks) answers `imported` with `walk ok`.

Command: baseline `bats build-loop-check.bats` · exit 0 · 2026-10-07T04:03:19Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:571-577`, `scripts/lib/dev-cycle-read.sh:604-613`, `test/scripts/build-loop-check.bats:46-62`, `test/scripts/build-loop-check.bats:108-130`, `/tmp/u2a3-cfc3-i3-irp4/logs/blc.txt`

---

## Claim 15: Block comment's refusal list: "a name listed twice or as both a file and a directory, a name holding a newline, symlink text that is empty, absolute, leaves the repo, holds a newline or a NUL, or has a .. after a symlink (on main or in the checkout), an imported path main lacks that lies under a directory main stores as a symlink or gitlink, or that the checkout holds as anything but a plain directory (the root itself included), and a start file main lacks (untracked, ignored, or in the checkout's index) fail the walk, so isimported main answers imported for every path"

**Location:** `scripts/lib/dev-cycle-read.sh:457-465`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed shape (mutant-killed or probed) and the every-path answer on failure; does not establish behaviour when a helper (`lower`, `grep`, `sed`) fails inside the drain loop with errexit off (U2a3b's, stacked; settled errexit row).

Each refusal: Claims 7 and 8. "The root itself included": an import of `docs/..` and link text `.` or `docs/..` each fail the walk (`logs/probe-craft.txt`, P2, P4), because `blocker . dir` prints `./` (`plaindir .` compares `$ROOT_REAL` with `$ROOT_REAL/.`). Every-path answer: `:626` `main) main_imports || return 0; ...` and test 8 (`if isimported main docs/z.md` prints `failed walk: imported`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:102`, `scripts/lib/dev-cycle-read.sh:110-121`, `scripts/lib/dev-cycle-read.sh:612`, `scripts/lib/dev-cycle-read.sh:626`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-craft.txt`

---

## Claim 16: "Checkout files are not walked until U2a3c, so the walk fails closed on them. A start file answers imported only when an import reaches it (U2a4's floor names start files by its own rules)."

**Location:** `scripts/lib/dev-cycle-read.sh:465-467`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the seeding (`seen` but not appended) and the append-on-reach path; does not establish U2a4's rules.

Seeding at `:575` `seen[${cand[i]:2}]=1; queue+=("${cand[i]:2}")` appends nothing to `IMPORTED_MAIN`; `:606` appends every reached path before the `seen` check at `:607`. Test 3 answers `CLAUDE.md: -` with `walk ok` (`logs/blc.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:575`, `scripts/lib/dev-cycle-read.sh:604-608`, `test/scripts/build-loop-check.bats:57`

---

## Claim 17: "Not covered (known issue A5): start files under a symlinked directory or in a submodule or untracked nested repo, other names one file has on a case-insensitive checkout, absolute imports, checkout conversions (A5), and three shapes A5 lists as untraced against Claude Code."

**Location:** `scripts/lib/dev-cycle-read.sh:467-471`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers agreement with A5 and the probes of Claim 9; does not establish completeness against Claude Code's real loader.

The list matches A5's (`docs/working/known-issues-dev-cycle.md:18`) item for item; the executed parts are in Claim 9.

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-misc.txt`

---

## Claim 18: "IMPORTED_MAIN reads "error" until a walk succeeds; the result is cached for the commit, MAIN_BY_NAME and root in IMPORTED_MAIN_DONE, so a caller whose checkout changes between calls sets IMPORTED_MAIN_DONE="" to walk again."

**Location:** `scripts/lib/dev-cycle-read.sh:472-474`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the key, the cached failure, and every return path setting `error`; does not establish a caller's use of the reset.

`:554-555`: `[[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }` / `IMPORTED_MAIN=error; IMPORTED_MAIN_DONE="$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"`. Every `return 1` before `:578` leaves `error`; every one after sets `IMPORTED_MAIN=error` first (`:583, :588, :590, :595, :600, :602, :611, :612`). Test 16 prints `- docs/b.md x.sh x.sh - y.sh` (new commit walks again; a failed walk stays failed; MAIN_BY_NAME="" walks again and fails) (`logs/blc.txt`, ok 16).

**Evidence:** `scripts/lib/dev-cycle-read.sh:554-615`, `test/scripts/build-loop-check.bats:295-304`, `/tmp/u2a3-cfc3-i3-irp4/logs/blc.txt`

---

## Claim 19: "nul_list NAME CMD...: array NAME gets CMD's NUL-split output, or is emptied and 1 unless CMD exited 0 and its output was empty or ended in NUL."

**Location:** `scripts/lib/dev-cycle-read.sh:518-519`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exit status, empty output, a missing trailing NUL, and an `rc=0` item inside the output; does not establish behaviour for a NAME that collides with the function's own `nl_a` nameref.

Run directly: `printf "a\0b\0"` → `rc0 n=2 [a b]`; `printf ""` → `rc0 n=0`; `printf "a\0b"` → `rc1 n=0`; a command printing `a\0` and exiting 3 → `rc1 n=0`; `printf "x\0rc=0\0"` → `rc0 n=2 [x rc=0]` (`logs/probe-misc.txt`).

Command: `bash probe-misc.sh` · exit 0 · 2026-10-07T04:10:21Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:519`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-misc.txt`

---

## Claim 20a: The return-1 comment: each listed condition makes the walk return 1 with IMPORTED_MAIN "error" ("main is not found by name, the commit's tree or the checkout's .md list (tracked and untracked) cannot be listed whole (nul_list), a tree record does not parse ..., a name is listed twice ..., is also a directory of another listed name, or holds a newline, the lower-cased start list comes back short, a start file main lacks is listed (even one deleted from the checkout), a blob cannot be read, symlink text ..., or an imported path main lacks lies under a directory main stores as a symlink or gitlink or exists in the checkout as anything but a plain directory below the root; need_root exits instead"), and every failure path is listed

**Location:** `scripts/lib/dev-cycle-read.sh:538-549`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each `return 1` site in `main_imports` (`:556, :557, :559, :561, :565, :566, :567, :570, :574, :583, :587-588, :590, :595, :600, :602, :611, :612`) against the list, plus tests 4, 10 and 14 and P1; does not establish the record-type phrase's precision (Claim 20b) or failures of helpers whose own failure is swallowed (U2a3b, stacked).

Each site maps to a listed cause: `:567` `[[ "$f" != *$'\n'* ]] || return 1` is "holds a newline" for checkout names; `:570` `[[ ${#low[@]} -eq ${#cand[@]} ]] || return 1` is "comes back short" (lowlen mutant fails test 10); `:583`'s pipeline fails only through `git cat-file` ("a blob cannot be read"), since `import_targets`' grep ends `|| true` (`:509`); `:599` maps a failed `realpath` to `..`, which `:600` refuses ("leaves the repo"). Tests 4 (missing blob, no main by name), 10 (missing tree object, corrupt index, failing tr, failing `--cached`) and 14 pass; P1 confirms the deleted-index case.

**Evidence:** `scripts/lib/dev-cycle-read.sh:509`, `scripts/lib/dev-cycle-read.sh:550-615`, `test/scripts/build-loop-check.bats:64-77`, `test/scripts/build-loop-check.bats:193-217`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-lowlen.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-craft.txt`

---

## Claim 20b: "a tree record ... has a type but blob, link or gitlink"

**Location:** `scripts/lib/dev-cycle-read.sh:541-542`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `case` on the record's mode at `:582-603`; does not establish that any such record can occur (ls-tree canonicalises modes, Claim 5).

The check is on the stored mode, not the type word, and it runs only when the record is walked (a start or an import target): `:582` `case "${ent[$f]}" in` ... `:602` `*) IMPORTED_MAIN=error; return 1 ;;`. An unwalked record never fails the walk on its type. Since ls-tree canonicalises modes the arm is unreachable (Claim 5), so the imprecision misleads nobody; precise wording: "a walked record's mode is not a regular file, link or gitlink".

**Evidence:** `scripts/lib/dev-cycle-read.sh:559-562`, `scripts/lib/dev-cycle-read.sh:582-603`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-craft.txt`

---

## Claim 21: The ancestor pass: "then a name that is also a directory of another listed name (a crafted tree) fails" (memoised `dir` map)

**Location:** `scripts/lib/dev-cycle-read.sh:564-565`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers correctness of the memo (break only on an ancestor already checked against the complete `ent`), tree-and-link, gitlink-and-tree and slash-named-entry-and-link shapes; does not establish cost at scale (performance's row).

```bash
# scripts/lib/dev-cycle-read.sh:565
for f in "${!ent[@]}"; do c="$f"; while [[ "$c" == */* ]]; do c="${c%/*}"; [[ -z "${dir[$c]+set}" ]] || break; [[ -z "${ent[$c]+set}" ]] || return 1; dir[$c]=1; done; done
```

`ent` is complete before this pass (the record loop ends at `:564`), so an ancestor marked in `dir` was already checked against every listed name, and its own ancestors were too; the `break` loses nothing whatever the iteration order. The ancestor mutant fails test 17 (`logs/mut-ancestor.txt`); a gitlink `sub` beside a tree `sub` (P9) and a root entry named `l/x.md` beside a link `l` (P6c) each fail the walk. On this repo's main the pass refuses nothing (Claim 22).

**Evidence:** `scripts/lib/dev-cycle-read.sh:558-565`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-ancestor.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-craft.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-craft2.txt`

---

## Claim 22: The merged `ls-files --cached --others` listing: index-only and untracked/ignored starts main lacks are refused, starts main stores are skipped, and a normal repo is not wrongly refused

**Location:** `scripts/lib/dev-cycle-read.sh:566-567`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this repo's main (a fresh `git clone` of /workspace checked out at main 62d366a7, clean, 0 status lines) and the review worktree, plus the probes of Claim 8; does not establish behaviour on a sparse index or with GIT_INDEX_FILE (settled Defer row).

On the fresh clone of main the walk prints `walk: ok` in 0.5 s and records three paths (`global-instructions/claude-plugins-official`, `skills/code-fact-check/deprecated`, `skills/dependency-upgrade/org/migrate"}`), none of which main stores or the checkout holds; on the review worktree (HEAD 0bb98f27, no ignored start files) `walk: ok` too (`logs/probe-own.txt`, `logs/probe-own2.txt`). `:567` `[[ -n "${ent[$f]+set}" ]] || cand+=("t:$f")` adds only names main lacks.

Commands: `bash probe-own.sh` · cwd scratch · exit 0 · 2026-10-07T04:06:26Z; `bash probe-own2.sh` · exit 0 · 2026-10-07T04:06Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:566-577`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-own.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-own2.txt`

---

## Claim 23: "main lacks it: not walked until U2a3c"

**Location:** `scripts/lib/dev-cycle-read.sh:574`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the start-file arm; does not establish U2a3c.

`[[ "${cand[i]:0:1}" == m ]] || return 1` returns before any read of a `t:` start; the untrackedstart mutant (`|| continue`) fails tests 3, 9 and 11 (`logs/mut-untrackedstart.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:574`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-untrackedstart.txt`

---

## Claim 24: Link-arm comments: "$(...) drops NULs, so they are counted first; the x keeps trailing newlines"; "realpath -s reads x/.. as nothing, but the kernel follows a symlink x first: a .. after a symlink on main or in the checkout fails."

**Location:** `scripts/lib/dev-cycle-read.sh:584-598`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the NUL count, trailing-newline retention, and the per-component `..` check against main's links and checkout links; does not establish the token-side `..` (A5 untraced, settled).

NUL-count mutant fails test 9 with bash's "ignored null byte" warning and `walk: ok` (`logs/mut-nulcount.txt`); the newline-text case `$'notes.md\n'` fails (test 7). The lk mutant fails tests 10 and 15, and dropping `! -L "$p"` from `:597` fails test 15 (the checkout-only link) (`logs/mut-lk.txt`, `logs/mut-lkcheckoutL.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:584-600`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-nulcount.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-lk.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-lkcheckoutL.txt`

---

## Claim 25: Record-type arms: "160000) continue ;;  # a gitlink: its files are not main's"; any other type fails

**Location:** `scripts/lib/dev-cycle-read.sh:601-602`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a gitlink at a start name and the `*)` arm; does not establish submodule contents (A5's gap).

Removing the `160000)` line sends a gitlink start to `*)`, and test 12's gitlink-start step fails with `walk: failed` where it wants ok (`logs/mut-gitlinkarm.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:601-602`, `test/scripts/build-loop-check.bats:246`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-gitlinkarm.txt`

---

## Claim 26: Parent-check comment: "Main lacks p: under a link or gitlink main stores, or in the checkout as anything but a plain directory, fail."

**Location:** `scripts/lib/dev-cycle-read.sh:610-612`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every ancestor (not only the parent), links and gitlinks, and the checkout probe; does not establish the unsearchable-directory case (settled Defer to U2a3c).

`^120000$` in place of `^1[26]0000$` fails test 12 (gitlink parent); an immediate-parent-only loop fails test 15 (one-letter link two levels up); dropping the checkout probe fails tests 3, 9 and 12; `false ||` in place of the plain-directory allowance fails test 9 (`logs/mut-gitlinkparent.txt`, `mut-parentimmediate.txt`, `mut-checkoutprobe.txt`, `mut-plaindirallow.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:610-612`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-gitlinkparent.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-parentimmediate.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-checkoutprobe.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-plaindirallow.txt`

---

## Claim 27: isimported: "A failed main walk, or a walk name that is neither, answers imported (0), so a caller testing it with `if` refuses; a caller that words a failed walk runs main_imports first. Run it in the caller's shell: the walk exits through need_root and caches its result."

**Location:** `scripts/lib/dev-cycle-read.sh:616-630`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `main`, `tree` and unknown arms under `if`; does not establish behaviour of helper failures with errexit off inside the walk (settled row; U2a3b).

`main) main_imports || return 0; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]] ;;` and `*) return 0 ;;`. Tests 2, 8 and 14 pass (`bogus: imported`, `failed walk: imported`, `scripts/x.sh: imported`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:621-630`, `test/scripts/build-loop-check.bats:40-44`, `test/scripts/build-loop-check.bats:154-163`, `test/scripts/build-loop-check.bats:260-268`, `/tmp/u2a3-cfc3-i3-irp4/logs/blc.txt`

---

## Claim 28: Suite header: "Contract tests for the build-loop gate: the reader lib's import walks (scripts/lib/dev-cycle-read.sh isimported, import_targets, main_imports) ..."

**Location:** `test/scripts/build-loop-check.bats:3-4`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which lib functions the suite exercises; does not establish U2a4/U2b's future tests.

The suite's tests call `imps tree`, `imps main`, `isimported` and `main_imports` directly (`:17-22`, `:212`).

**Evidence:** `test/scripts/build-loop-check.bats:13-24`, `test/scripts/build-loop-check.bats:211-216`

---

## Claim 29: Each `main walk` test name and comment asserts what it says, and no refusal is masked by an earlier failure (stale index, untracked start)

**Location:** `test/scripts/build-loop-check.bats:46-311`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers tests 3-17 against 19 single-point mutants of HEAD's lib, each failing the test that names the refusal at the expected `want` line; does not cover test 10's wording (Claim 30), and notes that test 7's empty-text case at the top level is refused by the root check (`:612`), not the empty-text check, which test 12 pins below the top level as its name says.

Mutants and the tests they fail (`logs/mut-*.txt`): dupname 5; treenl 5; ancestor 17; checkoutnl 7; absolute 7; leaves 7; emptytext 12; nulcount 9; lk 10, 15; lkcheckoutL 15; parentimmediate 15; gitlinkparent 12; gitlinkarm 12; checkoutprobe 3, 9, 12; plaindirallow 9; untrackedstart 3, 9, 11; indexhalf 3, 10; lowlen 10; herestring 10. Each failure shows the named `want` mismatching (e.g. treenl: `want: walk: failed` / `walk: ok` at `:105`). Tests 5, 9 and 12 now `git rm -qf CLAUDE.md` before the refusal (`:91`, `:189`, `:242`), and the same three mutants that 664c18fe's tests let through are caught (Claim 1). Comments checked: test 9's "An import of a plain directory reads nothing and is no failure" (`walk ok`, `docs/x.md: -`); test 12's "(sub/ is an empty directory here)" (`mkdir -p docs sub real/sub.md`); test 15's "The kernel reads deep/evil.md through ld; realpath -s would read evil.md".

Commands: `$S/mut.sh <name> ...` (batch 1, 2026-10-07T04:03:55Z), `bash mut-batch2.sh` (04:10:03Z), `bash mut-batch3.sh` (04:12:08Z) · cwd scratch · bats rc=1 for every mutant.

**Evidence:** `test/scripts/build-loop-check.bats:46-311`, `/tmp/u2a3-cfc3-i3-irp4/logs/` (`mut-*.txt`, `mut-*.diff`)

---

## Claim 30: Test 10's name "when main's tree or the untracked list cannot be listed" and comment "A corrupt index: git ls-files --others fails."

**Location:** `test/scripts/build-loop-check.bats:193`, `test/scripts/build-loop-check.bats:199`
**Type:** Behavioral / Staleness
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the corrupt-index step exercises at HEAD; does not affect the test's assertions, which pass and kill the listing mutants.

Since 99cce51b the listing is one `git ls-files -z --cached --others` call (`:566`), so the step fails the tracked-and-untracked listing, not "the untracked list" or a bare `ls-files --others`. Precise: "the checkout's .md list (tracked and untracked) cannot be listed" / "git ls-files --cached --others fails". The test does pin the `--cached` half separately (the git shim at `:206`; indexhalf mutant fails it).

**Evidence:** `scripts/lib/dev-cycle-read.sh:566`, `test/scripts/build-loop-check.bats:193-206`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-indexhalf.txt`

---

## Claim 31: dev-cycle.bats inventory lists `main_imports`, `nul_list`, `IMPORTED_MAIN`, `IMPORTED_MAIN_DONE`

**Location:** `test/scripts/dev-cycle.bats:1083-1090`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the sourced-lib inventory test; does not establish other suites' inventories.

dev-cycle.bats: 75 ok, exit 0 (`logs/dev-cycle.bats.txt`).

**Evidence:** `test/scripts/dev-cycle.bats:1086-1090`, `/tmp/u2a3-cfc3-i3-irp4/logs/dev-cycle.bats.txt`

---

## Claim 32: Commit 99cce51b: "Tests: build-loop-check.bats 17; 115 across the five suites. ... 400 changed code lines against main."

**Location:** commit `99cce51b`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `@test` counts at 99cce51b and HEAD, a live run at HEAD, and `git diff --numstat main...99cce51b -- . ':!docs'`; does not establish the "Test lines ... joined" note beyond the line count.

`@test` counts at 99cce51b: 75 + 19 + 17 + 2 + 2 = 115 (same at 0bb98f27); live run at HEAD 115 ok. numstat sums to 400 at 99cce51b and at HEAD (`117 9`, `268 2`, `2 2`).

**Evidence:** `test/scripts/build-loop-check.bats`, `/tmp/u2a3-cfc3-i3-irp4/logs/blc.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/suites-rc.txt`

---

## Claim 33: Commit 99cce51b: "Mutants of the ancestor pass, the tree-name newline check, the NUL count, the empty-text check, the gitlink arm and the index half of the listing each fail."

**Location:** commit `99cce51b`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the six named mutants as reconstructed here (diffs in `logs/mut-<name>.diff`); does not establish the author's exact mutant text.

ancestor → test 17; treenl → test 5; nulcount → test 9; emptytext → test 12; gitlinkarm → test 12; indexhalf → tests 3, 10 (`logs/mut-*.txt`).

Command: `$S/mut.sh <name> OLD NEW` x7 in parallel · cwd scratch · bats rc=1 each · 2026-10-07T04:03:55Z.

**Evidence:** `/tmp/u2a3-cfc3-i3-irp4/logs/mut-ancestor.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-treenl.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-nulcount.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-emptytext.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-gitlinkarm.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-indexhalf.txt`

---

## Claim 34: Commit 99cce51b F1, F2: the tree-and-symlink fail-open ("full paths differ ... the walk read the tree's blob while a checkout writes the link ... not a regression") and "since dfeeb85d's index listing, tests 5, 9 and 12 failed on a stale index-only CLAUDE.md before reaching the refusal they name ... they now `git rm -qf CLAUDE.md` first"

**Location:** commit `99cce51b`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claim 1; does not establish the reviewer attributions.

See Claim 1 (pre-fix walk ok on test 17 at 664c18fe and cc1aa864; checkout writes `l -> docs`; three mutants survive 664c18fe's tests and are killed at HEAD).

**Evidence:** `/tmp/u2a3-cfc3-i3-irp4/logs/mut-old-lib-new-test17.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-cc1-test17.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-old-treenl.txt`, `test/scripts/build-loop-check.bats:91`, `test/scripts/build-loop-check.bats:189`, `test/scripts/build-loop-check.bats:242`

---

## Claim 35: Commit 99cce51b F3-F5: one `ls-files --cached --others` call; "a gitlink at a start name and a git whose `ls-files --cached` fails are pinned"; wording (A5 "a .. after a checkout link", nul_list "empty or ended in NUL", test 9's name, the U2b bullet); F3 rows listed in A5 and F11 and the U2b bullet makes the gate refuse them

**Location:** commit `99cce51b`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named change at HEAD; the U2b refusal is a plan (Claim 12), not code.

`:566` is one call; test 12's last step (gitlink start, `walk ok`) and test 10's `--cached` shim are present and each is killed by its mutant (Claims 25, 30). A5 holds "a `..` after a checkout link in link text"; `:518` holds "empty or ended in NUL"; F11 and A5 name `working-tree-encoding`/`filter` and `core.symlinks=false`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:518`, `scripts/lib/dev-cycle-read.sh:566`, `test/scripts/build-loop-check.bats:206`, `test/scripts/build-loop-check.bats:246`, `docs/working/known-issues-dev-cycle.md:18`, `docs/working/plan-build-loop-handoff.md:126`

---

## Claim 36: Commit 0bb98f27: "the U2b bullet states the checkout-conversion refusal as U2b's to build"

**Location:** commit `0bb98f27`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the bullet text; does not establish U2b.

The bullet reads "U2b is to refuse (not built yet; the walk does not check this) a checkout whose `.gitattributes` sets ..." (`docs/working/plan-build-loop-handoff.md:279`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:279`

---

## Claim 37: Commit dfeeb85d: E1 (an index-only start main lacks "was neither walked nor failed"; now fails), E4, "Tests: build-loop-check.bats 16; 114 across the five suites. Mutants of the index listing, the link-text split (here-string revert) and the newline check each fail. 400 changed code lines against main." (test-7 fixture and rename wording: Accepted-immutable row, `docs/reviews/override-log.md:395`)

**Location:** commit `dfeeb85d`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the figures at dfeeb85d and the three mutants as reconstructed at HEAD; pointer only for the Accepted-immutable wording.

Counts at dfeeb85d: 16 in build-loop-check.bats, 114 total; numstat 400. E1's pre-fix behaviour equals the indexhalf mutant (test 3 `walk: ok` on `git add -f CLAUDE.local.md`); herestring and checkoutnl mutants fail tests 10 and 7 (Claim 29).

**Evidence:** `/tmp/u2a3-cfc3-i3-irp4/logs/mut-indexhalf.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-herestring.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-checkoutnl.txt`, `docs/reviews/override-log.md:395`

---

## Claim 38: Commit 2b22a082: "build-loop-check.bats 16; 114 across the five suites. ... 392 changed code lines against main." (headline and D13 sentence: Accepted-immutable row, `docs/reviews/override-log.md`, loop 2 iteration 1 row)

**Location:** commit `2b22a082`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the figures; the named mutants were verified by loop 2 iteration 1 and are reconstructed here only in their HEAD forms (untracked start, checkout probe, gitlink match, parent loop, plain-directory allowance, link-text split: each killed, Claim 29); pointer only for the Accepted-immutable rows.

Counts at 2b22a082: 16 and 114; `git diff --numstat main...2b22a082 -- . ':!docs'` sums to 392.

**Evidence:** `/tmp/u2a3-cfc3-i3-irp4/logs/mut-untrackedstart.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-checkoutprobe.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-parentimmediate.txt`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 20b** (`scripts/lib/dev-cycle-read.sh:541-542`): the record-type refusal checks the mode, and only for a walked record; the arm is unreachable, so this is wording only.
- **Claim 30** (`test/scripts/build-loop-check.bats:193`, `:199`): test 10's "the untracked list" / "git ls-files --others fails" predate the merged `--cached --others` listing.

### Unverifiable
(none)

## Fail-closed probe summary (task item 1)

No main tree or checkout state was found where the walk answers ok and misses an import a fresh checkout of main would load, beyond A5's documented gaps and the settled rows. Probed and failing closed: slash-named root entries (`docs/CLAUDE.md` read consistently by `cat-file` and the checkout; `l/x.md` beside a link `l` refused), two trees with one name (start or target in the second tree: `cat-file` cannot find it, walk fails), a gitlink and a tree with one name, modes 100664 (read as 100644, as the checkout writes) and 70000 (read as a gitlink, as the checkout writes), a 100644 entry naming a tree object, link text `.` and `docs/..`, an import of the root, a FIFO, an index-only start deleted from the checkout, untracked rules files at depth, an ignored start in an ignored directory, `@.git` in a linked worktree. Found ok and consistent with A5: a symlinked `.claude/rules` directory, a symlinked directory and an untracked nested repo in the checkout.

## Escalations

- `test/scripts/build-loop-check.bats:193`, `:199` → author (wording, Claim 30; optional, no behavioural effect).
- `scripts/lib/dev-cycle-read.sh:541-542` → author (wording, Claim 20b; optional).
- None to critics: no Incorrect verdict, no fail-open found.

## Goal-Alignment Note

**Success criterion (verbatim):** A code-fact-check report verdicting every checkable claim in the U2a3 diff's comments, docs and commit messages, saved at the path given below.

**Answered:** Yes. 39 rows over the lib comments (header, block, cache, nul_list, return-1, ancestor pass, start arm, link and record arms, parent check, isimported), A5, F11, the U2a3/U2b plan bullets, the suite header, test names and comments (unmasking checked with 19 mutants), the dev-cycle.bats inventory, the commits since 0170f16a (figures re-counted and run: 17, 115, 400, 392, 16/114; named mutants run and killed), and the rubric's Loop 2 rows and override rows that make claims about the code. 37 Verified, 2 Mostly accurate (wording only), 0 Incorrect.

**Out of scope:** U2a3b's helper-failure behaviours (stacked); U2a3c's plan bullet (design for unbuilt code, verdicted only where it states current behaviour); Claude Code's own loader (no host probe); performance figures in override rows (performance critic's); Accepted-immutable commit-message rows (pointers only).

**Escalate:** Nothing blocking. The two Mostly-accurate rows are optional wording fixes; the unit as fact-checked holds its fail-closed contract.
