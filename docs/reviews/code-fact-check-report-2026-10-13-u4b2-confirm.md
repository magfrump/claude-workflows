# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u4b2 (feat/build-loop-u4b2)
**Scope:** the range `b88e418a..ccc638d7`: `git diff b88e418a..ccc638d7 -- skills` (`skills/dev-cycle/SKILL.md`, the whole post-change file read), commit ccc638d7's message, and the one-line plan as-built note it adds. Checked against `scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `scripts/lib/dev-cycle-read.sh`, `scripts/questions.sh` (and `scripts/health-check.sh` for Claim 8b), with the rest of the branch as context
**Checked:** 2026-10-13
**Replication:** k=1 (confirming pass)
**Commit:** ccc638d7
**Total claims checked:** 19 (17 numbered; Claims 8 and 12 split into a/b)
**Summary:** 12 verified, 3 mostly accurate, 1 stale, 3 incorrect, 0 unverifiable

Legibility-target per claim: **orchestrator** (text the orchestrator executes; a wrong statement is behavioural) or **reader** (a maintainer or reviewer reading the text or a commit message; doc-only).

Introduced-by-range or pre-existing: every non-Verified claim is labelled in its prose and in "Claims Requiring Attention".

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 5 entries). No claim here matches a logged pattern, and no Incorrect verdict is a fabrication: every named mode, symbol and refusal exists. The log needs no new entry, and the brief allows writing only this report.

**Executed probes.** Scratch dir `S=/tmp/claude-1000/-workspace/3f9d7e3a-3058-4f14-a27e-9ecde97197ee/scratchpad/u4b2-c1/fc/`. Each probe is a script `S/probe-*.sh` that starts with `set -eu`, makes its own `mktemp -d /tmp/u4b2rv-fc-XXXX` (named on the output's last line), and refuses to run git outside it. It uses hermetic git (`GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1`, a fixture HOME) and runs the worktree's scripts at ccc638d7. Each was run as `bash S/probe-X.sh > S/probe-X.out 2>&1` with cwd `S`, exit 0, git 2.39.5:

| Probe | Run at (UTC) | Output | Claims |
|---|---|---|---|
| `probe-answers.sh` | 2026-10-14T03:07:44Z | `S/probe-answers.out` | 10, 13 |
| `probe-gt-state.sh` | 2026-10-14T03:07:58Z | `S/probe-gt-state.out` | 1, 9, 16 |
| `probe-land.sh` | 2026-10-14T03:08:34Z | `S/probe-land.out` | 2, 5, 7, 13, 14 |
| `probe-quote.sh` | 2026-10-14T03:09:11Z (final run; two earlier runs fixed its own fixture) | `S/probe-quote.out` | 4, 8b |
| `probe-approved.sh` | 2026-10-14T03:10:03Z | `S/probe-approved.out` | 12a, 12b |
| `probe-slug.sh` | 2026-10-14T03:10:32Z | `S/probe-slug.out` | 5 |

No probe starts a background process. Fixture dirs are left in place.

---

## Claim 1: "Every `build-loop.sh` and `dev-cycle.sh` call runs from WT (step 0's first two from MAIN_WT, step 7's self-merge from its GT)"

**Location:** `skills/dev-cycle/SKILL.md:47-49`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the Rule's list of exceptions against step 7's gate-checkout `--state`, which the range moved. Does not establish anything about the other calls the Rule governs, which the range did not change.
**Legibility-target:** orchestrator

The range changed step 7's pre-GT `--state` to run from MAIN_WT: "`--state` (from MAIN_WT, whose config the add copies)" (`skills/dev-cycle/SKILL.md:490`). The Rule's exception list still names only "step 0's first two from MAIN_WT, step 7's self-merge from its GT" (`:48`). Step 7's `--state` is neither of those, so the Rule sends it to WT. That is the location the D2 fix moved it away from.

This is introduced by the range: a new contradiction with the Rules. It matters because WT's `--state` passes a filter planted in MAIN_WT's `config.worktree`, which then runs in GT's `worktree add`. From `S/probe-gt-state.out`:

```
MAIN_WT:
refuse state filter.x.smudge: set in config.worktree, it can make the gate's git run a command or change its merge
exit 2
WT:
ok
```

This is the same pattern as iteration 2's B2, where the Rules contradicted step 7's GT and following the Rules recreated A2. The fix is to add "and step 7's pre-GT `--state` from MAIN_WT" to the exception list.

**Evidence:** `skills/dev-cycle/SKILL.md:47-49`, `skills/dev-cycle/SKILL.md:489-491`, `S/probe-gt-state.out`

---

## Claim 2: "Each stop ends the iteration there (one before step 9's land lands no record, so the next starts from the same `Main at:`; one in step 10's land comes after it)"

**Location:** `skills/dev-cycle/SKILL.md:59-61`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that a record reaches main only through `--land-cycle`, and that the first land already carries the record (so a stop in step 10's land leaves it on main). Does not establish the D9 interplay, where a stopped-after-commit branch's record lands with the next iteration (Claim 7).

The SINCE that step 0.2 reads comes from main's newest record (`:236-240`), and the record reaches main only in the land. In `S/probe-land.out` the first land prints `landed chore/dev-cycle-2026-10-13-0930 …`, and `--main-log` then reads it as `chore` with the record on main. The second land runs after that, so a stop there leaves the first land's record in place.

**Evidence:** `skills/dev-cycle/SKILL.md:236-240`, `S/probe-land.out`

---

## Claim 3: "`--main-log`'s `other` lines block dispatch but are no stop"

**Location:** `skills/dev-cycle/SKILL.md:62-63`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Rule's summary of what an `other` line does, against step 0.2's text after the range. Does not establish the script's behaviour, which only prints the class.

Step 0.2 now says an `other` line "blocks this iteration's dispatch and every answer step 7 would act on" and holds "in every later iteration while such an entry is open" (`:256-260`). The Rule still says dispatch only. The precise version is: "block dispatch and answers, while their `other-commit-` entry is open, but are no stop".

This is introduced by the range, because the answers half and the persistence are new. It is doc-only in effect, since step 7's own text (`:537-539`) carries the rule.

**Evidence:** `skills/dev-cycle/SKILL.md:62-63`, `skills/dev-cycle/SKILL.md:255-260`, `skills/dev-cycle/SKILL.md:537-539`

---

## Claim 4: "else the line and stderr go in one `agent` entry, each line quoted as `> ` text with any HTML comment opener replaced"

**Location:** `skills/dev-cycle/SKILL.md:62-64`
**Type:** Behavioral / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the stated form keeps `--check-answer` (and with it `--cycle-diff`'s whole-file rule) reading the questions file, which is D5's stated purpose and step 7's reason for the same treatment of REASON (`:524-526`). Does not establish which real script or stderr lines take the failing shapes. Script lines start with fixed words; git's stderr lines start with `fatal:`/`error:`.

The form works for ordinary lines. It does not cover two shapes that `FENCE_AWK` still refuses behind `> `:

- A line starting `[` that holds `]:` or leaves `[` open. `refdef` strips leading `>` first: `if (match(l, /^([ \t>]|[-*+][ \t]|[0123456789]+[.)][ \t])*/)) l = substr(l, RLENGTH + 1)` … `return index(l, "]:") || !index(l, "]")` (`scripts/lib/dev-cycle-read.sh:281-289`; excerpt ends :289; enclosing `refdef()` ends there — read).
- A carriage return inside a line: `if (index(l, "\r")) { refuse("cr"); return 1 }` (`scripts/lib/dev-cycle-read.sh:302`). Git progress output on stderr uses CR.

From `S/probe-quote.out`, after a questions entry holding one quoted line:

```
plain refuse line:           open Q-001
comment opener replaced:     open Q-001
line starting [ with ]::     skip Q-001: line 12 of docs/working/questions.md starts like a link reference definition …
line starting [ left open:   skip Q-001: line 12 … starts like a link reference definition …
line starting [ closed:      open Q-001
line with a CR:              skip Q-001: line 12 … holds a carriage return that does not end it …
```

This is the same gap iteration 3's C3 closed for REASON by writing `> Reason: REASON`, so the line never starts with `[`. The rule is new in the range (introduced). It fails closed: the land refuses and nothing bad lands, but every land stalls until someone fixes it by hand. A complete form would also prefix a word (`> Output: LINE`) and replace CR.

**Evidence:** `skills/dev-cycle/SKILL.md:62-64`, `skills/dev-cycle/SKILL.md:524-526`, `scripts/lib/dev-cycle-read.sh:281-289`, `scripts/lib/dev-cycle-read.sh:302`, `S/probe-quote.out`

---

## Claim 5: "gets one `you: judgment` entry naming its SHA (slug `other-commit-SHA12`) … The block holds in every later iteration while such an entry is open (`--check-answer` prints `open`)"

**Location:** `skills/dev-cycle/SKILL.md:256-260`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that an `other-commit-0123456789ab` entry is accepted by `questions.sh check`/`open`, lands through `--cycle-diff`/`--land-cycle` (it is not an `Asked:` item, so the WORDS-STEM-N rule does not apply), and reads `open` through `--check-answer` from main. Does not establish how a later iteration finds the entry's ID. The text does not say; scanning WT's questions files for the slug is implied by "unless an open one does".

- `S/probe-slug.out`: `✓ questions: structure valid, indexes current` and `Q-001  you: judgment   other-commit-0123456789ab`.
- `S/probe-land.out`: the entry Q-003 `other-commit-0123456789ab` lands (`--cycle-diff` `ok`, `landed …`), and `--check-answer` prints `open Q-003`.
- The persistence is needed. SINCE becomes this iteration's MAIN (`:628-631`), so the next `--main-log` no longer lists the commit. The open entry is what keeps the block.

**Evidence:** `skills/dev-cycle/SKILL.md:255-260`, `skills/dev-cycle/SKILL.md:628-631`, `scripts/questions.sh:272-273`, `S/probe-slug.out`, `S/probe-land.out`

---

## Claim 6: "so a commit the user has not seen never feeds a merge or a loop"

**Location:** `skills/dev-cycle/SKILL.md:260`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "merge" half against step 7's self-merge bullet. Does not establish exploitability beyond what the security reviews already state (F1). The "loop" half holds for dispatch (`:679-681`).

The block covers dispatch and answers only: "blocks this iteration's dispatch and every answer step 7 would act on" (`:256-257`). Step 7's self-merge bullet carries no hold: "**ready**, POLICY `self-merge`: `--merge BRIEF --expect TIP`, run from a gate checkout … A `merged` line goes in the record." (`:489-495`; excerpt ends :495; the bullet continues to :501 with the refusal routing, which also has no hold — read).

`--merge` reads main's live commit, which includes the unseen `other` commit. It merges TIP into it and reads `--settings` (policy, never globs) from it, per the header: "`--settings` five lines from the default branch's commit" (`scripts/build-loop.sh:19`). So while the block holds, an unclassified commit still feeds every self-merge of a `ready` brief. Examples are a commit that sets `Build-loop policy: self-merge` and `Self-merge never: none`, or one the merge simply builds on.

This is introduced by the range: the sentence is new in ccc638d7. The fix is either to hold step 7's self-merge under the same block, or to narrow the sentence to "never feeds an answered merge or a loop".

**Evidence:** `skills/dev-cycle/SKILL.md:255-260`, `skills/dev-cycle/SKILL.md:489-501`, `scripts/build-loop.sh:19-20`

---

## Claim 7: "When this session's previous iteration stopped after committing (its branch not in main), merge that branch into WT first (as step 9 merges main in), so its entries and `Asked:` items land now and are not filed again … a conflict is a stop"

**Location:** `skills/dev-cycle/SKILL.md:263-266`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one stranded branch S, holding a record block, two new entries, an `Asked:` extension and an `Applied:` line, merged into a new WT after main moved by an unrelated commit, then landed. Does not establish:
- a conflicting merge;
- a stranded branch from another session, or two iterations back;
- a stop before the commit (whose edits `--force` removal discards, so they are re-derived; plan D13 line 105 needs no retry there);
- that step 7's dedupe by "an item on its `Asked:` line ends `@TIP`, or WT's questions files hold its merge entry's heading" (`:476-477`) runs as written. That part was read, not executed.

From `S/probe-land.out`:
- The merge exits 0.
- The record then holds three `Branch:` lines (`chore/dev-cycle-2026-10-13-0800`, `-0900` (S), `-0930` (WT)).
- `--cycle-diff` prints `ok` and `--land-cycle` prints `landed chore/dev-cycle-2026-10-13-0930 …`, with `is-ancestor HEAD main: yes`.
- `--main-log` reads the land as `chore … Merge branch 'chore/dev-cycle-2026-10-13-0930'`, because the record holds "Branch: B", anywhere in it (`scripts/build-loop.sh:162`). S's own `Branch:` line does not disturb this.
- S's entries read `open` on main, and the brief's line on main is `Asked: Q-001@abcdef1, Q-002@abcdef2`: each item added once.

This matches plan D13: "A failed land is retried before the next iteration's step 7" (`docs/working/plan-build-loop-handoff.md:105`).

**Evidence:** `skills/dev-cycle/SKILL.md:261-270`, `skills/dev-cycle/SKILL.md:673-675`, `scripts/build-loop.sh:157-162`, `docs/working/plan-build-loop-handoff.md:105`, `S/probe-land.out`

---

## Claim 8a: "cycle lands carry no code"

**Location:** `skills/dev-cycle/SKILL.md:301-302`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what `--cycle-diff`/`--land-cycle` let a chore land carry. Does not establish that the health check's result cannot change (Claim 8b).

The header says: "A path other than the cycle's own files, a .md under docs/ or README.md, compared lower-cased, refuses" (`scripts/build-loop.sh:214-216`; the gate's own code also refuses).

**Evidence:** `scripts/build-loop.sh:205-221`

---

## Claim 8b: the health check is skipped "when the previous iteration's `1.` line reads `passed at P` or `unchanged since P` and step 0.2 listed only `chore` lines (cycle lands carry no code; this iteration's line then reads `unchanged since P`)", i.e. a chore-only window leaves the health check's result as it was

**Location:** `skills/dev-cycle/SKILL.md:300-302`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the skip's stated rationale against claude-workflows' own health check, which the step names. Does not establish what other repos' health checks read, or whether an orchestrator also runs `questions.sh index` after filing. The skill never tells it to; step 1 runs `archive` (which reindexes) before steps 7 and 10 file entries.

claude-workflows' health check is not code-only. It gates the questions doc: "14. Running-questions doc: entry grammar, unique ids, index freshness (gate)" (`scripts/health-check.sh:53`), failing with `fail "questions doc: structure or index problems (see above)"` (`scripts/health-check.sh:1097`).

A chore land changes `docs/working/questions.md`. An entry filed after the index was regenerated leaves it stale. From `S/probe-quote.out`:

```
check after init+index: ok
  ✗ questions.md: index is stale — run: ~/.claude/scripts/questions.sh index
questions.sh check after filing an entry: exit 1
```

So a chore land can turn a passing health check into a failing one. The chained skip then records `unchanged since P` for as long as only chore lines move main.

This is pre-existing: the chore-only skip and its rationale came with b88e418a's C4 fix. The range's D6 rewrite extends it into an unbounded chain. In effect it is behavioural, but low-harm: the record misreports health, and the failure surfaces at the next real run.

**Evidence:** `skills/dev-cycle/SKILL.md:297-303`, `skills/dev-cycle/SKILL.md:310-315`, `scripts/health-check.sh:53`, `scripts/health-check.sh:1085-1097`, `scripts/questions.sh:296`, `S/probe-quote.out`

---

## Claim 9: "`--state` (from MAIN_WT, whose config the add copies), then `hg -C MAIN_WT worktree add --detach GT refs/heads/main`"

**Location:** `skills/dev-cycle/SKILL.md:490-492`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that git 2.39.5's `worktree add`, run in MAIN_WT, copies MAIN_WT's `config.worktree` into GT, and that `--state` from MAIN_WT refuses a key planted there while `--state` from WT does not. Does not establish an `include.path` in MAIN_WT's `config.worktree` (security final F2's untested candidate), or a planted GT admin directory.

From `S/probe-gt-state.out`: GT's `config.worktree` after the add holds `[filter "x"] smudge = touch …`. `--state` from MAIN_WT and from GT both print `refuse state filter.x.smudge: set in config.worktree, …` (exit 2). `--state` from WT prints `ok`.

**Evidence:** `skills/dev-cycle/SKILL.md:489-495`, `scripts/build-loop.sh:271-273`, `S/probe-gt-state.out`

---

## Claim 10: "An answer starting `[1]`, or that is `1` or `keep` (any case) alone or before punctuation or a dash, reads `keep`; likewise 2 or `drop`, 3 or `done`; anything else, `unrecognized` (a merge entry answered "merge" included …)"

**Location:** `skills/dev-cycle/SKILL.md:534-536`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the leading-token rule of `option()` on 22 answers. Does not establish where the answer line is found (the `Q-NNN:` or `**Answer` label rule), which the text does not restate.

`option()` accepts a narrower trailer than "punctuation or a dash":

```awk
# scripts/lib/dev-cycle-read.sh:2077-2079
  if (!(r == "" || r ~ /^[.,;:!)*]/ || (t != r && (t == "" || substr(t, 1, 1) == "-" \
      || substr(t, 1, 3) == "\342\200\224" || substr(t, 1, 3) == "\342\200\223"))))
    return "unrecognized"
```

(excerpt ends :2079; enclosing `option()` continues to :2083 — read). Only `. , ; : ! ) *` count as punctuation, and a dash counts only after a blank. From `S/probe-answers.out`:

- These read `keep`: `[1] merge it`, `1.`, `1, please`, `1 - yes`, `1 — yes`, `KEEP!`.
- These read `unrecognized`: `1?`, `keep (go)`, `keep-it`, `1 please`.
- `merge` reads `unrecognized`, and `[4]` reads `unrecognized`.

The precise wording is "alone, before `. , ; : ! )` or `*`, or before a blank and then a dash or the end". The sentence was reworded in the range (introduced). It is doc-only: `--check-answer` decides, and an unread answer is listed for the user.

**Evidence:** `scripts/lib/dev-cycle-read.sh:2070-2083`, `S/probe-answers.out`

---

## Claim 11: "Then run `--main-log MAIN` again: if it lists an `other` line after MAIN, or step 0.2's block holds, act on no answer this iteration"

**Location:** `skills/dev-cycle/SKILL.md:537-539`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the order (the `--check-answer` call at `:531-533`, then the re-read), which D3 asked for. Does not establish anything about the race between this re-read and `--merge --approved`'s own live read of main (deferred row, security F3).

The paragraph names `--check-answer` first ("one call with the IDs", `:531-533`) and then "Then run `--main-log MAIN` again" (`:537`), so every commit the answers came from is classified before they are acted on.

**Evidence:** `skills/dev-cycle/SKILL.md:531-539`

---

## Claim 12a: "A refusal of the paths, or a conflict, is filed as `stopped`" (merge entry `keep`)

**Location:** `skills/dev-cycle/SKILL.md:548-549`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that these two refusals exist under `--approved` with these texts. Does not establish the routing of the other refusals (Claim 12b).

`echo "refuse $a: $br conflicts with the default branch"` (`scripts/build-loop.sh:1368`) and `echo "refuse $a: $nd of ${#ps[@]} changed paths refused in the merge of $sha (tree $tree)"` (`scripts/build-loop.sh:1417`). As a control, `S/probe-approved.out` shows a `--merge --approved` at the entry's TIP printing `merged …` followed by `path` lines.

**Evidence:** `scripts/build-loop.sh:1364-1417`, `S/probe-approved.out`

---

## Claim 12b: "any other (MAIN_WT's state, no identity, a moved main) is retried next iteration, the ID left off `Applied:`"

**Location:** `skills/dev-cycle/SKILL.md:549-550`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim that every refusal outside paths and conflicts is environmental and clears on a retry. Does not establish how often a `ready` branch moves past its marker.

Under `--approved`, TIP is fixed: "TIP the full one the entry names, never the branch's live tip" (`:547-548`). `--expect` binds it: `if [[ -n "$EXPECT" && "$sha" != "$EXPECT" ]]; then echo "refuse $a: the tip of $br is $sha, not the expected $EXPECT"; return; fi` (`scripts/build-loop.sh:1364`). Once the branch moves past the entry's TIP, that refusal repeats in every iteration. From `S/probe-approved.out`:

```
refuse docs/working/briefs/2026-10-01-x.md: the tip of feat/x is adb77107…, not the expected fd2a66cc…
exit 2
```

Under this text the refusal is "retried next iteration, the ID left off `Applied:`" for ever. The answer is never applied, no entry is filed, and unlike step 7's self-merge environment refusals ("recorded, named in the final message", `:499-501`) nothing says it is recorded. Other refusals that never clear on a retry also fall here:
- a heading other than `merge-`/`merge-gate-STEM-SHA12`;
- an object that does not hash (`:1388`).

Before the range, every refusal was "filed as `stopped`", which covered these cases. So this is introduced by the range (D8). It is behavioural and fails closed, as a silent livelock of that answer.

**Evidence:** `skills/dev-cycle/SKILL.md:547-551`, `skills/dev-cycle/SKILL.md:499-501`, `scripts/build-loop.sh:1364`, `scripts/build-loop.sh:1388`, `scripts/build-loop.sh:2129-2131`, `S/probe-approved.out`

---

## Claim 13: "Add each ID acted on to the brief's `Applied:` line as `Q-NNN=ACTION` … so each answer is acted on once and the action survives a restart"

**Location:** `skills/dev-cycle/SKILL.md:553-556`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that no script judges or misreads an `Applied: Q-001=redispatch` line: `--cycle-diff`, `--land-cycle`, `--check-brief` and `--status` all pass, and `questions.sh` never reads briefs. Does not establish the orchestrator-side split. `--check-answer` takes the bare ID only: `skip Q-001=redispatch: not a question ID (Q- and digits)`. The text's "IDs … less those on its `Applied:` line" (`:532-533`) already implies the ID part.

`grep -rn Applied scripts/` finds nothing (paraphrased — no quote available because the claim covers absence of code: no matching grep results). `brief_fields` reads only `^(Status|Branch|Policy|Paths|Asked|Dispatched):` (`scripts/lib/dev-cycle-read.sh:448`). In `S/probe-land.out` a brief holding `Applied: Q-001=redispatch` gives:
- `--cycle-diff` `ok` and `landed …`;
- `ok … open f7045ef…` from `--check-brief`;
- `ok … open review feat/x absent - - 0` from `--status`.

`S/probe-answers.out` shows the `--check-answer` skip.

**Evidence:** `scripts/lib/dev-cycle-read.sh:426-448`, `S/probe-land.out`, `S/probe-answers.out`

---

## Claim 14: "Then land again as step 9 does (1 to 4): the briefs' `Dispatched:` lines, step 10's entries and the record's `9.` and `10.` lines; when step 10 dispatched and filed nothing, skip this land (those two lines join the next iteration's block)"

**Location:** `skills/dev-cycle/SKILL.md:703-705` (with the template's `9.` line at `:616`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the second land passes `--cycle-diff` and `--land-cycle` with the `9.`/`10.` lines inserted mid-block (between `8.` and `### Skipped inputs`, as the template orders them) and a `Dispatched: 1` line added. Also covers that the record still meets the chore record rule and that `--status` then reads DISPATCHED 1. Does not establish anything about the skipped-land path, which has no script contract: the next block simply carries the two lines.

From `S/probe-land.out`, second land: `--cycle-diff` `ok`, then `landed chore/dev-cycle-2026-10-13-0930 1c65ea3b…`, then `chore ed9474cd… Merge branch 'chore/dev-cycle-2026-10-13-0930'`, then `--status … - - 1`. BASE is the first land's HEAD, and the record still holds `Branch: B` "anywhere in it" (`scripts/build-loop.sh:162`).

**Evidence:** `skills/dev-cycle/SKILL.md:599-617`, `skills/dev-cycle/SKILL.md:703-709`, `scripts/build-loop.sh:157-162`, `S/probe-land.out`

---

## Claim 15: "A brief `--status` read with DISPATCHED 4 (the cap, D1) or more is never dispatched again"

**Location:** `skills/dev-cycle/SKILL.md:698`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cap's value and comparison in `dispatch()`. Does not establish anything about the capped entry's filing.

`DISPATCH_CAP=4; STEAL_AGE=7200` (`scripts/build-loop.sh:1595`) and `elif [[ "${STATUS[dispatched]}" -ge "$DISPATCH_CAP" ]]; then x="it was dispatched ${STATUS[dispatched]} times, and the cap is $DISPATCH_CAP"` (`scripts/build-loop.sh:1637`). DISPATCHED ranges 0-99 (`scripts/build-loop.sh:87`).

**Evidence:** `scripts/build-loop.sh:87`, `scripts/build-loop.sh:1595`, `scripts/build-loop.sh:1628-1640`

---

## Claim 16: Commit ccc638d7's message, "D1 … D10" and the Consider/override lines

**Location:** commit `ccc638d7` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each listed change is present in the diff as described:
- D1 hold (`:256-260`);
- D2 `--state` from MAIN_WT with `config.worktree` copied (executed, Claim 9);
- D3 order (Claim 11);
- D5 quoting (`:63-64`);
- D6 chained `1.` line (`:300-302`, `:609`);
- D7 `Q-NNN=ACTION` (`:553-556`);
- D8 retry (`:549-550`);
- D9 stranded merge (executed, Claim 7);
- D10 count (`:319-321`);
- "cap 'or more'" (`:698`);
- the plan note and 6 override rows (the diff adds exactly 6 rows, naming security F3's dispatch half, F4, architecture 3 with api-consistency 9, architecture 7, architecture 8, and performance F5).

Does not establish that each fix is complete or correct. Claims 1, 4, 6 and 12b record where it is not.

**Evidence:** `git show ccc638d7`, `docs/reviews/override-log.md:801-806`, `S/probe-gt-state.out`, `S/probe-land.out`

---

## Claim 17: Plan U4b2 as-built note: "answers and dispatch are held while `--main-log MAIN` shows an unclassified `other` commit or an `other-commit-SHA12` entry is open … lands a second time when it dispatched or filed anything; a stranded chore branch is merged into the next iteration's WT (D13's retry)"

**Location:** `docs/working/plan-build-loop-handoff.md:343`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement of the note's added clauses with SKILL.md after the range. Does not establish the note's earlier clauses, which were reviewed in earlier passes.

The note matches `:256-260` and `:537-539` (answers and dispatch only; unlike Claim 6, it claims nothing about merges), `:703-705` and `:263-266`.

**Evidence:** `docs/working/plan-build-loop-handoff.md:343`, `skills/dev-cycle/SKILL.md:255-266`, `skills/dev-cycle/SKILL.md:703-705`

---

## Claims Requiring Attention

### Incorrect
- **Claim 6** (`skills/dev-cycle/SKILL.md:260`): "never feeds a merge" is false. Step 7's self-merge of a `ready` brief carries no `other` hold, and `--merge` reads main, including the unseen commit, live. Introduced by the range. Behavioural, High. Hold self-merges under the block, or narrow the sentence.
- **Claim 8b** (`skills/dev-cycle/SKILL.md:300-302`): a chore-only window can change claude-workflows' health check (it gates `questions.sh check`'s index freshness, and a land filing entries leaves the index stale; executed). The chained skip records `unchanged since P` regardless. Pre-existing (b88e418a's C4), extended by the range's chain. Behavioural, Medium.
- **Claim 12b** (`skills/dev-cycle/SKILL.md:549-550`): an approved merge's "any other" refusal is not always environmental. "the tip of BR is X, not the expected TIP" (branch moved past the entry's TIP; executed) and a heading mismatch never clear, so they are retried for ever with the ID never applied and nothing filed. Introduced by the range (D8). Behavioural, High. It fails closed.

### Stale
- **Claim 1** (`skills/dev-cycle/SKILL.md:47-49`): the Rules' exception list does not name step 7's pre-GT `--state` from MAIN_WT, so following the Rules runs it from WT, the location D2 fixed (executed: WT's `--state` passes a MAIN_WT `config.worktree` filter). Introduced by the range. Behavioural, High.

### Mostly Accurate
- **Claim 3** (`skills/dev-cycle/SKILL.md:62-63`): `other` lines now also hold answers, while their entry is open. Introduced. Doc-only.
- **Claim 4** (`skills/dev-cycle/SKILL.md:62-64`): `> `-quoting with the comment opener replaced still leaves a pasted line starting `[` (holding `]:` or left open), or one holding a CR, making `--check-answer` refuse the whole file (executed). Introduced. Behavioural, but it fails closed (stalls lands).
- **Claim 10** (`skills/dev-cycle/SKILL.md:534-536`): "punctuation" is only `. , ; : ! ) *`, and a dash counts only after a blank (`1?`, `keep (go)` and `keep-it` read unrecognized; executed). Introduced (reworded). Doc-only.

### Unverifiable
- None.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A code-fact-check report saved at the given path, every checkable claim in the range verdicted with evidence"
- **Answered:** yes. The report is saved at `docs/reviews/code-fact-check-report-2026-10-13-u4b2-confirm.md` in the worktree, with header `**Replication:** k=1 (confirming pass)` and `**Commit:** ccc638d7`. Its 19 claims cover every script-checkable statement the range adds or rewrites in `skills/dev-cycle/SKILL.md`, plus commit ccc638d7's message and the plan note. Each carries the seven mandatory fields plus Legibility-target, and each non-Verified claim is labelled introduced-by-range or pre-existing. Six probes ran in throwaway fixture repos under `/tmp/u4b2rv-fc-*`, with provenance in the table above.
- **Out of scope / not verdicted:** range text with no script contract was not verdicted:
  - step 1's merged-branch count;
  - the wait rule's NEW;
  - step 8's queue-count wording;
  - step 9's "any other refusal is a stop";
  - the record's reading list;
  - "Unmerged `chore/dev-cycle-*` branches are named in the final message".
  The new bats test named in the shared brief is outside `b88e418a..ccc638d7` (the range touches no test file) and was not re-checked.
- **Static only:** Claims 3, 6, 8a, 11, 15 and 17.
- **Escalate:**
  - Claim 6, a Medium the range introduced: the D1 guarantee is overstated, and self-merge runs under an open `other` block.
  - Claim 12b, a behavioural Incorrect introduced by D8.
  - Claim 1, a Rules/step contradiction of the B2 kind that recreates security F2 if followed.
  Per the rubric's iteration-4 gate, "a new Must Fix, or a Medium the range introduced, stops it and goes to the user".
- **Decisions I made:**
  - Verdicted Claim 8b on claude-workflows' own health check, because the step names it.
  - Treated the D5 quoting rule's purpose as stated by step 7's REASON sentence ("since `--check-answer` would then refuse the whole questions file").
  - Did not edit the hallucination-pattern log: no fabrications, and the brief allows writing only this file.
