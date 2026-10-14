Commit: b88e418a

# Security Review — feat/build-loop-u4b2 (iteration 3, final pass)

**Scope:** `git diff main...HEAD` at b88e418a: `skills/dev-cycle/SKILL.md` (steps 0.2, 1, 6-10, Rules, Flow) and `test/scripts/build-loop-orchestrator.bats` (one test). Read against the `scripts/build-loop.sh` header (--status, --marker, --state, --main-log, --cycle-diff, --land-cycle, --merge, --start, --prompt), its `state_gate`, `approval`, `steal`/`ended` and `QDIFF_AWK`, `scripts/lib/dev-cycle-read.sh` (`FENCE_AWK`, `scrub`, `pathform`), `scripts/questions.sh` (index markers), plan D13 and override-log rows 720, 726, 727, 776 and the 2026-10-13 rows for this branch.
**Date:** 2026-10-13
**Based on:** `docs/reviews/code-fact-check-report-2026-10-13-u4b2-final-r{1,2,3}.md` and the rubric's C1-C10 (fixed in b88e418a); the prior `docs/reviews/security-review-2026-10-13-u4b2-i2.md` (F1-F9) and the rubric's B3-B7 statuses.
**Mode:** design review of instructions an orchestrator model executes. Threat: a same-uid build loop (writes its branch, working trees, `.git` state) or crafted marker, brief, questions or report text steering the orchestrator; plus honest-path failures that fail open. Weaknesses are in prose (weakness, preconditions, impact, fix); no attack recipes.

## Trust Boundary Map

```
B1: [loop marker subject REASON / --marker WHY / --check refusal] → [step 7 "> Reason:" line, <!-- replaced]        → [questions entry text in WT, then main]
B2: [questions answers on main (any first-parent commit)]         → [--main-log MAIN re-run, then --check-answer]  → [step 7 actions: --merge --approved, drop, re-dispatch]
B3: [main's first-parent history (any same-uid writer)]           → [--main-log class, per iteration window]        → [step 10 dispatch, step 7 answers, step 1 health check]
B4: [repo-local .git state: common config, each worktree's config.worktree, info/*] → [--state (snapshot, from one worktree) + hg] → [git checkout/merge the orchestrator runs: GT worktree add, merge of main into WT]
B5: [loop reports / task notifications in the orchestrator's conversation] → [Rules' data list; step 9.3 wording] → [--cycle-diff/--land-cycle --answered]  (moved: text-only guard)
B6: [WT's index after step 9's commit]                             → [--cycle-diff, then --land-cycle's own re-judgment] → [main]  (moved: commit now precedes --cycle-diff)
```

Input-source classification:

```
S1: marker subject REASON, --marker skip WHY        — request-time (loop-written) — UNTRUSTED for text sinks in questions files; 1-120 printable ASCII
S2: questions answers and headings on main           — runtime-mutable (user, chore land, or any same-uid commit) — UNTRUSTED as approval unless its commit is classified first
S3: main's first-parent commits after a --main-log read — runtime-mutable — UNTRUSTED for dispatch/approval sinks until classified
S4: MAIN_WT's own config.worktree                    — runtime-mutable (loop-writable) — UNTRUSTED for exec sinks (filters run by checkout)
S5: main's committed .gitattributes                  — runtime-mutable via merges — names which filter driver a checkout calls; inert without S4/common config
S6: loop subagent reports in the conversation        — request-time — UNTRUSTED for "answers the user gave this session"
S7: SKILL.md's GATE_CODE copy, DISPATCH_CAP/STEAL_AGE text — code-constant, pinned by bats — trusted
```

The iteration-2 fixes moved the right guards into place (REASON on a quoted line, `--state` before GT and before each merge-in, a fresh `--main-log MAIN` before answers and dispatch, a commit-first land). The gaps left are where a guard reads a different scope than the action it protects: `--state` from WT before a checkout run from MAIN_WT, a `--main-log` window that ends one iteration later, and a `--main-log` read placed before the reads it is meant to cover.

## Findings

#### F1. The `other`-commit block is window-scoped: it does not defer answers from step 0.2's window, and it lapses entirely one iteration later, while its judgment entry is still open

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:250-257` (step 0.2), `:519-527` (step 7 answers), `:663-666` (step 10), `:290-294` (step 1 skip)
**Boundary:** B2, B3
**Move:** 4 (TOCTOU), 5 (invert the access model), 3 (fail-open path)
**Confidence:** High (read-static; ordering and window arithmetic)
**Legibility-target:** for-author

Evidence:
> step 0.2: "Any `other` line, or a `refuse main-log:` line other than the bootstrap's own (...), blocks this iteration's dispatch and gets one `you: judgment` entry naming its SHA or quoting the line, unless an open one does (rows 720, 726)."
> step 7: "First run `--main-log MAIN` again: if it lists an `other` line after MAIN, act on no answer this iteration (the next one's step 0.2 classifies that commit and files it), so every answer acted on came in a commit the user is shown (row 727)."
> step 9 template note: "step 0.2 takes the file's last `Main at:` line as the next SINCE (MAIN, the commit this iteration started from ...)"
> plan D13: "Any `other` stops dispatch and files one `you: judgment` entry naming the commit (F43)."
> rubric B4 status: "Fixed: --main-log MAIN again before acting; an other line defers all answers"

Weakness: two gaps, one root. (a) Step 7 defers answers only on an `other` line *after* MAIN; an `other` commit in step 0.2's window (SINCE..MAIN) blocks dispatch but not answer actions, so its content is acted on in the same iteration that first files it. The rubric records B4 as "an other line defers all answers"; the text does less. (b) Every block keyed on an `other` line lasts one iteration. The record is still written (an `other` line is no stop), so the next SINCE is past the commit. The next iteration's step 0.2 no longer lists it. Dispatch, answer actions and the step 1 health check (row 776's skip) then resume over the unreviewed commit while its `you: judgment` entry is still open. The window is the 1200-1800 s wait, or the next task notification.

Preconditions: any commit on main outside the design, from a same-uid writer or an honest hand edit (row 726 notes every hand landing reads `other`). Impact: an `other` commit can add a merge entry heading for a tip the user never reviewed, together with a `[1]` answer. Step 7 then treats the brief as "already asked about at TIP" ("WT's questions files hold its merge entry's heading"), reads `keep` and runs `--merge --approved`. `approval()` checks only the heading shape and the answer on main, so the merge lands with a `Build-loop-approved:` trailer that makes it look approved. Under (a) that happens in the same iteration that files the commit. Under (b), once the user's answer is merely pending, constraints or brief changes in the commit also feed the dispatched loops. Either way the user's judgment entry arrives after the action, which is the order F43 and row 727 exist to prevent.

**Recommendation:** Key the block on the open entry rather than on the window. Give `other`/main-log-refusal entries a fixed slug, e.g. `other-main-SHA12`. While `--check-answer` reads any such entry `open` (or the entry is filed this iteration), skip step 7's answer actions, step 10's dispatch, step 1's health check and step 4's test runs. Also let an `other` line from step 0.2 defer answers in the same iteration, as the rubric's B4 status says.

#### F2. `--state` before the gate checkout runs from WT, so a filter planted in MAIN_WT's own `config.worktree` passes it and runs during `worktree add` (executed)

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:478-483` (step 7, ready/self-merge); `scripts/build-loop.sh:613-620` (`state_gate` reads `--git-path config.worktree`, the caller's own worktree only)
**Boundary:** B4
**Move:** 4 (TOCTOU), 11 (bypass of the B5 fix), 12
**Confidence:** High (executed: `sec/probe-gt-wtconfig.sh`)
**Legibility-target:** for-author

Evidence:
> "**ready**, POLICY `self-merge`: `--merge BRIEF --expect TIP`, run from a gate checkout, not WT: `--state` (from WT), then `hg -C MAIN_WT worktree add --detach GT refs/heads/main`" [unit continues: GT's name and removal, merged line, fall-through and environment refusals]
> state_gate: `for f in config config.worktree; do p="$(git rev-parse --path-format=absolute --git-path "$f" 2>/dev/null)"`

Weakness: `state_gate` checks the common config and *the calling worktree's* `config.worktree`. Run from WT, it never reads MAIN_WT's `.git/config.worktree`. `worktree add` is run in MAIN_WT, and git (2.39 here) copies the current worktree's `config.worktree` into the new worktree when `extensions.worktreeConfig` is on. The checkout into GT then reads the copy. `hg` overrides global/system config and hooks, not repository worktree config. Probe (temp repo; the skill's `hg` verbatim; main's tree carrying a filter attribute in `.gitattributes`, as any LFS repository does; a smudge key planted in MAIN_WT's `config.worktree` after WT existed): `--state` from WT printed `ok`, the same call from MAIN_WT refused `filter.x.smudge: set in config.worktree`, and the planted smudge ran during `hg -C MAIN_WT worktree add --detach GT`. Step 0.3's WT add is not affected: step 0.1's `--state` runs from MAIN_WT just before it.

Preconditions: a same-uid loop writes MAIN_WT's `config.worktree` and enables `extensions.worktreeConfig` (a common-config key `state_gate` does not list). An attribute that names a filter must also come from main's tree (`info/attributes` is in the common dir and is caught). Impact: the orchestrator runs a loop-chosen command, the primitive B5/F3 was fixed to stop. Privilege gain is limited by the shared uid, as in i2 F3.

**Recommendation:** Run this `--state` from MAIN_WT, the checkout `worktree add` runs in (the Rules' D6 sentence then names it), or run it from both. Alternatively, have `state_gate` scan every registered worktree's `config.worktree` and refuse `extensions.worktreeConfig` outright, since nothing in this design needs it. Add a bats case with the planted per-worktree key.

#### F3. The fresh `--main-log MAIN` read precedes the reads it guards, so a commit landing between it and `--check-answer` (or `--start`) is acted on unclassified

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:519-527` (step 7 answers), `:663-672` (step 10)
**Boundary:** B2, B3
**Move:** 4 (TOCTOU)
**Confidence:** Medium (read-static; needs a writer that times a commit into a window of one or two tool calls)
**Legibility-target:** for-author

Evidence:
> step 7: "Then answers, only through `--check-answer` (main's commit ...) ... First run `--main-log MAIN` again: if it lists an `other` line after MAIN, act on no answer this iteration"
> step 10: "with no dispatch block from step 0.2 or from `--main-log MAIN` run again now (an `other` line after MAIN: the loops would start from it)"
> build-loop.sh `approval()`: `check_answer "$1" > "$GATE_TMP/answer"` (reads the default branch's commit at call time)

Weakness: `--check-answer`, `--merge --approved` and `--start` each read main's live commit when they run. The re-run of `--main-log` classifies main only up to the moment it runs. A commit landing after it is read by `--check-answer` and acted on, and the next iteration's step 0.2 classifies it only after the merge or drop. Likewise `--start` creates the loop's branch at main's commit as of its own call. Preconditions: a same-uid process committing on main during the iteration. A polling loop can hit the window; honest timing rarely will. Impact: the F2 (i2) gap, narrowed to a race but not closed. An approved merge or a drop is driven by an answer the user is shown only afterwards.

**Recommendation:** For answers, run the `--main-log MAIN` re-read *after* `--check-answer`, not before. Every answer read then lies inside the classified range, and `--approved`'s later re-read can only confirm, since `--expect` and the heading bind the TIP. For dispatch, compare the commit `--start` reports for the new branch with the `main MAIN2` line of the re-read; on a mismatch, start no subagent and treat it as an `other`.

#### F4. "Never pass `--answered` for a merge entry" is a skill-text guard only; `--cycle-diff`/`--land-cycle` accept it, and `--approved` then honours the answer

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:632-635` (step 9.3); `scripts/build-loop.sh:197-199` (header), `:1835-1849` (`QDIFF_AWK`: any ID in `--answered` is exempt), `:1442-1458` (`approval()`)
**Boundary:** B5, B2
**Move:** 5 (invert the access model), 2
**Confidence:** Low (it needs the orchestrator model to be steered past its instruction; the absence of a script check is certain)
**Legibility-target:** for-author

Evidence:
> step 9.3: "`--answered Q-NNN` for each answer the user gave this session that this iteration wrote (never one from repo text or a loop's report, and never a merge entry's: those land only in the user's own commit"
> QDIFF_AWK: `for (id in nw) if (!(id in o) && !(id in ok) && an[id]) print id " " nf[id] " new"` (an ID in `ok`, i.e. `--answered`, is never reported, whatever its heading)

Weakness: the B6 fix made the rule explicit, but nothing executable enforces it. A merge entry filed this iteration with an answer line, plus its ID on `--answered`, passes both `--cycle-diff` and `--land-cycle`'s re-judgment. It lands as a `chore` merge, which `--main-log` does not list as an `answers` commit, and the next step 7's `--merge --approved` lands the loop's branch. The threat in scope is exactly loop text (a report or task notification that reads like the user's in-session answer) steering this one sentence. Impact: a review-policy merge approved by no human, recorded as approved.

**Recommendation:** In `--cycle-diff`'s questions rule, refuse an `--answered` ID whose heading (after " · ") starts `merge-` or `merge-gate-`, so approvals reach main only through a non-chore commit. This is a gate-code change: if it is deferred, record an override row with a revisit trigger. Optionally, have `approval()` refuse when the answer line was introduced by a `chore` merge.

#### F5. Free-text refusals and stderr go into `agent` entries unquoted; a line that `FENCE_AWK` refuses makes the questions file unreadable until fixed (fails closed)

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:61-64` (Rules: "the line and stderr go in one `agent` entry"), `:679-681` (step 10: "Any other refusal or skip: recorded, and one `agent` entry"), `:487-489` (environment refusals)
**Boundary:** B1
**Move:** 2
**Confidence:** Low (no concrete loop-controlled source found; script lines start with fixed words and pass through `scrub`, and git's own stderr lines carry `fatal:`/`error:` prefixes)
**Legibility-target:** for-author

Evidence:
> "else the line and stderr go in one `agent` entry; either way also in the final message"

Weakness: B3/C2/C3 put the loop's REASON on a `> Reason:` line, but the other places that paste script output into the questions files give no form. A pasted line that starts with `<`, opens `<!--`, or starts like a link reference definition makes `--check-answer` refuse the whole file. `--cycle-diff` then refuses the land ("a questions file `--check-answer` refuses whole"). That is a safe failure, but it leaves a stall the orchestrator must notice and repair. Impact: availability only.

**Recommendation:** Say once in the Rules that any script line or stderr pasted into a questions entry goes on `> ` lines, with `<!--` replaced as step 7 does for REASON. That reuses the form already verified for REASON (see the endorsement claims).

## Deferred items re-checked

- i2 F6 (floor notes by class), F8 (`--steal` on another session's loop), F9 (conditional `[1]`): the deferrals stand. F8's revisit trigger names the case, and `--steal` is now passed on every re-dispatch, which matches its row. F9's answer is still the user's own text.
- GT name reuse, merge entries tracked by heading, the lost `Dispatched:` count: the deferrals stand. F1 above is not the heading-tracking row: it concerns *who* can add a merge heading on main (an unblocked `other` commit), not how the orchestrator ties it.

## Untested bypass candidates

- F2: a filter planted in GT's own future `config.worktree` path before GT exists (`.git/worktrees/<GT name>/` pre-created, since the name is predictable). Not run; git normally refuses an existing admin dir, so this was left untested.
- F2: `include.path` or `includeIf` in MAIN_WT's `config.worktree` pointing at a filter. Not run. `state_gate` refuses `include*` keys only in the file it reads, so this falls under the same scope gap.
- F1: an `answers`-class commit (one that cannot add a heading) answering a merge entry already filed by the orchestrator. Not a bypass: row 727 Won't-Fix accepts it.
- F3: a commit landing between `--check-answer` and `--merge --approved` that rewrites the heading to another SHA12. Traced: `--expect` binds the orchestrator's TIP and the heading must match it, so the merge refuses (fails closed).

## Endorsement Claims

- **Claim:** A `> Reason: REASON` line, for each sampled printable-ASCII REASON (a `[x]: y` label, an open `[`, a raw `<b>` tag, a backtick or tilde fence, `-->`, the replacement text, an escaped `\[`), is read as text by `FENCE_AWK`: none of those samples triggers the html, comment, refdef or fence refusal.
  **Location:** `skills/dev-cycle/SKILL.md:511-515`; `scripts/lib/dev-cycle-read.sh:273-315`
  **Evidence:** executed
  **Verified:** `sec/probe-reason.sh` ran `FENCE_AWK`, extracted verbatim from the lib, over those eight lines: all `text`. `questions.sh`'s index markers (`<!-- index:start -->`, `<!-- index:end -->`) both contain `<!--`, which the replacement rule removes.
  **Not verified:** `questions.sh index`/`archive` run over a full entry holding such a line; `ANSWER_AWK` over it.
  **route: code-fact-check**
- **Claim:** Committing before `--cycle-diff` (C1) does not let a refused change land: `--land-cycle` re-judges the merge of HEAD into main by `--cycle-diff`'s rules, with the same `--answered`, before it moves main.
  **Location:** `skills/dev-cycle/SKILL.md:627-650`; `scripts/build-loop.sh:240-252` (header)
  **Evidence:** read-static
  **Verified:** the `--land-cycle` header text ("is judged against main by --cycle-diff's rules with these --answered IDs") and the skill's order (commit, `--cycle-diff`, `--land-cycle --main M`)
  **Not verified:** `land_cycle()`'s call into `cycle_rules` (`scripts/build-loop.sh:2043-2075`, read only in part)
  **route: code-fact-check**
- **Claim:** `--approved` honours an answer only under the exact heading `Q-NNN · merge[-gate]-STEM-SHA12` built from the `--expect` tip, so a heading for another tip refuses.
  **Location:** `scripts/build-loop.sh:1442-1458`
  **Evidence:** read-static
  **Verified:** `approval()`'s `case` over `check_answer`'s line and its `ANSWER_HEADING` comparison
  **Not verified:** that `VERDICT[tip]` is the `--expect` value on every path into `approval()` (`check_line` not read)
  **route: code-fact-check**

## Primitive sweep

Primitive: process exec through git checkout/merge machinery (filters, merge drivers)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `SKILL.md:258` step 0.3 `hg -C MAIN_WT worktree add -b ... WT MAIN` | S4, S5 | `--state` from MAIN_WT at 0.1, just before | cleared: same worktree scope, narrow window |
| `SKILL.md:479` step 7 GT `hg -C MAIN_WT worktree add --detach` | S4, S5 | `--state` from WT | F2 (executed) |
| `SKILL.md:657` merge of main into WT | S4 (WT's), S5 | `--state` from WT, the same worktree | cleared: scope matches |
| `SKILL.md:628` `hg -C WT commit --no-verify` | S4 | `--state` at 9.2, hooksPath=/dev/null | cleared |
| `SKILL.md:260`, `:481` `worktree remove --force` | S4 | no status run | cleared (per step 0.3's rationale; not executed) |
| `--merge` in GT / `--land-cycle` fast-forward in MAIN_WT | S4 | script's W state gate (`build-loop.sh:1528`) | cleared (header and comment read) |
| `SKILL.md:290` health check; step 4 tests | S3 | skipped only in the iteration that lists `other` | F1(b) |

Primitive: write of untrusted text into the questions files
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `SKILL.md:511-513` `> Reason: REASON` | S1 | `> ` prefix, `<!--` replaced | cleared (executed, endorsement 1) |
| `SKILL.md:514` `--marker` lines verbatim | S1 | script body rules, `> ` prefix | cleared (header) |
| `SKILL.md:495` `--check` lines in a merge entry | S1 (paths) | `pathform` charset, fixed line prefixes | cleared |
| `SKILL.md:61-64`, `:680` refusal line and stderr in `agent` entries | script/git text | `scrub` only | F5 (fails closed) |

Primitive: approval sink (`--merge --approved`)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `SKILL.md:535` step 7 merge entry `keep` | S2, S3 | `--main-log MAIN` re-read before `--check-answer`, after-MAIN only | F1(a), F3 |
| `SKILL.md:632` `--answered` into a chore land | S6 | skill text only | F4 |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | `other` block is window-scoped: step 0.2's `other` does not defer answers; all blocks lapse next iteration with the entry still open | Medium | B2, B3 | `SKILL.md:250-257`, `:519-527`, `:663-666` | High |
| F2 | GT's `--state` runs from WT; a MAIN_WT `config.worktree` filter passes and runs in `worktree add` | Medium | B4 | `SKILL.md:478-483`; `build-loop.sh:613-620` | High |
| F3 | `--main-log MAIN` re-read precedes `--check-answer`/`--start`; a commit in between is acted on unclassified | Medium | B2, B3 | `SKILL.md:519-527`, `:663-672` | Medium |
| F4 | "No `--answered` for a merge entry" is text-only; the scripts accept it and `--approved` honours it | Medium | B5, B2 | `SKILL.md:632-635`; `build-loop.sh:1835-1849` | Low |
| F5 | Refusal lines and stderr pasted unquoted into `agent` entries can make the questions file unreadable (fails closed) | Low | B1 | `SKILL.md:61-64`, `:679-681` | Low |

## Overall Assessment

The iteration-2 fixes are mostly right, and the final-pass fixes (commit before `--cycle-diff`, `> Reason:` lines, environment-refusal retry) open no new exec or injection path that I found. The `> Reason:` form was executed clean against `FENCE_AWK`. Three of the four Medium findings share one pattern: a guard reads a different scope than the action it protects. F2 checks the wrong worktree's config (executed). F1 has a classification window that ends before the user has answered. F3 runs its classification read before the reads it covers. The most important item is F1. Fixing it closes the path by which an ungated commit on main can plant and answer a merge entry and get a loop's unreviewed tip landed under a `Build-loop-approved:` trailer, and it restores plan D13's "any other stops dispatch". F2 is a one-word fix in the skill (`from MAIN_WT`). F4 needs a gate-code change and may be deferred with a row. No HALT pattern applies. No findings exist outside the code paths read; the endorsement claims are pending execution verification.

## Goal-Alignment Note
- Success criterion (restated verbatim): A security review saved at the given path, structured per the security-reviewer skill
- Answered: yes. Full branch main...HEAD at b88e418a. 5 findings (4 Medium, 1 Low); 2 executed probes (`sec/probe-gt-wtconfig.sh` for F2, `sec/probe-reason.sh` for endorsement 1); the deferred i2 rows were re-checked and stand.
- Out of scope: script implementations beyond the functions cited; the D6 block (pending Q-140); performance and API concerns.
- Escalate: F1 (contradicts plan D13 and the rubric's B4 status) and F2 (executed bypass of the B5 fix).
- Decisions I made: treated a same-uid writer committing on main and writing MAIN_WT's `.git` as in scope, per the brief's threat statement. Rated F4 Medium under the floor rule (a named mechanism in the stated threat model), with Low confidence because it depends on model compliance. Kept F5 Low because it fails closed.
