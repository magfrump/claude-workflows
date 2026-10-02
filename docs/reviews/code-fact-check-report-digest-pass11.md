Commit: c034a75 (A) / a218ad8 (B)

# Code Fact-Check Report

**Repository:** claude-workflows. A: `/workspace/.claude/wt-digest` (digest code at c034a75. HEAD was 9e23ea8, review docs only, when this review started; e08d526 (22:33:24) and 5dd5377 (22:34:37) landed during the review and are out of scope. The first bats and probe runs, at 22:31, predate them. The key results were re-run at 22:35:59 against files extracted with `git show c034a75:…`: `fc11/bats-pinned.log`, 21/21, and `fc11/p1pin.2PaG/p1.out`, P1 reproduced). B: `/workspace/.claude/wt-devcycle` (content at a218ad8; HEAD 2a4a171 merges A, and `git diff --stat a218ad8 HEAD -- skills docs/working/questions.md docs/working/seed-build-loop-handoff.md docs/dev-cycle.md` is empty)
**Scope:** Partial, the pass-10 fix round only. A: `git diff b88a9c4..c034a75 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus commit message c034a75. B: `git diff 79b1bfe..a218ad8 -- skills/dev-cycle/SKILL.md docs/working/questions.md docs/working/seed-build-loop-handoff.md` plus commit message a218ad8. Everything else on both branches is context only.
**Checked:** 2026-10-01
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 27
**Summary:** 18 verified, 7 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

Execution logs (scratch, not committed), all under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc11/`: `bats.log`, `shellcheck.log` (empty: no findings), `qcheck.log`, `qcheck-repo.log`, `probe-commands.txt` (what each probe set up) and `probe.AKFG/p1.out`…`p9.out`. Every probe ran under `timeout 30` in a throwaway repo inside a `mktemp -d` directory under fc11; nothing was written to either worktree except this report.

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read. Its entries are measured values quoted from artifact sets that do not contain them (test counts, corpus statistics). The one claim of that class here, "21/21" (Claim 23c), was recounted by execution and holds. Neither Incorrect verdict below is a fabrication (both are behavior mismatches), so the log needs no new entry.

Legibility-target values: **agent** (the model running the skill acts on the text), **maintainer** (someone editing the script or tests), **user** (the human answering Q-103 or reading the digest).

---

## Claim 1: "only for work outside what later runs follow unreviewed (the seed's list: hooks, enforcement and harness config, instruction files, skills/, workflows/, scripts/, guides/, patterns/, templates/, test/, devcontainer-config/)"

**Location:** `docs/working/questions.md:57`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** user
**Scope:** Covers that Q-103 option [2]'s list matches, item for item, the seed's rule 3; does not establish that the list is complete for this repo (no inventory of hook or harness files was made), or anything about the handoff unit that does not exist yet.

The seed's rule reads: `Self-merge only for work outside what later runs follow unreviewed (hooks, enforcement and harness settings, instruction files, \`skills/\`, \`workflows/\`, \`scripts/\`, \`guides/\`, \`patterns/\`, \`templates/\`, \`test/\`, \`devcontainer-config/\`)` (`docs/working/seed-build-loop-handoff.md:33-35`). Every item appears in Q-103's list in the same order. The only difference is "harness config" against the seed's "harness settings", which a reader would take as the same thing. This fixes pass 10's Claim 6, where the list left out hooks, `patterns/`, `templates/` and `devcontainer-config/`.

**Evidence:** `docs/working/questions.md:57`, `docs/working/seed-build-loop-handoff.md:33-36`

---

## Claim 2: "Nothing reads it until the handoff unit lands; its design counts that line as unset, which means `review`."

**Location:** `docs/working/questions.md:59`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** user
**Scope:** Covers that no script, skill step, workflow, hook or test at a218ad8 parses the policy line, and that the seed's exact-line rule sends `review (interim; Q-103)` to `review`; does not establish how the future handoff code will parse it.

`git grep -n "Build-loop policy" a218ad8 -- scripts skills workflows hooks test` finds only the settings template (`skills/dev-cycle/SKILL.md:48`), the skill's note on it (`:56`) and onboarding's instruction to *record* it (`workflows/codebase-onboarding.md:453`). None of them parses the line (paraphrased — no quote available because the claim covers the absence of a reader, shown by the grep). The skill says so itself: `This skill does not read it.` (`skills/dev-cycle/SKILL.md:57-58`). The seed's rule 2: `set only when \`docs/dev-cycle.md\` has exactly one line, outside code blocks, reading exactly \`Build-loop policy: self-merge\` or \`Build-loop policy: review\` (a trailing CR is ignored); anything else is \`review\`` (`docs/working/seed-build-loop-handoff.md:29-31`). The live line is `Build-loop policy: review (interim; Q-103)` (`docs/dev-cycle.md:7`). That is not one of the two exact lines, so it falls under "anything else", which means `review`. This fixes pass 10's Stale Claim 7.

**Evidence:** `docs/working/questions.md:59`, `docs/dev-cycle.md:7,17-19`, `docs/working/seed-build-loop-handoff.md:29-32`, `skills/dev-cycle/SKILL.md:56-58`, `workflows/codebase-onboarding.md:453`

---

## Claim 3: "**If the answer differs:** nothing to redo. Either answer is recorded the same way: in `docs/dev-cycle.md`, replace the policy line … and delete the paragraph starting "Interim note:"."

**Location:** `docs/working/questions.md:60`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers that the field name is the template's, that the paragraph it names exists, and that the entry passes `questions.sh check`; does not establish that "nothing to redo" will still hold once handoff code exists that reads the setting.

The template field is `- **If the answer differs:** <what gets redone>` (`global-instructions/CLAUDE.md:256`). The paragraph to delete exists: `Interim note: the "(interim; Q-103)" on the policy line keeps it unset until Q-103 is answered.` (`docs/dev-cycle.md:21-22`). "Nothing to redo" follows from Claim 2: nothing reads the line today. Execution: `timeout 60 bash scripts/questions.sh check`, cwd `/workspace/.claude/wt-devcycle`, 2026-10-01T22:32:20-07:00, exit 0, output `✓ questions: structure valid, indexes current` (the same with `~/.claude/scripts/questions.sh`).

**Evidence:** `docs/working/questions.md:60`, `docs/dev-cycle.md:21-22`, `global-instructions/CLAUDE.md:256`, `fc11/qcheck-repo.log`, `fc11/qcheck.log`

---

## Claim 4: "Policy: set only when `docs/dev-cycle.md` has exactly one line, outside code blocks, reading exactly `Build-loop policy: self-merge` or `Build-loop policy: review` (a trailing CR is ignored); anything else is `review`."

**Location:** `docs/working/seed-build-loop-handoff.md:29-31`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers that the seed now holds the same rule `docs/dev-cycle.md` attributes to the handoff design; does not establish that any code implements it (none exists yet, by design).

`docs/dev-cycle.md:17-19`: `The handoff design counts the setting as made only when the file has exactly one line, outside code blocks, reading exactly \`Build-loop policy: self-merge\` or \`Build-loop policy: review\` (a trailing CR is ignored). Anything else counts as unset, which means \`review\`.` The seed's rule 2 has every element: exactly one line, outside code blocks, the two exact strings, trailing CR, anything else → `review`. This fixes pass 10's Claim 4.

**Evidence:** `docs/working/seed-build-loop-handoff.md:29-32`, `docs/dev-cycle.md:17-19`

---

## Claim 5: "A directory the digest globs in must be plain too, or the glob would list names from wherever a symlinked directory points."

**Location:** `scripts/dev-cycle.sh:93-95`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers both globs in the script (the cycle records at `:128-136` and the decision records at `:173-176`) for a symlinked leaf directory, a symlinked parent (`docs`) and a regular file at the directory path; does not establish what happens to the fixed-name inputs inside such a directory (Claim 23a) or how section 2 reports the skip (Claim 23b).

```bash
# scripts/dev-cycle.sh:95
plaindir() { local r; [[ -d "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL/$1" ]]; }
```

The two globs are reached only behind it: `if plaindir docs/working/cycles; then for f in docs/working/cycles/cycle-…md; do … done; else skipdir docs/working/cycles || true; fi` (`:128-136`, condensed), and `if plaindir docs/decisions; then decisions_glob=(docs/decisions/[0-9][0-9][0-9]-*.md); else skipdir docs/decisions || true; fi` (`:174`). These are the script's only globs over repo directories (paraphrased — no quote available because the claim covers the absence of other glob sites, checked by reading the whole script). Probes P1 (symlinked `docs/decisions` holding `001-a.md`), P5 (symlinked `docs/working/cycles`) and P9 (`docs` itself a symlink) printed no outside file name: section 8 lists only `- docs/decisions/` and/or `- docs/working/cycles/`. Test 7 asserts the same: `[[ "$output" != *private-plan* && … ]]`. Command `timeout 30 bash $DC`, cwd a throwaway repo, 2026-10-01T22:31:48-07:00, exit 0 for each probe.

**Evidence:** `scripts/dev-cycle.sh:93-95,127-136,173-176`, `fc11/probe-commands.txt`, `fc11/probe.AKFG/p1.out`, `fc11/probe.AKFG/p5.out`, `fc11/probe.AKFG/p9.out`, `fc11/bats.log`

---

## Claim 6: "An input that exists in some form but is not a plain file (reached through a symlink, or not a regular file) is skipped, not absent"

**Location:** `scripts/dev-cycle.sh:96-97`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers `skipped()` for a symlinked file, a dangling symlink and a FIFO, and `skipdir()` for a symlinked directory and a regular file at a directory path; does not establish whether the skip is *reported* at the read site (Claim 7).

```bash
# scripts/dev-cycle.sh:101-102
skipped() { if [[ -e "$1" || -L "$1" ]] && ! inrepo "$1"; then SKIPPED+=("${1//$'\n'/ }"); return 0; fi; return 1; }
skipdir() { if [[ -e "$1" || -L "$1" ]] && ! plaindir "$1"; then SKIPPED+=("$1/"); return 0; fi; return 1; }
```

`inrepo` needs `[[ -f "$1" ]]` and a real path equal to `$ROOT_REAL/$1` (`:92`). Anything present that is not a regular file, or is reached through a link, therefore fails it, and `-e || -L` catches dangling links. Probe P7 (dangling `docs/roadmap.md`, FIFO `docs/working/questions.md`) printed `docs/working/questions.md is not a plain file (reached through a symlink, or not a regular file): NOT read (section 8).`, and section 8 listed both paths. P4 (a regular file at `docs/decisions`) listed `- docs/decisions/`.

**Evidence:** `scripts/dev-cycle.sh:92,96-102`, `fc11/probe.AKFG/p7.out`, `fc11/probe.AKFG/p4.out`

---

## Claim 7: "it is named where it would have been read and listed in section 8"

**Location:** `scripts/dev-cycle.sh:97-98`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the read sites of the glob-fed inputs (section 2's decision records, the Window line's cycle records); does not concern the singleton inputs (questions, roadmap, idea log, decision log), which are named at their read sites (Claim 11).

**Behavioral.** "Listed in section 8" holds for every skip. "Named where it would have been read" fails in three cases, all shown by execution:

1. **A skipped decision directory** gets nothing in section 2. `n_before_triggers` is taken *after* `skipdir docs/decisions` has already appended `docs/decisions/`:

   ```bash
   # scripts/dev-cycle.sh:173-176 (excerpt ends :176; the enclosing loop and the :200-203 message block were read)
   decisions_glob=()
   if plaindir docs/decisions; then decisions_glob=(docs/decisions/[0-9][0-9][0-9]-*.md); else skipdir docs/decisions || true; fi
   n_before_triggers=${#SKIPPED[@]}
   for f in "${decisions_glob[@]}"; do
   ```

   At `:200-202`, `if [[ ${#SKIPPED[@]} -gt $n_before_triggers ]]` is then false unless `log.md` was skipped too. P1 (symlinked `docs/decisions` whose target holds a record with triggers but no `log.md`), P4 (a regular file at `docs/decisions`) and P9 (`docs` symlinked) all print `No revisit triggers recorded.` P2 (a target that also holds `log.md`) prints the "read" message, but only because `log.md` was skipped as well.
2. **Skipped decision records when another record has triggers.** With `found=1` the `:200` block does not run, so section 2 says nothing about the skipped ones (paraphrased — no quote available because the claim covers the absence of a note on the `found=1` path, which the `:200` guard shows).
3. **A newer skipped cycle record next to an older readable one.** P3: `Window: since 2026-02-01 (from the last cycle record, docs/working/cycles/cycle-2026-02-01.md)`, while section 8 lists `docs/working/cycles/cycle-2026-03-01.md`. The window silently falls back to the older record.

Even where a note does fire, it is generic ("decision records or the log were skipped", "one or more were skipped"), not a name (paraphrased — no quote available because this is a comparison of the `:145` and `:201` strings, quoted in Claims 9 and 10). Case 1 is the case this commit was meant to cover. A reader trusting the comment expects section 2 to account for every skipped trigger source, but a symlinked decisions directory looks exactly like a repo with no triggers.

**Evidence:** `scripts/dev-cycle.sh:96-99,137-148,173-203`, `fc11/probe.AKFG/p1.out`, `p2.out`, `p3.out`, `p4.out`, `p9.out`

---

## Claim 8: "A newline in a name becomes a space here, before the name is ever printed."

**Location:** `scripts/dev-cycle.sh:98-99`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers `skipped()`'s replacement (`:101`) and section 8's printing (`:328`), and that every name `skipdir` records is a fixed constant; does not establish handling of other line-breaking characters inside `skipped()` (CR, U+2028/2029), which the scrub removes later (`:47,51`) rather than turning into spaces.

`SKIPPED+=("${1//$'\n'/ }")` (`:101`) runs before anything is printed, and section 8 now prints the array unchanged: `printf '%s\n' "${SKIPPED[@]}" | sort -u | sed 's/^/- /'` (`:328`). `skipdir` is called only with the literals `docs/working/cycles` and `docs/decisions` (`:135,174`). Test 7's second half links `docs/decisions/002-a`$'\n'`- FORGED.md` and asserts `[[ "$skipped" == *"- docs/decisions/002-a - FORGED.md"* ]]` and `[[ "$skipped" != *$'\n'"- - FORGED"* ]]`. It passed: `timeout 300 bats test/scripts/dev-cycle.bats`, cwd `/workspace/.claude/wt-digest`, 2026-10-01T22:31:20-07:00, exit 0, `ok 7`.

**Evidence:** `scripts/dev-cycle.sh:101-102,135,174,328`, `test/scripts/dev-cycle.bats:166-175`, `fc11/bats.log`

---

## Claim 9: "no readable cycle record (one or more were skipped as not plain files: section 8), so the default of 14 days"

**Location:** `scripts/dev-cycle.sh:137-148`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers that this text prints exactly when no readable record was found and at least one record or the cycles directory was skipped, and that it is true when printed; does not establish that the mixed case (a skipped record newer than a readable one) is reported (it is not: Claim 7, case 3), nor that the skipped record would have been used (a skipped future-dated record also triggers it, P6).

```bash
# scripts/dev-cycle.sh:137 and :142-148 (the if/elif at :138-141 read)
records_skipped=${#SKIPPED[@]}
…
else
  SINCE="$(date -d "$TODAY - 14 days" +%F)"
  if [[ $records_skipped -gt 0 ]]; then
    source_note="no readable cycle record (one or more were skipped as not plain files: section 8), so the default of 14 days"
```

`SKIPPED` is empty before `:127` (no earlier call appends to it), so `records_skipped` counts only the cycle-record skips (paraphrased — no quote available because this shows that no earlier code touches `SKIPPED`, from reading `:100-136`). P5 (symlinked cycles dir), P6 (one future-dated symlinked record) and P9 printed the skipped text. Test 6 asserts it for a symlinked record.

**Evidence:** `scripts/dev-cycle.sh:100,127-148`, `fc11/probe.AKFG/p3.out`, `p5.out`, `p6.out`, `p9.out`, `test/scripts/dev-cycle.bats:148`

---

## Claim 10: "No revisit triggers read: decision records or the log were skipped as not plain files (section 8)."

**Location:** `scripts/dev-cycle.sh:200-203`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers that the message is true whenever it prints (`found=0` and a record or `log.md` was skipped after `:175`) and cannot print when a trigger was read; does not establish that it prints for every skip in section 2 (it misses a skipped `docs/decisions/` directory, Claim 7 case 1 and Claim 23b).

```bash
# scripts/dev-cycle.sh:200-203
if [[ $found -eq 0 ]]; then
  if [[ ${#SKIPPED[@]} -gt $n_before_triggers ]]; then echo "No revisit triggers read: decision records or the log were skipped as not plain files (section 8)."
  else echo "No revisit triggers recorded."; fi
fi
```

`found=1` is set only after a trigger section or a log row is printed (`:179,188`), so the message cannot fire when triggers were read. P8 (a plain record without triggers next to a symlinked one) and P2 print it, and both times something was skipped.

**Evidence:** `scripts/dev-cycle.sh:171-203`, `fc11/probe.AKFG/p2.out`, `fc11/probe.AKFG/p8.out`

---

## Claim 11: "is not a plain file (reached through a symlink, or not a regular file): NOT read (section 8)"

**Location:** `scripts/dev-cycle.sh:227,249,299,318`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the four singleton read sites (questions, roadmap twice, idea log) for symlinks, dangling symlinks and FIFOs; does not establish the decision log's site, which has no message of its own and is covered by `:201` only when `found=0`.

Each site is `elif skipped <path>; then echo "<path> is not a plain file (reached through a symlink, or not a regular file): NOT read (section 8)."` (e.g. `:226-227`), following an `inrepo` branch, so it fires on exactly the `skipped()` condition of Claim 6. P7 printed it for a FIFO `questions.md` and a dangling `roadmap.md` (`p7.out` lines 18, 26, 39).

**Evidence:** `scripts/dev-cycle.sh:208,226-227,243,248-249,293,298-299,304,317-318`, `fc11/probe.AKFG/p7.out`

---

## Claim 12: "- Roadmap: none yet (nothing to brief)"

**Location:** `scripts/dev-cycle.sh:301`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers that this branch runs only when `docs/roadmap.md` is absent, so no Now item exists for step 6's build briefs; does not establish anything about step 5's brainstorm threshold beyond that.

The branch is the `else` after `inrepo docs/roadmap.md` and `skipped docs/roadmap.md` (`:293,298,300-301`). Build briefs come only from Now items: `Take the Now items whose first step needs no open choice … write docs/working/handoffs/…` (`skills/dev-cycle/SKILL.md:229-231`). With no roadmap there are none. This fixes pass 10's Stale Claim 16 ("6b").

**Evidence:** `scripts/dev-cycle.sh:293-302`, `skills/dev-cycle/SKILL.md:229-231`

---

## Claim 13: "Not plain files (reached through a symlink, or not regular files), so not read; they exist but their contents are not in the sections above:"

**Location:** `scripts/dev-cycle.sh:323-328`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the section 8 header and its list for file, directory, dangling-link and FIFO skips, plus the empty-case line `None: every input is a plain file.`; does not establish anything about absent inputs, which are correctly not listed.

**Wording.** The header is right for symlinks, dangling links and FIFOs (P7). It is imprecise in one edge case: a regular file at a directory path (P4, `docs/decisions` is a file) is listed as `- docs/decisions/`, so a trailing slash marks it as a directory and the header calls it "not regular files", when it is a regular file in a directory's place (`skipdir`'s `SKIPPED+=("$1/")`, `:102`). A precise version would be "not plain files or directories (reached through a symlink, or the wrong kind of file)". The empty-case line (`:325`) is accurate: it prints only when nothing present was skipped. It no longer says inputs are absent, which fixes pass 10's api F7.

**Evidence:** `scripts/dev-cycle.sh:102,323-328`, `fc11/probe.AKFG/p4.out`, `fc11/probe.AKFG/p7.out`

---

## Claim 14: "and expand a glob only inside a directory that passes the same check. … The digest applies the same rule to everything it reads and lists what it skipped in its section 8."

**Location:** `skills/dev-cycle/SKILL.md:61-67`
**Type:** Architectural / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the comparison between the skill's `test -L`-per-component rule and the digest's `inrepo`/`plaindir`, glob gating included; does not establish the cycle's own compliance at run time (prose-only).

**Wording.** The digest now gates both its globs behind `plaindir` (Claim 5) and lists skips in section 8 (Claim 6), so the glob clause and "lists what it skipped" hold. "The same rule" understates it. The digest also skips anything present that is not a regular file (`[[ -f "$1" ]]`, `scripts/dev-cycle.sh:92`), and its directory check is `-d` plus a realpath match (`:95`), while the skill's rule checks only for symlinks (`check that no part of the path below the repo root is a symlink (\`test -L\` on each component …)`, `:63-64`). A precise version: "The digest applies the same rule, and also skips anything that is not a regular file, …". The difference matters only for an agent that expects a FIFO or a file-in-place-of-a-directory entry in section 8 to be a symlink.

**Evidence:** `skills/dev-cycle/SKILL.md:61-67`, `scripts/dev-cycle.sh:92,95,101-102`

---

## Claim 15: "8 skipped inputs (the record's `## Skipped inputs`)" / record template `## Skipped inputs`

**Location:** `skills/dev-cycle/SKILL.md:97-98`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers that the skill's three mentions (`:66`, `:98`, `:251`) and the digest's section header use one name, and that no live doc still says `## Skipped paths`; does not establish anything about past review reports, which keep the old name as history.

The digest prints `## 8. Skipped inputs` (`scripts/dev-cycle.sh:323`). The skill says `listed in the record under \`## Skipped inputs\`` (`:66`), `8 skipped inputs (the record's \`## Skipped inputs\`)` (`:97-98`), and the template has `## Skipped inputs` (`:251`). `git grep "Skipped paths" a218ad8` hits only `docs/reviews/*pass8*`/`*pass9*` (paraphrased — no quote available because the claim covers the absence of the old name outside review history, shown by the grep).

**Evidence:** `skills/dev-cycle/SKILL.md:66,97-98,251`, `scripts/dev-cycle.sh:323`

---

## Claim 16: "If instead it says the records were skipped (section 8), the record exists but is not a plain file: note that, fix or report the link, and rerun with `--since` the same way."

**Location:** `skills/dev-cycle/SKILL.md:102-103`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the match between this sentence and the digest's Window-line text, and what that text implies; does not establish the step-0 handling of the mixed case, which has no "skipped" text and falls to the sentence before (`:99-102`) only if the agent knows the last cycle ran.

**Wording.** The trigger text matches: the digest prints `no readable cycle record (one or more were skipped as not plain files: section 8)` (`scripts/dev-cycle.sh:145`), so step 0 can now tell a skipped record from a missing one (this fixes pass 10's Claim 20). "The record exists" is not always established, though. The same text prints when the whole `docs/working/cycles/` directory was skipped (P5, P9: section 8 lists only `- docs/working/cycles/`, and no record need exist). It also prints when the only skipped record is future-dated, which would have been ignored anyway (P6, `cycle-2027-01-01.md` against `DEV_CYCLE_TODAY=2026-03-10`). And "fix or report the link" assumes a link, while a FIFO or a regular file at the directory path triggers it too (Claim 6). Precise version: "…one or more records, or the records directory, were skipped (section 8): note that, fix or report it, and rerun with `--since` set to the last cycle's date."

**Evidence:** `skills/dev-cycle/SKILL.md:99-103`, `scripts/dev-cycle.sh:137-148`, `fc11/probe.AKFG/p5.out`, `p6.out`, `p9.out`

---

## Claim 17: "The digest prints every trigger in full (an output line over 4096 bytes is cut; read the record itself then)."

**Location:** `skills/dev-cycle/SKILL.md:129-130`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the wording match with the digest and that the cut is applied per output line by the scrub; does not re-verify the scrub's byte handling (verified in earlier passes, unchanged here).

The digest says `Every trigger, in full (an output line over 4096 bytes is cut: read the record itself then).` (`scripts/dev-cycle.sh:170`). The cut is in the scrub every printed line passes through: `$_ = substr($_, 0, 4096) . " [line cut at 4096 bytes]" if length($_) > 4096;` (`:45`). This fixes pass 10's api F8 / Claim 21.

**Evidence:** `skills/dev-cycle/SKILL.md:129-130`, `scripts/dev-cycle.sh:45,67,170`

---

## Claim 18: "A brief open for 14 days with no commit on its branch gets one `you: judgment` entry, "keep or drop the brief for <item>?" (unless one is already open), so unstarted briefs do not hold the slots for good."

**Location:** `skills/dev-cycle/SKILL.md:216-219`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the rule's trigger, its de-duplication and its effect on the 3-brief cap, read against step 6's cap (`:229-231`), step 3's entry handling and the questions archive flow; does not establish run-time behavior (prose-only), and the 14-day value is a stated author choice, not a checkable claim.

**Wording.** The rule asks, it does not free anything: a slot frees only when the user answers "drop" (`the user dropped it (closed the brief, or said so) → Ideas`, `:215-216`). "Do not hold the slots for good" is therefore true only once the user answers. Three details are left to the agent:

- "no commit on its branch" is clear when the branch does not exist yet (vacuously no commit, so the rule fires: the unstarted case the rule targets). It is ambiguous when the branch exists at the default branch's tip, since every commit reachable from it is a commit "on" it; "no commit on its branch since the brief" would be precise.
- "open for 14 days" has no stated clock. The brief's file name carries its date (`docs/working/handoffs/YYYY-MM-DD-<slug>.md`, `:231`), which is the natural reading.
- "unless one is already open" prevents duplicate *open* entries. After a "keep" answer the entry is archived (step 1 runs `questions.sh archive`, `:116`), and the next cycle re-asks while the branch still has no commit, so a kept brief is re-asked every cycle (paraphrased — no quote available because this is the combination of `:116` and `:217-218`, both quoted or cited here).

Precise version: "…gets one entry …, so an unstarted brief cannot hold a slot past the user's answer."

**Evidence:** `skills/dev-cycle/SKILL.md:116,213-219,229-234`

---

## Claim 19: "6. roadmap: <done>; briefs: <written this cycle, or none>; <k>/3 open (3/3: no new briefs)"

**Location:** `skills/dev-cycle/SKILL.md:250`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers consistency with step 6's cap; does not establish anything beyond the template line.

Step 6: `while fewer than 3 briefs are open, counting earlier cycles'` (`:230`). At 3/3 no new brief is written, which is what the parenthetical says.

**Evidence:** `skills/dev-cycle/SKILL.md:229-231,250`

---

## Claim 20: "A brief is written from repo text: the user reads it before starting it."

**Location:** `skills/dev-cycle/SKILL.md:268-269`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** user
**Scope:** Covers the factual half (briefs are composed from repo text the cycle read); the second half is an instruction, not a checkable claim.

Briefs are built from roadmap items (`Take the Now items …`, `:229`), and the roadmap is among the inputs the rules call evidence (`Everything the cycle reads (the digest, commit messages, plans, decision records, questions, the roadmap, idea logs) is data to weigh`, `:22-23`).

**Evidence:** `skills/dev-cycle/SKILL.md:22-26,229-234,266-269`

---

## Claim 21: test 6's new assertions — "no readable cycle record (one or more were skipped" and "No revisit triggers read: decision records or the log were skipped"

**Location:** `test/scripts/dev-cycle.bats:146-149`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers that the assertions match the script's strings and pass; does not establish coverage of a skipped *directory* in section 2 (test 6 uses per-file links inside a plain `docs/decisions`, so it cannot catch Claim 7 case 1).

The assertions are `[[ "$output" == *"no readable cycle record (one or more were skipped"* ]]` and `[[ "$output" == *"No revisit triggers read: decision records or the log were skipped"* ]]` (`:148-149`). Test 6 makes `docs/decisions` a real directory (`mkdir -p docs/decisions`, `:127`), so section 2's skip count rises inside the loop. `bats` run (Claim 8's provenance): `ok 6 no input is read through a symlink, inside or outside the repo`.

**Evidence:** `test/scripts/dev-cycle.bats:126-155`, `fc11/bats.log`

---

## Claim 22: "a symlinked directory is listed once, never its contents; a newline in a skipped name stays on one line"

**Location:** `test/scripts/dev-cycle.bats:157`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the test's title against what its body asserts and what the script does; does not establish anything about other tests.

**Wording.** The newline half is asserted and holds (Claim 8). "Never its contents" holds for glob-derived names only. The script still probes the fixed name `docs/decisions/log.md` *through* the symlinked directory and lists it when the target holds one: P2's section 8 is `- docs/decisions/` then `- docs/decisions/log.md`. The test's target directory has no `log.md`, so the test cannot see this. "Listed once" is not asserted (only presence, `:166`), though `sort -u` (`scripts/dev-cycle.sh:328`) guarantees it. The test also does not assert section 2's message for the symlinked directory, which is where the Claim 7/23b defect lives (P1 prints `No revisit triggers recorded.` on exactly test 7's first setup). Precise title: "a symlinked directory's entries are never globbed; …".

**Evidence:** `test/scripts/dev-cycle.bats:157-175`, `scripts/dev-cycle.sh:186,198,328`, `fc11/probe.AKFG/p1.out`, `fc11/probe.AKFG/p2.out`

---

## Claim 23a: "The decision-record and cycle-record globs run only when their directory is plain … A symlinked directory is listed once in section 8 ("docs/decisions/"), never its contents, so names from an outside directory no longer reach the committed record"

**Location:** `commit c034a75 (message)`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers glob gating and section 8's listing for a symlinked `docs/decisions` with and without a `log.md` in its target; does not establish the section 2 message (Claim 23b).

**Wording.** Glob-derived names from the outside directory never reach the output (P1, P5, P9, test 7: Claim 5). But a fixed input name inside the symlinked directory is still listed when the target holds that file. P2 lists `- docs/decisions/log.md` under `- docs/decisions/`, because `inrepo docs/decisions/log.md` fails and `skipped` sees `-e` true through the link (`scripts/dev-cycle.sh:186,198,101`). This tells the reader that `log.md` exists in the outside directory, and that name enters the record through `## Skipped inputs`. Precise version: "no name *globbed* from an outside directory reaches the record; fixed input names (`log.md`) are still listed if present."

**Evidence:** `scripts/dev-cycle.sh:101,174,186,198`, `fc11/probe.AKFG/p2.out`

---

## Claim 23b: "the Window line … ; section 2 says "No revisit triggers read" when its inputs were skipped (api F2)"

**Location:** `commit c034a75 (message)`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the section 2 half of the sentence for every way its inputs can be skipped (per-file link, symlinked directory, `docs` symlinked, a file at the directory path, a symlinked log); does not cover the Window-line half, which holds (Claim 23c).

**Behavioral.** When `docs/decisions` itself is skipped, `skipdir` appends `docs/decisions/` *before* `n_before_triggers=${#SKIPPED[@]}` is read (`scripts/dev-cycle.sh:174-175`, quoted in Claim 7). The `:201` comparison then misses it, and section 2 prints `No revisit triggers recorded.` P1 (symlinked dir whose target record has a `## Revisit triggers` section), P4 (regular file at `docs/decisions`) and P9 (`docs` symlinked) all printed that. Only P2, where `log.md` was skipped too, printed the "read" message. Preconditions: a committed symlink (or non-directory) at `docs/decisions` or a parent, with no `log.md` behind it. That is the case this commit introduced `skipdir` for. Consequence: section 2 tells the agent there are no triggers, step 2 records no verdicts, and only section 8 shows that a trigger source was skipped. Fix: take `n_before_triggers` before the `plaindir` line (`:173`), and add a test 7 assertion on section 2.

**Evidence:** `scripts/dev-cycle.sh:173-176,200-203`, `fc11/probe.AKFG/p1.out`, `p2.out`, `p4.out`, `p9.out`

---

## Claim 23c: c034a75's remaining claims — a newline in a skipped name becomes a space; the Window line says "no readable cycle record (… skipped …)" when the only records were skipped; messages say "not a plain file (…)" covering directories and FIFOs; section 8's header no longer claims absence; "(0 items ready for 6b)" → "(nothing to brief)"; "New test 7 …; test 6 asserts the window and section 2 messages. 21/21; shellcheck clean."

**Location:** `commit c034a75 (message)`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers each listed item at c034a75 (via Claims 8, 9, 11, 12, 13, 21) and the test and lint counts; does not cover the section 2 item (Claim 23b) or the "never its contents" item (Claim 23a).

`timeout 300 bats test/scripts/dev-cycle.bats`, cwd `/workspace/.claude/wt-digest`, 2026-10-01T22:31:20-07:00, exit 0, 21 `ok` lines (`grep -c '^ok'` = 21). `timeout 60 shellcheck scripts/dev-cycle.sh`, same cwd and time, exit 0, empty output. The diff (`git diff b88a9c4..c034a75`) contains each listed message change: `:227,249,299,318` (messages), `:301` ("nothing to brief"), `:325-328` (section 8), `:101` (newline), `:144-148` (Window), and test changes at `:146-149,157-175`.

**Evidence:** `scripts/dev-cycle.sh:101,144-148,227,249,299,301,318,323-328`, `test/scripts/dev-cycle.bats:146-149,157-175,179`, `fc11/bats.log`, `fc11/shellcheck.log`

---

## Claim 24a: "A brief open 14 days with no commit on its branch gets one "keep or drop?" judgment entry, so unstarted briefs cannot hold all 3 slots"

**Location:** `commit a218ad8 (message)`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the commit's summary of the rule against the skill text; does not re-verify the rule's internal details (Claim 18).

**Wording.** Unstarted briefs can still hold all 3 slots: for at least 14 days, and for as long as the user leaves the entry unanswered or answers "keep". The rule turns an indefinite hold into a user decision (Claim 18). The skill text's own "do not hold the slots for good" is the closer phrasing. Precise version: "…so unstarted briefs cannot hold the slots without the user deciding to keep them."

**Evidence:** `skills/dev-cycle/SKILL.md:213-219,229-231`

---

## Claim 24b: a218ad8's remaining claims — globs only inside plain directories; the record section is `## Skipped inputs`, matching the digest's section 8; step 0 tells a skipped record from a missing one; step 2 says "output line" like the digest; the final message reminder; Q-103's interim line no longer says the skill reads the setting, [2] carries the seed's full list, the closing line uses "If the answer differs"; the seed records the full exact-line rule

**Location:** `commit a218ad8 (message)`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers that each listed change is present in `git diff 79b1bfe..a218ad8` and does what the message says (Claims 1–4, 14–17, 20); does not cover the precision issues in Claims 14 and 16, which are wording, not absent changes.

Each item appears in the diff: `:65` (glob clause), `:66,98,251` (`## Skipped inputs`), `:102-103` (step 0), `:129` (step 2), `:268-269` (final message), `docs/working/questions.md:57,59,60` (Q-103), `docs/working/seed-build-loop-handoff.md:29-31` (rule). `questions.sh check` passes (Claim 3).

**Evidence:** `skills/dev-cycle/SKILL.md:65-66,98,102-103,129,251,268-269`, `docs/working/questions.md:57-60`, `docs/working/seed-build-loop-handoff.md:29-31`

---

## Claims Requiring Attention

### Incorrect
- **Claim 7** (`scripts/dev-cycle.sh:97-98`): behavioral. A skipped `docs/decisions/` directory is not reported in section 2, which prints "No revisit triggers recorded." (P1/P4/P9). A newer skipped cycle record next to an older readable one is not mentioned on the Window line (P3). Skipped records are never named at their read sites, only described generically. Take `n_before_triggers` before `:174`, and either narrow the comment ("noted where it would have been read") or add the mixed-case note.
- **Claim 23b** (commit c034a75): behavioral. Same root cause: "section 2 says 'No revisit triggers read' when its inputs were skipped" fails for a skipped decisions directory, the case this commit added `skipdir` for. Test 7 does not assert section 2.

### Stale
(none)

### Mostly Accurate
- **Claim 13** (`scripts/dev-cycle.sh:323-328`): wording. A regular file at a directory path is listed with a trailing slash under "not regular files".
- **Claim 14** (`skills/dev-cycle/SKILL.md:61-67`): wording. The digest's rule is stricter than "the same rule": it also skips non-regular files.
- **Claim 16** (`skills/dev-cycle/SKILL.md:102-103`): wording. "the record exists … fix or report the link": the same text fires for a skipped cycles *directory*, a future-dated skipped record, or a non-link.
- **Claim 18** (`skills/dev-cycle/SKILL.md:216-219`): wording. The rule only asks, so the slot frees on a "drop" answer. "No commit on its branch" is ambiguous for an existing branch with no commits of its own, and a "keep" answer is re-asked every cycle.
- **Claim 22** (`test/scripts/dev-cycle.bats:157`): wording. "Never its contents": a target's `log.md` is still listed. "Once" is not asserted, and section 2 is not asserted.
- **Claim 23a** (commit c034a75): wording. Fixed names (`docs/decisions/log.md`) inside a symlinked directory still reach section 8 and the record.
- **Claim 24a** (commit a218ad8): wording. "Cannot hold all 3 slots": they can until the user answers, or indefinitely on "keep".

### Unverifiable
(none)

---

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass11.md`. Its first line is `Commit: c034a75 (A) / a218ad8 (B)` and it carries the `**Replication:** k=1 (loop pass, decision 031)` header field. It follows the code-fact-check structure: header fields, the seven mandatory per-claim fields plus Legibility-target, compound claims split on verdict divergence, and Claims Requiring Attention. It serves the loop's goal (a clean delta pass, then merge) by naming the one behavioral defect that keeps this pass from clean. c034a75 measures section 2's skip baseline after the directory skip, so a symlinked `docs/decisions/` still reads as "No revisit triggers recorded." (Claims 7, 23b). This is a one-line move plus a test assertion. e08d526, which landed during this review and was not reviewed here, appears to target it: a test 7 assertion on section 2 now exists at HEAD. Everything else in both fix rounds holds or is wording: B's Q-103, seed and naming fixes all verify, and its new staleness rule and step-0 sentence need only tighter phrasing (Claims 16, 18, 24a).
