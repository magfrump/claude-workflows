Commit: 0a81388

# Security Review — skill-fixtures, pass 2 (fix diff)

**Scope:** `git diff 4371ec0..0a81388 -- . ':!docs'` (fix commits a2972bf, a75ba3e, c90b97a): `test/skills/generate-reports.bash`, `test/skills/runner-contract.bash` (new), `test/generate-reports.bats`, `test/skills/eval-helpers.bash`, `test/skills/eval-helpers-empty-report.bats` (new), `test/skills/eval-helpers-transcript.bats`, 13 `runner.bash` comment/path edits.
**Date:** 2026-09-24
**Based on:** pass-1 report `docs/reviews/security-review-2026-09-24-skill-fixtures.md` (F1-F7), the pass-1 rubric `docs/reviews/code-review-rubric-2026-09-24-skill-fixtures.md`, `docs/reviews/override-log.md`, and `claude --help` for claude 2.1.282 (run; no model call).

> ⚠️ **No code fact-check report provided for pass 2.** The fix diff's comments and the a75ba3e canary-probe claims have not been independently verified. I checked the shell side by execution; the CLI side rests on `claude --help` text.

Threat model is unchanged from pass 1. The adversary is the model under evaluation, and the exploit class is reward hacking: reading S6, learning a verdict from a fixture name, or scoring a pass without earning it. The secondary concern is that runner authors (agents) make mistakes the harness guard exists to catch.

Execution done for this pass: `bats test/generate-reports.bats test/skills/eval-helpers-empty-report.bats test/skills/eval-helpers-transcript.bats` gave 33/33 ok. `shellcheck -x` on `generate-reports.bash` and `runner-contract.bash` is clean. I ran a 17-value probe of `check_runner_settings` (results below), a RETURN-trap scope probe, and a probe of an inline `cat` failure under `set -euo pipefail`. I made no `claude` model calls and did not run `generate-reports.bash` against real fixtures.

## Closure status of pass-1 findings

| Pass-1 | Status | Evidence |
|---|---|---|
| **F1** Write/Edit exact-token denylist | **Resolved for every spelling pass 1 enumerated. One new bypass is open (Finding 1 below).** | `runner-contract.bash:14` `RUNNER_ALLOWED_TOOLS=(Read Grep Glob WebSearch WebFetch Agent)`. My probe rejects `Read, Write`, `Write(*)`, `read`, `*`, `Read,Gr*`, `Read Bash`, `Read<TAB>Bash`, `none,Read`, `Read,none`, ` none`, `,Read` and `Read,,Grep`. The bats test "a runner naming any tool outside the allowlist is refused" covers 9 spellings (passes). The same allowlist binds every committed runner in the fast test "every committed fixture set has a runner the generator accepts" (passes). The second layer pass 1 recommended, `--disallowedTools`, was not added. `--restricted` stands in for it: per `claude --help`, it "removes the built-in tools that run commands or code (Bash, PowerShell, REPL …) and WebFetch unless --tools names them". The open gap is a value with an embedded newline, which the parser accepts (Finding 1). |
| **F2** repo/tree isolation assumed from cwd | **Resolved (CLI-enforced; the probe is not independently reproduced here)** | `generate-reports.bash:145-146` `local -a claude_args=(-p --system-prompt-file "$SKILL_FILE"` / `--strict-mcp-config --restricted --safe-mode)`. `claude --help`: `--restricted` "Also confines the file tools to the working directories (--add-dir included)". Commit a75ba3e records canary probes: "-p already refused absolute-path Read/Grep into /workspace; --restricted refuses it independently of permission settings." I did not rerun them (paid). Nothing in the diff passes `--add-dir`. |
| **F3** inline mode ran in the real repo; sub-agent reach; ambient context | **Resolved** | `generate-reports.bash:158-165`: every mode now does `temp_dir=$(mktemp -d)`, and inline writes nothing into it. `:189` `(cd "$temp_dir" && printf '%s' "$stdin_text" \`. bats "inline mode: claude runs in an empty temp directory, not the caller's" passes (asserts empty `LS:`/`FILES:`). Sub-agent `--tools` inheritance is from the a75ba3e probe ("No such tool available: Read ... in subagents as well as here"), not reproduced here. Ambient context: `--safe-mode` disables "CLAUDE.md, skills, installed plugins, hooks, MCP servers, custom commands and agents" (help text), and an inline temp dir outside any git repo has no git status. |
| **F4** host hooks fire in fixture runs (routing hint, usage log) | **Resolved per CLI help text; not observed** | `--restricted` "ignores user, project and local settings files", and `--safe-mode` disables "hooks" (help text). Both drop `~/.claude/settings.json` hooks, including `dd-routing-reminder.sh` and `log-usage.sh`. The a75ba3e commit body concedes: "Hook suppression rests on the CLI help text; the probe could not observe hook injection directly." One tc-dd1 run followed by a check that `~/.claude/logs/usage.jsonl` gained no line would confirm it. |
| **F5** CLAUDE_FLAGS/CLAUDE_MODEL word-split, unvalidated | **Still open, settled by override** (Won't-Fix (intended), override-log row 2026-09-24, C4) | `generate-reports.bash:128-129` `model_flag="--model $CLAUDE_MODEL"`, `:191-192` `$model_flag \` / `${CLAUDE_FLAGS:-} \`. Unchanged. I raise no new finding. The one new fact is that the header now makes a categorical promise ("So the model cannot reach expected-verdicts.bash", `:67`) which `CLAUDE_FLAGS="--add-dir /workspace"` or `--settings` would void. The override's revisit trigger (CI or an untrusted caller) still governs. |
| **F6** dotted id leaks suffix | **Resolved as recommended; a narrow residual remains (Finding 4)** | `generate-reports.bash:135-140` `elif [ "$ext" != "$fixture_name" ] && [[ "$ext" =~ ^[A-Za-z0-9]{1,5}$ ]]; then`. bats "a dotted fixture name with no plain extension reaches the model as 'subject'" passes. Every committed extension (cs, go, js, md, patch, py, ts, tsx) still maps to `subject.<ext>`. |
| **F7** aborted run leaves a stale report | **Resolved** | `generate-reports.bash:123` `rm -f "$report_path" "$transcript_path"`, before any step that can fail. bats "a failed claude run leaves no stale report behind" passes. A related residual in A1's fix is Finding 2. |

Re-flagged settled decisions: F5 only (above). It is not re-triaged.

## Trust Boundary Map

```
B1: [fixture file/dir, S1]              → [generate_one: subject-name regex, REQUEST.md append, .fixture-* removal, inline cat] → [model prompt + temp cwd]
B2 (moved): [runner.bash FIXTURE_TOOLS, S2] → [runner-contract.bash allowlist: IFS=',' read -ra split + token match]   → [claude --tools = model capability]
B3 (moved): [model tool calls, S5]      → [--restricted: file tools confined to temp cwd (CLI-enforced)]                    → [repo files: S6]
B4 (moved): [host config, S4]           → [--restricted --safe-mode --strict-mcp-config]                                     → [model context, tools, hooks]
B5: [operator env CLAUDE_FLAGS/MODEL, S3] → [unquoted word-split, no validation (override-logged)]                         → [claude argv]
B6: [model stdout / stream-json, S5]    → [generator `|| true` + jq; eval_fixture empty-report gate]                        → [report scored by eval-helpers]
```

Input-source classification (unchanged labels from pass 1):

```
S1: test/skills/<skill>/fixtures/*     — code-constant — trusted as data for exec/source sinks; NAME secret toward the model
S2: test/skills/<skill>/runner.bash    — code-constant, agent-authored — trusted for exec (sourced); NOT trusted to keep
                                         the capability invariant (that is what the allowlist is for)
S3: CLAUDE_FLAGS / CLAUDE_MODEL        — deploy-time (operator shell) — trusted for exec; unconstrained toward capability
S4: ~/.claude settings/hooks/MCP/memory — runtime-mutable — UNTRUSTED toward eval isolation (now cut off by B4 flags)
S5: model output and tool calls        — request-time — UNTRUSTED (all sinks); adversarial toward eval integrity
S6: expected-verdicts.bash / eval-criteria — code-constant — trusted for source; SECRET toward the model
```

Summary: the fix moves B2 from a denylist to an allowlist, and moves B3 and B4 from placement-by-convention to CLI flags on one shared pipeline. B6 gains an empty-report gate. The remaining gaps are narrow. The allowlist parser accepts a newline-joined value (B2). B6 still ignores claude's exit status, so a failed run that prints anything is not caught by the new gate.

## Findings

#### 1. The allowlist parser reads only the first line of FIXTURE_TOOLS, so a newline-joined value passes the check whole and reaches `--tools`

**Severity:** Medium (floor rule: a named mechanism against the guard's own invariant. Whether the CLI honors it is untested, so that uncertainty goes in Confidence)
**Location:** `test/skills/runner-contract.bash:43-47`; value flows to `test/skills/generate-reports.bash:110`, `:154`
**Boundary:** B2
**Move:** 11 (enumerate bypasses)
**Confidence:** High for the shell mechanism (executed). Low for exploitability: I have not verified that `claude --tools` splits on newlines.
**Legibility-target:** for-author

**Evidence:**
```bash
  if [ "$FIXTURE_TOOLS" != "none" ]; then
    local -a tools
    local tool allowed ok
    IFS=',' read -ra tools <<< "$FIXTURE_TOOLS"
    for tool in "${tools[@]}"; do
```
(excerpt ends inside `check_runner_settings`, which continues to :77. I read all of it. The only other use of `FIXTURE_TOOLS` is the `TOOLS_ARG="$FIXTURE_TOOLS"` copy at `generate-reports.bash:110`, which passes the raw string, not the parsed array.)

`read` stops at the first newline, so only line 1 is validated. Probe results: `$'Read\nBash'` gives ACCEPT and `$'Read\n'` gives ACCEPT. A trailing comma (`Read,`) also gives ACCEPT, because `read -a` drops a trailing empty field. The same gap bypasses the inline file-tool rule: `$'Agent\nRead'` validates as `Agent` only. The check validates a parsed copy, but the CLI receives the unparsed string. So the guard's verdict and the capability actually granted can differ. `--restricted` removes Bash only "unless --tools names them". If the CLI's `--tools` parser treats whitespace or newlines as separators (the neighbouring `--allowedTools` help says "Comma or space-separated"), that value names Bash, and the run gets a shell. The shell can read S6 and write outside the temp dir wherever the sandbox allows. No committed runner does this: every value is a single-line literal. A newline needs `$'…'` or a multi-line quote, so an accident is unlikely. But closing exactly this class of agent-authoring error is the guard's job.

**Recommendation:** Validate the raw string's shape before splitting. For example, reject any value outside `^(none|[A-Za-z]+(,[A-Za-z]+)*)$`. That rejects newlines, spaces, empty and trailing tokens in one step. Then split. Add `$'Read\nBash'` and `Read,` to the bats refusal loop.

#### 2. A1's empty-report gate misses failed runs that print anything: the generator still discards claude's exit status

**Severity:** Low (eval integrity, not secrecy or write capability; same class as pass-1 F4)
**Location:** `test/skills/generate-reports.bash:189-193`; `test/skills/eval-helpers.bash:79-82`
**Boundary:** B6
**Move:** 3 (error path)
**Confidence:** Medium. The mechanism was read in full. Whether `claude -p` writes its failure text (auth, quota, network) to stdout rather than stderr is untested here.
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```bash
  (cd "$temp_dir" && printf '%s' "$stdin_text" \
    | claude "${claude_args[@]}" \
      $model_flag \
      ${CLAUDE_FLAGS:-} \
  ) > "$out_path" 2>/dev/null || true
```
```bash
  if [ -z "$REPORT_CONTENT" ] && [[ ";$key_check;" != *";max_claims:0;"* ]]; then
    echo "Empty report for $fixture: the generation run failed or printed nothing"
    return 1
  fi
```
A1's goal, per the rubric, is that a dead run must not score as a pass on a clean-negative fixture. The gate checks emptiness, not failure. Suppose claude exits non-zero after printing an error line to stdout (text mode). The report is then non-empty, and every absence-only check (`no_severity:`, `no_pattern:` …) passes on it, which is exactly the A1 outcome. The same holds for a whitespace-only report such as a single space, since `$(cat …)` strips only trailing newlines. Transcript mode is unaffected: its report comes from the `result` event only (`:200`).

**Recommendation:** Record claude's exit status, for example `set +e; ( … ); rc=$?; set -e`. On a non-zero status, remove the report (or write a `.failed` marker that `eval_fixture` rejects) and print the WARNING. Optionally treat a whitespace-only report as empty in `load_eval_report`.

#### 3. Inline mode now swallows a failed fixture read and runs the prompt with no fixture

**Severity:** Informational (regression from a75ba3e; not reachable by the model)
**Location:** `test/skills/generate-reports.bash:165`
**Boundary:** B1
**Move:** 3 (error path)
**Confidence:** High (executed: `set -euo pipefail; x="$(printf "%s\n\n%s" P "$(cat /nonexistent)")"` completes with `x=[P]`)
**Legibility-target:** for-author

**Evidence:**
```bash
    stdin_text="$(printf '%s\n\n%s' "$prompt" "$(cat "$fixture_path")")"
```
Before a75ba3e, `fixture_content="$(cat "$fixture_path")"` was a bare assignment, so `set -e` aborted on a read failure. Now the inner substitution's status is lost inside `printf`'s arguments. A run whose fixture is unreadable proceeds with the prompt alone. The model's "nothing to review" answer is a non-empty report that passes absence-only checks (compounds Finding 2). Fixtures are pre-filtered with `[ -f ]` (`:218`), so this needs a permissions or race failure.

**Recommendation:** Read into a variable first, `local fixture_content; fixture_content="$(cat "$fixture_path")"`, then build `stdin_text`.

#### 4. The subject-name rule still passes a descriptive suffix of up to 5 alphanumerics

**Severity:** Informational (latent; no committed fixture triggers it)
**Location:** `test/skills/generate-reports.bash:135-140`
**Boundary:** B1
**Move:** 11
**Confidence:** High
**Legibility-target:** for-automated-gate

**Evidence:**
```bash
  elif [ "$ext" != "$fixture_name" ] && [[ "$ext" =~ ^[A-Za-z0-9]{1,5}$ ]]; then
    subject_name="subject.$ext"
```
This implements pass-1's recommendation exactly. It still maps `tc-3.vuln`, `tc-4.safe`, `tc-5.clean` or `tc-6.bad` to `subject.vuln` and so on, putting a verdict word in the prompt. Committed extensions are cs, go, js, md, patch, py, ts and tsx.

**Recommendation:** Add a fast bats test that runs every committed fixture name through the rule and asserts the result is `subject`, `.` or `subject.` plus a member of a known-extension list. That turns the latent case into a gate failure rather than tightening the regex speculatively.

## Untested bypass candidates

- `FIXTURE_TOOLS=$'Read\nBash'` or `$'Agent\nRead'` at the CLI: whether `--tools` splits on newlines or whitespace (Finding 1). Untested because it needs a `claude` call. A bundle string search found `split(/[\s,]+/)` only in no_proxy and UI code, not in the `--tools` handler, which is inconclusive.
- `FIXTURE_TOOLS=Read,` (trailing comma) at the CLI: harmless if the CLI ignores empty tokens. Untested.
- `--restricted` confinement against `Glob` with `path: "/"` and `Grep` with `path: "/workspace"`. a75ba3e reports that Read and Grep are refused and says nothing about Glob. Untested here (paid).
- Hook suppression under `--restricted --safe-mode` (F4): not observed directly by anyone.
- A failing `claude -p` (bad auth or quota) printing its error to stdout (Finding 2). Untested.

Because of the first candidate, the allowlist guard does not appear in Endorsement Claims as a whole. Only its single-line behaviour is endorsed, and that is scoped.

## `--restricted` / `--safe-mode` compatibility with the non-file runners

- **fact-check (`WebSearch,WebFetch`, inline):** `--restricted` removes "WebFetch unless --tools names them". This runner's `--tools` names it, so WebFetch stays. WebSearch is not in the removed set. The help text shows no breakage.
- **matrix-analysis (`Agent`, inline, transcript):** Agent is not in `--restricted`'s removed set. `--safe-mode` disables "custom commands and agents" but keeps "built-in tools and plugins" working, so built-in sub-agent types stay available. If SKILL.md steers dispatch toward a custom or plugin agent type, that type would be missing, which is a behaviour change for eval calibration, not security. The a75ba3e init count ("plugins (6 -> 2)") shows some plugins are dropped.
- **none-tool runners:** `--tools ""` is unaffected.

## Endorsement Claims

- **Claim:** The allowlist rejects every single-line FIXTURE_TOOLS spelling pass 1 enumerated, plus `*`, glob tokens, lowercase names, empty and leading-comma tokens, and `none` mixed with a tool.
  **Location:** `test/skills/runner-contract.bash:43-67`
  **Evidence:** executed
  **Verified:** the 17-value probe listed in the Closure table, plus the bats refusal loop (9 spellings) and the inline file-tool refusal test, all passing.
  **Not verified:** multi-line values (Finding 1) and the raw `TOOLS_ARG` string the CLI actually parses.
- **Claim:** Every mode builds argv with `--strict-mcp-config --restricted --safe-mode` in that order and runs claude from a fresh `mktemp -d` cwd. For inline mode that cwd is empty.
  **Location:** `test/skills/generate-reports.bash:145-146`, `:158-161`, `:189`
  **Evidence:** executed (bats "every mode passes --strict-mcp-config --restricted --safe-mode" and "inline mode: claude runs in an empty temp directory, not the caller's", both ok)
  **Verified:** the stub-recorded argv, cwd listing and file listing.
  **Not verified:** what the real CLI does with those flags (next claim).
  **route: code-fact-check**
- **Claim:** Under these flags, a repo/tree-mode model cannot Read, Grep or Glob `test/skills/*/expected-verdicts.bash` by absolute path, and inline sub-agents get no file tools. This is the header's promise at `generate-reports.bash:54-67`.
  **Location:** `test/skills/generate-reports.bash:54-67`
  **Evidence:** read-static (help text), plus commit a75ba3e's reported haiku canary probes, which I did not reproduce
  **Verified:** `claude --help` text for `--restricted` ("confines the file tools to the working directories") and `--safe-mode`.
  **Not verified:** the Glob `path: "/"` case, and any run with a non-empty `CLAUDE_FLAGS`.
  **route: code-fact-check**
- **Claim:** The fast test sources each committed runner in its own subshell, after `reset_runner_settings`, so one runner's `fixture_prompt`, `fixture_base` or globals cannot mask another's omission.
  **Location:** `test/generate-reports.bats` (test "every committed fixture set has a runner the generator accepts")
  **Evidence:** executed (test passes). The subshell `msg=$( ( … ) 2>&1 )` was read.
  **Not verified:** runner top-level side effects beyond variable and function definitions. All runners are code-constant.
- **Claim:** The RETURN trap fires once when `generate_one` returns and does not fire when the runner's `fixture_base` returns or for later functions, so the temp dir is not removed early.
  **Location:** `test/skills/generate-reports.bash:159-161`
  **Evidence:** executed (bash probe: trap set in `f` fired on `f`'s return only, not on callee `g` or later `h`)
  **Verified:** the trap-scope semantics in the installed bash.
  **Not verified:** the abort path. Under `set -e`, a failure inside `generate_one` (for example `cp`, `git commit`) exits without firing RETURN and leaves the temp dir. This was pre-existing for repo/tree and now also applies to inline. The contents are fixture copies only, so I cleared it as hygiene.

## Primitive sweep

Primitive: filesystem removal / copy on paths built from S1 or mktemp
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `test/skills/generate-reports.bash:123` `rm -f "$report_path" "$transcript_path"` | S1 name under `$OUTPUT_DIR` | basename-only (`:118`) | cleared: basename cannot contain `/` |
| `test/skills/generate-reports.bash:161` `trap "rm -rf '$temp_dir'" RETURN` | mktemp | single-quoted at trap-set time | cleared: mktemp paths contain no `'`. Leaks on a `set -e` abort (endorsement above) |
| `test/skills/generate-reports.bash:171` `cp -R "$fixture_path"/. "$temp_dir"/` | S1 | none | cleared: no symlinks in committed fixtures (pass-1 check). A future symlink would be neutralized for the model by `--restricted`, not by the copy |
| `test/skills/generate-reports.bash:176` `rm -rf "$temp_dir"/.fixture-*` | mktemp + S1 | temp_dir prefix | cleared |
| `test/skills/generate-reports.bash:178` `cp "$fixture_path" "$temp_dir/$subject_name"` | S1 | subject regex (`:138`) | cleared: `subject_name` is `subject` or `subject.<[A-Za-z0-9]{1,5}>` |
| `test/skills/self-eval/runner.bash:23` `cp -R "$REPO_ROOT/test/skills/self-eval/base/skills/." "$dest/skills/"` | code-constant path | none | cleared: copies base skills only, not S6 |

Primitive: `source` (exec)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `test/skills/generate-reports.bash:97` `source "$SCRIPT_DIR/runner-contract.bash"` | code-constant | none | cleared |
| `test/skills/generate-reports.bash:100` `source "$RUNNER_FILE"` | S2 | `check_runner_settings` after | cleared for exec (S2 trusted to exec). Capability check is Finding 1 |
| `test/generate-reports.bats` fast test `source "$skill_dir/runner.bash"` | S2 | subshell | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Allowlist validates only the first line; `$'Read\nBash'` and `Read,` pass, and the raw string reaches `--tools` | Medium | B2 | `test/skills/runner-contract.bash:43-47` | High (shell) / Low (CLI) |
| 2 | Empty-report gate misses failed runs that print to stdout; exit status discarded | Low | B6 | `test/skills/generate-reports.bash:189-193`, `test/skills/eval-helpers.bash:79-82` | Medium |
| 3 | Inline `$(cat)` failure masked inside `printf` args (regression) | Informational | B1 | `test/skills/generate-reports.bash:165` | High |
| 4 | ≤5-char alphanumeric descriptive suffix still reaches `subject.<ext>` | Informational | B1 | `test/skills/generate-reports.bash:135-140` | High |

## Overall Assessment

The fix diff does what pass 1 asked where it matters most. The capability check is now an allowlist, validated for every committed runner in a fast test. Isolation from the repo, host hooks and ambient context now comes from CLI flags on one shared pipeline instead of from cwd placement. The empty-report gate closes A1's literal case. F1-F4, F6 and F7 are closed. F5 stays open as a logged Won't-Fix. I found no regression in the fact-check or matrix-analysis runners per the CLI help text. The new problems are narrow and fixable in place. The single most important one is Finding 1: validate the raw `FIXTURE_TOOLS` string with an anchored regex, because the string the CLI parses is not the array the guard checked. Finding 2 is the other follow-up, since it leaves part of A1's intent unmet. The review found no findings above Medium within the code paths read. The endorsement claims about CLI confinement are pending execution verification.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** "a markdown critique saved to /workspace/docs/reviews/security-review-2026-09-24-skill-fixtures-pass2.md, with `Commit: 0a81388` at the top, structured per the skill, ending with a Goal-Alignment Note."
- **Answered:** F1-F7 closure with evidence (Closure table). Allowlist parsing edge cases (empty tokens, trailing comma, `none` mixed with a tool, and a newline, which is the one gap): Finding 1 and the probe list. Temp-dir handling and the RETURN trap: an endorsement plus the Primitive sweep. The only new regression is the masked `cat`, Finding 3. `--restricted` versus WebSearch/WebFetch/Agent: a dedicated section, with no breakage per help text. `set -e` interactions: `check_runner_settings … || exit 1` and the `&&` inside its loop behave as intended, and the masked `cat` is the one `set -e` gap. `declare -F` / `unset -f` scoping: endorsement on the subshell-isolated fast test.
- **Out of scope:** the non-fix branch content reviewed in pass 1, and the fixture data, expected-verdicts and eval-criteria contents. I made no paid `claude` runs, so every CLI-behaviour question is under Untested bypass candidates.
- **Escalate:** one paid probe settles Finding 1's exploitability. Run `claude -p --restricted --safe-mode --strict-mcp-config --tools $'Read\nBash'` and ask the model to list its tools. Route it to code-fact-check execution or the user's terminal. The same session can confirm Finding 2 (a run with invalid auth, then check stdout) and F4 (usage.jsonl unchanged after a tc-dd1 run).
- **Decisions I made:** I rated Finding 1 Medium under the floor rule and put the untested CLI half in Confidence. I did not re-triage F5 because it matches a settled override row. I treated the a75ba3e canary-probe results as reported evidence, not as my own verification.
