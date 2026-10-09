Commit: a382a3f8
**Replication:** k=1 (loop pass, decision 031)

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2b1b (branch `feat/build-loop-u2b1b`)
**Scope:** fix commit a382a3f8 only (`git diff 809df345..a382a3f8`): its commit message; `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh` and `test/scripts/build-loop-check.bats` changes; override-log rows 494, 509, 511-517; plan step 13. The iteration-1 review reports added in the commit are not checked.
**Checked:** 2026-10-08
**Total claims checked:** 30
**Summary:** 25 verified, 5 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Execution provenance (shared by every `executed` claim below). Scratch dir `S=/tmp/claude-1000/-workspace/0c855a7c-1c04-4bab-8bf1-7620be67b78e/scratchpad/u2b1b-i2/fc`. The suites ran from the worktree (through the `scratchpad/wt` symlink) at HEAD a382a3f8, started 2026-10-08T21:55:48Z, with `TMPDIR=$(mktemp -d -p $S) bats test/scripts/<suite>.bats` (fixture-hermeticity from `test/`), all exiting 0. Logs are in `$S/logs/<suite>.log`. Each mutant is a `git archive a382a3f8 scripts test` copy in `$S/<mutant>/`, changed by one perl substitution and run with `bats -f <filter> test/scripts/build-loop-check.bats` from that copy, starting 2026-10-08T21:56:55Z. Logs are in `$S/logs/mut-<mutant>.log`. The git-level merge-tree probe is `$S/probe1.sh` (git 2.39.5), logged to `$S/logs/probe1-merge-tree.log`. Hallucination-pattern log read: claim 9 matches the "test tally" pattern (entries for 59ca38f and 37c5ea9). The counts were checked by running the suites, and they match.

---

## Claim 1: "security F1: nrules checks own_blob's exit status (a failed second read made hash-object print the empty-blob id)."

**Location:** commit a382a3f8 message; `scripts/build-loop.sh:562-563`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers how nrules handles own_blob's return status (a non-zero status denies the path). It does not establish a runtime test of the race, since none exists and override row 515 declines one.

```bash
# scripts/build-loop.sh:562-563
    { [[ "$5" == M && "$2" == "$3" ]] && ob="$(own_blob "$1")" && [[ "$4" == "$ob" ]]; } \
      || DENY="this brief: only its first Status: line outside a fence may change, from open to done"
```
The substitution's status gates the `&&` chain. The script runs under `set -euo pipefail` (`scripts/build-loop.sh:140`), so a failed `git cat-file` in own_blob's last pipeline makes own_blob's status non-zero (`scripts/build-loop.sh:540`).

**Evidence:** `scripts/build-loop.sh:140`, `scripts/build-loop.sh:535-541`, `scripts/build-loop.sh:552-571`

---

## Claim 2: "security F2: one cat-file --batch-check over every new regular file of the merge … New refusal "names a file the object store lacks"; test with a mktree --missing tip (mutant fails)."

**Location:** commit a382a3f8 message; `scripts/build-loop.sh:606-611`; `test/scripts/build-loop-check.bats:1544-1549`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers four things: there is one batch-check over every changed path whose new mode is 100644/100755; the refusal text matches; the test builds a `mktree --missing` tip; and the mutant `if false &&` (which drops the check) fails the R6 test. It does not cover a missing subtree passed by id, which `diff-tree` refuses instead (claim 8b).

```bash
# scripts/build-loop.sh:601,609-611
    [[ "${nms[-1]}" != 100644 && "${nms[-1]}" != 100755 ]] || ids+=("${nos[-1]}")
  if [[ ${#ids[@]} -gt 0 ]] && { ! out="$(printf '%s\n' "${ids[@]}" | gate_git cat-file --batch-check='%(objecttype)')" \
    || [[ "$(printf '%s\n' "$out" | grep -cx blob)" -ne ${#ids[@]} ]]; }; then
    echo "refuse $a: the merge of $br names a file the object store lacks"; return
```
Mutant mF2 (`if [[ ${#ids[@]} -gt 0 ]] &&` changed to `if false &&`): test 3 (R6) reported `not ok`, while T12 and T14 stayed ok. Command: `bats -f 'T12|R6, U2b1b|T14'`, cwd `$S/mF2`, exit 1.

**Evidence:** `scripts/build-loop.sh:596-611`, `test/scripts/build-loop-check.bats:1532-1550`, `$S/logs/mut-mF2.log`, `$S/logs/mut-base.log`

---

## Claim 3: "performance F1: one lower_all pass per brief instead of a tr per path (measured 13.5 s at 5,000 paths as built)."

**Location:** commit a382a3f8 message; `scripts/build-loop.sh:612-613`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers two points: check_line makes one `lower_all` call per brief, and the 13.5 s figure is the iteration-1 performance reviewer's measurement. It does not re-measure 13.5 s.

```bash
# scripts/build-loop.sh:613
  if ! nul_list lps lower_all "${ps[@]}" || [[ ${#lps[@]} -ne ${#ps[@]} ]]; then echo "refuse $a: the paths the merge of $br changes could not be lower-cased"; return; fi
```
The figure is sourced at `docs/reviews/performance-reviewer-review-2026-10-08-build-loop-u2b1b.md:113`: "`lower` fork+exec per changed path: 13.5 s vs 1.2 s at 5,000 paths". nrules no longer calls `lower` (`scripts/build-loop.sh:552-571`).

**Evidence:** `scripts/build-loop.sh:612-618`, `docs/reviews/performance-reviewer-review-2026-10-08-build-loop-u2b1b.md:33,113`

---

## Claim 4: "api 1: the refusing verdict carries TIP and TREE: "K of N changed paths refused in the merge of TIP (tree TREE)""

**Location:** commit a382a3f8 message; `scripts/build-loop.sh:619`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the verdict text and the fact that `$sha` is the tip status_line read and `$tree` is merge_result's tree. It does not cover consumers that parse the line, since none exist before U3.

```bash
# scripts/build-loop.sh:619
  if [[ "$nd" -eq 0 ]]; then echo "ok $a $sha $tree"; else echo "refuse $a: $nd of ${#ps[@]} changed paths refused in the merge of $sha (tree $tree)"; fi
```
The test helper `nref` at `test/scripts/build-loop-check.bats:1450` builds the same text from `git rev-parse feat/x` and `git merge-tree --write-tree main feat/x`. T14, T12 and the pathform test assert it, and build-loop-check passed 101/101.

**Evidence:** `scripts/build-loop.sh:578-590,619`, `test/scripts/build-loop-check.bats:1450`, `$S/logs/build-loop-check.log`

---

## Claim 5: "api 2, architecture 5: the R7 check is default_gate, beside state_gate, printing every finding."

**Location:** commit a382a3f8 message; `scripts/build-loop.sh:235-250,259`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the two checks and the fact that neither returns early. It does not cover a test of both findings printing together; the R7 test triggers one finding per run, and both together need a refs/heads/master that is not a commit (resolve_main skips it).

```bash
# scripts/build-loop.sh:240-249
  if git show-ref --verify --quiet refs/heads/main && git show-ref --verify --quiet refs/heads/master; then
    echo "refuse state default-branch: both main and master exist"; bad=1
  fi
  p="$(git symbolic-ref -q refs/remotes/origin/HEAD)" || true
  if [[ -n "$p" && "$p" != "refs/remotes/origin/$MAIN" ]]; then
    echo "refuse state default-branch: origin/HEAD names ${p#refs/remotes/}, but the default branch taken is $MAIN"; bad=1
  fi
  return "$bad"
```
It is called at `scripts/build-loop.sh:259` as `if [[ "$MODE" == check ]]; then default_gate || exit 2; fi`, after `main_by_name`.

**Evidence:** `scripts/build-loop.sh:235-259`, `scripts/lib/dev-cycle-read.sh:490-502`

---

## Claim 6: "architecture 1: nrules reads truthrule's cycle, settings and user words (one source for the named files); the briefs/ and cycles/ subtrees stay an N-only widening, named in its comment."

**Location:** commit a382a3f8 message; `scripts/build-loop.sh:564-569`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers nrules reading truthrule and the subtree regex in its default branch. It does not cover floor's use of the same words, which comes in U2c.

```bash
# scripts/build-loop.sh:565-569
    truthrule "$7" || true  # $7 is lower-cased, so no word hides cycle, settings or user
    case "$TRUTH_WHY" in
      cycle|settings) DENY="one of the dev cycle's own files" ;;
      user) DENY="the user's constraints doc, which every loop prompt carries" ;;
      *) [[ ! "$7" =~ ^docs/working/(briefs|cycles)/ ]] || DENY="one of the dev cycle's own files" ;;
```
**Evidence:** `scripts/build-loop.sh:544-571`, `scripts/lib/dev-cycle-read.sh:1087-1097`

---

## Claim 7: "A16 is pinned (T12 under submodule ignore=all in .gitmodules and the repo config; the mutant running diff-tree in the real repository fails it)."

**Location:** commit a382a3f8 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers three mutants of the diff-tree line. It does not establish that either guard (the gate repository, or `--ignore-submodules=none`) is pinned alone.

T12 fails only when the mutant both runs in the real repository **and** drops `--ignore-submodules=none`:
- mA16a: `if ! git diff-tree -r --no-renames --raw -z "$MAIN_SHA" ...` (real repo, no flag). T12 is not ok and prints "4 of 6", with `A gl` hidden. Log `$S/logs/mut-mA16a.log`, exit 1.
- mA16b: `if ! git diff-tree -r --no-renames --raw -z --ignore-submodules=none ...` (real repo, flag kept). T12 is ok. Log `$S/logs/mut-mA16b.log`, exit 0.
- mA16c: `gate_git diff-tree ...` without `--ignore-submodules=none`. T12 is ok. Log `$S/logs/mut-mA16c.log`, exit 0.

The more precise wording: the test pins the union of the two guards. A mutant that runs diff-tree in the real repository but keeps the flag passes.

**Evidence:** `scripts/build-loop.sh:592-597`, `test/scripts/build-loop-check.bats:1507-1523`, `$S/logs/mut-mA16a.log`, `$S/logs/mut-mA16b.log`, `$S/logs/mut-mA16c.log`

---

## Claim 8a: "a missing top-level tree is read as empty with a warning, exiting 0 only when that merge is otherwise clean; a missing subtree or blob is fatal only when merge-tree must read it (one passed by id is silent …)"

**Location:** commit a382a3f8 message (correction to cc9b69d3)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers git 2.39.5's `merge-tree --write-tree --no-messages` in six probed cases. It does not cover other git versions.

The probe `bash $S/probe1.sh` (exit 0, cwd under `$S`) gave these results:
- A: the tip's tree is missing and the merge is clean. Output was `error: Could not read 6ba900…` with rc=0, and the tree differs from the real result.
- B: the tip's tree is missing and main changed a file. Output was the warning plus conflict stages, with rc=1.
- C: an unchanged subtree is missing. Silent, rc=0.
- D: a blob only the tip adds is missing. Silent, rc=0.
- E: a blob both sides change is missing. `fatal: unable to read blob object`, rc=128.
- F: a subtree both sides change is missing. `fatal: unable to read tree`, rc=128.

**Evidence:** `$S/probe1.sh`, `$S/logs/probe1-merge-tree.log`

## Claim 8b: "(one passed by id is silent, which security F2 now refuses)"

**Location:** commit a382a3f8 message (correction to cc9b69d3)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers how `--check` handles a missing blob and a missing new subtree, each passed by id. It does not cover a missing subtree that main already holds unchanged, which diff-tree never reads.

F2's batch-check only covers blobs (claim 2). I ran a scratch bats probe in `$S/base/test/scripts/` (since deleted), with a tip that adds `newdir/` whose tree object was removed after `mktree --missing`. `--check` printed `refuse …: the paths the merge of feat/x changes could not be listed` (status 2). So `diff-tree -r` failing refuses a missing subtree, not F2. Precise version: "one passed by id is silent; --check now refuses it, a blob by F2's batch-check and a subtree by diff-tree's failed listing."

**Evidence:** `scripts/build-loop.sh:595-597,606-611`. Probe output recorded in this session (probe file removed as scratch).

---

## Claim 9: "Tests: build-loop-check 101, build-loop-read 19, dev-cycle 78, fixture-git-env 2, fixture-hermeticity 2; shellcheck clean on build-loop.sh … 367 code lines against main."

**Location:** commit a382a3f8 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the pass counts at a382a3f8 on this host, shellcheck on `scripts/build-loop.sh`, and the line count read as insertions plus deletions outside `docs/` (the plan's row-62 measure). It does not cover the lib's shellcheck notes.

Suite results, all exit 0 with no failures: build-loop-check ok=101, build-loop-read ok=19, dev-cycle ok=78, fixture-git-env ok=2, fixture-hermeticity ok=2. `shellcheck scripts/build-loop.sh` exited 0. `git diff --numstat main...a382a3f8 -- . ':!docs'` gave `158 26 scripts/build-loop.sh`, `5 3 scripts/lib/dev-cycle-read.sh` and `165 10 test/scripts/build-loop-check.bats`, which sum to 328 + 39 = 367. This matches the logged "test tally" hallucination pattern, but the numbers check out.

**Evidence:** `$S/logs/build-loop-check.log`, `$S/logs/build-loop-read.log`, `$S/logs/dev-cycle.log`, `$S/logs/fixture-git-env.log`, `$S/logs/fixture-hermeticity.log`

---

## Claim 10: "R8: decided a Q-103 residual … rows 494 and 509 reworded, plan step 13 lists it for U5."

**Location:** commit a382a3f8 message; `docs/reviews/override-log.md:494,509`; `docs/working/plan-build-loop-handoff.md:305`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the presence and content of the three edits. It does not judge whether the residual decision is sound.

Row 494 now ends: "**U2b1b i1 (security F3):** "the gate repository closes merge-tree" holds against state planted before the run, not against a concurrent same-uid writer (R8, row 509)." Row 509 ends: "**Decided at U2b1b iteration 1 (security, architecture concur): Q-103 residual.** … Listed in plan step 13 for U5's Q-103 re-route." Plan :305 reads "U2b1a2's R8 (a same-uid writer racing the gate's GATE_TMP: its config, info/, work/.gitattributes, err and diff; override row 509)".

**Evidence:** `docs/reviews/override-log.md:494`, `docs/reviews/override-log.md:509`, `docs/working/plan-build-loop-handoff.md:305`

---

## Claim 11: --check help: "or a file the merge adds or changes names a blob the object store lacks. Or "K of N changed paths refused in the merge of TIP (tree TREE)", when deny lines follow."

**Location:** `scripts/build-loop.sh:107-110`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers how the help text matches the two output lines at `:610` and `:619`. "Adds or changes" includes T entries to a regular file and exec-bit-only changes, both put in `ids` by new mode. It does not cover subtrees (claim 8b).

The code prints `echo "refuse $a: the merge of $br names a file the object store lacks"` (`scripts/build-loop.sh:610`) and the K of N line quoted in claim 4.

**Evidence:** `scripts/build-loop.sh:101-110,601,610,619`

---

## Claim 12: default_gate: "Prints one line per finding, as state_gate does; returns 1 on any."

**Location:** `scripts/build-loop.sh:235-239`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers default_gate's two checks (quoted in claim 5) and the fact that neither exits early. It does not cover "(U3b's --state calls both)", which describes a future caller.

**Evidence:** `scripts/build-loop.sh:235-250`

---

## Claim 13: own_blob: "Returns 1 when a read fails; the caller checks it (hash-object would hash a truncated read)."

**Location:** `scripts/build-loop.sh:533-534`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** This covers own_blob's return values and its one caller. It does not cover perl failures beyond pipefail.

The status is 1 only for the first read. The second read is a pipeline whose status under pipefail is cat-file's (128) or gate_git's (3):
```bash
# scripts/build-loop.sh:539-540
  n="$(git cat-file blob "$MAIN_SHA:$1" | env LC_ALL=C awk "$FENCE_AWK"'…')" || return 1
  [[ "$n" -gt 0 ]] || return 1
  git cat-file blob "$MAIN_SHA:$1" | N="$n" perl -pe '…' | gate_git hash-object --no-filters --stdin
```
Precise version: "returns non-zero when a read fails". The caller (claim 1) tests for non-zero, so it does not matter in practice.

**Evidence:** `scripts/build-loop.sh:535-541`, `scripts/build-loop.sh:509-514`, `scripts/build-loop.sh:562`

---

## Claim 14: nrules comment: "the cycle's files (truthrule's cycle and settings words: writable() and docs/dev-cycle.md, plus anything under docs/working/briefs/ or docs/working/cycles/) and the constraints doc (its user word) compare lower-cased"

**Location:** `scripts/build-loop.sh:544-551`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers how truthrule's words map to writable(), docs/dev-cycle.md and docs/constraints.md, and how the subtree regex runs on `$7`. It does not cover non-ASCII case folding, which pathform's ASCII-only set refuses first at `:559`.

```bash
# scripts/lib/dev-cycle-read.sh:1093-1095
  elif writable "$1"; then TRUTH_WHY="cycle"
  elif [[ "$1" == docs/dev-cycle.md ]]; then TRUTH_WHY="settings"
  elif [[ "$1" == docs/constraints.md ]]; then TRUTH_WHY="user"
```
The brief's own file is "matched exactly", as `[[ "$6" == "$1" ]]` (`:561`). A case variant of it falls through to truthrule on the lower-cased path, where `anybrief` makes it `cycle`.

**Evidence:** `scripts/build-loop.sh:544-571`, `scripts/lib/dev-cycle-read.sh:199-207,1087-1097`

---

## Claim 15: "$7 is lower-cased, so no word hides cycle, settings or user"

**Location:** `scripts/build-loop.sh:565`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers truthrule's order (case, instr, dot, then cycle, settings, user, then record) for every path that writable(), docs/dev-cycle.md or docs/constraints.md matches. It does not cover paths under briefs/ or cycles/ that are not writable(); those reach the `*)` regex and are denied whatever word they get.

`case` cannot fire: `$7` comes from `lower_all`'s ASCII tr (`scripts/lib/dev-cycle-read.sh:857`), and pathform has already refused anything outside NAMECHARS. `instr` cannot fire either. Its basename test is anchored: `INSTRUCTION_FILE='^(claude|agents?|gemini)(\.[…]+)?\.md$|^skill\.md$'` (`scripts/lib/dev-cycle-read.sh:516`), and no writable() basename (roadmap.md, questions.md, questions-archive.md, idea-log.md, cycle-DATE.md, DATE-slug.md), dev-cycle.md or constraints.md matches it. Its PROMPT_DIR and `.claude/rules` arms need a `.claude/` component (`:520,529`). `dot` (`[[ "/$1" == */.* ]]`) cannot fire because none of these paths has a dot-led component. `record` is tested after `user`, so it cannot win.

**Evidence:** `scripts/lib/dev-cycle-read.sh:199-207,516-529,857,1087-1097`, `scripts/build-loop.sh:559-569`

---

## Claim 16: check_line header: ""ok BRIEF TIP TREE" or "refuse BRIEF: K of N changed paths refused in the merge of TIP (tree TREE)", then a "path …" or "deny …" line per path"

**Location:** `scripts/build-loop.sh:576-581`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the two verdict forms at `:605,619` and the row lines at `:617,620`. It does not cover status_line's own lines.

The code prints `printf '%s\n' "${rows[@]}"` (`:620`) after the verdict. With zero paths, it returns after `echo "ok $a $sha $tree"` (`:605`) and prints no row.

**Evidence:** `scripts/build-loop.sh:575-621`

---

## Claim 17: "merge-tree passes a side's unchanged blob by id without reading it, so a blob the store lacks would land unseen: every new file must be present."

**Location:** `scripts/build-loop.sh:606-607`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers two things: "every new file" means each diff-tree record whose new mode is 100644/100755 (A, M, a T to a regular file, and an exec-bit-only M, whose blob is checked though main already holds it); and the git behaviour (probe case D). It does not cover D records (no new blob), symlink or gitlink new sides (denied by the mode rule), or subtrees (claim 8b).

The collection step is quoted in claim 2 (`:601`). Probe case D: a blob only the tip adds was missing, and merge-tree was silent with rc=0. An exec-bit-only change passed `--check` as `path … M s.sh` (scratch probe).

**Evidence:** `scripts/build-loop.sh:599-611`, `$S/logs/probe1-merge-tree.log`

---

## Claim 18: "One lower-casing pass for every path (a tr per path cost 2.5 ms each)."

**Location:** `scripts/build-loop.sh:612`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** This covers the single `lower_all` call, `nul_list`'s fail-closed semantics, and a re-timing of the old `lp="$(lower …)"` form. It does not reproduce the reviewer's whole-run figure.

One pass is right (`:613`, quoted in claim 3). Under `nul_list`, a failed tr empties the list and returns 1; a truncated output shows up through the length check `${#lps[@]} -ne ${#ps[@]}`. Both cases refuse. An empty path list never reaches this line because `:605` returns first. If it did, `printf '%s\0'` with no arguments would emit one empty element, the length check would fail, and the brief would be refused (fail-safe). Timing: 1,000 calls of `lp="$(lower …)"` in bash took 1,166 ms (1.17 ms/call) on this host at load 0.77. The reviewer reported ~2.5 ms/path in a loaded per-path context (`performance-reviewer-review-…:33`). The number depends on the environment; "about 1-2.5 ms" would be the precise version.

**Evidence:** `scripts/build-loop.sh:605,612-613`, `scripts/lib/dev-cycle-read.sh:851-857`, `docs/reviews/performance-reviewer-review-2026-10-08-build-loop-u2b1b.md:33`

---

## Claim 19: refusal line "refuse BRIEF: the merge of BR names a file the object store lacks" (help and commit wording)

**Location:** `scripts/build-loop.sh:610`; `test/scripts/build-loop-check.bats:1549`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the exact string, and that the test asserts it as the whole output with status 2. It does not cover a store holding the id as a non-blob, which the `grep -cx blob` count mismatch also refuses with this text.

The test asserts `[ "$status" -eq 2 ] && [ "$output" = "refuse $B: the merge of feat/x names a file the object store lacks" ]`, and it passed in the full suite.

**Evidence:** `scripts/build-loop.sh:609-611`, `test/scripts/build-loop-check.bats:1544-1549`, `$S/logs/build-loop-check.log`

---

## Claim 20: lib header contract item 5: "build-loop.sh's N rules apply them, and pathform, under both policies before floor runs, so a path pathform refuses (.github/x.yml) is denied as a path form and floor's dotfile reason serves the dot paths pathform accepts (.envrc)."

**Location:** `scripts/lib/dev-cycle-read.sh:59-65`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers four things: the N rules' order (pathform, then mode, then the own brief) at `scripts/build-loop.sh:559-563`; pathform refusing `.github` and accepting `.envrc`; and floor's dot reason. It does not cover U2c's floor call, since build-loop.sh does not call floor yet, so "before floor runs" is a contract for U2c.

pathform's component test is `[[ -n "$c" && "$c" != "." && "$c" != ".." && "$c" != [.][gG][iI][tT]* ]] || return 1` (`scripts/lib/dev-cycle-read.sh:191`). That refuses `.github` and accepts `.envrc`. floor maps `dot) FLOOR_WHY="a dotfile or a path under a dot-directory"` (`:1144`) from `elif [[ "/$1" == */.* ]]; then TRUTH_WHY="dot"` (`:1092`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:184-192,1087-1097,1136-1158`, `scripts/build-loop.sh:559-563`

---

## Claim 21: override row 494 addition: "the gate repository closes merge-tree" holds against state planted before the run, not against a concurrent same-uid writer (R8, row 509)

**Location:** `docs/reviews/override-log.md:494`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** This covers that the gate repository's config is written fresh into a new temp dir at setup, so state planted before the run cannot reach it. It does not cover the race itself (R8), which was taken from row 509's probe and not re-probed.

```bash
# scripts/build-loop.sh:503
  printf '[core]\n\trepositoryformatversion = 1\n[extensions]\n\tobjectformat = %s\n' "$fmt" > "$GATE_TMP/git/config"
```
**Evidence:** `scripts/build-loop.sh:495-505`, `docs/reviews/override-log.md:494,509`

---

## Claim 22: override row 509: "Surface: `$GATE_TMP/git/config`, `git/info/`, `work/.gitattributes`, and from U2b1b `err` and `diff` (merge-base, cat-file, diff-tree and hash-object now run there too)."

**Location:** `docs/reviews/override-log.md:509`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers which files and commands are new against main. It does not establish that this list is the whole race surface (GATE_TMP's `git/refs` and `HEAD` are not named).

On main the gate repository ran only merge-tree, with stderr discarded: `git show main:scripts/build-loop.sh` line 465 reads `out="$(cd "$GATE_TMP/work" && "${GATE_ENV[@]}" git merge-tree --write-tree --no-messages "$MAIN_SHA" "$1" 2>/dev/null)"`. At a382a3f8, gate_git writes `2>"$GATE_TMP/err"` (`scripts/build-loop.sh:511`). merge-base and cat-file -e run through it (`:521,524`), as do diff-tree to `"$GATE_TMP/diff"` (`:595`), cat-file --batch-check (`:609`) and hash-object (`:540`).

**Evidence:** `scripts/build-loop.sh:509-528,540,595,609`; `git show main:scripts/build-loop.sh` lines 441-465

---

## Claim 23: override row 511 addition: "stay with the F3 row" means override row 492 (U2b1a security F3, trigger U3), which does not yet name alternates, packs or the multi-pack-index … A18 priced (performance F2): 3 ms at 1,000 … 50 ms at 20,000, 306 ms at 100,000 (7 ms … with a commit-graph)

**Location:** `docs/reviews/override-log.md:511`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers row 492's content and the source of the timings. It does not re-measure the timings.

Row 492 reads "Rewriting a loose object's bytes behind its unchanged id … Revisit trigger: U3's `--merge` … name the residual (trees and commits) in Q-103". It does not mention alternates, packs or the multi-pack-index. The timings appear verbatim at `docs/reviews/performance-reviewer-review-2026-10-08-build-loop-u2b1b.md:63`: "50 ms (7 ms with a commit-graph) … At 1,000 commits: 3 ms; at 100,000: 306 ms".

**Evidence:** `docs/reviews/override-log.md:492,511`, `docs/reviews/performance-reviewer-review-2026-10-08-build-loop-u2b1b.md:63`

---

## Claim 24: override row 512: "check_line is the whole per-brief pipeline and returns printed text only"

**Location:** `docs/reviews/override-log.md:512`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers check_line's outputs and its caller. It does not cover U3's future needs.

check_line only `echo`es and `printf`s, and returns with no value. The caller captures text: `out="$(check_line "$a")"; printf '%s\n' "$out"` (`scripts/build-loop.sh:640`).

**Evidence:** `scripts/build-loop.sh:575-621,635-640`

---

## Claim 25: override row 513: "No test pins check_line's NUL-count completeness check (a mutant removing it passes)"

**Location:** `docs/reviews/override-log.md:513`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the build-loop-check suite against the mutant. It does not cover the row's claim that "git's own diff-tree -z output never ends mid-record", which was not probed.

Mutant mNUL replaced `:604`'s condition with `if false && [[ 1 -ne …`. The full `bats test/scripts/build-loop-check.bats` from `$S/mNUL` exited 0 with ok=101.

**Evidence:** `scripts/build-loop.sh:603-604`, `$S/logs/mut-mNUL-full.log`

---

## Claim 26: override row 514: "Each R6 guard (any git stderr; the main, tip and merge-base trees exist) passes the R6 test alone … The test pins their union (the double mutant fails)."

**Location:** `docs/reviews/override-log.md:514`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the R6 test against three mutants. It does not cover the row's "every probed missing-tree case trips both" beyond probe cases A and B (claim 8a).

- mR6s, where `[[ ! -s "$GATE_TMP/err" ]] || return 3` became `true` (`:512`): ok.
- mR6t, where the cat-file -e loop body became `:` (`:524`): ok.
- mR6st, with both changes: not ok.

Each ran as `bats -f 'R6, U2b1b'`, with exit codes 0, 0 and 1.

**Evidence:** `scripts/build-loop.sh:509-528`, `$S/logs/mut-mR6s.log`, `$S/logs/mut-mR6t.log`, `$S/logs/mut-mR6st.log`

---

## Claim 27: override row 517: "U2c's floor call will run inside check_line's subshell …; gate_git's code 3 folds into failure and every call shares one err file; `--status` has no default-branch refusal"

**Location:** `docs/reviews/override-log.md:517`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the three present-tense facts. It does not cover U2c's future placement of floor.

check_line runs in `$(…)` (`scripts/build-loop.sh:640`, with the comment `open_shared  # once, in this shell: check_line runs in a subshell` at `:635`). gate_git always writes `2>"$GATE_TMP/err"` and `return 3` (`:511-512`), and callers test only for non-zero (for example `|| return 2` at `:524`). default_gate runs only under `if [[ "$MODE" == check ]]` (`:259`).

**Evidence:** `scripts/build-loop.sh:259,509-528,635-640`

---

## Claim 28: plan step 13: "U2b1a2's R8 (a same-uid writer racing the gate's GATE_TMP: its config, info/, work/.gitattributes, err and diff; override row 509)"

**Location:** `docs/working/plan-build-loop-handoff.md:305`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers whether the step matches row 509's surface list. It does not cover the completeness caveat in claim 22.

Both name config, info/, work/.gitattributes, err and diff, and row 509 says "Listed in plan step 13".

**Evidence:** `docs/working/plan-build-loop-handoff.md:305`, `docs/reviews/override-log.md:509`

---

## Claim 29: T12 name: "--check refuses a symlink or gitlink on either side, though submodule ignore=all is set, and passes an exec bit (T12, F7, A16, U2b1b)"; and its comment "diff-tree in the real repository would hide gl (A16)"

**Location:** `test/scripts/build-loop-check.bats:1507-1509`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the name, which is verified: an old-side gitlink `og` (T), a new gitlink `gl` (A), symlinks either side, and exec-bit `path` lines under ignore=all in .gitmodules and the repo config. It also covers the comment, which is Mostly accurate. It does not establish that either A16 guard is pinned alone.

The test passes at a382a3f8 and asserts `"$(nref 5 7)"` with `T og` denied. The comment holds only for real-repository diff-tree **without** `--ignore-submodules=none`: mutant mA16b (real repository, flag kept) shows gl and passes (claim 7).

**Evidence:** `test/scripts/build-loop-check.bats:1507-1523`, `$S/logs/mut-mA16a.log`, `$S/logs/mut-mA16b.log`

---

## Claim 30: R6 and T14 test names after the edit: "… a missing blob does not land (R6, U2b1b)"; T14 adds docs/working/Questions.md and docs/CONSTRAINTS.md

**Location:** `test/scripts/build-loop-check.bats:1532`, `test/scripts/build-loop-check.bats:1453-1462`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the R6 test's new clause (it fails under mF2) and T14's two new upper-case paths, denied as cycle and user, with the count going to 15 of 16. It does not cover an upper-case path under `docs/working/Briefs/` or `Cycles/` (T14 does not test the subtree regex on a case variant), which T14's name, unchanged in this commit, does not specifically claim.

T14 asserts `has "deny $B A docs/CONSTRAINTS.md: $NUSER"`, and `docs/working/Questions.md` is in `fs`, each expecting `$NOWN`. Both tests passed at base and in the full suite.

**Evidence:** `test/scripts/build-loop-check.bats:1453-1470,1532-1550`, `$S/logs/mut-base.log`, `$S/logs/mut-mF2.log`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 7** (commit a382a3f8): the A16 test fails only if the mutant drops `--ignore-submodules=none` as well as moving diff-tree to the real repository. Either guard alone keeps T12 green, so it pins the union.
- **Claim 8b** (commit a382a3f8): "which security F2 now refuses" holds for blobs. A missing subtree passed by id is refused by diff-tree's failed listing, not F2.
- **Claim 13** (`scripts/build-loop.sh:533`): own_blob returns non-zero (1, 128 or 3), not always 1.
- **Claim 18** (`scripts/build-loop.sh:612`): "2.5 ms each" depends on the environment; I re-timed 1.17 ms per call on this host.
- **Claim 29** (`test/scripts/build-loop-check.bats:1509`): the comment's "would hide gl" holds only without `--ignore-submodules=none`.

### Unverifiable
(none)

## Goal-Alignment Note

The user's goal is to land U2b1b after a clean review-fix loop. This pass found no Incorrect claim in a382a3f8. Every "Fixed" item in its message matches the code. The F2 mutant fails as claimed, the R6 and NUL-count override rows hold under their mutants, the test tallies and the 367-line count are exact, and the correction to cc9b69d3 matches git 2.39.5's merge-tree behaviour. The five Mostly-accurate items are wording. The only one that bears on the unit's claims about itself is claim 7/29: the A16 pin is a union pin, so a future change that drops `--ignore-submodules=none` while keeping the gate repository (or the reverse) would pass T12. That is honest-path test coverage, not a red, and could go in an override row or one more assertion. The nrules truthrule refactor is sound: no earlier truthrule word can mask cycle, settings or user for any path those rules name.
