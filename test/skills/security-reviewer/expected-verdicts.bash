#!/usr/bin/env bash
# shellcheck disable=SC2034  # Arrays are used by test files that source this file
# Machine-parseable expected verdicts for security-reviewer evaluation fixtures.
# Used by health-check to validate fixture ↔ verdict coverage.
#
# security-reviewer produces severity-tagged findings per file. The "verdict"
# here is the expected severity tier from the skill's own scale
# (Critical / High / Medium / Low / Informational), checked by finding_match
# against the **Severity:** lines. Adjacent tiers are allowed where SKILL.md's
# rubric makes the tier a judgment call. cites_pattern checks that the report
# names the mechanism or the fix; clean negatives use no_severity instead.
# finding_match:<tiers>=<ERE>[&&<ERE>...] needs ONE finding (a "####" block or a
# summary-table row) carrying both a tier from EXPECTED_VERDICT and a line
# matching each ERE outside lines copied from the fixture, so an unrelated
# finding with the right tier cannot pass (2026-09-26 audit T5).

declare -gA EXPECTED_VERDICT
declare -gA CLAIM_ACCURACY
declare -gA KEY_CHECK

# --- Injection / trust-boundary defects ---

EXPECTED_VERDICT["tc-sec1-sql-injection.py"]="Critical|High"
CLAIM_ACCURACY["tc-sec1-sql-injection.py"]="bug"  # ORDER BY column interpolated from ?sort= (CWE-89)
KEY_CHECK["tc-sec1-sql-injection.py"]="finding_match:Critical|High=sql.?inject|order.?by|sort (param|column|key)|allow.?list|whitelist"

EXPECTED_VERDICT["tc-sec3-path-traversal.go"]="Critical|High"
CLAIM_ACCURACY["tc-sec3-path-traversal.go"]="bug"  # ?file= joined into export path, ../ escapes the user dir (CWE-22)
KEY_CHECK["tc-sec3-path-traversal.go"]="finding_match:Critical|High=travers|\.\./|filepath\.(Rel|Base|IsLocal|Clean)|escap(e|es|ing)[^.]{0,40}(dir|directory|root|base)|outside (the )?[a-z ]{0,20}(dir|directory|root)"

EXPECTED_VERDICT["tc-sec6-unsafe-deserialization.py"]="Critical"
CLAIM_ACCURACY["tc-sec6-unsafe-deserialization.py"]="bug"  # pickle.loads on a client cookie (CWE-502)
KEY_CHECK["tc-sec6-unsafe-deserialization.py"]="finding_match:Critical=remote code|code execution|RCE|arbitrary (code|object)|__reduce__"

# --- Access-control defects ---

EXPECTED_VERDICT["tc-sec2-missing-ownership-check.ts"]="Critical|High"
CLAIM_ACCURACY["tc-sec2-missing-ownership-check.ts"]="bug"  # /invoices/:id not scoped to caller's org (IDOR, CWE-639)
KEY_CHECK["tc-sec2-missing-ownership-check.ts"]="finding_match:Critical|High=IDOR|insecure direct|org(Id|_id)? scop|tenant isolation|cross.?(org|tenant)|(another|other|different) (org|organi[sz]ation|tenant)|(not|isn.t|never|without)( being)? (scoped|filtered|checked|restricted)[^.]{0,30}(caller|user|org|tenant)"

EXPECTED_VERDICT["tc-sec4-fail-open-auth.go"]="Critical|High"
CLAIM_ACCURACY["tc-sec4-fail-open-auth.go"]="bug"  # introspection error calls next handler (CWE-636)
KEY_CHECK["tc-sec4-fail-open-auth.go"]="finding_match:Critical|High=fail.?(open|closed|secure)|default.?allow|(error|err|fail|timeout|outage|unavailab)[^.]{0,80}(next\.ServeHTTP|next handler|\blets?\b|\ballow(s|ed|ing)?\b|pass(es)? through|proceed|continu|unauthenticated)|bypass;;format_check"

# --- Secrets / randomness ---

EXPECTED_VERDICT["tc-sec5-predictable-reset-token.js"]="Critical|High"
CLAIM_ACCURACY["tc-sec5-predictable-reset-token.js"]="bug"  # reset token from Math.random() (CWE-338)
KEY_CHECK["tc-sec5-predictable-reset-token.js"]="finding_match:Critical|High=randomBytes|getRandomValues|randomUUID|CSPRNG|cryptographic(ally)? (secure|random)|predictable"

# --- Clean negatives: look suspicious, are safe ---

EXPECTED_VERDICT["tc-sec7-clean-dynamic-query.ts"]="None"
CLAIM_ACCURACY["tc-sec7-clean-dynamic-query.ts"]="clean"  # SQL built by concatenation, but only from allowlist + placeholders
KEY_CHECK["tc-sec7-clean-dynamic-query.ts"]="no_severity:Critical|High;;format_check"

EXPECTED_VERDICT["tc-sec8-clean-exec.go"]="None"
CLAIM_ACCURACY["tc-sec8-clean-exec.go"]="clean"  # exec with request input, but argv (no shell) and 40-hex regex
KEY_CHECK["tc-sec8-clean-exec.go"]="no_severity:Critical|High;;format_check;;cites_pattern:argv|argument (vector|list|array|slice)|no shell|without (a |invoking a |spawning a )?shell|not (passed )?(through|via|to) a shell|sh -c|shell (metacharacter|interpret|expansion|injection)|anchored|40.?(hex|char)|\[0-9a-f\]\{40\}"
