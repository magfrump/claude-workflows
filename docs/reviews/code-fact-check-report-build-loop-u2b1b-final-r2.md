Commit: e02d056b
**Replication:** k=3, replicate fc-r2 (final confirming pass)

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2b1b (branch `feat/build-loop-u2b1b`, HEAD e02d056b, base main 0e4596ce)
**Scope:** full branch, `git diff main...HEAD` (cc9b69d3, 809df345, a382a3f8, e02d056b). Checked: `scripts/build-loop.sh` (the `--check` help and every comment the branch added or edited), `scripts/lib/dev-cycle-read.sh` (contract item 5, truthrule's comment), the tests added or renamed in `test/scripts/build-loop-check.bats`, the plan's edited lines, override-log rows 494, 497, 507-520, and the four commit messages. The review reports the branch adds are not checked.
**Checked:** 2026-10-08
**Total claims checked:** 66
**Summary:** 55 verified, 5 mostly accurate, 1 stale, 4 incorrect, 1 unverifiable

Execution provenance, shared by every `executed` claim. `S=/tmp/claude-1000/-workspace/0c855a7c-1c04-4bab-8bf1-7620be67b78e/scratchpad/u2b1b-i3/fc-r2`. Git 2.39.5.
- Suites: from the worktree (through `scratchpad/wt`) at e02d056b, started 2026-10-08T22:16:49Z. The command was `TMPDIR=$(mktemp -d -p $S) bats -j 8 test/scripts/build-loop-check.bats test/scripts/build-loop-read.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats`. It exited 0 with 124 ok and 0 not ok (`$S/logs/bats.txt`). `bats -j 8 test/scripts/dev-cycle.bats` exited 0 with 78 ok (`$S/logs/bats-dc.txt`). `shellcheck scripts/build-loop.sh` exited 0.
- Mutants: run by `python3 $S/probes/mutants.py`, cwd `$S`, from 2026-10-08T22:19Z. Each mutant is a copy of the worktree's `scripts/` and `test/` under `$S/mut/<name>-*/`, changed by one exact string substitution (asserted to match once), then run as `bats -j 8 -f <filter>` on that copy's build-loop-check.bats. Each log holds its command, cwd, timestamp and exit code (`$S/logs/mut-<name>.txt`).
- Probes, each `set -eu` with its own mktemp dir under `$S`, run as `timeout N bash $S/probes/<p>.sh > $S/logs/<p>.txt`:
  - p1-mergetree (22:18:49Z, exit 0): missing objects, cases A-G.
  - p2-a15 (22:20:17Z, exit 128 from its last diagnostic line, after both runs printed).
  - p3-time (22:20:33Z, exit 0): 5,000-path timing.
  - p4-f8-a17 (22:22:08Z, exit 0): F8's flag and A17's system config.
- Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`): five entries. The "test tally" pattern (59ca38f, 37c5ea9) applies to claims 57, 63 and 64. Each count was checked against `grep -c '^@test'` at its commit and by the suite run, and each matches. No Incorrect verdict here is a fabricated symbol, so the log gains no entry. This pass was told to write nothing else in the worktree in any case.

---

## Claim 1: override row 494 addition: "the gate repository closes merge-tree" holds against state planted before the run, not against a concurrent same-uid writer (R8, row 509)

**Location:** `docs/reviews/override-log.md:494`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that GATE_TMP is created once per run and written into by later gate_git calls, so a concurrent writer can reach it. It does not establish R8's timing (~40 ms), which this pass did not re-measure.
**Legibility-target:** for-orchestrator-synthesis

The gate repository is made at run time and then used: `GATE_TMP="$(mktemp -d)"; trap 'rm -rf -- "$GATE_TMP"' EXIT` / `gate_repo || { echo "refuse state gate: ..."; exit 2; }` (`scripts/build-loop.sh:642-643`). Every merge call reads `$GATE_TMP/git` through `GATE_ENV+=(GIT_DIR="$GATE_TMP/git" GIT_OBJECT_DIRECTORY="$v")` (`:505`). No check runs between creation and use (paraphrased — no quote available because the claim covers absence of code: there is no re-check of `$GATE_TMP/git/config` between `gate_repo` and `gate_git`).

**Evidence:** `scripts/build-loop.sh:497-514`, `scripts/build-loop.sh:642-643`

---

## Claim 2: override row 497 note: "the first line is the verdict line; path and deny lines follow it, and the help says 'every verdict line ok'"

**Location:** `docs/reviews/override-log.md:497`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers check_line's output order and the exit test on the first line. It does not establish that a caller reading only the first line is safe from a deny line, which the verdict line carries as "K of N".
**Legibility-target:** for-orchestrator-synthesis

`if [[ "$nd" -eq 0 ]]; then echo "ok $a $sha $tree"; else echo "refuse $a: ..."; fi` / `printf '%s\n' "${rows[@]}"` (`scripts/build-loop.sh:626-627`). The exit test is `[[ "$out" == "ok "* ]] || fails=1` (`:647`). The help reads `# Exit: 0 every line printed (or help), and for --check every verdict line ok;` (`:137`).

**Evidence:** `scripts/build-loop.sh:626-627`, `scripts/build-loop.sh:646-649`, `scripts/build-loop.sh:137`

---

## Claim 3: override row 507 note: "gate_git refuses any stderr; the trees of main, the tip and each merge base must exist; the test fails with both guards removed"

**Location:** `docs/reviews/override-log.md:507`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both guards in code and the double mutant. It does not establish that either guard alone is pinned (row 514: neither is).
**Legibility-target:** for-orchestrator-synthesis

`[[ ! -s "$GATE_TMP/err" ]] || return 3` (`scripts/build-loop.sh:513`). `for b in "$MAIN_SHA" "$1" $bases; do gate_git cat-file -e "$b^{tree}" || return 2; done` (`:525`). Mutant `R6-both` removes both, and the R6 test fails (`not ok 1`, `$S/logs/mut-R6-both.txt`).

**Evidence:** `scripts/build-loop.sh:510-530`, `$S/logs/mut-R6-both.txt`

---

## Claim 4: override row 508 note: "--check refuses both main and master, or origin/HEAD naming a branch other than the one taken (`refuse state default-branch:`)"

**Location:** `docs/reviews/override-log.md:508`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers default_gate's two findings and their prefix under --check. It does not cover --status or --settings, which do not call default_gate (row 517).
**Legibility-target:** for-orchestrator-synthesis

`echo "refuse state default-branch: both main and master exist"` and `echo "refuse state default-branch: origin/HEAD names ${p#refs/remotes/}, but the default branch taken is $MAIN"` (`scripts/build-loop.sh:245,248`). It is called only as `if [[ "$MODE" == check ]]; then default_gate || exit 2; fi` (`:260`). The R7 test passes, and mutant `R7-off` fails it (`$S/logs/mut-R7-off.txt`).

**Evidence:** `scripts/build-loop.sh:241-251`, `scripts/build-loop.sh:260`, `test/scripts/build-loop-check.bats:1553-1570`, `$S/logs/mut-R7-off.txt`

---

## Claim 5: override row 509 notes: "Surface: `$GATE_TMP/git/config`, `git/info/`, `work/.gitattributes`, and from U2b1b `err` and `diff` (merge-base, cat-file, diff-tree and hash-object now run there too)… the surface also holds `git/refs/` and `git/HEAD`; the missing-blob batch-check adds one more gate_git call"

**Location:** `docs/reviews/override-log.md:509`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the files gate_repo and check_line create and the gate_git call sites. It does not establish that the list is the complete set of files a racing writer could plant (for example `git/objects/info/alternates` is outside GATE_TMP and belongs to row 492).
**Legibility-target:** for-orchestrator-synthesis

`mkdir "$GATE_TMP/git" "$GATE_TMP/git/refs" "$GATE_TMP/work"`, `printf 'ref: refs/heads/none\n' > "$GATE_TMP/git/HEAD"` and `... > "$GATE_TMP/git/config"` (`scripts/build-loop.sh:502-504`). `2>"$GATE_TMP/err"` (`:512`) and `> "$GATE_TMP/diff"` (`:599`). The gate_git calls are merge-base, cat-file -e, merge-tree (`:522-526`), diff-tree (`:599`), cat-file --batch-check (`:615`) and hash-object (`:542`).

**Evidence:** `scripts/build-loop.sh:497-514`, `scripts/build-loop.sh:522-526`, `scripts/build-loop.sh:542`, `scripts/build-loop.sh:599`, `scripts/build-loop.sh:615`

---

## Claim 6: override row 510 note: "the old test keeps its base gitlink; a new one merges a gitlink fast-forward that the real repository resolves cleanly; merge-tree in the real repository fails it"

**Location:** `docs/reviews/override-log.md:510`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both tests and the merge-tree mutant. It does not establish the old test's own discrimination under the same mutant, because the mutant was run only with the R9 filter.
**Legibility-target:** for-orchestrator-synthesis

The old test commits its base gitlink: `git add .gitmodules; git update-index --add --cacheinfo "160000,$s1,sub"; git commit -q -m sub1` (`test/scripts/build-loop-check.bats:1405`). The new test asserts that the real repository merges, with `git merge-tree --write-tree main feat/x > /dev/null || { echo "fixture: the real repository did not merge"; return 1; }` (`:1583`), and then expects a conflict from `--check`. Mutant `R9-realrepo` swaps `gate_git merge-tree` for `git merge-tree`, and R9 fails (`$S/logs/mut-R9-realrepo.txt`).

**Evidence:** `test/scripts/build-loop-check.bats:1400-1416`, `test/scripts/build-loop-check.bats:1572-1586`, `$S/logs/mut-R9-realrepo.txt`

---

## Claim 7: override row 511 note: "A15 test added; A16 diff-tree runs in the gate repository with --ignore-submodules=none (plan F8 corrected); A17 GIT_CONFIG_NOSYSTEM=1 …; A18 not changed (no new history walk but merge-base --all, one per brief); A19 help and comments fixed"

**Location:** `docs/reviews/override-log.md:511`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each item's presence in code, tests and the plan. It does not cover the A18 prices (3/50/306 ms), which were not re-measured, or whether the A15 test discriminates (Claim 54: it does not establish its name).
**Legibility-target:** for-orchestrator-synthesis

`if ! gate_git diff-tree -r --no-renames --raw -z --ignore-submodules=none "$MAIN_SHA" "$tree"` (`scripts/build-loop.sh:599`). `export ... GIT_CONFIG_NOSYSTEM=1 ...` (`:198`). `bases="$(gate_git merge-base --all "$MAIN_SHA" "$1")"` is called once per merge_result, which runs once per check_line (`:522`, `:591`). The A15 test exists at `test/scripts/build-loop-check.bats:1588`.

**Evidence:** `scripts/build-loop.sh:198`, `scripts/build-loop.sh:522`, `scripts/build-loop.sh:599`, `docs/working/plan-build-loop-handoff.md:123`, `test/scripts/build-loop-check.bats:1588`

---

## Claim 8: override row 512: "check_line is the whole per-brief pipeline and returns printed text only … a382a3f8 split check_line into collect, batch-check and judge phases; nrules takes seven positional arguments and trusts that $7 is lower($6)"

**Location:** `docs/reviews/override-log.md:512`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers check_line's structure and nrules' signature. It does not establish whether U3 needs exactly these values.
**Legibility-target:** for-orchestrator-synthesis

The three phases are the collect loop `while IFS= read -r -d '' meta && IFS= read -r -d '' p; do` (`scripts/build-loop.sh:602`), the batch-check (`:615-618`), and the judge loop `nrules "$a" "${oms[$i]}" "${nms[$i]}" "${nos[$i]}" "${ss[$i]}" "$p" "${lps[$i]}"` (`:623`). Output is by `echo` and `printf` only (paraphrased — no quote available because the claim covers absence of code: check_line sets no global result variable).

**Evidence:** `scripts/build-loop.sh:579-628`

---

## Claim 9: override row 513: "No test pins check_line's NUL-count completeness check (a mutant removing it passes)"

**Location:** `docs/reviews/override-log.md:513`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the nine U2b1b tests under the mutant. It does not establish that git's diff-tree never emits a partial record (the row's reason), which was not probed.
**Legibility-target:** for-orchestrator-synthesis

Mutant `NUL-off` replaces `if [[ "$(tr -cd '\000' < "$GATE_TMP/diff" | wc -c)" -ne $((2 * ${#ps[@]})) ]]` (`scripts/build-loop.sh:609`) with `if false`. All nine U2b1b tests pass (`$S/logs/mut-NUL-off.txt`).

**Evidence:** `scripts/build-loop.sh:609`, `$S/logs/mut-NUL-off.txt`

---

## Claim 10a: override row 514: "Each R6 guard … passes the R6 test alone … The test pins their union (the double mutant fails)"

**Location:** `docs/reviews/override-log.md:514`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three mutants on the R6 test. It does not establish the row's parenthetical about merge-tree (Claim 10b).
**Legibility-target:** for-orchestrator-synthesis

The `R6-stderr-only-removed` and `R6-trees-only-removed` mutants each pass the R6 test (`ok 1`), and `R6-both` fails it (`$S/logs/mut-R6-*.txt`).

**Evidence:** `$S/logs/mut-R6-stderr-only-removed.txt`, `$S/logs/mut-R6-trees-only-removed.txt`, `$S/logs/mut-R6-both.txt`

---

## Claim 10b: override row 514: "no case found where only stderr catches it (a missing subtree or blob is fatal, exit 128)"

**Location:** `docs/reviews/override-log.md:514`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers merge-tree's behaviour on a missing subtree or blob passed by id versus one it must read. It does not refute the row's disposition: in the passed-by-id cases neither R6 guard fires, and diff-tree or the batch-check refuses instead.
**Legibility-target:** for-orchestrator-synthesis

The mechanism is false for an object merge-tree passes by id. In p1 case A (a missing subtree only the tip changed), merge-tree printed `merge-tree rc=0 stdout=52c0b1f8… stderr=` (empty), and `--check` refused through diff-tree: `the paths the merge of feat/x changes could not be listed`. In case D (a missing blob passed by id), merge-tree also printed `rc=0` with empty stderr, and `--check` refused through the batch-check: `names a blob the object store lacks`. Only case B, where both sides changed the directory, gave `rc=128 stderr=fatal: unable to read tree …` (`$S/logs/p1.txt`). The branch's own correction paragraphs (a382a3f8, e02d056b) already say it is "fatal only when merge-tree must read it". The precise version: "a missing subtree or blob that merge-tree must read is fatal (exit 128); one passed by id is silent and is refused by diff-tree or the batch-check".

**Evidence:** `docs/reviews/override-log.md:514`, `scripts/build-loop.sh:599-618`, `$S/logs/p1.txt`

---

## Claim 11: override rows 515-517: own_blob's exit-status fix "has no test: reaching it needs the object deleted between own_blob's two reads"; own_blob repeats brief_fields' Status awk and drift "fails closed"; U2c's floor will run inside check_line's subshell, gate_git's code 3 folds into failure with one shared err file, and --status has no default-branch refusal

**Location:** `docs/reviews/override-log.md:515-517`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the missing test (mutant), the duplicated awk, the subshell, the shared err file and the --status path. It does not establish the race's reachability.
**Legibility-target:** for-orchestrator-synthesis

Mutant `ownblob-status-ignored` turns `ob="$(own_blob "$1")"` into `{ ob=…; || true; }`, and all nine U2b1b tests still pass (`$S/logs/mut-ownblob-status-ignored.txt`). own_blob's awk `!n && /^Status:/ { n = NR }` (`scripts/build-loop.sh:540`) repeats brief_fields' `match($0, /^(Status|...):/)` (`scripts/lib/dev-cycle-read.sh:368`). If the two drift, `[[ "$4" == "$ob" ]]` fails and the path is denied (`:559-560`). check_line runs in `out="$(check_line "$a")"` (`:646`), and every gate_git call writes `2>"$GATE_TMP/err"` (`:512`). default_gate is called only under `MODE == check` (`:260`).

**Evidence:** `scripts/build-loop.sh:260`, `scripts/build-loop.sh:512`, `scripts/build-loop.sh:536-543`, `scripts/build-loop.sh:559-560`, `scripts/build-loop.sh:646`, `$S/logs/mut-ownblob-status-ignored.txt`

---

## Claim 12: override row 518: "A16's two guards (diff-tree in the gate repository; --ignore-submodules=none) are pinned only together: either alone passes T12"

**Location:** `docs/reviews/override-log.md:518`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers T12 under three mutants. It does not establish that each guard alone closes A16 in every configuration (only T12's fixture was run).
**Legibility-target:** for-orchestrator-synthesis

`A16-realrepo-keepflag` passes T12, `A16-gate-noflag` passes T12, and `A16-realrepo-noflag` fails T12 (`$S/logs/mut-A16-*.txt`). p4 confirms that the flag alone shows a gitlink under `submodule.gl.ignore=all` in the real repository: `:000000 160000 … A	gl` (`$S/logs/p4.txt`).

**Evidence:** `$S/logs/mut-A16-realrepo-keepflag.txt`, `$S/logs/mut-A16-gate-noflag.txt`, `$S/logs/mut-A16-realrepo-noflag.txt`, `$S/logs/p4.txt`

---

## Claim 13: override row 519: "The K-of-N verdict names the merge by TIP while six sibling refusals name it by branch"

**Location:** `docs/reviews/override-log.md:519`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the six refusals about the merge itself under that reading (conflicts, computed, listed, read, names a blob, lower-cased). It does not count the four branch-state refusals (does not exist, moved, no commit, tip is not SHA), which also name the branch but are not about the merge.
**Legibility-target:** for-orchestrator-synthesis

The K-of-N line is `refuse $a: $nd of ${#ps[@]} changed paths refused in the merge of $sha (tree $tree)` (`scripts/build-loop.sh:626`). The siblings are `$br conflicts with the default branch` (`:594`), `the merge of $br could not be computed` (`:595`), `the paths the merge of $br changes could not be listed` (`:600`), `…could not be read` (`:604`, `:609`, same text), `the merge of $br names a blob the object store lacks` (`:617`) and `…could not be lower-cased` (`:620`).

**Evidence:** `scripts/build-loop.sh:584-626`

---

## Claim 14: override row 520: "--check is linear at about 0.25 ms per path (1,326 ms at 5,000, about 5 s at 20,000)"

**Location:** `docs/reviews/override-log.md:520`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the 5,000-path figure on this machine. It does not cover the 20,000-path extrapolation, truthrule's 0.07 ms per path or the batch-check's 0.1 s, none of which were measured (timing is machine- and load-dependent; load average was 1.0-1.7).
**Legibility-target:** for-orchestrator-synthesis

p3 ran e02d056b's `--check` on a 5,000-new-file branch twice: `run1: 1338 ms` and `run2: 1275 ms`, each with 5,001 lines (`$S/logs/p3-time.txt`).

**Evidence:** `$S/logs/p3-time.txt`

---

## Claim 15: plan F8: "plumbing `diff-tree` in the gate repository (no repo config, no checkout `.gitmodules`) with `--ignore-submodules=none`: `-c diff.ignoreSubmodules=none` does not override `submodule.<name>.ignore=all` (U2b1a2 A16, probed; U2b1b)"

**Location:** `docs/working/plan-build-loop-handoff.md:123`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's diff-tree with the -c form versus the flag, and the call site. It does not establish behaviour in other git versions.
**Legibility-target:** for-orchestrator-synthesis

In p4, with `submodule.gl.ignore=all` in .gitmodules and the repo config, plain diff-tree and `git -c diff.ignoreSubmodules=none diff-tree` both print nothing. `--ignore-submodules=none` prints `:000000 160000 … A	gl` (`$S/logs/p4.txt`). The call site is `gate_git diff-tree -r --no-renames --raw -z --ignore-submodules=none` (`scripts/build-loop.sh:599`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:123`, `scripts/build-loop.sh:599`, `$S/logs/p4.txt`

---

## Claim 16: plan F12: "N-denied via truthrule's cycle and settings words (the lib's `writable()` plus `docs/dev-cycle.md`), and, N-only, anything under `docs/working/briefs/` or `docs/working/cycles/`; `docs/constraints.md` by its user word (F54) (T14; U2b1b)"

**Location:** `docs/working/plan-build-loop-handoff.md:127`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers nrules' mapping. It does not establish floor's (U2c) treatment.
**Legibility-target:** for-orchestrator-synthesis

`cycle|settings) DENY="one of the dev cycle's own files" ;;`, `user) DENY="the user's constraints doc, …" ;;` and `*) [[ ! "$7" =~ ^docs/working/(briefs|cycles)/ ]] || DENY="one of the dev cycle's own files" ;;` (`scripts/build-loop.sh:567-569`).

**Evidence:** `scripts/build-loop.sh:565-570`, `scripts/lib/dev-cycle-read.sh:1094-1096`

---

## Claim 17: plan `--state` line: "U2b1a's `state_gate`, then U2b1b's `default_gate` once main is resolved: both main and master, or origin/HEAD naming another branch than the one taken"

**Location:** `docs/working/plan-build-loop-handoff.md:207`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers default_gate's checks and when it runs. It does not establish `--state`, which is not built yet (U3b).
**Legibility-target:** for-orchestrator-synthesis

`if [[ "$MODE" == check ]]; then state_gate || exit 2; fi` / `resolve_main || true` / `main_by_name || …` / `if [[ "$MODE" == check ]]; then default_gate || exit 2; fi` (`scripts/build-loop.sh:257-260`).

**Evidence:** `scripts/build-loop.sh:241-260`

---

## Claim 18: plan `--check` line: "U2b1b (built): the verdict line comes first (`ok BRIEF TIP TREE`, or `refuse BRIEF: K of N changed paths refused`), then `path BRIEF S PATH` or `deny BRIEF S PATH: WHY` per changed path; exit 0 only when every verdict line is ok"

**Location:** `docs/working/plan-build-loop-handoff.md:212`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers order, line forms and the exit rule. It does not cover the refusal text in full: the plan quotes only cc9b69d3's prefix, not a382a3f8's TIP and TREE suffix.
**Legibility-target:** for-orchestrator-synthesis

The code prints `refuse $a: $nd of ${#ps[@]} changed paths refused in the merge of $sha (tree $tree)` (`scripts/build-loop.sh:626`), and the help documents the full form at `:110-111`. The plan line gives only "K of N changed paths refused". The precise version: "`refuse BRIEF: K of N changed paths refused in the merge of TIP (tree TREE)`". e02d056b's message says the plan's F12 and --state lines were brought to match the code. This line was not changed in that commit.

**Evidence:** `docs/working/plan-build-loop-handoff.md:212`, `scripts/build-loop.sh:110-111`, `scripts/build-loop.sh:626`

---

## Claim 19a: plan step 5's U2b1b note: "Built 2026-10-08 (`feat/build-loop-u2b1b`, cc9b69d3, 317 lines): the mode rule is an N rule (both policies), so floor item 5 is already enforced before U2c; the own brief also keeps its mode; plus U2b1a2's carried R6, R7, R9, A15, A17 and A19 (override rows 497, 507-511)"

**Location:** `docs/working/plan-build-loop-handoff.md:283`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line count at cc9b69d3 (added plus deleted lines in `scripts` and `test`), the mode rule and the mode-kept rule. It does not cover the R8 sentence (Claim 19b).
**Legibility-target:** for-orchestrator-synthesis

`git diff --numstat main cc9b69d3 -- scripts test` sums to `add 282 del 35 sum 317` (run in this session). The mode rule is `elif [[ ! "$2 $3" =~ ^(000000|100644|100755)\ (000000|100644|100755)$ ]]` (`scripts/build-loop.sh:557`), applied with no policy test, and the brief's own file needs `"$5" == M && "$2" == "$3"` (`:559`).

**Evidence:** `scripts/build-loop.sh:553-572`

---

## Claim 19b: plan step 5's U2b1b note: "R8 is proposed as a Q-103 residual for its review to decide."

**Location:** `docs/working/plan-build-loop-handoff.md:283`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the note against row 509 and step 13. It does not affect any code.
**Legibility-target:** for-orchestrator-synthesis

Row 509 now reads `**Decided at U2b1b iteration 1 (security, architecture concur): Q-103 residual.**` (`docs/reviews/override-log.md:509`). Step 13 lists R8 for U5: `U2b1a2's R8 (a same-uid writer racing the gate's GATE_TMP: …; override row 509)` (`docs/working/plan-build-loop-handoff.md:305`). Step 5 still says "proposed". It was true at 809df345.

**Evidence:** `docs/working/plan-build-loop-handoff.md:283`, `docs/working/plan-build-loop-handoff.md:305`, `docs/reviews/override-log.md:509`

---

## Claim 20: plan step 13: "U2b1a2's R8 (a same-uid writer racing the gate's GATE_TMP: its config, info/, work/.gitattributes, err and diff; override row 509)"

**Location:** `docs/working/plan-build-loop-handoff.md:305`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the surface list against row 509 and gate_repo. It does not establish completeness beyond row 509.
**Legibility-target:** for-orchestrator-synthesis

Row 509's i2 addition says `the surface also holds `git/refs/` and `git/HEAD`` (`docs/reviews/override-log.md:509`), and gate_repo creates both (`mkdir … "$GATE_TMP/git/refs"`, `> "$GATE_TMP/git/HEAD"`, `scripts/build-loop.sh:502-503`). Step 13's list omits them.

**Evidence:** `docs/working/plan-build-loop-handoff.md:305`, `docs/reviews/override-log.md:509`, `scripts/build-loop.sh:502-503`

---

## Claim 21: --check help, state gate: "a git config key (common config or config.worktree, includes not followed) for a filter, include, config hook, merge or diff setting, core.fsmonitor, core.attributesFile, core.hooksPath, gpg.*, log.showSignature, extensions.partialClone or remote.*.promisor (a partial clone); an info/attributes, info/grafts or shallow that is not absent or an empty file; a replace ref; an origin/HEAD naming any branch but origin/main or origin/master; then (once main is found) both main and master present, or origin/HEAD naming another branch than the one taken. Each finding prints "refuse state WHAT: WHY" and exits 2 before any brief is read"

**Location:** `scripts/build-loop.sh:80-91`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers STATE_KEYS_RE, the file checks, the replace-ref and origin/HEAD checks, default_gate, the line format and exit 2 before check_line. It does not cover state_gate's early `return 1` cases (an unreadable path or a missing config), which print one line and stop at the first finding rather than listing every one.
**Legibility-target:** for-orchestrator-synthesis

`STATE_KEYS_RE='^(filter\.|include|hook\.|merge\.|diff\.|core\.fsmonitor|core\.attributesfile|core\.hookspath|gpg\.|log\.showsignature|extensions\.partialclone$|remote\..*\.promisor$)'` (`scripts/build-loop.sh:212`) is read with `git config --file "$p" --no-includes --name-only --get-regexp` over `config config.worktree` (`:215-218`). The file test is `[[ -s "$p" || -L "$p" || ( -e "$p" && ! -f "$p" ) ]]` (`:226`). The state-gate tests in the suite pass (`$S/logs/bats.txt`), including the multi-finding test that expects `refuse state shallow: present and not an empty file` (`test/scripts/build-loop-check.bats:1339-1343`).

**Evidence:** `scripts/build-loop.sh:212-251`, `scripts/build-loop.sh:257-260`, `test/scripts/build-loop-check.bats:1339-1343`, `$S/logs/bats.txt`

---

## Claim 22: --check help: "exits 2 before any brief is read ("refuse state gate: WHY" when the gate's own merge repository cannot be set up)"

**Location:** `scripts/build-loop.sh:90-92`
**Type:** Behavioral / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers when the gate-repository refusal is printed and what happens when its temporary directory cannot be made. It does not affect the state-gate findings themselves (Claim 21).
**Legibility-target:** for-orchestrator-synthesis

Read beside "before any brief is read", the parenthetical suggests the gate-repository refusal also comes before any brief is read. It does not. It is printed after `read_settings` and `open_shared`: `open_shared  # once, in this shell` / `GATE_TMP="$(mktemp -d)"; trap …` / `gate_repo || { echo "refuse state gate: its merge repository could not be set up"; exit 2; }` (`scripts/build-loop.sh:641-643`). open_shared reads each open brief on main through `brief_fields "$f"` (`scripts/lib/dev-cycle-read.sh:478`). It still comes before any verdict line. Also, if `mktemp -d` itself fails, `set -e` exits 1 with no "refuse state gate" line. p1 case G (`TMPDIR=/nonexistent-dir-xyz`) printed `mktemp: failed to create directory …` and `check rc=1` (`$S/logs/p1.txt`). The precise version: "before any verdict line ('refuse state gate: WHY' when the gate's merge repository cannot be set up; a failed mktemp exits 1)".

**Evidence:** `scripts/build-loop.sh:639-644`, `scripts/lib/dev-cycle-read.sh:469-484`, `$S/logs/p1.txt`

---

## Claim 23: --check help, ok line: "--status reads the brief as open and its branch at TIP, at least one commit ahead of main (and TIP equals SHA when --expect is given …); TREE is the merge of TIP into main as merge-tree writes it, run where no repo config or checkout attributes are read; and no changed path is denied."

**Location:** `scripts/build-loop.sh:94-100`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ok conditions and the gate repository's config and attributes isolation. It does not cover config the caller supplies through its own environment (`GIT_CONFIG_COUNT` or `GIT_CONFIG_PARAMETERS` survive GATE_ENV by design, `:185-186`), which is not repo config.
**Legibility-target:** for-orchestrator-synthesis

`if [[ "$nd" -eq 0 ]]; then echo "ok $a $sha $tree"` (`scripts/build-loop.sh:626`), and an empty diff also prints ok (`:610`). GATE_ENV unsets every local env var except `GIT_CONFIG*` and `GIT_NO_REPLACE_OBJECTS` (`:500`). It points GIT_DIR at a fresh config that holds only `repositoryformatversion` and `objectformat` (`:504-505`) and runs in an empty `$GATE_TMP/work` (`:512`). The suite's ok-path tests pass with path lines appended (`test/scripts/build-loop-check.bats:1260-1261`).

**Evidence:** `scripts/build-loop.sh:497-514`, `scripts/build-loop.sh:579-628`, `$S/logs/bats.txt`

---

## Claim 24: --check help, refuse line: "… the merge (or its changed paths) could not be computed: git failed, or warned on stderr (a missing tree object), or the tree of main, TIP or a merge base is missing. Or "the merge of BRANCH names a blob the object store lacks": a regular file the merge adds or changes names an object that is absent or not a blob. Or "K of N changed paths refused in the merge of TIP (tree TREE)", when deny lines follow."

**Location:** `scripts/build-loop.sh:101-111`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each refusal case against probes and tests. It does not establish the exact WHY text of the changed-paths failures, which reads "could not be listed/read/lower-cased" rather than "computed". The help groups them by meaning, not by text.
**Legibility-target:** for-orchestrator-synthesis

The p1 cases:
- C, a missing top-level merge-base tree: merge-tree gave rc=0 with `error: Could not read …` on stderr, and `--check` printed `the merge of feat/x could not be computed`.
- B, a missing subtree merge-tree must read: rc=128, and `--check` printed `could not be computed`.
- D, a missing blob: `names a blob the object store lacks`.
- F, a tree id at a 100644 entry, built with `hash-object -t tree --literally`: `names a blob the object store lacks`.

All are in `$S/logs/p1.txt`. Code: `echo "refuse $a: the merge of $br names a blob the object store lacks"` (`scripts/build-loop.sh:617`) and the K-of-N line (`:626`). T14 asserts the K-of-N text through `nref` (`test/scripts/build-loop-check.bats:1449`).

**Evidence:** `scripts/build-loop.sh:516-530`, `scripts/build-loop.sh:591-626`, `$S/logs/p1.txt`, `test/scripts/build-loop-check.bats:1449`

---

## Claim 25: --check help, path lines: "After an ok line or a K of N refusal, one line per path TREE changes against main (diff-tree -r --no-renames, so a rename is its D and A sides), in diff-tree's order; S is its status letter (A, M, D or T) and PATH is "?" unless every character is one pathform allows"

**Location:** `scripts/build-loop.sh:114-120`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the format, order, rename split and display rule. It does not establish anything for statuses other than A/M/D/T, which refuse the brief as "could not be read" (`:603-604`).
**Legibility-target:** for-orchestrator-synthesis

`p="${ps[$i]}"; shown="?"; [[ ! "$p" =~ ^[$NAMECHARS]+$ ]] || shown="$p"` (`scripts/build-loop.sh:622`). The display rule tests NAMECHARS only (pathform's character set), so `-x.md` and `.github/w.yml` print by name although pathform refuses them. T13 asserts exactly that (`has "deny $B A -x.md: $NFORM"`, `test/scripts/build-loop-check.bats:1529`). T11 asserts the D and A sides of a rename, and T14 asserts diff-tree order (`lines[1]` is `Docs/Roadmap.md`). Both pass.

**Evidence:** `scripts/build-loop.sh:599-627`, `test/scripts/build-loop-check.bats:1453-1531`, `$S/logs/bats.txt`

---

## Claim 26: --check help, N rules: "a path pathform refuses (a part starting .git, any case: .github/); a mode other than 100644 or 100755 on either side (a symlink or gitlink); the brief's own file, unless only its first Status: line outside a fence changes, from open to done (mode kept); and, compared lower-cased, the dev cycle's own files (the roadmap, the questions files, the idea log, docs/dev-cycle.md, anything under docs/working/briefs/ or docs/working/cycles/) and docs/constraints.md."

**Location:** `scripts/build-loop.sh:121-129`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each rule against nrules and T11-T15. Two things are outside it. "On either side" is read as either side that exists: an absent side (000000) is allowed. Cycle files are recognised by writable()'s exact names; a non-brief name directly under docs/working/ (for example `docs/working/notes.md`) is not a cycle file.
**Legibility-target:** for-orchestrator-synthesis

pathform refuses `"$c" != [.][gG][iI][tT]*` in any case (`scripts/lib/dev-cycle-read.sh:191`). The mode regex admits `000000|100644|100755` on each side (`scripts/build-loop.sh:557`). The own-brief branch compares the new blob to `own_blob` (`:559-560`), which rewrites only line N's `^Status: open(\r?)$` (`:542`). The suite passes T12 (five mode denies), T13, T14 (15 of 16 denied, including `Docs/Roadmap.md` and `docs/CONSTRAINTS.md`) and T15 (fenced line, dropped, extra line, chmod, trailing blank and move all denied; CRLF kept) (`$S/logs/bats.txt`).

**Evidence:** `scripts/build-loop.sh:536-572`, `scripts/lib/dev-cycle-read.sh:184-207`, `test/scripts/build-loop-check.bats:1453-1531`, `$S/logs/bats.txt`

---

## Claim 27: Exit line: "Exit: 0 every line printed (or help), and for --check every verdict line ok; 2 any --check verdict line or the state gate not ok; 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no default branch found by name."

**Location:** `scripts/build-loop.sh:137-139`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit paths the script codes explicitly. It does not enumerate `set -e` exits.
**Legibility-target:** for-orchestrator-synthesis

The named paths match: `[[ "$fails" -eq 0 ]] || exit 2` (`scripts/build-loop.sh:649`), the state and default gates `exit 2` (`:257`, `:260`), and `exit 1` for usage, not a repo, perl, the lib, or no default branch (`:143`, `:149`, `:154`, `:252`, `:259`). One --check path is missing from the list. A failed `GATE_TMP="$(mktemp -d)"` (`:642`) exits 1 with no line, as p1 case G showed (`check rc=1`, `$S/logs/p1.txt`), although the help files gate-repository failures under exit 2 ("refuse state gate").

**Evidence:** `scripts/build-loop.sh:137-139`, `scripts/build-loop.sh:642-649`, `$S/logs/p1.txt`

---

## Claim 28: "GIT_CONFIG_NOSYSTEM: the system config is no more the gate's than the user's (merge.directoryRenames there flipped a conflict: A17)."

**Location:** `scripts/build-loop.sh:196-198`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that a system-level merge.directoryRenames changes merge-tree's exit code, and the export. It does not establish which other system keys matter.
**Legibility-target:** for-orchestrator-synthesis

p4, a directory-rename merge with `GIT_CONFIG_SYSTEM` pointing at a file: `system merge.directoryRenames=conflict: merge-tree rc=1` and `system merge.directoryRenames=true: merge-tree rc=0` (`$S/logs/p4.txt`). The export is `GIT_CONFIG_NOSYSTEM=1` (`scripts/build-loop.sh:198`), and mutant `A17-off` fails the shim test (`$S/logs/mut-A17-off.txt`).

**Evidence:** `scripts/build-loop.sh:196-198`, `$S/logs/p4.txt`, `$S/logs/mut-A17-off.txt`

---

## Claim 29: state_gate comment: "Keys, in the common config and this worktree's config.worktree: filter drivers, every merge.* and diff.* key (drivers run commands), config hooks, includes, core.fsmonitor, core.attributesFile, core.hooksPath, gpg and log.showSignature …, and a partial clone … Files: an info/attributes, info/grafts or shallow that is not absent or an empty regular file …"

**Location:** `scripts/build-loop.sh:199-211`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the comment against STATE_KEYS_RE and the file test. It does not establish that the key list is exhaustive for every command-running key (a design question).
**Legibility-target:** for-orchestrator-synthesis

`merge\.|diff\.` match every key in those sections, `filter\.` every filter key, `hook\.` config hooks, and `include` both include and includeIf (`scripts/build-loop.sh:212`). The file test accepts only an absent path or an empty regular file (`:226`).

**Evidence:** `scripts/build-loop.sh:212-235`

---

## Claim 30: default_gate comment: "the default branch counts only when no other name could claim it. A loop can create a local master beside main (or main beside master) and point origin/HEAD at it, and resolve_main would follow (R7). Prints one line per finding, as state_gate does; returns 1 on any."

**Location:** `scripts/build-loop.sh:236-240`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both findings printed together and resolve_main's order. Two things are outside it. For "main beside master", resolve_main takes main even without origin/HEAD, because main comes before master in its candidate list. The comment's "and point origin/HEAD at it" is sufficient but not necessary there.
**Legibility-target:** for-orchestrator-synthesis

resolve_main tries `origin_head` first, then `candidates+=(main master)` (`scripts/lib/dev-cycle-read.sh:493-495`). default_gate sets `bad=1` per finding and returns it (`scripts/build-loop.sh:242-250`). The R7 test's third block expects both lines together and passes (`test/scripts/build-loop-check.bats:1562-1565`, `$S/logs/bats.txt`).

**Evidence:** `scripts/build-loop.sh:241-251`, `scripts/lib/dev-cycle-read.sh:490-512`, `test/scripts/build-loop-check.bats:1553-1570`

---

## Claim 31: gate_git: "git in the gate repository, stdout passed through; returns git's status, or 3 when git wrote anything to stderr (a missing object can warn and still exit 0: R6)."

**Location:** `scripts/build-loop.sh:507-509`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the function and R6's warn-and-exit-0 case. It does not cover concurrent writers to the shared err file (R8 residual).
**Legibility-target:** for-orchestrator-synthesis

`(cd "$GATE_TMP/work" && "${GATE_ENV[@]}" git "$@") 2>"$GATE_TMP/err" || rc=$?` / `[[ ! -s "$GATE_TMP/err" ]] || return 3` / `return "$rc"` (`scripts/build-loop.sh:512-514`). In p1 case C, merge-tree exited 0 with `error: Could not read …` on stderr (`$S/logs/p1.txt`).

**Evidence:** `scripts/build-loop.sh:510-515`, `$S/logs/p1.txt`

---

## Claim 32: merge_result: "prints the result tree; returns 1 on a conflict (a gitlink both sides moved is one, since no submodule repository is reachable), 2 when git failed or warned, or the tree of main, the tip or a merge base is missing (R6)."

**Location:** `scripts/build-loop.sh:516-519`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each return code against probes and the R9 test. It does not cover a missing blob or subtree passed by id: merge_result returns 0 for those, and check_line refuses them later (Claim 39).
**Legibility-target:** for-orchestrator-synthesis

`[[ "$rc" -le 1 ]] || return 2` after merge-base, the tree loop's `|| return 2`, then `[[ "$rc" -le 1 && "${out%%$'\n'*}" =~ ^(…)$ ]] || return 2` and `[[ "$rc" -eq 0 ]] || return 1` (`scripts/build-loop.sh:523-528`). In p1 case E (missing tree plus conflict), merge-tree gave rc=1 with stderr, so gate_git returns 3 and merge_result returns 2. In case A (missing subtree passed by id), merge-tree gave rc=0 with no stderr, so merge_result returns 0 (`$S/logs/p1.txt`). The R9 test (gitlink fast-forward, a conflict in the gate repository) passes.

**Evidence:** `scripts/build-loop.sh:520-530`, `test/scripts/build-loop-check.bats:1572-1586`, `$S/logs/p1.txt`

---

## Claim 33: own_blob: "main's copy with its first Status: line outside a fence, the one brief_fields reads (status_line has read it as "Status: open"), reading "Status: done", every other byte kept (a CR at its end too). Returns non-zero when a read fails; the caller checks it"

**Location:** `scripts/build-loop.sh:531-535`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers line selection, the CR case, pipefail and the caller's check. It does not establish a test of the failed-read path (none exists, row 515, Claim 11).
**Legibility-target:** for-orchestrator-synthesis

`n="$(… awk "$FENCE_AWK"'{ sub(/\r$/, "") } fence($0) { next } !n && /^Status:/ { n = NR } END { print n + 0 }')" || return 1` and `N="$n" perl -pe 's/^Status: open(\r?)$/Status: done$1/ if $. == $ENV{N}' | gate_git hash-object --no-filters --stdin` (`scripts/build-loop.sh:540-542`). The script runs under `set -euo pipefail` (`:141`). The caller writes `ob="$(own_blob "$1")" && [[ "$4" == "$ob" ]]` (`:559`). T15's fenced-line and CRLF cases pass.

**Evidence:** `scripts/build-loop.sh:536-543`, `scripts/build-loop.sh:559-560`, `test/scripts/build-loop-check.bats:1475-1496`

---

## Claim 34: nrules comment: "diff-tree's old and new modes $2 $3, new blob $4, status $5, path $6 and its lower-cased spelling $7 … The brief's own file is matched exactly; the cycle's files (truthrule's cycle and settings words: writable() and docs/dev-cycle.md, plus anything under docs/working/briefs/ or docs/working/cycles/) and the constraints doc (its user word) compare lower-cased"

**Location:** `scripts/build-loop.sh:544-551`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the argument order at the single call site and the comparisons. It does not cover other callers (there are none: nrules is called only at `:623`).
**Legibility-target:** for-orchestrator-synthesis

The call is `nrules "$a" "${oms[$i]}" "${nms[$i]}" "${nos[$i]}" "${ss[$i]}" "$p" "${lps[$i]}"` (`scripts/build-loop.sh:623`), the own-file test is `[[ "$6" == "$1" ]]` (`:558`), and `truthrule "$7"` runs on the lower-cased path (`:565`).

**Evidence:** `scripts/build-loop.sh:553-572`, `scripts/build-loop.sh:623`

---

## Claim 35: nrules invariant: "$7 is lower-cased, so the case word cannot fire; instr and dot, tested before cycle, match no cycle file, docs/dev-cycle.md or docs/constraints.md today (T14 fails if one ever does: truthrule names this third consumer)."

**Location:** `scripts/build-loop.sh:562-564`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the word order, the names writable() and the two settings files cover, and T14 failing when instr shadows docs/roadmap.md. "T14 fails" holds for the exact names T14 writes (roadmap, questions, questions-archive, idea-log, dev-cycle, constraints). For a brief or cycle-log path, an instr or dot match would not be caught by T14, because the briefs/cycles subtree fallback still denies it; that is not a fail-open.
**Legibility-target:** for-orchestrator-synthesis

truthrule's order is `case`, `isstart`, dot, `writable`, `docs/dev-cycle.md`, `docs/constraints.md` (`scripts/lib/dev-cycle-read.sh:1091-1096`). lower_all uses `tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz'` (`:857`), which matches the case test's set. No covered name has a `claude|agents?|gemini|skill` basename, a `.claude/` part or a dot-prefixed part: writable's patterns are fixed names under `docs/`, and brief slugs are `[abcdefghijklmnopqrstuvwxyz0123456789-]+` (`:200-206`). Mutant `T14-instr-shadows` (isstart also matching docs/roadmap.md) fails T14 (`$S/logs/mut-T14-instr-shadows.txt`).

**Evidence:** `scripts/build-loop.sh:562-570`, `scripts/lib/dev-cycle-read.sh:200-206`, `scripts/lib/dev-cycle-read.sh:1089-1099`, `$S/logs/mut-T14-instr-shadows.txt`

---

## Claim 36: check_line header: ""ok BRIEF TIP TREE" or "refuse BRIEF: K of N changed paths refused in the merge of TIP (tree TREE)", then a "path BRIEF S PATH" or "deny BRIEF S PATH: WHY" line per path …; or one skip or refuse line"

**Location:** `scripts/build-loop.sh:573-578`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers check_line's outputs. It does not cover the ok case with no changed paths, which prints the verdict alone (`:610`) and is consistent with "per path".
**Legibility-target:** for-orchestrator-synthesis

`rows+=("deny $a ${ss[$i]} $shown: $DENY")` / `rows+=("path $a ${ss[$i]} $shown")` (`scripts/build-loop.sh:624`). Every other exit is a single `echo …; return` (`:582-620`).

**Evidence:** `scripts/build-loop.sh:579-628`

---

## Claim 37: "In the gate repository, so no repo config or checkout .gitmodules hides a moved gitlink (A16); --no-renames, so a rename is judged as both its sides (F6)."

**Location:** `scripts/build-loop.sh:597-598`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the gate repository plus the flag shows the gitlink, and the rename split. It does not establish that the gate repository alone is needed (the flag alone suffices, Claim 12). The comment does not claim it is.
**Legibility-target:** for-orchestrator-synthesis

`gate_git diff-tree -r --no-renames --raw -z --ignore-submodules=none "$MAIN_SHA" "$tree"` (`scripts/build-loop.sh:599`). T12 under `ignore = all` and T11 pass, and mutant `A16-realrepo-noflag` fails T12 (`$S/logs/mut-A16-realrepo-noflag.txt`).

**Evidence:** `scripts/build-loop.sh:597-601`, `$S/logs/mut-A16-realrepo-noflag.txt`

---

## Claim 38: "Every record read whole: two NUL-ended fields each."

**Location:** `scripts/build-loop.sh:608-609`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count check's logic. It does not establish a test (row 513, Claim 9).
**Legibility-target:** for-orchestrator-synthesis

A trailing field without a NUL ends the `read -r -d ''` loop (`scripts/build-loop.sh:602`) without being added to `ps`. The total NUL count then differs from `$((2 * ${#ps[@]}))` (`:609`).

**Evidence:** `scripts/build-loop.sh:602-609`

---

## Claim 39: "merge-tree passes a side's unchanged blob by id without reading it, so a blob the store lacks would land unseen: every regular file the merge adds or changes must name a blob present in the store (a missing subtree already failed diff-tree)."

**Location:** `scripts/build-loop.sh:611-614`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the passed-by-id blob case, the wrong-type case, the subtree case and the id selection (new mode 100644 or 100755). It does not cover an old-side blob of a deleted or modified path, which is never landed.
**Legibility-target:** for-orchestrator-synthesis

The ids are collected as `[[ "${nms[-1]}" != 100644 && "${nms[-1]}" != 100755 ]] || ids+=("${nos[-1]}")` (`scripts/build-loop.sh:606`) and checked with `gate_git cat-file --batch-check='%(objecttype)'` plus `grep -cx blob` (`:615-616`). p1 results (`$S/logs/p1.txt`):
- Case D: merge-tree rc=0 with no stderr, and `--check` printed `names a blob the object store lacks`.
- Case F: a wrong-type entry gave the same refusal.
- Case A: a missing subtree gave `the paths the merge of feat/x changes could not be listed`.

Mutant `F2-nobatch` fails the R6 test (`$S/logs/mut-F2-nobatch.txt`).

**Evidence:** `scripts/build-loop.sh:599-618`, `$S/logs/p1.txt`, `$S/logs/mut-F2-nobatch.txt`

---

## Claim 40: "One lower-casing pass for every path (a tr per path cost 1 to 2.5 ms each)."

**Location:** `scripts/build-loop.sh:619`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers one lower_all call per brief and the per-tr cost on this machine (low end of the range). It does not establish the 2.5 ms upper figure, which depends on machine and load.
**Legibility-target:** for-orchestrator-synthesis

`nul_list lps lower_all "${ps[@]}"` is one call (`scripts/build-loop.sh:620`). p3 measured `1000 lower in $(): 951 ms` (about 0.95 ms each). The 5,000-path run went from 8,879-8,977 ms at cc9b69d3 (a `lower` per path) to 1,275-1,338 ms at e02d056b, about 1.5 ms saved per path (`$S/logs/p3-time.txt`).

**Evidence:** `scripts/build-loop.sh:619-620`, `scripts/lib/dev-cycle-read.sh:852-857`, `$S/logs/p3-time.txt`

---

## Claim 41: lib contract item 5: "Ask floor about each changed path, in this shell, before main_entry … Floor item 5 (symlinks, gitlinks) and the brief's own Status change are the caller's rules; build-loop.sh's N rules apply them, and pathform, under both policies before floor runs, so a path pathform refuses (.github/x.yml) is denied as a path form and floor's dotfile reason serves the dot paths pathform accepts (.envrc)."

**Location:** `scripts/lib/dev-cycle-read.sh:59-65`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers nrules' rules and the pathform/dot split. It does not establish floor's call site, which does not exist yet (U2c), so "before floor runs" describes the planned order.
**Legibility-target:** for-orchestrator-synthesis

nrules checks pathform first (`if ! pathform "$6"; then DENY="not an allowed path form …"`, `scripts/build-loop.sh:556`) with no policy test. pathform rejects only `[.][gG][iI][tT]*` parts among dot parts (`scripts/lib/dev-cycle-read.sh:191`), so `.envrc` passes it. truthrule's `[[ "/$1" == */.* ]]` gives `dot` (`:1093`), which nrules' `*)` branch does not deny (`scripts/build-loop.sh:569`). floor maps `dot` to "a dotfile or a path under a dot-directory" (`scripts/lib/dev-cycle-read.sh:1146`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:59-65`, `scripts/lib/dev-cycle-read.sh:184-193`, `scripts/lib/dev-cycle-read.sh:1138-1160`, `scripts/build-loop.sh:553-572`

---

## Claim 42: truthrule comment: "build-loop.sh's N rules read its cycle, settings and user words too, so a word tested before them must never match a file those words cover"

**Location:** `scripts/lib/dev-cycle-read.sh:1076-1079`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the consumer statement and today's order (Claim 35). It does not establish future edits.
**Legibility-target:** for-orchestrator-synthesis

nrules reads `cycle|settings` and `user` from `TRUTH_WHY` (`scripts/build-loop.sh:566-568`). The words tested before them are `case`, `instr` and `dot` (`scripts/lib/dev-cycle-read.sh:1091-1093`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1076-1099`, `scripts/build-loop.sh:565-570`

---

## Claim 43: test name "every git call --check makes carries harden's config pairs …, no global or system config and no transport (T26, A4, U2b1a i1, i2, A17)"

**Location:** `test/scripts/build-loop-check.bats:1375`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that every logged call sees `GIT_CONFIG_NOSYSTEM=1` once the test unsets the fixture's copy. It does not plant a system config file (p4 covers that effect, Claim 28).
**Legibility-target:** for-orchestrator-synthesis

The shim logs `S=$GIT_CONFIG_NOSYSTEM`, the test runs `unset GIT_CONFIG_NOSYSTEM`, and it requires `S=1` on every line (`test/scripts/build-loop-check.bats:1379-1387`). Mutant `A17-off` fails it (`$S/logs/mut-A17-off.txt`).

**Evidence:** `test/scripts/build-loop-check.bats:1375-1389`, `$S/logs/mut-A17-off.txt`

---

## Claim 44: submodule test's base gitlink and comment "Not commit_all: add -A would drop the gitlink, which has no directory (R9)."

**Location:** `test/scripts/build-loop-check.bats:1404-1405`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that the test commits a base gitlink and passes. The add -A mechanism was not probed separately; it is consistent with git staging a deletion for an index entry that has no working-tree path.
**Legibility-target:** for-orchestrator-synthesis

`git add .gitmodules; git update-index --add --cacheinfo "160000,$s1,sub"; git commit -q -m sub1` (`test/scripts/build-loop-check.bats:1405`). Then feat/x merges main before moving the gitlink (`:1406`), so the base holds `s1`. The test passes (`$S/logs/bats.txt`).

**Evidence:** `test/scripts/build-loop-check.bats:1400-1416`, `$S/logs/bats.txt`

---

## Claim 45: T14 name "--check lists every changed path and refuses the dev cycle's own files, other briefs and the constraints doc in any case; other paths pass (T14, F2, F12, F54, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1453`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 16 named paths (four mixed-case spellings among them), the other open brief, a new brief, a closed/ path, `docs/ok.md` passing, the line count, diff-tree order, and an empty merge printing ok alone. It does not test an upper-case brief path, so "in any case" rests on the roadmap, dev-cycle, questions and constraints spellings.
**Legibility-target:** for-orchestrator-synthesis

The test expects `[ "${lines[0]}" = "$(nref 15 16)" ] && [ "${#lines[@]}" -eq 17 ]`, then `has "path $B A docs/ok.md"`, then the empty-merge block `[ "${#lines[@]}" -eq 1 ]` (`test/scripts/build-loop-check.bats:1461-1472`). It passes. Mutant `T14-instr-shadows` fails it.

**Evidence:** `test/scripts/build-loop-check.bats:1453-1473`, `$S/logs/bats.txt`, `$S/logs/mut-T14-instr-shadows.txt`

---

## Claim 46: T15 name "--check: the brief's own file may change only its first Status: line outside a fence, open to done (T15, F13, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1475`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the allowed change and five denied variants: fenced line, dropped, extra line, chmod and trailing blank. It also covers a move to closed/ and the CRLF keep. It does not test a second unfenced Status line changing instead of the first, though line 4 (fenced) stands in for "not the first outside a fence".
**Legibility-target:** for-orchestrator-synthesis

The loop over `'sed -i "4s/open/done/" "$B"' 'sed -i "6s/open/dropped/" "$B"' … chmod +x … echo "" >> "$B"` expects `nref 1 1` and `deny $B M $B: $NBRIEF` (`test/scripts/build-loop-check.bats:1482-1487`). The CRLF block expects `path $c M $c` (`:1491-1495`). It passes.

**Evidence:** `test/scripts/build-loop-check.bats:1475-1496`, `$S/logs/bats.txt`

---

## Claim 47: T11 name "--check: a rename is its two sides, so moving a cycle file out refuses its old path (T11, F6, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1498`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one rename of the roadmap. It does not cover a rename into a cycle path, which the same per-side rule denies by its A side.
**Legibility-target:** for-orchestrator-synthesis

`has "deny $B D docs/roadmap.md: $NOWN"; has "path $B A docs/x.md"` (`test/scripts/build-loop-check.bats:1504`). It passes.

**Evidence:** `test/scripts/build-loop-check.bats:1498-1505`, `$S/logs/bats.txt`

---

## Claim 48: T12 name and comment: "--check refuses a symlink or gitlink on either side, though submodule ignore=all is set, and passes an exec bit"; "The gate repository and the flag each suffice, so this pins them together."

**Location:** `test/scripts/build-loop-check.bats:1507-1510`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers new-side links (link, gl), old-side links (was-link, og), a regular file turned into a symlink (g.txt), exec bits on an existing and a new file, and the joint pin. It does not pin each A16 guard alone (row 518).
**Legibility-target:** for-orchestrator-synthesis

`for p in "T g.txt" "A gl" "A link" "T og" "T was-link"; do has "deny $B $p: $NMODE"; done` and `has "path $B A scripts/n.sh"; has "path $B M scripts/x.sh"` (`test/scripts/build-loop-check.bats:1520-1521`). Of the A16 mutants, only `A16-realrepo-noflag` fails it (Claim 12).

**Evidence:** `test/scripts/build-loop-check.bats:1507-1522`, `$S/logs/mut-A16-*.txt`

---

## Claim 49: T13 name "--check refuses a changed path pathform refuses, and prints only a name in its character set (T13, F17, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1524`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers five paths: space, UTF-8, newline, leading `-` and `.github/`. It does not cover `.gitattributes` or an upper-case `.GIT` part, which pathform's `[.][gG][iI][tT]*` also refuses.
**Legibility-target:** for-orchestrator-synthesis

The test expects `nref 5 5`, 6 lines, `deny $B A -x.md`, `deny $B A .github/w.yml`, and three `deny $B A ?:` lines (`test/scripts/build-loop-check.bats:1527-1530`). It passes.

**Evidence:** `test/scripts/build-loop-check.bats:1524-1531`, `$S/logs/bats.txt`

---

## Claim 50: R6 test name "--check refuses a merge git warned about or that names a missing object: a missing tip or merge-base tree is not read as empty, a missing blob does not land (R6, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1533`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three cases (tip tree, merge-base tree, missing blob) and their union of guards. It does not pin each R6 guard alone (row 514).
**Legibility-target:** for-orchestrator-synthesis

The test passes. Mutant `R6-both` fails it, and so does `F2-nobatch` (the blob case) (`$S/logs/mut-R6-both.txt`, `$S/logs/mut-F2-nobatch.txt`).

**Evidence:** `test/scripts/build-loop-check.bats:1533-1551`, `$S/logs/mut-R6-both.txt`, `$S/logs/mut-F2-nobatch.txt`

---

## Claim 51: R6 test comment "merge-tree reads a missing top-level tree as empty, warns and exits 0 (a missing subtree or blob is fatal)."

**Location:** `test/scripts/build-loop-check.bats:1540`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers merge-tree on git 2.39.5 for the four missing-object shapes. It does not affect what the test asserts, which is correct.
**Legibility-target:** for-orchestrator-synthesis

Both halves are unqualified, and the probes contradict each.
- "Exits 0": p1 case E (missing top-level tree plus a conflict) gave `merge-tree rc=1` with `error: Could not read …`.
- "A missing subtree or blob is fatal": case A (subtree passed by id) and case D (blob passed by id) each gave `rc=0` with empty stderr (`$S/logs/p1.txt`).

The same test's third block says so itself: `# A blob the store lacks, which merge-tree passes by id without reading (security F2).` (`test/scripts/build-loop-check.bats:1545`). The precise version (a382a3f8's correction): "reads a missing top-level tree as empty with a warning, exiting 0 when the merge is otherwise clean; a missing subtree or blob is fatal only when merge-tree must read it".

**Evidence:** `test/scripts/build-loop-check.bats:1540-1550`, `$S/logs/p1.txt`

---

## Claim 52: R7 test name "--check refuses an ambiguous default branch: both main and master, or origin/HEAD naming a branch the gate did not take (R7, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1553`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers four states: both branches with and without origin/HEAD, both findings at once, and origin/HEAD at main when master was taken. It does not cover a non-symbolic origin/HEAD.
**Legibility-target:** for-orchestrator-synthesis

It passes, and mutant `R7-off` fails it (`$S/logs/mut-R7-off.txt`).

**Evidence:** `test/scripts/build-loop-check.bats:1553-1570`, `$S/logs/mut-R7-off.txt`

---

## Claim 53: R9 test name "--check's merge reads no submodule repository: a gitlink fast-forward the real repository would merge is a conflict (R9, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1572`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers merge-tree's isolation from `.git/modules`. It does not cover diff-tree's isolation (T12 covers that).
**Legibility-target:** for-orchestrator-synthesis

The fixture asserts that the real repository merges cleanly (`test/scripts/build-loop-check.bats:1583`). Mutant `R9-realrepo` fails the test (`$S/logs/mut-R9-realrepo.txt`).

**Evidence:** `test/scripts/build-loop-check.bats:1572-1586`, `$S/logs/mut-R9-realrepo.txt`

---

## Claim 54: A15 test name "--check runs its state gate before resolve_main reads an object: a planted key refuses even with main's commit missing (A15, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1588`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test discriminates. What it establishes is that state_gate runs before main_by_name's exit-1 refusal. It does not establish that state_gate runs before resolve_main reads an object. The code does order them that way (`scripts/build-loop.sh:257-258`), so this is a test gap on the honest path, not a code defect.
**Legibility-target:** for-orchestrator-synthesis

Mutant `A15-order` moves `if [[ "$MODE" == check ]]; then state_gate || exit 2; fi` from before `resolve_main || true` to just after it (diff in `$S/logs/p2-a15.txt`). The A15 test still passes (`ok 1`, `$S/logs/mut-A15-order.txt`). Run by hand on the test's fixture, the real script and the mutant print the same line, `refuse state merge.x.driver: set in config, …`, with `rc=2` (`$S/logs/p2-a15.txt`). The reason: with main's commit deleted, `git show-ref --verify` fails (`fatal: git show-ref: bad ref refs/heads/main …`, `$S/logs/p2-a15.txt`). resolve_main then falls back to the current branch (`MAIN="$cur"; MAIN_SHA="$(git rev-parse --verify --quiet HEAD …)"`, `scripts/lib/dev-cycle-read.sh:508`), and state_gate still runs before `main_by_name || … exit 1`. Iteration 1's fact-check (claims 6a and 34) tested a mutant that moved state_gate after main_by_name; that mutant does fail. A test that discriminates would need resolve_main's object read to fail visibly, for example by asserting no git call before state_gate's config reads via the shim, or by making resolve_main's failure exit before the state gate could run.

**Evidence:** `test/scripts/build-loop-check.bats:1588-1594`, `scripts/build-loop.sh:257-260`, `scripts/lib/dev-cycle-read.sh:490-512`, `$S/logs/mut-A15-order.txt`, `$S/logs/p2-a15.txt`

---

## Claim 55: commit cc9b69d3 description: "--check now prints, after each brief's verdict line, one line per path … The verdict is "ok BRIEF TIP TREE" only when nothing is denied, else "refuse BRIEF: K of N changed paths refused". PATH prints as "?" unless …; The N rules (both policies): …; R7 …; A15: a test plants a key with main's commit object deleted; A17: GIT_CONFIG_NOSYSTEM=1; the shim test pins it; A19: help and comments …"

**Location:** `git log -1 cc9b69d3`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the description against the code at cc9b69d3. It does not re-verdict the probe claim (Claim 56) or the counts and mutants (Claim 57).
**Legibility-target:** for-orchestrator-synthesis

At cc9b69d3 the refusal was `echo "refuse $a: $nd of $i changed paths refused"` (`git show cc9b69d3:scripts/build-loop.sh`, line 592), matching the message. The rules and fixes match today's code with the later edits (Claims 21-39). The A15 sentence describes the fixture literally (`rm ".git/objects/${o:0:2}/${o:2}"`, `test/scripts/build-loop-check.bats:1591`).

**Evidence:** `scripts/build-loop.sh:553-628`, `test/scripts/build-loop-check.bats:1588-1594`

---

## Claim 56: commit cc9b69d3: "R6: … (a missing top-level tree is read as empty with exit 0; a missing subtree or blob is fatal, probed)"

**Location:** `git log -1 cc9b69d3`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parenthetical as written. The branch corrects it in a382a3f8's message (Claim 62) and refines that in e02d056b's, so no further action is needed beyond Claims 10b and 51, where the uncorrected wording survives.
**Legibility-target:** for-orchestrator-synthesis

The p1 results contradict both halves (`$S/logs/p1.txt`):
- Case E: a missing top-level tree with a conflict exits 1, not 0.
- Cases A and D: a missing subtree or blob passed by id exits 0 with no stderr.

**Evidence:** `$S/logs/p1.txt`

---

## Claim 57: commit cc9b69d3: "Tests: build-loop-check 101 (92 + 9), build-loop-read 19, dev-cycle 78, fixture-git-env 2, fixture-hermeticity 2; shellcheck clean. Mutants: R6 with both guards removed, R7 with the check off, R9 with merge-tree in the real repository each fail their test. 317 changed lines."

**Location:** `git log -1 cc9b69d3`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at cc9b69d3 (by `grep -c '^@test'`), today's passing runs, the three mutants (run on today's code, which keeps those guards) and the line count. It does not re-run the suites at cc9b69d3 itself.
**Legibility-target:** for-orchestrator-synthesis

`grep -c '^@test'` gave `main: chk=92` and `cc9b69d3: chk=101 read=19 dc=78 fge=2`, and `test/fixture-hermeticity.bats` has 2 (run in this session). The nine added tests are T14, T15, T11, T12, T13, R6, R7, R9 and A15 (the test diff). `--numstat main cc9b69d3 -- scripts test` sums to 317. The mutants `R6-both`, `R7-off` and `R9-realrepo` each fail their test. This matches the "test tally" hallucination pattern, and the counts check out.

**Evidence:** `test/scripts/build-loop-check.bats:1453-1594`, `$S/logs/mut-R6-both.txt`, `$S/logs/mut-R7-off.txt`, `$S/logs/mut-R9-realrepo.txt`

---

## Claim 58: commit 809df345: "Plan: F8 names the gate repository and --ignore-submodules=none (the -c diff.ignoreSubmodules=none form does not override a planted submodule.<name>.ignore=all); the --check interface line describes the verdict, path and deny lines; step 5's U2b1b note records what was built. Override log rows 497 and 507-511 gain their U2b1b resolution. R8 is left open with a proposal"

**Location:** `git log -1 809df345`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the doc edits and F8's probe claim (Claim 15). It does not re-check the text of the later edits to those rows.
**Legibility-target:** for-orchestrator-synthesis

Plan lines 123, 212 and 283 and rows 497 and 507-511 carry the named additions (the diff in this session). p4 confirms the -c form does not override `submodule.<name>.ignore=all` (`$S/logs/p4.txt`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:123`, `docs/working/plan-build-loop-handoff.md:212`, `docs/working/plan-build-loop-handoff.md:283`, `docs/reviews/override-log.md:497-511`, `$S/logs/p4.txt`

---

## Claim 59: commit a382a3f8 fix list: "security F1: nrules checks own_blob's exit status …; security F2: one cat-file --batch-check over every new regular file … New refusal "names a file the object store lacks"; test with a mktree --missing tip (mutant fails); performance F1: one lower_all pass per brief …; api 1: the refusing verdict carries TIP and TREE …; api 2, architecture 5: the R7 check is default_gate …; architecture 1 …; architecture 2: lib header contract item 5 …; T14 adds docs/working/Questions.md and docs/CONSTRAINTS.md, T12 an old-side gitlink; fact-check 6b: override row 511 names row 492."

**Location:** `git log -1 a382a3f8`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed fix at a382a3f8 (refusal text then "file", now "blob") and the F2 mutant. It does not cover the A16 sentence (Claim 60) or the timing (Claim 61).
**Legibility-target:** for-orchestrator-synthesis

At a382a3f8, line 611 read `names a file the object store lacks` (`git show a382a3f8:scripts/build-loop.sh`). The R6 test builds its tip with `git mktree --missing` (`test/scripts/build-loop-check.bats:1548`), and mutant `F2-nobatch` fails it. T14's `fs` holds `docs/working/Questions.md` and the loop writes `docs/CONSTRAINTS.md` (`:1458-1459`). T12 adds `og` as an old-side gitlink (`:1515`). Row 511 names row 492 (`docs/reviews/override-log.md:511`).

**Evidence:** `scripts/build-loop.sh:559`, `scripts/build-loop.sh:615-626`, `scripts/build-loop.sh:241-251`, `scripts/lib/dev-cycle-read.sh:59-65`, `test/scripts/build-loop-check.bats:1453-1551`, `$S/logs/mut-F2-nobatch.txt`

---

## Claim 60: commit a382a3f8: "A16 is pinned (T12 under submodule ignore=all in .gitmodules and the repo config; the mutant running diff-tree in the real repository fails it)."

**Location:** `git log -1 a382a3f8`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three A16 mutants. It does not change the settled disposition (row 518, Won't-Fix).
**Legibility-target:** for-orchestrator-synthesis

Moving diff-tree into the real repository while keeping `--ignore-submodules=none` passes T12. Only the mutant that also drops the flag fails it (`$S/logs/mut-A16-realrepo-keepflag.txt`, `$S/logs/mut-A16-realrepo-noflag.txt`). The precise version: "the mutant running diff-tree in the real repository without --ignore-submodules=none fails it". e02d056b's test comment and row 518 already say this.

**Evidence:** `test/scripts/build-loop-check.bats:1508-1510`, `docs/reviews/override-log.md:518`, `$S/logs/mut-A16-realrepo-keepflag.txt`, `$S/logs/mut-A16-realrepo-noflag.txt`

---

## Claim 61: commit a382a3f8: "performance F1: … (measured 13.5 s at 5,000 paths as built)"

**Location:** `git log -1 a382a3f8`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers a re-measurement of cc9b69d3's script on this machine. It cannot confirm a past measurement taken under different load.
**Legibility-target:** for-orchestrator-synthesis

p3 ran cc9b69d3's `build-loop.sh` (from `git show`) on 5,000 new files and measured `run1: 8977 ms` and `run2: 8879 ms` (`$S/logs/p3-time.txt`). That is the same order as 13.5 s but about 34% lower. Verifying the exact figure would need the original machine and load.

**Evidence:** `$S/logs/p3-time.txt`

---

## Claim 62: commit a382a3f8 correction: "a missing top-level tree is read as empty with a warning, exiting 0 only when that merge is otherwise clean; a missing subtree or blob is fatal only when merge-tree must read it (one passed by id is silent, which security F2 now refuses)"; and e02d056b's correction: "a missing subtree passed by id is refused by diff-tree ("could not be listed"), not by the missing-blob check, which covers blobs."

**Location:** `git log -1 a382a3f8`, `git log -1 e02d056b`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two corrections together on git 2.39.5. It does not cover other git versions.
**Legibility-target:** for-orchestrator-synthesis

The p1 results (`$S/logs/p1.txt`), case by case:
- Case C (clean merge): rc=0 with a warning.
- Case E (conflict): rc=1 with a warning.
- Case B (a subtree that must be read): rc=128 fatal.
- Cases A and D (passed by id): rc=0 and silent.
- Case A under `--check`: `the paths the merge of feat/x changes could not be listed`.
- Case D under `--check`: `names a blob the object store lacks`.

**Evidence:** `$S/logs/p1.txt`

---

## Claim 63: commit a382a3f8: "Tests: build-loop-check 101, build-loop-read 19, dev-cycle 78, fixture-git-env 2, fixture-hermeticity 2; shellcheck clean on build-loop.sh … 367 code lines against main."

**Location:** `git log -1 a382a3f8`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at a382a3f8 and the line count (added plus deleted in `scripts` and `test`). It does not re-run the suites at that commit.
**Legibility-target:** for-orchestrator-synthesis

`grep -c '^@test'` gave `a382a3f8: chk=101 read=19 dc=78 fge=2`, and `--numstat main a382a3f8 -- scripts test` sums to `add 328 del 39 sum 367` (run in this session).

**Evidence:** `test/scripts/build-loop-check.bats`

---

## Claim 64: commit e02d056b: "5,000 paths now about 1.3 s … help says pathform refuses a part starting .git in any case; the missing-object refusal reads "names a blob the object store lacks" … and the help lists it as its own case … the R7 test now shows default_gate printing both findings (a master ref naming a tree) … Tests: build-loop-check 101, …; shellcheck clean. 382 code lines against main. Notes: wording and one test only; no behavior change but the refusal text."

**Location:** `git log -1 e02d056b`
**Type:** Behavioral / Reference / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the timing, the help and refusal text, the R7 block, the counts and line count, and the no-behavior-change claim. It does not check the cited reviewer finding numbers against the iteration-2 reports.
**Legibility-target:** for-orchestrator-synthesis

The evidence, item by item:
- Timing: p3 measured 1,275-1,338 ms.
- Help: it reads `(a part starting .git, any case: .github/)` (`scripts/build-loop.sh:122`) and lists the blob refusal as its own case (`:107-110`).
- R7 test: it writes `git rev-parse main^{tree} > .git/refs/heads/master` and expects both lines (`test/scripts/build-loop-check.bats:1562-1565`).
- Counts: e02d056b has `chk=101 read=19 dc=78 fge=2`, and the 124 + 78 suite runs passed.
- Line count: `sum 382`.
- No behavior change: in `git diff a382a3f8 e02d056b -- scripts test`, the only non-comment changes are the moved truthrule call (comment removed), the refusal text, and the R7 test block.

**Evidence:** `scripts/build-loop.sh:107-122`, `test/scripts/build-loop-check.bats:1553-1570`, `$S/logs/p3-time.txt`, `$S/logs/bats.txt`, `$S/logs/bats-dc.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 54** (`test/scripts/build-loop-check.bats:1588`): the A15 test does not establish its name. A mutant running state_gate after resolve_main passes it, because with main's commit missing resolve_main falls back to the current branch and state_gate still runs before main_by_name's exit. The code's order is right; the test pins only "before main_by_name". Honest-path test gap, new in this pass (iteration 1 tested a weaker mutant).
- **Claim 51** (`test/scripts/build-loop-check.bats:1540`): "exits 0 (a missing subtree or blob is fatal)" is unqualified. It exits 1 on a conflict, and a subtree or blob passed by id is silent, as the same test's third block says. Use a382a3f8's corrected wording.
- **Claim 10b** (`docs/reviews/override-log.md:514`): the parenthetical "(a missing subtree or blob is fatal, exit 128)" repeats cc9b69d3's uncorrected probe claim. The row's disposition holds: in the by-id cases neither guard fires, and diff-tree or the batch-check refuses instead.
- **Claim 56** (commit cc9b69d3): same probe claim, already corrected in a382a3f8's and e02d056b's messages; no action.

### Stale
- **Claim 19b** (`docs/working/plan-build-loop-handoff.md:283`): "R8 is proposed as a Q-103 residual for its review to decide". It was decided at iteration 1 (row 509; step 13 lists it).

### Mostly Accurate
- **Claim 18** (`docs/working/plan-build-loop-handoff.md:212`): the K-of-N refusal is quoted without "in the merge of TIP (tree TREE)".
- **Claim 20** (`docs/working/plan-build-loop-handoff.md:305`): step 13's R8 surface omits `git/refs/` and `git/HEAD`, which row 509 now lists.
- **Claim 22** (`scripts/build-loop.sh:90-92`): "refuse state gate" is printed after open_shared has read main's open briefs, not before any brief is read, and a failed mktemp exits 1 with no line.
- **Claim 27** (`scripts/build-loop.sh:137-139`): the Exit line does not mention that a failed mktemp exits 1.
- **Claim 60** (commit a382a3f8): the real-repo diff-tree mutant fails T12 only when the flag is also dropped (already stated in row 518 and the test comment).

### Unverifiable
- **Claim 61** (commit a382a3f8): "13.5 s at 5,000 paths". Re-measured at 8.9 s here; the original machine and load are needed.

## Goal-Alignment Note

The goal is to land U2b1b after a clean review-fix loop. Every behavioral claim in the `--check` help and the new comments matched the code under execution: the state gate, default_gate, gate_git, merge_result, the missing-blob batch-check, the N rules, the own-brief rule and the path display. All suites pass (124 + 78), and the carried R6, R7, R9, A16 and A17 mutants fail their tests as claimed. Nothing found is a behavioral red. One item is a test gap: the A15 test's name claims an ordering it does not pin (Claim 54; honest-path class, test only, code correct). The rest is wording:
- Two places keep the pre-correction "missing subtree or blob is fatal" claim (test comment `:1540`, row 514).
- The plan has three small drifts (step 5's R8 sentence, step 13's surface, the --check line's refusal text).
- Two help or exit details concern the rare gate-repository setup failure.

Whether the A15 gap is amber for merge is the orchestrator's call: either rename the test to "before main_by_name refuses" or strengthen it.
