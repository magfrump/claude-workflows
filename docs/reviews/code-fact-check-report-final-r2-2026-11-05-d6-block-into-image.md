Commit: 1c5fd04f

# Code Fact-Check Report

**Repository:** claude-workflows, worktree `.claude/wt-2026-11-05-d6-block-into-image`, branch `refactor/d6-block-into-image`
**Scope:** `git diff 5b20d4bd..1c5fd04f -- . ':!docs/reviews'` (9 files), plus the code that exercises each claim the dispatch named
**Checked:** 2026-11-05
**Replication:** k=3, replicate r2 (final confirming pass, full branch)
**Total claims checked:** 61
**Summary:** 54 verified, 4 mostly accurate, 1 stale, 2 incorrect, 0 unverifiable

One root error, in two places, both in the research doc: a planted `info/grafts` does **not** reach `--main-log`, and everything does **not** read a graft consistently (Claims 15b, 26a). `--main-log` walks and classifies through `gate_git`, whose repository has no `info/`. With a graft that rewrites first-parent history, real hardened git follows it and `--main-log` ignores it. The same sentence is the "If it's wrong" cell of the owner's option [1], so the owner's stated cost is misplaced, though it errs toward overstating the risk. Pass 1's Verified on this sentence (its Claim 24) rested only on "`--main-log` answered", which cannot tell the two apart. This pass supersedes it.

No code is wrong: d6.sh's behaviour, its header's exit list, the Rules bullet, the four 127 sites and every d6 test title match what runs. All eight mutations of `scripts/d6.sh` were caught. The four Mostly accurate items and the one Stale item are wording, and all five are small.

No claim matches a pattern in `docs/reviews/hallucination-patterns.md`. Claim 26a is a wrong reach, not a fabricated symbol, method or option, so it does not qualify for that log, and the dispatch allowed no other edit in any case.

## Execution provenance

FC3 is `/tmp/claude-1000/-workspace/47403b7b-5fcb-4e13-8807-c539081df064/scratchpad/2026-11-05-d6-block-into-image/fc3-r2/`. Logs stay there because the dispatch allowed no edit but this report, so `docs/reviews/execution-logs/` was not used. Every row ran under `timeout` except E4's two direct calls that exit at once. Probes ran in fixture repositories under FC3 against a stand-in image: HEAD's scripts with the one `D6_OPT` literal changed. No probe process remains. git 2.39.5, bash 5.2.15, uid 1000.

| Id | Command | Cwd | Exit | Time (UTC) | Output |
|---|---|---|---|---|---|
| E1 | `timeout 280 bats -f 'd6\|GATE_CODE\|git_harden exports\|image-lag' test/scripts/build-loop-orchestrator.bats` (16 of 16 ok, none skipped) | worktree | 0 | start 2026-11-06T07:28:29Z | FC3/bats-orch.log |
| E2 | `timeout 200 bats -f 'floor' test/scripts/build-loop-check.bats` | worktree | 0 | start 2026-11-06T07:28:37Z | FC3/bats-check.log |
| E3 | `timeout 120 bash p1.sh FC3 WT` (exit codes of `show-ref` on broken refs; d6.sh on each). Exit 124: this probe's own last step read stdin and hung; every row used here printed before it | FC3 | 124 | ended 07:25:46Z | FC3/p1.out |
| E4 | `bash /opt/claude-workflows/scripts/d6.sh build-loop.sh --settings` under bash and zsh, the bare path under both, then the working-tree d6.sh against the real image | FC3/p2/r | 127 each; 0 for the last | 2026-11-06T07:33:36Z | FC3/p2.log |
| E5 | `timeout 60 bash p3.sh FC3 WT` (graft and replace counts, update-ref to a tag, BASH_ENV, symbolic default) | FC3 | 0 | ended 07:28:29Z | FC3/p3.out |
| E6 | `timeout 500 bash p4.sh FC3 WT` (plain revert of 2b0838bb; restore from da07a77c; 8 mutations of d6.sh) in a throwaway clone | FC3 | 0 | start 2026-11-06T07:29:33Z | FC3/p4.out, FC3/restoreA.log, FC3/mut-*.log |
| E7 | `timeout 90 bash p5.sh FC3 WT` (each gated mode on a symbolic and a tag default; the 127 test's sentinel) | FC3 | 0 | ended 07:29:57Z | FC3/p5.out |
| E8 | `timeout 60 bash p6.sh FC3 WT` (control: a graft that moves first-parent history, real hardened git against `--main-log`; the digest under a graft) | FC3 | 0 | start 2026-11-06T07:32:16Z | FC3/p6.out |
| E9 | `timeout 150 bash p7.sh FC3` (restore from da07a77c, one test phrase changed, `-f 'd6\|GATE_CODE\|git_harden\|image-lag'`): 15 of 15 | FC3 | 0 | start 2026-11-06T07:33:04Z | FC3/restoreA3.log |

E6's mutations, each failing the numbered tests of `bats -f 'd6\.sh'`: `-u ENV` dropped (4), `</dev/null` dropped (4), `g()` without harden (8), the tried-alone line deleted (6), the rc check removed (6), `! -L` dropped (6), harden in the main shell (6, 8), `D6_OPT` read from the environment (nine tests).

---

## Claim 1: Plan D6 amendment 2026-11-05: the snippet is now `scripts/d6.sh`; what it keeps and drops; "T33, T36 and T37 test the file; T37's uid-owned case and T36's replace and graft cases went, and a new case pins that d6.sh now passes them."

**Location:** `docs/working/plan-build-loop-handoff.md:88`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each kept and dropped check against `scripts/d6.sh` and the tests; does not establish that "one commit" holds for a release built by hand outside `install.sh`.

The kept checks are in the file: `[[ "$have" == main || "$have" == master ]]` (`scripts/d6.sh:59`), `[[ -f "$x" && ! -L "$x" ]]` (`scripts/d6.sh:48`) and the `env -u` line (`scripts/d6.sh:60`). No replace, grafts, symbolic-ref, `cat-file` or `stat` call remains (paraphrased — no quote available because the claim covers absence of code). The new case is `test/scripts/build-loop-orchestrator.bats:352`, passing in E1. T36's symbolic and tag cases also moved there, which the sentence does not name but does not deny.

**Evidence:** `scripts/d6.sh:45-60`, `test/scripts/build-loop-orchestrator.bats:332-366`, FC3/bats-orch.log

---

## Claim 2: F38 "`git_harden` ignores replace refs; d6.sh refuses a default branch that is not exactly one of main and master (T36 ...). Grafts are an accepted hostile-only residual"

**Location:** `docs/working/plan-build-loop-handoff.md:166`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pins against a `git replace --graft` probe and T36's refusals; does not establish what any read does with a graft file (Claims 15b, 26a).

`export ... GIT_NO_REPLACE_OBJECTS=1` and `core.useReplaceRefs=false` are in `scripts/lib/dev-cycle-read.sh:333-343`. E5: `git replace --graft` gave `rev-list --count` 2 plain and 3 pinned.

**Evidence:** `scripts/lib/dev-cycle-read.sh:333-343`, FC3/p3.out, FC3/bats-orch.log

---

## Claim 3: F39 "`/opt/...` by absolute path, in every repository ...; the image's own ownership, not a runtime check, since 2026-11-05 (D6) (T37)"

**Location:** `docs/working/plan-build-loop-handoff.md:167`
**Type:** Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers d6.sh's literal root and the absence of an ownership check; does not establish the built image's modes beyond the Dockerfile lines.

`D6_OPT=/opt/claude-workflows` (`scripts/d6.sh:34`), and no `stat` or owner test in the file (paraphrased — no quote available because the claim covers absence of code). `chown -R root:root /opt/claude-workflows` is `devcontainer-config/Dockerfile:525`.

**Evidence:** `scripts/d6.sh:34`, `devcontainer-config/Dockerfile:525-528`

---

## Claim 4: T27 row "the D6 snippet's copy refuses the same tip"; F26 "the hardened snippet"; traceability row "D6 snippet; T27, T33, T36, T37"

**Location:** `docs/working/plan-build-loop-handoff.md:406`
**Type:** Staleness
**Verdict:** Stale
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** static
**Scope:** Covers three live-table rows the amendment left unchanged, outside the diff; does not cover history bullets such as the U3b3 and U4c steps, which describe their time correctly.

The test title now reads `d6.sh's image copy refuses the same tip` (`test/scripts/build-loop-orchestrator.bats:379`), and T33, T36 and T37 were reworded but T27 was not. `docs/working/plan-build-loop-handoff.md:151` and `:431` keep the same word. The amendment at `:88` explains the rename, so a reader can recover it. Fix: "d6.sh" in the three rows, or leave them as the amendment covers them.

**Evidence:** `docs/working/plan-build-loop-handoff.md:151`, `docs/working/plan-build-loop-handoff.md:406`, `docs/working/plan-build-loop-handoff.md:431`, `test/scripts/build-loop-orchestrator.bats:379`

---

## Claim 5: T33 "d6.sh ...: runs the image copy's four files ...; main's and the working tree's copies have no effect; SKILL.md states the one-line call once"

**Location:** `docs/working/plan-build-loop-handoff.md:408`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tests at `:273` and `:313`; does not establish the same on a built image with a d6.sh, since the real `/opt` has none yet.

The test overwrites main's and the working tree's four files with `echo main copy; exit 9` and `echo working copy; exit 9` (`test/scripts/build-loop-orchestrator.bats:316-319`) and still gets the image's output. The call count is `grep -cxF ... -eq 1` (`:275`). Both pass in E1.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:273-282`, `test/scripts/build-loop-orchestrator.bats:313-330`, FC3/bats-orch.log

---

## Claim 6: T36 "not exactly one of main and master, a repository git cannot read, an image file missing or not a regular file, an image lib that does not load, another first argument → d6.sh refuses before running anything; a replace ref or `info/grafts` no longer refuses"

**Location:** `docs/working/plan-build-loop-handoff.md:411`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed case; the test's "repository git cannot read" is a non-repository, and the E3 probe adds `core.repositoryformatversion=99` and a bad `packed-refs`, both refused the same way.

E3: `refuse d6: refs/heads/main could not be read` for format version 99, with `fatal: Expected git repo version <= 1, found 99` on stderr.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:332-350`, FC3/p1.out, FC3/bats-orch.log

---

## Claim 7: T37 "... d6.sh runs the real `/opt` copy (skipped without one), not main's; a missing file → refuse (a uid-owned stub dir no longer refuses ...)"

**Location:** `docs/working/plan-build-loop-handoff.md:412`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both T37 tests, which ran here against the real image and were not skipped; the image's d6.sh branch at `:396` has not run, as the image has no d6.sh.

`skip "no root-owned image copy at $O here"` (`test/scripts/build-loop-orchestrator.bats:394`) did not fire in E1: `ok 10`, no skip marker.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:392-404`, FC3/bats-orch.log

---

## Claim 8: Design 1 table: `scripts/` is already a payload item and `.sh` is 0555; `bin/d6` needs a new item and is 0444; `/usr/local/bin` is a Dockerfile edit

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:48-51`
**Type:** Configuration
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the installer list and Dockerfile lines, and the `:284` test; does not establish a built image, which the brief puts out of scope.

`CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)` (`devcontainer-config/install.sh:146`); files 0444 then `-name '*.sh' -o -name '*.py'` 0555 (`devcontainer-config/Dockerfile:527-528`). The live image confirms the rule: `hermeticity-lint` has no suffix and is `-r--r--r--` under `/opt/claude-workflows/scripts`.

**Evidence:** `devcontainer-config/install.sh:146`, `devcontainer-config/Dockerfile:525-528`, `test/scripts/build-loop-orchestrator.bats:284-289`, FC3/bats-orch.log

---

## Claim 9: "One option dominates: it alone needs no enforcement-file change"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:53`
**Type:** Architectural
**Verdict:** Mostly accurate
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the four table rows against the enforcement list; does not question the pick, which stands because the fourth row fails on R6f.

The fourth row, `No wrapper`, has Image route `nothing new` (`:51`), so it also needs no enforcement-file change. It is pruned for losing the scrub, not on this axis. `enforcement=` at `hooks/live-verify-gate.sh:83` holds `Dockerfile` and `install.sh`, so rows 2 and 3 do need one. Precise version: "of the options that keep R6f's scrub, it alone needs no enforcement-file change".

**Evidence:** `docs/working/research-2026-11-05-d6-block-into-image.md:48-53`, `hooks/live-verify-gate.sh:83`

---

## Claim 10: "Its call is `bash PATH`, not a bare `PATH`: the same message under zsh and bash, and independent of the mode bit."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:53`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the missing-file message on the real `/opt` under bash 5.2 and zsh; the mode-bit half rests on bash reading the file as a script argument, not on a probe.

E4: both shells print `bash: /opt/claude-workflows/scripts/d6.sh: No such file or directory`, exit 127. The bare path differs: `zsh:1: no such file or directory: ...` against `bash: line 1: ...: No such file or directory`.

**Evidence:** FC3/p2.log

---

## Claim 11: "D6_OPT stays a literal ... A test pins the literal and forbids `BASH_SOURCE`, `$0` and `dirname`."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:55`
**Type:** Invariant
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the literal, the test and a mutation reading the variable from the environment; does not cover `readonly` or an exported function, the same-uid residual.

`grep -qxF 'D6_OPT=/opt/claude-workflows' "$S"` and `BASH_SOURCE|\$0|dirname` are at `test/scripts/build-loop-orchestrator.bats:279-280`. E6's `D6_OPT=${D6_OPT:-...}` mutation failed nine tests.

**Evidence:** `scripts/d6.sh:34`, `test/scripts/build-loop-orchestrator.bats:278-280`, FC3/p4.out

---

## Claim 12: Design 2's quotations: the brief's motive and Goal, and "the audit's rule for units is to apply a verdict and record any row kept after all"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:59`
**Type:** Reference
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the text of the brief and the audit; does not judge the tentative pick.

`remove every restriction without a specific, in-scope threat model` and `The block's checks keep running, now from that script.` are in the brief (`docs/working/briefs/2026-11-05-d6-block-into-image.md:10-14`). The audit says `re-checks each verdict against the code, and records in its research doc any row it keeps after all` (`docs/working/research-2026-11-01-restriction-audit.md:47`).

**Evidence:** `docs/working/briefs/2026-11-05-d6-block-into-image.md:10-14`, `docs/working/research-2026-11-01-restriction-audit.md:47`

---

## Claim 13: "restoring `scripts/d6.sh` and the D6 tests from there gives A, after updating one test phrase ... and two comments in the lib (a review probe: 16 of 16 filtered tests green with those). Later commits touch the same lines, so a plain revert of the narrowing commit no longer applies alone"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:59`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the plain revert and the restore with one phrase changed; the "16" counts one more test than E9's 15, a `--check` test from a second suite in pass 2's log, and this does not establish the whole health check under option A.

E6: `CONFLICT (content): Merge conflict in scripts/d6.sh` and in the test file. Restored unpatched, the one failure is `missing: a `refuse d6:` naming a missing image file, or the exit 127 above, means an image older than this skill`. With that phrase changed, E9 gives 15 of 15. Diffing test names against pass 2's `fc2/bats-optionC-patched.log` leaves the single extra title `every git call --check makes carries git_harden's config pairs`. The two lib comments do describe the narrowed file (Claims 37, 38).

**Evidence:** FC3/p4.out, FC3/restoreA.log, FC3/restoreA3.log

---

## Claim 14: R6c replace ref: "The gate's git ignores it (the probe above); `git_harden` sets both pins."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:63`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both pins and the probe; "nothing reads" means the gate's git, not the owner's plain git, which follows a replace ref.

`HARDEN=(core.useReplaceRefs=false ...` (`scripts/lib/dev-cycle-read.sh:333`) and `GIT_NO_REPLACE_OBJECTS=1` (`:343`). E5 as Claim 2.

**Evidence:** `scripts/lib/dev-cycle-read.sh:333-343`, FC3/p3.out

---

## Claim 15a: R6c grafts: "hardened git does follow grafts"; "`--state` dropped it (unit 1, G5)"; "git has deprecated the file and prints a hint on reading one"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:64`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git run in the real repository with the pins; does not extend to `gate_git`, whose repository has no `info/` (Claims 15b, 26a).

E5: with a graft, `rev-list --count` gave 2 plain and 2 pinned, each with `hint: Support for <GIT_DIR>/info/grafts is deprecated`. The G5 row reads `grafts: hostile-only` (`docs/working/research-2026-11-01-relax-gate-git-state.md:31`).

**Evidence:** `docs/working/research-2026-11-01-relax-gate-git-state.md:31`, FC3/p3.out

---

## Claim 15b: R6c grafts: "honest use is a deliberate history splice that everything then reads consistently"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:64`
**Type:** Behavioral
**Verdict:** Incorrect
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the real repository's git against the gate repository under one graft; does not rank how often an honest graft occurs, and leaves the drop decision itself untouched.

The gate's history reads run in a repository with no `info/`: `a git dir with no config but the repo's object format, no modules/, info/ or shallow` (`scripts/build-loop.sh:1055-1057`), with `GATE_ENV+=(GIT_DIR="$GATE_TMP/git" GIT_OBJECT_DIRECTORY="$v")` (`scripts/build-loop.sh:1072`). Real-repository reads do follow a graft, such as `git rev-list --parents -n 1` (`scripts/build-loop.sh:907`) and `git log "$MAIN_SHA" --first-parent` (`scripts/dev-cycle.sh:262`). So under a graft the two disagree: E8's real hardened walk lists the tip then the grafted parent, while `--main-log` calls that parent `not on the default branch's first-parent history`. Precise version: "that real-repository reads then follow, and the gate repository's reads (`--main-log`, merges) ignore".

**Evidence:** `scripts/build-loop.sh:1055-1072`, `scripts/build-loop.sh:907`, `scripts/dev-cycle.sh:262`, FC3/p6.out

---

## Claim 16: R6d: exactly-one is "the only such check `dev-cycle.sh` and `questions.sh` have"; "`default_gate` refuses both in `--state` ... and `--state` opens every iteration."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:65-66`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `default_gate`, a grep of both scripts and step 0; does not establish that `resolve_main` picks a safe name for those two scripts.

`refuse state default-branch: refs/heads/$MAIN is a symbolic ref` and `names an object that is not a commit` are `scripts/build-loop.sh:773-779`. Neither `default_gate` nor `state_gate` appears in `scripts/dev-cycle.sh` or `scripts/questions.sh` (paraphrased — no quote available because the claim covers absence of code).

**Evidence:** `scripts/build-loop.sh:764-791`, `skills/dev-cycle/SKILL.md:208-211`, FC3/bats-orch.log

---

## Claim 17: R6e: the walk "is now self-referential"; "pinned in `test/cc-isolated-functions.bats`"; "It also refused a run as root."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:67-68`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Dockerfile pins and the old block's text; the run-as-root part is read from the block's header, not run, since no root is available here.

`run grep -E 'chown -R root:root /opt/claude-workflows'` is `test/cc-isolated-functions.bats:778`, chmod pins at `:780`, `:785`. The removed block said `the -w test makes a run as root refuse unless the mount is read-only` (git show 5b20d4bd, `skills/dev-cycle/SKILL.md`).

**Evidence:** `test/cc-isolated-functions.bats:778-785`, `devcontainer-config/Dockerfile:525-528`

---

## Claim 18: Design 3: "d6.sh's only git call is now `show-ref`, run through the image lib's `git_harden` in a subshell ... so nothing is exported to the script."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:74`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers d6.sh's git calls and the export; does not cover pairs the caller already exported, which pass through by design.

`g() { ( harden && git "$@" ); }` (`scripts/d6.sh:38`) is called only at `:55`. The shim counts exactly two calls and the probe prints `count=unset` (`test/scripts/build-loop-orchestrator.bats:372-373`). E6's harden-in-the-main-shell mutation failed tests 6 and 8.

**Evidence:** `scripts/d6.sh:37-38`, `scripts/d6.sh:55`, FC3/p4.out

---

## Claim 19: Design 4's four-row table of skill against image

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:78-85`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers row 4 on the real image and rows 1-3 by reading; row 3 ("Works") was not run, as it needs a new root-owned image.

E4 is row 4 exactly: `bash: /opt/claude-workflows/scripts/d6.sh: No such file or directory`, exit 127, stdout empty. Row 1 holds because step 0.1's PATHS line includes `skills/dev-cycle/` (`skills/dev-cycle/SKILL.md:230`), which this branch changes. Row 3 holds by reading: the four files stay in `scripts/`, and `chown -R` covers them.

**Evidence:** `skills/dev-cycle/SKILL.md:230`, `devcontainer-config/Dockerfile:525`, FC3/p2.log

---

## Claim 20: "H2's 'a missing script refuses and names the gap' is met by that line and the Rules."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:87`
**Type:** Reference
**Verdict:** Mostly accurate
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where the quoted words are; the substance (bash's line plus the Rules) is Verified in Claims 19 and 43.

The quoted words are the brief's, `A missing script refuses and names the gap (H2).` (`docs/working/briefs/2026-11-05-d6-block-into-image.md:20`). H2 itself says `refuses and names what went unenforced` (`docs/constraints.md:6`). Precise version: "The brief's reading of H2, 'a missing script ...'".

**Evidence:** `docs/working/briefs/2026-11-05-d6-block-into-image.md:20`, `docs/constraints.md:6`

---

## Claim 21: Pre-mortem 1: "A session calls `bash scripts/d6.sh` from a checkout. The root is a literal, so it still runs the image's scripts"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:100`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unmodified working-tree file against the real image with `--help`; does not cover an edited working-tree copy, which is the "reach" the sentence names.

E4: the working-tree `scripts/d6.sh` exits 0 with the image's `--help`, byte-equal, and differs from the working tree's own `--help`.

**Evidence:** `scripts/d6.sh:34`, `scripts/d6.sh:60`, FC3/p2.log

---

## Claim 22: Pre-mortem 2: "D6_OPT is assigned, never read. BASH_ENV applies to `bash d6.sh` as it did to `bash -s` ... The scrub is pinned by a new test."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:101`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers BASH_ENV for both forms and the scrub test with its mutations; "never read" means from the environment, since the script reads its own assignment.

E5: `BASHENV-RAN` printed for both `bash d6.sh` and `bash -s`. E6: dropping `-u ENV` fails test 4.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:306-311`, FC3/p3.out, FC3/p4.out

---

## Claim 23: Pre-mortem 3, the release gap

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:102`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the image's GATE_CODE, step 0.1's list and the security review's rating; does not re-run the self-merge, which pass 1 and the security review executed.

The image's list is `GATE_CODE='^scripts/(build-loop|dev-cycle|questions)\.sh$|...` (`/opt/claude-workflows/scripts/lib/dev-cycle-read.sh:2017`), without d6. Step 0.1's entry holds `every path changed from C to M outside `docs/`` (`skills/dev-cycle/SKILL.md:237`). `**Severity:** Medium` is `docs/reviews/security-review-2026-11-05-d6-block-into-image.md:44`.

**Evidence:** `skills/dev-cycle/SKILL.md:230-240`, `docs/reviews/security-review-2026-11-05-d6-block-into-image.md:44`

---

## Claim 24: Pre-mortem 4: "The 127 path has empty stdout ... The Rules state it, step 1b's 'if either fails, go on' names it as still a stop, and a test pins those phrases. Step 0.1 comes first in every iteration"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:103`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the output, the four phrases and step order; the step 1b quotation shortens "note it in the record and go on".

E4 for stdout. The test loops over four phrases (`test/scripts/build-loop-orchestrator.bats:300-303`). `Start every iteration in this order` is `skills/dev-cycle/SKILL.md:208`.

**Evidence:** `skills/dev-cycle/SKILL.md:208-218`, `skills/dev-cycle/SKILL.md:356-359`, FC3/p2.log, FC3/bats-orch.log

---

## Claim 25: Pre-mortem 5: "exit 1 in the loop comes from `show-ref`. That exit also covers a ref git cannot use (a junk file, a dangling symbolic ref, an unreadable file): it counts as absent ... Beside a good name that passes; alone it refuses as 'not exactly one'. A test proves no pair reaches the script and every git call carries the pins."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:104`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three named shapes on git 2.39.5; the test checks six of the pins per call, with the full list pinned by the `git_harden` test, and does not establish that every unusable ref exits 1 (a ref naming a missing object exits 128, Claim 36).

E3: junk, dangling symbolic and chmod 000 each `rc=1`, and d6.sh alone prints `the default branch is not exactly one of main and master`. Beside a good `master`, junk and unreadable both run the script, exit 0.

**Evidence:** `scripts/d6.sh:50-59`, `test/scripts/build-loop-orchestrator.bats:368-377`, FC3/p1.out

---

## Claim 26a: Pre-mortem 6: "A planted `info/grafts` now reaches `--main-log`." and option [1]'s "a planted graft reaches `--main-log`: hostile-only, S1"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:105`
**Type:** Behavioral
**Verdict:** Incorrect
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `main_log` and `log_class` end to end with a control on one graft shape; does not establish which other reads a graft changes beyond the ones named, and "reaches" is true only in the empty sense that the run is no longer stopped first.

Every history read of `--main-log` is in the gate repository: `gate_git rev-list --first-parent "$MAIN_SHA" > "$GATE_TMP/fp"` (`scripts/build-loop.sh:1870`) and `gate_git cat-file commit "$c"` (`scripts/build-loop.sh:1835`, in `log_class`, which reads parents from the raw commit text). That repository has no `info/` (`scripts/build-loop.sh:1055-1057`).

Control, E8: three commits r0, r1, r2, an unrelated commit x, and `r2 x` in `.git/info/grafts`. Hardened git in the real repository lists `r2 x`, with the deprecation hint. `--main-log r0` still answers `main r2 2`, then `other r1`, `other r2`, as with no graft, and no hint. `--main-log x` answers `refuse main-log: x is not on the default branch's first-parent history`.

What a graft does reach, so the residual is real but elsewhere: `dev-cycle.sh`'s `git log` (E8 shows the hint in the digest's output), and `git rev-list --parents -n 1` and `git merge-base` in the real repository (`scripts/build-loop.sh:907`, `:1692`, `:2016`). Precise version at `:105` and `:117`: "A planted `info/grafts` no longer refuses. `--main-log` and the merge computations ignore it (the gate repository has no `info/`); the digest's `git log` and the real-repository reads follow it." The drop decision and S1's reasoning do not depend on the wrong sentence. Pass 1's Claim 24 is superseded.

**Evidence:** `scripts/build-loop.sh:1055-1072`, `scripts/build-loop.sh:1835`, `scripts/build-loop.sh:1870`, `docs/working/research-2026-11-05-d6-block-into-image.md:117`, FC3/p6.out, FC3/p5.out

---

## Claim 26b: Pre-mortem 6: "`--state` already accepted it in unit 1."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:105`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--state` through d6.sh with a graft present; does not cover what a later mode does with it.

E5: `state grafted` gives `rc=0 stdout=[ok]`.

**Evidence:** `scripts/build-loop.sh:722-736`, FC3/p3.out

---

## Claim 27: d6.sh header: "the one way the orchestrator runs build-loop.sh ..., dev-cycle.sh ... and questions.sh. The dev-cycle skill calls the root-owned image copy by absolute path"

**Location:** `scripts/d6.sh:2-5`
**Type:** Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the skill's text and a grep of its call sites; "the one way" is the skill's rule, not something a script enforces.

`cd WT && bash /opt/claude-workflows/scripts/d6.sh SCRIPT ARG...` (`skills/dev-cycle/SKILL.md:39`). No other form of call remains in the skill; `D6 block` and `bash -s -- ` have no hit there, which the `:276` test pins.

**Evidence:** `skills/dev-cycle/SKILL.md:36-41`, `test/scripts/build-loop-orchestrator.bats:276`

---

## Claim 28: "It always runs the root-owned image copy under D6_OPT by absolute path ... D6_OPT is a literal, never read from the environment or from this file's own path: a working-tree copy of this file still runs the image's scripts."

**Location:** `scripts/d6.sh:6-12`
**Type:** Invariant
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exec line, the assignment and E4's real run; "root-owned" is the image's property, which d6.sh no longer checks.

`bash "$D6_OPT/scripts/$s" "$@" </dev/null` (`scripts/d6.sh:60`) after `D6_OPT=/opt/claude-workflows` (`:34`). See Claims 11 and 21.

**Evidence:** `scripts/d6.sh:34`, `scripts/d6.sh:60`, FC3/p2.log

---

## Claim 29: "It still trusts that entry and the default branch's ref ... it cannot guard against this uid's own shell ...: the plan's same-uid residual (Q-103). In claude-workflows a gate change runs from the next image release."

**Location:** `scripts/d6.sh:12-16`
**Type:** Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that d6.sh does not validate `.git` or the ref's value and that Q-103 holds the residual; does not re-derive Q-103's list.

d6.sh runs `show-ref --verify` only, so a moved main passes (`scripts/d6.sh:55`). E5 shows BASH_ENV, one such shell route, runs first. Q-103 is at `docs/working/questions-archive.md:109`.

**Evidence:** `scripts/d6.sh:53-59`, `docs/working/questions-archive.md:109`, FC3/p3.out

---

## Claim 30: The exit list: "the script's own status; 2 and one 'refuse d6: WHY' line on stdout, with nothing run, for an image-copy file that is missing or not a regular file (a partial image), an image lib that does not load or whose git_harden refuses the caller's environment, a default branch that is not exactly one of main and master, or a git read that exits above 1 (git may add a line on stderr); 1 for another first argument."

**Location:** `scripts/d6.sh:19-24`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each branch by test and probe, with the observer being the skill's Rules; a `git_harden` refusal also adds its own stderr line, which the parenthetical does not mention but the stdout claim allows.

`no() { echo "refuse d6: $*"; exit 2; }` (`scripts/d6.sh:35`) is the only exit-2 route, and `exec` passes the script's status. E3 with `GIT_CONFIG_COUNT=010`: stdout has the one refuse line, stderr has `d6.sh: GIT_CONFIG_COUNT is not a plain decimal count`.

**Evidence:** `scripts/d6.sh:35-60`, `scripts/lib/dev-cycle-read.sh:338`, FC3/p1.out, FC3/bats-orch.log

---

## Claim 31: "An image with no d6.sh at all prints nothing of this: bash exits 127 naming the path, which the skill's Rules read as this refusal."

**Location:** `scripts/d6.sh:24-25`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the real image as it stands today; a script's own 127 is told apart only by the Rules' "naming d6.sh".

E4 on the real `/opt`, which has no d6.sh. Rules: `skills/dev-cycle/SKILL.md:47-49`.

**Evidence:** `skills/dev-cycle/SKILL.md:47-49`, FC3/p2.log

---

## Claim 32: "Its git is the image lib's git_harden, in a subshell, so the script starts from the caller's environment, not with d6.sh's pairs."

**Location:** `scripts/d6.sh:26-27`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exported pairs; the environment is the caller's less the six scrubbed names, and an exported variable sharing a d6.sh local name (`x`, `s`, `n`) was not probed.

`g() { ( harden && git "$@" ); }` and `( harden ) || no ...` (`scripts/d6.sh:38`, `:52`). See Claim 18.

**Evidence:** `scripts/d6.sh:37-38`, `scripts/d6.sh:52`, `scripts/d6.sh:60`, FC3/bats-orch.log, FC3/p4.out

---

## Claim 33: "These checks come before, not instead of, build-loop.sh's own state and default-branch gates in its gated modes, which also refuse a symbolic or non-commit default branch (dev-cycle.sh, questions.sh and the read modes have none; row 548 for dev-cycle.sh)."

**Location:** `scripts/d6.sh:27-31`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--state`, `--main-log`, `--check`, `--merge`, `--prompt`, `--cycle-diff` and `--land-cycle` on a symbolic default and `--cycle-diff`, `--main-log` and `--check` on a tag; `--check-constraints` runs without the gate, as it exits before it, so it counts as a read mode here though `GATED` would mark it.

E7 prints `refuse state default-branch: refs/heads/main is a symbolic ref` for each and `names an object that is not a commit` for the tag, while `--settings` and `--marker` run on. `--check-constraints` exits at `if [[ "$MODE" == check-constraints ]]` (`scripts/build-loop.sh:680`), before `:800`. Row 548 is the origin/HEAD row quoted at `docs/working/questions-archive.md:3500`.

**Evidence:** `scripts/build-loop.sh:680`, `scripts/build-loop.sh:798-801`, `scripts/build-loop.sh:1292-1300`, FC3/p3.out, FC3/p5.out

---

## Claim 34: "What it no longer checks, and why, is rows R6c to R6e of the restriction audit, in docs/working/research-2026-11-05-d6-block-into-image.md."

**Location:** `scripts/d6.sh:31-32`
**Type:** Reference
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the named doc holds those rows with decisions and reasons; the audit proper is `research-2026-11-01-restriction-audit.md`, and the named doc is its re-check.

The table at `docs/working/research-2026-11-05-d6-block-into-image.md:61-68` lists R6c, R6d and R6e row by row.

**Evidence:** `docs/working/research-2026-11-05-d6-block-into-image.md:61-68`

---

## Claim 35: "The four files the scripts run (build-loop.sh and dev-cycle.sh source the lib from their own directory; dev-cycle.sh runs questions.sh beside it). lib/migrations.sh is left out: both scripts check it themselves before use."

**Location:** `scripts/d6.sh:42-44`
**Type:** Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the source and run lines in both scripts; questions.sh sources nothing, and no other helper was found by grep.

`READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"` (`scripts/build-loop.sh:570`, `scripts/dev-cycle.sh:97`), `QS="$SCRIPT_DIR/questions.sh"` (`scripts/dev-cycle.sh:384`). Migrations: `if [[ ! -f "$SCRIPT_DIR/lib/migrations.sh" ...` (`scripts/build-loop.sh:2067`) and `lib/migrations.sh is missing beside this script` (`scripts/dev-cycle.sh:579`).

**Evidence:** `scripts/build-loop.sh:570`, `scripts/build-loop.sh:2067-2072`, `scripts/dev-cycle.sh:97`, `scripts/dev-cycle.sh:384`, `scripts/dev-cycle.sh:576-583`

---

## Claim 36: "Tried alone first, so that exit 1 below comes from show-ref, which counts as absent a ref it cannot use (a junk or dangling one), as the block did."

**Location:** `scripts/d6.sh:50-51`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers five broken-ref shapes on git 2.39.5; the exit-1 attribution and the refusals are right, the imprecision is only what "a ref it cannot use" and "dangling" include.

Junk and a dangling **symbolic** ref exit 1 (E3). A ref that names a missing object, the other common sense of dangling, exits 128: `fatal: git show-ref: bad ref refs/heads/main (aaaa...)`, and d6.sh refuses `refs/heads/main could not be read`, even beside a good master. The block counted that as absent, since `g show-ref ... && m+="$n "` took any failure. So d6.sh is stricter than the block there, and the code is on the safe side. Precise version: "(a junk one or a dangling symbolic one)", which is what the research doc's `:104` already says.

**Evidence:** `scripts/d6.sh:50-59`, `docs/working/research-2026-11-05-d6-block-into-image.md:104`, FC3/p1.out

---

## Claim 37: "scripts/d6.sh is the exception to what follows: it sources the image copy in a subshell for git_harden alone, with no -e and no ROOT_REAL."

**Location:** `scripts/lib/dev-cycle-read.sh:13-14`
**Type:** Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers d6.sh's shell options and use of the lib; d6.sh also does not cd to the repo root, which the comment leaves unsaid.

`set -u -o pipefail` (`scripts/d6.sh:33`), `harden() { source "$D6_OPT/scripts/lib/dev-cycle-read.sh" && git_harden; }` (`:37`), and no `ROOT_REAL` in the file.

**Evidence:** `scripts/d6.sh:33`, `scripts/d6.sh:37`

---

## Claim 38: "d6.sh calls it in a subshell for its own git"

**Location:** `scripts/lib/dev-cycle-read.sh:311-312`
**Type:** Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the call sites; there are three subshells, one per call, so `git_harden`'s run-once guard never acts in d6.sh.

`( harden ) || no` and `g()` (`scripts/d6.sh:38`, `:52`), with `g` called twice from the `:54` loop.

**Evidence:** `scripts/d6.sh:37-38`, `scripts/d6.sh:52-55`

---

## Claim 39: "The scripts because ...; scripts/d6.sh because it runs the gate; skills/dev-cycle/ because its SKILL.md states the call .... Both reach a session only from a release"

**Location:** `scripts/lib/dev-cycle-read.sh:1027-1032`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the sentence's count; the reasons and the release claim are right for all three.

The list now has three items and `Both` was written for two. Precise version: "All three reach a session only from a release".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1027-1032`

---

## Claim 40: The renamed comments: "a name d6.sh does not take"; "through d6.sh (the image copy; this file sits in its root-owned lib/)"; build-loop.sh's header "scripts/build-loop.sh, d6.sh, dev-cycle.sh, questions.sh"

**Location:** `scripts/build-loop.sh:759-763`
**Type:** Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three edited comments and the floor test with d6.sh in its list; does not cover other comments in those files.

d6.sh takes only main and master (`scripts/d6.sh:54`). `scripts/build-loop.sh:451-455` matches GATE_CODE at `scripts/lib/dev-cycle-read.sh:1035`. `scripts/lib/migrations.sh:33-38` matches step 1b.

**Evidence:** `scripts/build-loop.sh:451-455`, `scripts/lib/migrations.sh:33-38`, FC3/bats-check.log

---

## Claim 41: Rules bullet: the one-line call; "d6.sh is the root-owned image copy, and it runs the image's SCRIPT"; "a gate change merged here runs from the next image release (step 0.1 checks the lag)"

**Location:** `skills/dev-cycle/SKILL.md:36-45`
**Type:** Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the call, the target and step 0.1's check; "no repository file or state ... chooses" holds for which script runs, not which repository it reads (Claim 29).

See Claims 28 and 47; d6.sh's exec is `scripts/d6.sh:60`.

**Evidence:** `skills/dev-cycle/SKILL.md:36-45`, `scripts/d6.sh:60`, FC3/bats-orch.log

---

## Claim 42: "`refuse d6: WHY` (exit 2; d6.sh's header lists them) or a usage line on stderr (exit 1, a first argument that is none of the three) means nothing ran."

**Location:** `skills/dev-cycle/SKILL.md:46-47`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both outputs through the shipped file; "nothing ran" means no gate script, as the lib may have been sourced.

The test asserts `[ "$status" -eq 1 ] && [ -z "$output" ]` with the usage text on stderr (`test/scripts/build-loop-orchestrator.bats:348-349`). Header list: Claim 30.

**Evidence:** `scripts/d6.sh:35`, `scripts/d6.sh:40`, FC3/bats-orch.log

---

## Claim 43: 127 site 1: "So does exit 127 with `bash`'s `No such file or directory` line naming d6.sh: that is the same refusal from an image older than this skill, which has no d6.sh to print it."

**Location:** `skills/dev-cycle/SKILL.md:47-49`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the real line on the real image; does not establish other sources of 127.

E4, and the test at `test/scripts/build-loop-orchestrator.bats:291`.

**Evidence:** FC3/p2.log, FC3/bats-orch.log

---

## Claim 44: 127 site 2: "a call of any script that the Bash tool timed out, and a `refuse d6:` line or that exit 127, are stops too."

**Location:** `skills/dev-cycle/SKILL.md:53-54`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the phrase's presence and its place after the check-modes clause; a stop is a rule the skill states, not code that runs.

Pinned by the phrase list at `test/scripts/build-loop-orchestrator.bats:300-303`.

**Evidence:** `skills/dev-cycle/SKILL.md:51-58`, FC3/bats-orch.log

---

## Claim 45: 127 site 3: "the exit 127 above means an image older than this skill, and a `refuse d6:` naming a missing image file a partial image: either entry also gives the release paste below"

**Location:** `skills/dev-cycle/SKILL.md:217-218`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two meanings and that a release paste exists below; by the Rules a 127 here files as an agent work item, not a `you: judgment` entry, so "entry" is used loosely.

Both meanings match E4 and `no "$x is missing"` (`scripts/d6.sh:47`). The paste is `cd A && test "$(git rev-parse HEAD)" = M &&` (`skills/dev-cycle/SKILL.md:243-244`). Rules routing: `else the line and stderr go in` / `one agent work item` (`skills/dev-cycle/SKILL.md:57-58`).

**Evidence:** `skills/dev-cycle/SKILL.md:57-58`, `skills/dev-cycle/SKILL.md:217-218`, `skills/dev-cycle/SKILL.md:243-244`, FC3/p2.log

---

## Claim 46: 127 site 4: "(a `refuse d6:` line, its exit 127 or a timed-out call is still a stop, as the Rules say)"

**Location:** `skills/dev-cycle/SKILL.md:358-359`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers agreement with the Rules and the pinned phrase; does not establish a step 1b call could reach a 127, since step 0.1 stops first.

Same as Claim 44, and the fourth phrase in the test's list.

**Evidence:** `skills/dev-cycle/SKILL.md:356-359`, FC3/bats-orch.log

---

## Claim 47: Step 0.1's PATHS line and the merge-gate slug rule both state GATE_CODE with d6

**Location:** `skills/dev-cycle/SKILL.md:230`
**Type:** Configuration
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both copies, the lib and the floor test; `image_cleared` was not traced beyond its passing tests.

`scripts/build-loop.sh scripts/d6.sh scripts/dev-cycle.sh scripts/questions.sh scripts/lib/ skills/dev-cycle/` (`:230`) and `^scripts/(build-loop|d6|dev-cycle|questions)\.sh$|...` (`:618`). Tests 13 and 14 of E1 pin them, and `scripts/d6.sh "$GATE"` is in the floor list (`test/scripts/build-loop-check.bats:262`).

**Evidence:** `skills/dev-cycle/SKILL.md:618`, `scripts/lib/dev-cycle-read.sh:1035`, FC3/bats-orch.log, FC3/bats-check.log

---

## Claim 48: Helper comments: "the file itself, with one literal changed, runs in these tests"; "a uid-owned OPT stands in for the root-owned image, as d6.sh checks presence, not owner"; "In its real place beside the scripts, where the stand-in can hold it"; "d6_setup: main holds this branch's four scripts, and so does a stand-in at $U"; d6_is "refused with exactly WANT, exit 2, before running anything"

**Location:** `test/scripts/build-loop-orchestrator.bats:247-265`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the helpers as read and as run; `d6_is` allows stderr only for `could not be read`, matching the header's parenthetical.

`cp "$REPO_ROOT/scripts/d6.sh" "$D6"` then one `sed` guarded on both sides (`:255-256`), and `[[ ! -w "$1/scripts" ]] || D6="$1/scripts/d6.sh"` (`:254`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:247-265`, FC3/bats-orch.log

---

## Claim 49: Title: "SKILL.md states d6.sh's one-line call once, by absolute path, with no pasted block; d6.sh names no other copy to run: no root test, no read of main's scripts"

**Location:** `test/scripts/build-loop-orchestrator.bats:273`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test's greps against HEAD; "no other copy" is a pattern list, not a proof over all shell forms.

Passes in E1; the `envopt` mutation fails it.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:273-282`, FC3/bats-orch.log, FC3/p4.out

---

## Claim 50: Title: "d6.sh reaches the image with no installer or Dockerfile change: scripts/ is a payload item, and a .sh file is made 0555"

**Location:** `test/scripts/build-loop-orchestrator.bats:284`
**Type:** Configuration
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the text of both files and the tree mode 100755; does not build an image.

Passes in E1; `git ls-files -s scripts/d6.sh` gives `100755`.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:284-289`, `devcontainer-config/install.sh:146`, `devcontainer-config/Dockerfile:528`, FC3/bats-orch.log

---

## Claim 51: Title: "the skill's d6 call on an image with no d6.sh ...: exit 127, bash names the path, nothing runs, and the Rules read it as a refusal"

**Location:** `test/scripts/build-loop-orchestrator.bats:291`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test and its sentinel; the call is run as argv, not through a shell, and without the skill's `cd WT &&`.

The sentinel is live: E7 ran `build-loop.sh --settings` with the appended `touch` line and it fired (`ran=yes`), so `[ ! -e "$BATS_TEST_TMPDIR/ran" ]` can fail.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:291-304`, FC3/p5.out, FC3/bats-orch.log

---

## Claim 52: Title: "d6.sh scrubs the caller's variables and closes stdin before it runs the image's script; a caller's stdin never reaches it"

**Location:** `test/scripts/build-loop-orchestrator.bats:306`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all six names and stdin; "closes" is `</dev/null`, an EOF, not a closed descriptor, which changes nothing a script would see here.

Mutations `scrubENV` and `stdin` each fail this test alone (E6).

**Evidence:** `scripts/d6.sh:60`, `test/scripts/build-loop-orchestrator.bats:306-311`, FC3/p4.out

---

## Claim 53: Title and comments: "d6.sh runs the image copy's scripts by absolute path, with the image's own lib and questions.sh, never main's or the working tree's"; "--state through d6.sh passes."

**Location:** `test/scripts/build-loop-orchestrator.bats:313`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all three scripts; `lib at` is asserted for build-loop.sh's run only, with dev-cycle.sh's lib shown by the code at `scripts/dev-cycle.sh:97`.

Passes in E1.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:313-330`, FC3/bats-orch.log

---

## Claim 54: Title and comment: "d6.sh refuses before running anything: ..."; "A lib that does not load, or a git_harden that refuses, is named as that, never as an absent branch."

**Location:** `test/scripts/build-loop-orchestrator.bats:332`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every case in the title plus the lib cases; a syntax error in the lib was not separately run in this pass, only `return 1`.

Mutations `notried`, `rcany` and `nosymlink` each fail this test alone (E6).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:332-350`, FC3/p4.out

---

## Claim 55: Title and comments: "d6.sh runs the script past what audit rows R6c to R6e dropped: ... --state still refuses the two default-branch shapes"; "git refuses to update-ref a branch to a tag: write the ref file (row 656's case)."

**Location:** `test/scripts/build-loop-orchestrator.bats:352`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each shape; the replace and graft cases assert status 0 on `--settings`, not what any read then saw.

E5: `update_ref failed ... trying to write non-commit object`, exit 128. Row 656 matches `scripts/build-loop.sh:775`. Each shape's refuse line comes from build-loop.sh, so d6.sh did pass it on.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:352-366`, `scripts/build-loop.sh:775-779`, FC3/p3.out

---

## Claim 56: Title: "d6.sh's own git is hardened by the image lib's git_harden, and no pair reaches the script (T26 ...)"

**Location:** `test/scripts/build-loop-orchestrator.bats:368`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both calls and six of the pins; a full-list check is the `git_harden` test at `:406`.

Mutations `noharden` and `noexport` fail it (E6).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:368-377`, FC3/p4.out

---

## Claim 57: Title: "a gate copy patched in the loop's worktree prints ok for its tip; d6.sh's image copy refuses the same tip (T27, U3b3)"

**Location:** `test/scripts/build-loop-orchestrator.bats:379`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test as run; only the wording changed on this branch.

Passes in E1.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:379-390`, FC3/bats-orch.log

---

## Claim 58: Titles: "d6.sh runs the root-owned image copy at /opt by absolute path, not main's copy (T37 ...)"; "d6.sh refuses an image copy missing a file (a partial image), and never runs main's (T37 ...)"

**Location:** `test/scripts/build-loop-orchestrator.bats:392`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** See Claim 7; the second test's "never runs main's" rests on the exact refuse line.

Passes in E1, against the real `/opt`.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:392-404`, FC3/bats-orch.log

---

## Claim 59: "d6.sh repeats neither list: it runs the lib's git_harden (its own test above)."

**Location:** `test/scripts/build-loop-orchestrator.bats:417`
**Type:** Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the grep on two sentinel names and the test's place in the file; other names of the lists are not grepped.

`! grep -nE '^[^#]*(GIT_NO_REPLACE_OBJECTS|core\.hooksPath)'` (`:418`), and the test it names is at `:368`, above.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:368`, `test/scripts/build-loop-orchestrator.bats:417-418`, FC3/bats-orch.log

---

## Claims Requiring Attention

### Incorrect
- **Claim 26a** (`docs/working/research-2026-11-05-d6-block-into-image.md:105`, `:117`): `--main-log` ignores `info/grafts`, because `gate_git`'s repository has no `info/`. Restate where a graft does reach (the digest's `git log`, real-repository reads), including the owner's option [1] cell.
- **Claim 15b** (`docs/working/research-2026-11-05-d6-block-into-image.md:64`): "everything then reads consistently" is false for the same reason: real-repository reads and the gate repository disagree under a graft.

### Stale
- **Claim 4** (`docs/working/plan-build-loop-handoff.md:406`, `:151`, `:431`): live table rows still say "D6 snippet" or "hardened snippet", outside the diff.

### Mostly Accurate
- **Claim 9** (`docs/working/research-2026-11-05-d6-block-into-image.md:53`): "it alone" also fits the no-wrapper row; qualify to the options that keep R6f.
- **Claim 20** (`docs/working/research-2026-11-05-d6-block-into-image.md:87`): the quoted words are the brief's, not H2's.
- **Claim 36** (`scripts/d6.sh:50-51`): "dangling" holds for a symbolic ref; a ref naming a missing object exits 128 and refuses, so say "dangling symbolic".
- **Claim 39** (`scripts/lib/dev-cycle-read.sh:1031`): "Both" now has three antecedents.

### Unverifiable
- None.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to docs/reviews/code-fact-check-report-final-r2-2026-11-05-d6-block-into-image.md, first line `Commit: 1c5fd04f`, every claim tagged Legibility-target, ending with a Goal-Alignment Note (patterns/orchestrated-review.md). Do not commit.
- Answered: yes; every dispatch-named claim verdicted against the code that exercises it, with d6.sh's header line by line.
- Out of scope: hostile-author findings (S1); the known-stale 2b0838bb revert claim; a built image; roadmap "D6 block" lines, which are cycle-owned.
- Escalate: Claims 15b and 26a correct a Verified from pass 1 and change the owner's option [1] cost cell, so the owner should see the corrected sentence. The other five items are small wording fixes.
- Decisions I made: read "reaches `--main-log`" as "changes what it reports", not "is no longer stopped first", since the sentence sits in a failure story and the owner's "If it's wrong" cell; the other reading would make it Verified but empty. Reported Claim 4 though outside the diff, because T27's test title changed on this branch; leaving it out was defensible.
