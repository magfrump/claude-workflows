Commit: ccc638d7

# Security Review — feat/build-loop-u4b2 (confirming pass, b88e418a..ccc638d7)

**Scope:** `git diff b88e418a..ccc638d7 -- skills` (`skills/dev-cycle/SKILL.md`, 90 changed lines), with the rest of `main...HEAD` as context. Read against `scripts/build-loop.sh` (header for --status, --marker, --main-log, --cycle-diff, --land-cycle, --merge; `check_line`, `log_class`, `chore_record`, `state_gate`), `scripts/lib/dev-cycle-read.sh` (`FENCE_AWK`), `scripts/health-check.sh` (check list), rubric D1-D10 and the six override rows dated 2026-10-13 that the range adds.
**Date:** 2026-10-13
**Based on:** predecessor `docs/reviews/security-review-2026-10-13-u4b2-final.md` (F1-F5 = rubric D1-D5). No code-fact-check report for this range was supplied: claims about script behaviour below were checked by reading the script, or by execution where marked.
**Mode:** design review of instructions an orchestrator model executes. Threat: a same-uid build loop (writes its branch, working trees, refs, `.git` state), or crafted marker, brief, questions or report text, steering the orchestrator into landing, answering or running something the user never approved; plus honest-path failures that fail open. Prose only; no attack recipes.

> ⚠️ **No code fact-check report provided for this range.** Claims about security properties in comments and documentation have not been independently verified beyond the reads and probes named here.

## Trust Boundary Map

```
B1: [main's first-parent commits (any same-uid writer, or a hand edit)]  → [--main-log class; other-commit-SHA12 entry hold] → [step 7 answers/self-merge, step 10 dispatch, step 1 health check]  (moved: hold now entry-keyed)
B2: [questions answers on main]                                          → [--check-answer, then --main-log MAIN re-read]      → [--merge --approved, drop, redispatch; hold release]  (moved: re-read now after)
B3: [repo-local .git state: common config, MAIN_WT's config.worktree]    → [--state from MAIN_WT]                              → [hg -C MAIN_WT worktree add GT (checkout runs filters)]  (moved)
B4: [a stranded chore/dev-cycle-* branch ref (unattended between iterations)] → [hg merge into WT at step 0.3; --cycle-diff; --land-cycle] → [main, as a chore merge]  (new)
B5: [brief lines Applied:/Dispatched:/Asked: on main]                    → [orchestrator reads (Applied: unjudged by any script); --status reads Dispatched:] → [step 10 redispatch, the D1 cap]  (new: Applied ACTION)
B6: [previous record's "1." line; --main-log chore class]                → [step 1 chained skip]                               → [health check (incl. questions grammar gate) skipped]  (new)
B7: [script refusal lines and stderr]                                    → [Rules: "> " quoting, comment opener replaced]       → [agent entries in questions files]  (moved)
```

Input-source classification:

```
S1: main's first-parent commits after MAIN, and their content (settings, briefs, questions) — runtime-mutable (same-uid writer) — UNTRUSTED for merge/dispatch/exec sinks until the user has reviewed them
S2: answers on main to other-commit / merge entries                                     — runtime-mutable — UNTRUSTED as approval unless its commit is classified (answers class trusted by row 727/F19 Won't-Fix)
S3: MAIN_WT's config.worktree, common config                                             — runtime-mutable (loop-writable) — UNTRUSTED for exec sinks (filters run by checkout)
S4: refs/heads/chore/dev-cycle-* tip between iterations                                  — runtime-mutable (loop-writable ref) — UNTRUSTED for the land sink (as content) and for the "my own commit" assumption
S5: Applied:/Dispatched: lines of a brief on main                                         — runtime-mutable (any chore land, forged chore) — UNTRUSTED for redispatch and cap sinks; no script judges Applied:
S6: record "1." line and --main-log's chore class                                         — runtime-mutable; chore is message+shape-based (F19: "catches an honest slip, not a forged commit") — trusted only for availability decisions
S7: script refusal text, git stderr                                                       — request-time — UNTRUSTED for text sinks in questions files
S8: SKILL.md GATE_CODE copy, D1 cap text                                                   — code-constant — trusted
```

The range moves the right guards: `--state` now reads the worktree `worktree add` copies from, the answer re-read follows `--check-answer`, and the `other` block is keyed on an open entry. The residual gaps are in the hold's coverage (it does not reach step 7's self-merge or step 1) and its release rule (any reading other than `open` ends it), plus one new land input: a stranded branch merged by name.

## Fix verification (rubric D1-D5)

| Row | Predecessor | Verdict | Basis |
|---|---|---|---|
| D1 | F1 `other` block window-scoped | **Partly fixed.** Answers and dispatch now held while an `other-commit-SHA12` entry is open (`SKILL.md:256-260`), and step 0.2's own `other` lines now hold answers (`:538`). Not covered: step 7's self-merge (N1), step 1's health check and step 4's tests in later iterations (N3); the release rule fails open (N2). | read-static |
| D2 | F2 GT `--state` from WT | **Fixed in step 7** (`:490`). Executed: `sec/probe-d2.sh` — with a smudge planted in MAIN_WT's `config.worktree`, `--state` from MAIN_WT refuses `filter.x.smudge: set in config.worktree`, from WT prints `ok`. The Rules still say `--state` runs from WT (N5). | executed |
| D3 | F3 re-read before `--check-answer` | **Fixed for answers** (`:537-539`: "Then run `--main-log MAIN` again"). Dispatch half deferred with a row; deferral stands (the D1 hold catches the commit next iteration). | read-static |
| D4 | F4 `--answered` text-only | **Deferred with a row**; deferral stands (D11, no script change in range). | read-static |
| D5 | F5 unquoted pasted lines | **Partly fixed.** The comment opener is handled; a quoted line whose content starts like a link label is still refused by `FENCE_AWK` (executed), and step 10's non-stop `agent` entries are outside the Rule's sentence (N8). Fails closed. | executed |

## Findings

#### N1. The `other`-commit hold does not reach step 7's self-merge: an unreviewed commit can turn on self-merge for a brief, and step 7 lands the loop's branch with no human

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:254-260` (step 0.2 hold), `:489-501` (step 7, ready/self-merge); `scripts/build-loop.sh:72-74` (--status POLICY)
**Boundary:** B1
**Move:** 5 (invert the access model), 3
**Confidence:** Medium
**Legibility-target:** for-author
**Label:** pre-existing gap; the range's D1 sentence now claims it closed

Evidence:
> step 0.2: "blocks this iteration's dispatch and every answer step 7 would act on ... The block holds in every later iteration while such an entry is open (`--check-answer` prints `open`), so a commit the user has not seen never feeds a merge or a loop."
> step 7: "**ready**, POLICY `self-merge`: `--merge BRIEF --expect TIP`, run from a gate checkout" [unit continues: GT setup, merged line, path refusals fall through, environment refusals retried]
> --status header: "POLICY: self-merge only when --settings' policy is self-merge and the brief's first "Policy:" line is exactly "Policy: self-merge""

Weakness: the hold names dispatch and answers. Step 7's self-merge is neither, so it runs in the same iteration that first lists an `other` commit, and in every later one while the entry is open. Both inputs to POLICY (`docs/dev-cycle.md`'s policy line and the brief's `Policy:`/`Paths:` lines) are read from main's commit, which an `other` commit can change. Preconditions: a commit on main outside the design (same-uid writer) that edits the settings and a brief whose loop is at `ready`. Impact: a loop's branch lands under a `Build-loop-gate:` self-merge trailer the user never authorised, before the user sees the judgment entry. The self-merge floor still refuses truth files, dot paths, gate code and never-globs; everything else the brief's new `Paths:` names lands. The sentence's own claim ("never feeds a merge") is false for this path.

**Recommendation:** Extend the hold to step 7's `--merge` without `--approved`: while held, record a `ready` self-merge brief and retry it next iteration, as the environment refusals already are. Keep "never feeds a merge" only once that is true.

#### N2. The hold's release rule fails open: any reading other than `open` ends it, including the user saying "do not trust it" and a `skip`; `refuse main-log` entries have no slug to find them by

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:256-260`
**Boundary:** B1, B2
**Move:** 3 (error path), 5
**Confidence:** Medium
**Legibility-target:** for-author
**Label:** introduced-by-range

Evidence:
> "gets one `you: judgment` entry naming its SHA (slug `other-commit-SHA12`) or quoting the line, unless an open one does (rows 720, 726). The block holds in every later iteration while such an entry is open (`--check-answer` prints `open`)"

Weakness: three gaps, one root. (a) The entry has no defined options, and the hold lasts only while the answer reads `open`. An answer such as "[2] revert it, do not build on it" ends the hold just like "[1] fine", so answers and dispatch resume over the commit the user has just rejected. (b) `--check-answer` also prints `skip` (an ID it cannot read, or a questions file refused whole), and `skip` is not `open`, so the literal rule lifts the hold. In the whole-file case `--cycle-diff` then refuses the land, which stops dispatch (the land must be verified first), but answers are not held by that stop. (c) Only the `other` case gets a slug. A `refuse main-log:` entry (main rewritten, SINCE off its history) is "quoting the line", so a later session cannot find it by heading. That is the case where everything after the rewrite is unclassified, and after the record lands, the next SINCE is on history again and nothing re-lists it. Within one session the orchestrator may remember the ID. Across sessions the hold for that case is lost. Also note the accepted residual: an `answers`-class commit can answer the entry (row 727, F19), so a same-uid writer can lift the hold without the user. That residual is not new; (a)-(c) are.

**Recommendation:** Give the entry fixed options, e.g. **[1] reviewed, build on it** and **[2] keep holding** (revert by hand), and lift the hold only on `keep`; any other reading (open, skip, drop, unrecognized) holds. Give `refuse main-log` entries a slug too (e.g. `main-log-refused-MAIN12`). Say where the hold check runs: one `--check-answer` call on every `other-commit-`/`main-log-refused-` heading in WT's questions files, before step 1.

#### N3. Step 1's health check (and step 4's tests) resume the iteration after an `other` commit, while its entry is still open

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:297-302` (step 1)
**Boundary:** B1, B6
**Move:** 3, 4
**Confidence:** Medium
**Legibility-target:** for-author
**Label:** pre-existing (the remainder of predecessor F1(b); rubric D1 says only dispatch and answers)

Evidence:
> "skipped when step 0.2 read an `other` line, whose unreviewed test code it would run (row 776; step 4 then runs no repo test either), or when the previous iteration's `1.` line reads `passed at P` or `unchanged since P` and step 0.2 listed only `chore` lines"

Weakness: the skip is keyed on step 0.2's window, the hold on the open entry. In the next iteration the `other` commit is before SINCE, so step 0.2 does not list it, and the previous `1.` line reads "skipped", which breaks the chain. The health check therefore runs the commit's test code from WT, as do step 4's tests, while the user has not yet reviewed it. Preconditions: as N1. Impact: the orchestrator runs code row 776 decided it should not run, in its own environment. The privilege gain is limited by the shared uid.

**Recommendation:** Skip the health check and step 4's test runs while the N2 hold holds, with the record's `1.` line saying so (and the chain then broken, so the first run after release is a full one).

#### N4. A stranded chore branch is merged into WT by name, so whatever its ref points to after a 20-30 minute wait lands as a chore merge under the orchestrator's identity

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:263-266` (step 0.3)
**Boundary:** B4, B5
**Move:** 4 (TOCTOU), 2
**Confidence:** Low
**Legibility-target:** for-author
**Label:** introduced-by-range (D9)

Evidence:
> "When this session's previous iteration stopped after committing (its branch not in main), merge that branch into WT first (as step 9 merges main in), so its entries and `Asked:` items land now and are not filed again (D13: a failed land is retried); a conflict is a stop."
> --cycle-diff header (`build-loop.sh:225-236`): "A brief's first unfenced "Asked:" line ... must be as on BASE, or BASE's line followed by ", " and more" (no rule names `Applied:` or `Dispatched:`)

Weakness: before the range, a stranded branch was never read again, so its ref was not an input. Now its ref, left unattended between iterations, is merged by name, not as the commit the session made. `--cycle-diff` and `--land-cycle` still judge the result, but by the cycle rules: new unanswered questions entries are free, and `Applied:` and `Dispatched:` lines are judged by nothing. Preconditions: a same-uid writer moves the stranded ref. Impact, within the cycle rules: a lowered `Dispatched:` count lands and `--status` reads it, so the D1 cap is evaded. An `Applied: Q-NNN=...` item hides a pending answer or asks for a re-dispatch. A merge entry's body can misdescribe `--check`'s lines while keeping the heading `--approved` binds, so the user approves on loop-written evidence. All of it lands as `chore`, the class the step 1 chain and the hold trust. Parity note: F19 already accepts that a writer who can move refs can forge a chore merge on main directly. This route is harder to spot, because it carries the orchestrator's own identity and passed `--cycle-diff`.

**Recommendation:** Merge the commit the session recorded when it stopped (session memory, not the ref), and only when the ref still points to it. On a mismatch, merge nothing and file one `you: judgment` entry naming both SHAs.

#### N5. The Rules still place every `--state` in WT; following them recreates the executed F2 bypass

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:47-49` (D6 Rule), `:83-85` (Hardened git), versus `:490`
**Boundary:** B3
**Move:** 11 (bypass of a guard via an alternate path)
**Confidence:** Low (the step's own text is explicit and says why)
**Legibility-target:** for-author
**Label:** introduced-by-range (new contradiction)

Evidence:
> Rules: "Every `build-loop.sh` and `dev-cycle.sh` call runs from WT (step 0's first two from MAIN_WT, step 7's self-merge from its GT)"
> Rules: "`--state` refuses those, but only when it runs, so run it again (through the D6 block, from WT) right before the iteration's commits"
> step 7: "`--state` (from MAIN_WT, whose config the add copies)"

Weakness: the predecessor's fix note asked that "the Rules' D6 sentence then names it". It does not, so the general Rule and step 7 disagree on where this one call runs. Executed (`sec/probe-d2.sh`): from WT the planted `config.worktree` smudge passes `--state` (`ok`) and runs during the GT add. Impact: if the Rule wins, D2 is undone.

**Recommendation:** Add "step 7's gate `--state` from MAIN_WT" to the D6 Rule's list of exceptions.

#### N6. The chained health-check skip assumes "cycle lands carry no code", but the health check gates what chore lands change (the questions doc's grammar)

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:300-302`, `:609`; `scripts/health-check.sh:53`
**Boundary:** B6
**Move:** 3 (fail-open on the honest path)
**Confidence:** High (read-static)
**Legibility-target:** for-author
**Label:** introduced-by-range (D6)

Evidence:
> "or when the previous iteration's `1.` line reads `passed at P` or `unchanged since P` and step 0.2 listed only `chore` lines (cycle lands carry no code; this iteration's line then reads `unchanged since P`)"
> health-check.sh: "#  14. Running-questions doc: entry grammar, unique ids, index freshness (gate)"

Weakness: every chore land changes `docs/working/questions.md`, the roadmap, briefs, records and in-cycle `.md` fixes. Check 14 is a gate over exactly that. Under the chain, a malformed entry or a stale index from the orchestrator's own land is never checked while only chore lines land, and the record says "unchanged since P". Separately, `chore` is a class read from message and shape (F19), so a forged chore commit carrying code also extends the chain. Skipping is the safe side for execution, so the impact is a missed gate failure, not an exec. It is honest-path and fails open.

**Recommendation:** Narrow the chain to "no chore land changed a path the health check reads" (simplest: let the chain skip only when the window holds no commit at all), or run the questions check (`questions.sh check`) on every iteration, outside the health check.

#### N7. Loop-caused refusals of an approved merge are classed as the environment's and retried indefinitely, unlisted, and planted-object refusals are never filed

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:547-551` (merge entry `keep`), `:499-501` (self-merge); `scripts/build-loop.sh:1361-1388`, `:300-317`
**Boundary:** B2, B3
**Move:** 3
**Confidence:** Medium
**Legibility-target:** for-user
**Label:** introduced-by-range (D8)

Evidence:
> "A refusal of the paths, or a conflict, is filed as `stopped`; any other (MAIN_WT's state, no identity, a moved main) is retried next iteration, the ID left off `Applied:`."
> check_line: "refuse $a: the tip of $br is $sha, not the expected $EXPECT"; "the brief is $st on the default branch; only an open brief merges"; "its branch $br has no commit the default branch lacks"; "an object of the tip of $br or of the merge does not hash to its id"

Weakness: "any other" also covers refusals that no later iteration cures: the loop moved its branch off the approved TIP, the brief is done, or the branch is already merged (for example after a lost `Applied:` line). It also covers a re-hash failure, which is planted object state that step 0.1 would file as a `you: judgment` stop. Each is retried every iteration with the approval held open. For the approved path, nothing puts it in the final message's lists ("each answer still open, skipped or unrecognized"). Impact: no unapproved landing (fails closed), but the user believes an approved merge landed, and a tamper signal goes unfiled.

**Recommendation:** Treat only the named environment refusals (`refuse state`, no identity, a moved main) as retryable. File the rest as `stopped`, and file a re-hash refusal as step 0.1 files planted state. List every retried approval in the final message.

#### N8. Quoting pasted lines handles only the comment opener; a line that starts like a link label still makes the questions file unreadable, and step 10's `agent` entries are outside the Rule

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:63-64` (Rules), `:695-697` (step 10)
**Boundary:** B7
**Move:** 2, 11
**Confidence:** High (executed)
**Legibility-target:** for-author
**Label:** pre-existing (predecessor F5), fix incomplete

Evidence:
> Rules: "else the line and stderr go in one `agent` entry, each line quoted as `> ` text with any HTML comment opener replaced"
> step 10: "Any other refusal or skip: recorded, and one `agent` entry per brief unless an open one names it."
> FENCE_AWK `refdef`: "also behind any number of blockquote and list markers"

Weakness: `sec/probe-quote.sh` ran the lib's `FENCE_AWK` over quoted lines. `> <div>`, `` > ``` ``, `> fatal: ...` and `> [1]    12345 killed ...` read as text. `> [x]: y` is refused (`refdef`), and so, by the same function, is a quoted line with an unclosed `[`. The Rule's sentence sits in the stop paragraph, so step 10's non-stop entries are not plainly under it. Impact: availability only. `--check-answer` then refuses the whole file and `--cycle-diff` refuses the land.

**Recommendation:** State the form once for every pasted line in any entry: `> ` prefix, `<!--` replaced, and a `[` at the start of the content escaped as `\[`.

## Deferred items re-checked

- D3's dispatch half (row: `--start`/`--prompt` read main live): the deferral stands. The next iteration's step 0.2 lists the commit and its entry holds dispatch, subject to N2.
- D4 (row: `--answered` for merge entries text-only): the deferral stands; the range adds no script check and no new path to it.
- Row 727 / F19 (an `answers`-class commit is trusted as the user's): now also releases the N2 hold. Accepted residual, noted under N2, not refiled.

## Untested bypass candidates

- N4: whether `--status` or any reader takes the *first* `Dispatched:` line while the orchestrator replaces "the old line" (a second line planted above). Not run; `build-loop.sh:902` reads "its first Dispatched: line".
- D2: a pre-created `.git/worktrees/<GT name>/` admin directory (the name is predictable). Not run; git normally refuses an existing admin dir.
- D2: TOCTOU between step 7's `--state` and `worktree add` (a planted key written in between). Not run; a window of one tool call, the same residual the Rules name for commits.
- N2: whether `--check-answer` prints `open` or `skip` for an ID whose entry was moved to the archive by `questions.sh archive`. Not run.

## Endorsement Claims

- **Claim:** Step 7's gate `--state`, run from MAIN_WT as the range now says, refuses a filter planted in MAIN_WT's `config.worktree` that the same call from WT passes.
  **Location:** `skills/dev-cycle/SKILL.md:490`; `scripts/build-loop.sh:613-620`
  **Evidence:** executed
  **Verified:** `sec/probe-d2.sh` (temp repo, the skill's `hg` verbatim): from WT `ok`, from MAIN_WT `refuse state filter.x.smudge: set in config.worktree ...` (exit 2)
  **Not verified:** a key planted between that `--state` and the add; `include.path` inside `config.worktree`
  **route: code-fact-check**
- **Claim:** The answer path now classifies main after reading the answers: `--check-answer` runs first, then `--main-log MAIN` again, and an `other` line or step 0.2's hold means no answer is acted on.
  **Location:** `skills/dev-cycle/SKILL.md:531-539`
  **Evidence:** read-static
  **Verified:** the order of the two sentences in the unit and the "act on no answer" consequence
  **Not verified:** a commit landing between that re-read and `--merge --approved` (its own `approval()` re-read; `check_line` path into `VERDICT[tip]` not read)
  **route: code-fact-check**
- **Claim:** Under the Rules' `> ` form, quoted lines whose content starts `<`, a backtick fence, `fatal:` or `[1]` followed by text without `]:` are read as text by `FENCE_AWK`.
  **Location:** `skills/dev-cycle/SKILL.md:63-64`; `scripts/lib/dev-cycle-read.sh:273-315`
  **Evidence:** executed
  **Verified:** `sec/probe-quote.sh` over six lines (one refused, N8)
  **Not verified:** `ANSWER_AWK` and `questions.sh check` over the same lines

## Primitive sweep

Primitive: process exec through git checkout/merge machinery (filters, merge drivers)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `SKILL.md:261` step 0.3 `worktree add -b ... WT MAIN` | S3 | `--state` from MAIN_WT at 0.1 | cleared (unchanged) |
| `SKILL.md:263-266` step 0.3 merge of stranded branch into WT | S3, S4 | "as step 9 merges main in" (`--state` from WT first) | exec cleared; content: N4 |
| `SKILL.md:490-492` step 7 GT `worktree add --detach` | S3 | `--state` from MAIN_WT | cleared (executed); Rules contradiction N5 |
| `SKILL.md:673-675` merge of main into WT | S3 | `--state` from WT | cleared (unchanged) |
| `SKILL.md:643-646` chore commit | S3 | `--state` at 9.2, hooks off | cleared (unchanged) |
| `SKILL.md:297-302` health check; step 4 tests | S1, S6 | skip on step 0.2 `other` only; chain on chore | N3, N6 |

Primitive: approval / merge sink (`--merge`, `--merge --approved`)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `SKILL.md:489` step 7 self-merge | S1 (settings, brief Policy/Paths on main) | none from the hold | N1 |
| `SKILL.md:547` merge entry `keep` | S2 | `--check-answer` then `--main-log` re-read; hold | cleared for order (endorsement 2); release rule N2; retry classes N7 |
| `SKILL.md:648-651` `--answered` | S2 | skill text | D4 deferred (stands) |

Primitive: redispatch / cap sink
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `SKILL.md:476-481` `Applied: Q-NNN=redispatch` | S5 | none (no script reads Applied:) | N4 (reachable through the stranded merge or a forged chore) |
| `SKILL.md:698` DISPATCHED cap | S5 | `--status` reads the brief's line | N4 |

Primitive: untrusted text into questions files
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `SKILL.md:63-64` stop entries | S7 | `> `, comment opener replaced | N8 (fails closed) |
| `SKILL.md:695-697` step 10 agent entries | S7 | unspecified | N8 |
| `SKILL.md:524-526` `> Reason:` | loop REASON | unchanged | cleared (predecessor, executed) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| N1 | Hold does not cover step 7's self-merge; an `other` commit can enable self-merge and the loop lands (pre-existing; range claims closed) | Medium | B1 | `SKILL.md:254-260`, `:489-501` | Medium |
| N2 | Hold lifts on any non-`open` reading (incl. "don't trust it", `skip`); `refuse main-log` entries unslugged (introduced) | Medium | B1, B2 | `SKILL.md:256-260` | Medium |
| N3 | Health check and step 4 tests resume next iteration while the `other` entry is open (pre-existing, F1(b) remainder) | Medium | B1, B6 | `SKILL.md:297-302` | Medium |
| N4 | Stranded chore branch merged by name; loop-moved ref lands Applied:/Dispatched:/entry text as chore (introduced) | Medium | B4, B5 | `SKILL.md:263-266` | Low |
| N5 | Rules still put `--state` in WT; following them recreates F2 (introduced contradiction) | Medium | B3 | `SKILL.md:47-49`, `:83-85` vs `:490` | Low |
| N6 | Chained health-check skip misses the questions-grammar gate that chore lands change (introduced) | Low | B6 | `SKILL.md:300-302` | High |
| N7 | Loop-caused / tamper refusals of an approved merge retried forever, unlisted, unfiled (introduced) | Low | B2, B3 | `SKILL.md:547-551` | Medium |
| N8 | Quoting fixes only `<!--`; `> [x]: y` still refused; step 10 entries outside the Rule (pre-existing, incomplete fix) | Low | B7 | `SKILL.md:63-64`, `:695-697` | High |

## Overall Assessment

D2 is fixed in its step and executed clean. D3's answer half is correctly ordered. D4 and D3's dispatch half are deferred with rows that still hold. D1 is the incomplete one. The hold is now keyed on the open entry, as recommended, but it does not reach step 7's self-merge (N1) or step 1's test runs (N3), and it lifts on any reading other than `open` (N2). An unreviewed commit can therefore still change policy and get a loop's branch self-merged before the user sees its entry. The answer "keep holding" also does not hold. The range adds one new land input, the stranded branch merged by name (N4), and one Rules/step contradiction that would undo D2 if read the wrong way (N5). Every issue can be fixed in place in SKILL.md, with no script change needed. The single most important fix is N1+N2 together: hold every merge (self-merge included), every dispatch and every repo test while an `other-commit`/`main-log-refused` entry reads anything but `keep`. No HALT pattern applies. Within the code paths read there are no further findings, and the read-static endorsement claims are pending execution verification.

## Goal-Alignment Note
- Success criterion (restated verbatim): A security review saved at the given path, structured per the security-reviewer skill
- Answered: yes. The range b88e418a..ccc638d7 of `skills/dev-cycle/SKILL.md` was reviewed with the branch as context. D1-D5 were verified (D2 executed). 8 findings: 5 Medium, 3 Low, each labelled introduced-by-range or pre-existing. 2 probes were executed (`sec/probe-d2.sh`, `sec/probe-quote.sh`; temp dirs `/tmp/u4b2rv-secc-*`, left in place).
- Out of scope: the D6 block (Q-140); script implementations beyond the functions cited; performance and API concerns (N7's retry cost is noted only for its legibility effect).
- Escalate: N1 (an unapproved self-merge reachable from an unreviewed commit, contradicting the D1 sentence and plan D13), and N2(a) (the user's "keep holding" answer releases the hold).
- Decisions I made: treated a same-uid writer moving refs and committing on main as in scope, per the brief. Rated N4 and N5 Medium under the floor rule (named mechanisms), with Low confidence (N4 sits beside F19's accepted forged-chore residual; N5 depends on the Rule overriding the step). Labelled N1 pre-existing because self-merge in step 7 predates the range, but called out that the range's sentence claims the property.
