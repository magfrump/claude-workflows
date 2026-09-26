Commit: 299727c

# Security Review: skill-fixtures, q062/q063 iteration 6 (census fix b22a026, terminal pass)

**Scope:** `git diff main...HEAD` at 299727c, focused on `git show b22a026`: `test/skills/transcript.jq`, its readers in `test/skills/generate-reports.bash` (`generate_one`) and `test/skills/eval-helpers.bash` (`transcript_jq` … `assert_mode1_equiv`), and `test/skills/arithmetic-eval/mode1-equiv.py`
**Date:** 2026-09-26
**Based on:** `docs/reviews/code-fact-check-report.md` (Claims 24, 25b, 6, 1, 31a, C36). Probes: `docs/reviews/execution-logs/sec-299727c-iter6-probes.sh` → `.txt` (2026-09-26T09:08:02Z, exit 0; passes `shellcheck -x -e SC1091 -s bash -S warning`)

No HALT: none of the escalation patterns applies.

## Trust Boundary Map

```
B1: [claude -p stdout: CLI-shaped events, model-authored nested content] → [transcript.jq events + problems + census] → [verdict failure lines]
B2: [verdict lines on jq stdout]              → [sentinel check: generate_one :291, transcript_verdict :404] → [.failed marker / eval pass]
B3: [events read OUTSIDE the census: init, denials, last result] → [no validation (see Finding 1)] → [deny-record canary/tripwire, result_state, report text]
B4: [census .input.command (model-authored)]  → [mode1-equiv.py split_mode1 + AST equality] → [python3 -c SKILL.md evaluator (exec)]
```

```
S1: top-level event keys/types/fields     — per run, CLI-authored — UNTRUSTED toward the verdict sink (a CLI shape change is the stated threat; must be validated before being read)
S2: nested content (tool input, text, tool_result content) — per run, model-authored — UNTRUSTED (all sinks)
S3: verdict_def, jq filter strings, sentinel literal — code-constant — trusted (all sinks)
S4: skills/arithmetic-eval/SKILL.md Mode 1 program — deploy-time repo file — trusted for exec (self-tested, 6 * 7)
S5: check specs (tool names, expected values), FIXTURE_BASH — deploy-time fixture/runner — trusted
```

The transcript enters from the CLI (B1). The module's stated design is that one validated census feeds every check. The claim holds for calls. It does not hold for events: the set of events that `problems` validates is smaller than the set that `init`, `denials` and the generator's result reads consume (B3). The verdict sentinel (B2) could not be forged from S1/S2 data in any probe.

## Findings

#### 1. The `__text` marker lives in the event's key namespace, and three more readers consume the events it exempts from validation (extends Claim 24)

**Severity:** Medium
**Location:** `test/skills/transcript.jq:45-46, 56-57, 70, 111, 114-115`; `test/skills/generate-reports.bash:252-261`
**Boundary:** B1, B3
**Move:** 2 (implicit sanitization assumption), 11 (guardrail bypasses)
**Confidence:** High for the mechanism (executed). Likelihood is Low: no known CLI emits a top-level `__text` key.
**Legibility-target:** for-author
**Property violated:** complete mediation / no in-band signaling. Every value a verdict reads must come from an event the verdict validated, and the reader's own control marker must not be expressible in the data it marks.

The census skips `__text` events. The rest of the module does not:

```jq
# test/skills/transcript.jq:56 (census: skips them)
def tool_uses: [.[] | objects | select(has("__text") | not) | .. | objects | select(.type == "tool_use")];
# :70 (validation: skips them)
  elif has("__text") then empty
# :111 (reads them)
def init: [.[] | objects | select(.type == "system" and .subtype == "init")] | first;
# :114-115 (reads them)
def denials: [.[] | objects | select(.type == "result") | .permission_denials | arrays | .[] | objects
  | {tool_name, tool_use_id}];
```

The generator's report and result-state reads (`generate-reports.bash:253, 259`, `[.[] | objects | select(.type == "result")] | last`) also include `__text` events. Claim 24 showed a call hidden inside such an event. These probes add three effects with the call in plain view, all passing end to end (`sec-299727c-iter6-probes.txt`, Parts 1 and 4):

- `text_key_result_supplies_denial`: a placed, undenied Bash call `x1` with its tool_result, a real result event with `permission_denials: []`, and then `{"__text":0,"type":"result",…,"permission_denials":[{"tool_name":"Bash","tool_use_id":"x1"}]}`. The verdict is only `__VERDICT_COMPLETE__`, the generator leaves `no .failed marker: the run PASSED`, and `transcript_verdict … deny_record_failures -> exit 0`. The control without that line fails with `Bash tripwire: 1 call(s) not in permission_denials (may have executed)`. So the tripwire is satisfied by a denial record that nothing validated.
- `text_key_init_only`: a `__text` init as the only init satisfies `transcript_failures`' "no init event" check (control: `no init event in the stream`). In `text_key_init_shadows_real_init`, a `__text` init with `["Bash"]` ahead of a real init with `["Bash","Read"]` makes the canary read the unvalidated one. The generator passes; the control fails on the init canary.
- `text_key_result_state`: a real `is_error:true` result followed by a `__text` result gives `result_state: ok`, and the report text comes from the unvalidated event. The generator passes. (In a real run the error would probably also give a non-zero exit, which `failure` records separately.)

The placed-call variant is caught only by accident. `_placed_tool_uses` (`:62`) does *not* exclude `__text`, so the census and placement counts disagree. That asymmetry is itself an instance of the property.

The marker has no purpose that needs it to be an object. Ignored lines are, by definition, read by nothing. A fix confined to the census, such as dropping `select(has("__text")|not)` there, leaves all three effects above. A fix that adds the same `select` to `init`/`denials`/the result reads keeps the in-band key for the next reader to forget.

**Recommendation:** In `events`, drop ignored text lines (`else empty`) and represent an unparsed line out of band. For example, emit the raw `$line` string: `_event_problems` already fails any non-object as "a line is not a JSON object". Alternatively, wrap every event (`{ev: …}` / `{unparsed: …}`) so no data key can collide. Then delete every `has("__text")` guard. Extend the insertion property test to vary *keys* as well as containers: a reserved or unknown top-level key on every event type, through the generator and `transcript_verdict`. `__unparsed` collides the same way but fails closed (probe `control_unparsed_key_collision` → "does not parse"), so the out-of-band fix should cover it too.

#### 2. Only the first init event is checked, and the real CLI emits many per run

**Severity:** Low
**Location:** `test/skills/transcript.jq:111, 149-150`; `test/skills/eval-helpers.bash:438`
**Boundary:** B3
**Move:** 5 (invert the access-control model: what the check does not cover)
**Confidence:** High (executed)
**Legibility-target:** for-author
**Property violated:** validate every instance of a repeated record, not a representative one.

```jq
# test/skills/transcript.jq:149-150 (excerpt; the list continues to :161)
      | [ (init | .tools) as $tools
          | if init != null and $tools != ["Bash"] then "Bash init canary: …" else empty end,
```

Claim 31a notes that a second init with `["Bash","Read"]` passes. What this adds is that the shape is real, not hypothetical. 15 of the 16 committed transcripts (`runs/**/transcript.jsonl`, CLI 2.1.232) carry 3 to 17 init events per run, one after each background-task turn (Part 2 table). In all of them the tools list is identical across inits. `permissionMode`, the field that records the posture deny-record depends on (`dontAsk`), is never checked. Probe `later_init_bypass_mode` (a later init with `"permissionMode":"bypassPermissions"`) passes the generator. The breach-level checks still hold: a non-Bash call fails on "a tool other than Bash" (Claim 31a), and an executed call is absent from `permission_denials` and trips the tripwire. So this weakens the canary, not the tripwire. It is defense in depth, which is why it is rated Low under the floor rule.

**Recommendation:** Check every init, for example `[… select(.type=="system" and .subtype=="init") | .tools] | unique == [["Bash"]]`. Consider requiring `permissionMode == "dontAsk"` once a committed 2.1.282+ deny-record transcript confirms the field's presence and value. None is on disk to confirm it (untested; see below).

## Answers to the brief's questions

- **Other markers, reserved keys and pre-census filters.** The module has two reserved keys, `__text` and `__unparsed`, and grep finds no others in `test/`. `__text` opts data out (Finding 1 and Claim 24). `__unparsed` fails closed. The other pre-census filters cannot hide a call:
  - `select(test("\\S"))`: whitespace-only lines hold no JSON.
  - The brace test at `:46`: structural `{`/`[` must be literal in JSON, so a line without either cannot parse to an object.
  - `.[] | objects`: a non-object event is voided by `_event_problems`' first branch.
  - `inside/1` (Claim 25b): it widens the accepted types but does not narrow the census.
- **Sentinel forgery.** Not possible from data in any probe (Part 3). Every data-bearing failure string starts with a fixed prefix, and `_one_line` maps C0 controls, so an embedded `\n__VERDICT_COMPLETE__` stays on the failure line (`… (CLI 1 __VERDICT_COMPLETE__)`). U+2028 and NEL do not split under `mapfile`. A raw text line equal to the sentinel is ignored as text. In every case there is exactly one sentinel line, and it is last. Forging would not help anyway: the generator appends every line but the last to `failure` (`:294`), and `transcript_verdict` fails on more than one line (`:408`).
- **First-init-only.** It matters for the canary, not the tripwire (Finding 2). The real CLI does emit later inits.

## Untested bypass candidates

- **C1 control characters.** `_one_line` (`:52`) maps codepoints < 32 and 127 only, so U+0080–U+009F reach `.failed` and the terminal through `echo "  FAILED: …"`. Line splitting was tested (NEL: no split). How a terminal interprets 8-bit CSI was not tested.
- **jq versions other than 1.6.** `fromjson` depth limit, BOM handling, `inside` semantics and `first` on an empty array were not tested. The probes ran on the sandbox jq only.
- **2.1.282+ deny-record transcripts.** None is committed or on disk, so it is unknown whether real deny-record runs carry several inits, `permissionMode`, or denials outside `result` events. A denial outside a result event would be ignored, which is fail-safe.
- **Two result events that disagree on `permission_denials`.** `denials` unions them. This was not probed beyond the `__text` case.

## Endorsement Claims

- **Claim:** No transcript content probed produced a verdict line equal to `__VERDICT_COMPLETE__` other than the final line. This covered the sentinel as an event type, after `\n` in a block type and in `claude_code_version`, after U+2028/NEL in init tools, and as a raw text line.
  **Location:** `test/skills/transcript.jq:49-52, 123, 164-165`
  **Evidence:** executed
  **Verified:** `sec-299727c-iter6-probes.txt` Part 3: `sentinel_lines=1 last_is_sentinel=yes` for all five. The generator and `transcript_verdict` fail two of them end to end (Part 4).
  **Not verified:** failure strings whose interpolated values come from fields not probed here. `:83` interpolates block `.type`, `:73` event `.type` and `:150` `tools`/`claude_code_version`; the others are fixed text.
  **route: code-fact-check**
- **Claim:** In both consumers, a verdict with any line before the sentinel is recorded as a failure, whatever that line's text.
  **Location:** `test/skills/generate-reports.bash:291-297`, `test/skills/eval-helpers.bash:401-411`
  **Evidence:** read-static
  **Verified:** read `generate_one` in full (:140-313) and `transcript_verdict` in full (:393-412).
  **Not verified:** `print_verdict` erroring on a non-string failure element mid-output. That case would drop the sentinel and void the run (read-static reasoning only).
  **route: code-fact-check**
- **Claim:** A real JSON event carrying the `__unparsed` key is voided ("a line containing JSON-like text does not parse").
  **Location:** `test/skills/transcript.jq:69`
  **Evidence:** executed
  **Verified:** probe `control_unparsed_key_collision`.
  **Not verified:** `__unparsed` combined with `__text` on one event (read-static: `:69` precedes `:70`, so the event is voided).
- **Claim:** `mode1-equiv.py`'s new self-test runs the SKILL.md evaluator on the constant `"6 * 7"` only. Model-authored expressions reach `evaluate` only after `split_mode1` and AST equality to SKILL.md's program, and they run under the AST allowlist and `MAX_BITS` cap with a 10 s timeout.
  **Location:** `test/skills/arithmetic-eval/mode1-equiv.py:96, 134-147, 169-185`
  **Evidence:** read-static
  **Verified:** read the whole file and the SKILL.md Mode 1 block.
  **Not verified:** memory use without the wrapper's `ulimit -v` (the checker omits it; pre-existing, not changed by b22a026).

## Primitive sweep

Primitive: process exec / jq program construction

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `mode1-equiv.py:137` `subprocess.run(["python3","-c",program], input=expr)` | S4 program, S2 expr | wrapper regex + AST equality + evaluator allowlist + timeout | cleared: argv list, no shell; expression goes to stdin of the trusted evaluator |
| `mode1-equiv.py:96` self-test | S3 constant | n/a | cleared |
| `eval-helpers.bash:541` `python3 "$checker" …` | S5 skill name, S2 commands via a JSON file | argv, `transcript_verdict` first | cleared (the commands are data in a file, not argv) |
| `generate-reports.bash:288` jq program `t::$verdict_def` | S3 | two constant values | cleared |
| `eval-helpers.bash:379` `transcript_jq` filter | S3 filters; `--arg n` S5 | `--arg` binding | cleared |
| `generate-reports.bash:238-242` `claude …` | S5/env | settled overrides (C16, `--tools`, deny-record refuses `CLAUDE_FLAGS`) | not re-analyzed: unchanged by b22a026, settled |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `__text` marker is in-band; `init`, `denials` and the result reads consume events the census and validation skip (tripwire satisfied, init canary shadowed, error result overridden) | Medium | B1, B3 | `transcript.jq:45-46,56-57,70,111,114-115`; `generate-reports.bash:252-261` | High (mechanism) / Low likelihood |
| 2 | Only the first of many real init events is checked; `permissionMode` never checked | Low | B3 | `transcript.jq:111,149-150` | High |

## Overall Assessment

The census fixes the class it names: calls are found wherever they sit, and the verdict/sentinel channel held against every forgery probe. What is left is one root cause, now seen through four readers. The module validates a *subset* of events, because the in-band `__text` key exempts an event, while the census (Claim 24), `init`, `denials` and the generator's result reads each draw on a larger or different set. All of these require a CLI shape the fail-safe story says would void runs, so they refute that stated property rather than describe a likely incident. The fix is architectural but small: remove the in-band marker, so there is only one event set, and vary keys in the property test. Finding 2 is a canary-coverage gap, not a breach path. No findings within the code paths read beyond these; endorsement claims pending execution verification.

## Goal-Alignment Note

The user's goal is a terminal review of b22a026 before a local merge, with the full remaining inventory. This review answers the three focus questions:
- **Other opt-outs:** yes. The same `__text` root reaches `init`, `denials` and the result reads, and they need a single root fix, not a census-only patch.
- **Sentinel spoofing:** no, executed.
- **Later init:** yes, but only the canary is weakened, and later inits are a real CLI shape.

Neither finding is an execution breach under the residual already accepted (accidental, not concealed). Both violate the module's own stated fail-safe property ("A new CLI shape voids runs"). That places the merge decision on whether that stated property must be true at merge (fix Finding 1 first) or can be recorded as a known gap alongside Claims 24 and 25b.
