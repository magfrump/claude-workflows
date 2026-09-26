#!/usr/bin/env bash
# shellcheck disable=SC2034  # Arrays are used by test files that source this file
# Machine-parseable expected verdicts for architecture-review evaluation fixtures.
# Used by health-check to validate fixture ↔ verdict coverage.
#
# architecture-review produces severity-tagged findings (Structural | Coupling |
# Minor | Informational). The "verdict" here is the expected severity tier,
# checked by finding_match against the **Severity:** lines; adjacent tiers are
# allowed where the SKILL.md scale makes the tier a judgment call. Clean
# negatives carry EXPECTED_VERDICT "None" and use no_severity instead.
# cites_pattern values must not contain ';' (KEY_CHECK splits on it).
# finding_match:<tiers>=<ERE>[&&<ERE>...] needs ONE finding (a "####" block or a
# summary-table row) carrying both a tier from EXPECTED_VERDICT and a line
# matching each ERE outside lines copied from the fixture, so an unrelated
# finding with the right tier cannot pass (2026-09-26 audit T5).

declare -gA EXPECTED_VERDICT
declare -gA CLAIM_ACCURACY
declare -gA KEY_CHECK

# --- Planted defects ---

EXPECTED_VERDICT["tc-arch1-domain-imports-infra.py"]="Structural"
CLAIM_ACCURACY["tc-arch1-domain-imports-infra.py"]="bug"  # Domain PricingService imports and constructs a Postgres adapter
KEY_CHECK["tc-arch1-domain-imports-infra.py"]="finding_match:Structural=dependency (direction|inversion|rule)|invert|domain.{0,60}(infrastructure|psycopg|postgres)|(infrastructure|psycopg|postgres).{0,60}domain;;format_check"

EXPECTED_VERDICT["tc-arch2-circular-modules.ts"]="Structural"
CLAIM_ACCURACY["tc-arch2-circular-modules.ts"]="bug"  # customers <-> billing import each other
KEY_CHECK["tc-arch2-circular-modules.ts"]="finding_match:Structural=circular|cycl|mutual|bidirectional|two-way"

EXPECTED_VERDICT["tc-arch3-god-class.py"]="Structural|Coupling"
CLAIM_ACCURACY["tc-arch3-god-class.py"]="bug"  # AccountService: auth, mail, billing, PDFs, CSV, stats, flags, audit
KEY_CHECK["tc-arch3-god-class.py"]="finding_match:Structural|Coupling=single.responsibility|SRP|god (object|class)|responsibilities"

EXPECTED_VERDICT["tc-arch4-fat-interface.py"]="Coupling|Minor"
CLAIM_ACCURACY["tc-arch4-fat-interface.py"]="bug"  # 15-method BlobStore port; read-only adapter stubs 12 with NotImplementedError
KEY_CHECK["tc-arch4-fat-interface.py"]="finding_match:Coupling|Minor=segregat|NotImplementedError|too (broad|wide|large)|fat (interface|port)|narrow"

EXPECTED_VERDICT["tc-arch5-leaky-gateway.py"]="Coupling|Structural"
CLAIM_ACCURACY["tc-arch5-leaky-gateway.py"]="bug"  # PaymentGateway port returns stripe types; use case catches stripe errors
KEY_CHECK["tc-arch5-leaky-gateway.py"]="finding_match:Coupling|Structural=leak|vendor|provider.specific|stripe.(specific|types?|sdk|error)"

# --- Clean negatives ---

EXPECTED_VERDICT["tc-arch6-clean-ports-adapters.py"]="None"
CLAIM_ACCURACY["tc-arch6-clean-ports-adapters.py"]="clean"  # Correct ports and adapters with a composition root
KEY_CHECK["tc-arch6-clean-ports-adapters.py"]="no_severity:Structural|Coupling;;format_check"

EXPECTED_VERDICT["tc-arch7-internal-fix.patch"]="None"
CLAIM_ACCURACY["tc-arch7-internal-fix.patch"]="skip"  # Private-method bug fix only: Scope Check skip path
KEY_CHECK["tc-arch7-internal-fix.patch"]="no_severity:Structural|Coupling|Minor;;cites_pattern:skipped|out of scope|implementation.only;;format_check"
