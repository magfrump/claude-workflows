# INVALID CELL — reviewed the wrong diff

This 2026-08-19 cell reviewed `refs/pull/1/head` of the fork, which was a
Dependabot PR ("Bump manusa/actions-setup-minikube from 2.13.1 to 2.16.1",
head f09d73d) — NOT the benchmark's reviewed change. Dependabot is enabled on
the `code-review-benchmark` org and opened 228 bump PRs on this fork at
fork-creation time (2026-03-11), claiming PR #1 before/instead of the
benchmark's own PR.

The actual reviewed change for keycloak PR 36880 ("Add Client resource type
and scopes to authorization schema") lives on the fork branch `pr-36880`,
head 1950a511026d520a7329c7b6b9ee60a4af8f8b55 (10 files, +866/-138).

Consequences:
- `review.md` / `result.json` / `artifacts/` here are a review of the wrong
  3-line diff and CANNOT be scored against the 5 golden comments.
- Root cause fixed 2026-08-20 in `scripts/crb-materialize.py`: the review ref
  is now the fork's `pr-<upstream-number>` branch, with refs/pull/1/head only
  as an explicit, warned fallback.
- The clone + baseline for keycloak-PR36880 were re-materialized (`--force`);
  `runs/review-arms/crb/instances.json` now records the correct head/base.
- Audit of the other 4 pilot instances (cal_com-PR11059, discourse-graphite-PR4,
  grafana-PR79265, sentry-greptile-PR5): recorded head == fork `pr-<n>` branch
  == refs/pull/1/head, so only this cell is affected.

Re-run this cell against the rebuilt baseline before using its numbers.
