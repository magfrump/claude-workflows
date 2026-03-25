# Shared keyword arrays for critic semantic dimension tests.
# Load with: load ../critic-dimensions  (from a critic subdirectory)
#
# Each array lists keywords that MUST appear in a well-formed critique
# of the corresponding type.  These are not exhaustive — they represent
# the semantic dimensions that distinguish each critic persona.

# Cowen-style critique: economist reasoning, stress-testing arguments
COWEN_DIMENSION_KEYWORDS=(
  "inversion"       # What Survives the Inversion
  "boring"          # The Boring Explanation
  "revealed"        # Revealed vs. Stated preferences
  "analogy"         # Cross-domain analogy
  "contingent"      # Contingent Assumptions
  "market"          # What the Market Says
  "sub-claim"       # Argument decomposition into sub-claims
)

# Yglesias-style critique: policy mechanism, institutional analysis
YGLESIAS_DIMENSION_KEYWORDS=(
  "mechanism"       # The Goal vs. the Mechanism
  "lever"           # The Boring Lever
  "money"           # Follow the Money
  "scale"           # The Scale Test
  "adoption"        # Political Survival / Adoption Viability
  "cost disease"    # The Cost Disease Check
  "org chart"       # The Org Chart — institutional analysis
)

# Helper: assert that a report contains all keywords from a given array.
# Args: $1 = report content variable name, $2..N = keywords
assert_dimension_keywords_present() {
  local content="$1"; shift
  local missing=()
  for kw in "$@"; do
    if ! echo "$content" | grep -qi "$kw"; then
      missing+=("$kw")
    fi
  done
  if [ ${#missing[@]} -gt 0 ]; then
    echo "Missing dimension keywords: ${missing[*]}" >&2
    return 1
  fi
}
