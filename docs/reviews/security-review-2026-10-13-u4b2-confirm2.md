Commit: 484eaafc

# Security Review — feat/build-loop-u4b2 (second confirming pass, ccc638d7..484eaafc)

**Scope:** `git diff ccc638d7..484eaafc -- skills` (`skills/dev-cycle/SKILL.md`, 44 changed lines), with the rest of `main...HEAD` as context. Checked against `scripts/lib/dev-cycle-read.sh` (`FENCE_AWK`, `ANSWER_AWK` `option()`, `check_answer`), `scripts/build-loop.sh` (header for --status, --main-log, --merge), `scripts/dev-cycle.sh` (--check-answer header) and the `~/.claude/scripts` link.
**Date:** 2026-10-13
**Based on:** predecessor `docs/reviews/security-review-2026-10-13-u4b2-confirm.md` (N1-N8), rubric "Confirming pass" section, Q-143 option [1].
**Mode:** design review of instructions an orchestrator model executes. Threat: a same-uid build loop (its branch, working trees, refs, `.git` state), or crafted marker, brief, questions or report text, steering the orchestrator into landing, answering or running something the user never approved; plus honest-path failures that fail open. Prose only; no attack recipes.

> ⚠️ **No code fact-check report provided for this range.** Claims about security properties in comments and documentation have not been independently verified beyond the reads and probes named here.

## Trust Boundary Map

```
B1: [main's first-parent commits (same-uid writer)]          → [--main-log class at step 0.2; hold keyed on other-commit / main-log-refused entries] → [self-merge, answers, dispatch, health check, tests]  (moved: hold now covers self-merge and tests)
B2: [answers to hold entries on main (user or answers-class)] → [--check-answer → ANSWER_AWK option()]                                                → [hold release ("keep")]  (new: release = keep)
B3: [the hold entries' location across iterations]           → [orchestrator's lookup (unspecified); step 1's questions.sh archive moves ANSWERED entries] → [hold persists or lapses]  (new)
B4: [main between step 0.2 and step 7]                        → [--status POLICY read live; no --main-log re-read before self-merge]                   → [--merge (self-merge)]
B5: [script refusal lines, git stderr]                        → [Rules: "> Output: LINE", comment opener and CR removed]                                → [agent entries in questions files]  (moved)
B6: [--merge --approved refusal text]                         → [step 7 classification: stopped vs retried]                                             → [questions entries, Applied:, retry]  (moved)
B7: [stranded chore commit]                                   → [merged by the id the session recorded]                                                → [WT, then main as a chore land]  (moved)
```

Input-source classification:

```
S1: main's first-parent commits after MAIN, incl. docs/dev-cycle.md and brief Policy:/Paths: — runtime-mutable (same-uid) — UNTRUSTED for merge/dispatch/exec sinks until reviewed
S2: answer lines in questions files on main                                                — runtime-mutable — UNTRUSTED as approval unless from the user (answers class trusted: row 727 / F19, accepted)
S3: hold-entry headings (other-commit-SHA12, main-log-refused-MAIN12) and their file          — runtime-mutable (archive moves them) — trusted for availability only
S4: script refusal text, git stderr                                                          — request-time (loop-influenced) — UNTRUSTED for text sinks in questions files
S5: --merge refusal WHY                                                                      — request-time — trusted as the gate's own verdict, UNTRUSTED as to cause (planted state reads like environment)
S6: the session's recorded commit id for a stranded land                                     — session memory — trusted (content-addressed)
S7: SKILL.md option labels, answer grammar text                                              — code-constant — trusted, but interacts with S2
```

The range widens the hold to the right sinks and fixes N4, N5 and the quoting shape. What it adds is a release rule whose wording and lookup are new attack surface: the [2] option's label begins with the word that reads as [1], and the entries that now carry the hold past their answer are the ones step 1's own archive moves out of the live file.

## Fix verification (N1-N8)

| Row | Verdict | Basis |
|---|---|---|
| N1 self-merge outside the hold | **Partly closed.** Step 7 now reads "**ready**, POLICY `self-merge` (not while step 0.2's hold is on)" (`SKILL.md:494`). It is keyed on step 0.2's window, though. A commit that lands after step 0.2 and before step 7 is not held for the self-merge. The answer path and step 10 re-run `--main-log MAIN` before they act; the self-merge does not (C3). A held ready brief also has no stated disposition (recorded only through the `7.` line). | read-static |
| N2 release fails open; refused case unslugged | **Partly closed.** Options are now fixed, release happens only on `keep`, and `skip`/`unrecognized`/`drop` hold. The `main-log-refused-MAIN12` slug is added (`:260-263`). Two new problems: the [2] label starts with the release word (C1, executed), and the lookup is unspecified while answered entries are archived (C2). | executed + read-static |
| N3 tests resume next iteration | **Closed.** "skipped while step 0.2's hold is on" (`:303-305`); the hold persists across iterations. Steps 2 and 4b are outside it (C7). | read-static |
| N4 stranded branch merged by name | **Closed.** "merge the commit the session made there (by its id, not the branch name)" (`:267-269`). The content is content-addressed, so the ref is no longer an input to the land. Residual (availability only): "its branch not in main" is still read from the ref. | read-static |
| N5 Rules vs step 7 `--state` | **Closed.** The Rules now read "step 7's self-merge from its GT, after a `--state` from MAIN_WT" (`:48-49`), which agrees with `:496`. | read-static |
| N6 chained skip vs questions gate | **Mostly closed.** "after `questions.sh index` and `check` in WT when this iteration filed or edited entries" (`:646-647`). What a failing `check` leads to is not stated (fix, or stop). `--cycle-diff` catches only what `FENCE_AWK` refuses whole. `questions.sh` resolves to the root-owned image copy (`~/.claude/scripts -> /opt/claude-workflows/scripts`, `-r-xr-xr-x root`), so the new call site is not loop-writable. | read-static + `ls` |
| N7 approved-merge refusal classes | **Partly closed** on the approved path (`:553-557`). Refusals in neither list, and the stopped entries' `Applied:` action, are new gaps (C5). The self-merge path still retries a re-hash refusal (C6). | read-static |
| N8 quoting | **Closed for the reported shapes** (executed: `> Output: [x]: y`, `> Output: <div>` and `` > Output: ``` `` read as text). Single-pass removal can rebuild the opener (C4, executed). Step 10's non-stop entries are still outside the Rule's sentence (C8). | executed |

## Findings

#### C1. The hold entry's option [2] is labelled "keep holding", but the answer grammar reads a bare "keep" as option [1], so answering [2] by its label's first word releases the hold

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:261-263` (options), `:540-541` (grammar); `scripts/lib/dev-cycle-read.sh:2070-2083` (`option()`)
**Boundary:** B2
**Move:** 5 (invert the access model), 11
**Confidence:** Medium (the questions convention says to answer by number; a word answer is still plausible, and the grammar documents word answers as valid)
**Legibility-target:** for-author
**Label:** introduced-by-range

Evidence:
> SKILL.md: "with options **[1] reviewed, build on it** and **[2] keep holding**. The hold lasts, in every later iteration, until each such entry reads `keep` (`--check-answer`)"
> SKILL.md: "An answer starting `[1]`, or that is `1` or `keep` (any case) alone or before one of `.,;:!)*` or a blank and a dash, reads `keep`"
> option(): `if (w == "1" || w == "keep") return "keep"`

Executed (`sec/probe-hold.sh`, temp dir `/tmp/u4b2rv-secc2-dkxT`), with the lib's own `FENCE_AWK`+`ANSWER_AWK` run over an ANSWERED hold entry: `Q-150: keep` → `keep`; `Q-150: Keep.` → `keep`; `Q-150: keep - not reviewed yet` → `keep`; `**Answer:** keep` → `keep`; `Q-150: keep holding` → `unrecognized`; `Q-150: [2] keep holding` → `drop`.

Weakness: the hold is released by the token `keep`, and the option that means "do not release" is the only one whose label begins with that token. A user who answers with the label's first word, alone or with a period or a dash note, picks option [1]. The orchestrator then resumes self-merges, answers, dispatch and tests over a commit the user meant to keep holding. The other entries in the skill do not have this inversion: stopped entries use re-dispatch/drop, and capped entries use [1] keep/[2] drop. Impact: the guard the range adds is undone by an honest answer, and nothing in the final message distinguishes it.

**Recommendation:** Relabel [2] with a word the grammar does not map to an option, e.g. **[2] hold** or **[2] not yet**. Or invert the options so that `keep` means hold, and release on `drop`/`done`. A test can pin it: every option label in SKILL.md that is not [1] must not start with `keep`, `1`, `[1]`.

#### C2. The hold now outlives the entry's answer, but no step says where its entries are found; step 1's own `questions.sh archive` moves an entry answered [2] out of the live file

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:262-264` (hold duration), `:315-319` (step 1 archive), `:537-539` (step 7's `--check-answer` ID list)
**Boundary:** B3
**Move:** 3 (error path), 4
**Confidence:** Medium (whether the hold lapses depends on how the orchestrator fills the gap)
**Legibility-target:** for-author
**Label:** introduced-by-range (before the range the hold lasted only while the entry was `open`, and `archive` moves only ANSWERED entries, so a holding entry was always in `questions.md`)

Evidence:
> SKILL.md:262-264: "The hold lasts, in every later iteration, until each such entry reads `keep` (`--check-answer`), so a commit the user has not seen never feeds a merge, a test run or a loop."
> SKILL.md:317-319: "run `~/.claude/scripts/questions.sh init` ... and then `~/.claude/scripts/questions.sh archive` (it also reindexes), so answered entries leave the live file."
> SKILL.md:538-539: "one call with the IDs ... of every brief's `Asked:` items and merge entries, less those on its `Applied:` line." (hold entries are not named)

Weakness: in a later iteration the window no longer lists the commit, so the hold rests entirely on finding the `other-commit-*`/`main-log-refused-*` entries again. The text names no lookup: which files, which headings, which step, or before step 1. It is not part of step 7's `--check-answer` call either. `check_answer` itself reads both files (`dev-cycle-read.sh:2140`). The risk is a lookup that, as with "the live file", scans only `questions.md`. Once the user answers [2] and sets ANSWERED, as the questions convention asks, the next step 1 archives the entry. A lookup of the live file then finds no hold entry, and the hold lapses with no answer reading `keep`. A loose lookup has a second failure mode: an orchestrator that remembers the hold only within the session loses it on restart. Impact: the same as N2(a), reached through the cycle's own housekeeping instead of a wrong answer.

**Recommendation:** State the lookup once, at step 0.2. Every `### Q-NNN · other-commit-` and `main-log-refused-` heading in both questions files on main (`hg -C MAIN_WT show MAIN:...`) gets one `--check-answer` call before step 1, and any result other than `keep` holds. Alternatively, keep a hold entry out of `archive` until it reads `keep`.

#### C3. Self-merge is held only by step 0.2's window: a commit landing during the iteration can turn on self-merge, and step 7 acts on it without the `--main-log MAIN` re-read the answer path and dispatch run

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:494-507` (ready, self-merge); compare `:543-545` (answers) and `:687-689` (dispatch); `scripts/build-loop.sh:72-75` (--status POLICY from main's commit)
**Boundary:** B4, B1
**Move:** 4 (TOCTOU)
**Confidence:** Medium (the window spans steps 1 to 6, which can run long: the health check may wait up to 3600 s for its lock)
**Legibility-target:** for-author
**Label:** pre-existing (the remainder of N1: the range keys the self-merge on step 0.2's hold and adds no re-read)

Evidence:
> step 7: "**ready**, POLICY `self-merge` (not while step 0.2's hold is on): `--merge BRIEF --expect TIP`"
> answers: "Then run `--main-log MAIN` again: if it lists an `other` line after MAIN, or step 0.2's block holds, act on no answer this iteration"
> --status header: "POLICY: self-merge only when --settings' policy is self-merge and the brief's first "Policy:" line is exactly "Policy: self-merge""

Weakness: `--status` and `--merge` read policy, the never globs, and the brief's `Policy:`/`Paths:` lines from main's live commit. A commit that lands after step 0.2's `--main-log` is invisible to the hold until the next iteration. In this iteration it can switch the settings or a ready brief to self-merge, and step 7 self-merges the loop's branch before any entry exists. The answer path and step 10 close this same window with a re-read; the self-merge, the one sink that lands code without a human, has none. Preconditions: a same-uid writer committing to main while an iteration runs, and a brief at `ready`. Impact: a loop's branch lands under a self-merge trailer the user never authorised (the floor still refuses truth files, dot paths, gate code and never globs).

**Recommendation:** Before each self-merge, run `--main-log MAIN` again (as the answer path does) and do no self-merge on any `other` line. Better, in a later unit: give `--merge` a `--main M` binding like `--land-cycle`'s, so the gate refuses when main moved past the commit the iteration classified. The residual between the re-read and the merge is the same one the answer path already carries.

#### C4. "comment opener ... removed" in one pass can build a new opener from what is left, and a NUL byte is not removed; either makes the questions file unreadable

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:64-66`
**Boundary:** B5
**Move:** 11 (bypass candidates for the sanitiser)
**Confidence:** High (executed)
**Legibility-target:** for-author
**Label:** introduced-by-range

Evidence:
> Rules: "each line as `> Output: LINE` with any HTML comment opener and carriage return removed"
> FENCE_AWK: `if (index(l, "\0")) { refuse("nul"); return 1 }`; `function opencomment(l, ...) { n = split(l, p, /<!--/) ... }`

Executed (`sec/probe-hold.sh`): one pass of global removal over a line that nests an opener inside a partial opener leaves a fresh `<!--`. The resulting `> Output:` line makes `FENCE_AWK` refuse the file (`odd 4 comment`). The prefix itself works: `> Output: [x]: y`, `> Output: <div>` and `` > Output: ``` `` all read as text (`open`). Impact: availability only. `--check-answer` skips every ID in that file, and `--cycle-diff` refuses the land, which is a stop. Each later iteration re-files the same loop-influenced line and stops again until a human edits it. The text that reaches this sink (git stderr naming refs, script WHYs quoting loop data) is loop-influenced.

**Recommendation:** Reuse step 7's `> Reason:` rule for any line holding `<!--`, a NUL or a CR: replace the whole line with a fixed "(not shown: ...)" text. Alternatively, replace every `<` (e.g. with `&lt;`) instead of removing a sequence.

#### C5. The approved-merge refusal lists leave some refusals unclassified, and a `stopped` filing has no `Applied:` action, so the same refusal can be filed again every iteration

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:553-557`, `:560-563`; `scripts/build-loop.sh:300-317` (refuse BRIEF causes)
**Boundary:** B6
**Move:** 3
**Confidence:** Medium
**Legibility-target:** for-author
**Label:** introduced-by-range (the range replaced "any other ... retried" with two closed lists)

Evidence:
> "A refusal that cannot clear (the paths, a conflict, the tip or heading, a brief no longer open, an object that does not hash) is filed as `stopped`; MAIN_WT's state, no identity or a moved main is retried next iteration and named in the final message, the ID left off `Applied:`."
> "ACTION being `redispatch`, `merged`, `drop` or `noted` (`unrecognized`)"
> --merge header: "its branch is absent or not ahead ... the merge (or its changed paths) could not be computed: git failed, or warned on stderr ... names a blob the object store lacks"

Weakness: (a) Several documented refusals fall in neither list: branch absent or not ahead (for example a merge that landed before a lost `Applied:` line), a missing blob, and git failing or warning. What the orchestrator does with them is now a guess, where before the range it was "retry". (b) No ACTION covers "keep, refused, filed stopped". If the ID is left off `Applied:`, the next iteration reads `keep` again, runs `--merge --approved` again, gets the same refusal and files another `stopped-STEM-N`. Fails closed (nothing lands), but it spends the user's attention each iteration and leaves the brief stuck behind an ID never applied.

**Recommendation:** Make the retry list the closed one ("MAIN_WT's state, no identity, a moved main: retried; every other refusal: stopped"). Add `Q-NNN=stopped` as an ACTION, so a refused approval is acted on once.

#### C6. The self-merge path still classes a re-hash refusal ("does not hash ... or could not be read") as the environment's and retries it unfiled

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:505-507`
**Boundary:** B6
**Move:** 3
**Confidence:** Medium
**Legibility-target:** for-author
**Label:** pre-existing (N7's self-merge half, not in the range's fix)

Evidence:
> "Any other refusal (no identity, MAIN_WT's state, a moved main, a failed read) is the environment's, not the loop's: recorded, named in the final message, and tried again next iteration."

Weakness: the range now files the approved path's "an object that does not hash" as `stopped`. On the self-merge path the same refusal, whose text also says "or could not be read", still matches "a failed read" and is retried. A planted-object signal on a loop's branch is therefore filed on one path and only named on the other. Impact: no landing (fails closed); a tamper signal goes unfiled.

**Recommendation:** Use one classification for both paths (C5's closed retry list).

#### C7. Steps 2 and 4b run outside the hold, so "never feeds ... a test run" overstates it

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:36-37` (Rules), `:303-305` (step 1), `:347-351` (step 2)
**Boundary:** B1
**Move:** 5
**Confidence:** Low (it depends on a step 2 subagent choosing to run a repo test as evidence)
**Legibility-target:** for-author
**Label:** pre-existing (step 2's text is unchanged; the range's sentence now claims the property)

Evidence:
> Rules: "Run only commands this skill names and tests that exist in the repo's test tree"
> step 2: "decide **fired / not fired / cannot tell** and write the evidence (a command and its output, a count, a commit)"
> step 0.2: "holds ... the repo's health check and tests (steps 1 and 4) ... so a commit the user has not seen never feeds a merge, a test run or a loop."

Weakness: the hold names steps 1 and 4. Step 2's subagents may run a repo test as a trigger's evidence, and the Rules allow that. Under the hold, a test the unreviewed commit added or changed then runs from WT. Impact: the same as N3, through a narrower route.

**Recommendation:** Say once, in step 0.2, that while the hold is on no step or subagent runs a repo test or script (steps 2, 4 and 4b included), and put that line in their briefs.

#### C8. Step 10's non-stop `agent` entries are still outside the quoting Rule's sentence

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:703-705`; Rules `:62-66`
**Boundary:** B5
**Move:** 2
**Confidence:** Medium
**Legibility-target:** for-author
**Label:** pre-existing (N8 remainder)

Evidence:
> step 10: "Any other refusal or skip: recorded, and one `agent` entry per brief unless an open one names it."
> Rules: "else the line and stderr go in one `agent` entry, each line as `> Output: LINE` ..." (in the paragraph about stops)

Weakness: the form is stated for stop entries. Step 10's refusals are not stops, so the form may not be applied, and a `--start`/`--prompt` refusal quoting loop data can then make the questions file unreadable (availability, fails closed).

**Recommendation:** State the `> Output:` form as applying to every pasted script or git line in any entry.

## Deferred items re-checked

- D3's dispatch half and D4: unchanged by the range; the deferrals stand. C3 is the self-merge analogue of D3. It is not deferrable on the same ground, because the next iteration's hold comes after the merge.
- Row 727 / F19 (an `answers`-class commit is trusted as the user's): it can still release the hold. Accepted residual, not refiled.

## Untested bypass candidates

- C2: an orchestrator that remembers hold IDs within the session vs one that greps the files. Not run; this depends on the model's reading of unspecified text.
- C3: the time from step 0.2 to step 7 in a real iteration. Not measured.
- N4 residual: a loop moving the stranded ref into main's history so that "its branch not in main" reads false, and the stranded commit is skipped (its entries filed again). Not run; availability only.
- C4: other bytes `FENCE_AWK` refuses (a BOM, only on line 1, which an `Output:` line never is). Not run.

## Endorsement Claims

- **Claim:** Under the range's `> Output: LINE` form, quoted lines whose content starts `[x]: y`, `[1]: z`, `<div>` or a backtick fence are read as text by `FENCE_AWK`+`ANSWER_AWK`.
  **Location:** `skills/dev-cycle/SKILL.md:65`; `scripts/lib/dev-cycle-read.sh:273-315`
  **Evidence:** executed
  **Verified:** `sec/probe-hold.sh`, 4 lines, each `open` (no whole-file refusal)
  **Not verified:** `questions.sh check` over the same lines
- **Claim:** `check_answer` reads an entry from either `questions.md` or `questions-archive.md` on main, so an archived hold entry's answer is still readable by ID.
  **Location:** `scripts/lib/dev-cycle-read.sh:2135-2162`
  **Evidence:** read-static
  **Verified:** the loop over both files and the "both files" skip
  **Not verified:** how the orchestrator finds the ID (C2)
  **route: code-fact-check**
- **Claim:** The stranded-land merge input is now the session's recorded commit id, not the branch ref.
  **Location:** `skills/dev-cycle/SKILL.md:267-269`
  **Evidence:** read-static
  **Verified:** the step's text
  **Not verified:** the "not in main" test that decides whether to merge (still ref-based)
  **route: code-fact-check**

## Primitive sweep

Primitive: merge / approval sink
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `SKILL.md:494` step 7 self-merge | S1 | step 0.2 hold only | C3 |
| `SKILL.md:553` merge entry `keep` (`--approved`) | S2 | `--check-answer`, `--main-log MAIN` re-read, hold | cleared for the hold; refusal handling C5 |
| `SKILL.md:262-264` hold release | S2, S3, S7 | `--check-answer` reads `keep` | C1, C2 |

Primitive: process exec (repo tests, scripts, git checkout machinery)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `SKILL.md:303-305` health check | S1 | hold, chain | cleared (N3 closed) |
| step 4 repo tests | S1 | hold | cleared |
| step 2 / 4b evidence commands | S1 | none from the hold | C7 |
| `SKILL.md:646-647` `questions.sh index`/`check` (new) | image copy | root-owned `/opt` path | cleared (not loop-writable) |
| `SKILL.md:267-269` stranded merge by id | S6 | `--state` from WT first | cleared (N4 closed) |
| `SKILL.md:496-498` GT add | repo config | `--state` from MAIN_WT; Rules agree | cleared (N5 closed) |

Primitive: untrusted text into questions files
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `SKILL.md:64-66` stop `agent` entries | S4 | `> Output:`, opener and CR removed | C4 |
| `SKILL.md:703-705` step 10 `agent` entries | S4 | unspecified | C8 |
| `SKILL.md:260-261` `main-log-refused` "quoting the line" | S4 | unspecified form | C8 (same root) |
| `SKILL.md:530-532` `> Reason:` | loop REASON | whole-line replacement | cleared (unchanged) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| C1 | [2] "keep holding" vs grammar's "keep" = [1]: a word answer for [2] releases the hold (introduced; executed) | Medium | B2 | `SKILL.md:261-263`, `:540-541` | Medium |
| C2 | Hold outlives its answer, lookup unspecified; step 1's archive moves the [2]-answered entry out of the live file (introduced) | Medium | B3 | `SKILL.md:262-264`, `:317-319` | Medium |
| C3 | Self-merge held only by step 0.2's window; no `--main-log MAIN` re-read before it (pre-existing, N1 remainder) | Medium | B4, B1 | `SKILL.md:494-507` | Medium |
| C4 | One-pass opener removal rebuilds `<!--`; NUL not removed; questions file unreadable (introduced; executed) | Low | B5 | `SKILL.md:64-66` | High |
| C5 | Approved-merge refusals in neither list; no `Applied:` action for "filed stopped", so refiled each iteration (introduced) | Low | B6 | `SKILL.md:553-563` | Medium |
| C6 | Self-merge path still retries re-hash refusals unfiled (pre-existing, N7 remainder) | Low | B6 | `SKILL.md:505-507` | Medium |
| C7 | Steps 2/4b may run repo tests during the hold (pre-existing; range's claim overstates) | Low | B1 | `SKILL.md:347-351` | Low |
| C8 | Step 10 agent entries outside the quoting Rule (pre-existing, N8 remainder) | Low | B5 | `SKILL.md:703-705` | Medium |

## Overall Assessment

The range closes N3, N4 and N5 outright, and closes N8's reported shapes (executed). The hold now reaches the right sinks. Its new release rule brings two Mediums of its own. C1: the option meant to keep the hold is labelled with the word that releases it, which the probe confirms. C2: the entries that now carry the hold past their answer are exactly what step 1's archive moves, and no step says where to look for them. C3 is the remaining half of N1: the self-merge, unlike answers and dispatch, gets no `--main-log MAIN` re-read, so a commit made during the iteration is not held for it. All three are fixable in SKILL.md text: relabel [2], name the lookup over both files before step 1, and re-read before each self-merge. A `--merge --main M` binding is the stronger script-side fix for C3, for a later unit. The Lows fail closed or are attention costs. No HALT pattern applies. Within the code paths read, there are no further findings, and the endorsement claims marked read-static are pending execution verification.

## Goal-Alignment Note
- Success criterion (restated verbatim): A security review saved at the given path, structured per the security-reviewer skill
- Answered: yes. The range ccc638d7..484eaafc of `skills/dev-cycle/SKILL.md` was reviewed with the branch as context, and N1-N8 were each verified. N3, N4, N5 and N8 (reported shapes) are closed; N6 is mostly closed; N1, N2 and N7 are partly closed. 8 findings: 3 Medium (2 introduced, 1 pre-existing) and 5 Low (2 introduced, 3 pre-existing). One probe was executed (`sec/probe-hold.sh`, temp dir `/tmp/u4b2rv-secc2-dkxT`, left in place; no git operations, no processes left running).
- Out of scope: the D6 block (Q-140); the bats test (not in the skills range); performance and API concerns.
- Escalate: C1 and C2. Each lets the new hold lapse without the user's release; C1 through the user's own honest answer.
- Decisions I made: labelled C2 introduced because before the range a holding entry was always `open` and so never archived. Labelled C3 pre-existing as the unfixed half of N1, not as a new regression. Treated an orchestrator's unspecified lookup as a real gap, because SKILL.md text is behaviour.
