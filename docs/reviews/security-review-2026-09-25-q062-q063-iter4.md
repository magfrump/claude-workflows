Commit: 5bdee46

# Security Review — skill-fixtures (Q-062 [2] / Q-063 [1]), iteration 4 (user-authorized terminal pass after the cap)

**Scope:** `git diff main...HEAD` on `skill-fixtures` (HEAD 5bdee46), focused on fix commit 37c5ea9 and regressions from it. Four areas: the one-pass deny-record jq (`generate-reports.bash:257-302`), the init requirement in `tool_inputs_checked` (`eval-helpers.bash:376-401`), the tripwire copy in mode1-equiv (`mode1-equiv.py:159-207`, the Claim 13 shapes), and the rc-4 path in install.sh (`install.sh:1157-1211`).
**Date:** 2026-09-25
**Based on:** `docs/reviews/code-fact-check-report.md` (Commit 5bdee46; I used Claims 1-3, 9b, 13, 14, 16a/b, 20a-c as the behavioral foundation and did not re-verify them), the rubric `docs/reviews/code-review-rubric-2026-09-25-skill-fixtures-q062-q063.md`, and `docs/reviews/security-review-2026-09-25-q062-q063-iter3.md`.
**Probe logs (new, this review):** `docs/reviews/execution-logs/sec-5bdee46-iter4-probes.{sh,txt}` and `…-probes2.{sh,txt}`. They ran with jq-1.6 and python3 3.11, ended 2026-09-26T04:46:59Z, cwd the session scratchpad. They use the generator's jq program exactly as the fact-check extracted it (`cfc-5bdee46-gen.jq`) and source `eval-helpers.bash` and `mode1-equiv.py` as committed. No `claude` and no network.

Settled items are not re-filed: C4, C5, C9, C6, trap RETURN, `--tools` variadic, RUNNER_ALLOWED_TOOLS naming, A1/Q-064, A20, C24, C30, and C3/C4/C6/C8/C13/C14/C15. I did not re-report rows marked Fixed. Where a Fixed row left a residual that the brief asked about (A16's "both shapes change"), I report the residual and say that the fix itself is correct.

---

## Trust Boundary Map

```
B1: [operator env: CLAUDE_FLAGS, CLAUDE_MODEL]          → [generate-reports.bash refusal :127 + argv build]     → [claude argv (permission flags)]
B2: [model under test]                                   → [claude CLI: --tools Bash + DENY_RECORD_FLAGS]         → [host shell (Bash execution)]
B3: [claude stream-json (CLI-shaped events holding model-chosen tool inputs)] → [generator one-pass jq :275-287 → .failed] → [run recorded clean/void]
B4: [transcript.jsonl]                                   → [eval-helpers transcript_tool_inputs / tool_inputs_checked :369-401; mode1-equiv.py :98-207] → [fixture pass/fail]
B5: [model-chosen Mode 1 expression]                     → [mode1-equiv evaluate() with SKILL.md's program :143-156] → [python3 subprocess on the test host]
B6: [other same-uid processes / host process table]      → [install.sh procs_in_checkout :1157-1173 + gate case :1192-1211] → [agent_gate allow/refuse]
```

**Input-source classification**

```
S1: CLAUDE_FLAGS / CLAUDE_MODEL        — deploy-time (operator shell) — trusted for intent; UNTRUSTED as argv (C16 history)
S2: CLI event shape (stream-json)      — runtime-mutable (the CLI floats to latest, C17) — UNTRUSTED as a stable schema
                                         for every fail-closed parser (B3, B4)
S3: model-chosen tool input (command text, and any extra keys)
                                       — request-time (model output) — UNTRUSTED for exec (B2) and evaluator (B5) sinks,
                                         and UNTRUSTED toward the transcript *parsers* (B3, B4): its bytes sit inside
                                         the event line that every jq reader must parse
S4: SKILL.md Mode 1 block, expected-verdicts specs — code-constant — trusted (all sinks)
S5: /proc entries (cwd, cmdline)       — runtime (other same-uid processes) — UNTRUSTED for content; trusted for
                                         availability only inside install.sh's own PID namespace (037:86)
S6: PATH-resolved tools in install.sh (readlink, pgrep, awk) — deploy-time ($HOME-writable) — same trust as any
                                         file in $HOME; 037 accepts "equivalent persistence through any other file in $HOME"
```

The change from iteration 3 is in S3's row. The model's own tool input is inside the line that the tripwire parses. So the tripwire's `fromjson?` (skip what does not parse) is an untrusted-input decision, not only a CLI-drift decision. F3 tests that. F1 and F2 test S2 against B3/B4 after A16's parser canary. B6 is unchanged in shape, and 37c5ea9 only relabelled its rc-4 arm. I found no way for a process to force that arm (see the bypass tables).

---

## Findings

#### F1: The canary checks the generator's parser, and `no_tool_called` uses a different one. A stray non-object content block hides a denied Bash call from tc-ae5 under jq 1.6

**Severity:** Low. The floor rule does not bind: no *executed* call goes unrecorded. The generator still sees the call, so the tripwire voids an undenied one (probe P1, `gen=[0 0 …]` only because the call was denied). The violated property is grading integrity of the only negative fixture. It is not concealment of an execution.
**Location:** `test/skills/eval-helpers.bash:369-374` (`transcript_tool_inputs`), `:381-383` (the comment); `test/skills/generate-reports.bash:280`
**Boundary:** B3, B4 (source S2)
**Move:** #11 (bypass enumeration), #2 (assumed sanitization: the comment assumes the canary protects this reader)
**Confidence:** High on the mechanism (executed). Low on the environment: it needs a CLI that emits a non-object element in `message.content`.
**Legibility-target:** for-author

The two parsers differ by one filter. The generator drops non-objects before `select`:

```bash
# test/skills/generate-reports.bash:280-281 (inside the jq program :275-287; generate_one ends :314 — read)
        | [$ev[] | select(.type == "assistant") | .message.content[]? | objects
           | select(.type == "tool_use" and .name == "Bash") | .id] as $calls
```

eval-helpers does not:

```bash
# test/skills/eval-helpers.bash:369-374 (complete unit)
transcript_tool_inputs() {
  # -R + fromjson?: skip non-JSON lines instead of aborting on the first one.
  jq -rR --arg n "$2" \
    'fromjson? | select(.type == "assistant") | .message.content[]?
     | select(.type == "tool_use" and .name == $n) | .input | tostring' "$1"
}
```

On jq 1.6, `select(.type …)` on a string raises an error. The enclosing `fromjson?` swallows it, a known jq 1.6 try-scoping behavior, and that ends the line's iteration. So every later block in that message is lost, and jq still exits 0. Probe log `sec-5bdee46-iter4-probes.txt`:

```text
P1 ["stray", Bash t1], t1 denied                           gen=[0 0 bash 9.9] no_tool_called_rc=0 mode1_rc=1
P1b [7, Bash t1], t1 denied                                gen=[0 0 bash 9.9] no_tool_called_rc=0 mode1_rc=1
P1c [Bash t1, "stray"] (order reversed)                    gen=[0 0 bash 9.9] no_tool_called_rc=1 mode1_rc=1
```

The generator sees `t1` and matches it to its denial. The canary is satisfied, so no `.failed` is written. `assert_no_tool_called Bash`, which is tc-ae5's whole check (`expected-verdicts.bash:46`), then returns 0 with a Bash call present. The comment at `:381-383` tells the reader that this case is covered:

```bash
# test/skills/eval-helpers.bash:381-383 (comment above tool_inputs_checked, :384-401 — read)
# misspelled name such as "bash"). It does not detect a changed event shape
# that hides tool_use blocks: generate-reports.bash's parser canary does, for
# deny-record runs, and eval_fixture fails any run with a .failed marker.
```

The canary proves only that the *generator's* parser saw every denied call. It says nothing about a reader that parses differently. (Not executed: jq ≥1.7 scopes `?` more narrowly, so the same line probably makes jq exit 5 there, which is "Could not read tool calls", fail-closed. This behavior depends on the jq version.)

**Recommendation:** Add `| objects` after `.message.content[]?` in `transcript_tool_inputs`, so both readers use the same path. Better, define that path once, as a jq `def` the two files share, so the canary validates the path the graders actually use. Then narrow the comment to "the parser canary validates the tool_use path shared with transcript_tool_inputs".

---

#### F2: Residual of A16. An executed Bash call is still unrecorded when the deny rule fails for every call in a run *and* the tool_use path moves. The result stream has evidence that would catch this, and no check reads it

**Severity:** Medium (floor rule). The mechanism is concrete: two CLI regressions of the kind C17 already treats as reachable, because the CLI floats. The security property is the one the tripwire exists for: "a Bash call that may have executed voids the run". The unlikelihood is carried in Confidence. This is not a re-fire. A16's canary is correct for what it targets (a shape change while denials still parse). What remains is the case the `:262-264` comment says is now caught.
**Location:** `test/skills/generate-reports.bash:257-287` (the comment and the jq), `:262-264` specifically
**Boundary:** B3 (source S2)
**Move:** #11, #5 (invert the check: what does the canary *not* cover?)
**Confidence:** Low for the environment (two independent CLI changes). High for the mechanism (executed).
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/skills/generate-reports.bash:262-264 (comment inside generate_one, :139-314 — read)
    #  - parser canary: every Bash denial must name a tool_use the parser saw.
    #    If the CLI's event shape changed, the tripwire and every transcript
    #    check would see no calls and pass; this makes that fail loudly (A16).
```

The canary keys on *denials*. Every case with no denial for the moved call is blind. Probe log `sec-5bdee46-iter4-probes.txt`:

```text
P2a tool_use moved + no permission_denials key             gen=[0 0 bash 9.9] no_tool_called_rc=0 mode1_rc=1
P2b tool_use moved + denial tool_name renamed              gen=[0 0 bash 9.9] no_tool_called_rc=0 mode1_rc=1
P2c tool_use moved + call NOT denied (executed)            gen=[0 0 bash 9.9] no_tool_called_rc=0 mode1_rc=1
P2d same as P2c + its tool_result in a user event          gen=[0 0 bash 9.9] no_tool_called_rc=0 mode1_rc=1
P2e only permission_denials moved (tool_use visible)       gen=[1 0 bash 9.9] no_tool_called_rc=1 mode1_rc=1
M2 Mode 1 t1 denied + hidden undenied t2 in .blocks        gen=[0 0 bash 9.9] no_tool_called_rc=1 mode1_rc=0
```

P2c is the security case: the call executed, the tripwire reads 0, and no `.failed` is written. P2a and P2b show that a single schema revision moving both the tool_use and the denials (or renaming `tool_name`) is enough for tc-ae5 to pass. That is one CLI release, not two unrelated regressions. P2e shows that the generator does fail closed when only the denials move. M2 is the mixed-shape variant: one call in the old shape and one in a new shape in the same run. It is the only probe where the whole pipeline *passes* a positive fixture with an unrecorded call, because mode1-equiv exits 0 and the generator writes nothing.

What limits the damage: in P2a-P2c, mode1-equiv reads zero calls, so the four positive fixtures fail. The suite goes red, but it reads "the model did not route", not "a call may have executed". The operator gets a failure with the wrong cause.

P2d is the lever. Every tool call, executed or denied, gets a `tool_result` block in a `user` event, keyed by `tool_use_id`. That evidence is independent of `permission_denials`, and the current jq never reads it.

**Recommendation:** Extend the one-pass jq with a second canary on the independent evidence. Collect the `tool_use_id` of every `tool_result` block (`select(.type == "user") | .message.content[]? | objects | select(.type == "tool_result") | .tool_use_id`). Void the run if any of them is not in `$cset`. Also void under deny-record when any denial's `tool_name` is not `"Bash"`: only Bash is offered, so that denial is itself a shape change (it closes P2b). After that, a silent execution needs the tool_use, the tool_result *and* the denial to move together. Change the `:262-264` comment to say what the canary keys on.

---

#### F3: The model's own tool input can make the tripwire's line unparseable to jq 1.6. When the deny rule fails, that call is then invisible to the generator and to `no_tool_called`

**Severity:** Low. The mechanism is concrete and comes from an untrusted source (S3). But the generator's own scope statement, "It catches accidental breaches, not concealed ones" (`:271`), excludes deliberate concealment, and this vector needs intent. Low rather than Informational because that statement names only the post-execution transcript rewrite (C29). This vector conceals *without* the command having run first: the concealment is in the request itself. So the stated scope understates it, and the fix is one jq clause.
**Location:** `test/skills/generate-reports.bash:275` (`[inputs | fromjson? | objects]`), `:271-272` (scope comment); `test/skills/eval-helpers.bash:372`
**Boundary:** B2 → B3, B4 (source S3)
**Move:** #2 ("what if this value contained an attacker-controlled string?"), #7 (deserialization boundary), #11
**Confidence:** High that jq 1.6 drops these lines (executed). Low for reachability: whether the Messages API and the CLI pass a model-written `\ud800` escape in tool-input JSON through to stream-json was not tested, because the brief forbids `claude` and network.
**Legibility-target:** for-author

```bash
# test/skills/generate-reports.bash:275 (first line of the jq program :275-287; generate_one ends :314 — read)
      verdict=$(jq -rRn '[inputs | fromjson? | objects] as $ev
```

`fromjson?` drops any line that jq 1.6 refuses. The model's tool input is part of that line. Two model-chosen inputs make jq refuse (`sec-5bdee46-iter4-probes2.txt`):

```text
S1 lone surrogate in command, call denied:   gen=[0 1 bash unknown]
S2 lone surrogate in command, call undenied: gen=[0 0 bash unknown]
S2 transcript_tool_inputs: []
S2 mode1-equiv rc=1 (python json parses lone surrogates)
D124 tool input nested 124 objects deep, undenied: gen=[1 0 bash unknown]
D125 tool input nested 125 objects deep, undenied: gen=[0 0 bash unknown]
jq: error (at d.jsonl:2): Exceeds depth limit for parsing at line 1, column 736 (while par
```

A command string holding a lone-surrogate escape (`"echo \ud800"`, which Node's JSON.stringify writes for a lone surrogate) is dropped whole by jq 1.6. So is a tool input nested 125 or more levels deep (jq 1.6's parse-depth limit). When the call is denied, A16's canary catches it (S1: `unseen=1`), which is good. When the deny rule failed (S2, D125), the generator reads a clean run, and tc-ae5's `no_tool_called` passes. Python's `json` accepts both, so mode1-equiv's own tripwire flags S2 for the positive fixtures. This is the same parser-divergence pattern as F1, in the opposite direction.

Because the whole line is dropped, a lone surrogate in *any* block of an assistant message hides *every* tool_use in that message.

**Recommendation:** Under deny-record, stop skipping unparseable lines. Void the run if any non-blank line fails to parse, for example `[inputs | select(test("\\S")) | (try fromjson catch "__unparsed__")]`, and count the markers alongside `undenied`/`unseen`. The `fromjson?` skip was added for stray CLI warnings on stdout. With `2>/dev/null`, a deny-record run should have none, and if one appears, voiding is the right call. Extend the `:271-272` scope sentence with "or a tool input shaped so the parser drops its event (the fix above closes that)".

---

#### F4: mode1-equiv's tripwire copy still has wrong-exit-0 paths when run on its own. Id type confusion and the missing `tool_name` filter are both closed end to end by the generator's `.failed`, except where F2 already applies

**Severity:** Informational. No end-to-end false pass beyond F2's M2 row: `eval_fixture` fails a fixture with `.failed` before `mode1_equiv:` runs (`eval-helpers.bash:79-83`). None of the ids involved are model-producible, because the CLI mints them.
**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:98-105` (`events`), `:178-183` (the tripwire, outside the SetupError `try`, :160-176)
**Boundary:** B4 (source S2)
**Move:** #7 (type confusion when deserializing), #3
**Confidence:** High (executed)
**Legibility-target:** for-orchestrator-synthesis (it bears on the Claim 13 structural fix)

```python
# test/skills/arithmetic-eval/mode1-equiv.py:178-186 (inside main, :159-207 — read)
    denied = {d.get("tool_use_id") for ev in evs
              if isinstance(ev, dict) and ev.get("type") == "result"
              for d in (ev.get("permission_denials") or []) if isinstance(d, dict)}
    denied.discard(None)
    # A call with no id counts as undenied (review iteration 3, C28).
    undenied = [cid for cid, _ in calls if cid is None or cid not in denied]
    if undenied:
        print(f"Bash tripwire: {len(undenied)} Bash call(s) not in permission_denials (may have executed): {undenied}")
        return 1
```

On the brief's question, whether any Claim 13 shape makes the checker exit 0 wrongly: **none do.** A number-valued `permission_denials`, an unhashable `tool_use_id` or `id`, a non-object event, and a string `message`/`content` all exit 1 (fact-check Claim 13, and M5 here). So does a 1200-deep line, which raises `RecursionError` in `events()`: that function catches only `ValueError` (`probes2.txt` R1: `rc=1`, traceback). All of these fail closed. What *does* exit 0 wrongly, with a correct denied-looking Mode 1 call:

```text
M1 Mode 1 t1 denied under tool_name Read                   gen=[1 0 bash 9.9] no_tool_called_rc=1 mode1_rc=0
M3 id true vs denial id 1 (hash-equal in Python)           gen=[1 1 bash 9.9] no_tool_called_rc=1 mode1_rc=0
M6 NaN ids on both sides (Python json accepts NaN)         gen=[0 0 bash 9.9] no_tool_called_rc=1 mode1_rc=0
M4 id 1 vs denial id "1" (tostring-equal in jq)            gen=[0 0 bash 9.9] no_tool_called_rc=1 mode1_rc=1
```

- M1 is fact-check Claim 9b: no `tool_name == "Bash"` filter.
- M3: Python treats `True == 1` as the same set key.
- M6: `json.loads` reuses one NaN object for every `NaN` literal, so the identity check in set membership matches.
- M4 is the generator's mirror image: `tostring` maps `1` and `"1"` to the same key.

In M1 and M3 the generator voids the run. In M6 and M4 neither checker catches it, but the CLI never writes NaN (JSON.stringify writes `null`) or numeric ids.

**Recommendation:** When the orchestrator makes the whole checker the SetupError boundary (the Claim 13 escalation), include in the same change: (a) `RecursionError` in `events()`'s except clause; (b) ids must be non-empty `str`, on both the call side and the denial side, and anything else counts as undenied (Python) or unseen (jq: `select(type == "string")` in place of `tostring`), which also removes the unhashable crashes of Claim 14; (c) filter denials by `d.get("tool_name") == "Bash"`, matching the generator.

---

## Untested bypass candidates

Guardrail: **generator one-pass jq (tripwire, parser canary, init canary)**

| Candidate | Status |
|---|---|
| Non-object content block before the tool_use | **Tested:** the generator sees the call; eval-helpers does not (F1) |
| tool_use path moved, with no denial (deny failed, key renamed, or `tool_name` renamed) | **Tested:** blind (F2: P2a-c) |
| Only the denials moved | **Tested:** fails closed, `undenied=1` (P2e) |
| Mixed shapes in one run | **Tested:** blind; mode1-equiv exits 0 (F2: M2) |
| Model-chosen lone-surrogate escape or ≥125-deep tool input | **Tested (jq 1.6):** line dropped; caught when the call was denied, blind when executed (F3). **Untested:** whether the API/CLI pass such input through |
| Duplicate tool_use id (an executed call sharing a denied call's id) | Untested: needs a CLI bug; ids are CLI-minted, not model-producible |
| Non-string ids (`1` vs `"1"`, NaN) | **Tested:** collide (F4: M4, M6); the CLI never emits them |
| Init event only at the end of the stream | Tested by the fact-check (Claim 20c): passes. Not a security gap, since presence is what the canary needs |
| `init.tools` as a string (`"Bash,Read"`, `"NotBashButContainsBash"`) | **Tested:** `index("Bash")` does a substring match → `bash`. An array `["BashOutput"]` → `nobash` (correct). The CLI emits an array, so this is cleared |
| Model text forging a JSON event line | Traced (iteration 3): escaped inside one line. Cleared |
| An executed command rewriting the transcript through `/proc/<pid>/fd/1` | Accepted scope (C29) |
| jq ≥1.7 behavior for F1/F3's lines | **Untested:** only jq 1.6 is in this sandbox. F1 probably fails closed on 1.7. F3's surrogate handling on 1.7 is unknown |

Guardrail: **`tool_inputs_checked` init requirement**

| Candidate | Status |
|---|---|
| Junk, empty or init-less file | Tested by the fact-check (Claim 16a): rc 1 |
| Tail-truncated (init only) | Tested by the fact-check (Claim 16b): passes here. Caught upstream by the generator's "no result event" `.failed` (`generate-reports.bash:252-255`). Cleared end to end |
| A non-JSON line or a bare `123` line before the init line | Traced: `fromjson?` skips the first. The second errors in `select`, which jq 1.6 swallows; jq 1.7 prints to stderr and continues. The `grep -q .` still finds the init. No fail-open. Cleared |
| The init requirement adding a fail-open | Traced: it only adds `return 1` paths (`:390-394`). Cleared |

Guardrail: **mode1-equiv exit 0**. Covered in F4: M1, M3 and M6 exit 0, all Claim 13 shapes exit 1, and RecursionError exits 1.

Guardrail: **install.sh rc-4 (blind scan → NOTE, treated as none)**

| Candidate | Status |
|---|---|
| Another same-uid process making install.sh's *own* subshell cwd unreadable | Traced: `readlink /proc/<own subshell>/cwd` passes the kernel's `PTRACE_MODE_READ_FSCREDS` check for a same-uid, dumpable parent. Yama restricts only ATTACH mode. No unprivileged process can flip install.sh's dumpable flag. `readable` counts the subshell itself, before the in-checkout filter (fact-check Claim 2). Cleared |
| Exhausting `RLIMIT_NPROC` so that every `$(readlink …)` fork fails (`readable` stays 0 → rc 4) | **Tested** (`probes2.txt` F1): under `ulimit -u 1`, bash retries 4 times and then *exits 254* on the command-substitution fork. It does not return a failed status to `\|\| continue`. Inside `$(procs_in_checkout)`, that is rc 254 → the new catch-all arm refuses (`install.sh:1208-1210`), or install.sh itself dies. Fail-closed. Cleared |
| A `readlink` shim earlier in PATH that always fails | Reachable, and it is how T91 simulates the case (by `sed`). Anyone who can plant a shim can plant a `pgrep` shim, which already blinds the Claude check. 037 accepts that class ("equivalent persistence through any other file in $HOME"). No new exposure. Cleared as accepted |
| An LSM hiding `/proc/*/cwd` | By design: NOTE + treated as none (A15/C27; 037:76). Accepted |
| install.sh run inside a PID namespace | Accepted residual (037:86; usage `:66-68`). The NOTE does not fire, as documented |

---

## Endorsement Claims

- **Claim:** In the one-pass jq, a deny-record run is voided when a Bash tool_use at `.message.content[]` is absent from the Bash-named denials, when a Bash-named denial names an id not seen at that path, when there is no init event, or when the init tools array lacks `"Bash"`. A jq failure is voided as "could not be read".
  **Location:** `test/skills/generate-reports.bash:273-302`
  **Evidence:** executed (probes B0, P2e, M1, M5, S1, D124; fact-check Claims 20a-c)
  **Verified:** the four counts and states on crafted stub transcripts, and the `unreadable` arm
  **Not verified:** events whose tool_use sits off that path with no denial (F2), lines jq 1.6 refuses (F3), and jq ≥1.7
  **route: code-fact-check**

- **Claim:** No Claim 13 shape (number-valued `permission_denials`, list `tool_use_id`, object `id`, non-object event, string `message`/`content`, a >1000-deep line) makes mode1-equiv exit 0. Each exits 1 or 2.
  **Location:** `test/skills/arithmetic-eval/mode1-equiv.py:98-207`
  **Evidence:** executed (fact-check `cfc-5bdee46-mode1-probes.txt`; here M5, R1)
  **Verified:** the exit code for each named shape
  **Not verified:** the wrong-exit-0 paths listed in F4 (M1, M3, M6), which are not Claim 13 shapes
  **route: code-fact-check**

- **Claim:** `procs_in_checkout` returns 4 only when no same-uid `/proc` entry's cwd resolves, including its own subshell's. A fork failure inside the scan exits the subshell 254, and the gate's catch-all arm turns that into a refusal.
  **Location:** `devcontainer-config/install.sh:1157-1173, 1192-1211`
  **Evidence:** executed (fact-check Claims 2-3, T91; here the `ulimit -u 1` probe, on a standalone script, not on install.sh itself)
  **Verified:** bash's exit 254 on a command-substitution fork failure, and the catch-all arm's text (read)
  **Not verified:** an end-to-end install.sh run under NPROC exhaustion (not run, to avoid starving the shared sandbox)
  **route: code-fact-check**

- **Claim:** `tool_inputs_checked`'s init requirement adds only failure paths. It has no path that returns the inputs when the earlier version would have failed.
  **Location:** `test/skills/eval-helpers.bash:384-401`
  **Evidence:** read-static (the whole function; fact-check Claim 16a executed its failure cases)
  **Verified:** the new block (`:390-394`) is a guard with `return 1` placed before the existing logic
  **Not verified:** the jq-version-dependent parse in `transcript_tool_inputs` that feeds it (F1)

---

## Primitive sweep

Primitive: **deserialization** (JSON from the transcript: jq `fromjson` and Python `json.loads`)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `generate-reports.bash:245` (report extraction) | S2, S3 | `fromjson?` | cleared: the report text only; result_state gates it |
| `generate-reports.bash:249` (result_state) | S2 | `fromjson?`, `tail -n 1` | cleared: missing → "no result event" (fail-closed) |
| `generate-reports.bash:275` (one-pass jq) | S2, S3 | `fromjson? \| objects` | F2 (shape), F3 (model-steerable skip), F4/M4 (`tostring` ids) |
| `eval-helpers.bash:372` (`transcript_tool_inputs`) | S2, S3 | `fromjson?`, `[]?` | F1 (no `objects`), F3 |
| `eval-helpers.bash:390, 395` (init probe, tools list) | S2 | `fromjson?`, `grep -q .` | cleared (traced above) |
| `eval-helpers.bash` `assert_subagents_min` jq | S2 | `fromjson?` | cleared: not used by deny-record fixtures; unchanged in this diff |
| `mode1-equiv.py:98-105` (`events`) | S2, S3 | `except ValueError` | F4 (RecursionError escapes, fail-closed) |

Primitive: **process exec**

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `generate-reports.bash:231-235` `claude …` | S1, S3 | CLAUDE_FLAGS refusal; one-element `--model`; `--tools Bash` + `DENY_RECORD_FLAGS` | unchanged by 37c5ea9; detection side is F2/F3 |
| `mode1-equiv.py:146` `subprocess.run(["python3","-c",program], input=expr)` | S4 (program), S3 (expr on stdin) | always SKILL.md's program; `timeout=10`; `MAX_BITS` | cleared (iteration 3; unchanged by 37c5ea9) |
| `eval-helpers.bash` `python3 "$checker" …` | S4 | argv array | cleared |
| `install.sh:1165-1170` `readlink`, `tr < cmdline` | S5, S6 | read-only; fork failure → exit 254 → refusal | cleared (tested above) |
| `install.sh` `pgrep -af -- "$CLAUDE_PROC_RE"` | S6, code constant | `--`; rc > 1 refuses | cleared; namespace scope accepted (037:86) |

---

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F2 | Residual of A16: an executed call is unrecorded when no denial exists and the tool_use path moves; one schema revision passes tc-ae5; tool_result evidence unused | Medium | B3 | `generate-reports.bash:257-287` | Low (env) / High (mechanism) |
| F1 | The canary validates the generator's parser, not eval-helpers'; a non-object block hides a denied call from tc-ae5 (jq 1.6); the comment says it is covered | Low | B3, B4 | `eval-helpers.bash:369-374, 381-383` | High (mechanism) / Low (env) |
| F3 | Model-chosen tool input (lone-surrogate escape, ≥125-deep nesting) makes jq 1.6 drop the event line; an executed call is invisible to the tripwire and `no_tool_called` | Low | B2→B3, B4 | `generate-reports.bash:275, 271-272`; `eval-helpers.bash:372` | High (jq) / Low (reachability) |
| F4 | mode1-equiv standalone exit 0 on unfiltered `tool_name` and non-string ids; RecursionError escapes `events()`; no Claim 13 shape exits 0 | Informational | B4 | `mode1-equiv.py:98-105, 178-186` | High |

---

## Overall Assessment

37c5ea9 is a net security improvement, and I found no regression in it. The parser canary does what A16 asked. The one-pass rewrite kept the tripwire's semantics, including no-id calls counting as undenied. The init requirement adds only failure paths. The runner-contract reorder dropped no check. The rc-4 relabel did not open a way to force the blind path: a fork-starvation attempt makes bash exit 254, and the new catch-all arm refuses on that. All four findings are in one place: **how the transcript is parsed, and by how many parsers.** Three readers (generator jq, eval-helpers jq, Python) differ on non-object blocks, unparseable lines and id types. The canary vouches for only one of them. And every fail-closed check keys on `permission_denials`, which a failed deny rule never writes. The single most important fix is F2's second canary on `tool_result` ids, together with F3's "an unparseable line voids a deny-record run". Both are clauses in the existing one-pass jq. With F1's `objects` (or one shared jq `def`), they would make the three readers agree and put the independent evidence to use. None of this needs architectural change. The verdict is: **no findings above Medium within the code paths read; endorsement claims pending execution verification.** F2 is the amber candidate. The CLI-side questions (whether the API passes a model-written lone surrogate; jq ≥1.7 behavior) remain untested under the brief's constraints.

---

## Goal-Alignment Note

- **User goal / success criterion:** a review-fix-loop security critique of `skill-fixtures` before the local merge, saved at `docs/reviews/security-review-2026-09-25-q062-q063-iter4.md` with `Commit: 5bdee46` at top. **Answered:** yes, at this path. Every finding carries Severity, Location, verbatim Evidence, Confidence and Legibility-target. Endorsements that could anchor a Confirmed-Good row are routed `route: code-fact-check`.
- **Focus coverage:**
  - The one-pass jq and the "both shapes" blind spot: F2, F3, and the first bypass table. The answer to "can undenied=0/unseen=0/init=bash while a Bash call ran?" is yes, in P2c, M2, S2 and D125.
  - `tool_inputs_checked`'s init requirement: the second bypass table and the fourth endorsement. It is sound; F1 is in the function that feeds it.
  - mode1-equiv's tripwire copy: F4. No Claim 13 shape exits 0. M1, M3 and M6 do, and the generator covers M1 and M3.
  - install.sh rc-4: the last bypass table. No process can force the blind NOTE path beyond the accepted PATH-shim and LSM classes.
- **Terminal pass, full inventory from this critic:** F2 Medium (amber candidate), F1 Low, F3 Low, F4 Informational. Not re-filed: iteration-3 F1 (Fixed as A15, verified correct), F3 (C29), F4/F5 (A19/C28; the residue is folded into F4 for the Claim 13 structural fix).
- **Out of scope:** Claims 18, 24b and 24c (doc and commit-message accuracy with no security effect). Whether to fix F1-F3 now or record them as Q-entries is the orchestrator's call.
- **Escalate:** F4's recommendation (a)-(c) should go into the orchestrator's Claim 13 structural fix, so that the boundary covers ids and RecursionError too.
- **Execution:** probes ran in the session scratchpad (jq-1.6, python3, bash). I copied the scripts and logs to `docs/reviews/execution-logs/sec-5bdee46-iter4-probes{,2}.{sh,txt}`. No `claude` and no network. Nothing was committed.
