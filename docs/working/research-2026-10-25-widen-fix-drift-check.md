# Research: widen the fix-drift lite check to prose a fix adds

Brief: `docs/working/briefs/2026-10-25-widen-fix-drift-check.md` (at d40e4bae).
Branch: `feat/widen-fix-drift-check`. Mode: build loop, no plan gate.

## What exists

- `workflows/review-fix-loop.md` § Fix-commit drift check (lite) owns the rule;
  `workflows/pr-prep.md` step 3c restates the command and defers to it.
- The check is `scripts/lite-review.py --mode fix-drift`: one headless Haiku call, no
  tools, diff only. Its behaviour is set by `PROMPT_FIX_DRIFT`, which reports only
  (a) prose the fix made stale relative to the changed code and (b) new or edited prose
  making claims "the code does not satisfy". Nothing in the workflow text adds scope
  on its own: whatever the workflow says the check covers, the prompt is what runs.
- No test pins `PROMPT_FIX_DRIFT`; `test/lite-review-grammar.bats` pins only the
  FINDINGS accept spec (`parse_findings`). `test/workflow-required-sections.bats`,
  `test/agents-gemini-sync.bats` and `test/morning-summary-clusters.bats` mention the
  two workflows; none pins the drift-check paragraph.
- `scripts/lite-review.py` is not an enforcement file (`hooks/live-verify-gate.sh`'s
  set is `devcontainer-config/...`), so no `Live-verified:` trailer is needed.

## The miss (why T4 fired)

258f9ec4 (fix for B3) added to `guides/devcontainer-setup.md`: cached-layer reuse holds
"until something above it in the Dockerfile changes (the base image, the apt list, a
toolchain version, `TZ`, or a pruned build cache)". The lite check on
9e0ff1a5..258f9ec4 printed FINDINGS: NONE; the next full pass found D1: elan and Lean
sit *below* the install layer (`Dockerfile:451-454`) and a pruned cache is not a
Dockerfile input. The claim is about a file the diff does not show. The current prompt
asks for prose claims "the code does not satisfy", which a diff-only model reads as
"the code in this diff"; it had nothing to contradict the guide with, so it reported
nothing. A prompt that only says "fact-check added prose" would still not have caught
D1 from the diff alone: the model cannot see the Dockerfile.

## Constraints in play

H2 (nothing present-but-inert), H3 (hermetic tests for a behavioural change), H4 (LLM
judgment is a detector; the lite check blocks nothing, its findings go to the loop
agent), S2 (no new mandatory dispatch per pass), S3 (reuse the existing lite call),
S4/S6 (the behaviour lives in the tested script, with a real call site: pr-prep 3c),
S5 (the motive is a real miss, and the user chose [2] on Q-194), S7 (cost note honest),
S8 (small, one revert). Brief: workflow text says the check fact-checks prose the fix
adds or changes, same lite pass, findings handled as the others; 031 dated amendment;
"no other workflow or skill changes".

## Divergent design

| # | Option | Verdict |
|---|---|---|
| A | Workflow text only; prompt unchanged | Fails H2: the docs would claim a check the script does not run (itself the drift class this check exists for). Pruned. |
| B | Widen `PROMPT_FIX_DRIFT`: report factual errors in prose the diff adds or changes, judged from the diff and general knowledge | Honours the brief; does not catch a D1-shaped claim about an unshown file, so T4 would likely fire again on the same class. |
| C | B, plus: a specific claim about material the diff does not show (another file's contents or order, a line number, what a list includes, a tool's behaviour) that the diff does not support is reported as a Low "unverified claim" naming what to check and where; the loop agent checks it with its tools and corrects it if wrong | Catches D1's shape (the guide states Dockerfile layer order the diff does not show, so it is flagged and the agent reads `Dockerfile`). Same single call (S2/S3). Cost: more findings on docs-heavy loops, each a quick lookup, which is exactly Q-194 [2]'s "if it's wrong" column. |
| D | Script reads files the added prose names and inlines them | Parses paths out of untrusted prose (trust boundary), grows the script, unbounded prompt size; S8/S1 cost far above the gain. Pruned. |
| E | Loop agent runs a narrow code-fact-check on added prose each iteration | A new agent dispatch per iteration (S2), and not "in the same lite pass" as the brief requires. Pruned. |

**Decision: C** (dominates B on the motive, the only cost axis is the one the user
already accepted with [2]). Path A of the dispatch rules: decide and continue.

Brief tension, resolved: "The doc change is the change itself; no other workflow or
skill changes." The script is neither a workflow nor a skill, and without its prompt
change the doc change would be inert (option A). The script edit is the minimum that
makes the doc true; recorded here and in the commit body.

Decision-log row: 031's one earlier amendment (2026-09-28) is a header bullet that cites
the log row recording the change (log row 63), and L's original implementation also got
a log row (2026-08-20). So 031's convention is header bullet plus log row; one row is
added (row 77).

## Plan

1. `scripts/lite-review.py`: add the third report bullet (option C) to
   `PROMPT_FIX_DRIFT`; update the module docstring's `--mode fix-drift` line.
2. New `test/lite-review-fix-drift-prompt.bats`: run the script end to end against a
   temp git repo with a strict PATH-stub `claude` that records its stdin and refuses
   unexpected argv (`--bare` included); assert the fix-drift prompt carries the prose
   fact-check and unverified-claim clauses and the full mode does not.
3. `workflows/review-fix-loop.md` § Fix-commit drift check: scope now covers prose the
   fix adds or changes; how an unverified-claim finding is "fixed"; honest cost note.
   `workflows/pr-prep.md` 3c: one clause restating the widened scope.
4. `docs/decisions/031-...md`: dated amendment bullet in the header and a dated note
   under the T4 trigger (original text untouched). `docs/decisions/log.md`: row 77.
5. Tests: the new file, `lite-review-grammar.bats`, the files naming the two workflows,
   then the health check. Review-fix loop (code-review). Final change sets the brief's
   Status to done.

## Observable (S6)

Positive: a lite-check finding in prose a fix added that turns out wrong (it would have
cost a full pass). Negative: T4 fires again (a full pass catches fix-added prose the
widened check passed), or unverified-claim findings almost always check out (noise to
narrow). T4 stays as the trigger for the first; the second is noted in the amendment.
