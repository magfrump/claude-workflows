Commit: 299727c

# Tech Debt Triage, iteration 6 of 6 (terminal pass): branch `skill-fixtures` (Q-062 [2], Q-063 [1])

**Scope:** the whole branch, `git diff main...HEAD` at 299727c (149 files, +24,774/−305), focused on b22a026 ("transcript census"). This pass answers three questions:
- **(a)** What net debt does the branch carry into `main` after this final pass?
- **(b)** What changed for earlier items, especially C39 (posture) and C38 (golden transcripts)? Fact-check found 16 committed real transcripts from CLI 2.1.232. Should the tests use them as golden cases?
- **(c)** What should the local merge commit record?

Settled rows are not re-judged: C3, C4, C6, C8, C13, C14, C15, C24, C30, C34, C35, C37, C38 and C39 (open by choice or Deferred), and the accepted residual in the DD doc. For C38 and C39 this pass reports a **status change and new evidence** only. It does not reopen the decision.

**Inputs:**
- the stage-1 report, `docs/reviews/code-fact-check-report.md` (299727c, 38 claims). Branch test and probe outcomes come from it and are cited by claim id;
- the iteration-5 triage, `docs/reviews/tech-debt-triage-review-2026-09-25-q062-q063-iter5.md` (9c73ae4);
- the rubric `docs/reviews/code-review-rubric-2026-09-25-skill-fixtures-q062-q063.md`, rows R3, R4, A27–A29 and C30–C39.

**What this pass ran itself** (hermetic, all in the scratchpad or read-only; no `claude`, no network):
1. `git diff --numstat` / `git show --numstat` for sizes and churn.
2. A profile of the 16 committed transcripts under `runs/review-arms/e7-fable-3x/`: event types, content-block types, tool names, init events, sub-agent events. It also timed `transcript_failures` over all 16.
3. A candidate fix for Claims 24 and 25b, a 6-line change applied to a `git archive HEAD` copy of `test/` in the scratchpad. Results:
   - both refuting probes fail under the fix, and so do three more fact-check probes;
   - the 16 real transcripts still pass;
   - four suites pass on that copy: generate-reports.bats, mode1-equiv.bats, eval-helpers-transcript.bats and arithmetic-eval-eval.bats.

   The working tree was not touched.

**Mode:** advisory. Not committed.

---

## Status of earlier items

| Item | Iter-5 rec. | What b22a026 did | Status at merge |
|---|---|---|---|
| iter-5 A: contract absolutes at ~8 sites | Fix now | b22a026 rewrote them around the census, and the census makes most of them true. | **Recurs (7th time for this class).** The census absolute is refuted by a `__text`-keyed event (Claim 24). "Anything else is a problem" is refuted by substring allowlists (Claim 25b). Log #56's voiding list is stale again (Claim 1). The rubric's A29 "Fixed" marker is Incorrect (Claim 6). See Items A and B. |
| iter-5 B / C39: posture (~7× budget; freeze) | Carry intentionally | The user chose [1], fix by construction. test/ churn was +378/−183. | Open by choice (settled). **New evidence:** the by-construction route converged much further than iteration 5 predicted. Escapes went from 20/22 positions to 1 marker-key shape; the other refuted shape (substring types) hides no call. See Item D. |
| iter-5 C: tool_use outside assistant content never counted | Defer and monitor (to A8) | Census via `..` (R3). | **Retired**, except the marker-key case (Item A). The risk iteration 5 could not judge, whether real transcripts nest `tool_use` objects legitimately, is now answered for CLI 2.1.232. All 16 real transcripts, with 3,006 sub-agent assistant events among them, have census = placed (fact-check Claim 28 scope; confirmed below). |
| iter-5 D: verdict split drops counts | Fix opportunistically | Verdict decided in jq, with a sentinel (R4). | **Retired** (Claim 3, Verified). |
| iter-5 E: mode1-equiv trusts the evaluator | Fix opportunistically | `6 * 7` self-test (A27). | **Retired** (Claim 4, Verified). The DD summary still drops the docstring's limit (Claim 9); folded into Item B. |
| iter-5 F / C36: lenient side readers | Carry intentionally | Report, result state and `assert_subagents_min` go through the strict reader. | **Mostly retired** (Claim 7). An init-only transcript still passes the eval-level check, and a string `tools` still turns off the misspelling guard. See Item E. |
| C38: no real transcript in repo | Open | None. | Open by choice (settled). **New evidence:** 16 real transcripts *were* already in the repo, on `main` since E7 (2934c51). They can anchor the generic reader now. They cannot anchor deny-record. See Item C. |
| C34: hand-typed tallies | Open | The tallies were pasted from TAP output. | All re-run exactly (Claim 32). This is the second clean pass; the guard is working as practice. |
| C30: `docs/reviews/` volume | Deferred | +2 artifact commits. | 122 files and 22,477 of the 24,774 branch lines added (90.7%, up from 87.9%). Settled, so no item. |

---

## Item A: The census skips any event with a `__text` key, and the type allowlists match substrings (Claims 24, 25b)

**Severity/priority:** P1 (before the local merge; a trivial fix)
**Location:** `test/skills/transcript.jq:45-46` (events), `:56-57` (census), `:70` (`_event_problems`), `:72` and `:81-82` (allowlists)
**Nature:** a correctness gap in a detector (the reader's own marker key is reachable from input), plus a jq-semantics bug (`inside/1` is a substring test on strings)
**Cost of Deferral:** `+0 — inert` for the code. It compounds only through the stated contract: `+1 Incorrect claim per review pass that reads transcript.jq`, and this is the 7th pass in a row for the class.
**Failure Cost:** `Low × Low`. Claim 24's shape passes the generator, `no_tool_called` and `mode1_equiv` end to end with an undenied call. But real `claude -p` lines never carry `__text`, so reaching it takes a CLI shape change or a hand-written transcript. Claim 25b hides no call; it weakens the "a CLI change voids loudly" fail-safe.
**Confidence:** High. Both defects are executed in the fact-check. The fix's effect was executed in this pass.
**Legibility-target:** for-author

**Evidence (verbatim):**
```jq
# test/skills/transcript.jq:45-46
def events: [inputs | select(test("\\S")) | . as $line | (try fromjson catch
  (if ($line | test("[\\[{]")) then {"__unparsed": $line} else {"__text": $line} end))];
```
```jq
# test/skills/transcript.jq:56-57
def tool_uses: [.[] | objects | select(has("__text") | not) | .. | objects | select(.type == "tool_use")];
def tool_results: [.[] | objects | select(has("__text") | not) | .. | objects | select(.type == "tool_result")];
```
```jq
# test/skills/transcript.jq:72
  elif ([.type] | inside(["system", "assistant", "user", "result", "rate_limit_event"]) | not) then
```
```jq
# test/skills/transcript.jq:7-8, 12 (header)
# in a place nobody looked passed every check. Here the list of calls is a
# CENSUS: every object whose "type" is "tool_use", at any depth of any event,
# Wherever a call sits, it is found; if it sits anywhere but an assistant
```

### Carrying Cost: Low
Nothing real reaches either gap. The cost is that the module's headline invariant ships false into `main`. The insertion property test also cannot find this class: it varies containers, not key names (Claim 23).

### Fix Cost
- **Scope:** one file, 6 changed lines.
  - A text line emits `empty` instead of `{"__text": …}`. The three `has("__text")` filters then go, so the reader has no marker key that input can collide with. `__unparsed` stays: an input object with that key is reported as a problem, which fails closed.
  - `[.type] | inside([...])` becomes `.type | IN(...)`, in all three places. `IN` exists in jq 1.6, and this pass checked it: `"sys" | IN("system","assistant")` gives `false`.
- **Verified in this pass** on a `git archive HEAD` copy:
  - the `__text` call-and-result probe, `"type":"sys"`, `"type":""`, the `"tool"` block and the user `"result"` block each gave `__VERDICT_COMPLETE__` alone at HEAD. Under the fix each fails, with "an event has no string type" plus both placement mismatches, "an event of unknown type sys", "an event of unknown type " (empty), "unknown content block type tool", and "unknown content block type result";
  - a plain-text line is still ignored;
  - all 16 committed real transcripts still give an empty, complete verdict;
  - generate-reports.bats 46/46, mode1-equiv.bats 31/31, eval-helpers-transcript.bats 7/7 and arithmetic-eval-eval.bats 9/9 (9 skip) pass.
- **Tests to add:** two rows in `MALFORMED_SHAPES` (`text_marker_key` and `substring_type`). The table then runs them in both suites.
- **Effort:** under 30 minutes.
- **Risk:** low. The real-transcript control is Item C.
- **Incremental?** Yes.

### Urgency Triggers
- The local merge. After it, the header becomes `main`'s description of the harness.

### Recommendation

**Recommendation:** Fix now

Both are one-line closures of the kind C39's proposed working rule allows. The fix makes the stated contract true, which is cheaper than narrowing it in six places. It is a trivial single-file fix, so make it in place with no RPI. It lands after the last authorized review pass, so record in the commit body that it is probe- and suite-verified but not re-reviewed.

---

## Item B: Contract prose residue, the seventh recurrence (Claims 1, 6, 9, 12, 25a, 26, 31a)

**Severity/priority:** P1 (same commit as Item A)
**Location:**
- `docs/decisions/log.md:77` (#56 voiding list);
- `docs/working/dd-arith-eval-bash-grant.md:175` (BOM example, "allowlisted"), `:176` ("the init event"), `:183` (exit contract);
- `test/skills/transcript.jq:23-25`, `:40-44` and `:132`;
- `test/skills/generate-reports.bash:37-39`;
- rubric row A29's status cell (`:54`).

**Nature:** documentation / contract accuracy
**Cost of Deferral:** `+1 Incorrect or Stale fact-check claim per pass that reads these files`. Log #56's list is the second recurrence (iteration-5 Claim 1, then this pass's Claim 1).
**Failure Cost:** (blank; nothing here is behavioral)
**Confidence:** High. Every site is a fact-check verdict.
**Legibility-target:** for-author

**Evidence (verbatim):**
```
# docs/decisions/log.md:77 (#56), as quoted by fact-check Claim 1
it voids a run when a Bash call is missing from `permission_denials` (tripwire), when a denial names a call the parser did not see (parser canary), or when the init event is missing or does not list Bash
```
```python
# test/skills/arithmetic-eval/mode1-equiv.py:38-40 (the limit the DD summary drops)
unexpected error in this script. So exit 1 means "the model's commands did not
compute the value", unless the evaluator misbehaves only on some inputs, which
the self-test cannot see.
```
```jq
# test/skills/transcript.jq:132
#   - the init event must list exactly ["Bash"], the only tool granted;
```

### Carrying Cost: Low
Each fix is one phrase: the voiding list replaced by a pointer to `deny_record_failures`, the exit-contract limit added, BOM dropped as an example, "the first init event", and "a bracket-free line that is not itself JSON". Fact-check supplies a precise version for each site. After Item A, the census and allowlist sentences are true as written and need no edit.

### Fix Cost
- **Effort:** under 30 minutes, prose only.
- **Risk:** none.
- Set rubric A29 to "Fixed (census and allowlist absolutes true after the iteration-6 fix; log #56 list replaced by a pointer)". Do not leave the Incorrect marker standing.

### Urgency Triggers
- The local merge.

### Recommendation

**Recommendation:** Fix now

The durable fix for log #56 is structural. Stop enumerating conditions in a decision-log row, and point at the module. An enumerated list there has gone stale twice, and the module is already the authority (Claim 12).

---

## Item C: The 16 committed real transcripts can serve as golden cases for the generic reader, but not for deny-record (C38, new evidence)

**Severity/priority:** P2
**Location:**
- `runs/review-arms/e7-fable-3x/*/rep{2,3}/transcript.jsonl` (16 files, 18 MB, on `main` since 2934c51);
- `test/skills/transcript.jq:21-22` (the provenance claim);
- a new test in `test/skills/eval-helpers-transcript.bats` or `test/generate-reports.bats`.

**Nature:** testing (no real-output regression control) plus unverifiable provenance
**Cost of Deferral:** `+0 — inert` while `transcript.jq` is frozen. Every edit to the allowlists or the census is a false-void risk that no test catches, and Item A is such an edit.
**Failure Cost:** (blank. A false void is loud and costs a re-run. It has no safety dimension.)
**Confidence:** High for what the files contain (this pass profiled them). Medium for their value against the current CLI, since they are 2.1.232 and the arithmetic-eval runs used 2.1.282/283.
**Legibility-target:** for-author

**Evidence (verbatim):**
```
# docs/reviews/execution-logs/cfc-299727c-committed-transcripts.txt (excerpt)
# per file: [init claude_code_version, census tool_uses, census tool_results, placed tool_uses, problems count, transcript_failures]
runs/review-arms/e7-fable-3x/mfc-corpus/rep3/transcript.jsonl ["2.1.232",241,241,241,0,[]]
runs/review-arms/e7-fable-3x/mfc-postfix/rep3/transcript.jsonl ["2.1.232",0,0,0,0,[]]
```
```
# this pass: profile of mfc-corpus/rep3 (event [type, subtype] counts)
    423 ["assistant",null]
      2 ["rate_limit_event",null]
     13 ["result","success"]
     13 ["system","init"]
    229 ["system","task_progress"]
    152 ["system","thinking_tokens"]
    241 ["user",null]
# this pass: all 16 files
init events per file: 14 13 17 3 4 9 5 9 8 12 14 9 7 1 9 6   (tools identical across inits in 16/16)
events with parent_tool_use_id != null: 3006 assistant, 1709 user
result permission_denials: [] in all 140 result events
16 x transcript_failures: 16 __VERDICT_COMPLETE__, 1.30 s total
```
```jq
# test/skills/transcript.jq:21-22
# Accepted shapes, from 13 real runs on CLI 2.1.282/283 (2026-09-25), where
# the census found exactly the positional calls (21 tool_use, 21 tool_result):
```

### What they are golden for, and what not

**Golden for `transcript_failures`: yes.** They are richer than any synthetic case:
- sub-agent events, with 3,006 assistant events under a parent `tool_use`;
- up to 17 init events per session;
- six `system` subtypes and `rate_limit_event`;
- thinking blocks;
- 12 tool names, including Agent and Skill.

A test that requires an empty, complete verdict and census = placed for each file answers the question iteration 5's Item C could not: does a strict reader void real runs? Such a test is the regression control for Item A's `IN` change, and for any future allowlist edit. It costs about 1.3 s and no repo growth, since the files are already tracked.

**Not golden for `deny_record_failures`.** The runs granted 30 tools, and every `permission_denials` is `[]`. They cannot exercise the tripwire, the canaries or the `["Bash"]` rule, and they do not re-validate the "13 real runs" claim (Claim 28). That half of C38 still needs A8's deny-record transcripts.

**One observation for Claim 31a.** Real sessions emit many init events, all with the same tools. So "check the first init" matches every observed shape, and a second, differing init is still unobserved.

### Fix Cost
- **Scope:** one bats test, about 15 lines. It loops over `git ls-files 'runs/**/transcript.jsonl'`, calls `transcript_verdict … transcript_failures` and checks census = placed. It skips with a message when no file is found, so a future `runs/` retention rule (C30) cannot turn it red.
- Also reword `transcript.jq:21-22` to name the verifiable anchor: "shapes checked against the 16 committed E7 transcripts (CLI 2.1.232); also observed, not committed: 13 deny-record runs on 2.1.282/283".
- **Effort:** under 30 minutes.
- **Risk:** low. A cross-directory read from `test/` into `runs/` couples the suite to an experiment archive. The skip guard bounds that.
- **Incremental?** Yes.

### Urgency Triggers
- Item A's allowlist change, which needs a real-output control. That is now.
- A8: add one or two deny-record transcripts, checked for secrets, to the same test. That closes the rest of C38.

### Recommendation

**Recommendation:** Fix now

It is cheap, uses files the repo already carries, and is the control Item A needs. Without it, the allowlist fix is verified only by this pass's one-off run. If Item A is not taken, the rating drops to Fix opportunistically. C38 stays open until A8 supplies the deny-record half.

---

## Item D: Posture (C39), status at the loop's end

**Severity/priority:** P2 (a record, not a change)
**Location:** the deny-record harness as sized in iteration-5 Item B; `docs/working/dd-arith-eval-bash-grant.md` "As built"
**Nature:** structural / investment relative to risk
**Cost of Deferral:** `+0 — inert`. The loop cap now enforces the freeze: this is iteration 6 of 6.
**Failure Cost:** `Low × Low` (unchanged from iteration 5 Item B)
**Confidence:** High for the size numbers. Medium for the convergence reading, which rests on one pass.
**Legibility-target:** for-author

**Evidence (verbatim):**
```
# this pass: git diff --numstat main...HEAD -- test/ (deny-record harness files)
165  0   test/skills/transcript.jq
198  0   test/skills/arithmetic-eval/mode1-equiv.py
70   0   test/skills/malformed-transcripts.bash
177  20  test/skills/eval-helpers.bash
89   15  test/skills/generate-reports.bash
42   2   test/skills/runner-contract.bash
346  3   test/generate-reports.bats
407  0   test/skills/mode1-equiv.bats
98   0   test/skills/arithmetic-eval-eval.bats
87   0   test/skills/arithmetic-eval-after-denial-patterns.bats
```
```
# git show --numstat b22a026, test/ only: +378 −183
```

**Sizing** (net lines):
- **Code:** 704 (165 + 198 + 70 + 157 + 74 + 40), up from 623.
- **Tests:** 938 (346 + 407 + 98 + 87), up from 821, in 91 `@test` blocks (46, 31, 9 and 5). Not every generate-reports.bats test is about deny-record.
- **Budget:** about 7.8× the DD's ~90-line design.

### What changed
Iteration 5 argued that the shape question "has no finite answer". The census has partly refuted that forecast. The census changed the question from "which positions are read" to "which objects are excluded from `..`". This pass then found:
- exactly one exclusion, the reader's own marker (Item A);
- one unrelated jq bug, which hides no call.

After Item A, the census has no exclusion. The residual moves to what the DD already accepts: concealed breaches (C29), CLI shape changes (fail-safe), and deny-record semantics untested on real output (C38).

So by-construction proved the better investment than iteration 5's freeze-only option would have been. The size cost is real, but it was a one-time cost.

### Recommendation

**Recommendation:** Carry intentionally

C39 stays open by choice. At merge the posture question is moot in practice. Record the residual list (below) in the DD "As built" section, so a future reviewer verifies a finite contract. Adopt the working rule only if the user wants one: "a new shape finding goes to the residual list, unless it is observed in a real transcript or is a one-line closure". Do not grow the harness further before A8 produces real deny-record output.

---

## Item E: The eval-level readers are lenient where the generator is strict (Claims 7, 31a)

**Severity/priority:** P3
**Location:** `test/skills/eval-helpers.bash:420` (`transcript_checked` uses `transcript_failures`), `:438` (misspelling guard reads only arrays); `test/skills/transcript.jq:111` (first init)
**Nature:** defense-in-depth asymmetry
**Cost of Deferral:** `+0 — inert`
**Failure Cost:** (blank. Through `eval_fixture` the generator voids an init-only run first, so the eval leniency is reachable only by a hand-run check.)
**Confidence:** High (Claim 7, executed)
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# test/skills/eval-helpers.bash:438
  known="$(transcript_jq "$t" 't::init | .tools // [] | if type == "array" then .[] | strings else empty end' 2>/dev/null || true)"
```

### Carrying Cost: Low
Both gaps are behind the generator's voiding. Real transcripts always carry an array `tools` and repeat identical inits (Item C profile).

### Fix Cost
- **Effort:** under 1 hour. Give the init event a shape rule (`tools` must be an array) in `transcript_failures`, and require a result event.
- **Risk:** low with Item C's control in place.

### Urgency Triggers
- A second skill uses `tool_called:` or `no_tool_called:` outside the generator, for example a graded-by-hand transcript.

### Recommendation

**Recommendation:** Carry intentionally

The generator already covers both paths that grade. List it in the residuals.

---

## Triage Summary

| # | Debt Item | Carrying Cost | Cost of Deferral | Failure Cost | Fix Cost | Urgency | Recommendation |
|---|-----------|:---:|:---:|:---:|:---:|:---:|---|
| A | Census skips `__text`-keyed events; allowlists match substrings (Claims 24, 25b) | Low | +1 Incorrect claim per pass | Low × Low — needs a non-CLI shape | <30 min, 6 lines (verified) | Merge | Fix now |
| B | Prose residue: log #56 list, DD exit contract/BOM/first init, rubric A29 marker | Low | +1 Incorrect/Stale claim per pass |  | <30 min, prose | Merge | Fix now |
| C | 16 committed real transcripts unused as golden cases; `:21-22` cites uncommitted runs | Low | +0 while frozen; each allowlist edit is an untested false-void risk |  | <30 min, 1 test | Item A; A8 | Fix now |
| D | C39 posture: 704 code / 938 test lines (~7.8× budget), converged after census | Low (frozen by cap) | +0 — inert | Low × Low | Record only | None | Carry intentionally |
| E | Eval-level init-only / string-`tools` leniency; first init only | Low | +0 — inert |  | <1 h | Second skill uses the checks | Carry intentionally |

**Net debt at merge:** if A–C land in one terminal commit (about 1 hour), nothing left on the branch is above Low carrying cost. Every stated contract then matches an executed verdict. What stays open:
- one posture record (D);
- one intentional carry (E);
- C38's deny-record half, tied to A8;
- the settled Deferred and open-by-choice rows (C14, C24, C30, C34, C35, C37, C39).

If A–C do not land, the branch still merges safely. Both gaps are Low × Low and unreachable from real CLI output. But `main` would carry a module header, log #56 and rubric A29 that fact-check has marked Incorrect or Stale. In that case the merge commit must list those claims as known-wrong.

### Recommended Order
1. **One terminal commit before the merge:** A (6 lines and 2 table rows), C (the golden test and the `:21-22` reword), and B (prose). C goes in with A, as A's control. Run the four suites and `scripts/health-check.sh`, and paste the TAP plan lines (C34 practice).
2. **Archive commit:** the untracked `docs/reviews/code-fact-check-report.md` and `docs/reviews/execution-logs/cfc-299727c-*`, as prior iterations did (5bdee46, 9c73ae4, 299727c). Stage them by path, because the untracked, 0-byte `devcontainer-config/.env*` and lockfile stubs are not branch content.
3. **At A8:** add deny-record transcripts to Item C's test, and close C38.
4. **When a second skill reuses the checks:** Item E, C24.

---

## What the merge commit should record

Suggested body for the local `--no-ff` merge (adjust to what lands):

```
Merge skill-fixtures: Q-062 [2] install gate; Q-063 [1] arithmetic-eval
LLM fixtures via Bash deny-and-record.

Review-fix loop: 6 iterations (cap 3, extended by the user to 6). Final
state: R1-R4, A1-A29 Fixed or Acknowledged (A1 -> Q-064; A20 ack). <If the
terminal commit landed:> Iteration-6 findings (fact-check Claims 24, 25b:
census marker key, substring allowlists) fixed after the last review pass;
probe- and suite-verified, not re-reviewed.

Contract (transcript.jq): every tool_use/tool_result object in any parsed
event is censused, validated and counted; event and block types are exact
allowlists; deny-record adds init tools == ["Bash"], all calls Bash, all
denied, canaries, no foreign denial; .failed is fail-closed with a sentinel.

Accepted residual (DD "As built"): accidental breaches only, not concealed
ones (C29); a CLI format change voids runs until the module is updated;
only the first init event is checked (real sessions repeat identical
inits); eval-level checks rely on the generator for init-only/string-tools
transcripts; deny-record semantics are untested on committed real output.

Evidence not in the repo: "13 real runs on CLI 2.1.282/283" and "Haiku
routing 5/5 with no false voids" (fact-check Claims 28, 35). The 16
committed E7 transcripts (CLI 2.1.232) pass the generic reader.

Open by choice / Deferred: C3 C4 C6 C8 C13 C14 C15 C24 C30 C34 C35 C37 C38
C39. Triggers: A8 (C38 deny-record transcripts), second skill reusing the
checks (C24, iter-6 Item E).

Confidence: high (tests, health-check, fact-check 26/38 verified at 299727c)
Notes: harness is ~7.8x its design budget (C39); frozen pending A8.
```

---

## Goal-Alignment Note

- **Answered.** The brief asked for a terminal tech-debt triage of `skill-fixtures` at 299727c, saved to this path with `Commit: 299727c` at the top, advisory and not committed. Each focus item is covered:
  - **Net debt at merge:** the status table, the summary table and "Net debt at merge", with both outcomes (A–C land, or they do not).
  - **Status changes:** every iteration-5 item (A–F) and C30, C34, C38 and C39 has a row. Iteration-5 C, D and E are retired, F is mostly retired, and A recurs as Items A and B.
  - **C39:** Item D. It stays open by choice. The new evidence is that the census converged, and the loop cap now enforces the freeze.
  - **C38:** Item C. The 16 transcripts are golden for `transcript_failures` and not for `deny_record_failures`. Use them now as Item A's control, and leave the deny-record half to A8.
  - **The merge commit:** the section above.
- **Format:** every item carries a priority, Location, verbatim Evidence, Confidence, Legibility-target and one of the four Recommendation values.
- **Beyond fact-check:** I ran a hermetic probe of the candidate Item A fix on a `git archive` copy in the scratchpad (four suites, the refuting probes, the 16 real transcripts) and profiled the real transcripts. No `claude` or network command was run, and the working tree was not modified.
- **Not re-litigated:** the settled rows and the DD residual. C38 and C39 get evidence and status only.
- **Judgment calls:**
  - I rated Item C Fix now, not Fix opportunistically, because it is Item A's regression control.
  - I read C39's history as "by-construction converged", which reverses iteration 5's forecast. It rests on one pass of evidence (Medium confidence).
- **Escalate:** whether to land a code change (Item A) after the last authorized review pass is the user's call. This triage recommends it, and the commit body should say that it was not re-reviewed.
