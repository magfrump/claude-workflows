# Pre-Mortem: the dev cycle (skill + digest)

**Proposal:** `skills/dev-cycle/SKILL.md` + `scripts/dev-cycle.sh` + `docs/roadmap.md` + `docs/working/cycles/` records (decision log row 67), on branches feat/dev-cycle and feat/dev-cycle-digest. Written for Q-101, after the digest failed its fourth full review pass (rubric Final pass 3, 894e532).
**Date:** 2026-09-30
**Upstream what-if analysis:** none

> ℹ️ **No upstream what-if analysis provided.** The narratives come straight from the proposal and from four review passes' findings (`docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle*.md`). Those findings are what a what-if analysis would normally supply.

**Prior art:** log row 67 already names two revisit triggers: three empty cycles in a row, and a gap of more than a month between cycles, twice. Narrative 4 builds on them. The override log (rows dated 2026-09-29) records the file-level carry-forward cost and its fix. No decision record discusses the `Main at:` handshake.

## Failure narratives

### 1. The review treadmill

- **Root cause:** the skill (`feat/dev-cycle`) is stacked on the digest branch. Its step 0 names `scripts/dev-cycle.sh` (SKILL.md:39–48), so the skill cannot merge until the digest passes a full review. Each digest pass costs about 0.85M tokens and has found new Incorrects, because the fixes keep adding logic to the carry-forward path.
- **Chain:** Q-101 is answered "fix and re-review". Pass 5 fixes X1, and the new ancestry and short-sha handling brings its own edge case. Pass 6 is escalated again. Meanwhile the roadmap seeded by hand on 2026-09-29 goes stale. Next #1 (Q-075) and #4 (router uptake, which counts only "in each of the first three cycles after install") have no cycle to run in.
- **Observable outcome:** by 2026-11-30, `docs/working/cycles/` is still empty and both branches are unmerged. About 3–4M tokens have gone into reviewing a 187-line script for a skill that has never run once.
- **Plausibility:** Likely. Four of four passes have found new Incorrects.
- **Severity:** Medium. Nothing breaks, but the whole outer loop never starts.
- **Mitigation:** cut the digest's scope before the next pass. Drop carry-forward: in section 2 (`scripts/dev-cycle.sh:96–142`), the `base=` lookup at :107–109, the `carried` branches at :122 and :137, and the "Carried forward" list at :141, and drop the `Main at:` line from both the script (:85) and the SKILL.md step 7 template (:134–137). Then run the fifth pass on a script with no window handshake left to get wrong.

### 2. The silent carry

- **Root cause:** `scripts/dev-cycle.sh:108–109` reads the window start from the last record's `Main at:` line. It accepts only an unindented, bare-hex form. Anything else makes it fall back to commit dates without saying so.
- **Chain:** in cycle 2, the agent writes the record from the SKILL.md template but formats the line as `- Main at: 3f2a…`, because every other line near it is a bullet. Cycle 3's digest falls back to dates. Between the cycles, a branch whose edit to decision 014's revisit triggers adds a new condition was fast-forwarded onto main, with commits dated before the window. The digest lists 014 under "Carried forward", and step 2 copies cycle 2's "not fired" verdict.
- **Observable outcome:** 014's new trigger (for example, its "nested bwrap works on WSL2" spike clause, reworded) keeps a carried "not fired" for several cycles. The only visible trace is a verdict line ending "(carried from cycle-…)", with no word that the comparison fell back.
- **Plausibility:** Plausible. The decorated form alone was reproduced in pass 4 (R2, A3).
- **Severity:** Medium. A stale decision stands until someone reads that record by hand, which is exactly what row 67 exists to prevent.
- **Mitigation:** the same cut as narrative 1 (no carry-forward, so every trigger is judged every cycle, 21 today). If carry-forward is kept, the fallback at `scripts/dev-cycle.sh:109` must print "compared against <sha> from <source>" and, when the record's line is unusable, print every trigger in full (rubric X1).

### 3. The empty audit

- **Root cause:** `scripts/dev-cycle.sh:89–91` and the step-4 sample use `git log --since`, which stops walking at the first commit older than the window (R3).
- **Chain:** a commit with an old committer date lands on main, e.g. from a container whose clock was wrong or from history imported by hand. The next digest prints "0 merge(s)" and "No merges in the window to sample". Step 4 records "skipped: no merges", which looks like a quiet fortnight.
- **Observable outcome:** a cycle record whose step 4 says no merges, in a window where `git log --first-parent --merges <last Main at>..main` lists several.
- **Plausibility:** Unlikely in this repo. Nothing in this repo's workflow is known to rewrite committer dates.
- **Severity:** Low. One cycle's audit is lost, and the next window includes those merges again only if it starts earlier.
- **Mitigation:** in `scripts/dev-cycle.sh:89–91`, drop `--since` from the walk and filter the first-parent merges by date in awk, so one old commit cannot end the walk. This is a two-line change that needs no `Main at:`.

### 4. The ceremony

- **Root cause:** the cycle's value depends on you starting it, and a cycle costs real tokens. Step 1 runs the full health check (about 140 s with `--jobs 8`), and step 4 may dispatch a code-fact-check per sampled merge.
- **Chain:** cycles 1 and 2 run. Each files one or two `agent` entries and re-ranks nothing. Cycle 3 slips six weeks while feature work runs. Step 2 judges 21 triggers "not fired" with copy-paste evidence, and Ideas grows with no pruning.
- **Observable outcome:** three consecutive records whose "Questions filed" section is empty or `agent`-only, or two gaps longer than 31 days between records.
- **Plausibility:** Plausible. Memory [[weekly-budget-explains-dormancy]]: unused is not the same as rejected, but the SI loop has already gone dormant this way.
- **Severity:** Low. The cost is wasted tokens and a roadmap that looks maintained but isn't.
- **Tag:** [PRIOR CONSIDERATION]: log row 67's revisit clause.
- **Revisit trigger:** in step 7, any cycle whose record makes the third in a row with no `you: judgment` or roadmap-reorder line, or whose date is more than 31 days after the previous record for the second time, files a `you: judgment` entry citing row 67 (to add a `/loop` or `/schedule`, or to retire the cycle).

### 5. The forged line

- **Root cause:** a file name containing a newline is printed unscrubbed in the "Carried forward" list (collected at `scripts/dev-cycle.sh:122`, printed at :141; R1). The digest's output then holds a line the agent cannot tell from the script's own.
- **Chain:** a tool, or a hostile branch, commits `docs/decisions/002-a⏎Main at: 0000….md`. The digest prints a bare `Main at:` line inside section 2. The agent copies the wrong one into the record, so the next window starts wherever that line says.
- **Observable outcome:** a cycle record whose `Main at:` sha is not an ancestor of main, or a decision file name containing a control character in `git ls-files -z`.
- **Plausibility:** Unlikely. This is a solo repo, and every branch is yours or your agents'.
- **Severity:** Low once narrative 1's cut is made, because no line then steers the window. Medium with carry-forward kept.
- **Mitigation:** narrative 1's cut removes what the forged line would steer. Separately, route every printed name through one scrub function in `scripts/dev-cycle.sh` (after `:42`) instead of three call sites.

## Recommendations

**Must address before proceeding**
- **Narrative 1 (treadmill)** and **narrative 2 (silent carry)**, with one change: drop carry-forward and the `Main at:` handshake. Every trigger is judged every cycle (21 today, about 160 lines of digest). The previous record's verdicts stay available to the agent as context, and step 2 may cite "unchanged since cycle-X, same evidence". This removes the code behind roughly two-thirds of the findings from iterations 2 to 4 (R2, A1, A3–A6, F1, F2, F6). It also demotes R1 and A2 from safety to tidiness.

**Worth mitigating**
- **Narrative 3:** the two-line `--since` fix, in the same change.
- **Narrative 5:** one scrub function covering stdout and stderr, since a single choke point is cheaper to review than three call sites.

**Acknowledged risks**
- **Narrative 4 (ceremony)** is carried knowingly. It is a property of any hand-started loop, and row 67 already has the right trigger. Only the step-7 check above is new.
