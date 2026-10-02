Commit: b88a9c4 (A) / 79b1bfe (B)

# API Consistency Review: dev-cycle loop pass 10 (k=1 delta, digest + skill/docs)

**Scope:** A: `git diff d503a43..b88a9c4 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree `wt-digest`). B: `git diff 1ae9b21..79b1bfe` over the skill, `docs/dev-cycle.md`, roadmap, log row 68, Q-103, global row 12, guide row, onboarding step 13, and the seed doc (worktree `wt-devcycle`). Partial scope: everything else on both branches is context only.
**Date:** 2026-10-01
**Based on:** `docs/reviews/code-fact-check-report-digest-pass9.md` (Stage-1 context, loop pass 9). Bats run at b88a9c4: 20/20 ok (`timeout 300 bats test/scripts/dev-cycle.bats`, cwd `/workspace/.claude/wt-digest`). Probes ran in `mktemp -d` repos under the scratchpad `api10/` directory.

The consumers of this surface are the agent that runs the skill, which reads the digest's printed text, and the user, who reads Q-103, the roadmap and the onboarding question. The "API" here has three parts: the digest's section headings and fixed message strings, which the skill maps by section number; the skill's step and section names; and the cross-document descriptions of the build-loop policy and the handoff split.

## Baseline Conventions

- **Digest sections** are `## N. Title`, and the skill's step 0 maps them by number (`SKILL.md:94-97`). An input the digest has not read gets one fixed sentence in the section that would have used it. Before b88a9c4, every such sentence was an absence message (`No docs/roadmap.md yet`, `No docs/working/questions.md (or questions.sh) in this repo.`, `- No $LOG: ...`, `no cycle record found ...`).
- **Digest helpers** are short lowercase shell functions (`inrepo`, `trig`), and arrays/flags are lowercase (`flagged`, `candidates`). Uppercase is used for configuration-like globals (`ROOT_REAL`, `MAIN`, `SINCE`, `LOG`).
- **Skill step references** use the step number (`step 4b`, `step 6`). At 79b1bfe there is no step 6b.
- **Questions entries** follow the global grammar. Fields are `Why it's yours`, `Read`, an options table, `Blocks`, `Interim`, and `If the answer differs`, plus dated notes such as `Deferred 2026-09-26 behind Q-071:` (Q-067).
- **Cross-document policy text** has one long-form home for the policy's semantics, `docs/dev-cycle.md`, which points to the seed for the authoritative self-merge exclusion list. Other documents summarize it.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `## 8. Skipped inputs` | digest section | `## 7. Inputs for steps 4b and 5`, `## 6. Merges with code but no docs` | `scripts/dev-cycle.sh:221,233,251` | Consistent in shape. The noun differs from the record's `## Skipped paths` (F7) |
| `skipped()` | shell function | `inrepo()`, `trig()` | `scripts/dev-cycle.sh:92,157` | Consistent (lowercase verb/adjective helper) |
| `SKIPPED` | array | `flagged`, `candidates` (lowercase arrays) | `scripts/dev-cycle.sh:103,237` | Mild deviation. The existing arrays are lowercase, but uppercase matches the script-wide globals `ROOT_REAL`/`MAIN`. Internal only, so no finding |
| `"<path> is reached through a symlink: NOT read (section 8)."` | message | `"No docs/roadmap.md yet — ..."`, `"**questions.sh open failed** — watched questions were NOT checked"` | `scripts/dev-cycle.sh:201,230` | Consistent (uses the capitalised `NOT` convention from the questions.sh failure line) |
| `"- Roadmap: reached through a symlink, NOT read (section 8)"` | message (section 7 bullet) | `"- Roadmap: none yet (...)"`, `"- No $LOG: ..."` | `scripts/dev-cycle.sh:280,299` | Consistent with section 7's bullet style. Sections 3 and 5 use sentence form, which matches their own local style |
| `"None: no input is reached through a symlink."` | message | `"None in the window."`, `"None open."` | `scripts/dev-cycle.sh:196,245` | Consistent (`None` + qualifier) |
| `briefs: <...>; <k>/3 open` | record step line | `4b. deep-audit check: <none fired / task filed: trigger>` | `skills/dev-cycle/SKILL.md:243-245` | Consistent |
| `docs/working/seed-build-loop-handoff.md` | doc path | no `seed-*` doc in `docs/working/`; spikes carry an "RPI seed section" | none — searched `git ls-tree 79b1bfe docs/working` | New category. Informational, no finding needed |
| Roadmap item **Build-loop handoff** | roadmap item | **This dev cycle**, `Q-075 — ...` items | `docs/roadmap.md:15-31` | Consistent (bold name, motive, first step) |
| Q-103 field `On either answer:` | questions field | `If the answer differs:` (Q-067, Q-084 and others) | `docs/working/questions.md:79,95,133`; template in `global-instructions/CLAUDE.md` | Inconsistent (F6) |
| Q-103 field `Deferred 2026-10-01:` | questions field | `Deferred 2026-09-26 behind Q-071:` | `docs/working/questions.md:77` | Consistent |

## Findings

#### F1. Symlinked cycle record still reads as absent in the Window line, and the skill turns that into a false "skipped step 7" diagnosis

**Severity:** Inconsistent
**Location:** `scripts/dev-cycle.sh:121-134` (A, b88a9c4); `skills/dev-cycle/SKILL.md:98-101` (B, 79b1bfe)
**Move:** 3 (consumer contract), 8 (nullability: present-but-skipped versus absent)
**Confidence:** High
**Legibility-target:** the agent running step 0, and the cycle record the next cycle reads

Evidence (script, the whole window-source block):
```
  inrepo "$f" || { skipped "$f" || true; continue; }
...
  SINCE="$(date -d "$TODAY - 14 days" +%F)"
  source_note="no cycle record found, so the default of 14 days (the previous cycle, if any, did not write its record)"
```
Evidence (skill step 0): "If the window starts before the last cycle you know ran (or says no cycle record was found when one ran), that cycle skipped step 7: note it in this record and rerun with `--since` set to that cycle's date."

Evidence (commit b88a9c4): "instead of reading as absent ("create it", "no cycle record found", "no brainstorm recorded")".

Probe: in a fresh repo with `docs/working/cycles/cycle-2026-09-20.md` symlinked outside the repo, the digest printed `Window: since 2026-09-17 (from no cycle record found, so the default of 14 days (the previous cycle, if any, did not write its record))`. Section 8 of the same run listed `docs/working/cycles/cycle-2026-09-20.md`. The digest therefore contradicts itself: the header says no record exists and that the previous cycle did not write one, while section 8 says one exists and was skipped. The skill's step 0 reads the header and instructs the agent to record "that cycle skipped step 7", which is false. Of the three absence messages the commit says it replaced, this is the one left unchanged. The pass-9 fact-check (Claim 9) named it explicitly. The bats test asserts only `[[ "$output" != *"from the last cycle record"* ]]`, so it passes while the absence wording remains. Precondition: a committed symlink at a cycle-record path. The `--since` rerun the skill prescribes still gives a correct window, so only the stated reason and the record note are wrong.

**Recommendation:** When the cycle-record loop skipped any file and no record was accepted, use a source note such as "no readable cycle record (N skipped through a symlink, section 8), so the default of 14 days". Add a step-0 clause: a skipped record is not a skipped step 7. Assert the new note in test 6. Alternatively, correct the commit claim.

#### F2. Section 2 prints "No revisit triggers recorded." when every decision record or the log was skipped

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:158-182`
**Move:** 4 (message consistency across equivalent conditions), 8
**Confidence:** High
**Legibility-target:** the agent running step 2

Evidence:
```
  inrepo "$f" || { skipped "$f" || true; continue; }
...
else
  skipped docs/decisions/log.md || true
fi
[[ $found -eq 1 ]] || echo "No revisit triggers recorded."
```
Sections 3, 5 and 7 each print an inline "NOT read (section 8)" note for a skipped input. Section 2 prints nothing for a skipped record or log, and when nothing else was read it states that no triggers are recorded. Probe: with one symlinked `docs/decisions/001-a.md` carrying a `## Revisit triggers` section, section 2 printed `No revisit triggers recorded.` and section 8 listed the file. This is the same skipped-read-as-absent pattern the round set out to remove, in the one section without an inline note. Section 8 does still list the file. Precondition: a committed symlink at a decision record or the log.

**Recommendation:** If any record or the log was skipped, print "N trigger source(s) reached through a symlink: NOT read (section 8)." in section 2, and make the empty-case sentence "No revisit triggers recorded in the files read."

#### F3. The digest still points to "6b", a step the skill no longer has

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:280` (unchanged in A; present at 79b1bfe through the merge)
**Move:** 3 (documentation drift across the A↔B contract)
**Confidence:** High
**Legibility-target:** the agent applying step 5's first brainstorm condition

Precedent: step 5 names the condition "roadmap Now holds 0–1 items ready for a build brief" in `skills/dev-cycle/SKILL.md:179`.

Evidence: `echo "- Roadmap: none yet (0 items ready for 6b)"`. At 79b1bfe the skill has no step 6b: `git show 79b1bfe:skills/dev-cycle/SKILL.md | grep 6b` matches only "4b" lines. Briefs are now written in step 6's "Build briefs" paragraph. This is a leftover of the removed handoff in B's consumer-facing text, which the brief asks reviewers to flag.

**Recommendation:** Change the message to `(0 items ready for a build brief)`, matching step 5's wording.

#### F4. Q-103's Interim still says "the skill" reads the policy and "does not re-ask"

**Severity:** Minor
**Location:** `docs/working/questions.md:59` (79b1bfe)
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** the user answering Q-103

Evidence (Q-103): "- **Interim:** [1] `review`, recorded as `Build-loop policy: review (interim; Q-103)`; the skill counts that line as unset (so `review`) and does not re-ask while this entry is open."

Evidence (skill): "recorded for the build-loop handoff, which this skill does not run yet. This skill does not read it." (`SKILL.md:56-58`).

Evidence (`docs/dev-cycle.md`): "The handoff design counts the setting as made only when ...".

After the split, the skill neither counts nor asks: onboarding step 13 asks, and the future handoff counts. The other B documents were updated to say this, and Q-103's Interim was not.

**Recommendation:** "...; the handoff design counts that line as unset (so `review`), and nothing reads it until the handoff lands."

#### F5. Q-103 option [2] gives a closed, shorter self-merge exclusion list than the design it refers to

**Severity:** Minor
**Location:** `docs/working/questions.md` Q-103 options table, row [2] (79b1bfe); compare `docs/dev-cycle.md:10-13`, `workflows/codebase-onboarding.md:453`, `docs/working/seed-build-loop-handoff.md:32-35`
**Move:** 7 (asymmetry: one concept defined three ways)
**Confidence:** High
**Legibility-target:** the user choosing between [1] and [2]

Evidence:
- Q-103 [2]: "only for work outside skills/, workflows/, scripts/, test/, guides/ and instruction files; anything else still stops for review"
- `docs/dev-cycle.md`: "(skills, workflows, scripts, tests, guides, instruction files and similar; the handoff seed, `docs/working/seed-build-loop-handoff.md`, lists them)"
- Seed design 3: "(hooks, enforcement and harness settings, instruction files, `skills/`, `workflows/`, `scripts/`, `guides/`, `patterns/`, `templates/`, `test/`, `devcontainer-config/`)"

`docs/dev-cycle.md` and onboarding give examples and defer to the seed. Q-103 is phrased as an exhaustive list, and it omits hooks, harness settings, `patterns/`, `templates/` and `devcontainer-config/`. As written, a user picking [2] would expect hook or devcontainer changes to self-merge, which the reviewed design forbids. Q-103 is deferred and nothing reads the setting yet, so this has no effect until the handoff unit lands. That unit re-presents the question anyway ("Becomes `you: judgment` then").

**Recommendation:** Rephrase [2] as "only for work outside what later runs follow unreviewed (skills/, scripts/, hooks/, test/, instruction files and the rest listed in the seed)", or point at the seed's list.

#### F6. Q-103 renames the standard "If the answer differs" field

**Severity:** Informational
**Location:** `docs/working/questions.md:60` (79b1bfe)
**Move:** 2
**Confidence:** Medium
**Legibility-target:** whoever greps or scripts over the questions doc

Precedent: `- **If the answer differs:**` used in `docs/working/questions.md:79,95,133` and in the entry template in `global-instructions/CLAUDE.md` ("Running questions document").

Evidence: "- **On either answer:** in `docs/dev-cycle.md`, replace the policy line with `Build-loop policy: review` ([1]) or `Build-loop policy: self-merge` ([2]) and delete the paragraph starting "Interim note:"."

The new name is accurate, since both answers require an edit. It still departs from the template's field name, and the health check passed, so `questions.sh check` does not enforce the field. Severity would be Minor for a naming deviation with precedent. It is Informational here because the content is a correct superset of what the template asks for.

**Recommendation:** Keep the template field: "- **If the answer differs:** either answer edits `docs/dev-cycle.md`: ...".

#### F7. Section 8's names: "Skipped inputs" versus the record's "Skipped paths"; "absent from the sections above" versus the inline notes; newline-split names

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:302-308`; `skills/dev-cycle/SKILL.md:65-66,96-97,246`
**Move:** 2, 7
**Confidence:** High (newline-split behavior executed); Medium (wording)
**Legibility-target:** the agent copying section 8 into `## Skipped paths`

Precedent: `## Skipped paths` used in `skills/dev-cycle/SKILL.md:65,246` (it predates section 8).

Evidence: `printf '\n%s\n\n' "## 8. Skipped inputs"`, then `echo "Reached through a symlink, so not read. Absent from the sections above, not missing from the repo:"`, then `printf '%s\n' "${SKIPPED[@]}" | sort -u | while IFS= read -r f; do echo "- ${f//$'\n'/ }"; done`.

1. Step 0 maps section 8 explicitly to `## Skipped paths`, so the different nouns cost little.
2. "Absent from the sections above" contradicts sections 3, 5 and 7, which now name the skipped file inline. "Not read in the sections above" would be accurate.
3. The `${f//$'\n'/ }` replacement does nothing, because `read` has already split at the newline. Probe: a symlinked `docs/decisions/009-a<LF>b.md` printed two bullets, `- b.md` and `- docs/decisions/009-a`, separated and reordered by `sort`. Line 165 handles the same case correctly for records that are read. Precondition: a decision-record file name containing a newline.
4. `skipped()` tests `-e || -L`, so a non-regular input (for example a directory at `docs/roadmap.md`) is also reported as "reached through a symlink". Probe: `mkdir docs/roadmap.md` printed `docs/roadmap.md is reached through a symlink: NOT read (section 8).` The conclusion "NOT read" is correct, but the stated reason is wrong.

**Recommendation:** Sort with `-z` (or replace newlines before sorting). Say "not a plain file (a symlink, or not a regular file)", or test `-L` on the path components before blaming a symlink. Optionally rename the section to `## 8. Skipped paths`.

#### F8. Step 2's cut wording lags the digest's new wording

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:127` (79b1bfe) versus `scripts/dev-cycle.sh:16,155` (b88a9c4)
**Move:** 2 (same concept, two phrasings across A↔B)
**Confidence:** High
**Legibility-target:** the agent reading step 2 alongside the digest

Precedent: "an output line over 4096 bytes is cut" used in `scripts/dev-cycle.sh:16,155` (b88a9c4).

Evidence: the skill reads "The digest prints every trigger in full (a printed line over 4096 bytes is cut; read the record itself then)." The digest reads "Every trigger, in full (an output line over 4096 bytes is cut: read the record itself then)." b88a9c4 changed the wording to name what is counted (Claims 6 and 12). The skill quotes the old form, so the two sides now describe the same rule in different words.

**Recommendation:** Change the skill to "an output line".

## Rules checked and found correct and complete

- **Every read site has a skip path (A).** All six input kinds (cycle-record glob, decision records, log, questions, roadmap, idea log) call `skipped` on failure, and each kind lands in section 8. Roadmap is appended twice (sections 5 and 7) and printed once through `sort -u`; this was verified by probe. A plain input is never listed, because `skipped` requires `! inrepo`. An unmatched glob literal is not listed either, because `-e`/`-L` are both false. The exceptions are F1 and F2, which add no inline note.
- **questions.md with questions.sh missing (A).** The `inrepo && -f QS` → `elif skipped` → `else` ordering still prints the absence message, because `skipped` returns 1 for a readable file. This is correct.
- **Step 0's section map (B)** names all eight sections, and section 8 maps to `## Skipped paths`. The digest-failure rule (stop on "a missing section") covers the new section, which is fail-safe against a stale installed copy.
- **Brief cap and lifecycle (B).** "fewer than 3 briefs are open, counting earlier cycles'" (step 6), "(at most 3 open)" (row 68), `<k>/3 open` (record), "each open build brief by path" (final message), and "In flight: items with an open build brief" agree. Step 1's "Skip any branch or worktree a brief ... with `Status: open` names" matches the brief format, which includes `branch`. No marker commit, self-merge, Paths, or policy read remains in the skill. The only handoff residues in B are F3 and F4.
- **Cross-document split (B).** Global row 12 ("then writes build briefs for its top items"), the skill description, row 68, the guide row ("no human checkpoint mid-run beyond the Operating Modes approvals", which is correct now that the step-6 queue confirmation is gone), onboarding step 13 ("a planned unit; the skill writes build briefs today"), `docs/dev-cycle.md` ("Read by the build-loop handoff ... not by the dev-cycle skill itself") and the roadmap item agree on the split.
- **Seed doc as a record (B).** Both fenced blocks are exact contiguous substrings of `git show 8b3a8ad:skills/dev-cycle/SKILL.md`, checked with a python `in` test (3207 and 1940 chars, both True). The doc labels them as 8b3a8ad text, unreviewed after its last fix. It is accurate as a record.

## What Looks Good

- Inline notes use one sentence pattern (`<path> is reached through a symlink: NOT read (section 8).`) in sentence-form sections and one bullet pattern in section 7. Both point to section 8.
- Section 8 always prints, with a `None:` line when empty, so step 0's "missing section" failure rule stays a reliable completeness check.
- The `skipped` helper sits next to `inrepo` and reuses it, so the meaning of "skipped" cannot drift from the read gate.
- B's split is done consistently in all seven documents, apart from Q-103's Interim line.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Symlinked cycle record reads as absent in the Window line; step 0 diagnoses "skipped step 7"; commit claims it was fixed | Inconsistent | `scripts/dev-cycle.sh:121-134`; `SKILL.md:98-101` | High |
| 2 | Section 2 prints "No revisit triggers recorded." when records/log were skipped, with no inline note | Minor | `scripts/dev-cycle.sh:158-182` | High |
| 3 | Digest still says "0 items ready for 6b"; the skill has no step 6b | Minor | `scripts/dev-cycle.sh:280` | High |
| 4 | Q-103 Interim says "the skill counts ... does not re-ask"; the skill no longer reads the policy | Minor | `docs/working/questions.md:59` | High |
| 5 | Q-103 [2] exclusion list is closed and shorter than the seed's (no hooks, harness settings, patterns/, templates/, devcontainer-config/) | Minor | Q-103 options row [2] | High |
| 6 | `On either answer:` replaces the template's `If the answer differs:` | Informational | `docs/working/questions.md:60` | Medium |
| 7 | Section 8 naming and wording ("inputs" vs "paths", "absent from the sections above"), newline names split, non-regular files called symlinks | Informational | `scripts/dev-cycle.sh:96,302-308` | High / Medium |
| 8 | Skill step 2 says "printed line"; digest now says "output line" | Informational | `SKILL.md:127` | High |

## Overall Assessment

The split in B is consistent overall. The skill, row 68, global row 12, the guide row, onboarding step 13, `docs/dev-cycle.md` and the roadmap all describe a cycle that writes at most three open briefs and hands them to the user, with the policy recorded for a future unit. The remaining handoff residue is two strings: the digest's "6b" (F3) and Q-103's Interim (F4). A's new skipped-input contract is applied at every read site and section 8 is well formed. However, two read sites still report a skipped input as absent: the Window line for cycle records (F1), which the commit message says was fixed and which step 0 turns into a false record note, and section 2 (F2). All findings can be fixed in place with one-line wording changes plus one test assertion. Consumer impact needs a committed symlink at a cycle record or decision record (F1, F2) or a user reading the deferred Q-103 (F4, F5). Nothing breaks an existing consumer.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-01-digest-pass10.md` with the required first line. It follows the skill's structure: header, Baseline Conventions, Name-Pattern Audit, Findings with Precedent lines on the naming findings, What Looks Good, Summary Table and Overall Assessment. Each finding also carries the brief's Evidence and Legibility-target fields. It covers the brief's claims 1 and 2: claim 1 in F1, F2, F7 and the rules section; claim 2 in F3 to F6, F8 and the rules section. Not committed. Scratch files are only under `api10/`. The probe repos were `mktemp -d` dirs there, and every process ran under `timeout` and exited.
