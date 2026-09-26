Commit: 5bdee46

# API Consistency Review: branch skill-fixtures (Q-062 [2], Q-063 [1]), iteration 4 (user-authorized terminal pass)

**Scope:** `git diff main...HEAD` at 5bdee46, weighted toward 37c5ea9 (the one fix commit no review has covered). Surfaces: the deny-record void markers (tripwire, parser canary, init canary, "no init event"), install.sh's rc-4 gate NOTE and rc protocol against the docker NOTEs, the `tool_inputs_checked` messages, mode1-equiv.py's CLI and exit contract, the runner-contract messages, and the patterns-test helper names.
**Date:** 2026-09-25 (iteration 4 of 4, after the loop's cap: full remaining inventory)
**Based on:** `docs/reviews/code-fact-check-report.md` (commit 5bdee46), cited by claim number. My own probes are marked "(probe)", with input and output quoted inline. They ran in the session scratchpad (`…/scratchpad/api4/`). Nothing was written under `test/skills/*/output/`, and no `claude` or network command was run.
**Settled, not re-litigated:** overrides C4, C5, C6, C9, trap RETURN, `--tools` variadic, RUNNER_ALLOWED_TOOLS naming; A1 (Q-064), A20; C24, C30 deferred; C3/C4/C6/C8/C13/C14/C15 open by choice. Claim 13 (mode1-equiv's traceback/exit-1 leak) is escalated to the orchestrator, so it is not re-reported here. Finding 4 only asks that the boundary fix also decide one classification question.

## Baseline Conventions

This carries forward the baseline from iterations 1-3 (`api-consistency-review-2026-09-25-q062-q063{,-iter2,-iter3}.md`). At 5bdee46 I re-read these units in full:
- `procs_in_checkout` and `agent_gate` (`devcontainer-config/install.sh:1142-1266`) and the usage text (`:50-80`)
- `generate_one` (`test/skills/generate-reports.bash:139-314`) and the header (`:1-130`)
- `check_runner_settings` (`test/skills/runner-contract.bash:38-125`)
- `eval_fixture`, `tool_inputs_checked`, `match_inputs`, `assert_tool_called`, `assert_no_tool_called` and `assert_mode1_equiv` (`test/skills/eval-helpers.bash:58-179, 356-495`)
- all of `mode1-equiv.py`
- `arithmetic-eval-after-denial-patterns.bats`
- the 37c5ea9 hunks of `mode1-equiv.bats`, `generate-reports.bats` and `install-host.bats`

The conventions these findings rest on:
- **Generator failure markers** are lowercase phrases, joined with `; `. Deny-record markers name their mechanism with a `Bash <mechanism>:` prefix (`Bash tripwire:`, `Bash parser canary:`, `generate-reports.bash:294-296`). Stream-level markers are plain phrases: `no result event in the stream` (`:254`).
- **install.sh NOTEs** take the form `NOTE: <cause>: <what> not checked, treated as none running.` They print on stdout once per gate call (`install.sh:1221,1232`, T52). ERROR lines put the exit status and the question reference in separate parentheses: `ERROR: pgrep failed (exit $rc) while checking … (Q-058). $what` (`:1187`). Usage text on main wraps at 83 columns or less.
- **Transcript-helper messages** take the form `No <thing> at/in $t …` or `Could not read … from $t` (`eval-helpers.bash:360,387`). Positive and negative checks are twins, with one argument grammar and one message register.
- **Script CLIs** print a `<script>:` prefix on stderr and exit 2 on usage errors (`scripts/lite-review.py:236`, `mode1-equiv.py:175`).
- **Test assertion helpers** are named `assert_*`, both shared (`test/skills/helpers.bash:98-155`, `eval-helpers.bash:186-457`) and test-local (`test/skills/fact-check-edge-cases.bats:26`, `test/hooks/guard-trusted-writes.bats:62`).

### Iteration-3 API items re-checked at 5bdee46

| Iter-3 item → rubric row | Status | Note |
|---|---|---|
| #1 canary blames the deny rule with no init event → A17 | Fixed | `none` → `no init event in the stream (the run did not start?)`. This mirrors `no result event in the stream`, and bats :589 covers it. |
| #2 "resolves by skill" untested → C25 | Fixed | The new test at `mode1-equiv.bats:278` proves it (Claim 22). The old test name at :241 still claims it (Claim 21; Finding 6). |
| #3 three errors under deny-record → C26 | Fixed | One message for every non-empty wrong value (Claim 23). |
| #4 CLAUDE_FLAGS described four ways → A18 | Fixed at the three named places | The contract reference the DD doc names, the generator header's `FIXTURE_BASH` entry, is now stale (Claim 18; Finding 2). |
| #5 blind NOTE off-convention → C27 | Fixed | stdout, "not checked, treated as none", T91, usage text. See What Looks Good. |
| #6 `tool_called` edges → A16 (marked Fixed) | Partly fixed | Only the doc-overstatement part was fixed. The `/./` message and the empty tool name are unchanged (Finding 3). |
| #7 mode1-equiv exit contract → A19 | Arity and grammar fixed | The traceback leak is Claim 13, escalated. A new classification question is Finding 4. |
| #8 label order, 101-column lead line | Not in the rubric; unchanged | Finding 6 |

## Name-Pattern Audit

These are the names and message strings 37c5ea9 adds or changes. Names audited in iterations 1-3 and unchanged since are omitted.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `Bash parser canary: N Bash denial(s) name a tool_use the parser did not see (CLI v; did the event shape change?)` | failure marker | `Bash tripwire: N Bash call(s) …`, `Bash canary: …` | `test/skills/generate-reports.bash:294,300` | Consistent (`Bash <mechanism>:`, count first, CLI version, a cause hint) |
| `Bash canary: the init event does not list Bash …` (the check the code comment now calls the "init canary") | failure marker | `Bash parser canary:`, `Bash tripwire:` | `generate-reports.bash:265,296` | Inconsistent: this is the one canary whose marker omits its mechanism word, and `Bash canary` is not a substring of `Bash parser canary` (Finding 2) |
| `no init event in the stream (the run did not start?)` | failure marker | `no result event in the stream`, `the result event is an error` | `generate-reports.bash:254-255` | Consistent (stream-level plain phrase) |
| `Bash tripwire: the transcript could not be read, so denials are unverified` (existing text, new scope) | failure marker | `Could not read tool calls from $t` | `eval-helpers.bash:387` | Label and wording no longer fit the scope: it now stands for all three checks, and it fires on a readable file (Finding 1) |
| `No init event in $t: not a complete stream-json transcript` | helper message | `No transcript at $t — regenerate …`, `Could not read tool calls from $t` | `test/skills/eval-helpers.bash:360,387` | Consistent |
| `procs_in_checkout` rc 4 | return code | rc 2 (`/proc` not mounted), rc 3 (checkout path unresolved); pgrep's rc 1 = none | `devcontainer-config/install.sh:1159-1160` | Consistent: documented in the helper comment, and each rc has its own gate arm |
| `NOTE: no process's working directory could be read under /proc: processes inside the checkout not checked, treated as none (Q-062).` | install notice | `NOTE: docker not found: cc-isolated containers not checked, treated as none running.` | `install.sh:1221,1232` | Consistent (C27 resolved) |
| `ERROR: the check for processes inside the checkout failed (exit $rc, Q-062). $what` | install error | `ERROR: pgrep failed (exit $rc) while checking … (Q-058). $what` | `install.sh:1187` | Informational: the exit status and the Q-ref share one parenthesis (Finding 6) |
| `--check-spec expects 2 arguments: <SKILL.md> <expected>` | CLI usage error | `expected 3 arguments` (positional form, same file) | `mode1-equiv.py:168` | The new message is the better one. Its positional sibling does not name its operands (Finding 5) |
| `Bash tool_use <id> has no string input.command` (SetupError) | checker error | `bad expected value …`, `cannot read …` | `mode1-equiv.py:80-95,135` | Wording is consistent. The classification (exit 2, "not a model result") is questionable (Finding 4) |
| `NUMBER_RE` | regex constant | `HEAD_RE`, `TAIL_LINE_RE`, `CLAUDE_PROC_RE` | `mode1-equiv.py:45-50`, `install.sh:1110` | Consistent (`_RE` suffix) |
| `expect_hit`, `expect_miss` | test-local helpers | `assert_report_matches`/`assert_report_not_matches`, test-local `assert_no_verdicts`, `assert_decision` | `test/skills/eval-helpers.bash:299,310`, `test/skills/fact-check-edge-cases.bats:36`, `test/hooks/guard-trusted-writes.bats:62` | Informational: `expect_` has no precedent in `test/`; assertion helpers are `assert_*` (Finding 7) |
| `T91 a blind /proc scan … (review A15/C27)` | test name | `T88`-`T90`; 26 names ending `(review …)` | `test/install-host.bats:1503-1551` | Consistent |
| `deny-record parser canary: …`, `deny-record: a run with no init event …`, `deny-record tripwire: a Bash tool_use with no id …` | test names | `deny-record canary: …` | `test/generate-reports.bats:532` | Consistent |

## Findings

Findings are ordered by severity, then confidence. None is Breaking. Every finding fails closed: no run can pass because of it. The committed consumers are arithmetic-eval's five fixtures and divergent-design's `tool_called:Read=…`, and no finding changes a result either of them gets today.

#### 1. `Bash tripwire: the transcript could not be read` now stands for all three checks, and it fires on a readable transcript; the other two consumers treat the same line differently

**Severity:** Minor
**Location:** `test/skills/generate-reports.bash:275-291` (the one-pass jq and its `|| verdict="unreadable"` arm, inside `generate_one`, which continues to `:314`; `failure` is written to `.failed` at `:306-308`)
**Move:** 4 (error consistency), 7 (asymmetry across consumers)
**Confidence:** High
**Legibility-target:** the operator reading a `.failed` marker, or `eval_fixture`'s `Generation failed for …` line, after a CLI update.

Evidence. Since 37c5ea9, one jq program computes the tripwire, the parser canary and the init canary together. When jq fails, the only marker written is the old tripwire one:
```bash
        "$transcript_path" 2>/dev/null) || verdict="unreadable"
      local undenied unseen init_state cli_version
      if [ "$verdict" = unreadable ] || [ -z "$verdict" ]; then
        failure="${failure:+$failure; }Bash tripwire: the transcript could not be read, so denials are unverified"
      else
```
(excerpt ends inside the deny-record block; the `else` arm continues to `:302`, and the enclosing function to `:314` — read)

jq also fails on a file it read without trouble. (probe) Run against a transcript with an init event, one `{"type":"assistant","message":"oops"}` line and a result event, each of the three consumers gives a different answer:
```
generator jq (cfc-5bdee46-gen.jq):  jq: error (at m.jsonl:3): Cannot index string with string "content"  rc=5
                                    → "Bash tripwire: the transcript could not be read, so denials are unverified"
tool_inputs_checked m.jsonl Bash:   rc=0, no inputs   (no_tool_called:Bash would pass)
mode1-equiv.py … m.jsonl 1:         "Bash calls seen: 0" / "No Mode 1 call computed any of: 1"  rc=1
```
The generator's verdict is correct: the run is voided. But the marker is wrong on two counts. It blames the tripwire alone, when the parser and init canaries are unverified too. And it says "could not be read" about a file that was read, when the real cause is one mis-shaped event, which is exactly the "changed event shape" the parser canary exists to name. The Claim 9a scope note records the same mislabel. The `tool_inputs_checked` limit is documented (Claim 16a), and mode1-equiv's is Claim 13, so this finding is only about the text an operator sees.

**Recommendation:** Give the jq-failure arm its own family label, and name both causes. For example: `Bash deny-record checks: jq could not evaluate the transcript (unreadable, or an event of an unexpected shape; CLI unknown), so denials are unverified`. Keep it failing closed. Add a stub test next to `test/generate-reports.bats:571` with a string-`message` event.

#### 2. The init canary's marker is `Bash canary:`, its sibling is `Bash parser canary:`, and the header that is the named contract reference lists only two of the four markers

**Severity:** Minor
**Location:** `test/skills/generate-reports.bash:300` (marker), `:262-267` (comment naming "parser canary" / "init canary"), `:31-37` (header `FIXTURE_BASH` entry); `test/generate-reports.bats:532,538`
**Move:** 2 (naming), 3 (documentation drift)
**Confidence:** High
**Legibility-target:** an operator grepping `.failed` markers across a regeneration, and a reader following the DD doc's "the code is the reference: the `FIXTURE_BASH` entry in `generate-reports.bash`'s header" (`docs/working/dd-arith-eval-bash-grant.md:174`).

Precedent: the `Bash <mechanism>:` marker prefix, used in `test/skills/generate-reports.bash:294` (`Bash tripwire:`) and `:296` (`Bash parser canary:`).

Evidence. The comment names three checks, but the markers name them differently:
```
comment  :262  - parser canary: …           marker :296  Bash parser canary: …
comment  :265  - init canary: …             marker :300  Bash canary: the init event does not list Bash …
                                             marker :299  no init event in the stream (the run did not start?)
header   :37   … when the init event does not list Bash (canary).
```
`grep 'Bash canary'` over a set of `.failed` files misses every parser-canary void, and `grep 'parser canary'` misses nothing else. So "canary" cannot be used as the family key, and "init canary" appears in no marker. Separately, the header entry, which the DD doc names as the reference, lists only the tripwire and the no-Bash canary. It omits the parser canary and the missing-init case (Claim 18, Stale). The plain `no init event in the stream` marker is fine as it is, because it mirrors `no result event in the stream` (`:254`).

**Recommendation:** Rename the marker to `Bash init canary: the init event does not list Bash (…)`, and update the grep at `test/generate-reports.bats:538`. List all four voiding conditions in the header entry, as log #56 and the DD "Run voiding" bullet already do.

#### 3. Two of iteration 3's `tool_called:` edges are unchanged, although the rubric row that cites them (A16) is marked Fixed

**Severity:** Minor
**Location:** `test/skills/eval-helpers.bash:420-434` (`assert_tool_called`), `:457-470` (`assert_no_tool_called`), `:396-399` (`tool_inputs_checked` name check), `:146-164` (dispatcher arms); rubric row A16
**Move:** 7 (positive/negative twin asymmetry), 4 (author errors labelled as such)
**Confidence:** High
**Legibility-target:** a fixture author reading a red eval or writing a check spec; the orchestrator tallying A16.

Evidence (probe at 5bdee46; one transcript with an init event listing `["Bash"]` and no calls, a second whose init event has no `tools` list):
```
rc=1 tool_called 'Bash'      :: No Bash call with input matching /./.|Bash calls seen: 0|
rc=1 tool_called ''          ::  is not a tool of this run (its tools: Bash )|
rc=1 no_tool_called ''       ::  is not a tool of this run (its tools: Bash )|
no-tools-list init, empty name   rc=0
no-tools-list init, 'bash'       rc=0
```
Iteration 3's Finding 6 had three parts. 37c5ea9 fixed the doc overstatement, which is now accurate per Claim 16a. It did not touch the other two:
- **Message register.** The bare positive check still prints the internal default `/./`. Its negative twin hides that default with `${2:+ with input matching /$2/}` (`:466`).
- **Empty tool name.** `no_tool_called:` and `tool_called:=x` reach the asserts with `tool=""`. The result is either a message with a leading blank or, when the init event carries no `tools` list, a pass. Neither is labelled as the spec error it is, in the way `Unknown check type: …` is (`:173`).

The rubric's A16 row lists "api-consistency iter3 #6" among its sources and is marked Fixed, so these two parts have dropped out of the record.

**Recommendation:** In `assert_tool_called`, print `No $tool call${2:+ with input matching /$2/}.` In both dispatcher arms, reject an empty tool name with `Bad check spec: $check (no tool name)`. Alternatively, record the two parts in the rubric as Open rather than covered by A16.

#### 4. mode1-equiv now reports a Bash tool_use with no string `command` as "FIXTURE/CHECKER SETUP ERROR, not a model result", a shape the model may produce

**Severity:** Minor
**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:120-125` (in `bash_calls`, which ends `:126`; called inside the SetupError `try` at `:173`), `test/skills/eval-helpers.bash:490-494` (label)
**Move:** 3 (consumer contract: what exit 2 means), 4 (error consistency)
**Confidence:** Low. The CLI's recording of a malformed tool call was not probed, and cannot be without `claude`.
**Legibility-target:** a fixture author reading `assert_mode1_equiv` output, and whoever implements the orchestrator's Claim 13 boundary fix.

Evidence. Before 37c5ea9, `(block.get("input") or {}).get("command", "")` turned a missing command into `""`, which then printed `call i: not the Mode 1 wrapper` and exited 1, a model result. Now:
```python
                inp = block.get("input")
                cmd = inp.get("command") if isinstance(inp, dict) else None
                if not isinstance(cmd, str):
                    raise SetupError(f"Bash tool_use {block.get('id')!r} has no string input.command")
                calls.append((block.get("id"), cmd))
```
(excerpt ends `:125`; `bash_calls` returns at `:126` — read)

The dispatcher then prints `mode1_equiv: FIXTURE/CHECKER SETUP ERROR (exit 2), not a model result — fix the spec '<spec>' or the checker's inputs`. The block is not the checker's own input, though. It is what the model emitted. If the CLI records a schema-invalid call as the model sent it, which is how tool-input validation errors usually surface, that is model behaviour, and the label points the author at the spec. In the pipeline today, such a call is likely missing from `permission_denials`, so the generator voids the run first as `Bash tripwire: 1 Bash call(s) … (may have executed)`, and `eval_fixture` stops at the `.failed` marker before `mode1_equiv` runs. So the effect is limited to direct runs of the checker and to the contract text: the docstring (`:31-36`) and 37c5ea9 both present "a transcript event of the wrong shape" as a setup error.

**Recommendation:** When the Claim 13 boundary fix makes the whole checker the exit-2 boundary, decide one rule and state it in the docstring. Either a *model-emittable* shape inside an otherwise well-formed tool_use (a missing or non-string `command`) is a model result (exit 1, `call i: no string input.command`), and only structural damage (non-object events, unhashable ids, a non-list `permission_denials`) is exit 2; or all of it is exit 2, and the label says "malformed transcript" instead of "fix the spec".

#### 5. mode1-equiv's two arity messages use different registers

**Severity:** Informational
**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:161-168` (in `main`, which continues to `:207`)
**Move:** 4
**Confidence:** High
**Legibility-target:** a person running the checker by hand.

Evidence (probe):
```
$ mode1-equiv.py a b                 → mode1-equiv: expected 3 arguments                                   (rc 2)
$ mode1-equiv.py --check-spec a      → mode1-equiv: --check-spec expects 2 arguments: <SKILL.md> <expected>   (rc 2)
```
The new `--check-spec` message names its operands. The positional form it sits beside does not, and it uses a different verb form ("expected" against "expects"). Both are followed by the full docstring, so neither leaves the user stuck.

**Recommendation:** `expects 3 arguments: <SKILL.md> <transcript.jsonl> <expected>`, matching the new line.

#### 6. Small wording, layout and cross-reference drift, including iteration 3's #8, which is not tracked in the rubric

**Severity:** Informational
**Location:** `test/skills/eval-helpers.bash:490-493`; `devcontainer-config/install.sh:62,69,1209,1243`; `docs/decisions/037-bare-host-copy-install.md:76`; `test/skills/mode1-equiv.bats:241`
**Move:** 2, 3, 4
**Confidence:** High
**Legibility-target:** readers of bats output, install output and the decision record.

Precedent: category-first diagnostics (`Generation failed for $fixture: …`, `Unknown check type: …`) used in `test/skills/eval-helpers.bash:82,173`; exit status and Q-ref in separate parentheses in `devcontainer-config/install.sh:1187`; usage text at 83 columns or less in `git show main:devcontainer-config/install.sh` lines 1-80.

- **Label order (iteration 3 #8, carried).** `assert_mode1_equiv` prints the checker's `mode1-equiv: …` line first and its own `mode1_equiv: FIXTURE/CHECKER SETUP ERROR …` label after it. That puts the category second and uses two spellings of the check's name.
- **Lead line (iteration 3 #8, carried).** `ERROR: a process may be acting for an agent. install.sh installs only while no agent can run, because` is still 101 columns (`install.sh:1243`).
- **Usage reflow (new in 37c5ea9).** `Run from inside a Claude Code session, install.sh finds that session and exits 1 at startup,` is 92 columns (`:69`). The reflow of the paragraph above it left this line unwrapped. `:62` is 93 columns, from f9feb2c. On main, no usage line exceeds 83.
- **Usage asymmetry.** For the docker NOTE the usage says "prints a NOTE line at each check". The new sentence for the /proc NOTE says only "prints a NOTE", although it also repeats at each of the four gate calls.
- **Catch-all ERROR (new).** `(exit $rc, Q-062)` merges two parentheticals that `:1187` keeps apart: `(exit $rc) … (Q-058)`. The arm is unreachable today, because the function has no other return (Claim 3).
- **037:76** still cites "(T88–T90)". The blind-scan NOTE it now describes is tested by T91 (Claim 4 scope).
- **Test name.** `mode1-equiv.bats:241` still ends "mode1_equiv resolves by skill". That property is now proven by `:278`, not by this test (Claim 21). Iteration 3 #2 recommended dropping the phrase.

**Recommendation:** Print the label before the checker's output. Wrap `:69` and `:1243` at the block's width. Add "at each check" to the /proc NOTE sentence. Write the catch-all as `failed (exit $rc) (Q-062)`. Add T91 to 037:76. Rename the :241 test to "… parse <Tool>[=<ERE>]; mode1_equiv dispatches".

#### 7. `expect_hit` / `expect_miss` introduce an `expect_` prefix where every assertion helper is `assert_*`

**Severity:** Informational
**Location:** `test/skills/arithmetic-eval-after-denial-patterns.bats:22-33`
**Move:** 2
**Confidence:** High
**Legibility-target:** the next editor of the patterns suite.

Precedent: `assert_*` for assertion helpers, both shared and test-local, used in `test/skills/eval-helpers.bash:186-457`, `test/skills/helpers.bash:98-155`, `test/skills/fact-check-edge-cases.bats:26,36` and `test/hooks/guard-trusted-writes.bats:62,68`. `rg '^expect_' test/` finds only these two.

The helpers wrap `assert_report_matches` / `assert_report_not_matches` under `run`. That design is sound, and the mutation checks (Claim 10) show it is not vacuous. The names are the only thing off-pattern. They are test-local, so the cost is small. I rate this Informational rather than Minor, because nothing outside this file calls them.

**Recommendation:** Optional: `assert_pattern_hits` / `assert_pattern_misses`. Otherwise leave them.

## What Looks Good

- **The rc-4 NOTE now matches its siblings on every axis iteration 3 listed.** It goes to stdout, has the `NOTE: <cause>: <what> not checked, treated as none` shape, appears in the usage text, and has a test (T91) that mirrors T52. Like T52, T91 matches on merged `$output`, so the two are consistent, although neither pins the stream.
- **The gate's rc handling is now a `case` with one arm per documented code and an explicit catch-all.** Iteration 3's "any other rc reads as '/proc is not mounted'" can no longer happen. `procs_in_checkout`'s comment documents codes 2, 3 and 4 in the "Returns …" register.
- **A17 landed as recommended.** The no-init marker is a plain stream-level phrase, like `no result event in the stream`, and the "did the deny rule remove the tool?" hint now appears only when an init event exists and lacks Bash.
- **The new parser-canary marker follows the family**: `Bash <mechanism>:`, a count, the CLI version, and a cause hint.
- **C26 landed as recommended.** Every non-empty wrong `FIXTURE_TOOLS` under deny-record gets one message that states the rule (Claim 23). The comment gives the reason for the ordering.
- **`No init event in $t: not a complete stream-json transcript`** fits its neighbours' `No transcript at $t` / `Could not read … from $t` register. `tool_inputs_checked`'s comment now states its limit accurately (Claim 16a).
- **The `--check-spec` arity message names its operands**, and the strict `NUMBER_RE` makes the validator agree with the documented grammar, apart from the `1e+5` wording nit in Claim 12.
- **The C25 test proves resolution through the dispatcher**, with a stub checker under a second skill name, and it was mutation-checked (Claim 22).

## Summary Table

| # | Finding | Severity | Location | Confidence | Legibility-target |
|---|---------|----------|----------|------------|-------------------|
| 1 | jq-failure marker says "Bash tripwire … could not be read" for all three checks and for a readable file; three consumers treat one bad line three ways | Minor | `test/skills/generate-reports.bash:275-291` | High | operator reading `.failed` |
| 2 | Init canary marker `Bash canary:` vs `Bash parser canary:`; header contract lists 2 of 4 markers | Minor | `generate-reports.bash:300,262-267,31-37` | High | operator grepping markers; DD-doc reader |
| 3 | Iteration 3 #6 edges (`/./` message, empty tool name) unchanged though A16 is marked Fixed | Minor | `test/skills/eval-helpers.bash:420-470,146-164` | High | fixture author; orchestrator |
| 4 | Missing or non-string `command` is now exit 2, "not a model result", for a shape the model may emit | Minor | `mode1-equiv.py:120-125`; `eval-helpers.bash:490-494` | Low | fixture author; Claim 13 implementer |
| 5 | Positional arity message does not name its operands, unlike the new `--check-spec` one | Informational | `mode1-equiv.py:161-168` | High | manual CLI user |
| 6 | Label order, 101- and 92-column lines, usage asymmetry, catch-all parentheses, 037 T-list, stale test name | Informational | `eval-helpers.bash:490-493`; `install.sh:62,69,1209,1243`; `037:76`; `mode1-equiv.bats:241` | High | readers |
| 7 | `expect_hit`/`expect_miss` vs the `assert_*` helper convention | Informational | `arithmetic-eval-after-denial-patterns.bats:22-33` | High | next editor |

## Overall Assessment

37c5ea9 is consistent with the codebase's API patterns, and it introduces no Breaking change. It resolved iteration 3's #1-#5 as recommended:
- the canary no longer misdiagnoses a run with no init event
- a dispatcher test now proves per-skill resolution
- one runner-contract message covers every wrong tools value
- the CLAUDE_FLAGS prose agrees at the named places
- the blind-scan NOTE now matches the docker NOTE

The gate's rc protocol is cleaner than before. What remains is edges of the surfaces this commit touched:
- the one-pass jq's failure marker still carries the tripwire's old label and wording (1)
- the init canary's marker name lags its comment and its sibling, and the header that the DD doc calls the reference lags the code (2)
- two sub-points of iteration 3 #6 were closed under A16 without being fixed (3)
- the new SetupError path raises a real classification question that belongs with the Claim 13 boundary fix (4)

Everything else is Informational. Every item fails closed and can be fixed in place in a few lines, and none changes a result for a committed consumer. Findings 1 and 2 are the ones worth doing before the first real deny-record regeneration, because they decide what an operator reads when triaging a voided run. One more observation, not a new row: the fact-check's Claim 9b shows mode1-equiv's tripwire counting denials of any tool, where the generator's counts Bash denials only. That is the first observed drift between the two implementations C8 warned about. C8 is open by choice, so I only record it here.

## Goal-Alignment Note

- **Success criterion (restated):** "A markdown critique saved to the path named in your role section below, structured per your skill." The file is saved at `docs/reviews/api-consistency-review-2026-09-25-q062-q063-iter4.md`, with `Commit: 5bdee46` at the top. It has the skill's sections: Baseline Conventions, Name-Pattern Audit, Findings, What Looks Good, Summary Table and Overall Assessment. Every finding has Severity, Location, verbatim Evidence, Confidence and Legibility-target. The naming findings (2, 6, 7) each carry a `Precedent:` line. Nothing is committed.
- **Answered:** every focus surface in the brief:
  - failure markers: Findings 1 and 2, and the audit
  - install.sh gate NOTE against the docker NOTEs, and the rc protocol: audit, What Looks Good, Finding 6
  - `tool_inputs_checked` messages: audit, Finding 3
  - mode1-equiv.py CLI and exit contract: Findings 4 and 5
  - runner-contract messages: C26 re-check
  - the patterns test helpers' names: Finding 7
  - regressions: every iteration-3 API item was re-checked (table under Baseline). No regression was found. Finding 3 is an incomplete fix, not a regression.
- **Out of scope / not re-reported:** C13, C24 and iteration-3 Fixed items that were fixed correctly. Claim 13's leak is escalated to the orchestrator; Finding 4 asks only that its fix settle one classification rule. C8 is open by choice (Claim 9b is noted in the Overall Assessment, not as a row). The Claim 12 `1e+5` wording and the Claim 16b/20c "truncated"/"start with" nits belong to the fact-check.
- **Escalate:** Finding 3. The rubric's A16 row is marked Fixed but carries two unaddressed parts of api-consistency iteration 3 #6. The orchestrator should split those out, or mark them Open. Finding 4 should be handed to whoever implements the Claim 13 boundary fix.
- **Probes:** these ran in `…/scratchpad/api4/`: the malformed-event case against all three consumers, the `tool_called` edge cases, and the mode1-equiv arity messages. Their inputs and outputs are quoted inline. They were not saved as execution logs.
