Commit: e02d056b
**Replication:** k=3, replicate r1 (final confirming pass, full branch)

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2b1b (branch `feat/build-loop-u2b1b`)
**Scope:** full branch, `git diff main...HEAD` (cc9b69d3, 809df345, a382a3f8, e02d056b). Checked: the four commit messages; the override-log rows this branch added or edited (494, 497, 507-511, 512-520); the plan's edited lines (F8, F12, `--state`, `--check`, step 5's U2b1b note, step 13); `scripts/build-loop.sh` (the help and every changed comment); the two comment edits in `scripts/lib/dev-cycle-read.sh`; every added or renamed test in `test/scripts/build-loop-check.bats`. The review reports added on the branch are not checked.
**Checked:** 2026-10-08
**Total claims checked:** 40
**Summary:** 33 verified, 4 mostly accurate, 2 stale, 1 incorrect, 0 unverifiable (40 verdicts: claims 1-38, with 23 and 26 each split into a and b)

Execution provenance (shared by every `executed` claim below). Scratch dir `S=/tmp/claude-1000/-workspace/0c855a7c-1c04-4bab-8bf1-7620be67b78e/scratchpad/u2b1b-i3/fc-r1`. Host: git 2.39.5, bash 5.2, WSL2.
- **Suites.** These ran at HEAD e02d056b from the worktree (through the `scratchpad/wt` symlink), starting 2026-10-08T22:16:24Z. Each used `TMPDIR=$(mktemp -d -p $S) timeout 900 bats test/scripts/<suite>.bats` (fixture-hermeticity from `test/`). Results: build-loop-check 101 ok, build-loop-read 19, dev-cycle 78, fixture-git-env 2, fixture-hermeticity 2, every one exit 0. `shellcheck scripts/build-loop.sh` exited 0. Logs: `$S/logs/<suite>.log` and `$S/logs/shellcheck.log`.
- **Mutants.** Each is a `git archive e02d056b scripts test` copy in `$S/<mutant>/`, changed by one perl substitution. Each ran `TMPDIR=… LC_ALL=C bats -f 'T11|T12|T13|T14|T15|R6, U2b1b|R7, U2b1b|R9, U2b1b|A15, U2b1b|A17\)' test/scripts/build-loop-check.bats` from its copy, starting 2026-10-08T22:17:00Z. Logs: `$S/logs/mut-<mutant>.log`. Results:
  - `base`: 10/10 ok, exit 0.
  - `mR6both` (both R6 guards removed): exit 1, only R6 fails.
  - `mR6err` (stderr guard only) and `mR6tree` (tree-existence guard only): both exit 0.
  - `mR7` (default_gate off): exit 1, only R7 fails.
  - `mR9` (merge-tree in the real repository): exit 1, only R9 fails.
  - `mA17` (GIT_CONFIG_NOSYSTEM removed): exit 1, only the shim test fails.
  - `mA15` (state_gate moved after resolve_main): exit 1, only A15 fails.
  - `mF2` (batch-check off): exit 1, only R6 fails.
  - `mMode` (own brief's `"$2" == "$3"` dropped): exit 1, only T15 fails.
  - `mA16a` (diff-tree in the real repository) and `mA16b` (no `--ignore-submodules=none`): both exit 0.
  - `mA16both`: exit 1, only T12 fails.
  - `mNUL` (NUL-count check replaced by `false`): ran the whole build-loop-check suite at 2026-10-08T22:20:21Z, 101/101 ok, exit 0.
- **Probes.** Each probe script starts with `set -eu`, makes its own `mktemp -d -p $S` and refuses to run outside it. Each is logged to `$S/logs/<probe>.log` and exited 0.
  - `probe1.sh` at 22:18:29Z: P2, the real repository's diff-tree under `submodule.gl.ignore=all`. (Its P1 attempt did not delete the subtree, so it is superseded by probe2.)
  - `probe2.sh` at 22:18:56Z: P1b, a missing subtree passed by id; P3, truthrule's words.
  - `probe3.sh` at 22:19:09Z: P4, timing.
  - `probe4.sh` at 22:20:12Z: P5, the old submodule fixture's merge base.
  - An inline loop at about 22:22Z for the NUL-fragment case, logged to `$S/logs/probe-frag.log`.
- **Hallucination-pattern log.** I read `docs/reviews/hallucination-patterns.md`. No claim here matches a logged fabrication pattern. The test-tally pattern was checked by running the suites, and the tallies match.

---

## Claim 1: cc9b69d3: "Mutants: R6 with both guards removed, R7 with the check off, R9 with merge-tree in the real repository each fail their test."

**Location:** commit cc9b69d3 message; `scripts/build-loop.sh:510-529`, `scripts/build-loop.sh:241-251`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the three named mutants against HEAD's tests: each fails only its own test. It does not cover the same mutants against cc9b69d3's tests, which differ only in the R7 test's middle block and the missing-blob clause added later.
**Legibility-target:** for-orchestrator-synthesis

The guards the mutants removed:
```bash
# scripts/build-loop.sh:512-513 (gate_git, whole body :510-515 read)
  (cd "$GATE_TMP/work" && "${GATE_ENV[@]}" git "$@") 2>"$GATE_TMP/err" || rc=$?
  [[ ! -s "$GATE_TMP/err" ]] || return 3
# scripts/build-loop.sh:525 (merge_result, :520-529 read)
  for b in "$MAIN_SHA" "$1" $bases; do gate_git cat-file -e "$b^{tree}" || return 2; done
```
Results: `mR6both` fails "R6, U2b1b", `mR7` fails "R7, U2b1b" and `mR9` fails "R9, U2b1b". Each other filtered test stayed ok.

**Evidence:** `scripts/build-loop.sh:241-251`, `scripts/build-loop.sh:510-529`, `$S/logs/mut-mR6both.log`, `$S/logs/mut-mR7.log`, `$S/logs/mut-mR9.log`, `$S/logs/mut-base.log`

---

## Claim 2: cc9b69d3, a382a3f8, e02d056b: test counts ("build-loop-check 101 (92 + 9), build-loop-read 19, dev-cycle 78, fixture-git-env 2, fixture-hermeticity 2; shellcheck clean") and code-line counts (317, 367, 382)

**Location:** commit messages cc9b69d3, a382a3f8, e02d056b; plan `docs/working/plan-build-loop-handoff.md:283` ("cc9b69d3, 317 lines")
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the suite counts at HEAD (only build-loop-check.bats changes on the branch, so the other counts are the same at each commit) and the `@test` counts and line counts at each commit. It does not re-run the suites at cc9b69d3 or a382a3f8.
**Legibility-target:** for-orchestrator-synthesis

`git show <c>:test/scripts/build-loop-check.bats | grep -c '^@test'` gives main 92, and 101 at cc9b69d3, a382a3f8 and e02d056b. `git diff --numstat main <c> -- scripts test`, adds plus deletes, gives 282+35=317 at cc9b69d3, 328+39=367 at a382a3f8 and 343+39=382 at e02d056b. The suites at HEAD passed 101/19/78/2/2, and shellcheck exited 0 (provenance above).

**Evidence:** `$S/logs/build-loop-check.log`, `$S/logs/build-loop-read.log`, `$S/logs/dev-cycle.log`, `$S/logs/fixture-git-env.log`, `$S/logs/fixture-hermeticity.log`, `$S/logs/shellcheck.log`

---

## Claim 3: cc9b69d3: the N rules and output ("path BRIEF S PATH" or "deny BRIEF S PATH: WHY"; verdict "ok BRIEF TIP TREE" only when nothing is denied; PATH "?" unless pathform's characters; modes in {absent, 100644, 100755}; the own brief's Status line open→done byte for byte, mode kept; cycle files and docs/constraints.md lower-cased), and R7/R9/A15/A17/A19 as described

**Location:** commit cc9b69d3 message; `scripts/build-loop.sh:553-571`, `scripts/build-loop.sh:579-628`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers each listed rule and carried fix against HEAD's code and passing tests. It does not cover the verdict's later " in the merge of TIP (tree TREE)" suffix, which cc9b69d3's own wording ("K of N changed paths refused") predates and a382a3f8 states.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:556-558
  if ! pathform "$6"; then DENY="not an allowed path form (...)"
  elif [[ ! "$2 $3" =~ ^(000000|100644|100755)\ (000000|100644|100755)$ ]]; then DENY="a symlink, gitlink ..."
  elif [[ "$6" == "$1" ]]; then
```
(excerpt ends :558; enclosing nrules() continues to :571 — read). Claims 1, 30-36 and 38 cover the tests that pin each rule. A19's help and comment items match the main→HEAD diff of the header (`refuse state gate:`, "not an empty file", the verdict-line exit wording, shallow and origin/HEAD in the state list).

**Evidence:** `scripts/build-loop.sh:80-139`, `scripts/build-loop.sh:553-628`, `$S/logs/build-loop-check.log`

---

## Claim 4: cc9b69d3: "R6: … (a missing top-level tree is read as empty with exit 0; a missing subtree or blob is fatal, probed)"

**Location:** commit cc9b69d3 message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the parenthetical's subtree half for a subtree the tip passes by id. It does not re-probe the top-level-tree half, which a382a3f8's correction qualifies ("exiting 0 only when that merge is otherwise clean") and iteration 2's fact-check probed.
**Legibility-target:** for-orchestrator-synthesis

P1b: the tip adds `newdir/`, a tree whose object was then deleted. merge-tree did not fail. merge_result returned 0, and the refusal came from diff-tree:
```
refuse docs/working/briefs/2026-10-01-x.md: the paths the merge of feat/x changes could not be listed
```
So "a missing subtree … is fatal" is false for a subtree passed by id. This is already corrected in a382a3f8's correction paragraph ("fatal only when merge-tree must read it") and in e02d056b's ("refused by diff-tree"). The commit message is immutable and the record is complete. Nothing more is needed than the existing corrections; listed because the claim as written is refuted.

**Evidence:** `$S/probe2.sh`, `$S/logs/probe2.log`, `scripts/build-loop.sh:597-600`

---

## Claim 5: 809df345: "Plan: F8 names the gate repository and --ignore-submodules=none (the -c diff.ignoreSubmodules=none form does not override a planted submodule.<name>.ignore=all)"; plan F8 row text to the same effect

**Location:** commit 809df345 message; `docs/working/plan-build-loop-handoff.md:123`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers git 2.39.5's plumbing `diff-tree -r --raw` in a repository with `submodule.gl.ignore=all` in `.gitmodules` and the repo config. It does not cover other git versions.
**Legibility-target:** for-orchestrator-synthesis

P2 output: plain `diff-tree` printed nothing, `-c diff.ignoreSubmodules=none` printed nothing, and `--ignore-submodules=none` printed `:000000 160000 … A	gl`. The code uses the flag in the gate repository:
```bash
# scripts/build-loop.sh:599
  if ! gate_git diff-tree -r --no-renames --raw -z --ignore-submodules=none "$MAIN_SHA" "$tree" > "$GATE_TMP/diff"; then
```

**Evidence:** `$S/probe1.sh`, `$S/logs/probe1.log`, `scripts/build-loop.sh:597-600`

---

## Claim 6: a382a3f8: the fixed items (security F1 own_blob status; F2 one batch-check, "mutant fails"; performance F1 one lower_all pass; api 1 TIP and TREE in the verdict; api 2/arch 5 default_gate printing every finding; arch 1 nrules reads truthrule's words; arch 2 contract item 5; T14, T12 additions; R8 decided; 367 lines)

**Location:** commit a382a3f8 message; `scripts/build-loop.sh:536-628`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers each item against HEAD: mF2 fails R6, and T14 includes `docs/working/Questions.md` and `docs/CONSTRAINTS.md`. It does not cover the "13.5 s at 5,000 paths as built" figure (iteration 1's performance report gives 13,460 ms; I did not rebuild cc9b69d3), or the "names a file the object store lacks" wording, which was accurate at a382a3f8 and changed to "a blob" in e02d056b.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:562-566 … :619-620
    truthrule "$7" || true
    case "$TRUTH_WHY" in
      cycle|settings) DENY="one of the dev cycle's own files" ;;
  if ! nul_list lps lower_all "${ps[@]}" || [[ ${#lps[@]} -ne ${#ps[@]} ]]; then
```
(excerpt ends :566; nrules() continues to :571 — read). The verdict prints `refuse $a: $nd of ${#ps[@]} changed paths refused in the merge of $sha (tree $tree)` (`scripts/build-loop.sh:626`).

**Evidence:** `scripts/build-loop.sh:536-628`, `test/scripts/build-loop-check.bats:1453-1473`, `$S/logs/mut-mF2.log`, `docs/reviews/performance-reviewer-review-2026-10-08-build-loop-u2b1b.md:29`

---

## Claim 7: a382a3f8 correction paragraph: "a missing subtree or blob is fatal only when merge-tree must read it (one passed by id is silent, which security F2 now refuses)"

**Location:** commit a382a3f8 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the passed-by-id behaviour (confirmed for a subtree by P1b) and which check refuses each kind. It does not re-probe a missing blob merge-tree must read.
**Legibility-target:** for-author

"Which security F2 now refuses" holds for blobs. For a missing subtree, merge-tree is silent and diff-tree refuses it ("could not be listed", P1b), not F2's batch-check. e02d056b's correction paragraph says exactly this, so the record is already complete.

**Evidence:** `$S/logs/probe2.log`, `scripts/build-loop.sh:611-617`

---

## Claim 8: e02d056b: items and Notes ("help says pathform refuses a part starting .git in any case"; "names a blob the object store lacks … as its own case"; the fact-check i2 1-5 wording; "the R7 test now shows default_gate printing both findings"; plan F12 and --state; override rows 509, 512, 517 and three new rows; "5,000 paths now about 1.3 s"; correction paragraph; 382 lines; "no behavior change but the refusal text")

**Location:** commit e02d056b message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers each item against `git diff a382a3f8 e02d056b`, P1b (the correction), P4 (timing) and the suites. It does not cover the iteration-2 reviewers' own findings beyond the rubric's summary of them ("no red").
**Legibility-target:** for-orchestrator-synthesis

The a382a3f8→e02d056b diff of `scripts/` changes only comments, help text and one echo (`names a file` → `names a blob`, `scripts/build-loop.sh:616`), which bears out "no behavior change but the refusal text". The test diff adds the R7 two-finding block and rewords two lines. P4 measured 1,295, 1,312 and 1,309 ms at 5,000 added paths. The rubric reads "ITERATION 2 — no red" (`docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1b.md:5`).

**Evidence:** `scripts/build-loop.sh:101-128`, `scripts/build-loop.sh:531-535`, `scripts/build-loop.sh:611-619`, `$S/logs/probe3.log`, `$S/logs/probe2.log`

---

## Claim 9: override row 494 addition: "the gate repository closes merge-tree" holds against state planted before the run, not against a concurrent same-uid writer (R8, row 509)

**Location:** `docs/reviews/override-log.md:494`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the row's cross-reference and the fact that gate_repo writes files a same-uid writer can reach under `$GATE_TMP` (`scripts/build-loop.sh:497-506`). It does not cover a race probe, which this pass did not run.
**Legibility-target:** for-orchestrator-synthesis

`printf '[core]\n\trepositoryformatversion = 1\n…' > "$GATE_TMP/git/config"` (`scripts/build-loop.sh:504`) is written after `mkdir`, in the caller's `mktemp -d` (`scripts/build-loop.sh:640`). Row 509 holds R8.

**Evidence:** `scripts/build-loop.sh:488-506`, `scripts/build-loop.sh:640`, `docs/reviews/override-log.md:509`

---

## Claim 10: override row 497 addition: "the first line is the verdict line; path and deny lines follow it, and the help says 'every verdict line ok'"

**Location:** `docs/reviews/override-log.md:497`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers check_line's output order and the main loop's exit test. It does not cover `--merge`.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:643-647
    for a in "${ARGS[@]}"; do
      out="$(check_line "$a")"; printf '%s\n' "$out"
      [[ "$out" == "ok "* ]] || fails=1
    done
    [[ "$fails" -eq 0 ]] || exit 2
```
The help reads `# Exit: 0 every line printed (or help), and for --check every verdict line ok;` (`scripts/build-loop.sh:137`). T14 checks `lines[0]` as the verdict, followed by 16 path lines.

**Evidence:** `scripts/build-loop.sh:137-139`, `scripts/build-loop.sh:626-627`, `scripts/build-loop.sh:635-649`, `$S/logs/build-loop-check.log`

---

## Claim 11: override row 507: "Fixed in cc9b69d3 … the test fails with both guards removed"; row 514: "Each R6 guard … passes the R6 test alone … The test pins their union (the double mutant fails)"

**Location:** `docs/reviews/override-log.md:507`, `docs/reviews/override-log.md:514`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the three mutants against the R6 test. It does not cover row 514's "no case found where only stderr catches it" beyond the R6 test's cases.
**Legibility-target:** for-orchestrator-synthesis

`mR6both` exit 1 (R6 not ok); `mR6err` exit 0; `mR6tree` exit 0.

**Evidence:** `scripts/build-loop.sh:510-529`, `test/scripts/build-loop-check.bats:1533-1551`, `$S/logs/mut-mR6both.log`, `$S/logs/mut-mR6err.log`, `$S/logs/mut-mR6tree.log`

---

## Claim 12: override row 508: "Fixed in cc9b69d3: --check refuses both main and master, or origin/HEAD naming a branch other than the one taken (`refuse state default-branch:`)"; row 510: "a new one merges a gitlink fast-forward that the real repository resolves cleanly; merge-tree in the real repository fails it"

**Location:** `docs/reviews/override-log.md:508`, `docs/reviews/override-log.md:510`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers default_gate's two findings and the R9 test under its mutant. It does not cover `--status` (which, as row 517 records, has no default-branch refusal).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:243-249 (default_gate, :241-251 read)
  if git show-ref --verify --quiet refs/heads/main && git show-ref --verify --quiet refs/heads/master; then
    echo "refuse state default-branch: both main and master exist"; bad=1
  fi
  p="$(git symbolic-ref -q refs/remotes/origin/HEAD)" || true
  if [[ -n "$p" && "$p" != "refs/remotes/origin/$MAIN" ]]; then
```
(excerpt ends :247; default_gate() continues to :251 — read). `mR7` and `mR9` each fail their test. The R9 test asserts `git merge-tree --write-tree main feat/x` succeeds in the real repository (`test/scripts/build-loop-check.bats:1582`).

**Evidence:** `scripts/build-loop.sh:241-260`, `test/scripts/build-loop-check.bats:1553-1586`, `$S/logs/mut-mR7.log`, `$S/logs/mut-mR9.log`

---

## Claim 13: override row 509 additions: R8 decided a Q-103 residual; surface `$GATE_TMP/git/config`, `git/info/`, `work/.gitattributes`, `err`, `diff` ("merge-base, cat-file, diff-tree and hash-object now run there too"); i2: "also holds git/refs/ and git/HEAD; the missing-blob batch-check adds one more gate_git call"

**Location:** `docs/reviews/override-log.md:509`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the list of files gate_repo and gate_git write and the gate_git callers. It does not cover whether the race is exploitable (the threat-scope decision is the reviewers').
**Legibility-target:** for-orchestrator-synthesis

gate_repo makes `"$GATE_TMP/git" "$GATE_TMP/git/refs" "$GATE_TMP/work"` and writes `git/HEAD` and `git/config` (`scripts/build-loop.sh:501-504`). gate_git writes `$GATE_TMP/err` (`:512`), and check_line writes `$GATE_TMP/diff` (`:599`). gate_git callers are merge-base, `cat-file -e`, merge-tree (`:522-526`), diff-tree (`:599`), hash-object (`:542`) and `cat-file --batch-check` (`:614`) (paraphrased — no quote available because the callers span four functions; each line is cited).

**Evidence:** `scripts/build-loop.sh:497-529`, `scripts/build-loop.sh:536-543`, `scripts/build-loop.sh:599`, `scripts/build-loop.sh:614`

---

## Claim 14: override row 511 additions: A15 test added; A16 diff-tree in the gate repository with --ignore-submodules=none; A17 GIT_CONFIG_NOSYSTEM=1; "A18 not changed (no new history walk but merge-base --all, one per brief)"; i1: row 492 "does not yet name alternates, packs or the multi-pack-index"

**Location:** `docs/reviews/override-log.md:511`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers each item against code, tests and mutants (mA15 and mA17 fail their tests), plus row 492's text. It does not re-measure A18's quoted merge-base prices (3/50/306 ms), which come from iteration 1's performance report.
**Legibility-target:** for-orchestrator-synthesis

On main, merge_result ran merge-tree alone. At HEAD it adds `bases="$(gate_git merge-base --all "$MAIN_SHA" "$1")"` (`scripts/build-loop.sh:522`), once per check_line call. `grep -ci 'alternates\|multi-pack'` on row 492 returns 0.

**Evidence:** `scripts/build-loop.sh:196-198`, `scripts/build-loop.sh:520-529`, `docs/reviews/override-log.md:492`, `$S/logs/mut-mA15.log`, `$S/logs/mut-mA17.log`

---

## Claim 15: override row 512 (i2): "a382a3f8 split check_line into collect, batch-check and judge phases (the seam); nrules takes seven positional arguments and trusts that $7 is lower($6)"

**Location:** `docs/reviews/override-log.md:512`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers check_line's structure at cc9b69d3 against HEAD. It does not cover U3's future interface.
**Legibility-target:** for-orchestrator-synthesis

At cc9b69d3 one loop parsed and judged each record: `nrules "$a" "$om" "$nm" "$no" "$s" "$p"` sat inside the `while read` loop. At HEAD the loop collects only (`scripts/build-loop.sh:602-607`), the batch-check follows (`:614-617`), and a second loop judges with `nrules "$a" "${oms[$i]}" … "$p" "${lps[$i]}"` (`:622`), which takes seven arguments.

**Evidence:** `scripts/build-loop.sh:579-628`, `git show cc9b69d3:scripts/build-loop.sh` check_line

---

## Claim 16: override row 513: "No test pins check_line's NUL-count completeness check (a mutant removing it passes) … git's own diff-tree -z output never ends mid-record"

**Location:** `docs/reviews/override-log.md:513`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the mutant against the whole build-loop-check suite. It does not cover git versions other than 2.39.5 for "never ends mid-record".
**Legibility-target:** for-orchestrator-synthesis

`mNUL` (`if false; then echo "refuse $a: the paths the merge of $br changes could not be read"; …`) passed 101/101.

**Evidence:** `scripts/build-loop.sh:608-609`, `$S/logs/mut-mNUL.log`

---

## Claim 17: override rows 515-517 (own_blob's race untested; own_blob repeats brief_fields' awk and drift fails closed; informational U2c/--status notes, i2 "U2c also states whether floor runs on a path the N rules already denied")

**Location:** `docs/reviews/override-log.md:515-517`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the code facts the rows rest on. It does not cover the dispositions (Won't-Fix and Defer are review decisions).
**Legibility-target:** for-orchestrator-synthesis

own_blob's awk is `'{ sub(/\r$/, "") } fence($0) { next } !n && /^Status:/ { n = NR } …'` (`scripts/build-loop.sh:540`). brief_fields uses the same prefix with `match($0, /^(Status|…):/)` and keeps the first (`scripts/lib/dev-cycle-read.sh:365-370`). If the two drift, the own brief's blob mismatches and the path is denied (`scripts/build-loop.sh:559-560`). build-loop.sh calls no floor (`grep -c floor` = 0).

**Evidence:** `scripts/build-loop.sh:536-543`, `scripts/build-loop.sh:559-560`, `scripts/lib/dev-cycle-read.sh:357-380`

---

## Claim 18: override row 518: "A16's two guards … are pinned only together: either alone passes T12 … T12 fails when both go; the test comment says so"

**Location:** `docs/reviews/override-log.md:518`; `test/scripts/build-loop-check.bats:1509-1510`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the three A16 mutants against T12. It does not cover other configs that could hide a gitlink.
**Legibility-target:** for-orchestrator-synthesis

`mA16a` exit 0, `mA16b` exit 0, `mA16both` exit 1 (T12 not ok). The comment reads `# --ignore-submodules=none would hide gl (A16). The gate repository and the flag each suffice, so this pins them together.`

**Evidence:** `test/scripts/build-loop-check.bats:1507-1522`, `$S/logs/mut-mA16a.log`, `$S/logs/mut-mA16b.log`, `$S/logs/mut-mA16both.log`

---

## Claim 19: override row 519: "The K-of-N verdict names the merge by TIP while six sibling refusals name it by branch"

**Location:** `docs/reviews/override-log.md:519`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** This covers the count of distinct merge-related refusal texts in check_line that name `$br`. It does not cover the refusals before the merge (branch absent, moved, no commit, tip mismatch), which also name the branch but are not about the merge.
**Legibility-target:** for-orchestrator-synthesis

The merge-related texts naming `$br` are: `$br conflicts` (`:592`), `could not be computed` (`:593`), `could not be listed` (`:600`), `could not be read` (`:604`, `:609`, one text), `names a blob` (`:616`) and `could not be lower-cased` (`:620`). That makes six distinct texts. Medium confidence because "six" depends on counting distinct texts, not occurrences (seven).

**Evidence:** `scripts/build-loop.sh:590-626`

---

## Claim 20: override row 520: "--check is linear at about 0.25 ms per path (1,326 ms at 5,000 …)"; "the missing-blob batch-check about 0.1 s per 5,000 new files"; "truthrule … about 0.07 ms per path"

**Location:** `docs/reviews/override-log.md:520`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** This covers the 5,000-path total and the per-path slope on this host. It does not cover the batch-check and truthrule sub-costs, or the 20,000-path extrapolation, none of which I timed separately.
**Legibility-target:** for-orchestrator-synthesis

P4: 1,295, 1,312 and 1,309 ms at 5,000 added paths; 98-100 ms at one path. The slope is (1,310 − 99) / 5,000 ≈ 0.24 ms per path. The numbers depend on the environment (load average 2.0 during the run).

**Evidence:** `$S/probe3.sh`, `$S/logs/probe3.log`

---

## Claim 21: plan F12: "N-denied via truthrule's cycle and settings words (the lib's writable() plus docs/dev-cycle.md), and, N-only, anything under docs/working/briefs/ or docs/working/cycles/; docs/constraints.md by its user word (F54) (T14; U2b1b)"; plan `--state` line: "then U2b1b's default_gate once main is resolved: both main and master, or origin/HEAD naming another branch than the one taken"

**Location:** `docs/working/plan-build-loop-handoff.md:127`, `docs/working/plan-build-loop-handoff.md:207`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers nrules' case arms and default_gate against T14 and the R7 test. It does not cover `--state`, which is not built (the line describes U3b's plan).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:565-568
      cycle|settings) DENY="one of the dev cycle's own files" ;;
      user) DENY="the user's constraints doc, which every loop prompt carries" ;;
      *) [[ ! "$7" =~ ^docs/working/(briefs|cycles)/ ]] || DENY="one of the dev cycle's own files" ;;
    esac
```

**Evidence:** `scripts/build-loop.sh:553-571`, `scripts/build-loop.sh:241-251`, `$S/logs/build-loop-check.log`

---

## Claim 22: plan `--check` line: "U2b1b (built): the verdict line comes first (`ok BRIEF TIP TREE`, or `refuse BRIEF: K of N changed paths refused`), then `path BRIEF S PATH` or `deny BRIEF S PATH: WHY` per changed path; exit 0 only when every verdict line is ok."

**Location:** `docs/working/plan-build-loop-handoff.md:212`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the refusing verdict's spelled format. The order, the path and deny formats, and the exit rule hold (claim 10).
**Legibility-target:** for-author

The line was written in 809df345 (`git log -L` on the line names only 809df345). a382a3f8 (api 1) then extended the verdict:
```bash
# scripts/build-loop.sh:626
  if [[ "$nd" -eq 0 ]]; then echo "ok $a $sha $tree"; else echo "refuse $a: $nd of ${#ps[@]} changed paths refused in the merge of $sha (tree $tree)"; fi
```
The plan's `refuse BRIEF: K of N changed paths refused` is now only a prefix. It should read `refuse BRIEF: K of N changed paths refused in the merge of TIP (tree TREE)`, as the help does (`scripts/build-loop.sh:111-112`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:212`, `scripts/build-loop.sh:111-112`, `scripts/build-loop.sh:626`

---

## Claim 23a: plan step 5's U2b1b note: "Built 2026-10-08 (`feat/build-loop-u2b1b`, cc9b69d3, 317 lines): the mode rule is an N rule (both policies), so floor item 5 is already enforced before U2c; the own brief also keeps its mode; plus U2b1a2's carried R6, R7, R9, A15, A17 and A19 (override rows 497, 507-511)."

**Location:** `docs/working/plan-build-loop-handoff.md:283`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the mode rule, the own-brief mode rule (mMode fails T15) and the carried fixes. "317 lines" is cc9b69d3's count, as labelled, not the unit's 382 at HEAD.
**Legibility-target:** for-orchestrator-synthesis

`[[ "$5" == M && "$2" == "$3" ]]` (`scripts/build-loop.sh:559`) keeps the mode. Dropping `"$2" == "$3"` fails T15's chmod case.

**Evidence:** `scripts/build-loop.sh:557-560`, `$S/logs/mut-mMode.log`

---

## Claim 23b: plan step 5's U2b1b note: "R8 is proposed as a Q-103 residual for its review to decide."

**Location:** `docs/working/plan-build-loop-handoff.md:283`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** This covers R8's status as the branch's own records state it. It does not judge the decision itself.
**Legibility-target:** for-author

Row 509 reads `**Decided at U2b1b iteration 1 (security, architecture concur): Q-103 residual.**` (`docs/reviews/override-log.md:509`), and plan step 13 lists R8 for U5 (`docs/working/plan-build-loop-handoff.md:305`). The note still says it is proposed. It should say R8 was decided a Q-103 residual at iteration 1 (row 509).

**Evidence:** `docs/working/plan-build-loop-handoff.md:283`, `docs/working/plan-build-loop-handoff.md:305`, `docs/reviews/override-log.md:509`

---

## Claim 24: plan step 13: "U2b1a2's R8 (a same-uid writer racing the gate's GATE_TMP: its config, info/, work/.gitattributes, err and diff; override row 509)"

**Location:** `docs/working/plan-build-loop-handoff.md:305`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the listed surface against gate_repo and row 509. It does not cover the Q-103 re-route itself (U5).
**Legibility-target:** for-author

Row 509's i2 note adds `git/refs/` and `git/HEAD` to the surface, and gate_repo creates both: `mkdir "$GATE_TMP/git" "$GATE_TMP/git/refs" "$GATE_TMP/work"` and `printf 'ref: refs/heads/none\n' > "$GATE_TMP/git/HEAD"` (`scripts/build-loop.sh:502-503`). Step 13's list stops at five files. The cross-reference to row 509 carries the full list, so it is imprecise rather than wrong.

**Evidence:** `scripts/build-loop.sh:497-506`, `docs/reviews/override-log.md:509`

---

## Claim 25: help, --check's state gate and default-branch lists, and "Each finding prints 'refuse state WHAT: WHY' and exits 2 before any brief is read ('refuse state gate: WHY' when the gate's own merge repository cannot be set up)"

**Location:** `scripts/build-loop.sh:80-93`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers each listed key and file against `STATE_KEYS_RE` and state_gate, default_gate's two findings, the order (state_gate before resolve_main, default_gate after it, both before read_settings), and the gate-setup line. It does not cover config keys outside the regex.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:212, :257-260, :641
STATE_KEYS_RE='^(filter\.|include|hook\.|merge\.|diff\.|core\.fsmonitor|core\.attributesfile|core\.hookspath|gpg\.|log\.showsignature|extensions\.partialclone$|remote\..*\.promisor$)'
if [[ "$MODE" == check ]]; then state_gate || exit 2; fi
resolve_main || true
main_by_name || { …; exit 1; }
if [[ "$MODE" == check ]]; then default_gate || exit 2; fi
    gate_repo || { echo "refuse state gate: its merge repository could not be set up"; exit 2; }
```
The state test, the A15 test (mA15 fails it) and the R7 test pass.

**Evidence:** `scripts/build-loop.sh:199-260`, `scripts/build-loop.sh:635-649`, `$S/logs/mut-mA15.log`, `$S/logs/build-loop-check.log`

---

## Claim 26a: help, verdict lines and refusal cases: "ok BRIEF TIP TREE … and no changed path is denied"; refuse cases incl. "git failed, or warned on stderr (a missing tree object), or the tree of main, TIP or a merge base is missing"; "the merge of BRANCH names a blob the object store lacks": a regular file the merge adds or changes names an object that is absent or not a blob; "K of N changed paths refused in the merge of TIP (tree TREE)", when deny lines follow

**Location:** `scripts/build-loop.sh:94-114`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers each refusal case against check_line, merge_result and the R6, T11-T15 tests (mF2 fails R6). It does not cover a non-blob object type at a regular file's id, which the code would also refuse (`grep -cx blob`) but no test plants.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:614-617
  if [[ ${#ids[@]} -gt 0 ]] && { ! out="$(printf '%s\n' "${ids[@]}" | gate_git cat-file --batch-check='%(objecttype)')" \
    || [[ "$(printf '%s\n' "$out" | grep -cx blob)" -ne ${#ids[@]} ]]; }; then
    echo "refuse $a: the merge of $br names a blob the object store lacks"; return
  fi
```
`ids` collects every record whose new mode is 100644 or 100755 (`scripts/build-loop.sh:606`), so A, M and T-to-file records are covered.

**Evidence:** `scripts/build-loop.sh:520-529`, `scripts/build-loop.sh:579-628`, `test/scripts/build-loop-check.bats:1533-1551`, `$S/logs/mut-mF2.log`

---

## Claim 26b: help, path/deny lines and the N-rule list: "After an ok line or a K of N refusal, one line per path … in diff-tree's order; S is its status letter (A, M, D or T) and PATH is '?' unless every character is one pathform allows"; "a path pathform refuses (a part starting .git, any case: .github/); a mode other than 100644 or 100755 on either side (a symlink or gitlink); the brief's own file … (mode kept); and, compared lower-cased, the dev cycle's own files (the roadmap, the questions files, the idea log, docs/dev-cycle.md, anything under docs/working/briefs/ or docs/working/cycles/) and docs/constraints.md"

**Location:** `scripts/build-loop.sh:113-128`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers each rule against nrules and pathform (`[.][gG][iI][tT]*`, `scripts/lib/dev-cycle-read.sh:191`) and T11-T15. It reads "a mode … on either side" as excluding an absent side (000000 is allowed, so regular-file adds and deletes pass), as iteration 1 did. It does not cover a case variant of the brief's own path, which is not matched exactly but is denied as a cycle file.
**Legibility-target:** for-orchestrator-synthesis

`p="${ps[$i]}"; shown="?"; [[ ! "$p" =~ ^[$NAMECHARS]+$ ]] || shown="$p"` (`scripts/build-loop.sh:622`) uses pathform's character set `NAMECHARS` (`scripts/lib/dev-cycle-read.sh:183`). T13 prints three `?` lines.

**Evidence:** `scripts/build-loop.sh:553-571`, `scripts/build-loop.sh:621-625`, `scripts/lib/dev-cycle-read.sh:183-192`, `test/scripts/build-loop-check.bats:1453-1531`

---

## Claim 27: help Exit line: "0 every line printed (or help), and for --check every verdict line ok; 2 any --check verdict line or the state gate not ok; 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no default branch found by name"

**Location:** `scripts/build-loop.sh:137-139`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers --check's exit paths (state_gate, default_gate, gate_repo, the verdict loop) and the exit-1 paths. It does not separately test "not a git repo".
**Legibility-target:** for-orchestrator-synthesis

The exit-2 paths are at `:256`, `:260`, `:641` and `:647` (claims 10 and 25). The exit-1 paths: `usage()` ends in `exit 1` (`:154`), and so do the perl and lib checks (`:143`, `:149`), the `rev-parse --show-toplevel` failure (`:252`) and `main_by_name` (`:258`).

**Evidence:** `scripts/build-loop.sh:141-176`, `scripts/build-loop.sh:252-260`, `scripts/build-loop.sh:635-649`

---

## Claim 28: A17 comment: "GIT_CONFIG_NOSYSTEM: the system config is no more the gate's than the user's (merge.directoryRenames there flipped a conflict: A17)"

**Location:** `scripts/build-loop.sh:196-198`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the export reaching every git call (the shim test, which mA17 fails) and the reference to A17's finding. It does not re-run the system-config conflict flip, which belongs to U2b1a2's iteration 3.
**Legibility-target:** for-orchestrator-synthesis

The export includes `GIT_CONFIG_NOSYSTEM=1` (`scripts/build-loop.sh:198`). The U2b1a rubric's A17 reads `System config reaches every gate call (`merge.directoryRenames` flipped a conflict)` (`docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:27`).

**Evidence:** `scripts/build-loop.sh:196-198`, `test/scripts/build-loop-check.bats:1375-1389`, `$S/logs/mut-mA17.log`

---

## Claim 29: state_gate and default_gate comments ("every merge.* and diff.* key … core.fsmonitor, core.attributesFile, core.hooksPath …; an info/attributes, info/grafts or shallow that is not absent or an empty regular file"; default_gate: "the default branch counts only when no other name could claim it … Prints one line per finding, as state_gate does; returns 1 on any")

**Location:** `scripts/build-loop.sh:199-211`, `scripts/build-loop.sh:236-240`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the comment text against the regex, the file test and default_gate's body, and the R7 test's two-finding case. It does not cover `--state` (U3b).
**Legibility-target:** for-orchestrator-synthesis

`if [[ -s "$p" || -L "$p" || ( -e "$p" && ! -f "$p" ) ]]; then echo "refuse state $f: present and not an empty file"` (`scripts/build-loop.sh:226`). The R7 test asserts both default_gate lines in one run (`test/scripts/build-loop-check.bats:1562-1564`).

**Evidence:** `scripts/build-loop.sh:212-251`, `test/scripts/build-loop-check.bats:1553-1570`

---

## Claim 30: gate_git and merge_result comments: "returns git's status, or 3 when git wrote anything to stderr (a missing object can warn and still exit 0: R6)"; "returns 1 on a conflict (a gitlink both sides moved is one, since no submodule repository is reachable), 2 when git failed or warned, or the tree of main, the tip or a merge base is missing (R6)"

**Location:** `scripts/build-loop.sh:507-519`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers both functions end to end and the R6/R9 tests under their mutants. It does not cover merge-base's exit 1 (no merge base), which merge_result allows through and merge-tree then refuses as unrelated histories (exit 2, "could not be computed").
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:522-528
  bases="$(gate_git merge-base --all "$MAIN_SHA" "$1")" || rc=$?
  [[ "$rc" -le 1 ]] || return 2
  for b in "$MAIN_SHA" "$1" $bases; do gate_git cat-file -e "$b^{tree}" || return 2; done
  rc=0; out="$(gate_git merge-tree --write-tree --no-messages "$MAIN_SHA" "$1")" || rc=$?
  [[ "$rc" -le 1 && "${out%%$'\n'*}" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]] || return 2
  [[ "$rc" -eq 0 ]] || return 1
```
(excerpt ends :527; merge_result() continues to :529 — read). R9 (mR9 fails it) shows the gitlink conflict.

**Evidence:** `scripts/build-loop.sh:507-529`, `$S/logs/mut-mR9.log`, `$S/logs/mut-mR6both.log`

---

## Claim 31: own_blob comment: "main's copy with its first Status: line outside a fence, the one brief_fields reads (status_line has read it as 'Status: open'), reading 'Status: done', every other byte kept (a CR at its end too). Returns non-zero when a read fails; the caller checks it"

**Location:** `scripts/build-loop.sh:531-535`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers line selection against brief_fields, the CR case (T15) and the exit-status check in nrules. It does not cover a test of the read-failure path (row 515: a race).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:540-542 (own_blob, :536-543 read)
  n="$(git cat-file blob "$MAIN_SHA:$1" | env LC_ALL=C awk "$FENCE_AWK"'{ sub(/\r$/, "") } fence($0) { next } !n && /^Status:/ { n = NR } END { print n + 0 }')" || return 1
  [[ "$n" -gt 0 ]] || return 1
  git cat-file blob "$MAIN_SHA:$1" | N="$n" perl -pe 's/^Status: open(\r?)$/Status: done$1/ if $. == $ENV{N}' | gate_git hash-object --no-filters --stdin
```
The caller's `ob="$(own_blob "$1")" &&` is under `set -euo pipefail` (`:140`). T15's fenced, CRLF and trailing-byte cases pass, and mMode fails T15.

**Evidence:** `scripts/build-loop.sh:140`, `scripts/build-loop.sh:536-560`, `scripts/lib/dev-cycle-read.sh:365-371`, `$S/logs/mut-mMode.log`

---

## Claim 32: nrules comment: "diff-tree's old and new modes $2 $3, new blob $4, status $5, path $6 and its lower-cased spelling $7 … The brief's own file is matched exactly; the cycle's files (truthrule's cycle and settings words …, plus anything under docs/working/briefs/ or docs/working/cycles/) and the constraints doc (its user word) compare lower-cased"; and the inline invariant "$7 is lower-cased, so the case word cannot fire; instr and dot, tested before cycle, match no cycle file, docs/dev-cycle.md or docs/constraints.md today"

**Location:** `scripts/build-loop.sh:544-552`, `scripts/build-loop.sh:562-564`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the argument order at the one call site (`:622`), truthrule's word order, and the invariant for every writable() family, dev-cycle.md and constraints.md. It does not cover future truthrule words.
**Legibility-target:** for-orchestrator-synthesis

truthrule tests `case`, then `isstart` (instr), then `"/$1" == */.*` (dot), then `writable` (`scripts/lib/dev-cycle-read.sh:1091-1097`). P3, with the lib sourced: docs/roadmap.md, questions.md, questions-archive.md, idea-log.md, cycles/cycle-2026-10-01.md, briefs/2026-10-01-x.md and briefs/closed/2026-10-01-x.md all → `cycle`; docs/dev-cycle.md → `settings`; docs/constraints.md → `user`. An instruction-file name or a dot name under briefs/ → `instr`/`dot`, which nrules' `*)` arm still denies through its subtree regex. writable's brief names start with a date (`$DIGIT{4}-`), so no INSTRUCTION_FILE basename matches one.

**Evidence:** `scripts/build-loop.sh:553-571`, `scripts/lib/dev-cycle-read.sh:199-207`, `scripts/lib/dev-cycle-read.sh:1088-1099`, `$S/probe2.sh`, `$S/logs/probe2.log`

---

## Claim 33: nrules comment: "(T14 fails if one ever does: truthrule names this third consumer)"

**Location:** `scripts/build-loop.sh:564`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** This covers which shadowing T14 would detect. It does not cover a run of a shadowing mutant.
**Legibility-target:** for-author

T14 lists every top-level cycle file, dev-cycle.md and constraints.md (`test/scripts/build-loop-check.bats:1457-1459`). If instr or dot ever matched one of those, nrules' `*)` arm would let it through and T14 would fail. A word that shadowed a file under `docs/working/briefs/` or `cycles/` would not fail T14: the `*)` arm's subtree regex still denies it with the same reason. So T14 fails exactly where a shadow would open a hole, not "if one ever does" in general. A precise version: "T14 fails if one ever shadows a file outside briefs/ and cycles/, where the subtree rule does not catch it."

**Evidence:** `scripts/build-loop.sh:562-569`, `test/scripts/build-loop-check.bats:1453-1473`

---

## Claim 34: check_line comments: header ("ok BRIEF TIP TREE" or "refuse BRIEF: K of N … (tree TREE)", then path/deny lines … or one skip or refuse line); A16 ("In the gate repository, so no repo config or checkout .gitmodules hides a moved gitlink (A16); --no-renames, so a rename is judged as both its sides (F6)"); batch-check ("merge-tree passes a side's unchanged blob by id without reading it … (a missing subtree already failed diff-tree)"); "One lower-casing pass for every path (a tr per path cost 1 to 2.5 ms each)"

**Location:** `scripts/build-loop.sh:573-578`, `scripts/build-loop.sh:597-598`, `scripts/build-loop.sh:611-614`, `scripts/build-loop.sh:619`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the header against check_line's output, A16 (claim 18), F6 (T11), the batch-check (mF2, P1b for the subtree parenthetical) and one nul_list/lower_all pass. It does not re-time "1 to 2.5 ms", which is environment-dependent (iteration 1: 2.2-2.6 ms; iteration 2's fact-check: 1.17 ms).
**Legibility-target:** for-orchestrator-synthesis

P1b: a missing subtree reached diff-tree and was refused there ("could not be listed"), before the batch-check, as the parenthetical says. T11 asserts `deny $B D docs/roadmap.md` and `path $B A docs/x.md` for a `git mv`.

**Evidence:** `scripts/build-loop.sh:579-628`, `test/scripts/build-loop-check.bats:1498-1505`, `$S/logs/probe2.log`, `$S/logs/mut-mF2.log`

---

## Claim 35: check_line comment: "Every record read whole: two NUL-ended fields each."

**Location:** `scripts/build-loop.sh:608-609`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers what the NUL count proves. It does not cover git's own output, which never ends mid-record (row 513), so the gap below is not reachable on the honest path.
**Legibility-target:** for-author

```bash
# scripts/build-loop.sh:609
  if [[ "$(tr -cd '\000' < "$GATE_TMP/diff" | wc -c)" -ne $((2 * ${#ps[@]})) ]]; then echo "refuse $a: the paths the merge of $br changes could not be read"; return; fi
```
The check proves that every NUL-ended field was consumed as part of a whole record. Trailing bytes after the last NUL are not counted. A loop over `m1\0p1\0frag` with the same `read -r -d ''` pair read 1 record with 2 NULs, so the check would pass and `frag` would be dropped silently (`$S/logs/probe-frag.log`). A precise version: "every NUL-ended field read as part of a whole record (bytes after the last NUL are not checked)". This is informational: diff-tree's `-z` output ends in NUL, and row 513 already records the check as defensive.

**Evidence:** `scripts/build-loop.sh:602-609`, `$S/logs/probe-frag.log`, `docs/reviews/override-log.md:513`

---

## Claim 36: lib header contract item 5: "Ask floor about each changed path, in this shell, before main_entry … Floor item 5 (symlinks, gitlinks) and the brief's own Status change are the caller's rules; build-loop.sh's N rules apply them, and pathform, under both policies before floor runs, so a path pathform refuses (.github/x.yml) is denied as a path form and floor's dotfile reason serves the dot paths pathform accepts (.envrc)"; truthrule comment: "build-loop.sh's N rules read its cycle, settings and user words too, so a word tested before them must never match a file those words cover"

**Location:** `scripts/lib/dev-cycle-read.sh:59-65`, `scripts/lib/dev-cycle-read.sh:1076-1079`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers nrules applying the mode rule, the own-brief rule and pathform under both policies (no policy branch in nrules), pathform refusing `.github/x.yml` (T13) and accepting `.envrc` (no `.git` prefix), and truthrule reading `.envrc` as `dot`. "Before floor runs" holds vacuously: build-loop.sh calls no floor yet (U2c).
**Legibility-target:** for-orchestrator-synthesis

pathform's part test is `[[ -n "$c" && "$c" != "." && "$c" != ".." && "$c" != [.][gG][iI][tT]* ]]` (`scripts/lib/dev-cycle-read.sh:191`). truthrule's dot word is `elif [[ "/$1" == */.* ]]; then TRUTH_WHY="dot"` (`scripts/lib/dev-cycle-read.sh:1093`). Claim 32 checks the truthrule invariant.

**Evidence:** `scripts/lib/dev-cycle-read.sh:184-192`, `scripts/lib/dev-cycle-read.sh:1076-1099`, `scripts/build-loop.sh:553-571`

---

## Claim 37: tests added on the branch establish what their names claim: T14 ("lists every changed path and refuses the dev cycle's own files, other briefs and the constraints doc in any case; other paths pass"), T15 (own file Status-only), T11 (rename two sides), T12 ("symlink or gitlink on either side, though submodule ignore=all is set, and passes an exec bit"), T13 ("prints only a name in its character set"), R6 ("a missing tip or merge-base tree is not read as empty, a missing blob does not land"), R7 ("both main and master, or origin/HEAD naming a branch the gate did not take"), R9 ("a gitlink fast-forward the real repository would merge is a conflict"), A15 ("a planted key refuses even with main's commit missing")

**Location:** `test/scripts/build-loop-check.bats:1453-1594`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers each name against its assertions and a mutant that fails it (mMode for T15, mA16both for T12, mR6both and mF2 for R6, mR7, mR9, mA15). It does not cover T14's "in any case" for case variants under `briefs/` or `cycles/` (only top-level case variants are planted), or T11, T13 and T14 under a mutant of their own (they passed under every mutant run; pathform, the mode rule and the cycle arms were not mutated).
**Legibility-target:** for-orchestrator-synthesis

T14: `nref 15 16` over 13 cycle paths, including another open brief `$o` (M), a new brief, `closed/x`, `Docs/Roadmap.md`, `docs/Dev-Cycle.md` and `docs/working/Questions.md`, plus `docs/constraints.md`, `docs/CONSTRAINTS.md` and `docs/ok.md` (path). T12: `nref 5 7` with old-side gitlink `og` (T), new gitlink `gl` (A), symlinks `link` and `g.txt` (new side) and `was-link` (old side), and exec-bit `path` lines. R9 asserts the real repository's merge-tree succeeds before the gate refuses.

**Evidence:** `test/scripts/build-loop-check.bats:1440-1594`, `$S/logs/mut-*.log`, `$S/logs/build-loop-check.log`

---

## Claim 38: renamed and edited older tests: the shim test "no global or system config … (… A17)" with "The fixture sets GIT_CONFIG_NOSYSTEM; unset, so the script's own setting is what the log shows"; the old submodule test's "Not commit_all: add -A would drop the gitlink, which has no directory (R9)"; the new R9 test's "The brief first: commit_all's add -A would drop a gitlink that has no directory"

**Location:** `test/scripts/build-loop-check.bats:1375-1389`, `test/scripts/build-loop-check.bats:1404-1405`, `test/scripts/build-loop-check.bats:1575`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the shim test under mA17 and the gitlink-drop claim by direct reproduction of both fixture forms. It does not cover other git versions' `add -A` handling of a dirless gitlink.
**Legibility-target:** for-orchestrator-synthesis

The fixture exports `GIT_CONFIG_NOSYSTEM=1` (`test/lib/build-loop-fixtures.bash:16`), and the test runs `unset GIT_CONFIG_NOSYSTEM` before the shim run. mA17 fails it. P5: with the new form, the merge base of main and feat/x holds `160000 commit aaaaaa…` at `sub`. With `git add -A` after `update-index --cacheinfo` (the old form), the base holds nothing at `sub`.

**Evidence:** `test/lib/build-loop-fixtures.bash:16`, `$S/logs/mut-mA17.log`, `$S/probe4.sh`, `$S/logs/probe4.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4** (commit cc9b69d3): "a missing subtree … is fatal" is false for a subtree the tip passes by id. merge-tree is silent and diff-tree refuses it. Both later commit messages already correct this, and the message is immutable, so nothing is left to fix.

### Stale
- **Claim 22** (`docs/working/plan-build-loop-handoff.md:212`): the refusing verdict is now `refuse BRIEF: K of N changed paths refused in the merge of TIP (tree TREE)` (since a382a3f8). The plan line still shows the pre-a382a3f8 form.
- **Claim 23b** (`docs/working/plan-build-loop-handoff.md:283`): "R8 is proposed as a Q-103 residual for its review to decide". R8 was decided at iteration 1 (row 509).

### Mostly Accurate
- **Claim 7** (commit a382a3f8): F2 refuses missing blobs. A missing subtree is refused by diff-tree, and e02d056b says so.
- **Claim 24** (`docs/working/plan-build-loop-handoff.md:305`): step 13's R8 surface omits `git/refs/` and `git/HEAD` (row 509, i2).
- **Claim 33** (`scripts/build-loop.sh:564`): T14 fails only for a shadow outside `briefs/` and `cycles/`. Inside them the subtree rule still denies.
- **Claim 35** (`scripts/build-loop.sh:608`): the NUL count proves every NUL-ended field was read in whole records, but it does not catch bytes after the last NUL. Unreachable with git's own output (row 513).

### Unverifiable
(none)

## Goal-Alignment Note

The user's goal is to land U2b1b after a clean review-fix loop. This terminal pass found no claim in the code or tests that misstates behaviour:
- Every carried fix the branch claims holds under its mutant: R6 (union of two guards), R7, R9, A15, A16 (union), A17, F2 (missing blob) and the own brief's mode rule.
- The test and line tallies are exact (101/19/78/2/2; 317/367/382).
- The 1.3 s at 5,000 paths reproduces.
- The truthrule word-order invariant nrules depends on holds for every cycle file, dev-cycle.md and constraints.md.

The one Incorrect is a historical commit-message parenthetical, already corrected twice on the branch.

What remains is documentation in the plan. Its `--check` interface line (:212) lags the K-of-N verdict's TIP/TREE suffix. Its step 5 note (:283) still calls R8 "proposed". Step 13 (:305) omits two surface files row 509 names. These are wording, not reds, and are worth a one-line plan edit before merge, since the plan is the spec U3 builds `--merge` from (the :212 line in particular).

Claims 33 and 35 are comment precision on honest-path-unreachable or fail-closed cases. Neither is a Q-103 residual or a unit red.
