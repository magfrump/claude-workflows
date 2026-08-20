# Pre-Mortem: merging `feat/crb-direction1-harness` and running the sweep

**Proposal:** `feat/crb-direction1-harness` at HEAD `59733d8` — merge the CRB direction-1 harness and run it (5-PR pilot, then possibly all 50) against the WithMartian Code Review Bench.
**Date:** 2026-08-18
**Upstream what-if analysis:** none

> ℹ️ **No upstream what-if analysis provided.** Failure narratives are generated directly
> from the proposal. For higher-quality narratives, run `what-if-analysis` first and
> provide its output — this skill is sharpest when seeded with already-mapped assumptions
> and coupling points.

> **This supersedes `docs/reviews/pre-mortem.md` for the current tree.** That document
> analyzed `529ecd2`; three fix commits have landed since (`ed68ced`, `a04ef57`, `59733d8`)
> and **four of its five narratives are now closed in code** — the resume predicate,
> the sweep cap, the containment re-assertion, the section-match anchoring, and the generated
> `judge.sh` all shipped. It is kept for the reasoning trail, not as a live risk register.
> The narratives below are new: three of the five are failure modes **introduced by those
> fixes**, which is the expected shape of a second pre-mortem after a heavy review-fix loop.

**Prior art scanned:** `docs/decisions/` (29 records) and `docs/working/` for *containment,
voided, canary, egress, skip-permissions, sweep budget, run-meta*. Two matches carry directly
and are tagged inline: decision 015 (process isolation — the egress-firewall and
no-host-credentials premises) and decision 022 (payload registration). The prior pre-mortem's
"acknowledged risks" list is not re-litigated here.

---

## Narrative 1: The sweep that voided itself

**Root cause:** `runs/review-arms/crb-pipeline/run-host.sh:98` copies this repo's `CLAUDE.md`
into the container's `~/.claude` as part of the payload — correctly, since the routing table is
under test. That file carries the commit triggers at `CLAUDE.md:249-255` ("commit whenever … (d)
you finished a coherent file group … **When in doubt, commit**") and the `/away` default at
`:214`, which lists *creating git commits* as an autonomous action needing no approval. The
reviewing agent runs headless, which is `/away` by that document's own rule.

**Chain of consequences:** The agent reviews `keycloak-PR36880`, writes its rubric into
`docs/reviews/` inside the reviewed clone, and — following the instructions it was given —
commits it on the `review` branch. The run succeeds: `result.json` is clean, `review.md` is a
real review, and the harvest at `:257-288` collects the rubric before anything else happens. Then
the reset at `:291-292` runs `git checkout -- .` and `git clean -qfdx` — neither of which undoes a
commit. The post-run containment check at `:297` calls `crb-materialize.py --verify`, whose stray
test at `crb-materialize.py:183-186` compares `git rev-list --all` against the **manifest's**
recorded head (`:294-300`), so the agent's own commit is a stray commit reachable outside the
reviewed ancestry. The check fails. Per `:297-310` the cell is voided: `CONTAINMENT_FAILED` is
touched and `result.json` is rewritten with `is_error: true`, `subtype: "containment_failed"`.
The injector then skips it at `crb-pipeline-to-benchmark.py:241-244`. Worse, the clone stays
broken: on the next invocation the **pre-run** check at `run-host.sh:206-208` fails too, so that
slug is `skipped_bad` forever until it is re-materialized. And because the trigger is a document
mounted identically into every cell, this is systematic, not per-cell luck — the cells most likely
to trip it are the ones where the pipeline did the most work.

**Observable outcome:** `run-meta.json` reports a healthy `total_cost_usd` (the reviews were paid
for and did run) alongside a `voided_cells` list containing most or all of the sweep, and the
injector prints `!! <slug>: cell voided by a post-run containment failure — skipped` for each. The
harvested rubrics sit in `artifacts/` looking perfectly good. Because at least one cell ran, the
exit-code guard at `:423-426` does not fire, so the script exits 0. The operator sees a sweep that
cost $50–200 and produced zero injectable cells, with the failure attributed to "containment" —
the one label that reads as *the arm is compromised* rather than *the arm's own instructions did
this*.

**Plausibility:** Plausible (10–50%) — it needs the agent to commit rather than leave the rubric
in the working tree. Nothing in `skills/code-review/SKILL.md` tells it to commit, but the global
`CLAUDE.md` in the same payload tells it to, twice, in the mode it is running in.
**Severity:** High — the whole pilot's spend, and the recovery (re-materialize every affected
slug, ~127–195 MB each) has to happen before a single number can be produced.

**Mitigation:** Distinguish *the agent moved a ref* from *the clone reached outside its ancestry*
before the void fires. Two edits: (a) in `run-host.sh:291-292`, replace `git checkout -- .` with
`git reset --hard "$manifest_head"` so the reset restores refs and index, not just the working
tree, before the post-run check runs; (b) in the post-run block at `:297-310`, only void the cell
when `crb-materialize.py --verify` fails for the **remote** guard
(`crb-materialize.py:187-190`) or when the stray commits are not descendants of the manifest head
— a commit that is a pure descendant of the reviewed head cannot contain the answer key, and
should reset rather than void.

---

## Narrative 2: The tracked file that carried into the retry

**Root cause:** `run-host.sh:291` resets the reviewed clone with `git checkout -- .`, which
restores the working tree **from the index**. `git clean -qfdx` at `:292` removes untracked files
(the `-x` was added in `ed68ced` and does its job), but nothing undoes a `git add`. Review item
A16 was closed on the `clean -x` half; the index half is still open, and `git reset` appears
nowhere in the file.

**Chain of consequences:** During the review of `cal_com-PR11059` the agent stages a modified
tracked file — running `git add -A` to see a clean `git status`, or staging an edit it made while
testing an understanding of the diff. The cell finishes. The reset leaves the staged change in
place; the containment check passes, because `verify_containment` inspects commits and remotes
(`crb-materialize.py:183-190`), not the index or working tree, so nothing flags it. Then the new
retry logic — added in the same fix pass, `run-host.sh:184-198`, `MAX_ATTEMPTS=2` — makes a second
run of that same cell *routine* rather than exceptional: any incomplete result now automatically
re-runs. Attempt 2 reviews a repository whose diff against `main` no longer matches the PR under
test. Its findings are scored against goldens derived from the real PR.

**Observable outcome:** One cell whose candidate comments reference code that appears in no
golden, and whose `total_candidates` is out of line with its neighbours, with no artifact anywhere
recording that the tree differed. Undetectable after the fact: the reset on the *second* attempt
also leaves the index dirty, so inspecting the clone afterwards shows the contaminated state
without showing when it arrived. In aggregate it reads as "the pipeline was noisy on cal.com."

**Plausibility:** Plausible (10–50%) — requires a staged tracked file, which is a normal thing for
an agent to do, on a cell that retries, which the new logic makes common.
**Severity:** Medium — it corrupts one cell's row rather than the arm, and is recoverable by
re-materializing and re-running, but it is silent, so nobody will know to do that.

**Mitigation:** Same one-line change as Narrative 1(a), and it is the reason to prefer it over a
narrower fix: replace `git checkout -- .` at `run-host.sh:291` with
`git reset --hard <manifest head>`, which restores refs, index, and tracked files in one
operation. Keep `git clean -qfdx` at `:292` for untracked and gitignored leftovers. Add the
resulting `git status --porcelain` output (expected: empty) to the per-cell record written at
`:312-322` so a non-empty tree after reset is visible in the run log rather than inferred later.

---

## Narrative 3: The recall number computed only on the PRs that worked

**Root cause:** `scripts/crb-subset-leaderboard.py:62-63` defines the comparison subset as the
PRs where **our tool has a judged row** (`u for u, tools in evals.items() if args.tool in tools`).
Cells that the injector skipped — voided by containment (`crb-pipeline-to-benchmark.py:241-244`)
or producing no parseable findings (`:246-248`) — never reach `benchmark_data.json`, are never
judged, and therefore silently define themselves out of the denominator.

**Chain of consequences:** The pilot runs five cells. `sentry-greptile-PR5` (106 files, +2312/-981,
the largest by an order of magnitude) exhausts its $25 instance budget and produces a truncated
review whose rubric has no parseable findings table; `keycloak-PR36880` is voided by Narrative 1.
Both are skipped with a stderr line each, in the middle of an injector run that prints a normal
per-cell table for the other three. The leaderboard then ranks all 49 tools over a **3-PR** subset
and prints `Subset: 3 PR(s), N goldens` — a count that is honest but reads as a scoping choice
rather than as attrition. The two missing PRs are precisely the ones where the pipeline struggled,
so the surviving subset is selected *for* pipeline success. The results doc quotes recall and F1
from that table. The `GOLDEN-DENOMINATOR SKEW` warning at `:103-111` fires or not on its own
unrelated logic, giving the impression that subset caveats are being handled mechanically.

**Observable outcome:** A results doc reporting a headline recall over "the pilot" whose subset is
smaller than the pilot, with no line anywhere connecting `run-meta.json`'s `voided_cells` /
attempted-cell count to the leaderboard's `PRs` column. Recomputation by anyone who re-runs the
sweep and gets different cells to survive produces a materially different number, and the
difference is not noise — it is which failures got excluded.

**Plausibility:** Likely (>50%) — it does not require a bug, only that *any* cell fails to
produce injectable output, which the harness's own design treats as an ordinary outcome and which
Narratives 1, 4, and 5 each independently cause.
**Severity:** High — this is the arm's only product, and the bias runs in our favour, which is
the direction least likely to prompt a second look.

**Mitigation:** Make attrition impossible to omit. In `scripts/crb-subset-leaderboard.py`, read
`runs/review-arms/crb-pipeline/run-meta.json` (or take an explicit `--attempted N`) and print a
line above the table whenever `len(urls)` is less than the number of cells attempted, naming the
missing slugs and their reason — `voided_containment` from run-meta, "no reviewable output"
otherwise — to stderr in the same style as the existing `GOLDEN-DENOMINATOR SKEW` warning at
`:105-111`, and include it in the `--markdown` output so it survives into any pasted table.

---

## Narrative 4: The halt that erased its own provenance

**Root cause:** The sweep-spend gate at `run-host.sh:342-367` exits the script with status 2 when
the accumulated ledger crosses `SWEEP_BUDGET`. That `exit 2` is inside the `for` loop, so the
`run-meta.json` writer at `:371-417` and the cell summary at `:418` never run. `SWEEP_BUDGET`
defaults to `250.00` (`:68`) while `docs/working/crb-direction1-setup.md`'s cost model puts a
50-PR sweep at **$500–2000** — so on a full sweep, tripping the ceiling is the *designed* path,
not the exception.

**Chain of consequences:** The operator launches `--all` overnight after a satisfactory pilot,
leaving `SWEEP_BUDGET` at its default because the pilot never came close to it. Around cell 12–20
the ledger crosses $250 and the script exits 2 mid-sweep. No `run-meta.json` is written, so
there is no file recording which payload commit ran, which cells completed, what was retried, or
what was spent — the provenance artifact `docs/working/review-canon.md` §3 expects and that a
results doc quotes. The operator re-runs to continue. Completed cells `continue` at `:181-183`
*before* the gate is reached, so the gate is only evaluated after a cell that actually ran: the
resume pays for exactly one more cell, trips the ceiling again, and exits 2 again — having also
paid for a fresh preflight call each time. Each invocation buys one cell until someone reads the
message and raises the variable.

**Observable outcome:** `SWEEP BUDGET EXCEEDED — stopping.` on stderr, no `run-meta.json` on disk,
and a `crb-pipeline/` directory of ~15 finished cells whose total spend can only be reconstructed
by summing `attempts.jsonl` across cells by hand. If the operator raises `SWEEP_BUDGET` and
completes the sweep later, the final `run-meta.json` is correct — so the damage is confined to the
window where it is most useful, which is while deciding whether to keep going.

**Plausibility:** Likely (>50%) for a 50-PR sweep at the default ceiling; Unlikely for the pilot,
whose $50–200 estimate sits below it (deliberately, per the comment at `:65-67`).
**Severity:** Medium — money is not lost and the gate is doing its job; what is lost is the
provenance file at the moment a spend decision is being made.

**Mitigation:** Move the provenance write out of the loop's success path. Extract `:371-417` into a
shell function `write_run_meta` and call it (a) from the gate's failure branch at `:342` before
`exit 2`, and (b) from a `trap write_run_meta EXIT` alongside the existing payload-cleanup trap at
`:97`, so any exit — budget halt, `Ctrl-C`, docker failure — still leaves a `run-meta.json`
describing what was spent.

---

## Narrative 5: The review that said "logged in"

**Root cause:** The completion predicate at `run-host.sh:168-183` rejects a result whose body
contains any string in `NON_REVIEW` (`:174-175`), which includes the bare substrings `"log in"`
and `"logged in"`, tested against the **entire** review body (`low = r.lower()`, `:172`). Those
strings are there to catch Claude Code's auth and quota stubs, which are ~50 characters long; the
`len(r) >= 200` clause at `:178` already separates those from real reviews, but the substring test
is applied unconditionally on top of it.

**Chain of consequences:** The predicate was validated against the 32 `result.json` files already
in this repo, and it is clean on all of them — I checked; zero of the 32 contain either string.
But those 32 are reviews of *this* repo's `mfc-*` canon instances, and the corpus contains no
auth-domain code at all. The pilot's instances do: `keycloak-PR36880` is "Add Client resource type
and scopes to authorization schema" on an identity server, and `cal_com-PR11059` is "OAuth
credential sync and app integration enhancements". A multi-kilobyte review of an OAuth credential
flow that never once writes "once the user is logged in" is possible but not the way to bet.
When it does, the cell is judged incomplete on the operator's next invocation; the retry logic at
`:184-198` re-runs it — paying $10–40 again for a review that already succeeded — and after
`MAX_ATTEMPTS=2` marks it `skipped_bad`. The good `review.md` from attempt 1 has by then been
overwritten by attempt 2's, which is rejected on the same substring for the same reason.

**Observable outcome:** A cell that costs double and then reports `=== <slug> — 2 failed
attempt(s), at MAX_ATTEMPTS — skipping`, with a perfectly readable multi-KB review sitting in
`review.md` next to the message saying it failed. Downstream it compounds with Narrative 3: the
PR drops out of the judged subset, and the PRs most likely to drop are the auth-heavy ones —
a systematic content bias in which parts of the benchmark our number comes from.

**Plausibility:** Plausible (10–50%) — needs one auth-domain phrase in one review body, on a
sweep where two of five pilot instances are auth-domain.
**Severity:** Medium — double spend on the affected cells and silent subset attrition;
no incorrect number is produced directly, only a biased denominator via Narrative 3.

**Mitigation:** Scope the substring test to the short-body case it was written for. At
`run-host.sh:176-179`, apply the `NON_REVIEW` check only when `len(r) < 1000` — the stubs it
targets are 51–56 characters (measured on `e7-fable-3x/mfc-postfix/rep2` and `rep3`), and no real
review in the 32-file corpus is under 1000 — leaving `is_error`, `subtype`, and the length floor
as the predicate for anything longer. Add the two `mfc-postfix` stub bodies and one real
multi-KB review body as fixtures to `test/crb-injector-sections.bats` (or a sibling
`test/crb-completion-predicate.bats`) so the boundary is pinned.

---

## Recommendations

### Must address before proceeding

1. **Narrative 1 + Narrative 2 — the reset does not restore refs or the index** (Plausible / High
   and Plausible / Medium). One change closes both: `git reset --hard <manifest head>` in place of
   `git checkout -- .` at `run-host.sh:291`, plus the descendant test before the post-run void
   fires. As written, the harness ships a `CLAUDE.md` that instructs the agent to commit and a
   containment check that treats committing as compromise — and the interaction destroys the clone
   permanently, not just the cell. This is the cheapest fix on the list and the one most likely to
   consume the entire pilot budget for nothing.
2. **Narrative 3 — attrition is invisible in the leaderboard subset** (Likely / High). Every other
   narrative here funnels into this one, and it is the failure this project cares most about: a
   number in `docs/working/` that later sessions read as fact. Print the missing-cell line before
   any results doc is written.

### Worth mitigating

3. **Narrative 4 — `exit 2` skips the provenance write** (Likely-on-`--all` / Medium). A `trap` and
   a function extraction. Do it before the 50-PR sweep, not before the pilot.
4. **Narrative 5 — the `NON_REVIEW` substrings on long bodies** (Plausible / Medium). A one-line
   length guard plus fixtures. Worth doing in the same commit as items 1–2 since all three are in
   the same loop.
   *Revisit trigger:* if any pilot cell reports `at MAX_ATTEMPTS — skipping` while its `review.md`
   is larger than 1 KB, this narrative is happening — check the body for `log in` / `logged in`
   before assuming the run failed.

### Acknowledged risks

- **R3, the live credential in the review container** — `[PRIOR CONSIDERATION]`, and the strongest
  prior art in the repo argues against the current posture: decision 015 records that the isolation
  boundary's trust story rests on an *inherited default-deny egress firewall* (`:39-42`) and that
  "the record forbids real host credentials inside the boundary" (`:84`). `run-host.sh:218-231`
  runs plain `node:22` — not the `cc-isolated` image — with `-e ANTHROPIC_API_KEY`,
  `--dangerously-skip-permissions`, and no `--network` restriction, over third-party repository
  content whose repo-local instructions load as they would for any real user (`:34-36`). The
  rubric already carries this as the one red not closed and correctly calls it a host-and-billing
  decision. Carried knowingly: the 50 forks are a public benchmark org rather than an adversary,
  which is why this is not a narrative above. If it is carried into the sweep, carry it
  *explicitly* — a dedicated low-limit key, rotated after, is a ten-minute action that removes the
  only catastrophic-severity item on the board.
- **A18, no first-instance canary** — carried deliberately per the rubric, on the reasoning that
  the setup doc's human instruction (run `keycloak-PR36880` alone, read `review.md`) covers it.
  Note that Narrative 1 makes that first instance more valuable than the rubric assumed: a single
  pilot cell would surface the void-on-commit interaction for $10–40 rather than for the price of
  the sweep. The instruction is doing more work than "canary" suggests — follow it.
- **The review-fix loop has not reached two consecutive clean passes** — stated at the top of
  `code-review-rubric-2026-08-18-feat-crb-direction1-harness.md`. Three of the five narratives
  above are defects in pass-2/pass-3 fix code, which is the empirical case for that rule rather
  than an argument against merging. Merging is fine; the items in "must address" are the second
  clean pass.
