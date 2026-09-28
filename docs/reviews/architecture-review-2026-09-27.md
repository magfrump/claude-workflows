Commit: 795ff71

# Architecture Review — integrate/q077-q078-q080

**Scope:** `git diff main...HEAD -- . ':!docs/reviews'` (Q-077 deny backstop, Q-078 report stamp, Q-080 skill descriptions)
**Date:** 2026-09-27
**Based on:** `docs/reviews/iter2-code-fact-check-report.md`, `docs/reviews/code-fact-check-report-r1.md`/`-r2.md`/`-r3.md` (Q-077/Q-078), `docs/reviews/pass2-code-fact-check-report-r1.md`/`-r2.md`/`-r3.md` (Q-080)

**Scope check.** In scope: cross-cutting concerns (the permission pipeline: `hooks/wiring.json` → `devcontainer-config/link-claude-home.sh` merge → `settings.json` → Claude Code's engine and the PreToolUse hook), a persisted data contract (the `.stamp` format read by `check_report_stamp`), and the skill-description routing surface. Excluded as implementation/doc-only: `guides/*`, `docs/decisions/log.md` prose, test-file bodies except where they pin a contract.

**Trust-boundary cross-reference.** The newest security review on disk, `docs/reviews/security-review-2026-09-26-q062-q063-iter6.md` (Commit: `299727c`), maps boundaries B1–B4 on the transcript/verdict pipeline only. None of them coincides with the hook ↔ Claude Code permission boundary discussed below. No labels are cited. That review predates this diff.

## Dependency Map

- **Permission policy (Q-077).** The rule `Bash(*.credentials.json*)` is written once, in `hooks/wiring.json:131`. `link-claude-home.sh` merges it into `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json` (`link-claude-home.sh:36`). Two consumers then read it independently:
  1. Claude Code's permission engine, from its own settings hierarchy.
  2. `hooks/auto-approve-allowed-commands.sh`, which now has its own deny reader (`get_deny_globs` :132, `deny_rules_to_globs` :119) and matcher (`matches_deny`). It reads three hard-coded paths, starting with `$HOME/.claude/settings.json` (:140).
  The hook depends on Claude Code's rule grammar, the external semantics of `Bash(...)`. It does not depend on Claude Code's code. The direction is: policy data (wiring.json) → config merge → two interpreters.
- **Report stamp (Q-078).** `runner-contract.bash:report_stamp` (:198) is the single definition of which inputs are stamped. `generate-reports.bash` sources the contract (:117) and writes the stamp. `check_report_stamp` (:211) recomputes and diffs. `run-tests.sh` and `health-check.sh` only consume pass/NOT-RUN counts and gained wording changes. `.gitignore` (:9–13) independently lists the sidecar suffixes the suites read. The dependency flows one way (harness → per-skill artifacts), and the stamp no longer covers the harness side.
- **Skill descriptions (Q-080).** The `description:` frontmatter is the routing input that the Claude Code skill loader reads, truncated in the live listing. The body `## When to use` sections are not routing inputs. `health-check.sh:119–141` validates only that a description is present and multi-word.

## Findings

#### 1. The hook now holds a second, partial Bash-deny engine whose correctness is coupled to Claude Code semantics it cannot see

**Severity:** Coupling
**Location:** `hooks/auto-approve-allowed-commands.sh:119-163`, `:57-62`
**Move:** 2 (responsibility boundaries), 7 (coupling surface)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
# bare `Bash` deny rule denies everything. KNOWN DIVERGENCE: whether Claude
# Code's `Bash(rm *)` also matches a bare `rm` with no arguments is not
# documented anywhere this repo records.
...
deny_rules_to_globs() {
  sed -nE 's/^Bash$/*/p; s/^Bash\((.*)\)$/\1/p' \
    | sed -E 's/:\*$/*/; s/[^A-Za-z0-9*]/\\&/g'
}
```

The policy is still written in one place, `wiring.json`. That part is sound. Enforcement, however, is now split between Claude Code's engine and a re-implementation inside the hook. Before this branch, the hook's job was one-directional: it granted convenience allows, and a bug in it could only over-prompt or over-allow within the allow list. Now it also decides whether a deny rule actually takes effect. That decision rests on an unverified premise: that a hook `allow` overrides `permissions.deny`. The header and decision row 53 both say #39344 is "shown for `ask`; not verified for `allow`".

If the premise is false, the hook's deny engine is redundant. It then only adds a second grammar that can drift from Claude Code's. If the premise is true, the hook has become the actual enforcement point for a security rule. Decision 053 said to revisit that condition ("Revisit if the hook is ever relied on as a security control"). The amendment records the change, but the module still describes itself as "a convenience layer" (:35–37). A known semantic divergence already exists (`Bash(rm *)` vs bare `rm`). Every future deny rule's effective meaning therefore depends on which interpreter sees the command.

**Recommendation:** First, settle the premise on a host. Does a hook `allow` override a matching `permissions.deny` for Bash? Queue it as a `you: terminal` question if one is not already open. Then pick one of two structures:
- If deny wins, delete the deny reader and keep the hook allow-only.
- If allow wins, reclassify the hook in its header and in decision 023/053 as a policy-enforcement component, and hold it to that standard (see Findings 2 and 3).

#### 2. The hook's settings-source list is a hard-coded copy of Claude Code's settings hierarchy, and the linker writes to a different root

**Severity:** Coupling
**Location:** `hooks/auto-approve-allowed-commands.sh:132-145` (and :183, pre-existing allow path); `devcontainer-config/link-claude-home.sh:36`
**Move:** 7 (coupling surface), 4 (layer: config resolution)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**
```
    extract_deny_from_file "$HOME/.claude/settings.json"        # hook :140
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"                        # linker :36
```

The linker merges the deny rule into `$CLAUDE_CONFIG_DIR`. The hook reads `$HOME/.claude`. The hook also does not read managed settings or a `--settings` file, both of which Claude Code honors. In cc-isolated these paths coincide: `devcontainer.json:84` sets `CLAUDE_CONFIG_DIR=/home/node/.claude`. So the credentials backstop works where it was built for. On a bare host with a non-default `CLAUDE_CONFIG_DIR`, the hook would see no deny rules and would keep approving. That is the failure the rule exists to prevent.

For the allow list this mismatch was pre-existing and fail-safe: fewer allows means more prompts. For the deny list it fails open. The repo already resolves this exact root elsewhere: `guard-trusted-writes.py:100` reads `CLAUDE_CONFIG_DIR`. The hook is the one consumer that does not.

**Recommendation:** Resolve the global settings path the way the linker and `guard-trusted-writes.py` do, `${CLAUDE_CONFIG_DIR:-$HOME/.claude}`, in one helper that both loaders use. Document managed/`--settings` sources as not read. If Finding 1 keeps the deny engine, add a test that sets `CLAUDE_CONFIG_DIR` to a temp dir. [unverified — submitted as claim: bare-host CLAUDE_CONFIG_DIR ≠ $HOME/.claude leaves the hook with zero deny globs; route: code-fact-check]

#### 3. One module, two parsers for the same `Bash(...)` rule grammar with different semantics and opposite failure directions

**Severity:** Minor
**Location:** `hooks/auto-approve-allowed-commands.sh:83-106` vs `:119-128`
**Move:** 2 (responsibility boundaries)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
  jq -r '.permissions.allow[]? // empty' "$file" 2>/dev/null \
    | grep -E '^Bash\(' \
    | sed -E 's/^Bash\(//; s/(:\*)?\)$//' \
...
  jq -r '.permissions.deny[]? // empty' "$file" 2>/dev/null | deny_rules_to_globs
```

The two parsers read the same rule strings differently:
- **Allow rules are prefixes.** `Bash(git log *)` becomes the literal prefix `git log *`, which never matches anything.
- **Deny rules are globs.** `Bash(git log *)` becomes a live glob.

A reader of `wiring.json` cannot tell which meaning applies without reading the hook. Both loaders also swallow jq errors (`2>/dev/null`). That is safe for allow, because a broken file produces no allows. It is unsafe for deny, because a broken file produces no denies and the hook proceeds to approve. The asymmetry is structural: the deny loader reused the allow loader's error policy even though the consequence is the opposite. The severity of the fail-open itself is for security-reviewer to rate.

**Recommendation:** Factor one `parse_bash_rule` that returns a typed pattern (prefix vs glob) and is used by both lists. Make the deny loader fail closed: if a settings file exists but jq fails, return a `*` glob, so every command falls through to the prompt.

#### 4. The hook's semantics are restated in four prose locations

**Severity:** Minor
**Location:** `hooks/auto-approve-allowed-commands.sh:39-62`, `hooks/wiring.json:38-44`, `guides/bare-host-hook-wiring.md:151-156`, `docs/decisions/log.md` row 53
**Move:** 7 (coupling surface: documentation as contract)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:** `wiring.json:38` begins `"Bash(*.credentials.json*) is the Bash backstop for the credentials file (Q-070/Q-077)."`. The next six lines restate the matcher's bypass list, which the hook header (:48–52), the guide and row 53 each state again.

The bypass list and the wildcard rule each appear four times. This repo's own row 56 records the outcome of that pattern: "not restated here, since each earlier restatement went stale". `wiring.json` is policy data consumed by a merger, so the least stable fact (the matcher's bypass set) is sitting in the most stable artifact.

**Recommendation:** Keep the full statement in the hook header only. Have `wiring.json`, the guide and row 53 carry one line plus a pointer to it.

#### 5. The stamp format has no version field; "old format" is inferred from an unexplained diff

**Severity:** Minor
**Location:** `test/skills/runner-contract.bash:198-224`
**Move:** 3 (module boundary: persisted contract)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
    changed="$(diff <(printf '%s\n' "$now") "$stamp" | sed -nE 's/^< ([a-z]+) .*/\1/p' | tr '\n' ' ')"
    changed="${changed% }"
    echo "Stale report for $skill/$fixture: changed since generation: ${changed:-stamp format}. Regenerate: $regen"
```
(excerpt ends :223; enclosing `check_report_stamp()` continues to :226 — read)

`.stamp` is now meant to be committed, which makes it a persisted contract. Old-format detection works only because this particular change removed a line. A stamp with a missing line has no `<` lines, so the diff names nothing and the message falls back to "stamp format". A future change that adds or renames an input would be reported as that input having "changed", not as a format change. The "stamp format" message also relies on the fallback text rather than on a declared version. The behavior is correct today and pinned by the new `eval-helpers-freshness.bats` test. It is fragile to the next format edit.

**Recommendation:** Emit a first line `format 2` from `report_stamp` and let `check_report_stamp` compare it explicitly before diffing inputs. This is cheap now, while no stamps are committed yet.

#### 6. "Shared harness" puts generation-affecting and grading-only code in one unstamped bucket

**Severity:** Minor
**Location:** `test/skills/runner-contract.bash:190-196`; `test/skills/generate-reports.bash:133`
**Move:** 2 (responsibility boundaries)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**
```
# skill's own. Shared harness files are deliberately not stamped: this file,
# generate-reports.bash, transcript.jq. ...
DENY_RECORD_FLAGS=(--disallowedTools 'Bash(**)' --permission-mode dontAsk --permission-prompts none)
```

The accepted cost, that a harness change altering output goes unnoticed, is a legitimate user decision (Q-071 [1]). The bucket it applies to is broader than the problem, though. The problem was that `runner-contract.bash` churns. That file mostly holds grading and contract checks, which rerun on every test and need no stamp. `generate-reports.bash`, on the other hand, contains the flags that shape what the model is offered, such as `DENY_RECORD_FLAGS` for arithmetic-eval. Those are generation inputs in the same sense as `runner.bash`.

**Recommendation:** No change is needed to ship. If staleness from harness edits turns out to matter, move the generation-affecting constants (the flags and the prompt scaffold) into a small `generation-inputs.bash` and stamp that one file. The churny contract stays out.

#### 7. The description-shape invariants are recorded in an audit, not enforced

**Severity:** Informational
**Location:** `scripts/health-check.sh:132-141`; `guides/skill-format-audit.md` 2026-09-27 status update
**Move:** 8 (extension points)
**Confidence:** High
**Legibility-target:** for-automated-gate

**Evidence:** health-check's only description rule is "non-empty and multi-word" (:132). The new structure (purpose first, a "not this → X" line ending by character 250, length 364–426) exists only as a prose claim in the audit.

The split itself is structurally sound. The description stays the routing surface, and the long tail moved to the body `## When to use` section, which is documentation rather than routing input. Nothing stops the next skill edit from re-growing a description past the truncation point, which is exactly the drift F4 fixed. Separately, `when:` still carries a third copy of the trigger condition. The loader ignores it (health-check :119), so routing text for a skill now lives in three places, and only one of them is read.

**Recommendation:** Add a health-check warning, not a failure, when a description exceeds ~450 chars or when a declared routing target (`→ <skill>`) appears after char 250. Retire `when:` under F1.

## What Looks Good

- The rule is written once, as data in `wiring.json`, and flows through the existing merge path, not a new wiring mechanism. The linker test pins both merge and idempotency (`test/link-claude-home-wiring.bats`). [route: code-fact-check]
- The hook checks deny before loading allows and checks both the raw string and every extracted command. The deny precedence is therefore structural, not dependent on extraction coverage. [route: code-fact-check]
- `report_stamp` stays the single definition of the stamped input set. `check_report_stamp` derives from it, and `generate-reports.bash` only consumes it. The Q-078 change touched one function plus comments. [route: code-fact-check]
- The `.gitignore` allow-list is pinned by a test that also asserts other output stays ignored, so the tracked set is an explicit contract. [route: code-fact-check]
- Q-080 kept the description/body boundary clean. Displaced text moved into the body rather than into another frontmatter field, and no de-overlap was attempted in the same change.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Hook holds a second Bash-deny engine coupled to unverified CC semantics | Coupling | `hooks/auto-approve-allowed-commands.sh:119-163` | High |
| 2 | Hook reads `$HOME/.claude`; linker writes `$CLAUDE_CONFIG_DIR` (fails open for deny) | Coupling | `hooks/auto-approve-allowed-commands.sh:140` | Medium |
| 3 | Two rule parsers, different semantics, same (swallow-errors) failure policy | Minor | `hooks/auto-approve-allowed-commands.sh:83-128` | High |
| 4 | Matcher semantics restated in four prose locations | Minor | `hooks/wiring.json:38-44` | High |
| 5 | Stamp format unversioned; old format inferred from diff fallback | Minor | `test/skills/runner-contract.bash:211-224` | High |
| 6 | "Shared harness" mixes generation inputs with grading code | Minor | `test/skills/runner-contract.bash:190-196` | Medium |
| 7 | Description-shape invariants not enforced; `when:` is a third copy | Informational | `scripts/health-check.sh:132` | High |

Rubric mapping: 1–2 → 🟡 Must Address; 3–7 → 🟢 Consider. No Structural (🔴) findings.

## Overall Assessment

The branch keeps the system's structure intact. Policy stays as data in `wiring.json`, the stamp keeps one definition, and the description/body split follows a clear rule. The issues can be fixed in place. The main structural concern is Finding 1. To backstop an unverified Claude Code behavior (hook `allow` overriding `permissions.deny`), the hook has quietly changed role from convenience allow-layer to enforcement point. It re-implements part of Claude Code's rule grammar with an acknowledged divergence, and its settings-source list does not match the linker's (Finding 2). One host test resolves which structure is right. If deny wins over a hook allow, the deny reader should go. If it does not, the hook needs to be treated as a security control: one rule parser, a fail-closed loader, and the same config-root resolution as the linker. Q-078 and Q-080 are sound. Their residual issues are about cheap future-proofing, a stamp version line and a description-length warning.

## Goal-Alignment Note

- **Success criterion (verbatim):** A markdown report saved to /workspace/docs/reviews/architecture-review-2026-09-27.md, structured per the architecture-review skill, with a Goal-Alignment Note.
- **Answered:** Where deny policy lives (data in wiring.json, merged by the linker, interpreted twice). Whether the hook duplicates the permission engine: yes, partially, with a divergence, and its necessity depends on the unverified #39344-for-allow premise. Coupling among the stamp format, generate-reports, runner-contract, health-check and run-tests: single definition, unversioned format, harness bucket too broad; health-check and run-tests are wording-only. The description/body split as a structure: sound, but unenforced.
- **Out of scope:** Bypass-spelling adequacy and the fail-open severity of Finding 3 (security-reviewer). Per-skill description quality and routing accuracy (fact-check passes cover this). Q-076. Prior overrides rows 81 and 92–101, which were not re-raised.
- **Escalate:** Finding 1's premise needs a host test (hook `allow` vs a matching `permissions.deny` for Bash). Finding 2's bare-host fail-open is submitted as a claim for code-fact-check.
- **Decisions I made:** Rated Finding 1 as Coupling rather than Structural, because decision 053's amendment records the role change, even though the module header does not. Treated the untracked `devcontainer-config/claude-home/hooks/` copy (it lacks `--deny`) as install output, not a finding.
