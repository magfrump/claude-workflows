#!/usr/bin/env bash
# shellcheck disable=SC2034  # Arrays are used by test files that source this file
# Machine-parseable expected verdicts for what-if-analysis fixtures.
# Used by health-check to validate fixture ↔ verdict coverage.
#
# what-if-analysis has no Verdict or Severity line. Its graded vocabulary is:
#   - "**If wrong:** tweak | redesign | full retreat" on each assumption in
#     Assumptions Examined (move #1);
#   - the Findings Summary tags [UNEXAMINED ASSUMPTION], [SECOND-ORDER EFFECT],
#     [HIDDEN COUPLING], [REVERSIBILITY CLIFF], [SUCCESS COST],
#     [PRIOR CONSIDERATION].
# SKILL.md lays the assumption fields out as a bullet list, so reports write
# "- **If wrong:** redesign". field_match reads only lines that START with
# "**If wrong:**", so it would miss them; the If-wrong grade is checked with a
# cites_pattern that allows any line prefix instead.
# Each planted fixture aims at ONE cognitive move; EXPECTED_VERDICT names the
# move (documentation only — no check reads it). The flaw-specific
# cites_pattern is the real signal. Where a pattern anchors on a tag, it also
# requires a fixture-specific fact within the same line, so the tag alone
# never passes.
#
# Check formats used here (separated by ;; — so no pattern may contain ";"):
#   cites_pattern:<ERE>        — report matches <ERE> (case-insensitive, per line)
#   no_pattern:<ERE>           — report never matches <ERE>
#   format_check               — what-if-analysis-format.bats passes
#
# The negative (tc-wi6) is a small flag-guarded change with a rehearsed
# rollback. Its worst grade is a [REVERSIBILITY CLIFF] finding, so it forbids
# any Findings Summary list item or table row carrying that tag. The regex
# matches the tag only at the head of a list item or inside a table row, so a
# sentence like "no [REVERSIBILITY CLIFF] findings" in prose does not trip it.

declare -gA EXPECTED_VERDICT
declare -gA CLAIM_ACCURACY
declare -gA KEY_CHECK

# --- Planted flaws, one move each ---

EXPECTED_VERDICT["tc-wi1-order-events-queue.md"]="load-bearing assumption"
CLAIM_ACCURACY["tc-wi1-order-events-queue.md"]="flaw"  # Move 1/4: "every consumer is idempotent" stated as fact to justify at-least-once with no dedup, yet loyalty-accrual adds points and invoice-mailer sends email — a replay double-credits / double-sends
KEY_CHECK["tc-wi1-order-events-queue.md"]="cites_pattern:\\*\\*If wrong:\\*\\*[[:space:]]*[*_]*(redesign|full retreat);;cites_pattern:(loyalty|points|accrual|balance).{0,150}(twice|double|duplicat|again|re-?appl|inflat|over-?credit|not idempotent|non-idempotent)|(twice|double|duplicat|not idempotent|non-idempotent).{0,150}(loyalty|points|accrual|balance|receipt|email|pick ticket)|idempoten.{0,150}(assert|unverified|not (been )?(verified|tested|checked)|untested|no evidence|taken on faith|by fiat)|(unverified|untested|no evidence).{0,150}idempoten;;format_check"

EXPECTED_VERDICT["tc-wi2-ticket-auto-close.md"]="second-order effect"
CLAIM_ACCURACY["tc-wi2-ticket-auto-close.md"]="flaw"  # Move 2: the 39% of customers who reply on day 3-7 now find the ticket closed and contact again, creating fresh/duplicate tickets — the model claims auto-closed and total volume unchanged, and the metrics improve while the work moves
KEY_CHECK["tc-wi2-ticket-auto-close.md"]="cites_pattern:(new|fresh|second|duplicate|another|follow.?up) (ticket|request|conversation|case)|re-?open|re-?contact|contact (us )?again.{0,150}(new|duplicate|volume|count|inflat|lost|context|history)|(day 3|39 ?%|day.3.to.day.7|3.7 days).{0,200}(closed|lose|lost|new|again)|(metric|backlog|resolution time).{0,150}(gam|mask|hide|artifact|illusion|cosmetic|shift)"

EXPECTED_VERDICT["tc-wi3-settlement-batch-schedule.md"]="hidden coupling"
CLAIM_ACCURACY["tc-wi3-settlement-batch-schedule.md"]="flaw"  # Move 3: warehouse-sync at 02:15 copies merchant_settlement — at 01:00 settlement finished before it, at 03:00 the copy runs first and ships the previous day's or incomplete data. Listed in the Environment table, never connected
KEY_CHECK["tc-wi3-settlement-batch-schedule.md"]="cites_pattern:(warehouse.?sync|02:15|2:15).{0,250}(before|ahead of|stale|previous|prior day|yesterday|incomplete|partial|empty|race|out of order|no longer|finish|complet|ordering|dependen|misses)|(before|stale|previous|yesterday|incomplete|partial|empty|race|ordering).{0,250}(warehouse.?sync|02:15|2:15)|finance warehouse.{0,200}(stale|previous|yesterday|incomplete|partial|empty|miss|day behind|one day)"

EXPECTED_VERDICT["tc-wi4-password-hash-upgrade.md"]="reversibility cliff"
CLAIM_ACCURACY["tc-wi4-password-hash-upgrade.md"]="flaw"  # Move 6: "rollback is instant and complete" — but each upgrade overwrites the bcrypt hash in place, so redeploying the pre-work release (bcrypt only) locks out every upgraded account; the gradient steepens with each login
KEY_CHECK["tc-wi4-password-hash-upgrade.md"]="cites_pattern:(overwrit|replac|destroy|discard|lost|gone|no longer (have|exist|stored|available)|irrecoverabl|unrecoverabl).{0,150}(bcrypt|old hash|original hash|previous hash)|(bcrypt|old hash|original hash|previous hash).{0,150}(overwrit|replac|destroy|discard|lost|gone|irrecoverabl|unrecoverabl|no longer)|(previous|prior|old|earlier) (release|version|build|code).{0,200}(can.?t|cannot|unable to|fail|won.?t|does not|doesn.?t).{0,60}(verif|read|pars|recogni|authenticat|log)|lock(ed|s)? out|one.way;;cites_pattern:\[REVERSIBILITY CLIFF\].{0,300}(bcrypt|argon|hash|redeploy|previous release|rollback|roll back|login|log in);;format_check"

EXPECTED_VERDICT["tc-wi5-free-tier-launch.md"]="success cost"
CLAIM_ACCURACY["tc-wi5-free-tier-launch.md"]="flaw"  # Move 7: Solo users get the same Contact us button; 4 agents handle 900 conversations/month from 2,100 accounts (~0.43 each), and the goal is 40,000 Solo accounts — success multiplies support volume, which the plan never costs
KEY_CHECK["tc-wi5-free-tier-launch.md"]="cites_pattern:(support|agents?|tickets?|conversations|contact us|first.response).{0,200}(40,?000|solo|free.tier|free users|free accounts|19x|20x|volume|overwhelm|swamp|flood|drown|scale|multipl|surge|backlog|hire|staff)|(40,?000|solo|free.tier|free users|free accounts).{0,200}(support|agents|tickets|contact us|first.response)|\[SUCCESS COST\].{0,300}(support|ticket|agent|contact)"

# --- Negative: a genuinely reversible change ---

EXPECTED_VERDICT["tc-wi6-http-client-swap.md"]="None"
CLAIM_ACCURACY["tc-wi6-http-client-swap.md"]="sound"  # Per-request flag, both clients kept for a quarter, no stored data or contract change, flag-off rehearsed in staging and production — no reversibility cliff, flat gradient
KEY_CHECK["tc-wi6-http-client-swap.md"]="no_pattern:^[[:space:]]*([-*+]|[0-9]+[.)])[[:space:]]+([*_\`]*\[[a-z -]+\][*_\`]*[[:space:]]*)*[*_\`]*\[REVERSIBILITY CLIFF\]|^[[:space:]]*[|]([^|]*[|])*[^|]*\[REVERSIBILITY CLIFF\];;format_check"
