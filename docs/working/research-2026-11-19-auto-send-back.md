# Research: auto send-back of a gate-refused ready branch

Brief: `docs/working/briefs/2026-11-19-auto-send-back.md` (at a0ef9528c154). Policy: review. Branch: `fix/auto-send-back`.

Specification: `docs/working/research-2026-11-19-generated-file-conflicts.md`, its `## For the dev cycle` section (candidate 5, chosen on Path A there). This doc records the build and its pre-mortem; it does not reopen the decision.

Workflow: research-plan-implement, no plan gate; then pr-prep's Step 0 advisory and review-fix loop.

## What the code does on this base

- `skills/dev-cycle/SKILL.md` step 7 opens (lines 697-704 here; the spec cites 699-704, the same clause) with the "already asked about at TIP" rule: a brief whose `Asked:` item ends `@TIP`, or whose merge entry's heading is in the questions files, has only its answers read, and when the last applied item is `Q-NNN=redispatch` step 10 re-dispatches it.
- The three "filed as `stopped`" sentences are at the self-merge `ready` bullet (conflict and gap refusals), the review `ready` bullet (`refuse` verdict) and the approved-merge answer bullet ("any other refusal").
- Step 10's dispatch bullet appends "Answered for you: ..." for a send-back. The `--steal --ended` text that changed at 8ec5a900 is untouched.
- No script parses `Applied:` (`rg -n Applied scripts` prints nothing), and `--cycle-diff` judges only `Asked:` lines, so a new `Applied:` item needs no gate-script change.
- Gap texts (`scripts/build-loop.sh` `fp_gaps`, lines 1511-1563): missing grep line, research doc not in the tip or not a regular file, duplicate FP number ("renumber the branch's entry"), fix commits with no entry and no skip line: all loop-fixable. Owner remedy: the `failure-patterns-out-of-thoughts` migration gap. Failed reads: "could not be read", "listed", "compared".

## Gotchas

Failure-pattern grep: FP-012
- FP-012 (stale-merge-head-poisons-next-merge) is the only prior pattern on merges; the change adds no merge site and reuses the dispatch prompt's merge-in, whose `git merge --abort` on a stop stays as it is. A grep of `docs/failure-patterns.md` for redispatch, re-dispatch, send back, sent back and once per tip matched nothing.

## Design notes (no 3-option choice here; the spec decided)

- Where the rule sits: one `**Auto send-back**` paragraph after step 7's opening clause, which each of the three stopped sentences points to with "but for an auto send-back (above)". One source for the rule (S3) instead of restating it three times.
- The once-per-tip check is the amended opening clause, as the spec says: an `Applied:` redispatch item for TIP (auto or Q-ID, TIP12 a prefix of TIP) counts as sent back, so the gate is not re-run at that tip.
- The refusal line for step 10's "Sent back for you" line comes from the `7.` record line that recorded the send-back, so a dispatch deferred to a later iteration still has it. The record template's `7.` line ("what was done") already covers it: no template change, so no `scripts/lib/migrations.sh` registry line.
- Step 7's `Applied:` grammar paragraph names the `auto@TIP12=redispatch` item, which holds no ID for `--check-answer`.

## Pre-mortem (gate code: what the cycle can now do without the owner)

1. **Burn the dispatch cap on a fast-moving main.** Each new tip refused for a conflict is sent back once. Bounded by: only while DISPATCHED is under 3, so the owner still gets a stopped entry with a real re-dispatch under the cap of 4.
2. **Loop on one tip.** A sent-back loop that ends with no new commit is re-dispatched each iteration by the opening clause, until the cap files its `capped-` entry. Same as an owner `Q-NNN=redispatch` today, so no regression; bounded by the cap of 4.
3. **A loop silences a gap.** Sending a gap back could invite a `Failure-pattern skip:` line where an entry was due. Bounded by: the owner-remedy migration gap and failed reads keep the stopped route; for the rest, a skip line is a remedy the gate already accepts from a first dispatch, so nothing new is allowed.
4. **An approval read where none was given.** No answer line is written or inferred; `Q-NNN=redispatch` on an approved merge replaces `noted`, and the new tip needs its own `merge[-gate]-STEM-TIP12` entry (D8, `approval()` unchanged). Bounded by the gate's full re-check at the new tip.
5. **A conflict that means the brief is obsolete.** The loop's own stop rule (cannot merge without discarding a side: `git merge --abort`, `handoff: stopped`) files a stopped marker as today. Residual: a resolution into an empty change ends ready; self-merge lands an empty merge (harmless), review shows an empty merge entry.
6. **Hidden from the owner.** The final message lists each auto send-back with its brief and refusal line (S10).

Bypass families for the prose rule (it is gate code read by the orchestrator, not a script): a misread prefix match (TIP12 against a different tip) can only skip a send-back or file a stopped entry, both today's behaviour; a misread DISPATCHED is bounded by step 10's hard cap of 4, which `--status` enforces.

## Verification

- `test/scripts/build-loop-orchestrator.bats`: new `sect` pin (step 7: TIP rule, under-3 bound, owner-remedy and failed-read exclusion, the three exceptions; step 10: the send-back line and the final message). 52/52 pass.
- `test/scripts/convention-migrations.bats` passes (no template change); `build-loop-free.bats`, `build-loop-check.bats`, `questions-doc.bats` (the other readers of the skill) pass; `scripts/hermeticity-lint --root .` passes.

## Review log

See `docs/reviews/code-review-2026-11-19-auto-send-back.md`.
