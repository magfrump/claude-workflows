Commit: 9f80368a

# Code Fact-Check Report

**Repository:** claude-workflows, worktree `.claude/wt-2026-11-05-d6-block-into-image`, branch `refactor/d6-block-into-image`
**Scope:** `git diff 5b20d4bd..HEAD` at HEAD 9f80368a (9 files, four commits), plus the code those claims describe
**Checked:** 2026-11-05
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 42
**Summary:** 29 verified, 6 mostly accurate, 4 stale, 3 incorrect, 0 unverifiable

HEAD moved from 5600a101 to 9f80368a just after this pass began. Commit 9f80368a is dated 06:53:18Z and every run below started at 06:55:56Z or later, so all runs saw 9f80368a. Each file changed by 9f80368a was re-read. No claim in scope matches a pattern in `docs/reviews/hallucination-patterns.md`.

## Execution provenance

Each row ran under `timeout`. The cwd of E1 is the worktree; E2 to E4 ran from the scratch directory `/tmp/claude-1000/-workspace/47403b7b-5fcb-4e13-8807-c539081df064/scratchpad/2026-11-05-d6-block-into-image/fc1/` (below, FC1). Logs stay in FC1 because the dispatch allowed no edit but this report, so `docs/reviews/execution-logs/` was not used.

| Id | Command | Exit | Start (UTC) | Output |
|---|---|---|---|---|
| E1 | `TMPDIR=FC1 timeout 280 bats -f 'd6\|GATE_CODE\|git_harden' test/scripts/build-loop-orchestrator.bats`, then `timeout 120 bats -f 'floor\|gate' test/scripts/build-loop-check.bats` | 0, 0 (15 of 15 and 24 of 24 ok) | 2026-11-06T06:55:56Z | FC1/bats-d6.log, FC1/bats-check.log |
| E2 | `timeout 200 bash probe1.sh` (exits, broken libs, symlink, exported pairs, every mode on a symbolic and a tag main, grafts, replace, shim, BASH_ENV, scrub) | 0 | 2026-11-06T06:56:49Z | FC1/probe1.log |
| E3 | `timeout 400 bash probe2.sh` (old block on today's image and a new-image stand-in; diff of block and d6.sh at da07a77c). Its section L is superseded by E4 | 1 (section L's last grep counted 0 leftover worktrees) | 2026-11-06T06:57:34Z | FC1/probe2.log |
| E4 | `timeout 500 bash probe3.sh` (three reverts in scratch `git worktree add --detach` trees, all removed; shellcheck) | 0 | 2026-11-06T06:58:15Z | FC1/probe3.log |

---

## Claim 1: "every check the block ran, and its refuse d6: lines and exit 2, run unchanged from the file"

**Location:** commit da07a77c message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the code of d6.sh at da07a77c against the block at 5b20d4bd; does not establish identical stdin during the pre-checks, since only the final exec now carries `</dev/null`.
**Legibility-target:** for-orchestrator-synthesis

Provenance E3, section K. With the block's indent removed, the only non-comment differences are `local s="${1:-}" x m n sha f` becoming `s="${1:-}"` and the tail: `env -u BASH_ENV ... "$@"`, `exit "$?"`, the function close and `d6 "$@" </dev/null` became `exec env -u BASH_ENV ... "$@" </dev/null`. Every `no`, `own` and `g` line is unchanged.

**Evidence:** `scripts/d6.sh:53-54`, FC1/probe2.log

---

## Claim 2: "scripts/ is already a payload item and a .sh file is made 0555, so neither the installer nor the Dockerfile changes... The skill and d6.sh ship in one payload"

**Location:** commit da07a77c message
**Type:** Configuration / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the payload list, the staging from one commit and the mode rule; does not establish a built image, since no image was built.
**Legibility-target:** for-orchestrator-synthesis

`devcontainer-config/install.sh:146`: `CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)`. `devcontainer-config/install.sh:348`: `extract_commit "$commit" "$stage" "${CLAUDE_HOME_SRC[@]}"`, one `$commit` for all items. `devcontainer-config/Dockerfile:528`: `find /opt/claude-workflows -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod 0555 {} +`. The branch's file list has nothing under `devcontainer-config/` (paraphrased — no quote available because the claim covers absence from a `git diff --stat`).

**Evidence:** `devcontainer-config/install.sh:146`, `devcontainer-config/install.sh:268-285`, `devcontainer-config/install.sh:348`, `devcontainer-config/Dockerfile:508`, `devcontainer-config/Dockerfile:525-528`

---

## Claim 3: "Reverting this commit alone restores every check"

**Location:** commit 2b0838bb message
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `git revert 2b0838bb` at 5600a101 and at 9f80368a, and the two-commit revert at 9f80368a, with the 13 d6-filtered cases of the reverted file; does not establish that the two-commit result passes the whole health check, which this pass may not run.
**Legibility-target:** for-author

Provenance E4. True when written: at 5600a101 the revert applied (exit 0), left no difference from da07a77c under `scripts test skills`, and all 13 filtered cases passed. At HEAD it no longer applies: commit 9f80368a rewrote lines 2b0838bb introduced, so `git revert --no-commit 2b0838bb` exits 1 with `CONFLICT (content): Merge conflict in scripts/d6.sh`. The hunks that collide are `have=""` and `# shellcheck source=lib/dev-cycle-read.sh` (`scripts/d6.sh:35,47`).

What works at HEAD is `git revert --no-commit 9f80368a 2b0838bb`: exit 0, no difference from da07a77c, 13 of 13 ok, six check strings back in d6.sh. That also undoes 9f80368a's 127-test change.

Fix: fold 9f80368a's d6.sh hunks into 2b0838bb so the message holds, or leave the history and correct the research doc (Claim 13), which is what the owner reads.

**Evidence:** `scripts/d6.sh:35`, `scripts/d6.sh:47`, FC1/probe3.log

---

## Claim 4: "the audit's reason for dropping grafts is wrong (hardened git follows info/grafts); it is dropped as a hostile-only residual instead, as unit 1 did for --state"

**Location:** commit 2b0838bb message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 under `git_harden` and unit 1's record; does not establish behaviour of later git versions.
**Legibility-target:** for-orchestrator-synthesis

Provenance E2, section F: three commits, one cut, `graft plain: 2`, `graft hardened: 2`. `docs/working/research-2026-11-01-relax-gate-git-state.md:31` reads `grafts: hostile-only. ... Keep `shallow`; drop the rest.` The audit's reason is at `docs/working/research-2026-11-01-restriction-audit.md:109`: `the gate's own git already sets `GIT_NO_REPLACE_OBJECTS``.

**Evidence:** `docs/working/research-2026-11-01-relax-gate-git-state.md:31`, `docs/working/research-2026-11-01-restriction-audit.md:109`, FC1/probe1.log

---

## Claim 5: "The lib's array named m made shellcheck read d6.sh's string as one, now that d6.sh sources the lib. The 127 test takes the skill's line as argv, not through a shell re-parse."

**Location:** commit 9f80368a message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the warning under the health check's flags (`-x -e SC1091 -s bash -S warning`), with the old file's source path made literal so shellcheck follows it; does not establish the exact output of `scripts/health-check.sh`, which was not run.
**Legibility-target:** for-orchestrator-synthesis

Provenance E4: the old file gives `SC2178 (warning): Variable was used as an array but is now assigned a string` at `m=""`, exit 1; the new file exits 0. The lib's array is `local -A m=()` (`scripts/lib/dev-cycle-read.sh:365`). The test now reads `read -r -a w <<<"$l"; run -127 --separate-stderr "${w[@]}"` (`test/scripts/build-loop-orchestrator.bats:296`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:365`, `test/scripts/build-loop-orchestrator.bats:296`, `scripts/health-check.sh:525`, FC1/probe3.log

---

## Claim 6: "the snippet is no longer inline in SKILL.md and is no longer pasted... d6.sh keeps... it drops... Its git is the image lib's git_harden, so the repeated G= list and its pin are gone."

**Location:** `docs/working/plan-build-loop-handoff.md:88`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed keep and drop against d6.sh and the skill; the amendment's F38 and test sentences are Claims 7 and 8.
**Legibility-target:** for-orchestrator-synthesis

`scripts/d6.sh:36`: `g() { ( source "$D6_OPT/scripts/lib/dev-cycle-read.sh" && git_harden && git "$@" ); }`. `scripts/d6.sh:53`: `... [[ "$have" == main || "$have" == master ]] || no "the default branch is not exactly one of main and master"`. `skills/dev-cycle/SKILL.md:39`: `` `cd WT && bash /opt/claude-workflows/scripts/d6.sh SCRIPT ARG...` ``. Constraints S1, S3 and S4 exist (`docs/constraints.md:15,17,18`). E1 cases 6 and 7 passed: the kept refusals fire and the dropped shapes pass.

**Evidence:** `scripts/d6.sh:33-54`, `skills/dev-cycle/SKILL.md:36-41`, `docs/constraints.md:15-18`, FC1/bats-d6.log

---

## Claim 7: "F38's row now rests on `git_harden`'s pins for replace refs; grafts are an accepted hostile-only residual"

**Location:** `docs/working/plan-build-loop-handoff.md:88`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the plan's own rows; does not establish a convention that amendments must rewrite old rows, and earlier amendments here do leave superseded bullets standing.
**Legibility-target:** for-author

The mechanism is right (Claim 14), but the row still says the opposite. `docs/working/plan-build-loop-handoff.md:166`: `The snippet refuses replace refs and grafts and refuses a default branch that is not one plain main or master (T36; ...` (excerpt ends inside the table row, which closes on the same line — read). Line 411, T36: `... `info/grafts` present → the snippet refuses before running anything`. Line 412, T37: `a uid-owned stub dir or a missing file → refuse`. Line 82: `It runs only after ... `info/grafts` is absent (F38).`

Precise version: mark rows F38, T36 and T37 as amended, or point them at line 88.

**Evidence:** `docs/working/plan-build-loop-handoff.md:82`, `docs/working/plan-build-loop-handoff.md:88`, `docs/working/plan-build-loop-handoff.md:166`, `docs/working/plan-build-loop-handoff.md:411-412`

---

## Claim 8: "T33, T36 and T37 test the file; T37's uid-owned case and T36's replace and graft cases went, and a new case pins that d6.sh now passes them."

**Location:** `docs/working/plan-build-loop-handoff.md:88`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the bats file at HEAD; does not establish that the plan's T-table rows were updated (Claim 7).
**Legibility-target:** for-orchestrator-synthesis

`d6_copy` now reads `cp "$REPO_ROOT/scripts/d6.sh" "$D6"` and every T33, T36 and T37 case uses it or greps the file. The new case is titled `d6.sh runs the script past what audit rows R6c to R6e dropped: a replace ref, info/grafts, a symbolic or tag default branch, a uid-owned image` (`test/scripts/build-loop-orchestrator.bats:346`). Provenance E1: all pass.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:249-256`, `test/scripts/build-loop-orchestrator.bats:331-360`, FC1/bats-d6.log

---

## Claim 9: "extracted from one commit, a missing item fatal (FP-158)... directories 0555, files 0444, and `*.sh`/`*.py` 0555"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:13`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers install.sh's staging and the Dockerfile's modes; does not establish a built image.
**Legibility-target:** for-orchestrator-synthesis

`devcontainer-config/install.sh:279-285` collects misses and exits: `echo "ERROR: payload source(s) not found in commit ...` then `exit 1`. `devcontainer-config/Dockerfile:526-528` sets the three modes. FP-158 is `symptom:missing-payload-source-warns-and-continues-silent-and-total` (`docs/failure-patterns.md:300`). The live image agrees: `/opt/claude-workflows/scripts/hermeticity-lint` is `-r--r--r--` and each `.sh` is `-r-xr-xr-x` (paraphrased — no quote available because this is `ls -la` output of the image, not a repo file).

**Evidence:** `devcontainer-config/install.sh:268-285`, `devcontainer-config/Dockerfile:525-528`, `docs/failure-patterns.md:300`

---

## Claim 10: "a session's skill is that image's copy"; "No project-level skill copy shadows it in this repo"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:14`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers this container and this repository; does not establish that no other repository carries a project-level `dev-cycle` skill that would shadow the image's.
**Legibility-target:** for-orchestrator-synthesis

`readlink /home/node/.claude/skills` prints `/opt/claude-workflows/skills`, and the `scripts` link prints `/opt/claude-workflows/scripts`. `/workspace/.claude/skills` does not exist and `git ls-files .claude` lists nothing (paraphrased — no quote available because these are filesystem states, not file contents). The plan quote is exact: `The snippet is inline in the installed SKILL.md, which is the root-owned image copy.` (`docs/working/plan-build-loop-handoff.md:81`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:81`, `docs/working/research-2026-11-05-d6-block-into-image.md:78`

---

## Claim 11: "`--state` through d6 must see no exported config pair: `caller_gate` refuses one (row 702)"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:22`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `caller_gate` at HEAD with `GIT_CONFIG_COUNT` pairs and `GIT_CONFIG_PARAMETERS`; does not establish whether a pair reaching the script would be harmless in every mode.
**Legibility-target:** for-author

Same defect as Claim 28b, in a list headed Invariants and marked `[observed]`. The cited test passes whether or not the claim holds, so it observes nothing about `caller_gate`. Provenance E2, section D: `--state` with an exported pair prints `ok`, exit 0.

**Evidence:** `scripts/build-loop.sh:751-757`, `docs/working/research-2026-11-05-d6-block-into-image.md:22`, FC1/probe1.log

---

## Claim 12: "with a graft `rev-list --count` gave 2 with and without those pins; with `git replace --graft` it gave 2 plain and 3 hardened"; "git has deprecated the file and prints a hint on reading one"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:37`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 with the lib's `git_harden`; does not establish other git versions.
**Legibility-target:** for-orchestrator-synthesis

Provenance E2, section F reproduced all four numbers: `graft plain: 2`, `graft hardened: 2`, `replace plain: 2`, `replace hardened: 3`. Stderr held `hint: Support for <GIT_DIR>/info/grafts is deprecated`. The second quoted sentence is at line 64.

**Evidence:** `docs/working/research-2026-11-05-d6-block-into-image.md:37`, `docs/working/research-2026-11-05-d6-block-into-image.md:64`, FC1/probe1.log

---

## Claim 13: "The move and the narrowing are separate commits: reverting the second restores A exactly"; "[2] Keep every check | revert the narrowing commit; the move stands | one line in the review"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:59`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the revert at HEAD; same residue as Claim 3.
**Legibility-target:** for-author

This is the owner-facing form of Claim 3, repeated at line 118 as option [2]. Commit 9f80368a landed after this doc and made the single revert conflict. The cost column `one line in the review` holds only with `git revert 9f80368a 2b0838bb` (Provenance E4), and that also leaves the plan amendment and this doc describing the narrowing (paraphrased — no quote available because this is a `git diff --stat da07a77c -- docs` result naming both files).

Fix: name the two-commit revert in option [2], or fold 9f80368a into 2b0838bb.

**Evidence:** `docs/working/research-2026-11-05-d6-block-into-image.md:59`, `docs/working/research-2026-11-05-d6-block-into-image.md:118`, FC1/probe3.log

---

## Claim 14: "The gate's git ignores it (the probe above); `git_harden` sets both pins. The refusal stopped a repo for a ref nothing reads."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:63`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers build-loop.sh and dev-cycle.sh under `git_harden`, and questions.sh's two git calls; does not establish that questions.sh is hardened, because it is not.
**Legibility-target:** for-orchestrator-synthesis

`scripts/lib/dev-cycle-read.sh:330` holds `core.useReplaceRefs=false` and `git_harden` exports `GIT_NO_REPLACE_OBJECTS=1`. build-loop.sh calls it at line 704 with no git call before it, and dev-cycle.sh at line 128; E1 case 15 pins dev-cycle.sh's.

Residue on the third script: questions.sh neither sources the lib nor calls `git_harden`. Its only git calls are `git -C "$PWD" rev-parse --is-inside-git-dir` (`scripts/questions.sh:84`) and `git -C "$PWD" rev-parse --show-toplevel` (`:88`). Provenance E2 section G's shim shows d6's two `show-ref` calls with `COUNT=7 NOREPLACE=1` and then these two rev-parse calls. They read no object, so "nothing reads" the ref there, but "all three scripts are hardened" would be false.

**Evidence:** `scripts/lib/dev-cycle-read.sh:330-341`, `scripts/build-loop.sh:704`, `scripts/dev-cycle.sh:128`, `scripts/questions.sh:84-88`, FC1/probe1.log

---

## Claim 15: "`--state` dropped it (unit 1, G6) and that research accepts the residual"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:64`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row number; the drop itself is Claim 4.
**Legibility-target:** for-author

Grafts are row G5, not G6. `docs/working/research-2026-11-01-relax-gate-git-state.md:31`: `| G5 | info/attributes, grafts, shallow, alternates | ...`. Line 32: `| G6 | refs/replace | ...`. The residual is accepted at line 95 of that doc. Precise version: `(unit 1, G5)`.

**Evidence:** `docs/working/research-2026-11-01-relax-gate-git-state.md:31-32`, `docs/working/research-2026-11-01-relax-gate-git-state.md:95`

---

## Claim 16: "`default_gate` refuses both in `--state` [observed: `scripts/build-loop.sh`; a new test pins it through d6], and `--state` opens every iteration."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--state` and step 0.1's order; does not establish refusal in the read modes or dev-cycle.sh, which now run on both shapes (Claim 30).
**Legibility-target:** for-orchestrator-synthesis

The doc understates this: every gated mode refuses, not only `--state` (Claim 29). `skills/dev-cycle/SKILL.md:210`: `1. **`--state`**, run through d6 from the main worktree ... before any other git` (excerpt ends :211; step 1 continues to :217 — read).

**Evidence:** `scripts/build-loop.sh:764-789`, `skills/dev-cycle/SKILL.md:210-217`, `test/scripts/build-loop-orchestrator.bats:346-360`, FC1/probe1.log

---

## Claim 17: "old (a pasted block...) | new | Works: the block's four files stay in the image, root-owned. No flag day."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:84`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the real block on today's root-owned image and on a stand-in holding HEAD's scripts; the new-image run relaxed `own()` to presence, so the ownership walk on a real new image is inferred from the Dockerfile's unchanged chown, not observed.
**Legibility-target:** for-orchestrator-synthesis

Provenance E3. The block extracted from 5b20d4bd, run as `bash -s -- build-loop.sh --state` against the real `/opt`, printed `ok` (J1). Against the stand-in with d6.sh present, `--state`, `--settings` and `dev-cycle.sh --check-path a` each exited 0 (J2).

**Evidence:** `devcontainer-config/Dockerfile:525-528`, FC1/probe2.log

---

## Claim 18: "new (read from a checkout, not the image) | old | `bash` prints `.../d6.sh: No such file or directory`, exit 127, empty stdout, nothing ran."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:85`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2 called directly and from zsh; does not establish a d6.sh that is present but not a file, which is a different bash failure.
**Legibility-target:** for-orchestrator-synthesis

Provenance E2, section A3: both runs print `bash: .../nope/d6.sh: No such file or directory`, exit 127. E1 case 3 uses the skill's own line and confirms nothing ran.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:290-303`, FC1/probe1.log

---

## Claim 19a: "BASH_ENV applies to `bash d6.sh` as it did to `bash -s`"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:101`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the outer bash; the inner script's scrub is Claim 19b.
**Legibility-target:** for-orchestrator-synthesis

Provenance E2, section H: both forms printed `BASH_ENV-ran` first.

**Evidence:** FC1/probe1.log, `scripts/d6.sh:54`

---

## Claim 19b: "The scrub is pinned by a new test."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:101`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the new test asserts and what d6.sh does; does not establish a mutation run of the test.
**Legibility-target:** for-author

d6.sh unsets all six: Provenance E2 section I gives `benv=unset a=unset w=unset l=unset`. The test pins only three. `test/scripts/build-loop-orchestrator.bats:307`: `echo "live=${QUESTIONS_LIVE-unset} scrub=${DEV_CYCLE_SCRUBBED-unset} env=${ENV-unset} in=$(cat)"`. It sets `QUESTIONS_ARCHIVE` and `QUESTIONS_WATCHING` but never prints them, and never sets `BASH_ENV`, so deleting any of those three `-u` flags would still pass. Precise version: three of six are pinned, or add the three to the probe line.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:305-310`, `scripts/d6.sh:54`, FC1/probe1.log

---

## Claim 20: "After the merge and before the release, the image's floor does not list `scripts/d6.sh`... the `image-lag` entry this merge opens lists every changed path."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:102`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the image's GATE_CODE and the skill's entry text; no self-merge was run against the old image.
**Legibility-target:** for-orchestrator-synthesis

`/opt/claude-workflows/scripts/lib/dev-cycle-read.sh:2017`: `GATE_CODE='^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'`. `skills/dev-cycle/SKILL.md:236-237`: `the flag is a pointer, not proof), every path changed from C to M outside `docs/` on one line`.

**Evidence:** `skills/dev-cycle/SKILL.md:228-240`

---

## Claim 21: "The 127 path has empty stdout... The Rules state it, step 1b's 'if either fails, go on' names it as still a stop, and a test pins those phrases."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:103`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four pinned phrases; does not establish how an orchestrator session acts on them.
**Legibility-target:** for-orchestrator-synthesis

`skills/dev-cycle/SKILL.md:357-358`: `(a `refuse d6:` line, its exit 127 or a timed-out call is still a stop, as the Rules say)`. E1 case 3 checks all four phrases.

**Evidence:** `skills/dev-cycle/SKILL.md:356-358`, `test/scripts/build-loop-orchestrator.bats:298-302`, FC1/bats-d6.log

---

## Claim 22a: "A lib that fails to source reads as 'absent' for both names"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:104`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers eight broken-lib shapes on bash 5.2 and git 2.39.5; the refusal itself is Claim 22b.
**Legibility-target:** for-author

The outcome depends on `g`'s status, read at `scripts/d6.sh:49-50`:

```bash
# scripts/d6.sh:49-51
  rc=0; g show-ref --verify -q "refs/heads/$n" || rc=$?
  [[ "$rc" -le 1 ]] || no "refs/heads/$n could not be read"
  [[ "$rc" -ne 0 ]] || have+="$n "
```

(excerpt ends :51; the enclosing loop closes at :52 — read)

Provenance E2, section B:

| Broken lib | Refusal printed |
|---|---|
| syntax error, first or last line | `refs/heads/main could not be read` |
| empty, so no `git_harden` | `refs/heads/main could not be read` |
| exits 3 | `refs/heads/main could not be read` |
| unset variable under `set -u` | `the default branch is not exactly one of main and master` |
| unreadable | `the default branch is not exactly one of main and master` |
| last command fails | `the default branch is not exactly one of main and master` |
| `GIT_CONFIG_COUNT=010`, so `git_harden` exits 1 | `the default branch is not exactly one of main and master` |

So status 1 reads as absent and anything above 1 reads as a failed read. A syntax error, the plainest failure to source, takes the second path. In the "absent" cases the refusal names the wrong cause; the real one is only on stderr, and the `refuse d6:` line is what the skill quotes.

Precise version: "a lib that fails to source refuses, as a failed read or, when the subshell exits 1, as absent for both names".

**Evidence:** `scripts/d6.sh:36`, `scripts/d6.sh:48-53`, FC1/probe1.log

---

## Claim 22b: "which is still a refusal"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:104`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the eight shapes in Claim 22a; does not establish a lib that sources cleanly but defines a `git_harden` that does nothing, which would run git unhardened.
**Legibility-target:** for-orchestrator-synthesis

All eight exit 2 with a `refuse d6:` line and run no script (Provenance E2, section B). The `&&` chain in `g` means git runs only after both steps succeed, so no failure yields status 0: `scripts/d6.sh:36`: `g() { ( source "$D6_OPT/scripts/lib/dev-cycle-read.sh" && git_harden && git "$@" ); }`. Under `set -u` an unbound variable ends only the subshell, and the loop's `|| rc=$?` catches it.

**Evidence:** `scripts/d6.sh:32-36`, FC1/probe1.log

---

## Claim 23: "A test proves no pair reaches the script and every git call carries the pins."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:104`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers d6.sh's two git calls and `GIT_CONFIG_COUNT` in the child; the test does not check every HARDEN pair (it names three pairs and three environment values).
**Legibility-target:** for-orchestrator-synthesis

`test/scripts/build-loop-orchestrator.bats:362-370` asserts `count=unset` in the child and exactly two logged calls carrying `core.hooksPath=/dev/null core.fsmonitor=false core.useReplaceRefs=false`. E1 case 8 passes.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:362-370`, FC1/bats-d6.log

---

## Claim 24: "A planted `info/grafts` now reaches `--main-log`... `--state` already accepted it in unit 1."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:105`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one graft file through d6 to both modes; hostile use is out of scope under S1.
**Legibility-target:** for-orchestrator-synthesis

Provenance E2, section G: with `.git/info/grafts` present, `--state` printed `ok` and `--main-log` answered `main <sha> 0`.

**Evidence:** `scripts/build-loop.sh:722-736`, FC1/probe1.log

---

## Claim 25: "It always runs the root-owned image copy under D6_OPT by absolute path... D6_OPT is a literal, never read from the environment or from this file's own path"

**Location:** `scripts/d6.sh:6-12`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the literal, `D6_OPT` in the environment and a copy elsewhere running the configured root; "root-owned" rests on the Dockerfile, as d6.sh no longer checks owner, and the same-uid residual stands as the header says.
**Legibility-target:** for-orchestrator-synthesis

`scripts/d6.sh:33`: `D6_OPT=/opt/claude-workflows`. Provenance E2, section A4: `D6_OPT=/nonexistent` in the environment changes nothing, `ok`. E1 cases 1 and 5 pin the literal and "never main's or the working tree's".

**Evidence:** `scripts/d6.sh:33`, `scripts/d6.sh:54`, `test/scripts/build-loop-orchestrator.bats:272-281`, FC1/probe1.log

---

## Claim 26a: "Exit: the script's own status; 2 and one 'refuse d6: WHY' line on stdout, with nothing run, for an image-copy file that is missing..., a default branch that is not exactly one of main and master, or a git read that fails...; 1 for another first argument."

**Location:** `scripts/d6.sh:19-23`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed exit, a missing argument and a non-repository; stderr can also carry bash's or the lib's lines when the lib is broken, not only git's, and the regular-file clause is Claim 26b.
**Legibility-target:** for-orchestrator-synthesis

`scripts/d6.sh:34`: `no() { echo "refuse d6: $*"; exit 2; }`. `:54` is an `exec`, so the status is the child's; the probe's child exit 7 came through (Provenance E2, section I). E1 case 6 covers both and neither default branch, the non-repository, missing files and the bad argument; E2 A2 covers no argument, exit 1.

**Evidence:** `scripts/d6.sh:34-54`, `test/scripts/build-loop-orchestrator.bats:331-344`, FC1/probe1.log

---

## Claim 26b: "an image-copy file that is... not a regular file"

**Location:** `scripts/d6.sh:21`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a symlink to a regular file and a dangling link; does not establish that an image can hold such a link, and install.sh's extraction refuses committed links.
**Legibility-target:** for-author

`scripts/d6.sh:45`: `[[ -f "$x" ]] || no "$x is not a regular file"`. `-f` follows symlinks, so a link to a regular file passes: Provenance E2 section C ran questions.sh through one, with no `refuse d6:` line. A dangling link refuses (E1 case 6). The block's `own()` refused any link (`[[ ! -L "$1" ...`), and neither the commit nor research row R6e lists that refusal as dropped; both name only "the ownership walk".

Precise version: "or does not resolve to a regular file", and name the plain-path check among what R6e dropped.

**Evidence:** `scripts/d6.sh:44-45`, `docs/working/research-2026-11-05-d6-block-into-image.md:67-68`, `devcontainer-config/install.sh:299`, FC1/probe1.log

---

## Claim 27: "An image with no d6.sh at all prints nothing of this: bash exits 127 naming the path, which the skill's Rules read as this refusal."

**Location:** `scripts/d6.sh:23-24`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit and the Rules' wording, as Claims 18 and 34.
**Legibility-target:** for-orchestrator-synthesis

See Claim 18 for the run. `skills/dev-cycle/SKILL.md:46-48`: `So does exit 127 with `bash`'s `No such file or directory` line naming d6.sh: that is the same refusal from an image older than this skill`.

**Evidence:** `skills/dev-cycle/SKILL.md:46-48`, FC1/probe1.log

---

## Claim 28a: "Its git is the image lib's git_harden, in a subshell, so no pair reaches the script"

**Location:** `scripts/d6.sh:25-26`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers pairs d6.sh's own `git_harden` exports; a pair the caller exported does reach the script.
**Legibility-target:** for-orchestrator-synthesis

`g` is a `( ... )` subshell (`scripts/d6.sh:36`), and E1 case 8 asserts `count=unset` in the child.

**Evidence:** `scripts/d6.sh:36`, `test/scripts/build-loop-orchestrator.bats:362-370`

---

## Claim 28b: "whose caller_gate would refuse one (row 702)"

**Location:** `scripts/d6.sh:26`
**Type:** Behavioral / Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `caller_gate` at HEAD against exported `GIT_CONFIG_COUNT` pairs and `GIT_CONFIG_PARAMETERS`, directly and through d6; row 702 itself resolves, as `--state is called with no git_harden pair exported`.
**Legibility-target:** for-author

`caller_gate` checks only the stray-variable list:

```bash
# scripts/build-loop.sh:751-757
caller_gate() {
  local v bad=0
  for v in $(stray_vars); do
    echo "refuse state $v: set in the caller's environment, so git can read another repository, work tree, index or object store"; bad=1
  done
  return "$bad"
}
```

`stray_vars` names `GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR` (`scripts/build-loop.sh:746`). Provenance E2, section D: an exported HARDEN key with `GIT_CONFIG_COUNT=1` printed `ok`, exit 0, directly and through d6, and so did `GIT_CONFIG_PARAMETERS`; `GIT_DIR` refused. The config-pair scan went in brief 2026-11-01-relax-gate-git-state (`docs/working/research-2026-11-01-relax-gate-git-state.md:4` lists `caller_gate`'s config-pair scan among what it narrows).

This branch wrote the sentence after that change, and the same branch's skill says the opposite: `skills/dev-cycle/SKILL.md:78-79`: `an exported `GIT_CONFIG_PARAMETERS` would outrank the gate's own `HARDEN` pairs, and `--state` no longer refuses it; row 702`.

Fix: drop the clause, and the same words at Claim 11's location.

**Evidence:** `scripts/build-loop.sh:746-757`, `skills/dev-cycle/SKILL.md:78-79`, `docs/reviews/api-consistency-review-2026-10-12-u3b3-final.md:80`, FC1/probe1.log

---

## Claim 29: "build-loop.sh's own state and default-branch gates in its gated modes, which also refuse a symbolic or non-commit default branch"

**Location:** `scripts/d6.sh:26-28`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all eight gated modes on a symbolic main and a main naming a tag object; `--check-constraints` matches the GATED regex but exits at its own block before any gate and reads no git object.
**Legibility-target:** for-orchestrator-synthesis

`default_gate` runs in all gated modes, not only `--state`. `scripts/build-loop.sh:1292-1293`: `state_start() {` then `default_gate || exit 2`. `state_start` is called by `state`, `main-log`, `cycle-diff` and `land-cycle`, and through `gate_start` by `check`, `merge` and `start|prompt` (`scripts/build-loop.sh:2320-2371`). `land` also runs it again before writing.

Provenance E2, sections E1 and E2: `--state`, `--main-log`, `--cycle-diff`, `--land-cycle`, `--check`, `--merge`, `--start` and `--prompt` each exit 2 with `refuse state default-branch: refs/heads/main is a symbolic ref`, and with `names an object that is not a commit` for the tag.

**Evidence:** `scripts/build-loop.sh:764-789`, `scripts/build-loop.sh:1292-1300`, `scripts/build-loop.sh:1629`, `scripts/build-loop.sh:2320-2371`, FC1/probe1.log

---

## Claim 30: "(dev-cycle.sh, questions.sh and the read modes have none; row 548 for dev-cycle.sh)"

**Location:** `scripts/d6.sh:29-30`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both shapes through d6 in those modes and row 548's text; does not establish what those modes read on such a ref, since `--state` is the only stop before them in a cycle.
**Legibility-target:** for-orchestrator-synthesis

`scripts/build-loop.sh:798`: `GATED=""; [[ "$MODE" =~ ^(settings|status|marker)$ ]] || GATED=1`. Provenance E2: `--settings`, `--status`, `--marker` and `dev-cycle.sh` exit 0 on both shapes, and questions.sh reaches its own missing-file error. Row 548: `dev-cycle.sh runs no state_gate/default_gate` (`docs/reviews/api-consistency-review-2026-10-12-u3b3-final.md:81`).

**Evidence:** `scripts/build-loop.sh:798`, `docs/reviews/api-consistency-review-2026-10-12-u3b3-final.md:81`, FC1/probe1.log

---

## Claim 31: "The four files the scripts run (build-loop.sh and dev-cycle.sh source the lib from their own directory; dev-cycle.sh runs questions.sh beside it)."

**Location:** `scripts/d6.sh:40-41`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the three scripts source or run; wording moved from the block unchanged, and neither script needs the fifth file outside its migration path.
**Legibility-target:** for-author

A fifth file also runs: `scripts/build-loop.sh:2071`: `source "$SCRIPT_DIR/lib/migrations.sh"`, and `scripts/dev-cycle.sh:584`: `source "$MIG_LIB"`. d6.sh does not presence-check it, though each script reports a missing one itself. Precise version: "the four files every run needs".

**Evidence:** `scripts/build-loop.sh:2067-2071`, `scripts/dev-cycle.sh:580-584`, `scripts/d6.sh:42`

---

## Claim 32: "used by scripts/dev-cycle.sh and kept apart so scripts/build-loop.sh can share it"; "The caller sets -euo pipefail"; "build-loop.sh and dev-cycle.sh call it once, after scrub_reexec"

**Location:** `scripts/lib/dev-cycle-read.sh:2-13`
**Type:** Staleness / Architectural
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the lib's header and `git_harden`'s comment against the new third caller; does not establish a failure, since d6.sh calls only `git_harden`, which needs neither `-e` nor the scrub.
**Legibility-target:** for-author

This branch made d6.sh a third caller and left the lib's caller contract as it was. `scripts/d6.sh:32`: `set -u -o pipefail`, with no `-e`. `scripts/d6.sh:36` sources it from `$D6_OPT`, not from "its own directory" as line 10 says, which differs for any non-image copy. `git_harden` runs there once per `g` call, in a subshell, with no `scrub_reexec` (a grep of d6.sh for it finds nothing; `scripts/lib/dev-cycle-read.sh:307-309`).

Fix: one line naming d6.sh's narrower use, that it calls only `git_harden`, in a subshell.

**Evidence:** `scripts/lib/dev-cycle-read.sh:2-13`, `scripts/lib/dev-cycle-read.sh:305-309`, `scripts/d6.sh:32-36`

---

## Claim 33: GATE_CODE restatements agree: "d6.sh joins GATE_CODE"; "build-loop.sh's header repeats it"; "a test holds this copy to it"

**Location:** `scripts/lib/dev-cycle-read.sh:1032`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every restatement a grep of scripts, skills, test, guides, the plan and constraints finds; the build-loop.sh header and the plan are prose no test pins.
**Legibility-target:** for-orchestrator-synthesis

The same regex is at `scripts/lib/dev-cycle-read.sh:1032` and `skills/dev-cycle/SKILL.md:617`: `^scripts/(build-loop|d6|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/`. The PATHS line, `skills/dev-cycle/SKILL.md:229`, lists `scripts/build-loop.sh scripts/d6.sh scripts/dev-cycle.sh scripts/questions.sh scripts/lib/ skills/dev-cycle/`. `scripts/build-loop.sh:454` says `scripts/build-loop.sh, d6.sh, dev-cycle.sh, questions.sh, anything`. `docs/working/plan-build-loop-handoff.md:73` adds `since brief `2026-11-05-d6-block-into-image` `scripts/d6.sh``. E1 cases 13 and 14 and `test/scripts/build-loop-check.bats:262` pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1032`, `skills/dev-cycle/SKILL.md:229`, `skills/dev-cycle/SKILL.md:617`, `scripts/build-loop.sh:453-455`, `docs/working/plan-build-loop-handoff.md:73`, `test/scripts/build-loop-check.bats:262`, FC1/bats-d6.log, FC1/bats-check.log

---

## Claim 34: "So does exit 127... a `refuse d6:` line or that exit 127, are stops too"; no site treating `refuse d6:` lacks the 127 case

**Location:** `skills/dev-cycle/SKILL.md:46-53`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `refuse d6` mention in scripts, skills, guides, workflows, hooks, patterns, `docs/dev-cycle.md` and `docs/constraints.md`; the plan's history bullets keep the old text by design.
**Legibility-target:** for-orchestrator-synthesis

The skill has four such sites, lines 46, 53, 216 and 357, and each names 127 (paraphrased — no quote available because the claim covers absence across a grep; the four are quoted in the test at `test/scripts/build-loop-orchestrator.bats:299-300`). Outside the skill, only d6.sh and the bats file mention the line. An exit 127 also falls under `any other exit (1 included)` at line 50, and `--check-path` opens a path only on `ok <path>`, so a 127 there opens nothing.

**Evidence:** `skills/dev-cycle/SKILL.md:46-53`, `skills/dev-cycle/SKILL.md:133`, `skills/dev-cycle/SKILL.md:216-217`, `skills/dev-cycle/SKILL.md:357-358`, FC1/bats-d6.log

---

## Claim 35: the block and its "byte for byte" rule are gone: no leftover "D6 block", `bash -s` or snippet reference

**Location:** `skills/dev-cycle/SKILL.md:36-39`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers scripts, skills, guides, test, workflows, hooks, patterns, global-instructions and devcontainer-config; bare "D6" naming the plan decision is correct and stays, and the plan's own history is outside this claim.
**Legibility-target:** for-orchestrator-synthesis

The only hits are the test's negative pin `! grep -nE "bash -s -- |<<'D6'|^D6$|byte for byte|D6 block|D6_OPT" "$K"` and `[ ! -e "$REPO_ROOT/test/lib/d6-snippet.bash" ]` (`test/scripts/build-loop-orchestrator.bats:275`, `:280`). Other "byte for byte", "snippet" and `-s bash` hits concern unrelated things (paraphrased — no quote available because the claim covers absence of a reference across a grep). Bare "D6" remains at `scripts/lib/dev-cycle-read.sh:309`, `scripts/build-loop.sh:219,2054` and `scripts/dev-cycle.sh:126`, each meaning the decision.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:275`, `test/scripts/build-loop-orchestrator.bats:280`

---

## Claim 36: test comments on d6_copy, d6_setup, d6_is and "d6.sh repeats neither list"

**Location:** `test/scripts/build-loop-orchestrator.bats:247-263`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the comments at lines 247-251, 263 and 411; `d6_is` also tolerates stderr on "could not be read" refusals, as its body shows.
**Legibility-target:** for-orchestrator-synthesis

`d6_copy` copies the shipped file and changes one literal, with a `grep -qxF` proving the change took. d6.sh has no owner check. Line 411's claim is enforced on the next line by `! grep -nE '^[^#]*(GIT_NO_REPLACE_OBJECTS|core\.hooksPath)' "$REPO_ROOT/scripts/d6.sh"`. E1 passes.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:247-263`, `test/scripts/build-loop-orchestrator.bats:411-412`, FC1/bats-d6.log

---

## Claim 37: "d6.sh exports no config pair, so --state run through it passes caller_gate (row 702)."

**Location:** `test/scripts/build-loop-orchestrator.bats:324`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the causal "so"; the assertion on the next line still passes and still checks that `--state` through d6 prints `ok`.
**Legibility-target:** for-author

Same root as Claim 28b. `--state` passes `caller_gate` with or without pairs (Provenance E2, section D), so line 325 pins no property of the pair. The other test, at line 362, does pin it. Fix: reword to "--state runs through d6.sh", or drop the `row 702` cause.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:324-325`, `scripts/build-loop.sh:751-757`, FC1/probe1.log

---

## Claim 38: "A replace ref: the image's script runs and its hardened git does not follow it."

**Location:** `test/scripts/build-loop-orchestrator.bats:348`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the case asserts and what hardened git does; both halves of the comment are true of the code, but only the first is tested.
**Legibility-target:** for-author

The behaviour holds (Claim 12: `replace hardened: 3`). The case only asserts `d6 build-loop.sh --settings; [ "$status" -eq 0 ]`, and `--settings` reads `docs/dev-cycle.md`, not the replaced `scripts/build-loop.sh` blob, so it would pass if the pins were gone. The commit-level replace case left with T36. Precise version: "the image's script runs past it", or replace an object `--settings` reads and assert the original bytes.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:348-351`, FC1/probe1.log

---

## Claims Requiring Attention

### Incorrect
- **Claim 11** (`docs/working/research-2026-11-05-d6-block-into-image.md:22`): `caller_gate` no longer refuses a config pair; the listed invariant and its `[observed]` tag are wrong.
- **Claim 22a** (`docs/working/research-2026-11-05-d6-block-into-image.md:104`): a lib that fails to source reads as "absent" only at status 1; a syntax error reads as "could not be read". Refusal holds either way (22b).
- **Claim 28b** (`scripts/d6.sh:26`): "whose caller_gate would refuse one" is false, by run and by `skills/dev-cycle/SKILL.md:78-79`. Drop the clause.

### Stale
- **Claim 3** (commit 2b0838bb): `git revert 2b0838bb` conflicts at HEAD because of 9f80368a; `git revert 9f80368a 2b0838bb` works. The commit's own claim held at 5600a101.
- **Claim 13** (`docs/working/research-2026-11-05-d6-block-into-image.md:59`, `:118`): the owner's option [2] carries the same out-of-date revert. This is the one finding that touches a decision the owner is asked to make.
- **Claim 32** (`scripts/lib/dev-cycle-read.sh:2-13`, `:307-309`): the lib's caller contract omits its new caller d6.sh, which sets no `-e` and sources from `D6_OPT`.
- **Claim 37** (`test/scripts/build-loop-orchestrator.bats:324`): the comment's "so ... passes caller_gate" no longer has a cause.

### Mostly Accurate
- **Claim 7** (`docs/working/plan-build-loop-handoff.md:88`): rows F38, T36 and T37 still describe the removed refusals.
- **Claim 15** (`docs/working/research-2026-11-05-d6-block-into-image.md:64`): grafts are G5, not G6.
- **Claim 19b** (`docs/working/research-2026-11-05-d6-block-into-image.md:101`): the test pins three of the six scrubbed variables; `BASH_ENV`, `QUESTIONS_ARCHIVE` and `QUESTIONS_WATCHING` are unpinned.
- **Claim 26b** (`scripts/d6.sh:21`): a symlink to a regular file passes `-f`; the block's no-symlink refusal went unlisted.
- **Claim 31** (`scripts/d6.sh:40-41`): `lib/migrations.sh` is a fifth file the scripts source.
- **Claim 38** (`test/scripts/build-loop-orchestrator.bats:348`): the case does not exercise "does not follow it".

### Unverifiable
- None.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to docs/reviews/code-fact-check-report-2026-11-05-d6-block-into-image.md in that worktree, per skills/code-fact-check/SKILL.md (read that file and follow it), first line `Commit: <HEAD short sha>`, header carrying `**Replication:** k=1 (loop pass, decision 031)`, ending with a Goal-Alignment Note (patterns/orchestrated-review.md canonical form). Tag every claim with Legibility-target. Do not commit.
- Answered: yes; all eight listed areas checked against the code, with runs for every executable guarantee except the full health check.
- Out of scope: the whole test suite and `scripts/health-check.sh` (dispatch forbids them); image builds; hostile-author readings (S1).
- Escalate: HEAD moved to 9f80368a during this pass, which made the revert claim stale; the owner's option [2] needs the two-commit revert or a squash before the owner answers it.
- Decisions I made: Stamped 9f80368a, the live HEAD, rather than 5600a101, where the pass began; every run saw 9f80368a. Kept logs in the scratch dir and did not update hallucination-patterns.md, because the dispatch allows editing only this report, and no finding is a fabrication anyway. Rated Claim 22a Incorrect, not Mostly accurate, since a syntax error refutes the stated mechanism even though the refusal holds.
