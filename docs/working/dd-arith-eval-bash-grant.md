# DD: how arithmetic-eval's LLM fixtures test evaluator use (Q-059)

- **Trigger**: user answer to Q-059 (2026-09-25): "This feels like a false dichotomy; can we not test via something like equivalence of the proposed command to some static script? Run divergent design on this to come up with other options."
- **Feeds**: `plan-skill-fixtures-batch4.md` step 5. Q-059 is rewritten from this doc's survivors.
- **Status**: decided. The user answered Q-063 [1] (deny-and-record plus static equivalence) on 2026-09-25. Built the same day; recorded as decisions log #56.

## Motive

The skill exists so the model **never does arithmetic in its head**: every figure goes through the Mode 1 evaluator (a fixed `python3 -c` AST walker fed an inert heredoc) or the Mode 2 gated script. Step 4's gate tests already prove the evaluator is correct and safe. What nothing measures is the *routing*: given a draft with a planted wrong figure, does the model reach for the evaluator, with the right expression, instead of eyeballing it?

The old Q-059 framed this as "execute Bash or measure nothing." But the question is about the model's *choice of command*, and the command is almost entirely fixed text. Mode 1 is a static program plus one variable: the heredoc body. Checking the command is a string-and-AST problem the harness can do offline, with its own trusted copy of the evaluator. Execution is only needed if we also want to observe what the model does *with the result*.

## Harness facts (verified 2026-09-25 against CLI 2.1.282 and the repo)

- Fixture runs pass `--strict-mcp-config --restricted --safe-mode --tools <list>` (`test/skills/generate-reports.bash:154-162`). `runner-contract.bash` allows only `Read Grep Glob WebSearch WebFetch Agent`. [observed]
- `--restricted` removes Bash "unless --tools names them" and ignores user/project/local settings. Managed settings still apply, and this host has none (`/etc/claude-code/` absent). [observed, `claude --help`]
- `--allowedTools` takes prefix patterns like `Bash(git *)`. [observed, help text]
- `--permission-prompts none`: under `--print`, "anything that would prompt is denied automatically". `--permission-mode` has a `dontAsk` choice. [observed, help text]
- The result JSON carries a `permission_denials` array (present, empty, in `runs/review-arms/*/result.json`). [observed] No local transcript contains a *non-empty* denial, so whether a denied Bash `tool_use` block appears in stream-json has not been observed here. [inferred: the assistant message is streamed before the permission decision, and `permission_denials` records `tool_input`] **One probe settles it** (see Open verification).
- `eval-helpers.bash` already parses `tool_use` inputs from the transcript (`assert_tool_called`, line ~351), and `arithmetic-eval-gate.bats` already extracts the Mode 1 program from SKILL.md by exact delimiter lines. Both are reusable. [observed]
- Mode 1's command shape is `( ulimit ...; timeout 5 python3 -c '<program>' ) <<'EXPREOF'`. An allow rule that admits it must admit `timeout 5 python3 -c` with an arbitrary program argument. [observed, SKILL.md:42]

## 1. Diverge

Prior pruning grep (keywords: bash, fixture, allowedTools, shim, permission, wrapper, sandbox): matches in 014 and 015.
- `[7 allowlisted repo wrappers]` from 014 ("an allowlisted executable in an agent-writable repo is arbitrary execution"): **carried forward** against [6] below as far as the wrapper would live in the temp repo. Fixture runs have no Write, but Bash itself is a writer, so a Bash-approved wrapper call can still be chained.
- `[15 nested per-command sandboxes]` from 014 and `[8 bwrap launcher]` from 015: **revived** as [7] below. What's different this time: the scope is a single throwaway fixture run, not the interactive session, which was 014's objection. The WSL2 nested-bwrap fragility still applies.
- Log #53 (auto-approve hook): a prefix filter doesn't descend into heredoc bodies. This is an analog for [1], not a pruned candidate.

| # | Candidate |
|---|---|
| 0 | **Status quo / interim [1]**: gate tests only (step 4, landed), no LLM set. |
| 1 | **Old [2]**: `--tools Bash`, `--allowedTools` limited to python3 shapes, real execution. |
| 2 | **Deny-and-record plus static equivalence** (the user's idea): name Bash in `--tools`, but pin `--permission-mode dontAsk --permission-prompts none` so every call is denied. From the transcript, check that the proposed command *is* the SKILL.md Mode 1 program (normalized), pull out the heredoc body, run it through the harness's own extracted evaluator, and compare to the fixture's correct value. The model executes nothing. |
| 3 | **Equivalence-gated live approval**: same equivalence check, run live as the permission handler (`--permission-prompt-tool` MCP server or an SDK host), so an exact Mode 1 match with a numeric-only body is *allowed* to run and everything else is denied. The model sees real output. |
| 4 | **Dedicated MCP tool**: expose only `arith_eval(expr)` via `--mcp-config`, and tell the model to use it in place of the Bash block. |
| 5 | **PATH shim**: allow Bash, put a recording `python3` shim first on PATH that returns the precomputed answer. |
| 6 | **Fixed wrapper as the only allowed pattern**: ship `ae-mode1` outside the temp repo and allow only `Bash(ae-mode1:*)`. The prompt tells the model the wrapper *is* Mode 1. |
| 7 | **Whole run inside bwrap**: real Bash, read-only root, tmpfs home, only the temp repo writable, network limited to the API (ideal if effort were free). |
| 8 | **Report-tag check, no Bash**: grep the report for `[arithmetic-eval] <expr> -> <value>` (naive: the model can write the tag without running anything). |
| 9 | **LLM judge over the transcript**: a judge rules whether the figures went through the evaluator. |
| 10 | **AST-level golden match** (looser 2): accept any python3 heredoc whose body AST-equals the golden expression, not just the exact Mode 1 program. |
| 11 | **Dry-run disclosure**: no Bash at all. The prompt says "Bash is unavailable; print the exact command you would run", and the check is equivalence on the report text. |
| 12 | **Defer**: build nothing until the A8 measurement / first real generation shows whether models even reach for Bash. |

Health check: 1, 3, 5 and 6 cluster on "grant Bash, then narrow it". Their shared assumption is *execution is needed to measure routing*. Added 2, 8, 10 and 11, which violate it, and 12 (time-shifted). The dimensions covered are permission policy (1, 2, 3, 6), tool set (4, 11), environment (5, 7), and check location (8, 9, 10), so there's no dimensional anchoring.

## 2. Diagnose

| ID | Constraint | Kind | success: |
|---|---|---|---|
| H1 | A fixture run cannot execute a command other than the unmodified Mode 1 program on a numeric body, and cannot write outside its temp dir | hard | a `generate-reports.bats` stub test shows the argv pins the deny/approve flags, and a handler or contract test shows a non-template command (`echo x > /tmp/p`, a Mode 1 program with an appended `; id`) is denied |
| H2 | Distinguishes routing from mental math | hard | against stub transcripts: evaluator on the planted expression **passes**, no Bash call with the right number in the report **fails**, evaluator on the wrong expression **fails**, and a hand-rolled `python3 -c 'print(3600/0.003*1000)'` **fails** (it isn't the evaluator) |
| H3 | Deterministic and stub-testable (no real generation on this branch, memory `run-a8-measurement-after-settling`) | hard | new checks covered by `eval-helpers-transcript.bats` cases with hand-written JSONL, no `claude` invoked |
| H4 | The model can't reach verdicts or criteria | hard | the existing tree/repo-mode leak tests still pass, with no new readable path |
| S1 | Spends no user attention (no pre-mortem review, no new trust decision) | soft | |
| S2 | Tests the skill as written, not a modified procedure | soft | |
| S3 | Observes post-result behavior (uses the returned number, no mental-math fallback on REJECTED) | soft | |
| S4 | Breaks loudly when SKILL.md's Mode 1 block changes | soft | reuses the gate suite's extractor and its non-empty assertion |
| S5 | Small: under about 100 lines of harness code | soft | |

## 3. Match and prune

| # | H1 | H2 | H3 | H4 | S1 | S2 | S3 | S4 | S5 |
|---|---|---|---|---|---|---|---|---|---|
| 0 | ✓ | ✗ | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ | ✓ |
| 1 | ⚠ `python3 -c:*` admits any Python, which is arbitrary execution | ✓ | ~ | ~ reads by absolute path | ✗ | ✓ | ✓ | ✗ | ✓ |
| 2 | ✓ nothing runs | ✓ | ✓ | ✓ | ✓ | ~ the model sees a denial, not a result | ~ | ✓ | ✓ |
| 3 | ~ the handler is a new trust component, a bug in it means shell | ✓ | ~ handler unit-testable, end-to-end needs a real run | ✓ | ✗ needs the pre-mortem | ✓ | ✓ | ✓ | ✗ MCP server or SDK host; whether `--safe-mode` keeps `--mcp-config` servers is unverified |
| 4 | ✓ | ~ | ✓ | ✓ | ✓ | ✗ | ✓ | ✗ | ~ |
| 5 | ⚠ Bash runs for real, the shim confines nothing | ✓ | ~ | ⚠ | ✗ | ✓ | ✓ | ~ | ✓ |
| 6 | ~ [carried 014 [7]] | ~ | ✓ | ✓ | ✗ | ✗ | ✓ | ✗ | ✓ |
| 7 | ✓ if built right | ✓ | ✗ | ✓ | ✗ | ✓ | ✓ | ~ | ✗ |
| 8 | ✓ | ✗ | ✓ | ✓ | ✓ | ✓ | ✗ | ~ | ✓ |
| 9 | ✓ | ~ | ✗ | ✓ | ~ | ✓ | ~ | ✗ | ~ |
| 10 | ✓ | ~ accepts a hand-rolled evaluator | ✓ | ✓ | ✓ | ~ | ~ | ~ | ✓ |
| 11 | ✓ | ~ tests knowledge of the procedure, not reach | ✓ | ✓ | ✓ | ~ | ✗ | ✓ | ✓ |
| 12 | ✓ | ✗ now | ✓ | ✓ | ✓ | – | – | – | ✓ |

Pruned: [0] and [8] (✗ H2). [1] and [5] (⚠ H1: old option [2] as literally specified is worse than it looked, because an allow rule loose enough to admit Mode 1 admits any Python). [7] and [9] (✗ H3; [7] is also dominated by [3]). [4] and [6] (✗ S2 and S4, dominated by [2]). [10] is absorbed into [2] as its **normalization knob**: whitespace-normalize the program, and AST-compare the body. The program itself must still match, or H2's hand-rolled case passes. [12] is absorbed as sequencing: nothing on this branch runs real generation anyway, so any survivor is built now and first run at A8.

Survivors: **[2] [3] [11]**.

Fix sketches:
- [2]: add a **tripwire**. Any Bash `tool_result` that is not a permission denial fails the fixture *and* the run loudly, because execution happened when it must not. The runner contract accepts `Bash` only together with a new `FIXTURE_BASH=deny-record`, and the generator then adds `--permission-mode dontAsk --permission-prompts none`, pinned by a stub argv test. S3 partial fix: a `no_pattern` check that the report doesn't claim the corrected figure as verified after a denial (SKILL.md: "Do NOT fall back to mental math").
- [3]: to keep the handler small, approve on exact match only (normalized program equal to the extracted template, body matching `^[0-9eE.+\-*/%^(), _\n]*$`, no `EXPREOF` line). A stub MCP handler is unit-testable in bats.

## 4. Tradeoff matrix and decision

| Approach | Effort | Risk | Coverage (hard) | Key downside |
|---|---|---|---|---|
| [2] deny-and-record + equivalence | ~0.5 day, ~90 lines (helper ~50, contract/generator ~15, tests ~25 + fixtures) | low | 4/4 | The model's post-denial behavior isn't the real skill flow (it never sees a number). Relies on a denied `tool_use` being recorded, which is one probe away from observed |
| [3] equivalence-gated live approval | ~1.5-2 days (handler plus MCP or SDK plumbing, pre-mortem) | med | 3/4 (H1 ~) | A new trust component, where a matcher bug means shell. The `--safe-mode` × `--mcp-config` interaction is unverified |
| [11] dry-run disclosure | ~2 hours | low | 3/4 (H2 ~) | Tells the model it can't run anything, so it measures whether it *knows* the procedure, not whether it *reaches* for it |

Hypotheses:
- [2]: If chosen, the first A8 generation shows ≥3 of 4 positive fixtures with a denied Bash `tool_use` whose body evaluates to the planted figure's correct value, and the negative fixture shows none. Counter-evidence: the transcripts carry no denied `tool_use` (it isn't recorded), or models stop at the tool-list stage and never attempt Bash.
- [3]: If chosen, the positive fixtures show an executed Mode 1 call and the report cites the evaluator's value. Counter-evidence: the handler approves a non-template command in its own tests, or `--safe-mode` drops the `--mcp-config` server.
- [11]: If chosen, the reports print a Mode 1 block with the right body. Counter-evidence: the models print a paraphrased or hand-rolled command, and the check can't separate "knows" from "would do".

Stress tests:
- **Boring alternative** on [3]: [2] gets the routing signal, which is the motive, for a quarter of the effort and no trust change. [3] only adds S3 (what happens after a real result). That doesn't justify being built first, so [3] becomes [2]'s upgrade path, not a rival.
- **Invert the thesis** on [2]: the sincere case for execution is that a model denied once may retry with variants or give up, so the transcript shows *first intent* only. That still survives: first intent is exactly "did it reach for the evaluator." The retry noise is handled by checking *any* denied call that matches, not just the first.
- **Failure-driven** on [2]: a new failure category is a future CLI change making `dontAsk` or `none` auto-approve. The tripwire (a non-denial Bash `tool_result` fails loudly) plus the pinned-argv test make that fail closed. A second one is the model reading the evaluator source out of the denial message. That's harmless, since the denial text holds no verdicts.
- **Push to extreme** on [11]: with 20 fixtures, [11]'s "I'm told I can't run it" framing trains the check toward recitation. It stays a cheaper fallback only.

```
┌─ DECISION: how arithmetic-eval fixtures test that the model routes figures through the evaluator ─┐
│ 3 candidates survived step-3 pruning · scored on the step-4 axes                                  │
└───────────────────────────────────────────────────────────────────────────────────────────────────┘

  legend   ● strong / low   ◐ partial / medium   ○ weak / high   ✗ fails hard constraint

   #    approach                        effort          risk      coverage      key downside
  ───  ──────────────────────────────  ──────────────  ────────  ────────────  ──────────────────────────────────
   2 ★ deny-and-record + equivalence   ● ~0.5 day      ● low     ● 4/4 hard    ◐ no real result shown to model (mitig.)
   3   equivalence-gated live approve  ○ ~2 days       ◐ med     ◐ 3/4 hard    ○ new trust component; matcher bug = shell
  11   dry-run disclosure              ● ~2 hours      ● low     ◐ 3/4 hard    ◐ measures knowledge, not reach

  expand any other card by naming its #
```

```
╭─ [2] deny-and-record + equivalence   ★ recommended ─────────────────────╮
│ effort    ~0.5 day (~90 lines + 5 fixtures)     risk   low              │
│ coverage  4/4 hard · 3/5 soft (S2, S3 partial)                          │
│ hypothesis  If chosen, the first A8 run shows ≥3/4 positives with a     │
│             denied Mode 1 tool_use whose body evaluates to the correct  │
│             value, and 0 on the negative; counter-evidence = denied     │
│             tool_use not recorded, or no Bash attempt at all.           │
│ stress-tests applied                                                    │
│   · Invert → check any matching denied call, not only the first         │
│   · Failure-driven → tripwire: a non-denial Bash result fails loudly    │
│ key downside  no real result reaches the model; [3] is the upgrade path │
╰─────────────────────────────────────────────────────────────────────────╯
```

```
▶ recommend [2] deny-and-record + equivalence · confidence 80% · runner-up [3], axis = observes post-result behavior vs. no new trust component
```

**Path**: A for the direction (≈80%). [2] is the user's own suggestion made concrete, and it dominates on every hard constraint. The only open choice is whether [3]'s extra signal (S3) is ever wanted. That's an upgrade later, not a fork now.

## Open verification (before implementing [2])

One cheap probe: `claude -p --tools Bash --permission-mode dontAsk --permission-prompts none --output-format stream-json --verbose --strict-mcp-config --restricted --safe-mode "run: echo hi"` with the cheapest model, in a scratch dir. Confirm that (a) an assistant `tool_use` block with `name:"Bash"` and the command appears, (b) its `tool_result` is a denial (`is_error:true`), and (c) `permission_denials` in the final `result` event lists it. If (a) fails, fall back to reading `permission_denials[].tool_input` from the result event. If both fail, [2] collapses to [11].

## What changes in plan step 5

*Superseded by the "As built" section at the end; kept as the plan of record.* Replace the "If [2]" bullets with:
- `runner-contract.bash`: `Bash` is accepted only when the runner also sets `FIXTURE_BASH=deny-record`. Any other Bash grant is still refused, with a test.
- `generate-reports.bash`: when `FIXTURE_BASH=deny-record`, add `--permission-mode dontAsk --permission-prompts none`. A stub argv test pins both, and transcript is forced on.
- `eval-helpers.bash`: a new check, `mode1_equiv:<expected value>`. It finds the Bash `tool_use` inputs, requires the normalized program to equal the extracted Mode 1 template, takes the heredoc body, rejects it if it holds an `EXPREOF` line, runs it through the extracted evaluator, and passes if any call yields `<expected value>`. A second new check, `no_bash_executed`, is the tripwire: fail if any Bash `tool_result` isn't a denial. Both get stub-transcript tests covering H2's four cases.
- Fixtures: repo mode, 4 planted-wrong-figure drafts plus 1 no-math negative (`no_pattern` on the tag, and no Bash `tool_use`).
- The step's `/pre-mortem` trigger is dropped: no execution is granted. It moves to [3] if that upgrade is ever taken.

## Probe results (2026-09-25, user asked "Test [1]")

Two Haiku 4.5 runs with `--tools Bash --permission-mode dontAsk --permission-prompts none --output-format stream-json --verbose --strict-mcp-config --restricted --safe-mode`, run in a scratch dir.

**Probe A: `touch probe-ran && echo hi`.** [observed] (a) The assistant `tool_use` block with `name:"Bash"` and the full command is in the stream. (b) The `tool_result` has `is_error:true` ("denied because Claude Code is running in don't ask mode"). (c) The result event's `permission_denials` lists `tool_name`, `tool_use_id` and `tool_input.command`. `probe-ran` was not created, so nothing executed.

**Probe B: SKILL.md as `--append-system-prompt`, plus a plain claim ("$4,750 at $0.0025/1K tokens ≈ 1.9B tokens?").** No mention of the evaluator.
- [observed] The model reached for Mode 1 unprompted. The streamed command and `permission_denials[0].tool_input.command` are byte-identical, so either source works.
- [observed] **The command was not byte-identical to SKILL.md.** Haiku dropped every Python comment. A byte-exact check would have failed a correct run.
- [observed] The following check separated it correctly: the shell wrapper matches the regex exactly, and the embedded Python program equals SKILL.md's by `ast.dump`, which ignores comments. A one-token tamper (`MAX_BITS = 100001`) was rejected. The expression `4750 / 0.0025 * 1000` came out of the heredoc intact.
- [observed] After the denial, the model answered with mental math ("the number is correct"). SKILL.md says not to fall back. So [1] also sees a second behavior: what the model does after a denied evaluator. The fixture can grade that as its own assertion (it should report that it could not verify), or ignore it. It is not the skill's real post-result flow either way.

**Consequence for the design:** the equivalence helper compares by AST, not bytes. The `permission_denials` fallback is not needed. The stream already carries the command. (What the helper checks as built is in "As built" below.)

## As built (2026-09-25, review-fix loop iteration 1)

- **Deny flags.** `generate-reports.bash` pins `--disallowedTools 'Bash(**)' --permission-mode dontAsk --permission-prompts none`. Probe A above was misleading on its own: `touch` was denied only because it writes. Under `dontAsk` alone, `pwd`, `ls` and `echo marker-$((6*7))` all **executed**, with `permission_denials` empty (review A2 probe). `--permission-mode manual` behaved the same (it reports as `default`). A `Bash(*)` deny rule removes the tool from the model (init `tools: []`), and the model then writes fake calls as text. `Bash(*:*)` denied nothing, and `Bash(* *)` denied only commands containing a space. `Bash(**)` kept Bash visible and denied every call: `pwd`, `ls`, `echo`, `true`, a 41-line Mode 1 heredoc and a two-line write, all recorded in `permission_denials`, with nothing created on disk.
- **Contract.** The code is the reference: the `FIXTURE_BASH` entry in `generate-reports.bash`'s header, `DENY_RECORD_FLAGS` below it, and `check_runner_settings` in `runner-contract.bash`. In short: `FIXTURE_BASH=deny-record` needs `FIXTURE_TRANSCRIPT=1` and `FIXTURE_TOOLS=Bash` exactly, and refuses any non-blank `CLAUDE_FLAGS` (a denylist of flag names could not hold); the model comes from `CLAUDE_MODEL`, passed as one argument.
- **One strict transcript reader** (`test/skills/transcript.jq`, review iterations 4-5, R2-R4). The generator and every eval check read transcripts through it, and it decides the verdict: a list of failure strings ending in a sentinel line, so a verdict cut short can never read as a pass. Its calls are a **census**: every object with `"type": "tool_use"` at any depth of any event, found by recursion. That one list is validated, counted and read by the checks, so a call cannot be counted without being checked, or checked without being counted. A call anywhere but an assistant event's `message.content` makes the transcript malformed. Iteration 4's reader validated some positions and counted from others, and a review's insertion probe put a call past it in 20 of 22 positions. An insertion property test now puts an undenied call at every object and array position and requires every variant to fail, both end to end and in the eval checks. Event and content-block types are allowlisted, tool_use ids must be unique, and a line containing `{` or `[` that does not parse is a problem; a plain-text line is ignored. The accepted shapes are those of 13 real runs on CLI 2.1.282/283, where the census found exactly the positional calls.
- **Run voiding.** The rules are the module's `transcript_failures` (every transcript run) and `deny_record_failures` (deny-record), described once in the module and summarized in `generate_one`'s "Transcript checks" comment. Deny-record adds: the init event's tools exactly `["Bash"]`, every call a Bash call, every call denied (tripwire), every Bash denial and every `tool_result` answering a call in the census (parser canaries), and no denial of another tool. The `.failed` marker is fail-closed.
- **Residual, accepted.** These checks catch accidental breaches, not concealed ones: a command that did run could rewrite the transcript before it is read. The accepted shapes are the CLI's observed ones, so a CLI format change voids runs until the module is updated (fail-safe).
- **`mode1_equiv:`** (`assert_mode1_equiv` in `eval-helpers.bash`, plus the skill-owned `test/skills/arithmetic-eval/mode1-equiv.py`). The helper requires the transcript to pass `deny_record_failures`, then hands the checker only the list of attempted commands. The checker requires, per command:
  - the Mode 1 head (`( ulimit … python3 -c '` … `' ) <<'EXPREOF'`) to match exactly;
  - the heredoc to close at the **first** line equal to `EXPREOF`, as in bash, with only blank or `#` lines after it;
  - the program to equal SKILL.md's by `ast.dump`;
  - the expression to give a listed value when run through the evaluator extracted from SKILL.md.
  That evaluator must first pass a self-test (`6 * 7` gives 42), in `--check-spec` too. The checker exits 0 on a match, 1 when no command computed the value, and 2 on anything else, including any error it did not anticipate.
- **Fixtures.** Inline mode, 5 drafts: 3 wrong figures, 1 correct figure and 1 with no arithmetic (`no_tool_called:Bash`). The after-denial tests (no mental-math fallback) are opt-in via `AE_GRADE_AFTER_DENIAL=1`.

