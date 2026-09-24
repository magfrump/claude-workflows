#!/usr/bin/env bash
# shellcheck disable=SC2034  # Arrays are used by test files that source this file
# Machine-parseable expected results for design-space-situating fixtures.
# Used by health-check to validate fixture ↔ verdict coverage.
#
# design-space-situating grades nothing: it writes a Situating Record with a
# placements table for eight dimensions and a "Tensions surfaced" list. Every
# report names every dimension, so no check keys on dimension names or on the
# placement vocabulary (Centralized, Snapshot, Tacit, Stakeholder ...) alone.
# Each planted fixture is a decision brief that frames the decision wrongly on
# ONE dimension; its cites_pattern needs the dimension's tension word near a
# fact from that brief (the partners, the nurses, the attack waves, the head
# roaster, the control-room operators). EXPECTED_VERDICT is "None" throughout
# because the skill has no graded field line.
#
# Check formats used here (separated by ;; — so no pattern may contain ";"):
#   cites_pattern:<ERE>      — report matches <ERE> (case-insensitive, per line)
#   no_pattern:<ERE>         — report never matches <ERE>
#   format_check             — design-space-situating-format.bats passes
#
# Every cites_pattern was checked not to match its own fixture, so a report
# that only echoes the brief cannot pass.

declare -gA EXPECTED_VERDICT
declare -gA CLAIM_ACCURACY
declare -gA KEY_CHECK

# --- Planted misframings, one dimension each ---

EXPECTED_VERDICT["tc-dss1-partner-webhook-payloads.md"]="None"
CLAIM_ACCURACY["tc-dss1-partner-webhook-payloads.md"]="flaw"  # Dim 5 reversibility: framed as a cheap, revisit-later formatting choice, but 312 partners write their own parsers and the partner agreement freezes every field for 24 months
KEY_CHECK["tc-dss1-partner-webhook-payloads.md"]="cites_pattern:(one.way|irreversib|(expensive|costly|hard|difficult) to (undo|reverse|change)|cliff|lock(s|ed)?.?in|frozen|freez).{0,200}(partner|integrator|312|24.month|parser|agreement|compatib)|(partner|integrator|312|24.month|agreement|parser).{0,200}(one.way|irreversib|(expensive|costly|hard|difficult) to (undo|reverse|change)|cliff|lock(s|ed)?.?in|frozen|freez|not (actually |really |truly )?(cheap|easy|reversible|low.stakes))|(cheap|easy|low.stakes).{0,100}(only|just) (on|for) (our|ledgerline|the integrations)|(our|ledgerline.s) side.{0,150}(not|isn.t|but).{0,100}partner;;format_check"

EXPECTED_VERDICT["tc-dss2-ward-shift-swaps.md"]="None"
CLAIM_ACCURACY["tc-dss2-ward-shift-swaps.md"]="flaw"  # Dims 1 and 7 authority/social structure: one architect writes swap rules for 1,100 nurses on 14 wards that each run their own arrangement, union agreement requires negotiation, nurses only hear at go-live training
KEY_CHECK["tc-dss2-ward-shift-swaps.md"]="cites_pattern:(nurse|ward|union|staff).{0,200}(participat|co.?design|consult|say in|voice|legitima|buy.?in|involv|excluded|left out|no seat)|(participat|co.?design|consult|legitima|buy.?in|involv|excluded).{0,200}(nurse|ward|union)|(existing|informal|local|ward.level) (swap )?(arrangement|practice|norm|agreement)s?.{0,200}(override|overrid|erase|replace|ignore|discard|community)"

EXPECTED_VERDICT["tc-dss3-card-fraud-rules.md"]="None"
CLAIM_ACCURACY["tc-dss3-card-fraud-rules.md"]="flaw"  # Dim 2 orientation in time: optimises for today's fraud and hands over a finished rule set with no re-tuning budget, while the attack mix turned over three times in a year and new products launch next quarter
KEY_CHECK["tc-dss3-card-fraud-rules.md"]="cites_pattern:(snapshot|static|one.shot|ship.and.(walk|forget)|frozen|freez|finished artifact).{0,200}(attack|fraud|drift|chang|shift|evolv|adapt|wave|turn(ed|s)? over|bnpl|buy.now|gift.card)|(attack|fraud|wave|turn(ed|s)? over|drift|bnpl|buy.now|gift.card).{0,200}(snapshot|static|one.shot|frozen|freez|stale|decay|degrad|out of date|outdated)|(ongoing|continuous) (process|re.?tun|retrain|adapt)|backward.looking.{0,200}(attack|fraud|twelve months|last year)"

EXPECTED_VERDICT["tc-dss4-roast-profile-automation.md"]="None"
CLAIM_ACCURACY["tc-dss4-roast-profile-automation.md"]="flaw"  # Dim 6 formality: the head roaster's judgment by smell, colour and sound of first crack, learned by apprenticeship, is to be written into a formal controller spec in six weeks with manual adjustment switched off
KEY_CHECK["tc-dss4-roast-profile-automation.md"]="cites_pattern:(tacit|craft|apprentic|embodied|sensory|by feel).{0,200}(formal|spec|codif|rule|controller|explicit|write.?down|written|computable)|(formal|codif|spec|controller|explicit|computable).{0,200}(tacit|craft|apprentic|embodied|sensory)|formality budget;;format_check"

EXPECTED_VERDICT["tc-dss5-pumping-station-dashboard.md"]="None"
CLAIM_ACCURACY["tc-dss5-pumping-station-dashboard.md"]="flaw"  # Dim 8 legibility: the control-room dashboard is scored only on board and regulator readability, while night-shift operators judge incidents by single-pump pressure drift that a roll-up health score hides
KEY_CHECK["tc-dss5-pumping-station-dashboard.md"]="cites_pattern:(operator|control.room|night.shift|3 ?am).{0,200}(legib|illegib|readab|unreadab|translation|opaque|hid|lose|lost|(can.?not|can.t) (see|read)|invisible|obscur|mask|flatten|aggregat|roll.?up|no (criterion|voice|score|weight))|(legib|readab|translation layer|hide|hidden|hides|mask|obscur|flatten|aggregat|roll.?up|rolled.up).{0,200}(operator|control.room|night.shift|drift|single pump|individual pump|per.pump)"

# --- Negative: a well-framed decision ---

EXPECTED_VERDICT["tc-dss6-build-cache-hosting.md"]="None"
CLAIM_ACCURACY["tc-dss6-build-cache-hosting.md"]="sound"  # Build-cache hosting: the operating team decides after asking its users, switching is one URL and was rehearsed, data is regenerable, criteria are measured in a trial — no misframing, so no re-frame hand-off
KEY_CHECK["tc-dss6-build-cache-hosting.md"]="no_pattern:misfram|mis-fram|re-?fram(e|ed|es|ing)|corrected problem statement|Diamond 1|Double Diamond|wrong (kind of )?(problem|question|frame|framing)|wearing the costume|in the costume of;;format_check"
