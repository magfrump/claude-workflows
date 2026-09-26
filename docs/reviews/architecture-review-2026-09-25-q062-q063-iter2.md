Commit: d8c43ae

# Architecture Review — skill-fixtures (Q-062 [2], Q-063 [1]), iteration 2

**Scope:** `git diff main...HEAD` on skill-fixtures (HEAD d8c43ae). The focus is iteration 1's fix commit 8664e22 and what it changed structurally. Code files: `test/skills/{eval-helpers,generate-reports,runner-contract}.bash`, `test/skills/arithmetic-eval/mode1-equiv.py`, `devcontainer-config/install.sh` (`procs_in_checkout`, `agent_gate`). Doc-only and review-artifact files are excluded from structural findings.
**Date:** 2026-09-25
**Based on:** `docs/reviews/code-fact-check-report.md` (Commit d8c43ae, 39 claims). Behavior that report verified is not re-verified here. Claims 2, 9 and 25b are built on below.

**Scope check.** The same three trigger categories apply as in iteration 1. *Public APIs:* the check vocabulary (`mode1_equiv:` now takes `$skill`, and `no_tool_called:` takes `<Tool>[=<ERE>]`) and the `procs_in_checkout` return-code contract (rc 3 is new). *Cross-cutting:* the deny-record permission pipeline (the pinned flags gain `--disallowedTools 'Bash(**)'`, and the contract now requires `FIXTURE_TOOLS=Bash` exactly). *Module structure:* the skill-owned checker convention `test/skills/<skill>/mode1-equiv.py`.

**Trust-boundary cross-reference.** The newest security review is `docs/reviews/security-review-2026-09-25-q062-q063.md` (Commit: `5ddf804`). It predates this diff, so its boundaries may be stale. Two of its labels are used below:
- `B1` is the /proc state → `procs_in_checkout` + `in_lineage` → the `agent_gate` verdict.
- `B3` is the model's Bash tool_use → the CLI permission flags → execution.

`B3`'s transition point is written as `--permission-mode dontAsk --permission-prompts none`. Since 8664e22 the load-bearing flag is `--disallowedTools 'Bash(**)'`, so that label is out of date. That is for security-reviewer to update, and this review does not revise it.

## Dependency Map

The fixture harness's layering is unchanged from iteration 1:

`runner.bash` → `runner-contract.bash` (validation) → `generate-reports.bash` (pins flags, refuses CLAUDE_FLAGS, runs the tripwire, writes `.failed`) → `eval-helpers.bash` (shared dispatcher) → check functions.

What 8664e22 changed:

- **Check → skill.** The dispatcher no longer names arithmetic-eval by literal path. `mode1_equiv:` resolves `${BATS_TEST_DIRNAME}/${skill}/mode1-equiv.py` and `skills/${skill}/SKILL.md`, the same way `format_check` resolves `${skill}-format.bats`. So eval-helpers.bash no longer imports anything from arithmetic-eval. Only the check's *name* and its doc comment still come from arithmetic-eval (Finding 1).
- **Deny policy.** It is now held in three code sites, plus prose:
  - the contract: `FIXTURE_TOOLS=Bash` exactly, and `FIXTURE_TRANSCRIPT=1`;
  - the generator: the pinned argv, the CLAUDE_FLAGS refusal and the tripwire;
  - `mode1-equiv.py`: the tripwire copy (C8, open by choice).

  The pinned flag set exists once as code (`generate-reports.bash:192`) and is restated in prose in four places (Finding 3).
- **install.sh.** The gate still depends on its detector through a bare exit code. The code now has two meanings, rc 2 (no `/proc/self`) and rc 3 (the checkout's path does not resolve), and the gate still owns both messages (Finding 4). The dependencies still point one way: gate → detector → /proc.

## Findings

#### 1. A6 is fixed at the path level. The shared arm is now a generic "skill-owned checker" hook that still carries one skill's name and contract text

**Severity:** Minor
**Location:** `test/skills/eval-helpers.bash:161-163`, `test/skills/eval-helpers.bash:419-437`
**Move:** #8 extension points, #3 module boundary
**Confidence:** High
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# test/skills/eval-helpers.bash:161-163 (one case arm; eval_fixture runs :58-175)
      mode1_equiv:*)
        assert_mode1_equiv "$skill" "${check#mode1_equiv:}" || failed=1
        ;;
```
```bash
# test/skills/eval-helpers.bash:419-437 (whole comment and function)
# Assert a denied Bash call in a FIXTURE_BASH=deny-record transcript was the
# skill's Mode 1 evaluator (wrapper exact, heredoc closed at its first EXPREOF
# line with nothing but comments after it, program AST-equal to SKILL.md's) and
# that its expression, run through the evaluator extracted from SKILL.md, gives
# one of the expected values. Also fails if any Bash call is missing from
# permission_denials. The checker is skill-owned: test/skills/<skill>/
# mode1-equiv.py, reading skills/<skill>/SKILL.md (today only arithmetic-eval).
# Check syntax: mode1_equiv:1900000000|1900000   (or 42.16~0.002 for a tolerance)
# Args: $1 = skill, $2 = expected values
assert_mode1_equiv() {
  local skill="$1" spec="$2" t checker
  checker="${BATS_TEST_DIRNAME}/${skill}/mode1-equiv.py"
  if [ ! -f "$checker" ]; then
    echo "mode1_equiv: needs a skill-owned checker at $checker"
    return 1
  fi
  t="$(eval_transcript_path)" || { echo "$t"; return 1; }
  python3 "$checker" "${BATS_TEST_DIRNAME}/../../skills/${skill}/SKILL.md" "$t" "$spec"
}
```

The iteration-1 Coupling finding is resolved on its substance:
- the shared module no longer depends on arithmetic-eval's files;
- a second skill that used `mode1_equiv:` would now fail loudly instead of being graded against the wrong SKILL.md, and `mode1-equiv.bats` test 10 (`:117`, "a skill with no mode1-equiv.py of its own fails the check with a message") pins this;
- a change to arithmetic-eval's layout no longer touches eval-helpers.bash.

What is left is how the arm is presented. The mechanism is now generic: run `<skill>/<checker>` with (SKILL.md, transcript, spec) and pass or fail on its exit status. But the arm's name, the checker's file name, and the comment's description of what the check verifies (the wrapper, EXPREOF, AST equality) all describe arithmetic-eval's checker. So the shared file documents one skill's semantics, and the comment goes stale whenever `mode1-equiv.py` changes. The comment had to be rewritten in 8664e22 for A3, which is an example. The next skill that needs a "compare the attempted command with a reference" check has two options. It can ship a file named `mode1-equiv.py` that has nothing to do with a Mode 1, or it can add another arm, which is the growing switch iteration 1 warned about. The fix covered the dependency direction, but not the extension point.

**Recommendation:** Keep the resolution as it is. Either rename the arm and the file to a neutral hook, e.g. `skill_check:<args>` → `test/skills/<skill>/check.py`, or `transcript_check:`. Or keep the name and cut the comment down to the hook contract (argv, the SKILL.md path it is given, exit codes), pointing to `mode1-equiv.py`'s docstring for the semantics. Either way, the next skill's checker does not need an edit to eval-helpers.bash.

#### 2. The checker's exit-2 "fixture-author error" state has no consumer: the dispatcher collapses 0/1/2 to pass/fail

**Severity:** Minor
**Location:** `test/skills/eval-helpers.bash:162`, `:436`; `test/skills/arithmetic-eval/mode1-equiv.py:26-27`, `:44-46`
**Move:** #7 coupling surface (contract mismatch across a module boundary)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence (verbatim):**
```python
# test/skills/arithmetic-eval/mode1-equiv.py:26-27 (end of the module docstring, :2-28)
Exit 0 on a match, 1 on no match (per-call diagnostics on stdout), 2 on a
usage, value-spec or SKILL.md extraction error (message on stderr).
```
```python
# test/skills/arithmetic-eval/mode1-equiv.py:44-46 (whole function)
def usage_error(msg):
    print("mode1-equiv: " + msg, file=sys.stderr)
    sys.exit(2)
```
```bash
# test/skills/eval-helpers.bash:162 (inside eval_fixture's case, :101-172)
        assert_mode1_equiv "$skill" "${check#mode1_equiv:}" || failed=1
```
The last line of `assert_mode1_equiv` (`:436`, quoted whole in Finding 1) passes the checker's status through unchanged, and the arm above maps every non-zero status to `failed=1`.

8664e22 (A10) gave the checker a three-way contract, and fact-check Claim 25b shows it is incomplete: a negative tolerance and an unreadable path still exit 1. The orchestrator plans a structural fix in `mode1-equiv.py`. The architectural point is that finishing the three-way contract inside the checker will not change what a grade reports. `eval_fixture` has only pass and fail, so exit 2 and exit 1 both become the same failed routing test. Only the stderr text tells them apart. So a fixture-author error, such as a mistyped `KEY_CHECK` spec, still reads as "the model did not route through Mode 1" in the pass/fail result, and the error is found only on a paid run's report. Among this checker's inputs, only the spec comes from the fixture author, and it is static data in `expected-verdicts.bash`. It can be validated without any transcript.

**Recommendation:** Move the fixture-author check earlier, out of the graded path. Add a fast test (or a `--check-spec` mode of the checker) that parses every `mode1_equiv:` spec in `expected-verdicts.bash`: it refuses non-numbers, negative or non-finite tolerances and `nan`, and it confirms that SKILL.md's Mode 1 block extracts. That test then carries the "exit 2" category. If exit 2 is also kept at grade time, have `assert_mode1_equiv` map rc 2 to a distinct message such as "fixture/checker error, not a model result". This gives the orchestrator's 25b fix a consumer.

#### 3. The deny-record flag set is one literal plus four prose restatements, and one restatement drifted in the fix commit; the CLAUDE_FLAGS refusal list is a separate hand-kept inverse

**Severity:** Minor
**Location:** `test/skills/generate-reports.bash:192` (the literal); prose at `generate-reports.bash:31-39`, `runner-contract.bash:18-21`, `docs/decisions/log.md:77`, `docs/working/dd-arith-eval-bash-grant.md:173`; refusal list at `generate-reports.bash:124-134`; contract invariant at `runner-contract.bash:108-113`
**Move:** #2 responsibility boundaries, #7 coupling surface
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# test/skills/generate-reports.bash:191-193 (inside generate_one, :143-289)
  if [ "$FIXTURE_BASH" = "deny-record" ]; then
    claude_args+=(--disallowedTools 'Bash(**)' --permission-mode dontAsk --permission-prompts none)
  fi
```
```text
# docs/decisions/log.md:77 (row #56, headline only; the rationale and references columns follow)
| 56 | 2026-09-25 | **Skill fixtures may grant Bash only as `FIXTURE_BASH=deny-record`: Bash is offered, every call is denied (`--permission-mode dontAsk --permission-prompts none`), and the eval checks the command the model *tried*.**
```
```bash
# test/skills/generate-reports.bash:124-134 (whole if-block)
if [ "$FIXTURE_BASH" = "deny-record" ]; then
  flags_words=" ${CLAUDE_FLAGS:-} "
  flags_words="${flags_words//[[:space:]]/ }"
  case "$flags_words" in
    *" --permission-mode"*|*" --permission-prompt"*|*" --allowedTools"*|*" --allowed-tools"*|\
    *" --dangerously-skip-permissions"*|*" --allow-dangerously-skip-permissions"*|*" --settings"*)
      echo "Error: $RUNNER_FILE sets FIXTURE_BASH=deny-record; CLAUDE_FLAGS may not change permissions: ${CLAUDE_FLAGS}" >&2
      exit 1
      ;;
  esac
fi
```
```bash
# test/skills/runner-contract.bash:108-113 (inside the deny-record case arm, :102-114, of check_runner_settings, :42-120)
      # Exactly Bash: the pinned dontAsk mode applies to every tool, and only
      # Bash's denial is probed and tripwired (review C9).
      if [ "$FIXTURE_TOOLS" != "Bash" ]; then
        echo "Error: $label: FIXTURE_BASH=deny-record needs FIXTURE_TOOLS=Bash exactly, got '$FIXTURE_TOOLS'" >&2
        return 1
      fi
```

Iteration 1's Finding 6 said "a change to the pinned flags must update both files". 8664e22 is the first such change, and it bore that out. The literal and three of the four prose restatements were updated, but the log #56 headline was not (fact-check Claim 9). The headline credits "every call is denied" to exactly the two flags that the same commit found insufficient. That is a small doc error, but it shows the pattern: the fact that decides whether anything executes (which flag does the denying) is kept by hand in five places.

The generator's pre-run defenses are also out of step with the contract. The contract now requires "exactly Bash" because dontAsk covers every tool (C9). The CLAUDE_FLAGS refusal list exists to stop operator flags from undoing what deny-record pins, but it has no entry for `--tools`. So a later `CLAUDE_FLAGS="--tools Bash,Read"` gets past the invariant that the contract enforces for runners. This does not re-open C4, since operator env is still trusted. The structural point is that the contract and the refusal list are two validators of one session configuration, each kept by hand against the other, with nothing linking them.

**Recommendation:** Define the pinned set once, e.g. `DENY_RECORD_FLAGS=(--disallowedTools 'Bash(**)' --permission-mode dontAsk --permission-prompts none)` in `runner-contract.bash` next to the validation. Have the generator append that array, and have the prose name the array instead of listing the flags. When the refusal list is next edited, derive it from the same place (each pinned flag, `--tools`, and the allow/bypass flags). Update the log #56 headline in any case.

#### 4. rc 3 extends the detector→gate code enum while the gate keeps owning the messages; Q-064 [2] will need a third output class that this interface cannot carry

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:1138-1162` (`procs_in_checkout`), `:1180-1191` (inside `agent_gate`, :1167-1242)
**Move:** #3 module boundary, #8 extension points
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# devcontainer-config/install.sh:1148-1154 (start of procs_in_checkout, :1148-1162; the in-checkout filter, lineage exemption and printf follow at :1155-1161)
procs_in_checkout() {
  local root d pid cwd cmd
  [ -d /proc/self ] || return 2
  root="$(cd "$REPO_ROOT" && pwd -P)" || return 3
  for d in /proc/[0-9]*; do
    [ -O "$d" ] || continue                     # this uid's processes only
    cwd="$(readlink "$d/cwd" 2>/dev/null)" || continue   # unreadable: see above
```
```bash
# devcontainer-config/install.sh:1182-1191 (inside agent_gate; the de-duplication follows at :1192-1197)
  inrepo="$(procs_in_checkout)" || rc=$?
  if [ "$rc" -eq 3 ]; then
    echo "ERROR: could not resolve the checkout's path ($REPO_ROOT), so install.sh cannot" >&2
    echo "       check for processes working inside it (Q-062). $what" >&2
    exit 1
  elif [ "$rc" -ne 0 ]; then
    echo "ERROR: /proc is not readable, so install.sh cannot check for processes working" >&2
    echo "       inside the checkout (Q-062). It needs Linux /proc. $what" >&2
    exit 1
  fi
```

This finding sits on `B1` from `docs/reviews/security-review-2026-09-25-q062-q063.md` (Commit: `5ddf804`). That security review predates this diff, so the boundary may be stale. The recommendation below keeps the transition point where `B1` places it (detector plus gate) and does not move it.

C5's fix corrected the misattributed message. It did so by adding a second code, and the gate still writes the text for conditions that only the detector defines. Fact-check Claim 2 shows the cost that remains. The gate says "/proc is not readable" and the header says "a readable /proc", but the detector tests only that `/proc/self` exists. Readability is decided per process at `:1154`, which skips unreadable entries silently. So the gate's wording and the detector's test are written in two places and do not match. The readability wording is escalated to security-reviewer and is not re-argued here.

The forward cost is Q-064. Its entry says "[2] replaces the `|| continue` with a refusal list plus a test; nothing is redone". Under the current interface, [2] is more than a one-line change. An unreadable-cwd process has an *unknown* cwd, not a cwd in the checkout, so it needs its own output class. That means one of two things:
- a second output stream from a function whose only output is stdout in `PID cmd` format, or
- a tagged line format.

Either way the gate needs a new branch, a new message block, and an updated de-duplication step (the awk at `:1195-1197` keys on the first field). That is the five-site edit pattern iteration 1's F4 described, at the point where the user is most likely to ask for it. The skip itself is Acknowledged (A1) and is not re-flagged here.

**Recommendation:** Before Q-064 is answered, or in the same change as [2], give `procs_in_checkout` a small structured output: tagged lines such as `inrepo <pid> <cmd>` and `unreadable <pid> <cmd>`, and have it print its own cause text on stderr for the cannot-check returns. `agent_gate` then chooses a policy per tag. Under [1] it drops `unreadable` lines. Under [2] it refuses on them. The rc-to-message mapping goes away. Also correct Q-064's "If the answer differs" line so it reflects the real edit size.

#### 5. The generic runner contract names one skill's check and justifies its rule by the generator's internals

**Severity:** Informational
**Location:** `test/skills/runner-contract.bash:18-26`, `:108-109`
**Move:** #3 module boundary
**Confidence:** High
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# test/skills/runner-contract.bash:18-23 (a comment block that runs to :26)
# Bash is the one exception, and only as FIXTURE_BASH=deny-record (Q-063 [1]):
# the model is offered Bash, generate-reports.bash pins every call to be
# denied (a 'Bash(**)' deny rule; dontAsk alone still ran read-only commands
# such as pwd and ls, probed 2026-09-25), and the kept
# transcript records the command it tried. Nothing runs; eval checks compare
# the recorded command with a reference (arithmetic-eval's mode1_equiv:). A
```

The contract is shared by every runner. It now refers to one skill's check by name, and it restates the generator's flag probe results. Both will go stale independently of the contract's own rules: the first if Finding 1's rename happens, the second on the next flag change (Finding 3). This is iteration 1's F6, now with one more concrete coupling. It is still legible and harmless.

**Recommendation:** Trim the comment to what the contract enforces. Point to `generate-reports.bash`'s `FIXTURE_BASH` header for the flags and to the check registry for the checks. Nothing more is needed.

## What Looks Good

- **A6's resolution follows the existing convention.** `${skill}` resolution matches `format_check`. A skill without a checker fails loudly, and a test pins that. The shared module no longer depends on a skill.
- **C9 is enforced at the contract, before a paid run.** Requiring `FIXTURE_TOOLS=Bash` exactly narrows the mode to the only configuration that was probed. The stub tests cover `Bash,WebSearch` and `WebSearch` alone.
- **C10 keeps run validity on the one generic channel.** The tripwire now appends to an existing failure (`failure="${failure:+$failure; }$trip"`) and does not replace it. An unreadable transcript fails closed with its own message. Both still go through `.failed`, which every check type already respects.
- **rc 3 makes the detector's failure causes explicit, and both still fail closed.** The dependency still points one way, gate → detector.
- **`no_tool_called:` now takes the same `<Tool>[=<ERE>]` shape as `tool_called:`,** so the vocabulary grew by symmetry and not by a new pattern.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | A6 fixed at the path level; the arm is a generic checker hook with a skill-specific name and contract text | Minor | `test/skills/eval-helpers.bash:161-163, 419-437` | High |
| 2 | The checker's exit 2 (fixture-author error) has no consumer; the dispatcher collapses 0/1/2 to pass/fail | Minor | `eval-helpers.bash:162, 436`; `mode1-equiv.py:26-27, 44-46` | High |
| 3 | Deny flags: one literal plus four prose copies (one drifted, Claim 9); the CLAUDE_FLAGS refusal is a hand-kept inverse that misses the contract's "exactly Bash" (`--tools`) | Minor | `generate-reports.bash:124-134, 192`; `runner-contract.bash:108-113`; `log.md:77` | Medium |
| 4 | rc 3 extends a bare-code interface; the gate owns the messages; Q-064 [2] needs an output class the interface cannot carry | Minor | `devcontainer-config/install.sh:1148-1191` | Medium |
| 5 | The generic runner contract names a skill check and restates generator internals | Informational | `test/skills/runner-contract.bash:18-26, 108-109` | High |

## Overall Assessment

8664e22 keeps the branch's structure sound, and it resolves the one Coupling finding from iteration 1 in the right direction. `eval-helpers.bash` no longer depends on arithmetic-eval's files, and a misuse now fails loudly. No Structural or Coupling findings remain. All four Minor findings can be fixed in place.

The most important one for this loop is Finding 2. The orchestrator's planned structural fix for Claim 25b is inside `mode1-equiv.py`, but the dispatcher throws away the exit-code distinction that fix is meant to carry. The durable fix is a fast validation of the fixture specs, which takes fixture-author errors out of graded runs altogether.

Finding 4 matters for the user's pending Q-064 decision. Choosing option [2] costs more than the entry says, unless the detector's interface gains a tagged output first.

Not re-filed: iteration 1's prediction for C8 (the duplicated tripwire) has started to come true. 8664e22 changed the jq copy's behavior: it now runs on already-failed runs and has an "unreadable" arm. The Python copy got only a message change, and it still tracebacks on an unreadable transcript (Claim 25b). C8 stays open by choice.

The security review's `B3` label describes the pre-8664e22 flags, so that map is stale at `B3`. Security-reviewer should update it. This review does not.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown critique saved to the path named in your role section below, structured per your skill."
- **Answered:**
  - Does A6 resolve iteration-1's Coupling finding? Yes on substance: the dependency is gone and misuse is loud. The residue is naming and doc text in the shared arm (F1, Minor). The `mode1_equiv:` name is still skill-named, but it is no longer skill-bound.
  - The deny policy split across contract, generator and checker: F3 and F5. The C8 duplication is noted as drifting but not re-filed.
  - agent_gate rc 2/3: F4.

  Saved to `docs/reviews/architecture-review-2026-09-25-q062-q063-iter2.md`. Not committed.
- **Out of scope:** Whether `[ -d /proc/self ]` versus "readable /proc" is a security gap (Claim 2) is left to security-reviewer. F4 covers only the interface shape. Whether `--tools` in CLAUDE_FLAGS is a real risk is also left to security-reviewer: C4 is still Won't-Fix, and F3 is a structural note, not a security finding. Nothing was re-litigated from C4, C5, C6, C9, trap RETURN, `--tools` variadic, the RUNNER_ALLOWED_TOOLS naming, A1, C3/C4, C6, C8, C13, C14 or C15.
- **Escalate:**
  - To the orchestrator, for the 25b structural fix: F2. Any exit-2 work in `mode1-equiv.py` needs either a consumer in `assert_mode1_equiv` or a fast spec validation, or it changes nothing a grade reports.
  - To security-reviewer: the `B3` transition point in the security review's map is stale (it predates `Bash(**)`). F3's `--tools` gap in the CLAUDE_FLAGS refusal is also theirs.
  - To the Q-064 author: F4. The "If the answer differs: … nothing is redone" line understates what [2] would take.
- **Questions:** For F1, should the arm be renamed to a neutral hook now, while there is one user, or kept until a second skill needs it?
- **Decisions:** None made. All recommendations are left to the author.
