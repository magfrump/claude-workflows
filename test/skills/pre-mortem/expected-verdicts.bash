#!/usr/bin/env bash
# shellcheck disable=SC2034  # Arrays are used by test files that source this file
# Machine-parseable expected verdicts for pre-mortem fixtures.
# Used by health-check to validate fixture ↔ verdict coverage.
#
# pre-mortem writes 3-5 failure narratives, each tagged
# "**Plausibility:** Likely|Plausible|Unlikely-but-catastrophic" and
# "**Severity:** Low|Medium|High|Catastrophic". Each planted fixture is a
# proposal about to ship with ONE concrete failure path a competent pre-mortem
# should narrate. EXPECTED_VERDICT is the severity set that narrative should
# carry; finding_match requires the planted path's pattern and that severity in
# the same narrative (its heading's block; with no per-narrative headings, the
# enclosing section).
#
# Check formats used here (separated by ;; — so no pattern may contain ";"):
#   finding_match:<sev>=<ERE> — one narrative carries a **Severity:** from <sev>
#                              and a line matching <ERE> (outside fixture echo)
#   cites_pattern:<ERE>      — report matches <ERE> (case-insensitive, per line)
#   no_pattern:<ERE>         — report never matches <ERE>
#   no_severity:<values>     — no **Severity:** line starts with one of <values>
#   format_check             — pre-mortem-format.bats passes
#
# EXPECTED_VERDICT "None" marks the two negatives, which are checked with
# no_severity instead of finding_match.

declare -gA EXPECTED_VERDICT
declare -gA CLAIM_ACCURACY
declare -gA KEY_CHECK

# --- Planted failure paths, one each ---

EXPECTED_VERDICT["tc-pm1-billing-ledger-migration.md"]="High|Catastrophic"
CLAIM_ACCURACY["tc-pm1-billing-ledger-migration.md"]="flaw"  # No dual-write window: change capture stops at cutover and Postgres goes read-only, so "flip LEDGER_DSN back" during the 2-week soak strands every invoice/payment written to Keel since cutover
KEY_CHECK["tc-pm1-billing-ledger-migration.md"]="finding_match:High|Catastrophic=dual.?writ|reverse.?(replicat|sync|stream|change.?capture|cdc)|(writes?|invoices?|payments?|rows?|transactions?|records?)[^.]{0,120}(only (exist|live)|exist(ed)? only|live(d)? only|never (reach|made it|written|copied|replicated)|not (in|on|back in|back to) postgres|missing from postgres)|(roll.?back|revert|flip(ped|ping)? (it )?back)[^.]{0,200}(lost|lose|loses|losing|discard|orphan|strand|missing|diverge|gap)|(lost|lose|discard|orphan|strand)[^.]{0,120}(since|after) (the )?cut.?over|postgres[^.]{0,80}(stale|out of date|days behind|frozen at);;format_check"

EXPECTED_VERDICT["tc-pm2-checkout-redesign-rollout.md"]="High|Catastrophic"
CLAIM_ACCURACY["tc-pm2-checkout-redesign-rollout.md"]="flaw"  # Launch into the known peak: 100% + old code path deleted on 25 Nov, the day before the change freeze and three days before a 4x Black Friday peak, load tested only to 1.5x, with nothing to fall back to
KEY_CHECK["tc-pm2-checkout-redesign-rollout.md"]="finding_match:High|Catastrophic=1\.5.?x[^.]{0,200}(4.?x|four.?times|quadruple|black friday|cyber monday|peak weekend)|(4.?x|four.?times|black friday|cyber monday)[^.]{0,200}1\.5.?x|(freeze|frozen)[^.]{0,200}(nothing to (fall|roll) back|no (fallback|old checkout|way back)|could(n.t| not) (roll|revert|fall)|(old|v1|previous) (checkout|code path)[^.]{0,40}(gone|removed|deleted))|(day|eve) before (the )?(change )?freeze|(three|3|two|2|four|4) days (before|ahead of) (black friday|the peak|peak)|(never|not|wasn.t|was not) (been )?load.?tested (at|to|for|beyond|above)"

EXPECTED_VERDICT["tc-pm3-search-index-rebuild.md"]="Medium|High|Catastrophic"
CLAIM_ACCURACY["tc-pm3-search-index-rebuild.md"]="flaw"  # Key-person risk: Marguerite wrote the indexer, is porting it, reviews her own runbook, is the cutover on-call, and starts four months' leave on 16 March, three days before the old cluster stops being fed
KEY_CHECK["tc-pm3-search-index-rebuild.md"]="finding_match:Medium|High|Catastrophic=bus.?factor|single point of (failure|knowledge)|key.?person|nobody else|no.?one else|no other (engineer|person|one)|only (person|engineer|one) (who|that|with)|sole (owner|maintainer|expert|person|engineer|holder)|(no|without a?) (backup|secondary|second) (on.?call|engineer|responder|owner|reviewer)|knowledge (silo|concentrat|transfer|handoff|hand.?off)|(four|4) days (after|before)[^.]{0,120}(leave|20 march|decommission)|(leave)[^.]{0,200}(20 march|23 march|decommission|old cluster|lodestone 6)"

EXPECTED_VERDICT["tc-pm4-payment-processor-switch.md"]="High|Catastrophic"
CLAIM_ACCURACY["tc-pm4-payment-processor-switch.md"]="flaw"  # Contract end during the cutover: Tessellate's agreement ends 30 June with non-renewal already served, while the ramp is only at 25% until 7 July and 100% on 21 July; rollback "through August" and refunds of Tessellate-taken bookings assume a processor that no longer exists
KEY_CHECK["tc-pm4-payment-processor-switch.md"]="finding_match:High|Catastrophic=(30 june|june 30|end of june|1 july|july 1)[^.]{0,200}(25 ?%|75 ?%|three.quarters|still|mid.?ramp|middle of the ramp|half|ramp)|(25 ?%|75 ?%|three.quarters|mid.?ramp|middle of the ramp)[^.]{0,200}(30 june|june 30|end of june|1 july|july 1|contract|agreement)|(refund|chargeback)s?[^.]{0,200}tessellate[^.]{0,120}(ended|expired|lapsed|terminated|no longer|gone|closed|after the (contract|agreement))|(rollback|roll back|fall.?back|flag back to 0)[^.]{0,200}(no longer|doesn.t exist|does not exist|terminated|expired|ended|gone|nowhere);;format_check"

EXPECTED_VERDICT["tc-pm5-self-serve-returns.md"]="Medium|High|Catastrophic"
CLAIM_ACCURACY["tc-pm5-self-serve-returns.md"]="flaw"  # Success floods a manual step: tripling 35 requests/day gives ~105/day into a 3-person Refunds desk that clears ~45/day by hand, so ~60/day of backlog accrues while customers hold an instant "requested" email
KEY_CHECK["tc-pm5-self-serve-returns.md"]="finding_match:Medium|High|Catastrophic=backlog|bottleneck|overwhelm|swamp|flood|drown|pil(e|es|ed|ing) up|(^|[^0-9,.])105([^0-9]|$)|60 (more |extra )?(requests? |returns? )?(a|per|each) day|(refunds? desk|finance op|three people|45 a day)[^.]{0,200}(can.?t|cannot|could not|couldn.t|unable|behind|exceed|outstrip|outpace|capacity)|capacity[^.]{0,120}(refunds? desk|finance op|45)"

# --- Negatives: sound proposals that must not draw the worst grade ---

EXPECTED_VERDICT["tc-pm6-docs-typeface-change.md"]="None"
CLAIM_ACCURACY["tc-pm6-docs-typeface-change.md"]="sound"  # Low-stakes, internal, cookie-gated preview, stateless static site, 5-minute revert — nothing Catastrophic, and SKILL.md says to state explicitly when nothing rises to "must address"
KEY_CHECK["tc-pm6-docs-typeface-change.md"]="no_severity:Catastrophic;;cites_pattern:(no|none of the|not one of the)[^.]{0,40}(narratives?|failures?|risks?|items?|stories)[^.]{0,60}(rise|rises|reach|reaches|meet|meets|warrant|qualif|block)|must address[^.]{0,40}(none|nothing|n/a)|nothing[^.]{0,40}(rises|reaches|meets|warrants|blocks);;format_check"

EXPECTED_VERDICT["tc-pm7-orders-column-rename.md"]="None"
CLAIM_ACCURACY["tc-pm7-orders-column-rename.md"]="sound"  # Expand-and-contract rename with dual writes through a 30-day soak, per-step flags, daily equality check, snapshot before drop — nothing Catastrophic, and no false "no dual-write / rollback loses data" alarm
KEY_CHECK["tc-pm7-orders-column-rename.md"]="no_severity:Catastrophic;;no_pattern:(no|without|lacks?|lacking|missing|absent)( a| any)? dual.?writ|(never|not) (be )?(written|writ(es|ing)) to both;;format_check"
