# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u4b2`, branch feat/build-loop-u4b2)
**Scope:** range `ccc638d7..484eaafc`: `skills/dev-cycle/SKILL.md` and commit 484eaafc's message, checked against `scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `scripts/lib/dev-cycle-read.sh` and `scripts/questions.sh` at 484eaafc. The rest of the branch is context only.
**Checked:** 2026-10-13
**Replication:** k=1 (confirming pass)
**Commit:** 484eaafc
**Total claims checked:** 19
**Summary:** 11 verified, 5 mostly accurate, 0 stale, 3 incorrect, 0 unverifiable

Every non-Verified claim is labelled introduced-by-range or pre-existing, in its prose and under "Claims Requiring Attention". Every claim also carries a `Legibility-target`.

I read the hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 5 pattern entries) first. No claim here matches a logged pattern. No Incorrect verdict is a fabrication: every mode, refusal text and slug named exists. The log needs no new entry, and the brief allows writing only this report.

**Executed probes.** The scratch dir is `S=/tmp/claude-1000/-workspace/3f9d7e3a-3058-4f14-a27e-9ecde97197ee/scratchpad/u4b2-c2/fc/`. Each probe is a script `S/probe-*.sh` that:
- starts with `set -eu`;
- makes its own `mktemp -d /tmp/u4b2rv-fc2-XXXX`, named on the output's last line;
- refuses to run git outside that dir;
- uses hermetic git (`GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1`, a fixture HOME);
- runs the worktree's own scripts at 484eaafc.

Each was run as `bash S/probe-X.sh > S/probe-X.out 2>&1` with cwd `S`, and each exited 0. The bats run used cwd `/workspace/.claude/wt-build-loop-u4b2` and `TMPDIR=$(mktemp -d /tmp/u4b2rv-fc2-bats-XXXX)`, and exited 0.

| Probe | Run at (UTC) | Output | Claims |
|---|---|---|---|
| `probe-quote.sh` | 2026-10-14T03:19:57Z | `S/probe-quote.out` | 3a, 3b |
| `probe-answers.sh` | 2026-10-14T03:19:57Z | `S/probe-answers.out` | 5, 11 |
| `probe-land.sh` | 2026-10-14T03:20:35Z | `S/probe-land.out` | 4, 7, 9, 13 |
| `probe-approved.sh` | 2026-10-14T03:20:36Z | `S/probe-approved.out` | 12a, 12b, 14b |
| `bats --filter "GATE_CODE\|git_harden exports\|DISPATCHED\|cap" test/scripts/build-loop-orchestrator.bats` | 2026-10-14T03:20:51Z | `S/bats-skilltext.out` | (the SKILL-text tests still pass after the range's edits: 3/3 ok) |
| `probe-state.sh` | 2026-10-14T03:22:07Z | `S/probe-state.out` | 3c |

No probe starts a background process. The fixture dirs are left in place.

---

## Claim 1: "Every `build-loop.sh` and `dev-cycle.sh` call runs from WT (step 0's first two from MAIN_WT; step 7's self-merge from its GT, after a `--state` from MAIN_WT)"

**Location:** `skills/dev-cycle/SKILL.md:47-49`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the Rule's exception list now agrees with step 7's gate `--state` (`:494-496`). Does not establish where `--merge --approved` runs, which no step names, so the Rule sends it to WT. That is pre-existing, and it needs no GT, because `--approved` drops the checkout rule.
**Legibility-target:** orchestrator

The Rule now reads "step 7's self-merge from its GT, after a `--state` from MAIN_WT" (`skills/dev-cycle/SKILL.md:48-49`). Step 7 reads "`--state` (from MAIN_WT, whose config the add copies), then `hg -C MAIN_WT worktree add --detach GT`" (`:496-497`). The two agree, so the first confirming pass's Claim 1 (Stale; security N5) is fixed. Why it matters (paraphrased — no quote available because the evidence is the first pass's executed output, not code): `--state` run from WT passes a filter planted in MAIN_WT's `config.worktree` (`u4b2-c1/fc/probe-gt-state.out`).

**Evidence:** `skills/dev-cycle/SKILL.md:47-49`, `skills/dev-cycle/SKILL.md:494-498`

---

## Claim 2: "`--main-log`'s `other` lines block dispatch, merges and tests (step 0.2) but are no stop"

**Location:** `skills/dev-cycle/SKILL.md:63-64`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Rule's summary against step 0.2's hold. Does not establish script behaviour, since `--main-log` only prints the class.
**Legibility-target:** orchestrator

Step 0.2's hold covers more than this list. It holds "dispatch, every self-merge, every answer step 7 would act on, and the repo's health check and tests" (`:258-259`). Answers that are not merges (a re-dispatch, a drop) are held too (`:543-545`: "act on no answer this iteration"). The hold is also set by "a `refuse main-log:` line other than the bootstrap's own" (`:256-257`), and it lasts "until each such entry reads `keep`" (`:262-263`). The Rule names only `other` lines and only "dispatch, merges and tests". A precise version would read: "`--main-log`'s `other` lines and non-bootstrap refuse lines hold dispatch, merges, answers and tests while their entry does not read `keep` (step 0.2), but are no stop".

This is the remainder of the first pass's Claim 3. The range narrowed the gap: "merges and tests" are new. It is doc-only, because step 0.2 and step 7 carry the rule.

**Evidence:** `skills/dev-cycle/SKILL.md:63-64`, `skills/dev-cycle/SKILL.md:256-264`, `skills/dev-cycle/SKILL.md:543-545`

---

## Claim 3a: "else the line and stderr go in one `agent` entry, each line as `> Output: LINE` with any HTML comment opener and carriage return removed" (that `[`-, `<`- and fence-led lines no longer make the questions file unreadable)

**Location:** `skills/dev-cycle/SKILL.md:64-66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers FENCE_AWK as `--check-answer` runs it, over one pasted line in each of 11 shapes (listed below). Does not establish the doubled-opener case (Claim 3b) or entries the Rule does not reach (Claim 3c).
**Legibility-target:** orchestrator

The 11 shapes are:
- a plain refuse line;
- `[x]: y`;
- an open `[`;
- `<div>`;
- a line starting ```` ``` ````;
- a line starting `~~~`;
- `- ```` ``` ````;
- `### Q-009 · x`;
- `Q-001: [2]`;
- a mid-line `<!--`;
- an inner CR.

The lib's `refdef` strips only blanks, `>` and list markers before it tests for `[`: "`if (match(l, /^([ \t>]|[-*+][ \t]|[0123456789]+[.)][ \t])*/)) l = substr(l, RLENGTH + 1)`" (`scripts/lib/dev-cycle-read.sh:284`). The `Output:` word therefore puts every pasted line's own first character out of reach. `rawhtml` and `fenceish` anchor at the start of the line, after blanks only (`:276-277`). In `S/probe-quote.out`, all 11 shapes leave the file readable (`open Q-001`), for example:

```
starts [ with ]::                  [> Output: [x]: y] open Q-001
starts <:                          [> Output: <div>] open Q-001
starts ```:                        [> Output: ```] open Q-001
CR inside:                         [> Output: progress 50%progress 100%] open Q-001
```

A pasted `Q-001: [2]` cannot be read as an answer. ANSWER_AWK reads a line as an answer only when it starts, after "- ", with the ID or a bold label: "`if (index(line, id ":") == 1)`" (`:2103`). The first pass's Claim 4 (`[`-led lines and CR) and security N8's form are fixed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:273-315`, `scripts/lib/dev-cycle-read.sh:2100-2104`, `S/probe-quote.out`

---

## Claim 3b: "any HTML comment opener ... removed"

**Location:** `skills/dev-cycle/SKILL.md:65-66`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a single global removal pass, as `sed 's/<!--//g'` does it. Does not establish how an orchestrator would actually carry out "removed" (it may repeat the removal until none is left).
**Legibility-target:** orchestrator

Removing `<!--` is not idempotent. A line holding `<!<!----` becomes `<!--` after one global pass, and FENCE_AWK's `opencomment` then refuses the whole file:

```
nested opener <!<!----:            [> Output: x <!-- y] skip Q-001: line 12 of docs/working/questions.md opens an HTML comment that does not close on the same line, so no entry in docs/working/questions.md is read
```

The precise rule is: "removed until none is left", or replaced by text that cannot rebuild the opener, as step 7's REASON rule does with "(not shown: it opens an HTML comment)" (`:530-531`). This is introduced by the range: the earlier wording said "replaced". It is behavioural, but it fails closed: `--check-answer` skips, and `--cycle-diff` refuses the land.

**Evidence:** `scripts/lib/dev-cycle-read.sh:278-281`, `skills/dev-cycle/SKILL.md:530-531`, `S/probe-quote.out`

---

## Claim 3c: the `> Output:` form's reach ("in the `you: judgment` entry the step names, if it names one ... else the line and stderr go in one `agent` entry, each line as `> Output: LINE`")

**Location:** `skills/dev-cycle/SKILL.md:62-66`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which entries the form applies to, and one input that a step 0.1 judgment entry quotes. Does not establish what the orchestrator writes in practice.
**Legibility-target:** orchestrator

The form governs only the stop paragraph's `agent` entry. Other entries quote lines with no stated form:
- Step 0.1's `you: judgment` entry quotes `--state` refuse lines: "quoted in one `you: judgment` entry" (`:236`).
- Step 10's "one `agent` entry per brief" for a refusal (`:704-705`) is not a stop. This is security N8's remainder.

`--state` prints a planted config subsection name verbatim, `<!--` included (`S/probe-state.out`):

```
refuse state filter.<!--x.smudge: set in config, it can make the gate's git run a command or change its merge
```

Quoted as `> ` text, that line would make every questions-file read skip. This is pre-existing: step 0.1 and step 10 are unchanged by the range. Its effect is availability only, so it fails closed.

**Evidence:** `skills/dev-cycle/SKILL.md:232-237`, `skills/dev-cycle/SKILL.md:703-705`, `scripts/build-loop.sh:618-619`, `S/probe-state.out`

---

## Claim 4: "one `you: judgment` entry naming its SHA (slug `other-commit-SHA12`) or quoting the line (slug `main-log-refused-MAIN12`)"

**Location:** `skills/dev-cycle/SKILL.md:259-261`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers four things:
- that MAIN is printed on a `--main-log` refusal, so MAIN12 can be formed;
- that both slugs pass `questions.sh check`;
- that `--cycle-diff` and `--land-cycle` accept new entries with these slugs;
- that `--check-answer` reads them.

Does not establish how a later session finds these entries (by heading prefix; no step says so).
**Legibility-target:** orchestrator

Every refusal path in `main_log` prints MAIN first: "`echo "main $MAIN_SHA -"; echo "refuse main-log: $1 is not on the default branch's first-parent history at $MAIN_SHA"`" (`scripts/build-loop.sh:1803`, and likewise `:1800` and `:1806`). Executed:

```
main 0e503af2075e39ec51a1c961e5467439e60d16c5 -
refuse main-log: dc7c80be... is not on the default branch's first-parent history at 0e503af2...
```

`questions.sh check`'s heading grammar is "`^\#\#\#\ Q-[0-9]{3}\ ·\ [a-z0-9-]+$`" (`scripts/questions.sh:251`). Lower-case hex passes it, and so does the probe's `other-commit-0e503af2075e` / `main-log-refused-0e503af2075e` pair ("✓ questions: structure valid, indexes current"). Neither entry is put on an `Asked:` line, so `--cycle-diff`'s WORDS-STEM-N rule (`scripts/build-loop.sh:1993`) does not apply. `--cycle-diff` printed `ok`, `--land-cycle` landed, and `--check-answer Q-001 Q-002` on main printed `open` for both (`S/probe-land.out`). Security N2(c), "no slug for refuse main-log", is fixed.

**Evidence:** `scripts/build-loop.sh:1794-1806`, `scripts/questions.sh:248-254`, `scripts/build-loop.sh:1988-1995`, `S/probe-land.out`

---

## Claim 5: "with options **[1] reviewed, build on it** and **[2] keep holding**. The hold lasts, in every later iteration, until each such entry reads `keep` (`--check-answer`)"

**Location:** `skills/dev-cycle/SKILL.md:261-263`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers how `--check-answer` reads the two options and the non-`keep` results (`open`, `drop`, `unrecognized`, `skip`), all of which hold. Does not establish when the orchestrator calls `--check-answer` for these IDs. Step 7's call lists only `Asked:` items and merge entries (`:538-539`), and the hold must be read before step 1's health check; no step names that call. Also not established: a `[2]` answer holds for ever, since the commit is never re-listed and the entry never re-filed (a design consequence, not a script mismatch).
**Legibility-target:** orchestrator

`option()` lower-cases, strips leading blanks and `*`, then returns: "`if (substr(s, 1, 3) == "[1]") return "keep"`" (`scripts/lib/dev-cycle-read.sh:2071-2072`). Its other results, by input (`S/probe-answers.out`):

| Answer | Reads |
|---|---|
| `Q-001: [1] reviewed, build on it` | `keep` |
| `Q-001: [2] keep holding` | `drop` |
| `reviewed` | `unrecognized` |
| `[1]` with the Status still OPEN | `open` (`answered = (v == "ANSWERED")`, `:2096`) |

`--merge --approved` reads the same function and accepts only `keep` (`scripts/build-loop.sh:1448-1454`). Security N2(a) and N2(b), where the hold lifted on any non-`open` reading, are fixed: only `keep` lifts it now.

**Evidence:** `scripts/lib/dev-cycle-read.sh:2070-2084`, `scripts/lib/dev-cycle-read.sh:2090-2097`, `scripts/dev-cycle.sh:61-76`, `S/probe-answers.out`

---

## Claim 6a: "holds dispatch, every self-merge, every answer step 7 would act on ... so a commit the user has not seen never feeds a merge ... or a loop"

**Location:** `skills/dev-cycle/SKILL.md:258-264`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each place in SKILL.md that runs `--merge` or a dispatch: step 7's self-merge, step 7's answers (approved merges and re-dispatches) and step 10. Does not establish the accepted residual: an `answers`-class commit can answer the hold entry itself (row 727 / F19).
**Legibility-target:** orchestrator

The three places each name the hold:
- Self-merge: "**ready**, POLICY `self-merge` (not while step 0.2's hold is on)" (`:494`).
- Answers: "if it lists an `other` line after MAIN, or step 0.2's block holds, act on no answer this iteration" (`:543-545`).
- Dispatch: "with no dispatch block from step 0.2" (`:687`).

The first pass's Claim 6 (Incorrect) and security N1 are fixed.

**Evidence:** `skills/dev-cycle/SKILL.md:494-495`, `skills/dev-cycle/SKILL.md:543-545`, `skills/dev-cycle/SKILL.md:687-688`

---

## Claim 6b: "and the repo's health check and tests (steps 1 and 4) ... so a commit the user has not seen never feeds ... a test run"

**Location:** `skills/dev-cycle/SKILL.md:258-264`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers which steps the hold names, against the steps SKILL.md says run tests. Does not establish that a given iteration's step 2, 3 or 4b subagent will in fact run a repo test (that is the medium in the confidence).
**Legibility-target:** orchestrator

The hold names only "steps 1 and 4" (`:259`), and step 1 repeats this: "step 4 then runs no repo test either" (`:304-305`). Steps 2 to 4b run tests of their own, after step 1's wait: "wait for it to finish before steps 2–4b start their own tests and subagents" (`:308`). The Rules permit that: "Run only commands this skill names and tests that exist in the repo's test tree" (`:36`). Step 2's evidence can be "a command and its output" (`:348`), and step 3 makes in-cycle fixes (`:361-362`). With the hold on, nothing in their text stops a test that runs the unreviewed commit's code. The guarantee "never feeds ... a test run" is therefore broader than the mechanism. A precise version names steps 2-4b as well, or narrows the sentence.

This is introduced by the range: the "test run" guarantee and the step list are new in 484eaafc. It is behavioural. The same class was closed for steps 1 and 4 (row 776, security N3).

**Evidence:** `skills/dev-cycle/SKILL.md:36`, `skills/dev-cycle/SKILL.md:258-264`, `skills/dev-cycle/SKILL.md:303-308`, `skills/dev-cycle/SKILL.md:347-349`

---

## Claim 7: "merge the commit the session made there (by its id, not the branch name) into WT first (as step 9 merges main in)"

**Location:** `skills/dev-cycle/SKILL.md:267-271`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers four things: a merge by commit id with step 9's flags; that `--cycle-diff` and `--land-cycle` accept the result; that `--main-log` reads the land as `chore`; that the stranded commit's entries land. Does not establish how the session remembers the id across a restart (session memory; an ended session loses it).
**Legibility-target:** orchestrator

The probe merged the stranded commit by id, with `-c rerere.enabled=false merge --no-edit --no-ff`. Git writes "Merge commit '232371eb…' into chore/dev-cycle-2026-10-13-0930". The rest of `S/probe-land.out`:
- `--cycle-diff` printed `ok`;
- `--land-cycle` printed `landed chore/dev-cycle-2026-10-13-0930 …`;
- `--main-log` read `chore 2c0b0437… Merge branch 'chore/dev-cycle-2026-10-13-0930'`.

`--main-log` reads only first-parent commits (`scripts/build-loop.sh:139-148`), so the inner merge's message is never classified. Security N4 is addressed as recommended (merge the session's commit, not the ref).

**Evidence:** `scripts/build-loop.sh:139-163`, `scripts/build-loop.sh:2044-2077`, `S/probe-land.out`

---

## Claim 8: "skipped while step 0.2's hold is on, as an unreviewed commit's test code would run (row 776; step 4 then runs no repo test either)"

**Location:** `skills/dev-cycle/SKILL.md:303-305`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that step 1's skip is now keyed on the hold, not on step 0.2's window, so it persists while the entry does not read `keep`. Does not establish steps 2-4b (Claim 6b).
**Legibility-target:** orchestrator

The skip condition is now "while step 0.2's hold is on" (`:303-304`), and the hold persists "in every later iteration, until each such entry reads `keep`" (`:262-263`). The next iteration's `1.` line then reads "skipped" (`:616`), which breaks the `passed at P` / `unchanged since P` chain (`:305-306`), so the first run after release is a full one. Security N3 is fixed for steps 1 and 4.

**Evidence:** `skills/dev-cycle/SKILL.md:262-263`, `skills/dev-cycle/SKILL.md:303-307`, `skills/dev-cycle/SKILL.md:616`

---

## Claim 9: "or when the previous iteration's `1.` line reads `passed at P` or `unchanged since P` and step 0.2 listed only `chore` lines (cycle lands carry no code; this iteration's line then reads `unchanged since P`)"

**Location:** `skills/dev-cycle/SKILL.md:305-307`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers claude-workflows' health-check gates that a chore land can change. That is check 14 (the questions doc). The others either read files `--cycle-diff` refuses or are soft warnings. Does not establish other repos' health checks, or a forged `chore` commit (F19, accepted).
**Legibility-target:** orchestrator

The first pass's Claim 8b (Incorrect, pre-existing) was that a chore land leaves the questions index stale, and check 14, "Running-questions doc: entry grammar, unique ids, index freshness (gate)" (`scripts/health-check.sh:53`), would fail while the chain skips it. Step 9.1 now runs `questions.sh index` and `check` before staging (Claim 13), so the cycle's own lands keep check 14 green. Executed: `check` fails ("index is stale") before `index` and passes after (`S/probe-land.out`).

Paraphrased — no quote available because the claim covers absence (a grep with no gating hit): the bats suites copy only `docs/dev-cycle.md` (truth, refused), `docs/evaluation-rubric.md` and `docs/rubric.md` into fixtures, and no gated check asserts on another `docs/*.md` a chore may edit.

What remains imprecise: 9.1 says nothing about what a failing `check` does (stage anyway, fix, or stop). This is pre-existing and largely fixed by the range.

**Evidence:** `scripts/health-check.sh:38-53`, `skills/dev-cycle/SKILL.md:645-647`, `test/generate-reports.bats:207`, `test/skills/self-eval/runner.bash:24`, `S/probe-land.out`

---

## Claim 10: "**ready**, POLICY `self-merge` (not while step 0.2's hold is on)"

**Location:** `skills/dev-cycle/SKILL.md:494-495`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that a held `ready` self-merge brief is neither merged nor counted for a slot. Does not establish that the record or the final message names it (no line says so).
**Legibility-target:** orchestrator

The bullet excludes the held case, and step 8 leaves a ready brief uncounted: "a blocked, stopped, capped or ready one, or a stalled one held, waits on the user and is not counted" (`:571-572`).

**Evidence:** `skills/dev-cycle/SKILL.md:494-495`, `skills/dev-cycle/SKILL.md:567-572`

---

## Claim 11: "An answer starting `[1]`, or that is `1` or `keep` (any case) alone or before one of `.,;:!)*` or a blank and a dash, reads `keep`; likewise 2 or `drop`, 3 or `done`; anything else, `unrecognized`"

**Location:** `skills/dev-cycle/SKILL.md:540-542`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `option()`'s token rule, through `--check-answer`, for 15 answer lines. Does not establish two things the sentence leaves unstated: leading blanks and `*` are stripped first (`**keep**` reads `keep`), and the dash may be `-`, an en dash or an em dash.
**Legibility-target:** user

The code is "`if (!(r == "" || r ~ /^[.,;:!)*]/ || (t != r && (t == "" || substr(t, 1, 1) == "-" || … "\342\200\224" || … "\342\200\223"))))`" (`scripts/lib/dev-cycle-read.sh:2077-2079`). Readings from `S/probe-answers.out`:

| Answer | Reads |
|---|---|
| `Keep.`, `keep)`, `**keep**`, `keep - yes`, `keep -yes`, `keep — yes`, `keep ` | `keep` |
| `keep-it`, `keep?`, `keep (go)`, `reviewed` | `unrecognized` |
| `**Answer:** [1] reviewed` | `keep` |

The first pass's Claim 10 is fixed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:2070-2084`, `S/probe-answers.out`

---

## Claim 12a: "A refusal that cannot clear (the paths, a conflict, the tip or heading, a brief no longer open, an object that does not hash) is filed as `stopped`"

**Location:** `skills/dev-cycle/SKILL.md:554-556`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named class against `--merge --approved`'s refusal texts. Does not establish the refusals named in neither class (Claim 12b).
**Legibility-target:** orchestrator

Each class has a text:
- tip: "refuse $a: the tip of $br is $sha, not the expected $EXPECT" (`scripts/build-loop.sh:1364`);
- heading: "approves no merge of this tip: its heading must read …" (`:1457`);
- not open: "the brief is $st on the default branch; only an open brief merges" (`:1361`);
- conflict: "$br conflicts with the default branch" (`:1368`);
- paths: "$nd of N changed paths refused" (`:1417`).

The object class's text is broader than "does not hash". It reads "an object of the tip of $br or of the merge does not hash to its id, has a second copy in the object store, or could not be read" (`:1388`). A second copy (repacking) and a read failure can clear, and step 7's self-merge bullet calls "a failed read" the environment's, to be retried (`:506`). This is introduced by the range (D8, reworded). It fails closed.

**Evidence:** `scripts/build-loop.sh:1355-1417`, `scripts/build-loop.sh:1442-1458`, `skills/dev-cycle/SKILL.md:505-507`

---

## Claim 12b: "MAIN_WT's state, no identity or a moved main is retried next iteration and named in the final message, the ID left off `Applied:`" (as the rest of the partition: every approved refusal is either filed `stopped` or retried)

**Location:** `skills/dev-cycle/SKILL.md:553-557`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--merge --approved`'s refusal texts against the two classes. Does not establish which class each unlisted refusal belongs in.
**Legibility-target:** orchestrator

The range replaced "any other (MAIN_WT's state, no identity, a moved main) is retried" with two closed lists. Many refusals now fall in neither, and the step gives no action for them. Executed (`S/probe-approved.out`):

```
--- (a) the branch already merged by hand (a lost Applied: line), brief still open:
refuse docs/working/briefs/2026-10-01-x.md: its branch feat/x has no commit the default branch lacks
--- (b) the branch deleted:
refuse docs/working/briefs/2026-10-01-x.md: its branch feat/x does not exist
--- (c) a worktree (not MAIN_WT) mid-rebase of main ...:
refuse docs/working/briefs/2026-10-01-x.md: a worktree is rebasing the default branch
```

The code holds more refusals in neither list:
- "the merge of $br names a blob the object store lacks" (`:1385`);
- "could not be computed" and "could not be listed" (`:1369`, `:1374`);
- "the merge commit could not be written" (`:1557`);
- "the git state changed after the check" (`:1560`);
- "the default branch is checked out in two worktrees" (`:1499`);
- approval's `open`, `skip`, `drop` and `done` texts (`:1450-1454`; a race between `--check-answer` and `--merge`);
- a `skip BRIEF:` line from `--status`.

Case (a) is the case security N7 named ("after a lost `Applied:` line"). It is still unrouted, so N7 is only partly fixed.

This is introduced by the range: removing the catch-all created the gap. It is behavioural, and it fails closed (nothing merges), but the approval's fate is undefined. A precise version keeps a catch-all, for example "any other refusal is filed as `stopped`, the refusal its reason".

**Evidence:** `scripts/build-loop.sh:1355-1417`, `scripts/build-loop.sh:1442-1458`, `scripts/build-loop.sh:1491-1570`, `scripts/build-loop.sh:2124-2134`, `S/probe-approved.out`

---

## Claim 13: "Stage by name ... after `questions.sh index` and `check` in WT when this iteration filed or edited entries"

**Location:** `skills/dev-cycle/SKILL.md:645-647`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers four things: that `questions.sh` resolves WT's `docs/working/` when run there; that `index` clears `check`'s stale-index failure for new entries; that `--cycle-diff` and `--land-cycle` accept the regenerated index; that main's copy then passes `check`. Does not establish the action on a failing `check` (Claim 9).
**Legibility-target:** orchestrator

`questions.sh` acts on "the docs/working/ of the git repo you run it FROM (the toplevel of $PWD)" (`scripts/questions.sh:36-37`). Its check compares the index to the entries: "index is stale — run: $QS_CMD index" (`:301-302`). From `S/probe-land.out`:
1. In WT after filing two entries, `check` failed: `✗ questions.md: index is stale`.
2. After `index`, it passed: `✓ questions: structure valid, indexes current`.
3. `--cycle-diff` printed `ok`, and the land landed.
4. `check` on main passed.

The index table sits outside every entry, and `--cycle-diff` judges only entries' heading, Needs and answer lines ("Other entry lines are free", `scripts/build-loop.sh:199-200`).

**Evidence:** `scripts/questions.sh:233-306`, `scripts/build-loop.sh:189-203`, `S/probe-land.out`

---

## Claim 14a: commit 484eaafc message: "step 0.2's hold covers dispatch, self-merges, answers, the health check and step 4's tests, and lasts until each other-commit-SHA12 or main-log-refused-MAIN12 entry reads keep ([1] reviewed, build on it)"; "the D6 Rule names the --state step 7 runs from MAIN_WT"; "a stranded chore commit is merged by its id, not the branch name"; "questions.sh index and check run before entries are staged"; "the answer grammar's punctuation listed"

**Location:** commit `484eaafc` message body
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each bullet against the SKILL text it describes and the probes cited in Claims 1, 4, 5, 7, 11 and 13. Does not establish the subject's "tests" beyond steps 1 and 4 (Claim 6b), or the pasted-line bullet (Claims 3a-3c).
**Legibility-target:** user

Each bullet matches the text the range wrote (`skills/dev-cycle/SKILL.md:48-49`, `:256-264`, `:267-269`, `:540-541`, `:645-647`). The subject line, "the other hold covers self-merges and tests until reviewed", is accurate for the tests of steps 1 and 4 only. The bullet itself says "the health check and step 4's tests".

**Evidence:** `skills/dev-cycle/SKILL.md:47-49`, `skills/dev-cycle/SKILL.md:256-271`, `skills/dev-cycle/SKILL.md:540-541`, `skills/dev-cycle/SKILL.md:645-647`, `S/probe-land.out`, `S/probe-answers.out`

---

## Claim 14b: commit 484eaafc message: "an approved merge refused for a cause that cannot clear (paths, conflict, tip or heading, a brief no longer open, a bad object) is filed stopped; MAIN_WT's state, identity or a moved main retries, named in the final message"

**Location:** commit `484eaafc` message body
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claims 12a and 12b.
**Legibility-target:** user

The two lists are presented as a partition, but the refusals in Claim 12b ("no commit the default branch lacks", "does not exist", "a worktree is rebasing the default branch", and the others listed there) fit neither (`S/probe-approved.out`). This is introduced by the range. Behavioural; it fails closed.

**Evidence:** `scripts/build-loop.sh:1361-1388`, `scripts/build-loop.sh:1491-1570`, `S/probe-approved.out`

---

## First confirming pass: status of its findings at 484eaafc

| First-pass finding | Status now | Where |
|---|---|---|
| FC Claim 1 / security N5 (the Rules omit step 7's MAIN_WT `--state`) | fixed | Claim 1 |
| FC Claim 3 (the Rule's summary of the `other` hold) | narrowed; the answers half and persistence still missing (doc-only) | Claim 2 |
| FC Claim 4 / security N8 (pasted lines) | form fixed for `[`, `<`, fences, CR; new doubled-opener case; step 0.1 and step 10 entries still outside the form (pre-existing) | Claims 3a-3c |
| FC Claim 6 / security N1 (self-merge under the hold) | fixed | Claim 6a |
| FC Claim 8b / security N6 (chained skip vs check 14) | fixed for the cycle's own lands; the action on a failing `check` is unstated | Claims 9, 13 |
| FC Claim 10 (answer punctuation) | fixed | Claim 11 |
| FC Claim 12b / security N7 (approved refusals) | partly: unclearable causes are now filed, but the catch-all is gone and N7's own "not ahead" case is unrouted | Claims 12a, 12b, 14b |
| Security N2 (release on any non-`open`; no refuse slug) | fixed | Claims 4, 5 |
| Security N3 (health check and step 4 after an `other` commit) | fixed for steps 1 and 4; the new "never feeds a test run" overreaches to steps 2-4b | Claims 6b, 8 |
| Security N4 (stranded branch by name) | fixed | Claim 7 |

---

## Claims Requiring Attention

### Incorrect
- **Claim 6b** (`skills/dev-cycle/SKILL.md:258-264`): "never feeds ... a test run" is broader than what it holds. The hold names steps 1 and 4 only, but steps 2-4b "start their own tests" (`:308`). Introduced by the range. Behavioural, Medium. Fix: name steps 2-4b or narrow the sentence.
- **Claim 12b** (`skills/dev-cycle/SKILL.md:553-557`): the range dropped the catch-all. Approved-merge refusals in neither class get no action, among them "no commit the default branch lacks" (N7's lost-`Applied:` case), "does not exist" and "a worktree is rebasing the default branch" (all executed). Introduced by the range. Behavioural, High. Fails closed.
- **Claim 14b** (commit 484eaafc): the same partition, stated in the commit message. Introduced by the range. High.

### Stale
- None.

### Mostly Accurate
- **Claim 2** (`skills/dev-cycle/SKILL.md:63-64`): the Rule omits the non-merge answers, the refuse-line trigger and the hold's persistence. Introduced (it narrows the first pass's Claim 3). Doc-only.
- **Claim 3b** (`skills/dev-cycle/SKILL.md:65-66`): "removed" in one pass turns `<!<!----` into `<!--`, and `--check-answer` then skips the whole file (executed). Introduced. Behavioural, fails closed.
- **Claim 3c** (`skills/dev-cycle/SKILL.md:62-66`): the form covers only the stop paragraph's `agent` entry. Step 0.1's judgment entry can quote a `--state` line holding `<!--` (executed), and step 10's entries are not covered either. Pre-existing. Behavioural, fails closed.
- **Claim 9** (`skills/dev-cycle/SKILL.md:305-307`): fixed in effect by 9.1, but the action on a failing `questions.sh check` is unstated. Pre-existing. Doc-only.
- **Claim 12a** (`skills/dev-cycle/SKILL.md:554-556`): the "does not hash" refusal's text also covers a second copy and a failed read, which can clear (and are retried in the self-merge bullet). Introduced. Fails closed.

### Unverifiable
- None.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A code-fact-check report saved at the given path, every checkable claim in the range verdicted with evidence"
- **Answered:** yes.
  - The report is at `docs/reviews/code-fact-check-report-2026-10-13-u4b2-confirm2.md`, with header `**Replication:** k=1 (confirming pass)` and `**Commit:** 484eaafc`.
  - Its 19 claims cover every script-checkable statement the range adds or rewrites in `skills/dev-cycle/SKILL.md`, and commit 484eaafc's message.
  - Each claim carries the seven mandatory fields plus Legibility-target, and each non-Verified claim is labelled introduced-by-range or pre-existing.
  - The first confirming pass's findings (code-fact-check and security reports) are re-checked in the status table.
- **Out of scope / not verdicted:** range text with no script contract:
  - "named in the final message" (the final message's list is prose);
  - where a later session finds the hold entries (no step names it; noted in Claims 4 and 5);
  - the deferred override rows, which were not re-opened.
- **Static only:** Claims 1, 2, 6a, 6b, 8 and 10.
- **Escalate:**
  - **Claim 12b / 14b.** A behavioural Incorrect the range introduced: an approved merge refused for a cause in neither list has no route, including the very case security N7 named. It fails closed.
  - **Claim 6b.** A new guarantee ("never feeds a test run") that the mechanism does not deliver for steps 2-4b. This is a Medium-class item introduced by the range, of the kind the rubric's gate says "stops it and goes to the user".
- **Decisions I made:**
  - Treated the two lists in 12b as a claimed partition, because the range removed the earlier "any other" catch-all and the commit message presents them as the two outcomes.
  - Read "removed" as one global pass (as `sed s///g` does) for Claim 3b, and named the alternative reading in its Scope.
  - Did not edit the hallucination-pattern log: there are no fabrications, and the brief allows writing only this file.
