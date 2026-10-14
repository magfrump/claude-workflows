Commit: c8d90d62

# Security Review — feat/build-loop-u4b2 (third confirming pass, d00749ab..c8d90d62)

**Scope:** `git diff d00749ab..c8d90d62` (6beca252, c8d90d62): `skills/dev-cycle/SKILL.md` (the Q-143 [3] `other` stop, the mid-iteration re-reads, approved-merge refusal classes, the stop's record in the newest file), `docs/working/plan-build-loop-handoff.md` (as-built note). The rest of `main...HEAD` was used as context only. Read against `scripts/build-loop.sh` (`log_class`, `ANSWERS_AWK`, `chore_record`, `main_log`, `--cycle-diff`/`--land-cycle` headers), `scripts/lib/dev-cycle-read.sh` (`ANSWER_AWK`, `check_answer`, `isrecord`/`writable`) and `scripts/dev-cycle.sh` (the digest's window).
**Date:** 2026-10-13
**Based on:** `docs/reviews/security-review-2026-10-13-u4b2-confirm2.md` (C1-C8), the rubric's E1/E2, and `docs/reviews/code-fact-check-report-2026-10-13-u4b2-confirm3.md` (6beca252; its Stale C7 and the digest-window observation are what c8d90d62 addresses).
**Mode:** design review of instructions an orchestrator model executes. Threat model (given): a commit on main the user has not reviewed, or a rewritten main, must never feed a test run, a merge or a dispatch. Loops' branches and repo text are untrusted. Prose only; no attack recipes.

## Trust Boundary Map

```
B1: [main's first-parent commits after SINCE]               → [--main-log classes; the other stop at step 0.2]                 → [digest, tests, merges, answers, dispatch]  (moved: hold → stop)
B2: [answers to other-commit / main-log-refused entries]     → [--check-answer on main's commit (ANSWER_AWK)]                   → [stop released ("keep")]
B3: [entry headings in WT's two questions files]             → [orchestrator's slug lookup + "unless WT's files hold one"]       → [which IDs gate the stop; whether a new entry is filed]  (new)
B4: [main moving during an iteration]                        → [--main-log MAIN re-read before self-merge, answers, dispatch]    → [--merge, --merge --approved, --start/--prompt]  (new for self-merge)
B5: [the stop's record block]                                → [appended to the newest record; --cycle-diff, chore_record]        → [next SINCE; next digest window]  (new)
B6: [--merge --approved refusal text]                        → [step 7: retry (3 named causes) vs stopped (all else)]            → [questions entries, Applied:]  (moved)
```

Input-source classification:

```
S1: main's first-parent commits after SINCE/MAIN     — runtime-mutable (same-uid writer) — UNTRUSTED for test/merge/dispatch until the user answers [1]
S2: answer lines on main (answers class)              — runtime-mutable — trusted as the user's by the accepted row 727 / F19 residual; UNTRUSTED otherwise
S3: questions-entry headings (slugs) in WT            — runtime-mutable (WT = MAIN, written by any commit on main) — trusted for availability only
S4: the newest record's last `Main at:` and file name — runtime-mutable — trusted for window/SINCE only because a non-chore change to it is classed other
S5: --merge refusal text                              — request-time — trusted as the gate's verdict, not as to cause
S6: SKILL.md option labels / answer grammar           — code-constant
```

The range turns the per-step hold into one stop at step 0.2 that runs before the digest. This removes the class of "which step is under the hold" gaps (C2, C3, C7/E2) and leaves the release resting on one rule: every `other-commit-`/`main-log-refused-` entry in the two questions files reads `keep`. The new surface is that rule's lookup and dedupe (B3), its interaction with the digest window and the session's own window check (B5), and honest-path release paths that fail closed and so never lift the stop.

## Fix verification (C1-C8, E1, E2)

| Row | Verdict | Basis |
|---|---|---|
| C1 [2] label read as keep | **Closed.** [2] is now **not yet**. Executed (own probe and fact-check confirm3): `[2] not yet` → drop, `not yet` → unrecognized, `reviewed, build on it` → unrecognized, `1 - reviewed` → keep. No label's first word is a release word. | executed |
| C2 lookup unspecified; archive lapses the hold | **Closed.** The lookup is now named: entries with either slug in WT's `questions.md` **and** `questions-archive.md`, read by `--check-answer`, which reads both files on main (`dev-cycle-read.sh:2135-2167`). Step 1's archive cannot run while any such entry is not `keep`, because the iteration stops before step 1. | read-static |
| C3 self-merge without re-read | **Closed in text.** Step 7's self-merge runs "only if `--main-log MAIN`, run again, lists no `other` or `refuse` line after MAIN" (`SKILL.md:496-497`). Residual: the gap between that re-read and `--merge`, the same one the answer path and dispatch carry. A `--main M` binding on `--merge` remains the script-side fix. | read-static |
| C4 one-pass opener removal / NUL | **Open, now pre-existing.** The Rules' sentence (`SKILL.md:65-66`) is unchanged. | read-static |
| C5 / E1 approved-merge refusals in neither list | **(a) Closed.** Retry is the closed list (MAIN_WT's state, no identity, a moved main), and "any other refusal is filed as `stopped`" (`:557-559`). **(b) Open, pre-existing:** there is still no `Applied:` ACTION for "refused, filed stopped" (`:562-565`). The text names leaving the ID off `Applied:` only for the retry case, so a literal reading re-runs `--approved` and files another `stopped-` entry each iteration. Fails closed. | read-static |
| C6 self-merge retries a re-hash / failed read | **Open, pre-existing, now inverted.** The approved path files "a failed read" as `stopped`, while the self-merge path still retries it (`:507-509`), as fact-check confirm3 C13 notes. Fails closed. | read-static |
| C7 / E2 steps 2 and 4b outside the hold | **Closed.** The stop ends the iteration after step 0.3's land, before step 0.4's digest, so no step 1-4b work (subagents included) runs. The health check after a stop runs again because `stopped: step 0.2` matches neither skip form (`:306-308`). | read-static |
| C8 step 10's agent entries outside the quoting Rule | **Open, pre-existing.** `:705-706` is unchanged. | read-static |

## Findings

#### F1. The session's own window check rewinds the digest past the gap c8d90d62 closes

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:264-266` (the stop appends to the newest record), `:286-289` (step 0.4: "if the window starts before the last cycle you know ran ... rerun with `--since` set to that cycle's date"); `scripts/dev-cycle.sh:225-245`
**Boundary:** B5
**Move:** 4, 3
**Confidence:** Medium (it depends on the orchestrator counting a stop iteration as "a cycle you know ran", which a literal reading does)
**Label:** introduced by this range (c8d90d62)

c8d90d62 appends the stop's block to the newest record (day D0) so the next digest's window still starts at D0 (the digest reads only the file name). In the same session, the next iteration's step 0.4 compares the Window line with "the last cycle you know ran". That is the stop iteration on day D > D0, so the check reads the D0 window as "that cycle skipped step 9" and reruns with `--since D`. Merges between D0 and D are then never digested, spot-checked or trigger-checked: exactly the gap the commit says it keeps closed. Across sessions the check has no memory and the fix holds. Impact: a detective-control gap (spot-check and trigger coverage), not a gate bypass. The merges in it already passed the gate or the user.

**Recommendation:** In step 0.4, say that a stop iteration (`1.` line `stopped: step 0.2`) is not a cycle that ran for this check. Or compare the window with the last record that has a Window line.

#### F2. The entry dedupe now counts answered entries, so a `keep` given for one occurrence covers a later, different one with the same slug

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:258-261` ("unless WT's questions files hold one", previously "unless an open one does")
**Boundary:** B3, B2
**Move:** 11, 5
**Confidence:** Medium
**Label:** introduced by this range (6beca252)

Before the range, only an `open` entry suppressed filing. Now any entry with the slug does, including one answered `keep` long ago. The stop still fires once, because the line is listed, but no new question is filed. From the next iteration the old `keep` releases it. Three ways to reach this:
- **Main rolled back.** `main-log-refused-MAIN12` keys only on MAIN, not SINCE, so main rolled back to a tip whose earlier rewrite the user approved goes through with one stop and no ask.
- **SHA prefix match.** A commit whose SHA's first 12 hex digits match an approved `other-commit-` slug: 48 bits, attacker-grindable, not an honest event.
- **Forged heading.** An `other` commit Y that adds a pre-answered heading for an earlier `other` commit X. The user is then asked about Y only, and X's approval rides on reviewing Y's diff. The fixpoint makes it impossible for X to forge its own heading.

The forged heading and the prefix match need a main writer, and those are dominated by F19 (below). The rollback is an honest event, but every commit at that tip was approved before. Impact: an approval is reused for an occurrence the user never saw as a question.

**Recommendation:** Count an entry for the dedupe only if it is open, or was on main at SINCE (an entry added by a listed commit never counts). Key `main-log-refused-` on SINCE and MAIN.

#### F3. Two honest release paths never lift the stop: a later `[1]` appended below `[2] not yet`, and an answer told to the session

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:261` (options), `:541-543` (grammar); `scripts/lib/dev-cycle-read.sh` `ANSWER_AWK` (the first answer line decides: `done = 1`); `SKILL.md:264-267` (the stop's land), `:630-634` (`--answered`)
**Boundary:** B2
**Move:** 3
**Confidence:** High for (a) (executed); Medium for (b)
**Label:** introduced by this range (the [2] "not yet" option invites the second answer; the stop is what skips step 9's answer-writing)

- **(a) A later [1] below the [2].** Executed (probe below): an entry answered `Q-900: [2] not yet` with `Q-900: [1] reviewed now` appended below it reads `drop`, and with the order reversed reads `keep`. "Not yet" invites exactly that later second line. The stop then holds indefinitely, and each wakeup that sees main move stops again.
- **(b) An answer told to the session.** The final message tells the user "tell me, or commit it yourself". The stop's land is "as step 9 does", but the stop also does "no ... answers", and the text does not say whether it writes an in-session answer with `--answered`. If it does not, `--check-answer` (main only) never sees that answer.

Both fail closed: availability and attention, not exposure.

**Recommendation:** In the entry's body or the stop text, say that a changed answer replaces the first answer line. And say that the stop's land writes in-session answers to its own entries with `--answered`, as step 9 does.

#### F4. A `refuse main-log` from a listing failure advances `Main at:` past commits that were never classified, and [1] approves them unseen

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:255-267`; `scripts/build-loop.sh:1796-1810` ("the default branch's first-parent history could not be listed")
**Boundary:** B1, B5
**Move:** 3
**Confidence:** Medium
**Label:** pre-existing (the hold also landed `Main at: MAIN`); the range keeps it

For a rewrite, advancing SINCE to MAIN is the only way forward. For "could not be listed" (a transient or planted read failure), the stop lands `Main at: MAIN`, so the commits between the old SINCE and MAIN are never classified. Any `answers` commits among them are also never listed (row 727). The entry quotes only the refusal line, so the user's **[1] reviewed, build on it** approves a range they were not shown.

**Recommendation:** For a "could not be listed" refusal, the stop's block keeps the previous `Main at:` (SINCE), so the next iteration classifies the range once the listing works. Alternatively, the entry lists the first-parent range when it can be listed some other way.

## Accepted residuals (not refiled)

- **F19 / row 727.** The stop is only as strong as `--main-log`'s classes, which its header calls a catch for "an honest slip, not a commit made to look like one of the others". A same-uid main writer can release the stop with an `answers`-class commit (`ANSWERS_AWK` accepts an added answer line from anyone, and removed answer lines), or avoid it with a clean merge styled as a chore land that changes a record holding its `Branch:` line (`log_class`, `chore_record`). F2's forged-heading route, and `--check-answer` reading main's live commit rather than MAIN (a commit landing between step 0.2 and the lookup can change the answer read), are both dominated by this residual.
- **Q-140.** Step 0.1-0.2 and the stop's land (`--state`, `--cycle-diff`, `--land-cycle`) run the gate scripts committed on main, so an `other` commit that edits `scripts/build-loop.sh` runs as the gate before the stop is decided. The stop adds three calls, but no new exposure beyond step 0's two.

## Untested bypass candidates

- **Order of the step 0.2 lookup.** The text makes the slug lookup run in WT, which step 0.3 creates, and has the stranded commit merged into WT in 0.3. If an orchestrator evaluates "unless WT's files hold one" before that merge, duplicate entries follow (attention only). Not run.
- **A stop block written without `Branch:` or `Main at:`.** `--land-cycle` then refuses (`chore_record`), or SINCE stays put. Both fail closed into a repeated stop. Not run end to end. By reading, `--cycle-diff` and `chore_record` accept an append to an older record, because records are freely writable cycle files (`writable`/`isrecord`) and `chore_record` reads the whole changed file.
- **A 12-hex prefix grind (F2).** Not run (cost about 2^48 SHA-1).

## Endorsement Claims

- **Claim:** Answers to a stop entry read as follows under the lib's `FENCE_AWK`+`ANSWER_AWK`: `[2] not yet` and an appended `[1]` below it → `drop`; `[1]` above `[2]` → `keep`; `not yet, [1] tomorrow` → `unrecognized`; `1 - reviewed` → `keep`; `reviewed, build on it` → `unrecognized`; two headings with one ID in one file → `dup` (which `check_answer` turns into a skip, read as not `keep`).
  **Location:** `scripts/lib/dev-cycle-read.sh` `ANSWER_AWK`, `check_answer`
  **Evidence:** executed
  **Verified:** the probe below, over one-entry files marked ANSWERED
  **Not verified:** `check_answer`'s git-object path end to end (it reads `MAIN_SHA:file`)
- **Claim:** `--cycle-diff`'s rules put no append-only or date constraint on a cycle record, so the stop's append to an older day's record is within the cycle's writable files, and `chore_record` matches it when the appended block holds `Branch: B`.
  **Location:** `scripts/lib/dev-cycle-read.sh:246-249`; `scripts/build-loop.sh:1743-1752`
  **Evidence:** read-static
  **Verified:** `isrecord`/`writable` and `chore_record`'s loop over added/changed records
  **Not verified:** a `--land-cycle` run over such an append (the bats `--land-cycle` test adds a new file)
  **route: code-fact-check**
- **Claim:** The stop decision precedes step 0.4, so no digest, step 1-4b command, subagent, merge, answer or dispatch runs in a stopped iteration.
  **Location:** `skills/dev-cycle/SKILL.md:261-267`
  **Evidence:** read-static
  **Verified:** the step text and the step 0 order
  **Not verified:** an orchestrator transcript of a stopped iteration
  **route: code-fact-check**

Probe (executed): a script created with `mktemp -d` under the session scratchpad (`secc3.m8Tvk6`), with the lib's awk programs taken by sourcing the lib in a child shell. No git operations and no repo writes; the directory is left in place.

## Primitive sweep

Primitive: merge / approval sinks
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `SKILL.md:496` self-merge | S1 | stop; `--main-log MAIN` re-read | cleared (C3 closed); re-read-to-merge residual |
| `SKILL.md:555-559` approved merge | S2 | stop; `--check-answer`; re-read | cleared; C5(b) and C6 open (fail closed) |
| `SKILL.md:688-689` dispatch | S1 | stop; re-read | cleared |
| `SKILL.md:261-267` stop release | S2, S3 | `--check-answer` on both files | F2, F3; F19 residual |

Primitive: process exec (repo tests, gate scripts)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| step 1 health check, step 4 tests, steps 2/4b subagents | S1 | stop before step 0.4 | cleared (C7/E2 closed) |
| stop's land: `--state`, `--cycle-diff`, `--land-cycle` | main's committed scripts | D6 (pending) | Q-140 residual |

Primitive: untrusted text into questions files
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `SKILL.md:65-66` stop agent entries | script/git output | `> Output:`, single-pass removal | C4 open |
| `SKILL.md:705-706` step 10 agent entries | script output | unspecified | C8 open |
| `SKILL.md:260` `main-log-refused` "quoting the line" | refusal text | unspecified form | C8 (same root) |

Primitive: window / SINCE computation
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `SKILL.md:264-266` append to newest record | S4 | chore_record | cleared for the window file; F1 (in-session rewind); F4 (listing failure) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | In-session window check rewinds the digest to the stop's day, reopening the gap c8d90d62 closes (introduced) | Low | B5 | `SKILL.md:286-289` | Medium |
| F2 | Dedupe counts answered entries: an old `keep` covers a new same-slug occurrence (introduced) | Low | B3, B2 | `SKILL.md:258-261` | Medium |
| F3 | `[1]` appended below `[2] not yet` reads drop; in-session answers have no stated path to main: the stop never lifts (introduced; fails closed; executed) | Low | B2 | `SKILL.md:261`, `:264-267` | High / Medium |
| F4 | A listing-failure refusal advances `Main at:` past unclassified commits; [1] approves them unseen (pre-existing) | Low | B1, B5 | `SKILL.md:255-267` | Medium |
| C4 | One-pass opener removal / NUL (pre-existing now) | Low | B5 | `SKILL.md:65-66` | High |
| C5(b) | No `Applied:` action for an approved merge filed `stopped` (pre-existing) | Low | B6 | `SKILL.md:562-565` | Medium |
| C6 | Self-merge retries a failed read that the approved path files `stopped` (pre-existing) | Low | B6 | `SKILL.md:507-509` | Medium |
| C8 | Step 10 agent entries outside the quoting Rule (pre-existing) | Low | B5 | `SKILL.md:705-706` | Medium |

## Overall Assessment

The range closes the three Mediums of the second pass (C1, C2, C3) and both rubric items (E1, E2). It does so structurally: one stop before the digest leaves no step for a hold to miss, and the release lookup is named over both files that `--check-answer` reads. No Medium or higher was found, introduced or pre-existing.

The new findings are Lows:
- **F1** is the one that undercuts what c8d90d62 claims. The session's own window check can rewind the digest it preserves. It is a one-sentence fix in step 0.4.
- **F2** is approval reuse through the dedupe's widened wording.
- **F3** and **F4** are honest-path issues. F3 fails closed (livelock or attention). F4 has the user approve a range they were not shown.

The stop's security rests, as before, on the accepted F19 residual (classes catch honest slips, not forged commits) and on Q-140. No HALT pattern applies. Within the code paths read, there are no findings above Low; the read-static endorsement claims are pending execution verification.
