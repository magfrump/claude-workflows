Commit: 330138d8

# API Consistency Review — fix/doc-drift-cycle1

**Scope:** `git diff main...HEAD` in /workspace/.claude/wt-doc-drift (AGENTS.md, GEMINI.md, guides/README.md, guides/cc-isolated-usage.md, guides/devcontainer-setup.md, docs/working/briefs/2026-10-02-doc-drift-cycle1.md)
**Date:** 2026-10-15
**Based on:** Stage 1 merged code-fact-check summary (k=3, HEAD 330138d8): FC-A, FC-B, FC-C. Those verdicts are taken as given here. They come back only where they have a consistency consequence.

The consumer-facing surfaces in this doc-only diff are: the documented CLI recipes (`cc-isolated --probe-only <repo>`, `cc-isolated <repo>`) and their placeholder spelling; the recovery advice the launcher and the firewall script print, which the guides must agree with; how the two guides cross-reference each other and the code; and the row format of the AGENTS.md/GEMINI.md Skills table, compared with global-instructions/CLAUDE.md row 12.

## Baseline Conventions

- **Repo placeholder in prose recipes:** `<repo>` (angle brackets, lowercase). It appears in guides/devcontainer-setup.md:309 and :399, guides/cc-isolated-usage.md:941, devcontainer-config/cc-isolated.sh:316 and :487, and devcontainer-config/init-firewall.sh:349-350. The command-reference block in guides/cc-isolated-usage.md:25-35 uses `[REPO]` to mark an *optional* positional. Worked examples use concrete paths (`~/code/api`). The launcher's own `rebuild_hint` (cc-isolated.sh:560) prints the real, `%q`-quoted workspace path.
- **Recovery recipe for a container the firewall bricked:** init-firewall.sh:343-350 (since fc3bff82) prints `cc-isolated --probe-only <repo>` followed by `cc-isolated <repo>`. The launcher's other recovery prints go through `rebuild_hint` (cc-isolated.sh:557-567), which names the single step `cc-isolated WS` and claims it "rebuilds, re-probes, re-launches".
- **Guide cross-references:** devcontainer-setup.md sends readers to cc-isolated-usage.md for operations and troubleshooting ("Full workflow and troubleshooting: `guides/cc-isolated-usage.md`", :163, :183). guides/README.md:49 describes the split: "that guide covers the security model, this one covers running it." Inside a troubleshooting table, rows refer to each other by description ("see … above"), e.g. cc-isolated-usage.md:932 "see "SNI filtering" above".
- **Skills table rows (AGENTS.md:26-36, GEMINI.md identical):** three columns. The Trigger is sometimes a bold lead phrase plus an em-dash qualifier (`design-space-situating`, :34), and otherwise plain prose. The Skill cell holds backticked names only. The When cell is one or two sentences, mostly about timing or role ("After implementation, before PR.", "Use when the corresponding planning question comes up."). No existing row puts quoted trigger phrases in the Trigger cell. global-instructions/CLAUDE.md:32 (row 12) writes its triggers as `, or keywords: "…"`.

## Name-Pattern Audit

The diff adds no new CLI flags, commands or functions. The new public "names" are the documented invocations and placeholders, a new Skills-table row key, and one cross-reference target.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `cc-isolated --probe-only <repo>` (in the recovery recipe) | documented invocation | `cc-isolated --probe-only <repo>` (verify step), `cc-isolated --probe-only <repo>` (blast-radius note), `Next: cc-isolated --probe-only <repo>` | guides/devcontainer-setup.md:309, :399; devcontainer-config/cc-isolated.sh:316 | Consistent: same flag, same placeholder |
| `cc-isolated <repo>` | documented invocation | `Relaunch with cc-isolated <repo>`, `cc-isolated <repo>   # then start the session` | guides/cc-isolated-usage.md:941; devcontainer-config/init-firewall.sh:350 | Consistent |
| `<repo>` placeholder | placeholder | `[REPO]` (optional marker in the command reference), `WS` (comment in rebuild_hint), `NAME`/`DIR` (cc-push flag values) | guides/cc-isolated-usage.md:25-35; devcontainer-config/cc-isolated.sh:536-567 | Consistent: `<repo>` is the prose convention, and `[REPO]` is reserved for the synopsis. No finding |
| `dev-cycle` (Skills-table row) | table row / skill name | `tech-debt-triage`, `design-space-situating`, `code-review` | AGENTS.md:28-35; skills/dev-cycle/SKILL.md:2 | Name consistent (matches the skill dir and CLAUDE.md:32). The row's *format* departs from the table: see F3 |
| "the base-only egress row below" | cross-reference | "see "SNI filtering" above" | guides/cc-isolated-usage.md:932 | Consistent with the in-table reference style |
| "`rebuild_hint` in `cc-isolated.sh`" | cross-reference (guide to code symbol) | "Full workflow and troubleshooting: `guides/cc-isolated-usage.md`" | guides/devcontainer-setup.md:163, :183 | Inconsistent target: see F2 |

## Findings

#### F1. The guide's recovery recipe for a bricked firewall contradicts the launcher's own printed recovery advice for the same state

**Severity:** Inconsistent
**Location:** `guides/cc-isolated-usage.md:935` (also `guides/devcontainer-setup.md:389-391`), versus `devcontainer-config/cc-isolated.sh:912-915` and `:557-560` (not in the diff)
**Move:** 3 (consumer contract: documentation versus CLI output)
**Confidence:** High
**Legibility-target:** operator reading the terminal and the guide side by side; author deciding on a follow-up

Evidence (guide, after this diff):
> `If it cannot bootstrap any more, recreate it from the host with the launcher: \`cc-isolated --probe-only <repo>\` (rebuilds from the blessed config and re-probes), then \`cc-isolated <repo>\`.`

Evidence (launcher, same failure class, cc-isolated.sh:912-915 and :560):
> `echo "ERROR: init-firewall.sh failed. It fails closed, so this container may now" >&2`
> `echo "  Recreate it (the ~/.claude volume and your repo are not affected):" >&2`
> `rebuild_hint "$ws" "${dc[@]}"`
> `echo "    cc-isolated $(printf '%q' "$ws")        # the supported path: rebuilds, re-probes, re-launches" >&2`

The diff correctly brings both guides into line with init-firewall.sh:347-350. That leaves the launcher's own message for a container the firewall closed (cc-isolated.sh:912) giving a different recipe: a plain `cc-isolated <ws>`. A plain launch recreates the container only when `container_config_matches` fails (cc-isolated.sh:887-896). A container the firewall bricked carries the current hash, so the plain launch reuses it and fails again. A user who meets the :912 error has two surfaces telling them different things, and the one on their terminal is the one that does not work. The troubleshooting table has no row keyed to the `ERROR: init-firewall.sh failed` text. A user searching for it lands on the :935 row, which now disagrees with the message they are reading. This matches Stage 1's out-of-scope note. The consistency consequence is new: the diff turns a latent script inaccuracy into a visible doc-versus-CLI disagreement. The guides are the correct side.

**Recommendation:** Do not change the guide. Queue a follow-up in cc-isolated.sh: either give `rebuild_hint` a probe-only variant for the :915 call site, or print the init-firewall.sh two-step there. Optionally extend the :935 row's Symptom cell to also match `ERROR: init-firewall.sh failed`.

#### F2. The two guides cite different targets for the same rationale, and the code-symbol target prints the other recipe

**Severity:** Minor
**Location:** `guides/devcontainer-setup.md:392-394`; `guides/cc-isolated-usage.md:935`
**Move:** 3 (documentation cross-reference drift) / 7 (asymmetry)
**Confidence:** Medium
**Legibility-target:** guide reader following a cross-reference

Evidence:
> devcontainer-setup.md:392-394: `bare \`devcontainer up --remove-existing-container …\` from your own shell: it drops / the launcher's \`localEnv\` inputs and bakes base-only egress and an empty config / hash (see \`rebuild_hint\` in \`cc-isolated.sh\`).`
> cc-isolated-usage.md:935: `Not a bare \`devcontainer up --remove-existing-container …\` from your own shell — see the base-only egress row below.`
> devcontainer-setup.md:163: `allowlist. Full workflow and troubleshooting: \`guides/cc-isolated-usage.md\`.`

The same "why not the bare form" rationale points to a code symbol in one guide and to a guide row in the other. The guide's own convention (:163, :183) is to send operational and troubleshooting detail to cc-isolated-usage.md. A reader who follows the `rebuild_hint` citation finds a function whose first printed line recommends the single-step `cc-isolated WS` (see F1). That contradicts the two-step recipe in the sentence that cites it. The row at cc-isolated-usage.md:941 is the guide-level explanation of the same rationale. It also covers the egress and hash consequences that this sentence names. (Per FC-C, neither surface names the empty `CC_PROJECT_ID` / `CC_CONFIG_DIR` consequences. That gap is only informational and is not re-filed.)

**Recommendation:** In devcontainer-setup.md, point to the guide instead, e.g. "see the base-only egress row in `guides/cc-isolated-usage.md`'s Troubleshooting". Keep the `rebuild_hint` mention only as a secondary "the launcher's comment block explains why". This also matches init-firewall.sh:340's comment.

#### F3. The new Skills-table row is a third, divergent copy of the dev-cycle step list, in a Trigger format no other row in the table uses

**Severity:** Minor
**Location:** `AGENTS.md:36`, `GEMINI.md:36`
**Move:** 2 (format against the grain) / 3 (documentation drift across copies)
**Confidence:** High

Precedent: the bold lead phrase plus em-dash qualifier in the Trigger cell is used in AGENTS.md:34 (`design-space-situating`). Keyword triggers written as `, or keywords: "…"` are used in global-instructions/CLAUDE.md:32 (row 12, the same skill).
**Legibility-target:** agents (Copilot/Cursor/Gemini) that route from AGENTS.md/GEMINI.md; maintainer keeping the three copies in sync

Evidence:
> AGENTS.md:36: `| **Maintenance or planning pass over the repo** — "run the dev cycle", "maintenance pass", "what should we work on next", "update the roadmap" | \`dev-cycle\` | User-started outer loop over research-plan-implement and pr-prep: health and cleanup, revisit triggers, watched questions, roadmap (\`docs/roadmap.md\`), then build briefs for its top items. Output is triage in \`docs/working/questions.md\`. |`
> global-instructions/CLAUDE.md:32: `| 12 | **Maintenance or planning pass over the repo**, or keywords: "run the dev cycle", … | \`dev-cycle\` skill | e.g., "Run the dev cycle" · The outer loop over rows 6/9: health and cleanup, every revisit trigger, watched questions, claim spot-check, conditional deep-audit check and brainstorm, roadmap (\`docs/roadmap.md\`), then writes build briefs for its top items. User-started, no timer. Output is triage in \`docs/working/questions.md\`. |`

The row's lead phrase and trigger keywords match row 12. Translating "rows 6/9" into workflow names is a good tool-agnostic adaptation. But the step list is a hand-trimmed subset. It drops "claim spot-check, conditional deep-audit check and brainstorm" (FC-B), and "every revisit trigger" becomes "revisit triggers". That gives three step lists (CLAUDE.md:32, skills/dev-cycle/SKILL.md:4, and AGENTS/GEMINI) that already differ. The agents-gemini-sync bats test keeps only AGENTS and GEMINI in step, so the next change to the skill's steps has two unguarded copies to drift. Format: the em-dash form follows the :34 precedent. The quoted phrases follow row 12 rather than any sibling in this table, so the row is a hybrid. Its When cell (about 40 words of content plus output) is also the only one in the table that describes *what the skill does* rather than when to apply it.

**Recommendation:** Either copy row 12's step list verbatim (keeping the "research-plan-implement and pr-prep" translation), or shrink the When cell to timing plus a pointer, e.g. "User-started, no timer. Steps and outputs: `skills/dev-cycle/SKILL.md`." The pointer form removes the drift surface. Either keyword format is defensible; pick the one row 12 uses, so that a grep for `or keywords:` finds both.

#### F4. Consistency consequence of FC-A: the two guides now name different mechanisms for getting a newer Claude Code

**Severity:** Informational
**Location:** `guides/devcontainer-setup.md:387-397`; `guides/cc-isolated-usage.md:940`
**Move:** 7 (asymmetry across documents)
**Confidence:** Medium (rests on FC-A's medium-confidence Incorrect verdict)
**Legibility-target:** author deciding whether FC-A is fixed here or in a follow-up

Evidence:
> devcontainer-setup.md:389-391: `to pick up a newer CC *without* a config / change, recreate it with the launcher: \`cc-isolated --probe-only <repo>\` (always / rebuilds from the blessed config and re-probes), then \`cc-isolated <repo>\`.`
> devcontainer-setup.md:395-397: `The egress profile and the / config hash are the *last* layer in the Dockerfile, so projects on different / profiles still share every heavy layer.`
> cc-isolated-usage.md:940 (truncated …): `| Claude Code auto-update fails every launch in ONE project (\`.last-update-result.json\` shows \`install_failed\`; …`

FC-A is not re-filed. The consistency point is that the bullet contradicts itself. Its last sentence (the heavy layers are shared, i.e. cached) explains why its first recipe does not reinstall CC, and the usage guide treats in-container auto-update as the update path. The diff made the recipe *more* authoritative ("always rebuilds") without changing what it delivers.

**Recommendation:** Follow the FC-A escalation outcome. If the fix is deferred, a minimal consistent wording is: "CC updates in-container via auto-update / `claude update`; recreating with the launcher does not bust the CC layer cache."

## What Looks Good

- Placeholder spelling `<repo>` matches every prose recipe in both guides, the launcher's `Next:` and `verified live: NO` messages, and init-firewall.sh's hint. The `[REPO]` synopsis convention is left alone, correctly.
- Both guide edits now match init-firewall.sh:343-350 word for word in substance ("rebuilds from the blessed config, re-probes", "from the HOST"). The documentation and the firewall script's output agree, which was the brief's goal.
- The cc-isolated-usage.md:935 cross-reference to the :941 row uses the table's existing "see … above/below" style, and the referenced row exists.
- guides/README.md:49's index line uses the same nouns as the target guide's headings ("exit scan", `cc-push`: cc-isolated-usage.md:185, :302) and keeps the README's "Use once …; that guide covers …" sentence shape.
- AGENTS.md and GEMINI.md stay byte-identical in the Skills table (sync bats passes per Stage 1). The `dev-cycle` name matches the skill directory and CLAUDE.md row 12.
- No CLI flag, exit code or command changed. No consumer can break.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Guide's bricked-firewall recipe contradicts the launcher's own printed recovery advice (rebuild_hint at :915) | Inconsistent | `guides/cc-isolated-usage.md:935` / `devcontainer-config/cc-isolated.sh:912-915` | High |
| 2 | Guides cite different targets for the same rationale; the code-symbol target prints the other recipe | Minor | `guides/devcontainer-setup.md:392-394` | Medium |
| 3 | Skills row is a third, divergent dev-cycle step list in a hybrid Trigger/When format | Minor | `AGENTS.md:36`, `GEMINI.md:36` | High |
| 4 | FC-A consequence: the guides name different mechanisms for getting a newer CC | Informational | `guides/devcontainer-setup.md:387-397` | Medium |

## Overall Assessment

On its own surfaces, the diff is consistent with the codebase's conventions. Placeholders, cross-reference style and the README index line all follow the established patterns, and nothing consumer-facing breaks. Its main effect is to align the guides with init-firewall.sh. That exposes one remaining disagreement, in code outside the diff: the launcher's `rebuild_hint` still recommends a plain relaunch for a container the firewall closed, and that relaunch will not rebuild (F1). Fix it as a follow-up in cc-isolated.sh, not by changing these guide edits. F2 and F3 are small in-place wording fixes. F4 waits on the FC-A escalation. None of these suggest the author skipped surveying conventions.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to docs/reviews/api-consistency-review-2026-10-15-doc-drift-cycle1.md, structured per the api-consistency-reviewer skill.
- Answered: Placeholder consistency (`<repo>` versus `[REPO]`/`WS`/`NAME`): consistent. Guide cross-references: F2. Agreement between the guides and the launcher/firewall output: aligned with init-firewall.sh, misaligned with rebuild_hint (F1). Skills-table row format and wording against siblings and CLAUDE.md row 12: F3. Name-pattern audit done. FC-A/FC-B/FC-C used as input; only consistency consequences filed (F3 builds on FC-B, F4 on FC-A, and F2 notes FC-C).
- Out of scope: Fixing cc-isolated.sh's `rebuild_hint` (not in the diff). Whether `--build-no-cache` should exist (FC-A territory). Security and performance review. No processes were started.
- Escalate: F1, to the author/orchestrator as a follow-up item for cc-isolated.sh:915 (a doc-versus-CLI disagreement users will see). F4 is tied to the existing FC-A escalation.
