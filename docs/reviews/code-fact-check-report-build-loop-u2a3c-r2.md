Commit: 3a35c8b9

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a3c (branch `feat/build-loop-u2a3c`)
**Scope:** `git diff main...HEAD` (main e5d0f838, HEAD 3a35c8b9) plus the commit messages of main..HEAD (3e58eb9c, cb9723c3, 27364085, 80cc6224, 61e2e734, 21b35ebf, 2fbd929b, 3a35c8b9). The `docs/reviews/*u2a3c*` report files are history. Only the override-log rows the branch adds (439-456) and the iteration-2 rubric's factual claims about the code are in scope.
**Checked:** 2026-10-07
**Commit:** 3a35c8b9
**Replication:** replicate r2 of k=3 (final confirming pass, iteration 3)
**Total claims checked:** 34
**Summary:** 23 verified, 6 mostly accurate, 1 stale, 1 incorrect, 3 unverifiable

Execution provenance: every executed command ran on 2026-10-07 between 20:10Z and 20:40Z under bash 5.2, mawk and git 2.39, as uid 1000. That uid is not root, so the `-r` and `-x` probes mean something. This pass may write no worktree file but this report, so raw output is in the scratch directory `/tmp/u2a3c-i2-fc2-zy90/logs/`. Each log's first line records its timestamp, cwd and command, and its last line records the exit code. Old trees and mutants were built in `/tmp/u2a3c-i2-fc2-zy90/` with `git archive <rev> | tar -x` (`tree-<rev>/`, `lib-<rev>.sh`, `mut-*.sh`), never in the worktree. Bats ran as `TMPDIR=$(mktemp -d /tmp/u2a3c-i2-fc2-XXXX) LC_ALL=C timeout 900 bats …`. The helper `runwith2.sh S TESTREV LIB FILTER` copies LIB into TESTREV's archived tree and runs that tree's `build-loop-check.bats -f FILTER`.

Suites at HEAD (cwd `/workspace/.claude/wt-build-loop-u2a3c`, all exit 0): build-loop-check 63/63, dev-cycle 78/78, build-loop-read 19/19, fixture-hermeticity 2/2 (`logs/bats-build-loop-check.txt`, `logs/bats-dev-cycle.txt`, `logs/bats-build-loop-read.txt`, `logs/bats-fixture-hermeticity.txt`).

Hallucination-pattern log: read. No claim in scope matches a logged pattern. The closest are the logged test-count patterns ("All 85 tests…", "mode1-equiv 33"). This branch's counts were recounted and match: 51/19/78/2 at 3e58eb9c, 63/78/19/2 at 2fbd929b (Claim 30).

---

## Claim 1: Override row 448: "Closes U2a3b's routed N1 row … the candidates are lower-cased by lower_all under nul_list, so a tr that dies after a partial flush fails the walk; the test fails at 3e58eb9c."

**Location:** `docs/reviews/override-log.md:448`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the batch-lower path in main_imports and the N1 test's failure at 3e58eb9c. It does not establish behaviour for a `tr` that dies after a partial flush of a different shape than the test's shim, which drops 3 bytes.
**Legibility-target:** for-orchestrator-synthesis

```
# scripts/lib/dev-cycle-read.sh:700
lower_all() { local -; set -o pipefail; printf '%s\0' "$@" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz'; }
# scripts/lib/dev-cycle-read.sh:820-821
  [[ ${#cand[@]} -eq 0 ]] || nul_list low lower_all "${cand[@]}" || return 1
  [[ ${#low[@]} -eq ${#cand[@]} ]] || return 1
```
The fix is `nul_list`'s `rc=0` sentinel (`:695`), which a failed `tr` under pipefail never prints. Executed: the 27364085 tests run against 3e58eb9c's lib (`bash runwith2.sh $S 27364085 $S/lib-3e58eb9c.sh 'partial flush|first 4 MiB'`, cwd `$S`, 20:2xZ). The output is `not ok 2 main walk fails when the batch tr dies after a partial flush…`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:695-700`, `scripts/lib/dev-cycle-read.sh:820-821`, `test/scripts/build-loop-check.bats:800-809`, `/tmp/u2a3c-i2-fc2-zy90/logs/c27364085-vs-3e58eb9c.txt`

---

## Claim 2: Override rows 449 and 454: capped_read is the one reader for checkout files and main's file blobs, and it drains a pipe so `git cat-file` never dies of SIGPIPE ("a no-drain mutant fails the test"). Row 454 corrects row 449: the symlink arm's link blobs were read whole, and link text over 4096 bytes now fails before it is read.

**Location:** `docs/reviews/override-log.md:449`, `docs/reviews/override-log.md:454`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three reads the parser consumes (tree-walk file, checkout arm, blob arm), the drain's effect, and the 4096 cap. It does not re-measure the 58 s / 2 GiB pre-fix figure, which row 454 takes from the iteration-2 performance report (256 MiB of `a` stored as a 1.3 MB object).
**Legibility-target:** for-orchestrator-synthesis

```
# scripts/lib/dev-cycle-read.sh:775 (tree walk)   out="$(capped_read < "$f" | …
# scripts/lib/dev-cycle-read.sh:837 (checkout)    checkout) out="$(capped_read < "$f" | …
# scripts/lib/dev-cycle-read.sh:839 (main blob)   100644|100755) out="$(git cat-file blob "$MAIN_SHA:$f" | capped_read drain | …
# scripts/lib/dev-cycle-read.sh:843 (link)        i="$(git cat-file -s "$MAIN_SHA:$f")" && [[ "$i" -le 4096 ]] || { IMPORTED_MAIN=error; return 1; }
```
Executed:
- 27364085's 4 MiB test fails against a no-drain mutant of 27364085's lib (`logs/c27364085-vs-nodrain.txt`).
- HEAD's 4 MiB test fails against HEAD with `capped_read drain` changed to `capped_read` (`logs/HEAD-vs-nodrain.txt`).
- A 64 MiB link blob at a start name now fails the walk in 0.02 s (`bash biglink.sh lib-HEAD.sh`, `logs/biglink.txt`, 20:16:50Z).

**Evidence:** `scripts/lib/dev-cycle-read.sh:709`, `:775`, `:837-843`, `docs/reviews/performance-reviewer-review-2026-10-07-build-loop-u2a3c.md:53-62`, `/tmp/u2a3c-i2-fc2-zy90/logs/c27364085-vs-nodrain.txt`, `/tmp/u2a3c-i2-fc2-zy90/logs/HEAD-vs-nodrain.txt`, `/tmp/u2a3c-i2-fc2-zy90/logs/biglink.txt`

---

## Claim 3: Override row 450 and commit 80cc6224: "main_checkout memoizes the ancestors it has passed (18 realpath calls in the test's walk, against 102 unmemoized and 74 at 3e58eb9c); it also fixed a crash on an empty main tree with an untracked start" (80cc6224: "it fails at 27364085").

**Location:** `docs/reviews/override-log.md:450`; commit 80cc6224 message
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at the revisions the row names: 80cc6224 = 18, an unmemoized mutant of 80cc6224 = 102, 3e58eb9c = 74. It also covers the empty-tree test failing at 27364085. It does not cover HEAD, which now makes 10 calls (see Claim 25).
**Legibility-target:** for-orchestrator-synthesis

The count comes from a realpath shim over the memo test's shape (`bash rpcount.sh lib-<rev>.sh`). It reads 74 at 3e58eb9c and at 27364085, 18 at 80cc6224 and at 21b35ebf, and 10 at HEAD. The unmemoized mutant replaces `then mc_m[$c]=1` with `then :` in 80cc6224's lib and reads 102. The crash fix is the guarded type check:
```
# scripts/lib/dev-cycle-read.sh:736
  set +u; [[ "${mc_e@a}" == *A* && "${mc_m@a}" == *A* ]] || return 1
```
80cc6224's test "the checkout phase walks an untracked start when main's tree is empty" is `not ok` against 27364085's lib.

**Evidence:** `scripts/lib/dev-cycle-read.sh:733-736`, `test/scripts/build-loop-check.bats:834-840`, `/tmp/u2a3c-i2-fc2-zy90/logs/rpcount.txt`, `/tmp/u2a3c-i2-fc2-zy90/logs/rpcount-nomemo.txt`, `/tmp/u2a3c-i2-fc2-zy90/logs/c80cc6224-emptytree-vs-27364085.txt`

---

## Claim 4: Override row 451 and commit 61e2e734: "IMPORT_WORK_MAX bounds the work charged over a whole walk, so N adversarial files cost one bound"; "a per-file mutant passes at 3w - 1 and fails the test".

**Location:** `docs/reviews/override-log.md:451`; commit 61e2e734 message
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk-wide accumulation and the per-file mutant's behaviour against 61e2e734's test and HEAD's T3. It does not re-measure "about 5 s" per bound, and row 455 narrows the bound to charged work only.
**Legibility-target:** for-orchestrator-synthesis

```
# scripts/lib/dev-cycle-read.sh:677-682
import_work() {
  local -n iw_o="$1" iw_t="$2"; local iw_w="${iw_o##*/}"
  [[ "$iw_w" =~ ^[0123456789]+$ && ( "$iw_o" == "/$iw_w" || "$iw_o" == *$'\n'"/$iw_w" ) ]] || return 1
  iw_o="${iw_o%/*}"; iw_o="${iw_o%$'\n'}"
  (( (iw_t += iw_w) <= IMPORT_WORK_MAX ))
}
```
The mutant passes `IMPORT_WORK_LEFT=$IMPORT_WORK_MAX` and checks `(( (iw_t += iw_w), iw_w <= IMPORT_WORK_MAX ))`, so it still accumulates t for the test's own w measurement. Against 61e2e734's test it prints `-1 tree ok / -1 main ok` and the test fails. Against HEAD's T3 it fails both the `-1` rows and the caps rows (`[1000 1000 1000 1000]` against `[316 544 772 1000]`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:677-682`, `:775`, `:837-840`, `test/scripts/build-loop-check.bats:897-912`, `/tmp/u2a3c-i2-fc2-zy90/logs/c61e2e734-vs-perfile.txt`, `/tmp/u2a3c-i2-fc2-zy90/logs/HEAD-T3-vs-perfile.txt`

---

## Claim 5: Override row 452: "the rebase resolution 3e58eb9c dropped the cache-clear rule, the FIFO start and the snapshot assumption from known issue A5 and U2b's 'owes the walk three things' clause … Iteration 2 restored [them] (plus the MEMO rule for another main_checkout caller)."

**Location:** `docs/reviews/override-log.md:452`
**Type:** Reference / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the presence of the cache-clear rule, the FIFO item, the snapshot/swap item and the three duties at 2b1399ab, 3e58eb9c, 21b35ebf and HEAD. It does not establish that the restored MEMO rule is complete (Claim 14).
**Legibility-target:** for-orchestrator-synthesis

A grep of A5 and the U2b bullet at each revision gives these counts (IMPORTED_MAIN_DONE / FIFO / "three things"): 2b1399ab 1/1/1, 3e58eb9c 0/0/0, 21b35ebf 0/0/0, HEAD 1/1/1. At 2b1399ab the swap item reads "a checkout file swapped between its admission and its read". HEAD's A5 says "(the walk reads the checkout as one snapshot)". (paraphrased — no quote available because the evidence is grep counts across four revisions of a one-line table row several KB long.)

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `docs/working/plan-build-loop-handoff.md:279`, command `git show <rev>:docs/working/known-issues-dev-cycle.md | grep '^| A5'` (cwd worktree, exit 0)

---

## Claim 6: Override row 453: "the record line it says is commented was replaced in 3e58eb9c; main_imports records the parser's whole output before the seen test, so a start already seen is still recorded by structure … Test 'a main import of an untracked start' pins it."

**Location:** `docs/reviews/override-log.md:453`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the record-before-seen order and the existence of a test pinning it. It does not establish a mutant kill for that order, which was not run.
**Legibility-target:** for-author

```
# scripts/lib/dev-cycle-read.sh:866-869
    i="$(lower "$out")" || { IMPORTED_MAIN=error; return 1; }; IMPORTED_MAIN+="$i"$'\n'
    while IFS= read -r p; do
      [[ -n "$p" ]] || continue
      [[ -z "${seen[$p]+set}" ]] || continue
```
(excerpt ends :869; the enclosing while loop continues to :874 — read.) The mechanism is right. The row's quoted test name does not exist verbatim. The test is titled "main walk reads an untracked start that a main file also imports once, through the checkout (U2a3c; override row 446)" (`test/scripts/build-loop-check.bats:921`). Its `want docs/AGENTS.md imported` would fail if the record moved after the seen test.

**Evidence:** `scripts/lib/dev-cycle-read.sh:863-874`, `test/scripts/build-loop-check.bats:921-930`

---

## Claim 7: Override row 455: "IMPORT_WORK_MAX bounds charged parser work, not walk time; capped_read's drain (git inflates the whole blob, about 0.7 s per GiB) and the scan of @-less lines are uncharged, and a caller running both walks pays two bounds."

**Location:** `docs/reviews/override-log.md:455`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers which work is charged (`emit`, `put`, `splice` only) and the per-walk locals. The drain rate is host-dependent: 0.84 s per GiB measured here, against "about 0.7".
**Legibility-target:** for-orchestrator-synthesis

`scan` loops over every character without touching `work`, which only `emit` (`:566`), `put` (`:584`) and `splice` (`:617`) increment:
```
# scripts/lib/dev-cycle-read.sh:603-604
  for (i = 1; i <= L; i++) {
    if (substr(line, i, 1) != "@") continue
```
(excerpt ends :604; scan continues to :613 — read.) Each walk declares its own counter (`local … work=0`, `:757` and `:802`). A 256 MiB blob drained through `head -c 4194305; cat` took 0.21 s (`logs/biglink.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:564-629`, `:757`, `:802`, `/tmp/u2a3c-i2-fc2-zy90/logs/biglink.txt`

---

## Claim 8: Override row 456: "The reader, parser, trailer-strip and budget chain is written out three times (tree walk, main's checkout and blob arms) … main_checkout's comment now says why it differs from blocker."

**Location:** `docs/reviews/override-log.md:456`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three call sites and the comment. It does not assess the deferral.
**Legibility-target:** for-orchestrator-synthesis

The three sites are `:775-776`, `:837-838` and `:839-840`, each `capped_read … | IMPORT_LEFT=… IMPORT_WORK_LEFT=… import_targets "$d")" && import_work out work`. The comment at `:730-731` reads: "unlike blocker it answers 2 below a plain file and needs a searchable directory (a second traversal on purpose)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:730-731`, `:775-776`, `:837-840`

---

## Claim 9: Known issue A5's checkout-phase sentence: start files main lacks and imported files main lacks are walked "when each is a plain file there"; a path "under a directory main stores as a link or gitlink or under an unsearchable directory, anything but a plain file or directory there (or nothing), an unreadable checkout file, a `..` after a checkout link in link text, and a checkout listing git prints any stderr for fail it; a linked worktree's `.git` file is read like any checkout file."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed fail rule against main_checkout, checkout_md and the symlink arm, through the passing tests named in Evidence. It does not establish the claim that Claude Code reads a gitfile (Claim 28).
**Legibility-target:** for-orchestrator-synthesis

```
# scripts/lib/dev-cycle-read.sh:742-745
    [[ ! "${mc_e[$c]:-}" =~ ^1[26]0000$ ]] || return 1
    if [[ "$st" == d ]]; then
      if [[ ! -e "$c" && ! -L "$c" ]] || rawfile "$c"; then st=2
      elif ! plaindir "$c" || [[ ! -x "$c" ]]; then return 1; fi
# scripts/lib/dev-cycle-read.sh:751-752
  if rawfile "$c"; then [[ -r "$c" ]]; return; fi
  plaindir "$c" || return 1
# scripts/lib/dev-cycle-read.sh:716
checkout_md() { local e; { e="$(md_ls --cached --others 2>&1 >&3)"; } 3>&1 && [[ -z "$e" ]]; }
```
(main_checkout excerpts; the function runs :732-755 — read.) The tests at `:782` (link, gitlink, unsearchable, unreadable listing), `:853` (shape table), `:411`, `:657` and `:700` (.git) pass at HEAD.

**Evidence:** `scripts/lib/dev-cycle-read.sh:716`, `:732-755`, `:852-859`, `test/scripts/build-loop-check.bats:782-798`, `:853-882`, `/tmp/u2a3c-i2-fc2-zy90/logs/bats-build-loop-check.txt`

---

## Claim 10: Known issue A5: "The walk's cache ignores the checkout, so a caller clears `IMPORTED_MAIN_DONE` after any checkout change"; Not covered: "a start file that is not a regular file or symlink (git does not list a FIFO), a checkout file swapped between its admission and its read (the walk reads the checkout as one snapshot)".

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cache key and the cache test. It does not establish the FIFO listing claim by execution in this pass (it was executed in iteration 1, P6), and nothing in this pass covers whether any caller honours the clear.
**Legibility-target:** for-orchestrator-synthesis

```
# scripts/lib/dev-cycle-read.sh:806-807
  [[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }
  IMPORTED_MAIN=error; IMPORTED_MAIN_DONE="$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"
```
The cache test (`build-loop-check.bats`, "main walk cache: … a checkout change is not seen until IMPORTED_MAIN_DONE is cleared") expects `- - z.sh`, and it passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:806-807`, `test/scripts/build-loop-check.bats` (cache test, lines ~330-339), `/tmp/u2a3c-i2-fc2-zy90/logs/bats-build-loop-check.txt`

---

## Claim 11: Plan F11: U2a3c's "one admission check (`main_checkout`) refuses a path under a link or gitlink main stores, under an unsearchable directory, or anything but a plain file or directory, and a checkout listing git prints any stderr for fails the walk; the caller contract (cache clear, empty `ls-files` stderr, the git environment) is in the U2b bullet."

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers F11's list of refusals and its pointer to the U2b bullet. It does not cover the U2a3c bullet, which does list the unreadable file (Claim 12).
**Legibility-target:** for-author

main_checkout also refuses an unreadable plain file (`if rawfile "$c"; then [[ -r "$c" ]]; return; fi`, `scripts/lib/dev-cycle-read.sh:751`), which F11's list leaves out. A5, the lib's block comment and the U2a3c bullet all name it. Precise version: "…or anything but a readable plain file or a plain directory". The pointer is accurate: the U2b bullet holds all three duties (Claim 13).

**Evidence:** `scripts/lib/dev-cycle-read.sh:751`, `docs/working/plan-build-loop-handoff.md:126`, `:277`, `:279`

---

## Claim 12: Plan U2a3c bullet: "Built 2026-10-07 after the rebase onto U2a3b: the fail rules as stated (a readable plain file main lacks is walked; a non-plain node, an unreadable file, or a path under main's link or gitlink or under an unsearchable directory fails), `capped_read`, the work bound `IMPORT_WORK_MAX` (reported by the parser's trailer, charged by `import_work`), `main_checkout`'s ancestor memo, the `.git` rule, and N1 (`lower_all` under `nul_list`)."

**Location:** `docs/working/plan-build-loop-handoff.md:277`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence and wiring of each named item. It does not cover the bullet's older "Carried from U2a3b" text, which is unchanged from main.
**Legibility-target:** for-orchestrator-synthesis

Each item is wired in: `capped_read` (`:709`), `IMPORT_WORK_MAX` (`:511`), the awk trailer (`END { if (trail) print "/" (work + 0) }`, `:629`), `import_work` (`:677-682`), main_checkout's memo (`mc_m[$c]="$st"`, `:747`), `lower_all` under `nul_list` (`:820`). The `.git` special case is gone: `grep -n 'p" == .git'` hits main's lib (`:785`) and not HEAD's.

**Evidence:** `scripts/lib/dev-cycle-read.sh:511`, `:629`, `:677-682`, `:709`, `:747`, `:820`

---

## Claim 13: Plan U2b bullet: U2b "owes the walk three things: that checkout final before the walk, or `IMPORTED_MAIN_DONE` cleared (the cache key ignores the checkout); a git that prints nothing on stderr for `ls-files` (any stderr fails the walk closed); and the git environment the override log hands the caller".

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cache key and the stderr rule against code. It does not verify the override log's git-environment list item by item.
**Legibility-target:** for-orchestrator-synthesis

The cache key omits the checkout (`:806-807`, quoted in Claim 10). `checkout_md` fails on any stderr (`[[ -z "$e" ]]`, `:716`). The text matches the block comment above `IMPORTED=` (`:486-491`) and main_imports' header (`:787-800`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:486-491`, `:716`, `:806-807`

---

## Claim 14: Plan U2b bullet: "A caller of `main_checkout` other than `main_imports` passes a fresh MEMO per walk and ENT (a MEMO hit skips main's mode check too)".

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Invariant / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the contract a second caller would rely on. It does not affect main_imports, which never calls main_checkout on a path ENT holds (`:825`, `:870`).
**Legibility-target:** for-author

The parenthesis is right, but the contract is incomplete. main_checkout memoizes PATH itself as `d` without ever checking PATH's own mode in ENT:
```
# scripts/lib/dev-cycle-read.sh:749-754
  [[ "$st" == d ]] || return 2
  c="$3"; [[ -e "$c" || -L "$c" ]] || return 2
  if rawfile "$c"; then [[ -r "$c" ]]; return; fi
  plaindir "$c" || return 1
  [[ ! -x "$c" ]] || mc_m[$c]=d  # a prefix candidate's directory, which longer ones pass through
  return 2
```
Suppose a caller follows the bullet (fresh MEMO, the walk's ENT) and calls `main_checkout ENT MEMO a` where main stores `a` as 120000 and the checkout holds a plain directory `a`. The call memoizes `a=d`. A later `main_checkout ENT MEMO a/f` then returns 0, a file under a link main stores, admitted. 21b35ebf's top-down version returns 1 for that order. Executed: `bash repro1.sh $S` (cwd `$S`, exit 0, 20:10:54Z) prints `path=a/f new=0 old=1`. A fresh MEMO gives `fresh a/f new=1`. The random differential found the same divergence (`a/u/n`, ENT `a=160000`) when calls were allowed on ENT paths, and none otherwise (Claim 21). The contract needs "and never a PATH that ENT holds".

**Evidence:** `scripts/lib/dev-cycle-read.sh:732-755`, `:825`, `:870`, `/tmp/u2a3c-i2-fc2-zy90/logs/repro1.txt`, `/tmp/u2a3c-i2-fc2-zy90/logs/repro-path-memo.txt`, `/tmp/u2a3c-i2-fc2-zy90/logs/diff-any-21.txt`

---

## Claim 15: Lib block comment above `IMPORTED=` (checkout phase): the second phase "walks the checkout's start files main lacks … and the imported files main lacks, when each is a plain file there, and only appends"; fail list; "A linked worktree's .git file and files under .git are checkout files like any other"; the snapshot sentence; the cache is keyed "never the checkout".

**Location:** `scripts/lib/dev-cycle-read.sh:464-491`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the phase order, the append-only record, the fail list and `.git`, through the passing tests. "Only appends" means phase 2 never removes a recorded name; it can still fail the whole walk.
**Legibility-target:** for-orchestrator-synthesis

```
# scripts/lib/dev-cycle-read.sh:832-834
  while [[ ${#queue[@]} -gt 0 || ${#tq[@]} -gt 0 ]]; do
    [[ ${#queue[@]} -gt 0 ]] || { queue=("${tq[@]}"); tq=(); }  # phase 2: main's walk is done
    f="${queue[0]}"; queue=("${queue[@]:1}")
```
(excerpt ends :834; the loop continues to :875 — read.) `IMPORTED_MAIN` is only ever appended to (`+=`, `:866`). The `.git` tests (`:411`, `:657`, `:700`) pass at HEAD.

**Evidence:** `scripts/lib/dev-cycle-read.sh:464-491`, `:801-876`, `test/scripts/build-loop-check.bats:411`, `:657`, `:700`

---

## Claim 16: IMPORT_WORK_MAX comment: "/workspace's walks spend about 8,100 each (2026-10-07). The bound is per walk: a caller that runs both walks pays up to two"; and commit 61e2e734: "(1.1 s tree, 1.4 s main; the main walk now passes on this developer checkout, which failed closed before U2a3c)".

**Location:** `scripts/lib/dev-cycle-read.sh:504-511`; commit 61e2e734 message
**Type:** Performance / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the work figure, per-walk scope, and pass/fail at HEAD and main on /workspace as of 20:11Z. Timings are host-dependent: 1.4 s tree and 1.9 s main here, against 1.1 and 1.4.
**Legibility-target:** for-orchestrator-synthesis

Executed `LC_ALL=C bash measure.sh <HEAD lib> /workspace` (cwd `/workspace`, exit 0, 20:11:30Z, read-only), with import_work wrapped to record its running total. It printed `tree rc=0 work=8110` and `main rc=0 work=8110`. main's lib on the same checkout prints `main_imports rc=1 IMPORTED_MAIN=error`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:504-511`, `:757`, `:802`, `/tmp/u2a3c-i2-fc2-zy90/logs/measure-workspace.txt`, `/tmp/u2a3c-i2-fc2-zy90/logs/main-lib-workspace.txt`

---

## Claim 17: import_targets comment: IMPORT_WORK_LEFT "Unset or empty: no trailer and only the per-file bound; not a number: 0, so the first candidate fails it".

**Location:** `scripts/lib/dev-cycle-read.sh:524-528`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers unset, empty, alphabetic, numeric-prefix, zero and negative values. Walks always pass a computed integer, so the residue does not affect them.
**Legibility-target:** for-author

```
# scripts/lib/dev-cycle-read.sh:626
  wmax = 50000000; trail = (ENVIRON["IT_WORK"] != ""); if (trail && ENVIRON["IT_WORK"] + 0 < wmax) wmax = ENVIRON["IT_WORK"] + 0
```
Executed `LC_ALL=C bash trail.sh new.sh $S` (exit 0) on `x @aa @bbbb`. Unset and empty: rc 0, no trailer. `abc`, `0` and `-5`: rc 1. `12abc`: mawk reads it as 12, and the parser ran to work 34 before failing (`out=/34`). So a value with a leading number is read as that number, not 0. The precise version: "not a number: its leading numeric prefix, else 0". With no `@` in the text, `abc` gives rc 0 and `/0`, which is consistent with "first candidate".

**Evidence:** `scripts/lib/dev-cycle-read.sh:623-629`, `:670-671`, `/tmp/u2a3c-i2-fc2-zy90/logs/trailer.txt`

---

## Claim 18: import_work comment: "strips the parser's work trailer (its last line, "/N", printed when IMPORT_WORK_LEFT is set; a repo-relative name never starts with /) … returns 1 when the trailer is missing or TOTAL passes IMPORT_WORK_MAX."

**Location:** `scripts/lib/dev-cycle-read.sh:673-676`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the strip, the charge and the failure cases in the import_work test. The no-leading-/ invariant rests on `put`'s `substr(out, length(pre) + 1)` after a non-empty component.
**Legibility-target:** for-orchestrator-synthesis

```
# scripts/lib/dev-cycle-read.sh:594-595
  if (index(out, pre) != 1 || length(out) <= length(pre)) return
  out = substr(out, length(pre) + 1)
```
(excerpt ends :595; put continues to :600 — read.) The test at `:842` passes at HEAD: `1 ok [a.md] 17`, `3 failed` (no newline before `/12`), `4 failed`, `5 failed 31`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:580-600`, `:677-682`, `test/scripts/build-loop-check.bats:842-851`

---

## Claim 19: capped_read comment: "With the word drain (after git cat-file) it reads the rest … an argument, not a [[ -p /dev/stdin ]] test, which needs /proc. The drain is time the work bound does not charge (git inflates the whole blob)."

**Location:** `scripts/lib/dev-cycle-read.sh:701-709`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the call sites (drain only at `:839`), the /proc dependence of `/dev/stdin`, and the uncharged drain. It does not test a host without /proc.
**Legibility-target:** for-orchestrator-synthesis

```
# scripts/lib/dev-cycle-read.sh:709
capped_read() { head -c 4194305 || return 1; [[ "${1:-}" != drain ]] || cat > /dev/null; }
```
`ls -l /dev/stdin` gives `/dev/stdin -> /proc/self/fd/0`. Only `:839` passes `drain`. `:775` and `:837` read `< "$f"` from a regular file that main_checkout or inrepo_here admitted. The drained bytes never reach the parser, so nothing charges them. Removing `drain` fails HEAD's 4 MiB test (Claim 2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:709`, `:775`, `:837`, `:839`, `/tmp/u2a3c-i2-fc2-zy90/logs/HEAD-vs-nodrain.txt`

---

## Claim 20: main_checkout comment: MEMO holds "d for a plain searchable directory, 2 for one absent or a plain file (nothing below it loads), set only once its own and every higher ancestor's main mode passed."

**Location:** `scripts/lib/dev-cycle-read.sh:719-722`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both memo-writing sites (`:747`, `:753`). The invariant holds at `:747`, where every ancestor's mode is checked top-down from the nearest memo. It fails at `:753`, where PATH is memoized `d` and its own mode is never checked. This does not establish a defect for main_imports, which never passes a PATH that ENT holds.
**Legibility-target:** for-author

```
# scripts/lib/dev-cycle-read.sh:740-748
  for ((i = ${#anc[@]} - 1; i >= 0; i--)); do
    c="${anc[i]}"
    [[ ! "${mc_e[$c]:-}" =~ ^1[26]0000$ ]] || return 1
    if [[ "$st" == d ]]; then
      if [[ ! -e "$c" && ! -L "$c" ]] || rawfile "$c"; then st=2
      elif ! plaindir "$c" || [[ ! -x "$c" ]]; then return 1; fi
    fi
    mc_m[$c]="$st"
  done
# scripts/lib/dev-cycle-read.sh:753
  [[ ! -x "$c" ]] || mc_m[$c]=d  # a prefix candidate's directory, which longer ones pass through
```
Only `anc` entries (strict ancestors) get the mode test. PATH reaches `:753` with no `mc_e[$3]` test, so `a=d` can be set while ENT holds `a=120000`. That entry then lets `a/f` through (Claim 14's repro: new 0, old 1). The mechanism the comment states, "its own … main mode passed", does not run for PATH. The conclusion holds only under main_imports' unstated precondition (PATH ∉ ENT). Precise version: "…set at an ancestor once its own and every higher ancestor's main mode passed, and at PATH, which callers must not pass when ENT holds it."

**Evidence:** `scripts/lib/dev-cycle-read.sh:732-755`, `:825`, `:870`, `/tmp/u2a3c-i2-fc2-zy90/logs/repro-path-memo.txt`

---

## Claim 21: Commit 2fbd929b and rubric B2: main_checkout "walks its ancestors bottom up to the nearest decided one and memoizes every result (d or 2), and a searchable directory at PATH". The shared brief asks whether this preserves every return code of 21b35ebf's top-down version.

**Location:** `scripts/lib/dev-cycle-read.sh:737-755`; commit 2fbd929b message; `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md` (B2)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers return-code equality with 21b35ebf's main_checkout over random call orders sharing one memo per version, for calls whose PATH is not in ENT (main_imports' only pattern), and T1's shape table. It does not cover calls on ENT paths, where the versions diverge (Claim 20). "Every result" excludes a refusal, which is not memoized.
**Legibility-target:** for-orchestrator-synthesis

The differential is `diff.sh $S 500 contract <seed>`, run for 4 seeds. Each trial draws 8 random paths over 10 components and a random ENT of 0-3 link/gitlink/blob keys. The fixture holds a plain file, an unreadable file, a non-searchable dir, a symlink to a file, a symlink to a dir, a FIFO, a nested dir and absent paths. The 15,800 calls gave 0 divergences, including the shorter-prefix-memoized-2 then deeper-link order. T1 against 21b35ebf's lib gives an identical return code for each of its 17 shapes; only the memo line differs (`memo` empty, since 21b35ebf stored 1). A mutant that skips the mode check below an absent ancestor fails both T1 and T2 (`logs/modeonlyd-vs-HEAD.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:732-755`, `/tmp/u2a3c-i2-fc2-zy90/logs/diff-contract-11.txt` … `diff-contract-14.txt`, `/tmp/u2a3c-i2-fc2-zy90/logs/i2tests-at-21b35ebf.txt`, `/tmp/u2a3c-i2-fc2-zy90/logs/modeonlyd-vs-HEAD.txt`

---

## Claim 22: main_checkout comment: return codes "0 for a readable plain checkout file to walk, 2 when nothing there loads (absent, below an absent ancestor or a plain file, or a plain directory), 1 to fail the walk …; A MEMO hit skips that mode check too, so a MEMO serves one walk and one ENT. Callers test 1 as a refusal, never as a plain false." Also the iteration-1 fixes A1 (non-associative ENT/MEMO → 1), A3 (admission before seen) and the C1 fast return.

**Location:** `scripts/lib/dev-cycle-read.sh:723-731`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the return table (T1 passes), both callers' tests of 1, and the persistence of A1, A3 and C1. A MEMO hit skipping the check is exactly what makes Claim 20's precondition matter.
**Legibility-target:** for-orchestrator-synthesis

```
# scripts/lib/dev-cycle-read.sh:825-826
      f="${cand[i]:2}"; c=0; [[ "${cand[i]:0:1}" == m ]] || main_checkout ent pok "$f" || c=$?
      [[ $c -ne 1 ]] || return 1; [[ $c -eq 0 ]] || continue
# scripts/lib/dev-cycle-read.sh:870-872
      c=0; [[ -n "${ent[$p]+set}" ]] || main_checkout ent pok "$p" || c=$?  # main lacks p: admitted before it is marked seen
      [[ $c -ne 1 ]] || { IMPORTED_MAIN=error; return 1; }
      seen[$p]=1
```
A1 is `:736`. C1 is `[[ -e "$c" || -L "$c" ]] || return 2` at `:750`, before `rawfile` forks. T1's `ent-indexed 1` and `memo-indexed 1` rows pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:732-755`, `:822-829`, `:867-874`, `test/scripts/build-loop-check.bats:853-882`

---

## Claim 23: main_imports header: returns 1 when "… main_checkout refuses a start or an import main lacks, a blob or checkout file cannot be read … or the IMPORT_OUT_MAX or IMPORT_WORK_MAX budget is spent"; "Phase 2 begins when queue empties: tq's checkout files then join it, and a path main lacks reads the checkout."

**Location:** `scripts/lib/dev-cycle-read.sh:787-800`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the listed failure returns and phase order. A phase-2 file's import of a path main stores is read through main's arms in the same loop. The header's "a path main lacks reads the checkout" implies this, and the block comment says it.
**Legibility-target:** for-orchestrator-synthesis

```
# scripts/lib/dev-cycle-read.sh:836-838
    case "${ent[$f]-checkout}" in
      checkout) out="$(capped_read < "$f" | IMPORT_LEFT=$((IMPORT_OUT_MAX - used)) IMPORT_WORK_LEFT=$((IMPORT_WORK_MAX - work)) import_targets "$d")" \
          && import_work out work || { IMPORTED_MAIN=error; return 1; } ;;
```
(excerpt ends :838; the case continues to :862 — read.)

**Evidence:** `scripts/lib/dev-cycle-read.sh:801-876`

---

## Claim 24: Symlink arm: "Link text past PATH_MAX (4096) names nothing; it fails before the two whole reads below."

**Location:** `scripts/lib/dev-cycle-read.sh:842-843`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the size check's position and effect. Exactly 4096 bytes passes the check and is read, which is harmless: such text also names nothing, since Linux link targets stop at 4095.
**Legibility-target:** for-orchestrator-synthesis

```
# scripts/lib/dev-cycle-read.sh:843
        i="$(git cat-file -s "$MAIN_SHA:$f")" && [[ "$i" -le 4096 ]] || { IMPORTED_MAIN=error; return 1; }
```
This runs before `:846-847`'s two `git cat-file blob` reads. A 64 MiB link blob fails the walk in 0.02 s (`logs/biglink.txt`). The 4097-byte test fails at 21b35ebf's lib and passes at HEAD (`logs/i2tests-at-21b35ebf.txt`, `logs/i2tests-at-HEAD.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:841-859`, `/tmp/u2a3c-i2-fc2-zy90/logs/biglink.txt`, `/tmp/u2a3c-i2-fc2-zy90/logs/i2tests-at-21b35ebf.txt`

---

## Claim 25: Memo test comment: "Unmemoized, each candidate re-checks every ancestor (102 calls; 74 at 3e58eb9c); memoized, each directory once, plus each candidate's own check (18)."

**Location:** `test/scripts/build-loop-check.bats:822-825`
**Type:** Performance / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the realpath count at HEAD. The test's assertion (`-le 30`) still passes, so this affects only the comment's figure and mechanism.
**Legibility-target:** for-author

18 was 80cc6224's count (Claim 3). Since 2fbd929b, main_checkout also memoizes a searchable PATH directory (`:753`), so a candidate whose own path is a directory no longer re-checks it. HEAD's walk makes 10 realpath calls (`bash rpcount.sh lib-HEAD.sh` → `realpath calls: 10`). "Plus each candidate's own check (18)" now reads 10.

**Evidence:** `scripts/lib/dev-cycle-read.sh:753`, `test/scripts/build-loop-check.bats:821-832`, `/tmp/u2a3c-i2-fc2-zy90/logs/rpcount.txt`

---

## Claim 26: T1 title: "main_checkout answers each checkout shape: 0 for a readable plain file, 2 where nothing loads, 1 for anything it does not model, and memoizes only plain searchable directories".

**Location:** `test/scripts/build-loop-check.bats:853`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test asserts. It does not cover memo entries valued 2, which the test filters out.
**Legibility-target:** for-author

The memo check lists only keys whose value is `d`:
```
# test/scripts/build-loop-check.bats:860
        echo "memo $(for k in "${!M[@]}"; do [[ "${M[$k]}" != d ]] || echo "$k"; done | sort | tr "\n" " ")"; …
```
(excerpt ends inside the bash -c body, which continues to :861 — read.) The MEMO also holds 2-valued entries (for example `nd` and `f.md`, from `:747`). Precise version: "…memoizes as d only plain searchable directories". The return-code table is verified (Claim 21).

**Evidence:** `test/scripts/build-loop-check.bats:853-882`, `scripts/lib/dev-cycle-read.sh:747`, `:753`

---

## Claim 27: Deep-token test: "@a/a/.../x.md, 1,000 levels deep, none in the checkout: about 0.6 s; 21b35ebf's top-down loop rescanned every absent ancestor per prefix candidate (10.7 s)", under `timeout 6`. Commit 2fbd929b and rubric B2: "D=1000 took 10.7 s at 21b35ebf, 0.6 s now, main 0.5 s … Test with a 6 s timeout fails at 21b35ebf."

**Location:** `test/scripts/build-loop-check.bats:932-940`; commit 2fbd929b; rubric B2
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the timings on this host and the test's failure at 21b35ebf. It does not establish that the test keeps discriminating on a faster host.
**Legibility-target:** for-orchestrator-synthesis

`bash deep.sh lib-<rev>.sh` (cwd `$S`, exit 0, 20:1xZ) measured HEAD 0.66 s, 21b35ebf 11.00 s and main 0.55 s. HEAD's test is `not ok` against 21b35ebf's lib. Robustness has two sides. The pass side has about 9x headroom (0.66 s against 6 s). The kill side has 1.8x (11.0 s against 6 s), so on a host about twice as fast the 21b35ebf regression would finish inside the timeout and survive (escalated to test-strategy).

**Evidence:** `test/scripts/build-loop-check.bats:932-940`, `/tmp/u2a3c-i2-fc2-zy90/logs/deep-timing.txt`, `/tmp/u2a3c-i2-fc2-zy90/logs/i2tests-at-21b35ebf.txt`

---

## Claim 28: The three inverted U2a3b tests, and commit 3e58eb9c: "the .git directory passes main_checkout as a plain directory, and a linked worktree's gitfile is read as a checkout file"; test titles add "as Claude Code does".

**Location:** `test/scripts/build-loop-check.bats:411`, `:657`, `:700`; commit 3e58eb9c message
**Type:** Behavioral / Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** The lib behaviour is verified by execution: all three tests pass at HEAD and walk the gitfile, `.git/notes.md` and `n/.git`. The "as Claude Code does" half needs a trace of the installed Claude Code reader, which this pass did not run. The most severe part carries the verdict.
**Legibility-target:** for-orchestrator-synthesis

```
# test/scripts/build-loop-check.bats:657-663 (whole test)
@test "the main walk reads an imported file under .git as a checkout file and follows its imports (U2a3b L2-i2 security F2, U2a3c)" {
    # .git/notes.md is a checkout file main lacks: phase 2 reads it, so docs/t.md, which it imports, counts.
    mkdir -p docs && printf 'See @.git/notes.md and @sub/../.git/info/n.md\n' > CLAUDE.md && commit_all gitdir
    printf 'see @../docs/t.md\n' > .git/notes.md
    imps main docs/t.md docs/other.md
    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
    want walk ok; want docs/t.md imported; want docs/other.md -
}
```
main's lib held the special case (`if [[ "$p" == .git ]]`, main `:785`), and HEAD's lib has none. To verify the Claude Code half, re-trace the installed Claude Code import reader on a gitfile (Q-126's host probe).

**Evidence:** `test/scripts/build-loop-check.bats:411-422`, `:657-663`, `:700-714`, `/tmp/u2a3c-i2-fc2-zy90/lib-main.sh:777-785`, `/tmp/u2a3c-i2-fc2-zy90/logs/bats-build-loop-check.txt`

---

## Claim 29: Link-text test title: "main walk fails on link text main stores longer than 4096 bytes before reading it whole".

**Location:** `test/scripts/build-loop-check.bats:942`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the outcome the test pins: a 4097-byte link fails and a 4-byte link passes. It does not cover the ordering the title claims ("before reading it whole").
**Legibility-target:** for-author

The test checks only `walk: failed` / `walk: ok`:
```
# test/scripts/build-loop-check.bats:949
    [ "$(cat "$BATS_TEST_TMPDIR/got")" = $'walk: failed\nwalk: ok' ] || { cat "$BATS_TEST_TMPDIR/got"; return 1; }
```
A mutant that read the blob whole and then rejected text over 4096 bytes would pass it. The ordering is true of the code (Claim 24), but the test does not establish it. A reader trusting the title would think the read cost is pinned.

**Evidence:** `test/scripts/build-loop-check.bats:942-950`, `scripts/lib/dev-cycle-read.sh:843-847`

---

## Claim 30: Commit test tallies: 3e58eb9c "build-loop-check 51/51, build-loop-read 19/19, dev-cycle 78/78, fixture-git-env 2/2"; 2fbd929b "63/78/19/2"; and "shellcheck SC2034 on pok (passed by name) failed the health check". Rubric: "shellcheck -S warning clean"; "The health check at 61e2e734 failed only on shellcheck SC2034 (`pok`)".

**Location:** commits 3e58eb9c, 2fbd929b; `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:24`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `@test` counts at each revision, a full run at HEAD, and shellcheck at 61e2e734 and HEAD. It does not cover the full health check's other sections at 61e2e734 ("only"), which were not re-run.
**Legibility-target:** for-orchestrator-synthesis

`grep -c '^@test'` gives 51/19/78 at 3e58eb9c (fixture-git-env 2) and 63/19/78 at 2fbd929b. The HEAD runs are 63/78/19/2. `shellcheck -S warning` on 61e2e734's lib reports SC2034 `pok appears unused` and nothing else. On HEAD's lib it exits 0.

**Evidence:** `/tmp/u2a3c-i2-fc2-zy90/logs/bats-*.txt`, `scripts/lib/dev-cycle-read.sh:803-804`, command `shellcheck -S warning scripts/lib/dev-cycle-read.sh` (cwd worktree, exit 0)

---

## Claim 31: Commit 3e58eb9c: "squash-rebase chosen over a per-commit rebase (same final tree …)"; "a commit-by-commit rebase conflicted twice in the same hunks".

**Location:** commit 3e58eb9c message
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Would need a replay of the per-commit rebase of cebfed35..2b1399ab onto 581d41d8 and a tree comparison; not attempted.
**Legibility-target:** for-orchestrator-synthesis

paraphrased — no quote available because the claim is about a rebase that was never committed, so no code holds it. The other resolution claims in the same message are verified. "U2a3b already records the whole output before the loop" is `:866`. "main_checkout replaces U2a3b's inline parent-link loop (and its pok memo)" matches main's lib `:793-794`, which holds the `pok` loop that HEAD's lib replaces.

**Evidence:** `scripts/lib/dev-cycle-read.sh:866`, `/tmp/u2a3c-i2-fc2-zy90/lib-main.sh:793-794`

---

## Claim 32: Rubric B4: "One survivor fails open: a link main stores two levels below a directory the checkout lacks (M13, `continue` → `break`) passed every test … T1 … and T2 … applied. HEAD was correct; the gap was the tests."

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md` (B4)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers M13 as applied to 21b35ebf's lib (`[[ -z "$st" ]] || continue` → `break`). It survives 21b35ebf's own suite (57/57 ok) and fails HEAD's T2. It does not cover the other mutants named (M14, M16, M18-M20, M23).
**Legibility-target:** for-orchestrator-synthesis

`logs/m13-vs-21b35ebf-suite.txt` shows 57 ok and 0 not ok. `logs/m13-vs-HEAD-T2.txt` shows `not ok 1 main walk fails on a path under a link main stores below a directory the checkout lacks…`. Unmutated, T2 passes at 21b35ebf (`logs/i2tests-at-21b35ebf.txt`: 1 ok, the T2 row), which matches "HEAD was correct".

**Evidence:** `test/scripts/build-loop-check.bats:884-895`, `/tmp/u2a3c-i2-fc2-zy90/logs/m13-vs-21b35ebf-suite.txt`, `/tmp/u2a3c-i2-fc2-zy90/logs/m13-vs-HEAD-T2.txt`, `/tmp/u2a3c-i2-fc2-zy90/logs/i2tests-at-21b35ebf.txt`

---

## Claim 33: Rubric C8: "The absent-under-checkout-dir-link shape changed 2 → 1 (stricter) … Pinned by T1 (`sd/nx.md 1`)."

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md` (C8)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers T1's row at HEAD and at 21b35ebf. It does not re-derive the "2" of main's earlier rule.
**Legibility-target:** for-orchestrator-synthesis

T1 sets `ln -s sdt sd` and expects `sd/nx.md 1`, which passes at HEAD. The ancestor `sd` fails `plaindir` (`:745`), so the call returns 1.

**Evidence:** `test/scripts/build-loop-check.bats:854-855`, `:874`, `scripts/lib/dev-cycle-read.sh:745`

---

## Claim 34: Rubric C9: "Gitfile 'as Claude Code does' unverifiable here … reads only add names or fail".

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md` (C9)
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** "Reads only add names or fail" is verified for the code: phase 2 only appends to IMPORTED_MAIN or returns 1 (Claim 15). The Claude Code half stays unverifiable, as in Claim 28.
**Legibility-target:** for-orchestrator-synthesis

paraphrased — no quote available because the claim's open half concerns Claude Code's binary, not this repo. The repo half is quoted in Claims 15 and 23.

**Evidence:** `scripts/lib/dev-cycle-read.sh:832-875`

---

## Claims Requiring Attention

### Incorrect
- **Claim 20** (`scripts/lib/dev-cycle-read.sh:719-722`): MEMO's "set only once its own … main mode passed" is false for the PATH memo at `:753`, which never checks `mc_e[PATH]`. State the precondition (callers never pass a PATH that ENT holds) or check PATH's mode before `mc_m[$c]=d`.

### Stale
- **Claim 25** (`test/scripts/build-loop-check.bats:822-825`): "(18)" was 80cc6224's count. HEAD makes 10 realpath calls, since PATH directories are memoized too.

### Mostly Accurate
- **Claim 6** (`docs/reviews/override-log.md:453`): the quoted test name "a main import of an untracked start" is not the test's title (`:921`).
- **Claim 11** (`docs/working/plan-build-loop-handoff.md:126`): F11's refusal list omits the unreadable plain file.
- **Claim 14** (`docs/working/plan-build-loop-handoff.md:279`): the second-caller contract omits "never a PATH that ENT holds". Followed as written, it can admit a file under a link main stores (repro: new 0, old 1).
- **Claim 17** (`scripts/lib/dev-cycle-read.sh:524-528`): "not a number: 0" ignores mawk's numeric prefix (`12abc` reads as 12).
- **Claim 26** (`test/scripts/build-loop-check.bats:853`): "memoizes only plain searchable directories" means "as d". The MEMO also holds entries valued 2.
- **Claim 29** (`test/scripts/build-loop-check.bats:942`): the title claims "before reading it whole", but the test pins only the outcome.

### Unverifiable
- **Claim 28** (`test/scripts/build-loop-check.bats:411,657,700`): "as Claude Code does" for gitfiles and `.git` files needs a trace of the installed Claude Code reader (Q-126).
- **Claim 31** (commit 3e58eb9c): "same final tree" / "conflicted twice" needs a replay of the per-commit rebase.
- **Claim 34** (rubric C9): the same Claude Code half as Claim 28.

## Escalations

- **security-reviewer / api-consistency-reviewer:** main_checkout memoizes PATH as `d` (`scripts/lib/dev-cycle-read.sh:753`) without checking `ENT[PATH]`. A caller that passes a path main stores as a link or gitlink, while the checkout holds a plain directory there, makes every later call below it skip the link refusal. Repro: `ENT=([a]=120000)`, then `main_checkout ENT M a` (2) and `main_checkout ENT M a/f`, which returns 0 where 21b35ebf returned 1 (`/tmp/u2a3c-i2-fc2-zy90/logs/repro1.txt`). main_imports is safe: both call sites guard on `ent` (`:825`, `:870`), and the differential found 0 divergences in 15,800 in-contract calls. The plan's U2b contract for "a caller of main_checkout other than main_imports" (plan `:279`) and the comment (`:719-722`) do not state the precondition. Assess whether to add it to the contract, or to make `:753` conditional on `[[ -z "${mc_e[$3]+set}" ]]`.
- **test-strategy:** The deep-token test's `timeout 6` has 9x headroom on the pass side (0.66 s) but only 1.8x on the kill side (21b35ebf 11.0 s). On a host about twice as fast, the O(D³) regression it exists to catch would pass. A relative bound, or D large enough that the old shape costs over 30 s, would hold the kill. The link-text test pins only the outcome, not "before reading it whole". A read-then-reject mutant survives, and a `git` shim counting `cat-file blob` calls would pin the ordering. No test pins main_checkout's precondition (escalation above).
- **performance-reviewer:** none new. Rows 451/455's figures re-measure close: drain 0.84 s per GiB here against "about 0.7", and walk work 8,110.

## Goal-Alignment Note
- Success criterion (restated verbatim): "User goal: land `feat/build-loop-u2a3c` (worktree `/workspace/.claude/wt-build-loop-u2a3c`) on main once its review-fix loop is clean." (The goal preamble has no separate Success criterion line, so this is the User goal line.)
- Answered: yes. All eight claim groups in the shared brief were checked, most by execution: the memo across call orders, the 4096 cap, capped_read, the work bound, the restored docs, `.git`, the tests, and the commit messages and rows.
- Out of scope: the iteration-1 and iteration-2 review reports beyond the override rows and the iteration-2 rubric's code claims. The Claude Code binary trace for gitfiles.
- Escalate: the PATH-memo precondition (security / api-consistency) and the deep-token timeout's kill margin (test-strategy).
- Decisions I made: I verdicted the PATH-memo comment Incorrect rather than Mostly accurate, because its stated mechanism ("its own … main mode passed") never runs for PATH, even though main_imports' call sites make the conclusion hold.
