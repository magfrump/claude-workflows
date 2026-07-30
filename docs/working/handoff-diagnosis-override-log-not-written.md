# Handoff diagnosis — `docs/reviews/override-log.md` is not accumulating rows

**Date:** 2026-07-29
**Repo:** `magfrump/claude-workflows` (`/workspace`)
**Status:** Diagnosis only — no files modified other than this one.
**Relevant paths:** `docs/reviews/override-log.md`, `skills/code-review/SKILL.md`, `workflows/pr-prep.md`, `workflows/review-fix-loop.md`, `scripts/self-improvement.sh`, `scripts/lib/si-functions.sh`

---

Reproduction: `rg -c '^\| 20[0-9]{2}-[0-9]{2}-[0-9]{2} \|' docs/reviews/override-log.md` → `1`, while `git log --since=2026-05-12 --format='%h|%s' | rg -i "round-[0-9]|code.review finding|review finding"` → `8 distinct post-log review runs` and `git log --since=2026-05-12 --format=%b | rg -ic "refuted finding|accepted risk|won'?t.?fix|correctly not actioned|declined|out of scope|false positive|false rejection"` → `32`. One logged override against 32 override-shaped verdicts recorded elsewhere, all after the log was created on 2026-05-12 (`ffee7d8`).

---

## Framing correction (do not skip)

Two premises in the original brief are factually wrong and reshape the whole diagnosis:

1. **The log did not exist for most of the "~10 code-review runs."** `docs/reviews/override-log.md` was added 2026-05-12 in `ffee7d8`. Nine of the eleven `code-review-rubric.md` commits (2026-03-23 → 2026-05-14) predate it. Those runs *could not* have written to it.
2. **Only one of the three "capture" sites is a write path.** `workflows/pr-prep.md:169` (step 3b) and `workflows/review-fix-loop.md:110–158` are **read/prefilter** paths — they consume `Won't-Fix` rows to suppress re-fires. The only write instruction in the repo is `skills/code-review/SKILL.md:800–811` ("Capturing new overrides"). review-fix-loop:139 mentions a write, but only for the *un-waiving* escape hatch (superseding an existing row), never for the initial waiver. So the protocol is specified ~40 lines of read enforcement to ~10 lines of write instruction, and the write instruction lives in exactly one file.

3. **A third premise, offered mid-investigation by the coordinator, is also wrong** — see **H7** below. The claim was that the eligible population post-log is *one review run*, giving a 1/1 capture rate. It is at minimum **nine** runs; the appearance of one is an artifact of counting `docs/reviews/code-review-rubric.md` commits, and the July runs stopped persisting a rubric there.

The correct restatement of the failure is: **since the log was created, ≥9 code-review runs produced ≥32 override-shaped verdicts across ~50 commits, and exactly 1 became a row — written manually, in a dedicated commit, by the human, one commit after the review.**

---

## Hypothesis log

**H1: Trigger never fires — humans just fixed everything the pipeline flagged, so an empty log is correct behavior.**
· tested: grepped all commit bodies since 2026-05-12 for waiver language; read full bodies of `31e2d3a`, `08563f1`, `a249cfe`, `9adc642`.
· result: **refuted**
· learned: overrides happen constantly — `31e2d3a` ends "Refuted findings (shutil import-blocked, file-delivery intended, net-test-name) **correctly not actioned**"; `08563f1` ends "Refuted findings (confine-tests.sh duplication, removed file-output) correctly not actioned"; `a249cfe` records "documented as an accepted risk in android.txt … A real fix needs an SNI-filtering proxy — **out of scope**". These are textbook Must-Fix/Consider → Won't-Fix calls.

**H2: Capture is specified in the wrong actor's context — the writing actor is out of session, or no longer holds the rubric, when the verdict is uttered.**
· tested: traced each of the three `Capturing new overrides` paths against the actual sequence of the 2026-06-23 run (`8ea4dab` → `9e64bb1`) and the July rounds; checked which document is loaded at each moment.
· result: **confirmed**
· learned: Path 1 ("inside the same skill run") is structurally near-impossible — the `code-review` skill's job ends when it publishes the rubric; the human's verdict lands during the *fix* pass in pr-prep/review-fix-loop, by which time `SKILL.md` (and its capture format) is no longer the operative document, and the two documents that *are* operative specify only reads. Path 2 is mis-scoped to loop termination with waived findings, but pr-prep's own tier table waives findings mid-loop ("Must Address: fix **or explicitly acknowledge**"; "Consider: fix if cheap, **otherwise note for later**") with no capture instruction attached. Path 3 (manual) is the only one that has ever produced a row, and only because the human spent a whole separate commit on it.

**H3: Read and write are asymmetrically enforced.**
· tested: counted enforcement mechanisms on each side; `rg -n "override" test/ hooks/`.
· result: **confirmed**
· learned: the read side has a numbered Mandatory Execution Rule (`SKILL.md:74`), a dedicated pipeline step (3.5), a required negative sentinel ("No prior overrides matched this diff."), two required deliverable sections, a rubric column, and a stage-3 self-check. The write side has one prose paragraph with no MUST, no sentinel, no self-check, and no deliverable slot. **Zero references to `override-log` exist in `test/` or `hooks/`** — the repo's two mechanical enforcement surfaces — so neither side is machine-checked, but only the read side is even prose-checked.

**H4: Verdict changes are being recorded somewhere else instead.**
· tested: grepped rubric `Author note`/`Status` columns across all 11 historical rubrics; grepped commit bodies; read pr-prep's exit paths.
· result: **confirmed**
· learned: there are at least four competing sinks, three of them *explicitly specified by the same workflows*. (a) The rubric's own `Author note` cell — `f58db84` row A4 reads "🟡 Open … Freshness metadata adds no value for ephemeral artifacts … **No change needed.**", a full override captured in a file that is then overwritten. (b) The autonomous-commit `Notes:` field mandated by `CLAUDE.md` § Autonomous Commit Format — where all 32 July verdicts landed. (c) `pr-prep.md:199` — "document them in the PR description's **Areas of uncertainty** section". (d) `pr-prep.md:189` — "log a `follow-up issue filed: <id/title>` line in the review artifact". The data exists; it is being routed to sinks that are closer to hand and, in the case of (b), *required by a higher-precedence document*.

**H5: The rubric is overwritten each run, destroying the prior verdict.**
· tested: `git log -- docs/reviews/code-review-rubric.md` (undated filename, overwritten in place); `CLAUDE.md` § Review Artifacts ("re-runs overwrite prior artifacts"); rubric row A4 in `f58db84` flags this exact behavior.
· result: **inconclusive — contributing factor, not the cause**
· learned: overwriting destroys override *evidence* recorded in `Author note` cells (sink (a) above), which is why H4's data is invisible without `git show`. But the override log is explicitly exempted from overwrite (`SKILL.md:790`), so this cannot explain the log's emptiness; it explains why the loss went unnoticed.

**H6 (new, added during investigation): The dominant review path since 2026-07-22 discards the rubric entirely.**
· tested: read Gate 1h in `scripts/self-improvement.sh:1257–1282` and `scripts/lib/si-functions.sh:545–570`.
· result: **confirmed**
· learned: the self-improvement loop now runs `code-review` headless on every task branch, but asks only for a `CODE_REVIEW_RED: <n>` sentinel and keeps a single integer (`record_gate_detail … {red_findings: $red}`). No rubric artifact is written, amber/green findings are discarded, unparseable output "skips rather than auto-rejecting", and there is no human in the loop to override anything. The repo's highest-volume review path is structurally incapable of emitting an override row.

**H7 (coordinator-supplied): the eligible population post-log is one review run, so the capture rate is 1/1 and the mechanism "has had one opportunity and took it."**
· tested: did not take it on trust. Re-derived the run count from commit *subjects and bodies* rather than from `docs/reviews/code-review-rubric.md` commits: `git log --since=2026-05-12 | rg -i "round-[0-9]|code.review finding"`; then read `62beca1`, `b7e4595`, `503ebc9`, `0c02887`, `74d626e`, `31e2d3a`, `08563f1`, `45bea51` in full.
· result: **refuted** (the underlying *timeline* fact is confirmed and I had independently established it; the *inference* from it does not hold)
· learned: the coordinator's dedupe of 11 rubric commits → 7 runs, 6 of them pre-log, is correct as far as it goes, and the 2026-05-12 creation date is right. But rubric-file commits stopped being a proxy for review runs. July 2026 contains **seven consecutive numbered review rounds on one branch** (`62beca1` "address 7 code-review findings" → `b7e4595` round-2 → `503ebc9` round-3 → `0c02887` round-4 → `74d626e` round-5 → `31e2d3a` round-6 → `08563f1` round-7), plus a review-fix pass in `45bea51`, none of which wrote to `docs/reviews/`. So the eligible population is **≥9**, the observed capture rate is **≤1/9**, and the "one opportunity, took it" frame is unsupported.
· learned (2): `45bea51` is the single most damning artifact in the repo for this diagnosis — its commit body contains a literal section headed **"Consciously not addressed (see review triage)"** enumerating three waived findings ("intentional per user directive", "pre-existing", "accepted; no stable sandbox-safe location exists"). That is a formatted override table in everything but destination. It is a *post-log*, *review-fix-loop* override set — exactly the population the coordinator's frame says does not exist — and it went to the commit body.
· learned (3): the coordinator's follow-up question "why has code-review run only once in ~10 weeks?" dissolves — it ran ~9 times. The real usage change worth escalating is that **rubric persistence** stopped (see H6: Gate 1h keeps an integer and discards the rubric), which is what made the runs invisible to a `docs/reviews/`-based count.

**H8: the single existing row was agent-written in-run, and conforms to the specified format.**
· tested: `git show --stat 9e64bb1` + its full commit body; compared the row's cells against the six required columns in `SKILL.md:789–796`.
· result: **partially confirmed** — the row conforms; the authorship hypothesis is refuted.
· learned: the row is well-formed (all six columns populated, `PR ref` as branch + `#35`, location-bearing `Finding` cell, ~30-word `Reason`). But it was **not** written in-run: `8ea4dab` saved the review artifacts, and `9e64bb1` — a *separate, later, human-authored commit* whose body opens "Per author decision:" and lists "override-log.md: first entry" as a deliberate bullet — added the row. This is capture path 3 (manual by the author), not path 1 or 2. Every in-run automated path retains a 0/9 record.

---

## Root cause

**The write path is orphaned from the moment it is supposed to fire.** Capture is specified once, in `skills/code-review/SKILL.md`, and is scheduled to happen "inside the same skill run" — but the human verdict that constitutes an override is uttered *after* the skill run ends, during the pr-prep/review-fix fix pass, where the operative documents (`pr-prep.md` step 3b, `review-fix-loop.md` § Re-flagged settled decisions) specify only *reads* of the log and simultaneously offer three nearer, cheaper, and in one case mandatory alternative sinks for the same decision (rubric `Author note`, the commit-message `Notes:` field required by `CLAUDE.md`, and the PR description's "Areas of uncertainty"). The write therefore has no owner, no moment, no artifact slot, and no sentinel — against a read side with a numbered MUST, a dedicated step, a required negative sentinel, and two mandated deliverable sections.

**Confidence: high** for the structural claim (orphaned write path + competing sinks), based on: the read/write enforcement asymmetry being directly countable in `SKILL.md`; zero `override-log` references in `test/` or `hooks/`; the ≤1/9 run-level capture rate and 1-vs-32 verdict-level ratio; `45bea51`'s "Consciously not addressed" section being a fully-formed override table routed to a commit body; and the single existing row having been produced by the one path (manual author write, `9e64bb1`) that does not depend on any in-run trigger.

**Ruled out as the cause: a usage problem.** The competing explanation — that `code-review` simply isn't being run, so capture enforcement would fix nothing — is refuted by H7. The skill ran ≥9 times post-log. What stopped is rubric *persistence*, not review *execution*.

**Contributing amplifier (medium confidence):** since Tier B (`2b81baa`, 2026-07-22), most reviews run headless with no human present and no rubric persisted, so even a well-placed in-run trigger would fire on zero of them. Any fix that assumes a human reads a rubric will not cover the current dominant path.

---

## What this isn't

- **Not "overrides never happened" (H1).** tested: full-text grep of every commit body since the log was created, plus close reading of four fix commits. learned: at least 32 override-shaped verdicts exist, several stated in the exact vocabulary the log wants ("correctly not actioned", "accepted risk", "declined", "out of scope"). Eliminates the "empty log is correct behavior" branch entirely — do not spend further effort validating whether the log *should* have rows.
- **Not "the rubric overwrite destroys the prior verdict" (H5).** tested: `SKILL.md:790` explicitly exempts `override-log.md` from the overwrite/date-stamp convention, and the log survived untouched from 2026-05-12 to 2026-06-23. learned: eliminates artifact-lifecycle fixes (date-stamping the rubric, versioning review artifacts) as a route to fixing *this* problem. They may be worth doing for other reasons; they will not add rows.
- **Not a missing-instruction problem.** tested: counted the specification surface — ~40 lines across three files, including a numbered Mandatory Execution Rule, a capture-format table, a three-path enumeration, and a "why this isn't write-only" section. learned: eliminates "add more instruction text" as a candidate class. The protocol is among the most heavily specified things in the repo and has a 1/33 hit rate.
- **Not a low-usage problem — the skill runs, the artifacts don't persist (H7).** tested: re-derived the post-log run count from commit subjects/bodies instead of from `docs/reviews/code-review-rubric.md` commits; read all eight July review-round commits. learned: ≥9 post-log runs, not 1. Eliminates the "override log is downstream of a usage problem, so capture enforcement fixes nothing" branch. It also eliminates `docs/reviews/*` file history as a valid census of review activity from July 2026 onward — any future analysis must count commit bodies or SI-loop gate records instead, or it will undercount by ~8×.
- **Not an in-run capture success (H8).** tested: `git show --stat 9e64bb1` and its body. learned: the one existing row came from a separate human-authored follow-up commit ("Per author decision:"), not from capture path 1 or 2. Eliminates any reading in which the automated in-run paths have ever demonstrably worked — their record is 0/9, so do not treat them as a working mechanism that merely needs more runs.
- **Not a discoverability problem in the read direction.** tested: `rg -l override-log` shows the read path is cited from `pr-prep.md`, `review-fix-loop.md`, and the batch hook. learned: eliminates "agents don't know the file exists."

---

## Candidate fixes (ranked)

### 1. Move capture to the fix pass and give it a required artifact slot (recommended)

**What it changes — *when and by whom*:** capture stops being a code-review-skill responsibility and becomes a **pr-prep step 3b / review-fix-loop responsibility**, owned by the actor doing the fixing, at the moment it decides not to fix. Concretely: pr-prep's tier table gains a fourth outcome column — any finding resolved as "acknowledge without fixing", "note for later", or "out of scope" (the three waiver phrasings already in the table at `pr-prep.md:174–175, 189`) requires an override-log row *before* the fix commit lands. The step-3b prefilter is already there; this makes it bidirectional in the file where the decision actually occurs.

**How you'd know it worked:** the next review-fix loop that waives anything produces both a fix commit and an override-log diff in the same PR. Ratio check: re-run the reproduction command monthly — override-log rows should track within ~2× the count of `Refuted findings`/`accepted risk` phrases in commit bodies over the same window.

**Why first:** it is the only fix that relocates capture to the actor who holds the decision, and it costs no new document.

### 2. Make the commit-message `Notes:` field the capture surface (harvest, don't re-route)

**What it changes — *by whom*:** accepts that the data already lands in commit bodies (sink (b), which `CLAUDE.md` *requires* in /away mode) and stops fighting it. Add a `Refuted:` / `Waived:` line convention to the autonomous-commit format, then have pr-prep's Phase 2 (or a `scripts/` harvester, alongside `flag-removal-candidates.sh`) sweep `git log` for those lines and append the rows in one batch at PR time. The human/agent never writes the table by hand.

**How you'd know it worked:** run the harvester over the July history — it should retro-populate ~10–15 rows from `45bea51`, `31e2d3a`, `08563f1`, `a249cfe`, `0c02887`, etc. `45bea51` is the natural first fixture: its "Consciously not addressed (see review triage)" section is already a three-row override table in prose form, so a harvester that cannot parse it is not yet worth shipping.

**Tradeoff vs #1:** more machinery, but it survives /away mode and headless runs where nobody is reading a tier table. Complements #1 rather than competing — #1 fixes the interactive path, #2 fixes the autonomous one.

### 3. Add a mechanical write-side check to close the enforcement asymmetry

**What it changes — *enforcement, not instruction*:** a bats test in `test/` (the repo's existing enforcement surface, currently containing zero `override-log` references) or a `health-check.sh` rule that fails when a commit body contains waiver vocabulary but the same PR's diff does not touch `docs/reviews/override-log.md`. This is the write-side analogue of the read side's mandatory sentinel.

**How you'd know it worked:** the check fires on a deliberately-constructed test commit that waives a finding without logging it, and stays quiet on `9e64bb1` (which did both).

**Rank rationale:** high leverage but needs #1 or #2 to exist first — enforcing a path that has no owner just produces a red test nobody can satisfy.

### 4. Give Gate 1h an override-capture output (covers the headless path)

**What it changes — *when*:** extend the SI loop's `code-review` prompt beyond `CODE_REVIEW_RED: <n>` to also emit a `CODE_REVIEW_WAIVED:` block, and have `self-improvement.sh` append those to the log (or to a staging file the human reviews). Today Gate 1h keeps one integer and throws the rubric away.

**How you'd know it worked:** `record_gate_detail` payloads gain waiver entries, and rows appear from SI-loop task branches without human intervention.

**Rank rationale:** last because it is the narrowest scope and depends on decisions in #1/#2 about row format, but it is the only fix that touches what is now the highest-volume review path — schedule it immediately after whichever of #1/#2 ships.

**Explicitly not recommended:** adding a fourth specification site, strengthening the prose in `Capturing new overrides`, or promoting it to a numbered Mandatory Execution Rule. The read side already has all of that and the write side's problem is ownership and timing, not emphasis.

---

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to `/workspace/docs/working/handoff-diagnosis-override-log-not-written.md`, containing: 1. A `Reproduction:` line. 2. A `## Hypothesis log` section in the format above. 3. A root-cause statement naming the single most likely cause, with the evidence for it, and an explicit confidence level. 4. A `## What this isn't` section — one entry per refuted hypothesis with `tested:` / `learned:`, so the eliminated search space is preserved. 5. 2–4 candidate fixes, each stating what it changes and how you'd know it worked. Rank them. Prefer fixes that change *when or by whom* capture happens over fixes that add more instruction text to an already heavily-specified protocol — the repo has plenty of the latter and it is not working.
- Answered: yes — all five elements present; four ranked fixes, all relocating *when/by whom* rather than adding instruction text.
- Out of scope: implementing any fix; auditing pre-2026-05-12 rubrics for retroactive rows; assessing whether the 32 waived findings were *correct* calls.
- Escalate: three premises are wrong and downstream work should not inherit them — (a) the log postdates 9 of the 11 rubric commits; (b) two of the three named "capture" sites are read-only; (c) the coordinator's mid-task "eligible population is 1, capture rate 1/1" inference is refuted (H7) — it is ≥9 runs and ≤1/9, because July's seven review rounds never persisted a rubric. Also flag H6: Gate 1h (`2b81baa`) discards rubrics repo-wide, which is a larger observability loss than the override log alone, and is what makes `docs/reviews/` file history an ~8× undercount of review activity.
- Decisions I made: treated `## What this isn't` as covering refuted *and* eliminated-by-inconclusive branches, since H5 needed preserving; counted the commit-message `Notes:` field as a first-class competing sink rather than an informal one, because `CLAUDE.md` mandates it.
