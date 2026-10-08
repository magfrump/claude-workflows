# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2b1a2 (branch feat/build-loop-u2b1a2)
**Scope:** `git diff feat/build-loop-u2b1a1...HEAD` (HEAD 63ea50e7): scripts/build-loop.sh, test/scripts/build-loop-check.bats, commit 63ea50e7's message, the plan's Script interface, D7 and U2b1a lines (docs/working/plan-build-loop-handoff.md:84, :207, :212, :281), and the rubric docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md (Fixed notes). Final confirming pass, merged from replicates r1, r2 and r3 by most-severe-wins.
**Checked:** 2026-10-08
**Commit:** 63ea50e7
**Replication:** k=3
**Total claims checked:** 56
**Summary:** 43 verified, 5 mostly accurate, 3 stale, 5 incorrect, 0 unverifiable

Merged mechanically from `docs/reviews/code-fact-check-report-build-loop-u2b1a2-final-r1.md` (43 claims), `-r2.md` (31 claims) and `-r3.md` (39 claims), all at `Commit: 63ea50e7`. Each merged claim carries the evidence of the replicate that won its verdict. Replicate claim numbers appear in parentheses in the `Replicate verdicts` field. Where one replicate verdicted a compound claim and another split it, the merged report carries one claim per part. On those rows the compound replicate's verdict is marked `(compound)`. No claim or evidence below originates in the merge.

Execution provenance is in each replicate's report header, and the captured outputs stay outside the repo:
- **r1:** `/tmp/fcu2b1a2-r1-logs/`, with probe scripts in `/tmp/fcu2b1a2-r1-scripts/`. Suites ran from 2026-10-08T18:57:39Z, probes from 18:58Z to 19:10Z.
- **r2:** `/tmp/fcu2b1a2-r2-logs/`. Suites ran from 18:58:38Z, mutants from 19:00Z, probes from 19:01Z to 19:04Z.
- **r3:** `/tmp/fcu2b1a2-r3-logs/`, `/tmp/fcu2b1a2-r3-probe/` and `/tmp/fcu2b1a2-r3-mut/`. Suites ran from 18:58:59Z, probes from 19:00:10Z, mutants from 19:02:02Z.

All runs used git 2.39.5.

Mutant names differ by replicate. These labels name the same mutant:
- **Merge-tree in the real repo:** r1 m1, r2 m1, r3 MA.
- **The same, without GIT_ALLOW_PROTOCOL:** r2 m2, r3 MD.
- **State gate after resolve_main:** r1 mutant a, r2 m3, r3 MB (r3 describes it as after `main_by_name`).
- **The same, without GIT_ALLOW_PROTOCOL:** r1 mutant b, r2 m10, r3 MC.
- **No objectformat:** r1 m2, r2 m5, r3 MF.
- **No commitGraph pair:** r2 m8, r3 ME.

r3 cites rubric line numbers 3 lower than r1 and r2 do (R2 at `:13` against `:16`). Its rubric claims were clustered within the ±5 window.

---

## Claim 1: R2 "merge_result runs in a gate-owned repository ... The moved gitlink is now a conflict."

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:16`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the code half of R2's Fixed note: merge-tree no longer opens `.git/modules/<name>`, and a gitlink both sides moved from a shared base refuses as a conflict. It does not establish the test half of the note (Claim 2).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (1a) · r2=Verified (1) · r3=Verified (1a)
**Replicate annotations:**
- **r2:** "It holds even with GIT_ALLOW_PROTOCOL removed (m7) … So the gate repository, not the protocol block, is what keeps the submodule repository closed."
- **r3:** "The probe uses a corrected plant whose merge base really holds the gitlink … Under the real code, merge-tree reports 'Failed to merge submodule sub (not checked out)' and nothing is fetched."
- **r1+r3:** the corrected plant differs from the suite's own submodule test (Claim 2).

The fixture is p4: the merge base has `sub` at aaaa…, main moves it to cccc…, and feat/x moves it to bbbb…. A promisor repository sits under `.git/modules/sm`. Run unprotected in the real repo, merge-tree fetched (`exit 1 fetched=yes`). The script refused with `refuse …: feat/x conflicts with the default branch` and `fetched=no`. A mutant without `GIT_ALLOW_PROTOCOL=none`, with the gate repository kept, also gave `fetched=no` (p4d). So gate_repo alone keeps the submodule repository closed.

**Evidence:** `scripts/build-loop.sh:448-456`; `/tmp/fcu2b1a2-r1-logs/p4-submodule-base.txt`; `/tmp/fcu2b1a2-r1-logs/p4d-gaterepo-no-protocol.txt`

---

## Claim 2: R2 "Test: the P1 plant (mutant running merge-tree in the real repo fetches)."

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:16`
**Type:** Behavioral / Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test at build-loop-check.bats:1394 as committed at 63ea50e7, which is byte-identical to c66988b6. It does not establish what fixture the author's own mutant run used.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Incorrect (1b) · r2=Incorrect (2, compound with Claim 3) · r3=Incorrect (1b)
**Replicate annotations:**
- **r2:** "This does not say the code is wrong; Claim 1 shows it is right." r2 also found the test passes under m2 (real repo, transport allowed).
- **r3:** The test also passes under MD, which drops GIT_ALLOW_PROTOCOL as well.
- **r1:** The pattern resembles the logged hallucination class "a test outcome quoted from an artifact set that does not contain it". The log was not appended (see Escalations).

The test's merge base holds no gitlink, so git never reaches the submodule code path the plant targets. The fixture stages `sub` with `git update-index --add --cacheinfo "160000,$s1,sub"; commit_all sub1`, and `commit_all` is `git add -A && git commit …` (`test/lib/build-loop-fixtures.bash:28`). With no `sub` directory in the worktree, `add -A` stages the gitlink's removal. `git ls-tree $(git merge-base main feat/x)` lists only `.gitmodules` and `docs` (p3). Unprotected merge-tree in that fixture prints `Failed to merge submodule sub (no merge base)` and does not fetch (p3: `exit 1 fetched=no`). Under m1 (merge-tree in the real repo) the submodule test still passes: `ok 2 --check's merge opens no submodule repository…`.

**Evidence:** `test/scripts/build-loop-check.bats:1394-1408`; `test/lib/build-loop-fixtures.bash:28`; `/tmp/fcu2b1a2-r1-logs/p3-submodule.txt`; `/tmp/fcu2b1a2-r1-logs/m1-realrepo-mergetree.txt`

---

## Claim 3: "Mutants: merge-tree in the real repo (submodule and union tests fail)"

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:48`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the submodule half of this mutant claim at 63ea50e7. It does not cover the union half, which holds (the union test fails under m1).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Incorrect (10a) · r2=Incorrect (2, compound with Claim 2) · r3=Incorrect (5)
**Replicate annotations:**
- **r2+r3:** the union-test half of the line is true.
- **r1:** the same hallucination-class note as Claim 2.

Mutant m1 rewrites merge_result to `out="$(git merge-tree --write-tree --no-messages "$MAIN_SHA" "$1" 2>/dev/null)" || rc=$?`, with no GATE_ENV and no cd. Under m1, `bats -f 'submodule|union|SHA-256'` gave `not ok 1 --check's merge reads no checkout attributes…` and `ok 2 --check's merge opens no submodule repository…`. So the submodule test does not fail; the reason is Claim 2.

**Evidence:** `test/scripts/build-loop-check.bats:1394-1408`; `/tmp/fcu2b1a2-r1-logs/m1-realrepo-mergetree.txt`

---

## Claim 4: "no objectformat (SHA-256 test), no GIT_ALLOW_PROTOCOL (shim), no shallow (state test) ... Suites 91/19/78/2/2."

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:48`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the objectformat mutant and the suite counts. The no-GIT_ALLOW_PROTOCOL and no-shallow mutants are checked only by reading: the shim greps ` P=none` and the state test expects the shallow line. They were not executed.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (10b) · r2=Verified (3) · r3=—
**Replicate annotations:**
- **r2:** It executed the no-GIT_ALLOW_PROTOCOL mutant, and m7 fails the shim test (`not ok 9`). It did not run the no-shallow mutant: "the state test asserts the exact line … so it would fail by construction".
- **r3 (Claim 5's Scope, not its own claim):** MF (no objectformat) and ME (no commitGraph pair) fail as stated. MB fails the partial-clone test. The "no GIT_ALLOW_PROTOCOL (shim)" and "no shallow (state test)" mutants were not re-run.

Mutant m2 dropped `[extensions] objectformat`, and the result was `not ok 1 --check merges in a SHA-256 repository…`. The suites passed with 91, 19, 78, 2 and 2 tests (exit 0 each).

**Evidence:** `/tmp/fcu2b1a2-r1-logs/m2-no-objectformat.txt`; `/tmp/fcu2b1a2-r1-logs/build-loop-check.bats.txt` and the other `*.bats.txt` logs

---

## Claim 5: R3 "Fixed for --check: The state gate refuses an origin/HEAD naming anything but origin/main or origin/master (tested)."

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:17`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers state_gate's origin/HEAD rule and its test. It does not establish anything about `--settings`/`--status`, which still follow origin/HEAD by design (row 493).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (2) · r2=Verified (5, compound) · r3=Verified (2, compound)
**Replicate annotations:**
- **r3:** In P4, an origin/HEAD symref to refs/heads/feat/x was refused, and one to origin/main printed ok. The deferred parts are not covered: `--settings` and `--status` still follow origin/HEAD.

```bash
# scripts/build-loop.sh:198-201
  rc=0; p="$(git symbolic-ref -q refs/remotes/origin/HEAD)" || rc=$?
  if [[ "$rc" -gt 1 ]] || [[ -n "$p" && "$p" != refs/remotes/origin/main && "$p" != refs/remotes/origin/master ]]; then
    echo "refuse state origin/HEAD: it names a branch other than origin/main or origin/master"; bad=1
  fi
```
The test at :1315 plants `git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/feat/x` and expects that line. The suite passed, and p6 prints the same line.

**Evidence:** `scripts/build-loop.sh:198-201`; `test/scripts/build-loop-check.bats:1336-1342`; `/tmp/fcu2b1a2-r1-logs/build-loop-check.bats.txt`; `/tmp/fcu2b1a2-r1-logs/p6-noobj.txt`

---

## Claim 6: R4 "`GIT_CONFIG_GLOBAL=/dev/null` for every call (shim test)."

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the export and its runtime presence on every PATH-resolved git call. It does not cover the system config (Claim 15).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (3) · r2=Verified (5, compound) · r3=Verified (2, compound)
**Replicate annotations:**
- **r2:** m7 fails the shim test on `G=/dev/null`.
- **r3:** In P1, XDG and global files that make plain merge-tree union-merge left `--check` at a conflict.

`scripts/build-loop.sh:166` exports `GIT_CONFIG_GLOBAL=/dev/null`. The shim test (:1371) requires ` G=/dev/null` on every logged call, and it passed. GATE_ENV unsets only `--local-env-vars` names, and GIT_CONFIG_GLOBAL is not among them (p7 lists them).

**Evidence:** `scripts/build-loop.sh:166`, `test/scripts/build-loop-check.bats:1371-1383`; `/tmp/fcu2b1a2-r1-logs/p7-misc.txt`

---

## Claim 7: A6 "The state gate refuses a non-empty shallow file (tested); the gate repository has none either."

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the file check and gate_repo's layout. It does not cover a `GIT_SHALLOW_FILE` in the caller's environment, which GATE_ENV unsets and which the caller is trusted with anyway.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (4) · r2=Verified (5, compound) · r3=Verified (2, compound)
**Replicate annotations:** none

`for f in info/attributes info/grafts shallow; do` (`scripts/build-loop.sh:192`). The state test expects `refuse state shallow: present and not empty`. gate_repo creates only `git`, `git/refs` and `work`, writes `HEAD` and `config`, and makes no `shallow` (`scripts/build-loop.sh:453-455`).

**Evidence:** `scripts/build-loop.sh:192-195`, `:453-455`; `test/scripts/build-loop-check.bats:1331-1342`

---

## Claim 8: A7 "`core.commitGraph=false` pair (shim test)."

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the pair being set on every call and git ignoring the graph's parent data under it. It does not establish that a forged graph changes a merge base: r1's two forgeries that rewired parents and generation did not move `merge-base`, so that effect rests on security F5's probe.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (5) · r2=Verified (5, compound) · r3=Verified (2, compound)
**Replicate annotations:**
- **r2:** m8 fails the shim test. With a garbage commit-graph, the control prints `error: commit-graph file is too small` while `--check` stays silent.
- **r3:** With a garbage commit-graph, plain git printed `error: improper chunk offset(s)` while `--check` printed ok (P5). r3 does not establish the merge-base effect.

`for kv in core.useReplaceRefs=false core.hooksPath=/dev/null core.fsmonitor=false core.attributesFile=/dev/null core.commitGraph=false; do` (`scripts/build-loop.sh:160`). The shim test requires ` core.commitGraph=false` on every call. In p8 a forged commit-graph changed main's parent as `git log` reported it: graph on gave `… d649542…`, graph off gave `… ffc5358…`.

**Evidence:** `scripts/build-loop.sh:158-164`; `test/scripts/build-loop-check.bats:1380`; `/tmp/fcu2b1a2-r1-logs/p8-cgraph.txt`

---

## Claim 9: A8 "The gate repository reads no repo config."

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:27`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers merge-tree's config sources inside GATE_ENV. It does not cover system config (Claim 15) or the caller's GIT_CONFIG_* environment, which GATE_ENV keeps on purpose.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (6) · r2=Verified (5, compound) · r3=Verified (2, compound)
**Replicate annotations:** none

`printf '[core]\n\trepositoryformatversion = 1\n[extensions]\n\tobjectformat = %s\n' "$fmt" > "$GATE_TMP/git/config"` (`scripts/build-loop.sh:455`). GIT_DIR is the gate dir, and GIT_COMMON_DIR is unset (p7 lists it in `--local-env-vars`). That leaves no path to the repo's `config` or `config.worktree`.

**Evidence:** `scripts/build-loop.sh:448-456`; `/tmp/fcu2b1a2-r1-logs/p7-misc.txt`

---

## Claim 10: A9's Fixed note (GIT_ALLOW_PROTOCOL stops a fetch)

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:22-25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers GIT_ALLOW_PROTOCOL stopping a fetch. It does not cover A9's deferred part (config planted mid-run).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified (5, compound: "A9 partly") · r3=Verified (2, compound)
**Replicate annotations:**
- **merge:** The location is r3's compound range (`:14-15,22-25`, offset as noted in the header). A9 is the rubric's row at `:28` in r1 and r2's numbering.

A9: in P3, `GIT_ALLOW_PROTOCOL=none git cat-file -p <missing>` printed `fatal: transport 'file' not allowed`, and the upload-pack mark was not created. The control run without it did create the mark.

**Evidence:** `scripts/build-loop.sh:166`; `/tmp/fcu2b1a2-r3-probe/p3.log`

---

## Claim 11: A13 "Plan's --check interface line now states the duty for U2b1b"

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:28-29`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the presence of the plan text. It does not establish that U2b1b will carry out the duty.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=— · r3=Verified (3, compound with A14) · single-replicate detection
**Replicate annotations:**
- **merge:** the location is r3's (offset as noted in the header).

The plan reads `U2b1b adds per-path lines and must make the exit status "every line ok"` (`docs/working/plan-build-loop-handoff.md:212`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:212`

---

## Claim 12: A14 "Plan amended" (`--state` grammar and D7's install.sh)

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:33`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two plan lines named in the finding (Claims 17, 18). It does not cover other plan lines that still describe the iteration-1 design (Claim 20).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (7) · r2=Verified (5, compound) · r3=Verified (3, compound with A13)
**Replicate annotations:** none

The amendment landed in ae08688c (U2b1a1). The plan now reads `` `refuse state WHAT: WHY` `` (:207) and `` `devcontainer-config/install.sh`'s `git_state_gate` `` (:84).

**Evidence:** `docs/working/plan-build-loop-handoff.md:84`, `:207`

---

## Claim 13: the other Fixed notes (A1, A3, A4, A5, A10, C1, C3)

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:60-79`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each note's description of the code at 63ea50e7. It does not re-run the iteration-1 probes. A4 says "all four" pairs; there are now five, plus G and P, all asserted. That is a superset, not a mismatch.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified (5, compound residue after Claims 5-10, 12, 14) · r3=— · single-replicate detection
**Replicate annotations:** none

- **A10:** no comment now says a fetch needs a promisor remote.
- **A1:** the comment reads "filter, merge and diff drivers (commands)".
- **A3:** the help refuse list, the objects-and-temp-dir sentence and "an empty directory to run in".
- **A5:** `tr -d '\000'` in marker_kind.
- **C1:** `[ "${#lines[@]}" -eq 1 ]` at `test/…:1324`.
- **C3:** `--no-textconv` in check_brief.

paraphrased — no quote available because the claim spans several notes and their sites; the bullets above name each site.

**Evidence:** `scripts/build-loop.sh:158-166`, `scripts/lib/dev-cycle-read.sh:422`; `/tmp/fcu2b1a2-r2-logs/mutants.txt`

---

## Claim 14: C4 "Fixed (a separate variable)."

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two "its path could not be read" lines. It does not cover WHAT holding `: ` (C5, Won't-Fix).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (8) · r2=Verified (5, compound) · r3=—
**Replicate annotations:** none

`p="$(git rev-parse --path-format=absolute --git-path "$f" 2>/dev/null)" || { echo "refuse state $f: its path could not be read"; return 1; }` (`scripts/build-loop.sh:184`, the same at :193). `$f` is the loop word, set before the substitution.

**Evidence:** `scripts/build-loop.sh:183-184`, `:192-193`

---

## Claim 15: C11 "Global and system config apply to the gate repository ... Fixed: GIT_CONFIG_GLOBAL for all calls; GATE_ENV unsets the repo-local variables."

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:46`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the global and GIT_COMMON_DIR halves, which are fixed, and the system half, which is not. It does not establish that system config is reachable by a loop: `/etc/gitconfig` is absent here, and `/etc` is not writable by uid 1000.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Mostly accurate (9) · r2=Mostly accurate (6) · r3=Mostly accurate (4)
**Replicate annotations:**
- **r2:** A system `core.attributesFile` pointing at `* merge=union` did not change the result, because the pair outranks it. Other system keys, such as `merge.directoryRenames`, are not switched off. GIT_CONFIG_SYSTEM is caller environment.
- **r3:** "`touch /etc/gitconfig` was denied for uid 1000". In P1 a broken system config file stopped the script with `Not inside a git repository`, exit 1. The same key in repo config is refused (`refuse state merge.directoryrenames: set in config…`). The precise wording: "Fixed for global config; system config still applies to every call, through a root-owned file or the caller's environment."

The global config and GIT_COMMON_DIR halves hold (Claims 6 and 9). System config still reaches the gate's merge, because nothing sets `GIT_CONFIG_NOSYSTEM`. In p12, main renames `a/` to `b/` and feat/x adds `a/new`. That merge refuses as a conflict. But with `GIT_CONFIG_SYSTEM` holding `merge.directoryRenames = true` (standing in for `/etc/gitconfig`), `--check` printed `ok … cc5ae46…` and exited 0. The precise note: global fixed; system config still applies and is out of a loop's reach (root-owned).

**Evidence:** `scripts/build-loop.sh:166`; `/tmp/fcu2b1a2-r1-logs/p12-sysconf.txt`

---

## Claim 16: R1 "mutants without the keys, or with the gate after resolve_main, both let upload-pack run."

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:60`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both mutants against the code at 63ea50e7. It does not establish what they did at 9e5d92df; the claim was plausibly true before iteration 2 added `GIT_ALLOW_PROTOCOL=none`.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Stale (11) · r2=Stale (4) · r3=—
**Replicate annotations:**
- **r2:** "The fix itself is true: the keys are in STATE_KEYS_RE and the gate runs before resolve_main."
- **r2 results:** m9 (no keys) fails on its output with no upload-pack run. m3 (gate after resolve_main) passes. m10 (m3 plus no GIT_ALLOW_PROTOCOL) fails, and upload-pack ran.

At 63ea50e7, neither mutant lets upload-pack run, because `GIT_ALLOW_PROTOCOL=none` blocks the fetch.
- **Gate after resolve_main (mutant a):** exit 2, the two refusal lines, `fetched=no`. The R1 test passes under it, because resolve_main falls back to HEAD's sha and the gate still refuses (Claim 49).
- **Keys removed (mutant c):** `build-loop.sh needs a default branch found by name…`, exit 1, `fetched=no`. The test fails here on its status assertion, not on the mark.
- **Gate moved and GIT_ALLOW_PROTOCOL also dropped (mutant b):** `fetched=yes`. This is the only combination that makes upload-pack run.

**Evidence:** `test/scripts/build-loop-check.bats:1356-1369`; `/tmp/fcu2b1a2-r1-logs/p5-r1-mutations.txt`

---

## Claim 17: D7 "All git calls are hardened, with a state gate after `devcontainer-config/install.sh`'s `git_state_gate`."

**Location:** `docs/working/plan-build-loop-handoff.md:84`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the path and function name. It does not compare the two gates' key lists.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (12) · r2=Verified (8) · r3=Verified (6)
**Replicate annotations:**
- **r2:** It does not establish that the two gates refuse the same set. The build-loop gate is a superset (partial clone, shallow, origin/HEAD and others).
- **r3:** "There is no root-level `install.sh`."

`devcontainer-config/install.sh` is tracked. It defines `git_state_gate() {` at :209 and calls it at :332 (`git_state_gate   # before any other git call on the checkout (review R1)`).

**Evidence:** `devcontainer-config/install.sh:209`, `:332`

---

## Claim 18: "`--state` → `ok`, or `refuse state WHAT: WHY` for each planted `.git` state the gate refuses (exit 2), as `--check` prints them (U2b1a's `state_gate`)."

**Location:** `docs/working/plan-build-loop-handoff.md:207`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line grammar matching state_gate's output. `--state` itself is U3b's and does not exist yet; the line is a plan, not a claim about current code.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (13) · r2=Verified (7, compound) · r3=Verified (7, compound)
**Replicate annotations:**
- **r2:** "These amendments landed in U2b1a1 (ae08688c), not in this unit's diff."

Every state_gate output line starts `refuse state ` and has a `: ` separator, for example `echo "refuse state $f: present and not empty"` (`scripts/build-loop.sh:194`). On any finding `--check` exits 2: `if [[ "$MODE" == check ]]; then state_gate || exit 2; fi` (:209).

**Evidence:** `scripts/build-loop.sh:181-203`, `:209`

---

## Claim 19: "Output (U2b1a): `refuse state WHAT: WHY` lines (exit 2 before any brief), then per brief `ok BRIEF TIP TREE`, `refuse BRIEF: WHY` or `skip BRIEF: WHY`; U2b1b adds per-path lines and must make the exit status 'every line ok'."

**Location:** `docs/working/plan-build-loop-handoff.md:212`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the current line kinds and the exit-before-briefs ordering. It does not cover U2b1b's future lines.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (14) · r2=Verified (7, compound) · r3=Verified (7, compound)
**Replicate annotations:**
- **r3:** the state test pins the forms (executed against the suite).

The state gate runs at :209, before `resolve_main` and `read_settings`. check_line prints only `ok $a $sha $tree`, `refuse $a: …`, or status_line's non-ok line. That line is always a `skip`: check_brief emits only `ok` and `skip` lines, at 9 `echo "skip` sites. The current exit test is `[[ "$out" == "ok "* ]] || fails=1` (:507). It tests the first line of out, and today out is one line.

**Evidence:** `scripts/build-loop.sh:209`, `:470-488`, `:499-510`; `scripts/lib/dev-cycle-read.sh` check_brief

---

## Claim 20: plan U2b1a bullet: "merge-tree run from a fresh empty directory against the common git dir"

**Location:** `docs/working/plan-build-loop-handoff.md:281`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the merge-tree sentence of the 281 bullet. The bullet's harden and state-gate lists are also short of the code: they name no commit-graph, GLOBAL or protocol, and no partial clone, shallow or origin/HEAD. The bullet is dated "before code". Line 282 records the split but not this change.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Stale (9) · r3=— · single-replicate detection
**Replicate annotations:**
- **r1 (Escalation 5, not a claim):** "Out of this unit's diff, but stale … still describes 'merge-tree run from a fresh empty directory against the common git dir' and a state gate without the partial clone, shallow or origin/HEAD. This is history in a split note; the reader may want it marked as superseded."

merge-tree now runs against a gate-owned git dir, `GATE_ENV+=(GIT_DIR="$GATE_TMP/git" GIT_OBJECT_DIRECTORY="$v")` (`scripts/build-loop.sh:456`). It no longer runs against the common git dir.

**Evidence:** `scripts/build-loop.sh:448-467`

---

## Claim 21: --check help state gate list: "a git config key ... a non-empty info/attributes or info/grafts, or a replace ref prints 'refuse state WHAT: WHY' per finding and exits 2 before any brief is read."

**Location:** `scripts/build-loop.sh:78-85`
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the header's list against state_gate's checks. It does not cover the state_gate comment at :167-179 (Claim 34).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Stale (15) · r2=Mostly accurate (10) · r3=Mostly accurate (8)
**Replicate annotations:**
- **r2:** Every listed item was executed in `noobj.sh`: each printed one line and the run exited 2.
- **r3:** It does not establish completeness against every git setting that can change a read.
- **r2+r3:** The commit message and the plan name both omitted refusals.

```bash
# scripts/build-loop.sh:78-85 (header excerpt; the --check entry continues to :99 — read)
#   --check   the gate (D7), advisory when a loop runs it. First a state gate:
#             a git config key (common config or config.worktree, includes not
#             followed) for a filter, include, config hook, merge or diff
#             setting, core.fsmonitor, core.attributesFile, core.hooksPath,
#             gpg.*, log.showSignature, extensions.partialClone or
#             remote.*.promisor (a partial clone), a non-empty info/attributes or
#             info/grafts, or a replace ref prints "refuse state WHAT: WHY"
#             per finding and exits 2 before any brief is read. Then one line
```
The code also refuses a non-empty `shallow` (`for f in info/attributes info/grafts shallow; do`, :192) and a foreign origin/HEAD (:198-201). Iteration 2 (c66988b6) added both checks and rewrote the state_gate comment, but did not touch this header. The header should list "a non-empty info/attributes, info/grafts or shallow, a replace ref, or an origin/HEAD naming a branch other than origin/main or origin/master". The header is what `--help` prints.

**Evidence:** `scripts/build-loop.sh:78-85`, `:192`, `:198-201`; `git show c66988b6 -- scripts/build-loop.sh` (no header hunk)

---

## Claim 22: --check help line formats "ok BRIEF TIP TREE ... refuse BRIEF: WHY ... skip BRIEF: WHY As --status skips it."

**Location:** `scripts/build-loop.sh:86-99`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three line kinds and every listed refuse reason against check_line. It does not cover reason order: the header lists "not ahead" before "moved", while the code checks moved first; the header states no order.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (16) · r2=Verified (11) · r3=Verified (9)
**Replicate annotations:**
- **r2:** It ran T16-T18. With a blob missing from the store, `--check` printed `refuse …: the merge of feat/x could not be computed`. An XDG `merge=union` attributes file does not reach the merge.
- **r3:** "It does not establish that TREE always is the merge of TIP, because a missing object yields ok with another tree (Claim 26)", which is merged Claim 42. T18 checks argument order and the copied skip line.

Each listed reason maps to a check_line branch:
- **done, dropped or new:** `the brief is $st on the default branch` (:474).
- **branch absent:** `its branch $br does not exist` (:475).
- **moved or could not be read again:** `moved or could not be read again` (:478).
- **not ahead:** `has no commit the default branch lacks` (:479).
- **TIP is not SHA:** `the tip of $br is $sha, not the expected $EXPECT` (:480).
- **conflict:** `conflicts with the default branch` (:484).
- **merge not computed:** `could not be computed` (:485).

Skips come from status_line, which check_line echoes unchanged when it is not ok: `[[ "$out" == "ok "* ]] || { echo "$out"; return; }` (:472).

**Evidence:** `scripts/build-loop.sh:86-99`, `:470-488`

---

## Claim 23: "Writes nothing but --check's merge objects (merge-tree writes the merged trees and blobs into the object store) and its own temporary directory, removed at exit."

**Location:** `scripts/build-loop.sh:102-104`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one clean-merge run: the repo's non-object files, `.git` included, and the TMPDIR afterwards. It does not cover runs killed by a signal.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (17) · r2=Verified (12) · r3=Verified (10, Medium confidence)
**Replicate annotations:**
- **r2:** It measured a conflicting run, which freshened two existing loose objects. It does not cover `--settings`/`--status`, or other runs' paths such as an object-freshening write on a clean merge.
- **r3:** It does not cover a conflicting merge ("C9 notes it writes objects as well").

p11 snapshotted every path under the repo except `.git/objects` (name, size, mtime, inode) before and after `--check`. Result: `non-object changes: none`, `new object files: 1`, `left in TMPDIR: 0`.

**Evidence:** `scripts/build-loop.sh:500-502` (`GATE_TMP="$(mktemp -d)"; trap 'rm -rf -- "$GATE_TMP"' EXIT`); `/tmp/fcu2b1a2-r1-logs/p11-writes.txt`

---

## Claim 24: "Exit: 0 every line printed (or help), and for --check every line ok; 2 any --check line or the state gate not ok; 1 bad usage, not a git repo, ..."

**Location:** `scripts/build-loop.sh:107-109`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the --check exit codes the suite exercises: 0 for ok, 2 for a refuse, a skip or the state gate, 1 for usage. It does not separately exercise the gate_repo setup failure, which also exits 2 (:503).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (18) · r2=Verified (13) · r3=Verified (11)
**Replicate annotations:**
- **r2:** It also observed exit 1 on "Not inside a git repository" and on no default branch. The no-perl and no-lib exits were not run.

The tests at :1256 (0 and 2), :1275 (1 for usage), :1295 (2 for a skip) and :1315 (2 for the state gate) all pass.

**Evidence:** `scripts/build-loop.sh:503-509`; `/tmp/fcu2b1a2-r1-logs/build-loop-check.bats.txt`

---

## Claim 25: "The full id only: a short id, a branch name or HEAD would let git pick the commit."

**Location:** `scripts/build-loop.sh:134-135`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parser's acceptance of lower-case 40- or 64-hex only, as T17 asserts. EXPECT is compared as a string (`"$sha" != "$EXPECT"`), never passed to git.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=— · r3=Verified (28) · single-replicate detection
**Replicate annotations:** none

The check is `[[ "$2" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]] || usage …` (`:135`).

**Evidence:** `scripts/build-loop.sh:129-141,481`; `test/scripts/build-loop-check.bats:1275-1293`

---

## Claim 26: "Every git call in this process, the lib's included, runs hardened."

**Location:** `scripts/build-loop.sh:147`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every PATH-resolved git call of a --check run, the env-wrapped merge-tree included, and the absence of git calls before `harden`. It does not cover git's own exec-path subprocesses, which inherit the environment but are not logged by the shim, or the caller's own `git -c` (trusted, as stated).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (19) · r2=Verified (14, compound with Claim 27) · r3=Verified (12)
**Replicate annotations:**
- **r2:** m4 (no harden), m7 and m8 each fail the shim test. It does not establish the claim for calls made by absolute path; none exist.
- **r3:** It does not cover `--settings` and `--status` runs. A lib grep for `env -u`, `GIT_CONFIG` and `GIT_DIR` finds no environment-overriding git call. ME fails the shim.

Before `harden` (:165) the script runs only `perl` and `cd`/`pwd`, sources the lib, and calls `scrub_reexec`. The lib's top level and `scrub` (perl) run no git. The child re-exec runs the same file, so it hardens before its first git call. GATE_ENV keeps `GIT_CONFIG*` (`[[ "$v" == GIT_CONFIG* || "$v" == GIT_NO_REPLACE_OBJECTS ]] || GATE_ENV+=(-u "$v")`, :451). It does not touch GIT_CONFIG_GLOBAL or GIT_ALLOW_PROTOCOL, which are not local-env-vars. The shim test passed with more than 10 calls, each carrying all five pairs, `G=/dev/null` and `P=none`.

**Evidence:** `scripts/build-loop.sh:111-122`, `:158-166`, `:451`; `test/scripts/build-loop-check.bats:1371-1383`; `/tmp/fcu2b1a2-r1-logs/build-loop-check.bats.txt`

---

## Claim 27: "core.useReplaceRefs in the repo's config would override GIT_NO_REPLACE_OBJECTS"

**Location:** `scripts/build-loop.sh:148-150`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's precedence. It does not cover later git versions.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (20) · r2=Verified (14, compound with Claim 26) · r3=—
**Replicate annotations:**
- **r2 (`env.sh`):** `NO_REPLACE env` gives `a`, `+ repo useRR=true` gives `b`, and `+ count pair false` gives `a`.

p9 replaced blob `a` with `b` and set `core.useReplaceRefs true` in the repo. `GIT_NO_REPLACE_OBJECTS=1` alone printed `b`; with the config pair added it printed `a`.

**Evidence:** `scripts/build-loop.sh:160`; `/tmp/fcu2b1a2-r1-logs/p9-replace.txt`

---

## Claim 28: "no commit-graph (a forged one changes merge bases)"

**Location:** `scripts/build-loop.sh:151`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the pair disabling git's use of the graph's commit data, both in the repo and in the gate repo, which shares the object directory holding `info/commit-graph`. It does not cover the merge-base effect, which r1's two forgeries did not reproduce (see Claim 8).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (21) · r2=Verified (15) · r3=Verified (15)
**Replicate annotations:**
- **r2:** "GIT_TEST_COMMIT_GRAPH in the caller's environment could override the pair (caller trusted)". The rationale clause rests on security F5's probe.
- **r3:** The rationale clause is not re-run; rubric A7 records the security reviewer's probe. A garbage graph gave `improper chunk offset(s)` for plain git, while `--check` printed ok (P5).

Under a forged graph, `git -c core.commitGraph=true log --format='%H %P' -1 main` printed the forged parent; with `=false` it printed the real one (p8). The pair is kept inside GATE_ENV (:451).

**Evidence:** `scripts/build-loop.sh:160`, `:451`; `/tmp/fcu2b1a2-r1-logs/p8-cgraph.txt`

---

## Claim 29: "GIT_CONFIG_GLOBAL=/dev/null: a loop can write the user's ~/.gitconfig as easily as .git/config."

**Location:** `scripts/build-loop.sh:151-152`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the export reaching every call and blocking `~/.gitconfig` and `$XDG_CONFIG_HOME/git/config`. The XDG and HOME attributes files are blocked by the `core.attributesFile=/dev/null` pair (p7). It does not cover system config (Claim 15).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (22) · r2=Verified (16) · r3=Verified (13)
**Replicate annotations:** none

p7 planted `* merge=union` in `$XDG_CONFIG_HOME/git/attributes` and `$HOME/.config/git/attributes`. A plain merge-tree applied it (`control exit 0 (0 = union applied)`), but `--check` still refused the conflict.

**Evidence:** `scripts/build-loop.sh:166`; `/tmp/fcu2b1a2-r1-logs/p7-misc.txt`

---

## Claim 30: "GIT_ALLOW_PROTOCOL=none: no transport at all, so a lazy fetch (a partial clone's missing object) fails however the config was planted, even after the state gate read it."

**Location:** `scripts/build-loop.sh:152-154`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a lazy fetch through a local-path (file) promisor remote, with `protocol.allow=always` and `protocol.file.allow=always` set in the repo. It does not separately exercise ssh or ext transports, which the same whitelist check gates.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (23) · r2=Verified (17) · r3=Verified (14)
**Replicate annotations:**
- **r2:** It also covered https (`fatal: transport 'https' not allowed`), and m10 against m3 for the superproject's partial clone. ssh and ext were not probed; ext is off by default.
- **r3:** It also covered a submodule promisor: MA gave `fetched: no`, MD gave `fetched: yes`. ssh, http and ext were not tested.

In p2, with `GIT_ALLOW_PROTOCOL=none`, `git cat-file -p <missing>` failed with `fatal: transport 'file' not allowed` and `fetched=no`. The control run without the variable ran upload-pack and gave `fetched=yes`.

**Evidence:** `scripts/build-loop.sh:166`; `/tmp/fcu2b1a2-r1-logs/p2-protocol.txt`

---

## Claim 31: "The caller's own environment is trusted: its `git -c` or a zero-padded GIT_CONFIG_COUNT can still win (U3b's --state). What the rest cannot switch off, --check's state gate refuses."

**Location:** `scripts/build-loop.sh:154-157`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the `git -c` precedence and the gate's refusal of every state the iteration-1 and iteration-2 probes named. It does not establish completeness. Two pieces of state are neither switched off nor refused: system config (Claim 15) and `objects/info/alternates`, which every call reads, merge-tree in the gate repo included. Packs and multi-pack-index belong to the same class and were not probed.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Mostly accurate (18) · r3=Mostly accurate (16, High confidence; second sentence only)
**Replicate annotations:**
- **r3:** "It does not cover the system config file, which is neither switched off nor refused, or the object-store files (alternates, multi-pack-index) under deferred F3." State_gate reads only `config` and `config.worktree` (`:183`), and P6 shows system config changing the merge result. A precise version adds "(the system config, root-owned, is trusted like the caller's environment)".

`-c core.hooksPath=/x` beats the count pair, printing `/x`. A blob present only through a planted alternates file made the merge computable: "could not be computed" without it, a normal conflict with it. Alternates can only supply objects whose ids are not in the local store, so its exposure is the same as the deferred security F3 (rewritten object bytes, override-log row 492). The state gate's files loop covers `info/attributes info/grafts shallow` only (`scripts/build-loop.sh:192`). No line reads `objects/info/alternates`. paraphrased — no quote available because the claim covers absence of code.

**Evidence:** `scripts/build-loop.sh:181-202`; `/tmp/fcu2b1a2-r2-logs/probe-env.txt`, `/tmp/fcu2b1a2-r2-logs/probe-misc.txt` ("P-alt")

---

## Claim 32: state_gate "Prints one 'refuse state WHAT: WHY' line per finding, returns 1 on any"

**Location:** `scripts/build-loop.sh:167-170`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the finding lines on an empty object store and on a clean store. It does not cover the early-return paths: an unreadable `--git-path` or for-each-ref returns 1 after one line, not "one line per finding".
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified (19, compound with Claim 33) · r3=Verified (20)
**Replicate annotations:**
- **r3:** "It does not cover the early `return 1` cases: a path that cannot be resolved, or a missing config, stops after its own line and does not list later findings." Each `echo` begins `refuse state ` (`:184-200`). The state test asserts five lines from one run and one line per key.

With every object moved out and refs packed, state_gate ran to completion. It printed its four findings (filter key, info/attributes, a replace ref, a foreign origin/HEAD) with no git error, and exited 2. With nothing planted it passed.

**Evidence:** `scripts/build-loop.sh:181-210`; `/tmp/fcu2b1a2-r2-logs/probe-noobj.txt`

---

## Claim 33: state_gate "reads no object (git config --file --no-includes follows no include; --git-path reads no index)" and "runs before any object read"

**Location:** `scripts/build-loop.sh:169-171`, `:208-209`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers state_gate's own calls and its placement before resolve_main. It does not cover `git rev-parse --show-toplevel` (:204), which runs earlier and also reads no object. No test pins the ordering (Claim 49).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (24) · r2=Verified (19, compound with Claim 32) · r3=Verified (18)
**Replicate annotations:**
- **r3:** "It does not establish that repository setup reads no config: rev-parse and the others read the repo config with includes, as any git call does." A refs/replace ref naming a missing object is still listed (P10).
- **r3 (contrary to r1 and r2 at Claim 49):** "Mutants MB and MC, with the gate after main_by_name, fail the partial-clone test: their output is `build-loop.sh needs a default branch found by name…`, exit 1."

p6 moved `.git/objects` away entirely, with a replace ref, a foreign origin/HEAD and `merge.y.driver` planted. state_gate ran `config`, `for-each-ref`, 6 `rev-parse` and `symbolic-ref`. It then printed all three refusal lines, the replace ref counted, and exited 2. No call failed.

**Evidence:** `scripts/build-loop.sh:181-203`, `:208-210`; `/tmp/fcu2b1a2-r1-logs/p6-noobj.txt`

---

## Claim 34: state_gate comment, the key list: "filter, merge and diff drivers (commands), config hooks, includes, core.attributesFile, gpg and log.showSignature …, and a partial clone", the state "which harden does not switch off"

**Location:** `scripts/build-loop.sh:167-175`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the comment's key list against `STATE_KEYS_RE`. It does not judge whether the regex is complete.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (25, compound) · r2=Verified (20, compound) · r3=Mostly accurate (17)
**Replicate annotations:**
- **r1:** "The comment's key list leaves out core.fsmonitor and core.hooksPath, which the regex refuses; that is consistent with 'which harden does not switch off', since harden pairs both. It does not cover keys outside the list (see Escalations)."
- **r2:** "the regex also refuses core.fsmonitor and core.hooksPath, which harden switches off anyway; and `merge.` and `diff.` refuse every key in those sections, not only drivers." Config.worktree is read whether or not `extensions.worktreeConfig` is set. The `--name-only` keys are lower-cased, which the regex matches.

The regex is broader than "merge and diff drivers": `'^(filter\.|include|hook\.|merge\.|diff\.|core\.fsmonitor|core\.attributesfile|core\.hookspath|gpg\.|log\.showsignature|extensions\.partialclone$|remote\..*\.promisor$)'` (`:180`) refuses every `merge.*` and `diff.*` key. The test plants `merge.renormalize` and `diff.ignoreSubmodules`, and P6 shows `merge.directoryrenames` refused. The comment's key list omits `core.fsmonitor` and `core.hooksPath`, which the regex refuses. It says the state is what "harden does not switch off", then lists `core.attributesFile`, which harden does pair (`core.attributesFile=/dev/null`, `:160`). core.fsmonitor and core.hooksPath are paired as well. A precise version reads "every filter, merge and diff key, …, core.fsmonitor, core.attributesFile, core.hooksPath (refused although harden pairs them)…".

**Evidence:** `scripts/build-loop.sh:160,167-180`; `test/scripts/build-loop-check.bats:1317-1319`

---

## Claim 35: state_gate's files: "a non-empty info/attributes, info/grafts or shallow" / "refuse state $f: present and not empty"

**Location:** `scripts/build-loop.sh:194`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the condition against its message. It does not establish any effect of the extra refusals.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate (26; also Verified within compound 25) · r2=Verified (20, compound) · r3=Verified (19, compound)
**Replicate annotations:**
- **r2:** "a symlink or non-regular entry at a file path is refused even when empty, with the message 'present and not empty'". r2 records this as a detail under its Verified verdict.
- **r3:** "The `[[ -s "$p" || -L "$p" || ( -e "$p" && ! -f "$p" ) ]]` test refuses non-empty files, symlinks and non-files, a superset of 'non-empty'". r3 records this under its Verified verdict.
- **r1 (Claim 25):** the file list was Verified within the compound, with the state test and p6 printing the line formats.

`if [[ -s "$p" || -L "$p" || ( -e "$p" && ! -f "$p" ) ]]; then echo "refuse state $f: present and not empty"; bad=1; fi`. The code also refuses an empty symlink or a directory at the path, with the same "not empty" message. The precise version: non-empty, a symlink, or not a regular file.

**Evidence:** `scripts/build-loop.sh:194`

---

## Claim 36: "an origin/HEAD naming any branch but origin/main or origin/master (resolve_main would take the default branch from it)"

**Location:** `scripts/build-loop.sh:177-179`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers resolve_main's first candidate, and that the two allowed targets resolve to the same local branches as the fallbacks. A non-symbolic origin/HEAD passes the gate (`symbolic-ref -q` exits 1); resolve_main also ignores it.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (25, compound) · r2=Verified (21) · r3=Verified (19, compound)
**Replicate annotations:**
- **r1:** A symref to `refs/remotes/origin/feat/x` makes local `feat/x` the default branch.
- **r3:** It executed symrefs to origin/main (allowed) and to refs/heads/feat/x (refused). A non-symbolic origin/HEAD passes (P4: ok).

```bash
# scripts/lib/dev-cycle-read.sh:486-488 (excerpt ends :488; resolve_main continues to :507 — read)
  origin_head="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  [[ -n "$origin_head" ]] && candidates+=("${origin_head#origin/}")
  candidates+=(main master)
```

**Evidence:** `scripts/lib/dev-cycle-read.sh:483-507`, `scripts/build-loop.sh:198-201`

---

## Claim 37: gate_repo: "a git dir with no config but the repo's object format, no modules/, info/ or shallow, and an empty directory to run in, so merge-tree reads none of the repo's config (a submodule repository under .git/modules is never opened)"

**Location:** `scripts/build-loop.sh:439-444`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers repo config, the submodule repository and the kept object format. It does not cover system config (Claim 15) or alternates (Claim 39).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (27a, compound) · r2=Verified (22, compound) · r3=Verified (21)
**Replicate annotations:**
- **r2:** the fixed submodule plant does not fetch, even with protocol allowed.
- **r3:** MF (no objectformat) fails the SHA-256 test. P9's direct run in this layout printed `Failed to merge submodule sub (not checked out)`.

- **Submodule repository (p4d):** the gate repo alone kept the submodule repository closed.
- **Object format:** the SHA-256 test passes, and mutant m2 (no objectformat) fails it.

**Evidence:** `scripts/build-loop.sh:448-456`; `/tmp/fcu2b1a2-r1-logs/p4d-gaterepo-no-protocol.txt`, `/tmp/fcu2b1a2-r1-logs/m2-no-objectformat.txt`

---

## Claim 38: "no checkout's .gitattributes (git 2.39 reads one from the current directory even under --work-tree)"

**Location:** `scripts/build-loop.sh:443-444`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers checkout attributes from the current directory and under `--work-tree`, on git 2.39.5. It does not establish other git versions' behaviour.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (27a, compound) · r2=Verified (22, compound) · r3=Verified (22)
**Replicate annotations:**
- **r2:** "the '--work-tree' wording was not probed directly. The union test shows the current-directory read in the real repo (m1 fails it)."
- **r3:** In P3, run from a directory holding `* merge=union`, `git --git-dir=… --work-tree=<other> merge-tree` exited 0. Run from an empty directory, it exited 1.

Checkout attributes (p10): from the root, git 2.39.5 applied an untracked `.gitattributes` `* merge=union`, both plain and with `--git-dir=.git --work-tree=$empty` (both `exit 0`). `--check` refused the conflict.

**Evidence:** `scripts/build-loop.sh:448-456`; `/tmp/fcu2b1a2-r1-logs/p10-attrs.txt`

---

## Claim 39: "and only the repo's object store (GIT_OBJECT_DIRECTORY, where it also writes)"

**Location:** `scripts/build-loop.sh:444-445`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which object directories merge-tree reads. It does not establish that alternates can change an object's bytes. They only add objects git lacks locally; the same-id-different-bytes issue is security F3, deferred in row 492.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Mostly accurate (27b) · r2=Verified (22, compound) · r3=Mostly accurate (23)
**Replicate annotations:**
- **r2 (its not-established item (a)):** "'only the repo's object store' includes that store's `info/alternates`, which merge-tree follows (Claim 18; F3 class)".
- **r3:** "It also reads the store's multi-pack-index: in P7 a garbage `multi-pack-index` made `--check` print `error: improper chunk offset(s)` five times on stderr and still answer ok." In P2, a branch whose tree existed only in an alternate repository gave `ok`.

GATE_ENV unsets GIT_ALTERNATE_OBJECT_DIRECTORIES, but git still follows `objects/info/alternates` inside GIT_OBJECT_DIRECTORY. In p1, `.git/objects/info/alternates` pointed at another repository's store, and feat/x's tip existed only there (`objects alt-only? not-local`). `--check` printed `ok … b3895f8… 4f26876…` and exited 0. The state gate does not check that file. Precise version: the repo's object store and any alternates it lists; writes go to GIT_OBJECT_DIRECTORY.

**Evidence:** `scripts/build-loop.sh:451-456`; `/tmp/fcu2b1a2-r1-logs/p1-alternates.txt`

---

## Claim 40: "GATE_ENV unsets the repo-local variables (GIT_COMMON_DIR and the like) that would point it back."

**Location:** `scripts/build-loop.sh:445-446,451`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the variables `git rev-parse --local-env-vars` lists in git 2.39.5. All of them are unset except `GIT_CONFIG`, `GIT_CONFIG_PARAMETERS`, `GIT_CONFIG_COUNT` and `GIT_NO_REPLACE_OBJECTS`, which are kept on purpose. GIT_DIR and GIT_OBJECT_DIRECTORY are then set again. It does not establish behaviour under an inherited `GIT_CONFIG_PARAMETERS`, the caller's own `git -c`, which the harden comment trusts.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (27a, compound) · r2=Verified (22, compound) · r3=Verified (24)
**Replicate annotations:**
- **r1+r2:** they executed `--local-env-vars`. It lists GIT_COMMON_DIR, GIT_ALTERNATE_OBJECT_DIRECTORIES, GIT_GRAFT_FILE, GIT_SHALLOW_FILE and the rest.

The code is `for v in $(git rev-parse --local-env-vars); do [[ "$v" == GIT_CONFIG* || "$v" == GIT_NO_REPLACE_OBJECTS ]] || GATE_ENV+=(-u "$v"); done` (`:451`), then `GATE_ENV+=(GIT_DIR="$GATE_TMP/git" GIT_OBJECT_DIRECTORY="$v")` (`:456`). The list includes GIT_COMMON_DIR, GIT_WORK_TREE, GIT_INDEX_FILE, GIT_GRAFT_FILE, GIT_SHALLOW_FILE and GIT_ALTERNATE_OBJECT_DIRECTORIES.

**Evidence:** `scripts/build-loop.sh:448-457`

---

## Claim 41: merge_result "returns 1 on a conflict (a gitlink both sides moved is one, since no submodule repository is reachable)"

**Location:** `scripts/build-loop.sh:458-460`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a gitlink moved by both sides from a shared base (p4). The suite's own submodule test does not reach this case (Claim 51).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (28, compound with Claim 42) · r2=Verified (23, compound with Claim 42) · r3=Verified (25)
**Replicate annotations:**
- **r3:** "The suite's own submodule test does not reach this case."

```bash
# scripts/build-loop.sh:463-466
  out="$(cd "$GATE_TMP/work" && "${GATE_ENV[@]}" git merge-tree --write-tree --no-messages "$MAIN_SHA" "$1" 2>/dev/null)" || rc=$?
  [[ "$rc" -le 1 && "${out%%$'\n'*}" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]] || return 2
  [[ "$rc" -eq 0 ]] || return 1
  echo "${out%%$'\n'*}"
```
In p4 and p4d the script printed the conflict refusal.

**Evidence:** `scripts/build-loop.sh:461-467`; `/tmp/fcu2b1a2-r1-logs/p4-submodule-base.txt`

---

## Claim 42: merge_result "… 2 when git failed" (and the header's refuse reason "or the merge could not be computed"; "TREE is the merge of TIP into main")

**Location:** `scripts/build-loop.sh:460`, `scripts/build-loop.sh:89-90,96`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a branch tip whose tree object cannot be read. It does not cover rewritten bytes (deferred F3) or how U2b1b's per-path rules would judge the resulting tree.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (28 and 16, compound) · r2=Verified (23 and 11, compound) · r3=Incorrect (26)
**Replicate annotations:**
- **r1:** "It does not cover the rc-2 path, which no test exercises."
- **r2:** For rc 2, a missing blob produced "could not be computed". "It does not establish rc 2 for every git failure shape. Any first line that is not a hash, or an exit above 1, maps to 2."
- **r1 (Claim 24) and r2 (Claim 24, the T16 test):** no test plants rc 2.

merge_result keys failure on git's exit status alone, and stderr is discarded: `… merge-tree --write-tree --no-messages "$MAIN_SHA" "$1" 2>/dev/null)" || rc=$?` (`:463`). The next line is `[[ "$rc" -le 1 && "${out%%$'\n'*}" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]] || return 2` (`:464`). When the tip's tree is missing, git 2.39.5's merge-tree prints `error: Could not read 052f6cb…` and still exits 0 with a tree. In P2, `--check` with the alternates file removed printed `ok docs/working/briefs/2026-10-01-x.md 80d9b89… 2795b1c5…`, exit 0. That tree holds only `main.txt`: the branch's side is read as empty, so the brief is deleted. It is not the merge of TIP. status_line never reads the tip's tree (check_branch reads the commit, the count and the date), so nothing earlier refuses it. A same-uid loop can reach this by deleting an object file or writing a commit that names an absent tree.

**Evidence:** `scripts/build-loop.sh:461-467`; `scripts/lib/dev-cycle-read.sh:436-454`; `/tmp/fcu2b1a2-r3-probe/p2.log`. r3 ran a direct `git merge-tree` reproduction in the P2 repo at the prompt. It printed the error with rc 0, and r3 quotes that output above.

---

## Claim 43: check_line "ok BRIEF TIP TREE, or one skip or refuse line (from status_line, then the gate's own reasons)" and its field parsing

**Location:** `scripts/build-loop.sh:468-488`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the field positions against status_line's and check_branch's printed formats, and the check order. It does not cover brief paths holding blanks, which check_brief governs.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (29) · r2=— · r3=Verified (27)
**Replicate annotations:**
- **r3:** "It does not establish atomicity between the two check_branch reads." Every non-ok line status_line prints begins `skip`, and T16-T18 pass.

status_line prints `"ok $a $st $pol $br $loop $sha $date $disp$reason"` (:435), and check_line reads `read -r _ _ st _ br loop sha _`, which gives fields 3, 5, 6 and 7. check_branch prints `"ok $a $sha $n $d"` (lib :447), and check_line reads `read -r _ _ _ n _`, which gives field 4. The order is state, absent, moved/unreadable, not ahead, --expect, then merge.

**Evidence:** `scripts/build-loop.sh:400-436`, `:470-488`; `scripts/lib/dev-cycle-read.sh:436-450`

---

## Claim 44: T16 test title: "--check: a clean merge is ok with the tip and the merged tree; main's later commits are merged, not judged; a conflict refuses (T16, U2b1a)"

**Location:** `test/scripts/build-loop-check.bats:1256`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact ok line, with TREE compared to a direct `git merge-tree`, after main moves on, and the exact conflict refusal. It does not cover rc 2 ("could not be computed"), which no test plants.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Verified (24) · r3=— · single-replicate detection
**Replicate annotations:** none

The test asserts `[ "$output" = "ok $B $t $(git merge-tree --write-tree main feat/x)" ]` and then `"refuse $B: feat/x conflicts with the default branch"` (`:1259-1263`). It passes.

**Evidence:** `test/scripts/build-loop-check.bats:1256-1264`; `/tmp/fcu2b1a2-r2-logs/build-loop-check.bats.txt`

---

## Claim 45: test "--check's merge reads no checkout attributes: an untracked .gitattributes, or one planted in .git, cannot turn a conflict into a union merge"

**Location:** `test/scripts/build-loop-check.bats:1266`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the untracked root `.gitattributes`, which is a live plant (mutant m1 fails the test). It does not establish that `.git/.gitattributes` alone is live; that file is a plant for the iteration-1 design, which ran from `.git`.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (30) · r2=Verified (25) · r3=Verified (29)
**Replicate annotations:**
- **r2+r3:** the test does not separate the two plants; either alone could trip the mutant.
- **r2:** m2 also fails the test.

Under m1: `not ok 1 --check's merge reads no checkout attributes…`, `status 0`, `ok …`.

**Evidence:** `test/scripts/build-loop-check.bats:1266-1273`; `/tmp/fcu2b1a2-r1-logs/m1-realrepo-mergetree.txt`

---

## Claim 46: T17, T18 and T20 test titles

The three titles in full:
- **T17:** "--check --expect: the tip's full id passes in either order; a stale id refuses; a short id, a name, HEAD, upper case, no value, a second --expect or two briefs are usage errors"
- **T18:** "--check refuses a brief done, dropped or new on main, a branch absent or not ahead; skips what --status skips; answers each brief and exits 2 on any refusal"
- **T20:** "build-loop.sh and the reader lib never push"

**Location:** `test/scripts/build-loop-check.bats:1275`, `:1295`, `:1351`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what each body asserts against its title, and all three pass. T17 asserts each listed case, with exit 1, empty stdout and the usage text. T18 asserts each refusal's exact text, the three-brief output in order with exit 2, and the F31 skip. T20 is a word grep for "push" over the two files.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Verified (26, compound with Claim 47) · r3=— · single-replicate detection
**Replicate annotations:** none

paraphrased — no quote available because the claim covers three test bodies; r2's Scope names each assertion.

**Evidence:** `test/scripts/build-loop-check.bats:1275-1354`; `/tmp/fcu2b1a2-r2-logs/build-loop-check.bats.txt`

---

## Claim 47: test "--check's state gate refuses each planted git state that can run a command or change the merge, before reading any brief"

**Location:** `test/scripts/build-loop-check.bats:1315`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 16 keys one at a time (one output line each), config.worktree, the three files, a replace ref and origin/HEAD. "Before reading any brief" is checked only by the output being state lines alone (C1).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (31) · r2=Verified (26, compound) · r3=Verified (30)
**Replicate annotations:**
- **r2:** "T26's 'before reading any brief' is asserted only as the absence of a brief line; ordering against resolve_main is Claim 27's subject" (merged Claim 49).

Each key is set, run, required to produce exactly one `refuse state …: set in config…` line, then unset. The test then plants config.worktree, followed by the file and ref plants together with an exact five-line expectation. It passed.

**Evidence:** `test/scripts/build-loop-check.bats:1315-1342`; `/tmp/fcu2b1a2-r1-logs/build-loop-check.bats.txt`

---

## Claim 48: test "--check refuses a partial clone ... a promisor remote's upload-pack never runs for a missing object"

**Location:** `test/scripts/build-loop-check.bats:1356`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal (both key lines, exit 2) and the no-fetch mark. The mark fails only when both the gate ordering and GIT_ALLOW_PROTOCOL are broken (mutant b: `fetched=yes`).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (32a) · r2=Verified (27a) · r3=Verified (31, compound with Claim 49)
**Replicate annotations:**
- **r2:** m9 (no keys) fails the test.
- **r3:** "Since GIT_ALLOW_PROTOCOL=none, the upload-pack assertion no longer separates the gate's order from the transport block, so the output assertion carries the test."

The plant is live: mutant b, with the gate after resolve_main and no protocol block, ran upload-pack.

**Evidence:** `test/scripts/build-loop-check.bats:1356-1369`; `/tmp/fcu2b1a2-r1-logs/p5-r1-mutations.txt`

---

## Claim 49: same test title, "... before any object is read"

**Location:** `test/scripts/build-loop-check.bats:1356`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the test pins the gate-before-resolve_main ordering. It does not question the ordering in the code, which is correct (Claim 33).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect (32b) · r2=Incorrect (27b) · r3=Verified (31, compound with Claim 48)
**Replicate annotations:**
- **r3 (conflicting execution result):** "Covers the order of the gate: mutants MB and MC fail on the output assertion." MB and MC printed `not ok 1 …` with `build-loop.sh needs a default branch found by name…`. r3 describes MB as the gate moved after `main_by_name`, where r1 and r2 moved it after `resolve_main || true`. The two placements differ, which may explain the conflict.
- **r2:** "A test that sees an object read before the gate (an unreadable store with a planted key, as in `noobj.sh`, run under m3) would pin it." The test's comment at `:1363` ("so the gate must run before resolve_main") is part of r2's claim.

Mutant a moves `state_gate` after `resolve_main || true` and keeps GIT_ALLOW_PROTOCOL. Under it the test's exact assertions still hold: exit 2, the two refusal lines, `fetched=no`. resolve_main's read of the deleted commit fails without fetching, and it falls back to HEAD (`MAIN_SHA` set, `MAIN_BY_NAME` empty). The gate then refuses as before. The test cannot tell the gate ran before the first object read.

**Evidence:** `scripts/lib/dev-cycle-read.sh:496-503`; `/tmp/fcu2b1a2-r1-logs/p5-r1-mutations.txt` (block `/tmp/fcu2b1a2-r1-mut/a`)

---

## Claim 50: test "every git call --check makes carries harden's config pairs (core.hooksPath=/dev/null among them), no global config and no transport"

**Location:** `test/scripts/build-loop-check.bats:1371`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers PATH-resolved git calls, the env-wrapped merge-tree included. It does not cover git's internal exec-path subprocesses.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (33) · r2=Verified (28) · r3=Verified (32)
**Replicate annotations:**
- **r2:** m4, m7 and m8 each fail the test. "It does not check GIT_LITERAL_PATHSPECS, GIT_NO_REPLACE_OBJECTS, GIT_OPTIONAL_LOCKS or GIT_ATTR_NOSYSTEM; the title does not claim them."
- **r3:** ME printed `# a call without core.commitGraph=false`.

`! grep -v -- " $kv" "$BATS_TEST_TMPDIR/calls" || { echo "a call without $kv"; return 1; }` fails if any logged line lacks a pair. That covers all five pairs, `G=/dev/null` and `P=none`. The test also requires more than 10 calls. It passed.

**Evidence:** `test/scripts/build-loop-check.bats:1371-1383`

---

## Claim 51: test "--check's merge opens no submodule repository: a promisor one under .git/modules never fetches, and the moved gitlink is a conflict"

**Location:** `test/scripts/build-loop-check.bats:1394`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test exercises at 63ea50e7. It does not question the code's behavior, which is right (Claims 1, 41).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect (34) · r2=Incorrect (29) · r3=Incorrect (33)
**Replicate annotations:**
- **r2+r3:** the test also passes with transport allowed (m2/MD).
- **r3:** "Even with that plant, while GIT_ALLOW_PROTOCOL=none is in place the 'never fetches' assertion would not tell gate_repo's isolation from the transport block. Only the merge-tree message ('not checked out') or a mutant run without GIT_ALLOW_PROTOCOL tells them apart."

```bash
# test/scripts/build-loop-check.bats:1397-1398 (excerpt ends :1398; the test continues to :1408 — read)
    printf '[submodule "sm"]\n\tpath = sub\n\turl = ./nowhere\n' > .gitmodules
    git update-index --add --cacheinfo "160000,$s1,sub"; commit_all sub1
```
`commit_all` runs `git add -A`, which drops the gitlink because there is no `sub` path in the worktree. So the merge base has no `sub`, and both sides add a different gitlink. merge-ort reports `Failed to merge submodule sub (no merge base)` without opening any submodule repository, and an unprotected merge-tree in the real repo does not fetch (p3). The test passes under mutant m1. So the test checks neither "opens no submodule repository" nor a "moved" gitlink. It needs a base that keeps the gitlink. One way is `git add .gitmodules; git update-index …; git commit` as in p4, where unprotected merge-tree fetches.

**Evidence:** `test/scripts/build-loop-check.bats:1394-1408`; `test/lib/build-loop-fixtures.bash:28`; `/tmp/fcu2b1a2-r1-logs/p3-submodule.txt`, `/tmp/fcu2b1a2-r1-logs/p4-submodule-base.txt`, `/tmp/fcu2b1a2-r1-logs/m1-realrepo-mergetree.txt`

---

## Claim 52: test "--check merges in a SHA-256 repository: TIP and TREE are 64-hex"

**Location:** `test/scripts/build-loop-check.bats:1411`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers TIP's length explicitly, and TREE through equality with sha256 `git merge-tree` output. TREE's length is not asserted separately.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (35) · r2=— · r3=Verified (34)
**Replicate annotations:**
- **r2 (Claim 29's Scope, not its own claim):** "The SHA-256 test (`:1411`), checked alongside, is Verified: m5 fails it, and it asserts a 64-hex TIP and the TREE from `git merge-tree`."
- **r3:** MF printed `refuse …: the merge of feat/x could not be computed`, status 2.

The test passes, and mutant m2 fails it.

**Evidence:** `test/scripts/build-loop-check.bats:1411-1416`; `/tmp/fcu2b1a2-r1-logs/m2-no-objectformat.txt`

---

## Claim 53: commit 63ea50e7 "Suites: build-loop-check 91, build-loop-read 19, dev-cycle 78, fixture-git-env 2, fixture-hermeticity 2."

**Location:** commit 63ea50e7 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts and passing at 63ea50e7 under git 2.39.5. It does not cover other suites.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (36) · r2=Verified (30, compound) · r3=Verified (35)
**Replicate annotations:**
- **r2+r3:** they checked the counts against the logged hallucination patterns ("All 85 tests", "mode1-equiv 33"), and here the counts are exact.

`bats --count` gave 91, 19, 78, 2 and 2 (fixture-hermeticity is `test/fixture-hermeticity.bats`). All suites ran to exit 0, with last lines `ok 91 …`, `ok 19 …`, `ok 78 …`, `ok 2 …` and `ok 2 …`.

**Evidence:** `/tmp/fcu2b1a2-r1-logs/build-loop-check.bats.txt` and the other four `*.bats.txt` logs in that directory

---

## Claim 54: commit 63ea50e7 "330 code lines against U2b1a1."

**Location:** commit 63ea50e7 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers added plus deleted lines (the convention the command implies). Added lines alone are 316.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (37) · r2=Verified (30, compound) · r3=Verified (36)
**Replicate annotations:**
- **r2:** "The figure counts test and comment lines."

`git diff --numstat feat/build-loop-u2b1a1...HEAD -- ':(top)' ':(top,exclude)docs/'` gives `165 11 scripts/build-loop.sh` and `151 3 test/scripts/build-loop-check.bats`. 165+11+151+3 = 330.

**Evidence:** command output (run in the worktree, 2026-10-08) over `scripts/build-loop.sh` and `test/scripts/build-loop-check.bats`

---

## Claim 55: commit 63ea50e7 "Its code, tests and review history are feat/build-loop-u2b1a at c66988b6"

**Location:** commit 63ea50e7 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers tree identity outside docs/. It does not establish ancestry: c66988b6 is not an ancestor of U2b1a1, since the units are a re-split.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (38) · r2=Verified (30, compound) · r3=Verified (37)
**Replicate annotations:**
- **r2+r3:** docs/reviews is byte-identical too.

`git rev-parse feat/build-loop-u2b1a` gives `c66988b6…`. `git diff --stat c66988b6 HEAD -- ':(exclude)docs/'` is empty. The whole diff touches only `docs/working/plan-build-loop-handoff.md` (+1) and `docs/working/questions.md`.

**Evidence:** command output (run in the worktree, 2026-10-08)

---

## Claim 56: commit 63ea50e7's bullets (harden, state_gate, gate_repo "so no checkout attributes, repo config or submodule repository reach the merge", check_line, tests) and "security F3 ... is deferred with an override row"

**Location:** commit 63ea50e7 message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each bullet against the code and tests (Claims 26-52) and the F3 row. The "no repo config" wording does not extend to system config or alternates (Claims 15, 39).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (39) · r2=Verified (30, compound) · r3=Verified (38)
**Replicate annotations:**
- **r2:** "The Tests bullet's 'the … submodule plants' exists but does not test what it is for (Claim 29). That is a test defect, not a false statement in the message."
- **r3:** "It does not establish that the listed submodule plant exercises its path (Claim 33)." Both point to merged Claim 51.

The state_gate bullet's list matches the code, shallow and origin/HEAD included. The tests named are all present. Override row 492 (2026-10-08, `feat/build-loop-u2b1a`) records F3 as deferred.

**Evidence:** `scripts/build-loop.sh:158-210`, `:439-510`; `docs/reviews/override-log.md:492`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:16`): R2's test note is false of the committed test. The submodule test's mutant (merge-tree in the real repo) does not fetch, because the fixture's merge base has no gitlink. All three replicates agree.
- **Claim 3** (`docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:48`): "merge-tree in the real repo (submodule … tests fail)". The submodule test passes under that mutant; only the union test fails. All three agree.
- **Claim 42** (`scripts/build-loop.sh:460`, `:89-90,96`): "2 when git failed" is false. merge-tree exits 0 after `error: Could not read <tree>`, and `--check` prints `ok` with a tree that is not the merge of TIP. Only r3 found this; r1 and r2 marked it Verified within compounds.
- **Claim 49** (`test/scripts/build-loop-check.bats:1356`): the title's "before any object is read" is not pinned. With the gate moved after resolve_main the test still passes. r1 and r2 say Incorrect; r3's MB and MC mutants fail the test instead.
- **Claim 51** (`test/scripts/build-loop-check.bats:1394`): `commit_all`'s `add -A` drops the base gitlink, so git never opens a submodule repository, and the test passes with merge-tree in the real repo. All three agree.

### Stale
- **Claim 16** (`docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:60`): R1's "both mutants let upload-pack run" was true before GIT_ALLOW_PROTOCOL. At 63ea50e7 neither mutant fetches.
- **Claim 20** (`docs/working/plan-build-loop-handoff.md:281`): "merge-tree … against the common git dir" now runs in a gate-owned git dir (r2 only; r1 escalated it).
- **Claim 21** (`scripts/build-loop.sh:78-85`): the `--check` help's state gate list omits the shallow and origin/HEAD refusals added in iteration 2. r1 says Stale; r2 and r3 say Mostly accurate.

### Mostly Accurate
- **Claim 15** (`docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:46`): C11 is fixed for global config and GIT_COMMON_DIR only. System config still reaches the gate merge, though it is root-owned here.
- **Claim 31** (`scripts/build-loop.sh:154-157`): "What the rest cannot switch off, the state gate refuses" leaves out system config and `objects/info/alternates`.
- **Claim 34** (`scripts/build-loop.sh:167-175`): the comment's key list omits core.fsmonitor and core.hooksPath, narrows merge/diff to "drivers", and "which harden does not switch off" contradicts core.attributesFile.
- **Claim 35** (`scripts/build-loop.sh:194`): "present and not empty" is also printed for an empty symlink or a non-regular file.
- **Claim 39** (`scripts/build-loop.sh:444-445`): "only the repo's object store" leaves out `objects/info/alternates`, which merge-tree follows and which the state gate does not check. It also leaves out the multi-pack-index.

### Unverifiable
- none

## Escalations

1. **The submodule test is vacuous, and the rubric's R2 test note and mutant line rest on it.**
   - **Where:** `test/scripts/build-loop-check.bats:1394` and `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:16`, `:48` (Claims 2, 3, 51).
   - **Raised by:** r1 (Escalation 1; Goal-Alignment Escalate), r2 (Escalation 1; Goal-Alignment Escalate) and r3 (Escalation 2; Goal-Alignment Escalate).
   - **Addressee:** orchestrator (for-orchestrator-synthesis).
   - **Problem:** the code is right, but nothing in the suite pins gate_repo's submodule isolation. Only the union test catches merge-tree run in the real repo.
   - **Fix (r1, r2):** commit the base gitlink without `add -A`.
   - **Further fix (r3):** add an assertion that tells gate_repo apart from GIT_ALLOW_PROTOCOL.
2. **The gate-before-object-read ordering is unpinned.**
   - **Where:** `test/scripts/build-loop-check.bats:1356` (Claims 16, 49).
   - **Raised by:** r1 (Escalation 2) and r2 (Escalation 2).
   - **Addressee:** orchestrator (for-orchestrator-synthesis).
   - **Problem:** since iteration 2, GIT_ALLOW_PROTOCOL masks the ordering mutant.
   - **Suggested test (r2):** an object store resolve_main cannot read, with a planted key, asserting the refuse lines and no "default branch" error.
   - **Conflict:** r3's Claim 31 reports the opposite mutant outcome. In r3, MB and MC fail the test; r3 placed the gate after `main_by_name`.
3. **`--check` prints ok for a merge git could not read.**
   - **Where:** `scripts/build-loop.sh:463-464` (Claim 42).
   - **Raised by:** r3 (Escalation 1; Goal-Alignment Escalate).
   - **Addressee:** orchestrator. The orchestrator decides whether this is a finding for this unit or an override row next to F3.
   - **Problem:** with the tip's tree missing, merge-tree exits 0 after `error: Could not read …`, and check_line prints `ok BRIEF TIP TREE`.
   - **Closure options (r3):** check `git cat-file -e "$sha^{tree}"` before merge-tree, or refuse on non-empty merge-tree stderr.
4. **System config reaches every gate call, merge-tree included.**
   - **Where:** `scripts/build-loop.sh:166` (Claims 15, 31).
   - **Raised by:** r1 (Escalation 3), r2 (Claim 18) and r3 (Escalation 3; Goal-Alignment out of scope: "whether the threat model should include system config (security's call)").
   - **Addressee:** orchestrator, and security-reviewer for the threat-model question.
   - **Problem:** it is root-owned in this container. Security F8 and architecture 5(b) recommended `GIT_CONFIG_NOSYSTEM=1`, and the rubric marks C11 Fixed without it (r3).
   - **Choice:** record it as trusted (comment plus override row), or add the variable.
5. **`objects/info/alternates` reaches merge-tree and is not refused. Packs and multi-pack-index are read as usual.**
   - **Where:** `scripts/build-loop.sh:444-445`, `:192` (Claims 31, 39).
   - **Raised by:** r1 (Escalation 3) and r2 (Escalation 3, informational).
   - **Addressee:** orchestrator.
   - **Exposure:** the same class as deferred F3 (`docs/reviews/override-log.md:492`).
   - **Suggestion (r2):** the F3 row could name alternates, packs and multi-pack-index alongside loose objects when U3's re-hash work lands.
6. **The hallucination log was not updated for the test-outcome pattern.**
   - **Where:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:16`, `:48` (Claims 2, 3).
   - **Raised by:** r1 (Escalation 4).
   - **Addressee:** orchestrator.
   - **Proposal (r1):** append one line to `docs/reviews/hallucination-patterns.md` for a "test outcome claimed for an artifact that does not show it".
   - **Dissent:** r2 calls the Incorrect verdicts "test-power and stale-note findings", not fabricated symbols. r3 says "nothing goes into the log".
7. **Plan U2b1a bullet stale, out of this unit's diff.**
   - **Where:** `docs/working/plan-build-loop-handoff.md:281` (Claim 20).
   - **Raised by:** r1 (Escalation 5) and r2 (Claim 9).
   - **Addressee:** orchestrator (for-author). The reader may want it marked as superseded.
8. **Doc drift: the `--help` list, the state_gate comment and the object-store wording lag the code.**
   - **Where:** `scripts/build-loop.sh:78-85`, `:167-175`, `:444-445` (Claims 21, 34, 39).
   - **Raised by:** r3 (Escalation 4).
   - **Addressee:** orchestrator (for-author only).
9. **Keys outside STATE_KEYS_RE that could change reads (e.g. `i18n.logOutputEncoding`).**
   - **Where:** `scripts/build-loop.sh:180` (Claim 34).
   - **Raised by:** r1 (Goal-Alignment out of scope; Claim 25 Scope "see Escalations").
   - **Addressee:** security-reviewer.

## Verdict stability

- **Total clusters:** 56. Six are single-replicate detections: Claims 11, 13, 20, 25, 44 and 46.
- **Clusters where all reporting replicates agreed:** 50, the six single-replicate clusters included.
- **Clusters where verdicts disagreed:** 6.
  - **Claim 21** (`scripts/build-loop.sh:78-85`): r1=Stale · r2=Mostly accurate · r3=Mostly accurate. Merged Stale.
  - **Claim 34** (`scripts/build-loop.sh:167-175`): r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate. Merged Mostly accurate.
  - **Claim 35** (`scripts/build-loop.sh:194`): r1=Mostly accurate · r2=Verified (compound) · r3=Verified (compound). Merged Mostly accurate.
  - **Claim 39** (`scripts/build-loop.sh:444-445`): r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate. Merged Mostly accurate.
  - **Claim 42** (`scripts/build-loop.sh:460`): r1=Verified (compound) · r2=Verified (compound) · r3=Incorrect. Merged Incorrect.
  - **Claim 49** (`test/scripts/build-loop-check.bats:1356`): r1=Incorrect · r2=Incorrect · r3=Verified (compound). Merged Incorrect.
- **Agreement rate:** 50/56 = 89.3%. Over the 50 clusters surfaced by two or more replicates it is 44/50 = 88.0%.
- **Falsifier check:** the ≥20-claim sample is met, and agreement is below 90%, so the k=2 falsifier is not met by this run. Five of the six disagreements (all but Claim 21) are compound-against-split rows, where a compound Verified lost to a finer replicate's verdict on one part.
