#!/usr/bin/env bash
# shellcheck disable=SC2034  # Arrays are used by test files that source this file
# Machine-parseable expected verdicts for tech-debt-triage fixtures.
# Used by health-check to validate fixture ↔ verdict coverage.
#
# tech-debt-triage grades each debt item with a
# "**Recommendation:** Fix now|Fix opportunistically|Carry intentionally|Defer and monitor"
# line and a "### Carrying Cost: High|Medium|Low" heading. Each fixture is a
# single debt item whose correct call follows from SKILL.md's fix-or-carry
# rules. EXPECTED_VERDICT records the expected Recommendation for readers; the
# checks below grade it with field_match, since the skill uses no **Verdict:**
# line. field_match passes if ANY **Recommendation:** line matches, so the
# driver-specific cites_pattern is what shows the report reached the call for
# the right reason.
#
# Check formats used here (separated by ;; — so no pattern may contain ";"):
#   field_match:<F>=<values> — some **<F>:** line starts with one of <values>
#   no_field:<F>=<values>    — no **<F>:** line starts with one of <values>
#   cites_pattern:<ERE>      — report matches <ERE> (case-insensitive, per line)
#   no_pattern:<ERE>         — report never matches <ERE>
#   format_check             — tech-debt-triage-format.bats passes
#
# Carrying Cost is graded with a cites_pattern / no_pattern anchored on the
# "### Carrying Cost: <grade>" heading line.
#
# Every cites_pattern keys on a fact the report has to derive (an incident
# count, a runway, the days to an EOL date, the time since the last change), so
# a report that only echoes the fixture text cannot match it.

declare -gA EXPECTED_VERDICT
declare -gA CLAIM_ACCURACY
declare -gA KEY_CHECK

# --- Planted items: the correct call is to act ---

EXPECTED_VERDICT["tc-td1-discount-rules.md"]="Fix now"
CLAIM_ACCURACY["tc-td1-discount-rules.md"]="flaw"  # Hot path touched 49 of 52 weeks, four incidents (INC-2231/2270/2298/2340) blamed on hand-ordered precedence, 4-5 day fix, no competing deadline — carrying cost High, Fix now
KEY_CHECK["tc-td1-discount-rules.md"]="field_match:Recommendation=Fix now;;cites_pattern:^#{1,4} *Carrying Cost:? *\*{0,2}High;;cites_pattern:(4|four) (separate |production |recent |distinct |costly |customer.facing |sev[- ]?[0-9] )?(incidents|outages|regressions|postmortems|post.incident reviews)|weekly|every week|each week|(nearly|almost|practically|roughly) every (single )?week;;format_check"

EXPECTED_VERDICT["tc-td2-statement-renderer.md"]="Fix now"
CLAIM_ACCURACY["tc-td2-statement-renderer.md"]="flaw"  # Stable, incident-free code, but Quarrel 2.x EOL on 2026-12-31 is 87 days out and the 2027-02 regulator exam requires supported runtimes — imminent urgency trigger, Fix now
KEY_CHECK["tc-td2-statement-renderer.md"]="field_match:Recommendation=Fix now;;cites_pattern:(86|87|88|~ ?12|12|twelve|13|thirteen) (calendar )?(days|weeks)|(under|less than|about|roughly|within|only|~) ?(3|three) months|(before|ahead of|in time for) (the )?(february|feb|2027).{0,30}(exam|examination|audit)"

EXPECTED_VERDICT["tc-td3-nightly-reconciliation.md"]="Fix now"
CLAIM_ACCURACY["tc-td3-nightly-reconciliation.md"]="flaw"  # Peak RSS grows 0.6 GB/month toward a 16 GB hard limit: 14.2 GB in September leaves ~3 months (December) before OOM — scaling threshold imminent despite low day-to-day carrying cost, Fix now
KEY_CHECK["tc-td3-nightly-reconciliation.md"]="field_match:Recommendation=Fix now;;cites_pattern:(0\.6 ?gb|600 ?mb).{0,40}(/|per|a|each|every) ?(month|mo)|(~|about |roughly |within |in |under |only )?(3|three) months|december|(year.end|end of (the )?year|end of 2026)|(1\.8 ?gb|1,?800 ?mb).{0,60}(headroom|left|remaining|margin|of room);;format_check"

EXPECTED_VERDICT["tc-td4-postcode-validation.md"]="Fix opportunistically"
CLAIM_ACCURACY["tc-td4-postcode-validation.md"]="flaw"  # Medium carrying cost (drifted copies, one same-day bug), 2-3 hour fix, and FUL-1187 already rewrites every line of the three blocks next sprint — ride along, Fix opportunistically
KEY_CHECK["tc-td4-postcode-validation.md"]="field_match:Recommendation=Fix opportunistically;;cites_pattern:^#{1,4} *Carrying Cost:? *\*{0,2}Medium;;cites_pattern:(FUL-1187|pydantic|request.model|webargs).{0,200}(alongside|same (change|pr|sprint|ticket|work|diff)|as part of|fold|bundl|ride|piggyback|while|together|during)|(alongside|as part of|fold (it )?in|bundl|piggyback|ride.along|during).{0,150}(FUL-1187|pydantic|request.model|webargs|migration)"

# --- Negatives: carry-type items that must not be pushed to Fix now ---

EXPECTED_VERDICT["tc-td5-vat-rate-tables.md"]="Carry intentionally"
CLAIM_ACCURACY["tc-td5-vat-rate-tables.md"]="sound"  # False-urgency trap: ugly 780-line module, but last changed 2024-03-14, zero incidents, 412 finance-checked tests, one caller, 6-8 day fix — Carry intentionally, carrying cost not High/Medium
KEY_CHECK["tc-td5-vat-rate-tables.md"]="field_match:Recommendation=Carry intentionally;;no_field:Recommendation=Fix now;;no_pattern:^#{1,4} *Carrying Cost:? *\*{0,2}(High|Medium);;cites_pattern:(untouched|unchanged|not (been )?(changed|touched|modified)|no (changes|commits|edits)).{0,60}(since|in|for).{0,30}(2024|years|months)|(years|months).{0,40}(untouched|unchanged|without (a |any )?(change|commit|edit))|(2|two|2\.5|two and a half) (\+ )?years (old|stable|without)|last (changed|touched|modified) (over |more than |nearly |about )?(2|two|2\.5|two and a half) years;;format_check"

EXPECTED_VERDICT["tc-td6-job-queue.md"]="Defer and monitor"
CLAIM_ACCURACY["tc-td6-job-queue.md"]="sound"  # Works at 40 of a tested 900 jobs/s, no incidents; the only trigger is an undecided second region (go/no-go at Q2 2027 planning) against a 3-4 week fix and a contractual Q4 deadline — Defer and monitor (Carry intentionally accepted), tied to the region decision
KEY_CHECK["tc-td6-job-queue.md"]="field_match:Recommendation=Defer and monitor|Carry intentionally;;no_field:Recommendation=Fix now;;cites_pattern:(multi.?region|second (hosting )?region|asia.pacific|apac|region decision|go/no.go).{0,150}(revisit|re.?evaluat|reassess|re.?triage|monitor|trigger)|(revisit|re.?evaluat|reassess|re.?triage|trigger).{0,150}(multi.?region|second (hosting )?region|asia.pacific|apac|q2 2027|go/no.go);;format_check"
