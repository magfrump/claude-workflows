Commit: d8c43ae

# Security Review: skill-fixtures (Q-062 [2] / Q-063 [1]), review-fix loop iteration 2

**Scope:** `git diff main...HEAD` on `skill-fixtures` (HEAD d8c43ae). Focus: iteration 1's fixes in 8664e22, the new `Bash(**)` deny mechanism, `split_mode1`, and the Claim 2 escalation.
**Date:** 2026-09-25
**Based on:** `docs/reviews/code-fact-check-report.md` (commit d8c43ae, 39 claims). Its executed verdicts are used here and not re-verified.
**Delivery mode:** self-read. No `claude` or network command was run. Two stub/bash probes were run; their commands and outputs are quoted in F1 and F3.

---

## Trust Boundary Map

```
B1 (new):  [model's Bash tool_use command]      → [CLI: --disallowedTools 'Bash(**)' + dontAsk + prompts none] → [host shell, fixture temp dir]
B2 (new):  [operator env: CLAUDE_FLAGS, CLAUDE_MODEL] → [deny-record flag refusal, generate-reports.bash:124-134] → [claude argv, after the pinned flags]
B3 (new):  [stream-json transcript (CLI-written; strings inside it are model text)] → [tripwire: generator jq + mode1-equiv.py] → [.failed marker / grading verdict]
B4 (new):  [the command the model tried (S1 via S3)] → [split_mode1 + ast.dump equality] → [reference evaluator subprocess in the grader]
B5 (new):  [same-uid processes' /proc entries]  → [procs_in_checkout: -O, readlink cwd, in_lineage] → [agent_gate refuse/allow decision]
B6 (new):  [fixture-author check specs (expected-verdicts.bash)] → [parse_expected / assert_no_tool_called ERE] → [pass/fail of a fixture]
```

| Label | Source | Mutability | Trust classification (per sink) |
|---|---|---|---|
| S1 | The model's Bash `command` string | request-time | UNTRUSTED for the exec sink. That is what B1 exists to stop. UNTRUSTED for grading, where it must be parsed at least as strictly as bash. |
| S2 | `CLAUDE_FLAGS`, `CLAUDE_MODEL` | operator env, per run | Trusted for intent: it is the operator's own machine (settled C4). Treated as error-prone toward the permission-argv sink, and the deny-record refusal exists to catch those mistakes. |
| S3 | Transcript JSONL | request-time (CLI-written) | Trusted for event structure, since only the CLI emits events. Untrusted for the string contents, which are model text. |
| S4 | `skills/<skill>/SKILL.md` Mode 1 block | code-constant (repo) | Trusted as the reference program. The model has no write tool. |
| S5 | `/proc/<pid>/{cwd,cmdline,status}` of same-uid processes | runtime, controlled by the process | UNTRUSTED. A process chooses its own cwd, cmdline and dumpability, which is why A1 exists. PPid is kernel-set, but a process can re-parent by double-forking. |
| S6 | `KEY_CHECK` specs (`mode1_equiv:`, `no_tool_called:`) | code-constant | Trusted for intent. It is fixture-author input, so errors in it must fail closed. |

Two things cross boundaries here. Model text crosses B1 as a command the CLI must refuse, and B3/B4 as data the grader parses and partly executes (the expression, through S4's evaluator). Operator environment crosses B2 into the same argv as the pinned deny flags. Process state crosses B5 into the install gate. The diff assumes three things: S2 reaches claude's argv only through `CLAUDE_FLAGS`; the CLI's `Bash(**)` matcher behaves as it did when probed; and a mounted `/proc` is a functioning one.

---

## Findings

#### F1: `CLAUDE_MODEL` word-splits into claude's argv after the pinned deny flags, and the deny-record refusal never scans it. The refusal is also a denylist with unprobed gaps.

**Severity:** Low
**Location:** `test/skills/generate-reports.bash:160-163`, `:124-134`, `:234-238`
**Boundary:** B2 (and B1, whose flags it can follow)
**Move:** #11 (enumerate bypasses), #12 (exec primitive sweep)
**Confidence:** High for the argv mechanism (executed stub probe). Low for its effect: whether a later `--permission-mode bypassPermissions` overrides a `Bash(**)` deny rule is CLI behavior, and it was not probed.
**Legibility-target:** for-author

The refusal added under deny-record scans only `CLAUDE_FLAGS`:

```bash
# test/skills/generate-reports.bash:124-126 (excerpt; the if-block continues to :134 with the case list and exit 1)
if [ "$FIXTURE_BASH" = "deny-record" ]; then
  flags_words=" ${CLAUDE_FLAGS:-} "
  flags_words="${flags_words//[[:space:]]/ }"
```

`CLAUDE_MODEL` is interpolated into a string and expanded unquoted after the pinned flags:

```bash
# test/skills/generate-reports.bash:161-163
  if [ -n "${CLAUDE_MODEL:-}" ]; then
    model_flag="--model $CLAUDE_MODEL"
  fi
```
```bash
# test/skills/generate-reports.bash:234-238
  (cd "$temp_dir" && printf '%s' "$stdin_text" \
    | claude "${claude_args[@]}" \
      $model_flag \
      ${CLAUDE_FLAGS:-} \
  ) > "$out_path" 2>/dev/null || rc=$?
```

Probe: a copy of `test/generate-reports.bats` was run against the stub claude with `make_deny_skill`, one variable set per run. The output is from `bats -f PROBE`, run in the scratchpad.

```
== CLAUDE_MODEL=m --permission-mode bypassPermissions -> status=0 refused=no
ARGS: … --tools Bash --disallowedTools Bash(**) --permission-mode dontAsk --permission-prompts none --model m --permission-mode bypassPermissions
== CLAUDE_FLAGS=--disallowedTools= --tools Bash,Read -> status=0 refused=no
== CLAUDE_FLAGS=--setting-sources user,project -> status=0 refused=no
== CLAUDE_FLAGS=--mcp-config x.json -> status=0 refused=no
== CLAUDE_FLAGS=--add-dir / -> status=0 refused=no
== CLAUDE_FLAGS=--agents {} -> status=0 refused=no
```

The generator's own comment says "a later --permission-mode would win", and `CLAUDE_MODEL` places one later. The attack scenario is operator error, not an attacker: a model string pasted with a trailing flag. The tripwire (B3) would then void the run after the fact. It would do so only if the CLI does not list the executed call in `permission_denials`, and only after the command has run. The other passing flags are not proven harmful. Whether `--setting-sources` re-enables the user settings that `--restricted` ignores, whether a repeated `--tools` concatenates and breaks the "Bash exactly" invariant (C9), and whether `--mcp-config` adds tools that dontAsk handles differently are all CLI questions (see Untested bypass candidates). The structural point is that a denylist over flag names can only be as complete as the author's knowledge of the CLI. The deny-record path has a narrow legitimate need: choosing a model.

Settled C4 ("CLAUDE_FLAGS/CLAUDE_MODEL unvalidated", Won't-Fix) is not re-litigated. This finding is about the new guard, whose stated purpose ("CLAUDE_FLAGS must not loosen what the pinned permission flags deny") a sibling variable defeats.

**Recommendation:** Under deny-record, pass the model as one argv element (`claude_args+=(--model "$CLAUDE_MODEL")`, which also removes the SC2086 split). Invert the `CLAUDE_FLAGS` check to an allowlist of words (for example, only `--model`/`--max-turns`/`--effort` and their values), or refuse `CLAUDE_FLAGS` entirely under deny-record. Add `CLAUDE_MODEL='m --permission-mode bypassPermissions'` to the refusal test.

---

#### F2 (Claim 2 escalation): the Q-062 gate fails silently when cwd links are unreadable, and the docs promise a "readable /proc". This is framing for Q-064, not a new mechanism.

**Severity:** Low. The mechanism is A1's (Acknowledged, Medium, pending Q-064), and this entry does not re-flag the per-process skip. What is new is that the skip is silent and that the docs overclaim.
**Location:** `devcontainer-config/install.sh:62`, `:74-75`, `:1150`, `:1154`, `:1186-1190`; `docs/decisions/037-bare-host-copy-install.md:76`
**Boundary:** B5
**Move:** #3 (error path), #5 (invert the check: what does it not cover?)
**Confidence:** High on the code path (read, and fact-check Claim 2 executed T90). Medium on reachability: it needs a host where cwd links of other same-uid processes are unreadable or invisible, which was not observed on the target host.
**Legibility-target:** for-author

```bash
# devcontainer-config/install.sh:1150 and :1154 (excerpts; procs_in_checkout spans :1148-1162, read in full)
  [ -d /proc/self ] || return 2
…
    cwd="$(readlink "$d/cwd" 2>/dev/null)" || continue   # unreadable: see above
```

The docs promise more than the precondition checks: "Needs git, perl …, pgrep and a readable /proc (Linux); refuses without them" (`:74-75`), and the error string "/proc is not readable" (`:1188`) prints only when `/proc/self` is absent. Three environments satisfy `[ -d /proc/self ]` while the scan sees nothing:

- An LSM that denies ptrace-read on other tasks. `readlink` fails for every non-lineage process, so every one is skipped.
- A PID namespace, such as a terminal inside a sandboxed app. Other processes are simply absent, and the pre-existing pgrep check is blind the same way.
- A `/proc` implementation without cwd links.

In each case `agent_gate` returns 0 with no output. That breaks the file's own convention: when docker is unreachable, the gate prints `NOTE: … not checked, treated as none running`.

For Q-064, "refuse vs skip" is not the only choice. A third option addresses both A1 and Claim 2 without ssh-agent nuisance refusals: **[3] skip but name**. Count the same-uid, non-lineage processes whose cwd could not be read, and print a NOTE listing their PID and cmdline (`/proc/<pid>/cmdline` stays readable for non-dumpable processes). Pass the list through `vis_or_die` like the refusal block. On a normal host the user sees `ssh-agent` and recognises it, and an unexpected entry becomes visible instead of silent. A whole-`/proc` failure then shows up as an unusually long NOTE, not as a clean pass. This is not theater, because the NOTE's content varies with what the scan could not see. The PID-namespace case stays invisible to every in-namespace check, and belongs in 037's "does not see" list.

**Recommendation:** Reword `:74-75` and 037:76 to "a mounted /proc (cwd links it cannot read are skipped; see Q-064)", and the `:1188` message to "/proc is not mounted". Add option [3] to Q-064. Add "a terminal in a PID-namespaced sandbox" to 037's residuals.

---

#### F3: `no_tool_called:` passes when its ERE is invalid or the transcript cannot be read

**Severity:** Informational (grading integrity for fixtures, not an execution property)
**Location:** `test/skills/eval-helpers.bash:408-417`
**Boundary:** B6 (S6 into the check); B3
**Move:** #3 (error path)
**Confidence:** High (executed)
**Legibility-target:** for-author

```bash
# test/skills/eval-helpers.bash:411 (excerpt; assert_no_tool_called spans :408-417, read in full)
  hits="$(transcript_tool_inputs "$t" "$tool" | grep -iE "$pattern" || true)"
```

`|| true` absorbs both grep's no-match status (1) and its error status (2), and the pipe discards jq's failure. The probe used a one-line transcript holding a Bash call `rm -rf x`:

```
grep: Unmatched ( or \(
invalid-ERE rc=0          ← no_tool_called:Bash=rm ( passes with the call present
valid rc=1
jq: error: Could not open file …/t.jsonl: Permission denied
unreadable rc=0           ← passes on an unreadable transcript
```

This is the only absence check that guards a negative fixture (`tc-ae5`: `no_tool_called:Bash`). A typo in a future `<Tool>=<ERE>` spec reads as "the model behaved". `eval_transcript_path` checks `-f` but not readability. The same fail-open class is behind Claim 25b (mode1-equiv exits 1 on author errors), which the orchestrator is fixing structurally. Mode1-equiv fails closed, though, and this check fails open.

**Recommendation:** Distinguish grep status 1 from 2+ (`grep -iE … ; rc=$?; [ $rc -le 1 ] || { echo "no_tool_called: bad ERE"; return 1; }`), and run jq outside the pipe so its failure fails the check.

---

#### F4: "Nothing executes" rests on an unpinned CLI's rule matcher, and the argv test does not pin argv element boundaries

**Severity:** Informational (residual of A2, which is Fixed. The prevention is sound only as far as the probes reach, and detection is in place.)
**Location:** `test/skills/generate-reports.bash:191-193`, `:259-278`; `test/generate-reports.bats` ("deny-record: Bash is accepted and every call is pinned to be denied")
**Boundary:** B1, B3
**Move:** #1, #11
**Confidence:** Medium
**Legibility-target:** for-author

```bash
# test/skills/generate-reports.bash:191-193
  if [ "$FIXTURE_BASH" = "deny-record" ]; then
    claude_args+=(--disallowedTools 'Bash(**)' --permission-mode dontAsk --permission-prompts none)
  fi
```

The probes in the DD doc's "As built" section show that matcher semantics are fragile across near-identical spellings. `Bash(*)` removes the tool, `Bash(*:*)` denies nothing, and `Bash(* *)` denies only commands containing a space (fact-check Claims 12/30b: Unverifiable here). A CLI update that shifts `**` toward either neighbour degrades differently:

- Toward "removes the tool": the fixtures fail loudly, because mode1_equiv finds no call.
- Toward "denies nothing": dontAsk's read-only auto-approval (`pwd`, `ls`, `echo` executed) comes back. The tripwire then voids the run, but only after the command has run. Commands the CLI classes as read-only include reads of any user-readable file, and their output would land in the kept transcript.

The commit notes this ("the argv test pins the flag but cannot check that the CLI still honours it"). Nothing records which CLI version the probes covered, and nothing records which version a given run used. Separately, the stub records `"$*"`, so the argv assertion pins the token order but not the element boundaries. It also does not pin the absence of later contradicting flags, which is F1's vector.

**Recommendation:** Write `claude --version` into each run's output (or into `.failed` on a tripwire hit), and write the probed version into the DD doc's "As built" section, so a matcher regression can be attributed. Optionally, have the stub record one argv element per line and assert `Bash(**)` as a whole element.

---

No Critical or High findings. No HALT escalation pattern matched.

## Iteration-1 fix verification (regressions from 8664e22)

| Fix | What was checked | Result |
|---|---|---|
| C11: ENVIRON instead of `awk -v` (`install.sh:1195-1197`) | Read the whole `agent_gate`. `CW_SEEN=""` gives `split` n=0 and an empty skip set. The dedup keys on field 1 only. Fact-check Claim 7 executed the escape case. | No regression. The residual (a real newline inside a Claude argv drops a PID from the in-checkout *list*) still refuses, because `$procs` is non-empty. |
| return 3 path (`:1151`, `:1183-1186`) | `rc` is reset to 0 after pgrep (`:1180`), then set only by `procs_in_checkout`. The loop body always ends in `continue` or `printf`, so only 2 and 3 can escape (Claim 4). `set -e` is not inherited into `$(…)` (no `inherit_errexit` in the file), so a mid-scan `tr` failure on an exiting process cannot turn into a spurious rc. `REPO_ROOT` is absolute (`:105`), so `CDPATH` cannot add output to `root`. | No regression. It fails closed with a distinct message. |
| C10: tripwire on an already-failed run (`generate-reports.bash:263-278`) | The block sits outside the `[ -z "$failure" ]` guard and appends. An empty transcript counts 0 (Claim 32 scope), and the `claude exited N` failure still stands. A Bash id missing from the denial list counts as undenied, including a null id against an empty list. | No regression. |
| C9: `FIXTURE_TOOLS=Bash` exactly | `runner-contract.bash:108-112` | Holds for the runner. F1 notes that a repeated `--tools` in `CLAUDE_FLAGS` is not refused (CLI effect unprobed). |
| C12: whitespace folding, `--permission-prompt-tool` | Claim 31 (executed), plus the `=`-form traced: `--permission-mode=x` still contains ` --permission-mode`. | Holds for `CLAUDE_FLAGS`. It does not cover `CLAUDE_MODEL` (F1). |
| A3: `split_mode1` | See the section below. | Holds. |
| A10 / Claim 25b | All the paths that stray from the stated exit code fail closed. There is no false pass, so there is no security angle. The orchestrator owns the fix. | Not re-filed. |

## `split_mode1` vs bash (focus b)

`split_mode1` was read in full (`mode1-equiv.py:49-63`), together with `HEAD_RE` (`:36-40`) and `TAIL_LINE_RE` (`:41`). The fact-check executed 7 edge cases against real bash (Claim 21), and none accepted a command in which the shell ran extra text. Four more points were traced:

- `HEAD_RE` requires `\n` immediately after `<<'EXPREOF'`, so nothing can follow the redirection on the operator line (for example `; touch x`).
- The program is `[^']*` inside single quotes, so no shell expansion happens there, and it must also be AST-equal to S4.
- `cmd[m.end():].split("\n")` splits only on LF, like bash. `str.splitlines()` would also have split on `\x0b`, `\x0c` and ` `, and could have produced a spurious `EXPREOF` line that bash does not see. The code does not do that.
- `lines.index("EXPREOF")` is an exact match, so `EXPREOF\r`, `EXPREOF ` and tab-indented forms do not close the heredoc here. bash does not close it on those either, because the operator is `<<`, not `<<-`.

A missing terminator returns None, while bash would warn and run anyway, so the parser is stricter than bash there. The grader then runs S1's expression through S4's AST evaluator without the Mode 1 `ulimit` (Claim 22 scope). The evaluator allows only numeric constants and arithmetic operators, with a `MAX_BITS` cap, and runs under a 10 s timeout. The result regex reads the value the evaluator appends *after* the echoed expression, so a model-written `-> 1900000000` inside the expression cannot supply the value.

## Untested bypass candidates

**Deny-record `CLAUDE_FLAGS` refusal (B2):**

| Candidate | What was established | Why the rest is untested |
|---|---|---|
| `--setting-sources user,project` | Passes the scan (probed). | Whether it overrides `--restricted`'s "settings files ignored", and whether a user `permissions.allow`/`defaultMode` then beats the `Bash(**)` deny, needs a `claude` run. |
| A repeated `--tools Bash,Read` / `--disallowedTools ''` | Passes (probed). | Whether commander concatenates or replaces repeated variadic options is CLI behavior, not probed. |
| `--mcp-config x.json` alongside `--strict-mcp-config` | Passes (probed). | The added MCP tools are outside the Bash tripwire. Their handling under dontAsk is not probed. |
| Environment variables the CLI reads, and host managed/policy settings | Not enumerable from this repo. | Needs CLI documentation or a probe. |

Traced and dispositioned:

- `CLAUDE_MODEL` split: a bypass (F1).
- `--permission-mode=…`: caught by the prefix match.
- `--permission-mod[e]` glob: passes the scan. It expands in the fixture temp dir, which is empty in inline mode, so the CLI receives an unknown flag.

**`procs_in_checkout` (B5):**

| Candidate | Why untested |
|---|---|
| A same-uid process in another mount namespace (bwrap, bind mount), whose `/proc/<pid>/cwd` resolves to a path string other than `pwd -P` of the checkout | Needs a namespaced probe. It is a variant of 037's "working outside the checkout" residual. |
| A PID-namespaced terminal running install.sh | Needs a sandboxed terminal. See F2. |
| An open fd on the checkout with cwd `/` | Known and documented (Q-064 context). Not a new candidate. |

These guards therefore appear in no endorsement below.

## Endorsement Claims

- **Claim:** `split_mode1` returns a (program, expression) pair only when everything after the first exact `EXPREOF` line consists of blank lines or `#` comment lines, and it splits on LF only.
  **Location:** `test/skills/arithmetic-eval/mode1-equiv.py:49-63`
  **Evidence:** read-static (and fact-check Claim 21, executed against bash on 7 cases)
  **Verified:** read the full function, `HEAD_RE` and `TAIL_LINE_RE`, and traced the LF-only split and the exact-match `index`.
  **Not verified:** inputs holding NUL bytes. JSON can carry `\u0000`, which bash could not receive in argv at all, and this was not run.
  **route: code-fact-check**

- **Claim:** The deny-record tripwire in `generate_one` runs whether or not an earlier failure was recorded, and appends to it.
  **Location:** `test/skills/generate-reports.bash:263-278`
  **Evidence:** read-static (and fact-check Claim 32, executed for the error-result path)
  **Verified:** the block's placement relative to the `[ -z "$failure" ]` block (`:249-258`) and the `failure="${failure:+$failure; }$trip"` append.
  **Not verified:** the `claude exited N` path with a non-empty transcript. No stub exits non-zero after emitting a Bash call.
  **route: code-fact-check**

- **Claim:** In `agent_gate`, a `procs_in_checkout` return of 3 prints the path-resolution error and exits 1, and any other non-zero return prints the /proc error and exits 1. Neither path reaches `return 0`.
  **Location:** `devcontainer-config/install.sh:1180-1190`
  **Evidence:** read-static
  **Verified:** the `rc=0` reset at `:1180`, the if/elif with an `exit 1` in each branch, and the function's two `return` statements (`:1150-1151`).
  **Not verified:** execution of rc 3. No test makes `cd "$REPO_ROOT"` fail (Claim 4 scope).
  **route: code-fact-check**

- **Claim:** The process-controlled cmdlines printed in the Q-062 refusal pass through `vis_or_die` before they reach the terminal.
  **Location:** `devcontainer-config/install.sh:1227-1240`
  **Evidence:** read-static
  **Verified:** the `{ … } | vis_or_die >&2` grouping encloses the `printf '%s\n' "$inrepo"` line.
  **Not verified:** `vis_or_die`'s behavior on a cmdline holding UTF-8 C1 bytes, which is its own pre-existing test surface (`:156`).

## Primitive sweep

**Primitive: process exec**

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `generate-reports.bash:234-238` `claude "${claude_args[@]}" $model_flag ${CLAUDE_FLAGS:-}` | S2 | `CLAUDE_FLAGS` denylist only | F1 (`CLAUDE_MODEL` unscanned; denylist gaps) |
| `generate-reports.bash:192`: the pinned deny flags handed to the CLI's Bash tool, which executes S1 | S1 | `Bash(**)` + dontAsk + tripwire | F4 (probe-dependent; detection only after the fact) |
| `mode1-equiv.py` `evaluate`: `subprocess.run(["python3","-c",program], input=expr)` | S4 program, S1 expr | list argv with no shell; program from SKILL.md; AST evaluator; 10 s timeout | cleared: S1 reaches only the numeric AST evaluator |
| `eval-helpers.bash` `assert_mode1_equiv`: `python3 "$checker" …` | S6 (`$skill` from the suite) | `-f` check | cleared: repo-owned path |
| `install.sh:1154,1158` `readlink` / `tr < $d/cmdline` | S5 | `$d` comes from the `/proc/[0-9]*` glob, quoted | cleared: path fixed by the glob; content only printed |

**Primitive: deserialization**

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `mode1-equiv.py` `events`: `json.loads` per line | S3 | stdlib JSON; `ValueError` skipped | cleared: no object hooks |
| `generate-reports.bash:247-270` jq `fromjson?` | S3 | jq | cleared |
| `eval-helpers.bash:367-369` `transcript_tool_inputs` jq | S3 | jq | its failure is swallowed downstream (F3) |

**Primitive: regex/pattern evaluation of author input**

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `eval-helpers.bash:411` `grep -iE "$pattern"` | S6 | none (`\|\| true`) | F3 |

**Primitive: terminal output of untrusted text**

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `install.sh:1230` in-checkout cmdline list | S5 | `vis_or_die` | cleared (endorsement 4) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---|---|---|---|---|
| F1 | `CLAUDE_MODEL` splits into argv after the pinned deny flags, unscanned. The denylist has unprobed gaps. | Low | B2, B1 | `generate-reports.bash:160-163, 124-134, 234-238` | High (mechanism) / Low (CLI effect) |
| F2 | The Q-062 gate is silently blind when cwd links are unreadable or invisible. The docs promise a "readable /proc". Q-064 framing: add [3] skip-but-name. | Low (the mechanism is A1's) | B5 | `install.sh:62, 74-75, 1150, 1154, 1188`; 037:76 | High (code) / Medium (reach) |
| F3 | `no_tool_called:` passes on an invalid ERE or an unreadable transcript. | Informational | B6, B3 | `eval-helpers.bash:408-417` | High |
| F4 | "Nothing executes" depends on an unpinned CLI matcher. No CLI version is recorded, and the argv test does not pin element boundaries. | Informational | B1, B3 | `generate-reports.bash:191-193`; `generate-reports.bats` | Medium |

## Overall Assessment

Iteration 1's fixes hold. Nothing regressed in the C11 ENVIRON change, the return-3 path or the tripwire-on-failed-run change. `split_mode1` now agrees with bash's heredoc termination on every case traced or executed. The deny mechanism is the right shape: a deny rule, a mode that refuses prompts, and an after-the-fact tripwire that fails closed. Its weak point is the refusal of operator flags. That refusal is a denylist over one of two environment variables, and `CLAUDE_MODEL` puts arbitrary flags after the pinned ones (F1). That is the single most important thing to fix: quote `--model` as one element and turn the `CLAUDE_FLAGS` check into an allowlist. Both are local changes. For the Claim 2 escalation, the gap is A1's mechanism made silent, not a new hole. It is best resolved by fixing the wording and giving Q-064 a third option that names skipped processes, not by a separate refusal. No findings within the code paths read reach Medium or above. Endorsement claims are pending execution verification.

## Goal-Alignment Note

The goal is a pre-merge review-fix-loop critique of `skill-fixtures`. This review answers the four focus questions: the deny mechanism (F1, F4, and the untested candidates), `split_mode1` (endorsed with a named unverified hop), the Claim 2 escalation (F2, framed as a Q-064 option), and 8664e22 regressions (none found). Nothing here blocks the local merge. F1 is a small, mechanical fix worth landing in iteration 2. F2 needs the user's Q-064 answer for the behavior change, but its wording fix does not. F3 and F4 are optional. Scope limits: no `claude` probes were run, so every statement about CLI permission semantics stays Unverifiable, consistent with fact-check Claims 12 and 30b.
