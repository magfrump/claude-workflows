Commit: 3a35c8b9
# Code Fact-Check Report

**Commit:** 3a35c8b9
**Repository:** /workspace/.claude/wt-build-loop-u2a3c (branch `feat/build-loop-u2a3c`)
**Scope:** `git diff main...HEAD` (HEAD 3a35c8b9) and the commit messages of main..HEAD: `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`, `docs/working/known-issues-dev-cycle.md` (A5), `docs/working/plan-build-loop-handoff.md` (F11, U2a3c, U2b), `docs/reviews/override-log.md` (rows 448-456), and the iteration-2 rubric's claims about the code. Replicate fc3 of 3 (final confirming pass, iteration 3).
**Checked:** 2026-10-07
**Total claims checked:** 44
**Summary:** 31 verified, 8 mostly accurate, 2 stale, 0 incorrect, 3 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). The pattern it records most often is a commit message's test count that does not match the suite. Every count in this branch's commit messages was checked by running the suites, and all of them match (Claims 38a, 42).

Execution provenance: every executed claim ran with bash 5.2, mawk, git 2.39 and bats as uid 1000. Raw output is under `/tmp/u2a3c-i2-fc3-j0eh/logs/`, and each claim names its log file. The worktree was never modified. Old libs and mutants ran in a `git archive HEAD` copy at `/tmp/u2a3c-i2-fc3-j0eh/repo` (cwd for its bats runs), and the 3e58eb9c suite ran in `/tmp/u2a3c-i2-fc3-j0eh/repo-3e58`. HEAD suites (cwd: the worktree, `TMPDIR=<fresh mktemp> LC_ALL=C`), run 2026-10-07T20:10-20:11Z: build-loop-check 63/63, dev-cycle 78/78, build-loop-read 19/19, fixture-hermeticity 2/2, each with exit 0 (`logs/build-loop-check.log`, `dev-cycle.log`, `build-loop-read.log`, `herm.log`).

---

## Claim 1: Iteration-2 rubric: "D=1000: 0.62 s (main 0.50, 21b35ebf 10.67). Test with a 6 s timeout fails at 21b35ebf"; "T1 (the shape table, direct calls) and T2 (walk level) applied"; C8 "Pinned by T1 (`sd/nx.md 1`)"; "Tests after fixes (2fbd929b): build-loop-check 63/63, dev-cycle 78/78, build-loop-read 19/19, fixture-hermeticity 2/2"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:17-36`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the D=1000 timings, the 6 s test failing at 21b35ebf, T1's `sd/nx.md 1` row and the four suite counts at HEAD. It does not establish the D=1950 (64 s) and 256 MiB (58 s, 2 GiB) figures, which I did not re-measure.

Command: `bash /tmp/u2a3c-i2-fc3-j0eh/deep.sh <rev>` for main, 21b35ebf and 3a35c8b9, twice each (exit 0, 20:14:48-20:15:11Z). It gave main 511/502 ms, 21b35ebf 10461/10864 ms and 3a35c8b9 658/652 ms (`logs/deep-timing.log`). `runold.sh 21b35ebf 'deep import token'` gives `not ok` and 3a35c8b9 gives `ok` (`logs/old-21b35ebf-deep_import_token.log`). T1 expects the row `sd/nx.md 1` (`test/scripts/build-loop-check.bats:874`) and passes at HEAD.

**Evidence:** `test/scripts/build-loop-check.bats:853-883`, `test/scripts/build-loop-check.bats:932-940`, `/tmp/u2a3c-i2-fc3-j0eh/logs/deep-timing.log`, `/tmp/u2a3c-i2-fc3-j0eh/logs/build-loop-check.log`

---

## Claim 2: Override row 448: "27364085: the candidates are lower-cased by lower_all under nul_list, so a tr that dies after a partial flush fails the walk; the test fails at 3e58eb9c."

**Location:** `docs/reviews/override-log.md:448`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the start list's lower_all/nul_list path and the N1 test's failure on 3e58eb9c's lib. It does not establish the per-file `lower` calls, which still use a plain `$(...)`.

`[[ ${#cand[@]} -eq 0 ]] || nul_list low lower_all "${cand[@]}" || return 1` (`scripts/lib/dev-cycle-read.sh:820`). Command: `bash runold.sh 3e58eb9c 'batch tr dies'`, cwd `/tmp/u2a3c-i2-fc3-j0eh/repo`, exit 1, 2026-10-07T20:14:20Z, result `not ok 1` (`logs/old-3e58eb9c-batch_tr_dies.log`). At HEAD the same test gives `ok` (20:14:30Z).

**Evidence:** `scripts/lib/dev-cycle-read.sh:695-700`, `scripts/lib/dev-cycle-read.sh:820-821`, `/tmp/u2a3c-i2-fc3-j0eh/logs/old-3e58eb9c-batch_tr_dies.log`

---

## Claim 3: Override row 449: "capped_read is the one reader for checkout files and main's blobs, and drains a pipe so git cat-file never dies of SIGPIPE under pipefail (a no-drain mutant fails the test)."

**Location:** `docs/reviews/override-log.md:449`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the drain's mechanism and its test. It does not establish the link-blob half, which row 454 already corrects.

The row describes 27364085's `[[ ! -p /dev/stdin ]] || cat > /dev/null`. Since 2fbd929b, capped_read drains only when its caller passes the word `drain`, not whenever stdin is a pipe: `capped_read() { head -c 4194305 || return 1; [[ "${1:-}" != drain ]] || cat > /dev/null; }` (`scripts/lib/dev-cycle-read.sh:709`). Only the blob arm passes it (`:839`). Row 454 corrects the link-blob half, and the rubric's C1 records the mechanism change, but no override row amends row 449's "drains a pipe". The mutant claim still holds at HEAD. Mutant `capped_read drain |` → `capped_read |`: command `bash mutants.sh nodrain ...`, exit 1, 20:16:18Z, killed by the 4 MiB test (`logs/mutant-nodrain.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:701-709`, `scripts/lib/dev-cycle-read.sh:837-840`, `/tmp/u2a3c-i2-fc3-j0eh/logs/mutant-nodrain.log`

---

## Claim 4: Override row 450: "80cc6224: main_checkout memoizes the ancestors it has passed (18 realpath calls in the test's walk, against 102 unmemoized and 74 at 3e58eb9c); it also fixed a crash on an empty main tree with an untracked start"

**Location:** `docs/reviews/override-log.md:450`
**Type:** Performance / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at 80cc6224, for its no-memo mutant and at 3e58eb9c, and the empty-tree crash at 27364085. It does not establish HEAD's count, which is now 10 (see Claim 30).

Command: `bash rpcount.sh <lib> <label>` (exit 0, 20:15:32Z): 3e58eb9c 74, 80cc6224 18, 80cc6224 with `mc_m[$c]=1`→`:` 102, 21b35ebf 18, 3a35c8b9 10 (`logs/realpath-counts.log`). The empty-tree test on 27364085's lib gives `not ok` with `1  .../dev-cycle-read.sh: line 699: mc_e: unbound variable` (`logs/old-27364085-tree_is_empty.log`, 20:14:21Z).

**Evidence:** `test/scripts/build-loop-check.bats:821-840`, `/tmp/u2a3c-i2-fc3-j0eh/logs/realpath-counts.log`, `/tmp/u2a3c-i2-fc3-j0eh/logs/old-27364085-tree_is_empty.log`

---

## Claim 5: Override rows 451 and 455: IMPORT_WORK_MAX "bounds the work charged over a whole walk, so N adversarial files cost one bound"; "capped_read's drain ... and the scan of @-less lines are uncharged, and a caller running both walks pays two bounds"; "Comment states both."

**Location:** `docs/reviews/override-log.md:451`, `docs/reviews/override-log.md:455`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk-wide charge in all three read arms and the comment's statement of what is uncharged. It does not establish row 455's "about 0.7 s per GiB", which I did not measure.

Each arm passes `IMPORT_WORK_LEFT=$((IMPORT_WORK_MAX - work))` and charges `import_work out work` (`scripts/lib/dev-cycle-read.sh:775-776`, `:837-840`). The comment says "reading, draining and the scan of @-less lines are not charged ... The bound is per walk: a caller that runs both walks pays up to two" (`:507-509`). Each walk keeps its own `work=0` local (`:757`, `:802`). Mutant `IMPORT_WORK_LEFT=$IMPORT_WORK_MAX` (per-file): exit 1, 20:16:17Z, killed by T3 (`logs/mutant-perfile.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:504-511`, `scripts/lib/dev-cycle-read.sh:757`, `scripts/lib/dev-cycle-read.sh:802`, `/tmp/u2a3c-i2-fc3-j0eh/logs/mutant-perfile.log`

---

## Claim 6: Override row 452: "Iteration 2 restored A5's cache-clear sentence, FIFO and snapshot items, and the U2b clause (plus the MEMO rule for another main_checkout caller)"

**Location:** `docs/reviews/override-log.md:452`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the presence of the restored text. Its accuracy is checked in Claims 9-14.

A5 says "a caller clears `IMPORTED_MAIN_DONE` after any checkout change", "a start file that is not a regular file or symlink (git does not list a FIFO), a checkout file swapped between its admission and its read" (`docs/working/known-issues-dev-cycle.md:18`). U2b says it "owes the walk three things" and "A caller of `main_checkout` other than `main_imports` passes a fresh MEMO per walk and ENT" (`docs/working/plan-build-loop-handoff.md:279`).

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `docs/working/plan-build-loop-handoff.md:279`

---

## Claim 7: Override row 453: "main_imports records the parser's whole output before the seen test, so a start already seen is still recorded by structure"; T5 pins it

**Location:** `docs/reviews/override-log.md:453`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order of the record and the seen test, and T5 passing at HEAD. It does not establish a mutation test of a per-candidate record, which I did not run.

```bash
# scripts/lib/dev-cycle-read.sh:866-869
    i="$(lower "$out")" || { IMPORTED_MAIN=error; return 1; }; IMPORTED_MAIN+="$i"$'\n'
    while IFS= read -r p; do
      [[ -n "$p" ]] || continue
      [[ -z "${seen[$p]+set}" ]] || continue
```
(excerpt ends :869; the enclosing loop continues to :874 — read). T5 (`test/scripts/build-loop-check.bats:921-930`) expects `docs/AGENTS.md imported` for a start that main's CLAUDE.md also imports, and it passes at HEAD (`logs/build-loop-check.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:863-874`, `test/scripts/build-loop-check.bats:921-930`

---

## Claim 8: Override rows 454 and 456: "The symlink arm fails link text over 4096 bytes (`git cat-file -s`) before reading it; test added"; "main_checkout's comment now says why it differs from blocker"

**Location:** `docs/reviews/override-log.md:454`, `docs/reviews/override-log.md:456`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the size check, its position before both reads, its test and the blocker sentence. It does not establish row 454's figure for a 256 MiB blob (58 s, 2 GiB).

`i="$(git cat-file -s "$MAIN_SHA:$f")" && [[ "$i" -le 4096 ]] || { IMPORTED_MAIN=error; return 1; }` (`scripts/lib/dev-cycle-read.sh:843`) precedes the two `git cat-file blob` reads (`:846-847`). Mutant without `&& [[ "$i" -le 4096 ]]`: exit 1, 20:16:48Z, killed (`logs/mutant-nosizecap.log`). The comment reads "unlike blocker it answers 2 below a plain file and needs a searchable directory (a second traversal on purpose)" (`:730-731`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:841-859`, `scripts/lib/dev-cycle-read.sh:729-731`, `/tmp/u2a3c-i2-fc3-j0eh/logs/mutant-nosizecap.log`

---

## Claim 9: Known issue A5: the checkout phase "walks, and only appends: the checkout's start files main lacks (untracked, ignored, or only in the index) and the imported files main lacks, when each is a plain file there; a checkout path it would walk that lies under a directory main stores as a link or gitlink or under an unsearchable directory, anything but a plain file or directory there (or nothing), an unreadable checkout file, a `..` after a checkout link in link text, and a checkout listing git prints any stderr for fail it; a linked worktree's `.git` file is read like any checkout file."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed fail rule and the gitfile read, through the code and passing tests. It does not establish behaviour under a non-default git environment, which the U2b clause covers.

The rules are in main_checkout (`scripts/lib/dev-cycle-read.sh:742-753`), the symlink arm (`[[ "${ent[$p]:-}" != 120000 && ! -L "$p" ]] || lk=1`, `:856`) and checkout_md (`... && [[ -z "$e" ]]`, `:716`). The gitfile test passes at HEAD (`test/scripts/build-loop-check.bats:411-420`). Mutants that remove the mode check, the `-x` test or the readability test are each killed (`logs/mutant-nomode.log`, `mutant-nox.log`, `mutant-unreadable.log`, 20:16:24-20:16:46Z).

**Evidence:** `scripts/lib/dev-cycle-read.sh:716`, `scripts/lib/dev-cycle-read.sh:732-755`, `scripts/lib/dev-cycle-read.sh:852-857`, `/tmp/u2a3c-i2-fc3-j0eh/logs/mutant-nomode.log`

---

## Claim 10: Known issue A5: "The walk's cache ignores the checkout, so a caller clears `IMPORTED_MAIN_DONE` after any checkout change (the lib's block comment above `IMPORTED=` holds the caller contract; the U2b bullet names what U2b owes it)."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Architectural / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cache key and the lib comment's contents. It does not establish that any caller honours the contract (none exists before U2a4/U2b).

The key is `"$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"` (`scripts/lib/dev-cycle-read.sh:806-807`). The lib comment holds the cache-clear and HOME-clear duties: "so a caller whose checkout may have changed (a file added or edited) sets IMPORTED_MAIN_DONE="" to walk again ... A caller that changes HOME clears both" (`:488-491`). It does not hold the git-environment duty (GIT_INDEX_FILE, fsmonitor, sparse checkout and so on) or the `LC_ALL=C` duty. `grep -n 'GIT_INDEX_FILE\|fsmonitor\|sparse' scripts/lib/dev-cycle-read.sh` finds nothing (paraphrased; no quote is available because the claim concerns text that is absent). Those duties appear only in the U2b bullet and the override log. A precise version would say the lib comment holds the cache rules and the U2b bullet holds the rest.

**Evidence:** `scripts/lib/dev-cycle-read.sh:486-496`, `docs/working/plan-build-loop-handoff.md:279`

---

## Claim 11: Known issue A5 / lib comment: "a start file that is not a regular file or symlink (git does not list a FIFO)" is not covered; "the walk reads the checkout as one snapshot"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39's listing of a FIFO named like a start. It does not establish whether Claude Code loads a FIFO.

Command (cwd: a fresh repo under `/tmp/u2a3c-i2-fc3-j0eh/fz`, holding a `mkfifo AGENTS.md` and a plain GEMINI.md): `git ls-files -z --cached --others -- ':(glob,icase)**/*.md'`. Exit 0, 2026-10-07T20:19Z. It listed only `GEMINI.md` (`logs/fifo-ls.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:483-485`, `scripts/lib/dev-cycle-read.sh:713-716`, `/tmp/u2a3c-i2-fc3-j0eh/logs/fifo-ls.log`

---

## Claim 12: Plan F11: "one admission check (`main_checkout`) refuses a path under a link or gitlink main stores, under an unsearchable directory, or anything but a plain file or directory, and a checkout listing git prints any stderr for fails the walk; the caller contract (cache clear, empty `ls-files` stderr, the git environment) is in the U2b bullet."

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the listed refusals and the pointer to the U2b bullet. It does not cover the unreadable-file refusal, which F11 omits (A5 and the U2a3c bullet state it).

`[[ ! "${mc_e[$c]:-}" =~ ^1[26]0000$ ]] || return 1`; `elif ! plaindir "$c" || [[ ! -x "$c" ]]; then return 1`; `plaindir "$c" || return 1` (`scripts/lib/dev-cycle-read.sh:742`, `:745`, `:752`). The U2b bullet lists all three duties (`docs/working/plan-build-loop-handoff.md:279`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:732-755`, `docs/working/plan-build-loop-handoff.md:126`, `docs/working/plan-build-loop-handoff.md:279`

---

## Claim 13: Plan U2a3c bullet: "Built 2026-10-07 ...: the fail rules as stated (a readable plain file main lacks is walked; a non-plain node, an unreadable file, or a path under main's link or gitlink or under an unsearchable directory fails), `capped_read`, the work bound `IMPORT_WORK_MAX` (reported by the parser's trailer, charged by `import_work`), `main_checkout`'s ancestor memo, the `.git` rule, and N1 (`lower_all` under `nul_list`)."

**Location:** `docs/working/plan-build-loop-handoff.md:277`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the presence and behaviour of each named item. It does not establish the bullet's earlier, pre-existing design text.

Each item exists and its test passes at HEAD. The trailer is `END { if (trail) print "/" (work + 0) }` (`scripts/lib/dev-cycle-read.sh:629`), and import_work is at `:677-682`. The `.git` special case is gone: paraphrased; no quote is available because the claim concerns removed code (`git diff main...HEAD` deletes the `if [[ "$p" == .git ]]` block).

**Evidence:** `scripts/lib/dev-cycle-read.sh:626-629`, `scripts/lib/dev-cycle-read.sh:677-709`, `/tmp/u2a3c-i2-fc3-j0eh/logs/build-loop-check.log`

---

## Claim 14: Plan U2b bullet: the walk is owed "that checkout final before the walk, or `IMPORTED_MAIN_DONE` cleared ...; a git that prints nothing on stderr for `ls-files` (any stderr fails the walk closed); and the git environment ... A caller of `main_checkout` other than `main_imports` passes a fresh MEMO per walk and ENT (a MEMO hit skips main's mode check too)"

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Architectural / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three duties and the MEMO rule. It does not establish that the stated rule is complete for another caller (residue below).

The three duties match the code (`scripts/lib/dev-cycle-read.sh:716`, `:806`). The MEMO rule leaves out a third condition. A caller must not pass a PATH that ENT stores. main_checkout never reads `mc_e[$3]`, but it memoizes a searchable plain directory at PATH as `d` (`[[ ! -x "$c" ]] || mc_m[$c]=d`, `:753`). A later call below PATH then skips PATH's link check. Command (cwd: a scratch repo holding a plain directory `c`, `declare -A E=([c]=120000)`): `main_checkout E MN c` then `main_checkout E MN c/x.md`. Output: `c new=2 old=2`, `c/x.md new=2 old=1`, and `c/x.md` with a fresh memo `new=1` (`logs/memo-path-ent.log`, exit 0, 2026-10-07T20:13Z). Both current callers guard this. The start loop runs main_checkout only for `t:` candidates, which are added only when `ent` lacks them (`:819`, `:825`), and the import loop runs it only when `[[ -n "${ent[$p]+set}" ]]` fails (`:870`). The precise rule is "a fresh MEMO per walk and ENT, and a PATH that ENT does not hold".

**Evidence:** `scripts/lib/dev-cycle-read.sh:749-754`, `scripts/lib/dev-cycle-read.sh:819-825`, `scripts/lib/dev-cycle-read.sh:870`, `/tmp/u2a3c-i2-fc3-j0eh/logs/memo-path-ent.log`

---

## Claim 15: Lib header: "main_imports reads main's commit first and then the working tree (the checkout's start files and imported files main lacks, which can only add imports or fail it ...); imported_names, checkout_md and main_checkout read the working tree at ROOT_REAL."

**Location:** `scripts/lib/dev-cycle-read.sh:36-39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers append-only recording and the read order. It does not establish the path checks that phase 1 makes in the checkout (main_checkout runs on imports main lacks during main's walk too), which can also only fail the walk.

`IMPORTED_MAIN+="$i"$'\n'` is the only write to the result after `IMPORTED_MAIN=$'\n'` (`:831`, `:866`). Phase 2 starts only when `queue` is empty: `[[ ${#queue[@]} -gt 0 ]] || { queue=("${tq[@]}"); tq=(); }` (`:833`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:831-875`

---

## Claim 16: Lib block comment (main_imports): "a checkout path it would walk ... under a directory main stores as a symlink or gitlink or under an unsearchable directory, or that the checkout holds as anything but a readable plain file, a plain directory or nothing (the root included), or a checkout listing git prints any stderr for, fail the walk ... A linked worktree's .git file and files under .git are checkout files like any other."

**Location:** `scripts/lib/dev-cycle-read.sh:470-477`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these rules through main_checkout, checkout_md and the three inverted `.git` tests. It does not establish behaviour for a start under `.git` (git lists none).

See Claims 9 and 40. Nothing in main_imports special-cases `.git` (`grep -n '\.git' scripts/lib/dev-cycle-read.sh` finds no `.git` test in `:801-876`; paraphrased because the claim concerns absent code).

**Evidence:** `scripts/lib/dev-cycle-read.sh:460-495`, `scripts/lib/dev-cycle-read.sh:801-876`

---

## Claim 17: Lib cache comment: the result "is cached for the commit, MAIN_BY_NAME and root in IMPORTED_MAIN_DONE, never the checkout, whose files it read, so a caller whose checkout may have changed ... sets IMPORTED_MAIN_DONE="" to walk again, and a cached error returns 1 again."

**Location:** `scripts/lib/dev-cycle-read.sh:486-490`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the key and the stale answer until the key is cleared. It does not establish any caller's clearing.

`[[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }` (`:806`). The cache test expects `- - z.sh` (a checkout edit is not seen, then is seen once the key is cleared), and it passes at HEAD (`test/scripts/build-loop-check.bats:330-339`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:806-807`, `test/scripts/build-loop-check.bats:330-339`

---

## Claim 18: "Each walk also fails once the parser's work (the candidate and comment-splice characters it scans, the unit of its per-file bound of 50,000,000, about 5 s) passes this in all"

**Location:** `scripts/lib/dev-cycle-read.sh:504-505`
**Type:** Behavioral / Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the parser charges. It does not establish the "about 5 s" timing on this host (the iteration-2 fact-check measured 4.04 s at the bound).

The parser also charges the resolved spelling of each candidate in `put`, not only scanned candidate and splice characters:
```awk
# scripts/lib/dev-cycle-read.sh:580-584
function put(c,   n, i, k, part, st, out) {
  if (substr(c, 1, 1) != "/") c = root "/" dir "/" c
  # The resolved spelling is what costs (its length grows with the depth of
  # the importing file), so it is charged too, and each is resolved once per file.
  work += length(c); if (work > wmax) exit 3
```
(excerpt ends :584; the enclosing put() continues to :600 — read). A precise version: "the candidate, resolved-path and comment-splice characters it charges".

**Evidence:** `scripts/lib/dev-cycle-read.sh:565-622`

---

## Claim 19: "/workspace's walks spend about 8,100 each (2026-10-07)."

**Location:** `scripts/lib/dev-cycle-read.sh:508`
**Type:** Configuration / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers /workspace's checkout at main e5d0f838 today. The figure drifts as the checkout changes.

Command: `bash /tmp/u2a3c-i2-fc3-j0eh/work.sh lib-3a35c8b9.sh /workspace` (it wraps import_work to sum the trailers). Exit 0, 2026-10-07T20:15:50Z. Output: `tree ok work=8110 ms=1163`, `main ok work=8110 ms=1343` (`logs/workspace-work.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:673-682`, `/tmp/u2a3c-i2-fc3-j0eh/logs/workspace-work.log`

---

## Claim 20: import_targets' comment on IMPORT_WORK_LEFT: "Unset or empty: no trailer and only the per-file bound; not a number: 0, so the first candidate fails it"

**Location:** `scripts/lib/dev-cycle-read.sh:524-528`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unset, empty, non-numeric and numeric inputs. It does not establish anything for the walks, which always pass a non-negative integer.

Command (cwd: a scratch repo): `printf 'see @ab.md\n' | IMPORT_WORK_LEFT=<v> import_targets ""` for each value. Exit 0, 2026-10-07T20:17Z (`logs/iwl-variants.log`). Unset and `""` print five names and no trailer. `abc` gives rc=1 after one character. However, `5x` reads as 5, not 0 (rc=1 at `/37`), because awk's `ENVIRON["IT_WORK"] + 0` takes the leading digits (`:626`). With no candidate, `abc` succeeds and prints `/0`. The precise version is "not a number: its leading digits, 0 when it has none".

**Evidence:** `scripts/lib/dev-cycle-read.sh:626`, `/tmp/u2a3c-i2-fc3-j0eh/logs/iwl-variants.log`

---

## Claim 21: import_work "strips the parser's work trailer (its last line, "/N" ...) from the variable OUT, and adds N to the variable TOTAL. It returns 1 when the trailer is missing or TOTAL passes IMPORT_WORK_MAX."

**Location:** `scripts/lib/dev-cycle-read.sh:673-682`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the strip, the charge and both failures. It does not cover the no-leading-`/` invariant on names, which import_targets' resolution enforces (`out = substr(out, length(pre) + 1)`, `:595`).

The import_work test expects `1 ok [a.md] 17`, `3 failed`, `4 failed` and `5 failed 31`, and it passes at HEAD (`test/scripts/build-loop-check.bats:842-851`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:677-682`, `test/scripts/build-loop-check.bats:842-851`

---

## Claim 22: capped_read: "the first 4 MiB + 1 bytes of stdin, the one reader both walks parse, for checkout files and main's blobs alike ... With the word drain (after git cat-file) it reads the rest"; checkout files and the tree walk read `< file` without drain

**Location:** `scripts/lib/dev-cycle-read.sh:701-709`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the byte cap, the call sites and the drain. It does not cover link blobs, which are not parsed and are capped separately (Claim 8).

`head -c 4194305` is 4·1048576 + 1. `capped_read < "$f"` (`:775`, `:837`) and `git cat-file blob ... | capped_read drain` (`:839`). The 4 MiB test passes at HEAD and fails at 3e58eb9c (`logs/old-3e58eb9c-reads_only_the_first_4_MiB___1.log`, 20:14:21Z). The no-drain mutant is killed (Claim 3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:709`, `scripts/lib/dev-cycle-read.sh:775`, `scripts/lib/dev-cycle-read.sh:837-840`

---

## Claim 23: "an argument, not a [[ -p /dev/stdin ]] test, which needs /proc"

**Location:** `scripts/lib/dev-cycle-read.sh:706-707`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers this host's `/dev/stdin`. It does not establish bash's behaviour with /proc unmounted.

`ls -l /dev/stdin` shows `/dev/stdin -> /proc/self/fd/0`. Bash's manual says it uses these files when the OS provides them and emulates them otherwise, so with /proc absent the symlink would dangle (paraphrased; no quote is available because the source is the bash manual, not this repo). Execution was blocked: `unshare -rm` fails with `Operation not permitted`, and no strace is installed. Confirming this needs a mount namespace without /proc (Q-127).

**Evidence:** `scripts/lib/dev-cycle-read.sh:706-709`

---

## Claim 24: "Claude Code skips a file over 4 MiB"

**Location:** `scripts/lib/dev-cycle-read.sh:702-703`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing about Claude Code's runtime. The sentence was moved unchanged from main (`git show main:scripts/lib/dev-cycle-read.sh` line 686).

Verifying it needs Claude Code 2.1.292's reader, which this pass did not probe.

**Evidence:** `scripts/lib/dev-cycle-read.sh:701-704`

---

## Claim 25: main_checkout returns "0 for a readable plain checkout file to walk, 2 when nothing there loads (absent, below an absent ancestor or a plain file, or a plain directory), 1 to fail the walk ..."; the bottom-up memo "Bottom up to the nearest decided ancestor, then top down from it" preserves 21b35ebf's answers

**Location:** `scripts/lib/dev-cycle-read.sh:724-755`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every return code for calls that keep the callers' contract (PATH not in ENT), across random checkout shapes and call orders against 21b35ebf's top-down version. It does not cover a PATH that ENT holds (Claims 14 and 26).

Differential fuzz: `bash fuzz.sh lib-head.sh oldmc.sh <seed> <n> fz` and `fuzz2.sh`, seeds 1-4. Cwd was fresh directories under `/tmp/u2a3c-i2-fc3-j0eh/fz`. Exit 0, 2026-10-07T20:12-20:13Z. Each tree held random absent nodes, searchable, unsearchable and unreadable directories, readable and unreadable files, links to `.`, to a missing target and to `/etc/hostname`, and FIFOs, to depth 4. ENT held random 120000, 160000 and 100644 entries, and each tree got 25 calls in random order with a separate memo per version. Result: 20,975 calls (6,970 + 4,675 + 4,647 + 4,683), 0 mismatches. The distribution across seeds 2-4 was 0: 272, 1: 6,505, 2: 7,228. Seed 2 was re-run to a file: `total=4675 mismatches=0`, exit 0 (`logs/fuzz-seed2.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:732-755`, `/tmp/u2a3c-i2-fc3-j0eh/fuzz.sh`, `/tmp/u2a3c-i2-fc3-j0eh/oldmc.sh`, `/tmp/u2a3c-i2-fc3-j0eh/logs/fuzz-seed2.log`

---

## Claim 26: MEMO values are "set only once its own and every higher ancestor's main mode passed. A MEMO hit skips that mode check too, so a MEMO serves one walk and one ENT."

**Location:** `scripts/lib/dev-cycle-read.sh:720-723`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers memo entries set in the ancestor loop (`:747`) and the one set at PATH (`:753`). It does not establish anything beyond the two current callers.

For ancestors the claim holds. `mc_m[$c]="$st"` (`:747`) runs only after `[[ ! "${mc_e[$c]:-}" =~ ^1[26]0000$ ]] || return 1` (`:742`), and every higher ancestor was either checked earlier in the same loop or was itself a memo hit. The PATH entry `[[ ! -x "$c" ]] || mc_m[$c]=d` (`:753`) is set without checking `mc_e[$3]`. Its "own mode passed" only because both callers pass a PATH that ENT lacks. When the fuzz let PATH be a path ENT holds (`fuzz3.sh`, seed 7, 7,500 calls, exit 0), it found 97 mismatches against 21b35ebf, for example `p=c/a old=1 new=2 ENT=([c]="120000" ...)`. See Claim 14 for the minimal reproduction.

**Evidence:** `scripts/lib/dev-cycle-read.sh:739-754`, `/tmp/u2a3c-i2-fc3-j0eh/logs/memo-path-ent.log`, `/tmp/u2a3c-i2-fc3-j0eh/logs/fuzz3-seed7.log`

---

## Claim 27: "unlike blocker it answers 2 below a plain file and needs a searchable directory"

**Location:** `scripts/lib/dev-cycle-read.sh:730-731`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the comparison with blocker's ancestor loop. It does not cover blocker's leaf rule.

blocker prints the first existing non-plain-directory part: `plaindir "$p" || { printf '%s/' "$p"; return 0; }` (`:117-119`). It has no `-x` test, so a plain file ancestor blocks there, while main_checkout sets `st=2` (`:744`) and tests `[[ ! -x "$c" ]]` (`:745`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:114-124`, `scripts/lib/dev-cycle-read.sh:743-746`

---

## Claim 28: "Link text past PATH_MAX (4096) names nothing; it fails before the two whole reads below."

**Location:** `scripts/lib/dev-cycle-read.sh:842-843`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Linux's limit on link text and the order of the check. It does not cover other OSes.

Command: `ln -s <n×a> l<n>` for n = 4095, 4096 and 4097 (cwd: a scratch dir, 2026-10-07T20:18Z). 4095 was created and 4096 and 4097 were refused (`logs/ln-pathmax.log`). The `-le 4096` check therefore admits one length that cannot be a link, which only over-reads. The 4096 test fails at 21b35ebf (`walk: ok` twice; `logs/old-21b35ebf-longer_than_4096.log`) and passes at HEAD.

**Evidence:** `scripts/lib/dev-cycle-read.sh:843-847`, `/tmp/u2a3c-i2-fc3-j0eh/logs/ln-pathmax.log`

---

## Claim 29: "main lacks p: admitted before it is marked seen"; main_imports' failure list ("main_checkout refuses a start or an import main lacks, a blob or checkout file cannot be read ... or the IMPORT_OUT_MAX or IMPORT_WORK_MAX budget is spent")

**Location:** `scripts/lib/dev-cycle-read.sh:787-800`, `scripts/lib/dev-cycle-read.sh:870`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the order of admission and the seen mark, and each listed `return 1`. It does not cover start candidates main stores (`m:`), which skip main_checkout by design.

`c=0; [[ -n "${ent[$p]+set}" ]] || main_checkout ent pok "$p" || c=$?` then `[[ $c -ne 1 ]] || { IMPORTED_MAIN=error; return 1; }` then `seen[$p]=1` (`:870-872`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:801-876`

---

## Claim 30: L2-C6 test comment: "memoized, each directory once, plus each candidate's own check (18)"

**Location:** `test/scripts/build-loop-check.bats:822-825`
**Type:** Performance
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the realpath count at HEAD. The assertion `-le 30` still passes.

The comment dates from 80cc6224 (unchanged since then). At HEAD the count is 10, not 18, because a searchable directory at PATH is memoized (`:753`), so each directory candidate's own check is also the check its longer candidates reuse. `rpcount.sh` at 3a35c8b9 gives `realpath calls=10` (`logs/realpath-counts.log`, 20:15:32Z).

**Evidence:** `test/scripts/build-loop-check.bats:821-832`, `/tmp/u2a3c-i2-fc3-j0eh/logs/realpath-counts.log`

---

## Claim 31: T1 title: "main_checkout answers each checkout shape: 0 for a readable plain file, 2 where nothing loads, 1 for anything it does not model, and memoizes only plain searchable directories"

**Location:** `test/scripts/build-loop-check.bats:853`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what T1 asserts. It does not establish anything beyond the 17 shapes listed.

The memo also holds `2` entries for absent and file ancestors (`mc_m[$c]="$st"`, `scripts/lib/dev-cycle-read.sh:747`). The test checks only the keys whose value is `d`: `[[ "${M[$k]}" != d ]] || echo "$k"` (`test/scripts/build-loop-check.bats:860`). The precise title is "memoizes as d only plain searchable directories". T1 kills the nomode, nox, pathmemo-any, unreadable and skip-mode-below-2 mutants (`logs/mutant-*.log`).

**Evidence:** `test/scripts/build-loop-check.bats:853-883`, `/tmp/u2a3c-i2-fc3-j0eh/logs/mutant-pathmemo-any.log`

---

## Claim 32: Deep-token test: "@a/a/.../x.md, 1,000 levels deep, none in the checkout: about 0.6 s; 21b35ebf's top-down loop rescanned every absent ancestor per prefix candidate (10.7 s)"; title "stays linear"

**Location:** `test/scripts/build-loop-check.bats:932-940`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the two timings on this host and the test catching 21b35ebf. It does not establish linearity (one depth only), or the test's discrimination on a host more than about 1.8× faster, where 21b35ebf would finish under `timeout 6`.

See Claim 1 for the timings (658/652 ms; 10461/10864 ms). The margin at HEAD is about 9× below the 6 s timeout. The mutant that stops at a `2` ancestor without mode-checking deeper ones also times out here, and it is killed by T1 and T2 as well (`logs/mutant-memo-skip-mode-below-2.log`).

**Evidence:** `test/scripts/build-loop-check.bats:932-940`, `/tmp/u2a3c-i2-fc3-j0eh/logs/deep-timing.log`

---

## Claim 33: Link-text test title: "main walk fails on link text main stores longer than 4096 bytes before reading it whole"

**Location:** `test/scripts/build-loop-check.bats:942`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal of a 4097-byte link and the acceptance of `r.md`. It does not cover "before reading it whole", which the test cannot observe.

The test asserts only `walk: failed` then `walk: ok`: `[ "$(cat "$BATS_TEST_TMPDIR/got")" = $'walk: failed\nwalk: ok' ]` (`:949`). The ordering holds statically (Claim 8).

**Evidence:** `test/scripts/build-loop-check.bats:942-950`

---

## Claim 34: T5 title: "main walk reads an untracked start that a main file also imports once, through the checkout"; T2 title: "fails on a path under a link main stores below a directory the checkout lacks, and walks a path under a plain file"

**Location:** `test/scripts/build-loop-check.bats:884`, `test/scripts/build-loop-check.bats:921`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the asserted results. For T5's "once", the read count holds statically (`seen`) but is not asserted.

T2 kills the nomode and skip-mode-below-2 mutants (`logs/mutant-nomode.log`, `mutant-memo-skip-mode-below-2.log`). T5 expects `docs/AGENTS.md imported` and `docs/x.md imported`, then `walk failed` for a symlinked start (`:921-930`).

**Evidence:** `test/scripts/build-loop-check.bats:884-895`, `test/scripts/build-loop-check.bats:921-930`

---

## Claim 35: The three inverted U2a3b `.git` tests: the gitfile is read "as a checkout file", an imported file under `.git` is read and followed, and a nested `.git` file is read

**Location:** `test/scripts/build-loop-check.bats:411`, `test/scripts/build-loop-check.bats:657`, `test/scripts/build-loop-check.bats:700`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk's behaviour on these shapes. It does not establish Claude Code's reading of a gitfile (rubric C9, host probe Q-126).

Each test now expects `walk ok` and the import followed (diff lines `want walk ok; want docs/x.md imported`, `want docs/t.md imported`, `want docs/e.md imported`), and all three pass at HEAD (`logs/build-loop-check.log`).

**Evidence:** `test/scripts/build-loop-check.bats:411-420`, `test/scripts/build-loop-check.bats:657-664`, `test/scripts/build-loop-check.bats:700-712`

---

## Claim 36: dev-cycle.bats function inventory gains md_ls, checkout_md, main_checkout, lower_all, capped_read, import_work

**Location:** `test/scripts/dev-cycle.bats:1110`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the existence of each listed function. It does not establish inventory completeness for other files.

Each is defined (`scripts/lib/dev-cycle-read.sh:677`, `:693`, `:700`, `:709`, `:716`, `:732`), and dev-cycle passes 78/78 (`logs/dev-cycle.log`).

**Evidence:** `test/scripts/dev-cycle.bats:1106-1113`

---

## Claim 37: Commit 2fbd929b: "main_checkout walks its ancestors bottom up to the nearest decided one and memoizes every result (d or 2), and a searchable directory at PATH: ... (performance F1: D=1000 took 10.7 s at 21b35ebf, 0.6 s now, main 0.5 s; test added)"; "capped_read drains only when told"; "Tests: ... T1-T5 ... the inventory gains import_work, the stale :69 comment fixed. 63/78/19/2."; "shellcheck SC2034 on pok"

**Location:** commit 2fbd929b message
**Type:** Reference / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the timings, the counts, the inventory diff (2fbd929b adds only `import_work`) and the `:69` comment. It does not establish the shellcheck failure at 61e2e734, which I did not re-run; the `# shellcheck disable=SC2034` line is present (`:803`).

See Claims 1 and 36. `git show 2fbd929b -- test/scripts/dev-cycle.bats` adds ` import_work` only. Line 69 now reads "the main walk's checkout phase does too; the next test pins it", and the next test does walk untracked, ignored and index-only starts (`test/scripts/build-loop-check.bats:77-95`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:739-754`, `test/scripts/build-loop-check.bats:69`, `/tmp/u2a3c-i2-fc3-j0eh/logs/deep-timing.log`

---

## Claim 38a: Commit 3e58eb9c: "Tests: build-loop-check 51/51, build-loop-read 19/19, dev-cycle 78/78, fixture-git-env 2/2."; "Three U2a3b tests that pinned the interim fail-closed rule for .git paths now expect the walk to read them."

**Location:** commit 3e58eb9c message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four suite results at 3e58eb9c and the three inverted tests. It does not cover suites the message does not name.

Command: bats over `git archive 3e58eb9c`, cwd `/tmp/u2a3c-i2-fc3-j0eh/repo-3e58`, 2026-10-07T20:18:49-20:19:20Z, every run exit 0. Results: build-loop-check ok=51, build-loop-read ok=19, fixture-git-env ok=2, dev-cycle ok=78 (`logs/at3e58-*.log`).

**Evidence:** `/tmp/u2a3c-i2-fc3-j0eh/logs/at3e58-build-loop-check.log`, `/tmp/u2a3c-i2-fc3-j0eh/logs/at3e58-dev-cycle.log`

---

## Claim 38b: Commit 3e58eb9c: "squash-rebase chosen over a per-commit rebase (same final tree ...)"

**Location:** commit 3e58eb9c message
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing. A per-commit rebase was never completed (the message says it conflicted), so no tree exists to compare.

Verifying it would need a per-commit rebase of `backup/u2a3c-pre-rebase-2b1399ab` onto 581d41d8, with the conflicts resolved, and a comparison of trees.

**Evidence:** commit 3e58eb9c message

---

## Claim 39: Commit 27364085: "both new tests fail on 3e58eb9c's lib; a mutant without the drain fails the 4 MiB test (walk failed)"; "imported_names reads through it too"

**Location:** commit 27364085 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claims at their commit's mechanism and at HEAD's. It does not cover the message's "from a pipe it drains", which described 27364085's `-p` test and was superseded in 2fbd929b (Claim 3).

See Claims 2, 3 and 22. `capped_read < "$f"` appears in imported_names (`scripts/lib/dev-cycle-read.sh:775`).

**Evidence:** `/tmp/u2a3c-i2-fc3-j0eh/logs/old-3e58eb9c-batch_tr_dies.log`, `/tmp/u2a3c-i2-fc3-j0eh/logs/mutant-nodrain.log`

---

## Claim 40: Commit 80cc6224: "A test's realpath count: 18, against 102 unmemoized and 74 at 3e58eb9c"; "an empty main tree with an untracked start killed the caller's shell (test added; it fails at 27364085)"

**Location:** commit 80cc6224 message
**Type:** Reference / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at 80cc6224 and the crash at 27364085. HEAD's count is 10.

See Claim 4.

**Evidence:** `/tmp/u2a3c-i2-fc3-j0eh/logs/realpath-counts.log`, `/tmp/u2a3c-i2-fc3-j0eh/logs/old-27364085-tree_is_empty.log`

---

## Claim 41a: Commit 61e2e734: "Measured 2026-10-07: /workspace's walks spend about 8,100 each (1.1 s tree, 1.4 s main; the main walk now passes on this developer checkout, which failed closed before U2a3c)"; "Without IMPORT_WORK_LEFT the parser's output is unchanged"; "a per-file mutant passes at 3w - 1 and fails the test"; "about 6,000x this repo's real work"

**Location:** commit 61e2e734 message
**Type:** Reference / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the work figure, the timings, main's fail-closed result, the unset behaviour and the mutant (against HEAD's 4w test, which replaced the 3w one). It does not cover the mutant against the 61e2e734 test file (the iteration-2 fact-check ran that).

Results: work 8110 and 1163/1343 ms (Claim 19). main's lib on /workspace gives `main-lib main walk failed` (`logs/workspace-mainlib.log`, exit 0, 20:15:56Z). Unset produces no trailer (Claim 20). 50,000,000 / 8,110 ≈ 6,165. The per-file mutant is killed (Claim 5).

**Evidence:** `/tmp/u2a3c-i2-fc3-j0eh/logs/workspace-work.log`, `/tmp/u2a3c-i2-fc3-j0eh/logs/workspace-mainlib.log`, `/tmp/u2a3c-i2-fc3-j0eh/logs/mutant-perfile.log`

---

## Claim 41b: Commit 61e2e734 Notes: "the limit equals the old per-file bound, so the whole walk costs at most what one file could"

**Location:** commit 61e2e734 message
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers charged parser work. It does not cover uncharged work.

This holds for charged parser work. Reading, draining and the @-less scan are uncharged, as the lib comment states: "reading, draining and the scan of @-less lines are not charged" (`scripts/lib/dev-cycle-read.sh:507-508`). Override row 455 already narrows this.

**Evidence:** `scripts/lib/dev-cycle-read.sh:504-511`, `docs/reviews/override-log.md:455`

---

## Claim 42: Commit cb9723c3: "override-log.md: U2a3b's rows and U2a3c's 9 rows both kept (append-only)"; commit 21b35ebf closes four rows (N1, L2-C5, L2-C6, P2)

**Location:** commits cb9723c3 and 21b35ebf messages
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row counts. Rows 439-447 are history and are not re-verdicted here.

The diff appends nine U2a3c rows dated 2026-10-06 (`docs/reviews/override-log.md:439-447`), four closing rows (`:448-451`) and five iteration-2 rows (`:452-456`). It deletes no rows (paraphrased; no quote is available because the claim concerns the diff's shape: `git diff main...HEAD -- docs/reviews/override-log.md` shows only `+` lines).

**Evidence:** `docs/reviews/override-log.md:439-456`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
- **Claim 3** (`docs/reviews/override-log.md:449`): The row says capped_read "drains a pipe". Since 2fbd929b it drains only when the blob arm passes `drain`. Row 454 corrects only the link-blob half.
- **Claim 30** (`test/scripts/build-loop-check.bats:825`): The comment's "(18)" realpath calls are now 10 at HEAD, because PATH directories are memoized.

### Mostly Accurate
- **Claim 10** (`docs/working/known-issues-dev-cycle.md:18`): The lib comment above `IMPORTED=` holds the cache and HOME rules, not the whole caller contract. The git-environment and `LC_ALL` duties are only in U2b.
- **Claim 14** (`docs/working/plan-build-loop-handoff.md:279`): The MEMO rule for another caller should add "and a PATH that ENT does not hold". A PATH memoized `d` skips its own link check for later calls.
- **Claim 18** (`scripts/lib/dev-cycle-read.sh:504-505`): The work unit also includes each resolved spelling charged in `put`.
- **Claim 20** (`scripts/lib/dev-cycle-read.sh:527-528`): A non-numeric IMPORT_WORK_LEFT reads as its leading digits (`5x` → 5), not always 0.
- **Claim 26** (`scripts/lib/dev-cycle-read.sh:720-723`): "Its own ... mode passed" holds for the PATH memo (`:753`) only through the callers' guarantee that ENT lacks PATH.
- **Claim 31** (`test/scripts/build-loop-check.bats:853`): The memo also holds `2` entries. The title should say "memoizes as d only ...".
- **Claim 33** (`test/scripts/build-loop-check.bats:942`): The test pins the refusal, not "before reading it whole".
- **Claim 41b** (commit 61e2e734): "At most what one file could" holds for charged work only.

### Unverifiable
- **Claim 23** (`scripts/lib/dev-cycle-read.sh:707`): `[[ -p /dev/stdin ]]` needing /proc. This needs a mount namespace without /proc; `unshare` is not permitted here (Q-127).
- **Claim 24** (`scripts/lib/dev-cycle-read.sh:702`): "Claude Code skips a file over 4 MiB" was carried from main, and Claude Code was not probed.
- **Claim 38b** (commit 3e58eb9c): "Same final tree" has no per-commit rebase tree to compare against.

## Escalations

- **architecture / api-consistency** (Claims 14, 26): main_checkout's memo-at-PATH (`scripts/lib/dev-cycle-read.sh:753`) writes `d` for PATH without reading `mc_e[$3]`. A caller that passes a PATH main stores as a link (120000) or gitlink poisons the memo, and a later call below that PATH then returns 2 where 21b35ebf returned 1 (executed: `c/x.md new=2 old=1`). Neither current caller can do this (`:819`/`:825` and `:870` guard on `ent`), so this is not a fail-open in this branch. However, the contract written for U2a4/U2b's other callers (plan U2b bullet, lib `:720-723`) does not state the precondition. Either state it, or have main_checkout return 1 when `mc_e[$3]` is a link or gitlink.
- **test-strategy** (Claim 32): The deep-token test's `timeout 6` leaves about 9× headroom at HEAD on this host, which makes a flake unlikely. Its ability to catch 21b35ebf's regression, however, depends on the host: 21b35ebf took 10.5-10.9 s here and would pass on a host more than about 1.8× faster. T1 and T2 do not cover the cost regression. The realpath-count style (a call-count shim) would be host-independent.
- **test-strategy** (Claims 30, 31, 33): Small test-text drift. The `(18)` comment is now 10, T1's title says "memoizes only", and the 4096 test's title promises an ordering it does not observe.
- **security** (Claim 23): The `/proc` rationale for `capped_read drain` is still unexecuted here. The change is safe either way, because the argument does not depend on /proc.

## Goal-Alignment Note

The branch's stated goal is a checkout phase that only appends, behind one admission check, plus the four carried items. The code does what it claims. Every rule I could execute held. Under the callers' contract, the bottom-up memo gave the same answers as 21b35ebf's top-down version across about 21,000 randomized calls, and every main_checkout and reader mutant I tried was killed. No claim is Incorrect. The residue is documentation precision, plus one unstated precondition that matters only for a future second caller of main_checkout (escalated above).
