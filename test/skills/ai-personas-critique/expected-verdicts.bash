#!/usr/bin/env bash
# shellcheck disable=SC2034  # Arrays are used by test files that source this file
# Machine-parseable expected verdicts for ai-personas-critique evaluation fixtures.
# Used by health-check to validate fixture ↔ verdict coverage.
#
# ai-personas-critique tags each persona's objection "**Severity:** Fatal flaw |
# Significant weakness | Point to consider". The "verdict" here is the set of
# tiers the persona that names the flaw must assign, checked by finding_match
# (the tier and the flaw's pattern in the same persona section or Ranked
# Concerns row). Checks used (separated by ;; in KEY_CHECK):
#   finding_match:<tiers>=<ERE> — one persona section (or Ranked Concerns row)
#                           carries a tier from <tiers> and a line matching <ERE>
#   no_severity:<tiers>   — no **Severity:** line matches <tiers>
#   cites_pattern:<ERE>   — report matches <ERE> (case-insensitive)
#   no_pattern:<ERE>      — report does not match <ERE> (case-insensitive)
#   format_check          — report passes ai-personas-critique-format.bats
# Patterns are ERE and may not contain a semicolon (the check list splits on
# it), so the stub skip line "draft incomplete; persona pass skipped" is
# matched with "." standing in for the semicolon.
#
# Each planted-flaw draft is aimed at one catalog persona (named in the
# CLAIM_ACCURACY comment) in a different domain, so persona selection has to
# vary to catch them. cites_pattern names the flaw, not the persona: another
# persona catching it passes too. EXPECTED_VERDICT "None" marks the
# negatives, which are graded by no_pattern/no_severity instead.

declare -gA EXPECTED_VERDICT
declare -gA CLAIM_ACCURACY
declare -gA KEY_CHECK

# --- Planted flaws, one per persona lens ---

EXPECTED_VERDICT["tc-per1-red-light-cameras.md"]="Fatal flaw|Significant weakness"
CLAIM_ACCURACY["tc-per1-red-light-cameras.md"]="flaw"  # Empiricist: pilot sites picked as the worst 2023 intersections, no comparison sites — regression to the mean, and the 39% extrapolated to lower-crash sites
KEY_CHECK["tc-per1-red-light-cameras.md"]="finding_match:Fatal flaw|Significant weakness=regress(ion|ed|ing)? (to|toward|towards) the mean|control (group|site|intersection)|comparison (group|site|intersection)|selected (on|for|because of) (their |high |the )?(high|worst|crash)|selection (effect|bias)|worst (year|intersection)|unusually (high|bad);;format_check"

EXPECTED_VERDICT["tc-per2-support-bonus-plan.md"]="Fatal flaw|Significant weakness"
CLAIM_ACCURACY["tc-per2-support-bonus-plan.md"]="flaw"  # Incentive Analyst: pay tied to agent-set Resolved count per hour, quality out of pay — Goodhart, premature closes, cherry-picking easy tickets
KEY_CHECK["tc-per2-support-bonus-plan.md"]="finding_match:Fatal flaw|Significant weakness=goodhart|gam(e|ed|ing) (the|this)? ?(metric|system|number|leaderboard)|perverse|reopen|(close|resolv|mark)[a-z]* .{0,40}(prematurely|too early|before .{0,20}(fixed|solved))|cherry.?pick|easy tickets|split(ting)? tickets"

EXPECTED_VERDICT["tc-per3-account-recovery-redesign.md"]="Fatal flaw|Significant weakness"
CLAIM_ACCURACY["tc-per3-account-recovery-redesign.md"]="flaw"  # Security Analyst: recovery by SMS alone plus agent phone change on name/DOB/last-4, no hold on transfers — SIM swap and social-engineering account takeover
KEY_CHECK["tc-per3-account-recovery-redesign.md"]="finding_match:Fatal flaw|Significant weakness=SIM.?(swap|hijack|jack)|port(ing)?.?out|number port|social.?engineer|account takeover|pretext|(name|date of birth|DOB).{0,80}(breach|public|easily|findable|leaked|obtain);;format_check"

EXPECTED_VERDICT["tc-per4-marketplace-dispute-desk.md"]="Fatal flaw|Significant weakness"
CLAIM_ACCURACY["tc-per4-marketplace-dispute-desk.md"]="flaw"  # Scaling Skeptic: 40 disputes/week x 50 = ~2,000/week at ~40 min each, ~1,300+ hours/week for three specialists (~120 hours)
KEY_CHECK["tc-per4-marketplace-dispute-desk.md"]="finding_match:Fatal flaw|Significant weakness=2,?000 (disputes|a week|per week|/ ?w)|1,?[0-9]{3} (specialist.|staff.|person.|labou?r.)?hours|[0-9]{2,3} (specialists|FTEs|full.time)|bottleneck|backlog|(not|n't|cannot) scale|linear(ly)? with"

EXPECTED_VERDICT["tc-per5-clinic-overbooking-model.md"]="Fatal flaw|Significant weakness"
CLAIM_ACCURACY["tc-per5-clinic-overbooking-model.md"]="flaw"  # Ethicist: no-show model driven by insurance category and distance double-books poorer / publicly insured / distant patients, who bear the waits and bumped visits
KEY_CHECK["tc-per5-clinic-overbooking-model.md"]="finding_match:Fatal flaw|Significant weakness=proxy|disparat|inequit|discriminat|fairness|(low|lower).income|(poor|poorer) patients|public(ly)?.insur|self.pay (patients|and public)|who bears"

# --- Negatives: the stub pre-flight ---

EXPECTED_VERDICT["tc-per6-transit-fare-memo.md"]="None"
CLAIM_ACCURACY["tc-per6-transit-fare-memo.md"]="stub"  # 106 words, TODO markers, empty sections — must print only the skip line
KEY_CHECK["tc-per6-transit-fare-memo.md"]="cites_pattern:draft incomplete. persona pass skipped;;no_pattern:^#+ *(Persona Critiques|Synthesis|Convergent Findings|Ranked Concerns|Blind Spots|Goal-Alignment Note);;no_pattern:^\*\*(Severity|Personas selected):\*\*"

EXPECTED_VERDICT["tc-per7-library-sunday-pilot.md"]="None"
CLAIM_ACCURACY["tc-per7-library-sunday-pilot.md"]="short-complete"  # 437 words, no stub markers; small, funded, reversible pilot with stop criteria — full critique, no Fatal flaw
KEY_CHECK["tc-per7-library-sunday-pilot.md"]="no_pattern:draft incomplete. persona pass skipped;;no_severity:Fatal flaw;;format_check"
