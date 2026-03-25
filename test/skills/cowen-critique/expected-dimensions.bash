# Semantic dimension manifest for cowen-critique.
# Each dimension maps to a case-insensitive grep -E pattern that should appear
# in any well-formed Cowen-style critique.  The patterns are intentionally
# loose — they test that the analytical *perspective* is present, not that
# specific sentences exist.
#
# Sourced by cowen-critique-dimensions.bats.

declare -gA COWEN_DIMENSIONS

# Move 1 — Try the boring explanation first
COWEN_DIMENSIONS["boring_explanation"]="boring explanation|mundane|ordinary.*(explanation|account)"

# Move 2 — Invert the claim
COWEN_DIMENSIONS["inversion"]="invert|inversion|opposite|flip.*thesis|stress.test"

# Move 3 — Revealed vs stated preferences
COWEN_DIMENSIONS["revealed_preferences"]="revealed preference|stated preference|behavior.*(contradict|match|diverge)|what.*(people|they) actually (do|spend)"

# Move 4 — Push to logical extreme
COWEN_DIMENSIONS["logical_extreme"]="extreme|push.*further|reductio|absurd|boundary condition|over.built|over.engineer|blind spot|significant.*gap"

# Move 5 — Cross-domain analogy
COWEN_DIMENSIONS["cross_domain_analogy"]="analog|parallel.*(from|in)|cross.domain|different domain|structural.*similarity"

# Move 6 — Market signals
COWEN_DIMENSIONS["market_signal"]="market.*(tell|signal|say|behav)|price.*signal|capital.*flow|why.*market"

# Move 7 — Decompose claims
COWEN_DIMENSIONS["decomposition"]="decompos|sub.claim|constituent|break.*(apart|down|into)|bundled together"

# Move 8 — Contingent assumptions
COWEN_DIMENSIONS["contingent_assumptions"]="contingent|assumption.*(draft|author|argument)|take.*for granted|specific to.*(time|place|culture)"

# Move 9 — Calibrate uncertainty
COWEN_DIMENSIONS["uncertainty_calibration"]="uncertain|confidence level|calibrat|don.t know|[0-9]+%.*(likely|sure|confident)"
