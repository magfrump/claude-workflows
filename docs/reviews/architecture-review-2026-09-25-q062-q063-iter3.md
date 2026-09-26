Commit: c7747c7

# Architecture Review — skill-fixtures (Q-062 [2], Q-063 [1]), iteration 3 (terminal)

**Scope:** `git diff main...HEAD` on skill-fixtures (HEAD c7747c7), the whole branch. This pass is weighted toward what f9feb2c (iteration 2's fixes) changed. Code files: `test/skills/{eval-helpers,generate-reports,runner-contract}.bash`, `test/skills/arithmetic-eval/{mode1-equiv.py,after-denial-patterns.bash}`, `test/skills/{arithmetic-eval-eval,arithmetic-eval-after-denial-patterns,mode1-equiv}.bats`, `devcontainer-config/install.sh` (`procs_in_checkout`, `agent_gate`). The prose that restates code (log #56, the DD doc's "As built" section) is reviewed only as a copy of a code contract.
**Date:** 2026-09-25
**Based on:** `docs/reviews/code-fact-check-report.md` (Commit c7747c7, 35 claims). This review does not re-verify behavior that report established. It builds on Claims 2b, 5b, 6, 8, 14, 16, 17 and 23b.

**Scope check.** Three trigger categories apply:
- *Public APIs:* the check vocabulary. `tool_called:` and `no_tool_called:` now share `tool_inputs_checked` and `match_inputs`. `assert_mode1_equiv` now interprets the checker's exit 2. `mode1-equiv.py` gains `--check-spec`.
- *Cross-cutting:* the deny-record session configuration. There is now one `DENY_RECORD_FLAGS` array, `CLAUDE_FLAGS` is refused outright, and the init-event canary is new. The install gate's detection pipeline also changed: the blind-scan NOTE is new.
- *Module structure:* a new sourced data module, `arithmetic-eval/after-denial-patterns.bash`, with its own offline suite.

**Trust-boundary cross-reference.** The newest security review is `docs/reviews/security-review-2026-09-25-q062-q063-iter2.md` (Commit: `d8c43ae`). It predates this HEAD, so its boundaries may be stale. The findings below use three of its labels:
- `B3`: stream-json transcript → tripwire (generator jq + mode1-equiv.py) → `.failed` marker / grading verdict.
- `B5`: same-uid `/proc` entries → `procs_in_checkout` → the `agent_gate` decision.
- `B6`: fixture-author check specs → `parse_expected` / the assert EREs → pass or fail.

No recommendation below moves a boundary crossing.

**Not re-filed (settled or owned elsewhere):**
- C8, C13, C14 and C24 are unchanged in substance. C24 gets one Informational note because its surface grew (Finding 6).
- The fast-gate failure (Claims 8 and 29c) is the orchestrator's to fix.
- The NOTE-versus-PID-namespace question (Claim 2b) belongs to security-reviewer.
- Also not re-filed: A1/Q-064, C3, C4, C5, C6, C9, C15, trap RETURN, `--tools` variadic and the RUNNER_ALLOWED_TOOLS naming.

## Dependency Map

The harness layering is the same as in iteration 2:

`runner.bash` → `runner-contract.bash` (validates the settings) → `generate-reports.bash` (pins `DENY_RECORD_FLAGS`, refuses `CLAUDE_FLAGS`, runs the tripwire and the canary, writes `.failed`) → `eval-helpers.bash` (`eval_fixture` dispatcher → check functions) → the skill-owned `test/skills/<skill>/mode1-equiv.py`.

What f9feb2c changed:

- **The check layer.** `assert_tool_called` and `assert_no_tool_called` are now two thin policies over two shared primitives:
  - `tool_inputs_checked` reads the transcript and checks the tool name against the init event;
  - `match_inputs` runs a checked ERE match.

  This is the right factoring. The asymmetry that A13 fixed cannot come back through a divergent copy.
- **Stream-json schema knowledge.** It lives in three parsers, and none of them is shared:
  - jq in the generator: the result state, the tripwire, and the init tools and version;
  - jq in eval-helpers: tool inputs, the init tools, sub-agents;
  - Python in `mode1-equiv.py`: the events, the Bash calls, the denials.

  The init-tools selector is now spelled identically in two files (Finding 1).
- **mode1-equiv.py.** Its exit contract now has a consumer. `assert_mode1_equiv` maps rc 2 to a setup-error label, and a fast pre-flight test calls `--check-spec`. The shared dispatcher therefore depends on the checker's three-way exit protocol (Finding 6).
- **Patterns module.** `after-denial-patterns.bash` is a data module with two consumers, the eval suite (graded) and the offline pattern suite. The dependency points the right way: tests → data.
- **install.sh.** The dependency still runs gate → detector → `/proc`. The detector now reports its results on three channels: the return code, stdout and stderr (Finding 4).

## Findings

#### 1. mode1-equiv.py's SetupError boundary is drawn around file I/O, not around the transcript's shape. The three stream-json parsers disagree on what a malformed line means, so a transcript the generator accepts can crash the checker into "model failed"

**Severity:** Minor
**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:95-114`, `:148-191`; `test/skills/generate-reports.bash:281-282`; `test/skills/eval-helpers.bash:387`
**Move:** #3 module boundary (the exit-code contract), #7 coupling surface (schema knowledge duplicated)
**Confidence:** High (the mechanism, per fact-check Claim 14, executed). Low for how often it happens in practice.
**Legibility-target:** for-author

**Evidence (verbatim):**
```python
# test/skills/arithmetic-eval/mode1-equiv.py:95-114 (events and bash_calls, whole functions)
def events(transcript_path):
    out = []
    for line in read_text(transcript_path).split("\n"):
        try:
            out.append(json.loads(line))
        except ValueError:
            continue  # a stray non-JSON line, as the other transcript checks allow
    return out


def bash_calls(evs):
    """[(tool_use id, command)] for every Bash call, at any depth."""
    calls = []
    for ev in evs:
        if ev.get("type") != "assistant":
            continue
        for block in (ev.get("message") or {}).get("content") or []:
            if block.get("type") == "tool_use" and block.get("name") == "Bash":
                calls.append((block.get("id"), (block.get("input") or {}).get("command", "")))
    return calls
```
```python
# test/skills/arithmetic-eval/mode1-equiv.py:159-166 (inside main, :148-191; the per-call loop follows at :172-191)
        evs = events(transcript_path)
    except SetupError as e:
        print("mode1-equiv: " + str(e), file=sys.stderr)
        return 2
    calls = bash_calls(evs)

    denied = {d.get("tool_use_id") for ev in evs if ev.get("type") == "result"
              for d in ev.get("permission_denials") or []}
```
```bash
# test/skills/generate-reports.bash:281-282 (inside generate_one, :138-299)
      init_tools=$(jq -rR 'fromjson? | select(.type == "system" and .subtype == "init") | .tools[]?' \
        "$transcript_path" 2>/dev/null || true)
```
```bash
# test/skills/eval-helpers.bash:387 (inside tool_inputs_checked, :381-393)
  known="$(jq -rR 'fromjson? | select(.type == "system" and .subtype == "init") | .tools[]?' "$t" 2>/dev/null || true)"
```

The docstring promises that no setup error can "escape as a traceback with exit 1, which would read as 'the model did not compute the value'". But the `try` closes after `events()`, and `events()` checks only that each line is JSON. It does not check that the line is an event. The first use of a line's shape (`ev.get`, `block.get`, `.get("command")`, later `cmd.strip`) is outside the boundary. Claim 14 shows that each of the four wrong shapes tracebacks with exit 1. The dispatcher labels only rc 2 (`eval-helpers.bash:483-485`), so such a run reads as a routing failure.

The underlying problem is structural. A malformed transcript is neither a model result (exit 1) nor a fixture-author error (the spec). It is a failed generation, and the harness's channel for that is the generator's `.failed` marker. The generator validates with jq's `fromjson?` and `[]?`, which skip what they cannot index. So the generator (the validator) is looser than the checker (the consumer), and a transcript the generator passes can still crash the checker. That sits on `B3` from `docs/reviews/security-review-2026-09-25-q062-q063-iter2.md` (Commit: `d8c43ae` — the security review predates this diff, so the boundary may be stale). The two sides of `B3` apply different policies to the same input.

The init-tools selector is now spelled identically in two files. The generator's canary and `tool_inputs_checked` both depend on it, so a schema change (a renamed `subtype`, `tools` moved under another key) must be made twice. If it is made in only one file, that side fails open (see Finding 2). C8 is the tripwire copy, and this is a second instance of the same pattern, new in f9feb2c.

**Recommendation:** Make `events()` the shape boundary. It should keep only `dict` events and raise `SetupError` (exit 2, "transcript line N is not a stream-json event") on a non-dict line. `bash_calls` should do the same for a non-list `content`, a non-dict block or `input`, or a non-string `command`, so every input problem gets the labelled exit 2 and never exit 1. Either give the init-tools selector one name, or put a comment at each copy pointing to the other, as C8's pair would need too.

#### 2. The fail-closed guarantee of the transcript checks lives upstream, in the generator's result-event check and `eval_fixture`'s `.failed` gate, not in the check layer that documents it

**Severity:** Minor
**Location:** `test/skills/eval-helpers.bash:376-393` (`tool_inputs_checked`), `:449-462` (`assert_no_tool_called`); `test/skills/mode1-equiv.bats:36-41` (the synthetic `transcript()` helper)
**Move:** #6 substitutability (the contract a function states versus the one it keeps), #3 module boundary
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# test/skills/eval-helpers.bash:376-393 (comment and whole function)
# tool_inputs_checked <transcript> <tool>: print the tool's inputs (as
# transcript_tool_inputs does), or fail with a message when the transcript
# cannot be parsed, or when its init event lists the run's tools and <tool> is
# not one of them (a misspelled name such as "bash" would otherwise match
# nothing and let a negative check pass).
tool_inputs_checked() {
  local t="$1" tool="$2" inputs known
  if ! inputs="$(transcript_tool_inputs "$t" "$tool")"; then
    echo "Could not read tool calls from $t"
    return 1
  fi
  known="$(jq -rR 'fromjson? | select(.type == "system" and .subtype == "init") | .tools[]?' "$t" 2>/dev/null || true)"
  if [ -n "$known" ] && ! printf '%s\n' "$known" | grep -qxF -e "$tool"; then
    echo "$tool is not a tool of this run (its tools: $(printf '%s\n' "$known" | tr '\n' ' '))"
    return 1
  fi
  printf '%s' "$inputs"
}
```
```bash
# test/skills/mode1-equiv.bats:36-41 (whole helper)
transcript() {
  local denials='[{"tool_name":"Bash","tool_use_id":"b1","tool_input":{}}]'
  [ "${2:-yes}" = yes ] || denials='[]'
  jq -nc --arg c "$1" '{type:"assistant",parent_tool_use_id:null,message:{content:[{type:"tool_use",id:"b1",name:"Bash",input:{command:$c}}]}}' > "$T"
  jq -nc --argjson d "$denials" '{type:"result",subtype:"success",result:"# Report",permission_denials:$d}' >> "$T"
}
```

A12 set out to make `no_tool_called` fail closed. The check layer does so only when the file is unreadable, or when an init event exists (Claims 16 and 17). A transcript with no parseable events therefore passes `no_tool_called:<anything>`, a misspelled name included. What keeps a real run safe is a chain of three other modules:
1. `generate_one` writes `.failed` when no result event exists;
2. `eval_fixture` refuses any fixture that has a `.failed` marker;
3. the deny-record canary voids a run whose init event is missing.

So the invariant "a run with no evidence cannot pass a negative check" is held by the dispatcher and the generator, while the function whose comment claims it does not hold it. That matters in two places. The public `assert_*` functions are called directly, by `mode1-equiv.bats` today and by any future suite. And the check behaves differently depending on whether an init event is present. Its `[ -n "$known" ]` guard exists because the synthetic transcripts have no init event, while every real stream-json run does (the canary depends on that). The tests have shaped the production check around a transcript shape that production never produces.

Recommendation not relocating `B3` or `B6` (security-review iter2, Commit `d8c43ae`, predates this diff): this moves an invariant into the check layer. It does not move a trust transition.

**Recommendation:** Have `tool_inputs_checked` require an init event: "no init event in $t: cannot tell which tools the run had". Then the tool-name check is unconditional, and a junk transcript fails at the check itself. Have the `transcript()` test helper emit an init event listing Bash. If a check must also serve transcripts without an init event, correct the comment instead, so it says the guarantee comes from `eval_fixture`'s `.failed` gate (Claim 16's wording).

#### 3. C21's single source holds in code but not in prose. The DD doc still restates the flags and the retired denylist, and the `CLAUDE_FLAGS` policy has no named anchor, so log #56 restated it and it drifted

**Severity:** Minor
**Location:** `docs/working/dd-arith-eval-bash-grant.md:173-175`; `docs/decisions/log.md:77`; `test/skills/generate-reports.bash:115-129`
**Move:** #7 coupling surface (a contract kept by hand in several copies)
**Confidence:** High
**Legibility-target:** for-author

**Evidence (verbatim):**
```text
# docs/working/dd-arith-eval-bash-grant.md:173-174 (first two bullets of "As built", :171-182)
- **Deny flags.** `generate-reports.bash` pins `--disallowedTools 'Bash(**)' --permission-mode dontAsk --permission-prompts none`. …[remainder of the bullet: the probe results]
- **Contract.** `FIXTURE_BASH=deny-record` needs `FIXTURE_TRANSCRIPT=1` and `FIXTURE_TOOLS=Bash` exactly. Under it, `CLAUDE_FLAGS` may not name `--permission-mode`, `--permission-prompt*`, `--allowedTools`, `--settings` or the skip-permission flags, and whitespace of any kind separates flags.
```
```text
# docs/decisions/log.md:77 (row #56, one sentence of the decision column; the rationale and reference columns follow)
Under deny-record the generator refuses permission-changing `CLAUDE_FLAGS`, and it voids a run if any Bash call is missing from `permission_denials` (tripwire).
```
```bash
# test/skills/generate-reports.bash:115-116 (start of the comment above DENY_RECORD_FLAGS, :115-120)
# The flags that make every Bash call denied and recorded under deny-record
# (Q-063 [1]). The one definition: the prose elsewhere points here. Probed
```

The fix for C21 is correct as code: one array, one expansion (Claim 23a). But its comment claims more than holds: "the prose elsewhere points here" (Claim 23b). The DD doc's "As built" section still lists the flags, and in the next bullet it describes the denylist that f9feb2c deleted, with no mention of the canary (Claim 6).

The deny-record configuration is really three rules:
1. which flags are pinned (`DENY_RECORD_FLAGS`);
2. what the operator may add (nothing: `CLAUDE_FLAGS` is refused, `CLAUDE_MODEL` passes as one argv element);
3. what voids a run (the tripwire and the canary).

Only rule 1 got a name that prose can point to. Rules 2 and 3 are still restated in each doc. Log #56 had the rule 1 part of its headline fixed in f9feb2c, yet its rule 2 sentence went stale in the same commit (Claim 5b). This is the drift pattern iteration 2's F3 predicted, now in the part of the configuration that was not consolidated.

**Recommendation:** Treat the `FIXTURE_BASH` header in `generate-reports.bash:31-37` as the anchor for all three rules, since it already states them. Replace the DD doc's Deny flags and Contract restatements with a pointer there, keeping the probe history, which is the DD doc's own content. Change log #56's sentence to "refuses any `CLAUDE_FLAGS`" and add the canary. Or drop "the prose elsewhere points here" from the code comment until that is true.

#### 4. `procs_in_checkout` now reports on three channels, and each new state picked its own: the gate writes the rc 2/3 text, stdout carries the hits, and the detector writes the blind-scan NOTE straight to stderr

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:1151-1170` (`procs_in_checkout`), `:1188-1199` (inside `agent_gate`, :1175-1254), `:1208-1209`
**Move:** #3 module boundary, #8 extension points
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# devcontainer-config/install.sh:1166-1170 (end of procs_in_checkout, :1151-1170)
  if [ "$readable" -eq 0 ]; then
    echo "NOTE: no process's working directory could be read under /proc, not even this" >&2
    echo "      script's own: the check for processes inside the checkout saw nothing (Q-062)." >&2
  fi
}
```
```bash
# devcontainer-config/install.sh:1188-1199 (inside agent_gate; the de-duplication follows at :1200-1205)
  rc=0
  local inrepo
  inrepo="$(procs_in_checkout)" || rc=$?
  if [ "$rc" -eq 3 ]; then
    echo "ERROR: could not resolve the checkout's path ($REPO_ROOT), so install.sh cannot" >&2
    echo "       check for processes working inside it (Q-062). $what" >&2
    exit 1
  elif [ "$rc" -ne 0 ]; then
    echo "ERROR: /proc is not mounted, so install.sh cannot check for processes working" >&2
    echo "       inside the checkout (Q-062). It needs Linux /proc. $what" >&2
    exit 1
  fi
```
```bash
# devcontainer-config/install.sh:1208-1209 (inside agent_gate)
  if ! command -v docker >/dev/null 2>&1; then
    echo "NOTE: docker not found: cc-isolated containers not checked, treated as none running."
```

Iteration 2's F4 recommended one interface between the detector and the gate: tagged output, with the detector owning its cause text. f9feb2c instead added a fourth outcome, "scanned, but blind", through a third channel. The detector's stderr escapes the command substitution, so the NOTE bypasses the gate entirely. It also differs from the gate's other NOTE: the docker NOTE goes to stdout, and the unreachable-docker NOTE also passes through `vis_or_die`. So user-facing text for one check now comes from two functions under two conventions.

The gate cannot tell a blind scan from a clean one, so it cannot change its policy for that case (refuse, or say so once rather than at each of the up to four checks per install). The blindness test is a zero count, and an interface that only reports a count cannot express partial blindness. Whether that matters for PID namespaces is Claim 2b's question, left to security-reviewer. Q-064 [3] ("a NOTE lists each one") would add a fifth outcome, whose natural home is again the detector's stderr. The pattern is set: each new state takes whichever channel was easiest.

This sits on `B5` from `docs/reviews/security-review-2026-09-25-q062-q063-iter2.md` (Commit: `d8c43ae` — the security review predates this diff, so the boundary may be stale). The recommendation keeps the transition point in `procs_in_checkout` + `agent_gate`.

**Recommendation:** Keep all text in the gate. Have the detector signal "blind" as data, with a distinct return code (e.g. 4 = scanned, nothing readable) or a tagged line. `agent_gate` then prints the NOTE through the same path as its other NOTEs. Do this with Q-064's answer at the latest, since [3] needs the same channel for its per-process list.

#### 5. The offline pattern suite re-implements the grader's matcher instead of calling it. Calling the real assert functions would also remove the `!` construct behind Claim 8

**Severity:** Minor
**Location:** `test/skills/arithmetic-eval-after-denial-patterns.bats:11-12`, `:20-28`; `test/skills/arithmetic-eval-eval.bats:48-58`; `test/skills/eval-helpers.bash:299-317`
**Move:** #7 coupling surface (duplicated semantics)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# test/skills/arithmetic-eval-after-denial-patterns.bats:11-12 (whole helper)
# hits <ERE> <phrase>: grep -iE, as assert_report_(not_)matches use it.
hits() { printf '%s\n' "$2" | grep -qiE "$1"; }
```
```bash
# test/skills/arithmetic-eval-eval.bats:55-57 (end of after_denial, :48-58)
  assert_report_matches "$NOT_VERIFIED_RE" || return 1
  assert_report_not_matches "$VERDICT_RE" || return 1
  [ -z "${FIGURE_RE[$1]:-}" ] || assert_report_not_matches "${FIGURE_RE[$1]}"
```

Moving the patterns into a data module (C23) was the right call: the graded suite and its tests now share one definition. But the offline suite validates the patterns against a local copy of the matching rule ("as assert_report_(not_)matches use it"), not against the functions that grade. The patterns are only half of the grade. The other half is how `assert_report_matches` and `assert_report_not_matches` apply them: `echo` versus `printf`, line-based `grep`, `-i`. If those change (a switch to `field_values`, to multi-line matching, or to a different grep), the offline tests stay green while the graded behavior moves.

The negative assertions in the pattern suite are written as `! hits …`. Claim 8 shows that form is vacuous in bats when it is not the test's last line. If the suite called `assert_report_not_matches` with `REPORT_CONTENT` set, each negative would be an ordinary assertion that returns 1 on a hit, and the construct behind Claim 8 would go away.

**Recommendation:** `load eval-helpers` in the pattern suite, and assert through `REPORT_CONTENT="$phrase" assert_report_matches "$RE"` and `REPORT_CONTENT="$phrase" assert_report_not_matches "$RE"`, or a helper that wraps exactly those two calls. That gives the orchestrator's Claim 8 fix a form that cannot be vacuous.

#### 6. The skill-owned checker hook now has a de facto interface (argv, a 0/1/2 exit protocol, `--check-spec`), documented only in arithmetic-eval's checker

**Severity:** Informational
**Location:** `test/skills/eval-helpers.bash:464-487`; `test/skills/arithmetic-eval/mode1-equiv.py:22-34`; `test/skills/mode1-equiv.bats:224-234`
**Move:** #8 extension points
**Confidence:** High
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# test/skills/eval-helpers.bash:481-486 (inside assert_mode1_equiv, :473-487)
  local rc=0
  python3 "$checker" "${BATS_TEST_DIRNAME}/../../skills/${skill}/SKILL.md" "$t" "$spec" 2>&1 || rc=$?
  if [ "$rc" -eq 2 ]; then
    echo "mode1_equiv: FIXTURE/CHECKER SETUP ERROR (exit 2), not a model result — fix the spec '$spec' or the checker's inputs"
  fi
  [ "$rc" -eq 0 ]
```
```bash
# test/skills/mode1-equiv.bats:226 (inside the pre-flight test, :224-234)
  specs="$(grep '^KEY_CHECK' "$BATS_TEST_DIRNAME/arithmetic-eval/expected-verdicts.bash" | grep -o 'mode1_equiv:[^;"]*')"
```

This does not reopen C24 (naming, Deferred). It notes that the hook's surface grew in f9feb2c, as iteration 2's F2 recommended. The shared dispatcher now assigns meaning to exit 2, and the pre-flight test relies on a `--check-spec` mode. A second skill's checker would have to implement both. The only statement of that contract is `mode1-equiv.py`'s docstring, and the pre-flight test reads only arithmetic-eval's specs. That is fine with one user. It is the list to write down on the day C24's revisit trigger fires.

**Recommendation:** None now. When C24 is revisited, put the hook contract (argv order, exit 0/1/2, `--check-spec <SKILL.md> <spec>`) in the comment above `assert_mode1_equiv`, and make the pre-flight test loop over every `test/skills/*/mode1-equiv.py`.

## What Looks Good

- **`tool_called` and `no_tool_called` are now one read primitive plus one match primitive, with two small policies on top.** A13's asymmetry (bare `tool_called:X` meaning "input matches /X/") cannot come back through a copy, and `match_inputs`'s exit-2 channel is checked by both callers in the same way. The dispatcher tests (C18) run `eval_fixture` itself, so the parsing arm is covered, not only the assert functions.
- **Refusing `CLAUDE_FLAGS` outright dissolves iteration 2's hand-kept inverse.** The refusal list that mirrored the pinned flags, and missed `--tools`, is gone. It is replaced by a rule with nothing to keep in sync, and `CLAUDE_MODEL` is narrowed to one argv element. That is a smaller surface, not a longer list.
- **`DENY_RECORD_FLAGS` sits next to its only use.** Iteration 2 suggested putting it in `runner-contract.bash`. Keeping it in the generator is equally sound: the contract validates runner settings, the generator owns argv, and the contract's comment points to the array by name.
- **The exit-2 state now has consumers on both sides of a paid run.** `--check-spec` plus the pre-flight test catch a bad spec before any run, and `assert_mode1_equiv` labels a grade-time exit 2. Iteration 2's F2 is resolved in the form it recommended.
- **The canary closes the one silent failure mode of deny-by-rule.** If `Bash(**)` ever removes the tool, every run is voided with the CLI version recorded, instead of every fixture reading as "did not route".
- **The patterns are a data module with dependencies pointing inward.** Both the graded suite and the offline suite depend on `after-denial-patterns.bash`, which depends on nothing. `FIGURE_RE` is keyed exactly like `KEY_CHECK`.
- **install.sh's dependency direction is intact.** The gate calls the detector, the detector reads `/proc`, and nothing flows back. The lineage exemption is a pure helper pair (`ppid_of`, `in_lineage`).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The SetupError boundary stops at file I/O. Transcript-shape errors traceback as exit 1 ("model failed"). Three stream-json parsers disagree on malformed lines, and the init selector is duplicated | Minor | `mode1-equiv.py:95-114, 148-191`; `generate-reports.bash:281-282`; `eval-helpers.bash:387` | High (mechanism) / Low (frequency) |
| 2 | The transcript checks' fail-closed guarantee lives in the generator and `.failed`, not in `tool_inputs_checked`. The init check is conditional because the test transcripts have no init event | Minor | `eval-helpers.bash:376-393, 449-462`; `mode1-equiv.bats:36-41` | Medium |
| 3 | C21 residual: the DD doc restates the flags and the retired denylist. The `CLAUDE_FLAGS` and void rules have no named anchor, and log #56 drifted | Minor | `dd-arith-eval-bash-grant.md:173-175`; `log.md:77`; `generate-reports.bash:115-129` | High |
| 4 | The detector reports on three channels. The blind NOTE is written by the detector to stderr, bypassing the gate and its NOTE conventions. Q-064 [3] will add a fourth | Minor | `install.sh:1151-1170, 1188-1199, 1208-1209` | Medium |
| 5 | The pattern suite re-implements the grader's matcher. Calling `assert_report_(not_)matches` would also remove Claim 8's vacuous `!` | Minor | `arithmetic-eval-after-denial-patterns.bats:11-28`; `eval-helpers.bash:299-317` | Medium |
| 6 | The skill-owned checker hook has a de facto 0/1/2 and `--check-spec` interface, documented only in one checker (C24-adjacent, not reopened) | Informational | `eval-helpers.bash:464-487`; `mode1-equiv.py:22-34`; `mode1-equiv.bats:224-234` | High |

## Overall Assessment

f9feb2c leaves the branch structurally sound, and in two places it improves on iteration 2:
- the check layer is now properly factored;
- refusing `CLAUDE_FLAGS` outright replaces a hand-kept inverse with a rule that needs no upkeep.

There are no Structural or Coupling findings. All five Minor findings can be fixed in place, and none needs restructuring. The common thread is that a guarantee sits somewhere other than where it is documented:
- the checker's exit contract is kept only for file errors (F1);
- the negative checks fail closed only through the dispatcher (F2);
- the single source is single only in code (F3);
- the gate owns the text for only some detector states (F4);
- the pattern tests check a copy of the matcher (F5).

The most important concern is F2. It is the only one where a check can pass when it should fail, and the fix is small: require the init event that every real run carries, and make the test transcripts carry one too. F1 is the closest relative. It fails in the other direction (a spurious "model failed"), and it has the same root: the stream-json schema has no single parser.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown critique saved to the path named in your role section below, structured per your skill."
- **Answered:** Saved to `docs/reviews/architecture-review-2026-09-25-q062-q063-iter3.md`, with `Commit: c7747c7` at the top. Not committed. Each focus area is covered:
  - the eval-helpers check layer and the mode1_equiv hook: F2, F6, What Looks Good;
  - mode1-equiv.py's SetupError boundary versus transcript-shape errors: F1;
  - the patterns file sourced by an eval suite: F5, What Looks Good;
  - `DENY_RECORD_FLAGS` as the single source versus its prose copies: F3;
  - install.sh gate growth: F4.

  Every finding carries a Severity, Location, verbatim Evidence, Confidence and Legibility-target.
- **Fix checks (iteration 1 and 2):**
  - A12's fix is correct for the paths it names, but the fail-closed property is incomplete at the check layer (F2).
  - A11's boundary is correct for the enumerated setup errors, but not for the transcript's shape (F1).
  - C21 is complete in code and incomplete in prose (F3).
  - Iteration 2's F2 (exit 2 has no consumer) is resolved.
  - Iteration 2's F3 (the hand-kept refusal inverse) is resolved by the outright refusal.
  - Iteration 2's F4 is not restructured, and f9feb2c added a new channel (F4).
  - No regressions in dependency direction.
- **Out of scope:**
  - Whether the blind NOTE should fire for PID-namespaced scans (Claim 2b): security-reviewer.
  - The health-check gate failure (Claims 8 and 29c): the orchestrator. F5 only offers a structural form for the fix.
  - The settled items: C3, C4, C5, C6, C8, C9, C13, C14, C15, C24, A1/Q-064, trap RETURN, `--tools` variadic, the RUNNER_ALLOWED_TOOLS naming.
- **Escalate:**
  - To the orchestrator: F5's recommendation doubles as the Claim 8 fix.
  - To security-reviewer: `B3` in the iteration-2 map names "generator jq + mode1-equiv.py" as one transition point, but the two halves apply different malformed-input policies (F1). Whether that matters for trust is theirs to judge.
- **Questions:** For F2, should `tool_inputs_checked` require an init event? That is safe only if every FIXTURE_TRANSCRIPT=1 run emits one. The canary already assumes it for deny-record runs, and Claim 26 notes it cannot be verified offline.
- **Decisions:** None made. All recommendations are left to the author.
