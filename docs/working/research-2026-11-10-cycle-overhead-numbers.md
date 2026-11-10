# Research: what the dev cycle costs per iteration (numbers for the light-pass decision)

- **Goal**: Give the owner, from the repo's own records and history, how many dev-cycle iterations ran since 2026-10-16, how many found or changed anything outside their own bookkeeping, and what each kind cost, so they can decide the light pass.
- **Problem framing**: The owner chose a full cycle every iteration for now and a light pass "once the costs are visible", and nobody has totalled the costs. Considered and discarded: "the cycle is too slow" (wall time turns out to be minutes per iteration; what is unknown is tokens, which no record holds).
- **Project state**: this branch delivers one research doc, docs only · the first step of roadmap Next 3 (revisit the light pass), the later skill change being a separate unit · not blocked (cite: docs/working/briefs/2026-11-10-cycle-overhead-numbers.md)
- **Task status**: complete (two review rounds; see Review)

Brief: `docs/working/briefs/2026-11-10-cycle-overhead-numbers.md` (self-merge, docs only).
Everything here was read at main's commit a37733cc. Nothing was run to measure cost.

Words used below.

- An **iteration** is one `## Iteration` block in a cycle record
  (`docs/working/cycles/cycle-*.md`). Its name is the UTC time it began.
- **Steps 2, 3, 4 and 4b** are the dev-cycle skill's four checking steps: revisit triggers
  (has a recorded decision's "look again when" condition come true?), watched questions
  (has a parked question's condition been met, and is any agent work item stale?), the
  claim spot-check (do the claims of one or two recent merges still hold?) and the
  deep-audit check (is a full re-read of the repo's history due?).
- A **drift finding** is one result of the spot-check: a build loop's design record ruled
  an option out on a soft constraint, or decided by a rule that `docs/constraints.md` does
  not hold.
- A **light pass** is an iteration that skips the checking steps and only collects
  build-loop results, writes briefs, dispatches and lands (steps 7, 8 and 10).
- **Q-154** is the archived owner entry where the owner chose a full cycle every iteration
  for now, and a light pass "once the costs are visible".
- A **land** is the merge commit that puts an iteration's bookkeeping on main. A **loop
  merge** is a build loop's branch merged to main, approved by the owner or self-merged.
- `Main at:` is the record line naming the commit main was at when the iteration began.
- `[observed]`, `[inferred]` and `[assumed]` say how a claim is known: read or run
  directly, derived from what was read, or believed but not checked.

## Summary

1. **100 iterations** are recorded, named 2026-10-16 to 2026-11-10 (UTC). They fall on 16
   of the owner's working days: a median of 5 a day, 17 on the busiest day.
2. **The cycle has not run a full cycle every iteration.** 72 iterations ran the four
   checking steps. 24 were light passes: 22 the orchestrator chose, with no rule for it in
   the skill, and 2 the owner directed. 4 stopped at the start check. Of the 72 "full"
   ones, 27 wrote one line for all triggers ("as at iteration X") where the skill asks for
   each to be decided again.
3. **40 of the 72 full iterations (56%) were quiet**: the checking steps produced nothing.
   10 more (14%) only re-fired the deep-audit check onto a task that already existed. 22
   (31%) produced something. Counted in iterations: a trigger newly fired in 3, a watch
   was met in 2 (the same watch twice), a claim failed in 2, a drift finding came in 7,
   another finding in 5, a deep-audit task was filed in 6, and a stale item was fixed or
   sent on in 7.
4. **Wall time is small in total: about 16 hours over 26 days.** By commit times a full
   iteration took a median of 7.7 minutes and a light one 2.9. A quiet full iteration took
   3.8, and 2.4 when its health check did not re-run, which is no longer than a light
   pass. Wall time is not tokens: the checking steps may run as parallel subagents.
5. **Tokens are not recorded anywhere in this repo.** The cost the owner asked about is
   still not visible. Section 6 names the smallest change that would record it.
6. **Bookkeeping against features**: the cycle's 129 lands changed 15,522 lines, all in its
   own files (records, questions files, briefs, the roadmap, the idea log). In the same
   period 42 loop merges changed 31,878 lines, 12,109 of them outside `docs/`.
7. **What a light pass would have missed depends on what brings the full cycle back.** If a
   full cycle ran whenever main gained anything but a cycle land, or on the first iteration
   of a day, 44 of the 96 full or light iterations would have been full, and 4 of the 22
   catches would have waited; on inspection 2 of those are real waits, of 1 and 3.8 hours.
   With one full cycle a day, 14 would have been full, and 15 catches would have waited a
   median of 18 hours; 9 of those came from spot-check sampling and might not have been
   found at all.
8. **The options for the owner are the last section of this file.**

## 1. Method and commands

Run these from the repo root at a37733cc. `83b653d2` is the `Main at:` commit of the first
iteration counted.

```sh
# iterations since 2026-10-16 (100), and per local day
rg -o -N -I '^## Iteration \S+' docs/working/cycles/ | awk '$3 >= "2026-10-16" {print $3}' | sort | wc -l
rg -o -N -I '^## Iteration \S+' docs/working/cycles/ | awk '$3 >= "2026-10-16" {print $3}' | sort \
  | while read -r i; do TZ=America/Los_Angeles date -d "${i:0:10} ${i:11:2}:${i:13:2} UTC" +%F; done | uniq -c

# the lines every hand classification below was read from
rg -n '^(0|1|2|3|4|4b|7)\. ' docs/working/cycles/
# verdict lines per iteration (20 or more: a full list; 1: one "as at" line)
awk '/^## Iteration/{id=$3} /^### /{s=$0} s=="### Trigger verdicts" && /^- /{n[id]++} END{for(i in n) print i, n[i]}' docs/working/cycles/cycle-*.md | sort

# main's own history: 233 commits, 129 cycle lands, 42 loop merges, so 62 others
git rev-list --first-parent --count 83b653d2..a37733cc
git log --first-parent --format='%s' 83b653d2..a37733cc | rg -c "^Merge branch 'chore/dev-cycle-"
git log --first-parent --format='%s' 83b653d2..a37733cc | rg -c '\(build-loop (approved merge|self-merge)\)$'

# wall time: seconds from the iteration's name (UTC) to its last land's commit time
git log --first-parent --format='%ct %s' 83b653d2..a37733cc \
  | sed -n "s/^\([0-9]*\) Merge branch 'chore\/dev-cycle-\([0-9-]*\)'.*/\2 \1/p" | sort -k1,1 -k2,2n \
  | awk '{t[$1]=$2} END{for (i in t) print i, t[i]}' | sort \
  | while read -r i t; do echo "$i $(( t - $(date -u -d "${i:0:10} ${i:11:2}:${i:13:2}" +%s) ))"; done

# lines the cycle landed (prints: 495 file changes, 12821 added, 2701 removed, then by file)
git log --first-parent --format='%H %s' 83b653d2..a37733cc | rg "^\S+ Merge branch 'chore/dev-cycle-" \
  | while read -r h _; do git diff --numstat -M "$h^1" "$h"; done \
  | awk -F'\t' '{a+=$1; d+=$2; k="other"
      if ($3 ~ /^docs\/working\/cycles\//) k="record"
      else if ($3 ~ /^docs\/working\/(questions|questions-archive|watching)\.md$/) k="questions"
      else if ($3 ~ /^docs\/working\/briefs\//) k="briefs"
      else if ($3 == "docs/roadmap.md") k="roadmap"
      else if ($3 == "docs/working/idea-log.md") k="idea log"
      n[k]+=$1+$2} END{print NR, a, d; for (k in n) print k, n[k]}'

# lines the loop merges landed (prints: 325 27349 4529, then 12109 outside docs/ and 19769 in it)
git log --first-parent --format='%H %s' 83b653d2..a37733cc | rg '\(build-loop (approved merge|self-merge)\)$' \
  | while read -r h _; do git diff --numstat -M "$h^1" "$h"; done \
  | awk -F'\t' '{a+=$1; d+=$2; if ($3 ~ /^docs\//) doc+=$1+$2; else code+=$1+$2} END{print NR, a, d, code, doc}'

# tokens: the first prints no file; the second lists every tracked file that holds a usage field
rg -il 'token' docs/working/cycles/ docs/working/weekly/
git grep -l -E 'input_tokens|total_cost_usd|num_turns'
```

Appendix A's Wall column is the wall-time command's seconds divided by 60, to one decimal,
with iteration 2026-11-02-1438 read as 06:47 UTC (its record says the name is mistyped).

Three things are read by hand, not by a command: what kind each iteration was, who started
it, and whether the checking steps produced anything. Appendix A lists all three for every
iteration, so each call can be checked against its record line. The rule for "produced"
is in section 3. The group medians, the "main moved" table and the replay in section 7
are computed from Appendix A by the script in Appendix B.

## 2. How many iterations, and how long they took

**Count.** 100 iterations, from 2026-10-16-0510 to 2026-11-10-1902, in 15 record files.
[observed] The count is of iterations that wrote a record. The skill says an iteration
that stops at its start check writes none, so any such iteration is not in this number.

**Kinds**, by what the record itself says: [observed]

| Kind | Count | What the record says |
|---|---|---|
| Full | 72 | Steps 2, 3, 4 and 4b each have a result line |
| Light | 24 | 20 say "light pass" (2026-10-31-2325 to 2026-11-02-1846), 2 say "a light iteration" (2026-10-17), 2 say "owner-directed merge pass" (2026-10-30) |
| Stopped | 4 | "skipped: step 0.2 stopped" on every step (2026-10-16-0510, 2026-10-17-1846, 2026-10-20-0346, 2026-10-20-1923) |

Step 0.2 is the start check that lists what moved main since the last iteration; in
mid-October it stopped the iteration when main held a commit the cycle had not made, until
the owner had looked. The dev-cycle skill has no light pass, and Q-154's answer was a full
cycle every iteration. Two of the 24 light iterations were directed by the owner; the
other 22 were the orchestrator's choice. The records give no rule for when it chose one,
and it stopped choosing them after 2026-11-02 without a recorded reason.

**Per day** (the owner's local day, US Pacific; lines are added plus removed):

| Local day | Iterations | Full / light / stopped | Caught / re-fire only / quiet | Wall minutes | Cycle lands (lines) | Loop merges (lines) | Other commits (lines) |
|---|---|---|---|---|---|---|---|
| 2026-10-15 | 1 | 0/0/1 | 0/0/0 | n/a | 0 (0) | 0 (0) | 0 (0) |
| 2026-10-17 | 4 | 1/2/1 | 1/0/0 | 42 | 7 (1473) | 0 (0) | 1 (101) |
| 2026-10-19 | 1 | 0/0/1 | 0/0/0 | n/a | 1 (295) | 0 (0) | 9 (1447) |
| 2026-10-20 | 5 | 4/0/1 | 2/0/2 | 57 | 6 (1243) | 3 (897) | 10 (10164) |
| 2026-10-25 | 4 | 4/0/0 | 2/0/2 | 42 | 5 (561) | 1 (57) | 2 (249) |
| 2026-10-28 | 11 | 11/0/0 | 3/0/8 | 88 | 15 (1714) | 9 (6455) | 7 (1338) |
| 2026-10-29 | 13 | 13/0/0 | 4/0/9 | 155 | 21 (2455) | 6 (2909) | 5 (465) |
| 2026-10-30 | 7 | 5/2/0 | 1/0/4 | 55 | 8 (963) | 5 (1132) | 6 (2905) |
| 2026-10-31 | 2 | 1/1/0 | 0/0/1 | 6 | 3 (165) | 0 (0) | 0 (0) |
| 2026-11-01 | 17 | 3/14/0 | 1/1/1 | 109 | 20 (1836) | 4 (1961) | 2 (754) |
| 2026-11-02 | 7 | 2/5/0 | 1/1/0 | 42 | 8 (581) | 2 (685) | 0 (0) |
| 2026-11-03 | 3 | 3/0/0 | 0/1/2 | 20 | 4 (390) | 1 (647) | 2 (172) |
| 2026-11-05 | 7 | 7/0/0 | 2/1/4 | 205 | 9 (947) | 4 (8731) | 1 (21) |
| 2026-11-06 | 12 | 12/0/0 | 3/2/7 | 68 | 15 (1559) | 4 (7298) | 3 (199) |
| 2026-11-07 | 5 | 5/0/0 | 1/4/0 | 57 | 6 (950) | 3 (1106) | 1 (11) |
| 2026-11-10 | 1 | 1/0/0 | 1/0/0 | 12 | 1 (390) | 0 (0) | 0 (0) |
| **Total** | **100** | **72/24/4** | **22/10/40** | **958** | **129 (15522)** | **42 (31878)** | **49 (17826)** |

Notes on the table:

- Commits are counted on the day they were made, so the first iteration's land shows under
  2026-10-17.
- Thirteen more "other" commits fell on days with no iteration (2026-10-16, -18, -21 and
  -23: 8, 2, 1 and 2 commits, 1,588 lines). That makes 62 commits and 19,414 lines in all.
- The date command in section 1 prints 16 for 2026-11-01 and 8 for 2026-11-02, because it
  reads the mistyped name 2026-11-02-1438 as written. The table uses 06:47 UTC.

**Wall time**, from commit times. The start is the minute in the iteration's name, which
the orchestrator sets when it creates its worktree, just after the start check. The end is
the committer time of the iteration's last land. 96 of 100 can be measured; four cannot
(one landed 38 hours later from another session, three have a name later than their own
land). "Middle half" is the first to third quartile, by Python's `statistics.quantiles`.
[observed]

| Group | Measurable | Median minutes | Middle half | Longest | Total minutes |
|---|---|---|---|---|---|
| All | 96 | 5.6 | 2.4 to 12.2 | 182 | 958 |
| Full | 72 | 7.7 | 2.7 to 14.1 | 182 | 834 |
| Light | 22 | 2.9 | 1.8 to 5.4 | 45 | 118 |
| Full, caught something | 22 | 12.0 | 8.1 to 19.1 | 182 | 472 |
| Full, re-fire only | 10 | 12.0 | 2.8 to 13.3 | 15 | 91 |
| Full, quiet | 40 | 3.8 | 2.3 to 9.8 | 23 | 271 |
| Full, quiet, health check re-run | 15 | 9.8 | | | 178 |
| Full, quiet, health check "unchanged" | 24 | 2.4 | | | 88 |
| Full, quiet, a full verdict list written | 20 | 7.3 | | | |
| Full, quiet, one "as at" line written | 18 | 2.4 | | | |

Two stopped iterations make up the rest of "All". One quiet iteration skipped its health
check (2026-10-29-2306, 4.7 minutes), and two wrote a partial verdict list. The 182-minute
iteration is 2026-11-05-2347, whose health check passed on its third run.

The name's minute can be trusted in most cases. The records say a build loop started 41
iterations, and each of those names a loop's marker commit (`handoff: ready` or
`handoff: blocked`) on its collect line, which gives an independent start. 34 of the 41
names are within a minute of the first such marker, and from marker to land those 41 took
a median of 3.9 minutes. [observed]

What this shows, and what it does not:

- Iterations whose health check re-ran took far longer (9.8 against 2.4 minutes among the
  quiet ones). Those are mostly also the iterations where main had moved, so step 4 had
  something new to check and step 7 had merges to make; the health check is not the only
  cause.
- A quiet full iteration whose health check did not re-run took 2.4 minutes, less than
  the median light pass (2.9). The same is true of the quiet ones that wrote one "as at"
  line. That suggests many quiet "full" iterations did not redo the checking steps.
  [inferred]
- So against what actually ran, a light pass saves little wall time. Against the skill as
  written (every trigger decided again, every time), the saving would be larger, and these
  26 days cannot say by how much.

## 3. What steps 2, 3, 4 and 4b produced

**The rule used.** A step "produced" something when its record line reports one of these.
Step 2: a trigger newly fired, or the evidence for a verdict corrected. Step 3: a watch
met, a stale agent item done or corrected in-cycle, or a stale item or finding turned into
a new owner entry or agent item. Step 4: a claim that did not hold, a drift finding, any
other finding, or an in-cycle fix. Step 4b: a deep-audit task filed. Three things are not
counted. Recording or applying the owner's answers appears on the step 3 line of many
records, but it is the collect step's work (step 7), which a light pass keeps. Writing a
brief for a stale item is step 8's work. And when step 4b fires for a cause that an open
deep-audit task already covers, with nothing else new, the iteration is counted apart as
**re-fire only**.

**Result**, over the 72 full iterations: [inferred from reading each record line; Appendix A]

| Outcome | Iterations | Share of 72 |
|---|---|---|
| Caught something | 22 | 31% |
| Re-fire only | 10 | 14% |
| Quiet (nothing) | 40 | 56% |

Quiet or re-fire only: 50 of 72 (69%). Of all 100 recorded iterations, 22 produced
something from these four steps.

**By kind of product** (an iteration can appear in more than one row):

| Product | Iterations | Which |
|---|---|---|
| Trigger newly fired (step 2) | 3 | 2026-10-17-1912, 2026-10-20-1938, 2026-11-07-0500 |
| Evidence for a verdict corrected, verdict unchanged (step 2) | 1 | 2026-11-05-2347 |
| Watch met (step 3) | 2 | 2026-10-28-2136, 2026-10-29-2003 (the same watch both times) |
| Stale item done or corrected in-cycle (step 3) | 5 | 2026-10-17-1912, 2026-10-26-0002, 2026-11-02-2027, 2026-11-07-0115, 2026-11-10-1902 |
| Stale item or finding became a new entry or item (step 3) | 3 | 2026-10-30-0731, 2026-11-06-0956, 2026-11-10-1902 |
| Claim did not hold (step 4) | 2 | 2026-10-29-0235, 2026-11-02-0326 |
| Drift finding (step 4) | 7 | 2026-10-20-2344, 2026-10-28-2223, 2026-10-30-0035, 2026-11-06-0317, 2026-11-07-0500, 2026-11-07-2324, 2026-11-10-1902 |
| Other finding (step 4) | 5 | 2026-10-20-1938, 2026-10-26-0002, 2026-10-26-0027, 2026-10-29-2212, 2026-10-30-0100 |
| Deep-audit task filed, in the record's words (step 4b) | 6 | 2026-10-20-1938, 2026-10-20-2344, 2026-10-28-2136, 2026-10-28-2223, 2026-10-30-0035, 2026-11-06-0317 |
| Deep-audit check fired onto the existing task (step 4b) | 16 | the 10 re-fire-only iterations, and 6 that also caught something else |

Section 7 says in a line what each of the 22 catches was. Three patterns stand out.

- **Step 2 wrote 1,071 verdict lines and 3 of them were new firings.** 39 of the 72 full
  iterations wrote a full list (22 to 28 lines each), 6 wrote a few lines plus "the others
  as at", and 27 wrote one line for all triggers. [observed]
- **Step 4b fired in 22 iterations, and all 22 feed one piece of work that has not run**:
  the scoped deep audit, a roadmap Ideas item since 2026-10-02 and an agent task in the
  roadmap's Now since 2026-11-05. Its scope and timing are the owner's to confirm, and on
  2026-11-10 that became Q-269, the open owner entry asking whether and how to run it. All
  7 drift findings feed it too; in 6 of the 7 the record says the loop's pick stands
  anyway or calls the finding minor. [observed]
- **Step 4 often had nothing new to check.** In 28 of the 72 iterations it sampled a
  commit, other than the cycle's own lands, that no earlier iteration had sampled. In 5 it
  went back to one for a different claim or a first drift check. In the other 39 it
  checked only the cycle's own lands, repeated an earlier check, or was skipped.
  [inferred from reading each step 4 line]

**Main moved, or not.** For each full iteration, "main moved" means main gained a commit
other than a cycle land since the previous full iteration began (from the `Main at:`
lines). [observed]

| | Main had moved | Main had not moved |
|---|---|---|
| Caught something | 18 | 4 |
| Re-fire only | 6 | 4 |
| Quiet | 12 | 28 |

So of the 36 full iterations that ran when main held nothing new but cycle lands, 28 were
quiet, 4 were re-fire only and 4 caught something (2026-10-28-2223, 2026-10-29-0235,
2026-11-07-0115, 2026-11-10-1902; section 7 says what each was).

## 4. What each iteration landed, against feature and fix merges

Per iteration, Appendix A gives the lines and files of its own lands, and the loop merges
and other commits that reached main since the previous iteration began. The history does
not separate feature merges from fix merges in a way worth counting, so the split given is
lines outside `docs/` against lines in it. Totals: [observed]

| On main since 83b653d2 | Commits | Lines added | Lines removed | File changes |
|---|---|---|---|---|
| Cycle lands (bookkeeping) | 129 | 12,821 | 2,701 | 495 |
| Loop merges | 42 (34 approved by the owner, 8 self-merged) | 27,349 | 4,529 | 325 |
| Other commits (the owner's, and hand merges from other sessions) | 62 | 17,104 | 2,310 | 209 |

- **The cycle's lands touch only its own files.** By file: questions files 6,787 lines,
  records 4,908, briefs 2,391, roadmap 1,293, idea log 116, one feedback file 27. 71
  iterations landed once and 29 landed twice (the second land carries the dispatch lines).
- **A typical iteration**: a full one changed a median of 105 lines in 4 files, a light
  one 78 lines in 3 files. The 40 quiet iterations landed 5,202 lines, a third of all the
  bookkeeping.
- **Loop merges**: 12,109 of their 31,878 changed lines are outside `docs/` (code, tests,
  skills, workflows). The other 19,769 are the loops' own research docs, briefs and review
  reports. 36 of the 42 merges touch something outside `docs/`.
- **Ratios**: 100 iterations and 129 lands for 42 loop merges, so 2.4 iterations and 3.1
  lands per merge. The cycle landed 0.49 bookkeeping lines for each line the loops merged,
  and 1.28 for each line they merged outside `docs/`.
- **Other commits**: 17 of the 62 change only the questions files or the owner's answer
  files; 20 touch a path outside `docs/` (19 change lines there, one is a rename).

Lines are a rough measure. An archived question counts twice (removed from one file, added
to another), a brief moved to `closed/` counts as a rename, and briefs are counted as
bookkeeping although they are the specs the loops build from.

## 5. Who started each iteration

From each record's step 0 line or `Window:` line: [observed]

| Started by | Iterations | Full / light / stopped |
|---|---|---|
| A build loop's task notification or marker | 41 | 30 / 11 / 0 |
| The owner (a message, an answer in session, or `/loop /dev-cycle`) | 26 | 18 / 8 / 0 |
| The orchestrator going straight on from its previous iteration | 7 | 2 / 5 / 0 |
| A wakeup | 0 | |
| Not stated in the record | 26 | 22 / 0 / 4 |

- Four of the 26 unstated ones begin within a minute of a loop's marker commit
  (2026-11-07-0534, -0603, -0650 and -0745), so a loop probably started them. [inferred]
- No iteration was started by a wakeup. Four records mention five wakeups (about 00:42 UTC
  on 2026-10-21, about 01:19 UTC on 2026-10-26, and 19:56, 23:09 and 23:40 local time on
  2026-11-05), and each says the wakeup found a loop still working and ran no iteration.
- An owner's answer to a merge question can cost two iterations: one to land the answer
  on main, and a second to apply it, because the build-loop script reads such an answer
  only from main. Six of the seven "went straight on" iterations exist for that reason
  (the five light ones and 2026-10-29-2223); in one of the six the answer was to a
  stopped-loop entry, not a merge question.

## 6. Tokens

**No record or log in this repo holds per-iteration token counts.** The word "token" does
not appear in any cycle record or weekly digest. Usage fields (`input_tokens`,
`total_cost_usd`, `num_turns`) do appear in about 90 tracked files: review-benchmark runs
under `runs/` and `archive/`, review artifacts from August to early October, scripts and
tests that parse a headless run's output, and a few docs that mention the field names.
None is about a dev-cycle iteration. [observed, reading the matching lines] The
orchestrator runs as an interactive session, so it leaves no result file the way a
headless `claude -p` run does. This doc gives no estimate.

**The smallest change that would record them** (a suggestion only; nothing here is built):
one line in the record's header, next to `Model:`, written when the record is written:

```
Tokens: <input / output / cache-read for this iteration, from the session transcript>
```

A second part is optional: the collect step copies the usage a finished build loop
reports into its own record line, so loop cost and orchestrator cost can be told apart.

How hard this is, is not known. Session transcripts exist outside the repo, in the
sandbox's home volume (`~/.claude/projects/-workspace/`, 67 files dated 2026-10-12 to
2026-11-10). Counting fields in two of them, without reading their content, shows that
their lines carry `usage` and `timestamp` fields. [observed] That count was made only to
size this suggestion; the numbers in this doc use nothing from outside the repo. Three
things were not checked: whether a script can total usage between an iteration's first and
last message, whether an orchestrator session can name its own transcript file, and
whether the usage of the subagents that run the checking steps is in the same file.
[assumed] If those hold, the same transcripts would also allow a one-off total for the 100
past iterations with no model run.

## 7. What a light pass would have skipped, and what it would have missed

**Skipped.** In the 50 full iterations that were quiet or re-fire only, this work was
recorded again with the same result:

- Step 2: 23 of them wrote a full verdict list again (600 verdict lines, none a new
  firing); the other 27 wrote one "as at" line or a few lines.
- Step 3: the same parked questions were read as not met each time. Three were there
  throughout: Q-067 (regenerate the skill eval reports), Q-098 (ship a global allowlist)
  and Q-161 (bring back test confinement); they wait on a measurement run and a sandbox
  merge, neither of which has happened. Q-074 (does the failure-pattern log gain entries?)
  was there until it was met on 2026-10-28, and Q-262 (reopen merge approval?) and Q-264
  (did the gloss rule work?) from 2026-11-07.
- Step 4: 16 checked a commit other than the cycle's own lands and it held; 34 had
  nothing new to check.
- Step 4b: 10 fired onto the existing deep-audit task; 40 said nothing new.

In wall time those 50 iterations took 362 minutes over 26 days, a median of 4.8 each.
That is a ceiling on the saving, since it takes hindsight to know which iterations will be
quiet; the replay below says how many of the 50 each rule would have turned light. In
tokens the saving is unknown.

**Outside the four steps.** A light pass of steps 7, 8 and 10 also drops the digest, the
health check, migrations, the brainstorm check and the roadmap step, and this doc does not
count what those produced. Two facts from the records. The health check failed in 8 full
iterations; it re-ran in 39 of the 72 and was "unchanged" in 32. And the light iterations
mostly did not re-run it on main: their records cite an earlier pass or the loop's own
check on its branch, and two say it was run on the merged main (2026-11-01-2104 and
2026-11-01-2347). So a light-pass rule needs to say whether the health check stays.
[observed]

**Missed, in practice.** The 24 light iterations already run are a small test. What the
records show they put off is the deep-audit check: four light passes say a merge changed
the dev-cycle skill and "the next full cycle's 4b sees it". The next full cycle's
deep-audit check did fire each time, between 5 minutes and about 6 hours later, and in 3
of the 4 cases its line names that merge. One more thing came late: the full cycle at
2026-11-02-0326 drew a lesson for brief-writing from two merge conflicts that a light pass
had reported 3.6 hours earlier (Q-246 and Q-247, two loops stopped by those conflicts). No
other record of a full cycle that followed a light run reports something a light pass had
put off. [observed]

**Missed, replayed.** Suppose the 96 full or light iterations had run at the same times
under a rule, with all the remaining iterations light passes. For each of the 22 catches,
how long until the next full cycle? (Appendix B has the script.)

| Rule for a full cycle | Full cycles out of 96 | Of the 50 quiet or re-fire iterations, turned light | Catches that would have waited | Their wait |
|---|---|---|---|---|
| As actually run | 72 | 0 | 0 | |
| Main moved (anything but a cycle land), or the first iteration of a local day | 44 | 29 | 4 of 22 | 1, 3.8, 17 and 27 hours |
| Main moved only | 39 | 32 | 5 of 22 | the same four, and one never re-run by the end of the data |
| Every 6 hours | 19 | 42 | 13 of 22 | median 15 hours, longest 120 |
| First iteration of a local day | 14 | 45 | 15 of 22 | median 18 hours, longest 120 |
| Every 24 hours | 12 | 46 | 14 of 22 | median 24 hours, longest 120 |

How to read the waits:

- The "main moved" rule is this doc's own. It comes from the brief's motive (iterations
  that re-decided everything "with only cycle lands on main in between") and from the
  health check, which already skips itself on that condition. The interval rules are
  Q-154's second option, at 6 and 24 hours.
- For a catch from step 2 or step 3, the wait is an upper bound: under another schedule
  an earlier full cycle might have made it.
- For a finding from step 4, the wait is a floor. Step 4 samples one or two merges per
  iteration, so the next full cycle samples its own and may never reach the merge that
  held the finding. With fewer full cycles, fewer merges are spot-checked at all.
- The 120-hour wait is 2026-10-20 to 2026-10-25, when no iteration ran.
- The catch that "main moved only" never re-runs is 2026-11-10-1902: the model had
  changed and a release had happened, and neither is a commit on main.
- Under the first rule, the 44 full cycles are 18 of the 22 catching iterations, 21 of
  the 50 quiet or re-fire ones, and 5 that were light passes in fact.

**The 22 catches.** "Main moved" is as in section 3's table. The two wait columns are for
the rule in the table's second row ("moved or day") and for the first iteration of a local
day ("day"); 0 means that iteration would still have been a full cycle.

| Iteration | From step | What was caught | Main moved | Wait, moved or day | Wait, day |
|---|---|---|---|---|---|
| 2026-10-17-1912 | 2, 3 | A revisit trigger of decision 031 (the review loop's fact-check policy) fired and went to the owner as Q-194; three finished agent entries marked landed | yes | 0 | 0 |
| 2026-10-20-1938 | 2, 4, 4b | The trigger in decision-log row 73 (the constraints-builder skill's trust boundary) fired and went to the owner as Q-213; a gap found in the image-lag entry (the owner entry that says the installed image is behind main); deep-audit task filed | yes | 0 | 0 |
| 2026-10-20-2344 | 4, 4b | Drift finding on the import-guard merge (43762305); deep-audit task filed | yes | 0 | 120 h |
| 2026-10-26-0002 | 3, 4 | Four finished agent entries marked done; a stale sentence found in decision-log row 53 (the auto-approve hook's accepted gaps), which that iteration's own merge fixed | yes | 0 | 0 |
| 2026-10-26-0027 | 4 | The interview profile's README found to misstate behaviour; fixed on 2026-10-28 by a self-merge (9b8a0b34) | yes | 0 | 69 h |
| 2026-10-28-2136 | 3, 4b | Watch Q-074 (does the failure-pattern log gain entries?) met and sent to the owner as Q-223; deep-audit task filed for decision 040 (the questions file holds only owner entries) | yes | 0 | 0 |
| 2026-10-28-2223 | 4, 4b | Drift finding on the fix-drift-check merge (68287ee2); deep-audit task filed (added to the existing roadmap item) | no | 1 h | 21 h |
| 2026-10-29-0235 | 4 | The previous iteration's land had cut a brief down to one line; restored in-cycle | no | 17 h | 17 h |
| 2026-10-29-2003 | 3 | Watch Q-074 met again, by the merge that wires failure patterns into build loops (f91d7d09) | yes | 0 | 11 h |
| 2026-10-29-2212 | 4 | A test on a loop's branch fails in this sandbox on a locale warning; passed to that loop | yes | 0 | 9 h |
| 2026-10-30-0035 | 4, 4b | Drift finding on the watching-file merge (6ee39f24); deep-audit task filed (added to the existing roadmap item) | yes | 0 | 6.5 h |
| 2026-10-30-0100 | 4 | `migrations.sh check .` fails when given a relative path; briefed, and fixed the same day by a merge (ea1ab6fe) | yes | 0 | 6 h |
| 2026-10-30-0731 | 3 | A stale item's wait condition could no longer be met; became owner entry Q-238 (what to do with an old unmerged branch) | yes | 0 | 39 h |
| 2026-11-02-0326 | 4 | A brief's claim that three units could run in parallel did not hold (two conflicted at merge); the cycle changed how it splits briefs | yes | 0 | 5 h |
| 2026-11-02-2027 | 3 | A stale roadmap item removed and one line corrected | yes | 27 h | 27 h |
| 2026-11-05-2347 | 2 | The evidence line for decision-log row 57 (the self-improvement loop's trust check) corrected; verdict unchanged | yes | 0 | 0 |
| 2026-11-06-0317 | 4, 4b | Two drift findings on the canon-filter self-merge (605d4c18); deep-audit task filed | yes | 0 | 6 h |
| 2026-11-06-0956 | 3 | Two agent items filed from the weekly digest | yes | 0 | 37.5 h |
| 2026-11-07-0115 | 3 | A leftover item from the host-settings merge (owner entry Q-241) done in-cycle | no | 3.8 h | 22 h |
| 2026-11-07-0500 | 2, 4 | A trigger of decision 040 fired on the owner's feedback and became the gloss-rule brief (merged as 771c84e8); minor drift finding on the worktree-cleanup merge (85080263) | yes | 0 | 18 h |
| 2026-11-07-2324 | 4 | Minor drift finding on the merge that moved a script block into the image (aeab6745) | yes | 0 | 0 |
| 2026-11-10-1902 | 3, 4 | A stale item done in-cycle; the deep audit sent to the owner as Q-269; minor drift finding on the Q-125 check-file merge (546788f2); the model change added a cause to the deep-audit task | no | 0 | 0 |

Notes on the four that would have waited under the "moved or day" rule:

- 2026-10-29-0235 (17 h): a light pass would have seen this one anyway. The same record's
  collect line says the build-loop script's brief reader (`--status`) refused the cut-down
  brief, and its step 4 line says the loop had reported it.
- 2026-11-02-2027 (27 h): the "Main moved" column says yes because main had moved since
  the previous full cycle in fact. Under the rule a full cycle would have run 101 minutes
  earlier, at 2026-11-02-1846 (in fact a light pass), and could have made the same roadmap
  correction.
- 2026-10-28-2223 (1 h) and 2026-11-07-0115 (3.8 h) are the two real waits: a drift
  finding on an older merge that step 4 reached by sampling, and a leftover agent item.

Under the "day" rule, 9 of the 15 catches that wait are step 4 findings (the rows whose
only steps are 4, or 4 and 4b), so for them the wait is a floor and the finding might not
have been made.

## 8. What the numbers cannot show

1. **Tokens.** Nothing records them (section 6).
2. **Tokens from wall time.** The skill has the four checking steps run as parallel
   subagents, with one more per sampled merge. Subagents cost tokens and little wall time.
   Some records say a step was done "by hand", "inline" or "by one subagent"; most do not
   say, so short wall time does not mean low cost.
3. **Whether a step was run or carried forward.** 27 of the 72 full iterations wrote one
   "as at iteration X" line for all triggers, and many step 3 and step 4 lines read "as at"
   or "as checked at". The record cannot show whether the check was made again. "Quiet"
   therefore means the record reports nothing new, not that each check was repeated and
   found nothing. The brief's own motive says iterations 2026-11-08-0036 and
   2026-11-08-0600 "each re-decided all 28 revisit triggers"; their records hold one line
   each: "All 28 as at iteration 2026-11-07-2324".
4. **Whether a written-out verdict was decided from evidence.** Iteration 2026-11-05-2347
   corrected the evidence for decision-log row 57: earlier records said a test run of the
   self-improvement loop had not happened, and it had
   (`docs/working/si-trust-evidence-2026-10-14.md`). The next two full lists
   (2026-11-07-2324 and 2026-11-10-1902) say "no Q-075 run" again, Q-075 being the entry
   that asked for that run. The verdict, not fired, was the same either way.
5. **The start and end of an iteration.** The name's minute is typed by the orchestrator;
   one record says its own name is wrong and three more are later than their own land.
   The start check runs before the name exists and the final message comes after the last
   land, so the wall times are slightly short.
6. **What a light pass would take.** The 2.9-minute median comes from the 22 light
   iterations that can be measured (21 the orchestrator chose, 1 the owner directed), 18
   of them on two days (2026-11-01 and 2026-11-02). It is not a fair estimate of what a
   light pass would take in place of any given full one.
7. **What the steps around the four caught.** The health check, migrations, the
   brainstorm check and the roadmap step are not counted here (section 7 gives the two
   facts that were easy to read).
8. **Who started 26 iterations, and how many wakeups there were.** A wakeup that runs no
   iteration leaves a trace only if a later record mentions it.
9. **Iterations that left no record.** A stop at the start check writes none by design.
10. **The value of a check that held.** These numbers count findings. A spot-check that
    passes is still information, and it is counted here as nothing.
11. **The build loops' own cost.** Their research, reviews and fix rounds are outside the
    iteration and outside this doc.
12. **Effort, and the calls at the margin.** Line counts are not effort, and the hand
    classification could differ at the margin. The calls most open to argument:
    - Answer handling on step 3 lines is not counted (it is step 7's work), and briefing
      a stale item is not counted (step 8's).
    - Two agent items filed from the weekly digest (2026-11-06-0956) and a roadmap line
      corrected (2026-11-02-2027) are counted. A roadmap item moved to Done because a
      loop's merge finished it (2026-11-03-2329) is not.
    - Watch Q-074 is counted as met twice, as the records say (2026-10-28-2136 and
      2026-10-29-2003).
    - "Task filed" against "fired onto the existing task" follows each record's wording;
      every filing after the first lands on the same roadmap item. Three lines that say
      "same triggers" or "changed in the window" with "no new task" (2026-11-02-2027,
      2026-11-03-2329, 2026-11-06-0753) are counted as re-fires.
    - 2026-11-07-0620 calls itself "a short iteration" and is counted as full, because
      its steps have result lines.
13. **One model.** 99 of the 100 iterations ran on `claude-opus-5-5`; the last ran on
    `claude-fable-5-2`. Nothing here says how the next model's iterations will look.

## Research notes

These notes and the appendices are for agents; the options for the owner follow them.

### What exists

- `docs/working/cycles/cycle-YYYY-MM-DD.md`: one file per record date, one
  `## Iteration DATE-HHMM` block per iteration, with `Branch:`, `Main at:`, `Window:` and
  `Model:` lines, a `### Steps` list (0 to 10) and fixed sections (trigger verdicts,
  questions filed, paths landed and others). The template is in step 9 of
  `skills/dev-cycle/SKILL.md`. [observed]
- Main's first-parent history: each iteration lands as `Merge branch
  'chore/dev-cycle-DATE-HHMM'`, once after step 9 and again after step 10 when it
  dispatched or filed something. Loop merges end `(build-loop approved merge)` or
  `(build-loop self-merge)`. Everything else is a hand commit. [observed]
- A build loop ends with an empty marker commit (`handoff: ready`, `handoff: blocked`),
  whose commit time is an independent clock for when a loop-started iteration began.
  [observed]
- Q-154 (archived in `docs/working/questions-archive.md`) and roadmap Next 3 hold the
  owner's answer and the first step this doc carries out. [observed]

### Invariants

- This unit changes two files only: this doc, and the brief's status line (the brief's
  `Paths:` line; the gate checks it).
- Cycle records are append-only and never edited (step 9 of the skill): this doc reads
  them and corrects nothing in them, including the mistyped name.
- The questions files, the roadmap and `docs/dev-cycle.md` belong to the dev cycle: the
  options at the end are for the cycle to file, not filed here.

### Prior art

- `docs/reviews/performance-review-2026-10-13-u4b2-final.md` and `-i2.md` named this
  measurement before the orchestrator first ran ("measure tokens per iteration over one day
  of loop operation first") and proposed the no-change iterations as the first candidates
  for a light pass. The second also notes that each full iteration starts four or more
  subagents.
- Idea-log line 56 asks for the share of an iteration's tokens spent on one pasted block;
  it has the same gap this doc reports: no token record.
- No earlier doc counts iterations or classifies them.

### Gotchas

Failure-pattern grep: FP-108, FP-110, FP-114, FP-176 (see Prior failures)

The grep was `grep -inE 'under-?count|miscount|timezone|time-zone|utc|dst|numstat|rename|cycle-record|docs/working/cycles|dev-cycle|instrument|measure|wrong-denominator' docs/failure-patterns.md`.
It also matched FP-077, FP-078 and FP-099 (wrong denominators in scoring and billing code;
the same lesson as FP-110, nothing more specific to this work) and FP-038, FP-043 and
FP-138 (file renames in code, which do not bear on a measurement).

- Names are UTC and record files are dated in local time, so one local day spans two UTC
  dates. The per-day table uses the local day.
- `git diff --numstat --no-renames` counts a brief moved to `closed/` as a full delete and
  a full add: briefs came to 6,825 lines that way, 2,391 with rename detection (git's
  default for `diff`, and what `-M` asks for).
- One `Main at:` line holds a short hash (2026-10-30-0708), and one iteration's is older
  than the one before it (the mistyped name puts it out of order).
- The step 3 line of many records holds answer handling, which is step 7's work.
- Appendix A's "Landed" files are distinct files per iteration (417 in all); section 4's
  495 counts each land's files.
- The awk verdict count prints nothing for 2026-10-26-0139, whose single verdict line is
  a paragraph with no bullet; it is one of the 27 one-line iterations.

#### Prior failures

- FP-108 (a record summed results, not the ledger of attempts) and FP-110, FP-114 (failed
  cells removed themselves from the denominator): the denominators here are stated each
  time (100 recorded, 72 that ran the steps, 96 full or light), stopped and light
  iterations are shown and not dropped, and section 8 says which attempts leave no record
  (stops at the start check, wakeups).
- FP-176 (the brainstorm's seed count counted the brainstorm's own lines): cycle lands are
  separated from loop merges and hand commits by commit subject before anything is summed,
  and "main moved" excludes the cycle's own lands.

### Design choices

The brief's own lines are the hard constraints here: repo records and history only, every
count re-runnable, no token estimate, no pick for the owner. H1 to H4 in
`docs/constraints.md` concern gates and tests and bear on none of these choices. Options
are pruned only on the brief's lines or on a plain fact; the soft constraints only rank.

**D1. How to measure wall time** (divergent design, Path A).

| Candidate | Brief's lines | Notes |
|---|---|---|
| A. Name's minute to last land's commit time | passes; covers 96 of the 100 | the name is typed, so it needs a cross-check |
| B. Loop marker's commit time to last land | passes; covers 41 | a real clock at both ends, but only for loop-started iterations |
| C. Gap between one iteration's land and the next | fails: the brief asks for wall time per iteration, and this includes the idle wait between them | |
| D. Timestamps in the record | fails: the records hold none | |
| E. Session transcripts | fails: outside the repo | |

Pick: A for every iteration, checked against B where B exists. A and B do not compete: B
validates A (34 of 41 within a minute). One option dominates.

**D2. Which day an iteration belongs to** (Path A). Candidates: the UTC date in its name,
the owner's local date, the record file's date. All pass the brief's lines. The record
file's date is ruled out by a fact: a file can hold several days (`cycle-2026-10-17.md`
holds iterations of 2026-10-20). The brief asks for "iterations per day"; one evening's
session spans two UTC dates, so the local date is the day the count is about. Pick: local
date, with the UTC names kept in every table.

**D3. What counts as quiet** (Path A). Candidates: strict (any "fired" line counts as a
product), narrow (only new things count), and a three-way split. The brief names the
products (a fired trigger, a met watch, a failed claim, a drift finding, an in-cycle fix).
A deep-audit re-fire onto an existing task fits neither side cleanly. Pick: the three-way
split. It dominates as a plain fact: it reports both readings (40 quiet, or 50 with
re-fires), and either of the others can be read off it.

**D4. Which merges belong to an iteration** (Path A). Candidates: by commit time between
iteration names, by position on main between `Main at:` lines, by the record's `Window:`
line. The `Window:` line is ruled out by a fact: it is a date, and windows on one day
overlap. `Main at:` ranks above commit time because it is the cycle's own definition of
what an iteration sees (S3: one source of truth) and does not depend on typed names. Pick:
`Main at:` to `Main at:`.

Other choices, one line each:
- Which rules to replay in section 7: Q-154's interval at two lengths, a day-start rule,
  and a "main moved" rule of this doc's own (its source is stated in section 7).
- A per-iteration table or only the non-quiet list: the brief asks "for each iteration",
  so Appendix A lists all 100.
- Whether to total the session transcripts: no; the brief limits this doc to the repo.
- Where the options table sits: last in the file, because the brief says the doc ends
  with it.

### Plan and verification

No plan doc: the brief's `Paths:` line allows this file and the brief only. Steps taken:
parse the records, read git history, classify by hand, compute, write, review, fix,
review again. No code or behaviour changes, so no tests were written and `test-strategy`
was not run. Verification is the commands in section 1 and Appendix B, re-run by the
review passes, and the repo's health check run on the branch (see Review).

| Failure mode | Guard |
|---|---|
| A count silently drops stopped or light iterations | every table states its denominator (100, 96 or 72) |
| A hand classification is wrong | Appendix A lists every call beside its iteration; a reviewer re-read all 100 record blocks |
| A line count is inflated by renames | rename detection on every numstat; the command is shown |
| The doc picks for the owner | the last section gives a table and one recommendation line marked as such |

`/pre-mortem` and `/architecture-review`: not triggered (one docs file, no trust boundary,
no module change). Rollback: `git revert -m 1` of this branch's merge commit; the change is
two docs files, nothing installed and no state.

### Review

Round 1, on the first draft (abc8b1c1). Three independent reviewers, each a separate
subagent with its own scratch directory:

- One re-ran every command in section 1 and re-derived the counts, medians, totals and
  ratios its own way. Every headline number reproduced. It found the marker cross-check
  misstated (38, 32 and 3.5 where the records give 41, 34 and 3.9), the rename gotcha
  wrong (`--no-renames`, not a missing `-M`), "19 touch something outside `docs/`" one
  short, and the wall-time command unable to reproduce the wall table as printed.
- One re-read all 100 record blocks against Appendix A. Kind and starter matched on all
  100 rows. It found one clear error (2026-11-10-1902's step 4b was marked "task filed"
  where the record says it fired onto the existing task) and argued that three "no new
  task" lines are re-fires. Both were taken: the split moved from 22 / 8 / 42 to
  22 / 10 / 40, with quiet or re-fire only unchanged at 50.
- One read as the owner. Its main points, all taken: the options lacked "measure first",
  which the doc's own finding points to; "upper bounds" was wrong for step 4's sampled
  findings; "the orchestrator chose" overlooked the two owner-directed passes; the replay
  needed a row for what actually ran and a count of quiet iterations turned light; wall
  time needed a caveat that it is not tokens; and many references needed a plain gloss.

The fixes are in the commit after abc8b1c1.

Round 2, on the revised doc (5e6a8412). One independent reviewer re-ran Appendix B,
re-derived every number that round 1's changes added or moved, and checked each gloss
against its source. The new split was carried through consistently and no stale number was
left. It found two new sentences with wrong numbers (how many "went straight on"
iterations follow an owner's answer: six, not five; and where the light-pass median comes
from: 22 measurable light iterations, 18 on two days) and six small wording points. All
are fixed in the commit after 5e6a8412. No Must Fix item is left, so the loop ended after
two rounds.

Health check (`scripts/health-check.sh`, output sent to a file). A first run, made while
the three round 1 reviewers were working, failed on one test
(`test/rubric-selection.bats`, "emits nothing when two candidates tie"); that test then
passed three times on its own. A second run with nothing else running passed in full
(1,991 tests, "All checks passed"). The change is docs only, so the one failure looks like
a test that is sensitive to load, not something this branch caused. [inferred]

## Files read

Last verified: 2026-11-10
docs/working/briefs/2026-11-10-cycle-overhead-numbers.md
docs/working/cycles/cycle-*.md
docs/working/weekly/
docs/working/questions-archive.md
docs/working/questions.md
docs/working/watching.md
docs/working/idea-log.md
docs/working/si-trust-evidence-2026-10-14.md
docs/working/research-2026-11-07-confine-tests-situation.md
docs/roadmap.md
docs/constraints.md
docs/failure-patterns.md
docs/decisions/log.md
docs/reviews/performance-review-2026-10-13-u4b2-final.md
docs/reviews/performance-review-2026-10-13-u4b2-i2.md
skills/dev-cycle/SKILL.md
workflows/research-plan-implement.md
workflows/divergent-design.md
workflows/pr-prep.md
workflows/review-fix-loop.md
scripts/build-loop.sh
scripts/health-check.sh
runs/
archive/

Outside the repo, names, dates and field counts only: `~/.claude/projects/-workspace/`.

## Appendix A: every iteration

Columns. **Local**: the owner's local date (month-day). **Kind**: full, light or stopped.
**By**: who started it: `loop`, `owner`, `went on` (the orchestrator went straight on),
`(loop)` (not stated, but a loop's marker commit is within a minute), `·` (not stated).
**Wall**: minutes from the name to the last land. **2, 3, 4, 4b**: what each step produced.
Step 2: `F` a trigger newly fired, `c` evidence corrected. Step 3: `W` a watch met, `X` a
stale item done or corrected in-cycle, `Q` a new entry or item. Step 4: `C` a claim did not
hold, `D` a drift finding, `O` another finding, `X` fixed in-cycle, `h` a commit other than
the cycle's own lands checked (a new one, or an earlier one on a different claim) and it
held, `s` skipped, `–` only the cycle's own lands or a repeat of an earlier check. Step 4b:
`T` task filed, `r` fired onto the existing task. `–` means nothing. **New on main**: loop
merges / other commits that reached main between the previous iteration's `Main at:` and
this one's, with their changed lines. **Landed**: changed lines (distinct files) in the
iteration's own lands.

| # | Iteration (UTC) | Local | Kind | By | Wall | 2 | 3 | 4 | 4b | Outcome | New on main | Landed |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 2026-10-16-0510 | 10-15 | stopped | · | n/a |  |  |  |  |  | 0 | 596 (3) |
| 2 | 2026-10-17-1846 | 10-17 | stopped | · | 3.9 |  |  |  |  |  | 0/8 (587) | 304 (2) |
| 3 | 2026-10-17-1912 | 10-17 | full | · | 24.0 | F | X | h | – | caught | 0 | 338 (9) |
| 4 | 2026-10-17-1948 | 10-17 | light | loop | 8.5 |  |  |  |  |  | 0 | 143 (4) |
| 5 | 2026-10-17-1956 | 10-17 | light | loop | 5.3 |  |  |  |  |  | 0 | 92 (3) |
| 6 | 2026-10-20-0346 | 10-19 | stopped | · | n/a |  |  |  |  |  | 0/12 (1626) | 295 (2) |
| 7 | 2026-10-20-1923 | 10-20 | stopped | · | 1.9 |  |  |  |  |  | 0 | 653 (3) |
| 8 | 2026-10-20-1938 | 10-20 | full | · | 15.8 | F | – | O | T | caught | 0 | 100 (4) |
| 9 | 2026-10-20-2344 | 10-20 | full | · | 18.4 | – | – | D | T | caught | 3/10 (11061) | 310 (9) |
| 10 | 2026-10-21-0006 | 10-20 | full | loop | 4.9 | – | – | s | – | quiet | 0 | 86 (3) |
| 11 | 2026-10-21-0044 | 10-20 | full | loop | 16.0 | – | – | s | – | quiet | 0 | 94 (3) |
| 12 | 2026-10-26-0002 | 10-25 | full | · | 24.3 | – | X | O | – | caught | 0/5 (1172) | 283 (8) |
| 13 | 2026-10-26-0027 | 10-25 | full | loop | 10.6 | – | – | O | – | caught | 1/0 (57) | 116 (4) |
| 14 | 2026-10-26-0045 | 10-25 | full | loop | 3.8 | – | – | h | – | quiet | 0 | 94 (3) |
| 15 | 2026-10-26-0139 | 10-25 | full | loop | 3.3 | – | – | s | – | quiet | 0 | 68 (3) |
| 16 | 2026-10-28-2136 | 10-28 | full | · | 16.2 | – | W | – | T | caught | 0/5 (1326) | 348 (10) |
| 17 | 2026-10-28-2155 | 10-28 | full | loop | 9.8 | – | – | h | – | quiet | 4/0 (5248) | 67 (3) |
| 18 | 2026-10-28-2205 | 10-28 | full | loop | 13.5 | – | – | h | – | quiet | 1/0 (126) | 90 (3) |
| 19 | 2026-10-28-2223 | 10-28 | full | loop | 2.2 | – | – | D | T | caught | 0 | 93 (3) |
| 20 | 2026-10-28-2302 | 10-28 | full | owner | 3.4 | – | – | – | – | quiet | 0 | 166 (5) |
| 21 | 2026-10-28-2314 | 10-28 | full | loop | 2.4 | – | – | – | – | quiet | 0 | 90 (4) |
| 22 | 2026-10-28-2325 | 10-28 | full | owner | 7.7 | – | – | – | – | quiet | 1/1 (196) | 67 (3) |
| 23 | 2026-10-29-0133 | 10-28 | full | owner | 9.7 | – | – | – | – | quiet | 0/1 (4) | 324 (7) |
| 24 | 2026-10-29-0217 | 10-28 | full | loop | 10.7 | – | – | h | – | quiet | 2/0 (825) | 269 (4) |
| 25 | 2026-10-29-0235 | 10-28 | full | loop | 5.5 | – | – | C X | – | caught | 0 | 118 (4) |
| 26 | 2026-10-29-0240 | 10-28 | full | went on | 7.0 | – | – | – | – | quiet | 0 | 82 (4) |
| 27 | 2026-10-29-1937 | 10-29 | full | · | 23.2 | – | – | h | – | quiet | 1/0 (68) | 138 (3) |
| 28 | 2026-10-29-2003 | 10-29 | full | · | 34.5 | – | W | h | – | caught | 0/1 (13) | 329 (8) |
| 29 | 2026-10-29-2045 | 10-29 | full | loop | 14.6 | – | – | h | – | quiet | 1/0 (376) | 211 (5) |
| 30 | 2026-10-29-2108 | 10-29 | full | loop | 1.7 | – | – | – | – | quiet | 0 | 105 (3) |
| 31 | 2026-10-29-2126 | 10-29 | full | loop | 2.6 | – | – | – | – | quiet | 0 | 105 (4) |
| 32 | 2026-10-29-2212 | 10-29 | full | owner | 11.1 | – | – | O | – | caught | 0/1 (8) | 67 (2) |
| 33 | 2026-10-29-2223 | 10-29 | full | went on | 3.8 | – | – | – | – | quiet | 0 | 445 (8) |
| 34 | 2026-10-29-2248 | 10-29 | full | loop | 7.8 | – | – | h | – | quiet | 3/0 (1732) | 243 (5) |
| 35 | 2026-10-29-2306 | 10-29 | full | owner | 4.7 | – | – | – | – | quiet | 0 | 186 (6) |
| 36 | 2026-10-30-0035 | 10-29 | full | owner | 17.5 | – | – | D | T | caught | 1/0 (692) | 203 (7) |
| 37 | 2026-10-30-0100 | 10-29 | full | loop | 12.4 | – | – | O | – | caught | 1/0 (109) | 172 (4) |
| 38 | 2026-10-30-0116 | 10-29 | full | loop | 18.6 | – | – | – | – | quiet | 0 | 132 (5) |
| 39 | 2026-10-30-0136 | 10-29 | full | loop | 2.1 | – | – | – | – | quiet | 0 | 119 (4) |
| 40 | 2026-10-30-0708 | 10-30 | light | owner | 1.6 |  |  |  |  |  | 0/3 (444) | 75 (2) |
| 41 | 2026-10-30-0730 | 10-30 | light | owner | n/a |  |  |  |  |  | 3/0 (685) | 338 (7) |
| 42 | 2026-10-30-0731 | 10-30 | full | · | 6.5 | – | Q | h | r | caught | 0/1 (13) | 77 (3) |
| 43 | 2026-10-30-0800 | 10-30 | full | owner | 23.1 | – | – | – | – | quiet | 0 | 232 (6) |
| 44 | 2026-10-30-0841 | 10-30 | full | loop | 2.4 | – | – | – | – | quiet | 0 | 83 (3) |
| 45 | 2026-10-30-0848 | 10-30 | full | loop | 2.3 | – | – | – | – | quiet | 0 | 77 (3) |
| 46 | 2026-10-31-0316 | 10-30 | full | owner | 18.8 | – | – | h | – | quiet | 2/5 (3339) | 81 (5) |
| 47 | 2026-10-31-2256 | 10-31 | full | owner | 2.7 | – | – | – | – | quiet | 0 | 90 (3) |
| 48 | 2026-10-31-2325 | 10-31 | light | loop | 3.7 |  |  |  |  |  | 0 | 75 (3) |
| 49 | 2026-11-01-2056 | 11-01 | full | owner | 3.6 | – | – | – | – | quiet | 0 | 35 (1) |
| 50 | 2026-11-01-2101 | 11-01 | light | owner | 2.4 |  |  |  |  |  | 0 | 39 (2) |
| 51 | 2026-11-01-2104 | 11-01 | light | went on | 8.0 |  |  |  |  |  | 0 | 80 (4) |
| 52 | 2026-11-01-2142 | 11-01 | light | owner | 5.7 |  |  |  |  |  | 1/2 (1136) | 190 (5) |
| 53 | 2026-11-01-2222 | 11-01 | light | loop | 3.6 |  |  |  |  |  | 0 | 81 (3) |
| 54 | 2026-11-01-2237 | 11-01 | light | loop | 2.3 |  |  |  |  |  | 0 | 86 (3) |
| 55 | 2026-11-01-2243 | 11-01 | light | loop | 2.4 |  |  |  |  |  | 0 | 81 (3) |
| 56 | 2026-11-01-2346 | 11-01 | light | owner | 1.1 |  |  |  |  |  | 0 | 47 (2) |
| 57 | 2026-11-01-2347 | 11-01 | light | went on | 8.6 |  |  |  |  |  | 0 | 104 (6) |
| 58 | 2026-11-02-0326 | 11-01 | full | owner | 6.4 | – | – | C | r | caught | 1/0 (985) | 425 (5) |
| 59 | 2026-11-02-0337 | 11-01 | light | owner | 1.0 |  |  |  |  |  | 0 | 43 (2) |
| 60 | 2026-11-02-0340 | 11-01 | light | went on | 1.5 |  |  |  |  |  | 0 | 45 (3) |
| 61 | 2026-11-02-0420 | 11-01 | light | loop | 44.9 |  |  |  |  |  | 0 | 137 (4) |
| 62 | 2026-11-02-0532 | 11-01 | light | loop | n/a |  |  |  |  |  | 0 | 68 (3) |
| 63 | 2026-11-02-0649 | 11-01 | light | went on | 3.2 |  |  |  |  |  | 0 | 182 (6) |
| 64 | 2026-11-02-0718 | 11-01 | full | · | 13.0 | – | – | – | r | refire | 2/0 (594) | 150 (4) |
| 65 | 2026-11-02-0808 | 11-02 | light | loop | 2.7 |  |  |  |  |  | 0 | 64 (2) |
| 66 | 2026-11-02-1438 | 11-01 | light | owner | 1.8 |  |  |  |  |  | 0 | 43 (2) |
| 67 | 2026-11-02-1757 | 11-02 | light | owner | 1.0 |  |  |  |  |  | 0 | 39 (2) |
| 68 | 2026-11-02-1758 | 11-02 | light | went on | 3.1 |  |  |  |  |  | 0 | 125 (5) |
| 69 | 2026-11-02-1803 | 11-02 | full | · | 12.7 | – | – | h | r | refire | 1/0 (592) | 166 (5) |
| 70 | 2026-11-02-1833 | 11-02 | light | loop | 3.6 |  |  |  |  |  | 0 | 55 (4) |
| 71 | 2026-11-02-1846 | 11-02 | light | loop | 2.1 |  |  |  |  |  | 1/0 (93) | 63 (2) |
| 72 | 2026-11-02-2027 | 11-02 | full | · | 16.6 | – | X | h | r | caught | 0 | 69 (2) |
| 73 | 2026-11-03-2329 | 11-03 | full | · | 11.3 | – | – | h | r | refire | 0/2 (172) | 186 (6) |
| 74 | 2026-11-04-0017 | 11-03 | full | loop | 7.4 | – | – | h | – | quiet | 1/0 (647) | 102 (3) |
| 75 | 2026-11-04-0031 | 11-03 | full | loop | 1.4 | – | – | h | – | quiet | 0 | 102 (4) |
| 76 | 2026-11-05-2347 | 11-05 | full | · | 181.7 | c | – | h | – | caught | 0/1 (21) | 232 (7) |
| 77 | 2026-11-06-0310 | 11-05 | full | loop | 2.8 | – | – | – | – | quiet | 0 | 86 (5) |
| 78 | 2026-11-06-0317 | 11-05 | full | loop | 8.7 | – | – | D | T | caught | 1/0 (353) | 95 (3) |
| 79 | 2026-11-06-0400 | 11-05 | full | loop | 1.4 | – | – | – | – | quiet | 0 | 84 (3) |
| 80 | 2026-11-06-0630 | 11-05 | full | owner | 1.4 | – | – | – | – | quiet | 0 | 47 (2) |
| 81 | 2026-11-06-0631 | 11-05 | full | · | 7.7 | – | – | – | – | quiet | 0 | 317 (8) |
| 82 | 2026-11-06-0753 | 11-05 | full | loop | 1.2 | – | – | h | r | refire | 3/0 (8378) | 86 (3) |
| 83 | 2026-11-06-0851 | 11-06 | full | owner | 1.6 | – | – | – | – | quiet | 0 | 78 (3) |
| 84 | 2026-11-06-0956 | 11-06 | full | loop | 6.0 | – | Q | h | – | caught | 0/1 (160) | 79 (3) |
| 85 | 2026-11-07-0115 | 11-06 | full | owner | 9.2 | – | X | – | – | caught | 0 | 71 (4) |
| 86 | 2026-11-07-0145 | 11-06 | full | owner | 2.4 | – | – | – | – | quiet | 0 | 145 (3) |
| 87 | 2026-11-07-0148 | 11-06 | full | · | 14.3 | – | – | h | r | refire | 0 | 239 (6) |
| 88 | 2026-11-07-0500 | 11-06 | full | owner | 11.6 | F | – | D | r | caught | 2/1 (6695) | 157 (6) |
| 89 | 2026-11-07-0534 | 11-06 | full | (loop) | 1.3 | – | – | – | – | quiet | 0 | 56 (5) |
| 90 | 2026-11-07-0603 | 11-06 | full | (loop) | 6.7 | – | – | – | – | quiet | 1/0 (337) | 102 (4) |
| 91 | 2026-11-07-0620 | 11-06 | full | owner | 1.1 | – | – | s | – | quiet | 0 | 71 (4) |
| 92 | 2026-11-07-0621 | 11-06 | full | · | 2.6 | – | – | s | r | refire | 0 | 328 (8) |
| 93 | 2026-11-07-0650 | 11-06 | full | (loop) | 10.8 | – | – | – | – | quiet | 1/1 (305) | 128 (3) |
| 94 | 2026-11-07-0745 | 11-06 | full | (loop) | 0.8 | – | – | s | – | quiet | 0 | 105 (3) |
| 95 | 2026-11-07-2324 | 11-07 | full | · | 21.1 | – | – | D | r | caught | 0/1 (11) | 612 (10) |
| 96 | 2026-11-07-2353 | 11-07 | full | loop | 12.7 | – | – | h | r | refire | 2/0 (930) | 64 (3) |
| 97 | 2026-11-08-0016 | 11-07 | full | loop | 15.1 | – | – | – | r | refire | 1/0 (176) | 131 (3) |
| 98 | 2026-11-08-0036 | 11-07 | full | loop | 5.4 | – | – | h | r | refire | 0 | 109 (3) |
| 99 | 2026-11-08-0600 | 11-07 | full | · | 2.9 | – | – | – | r | refire | 0 | 34 (1) |
| 100 | 2026-11-10-1902 | 11-10 | full | owner | 11.6 | – | X Q | D | r | caught | 0 | 390 (9) |

## Appendix B: the script behind the group figures and the replay

It reads Appendix A from this file. Run it from the repo root:

```sh
python3 - docs/working/research-2026-11-10-cycle-overhead-numbers.md <<'EOF'
import re, sys, datetime as dt, statistics as st, collections
rows = [[c.strip() for c in l.split('|')[1:-1]] for l in open(sys.argv[1]) if re.match(r'\| \d+ \| 2026-', l)]
def t(r):  # the record says 2026-11-02-1438's name is mistyped: UTC was 0647
    return dt.datetime.strptime('2026-11-02-0647' if r[1] == '2026-11-02-1438' else r[1], '%Y-%m-%d-%H%M')
rows.sort(key=t)
KIND, WALL, OUT, NEW = 3, 5, 10, 11
print('kinds', collections.Counter(r[KIND] for r in rows), 'outcomes', collections.Counter(r[OUT] for r in rows if r[OUT]))
print('per local day', collections.Counter(r[2] for r in rows))
def wall(name, pick):
    w = [float(r[WALL]) for r in rows if r[WALL] != 'n/a' and pick(r)]
    q = st.quantiles(w, n=4) if len(w) > 3 else ['', '', '']
    print('wall', name, 'n', len(w), 'median', round(st.median(w), 1), 'middle half', q[0], q[2], 'max', max(w), 'total', round(sum(w)))
wall('all', lambda r: True)
for k in ('full', 'light'): wall(k, lambda r: r[KIND] == k)
for o in ('caught', 'refire', 'quiet'): wall(o, lambda r: r[OUT] == o)
moved, tab = False, collections.Counter()  # main moved since the previous full iteration started
for r in rows:
    moved = moved or r[NEW] != '0'
    if r[KIND] == 'full': tab[(r[OUT], 'moved' if moved else 'not moved')] += 1; moved = False
print('main moved', sorted(tab.items()))
def sim(rule):
    full, moved, days, last = [], False, set(), None
    for r in rows:
        moved = moved or r[NEW] != '0'
        if r[KIND] == 'stopped': continue
        first = r[2] not in days; days.add(r[2])
        if last is None or rule((t(r) - t(last)).total_seconds() / 3600, first, moved):
            full.append(r); last = r; moved = False
    waits = [(r[1], next((round((t(f) - t(r)).total_seconds() / 3600, 1) for f in full if t(f) > t(r)), None))
             for r in rows if r[OUT] == 'caught' and r not in full]
    return len(full), sum(1 for r in rows if r[OUT] in ('quiet', 'refire') and r not in full), waits
for name, rule in [('every 6 h', lambda h, f, m: h >= 6), ('every 24 h', lambda h, f, m: h >= 24),
                   ('first of the local day', lambda h, f, m: f), ('main moved', lambda h, f, m: m),
                   ('main moved, or first of the local day', lambda h, f, m: m or f)]:
    n, light, w = sim(rule)
    print(name, '| full', n, 'of 96 | quiet or re-fire turned light', light, 'of 50 | catches delayed', len(w), w)
EOF
```

## 9. Options for the owner

The question, for the dev cycle to file: between full dev-cycle iterations, should the
orchestrator run a light pass (collect loop results, write briefs, dispatch and land,
skipping the four checking steps), and if so, what brings a full cycle back? The answer
would replace the one in Q-154, the archived owner entry where the owner chose a full
cycle every iteration for now and a light pass "once the costs are visible".

"Replayed" below means section 7's table: the recorded iterations re-run under the rule.
A "catch" is something the checking steps found; there were 22 in 26 days.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Full cycle every iteration** | Q-154's answer stays. The skill already says this; holding to it means the orchestrator stops choosing light passes and writes every verdict out. | None if left to the skill's prose, which was not followed in 51 of 96 iterations. One merge to approve if a check should enforce it. | The repeats go on, and grow if the rule is really held: 50 of the 72 full iterations found nothing new. What that costs in tokens is unmeasured. |
| **[2] Full when main moved or a new day starts, light otherwise** | A full cycle on a day's first iteration and whenever main gained anything but a cycle land since the last full cycle. Otherwise collect, briefs, dispatch and land. | One merge to approve: it changes the dev-cycle skill, which never self-merges. | Whatever is not a commit on main waits for the next day's first iteration: a model change, a release, a dated trigger, a stale item. Replayed, 4 of 22 catches waited, 2 of them really (1 and 3.8 hours). The saving it buys is unmeasured. |
| **[3] One full cycle a day, light otherwise** | The first iteration of each day is full; every other one is light. Close to Q-154's second option (a full cycle every N hours), with the day's first iteration in place of a fixed interval. | One merge to approve, as for [2]. | Most catches wait a day. Replayed, 15 of 22 waited a median of 18 hours and up to 5 days, and 9 of those came from spot-check sampling that a later cycle might never repeat. Unless the light pass keeps the health check, it would not run after a loop merge until the next day. |
| **[4] Measure tokens first, then decide** | Q-154's answer stays for now. A docs-only unit totals tokens per iteration from the session transcripts that already exist, with no model run, or the record gains a token line (section 6). This question comes back with the numbers. | This question reaches you once more. A merge to approve only if the token line goes into the skill. | The repeats continue meanwhile. If the transcripts cannot be matched to iterations, the numbers need a few weeks of new records instead. |

- **Interim:** [1] as written. Q-154's answer stays in force until this is answered.
- **Recommendation, not a pick: [4], and then [2] if the tokens show the repeats cost
  something.** Q-154's own condition, "once the costs are visible", is not met: wall time,
  the one cost that could be measured, shows little to save, and tokens are not recorded.
  The project's constraint S7 (`docs/constraints.md`) says to measure before budgeting a
  saving. If you would rather settle it now, [2] gives up the least: it is the condition
  the health check already uses to skip itself, and it is close to practice (under [2], 52
  of the 96 iterations would be light; in fact 51 either ran light or carried their
  verdicts forward).
- **What no option here fixes:** the deep-audit check fired 22 times into a task that has
  not run. [2] removes 4 of its 10 re-fire-only iterations. Whether and how to run that
  audit is Q-269, an owner entry already open.
