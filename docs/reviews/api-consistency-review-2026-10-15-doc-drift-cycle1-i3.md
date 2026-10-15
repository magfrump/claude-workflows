Commit: 258f9ec4

# API Consistency Review — fix/doc-drift-cycle1 (iteration 3, final confirming pass)

**Scope:** `git diff main...HEAD` in /workspace/.claude/wt-doc-drift (AGENTS.md, GEMINI.md, guides/README.md, guides/cc-isolated-usage.md, guides/devcontainer-setup.md, docs/working/briefs/2026-10-02-doc-drift-cycle1.md). The docs/reviews/ artifacts are not under review.
**Date:** 2026-10-15
**Based on:** the Stage 1 merged fact-check summary, iteration 3 (k=3, HEAD 258f9ec4): no Incorrect or Stale; FC3-A Mostly accurate. Prior reports: docs/reviews/api-consistency-review-2026-10-15-doc-drift-cycle1.md (iteration 1) and -i2.md (iteration 2).

This pass does not re-file three items: `rebuild_hint` at cc-isolated.sh:560 (rubric A4, deferred), the init-firewall.sh "rebuilds" gloss (iteration-2 F3, rubric C4, deferred), and trigger-quoting in the Skills row (rubric C2, Won't-Fix). Fact-check items appear below only where they have a consistency consequence.

## Baseline Conventions

Carried over from iterations 1 and 2 and re-checked at 258f9ec4.

- **Repo placeholder in prose recipes:** `<repo>`. Used in guides/devcontainer-setup.md:397-398 and :406, guides/cc-isolated-usage.md:935 and :941, and devcontainer-config/init-firewall.sh:349-350. The synopsis block (guides/cc-isolated-usage.md:20-35) keeps `[REPO]` for an optional positional.
- **Recovery recipe for a bricked firewall:** init-firewall.sh:349-350 prints the two-step `cc-isolated --probe-only <repo>`, then `cc-isolated <repo>`.
- **Cross-references name their target by description.** Examples: cc-isolated-usage.md:932 "see "SNI filtering" above"; devcontainer-setup.md:394-395 "see the auto-update row in `cc-isolated-usage.md`'s troubleshooting table"; devcontainer-setup.md:408 "see "Changing the boundary"".
- **Skills table (AGENTS.md:26-36; GEMINI.md identical apart from the intro line at :3):** three columns. The Trigger cell is a bold lead phrase or prose. The Skill cell holds backticked names. global-instructions/CLAUDE.md:32 (row 12) is the source the new row mirrors.

## Status of iteration-2 findings

| Iter-2 # | Finding | Status at 258f9ec4 | Evidence |
|---|---|---|---|
| F1 | "see the row below" named no target, and the adjacent row was the wrong one | **Resolved** | cc-isolated-usage.md:935 (truncated …): `… see the "newly registered profile has no effect" row below; …`. The target's Symptom cell at :941 begins `A newly registered profile has no effect`, so the name matches the row. |
| F2 | The bare-form effect list was shorter than the cited comment's, under "each one dropped has its own effect" | **Resolved** | Both guides now list four effects after "among them". devcontainer-setup.md:401-403: `(among / them base-only egress, an empty config hash, a \`~/.claude\` volume shared across projects, and a / build pointed at \`/Dockerfile\`)`. cc-isolated-usage.md:935 lists the same four in the same order. They match cc-isolated.sh:542-547 (empty CC_EGRESS_PROFILE/CC_CONFIG_HASH, empty CC_PROJECT_ID and the shared volume, empty CC_CONFIG_DIR and /Dockerfile). "among them" also removes the over-claim for CC_PROJECT_NAME. |
| F3 | Guides say "recreates", the init-firewall hint says "rebuilds" | Deferred (not re-filed) | Rubric C4. init-firewall.sh:349 is unchanged. |

## Name-Pattern Audit

The diff adds no CLI flags, commands, functions or config fields. Its new public "names" are the documented invocations, the placeholder, one Skills-table row, the README index wording, and the cross-reference targets.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `cc-isolated --probe-only <repo>` (recovery recipe) | documented invocation | verify step; init-firewall hint; synopsis `--probe-only [REPO]` | guides/devcontainer-setup.md:406; devcontainer-config/init-firewall.sh:349; guides/cc-isolated-usage.md:25 | Consistent |
| `cc-isolated <repo>` | documented invocation | "Relaunch with `cc-isolated <repo>`"; init-firewall hint | guides/cc-isolated-usage.md:941; devcontainer-config/init-firewall.sh:350 | Consistent |
| `<repo>` | placeholder | `[REPO]` (synopsis), `<repo>` (init-firewall hint) | guides/cc-isolated-usage.md:20-35; devcontainer-config/init-firewall.sh:349-350 | Consistent: prose uses `<repo>`, the synopsis uses `[REPO]` |
| `dev-cycle` (Skills row) | table row / skill name | `tech-debt-triage`, `design-space-situating`, `code-review` | AGENTS.md:28-35; skills/dev-cycle/SKILL.md:2; global-instructions/CLAUDE.md:32 | Consistent: lead phrase, keywords and step list match row 12; the orchestrator clause matches the skill's description; AGENTS.md and GEMINI.md rows are byte-identical |
| "the exit scan of host-git inputs", "`cc-push`" (README index) | index wording | the other index entries' "Use once …" / noun-list shape | guides/README.md:45-51 | Consistent |
| "the "newly registered profile has no effect" row below" | cross-reference (within a table) | "see "SNI filtering" above" | guides/cc-isolated-usage.md:932 | Consistent: names its target, which exists at :941 |
| "the auto-update row in `cc-isolated-usage.md`'s troubleshooting table" | cross-reference (guide to guide) | as above | guides/cc-isolated-usage.md:932 | Consistent: target exists at :940 and names `claude update` |
| "the comment above `rebuild_hint` in `cc-isolated.sh`" | cross-reference (guide to code) | "see rebuild_hint in cc-isolated.sh" | devcontainer-config/init-firewall.sh:345 | Consistent: the comment (cc-isolated.sh:537-556) holds the four effects the guide lists |

## Findings

#### F1. The synopsis and a neighbouring row still say `--probe-only` "REBUILDS", next to new prose that says it "recreates"

**Severity:** Informational
**Location:** `guides/cc-isolated-usage.md:25` and `:941` (not in the diff), versus `guides/cc-isolated-usage.md:935` and `guides/devcontainer-setup.md:397` (in the diff)
**Move:** 3 (documentation versus the command's own description)
**Confidence:** Medium
**Legibility-target:** the author or orchestrator who picks up the deferred C4 script-wording follow-up

Evidence:
> cc-isolated-usage.md:25: `cc-isolated --probe-only [REPO]   # REBUILD REPO's container from the blessed config, run the`
> cc-isolated-usage.md:935 (truncated …): `` `cc-isolated --probe-only <repo>` (recreates the container from the blessed config and re-probes) ``
> cc-isolated-usage.md:941 (truncated …): `Relaunch with \`cc-isolated <repo>\`, which rebuilds with both set.`

This is the same class as the deferred C4 item, found at two more places in a guide the diff touches. Iteration 2 chose "recreates" because the image layers are cached. The synopsis and the :941 row are pre-existing text and still say "rebuild". `devcontainer up --remove-existing-container` does run an image build (cache-reusing), so "rebuild" is not wrong, only less precise. The command, flags and two-step order agree everywhere, so the recipe works. This is not a defect in the diff.

**Recommendation:** No change in this branch. If the C4 follow-up unifies the gloss, include cc-isolated-usage.md:25 and :941 and the cc-isolated.sh:883 comment, so the guide and the script move together.

## What Looks Good

- Both in-scope iteration-2 findings (F1, F2) are resolved, and the fixes did not introduce new drift. The renamed pointer matches the target row's Symptom text exactly.
- The two guides now give the bare-form warning with the same four effects, in the same order, under the same "among them" hedge. The list matches the code comment that devcontainer-setup.md cites.
- `<repo>` and the two-step recipe (same flags, same order) are consistent across both guides and init-firewall.sh:349-350.
- The AGENTS.md/GEMINI.md `dev-cycle` row mirrors global row 12's lead phrase, keywords and step list. It replaces "rows 6/9" with the tool-agnostic workflow names and matches skills/dev-cycle/SKILL.md:4 on collect, land and dispatch. The rows in the two files are identical.
- guides/README.md:49 uses the target guide's own nouns and keeps the index sentence shape.
- No CLI flag, exit code or command changed. No consumer can break.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Synopsis and :941 row say "rebuild(s)" for `--probe-only`/relaunch, next to new "recreates" prose (pre-existing; same class as deferred C4) | Informational | `guides/cc-isolated-usage.md:25`, `:941` | Medium |

## Overall Assessment

The branch is consistent with the repo's documentation conventions at 258f9ec4. Every in-scope finding from iterations 1 and 2 is resolved. The documented invocations, the placeholder, the cross-references (guide to guide, guide to code, within a table) and the Skills row all match their precedents. The one remaining item is Informational, outside the diff, and belongs with the already-deferred C4 wording follow-up. FC3-A (the "a toolchain version" parenthetical) is a fact-check accuracy item with no consistency consequence, so it is not filed here. No consumer impact. From an API-consistency standpoint, nothing blocks the merge.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to docs/reviews/api-consistency-review-2026-10-15-doc-drift-cycle1-i3.md, structured per the api-consistency-reviewer skill.
- Answered: Iteration-2 F1 and F2 are resolved at 258f9ec4. F3 stays deferred (C4) and is not re-filed. Documented CLI invocations and `<repo>`/`[REPO]` placeholders are consistent. Cross-references between the guides, to cc-isolated.sh, and within the troubleshooting table all name existing targets. The AGENTS.md/GEMINI.md Skills row matches the other rows' format, global-instructions/CLAUDE.md row 12 and the skill description, and the two files carry it identically. The name-pattern audit is done. One new Informational item (F1), pre-existing text.
- Out of scope: Script text (`rebuild_hint` at cc-isolated.sh:560, the init-firewall.sh "rebuilds" gloss, the cc-isolated.sh:883 comment). Trigger-quoting in the Skills row (Won't-Fix C2). FC3-A's accuracy of "a toolchain version"/"pruned build cache" in devcontainer-setup.md:389-390 (fact-check, not consistency). Live auto-update and bare-run behaviour (needs a host run). Security and performance. No processes were started.
- Escalate: Nothing. F1 can ride along with the deferred C4 follow-up.
