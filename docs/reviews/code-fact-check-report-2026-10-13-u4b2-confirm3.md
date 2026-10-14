# Code Fact-Check Report: U4b2 confirming pass 3 (Q-143 [3])

**Repository:** claude-workflows (worktree `.claude/wt-build-loop-u4b2`, branch `feat/build-loop-u4b2`)
**Scope:** `git diff d00749ab..6beca252` (one commit: `6beca252 fix(dev-cycle): U4b2 Q-143 [3], the other-commit hold becomes a stop`), files `skills/dev-cycle/SKILL.md`, `docs/working/plan-build-loop-handoff.md`, and the commit message. Evidence comes from `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `scripts/dev-cycle.sh` and the rest of SKILL.md.
**Checked:** 2026-10-13
**Mode:** k=1 confirming pass
**Total claims checked:** 17
**Summary:** 11 verified, 4 mostly accurate, 1 stale, 0 incorrect, 1 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). No claim matches a logged pattern. No fabricated symbol was found, so nothing is appended.

## Executed evidence

- **ANSWER_AWK probe.** Run in its own `mktemp -d` directory, with the lib sourced and `$FENCE_AWK$ANSWER_AWK` run over a one-entry questions file marked `**Status:** ANSWERED`, answer line `Q-900: <text>`:
  - `[2] not yet` → drop; `2` → drop; `not yet` → unrecognized; `reviewed` → unrecognized
  - `keep holding` → unrecognized; `keep`, `Keep.`, `keep - holding` → keep
  - `[1] reviewed, build on it`, `1`, `[1]` → keep
  - entry with `**Status:** OPEN` → open
- **bats.** `bats -f main-log test/scripts/build-loop-orchestrator.bats` passed 3 of 3: classification, the near-miss `other` lines and the `refuse main-log:` line, and `--land-cycle`'s chore merge. They ran with TMPDIR set to the session scratchpad, and `git status --porcelain` was unchanged afterwards.

## Claims

### C1. `--check-answer` reads both questions files
**Location:** SKILL.md:261-263 ("`--check-answer` reads any entry with either slug in WT's `docs/working/questions.md` or `questions-archive.md`"); commit message ("in WT's two questions files"; "the lookup files are named (C2)")
**Verdict:** Verified
**Evidence:** In `scripts/lib/dev-cycle-read.sh:2135-2167`, `check_answer` loops over `docs/working/questions.md docs/working/questions-archive.md` and reads each from the default branch's commit (`git cat-file blob "$MAIN_SHA:$f"`). It skips when an ID appears in both files and fails closed on a read failure. One precision note: the answer is read from main's commit. The text says "WT's" files, which is the same content, because WT is made at MAIN in step 0.3 and `--check-answer` reads main's commit, which is at or after MAIN. The slug lookup runs over WT, and the answer read runs over main. That matches step 7's split.

### C2. Option [2] "not yet" does not read as `keep`
**Location:** SKILL.md:260-261 (options **[1] reviewed, build on it** and **[2] not yet**); commit message ("the entry's [2] is "not yet"")
**Verdict:** Verified (executed)
**Evidence:**
- Skill grammar (SKILL.md:541-543): an answer reads `keep` only if it starts `[1]`, or is `1` or `keep` alone or before one of `.,;:!)*` or a blank and a dash.
- `[2] not yet` starts `[2]`, so it reads `drop`.
- `not yet` alone matches nothing, so it reads `unrecognized`.
- The probe confirms both under the real `ANSWER_AWK` (`option()`, lib :2070-2083). Neither label's first word is a release word: "reviewed" reads `unrecognized`, and the stop holds.

### C3. Commit message: "(C1: "keep holding" read as keep)"
**Location:** commit 6beca252 body
**Verdict:** Mostly accurate
**Evidence:** As a shorthand for confirm2's finding C1, the claim is right: the old [2] label began with the release word, so answering it by its first word (`keep`, `Keep.`, `keep - holding`) read `keep` (executed). The literal phrase "keep holding", answered whole, reads `unrecognized` (executed). That would have held, not released. The finding is real, but the quoted string is not the input that reproduces it.

### C4. `--main-log` prints `other` lines and `refuse main-log:` lines as the stop describes
**Location:** SKILL.md:255-264; commit message ("an `other` or `refuse main-log` line")
**Verdict:** Verified (read + bats)
**Evidence:**
- `main_log` (build-loop.sh:1796-1810) prints `main MAIN N`, then `CLASS SHA SUBJECT` for each first-parent commit after SINCE, oldest first. Any commit with `CLASS=other` gives exit 2.
- When SINCE is off main's history, or the history cannot be listed, it prints `main MAIN -` then `refuse main-log: WHY` (exit 2).
- The bootstrap (40 zeros) takes the "not on the default branch's first-parent history" refusal, which the skill excludes as "the bootstrap's own".
- Tests T39 pass.

### C5. The `other` stop: the iteration makes WT, files entries, lands a record with `1.` = `stopped: step 0.2`, and runs nothing else
**Location:** SKILL.md:261-265; commit message
**Verdict:** Verified (internal consistency)
**Evidence:**
- WT comes from step 0.3. The land is step 9's 1-4.
- The Rules' "A stop after step 0.3 removes WT" covers cleanup.
- The commit message's `1. stopped: step 0.2` matches the SKILL text.

### C6. The stop is consistent with step 1's `1.` line handling
**Location:** SKILL.md:304-308 (health check skipped only when the previous `1.` line reads `passed at P` or `unchanged since P`)
**Verdict:** Verified
**Evidence:** `stopped: step 0.2` matches neither form. The iteration after a stop therefore runs the health check on the now-reviewed commit, which is the right fail-safe. The removed text ("skipped while step 0.2's hold is on ... row 776; step 4 then runs no repo test either") is gone, and nothing else in step 1 or step 4 refers to it.

### C7. The step 0 preamble: "a stop below ends the iteration with no record, so the next one starts from the same `Main at:`"
**Location:** SKILL.md:229-230 (text unchanged; this commit made it stale)
**Verdict:** Stale
**Evidence:** Step 0.2's `other` stop is now a stop inside "below" (step 0), and it writes and lands a record whose `Main at:` is MAIN. So the next iteration does **not** start from the same `Main at:`. Its SINCE advances past the `other` commit, which is why the stop has to persist through the questions entry. The preamble was true before this commit, because the hold was not a stop. It needs a carve-out such as "(but step 0.2's `other` stop, which lands)".

### C8. Rules: "Each stop ends the iteration there (one before step 9's land lands no record ...)" with "`--main-log`'s `other` lines are step 0.2's `other` stop, which lands first"
**Location:** SKILL.md:60-64
**Verdict:** Mostly accurate
**Evidence:**
- The new parenthetical names the exception, and the `other` stop does land.
- The general clause "one before step 9's land lands no record" still reads as covering it, because the `other` stop comes before step 9's land in step order.
- "lands first" is ambiguous: first before what? It can be read as "lands before ending". The intent can be recovered, but a reader acting on the general clause would expect no record.

### C9. No remaining SKILL.md text refers to the removed per-step hold
**Location:** commit message ("the Rules, step 1, step 7 and step 10 lose their per-step hold text")
**Verdict:** Verified
**Evidence:** `grep -n -i 'hold\b|holds\b|held|row 776|0\.2'` over SKILL.md finds no "hold" in the old sense. The remaining "0.2" hits are:
- the Rules' stop pointer (:64)
- the stop itself (:264)
- step 1's `chore`-lines condition (:307)
- step 7's "the next step 0.2 stops on it" (:547)
- step 9's SINCE note (:637)
- the final message's `answers` list (:722)

All are consistent with the stop. Step 4 never carried its own hold text. Its "runs no repo test" came from step 1's removed parenthetical.

### C10. A self-merge re-runs `--main-log MAIN` first, "as answers and dispatch already did"
**Location:** SKILL.md:495-496; commit message (C3)
**Verdict:** Verified
**Evidence:** In the pre-image (d00749ab), step 7's answers paragraph already said "Then run `--main-log MAIN` again", and step 10 already said "`--main-log MAIN` run again now". The new self-merge bullet adds the same re-read, and an `other`/`refuse` line there means "no merge or answer this iteration".

### C11. Step 7 answers: on an `other` or `refuse` line after MAIN, "act on no answer this iteration (the next step 0.2 stops on it)"
**Location:** SKILL.md:545-547
**Verdict:** Verified
**Evidence:**
- This iteration's record lands with `Main at: MAIN` (step 9). So the next step 0.2 runs `--main-log MAIN` and lists the same `other` commit, or refuses again if MAIN left main's history. Either triggers the stop.
- The one path where the claim would fail is a stop before step 9's land. That path lands no record, so the next SINCE is the older `Main at:`, which still precedes the commit. The claim holds there too.

### C12. Step 10: dispatch only with no `other` or `refuse` line from `--main-log MAIN` run again
**Location:** SKILL.md:688-689
**Verdict:** Verified
**Evidence:**
- This matches `main_log`'s outputs.
- After step 9's land, `--main-log MAIN` lists this iteration's `gate` and `chore` merges, which do not block.
- `--land-cycle`'s chore merge is classed `chore` only with a record holding `Branch: B` (`chore_record`, :1744-1751). Test T39/U4a passes.

### C13. Approved merge: MAIN_WT's state, no identity or a moved main is retried; any other refusal is filed `stopped`
**Location:** SKILL.md:555-558; commit message (E1)
**Verdict:** Verified (for the text's own claim)
**Evidence:** `--merge`'s header (build-loop.sh:427-450) has refusal kinds for each named case: "no identity is known"; W's state (mid-merge, a tracked change, the state gate in W); and "the branch moved since the check". Everything else now files `stopped`.

Not a factual error, but worth noting: this list is narrower than the self-merge bullet's environment list (:507-509), which also retries "a failed read". An approved merge whose `--merge` hits an unreadable worktree, HEAD or git directory is now filed `stopped` rather than retried.

### C14. "steps 2 and 4b are covered (E2)"
**Location:** commit message
**Verdict:** Verified
**Evidence:** The stop ends the iteration after step 0.3's land, before the digest (0.4) and so before steps 1-4b. While a stop condition holds, no subagent step runs.

### C15. Plan doc: "stops the iteration after step 0 (entry filed, record landed; no tests, merges, answers or dispatch: Q-143 [3])"
**Location:** docs/working/plan-build-loop-handoff.md:343
**Verdict:** Mostly accurate
**Evidence:** SKILL.md stops after step **0.3**, and the digest (step 0.4) does not run. "after step 0" reads as after the whole of step 0, digest included. The parenthetical matches SKILL.md.

### C16. Plan doc: "mid-iteration, such a line in `--main-log MAIN` skips the rest of steps 7 and 10"
**Location:** docs/working/plan-build-loop-handoff.md:343
**Verdict:** Mostly accurate
**Evidence:**
- SKILL.md:495-496 and :545-547 skip only self-merges and acting on answers. Step 7's other work still runs: `--status` reads, review `--check` and its merge entries, filing blocked or stopped entries, and stalled-loop handling.
- Step 10 is skipped as stated (dispatch).
- "the rest of steps 7" overstates the skip.

### C17. The `other` stop keeps "a commit the user has not seen" from feeding a test, merge, answer or dispatch
**Location:** SKILL.md:264-265
**Verdict:** Unverifiable (design property; partly read-static)
**Evidence:**
- Within one iteration, the stop and the three re-reads (self-merge, answers, step 10) close the paths that are named.
- One path is not covered. A commit landing after step 7's last re-read and before step 10's re-read is caught for dispatch. But a commit landing between step 9's merge of main into WT and the next iteration is only caught at the next step 0.2. That is the intended design.
- Claims about subagent behaviour could not be executed.

## Observation (not a verdict; for the merge decision)

The `other` stop lands a record with no digest. Step 9 says the next digest's window starts from the newest record's date, using the file name only (`scripts/dev-cycle.sh:229-260`). Suppose an iteration stops on day D, and the previous record is from an earlier day D0. The next digest's window then starts at D instead of D0. Merges between D0 and D would never be digested, spot-checked or trigger-checked. Step 9's own warning ("a skipped record widens the next window ... so never skip it") assumes that every landed record had a digest. This commit introduced the gap, because before it no record landed ahead of step 0.4.

## Claims requiring attention

### Stale
- **C7** SKILL.md:229-230. "a stop below ends the iteration with no record, so the next one starts from the same `Main at:`" is false for the new `other` stop. The text is unchanged, but this commit made it stale.

### Mostly accurate
- **C3** commit message: "keep holding" whole reads `unrecognized`. The release came from `keep` alone.
- **C8** SKILL.md:60-64: the Rules' general "no record" clause still covers the `other` stop, and "lands first" is ambiguous.
- **C15**, **C16** plan doc:343: "after step 0" should be "after step 0.3"; "skips the rest of steps 7" should say only self-merges and answers.
