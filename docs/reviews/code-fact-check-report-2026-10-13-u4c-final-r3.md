# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u4c`)
**Scope:** full branch, `git diff main...feat/build-loop-u4c` (authored files: `skills/dev-cycle/SKILL.md`, `test/scripts/build-loop-orchestrator.bats`, `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `docs/working/plan-build-loop-handoff.md`, `docs/reviews/override-log.md` rows 812-819, `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md`; deleted `test/lib/d6-snippet.bash`) plus the four commit messages of `git log main..HEAD`. The i1/i2 critic reports and logs are evidence, not checked line by line.
**Commit:** 43b8d7ed
**Replication:** k=3, replicate r3 (final confirming pass; merged most-severe-wins)
**Checked:** 2026-10-13
**Total claims checked:** 41
**Summary:** 28 verified, 8 mostly accurate, 2 stale, 1 incorrect, 2 unverifiable

The hallucination pattern log (`docs/reviews/hallucination-patterns.md`) was read first. No claim matches a logged pattern (all logged entries are miscounted figures; the counts checked here, "nine per call" and "11 paths", hold). The one Incorrect is a wrong consequence in an override row, not a fabricated symbol, so the log is unchanged.

Execution logs (all under `docs/reviews/execution-logs/`; the sandbox clock reads 2026-10-14 UTC):
- `u4c-r3-orchestrator-bats.log`: `timeout 600 bats test/scripts/build-loop-orchestrator.bats`. cwd is the worktree, exit 0, 26/26 ok.
- `u4c-r3-step01.log`: step 0.1's commands run read-only against `/workspace` with the Rules' `hg` and the real `/opt/claude-workflows/.manifest`. Exit 0.
- `u4c-r3-d6-run.log`: the block extracted from SKILL.md with the test's own awk, then run in a throwaway repository against the real `/opt` image. Covers `--help`, `questions.sh open` and `dev-cycle.sh` with a planted `QUESTIONS_LIVE`, a bad first argument, a missing D6_OPT, and a run outside a repository. Exit 0.
- `u4c-r3-paste-test.log`: the paste's `test "$(git rev-parse HEAD)" = M` against `/workspace`, with the right M and with a wrong one.

Previously decided items are not re-filed. Where a claim touches one, the claim says so: row 812 (the commit's row-739 note), row 817's omissions (rubric iteration 2), C10 (T33's grep), and C11 (the -w-as-root claim).

---

## Claim 1: Rubric iteration 2: "30 claims; 22 Verified, 7 Mostly accurate, 1 Unverifiable"; critic tallies; D1-D7 "Fixed"

**Location:** `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:55-80`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the i2 fact-check counts, the three critic tallies and each D1-D7 "Fixed" status against the text at 43b8d7ed. It does not establish that the fixes are sufficient, and D9's text is Claim 4's.

The i2 report's header reads `**Total claims checked:** 30` / `**Summary:** 22 verified, 7 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable` (`docs/reviews/code-fact-check-report-2026-10-13-u4c-i2.md:8-9`). The security tally (Medium, Low, Informational, Informational at `security-review-2026-10-13-u4c-i2.md:51,65,79,91`) and the api tally (3 Inconsistent, 2 Minor, 1 Informational at `api-consistency-review-2026-10-13-u4c-i2.md:40-112`) match. The architecture tally "2 Coupling, 2 Minor" (`rubric:70`) leaves out that report's fifth finding, `#### 5. i1 Coupling finding 1 is resolved in substance` / `**Severity:** Informational` (`architecture-review-2026-10-13-u4c-i2.md:106-108`). The i1 line counts that report's Informationals ("2 Informational", `rubric:13`), so the precise version is "2 Coupling, 2 Minor, 1 Informational". Each Fixed status holds at HEAD:

- D1: `merge-base --is-ancestor C M` and `image-off-main` are at `SKILL.md:288-290`; the paste is `cd A && test "$(git rev-parse HEAD)" = M &&` (`:295`).
- D2: the path list sits on one line (`:292`), pinned by the test at `test/scripts/build-loop-orchestrator.bats:347`.
- D3: the body, paste, interim and `done` close are at `SKILL.md:293-298`; for "plan :356", see Claim 11.
- D4: "the gate that runs differs from main's" (`:293`), and a failed cat-file means "skip silently" (`:287-288`).
- D5: "its entry also gives the release paste below" (`:284`).
- D6: "no repository file or state a build loop writes" (`:42`).
- D7: "(`check` exiting 1 names entries to fix before staging)" (`:713`).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:13`, `:55-80`; `docs/reviews/architecture-review-2026-10-13-u4c-i2.md:29-108`; `skills/dev-cycle/SKILL.md:42`, `:284-298`, `:713`

---

## Claim 2: Override rows 812-816 and 818

**Location:** `docs/reviews/override-log.md:812-816`, `:818`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each row's factual statements and row citations against the code at 43b8d7ed. It does not judge the Defer or Won't-Fix decisions. Rows 817 and 819 are Claims 3 and 4.

- **812** says "Commit 1bc823ea's Notes cite row 739 for the canonical copy's home; it is row 738". 1bc823ea's Notes read "(row 739 left the home to U4)" (`git log`). Row 738 is "The canonical D6 source sits in test/lib/" and row 739 is "The snippet chooses main's copy from the repository's own data" (`override-log.md:738-739`).
- **813** says the git checks "are the only repository-state gate dev-cycle.sh and questions.sh have". Row 548 reads "dev-cycle.sh runs neither state_gate nor default_gate". `rg -n 'state_gate|default_gate|harden' scripts/questions.sh` prints nothing (paraphrased — no quote available because the claim covers absence of code: no matching grep results). The "three copies" are the lib's HARDEN, `G=(env ...` (`SKILL.md:226`) and `hg() { env ...` (`SKILL.md:68`). One test holds both to the lib (`bats:327-345`).
- **814** cites i1 security, which reads "Tested: a symlinked directory between the files and `/` ... refused" (`security-review-2026-10-13-u4c-i1.md:92`).
- **815** says "nine per call". own() holds the only `stat` (`SKILL.md:228`). It runs on four files (`:243-244`) and on five directories: `scripts/lib`, `scripts`, `/opt/claude-workflows`, `/opt` and `/` (`:246`).
- **816**: questions.sh's usage lines print `#   ~/.claude/scripts/questions.sh check ...` (`scripts/questions.sh:28-32`). Step 3's cause list reads "questions.sh missing" (`SKILL.md:432`), which the block reaches first as `refuse d6: .../questions.sh is missing` (executed, `u4c-r3-d6-run.log`).
- **818**: GATE_CODE is matched against `lp="$(lower "$p")"` (`scripts/build-loop.sh:1916`, `:1923`). `--cycle-diff` refuses "one of the dev cycle's own files, spelled in another case" (`:1928`).

**Evidence:** `docs/reviews/override-log.md:548`, `:738-739`, `:812-816`, `:818`; `skills/dev-cycle/SKILL.md:68`, `:226-246`, `:432`; `scripts/questions.sh:28-32`; `scripts/build-loop.sh:1916-1928`; `docs/reviews/security-review-2026-10-13-u4c-i1.md:92`

---

## Claim 3: Row 817: "U4c changed only the D6 block, its Rules and step 0.1, none of those paths"

**Location:** `docs/reviews/override-log.md:817`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the list of SKILL.md regions U4c changed, against `git diff main...HEAD -- skills/dev-cycle/SKILL.md`. It does not re-judge rows 808-811. The omission was already decided in the rubric's iteration 2 ("Row 817 ... also omits steps 0.4 and 1 and the deleted fallback"); it is not re-filed. The one new item is the step 9 sentence added after the row was written.

Paraphrased — no quote available because the claim is about which hunks a diff touches. The SKILL.md diff has hunks in the intro (the fallback was deleted), the Rules, the D6 block, step 0.1, step 0.4 (`:357-358`), step 1 (`:382-386`) and step 9 (`:712-713`, "(`check` exiting 1 names entries to fix before staging)"). The step 9 sentence was added at 43b8d7ed/f2cc21e6, after row 817 (added at 33ad1767). None of the extra regions touches the paths rows 808-811 name: the `unless WT's questions files hold one` rule, the drop reading, `refuse main-log`'s `Main at:`, and approved `stopped` filing. So the conclusion holds.

**Evidence:** `docs/reviews/override-log.md:817`; `skills/dev-cycle/SKILL.md:357-358`, `:382-386`, `:712-713`; `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:63-64`

---

## Claim 4: Row 819 and rubric D9: "deleting C's objects turns the check into a record note"

**Location:** `docs/reviews/override-log.md:819`; `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:82`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers what step 0.1 prescribes at 43b8d7ed when the repository lacks C's commit. It does not establish the fork case's first half ("compares unrelated gate code"), which follows from the text, or whether the Won't-Fix decision should change.

Row 819 and the rubric both add, in the same commit (43b8d7ed), that deleting C's objects drops the check to a record note. The same commit's step 0.1 says the opposite:

```
# skills/dev-cycle/SKILL.md:287-288
M main's commit. If `hg -C MAIN_WT cat-file -e 'C^{commit}'` fails, the image was not
built here: skip silently. Else, ...
```

The record note is only for "A missing `.manifest` or line, or any other exit" (`:298-299`). The row was true of f2cc21e6's text, where a failed cat-file fell to "any other exit: note it in the record". D4's fix moved it to the silent skip.

Executed (`u4c-r3-step01.log`): `hg cat-file -e` on an absent commit exits 128 with `fatal: Not a valid object name`. Under `:287-288` that branch writes nothing. So deleting C's objects leaves no trace in the record, which is weaker than the row's rationale says. A reader weighing the Won't-Fix would think the deletion is visible. The fix is a new appended row (rows are append-only) and the rubric's D9 wording: "turns the check into a silent skip". The Flow's "a skipped step is recorded, never silently dropped" (`:258-259`) covers steps, not this sub-check.

**Evidence:** `docs/reviews/override-log.md:819`; `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:77`, `:82`; `skills/dev-cycle/SKILL.md:287-288`, `:298-299`; `git show f2cc21e6:skills/dev-cycle/SKILL.md` (step 0.1); `docs/reviews/execution-logs/u4c-r3-step01.log` (cmd `timeout 60 bash step01.sh`, cwd scratchpad, exit 0, 2026-10-14T06:36:34Z)

---

## Claim 5: Plan D5 item 3: "D6 runs the image copy built from main (Q-140 [1]), so it is live at the next release, not the next merge"

**Location:** `docs/working/plan-build-loop-handoff.md:71`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the image's source commit and the "next release" conclusion. It does not establish when releases happen. i2 Claim 7 Verified this sentence at 33ad1767, before i2 security F1 / rubric D1 showed the image is built from the host checkout's HEAD. 43b8d7ed changed SKILL.md on that basis and left this line, so the basis has moved.

install.sh builds the image from HEAD, not from main:

```
# devcontainer-config/install.sh:185-186, 335
head_commit() {
  if ! repo_git rev-parse --verify -q 'HEAD^{commit}'; then
...
  commit="$(head_commit)" || exit 1
```

The branch's own SKILL.md now says "the image is the gate, built from the host checkout's HEAD" (`SKILL.md:285`). It files `image-off-main` when C is not on main (`:288-290`), so "built from main" is the intended release, not a guarantee. The conclusion ("live at the next release") holds. The precise version is "the image copy, built from the host checkout's HEAD (main's commit when released by step 0.1's paste)".

**Evidence:** `docs/working/plan-build-loop-handoff.md:71`; `devcontainer-config/install.sh:185-190`, `:319-361`; `skills/dev-cycle/SKILL.md:285-296`

---

## Claim 6: Plan D6 heading: "The snippet is inline in the installed SKILL.md, which is the root-owned image copy. It never trusts a file the uid can write"

**Location:** `docs/working/plan-build-loop-handoff.md:77`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the files the snippet runs (true) and the files it reads to decide (not all root-owned). It does not cover the same-uid shell residual, which SKILL.md names separately.

The line was rewritten on this branch (the heading's "root-owned image copy (Q-140 [1]; ...)"). Under the narrow reading, "the scripts it runs", it holds. The scripts are `$D6_OPT/scripts/$s`, checked root-owned and unwritable (`SKILL.md:243-247`). Under the broad reading it does not hold, and the block's own header says so:

```
# skills/dev-cycle/SKILL.md:203-204
# scripts). It still trusts that entry and the default branch's ref for which repository
# and branch the script reads
```

The `.git` entry and `refs/heads/main` are files the uid can write. The test writes the ref file directly (`echo "$c" > .git/refs/heads/main`, `bats:292`). The precise version is "It never runs a file the uid can write", or "never trusts one to choose the script".

**Evidence:** `docs/working/plan-build-loop-handoff.md:77`; `skills/dev-cycle/SKILL.md:203-206`, `:243-247`; `test/scripts/build-loop-orchestrator.bats:291-292`

---

## Claim 7: Plan D6 bullets: the replace-ref/grafts precondition, the "Superseded by Q-140 [1]" bullet ("extracts nothing from MAIN_SHA, so the two bullets above and this bullet's root-commit test no longer apply"), and "The digest runs the same way"

**Location:** `docs/working/plan-build-loop-handoff.md:78-82`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each bullet against the block at 43b8d7ed. It does not establish the history ("as first written") beyond the deleted file in the diff.

The block lists replace refs with `x="$(g for-each-ref --format='%(refname)' refs/replace/)"`, and `G` carries `GIT_NO_REPLACE_OBJECTS=1` (`SKILL.md:226`, `:232`). It refuses grafts at `:234-235`. Nothing extracts from MAIN_SHA: the block has no `cat-file blob`, `ls-tree` or `mktemp` outside comments (the grep in `bats:259`, which passed in `u4c-r3-orchestrator-bats.log`). The "two bullets above" are the extraction (`:79`) and hash-object (`:80`) bullets. The digest runs through the same block (`SKILL.md:341`, "`dev-cycle.sh` through the D6 block from WT").

**Evidence:** `docs/working/plan-build-loop-handoff.md:78-82`; `skills/dev-cycle/SKILL.md:226-247`, `:341`; `test/scripts/build-loop-orchestrator.bats:259`

---

## Claim 8: Plan F38 row: "The snippet refuses replace refs and grafts and compares hashes (T36)"

**Location:** `docs/working/plan-build-loop-handoff.md:156`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the "compares hashes" clause. The refusal clause holds (Claim 7). It does not establish whether F38's "covered" status changes, which is the author's call.

The row is unchanged on this branch, but its mechanism was deleted here. The old snippet's reader died with `"$id does not hash to its id\n"` (deleted `test/lib/d6-snippet.bash`, diff). The new block hashes nothing: it has no `hash-object`, `sha1_hex` or `cat-file --batch` (`SKILL.md:222-249`; the `bats:259` grep). The T36 hash tests were deleted with the reader (diff of `bats`: the "rewritten in place" tests). Now: "The snippet refuses replace refs and grafts (T36); nothing is extracted, so no hash is compared." The adjacent D6 bullet `:80` is marked superseded, but this row is not.

**Evidence:** `docs/working/plan-build-loop-handoff.md:80-81`, `:156`; `skills/dev-cycle/SKILL.md:222-249`; `test/scripts/build-loop-orchestrator.bats:259`

---

## Claim 9: Plan F39/F40 rows: "`/opt/...` by absolute path with an ownership check, in every repository ... (T37)"; "Nothing is extracted: the image copy's own layout, its four files checked (T33, T36)"

**Location:** `docs/working/plan-build-loop-handoff.md:157-158`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the run path, the ownership check and the four-file check with their tests. It does not establish the -w-as-root clause (Claim 23).

The block hard-codes `D6_OPT=/opt/claude-workflows` (`SKILL.md:224`) and runs `bash "$D6_OPT/scripts/$s" "$@"` (`:247`). It checks the four files and their directories with own() (`:243-246`).

Executed (`u4c-r3-d6-run.log`): `build-loop.sh --help` through the block printed output identical to running `/opt/claude-workflows/scripts/build-loop.sh --help` directly. T37 (`bats:312`, `:320`) and T36's missing and non-regular cases (`bats:294-295`) pass (`u4c-r3-orchestrator-bats.log`, ok 13, 15, 16).

**Evidence:** `docs/working/plan-build-loop-handoff.md:157-158`; `skills/dev-cycle/SKILL.md:224`, `:243-247`; `test/scripts/build-loop-orchestrator.bats:294-295`, `:312-325`; `docs/reviews/execution-logs/u4c-r3-d6-run.log`, `docs/reviews/execution-logs/u4c-r3-orchestrator-bats.log`

---

## Claim 10: Plan U4c as-built note (row citations, "a missing image file is refused as missing; the launch drops QUESTIONS_LIVE/QUESTIONS_ARCHIVE", "the image at the time of writing (774a0eef) predates U4a's `--land-cycle`")

**Location:** `docs/working/plan-build-loop-handoff.md:344`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the note's mechanism statements, its row numbers (738-742, 744, 775) and the image claim. The note records i1's fixes under "Review i1:" and does not mention i2's `image-off-main`; that is an omission of scope, not an error. It does not establish i2's fixes (Claims 1, 25-27).

The rows are right:
- 738 is the canonical copy and 739 the trust root.
- 740 and 741 are the reader's cost and seam.
- 744 is "The snippet has no timeout", which the Rules now treat as a stop ("a call the Bash tool timed out", `SKILL.md:48-51`).
- 775 is questions.sh through `~/.claude/scripts`.

Executed (`u4c-r3-d6-run.log`): D6_OPT at a missing directory printed `refuse d6: /nonexistent-cw/scripts/build-loop.sh is missing` (exit 2). With a planted `QUESTIONS_LIVE`, `questions.sh open` through the block printed nothing (exit 0), while the direct run printed `Q-001  you: judgment   planted`. `grep -c land-cycle /opt/claude-workflows/scripts/build-loop.sh` printed `0`, and the manifest reads `commit=774a0eef3ff85beb69695e014ab840f70648f193`.

**Evidence:** `docs/working/plan-build-loop-handoff.md:344`; `docs/reviews/override-log.md:738-744`, `:775`; `skills/dev-cycle/SKILL.md:48-51`, `:228`, `:247`; `docs/reviews/execution-logs/u4c-r3-d6-run.log`

---

## Claim 11: Plan :356 ("The gate needs it too (D6 runs the image copy: Q-140 [1]) ... U5 makes the release entry the `image-lag` entry's body") and :432 ("step 0.1 files an `image-lag` entry when main's GATE_CODE paths differ from the image's `.manifest` commit")

**Location:** `docs/working/plan-build-loop-handoff.md:356`, `:432`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers agreement with SKILL.md step 0.1 at 43b8d7ed. It does not establish U5's future work. ":432" omits step 0.1's other gates (C absent from the repository: skip; C off main: `image-off-main`), which a reader of the Risks line would assume are absent.

Step 0.1 compares `hg -C MAIN_WT diff --quiet C M -- PATHS`, PATHS being GATE_CODE's, and files `image-lag` on exit 1 (`SKILL.md:291-294`). It runs that diff only after the cat-file and is-ancestor gates (`:287-290`). The entry holds the paste (`:295-296`), which ":356" proposes as U5's release body.

**Evidence:** `docs/working/plan-build-loop-handoff.md:356`, `:432`; `skills/dev-cycle/SKILL.md:285-299`

---

## Claim 12: Plan T27 row: "the D6 snippet's copy refuses the same tip | refuse from main's copy"

**Location:** `docs/working/plan-build-loop-handoff.md:394`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the expected-result column. It does not establish T27's behavior, which passes (Claim 35).

This branch renamed the test to "the D6 snippet's image copy refuses the same tip (T27, U3b3)" (`bats:299`). It now runs the stand-in image at `$U` (`d6_setup`, `bats:241-244`). The block never runs main's copy (`SKILL.md:199-200`, "never / main's copy"). The row still reads "refuse from main's copy" and was not updated. Now: "refuse from the image copy".

**Evidence:** `docs/working/plan-build-loop-handoff.md:394`; `test/scripts/build-loop-orchestrator.bats:241-244`, `:299`; `skills/dev-cycle/SKILL.md:199-200`

---

## Claim 13: Plan T33 row: "runs the image copy's four files (build-loop.sh and dev-cycle.sh with their own lib, dev-cycle.sh with its own `questions.sh`); main's and the working tree's copies have no effect; SKILL.md holds the block once"

**Location:** `docs/working/plan-build-loop-handoff.md:396`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two T33 tests at 43b8d7ed. They run a uid-owned stand-in with own() stubbed, not the root-owned image; the real image is T37's. dev-cycle.sh's own lib is shown only indirectly: main's and the working tree's libs `exit 9`, and the call exits 0.

Test 12 (`bats:263-280`) writes `echo main copy; exit 9` into main's and the working tree's four files. It requires `lib at $U/scripts/lib/dev-cycle-read.sh` on every stderr line of `build-loop.sh --settings`. It requires `- Q-001  trigger  from-opt` in the digest and `Q-001  trigger  from-opt` from `questions.sh open`. Test 11 (`bats:255-261`) requires exactly one `<<'D6'` line and one `^D6$` line. Both pass (ok 11, 12).

**Evidence:** `docs/working/plan-build-loop-handoff.md:396`; `test/scripts/build-loop-orchestrator.bats:255-280`; `docs/reviews/execution-logs/u4c-r3-orchestrator-bats.log`

---

## Claim 14: Plan T37 row: "A non-claude-workflows fixture repo ... → the snippet picks the `/opt` path (stubbed), not main's; a uid-owned stub dir → refuse"

**Location:** `docs/working/plan-build-loop-handoff.md:400`
**Type:** Staleness
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the row against the two T37 tests. The row is unchanged on this branch; its "(stubbed)" was already loose before U4c. It does not establish anything about T36.

T37's first test runs the real `/opt` and skips without it: `[[ -f "$O/scripts/build-loop.sh" && "$(stat -c %u "$O/scripts")" == 0 ]] || skip` (`bats:313-314`). So the `/opt` path is not stubbed. The test names dropped "outside claude-workflows" (`bats:312`, `:320`) because the choice no longer depends on the repository, so "non-claude-workflows" is no longer a condition. The second test now also refuses a missing file (`bats:324`). Precise version: "a fixture repo with scripts/build-loop.sh on main → the snippet runs the real /opt copy (skipped without one), not main's; a uid-owned copy, or one missing a file → refuse".

**Evidence:** `docs/working/plan-build-loop-handoff.md:400`; `test/scripts/build-loop-orchestrator.bats:312-325`

---

## Claim 15: Plan Rollback 1: "the gate that runs is the image's, so a revert of gate code takes effect only after the image is rebuilt from the reverted main (the host's `./devcontainer-config/install.sh`, then the next sandbox launch)"

**Location:** `docs/working/plan-build-loop-handoff.md:441`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the run path and the release route as the code describes it. It does not establish that a launch rebuilds the image on the host, which cannot be observed here; see Claim 27c.

The block runs only `$D6_OPT/scripts/$s` (`SKILL.md:247`). install.sh stages `git archive HEAD` into `devcontainer-config/claude-home` (`install.sh:319-336`, `:498`). The Dockerfile has `COPY claude-home/ /opt/claude-workflows/` (`Dockerfile:500`). cc-isolated says "`devcontainer up` reuses an existing container and never rebuilds, so after a re-bless ... main() does that when this check fails" (`cc-isolated.sh:523-526`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:441`; `skills/dev-cycle/SKILL.md:247`; `devcontainer-config/install.sh:319-361`, `:498`; `devcontainer-config/Dockerfile:500`; `devcontainer-config/cc-isolated.sh:523-526`

---

## Claim 16: store_check's comment after U4c (the D6-reader parenthetical removed; "rows 492, 503")

**Location:** `scripts/build-loop.sh:1042-1043`
**Type:** Staleness / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the edited sentence and the removal of the dangling reference. It does not re-verify the rest of store_check's comment, which this branch did not change.

The comment now reads `# store_check [--main] REV...: the objects of REV a decision reads hash to their ids` / `# and have one copy each (rows 492, 503). git checks no hash when it reads an` (`:1042-1043`). Rows 492 and 503 are the rewritten-loose-object rows (`override-log.md:492`, `:503`). Outside review docs and historical working notes, `rg -n 'd6-snippet|D6_ROOT|verified reader'` finds only the T33 test's own absence checks (`bats:259-260`); paraphrased — no quote available because the claim covers absence of code (no matching grep results).

**Evidence:** `scripts/build-loop.sh:1042-1043`; `docs/reviews/override-log.md:492`, `:503`; `test/scripts/build-loop-orchestrator.bats:259-260`

---

## Claim 17: GATE_CODE comment: "The scripts because the image copy built from main runs every merge after the next release (plan D6, D5 item 3; Q-140 [1]); skills/dev-cycle/ because its SKILL.md holds the D6 snippet that runs the gate (U4c; plan D4, F52). Both reach a session only from a release"

**Location:** `scripts/lib/dev-cycle-read.sh:1962-1967`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers why each GATE_CODE alternative is on the list. It does not cover a loop's advisory `--check`, which runs a working-tree copy and decides nothing. i1 Claim 10 Verified this before rubric D1; the "built from main" basis has since changed (Claim 5).

The skill half holds: the block is in SKILL.md (`SKILL.md:195-254`), and sessions load the skill from the image (`~/.claude/scripts -> /opt/claude-workflows/scripts`, and likewise the skills, observed with `ls -ld`). The script half's "built from main" is the same imprecision as Claim 5. The image is built from the host checkout's HEAD (`install.sh:335`), and step 0.1 now treats an off-main image as its own case (`SKILL.md:288-290`). Precise version: "the image copy (built from the host checkout's HEAD, main's commit on a clean release)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1962-1970`; `devcontainer-config/install.sh:335`; `skills/dev-cycle/SKILL.md:285-290`

---

## Claim 18: Rule: "Every `build-loop.sh`, `dev-cycle.sh` and `questions.sh` call runs from WT (step 0's first two from MAIN_WT; step 7's self-merge from its GT, after a `--state` from MAIN_WT) ... In every repository, claude-workflows too, it runs the root-owned image copy (Q-140 [1]), so no repository file or state a build loop writes chooses which script runs as the gate (a hostile process of this uid still reaches the shell itself, through PATH, exported functions or the session's settings ...)"

**Location:** `skills/dev-cycle/SKILL.md:36-45`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers which file runs and each call site's consistency with the call form: step 0.1/0.2 from MAIN_WT (`:278`, `:300`), the digest from WT (`:341`), step 1's questions.sh (`:382-383`), step 7's GT (`:562-566`) and step 9's `questions.sh index`/`check` "in WT" (`:712`). It does not establish that repository state cannot make the block refuse (it can, by design), nor the shell residual it names.

The script path is `bash "$D6_OPT/scripts/$s"`, with `s` limited to three literals (`:230`, `:247`). Nothing read from the repository enters that path. Repository reads only gate a refusal (`:232-239`). Executed: test 12's main and working-tree copies (`exit 9`) never ran (ok 12). The block's `--help` equals the image's (`u4c-r3-d6-run.log`). `env`, `stat`, `git` and `bash` are found by name (`:226`, `:228`, `:247`), which is the PATH residual the Rule names. Step 7: "`--state` (from MAIN_WT, ...), then `hg -C MAIN_WT worktree add --detach GT`" (`:563-564`). No call site in SKILL.md spells `~/.claude/scripts/` except the Rule's own prohibitions (`:40`, `:61`); `grep -n '~/.claude/scripts'` (paraphrased — no quote available because the claim covers absence of other matches).

**Evidence:** `skills/dev-cycle/SKILL.md:36-45`, `:226-247`, `:278`, `:300`, `:341`, `:382-383`, `:562-566`, `:712`; `docs/reviews/execution-logs/u4c-r3-d6-run.log`; `docs/reviews/execution-logs/u4c-r3-orchestrator-bats.log`

---

## Claim 19: Rule: "`dev-cycle.sh`'s check modes follow the paths rule below, but a call of any script that the Bash tool timed out, and a `refuse d6:` line, are stops too ... `questions.sh` never runs as `~/.claude/scripts/questions.sh` (a uid-owned link; its own hints still print that path)"

**Location:** `skills/dev-cycle/SKILL.md:50-61`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the link's ownership, the hint text and the stop wording's consistency with step 1 (`:385-386`). It does not establish the stop handling at run time (skill prose, no script).

`ls -ld ~/.claude/scripts` printed `lrwxrwxrwx 1 node node ... /home/node/.claude/scripts -> /opt/claude-workflows/scripts`. `id -u` is 1000, which is the link's owner. questions.sh's usage prints `#   ~/.claude/scripts/questions.sh check ...` (`scripts/questions.sh:28`). Step 1 repeats "(a `refuse d6:` line / or a timed-out call is still a stop, as the Rules say)" (`:385-386`).

**Evidence:** `skills/dev-cycle/SKILL.md:50-61`, `:385-386`; `scripts/questions.sh:28-32`

---

## Claim 20: "The canonical copy: every run pastes the lines between the `bash -s` line and the `D6` line below, byte for byte (a test reads them from this file) ... the block's header lists every refusal."

**Location:** `skills/dev-cycle/SKILL.md:191-193`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the extraction (the test's awk yields exactly `:197-252`) and the match between refusal messages and the header list (Claim 22). It does not establish that an orchestrator pastes it unaltered.

The test's own awk (`bats:236`), run on SKILL.md, wrote 56 lines. `diff <(sed -n 197,252p SKILL.md) d6.bash` printed nothing ("extract-equals-197-252 (diff exit 0)", appended to `u4c-r3-d6-run.log`). The ten `no "..."` messages (`:225-246`) all fall under the header's list (`:210-217`); see Claim 22.

**Evidence:** `skills/dev-cycle/SKILL.md:191-253`; `test/scripts/build-loop-orchestrator.bats:234-239`; `docs/reviews/execution-logs/u4c-r3-d6-run.log`

---

## Claim 21: Block header trust statements: "never main's copy, a working-tree copy or ~/.claude/scripts, so no repository data chooses which script runs ... It still trusts that entry and the default branch's ref for which repository and branch the script reads ... and it cannot guard against this uid's own shell (PATH, exported functions): the plan's same-uid residual (Q-103) ... Run it from the checkout the script is to read (each step names MAIN_WT, WT or GT)"

**Location:** `skills/dev-cycle/SKILL.md:197-209`
**Type:** Invariant / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers what chooses the script and what the block trusts. It does not establish that the residual list (PATH, exported functions) is exhaustive. The Rule (`:43-44`) adds "the session's settings".

The run line is `bash "$D6_OPT/scripts/$s" "$@"` (`:247`). The git calls use the caller's cwd with no `-C` or `GIT_DIR` (`:226-227`), so the `.git` entry picks the repository. The branch comes from `g show-ref --verify -q "refs/heads/$n"` and `g rev-parse --verify -q "refs/heads/$m"` (`:236-239`), which read the ref without checking who wrote it. `env`, `stat`, `bash` and `git` resolve through PATH (`:226`, `:228`, `:247`). The steps name MAIN_WT (`:278`, `:300`), WT (`:341`, `:383`) and GT (`:563-564`).

**Evidence:** `skills/dev-cycle/SKILL.md:197-209`, `:226-247`, `:278`, `:300`, `:341`, `:383`, `:563-564`

---

## Claim 22: Header exit list: "2 and one 'refuse d6: WHY' line on stdout, with nothing run, for a replace ref, info/grafts, a default branch that is not exactly one plain main or master or whose ref names no commit itself, an image-copy file that is missing (an image older than this skill) or not a regular file, or one of those files or a directory above them that is not root-owned, a plain path and unwritable here ..., or a git read that fails (git may add a line on stderr); 1 for another first argument"

**Location:** `skills/dev-cycle/SKILL.md:210-217`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every `no` call in `d6()` against the list, and each case's execution. It does not cover the "-w as root" parenthetical (Claim 23).

The messages map one to one:
- `refs/replace could not be listed` and `the grafts path could not be read`: a git read fails.
- `a replace ref exists (F38)` and `info/grafts exists (F38)`.
- `not exactly one of main and master` and `is a symbolic ref`: "plain".
- `names no commit`.
- `is missing`, `is not a regular file`, and `is not root-owned, a plain path and unwritable here`.

These are at `:232-246`. Executed in the suite (ok 13, 16): the replace refs, grafts, master, symbolic ref, tag ref, missing file (stubbed and real own()) and directory-as-file cases each give `d6_is` with an empty stderr. Executed directly (`u4c-r3-d6-run.log`): outside a repository it printed `fatal: not a git repository ...` on stderr and `refuse d6: refs/replace could not be listed`, exit 2. A first argument `health-check.sh` printed `d6: the first argument is build-loop.sh, dev-cycle.sh or questions.sh` with exit 1.

**Evidence:** `skills/dev-cycle/SKILL.md:210-217`, `:225-246`; `test/scripts/build-loop-orchestrator.bats:282-297`, `:320-325`; `docs/reviews/execution-logs/u4c-r3-d6-run.log`; `docs/reviews/execution-logs/u4c-r3-orchestrator-bats.log`

---

## Claim 23: "(the -w test makes a run as root refuse unless the mount is read-only)"

**Location:** `skills/dev-cycle/SKILL.md:215`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers nothing beyond the reading of own(). It needs a root run, which this sandbox cannot do (uid 1000). This is the rubric's open C11, not re-filed.

own() requires `! -w "$1"` (`:228`). bash's `-w` for root ignores mode bits except on a read-only filesystem. That is a fact about the runtime, which execution is required to confirm. The blocker is that there is no root here.

**Evidence:** `skills/dev-cycle/SKILL.md:215`, `:228`; `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:50`

---

## Claim 24: "Its git carries the lib's HARDEN pairs and git_harden's environment (G; a test pins the lists equal). These checks come before, not instead of, build-loop.sh's own state and default-branch gates in its gated modes (dev-cycle.sh, questions.sh and the read modes have none; row 548 for dev-cycle.sh)."

**Location:** `skills/dev-cycle/SKILL.md:217-221`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the pin test, row 548, and questions.sh having no gate. It does not re-verify which build-loop.sh modes are gated.

The test now greps `G=(env ` from SKILL.md exactly once and compares its `-c` pairs and `GIT_*` set to the lib's: `[ "$(grep -c '^  G=(env ' "$REPO_ROOT/skills/dev-cycle/SKILL.md")" -eq 1 ]` (`bats:340`). It passes (ok 17). Row 548 reads "dev-cycle.sh runs neither state_gate nor default_gate" (`override-log.md:548`). questions.sh has no gate call (Claim 2, row 813).

**Evidence:** `skills/dev-cycle/SKILL.md:217-221`; `test/scripts/build-loop-orchestrator.bats:327-345`; `docs/reviews/override-log.md:548`; `docs/reviews/execution-logs/u4c-r3-orchestrator-bats.log`

---

## Claim 25: Block comment and launch: "The four files the scripts run (build-loop.sh and dev-cycle.sh source the lib from their own directory; dev-cycle.sh runs questions.sh beside it), then every directory from scripts/lib up to /." and `env -u ... -u QUESTIONS_LIVE -u QUESTIONS_ARCHIVE bash ...`

**Location:** `skills/dev-cycle/SKILL.md:240-247`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the scripts' lookups, the directory walk's reach, and the effect of the env -u list on questions.sh directly and through dev-cycle.sh. It does not cover other environment variables questions.sh or the lib read.

The two scripts look up their lib and questions.sh like this:

```
# scripts/dev-cycle.sh:95, 100, 389-390
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  # before the cd: relative paths work
READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"
QS="$SCRIPT_DIR/questions.sh"
[[ -f "$QS" ]] || QS="$HOME/.claude/scripts/questions.sh"
```

build-loop.sh does the same at `:523`, `:527`. The `~/.claude/scripts` fallback is unreachable through the block, which refuses a non-regular questions.sh first (`SKILL.md:244`). The walk `x="${x%/*}"; x="${x:-/}"` visits `scripts/lib`, `scripts`, `/opt/claude-workflows`, `/opt` and `/`, then stops at `/` (`:246`). questions.sh reads `LIVE="${QUESTIONS_LIVE:-$PROJECT_ROOT/docs/working/questions.md}"` (`scripts/questions.sh:85`).

Executed (`u4c-r3-d6-run.log`), against the real `/opt` image with `QUESTIONS_LIVE` set to a file holding an open Q-001:
- the block's `questions.sh open` printed nothing;
- the direct run printed `Q-001  you: judgment   planted`;
- the block's `dev-cycle.sh` section 3 printed `None open.` / `Open by route: none`.

**Evidence:** `skills/dev-cycle/SKILL.md:240-247`; `scripts/dev-cycle.sh:95-104`, `:389-390`; `scripts/build-loop.sh:523-531`; `scripts/questions.sh:85-86`; `docs/reviews/execution-logs/u4c-r3-d6-run.log` (cmd `timeout 120 bash run-d6.sh`, cwd worktree, exit 0, 2026-10-14T06:38:33Z)

---

## Claim 26: Step 0.1: "(a `refuse d6:` naming a missing image file means an image older than this skill: its entry also gives the release paste below)"

**Location:** `skills/dev-cycle/SKILL.md:283-284`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the cause ("older than this skill"). The skill now requires questions.sh in the image, which images do hold, so the inference holds for this skill's four files. It does not establish that no other cause yields "is missing", such as a broken mount.

own() prints `"$1 is missing"` only when `! -e && ! -L` (`:228`). The four files are those the skill requires (`:243`). The current image has all four (`ls -la /opt/claude-workflows/scripts`, observed).

**Evidence:** `skills/dev-cycle/SKILL.md:228`, `:243-244`, `:283-284`

---

## Claim 27a: Step 0.1's branch sequence: "C and A are the `commit=` and `assembled_from=` lines ... If `hg -C MAIN_WT cat-file -e 'C^{commit}'` fails, the image was not built here: skip silently. Else, if `... merge-base --is-ancestor C M` exits 1, the gate that runs was built off main ... Else run `hg -C MAIN_WT diff --quiet C M -- PATHS` ... Exit 1: the gate that runs differs from main's ... the changed names (the same diff with `--name-only`) ... Exit 0: an open `image-lag` entry is answered `done`"

**Location:** `skills/dev-cycle/SKILL.md:285-299`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers what each command establishes, run against `/workspace` with the Rules' `hg` (including `GIT_LITERAL_PATHSPECS=1`) and the real manifest. It does not cover what an `is-ancestor` exit other than 0 or 1 does: it falls to the diff, and the "any other exit" sentence covers that only loosely. Row 819's wording about the skip is Claim 4.

Executed (`u4c-r3-step01.log`, 2026-10-14T06:36:34Z):
- C=`774a0eef…` and A=`/home/magfrump/claude-workflows`; M=`2aaf97b4…`.
- `cat-file -e` exits 0, and exits 128 on an absent id (the skip branch).
- `is-ancestor C M` exits 0. The branch tip `43b8d7ed`, which is not on main, exits 1 (the `image-off-main` branch).
- `diff --quiet` over the five paths exits 1. `--name-only` gives `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh` and `skills/dev-cycle/SKILL.md`.
- `scripts/lib/` with literal pathspecs matched `scripts/lib/dev-cycle-read.sh`.
- Diffing all of `scripts/` adds `scripts/health-check.sh`, which f2cc21e6's narrowing excludes.

So the image runs gate code that differs from main's today, and `image-lag` would be filed.

**Evidence:** `skills/dev-cycle/SKILL.md:285-299`; `/opt/claude-workflows/.manifest` (`commit=774a0eef3ff85beb69695e014ab840f70648f193`, `assembled_from=/home/magfrump/claude-workflows`); `docs/reviews/execution-logs/u4c-r3-step01.log` (cmd `timeout 60 bash step01.sh`, cwd scratchpad `fc-r3`, exit 0)

---

## Claim 27b: The paste "`cd A && test "$(git rev-parse HEAD)" = M && ./devcontainer-config/install.sh`" checks the host checkout is at main's commit before install.sh (the image is "built from the host checkout's HEAD"; A is the host checkout)

**Location:** `skills/dev-cycle/SKILL.md:285`, `:295-296`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the guard's semantics and that install.sh stages A's HEAD with `assembled_from` = A. It does not run install.sh (host only; Claim 27c). `/workspace` stood in for A for the guard. That A and `/workspace` are one repository is inferred, not observed.

install.sh sets `REPO_ROOT="$(cd "$SRC/.." && pwd)"` (`install.sh:112`). It stages `commit="$(head_commit)"` (`:335`) from `repo_git rev-parse --verify -q 'HEAD^{commit}'` (`:186`) and writes `echo "assembled_from=$REPO_ROOT"` (`:360`). So `cd A && ./devcontainer-config/install.sh` stages A's HEAD. Executed (`u4c-r3-paste-test.log`): the guard exits 0 with M = main's commit and 1 with a wrong M, so `&&` runs install.sh only at M.

**Evidence:** `devcontainer-config/install.sh:112`, `:184-191`, `:329-361`; `docs/reviews/execution-logs/u4c-r3-paste-test.log` (cwd `/workspace`, exit 0 / 1, 2026-10-14T06:44:40Z)

---

## Claim 27c: "(host; then a new sandbox launch)": the paste followed by a launch puts main's gate into `/opt`

**Location:** `skills/dev-cycle/SKILL.md:296`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the documented route only. Running install.sh and a launch needs the host, so execution is required and blocked. Statically the route is consistent (Claim 15).

install.sh stages into `devcontainer-config/claude-home` (`install.sh:498`), and the Dockerfile copies `claude-home/` to `/opt/claude-workflows/` (`Dockerfile:500`). cc-isolated rebuilds when the blessed config hash differs (`cc-isolated.sh:523-526`). The blocker is that there is no host shell or container runtime in the sandbox.

**Evidence:** `devcontainer-config/install.sh:498`, `:606`; `devcontainer-config/Dockerfile:500-520`; `devcontainer-config/cc-isolated.sh:523-532`

---

## Claim 28: Step 0.4: "Here and above, a cycle you know ran is one that reached step 9's land; an iteration that stopped does not count (U4b2 confirm3 F1)"

**Location:** `skills/dev-cycle/SKILL.md:357-358`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the citation and the sentence's reach ("Here and above" covers both bullets at `:349-358`). It does not establish orchestrator behavior.

Row 807 reads "Step 0.4's 'last cycle you know ran' could take a stop iteration's day" (`override-log.md:807`). Both bullets use "the last cycle you know ran" (`:353-354`, `:355`).

**Evidence:** `skills/dev-cycle/SKILL.md:349-358`; `docs/reviews/override-log.md:807`

---

## Claim 29: Step 1: "run `questions.sh init` (it creates only what is missing) and then `questions.sh archive` (it also reindexes) through the D6 block from WT"

**Location:** `skills/dev-cycle/SKILL.md:382-386`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that questions.sh is an allowed first argument and runs from the image. It does not re-verify init's and archive's own semantics, which this branch did not change.

The allowlist includes `questions.sh` (`:230`). Executed: `questions.sh open` through the block ran the image copy (test 12 `from-opt`; `u4c-r3-d6-run.log`).

**Evidence:** `skills/dev-cycle/SKILL.md:230`, `:382-386`; `test/scripts/build-loop-orchestrator.bats:279`; `docs/reviews/execution-logs/u4c-r3-d6-run.log`

---

## Claim 30: Step 9: "after `questions.sh index` and `check` in WT ... (`check` exiting 1 names entries to fix before staging)"

**Location:** `skills/dev-cycle/SKILL.md:712-713`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers what `cmd_check` prints on exit 1. It does not establish how the orchestrator acts on it.

Most failures name an entry (`echo "  ✗ $id: invalid route ..."`, `scripts/questions.sh:263-264`). Some exit-1 causes are file-level, though: `echo "  ✗ missing: $file"` (`:237`), `not valid UTF-8` (`:243`) and `index is stale — run: $QS_CMD index` (`:296`). Precise version: "`check` exiting 1 names the entries or files to fix before staging".

**Evidence:** `scripts/questions.sh:233-300`; `skills/dev-cycle/SKILL.md:712-713`

---

## Claim 31: d6_copy/d6_setup comment: "Its one copy is SKILL.md's 'The D6 block': the lines between the block's bash -s line and its D6 line. d6_copy OPT [trust]: ... with trust its ownership check passes any path that exists (and refuses a missing one with the snippet's own words), so a uid-owned OPT stands in for the root-owned image. d6_setup: main holds this branch's four scripts, and so does a trusted stand-in at $U."

**Location:** `test/scripts/build-loop-orchestrator.bats:227-244`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the extraction, the D6_OPT rewrite and the stub's behavior. The stub's `-e` follows links, so a dangling link reads "missing" under the stub but "not root-owned" under the real own(). That does not matter for any test here.

The awk extracts exactly `SKILL.md:197-252` (Claim 20). The rewrite is guarded: `grep -qxF '  D6_OPT=/opt/claude-workflows' "$D6" && sed -i ... && grep -qxF "  D6_OPT=$1" "$D6" || return 1` (`:237`). With the literal `trust` it writes `  own() { [[ -e "$1" ]] || no "$1 is missing"; }` (`:238`). That is the same `"$1 is missing"` wording as the real own() (`SKILL.md:228`). d6_setup commits the scripts and runs `opt_copy "$U" && d6_copy "$U" trust` (`:243`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:227-244`; `skills/dev-cycle/SKILL.md:228`; `docs/reviews/execution-logs/u4c-r3-orchestrator-bats.log`

---

## Claim 32: T33 tests: "SKILL.md holds the D6 snippet once, and it names no other copy to run: no root test, no read of main's scripts" and "the D6 snippet runs the image copy's scripts by absolute path, with the image's own lib and questions.sh, never main's or the working tree's"

**Location:** `test/scripts/build-loop-orchestrator.bats:255`, `:263`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers what each test asserts. The first test's "names no other copy" is a grep for reader commands, not a proof; that is the rubric's decided C10. "image copy" here is the uid-owned stand-in.

The first test requires one `<<'D6'` line and one `^D6$` line. It requires the last extracted line to be `d6 "$@" </dev/null`, no `D6_ROOT|cat-file (blob|--batch)|ls-tree|mktemp|\$HOME|~/` outside comments, and that `test/lib/d6-snippet.bash` is absent (`:256-260`). The second test's assertions are in Claim 13. Both pass (ok 11, 12).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:255-280`; `docs/reviews/execution-logs/u4c-r3-orchestrator-bats.log`

---

## Claim 33: T36 test: "the D6 snippet refuses before running anything: a blob or commit replace ref, info/grafts, not exactly one plain main or master", with the missing-file and non-regular-file refusals added

**Location:** `test/scripts/build-loop-orchestrator.bats:282-297`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the listed refusals. The name under-lists the body, which also covers the missing-file, directory-as-file and bad-first-argument cases. Its missing-file case runs under the trust stub, so it checks the stub's copy of the words. The real own()'s missing branch is T37's (Claim 34).

`d6_is` asserts exit 2, the exact line and an empty stderr: `[ "$status" -eq 2 ] && [ "$output" = "$1" ] && [ -z "$stderr" ]` (`:247`). Line `:294` reads `rm "$U/scripts/questions.sh"; d6_is "refuse d6: $U/scripts/questions.sh is missing"`. Line `:295` replaces the lib with a directory and expects `is not a regular file`. Passes (ok 13).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:247`, `:282-297`; `docs/reviews/execution-logs/u4c-r3-orchestrator-bats.log`

---

## Claim 34: T27 and T37 tests: "the D6 snippet's image copy refuses the same tip"; "runs the root-owned image copy at /opt by absolute path, not main's copy"; "refuses an image copy the uid owns or one missing a file (an older image), and never runs main's"

**Location:** `test/scripts/build-loop-orchestrator.bats:299`, `:312`, `:320`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each test's assertions. The /opt test runs here, where `/opt` is root-owned, and would skip elsewhere. The uid-owned test uses the unstubbed own() (`d6_copy "$U"` with no `trust`).

`:323-324` reads `U="$BATS_TEST_TMPDIR/opt"; opt_copy "$U"; d6_copy "$U"` / `d6_is "refuse d6: $U/scripts/build-loop.sh is not root-owned, a plain path and unwritable here"`. Then `rm "$U/scripts/build-loop.sh"; d6_is "refuse d6: $U/scripts/build-loop.sh is missing"` (`:325`). This is the real own()'s missing branch, which i1's C2 asked for. The /opt test compares `--help` output with the image's own (`:315-316`). All pass (ok 14, 15, 16).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:299-325`; `docs/reviews/execution-logs/u4c-r3-orchestrator-bats.log`

---

## Claim 35: Pin test: "SKILL.md step 0.1's image-lag paths are GATE_CODE's, on one line of their own: a GATE_CODE change fails here until both move", and step 0.1's "(a test pins the line)"

**Location:** `test/scripts/build-loop-orchestrator.bats:347-354`; `skills/dev-cycle/SKILL.md:291-292`
**Type:** Invariant / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that GATE_CODE is pinned to a literal, that SKILL.md holds the exact path line once, and that each path matches GATE_CODE. It does not check that this line is the one step 0.1's diff command uses: a matching line anywhere in SKILL.md passes. The P-covers-every-alternative direction is held by the two literals, checked by hand here (all five alternatives are in P), not by code.

The test sources the lib's GATE_CODE. It fails with "GATE_CODE changed: update step 0.1's PATHS line and this test" unless the value equals `'^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'` (`:350`). It requires `grep -cxF "   $q$P$q"` = 1 (`:352`), and `[[ "$p" =~ $g || "${p}x" =~ $g ]]` for each path (`:353`). SKILL.md `:292` is exactly ``   `scripts/build-loop.sh scripts/dev-cycle.sh scripts/questions.sh scripts/lib/ skills/dev-cycle/` ``. Passes (ok 18).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:347-354`; `skills/dev-cycle/SKILL.md:291-292`; `scripts/lib/dev-cycle-read.sh:1970`; `docs/reviews/execution-logs/u4c-r3-orchestrator-bats.log`

---

## Claim 36: Commit 1bc823ea body ("The snippet always runs the root-owned image copy under /opt ... It keeps the replace-ref, grafts and default-branch checks, and the ownership checks ... It also takes questions.sh (row 775) ... the unstubbed refusal and the real /opt run are tested as before")

**Location:** `git log main..HEAD` (1bc823ea)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the body's statements against its own tree and HEAD. The Notes' "(row 739 left the home to U4)" is the row-738 mis-citation already recorded as Accepted-immutable (row 812, Claim 2); not re-filed.

The block keeps the git checks (`SKILL.md:232-239`) and the ownership walk (`:243-246`), and takes `questions.sh` (`:230`). Row 775 is questions.sh through `~/.claude/scripts`. The unstubbed refusal is `bats:323-324` and the real /opt run is `bats:312-317`.

**Evidence:** `skills/dev-cycle/SKILL.md:230-246`; `test/scripts/build-loop-orchestrator.bats:312-325`; `docs/reviews/override-log.md:775`, `:812`

---

## Claim 37: Commit 33ad1767: "Step 0.1 files an image-lag entry when main's gate code is ahead of the image's .manifest commit (architecture 1)"

**Location:** `git log main..HEAD` (33ad1767)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers this sentence against its own commit's tree. The rest of the body (the narrowed claim, the `.git` entry, missing-as-missing, the env -u, questions.sh in the Rules, the plan's rows 738-741) matches. A commit message cannot be edited, and later commits fixed the text (rubric D4), so this is recorded only.

At 33ad1767 the check diffed all of `scripts/` and `skills/dev-cycle/` and fired on any difference. Per the rubric's i2 note, "step 0.1's diff narrowed to GATE_CODE's paths (it read all of `scripts/`, where health-check.sh differs today)" (`rubric:58-59`), and D4's "'older than main's' where the test is 'differs'" (`rubric:77`). So "gate code" and "ahead" were both looser than that commit's test. Precise version: "when `scripts/` or `skills/dev-cycle/` differ between the image's `.manifest` commit and main".

**Evidence:** `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:58-59`, `:77`; `git show 33ad1767:skills/dev-cycle/SKILL.md` (step 0.1)

---

## Claim 38: Commit f2cc21e6: "Step 0.1 compares only GATE_CODE's paths (all of scripts/ named health-check.sh too), says the repository holds the image's commit, names the release as install.sh then the next sandbox launch ... Step 1 names the timeout stop; the block header says the default branch's ref; Rollback 1 is scoped to gate-code reverts."

**Location:** `git log main..HEAD` (f2cc21e6)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each statement against f2cc21e6's tree and, where still present, HEAD. It does not cover text that 43b8d7ed later replaced.

At f2cc21e6, step 0.1 read "when `hg -C MAIN_WT cat-file -e 'C^{commit}'` succeeds / (this repository holds the image's commit)" and "(the release: the host's / `./devcontainer-config/install.sh`, then the next sandbox launch rebuilds the image)" (`git show f2cc21e6:skills/dev-cycle/SKILL.md`). Executed: diffing all of `scripts/` lists `scripts/health-check.sh`, and the GATE_CODE paths do not (`u4c-r3-step01.log`). Step 1 has "or a timed-out call is still a stop" (`SKILL.md:385-386`). The header has "the default branch's ref" (`:203`). Rollback 1 has "a revert of gate code takes effect only after the image is rebuilt" (`plan:441`).

**Evidence:** `skills/dev-cycle/SKILL.md:203`, `:385-386`; `docs/working/plan-build-loop-handoff.md:441`; `docs/reviews/execution-logs/u4c-r3-step01.log`

---

## Claim 39: Commit 43b8d7ed: "step 0.1 now files image-off-main (you: judgment) when the image's commit is not on main ... the image-lag paste checks the host checkout is at main's commit before install.sh ... A missing image file's --state stop gives the same paste ... Notes: ... executed by hand against the real image (C on main, diff 1)"

**Location:** `git log main..HEAD` (43b8d7ed)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each body statement against HEAD and a re-run of the hand execution. The body's "i2 critic reports, rubric and override rows" includes row 819, whose content is Claim 4's Incorrect.

`image-off-main` is at `SKILL.md:288-290`, the paste guard at `:295`, the missing-file paste at `:283-284`, and the one-line pin at `bats:347` (Claim 35). Re-executed now (`u4c-r3-step01.log`): `is-ancestor C M` exit 0 ("C on main") and `diff --quiet` exit 1 ("diff 1"). Main has since moved to `2aaf97b4`, which does not change either result.

**Evidence:** `skills/dev-cycle/SKILL.md:283-299`; `test/scripts/build-loop-orchestrator.bats:347-354`; `docs/reviews/execution-logs/u4c-r3-step01.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4** (`docs/reviews/override-log.md:819`, rubric `:82`): they say deleting C's objects "turns the check into a record note", but step 0.1 at the same commit says a failed `cat-file -e` means "skip silently" (`SKILL.md:287-288`). The deletion leaves no trace. Fix with an appended row and the rubric's D9 wording.

### Stale
- **Claim 8** (`docs/working/plan-build-loop-handoff.md:156`): F38's "and compares hashes (T36)". The hash comparison and its tests were deleted with the reader.
- **Claim 12** (`docs/working/plan-build-loop-handoff.md:394`): T27's "refuse from main's copy". The test now refuses from the image copy.

### Mostly Accurate
- **Claim 1** (rubric `:70`): the architecture i2 tally omits its one Informational ("2 Coupling, 2 Minor, 1 Informational").
- **Claim 3** (`override-log.md:817`): already decided. The step 9 sentence is a further omission, and the conclusion holds.
- **Claim 5** (`plan:71`) and **Claim 17** (`scripts/lib/dev-cycle-read.sh:1962-1963`): "the image copy built from main". It is built from the host checkout's HEAD, and step 0.1 handles an off-main image.
- **Claim 6** (`plan:77`): "never trusts a file the uid can write". It never *runs* one, but it trusts the `.git` entry and the default branch's ref, as the block's header says.
- **Claim 14** (`plan:400`): T37's "non-claude-workflows ... (stubbed)". The /opt test runs the real image (skipping without it), and the repository no longer matters.
- **Claim 30** (`SKILL.md:713`): `check` exit 1 can name a file (missing, not UTF-8, stale index), not only entries.
- **Claim 37** (33ad1767): "gate code is ahead" was looser than that commit's diff over `scripts/`. Immutable, and fixed later.

### Unverifiable
- **Claim 23** (`SKILL.md:215`): the -w-as-root behavior needs a root run (C11, open).
- **Claim 27c** (`SKILL.md:296`): install.sh plus a new launch rebuilding `/opt` needs the host.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to /workspace/.claude/wt-build-loop-u4c/docs/reviews/code-fact-check-report-2026-10-13-u4c-final-r3.md, structured per the code-fact-check skill.
- Answered: all eight check areas of the brief:
  - the D6 header refusals, trust statements, the lib/questions.sh sourcing and the env -u effect (executed against the real /opt);
  - the Rules and every call site;
  - step 0.1's branches, executed read-only against /workspace with the real manifest, plus the paste guard, install.sh's HEAD/assembled_from and the pin test;
  - the D6 test names and comments;
  - the plan items listed, plus two stale rows found beside them (F38, T27);
  - override rows 812-819, the rubric, and every row number cited;
  - the store_check and GATE_CODE comments;
  - the four commit messages.
- Out of scope: judging fixes or decisions (critics' job); re-filing decided items (row 812, row 817's omissions, C10, C11); running health-check.sh (per the brief).
- Escalate: Claim 4. An override row and rubric D9 state a consequence (a record note) that the skill's own text at the same commit rules out (a silent skip), so the Won't-Fix rests on a weaker exposure than stated. Nothing else is blocking.
