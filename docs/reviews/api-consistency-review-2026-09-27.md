Commit: 795ff71

# API Consistency Review — integrate/q077-q078-q080

**Scope:** `git diff main...HEAD -- . ':!docs/reviews'` (Q-077 hook deny rules + wiring.json, Q-078 report stamp + .gitignore + remediation messages, Q-080 all 25 skill descriptions as a routing contract)
**Date:** 2026-09-27
**Based on:** docs/reviews/iter2-code-fact-check-report.md, code-fact-check-report-r1/-r2/-r3.md (Q-077/Q-078), pass2-code-fact-check-report-r1/-r2/-r3.md (Q-080). Their verdicts are taken as fact and not re-verified.

## Baseline Conventions

- **Hook CLI options** (`hooks/auto-approve-allowed-commands.sh:13-17`): long options only, `--debug` (bool) and `--permissions JSON` (test override of the settings files). "Unset" for `--permissions` is tested as `-n "$CUSTOM_PERMISSIONS"` (:172): an empty string means "not given".
- **Rule-source convention:** rules come from three files in a fixed order (`~/.claude/settings.json`, `<git root>/.claude/settings.json`, `.../settings.local.json`, cwd fallback). The allow side established it (`get_allowed_prefixes`). The new deny side copies it exactly (`get_deny_globs`, :132-149).
- **Allow-rule matching (pre-existing):** `Bash(X)` and `Bash(X:*)` both reduce to prefix `X` (:87, :104). `X` then matches the command exactly, or as a prefix followed by a space or `/` (:208). `*` anywhere else is literal (the `==` right-hand side is quoted). A bare `Bash` is ignored (`grep -E '^Bash\('`).
- **Settings rule syntax:** `permissions.{allow,deny}` arrays of `Tool(spec)` strings. The repo's own host probes (decision log 56) show Claude Code treats `Bash(*)` and `Bash(**)` differently: `Bash(**)` denies every call including multi-line, while `Bash(*)` removes the tool.
- **wiring.json:** `_comment` string array plus `hooks` and `permissions.deny`. Deny entries for paths under the config dir use the `/{{CLAUDE_DIR}}` token. Entries are merged by exact string match.
- **Report stamp:** one `<input> <sha256>` line per input. Lowercase single-word input names. The stale message lists the changed input names after `changed since generation:` and ends with `Regenerate: bash test/skills/generate-reports.bash <skill> <fixture>` (`runner-contract.bash:214-223`).
- **Skill descriptions (routing surface):** after this diff, all 25 carry a `Triggers:` label followed by quoted phrases. The most common "not this" form is `<concern> → <skill>` (bp-market-sizing, bp-moat, bp-unit-economics, cowen, yglesias, performance-reviewer, pre-mortem, what-if-analysis, design-space-situating, fact-check). Body sections are `## When to use` with a `- Trigger phrases:` bullet (20 of 25).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--deny JSON` | CLI flag | `--permissions JSON`, `--debug`; settings keys `permissions.allow` / `permissions.deny` | `hooks/auto-approve-allowed-commands.sh:13-17`, `hooks/wiring.json:128` | Minor: pairs with `--permissions` (which means *allow*) instead of `--allow`; its "set" semantics also differ (F3, F4) |
| `get_deny_globs` (:132) | function (script-internal) | `get_allowed_prefixes` | `hooks/auto-approve-allowed-commands.sh:170` | Consistent (`get_<noun>` shape). "globs" vs "prefixes" honestly reflects the different matching model |
| `extract_deny_from_file` | function (internal) | `extract_prefixes_from_file`, `extract_prefixes_from_json` | `:83`, `:92` | Minor drift: the neighbors name the output (`prefixes`), this one names the source list (`deny`). Informational only |
| `matches_deny` (:154) | predicate (internal) | `is_command_allowed` | `:199` | Informational: `matches_*` vs `is_*` predicate prefix; internal, no consumer |
| `deny_rules_to_globs` | function (internal) | none of the form `X_to_Y` | none — searched `hooks/*.sh` function names | New shape; fine |
| `CUSTOM_DENY`, `CUSTOM_DENY_SET` | internal vars | `CUSTOM_PERMISSIONS` | `:69` | `CUSTOM_DENY` consistent. `_SET` companion has no neighbor (F4) |
| `Bash(*.credentials.json*)` | config entry | `Read(/{{CLAUDE_DIR}}/.credentials.json)`, `Read(~/.npmrc)` | `hooks/wiring.json:130-133` | Consistent `Tool(spec)` form. Deliberately not `{{CLAUDE_DIR}}`-scoped (see What Looks Good) |
| stamp inputs `skill`, `runner`, `fixture` (dropped `contract`) | persisted field names | old 4-line stamp `skill runner contract fixture` | `test/skills/runner-contract.bash:198-203` | Consistent (subset of the existing names, same grammar) |
| stale reason `stamp format` | message token | input names `skill`/`runner`/`fixture` in the same slot | `runner-contract.bash:223` | Informational: a pseudo-input occupying the input-name slot (F9) |
| `.gitignore` sidecars `*.report.md`, `*.stamp`, `*.failed`, `*.transcript.jsonl` | persisted file names | output list in `generate-reports.bash:10-15` | `test/skills/generate-reports.bash:10-15` | Consistent: exactly the four the generator documents |
| "not this" routing line (25 descriptions) | routing-contract phrasing | arrow form `X → skill` | `skills/{business-plan-critique-*,cowen-critique,yglesias-critique,performance-reviewer,pre-mortem,what-if-analysis,design-space-situating,fact-check}/SKILL.md` | Inconsistent: five phrasings (F5) |
| `Triggers:` label | routing-contract label | same label in all 25 | `skills/*/SKILL.md` frontmatter | Consistent |
| body `## When to use` / `- Trigger phrases:` | doc section names | same in 20 skills; `## When to Use This Skill (vs. …)` + prose "More trigger phrases" in 2 | `skills/*/SKILL.md` | Minor drift in 3–5 skills (F8) |

## Findings

#### F1. The same `Bash(...)` rule string means different things in the hook's allow list and its deny list

**Severity:** Inconsistent
**Location:** `hooks/auto-approve-allowed-commands.sh:87`, `:104`, `:208` (allow) vs `:119-122` (deny)
**Move:** 7 (asymmetry), 3 (consumer contract)
**Confidence:** High (probed; see evidence)
**Legibility-target:** for-author

Evidence (allow parse and match):
```
104:    | sed -E 's/^Bash\(//; s/(:\*)?\)$//' \
208:    if [[ "$full_command" == "$allowed" ]] || [[ "$full_command" == "$allowed "* ]] || [[ "$full_command" == "$allowed/"* ]]; then
```
(excerpt :104 ends inside `extract_prefixes_from_file`, which continues to :106 `|| true` — read. :208 is inside `is_command_allowed`, :201-216 — read.)
Evidence (deny parse):
```
119 deny_rules_to_globs() {
120   sed -nE 's/^Bash$/*/p; s/^Bash\((.*)\)$/\1/p' \
121     | sed -E 's/:\*$/*/; s/[^A-Za-z0-9*]/\\&/g'
122 }
```
The diff adds a second parser for the same rule grammar. The two readings diverge in three places. Probe run from the scratchpad with `HOME` isolated, using `--permissions`/`--deny`. `[unverified — submitted as claim]`, route: code-fact-check:

| Rule | As allow | As deny |
|---|---|---|
| `Bash(ls)` / `Bash(rm)`, no wildcard | prefix: `ls -la` → **allow** | exact: deny `Bash(rm)` does **not** block `rm -rf x` (hook returned allow) |
| `Bash(rm:*)`, legacy | word-boundary prefix: allow `Bash(rm:*)` does **not** approve `rmdir x` | plain prefix `rm*`: deny `Bash(rm:*)` **blocks** `rmdir x` |
| `Bash(ls *)`, modern space-star | literal: `ls -la` **not** approved (the rule is dead) | glob: matches `ls -la` |

The deny readings err toward falling through to the prompt, so none of this weakens the deny backstop. The consumer cost is on people who write rules. A user who reads the header's deny semantics ("only `*` is a wildcard", :56-57) and writes allow rules to match gets a silently dead allow rule (`Bash(ls *)`). A no-wildcard deny rule like `Bash(rm)` looks like it covers `rm …` because the same shape does on the allow side, and it does not. The header's KNOWN DIVERGENCE note (:57-61) documents only the hook-vs-Claude-Code gap for `Bash(rm *)`, not this hook-vs-itself gap.

**Recommendation:** Either state the allow side's reading next to the deny syntax note in the header (one line per row of the table above), or route allow rules through the same tokenizer and keep the prefix/word-boundary step as a separate allow-only step. Pin the `Bash(ls *)`-as-allow behavior with a test either way, so the choice is deliberate.

#### F2. The hook's model treats `Bash(*)` and `Bash(**)` as identical; the repo's own Claude Code probes say they differ

**Severity:** Informational
**Location:** `hooks/auto-approve-allowed-commands.sh:56-57`; `hooks/wiring.json:131`
**Move:** 3 (consumer contract: the hook re-implements Claude Code's rule grammar)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Evidence: header `:56` `# Rule syntax: only \`*\` (and the legacy trailing \`:*\`) is a wildcard, and a`. Decision log 56 (`docs/decisions/log.md:79`): "a `Bash(**)` deny rule, which denies every call, multi-line included, while keeping Bash visible (`Bash(*)` removes the tool)". In the hook's bash glob, `*` crosses newlines. Whether Claude Code's `*` in `Bash(*.credentials.json*)` matches a multi-line command, and whether it accepts a leading `*` at all, is not recorded anywhere I found (searched `guides/`, `docs/decisions/`, `docs/thoughts/`). This matters only for the CC-native half of the backstop: the hook side falls through to a prompt either way.

**Recommendation:** Add the multi-line and leading-`*` cases to the existing host-verification question (the one tracking #39344 for `allow`). No code change is needed in the hook.

#### F3. `--deny` is paired with `--permissions`, not `--allow`

**Severity:** Minor
**Location:** `hooks/auto-approve-allowed-commands.sh:15-18`
**Move:** 2 (naming)
**Confidence:** High
**Legibility-target:** for-author

Precedent: `permissions.allow` / `permissions.deny` used in `hooks/wiring.json:128-129` and every settings file the hook reads (`:103`, `:127`)

Evidence:
```
15 #   --permissions JSON      Use custom permissions instead of reading from settings files
17 #   --deny JSON             Use custom deny rules instead of reading permissions.deny
18 #                           from the settings files (same format)
```
In the settings schema the hook mirrors, "permissions" is the parent of both `allow` and `deny`. With `--deny` beside it, `--permissions` now reads as "all permissions" but covers only `allow`. The help line at :15 is also now partly untrue: `--permissions` alone no longer isolates the run from the settings files, because deny rules are still read from them (F4).

**Recommendation:** Add `--allow` as the documented name, keep `--permissions` as an alias for existing callers (only `test/auto-approve-allowed-commands.bats` uses it), and reword :15 to "custom allow rules; deny rules are still read from settings unless `--deny` is given".

#### F4. `--permissions ''` and `--deny ''` mean opposite things

**Severity:** Minor
**Location:** `hooks/auto-approve-allowed-commands.sh:172` vs `:133`, `:230-234`
**Move:** 7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```
172   if [[ -n "$CUSTOM_PERMISSIONS" ]]; then
133   if $CUSTOM_DENY_SET; then
230       --deny)
231         CUSTOM_DENY="$2"
232         CUSTOM_DENY_SET=true
```
An empty `--permissions` value falls back to the settings files. An empty `--deny` value (or `[]`) replaces them with "no deny rules". The deny choice is the more useful one for tests: it is how a test states "no deny rules" explicitly. The two sibling options now follow different conventions, and only `--deny`'s comment (:70) says so.

**Recommendation:** Give `--permissions` the same `_SET` semantics, or document the difference on the two help lines. There are no external consumers, so either is cheap.

#### F5. The "not this — use X" routing line is written five different ways across the 25 descriptions

**Severity:** Minor
**Location:** `skills/*/SKILL.md` frontmatter `description:` (e.g. `skills/api-consistency-reviewer/SKILL.md:4-8`, `skills/security-reviewer/SKILL.md`, `skills/code-fact-check/SKILL.md`, `skills/code-review/SKILL.md`, `skills/architecture-review/SKILL.md:4-8`)
**Move:** 2 (naming/phrasing convention), 1 (baseline)
**Confidence:** High
**Legibility-target:** for-author

Precedent: arrow form `<concern> → <skill>` used in `skills/{business-plan-critique-market-sizing,business-plan-critique-moat,business-plan-critique-unit-economics,cowen-critique,yglesias-critique,performance-reviewer,pre-mortem,what-if-analysis,design-space-situating,fact-check}/SKILL.md`

Evidence (verbatim fragments):
- api-consistency-reviewer: "Not architecture-review (structure) or security-reviewer (exploitability)."
- code-fact-check: "For prose claims about the world use fact-check."
- security-reviewer: "For a full multi-concern review use code-review."
- dependency-upgrade / test-strategy / ui-visual-review: "code-review auto-selects it when …"
- performance-reviewer: "Security → security-reviewer; interfaces → api-consistency-reviewer; structure → architecture-review."

A router reading the truncated listing has to parse five constructions for one relation. The arrow form is already the majority and the most compact. The "auto-selects" form is a different relation ("reached via"), and fine to keep distinct.

**Recommendation:** Normalize the "Not …"/"For … use …" forms to `<concern> → <skill>` next time these descriptions are touched. This is not worth a pass of its own.

#### F6. architecture-review's routing line names no skill

**Severity:** Minor
**Location:** `skills/architecture-review/SKILL.md:4-8`
**Move:** 3 (consumer contract: the description is what routes)
**Confidence:** High
**Legibility-target:** for-author

Precedent: sibling critics name their targets, e.g. `skills/performance-reviewer/SKILL.md` "Security → security-reviewer; interfaces → api-consistency-reviewer; structure → architecture-review."

Evidence: "implementation-only diffs. Security, performance, API naming → own critics. Triggers: …". "Own critics" gives the router nothing to route to. "API naming" also understates api-consistency-reviewer's scope, which covers error format, pagination, versioning and more. The removed text had "(security, performance, API consistency)".

**Recommendation:** Replace it with "Security → security-reviewer; performance → performance-reviewer; API consistency → api-consistency-reviewer". That is about 40 more characters, which the ~376-char description has room for.

#### F7. Routing pointers are not reciprocal among the code critics and some sibling pairs

**Severity:** Informational
**Location:** `skills/{security-reviewer,api-consistency-reviewer,divergent-design,code-review,business-plan-critique-moat,business-plan-critique-unit-economics}/SKILL.md` descriptions
**Move:** 7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Evidence: performance-reviewer routes to all three sibling critics. api-consistency-reviewer routes to architecture and security but not performance. security-reviewer routes only to code-review. design-space-situating → divergent-design, but divergent-design points only to brainstorming. draft-review → code-review ("for code use code-review"), but code-review has no prose → draft-review pointer. Of the three bp-* skills, only market-sizing names cowen-critique. This is reciprocity, not de-overlap, so it is not covered by the brief's "no de-overlap" decision. It is still a follow-up, not a defect of this diff.

**Recommendation:** Record it as a follow-up to Q-080 if routing misfires are ever observed. No action on this branch.

#### F8. Body section and label names drift in the skills whose section pre-existed

**Severity:** Informational
**Location:** `skills/pre-mortem/SKILL.md:32`, `:57`; `skills/what-if-analysis/SKILL.md:33`, `:48`; `skills/design-space-situating/SKILL.md` ("**More trigger phrases.**"); `skills/divergent-design/SKILL.md:24` ("Trigger phrasings")
**Move:** 2
**Confidence:** High
**Legibility-target:** for-automated-gate

Precedent: `## When to use` heading + `- Trigger phrases:` bullet used in 20 of `skills/*/SKILL.md`

Evidence: `grep -c '^## When to use'` returns 0 for pre-mortem and what-if-analysis (they keep `## When to Use This Skill (vs. …)`). The moved phrases sit in a prose paragraph starting "More trigger phrases:". `guides/skill-format-audit.md:74` says the phrases moved "into a `## When to use` section in each SKILL.md body (appended to the existing section in …)". That is accurate, but a gate grepping for `^## When to use` (as `test/workflow-required-sections.bats` does for workflows) would miss two skills.

**Recommendation:** Only matters if a skill-side section gate is added. At that point, rename the two headings to `## When to use (vs. …)`.

#### F9. Remediation messages for reports disagree on the "commit" step and the invocation form

**Severity:** Minor
**Location:** `scripts/health-check.sh:407`; `test/skills/runner-contract.bash:214`, `:216`, `:223`
**Move:** 4 (error/message consistency)
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```
health-check.sh:407  ... (listed in the runner output above; generate with test/skills/generate-reports.bash <skill>, then commit output/)"
runner-contract.bash:214   local regen="bash test/skills/generate-reports.bash $skill $fixture"
runner-contract.bash:223     echo "Stale report for $skill/$fixture: changed since generation: ${changed:-stamp format}. Regenerate: $regen"
```
Q-078 made committing part of the workflow, and health-check now says "then commit output/". The two messages a user actually hits for a single stale or missing report still stop at "Regenerate:". "output/" is also ambiguous: the path is `test/skills/<skill>/output/`. The invocation forms differ as well (`bash test/…` vs `test/…`).

**Recommendation:** Make `regen` end with `, then commit test/skills/$skill/output/`, and use `test/skills/<skill>/output/` in the health-check message.

#### F10. The stamp file has no format version; "stamp format" is inferred and shares the input-name slot

**Severity:** Informational
**Location:** `test/skills/runner-contract.bash:198-203`, `:220-223`
**Move:** 6 (versioning of a persisted contract)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence:
```
221     changed="$(diff <(printf '%s\n' "$now") "$stamp" | sed -nE 's/^< ([a-z]+) .*/\1/p' | tr '\n' ' ')"
223     echo "Stale report for $skill/$fixture: changed since generation: ${changed:-stamp format}. Regenerate: $regen"
```
(`check_report_stamp` runs :211-225 — read.) An old 4-line stamp is detected only because it has an extra line and no `<` lines. If an old stamp also has a changed input, the message names that input and not the format change. Regenerating fixes both, so nothing is lost. This behavior is correct and test-pinned (`eval-helpers-freshness.bats:102-108`). It still has two drawbacks: the next format change (for example, adding an input) will surface as a changed input name, not as "stamp format", and "stamp format" reads as if it were an input.

**Recommendation:** Optional: when the set of input names differs, say "stamp format (inputs: …)". No change is required now.

## What Looks Good

- The deny side uses exactly the same three settings sources and git-root fallback as the allow side (`get_deny_globs` :132-149 mirrors `get_allowed_prefixes`). A rule's location means the same thing for both lists.
- Deny-rule escaping: every non-alphanumeric character except `*` is escaped, so `?`, `[…]` and extglob characters match literally. That matches the header's stated grammar and is test-pinned. The documented claim ("only `*` is a wildcard") matches the code (probed with `Bash(cat file?.txt)`). route: code-fact-check.
- Bare `Bash`, `Bash(*)` and `Bash(**)` all map to "never allow", which matches the decision-56 host observation that both forms deny.
- The wiring.json Bash rule avoids the `{{CLAUDE_DIR}}` token. That token is exactly the thing the Q-049 note (override row 81) says is fragile in a leading-`/` position. A placeholder-free glob holds regardless of how Claude Code resolves settings-relative paths. The `_comment` block is updated in the same commit, following that file's convention.
- The stamp format change is a strict subset of the old input names with the same `<input> <sha256>` grammar. Old stamps fail closed with a named reason and are not silently accepted.
- The `.gitignore` admits exactly the four sidecars `generate-reports.bash:10-15` documents, and a test pins it (`eval-helpers-freshness.bats:110-118`).
- All 25 descriptions use the same `Triggers:` label and put routing before triggers. The fact-check/code-fact-check and pre-mortem/what-if pairs route reciprocally.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| F1 | Same rule string, different meaning in allow vs deny (no-wildcard, `:*`, space-`*`) | Inconsistent | `hooks/auto-approve-allowed-commands.sh:104,208` vs `:119-122` | High |
| F3 | `--deny` pairs with `--permissions`, not `--allow`; :15 help now partly untrue | Minor | `hooks/auto-approve-allowed-commands.sh:15-18` | High |
| F4 | Empty `--permissions` = fallback, empty `--deny` = none | Minor | `:172` vs `:133` | High |
| F5 | Five phrasings of the "not this" routing line | Minor | `skills/*/SKILL.md` descriptions | High |
| F6 | architecture-review routes to "own critics", naming no skill | Minor | `skills/architecture-review/SKILL.md:4-8` | High |
| F9 | Stale/missing-report messages omit the commit step Q-078 introduced | Minor | `scripts/health-check.sh:407`; `test/skills/runner-contract.bash:214-223` | High |
| F2 | Hook treats `Bash(*)`≡`Bash(**)`; CC does not (log 56); multi-line/leading-`*` CC coverage unverified | Informational | `hooks/auto-approve-allowed-commands.sh:56-57`; `hooks/wiring.json:131` | Medium |
| F7 | Non-reciprocal routing pointers | Informational | several descriptions | High |
| F8 | `## When to Use This Skill (vs. …)` / prose trigger labels in 3–5 skills | Informational | `skills/{pre-mortem,what-if-analysis,design-space-situating,divergent-design}/SKILL.md` | High |
| F10 | Stamp has no format version; "stamp format" is inferred | Informational | `test/skills/runner-contract.bash:198-223` | Medium |

## Overall Assessment

The branch fits its surrounding conventions well where it copies an existing pattern: rule sources, the stamp grammar, the wiring.json entry and comment, the `.gitignore` sidecar set, and the uniform `Triggers:` label. None of the findings is breaking: no existing caller of the hook, stamp or settings changes behavior except in the intended fail-closed direction. The one Inconsistent finding (F1) comes from adding a second parser for the rule grammar that reads three rule shapes differently from the allow parser next to it. It is safe, because the deny side over-matches. It is still a trap for anyone writing rules, and it is cheap to fix in documentation or with a shared tokenizer. The remaining items are phrasing and label hygiene on the new routing surface (F5, F6) and remediation messages that lag the new "commit reports" workflow (F9). All are fixable in place and none blocks the merge.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved to /workspace/docs/reviews/api-consistency-review-2026-09-27.md, structured per the api-consistency-reviewer skill, with a Goal-Alignment Note.
- **Answered:** covered all the surfaces named in the dispatch: hook CLI options (F3, F4), deny syntax vs allow parsing (F1) and vs Claude Code (F2), wiring.json structure (audit + What Looks Good), the stamp format as a persisted contract (F10), health-check and stale messages (F9), and skill descriptions as a routing contract (F5–F8).
- **Out of scope:** exploitability of the string-match bypasses (security-reviewer). Description lengths and the front-loading character positions (fact-checked in pass2 reports). De-overlap of shared trigger phrases (explicitly declined in Q-080). Q-076.
- **Escalate:** (1) F2: Claude Code's handling of a leading `*` and of multi-line commands in `Bash(*.credentials.json*)` needs a host check alongside the open #39344/`allow` item. (2) The baked copy at `devcontainer-config/claude-home/hooks/auto-approve-allowed-commands.sh` (gitignored payload, dated 2026-09-24) differs from `hooks/`. The deny logic reaches cc-isolated only after the payload is rebuilt. This is a deployment note, not a diff defect.
- **Decisions I made:** I treated script-internal function names as audit rows but not findings. I ran F1's probes myself as supporting evidence and marked them `[unverified — submitted as claim]` rather than self-certifying them.
