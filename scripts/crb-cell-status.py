#!/usr/bin/env python3
"""Decide whether a review cell's result.json counts as COMPLETE.

Exit 0 = complete (run-host.sh skips the cell); exit 1 = incomplete (re-run).
The reason is printed on stdout either way, so the runner can put it in the log.

Extracted from run-host.sh so the predicate has fixtures. It is the arm's
resume/retry gate: a false "complete" banks a failed cell and locks it out of
retry, while a false "incomplete" re-pays $10-40 for a review that already
succeeded and, after MAX_ATTEMPTS, drops the PR out of the judged subset
entirely. The false-COMPLETE direction has already happened in this repo's
arms (e7's turns-only predicate banked a budget-exhausted cell); the
false-incomplete direction is a projected risk, not yet an observed one --
e5-cc-builtin's runner had no resume predicate at all, so its eight
num_turns == 0 reviews were never re-paid. Both directions are cheap to get
wrong, which is why the rules below are keyed to measured artifacts rather than
to intuition.

Measured against the 32 result.json files under runs/review-arms/ (see
test/crb-cell-status.bats, which asserts this script's verdict on all of them):

  * is_error / subtype catch real budget exhaustion
    (e7-fable-3x/mfc-hygiene/rep1: subtype=error_max_budget_usd, $15.24) — a
    turns-only predicate banked exactly that one and locked it out of retry;
  * 8 e5-cc-builtin cells are genuine successes with num_turns == 0 and
    2.7-7.1 KB of real review text, so requiring turns > 0 re-pays for
    finished work;
  * 2 e7 cells report subtype=success, is_error=false, num_turns=0 with a 51-56
    char body that is actually a quota stub -- one weekly limit (56 chars),
    one session limit (51 chars).

So: trust subtype/is_error, then look at what came out.
"""

import json
import sys

# Bodies that returned cleanly without reviewing anything. Every one of these is
# a short CLI stub, not review prose: the two in-repo examples are 51 and 56
# characters. The substrings are therefore only meaningful on a SHORT body —
# "logged in" is ordinary prose in a review of auth code, and two of the five
# pilot instances are auth-domain (keycloak-PR36880, "Add Client resource type
# and scopes to authorization schema"; cal_com-PR11059, "OAuth credential sync").
# Applying these to a multi-KB body would reject a good review of exactly the
# PRs the benchmark cares most about. The 32-file corpus that validated this
# predicate contains no auth-domain reviews, so it could not have caught that.
NON_REVIEW = ("log in", "logged in", "hit your weekly limit",
              "hit your session limit", "limit · resets", "limit - resets")
# Above this length a body is a review, not a stub, and NON_REVIEW no longer
# applies. Measured on the 32-cell corpus, NOT estimated: the two stubs are 51
# and 56 chars; the SHORTEST REAL REVIEW IS 1,208 chars, and 20 of the 32 bodies
# sit between 1.2 and 3.0 KB. 300 therefore clears the stubs by ~5x and the
# shortest real review by ~4x, roughly centred in the empty band.
#
# This was 1000 in cf6e7c9, justified by a claim that the shortest real review
# was "over 3 KB" — a value that appears nowhere in the corpus. All three k=3
# fact-check replicates caught it independently (logged to
# docs/reviews/hallucination-patterns.md). At 1000 the real-review margin was
# ~20%, i.e. one short review away from re-introducing the very failure this
# file exists to prevent: rejecting a genuine review of auth code because it
# says "logged in". Do not raise this without re-measuring the corpus minimum.
STUB_MAX_LEN = 300
# A real review runs to kilobytes. This floor is what actually rejects both
# stubs in the corpus (51 and 56 chars) — NON_REVIEW is never consulted for
# them. The substring list therefore only governs the 200-300 char band: a stub
# wordier than the two we have seen. Keeping both rules is deliberate (neither
# is load-bearing alone), but the division of labour is asserted in
# test/crb-cell-status.bats so it cannot drift unnoticed.
MIN_REVIEW_LEN = 200


def status(d):
    """(complete: bool, reason: str)"""
    if d.get("is_error"):
        return False, f"is_error=true subtype={d.get('subtype')!r}"
    subtype = d.get("subtype", "success")
    if subtype != "success":
        return False, f"subtype={subtype!r}"
    r = (d.get("result") or "").strip()
    if len(r) < MIN_REVIEW_LEN:
        return False, f"body is {len(r)} chars, under the {MIN_REVIEW_LEN}-char floor"
    if len(r) < STUB_MAX_LEN:
        low = r.lower()
        hit = next((s for s in NON_REVIEW if s in low), None)
        if hit:
            return False, f"short body ({len(r)} chars) matching a non-review stub: {hit!r}"
    return True, f"complete — {len(r)} char body, subtype={subtype}"


def main(argv):
    if len(argv) != 2:
        sys.exit("usage: crb-cell-status.py <result.json>")
    try:
        d = json.load(open(argv[1]))
    except Exception as e:
        print(f"unreadable result.json ({e})")
        return 1
    if not isinstance(d, dict):
        print("result.json is not an object")
        return 1
    ok, reason = status(d)
    print(reason)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
