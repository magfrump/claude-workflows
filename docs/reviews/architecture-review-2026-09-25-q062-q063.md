Commit: 5ddf804

# Architecture Review — skill-fixtures (Q-062 [2], Q-063 [1])

**Scope:** branch diff `git diff main...HEAD` (skill-fixtures at 5ddf804), code files: `devcontainer-config/install.sh`, `test/skills/{eval-helpers,generate-reports,runner-contract}.bash`, `test/skills/arithmetic-eval/{mode1-equiv.py,runner.bash,expected-verdicts.bash}`, and the test suites that pin them. Doc-only files are excluded from structural findings.
**Date:** 2026-09-25
**Based on:** `docs/reviews/code-fact-check-report.md` (Commit 5ddf804, 38 claims). Behavior the report verified is not re-verified here. Claim ids are cited where a finding builds on one.

**Scope check.** Three trigger categories apply. *Public APIs / data models:* the `KEY_CHECK` check vocabulary gains `mode1_equiv:` and `no_tool_called:`, and the runner contract (`runner.bash` settings) gains `FIXTURE_BASH`. *Cross-cutting concerns:* the shared eval dispatcher and the generator's permission and run-validity pipeline change. *Module structure:* a new skill-specific checker module, `arithmetic-eval/mode1-equiv.py`. install.sh's `agent_gate` is a cross-cutting guard called at four points (fact-check Claim 8), so it is in scope as well.

**Trust-boundary cross-reference.** The newest security review is `docs/reviews/security-review-2026-09-25-copy-install-q058-pass4.md` (Commit: `f5e3029`). That security review predates this diff, so its boundaries may be stale. Its map has B1–B4: git state, the devcontainer stage, `$DEST`, and the host copies. None of them is placed at `agent_gate` or the fixture harness, so no finding below sits on a labeled boundary, and this section has no effect on the findings.

## Dependency Map

**Fixture harness.** The layering is:

`runner.bash` (per-skill config) → `runner-contract.bash` (validation) → `generate-reports.bash` (claude run; writes `report.md`, `transcript.jsonl` and `.failed`) → `eval-helpers.bash` (shared check dispatcher, used by about 20 `<skill>-eval.bats`) → per-check assertion functions.

Before this branch, the dispatcher reached skill-specific code in one way only, by naming convention: `format_check` runs `${skill}-format.bats`. This branch adds a second way. The shared dispatcher now calls `arithmetic-eval/mode1-equiv.py` and reads `skills/arithmetic-eval/SKILL.md` by literal paths. So the stable, shared module now depends on one volatile skill.

Two consumers now enforce the deny-record invariant: the generator (jq, writing `.failed`) and `mode1-equiv.py` (Python). `eval_fixture` already reads `.failed` for every skill.

Four places now depend on the layout of SKILL.md's Mode 1 block: `arithmetic-eval-gate.bats` (awk, existed before), `mode1-equiv.bats` (awk, new), `mode1-equiv.py`'s `reference()`, and `WRAPPER_RE` (a regex, new).

**install.sh.** `agent_gate` is called at startup, before host staging, and after each y (fact-check Claim 8). It used to hold two detectors: pgrep for a Claude command line, and docker for cc-isolated containers. It now holds a third, `procs_in_checkout`, a /proc cwd scan built on `in_lineage` and `ppid_of`. The dependencies point one way: gate → detectors → /proc. No detector calls back into the gate.

## Findings

#### 1. The shared check dispatcher hard-codes one skill's checker and SKILL.md

**Severity:** Coupling
**Location:** `test/skills/eval-helpers.bash:156-158`, `test/skills/eval-helpers.bash:419-424`
**Move:** #1 dependency direction, #8 extension points
**Confidence:** High
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# test/skills/eval-helpers.bash:419-424 (whole function)
assert_mode1_equiv() {
  local spec="$1" t
  t="$(eval_transcript_path)" || { echo "$t"; return 1; }
  python3 "${BATS_TEST_DIRNAME}/arithmetic-eval/mode1-equiv.py" \
    "${BATS_TEST_DIRNAME}/../../skills/arithmetic-eval/SKILL.md" "$t" "$spec"
}
```
Prior art in the same dispatcher (`eval_fixture`, `:58-170`) finds skill-specific code from `$skill`:
```bash
# test/skills/eval-helpers.bash:159-162 (one case arm; eval_fixture continues to :170)
      format_check)
        # Delegate to the skill's format suite, test/skills/<skill>-format.bats
        REPORT_PATH="$REPORT_PATH" bats "${BATS_TEST_DIRNAME}/${skill}-format.bats" || failed=1
        ;;
```

`eval-helpers.bash` is shared infrastructure that about 20 skills load. This branch gives it a check whose name reads as generic (`mode1_equiv:`) but which is fixed to one skill: its checker path and its SKILL.md path are both literals. If any other skill's `KEY_CHECK` used `mode1_equiv:`, it would silently be graded against arithmetic-eval's SKILL.md. The next skill that needs a "compare the attempted command with a reference" check (the deny-record mode is now open to any runner) would add another literal arm and another `assert_*` function to the shared file. That makes the `case` a switch that grows with each skill, and it makes the shared module change whenever one skill's layout changes. The pattern set here is the one the next skill will copy, so it is cheapest to fix now, while there is one instance.

**Recommendation:** Resolve the checker from `$skill`, as `format_check` does. For example, `mode1_equiv:` → `${BATS_TEST_DIRNAME}/${skill}/mode1-equiv.py` with `skills/${skill}/SKILL.md`. Or add one generic arm, e.g. `skill_check:<name>:<args>` → `${skill}/checks/<name>`. Either way, a skill-specific checker becomes a file in that skill's directory, and eval-helpers.bash does not change for it. If you keep it as is, rename it to something skill-scoped (`arith_mode1_equiv:`) so the name does not promise generality.

#### 2. WRAPPER_RE is a second, hand-kept spec of SKILL.md's wrapper, and the fourth extractor of the Mode 1 block

**Severity:** Minor
**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:33-52`; also `test/skills/mode1-equiv.bats:20-22` and `test/skills/arithmetic-eval-gate.bats:22-23`
**Move:** #7 coupling surface
**Confidence:** High
**Legibility-target:** for-author

**Evidence (verbatim):**
```python
# test/skills/arithmetic-eval/mode1-equiv.py:33-40 (whole statement)
WRAPPER_RE = re.compile(
    r"\A\( ulimit -t 5 -v 1000000 2>/dev/null; timeout 5 python3 -c '\n"
    r"(?P<program>[^']*)\n"
    r"' \) <<'EXPREOF'\n"
    r"(?P<expr>.*?)\n"
    r"EXPREOF(?P<tail>(\n[ \t]*(#[^\n]*)?)*)\Z",
    re.S,
)
```
```python
# test/skills/arithmetic-eval/mode1-equiv.py:49-51 (inside reference(), :43-52; the function's last line, :52, returns the program and its ast.dump)
    w = WRAPPER_RE.match(m.group(1).strip("\n"))
    if not w:
        sys.exit("mode1-equiv: SKILL.md's own Mode 1 block does not match the wrapper pattern")
```

The check is described as comparing against "SKILL.md's Mode 1 wrapper exactly". In fact, only the *program* comes from SKILL.md. The *wrapper*, including the ulimit values and the heredoc terminator rule, is a copy written into the regex, and SKILL.md is only asserted to match it. So the reference is split across two files, and a SKILL.md wrapper edit (a new `ulimit -v`, say) needs a matching regex edit. The coupling fails loudly (`reference()` exits, and `mode1-equiv.bats` test 1 extracts the block), so it is not a silent-drift risk. The structural cost is that the regex has become the place where the contract actually lives, and it differs from the source it claims to mirror.

Fact-check Claim 22 (Incorrect) shows this concretely. The lazy `expr` group reads past bash's first `EXPREOF`, so "wrapper exact … only comments after the closing EXPREOF" is a property of the regex's view of the text, not bash's. SKILL.md itself states the rule the regex does not encode (`skills/arithmetic-eval/SKILL.md:39`: "check the untrusted expression contains no bare line equal to the delimiter `EXPREOF`; if it does, reject it"). Three awk/regex extractors (the gate suite, `mode1-equiv.bats` and `reference()`) each key on a different anchor: the `python3 -c '` line, `## Mode 1` plus the first fence, and `## Mode 1` plus a `# →` filter.

**Recommendation:** Derive the wrapper from the extracted block. Split SKILL.md's block into prefix, program, heredoc line, body and terminator, then require the model's command to equal the prefix and suffix literally. Refuse any body line equal to the terminator, which is SKILL.md:39's own rule. That removes the hand-kept copy and makes the "exact" wording true. You could also give `mode1-equiv.bats` the extraction from `mode1-equiv.py` (for example with a `--print-reference` flag), so the new code has one extractor rather than two. The contract-accuracy side of Claim 22 goes to api-consistency and security.

#### 3. The deny-record run-validity rule is implemented twice, and once inside a check

**Severity:** Minor
**Location:** `test/skills/generate-reports.bash:249-260`; `test/skills/arithmetic-eval/mode1-equiv.py:107-112`; `test/skills/arithmetic-eval-eval.bats:44-52`
**Move:** #2 responsibility boundaries, #7 coupling surface
**Confidence:** High
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# test/skills/generate-reports.bash:249-260 (inside generate_one, :133-271; the failure is written to .failed at :263-264)
    # Tripwire (deny-record): every Bash tool_use must be listed as denied. One
    # that is not may have run, so the whole run is void.
    if [ -z "$failure" ] && [ "$FIXTURE_BASH" = "deny-record" ]; then
      local undenied
      undenied=$(jq -rRn '[inputs | fromjson?] as $ev
        | ([$ev[] | select(.type == "result") | .permission_denials[]?.tool_use_id]) as $denied
        | [$ev[] | select(.type == "assistant") | .message.content[]?
           | select(.type == "tool_use" and .name == "Bash") | .id]
        | map(select(. as $id | $denied | index($id) | not)) | length' \
        "$transcript_path" 2>/dev/null) || undenied="unreadable"
      [ "$undenied" = 0 ] || failure="Bash tripwire: $undenied Bash call(s) not in permission_denials (may have executed)"
    fi
```
```python
# test/skills/arithmetic-eval/mode1-equiv.py:107-112 (inside main(), :98-133; evaluation of calls follows at :114-133)
    denied = {d.get("tool_use_id") for ev in evs if ev.get("type") == "result"
              for d in ev.get("permission_denials") or []}
    undenied = [cid for cid, _ in calls if cid not in denied]
    if undenied:
        print(f"Tripwire: {len(undenied)} Bash call(s) not in permission_denials (may have executed)")
        return 1
```
```bash
# test/skills/arithmetic-eval-eval.bats:44-52 (whole function)
after_denial() {
  load_eval_report "$SKILL" "$1"
  if [ -f "${REPORT_PATH%.report.md}.failed" ]; then
    echo "Generation failed for $1: $(cat "${REPORT_PATH%.report.md}.failed")"
    return 1
  fi
  assert_report_matches "$NOT_VERIFIED_RE" || return 1
  assert_report_not_matches "$VERDICT_RE"
}
```
(The `print` line in the second excerpt is shortened here; the source also prints `{undenied}`.)

"A deny-record run in which some Bash call was not denied is void" is a property of the *run*. The branch already routes it through the existing run-validity channel: the generator writes `.failed`, and `eval_fixture` fails any fixture that has one (`eval-helpers.bash:80-84`), for every check type. The Python copy only ever fires when that channel has been bypassed, and it covers only `mode1_equiv:` fixtures. `no_tool_called:` (tc-ae5) and the `after_denial` tests do not have it. So it adds a second place to change without extending coverage. The two versions are in different languages, and no shared test vector pins them to the same answer. The generator's test 32 and `mode1-equiv.bats` test 10 each build their own stream. A future change to the rule, such as also requiring `tool_result.is_error` (the DD doc's original tripwire wording, `dd-arith-eval-bash-grant.md:85`) or handling sub-agent denials, has to be made twice, and drift between the copies would pass silently.

Separately, `after_denial` re-implements `eval_fixture`'s failed-marker guard. That guard is only reachable inside the all-in-one `eval_fixture`, so a report-only test cannot reuse it.

**Recommendation:** Keep one enforcement point: the generator's `.failed`, which is already generic. Drop the Python copy, or keep it with a comment that it is a backstop. If you keep it, make both implementations read one shared jq filter (eval-helpers already holds the transcript jq helpers, and the generator could source them), or add a single test that runs the same streams through both. Factor `eval_fixture`'s marker and empty-report guards (`:80-91`) into a `require_valid_run` helper that `after_denial` and similar report-only tests call.

#### 4. `agent_gate` grows by editing, and its detectors are coupled through a text format

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:1158-1226` (`agent_gate`), `:1138-1154` (`procs_in_checkout`)
**Move:** #8 extension points, #7 coupling surface
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# devcontainer-config/install.sh:1171-1182 (inside agent_gate, :1158-1226; the docker detector follows at :1183-1202, then the combined empty test at :1203 and the per-detector message blocks)
  rc=0
  local inrepo
  inrepo="$(procs_in_checkout)" || rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "ERROR: /proc is not readable, so install.sh cannot check for processes working" >&2
    echo "       inside the checkout (Q-062). $what" >&2
    exit 1
  fi
  # A Claude Code process already listed above is not named twice.
  inrepo="$(printf '%s\n' "$inrepo" | awk -v seen="$procs" '
    BEGIN { n = split(seen, l, "\n"); for (i = 1; i <= n; i++) { split(l[i], f, " "); skip[f[1]] = 1 } }
    NF && !($1 in skip)')"
```
```bash
# devcontainer-config/install.sh:1140-1143 (start of procs_in_checkout, :1140-1154; the /proc loop follows at :1144-1153)
procs_in_checkout() {
  local root d pid cwd cmd
  [ -d /proc/self ] || return 2
  root="$(cd "$REPO_ROOT" && pwd -P)" || return 2
```

Adding the second process detector took edits at five sites in `agent_gate`: collect, map the error, de-duplicate, the combined empty test (`:1203`), and a message block (`:1212-1217`). Each detector's "cannot check" policy is written inline and differs between them: pgrep missing means refuse, /proc missing means refuse, docker missing means NOTE and pass.

The two process detectors are coupled through the *textual* "PID command line" format. The awk de-duplication splits `$procs` on spaces to find PIDs. So a change to either detector's output shape breaks de-duplication silently: the only effect is a process named twice, which no test covers.

The detector-to-gate interface is a bare exit code. `procs_in_checkout` returns 2 for two different causes (no `/proc`, or `cd "$REPO_ROOT"` failing), and the gate maps both to "/proc is not readable". Fact-check Claim 2 notes this misattribution. It is structural: the gate owns the message, but only the detector knows the cause.

Putting the /proc reader in install.sh is sound. The helpers are separate, pure-read functions, and dependencies point from gate to detector. The concern is the gate's shape, not where the detector lives. At three detectors this is borderline, not urgent.

**Recommendation:** When a fourth detector is proposed, or when the next gate change comes, make each detector a function that prints its own findings and its own refusal text and returns found / none / cannot-check. `agent_gate` then loops over the detector list and applies one policy. Until then, a small fix: have `procs_in_checkout` print the cause on stderr, or use distinct codes, so the gate's message is accurate.

#### 5. `FIXTURE_BASH` has a Bash-scoped name but pins a session-wide permission mode, and the contract lets it combine with other tools

**Severity:** Minor
**Location:** `test/skills/generate-reports.bash:181-183`; `test/skills/runner-contract.bash:65-87`, `:99-116`
**Move:** #7 coupling surface (control coupling), #5 interface segregation
**Confidence:** Low. The CLI's handling of non-Bash tools under `dontAsk` is not verified here, because `claude` may not be run.
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# test/skills/generate-reports.bash:180-183 (inside generate_one, :133-271)
  claude_args+=(--tools "$TOOLS_ARG")
  if [ "$FIXTURE_BASH" = "deny-record" ]; then
    claude_args+=(--permission-mode dontAsk --permission-prompts none)
  fi
```
```bash
# test/skills/runner-contract.bash:70-72 (inside the FIXTURE_TOOLS loop, :65-87, in check_runner_settings, :41-117)
      if [ "$tool" = "Bash" ] && [ "$FIXTURE_BASH" = "deny-record" ]; then
        ok=1
      fi
```

`FIXTURE_BASH` is named and documented as a Bash switch: "lets FIXTURE_TOOLS name Bash … so every Bash call is denied" (`generate-reports.bash:31-36`). What it actually pins, `--permission-mode dontAsk`, applies to the whole session. The contract accepts `FIXTURE_TOOLS="Bash,WebSearch"`, or `Bash,Agent` in repo mode, under deny-record. Whether WebSearch, WebFetch or a sub-agent's Read is then denied too is not probed. The tripwire looks only at `name == "Bash"`, so a denied WebSearch would pass without comment and look like a model that chose not to search. Today's only user sets `FIXTURE_TOOLS="Bash"`, so nothing is wrong yet. The risk is that the contract admits a combination whose meaning nobody has established.

**Recommendation:** Have the contract require `FIXTURE_TOOLS=Bash` exactly under deny-record, which is the probed configuration, and widen it only after a probe. Or probe the combinations and document them in the `runner-contract.bash:18-25` comment.

#### 6. The deny-record mode is spread across four modules with no single definition

**Severity:** Informational
**Location:** `test/skills/runner-contract.bash:18-25`, `:99-116`; `test/skills/generate-reports.bash:114-124`, `:181-183`, `:249-260`; `test/skills/arithmetic-eval/mode1-equiv.py:107-112`
**Move:** #2 responsibility boundaries
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

**Evidence (verbatim):**
```bash
# test/skills/runner-contract.bash:18-20 (start of a comment block that runs to :25)
# Bash is the one exception, and only as FIXTURE_BASH=deny-record (Q-063 [1]):
# the model is offered Bash, generate-reports.bash pins every call to be
# denied (--permission-mode dontAsk --permission-prompts none), and the kept
```

The mode is defined by the sum of five things:
- the contract's validation, both ways: `Bash` in `FIXTURE_TOOLS` requires deny-record, and deny-record requires `Bash` and `FIXTURE_TRANSCRIPT=1`;
- the generator's CLAUDE_FLAGS refusal;
- the generator's argv pin;
- the generator's tripwire;
- the check-side tripwire copy (Finding 3).

The literal `"deny-record"` is compared at five code sites. Each piece is documented at its own site and the pieces cross-reference one another, so this is legible. Putting the CLAUDE_FLAGS refusal in the generator rather than the contract is correct: CLAUDE_FLAGS is operator environment, not runner state (override C4, whose premise this branch narrows as the brief notes, without re-opening it). The one thing to watch: the contract's comment describes the generator's behavior, so a change to the pinned flags must update both files.

**Recommendation:** None required. If a second `FIXTURE_BASH` value is ever added, give each value one table or function in `runner-contract.bash` that supplies its pinned flags and its validity rule, and have the generator read from it.

#### 7. Tests for the generic `no_tool_called:` check live in a skill-specific suite

**Severity:** Informational
**Location:** `test/skills/mode1-equiv.bats:119-127`
**Move:** #3 module boundary
**Confidence:** High
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# test/skills/mode1-equiv.bats:119-127 (whole test)
@test "no_tool_called passes with no Bash call and fails with one" {
  jq -nc '{type:"result",subtype:"success",result:"# Report",permission_denials:[]}' > "$T"
  run assert_no_tool_called Bash
  [ "$status" -eq 0 ]
  transcript "echo hi"
  run assert_no_tool_called Bash
  [ "$status" -ne 0 ]
  [[ "$output" == *"Expected no Bash calls, found 1"* ]]
}
```

`no_tool_called:` is a generic transcript check, the negation of `tool_called:`. `tool_called:` and `subagents_min:` are unit-tested in `eval-helpers-transcript.bats`. `no_tool_called:`'s only test sits in the arithmetic-eval checker's suite. So someone changing `transcript_tool_inputs` would look in the wrong file for its tests.

**Recommendation:** Move this test to `eval-helpers-transcript.bats`, or duplicate it there. If Finding 1 is adopted, move `mode1-equiv.bats` under `arithmetic-eval/` next to the checker.

## What Looks Good

- **Run validity reuses the existing channel.** The generator records the tripwire as `.failed`, which `eval_fixture` already fails for every check type. It did not add a new status mechanism.
- **The contract refuses before a paid run, in both directions.** `Bash` without deny-record, deny-record without `Bash`, deny-record without a transcript, an unknown value, and `Bash(<pattern>)` spellings are all refused by `check_runner_settings`. The generator also refuses permission-changing CLAUDE_FLAGS before any `claude` call. Stub tests pin all of this (fact-check Claims 11, 16, 34).
- **The reference evaluator comes from SKILL.md, never from the transcript** (Claim 24). The check's trust anchor is in the right place: the skill's own source, not model output.
- **The /proc detector is decomposed into small, pure-read helpers** (`ppid_of`, `in_lineage`, `procs_in_checkout`). Dependencies point only from gate to detector, and the detector runs inside the existing gate, so it applies at all four check points without new call sites (Claim 8).
- **Routing is graded separately from post-denial behavior** (`arithmetic-eval-eval.bats`), so a known model weakness does not mask the property being measured.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Shared check dispatcher hard-codes arithmetic-eval's checker and SKILL.md | Coupling | `test/skills/eval-helpers.bash:156-158, 419-424` | High |
| 2 | WRAPPER_RE is a hand-kept second spec of the wrapper; the fourth Mode 1 extractor | Minor | `test/skills/arithmetic-eval/mode1-equiv.py:33-52` | High |
| 3 | Deny-record tripwire implemented twice (jq, Python); `after_denial` re-implements the failed-marker guard | Minor | `generate-reports.bash:249-260`, `mode1-equiv.py:107-112`, `arithmetic-eval-eval.bats:44-52` | High |
| 4 | `agent_gate` grows by editing; detectors coupled via text format and one bare exit code | Minor | `devcontainer-config/install.sh:1138-1226` | Medium |
| 5 | `FIXTURE_BASH` pins a session-wide mode; the contract admits unprobed tool combinations | Minor | `generate-reports.bash:181-183`, `runner-contract.bash:65-116` | Low |
| 6 | Deny-record semantics spread across four modules | Informational | `runner-contract.bash:18-25`, `generate-reports.bash:114-260` | Medium |
| 7 | Generic `no_tool_called:` tests live in a skill-specific suite | Informational | `test/skills/mode1-equiv.bats:119-127` | High |

## Overall Assessment

The branch keeps the harness's structure sound. The new mode is validated before the paid run, it reports run validity through the existing `.failed` channel, and it takes the reference evaluator from the skill rather than from the model. install.sh's new detector is properly split into helpers inside the existing gate. There are no Structural findings.

The one Coupling issue is the most important: `eval-helpers.bash`, shared by about 20 skills, now depends by literal path on one skill's checker and SKILL.md. The check name reads as generic but is not. This is the first skill-specific check in the dispatcher, so it sets the pattern the next one will copy. It can be fixed in place in a few lines by following `format_check`'s `${skill}` convention.

The Minor findings are also fixable in place:
- one hand-kept wrapper spec that already differs from SKILL.md's own rule (the structural side of fact-check Claim 22);
- a run-validity rule implemented in two languages;
- a gate that grows by editing;
- a Bash-named switch with session-wide effect.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown critique saved to the path named in your role section below, structured per your skill."
- **Answered:** All four structural questions in the brief:
  - skill-specific logic in the shared dispatcher (F1, with F2 and F7);
  - the duplicated tripwire (F3);
  - FIXTURE_BASH's cross-field constraints (F5 and F6; the constraints are bidirectional and correct, and the open issue is session-wide scope);
  - agent_gate's second detector (F4; the /proc reader belongs where it is, and the gate's shape is the concern).
  Saved to `docs/reviews/architecture-review-2026-09-25-q062-q063.md`. Not committed.
- **Out of scope:** Two items are for other critics: whether the non-dumpable fail-open is exploitable (Claims 6/10b), and the security or contract accuracy of WRAPPER_RE (Claim 22). Doc staleness (Claims 13, 15) is left to the fact-check. Nothing was re-litigated from override rows C4, C5, C6, C9, trap RETURN, `--tools` variadic, or RUNNER_ALLOWED_TOOLS naming.
- **Escalate:**
  - To security-reviewer: `procs_in_checkout`'s per-process `readlink … || continue` fails open, which contradicts the gate's fail-closed stance for a missing /proc (Claims 6/10b).
  - To security-reviewer and api-consistency: WRAPPER_RE's `expr` group spans a bash heredoc terminator, so "wrapper exact" and SKILL.md:39's rule are not enforced by the check (Claim 22). F2 gives the structural fix: derive the wrapper from the block and refuse terminator lines in the body.
  - F5's premise needs a `claude` probe: does `--permission-mode dontAsk` deny WebSearch, WebFetch, or a sub-agent's Read?
- **Questions:** For F1, should skill-specific checks live under `test/skills/<skill>/` and be resolved from `$skill` (a convention for all future ones), or is one literal arm acceptable until a second skill needs it?
- **Decisions:** None made. All recommendations are left to the author.
