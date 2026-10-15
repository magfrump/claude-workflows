Commit: 9e0ff1a5

# API Consistency Review — fix/doc-drift-cycle1 (iteration 2)

**Scope:** `git diff main...HEAD` in /workspace/.claude/wt-doc-drift (AGENTS.md, GEMINI.md, guides/README.md, guides/cc-isolated-usage.md, guides/devcontainer-setup.md, docs/working/briefs/2026-10-02-doc-drift-cycle1.md). The docs/reviews/ artifacts are not under review.
**Date:** 2026-10-15
**Based on:** the Stage 1 merged fact-check summary, iteration 2 (k=3, HEAD 9e0ff1a5): FC2-A, FC2-B, FC2-C. Iteration 1's report is docs/reviews/api-consistency-review-2026-10-15-doc-drift-cycle1.md.

This review does not re-file two items. Iteration 1's F1 (`rebuild_hint`, cc-isolated.sh:560) is deferred as out of scope (rubric A4, override-log row 2026-10-15). The trigger-quoting half of F3 is a recorded Won't-Fix (rubric C2, override-log row 2026-10-15). Fact-check items appear below only where they have a consistency consequence.

## Baseline Conventions

These carry over from iteration 1 and were re-checked at 9e0ff1a5.

- **Repo placeholder in prose recipes:** `<repo>`. It is used in guides/devcontainer-setup.md:397-398 and :406, guides/cc-isolated-usage.md:935 and :941, and devcontainer-config/init-firewall.sh:349-350. The synopsis keeps `[REPO]` for an optional positional.
- **Recovery recipe for a bricked firewall:** init-firewall.sh:347-350 prints the two-step `cc-isolated --probe-only <repo>`, then `cc-isolated <repo>`.
- **Cross-references between and within guides name their target by description.** Examples: cc-isolated-usage.md:932 "see "SNI filtering" above". devcontainer-setup.md:394 "see the auto-update row in `cc-isolated-usage.md`'s troubleshooting table", which is new in 9e0ff1a5. devcontainer-setup.md:407 "see "Changing the boundary"".
- **Skills table (AGENTS.md:26-36, GEMINI.md identical):** three columns. The Trigger cell is a bold lead phrase or plain prose. The Skill cell holds backticked names. global-instructions/CLAUDE.md:32 (row 12) is the source this row mirrors.

## Status of iteration-1 findings

| Iter-1 # | Finding | Status at 9e0ff1a5 | Evidence |
|---|---|---|---|
| F1 | Guide recipe contradicts `rebuild_hint`'s printed advice | Deferred (not re-filed) | Override-log row 2026-10-15. cc-isolated.sh:560 is unchanged. |
| F2 | The guides cite different targets for the same rationale, and the code-symbol target prints the other recipe | **Resolved** | devcontainer-setup.md:402-403 now reads "see the comment above `rebuild_hint` in `cc-isolated.sh`". The comment at cc-isolated.sh:537-556 holds the rationale and says "name the launcher first". It does not print a recipe, so the contradiction is gone. The two guides still point at different targets (a code comment and a table row). Both targets now agree with the text that cites them, so this is not re-filed. |
| F3 (step-list half) | Third, divergent dev-cycle step list | **Resolved** | AGENTS.md:36 now carries row 12's list verbatim: "health and cleanup, every revisit trigger, watched questions, claim spot-check, conditional deep-audit check and brainstorm, roadmap (`docs/roadmap.md`), then build briefs for its top items". The orchestrator clause ("collects, lands and dispatches build loops") matches skills/dev-cycle/SKILL.md:4. GEMINI.md is byte-identical. |
| F3 (format half) | Quoted triggers in the Trigger cell | Won't-Fix (not re-filed) | Override-log row 2026-10-15. |
| F4 | The guides name different mechanisms for getting a newer CC | **Resolved** | devcontainer-setup.md:393-396: "Newer CC versions arrive through Claude Code's own auto-update inside the container, or `claude update` there (see the auto-update row …)". This agrees with cc-isolated-usage.md:940. |

## Name-Pattern Audit

The diff adds no CLI flags, commands, functions or config fields. Its new public "names" are the documented invocations, the placeholder, one Skills-table row key, and the cross-reference targets.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `cc-isolated --probe-only <repo>` (recovery recipe) | documented invocation | verify step, blast-radius note, init-firewall hint | guides/devcontainer-setup.md:406; devcontainer-config/init-firewall.sh:349 | Consistent |
| `cc-isolated <repo>` | documented invocation | "Relaunch with `cc-isolated <repo>`", init-firewall hint | guides/cc-isolated-usage.md:941; devcontainer-config/init-firewall.sh:350 | Consistent |
| `<repo>` | placeholder | `[REPO]` (synopsis), `WS` (rebuild_hint comment) | guides/cc-isolated-usage.md:25-35; devcontainer-config/cc-isolated.sh:534-535 | Consistent |
| `dev-cycle` (Skills row) | table row / skill name | `tech-debt-triage`, `design-space-situating`, `code-review` | AGENTS.md:28-35; skills/dev-cycle/SKILL.md:2; global-instructions/CLAUDE.md:32 | Consistent: the name, lead phrase and step list match row 12 |
| "the auto-update row in `cc-isolated-usage.md`'s troubleshooting table" | cross-reference | "see "SNI filtering" above" | guides/cc-isolated-usage.md:932 | Consistent: names its target, and the row exists at :940 |
| "the comment above `rebuild_hint` in `cc-isolated.sh`" | cross-reference (guide to code) | "see rebuild_hint in cc-isolated.sh" (init-firewall comment) | devcontainer-config/init-firewall.sh:345 | Consistent: the target holds the rationale |
| "see the row below" | cross-reference (within a table) | "see "SNI filtering" above"; "the auto-update row in …" | guides/cc-isolated-usage.md:932; guides/devcontainer-setup.md:394 | **Inconsistent: names no target, and the adjacent row is the wrong one. See F1** |

## Findings

#### F1. The "see the row below" reference names no target, unlike every other in-guide reference, and the row directly below is the wrong one

**Severity:** Minor
**Location:** `guides/cc-isolated-usage.md:935`
**Move:** 2 (reference naming against the grain) / 3 (documentation cross-reference drift)
**Confidence:** High
**Legibility-target:** an operator in the troubleshooting table following the pointer from the bricked-firewall row

Precedent: in-guide references name their target by description. Examples: "see "SNI filtering" above" at guides/cc-isolated-usage.md:932, "see the auto-update row in `cc-isolated-usage.md`'s troubleshooting table" at guides/devcontainer-setup.md:394, and "see "Changing the boundary"" at guides/devcontainer-setup.md:407.

Evidence:
> cc-isolated-usage.md:935 (truncated …): `… each one dropped has its own effect (base-only egress and an empty config hash, see the row below; the shared \`cc--claude-config\` volume), and the launcher's probe never runs. |`
> cc-isolated-usage.md:936 (the row actually below, truncated …): `| \`OAuth error: getaddrinfo …\` at \`/login\`, launch probe passed | …`
> cc-isolated-usage.md:941 (the intended target, truncated …): `| A newly registered profile has no effect — the container's egress is still base-only (…) | The container was rebuilt with a bare \`devcontainer up --remove-existing-container …\` …`

This is the consistency consequence of FC2-A. Commit 330138d8 wrote "the base-only egress row below", which matched the descriptive-reference convention. Commit 9e0ff1a5 shortened it to "the row below". In a markdown table "below" reads as "adjacent", and the adjacent row is the OAuth row. The intended row is six rows further down. The same commit wrote a correctly named reference in the other guide (devcontainer-setup.md:394), so the diff is internally inconsistent. Readers cannot detect this from structure: a renderer gives table rows no anchors, so the description is the only handle.

**Recommendation:** Restore a named target, e.g. "see the "newly registered profile has no effect" row below". This matches :941's Symptom text and the :932 style.

#### F2. The bare-form consequence list in both guides says each dropped variable has its own effect, but it lists fewer effects than the source the guide cites

**Severity:** Informational
**Location:** `guides/devcontainer-setup.md:399-403`; `guides/cc-isolated-usage.md:935`
**Move:** 7 (asymmetry between a document and its cited source)
**Confidence:** High (the text comparison). The runtime effect of an empty CC_CONFIG_DIR is Medium; per FC2-B it needs a host run.
**Legibility-target:** a guide reader who follows the citation to the code comment; the author deciding whether to complete the list

Evidence:
> devcontainer-setup.md:399-403: `variables the launcher exports, and each one dropped has its own effect / (base-only egress, an empty config hash, the shared \`cc--claude-config\` volume), / and the launcher's probe never runs (see the comment above \`rebuild_hint\` in / \`cc-isolated.sh\`).`
> cc-isolated.sh:545-547 (the cited comment): `… an empty / # CC_PROJECT_ID mounts the SHARED \`cc--claude-config\` volume; an empty CC_CONFIG_DIR / # points the build at /Dockerfile.`

FC2-B already covers the omission. The consistency point is that devcontainer-setup.md sends the reader to a comment that names four effects, while the sentence citing it says "each one dropped has its own effect" and lists three. The two guides agree with each other: both list the same three effects. So the asymmetry is between the guides and their source, not between the guides. The variable list is also asymmetric. The comment names five variables (cc-isolated.sh:538), and CC_PROJECT_NAME has no stated effect anywhere, so "each one dropped has its own effect" is broader than any surface supports.

**Recommendation:** Either add the fourth effect, e.g. "the build pointed at `/Dockerfile`" (or "the build fails", once a host run settles FC2-B's residue), or soften "each one dropped has its own effect" to "among them". Apply the same wording to both guides so they stay in step.

#### F3. The guides now say the launcher "recreates" from the blessed config, while the firewall hint they were aligned with still says "rebuilds"

**Severity:** Informational
**Location:** `guides/cc-isolated-usage.md:935`, `guides/devcontainer-setup.md:397`, versus `devcontainer-config/init-firewall.sh:346`, `:349` (not in the diff)
**Move:** 3 (documentation versus CLI output)
**Confidence:** Medium
**Legibility-target:** the author or orchestrator queuing the deferred script follow-up

Evidence:
> cc-isolated-usage.md:935 (truncated …): `\`cc-isolated --probe-only <repo>\` (recreates the container from the blessed config and re-probes)`
> devcontainer-setup.md:397: `\`cc-isolated --probe-only <repo>\` (always recreates it from the blessed config and`
> init-firewall.sh:349: `echo "         cc-isolated --probe-only <repo>    # rebuilds from the blessed config, re-probes" >&2`

Iteration 1 praised the guides for matching init-firewall.sh:343-350 in substance. 9e0ff1a5 deliberately changed "rebuilds" to "recreates", because the A1 fix established that the image layers are cached (FC2-C). That makes the guides more accurate than the script's printed hint. The command and its two-step order still agree, so the recipe works. Only the gloss differs, and an operator comparing the terminal with the guide could read "rebuilds" as a fresh image. This is the same class as the deferred `rebuild_hint` item: script text outside the brief's scope. It is not a defect in the diff.

**Recommendation:** No change to the guides. Fold "rebuilds" to "recreates" at init-firewall.sh:346/:349 into the follow-up unit already queued for `rebuild_hint` (rubric A4).

## What Looks Good

- All three iteration-1 findings in scope are resolved (F2, the F3 step list, and F4). The fixes did not introduce new placeholder or recipe drift.
- `<repo>` is used everywhere in prose, and the two-step recipe has the same order and the same flags in both guides and in init-firewall.sh.
- The new devcontainer-setup.md:394 reference ("the auto-update row in `cc-isolated-usage.md`'s troubleshooting table") is a model of the descriptive-reference convention, and its target exists (:940).
- The AGENTS.md/GEMINI.md dev-cycle row now matches global row 12's lead phrase, keywords and step list. It translates "rows 6/9" into tool-agnostic workflow names, and its orchestrator clause matches the skill's description (collect, land, dispatch: steps 7, 9, 10 per the fact-check). The two files are identical.
- guides/README.md:49 uses the target guide's own nouns ("exit scan", `cc-push`) and keeps the index's sentence shape.
- No CLI flag, exit code or command changed. No consumer can break.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | "see the row below" names no target (convention: describe it), and the adjacent row is the wrong one (FC2-A consequence) | Minor | `guides/cc-isolated-usage.md:935` | High |
| 2 | Bare-form effect list (three items) is shorter than the cited comment's four, under an "each one dropped" claim (FC2-B consequence) | Informational | `guides/devcontainer-setup.md:399-403`; `guides/cc-isolated-usage.md:935` | High |
| 3 | Guides say "recreates", the firewall hint still says "rebuilds" (script text, out of scope) | Informational | `devcontainer-config/init-firewall.sh:346,349` vs the guides | Medium |

## Overall Assessment

The branch is consistent with the codebase's documentation conventions. The iteration-1 findings in scope are resolved, and nothing consumer-facing breaks. One in-diff fix remains: restore a named target at cc-isolated-usage.md:935 (F1, Minor, one phrase). Iteration 2 regressed that pointer, and the same commit used the correct style elsewhere. F2 is an optional wording completion that waits on FC2-B's host check. F3 belongs with the already-deferred script follow-up. None of these suggest a gap in surveying conventions.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to docs/reviews/api-consistency-review-2026-10-15-doc-drift-cycle1-i2.md, structured per the api-consistency-reviewer skill.
- Answered: Status of iteration-1 F2, F3 (step-list half) and F4: all resolved. F1 and the F3 format half are recorded as deferred or Won't-Fix and not re-filed. Documented CLI invocations and the `<repo>` placeholder are consistent. Guide-to-guide and guide-to-code cross-references: one regression (F1). The AGENTS.md/GEMINI.md Skills row matches row 12 and the skill, and the two files are identical. The name-pattern audit is done. FC2-A and FC2-B are used only for their consistency consequences (F1, F2). FC2-C informs F3.
- Out of scope: Script changes (`rebuild_hint` at cc-isolated.sh:560, the init-firewall.sh hint wording). Whether an empty CC_CONFIG_DIR fails the build (FC2-B residue; needs a host run). The cached-layer qualification (FC2-C, a fact-check item with no API-consistency consequence). Security and performance review. No processes were started.
- Escalate: Nothing new. F3 should ride along with the already-queued `rebuild_hint` follow-up (rubric A4).
