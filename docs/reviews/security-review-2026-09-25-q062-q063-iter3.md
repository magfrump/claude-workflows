Commit: c7747c7

# Security Review — skill-fixtures (Q-062 [2] / Q-063 [1]), review-fix loop iteration 3 of 3 (terminal pass)

**Scope:** `git diff main...HEAD` on `skill-fixtures` (HEAD c7747c7). The f9feb2c deny-record hardening end to end, the eval-helpers fail-closed claims, mode1-equiv.py's crash and false-pass paths, and the final state of the install.sh in-checkout gate.
**Date:** 2026-09-25
**Based on:** `docs/reviews/code-fact-check-report.md` (Commit c7747c7; Claims 2a, 2b, 14, 16, 17, 24, 25 used as the behavioral foundation), the rubric `docs/reviews/code-review-rubric-2026-09-25-skill-fixtures-q062-q063.md`, and `docs/reviews/security-review-2026-09-25-q062-q063-iter2.md`.

Settled items are not re-filed: C4, C5, C9, C6, trap RETURN, `--tools` variadic, RUNNER_ALLOWED_TOOLS naming, A1 (unreadable-cwd skip, pending Q-064), C24, C3/C4/C6/C8/C13/C14/C15. I checked the iteration-2 fixes this review depends on (C16, C17, C10, A12, A14). They are correct as far as the code goes. F1 and F2 below are what those fixes left open.

---

## Trust Boundary Map

```
B1: [operator env: CLAUDE_FLAGS, CLAUDE_MODEL, inherited env] → [generate-reports.bash refusal + argv build :126-160] → [claude argv (permission flags)]
B2: [model under test (Haiku etc.)]  → [claude CLI: --tools Bash + DENY_RECORD_FLAGS :120,188-190] → [host shell (Bash execution)]
B3: [claude CLI stream-json on stdout] → [transcript.jsonl in test/skills/<skill>/output] → [generator tripwire + canary :256-288 → .failed]
B4: [transcript.jsonl (model-chosen tool inputs inside CLI-shaped events)] → [eval-helpers transcript checks :369-462; mode1-equiv.py :95-191] → [fixture pass/fail verdict]
B5: [model-chosen Mode 1 expression] → [mode1-equiv.py evaluate() :132-145, SKILL.md evaluator] → [python3 subprocess on the test host]
B6: [other same-uid processes / host PID namespace] → [install.sh procs_in_checkout + pgrep :1151-1190] → [agent_gate allow/refuse decision]
```

**Input-source classification**

```
S1: CLAUDE_FLAGS / CLAUDE_MODEL      — deploy-time (operator shell) — trusted for intent; UNTRUSTED as argv
                                        (typo/paste errors reach the permission sink; C16 history)
S2: inherited environment of claude  — deploy-time (operator shell) — operator-controlled; not scanned
S3: model tool_use inputs (command)  — request-time (model output)  — UNTRUSTED for exec sinks (B2) and
                                        for the evaluator sink (B5); inert as JSON text in B3/B4
S4: CLI event shape (stream-json)    — runtime-mutable (CLI floats to latest, C17) — UNTRUSTED as a
                                        stable schema for fail-closed parsers (B3, B4)
S5: SKILL.md Mode 1 block, expected-verdicts specs — code-constant — trusted (all sinks)
S6: /proc entries (cwd, cmdline, status) — runtime (other same-uid processes) — UNTRUSTED for content
                                        (cmdline shown via vis_or_die); trusted for availability only
                                        within install.sh's own PID namespace
```

The deny-record design moves the only execution sink (B2) behind a CLI deny rule and then detects breaches after the fact from a CLI-written log (B3). Both the detector and the graders (B4) trust S4, the CLI's event shape, to stay stable. That is the assumption F2 tests. On the install side, the Q-062 scan and the older pgrep check both trust that install.sh's `/proc` is the host's (B6). That is the assumption F1 tests.

---

## Findings

#### F1: The blind-scan NOTE is silent exactly when the whole gate is namespace-blind, and the comment says the opposite (Claim 2b escalation)

**Severity:** Low. This rates the legibility defect. The mechanism, a gate that sees only its own PID namespace, is an accepted residual (`037:86`). If the orchestrator reads 037:86 as covering only the other direction (the *target* process inside a sandbox), then this is an unaccepted mechanism in a reachable environment, and the floor rule lifts it to **Medium**.
**Location:** `devcontainer-config/install.sh:1138-1143` (comment), `:1151-1170` (`procs_in_checkout`), `:1182` (pgrep); `docs/decisions/037-bare-host-copy-install.md:86`
**Boundary:** B6
**Move:** #5 (invert the check), #3 (error path)
**Confidence:** High on the code path and the silence (fact-check Claim 2b, executed). Medium on the environment: it needs install.sh to run from a terminal inside a PID namespace.
**Legibility-target:** for-author

Evidence (complete unit `procs_in_checkout`, :1151-1170, read in full):

```bash
# devcontainer-config/install.sh:1140-1143
# is not mounted, 3 when the checkout's own path cannot be resolved. When no
# process's cwd can be read at all (an LSM hiding /proc, a PID-namespaced
# sandbox), it says so on stderr: the scan is then blind, not clean (review
# iteration 2, A14).
```

```bash
# devcontainer-config/install.sh:1156-1158, 1166-1169
    [ -O "$d" ] || continue                     # this uid's processes only
    cwd="$(readlink "$d/cwd" 2>/dev/null)" || continue   # unreadable: see above
    readable=$((readable + 1))
…
  if [ "$readable" -eq 0 ]; then
    echo "NOTE: no process's working directory could be read under /proc, not even this" >&2
```

When install.sh runs inside a PID namespace (a flatpak-packaged editor's integrated terminal, which bwrap puts in its own PID namespace; a devcontainer; a bwrap sandbox like this review's), its own `/proc` lists only that namespace. install.sh's own entry and its siblings are readable, so `readable > 0` and the NOTE stays silent. Meanwhile both halves of the gate are blind to the host. `procs_in_checkout` cannot see host processes in the checkout, and `pgrep -u <uid> -af` at `:1182` cannot see a host `claude`. The gate then returns 0 with no output. This sandbox shows the shape: 8 entries under `/proc`, PID 1 = `/bin/sh -c echo Container started`, own PID 3571537, and the fact-check's unmodified scan read 6 cwds with no NOTE (`cfc-c7747c7-procs-blind-note.txt`).

The comment names this case as a NOTE trigger, so a reader takes the NOTE's silence as "not namespace-blind". 037:86's residual ("another PID or mount namespace (a terminal inside a PID-namespaced sandbox …), where `/proc` does not list them") is also ambiguous about direction. From the host, `/proc` *does* list processes in child PID namespaces. The unlisted case is install.sh itself running inside one, and that case blinds the pgrep check (037:81, Q-058) too, which 037 does not say.

I tried the obvious detection, and it does not work. `NSpid:` in `/proc/self/status` lists PIDs only from the `/proc` mount's namespace inward. Here it shows one level (`NSpid: 3571537`) although the process is plainly namespaced. `/proc/self/ns/pid` equals `/proc/1/ns/pid` for the same reason. From inside, no reliable signal exists.

**Recommendation:** (1) Drop "a PID-namespaced sandbox" from the comment at `:1141-1142`, and say the NOTE does not catch it. (2) Reword 037:86 to "install.sh run from inside a PID namespace (a flatpak editor's terminal, a container) sees only that namespace, and both the pgrep check and the cwd scan are blind to host processes; run install.sh from a host terminal", and state the same in `usage`. (3) Optional and cheap: print a NOTE, not a refusal, when `/proc/1/comm` is not a host init (`systemd`, `init`; WSL2's `/init` is also `init`). Flatpak's PID 1 is `bwrap`, and this sandbox's is `sh`. A false positive costs one line.

---

#### F2: The tripwire, the canary-guarded run and `no_tool_called` share one parse path and go blind together on a tool_use shape change; `permission_denials` is never cross-checked against the calls the parser saw

**Severity:** Medium. Floor rule: this is a concrete mechanism. The CLI floats to latest (C17's premise), and one shape change makes the executed-call detector read zero calls. Two independent CLI regressions are needed for an executed Bash call to go unrecorded, so the unlikelihood is carried in Confidence. A single shape change is enough for the negative fixture tc-ae5 to pass with a Bash call present.
**Location:** `test/skills/generate-reports.bash:262-267` (tripwire jq), `:281-287` (canary); `test/skills/eval-helpers.bash:369-393` (`transcript_tool_inputs`, `tool_inputs_checked`), `:449-462` (`assert_no_tool_called`); `test/skills/arithmetic-eval/mode1-equiv.py:105-114, 165-167`
**Boundary:** B3, B4 (source S4)
**Move:** #11 (bypass enumeration against the tripwire), #3
**Confidence:** Low for an unrecorded execution (needs a denial regression and a shape change together). High for the tc-ae5 false pass given a shape change (executed below).
**Legibility-target:** for-author

All four readers locate calls at one path:

```bash
# test/skills/generate-reports.bash:264-265 (inside the tripwire jq, :262-267; generate_one ends :299, read)
        | [$ev[] | select(.type == "assistant") | .message.content[]?
           | select(.type == "tool_use" and .name == "Bash") | .id]
```

```bash
# test/skills/eval-helpers.bash:371-373 (transcript_tool_inputs, complete unit :369-374)
  jq -rR --arg n "$2" \
    'fromjson? | select(.type == "assistant") | .message.content[]?
     | select(.type == "tool_use" and .name == $n) | .input | tostring' "$1"
```

The `[]?` and `fromjson?` suppressions turn "the shape moved" into "zero calls". The canary checks only that the init event lists Bash. It does not check that the parser can see calls. **Executed probe** (scratchpad, jq-1.6): a transcript with an init event listing Bash, one Bash `tool_use` under `.message.blocks` (a hypothetical shape change), and a result event with `is_error:false` and `permission_denials:[{"tool_name":"Bash","tool_use_id":"tu1",…}]`:

```text
generator tripwire undenied=0
canary init_tools=Bash
result_state=ok
assert_no_tool_called Bash rc=0
denials naming Bash: tu1
```

So the generator writes no `.failed`, and `no_tool_called:Bash` (tc-ae5) passes. The result event itself names a Bash denial that no reader saw. In the same drift, a Bash call that the deny rule failed to block would leave no denial and no seen call, which is a fully silent execution. mode1-equiv.py uses the same path (`(ev.get("message") or {}).get("content")`) and would read zero calls. That case fails closed, as a false "didn't route".

This also settles Claim 16 in security terms. The helper's comment ("fail … when the transcript cannot be parsed") overclaims. For generated deny-record transcripts, the generator's result-event check and canary do make a *junk* transcript fail closed, because `.failed` is written. They do not cover a *well-formed transcript of a new shape*. That case is the one that matters once the CLI floats.

**Recommendation:** Add a parser canary in the generator under deny-record: void the run when any `permission_denials` entry with `tool_name == "Bash"` has a `tool_use_id` that is not among the Bash `tool_use` ids the tripwire saw ("Bash parser canary: N denial(s) name calls the transcript parser did not see; CLI <version>"). This is one extra jq clause next to `:262`, and it turns shape drift into a void run. Under deny-record, `assert_no_tool_called Bash` could also require zero Bash denials in the result event. Correct the `tool_inputs_checked` comment (`:376-380`) to "fails when the transcript cannot be read; unparseable lines are skipped, and a transcript with no parseable calls reads as no calls".

---

#### F3: The tripwire's evidence is writable by the command it is meant to catch

**Severity:** Informational. Exploiting it requires code already executing as the operator's uid, which is below the reachable-environment bar.
**Location:** `test/skills/generate-reports.bash:231-235` (stdout redirected to the transcript), `:260-274` (tripwire reads the file afterwards)
**Boundary:** B2 → B3
**Move:** #4 (time of check vs time of use)
**Confidence:** Medium (read-static; standard Linux `/proc/<pid>/fd` semantics; not executed)
**Legibility-target:** for-author

```bash
# test/skills/generate-reports.bash:231-235
  (cd "$temp_dir" && printf '%s' "$stdin_text" \
    | claude "${claude_args[@]}" \
      "${model_args[@]}" \
      ${CLAUDE_FLAGS:-} \
  ) > "$out_path" 2>/dev/null || rc=$?
```

The tripwire exists for "a Bash call that may have executed" (`:256-259`). A call that did execute runs as the same uid, as a descendant of `claude`, whose fd 1 is the transcript file. It can reopen `/proc/<claude pid>/fd/1` and rewrite the `tool_use` line, or the whole file, before the tripwire reads it at `:262`. So the tripwire detects an *accidental* breach, such as a CLI regression running a benign command, but not a concealing one. That is a reasonable scope for grading runs. The docs should not present the detector as stronger than that.

**Recommendation:** No code change. In the DD doc's "As built" section, and in the `:256-259` comment, scope the claim: "detects an executed call the CLI logged; a command that ran could alter the log, so the prevention is `Bash(**)`, not the tripwire."

---

#### F4: mode1-equiv.py crashes on mis-shaped transcript JSON with an unlabelled exit 1 (fail-closed, never a false pass)

**Severity:** Informational (robustness/legibility; no false-pass path)
**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:105-114` (`bash_calls`), `:163-174` (`main` after the `try`); `test/skills/eval-helpers.bash:481-486`
**Boundary:** B4
**Move:** #3, #7 (type confusion at deserialization)
**Confidence:** High (fact-check Claim 14, executed: four shapes → traceback, exit 1)
**Legibility-target:** for-author

```python
# test/skills/arithmetic-eval/mode1-equiv.py:108-113 (bash_calls, complete unit :105-114)
    for ev in evs:
        if ev.get("type") != "assistant":
            continue
        for block in (ev.get("message") or {}).get("content") or []:
            if block.get("type") == "tool_use" and block.get("name") == "Bash":
                calls.append((block.get("id"), (block.get("input") or {}).get("command", "")))
```

`events()` catches only `ValueError`, so any valid JSON that is not the expected object shape (a bare `123`, a string content block, a string `input`, a numeric `command`, a list-valued `id`, which is unhashable at `:167`) raises `AttributeError`/`TypeError` outside `main`'s `try`. The only `return 0` (`:189`) comes after a successful evaluation, so every crash exits 1. The checker cannot pass falsely this way. It can only report a CLI-shape problem as "the model did not route", with a traceback in the output.

**Recommendation:** Wrap the post-setup section (`:163-191`) in `except (AttributeError, TypeError, KeyError)` and exit 2 with "transcript has an unexpected event shape (CLI change?)", so `assert_mode1_equiv`'s SETUP ERROR label applies. This pairs with F2's parser canary.

---

#### F5: Both tripwires treat an id-less Bash call as denied when a denial also lacks an id

**Severity:** Informational (needs a CLI that emits id-less events; the model cannot produce this)
**Location:** `test/skills/generate-reports.bash:263-266`; `test/skills/arithmetic-eval/mode1-equiv.py:165-167`
**Boundary:** B3, B4
**Move:** #11
**Confidence:** High (executed)
**Legibility-target:** for-author

```python
# test/skills/arithmetic-eval/mode1-equiv.py:165-167 (inside main, :148-191, read)
    denied = {d.get("tool_use_id") for ev in evs if ev.get("type") == "result"
              for d in ev.get("permission_denials") or []}
    undenied = [cid for cid, _ in calls if cid not in denied]
```

A `tool_use` with no `id`, together with a denial entry with no `tool_use_id`, gives `None in {None}` in Python and `$denied | index(null)` → 0 (truthy) in jq. Probes: mode1-equiv with a correct Mode 1 call and both ids absent gave `rc=0`, and the generator jq gave `undenied=0`. If only the call lacks an id, the run is voided (probe: `1`). This is correct.

**Recommendation:** Count a missing or null `id` as undenied in both places (`select(.id != null)` in the ids, and `cid is None or cid not in denied`).

---

## Untested bypass candidates

Guardrail: **deny-record argv (CLAUDE_FLAGS refusal, CLAUDE_MODEL, DENY_RECORD_FLAGS)**

| Candidate | Status |
|---|---|
| `CLAUDE_FLAGS` = whitespace plus a flag (`$'\t--x'`, `' --verbose'`) | Tested (fact-check Claim 24): refused |
| `CLAUDE_FLAGS=$'\v'` or a Unicode space: `[[:space:]]` strips it, so it counts as blank, but it is not in IFS | **Tested:** accepted, and reaches claude as one positional argv element (`argc=1`, `$'\v'`). It cannot form a flag (no `-`), so it is not a permission bypass. It may be read as a positional prompt. Cleared as a bypass; noted for grading integrity |
| `CLAUDE_MODEL='m --permission-mode bypassPermissions'` | Tested (test/generate-reports.bats:514; fact-check Claim 24): one argv element |
| `CLAUDE_MODEL='--dangerously-skip-permissions'` or `'--permission-mode=bypassPermissions'`: does the CLI take a `--model` value that starts with `--` as the value (greedy) or as a flag? | **Untested:** CLI behavior; the brief forbids running `claude` |
| Inherited environment: `CLAUDE_CONFIG_DIR` or any env var that loads settings or permission defaults despite `--restricted`/`--safe-mode` | **Untested:** CLI behavior. Operator-controlled (S2), so outside the reachable-environment bar |
| Managed settings (`/etc/claude-code/managed-settings.json`) with allow rules or hooks | **Untested:** CLI precedence (deny over allow; `--safe-mode` hooks). Host-controlled |
| `--disallowedTools` is variadic: could a following argv element be swallowed as a second rule? | Traced: the next element is `--permission-mode` (option-shaped), which ends the list. Cleared statically |

Guardrail: **generator tripwire + canary**

| Candidate | Status |
|---|---|
| Model text containing a newline plus a forged JSON event | Traced: stream-json escapes model text inside one event line. Cleared |
| tool_use shape change | **Tested:** blind (F2) |
| id-less call plus id-less denial | **Tested:** passes (F5) |
| Duplicate `tool_use` id (an executed call sharing an id with a denied one) | Untested: needs a CLI bug; not model-producible |
| Executed call rewrites the transcript via `/proc/<pid>/fd/1` | Not executed; read-static (F3) |

Guardrail: **mode1-equiv.py pass condition**

| Candidate | Status |
|---|---|
| A wrong expression with a trailing comment `# -> 1900000000` to spoof the `-> (\S+)\s*\Z` parse | **Tested:** `rc=1` (the evaluator prints the result last) |
| A correct expression whose id is not in `permission_denials` | **Tested:** `rc=1` (tripwire) |
| The literal answer as the expression (`1900000000`) | **Tested:** `rc=0`. That is a real denied Mode 1 call, so it is not a bypass of the security property. It is a routing-quality limit (the model may have done the math in its head), out of this critic's scope |
| Resource exhaustion in `evaluate()`: the checker runs the reference evaluator without the wrapper's `ulimit -v` | Traced: `MAX_BITS` predicts the size of a power before computing it, `ck()` caps every intermediate, and `timeout=10`. Cleared statically |

Guardrail: **eval-helpers `no_tool_called`**. The junk and init-less transcripts come from fact-check Claims 16 and 17 (executed: `rc=0`). End to end they are covered by the generator's `.failed` gates for deny-record runs. The shape-drift case is not covered (F2, tested).

Guardrail: **install.sh gate**. Install.sh inside a PID namespace: tested by the fact-check and here (F1). A cwd reached through a bind mount: accepted residual, untested (needs mount privileges). A non-dumpable process: A1, settled.

---

## Endorsement Claims

- **Claim:** Under `FIXTURE_BASH=deny-record`, any `CLAUDE_FLAGS` value holding a non-`[[:space:]]` character makes the generator exit 1 before `claude` is invoked.
  **Location:** `test/skills/generate-reports.bash:126-129`
  **Evidence:** executed (fact-check Claim 24, six values; `test/generate-reports.bats:498`), and here for `$'\v'`
  **Verified:** the refusal condition under `set -euo pipefail`, and that it runs before `generate_one`
  **Not verified:** whitespace-only values that reach argv as positional elements (the `$'\v'` row above), and inherited env vars, which are not scanned at all
  **route: code-fact-check**

- **Claim:** `CLAUDE_MODEL` reaches claude's argv as exactly one element after `DENY_RECORD_FLAGS`.
  **Location:** `test/skills/generate-reports.bash:157-160, 231-233`
  **Evidence:** executed (`test/generate-reports.bats:514`; fact-check Claim 24)
  **Verified:** the argv element boundaries with a stub `claude`
  **Not verified:** how the real CLI parses a `--model` value that begins with `--` (untested candidate above)
  **route: code-fact-check**

- **Claim:** mode1-equiv.py exits 0 only when some Bash `tool_use`, whose id is in a result event's `permission_denials`, carries the exact Mode 1 wrapper with an AST-equal program, and SKILL.md's evaluator (never the model's copy) maps its heredoc body to an expected value.
  **Location:** `test/skills/arithmetic-eval/mode1-equiv.py:163-191`
  **Evidence:** executed (here: the real/spoof/undenied probes; fact-check Claims 13-15)
  **Verified:** the pass, spoofed-parse, undenied and literal cases on crafted transcripts
  **Not verified:** the id-less case, which passes (F5)
  **route: code-fact-check**

- **Claim:** A deny-record run whose transcript has no init event listing Bash, or no result event, is recorded in `.failed`, and `eval_fixture` fails it before any check runs.
  **Location:** `test/skills/generate-reports.bash:246-255, 281-287, 291-293`; `test/skills/eval-helpers.bash:80-84`
  **Evidence:** executed (fact-check Claims 22, 25; `test/generate-reports.bats:527-562`)
  **Verified:** the canary, the result-state check and the marker read
  **Not verified:** a well-formed transcript of a changed shape (F2)
  **route: code-fact-check**

- **Claim:** `agent_gate` exits 1 when `/proc/self` is absent (rc 2) or the checkout path does not resolve (rc 3).
  **Location:** `devcontainer-config/install.sh:1153-1154, 1189-1199`
  **Evidence:** executed (fact-check Claim 1; T90)
  **Verified:** both return codes and the refusal messages
  **Not verified:** a `/proc` of a PID namespace other than the host's (F1)
  **route: code-fact-check**

---

## Primitive sweep

Primitive: **process exec** (a command built from data, and subprocess launch)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `test/skills/generate-reports.bash:231-235` `claude …` | S1, S2 (argv/env), S3 (model → Bash tool) | CLAUDE_FLAGS refusal; one-element `--model`; `--tools Bash` plus `DENY_RECORD_FLAGS`; tripwire and canary after the fact | F2, F3; the `$'\v'` row cleared |
| `test/skills/arithmetic-eval/mode1-equiv.py:135` `subprocess.run(["python3","-c",program], input=expr)` | S5 (program), S3 (expr on stdin) | the program is always SKILL.md's (`ref_program`); expr is inert stdin; AST evaluator with `MAX_BITS`; `timeout=10` | cleared: model code never runs, and the size is bounded |
| `test/skills/eval-helpers.bash:482` `python3 "$checker" … "$spec"` | S5 | argv array, no shell | cleared |
| `test/skills/eval-helpers.bash:170` `bats …-format.bats` | S5 (`$skill`) | fixed path | cleared (unchanged in this diff) |
| `devcontainer-config/install.sh:1157, 1162` `readlink`, `tr < cmdline` | S6 | read-only; cmdline shown via `vis_or_die` (`:1252`) | cleared as a sink; the scan scope is F1 |
| `devcontainer-config/install.sh:1182` `pgrep -af -- "$CLAUDE_PROC_RE"` | code constant | `--` | cleared as a sink; the namespace scope is F1 |

Primitive: **deserialization** (JSON from the transcript)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `generate-reports.bash:244, 248, 262, 281, 283` (jq `fromjson?`) | S4 | `fromjson?` skips lines | F2 (the skip hides shape drift), F5 |
| `eval-helpers.bash:371-373, 387, 435` (jq) | S4 | `fromjson?`; jq rc checked at `:383` | F2 |
| `mode1-equiv.py:97-101` (`json.loads`) | S4 | catches `ValueError` only | F4 (fail-closed crash), F5 |

---

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F2 | Tripwire, `no_tool_called` and mode1-equiv share one tool_use path; shape drift blinds all of them; `permission_denials` never cross-checked | Medium | B3, B4 | `generate-reports.bash:262-267`; `eval-helpers.bash:369-393` | Low (unrecorded exec) / High (tc-ae5 false pass) |
| F1 | Blind-scan NOTE silent when install.sh runs inside a PID namespace; comment claims it fires; 037 residual ambiguous; pgrep equally blind | Low (Medium if 037:86 does not cover this direction) | B6 | `install.sh:1138-1143, 1151-1170, 1182`; `037:86` | High (path) / Medium (env) |
| F3 | Tripwire evidence writable by an executed command (`/proc/<pid>/fd/1`) | Informational | B2→B3 | `generate-reports.bash:231-235, 260-274` | Medium |
| F4 | mode1-equiv mis-shaped JSON → unlabelled traceback exit 1 (fail-closed) | Informational | B4 | `mode1-equiv.py:105-114, 163-174` | High |
| F5 | id-less call plus id-less denial counts as denied in both tripwires | Informational | B3, B4 | `generate-reports.bash:263-266`; `mode1-equiv.py:165-167` | High |

---

## Overall Assessment

On focus (a), I found no path in the code by which a Bash call executes unrecorded, or by which a fixture passes without a real denied Mode 1 call, given today's CLI shape. f9feb2c closed C16 correctly. Any non-blank `CLAUDE_FLAGS` is refused. `CLAUDE_MODEL` is one argv element. `DENY_RECORD_FLAGS` has one definition. The canary catches a deny rule that removes the tool. mode1-equiv never runs the model's program, and its pass condition resisted the spoofing and undenied probes. The one structural gap is F2. Every fail-closed detector and grader parses tool calls at one unversioned path, and the result event's `permission_denials` is never checked against what they saw. The CLI floats, and a shape change would silently blind the tripwire and pass tc-ae5. One extra jq clause, a parser canary that voids the run when a Bash denial names an id the parser did not see, closes this. It is the single most important thing to address. On (b), Claim 16's comment overclaims. End to end, junk transcripts are caught by the generator's `.failed` gates, but drifted ones are not (F2). On (c), mis-shaped JSON crashes are fail-closed (F4). Only CLI-emitted id-less events can produce a wrong exit 0 (F5). On (d), the install gate's final code is as documented, except that the comment's PID-namespace example is wrong and 037's residual needs its direction stated (F1). No finding needs architectural change. All are fixable in place. The verdict is **no findings above Medium within the code paths read; endorsement claims pending execution verification.** The CLI-behavior candidates (`--model` greedy parsing, env and managed-settings precedence) remain untested by the brief's constraint.

---

## Goal-Alignment Note

- **User goal / success criterion:** a review-fix-loop security critique of `skill-fixtures` before the local merge, saved at `docs/reviews/security-review-2026-09-25-q062-q063-iter3.md` with `Commit: c7747c7` at top. **Answered:** yes, at this path. Every finding carries Severity, Location, verbatim Evidence, Confidence and Legibility-target, and endorsements are routed `route: code-fact-check`.
- **Focus coverage:** (a) the deny-record hardening end to end: Overall Assessment, F2, F3, bypass tables. (b) eval-helpers fail-closed and Claim 16: F2. (c) mode1-equiv crash paths and false-exit-0 attempts: F4, F5, probes. (d) Claim 2b and the gate's final state: F1.
- **Terminal pass, full amber inventory from this critic:** F2 (Medium) is the amber candidate. F1 is Low, or Medium if the orchestrator finds 037:86 does not cover install.sh running inside a namespace. F3-F5 are Informational.
- **Out of scope / not re-filed:** Claims 8 and 29c (the vacuous `! hits` and the red shellcheck gate; the orchestrator is fixing them) and Claims 5b and 6 (stale docs that *understate* the new protection, so no security risk). The literal-answer Mode 1 call is a routing-quality question, not a security property. Settled items are listed at the top.
- **Execution:** probes ran in the session scratchpad only (jq-1.6, python3, bash). No `claude` and no network. Nothing was committed.
