Commit: 366efd7 (A) / b73069e (B)

# API Consistency Review — dev-cycle pass 28 (pass-27 fix round)

**Scope:** A: `git diff b00c057..366efd7 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree `wt-digest`); B: `git diff 7f3e392..b73069e -- skills/dev-cycle/SKILL.md` (worktree `wt-devcycle`, merge d535260). Partial scope: everything else is context only.
**Date:** 2026-10-02
**Based on:** `docs/reviews/code-fact-check-report-digest-pass27.md` (Stage-1 context), shared brief for pass 28.

Probes: two scripts under the scratch dir `api28/` (`probe1.sh`, `probe2.sh`), each following the brief's probe rule (`set -eu`, own `mktemp -d`, `$PWD` guard, every process under `timeout`). Scripts were taken with `git show 366efd7:` / `b00c057:` into the temp dir; nothing was written to either worktree except this report. `bats test/scripts/dev-cycle.bats`: 46/46 ok. `python3 scripts/hermeticity-lint --root .`: clean. awk is mawk 1.3.4; git 2.39.5.

## Baseline Conventions

- **Check-mode output**: one line per argument, `ok <arg> [fields…]`, `absent <arg>`, `<option> <id>` (for `--check-answer`), or `skip <arg>: <reason>`. A skip is an answer (exit 0). Exit 1 only for usage or environment errors. Unchanged this round.
- **Help is the header comment** (`sed -n '2,Np'`), wrapped at about 80 columns, one block per mode stating the accepted input form and every output shape.
- **Embedded awk programs** are shell variables named `<PURPOSE>_AWK` (`ANSWER_AWK`), with short lowercase awk function names (`option`, `heading`).
- **Default-branch reads** use first-parent history with `--diff-merges=first-parent` (the digest's section-7 query at `scripts/dev-cycle.sh:682` sets the precedent).
- **The questions header** is written by `questions.sh` as `**Needs:** <route> · **Opened:** <date> · **Status:** OPEN|ANSWERED`, and `questions.sh` reads it by splitting on ` · ` (last `Status:` field wins, the whole field is the value).
- **Skill wording**: state comes only from the check modes; every skip is recorded; the final message lists what needs the user.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `FENCE_AWK` | shell var holding awk code | `ANSWER_AWK` | `scripts/dev-cycle.sh:365` | Consistent: `<PURPOSE>_AWK` shape |
| `lead`, `run`, `opens`, `closes` | awk functions | `option`, `heading` | `scripts/dev-cycle.sh:366-383` | Consistent: short lowercase names, locals declared after extra spaces |
| `fch`, `flen`, `infence` | awk globals | `count`, `inside`, `header`, `done`, `broken` (replaces `fence`) | `scripts/dev-cycle.sh:386-418` | Consistent: lowercase flag and counter globals |
| `skip <path>: not a build brief (docs/working/briefs/[closed/]YYYY-MM-DD-<slug>.md)` | printed skip reason (renamed from `not an open build brief (…)`) | `not one of the dev cycle's own files`, `not an allowed path form` | `scripts/dev-cycle.sh:243-247, 278-281` | Consistent. The rename breaks no consumer: `rg` outside `docs/reviews/` finds the string only in the script and its two updated bats assertions |
| `docs/working/briefs/[closed/]YYYY-MM-DD-<slug>.md` | help input form | `writable()`'s closed/ regex | `scripts/dev-cycle.sh:241-245` | Consistent: the same regex shape as `--check-write`'s closed/ rule |

No other new public names (no new flags, modes or output fields).

## Findings

#### 1. `--help` now says `unrecognized` means "no answer line starts with one of the options", but only the first answer line is read

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:47-51` (help); behaviour at `scripts/dev-cycle.sh:400-413` (`!done` rule); skill `skills/dev-cycle/SKILL.md:290-291`
**Move:** 3 (consumer contract: documentation drift)
**Confidence:** High
**Legibility-target:** the `--check-answer` help block, read by the skill author and by any agent deciding whether a second reply will be picked up.

**Evidence:**
- Help: `open (not marked ANSWERED yet) or unrecognized (answered, but no` / `answer line starts with one of the options, or a fence in the` / `entry is left open); "skip Q-NNN:` (the block continues with the skip reasons).
- Code: `if (index(line, id ":") == 1) { result = option(substr(line, length(id) + 2)); done = 1; next }` inside `!done { … }`: the first answer-shaped line sets `done`, so no later line is read.
- Probe2: entry `Q-1: maybe` then `Q-1: [2]` prints `unrecognized Q-1`, although an answer line (`Q-1: [2]`) does start with an option.
- Skill: `` `unrecognized` goes in the record and the final message (the user answers on the next keep-or-drop entry, which step 3 files; a second reply on this one is not read) ``.

The old wording ("the answer does not start with one of the options") matched the first-line rule; the new wording reads as "any answer line", which contradicts the code, the internal comment at :355-357 ("the answer is the first line in the entry … that starts …") and the skill. Precondition: an answered entry with a non-option first answer line followed by an option line. None of the 102 real IDs changed.

**Recommendation:** "unrecognized (answered, but its first answer line does not start with one of the options, or there is none, or a fence in the entry is left open)".

#### 2. The In flight definition (by slot) excludes the very briefs check 1 exists to resolve

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:266-267` with `:83-86`
**Move:** 7 (asymmetry between a definition and the steps it governs)
**Confidence:** Medium (the text contradiction is certain; whether an agent would act on the literal reading is not)
**Legibility-target:** the In flight bullet, read by the cycle agent deciding which roadmap lines to check.

**Evidence:**
- In flight: `items whose brief holds a slot (as in the Rules), plus any line being resolved after its brief moved to `closed/`, each naming its brief path.`
- Slot rule: `**A brief holds a slot** when the glob prints `ok` for it (its skip lines are only recorded) or this cycle wrote it, unless it is under `closed/` or `--check-brief` prints `done` or `dropped` for it;`
- Check 1: `` `--check-brief` prints `done` … → Done, … Either way, create `docs/working/briefs/closed/` if it is missing, `git mv` the brief there``.

A brief still at `briefs/` whose merged change set `Status: done` holds no slot, so by the definition its line is not an In flight item. The "plus" clause covers only briefs already under `closed/`. Read literally, check 1's main case (done or dropped, not yet moved) is unreachable, and the line has no defined home. Pass 27's finding 6 asked for the definition to follow the slot rule; the fix followed it one step too far.

**Recommendation:** define In flight by what is still unresolved: "items whose brief holds a slot or whose `--check-brief` state check 1 has not yet resolved (done or dropped briefs not yet moved, and lines pointed at `closed/`)".

#### 3. For a brief moved into `closed/` in its own commit, the printed commit is the move, not "the merge that brought the status in"

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:81-82, 270-271, 312-313`; help `scripts/dev-cycle.sh:29-34`; code `scripts/dev-cycle.sh:298`
**Move:** 3 (contract wording vs output)
**Confidence:** High (probe1 P2)
**Legibility-target:** Done's commit, read by the user auditing which change shipped a brief.

**Evidence:**
- Skill: `→ Done, naming the commit it prints (for merged work, the merge that brought the status in).` and `(the commit is the default branch's own commit that last changed a `Status:` line there; for merged work, the merge)`.
- Code: `c="$(git log -1 --format=%H --first-parent --diff-merges=first-parent -s -G'^Status: ' "$MAIN_SHA" -- "$a")"`.
- Probe1 P2: status set on `feat/m`, merged as `c16234f…`, then `git mv` to `closed/` in `c7de718…` ("move to closed"): `ok docs/working/briefs/closed/2026-01-01-m.md done c7de718d9a167565486671cefc30b4016ae48a65`. With the status change and the move in the same merge (`feat/t`), the merge `6846dd7…` is printed, which is correct.

With a single pathspec, git sees the rename as an add of the whole file, so every `Status: ` line counts as added. The help's literal wording ("its own commit … that last added or removed a "Status: " line there") is true. The skill's gloss is not. This is exactly the path the round added: a stale In flight line gets pointed at `closed/`, then check 1 records Done with the move commit (a hand move, or a cycle's chore landing) as the work's commit. Precondition: the brief was moved in a commit other than the one that set its status.

**Recommendation:** either say so in the skill ("for a brief moved to `closed/` after its status was set, the move") or, for a `closed/` path, add `--follow` (with a single path it follows the rename) so the merge is found. Whichever is chosen, add a bats case that pins it.

#### 4. A `closed/` brief whose state is `open` (or `new`) has no defined outcome, and step 3 says it holds a slot

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:85, 266-267, 281-303`
**Move:** 7 (asymmetry) / 3
**Confidence:** Medium
**Legibility-target:** In flight checks 1–3, read by the cycle agent once a stale line has been pointed at `closed/`.

**Evidence:**
- Probe1 P2: an open brief moved by hand: `ok docs/working/briefs/closed/2026-01-04-u.md open a4ba3db…`. The old path gives `skip … no tracked file …` and the closed/ path gives `ok …`, so the stale-line rule points the roadmap line there.
- Check 1 fires only on `done`/`dropped`. Checks 2–3 (`If the brief is still open, …`) then run keep-or-drop on it, and step 3 says `Until it is answered, the brief still holds its slot.`
- Rules: `… unless it is under `closed/` …` (no slot).

The flow never moves a brief twice (`a brief already under `closed/` stays`) and never points a line at a removed path (it is pointed only on `--check-path` `ok`). Both points the brief asked about hold. But an open brief under `closed/` is In flight indefinitely through the "plus" clause, may be asked keep-or-drop, holds no slot despite step 3's sentence, and is not listed in the final message ("each brief holding a slot by path"). A `new` state for a `closed/` path (working tree and default branch differ) has no rule at all. Precondition: a brief moved to `closed/` without its status line set, by hand or by a build session.

**Recommendation:** one sentence in check 1: "a brief under `closed/` whose state is `open` or `new` is recorded and goes to the final message (moved without its status set); it holds no slot and is not asked keep-or-drop."

#### 5. The `ANSWER_AWK` comment still says the header "ends with ` **Status:** ANSWERED`"; the code now reads the first field

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:346-350`
**Move:** 3 (documentation drift, internal)
**Confidence:** High
**Legibility-target:** maintainers reading the answer rule's comment.

**Evidence:** `# An entry is answered only when its header line (the first line starting` / `# "**Needs:**", as questions.sh writes it) ends with " **Status:** ANSWERED";` and two lines later `# it has been recorded. Its status is the first "**Status:** " field of that` / `# line, up to the next space.` Probe1 Q-12 (`**Status:** ANSWERED · **Note:** x`) prints `drop Q-12`, so a header that does not end with ANSWERED is read as answered.

**Recommendation:** replace "ends with …" with "whose first `**Status:** ` field is `ANSWERED`".

#### 6. The header read still differs from `questions.sh` on malformed headers

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:395-399`; `scripts/questions.sh:174-180`
**Move:** 1 / 7
**Confidence:** Medium
**Legibility-target:** maintainers keeping the two header readers in step.

**Evidence:** questions.sh: `n = split(line, f, " · ")` … `if (f[i] ~ /^Status:/) { status = substr(f[i], 9) }` (last field wins, whole field is the value). dev-cycle: `p = index(v, "**Status:** ")` … `if (q) v = substr(v, 1, q - 1); answered = (v == "ANSWERED")` (first occurrence, up to a space). Probe1: `**Status:** ANSWERED (2026-10-01)` gives `drop Q-10`; questions.sh's status there is `ANSWERED (2026-10-01)`, which its `check` rejects (`:269`) and `archive` never moves. `**Status:** OPEN · **Status:** ANSWERED` gives `open Q-11` (questions.sh reads ANSWERED). Precondition: hand-edited, malformed headers. All 102 real IDs are unchanged. Pass 27's Informational 10 narrowed the gap; this is what remains.

**Recommendation:** none needed now. If touched again, take the same field rule (` · `-split, `Status:` field equals `ANSWERED`).

#### 7. Help's gloss for `new` describes only a `briefs/` path

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:29-31`; `skills/dev-cycle/SKILL.md:82-83`
**Move:** 3
**Confidence:** High
**Legibility-target:** `--help` readers passing a closed/ path.

**Evidence:** `"ok <path> new" when the default branch has no file` / `there (not landed, or moved to closed/)`. For a `closed/` path (now accepted), `new` means it has not been moved there on the default branch. The skill's `(not landed yet, or already moved)` fits both only loosely.

**Recommendation:** "(not landed; for a `briefs/` path, moved to `closed/`; for a `closed/` path, not moved there yet)".

#### 8. Cosmetic: the help range now ends on a blank line, and the Exit line is unwrapped

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:63-64, 127`
**Move:** 1
**Confidence:** High
**Legibility-target:** `--help` output.

**Evidence:** `-h|--help) sed -n '2,64p' "$0"`. Line 63 is the last comment line and line 64 is empty (probe1 P4 shows a trailing `$`). Line 63, `# default branch (for the digest, --check-brief and --check-branch); a failed step exits non-zero mid-digest. Printed repo text is data.`, is about 130 columns, against the roughly 80-column wrap of the surrounding help. The range shows the whole help, so nothing is lost.

**Recommendation:** `2,63p` and re-wrap line 63.

#### 9. "A day covers time zones ahead" does not quite cover UTC+14 against UTC−12

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:306-307`
**Move:** 8 (edge of a contract)
**Confidence:** Medium
**Legibility-target:** the cycle agent judging idleness.

**Evidence:** `A tip date more than a day after today is recorded and counts as idle (the committer sets the date; a day covers time zones ahead of the cycle's).` Zone offsets span 26 hours, so for up to two hours a fresh commit's committer-local date can be today+2. Precondition: extreme zones on both sides. The effect is one cycle's spurious "idle" and a recorded line.

**Recommendation:** "more than two days", or leave the wording and drop the claim in parentheses.

## What Looks Good (rules checked, correct and complete)

- **CommonMark fences** (`FENCE_AWK`, both readers). Probe1: four-backtick around three-backtick (`drop Q-1`), a backtick in a backtick info string is not a fence (`drop Q-2`), a tilde fence with a backtick info string is one (`keep Q-3`), a 4-space indent is not a fence (`drop Q-4`), a 3-space indented opener and a closer with trailing spaces (`keep Q-5`), a closer with text does not close (`keep Q-6`), a shorter closer leaves a 4-fence open (`unrecognized Q-7`), `## ` inside a fence does not end the entry (`drop Q-8`), `### Q-NNN ` does (`unrecognized Q-9`), CRLF (`drop Q-13`). The brief reader agrees: bats 45 and the test at 46.
- **Concatenation under mawk**: `"$FENCE_AWK$ANSWER_AWK"` and `"$FENCE_AWK"'…'` both parse under mawk 1.3.4 (all 46 tests run there). `fch`/`flen` are set only by `opens()` and read only by `closes()` while `infence`; `infence` is reset at the target heading.
- **First-parent `-G` lookup**: a `--no-ff` merge prints the merge (bats 46). A squash prints the squash commit. Status and move in one merge print that merge (probe1 P2). `-s` does not disable the `-G` filter on git 2.39.5. On renames, see finding 3.
- **102 real IDs**: `--check-answer Q-001…Q-102` against `/workspace` main's questions files gives byte-identical output for b00c057 and 366efd7 (`SAME`; 3 done, 19 drop, 23 keep, 12 open, 42 unrecognized, 3 skip).
- **`--check-branch` refusing the default branch unconditionally** is safe: without a default branch found by name the mode exits 1 before it runs (probe2: `--check-branch needs a default branch …; found none`, rc 1), so `$MAIN` is always the named branch there. Probe1: `skip main: the default branch`.
- **Exit line**: accurate. Probe2 on a `trunk`-only repo: `--check-path` and `--check-answer` rc 0; `--check-brief` and `--check-branch` rc 1; the digest on a detached HEAD exits 1 with "Could not resolve a default branch".
- **closed/ in `--check-brief`**: accepted with the same regex as `--check-write`. The renamed skip reason has no consumer outside the bats file.
- **Skill B**: the glob never lists `closed/` (`:(glob)` `*` does not cross `/`; probe1 P2 listed only `2026-01-02-s.md`), so the closed/ exemption matters only for briefs this cycle moved, and it is harmless. No step moves a closed brief twice. A roadmap line is never pointed at a path `--check-path` refused. The final message now lists `could not read` / `unrecognized` / `open`, exactly the three cases step 2 sends there. Glob skip lines are recorded only, consistent with `--check-brief` skips keeping their slot.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| 1 | Help defines `unrecognized` as "no answer line starts with an option"; only the first answer line is read | Minor | `scripts/dev-cycle.sh:47-51` | High |
| 2 | In flight defined by slot excludes done/dropped briefs not yet moved, the case check 1 resolves | Minor | `SKILL.md:266-267, 83-86` | Medium |
| 3 | Closed/ brief moved in its own commit: printed commit is the move, not the merge the skill promises | Minor | `SKILL.md:81-82, 270-271`; `dev-cycle.sh:298` | High |
| 4 | A closed/ brief that is `open`/`new` has no defined outcome; step 3 says it holds a slot | Minor | `SKILL.md:85, 266-267, 302-303` | Medium |
| 5 | `ANSWER_AWK` comment still says "ends with … ANSWERED" | Minor | `dev-cycle.sh:346-350` | High |
| 6 | Header read differs from questions.sh on malformed headers | Informational | `dev-cycle.sh:395-398`; `questions.sh:174-180` | Medium |
| 7 | Help's `new` gloss fits only a briefs/ path | Informational | `dev-cycle.sh:29-31` | High |
| 8 | Help range ends on a blank line; Exit line unwrapped | Informational | `dev-cycle.sh:63-64, 127` | High |
| 9 | "A day" does not cover the full zone span | Informational | `SKILL.md:306-307` | Medium |

## Overall Assessment

The pass-27 fixes land. Both readers now share one CommonMark fence rule that every pass-27 probe case reads correctly. `--check-brief` reads `closed/` paths and names the merge for merged work. `--check-branch`'s guard and the Exit line are accurate. The 102 real IDs are unchanged. Nothing is Breaking or Inconsistent. What remains is wording, fixable in place: the help's new `unrecognized` definition overstates what is read (1); the skill's In flight definition, made to follow the slot rule, now formally excludes the done and dropped briefs check 1 handles (2); the `closed/` path the round opened prints the move commit when the move came later (3) and has no rule for an `open` state (4); and one stale internal comment (5). Consumer impact is low: each needs a hand move, a malformed header or a literal reading against obvious intent. Findings 1, 2 and 5 are one-line edits; 3 needs a choice (document it, or `--follow`) plus a test.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-02-digest-pass28.md` with the required first line, and follows the skill's structure: header, Baseline, Name-Pattern Audit, Findings with Severity/Location/Evidence/Confidence/Legibility-target, What Looks Good, Summary Table and Overall Assessment. No naming findings were raised, so no Precedent lines are required. It is not committed. Probes stayed in `api28/` temp dirs; neither worktree was changed except for this file.
