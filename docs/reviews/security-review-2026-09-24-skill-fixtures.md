Commit: 04c0746

# Security Review — skill-fixtures, pass 1 (harness)

**Scope:** `git diff answers-2026-09-20...skill-fixtures` for the 40 harness files: `test/skills/generate-reports.bash`, `eval-helpers.bash`, 22 `runner.bash`, the bats suites, `scripts/health-check.sh` and `.gitignore`. I also read host config that reaches headless runs: `~/.claude/settings.json` hooks and permissions, `.claude/settings*.json` and `~/.claude/hooks/{dd-routing-reminder,log-usage}.sh`.
**Date:** 2026-09-24
**Based on:** `docs/reviews/code-fact-check-report-skill-fixtures.md` (merged, k=3). Its claim numbers are cited as FC-n.

Threat model: the adversary is the model under evaluation, a headless `claude -p` run on a fixture. Here "exploit" means reward hacking: reading `expected-verdicts.bash` or `eval-criteria.md`, learning the verdict from a fixture name, or writing outside stdout. The secondary concern is side effects that fixture runs leave on the host. The harness takes no network or multi-user input, so there is no RCE or auth surface.

## Trust Boundary Map

```
B1: [fixture file/dir, S1]           → [generate_one: subject.<ext> rename, REQUEST.md append, .fixture-* removal] → [model prompt + cwd]
B2: [runner.bash FIXTURE_TOOLS, S2]  → [case ",$FIXTURE_TOOLS," Write/Edit denylist]                               → [claude --tools allowlist = model capability]
B3: [model tool calls, S5]           → [cwd containment (assumed, not enforced)]                                     → [repo files: expected-verdicts.bash, eval-criteria.md]
B4: [host config, S4]                → [--strict-mcp-config only (no --bare)]                                        → [model context, tools, hooks]
B5: [operator env CLAUDE_FLAGS/MODEL, S3] → [unquoted word-split, no validation]                                     → [claude argv, after --tools]
B6: [model stdout / stream-json, S5] → [jq fromjson? / grep -E]                                                      → [report + transcript → eval-helpers checks]
```

Input-source classification:

```
S1: test/skills/<skill>/fixtures/*         — code-constant — trusted as data toward exec/source sinks (never sourced);
                                             its NAME is secret toward the model (verdict-bearing)
S2: test/skills/<skill>/runner.bash        — code-constant (agent-authored across HC1 batches) — trusted for exec (sourced);
                                             NOT trusted to keep the capability invariant: the harness guard exists because
                                             runner authors can err
S3: CLAUDE_FLAGS / CLAUDE_MODEL env        — deploy-time (operator shell) — trusted for exec; unconstrained toward the
                                             tool-capability sink
S4: ~/.claude settings, hooks, MCP
    connectors, CLAUDE.md, auto-memory     — runtime-mutable (user edits) — UNTRUSTED toward eval-isolation: it changes
                                             what a fixture run sees and can do, with no involvement from the harness
S5: model output and tool calls            — request-time — UNTRUSTED (all sinks); adversarial toward eval integrity
S6: expected-verdicts.bash / eval-criteria — code-constant — trusted for source; SECRET toward the model
```

Summary: the only things crossing into the fixture run are the prompt (B1), the tool list (B2) and whatever host config Claude Code loads by itself (B4). The diff's central assumption is that the tool list plus cwd placement keep S6 out of the model's reach. The tool list is validated with a denylist (B2). cwd placement is assumed to bound Read/Grep/Glob, but nothing enforces it (B3). Inline runs, including matrix-analysis with `Agent`, execute in the caller's cwd inside the real repo. Model output (B6) is handled as data only.

## Findings

#### 1. The Write/Edit guard is an exact-token denylist; write-capable tools under other names pass

**Severity:** Medium
**Location:** `test/skills/generate-reports.bash:89-94`
**Boundary:** B2
**Move:** 11 (enumerate bypasses), 5 (invert the access model)
**Confidence:** High for the guard mechanism. Medium for how the CLI reads the slipping spellings.
**Legibility-target:** for-author

**Evidence:**
```bash
case ",$FIXTURE_TOOLS," in
  *,Write,*|*,Edit,*)
    echo "Error: $RUNNER_FILE: FIXTURE_TOOLS must not include Write or Edit" >&2
```
FC-21 executed this `case` statement. It rejects `Read,Write`, `Edit` and `Read,Edit,Glob`. It accepts `Read, Write` (space after the comma), `Write(*)`, `Read,write`, `NotebookEdit`, `MultiEdit` and `Bash`. `Bash` can write any file, and `NotebookEdit` writes files. The only guard test uses the exact `"Read,Write"` spelling (`test/generate-reports.bats:257-263`).

The header promises that "the tool allowlist never includes Write" (`:48`), but the guard only enforces the canonical spelling of two names. `runner.bash` files are written by agents across batches, and that is exactly the error the guard is there to catch. A runner that grants `Bash` for "git log evidence" would pass: self-eval's comment at `runner.bash:14-16` shows that temptation already came up once. That runner would give a run that sits in the real repo (inline mode) or a temp repo (repo/tree mode) a shell, which can read S6 and write anywhere the sandbox allows. No committed runner uses a slipping form today (FC-18: values are only `none`, `Read,Grep,Glob`, `WebSearch,WebFetch` and `Agent`). The protection that does exist is headless permission denial for writes, and the harness neither names nor relies on it.

**Recommendation:** Replace the denylist with an allowlist. Split on commas, trim whitespace, and reject any token outside a fixed set: `Read,Grep,Glob,WebSearch,WebFetch,Agent` plus `none`. Also pass `--disallowedTools "Write,Edit,MultiEdit,NotebookEdit,Bash"` on every run. The CLI enforces that list whatever the runner spells, and it should also bind sub-agents (see Finding 3). Add bats cases for `Read, Write`, `Bash` and `NotebookEdit`.

#### 2. Repo/tree isolation assumes Read/Grep/Glob stay inside the cwd; nothing enforces that

**Severity:** Medium
**Location:** `test/skills/generate-reports.bash:48-50`, `:167-201`
**Boundary:** B3
**Move:** 2 (implicit sanitization assumption), 1
**Confidence:** Low. Exploitability depends on the Claude Code CLI's read policy outside the working directory, which I could not run.
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```bash
# Cheat prevention: the tool allowlist never includes Write, and in "repo" mode
# the working directory holds only the fixture, so the model cannot reach
# expected-verdicts.bash or eval-criteria.md. "inline" skills should omit Read.
```
```bash
    temp_dir=$(mktemp -d)
```
(excerpt ends :172. The enclosing `generate_one()` continues to :233 and was read: no `--add-dir`, `--settings` or `--permission-mode` is passed, and cwd is the only confinement.)

"Cannot reach" follows from "the cwd holds only the fixture" only if the tools cannot resolve paths outside the cwd (FC-19: Unverifiable). The 8 repo/tree runners grant `Read,Grep,Glob`. The repo sits at a fixed, guessable path (`/workspace`). A `Glob` with `path: "/"` and pattern `**/expected-verdicts.bash`, or a direct `Read` of `/workspace/test/skills/security-reviewer/expected-verdicts.bash`, would expose the verdicts if outside-cwd reads are allowed. The host settings add no allow rule that would permit them (`~/.claude/settings.json` only denies credential paths). But they add no deny either, so the result rests on the CLI default.

A concrete lure already exists: Finding 4's hook injects a pointer to `~/.claude/workflows/divergent-design.md`, which lies outside the temp cwd, into a tree-mode run.

**Recommendation:** Enforce the boundary with a CLI permission rule instead of placement. Pass `--settings` with `permissions.deny` entries such as `Read(/<REPO_ROOT>/test/skills/**)` and `Read(/<REPO_ROOT>/docs/working/**)`, generated from `$REPO_ROOT`. Read deny rules also govern Grep and Glob. Then run one canary probe: have the model try an absolute-path Read of a planted canary file, with and without the rule. Record the result where the header's claim lives. `route: code-fact-check` for the probe.

#### 3. Inline mode runs in the caller's cwd, the real repo: matrix-analysis sub-agents and ambient context both reach it

**Severity:** Medium
**Location:** `test/skills/generate-reports.bash:202-213`; `test/skills/matrix-analysis/runner.bash:1-6,13-14`
**Boundary:** B3, B4
**Move:** 1, 5
**Confidence:** Low. Both mechanisms depend on CLI behavior that has not been probed.
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```bash
    printf '%s\n\n%s' "$prompt" "$fixture_content" \
      | claude "${claude_args[@]}" \
```
```bash
# Sub-agents inherit the same tool list, so they cannot read the repo either;
FIXTURE_TOOLS="Agent"
FIXTURE_MODE="inline"
```
The inline branch never changes directory, so claude runs where the operator invoked it: `test/skills/` in the documented usage (FC-39). That leaves two routes to S6 and to fixture names.

(a) **Sub-agent reach.** matrix-analysis is the only inline runner that grants a tool. Whether sub-agents inherit the parent's `--tools` is unverified (FC-31). The only recorded probe granted `Agent,Read`, not `Agent` alone. The session's agent roster includes types whose definitions list their own tools, "general-purpose (Tools: *)" and plugin agents such as `code-simplifier` ("All tools"). If `*` means the full built-in set, not the parent's set, then a sub-agent in the real repo can Read `expected-verdicts.bash`. With Write or Bash it could also modify repo files, limited only by headless permission denial. It is unconfirmed that `--strict-mcp-config` strips connectors inside sub-agents (FC-23).

(b) **Ambient context.** Claude Code still loads host context from the cwd under `--system-prompt-file`: the CLAUDE.md chain, auto-memory for the cwd's project, and possibly git status with recent commit subjects. A subject naming a descriptive fixture id would then reach the model. Today only `83c9681 … matrix-analysis tc-ma3 too` names one, by id only, so this is latent (FC-15 notes the same gap).

**Recommendation:** Run inline mode in an empty `mktemp -d` cwd as well. The prompt already carries the fixture, so no behavior changes, and both (a) and (b) are removed without depending on inheritance semantics. At minimum, do this for matrix-analysis, then correct its runner comment. Fix (a) regardless of the probe outcome, because it is the only path by which a fixture run touches the real working tree.

#### 4. Host hooks run inside fixture runs: a routing hint lands in a divergent-design fixture, and fixture tool calls go into the host usage log

**Severity:** Low
**Location:** `test/skills/generate-reports.bash:117-121` (the omission is the absence of `--bare`/`--settings` isolation for hooks); `~/.claude/settings.json` `hooks.UserPromptSubmit`, `hooks.PreToolUse[matcher=Skill|Read|Agent]`
**Boundary:** B4
**Move:** 1 (runtime-mutable ⇒ reachable)
**Confidence:** High that the hooks fire (they are not suppressed and headless runs load user settings), and executed for the regex match below.
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```bash
# --strict-mcp-config on every run: without it the account's claude.ai MCP
# connectors (e.g. Claude Docs create/update/delete) are exposed even under
# --tools "", in sub-agents too — a write-capable, outward-facing tool the
# no-Write rule above assumes is absent. Not --bare: it breaks subscription
# auth (FP-097).
```
`--strict-mcp-config` isolates MCP but nothing else from S4. I ran the `dd-routing-reminder.sh` allowlist regex over the divergent-design REQUEST.md files: `tc-dd1-job-queue-no-new-infra` matches, the other four do not, and no matrix-analysis fixture matches. On a match, the hook injects "consider the divergent-design workflow (~/.claude/workflows/divergent-design.md)". That hint names the routing target, which `divergent-design/runner.bash:48-49` deliberately keeps out of the prompt ("The prompt names neither the workflow nor the routing"). It also points outside the temp cwd (Finding 2). The run appends to `$HOME/.claude/logs/usage.jsonl` through `log-usage.sh`, which logs `workflow` file_reads for divergent-design, `skill` reads for self-eval, and `agent` dispatches for matrix-analysis. Fixture runs therefore inflate the usage telemetry that skill-usage reports and the attention-budget triage rely on.

**Recommendation:** Point `USAGE_LOG_FILE` at the output dir for fixture runs (the hook honors it). Give the hooks an opt-out env var that the generator sets (e.g. `CLAUDE_FIXTURE_RUN=1`), or pass `--settings` with an empty hooks object if the CLI's settings merge allows it. Record in the tc-dd1 eval notes that host hooks can inject routing hints.

#### 5. `CLAUDE_FLAGS` and `CLAUDE_MODEL` are word-split into argv after `--tools` without validation

**Severity:** Informational
**Location:** `test/skills/generate-reports.bash:141-144`, `:196-201`, `:207-212`
**Boundary:** B5
**Move:** 5
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```bash
    model_flag="--model $CLAUDE_MODEL"
```
```bash
        $model_flag \
        ${CLAUDE_FLAGS:-} \
```
The operator can widen the run past every guard, for example with `--allowedTools Bash`, `--dangerously-skip-permissions`, `--add-dir /workspace`, `--mcp-config …` or `--tools Write`. Whether a second `--tools` overrides the first depends on the CLI. These are operator-set deploy-time values (S3), so this does not meet the reachable-attacker bar. The risk is an accidental global `CLAUDE_FLAGS` exported in a shell profile. Word-splitting also breaks any flag value that contains spaces.

**Recommendation:** Either reject `CLAUDE_FLAGS` tokens that match `--tools|--allowedTools|--add-dir|--dangerously|--permission-mode|--mcp-config`, or print the effective argv on each run so a widened run is visible in the log. Use an array for `model_flag`.

#### 6. A dotted fixture id with no extension leaks its descriptive suffix into `subject.<ext>`

**Severity:** Informational (latent; no committed fixture triggers it, per FC-41)
**Location:** `test/skills/generate-reports.bash:150-151`
**Boundary:** B1
**Move:** 11
**Confidence:** High (FC-41 executed: `tc-2.4-inaccurate -> subject.4-inaccurate`)
**Legibility-target:** for-automated-gate

**Evidence:**
```bash
  elif [[ "$fixture_name" == *.* ]]; then
    subject_name="subject.${fixture_name##*.}"
```
The header's own usage example (`:6`) uses that exact name shape. A fixture named like it would put the verdict word in the prompt.

**Recommendation:** Keep the suffix only if it matches `^[A-Za-z0-9]{1,5}$` and contains no `-`. Add a bats test that runs every committed fixture name through the rule and asserts the result contains no `-`.

#### 7. An aborted run leaves the previous report in place, pairing a stale report with no transcript

**Severity:** Informational
**Location:** `test/skills/generate-reports.bash:136-137`
**Boundary:** B6
**Move:** 3 (error path)
**Confidence:** High (FC-25 scope note)
**Legibility-target:** for-author

**Evidence:**
```bash
  # A stale transcript must never pair with a fresh report.
  rm -f "$transcript_path"
```
If `fixture_prompt`, `cp` or `git` fails under `set -e` after this line, the old `report.md` survives and the eval suite scores it as current. This is an integrity problem, not an exploit.

**Recommendation:** Also `rm -f "$report_path"` here.

## Untested bypass candidates

For the Finding 1 guard, the shell side was tested (FC-21). What the CLI does with each spelling was not, because I could not run `claude`:
- `Read, Write`: does the CLI trim the space and grant Write?
- `Read,write`: are tool names matched case-insensitively?
- `Write(*)` / `Bash(git log:*)`: does `--tools` accept rule syntax, or reject it?

For Finding 2's cwd assumption, none were tested:
- an absolute-path `Read` of `/workspace/test/skills/<skill>/expected-verdicts.bash` from a repo-mode run;
- `Glob` with `path: "/"`;
- `Grep` with `path: "/workspace"`.

For Finding 3, not tested: a matrix-analysis run whose sub-agent (`general-purpose`, and a plugin agent type) tries `Read` and `Write` of a canary in the real repo.

## Endorsement Claims

- **Claim:** Every committed `runner.bash` sets `FIXTURE_TOOLS` to one of `none`, `Read,Grep,Glob`, `WebSearch,WebFetch` or `Agent`. No token names Write, Edit, MultiEdit, NotebookEdit or Bash.
  **Location:** `test/skills/*/runner.bash`
  **Evidence:** executed
  **Verified:** my grep of all 22 runners' assignment lines, which matches FC-18's guard log.
  **Not verified:** what each value grants at runtime inside sub-agents (Finding 3), and flags added through `CLAUDE_FLAGS`.
  **route: code-fact-check**
- **Claim:** `--strict-mcp-config` is present in the built argv in inline, repo and tree modes, with and without transcript mode.
  **Location:** `test/skills/generate-reports.bash:159`
  **Evidence:** executed (FC-22, bats "every mode passes --strict-mcp-config")
  **Verified:** the argv recorded by the stub claude.
  **Not verified:** the flag's effect on claude.ai connectors in the parent session and in sub-agents (FC-23).
  **route: code-fact-check**
- **Claim:** Model output reaches the eval side only as data. `eval-helpers.bash` passes report and transcript text to `grep -E` and `jq` as input, with patterns taken from `expected-verdicts.bash`, and the reviewed lines never `source` or `eval` it.
  **Location:** `test/skills/eval-helpers.bash:17,51,167-367`
  **Evidence:** read-static
  **Verified:** each `grep`/`jq` call site in eval-helpers. The single `source` (`:17`) reads the code-constant verdicts file.
  **Not verified:** the per-skill `*-eval.bats` and `*-format.bats` suites that consume these helpers (pass 2 / sibling files).
- **Claim:** In repo and tree modes the temp repo is created with `mktemp -d`, committed under a neutral identity, and removed on function return.
  **Location:** `test/skills/generate-reports.bash:171-193`
  **Evidence:** read-static, plus FC-15's bats tests over the cwd, file list and argv
  **Verified:** the `mktemp -d`, the `trap … RETURN` and the `-c user.name=fixture` commit.
  **Not verified:** the user's global git config (`init.templateDir`, `core.hooksPath`), which applies to `git init`/`commit` in the temp dir.

## Primitive sweep

Primitive: process exec / sourcing (`source`, `claude`, argv construction)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `test/skills/generate-reports.bash:83` `source "$RUNNER_FILE"` | S2 | none (code-constant) | cleared: code constant, intended |
| `test/skills/generate-reports.bash:198-200` `claude … $model_flag ${CLAUDE_FLAGS}` | S2, S3 | Write/Edit denylist | Finding 1, Finding 5 |
| `test/skills/generate-reports.bash:209-211` same, inline | S2, S3 | Write/Edit denylist | Finding 1, Finding 3, Finding 5 |
| `test/skills/generate-reports.bash:178` `fixture_base` (runner fn) | S2 | none | cleared: code constant; copies the live rubric/workflow, not S6 (read `self-eval/runner.bash:20-33`, `divergent-design/runner.bash:54-57`) |
| `test/skills/eval-helpers.bash:17` `source "$verdicts_file"` | S6 | none | cleared: code constant |

Primitive: path construction / filesystem mutation (`rm -rf`, `cp -R`, name-derived paths)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `test/skills/generate-reports.bash:134-137` report/transcript paths from `basename` | S1 name | `basename` | cleared: fixture names are code constants; Finding 7 for the rm scope |
| `test/skills/generate-reports.bash:151` `subject.${fixture_name##*.}` | S1 name | none | Finding 6 |
| `test/skills/generate-reports.bash:174` `trap "rm -rf '$temp_dir'" RETURN` | mktemp | quoted | cleared: mktemp path, no quote chars |
| `test/skills/generate-reports.bash:180` `cp -R "$fixture_path"/. "$temp_dir"/` | S1 | none | cleared: `find test/skills -path '*/fixtures/*' -type l` returns nothing, so there are no symlinks that could point out of the temp repo. A future symlinked fixture would bypass B3 |
| `test/skills/generate-reports.bash:185` `rm -rf "$temp_dir"/.fixture-*` | mktemp + S1 | temp_dir prefix | cleared |
| `test/skills/self-eval/runner.bash:29-31` `find … -name '*.bats.in'` then `mv` | S1 | confined to `$dest/test` | cleared |
| `scripts/health-check.sh:333` `-e "$skill_dir/fixtures/$key"` | S6 key | none | cleared: read-only existence test on code constants |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Write/Edit guard is an exact-token denylist (Bash, NotebookEdit, spaced forms pass) | Medium | B2 | `test/skills/generate-reports.bash:89-94` | High (mechanism) / Medium (CLI) |
| 2 | Repo/tree isolation assumes cwd-bound Read/Grep/Glob; unenforced | Medium | B3 | `test/skills/generate-reports.bash:48-50,167-201` | Low |
| 3 | Inline mode runs in the real repo: matrix-analysis sub-agent reach plus ambient context | Medium | B3, B4 | `test/skills/generate-reports.bash:202-213`, `test/skills/matrix-analysis/runner.bash:1-14` | Low |
| 4 | Host hooks fire in fixture runs: DD routing hint in tc-dd1, fixture calls logged to usage.jsonl | Low | B4 | `test/skills/generate-reports.bash:117-121` | High |
| 5 | CLAUDE_FLAGS/CLAUDE_MODEL word-split, unvalidated, after --tools | Informational | B5 | `test/skills/generate-reports.bash:141-144,196-212` | High |
| 6 | Dotted id without extension leaks suffix into subject name | Informational | B1 | `test/skills/generate-reports.bash:150-151` | High |
| 7 | Aborted run leaves a stale report | Informational | B6 | `test/skills/generate-reports.bash:136-137` | High |

## Overall Assessment

The harness is carefully built for the channels it controls. Fixture names are kept out of the prompt, argv and temp-repo metadata. MCP connectors are stripped. Model output is handled as data. None of the findings is exploitable by anyone other than the model under evaluation, and no committed runner is misconfigured today. The weakness is architectural and fixable in place: the no-cheat invariant relies on placement and naming conventions, not on CLI-enforced rules. The Write/Edit check is a denylist of exact tokens, cwd containment is assumed, inline runs sit in the real repo, and host hooks and ambient context pass through freely. The single most important change is to enforce the boundary through the CLI on every run: `--disallowedTools` for write-capable tools, a `--settings` Read deny on `$REPO_ROOT/test/skills/**`, and an empty temp cwd for inline mode too. Then confirm it with one canary probe. The review found no Critical or High issues within the code paths read. The endorsement claims await execution verification, and Findings 2 and 3 await a CLI probe.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** a markdown critique saved to /workspace/docs/reviews/security-review-2026-09-24-skill-fixtures.md with a `Commit: 04c0746` line at the top, structured per the security-reviewer skill, ending with a Goal-Alignment Note.
- **Answered:** Every escalation the merged fact-check addressed to security-reviewer is handled. matrix-analysis inline + Agent sub-agent inheritance is Finding 3. The exact-token Write/Edit guard and unvalidated `CLAUDE_FLAGS` are Findings 1 and 5. Absolute-path reads in repo/tree mode are Finding 2. The dotted-name leak is Finding 6. The brief's other trust-boundary topics are also covered: tool allowlists (Finding 1, Endorsement 1), MCP exposure (Endorsement 2, Finding 3a), fixture-name leakage (Findings 3b and 6), and a host-config bleed the fact-check did not raise (Finding 4).
- **Out of scope:** pass-2 fixture data, eval-criteria and expected-verdicts contents; the `*-eval.bats` consumers. The fifth escalation (the empty-`--tools` bats test failing with `CLAUDE_MODEL` exported) is addressed to test-strategy/orchestrator and is not a security issue. I made no paid `claude` runs, so every CLI-behavior question is listed under Untested bypass candidates, not decided.
- **Escalate:** one canary probe settles Findings 2 and 3 together. Run it in a repo-mode and a matrix-analysis-shaped headless run, and try absolute-path Read/Glob of a planted canary plus a sub-agent Write. Route it to code-fact-check execution or to the user's terminal; it costs a few paid calls.
- **Decisions I made:** I treated the model under evaluation as the adversary and reward hacking as the exploit class. I rated Findings 1-3 Medium under the floor rule (each is a named mechanism in the environment where fixtures actually run) and put the environmental uncertainty in Confidence. I rated Finding 4 Low because it concerns eval and telemetry integrity, not a secrecy or write property.
