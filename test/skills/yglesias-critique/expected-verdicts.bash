#!/usr/bin/env bash
# shellcheck disable=SC2034  # Arrays are used by test files that source this file
# Machine-parseable expected results for yglesias-critique evaluation fixtures.
# Used by health-check to validate fixture <-> verdict coverage.
#
# yglesias-critique does not grade: there are no **Verdict:** or **Severity:**
# lines, so EXPECTED_VERDICT is "Any" for every critiqued draft and "None" for
# the stub, and verdict_match / severity_match are never used. Checks:
#
#   cites_pattern:<ERE>  the report names the planted flaw. Every critique must
#                        use "scale", "money", "org chart", "cost disease" etc.
#                        in its fixed sections, so patterns key on the draft's
#                        specific failure (teacher transfers, capitalization
#                        into prices, cost per mile...), never on those words.
#   no_pattern:<ERE>     the report must not match (stub: no critique headings,
#                        title, warning or load-bearing line. Short complete
#                        draft: no skip line).
#   format_check         the report passes yglesias-critique-format.bats.
#
# Patterns are case-insensitive ERE and never contain a semicolon, because the
# check list splits on ";;".
#
# CLAIM_ACCURACY is "flaw" for drafts with one planted flaw (the comment names
# it and the move meant to catch it), "stub" for the pre-flight skip case and
# "complete" for the short draft that must still be critiqued.

declare -gA EXPECTED_VERDICT
declare -gA CLAIM_ACCURACY
declare -gA KEY_CHECK

# --- Planted mechanism flaws, one cognitive move each ---

EXPECTED_VERDICT["tc-ygl1-class-size-cap.md"]="Any"
CLAIM_ACCURACY["tc-ygl1-class-size-cap.md"]="flaw"  # move 1: universal K-3 cap + seniority transfers pull experienced teachers west, east side gets novices
KEY_CHECK["tc-ygl1-class-size-cap.md"]="cites_pattern:emergency (permit|credential)|uncertified|under.?qualified|inexperienced|less.experienced|novice|first.year teachers|seniority|(experienced|veteran|senior) teachers.{0,60}(west|leave|transfer|move)|teacher (supply|shortage|pool|quality);;format_check"

EXPECTED_VERDICT["tc-ygl2-down-payment-grants.md"]="Any"
CLAIM_ACCURACY["tc-ygl2-down-payment-grants.md"]="flaw"  # move 3: $30k demand subsidy into a supply-constrained market is capitalized into prices, sellers capture it
KEY_CHECK["tc-ygl2-down-payment-grants.md"]="cites_pattern:capitaliz|bid(s|ding)? up|(push|drive)(s|ing)? up (home )?prices|sellers?.{0,60}(capture|pocket|windfall|keep|receive)|inelastic|supply.constrained|fixed (housing )?supply"

EXPECTED_VERDICT["tc-ygl3-rail-extension.md"]="Any"
CLAIM_ACCURACY["tc-ygl3-rail-extension.md"]="flaw"  # move 5: cost per mile nearly tripled (~$291M to ~$848M), plan pours more money into the same delivery model
KEY_CHECK["tc-ygl3-rail-extension.md"]="cites_pattern:per.mile|per.(km|kilometer)|cost per (mile|km)|nearly (tripl|three times)|(peer|international|european|comparable) (cities|systems|countries|projects|agencies)"

EXPECTED_VERDICT["tc-ygl4-apprenticeship-guarantee.md"]="Any"
CLAIM_ACCURACY["tc-ygl4-apprenticeship-guarantee.md"]="flaw"  # move 6: 320-student selective pilot with 74 employers scaled to 45,000/yr needs ~10,400 host employers
KEY_CHECK["tc-ygl4-apprenticeship-guarantee.md"]="cites_pattern:employer.{0,50}(slot|capacity|placement|willing|supply|recruit|absorb|enough)|(slot|placement|host)s?.{0,40}employer|10,?[0-9]{3} employers|self.select|(competitive|selective) (process|admission|screen)|one in three|cream|motivated (students|applicants|participants);;format_check"

EXPECTED_VERDICT["tc-ygl5-regional-housing-portal.md"]="Any"
CLAIM_ACCURACY["tc-ygl5-regional-housing-portal.md"]="flaw"  # move 7: 23 towns + 4 counties, a voluntary steering committee, no lead agency, owner, staff or authority
KEY_CHECK["tc-ygl5-regional-housing-portal.md"]="cites_pattern:lead (agency|entity|organization|jurisdiction)|(no|single|named|accountable|clear) (owner|entity|agency|body|operator)|who (would|will|actually)? ?(runs?|owns?|builds?|operates?|staffs?|maintains?|hires?)|joint powers|governance|job description|legal authority"

# --- Pre-flight negatives ---

EXPECTED_VERDICT["tc-ygl6-parking-minimums.md"]="None"
CLAIM_ACCURACY["tc-ygl6-parking-minimums.md"]="stub"  # 66 words, TODO/TBD/placeholder, empty sections: skip line only
KEY_CHECK["tc-ygl6-parking-minimums.md"]="cites_pattern:draft incomplete.{1,3}persona pass skipped;;no_pattern:^## (The Goal|Goal vs|The Boring Lever|Follow the Money|Factual Foundation|The Scale Test|The Org Chart|Adoption Survival|The Cost Disease|Overall Assessment);;no_pattern:^# .*Yglesias|load-bearing objection|no fact-check report provided"

EXPECTED_VERDICT["tc-ygl7-library-fines.md"]="Any"
CLAIM_ACCURACY["tc-ygl7-library-fines.md"]="complete"  # 386 words, no stub markers: full critique, not skipped
KEY_CHECK["tc-ygl7-library-fines.md"]="no_pattern:draft incomplete|persona pass skipped;;format_check"
