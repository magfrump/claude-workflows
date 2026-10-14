# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u4c`)
**Scope:** full branch `git diff main...feat/build-loop-u4c` (authored files: `skills/dev-cycle/SKILL.md`, `test/scripts/build-loop-orchestrator.bats`, `docs/working/plan-build-loop-handoff.md`, `docs/reviews/override-log.md`, `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md`, `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, the deleted `test/lib/d6-snippet.bash`) plus the four commit messages of `git log main..HEAD`. The i1/i2 critic reports and logs are evidence, not checked line by line. This is the final confirming pass, replicate r1 of k=3.
**Commit:** 43b8d7ed
**Replication:** k=3 (final confirming pass, merged most-severe-wins); this is r1
**Checked:** 2026-10-13
**Total claims checked:** 37
**Summary:** 27 verified, 6 mostly accurate, 1 stale, 2 incorrect, 1 unverifiable

I read `docs/reviews/hallucination-patterns.md` first. No claim below matches a logged pattern. Neither Incorrect verdict is a fabrication: one is a behaviour that changed in the same commit (Claim 4), the other a row mis-citation already on record (Claim 30b). So the log is unchanged.

Prior decided items (rubric B1-B5, C1-C11, D1-D9; override rows 812-819) are not filed again. The exceptions are where the code at 43b8d7ed changes their basis, and each one says so: Claim 4 (D9 / row 819), Claims 7 and 16 ("built from main", whose basis D1 changed).

Execution logs, all under `docs/reviews/execution-logs/`:
- `u4c-final-r1-orchestrator-bats.log`: the command was `timeout 300 bats test/scripts/build-loop-orchestrator.bats`. It ran in `/workspace/.claude/wt-build-loop-u4c`, finished at 2026-10-13T23:37:01-07:00 and exited 0, with 26/26 ok and no skips (test 15, the real `/opt` run, ran).
- `u4c-final-r1-step01.log`: step 0.1's commands run read-only against MAIN_WT=/workspace with the Rules' `hg`, the real `/opt/claude-workflows/.manifest`, 2026-10-13T23:36:20-07:00 and 23:40:38-07:00. Each command's exit code is in the log.
- `u4c-final-r1-d6-real.log`: the real, unstubbed D6 block (extracted from SKILL.md by T33's own awk) run against the real `/opt/claude-workflows` in a throwaway repo in the session scratchpad, 2026-10-13T23:39:46-07:00. Each command's exit code is in the log.
- `u4c-final-r1-pin-mutation.log`: the pin test's three assertions run with a widened GATE_CODE, 2026-10-13T23:38:45-07:00, exit 0.

---

## Claim 1: Rubric header "Commit: f2cc21e6" and its "## Status" section

**Location:** `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:1`, `:84-86`
**Type:** Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** the merge reviewer and the next session reading the rubric as the loop's record
**Scope:** Covers whether the header commit and the Status section describe the rubric as it stands at 43b8d7ed. It does not establish the correctness of any individual row.

The rubric was last edited in 43b8d7ed (`git log main..HEAD -- <rubric>` lists 43b8d7ed, f2cc21e6 and 33ad1767). That commit added the iteration-2 critic paragraph and the D1-D9 table, whose "Fixed" statuses describe 43b8d7ed's changes. The header still reads `Commit: f2cc21e6` (`:1`). The Status section covers iteration 1 only: `Iteration 1 found no 🔴 and five 🟡, fixed in 33ad1767 (B2's commit-message half an Accepted-immutable row). Health check passed at 1bc823ea` (`:86`). It says nothing about iteration 2's outcome or the fix commit 43b8d7ed.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:1`, `:66-82`, `:84-86`; `git diff f2cc21e6 43b8d7ed -- docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md`

---

## Claim 2: Rubric iteration-2 critic tallies

**Location:** `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:66-70`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** the merge reviewer weighing the critics' severities
**Scope:** Covers the severity counts quoted for the three i2 critic reports against their Summary Tables. It does not establish the findings' content.

Security: `1 Medium, 1 Low, 2 Informational` matches the table (`security-review-2026-10-13-u4c-i2.md`, Summary Table: rows 1 Medium, 2 Low, 3 and 4 Informational). Api-consistency: `3 Inconsistent, 2 Minor, 1 Informational` matches (F1-F3 Inconsistent, F4-F5 Minor, F6 Informational). Architecture is quoted as `2 Coupling, 2 Minor`, but its table also has `| 5 | i1 finding 1 ... resolved | Informational |` (`architecture-review-2026-10-13-u4c-i2.md`, Summary Table). A precise version reads "2 Coupling, 2 Minor, 1 Informational".

**Evidence:** `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:66-70`; Summary Tables of `docs/reviews/{security,api-consistency,architecture}-review-2026-10-13-u4c-i2.md`

---

## Claim 3: Rubric D1-D7 "Fixed" statuses

**Location:** `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:74-80`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** the merge reviewer confirming each 🟡-grade item landed
**Scope:** Covers that the text each status names exists in SKILL.md, the plan and the tests at 43b8d7ed. It does not establish that the pin test (D2) blocks every drift, which Claim 29 covers.

- D1: SKILL.md has `if hg -C MAIN_WT merge-base --is-ancestor C M exits 1, the gate that runs was built off main: file one you: judgment entry image-off-main` and the paste `` cd A && test "$(git rev-parse HEAD)" = M && ./devcontainer-config/install.sh `` (`skills/dev-cycle/SKILL.md:288-296`).
- D2: the paths sit on one line, `` `scripts/build-loop.sh scripts/dev-cycle.sh scripts/questions.sh scripts/lib/ skills/dev-cycle/` `` (`:292`), and a new test reads that line (`test/scripts/build-loop-orchestrator.bats:347-354`).
- D3: the entry holds `C, M, the changed names (the same diff with --name-only) and the paste ..., interim: the image's gate runs. Exit 0: an open image-lag entry is answered done` (`:293-298`). Plan `:356` joins U5's release entry to it.
- D4: "differs" replaces "older", and a failed `cat-file` is now `skip silently` (`:287-288`).
- D5: `a refuse d6: naming a missing image file means an image older than this skill: its entry also gives the release paste below` (`:283-284`).
- D6: the Rule reads `no repository file or state a build loop writes` (`:42`).
- D7: `(check exiting 1 names entries to fix before staging)` (`:713`).

**Evidence:** `skills/dev-cycle/SKILL.md:42`, `:283-299`, `:712-713`; `test/scripts/build-loop-orchestrator.bats:347-354`; `docs/working/plan-build-loop-handoff.md:356`

---

## Claim 4: "deleting C's objects drops the check to a record note" (rubric D9) / "deleting C's objects turns the check into a record note" (override row 819)

**Location:** `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:82`; `docs/reviews/override-log.md:819`
**Type:** Behavioral / Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** the user reading a Won't-Fix row's rationale; a later reviewer deciding whether the bypass is visible
**Scope:** Covers what step 0.1 at 43b8d7ed does when the image's commit object C is absent from MAIN_WT. It does not establish the partial-deletion case (C's commit present, a tree or blob gone), where the diff fails and the "any other exit: note it" branch does apply.

This basis changed in the same commit that wrote the row. At f2cc21e6, step 0.1 read `when hg -C MAIN_WT cat-file -e 'C^{commit}' succeeds ... No .manifest, no commit= line or any other exit: note it in the record` (`git show f2cc21e6:skills/dev-cycle/SKILL.md:284-290`). Under that text a failed `cat-file` was a record note. 43b8d7ed (rubric D4) changed it to:

```
// skills/dev-cycle/SKILL.md:287-288
M main's commit. If `hg -C MAIN_WT cat-file -e 'C^{commit}'` fails, the image was not
built here: skip silently.
```

Deleting C's objects therefore now makes the check vanish with no record line. That is less visible than the row says. Executed: `hg -C /workspace cat-file -e "0000…0001^{commit}"` exits 128 (`u4c-final-r1-step01.log`), which is the "fails" branch, so the step skips silently. The Won't-Fix rationale ("Advisory only, never a stop; the deletion is the same-uid hostile class") is untouched. Only the stated consequence is wrong. To fix the text, say "deleting C's commit object skips the check silently; deleting only its trees or blobs leaves a record note".

**Evidence:** `skills/dev-cycle/SKILL.md:287-288`, `:298-299`; `git show f2cc21e6:skills/dev-cycle/SKILL.md:284-290`; `docs/reviews/override-log.md:819`; `docs/reviews/execution-logs/u4c-final-r1-step01.log` (cwd `/workspace/.claude/wt-build-loop-u4c`, git `-C /workspace`, 2026-10-13T23:36:20-07:00, exit 128 recorded)

---

## Claim 5: Override rows 812-817 and every row number cited on the branch

**Location:** `docs/reviews/override-log.md:812-817`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** the next cycle's revisit-trigger scan
**Scope:** Covers that each cited row number (548, 735-744, 775, 807-811, 812-819) is the line of `docs/reviews/override-log.md` it is cited for, and the content of rows 812-816. It does not re-open row 817's "only ... step 0.1" omission, which i2 recorded as Mostly accurate (append-only).

Line numbers, read with `sed -n Np`:
- 738: `The canonical D6 source sits in test/lib/ ...`
- 739: `The snippet chooses main's copy from the repository's own data ...`
- 740 and 741: the verified reader's cost and seam
- 744: `The snippet has no timeout`
- 775: `questions.sh ... run through ~/.claude/scripts`
- 807: `confirm3 security F1`
- 808-811: F2, F3, F4 and C5(b)/C6, as row 817 says
- 548: `dev-cycle.sh runs neither state_gate nor default_gate`

Row 815's "nine per call" holds. `own()` runs `$(stat ...)` once per call unless `-L` (`skills/dev-cycle/SKILL.md:228`), and is called for 4 files plus 5 directories (`scripts/lib`, `scripts`, `claude-workflows`, `/opt`, `/`; `:243-246`). Row 816 also holds: `questions.sh`'s usage prints `#   ~/.claude/scripts/questions.sh check` (`scripts/questions.sh:28`).

**Evidence:** `docs/reviews/override-log.md:548`, `:735-744`, `:775`, `:807-819`; `skills/dev-cycle/SKILL.md:228`, `:243-246`; `scripts/questions.sh:28`

---

## Claim 6: Row 818, "the GATE_CODE check lower-cases paths ... install.sh stages exact names, and the scripts run by exact path ... --cycle-diff already refuses a cycle file in another case"

**Location:** `docs/reviews/override-log.md:818`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** the user reading a Won't-Fix rationale
**Scope:** Covers floor's lower-casing, the D6 block's exact-path launch and `cycle_rules`' case refusal. It does not establish behaviour on a case-insensitive filesystem.

floor lower-cases before the GATE_CODE test: `[[ -n "$lp" ]] || lp="$(lower "$1")" ... elif [[ "$lp" =~ $GATE_CODE ]]; then FLOOR_WHY=gate` (`scripts/lib/dev-cycle-read.sh:2000-2002`). The block runs `bash "$D6_OPT/scripts/$s"` with `$s` one of three exact names (`skills/dev-cycle/SKILL.md:230`, `:247`). `cycle_rules` has `refuse $p: one of the dev cycle's own files, spelled in another case` (`scripts/build-loop.sh:1925`), and its GATE_CODE test is lower-cased too (`:1923`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:2000-2002`; `scripts/build-loop.sh:1916-1925`; `skills/dev-cycle/SKILL.md:230`, `:247`

---

## Claim 7: D5 item 3, "D6 runs the image copy built from main (Q-140 [1]), so it is live at the next release, not the next merge"

**Location:** `docs/working/plan-build-loop-handoff.md:71`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** the next planner of U5's release entry
**Scope:** Covers what the image is built from. It does not establish the "by choice ... F58" rationale, which is design.

This basis changed since i1/i2 verified the sentence. The finding D1 (i2 security F1) established that the image is built from the host checkout's HEAD, not from main: `commit="$(head_commit)"`, where `head_commit` runs `repo_git rev-parse --verify -q 'HEAD^{commit}'` (`devcontainer-config/install.sh:186`, `:335`). The `.manifest` stamps that commit (`:357`). 43b8d7ed's step 0.1 exists precisely because the image may not be on main (`image-off-main`, `skills/dev-cycle/SKILL.md:288-290`). A precise version reads "the image copy, built from the host checkout's HEAD (normally main; step 0.1 flags otherwise)". The conclusion, live at the next release, holds.

**Evidence:** `docs/working/plan-build-loop-handoff.md:71`; `devcontainer-config/install.sh:184-191`, `:329-361`; `skills/dev-cycle/SKILL.md:285-290`

---

## Claim 8: D6 heading "The gate runs from the root-owned image copy (Q-140 [1]; first written as 'from main's commit')" and the Superseded bullet "it extracts nothing from MAIN_SHA, so the two bullets above and this bullet's root-commit test no longer apply"

**Location:** `docs/working/plan-build-loop-handoff.md:77`, `:81`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** a reader of the plan's decisions
**Scope:** Covers that the block extracts nothing and has no root test, and that "the two bullets above" are the extraction and hash-check bullets. It does not establish the still-standing first bullet (replace refs and grafts), which remains true.

The block's only launch is `env -u ... bash "$D6_OPT/scripts/$s" "$@"` (`skills/dev-cycle/SKILL.md:247`). It contains no `cat-file blob`, `ls-tree`, `hash-object` or `D6_ROOT` outside comments (`test/scripts/build-loop-orchestrator.bats:259`, test 11, ok). The two bullets directly above `:81` are `It extracts ... from MAIN_SHA` (`:79`) and `It checks each file's hash-object` (`:80`). The bullet before those, the replace-ref and grafts check (`:78`), still matches `:232-235` of SKILL.md.

**Evidence:** `docs/working/plan-build-loop-handoff.md:77-84`; `skills/dev-cycle/SKILL.md:232-247`; `u4c-final-r1-orchestrator-bats.log` test 11

---

## Claim 9: F39 "`/opt/...` by absolute path with an ownership check, in every repository (... the root-commit choice is gone) (T37)"; F40 "Nothing is extracted: the image copy's own layout, its four files checked (T33, T36)"

**Location:** `docs/working/plan-build-loop-handoff.md:157-158`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a reader of the failure-mode table
**Scope:** Covers the launch path, the ownership checks, and the tests named. It does not establish the root-only `-w` behaviour (Claim 19b).

The block sets `D6_OPT=/opt/claude-workflows` (`skills/dev-cycle/SKILL.md:224`) and checks `for f in build-loop.sh dev-cycle.sh questions.sh lib/dev-cycle-read.sh; do own "$D6_OPT/scripts/$f"; [[ -f ... ]]` (`:243-245`). T37 (tests 15 and 16) and the T36-labelled test 13, which holds the missing and not-regular cases (`test/scripts/build-loop-orchestrator.bats:294-295`), all pass. Executed: the real block's `--help` output is byte-identical to `/opt`'s direct output (`u4c-final-r1-d6-real.log`, "identical to /opt direct: yes").

**Evidence:** `skills/dev-cycle/SKILL.md:224`, `:243-247`; `test/scripts/build-loop-orchestrator.bats:282-296`, `:312-326`; `docs/reviews/execution-logs/u4c-final-r1-orchestrator-bats.log`; `docs/reviews/execution-logs/u4c-final-r1-d6-real.log`

---

## Claim 10: U4c as-built note: the as-built mechanism and its row citations (740, 741 discharged; 739 closed; 744 the Rules' stop; 775; 738; U4b2 confirm3 F1)

**Location:** `docs/working/plan-build-loop-handoff.md:344`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** the next session resuming the build-loop plan
**Scope:** Covers the mechanism sentence, the row numbers and the "image predates --land-cycle" consequence. It does not establish that the note lists the i2 additions (image-off-main), which it does not mention; nothing in the note claims to.

"once the four files are regular, root-owned, not symlinks and not writable, and so is every directory up to /" matches `own()` and the walk: `[[ ! -L "$1" && "$(stat -c %u -- "$1")" == 0 && ! -w "$1" ]]` (`skills/dev-cycle/SKILL.md:228`) and `while own "$x"; [[ "$x" != / ]]` (`:246`). Every cited row matches its line (Claim 5). "Row 744's timeout is the Rules' stop" matches `a call of any script that the Bash tool timed out ... are stops too` (`:50-51`). "the image at the time of writing (774a0eef) predates U4a's --land-cycle": `grep -c -- --land-cycle /opt/claude-workflows/scripts/build-loop.sh` gives 0, against 13 in the branch's copy.

**Evidence:** `docs/working/plan-build-loop-handoff.md:344`; `skills/dev-cycle/SKILL.md:50-51`, `:228`, `:246`; `/opt/claude-workflows/scripts/build-loop.sh`; `docs/reviews/override-log.md:738-744`, `:775`, `:807`

---

## Claim 11: ":356: The gate needs it too (D6 runs the image copy: Q-140 [1]) ... Since U4c, step 0.1's image-lag entry is that release entry's trigger: U5 makes the release entry the image-lag entry's body (one slug, one paste)"

**Location:** `docs/working/plan-build-loop-handoff.md:356`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** U5's implementer
**Scope:** Covers that step 0.1 files an `image-lag` entry with one paste, and that the sentence is a statement of U5's plan. It does not establish that U5 does it (not built).

Step 0.1 files `one you: terminal entry image-lag (an open one has its body rewritten) holding C, M, the changed names ... and the paste` (`skills/dev-cycle/SKILL.md:293-295`). The image copy is the only launch (`:247`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:356`; `skills/dev-cycle/SKILL.md:247`, `:293-298`

---

## Claim 12: T33 row "runs the image copy's four files (build-loop.sh and dev-cycle.sh with their own lib, dev-cycle.sh with its own questions.sh); main's and the working tree's copies have no effect; SKILL.md holds the block once (its one copy)"

**Location:** `docs/working/plan-build-loop-handoff.md:396`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a reader mapping T-ids to tests
**Scope:** Covers tests 11 and 12. It does not establish that dev-cycle.sh's own lib line is asserted. That is shown indirectly: main's and the working tree's libs are `echo main copy; exit 9` / `echo working copy; exit 9`, so sourcing either would end the digest, and the digest exits 0.

Test 12 writes `echo 'echo main copy; exit 9'` into each of main's four files, commits them, and puts `echo working copy; exit 9` in the working tree (`test/scripts/build-loop-orchestrator.bats:266-270`). It then asserts the lib was sourced from `$U` (`:274`), that the digest lists `from-opt` from `$U`'s questions.sh (`:278`), and that `d6 questions.sh open` prints `Q-001  trigger  from-opt` (`:279`). Test 11 asserts exactly one `bash -s` line and one `D6` line (`:256-257`). Both pass (`u4c-final-r1-orchestrator-bats.log`, tests 11 and 12).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:255-279`; `docs/reviews/execution-logs/u4c-final-r1-orchestrator-bats.log`

---

## Claim 13: Risks: "Since Q-140 [1] the gate waits too (D6 runs the image copy); step 0.1 files an image-lag entry when main's GATE_CODE paths differ from the image's .manifest commit."

**Location:** `docs/working/plan-build-loop-handoff.md:432`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a reader of the Risks section
**Scope:** Covers the condition under which step 0.1 files `image-lag`. It does not establish the paste's effect (Claim 23c).

`image-lag` is filed only after two earlier branches pass. The repository must hold C (`If ... cat-file -e 'C^{commit}' fails ... skip silently`), and C must be on main (`if ... merge-base --is-ancestor C M exits 1 ... image-off-main`). Only then does a differing diff file `image-lag` (`skills/dev-cycle/SKILL.md:287-294`). When the image is off main and its gate code differs, the entry is `image-off-main`, not `image-lag`. Executed today: cat-file exits 0, is-ancestor exits 0, and the diff exits 1 with `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh` and `skills/dev-cycle/SKILL.md` (`u4c-final-r1-step01.log`). A precise version adds "when the image's commit is on main (else image-off-main)".

**Evidence:** `docs/working/plan-build-loop-handoff.md:432`; `skills/dev-cycle/SKILL.md:285-299`; `docs/reviews/execution-logs/u4c-final-r1-step01.log`

---

## Claim 14: Rollback 1, "the gate that runs is the image's, so a revert of gate code takes effect only after the image is rebuilt from the reverted main (the host's ./devcontainer-config/install.sh, then the next sandbox launch)"

**Location:** `docs/working/plan-build-loop-handoff.md:441`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** the user performing a rollback
**Scope:** Covers that the gate is the `/opt` copy and that `/opt` is the image's `COPY claude-home/`, staged by install.sh from HEAD. It does not establish cc-isolated's rebuild-on-launch end to end (host-side, not runnable here).

The only launch is `/opt` (`skills/dev-cycle/SKILL.md:247`). The Dockerfile has `COPY claude-home/ /opt/claude-workflows/` (`devcontainer-config/Dockerfile:500`), and `assemble()` stages `commit="$(head_commit)"` (`devcontainer-config/install.sh:335`). cc-isolated's header says a launch on an unverified config "rebuilds the container" (`devcontainer-config/cc-isolated.sh:60-62`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:441`; `devcontainer-config/Dockerfile:500`; `devcontainer-config/install.sh:329-361`; `devcontainer-config/cc-isolated.sh:55-64`

---

## Claim 15: store_check comment "the objects of REV a decision reads hash to their ids and have one copy each (rows 492, 503). git checks no hash when it reads an object ..."

**Location:** `scripts/build-loop.sh:1042-1045`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** the next editor of store_check
**Scope:** Covers that the removed parenthetical leaves no dangling reference: `test/lib/d6-snippet.bash` and the "narrower reader" are gone from `scripts/`. It does not re-verify store_check's own behaviour, which this branch did not change.

The diff removes only `(The D6 snippet, test/lib/d6-snippet.bash, runs a narrower reader ...)`. `git grep -n 'd6-snippet\|verified reader\|D6_ROOT' -- scripts/` returns no hit (paraphrased — no quote available because the claim covers absence of code, no matching grep results).

**Evidence:** `scripts/build-loop.sh:1042-1050`; `git diff main...HEAD -- scripts/build-loop.sh`

---

## Claim 16: GATE_CODE comment "The scripts because the image copy built from main runs every merge after the next release (plan D6, D5 item 3; Q-140 [1]); skills/dev-cycle/ because its SKILL.md holds the D6 snippet that runs the gate (U4c; plan D4, F52). Both reach a session only from a release"

**Location:** `scripts/lib/dev-cycle-read.sh:1962-1966`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** the next editor of GATE_CODE
**Scope:** Covers the "built from main" mechanism and the SKILL.md holding the snippet. It does not establish the floor rationale, which is design.

Same basis change as Claim 7. The image is built from `HEAD^{commit}` of the host checkout (`devcontainer-config/install.sh:186`), not necessarily main. Step 0.1 files `image-off-main` when it is not (`skills/dev-cycle/SKILL.md:288-290`). "Its SKILL.md holds the D6 snippet" is true (`skills/dev-cycle/SKILL.md:195-253`). A precise version reads "the image copy, built from the host checkout (step 0.1 checks it is main)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1962-1970`; `devcontainer-config/install.sh:184-191`, `:335`; `skills/dev-cycle/SKILL.md:288-290`

---

## Claim 17: Rule "Every build-loop.sh, dev-cycle.sh and questions.sh call runs from WT (step 0's first two from MAIN_WT; step 7's self-merge from its GT, after a --state from MAIN_WT) ... In every repository, claude-workflows too, it runs the root-owned image copy (Q-140 [1]), so no repository file or state a build loop writes chooses which script runs as the gate (a hostile process of this uid still reaches the shell itself ...)"

**Location:** `skills/dev-cycle/SKILL.md:36-45`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** the orchestrator following the Rules; the user judging what the gate can be fooled by
**Scope:** Covers the call sites' checkouts and the script choice being independent of repository data. It does not establish anything against a same-uid shell (named as the residual), or which repository the script reads (Claim 20).

The call sites match the Rule:
- step 0.1 `--state` "run through the D6 block from the main worktree" (`:278`)
- step 0.2 "also from MAIN_WT" (`:300`)
- the digest "through the D6 block from WT" (`:341`)
- step 1's questions.sh "through the D6 block from WT" (`:382-383`)
- step 7 "run from a gate checkout, not WT: `--state` (from MAIN_WT ...), then `hg -C MAIN_WT worktree add --detach GT`" (`:562-565`)
- step 9 "after `questions.sh index` and `check` in WT" (`:712`)

The script path is the constant `$D6_OPT/scripts/$s` (`:247`). Executed: test 12 shows main's and the working tree's copies have no effect, and the real block's output equals `/opt`'s (`u4c-final-r1-d6-real.log`).

**Evidence:** `skills/dev-cycle/SKILL.md:36-45`, `:247`, `:278`, `:300`, `:341`, `:382-383`, `:562-565`, `:712`; `docs/reviews/execution-logs/u4c-final-r1-orchestrator-bats.log`; `docs/reviews/execution-logs/u4c-final-r1-d6-real.log`

---

## Claim 18: Rules "a call of any script that the Bash tool timed out, and a refuse d6: line, are stops too" ... "questions.sh never runs as ~/.claude/scripts/questions.sh (a uid-owned link; its own hints still print that path)"

**Location:** `skills/dev-cycle/SKILL.md:46-61`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** the orchestrator classifying an exit
**Scope:** Covers the block's exit contract (2 with one `refuse d6:` line, 1 for a bad first argument, otherwise the script's own) and that the hint text is questions.sh's own. It does not establish how each writing mode behaves when stopped part way.

`no() { echo "refuse d6: $*"; exit 2; }` (`:225`), and `exit "$?"` after the launch (`:248`). Executed: outside a repo the block prints `refuse d6: refs/replace could not be listed` and exits 2. `nope` exits 1 with the stderr line. Two default branches exit 2 (`u4c-final-r1-d6-real.log`). The block never names `~/.claude/scripts` (test 11's grep, `test/scripts/build-loop-orchestrator.bats:259`). The `/opt` questions.sh hint prints `run ~/.claude/scripts/questions.sh init first` (`u4c-final-r1-d6-real.log`, control run).

**Evidence:** `skills/dev-cycle/SKILL.md:46-61`, `:225`, `:247-248`; `docs/reviews/execution-logs/u4c-final-r1-d6-real.log`

---

## Claim 19a: Header refusal list: "a replace ref, info/grafts, a default branch that is not exactly one plain main or master or whose ref names no commit itself, an image-copy file that is missing ... or not a regular file, or one of those files or a directory above them that is not root-owned, a plain path and unwritable here ..., or a git read that fails (git may add a line on stderr); 1 for another first argument"

**Location:** `skills/dev-cycle/SKILL.md:210-218`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** the orchestrator reading a `refuse d6:` line
**Scope:** Covers every listed case against the code and the tests or runs that exercise it. It does not establish the as-root `-w` parenthetical (19b).

Each case maps to a `no` call:
- `:232-235`: replace refs and grafts
- `:236-237`: not exactly one of main and master
- `:238`: a symbolic ref
- `:239`: names no commit
- `:228`: `no "$1 is missing"` and the ownership refusal
- `:244`: not a regular file
- `:246`: the directory walk

The block has no other `no` call and no other exit 1 (`:230`). Test 13 exercises replace refs, grafts, branch variants, the missing and not-regular file, and the first argument. Test 16 exercises the unstubbed uid-owned and missing refusals. Both pass. The real run shows a failed git read with git's `fatal:` on stderr (`u4c-final-r1-d6-real.log`).

**Evidence:** `skills/dev-cycle/SKILL.md:210-248`; `test/scripts/build-loop-orchestrator.bats:282-296`, `:320-326`; `docs/reviews/execution-logs/u4c-final-r1-orchestrator-bats.log`; `docs/reviews/execution-logs/u4c-final-r1-d6-real.log`

---

## Claim 19b: "(the -w test makes a run as root refuse unless the mount is read-only)"

**Location:** `skills/dev-cycle/SKILL.md:215`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** an operator who runs the orchestrator as root
**Scope:** Covers nothing beyond static reading of `! -w "$1"` in `own()`. It does not establish root behaviour.

`own()` requires `! -w "$1"` (`:228`). Execution required: the session runs as uid 1000 with no root, so the root case cannot be run (rubric C11, still open).

**Evidence:** `skills/dev-cycle/SKILL.md:215`, `:228`

---

## Claim 20: Header trust statements: "so no repository data chooses which script runs ... It still trusts that entry and the default branch's ref for which repository and branch the script reads (a moved main is --main-log's to report), and it cannot guard against this uid's own shell (PATH, exported functions): the plan's same-uid residual (Q-103). In claude-workflows a gate change runs from the next image release."

**Location:** `skills/dev-cycle/SKILL.md:200-211`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** the user judging the gate's trust root
**Scope:** Covers that the script choice reads no repository data, and that `.git` discovery and the default branch's ref are taken as given. It does not establish anything about the scripts' own reads after launch.

The only repository reads before the launch are refusal checks (`:232-239`). Their results gate whether anything runs, never which file. The launch path is constant (`:247`). Repository discovery is git's own, through the checkout's `.git` entry. `sha` is read from `refs/heads/$m` and checked only to be a commit (`:239`), and is not passed to the script. i1 security executed the PATH and `BASH_FUNC_` residual (rubric B1).

**Evidence:** `skills/dev-cycle/SKILL.md:200-211`, `:232-247`

---

## Claim 21: "The four files the scripts run (build-loop.sh and dev-cycle.sh source the lib from their own directory; dev-cycle.sh runs questions.sh beside it)"

**Location:** `skills/dev-cycle/SKILL.md:240-242`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** the next editor of the four-file list
**Scope:** Covers the source and run paths of the three scripts. It does not establish dev-cycle.sh's `~/.claude/scripts/questions.sh` fallback, which is unreachable through the block because the block refuses a missing `/opt` questions.sh first.

```bash
# scripts/build-loop.sh:524-531
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"
source "$READ_LIB"
```

dev-cycle.sh does the same (`scripts/dev-cycle.sh:95-103`) and runs `QS="$SCRIPT_DIR/questions.sh"; [[ -f "$QS" ]] || QS="$HOME/.claude/scripts/questions.sh"` (`:389-390`). questions.sh sources nothing (`grep -n source scripts/questions.sh`: no `source` line). Test 12's `from-opt` digest line executes the beside-it path.

**Evidence:** `scripts/build-loop.sh:524-532`; `scripts/dev-cycle.sh:95-104`, `:389-390`; `test/scripts/build-loop-orchestrator.bats:277`

---

## Claim 22: The launch `env -u BASH_ENV -u ENV -u DEV_CYCLE_SCRUBBED -u QUESTIONS_LIVE -u QUESTIONS_ARCHIVE` keeps the caller's QUESTIONS_LIVE/ARCHIVE from reaching questions.sh

**Location:** `skills/dev-cycle/SKILL.md:247`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** the orchestrator running questions.sh through the block
**Scope:** Covers questions.sh launched directly and, through dev-cycle.sh, by inheritance. It does not establish other variables questions.sh might read.

questions.sh reads `LIVE="${QUESTIONS_LIVE:-$PROJECT_ROOT/docs/working/questions.md}"` (`scripts/questions.sh:85-86`). Executed with both set to `/nonexistent/...`: through the block, `questions.sh check` prints `✓ questions: structure valid, indexes current` and exits 0. Run directly, the same environment gives `✗ missing: /nonexistent/q.md` and exits 1 (`u4c-final-r1-d6-real.log`).

**Evidence:** `skills/dev-cycle/SKILL.md:247`; `scripts/questions.sh:85-86`; `docs/reviews/execution-logs/u4c-final-r1-d6-real.log` (cwd scratch repo, 2026-10-13T23:39:46-07:00, exits 0 and 1)

---

## Claim 23a: Step 0.1's commands and what each branch establishes: "C and A are the commit= and assembled_from= lines ... If cat-file -e 'C^{commit}' fails, the image was not built here: skip silently. Else, if merge-base --is-ancestor C M exits 1, the gate that runs was built off main ... Else run diff --quiet C M -- PATHS ... Exit 1: the gate that runs differs from main's ... Exit 0: an open image-lag entry is answered done (this diff is the observation)"

**Location:** `skills/dev-cycle/SKILL.md:285-299`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** the orchestrator filing step 0.1's outcome; the user reading the entry
**Scope:** Covers the exit codes of each command against the real manifest and /workspace, and the inference "image files = C's committed content". It does not establish the is-ancestor exit-128 path, which falls to the diff and then to "note it".

Executed with the Rules' `hg`:
- C=774a0eef…, A=/home/magfrump/claude-workflows, M=2aaf97b4…
- `cat-file -e` exits 0, `--is-ancestor C M` exits 0, and `diff --quiet` exits 1
- `--name-only` lists `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh` and `skills/dev-cycle/SKILL.md`
- an unknown C makes `cat-file -e` exit 128 (skip)
- a commit not on main makes `--is-ancestor` exit 1, the image-off-main branch

All of these are in `u4c-final-r1-step01.log`. The literal pathspec `scripts/lib/` under `GIT_LITERAL_PATHSPECS=1` still matches the directory's files (same log). "The gate that runs differs" follows because `/opt` is the image's `COPY claude-home/` of `git archive`-staged HEAD content, with `# dirty=no always: the payload is exactly the commit's content` (`devcontainer-config/install.sh:355`).

**Evidence:** `skills/dev-cycle/SKILL.md:285-299`; `devcontainer-config/install.sh:329-361`; `devcontainer-config/Dockerfile:500`; `docs/reviews/execution-logs/u4c-final-r1-step01.log`

---

## Claim 23b: "A missing .manifest or line, or any other exit: note it in the record."

**Location:** `skills/dev-cycle/SKILL.md:298-299`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** the orchestrator handling a malformed manifest
**Scope:** Covers the order of the step's tests for an empty C. It does not establish any runtime case beyond reading the text.

The text applies the `cat-file -e 'C^{commit}'` test first (`:287-288`). With no `commit=` line, C is empty, `cat-file -e '^{commit}'` fails, and the literal order reaches `skip silently` before the closing "note it" sentence. The two sentences give opposite instructions for that case. A precise version tests the manifest first: "If the `.manifest` or either line is missing, note it in the record; else, if `cat-file -e` fails, skip silently".

**Evidence:** `skills/dev-cycle/SKILL.md:286-299`

---

## Claim 23c: The paste "cd A && test "$(git rev-parse HEAD)" = M && ./devcontainer-config/install.sh (host; then a new sandbox launch)", A being the manifest's assembled_from

**Location:** `skills/dev-cycle/SKILL.md:295-296`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** the user running the `you: terminal` paste on the host
**Scope:** Covers that A is install.sh's REPO_ROOT, that install.sh stages HEAD, and that the guard aborts unless HEAD is M. It does not establish the host-side run, which needs the host.

install.sh sets `REPO_ROOT="$(cd "$SRC/.." && pwd)"` (`devcontainer-config/install.sh:112`) and writes `echo "assembled_from=$REPO_ROOT"` (`:360`), so `./devcontainer-config/install.sh` from A is that script. It stages `commit="$(head_commit)"` (`:335`), which is `rev-parse --verify -q 'HEAD^{commit}'` (`:186`). The `test ... = M &&` guard therefore installs only when the staged commit is M.

**Evidence:** `devcontainer-config/install.sh:105-112`, `:184-191`, `:329-361`; `/opt/claude-workflows/.manifest`

---

## Claim 24: Step 1 "run questions.sh init ... then questions.sh archive ... through the D6 block from WT ... (a refuse d6: line or a timed-out call is still a stop, as the Rules say)" and step 9 "after questions.sh index and check in WT ... (check exiting 1 names entries to fix before staging)"

**Location:** `skills/dev-cycle/SKILL.md:382-385`, `:712-713`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** the orchestrator at steps 1 and 9
**Scope:** Covers consistency with the Rule and `check`'s exit contract. It does not establish that step 9 repeats "through the D6 block" (it relies on the Rule's "every questions.sh call").

The Rule covers every questions.sh call (`:36`). questions.sh's usage reads `check  validate both files (exit 1 on problems)` (`scripts/questions.sh:28`).

**Evidence:** `skills/dev-cycle/SKILL.md:36-41`, `:382-385`, `:712-713`; `scripts/questions.sh:28`

---

## Claim 25: d6_copy comment "with trust its ownership check passes any path that exists (and refuses a missing one with the snippet's own words), so a uid-owned OPT stands in for the root-owned image"

**Location:** `test/scripts/build-loop-orchestrator.bats:227-233`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** the next editor of the D6 tests
**Scope:** Covers the stub's text and the literal `trust` argument. It does not establish that the stub refuses a dangling symlink the way the real `own()` does: the stub's `[[ -e "$1" ]]` calls it missing, while the real `own()` gives the ownership refusal. No test relies on that case.

The stub is `own() { [[ -e "$1" ]] || no "$1 is missing"; }`, installed only when `"${2:-}" == trust` (`:238`). The real first clause is `no "$1 is missing"` (`skills/dev-cycle/SKILL.md:228`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:227-239`; `skills/dev-cycle/SKILL.md:228`

---

## Claim 26: T33 extraction test "SKILL.md holds the D6 snippet once, and it names no other copy to run: no root test, no read of main's scripts"

**Location:** `test/scripts/build-loop-orchestrator.bats:255-261`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a reader trusting T33 as the single-copy guard
**Scope:** Covers one call line, one `D6` line, the extracted last line, a grep of non-comment lines for the old reader's commands, and the deleted file. It does not prove that no other root test exists (rubric C10: a grep, not a proof; test 12 is the behavioural check).

The test asserts the counts (`:256`), checks that the last line is `d6 "$@" </dev/null` (`:257`), runs `! grep -v '^ *#' "$D6" | grep -nE 'D6_ROOT|cat-file (blob|--batch)|ls-tree|mktemp|\$HOME|~/'` (`:259`), and checks `[ ! -e "$REPO_ROOT/test/lib/d6-snippet.bash" ]` (`:260`). My own extraction with the same awk gives 56 lines, ending at the `d6 "$@"` line. The test passes (test 11).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:255-261`; `docs/reviews/execution-logs/u4c-final-r1-orchestrator-bats.log`

---

## Claim 27: Test "the D6 snippet runs the image copy's scripts by absolute path, with the image's own lib and questions.sh, never main's or the working tree's (T33, U3b3, U4c)"

**Location:** `test/scripts/build-loop-orchestrator.bats:263-279`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a reader of the test suite
**Scope:** Covers the stand-in image at `$U` under the trust stub. It does not cover the real root-owned `/opt` run, which is test 15.

See Claim 12 for the assertions. The test passes (test 12).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:263-279`; `docs/reviews/execution-logs/u4c-final-r1-orchestrator-bats.log`

---

## Claim 28: The missing-file refusals: test 13's `rm "$U/scripts/questions.sh"; d6_is "refuse d6: $U/scripts/questions.sh is missing"` and test 16, "refuses an image copy the uid owns or one missing a file (an older image), and never runs main's"

**Location:** `test/scripts/build-loop-orchestrator.bats:294`, `:320-326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a reader checking the missing-image case is tested on the real `own()`
**Scope:** Covers that test 16 uses the unstubbed copy (`d6_copy "$U"` with no `trust`) and asserts the exact output. It does not establish the walk over directories that fail (override row 814).

Test 13's missing-file line runs under the trust stub (`d6_setup` calls `d6_copy "$U" trust`, `:243`). Test 16 runs `opt_copy "$U"; d6_copy "$U"`, then `d6_is "... build-loop.sh is not root-owned ..."`, then `rm "$U/scripts/build-loop.sh"; d6_is "... is missing"` (`:322-325`). `d6_is` asserts exit 2 and exactly that output, so main's `echo main copy` never ran. Both pass.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:241-251`, `:282-296`, `:320-326`; `docs/reviews/execution-logs/u4c-final-r1-orchestrator-bats.log`

---

## Claim 29: Test "SKILL.md step 0.1's image-lag paths are GATE_CODE's, on one line of their own: a GATE_CODE change fails here until both move (U4c i2 architecture 1)"

**Location:** `test/scripts/build-loop-orchestrator.bats:347-354`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** the next editor of GATE_CODE
**Scope:** Covers what the three assertions enforce. It does not establish that every GATE_CODE alternative has a PATHS entry (the reverse direction).

The test pins GATE_CODE to a literal (`:350`), pins SKILL.md's line to the test's `P` (`:352`), and checks that each `P` path matches GATE_CODE (`:353`). Any GATE_CODE change does fail here, and the message says `update step 0.1's PATHS line and this test`. But "until both move" is not enforced. Executed: GATE_CODE widened with `|^scripts/health-check\.sh$` and the test's literal updated to match, with SKILL.md's line unchanged. All three assertions pass, though `scripts/health-check.sh` is then gate code that the lag check does not read (`u4c-final-r1-pin-mutation.log`, exit 0). A precise name is "fails on any GATE_CODE change until this test's literal is updated; every PATHS entry is GATE_CODE's". The reverse direction holds only by an editor heeding the message.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:347-354`; `docs/reviews/execution-logs/u4c-final-r1-pin-mutation.log` (cwd `/workspace/.claude/wt-build-loop-u4c`, 2026-10-13T23:38:45-07:00, exit 0)

---

## Claim 30a: Commit 1bc823ea body, apart from its row citation

**Location:** `1bc823ea` (commit message)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a reader of `git log`
**Scope:** Covers "always runs the root-owned image copy ... the verified reader, D6_ROOT and the temp dir go ... keeps the replace-ref, grafts and default-branch checks, and the ownership checks ... takes questions.sh (row 775) ... test/lib/d6-snippet.bash is deleted ... by-hand fallback is gone ... Step 0.4" and the Notes' "the unstubbed refusal and the real /opt run are tested as before". It does not cover the row citation (30b).

These match `skills/dev-cycle/SKILL.md:224-248`, the deletion in `git diff main...HEAD -- test/lib/d6-snippet.bash`, the removed fallback paragraph, and step 0.4's `a cycle you know ran is one that reached step 9's land` (`:357-358`). Tests 15 and 16 pass.

**Evidence:** `git log -1 1bc823ea`; `skills/dev-cycle/SKILL.md:224-248`, `:357-358`; `docs/reviews/execution-logs/u4c-final-r1-orchestrator-bats.log`

---

## Claim 30b: Commit 1bc823ea Notes "(row 739 left the home to U4)"

**Location:** `1bc823ea` (commit message)
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** a reader of `git log`
**Scope:** Covers the row number only. This is already recorded as Accepted-immutable (`docs/reviews/override-log.md:812`, rubric B2) and is not a new finding.

Row 738 is `The canonical D6 source sits in test/lib/ ... | Defer | U4 writ…` (`docs/reviews/override-log.md:738`). Row 739 is the trust-root row.

**Evidence:** `docs/reviews/override-log.md:738-739`, `:812`

---

## Claim 31: Commit 33ad1767 body

**Location:** `33ad1767` (commit message)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** a reader of `git log`
**Scope:** Covers the commit's statements about its own diff (verified as i2 claim 30), re-read against `git show 33ad1767`. It does not establish that "main's gate code is ahead of" still describes HEAD's step 0.1, which says "differs" since f2cc21e6/43b8d7ed. A commit message describes its own commit.

The narrower Rule and header, the `.git` entry named, `is missing` first, the `env -u` of both QUESTIONS variables, step 0.1's image-lag check and the plan corrections all appear in `git show 33ad1767` (paraphrased — no quote available because the behaviour spans five files of that commit's diff).

**Evidence:** `git log -1 33ad1767`; `git show 33ad1767 --stat`; `docs/reviews/code-fact-check-report-2026-10-13-u4c-i2.md` claim 30

---

## Claim 32: Commit f2cc21e6 "Step 0.1 compares only GATE_CODE's paths (all of scripts/ named health-check.sh too) ... notes a missing manifest or failed command. Step 1 names the timeout stop; the block header says the default branch's ref; Rollback 1 is scoped to gate-code reverts."

**Location:** `f2cc21e6` (commit message)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a reader of `git log`
**Scope:** Covers the parenthetical, executed, and each named edit, read in `git diff 33ad1767 f2cc21e6`. It does not establish the step 0.1 text at HEAD, which 43b8d7ed rewrote.

Executed: `git diff --name-only C M -- scripts/` lists `scripts/build-loop.sh`, `scripts/health-check.sh` and `scripts/lib/dev-cycle-read.sh`, so all of `scripts/` named health-check.sh (`u4c-final-r1-step01.log`). The f2cc21e6 step 0.1 text reads `No .manifest, no commit= line or any other exit: note it in the record and go on`, and the header reads `the default branch's ref` (`git show f2cc21e6:skills/dev-cycle/SKILL.md:284-290`).

**Evidence:** `git log -1 f2cc21e6`; `git diff 33ad1767 f2cc21e6 -- skills docs/working`; `docs/reviews/execution-logs/u4c-final-r1-step01.log` (cwd `/workspace`, 2026-10-13T23:40:38-07:00, exit 0)

---

## Claim 33: Commit 43b8d7ed "step 0.1 now files image-off-main (you: judgment) when the image's commit is not on main ... the image-lag paste checks the host checkout is at main's commit before install.sh. image-lag carries C, M, the changed names and an interim, and a clean diff answers it done. The path list sits on one line pinned with GATE_CODE by a new test. A missing image file's --state stop gives the same paste. Plan: U5's release entry becomes the image-lag entry's body." Notes: "executed by hand against the real image (C on main, diff 1)"

**Location:** `43b8d7ed` (commit message)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a reader of `git log`; the merge reviewer
**Scope:** Covers each statement against HEAD and a re-run of the Notes' observation. It does not establish the pin's reverse direction (Claim 29), and "pinned" here means a GATE_CODE change fails the test.

Each statement is in `skills/dev-cycle/SKILL.md:283-299`, `test/scripts/build-loop-orchestrator.bats:347-354` and `docs/working/plan-build-loop-handoff.md:356` (Claim 3). Re-run: is-ancestor exits 0 (C on main), and `diff --quiet` exits 1 (`u4c-final-r1-step01.log`). "i2 critic reports, rubric and override rows": the commit adds the three `*-u4c-i2.md` critic reports, the rubric edit and rows 818-819 (`git diff f2cc21e6 43b8d7ed --stat`).

**Evidence:** `git log -1 43b8d7ed`; `git diff f2cc21e6 43b8d7ed --stat`; `docs/reviews/execution-logs/u4c-final-r1-step01.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4** (`docs/reviews/override-log.md:819`, rubric `:82`): since 43b8d7ed a failed `cat-file -e 'C^{commit}'` is "skip silently", so deleting C's commit object skips the check with no record line. A record note follows only when C's commit stays and its trees or blobs are gone. Fix the stated consequence; the Won't-Fix rationale stands.
- **Claim 30b** (`1bc823ea`): row 739 cited for the canonical copy's home, which is row 738. Already Accepted-immutable (row 812), so no action.

### Stale
- **Claim 1** (rubric `:1`, `:84-86`): the header says `Commit: f2cc21e6`, but the rubric records 43b8d7ed's fixes. The Status section covers iteration 1 only.

### Mostly Accurate
- **Claim 2** (rubric `:70`): the architecture i2 tally omits its one Informational finding.
- **Claim 7** (plan `:71`) and **Claim 16** (`scripts/lib/dev-cycle-read.sh:1963`): "the image copy built from main". The image is built from the host checkout's HEAD (D1 changed this basis), which step 0.1 checks is on main.
- **Claim 13** (plan `:432`): `image-lag` is filed only when C is held and on main; otherwise the entry is `image-off-main` or the check is skipped.
- **Claim 23b** (`skills/dev-cycle/SKILL.md:287`, `:298`): an empty C (no `commit=` line) reaches "skip silently" before "a missing ... line: note it". Test the manifest first.
- **Claim 29** (`test/scripts/build-loop-orchestrator.bats:347`): "until both move" is not enforced. Updating GATE_CODE and the test's literal passes with step 0.1's line unchanged (executed).

### Unverifiable
- **Claim 19b** (`skills/dev-cycle/SKILL.md:215`): the as-root `-w` behaviour needs a root run (rubric C11).

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to /workspace/.claude/wt-build-loop-u4c/docs/reviews/code-fact-check-report-2026-10-13-u4c-final-r1.md, structured per the code-fact-check skill.
- Answered: all eight focus areas of the brief. These are the D6 header, Rules and call sites, and step 0.1, executed read-only against /workspace with the real manifest and paste provenance traced through install.sh. They also include the D6 tests (bats run, 26/26) and the pin test (mutation executed), the plan items, override rows 812-819 and the rubric, the two script comments, and the four commit messages.
- Out of scope: code quality and design judgments; `scripts/health-check.sh` (not run, per the brief); host-side runs of install.sh and cc-isolated; a root run.
- Escalate: Claim 4 is the one new Incorrect. A decided row's stated consequence changed in its own commit, making the deletion case silent rather than recorded. It is advisory and in the hostile class, so it is not blocking. The rest is wording-grade.
