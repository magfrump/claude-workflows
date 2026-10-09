Commit: e02d056b

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2b1b (branch `feat/build-loop-u2b1b`, HEAD e02d056b, base main 0e4596ce)
**Scope:** full branch, `git diff main...HEAD` (commits cc9b69d3, 809df345, a382a3f8, e02d056b): `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh` (two comment edits), `test/scripts/build-loop-check.bats`, the plan's edited lines, the override-log rows this branch added or edited, and the four commit messages. Replicate fc-r3 (k=3, final confirming pass).
**Checked:** 2026-10-08
**Total claims checked:** 62
**Summary:** 50 verified, 9 mostly accurate, 2 stale, 0 incorrect, 1 unverifiable

Execution provenance, shared by every `executed` claim. The scratch dir is `S=/tmp/claude-1000/-workspace/0c855a7c-1c04-4bab-8bf1-7620be67b78e/scratchpad/u2b1b-i3/fc-r3`. All logs are under `$S/logs/` (outside the worktree, per the task's "write nothing else in the worktree"). git is 2.39.5.

- **Suites.** cwd is the worktree via the `scratchpad/wt` symlink, at HEAD e02d056b. `TMPDIR=$(mktemp -d -p $S) bats test/scripts/build-loop-check.bats` started 2026-10-08T22:17:03Z, exit 0, 101 ok (`$S/logs/check.log`). build-loop-read (19), dev-cycle (78), fixture-git-env (2), `test/fixture-hermeticity.bats` (2) and `shellcheck scripts/build-loop.sh` ran in one background run, all exiting 0 (`$S/logs/others.log`).
- **Mutants.** Each is a `git archive e02d056b scripts test` copy in `$S/<mutant>/`, changed by one perl edit. Each ran `bats -f <filter> test/scripts/build-loop-check.bats` from its copy, starting 2026-10-08T22:18:27Z, with the summary in `$S/logs/mutants.log` and per-mutant logs in `$S/logs/mut-<name>.log`:
  - mF2 (batch-check off): R6 test fails, rc 1.
  - mR6 (stderr guard and tree guard both off): R6 fails, rc 1.
  - mR7 (default_gate call off): R7 fails, rc 1.
  - mDG (only default_gate's origin/HEAD check off): R7 fails at :1565, rc 1.
  - mR9 (merge-tree in the real repo): R9 fails, rc 1.
  - mA16a (diff-tree in the real repo, flag kept): T12 passes, rc 0.
  - mA16b (real repo, flag dropped): T12 fails, rc 1.
  - mA16c (gate repo, flag dropped): T12 passes, rc 0.
  - mA15 (state_gate moved after resolve_main): A15 fails, rc 1, with "build-loop.sh needs a default branch …".
  - mT14a (truthrule's instr word also matches `docs/working/{cycles,briefs}/*`): T14, T15 and T11 pass, rc 0.
  - mT14b (instr also matches `docs/roadmap.md`): T14 and T11 fail, rc 1.
- **Probes.** Scripts are `$S/probe1.sh`, `$S/probe2.sh` and `$S/probe3.sh`. Each does `set -eu`, makes its own `mktemp -d -p $S` and refuses to run outside it.
  - probe1 (22:19:34Z, exit 0, `$S/logs/probe1.log`) has four cases:
    - P1: a missing subtree passed by id.
    - P2: diff-tree under `submodule.gl.ignore=all`.
    - P3: system-config `merge.directoryRenames=true`, with and without `GIT_CONFIG_NOSYSTEM=1`.
    - P4: `git add -A` on a gitlink with no directory.
  - probe2 (22:19:48Z, exit 0, `$S/logs/probe2.log`) has two cases:
    - 1,000 `$(lower …)` calls.
    - `--check` over 5,000 added paths, three runs.
  - probe3 (22:21:54Z, exit 0, `$S/logs/probe3.log`) has three cases:
    - shellcheck on the lib.
    - The NUL-count edge.
    - cc9b69d3's `--check` at 5,000 paths.

Hallucination-pattern log read. The only pattern near these claims is the "test tally" entry (37c5ea9). Every tally here was checked against `grep -c '^@test'` at each commit and by running the suites, and all of them match.

---

## Claim 1: override row 494 addendum: "the gate repository closes merge-tree" holds against state planted before the run, not against a concurrent same-uid writer (R8, row 509)

**Location:** `docs/reviews/override-log.md:494`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers where the gate repository is built and when merge-tree runs there. It does not cover the race's timing (R8's ~40 ms was not re-measured).
**Legibility-target:** for-orchestrator-synthesis

The gate repository is written once, after the state gate. `GATE_TMP="$(mktemp -d)"; trap …; gate_repo || …` is at `scripts/build-loop.sh:642-643`, and every later merge-tree call reads it through `gate_git` (`(cd "$GATE_TMP/work" && "${GATE_ENV[@]}" git "$@")`, `:512`). Nothing in the script stops a same-uid writer from editing `$GATE_TMP` between those points (paraphrased — no quote available because this is about absent code: no lock, no re-verification of `$GATE_TMP/git/config` after `gate_repo`).

**Evidence:** `scripts/build-loop.sh:497-515`, `scripts/build-loop.sh:640-649`

---

## Claim 2: override row 497 addendum: "the first line is the verdict line; path and deny lines follow it, and the help says 'every verdict line ok'"

**Location:** `docs/reviews/override-log.md:497`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers check_line's print order and the help's exit line. It does not cover a skip or refuse line from status_line, which is a single line with no path lines after it.
**Legibility-target:** for-orchestrator-synthesis

check_line prints the verdict first and then the rows: `if [[ "$nd" -eq 0 ]]; then echo "ok $a $sha $tree"; else echo "refuse …"; fi` and then `printf '%s\n' "${rows[@]}"` (`scripts/build-loop.sh:626-627`). The caller tests the start of the output: `[[ "$out" == "ok "* ]] || fails=1` (`:647`). The help reads `# Exit: 0 every line printed (or help), and for --check every verdict line ok;` (`:137`).

**Evidence:** `scripts/build-loop.sh:137-139`, `scripts/build-loop.sh:579-628`, `scripts/build-loop.sh:644-649`

---

## Claim 3: override row 507: "Fixed in cc9b69d3 (U2b1b): gate_git refuses any stderr; the trees of main, the tip and each merge base must exist; the test fails with both guards removed."

**Location:** `docs/reviews/override-log.md:507`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers both guards and the double mutant. It does not establish that either guard is pinned alone (row 514 says so).
**Legibility-target:** for-orchestrator-synthesis

Both guards are in the code: `[[ ! -s "$GATE_TMP/err" ]] || return 3` (`scripts/build-loop.sh:513`) and `for b in "$MAIN_SHA" "$1" $bases; do gate_git cat-file -e "$b^{tree}" || return 2; done` (`:525`). Mutant mR6 removes both. The R6 test then fails at `:1538`, because `--check` prints `refuse …: 1 of 2 changed paths refused … (tree 4b825dc642cb6eb9a060e54bf8d69288fbee4904)`: the tip's tree was read as the empty tree.

**Evidence:** `scripts/build-loop.sh:510-530`, `test/scripts/build-loop-check.bats:1533-1551`, `$S/logs/mut-mR6.log`

---

## Claim 4: override row 508: "Fixed in cc9b69d3 (U2b1b): --check refuses both main and master, or origin/HEAD naming a branch other than the one taken (`refuse state default-branch:`)."

**Location:** `docs/reviews/override-log.md:508`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers default_gate's two checks and their wording. It does not cover `--status` and `--settings`, which still follow origin/HEAD (row 495, deferred).
**Legibility-target:** for-orchestrator-synthesis

The code is `echo "refuse state default-branch: both main and master exist"` (`scripts/build-loop.sh:244`) and `echo "refuse state default-branch: origin/HEAD names ${p#refs/remotes/}, but the default branch taken is $MAIN"` (`:248`). The R7 test fails under mR7 (the call removed) and under mDG (only the origin/HEAD check removed).

**Evidence:** `scripts/build-loop.sh:241-251`, `scripts/build-loop.sh:260`, `$S/logs/mut-mR7.log`, `$S/logs/mut-mDG.log`

---

## Claim 5: override row 509 (R8 decided; surface `$GATE_TMP/git/config`, `git/info/`, `work/.gitattributes`, `err`, `diff`, plus `git/refs/` and `git/HEAD`; "merge-base, cat-file, diff-tree and hash-object now run there too"; "the missing-blob batch-check adds one more gate_git call")

**Location:** `docs/reviews/override-log.md:509`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the files gate_repo and gate_git create or write, and the list of gate_git callers. It does not cover the decision itself (a judgment) or a measurement of the race.
**Legibility-target:** for-orchestrator-synthesis

- gate_repo creates `mkdir "$GATE_TMP/git" "$GATE_TMP/git/refs" "$GATE_TMP/work"`, writes `$GATE_TMP/git/HEAD` and writes `$GATE_TMP/git/config` (`scripts/build-loop.sh:502-504`).
- gate_git writes `2>"$GATE_TMP/err"` (`:512`), and check_line writes `> "$GATE_TMP/diff"` (`:599`).
- The gate_git callers are `merge-base --all` (`:522`), `cat-file -e` (`:525`), `merge-tree` (`:526`), `hash-object` (`:542`), `diff-tree` (`:599`) and `cat-file --batch-check` (`:615`).
- `git/info/` and `work/.gitattributes` are not created by the script. They are paths a racer could create (paraphrased — no quote available because the claim names paths a writer could add, not code).

**Evidence:** `scripts/build-loop.sh:497-543`, `scripts/build-loop.sh:599`, `scripts/build-loop.sh:615`

---

## Claim 6: override row 510: "Fixed in cc9b69d3 (U2b1b): the old test keeps its base gitlink; a new one merges a gitlink fast-forward that the real repository resolves cleanly; merge-tree in the real repository fails it."

**Location:** `docs/reviews/override-log.md:510`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers both tests and the mutant. It does not cover a gitlink conflict whose submodule repository lives somewhere other than `.git/modules/<name>`.
**Legibility-target:** for-orchestrator-synthesis

- The old test now commits with `git add .gitmodules; git update-index --add --cacheinfo "160000,$s1,sub"; git commit -q -m sub1` (`test/scripts/build-loop-check.bats:1405`).
- Probe P4 shows why: after `git add -A`, a gitlink with no directory is dropped from the index. `git ls-files -s` lists `160000 … sub` before the add and nothing after it.
- The new test checks its own fixture with `git merge-tree --write-tree main feat/x > /dev/null || { echo "fixture: …"; return 1; }` (`:1584`).
- Mutant mR9 (merge-tree in the real repo) fails it.

**Evidence:** `test/scripts/build-loop-check.bats:1400-1416`, `test/scripts/build-loop-check.bats:1572-1586`, `$S/logs/probe1.log` (P4), `$S/logs/mut-mR9.log`

---

## Claim 7: override row 511 addenda (A15 test; A16 in the gate repository with --ignore-submodules=none; A17 GIT_CONFIG_NOSYSTEM=1; A18 unchanged, "merge-base --all, one per brief"; row 492 "does not yet name alternates, packs or the multi-pack-index")

**Location:** `docs/reviews/override-log.md:511`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers A15 (mA15), A16 (P2 and the mA16 mutants), A17 (P3), the one merge-base call per brief, and row 492's text. It does not cover the A18 timings ("3 ms at 1,000 … 306 ms at 100,000"), which were not re-measured.
**Legibility-target:** for-orchestrator-synthesis

- **merge-base.** merge_result is called once per brief (`tree="$(merge_result "$sha")"`, `scripts/build-loop.sh:591`) and runs one `gate_git merge-base --all` (`:522`).
- **Row 492.** Its text (`docs/reviews/override-log.md:492`, "Rewriting a loose object's bytes behind its unchanged id …") names no alternates, packs or multi-pack-index.
- **A15.** Under mA15 the A15 test fails, exiting 1 with "needs a default branch".
- **A17.** In P3 the shipped script prints `refuse …: feat/x conflicts with the default branch` when `GIT_CONFIG_SYSTEM` holds `merge.directoryRenames = true`. A copy without `GIT_CONFIG_NOSYSTEM=1` prints `ok …` with `path … A new/c`.

**Evidence:** `scripts/build-loop.sh:196-198`, `scripts/build-loop.sh:520-530`, `docs/reviews/override-log.md:492`, `$S/logs/probe1.log` (P2, P3), `$S/logs/mut-mA15.log`

---

## Claim 8: override row 512 i2 addendum: "a382a3f8 split check_line into collect, batch-check and judge phases (the seam); nrules takes seven positional arguments and trusts that $7 is lower($6)"

**Location:** `docs/reviews/override-log.md:512`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the order of the three phases inside check_line and nrules' signature. It does not establish that the phases are separate functions (they are not; check_line is still one function).
**Legibility-target:** for-orchestrator-synthesis

- **Collect.** The `while … read -r -d '' meta && … read -r -d '' p` loop (`scripts/build-loop.sh:602-607`).
- **Batch-check.** `printf '%s\n' "${ids[@]}" | gate_git cat-file --batch-check='%(objecttype)'` (`:615`).
- **Judge.** `nrules "$a" "${oms[$i]}" "${nms[$i]}" "${nos[$i]}" "${ss[$i]}" "$p" "${lps[$i]}"` (`:623`). nrules' only check that `$7` is lower-cased is in check_line: `nul_list lps lower_all "${ps[@]}"` (`:620`).

**Evidence:** `scripts/build-loop.sh:579-628`

---

## Claim 9: override row 513: the NUL-count check is untested and "git's own diff-tree -z output never ends mid-record, so only a shimmed git could reach it; the check fails closed"

**Location:** `docs/reviews/override-log.md:513`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** This covers "untested" (no test exercises a short diff file) and "fails closed" for a record cut after its first NUL. It does not establish that the check catches every malformed tail (see Claim 33), and it does not establish git's output guarantee, which was not probed.
**Legibility-target:** for-orchestrator-synthesis

When diff-tree fails, check_line refuses before the count runs: `if ! gate_git diff-tree … > "$GATE_TMP/diff"; then echo "refuse …could not be listed"; return; fi` (`scripts/build-loop.sh:599-601`). A partial file could therefore only come from a git that exits 0. No test in the branch's diff writes a malformed diff file (paraphrased — no quote available because the claim is about absent tests; grep of the test diff for `NUL` or a shimmed diff-tree finds none).

**Evidence:** `scripts/build-loop.sh:599-609`, `test/scripts/build-loop-check.bats:1440-1594`

---

## Claim 10: override row 514: "every probed missing-tree case trips both; no case found where only stderr catches it (a missing subtree or blob is fatal, exit 128). The test pins their union (the double mutant fails)."

**Location:** `docs/reviews/override-log.md:514`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the union pin (mR6) and the parenthetical. It does not cover single-guard mutants, which iteration 2 ran (its claim 26).
**Legibility-target:** for-orchestrator-synthesis

The union pin holds: mR6 fails the R6 test. The parenthetical "(a missing subtree or blob is fatal, exit 128)" overstates. A missing blob or subtree that merge-tree passes by id is silent. Under mF2 (batch-check off), the R6 test's `mktree --missing` tip prints `ok … path … A new.txt` with status 0. A missing subtree passed by id gets past merge-tree and is caught only by diff-tree (P1: `refuse …: the paths the merge of feat/x changes could not be listed`). a382a3f8's own correction paragraph says this ("fatal only when merge-tree must read it"). The precise wording is "a missing subtree or blob that merge-tree must read is fatal".

**Evidence:** `docs/reviews/override-log.md:514`, `$S/logs/mut-mF2.log`, `$S/logs/probe1.log` (P1)

---

## Claim 11: override rows 515-517 (own_blob's race untested; own_blob repeats brief_fields' awk and check_line reads NAMECHARS; informational notes incl. "U2c also states whether floor runs on a path the N rules already denied")

**Location:** `docs/reviews/override-log.md:515-517`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the code facts the rows state. It does not cover their dispositions, which are judgments.
**Legibility-target:** for-orchestrator-synthesis

- **Row 515.** own_blob reads the blob twice: `n="$(git cat-file blob "$MAIN_SHA:$1" | … awk …)"` (`scripts/build-loop.sh:540`) and `git cat-file blob "$MAIN_SHA:$1" | N="$n" perl … | gate_git hash-object --no-filters --stdin` (`:542`).
- **Row 516.** own_blob's awk `!n && /^Status:/` (`:540`) restates brief_fields' `match($0, /^(Status|Branch|Policy|Paths|Asked|Dispatched):/)` first-match rule (`scripts/lib/dev-cycle-read.sh:369-371`). check_line's display rule is `[[ ! "$p" =~ ^[$NAMECHARS]+$ ]] || shown="$p"` (`scripts/build-loop.sh:622`).
- **Row 517.** U2c has not been built, so nrules has no floor call (paraphrased — no quote available because this is about absent code: `grep -n floor scripts/build-loop.sh` matches only comments).

**Evidence:** `scripts/build-loop.sh:536-543`, `scripts/build-loop.sh:622`, `scripts/lib/dev-cycle-read.sh:357-381`

---

## Claim 12: override row 518: "A16's two guards … are pinned only together: either alone passes T12 … each alone closes A16, and T12 fails when both go"

**Location:** `docs/reviews/override-log.md:518`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the three diff-tree mutants against T12. It does not cover `.gitmodules` read from a checkout's index in the gate repository (the gate repository has none).
**Legibility-target:** for-orchestrator-synthesis

mA16a (real repo, flag kept) and mA16c (gate repo, no flag) pass T12. mA16b (real repo, no flag) fails it. In P2, the real repository under `submodule.gl.ignore=all` prints nothing for plain `diff-tree`, nothing for `-c diff.ignoreSubmodules=none diff-tree`, and `:000000 160000 … A	gl` for `--ignore-submodules=none`.

**Evidence:** `scripts/build-loop.sh:599`, `test/scripts/build-loop-check.bats:1507-1522`, `$S/logs/mutants.log`, `$S/logs/probe1.log` (P2)

---

## Claim 13: override row 519: "The K-of-N verdict names the merge by TIP while six sibling refusals name it by branch"

**Location:** `docs/reviews/override-log.md:519`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers check_line's refusal texts. It does not cover status_line's skip texts.
**Legibility-target:** for-orchestrator-synthesis

The K-of-N line is `"refuse $a: $nd of ${#ps[@]} changed paths refused in the merge of $sha (tree $tree)"` (`scripts/build-loop.sh:626`). The siblings that use `$br` are `:594` (conflicts), `:595` (could not be computed), `:600` (could not be listed), `:604` and `:609` (could not be read), `:617` (names a blob) and `:620` (could not be lower-cased). That is seven sites carrying six distinct texts, so "six" counts texts, not sites.

**Evidence:** `scripts/build-loop.sh:579-628`

---

## Claim 14: override row 520 prices: "--check is linear at about 0.25 ms per path (1,326 ms at 5,000, about 5 s at 20,000)"; truthrule 0.07 ms per path; batch-check 0.1 s per 5,000

**Location:** `docs/reviews/override-log.md:520`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** This covers the 5,000-path figure (three runs). It does not cover the 20,000-path extrapolation, the per-component costs (truthrule, batch-check), or linearity itself (only one size was measured).
**Legibility-target:** for-orchestrator-synthesis

probe2's runs took 1,341, 1,334 and 1,323 ms for 5,000 added files, each printing 5,001 lines. That is about 0.27 ms per path, with a load average of 1.44.

**Evidence:** `$S/logs/probe2.log`

---

## Claim 15: plan F8: "plumbing `diff-tree` in the gate repository (no repo config, no checkout `.gitmodules`) with `--ignore-submodules=none`: `-c diff.ignoreSubmodules=none` does not override `submodule.<name>.ignore=all` (U2b1a2 A16, probed; U2b1b)"

**Location:** `docs/working/plan-build-loop-handoff.md:123`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers git 2.39.5's behavior and the code's flags. It does not cover other git versions.
**Legibility-target:** for-orchestrator-synthesis

The code runs `gate_git diff-tree -r --no-renames --raw -z --ignore-submodules=none "$MAIN_SHA" "$tree"` (`scripts/build-loop.sh:599`). P2 shows that `-c diff.ignoreSubmodules=none` prints nothing under `submodule.gl.ignore=all`, while `--ignore-submodules=none` prints the gitlink.

**Evidence:** `scripts/build-loop.sh:599`, `$S/logs/probe1.log` (P2)

---

## Claim 16: plan F12: "N-denied via truthrule's cycle and settings words (the lib's `writable()` plus `docs/dev-cycle.md`), and, N-only, anything under `docs/working/briefs/` or `docs/working/cycles/`; `docs/constraints.md` by its user word (F54) (T14; U2b1b)"

**Location:** `docs/working/plan-build-loop-handoff.md:127`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers nrules' branch and T14. It does not cover the S rules (U2c).
**Legibility-target:** for-orchestrator-synthesis

The code is `cycle|settings) DENY="one of the dev cycle's own files" ;; user) DENY="the user's constraints doc…" ;; *) [[ ! "$7" =~ ^docs/working/(briefs|cycles)/ ]] || DENY="one of the dev cycle's own files" ;;` (`scripts/build-loop.sh:567-569`), and truthrule's words are `writable "$1"` → cycle, `docs/dev-cycle.md` → settings and `docs/constraints.md` → user (`scripts/lib/dev-cycle-read.sh:1094-1096`). T14 passes.

**Evidence:** `scripts/build-loop.sh:553-572`, `scripts/lib/dev-cycle-read.sh:1089-1099`, `$S/logs/check.log`

---

## Claim 17: plan `--state` line: "U2b1a's `state_gate`, then U2b1b's `default_gate` once main is resolved: both main and master, or origin/HEAD naming another branch than the one taken"

**Location:** `docs/working/plan-build-loop-handoff.md:207`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the two functions' order and findings in `--check`. It does not cover `--state`, which does not exist yet (U3b).
**Legibility-target:** for-orchestrator-synthesis

The order is `state_gate || exit 2` (`scripts/build-loop.sh:257`), then `resolve_main`, then `default_gate || exit 2` (`:260`). default_gate's two findings are at `:243-249`.

**Evidence:** `scripts/build-loop.sh:241-260`

---

## Claim 18: plan `--check` line: "U2b1b (built): the verdict line comes first (`ok BRIEF TIP TREE`, or `refuse BRIEF: K of N changed paths refused`), then `path BRIEF S PATH` or `deny BRIEF S PATH: WHY` per changed path; exit 0 only when every verdict line is ok."

**Location:** `docs/working/plan-build-loop-handoff.md:212`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the refusal text and the exit rule. It does not cover the rest of the line, which is Verified (order, path and deny forms, exit).
**Legibility-target:** for-orchestrator-synthesis

Since a382a3f8 (api 1) the refusal reads `refuse $a: $nd of ${#ps[@]} changed paths refused in the merge of $sha (tree $tree)` (`scripts/build-loop.sh:626`). The plan line, written in 809df345, still shows the shorter text. e02d056b updated F12 and the `--state` line, but not this one. The current form is `refuse BRIEF: K of N changed paths refused in the merge of TIP (tree TREE)`.

**Evidence:** `scripts/build-loop.sh:626`, `docs/working/plan-build-loop-handoff.md:212`

---

## Claim 19: plan step 5's U2b1b note: "… (override rows 497, 507-511). R8 is proposed as a Q-103 residual for its review to decide."

**Location:** `docs/working/plan-build-loop-handoff.md:283`
**Type:** Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the R8 sentence. It does not cover the rest of the note (cc9b69d3, 317 lines, the mode rule as N, the own brief keeping its mode, R6/R7/R9/A15/A17/A19), which is Verified.
**Legibility-target:** for-orchestrator-synthesis

Row 509 now reads `**Decided at U2b1b iteration 1 (security, architecture concur): Q-103 residual.**` (`docs/reviews/override-log.md:509`), and plan step 13 lists R8 for U5 (`:305`). The step-5 note still says "proposed … for its review to decide". The other atoms check out: `317` matches `git diff --shortstat main..cc9b69d3 -- scripts test` (282+35), and the mode rule runs under both policies (`scripts/build-loop.sh:557`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:283`, `docs/working/plan-build-loop-handoff.md:305`, `docs/reviews/override-log.md:509`

---

## Claim 20: plan step 13: "U2b1a2's R8 (a same-uid writer racing the gate's GATE_TMP: its config, info/, work/.gitattributes, err and diff; override row 509)"

**Location:** `docs/working/plan-build-loop-handoff.md:305`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the surface list against row 509 and gate_repo. It does not cover U5's future content.
**Legibility-target:** for-orchestrator-synthesis

Row 509's i2 addendum adds `git/refs/` and `git/HEAD` to the surface (`docs/reviews/override-log.md:509`), and gate_repo creates both (`printf 'ref: refs/heads/none\n' > "$GATE_TMP/git/HEAD"`, `scripts/build-loop.sh:503`). Step 13 lists five items and omits those two. It does point at row 509, so a reader who follows the pointer gets the full list.

**Evidence:** `docs/working/plan-build-loop-handoff.md:305`, `docs/reviews/override-log.md:509`, `scripts/build-loop.sh:502-504`

---

## Claim 21a: help, --check state gate: the key list, the files "not absent or an empty file", the replace ref, origin/HEAD, "then (once main is found) both main and master present, or origin/HEAD naming another branch than the one taken. Each finding prints 'refuse state WHAT: WHY' and exits 2 before any brief is read"

**Location:** `scripts/build-loop.sh:80-91`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers state_gate's and default_gate's findings, their run before read_settings, open_shared and check_line, and the tests that pin them (state-gate tests, R7, A15). It does not cover keys written after the gate passes (row 494).
**Legibility-target:** for-orchestrator-synthesis

- **Keys.** `STATE_KEYS_RE='^(filter\.|include|hook\.|merge\.|diff\.|core\.fsmonitor|core\.attributesfile|core\.hookspath|gpg\.|log\.showsignature|extensions\.partialclone$|remote\..*\.promisor$)'` (`:212`) is read with `git config --file "$p" --no-includes` from `config` and `config.worktree` (`:215-218`).
- **Files.** `[[ -s "$p" || -L "$p" || ( -e "$p" && ! -f "$p" ) ]]` over `info/attributes info/grafts shallow` (`:224-226`).
- **Order.** Both gates exit before `read_settings` and `open_shared` (`:257`, `:260`, `:640-641`).
- **Tests.** Every test in the suite passes. Under mA15 the A15 test fails.

**Evidence:** `scripts/build-loop.sh:80-92`, `scripts/build-loop.sh:212-260`, `$S/logs/check.log`, `$S/logs/mut-mA15.log`

---

## Claim 21b: help: "('refuse state gate: WHY' when the gate's own merge repository cannot be set up)" as one of the findings that exit 2 "before any brief is read"

**Location:** `scripts/build-loop.sh:91-92`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** This covers where gate_repo runs. It does not cover state_gate and default_gate, which do run before any brief is read (Claim 21a).
**Legibility-target:** for-orchestrator-synthesis

gate_repo runs after `read_settings` and `open_shared  # once, in this shell` (`scripts/build-loop.sh:640-643`). open_shared runs `brief_fields "$f"` over every brief on main with a `Status: open` line (`scripts/lib/dev-cycle-read.sh:480`). So "refuse state gate:" comes after open briefs have been read, though before any verdict line. It is accurate if read as "before any brief's verdict".

**Evidence:** `scripts/build-loop.sh:639-644`, `scripts/lib/dev-cycle-read.sh:469-487`

---

## Claim 22: help, ok line: "TREE is the merge of TIP into main as merge-tree writes it, run where no repo config or checkout attributes are read; and no changed path is denied."

**Location:** `scripts/build-loop.sh:94-100`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the gate repository's config (core and extensions only), its empty work directory, and the ok condition. It does not cover the caller's own `GIT_CONFIG_*` env pairs, which harden deliberately keeps (`:185-187`).
**Legibility-target:** for-orchestrator-synthesis

- **Config.** gate_repo writes only `[core]\n\trepositoryformatversion = 1\n[extensions]\n\tobjectformat = %s` (`:504`).
- **Directory.** merge-tree runs in `$GATE_TMP/work` (`:512`).
- **Verdict.** `ok` is printed only when `nd` is 0 or there are no paths (`:610`, `:626`). The R9 test passes, and the ok lines in the changed tests carry the merge-tree tree.

**Evidence:** `scripts/build-loop.sh:497-530`, `scripts/build-loop.sh:610`, `scripts/build-loop.sh:626`, `$S/logs/check.log`

---

## Claim 23: help, refuse cases: "the merge (or its changed paths) could not be computed: git failed, or warned on stderr (a missing tree object), or the tree of main, TIP or a merge base is missing. Or 'the merge of BRANCH names a blob the object store lacks': a regular file the merge adds or changes names an object that is absent or not a blob. Or 'K of N changed paths refused in the merge of TIP (tree TREE)', when deny lines follow."

**Location:** `scripts/build-loop.sh:101-111`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers every check_line refusal and its trigger. It does not cover a missing blob on a path the merge deletes (old side only), which is never checked because it never lands.
**Legibility-target:** for-orchestrator-synthesis

- **Blob ids.** Collected only for regular new modes: `[[ "${nms[-1]}" != 100644 && "${nms[-1]}" != 100755 ]] || ids+=("${nos[-1]}")` (`:606`).
- **Check.** They are checked with `grep -cx blob` against `--batch-check='%(objecttype)'` (`:615-616`), which prints `missing` for an absent id (paraphrased — no quote available because this is git's batch-check output format; the R6 test's `mktree --missing` case exercises it).
- **Tests.** The R6 test passes and fails under mF2 and mR6. P1 (a missing subtree) gives "could not be listed", which falls under "its changed paths could not be computed".

**Evidence:** `scripts/build-loop.sh:579-628`, `$S/logs/mut-mF2.log`, `$S/logs/mut-mR6.log`, `$S/logs/probe1.log` (P1)

---

## Claim 24: help, path lines and N rules: "one line per path TREE changes against main (diff-tree -r --no-renames, so a rename is its D and A sides), in diff-tree's order; S … (A, M, D or T) and PATH is '?' unless every character is one pathform allows" and the deny list

**Location:** `scripts/build-loop.sh:114-129`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the parse, the display rule and every N rule named, against T11-T15. It does not cover S rules (U2c).
**Legibility-target:** for-orchestrator-synthesis

- **Parse.** The status class is `([AMDT])` (`:603`).
- **Display.** `shown="?"; [[ ! "$p" =~ ^[$NAMECHARS]+$ ]] || shown="$p"` (`:622`) uses pathform's own set, `set="^[$NAMECHARS]+\$"` (`scripts/lib/dev-cycle-read.sh:185`).
- **pathform.** It refuses `[.][gG][iI][tT]*` parts (`scripts/lib/dev-cycle-read.sh:191`), so ".git, any case" holds.
- **Tests.** T11, T12, T13, T14 and T15 pass.

**Evidence:** `scripts/build-loop.sh:114-129`, `scripts/build-loop.sh:553-627`, `scripts/lib/dev-cycle-read.sh:183-193`, `$S/logs/check.log`

---

## Claim 25: help, Exit: "0 every line printed (or help), and for --check every verdict line ok; 2 any --check verdict line or the state gate not ok; 1 bad usage, …"

**Location:** `scripts/build-loop.sh:137-139`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers check mode's exits. It does not re-check the status and settings exits, which this branch did not change.
**Legibility-target:** for-orchestrator-synthesis

- **Exit 2.** `[[ "$out" == "ok "* ]] || fails=1` then `[[ "$fails" -eq 0 ]] || exit 2` (`:647-649`). The state gates `exit 2` (`:257`, `:260`), and so does gate_repo's failure (`:643`).
- **Tests.** They assert status 0 for ok-only runs and status 2 for any refuse or skip line.

**Evidence:** `scripts/build-loop.sh:137-139`, `scripts/build-loop.sh:640-649`, `$S/logs/check.log`

---

## Claim 26: "GIT_CONFIG_NOSYSTEM: the system config is no more the gate's than the user's (merge.directoryRenames there flipped a conflict: A17)."

**Location:** `scripts/build-loop.sh:196-198`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the export and the directory-rename flip in P3. It does not cover other system keys.
**Legibility-target:** for-orchestrator-synthesis

The export line includes `GIT_CONFIG_NOSYSTEM=1` (`:198`), and GATE_ENV keeps every `GIT_CONFIG*` variable (`[[ "$v" == GIT_CONFIG* || … ]] || GATE_ENV+=(-u "$v")`, `:500`). In P3 the shipped script refuses a directory-rename merge as a conflict, and the copy without the variable prints ok.

**Evidence:** `scripts/build-loop.sh:196-198`, `scripts/build-loop.sh:500`, `$S/logs/probe1.log` (P3)

---

## Claim 27: state_gate comment: "filter drivers, every merge.* and diff.* key (drivers run commands), config hooks, includes, core.fsmonitor, core.attributesFile, core.hooksPath, gpg and log.showSignature …, and a partial clone … Files: an info/attributes, info/grafts or shallow that is not absent or an empty regular file"

**Location:** `scripts/build-loop.sh:199-211`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the regex and the file test. It does not cover config files outside the common dir and config.worktree.
**Legibility-target:** for-orchestrator-synthesis

The regex is `^(filter\.|include|hook\.|merge\.|diff\.|core\.fsmonitor|core\.attributesfile|core\.hookspath|gpg\.|log\.showsignature|extensions\.partialclone$|remote\..*\.promisor$)` (`:212`). The file test refuses a non-empty file, a symlink, or anything that exists and is not a regular file (`:226`).

**Evidence:** `scripts/build-loop.sh:199-235`

---

## Claim 28: default_gate comment: "once resolve_main has run (U3b's --state calls both): the default branch counts only when no other name could claim it. A loop can create a local master beside main … and point origin/HEAD at it, and resolve_main would follow (R7). Prints one line per finding, as state_gate does; returns 1 on any."

**Location:** `scripts/build-loop.sh:236-240`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers resolve_main's candidate order and default_gate's findings. It does not cover "U3b's --state calls both", which is a plan statement (the plan's --state line agrees, Claim 17).
**Legibility-target:** for-orchestrator-synthesis

resolve_main tries origin/HEAD's branch first: `[[ -n "$origin_head" ]] && candidates+=("${origin_head#origin/}")`, then `candidates+=(main master)` (`scripts/lib/dev-cycle-read.sh:494-495`). default_gate sets `bad=1` per finding and `return "$bad"` (`scripts/build-loop.sh:242-250`). The R7 test's both-findings case fails under mDG.

**Evidence:** `scripts/build-loop.sh:236-251`, `scripts/lib/dev-cycle-read.sh:490-512`, `$S/logs/mut-mDG.log`

---

## Claim 29: gate_git comment: "git in the gate repository, stdout passed through; returns git's status, or 3 when git wrote anything to stderr (a missing object can warn and still exit 0: R6)"

**Location:** `scripts/build-loop.sh:507-509`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the return codes and the warn-and-exit-0 case. It does not cover concurrent writes to the shared err file (row 509).
**Legibility-target:** for-orchestrator-synthesis

The code is `(cd "$GATE_TMP/work" && "${GATE_ENV[@]}" git "$@") 2>"$GATE_TMP/err" || rc=$?; [[ ! -s "$GATE_TMP/err" ]] || return 3; return "$rc"` (`:512-514`). Under mR6 the missing tip tree reads as empty, and the merge passed, so merge-tree exited 0 despite the missing object.

**Evidence:** `scripts/build-loop.sh:510-515`, `$S/logs/mut-mR6.log`

---

## Claim 30: merge_result comment: "returns 1 on a conflict (a gitlink both sides moved is one, since no submodule repository is reachable), 2 when git failed or warned, or the tree of main, the tip or a merge base is missing (R6)"

**Location:** `scripts/build-loop.sh:516-519`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers every return path. It does not cover a merge-tree that writes to stderr on an otherwise clean conflict (it would read as 2, not 1, which is still a refusal).
**Legibility-target:** for-orchestrator-synthesis

- **Return paths.** `[[ "$rc" -le 1 ]] || return 2` after merge-base (`:523`), the tree loop `|| return 2` (`:525`), `[[ "$rc" -le 1 && …hex… ]] || return 2` (`:527`) and `[[ "$rc" -eq 0 ]] || return 1` (`:528`).
- **Gitlink conflict.** The R9 test, where the real repository merges cleanly, expects `conflicts`, and passes.

**Evidence:** `scripts/build-loop.sh:516-530`, `test/scripts/build-loop-check.bats:1572-1586`, `$S/logs/check.log`

---

## Claim 31: own_blob comment: "main's copy with its first Status: line outside a fence, the one brief_fields reads (status_line has read it as 'Status: open'), reading 'Status: done', every other byte kept (a CR at its end too). Returns non-zero when a read fails; the caller checks it"

**Location:** `scripts/build-loop.sh:531-535`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers line selection, the substitution, CR handling, the exit status and the caller's check. It does not cover a race between own_blob's two reads (row 515).
**Legibility-target:** for-orchestrator-synthesis

- **Line selection.** Both readers use FENCE_AWK, `{ sub(/\r$/, "") } fence($0) { next }`, and take the first line starting `Status:`: own_blob `:540`, brief_fields `scripts/lib/dev-cycle-read.sh:368-371`.
- **Substitution.** `s/^Status: open(\r?)$/Status: done$1/ if $. == $ENV{N}` (`:542`) keeps the CR.
- **Open on main.** check_line refuses `st != open` (`:584`).
- **Caller.** It checks the status with `ob="$(own_blob "$1")" && [[ "$4" == "$ob" ]]` (`:559`). The pipeline's status is own_blob's return value under pipefail (`set -euo pipefail`, `:141`).
- **Tests.** T15 passes, including the CRLF brief.

**Evidence:** `scripts/build-loop.sh:536-543`, `scripts/build-loop.sh:559`, `scripts/lib/dev-cycle-read.sh:357-381`, `test/scripts/build-loop-check.bats:1475-1496`

---

## Claim 32: nrules comment: arguments "$2 $3 … $4 … $5 … $6 … $7"; "The brief's own file is matched exactly; the cycle's files (truthrule's cycle and settings words: writable() and docs/dev-cycle.md, plus anything under docs/working/briefs/ or docs/working/cycles/) and the constraints doc (its user word) compare lower-cased"

**Location:** `scripts/build-loop.sh:544-551`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the call site's argument order and the match rules. It does not cover the S rules.
**Legibility-target:** for-orchestrator-synthesis

The call is `nrules "$a" "${oms[$i]}" "${nms[$i]}" "${nos[$i]}" "${ss[$i]}" "$p" "${lps[$i]}"` (`:623`). The own-brief match is `[[ "$6" == "$1" ]]` (`:558`), and the cycle and constraints rules test `$7` (`:565-569`). T14's mixed-case paths (`Docs/Roadmap.md`, `docs/Dev-Cycle.md`, `docs/working/Questions.md`, `docs/CONSTRAINTS.md`) are denied.

**Evidence:** `scripts/build-loop.sh:544-572`, `test/scripts/build-loop-check.bats:1453-1473`

---

## Claim 33a: nrules invariant: "$7 is lower-cased, so the case word cannot fire; instr and dot, tested before cycle, match no cycle file, docs/dev-cycle.md or docs/constraints.md today"

**Location:** `scripts/build-loop.sh:562-564`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers today's INSTRUCTION_FILE, PROMPT_DIR, `.claude/rules/` and dot tests against writable()'s patterns and the two docs. It does not cover future words.
**Legibility-target:** for-orchestrator-synthesis

- **Lower-casing.** `lower_all` maps A-Z to a-z (`scripts/lib/dev-cycle-read.sh:857`). truthrule's case test is `*[ABCDEFGHIJKLMNOPQRSTUVWXYZ]*` (`:1091`), so it cannot fire on lower-cased input.
- **instr.** isstart needs a basename matching `^(claude|agents?|gemini)(\.…)?\.md$|^skill\.md$` or a `.claude/` part (`:516`, `:525`, `:529`). No writable() path has either: writable() covers `docs/roadmap.md`, `docs/working/{questions,questions-archive,idea-log}.md`, `cycles/cycle-DATE.md`, and briefs named `DATE-slug.md` (`:204-207`).
- **dot.** It needs a `/.` part, and none of those paths has one.

**Evidence:** `scripts/lib/dev-cycle-read.sh:198-207`, `scripts/lib/dev-cycle-read.sh:516-529`, `scripts/lib/dev-cycle-read.sh:857`, `scripts/lib/dev-cycle-read.sh:1089-1099`

---

## Claim 33b: "(T14 fails if one ever does: truthrule names this third consumer)"

**Location:** `scripts/build-loop.sh:564`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers two mutants of truthrule's instr word. It does not cover a dot-word mutant (same structure, not run).
**Legibility-target:** for-orchestrator-synthesis

Under mT14b (instr also matches `docs/roadmap.md`), T14 and T11 fail. Under mT14a (instr also matches anything under `docs/working/cycles/` or `docs/working/briefs/`), T14, T15 and T11 all pass. The `*)` fallback `[[ ! "$7" =~ ^docs/working/(briefs|cycles)/ ]] || DENY=…` (`:569`) still denies those paths with the same reason. So T14 fails when a shadowing word would open a path, but not for briefs or cycles, where a shadow is harmless. The precise wording is "T14 fails if one ever opens a covered path". The truthrule half holds: its comment now reads `build-loop.sh's N rules read its cycle, settings and user words too` (`scripts/lib/dev-cycle-read.sh:1077`).

**Evidence:** `scripts/build-loop.sh:562-570`, `$S/logs/mut-mT14a.log`, `$S/logs/mut-mT14b.log`

---

## Claim 34: check_line header comment: "'ok BRIEF TIP TREE' or 'refuse BRIEF: K of N changed paths refused in the merge of TIP (tree TREE)', then a 'path …' or 'deny …' line per path …; or one skip or refuse line (from status_line, then the gate's own reasons)"

**Location:** `scripts/build-loop.sh:573-578`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers check_line's outputs. It does not cover the caller's handling, which is Claim 25.
**Legibility-target:** for-orchestrator-synthesis

status_line's non-ok output is echoed alone (`[[ "$out" == "ok "* ]] || { echo "$out"; return; }`, `:582`). Every gate refusal is followed by `return` (`:584-620`). The final branches print the verdict and the rows (`:626-627`).

**Evidence:** `scripts/build-loop.sh:579-628`

---

## Claim 35: "Every record read whole: two NUL-ended fields each."

**Location:** `scripts/build-loop.sh:608-609`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers a record cut after its first NUL, which the check refuses, and a tail with no NUL at all, which it passes. It does not cover whether git can produce either (row 513).
**Legibility-target:** for-orchestrator-synthesis

The loop `while IFS= read -r -d '' meta && IFS= read -r -d '' p` (`:602`) stops without recording a final fragment, and the check compares `tr -cd '\000' … | wc -c` with `2 * ${#ps[@]}` (`:609`). probe3 fed two whole records followed by a meta field with no trailing NUL. It read 2 records and counted 4 NULs, so the check passes and the third fragment is dropped silently. A cut after the meta's NUL leaves an odd count, which the check refuses. The precise wording is "every NUL-ended field belongs to a record that was read". This is unreachable on the honest path: a failing diff-tree is refused at `:599-601`.

**Evidence:** `scripts/build-loop.sh:599-609`, `$S/logs/probe3.log`

---

## Claim 36: "merge-tree passes a side's unchanged blob by id without reading it, so a blob the store lacks would land unseen: every regular file the merge adds or changes must name a blob present in the store (a missing subtree already failed diff-tree)."

**Location:** `scripts/build-loop.sh:611-614`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers a missing blob on a one-sided addition (the R6 test, mF2) and a missing subtree passed by id (P1). It does not cover a missing blob both sides change, which merge-tree reads and fails on (iteration 2's probe, case E).
**Legibility-target:** for-orchestrator-synthesis

Under mF2, the R6 test's missing blob gives `ok … path … A new.txt` with status 0, so merge-tree did not read it. In P1, a tip whose subtree id is absent from the store gives `refuse …: the paths the merge of feat/x changes could not be listed`, which is diff-tree's refusal at `:599-601`.

**Evidence:** `scripts/build-loop.sh:611-618`, `$S/logs/mut-mF2.log`, `$S/logs/probe1.log` (P1)

---

## Claim 37: "One lower-casing pass for every path (a tr per path cost 1 to 2.5 ms each)."

**Location:** `scripts/build-loop.sh:619-620`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** This covers one 1,000-call measurement of the lib's `lower` through `$(…)` on this host. It does not cover other hosts or load levels.
**Legibility-target:** for-orchestrator-synthesis

`nul_list lps lower_all "${ps[@]}"` (`:620`) runs one `tr` over every path (`lower_all() { …; printf '%s\0' "$@" | tr … }`, `scripts/lib/dev-cycle-read.sh:857`). In probe2, 1,000 `$(lower …)` calls took 1,082 ms, which is 1.08 ms each and inside the stated range.

**Evidence:** `scripts/build-loop.sh:620`, `scripts/lib/dev-cycle-read.sh:852-857`, `$S/logs/probe2.log`

---

## Claim 38: lib contract item 5: "Ask floor about each changed path, in this shell, before main_entry … Floor item 5 … and the brief's own Status change are the caller's rules; build-loop.sh's N rules apply them, and pathform, under both policies before floor runs, so a path pathform refuses (.github/x.yml) is denied as a path form and floor's dotfile reason serves the dot paths pathform accepts (.envrc)."

**Location:** `scripts/lib/dev-cycle-read.sh:59-65`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the N rules' pathform, mode and own-brief steps, the `.github/w.yml` denial (T13), and pathform accepting `.envrc`. It does not cover "before floor runs", which is U2c's to honor because no floor call exists yet in build-loop.sh.
**Legibility-target:** for-orchestrator-synthesis

- **N rules.** nrules runs `pathform "$6"` first, then the mode rule, then the own-brief rule (`scripts/build-loop.sh:556-560`), and has no policy test.
- **pathform.** It refuses only parts matching `[.][gG][iI][tT]*` among dot parts (`scripts/lib/dev-cycle-read.sh:191`), so `.envrc` passes it.
- **T13.** It asserts `deny $B A .github/w.yml: $NFORM` and passes.

**Evidence:** `scripts/build-loop.sh:553-560`, `scripts/lib/dev-cycle-read.sh:184-193`, `test/scripts/build-loop-check.bats:1524-1531`

---

## Claim 39: truthrule comment edit: "build-loop.sh's N rules read its cycle, settings and user words too, so a word tested before them must never match a file those words cover"

**Location:** `scripts/lib/dev-cycle-read.sh:1077-1078`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the consumer and the word order. It does not cover the record word, which nrules ignores.
**Legibility-target:** for-orchestrator-synthesis

nrules' `case "$TRUTH_WHY" in cycle|settings) … user) …` (`scripts/build-loop.sh:566-568`) reads those words. truthrule tests case, then instr, then dot, then cycle, then settings, then user (`scripts/lib/dev-cycle-read.sh:1091-1096`).

**Evidence:** `scripts/build-loop.sh:565-570`, `scripts/lib/dev-cycle-read.sh:1089-1099`

---

## Claim 40: test comment: "# The fixture sets GIT_CONFIG_NOSYSTEM; unset, so the script's own setting is what the log shows (A17)." and the renamed shim test "… no global or system config and no transport (T26, A4, U2b1a i1, i2, A17)"

**Location:** `test/scripts/build-loop-check.bats:1375-1391`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the fixture export, the unset and the `S=1` assertion. It does not cover a git that never consults the variable.
**Legibility-target:** for-orchestrator-synthesis

The fixture runs `export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1` (`test/lib/build-loop-fixtures.bash:16`). The test runs `unset GIT_CONFIG_NOSYSTEM` (`:1382`), logs `S=$GIT_CONFIG_NOSYSTEM` per call, and requires `S=1` on every call. It passes.

**Evidence:** `test/scripts/build-loop-check.bats:1375-1391`, `test/lib/build-loop-fixtures.bash:16`, `$S/logs/check.log`

---

## Claim 41: test comment: "# Not commit_all: add -A would drop the gitlink, which has no directory (R9)."

**Location:** `test/scripts/build-loop-check.bats:1404`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers git 2.39.5's `add -A` on a cacheinfo gitlink with no directory. It does not cover other versions.
**Legibility-target:** for-orchestrator-synthesis

`commit_all() { git add -A && … }` (`test/lib/build-loop-fixtures.bash:29`). In P4, `git ls-files -s` lists `160000 … sub` before `git add -A` and lists nothing after it.

**Evidence:** `test/lib/build-loop-fixtures.bash:29`, `$S/logs/probe1.log` (P4)

---

## Claim 42: test name T14: "--check lists every changed path and refuses the dev cycle's own files, other briefs and the constraints doc in any case; other paths pass (T14, F2, F12, F54, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1453`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers 16 changed paths, four mixed-case spellings, a modified other brief and a new one, the diff-tree order, and the no-path ok case. It does not cover a closed brief with a real `DATE-slug` name. That case is covered by T15's move into closed/ (`:1491`).
**Legibility-target:** for-orchestrator-synthesis

The test asserts `"$(nref 15 16)"`, 17 lines in total, a deny line per cycle file (mode M for the other brief), both constraints spellings, `path $B A docs/ok.md`, `Docs/Roadmap.md` first and `docs/working/questions.md` last. It passes, and it fails under mT14b.

**Evidence:** `test/scripts/build-loop-check.bats:1453-1473`, `$S/logs/check.log`, `$S/logs/mut-mT14b.log`

---

## Claim 43: test name T15: "--check: the brief's own file may change only its first Status: line outside a fence, open to done (T15, F13, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1475`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the allowed change and five disallowed variants: the fenced line, open to dropped, an extra line, an exec bit, a trailing blank. It also covers a move to closed/ and CRLF. It does not cover a brief with no Status line (status_line skips it earlier).
**Legibility-target:** for-orchestrator-synthesis

The comment "Lines: 1 title, 2 blank, 3-5 a fence…, 6 the Status line, 7 Branch" (`:1478`) matches `brief()`, which writes `# Brief: %s\n\n` and then the lines (`test/lib/build-loop-fixtures.bash:52`). The test passes.

**Evidence:** `test/scripts/build-loop-check.bats:1475-1496`, `test/lib/build-loop-fixtures.bash:48-53`

---

## Claim 44: test name T11: "--check: a rename is its two sides, so moving a cycle file out refuses its old path (T11, F6, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1498`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers a pure `git mv` of the roadmap. It does not cover a rename with content changes (the same `--no-renames` path).
**Legibility-target:** for-orchestrator-synthesis

The test asserts `"$(nref 1 2)"`, `deny $B D docs/roadmap.md` and `path $B A docs/x.md`. It passes.

**Evidence:** `test/scripts/build-loop-check.bats:1498-1505`, `scripts/build-loop.sh:599`

---

## Claim 45: test name and comment T12: "… symlink or gitlink on either side, though submodule ignore=all is set, and passes an exec bit (T12, F7, A16, U2b1b)"; "The gate repository and the flag each suffice, so this pins them together."

**Location:** `test/scripts/build-loop-check.bats:1507-1510`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers new-side and old-side symlinks and gitlinks, exec bits on a modified and a new file, and the joint pin. It does not pin either A16 guard alone, which the comment itself says.
**Legibility-target:** for-orchestrator-synthesis

The test asserts the deny lines `T g.txt`, `A gl`, `A link`, `T og` and `T was-link`, and the path lines for `scripts/n.sh` and `scripts/x.sh`. Under the A16 mutants, mA16a and mA16c pass and mA16b fails, which matches "each suffice … pins them together".

**Evidence:** `test/scripts/build-loop-check.bats:1507-1522`, `$S/logs/mutants.log`

---

## Claim 46: test name T13: "--check refuses a changed path pathform refuses, and prints only a name in its character set (T13, F17, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1524`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers `.github/`, a space, a UTF-8 name, a newline and a leading `-`. It does not cover `.`/`..` parts, which git trees cannot hold.
**Legibility-target:** for-orchestrator-synthesis

The test asserts `"$(nref 5 5)"`, 6 lines, the named denials for `-x.md` and `.github/w.yml`, and three `?` lines. It passes.

**Evidence:** `test/scripts/build-loop-check.bats:1524-1531`

---

## Claim 47: test name R6: "--check refuses a merge git warned about or that names a missing object: a missing tip or merge-base tree is not read as empty, a missing blob does not land (R6, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1533`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the three cases: the tip tree, the merge-base tree (`main~1`, which is the merge base after `onx` and one main commit), and a missing blob. It does not pin either R6 guard alone (row 514).
**Legibility-target:** for-orchestrator-synthesis

The test passes on HEAD. It fails under mR6 (at the tip-tree case) and under mF2 (at the blob case, `:1550`).

**Evidence:** `test/scripts/build-loop-check.bats:1533-1551`, `$S/logs/mut-mR6.log`, `$S/logs/mut-mF2.log`

---

## Claim 48: test comment: "# merge-tree reads a missing top-level tree as empty, warns and exits 0 (a missing subtree or blob is fatal)."

**Location:** `test/scripts/build-loop-check.bats:1540`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the parenthetical, checked against the same test's blob case and P1. It does not cover the main clause, which held under mR6: the tip tree read as empty.
**Legibility-target:** for-orchestrator-synthesis

Five lines later the same test builds a missing blob that merge-tree passes silently: `# A blob the store lacks, which merge-tree passes by id without reading (security F2).` (`:1545`). Under mF2 that case prints ok. P1 shows the same for a missing subtree passed by id. The parenthetical holds only when merge-tree must read the object. a382a3f8's correction paragraph fixed this in the commit record but not here. The precise wording is "(a missing subtree or blob that merge-tree must read is fatal)". Row 514 carries the same wording (Claim 10).

**Evidence:** `test/scripts/build-loop-check.bats:1540-1550`, `$S/logs/mut-mF2.log`, `$S/logs/probe1.log` (P1)

---

## Claim 49: test name and comment R7: "--check refuses an ambiguous default branch: both main and master, or origin/HEAD naming a branch the gate did not take"; "Both findings at once: a master ref that names no commit is not taken, so origin/HEAD disagrees too."

**Location:** `test/scripts/build-loop-check.bats:1553-1561`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers four states: both branches with origin/HEAD, both without it, a tree-valued master with origin/HEAD at master, and master alone with origin/HEAD at main. It does not cover only main local with origin/HEAD at origin/master (iteration 1 probed it).
**Legibility-target:** for-orchestrator-synthesis

resolve_main skips a candidate whose `rev-parse --verify --quiet "$sha^{commit}"` is empty (`scripts/lib/dev-cycle-read.sh:500-501`), so a tree-valued master is not taken and MAIN stays main. The test passes. It fails under mR7, and under mDG at the both-findings assertion (`:1565`).

**Evidence:** `test/scripts/build-loop-check.bats:1553-1570`, `scripts/lib/dev-cycle-read.sh:490-512`, `$S/logs/mut-mDG.log`, `$S/logs/mut-mR7.log`

---

## Claim 50: test name R9: "--check's merge reads no submodule repository: a gitlink fast-forward the real repository would merge is a conflict (R9, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1572`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers a `.git/modules/sm` repository holding w, x and y, with the fixture checking that the real repository merges cleanly. It does not cover a submodule worktree checked out at `sub/`.
**Legibility-target:** for-orchestrator-synthesis

The test passes, and it fails under mR9, which runs merge-tree in the real repository.

**Evidence:** `test/scripts/build-loop-check.bats:1572-1586`, `$S/logs/mut-mR9.log`

---

## Claim 51: test name A15: "--check runs its state gate before resolve_main reads an object: a planted key refuses even with main's commit missing (A15, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1588`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the order of state_gate and resolve_main. It does not cover the order of state_gate and the earlier `git rev-parse --show-toplevel` (`:252`), which reads no object.
**Legibility-target:** for-orchestrator-synthesis

mA15 moves `state_gate || exit 2` after `main_by_name`. The test then fails with status 1 and "build-loop.sh needs a default branch found by name …".

**Evidence:** `scripts/build-loop.sh:256-260`, `test/scripts/build-loop-check.bats:1588-1594`, `$S/logs/mut-mA15.log`

---

## Claim 52a: commit cc9b69d3: the feature description, R7, R9, A15, A17, A19, "Tests: build-loop-check 101 (92 + 9), build-loop-read 19, dev-cycle 78, fixture-git-env 2, fixture-hermeticity 2; shellcheck clean. Mutants: R6 with both guards removed, R7 with the check off, R9 with merge-tree in the real repository each fail their test. 317 changed lines."

**Location:** commit `cc9b69d3` message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the test counts at cc9b69d3 (`git show cc9b69d3:… | grep -c '^@test'`), 317 lines, and the three mutants (run at HEAD, where those lines are unchanged). It does not cover the K-of-N text, which a382a3f8 later extended, or the probe parenthetical (52b).
**Legibility-target:** for-orchestrator-synthesis

- **Counts.** At main and cc9b69d3, `@test` counts are check 92 → 101, read 19, dev-cycle 78, and nine `+@test` lines were added. `git diff --shortstat main..cc9b69d3 -- scripts test` gives 282 insertions and 35 deletions, which is 317.
- **Verdict text.** cc9b69d3's line was `echo "refuse $a: $nd of $i changed paths refused"` (`git show cc9b69d3:scripts/build-loop.sh`, line 592), which matches its message.
- **Mutants.** mR6, mR7 and mR9 fail.

**Evidence:** `scripts/build-loop.sh:196-260`, `test/scripts/build-loop-check.bats:1440-1594`, `$S/logs/mutants.log`, `$S/logs/check.log`, `$S/logs/others.log`

---

## Claim 52b: commit cc9b69d3: "(a missing top-level tree is read as empty with exit 0; a missing subtree or blob is fatal, probed)"

**Location:** commit `cc9b69d3` message (R6 bullet)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the parenthetical. It does not cover the correction, which is in a382a3f8's message (Claim 54b).
**Legibility-target:** for-orchestrator-synthesis

A missing blob or subtree that merge-tree passes by id is not fatal: mF2 prints ok, and in P1 only diff-tree fails. a382a3f8 corrects this, and the rubric records it as Accepted-immutable (A4).

**Evidence:** `$S/logs/mut-mF2.log`, `$S/logs/probe1.log` (P1)

---

## Claim 52c: commit cc9b69d3 Notes: "the plan puts it in U2b1b's diff parse, rev 2 marked T12 refuse under both, and D3 makes a symlink a loop stop condition"

**Location:** commit `cc9b69d3` message (Notes)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** This covers the plan text at e02d056b and at 9b292d6f (the revision-2 plan). It does not establish "under both" for rev 2's T12.
**Legibility-target:** for-orchestrator-synthesis

- **Diff parse.** Step 5's U2b1b bullet puts "the raw `diff-tree -z` parse of MAIN→TREE with the mode rule" in U2b1b (`docs/working/plan-build-loop-handoff.md:283`).
- **D3.** It lists "a symlink" as a stop condition (`:55`).
- **Rev 2's T12.** At 9b292d6f the row reads `| T12 | Symlink added; file → symlink; exec bit; gitlink | refuse (mode) | integration |`, and F7 has no N/S mark in that table (paraphrased — no quote available because this is about an absent marker: the bypass table at 9b292d6f has no N/S column). "Under both" would need the rev-2 test strategy or a policy-qualified row, and neither was found.

**Evidence:** `docs/working/plan-build-loop-handoff.md:55`, `docs/working/plan-build-loop-handoff.md:283`, `git show 9b292d6f:docs/working/plan-build-loop-handoff.md` (lines 26-37, 169)

---

## Claim 53: commit 809df345: "Plan: F8 names the gate repository and --ignore-submodules=none (the -c diff.ignoreSubmodules=none form does not override a planted submodule.<name>.ignore=all); the --check interface line describes the verdict, path and deny lines; step 5's U2b1b note records what was built. Override log rows 497 and 507-511 gain their U2b1b resolution. R8 is left open with a proposal"

**Location:** commit `809df345` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the commit's content as committed, and P2. It does not cover the later staleness of the step-5 note and the --check line (Claims 18 and 19).
**Legibility-target:** for-orchestrator-synthesis

P2 confirms the F8 claim, and the plan and override-log edits are present as described.

**Evidence:** `docs/working/plan-build-loop-handoff.md:123`, `docs/working/plan-build-loop-handoff.md:212`, `docs/working/plan-build-loop-handoff.md:283`, `docs/reviews/override-log.md:497-511`, `$S/logs/probe1.log` (P2)

---

## Claim 54a: commit a382a3f8: the fix list (security F1, F2 with a mutant; one lower_all pass; the TIP/TREE verdict; default_gate; truthrule words; item 5; T14/T12 additions; row 511 names row 492); R8 decided and its declined rows; "Tests: build-loop-check 101 …; shellcheck clean on build-loop.sh (the lib's notes are on untouched lines). 367 code lines against main."

**Location:** commit `a382a3f8` message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers every listed fix in today's code, the F2 mutant, the counts, 367 lines, and the lines shellcheck flags in the lib. It does not cover the A16 mutant sentence (54b) or the 13.5 s figure (54c).
**Legibility-target:** for-orchestrator-synthesis

- **Lines.** `git diff --shortstat main..a382a3f8 -- scripts test` gives 328 insertions and 39 deletions, which is 367. Test counts there are 101, 19 and 78.
- **shellcheck.** It flags lib lines 818, 910, 916, 941, 1016, 1018 and 1023 (`$S/logs/probe3.log`). The branch's lib edits are at 56-66 and 1074-1078.
- **Mutant.** mF2 fails the R6 test.
- **Declined rows.** They match rows 512-517 (Claims 8-11).

**Evidence:** `scripts/build-loop.sh:536-628`, `scripts/lib/dev-cycle-read.sh:56-66`, `docs/reviews/override-log.md:511-517`, `$S/logs/probe3.log`, `$S/logs/mut-mF2.log`

---

## Claim 54b: commit a382a3f8: "A16 is pinned (T12 under submodule ignore=all in .gitmodules and the repo config; the mutant running diff-tree in the real repository fails it)."

**Location:** commit `a382a3f8` message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers three diff-tree mutants. It does not cover the commit's intent.
**Legibility-target:** for-orchestrator-synthesis

The real-repository mutant fails T12 only when `--ignore-submodules=none` is also dropped. mA16a (real repo, flag kept) passes and mA16b fails. Row 518 and the test comment at `:1509-1510` now record this as a joint pin.

**Evidence:** `$S/logs/mutants.log`, `docs/reviews/override-log.md:518`

---

## Claim 54c: commit a382a3f8: "performance F1: one lower_all pass per brief instead of a tr per path (measured 13.5 s at 5,000 paths as built)"

**Location:** commit `a382a3f8` message
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** This covers cc9b69d3's `--check` at 5,000 added paths on this host, in one run. It does not reproduce the 13.5 s figure, which depends on the host.
**Legibility-target:** for-orchestrator-synthesis

In probe3, cc9b69d3's script took 9,379 ms for 5,000 paths, against about 1,330 ms at HEAD (probe2). The roughly sevenfold gap and the mechanism (a `tr` per path, 1.08 ms each) are reproduced, but the absolute figure is not.

**Evidence:** `$S/logs/probe3.log`, `$S/logs/probe2.log`

---

## Claim 55a: commit e02d056b: each batch item, "performance F1, 5,000 paths now about 1.3 s", "Override rows: 509 …, 512 …, 517 …; new rows for A16's joint pin, the K-of-N TIP, the measured prices", "Tests: build-loop-check 101, …; shellcheck clean. 382 code lines against main.", "no behavior change but the refusal text"

**Location:** commit `e02d056b` message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the code diff a382a3f8..e02d056b, the counts, 382 lines, the 1.3 s figure, the new rows 518-520, and the R7 test change. It does not cover "plan F12 and the --state line match the code" beyond those two lines: the --check line beside them is stale (Claim 18).
**Legibility-target:** for-orchestrator-synthesis

- **Code diff.** The only non-comment changes in `scripts/` are dropping a trailing comment on `truthrule "$7" || true` and `names a file` → `names a blob` (`git diff a382a3f8 e02d056b -- scripts`).
- **Lines.** `--shortstat main..e02d056b -- scripts test` gives 343 insertions and 39 deletions, which is 382.
- **Timing.** probe2 measured 1,323-1,341 ms.
- **R7 test.** mDG fails its new both-findings assertion.
- **Suites.** All pass, and shellcheck exits 0.

**Evidence:** `scripts/build-loop.sh:562-570`, `scripts/build-loop.sh:617`, `docs/reviews/override-log.md:518-520`, `$S/logs/probe2.log`, `$S/logs/mut-mDG.log`, `$S/logs/others.log`

---

## Claim 55b: commit e02d056b correction: "a missing subtree passed by id is refused by diff-tree ('could not be listed'), not by the missing-blob check, which covers blobs."

**Location:** commit `e02d056b` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers a one-sided addition of a directory whose subtree id is absent. It does not cover a subtree both sides change, which merge-tree reads and fails on.
**Legibility-target:** for-orchestrator-synthesis

P1 prints `refuse docs/working/briefs/2026-10-01-x.md: the paths the merge of feat/x changes could not be listed`, with rc 2. The batch-check only collects ids with a regular-file mode (`scripts/build-loop.sh:606`).

**Evidence:** `scripts/build-loop.sh:599-618`, `$S/logs/probe1.log` (P1)

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
- **Claim 18** (`docs/working/plan-build-loop-handoff.md:212`): the --check interface line gives the refusal as `refuse BRIEF: K of N changed paths refused`. The code says `… refused in the merge of TIP (tree TREE)` (since a382a3f8).
- **Claim 19** (`docs/working/plan-build-loop-handoff.md:283`): step 5's U2b1b note still says "R8 is proposed as a Q-103 residual for its review to decide". It was decided at iteration 1 (row 509, step 13).

### Mostly Accurate
- **Claim 10** (`docs/reviews/override-log.md:514`) and **Claim 48** (`test/scripts/build-loop-check.bats:1540`): "a missing subtree or blob is fatal" should read "… that merge-tree must read is fatal". One passed by id is silent, as the same test's blob case shows.
- **Claim 20** (`docs/working/plan-build-loop-handoff.md:305`): step 13's R8 surface list omits `git/refs/` and `git/HEAD`, which row 509 names.
- **Claim 21b** (`scripts/build-loop.sh:91-92`): "refuse state gate:" comes after open_shared has read the open briefs. It is "before any verdict line", not "before any brief is read".
- **Claim 33b** (`scripts/build-loop.sh:564`): T14 fails only when a shadowing word would open a covered path. A shadow over briefs/ or cycles/ is masked by the `*)` fallback (mT14a passes).
- **Claim 35** (`scripts/build-loop.sh:608`): the NUL-count check passes a trailing fragment with no NUL and drops it silently. It catches a record cut after its first NUL. This is unreachable with real diff-tree output.
- **Claim 52b** (commit cc9b69d3) and **Claim 54b** (commit a382a3f8): commit messages, immutable. They are corrected or recorded elsewhere (a382a3f8's correction; row 518).
- **Claim 54c** (commit a382a3f8): "13.5 s at 5,000 paths" re-measured as 9.4 s here. The magnitude and mechanism are reproduced, but the figure depends on the host.

### Unverifiable
- **Claim 52c** (commit cc9b69d3 Notes): "rev 2 marked T12 refuse under both". Rev 2's T12 row says "refuse (mode)" with no policy mark, so the rev-2 test strategy would be needed to confirm "under both".

---

## Goal-Alignment Note

The user's goal is to land U2b1b after a clean review-fix loop, and this terminal pass decides that by its amber inventory. This replicate found no Incorrect claim.

**Behavior.** Every behavioral claim the gate makes about itself held under execution:
- the help's refusal cases and N rules;
- R6, R7, R9, A15, A16 and A17, each probed or mutated at HEAD;
- the F2 batch-check;
- the e02d056b correction.

All eleven mutants behaved as the docs say. That includes the A16 joint pin (either guard alone passes T12) and the truthrule-order invariant (mT14b fails T14).

**Counts.** The 101/19/78/2/2 tallies and the 317/367/382 line counts are exact. The 5,000-path price (about 1.33 s) reproduces.

**Ambers (wording only).**
- Two stale plan lines: the `--check` interface line's refusal text, and step 5's "R8 is proposed".
- One overbroad parenthetical, "a missing subtree or blob is fatal", in the R6 test comment and row 514.
- Step 13's R8 surface missing `git/refs/` and `git/HEAD`.
- The "refuse state gate: … before any brief is read" timing.
- "T14 fails if one ever does" (true where it matters).
- The NUL-count check's unreachable tail case.
- Immutable commit-message points already recorded elsewhere.

None changes what the code does or weakens an honest-path guarantee. All are honest-path documentation drift; none is a Q-103 (hostile-loop) class issue. The two stale plan lines and the test comment are one-line edits if the loop wants a clean doc state before merging.
