Commit: db0e5ca

# API Consistency Review — feat/dev-cycle-digest, final pass 4

**Scope:** `git diff main...HEAD -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` at db0e5ca; consumer read from `git show feat/dev-cycle:skills/dev-cycle/SKILL.md` (70cc7dc) and `feat/dev-cycle:docs/roadmap.md`
**Date:** 2026-10-01
**Based on:** Stage-1 merged fact-check summary (k=3), `docs/reviews/code-fact-check-report-r{1,2,3}-digest-final4.md`

Public surface reviewed: the CLI (`--since`, `--sample`, `-h/--help`, exit codes), the digest's printed format (section headings and the lines the dev-cycle skill reads), and the file-format contracts (cycle record names and contents, roadmap sections, idea log).

## Baseline Conventions

- **Sibling CLI scripts** (`scripts/skill-usage-report.sh:29`, `scripts/flag-removal-candidates.sh:42`, `scripts/archive-working-docs.sh:32`) report an unknown flag as `Unknown option: <arg>` on stderr and exit 1. Help text is the header comment, printed by `sed`. `scripts/questions.sh` acts on `$PWD`'s repo and documents its usage in that header. `dev-cycle.sh` follows all of these.
- **The consumer contract** is `skills/dev-cycle/SKILL.md` on `feat/dev-cycle`, which still describes baa46e3's digest. Step 0 lists what the digest gives. Step 2 reads the trigger list, including a "carried forward" list. Step 3 reads "`questions.sh open` failed". Step 6 defines the roadmap template (`## Now`, `## Next`, `## Ideas`, `## Done`). Step 7 defines the cycle record (`cycle-YYYY-MM-DD.md`, a `Main at:` line, trigger verdicts "under the name the digest prints").
- **The old digest (baa46e3)** printed `Main at: <sha>` and a `Carried forward (N): <basenames>` line. It printed full trigger sections under `### docs/decisions/<file>`. The skill was written against that output.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `## 6. Merges with code but no docs` | digest heading | `## 4. Spot-check sample`, `## 2. Revisit triggers` (section N = skill step N) | `scripts/dev-cycle.sh:107,160`; `feat/dev-cycle:skills/dev-cycle/SKILL.md` steps 2, 4 | Inconsistent: skill step 6 is Roadmap (F6) |
| `## 7. Inputs for steps 4b and 5` | digest heading | skill step numbers 0–7 | `feat/dev-cycle:skills/dev-cycle/SKILL.md:39-131` | Inconsistent: the skill has no step 4b (F3) |
| `Step 4b (deep-audit triggers)` / `0 items ready for 6b` | printed step references | skill steps `### 4. Spot-check audit`, `### 6. Roadmap` | same | Inconsistent: no 4b or 6b in the skill (F3) |
| `## In flight` (roadmap section counted) | file-format section | `## Now`, `## Next`, `## Ideas`, `## Done` | `feat/dev-cycle:skills/dev-cycle/SKILL.md:115-118`, `feat/dev-cycle:docs/roadmap.md` | Inconsistent: not in the template (F3) |
| `docs/working/idea-log.md`, `## Brainstorm YYYY-MM-DD` | file-format contract | `docs/working/feature-ideas*.md` (skill step 5), roadmap `## Ideas` (step 6) | `feat/dev-cycle:skills/dev-cycle/SKILL.md:100,125`; `docs/working/feature-ideas.md` | Inconsistent: no writer for this file (F3) |
| `Ideas seeded since` | printed label | `Last brainstorm` | `scripts/dev-cycle.sh:234-238` | Minor: counts more than it says (F8) |
| `### docs/decisions/<file>` trigger name | printed key | skill record example `014-secure-tool-guidance-layers.md`; baa46e3 carried list `${f#docs/decisions/}` | `feat/dev-cycle:skills/dev-cycle/SKILL.md:146-148`; `baa46e3:scripts/dev-cycle.sh` | Inconsistent: the skill keys verdicts by basename (F5) |
| `--since`, `--sample`, `-h/--help` | CLI flags | unchanged names; `Unknown option` exit 1 | `scripts/skill-usage-report.sh:29`, `scripts/flag-removal-candidates.sh:42` | Consistent (the `--since` meaning changed: F7) |
| exit 1 "needs perl" | exit code | exit 1 for bad environment (`Not inside a git repository`) | `scripts/dev-cycle.sh:48,72` | Consistent, and documented in `--help` |

## Findings

#### F1. The skill's cycle record still requires a `Main at:` line the digest no longer prints, and claims the next digest reads it

**Severity:** Breaking
**Location:** `scripts/dev-cycle.sh:90-92` (provider); `feat/dev-cycle:skills/dev-cycle/SKILL.md:133-137,154-155` (consumer)
**Move:** 3 (consumer contract)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:** HEAD prints only the header and the Window line. The SHA appears only abbreviated, inside prose:
```
echo "# Dev-cycle digest — $TODAY"
echo
echo "Window: since $SINCE (from $source_note). Merges and commits: those on \`$MAIN\` at ${MAIN_SHA:0:7} committed on or after $SINCE, ..."
```
The removed line (baa46e3) was `echo "Main at: $MAIN_SHA (copy this line into the cycle record; the next digest compares triggers against it)"`. The skill still says:
```
in place, keeping a single `Main at:` line):
...
Main at: <sha from the digest, on its own unindented line>
...
file's date and compares triggers against the recorded commit.
```
The test `test/scripts/dev-cycle.bats:77` asserts the opposite: `[[ "$output" != *"Main at:"* ]]`.

Q-101 [1] removed this handshake on purpose. The skill, its only consumer, was not updated. An agent following step 7 is told to copy a line that does not exist, and the skill tells it the next digest uses that line, which it no longer does. In practice it will paste the 7-character SHA from the Window line or stall. Nothing reads the result, so no data is corrupted. But the skill's own description of the mechanism is false, and the cut does not hold until both branches agree.

**Recommendation:** Land the matching skill edit as part of this merge (or immediately after it): delete the `Main at:` line from the step 7 template, the "keeping a single `Main at:` line" clause and "and compares triggers against the recorded commit". Do not reintroduce the line in the digest.

#### F2. Skill steps 2 and 7 still describe carried-forward verdicts; the digest now tells the agent the opposite

**Severity:** Inconsistent
**Location:** `scripts/dev-cycle.sh:108`; `feat/dev-cycle:skills/dev-cycle/SKILL.md:70-71,148,153-154`
**Move:** 3 (consumer contract), 7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:** The digest says:
```
echo "Every trigger, in full. Decide each: fired / not fired / cannot tell, with the evidence. A fired trigger becomes a questions.md entry. The last cycle record's verdicts are context, not answers."
```
The skill says:
```
would tell. Triggers the digest lists as carried forward keep the previous record's verdict,
unless that verdict was "cannot tell" or "fired", or the previous record has none for it:
...
- 031-review-loop-tier-and-factcheck-policy.md: not fired (carried from cycle-<date>)
...
Record one verdict for every trigger, under the name the digest prints, including carried
ones, so the next cycle can carry them again.
```
The digest no longer lists anything as carried, so the step 2 clause never applies. The step 7 template still shows a `(carried from cycle-<date>)` verdict, and "so the next cycle can carry them again" describes a mechanism that no longer exists. An agent that copies the template line can record a carried verdict without deciding it. That is the behaviour the cut was meant to stop, and it contradicts the digest's "context, not answers".

**Recommendation:** In the same skill edit as F1, delete the carried-forward sentence in step 2, the `(carried from …)` example line and "including carried ones, so the next cycle can carry them again". Optionally add one line saying the previous record's verdicts are context.

#### F3. Section 7 assumes skill contracts that do not exist: step 4b, step 6b, "the skill's thresholds", a roadmap `## In flight` section and `docs/working/idea-log.md` with `## Brainstorm YYYY-MM-DD` headings

**Severity:** Inconsistent
**Location:** `scripts/dev-cycle.sh:195,208,218-241`; `test/scripts/dev-cycle.bats:250-262`
**Move:** 3 (consumer contract), 5/8 (fields the consumer never writes)
**Confidence:** High
**Legibility-target:** for-author

No existing precedent in `feat/dev-cycle:skills/dev-cycle/SKILL.md`, `feat/dev-cycle:docs/roadmap.md` and a repo-wide `rg -i 'idea-log|In flight|step 4b|\b6b\b|Brainstorm [0-9Y]'` excluding `docs/reviews/`, for the names `4b`, `6b`, `In flight` and `idea-log.md`. Severity is shown after the one-tier downgrade from Breaking: the step numbers and the files are new conventions, not violations of existing ones. The template does exist for the roadmap sections, and that part stays Inconsistent on its own.

**Evidence:**
```
printf '\n%s\n\n' "## 7. Inputs for steps 4b and 5"
echo "Step 5 (brainstorm triggers; the thresholds are the skill's):"
  for sec in Now "In flight" Next; do
  echo "- Roadmap: none yet (0 items ready for 6b)"
LOG=docs/working/idea-log.md
  # Step 5 heads each brainstorm "## Brainstorm YYYY-MM-DD"; ideas are "- " lines.
```
The skill's roadmap template is `## Now`, `## Next`, `## Ideas`, `## Done` (`SKILL.md:115-118`). Its step 5 reads `docs/working/feature-ideas*.md` and puts surviving ideas in the roadmap's `## Ideas`; it writes no idea log. It has no step 4b or 6b and no brainstorm thresholds. db0e5ca's Notes admit this ("which the skill (feat/dev-cycle) must write"). The section 7 code also ends at `:241`, so nothing else in the script defines these contracts.

Executed on a clone of `feat/dev-cycle` (scratch `api-final4/out-skillbranch.txt`):
```
- Roadmap Now: 1 item(s)
- Roadmap In flight: 0 item(s)
- Roadmap Next: 5 item(s)
- No docs/working/idea-log.md: no ideas seeded, no brainstorm recorded
```
Against the real skill, then, section 7's step-5 half always prints a constant "In flight: 0" and "no brainstorm recorded". It never counts the `## Ideas` section that the skill does write. It ignores `docs/working/feature-ideas.md`, which exists in /workspace and is the input the skill names. The bats test (`:254-259`) fixes the unratified format in place: `## In flight` and `docs/working/idea-log.md` are now asserted contracts with no writer.

**Recommendation:** Pick one before merging. (a) Cut section 7's step-5 half (and the "4b"/"6b" labels) until the skill change that defines them lands, or (b) land the skill edit that adds step 4b, the `In flight` section (or drop it from the digest and count `## Ideas`), the idea-log writer and its heading, and the thresholds. This is the "new contracts section 7 assumes" the brief asks about. It needs one owner decision, not two branches each guessing.

#### F4. Section 6 hands step 4 a finding list that step 4 does not read, and skill step 0 does not list sections 6 or 7

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:180-193`; `feat/dev-cycle:skills/dev-cycle/SKILL.md:43-45,85-93`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
# A merge whose diff against its first parent touches files but no docs/ path,
# *.md or README is a step 4 finding to check (rule: undocumented is broken).
```
Skill step 0: "It is read-only and gives the window and where its start came from, merges in it, the revisit triggers that need a verdict, the watched questions, the spot-check sample and the roadmap's Next section." Step 4 covers only "each sampled merge". A merge flagged in section 6 but not sampled reaches no step. The digest prints it and nothing consumes it. That works against the repo's own principle (`dev-cycle.sh:5-6`: "steps that only prose asks for do not run").

**Recommendation:** Add one sentence to skill step 4 ("also check every merge the digest's section 6 flags") and extend step 0's list of what the digest gives. Ship this in the same skill edit as F1–F3.

#### F5. Trigger keys: the digest prints the full path, the skill keys verdicts by basename

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:118`; `feat/dev-cycle:skills/dev-cycle/SKILL.md:146,153`
**Move:** 2 (naming), 7 (asymmetry)
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: basename keys (`014-secure-tool-guidance-layers.md`) used in `feat/dev-cycle:skills/dev-cycle/SKILL.md:146-148` and in baa46e3's `carried+=("${f#docs/decisions/}")` (`baa46e3:scripts/dev-cycle.sh`)

**Evidence:**
```
  echo "### ${f//$'\n'/ } (last committed on this branch: ${d:-never, uncommitted})"
```
which prints `### docs/decisions/014-secure-tool-guidance-layers.md (last committed …)` (executed on the feat/dev-cycle clone). The skill says "Record one verdict for every trigger, under the name the digest prints", and its example is `- 014-secure-tool-guidance-layers.md: not fired`. Before the cut, the basename was what the carried list printed. Now the only printed form is the full path, so the instruction and its example disagree. With carry-forward gone, no program matches these keys, so the impact is only on readers. That is why this is Minor and not Inconsistent.

**Recommendation:** In the skill edit, change the example to `docs/decisions/014-….md` (the printed name), or say "the record's file name". Leave the digest unchanged.

#### F6. Digest section numbers 6 and 7 collide with skill steps 6 and 7

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:180,195`
**Move:** 2 (naming against the grain)
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: digest section N = skill step N for `## 2. Revisit triggers`, `## 3. Watched questions`, `## 4. Spot-check sample` (`scripts/dev-cycle.sh:107,135,160` against `feat/dev-cycle:skills/dev-cycle/SKILL.md` steps 2–4)

**Evidence:**
```
printf '\n%s\n\n' "## 6. Merges with code but no docs"
printf '\n%s\n\n' "## 7. Inputs for steps 4b and 5"
```
In the skill, step 6 is Roadmap and step 7 is Close. The digest's own Roadmap section is `## 5`. Sections 2–4 line up with the skill's steps and sections 5–7 do not. A cycle record or questions entry that cites "section 6" or "step 6" is now ambiguous, and section 7's title names *steps* 4b and 5 while being numbered 7. The mismatch at section 5 dates from before this branch; sections 6 and 7 are new and make it worse.

**Recommendation:** Either number the digest sections by the step they feed (e.g. `## 4a. Merges with code but no docs`) or drop the numbers from the headings. Update the heading test at `test/scripts/dev-cycle.bats:39-41` to match.

#### F7. `--since` changed meaning from local midnight to the committer's own-zone date; `--help` does not say which

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:10,96-102`
**Move:** 6 (changed semantics of an existing flag)
**Confidence:** High (executed)
**Legibility-target:** for-author

**Evidence:** baa46e3's help said `--since   start of the cycle window (midnight, local time).` HEAD says:
```
#   --since   start of the cycle window: merges committed on or after this date.
merges_full="$(git log "$MAIN_SHA" --first-parent --merges --format='%cs %H %h %ad %s' --date=short | awk -v s="$SINCE" '$1 >= s')"
```
Probe (merge committed `2026-09-30T23:30-07:00`, `--since=2026-10-01`): baa46e3 counted it under `TZ=UTC` (1 merge) but not under `TZ=America/Los_Angeles` (0). HEAD excludes it under both (0). The new rule is deterministic, which is an improvement, but it is a silent semantic change to an existing flag, and the help text does not name the zone. For this repo the user commits in one zone (PDT), so the practical effect is nil today.

**Recommendation:** Add three words to `--help`: "(the committer's own date, `%cs`)". No code change.

#### F8. "Ideas seeded since" counts the last brainstorm's own bullets

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:232,238`; `test/scripts/dev-cycle.bats:255,260`
**Move:** 2 (label vs. value)
**Confidence:** High
**Legibility-target:** for-author

No existing precedent in `scripts/dev-cycle.sh` and `feat/dev-cycle:skills/dev-cycle/SKILL.md` (no other "since" counter over a log). This is downgraded from Inconsistent.

**Evidence:**
```
  seeded="$(awk '/^## Brainstorm [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ { c = 0; next } /^- / { c++ } END { print c + 0 }' "$LOG")"
  echo "- Ideas seeded since: $seeded"
```
The test fixture `## Brainstorm 2026-01-01\n- one\n- two` expects `Ideas seeded since: 2`. Those two bullets are the brainstorm's own output, not ideas seeded after it. A threshold such as "brainstorm when ≥ N ideas are seeded since the last one" would count a brainstorm's output as new input to the next brainstorm. This depends on F3; if section 7's step-5 half is cut, so is this.

**Recommendation:** Define the contract when F3 is decided. If brainstorm output goes under the heading, count only bullets in a separate "seeded" area. Otherwise rename the label to what is counted ("Ideas under the last brainstorm heading and after").

#### F9. The Window line does not describe section 7's file lists

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:92,196-205`
**Move:** 3 (documentation drift; the skill copies this line into the record)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**
```
echo "Window: since $SINCE (from $source_note). Merges and commits: those on \`$MAIN\` at ${MAIN_SHA:0:7} committed on or after $SINCE, filtered by date after a full walk. Triggers: all of them, from the working tree. Questions, roadmap, idea log: the working tree."
...
  changed="$(git diff --name-only -z "$base" "$MAIN_SHA" -- skills workflows docs/decisions | tr '\0\n' '\n ')"
```
Section 7 lists a net diff from the parent of the oldest in-window first-parent commit. That is neither "committed on or after" nor the working tree, and a file changed and reverted inside the window shows nothing (Stage-1). Skill step 7 copies the Window line verbatim into the record (`Window: <the digest's Window line>`), so the record misdescribes what was compared. A4 was this same class of finding at pass 3.

**Recommendation:** Add a clause to the Window line, e.g. "Changed files (section 7): net diff from the commit before the window to `<sha>`".

#### F10. With `2>&1`, an error can print before the digest header, and output can trail the exit

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:31`
**Move:** 4 (error consistency)
**Confidence:** Medium (taken from Stage-1, not re-executed here)
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
exec > >(scrub) 2> >(scrub >&2)
```
Stdout and stderr go through two separate perl filters that bash does not wait for. Stage-1 observed an empty redirected file at exit when perl was slowed, and stderr overtaking stdout. For a consumer that captures `2>&1` ("Keep its output"), a "**questions.sh open failed**" block or a failed step's message may appear out of order. The skill's step 3 relies on finding that block inside section 3. The security and performance critics own the mechanics; for API consistency, the point is that printed order is part of the contract the skill reads.

**Recommendation:** Wait for the filters at exit, e.g. use one combined filter and `wait` in an EXIT trap. The performance and security reviews own the details.

## What Looks Good

- **The CLI is unchanged in shape.** `--since[=]`, `--sample[=]` and `-h/--help` keep their names. `Unknown option: …` → exit 1 matches `scripts/skill-usage-report.sh`, `scripts/flag-removal-candidates.sh` and `scripts/archive-working-docs.sh`. The new "needs perl" exit is documented in `--help` (`:18-19`), and the `--help` range `2,19p` covers the whole header.
- **The cycle record name contract holds.** `docs/working/cycles/cycle-YYYY-MM-DD.md` is read by file name only (`:75-79`, `:11-12`), which matches skill step 7, and future-dated records are ignored. A record written to the skill's current template (with `Main at:`) does not affect the digest (`bats:65-77`).
- **The strings the skill matches still match.** `no cycle record found` (skill step 0), `**questions.sh open failed**` (step 3), `## 5. Roadmap … Its Next section` and the `No docs/roadmap.md yet — create it this cycle from the template in the dev-cycle skill` pointer (step 6).
- **The cut removed the carried-list output and the `Main at:` line without leaving a partial form behind,** and a test pins both absences (`bats:77`).
- **The section 2 instruction text** ("Decide each: fired / not fired / cannot tell…") uses the skill's three verdict words exactly.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Skill still requires and describes a `Main at:` line the digest removed | Breaking | `scripts/dev-cycle.sh:90-92`; skill `:133-137,154-155` | High |
| F2 | Skill steps 2/7 still describe carried verdicts; digest says "context, not answers" | Inconsistent | `scripts/dev-cycle.sh:108`; skill `:70-71,148,153-154` | High |
| F3 | Section 7 assumes step 4b/6b, thresholds, `## In flight`, `idea-log.md`/`## Brainstorm` that the skill does not define | Inconsistent (downgraded from Breaking: no precedent) | `scripts/dev-cycle.sh:195,208,218-241`; `bats:250-262` | High |
| F4 | Section 6 is a "step 4 finding" no step reads; step 0 omits sections 6–7 | Minor | `scripts/dev-cycle.sh:180-193`; skill `:43-45,85-93` | High |
| F5 | Trigger keys: full path printed, basename in the skill's record example | Minor | `scripts/dev-cycle.sh:118`; skill `:146,153` | Medium |
| F6 | Sections 6/7 numbered against skill steps 6/7 | Minor | `scripts/dev-cycle.sh:180,195` | Medium |
| F7 | `--since` now uses the committer-zone date; help does not say so | Minor | `scripts/dev-cycle.sh:10,96-102` | High |
| F8 | "Ideas seeded since" counts the brainstorm's own bullets | Minor (downgraded) | `scripts/dev-cycle.sh:232,238` | High |
| F9 | Window line (copied into the record) omits section 7's net-diff basis | Minor | `scripts/dev-cycle.sh:92,196-205` | Medium |
| F10 | Unwaited filters: stderr/stdout order and completeness at exit | Informational | `scripts/dev-cycle.sh:31` | Medium |

## Overall Assessment

The digest's own CLI is consistent with its sibling scripts, and the cut is clean on the provider side: no `Main at:` and no carried list remain, and a test pins both. The contract breaks are all on the consumer side. `skills/dev-cycle/SKILL.md` on `feat/dev-cycle` still describes baa46e3's digest: the `Main at:` handshake (F1), carried verdicts (F2) and basename keys (F5). Section 7 adds contracts (step 4b, step 6b, `## In flight`, the idea log) that no skill text defines or writes (F3), so on the real repo its step-5 half prints constants. All of this is fixable in place with one coordinated skill edit plus one decision on section 7. That decision is to cut its step-5 half for now, or land the skill text that defines it. Neither branch should merge to main alone, because whichever lands first leaves the pair inconsistent.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your role instructions give, structured per your skill file.
- Answered: yes. Covers the CLI, the printed format against the feat/dev-cycle skill (the post-cut `Main at:` and carried breaks) and the new section 6/7 contracts.
- Out of scope: scrub bypasses (security-reviewer); exactness of section 6 and 7 classification beyond its contract (fact-check and test-strategy); files on the branch other than the two scoped files.
- Escalate: F1+F2+F3 need one coordinated skill edit on feat/dev-cycle and an owner decision on section 7's step-5 contract before either branch reaches main.
- Decisions I made: treated feat/dev-cycle's SKILL.md (70cc7dc) as the binding consumer although it is unmerged. Rated F1 Breaking because the skill's instruction cannot be followed as written, even though the data harm is nil.
