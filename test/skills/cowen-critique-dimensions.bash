# Semantic dimension manifest for cowen-critique.
# Each dimension maps to a pipe-separated list of keywords (case-insensitive grep).
# A dimension is "covered" if at least one keyword appears in the report body.
#
# Dimensions derive from the 9 cognitive moves in skills/cowen-critique.md.

declare -gA COWEN_DIMENSIONS

# Move 1: Try the boring explanation first
COWEN_DIMENSIONS[boring_explanation]="boring|mundane|ordinary|least dramatic"

# Move 2: Invert the claim and see what survives
COWEN_DIMENSIONS[inversion]="invert|inversion|opposite|flip|counter-argument"

# Move 3: Follow revealed preferences, ignore stated ones
COWEN_DIMENSIONS[revealed_preferences]="revealed preference|stated preference|behavior.*contradicts|what they actually do"

# Move 4: Push the argument to its logical extreme
COWEN_DIMENSIONS[logical_extreme]="logical extreme|push.*further|absurd|reductio|extreme version"

# Move 5: Find the cross-domain analogy
COWEN_DIMENSIONS[cross_domain_analogy]="analogy|cross-domain|parallel.*domain|structural.*similarity"

# Move 6: Ask what the market is telling you
COWEN_DIMENSIONS[market_signal]="market|price signal|capital.*flow|undervalued|market.*wrong"

# Move 7: Decompose the claim into sub-claims
COWEN_DIMENSIONS[decomposition]="sub-claim|decompose|constituent|bundled together|independently"

# Move 8: Notice what is contingent vs natural
COWEN_DIMENSIONS[contingent_assumptions]="contingent|takes? for granted|background assumption|specific to a time"

# Move 9: Calibrate uncertainty honestly
COWEN_DIMENSIONS[calibrated_uncertainty]="confidence|uncertain|calibrat|60% likely|I don't know"

# Cross-cutting analytical vocabulary expected in a Cowen critique
COWEN_DIMENSIONS[economic_lens]="tradeoff|trade-off|cost|incentive|marginal"

# Minimum number of dimensions that must be covered for a passing report
COWEN_MIN_DIMENSIONS=7
