#!/usr/bin/env bash
# shellcheck disable=SC2034  # Arrays are used by test files that source this file
# Machine-parseable expected verdicts for business-plan-critique-moat fixtures.
# Used by health-check to validate fixture ↔ verdict coverage.
#
# business-plan-critique-moat grades each of its five lenses with a
# "**Verdict:** Durable|Plausible|Weak|Absent|Not Claimed" line. Each
# planted-flaw fixture aims at ONE lens; EXPECTED_VERDICT is the grade that
# lens should get, and verdict_match passes if ANY **Verdict:** line matches,
# so the flaw-specific cites_pattern is what ties the grade to the right lens.
#
# Check formats used here (separated by ;; — so no pattern may contain ";"):
#   verdict_match            — some **Verdict:** line matches EXPECTED_VERDICT
#   cites_pattern:<ERE>      — report matches <ERE> (case-insensitive, per line)
#   no_pattern:<ERE>         — report never matches <ERE>
#   no_verdict:<values>      — no **Verdict:** line starts with one of <values>
#   format_check             — business-plan-critique-moat-format.bats passes
#
# EXPECTED_VERDICT "None" marks the two negatives, which carry no graded lens:
# the stub (must print only the skip line) and the short sound plan (checked by
# no_verdict:Absent instead).

declare -gA EXPECTED_VERDICT
declare -gA CLAIM_ACCURACY
declare -gA KEY_CHECK

# --- Planted flaws, one lens each ---

EXPECTED_VERDICT["tc-moat1-veterinary-booking.md"]="Weak|Absent"
CLAIM_ACCURACY["tc-moat1-veterinary-booking.md"]="flaw"  # Moat Type: the named moat is an 18-month head start / first-mover land-grab, no structural mechanism
KEY_CHECK["tc-moat1-veterinary-booking.md"]="verdict_match;;cites_pattern:(first.?mover|head.?start|speed|got here first).{0,150}(not a (durable |real |structural )?moat|isn.t a moat|temporary|erode|copied|copy|replicat|no (structural|durable))|(not a (durable |real |structural )?moat|isn.t a moat|no (durable|structural) moat).{0,150}(first.?mover|head.?start|speed)|first.?mover advantage is not;;format_check"

EXPECTED_VERDICT["tc-moat2-meal-planning-app.md"]="Weak|Absent"
CLAIM_ACCURACY["tc-moat2-meal-planning-app.md"]="flaw"  # Distribution Channel: 88% of installs from App Store search/editorial + TikTok organic (rented demand surfaces), CAC modelled flat for 3 years
KEY_CHECK["tc-moat2-meal-planning-app.md"]="verdict_match;;cites_pattern:(apple|app store|tiktok|platform).{0,150}(owns|own the|control|chang|algorithm|rent|dependen|concentrat|mediat)|(owns|control|rent|dependen|concentrat|mediat).{0,150}(apple|app store|tiktok)|(cac|acquisition cost).{0,100}(flat|rise|rising|increase|saturat)"

EXPECTED_VERDICT["tc-moat3-field-inspection-forms.md"]="Weak|Absent"
CLAIM_ACCURACY["tc-moat3-field-inspection-forms.md"]="flaw"  # Switching Cost: claimed "high switching costs" but one-click CSV/PDF export, month-to-month, 10-minute training, integrations only on the v3 roadmap
KEY_CHECK["tc-moat3-field-inspection-forms.md"]="verdict_match;;cites_pattern:(one.click|csv|pdf).{0,100}export|export.{0,100}(one.click|csv|trivial|easy|cheap)|month.to.month|pre.churn|nothing structural|(version 3|v3|roadmap|integrations module).{0,150}(hypothetical|not yet|future|doesn.t exist|does not exist|unbuilt|unshipped)|(hypothetical|not yet|future).{0,150}(version 3|v3|roadmap|integrations module);;format_check"

EXPECTED_VERDICT["tc-moat4-household-budgeting.md"]="Weak|Absent"
CLAIM_ACCURACY["tc-moat4-household-budgeting.md"]="flaw"  # Network Effect: "strong network effects" for a single-player app — brand, volume pricing and word of mouth relabelled as network effects
KEY_CHECK["tc-moat4-household-budgeting.md"]="verdict_match;;cites_pattern:single.player|no (user.to.user |direct )?interaction|(don.t|do not|never) interact|weak form|(brand|word.of.mouth|scale econom|viral|referral).{0,150}(not a (true |real |structural )?network effect|isn.t a network effect|mislabel|miscategori|misclassif|relabel|rebrand)|(not a (true |real |structural )?network effect|isn.t a network effect|mislabel|miscategori|misclassif|relabel).{0,150}(brand|word.of.mouth|scale econom|viral|referral)"

EXPECTED_VERDICT["tc-moat5-sales-call-notes.md"]="Weak|Absent"
CLAIM_ACCURACY["tc-moat5-sales-call-notes.md"]="flaw"  # Competitive Response: 94% of calls run on Convene, plan assumes Convene won't build notes and budgets for no response (obvious bundling threat)
KEY_CHECK["tc-moat5-sales-call-notes.md"]="verdict_match;;cites_pattern:bundl|convene.{0,150}(free|native|built.in|ships?|replicat|cop(y|ies)|build (it|this|its own)|launch)|(free|native|built.in).{0,150}convene"

# --- Negatives: the stub pre-flight ---

EXPECTED_VERDICT["tc-moat6-cold-chain-sensors.md"]="None"
CLAIM_ACCURACY["tc-moat6-cold-chain-sensors.md"]="stub"  # 90 words, TODO/TBD/placeholder markers, empty sections — must print only the skip line
KEY_CHECK["tc-moat6-cold-chain-sensors.md"]="cites_pattern:draft incomplete.{0,3}moat critique skipped;;no_pattern:^#{1,4} .*(Moat Type|Distribution Channel|Switching Cost|Network Effect|Competitive Response|Factual Foundation|Overall Assessment);;no_pattern:^\*\*(Verdict|Confidence):\*\*"

EXPECTED_VERDICT["tc-moat7-lab-compliance-software.md"]="None"
CLAIM_ACCURACY["tc-moat7-lab-compliance-software.md"]="sound"  # 433 words, no stub markers, regulation-backed switching cost, matched sales channel, incumbent bundling addressed — full critique, no Absent lens
KEY_CHECK["tc-moat7-lab-compliance-software.md"]="no_pattern:moat critique skipped;;no_verdict:Absent;;format_check"
