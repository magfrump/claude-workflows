Commit: 42414307

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u5`)
**Scope:** branch diff `git diff main...HEAD` on `feat/build-loop-u5` (12 files; docs, settings, questions, SKILL.md step 0.1, one test), checked against `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `scripts/dev-cycle.sh`, `scripts/health-check.sh`, `skills/dev-cycle/SKILL.md`, `docs/working/plan-build-loop-handoff.md`, `docs/reviews/override-log.md` and `/opt/claude-workflows`
**Checked:** 2026-10-14
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 42
**Summary:** 32 verified, 5 mostly accurate, 0 stale, 5 incorrect, 0 unverifiable

Execution logs (scratch dir, not committed): `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-i1/logs/` holds `settings-real.txt`, `settings-variants.txt` (script `../variants.sh`), `q156.txt`, `bats-real.txt`, `qcheck.txt`. Every run used `GIT_CONFIG_GLOBAL=/dev/null` and `timeout`; no process was left running.

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 5 patterns): no claim here matches a logged pattern, and no Incorrect below is a fabricated symbol, so the log is not updated.

---

## Claim 1: "D1: the orchestrator starts each loop itself (`build-loop.sh --start`/`--prompt`, a locked worktree, a background subagent with no isolation), caps a brief at 4 dispatches and stops a stalled loop."

**Location:** `docs/decisions/log.md:95`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the cap constant, the lock at dispatch, the skill's no-isolation subagent and the stall rule; does not establish the two-hour stall timing in practice or that a lost `Dispatched:` line cannot admit a fifth run (it can: SKILL.md step 10's own residual).

`scripts/build-loop.sh:1593` reads `DISPATCH_CAP=4; STEAL_AGE=7200`, and `dispatch()` refuses `elif [[ "${STATUS[dispatched]}" -ge "$DISPATCH_CAP" ]]` (`scripts/build-loop.sh:1635`); the worktree is added with `git worktree add -q --lock --reason "$reason"` (`scripts/build-loop.sh:1656`). SKILL.md step 10: "start one background subagent (Agent tool, no isolation)" (`skills/dev-cycle/SKILL.md:773-774`); step 7: "unless its TIP has not moved in two hours of iterations ... then stop its task by ID and file it as `stopped`, reason "stalled" (D1)" (`skills/dev-cycle/SKILL.md:567-568`).

**Evidence:** `scripts/build-loop.sh:1593`, `scripts/build-loop.sh:1626-1660`, `skills/dev-cycle/SKILL.md:566-570`, `skills/dev-cycle/SKILL.md:770-790`

---

## Claim 2: Row 72's D4–D14 summary (merge-/merge-gate- entry merged by `--merge --approved`; the floor; D6 image copy; D7 merge-tree/commit-tree/CAS; D9 default 3; D11 `--marker`; D13 `--state`, `--main-log`, `--land-cycle`; D14 scoped quiesce and a `flock` on the health check)

**Location:** `docs/decisions/log.md:95`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each named mechanism's existence in the script, lib, skill or health check; does not establish that "never checked out" excludes the fast-forward in a worktree W that has main checked out (it does run `merge --ff-only` there, as plan D7 also says).

`approval()` builds `s="merge-"` or `s="merge-gate-"` plus `${VERDICT[stem]}-${VERDICT[tip]:0:12}` (`scripts/build-loop.sh:1441-1443`); the usage line lists `--merge BRIEF --expect SHA [--approved Q-NNN]` and `--land-cycle --main SHA` (`scripts/build-loop.sh:12-14`). The health check wraps itself: `flock -n -E 75 -o "$lk" bash "$REPO_ROOT/scripts/health-check.sh"` (`scripts/health-check.sh:1155`). The `--merge` header: "a commit of TREE whose parents are main's commit and TIP" and "moves by compare-and-swap from the checked commit; checked out in a worktree W, by merge --ff-only in W" (`scripts/build-loop.sh:398-427`). The D6 block "always runs the root-owned image copy under D6_OPT" (`skills/dev-cycle/SKILL.md:197-199`). Slots default: `SLOTS_LINE='slots 3 default: ...'` (`scripts/build-loop.sh:822`).

**Evidence:** `scripts/build-loop.sh:6-17`, `scripts/build-loop.sh:393-427`, `scripts/build-loop.sh:1437-1455`, `scripts/health-check.sh:1134-1160`, `skills/dev-cycle/SKILL.md:26-31`, `skills/dev-cycle/SKILL.md:189-221`

---

## Claim 3: Row 72's D10 quotes ("start a cycle should be kick off a loop, not assumed stopping after one cycle"; "next loop should start autonomously; ..."; "then tasks deferred rather than blocking the loop")

**Location:** `docs/decisions/log.md:95`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the quoted text against the design-conversation doc; does not establish the 2026-10-03 date beyond that doc's own heading.

`docs/working/handoff-build-loop-handoff.md:30` reads `1. "start a cycle should be kick off a loop, not assumed stopping after one cycle"`, `:37` reads `8. "next loop should start autonomously; the point is to work through all threads until they are blocked on questions, all surfaced via questions.md"`, and `:38` reads `9. Loop questions are surfaced async to questions.md, "then tasks deferred rather than blocking the loop"`.

**Evidence:** `docs/working/handoff-build-loop-handoff.md:30-38`

---

## Claim 4: The new `docs/dev-cycle.md` reads as policy `review` (unset), slots 3 and never `workflows/`, and no prose line counts as a second copy

**Location:** `docs/dev-cycle.md:7-42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `--settings` on this exact file committed on main in a throwaway repo, and the same file with the policy flipped to `self-merge` (prose still not counted); does not establish the reading on the real repository's main (not merged yet) or against a future prose edit.

Command: `GIT_CONFIG_GLOBAL=/dev/null timeout 60 bash /workspace/.claude/wt-build-loop-u5/scripts/build-loop.sh --settings`, cwd `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-i1/repo` (a `git init -b main` repo with `docs/dev-cycle.md` copied and committed), 2026-10-15T04:16:38Z, exit 0. Output:

```
policy review unset: line 7 is not exactly "Build-loop policy: self-merge" or "Build-loop policy: review"
slots 3 set: line 9 of docs/dev-cycle.md on the default branch
never workflows/ set: line 11 of docs/dev-cycle.md on the default branch
```

With line 7 replaced by `Build-loop policy: self-merge` the policy reads `policy self-merge set: line 7` (variant `selfmerge-with-never`), so no prose line in the file is counted as a copy of any key. The copy counter folds each line to letters (`s = tolower($0); gsub(/[^a-z]/, "", s)`, `scripts/lib/dev-cycle-read.sh:623`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:618-634`, `scripts/build-loop.sh:785-826`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-i1/logs/settings-real.txt`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-i1/logs/settings-variants.txt`

---

## Claim 5: "A line counts only when it is the one line in the file, outside code blocks, that starts with its key; a trailing CR is ignored." / slots "From 1 to 9 (anything else, or no line, means 3)" / "`self-merge` also needs a valid never line (its `none` form for an empty list)" / "A malformed line turns self-merge off."

**Location:** `docs/dev-cycle.md:16-17`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers trailing CR, slots 0/9/10, a second slots copy in bold markup, a malformed and a missing never line under `self-merge`; does not establish copy detection for markup that adds letters (the header's own stated best-effort limit).

Command: `timeout 300 bash /home/node/.claude/jobs/00bcf178/tmp/u5/fc-i1/variants.sh` (cwd the throwaway repo; each variant committed then `--settings` run), 2026-10-15T04:17:24Z, every run exit 0. Results: `selfmerge-CR` → `policy self-merge set`; `selfmerge-malformed-never` → `policy review unset: line 7 reads self-merge, but there is no valid Self-merge never: line ... so self-merge is off`; `selfmerge-no-never` → same; `slots0`/`slots10` → `slots 3 default: line 9 is not exactly "Build-loop slots: N" with N from 1 to 9`; `slots9` → `slots 9 set`; a trailing `**Build-loop slots:** 4` → `slots 3 default: more than one line starts "Build-loop slots:" (lines 9 and 72)`. Code: `{ sub(/\r$/, "") }` (`scripts/lib/dev-cycle-read.sh:619`); `if [[ "$v" == self-merge && -z "$never_ok" ]]` (`scripts/build-loop.sh:818`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:618-634`, `scripts/build-loop.sh:800-825`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-i1/logs/settings-variants.txt`

---

## Claim 6: "The dev cycle's orchestrator reads the three lines above, and the two reader lines below, only through `scripts/build-loop.sh --settings`, from the default branch's commit, never from a working tree"

**Location:** `docs/dev-cycle.md:13-15`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers which code reads the lines and from where; does not establish the origin/HEAD redirect case of override row 548, in which dev-cycle.sh's reader read can follow a branch other than main.

The "from the default branch's commit" half holds: every read goes through `main_file`, which reads `git cat-file blob "$MAIN_SHA:$f"` (`scripts/lib/dev-cycle-read.sh:606`). The "only through `--settings`" half is narrower than the code: the scripts read the same lines on their own, outside `--settings`. `scripts/dev-cycle.sh:201` calls `reader_settings` (the reader lines, for `--check-fix`), and the gated modes run `reader_settings; read_settings; never_res; open_shared` (`scripts/build-loop.sh:1324`), so `--status`, `--check` and `--merge` take the policy and never globs from read_settings directly. The precise version: the orchestrator's own reading of these values goes only through `--settings`, and the scripts it runs read them through the same functions, always from main's commit.

**Evidence:** `scripts/lib/dev-cycle-read.sh:597-612`, `scripts/dev-cycle.sh:201`, `scripts/build-loop.sh:717`, `scripts/build-loop.sh:1324`, `scripts/build-loop.sh:2081-2106`

---

## Claim 7: Under `self-merge` a ready branch lands "only when every changed path is listed in the brief's `Paths:` line or is one of the loop's own files, and none is on the gate's fixed floor (instruction files and what they `@`-import, any dot path, the gate's own code, files later runs read as truth such as `docs/decisions/` and `docs/constraints.md`, symlinks and gitlinks) or matches the never line"

**Location:** `docs/dev-cycle.md:19-25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers srules' order and the floor's words; does not establish the import walk's completeness (F11's known gaps) and notes that symlinks and gitlinks are refused by the N rules (every policy), not by `floor()` itself.

`srules()` checks the floor first (`if [[ -z "$5" ]] && floor "$2" "$1" "$4" "$3"`), then each never regex, then `ownfile`, then each `Paths:` entry, and otherwise sets `DENY="neither listed in the brief's Paths: line nor one of its own files"` (`scripts/build-loop.sh:1206-1218`). `truthrule()` refuses `instr`, `dot` (`[[ "/$1" == */.* ]]`), `cycle`, `settings`, `user` (`docs/constraints.md`) and `record` (`^docs/(decisions|human-author)/`) (`scripts/lib/dev-cycle-read.sh:1916-1926`); `floor()` adds `elif [[ "$lp" =~ $GATE_CODE ]]; then FLOOR_WHY=gate` and the import walk (`scripts/lib/dev-cycle-read.sh:1997-2016`). The N rules deny "a mode other than 100644 or 100755 on either side (a symlink or gitlink)" (`scripts/build-loop.sh:357-358`), and the lib names this "floor item 5, symlinks and gitlinks, is the caller's mode rule" (`scripts/lib/dev-cycle-read.sh:1986-1987`).

**Evidence:** `scripts/build-loop.sh:1196-1219`, `scripts/build-loop.sh:354-392`, `scripts/lib/dev-cycle-read.sh:1904-2034`

---

## Claim 8: "A refused self-merge falls through to review."

**Location:** `docs/dev-cycle.md:25`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers SKILL.md step 7's handling of each `--merge` refusal class; does not establish the orchestrator's behaviour in practice.

Only a path refusal falls through. SKILL.md step 7: "A refusal of the paths ("K of N changed paths refused", `deny` lines following) falls through to review ... A conflict is `stopped`. Any other refusal (no identity, MAIN_WT's state, a moved main, a failed read) is the environment's, not the loop's: recorded, named in the final message, and tried again next iteration" (`skills/dev-cycle/SKILL.md:579-586`). The precise version: a self-merge refused for its paths falls through to review; a conflict is filed as stopped, and an environment refusal is retried.

**Evidence:** `skills/dev-cycle/SKILL.md:570-586`

---

## Claim 9: "Under `review`, the orchestrator files one merge entry (`merge-STEM-SHA12`, or `merge-gate-STEM-SHA12` when the change touches the gate's own code) holding `--check`'s output, and merges only on your `[1] merge`. A brief self-merges only when its own `Policy:` line also reads `self-merge`."

**Location:** `docs/dev-cycle.md:25-28`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the slug code, the step 7 entry body and the `--status` POLICY rule; does not establish that an answer of "merge" in words is read (it is not: step 7 reads it as `unrecognized`).

`approval()` requires `[[ "$ANSWER_HEADING" == "$1 · $s" ]]` with `s` built as `merge-` or `merge-gate-` plus STEM and the tip's 12 hex digits (`scripts/build-loop.sh:1441-1454`) and `case "$r" in "keep $1") ;;` (option 1). SKILL.md step 7: "On `ok`, one merge entry, heading `### Q-NNN · merge-STEM-SHA12` ... Its body: the full TIP (row 673), `--check`'s lines as printed" (`skills/dev-cycle/SKILL.md:587-593`). The `--status` header: "POLICY: self-merge only when --settings' policy is self-merge and the brief's first "Policy:" line is exactly "Policy: self-merge"" (`scripts/build-loop.sh:73-75`).

**Evidence:** `scripts/build-loop.sh:73-75`, `scripts/build-loop.sh:1435-1455`, `skills/dev-cycle/SKILL.md:587-596`, `skills/dev-cycle/SKILL.md:625-630`

---

## Claim 10: "Only a live dispatched loop holds a slot; a blocked, stopped or ready-for-review one does not."

**Location:** `docs/dev-cycle.md:32-34`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers SKILL.md steps 8 and 10's use of the slots value; does not establish behaviour across a session restart.

Step 10 fills "free slots (`--settings`' `slots` less the loops this session runs)" (`skills/dev-cycle/SKILL.md:766-767`), which matches the claim for dispatch. Step 8 also uses the slots value to cap brief writing, and there the count is wider than live loops: "while the queue is shorter than `--settings`' `slots` line ...: open briefs whose loop step 7 read as absent or working, plus those it sends back to a loop, each counted once (a blocked, stopped, capped or ready one, or a stalled one held, waits on the user and is not counted)" (`skills/dev-cycle/SKILL.md:645-649`). So a written but undispatched brief (`absent`), or a `working` one whose subagent has ended, counts against slots in step 8. The blocked/stopped/ready exclusions hold in both steps. The precise version: slots cap live loops at dispatch and the open, undispatched or working briefs the cycle writes; blocked, stopped and ready ones count in neither.

**Evidence:** `skills/dev-cycle/SKILL.md:642-650`, `skills/dev-cycle/SKILL.md:762-768`

---

## Claim 11: Never globs: "`*` and `?` match within one path part, a glob matches the path or any directory above it, and paths compare lower-cased."

**Location:** `docs/dev-cycle.md:35-37`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers never_res' regex construction and srules' lower-cased comparison; does not establish the glob form check (globform) beyond the malformed case run in Claim 5.

`never_res()` lowers each glob (`g="$(lower "${g%/}")"`), maps `'*') re+='[^/]*' ;; '?') re+='[^/]' ;; .) re+='\.'` and anchors it as `NEVER_RES+=("^$re(/|\$)")` (`scripts/build-loop.sh:1181-1192`); srules tests the lower-cased path `$3` against each (`scripts/build-loop.sh:1209-1211`).

**Evidence:** `scripts/build-loop.sh:1176-1192`, `scripts/build-loop.sh:1206-1211`

---

## Claim 12: "every later session in this repo reads the workflows from its own checkout, so a workflow change takes effect on merge, while scripts, skills, hooks and guides reach running sessions only through an image release you cut."

**Location:** `docs/dev-cycle.md:38-40`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the "scripts only through a release" half against SKILL.md step 1 and override row 682; does not establish which other repo paths (beyond `scripts/health-check.sh` and the test suites it runs) take effect on merge. The workflows half is consistent with plan D5.

The orchestrator runs a script from its own checkout every iteration. SKILL.md step 1: "Then run the repo's health check from WT, if it has one (e.g. `scripts/health-check.sh` in claude-workflows ...)" (`skills/dev-cycle/SKILL.md:379-380`), and WT is a worktree of main's commit. `scripts/health-check.sh` is neither GATE_CODE (`GATE_CODE='^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'`, `scripts/lib/dev-cycle-read.sh:1965`) nor on the floor. So a self-merge whose `Paths:` lists it, or a test file it runs, takes effect on merge, and the never line does not cover it. Override row 682 says exactly this: "`scripts/health-check.sh` (and the suites it runs) ... matches neither GATE_CODE nor the floor, so a self-merge whose Paths: lists it lands code the orchestrator runs next cycle with no review entry (... an exception to plan D5's "scripts reach sessions only through a release", like workflows/)". Its disposition was "Revisit trigger: U5's Q-103 re-route and its `Self-merge never:` entry for this repo (add scripts/health-check.sh and test/ there, or record the acceptance)" (`docs/reviews/override-log.md:682`). U5 does neither and repeats the claim the row refutes. Fix: add `scripts/health-check.sh test/` (and whatever it runs) to the interim never line, or name the exception here, in Q-149 and in Q-103.

**Evidence:** `skills/dev-cycle/SKILL.md:375-390`, `scripts/lib/dev-cycle-read.sh:1958-1965`, `scripts/lib/dev-cycle-read.sh:1997-2016`, `docs/reviews/override-log.md:682`

---

## Claim 13: "**Review handoff.** No line. The pull-request route the design names is not built, and this repo has no PRs, so every review merge is one questions entry."

**Location:** `docs/dev-cycle.md:41-42`
**Type:** Staleness / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every reader of the line in scripts/ and the dev-cycle skill; does not establish other projects' PR usage.

`rg -i 'review handoff' scripts/ skills/dev-cycle/` returns only `skills/dev-cycle/SKILL.md:595`: "(D4's `Review handoff: pull request` route is not built: every review brief gets a merge entry.)" (paraphrased — no quote available for the scripts because the claim covers absence of code: no matching grep results in `scripts/`).

**Evidence:** `skills/dev-cycle/SKILL.md:594-596`

---

## Claim 14: Roadmap Next item 5 placement and "Next holds at most five"

**Location:** `docs/roadmap.md:49`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the skill's Next cap and the item count after the change; does not establish ranking.

SKILL.md step 6's template: "**Next**: at most five items, ranked" (`skills/dev-cycle/SKILL.md:537`). The Next section now holds items `1.` to `5.` (paraphrased — no quote available because the claim is about the section's list structure, counted with awk over `docs/roadmap.md`).

**Evidence:** `skills/dev-cycle/SKILL.md:537`, `docs/roadmap.md:29-53`

---

## Claim 15: "step 4b names triggers, and its only named dimension is D2's constraints one."

**Location:** `docs/roadmap.md:66-67`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers step 4b's text; does not establish whether the never-line coverage check inside that dimension counts as a separate one (read here as part of it).

Step 4b: "Every deep audit covers one more dimension: whether the constraints and project guidance still match intent. It samples Path A records more widely ... and checks that `Self-merge never:` covers the paths that take effect on merge in this repo (F57)" (`skills/dev-cycle/SKILL.md:478-482`).

**Evidence:** `skills/dev-cycle/SKILL.md:464-482`

---

## Claim 16: "plan D13 built only `--main-log`'s check of what moved main; re-running the N and S rules over past gate merges is not built."

**Location:** `docs/roadmap.md:71-72`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the plan text and build-loop.sh's mode list; does not establish no other script re-runs the rules.

Plan D13: "Any `other` stops dispatch and files one `you: judgment` entry naming the commit (F43). This is the minimal part of roadmap item (d), moved into this unit." (`docs/working/plan-build-loop-handoff.md:103`); step 12 names "(d) the rest of "build-loop audit": re-running the N/S rules over past gate merges" (`docs/working/plan-build-loop-handoff.md:353`). The usage block lists no audit mode (`scripts/build-loop.sh:6-17`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:103`, `docs/working/plan-build-loop-handoff.md:353`, `scripts/build-loop.sh:6-17`

---

## Claim 17: Done entry: "Runs here only after the release (Q-156) and once `docs/constraints.md` exists (Q-155)"

**Location:** `docs/roadmap.md:120-124`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the dispatch gate on constraints and the image's missing D6 block; does not establish that no other step of the cycle runs before the release.

`dispatch()`: `if [[ "$CONSTRAINTS" != ok ]]; then x="no loop is dispatched until --settings reads the constraints as ok ..."` (`scripts/build-loop.sh:1633`); `git cat-file -e main:docs/constraints.md` fails ("path 'docs/constraints.md' does not exist in 'main'"). The image's skill still holds the placeholder "## The D6 block\n\nPending: Q-140 (the snippet's trust root)" (`/opt/claude-workflows/skills/dev-cycle/SKILL.md:199-201`).

**Evidence:** `scripts/build-loop.sh:1626-1640`, `/opt/claude-workflows/skills/dev-cycle/SKILL.md:199-207`

---

## Claim 18: "the decision-log row is 72, not 70 (rows 70 and 71 were taken after this plan was written; D10 and the seed's Status line name 72)"

**Location:** `docs/working/plan-build-loop-handoff.md:358`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the plan's D10 bullet and the seed's Status line; does not establish another reading of "D10" (row 72's own D10 clause does not name a row number either).

The seed's Status line does name 72: "**Status:** superseded by decision log row 72" (`docs/working/seed-build-loop-handoff.md:3`). The plan's D10 bullet, which the diff does not touch, still reads "It is recorded instead as decision-log row 70, quoting your answers 1, 5, 8 and 9" (`docs/working/plan-build-loop-handoff.md:91`). Fix: change D10's "row 70" to "row 72", or drop "D10 and" from the note.

**Evidence:** `docs/working/plan-build-loop-handoff.md:91`, `docs/working/seed-build-loop-handoff.md:3-4`

---

## Claim 19: The rest of the U5 as-built note (`Build-loop slots: 3`, `Self-merge never: workflows/`, no `Review handoff:` line; the entry IDs; step 0.1's listing; roadmap (f) to Next and (e) to Ideas; no pre-answered D10 entry)

**Location:** `docs/working/plan-build-loop-handoff.md:358`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each listed artifact's presence in the branch; does not establish the content claims verdicted separately (Claims 12, 25, 26).

`docs/dev-cycle.md:9` reads `Build-loop slots: 3` and `:11` `Self-merge never: workflows/`. The questions index lists Q-149 to Q-153, Q-155 and Q-156, and the archive index lists Q-154 (paraphrased — no quote available because the claim covers the index tables' rows, `docs/working/questions.md:28-40`). No entry pre-answers D10 (paraphrased — no quote available because the claim covers absence: no `D10` heading in either questions file).

**Evidence:** `docs/dev-cycle.md:7-11`, `docs/working/questions.md:25-53`, `docs/working/questions-archive.md:141`, `docs/roadmap.md:49-75`

---

## Claim 20: Q-154 filed answered: "a full cycle every iteration for now; move to a light pass of steps 7, 8 and 10 between full cycles once the costs are visible ... roadmap Next "Revisit the light pass" tracks it."

**Location:** `docs/working/questions-archive.md:2712-2726`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the answer against plan D12, the roadmap item and `questions.sh check`; does not establish the answer's original wording, which only the plan records.

Plan D12: "You answered on 2026-10-04: a full cycle every iteration for now, and a move to a light pass of steps 7, 8 and 10 between full cycles once the costs are visible. U5 files C5 as ANSWERED and adds a roadmap Next item" (`docs/working/plan-build-loop-handoff.md:96`). Roadmap: "5. **Revisit the light pass between full cycles (C5, Q-154).**" (`docs/roadmap.md:49`). Command `timeout 120 bash scripts/questions.sh check`, cwd `/workspace/.claude/wt-build-loop-u5`, 2026-10-15T04:24:29Z, exit 0, output `✓ questions: structure valid, indexes current`.

**Evidence:** `docs/working/plan-build-loop-handoff.md:93-96`, `docs/roadmap.md:49-53`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-i1/logs/qcheck.txt`

---

## Claim 21: Q-103's "What the gate can and cannot do" paragraph

**Location:** `docs/working/questions.md:91`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers agreement with the plan's section and the as-built D6; does not establish the threat model itself.

The plan: "Loops run as your uid, with a shell, in worktrees that share `/workspace/.git`. No script can contain a loop that turns hostile with its shell ... Each iteration checks that main moved only by the orchestrator's own merges, the gate's merges and answer-only commits (D13)" (`docs/working/plan-build-loop-handoff.md:33-35`). The entry's "the gate that runs is the root-owned image copy, which no loop can edit (D6, Q-140 [1])" matches the D6 block header's "always runs the root-owned image copy under D6_OPT by absolute path" (`skills/dev-cycle/SKILL.md:197-200`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:31-35`, `skills/dev-cycle/SKILL.md:197-206`

---

## Claim 22: F11: "Precondition: the walk reads the checkout, so the gate runs it in a clean checkout at `MAIN_SHA` (`checkout_gate` refuses anything else)." plus the known-issue A5 gap list

**Location:** `docs/working/questions.md:95`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers checkout_gate's existence and role for self-merge briefs and the gap list against plan F11; does not establish checkout_gate's individual checks (not re-read line by line here) and notes the walk runs only for self-merge briefs.

`checkout_gate() {` is defined at `scripts/build-loop.sh:1233`; the `--check` header: "for a brief --status reads as self-merge, "a self-merge brief needs --check run from a clean checkout of the default branch's commit; WHY" ... the checkout --check runs from (the self-merge floor reads it) has its HEAD at another commit" (`scripts/build-loop.sh:318-323`). Plan F11 lists "Gaps: known issue A5 (start files under a symlinked directory or in a submodule or untracked nested repo, case-insensitive names, checkout conversions ..., a prompt file read by a session started outside the top level ..., and instruction files outside the repo)" and "a Claude Code upgrade that changes its import grammar reopens this row" (`docs/working/plan-build-loop-handoff.md:126`).

**Evidence:** `scripts/build-loop.sh:318-345`, `scripts/build-loop.sh:1220-1240`, `docs/working/plan-build-loop-handoff.md:126`

---

## Claim 23: Residuals F19, F21, F29, F35, F58, F59 as stated in Q-103

**Location:** `docs/working/questions.md:96-102`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each bullet against its plan row and the `--merge` header's residual; does not establish the rows' own correctness.

Plan rows: F19 "A deliberate `git push` or a commit disguised as `answers` is not caught" (`:134`); F21 "Under self-merge the allowlist bounds what lands; under review you read the result. What a steered loop *does* outside git is bounded only by the sandbox" (`:136`); F35 "**not covered** | The prompt forbids each (T19); the subagent shares the orchestrator's permission mode" (`:153`); F58 "The release entry lists every commit and changed path since the image `.manifest` commit, flagging self-merged ones. Your release review is the gate" (`:176`); F59 "D2's drift check samples one Path A decision per sampled merge; a finding triggers the deep audit's constraints dimension" (`:177`). F29's residual matches the `--merge` header: "W switching to another branch at the same commit, between the checks and the move" (`scripts/build-loop.sh:450-452`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:134-177`, `scripts/build-loop.sh:428-453`

---

## Claim 24: F37: "Two chore branches can mint the same Q-ID; `questions.sh check` catches it when one lands."

**Location:** `docs/working/questions.md:100`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers where the land and the health check run `questions.sh check`; does not establish that `check` flags duplicate IDs (not executed against a duplicate).

The land runs `check` only before staging: "after `questions.sh index` and `check` in WT when this iteration filed or edited entries" (`skills/dev-cycle/SKILL.md:723-724`). When main moved, the remedy is "merge main in (below) and go back to 3" (`skills/dev-cycle/SKILL.md:749-750`), which skips step 1's `check`, so an ID clash made by that merge-in lands. The next iteration's health check runs `"$REPO_ROOT/scripts/questions.sh" check` (`scripts/health-check.sh:1125`). The precise version: caught by the land's check when the clash is visible before the merge-in, else by the next health check.

**Evidence:** `skills/dev-cycle/SKILL.md:722-760`, `scripts/health-check.sh:1115-1130`, `docs/working/plan-build-loop-handoff.md:155`

---

## Claim 25: "**R8, racing the gate's temp files.** A same-uid writer can race the gate's GATE_TMP between its writes and its reads: `git/config`, `git/info/`, `git/refs/`, `git/HEAD`, `work/.gitattributes`, `err` and `diff` (override row 509)."

**Location:** `docs/working/questions.md:103`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the surface list against override rows 509 and 684 and approval()'s use of `$GATE_TMP/answer`; does not establish whether further GATE_TMP files written after U3a3 (`msg`, `want`, `add`) also belong on it.

The list matches row 509 ("Surface: `$GATE_TMP/git/config`, `git/info/`, `work/.gitattributes`, and from U2b1b `err` and `diff` ... the surface also holds `git/refs/` and `git/HEAD`", `docs/reviews/override-log.md:509`). It leaves out the file that holds the merge authorisation. `approval()` runs `check_answer "$1" > "$GATE_TMP/answer"; r="$(< "$GATE_TMP/answer")"` (`scripts/build-loop.sh:1445`), and override row 684 routes that race here: "Revisit trigger: U5's Q-103 re-route, which adds `answer` to row 509's surface list" (`docs/reviews/override-log.md:684`). A reader deciding Q-103 is told the racable files do not include the authorisation. Fix: add `answer` (row 684) to the list, and check `msg`/`want`/`add`.

**Evidence:** `scripts/build-loop.sh:1441-1455`, `scripts/build-loop.sh:1553`, `scripts/build-loop.sh:1775`, `docs/reviews/override-log.md:509`, `docs/reviews/override-log.md:684`

---

## Claim 26: "**Also routed here during the build:** a loop editing the worktree registry in the shared common dir (U2b3a); objects re-hashed once per run ... (U3a1); a planted `core.bare` with the index deleted (U3a2, Low); a same-uid shell's PATH, exported functions or settings around the D6 block (U4c)."

**Location:** `docs/working/questions.md:104`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers override-log rows whose disposition or revisit trigger names Q-103 or "U5's Q-103 list/re-route", and SKILL.md's own "Q-103 residual" mentions; does not establish which of them the author meant to merge into a listed family, or whether row 775 was discharged by U4c (questions.sh now runs through the D6 block).

The four items listed do appear in the log (rows 638/646, 671 and the U4c rows). The list reads as the complete set, and it is not: these rows also name Q-103 or U5's Q-103 list and are absent:
- row 548, "Defer (Q-103 residual)": dev-cycle.sh runs no state or default gate, so an origin/HEAD redirect makes reader_settings read a loop's branch;
- row 668: a hand-edited rebase todo, "Revisit trigger: Q-103's re-route (U5)";
- row 682: health-check.sh and test/ self-mergeable and run each cycle (Claim 12);
- row 749: the orchestrator's commit runs the common dir's hooks ("Q-103 class");
- row 750: a swapped FIFO hangs the health-check lock ("Q-103 class");
- row 784: a main rewritten to a history with no record bootstraps again ("Revisit trigger: ... or Q-103's list");
- row 786: a lost `Dispatched:` line admits one more run past the cap ("Revisit trigger: U5's Q-103 list");
- rows 787, 797, 801 and 802: `--steal` of another session's loop, merge entries flagging floor paths only by class, `--start` reading main after `--main-log`, and `--answered` accepting any ID. Each has "Revisit trigger: ... or U5's Q-103 list".

SKILL.md itself calls two of these Q-103 residuals: step 0.2, "across sessions nothing anchors this, a Q-103 residual" (`skills/dev-cycle/SKILL.md:319-321`), and step 10, "one more loop run under the cap (a Q-103 residual)" (`skills/dev-cycle/SKILL.md:793-795`) (rows paraphrased from `docs/reviews/override-log.md` — no quote available for each because the rows are 800-1500 characters wide; the revisit-trigger phrases above are quoted). Fix: list them, or point to the override-log rows that name Q-103.

**Evidence:** `docs/reviews/override-log.md:548`, `docs/reviews/override-log.md:668`, `docs/reviews/override-log.md:682`, `docs/reviews/override-log.md:749-750`, `docs/reviews/override-log.md:784-802`, `skills/dev-cycle/SKILL.md:311-321`, `skills/dev-cycle/SKILL.md:790-795`

---

## Claim 27: Q-103 Interim: "`Build-loop policy: review (interim; Q-103)`, which `--settings` reads as unset, which means `review`."

**Location:** `docs/working/questions.md:111`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `--settings` on the branch's file in a throwaway repo; does not establish the reading on the real main.

Same run as Claim 4 (2026-10-15T04:16:38Z, exit 0): `policy review unset: line 7 is not exactly "Build-loop policy: self-merge" or "Build-loop policy: review"`.

**Evidence:** `scripts/build-loop.sh:814-821`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-i1/logs/settings-real.txt`

---

## Claim 28: Q-149: "Scripts, skills, hooks and guides reach running sessions here only through an image release you cut. Workflows are the exception"

**Location:** `docs/working/questions.md:356`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Same evidence as Claim 12; does not establish the full set of take-effect-on-merge paths.

The orchestrator runs `scripts/health-check.sh` (and the suites it runs) from its own worktree of main each iteration: "Then run the repo's health check from WT, if it has one (e.g. `scripts/health-check.sh` in claude-workflows" (`skills/dev-cycle/SKILL.md:379-380`). Override row 682 names it "an exception to plan D5's "scripts reach sessions only through a release", like workflows/" and asks this entry to add it or record the acceptance (`docs/reviews/override-log.md:682`). As written, the options table offers keep or drop for `workflows/` alone, so the user is not shown the second exception.

**Evidence:** `skills/dev-cycle/SKILL.md:379-387`, `docs/reviews/override-log.md:682`

---

## Claim 29: Q-150 [1]: "the orchestrator files its question as an entry, the body quoted line by line (`--marker`)"

**Location:** `docs/working/questions.md:375`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `--marker`'s documented output and step 7's use; does not establish the refusal rules' completeness.

The header: "Then the body ... scrubbed as all output is, each line prefixed "> " (an empty one ">"); at most 100 lines of 300 bytes" (`scripts/build-loop.sh:101-106`); step 7 puts "`--marker`'s lines verbatim" into the entry (`skills/dev-cycle/SKILL.md:609`).

**Evidence:** `scripts/build-loop.sh:97-124`, `skills/dev-cycle/SKILL.md:598-612`

---

## Claim 30: Q-151 [1]: "Only a live loop holds a slot; a blocked item re-enters the queue on its existing branch once answered, ahead of new briefs"

**Location:** `docs/working/questions.md:390`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers dispatch order and the slot count at dispatch; does not establish step 8's wider queue count (Claim 10).

Step 10: "Fill free slots (`--settings`' `slots` less the loops this session runs), briefs step 7 sends back first, then absent ones" and "any other: `--prompt BRIEF --steal`" (`skills/dev-cycle/SKILL.md:766-770`); step 7: "A blocked entry, answered ...: step 10 re-dispatches the brief" (`skills/dev-cycle/SKILL.md:622-623`).

**Evidence:** `skills/dev-cycle/SKILL.md:620-630`, `skills/dev-cycle/SKILL.md:762-772`

---

## Claim 31: Q-152 [1]: "It wakes every 1200–1800 s and runs a full cycle only when main moved past its last land (a committed answer moves it), a retry's wait ran out or you wrote; otherwise the wakeup does nothing"

**Location:** `docs/working/questions.md:405`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the wait paragraph's no-loop branch; does not establish the with-loop branch (1800 s fallback), which the option does not describe.

"with none, every 1200-1800 s, and only when the default branch moved past this iteration's last land (the NEW it printed), a retry's wait ran out, or the user wrote, run a full iteration (an answer lands as a move of main); otherwise the wakeup does nothing" (`skills/dev-cycle/SKILL.md:805-809`).

**Evidence:** `skills/dev-cycle/SKILL.md:804-809`

---

## Claim 32: Q-153: global instructions forbid it today ("deleting branches" needs approval in every mode)

**Location:** `docs/working/questions.md:415`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the installed global CLAUDE.md; does not establish other projects' instructions.

Global CLAUDE.md, /away section: "**Still require user approval (regardless of mode):** - Force-push, `git reset --hard`, deleting branches, dropping database tables" (`/home/node/.claude/CLAUDE.md`, "Operating Modes" section; paraphrased line reference — no line number given because the file is the image's symlinked copy, read as session context, not from the repo).

**Evidence:** `/home/node/.claude/CLAUDE.md`, `docs/working/handoff-build-loop-handoff.md:95`

---

## Claim 33: Q-155 Interim: "`--settings` prints `constraints missing`, and step 10 files nothing more while this entry is open."

**Location:** `docs/working/questions.md:446`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `--settings` with no constraints doc and step 10's "unless an open one does"; does not establish that the orchestrator recognises Q-155 as that open entry (it rests on its reading of the entry, not a slug).

The Claim 4 run printed `constraints missing: no docs/constraints.md on the default branch`, and main has no such file (`git cat-file -e main:docs/constraints.md` fails). Step 10: "while `--settings` prints `constraints ok` (else one `you: judgment` entry asking for `docs/constraints.md`, unless an open one does: D2)" (`skills/dev-cycle/SKILL.md:765-766`).

**Evidence:** `scripts/build-loop.sh:827-831`, `skills/dev-cycle/SKILL.md:764-766`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-i1/logs/settings-real.txt`

---

## Claim 34: Q-156: C is `8d0e660e…` on main's first-parent history; the gate code changed; the eleven first-parent commits (none a `(build-loop self-merge)`); the 28 paths outside `docs/`; "about 500 paths under `docs/` besides, nearly all `docs/reviews/`"

**Location:** `docs/working/questions.md:456-475`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the lists against C..main and C..HEAD as of the run; does not establish the list once main moves or after the U5 merge (the entry says step 0.1 rewrites it).

`/opt/claude-workflows/.manifest` reads `commit=8d0e660e2e5a9769200500ac3dcfb4b113a32589` and `assembled_from=/home/magfrump/claude-workflows`. Commands, cwd `/workspace/.claude/wt-build-loop-u5`, 2026-10-15T04:19:12Z, all exit 0: `git log --first-parent --format='%h %s' 8d0e660e..main` printed exactly the eleven listed commits (308196e7 … b279a2ba), none ending `(build-loop self-merge)`; `git diff --name-status 8d0e660e HEAD -- . ':!docs/'` printed the 28 listed paths (`test/lib/d6-snippet.bash` as `D`); the GATE_CODE diff printed `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `skills/dev-cycle/SKILL.md`; `docs/` counted 501 paths, 490 under `docs/reviews/`; `git rev-list --first-parent main | grep -c 8d0e660e…` printed 1; main was `b279a2ba2a8f…`.

**Evidence:** `/opt/claude-workflows/.manifest`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-i1/logs/q156.txt`

---

## Claim 35: Q-156: "The image's dev-cycle skill lacks the D6 block (U4c), so the orchestrator loop cannot run as written until this release."

**Location:** `docs/working/questions.md:456`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the installed skill's D6 section; does not establish which other image scripts lag.

`/opt/claude-workflows/skills/dev-cycle/SKILL.md:199-202`: "## The D6 block\n\nPending: Q-140 (the snippet's trust root). Its canonical copy is `test/lib/d6-snippet.bash` in claude-workflows; once Q-140 is answered, that file goes here" (excerpt ends :202; the section continues to :207 — read).

**Evidence:** `/opt/claude-workflows/skills/dev-cycle/SKILL.md:199-207`

---

## Claim 36: Q-156's paste: `cd /home/magfrump/claude-workflows && test "$(git rev-parse HEAD)" = "$(git rev-parse refs/heads/main)" && ./devcontainer-config/install.sh`

**Location:** `docs/working/questions.md:480`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the only git calls before install.sh's state gate are `rev-parse` (step 0.1's safety condition) and that install.sh gates before its other git calls; does not establish that the host checkout holds the U5 merge (the test binds HEAD to the host's main, not to M; the entry and commit 2846f9fa say so).

Both git calls are `rev-parse`, the class step 0.1 names: "the paste's only git call before install.sh's state gate is `rev-parse`, which runs no hook or fsmonitor" (`skills/dev-cycle/SKILL.md:304-306`). install.sh calls `git_state_gate   # before any other git call on the checkout (review R1)` (`devcontainer-config/install.sh:332`). Unlike step 0.1's form (`= M`), it compares with `refs/heads/main` (paraphrased — no quote available because the claim is the difference between two command strings already quoted above).

**Evidence:** `skills/dev-cycle/SKILL.md:303-307`, `devcontainer-config/install.sh:178-220`, `devcontainer-config/install.sh:332`

---

## Claim 37: Research corrections: "`/opt/claude-workflows/scripts/build-loop.sh` is in the image now (its `.manifest` commit was 8d0e660e on 2026-10-14), and since Q-140 [1] the D6 block always runs that root-owned image copy, in this repo too" / "the cycle does spawn loops itself, as background subagents with no isolation, in a worktree `build-loop.sh --start` creates (plan D1)"

**Location:** `docs/working/research-build-loop-handoff.md:23`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the image listing, the manifest, the D6 header and step 10; does not establish the second correction's "in a worktree `--start` creates" for re-dispatches (`--prompt` reuses the existing worktree).

`ls /opt/claude-workflows/scripts` lists `build-loop.sh`; `git show -s 8d0e660e` dates it `2026-10-14 00:12:07 -0700`; the D6 header: "always runs the root-owned image copy under D6_OPT by absolute path, never main's copy" (`skills/dev-cycle/SKILL.md:197-200`); step 10: "start one background subagent (Agent tool, no isolation)" (`skills/dev-cycle/SKILL.md:773-774`). The second correction is at `docs/working/research-build-loop-handoff.md:59`.

**Evidence:** `docs/working/research-build-loop-handoff.md:23`, `docs/working/research-build-loop-handoff.md:59`, `skills/dev-cycle/SKILL.md:197-200`, `skills/dev-cycle/SKILL.md:770-776`

---

## Claim 38: Seed Status: "superseded by decision log row 72 (the build-loop handoff as built, merged with `feat/build-loop-u5`; plan `docs/working/plan-build-loop-handoff.md`)"

**Location:** `docs/working/seed-build-loop-handoff.md:3-4`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers row 72's existence and its "Supersedes the seed"; does not establish the merge, which has not happened yet.

Row 72 ends its rationale with "Built as stacked units U0a–U5 under the row-62 cap. Supersedes the seed." (`docs/decisions/log.md:95`).

**Evidence:** `docs/decisions/log.md:95`

---

## Claim 39: SKILL.md step 0.1: the `image-lag` entry "is also the release entry ... every first-parent commit after C as a list item (`hg -C MAIN_WT log --first-parent --format='%h %s' C..M`; flag a subject ending `(build-loop self-merge)`, which no one reviewed), every path changed from C to M outside `docs/` (the image carries none of `docs/`: give its count)"

**Location:** `skills/dev-cycle/SKILL.md:298-303`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the self-merge subject against gate_msg and the image's top-level contents; does not establish that an approved merge (subject `(build-loop approved merge)`) needs no flag (it was reviewed through its entry, so leaving it unflagged is consistent).

`gate_msg()`: `printf "Merge branch '%s' (build-loop %s)\n\nBuild-loop-gate: %s\n" "$1" "$2" "$3"`, with WHAT `self-merge` or `approved merge` (`scripts/build-loop.sh:1463-1466`). `ls /opt/claude-workflows/` lists `CLAUDE.md guides hooks patterns scripts skills workflows` and no `docs` (`ls /opt/claude-workflows/docs`: "No such file or directory").

**Evidence:** `scripts/build-loop.sh:1457-1466`, `/opt/claude-workflows/`

---

## Claim 40: The real-settings test asserts the new never and slots lines

**Location:** `test/scripts/build-loop-read.bats:79-81`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers this one test on the branch's file; does not establish the rest of the suite (not run).

Command `TMPDIR=/home/node/.claude/jobs/00bcf178/tmp/u5/fc-i1 timeout 300 bats -f "this repo's own docs/dev-cycle.md" test/scripts/build-loop-read.bats`, cwd `/workspace/.claude/wt-build-loop-u5`, 2026-10-15T04:23:22Z, exit 0: `ok 1 --settings on this repo's own docs/dev-cycle.md: review, unset by the interim note (T3, G19)`. Asserted: `[[ "$(line never)" == "never workflows/ set: line "*" of docs/dev-cycle.md on the default branch" ]]` (`test/scripts/build-loop-read.bats:80`).

**Evidence:** `test/scripts/build-loop-read.bats:71-82`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-i1/logs/bats-real.txt`

---

## Claim 41: Onboarding step 13: self-merge "covers only paths a brief lists that are outside what takes effect on merge with no later review, such as instruction files, dot paths and the gate's own code, plus any the project adds to `Self-merge never:`" / "the dev cycle dispatches no build loop in a repo without one that holds a hard constraint"

**Location:** `workflows/codebase-onboarding.md:453-455`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the constraints gate's direction (no doc or no hard constraint → no dispatch) and the self-merge description at the stated level; does not establish the converse (a doc with a hard constraint can still read `unreadable`, e.g. one lacking its `success:` line, and also stops dispatch).

`read_settings`: `ok) if [[ "$c" -gt 0 ]]; then CONSTRAINTS_LINE="constraints ok ..." else CONSTRAINTS_LINE="constraints none-hard: ..."` (`scripts/build-loop.sh:834-836`), and `dispatch()` refuses unless `$CONSTRAINTS` is `ok` (`scripts/build-loop.sh:1633`). The roadmap item it names exists: "**A process for writing a repo's constraints doc**" (`docs/roadmap.md:59`).

**Evidence:** `scripts/build-loop.sh:827-842`, `scripts/build-loop.sh:1633`, `docs/roadmap.md:59-61`

---

## Claim 42: Commit messages main..HEAD (92fa6e52, 2846f9fa, 42414307)

**Location:** `git log main..HEAD` (92fa6e52, 2846f9fa, 42414307)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers each message's file and content claims against its own diff; does not establish the "IDs from next-id on main b279a2ba" provenance beyond the IDs being above Q-148.

The file lists and descriptions match each commit's `--stat`: 92fa6e52 touches the seven files it names; rows 70 and 71 exist on main; "No `Review handoff:` line, since nothing reads one" matches Claim 13. 2846f9fa: "(f) is Next 5, the rest Ideas (Next holds at most five)" matches Claim 14, and "Next would hold six" holds (four items before, plus (f)). One part inherits Claim 26: 2846f9fa's "plus the residuals earlier units routed to it" says Q-103 carries those residuals, and it carries four of at least fourteen. 42414307's "The plan records how U5 was built where it differs" inherits Claim 18's D10 slip.

**Evidence:** `docs/decisions/log.md:93-95`, `docs/roadmap.md:29-75`, `docs/working/questions.md:104`

---

## Claims Requiring Attention

### Incorrect
- **Claim 12** (`docs/dev-cycle.md:38-40`): says scripts reach sessions only through a release, but `scripts/health-check.sh` and the tests it runs execute from the orchestrator's worktree every iteration and are self-mergeable (override row 682 asked U5 to add them to the never line or record acceptance).
- **Claim 18** (`docs/working/plan-build-loop-handoff.md:358`): says D10 names row 72; the plan's D10 bullet (`:91`) still says row 70.
- **Claim 25** (`docs/working/questions.md:103`): R8's surface list omits `$GATE_TMP/answer`, the file that holds the merge authorisation, which override row 684 routed to this re-route.
- **Claim 26** (`docs/working/questions.md:104`): the "also routed here" list holds 4 items; override rows 548, 668, 682, 749, 750, 784, 786, 787, 797, 801 and 802 also route to Q-103 or "U5's Q-103 list", and SKILL.md steps 0.2 and 10 call two of them Q-103 residuals.
- **Claim 28** (`docs/working/questions.md:356`): Q-149 makes Claim 12's claim and offers keep/drop for `workflows/` alone, hiding the health-check exception.

### Stale
- none

### Mostly Accurate
- **Claim 6** (`docs/dev-cycle.md:13-15`): the scripts' gated modes and dev-cycle.sh also read these lines themselves (read_settings, reader_settings), always from main; "only through `--settings`" holds only for the orchestrator's own reads.
- **Claim 8** (`docs/dev-cycle.md:25`): only a path refusal falls through to review; a conflict is filed as stopped and an environment refusal is retried.
- **Claim 10** (`docs/dev-cycle.md:32-34`): step 8 also counts absent (undispatched) and working briefs against slots when writing briefs.
- **Claim 24** (`docs/working/questions.md:100`): after a merge-in of main the land skips step 1's `questions.sh check`; the next health check is what catches a clash then.
- **Claim 42** (commit 2846f9fa): "plus the residuals earlier units routed to it" inherits Claim 26's incompleteness.

### Unverifiable
- none

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u5/docs/reviews/code-fact-check-report-2026-10-14-u5-i1.md, structured per the code-fact-check skill, first line `Commit: 42414307`, header carrying `**Replication:** k=1 (loop pass, decision 031)`.
- Answered: yes. All 12 focus areas checked; `--settings` claims executed in a throwaway repo; Q-156's lists re-derived; the real-settings test and `questions.sh check` run.
- Out of scope: the full bats suites and health check (only the one changed test was run); judging the residuals themselves (only whether Q-103 lists them).
- Escalate: Claims 12/28 (health-check.sh and test/ take effect on merge but are missing from the never line and from Q-149), and Claims 25/26 (Q-103's residual list is incomplete against the override log). The user decides Q-103 and Q-149 from these entries, so both gaps bear on U5's goal of docs that match the built code.
- Decisions I made: read "D10 and the seed's Status line name 72" as the plan's D10 bullet; treated Q-103's "Also routed here" as an exhaustive list, since the entry gives no "e.g." or pointer to the log; counted symlinks and gitlinks under the "floor" wording as accurate, since the lib calls the N rules' mode check floor item 5.
