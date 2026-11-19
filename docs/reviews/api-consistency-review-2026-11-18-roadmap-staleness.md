Commit: 969e8227

# API Consistency Review — fix/dev-cycle-roadmap-staleness

**Scope:** `git diff main...HEAD` (HEAD 969e8227): `scripts/dev-cycle.sh` section 5, `scripts/lib/migrations.sh`, `skills/dev-cycle/SKILL.md` (steps 0, 3, 6, 8, record template), with `test/scripts/dev-cycle.bats` read as the contract's tests
**Date:** 2026-11-18
**Based on:** `docs/reviews/code-fact-check-report-2026-11-18-roadmap-staleness.md` and `...-pass2.md` (their Incorrect findings are fixed; behaviour they verified is not re-verified here)

The surface under review is a text contract. `scripts/dev-cycle.sh` prints the digest, and `skills/dev-cycle/SKILL.md` reads it section by section, quoting its lines word for word. The record template and the migrations registry are conventions that other repos' files follow. "Consumer" here means the dev-cycle orchestrator reading the digest and the skill, and the owner reading the records.

Probes: (P1) a scratch repo at `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/apicons-probe/repo`, with HOME and git config isolated, running `timeout 60 bash scripts/dev-cycle.sh` in two cases: no `docs/working/questions.md`, and an entry with no `**Needs:**` line. (P2) The digest run read-only in the worktree, with its output in `.../scratchpad/apicons-probe/digest.txt`. (P3) `bash scripts/lib/migrations.sh check`, which exits 0. Every process ran under `timeout` and has exited.

## Baseline Conventions

- **Digest "not checked" lines.** A section that could not read its input says so in one bold-lead shape, followed by the cause: `**Decision log revisit triggers were NOT checked** — …` (`scripts/dev-cycle.sh:366`), `nc="**Watched questions were NOT checked** —"` (`:398`), and `nm="**Migrations were NOT checked** —"` (`:639`). Section 3 keeps an *absent* questions file separate from an *unreadable* one. Absent prints `No docs/working/questions.md in this repo.` (`:401-402`) and is not a "NOT checked" state. The skill gives every "NOT checked" line a handler: step 1b (`SKILL.md:470-473`, "never read as none pending"), step 2 (`:489`) and step 3 (`:515-518`).
- **Digest list lines.** A `- ` bullet with `ITEM: detail` or `ITEM (annotation)` (`:431-433`, `:562`, `:571`, and `- pending ID (CONV): …` at `:660`).
- **Skill quoting the digest.** The skill names digest lines by their literal text in quotes, for example step 3's "Watched questions were NOT checked" (`SKILL.md:515`).
- **Step 6 roadmap bullets.** One bullet per roadmap section, `- **Now**:`, `- **Next**:`, `- **Ideas**:`, `- **Done**:` (bold section name, then a colon), followed by procedure bullets (`- \`docs/working/roadmap-from-questions.md\` …`).
- **Record template lines.** `N. label: <A / B / C>`, where the alternatives sit on one axis separated by ` / ` (for example `1b.`, `4.`, `4b.`, `5.`), and `8.` uses `; ` to join two independent fields (`SKILL.md:851-858`). Elsewhere the skill refers to a line as "the record's `8.` line" (`:784`).
- **Migrations registry.** `mig record-<N>-<slug> record FP - - 'none: the record'"'"'s N. line only gained …; every record written before stays valid'` (`scripts/lib/migrations.sh:162-164`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `Now and Next items were NOT checked against open entries and watches: section 3 did not read them.` | digest status line | `**Watched questions were NOT checked** —`, `**Migrations were NOT checked** —`, `**Decision log revisit triggers were NOT checked** —` | `scripts/dev-cycle.sh:366,398,639` | Inconsistent: no bold lead, and a colon where the siblings use an em dash (Finding 3) |
| `Now and Next items, with the open entries and watches each names (…):` | digest list header | `Open by route: …`, `Its Next section:` | `scripts/dev-cycle.sh:440,461` | Consistent |
| `- SEC N · TITLE: open ID (ROUTE), …` | digest list line | `- ID  ROUTE  slug (annotation)`, `- pending ID (CONV): PATH line N` | `scripts/dev-cycle.sh:431-433,660` | Consistent in shape (` · ` matches the entry-heading separator). The rendered TITLE can end in `.:` (Finding 5) |
| `no open entry or watch names it` | digest literal | (first of its kind) | none, searched `scripts/dev-cycle.sh` | New. The skill quotes it exactly (`SKILL.md:626`), which is good. The record template words the same idea differently (Finding 6) |
| `No items in Now or Next.` | digest empty-state | `None open.`, `None in the window.`, `No merges in the window to sample.` | `scripts/dev-cycle.sh:437,543,455` | Consistent |
| `**Items nothing open holds.**` | skill step-6 bullet title | `**Now**:`, `**Next**:`, `**Ideas**:`, `**Done**:` | `skills/dev-cycle/SKILL.md:609-623` | Minor: a period inside the bold, where siblings use bold then a colon. It also sits among section-name bullets but names a procedure (Finding 6) |
| `6. roadmap: <done; moved to Done or Ideas: ITEMS (why) / none; items no open entry names: each with its hold>` | record template line | `1b. migrations: <none / ran ID / …>`, `8. briefs: <…>; queue <k>/<slots> (<full… / under…>)` | `skills/dev-cycle/SKILL.md:851-858` | Minor: it mixes ` / ` and `; ` so the scope of `/ none` is unclear, and it drops "or watch" (Findings 6, 8) |
| `record-6-roadmap-holds` | migration ID | `record-1b-ran`, `record-8-free-slot`, `record-light-pass` | `scripts/lib/migrations.sh:162-164` | Consistent: same `record-<line>-<slug>` shape, same remedy wording, FP matches `fingerprint` (P3) |
| `open_ok`, `answered`, `items`, `held` | internal shell variables | `open_q`, `open_l`, `watched`, `legacy` | `scripts/dev-cycle.sh:418-440` | Not public. Snake-case lowercase like their neighbours |

## Findings

#### 1. Section 5 reports "NOT checked" in a repo that simply has no questions file

**Severity:** Inconsistent
**Location:** `scripts/dev-cycle.sh:475-477` (with `:385`, `:401-402`)
**Move:** 3 (consumer contract), 4 (error consistency)
**Confidence:** High
**Legibility-target:** dev-cycle orchestrator reading the digest; the owner reading the final message

Evidence (P1, no `docs/working/questions.md`, roadmap Now holding `- **Item A**: waits on Q-010.`):
```
## 3. Watched questions (trigger and deferred routes)

No docs/working/questions.md in this repo.
...
## 5. Roadmap
...
Now and Next items were NOT checked against open entries and watches: section 3 did not read them.
```
Section 3 treats an absent questions file as a normal state. It does not use its `$nc` "NOT checked" prefix, and step 0 has step 1 create the file. Section 5 sets `open_ok=0` at `:385` and changes it only on the `qopen` success path (`:417-418`), so here it reports a failure. With nothing open, the honest answer is that every item is unheld. Every other "NOT checked" line in the digest means "an input could not be read; fix or report it". A consumer that follows that convention will chase a failure that does not exist, and step 6 will skip every item on the very repos that most need it: a new repo that has a roadmap and no questions file yet.

**Recommendation:** When section 3 took the "No docs/working/questions.md" branch, treat the open list as empty and print the list. Every item then shows "no open entry or watch names it". Keep the NOT-checked line for the real failure branches (skipped path, questions.sh missing, `open` failed). Add a bats case next to the archive-removal case at `test/scripts/dev-cycle.bats:1668-1674`.

#### 2. The skill never says what to do with section 5's NOT-checked line

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:624-639` (step 6 "Items nothing open holds")
**Move:** 3 (consumer contract)
**Confidence:** High
**Legibility-target:** dev-cycle orchestrator

Evidence: the new bullet tells the reader only to act "on each item it shows as \"no open entry or watch names it\"". Its sibling NOT-checked lines each have a handler, for example step 3: `If the digest prints "Watched questions were NOT checked" (…), fix or report that first … the section was not checked.` (`SKILL.md:515-518`) and step 1b: `**Migrations were NOT checked**: the record and the final message, never read as none pending.` (`:472-473`). When section 5 prints `Now and Next items were NOT checked …`, no item is shown as unheld, so step 6 does nothing and the record's `6.` line has no slot for "not checked". The silent outcome is the one the step-1b rule forbids: "not checked" read as "none".

**Recommendation:** Add one sentence to the bullet, quoting the line. For example: if the digest prints "Now and Next items were NOT checked", the record's `6.` line says `not checked: <section 3's cause>` and the final message names it, never read as no unheld items. Optionally add a `not checked: why` alternative to the `6.` template, as `1b.` has.

#### 3. The new NOT-checked line breaks the digest's NOT-checked shape

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:477`
**Move:** 2 (naming against the grain)
**Confidence:** High
**Legibility-target:** dev-cycle orchestrator (pattern-matching the digest)

Precedent: `**<Thing> were NOT checked** — <cause>` used in `scripts/dev-cycle.sh:366`, `scripts/dev-cycle.sh:398`, `scripts/dev-cycle.sh:639`

Evidence: `echo "Now and Next items were NOT checked against open entries and watches: section 3 did not read them."`. This line has no bold lead and a colon in place of ` — `. The skill refers to these lines as **NOT checked** in bold (`SKILL.md:470`, `:489`). A reader scanning the digest for bold NOT-checked markers will miss this one.

**Recommendation:** Print `**Now and Next items were NOT checked** — section 3 did not read the open entries and watches.`, and update the matching assertion at `test/scripts/dev-cycle.bats:1673`.

#### 4. Done's definition was not widened for the new answer-finished path

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:622-623` vs `:628-629`
**Move:** 7 (asymmetry)
**Confidence:** High
**Legibility-target:** dev-cycle orchestrator writing the roadmap

Evidence: Done is still defined as `items finished since the last cycle, each with the commit \`--check-brief\` printed (agent work done in-cycle: the iteration's branch name)`, while the new bullet sends items `→ Done, with the commit or answer that finished it`. The branch widened Ideas in the same edit ("and parked items, each with the owner answer that parked it…"), but not Done. A Done line that carries an answer ID matches one rule and contradicts the other.

**Recommendation:** Extend the Done bullet: "…or, for an item an owner answer finished, that answer's `Q-NNN`."

#### 5. Digest titles render as `TITLE.:` when the bold span ends with a period

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:488`, `:518-519`
**Move:** 1 (baseline: roadmap Next items in this repo are `N. **Title.** …`)
**Confidence:** High
**Legibility-target:** owner and orchestrator reading the digest

Evidence (P2, this worktree's real roadmap):
```
- Now 2 · Trial week: less friction, less habituation (2026-10-30 to about 2026-11-06).: open Q-262 (trigger)
- Next 1 · A8 post-restructure token measurement.: no open entry or watch names it
```
The bats fixture asserts the same artifact: `"- Next 1 · Ranked one.: open Q-010 (you: judgment)"` (`test/scripts/dev-cycle.bats:1653`). Both the skill's step-6 template and this repo's roadmap put the closing period inside the bold. As a result, most Next lines will carry `.:`, which reads like a typo in a line the skill asks to be read word for word.

**Recommendation:** Strip one trailing `.` from the extracted bold title (`sub(/\.$/, "", title)`) and update the fixture expectation.

#### 6. One concept, three wordings: "nothing open holds" / "no open entry or watch names it" / "items no open entry names"

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:624` (bullet title), `scripts/dev-cycle.sh:519` (digest literal), `skills/dev-cycle/SKILL.md:858` (record `6.` line); also `SKILL.md:790` ("step 6's `6.` line") vs `:633` ("the record's `6.` line")
**Move:** 2 (naming against the grain)
**Confidence:** Medium
**Legibility-target:** owner reading records; orchestrator matching digest text to the record

Precedent: the skill reuses a digest line's literal text when it refers to it, e.g. "Watched questions were NOT checked" in `skills/dev-cycle/SKILL.md:515` against `scripts/dev-cycle.sh:398`; record lines are referred to as "the record's `8.` line" in `skills/dev-cycle/SKILL.md:784`

Evidence: `- **Items nothing open holds.** The digest's section 5 …`; `echo "- $sec $num · $title: no open entry or watch names it"`; `6. roadmap: <… items no open entry names: each with its hold>`. The record wording drops "or watch", so an item held only by a watch looks like it should have been listed. It also leaves out the bullet's second class ("whose only open ID it names in passing"), which the bullet says to act on as well. The bullet title is also the only one in that list with a period inside the bold rather than `**X**:`, and it is a procedure placed among section-definition bullets.

**Recommendation:** Pick the digest's phrase as the canonical one. Make the record slot `items no open entry or watch holds: each with its hold`. Title the bullet in the list's own shape, or move it below the section bullets as a procedure paragraph, as the `roadmap-from-questions.md` bullet is. Use "the record's `6.` line" at `:790`.

#### 7. Light-pass text still says a stale item waits for the day's first iteration

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:362-364` vs `:510-511`, `:625`
**Move:** 3 (documentation drift)
**Confidence:** Medium
**Legibility-target:** dev-cycle orchestrator on a light pass

Evidence: step 0.5 says `What is not a commit on main (a model change, a release, a dated trigger, a stale item) waits for the day's first iteration`. The new text says `Every iteration, a light pass included, reads that list and acts on each item…` and `Every other Now item is checked in step 6, which a light pass runs too.` In context, step 0.5's "stale item" means step 3's stale agent items, which a light pass skips. But the unheld items that step 6 now acts on are stale items too, so the two lines read as a contradiction. The caller's grep found no other stale statement: no other file in `guides/`, `workflows/` or `skills/` describes section 5 as Next-only, or says only agent items are checked.

**Recommendation:** Narrow step 0.5's list to "a stale agent work item (step 3)", or add "(step 6's unheld items excepted)".

#### 8. The `6.` template line mixes alternatives and fields

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:858`
**Move:** 1 (baseline: template line grammar)
**Confidence:** Medium
**Legibility-target:** orchestrator filling the record; owner reading it

Evidence: `6. roadmap: <done; moved to Done or Ideas: ITEMS (why) / none; items no open entry names: each with its hold>`. Siblings put ` / ` alternatives on one axis (`<none / ran ID / pending ID filed Q-NNN / …>`) and use `; ` only between independent fields (`8.`). Here it is unclear whether `/ none` is the alternative to "moved …" or to the whole line, and the last field has no empty form. No parser reads the `6.` line today (fact-check pass 1, claim on `scripts/build-loop.sh:2258-2330`), so this costs readability only. The migration line `record-6-roadmap-holds` is correctly a `none:` remedy.

**Recommendation:** `6. roadmap: done; moved: <ITEMS (why) / none>; unheld: <ITEM: hold, … / none>`. This would change the record fingerprint again, so it needs one more registry line, per `guides/convention-changes.md`.

#### 9. The route annotation inherits section 3's positional parse

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:516`
**Move:** 8 (nullability)
**Confidence:** Medium
**Legibility-target:** orchestrator reading the hold annotation

Evidence (P1, an entry with no `**Needs:**` line): `questions.sh open` prints `Q-010  ask-it            ` (no route column), and section 5 prints `- Now 1 · Item A: open Q-010 (ask-it)`, showing the slug where the route belongs. The item still counts as held, which matches section 3's rule that a malformed entry must not drop out. Section 3 has the same misread (`Open by route: ask-it=1`), so this is not new behaviour. Section 3 flags the entry `(malformed route: …)`, but section 5 does not.

**Recommendation:** Optional: reuse section 3's `m` classification and print `(malformed route)` instead of the parsed value.

## What Looks Good

- The migration line `record-6-roadmap-holds` matches its siblings exactly: ID shape, `- -` PATH/ERE, the `none: the record's N. line only gained …; every record written before stays valid` remedy, and an FP equal to `fingerprint`'s output (`check` exits 0). The Ideas wording change lives in prose outside the roadmap template's code fence, so it correctly needs no roadmap registry line.
- Section 5's item boundary (column-0 `- `/`* `/`N. `, first `## Now`/`## Next` only, CR-stripped) is the same rule section 7 uses to count items (`scripts/dev-cycle.sh:569-570`), so the two sections agree on what an item is.
- The `answered` filter reads Status the way `questions.sh` does, so section 5 and the archive step agree on which entries are live.
- Step 0's section map (`5 roadmap (steps 6 and 8)`), step 3's handoff sentence, and step 8's "holds come from the digest's section 5 list … never from the last record's `8.` line" are updated together. Step 8's owner-call rule and the Rules' "Attention is the budget" are cited, not restated.
- The skill quotes the digest's literal `no open entry or watch names it`, so a consumer can match the text exactly.
- The empty state `No items in Now or Next.` and the list header follow the digest's existing tone.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | "NOT checked" printed when the repo has no questions file | Inconsistent | `scripts/dev-cycle.sh:475-477` | High |
| 2 | No skill handler for section 5's NOT-checked line | Inconsistent | `skills/dev-cycle/SKILL.md:624-639` | High |
| 3 | NOT-checked line lacks the bold-lead/em-dash shape | Minor | `scripts/dev-cycle.sh:477` | High |
| 4 | Done definition not widened for answer-finished items | Minor | `skills/dev-cycle/SKILL.md:622-623` | High |
| 5 | Titles render `TITLE.:` | Minor | `scripts/dev-cycle.sh:488` | High |
| 6 | Three wordings for "unheld item"; bullet title shape | Minor | `SKILL.md:624,858`, `dev-cycle.sh:519` | Medium |
| 7 | Step 0.5's "stale item waits" reads against step 6 | Informational | `SKILL.md:362-364` | Medium |
| 8 | `6.` template mixes alternatives and fields | Informational | `SKILL.md:858` | Medium |
| 9 | Route annotation shows the slug for a malformed entry | Informational | `scripts/dev-cycle.sh:516` | Medium |

## Overall Assessment

The change mostly follows existing conventions. The migration line, the item boundary, the section map and step 8's hold-source rule all fit. Nothing breaks existing consumers: records written before stay valid and no parser reads the `6.` line. The two Inconsistent findings concern the new failure state. Section 5 reports "NOT checked" in a repo that has no questions file yet, which section 3 treats as normal (1), and the skill gives that line no handler, so a "not checked" result turns silently into "nothing to do" (2). Both are small fixes in place, and each fits in one bats case. The rest are wording and shape fixes: the `.:` title artifact, the Done definition, and settling on one phrase for "unheld item" across the digest, the skill and the record.

## Goal-Alignment Note
- Success criterion (restated verbatim): "a markdown report saved to /workspace/.claude/wt-roadmap-staleness/docs/reviews/api-consistency-review-2026-11-18-roadmap-staleness.md, structured per the api-consistency-reviewer skill, with `Commit: 969e8227` as its first line."
- Answered: consistency of section 5's new lines with the digest's other sections (NOT-checked shape, list shape, empty state); the skill's new text against its vocabulary (Now/Next/Ideas/Done, hold, step numbering, step 8's owner-call rule, "Attention is the budget"); the record template `6.` line against its siblings; the migrations line against its siblings (with `check` run); a repo-wide grep (skills/, guides/, workflows/, scripts/) for stale statements that section 5 shows only Next or that only agent items are checked. The only near-stale statement found is step 0.5's light-pass sentence (Finding 7).
- Out of scope: security of the new awk/shell parsing, performance, re-verifying behaviour the two fact-check passes already verified, and the plan/research/fact-check docs themselves.
- Escalate: none. Findings 1 and 2 are mechanical fixes for the branch's own review-fix loop. If Finding 8's template reshape is taken, it needs one more `record` registry line.
