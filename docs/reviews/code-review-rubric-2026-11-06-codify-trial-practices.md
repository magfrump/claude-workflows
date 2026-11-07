Commit: 4873ac59

# Code review rubric: feat/codify-trial-practices

Status: 0 red, 0 amber open. Single-sample review; absence of findings is not an attestation.

Scope: `c14c9c08..HEAD`, delivery mode self-read. Override log: searched by keyword (`skills/dev-cycle`, `writable`, `weekly`, `batched`, `dev-cycle-read`), not read row by row. No prior overrides matched this diff: the hits concern other functions and older wording of step 0.1.

## Coverage

- Pass 1 (63900c21, then 00f6d2ea): code-fact-check at k=1, security-reviewer, api-consistency-reviewer with a short performance read.
- Pass 2 (1be9fdca): one opus reader across the full branch, as fact-check, security and consistency.
- Pass 3 (4873ac59): a delta review of the last fix commit.
- Departures from `code-review`: the confirming pass ran at k=1, not k=3, and as one reader, not the full panel; architecture-review was not dispatched (one predicate added inside an existing module). The change is prose plus about ten code lines, and pass 2's mutation run killed every code mutant. Critic reports stayed in the session's scratch directory.

## Findings

| ID | Source | Tier | Finding | Status |
|---|---|---|---|---|
| A1 | fact-check | amber | `docs/dev-cycle.md` update wrongly left "for the cycle", which cannot write it | fixed in the research doc; 00f6d2ea's body corrects 63900c21's Notes line; marker names the owner |
| A2 | fact-check | amber | N-rule header omitted weekly digests | fixed |
| A3 | fact-check | amber | F58's "lists every commit" amended with no record | fixed: log row 85 |
| A4 | security | amber | the block route dropped the "must name the ID" bound; a bare "merge" fit | fixed: unconditional instruction, the orchestrator's own last block |
| A5 | security | amber | an entry outside the batch could merge (race, range past the block) | fixed: only entries that block listed, never a later one; the record names each |
| A6 | security | amber | "one paste for every host command" opened the host paste to a set the orchestrator picks | fixed: the one fixed paste |
| A7 | consistency | amber | the digest's security count had no durable source | fixed: named sources, and the limit stated |
| A8 | consistency | amber | the If-you-say-no position disagreed with step 0.1's and step 7's sequences | fixed |
| A9 | confirming pass | amber | the design pointer led only to a doc the batch contradicts | fixed: pointer and log row 85 |
| A10 | confirming pass | amber | `refuse state` is often filed as an agent item, and a stop's filing can be discarded | fixed |

## Consider, not fixed

- Step 3's stop list in step 9 does not name a `refuse state` line from `--cycle-diff`. Pre-existing, and outside this brief.
- A hand commit has no slot in the release notes; the paths line and the log command still expose it.
- Prose pins cover the load-bearing strings, not every clause (pass 2's mutants: 13 of 22 prose mutants survived before more pins were added).

## Composition check

No multi-source co-located clusters beyond A4 and A5, which share step 9.3 and are fixed by one sentence.
