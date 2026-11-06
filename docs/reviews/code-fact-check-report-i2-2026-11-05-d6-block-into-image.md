Commit: b8722aba

# Code Fact-Check Report

**Repository:** claude-workflows, worktree `.claude/wt-2026-11-05-d6-block-into-image`, branch `refactor/d6-block-into-image`
**Scope:** `git diff 4dd68cdc..b8722aba -- . ':!docs/reviews'` (6 files), plus the rows and items the dispatch named and the code that exercises them; commits before 4dd68cdc are context only
**Checked:** 2026-11-05
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 24
**Summary:** 18 verified, 4 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

One claim is wrong, in two places: exit 1 from the loop's `show-ref` is not only "no such ref". `git show-ref --verify -q` also exits 1 for a junk ref file, a dangling symbolic ref and an unreadable ref file (Claims 12b, 14b). The code's refusals still hold and this behaviour is not new; the comment and the pre-mortem sentence overstate it. Option [2] needs one more edit than it says (Claim 9).

No claim in scope matches a pattern in `docs/reviews/hallucination-patterns.md`, and neither Incorrect verdict is a fabricated symbol, so nothing qualifies for that log.

## Execution provenance

Each row ran under `timeout`. FC2 is `/tmp/claude-1000/-workspace/47403b7b-5fcb-4e13-8807-c539081df064/scratchpad/2026-11-05-d6-block-into-image/fc2/`. Logs stay there because the dispatch allowed no edit but this report, so `docs/reviews/execution-logs/` was not used. Both scratch worktrees are removed and no probe is running. git is 2.39.5. The image at `/opt/claude-workflows` is commit c214970a and holds no `d6.sh`.

| Id | Command | Cwd | Exit | Start (UTC) | Output |
|---|---|---|---|---|---|
| E1 | `TMPDIR=FC2/tmpD timeout 280 bats -f 'd6' test/scripts/build-loop-orchestrator.bats` (11 of 11 ok, none skipped) | worktree | 0 | finished 2026-11-06T07:16:41Z (start stamp overwritten by E7) | FC2/bats-head-d6.log |
| E2 | `timeout 200 bats -f 'merge-gate\|GATE_CODE\|gate path' test/scripts/build-loop-check.bats test/scripts/build-loop-orchestrator.bats` | worktree | 0 | finished 2026-11-06T07:16:41Z | FC2/bats-head-gate.log |
| E3 | `timeout 120 bats -f 'needs merge-gate-STEM' test/scripts/build-loop-merge.bats` | worktree | 0 | 2026-11-06T07:18:23Z | FC2/bats-head-t35.log |
| E4 | `timeout 120 bash probeA.sh` (HEAD's d6.sh with one literal changed: broken refs, broken libs, usage exits) | FC2 | 0 | 2026-11-06T07:16:03Z | FC2/probeA.log |
| E5 | `timeout 120 bash probeB.sh` (the image's build-loop.sh: `--check` and `--merge` of a self-merge brief naming `scripts/d6.sh`, never line none and set) | FC2 | 0 | 2026-11-06T07:16:37Z | FC2/probeB.log |
| E6 | `timeout 400 bash probeC.sh`, then `timeout 450 bash probeC2.sh` (scratch `git worktree add --detach` at b8722aba, d6.sh and the orchestrator tests restored from da07a77c) | FC2 | 0, 0 | 2026-11-06T07:16:18Z, 07:18:06Z | FC2/probeC.log, FC2/probeC2.log, FC2/bats-optionC.log, FC2/bats-optionC-wide.log, FC2/bats-optionC-patched.log, FC2/revert.log |
| E7 | `timeout 120 bash probeD.sh` (two-glob never line, docs/dev-cycle.md on a branch, replace graft and info/grafts under git_harden, GATE_CODE per lib, the real diff from C) | FC2 | 0 | 2026-11-06T07:18:15Z | FC2/probeD.log |

---

## Claim 1: "A change to the gate's own files (`scripts/{build-loop,d6,dev-cycle,questions}.sh`, `scripts/lib/`, `skills/dev-cycle/`) gets its own slug, `merge-gate-…`. Plain `--approved` refuses such a change (F52)."

**Location:** `docs/working/plan-build-loop-handoff.md:63`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the list against HEAD's GATE_CODE and the plain-slug refusal for three sample gate paths; does not establish a `--approved` run on `scripts/d6.sh` itself, which rests on the same regex.

`scripts/lib/dev-cycle-read.sh:1035` reads `GATE_CODE='^scripts/(build-loop|d6|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'`, the same six items. E7 matched each listed path as `gate` and `scripts/other.sh` as `no`. E3 ran the T35 case, which refuses a plain slug with `its heading must read "Q-001 · $G" (the merge changes the gate's own code)` (`test/scripts/build-loop-merge.bats:286`). That case loops over `scripts/build-loop.sh Scripts/Lib/x.sh skills/dev-cycle/references/x.md` (`:283`); `scripts/d6.sh` is pinned for the floor at `test/scripts/build-loop-check.bats:262`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1035`, `test/scripts/build-loop-merge.bats:282-292`, `test/scripts/build-loop-check.bats:262`, FC2/probeD.log, FC2/bats-head-t35.log

---

## Claim 2: The D6 amendment bullet ("the snippet is no longer inline ... d6.sh keeps 'exactly one of main and master', 'each image file present and a regular file' and the variable scrub; it drops ... T33, T36 and T37 test the file; T37's uid-owned case and T36's replace and graft cases went, and a new case pins that d6.sh now passes them.")

**Location:** `docs/working/plan-build-loop-handoff.md:88`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each kept and dropped check and the test moves; does not establish that the bullet lists everything d6.sh does, as it never mentions the lib-load refusal added in b8722aba (it says "keeps", and that check is new).

`scripts/d6.sh:45-49` holds the presence loop, `:53-58` the exactly-one check and `:59` the scrub: `exec env -u BASH_ENV -u ENV -u DEV_CYCLE_SCRUBBED -u QUESTIONS_LIVE -u QUESTIONS_ARCHIVE -u QUESTIONS_WATCHING bash "$D6_OPT/scripts/$s" "$@" </dev/null`. No replace, grafts, symbolic-ref or ownership check remains (paraphrased — no quote available because the claim covers absence: the file's 59 lines were read whole). The new case is `test/scripts/build-loop-orchestrator.bats:352`, which passed in E1. E7 confirmed the graft residual: `replace graft: plain=2 hardened=3` and `info/grafts: plain=2 hardened=2`.

**Evidence:** `scripts/d6.sh:33-59`, `test/scripts/build-loop-orchestrator.bats:332-366`, FC2/bats-head-d6.log, FC2/probeD.log

---

## Claim 3: F38 "`git_harden` ignores replace refs; d6.sh refuses a default branch that is not exactly one of main and master (T36 ...). Grafts are an accepted hostile-only residual"

**Location:** `docs/working/plan-build-loop-handoff.md:166`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers replace refs under the pins and refusal of both or neither good name; does not establish refusal of a broken name beside a good one, which counts as absent and passes (Claim 14b).

`HARDEN` holds `core.useReplaceRefs=false` and `git_harden` exports `GIT_NO_REPLACE_OBJECTS=1` (`scripts/lib/dev-cycle-read.sh:333,343`). E7 shows the hardened count ignoring a replace graft and following `info/grafts`. E1's T36 case refuses both names and neither name (`test/scripts/build-loop-orchestrator.bats:334-335`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:333-343`, `scripts/d6.sh:53-58`, FC2/probeD.log, FC2/bats-head-d6.log

---

## Claim 4: F39 "`/opt/...` by absolute path, in every repository (Q-140 [1]; the root-commit choice is gone); the image's own ownership, not a runtime check, since 2026-11-05 (D6) (T37)"

**Location:** `docs/working/plan-build-loop-handoff.md:167`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the literal root, the absence of an owner check and T37's run against the real `/opt` (a copy of d6.sh, since this image has none); does not establish the new line's branch to the image's own d6.sh at `:396`, which cannot run before a release.

`scripts/d6.sh:34` is `D6_OPT=/opt/claude-workflows`. d6.sh has no `stat`, owner or root test (paraphrased — no quote available because the claim covers absence of code: the file was read whole; no test pins that absence). E1 ran the T37 case at `:392` with no skip.

**Evidence:** `scripts/d6.sh:34`, `test/scripts/build-loop-orchestrator.bats:392-398`, FC2/bats-head-d6.log

---

## Claim 5: T33 "d6.sh (as built, U4c; a file since 2026-11-05, D6): runs the image copy's four files (build-loop.sh and dev-cycle.sh with their own lib, dev-cycle.sh with its own `questions.sh`); main's and the working tree's copies have no effect; SKILL.md states the one-line call once"

**Location:** `docs/working/plan-build-loop-handoff.md:408`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all the row's behaviour; does not establish that the T33 test itself pins dev-cycle.sh's lib, as it reads the lib line only for build-loop.sh (E4 case q showed dev-cycle.sh sourcing the image's lib).

`test/scripts/build-loop-orchestrator.bats:324` checks the `lib at $U/...` line on `d6 build-loop.sh --settings`'s stderr; `:327-328` check `d6 dev-cycle.sh`'s stdout only. E4 case q printed `lib at .../a/opt/scripts/lib/dev-cycle-read.sh` for `dev-cycle.sh`. The once-only call is `[ "$(grep -cxF "  ${q}cd WT && bash /opt/claude-workflows/scripts/d6.sh SCRIPT ARG...$q" "$K")" -eq 1 ]` (`:275`), passing in E1.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:273-282`, `test/scripts/build-loop-orchestrator.bats:313-330`, FC2/bats-head-d6.log, FC2/probeA.log

---

## Claim 6: T36 "not exactly one of main and master, a repository git cannot read, an image file missing or not a regular file, another first argument → d6.sh refuses before running anything; a replace ref or `info/grafts` no longer refuses"

**Location:** `docs/working/plan-build-loop-handoff.md:411`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed refusal and pass; does not establish the row's "a repository git cannot read" for a broken loose ref, which reads as absent (Claim 14b).

Each listed case is right, but the row predates b8722aba: the T36 test now also pins the lib refusal, `L="refuse d6: $U/scripts/lib/dev-cycle-read.sh did not load, or its git_harden refused this environment"` (`test/scripts/build-loop-orchestrator.bats:345`), which neither the row nor the test's title names. The precise row adds "an image lib that does not load, or a git_harden that refuses".

**Evidence:** `test/scripts/build-loop-orchestrator.bats:332-350`, `scripts/d6.sh:51`, FC2/bats-head-d6.log

---

## Claim 7: T37 "A non-claude-workflows fixture repo with `scripts/build-loop.sh` on main → the snippet runs the real `/opt` copy (skipped without one), not main's; a missing file → refuse (a uid-owned stub dir no longer refuses: amended 2026-11-05, D6)"

**Location:** `docs/working/plan-build-loop-handoff.md:412`
**Type:** Behavioral / Staleness
**Verdict:** Mostly accurate
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the behaviour; does not establish other "snippet" wording, such as T27 at `:406` and `:431`, which this pass did not verdict.

The behaviour holds (E1), and the uid-owned pass is `test/scripts/build-loop-orchestrator.bats:352`. The row still says "the snippet" where the delta changed T33's wording to "d6.sh"; the amendment at `:88` defines the snippet as now being that file, so the word misleads little. The precise row reads "d6.sh runs".

**Evidence:** `test/scripts/build-loop-orchestrator.bats:392-403`, FC2/bats-head-d6.log

---

## Claim 8: "exit 1 for a bad first argument stays, and the Rules now state it."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:21`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `x`, an empty argument and no argument; does not establish that every exit 1 of a call is this one, since each script has its own (Claim 16).

`scripts/d6.sh:40` ends `{ echo "d6: the first argument is build-loop.sh, dev-cycle.sh or questions.sh" >&2; exit 1; }`. E4 case k gave rc=1, empty stdout and that line for all three forms. `skills/dev-cycle/SKILL.md:46-47` states it.

**Evidence:** `scripts/d6.sh:39-40`, `skills/dev-cycle/SKILL.md:46-47`, FC2/probeA.log

---

## Claim 9: "restoring `scripts/d6.sh` and its tests from there gives A" and option [2] "restore `scripts/d6.sh` and its tests from da07a77c, the move with every check kept"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:59`, `:118`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two files restored over b8722aba with GATE_CODE and SKILL.md left at HEAD, under `bats -f 'd6|GATE_CODE|git_harden|image-lag'` and the health check's shellcheck flags; does not establish the whole health check, or a run against a real root-owned image.

The checks do come back, but the restored tests do not pass against HEAD's SKILL.md. `-f 'd6'` gives 9 of 10. The wider filter gives 15 of 16, the same single failure:

```
# missing: a `refuse d6:` naming a missing image file, or the exit 127 above, means an image older than this skill
```

That phrase is the one b8722aba rewrote at `skills/dev-cycle/SKILL.md:217-218`. With that one phrase in the restored test changed to HEAD's wording, all 16 pass (`bats-optionC-patched.log`). The other parts agree: the GATE_CODE pins pass, and `shellcheck -x -e SC1091 -s bash -S warning` (the flags at `scripts/health-check.sh:525`) exits 0 on the old file. The precise option says to also change that phrase. Restoring also leaves two lib comments false, since the old d6.sh does not call `git_harden` but repeats its environment as `G=(env GIT_NO_REPLACE_OBJECTS=1 ...`: `scripts/lib/dev-cycle-read.sh:13-14` and `:311`.

**Evidence:** `docs/working/research-2026-11-05-d6-block-into-image.md:59`, `docs/working/research-2026-11-05-d6-block-into-image.md:118`, `skills/dev-cycle/SKILL.md:217-218`, `scripts/health-check.sh:525`, FC2/probeC.log, FC2/probeC2.log, FC2/bats-optionC.log, FC2/bats-optionC-wide.log, FC2/bats-optionC-patched.log

---

## Claim 10: "Later commits touch the same lines, so a plain revert of the narrowing commit no longer applies alone"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:59`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `git revert --no-commit 2b0838bb` on b8722aba; does not establish any other revert order.

E6 exits 1 with `CONFLICT (content): Merge conflict in scripts/d6.sh` and the same for `test/scripts/build-loop-orchestrator.bats`.

**Evidence:** FC2/revert.log, FC2/probeC2.log

---

## Claim 11a: Pre-mortem 3, the window: "the image's floor does not list `scripts/d6.sh`, so a self-merge naming it in `Paths:` would pass unflagged ... The new image's GATE_CODE closes it. Step 0.1's old PATHS line also omits the file, but `skills/dev-cycle/` differs from the same merge until the release."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:102`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the image at c214970a on a fixture, and the real diff from C to b8722aba; does not establish that the lag entry stays open across every later iteration.

`/opt/claude-workflows/scripts/lib/dev-cycle-read.sh:2017` has no `d6` in GATE_CODE. E5, with `Self-merge never: none`, printed `merged docs/working/briefs/2026-10-01-x.md ...` and main's subject `Merge branch 'feat/x' (build-loop self-merge)`, with `path ... A scripts/d6.sh` unflagged. HEAD's lib matches the path (E7). `/opt/claude-workflows/skills/dev-cycle/SKILL.md:293` omits the file, and E7's `git diff --quiet` from C over those paths exited 1, naming `skills/dev-cycle/SKILL.md`.

**Evidence:** `/opt/claude-workflows/scripts/lib/dev-cycle-read.sh:2017`, `/opt/claude-workflows/skills/dev-cycle/SKILL.md:293`, FC2/probeB.log, FC2/probeD.log

---

## Claim 11b: Pre-mortem 3, the bound: "the `image-lag` entry this merge opens lists every changed path."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:102`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the image skill's entry text against the real diff; does not establish that a session writes the entry as specified, since it is skill prose.

`scripts/d6.sh` is listed, so the bound holds for the file at issue, but "every" is too broad. The entry's "changed names" are the PATHS diff, which omits the file on the old skill; the wider list is `every path changed from C to M outside `docs/` on one line` (`/opt/claude-workflows/skills/dev-cycle/SKILL.md:300-301`), with `docs/` given only as a count. E7: `outside docs/ holds d6.sh: 1`, `docs/ count: 39`. The precise version is "every changed path outside `docs/`".

**Evidence:** `/opt/claude-workflows/skills/dev-cycle/SKILL.md:296-302`, FC2/probeD.log

---

## Claim 11c: Pre-mortem 3, the remedy: "the cycle can add `scripts/d6.sh` to `Self-merge never:` in `docs/dev-cycle.md`, which the old image reads from main ... this branch may not edit that file. The security review rated the window Medium."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:102`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the image's refusal with the line on main, this repo's two-glob form, and the N rule on both builds; does not establish the other option, "dispatch no brief touching the file", which is a practice, not code.

E5 with the line set: `deny ... A scripts/d6.sh: matched by scripts/d6.sh in the Self-merge never: line of docs/dev-cycle.md`, `--merge` exit 2, main unmoved. E7 with `workflows/ scripts/d6.sh` (this repo's current glob plus the new one) gives the same deny. A branch changing the file gets `deny ... M docs/dev-cycle.md: one of the dev cycle's own files` under the image and HEAD alike. `docs/reviews/security-review-2026-11-05-d6-block-into-image.md:44` reads `**Severity:** Medium`.

**Evidence:** `docs/dev-cycle.md:11`, `docs/reviews/security-review-2026-11-05-d6-block-into-image.md:44`, FC2/probeB.log, FC2/probeD.log

---

## Claim 12a: Pre-mortem 5: "A lib that fails to load, or a `git_harden` that refuses the environment, is tried alone before the loop and named as such (review i1)"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:104`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a lib ending `return 1`, a syntax error, a lib with no `git_harden`, and `GIT_CONFIG_COUNT=010`; does not establish a lib that passes alone and then misbehaves (Claim 14a).

`scripts/d6.sh:51`: `( harden ) || no "$D6_OPT/scripts/lib/dev-cycle-read.sh did not load, or its git_harden refused this environment"`. E1 pins the first and last case; E4 cases o and p refuse the same way, rc=2.

**Evidence:** `scripts/d6.sh:37-38`, `scripts/d6.sh:51`, `test/scripts/build-loop-orchestrator.bats:344-347`, FC2/probeA.log

---

## Claim 12b: Pre-mortem 5: "so exit 1 in the loop can only be git's 'no such ref'."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:104`
**Type:** Error-handling
**Verdict:** Incorrect
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Same finding as Claim 14b, on git 2.39.5; does not establish other git versions.

The sentence repeats the comment at `scripts/d6.sh:50`; the evidence is in Claim 14b. The item's earlier text, cut from this version, said the line "can name the wrong cause", which remains true for a broken ref.

**Evidence:** `scripts/d6.sh:50-58`, FC2/probeA.log

---

## Claim 12c: Pre-mortem 5: "A test proves no pair reaches the script and every git call carries the pins."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:104`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two `show-ref` calls after the new `( harden )` line, which runs no git; does not establish all HARDEN pairs, as the test names three of seven plus three variables.

`test/scripts/build-loop-orchestrator.bats:368-377` asserts `count=unset` in the script, two logged calls, and `core.hooksPath=/dev/null core.fsmonitor=false core.useReplaceRefs=false G=/dev/null P=none S=1` on each. It passed in E1.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:368-377`, FC2/bats-head-d6.log

---

## Claim 13: d6.sh's header exits: "the script's own status; 2 and one 'refuse d6: WHY' line on stdout, with nothing run, for an image-copy file that is missing or not a regular file (a partial image), an image lib that does not load or whose git_harden refuses the caller's environment, a default branch that is not exactly one of main and master, or a git read that exits above 1 (git may add a line on stderr); 1 for another first argument."

**Location:** `scripts/d6.sh:19-24`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all five `no` sites and the usage exit; does not establish that stderr is empty on the lib refusal, since `git_harden` and bash add a line there too, nor a missing `env` at `:59`.

The five `no` calls at `:47`, `:48`, `:51`, `:55` and `:58` are the five named cases, and `:40` is the only `exit 1`. "Exits above 1" is now exact, for `[[ "$rc" -le 1 ]] || no "refs/heads/$n could not be read"` (`:55`): E4 cases f, h, i, j and l (a missing object, unreadable and junk `packed-refs`, a count with no key, no git on PATH) each gave rc=2 with that line. "Nothing run" means no script: the lib is sourced and git runs (paraphrased — no quote available because this is the reading of a phrase, confirmed by E1's `ran` marker case).

**Evidence:** `scripts/d6.sh:35-59`, FC2/probeA.log, FC2/bats-head-d6.log

---

## Claim 14a: "Tried alone first, so that exit 1 below" is not the lib's or git_harden's

**Location:** `scripts/d6.sh:50`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a lib that behaves the same on each load, which a read-only image lib does; does not establish a lib that changes between loads or exits 0 at top level, both of which refuse under the wrong cause.

`harden` reads only the lib and the environment, and d6.sh changes neither between `:51` and `:54`, so a lib that fails in `g` fails first at `:51` (paraphrased — no quote available because this is an argument from what the subshells share). Two contrived libs get past it (E4): a counter lib that passes once and then returns 1 (case n), and a top-level `exit 0` (case m). Both end `refuse d6: the default branch is not exactly one of main and master`, so nothing ran and only the cause is wrong.

**Evidence:** `scripts/d6.sh:37-38`, `scripts/d6.sh:50-54`, FC2/probeA.log

---

## Claim 14b: "exit 1 below can only be git's 'no such ref'."

**Location:** `scripts/d6.sh:50`
**Type:** Error-handling
**Verdict:** Incorrect
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `git show-ref --verify -q` on git 2.39.5 through HEAD's d6.sh; does not establish other git versions, and is no claim of a regression (the security review saw the old block do the same with a junk ref and a dangling symbolic ref).

`g show-ref --verify -q "refs/heads/$n"` (`:54`) exits 1, silently, for a ref that exists but cannot be resolved. Each row below is from E4:

| Case | Raw rc | d6.sh result |
|---|---|---|
| a. junk text in `refs/heads/main`, no master | 1 | rc=2, `refuse d6: the default branch is not exactly one of main and master` (the name exists, and the cause is not stated) |
| b. junk `main`, good `master` | 1 | runs the script; `--state` prints `ok` |
| c. good `main`, junk `master` | 1 | runs the script; `--state` prints `ok` |
| d. dangling symbolic `main`, good `master` | 1 | runs the script; `--state` prints `ok` |
| e. `chmod 000` on `main`'s ref file, good `master` | 1 | runs the script; `--state` prints `ok` |
| f. `main` at a missing object (for contrast) | 128 | rc=2, `refuse d6: refs/heads/main could not be read` |

So `:55`'s `could not be read` does not fire for these; they count as absent. The precise comment is that exit 1 below is git's "this name did not resolve": no such ref, or one `-q` could not read. Case e is a read failure that the header's "a git read" wording might suggest is refused; the header's "exits above 1" keeps it accurate (Claim 13). The practical effect is limited: a broken name beside a good one passes, and an honest broken default with no other name still refuses, under an imprecise cause.

**Evidence:** `scripts/d6.sh:50-58`, FC2/probeA.log, `docs/reviews/security-review-2026-11-05-d6-block-into-image.md:114`

---

## Claim 15: "d6.sh calls it in a subshell for its own git"

**Location:** `scripts/lib/dev-cycle-read.sh:311`
**Type:** Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers d6.sh's two subshell sites; does not establish that the pairs stay out of the script beyond Claim 12c's run.

`scripts/d6.sh:37-38`: `harden() { source "$D6_OPT/scripts/lib/dev-cycle-read.sh" && git_harden; }` and `g() { ( harden && git "$@" ); }`; `:51` calls `( harden )`. Both are subshells, each with a fresh lib, so the lib's second-call guard, `[[ -z "$CALLER_COUNT" ]] || return 0` (`scripts/lib/dev-cycle-read.sh:336`), never applies here.

**Evidence:** `scripts/d6.sh:37-38`, `scripts/d6.sh:51`, `scripts/lib/dev-cycle-read.sh:307-343`

---

## Claim 16: "`refuse d6: WHY` (exit 2; d6.sh's header lists them) or a usage line on stderr (exit 1, a first argument that is none of the three) means nothing ran."

**Location:** `skills/dev-cycle/SKILL.md:46-47`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers d6.sh's own refusals and its one usage line; does not establish that exit 1 alone means nothing ran, as a script that ran can also exit 1 (E4 case b, `questions.sh open`, rc=1 with its own stderr), which is why the sentence keys on the line.

The header lists all five refusals (Claim 13). The Rules' next sentences keep a script's exit 1 as "any other exit (1 included) ... means nothing was decided" (`:51-52`), so the two do not conflict. T36 pins the usage line exactly at `test/scripts/build-loop-orchestrator.bats:348`.

**Evidence:** `skills/dev-cycle/SKILL.md:45-53`, `test/scripts/build-loop-orchestrator.bats:348-349`, FC2/probeA.log, FC2/bats-head-d6.log

---

## Claim 17: "the exit 127 above means an image older than this skill, and a `refuse d6:` naming a missing image file a partial image: either entry also gives the release paste below"

**Location:** `skills/dev-cycle/SKILL.md:217-218`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both meanings and that a paste exists below; does not establish a paste for the "not a regular file" or lib refusals, which the sentence does not cover and which stop under the Rules alone.

An image older than the skill has no d6.sh, so it can only give 127 (E1, `test/scripts/build-loop-orchestrator.bats:291`); a `refuse d6:` line needs d6.sh in the image, whose payload then carries the other files, so a missing one is partial. The paste is at `:243-244`: `cd A && test "$(git rev-parse HEAD)" = M && ./devcontainer-config/install.sh`. The test pins the sentence at `test/scripts/build-loop-orchestrator.bats:301`, passing in E1.

**Evidence:** `skills/dev-cycle/SKILL.md:216-218`, `skills/dev-cycle/SKILL.md:243-244`, `test/scripts/build-loop-orchestrator.bats:291-304`, `test/scripts/build-loop-orchestrator.bats:400-404`, FC2/bats-head-d6.log

---

## Claim 18: "In its real place beside the scripts, where the stand-in can hold it."

**Location:** `test/scripts/build-loop-orchestrator.bats:253`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the uid-owned stand-in and the read-only `/opt`; does not establish behaviour under root, where `-w` is true of `/opt` too.

`D6="$BATS_TEST_TMPDIR/d6.bash"; [[ ! -w "$1/scripts" ]] || D6="$1/scripts/d6.sh"` (`:254`) puts the copy in a writable stand-in and leaves it in the temp dir for `/opt`, which E1's T37 run uses. The 127 test does not call `d6_copy`, so its stand-in still has no d6.sh (`:295`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:252-257`, `test/scripts/build-loop-orchestrator.bats:291-296`, FC2/bats-head-d6.log

---

## Claim 19: "A lib that does not load, or a git_harden that refuses, is named as that, never as an absent branch."

**Location:** `test/scripts/build-loop-orchestrator.bats:344`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test's two cases and E4's two more; does not establish "never" for a lib that passes alone first (Claim 14a).

`:346` appends `return 1` to the lib and `:347` sets `GIT_CONFIG_COUNT=010`; both compare `$output` to the full refusal line, and both passed in E1.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:344-347`, FC2/bats-head-d6.log, FC2/probeA.log

---

## Claims Requiring Attention

### Incorrect
- **Claim 12b** (`docs/working/research-2026-11-05-d6-block-into-image.md:104`): "can only be git's 'no such ref'" is false; change with Claim 14b.
- **Claim 14b** (`scripts/d6.sh:50`): `show-ref --verify -q` also exits 1 for a junk ref, a dangling symbolic ref and an unreadable ref file, which d6.sh counts as absent. Say so in the comment.

### Stale
- None.

### Mostly Accurate
- **Claim 6** (`docs/working/plan-build-loop-handoff.md:411`): T36 omits the lib-load refusal its test now pins.
- **Claim 7** (`docs/working/plan-build-loop-handoff.md:412`): T37 still says "the snippet" where T33 now says d6.sh.
- **Claim 9** (`docs/working/research-2026-11-05-d6-block-into-image.md:59`, `:118`): restoring from da07a77c leaves one test red against HEAD's SKILL.md until one phrase changes, and two lib comments false.
- **Claim 11b** (`docs/working/research-2026-11-05-d6-block-into-image.md:102`): the entry lists every changed path outside `docs/`, with `docs/` as a count.

### Unverifiable
- None.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to docs/reviews/code-fact-check-report-i2-2026-11-05-d6-block-into-image.md, per skills/code-fact-check/SKILL.md (read it and follow it), first line `Commit: <HEAD short sha>`, header `**Replication:** k=1 (loop pass, decision 031)`, every claim tagged Legibility-target, ending with a Goal-Alignment Note (patterns/orchestrated-review.md). Do not commit.
- Answered: yes; every named claim was checked and executed where it could be, and only the T37 line's post-release branch could not run.
- Out of scope: commits before 4dd68cdc except as context; hostile-author cases (S1); whether the broken-ref behaviour should change, which is a code question, not a fact-check one.
- Escalate: the comment at `scripts/d6.sh:50` and pre-mortem 5 (Claims 12b, 14b); option [2]'s missing step (Claim 9), before the owner answers that question.
- Decisions I made: kept probe logs in scratch, as i1 did, since the dispatch allowed no other edit; the alternative was `docs/reviews/execution-logs/`. Rated Claim 9 Mostly accurate because a one-phrase edit turns it green; the alternative was Incorrect for the red test.
