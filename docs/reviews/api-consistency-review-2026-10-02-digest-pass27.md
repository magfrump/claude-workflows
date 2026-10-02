Commit: b00c057 (A) / 7f3e392 (B)

# API Consistency Review: dev-cycle pass 27 (the pass-26 fix round)

**Scope:** Partial: the pass-26 fix round only. A: `git diff 10c2809..b00c057 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` in `/workspace/.claude/wt-digest`. B: `git diff 875b41f..7f3e392 -- skills/dev-cycle/SKILL.md` in `/workspace/.claude/wt-devcycle`. The merge c7a29b3 carries b00c057's script and tests unchanged, and its `SKILL.md` is 7f3e392's. Everything else is context only (rubric section "Pass 26").
**Date:** 2026-10-02
**Based on:** `docs/reviews/code-fact-check-report-digest-pass26.md` (Stage-1 context), pass 26's api-consistency review (380bcb7), and this pass's own probes.
**Replication:** k=1 (loop pass).

**Probe discipline.** Each probe is one script. Each starts with `set -eu`, creates its own `mktemp -d -p api27/` dir in the same script, and checks `case "$PWD"` before any `git init`, commit or write. The code came from `git show <commit>:scripts/dev-cycle.sh` or `git archive b00c057`. Every process ran under `timeout`, and every script ended with `pgrep` printing "no leftover processes". I wrote nothing outside `api27/` except this report. Scratch dir: `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/api27/` (`api27/` below).

- **probe1** (`api27/probe1.out`):
  - bats on `git archive b00c057`: 44 ok, rc 0.
  - `hermeticity-lint --root .`: clean.
  - shellcheck: rc 0.
  - `--help`: still ends on the Exit paragraph, because line 62 is still the blank line before `set -euo pipefail`.
  - `--check-answer` on all 99 IDs in `/workspace`'s `questions.md` and archive, under 10c2809 and b00c057: `diff` empty.
- **probe4** (`api27/probe4.out`): the same diff on all 102 IDs in 7f3e392's two questions files. `diff` empty: 3 done, 19 drop, 26 keep, 13 open, 41 unrecognized. Every `**Needs:**` line ends exactly in ` **Status:** OPEN` or ` **Status:** ANSWERED` (0 exceptions). The commit message's "all 102 real IDs read as before" holds.
- **probe2 / probe2b** (`api27/probe2.out`, `probe2b.out`):
  - `--check-brief`'s `-G` commit, in seven cases P1–P7.
  - The six modes in an unborn `trunk` repo (U1) and on a detached HEAD with only `trunk` (U2).
  - Header and fence variants of `--check-answer`.
- **probe3** (`api27/probe3.out`): nested fences (a four-backtick fence around a three-backtick block) in a questions entry and in a brief.

Legibility-target values:
- **agent**: the model running the skill acts on the text.
- **maintainer**: someone editing the script or the tests.
- **user**: the human reading the help, the record or the final message.

## Baseline Conventions

- **Check-mode output.** Each argument gets one line: `ok <arg> [fields…]`, `absent <name>`, `skip <arg>: <reason>`, or for `--check-answer`, `<option> Q-NNN`. A skip is an answer (exit 0). Only usage or environment failures exit 1, with a `<flag> needs …` message on stderr (`scripts/dev-cycle.sh:22-62`, `:114`, `:123`).
- **The help is the contract.** Each output word is defined in the header that `--help` prints (`:2-62`). The function comments add maintainer detail.
- **Fences.** Both readers (brief `Status:`, questions entries) claim to skip lines "in a fence". The repo's markdown is CommonMark (GitHub). There, a closing fence must use the same character and be at least as long as the opening one.
- **Skill vocabulary.** One slot rule (`SKILL.md:81-84`, "holds a slot"). Paths are quoted as the checks print them (`docs/working/briefs/…`).
- **Two readers of the questions header.** `scripts/questions.sh` `parse_entries` splits the `**Needs:**` line on ` · ` and takes the `Status:` field. `--check-answer` reads the first `**Needs:**` line.

## Name-Pattern Audit

This round adds no new flag, output word or variable name. Pre-existing values and terms change:

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `INSTRUCTION_FILE` (value now spelled out, `agents?`) | global pattern variable | `NAMECHARS`, `DIGIT`, `SLUG` | `scripts/dev-cycle.sh:182`, `:234-235` | Consistent: characters listed one by one, as its siblings do |
| `<commit>` in `ok <path> <status> <commit>` (now "last commit that changed a Status line") | output field | `--check-branch`'s `<commit>` (the ref's own sha) | `scripts/dev-cycle.sh:30-34`, `:273-274` | Same name and shape. Its meaning is wider than the skill says (Finding 3). |
| "`<k>/3 slots held`", "a brief holding a slot" | skill term | "holds a slot" (Rules), "fewer than 3 briefs hold a slot" | `SKILL.md:81`, `:311` | Consistent. "open build brief" survives in In flight's definition (Finding 6). |
| `briefs/closed/<same name>` | skill path form | `docs/working/briefs/closed/` | `SKILL.md:78`, `:270` | Short form of a path the checks print in full (Finding 7) |

## Findings

#### 1. A stale In flight line is pointed at `briefs/closed/`, a path that In flight's own first check always skips

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:84-87`, `:263-266`; `scripts/dev-cycle.sh:258` (`isbrief` gate in `check_brief`)
**Move:** 3 (consumer contract)
**Confidence:** High for the check outputs (probe2 P5). Medium for how an agent then behaves.
**Legibility-target:** agent

**Evidence:**
- Skill: "A roadmap In flight path that `--check-path` skips (the brief moved, or never landed) is recorded and its line corrected: pointed at `briefs/closed/<same name>` if `--check-path` prints `ok` there, otherwise removed."
- In flight step 1: "`--check-brief` prints `done` … → Done … It prints `dropped` … → Ideas".
- Probe P5, after `git mv` into `closed/`:
  ```
  skip docs/working/briefs/closed/2026-09-01-x.md: not an open build brief (docs/working/briefs/YYYY-MM-DD-<slug>.md)
  ok docs/working/briefs/closed/2026-09-01-x.md        # --check-path
  ```

The correction keeps the item **in In flight**, now naming a `closed/` path. On every later cycle, In flight step 1 runs `--check-brief` on that path. The check refuses every `closed/` path, so the item never reaches Done or Ideas, and the same skip is recorded every cycle. The Rules also say "a brief the check skips keeps its slot (recorded) until the cause is fixed". An agent can read this as holding a slot for a brief that is already closed, and that blocks a new brief. No allowed interface says whether the closed brief was `done` or `dropped`, because a brief's state "comes only from `--check-brief`". So the agent cannot route the item to Done or to Ideas either. This is the pass-26 Finding 10 fix: the "moved" case now has a target, but the target is a state no check can resolve.

**Recommendation:** Do not leave a closed brief In flight. Either:
- let `--check-brief` accept `docs/working/briefs/closed/<name>` and report its status from the default branch (an `isbrief` change plus a test), then route the item to Done or Ideas from that; or
- say "move the item to Done (or Ideas) naming the `closed/` path, with the reason 'closed by an earlier change'", and exempt `closed/` paths from the skip-keeps-its-slot sentence.

#### 2. Fences close on their first three characters, not on their length, so a nested fence still yields a wrong keep or a wrong done

**Severity:** Inconsistent. Precondition: an entry or brief that quotes a fenced example using a longer fence (four backticks or tildes) around a three-character fence, with an answer-shaped or `Status:` line between the inner fences. No real entry or brief has this (probe4).
**Location:** `scripts/dev-cycle.sh:268-269` and `:365-366`; documented at `:264` and `:327-329`
**Move:** 3 / 8 (the documented contract vs. behavior)
**Confidence:** High (reproduced)
**Legibility-target:** maintainer, agent

**Evidence:** In the code, `/^(```|~~~)/ { fence = substr($0, 1, 3); next }` opens a fence and `fence != "" { if (substr($0, 1, 3) == fence) fence = ""; next }` closes it. The comment says "a fence closes only with the characters that opened it". probe3:
- N1: an entry with ```` ```` ```` / ```` ``` ```` / `Q-001: [1]` / ```` ``` ```` / ```` ```` ````, then the real `Q-001: [2]`. Output: `keep Q-001`.
- N2: a brief with the same nesting around `Status: done`, then the real `Status: open`. Output: `ok docs/working/briefs/2026-01-01-a.md done ba9bf12…`.

The opener ```` ```` ```` is stored as ```` ``` ````, so the inner ```` ``` ```` closes it. The quoted example is then read as the answer, or as the status. In CommonMark the inner line is content, and only a closing fence at least as long as the opener closes it. This refutes the brief's claim 1 bar ("never a wrong keep/drop/done") for this input class. The behavior is pre-existing: 10c2809's toggle gave the same result. Pass-26 api Finding 5 said "Match fences by marker and length if parity matters". The fix matched by kind only. A wrong `done` closes and moves a live brief, and a wrong `keep` resets its `Kept:` date.

**Recommendation:** Store the whole run of the opening marker (`match($0, /^(`+|~+)/)`, keep `RLENGTH` and its character). Close only on a line that starts with at least that many of the same character and has nothing else after it but spaces. Apply this to both awk programs, and add the N1 and N2 cases to the bats file.

#### 3. The printed `<commit>` is the last commit touching any `Status: ` line, not "the brief's Status line"

**Severity:** Minor. Preconditions: a brief whose body has a second line starting `Status: ` (fenced or not) that a later commit edits, or a brief moved back into place (a rename shows as an add).
**Location:** `skills/dev-cycle/SKILL.md:264-265`; `scripts/dev-cycle.sh:254-255`, `:271-274`
**Move:** 3 / 7
**Confidence:** High (probe2)
**Legibility-target:** agent, user

**Evidence:**
- Skill: "naming the commit it prints (the last commit on the default branch that changed the brief's Status line)".
- Comment: "The commit that last added or removed a Status line in the file there is printed: the commit that set the status".
- Help (`:32-33`): "the commit that last changed a Status line there".
- Code: `git log -1 --format=%H -G'^Status: ' "$MAIN_SHA" -- "$a"`.

Probe2 results (status set by commit A in every case):

| Case | Change | Printed commit |
|---|---|---|
| P1 | later `Asked:` edit | A (correct) |
| P2 | a later commit adds a fenced `Status: example` | that commit (C), not A |
| P3 | a later commit adds a second unfenced `Status: later note` | that commit (D) |
| P4 | `--no-ff` merge | the side commit E, not the merge (correct) |
| P6 | a commit that only moved the brief back from `closed/` | the move commit (H) |

`-G` is a pickaxe over every added or removed line in the file. It does not know which line the status reader chose, or whether a line was fenced. The help's "a Status line" is accurate. The skill's "the brief's Status line" and the comment's "the commit that set the status" claim more than that. The impact is limited to evidence: Done names the wrong commit, and no routing changes.

**Recommendation:** Change the skill to the help's wording ("the last commit on the default branch that added or removed a line starting `Status: `"), and fix the comment the same way. Or narrow the code: walk `git log --format=%H -- path`, and print the first commit whose parent's status (as the awk reads it) differs. That costs more and needs a test.

#### 4. `--help` still defines `unrecognized` as a bad answer, but it now also reports a fence problem, including a closed bash block with a `# comment`

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:48-50` (help); `:325-329` (comment); `:363`
**Move:** 3 (documentation drift)
**Confidence:** High (probe2b Q-001, Q-002; bats test at `:745-762`)
**Legibility-target:** user, agent

**Evidence:**
- Help: "open (not marked ANSWERED yet) or unrecognized (answered, but the answer does not start with one of the options)".
- Code: `/^(#|##|###) / { if (inside && fence != "") broken = 1; inside = 0 }`.
- probe2b Q-002, a closed ```` ```bash ```` block holding `# comment`, then `Q-002: [2]`. Output: `unrecognized Q-002`.
- probe2b Q-001, a valid `Q-001: [1]` followed later by an unclosed fence. Output: `unrecognized Q-001`.

The function comment documents both cases. The help does not. The help is what the skill and the user read. The comment also says a heading inside a fence "can only lose an answer", but the reading is `unrecognized`, not a lost or `open` answer. The skill then adds the ID to `Applied:` and reports "unrecognized" in the record and final message. The user sees that a valid `[2]` was "not one of the options", when the cause was the file's shape. This is fail-safe: no wrong option is read.

**Recommendation:** Extend the help's definition: "unrecognized (answered, but the answer does not start with one of the options, or a fence in the entry is left open or holds a heading-shaped line such as a shell `# comment`)". Change "can only lose an answer" to "reads unrecognized".

#### 5. The Close step's final-message list leaves out `unrecognized`, which step 6.2 sends there

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:356-358` vs `:283-284`
**Move:** 7 (asymmetry)
**Confidence:** Medium. "Could not read" might be meant to cover it.
**Legibility-target:** agent

**Evidence:**
- Step 6.2: "`unrecognized` goes in the record and the final message".
- Close: "any keep-or-drop answer step 6 could not read or that is still `open` (with its brief)".

7f3e392 aligned `open` across the two lists (pass-26 Finding 7). The Close list now names the skip case ("could not read") and `open`. It does not name `unrecognized`, which the script defines as answered and read, but not an option. An agent writing the final message from the Close paragraph alone drops it. Finding 4 makes this more likely to matter.

**Recommendation:** Say "any keep-or-drop answer step 6 could not read (`skip`), could not recognize (`unrecognized`), or that is still `open`, each with its brief".

#### 6. In flight is still defined as "an open build brief", while membership now follows the slot rule

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:261`; `:81-87`
**Move:** 2 (naming against the grain)
**Confidence:** Medium
**Legibility-target:** agent

Precedent: "holds a slot" used in `skills/dev-cycle/SKILL.md:81-84`, `:162`, `:311`, `:340`, `:358`

**Evidence:**
- `:261`: "**In flight**: items with an open build brief, each naming its brief path."
- `:86-87`: "A brief that holds a slot but that no In flight line names gets one".
- `:82-84`: "when the glob lists it … a brief the check skips keeps its slot (recorded)".

The orphan rule adds every slot-holding brief to In flight. That includes one that `--check-brief` skips, which is not known to be open. In flight's own definition still uses the older "open" term this round removed elsewhere. Pass 26's Finding 4 also asked to state "that the glob's `ok` lines are what 'lists' means". That was not done. The glob also prints `skip <path>: reached through a symlink…` lines, and the text does not say whether such a line "lists" the brief.

**Recommendation:** Define In flight as "items whose brief holds a slot (as in the Rules), each naming its brief path". Write "when the glob prints `ok <path>` for it".

#### 7. No check backs "no In flight line names it", and the skill's own path forms differ

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:85-87`, `:261`
**Move:** 3
**Confidence:** Medium
**Legibility-target:** agent, user

**Evidence:**
- "pointed at `briefs/closed/<same name>`".
- "A brief that holds a slot but that no In flight line names gets one".
- In flight lines are "each naming its brief path" (free form).

The brief asks which check proves "no In flight line names it". None does. It is a prose string match between the glob's `ok docs/working/briefs/<name>.md` lines and whatever form the roadmap lines use. The skill's own correction writes the short form `briefs/closed/…`. If In flight lines use short forms, an exact-match agent finds no match, adds duplicate lines, or misses a stale one. The user's rule is that mechanical rules for repo text live in tested code, and this match is mechanical.

**Recommendation:** Require the full path the checks print (`docs/working/briefs/…`) in In flight lines, including after the closed/ correction. Optionally, add an In flight cross-check to the digest's section 5 (briefs listed by the glob vs. paths on In flight lines).

#### 8. A tip date "after today" includes a commit made today in a time zone ahead of the runner

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:298-299`; `scripts/dev-cycle.sh:283-284`
**Move:** 8
**Confidence:** Medium
**Legibility-target:** agent

**Evidence:**
- Skill: "A tip date after today is recorded and counts as idle (the committer sets the date)".
- Help comment: "YYYY-MM-DD in the committer's own time zone (as the committer set it: a future date is possible)".

The most common source of a "future" `%cs` is not a skewed clock. It is a commit made today by a committer whose zone is past midnight relative to the runner. That branch is active, yet it counts as idle. The rule only applies 14 days after the last `Kept:`. The fail direction is one extra keep-or-drop question, so the impact is small.

**Recommendation:** Optional. Count as idle only a tip date more than one day after today, or say in the record that a one-day lead is usually a time zone.

#### 9. `check_branch`'s "when one was found by name" guard is now always true

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:285`, `:291`
**Move:** 3
**Confidence:** High
**Legibility-target:** maintainer

**Evidence:**
- `# The default branch, when one was found by name, is refused.`
- `elif [[ -n "$MAIN_BY_NAME" && "$a" == "$MAIN" ]]`.
- The gate at `:428` exits before `--check-branch` runs unless `MAIN_BY_NAME` is set (probe2b U1/U2: `--check-branch needs a default branch …`, rc 1).

The qualifier describes a case that can no longer happen. This is harmless, but it suggests to a maintainer that `--check-branch` runs without a named default branch.

**Recommendation:** Drop the qualifier from the comment. Keep the guard as defense in depth, or note that it is one.

#### 10. The two questions-header readers still differ on fields after `Status:`

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:367`; `scripts/questions.sh:171-181`
**Move:** 7
**Confidence:** High (probe2b Q-004)
**Legibility-target:** maintainer

**Evidence:**
- A header `… · **Status:** ANSWERED · **Answered:** 2026-01-02` reads `open Q-004` under `/ \*\*Status:\*\* ANSWERED$/`.
- `questions.sh` splits on ` · ` and sets `status = "ANSWERED"`, so it would archive the entry, and `check` would pass it.

Pass-26 Finding 8 said to anchor both readers on the exact field. Only `--check-answer` changed. The result is fail-safe (`open`, then listed in the final message), and no real header has a trailing field (probe4: 0 of 102).

**Recommendation:** None needed now. If the grammar ever gains a field after `Status:`, change both readers together.

## What Looks Good

- **The default-branch gate is scoped correctly (pass-26 Breaking 1 fixed).**
  - In an unborn `trunk` repo (U1), `--check-path`, `--check-write`, `--check-fix` and `--check-answer` answer with rc 0.
  - In the same repo, `--check-brief` and `--check-branch` print `<flag> needs a default branch (origin/HEAD, main or master); found none` and exit 1, which matches the `<flag> needs …` convention.
  - The digest still refuses with "Could not resolve a default branch".
  - On a detached HEAD with only `trunk` (U2), the results are the same.
  - A grep shows `MAIN_SHA` is read only in `check_brief` (`:261-274`), `check_branch` (`:295`) and the digest (`:482` on). None of the four ungated modes uses the empty value.
  - The help's `:53-54` sentence and the skill's "A check that exits non-zero (no default branch, say) is recorded" agree with this. The rule is correct and complete.
- **The ANSWERED gate is correct against the real files.** All 102 IDs (7f3e392's files) and all 99 (`/workspace`'s) read identically at 10c2809 and b00c057. Every real header ends in exactly ` **Status:** OPEN|ANSWERED`, so the `$` anchor changes nothing on real data. The anchor also refuses `OPEN (was **Status:** ANSWERED)` (bats `:777`).
- **The pass-26 fence regression is fixed for every case pass 26 probed.** Entries are bounded by headings again. An unclosed fence reads `unrecognized` and never another entry's answer. A fenced copy of an entry makes the ID `dup` (bats `:812-827`). Finding 2's longer-fence case is the only remaining wrong reading I found.
- **`-G` gives the intended commit in the common cases.** These are a later `Asked:`/`Applied:` edit on the default branch (P1, bats `:799-810`), a `--no-ff` merge that brought the status in (P4), and a CRLF line (P7). The whole-blob read fixes the SIGPIPE exit (bats `:799`, 200 KB brief). The fallback to the last commit touching the file only fires in histories where `-G` finds nothing (shallow or binary). It keeps the output shape.
- **`INSTRUCTION_FILE` now follows the listed-characters convention**, and `agents?` covers `AGENT.md` (pass-26 Finding 6 fixed).
- **The slot term is now used in the record template, step 1, Build briefs and the final message** (pass-26 Finding 4 fixed, apart from Finding 6). "List it in the final message with its brief" removes the date that no interface provided (pass-26 Finding 2 fixed). Done's commit wording now matches what Done lists (`:304-305`).
- **The help range `sed -n '2,62p'` is still correct**: the one added comment line kept line 62 as the blank before `set -euo pipefail`.
- **The commit messages hold up.** For b00c057:
  - 44/44, shellcheck and lint are clean.
  - The 102 IDs read unchanged.
  - The fence, gate and `-G` claims match the probes, apart from Findings 2 and 3.

  7f3e392's bullets each match a diff hunk.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The stale-line fix points In flight at `closed/`, which `--check-brief` always skips, so the item never leaves | Inconsistent | `SKILL.md:84-87, 263-266`; `dev-cycle.sh:258` | High (outputs) / Medium (agent behavior) |
| 2 | Fences close on 3 characters, not length: a nested fence yields a wrong `keep` / `done` | Inconsistent (needs a longer outer fence; none in real data) | `dev-cycle.sh:268-269, 365-366` | High |
| 3 | `-G` names the last commit touching any `Status: ` line (fenced, second line, a move), not "the brief's Status line" | Minor | `SKILL.md:264-265`; `dev-cycle.sh:254-255, 271-274` | High |
| 4 | `--help`'s `unrecognized` omits the fence cases, including a closed bash block with `# comment` | Minor | `dev-cycle.sh:48-50, 325-329, 363` | High |
| 5 | The Close list omits `unrecognized`, which step 6.2 sends to the final message | Minor | `SKILL.md:356-358` vs `:283-284` | Medium |
| 6 | In flight is still "an open build brief"; "glob lists it" is undefined for skip lines | Minor | `SKILL.md:261, 81-87` | Medium |
| 7 | No check backs "no In flight line names it"; short vs full path forms | Informational | `SKILL.md:85-87, 261` | Medium |
| 8 | A "future" tip date is usually a time zone ahead, not skew | Informational | `SKILL.md:298-299` | Medium |
| 9 | `check_branch`'s found-by-name qualifier is now always true | Informational | `dev-cycle.sh:285, 291` | High |
| 10 | The header readers still differ on trailing fields | Informational | `dev-cycle.sh:367`; `questions.sh:171-181` | High |

## Overall Assessment

The pass-26 fixes hold where pass 26 aimed them. The default-branch gate now covers exactly the two modes that read the default branch. The four other modes work in unborn and detached repos and never touch an empty `MAIN_SHA`. The anchored ANSWERED gate changes no reading on the 102 real IDs. Headings bound entries again, so no other entry's answer leaks in. The output shapes, error messages and help range are all consistent with the established check-mode conventions.

Two contracts are still weaker than their text:
- **Finding 1 (skill).** The stale-line correction moves an In flight line to a `closed/` path that In flight's own first check refuses. The item is stranded, and the slot sentence can be read as keeping it.
- **Finding 2 (both readers).** Fence matching by first three characters still reads a quoted example inside a longer fence as the answer or the status. That gives a wrong `keep`, or a wrong `done` that closes a live brief. Its precondition is absent from all real data.

Both are fixable in place: an `isbrief` or skill-wording change for 1, and length-aware fence tracking plus two tests for 2. The rest are wording alignments between the help, the comments and the skill: the `-G` commit's meaning, `unrecognized`'s definition, the final-message list and the In flight definition. None suggests the author skipped the conventions.

## Goal-Alignment Note

Success criterion (verbatim from the brief): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-02-digest-pass27.md`. Its first line is `Commit: b00c057 (A) / 7f3e392 (B)`. It follows the api-consistency-reviewer structure: header, Baseline Conventions, Name-Pattern Audit, Findings, What Looks Good, Summary Table and Overall Assessment. Every finding that cites a location carries Severity, Location, Evidence (verbatim), Confidence and Legibility-target. Naming-shaped Finding 6 carries a `Precedent:` line. The report covers:

- the check modes' interface, output and help after this round (the narrowed gate, the commit semantics of `--check-brief`);
- the skill's instructions against what the checks print (orphan briefs, stale lines, the final message, slot wording);
- `--check-answer` against the real answer lines (102 and 99 IDs, unchanged).

It was not committed. The probes wrote only under `api27/`, and nothing outside it was changed.
