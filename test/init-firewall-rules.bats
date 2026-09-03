#!/usr/bin/env bats
# @category fast
# Rule-construction tests for devcontainer-config/init-firewall.sh.
#
# WHY THIS SUITE EXISTS. test/cc-isolated-functions.bats reaches this script only
# through `--print-domains`, which exits before any firewall statement runs — so
# every line that actually builds the boundary had zero coverage. Two review passes
# then found three defects in that uncovered region (an unreachable fail-open branch
# under `set -e`, an inert fallback, and a wide-open flush→DROP window), which is
# what this suite regression-guards.
#
# HOW IT RUNS WITHOUT ROOT. The script is executed for real, with `iptables`,
# `ipset`, `ip`, `dig`, `curl`, `aggregate` and `iptables-save` replaced by PATH
# stubs that append their argv to $CMD_LOG and return success. Assertions are made
# against that log, so what is tested is the sequence of commands the script issues —
# which is exactly where the three defects lived. Kernel/netfilter semantics are out
# of scope here and need a privileged container (guides/devcontainer-setup.md).
#
# Usage: bats test/init-firewall-rules.bats

load lib/hermetic-env

setup() {
  pin_hermetic_locale

  FW="$BATS_TEST_DIRNAME/../devcontainer-config/init-firewall.sh"
  TEST_TMPDIR=$(mktemp -d)
  export CMD_LOG="$TEST_TMPDIR/cmds.log"
  : > "$CMD_LOG"

  # Egress profile inputs (the real profiles, so composition stays realistic).
  export CC_EGRESS_DIR="$BATS_TEST_DIRNAME/../devcontainer-config/egress"
  export CC_EGRESS_PROFILE_FILE="$TEST_TMPDIR/profile"
  : > "$CC_EGRESS_PROFILE_FILE"   # base only

  # --- PATH stubs -----------------------------------------------------------
  STUB_DIR="$TEST_TMPDIR/bin"
  mkdir -p "$STUB_DIR"

  # Every stub logs "<name> <args...>" then returns 0 unless a FAIL_* knob is set.
  cat > "$STUB_DIR/iptables" <<'STUB'
#!/usr/bin/env bash
echo "iptables $*" >> "$CMD_LOG"
exit 0
STUB

  cat > "$STUB_DIR/iptables-save" <<'STUB'
#!/usr/bin/env bash
echo "iptables-save $*" >> "$CMD_LOG"
exit 0
STUB

  cat > "$STUB_DIR/ipset" <<'STUB'
#!/usr/bin/env bash
echo "ipset $*" >> "$CMD_LOG"
exit 0
STUB

  cat > "$STUB_DIR/ip" <<'STUB'
#!/usr/bin/env bash
echo "ip $*" >> "$CMD_LOG"
[ "${1:-}" = "route" ] && echo "default via 192.168.65.1 dev eth0"
exit 0
STUB

  cat > "$STUB_DIR/dig" <<'STUB'
#!/usr/bin/env bash
echo "dig $*" >> "$CMD_LOG"
if [ -n "${FAIL_DIG:-}" ]; then exit 9; fi
domain="${!#}"
printf '%s.\t60\tIN\tA\t203.0.113.7\n' "$domain"
exit 0
STUB

  # curl must dispatch on URL: the /meta fetch supplies the ranges, and the two
  # end-of-script probes require example.com to FAIL and api.github.com to SUCCEED.
  cat > "$STUB_DIR/curl" <<'STUB'
#!/usr/bin/env bash
echo "curl $*" >> "$CMD_LOG"
url=""
for a in "$@"; do case "$a" in https://*) url="$a";; esac; done
case "$url" in
  *api.github.com/meta*)
    if [ -n "${FAIL_META:-}" ]; then exit 7; fi
    echo '{"web":["192.30.252.0/22"],"api":["143.55.64.0/20"],"git":["192.30.252.0/22"]}'
    ;;
  *example.com*)       exit 7 ;;   # must be unreachable for the probe to pass
  *api.github.com/zen*) echo "keep it logically awesome" ;;
  *) exit 7 ;;
esac
exit 0
STUB

  cat > "$STUB_DIR/aggregate" <<'STUB'
#!/usr/bin/env bash
cat
STUB

  chmod +x "$STUB_DIR"/*
  export PATH="$STUB_DIR:$PATH"
}

teardown() {
  [ -n "${TEST_TMPDIR:-}" ] && rm -rf "$TEST_TMPDIR"
}

# Line number of the first log entry matching a pattern (empty if absent).
first_line_matching() {
  grep -n -- "$1" "$CMD_LOG" 2>/dev/null | head -1 | cut -d: -f1
}

# --- the resolver-parsing hook (the twice-regressed logic) -------------------

@test "print-resolvers keeps valid IPv4 nameservers" {
  printf 'nameserver 192.168.65.7\nnameserver 8.8.8.8\n' > "$TEST_TMPDIR/rc"
  run bash "$FW" --print-resolvers "$TEST_TMPDIR/rc"
  [ "$status" -eq 0 ]
  [[ "$output" == *"192.168.65.7"* ]]
  [[ "$output" == *"8.8.8.8"* ]]
}

@test "print-resolvers rejects out-of-range octets rather than passing them to iptables" {
  # A `[0-9]{1,3}` shape check accepted these; iptables then treats them as
  # hostnames, fails, and (pre-fix) aborted the rebuild.
  printf 'nameserver 999.999.999.999\nnameserver 256.1.1.1\n' > "$TEST_TMPDIR/rc"
  run bash "$FW" --print-resolvers "$TEST_TMPDIR/rc"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "print-resolvers exits 0 on an IPv6-only resolv.conf (no set -e abort)" {
  # REGRESSION: a bare `var=$(awk|grep|sort)` assignment propagated grep's exit-1
  # through pipefail and killed the script here.
  printf 'nameserver fd00::1\n' > "$TEST_TMPDIR/rc"
  run bash "$FW" --print-resolvers "$TEST_TMPDIR/rc"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "print-resolvers exits 0 when resolv.conf is missing entirely" {
  run bash "$FW" --print-resolvers "$TEST_TMPDIR/does-not-exist"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "inspection hooks never touch iptables" {
  run bash "$FW" --print-domains
  [ "$status" -eq 0 ]
  run bash "$FW" --print-resolvers /etc/resolv.conf
  [ "$status" -eq 0 ]
  # Neither hook may issue a single firewall command.
  [ ! -s "$CMD_LOG" ]
}

# --- full-run rule construction ---------------------------------------------

@test "a successful run sets DROP policies and installs the terminal REJECT" {
  run bash "$FW"
  [ "$status" -eq 0 ]
  grep -q "iptables -P OUTPUT DROP" "$CMD_LOG"
  grep -q "iptables -P INPUT DROP" "$CMD_LOG"
  grep -q "iptables -P FORWARD DROP" "$CMD_LOG"
  grep -q "iptables -A OUTPUT -j REJECT" "$CMD_LOG"
  grep -q "match-set allowed-domains dst,dst -j ACCEPT" "$CMD_LOG"
}

# --- port-scoped allowlist (security review 2026-08-29, finding 5) ------------

@test "the allowlist ipset is address+port, and the OUTPUT accept matches on both" {
  # REGRESSION: a plain `hash:net` matched on `dst` alone, so any allowlisted
  # address was reachable on every port.
  run bash "$FW"
  [ "$status" -eq 0 ]
  grep -q "^ipset create allowed-domains hash:net,port$" "$CMD_LOG"
  run grep -c -- "match-set allowed-domains dst -j ACCEPT" "$CMD_LOG"
  [ "$output" -eq 0 ]
  grep -q -- "-m set --match-set allowed-domains dst,dst -j ACCEPT" "$CMD_LOG"
  # Every member added carries a proto:port; a bare address would be an ipset
  # error on the real kernel and a silent any-port grant in intent.
  run grep -E '^ipset add ' "$CMD_LOG"
  [ -n "$output" ]
  run grep -cvE '^ipset add -exist allowed-domains [0-9./]+,tcp:[0-9]+$' <<<"$output"
  [ "$output" -eq 0 ]
}

@test "GitHub CIDRs are admitted on tcp 443 and tcp 22 only" {
  run bash "$FW"
  [ "$status" -eq 0 ]
  grep -q "^ipset add -exist allowed-domains 192.30.252.0/22,tcp:443$" "$CMD_LOG"
  grep -q "^ipset add -exist allowed-domains 192.30.252.0/22,tcp:22$" "$CMD_LOG"
  grep -q "^ipset add -exist allowed-domains 143.55.64.0/20,tcp:443$" "$CMD_LOG"
  grep -q "^ipset add -exist allowed-domains 143.55.64.0/20,tcp:22$" "$CMD_LOG"
  # Distinct members: the stub's /meta lists one CIDR under two keys, and dedup is
  # `-exist`'s job at add time, so count unique lines rather than raw adds.
  run bash -c "grep -E '^ipset add -exist allowed-domains [0-9./]+/[0-9]+,tcp:' '$CMD_LOG' | sort -u | wc -l"
  [ "$output" -eq 4 ]
  run grep -cE '^ipset add -exist allowed-domains [0-9./]+/[0-9]+,tcp:' "$CMD_LOG"
  cidr_adds="$output"
  run grep -cE '^ipset add -exist allowed-domains [0-9./]+/[0-9]+,tcp:(443|22)$' "$CMD_LOG"
  [ "$output" -eq "$cidr_adds" ]   # no CIDR admitted on any other port
}

@test "a port-less profile entry defaults to tcp 443" {
  # The dig stub resolves everything to 203.0.113.7; base has only port-less entries.
  run bash "$FW"
  [ "$status" -eq 0 ]
  grep -q "^ipset add -exist allowed-domains 203.0.113.7,tcp:443$" "$CMD_LOG"
  run grep -E '^ipset add -exist allowed-domains 203\.0\.113\.7,' "$CMD_LOG"
  [ -n "$output" ]
  run grep -cvE '^ipset add -exist allowed-domains 203\.0\.113\.7,tcp:443$' <<<"$output"
  [ "$output" -eq 0 ]
}

@test "a profile entry with a port suffix is admitted on exactly those ports" {
  # Use a private profile dir so the assertion is about the grammar, not about
  # what the shipped profiles happen to contain today.
  local dir="$TEST_TMPDIR/egress"
  mkdir -p "$dir"
  printf 'api.anthropic.com\nmodels.example:11434,8080\n' > "$dir/base.txt"
  CC_EGRESS_DIR="$dir" run bash "$FW"
  [ "$status" -eq 0 ]
  grep -q "models.example$" <(grep '^dig ' "$CMD_LOG")   # the port suffix is stripped for dig
  grep -q "^ipset add -exist allowed-domains 203.0.113.7,tcp:11434$" "$CMD_LOG"
  grep -q "^ipset add -exist allowed-domains 203.0.113.7,tcp:8080$" "$CMD_LOG"
  grep -q "^ipset add -exist allowed-domains 203.0.113.7,tcp:443$" "$CMD_LOG"   # api.anthropic.com
  run grep -c -- "allowed-domains 203.0.113.7,tcp:" "$CMD_LOG"
  [ "$output" -eq 3 ]
}

@test "the shipped llm profile scopes host.docker.internal to 11434, and only there" {
  echo 'llm' > "$CC_EGRESS_PROFILE_FILE"
  run bash "$FW" --print-entries
  [ "$status" -eq 0 ]
  grep -qE $'^host\\.docker\\.internal\t11434$' <<<"$output"
  grep -qE $'^openrouter\\.ai\t443$' <<<"$output"
  [ ! -s "$CMD_LOG" ]   # an inspection hook, like the other two
}

@test "a malformed profile entry is a hard failure before any network read" {
  local dir="$TEST_TMPDIR/egress"
  mkdir -p "$dir"
  for bad in 'models.example:0' 'models.example:65536' 'models.example:abc' \
             'models.example:443,' 'bad_host:443' 'models.example:443 --extra'; do
    : > "$CMD_LOG"
    printf 'api.anthropic.com\n%s\n' "$bad" > "$dir/base.txt"
    CC_EGRESS_DIR="$dir" run bash "$FW"
    [ "$status" -ne 0 ]
    [[ "$output" == *"malformed egress entry"* ]]
    # Aborted before phase A (no curl/dig) and before the flush; fail-closed trap ran.
    run grep -cE '^(curl|dig|iptables -F)' "$CMD_LOG"
    [ "$output" -eq 0 ]
    grep -q "iptables -P OUTPUT DROP" "$CMD_LOG"
  done
}

# --- narrowed host-network accepts ------------------------------------------

@test "the bridge gateway is admitted on udp/tcp 53 only, with no inbound counterpart" {
  # REGRESSION: `-A INPUT -s <bridge>/24` / `-A OUTPUT -d <bridge>/24` admitted every
  # port to and from every address on the bridge. The ip stub's gateway is
  # 192.168.65.1.
  run bash "$FW"
  [ "$status" -eq 0 ]
  grep -q "^iptables -A OUTPUT -p udp -d 192.168.65.1 --dport 53 -j ACCEPT$" "$CMD_LOG"
  grep -q "^iptables -A OUTPUT -p tcp -d 192.168.65.1 --dport 53 -j ACCEPT$" "$CMD_LOG"
  run grep -cE -- '-[sd] 192\.168\.65\.0/24' "$CMD_LOG"
  [ "$output" -eq 0 ]
  # No other rule names the gateway, and no INPUT accept keys on a source address at all.
  run grep -cE -- '192\.168\.65\.1( |$)' "$CMD_LOG"
  [ "$output" -eq 2 ]
  run grep -cE -- '^iptables -A INPUT -s ' "$CMD_LOG"
  [ "$output" -eq 0 ]
}

@test "the flush-to-DROP window contains no network call" {
  # This is the whole point of the phase A / phase B split: every network read
  # happens BEFORE the flush, so the interval where the chains are empty cannot
  # stall on (or be widened by) curl and dig.
  run bash "$FW"
  [ "$status" -eq 0 ]

  local flush drop meta
  flush=$(first_line_matching "^iptables -F")
  drop=$(first_line_matching "^iptables -P OUTPUT DROP")
  meta=$(first_line_matching "api.github.com/meta")
  [ -n "$flush" ] && [ -n "$drop" ] && [ -n "$meta" ]

  # The GitHub fetch precedes the flush ...
  [ "$meta" -lt "$flush" ]
  # ... and DROP lands immediately after it, with no curl/dig in between.
  [ "$drop" -gt "$flush" ]
  run bash -c "sed -n '${flush},${drop}p' '$CMD_LOG' | grep -cE '^(curl|dig) '"
  [ "$output" -eq 0 ]
}

@test "every domain is resolved before the flush, not during the window" {
  run bash "$FW"
  [ "$status" -eq 0 ]
  local flush last_dig
  flush=$(first_line_matching "^iptables -F")
  last_dig=$(grep -n '^dig ' "$CMD_LOG" | tail -1 | cut -d: -f1)
  [ -n "$last_dig" ]
  [ "$last_dig" -lt "$flush" ]
}

@test "scoped DNS accepts are installed for the configured resolver" {
  # The host's real resolv.conf is used here; assert the rule shape rather than a
  # specific address so the test is not tied to this machine's DNS.
  run bash "$FW"
  [ "$status" -eq 0 ]
  if [ -n "$(bash "$FW" --print-resolvers /etc/resolv.conf)" ]; then
    grep -qE "iptables -A OUTPUT -p udp -d [0-9.]+ --dport 53 -j ACCEPT" "$CMD_LOG"
    grep -qE "iptables -A OUTPUT -p tcp -d [0-9.]+ --dport 53 -j ACCEPT" "$CMD_LOG"
  fi
  # No blanket DNS accept may ever be installed.
  run grep -c -- "-A OUTPUT -p udp --dport 53 -j ACCEPT" "$CMD_LOG"
  [ "$output" -eq 0 ]
}

@test "no blanket outbound SSH accept is installed" {
  # REGRESSION: `--dport 22 -j ACCEPT` to 0.0.0.0/0 was an unconditional tunnel out.
  run bash "$FW"
  [ "$status" -eq 0 ]
  run grep -c -- "--dport 22" "$CMD_LOG"
  [ "$output" -eq 0 ]
}

# --- fail-closed behaviour ---------------------------------------------------

@test "an aborted run forces DROP policies rather than leaving the container open" {
  # REGRESSION: an abort between the flush and the policies left a fresh container
  # with empty chains AND a default-ACCEPT policy — wide open.
  FAIL_META=1 run bash "$FW"
  [ "$status" -ne 0 ]
  grep -q "iptables -P OUTPUT DROP" "$CMD_LOG"
  grep -q "iptables -P INPUT DROP" "$CMD_LOG"
  grep -q "iptables -P FORWARD DROP" "$CMD_LOG"
}

@test "a GitHub fetch failure aborts before the flush, leaving the live ruleset intact" {
  # Phase A runs while the previous firewall is still installed, so a transient
  # outage must not half-build a ruleset.
  FAIL_META=1 run bash "$FW"
  [ "$status" -ne 0 ]
  run grep -c -- "^iptables -F" "$CMD_LOG"
  [ "$output" -eq 0 ]
}

@test "failure to resolve the critical domain aborts and fails closed" {
  FAIL_DIG=1 run bash "$FW"
  [ "$status" -ne 0 ]
  [[ "$output" == *"api.anthropic.com"* ]]
  grep -q "iptables -P OUTPUT DROP" "$CMD_LOG"
}
