Commit: 47c9a8e (A) / d6e1f24 (B)

# API Consistency Review — dev-cycle pass 7 (k=1 loop pass, partial scope)

**Scope:** A: `git diff 28c6178..47c9a8e -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (wt-digest). B: `git diff c079e8c..d6e1f24 -- skills/dev-cycle/SKILL.md docs/decisions/log.md guides/skill-creation.md docs/dev-cycle.md docs/dev-cycle-sources.md workflows/codebase-onboarding.md docs/working/questions.md` (wt-devcycle). Also checked for consistency: global-instructions/CLAUDE.md row 12. Partial scope: everything else on both branches is context only.
**Date:** 2026-10-01
**Based on:** `docs/reviews/code-fact-check-report-digest-pass6.md` (Stage 1 for round one; round two's fixes were checked directly here) and the rubric sections "Final pass 5" and "Pass 6".

Probes, all in `mktemp -d` repos under the session scratchpad (`api7/`), each under `timeout`: (1) the 47c9a8e digest run against a clone of wt-devcycle at ed0d372; (2) a synthetic repo with a 5000-byte trigger line, roadmap headings `## NEXT`, `## Next steps` and `## Nextgen`, and seed lines `- foo (signal: bar)`, `- baz` and `- (signal: x)`. Nothing was written into either worktree except this report.

## Baseline Conventions

- **Key: value lines read by an agent.** The dev-cycle skill already uses plain `Key: value` lines: the record's `Model:` and Window lines, and the brief's `Status:`. The questions grammar uses bold keys (`**Needs:**`, `**Status:** OPEN`), and decision records use `**Status:** Accepted`.
- **Cross-references in the decision log.** Rows cite each other as `#NN` (`#18`, `#40`, `#44`), as `row NN` ("Superseded in part by row 49"), or as `log NN`. Revision markers sit in bold at the start of the decision cell (`**Amended 2026-09-28 (Q-082):**`).
- **"settings".** Across guides and global instructions, "settings" means Claude Code's `settings*.json` (`guides/bare-host-hook-wiring.md`, `guides/claude-config-security-checkup.md:8`). Before this change, no repo doc called itself a settings file.
- **Questions grammar** (global instructions, "Running questions document"): the heading `### Q-NNN · slug`, then the Needs/Opened/Status line, the question, Why/Read, an options table, `Blocks:` (left out when nothing waits), Interim, and If the answer differs.
- **Digest output.** Numbered `## N.` sections, list lines starting `- `, and repo text quoted with `> `. The skill's step 0 maps the sections to steps.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `docs/dev-cycle.md` (replaces `docs/dev-cycle-sources.md`) | settings file | `docs/roadmap.md`, `docs/working/idea-log.md`, `docs/dev-cycle-sources.md` | `docs/*.md`, `skills/dev-cycle/SKILL.md:41-45` | Consistent (named after the skill). Its self-description "settings" collides with the stop-condition term (F2) |
| `Build-loop policy: <value>` | config line | `Model: <id>`, `Status: open`, `**Needs:** …` | `skills/dev-cycle/SKILL.md:207,220` | Consistent with the skill's plain `Key: value` lines. The skill itself never states the key (F5) |
| `autonomous` / `review` | config enum | "autonomous build loops", the `/away` "Do autonomously" list, the review-fix loop | `skills/dev-cycle/SKILL.md:14,245`, global `Operating Modes` | `autonomous` also names every 6b loop (F3) |
| `(interim; Q-103)` | config marker | the skill's `(interim)`, questions' `**Interim:**` | `skills/dev-cycle/SKILL.md:44`, `docs/working/questions.md` | Inconsistent with the token the skill names (F1) |
| `## Idea sources` (columns Source / Path or glob / Format) | settings section | old `dev-cycle-sources.md` table (with Done when) | `git show c079e8c:docs/dev-cycle-sources.md` | Consistent. Dropping the column is deliberate (seed log fixed) |
| `Status: open` / `Status: closed` (brief) | doc field | `**Status:** OPEN` / `ANSWERED`, `**Status:** Accepted` | `docs/working/questions.md`, `docs/decisions/0*.md` | Diverges in casing and bold (F8, informational) |
| `Revised by #68 (2026-10-01).` | log marker | `Superseded in part by row 49`, `Amended 2026-09-28 (Q-082):`, `#18`/`#19` refs | `docs/decisions/log.md` | Consistent: `#NN` is an established in-log reference form |
| `Q-103 · dev-cycle-build-loop-policy` | question entry | Q-084, Q-075, Q-102 | `docs/working/questions.md` | Consistent with the grammar (no `Blocks:`, which the grammar allows; see F6) |
| Roadmap heading match (exact, or followed by ` ` or `(`, any case) | digest parse rule | section 2's `^## Revisit triggers` prefix match; questions `### Q-NNN` | `scripts/dev-cycle.sh:150,215,261` | Consistent between sections 5 and 7. Not documented in the skill's template (F10) |
| Seed shape `- <idea> (signal: …)` (regex `^- [^ ].*\(signal: .*\)[[:space:]]*$`) | log line grammar | the skill's seed shape | `skills/dev-cycle/SKILL.md:47-50`, `scripts/dev-cycle.sh:274` | Consistent. In the probe, `- foo (signal: bar)` counts, while `- baz` and `- (signal: x)` do not |
| `[line cut at 4096 bytes]` | output marker | none (first output marker) | none — searched `scripts/*.sh` for in-band markers | New convention. It qualifies the "in full" claims (F7) |

## Findings

#### F1. The interim marker the skill names is not the one the settings file writes

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:44` · `docs/dev-cycle.md:7` · `docs/working/questions.md` (Q-103 Interim line)
**Move:** 3 (consumer contract)
**Confidence:** High
**Legibility-target:** the cycle agent reading `docs/dev-cycle.md` in the settings check; any future script that greps the marker.

**Evidence:** The skill says "No file, no policy line, or a value marked `(interim)`: use `review`". The file says "Build-loop policy: review (interim; Q-103)". Q-103 says "recorded as `Build-loop policy: review (interim; Q-103)`; the skill treats an interim value as unset". `git grep '(interim'` turns up no other settings marker.

The skill puts the literal token `(interim)` in backticks, which reads as an exact string. The only producer writes `(interim; Q-103)`, and neither onboarding step 13 nor the file's own preamble describes the suffix. A model reader will probably make the match, but a literal check (a future digest line, or a careful agent) fails open: it reads the value as set and never asks. The `; Q-103` part is useful, because it tells the cycle which entry already asks. The skill just does not say so.

**Recommendation:** In the skill, say "a value followed by `(interim` (optionally `; Q-NNN)` naming the entry that asks)". Alternatively, write the marker as `review (interim)` and keep the Q-ID in the preamble.

#### F2. "settings files" in the brief stop conditions now also names `docs/dev-cycle.md`

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:208-209` · `docs/dev-cycle.md:1` · `workflows/codebase-onboarding.md:453`
**Move:** 2 (naming)
**Confidence:** Medium
**Legibility-target:** a 6b build loop deciding whether it hit a stop condition.

Precedent: "settings" = Claude Code `settings*.json` used in `guides/bare-host-hook-wiring.md`, `guides/claude-config-security-checkup.md:8`

**Evidence:** The stop conditions "always include touching enforcement, hook or settings files, adding a dependency". `docs/dev-cycle.md` is titled "# Dev-cycle settings", and onboarding calls it "(the skill's settings file; …)".

Everywhere else in the repo, "settings files" means Claude Code's `settings*.json`, which is what the stop condition guards. The new file describes itself with the same word. A brief whose acceptance criteria touch `docs/dev-cycle.md` (adding an idea source, say) now meets an ambiguous stop condition. Depending on the loop, it either stops needlessly or learns that "settings" is open to interpretation.

**Recommendation:** Write the stop condition as "Claude Code settings (`settings*.json`)". Alternatively, call `docs/dev-cycle.md` the dev-cycle "config" or "project file" in its title and in onboarding.

#### F3. `autonomous` is both a policy value and the adjective for every build loop

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:14,42,245-254` · `docs/working/questions.md` (Q-103 question) · `docs/decisions/log.md` row 68
**Move:** 2 (naming)
**Confidence:** Medium
**Legibility-target:** the user answering Q-103; a reader of 6b.

Precedent: "autonomous build loops" for all 6b loops used in `skills/dev-cycle/SKILL.md:14`, `skills/dev-cycle/SKILL.md:245` ("start an autonomous build loop (`research-plan-implement`)")

**Evidence:** Q-103 asks "May the dev cycle's autonomous build loops (step 6b) merge their own branches …, or must each stop for your review?". Its options are `[1] review` and `[2] autonomous`. In the skill, the 6b intro reads "start an autonomous build loop", followed by "- **`autonomous`**: …" and "- **`review`**: …".

Under the `review` policy the loop is still called "autonomous", so "the autonomous loop under the review policy" is a legitimate but confusing phrase. The global Operating Modes also use "autonomously" for `/away`, a third meaning. The values describe who merges, so names on that axis read unambiguously.

**Recommendation:** Rename the values to the merge axis, for example `self-merge` / `review` (or `merge` / `review`), and update the skill, the file, onboarding step 13, Q-103 and row 68 together. Since Q-103 is still open, this is the cheapest moment to do it.

#### F4. Onboarding step 13 and row 68 describe `review` as "PR review"; the skill, the file and Q-103 allow a merge entry

**Severity:** Minor
**Location:** `workflows/codebase-onboarding.md:453` · `docs/decisions/log.md` row 68
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** the user answering the onboarding question in a project without PRs (such as this one).

**Evidence:** Onboarding reads "or must each stop for a separate PR review (`review`)?". Row 68 reads "whether a loop merges on its own or stops for a separate PR review is a per-project build-loop policy". The skill, at 252-254, reads "stops without merging: it opens a PR where the project uses them, otherwise it files one `you: judgment` entry, "merge <branch>?"". `docs/dev-cycle.md` reads "(a PR, or one `you: judgment` "merge <branch>?" entry where the project has no PRs)".

The question asked at onboarding, which is where the value gets chosen, implies PRs. In a repo with no PRs (this one, per Q-103's "(no PRs here)"), the user is choosing an option phrased in terms of something the project lacks.

**Recommendation:** In both places, say "stop for a separate review (a PR, or a merge question where the project has no PRs)".

#### F5. Onboarding says to create `docs/dev-cycle.md` "from the skill's description", but the skill defines no format

**Severity:** Minor
**Location:** `workflows/codebase-onboarding.md:453` · `skills/dev-cycle/SKILL.md:41-45`
**Move:** 3 (consumer contract)
**Confidence:** High
**Legibility-target:** an onboarding agent in another project creating the file.

**Evidence:** Onboarding: "Record it as `Build-loop policy: <value>` in `docs/dev-cycle.md` (the skill's settings file; create it from the skill's description if missing)". The skill says only: "`docs/dev-cycle.md` holds this repo's dev-cycle settings: the **build-loop policy** (`autonomous` or `review`, used by 6b), … and the **idea sources** step 5 reads, kept by hand."

The skill is the file's consumer. It names neither the `Build-loop policy:` key nor the `## Idea sources` heading and its table, and it has no template, unlike `docs/roadmap.md` at step 6. Onboarding supplies only the key, and the only full instance is this repo's file. Another project's onboarding agent would invent the idea-sources shape. The settings check ("no policy line") also depends on a key the skill never states.

**Recommendation:** Add a short template block to the skill's Project settings paragraph (title, the `Build-loop policy:` line, `## Idea sources` with its three columns), the same way step 6 carries the roadmap template. Onboarding can then point to it.

#### F6. The skill's "every `you: judgment` entry names the roadmap item it blocks" conflicts with the settings ask it mandates

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:31-33` vs `:44-45` · Q-103
**Move:** 3 (internal contract)
**Confidence:** Medium
**Legibility-target:** the cycle agent filing the settings ask.

**Evidence:** Rule 3 says "only real choices become `you: judgment` entries … and every such entry names the roadmap item it blocks". The settings paragraph says "unless an open `you: judgment` entry already asks for it, file one asking the user to set it". Q-103 has no `Blocks:` line and names no roadmap item. The global grammar says "**Blocks:** … — omit if nothing is".

A policy ask blocks no roadmap item, because the interim `review` lets the work proceed. So the skill's own mandated entry cannot satisfy its own rule, and Q-103 (correctly, per the grammar) leaves the line out.

**Recommendation:** Change rule 3 to "names the roadmap item it blocks, if any". Alternatively, exempt the settings ask explicitly.

#### F7. "Every trigger, in full" is now qualified by the 4096-byte cut, and neither the skill nor the digest says so

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:16,148` · `skills/dev-cycle/SKILL.md:106`
**Move:** 3 (documentation drift after a behavior change)
**Confidence:** High
**Legibility-target:** the cycle agent judging step 2 verdicts.

**Evidence:** The script says "# Every revisit trigger is printed in full every run; nothing carries forward." and `echo "Every trigger, in full. …"`. The skill says "The digest prints every trigger in full." The scrub (47c9a8e) says: "and cuts lines longer than 4096 input bytes". In the probe, a decision record with a 5000-byte `Revisit if …` line printed `…xxx [line cut at 4096 bytes]`, with the trailing ` END` lost.

The in-band marker makes the cut visible, which is good. But the two "in full" promises are now false for long lines, and step 2 gives no instruction to read the source when it sees the marker. No current trigger comes close: the longest digest line on this repo is 2075 bytes, though log row 44 is 6708 bytes. That makes this latent rather than live.

**Recommendation:** Add "(a line over 4096 bytes is cut and marked; read the source for the rest)" to the header comment, the section 2 lead and step 2.

#### F8. The brief `Status:` field breaks with both existing Status conventions

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:97,191-194,207`
**Move:** 2 (naming)
**Confidence:** Medium
**Legibility-target:** a build loop or a human editing a brief.

Precedent: `**Status:** OPEN` / `ANSWERED` used in `docs/working/questions.md`; `**Status:** Accepted` used in `docs/decisions/0*.md`

**Evidence:** The skill uses "`Status: open`" and "its brief `Status: closed`".

Only the cycle agent reads the field, and it reads leniently, so a brief written in the questions style (`**Status:** OPEN`) would still probably match. Rated informational because the skill states the literal once and uses it consistently. It is a third Status casing in the repo.

**Recommendation:** Either keep the form and leave it, or use `**Status:** OPEN` / `CLOSED` to match the questions doc that sits next to the briefs in `docs/working/`.

#### F9. (Outside these rounds) Step 4b's decision trigger never sees decision-log rows

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:247` · `skills/dev-cycle/SKILL.md:144` · `docs/decisions/log.md` row 68
**Move:** 3 (consumer contract)
**Confidence:** High
**Legibility-target:** the cycle agent deciding 4b.

**Evidence:** The digest's records regex is `'^"?docs/decisions/[0-9]{3}-[^/]*\.md"?$'`. The skill's trigger is "a decision record added or changed that is a major design decision". Row 68 says "when a skill, the model or a major decision changes". In probe 1 (clone at ed0d372, `--since=2026-09-30`), rows 67 and 68 had changed in the window, yet section 7 printed "Decision records added or changed … in the window …: 0".

This repo records major decisions such as rows 64–68 as log rows, and the digest's input list cannot show them. The skill's wording ("decision record") is consistent with the digest. Row 68's broader "a major decision" is not. This predates these rounds (the same 4b text is at c079e8c), so it is not a regression.

**Recommendation:** Either list `docs/decisions/log.md` row changes in section 7 (for example, "log.md changed: yes/no"), or narrow row 68 to "a major decision record".

#### F10. Roadmap heading tolerance is a digest-side rule with no counterpart in the skill's template

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:215,261` · `skills/dev-cycle/SKILL.md:182-186`
**Move:** 7 (asymmetry: writer vs reader)
**Confidence:** High
**Legibility-target:** a user hand-editing `docs/roadmap.md`.

**Evidence:** Section 5's match is `t == "## next" || index(t, "## next ") == 1 || index(t, "## next(") == 1`. In probe 2, `## NEXT` and `## Next steps` both opened Next (the second heading continued the section rather than closing it, so section 7 counted 2 Next items), and `## Nextgen` did not.

The writer (the skill's template) uses exact headings. The reader accepts case variants and `" "`/`"("` suffixes, and it merges two matching headings into one section. The behavior is reasonable, but nobody who edits the roadmap can see it.

**Recommendation:** Below the template, add one line: "The digest matches these headings in any case, optionally followed by a space or `(`; keep each heading unique."

#### F11. Global row 12's summary leaves out watched questions

**Severity:** Informational
**Location:** `global-instructions/CLAUDE.md:32`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** a session choosing the workflow.

**Evidence:** "The outer loop over rows 6/9: health and cleanup, every revisit trigger, claim spot-check, conditional deep-audit check and brainstorm, roadmap (`docs/roadmap.md`), then hands ready items to autonomous build loops." Step 3 (watched questions) is missing. The triggers match the skill's description word for word.

**Recommendation:** Add "watched questions" after "every revisit trigger", or leave it as is, since the row is a router summary.

## What Looks Good

- **Heading matching is now the same in both digest sections** (5 and 7). Both use one exact-or-suffix rule, and `## Nextgen` no longer reopens Next (probe 2). The `In flight` and `Now` lookups share the code path through `-v h=`.
- **The seed contract matches on both sides.** The skill's shape `- <idea> (signal: <what prompted it>)` and the digest's regex agree, the comment at `scripts/dev-cycle.sh:269-271` says that only lines of that shape count, and the probe confirms that a line with no idea or no signal is not counted.
- **The In flight lifecycle now partitions cleanly.** The states are merged → Done; waiting on the merge decision → stays; stopped, or idle while still building → Now. The waiting state is excluded from the idle rule, so R1's double handoff cannot recur. Brief `Status: open` and the step 1 skip rule agree, and the handoff queue's "no open `you: judgment` names them" keeps a stalled item from being re-queued while its stop-condition entry is open.
- **Q-103 follows the entry grammar exactly:** slug heading, route, options table with all four columns, Interim, and If the answer differs. Its Read links resolve to step 6b, `docs/dev-cycle.md` and row 68. The interim it records is the default the skill and onboarding both state.
- **Row 67's revision marker** uses the log's own `#NN` reference form. The digest's `Revisit[^|]*` extraction is not tripped by "Revised", and both rows' Revisit clauses still print.
- **Row 68 now matches the skill's step 5 list** (0–1 Now items ready, 10+ seeds, a week or none recorded, reopened direction, asked), its "scoped deep-audit task", and "at most 3 In flight". The guide row's step count ("steps 0–7, with step 4b and the 6b handoff added and steps 4b and 5 conditional") and its checkpoint clause match the skill's "this skill's own gate".
- **Onboarding step 13** places the question in the Gate step with a matching Done-when checkbox, and both `docs/dev-cycle.md` and the skill name "step 13" correctly.
- The `docs/dev-cycle-sources.md` → `docs/dev-cycle.md` rename has no stale references in skills, workflows, guides or global instructions.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| F1 | Skill's `(interim)` vs file's `(interim; Q-103)` | Minor | `skills/dev-cycle/SKILL.md:44`, `docs/dev-cycle.md:7` | High |
| F2 | "settings files" stop condition vs `docs/dev-cycle.md` "settings" | Minor | `skills/dev-cycle/SKILL.md:209` | Medium |
| F3 | `autonomous` policy value vs "autonomous build loops" | Minor | `skills/dev-cycle/SKILL.md:14,245`; Q-103 | Medium |
| F4 | "PR review" in onboarding and row 68 vs PR-or-merge-entry | Minor | `workflows/codebase-onboarding.md:453`; log row 68 | High |
| F5 | Skill defines no `docs/dev-cycle.md` format that onboarding can create it from | Minor | `workflows/codebase-onboarding.md:453`; `skills/dev-cycle/SKILL.md:41-45` | High |
| F6 | "every judgment entry names the roadmap item it blocks" vs the settings ask | Minor | `skills/dev-cycle/SKILL.md:31-33,44-45` | Medium |
| F7 | "in full" vs the 4096-byte cut | Minor | `scripts/dev-cycle.sh:16,148`; `skills/dev-cycle/SKILL.md:106` | High |
| F8 | Brief `Status: open` casing vs repo Status forms | Informational | `skills/dev-cycle/SKILL.md:97,207` | Medium |
| F9 | 4b never sees log rows (pre-existing) | Informational | `scripts/dev-cycle.sh:247`; log row 68 | High |
| F10 | Heading tolerance undocumented in the template | Informational | `scripts/dev-cycle.sh:215,261` | High |
| F11 | Row 12 omits watched questions | Informational | `global-instructions/CLAUDE.md:32` | High |

## Overall Assessment

The A↔B contract these two rounds changed is consistent where it is mechanical. The seed shape, the roadmap heading rule (identical in sections 5 and 7), the section-to-step map, the In flight lifecycle with brief `Status:` and the step 1 skip, and the Q-103 grammar all agree across script, skill, onboarding, decision rows 67–68, the guide row and global row 12. Probes confirm the digest side. None of the findings is breaking or behavioral. They are wording-level contract gaps in the new per-project settings surface. The interim marker token the skill names differs from the one written (F1). "Settings" and "autonomous" are now overloaded (F2, F3). "PR review" survives in the two places that frame the user's choice (F4). The skill has no template for the file it consumes (F5). Rule 3 conflicts with the settings ask (F6). The digest's "in full" promise is unqualified after the cut (F7). All are fixable in place with one-line edits. F3 is cheapest to fix now, while Q-103 is still open.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-01-digest-pass7.md` with the requested first line. It follows the api-consistency-reviewer structure (header, Baseline, Name-Pattern Audit, Findings, What Looks Good, Summary Table, Overall Assessment). Every finding carries Severity, Location, Evidence (verbatim), Confidence and Legibility-target, and naming findings (F2, F3, F8) carry a `Precedent:` line. Scope was the two fix rounds named in the brief, plus the consistency set the role named. F9 is labelled as outside these rounds. Nothing was committed, and scratch stayed under `api7/`.
