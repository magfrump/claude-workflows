Commit: 330138d8

# Security Review — fix/doc-drift-cycle1

**Scope:** `git diff main...HEAD` in /workspace/.claude/wt-doc-drift (AGENTS.md, GEMINI.md, guides/README.md, guides/cc-isolated-usage.md, guides/devcontainer-setup.md, docs/working/briefs/2026-10-02-doc-drift-cycle1.md). Read for context: devcontainer-config/cc-isolated.sh (rebuild_hint 534-567, H6 probe 625-647, env export 813-821, probe action / main rebuild 879-918), devcontainer-config/init-firewall.sh 330-352, devcontainer-config/devcontainer.json, devcontainer-config/Dockerfile:403, skills/dev-cycle/SKILL.md.
**Date:** 2026-10-15
**Based on:** Stage 1 merged code-fact-check summary (k=3), docs/reviews/code-fact-check-report-2026-10-15-doc-drift-cycle1.md

The diff is documentation only, but two of its hunks are operating instructions for the cc-isolated isolation boundary (how to recreate a container), and two put a new row into instruction files that agents load automatically (AGENTS.md, GEMINI.md). This review judges whether following the text could leave a user with a weaker boundary, and whether the new row creates an import or instruction-loading risk.

## Trust Boundary Map

```
B1: [user's host shell, following guide text]  → [cc-isolated launcher exports localEnv (cc-isolated.sh:813-821)] → [devcontainer build/run: egress profile, config hash, per-project ~/.claude volume]
B2 (bypassed path): [user's host shell, bare `devcontainer up --remove-existing-container`] → [no launcher, no self-probe] → [container built with empty CC_* localEnv: base-only egress, empty hash, SHARED cc--claude-config volume]
B3: [AGENTS.md / GEMINI.md text in repo] → [agent harness auto-loads it as instructions (Copilot, Cursor, Cline, Gemini CLI)] → [agent decides which skill to run on a user phrase]
```

| Label | Source | Mutability | Trust classification (per sink) |
|---|---|---|---|
| S1 | Guide text in guides/*.md (read by the human operator) | deploy-time (repo content, reviewed on merge) | Trusted as operator guidance for **command-choice** sinks only to the extent it matches the code; it is the thing under review here |
| S2 | `CC_PROJECT_ID`, `CC_CONFIG_DIR`, `CC_EGRESS_PROFILE`, `CC_CONFIG_HASH`, `CC_PROJECT_NAME` via `${localEnv:…}` | request-time (whatever the invoking shell exports) | Trusted toward **volume-name / build-path / egress** sinks only when set by the launcher (B1); on B2 they are the empty string, which devcontainer.json does not reject |
| S3 | AGENTS.md / GEMINI.md rows | deploy-time, but agent-writable inside a session (repo is bind-mounted) | Loaded as instructions by harnesses; UNTRUSTED toward **file-import** sinks (Gemini CLI `@path` import) — any `@` token would pull another file into context |
| S4 | `CLAUDE_CODE_VERSION: "latest"` (devcontainer.json:29) | code-constant | Trusted, but as a constant string it never changes the Docker layer cache key |

What crosses: the guides tell an operator which command to run at B1/B2; the safe path (B1) sets every S2 value and runs the self-probe, the bypass path (B2) sets none and skips the probe. The diff moves both guides from recommending B2 to recommending B1, which is a strict improvement. The open question is how well it warns about B2. At B3 the new row is plain text, with no `@` import tokens.

## Findings

#### 1. The "don't use the bare form" warning names the harmless-sounding consequences and leaves out the cross-project volume share (H6)

**Severity:** Medium
**Location:** `guides/devcontainer-setup.md:391-394`, `guides/cc-isolated-usage.md:935`
**Boundary:** B2
**Move:** 1 (trace the trust boundaries), 5 (invert the access-control model)
**Confidence:** Medium (the mechanism is certain from devcontainer.json and cc-isolated.sh; whether an operator gets there depends on them ignoring the advice)

Evidence (guides/devcontainer-setup.md:391-394):
> `rebuilds from the blessed config and re-probes), then \`cc-isolated <repo>\`. Not a`
> `bare \`devcontainer up --remove-existing-container …\` from your own shell: it drops`
> `the launcher's \`localEnv\` inputs and bakes base-only egress and an empty config`
> `hash (see \`rebuild_hint\` in \`cc-isolated.sh\`). Staleness >1`

Evidence (code the warning summarises, devcontainer-config/cc-isolated.sh:545-547):
> `# exactly this reason, base's 9 names instead of base+lean's 14); an empty`
> `# CC_PROJECT_ID mounts the SHARED \`cc--claude-config\` volume; an empty CC_CONFIG_DIR`
> `# points the build at /Dockerfile.`

Evidence (devcontainer-config/devcontainer.json, mounts comment):
> `// so each project gets its OWN /home/node/.claude. Decision 016 H6: sharing one`
> `// volume across projects would let a compromised session in project A read`
> `// project B's credentials, memory, and session history.`

The warning only gives reasons that sound restrictive: "base-only egress" and "an empty config hash". A security-minded reader can fairly conclude that a narrower allowlist is the safe kind of failure and that the bare form is acceptable in a pinch, for example when the launcher itself is misbehaving. The consequence that actually breaks isolation is missing. With an empty `CC_PROJECT_ID`, the bare form mounts `cc--claude-config`, a `~/.claude` volume shared by every project rebuilt this way. That is decision 016's H6, cross-project credential and memory exposure. The H6 self-probe (cc-isolated.sh:625-647) does catch it, but only when the launcher runs. An operator who rebuilt with the bare form and then runs `devcontainer exec … claude` by hand gets no probe. The cc-isolated-usage.md:935 row points to the "base-only egress row below" (941) for the reason, and that row also describes only the egress and hash symptoms. This builds on FC-C and adds the security consequence. The diff's direction is right. Its stated reason is incomplete in a way that makes the bypass look safer than it is.

**Recommendation:** In devcontainer-setup.md:392-394, add the shared-volume consequence ("and mounts a `~/.claude` volume shared across projects, H6"), and note that the bare path skips the self-probe. One clause in the :935 row (or in row 941) closes the same gap in the usage guide.

#### 2. "Recreate to pick up a newer CC" reuses the cached CC layer, so a user can believe they have patched CC when they have not

**Severity:** Low
**Location:** `guides/devcontainer-setup.md:387-391`
**Boundary:** B1
**Move:** 3 (check the error path: the step quietly fails to do what it says)
**Confidence:** Medium (inherits FC-A's medium confidence on layer-cache behaviour; no build was run)

Evidence (guides/devcontainer-setup.md:387-391):
> `- **Image lifecycle:** \`CLAUDE_CODE_VERSION=latest\` is baked at build time. A`
> `re-bless changes the baked config hash, so the next launch of each project`
> `recreates its container automatically; to pick up a newer CC *without* a config`
> `change, recreate it with the launcher: \`cc-isolated --probe-only <repo>\` (always`
> `rebuilds from the blessed config and re-probes), then \`cc-isolated <repo>\`. Not a`

Evidence (devcontainer-config/Dockerfile:403):
> `RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}`

As FC-A records, S4 is the constant `"latest"` and the `--probe-only` path (cc-isolated.sh:882) passes no `--build-no-cache`, so the CC install layer comes from cache and the image keeps the old CC. The security angle is false assurance about patch level. An operator reacting to a CC security advisory follows this documented step, sees a successful rebuild and probe, and reasonably thinks the fix is deployed. Rated Low, not Medium: no boundary property is violated, the issue was present before this diff (the old bare advice had the same flaw), and in-container auto-update / `claude update` (cc-isolated-usage.md:940) normally makes up the gap. The exposure only matters if a CC vulnerability lands in the window and auto-update is failing.

**Recommendation:** Either reword to say that a recreate does not refresh the cached CC layer and that `claude update` inside the container is how a newer CC arrives, or file a follow-up for a no-cache launcher path (outside the brief's scope, per FC-A's escalation).

#### 3. The new dev-cycle row in auto-loaded instruction files understates the skill's authority: it dispatches build loops and lands merges

**Severity:** Low
**Location:** `AGENTS.md:36`, `GEMINI.md:36`
**Boundary:** B3
**Move:** 5 (invert the access-control model: what does a trigger phrase authorize?)
**Confidence:** Medium

Evidence (AGENTS.md:36, identical at GEMINI.md:36):
> `| **Maintenance or planning pass over the repo** — "run the dev cycle", "maintenance pass", "what should we work on next", "update the roadmap" | \`dev-cycle\` | User-started outer loop over research-plan-implement and pr-prep: health and cleanup, revisit triggers, watched questions, roadmap (\`docs/roadmap.md\`), then build briefs for its top items. Output is triage in \`docs/working/questions.md\`. |`

Evidence (skills/dev-cycle/SKILL.md:4):
> `… roadmap, then as orchestrator collect build-loop results, write build briefs into free slots, record and land, and dispatch build loops. …`

AGENTS.md is loaded as standing instructions by tools that have not read the dev-cycle skill. The row maps a casual phrase ("what should we work on next") to a skill and says its output is "triage". The skill itself also dispatches autonomous build loops and self-merges whatever `scripts/build-loop.sh` allows. A user asking an ordinary planning question in Copilot, Cursor or Gemini is not told that the routed action can include unattended merges. The skill's own gates still apply (Operating Modes, the build-loop policy and `Self-merge never` settings, the `constraints ok` check), so no merge happens without configured consent, and that limits the severity. The problem is informed consent at the routing layer, which FC-B flags as "understates". This finding adds the authority consequence.

**Recommendation:** Add "dispatches build loops and lands what the build-loop gate allows" to the row's description, in both files so the sync bats test stays green. Optionally drop the most casual trigger phrase from the non-Claude files.

## Endorsement Claims

- **Claim:** Both guides' recreate advice now names the launcher path, which exports all five `CC_*` localEnv values before calling the devcontainer CLI.
  **Location:** `guides/devcontainer-setup.md:390-391`, `guides/cc-isolated-usage.md:935`; `devcontainer-config/cc-isolated.sh:813-821, 879-885`
  **Evidence:** read-static
  **Verified:** `main()` assigns and exports `CC_PROJECT_ID CC_PROJECT_NAME CC_EGRESS_PROFILE CC_CONFIG_DIR` (813-821) ahead of the `action = probe` branch, which runs `devcontainer up --remove-existing-container "${dc[@]}"` then `probe_boundary` (882-883). The advice text matches init-firewall.sh:343-350.
  **Not verified:** where `CC_CONFIG_HASH` is exported (not read in this pass; FC verified it end-to-end), and how the devcontainer CLI resolves `${localEnv:}` when a value is set but empty.
  **route: code-fact-check**

- **Claim:** The new AGENTS.md/GEMINI.md row contains no `@`-prefixed token, so Gemini CLI's `@path` import processor has nothing to expand from this row. Its two paths are in backticks with no `@`.
  **Location:** `AGENTS.md:36`, `GEMINI.md:36`
  **Evidence:** executed (`grep -n "@" GEMINI.md` and over AGENTS.md: no matches outside the existing email/package strings, none on line 36)
  **Verified:** the grep result and a visual read of line 36 in both files.
  **Not verified:** how other harnesses (Cursor, Cline) treat inline-code paths; whether any of them auto-reads files named in AGENTS.md.

- **Claim:** The diff changes no executable code, dependency manifest or lockfile. Its six files are Markdown.
  **Location:** diff.patch (all hunks)
  **Evidence:** read-static
  **Verified:** the full 9.5 KB diff.patch.
  **Not verified:** the untracked devcontainer-config/ manifest files in /workspace's own checkout (not part of this branch diff).

## Primitive sweep

Primitive sweep: no dangerous primitives in scope. The diff is Markdown only. The shell commands it quotes (`cc-isolated --probe-only <repo>`, `cc-isolated <repo>`, `devcontainer up --remove-existing-container …`) are operator instructions, not call sites, and are handled under B1/B2 above.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Bare-form warning omits shared `~/.claude` volume (H6) and probe skip | Medium | B2 | `guides/devcontainer-setup.md:391-394` | Medium |
| 2 | Recreate-for-newer-CC reuses cached CC layer: false patch assurance | Low | B1 | `guides/devcontainer-setup.md:387-391` | Medium |
| 3 | dev-cycle row understates dispatch/merge authority in auto-loaded files | Low | B3 | `AGENTS.md:36`, `GEMINI.md:36` | Medium |

## Overall Assessment

The change makes the boundary safer: both guides stop recommending the bare `devcontainer up` rebuild (B2) and point to the launcher (B1), which sets every localEnv input and re-runs the self-probe. Every issue can be fixed in place with wording and none is architectural. The most important fix is Finding 1. The warning against the bypass gives only consequences that sound restrictive (base-only egress, empty hash) and leaves out the one that breaks isolation: a `~/.claude` volume shared across projects, with no H6 probe on the by-hand path. One added clause fixes it. No findings within the code paths read reach High or Critical, and no escalation pattern matched. The launcher-path endorsement claim is still waiting on execution-backed verification.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to docs/reviews/security-review-2026-10-15-doc-drift-cycle1.md, structured per the security-reviewer skill.
- Answered: Whether the operational advice could lead to a weaker boundary (no: it moves users to the stronger path, but the warning's stated reasons under-sell the bypass's H6 risk, Finding 1, and the CC-refresh step gives false patch assurance, Finding 2). Whether the AGENTS/GEMINI row introduces an @-import or instruction-loading risk (no @-import tokens, verified by grep; one authority-understatement issue at the routing layer, Finding 3).
- Out of scope: rebuild_hint's first line in cc-isolated.sh:560 claiming plain `cc-isolated WS` "rebuilds" (code, not in this diff; FC out-of-scope note); a no-cache launcher path; the untracked devcontainer-config/ files in /workspace's checkout.
- Escalate: Finding 2 to orchestrator/author together with FC-A (fix wording here vs a follow-up for a no-cache path). No HALT-level escalation.
