Commit: 04c0746

# Architecture Review — `skill-fixtures` pass 1 (harness code)

**Scope:** `git diff answers-2026-09-20...skill-fixtures` restricted to the 40 harness files listed in the pass-1 brief. The focus is `test/skills/generate-reports.bash`, the 22 `test/skills/*/runner.bash`, `test/skills/eval-helpers.bash`, `test/skills/helpers.bash` (unchanged; read for context), `test/generate-reports.bats`, and `scripts/health-check.sh`.
**Date:** 2026-09-24
**Based on:** `docs/reviews/code-fact-check-report-skill-fixtures.md` (merged k=3). Claim numbers cited as "FC-N".

**Trust-boundary cross-reference:** I scanned for `docs/reviews/security-review-*.md`. The newest files (`security-review-2026-09-23-copy-install*.md`, `security-review-2026-09-23-guard.md` at Commit `3e9e448`) cover other diffs (`hooks/guard-trusted-writes.py` and the copy-install work). None has a Trust Boundary Map for this harness, so no boundary labels are referenced. Finding 1 touches the harness's own cheat-prevention boundary, so it carries a `route: security-reviewer` note instead of a label.

## Dependency Map

- **`generate-reports.bash` is the composition root.** It resolves the skill, then `source`s `test/skills/<skill>/runner.bash` into its own global scope. It then validates `FIXTURE_TOOLS`, `FIXTURE_MODE` and `FIXTURE_TRANSCRIPT` and calls back into `fixture_prompt` and, when defined, `fixture_base`. Dependency direction is plugin → host. Runners read host globals (`REPO_ROOT`, and in self-eval also `SCRIPT_DIR`), and the host calls runner functions by name. The host holds no skill-specific knowledge apart from the report-shape greps at `:227-228`.
- **Runners → live repo files.** Three runners reach into production content:
  - divergent-design: `workflows/divergent-design.md`, through `fixture_base`.
  - self-eval: `docs/evaluation-rubric.md`, through `fixture_base`.
  - ai-personas-critique: `skills/ai-personas-critique/personas.md`, inlined into the prompt through a `BASH_SOURCE`-relative path.

  These point from tests to production, which is the correct direction.
- **Generator → eval-helpers: a filesystem contract, not an import.** The generator writes `output/<fixture>.report.md` and, in transcript mode, `output/<fixture>.transcript.jsonl`. `eval-helpers.bash` finds both by name convention. It parses the report's markdown fields and the stream-json event schema.
- **eval-helpers → helpers.bash: indirect, through a subprocess.** `format_check` shells out to `bats <skill>-format.bats`, and those suites `load helpers`.
- **External schema dependencies.** Both the generator (`:220`, `select(.type == "result") | .result`) and eval-helpers (`:337-339`, `:364-366`) depend on the `claude -p --output-format stream-json` event schema.

## Findings

#### 1. The cheat-prevention invariant is declared by the harness but enforced by each plugin

**Severity:** Coupling
**Location:** `test/skills/generate-reports.bash:48-50`, `:89-94`, `:202-212`; repeated in 12 inline `runner.bash` files, e.g. `test/skills/cowen-critique/runner.bash:2-3`, `test/skills/matrix-analysis/runner.bash:13`
**Move:** #2 responsibility boundaries, #4 layer placement, #7 coupling
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
# Cheat prevention: the tool allowlist never includes Write, and in "repo" mode
# the working directory holds only the fixture, so the model cannot reach
# expected-verdicts.bash or eval-criteria.md. "inline" skills should omit Read.
```
```
case ",$FIXTURE_TOOLS," in
  *,Write,*|*,Edit,*)
```
```
    printf '%s\n\n%s' "$prompt" "$fixture_content" \
      | claude "${claude_args[@]}" \
        $model_flag \
        ${CLAUDE_FLAGS:-} \
```
(excerpt ends at `:211`; the enclosing `generate_one()` continues to `:233`, read in full)
```
# Cowen critique: the draft goes inline in the prompt. No Read (inline mode runs
# in the real repo, where Read could reach expected-verdicts.bash) and no Write,
```
```
FIXTURE_TOOLS="Agent"
```

The harness is the only place that can guarantee "the model cannot see the answers". Today it guarantees only part of that.

- **Repo and tree modes** get a temp working directory.
- **Inline mode** runs claude in the caller's directory, the real repo (FC-39). The only thing keeping the verdicts out of reach there is that each inline runner withholds Read. That is a convention, and each runner re-explains it in its own comment: 12 copies of the same rationale.
- **The host-side check is a denylist.** It matches exactly `Write` and `Edit`. Spaced forms, `Write(*)`, `MultiEdit`, `NotebookEdit` and `Bash` all pass (FC-21, Incorrect).
- **A second, unvalidated channel feeds claude's argv.** `$CLAUDE_FLAGS` is word-split after `--tools`.
- **One inline runner already sits outside the convention's reasoning.** matrix-analysis grants `Agent` in the real repo. The runner's claim that sub-agents inherit the Read-less tool list is unverified (FC-31).

Structurally, a policy the host owns has been pushed down into 22 plugins. Every new runner is a new place to get it wrong, and the host's check cannot see most of the ways to get it wrong.

**Recommendation:** Move the invariant into the host.

1. Run inline mode in an empty `mktemp -d` working directory, as repo mode does. This makes "should omit Read" unnecessary, and the 12 runner comments can drop their rationale.
2. Replace the Write/Edit denylist with a host-owned allowlist of permitted tool tokens (today: `Read`, `Grep`, `Glob`, `WebSearch`, `WebFetch`, `Agent`). Split on `,` after stripping spaces.
3. Either refuse `--tools`, `--allowedTools` and `--disallowedTools` inside `CLAUDE_FLAGS`, or document it as an operator-only escape hatch.

The security consequences belong to security-reviewer (route: security-reviewer). This finding is only about where the rule lives.

#### 2. The runner contract is implicit and wider than documented, and its only fast test checks that the file exists

**Severity:** Coupling
**Location:** `test/skills/generate-reports.bash:13-29`, `:79-94`; `test/skills/self-eval/runner.bash:23`; `test/generate-reports.bats:272-281`
**Move:** #3 module boundary, #7 coupling (content coupling)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
# shellcheck source=/dev/null  # Path is per-skill
source "$RUNNER_FILE"
```
```
  cp -R "$SCRIPT_DIR/self-eval/base/skills/." "$dest/skills/"
```
```
  for dir in "$REPO_ROOT"/test/skills/*/fixtures/; do
    local skill_dir="${dir%/fixtures/}"
    [ -f "$skill_dir/runner.bash" ] || missing+=("$(basename "$skill_dir")")
  done
```

This branch turns `runner.bash` into a plugin API with 22 implementors, but the API boundary is `source` into the host's global namespace.

- **The header documents part of the surface:** four variables and two functions, plus `REPO_ROOT` "for runners' fixture_base".
- **self-eval already reaches past it.** It uses `SCRIPT_DIR`, which is a host-private variable, so renaming or relocating it in the generator would break self-eval silently.
- **A runner can clobber any host global.** `FIXTURE_DIR`, `OUTPUT_DIR` and `REPO_ROOT` are all set before the `source`, so a runner can overwrite them unnoticed.
- **The contract is checked in one place only: `generate-reports.bash:85-115`, at paid-run time.** The fast test named "has a runner the generator accepts" only asserts that the file exists (FC-2, Incorrect). A runner with a bad mode or a Write grant passes CI and fails, or silently misbehaves, only when someone spends model budget.

**Recommendation:**
1. Extract the checks at `:85-115` into a `validate_runner` function in a small sourced lib, or behind a `--check` flag on the generator.
2. Have `generate-reports.bats` source every committed runner in a subshell and call it, so the host and the CI test share one definition of "accepted".
3. Publish a `RUNNER_DIR`, or document `SCRIPT_DIR`, as part of the contract instead of leaving it an accident.

#### 3. Fixtures depend on live repo files through three ad-hoc paths, and the dependency is invisible until a paid run

**Severity:** Minor
**Location:** `test/skills/divergent-design/runner.bash:17-20`; `test/skills/self-eval/runner.bash:24`; `test/skills/ai-personas-critique/runner.bash:13`
**Move:** #7 coupling, #1 dependency direction
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**
```
  cp "$REPO_ROOT/workflows/divergent-design.md" "$1/workflows/"
```
```
  [ -e "$fx/.fixture-no-rubric" ] || cp "$REPO_ROOT/docs/evaluation-rubric.md" "$dest/docs/"
```
```
PERSONAS_CATALOG="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../skills/ai-personas-critique" && pwd)/personas.md"
```

Using live files is a deliberate and defensible choice: the evals test the current workflow and rubric, not a vendored copy that drifts. The dependency direction (tests → production docs) is correct. Three structural costs come with it:

1. **The coupling cannot be seen from the depended-on side.** Someone editing `workflows/divergent-design.md` or `docs/evaluation-rubric.md` has no signal that eval expectations hinge on the text. If a path moves, `set -e` stops the generator, but only during a paid run. No fast check catches it.
2. **Generated reports are not stamped with the live-input version.** The reports are gitignored and paired with nothing but the fixture name. A report produced before a workflow edit is indistinguishable from one produced after it. This is the same staleness class the transcript sidecar guards against for transcripts (`:136`).
3. **The mechanism is inconsistent.** Two runners use `fixture_base` + `REPO_ROOT`; the third uses a `BASH_SOURCE`-relative path in inline mode, even though `REPO_ROOT` is documented for exactly this purpose.

**Recommendation:**
1. Declare live inputs as data, e.g. `FIXTURE_LIVE_FILES=(workflows/divergent-design.md)`, which the host copies or reads.
2. Have a fast bats test assert that each declared file exists.
3. Have the host write their content hashes into a small `<fixture>.inputs` sidecar next to the report, removed up front like the transcript.
4. Use `REPO_ROOT` in ai-personas-critique.

#### 4. Report and transcript shape knowledge is spread across three modules with no shared definition

**Severity:** Minor
**Location:** `test/skills/generate-reports.bash:135`, `:220`, `:227-228`; `test/skills/eval-helpers.bash:24-29`, `:324`, `:364-366`; `test/skills/helpers.bash:19`
**Move:** #7 coupling (stamp coupling through shared formats)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
  local transcript_path="$OUTPUT_DIR/${fixture_name}.transcript.jsonl"
```
```
  local t="${REPORT_PATH%.report.md}.transcript.jsonl"
```
```
    claim_count=$(grep -cE '^## (Claim [0-9]+|Verdict for C[0-9]+)' "$report_path" || true)
```
```
  CLAIM_HEADING_RE="${2:-^## Claim [0-9]+}"
```
```
       | .message.content[]? | select(.type == "tool_use" and .name == "Agent")
```

The shared knowledge is duplicated in several places:

- **Sidecar filename convention:** written independently in the generator and eval-helpers.
- **Claim-heading shape:** encoded three times, in the generator's progress grep, `claim_heading_re`, and `helpers.bash`'s default.
- **Stream-json event schema:** parsed in both the generator and eval-helpers, with the sub-agent tool name hard-coded as `"Agent"`.

Each copy is small. The risk is correlated drift. A renamed sidecar or a changed CLI tool name (the sub-agent tool has been renamed before) must be updated in two places, and missing one fails as "no transcript" or "0 sub-agents", not as a schema error. The generator's claim/severity grep is also the one piece of skill-specific report knowledge in the otherwise skill-agnostic host.

**Recommendation:** Keep the sidecar suffix and the stream-json selectors in one sourced snippet that both the generator and eval-helpers load. Leave the host's progress line generic (e.g. byte or line count), or move it to the runner. This is low priority, and fine to defer with a revisit trigger (a third transcript consumer, or a CLI tool rename).

#### 5. Fixture directories carry control flags for runner code through reserved names

**Severity:** Informational
**Location:** `test/skills/generate-reports.bash:181-185`; `test/skills/self-eval/runner.bash:24-26`
**Move:** #7 coupling (control coupling)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**
```
      if [ -f "$temp_dir/REQUEST.md" ]; then
        prompt="$prompt"$'\n\n'"$(cat "$temp_dir/REQUEST.md")"
        rm "$temp_dir/REQUEST.md"
      fi
      rm -rf "$temp_dir"/.fixture-*
```
```
  [ -e "$fx/.fixture-no-rubric" ] || cp "$REPO_ROOT/docs/evaluation-rubric.md" "$dest/docs/"
```

Tree mode reserves two names inside what is otherwise model-visible data:

- **`REQUEST.md`** is a prompt channel.
- **`.fixture-*`** is a control channel read by the runner and stripped by the host.

That is control coupling, but it is contained. The host owns the reserved prefix and removes it generically, so the runner and the host agree through one naming rule, and the bats suite covers it (`test/generate-reports.bats:213`). One gap: a fixture's own content that happens to be named `REQUEST.md` or `.fixture-*` would be silently consumed. And the header calls the markers "files", while self-eval uses a directory (FC-17).

**Recommendation:** None required. Optionally state in the header that these are reserved top-level names (files or directories).

#### 6. `eval_fixture` grows by editing a central dispatch, and its documented scope lags its actual generality

**Severity:** Informational
**Location:** `test/skills/eval-helpers.bash:82-142`, `:7`, `:135`
**Move:** #8 extension points
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
# Args: $1 = skill name (fact-check or code-fact-check)
```
```
        # Delegate to the format BATS suite (fact-check-format.bats or code-fact-check-format.bats)
```

The branch adds 8 check types by adding `case` arms, bringing the total to 17. At this size, a single dispatch in a bash helper is the pragmatic choice; a registry would be over-engineering. The aggregation into `failed` is a structural improvement (FC-10). The stale parentheticals (FC-40) are a small sign that the module was generalized without its documented contract being updated.

**Recommendation:** Update the two comments. Revisit the dispatch only if runners start needing skill-private check types.

## What Looks Good

- **The runner plugin boundary puts policy and mechanism in the right places.** Per-skill decisions (tools, mode, prompt, base files) live next to each skill's fixtures. The generator stays generic, and the dependency runs one way: plugin → host variables, host → plugin callbacks by name. The two pre-existing skills moved into runners unchanged (FC-45).
- **Tree mode's base-then-overlay composition** (`fixture_base`, then `cp -R fixture/.`) is a clean extension point. Per-fixture variation stays in data, not in new host branches.
- **The transcript is a sidecar, not a replacement.** The report stays plain text, so every pre-existing check and format suite works unchanged. Process checks read the new artifact only when asked. The upfront `rm -f` pairs the two artifacts' lifetimes (FC-25).
- **`--strict-mcp-config` is set once in the host argv** for every mode, instead of per runner. This is the right layer, and the model for where finding 1's rules should live.
- **`scripts/health-check.sh` generalizes with `-e` / `-d`** instead of adding a special case for tree skills.
- **`test/generate-reports.bats` tests the host against a stubbed `claude`** in a copied layout, so the contract is exercised without paid calls or writes to real `output/`.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Cheat-prevention invariant declared by the host, enforced by plugins (inline cwd, Write/Edit denylist, unvalidated `CLAUDE_FLAGS`) | Coupling | `test/skills/generate-reports.bash:48-50,89-94,202-212` | High |
| 2 | Runner contract implicit and wider than documented (`SCRIPT_DIR` use, global clobbering); fast test checks existence only | Coupling | `test/skills/generate-reports.bash:83`, `test/skills/self-eval/runner.bash:23`, `test/generate-reports.bats:272-281` | High |
| 3 | Live-file coupling through three ad-hoc paths; invisible to editors, unstamped in reports | Minor | `test/skills/divergent-design/runner.bash:19`, `test/skills/self-eval/runner.bash:24`, `test/skills/ai-personas-critique/runner.bash:13` | Medium |
| 4 | Report/transcript shape duplicated across generator, eval-helpers and helpers | Minor | `test/skills/generate-reports.bash:135,220,227`; `test/skills/eval-helpers.bash:324,364`; `test/skills/helpers.bash:19` | High |
| 5 | Reserved `REQUEST.md` / `.fixture-*` names as control channel | Informational | `test/skills/generate-reports.bash:181-185` | Medium |
| 6 | Central check dispatch; stale scope comments | Informational | `test/skills/eval-helpers.bash:7,135` | High |

## Overall Assessment

The branch improves the harness's structure. It replaces two hard-wired skills with a plugin boundary whose dependency direction is right, and it adds tree mode and transcripts as extensions rather than special cases. All the issues can be fixed in place; none requires restructuring.

The most important concern is finding 1. The harness's single non-negotiable property, that the model cannot see or write the answers, is only partly owned by the harness. Inline mode and the tool policy rely on 22 runners each doing the right thing, backed by a denylist check and a CI test that does not source the runners (finding 2).

Moving the working-directory isolation and a tool allowlist into the host, and sharing the validation with the fast test, would close both findings with roughly a dozen lines. It would also let the 12 duplicated runner rationales shrink to one line each.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** a markdown critique saved to /workspace/docs/reviews/architecture-review-2026-09-24-skill-fixtures.md with a `Commit: 04c0746` line at the top, structured per the architecture-review skill, ending with a Goal-Alignment Note.
- **Answered:** Yes. This covers the module boundaries between generate-reports.bash, runner.bash, eval-helpers.bash and helpers.bash (findings 2, 4, 6), dependency direction (Dependency Map, finding 3), and fixture coupling to live repo files through `fixture_base` (finding 3, which also covers the ai-personas inline variant).
- **Out of scope:** Pass-2 fixture data, eval-criteria and expected-verdicts. The exploitability of the finding-1 gaps (security-reviewer). The comment-accuracy findings the fact-check already owns (FC-2, 16, 21, 27, 40), which are used here as evidence only. I did not run `claude` or the generator.
- **Escalate:** Finding 1's gaps go to security-reviewer: inline cwd, the matrix-analysis `Agent` grant in the real repo (FC-31), the denylist bypass forms (FC-21), and `CLAUDE_FLAGS`. Claims that isolation holds are `route: code-fact-check` and are not self-certified here.
- **Decisions I made:** I rated finding 1 Coupling rather than Structural, because the placement is fixable in place and no committed runner currently exploits it. I rated the live-file coupling Minor, because its direction is correct and the choice is deliberate. The costs are visibility and staleness, not wrong structure.
