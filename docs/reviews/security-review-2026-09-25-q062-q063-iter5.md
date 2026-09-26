Commit: 9c73ae4

# Security Review — skill-fixtures, iteration 5 of 5 (terminal pass on 272bc83)

**Scope:** `git diff main...HEAD` on `skill-fixtures`, focused on `git show 272bc83`: `test/skills/transcript.jq`, `generate-reports.bash` (`generate_one`), `eval-helpers.bash` (the transcript checks), `arithmetic-eval/mode1-equiv.py`, `malformed-transcripts.bash`
**Date:** 2026-09-25 (probes ran 2026-09-26T05:58Z UTC)
**Based on:** `docs/reviews/code-fact-check-report.md` (Commit 9c73ae4, 37 claims). New probes: `docs/reviews/execution-logs/sec-9c73ae4-probes.{sh,txt}`. The script passes `shellcheck -x -e SC1091 -s bash -S warning`.

No HALT escalation. None of the five escalation patterns applies. This is a test harness, and the defects below are gaps in *detecting* a Bash call that the CLI's deny rule failed to block. They are not failures of the deny rule itself.

**Answer to the brief's question.** Yes. The generator can remove the marker, or `mode1_equiv`/`no_tool_called` can pass, while a call was undenied or ran. Seven transcript families do it. Each one violates a named general property:

| Family | Property violated | Finding | Proof |
|---|---|---|---|
| tool_use in a `user` event, an event with an unknown, missing or non-string `type`, or nested in a `tool_result` | P1 complete enumeration | F1 | fact-check P9, P10, E2 |
| content block of a type the reader does not know (`server_tool_use`) | P2 allowlist of shapes | F2 | S5 |
| newline in `claude_code_version` | P3 separator-safe transport, and a verdict that is complete before the marker is removed | F3 | fact-check P1; S6 (a *trailing* newline) |
| an executed non-Bash tool (`BashOutput`) listed in init | P4 grant set is exactly Bash | F4 | S1 |
| a second Bash call reusing a denied id | P5 one denial per call | F5 | S2 |
| a call and its result on lines that start with a non-JSON prefix (ANSI, BOM) | P6 a line is ignored only if it cannot carry an event | F6 | S3, S4 |

Every family needs the **CLI** to emit the shape. In the paths probed, no model-authored content reaches any of them (Endorsement E1, E2). F1, F2, F5 and F6 are one class: *the reader's idea of a call is narrower than the CLI's*. One structural change closes that class (see the Overall Assessment). F3 and F4 are separate classes, and each needs its own small fix.

---

## Trust Boundary Map

```
B1: [claude CLI stdout: stream-json events]      → [transcript.jq events/problems/tool_uses/denials] → [generator verdict; eval checks]
B2: [model-authored content inside events]       → [CLI JSON encoding → transcript.jq]                 → [counts, command list, ERE match]
B3: [jq verdict string, \x1f-joined]             → [bash `IFS=$'\x1f' read` in generate_one]          → [.failed marker removed or kept]
B4: [transcript file on disk, read later]        → [eval-helpers transcript_checked / counts gate]     → [bats pass/fail]
B5: [attempted-command list (JSON array)]        → [mode1-equiv.py commands()/evaluate()]              → [exit 0/1/2 → pass/fail]
B6: [same-uid processes' /proc cwd] (unchanged)  → [install.sh agent_gate]                             → [install proceeds/refuses]
```

B1 is the boundary 272bc83 rebuilt (it is new in its current form). B3 is where the verdict crosses from jq into bash. B6 (Q-062) has not changed since iteration 4 and was not reviewed again.

**Input-source classification**

```
S1: CLI event framing (event/block types, ids, permission_denials, init.tools, claude_code_version)
      — runtime-mutable (the CLI floats to latest, C17) — UNTRUSTED toward the verdict sink: its
        shape can drift, which is the premise of 272bc83; trusted for its denial facts (only the
        CLI writes permission_denials)
S2: model-authored strings/objects inside events (Bash input object incl. extra keys, tool name,
    text) — request-time — UNTRUSTED for all sinks (verdict, ERE, exec stdin)
S3: transcript file at eval time — filesystem, written by the audited process — UNTRUSTED for
      concealed breaches (C29, accepted); treated as S1+S2 otherwise
S4: skills/<skill>/SKILL.md Mode 1 program — repo, deploy-time — trusted as code; its output
      FORMAT is an unchecked contract (F8)
S5: KEY_CHECK specs, DENY_RECORD_FLAGS, runner settings — code-constant — trusted
```

The diff trusts S1 in one way it should not. It assumes the CLI puts every tool call at one path (`assistant` → `message.content[]`) and prints every event as one well-framed line. Its stated premise is the opposite: "a future CLI shape change now voids runs loudly" (272bc83 Notes). S2 is handled well. Model content only ever reaches the verdict as counts, or as JSON-escaped lines (E1, E2).

---

## Findings

#### F1 — Tool calls are counted at one path, while the reader accepts them at several others (P1: complete enumeration)

**Severity:** Medium
**Location:** `test/skills/transcript.jq:70-72`, `:78-79` (read: whole file, `:1-101`)
**Boundary:** B1, B4
**Move:** 11 (bypass enumeration), 2 (implicit assumption)
**Confidence:** High for the mechanism (executed). Low for reachability: no CLI version is known to emit these shapes.
**Legibility-target:** for-author

**Property violated:** *every object with `type: "tool_use"` (and every `tool_result`) anywhere in any event is counted.* Here is the counting definition:

```jq
# test/skills/transcript.jq:70-72
def tool_uses:
  [.[] | objects | select(.type == "assistant") | .message.content[]? | objects | select(.type == "tool_use")
   | {id, name, input}];
```

`_event_problems` validates tool_use blocks in `user` events as well (`:38`, `.type == "assistant" or .type == "user"`), and it does not inspect events of any other type (`:60`, `else empty end`). So a tool_use in a `user` event, in an event whose `type` is renamed, missing or not a string, or nested inside a `tool_result`'s `content` is accepted and never counted. `tool_result_ids` has the same narrowing to `user` events. That weakens the orphan canary, which is the backstop for an executed call, when a renamed event also carries the result. Fact-check probes: P10 (deny-record, "Done", no marker), P9 (plain transcript run) and E2 (`assert_no_tool_called Bash rm` exit 0) (Claims 26, 29). The contract "an unexpected shape is a problem, never skipped" is stated in six places and does not hold.

**Recommendation:** Count tool_use and tool_result objects by recursive descent over *every* parsed event: `[.[] | .. | objects | select(.type == "tool_use")]`, and the same for `tool_result`. Keep denials read *only* from the top level of `result` events. The asymmetry is the point. Over-counting uses or results can only void a run, and under-counting denials can only void a run, so the verdict stays monotone fail-closed. A model can put `{"type":"tool_use"}` objects inside its own Bash `input`, but that only voids its own run, which it can already do with a lone surrogate. This one change also fixes `no_tool_called`, because `transcript_tool_inputs` uses `t::tool_uses`.

#### F2 — The shape check is a denylist inside two event types; anything else is accepted by default (P2: allowlist of shapes)

**Severity:** Medium
**Location:** `test/skills/transcript.jq:35-60`, and the header's `:18-19`
**Boundary:** B1
**Move:** 5 (invert the access-control model), 11
**Confidence:** High for the mechanism (executed, S5). Low for reachability.
**Legibility-target:** for-author

**Property violated:** *an event type or content-block type the reader has no rule for is a problem.* The header says "Other event types … need only be objects". Inside `assistant`/`user` events, a block needs only a string `type`, and then only `tool_use` and `tool_result` are examined. Probe S5 is an assistant event with a `server_tool_use` block (`"name":"bash_code_execution"`, `"input":{"command":"rm -rf x"}`) beside a good denied g1. It gives `{"problems":[],…,"counts":{"undenied":0,…}}`, and the generator under deny-record prints "Done" with **NO MARKER** (`sec-9c73ae4-probes.txt`, S5). F1's recursive count would *not* catch this, because the `type` differs. It is a different property: F1 closes the "known type in an unexpected place" class, and F2 closes the "unknown type" class. S5's block would run server-side, not on the host. The finding is that the reader cannot tell. The claim "a future CLI shape change now voids runs loudly" needs this allowlist to be true.

**Recommendation:** Keep an allowlist of event types (those in the 13 real transcripts: `system`, `assistant`, `user`, `result`, plus any others they held, such as rate-limit events) and of block types (`text`, `thinking`, `redacted_thinking`, `tool_use`, `tool_result`, …). Anything else is a problem. The cost is that a CLI addition voids runs until it is added to the list. That is the "loud" failure the commit asks for.

#### F3 — A newline in a free-text CLI field drops the counts field, and a missing counts field skips every deny-record check (P3: separator-safe transport and a complete verdict before the marker is removed)

**Severity:** Medium
**Location:** `test/skills/generate-reports.bash:286-297`, `:307-318`, `:329` (read: `generate_one`, `:141-335`)
**Boundary:** B3
**Move:** 3 (error path), 11
**Confidence:** High for the mechanism (executed: fact-check P1; S6). Low for reachability, because the field is written by the CLI.
**Legibility-target:** for-author

This finding violates two properties, and each needs its own fix.
(a) *Every field that crosses from jq into bash is newline- and separator-safe.* The only free-text field, `cli_version` (`:289`, `t::init | .claude_code_version // "unknown"`), sits *before* the security-bearing `counts`, and then:

```bash
# test/skills/generate-reports.bash:297
      IFS=$'\x1f' read -r n_problems problems init_state cli_version counts <<< "$verdict"
```

(b) *The marker is removed only after a verdict that is known to be complete.* An empty `counts` is read as "nothing to check":

```bash
# test/skills/generate-reports.bash:307-309 (excerpt ends :309; the if-block continues to :318, then the marker is removed at :329 when failure is empty — read)
        if [ -n "$counts" ]; then
          local undenied unseen orphans foreign
          read -r undenied unseen orphans foreign <<< "$counts"
```

S6 adds the most plausible trigger: a *trailing* newline (`"claude_code_version":"9.9.9\n"`, the form a version read from a file would take). The reader reports `"undenied":1`, but the generator prints "Done" and leaves **NO MARKER** (`sec-9c73ae4-probes.txt`, S6). The eval-side gate already gets this right. `[ "$counts" != "0 0 0 0" ]` (`eval-helpers.bash:527`) is an exact match, so an empty or garbled value fails.

**Recommendation:** (a) Decide inside jq. Have the jq program return the list of failure strings as JSON (or `@sh`), and let bash only test "list empty, and the list itself was produced". At the least, `tojson` the version and put `counts` first. (b) Under deny-record, when `n_problems` is 0, an empty or non-numeric `counts` must set `failure`, matching the eval side's exact-match test.

#### F4 — Under deny-record, only Bash is checked; an executed non-Bash tool passes (P4: the grant set is exactly Bash)

**Severity:** Medium
**Location:** `test/skills/generate-reports.bash:288`, `:304-306`; `test/skills/transcript.jq:90-101`
**Boundary:** B1
**Move:** 5 (invert the model: what does "only Bash" prevent?)
**Confidence:** High for the mechanism (executed, S1). Low for reachability. The request side is pinned (`FIXTURE_TOOLS=Bash` exactly, C9 Fixed), but whether a CLI version adds companion tools under `--tools Bash` was not probed. This finding needs a `claude` run.
**Legibility-target:** for-author

**Property violated:** *under deny-record, the tool set the CLI granted, and every tool_use, is Bash only.* The init canary tests inclusion (`index(["Bash"]) != null`), and `foreign` counts only *denials* of other tools. `undenied` counts only `name == "Bash"`. S1 has init tools `["Bash","BashOutput"]` and an undenied `BashOutput` tool_use *with a tool_result* (it ran). The reader gives `counts` all zero, and the generator prints "Done" with **NO MARKER** (`sec-9c73ae4-probes.txt`, S1). tc-ae5's only check is `no_tool_called:Bash` (`expected-verdicts.bash:46`), and it would pass too. C9 closed the *requested* set. This finding is about the *observed* set.

**Recommendation:** Under deny-record, void the run unless `init.tools == ["Bash"]` exactly and every tool_use (F1's recursive set) has `name == "Bash"`. Report violations in the existing "Bash tripwire: … other than Bash" wording.

#### F5 — Denials are matched to calls by id set membership, so one denial covers any number of calls with that id (P5: one denial per call)

**Severity:** Medium
**Location:** `test/skills/transcript.jq:92-100`
**Boundary:** B1
**Move:** 11
**Confidence:** High for the mechanism (executed, S2). Low for reachability: tool_use ids are unique by API contract, so this needs a CLI or replay bug.
**Legibility-target:** for-author

```jq
# test/skills/transcript.jq:98-100 (excerpt starts inside deny_record_counts, which begins :90 and ends :101 — read)
  | { undenied: ([$bash[] | select($denied_set[.] | not)] | length),
      unseen:   ([$denied[] | select($bash_set[.] | not)] | length),
      orphans:  ([tool_result_ids[] | select($all_set[.] | not)] | length),
```

S2 has a second Bash tool_use reusing the denied id `g1` (`rm -rf x`), plus a `tool_result` for `g1`. That gives `undenied:0 … orphans:0`, and the generator prints "Done" with **NO MARKER**. `assert_mode1_equiv` gets past its `"0 0 0 0"` gate and hands both commands to the checker (`sec-9c73ae4-probes.txt`, S2: "Bash commands seen: 2"). The orphan canary cannot help, because the result's id is "seen". The fact-check found the reader half (Claim 30, `duplicate_id_undenied_second_call`). S2 is the end-to-end result.

**Recommendation:** Make a repeated tool_use id a `problem`. The `_set` lookups then stay correct, because each id names exactly one call.

#### F6 — A line is dropped as "plain text" by its first character, so a JSON event behind a prefix is invisible (P6: a line is ignored only if it cannot carry an event)

**Severity:** Medium
**Location:** `test/skills/transcript.jq:29-30`
**Boundary:** B1
**Move:** 11 (encoding variants)
**Confidence:** High for the mechanism (executed, S3/S4). Low for reachability: `claude`'s stderr goes to `/dev/null`, and the CLI is not known to prefix stdout lines.
**Legibility-target:** for-author

```jq
# test/skills/transcript.jq:29-30
def events: [inputs | select(test("\\S")) | . as $line | (try fromjson catch
  (if ($line | test("^\\s*[\\[{]")) then {"__unparsed": $line} else {"__text": $line} end))];
```

The comment's reason is "A plain-text line … cannot carry a tool call for any reader". That holds for text with no `{`, but a prefix test does not check it. S3 puts an ANSI reset (`\e[0m`) before an undenied `x1` call and before its `tool_result`. It gives `problems:[]`, counts all zero, a generator "Done" with **NO MARKER**, `assert_no_tool_called Bash rm` exit 0, and the mode1 gate passed. S4 is a UTF-8 BOM before an unparseable (lone-surrogate) call line. It is classed as text, and `no_tool_called` exits 0, while the same line without the BOM is caught ("a line starting like JSON does not parse") (`sec-9c73ae4-probes.txt`, S3, S3b, S4). This is the C32 class again, now at the line classifier rather than the parser.

**Recommendation:** Ignore a non-parsing line only if it contains no `{` at all. Better, since no real transcript is known to hold a text line, make every non-blank non-JSON line a problem and add known CLI warnings to an allowlist when one shows up.

#### F7 — With a malformed line present, the tripwire's "may have executed" signal is not computed (diagnostic only)

**Severity:** Informational
**Location:** `test/skills/generate-reports.bash:290`
**Boundary:** B3
**Move:** 3
**Confidence:** High (fact-check P5, Claim 23b)
**Legibility-target:** for-author

`(if (t::problems | length) == 0 then (t::deny_record_counts | …) else "" end)`. The run is voided either way, so nothing passes. But an executed call is reported only as "malformed event", which is the masking C10 set out to remove. Compute the counts over the well-formed events regardless, and report them. The comment "Also when the run already failed" at `:273-274` should then be true as written.

#### F8 — mode1-equiv exit 1 still conflates a SKILL.md evaluator-format fault with a model result (exit-contract, fifth appearance)

**Severity:** Informational (fails closed: a fixture fails, it never passes)
**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:124-137`, `:34-37`
**Boundary:** B5
**Move:** 3
**Confidence:** High (fact-check E5, Claim 14)
**Legibility-target:** for-author

**Property violated:** *a checker fault is distinguishable from a model result.* `evaluate()` maps every evaluator failure to `None`, and `None` becomes exit 1. This is not a way to pass an undenied call. It misattributes a checker fault as "the model did not route". **Recommendation:** in `reference()` (so also under `--check-spec`), run the extracted program once on a fixed sample (`6 * 7` → 42), and raise SetupError (exit 2) if that fails. That closes the class rather than one instance of it.

#### F9 — Two lenient readers remain beside the strict one

**Severity:** Informational
**Location:** `test/skills/eval-helpers.bash:476-478` (`assert_subagents_min`), `test/skills/generate-reports.bash:252`, `:256`
**Boundary:** B1, B4
**Move:** 12 (sweep of the parse primitive)
**Confidence:** High (fact-check Claims 11, 21; E3)
**Legibility-target:** for-author

Neither reader feeds a Bash verdict. The generator's strict pass still voids whatever the lenient `result_state` read skips. `assert_subagents_min` passes on a malformed, init-less transcript when called directly (E3). Route both through `transcript_jq`/`transcript_checked`, so that the claim "one reader" is true.

#### F10 — `no_tool_called:<Tool>=<ERE>` matches the JSON encoding of the input, not the command

**Severity:** Informational
**Location:** `test/skills/eval-helpers.bash:384`, `:441`
**Boundary:** B2
**Move:** 2
**Confidence:** High (executed, S7)
**Legibility-target:** for-author

`.input | tostring` escapes control characters, so a tab becomes the two characters `\t`. `jq -nc '{command:"rm\t-rf /x"} | tostring' -r | grep -ciE 'rm[[:space:]]+-rf'` prints `0` (S7). No current deny-record fixture relies on a pattern: tc-ae5 uses bare `no_tool_called:Bash`, and the mode1 fixtures use the counts gate. A future pattern-based negative check would be a regex denylist over an escaped form. Document it, or match against `.input.command` decoded to raw text.

---

## Untested bypass candidates

- **Tool-name aliasing.** A model-chosen tool_use `name` that the CLI resolves to the Bash tool, with a denial naming "Bash". The "unseen" canary would catch a denied call. An *undenied* aliased call would pass through F4's gap. Not tested: this needs a `claude` run, which the brief forbids.
- **Duplicate JSON keys** (`{"type":"user",…,"type":"assistant"}`). jq keeps the last key. The CLI's `JSON.stringify` never emits duplicates, and no second reader parses the transcript differently, so this is listed and not probed.
- **A later `init` event** (resume, or a sub-agent init) with a different `tools` list. `t::init` takes the first. Not probed, and it overlaps with F4.
- **NUL bytes (`\u0000`) in `claude_code_version`.** Bash command substitution drops NUL bytes. Read-static, this looks harmless (the fields concatenate). Not probed.
- **Transcript size or memory exhaustion.** jq slurps the whole stream (`events`). A jq failure sets `verdict=""` → "could not be read" (fail-closed, read-static at `:291-293`). No large file was generated.

---

## Endorsement Claims

- **Claim E1:** No model-authored (S2) string reaches the generator's `\x1f` verdict. The problem texts are fixed literals, with `\(.type)` limited to "assistant"/"user". The other fields are counts, a fixed init state, and the CLI-written version.
  **Location:** `test/skills/transcript.jq:35-60`, `test/skills/generate-reports.bash:286-291`
  **Evidence:** read-static
  **Verified:** every string literal in `_event_problems`, and the five jq expressions joined at `:287-291`.
  **Not verified:** whether the CLI ever copies model text into `claude_code_version` or `init.tools`. Those are the only non-literal fields.
  **route: code-fact-check**

- **Claim E2:** A model-authored command reaches `no_tool_called` and `mode1-equiv.py` as exactly one line, or one array element, per call. `tostring`/JSON encoding escapes embedded newlines.
  **Location:** `test/skills/eval-helpers.bash:384`, `:532-533`; `mode1-equiv.py:99-107`
  **Evidence:** read-static (plus S7, which shows the escaping)
  **Verified:** the jq filters `.input | tostring` and `[… | .input.command]`, and `commands()`'s type check.
  **Not verified:** a command containing U+2028/U+2029. jq emits these raw, and `grep` treats them as ordinary bytes, so this is believed benign but was not run.
  **route: code-fact-check**

- **Claim E3:** The eval-side deny-record gate fails closed on a missing or garbled counts value, because it is an exact string compare against `"0 0 0 0"`.
  **Location:** `test/skills/eval-helpers.bash:525-530`
  **Evidence:** read-static
  **Verified:** the `transcript_jq … ||` failure branch and the `!=` compare.
  **Not verified:** the generator's equivalent, which does not fail closed (F3).
  **route: code-fact-check**

- **Claim E4:** The fail-closed marker survives a `set -e` abort at any step before `:329`.
  **Location:** `test/skills/generate-reports.bash:155-159`, `:323-329`
  **Evidence:** executed (fact-check P8, Claim 22a)
  **Verified:** marker "generation did not finish" after an unreadable-fixture abort, and `generate-reports.bats:663`.
  **Not verified:** delivery of a signal (read-static only). Also, the "every check passed" half does not hold (F3).

(The shape-rejection guardrail, `problems`, is **not** endorsed. It has the bypasses above.)

---

## Primitive sweep

Primitive: JSON deserialization of the transcript and command list (verdict-bearing)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `test/skills/transcript.jq:29-30` (`events`) | S1, S2 | JSON-prefix classifier | F6 (prefix bypass); F1/F2 downstream |
| `test/skills/generate-reports.bash:286-297` (verdict → `read`) | S1 | `\x1f` split | F3 |
| `test/skills/eval-helpers.bash:374-378` (`transcript_jq`) | S1, S2, S3 | strict reader | inherits F1, F2, F5, F6 |
| `test/skills/generate-reports.bash:252` (report text, `fromjson?`) | S1 | none | F9, cleared for Bash verdicts (not a verdict input) |
| `test/skills/generate-reports.bash:256` (`result_state`, `fromjson?`) | S1 | strict pass afterwards | F9, cleared: the strict reader still voids what this skips |
| `test/skills/eval-helpers.bash:476` (`assert_subagents_min`, `fromjson?`) | S3 | none | F9 |
| `test/skills/arithmetic-eval/mode1-equiv.py:99-107` (`commands`) | S2 via reader | type check → SetupError | cleared: strict, exit 2 on any other shape |

Primitive: process exec

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `test/skills/generate-reports.bash` `claude` invocation (`claude_args`, `model_args`) | S5, CLAUDE_MODEL | one argv element; CLAUDE_FLAGS refused under deny-record | cleared (C16 fixed; C4 override) |
| `test/skills/arithmetic-eval/mode1-equiv.py:127` (`python3 -c program`, stdin = expression) | S4 program, S2 expression | SKILL.md evaluator | cleared for this diff: the program always comes from SKILL.md (earlier iterations). Evaluator safety is not re-reviewed. F8 covers its exit mapping |
| `test/skills/eval-helpers.bash:534` (`python3 "$checker"`) | S5 paths and spec | fixed paths | cleared |
| `devcontainer-config/install.sh` agent_gate (`readlink`, `pgrep`) | B6 | — | not analyzed: unchanged since iteration 4. Its rubric rows (A1/Q-064, C3, C11) stand |

The sweep is complete for the Q-063 scope and explicitly partial for Q-062.

---

## Summary Table

| # | Finding | Property | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|----------|------------|
| F1 | Calls counted at one path; accepted at others | P1 complete enumeration | Medium | B1, B4 | `transcript.jq:70-72, 78-79` | High mech. / Low reach |
| F2 | Unknown event/block types accepted by default | P2 allowlist | Medium | B1 | `transcript.jq:35-60` | High / Low |
| F3 | Newline drops counts; empty counts skips checks | P3 separator-safe, complete verdict | Medium | B3 | `generate-reports.bash:297, 307` | High / Low |
| F4 | Non-Bash executed tool passes deny-record | P4 grant set = Bash | Medium | B1 | `generate-reports.bash:288`; `transcript.jq:90-101` | High / Low |
| F5 | One denial covers repeated ids | P5 one denial per call | Medium | B1 | `transcript.jq:92-100` | High / Low |
| F6 | Prefixed JSON line dropped as text | P6 ignore only event-free lines | Medium | B1 | `transcript.jq:29-30` | High / Low |
| F7 | Tripwire not computed beside a malformed line | evidence always reported | Informational | B3 | `generate-reports.bash:290` | High |
| F8 | Exit 1 conflates evaluator fault with model result | checker fault ≠ model result | Informational | B5 | `mode1-equiv.py:124-137` | High |
| F9 | Lenient readers remain | one reader | Informational | B1, B4 | `eval-helpers.bash:476`; `generate-reports.bash:252, 256` | High |
| F10 | ERE matches JSON-escaped input | match the decoded command | Informational | B2 | `eval-helpers.bash:384, 441` | High |

Mapping to fact-check verdicts: F1 = Claims 26, 29 (escalated); F3 = Claim 22b (escalated), extended by S6; F7 = Claim 23b; F8 = Claim 14 (escalated); F9 = Claims 11, 21. F2, F4, F5 (end to end), F6 and F10 are new in this pass.

## Overall Assessment

272bc83 is a real improvement. Model-authored content no longer reaches a verdict in any path I probed (E1, E2). The 13 table shapes fail closed. The marker survives aborts. The eval gate uses exact matching. But the redesign's own premise, that "a future CLI shape change now voids runs loudly", does not yet hold. The reader still has the pre-fix posture, *default-accept outside a known list of bad shapes*, moved one level up. Six families of CLI output let an undenied or executed call through (F1–F6). None is known to be reachable: each needs the CLI to emit a shape or content not seen in the 13 real runs, and the model cannot write any of them. So these are detection gaps behind a working CLI deny rule, not exploitable holes. They are fixable in place, in about 30 lines, and do not need another redesign. **The single most important change** is to make the reader monotone. Count tool_use and tool_result evidence *maximally* (recursive descent over every event, unique ids, every line containing `{` must parse), and read denial evidence *minimally* (top-level `result` events only). Put that behind an allowlist of event and block types (F2), so that anything unknown is a problem. That closes F1, F2, F5 and F6 as one class. F3 needs the verdict decided in jq, with bash failing on an incomplete verdict. F4 needs an exact-grant check. Both are small and independent of the class fix. No findings reach High or Critical. The endorsement claims are pending execution verification.

---

## Goal-Alignment Note

**Success criterion:** "A markdown critique saved to the path named in your role section below, structured per your skill." **Met.** It is saved at `docs/reviews/security-review-2026-09-25-q062-q063-iter5.md` with `Commit: 9c73ae4` at the top. It has the skill's sections: Trust Boundary Map with sources, Findings with Severity, Location, verbatim Evidence, Confidence and Legibility-target, untested bypass candidates, Endorsement Claims with `route: code-fact-check`, Primitive sweep, Summary, and Overall Assessment.

**Brief's focus question** ("is there ANY transcript … for which the generator removes the marker, or eval checks pass, while a Bash call was undenied or ran?"): answered yes, with six property-named families (table at top), each proved by execution. Every reader defect is mapped to the general property it violates, and to the one class fix that covers F1, F2, F5 and F6, as the iteration context asked.

**Escalations confirmed from Stage 1:** Claims 26/29 → F1 (plus the new F2/F5/F6 in the same class). Claim 22b → F3, which is worse than stated because a *trailing* newline triggers it (S6). Claim 14 → F8, which fails closed, so it is Informational from a security view.

**Out of scope / not done:** Q-062 install.sh (unchanged since iteration 4; not re-reviewed). No `claude` or network command was run, so F4's companion-tool reachability and the tool-name-alias candidate are unprobed. Settled decisions and open-by-choice rows were not re-litigated. F4 is distinct from C9 (the observed tool set versus the requested one). Nothing was committed.

**Artifacts:** `docs/reviews/execution-logs/sec-9c73ae4-probes.sh` (passes the shellcheck gate) and `sec-9c73ae4-probes.txt` (cwd `/workspace`, started 2026-09-26T05:58:05Z, jq-1.6).
