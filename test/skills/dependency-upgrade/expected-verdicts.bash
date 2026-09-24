#!/usr/bin/env bash
# shellcheck disable=SC2034  # Arrays are used by test files that source this file
# Machine-parseable expected verdicts for dependency-upgrade fixtures.
# Used by health-check to validate fixture ↔ verdict coverage.
#
# Each fixture is a self-contained upgrade request for an INVENTED package: the
# manifest entry, every call site, and the complete release notes between the
# two versions. Real packages would let the model answer from memory and would
# contradict the invented changelog. Five fixtures each plant ONE decisive fact
# that SKILL.md's Analysis steps should catch; one negative has breaking
# changes that touch only APIs the project does not call.
#
# dependency-upgrade grades with Summary field lines:
#   **Recommendation:** Upgrade now | Upgrade soon | Defer | Don't upgrade
#   **Breaking change impact:** None | Mechanical | Moderate | Significant
#   **Audit state:** <as-of timestamp> | Consumed from ... | Unverified
# Field checks compare the leading words and pass if ANY such line matches, so
# the fact-specific cites_pattern is the real signal. "Don't" is spelled
# "Don.t" so a curly apostrophe also matches.
#
# Check formats used here (separated by ;; — so no pattern may contain ";"):
#   cites_pattern:<ERE>      — report matches <ERE> (case-insensitive, per line)
#   no_pattern:<ERE>         — report never matches <ERE>
#   field_match:<F>=<vals>   — some **<F>:** line starts with one of <vals>
#   no_field:<F>=<vals>      — no **<F>:** line starts with one of <vals>
#   format_check             — dependency-upgrade-format.bats passes
#
# The harness gives no shell, repo or web access, so SKILL.md's Execution
# evidence protocol can never be satisfied. Where the protocol is well defined
# it is checked: **Audit state:** must be Unverified, the rollback rehearsal box
# must not be ticked, and no Execution Evidence row may report an exit code for
# a package-manager command (tc-dep2, tc-dep6).
#
# EXPECTED_VERDICT holds the expected Recommendation for readers; the checks
# themselves are the field_match/no_field entries in KEY_CHECK.

declare -gA EXPECTED_VERDICT
declare -gA CLAIM_ACCURACY
declare -gA KEY_CHECK

# --- Planted decisive facts, one per fixture ---

EXPECTED_VERDICT["tc-dep1-http-client.md"]="Upgrade soon|Defer"
CLAIM_ACCURACY["tc-dep1-http-client.md"]="flaw"  # Breaking change to a called API: 4.0 makes `timeout` seconds, the project passes timeout: 5000 and 30000 (ms) — ~83 min / ~8.3 h once upgraded
KEY_CHECK["tc-dep1-http-client.md"]="field_match:Recommendation=Upgrade soon|Defer;;field_match:Breaking change impact=Mechanical|Moderate|Significant;;cites_pattern:timeout:? ?5\b|timeout:? ?30\b|(5000|30000|30,000|5,000).{0,150}(seconds|minutes|hours)|(seconds|minutes|hours).{0,150}(5000|30000|30,000|5,000)|83 min|8\.3 h|1\.4 h;;format_check"

EXPECTED_VERDICT["tc-dep2-archive-import.md"]="Upgrade now"
CLAIM_ACCURACY["tc-dep2-archive-import.md"]="flaw"  # Security advisory fixed only in the target: TARN-2026-0117 path traversal in extract_all(), which the project calls on bundles any signed-in account uploads
KEY_CHECK["tc-dep2-archive-import.md"]="field_match:Recommendation=Upgrade now;;cites_pattern:(TARN-2026-0117|traversal|extract_all|outside the (destination|workspace|target)).{0,200}(upload|import_bundle|import route|/bundles/import|signed.in|any account|attacker|exploitable|reachable)|(upload|import_bundle|/bundles/import|signed.in|attacker|exploitable|reachable).{0,200}(TARN-2026-0117|traversal|extract_all|outside the (destination|workspace|target));;field_match:Audit state=Unverified;;no_pattern:\[x\] *Rehearsed;;no_pattern:^\|[^|]*(pip|uv|poetry|npm|audit)[^|]*\| *0 *\|;;format_check"

EXPECTED_VERDICT["tc-dep3-invoice-renderer.md"]="Defer|Don't upgrade"
CLAIM_ACCURACY["tc-dep3-invoice-renderer.md"]="flaw"  # New minimum runtime not met: ledgerline 2.0 requires Node 22 and throws at import, the Dockerfile and CI run node:20-alpine
KEY_CHECK["tc-dep3-invoice-renderer.md"]="field_match:Recommendation=Defer|Don.t upgrade;;cites_pattern:(node|runtime|image|dockerfile|ci)[^0-9]{0,25}20.{0,150}22|22.{0,150}(node|runtime|image|dockerfile|ci)[^0-9]{0,25}20\b;;format_check"

EXPECTED_VERDICT["tc-dep4-signup-forms.md"]="Defer|Don't upgrade"
CLAIM_ACCURACY["tc-dep4-signup-forms.md"]="flaw"  # Peer dependency conflict: formwright 6 needs React 19, datepane 3.1.0 (latest) peers on React ^18
KEY_CHECK["tc-dep4-signup-forms.md"]="field_match:Recommendation=Defer|Don.t upgrade;;cites_pattern:datepane.{0,200}(react 18|\^18|conflict|incompatib|block|peer|does(n.t| not) support)|(conflict|incompatib|block|peer).{0,200}datepane"

EXPECTED_VERDICT["tc-dep5-analytics-orm.md"]="Any"
CLAIM_ACCURACY["tc-dep5-analytics-orm.md"]="flaw"  # Major jump must step through 2.x: 3.0 drops the 1.x _strata_meta reader and removes migrate-meta, so 1.8 → 3.2 in one change breaks `strata upgrade head` on prod
KEY_CHECK["tc-dep5-analytics-orm.md"]="no_field:Breaking change impact=None;;cites_pattern:(2\.[0-9x]|v2|2 ?x).{0,150}(first|intermediate|stepping|step through|then (upgrade|move|bump|go)|before)|(intermediate|two.step|two.hop|two.stage|stepping stone|step through|via|through) .{0,150}(2\.[0-9x]|v2)|migrate.meta.{0,150}(before|first|prior to|while (still )?on|under 2)"

# --- Negative: breaking changes touch only APIs the project does not call ---

EXPECTED_VERDICT["tc-dep6-thumbnail-service.md"]="Upgrade now|Upgrade soon|Defer"
CLAIM_ACCURACY["tc-dep6-thumbnail-service.md"]="sound"  # Every 5.0 break (stream(), composite(), cache(false), Node 16/18) is unused or already met; the project calls only open/resize/toFile on Node 22
KEY_CHECK["tc-dep6-thumbnail-service.md"]="no_field:Recommendation=Don.t upgrade;;no_field:Breaking change impact=Moderate|Significant;;no_pattern:^\|[^|]*(stream|composite|cache\(|node\.?js 1[68])[^|]*\| *\`?(src|test)/;;field_match:Audit state=Unverified;;no_pattern:\[x\] *Rehearsed;;no_pattern:^\|[^|]*(npm|yarn|pnpm|audit)[^|]*\| *0 *\|;;format_check"
