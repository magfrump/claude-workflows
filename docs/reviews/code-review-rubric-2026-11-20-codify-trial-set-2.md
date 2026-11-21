Commit: 6552a394

# Code review rubric: feat/codify-trial-set-2

Status: 0 red, 0 amber open. Single-sample review; absence of findings is not an attestation.

Scope: `b7663bf2..HEAD`, delivery mode self-read. The diff is skill prose, one bats test and two working docs; no script or gate code changes.

## Coverage

- Pass 1 (07266f2d): one fresh general-purpose reader as fact-check, consistency and test-armedness (it swapped in the old `SKILL.md` and saw the new test fail).
- Pass 2 (9dd371e0): a fresh reader across the full branch; clean but for one optional amber. It ran four mutations of `SKILL.md`, and each failed the new test.
- 6552a394 applied pass 2's amber (one clause) and the brief's status; self-read, pins rerun.
- Departures from `code-review`: one reader per pass, not the full panel; security, performance and architecture critics were not dispatched, since nothing reads input, runs or computes a path. Reports stayed in the session's scratch directory.

## Findings

| ID | Source | Tier | Finding | Status |
|---|---|---|---|---|
| A1 | pass 1 | amber | `docs/audiences/owner.md:40` still says "at most two links" | not fixed: the owner's ratified profile (0e95e3f2); left for the cycle to raise, named in the marker |
| A2 | pass 1 | amber | "end it with the links" clashed with the Wait paragraph's closing line | fixed: links come ahead of any closing instruction |
| A3 | pass 1 | amber | the look's count had no reply form to count | fixed: `look: fine` named |
| A4 | pass 1 | amber | "earlier looks" had no window | fixed: those offered in past editions |
| A5 | pass 1 | amber | the design-pick pool was narrow, with no empty-pool rule | fixed: adds `docs/decisions/`; none falls back to a self-merge |
| A6 | pass 1 | amber | T12 checkable facts may not be the owner's "numbers I've seen" | not fixed: follows the brief's criterion 4; residual recorded in the research doc |
| A7 | pass 2 | amber | past editions' `sample: fine` replies would not count | fixed (6552a394) |

## Consider, not fixed

- Prose pins cover the load-bearing strings, not every clause.
