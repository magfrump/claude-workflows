# Research: what the dev cycle costs per iteration (numbers for the light-pass decision)

- **Goal**: Give the owner, from the repo's own records and history, how many dev-cycle iterations ran since 2026-10-16, how many found or changed anything outside their own bookkeeping, and what each kind cost, so they can decide the light pass.
- **Problem framing**: The owner chose a full cycle every iteration "until the costs are visible", and nobody has totalled the costs. Considered and discarded: "the cycle is too slow" (wall time turns out to be minutes per iteration; what is unknown is tokens, which no record holds).
- **Project state**: this branch delivers one research doc, docs only · the first step of roadmap Next 3 (revisit the light pass), the later skill change being a separate unit · not blocked (cite: docs/working/briefs/2026-11-10-cycle-overhead-numbers.md)
- **Task status**: complete (numbers checked by an independent review pass, see Review)

Brief: `docs/working/briefs/2026-11-10-cycle-overhead-numbers.md` (self-merge, docs only).
Everything here was read at main's commit a37733cc. Nothing was run to measure cost.

Words used below. An **iteration** is one `## Iteration` block in a cycle record
(`docs/working/cycles/cycle-*.md`). **Steps 2, 3, 4 and 4b** are the dev-cycle skill's
revisit triggers, watched questions, claim spot-check and deep-audit check. A **light pass**
is an iteration that skips them and only collects build-loop results, writes briefs,
dispatches and lands (steps 7, 8 and 10). **Q-154** is the archived owner entry where the
owner chose a full cycle every iteration for now. A **land** is the merge commit that puts
an iteration's bookkeeping on main. A **loop merge** is a build loop's branch merged to
main, either approved by the owner or self-merged.

## Summary

1. **100 iterations** are recorded from 2026-10-16 to 2026-11-10, on 16 working days (US
   Pacific): a median of 5 a day, 17 on the busiest day.
2. **The cycle has not run a full cycle every iteration.** 72 iterations ran steps 2 to 4b,
   24 were light passes the orchestrator chose on its own (the skill has no light pass),
   and 4 stopped at step 0. Of the 72 "full" ones, 27 wrote one line for all triggers
   ("as at iteration X") where the skill asks for each to be decided again.
3. **42 of the 72 full iterations (58%) were quiet**: steps 2 to 4b produced nothing. 8
   more (11%) only re-fired the deep-audit check onto a task that already existed. 22 (31%)
   produced something: 3 fired triggers, 2 met watches, 2 failed claims, 7 drift findings,
   5 other findings, and a few small in-cycle fixes.
4. **Wall time is small and a light pass saves little of it.** By commit times a full
   iteration took a median of 7.7 minutes and a light one 2.9; a quiet full iteration took
   3.8. All 96 measurable iterations together took about 16 hours over 26 days.
5. **Tokens are not recorded anywhere in this repo.** The cost the owner asked about is
   still not visible. Section 6 names the smallest change that would record it.
6. **Bookkeeping against features**: the cycle's 129 lands changed 15,522 lines, all in
   records, questions files, briefs and the roadmap. In the same period 42 loop merges
   changed 31,878 lines, 12,109 of them outside `docs/`.
7. **What a light pass would have missed depends on what brings the full cycle back.** If a
   full cycle ran whenever main gained anything but a cycle land, or on the first iteration
   of a day, 44 of 96 iterations would have been full and 4 of the 22 catches would have
   waited 1 to 27 hours. With one full cycle a day, 14 would have been full and 15 catches
   would have waited a median of 18 hours.

## 1. Method and commands

Run these from the repo root at a37733cc. `83b653d2` is the `Main at:` commit of the first
iteration counted.

```sh
# iterations since 2026-10-16 (100), and per local day
rg -o -N -I '^## Iteration \S+' docs/working/cycles/ | awk '$3 >= "2026-10-16" {print $3}' | sort > ids.txt
wc -l < ids.txt
while read -r i; do TZ=America/Los_Angeles date -d "${i:0:10} ${i:11:2}:${i:13:2} UTC" +%F; done < ids.txt | uniq -c

# the lines every hand classification below was read from
rg -n '^(0|2|3|4|4b)\. ' docs/working/cycles/
# verdict lines per iteration (20 or more: a full list; 1: one "as at" line)
awk '/^## Iteration/{id=$3} /^### /{s=$0} s=="### Trigger verdicts" && /^- /{n[id]++} END{for(i in n) print i, n[i]}' docs/working/cycles/cycle-*.md | sort

# main's own history: 233 commits, 129 cycle lands, 42 loop merges, 62 others
git rev-list --first-parent --count 83b653d2..a37733cc
git log --first-parent --format='%s' 83b653d2..a37733cc | rg -c "^Merge branch 'chore/dev-cycle-"
git log --first-parent --format='%s' 83b653d2..a37733cc | rg -c '\(build-loop (approved merge|self-merge)\)$'

# wall time: minutes from the iteration's name (UTC) to its last land's commit time
git log --first-parent --format='%ct %s' 83b653d2..a37733cc \
  | sed -n "s/^\([0-9]*\) Merge branch 'chore\/dev-cycle-\([0-9-]*\)'.*/\2 \1/p" | sort -k1,1 -k2,2n \
  | awk '{t[$1]=$2} END{for (i in t) print i, t[i]}' | sort \
  | while read -r i t; do echo "$i $(( (t - $(date -u -d "${i:0:10} ${i:11:2}:${i:13:2}" +%s)) / 60 ))"; done

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

# tokens: no file is printed
rg -il 'token' docs/working/cycles/ docs/working/weekly/
```

Three things are read by hand, not by a command: what kind each iteration was, who started
it, and whether steps 2 to 4b produced anything. Appendix A lists all three for every
iteration, so each call can be checked against its record line. The rule for "produced"
is in section 3.

## 2. How many iterations, and how long they took

**Count.** 100 iterations, from 2026-10-16-0510 to 2026-11-10-1902 (names are UTC), in 15
record files. [observed] The count is of iterations that wrote a record. The skill says an
iteration that stops at step 0 writes none, so any such iteration is not in this number.

**Kinds**, by what the record itself says: [observed]

| Kind | Count | What the record says |
|---|---|---|
| Full | 72 | Steps 2, 3, 4 and 4b each have a result line |
| Light | 24 | 20 say "light pass" (2026-10-31-2325 to 2026-11-02-1846), 2 say "a light iteration" (2026-10-17), 2 say "owner-directed merge pass" (2026-10-30) |
| Stopped | 4 | "skipped: step 0.2 stopped" on every step (2026-10-16-0510, 2026-10-17-1846, 2026-10-20-0346, 2026-10-20-1923) |

The dev-cycle skill has no light pass, and Q-154's answer was a full cycle every iteration.
The 24 light iterations were the orchestrator's own choice; the records give no rule for
when it chose one, and it stopped choosing them after 2026-11-02 without a recorded reason.

**Per day** (the owner's local day; lines are added plus removed):

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
| 2026-11-03 | 3 | 3/0/0 | 0/0/3 | 20 | 4 (390) | 1 (647) | 2 (172) |
| 2026-11-05 | 7 | 7/0/0 | 2/0/5 | 205 | 9 (947) | 4 (8731) | 1 (21) |
| 2026-11-06 | 12 | 12/0/0 | 3/2/7 | 68 | 15 (1559) | 4 (7298) | 3 (199) |
| 2026-11-07 | 5 | 5/0/0 | 1/4/0 | 57 | 6 (950) | 3 (1106) | 1 (11) |
| 2026-11-10 | 1 | 1/0/0 | 1/0/0 | 12 | 1 (390) | 0 (0) | 0 (0) |
| **Total** | **100** | **72/24/4** | **22/8/42** | **958** | **129 (15522)** | **42 (31878)** | **49 (17826)** |

Commits are counted on the day they were made, so the first iteration's land shows under
2026-10-17. Thirteen more "other" commits fell on days with no iteration (2026-10-16, -18,
-21 and -23: 8, 2, 1 and 2 commits, 1,588 lines), which makes 62 commits and 19,414 lines
in all. The date command
in section 1 prints 16 for 2026-11-01 and 8 for 2026-11-02, because iteration
2026-11-02-1438 carries a mistyped name; its record says the real time was 06:47 UTC, and
the table uses that.

**Wall time**, from commit times. The start is the minute in the iteration's name, which
the orchestrator sets when it creates its worktree at step 0.3. The end is the committer
time of the iteration's last land. 96 of 100 can be measured; four cannot (one landed 38
hours later from another session, three have a name later than their own land). [observed]

| Group | Measurable | Median minutes | Middle half | Longest | Total minutes |
|---|---|---|---|---|---|
| All | 96 | 5.6 | | 182 | 958 |
| Full | 72 | 7.7 | 2.7 to 14.1 | 182 | 834 |
| Light | 22 | 2.9 | 1.8 to 5.4 | 45 | 118 |
| Full, caught something | 22 | 12.0 | | 182 | 472 |
| Full, re-fire only | 8 | 12.7 | | 15 | 79 |
| Full, quiet | 42 | 3.8 | | 23 | 283 |
| Full, quiet, health check re-run | 16 | 10.2 | | | 190 |
| Full, quiet, health check "unchanged" | 25 | 2.4 | | | 89 |

Two stopped iterations make up the rest of "All". The 182-minute iteration is
2026-11-05-2347, whose health check passed on its third run. The name's minute can be
trusted in most cases: for 38 iterations started by a build loop, the loop's own marker
commit (`handoff: ready` or `handoff: blocked`) gives an independent start, and 32 of the
38 names are within a minute of it. From marker to land, those 38 took a median of 3.5
minutes. [observed]

What this shows: a quiet full iteration whose health check did not need re-running took
about as long as a light pass (2.4 against 2.9 minutes). The health check already skips
itself when main moved only by cycle lands, and it is what makes an iteration long.

## 3. What steps 2, 3, 4 and 4b produced

**The rule used.** A step "produced" something when its record line reports one of: a
trigger newly fired (step 2); a watch met, a stale agent item done or corrected in-cycle,
or a stale item or finding turned into a new owner entry or agent item (step 3); a claim
that did not hold, a drift finding, any other finding, or an in-cycle fix (step 4); a
deep-audit task filed (step 4b). Three things are not counted. Recording or applying the
owner's answers appears on the step 3 line of many records, but it is collect's work
(step 7), which a light pass keeps. Writing a brief for a stale item is step 8's work. And
when step 4b fires for a cause the open deep-audit task already names, with nothing else
new, the iteration is counted apart as **re-fire only**.

**Result**, over the 72 full iterations: [inferred from reading each record line; Appendix A]

| Outcome | Iterations | Share of 72 |
|---|---|---|
| Caught something | 22 | 31% |
| Re-fire only | 8 | 11% |
| Quiet (nothing) | 42 | 58% |

Quiet or re-fire only: 50 of 72 (69%). Of all 100 recorded iterations, 22 produced
something from these four steps.

**By kind of product** (an iteration can appear in more than one row):

| Product | Iterations | Which |
|---|---|---|
| Trigger newly fired (step 2) | 3 | 2026-10-17-1912, 2026-10-20-1938, 2026-11-07-0500 |
| Evidence for a verdict corrected, verdict unchanged (step 2) | 1 | 2026-11-05-2347 |
| Watch met (step 3) | 2 | 2026-10-28-2136, 2026-10-29-2003 (the same watch, Q-074) |
| Stale item done or corrected in-cycle (step 3) | 5 | 2026-10-17-1912, 2026-10-26-0002, 2026-11-02-2027, 2026-11-07-0115, 2026-11-10-1902 |
| Stale item or finding became a new entry or item (step 3) | 3 | 2026-10-30-0731, 2026-11-06-0956, 2026-11-10-1902 |
| Claim did not hold (step 4) | 2 | 2026-10-29-0235, 2026-11-02-0326 |
| Drift finding (step 4) | 7 | 2026-10-20-2344, 2026-10-28-2223, 2026-10-30-0035, 2026-11-06-0317, 2026-11-07-0500, 2026-11-07-2324, 2026-11-10-1902 |
| Other finding (step 4) | 5 | 2026-10-20-1938, 2026-10-26-0002, 2026-10-26-0027, 2026-10-29-2212, 2026-10-30-0100 |
| Deep-audit task filed (step 4b) | 7 | 2026-10-20-1938, 2026-10-20-2344, 2026-10-28-2136, 2026-10-28-2223, 2026-10-30-0035, 2026-11-06-0317, 2026-11-10-1902 |
| Deep-audit check re-fired onto the existing task (step 4b) | 12 | the 8 re-fire-only iterations, and 4 that also caught something else |

Three patterns stand out.

- **Step 2 wrote 1,071 verdict lines and 3 of them were new firings.** 39 of the 72 full
  iterations wrote a full list (22 to 28 lines each), 6 wrote a few lines plus "the others
  as at", and 27 wrote one line for all triggers. [observed]
- **Step 4b fired or re-fired in 19 iterations, and all 19 feed one piece of work that has
  not run**: the scoped deep audit, a roadmap Ideas item since 2026-10-02 and an agent task
  in the roadmap's Now since 2026-11-05. Its scope and timing are the owner's to confirm,
  and became owner entry Q-269 on 2026-11-10. All 7 drift findings feed it too; in 6 of
  the 7 the record says the pick stands or calls the finding minor. [observed]
- **Step 4 had a new commit to check in 33 of the 72 iterations.** In the other 39 it
  checked only the cycle's own lands, re-checked a merge it had already checked, or was
  skipped. [inferred from reading each step 4 line]

**Main moved, or not.** For each full iteration, "main moved" means main gained a commit
other than a cycle land since the previous full iteration started (from the records'
`Main at:` lines). [observed]

| | Main had moved | Main had not moved |
|---|---|---|
| Caught something | 18 | 4 |
| Re-fire only | 4 | 4 |
| Quiet | 14 | 28 |

So of the 36 full iterations that ran when main held nothing new but cycle lands, 28 were
quiet, 4 were re-fire only and 4 caught something (2026-10-28-2223, 2026-10-29-0235,
2026-11-07-0115, 2026-11-10-1902; section 7 says what each was).

## 4. What each iteration landed, against feature and fix merges

Per iteration, Appendix A gives the lines and files of its own lands and the loop merges
and other commits that reached main since the previous iteration started. Totals: [observed]

| On main since 83b653d2 | Commits | Lines added | Lines removed | File changes |
|---|---|---|---|---|
| Cycle lands (bookkeeping) | 129 | 12,821 | 2,701 | 495 |
| Loop merges | 42 (34 approved by the owner, 8 self-merged) | 27,349 | 4,529 | 325 |
| Other commits (the owner's, and hand merges from other sessions) | 62 | 17,104 | 2,310 | 209 |

- **The cycle's lands touch only its own files.** By file: questions files 6,787 lines,
  records 4,908, briefs 2,391, roadmap 1,293, idea log 116, one feedback file 27. 71
  iterations landed once and 29 landed twice (the second land carries the dispatch lines).
- **A typical land**: a full iteration changed a median of 105 lines in 4 files, a light
  one 78 lines in 3 files. The 42 quiet iterations landed 5,474 lines, about a third of
  all the bookkeeping.
- **Loop merges**: 12,109 of their 31,878 changed lines are outside `docs/` (code, tests,
  skills, workflows). The other 19,769 are the loops' own research docs, briefs and review
  reports. 36 of the 42 merges touch something outside `docs/`.
- **Ratios**: 100 iterations and 129 lands for 42 loop merges, so 2.4 iterations and 3.1
  lands per merge. The cycle landed 0.49 bookkeeping lines for each line the loops merged,
  and 1.28 for each line they merged outside `docs/`.
- **Other commits**: 17 of the 62 change only the questions files or the owner's answer
  files; 19 touch something outside `docs/`.

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

Four of the 26 unstated ones begin within a minute of a loop's marker commit
(2026-11-07-0534, -0603, -0650 and -0745), so a loop probably started them. [inferred]
No iteration was started by a wakeup. Four records mention five wakeups (about 00:42 UTC
on 2026-10-21, about 01:19 UTC on 2026-10-26, and 19:56, 23:09 and 23:40 local time on
2026-11-05), and each says the wakeup found a loop still working and ran no iteration. The owner's answers often cost two
iterations: one to land the answer on main, and a second to apply it, because the gate
reads a merge entry's answer only from main.

## 6. Tokens

**No record or log in this repo holds per-iteration token counts.** The word "token" does
not appear in any cycle record or weekly digest. Usage fields (`input_tokens`,
`total_cost_usd`, `num_turns`) appear only in review-benchmark runs under `runs/` and
`archive/`, in review artifacts dated August to early October, and in scripts and tests
that parse a headless run's envelope; none is about a dev-cycle iteration. [observed] The orchestrator runs as an
interactive session, so it leaves no JSON envelope the way a headless `claude -p` run does.
This doc gives no estimate.

**The smallest change that would record them** (a suggestion only; nothing here is built):
one line in the record's header, next to `Model:`, written at step 9:

```
Tokens: <input / output / cache-read for this iteration, from the session transcript>
```

A second part is optional: step 7 copies the usage a finished build loop reports into its
`7.` line, so loop cost and orchestrator cost can be told apart. Two facts bear on how hard
this is. Session transcripts exist outside the repo, in the sandbox's home volume
(`~/.claude/projects/-workspace/`, 67 files dated 2026-10-12 to 2026-11-10); counting
fields in one, without reading its content, found 841 `usage` fields and 3,308
`timestamp` fields. [observed] So a small script could total usage between an iteration's
first and last message. Whether an orchestrator session can name its own transcript file,
and whether a loop's task notification carries its usage, were not checked. [assumed] The
same transcripts would also allow a one-off total for the 100 past iterations with no
model run; this brief limits itself to the repo's records, so that was not done.

## 7. What a light pass would have skipped, and what it would have missed

**Skipped.** In the 50 full iterations that were quiet or re-fire only, this work was
repeated with the same result:

- Step 2: 23 of them wrote a full verdict list again (600 verdict lines, none a new
  firing); the other 27 wrote one "as at" line or a few lines.
- Step 3: the same watches were read as not met each time: Q-067, Q-098 and Q-161
  throughout (they wait on a sandbox merge and a measurement run, neither of which has
  happened), Q-074 until it was met on 2026-10-28, and Q-262 and Q-264 from 2026-11-07.
- Step 4: 16 checked a new commit and it held; 34 had nothing new to check.
- Step 4b: 8 re-fired onto the existing deep-audit task; 42 said nothing new.
- Around them, a light pass would also skip the digest, the health check (re-run in 21 of
  the 50), the brainstorm check (it ran in 1 of the 50) and the roadmap step.

In wall time that is 362 minutes over 26 days, against about 3 minutes each for the
light passes that would replace them. In tokens it is unknown.

**Missed, in practice.** The 24 light iterations already run are a small test. What the
records show they put off is the deep-audit check: four light passes say a merge changed
`skills/dev-cycle/SKILL.md` and "the next full cycle's 4b sees it", and the next full
cycle did, between 5 minutes and about 6 hours later. One more thing came late: the full
cycle at 2026-11-02-0326 drew a lesson for step 8 from two merge conflicts that a light
pass had reported 3.6 hours earlier (Q-246, Q-247). No other record of a full cycle that
followed a light run reports something a light pass had put off. [observed]

**Missed, replayed.** Suppose the 96 iterations that were not stopped had run at the same
times under a rule, with every other iteration a light pass. For each of the 22 catches,
how long until the next full cycle? (Appendix B has the script.) These waits are upper
bounds: a catch is credited to the iteration that recorded it, and under another schedule
an earlier full cycle might have made it.

| Rule for a full cycle | Full cycles out of 96 | Catches that would have waited | Their wait |
|---|---|---|---|
| Every iteration (today's rule) | 96 | 0 | |
| Main moved (anything but a cycle land), or the first iteration of a local day | 44 | 4 of 22 | 1, 3.8, 17 and 27 hours |
| Main moved only | 39 | 5 of 22 | the same four, and one never re-run by the end of the data |
| First iteration of a local day | 14 | 15 of 22 | median 18 hours, longest 120 |
| Every 24 hours | 12 | 14 of 22 | median 24 hours, longest 120 |

The 120-hour wait is 2026-10-20 to 2026-10-25, when no iteration ran. The catch that
"main moved only" never re-runs is 2026-11-10-1902: the model had changed and a release
had happened, and neither is a commit on main.

**The 22 catches**, with whether main had moved and how long each would have waited under
the two middle rules (0 means that iteration would still have been a full cycle):

| Iteration | What steps 2 to 4b caught | Main moved | Wait, moved-or-first-of-day | Wait, first-of-day |
|---|---|---|---|---|
| 2026-10-17-1912 | Decision 031's trigger fired (owner entry Q-194); three finished agent entries marked landed | yes | 0 | 0 |
| 2026-10-20-1938 | Log row 73's trigger fired (Q-213); a gap in the image-lag entry found; deep-audit task filed | yes | 0 | 0 |
| 2026-10-20-2344 | Drift finding on merge 43762305 (a soft constraint pruned options); deep-audit task filed | yes | 0 | 120 h |
| 2026-10-26-0002 | Four finished agent entries marked done; a stale sentence in log row 53 found (that iteration's merge fixed it) | yes | 0 | 0 |
| 2026-10-26-0027 | `profiles/interview/README.md` found to misstate behaviour (fixed by self-merge 9b8a0b34) | yes | 0 | 69 h |
| 2026-10-28-2136 | Watch Q-074 met and sent to the owner as Q-223; deep-audit task filed for decision 040 | yes | 0 | 0 |
| 2026-10-28-2223 | Drift finding on merge 68287ee2; added to the deep-audit task | no | 1 h | 21 h |
| 2026-10-29-0235 | The previous iteration's land had cut a brief down to one line; restored in-cycle | no | 17 h | 17 h |
| 2026-10-29-2003 | Watch Q-074 met by merge f91d7d09 | yes | 0 | 11 h |
| 2026-10-29-2212 | A test on a loop's branch fails in this sandbox on a locale warning; passed to the loop | yes | 0 | 9 h |
| 2026-10-30-0035 | Drift finding on merge 6ee39f24; added to the deep-audit task | yes | 0 | 6.5 h |
| 2026-10-30-0100 | `migrations.sh check .` fails with a relative root; briefed, fixed by merge ea1ab6fe | yes | 0 | 6 h |
| 2026-10-30-0731 | A stale item's hold could no longer be met; became owner entry Q-238 | yes | 0 | 39 h |
| 2026-11-02-0326 | A brief's claim that three units could run in parallel did not hold; step 8 changed how it splits | yes | 0 | 5 h |
| 2026-11-02-2027 | A stale roadmap item removed and one line corrected | yes | 27 h | 27 h |
| 2026-11-05-2347 | The evidence line for log row 57 corrected; verdict unchanged | yes | 0 | 0 |
| 2026-11-06-0317 | Two drift findings on self-merge 605d4c18; deep-audit task filed | yes | 0 | 6 h |
| 2026-11-06-0956 | Two agent items filed from the weekly digest | yes | 0 | 37.5 h |
| 2026-11-07-0115 | A leftover item of Q-241 done in-cycle | no | 3.8 h | 22 h |
| 2026-11-07-0500 | Decision 040's trigger fired on the owner's feedback, which became the gloss-rule brief (merged 771c84e8); minor drift finding | yes | 0 | 18 h |
| 2026-11-07-2324 | Minor drift finding on merge aeab6745 | yes | 0 | 0 |
| 2026-11-10-1902 | A stale item done in-cycle; the deep audit became owner entry Q-269; minor drift finding; the model change added a deep-audit trigger | no | 0 | 0 |

Notes on the four that would have waited under the moved-or-first-of-day rule:

- 2026-10-29-0235 (17 h): a light pass would have seen this one anyway. The same record's
  step 7 line says `--status` refused the cut-down brief, and the loop had reported it.
- 2026-11-02-2027 (27 h): under this rule a full cycle would have run 100 minutes
  earlier, at 2026-11-02-1846 (in fact a light pass), and could have made the same roadmap
  correction.
- 2026-10-28-2223 (1 h) and 2026-11-07-0115 (3.8 h): a drift finding on an older merge
  that step 4 reached by sampling, and a leftover agent item.

One cost does not show in the table: step 4 samples one or two merges per iteration, so
fewer full cycles means fewer merges spot-checked, unless a full cycle samples more.

## 8. What the numbers cannot show

1. **Tokens.** Nothing records them (section 6).
2. **Whether a step was run or carried forward.** 27 of the 72 full iterations wrote one
   "as at iteration X" line for all triggers, and many step 3 and step 4 lines read "as at"
   or "as checked at". The record cannot show whether the check was made again. "Quiet"
   therefore means the record reports nothing new, not that each check was repeated and
   found nothing. The brief's own motive says iterations 2026-11-08-0036 and
   2026-11-08-0600 "each re-decided all 28 revisit triggers"; their records hold one line
   each: "All 28 as at iteration 2026-11-07-2324".
3. **Whether a written-out verdict was decided from evidence.** Iteration 2026-11-05-2347
   corrected the evidence for log row 57: earlier records said a test run had not happened,
   and it had (`docs/working/si-trust-evidence-2026-10-14.md`). The next two full lists
   (2026-11-07-2324 and 2026-11-10-1902) say "no Q-075 run" again. The verdict, not fired,
   was the same either way.
4. **The start and end of an iteration.** The name's minute is typed by the orchestrator;
   one record says its own name is wrong and three more are later than their own land.
   Steps 0.1 and 0.2 run before the name exists and the final message comes after the last
   land, so the wall times are slightly short.
5. **Who started 26 iterations, and how many wakeups there were.** A wakeup that runs no
   iteration leaves a trace only if a later record mentions it.
6. **Iterations that left no record.** A stop at step 0 writes none by design.
7. **The value of a check that held.** These numbers count findings. A spot-check that
   passes is still information, and it is counted here as nothing.
8. **What another schedule would have caught.** Section 7's waits credit each catch to the
   iteration that recorded it.
9. **The build loops' own cost.** Their research, reviews and fix rounds are outside the
   iteration and outside this doc.
10. **Effort.** Line counts are not effort, and the hand classification could differ at
    the margin. The calls most open to argument: answer handling on step 3 lines is not
    counted (it is step 7's work); briefing a stale item is not counted; two agent items
    filed from the weekly digest (2026-11-06-0956) and a roadmap line corrected
    (2026-11-02-2027) are counted; a roadmap item moved to Done because a loop's merge
    finished it (2026-11-03-2329) is not.
11. **One model.** 99 of the 100 iterations ran on `claude-opus-5-5`; the last ran on
    `claude-fable-5-2`. Nothing here says how the next model's iterations will look.

## 9. Options for the owner

The question, for the dev cycle to file: between full dev-cycle iterations, should the
orchestrator run a light pass (collect loop results, write briefs, dispatch and land), and
if so, what brings a full cycle back? This would replace the answer in Q-154.

"Replayed" below means section 7's table: the 96 recorded iterations re-run under the rule.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Full cycle every iteration** | The answer you gave in Q-154 stays. The skill already says this; holding to it means the orchestrator stops choosing light passes on its own and writes every verdict out. | Nothing new. | You keep paying for repeats: 50 of 72 full iterations found nothing new. The cost in tokens is unmeasured; in wall time it is about 4 minutes each. |
| **[2] Full when main moved or a new day starts, light otherwise** | A full cycle on the first iteration of a day and whenever main gained anything but a cycle land since the last full cycle. Otherwise steps 7, 8 and 10 and the land. | One gate-code merge to review (the skill change). | Something that depends on neither waits for the next full cycle. Replayed: 4 of 22 catches waited 1 to 27 hours, 44 of 96 iterations stayed full. |
| **[3] One full cycle a day, light otherwise** | The first iteration of each day is full; every other one is light. This is Q-154's second option with a day as its interval. | One gate-code merge to review (the skill change). | Most catches wait for the next day. Replayed: 15 of 22 waited a median of 18 hours and up to 5 days; 14 of 96 stayed full; far fewer merges get spot-checked. |

Recommendation, not a pick: **[2]**. It is the rule the health check already uses (skip when
only cycle lands moved main), it is close to what the orchestrator has been doing without
a rule, and replayed it gives up little. Two cautions. The saving is unproven: wall time
shows almost nothing to save, and tokens are not recorded, so recording them (section 6)
should come with whichever option is taken. And [2] does not touch the largest repeat this
doc found, the deep-audit check firing 19 times into a task that has not run; that is
Q-269's subject, not this question's.

## Research notes

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
  options in section 9 are for the cycle to file, not filed here.

### Prior art

- `docs/reviews/performance-review-2026-10-13-u4b2-final.md` and `-i2.md` named this
  measurement before the orchestrator first ran ("measure tokens per iteration over one day
  of loop operation first") and proposed the no-change iterations as the first candidates
  for a light pass.
- Idea-log line 56 asks for the share of an iteration's tokens spent on one pasted block;
  it has the same gap this doc reports: no token record.
- No earlier doc counts iterations or classifies them.

### Gotchas

Failure-pattern grep: FP-108, FP-110, FP-114, FP-176 (see Prior failures)

The grep was `grep -inE 'under-?count|miscount|timezone|time-zone|utc|dst|numstat|rename|cycle-record|docs/working/cycles|dev-cycle|instrument|measure|wrong-denominator' docs/failure-patterns.md`.
It also matched FP-038, FP-043 and FP-138, which are about file renames in code and do not
bear on a measurement.

- Names are UTC and record files are dated in local time, so one local day spans two UTC
  dates. The per-day table uses the local day.
- `git diff --numstat` without `-M` counts a brief moved to `closed/` as a full delete and
  a full add: briefs came to 6,825 lines that way, 2,391 with `-M`.
- Some `Main at:` lines hold a short hash, and one iteration's is older than the one before
  it (the mistyped name puts it out of order).
- The step 3 line of many records holds answer handling, which is step 7's work.

#### Prior failures

- FP-108 (a record summed results, not the ledger of attempts) and FP-110, FP-114 (failed
  cells removed themselves from the denominator): the denominators here are stated each
  time (100 recorded, 72 that ran the steps, 96 not stopped), stopped and light iterations
  are shown and not dropped, and section 8 says which attempts leave no record (stops at
  step 0, wakeups).
- FP-176 (a dev-cycle count that counted the cycle's own lines): cycle lands are separated
  from loop merges and hand commits by commit subject before anything is summed, and "main
  moved" excludes the cycle's own lands.

### Design choices

The brief's own lines are the hard constraints here: repo records and history only, every
count re-runnable, no token estimate, no pick for the owner. H1 to H4 in
`docs/constraints.md` concern gates and tests and bear on none of these choices. Options
are pruned only on the brief's lines; the soft constraints only rank.

**D1. How to measure wall time** (divergent design, Path A).

| Candidate | Brief's lines | Ranking notes |
|---|---|---|
| A. Name's minute to last land's commit time | passes; covers all 100 | the name is typed, so it needs a cross-check |
| B. Loop marker's commit time to last land | passes; covers 38 | a real clock at both ends, but only for loop-started iterations |
| C. Gap between one iteration's land and the next | passes | includes idle waiting, so it measures the day, not the iteration |
| D. Timestamps in the record | fails: the records hold none | |
| E. Session transcripts | fails: outside the repo | |

Pick: A for every iteration, checked against B where B exists. D and E fail the brief's
lines. C survives but measures the wrong thing (S7: measure the thing being budgeted). A
and B do not compete: B validates A (32 of 38 within a minute). One option dominates.

**D2. Which day an iteration belongs to** (Path A). Candidates: the UTC date in its name,
the owner's local date, the record file's date. All pass the brief's lines. The record
file's date is ruled out by a fact: a file can hold several days (`cycle-2026-10-17.md`
holds iterations of 2026-10-20). Local date ranks above UTC because the question is the
owner's (S10: their attention, their days) and one evening's session would otherwise split
in two. Pick: local date, with the UTC command also shown.

**D3. What counts as quiet** (Path A). Candidates: strict (any "fired" line counts as a
product), narrow (only new things count), and a three-way split. The brief names the
products (a fired trigger, a met watch, a failed claim, a drift finding, an in-cycle fix).
A deep-audit re-fire onto an existing task fits neither side cleanly, and folding it into
either hides something. Pick: the three-way split, which shows both readings (42 quiet, or
50 with re-fires). It dominates because it loses no information.

**D4. Which merges belong to an iteration** (Path A). Candidates: by commit time between
iteration names, by position on main between `Main at:` lines, by the record's `Window:`
line. The `Window:` line is ruled out by a fact: it is a date, and windows on one day
overlap. `Main at:` ranks above commit time because it is the cycle's own definition of
what an iteration sees (S3: one source of truth) and does not depend on typed names. Pick:
`Main at:` to `Main at:`.

Other choices, one line each:
- Which rules to replay in section 7: not mine to choose; the two in Q-154 and roadmap
  Next 3 (an interval, a trigger) and their combinations are shown.
- A per-iteration table or only the non-quiet list: the brief asks "for each iteration",
  so Appendix A lists all 100.
- Whether to total the session transcripts: no; the brief limits this doc to the repo.

### Plan and verification

No plan doc: the brief's `Paths:` line allows this file and the brief only. Steps taken:
parse the records, read git history, classify by hand, compute, write, review. No code or
behaviour changes, so no tests were written and `test-strategy` was not run. Verification
is the commands in section 1 and Appendix B, re-run by the review pass.

| Failure mode | Guard |
|---|---|
| A count silently drops stopped or light iterations | every table states its denominator (100, 96 or 72) |
| A hand classification is wrong | Appendix A lists every call beside its iteration; an independent reviewer re-read a sample |
| A line count is inflated by renames | `-M` on every numstat; the command is shown |
| The doc picks for the owner | section 9 gives a table and one recommendation line marked as such |

`/pre-mortem` and `/architecture-review`: not triggered (one docs file, no trust boundary,
no module change). Rollback: `git revert -m 1` of this branch's merge commit; the change is
two docs files, nothing installed and no state.

## Files read

Last verified: 2026-11-10
docs/working/briefs/2026-11-10-cycle-overhead-numbers.md
docs/working/cycles/cycle-*.md
docs/working/questions-archive.md
docs/working/idea-log.md
docs/roadmap.md
docs/constraints.md
docs/failure-patterns.md
docs/decisions/log.md
docs/reviews/performance-review-2026-10-13-u4b2-final.md
docs/reviews/performance-review-2026-10-13-u4b2-i2.md
docs/working/research-2026-11-07-confine-tests-situation.md
skills/dev-cycle/SKILL.md
workflows/research-plan-implement.md
workflows/divergent-design.md
scripts/build-loop.sh
scripts/health-check.sh

## Appendix A: every iteration

Columns. **Local**: the owner's local date (month-day). **Kind**: full, light or stopped.
**By**: who started it: `loop`, `owner`, `went on` (the orchestrator went straight on),
`(loop)` (not stated, but a loop's marker commit is within a minute), `·` (not stated).
**Wall**: minutes from the name to the last land. **2, 3, 4, 4b**: what each step produced.
Step 2: `F` a trigger newly fired, `c` evidence corrected. Step 3: `W` a watch met, `X` a
stale item done or corrected in-cycle, `Q` a new entry or item. Step 4: `C` a claim did not
hold, `D` a drift finding, `O` another finding, `X` fixed in-cycle, `h` a new commit
checked and it held, `s` skipped, `–` only the cycle's own lands or a re-check. Step 4b:
`T` task filed, `r` re-fired onto the existing task. `–` means nothing. **New on main**:
loop merges / other commits that reached main between the previous iteration's `Main at:`
and this one's, with their changed lines. **Landed**: changed lines (files) in the
iteration's own lands.

| # | Iteration (UTC) | Local | Kind | By | Wall | 2 | 3 | 4 | 4b | Outcome | New on main | Landed |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 2026-10-16-0510 | 10-15 | stopped | · | n/a |  |  |  |  |  | 0 | 596 (3) |
| 2 | 2026-10-17-1846 | 10-17 | stopped | · | 4 |  |  |  |  |  | 0/8 (587) | 304 (2) |
| 3 | 2026-10-17-1912 | 10-17 | full | · | 24 | F | X | h | – | caught | 0 | 338 (9) |
| 4 | 2026-10-17-1948 | 10-17 | light | loop | 9 |  |  |  |  |  | 0 | 143 (4) |
| 5 | 2026-10-17-1956 | 10-17 | light | loop | 5 |  |  |  |  |  | 0 | 92 (3) |
| 6 | 2026-10-20-0346 | 10-19 | stopped | · | n/a |  |  |  |  |  | 0/12 (1626) | 295 (2) |
| 7 | 2026-10-20-1923 | 10-20 | stopped | · | 2 |  |  |  |  |  | 0 | 653 (3) |
| 8 | 2026-10-20-1938 | 10-20 | full | · | 16 | F | – | O | T | caught | 0 | 100 (4) |
| 9 | 2026-10-20-2344 | 10-20 | full | · | 18 | – | – | D | T | caught | 3/10 (11061) | 310 (9) |
| 10 | 2026-10-21-0006 | 10-20 | full | loop | 5 | – | – | s | – | quiet | 0 | 86 (3) |
| 11 | 2026-10-21-0044 | 10-20 | full | loop | 16 | – | – | s | – | quiet | 0 | 94 (3) |
| 12 | 2026-10-26-0002 | 10-25 | full | · | 24 | – | X | O | – | caught | 0/5 (1172) | 283 (8) |
| 13 | 2026-10-26-0027 | 10-25 | full | loop | 11 | – | – | O | – | caught | 1/0 (57) | 116 (4) |
| 14 | 2026-10-26-0045 | 10-25 | full | loop | 4 | – | – | h | – | quiet | 0 | 94 (3) |
| 15 | 2026-10-26-0139 | 10-25 | full | loop | 3 | – | – | s | – | quiet | 0 | 68 (3) |
| 16 | 2026-10-28-2136 | 10-28 | full | · | 16 | – | W | – | T | caught | 0/5 (1326) | 348 (10) |
| 17 | 2026-10-28-2155 | 10-28 | full | loop | 10 | – | – | h | – | quiet | 4/0 (5248) | 67 (3) |
| 18 | 2026-10-28-2205 | 10-28 | full | loop | 13 | – | – | h | – | quiet | 1/0 (126) | 90 (3) |
| 19 | 2026-10-28-2223 | 10-28 | full | loop | 2 | – | – | D | T | caught | 0 | 93 (3) |
| 20 | 2026-10-28-2302 | 10-28 | full | owner | 3 | – | – | – | – | quiet | 0 | 166 (5) |
| 21 | 2026-10-28-2314 | 10-28 | full | loop | 2 | – | – | – | – | quiet | 0 | 90 (4) |
| 22 | 2026-10-28-2325 | 10-28 | full | owner | 8 | – | – | – | – | quiet | 1/1 (196) | 67 (3) |
| 23 | 2026-10-29-0133 | 10-28 | full | owner | 10 | – | – | – | – | quiet | 0/1 (4) | 324 (7) |
| 24 | 2026-10-29-0217 | 10-28 | full | loop | 11 | – | – | h | – | quiet | 2/0 (825) | 269 (4) |
| 25 | 2026-10-29-0235 | 10-28 | full | loop | 6 | – | – | C X | – | caught | 0 | 118 (4) |
| 26 | 2026-10-29-0240 | 10-28 | full | went on | 7 | – | – | – | – | quiet | 0 | 82 (4) |
| 27 | 2026-10-29-1937 | 10-29 | full | · | 23 | – | – | h | – | quiet | 1/0 (68) | 138 (3) |
| 28 | 2026-10-29-2003 | 10-29 | full | · | 34 | – | W | h | – | caught | 0/1 (13) | 329 (8) |
| 29 | 2026-10-29-2045 | 10-29 | full | loop | 15 | – | – | h | – | quiet | 1/0 (376) | 211 (5) |
| 30 | 2026-10-29-2108 | 10-29 | full | loop | 2 | – | – | – | – | quiet | 0 | 105 (3) |
| 31 | 2026-10-29-2126 | 10-29 | full | loop | 3 | – | – | – | – | quiet | 0 | 105 (4) |
| 32 | 2026-10-29-2212 | 10-29 | full | owner | 11 | – | – | O | – | caught | 0/1 (8) | 67 (2) |
| 33 | 2026-10-29-2223 | 10-29 | full | went on | 4 | – | – | – | – | quiet | 0 | 445 (8) |
| 34 | 2026-10-29-2248 | 10-29 | full | loop | 8 | – | – | h | – | quiet | 3/0 (1732) | 243 (5) |
| 35 | 2026-10-29-2306 | 10-29 | full | owner | 5 | – | – | – | – | quiet | 0 | 186 (6) |
| 36 | 2026-10-30-0035 | 10-29 | full | owner | 18 | – | – | D | T | caught | 1/0 (692) | 203 (7) |
| 37 | 2026-10-30-0100 | 10-29 | full | loop | 12 | – | – | O | – | caught | 1/0 (109) | 172 (4) |
| 38 | 2026-10-30-0116 | 10-29 | full | loop | 19 | – | – | – | – | quiet | 0 | 132 (5) |
| 39 | 2026-10-30-0136 | 10-29 | full | loop | 2 | – | – | – | – | quiet | 0 | 119 (4) |
| 40 | 2026-10-30-0708 | 10-30 | light | owner | 2 |  |  |  |  |  | 0/3 (444) | 75 (2) |
| 41 | 2026-10-30-0730 | 10-30 | light | owner | n/a |  |  |  |  |  | 3/0 (685) | 338 (7) |
| 42 | 2026-10-30-0731 | 10-30 | full | · | 6 | – | Q | h | r | caught | 0/1 (13) | 77 (3) |
| 43 | 2026-10-30-0800 | 10-30 | full | owner | 23 | – | – | – | – | quiet | 0 | 232 (6) |
| 44 | 2026-10-30-0841 | 10-30 | full | loop | 2 | – | – | – | – | quiet | 0 | 83 (3) |
| 45 | 2026-10-30-0848 | 10-30 | full | loop | 2 | – | – | – | – | quiet | 0 | 77 (3) |
| 46 | 2026-10-31-0316 | 10-30 | full | owner | 19 | – | – | h | – | quiet | 2/5 (3339) | 81 (5) |
| 47 | 2026-10-31-2256 | 10-31 | full | owner | 3 | – | – | – | – | quiet | 0 | 90 (3) |
| 48 | 2026-10-31-2325 | 10-31 | light | loop | 4 |  |  |  |  |  | 0 | 75 (3) |
| 49 | 2026-11-01-2056 | 11-01 | full | owner | 4 | – | – | – | – | quiet | 0 | 35 (1) |
| 50 | 2026-11-01-2101 | 11-01 | light | owner | 2 |  |  |  |  |  | 0 | 39 (2) |
| 51 | 2026-11-01-2104 | 11-01 | light | went on | 8 |  |  |  |  |  | 0 | 80 (4) |
| 52 | 2026-11-01-2142 | 11-01 | light | owner | 6 |  |  |  |  |  | 1/2 (1136) | 190 (5) |
| 53 | 2026-11-01-2222 | 11-01 | light | loop | 4 |  |  |  |  |  | 0 | 81 (3) |
| 54 | 2026-11-01-2237 | 11-01 | light | loop | 2 |  |  |  |  |  | 0 | 86 (3) |
| 55 | 2026-11-01-2243 | 11-01 | light | loop | 2 |  |  |  |  |  | 0 | 81 (3) |
| 56 | 2026-11-01-2346 | 11-01 | light | owner | 1 |  |  |  |  |  | 0 | 47 (2) |
| 57 | 2026-11-01-2347 | 11-01 | light | went on | 9 |  |  |  |  |  | 0 | 104 (6) |
| 58 | 2026-11-02-0326 | 11-01 | full | owner | 6 | – | – | C | r | caught | 1/0 (985) | 425 (5) |
| 59 | 2026-11-02-0337 | 11-01 | light | owner | 1 |  |  |  |  |  | 0 | 43 (2) |
| 60 | 2026-11-02-0340 | 11-01 | light | went on | 2 |  |  |  |  |  | 0 | 45 (3) |
| 61 | 2026-11-02-0420 | 11-01 | light | loop | 45 |  |  |  |  |  | 0 | 137 (4) |
| 62 | 2026-11-02-0532 | 11-01 | light | loop | n/a |  |  |  |  |  | 0 | 68 (3) |
| 63 | 2026-11-02-0649 | 11-01 | light | went on | 3 |  |  |  |  |  | 0 | 182 (6) |
| 64 | 2026-11-02-0718 | 11-01 | full | · | 13 | – | – | – | r | refire | 2/0 (594) | 150 (4) |
| 65 | 2026-11-02-0808 | 11-02 | light | loop | 3 |  |  |  |  |  | 0 | 64 (2) |
| 66 | 2026-11-02-1438 | 11-01 | light | owner | 2 |  |  |  |  |  | 0 | 43 (2) |
| 67 | 2026-11-02-1757 | 11-02 | light | owner | 1 |  |  |  |  |  | 0 | 39 (2) |
| 68 | 2026-11-02-1758 | 11-02 | light | went on | 3 |  |  |  |  |  | 0 | 125 (5) |
| 69 | 2026-11-02-1803 | 11-02 | full | · | 13 | – | – | h | r | refire | 1/0 (592) | 166 (5) |
| 70 | 2026-11-02-1833 | 11-02 | light | loop | 4 |  |  |  |  |  | 0 | 55 (4) |
| 71 | 2026-11-02-1846 | 11-02 | light | loop | 2 |  |  |  |  |  | 1/0 (93) | 63 (2) |
| 72 | 2026-11-02-2027 | 11-02 | full | · | 17 | – | X | h | – | caught | 0 | 69 (2) |
| 73 | 2026-11-03-2329 | 11-03 | full | · | 11 | – | – | h | – | quiet | 0/2 (172) | 186 (6) |
| 74 | 2026-11-04-0017 | 11-03 | full | loop | 7 | – | – | h | – | quiet | 1/0 (647) | 102 (3) |
| 75 | 2026-11-04-0031 | 11-03 | full | loop | 1 | – | – | h | – | quiet | 0 | 102 (4) |
| 76 | 2026-11-05-2347 | 11-05 | full | · | 182 | c | – | h | – | caught | 0/1 (21) | 232 (7) |
| 77 | 2026-11-06-0310 | 11-05 | full | loop | 3 | – | – | – | – | quiet | 0 | 86 (5) |
| 78 | 2026-11-06-0317 | 11-05 | full | loop | 9 | – | – | D | T | caught | 1/0 (353) | 95 (3) |
| 79 | 2026-11-06-0400 | 11-05 | full | loop | 1 | – | – | – | – | quiet | 0 | 84 (3) |
| 80 | 2026-11-06-0630 | 11-05 | full | owner | 1 | – | – | – | – | quiet | 0 | 47 (2) |
| 81 | 2026-11-06-0631 | 11-05 | full | · | 8 | – | – | – | – | quiet | 0 | 317 (8) |
| 82 | 2026-11-06-0753 | 11-05 | full | loop | 1 | – | – | h | – | quiet | 3/0 (8378) | 86 (3) |
| 83 | 2026-11-06-0851 | 11-06 | full | owner | 2 | – | – | – | – | quiet | 0 | 78 (3) |
| 84 | 2026-11-06-0956 | 11-06 | full | loop | 6 | – | Q | h | – | caught | 0/1 (160) | 79 (3) |
| 85 | 2026-11-07-0115 | 11-06 | full | owner | 9 | – | X | – | – | caught | 0 | 71 (4) |
| 86 | 2026-11-07-0145 | 11-06 | full | owner | 2 | – | – | – | – | quiet | 0 | 145 (3) |
| 87 | 2026-11-07-0148 | 11-06 | full | · | 14 | – | – | h | r | refire | 0 | 239 (6) |
| 88 | 2026-11-07-0500 | 11-06 | full | owner | 12 | F | – | D | r | caught | 2/1 (6695) | 157 (6) |
| 89 | 2026-11-07-0534 | 11-06 | full | (loop) | 1 | – | – | – | – | quiet | 0 | 56 (5) |
| 90 | 2026-11-07-0603 | 11-06 | full | (loop) | 7 | – | – | – | – | quiet | 1/0 (337) | 102 (4) |
| 91 | 2026-11-07-0620 | 11-06 | full | owner | 1 | – | – | s | – | quiet | 0 | 71 (4) |
| 92 | 2026-11-07-0621 | 11-06 | full | · | 3 | – | – | s | r | refire | 0 | 328 (8) |
| 93 | 2026-11-07-0650 | 11-06 | full | (loop) | 11 | – | – | – | – | quiet | 1/1 (305) | 128 (3) |
| 94 | 2026-11-07-0745 | 11-06 | full | (loop) | 1 | – | – | s | – | quiet | 0 | 105 (3) |
| 95 | 2026-11-07-2324 | 11-07 | full | · | 21 | – | – | D | r | caught | 0/1 (11) | 612 (10) |
| 96 | 2026-11-07-2353 | 11-07 | full | loop | 13 | – | – | h | r | refire | 2/0 (930) | 64 (3) |
| 97 | 2026-11-08-0016 | 11-07 | full | loop | 15 | – | – | – | r | refire | 1/0 (176) | 131 (3) |
| 98 | 2026-11-08-0036 | 11-07 | full | loop | 5 | – | – | h | r | refire | 0 | 109 (3) |
| 99 | 2026-11-08-0600 | 11-07 | full | · | 3 | – | – | – | r | refire | 0 | 34 (1) |
| 100 | 2026-11-10-1902 | 11-10 | full | owner | 12 | – | X Q | D | T | caught | 0 | 390 (9) |

## Appendix B: the replay script

It reads Appendix A from this file. Run it from the repo root:

```sh
python3 - docs/working/research-2026-11-10-cycle-overhead-numbers.md <<'EOF'
import re, sys, datetime as dt
rows = [[c.strip() for c in l.split('|')[1:-1]] for l in open(sys.argv[1]) if re.match(r'\| \d+ \| 2026-', l)]
def t(r):  # the record says 2026-11-02-1438's name is mistyped: UTC was 0647
    return dt.datetime.strptime('2026-11-02-0647' if r[1] == '2026-11-02-1438' else r[1], '%Y-%m-%d-%H%M')
rows.sort(key=t)
def sim(rule):
    full, moved, days, last = [], False, set(), None
    for r in rows:
        moved = moved or r[11] != '0'
        if r[3] == 'stopped': continue
        first = r[2] not in days; days.add(r[2])
        if last is None or rule((t(r) - t(last)).total_seconds() / 3600, first, moved):
            full.append(r); last = r; moved = False
    waits = [(r[1], next((round((t(f) - t(r)).total_seconds() / 3600, 1) for f in full if t(f) > t(r)), None))
             for r in rows if r[10] == 'caught' and r not in full]
    return len(full), waits
for name, rule in [('every 24 h', lambda h, f, m: h >= 24), ('first of the local day', lambda h, f, m: f),
                   ('main moved', lambda h, f, m: m), ('main moved, or first of the local day', lambda h, f, m: m or f)]:
    n, w = sim(rule); print(name, '| full', n, 'of 96 | catches delayed', len(w), w)
EOF
```
