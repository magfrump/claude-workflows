# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u4c`)
**Scope:** fix range `git diff 1bc823ea..33ad1767`, the authored files only (`skills/dev-cycle/SKILL.md`, `test/scripts/build-loop-orchestrator.bats`, `docs/working/plan-build-loop-handoff.md`, `docs/reviews/override-log.md`, `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md`) plus the commit message of 33ad1767; the i1 critic reports and logs in the range are evidence, not checked line by line. The rest of the branch (`git diff main...HEAD`) was read as context.
**Commit:** 33ad1767
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-10-13
**Total claims checked:** 30
**Summary:** 22 verified, 7 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

I read the hallucination pattern log (`docs/reviews/hallucination-patterns.md`) first. No claim below matches a logged pattern, and there is no Incorrect verdict, so the log is unchanged.

Execution logs (all under `docs/reviews/execution-logs/`): `u4c-i2-image-lag.log` (step 0.1's commands against `/workspace`, read-only), `u4c-i2-own.log` (own() taken verbatim from SKILL.md and run on six kinds of path), `u4c-i2-questions-env.log` (the block run with QUESTIONS_LIVE/ARCHIVE set), `u4c-i2-orchestrator-bats.log` (the suite).

---

## Claim 1: "Fact-check: 33 claims; 21 Verified, 6 Mostly accurate, 1 Stale, 4 Incorrect, 1 Unverifiable" and the "Considered overrides" row list

**Location:** `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:11`, `:53`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the i1 verdict counts and each row number on `:53` checked against that line of `docs/reviews/override-log.md`. It does not establish that the i1 verdicts themselves are right.

The i1 report header says `**Total claims checked:** 33` and `**Summary:** 21 verified, 6 mostly accurate, 1 stale, 4 incorrect, 1 unverifiable` (`docs/reviews/code-fact-check-report-2026-10-13-u4c-i1.md:8-9`). Counting its `**Verdict:**` lines gives the same numbers: 21/6/1/4/1. Each row on `:53` matches its subject as a line number in override-log.md:

- 735 is the `refuse d6:` handling row.
- 736 and 737 are the row-704 wrapper/HARDEN row and the "opposite precedence" row.
- 738 is "The canonical D6 source sits in test/lib/".
- 739 is "The snippet chooses main's copy from the repository's own data".
- 740 and 741 are the verified reader's cost and its perl test seam.
- 742 is the environmental refusals row.
- 743 is the fork-overhead correction.
- 744 is "The snippet has no timeout".
- 775 is questions.sh through `~/.claude/scripts`.
- 807 to 811 are the U4b2 confirm3 rows.

The rubric's gloss "the Incorrects are a row mis-citation and an overbroad guarantee" covers four Incorrects: two of each kind (claims 6 and 30b, claims 11b and 15b in the i1 report). That is true as a description of their kinds.

**Evidence:** `docs/reviews/code-fact-check-report-2026-10-13-u4c-i1.md:8-9`, `:560-570`; `docs/reviews/override-log.md:735-744`, `:775`, `:807-811`

---

## Claim 2: Rubric statuses "Fixed" for B1-B5, C1-C5 and C10

**Location:** `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:25-39`, `:44`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each Fixed status against the text at 33ad1767. It does not establish that the fixes are sufficient (that is the critics' job). The deferred and won't-fix rows are covered by Claim 5.

- B1: the Rule now reads "no file or repository state a build loop writes chooses which script runs as the gate" (`skills/dev-cycle/SKILL.md:42`). The header reads "so no repository data / chooses which script runs" (`:200-201`). Both name the same-uid residual.
- B2: the plan note cites "(row 738)" for the canonical copy and "rows 740, 741 discharged" for the reader (`docs/working/plan-build-loop-handoff.md:344`). The commit's part is row 812, which is Accepted-immutable.
- B3: see Claims 7 to 9, 12 and 14.
- B4: step 0.1's image-lag text is at `SKILL.md:283-288`.
- B5: "Every `build-loop.sh`, `dev-cycle.sh` and `questions.sh` call" (`:36`), "a call of any / script that the Bash tool timed out" (`:50-51`), and step 1's "(a `refuse d6:` line / is still a stop, as the Rules say)" (`:374-375`).
- C1: "It still trusts that entry and refs/heads/main" (`:203`).
- C2: see Claims 22 and 29.
- C3: see Claim 24.
- C4: "MAIN_WT, WT or GT" (`:208`), "row 548 for / dev-cycle.sh" (`:220-221`), "build-loop.sh and dev-cycle.sh source the / lib" (`:240-241`), and the plan's "this bullet's root-commit test" (`plan:81`).
- C5: `[[ "${2:-}" != trust ]] ||` (`test/scripts/build-loop-orchestrator.bats:236`).
- C10: the plan note reads "T33 asserts it appears once and holds no reader commands; the run test shows main's and the working tree's copies have no effect" (`plan:344`).

**Evidence:** `skills/dev-cycle/SKILL.md:36-61`, `:200-247`, `:283-288`, `:374-375`; `docs/working/plan-build-loop-handoff.md:81`, `:344`; `test/scripts/build-loop-orchestrator.bats:236`; `docs/reviews/override-log.md:812`

---

## Claim 3: "Iteration 1 found no 🔴 and five 🟡, all fixed in the fix commit"

**Location:** `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:57`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the count and the "all fixed" status. It does not cover the 🟢 rows.

The count is right: five 🟡 rows (B1-B5) and "None." under Must Fix. B2's own Status cell says otherwise for part of B2, though: "Fixed in the plan; the commit message is an Accepted-immutable row" (`:26`). So one 🟡 is fixed in the plan and accepted, not fixed, for the commit. A precise version: "all fixed in the fix commit (B2's commit-message half accepted as immutable, row 812)".

**Evidence:** `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:21-29`, `:57`; `docs/reviews/override-log.md:812`

---

## Claim 4: "Health check passed at 1bc823ea."

**Location:** `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:15`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers whether this pass can confirm the statement. It does not establish whether the health check passes at 33ad1767.

This is an executable guarantee. I was told not to run `scripts/health-check.sh`, and none of the i1 execution logs in the range captures a health-check run (paraphrased — no quote available because the claim covers absence: the four i1 logs are `u4c-i1-d6-path.log`, `u4c-i1-d6-run.zsh.txt`, `u4c-i1-d6-zsh.log` and `u4c-i1-orchestrator-bats.log`). Blocker: the instruction not to run it. Checking it would need a run at 1bc823ea, or its captured log.

**Evidence:** `docs/reviews/execution-logs/` (listing at 33ad1767)

---

## Claim 5: Override rows 812-816 (i1 accepted, deferred and won't-fix rows)

**Location:** `docs/reviews/override-log.md:812-816`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each row's factual content and its citations. It does not establish that Defer or Won't-Fix is the right call.

- Row 812: 1bc823ea's Notes do read "(row 739 left the home to U4)" (`git log -1 1bc823ea`), and line 738 is the canonical-copy row.
- Row 813: HARDEN's three copies are the lib, the block's `G=(env …)` (`SKILL.md:226`) and the Rules' `hg()` (`:68`). One test pins all three (`bats:327`, "the D6 snippet's git and SKILL.md's hg carry the same").
- Row 814: i1 security says "a symlinked directory between the files and `/` … refused … a uid-owned 0555 stand-in tree (refused at the first file, executed)" (`security-review-2026-10-13-u4c-i1.md:92`).
- Row 815: "nine per call" is right. own() runs on four files and five directories (`scripts/lib`, `scripts`, `claude-workflows`, `opt`, `/`), and `stat` runs once in each call that passes the `! -L` test (`SKILL.md:228`, `:244-246`).
- Row 816: questions.sh's hints read `#   ~/.claude/scripts/questions.sh check …` (`scripts/questions.sh:28-30`). A missing image questions.sh is refused before anything runs (Claim 22).

**Evidence:** `docs/reviews/override-log.md:738`, `:812-816`; `skills/dev-cycle/SKILL.md:68`, `:226-246`; `scripts/questions.sh:28-30`; `docs/reviews/security-review-2026-10-13-u4c-i1.md:92`

---

## Claim 6: "Re-keys rows 808-811 …: U4c changed only the D6 block, its Rules and step 0.1, none of those paths"

**Location:** `docs/reviews/override-log.md:817`
**Type:** Reference / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the list of SKILL.md regions U4c changes (`git diff main...HEAD -U0`) and whether any of them holds the paths rows 808-811 describe. It does not establish that those rows' risks are acceptable.

The conclusion holds: rows 808-811 concern step 0.2's `keep` and answer handling, `refuse main-log`, and step 7's approved merges, and U4c has no hunk in step 0.2 or step 7. The "only" list is incomplete, though. Hunks headed `@@ -295 +346,2 @@` (step 0.4) and `@@ -319,2 +371,2 @@` / `@@ -322 +374,2 @@` (step 1), plus the removal of the by-hand fallback paragraph (`@@ -19,11 +18,0 @@`), are also U4c's. Step 0.4 is the one this same row says "row 807 (F1) is fixed in U4c's step 0.4". Precise version: "the D6 block, its Rules, steps 0.1, 0.4 and 1 and the deleted fallback paragraph; none of those paths".

**Evidence:** `docs/reviews/override-log.md:808-811`, `:817`; `git diff main...HEAD -U0 -- skills/dev-cycle/SKILL.md` hunk headers

---

## Claim 7: "D6 runs the image copy built from main (Q-140 [1]), so it is live at the next release, not the next merge; it stays on this list by choice, since a release review is a skim (F58)"

**Location:** `docs/working/plan-build-loop-handoff.md:71`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the run target and the F58 citation. It does not establish when a release happens.

The block launches `bash "$D6_OPT/scripts/$s"` with `D6_OPT=/opt/claude-workflows` (`SKILL.md:224`, `:247`). F58 reads "Self-mergeable code reaches running sessions through a release you skim" (`plan:176`). GATE_CODE still lists the scripts (`scripts/lib/dev-cycle-read.sh:1970`).

**Evidence:** `skills/dev-cycle/SKILL.md:224`, `:247`; `docs/working/plan-build-loop-handoff.md:176`; `scripts/lib/dev-cycle-read.sh:1970`

---

## Claim 8: D6 heading "The gate runs from the root-owned image copy (Q-140 [1]; first written as "from main's commit")" and "this bullet's root-commit test no longer apply"

**Location:** `docs/working/plan-build-loop-handoff.md:77`, `:81`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the heading against the block, and the self-reference against the bullet's own text. It does not cover the bullets at `:78-80` the heading supersedes, which are left as history.

The block always runs `/opt` (Claim 7). The `:81` bullet itself holds "As first written: it used main's copy only when main's first-parent root commit is claude-workflows'", so "this bullet's" is the right referent. The block holds no root test: T33 greps for `D6_ROOT|cat-file (blob|--batch)|ls-tree|mktemp` (`bats:258`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:77-81`; `test/scripts/build-loop-orchestrator.bats:255-261`

---

## Claim 9: F39 "`/opt/...` by absolute path with an ownership check, in every repository … (T37)"; F40 "Nothing is extracted: the image copy's own layout, its four files checked (T33, T36)"

**Location:** `docs/working/plan-build-loop-handoff.md:157-158`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the mitigations and the T-ids each names. It does not establish ancestor-directory refusals under test (row 814's gap).

- The four files are checked in a loop: `for f in build-loop.sh dev-cycle.sh questions.sh lib/dev-cycle-read.sh; do own …; [[ -f … ]] || no …` (`SKILL.md:243-245`).
- T37's tests cover the `/opt` run and the uid-owned or missing refusal (`bats:312`, `:320`).
- T36's test also checks the files: `rm "$U/scripts/questions.sh"; d6_is "refuse d6: $U/scripts/questions.sh is missing"` and the "is not a regular file" case (`bats:294-295`).
- T33's run test covers the layout (`bats:263`).

Command: `timeout 300 bats test/scripts/build-loop-orchestrator.bats`, cwd `/workspace/.claude/wt-build-loop-u4c`, exit 0, 2026-10-14T06:14:02Z (UTC), 25/25 ok.

**Evidence:** `skills/dev-cycle/SKILL.md:243-246`; `test/scripts/build-loop-orchestrator.bats:263`, `:282-297`, `:312-324`; `docs/reviews/execution-logs/u4c-i2-orchestrator-bats.log`

---

## Claim 10: U4c as-built note's row citations and its "Review i1" sentence

**Location:** `docs/working/plan-build-loop-handoff.md:344`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the rows cited in the note's as-built half (738, 739, 740, 741, 744, 775) and the i1 sentence's citations. It does not cover the note's unchanged opening list "(rows 735, 738, 739, 741, 742)", which is the original plan text.

- "rows 740, 741 discharged with them": 740 is the reader's walk cost and 741 is "The verified reader is perl in a bash string" (`override-log.md:740-741`).
- "row 739, the trust root, closed by Q-140 [1]": 739 is the main's-copy selector.
- "row 744's timeout is the Rules' stop": the Rules say "a call of any / script that the Bash tool timed out … are stops too" (`SKILL.md:50-51`).
- "(row 738)" is the canonical-copy row.
- "row 775" is questions.sh through `~/.claude/scripts`.
- "Q-140's 'only quiet routes' premise": Q-140's answer reads "both routes are hostile-class (Q-103), but they are the only quiet ones (--main-log cannot see them)" (`docs/working/questions-archive.md`, Q-140 Answer line).
- F1, F2, F4, architecture 1 and F3 match the i1 security and architecture findings that the rubric's B1, C1, C3 and B4 cite.
- "the image at the time of writing (774a0eef) predates U4a's `--land-cycle`": `/opt/claude-workflows/.manifest` reads `commit=774a0eef…`, and `grep -c land-cycle /opt/claude-workflows/scripts/build-loop.sh` prints `0`.

**Evidence:** `docs/reviews/override-log.md:738-744`, `:775`; `skills/dev-cycle/SKILL.md:50-51`; `docs/working/questions-archive.md` (Q-140); `/opt/claude-workflows/.manifest`

---

## Claim 11: "The gate needs it too (D6 runs the image copy: Q-140 [1]), as does the installed skill."

**Location:** `docs/working/plan-build-loop-handoff.md:356`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers which copy the gate runs. It does not establish what a release does on the host (see Claim 14).

Same mechanism as Claim 7: the block runs `bash "$D6_OPT/scripts/$s"` with `D6_OPT=/opt/claude-workflows` (`SKILL.md:224`, `:247`).

**Evidence:** `skills/dev-cycle/SKILL.md:224`, `:247`

---

## Claim 12: T33 row "runs the image copy's four files, each with its own lib and `questions.sh`; main's and the working tree's copies have no effect; SKILL.md holds the block once (its one copy)"

**Location:** `docs/working/plan-build-loop-handoff.md:396`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the row against the two T33 tests. It does not establish that T33 proves "no other copy" beyond its grep denylist (C10's residue).

Two of the three parts match the tests:

- "Main's and the working tree's copies have no effect": both are written as `echo main copy; exit 9` / `echo working copy; exit 9`, and every mode still answers from `$U` (`bats:266-279`).
- "Holds the block once": the test greps that the `cd WT && bash -s` line and the `D6` line each appear exactly once (`bats:257`).

"Each with its own lib and `questions.sh`" is imprecise. The test checks only that build-loop.sh sources `$U`'s lib (`[ "$l" = "lib at $U/scripts/lib/dev-cycle-read.sh" ]`, `bats:274`) and that dev-cycle.sh runs `$U`'s questions.sh (`bats:277-278`). questions.sh sources no lib (no `source` in `scripts/questions.sh`), and the lib and questions.sh are themselves two of the four files. This is the imprecision i1's Claim 21 flagged in the snippet comment. It survives here and in the test name (`bats:263`). Precise version: "build-loop.sh and dev-cycle.sh with the image's lib, dev-cycle.sh with its questions.sh". The suite passed (25/25, see Claim 9).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:255-280`; `scripts/build-loop.sh:528-531`; `scripts/dev-cycle.sh:100-103`, `:389`; `docs/reviews/execution-logs/u4c-i2-orchestrator-bats.log`

---

## Claim 13: "Since Q-140 [1] the gate waits too (D6 runs the image copy); step 0.1 files an `image-lag` entry when main's gate code is ahead of the image's `.manifest` commit."

**Location:** `docs/working/plan-build-loop-handoff.md:432`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers what step 0.1's diff tests compared with "gate code". It does not establish the check's behaviour outside claude-workflows (Claim 25).

Step 0.1 diffs `-- scripts/ skills/dev-cycle/` (`SKILL.md:285-286`). GATE_CODE is `'^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'` (`scripts/lib/dev-cycle-read.sh:1970`), and `scripts/` also holds non-gate files (`health-check.sh`, `self-improvement.sh`, `run-tests.sh` and others). Today's diff lists `scripts/health-check.sh` among its four names (`u4c-i2-image-lag.log`). So the entry also fires when only non-gate scripts differ. The test also detects "differs", not "ahead", though C is an ancestor of main today (`merge-base --is-ancestor` exit 0). Precise version: "when main's `scripts/` or `skills/dev-cycle/` differ from the image's `.manifest` commit".

**Evidence:** `skills/dev-cycle/SKILL.md:283-288`; `scripts/lib/dev-cycle-read.sh:1970`; `docs/reviews/execution-logs/u4c-i2-image-lag.log`

---

## Claim 14: Rollback 1: "the gate that runs is the image's, so a revert takes effect only after the image is rebuilt from the reverted main (`./devcontainer-config/install.sh`, host)"

**Location:** `docs/working/plan-build-loop-handoff.md:441`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the gate-code half and the named command. It does not establish the rebuild mechanics end to end (no host access).

The mechanism is right for gate code. Two qualifiers are missing:

1. install.sh does not rebuild the image by itself. `link-claude-home.sh` describes the path as "edit the repo, run install.sh, read the diff, bless, rebuild" (`devcontainer-config/link-claude-home.sh:22-23`). The rebuild happens on the next `cc-isolated` launch ("Next launch rebuilds the image", `devcontainer-config/cc-isolated.sh:356`).
2. install.sh stages "every CLAUDE_HOME_SRC entry, as committed at HEAD" of the host checkout (`devcontainer-config/install.sh:319-320`), not main as such.

Units whose files take effect on merge (`workflows/`, `plan:75`) are not delayed by the image. The sentence's "a revert" reads as covering them too. Precise version: "a revert of gate code takes effect only after install.sh from a host checkout at the reverted main and the next cc-isolated rebuild".

**Evidence:** `devcontainer-config/install.sh:11`, `:319-361`; `devcontainer-config/link-claude-home.sh:15-23`; `devcontainer-config/cc-isolated.sh:356`, `:523-525`; `docs/working/plan-build-loop-handoff.md:75`

---

## Claim 15: Rule "Every `build-loop.sh`, `dev-cycle.sh` and `questions.sh` call … it runs the root-owned image copy (Q-140 [1]), so no file or repository state a build loop writes chooses which script runs as the gate (a hostile process of this uid still reaches the shell itself, through PATH, exported functions or the session's settings …), and a gate change merged here runs from the next image release (step 0.1 checks the lag)"

**Location:** `skills/dev-cycle/SKILL.md:36-45`
**Type:** Invariant / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the narrow reading: the script path the block runs is fixed (`/opt/claude-workflows/scripts/` plus one of three literal names) and no repository input selects it. Two things are not established. First, the interpreters (outer `bash -s`, `env`, inner `bash`, `git`, `stat`) are PATH-resolved, so a uid-writable PATH entry still decides what executes. The Rule's parenthetical carves this out and i1 executed it. Second, the narrow-reading guarantee does not hold against an exported `stat` function, which defeats own() (i1 security F1).

The script choice is `[[ "$s" == build-loop.sh || "$s" == dev-cycle.sh || "$s" == questions.sh ]]` with `D6_OPT=/opt/claude-workflows` hard-coded, launched as `bash "$D6_OPT/scripts/$s" "$@"` (`SKILL.md:224`, `:230`, `:247`). No line of the block reads a path from git output to pick the script (paraphrased — no quote available because the claim covers absence: `git` output in the block feeds only the refusal tests at `:232-239`). The first PATH entry here is `/home/node/.elan/bin`, owned by node with mode 755 (`stat` run in this pass), which is the parenthetical's case. "Step 0.1 checks the lag" matches `:283-288`.

**Evidence:** `skills/dev-cycle/SKILL.md:36-45`, `:222-249`; `docs/reviews/security-review-2026-10-13-u4c-i1.md:34-48`

---

## Claim 16: "a call of any script that the Bash tool timed out, and a `refuse d6:` line, are stops too" and "`questions.sh` never runs as `~/.claude/scripts/questions.sh` (a uid-owned link; its own hints still print that path)"

**Location:** `skills/dev-cycle/SKILL.md:50-51`, `:60-61`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the wording against the block and questions.sh's usage text. It does not establish an exit-code contract for questions.sh (the Rules give one only for build-loop.sh).

questions.sh's header prints `#   ~/.claude/scripts/questions.sh check      validate both files (exit 1 on problems)` (`scripts/questions.sh:28`). The block never names `~/.claude` (T33's grep `\$HOME|~/` on non-comment lines, `bats:259`).

**Evidence:** `skills/dev-cycle/SKILL.md:50-61`; `scripts/questions.sh:28-30`; `test/scripts/build-loop-orchestrator.bats:259`

---

## Claim 17: Header "so no repository data chooses which script runs … and it cannot guard against this uid's own shell (PATH, exported functions): the plan's same-uid residual (Q-103)"

**Location:** `skills/dev-cycle/SKILL.md:200-206`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the narrowed claim (repository data does not select the script) and its stated residual. It does not establish anything about the session's settings or hooks, which the header leaves out but the Rule names.

Same code as Claim 15. "Repository data" (refs, objects, the `.git` entry) feeds only the refusal checks at `:232-239`, never the launch path at `:247` (paraphrased — no quote available because the claim covers absence of a data flow from those reads to the launch line).

**Evidence:** `skills/dev-cycle/SKILL.md:196-249`

---

## Claim 18: "It still trusts that entry and refs/heads/main for which repository and branch the script reads (a moved main is --main-log's to report)"

**Location:** `skills/dev-cycle/SKILL.md:203-204`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers what the block reads from the `.git` entry and the default-branch ref. It does not establish how each script picks its branch internally.

The block checks the ref by variable, not by the literal `refs/heads/main`: `for n in main master; do g show-ref --verify -q "refs/heads/$n" && m+="$n "; done`, then `sha="$(g rev-parse --verify -q "refs/heads/$m")"` (`:236-239`). In a master repository the trusted ref is `refs/heads/master`. The block runs git in the cwd's repository with no `--git-dir`, so the `.git` entry does pick the repository (`g()` at `:227`). Precise version: "refs/heads/main (or master)".

**Evidence:** `skills/dev-cycle/SKILL.md:227`, `:236-239`

---

## Claim 19: "Run it from the checkout the script is to read (each step names MAIN_WT, WT or GT)."

**Location:** `skills/dev-cycle/SKILL.md:207-208`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three names against the Rule. It does not cover every step's call site.

The Rule reads "runs from WT (step 0's first two from MAIN_WT; step 7's self-merge from its GT, after a / `--state` from MAIN_WT)" (`:37-38`).

**Evidence:** `skills/dev-cycle/SKILL.md:37-38`, `:207-208`

---

## Claim 20: Header refusal list, now including "an image-copy file that is missing (an image older than this skill) or not a regular file"

**Location:** `skills/dev-cycle/SKILL.md:210-217`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every `no …` call in the block against the listed causes. It does not establish that "an image older than this skill" is the only way a file goes missing.

Each `no` call maps to a listed cause:

| Cause in the header | Refusal in the code |
|---|---|
| replace ref | "refs/replace could not be listed", "a replace ref exists (F38)" |
| grafts | "the grafts path could not be read", "info/grafts exists (F38)" |
| default branch | "the default branch is not exactly one of main and master", "refs/heads/$m is a symbolic ref", "refs/heads/$m names no commit" |
| missing file | "$1 is missing" |
| not a regular file | "… is not a regular file" |
| ownership | "$1 is not root-owned, a plain path and unwritable here" |

Every refusal exits 2 through `no() { echo "refuse d6: $*"; exit 2; }`. A wrong first argument gives exit 1, with its message on stderr (`:230`). Within each file, the missing check runs before the regular-file check (`:244`). Executed: Claim 22's run and the bats suite (T36 asserts each string, `bats:285-296`).

**Evidence:** `skills/dev-cycle/SKILL.md:210-247`; `test/scripts/build-loop-orchestrator.bats:282-297`; `docs/reviews/execution-logs/u4c-i2-own.log`

---

## Claim 21: "(dev-cycle.sh, questions.sh and the read modes have none; row 548 for dev-cycle.sh)"

**Location:** `skills/dev-cycle/SKILL.md:220-221`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the row citation. It does not cover a check of every read mode.

Row 548 reads "dev-cycle.sh runs neither state_gate nor default_gate" (`docs/reviews/override-log.md:548`). The narrowed citation now matches the row's subject.

**Evidence:** `docs/reviews/override-log.md:548`

---

## Claim 22: own() refuses a missing file as "is missing" first; a symlink to nothing and a present uid-owned file get the ownership refusal

**Location:** `skills/dev-cycle/SKILL.md:228`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers missing, dangling-symlink, symlink-to-root-file, uid-owned and root-owned paths, using the exact own()/no() lines taken from SKILL.md. It does not establish behaviour as root (C11) or against an exported `stat` function (i1 F1).

```bash
# skills/dev-cycle/SKILL.md:228
own() { [[ -e "$1" || -L "$1" ]] || no "$1 is missing"; [[ ! -L "$1" && "$(stat -c %u -- "$1")" == 0 && ! -w "$1" ]] || no "$1 is not root-owned, a plain path and unwritable here"; }
```

Command: `timeout 30 bash own.sh` (which `eval`s the two lines grepped from SKILL.md), cwd the session scratchpad, exit 0, 2026-10-14T06:13:50Z (UTC). Results:

- absent → `[2] … is missing`
- dangling symlink → `[2] … is not root-owned, a plain path and unwritable here`
- symlink to `/usr/bin/env` → the same ownership refusal
- uid-owned file → the same ownership refusal
- `/usr/bin/env`, `/opt/claude-workflows/scripts/build-loop.sh`, `…/scripts/lib`, `/opt/claude-workflows` and `/` → accepted

A symlink to nothing is therefore not reported as missing, which fits the header: "missing" is an absent path, and a symlink fails "a plain path".

**Evidence:** `skills/dev-cycle/SKILL.md:225-228`; `docs/reviews/execution-logs/u4c-i2-own.log`

---

## Claim 23: "The four files the scripts run (build-loop.sh and dev-cycle.sh source the lib from their own directory; dev-cycle.sh runs questions.sh beside it)"

**Location:** `skills/dev-cycle/SKILL.md:240-242`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the sourcing and invocation sites. It does not cover dev-cycle.sh's fallback when questions.sh is absent beside it (unreachable through the block, Claim 5).

- `READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"` then `source "$READ_LIB"` (`scripts/build-loop.sh:528-531`, `scripts/dev-cycle.sh:100-103`).
- `QS="$SCRIPT_DIR/questions.sh"` (`scripts/dev-cycle.sh:389`).
- questions.sh contains no `source` line (grep on `scripts/questions.sh`, empty).

**Evidence:** `scripts/build-loop.sh:528-531`; `scripts/dev-cycle.sh:100-103`, `:389-390`

---

## Claim 24: The launch drops QUESTIONS_LIVE/QUESTIONS_ARCHIVE (`env -u … -u QUESTIONS_LIVE -u QUESTIONS_ARCHIVE bash …`)

**Location:** `skills/dev-cycle/SKILL.md:247`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the image questions.sh run through the block. It does not establish behaviour for any other environment override questions.sh might read.

questions.sh honours the variables directly: `LIVE="${QUESTIONS_LIVE:-$PROJECT_ROOT/docs/working/questions.md}"` (`scripts/questions.sh:85`). Command: `QUESTIONS_LIVE=$S/fakeq.md QUESTIONS_ARCHIVE=$S/fakeq.md timeout 60 bash -s -- questions.sh next-id < d6.bash`, where d6.bash is the block taken out with the bats awk. It ran in cwd `/workspace/.claude/wt-build-loop-u4c` at 2026-10-14T06:15:27Z (UTC), exit 0, and printed `Q-144`, the worktree's file. Run with the same variables and no block, `/opt/…/questions.sh next-id` printed `Q-001`, read from the fake file. The block therefore drops them.

**Evidence:** `skills/dev-cycle/SKILL.md:247`; `scripts/questions.sh:85-86`; `docs/reviews/execution-logs/u4c-i2-questions-env.log`

---

## Claim 25: Step 0.1's image-lag commands: "C is the `commit=` line of `/opt/claude-workflows/.manifest`; when `hg -C MAIN_WT cat-file -e 'C^{commit}'` succeeds … and `hg -C MAIN_WT diff --quiet C refs/heads/main -- scripts/ skills/dev-cycle/` exits 1 … file or update one `you: terminal` entry `image-lag` … and go on"

**Location:** `skills/dev-cycle/SKILL.md:283-288`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the commands' exit behaviour under the Rules' `hg` environment (GIT_LITERAL_PATHSPECS=1 included) and how the text fits the Rules. It does not establish two things. First, the step names no outcome when `.manifest` is missing or either command errors (exit 128): the condition is simply false and the step goes on with no entry. Second, where the entry is filed before step 0.3 creates WT; step 0.1's existing judgment entries share that timing.

Run against `/workspace` (read-only), using the Rules' `hg()` verbatim, cwd the session scratchpad (`timeout 60 bash imagelag.sh`), exit 0, at 2026-10-14T06:12:48Z (UTC). Results:

- C = `774a0eef…`.
- `cat-file -e "$C^{commit}"` exit 0.
- `diff --quiet C refs/heads/main -- scripts/ skills/dev-cycle/` exit 1, naming `scripts/build-loop.sh`, `scripts/health-check.sh`, `scripts/lib/dev-cycle-read.sh` and `skills/dev-cycle/SKILL.md`.
- `diff --quiet C C` exit 0.

Under GIT_LITERAL_PATHSPECS=1 the trailing-slash directory pathspecs still match by prefix: the same four names with literal pathspecs off, and with no trailing slash. Literal mode only stops globs: `'scripts/*.sh'` exit 0 literal and exit 1 non-literal. An unknown SHA, and a tree id peeled with `^{commit}`, both give exit 128.

The text fits the Rules. It uses the `hg -C MAIN_WT` form steps 0.2 and 1 use. The entry is `you: terminal` with one paste. It is not a stop, which agrees with the commit Notes and with the Rules' stop list (which names no image-lag stop).

**Evidence:** `skills/dev-cycle/SKILL.md:66-69`, `:283-288`; `/opt/claude-workflows/.manifest`; `docs/reviews/execution-logs/u4c-i2-image-lag.log`

---

## Claim 26: Step 0.1's inferences: "(this repository built the image)", "the gate that runs is older than main's", and the paste "`./devcontainer-config/install.sh` run from the host"

**Location:** `skills/dev-cycle/SKILL.md:284-288`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers what each test establishes. It does not establish host-side rebuild behaviour, which I could not run.

All three are directionally right, and each is broader than its test:

1. `cat-file -e C^{commit}` shows that the image's commit object is in this repository's object store (alternates included), not that this repository built the image. A fork, or any repository holding claude-workflows' history, passes it, and the manifest names the builder separately as `assembled_from=/home/magfrump/claude-workflows`. Precise version: "this repository holds the image's commit".
2. `diff --quiet` over `scripts/` exits 1 for non-gate scripts too: today's diff includes `scripts/health-check.sh` (Claim 13). So "the gate is older" over-reads a change limited to non-gate scripts.
3. The paste installs and blesses. The image is rebuilt only at the next `cc-isolated` launch (Claim 14), so running the paste alone does not make the running gate current.

**Evidence:** `skills/dev-cycle/SKILL.md:283-288`; `/opt/claude-workflows/.manifest`; `devcontainer-config/link-claude-home.sh:20-23`; `devcontainer-config/cc-isolated.sh:356`; `docs/reviews/execution-logs/u4c-i2-image-lag.log`

---

## Claim 27: Step 1: "If either fails, note it in the record and go on: … (a `refuse d6:` line is still a stop, as the Rules say)."

**Location:** `skills/dev-cycle/SKILL.md:373-375`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers agreement with the Rules' `refuse d6:` stop. It does not cover the Rules' other non-exception stop: a questions.sh call the Bash tool timed out, which the parenthetical leaves out and the Rules (`:50-51`) still make a stop.

The Rules say "a call of any / script that the Bash tool timed out, and a `refuse d6:` line, are stops too" (`:50-51`). The parenthetical agrees with this for the `refuse d6:` case.

**Evidence:** `skills/dev-cycle/SKILL.md:50-51`, `:369-375`

---

## Claim 28: "d6_copy OPT [trust]: … with trust its ownership check passes any path that exists (and refuses a missing one with the snippet's own words)"

**Location:** `test/scripts/build-loop-orchestrator.bats:229-233`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the stub against the comment and the snippet's string. It does not cover the stub's handling of a dangling symlink, which it reports as missing while the real own() reports it as an ownership refusal (Claim 22).

The stub is `own() { [[ -e "$1" ]] || no "$1 is missing"; }`, applied only when `[[ "${2:-}" != trust ]]` is false (`:236`). Its message equals the real own()'s first refusal (`SKILL.md:228`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:229-237`; `skills/dev-cycle/SKILL.md:228`

---

## Claim 29: Test "the D6 snippet refuses an image copy the uid owns or one missing a file (an older image), and never runs main's (T37, U3b3, U4c)" runs the real, unstubbed snippet

**Location:** `test/scripts/build-loop-orchestrator.bats:320-324`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the build-loop.sh file being missing, with the real own(). It does not cover missing files deeper down (questions.sh's missing case is tested only under the stub, at `:294`).

```bash
# test/scripts/build-loop-orchestrator.bats:321-323
U="$BATS_TEST_TMPDIR/opt"; opt_copy "$U"; d6_copy "$U"
d6_is "refuse d6: $U/scripts/build-loop.sh is not root-owned, a plain path and unwritable here"
rm "$U/scripts/build-loop.sh"; d6_is "refuse d6: $U/scripts/build-loop.sh is missing"
```

`d6_copy "$U"` has no second argument, so the stub is not applied. `d6_is` asserts exit 2, exact stdout and empty stderr (`:247`). The pre-fix own() would have printed the ownership refusal for an absent path (`! -L && -e && …`, in the 1bc823ea version), so this assertion tells the old code from the new. The suite passed, 25/25, including `ok 16` (Claim 9's run).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:234-237`, `:247`, `:320-324`; `docs/reviews/execution-logs/u4c-i2-orchestrator-bats.log`

---

## Claim 30: Commit message of 33ad1767

**Location:** commit `33ad1767` (message body)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each sentence against the diff `1bc823ea..33ad1767`. It does not cover the precision issues inside the changed text, which are verdicted in Claims 12-14, 18 and 26.

Each statement in the message matches the diff:

| The message says | The diff shows |
|---|---|
| The Rule and header are narrowed | Claims 15 and 17 |
| "names the trusted .git entry again" | `SKILL.md:203` |
| "a missing image file is refused as missing" | Claim 22 |
| "the launch drops QUESTIONS_LIVE/QUESTIONS_ARCHIVE" | Claim 24 |
| Step 0.1 files image-lag | Claim 25 |
| "The Rules name questions.sh throughout" | `:36`, `:50`, `:60-61` |
| "row citations (738-741)" | Claim 10 |
| Rollback is corrected | `plan:441` |
| "i1 review artifacts and override rows added" | 9 review and log files plus rows 812-817 in the diffstat |
| Notes: "the image-lag check is skill text, not a script mode" | No script changed in the range |
| Notes: "a lagging image does not stop the cycle" | Step 0.1's "and go on" |
| U5 owns the release entry | `plan:356` sits under item 12, "U5, roadmap and questions" (`plan:352`) |

**Evidence:** `git show --stat 33ad1767`; `skills/dev-cycle/SKILL.md:36-61`, `:283-288`; `docs/working/plan-build-loop-handoff.md:352-356`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
None.

### Mostly Accurate
- **Claim 3** (`rubric:57`): "all fixed in the fix commit": B2's commit-message half is Accepted-immutable (row 812), not fixed.
- **Claim 6** (`override-log.md:817`): "changed only the D6 block, its Rules and step 0.1" leaves out steps 0.4 and 1 and the deleted fallback paragraph. Step 0.4 is the one the same row cites. The conclusion ("none of those paths") holds.
- **Claim 12** (`plan:396`, and the test name at `bats:263`): "each with its own lib and questions.sh". questions.sh sources no lib, and the test checks build-loop.sh's lib and dev-cycle.sh's questions.sh.
- **Claim 13** (`plan:432`): "main's gate code is ahead": the check diffs all of `scripts/` (health-check.sh differs today) and tests "differs", not "ahead".
- **Claim 14** (`plan:441`): install.sh installs and blesses from the host checkout's HEAD; the image rebuilds at the next cc-isolated launch. Only gate-code reverts wait.
- **Claim 18** (`SKILL.md:203`): "refs/heads/main" should be "refs/heads/main (or master)".
- **Claim 26** (`SKILL.md:284-288`): `cat-file -e` shows the repository holds the image's commit, not that it built the image. The `scripts/` diff includes non-gate scripts. The paste alone does not rebuild the running image.

### Unverifiable
- **Claim 4** (`rubric:15`): "Health check passed at 1bc823ea": checking it needs a health-check run or its log; running it was out of scope.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to docs/reviews/code-fact-check-report-2026-10-13-u4c-i2.md, per the code-fact-check skill, header `**Commit:** 33ad1767` and `**Replication:** k=1 (loop pass, decision 031)`.
- Answered: yes. All six focus areas are checked. I executed step 0.1's commands against /workspace (read-only, Rules' hg), own() on six kinds of path, the block with QUESTIONS_* set, and the bats suite (25/25).
- Out of scope: scripts/health-check.sh (not run, per instruction); a root run (C11); host-side install/rebuild; the i1 critic reports' internal claims beyond the rubric's use of them.
- Escalate: Claim 26's breadth and gap: no outcome named when `.manifest` is unreadable or a command errors (exit 128 is silently skipped), and the `scripts/` diff includes non-gate files. Both are for the author/api critic, not blocking.
- Decisions I made: "row N" is read as line N of override-log.md; Claim 15's Rule counts as Verified on the narrow reading because its own parenthetical carves out PATH/exported functions; step 0.1's three over-reads are verdicted as one Mostly-accurate claim rather than split, since all three earn the same verdict.
