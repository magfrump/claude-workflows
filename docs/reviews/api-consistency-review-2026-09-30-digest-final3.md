Commit: baa46e3

# API Consistency Review: feat/dev-cycle-digest (final pass 3)

**Scope:** the public surface of `scripts/dev-cycle.sh` at baa46e3 (branch scope 4225753..baa46e3): the CLI, the exit codes, the digest's output format as the dev-cycle skill reads it, and the new `Main at:` line. That line is a contract between two units: the digest prints it at :85, the skill pastes it into each cycle record (`/workspace/.claude/wt-devcycle/skills/dev-cycle/SKILL.md:133-156`, read-only, feat/dev-cycle at 315f014), and the digest parses it back at :108.
**Date:** 2026-09-30
**Based on:** the Stage-1 merged fact-check summary (`fc-summary.md`, k=3; replicates `docs/reviews/code-fact-check-report-r{1,2,3}-digest-final3.md`), the pass-2 API review (`api-consistency-review-2026-09-29-digest-final2.md`), the rubric's final-pass-2 table and the override log.
**Probe log:** `docs/reviews/execution-logs/api-digest-final3-mainat-variants.txt`. It holds 11 variants of the `Main at:` line, each run in its own hermetic scratchpad repo with `DEV_CYCLE_TODAY=2026-09-30` under `timeout`. No processes are left running.

> Brief note: the shared brief at the orchestrator's `shared.md` path describes a different review (`--jobs N` for `scripts/run-tests.sh`, worktree `wt-run-tests-jobs`). It looks as if another session overwrote it. I used the scope from the dispatch message and `fc-summary.md`, which both describe this unit. The success criterion quoted below comes from that file, and it applies to this report too.

## Baseline Conventions

The sibling scripts (`scripts/questions.sh`, `archive-working-docs.sh`, `flag-removal-candidates.sh`, `skill-usage-report.sh`) share these conventions:
- long `--name=value` flags;
- `Unknown option: X` on stderr with exit 1 (`archive-working-docs.sh:32`, `flag-removal-candidates.sh:42`);
- `-h|--help` prints the header with `sed`;
- the script acts on `$PWD`'s git toplevel.

**The closest precedent for a file format a script reads back** is `scripts/questions.sh`:
- Its header documents the grammar it parses (`scripts/questions.sh:13-18`, "Entry grammar (enforced by `check`)").
- It fails loudly when the grammar breaks (`:28`, "`check` validate both files (exit 1 on problems)").
- Its header gives the design reason: "an unenforced instruction does not execute … so the drift is caught rather than trusted" (`:5-11`).

`dev-cycle.sh` cites that same header as its own rationale (`scripts/dev-cycle.sh:6`, "steps that only prose asks for do not run (scripts/questions.sh header; Q-074)").

The skill depends on these parts of the digest:
- the Window line (it is pasted into the record, SKILL.md:140);
- "no cycle record was found" (:47);
- "printed in full" and "carried forward" (:68-71);
- the `Main at:` line (:134, :137, :155);
- the rule that each verdict is recorded "under the name the digest prints" (:153).

### Fix F6 check (rubric final-pass-2 F6: "Two spellings of 'uncommitted'; Window line imprecise; 'last committed' reads the current branch")

| Part | Holds? | Evidence |
|---|---|---|
| One spelling of "uncommitted" | Yes | `:119` `(last committed on this branch: ${d:-never, uncommitted})`; `:182` `last committed on this branch: ${d:-never, uncommitted}` |
| "on this branch" label | Yes | same two lines |
| Window line "states exactly which sections read what" (baa46e3 body) | **No, partly.** | See F2. The line is static text. It claims a comparison even when none happens, does not name the commit that was compared, and leaves out that log rows are chosen by date (FC-E, 3/3 replicates) |

Items the rubric marked Won't-Fix (rubric F8: bare `--since` error text, `DEV_CYCLE_TODAY` missing from `--help`, TAB kept) and override rows 167-169 are not re-filed.

CLI and exit codes are unchanged from pass 2 and consistent with the siblings. Header `:17-18` says "Exit: 0 digest printed; 1 bad usage, not a git repo or no default branch; a failed step exits non-zero mid-digest". Fact-check F4 verified this (exit 3 through `$(…)` and a pipe). `--help` (`sed -n '2,18p'`) still covers exactly the header.

## Name-Pattern Audit

| New or changed name (4225753..baa46e3) | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `Main at: <40-hex> (copy this line …)` | digest line / record key | `Window: …` (digest :84, record template SKILL.md:140); `**Needs:**`-style keys | `scripts/dev-cycle.sh:84`; `scripts/questions.sh:15-16` | Key shape consistent with `Window:` (plain `Key:` at column 0). The parser's tolerance does not match how the skill describes the line (F1). The word "Main" is fixed although the digest names the branch elsewhere (F6) |
| `Triggers: the working tree, compared with \`$MAIN\` at the window start.` | digest text | pass-2 Window line | `scripts/dev-cycle.sh:84` | Wording clearer. Semantics inaccurate (F2) |
| `(last committed on this branch: …)` / `never, uncommitted` | digest token | pass-2 `never: uncommitted` / `never (uncommitted)` | `scripts/dev-cycle.sh:119, 182` | Consistent: one spelling now |
| `### docs/decisions/NNN-x.md` vs carried `NNN-x.md` | record name in digest | skill verdict names `014-secure-tool-guidance-layers.md` | `skills/dev-cycle/SKILL.md:146`; `scripts/dev-cycle.sh:119, 122` | Asymmetric (F4) |
| `--since`, `--sample`, `-h/--help` | CLI flags | `--round=`, `--project=`, `--with-usage` | `scripts/flag-removal-candidates.sh`, `scripts/skill-usage-report.sh` | Consistent, unchanged. `--since` semantics under-documented (F5) |

## Findings

#### F1. The `Main at:` contract accepts only the bare form and falls back silently when the line is decorated or unusable

**Severity:** Inconsistent
**Location:** `scripts/dev-cycle.sh:107-109`; `skills/dev-cycle/SKILL.md:134, 137` (feat/dev-cycle)
**Move:** 3 (consumer contract), 4 (error consistency), 8 (nullability)
**Confidence:** High (executed)
**Legibility-target:** the agent running the next cycle, and the user reading the digest to judge whether its carried list can be trusted.

**Evidence:**
```
107	# Window start = the commit the last cycle recorded ("Main at:"), else by date.
108	base="$(sed -n 's/^Main at: \([0-9a-f]\{7,40\}\).*/\1/p' "docs/working/cycles/cycle-$last_record.md" 2>/dev/null | head -1 || true)"
109	[[ -n "$base" && "$source_note" != --since ]] && git merge-base --is-ancestor "$base" "$MAIN_SHA" 2>/dev/null || base="$(git rev-list -1 --first-parent --before="$SINCE_TS" "$MAIN_SHA")"
```
Skill: `137	Main at: <sha from the digest, on its own unindented line>`. The digest (:85): `echo "Main at: $MAIN_SHA (copy this line into the cycle record; the next digest compares triggers against it)"`.

The parser is exact: column 0, a capital `M`, one space, lowercase hex. An agent writing a markdown file can plausibly paste the line as a bullet, in backticks, in bold or indented. The log shows 11 variants:
- **Used as the base** (verbatim; the full digest line with its parenthetical; a 7-char short sha): the record at :122 is carried, as intended.
- **Silently replaced by the date fallback** (`- Main at:`, `` Main at: `sha` ``, `**Main at:**`, two-space indent, `main at:`, uppercase hex, a non-ancestor sha, no line): `002-b.md` prints in full instead.

In every case the digest's text is byte-identical apart from the section 2 list. In this probe the fallback over-printed, which is harmless. FC-B (r1 Incorrect) shows the harmful direction: with an old-dated commit fast-forwarded to the tip, the fallback carried forward a record committed on main that day, which no cycle had judged.

This departs from the repo's precedent for read-back formats. `questions.sh` documents its grammar and fails loudly (`scripts/questions.sh:13-18, 28`), for the reason `dev-cycle.sh:6` itself cites: prose-only obligations drift. Here the only enforcement is the skill's prose "on its own unindented line". A mistake is invisible both when the record is written and when the next digest runs.

**Recommendation:** Do both of these:
1. Make the fallback visible. Print the base that was used and why, for example `Triggers compared with \`main\` at 1a2b3c4 (the Main at: line in cycle-2026-09-25.md)` or `… at 1a2b3c4 (estimated by date: cycle-2026-09-25.md has no usable Main at: line)`.
2. Widen the parser to cover the forms an agent plausibly writes, or warn on them. Case-insensitive key, optional leading `-`/`*`/spaces/`**`, optional backticks, `[0-9a-fA-F]`. Warn when a line matches `main at` case-insensitively but does not parse.

A test for a decorated line would pin the behaviour.

#### F2. The Window line promises a comparison it does not always make, and never names the commit compared against (F6 only partly holds)

**Severity:** Inconsistent
**Location:** `scripts/dev-cycle.sh:84` (with :97-103, :109, :130)
**Move:** 3 (documentation drift in the output contract), 7 (asymmetry between stated and actual sources)
**Confidence:** High (code read; FC-E 3/3)
**Legibility-target:** the skill agent, which pastes this line into the record (SKILL.md:140) and uses it to decide what the carried list means.

**Evidence:**
```
84	echo "Window: since $SINCE (from $source_note). Merges: \`$MAIN\` at ${MAIN_SHA:0:7}. Triggers: the working tree, compared with \`$MAIN\` at the window start. Questions, roadmap: the working tree."
```
```
130	    if [[ $full -eq 1 || ! "$d" < "$SINCE" ]]; then
```

The line is printed unconditionally, and it is inaccurate in three ways:
1. With `--since`, or with no cycle record (`full=1`, :101-102), nothing is compared, but the line still says "compared with `main` at the window start".
2. "The window start" reads as `since $SINCE`, a date. Section 2 actually compares against a commit: the recorded `Main at:` sha, or the last first-parent commit before `$SINCE_TS` (:109). The digest prints neither that commit nor which of the two it was. The `Main at:` line on :85 is the *current* tip, which makes the confusion worse.
3. Log rows (:125-139) are chosen by date from the working tree and are not compared with main. The line says nothing about them.

The baa46e3 body claims the "Window line states exactly which sections read what". That claim does not hold, so the Window-line part of rubric F6 is not fixed.

**Recommendation:** Build the triggers clause from the actual path:
- with a record: `Triggers: the working tree vs \`main\` at <base7> (<source, per F1>); log rows by date.`
- with `--since` or no record: `Triggers: the working tree, all printed in full.`

One line of code covers this, and it also discharges F1's visibility half.

#### F3. Section 2's preamble says "changed since <date>", but the code compares against a commit

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:99`
**Move:** 3 (documentation drift)
**Confidence:** High (executed; FC-F 3/3)
**Legibility-target:** the skill agent deciding which triggers need a fresh verdict.

**Evidence:**
```
99	  echo "Printed in full: triggers in decision records changed since $SINCE, and log rows dated on or after it. Listed by name only: the rest, whose verdict carries forward from docs/working/cycles/cycle-$last_record.md unless that record says \"cannot tell\" or \"fired\"."
```

In the verbatim probe, `002-b.md` was committed on 2026-09-25 09:00, before the recorded commit. The digest prints "changed since 2026-09-25" and then `Carried forward (2): 001-a.md 002-b.md`. That is correct behaviour (the 09-25 cycle saw it), but the sentence says it should have printed. Conversely, FC-F shows a 2020-dated edit fast-forwarded in the window prints, which is also correct and also contradicts "since <date>". The date clause is right for log rows only.

**Recommendation:** "triggers in decision records whose `## Revisit triggers` section differs from `main` at <base7>, and log rows dated on or after $SINCE." This shares the base token with F2.

#### F4. A record appears under two names, depending on whether it was printed or carried, while the skill keys verdicts on "the name the digest prints"

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:119, 122`; `skills/dev-cycle/SKILL.md:146, 153`
**Move:** 7 (asymmetry), 2 (naming)
**Confidence:** High (executed: `### docs/decisions/002-b.md (…)` next to `Carried forward (1): 001-a.md` in the same digest)
**Legibility-target:** the next cycle's agent, which must match this cycle's verdicts to the carried list by name.

Precedent: bare `NNN-slug.md` record names used in `skills/dev-cycle/SKILL.md:146,148` and `scripts/dev-cycle.sh:122`

**Evidence:**
```
119	    echo "### ${f//$'\n'/ } (last committed on this branch: ${d:-never, uncommitted})"
122	    carried+=("${f#docs/decisions/}")
```
Skill: `153	Record one verdict for every trigger, under the name the digest prints, including carried`

A trigger printed in full is recorded as `docs/decisions/002-b.md` if the agent follows :153 literally. Next cycle it is carried as `002-b.md`, and the agent has to match across the two forms to find the verdict it carries. This is small but sits on the carry-forward path, and the skill's template (:146) uses the bare form. It differs from override row 169, which covers whether the carried list can be split mechanically, not the naming mismatch between the heading and the list.

**Recommendation:** Print the heading as `### ${f#docs/decisions/}` (the path is implied by the section), or have the skill say to record the bare file name.

#### F5. `--help` does not say that `--since` turns off carry-forward, or what the script reads from the cycle record

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:8-13`
**Move:** 3 (documentation drift), 1 (baseline: questions.sh documents its read-back grammar)
**Confidence:** High
**Legibility-target:** a user or agent choosing whether to pass `--since`. The skill tells them to in one case (SKILL.md:47-48).

**Evidence:**
```
10	#   --since   start of the cycle window (midnight, local time). Default: the
11	#             date in the newest docs/working/cycles/cycle-YYYY-MM-DD.md, else
12	#             14 days ago. The digest says which.
```

`--since` also makes every trigger print in full (:97-102) and ignores the recorded `Main at:` (:109). The header never mentions the `Main at:` line, which is the only record content the script parses. `questions.sh:13-18` documents the grammar it reads.

**Recommendation:** Add two lines:
- "`--since` also prints every trigger in full (no carry-forward)."
- "Reads the record's first `Main at: <sha>` line (column 0) as the trigger baseline."

Widen the `sed` range to match.

#### F6. The `Main at:` key says "Main" even when the resolved branch is `master` or the current branch

**Severity:** Informational (Minor, downgraded one tier: no precedent for a fixed branch word in a key)
**Location:** `scripts/dev-cycle.sh:85` (with :49, :56-60)
**Move:** 2 (naming)
**Confidence:** Medium
**Legibility-target:** a reader of a cycle record in a non-`main` repo.

No existing precedent in `scripts/*.sh` echo output or `skills/dev-cycle/SKILL.md` for a record key naming a branch. The rest of the digest names the branch by variable (``` `$MAIN` ``` at :84, :93).

**Evidence:** `85	echo "Main at: $MAIN_SHA (copy this line …)"`. The fallback at `58-59` (``if [[ -n "$cur" && "$cur" != -* ]]; then`` / ``MAIN="$cur"; MAIN_SHA="$(git rev-parse --verify --quiet HEAD …)"``) can make this a feature branch's tip.

**Recommendation:** Keep the fixed key, which the parser needs. Optionally append the branch name after the sha, for example `Main at: <sha> (\`master\`; copy this line …)`, which the parser's `.*` already tolerates.

#### F7. The skill's record template has two small paste ambiguities around the digest's lines

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:133-134, 140` (read-only; for the stacked unit)
**Move:** 3
**Confidence:** Medium
**Legibility-target:** the skill agent writing the record.

**Evidence:**
```
133	Write `docs/working/cycles/cycle-YYYY-MM-DD.md` (if one already exists for today, update it
134	in place, keeping a single `Main at:` line):
140	Window: <the digest's Window line>
```

- The digest's Window line already starts with `Window: `, so a literal fill gives `Window: Window: since …`.
- When the digest is rerun on the same day, :134 does not say whether the single `Main at:` should be the new tip or the old one. The parser takes the first line (:108 `head -1`), and the verdicts were made against the rerun's tip.

**Recommendation:** `<the digest's Window line, verbatim>` on its own line, and "replace the `Main at:` line with the latest digest's."

## What Looks Good

- The core design works: a recorded commit, with the trigger section compared at that commit. With a verbatim line (including the full pasted digest line and a 7-char short sha), the record committed before the recorded tip is carried and nothing else is.
- The parser's trailing `.*` means pasting the whole digest line, parenthetical included, works. That is the most likely thing an agent does when told to "copy this line".
- "uncommitted" now has one spelling and "on this branch" labels both date sources. That part of F6 holds.
- The CLI and exit codes match the siblings. `--help` still prints exactly the header.
- The `Main at:` key has the same shape as the record's other plain `Key:` line (`Window:`).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `Main at:` accepts only the bare form; decorated, uppercase or non-ancestor lines fall back silently to the date | Inconsistent | `scripts/dev-cycle.sh:107-109`; SKILL.md:137 | High |
| 2 | Window line claims a comparison with `--since` or no record, never names the base commit, omits log rows (F6 partly unfixed) | Inconsistent | `scripts/dev-cycle.sh:84` | High |
| 3 | Section 2 says "changed since <date>"; the code compares against a commit | Minor | `scripts/dev-cycle.sh:99` | High |
| 4 | Heading uses `docs/decisions/x.md`, carried list uses `x.md`; skill keys verdicts on the printed name | Minor | `scripts/dev-cycle.sh:119, 122`; SKILL.md:153 | High |
| 5 | `--help` omits that `--since` disables carry-forward and that `Main at:` is read | Minor | `scripts/dev-cycle.sh:8-13` | High |
| 6 | `Main at:` hardcodes "Main" when the branch may be `master` or current | Informational | `scripts/dev-cycle.sh:85` | Medium |
| 7 | Skill template: `Window: Window:` double prefix; which sha to keep on a same-day rerun | Informational | SKILL.md:134, 140 | Medium |

## Overall Assessment

The CLI is consistent with the sibling scripts, and the exit contract holds. The new cross-unit contract works when the agent writes the line exactly as printed. But the digest accepts a narrower form than the skill's prose leads an agent to write, and it gives no signal when it falls back. The fallback is date-based, which is the mechanism the fix was meant to replace (FC-B). Worse, the Window line and section 2's preamble describe a date comparison the code no longer makes, and they omit the commit it does compare against.

All three issues (F1-F3) close with one change: print the base commit and where it came from, and word the triggers clause from the path actually taken. Tolerating or warning on decorated lines makes the contract robust. Nothing here breaks the stacked skill today (no cycle record exists yet, and the template shows the bare form). The fixes are local, a few lines each, and consistent with the `questions.sh` precedent the script itself cites.

## Goal-Alignment Note

- **Success criterion (verbatim from the brief):** "a markdown report saved at the path named below, structured per the skill."
- **Answered:** I reviewed the CLI, the exit codes, the digest-as-contract and the `Main at:` round trip, against the siblings and the skill. I actioned all three escalations addressed to me:
  - silent fallback on a decorated or unusable line: F1, with 11 executed variants;
  - the digest not naming its base: F1 and F2;
  - the Window line and :99 text against the real semantics: F2 and F3.
  
  F6 holds for the spelling and the label, but not for the Window line.
- **Out of scope:** security aspects of FC-A (forged line) and FC-D (C1 controls, unfiltered stderr) belong to security-reviewer. FC-C (the activity counts' date walk) is correctness, not interface; F2's recommendation does not fix it. I did not assess the performance claim. I did not edit the skill (read-only) or run the bats suite.
- **Escalate:**
  - To the orchestrator: the shared brief file at `shared.md` belongs to another review (run-tests `--jobs`). Other critics dispatched with it may have reviewed the wrong unit.
  - To the author: F1 and F2 are one small change, and should be fixed before merge or recorded as an override. F4 and F7 touch the stacked skill unit (feat/dev-cycle).
- **Questions / Decisions:** Should the parser be widened (tolerant) or kept strict with a warning? A strict parser plus a warning matches the questions.sh precedent (document it, fail loudly). The tolerant parser is fewer lines. Either choice satisfies F1 once the base is printed.
