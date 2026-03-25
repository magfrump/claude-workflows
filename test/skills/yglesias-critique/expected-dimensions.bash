# Semantic dimension manifest for yglesias-critique.
# Each dimension maps to a case-insensitive grep -E pattern that should appear
# in any well-formed Yglesias-style critique.  The patterns are intentionally
# loose — they test that the analytical *perspective* is present, not that
# specific sentences exist.
#
# Sourced by yglesias-critique-dimensions.bats.

declare -gA YGLESIAS_DIMENSIONS

# Move 1 — Agree with goal, demolish mechanism
YGLESIAS_DIMENSIONS["goal_vs_mechanism"]="goal.*(vs|versus|mechanism)|mechanism.*(undermine|fail|problem)|goal.*right.*(but|mechanism)"

# Move 2 — Boring lever
YGLESIAS_DIMENSIONS["boring_lever"]="boring lever|boring.*(intervention|solution|fix)|unsexy|zoning|licensing|regulatory.*(bottleneck|barrier|removal)"

# Move 3 — Follow the money
YGLESIAS_DIMENSIONS["follow_money"]="follow.*(the )?money|trace.*(the )?(dollar|money|spending)|intermediar|who captures|overhead|absorb"

# Move 4 — Political survival / election cycle
YGLESIAS_DIMENSIONS["political_survival"]="election.*(cycle|survive)|political.*(survival|sustain|viability)|constituency|backlash|repealed|defend.*(it|the policy)"

# Move 5 — Cost disease
YGLESIAS_DIMENSIONS["cost_disease"]="cost disease|cost.*(inflation|rising faster)|stagnate|baumol|absorb.*(by|into).*cost"

# Move 6 — Scale test (10 million people)
YGLESIAS_DIMENSIONS["scale_test"]="scale.*(test|break|fail)|10.million|at scale|what happens when.*million|race to the bottom"

# Move 7 — Org chart / implementation
YGLESIAS_DIMENSIONS["org_chart"]="org chart|which agency|who.*(implement|run|execute)|institution.*(capacity|track record)|bureaucra"

# Move 8 — Popular version
YGLESIAS_DIMENSIONS["popular_version"]="popular version|80%.*(benefit|of the way)|20%.*(cost|political)|politically.*viable.*version|default.*(lean|comprehensive)"
