#!/usr/bin/env bash
# Verdict logic for the CRB egress preflight — extracted so it can be TESTED.
#
# WHY THIS FILE EXISTS. The preflight is the control that makes the arm's numbers
# meaningful (an agent that can fetch the merged PR scores well for the wrong
# reason) and that keeps ANTHROPIC_API_KEY out of a hostile fork's reach. It ran
# inline in run-host.sh, where `test/crb-egress-config.bats` could pin that the
# legs *existed* but nothing pinned what they *concluded*. The 2026-08-19
# test-strategy pass proved the gap by mutation: widening leg 2 to accept HTTP
# 200, neutering leg 3 to `[ -n "$direct" ]`, and dropping `--internal` from the
# network create each left 37/37 tests green with all three "ok" lines still
# printed. A control whose verdicts no test can see is a control that can be
# deleted by accident.
#
# Same move `scripts/crb-cell-status.py` made out of the same runner, for the
# same reason: the rules live where they can have fixtures.
#
# Usage:  crb-egress-verdict.sh <leg> <observed>
# Exit:   0 = leg passed · 1 = leg FAILED (do not spend) · 2 = usage error.
#
# `<observed>` is the curl `%{http_code}` for the http legs ("000" when curl
# could not connect at all), or the literal network-create command line for the
# `internal-net` leg.
set -uo pipefail

usage() {
  cat >&2 <<'USAGE'
usage: crb-egress-verdict.sh <leg> <observed>
  legs:
    api-reachable   <http_code>  api.anthropic.com THROUGH the proxy must answer
    filter-blocks   <http_code>  a non-allowlisted host through the proxy must be refused
    no-direct-route <http_code>  the same host with NO proxy must be unreachable
    plain-http      <http_code>  a non-allowlisted host over plain HTTP must be refused
    internal-net    <cmdline>    the network-create must actually be --internal
USAGE
  exit 2
}

[ $# -eq 2 ] || usage
leg=$1; observed=$2
[ -n "$leg" ] || usage

case "$leg" in
  api-reachable)
    # Any HTTP status proves the tunnel; 401 is the expected answer to an
    # unauthenticated GET and we deliberately do not send the key. Only "no
    # answer at all" fails. This leg must pass FIRST — legs 2 and 4 accept
    # "000" as a refusal, and "000" is also what an unreachable proxy returns,
    # so on their own they cannot tell a working filter from a dead proxy.
    if [ "$observed" = "000" ]; then
      echo "FAIL api-reachable: api.anthropic.com unreachable through the proxy — every cell would fail"
      exit 1
    fi
    echo "ok  api.anthropic.com reachable through the proxy (HTTP $observed)"
    ;;
  filter-blocks|plain-http)
    # 403 is tinyproxy's filter refusal; 000 is a connect-level refusal. Any
    # 2xx/3xx means the request was SERVED — the allowlist is not filtering and
    # the answer key is reachable from a review cell.
    case "$observed" in
      403|000)
        echo "ok  non-allowlisted host refused ($leg, HTTP $observed)" ;;
      *)
        echo "FAIL $leg: non-allowlisted host returned HTTP $observed — the allowlist is NOT filtering."
        echo "     The answer key is reachable from a review cell; refusing to spend."
        exit 1 ;;
    esac
    ;;
  no-direct-route)
    # With the proxy env removed there must be NO route at all, so a cell that
    # ignores HTTPS_PROXY (curl, git, any subprocess) is still contained.
    # Strictly 000: any status means something answered.
    if [ "$observed" != "000" ]; then
      echo "FAIL no-direct-route: reached a non-allowlisted host (HTTP $observed) with NO proxy env — the network is not internal."
      exit 1
    fi
    echo "ok  non-allowlisted host unroutable without the proxy (network is --internal)"
    ;;
  internal-net)
    # The single flag the whole containment story rests on. Without --internal
    # the network routes to the internet directly and every other leg still
    # passes, because they all go through the proxy by construction.
    case "$observed" in
      *--internal*)
        echo "ok  network created --internal" ;;
      *)
        echo "FAIL internal-net: network was created WITHOUT --internal — containers would route directly."
        exit 1 ;;
    esac
    ;;
  *)
    usage ;;
esac
exit 0
