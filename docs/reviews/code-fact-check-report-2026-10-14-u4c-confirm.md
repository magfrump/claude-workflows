# Code Fact-Check Report

**Commit:** e58adc1f
**Replication:** k=1 (second confirming pass, Q-144 interim)
**Repository:** claude-workflows (`/workspace/.claude/wt-build-loop-u4c`, branch `feat/build-loop-u4c`)
**Scope:** fix range `git diff 43b8d7ed..e58adc1f`: `skills/dev-cycle/SKILL.md` step 0.1 and step 9.1, `scripts/lib/dev-cycle-read.sh` comment, `test/scripts/build-loop-orchestrator.bats` pin-test name, `docs/working/plan-build-loop-handoff.md` edits, override-log rows 820-821, the rubric's final confirming-pass section (E1-E6), commit message of e58adc1f. Commands executed read-only against `/workspace` (main at 000a6942) and in throwaway repos.
**Checked:** 2026-10-14
**Total claims checked:** 24 (22 numbered, two split into a/b)
**Summary:** 16 verified, 5 mostly accurate, 1 stale, 1 incorrect, 1 unverifiable (the one Incorrect is a test name, not behaviour; no behavioural Incorrect)

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`); no claim in scope matches a logged pattern, and no fabrication was found, so the log is not updated.

Execution logs (all under `docs/reviews/execution-logs/`): `u4c-confirm2-step01.log` (manifest, cat-file, first-parent membership, old is-ancestor, diff, name-only, absent object), `u4c-confirm2-paste.log` (the paste in a throwaway repo with a stub install.sh), `u4c-confirm2-objects.log` (deleted tree vs deleted commit object), `u4c-confirm2-pin-mutation.log` (pin test with GATE_CODE widened), `u4c-confirm2-orchestrator-bats.log` (bats, 26/26, exit 0).

---

## Claim 1: Commit message of e58adc1f

**Location:** commit `e58adc1f` (message body)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each factual sentence of the message (the two introduced findings, the interim [1] content, rows 820/821's roles, the executed first-parent result); does not establish that the interim is the right design (Q-144 stays open).
**Legibility-target:** for-orchestrator-synthesis

The message says "merge-base --is-ancestor passed a merged branch's own commit" and "Executed: 774a0eef is on main's first-parent history, 6beca252 is not." Re-executed at 2026-10-14T07:03:05Z, cwd `/workspace`, M=000a6942:

```
== C=6beca252982b998c71b3da23c5cd22726b113da6
$ git rev-list --first-parent M | grep -qx C
exit=1
$ git merge-base --is-ancestor C M (old test)
exit=0
```
(`docs/reviews/execution-logs/u4c-confirm2-step01.log`; 774a0eef gives exit 0 for both.) The remaining sentences ("image-off-main-C12 is keyed and suppressed by any entry, with numbered options; a cleared image-lag is listed for the user, never answered by the orchestrator (D8); the manifest is read first; the paste checks the working-tree install.sh") each match the SKILL.md text quoted in Claims 14-19. "found a Medium and an Inconsistent the range introduced" matches `security-review-2026-10-13-u4c-final.md:48` (`**Severity:** Medium`) and `api-consistency-review-2026-10-13-u4c-final.md:46` (`**Severity:** Inconsistent (introduced by this branch, 43b8d7ed)`). "row 820 amends 819" matches `docs/reviews/override-log.md:820` ("Amends row 819: ...").

**Evidence:** `git log -1 e58adc1f`; `docs/reviews/execution-logs/u4c-confirm2-step01.log`; `docs/reviews/security-review-2026-10-13-u4c-final.md:46-48`; `docs/reviews/api-consistency-review-2026-10-13-u4c-final.md:46`; `docs/reviews/override-log.md:820`

---

## Claim 2: Row 820: "deleting C's commit object now makes step 0.1 skip silently (no record note) ... a record note appears only when C's trees or blobs are gone"

**Location:** `docs/reviews/override-log.md:820`
**Type:** Behavioral (doc of behaviour)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the consequence of deleting C's objects (commit object gone: silent skip; commit present, tree gone: the diff exits 128, the "Any other exit" note); does not establish that a record note appears whenever trees or blobs are gone (if C is also off main's first-parent history, the off-main entry is filed instead and no diff runs), nor the manifest-missing note, which is outside the deletion case the row is about.
**Legibility-target:** for-author

Executed at 2026-10-14T07:05:02Z in a throwaway repo (`docs/reviews/execution-logs/u4c-confirm2-objects.log`):

```
-- tree of C deleted
cat-file exit=0
...
member exit=0
fatal: unable to read tree 7bac8886dcb7d439ef295fc7c562defc386bd109
diff exit=128 (other exit -> record note)
-- commit C deleted
cat-file exit=128 (-> skip silently)
```

That matches SKILL.md's order: `skills/dev-cycle/SKILL.md:288-289` "If `hg -C MAIN_WT cat-file -e 'C^{commit}'` fails, this repository does not hold the image's commit: skip silently", and `:305` "Any other exit: note it in the record."

**Evidence:** `docs/reviews/override-log.md:820`; `skills/dev-cycle/SKILL.md:285-306`; `docs/reviews/execution-logs/u4c-confirm2-objects.log`

---

## Claim 3: Row 821: "The paste adds `git diff --quiet HEAD -- devcontainer-config/install.sh` before running it"

**Location:** `docs/reviews/override-log.md:821`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the paste refuses (does not run install.sh) on an unstaged or a staged edit of install.sh and on a moved HEAD, and runs it when clean; does not establish anything about other working-tree files install.sh might read (it builds its payload from `git archive HEAD`, `devcontainer-config/install.sh:325-327`, so only install.sh itself runs from the working tree), and an untracked file elsewhere in `devcontainer-config/` does not stop the paste.
**Legibility-target:** for-author

The paste at `skills/dev-cycle/SKILL.md:300-301`: "`cd A && test "$(git rev-parse HEAD)" = M && git diff --quiet HEAD -- devcontainer-config/install.sh && ./devcontainer-config/install.sh`". Executed at 2026-10-14T07:03:19Z in a throwaway repo, install.sh a stub that echoes RAN (`docs/reviews/execution-logs/u4c-confirm2-paste.log`):

```
case clean:
RAN
paste exit=0
case unstaged edit:
paste exit=1
case staged edit:
paste exit=1
case other untracked file in devcontainer-config:
RAN
paste exit=0
case HEAD moved:
paste exit=1
```

**Evidence:** `docs/reviews/override-log.md:821`; `skills/dev-cycle/SKILL.md:300-302`; `devcontainer-config/install.sh:320-327`; `docs/reviews/execution-logs/u4c-confirm2-paste.log`

---

## Claim 4: Row numbers cited in the range (rubric D9 "override rows 819, 820", E5 "row 821", E6 "row 820 amends 819", row 820 "Amends row 819")

**Location:** `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:82`, `:101`, `:102`; `docs/reviews/override-log.md:820`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that each cited row number is the line number of the override-log row with that content; does not establish row numbers cited outside the range.
**Legibility-target:** for-orchestrator-synthesis

`sed -n 819,821p docs/reviews/override-log.md` gives, at `:819`, "In a fork that holds the image's commit, step 0.1 compares unrelated gate code ..." (the D9 row), at `:820` "Amends row 819: deleting C's commit object ...", and at `:821` "The image-lag paste checks HEAD equals main's commit but not the working-tree install.sh ...". The file has 821 lines, so 820 and 821 are the two appended rows.

**Evidence:** `docs/reviews/override-log.md:819-821`

---

## Claim 5: Rubric tallies for the final confirming pass

**Location:** `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:86-90`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the critic tallies and the fact-check counts against the 43b8d7ed reports' headers and severity lines; does not re-verdict those reports, and "Health check passed at 43b8d7ed" is Claim 7.
**Legibility-target:** for-orchestrator-synthesis

The rubric says "performance (1 Informational), architecture (2 Minor, 3 Informational ...), api-consistency (1 Inconsistent introduced, 3 Minor, 1 Informational), security (1 Medium introduced, 3 Low)". Severity lines: performance `:32` `**Severity:** Informational` (only one); architecture `:25`, `:44` Minor, `:59`, `:74`, `:89` Informational; api `:46` Inconsistent, `:62`, `:78`, `:92` Minor, `:105` Informational; security `:48` Medium, `:63`, `:78`, `:93` Low. The fact-check counts match that report's header: "1 Incorrect (new), 1 Incorrect (already Accepted-immutable), 3 Stale, 12 Mostly accurate" (`code-fact-check-report-2026-10-13-u4c-final.md:9`).

**Evidence:** `docs/reviews/performance-review-2026-10-13-u4c-final.md:32`; `docs/reviews/architecture-review-2026-10-13-u4c-final.md:25-89`; `docs/reviews/api-consistency-review-2026-10-13-u4c-final.md:46-105`; `docs/reviews/security-review-2026-10-13-u4c-final.md:48-93`; `docs/reviews/code-fact-check-report-2026-10-13-u4c-final.md:9`

---

## Claim 6: Rubric E1-E6 sources and statuses ("Interim fix" / "Fixed")

**Location:** `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:97-102`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each row's source finding and whether its stated fix is present at e58adc1f; E1-E5 hold; E6's "Fixed" holds for row 819/D9, plan :71, :77 (header sentence), :156, :394, :400, the as-built note, the lib comment's rewording and step 9's check line, but not fully for the pin test's name (Claim 22b) or plan :432 (Claim 13); does not establish that the fixes close the findings' design concerns.
**Legibility-target:** for-author

Sources match: E1 to security final #1 (`security-review-2026-10-13-u4c-final.md:46` "`--is-ancestor` reads an unreviewed mid-branch commit as \"on main\""), E3 to #2 (`:61` "Step 0.1 tells the orchestrator to answer `image-lag` itself"), E2 to #3 (`:76`), E5 to #4 (`:91` "pre-existing, not introduced"). E6 says the pin test's name is fixed. The renamed test still claims "a GATE_CODE change fails here until this test's literal and that line move", and widening GATE_CODE with the literal updated passes while SKILL.md's line stays unchanged (`u4c-confirm2-pin-mutation.log`, Claim 22b). Plan :432 still leaves out the cat-file skip (Claim 13).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:97-102`; `docs/reviews/security-review-2026-10-13-u4c-final.md:46-93`; `docs/reviews/execution-logs/u4c-confirm2-pin-mutation.log`

---

## Claim 7: Rubric: "Health check passed at 43b8d7ed."

**Location:** `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:90`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing beyond noting the claim; does not establish a pass or a fail at 43b8d7ed.
**Legibility-target:** for-orchestrator-synthesis

This is an executable guarantee. The brief forbids running `scripts/health-check.sh` (blocker: execution not permitted in this pass), and the range commits no log of it (paraphrased — no quote available because the claim covers absence of a file: no `health-check` log appears in `git diff --stat 43b8d7ed..e58adc1f`).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:90`; `git diff --stat 43b8d7ed..e58adc1f`

---

## Claim 8: Rubric header `Commit: 43b8d7ed` and Status "Final confirming pass not clean (E1, E2): Q-144, interim [1] applied"

**Location:** `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:1`, `:107`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the stamp and the Status line; does not establish a convention for what the stamp names.
**Legibility-target:** for-author

The stamp names the commit that was reviewed: "## Final confirming pass (43b8d7ed)" (`:84`). But the E-table records fixes that only exist at e58adc1f ("Interim fix: C is on main only on `rev-list --first-parent M`", `:97`), and the Status line says "interim [1] applied" without naming the commit that applied it. The prior pass flagged the same pattern (`code-fact-check-report-2026-10-13-u4c-final.md:49-53`, "Rubric header stamp ... Stale"). Precise version: name e58adc1f as the commit carrying the E fixes.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:1`, `:84`, `:97`, `:107`

---

## Claim 9: Plan :71: "D6 runs the image copy, built from the host checkout's HEAD (Q-140 [1]; step 0.1 checks it is on main)"

**Location:** `docs/working/plan-build-loop-handoff.md:71`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that install.sh stamps and stages HEAD's commit and that step 0.1 tests first-parent membership; does not establish that step 0.1 runs at all when the repository lacks C or the manifest lacks a line (it skips).
**Legibility-target:** for-author

`devcontainer-config/install.sh:335` `commit="$(head_commit)" || exit 1`, and `head_commit` runs `repo_git rev-parse --verify -q 'HEAD^{commit}'` (`:186`). The manifest records that commit at `:357` `echo "commit=$commit"`. The real manifest reads `commit=774a0eef...` / `assembled_from=/home/magfrump/claude-workflows` (step01 log). Step 0.1 checks first-parent membership (Claim 16).

**Evidence:** `devcontainer-config/install.sh:184-190`, `:330-361`; `docs/reviews/execution-logs/u4c-confirm2-step01.log`

---

## Claim 10a: Plan :77 (D6 header): "It never runs a file the uid can write (it trusts the checkout's `.git` entry and the default branch's ref, as its header says)"

**Location:** `docs/working/plan-build-loop-handoff.md:77`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the header sentence against the D6 block's ownership checks and header text; does not establish the sub-bullets under it (Claim 10b) or the same-uid shell residual (Q-103).
**Legibility-target:** for-author

`skills/dev-cycle/SKILL.md:228` `own() { ... [[ ! -L "$1" && "$(stat -c %u -- "$1")" == 0 && ! -w "$1" ]] || no ...` is applied to the four files and every directory up to `/` (`:243-246`). The header says: "It still trusts that entry and the default branch's ref for which repository and branch the script reads" (`:203-204`).

**Evidence:** `skills/dev-cycle/SKILL.md:197-247`

---

## Claim 10b: Plan :79-80, the D6 sub-bullets: "It extracts `scripts/build-loop.sh` ... from `MAIN_SHA` ... into a fresh `mktemp -d`" / "It checks each file's `hash-object` against its `ls-tree MAIN_SHA` id"

**Location:** `docs/working/plan-build-loop-handoff.md:79-80`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two bullets right under the header sentence that the range edited; does not establish that the range introduced them (they predate it, the range left them untouched, and the as-built note at :344 supersedes them: "the verified reader, D6_ROOT, the temp dir and the SHA-1 branch are gone").
**Legibility-target:** for-author

The D6 block holds no extraction, temp dir or hash comparison: `grep -c "hash-object\|ls-tree\|mktemp"` over `SKILL.md:189-253` prints `0`. The block runs `bash "$D6_OPT/scripts/$s" "$@"` (`:247`). The range's edit to :77 now sits directly above two bullets that contradict it.

**Evidence:** `docs/working/plan-build-loop-handoff.md:77-80`, `:344`; `skills/dev-cycle/SKILL.md:189-253`

---

## Claim 11: Plan :156 (F38): "refuses a default branch that is not one plain main or master (T36; the hash comparison went with the reader, Q-140 [1])"

**Location:** `docs/working/plan-build-loop-handoff.md:156`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the default-branch refusal and the hash comparison being gone; does not establish T36's test coverage beyond the bats run passing.
**Legibility-target:** for-author

`skills/dev-cycle/SKILL.md:236-237`: "`m=""; for n in main master; do g show-ref --verify -q "refs/heads/$n" && m+="$n "; done`" / "`[[ "$m" == main || "$m" == master ]] || no "the default branch is not exactly one of main and master"`". The block has no hash comparison (Claim 10b).

**Evidence:** `skills/dev-cycle/SKILL.md:232-239`

---

## Claim 12: Plan :344, :394, :400 edits (as-built note's `image-off-main-C12` sentence; T27 "refuse from the image copy (U4c)"; T37 "runs the real `/opt` copy (skipped without one) ... a uid-owned stub dir or a missing file → refuse")

**Location:** `docs/working/plan-build-loop-handoff.md:344`, `:394`, `:400`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three edited sentences against SKILL.md step 0.1 and the T37 tests; does not establish T27's own test body beyond the bats run passing.
**Legibility-target:** for-author

T37: `test/scripts/build-loop-orchestrator.bats:314` "`|| skip "no root-owned image copy at $O here"`" and `:320` "@test \"the D6 snippet refuses an image copy the uid owns or one missing a file (an older image), and never runs main's (T37, U3b3, U4c)\"". The :344 sentence ("`image-off-main-C12` when the image's commit is not on main's first-parent history") matches `SKILL.md:290-292`. Bats run at 2026-10-14 (cwd the worktree, `timeout 600 bats test/scripts/build-loop-orchestrator.bats`) exited 0 with 26 `ok` lines.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:312-330`; `skills/dev-cycle/SKILL.md:288-294`; `docs/reviews/execution-logs/u4c-confirm2-orchestrator-bats.log`

---

## Claim 13: Plan :432: "step 0.1 files `image-off-main-C12` when the image's `.manifest` commit is not on main's first-parent history, else `image-lag` when main's GATE_CODE paths differ from it"

**Location:** `docs/working/plan-build-loop-handoff.md:432`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two filing conditions; does not establish the earlier skips the summary leaves out.
**Legibility-target:** for-author

The mechanism is right, but the claim leaves out a qualifier. A C this repository does not hold is also "not on main's first-parent history", yet step 0.1 skips silently before the membership test: `SKILL.md:288-289` "If `hg -C MAIN_WT cat-file -e 'C^{commit}'` fails ... skip silently". It also leaves out the manifest note (`:287`). The prior pass found the same omission (`code-fact-check-report-2026-10-13-u4c-final.md:79`, "plan :432 omits the two earlier conditions"). Precise version: "... when the repository holds the image's commit and it is not on main's first-parent history ...".

**Evidence:** `docs/working/plan-build-loop-handoff.md:432`; `skills/dev-cycle/SKILL.md:285-294`

---

## Claim 14: Lib comment: "The scripts because the image copy, built from main on the host, runs every merge after the next release"

**Location:** `scripts/lib/dev-cycle-read.sh:1963-1965`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "built from" wording; does not establish the floor rule the comment justifies (unchanged by the range).
**Legibility-target:** for-author

The image is built from the host checkout's HEAD (`devcontainer-config/install.sh:335` `commit="$(head_commit)"`), which may be off main. That is exactly the case step 0.1 now files as `image-off-main-C12` (`SKILL.md:291-292`). The plan's matching line was corrected to "built from the host checkout's HEAD" (`plan:71`), but the lib still says "from main on the host". Precise version: "built from the host checkout's HEAD (step 0.1 checks it is on main)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1962-1969`; `devcontainer-config/install.sh:335`; `docs/working/plan-build-loop-handoff.md:71`

---

## Claim 15: Step 0.1 reads the manifest first: "C and A are the `commit=` and `assembled_from=` lines ... with no file or either line, note it in the record and skip"

**Location:** `skills/dev-cycle/SKILL.md:285-287`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order (the manifest check comes before cat-file, so an empty C no longer reaches the silent skip: E4) and the two line names in the real manifest; does not establish the parse of a malformed or duplicated line.
**Legibility-target:** for-author

The text now puts the manifest note before the cat-file test: "M main's commit; with no file or either line, note it in the record and skip. If `hg -C MAIN_WT cat-file -e 'C^{commit}'` fails ..." (`SKILL.md:287-289`). The real `/opt/claude-workflows/.manifest` holds `commit=774a0eef3ff85beb69695e014ab840f70648f193` and `assembled_from=/home/magfrump/claude-workflows` (step01 log, 2026-10-14T07:03:05Z, exit 0). "either line" means "a missing one of the two lines". That reading is natural but terse.

**Evidence:** `skills/dev-cycle/SKILL.md:285-289`; `docs/reviews/execution-logs/u4c-confirm2-step01.log`

---

## Claim 16: "C is on main only when it is one of the lines of `hg -C MAIN_WT rev-list --first-parent M` (the history `--main-log` reads; a merged branch's own commits are not on it)"

**Location:** `skills/dev-cycle/SKILL.md:289-291`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the membership test (full 40-hex C against rev-list's 40-hex lines), the `--main-log` cross-reference, and the merged-branch example 6beca252; does not establish behaviour when rev-list itself fails (no lines, so C reads as off main and the off-main entry is filed rather than a note: advisory noise only), nor an abbreviated `commit=` value (install.sh writes the full id).
**Legibility-target:** for-author

Executed (step01 log): 774a0eef `rev-list --first-parent M | grep -qx C` exit=0; 6beca252 (U4b2's "fix(dev-cycle): U4b2 Q-143 [3] ..." commit, merged via 3943ab1c) exit=1 while the old `merge-base --is-ancestor` gave exit=0. `--main-log` reads the same history: `scripts/build-loop.sh:1797` "`gate_git rev-list --first-parent "$MAIN_SHA" > "$GATE_TMP/fp"`".

**Evidence:** `skills/dev-cycle/SKILL.md:289-291`; `scripts/build-loop.sh:1794-1806`; `docs/reviews/execution-logs/u4c-confirm2-step01.log`

---

## Claim 17: `image-off-main-C12` "(C's first 12 hex), unless WT's questions files hold one: [1] rebuild from main (check main out on the host, then the paste below), [2] keep this image" is consistent with the step-0 sibling entries

**Location:** `skills/dev-cycle/SKILL.md:291-294`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the slug key, the suppression rule and numbered options against `other-commit-SHA12` / `main-log-refused-MAIN12`; does not establish when the entry is filed relative to WT (step 0.1 runs before WT exists at step 0.3, and only step 0.2's stop path says "makes WT (step 0.3), files the entries"; this gap is shared with `image-lag`'s pre-existing "an open one has its body rewritten"), nor that the answer is read (it need not be: "None of these stops the iteration", `:306`).
**Legibility-target:** for-author

Siblings: "naming its SHA (slug `other-commit-SHA12`) or quoting the line (slug `main-log-refused-MAIN12`), unless WT's questions files hold one (rows 720, 726), with options **[1] reviewed, build on it** and **[2] not yet**" (`SKILL.md:325-328`). The new entry uses the same 12-hex key form, the same "unless WT's questions files hold one" suppression, and numbered options. Its suppression covers answered entries too, so a `[2] keep` sticks for that C, and a rebuild changes C and so the slug. Slug grammar holds: `questions.sh check` requires `[a-z0-9-]+` (`scripts/questions.sh:250`), and C12 is lowercase hex. One difference: the siblings' bracketed options are bold and the new ones are not (cosmetic).

**Evidence:** `skills/dev-cycle/SKILL.md:285-334`; `scripts/questions.sh:248-254`

---

## Claim 18: "On main: run `hg -C MAIN_WT diff --quiet C M -- PATHS` ... Exit 1: ... File one `you: terminal` entry `image-lag` ... holding C, M, the changed names (the same diff with `--name-only`)"

**Location:** `skills/dev-cycle/SKILL.md:294-299`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the diff's exit codes and name listing on the real image commit vs main; does not establish the body-rewrite of an existing entry (unchanged by the range).
**Legibility-target:** for-author

Executed (step01 log): `git diff --quiet C M -- PATHS` exit=1 for C=774a0eef, M=000a6942; `--name-only` lists `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `skills/dev-cycle/SKILL.md` (exit 0). So against the current image, the step files `image-lag`. The pinned PATHS line still passes the bats pin test (bats log, exit 0).

**Evidence:** `skills/dev-cycle/SKILL.md:294-299`; `docs/reviews/execution-logs/u4c-confirm2-step01.log`; `docs/reviews/execution-logs/u4c-confirm2-orchestrator-bats.log`

---

## Claim 19: The paste `cd A && test "$(git rev-parse HEAD)" = M && git diff --quiet HEAD -- devcontainer-config/install.sh && ./devcontainer-config/install.sh`

**Location:** `skills/dev-cycle/SKILL.md:299-302`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 3: it refuses a modified install.sh (staged or not) or a moved HEAD and runs only when both hold; does not establish install.sh's own behaviour on the host (not runnable here).
**Legibility-target:** for-author

See Claim 3's captured output (`u4c-confirm2-paste.log`): clean exit 0 with RAN; unstaged edit exit 1; staged edit exit 1; HEAD moved exit 1.

**Evidence:** `skills/dev-cycle/SKILL.md:299-302`; `docs/reviews/execution-logs/u4c-confirm2-paste.log`

---

## Claim 20: "Exit 0: the image holds main's gate code; list any open `image-lag` or `image-off-main-*` entry in the final message for the user to answer `done` (the orchestrator never answers one itself: D8)"

**Location:** `skills/dev-cycle/SKILL.md:302-304`
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers consistency with D8 and `--cycle-diff` (consistent: the orchestrator no longer flips an entry it did not receive an answer for), and the reach to the Final message; does not establish that `done` is a recognised answer for an `image-off-main-*` entry.
**Legibility-target:** for-author

D8: "The orchestrator never commits an answer it did not receive from you in-session. `--cycle-diff` enforces this (D13)" (`plan:88`). The `--cycle-diff` questions rule refuses changed key lines unless the ID is in `--answered` (`plan:331`). So listing the entry for the user, rather than answering it, is consistent with both. Two smaller points. (a) An `image-off-main-*` entry's options are "[1] rebuild from main ... [2] keep this image" (`SKILL.md:293-294`), but this line asks the user to answer `done`, which is neither option. (b) The **Final message** paragraph (`SKILL.md:789-795`) lists what it carries ("the new `you: judgment` entries ..., the `answers` commits step 0.2 read, the `--answered` IDs ...") but not these entries. The step-local instruction is the only place it is stated (the same pattern as step 0.3's "Unmerged `chore/dev-cycle-*` branches are named in the final message", `:341-342`).

**Evidence:** `skills/dev-cycle/SKILL.md:291-306`, `:789-795`; `docs/working/plan-build-loop-handoff.md:85-88`, `:331`

---

## Claim 21: Step 9.1: "(`check` exiting 1 names what to fix before staging)"

**Location:** `skills/dev-cycle/SKILL.md:718`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that every rc=1 path prints a named problem (file, entry ID or index); does not establish the ⚠ warning lines, which do not set rc.
**Legibility-target:** for-author

`scripts/questions.sh:237` "`echo "  ✗ missing: $file" >&2; rc=1`", `:259` "`echo "  ✗ duplicate id: $id" >&2; rc=1`", `:296` "`echo "  ✗ $(basename "$file"): index is stale — run: $QS_CMD index" >&2`". Each failure names a file or an entry. The old "names entries" undercounted this, and "what to fix" covers it.

**Evidence:** `scripts/questions.sh:233-300`

---

## Claim 22a: Pin test name: "a GATE_CODE change fails here until this test's literal ... move[s]"

**Location:** `test/scripts/build-loop-orchestrator.bats:347`
**Type:** Behavioral (test claim)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the literal assertion; does not establish the PATHS-line half (Claim 22b).
**Legibility-target:** for-author

`:350` "`[ "$g" = '^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/' ] || { echo "GATE_CODE changed: update step 0.1's PATHS line and this test: $g"; return 1; }`": any GATE_CODE change fails until the literal changes.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:347-353`; `docs/reviews/execution-logs/u4c-confirm2-orchestrator-bats.log`

---

## Claim 22b: Pin test name: "... and that line move"

**Location:** `test/scripts/build-loop-orchestrator.bats:347`
**Type:** Behavioral (test claim)
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a widening of GATE_CODE (a path added): the test passes with SKILL.md's PATHS line unchanged once the literal is updated. A narrowing (a path removed) does fail assertion 3 until the line moves. Does not establish any runtime effect: step 0.1 is advisory, and a missed path means only that an image lag in that path goes unreported.
**Legibility-target:** for-author

Executed 2026-10-14T07:06:12Z (bash, scratch dir; `docs/reviews/execution-logs/u4c-confirm2-pin-mutation.log`, exit 0). The test's three assertions were run with GATE_CODE extended by `^scripts/health-check\.sh$` and the literal updated:

```
assert1 (updated literal) pass
assert2 pass
assert3 pass: test passes with SKILL.md's PATHS line unchanged; scripts/health-check.sh is GATE_CODE but not in PATHS
```

Assertion 3 checks only that each listed path is GATE_CODE (`:352` "`for p in $P; do [[ "$p" =~ $g || "${p}x" =~ $g ]] ...`"), not the reverse. The rename (E6, "the pin test's name ... Fixed") kept the overclaim the prior pass reported as Claim 7, "until both move". What holds the line in place is the failure message's instruction ("update step 0.1's PATHS line and this test"), not the test. Precise name: "... fails here until this test's literal moves (its message names the PATHS line too); a removed path also fails until that line moves".

**Evidence:** `test/scripts/build-loop-orchestrator.bats:347-353`; `docs/reviews/execution-logs/u4c-confirm2-pin-mutation.log`; `docs/reviews/execution-logs/u4c-final-r1-pin-mutation.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 22b** (`test/scripts/build-loop-orchestrator.bats:347`): the test name says a GATE_CODE change fails "until ... that line move[s]". Widening GATE_CODE with the literal updated passes with the PATHS line unchanged. Fix the name, or add the reverse assertion.

### Stale
- **Claim 10b** (`docs/working/plan-build-loop-handoff.md:79-80`): the D6 bullets still describe extraction, `mktemp -d` and the `hash-object` check, right under the corrected :77 header. These predate the range.

### Mostly Accurate
- **Claim 6** (rubric `:102`): E6's "Fixed" overstates the pin-test name and plan :432.
- **Claim 8** (rubric `:1`, `:107`): the stamp names the reviewed commit, while the E fixes live at e58adc1f, which goes unnamed.
- **Claim 13** (plan `:432`): leaves out the "repository does not hold C" skip.
- **Claim 14** (`scripts/lib/dev-cycle-read.sh:1963-1964`): "built from main on the host" should be "built from the host checkout's HEAD".
- **Claim 20** (`SKILL.md:302-304`): `done` is not one of `image-off-main-*`'s options, and the Final message paragraph does not list these entries.

### Unverifiable
- **Claim 7** (rubric `:90`): "Health check passed at 43b8d7ed" needs a health-check run or a committed log. This pass was not permitted to run one.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** "a report saved to /workspace/.claude/wt-build-loop-u4c/docs/reviews/code-fact-check-report-2026-10-14-u4c-confirm.md, header `**Commit:** e58adc1f` and `**Replication:** k=1 (second confirming pass, Q-144 interim)`, every claim with a Legibility-target."
- **Answered:** Step 0.1's new sequence was executed against /workspace and the real manifest: manifest first, cat-file, first-parent membership (774a0eef on, the merged branch's 6beca252 off, the old is-ancestor test wrongly on), the diff, and the paste including `git diff --quiet HEAD -- devcontainer-config/install.sh`. Each branch's wording matches what the commands establish. `image-off-main-C12` is consistent with the step-0 siblings' slug and suppression rules and with D8. The plan, lib, test-name, rubric and override-row edits were checked, row numbers 819-821 are verified as line numbers, and the commit message of e58adc1f is verified. No behavioural Incorrect and no Inconsistent was introduced. The one Incorrect is a test name (22b, carried over from the prior Claim 7).
- **Out of scope:** security severity grading (the security pass's job), the design choice of interim [1] (Q-144), and running `scripts/health-check.sh`.
- **Escalate:** none blocking. Claim 22b and the Mostly-accurate items are for-author text fixes.
