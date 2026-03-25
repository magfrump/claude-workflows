# Semantic dimension manifest for yglesias-critique.
# Each dimension maps to a pipe-separated list of keywords (case-insensitive grep).
# A dimension is "covered" if at least one keyword appears in the report body.
#
# Dimensions derive from the 9 cognitive moves in skills/yglesias-critique.md.

declare -gA YGLESIAS_DIMENSIONS

# Move 1: Agree with the goal, demolish the mechanism
YGLESIAS_DIMENSIONS[goal_vs_mechanism]="goal.*mechanism|mechanism.*undermine|values.*lead.*different|goal.*wrong"

# Move 2: Find the boring lever
YGLESIAS_DIMENSIONS[boring_lever]="boring.*lever|unsexy|zoning|licensing|bottleneck|structural.*reform"

# Move 3: Trace the money through the system
YGLESIAS_DIMENSIONS[follow_the_money]="follow the money|trace.*money|subsid|intermediar|overhead|cost.*absorb"

# Move 4: Check political survival
YGLESIAS_DIMENSIONS[political_survival]="election|political.*survival|constituency|repeal|backlash|defend.*policy"

# Move 5: Cost disease
YGLESIAS_DIMENSIONS[cost_disease]="cost disease|costs.*risen|cost.*inflat|stagnate|same.*higher price"

# Move 6: Run the scale test
YGLESIAS_DIMENSIONS[scale_test]="scale|10.million|million people|race to the bottom|resource constraint"

# Move 7: Swap in the implementation org chart
YGLESIAS_DIMENSIONS[org_chart]="org chart|which agency|what authority|track record|bureaucra|implementation"

# Move 8: Find the popular version
YGLESIAS_DIMENSIONS[popular_version]="popular version|unpopular|political cost|80%.*benefit|boring.*popular|default.*lean|opt.in"

# Move 9: Verify facts with calibrated confidence
YGLESIAS_DIMENSIONS[factual_calibration]="confidence|calibrat|probably wrong|probably right|primary source|50%.*accurate|is probably"

# Cross-cutting analytical vocabulary expected in a Yglesias critique
YGLESIAS_DIMENSIONS[policy_lens]="feasib|supply.side|incentive|tradeoff|trade-off|cost-benefit|benefit.*cost|decomposition"

# Minimum number of dimensions that must be covered for a passing report
YGLESIAS_MIN_DIMENSIONS=7
