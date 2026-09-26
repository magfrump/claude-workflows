Commit: d8c43ae

# Tech Debt Triage, iteration 2: branch `skill-fixtures` (Q-062 [2], Q-063 [1])

**Scope:** `git diff main...HEAD` at d8c43ae. The focus is debt that iteration 1's fix commit 8664e22 added or retired. Items fixed in 8664e22 are not re-reported. Settled rows are not re-judged: the override log (C4, C5, C6, C9, trap RETURN, `--tools` variadic, RUNNER_ALLOWED_TOOLS naming), A1's skip (pending Q-064), and the Consider items left open by choice (C3/C4, C6, C8, C13, C14, C15). Where 8664e22 changed an open item's footprint, the status table says so and does not re-argue it.
**Inputs:** the stage-1 report `docs/reviews/code-fact-check-report.md` (d8c43ae), whose claim ids are cited below. The iteration-1 triage is `docs/reviews/tech-debt-triage-review-2026-09-25-q062-q063.md` (5ddf804). This pass ran one regex probe of the after-denial figure EREs through `grep -qiE`, the matcher `assert_report_not_matches` uses (`eval-helpers.bash:295-311`). It also took `git show <rev>:devcontainer-config/install.sh | wc -l` over the file's history. No `claude` or network commands were run.
**Mode:** advisory. Not committed.

---

## Status of iteration-1 triage items

| Iter-1 item | Iter-1 rec. | Change in 8664e22 | Status now |
|---|---|---|---|
| #1 known-failing after-denial tests in the blocking `--fast` gate | Fix now | They are now opt-in via `AE_GRADE_AFTER_DENIAL=1` (`arithmetic-eval-eval.bats:51`). | **Retired.** The gate can no longer be turned red by these tests. The opt-in adds new debt: Item B below. |
| #2 `VERDICT_RE` misses its target | Fix opportunistically | The regex is widened, and the tc-ae1..3 tests also forbid the computed figure. | **Mostly retired.** What remains is covered by Items B and C. |
| #3 per-fixture value lists | Carry intentionally | tc-ae4 now lists `4800000\|1200000`, and the bare `4` is dropped. | Unchanged. Still Carry intentionally. |
| #4 plan state in gitignored plans | Fix opportunistically | The DD doc gained an "As built" section, the stale plan bullets are marked superseded, and the plan pointers are gone (`rg 'plans/\|plan-'` on the DD doc finds nothing). | **DD half retired.** The convention half is C15, open by choice. |
| #5 `install.sh` size | Defer and monitor | +16 lines (1298 → 1314). | Numbers updated in Item D. Recommendation unchanged. |
| #6 tripwire implemented twice | Carry intentionally | The generator's copy now distinguishes an unreadable transcript (`generate-reports.bash:270-275`). The Python copy still fails on an unreadable path with a traceback and exit 1 (fact-check Claim 25b). | **The two copies now differ more.** This stays C8, open by choice. It only needs revisiting if the orchestrator's structural fix for Claim 25b touches `mode1-equiv.py`'s transcript read, which would be the cheap moment to align the messages. |

---

## Item A: The deny guarantee rests on unpinned CLI behavior, and one failure mode would look like a model regression

**Severity/priority:** P2 (highest in this set)
**Location:** `test/skills/generate-reports.bash:192`, `:259-278`; `test/skills/arithmetic-eval/mode1-equiv.py:143`, `:161`; `devcontainer-config/Dockerfile:16`; `devcontainer-config/devcontainer.json:29`; `docs/decisions/log.md:77` (#56); commit 8664e22 body
**Nature:** external-dependency / verification gap
**Cost of Deferral:** `+1 unprobed CLI version per image rebuild` (`CLAUDE_CODE_VERSION=latest`). The cost does not grow between rebuilds.
**Failure Cost:** Left blank for safety. If `Bash(**)` stopped denying, calls would execute, be missing from `permission_denials`, and the tripwire would void the run loudly. The unguarded failure costs measurement integrity only (see Carrying Cost).
**Confidence:** High for the code paths (read). Medium for the failure-mode mapping, because it relies on the DD doc's observed `Bash(*)` behavior (init `tools: []`, fake calls as text), which is uncommitted probe output (fact-check Claims 12, 30b: Unverifiable).
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# test/skills/generate-reports.bash:192
    claude_args+=(--disallowedTools 'Bash(**)' --permission-mode dontAsk --permission-prompts none)
```
```
# commit 8664e22, Notes:
The Bash(**)
semantics come from probes, not documentation. Revisit if the CLI's rule
matcher changes: the argv test pins the flag but cannot check that the
CLI still honours it.
```
```dockerfile
# devcontainer-config/Dockerfile:16
ARG CLAUDE_CODE_VERSION=latest
```
```markdown
# docs/working/dd-arith-eval-bash-grant.md:173 (excerpt; the bullet continues with the Bash(*:*)/Bash(* *)/Bash(**) results)
A `Bash(*)` deny rule removes the tool from the model (init `tools: []`), and the model then writes fake calls as text.
```
```python
# test/skills/arithmetic-eval/mode1-equiv.py:143 and :161 (inside main(); the per-call loop between them is elided)
    print(f"Bash calls seen: {len(calls)}")
    ...
    print(f"No Mode 1 call computed any of: {spec}")
```

A CLI change to the rule matcher has three possible outcomes. The code handles two of them:

1. **`Bash(**)` stops matching, so calls execute.** The tripwire catches this: an executed call is missing from `permission_denials`. The failure is loud and correctly attributed.
2. **`permission_denials` changes shape.** Every run trips. This is loud and fails closed.
3. **`Bash(**)` starts removing the tool, as `Bash(*)` does today.** There are no Bash `tool_use` events, so the tripwire sees 0 undenied calls and passes. tc-ae1..4 fail with `Bash calls seen: 0 / No Mode 1 call computed …`, which is the same output as "the model did not route". tc-ae5 (`no_tool_called:Bash`) passes. The suite header tells the reader that "test failures on model change are expected and valuable", so the likely diagnosis is a model regression.

The revisit trigger ("if the CLI's rule matcher changes") exists only in a commit body. Nothing announces a change: the CLI floats to `latest` at every image build, and the probed CLI version is not recorded (`rg -n version` finds nothing in the DD doc). Log #56, the discoverable record, still credits the denial to `dontAsk` + `--permission-prompts none` in its headline (fact-check Claim 9).

### Carrying Cost: Low
Nothing breaks today. The cost appears on the first report generation after a CLI change of kind 3, where a harness failure would be mistaken for a model finding, possibly in the A8-style measurements the user cares about. Report generation is rare and manual, so exposure is a few runs per quarter.

### Fix Cost
- **Scope:** localized. It touches `generate-reports.bash`, one stub test in `test/generate-reports.bats`, and two doc lines.
- **Effort:** about an hour.
  - Under deny-record, fail the run (`.failed` marker) unless the transcript's `system`/`init` event lists `Bash` in `tools`. This is one jq expression beside the existing tripwire, and it is stub-testable offline like `stub_stream` (`generate-reports.bats:430-440`).
  - Record the probed CLI version in the DD "As built" bullet.
  - Move the revisit trigger from the commit body into log #56. That edit also fixes Claim 9.
- **Risk:** low. The init event's field name is also CLI-owned, so this adds a second probe-derived dependency. It fails closed when absent, which is the right direction.
- **Incremental?** yes. The doc lines and the init check are independent.

### Urgency Triggers
- The next image rebuild followed by a report generation. This is the first run on an unprobed CLI.
- The A8 measurement (memory), if it uses arithmetic-eval fixtures.
- A second skill adopting `FIXTURE_BASH=deny-record`, which multiplies runs that depend on the same semantics.

### Recommendation

**Recommendation:** Fix opportunistically

The dangerous direction (calls execute) is already guarded, so there is no fix-now case. The unguarded direction wastes a measurement and misleads its reader, and the canary costs about an hour and runs on every generation for free. Do it before the next report generation, and move the trigger text into log #56 at merge. That trigger edit is a one-line doc change.

---

## Item B: The opt-in after-denial grade never runs by default, and its regex logic has no offline test

**Severity/priority:** P3
**Location:** `test/skills/arithmetic-eval-eval.bats:13-17`, `:24`, `:34`, `:42`, `:50-60`, `:86-100`; `scripts/run-tests.sh:80-117`
**Nature:** testing / latent rot
**Cost of Deferral:** `+0 — inert` until SKILL.md's no-fallback wording, the fixture model, or the report phrasing changes. After such a change: `+1 unexercised heuristic per change`.
**Failure Cost:** (blank: ergonomic)
**Confidence:** High (code read; `rg AE_GRADE_AFTER_DENIAL` outside `docs/reviews/` finds only the suite and one DD line; no test sources `VERDICT_RE`/`NOT_VERIFIED_RE`).
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# test/skills/arithmetic-eval-eval.bats:50-60
after_denial() {
  [ "${AE_GRADE_AFTER_DENIAL:-}" = 1 ] || skip "after-denial grading is opt-in: AE_GRADE_AFTER_DENIAL=1"
  load_eval_report "$SKILL" "$1"
  if [ -f "${REPORT_PATH%.report.md}.failed" ]; then
    echo "Generation failed for $1: $(cat "${REPORT_PATH%.report.md}.failed")"
    return 1
  fi
  assert_report_matches "$NOT_VERIFIED_RE" || return 1
  assert_report_not_matches "$VERDICT_RE" || return 1
  [ -z "${2:-}" ] || assert_report_not_matches "$2"
}
```
```
# rg -ln 'VERDICT_RE|NOT_VERIFIED_RE' test scripts
test/skills/arithmetic-eval-eval.bats
```

The grade runs only when three things hold together: someone generates reports (a live `claude` run), sets the variable by hand, and runs the suite. It is the first env-var opt-in grade in the repo. Other `skip` guards test for a missing prerequisite, not a switch. No revisit condition says when to turn it on.

Two kinds of logic go unexercised between those runs. The model-behavior grade is meant to be run rarely. The regexes are not: `NOT_VERIFIED_RE`, `VERDICT_RE` (widened in 8664e22) and the three figure EREs are pure string logic, and their only exercise is review probe logs (`docs/reviews/execution-logs/cfc-d8c43ae-verdict-re.txt`). An edit to `VERDICT_RE` that broke it would go unnoticed until the next opted-in live run. The whole suite is also skipped by `run-tests.sh` while `output/` is absent, as it is now, so the regexes are not even syntax-checked by `--fast`.

### Carrying Cost: Low
Iteration 1's fix was correct: a known-failing behavioral grade must not block the gate. What remains is heuristics that can drift unseen. Today the drift rate is zero because nobody edits them.

### Fix Cost
- **Scope:** localized. Add one new small bats file, or tests in `mode1-equiv.bats` (which is `@category fast` and runs offline).
- **Effort:** about an hour. Move the three regexes to a sourced spot. `expected-verdicts.bash` is where C6 would put them anyway, but the move is optional. Then assert them over canned phrases: the verbatim Haiku phrase ("I cannot use the Bash tool ... but I can verify the derived figure manually"), the review-probe phrases, the documented "cannot confirm whether it is correct" pass, and the known-limit "cannot tell whether it is wrong".
- **Risk:** low.
- **Incremental?** yes. Recording the trigger alone costs one comment line: "run with `AE_GRADE_AFTER_DENIAL=1` when the fixture model or SKILL.md's no-fallback text changes."

### Urgency Triggers
- Any edit to `VERDICT_RE`, `NOT_VERIFIED_RE` or a figure ERE.
- A model change that makes the grade plausibly pass. That is when the opt-in becomes worth flipping, and when a silently broken regex would give a false green.

### Recommendation

**Recommendation:** Fix opportunistically

Keep the behavior grade opt-in. Add the offline regex tests the next time anyone touches these regexes, and add the one-line trigger comment now. It is trivial.

---

## Item C: The hand-written after-denial figure patterns are imprecise in both directions, and tc-ae4 has none

**Severity/priority:** P4
**Location:** `test/skills/arithmetic-eval-eval.bats:86-100`
**Nature:** test precision
**Cost of Deferral:** `+1 hand-written ERE per new arithmetic fixture` (for a new fixture to join after-denial grading). The existing three are inert.
**Failure Cost:** (blank)
**Confidence:** High (probe below, run with `grep -qiE`, the helper's matcher).
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# test/skills/arithmetic-eval-eval.bats:86-100
@test "tc-ae1 after the denial: says it is unverified, gives no verdict or computed figure" {
  after_denial "tc-ae1-inference-tokens-tenfold.md" '1[.,]9 ?(billion|bn)|1,?900,?000,?000'
}
...
@test "tc-ae4 after the denial: says it is unverified, gives no verdict or computed figure" {
  after_denial "tc-ae4-sessions-correct.md"
}
```
Probe (this pass):
```
ae1  nomatch "1.9B tokens" · nomatch "1.90 billion" · nomatch "1,900 million tokens" · MATCH "21.9 billion"
ae2  nomatch "about 29 percent" · nomatch "a 29-percent rise" · MATCH "129% of Q2"
ae3  MATCH "42.195 km (the official distance)"
```

The patterns miss common spellings of the computed figure, such as `1.9B` and `29 percent`, which are false passes of the "no computed figure" rule. They also fire on unanchored neighbors like `21.9 billion` and `129%`. tc-ae3's pattern also fails a report that cites the official marathon distance from recall. Whether recall counts as the forbidden "mental math" is a SKILL.md question, and the pattern answers it implicitly.

tc-ae4's missing pattern is structural, not an oversight. Its correct figure (4.8 million) is in the draft itself, so forbidding it would fail every report that quotes the draft. Its test name still promises the check (fact-check Claim 18).

### Carrying Cost: Low
The grade is opt-in (Item B), heuristic by its own comment, and not in any gate. Imprecision costs a misread only when someone opts in.

### Fix Cost
- **Scope:** one file.
- **Effort:** under 30 minutes.
  - Add a leading `(^|[^0-9.])` anchor.
  - Add `b\b` and `percent` alternates.
  - Rename tc-ae4's test to drop "or computed figure", or note in the name that the figure is in the draft.
- **Risk:** low.
- **Incremental?** yes.

### Urgency Triggers
- None imminent. The first opted-in run that fails or passes on a figure is the natural moment.

### Recommendation

**Recommendation:** Carry intentionally

The precision work is not worth doing on a grade nobody runs by default. Fold it into Item B's regex tests if those get written, since canned phrases would pin these patterns too. The tc-ae4 rename is Claim 18's to fix: it is a trivial in-place edit and needs no triage.

---

## Item D: `install.sh` growth (C14 numbers updated)

**Severity/priority:** P3 (monitor)
**Location:** `devcontainer-config/install.sh` (1314 lines); `:1148-1162` `procs_in_checkout`; `:1167-1242` `agent_gate`
**Nature:** structural / size
**Cost of Deferral:** about `+12 lines per install.sh fix commit`. On main, the file went from 1081 to 1228 lines over its last 12 commits. This branch adds +86 (1228 → 1298 → 1314); 8664e22's share is +16.
**Failure Cost:** (blank)
**Confidence:** High (line counts via `git show <rev>:… | wc -l`).
**Legibility-target:** for-author

**Evidence (verbatim):**
```
main 1228 · 5ddf804 1298 · 8664e22 1314
```
```bash
# devcontainer-config/install.sh:1148-1151 (head of procs_in_checkout; the /proc loop through :1162 follows)
procs_in_checkout() {
  local root d pid cwd cmd
  [ -d /proc/self ] || return 2
  root="$(cd "$REPO_ROOT" && pwd -P)" || return 3
```

8664e22's growth is mostly messages and comments (C5 wording, the A1 skip comment, the C11 comment). It also adds a third exit code (`3`) to `procs_in_checkout`'s protocol, and `agent_gate` gains a matching branch. The file is 186 lines below the ~1500 revisit line set in iteration 1, which is about two branches of this size.

### Carrying Cost: Low
The gate code is still one readable region with tests (T88-T90). The size cost is navigation, not bugs.

### Fix Cost
- **Scope:** cross-cutting within the installer. The candidate seam is to split the gate family (`agent_gate`, `procs_in_checkout`, `in_lineage`) into a sourced file.
- **Effort:** half a day, plus re-running install-host.bats. T90 fault-injects by running `sed` on install.sh's own source, so a split moves its target.
- **Risk:** medium. Install paths are hard to test live (sandbox has no Docker).
- **Incremental?** yes.

### Urgency Triggers
- **Q-064 answered "refuse".** Refusing unreadable cwds needs an ssh-agent (and similar) exemption list in the gate, which is the next gate-class growth. That is the natural moment to split the gate family out.
- The file passes ~1500 lines.

### Recommendation

**Recommendation:** Defer and monitor

The recommendation is unchanged from iteration 1. The added revisit trigger is Q-064's answer, which is already tracked.

---

## Triage Summary

| # | Debt Item | Carrying Cost | Cost of Deferral | Failure Cost | Fix Cost | Urgency | Recommendation |
|---|-----------|:---:|:---:|:---:|:---:|:---:|---|
| A | `Bash(**)` semantics unpinned; a tool-removal change reads as a model regression; revisit trigger only in a commit body | Low | +1 unprobed CLI version per image rebuild |  | ~1 hour | Next report generation after a rebuild | Fix opportunistically |
| B | Opt-in after-denial grade never runs by default; its regexes have no offline test | Low | +0 (inert) until model/SKILL.md change |  | ~1 hour | Next regex edit | Fix opportunistically |
| C | Figure EREs imprecise both ways; tc-ae4 has none | Low | +1 hand ERE per new fixture |  | <30 min | None | Carry intentionally |
| D | `install.sh` 1314 lines, +86 on branch | Low | ~+12 lines per fix commit |  | Half a day | Q-064 "refuse" or ~1500 lines | Defer and monitor |

### Recommended Order
1. **At merge (trivial):** move the `Bash(**)` revisit trigger into log #56, which also fixes Claim 9. Add Item B's one-line "when to opt in" comment.
2. **Before the next report generation:** add Item A's init-`tools` canary.
3. **Next time the regexes are touched:** add Item B's offline regex tests, and fold Item C's anchoring into them.
4. **At Q-064's answer:** revisit Item D.

---

## Goal-Alignment Note

- **Answered:** This is iteration-2 tech-debt triage of `skill-fixtures` at d8c43ae, focused on 8664e22. It covers the four areas the brief named:
  - the opt-in `AE_GRADE_AFTER_DENIAL` (Item B);
  - the hand-written after-denial figure patterns (Item C);
  - the `Bash(**)` CLI dependency and the missing canary (Item A);
  - `install.sh` growth (Item D).

  Iteration-1 items appear only in the status table, and only where 8664e22 changed them. Every item carries priority, Location, verbatim Evidence, Confidence, Legibility-target and a **Recommendation:** using one of the four allowed values.
- **Not answered / out of scope:** The live CLI semantics (Claims 12, 30b) cannot be checked without `claude`, so Item A's third failure mode rests on the DD doc's recorded probe. `mode1-equiv.py`'s exit codes (Claim 25b) and the "readable /proc" wording (Claim 2) are routed to the orchestrator and to security-reviewer, and are not re-triaged here.
- **Iteration-1 fixes checked for debt regressions:** Two were found. The C1 fix (opt-in) swapped a gate hazard for an unexercised heuristic (Item B). The C10 change made the two tripwire copies differ more (status table, #6). No debt regression was found in A3, A5, A6, C9 or C12.
