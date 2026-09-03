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
# `ipset`, `ip`, `dig`, `curl`, `aggregate`, `iptables-save`, `dnsmasq`, `pkill`
# and `id` replaced by PATH stubs that append their argv to $CMD_LOG and return
# success. Assertions are made
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

  # --- filtering-resolver stubs (decision log #39) -----------------------------
  # The script writes its dnsmasq config and pidfile to overridable paths.
  export CC_DNSMASQ_CONF="$TEST_TMPDIR/dnsmasq.d/cc-allowlist.conf"
  export CC_DNSMASQ_PIDFILE="$TEST_TMPDIR/cc-dnsmasq.pid"

  # `id -u dnsmasq` must yield a non-zero uid; everything else passes through.
  cat > "$STUB_DIR/id" <<'STUB'
#!/usr/bin/env bash
if [ "${1:-}" = "-u" ] && [ "${2:-}" = "dnsmasq" ]; then echo 999; exit 0; fi
exec /usr/bin/id "$@"
STUB

  # dnsmasq daemonises and writes its pidfile before the parent exits; the stub
  # records a pid that is alive for the rest of the run (the script's own) so the
  # liveness check after start passes.
  cat > "$STUB_DIR/dnsmasq" <<'STUB'
#!/usr/bin/env bash
echo "dnsmasq $*" >> "$CMD_LOG"
for a in "$@"; do case "$a" in --pid-file=*) echo "$PPID" > "${a#--pid-file=}";; esac; done
exit 0
STUB

  cat > "$STUB_DIR/pkill" <<'STUB'
#!/usr/bin/env bash
echo "pkill $*" >> "$CMD_LOG"
exit 1
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
  grep -q "match-set allowed-domains dst -j ACCEPT" "$CMD_LOG"
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
    grep -qE "iptables -A OUTPUT -p udp -d [0-9.]+ --dport 53 -m owner --uid-owner 999 -j ACCEPT" "$CMD_LOG"
    grep -qE "iptables -A OUTPUT -p tcp -d [0-9.]+ --dport 53 -m owner --uid-owner 999 -j ACCEPT" "$CMD_LOG"
  fi
  # No blanket DNS accept may ever be installed.
  run grep -c -- "-A OUTPUT -p udp --dport 53 -j ACCEPT" "$CMD_LOG"
  [ "$output" -eq 0 ]
}

# --- the filtering resolver (decision log #39) --------------------------------

@test "print-dnsmasq-conf has no default upstream and one server line per allowlisted domain" {
  printf 'nameserver 127.0.0.11\n' > "$TEST_TMPDIR/rc"
  run bash "$FW" --print-dnsmasq-conf "$TEST_TMPDIR/rc"
  [ "$status" -eq 0 ]
  # The property that closes finding 6: nothing is forwarded by default.
  run grep -cE '^server=[^/]' <<< "$output"
  [ "$output" -eq 0 ]
  run bash "$FW" --print-dnsmasq-conf "$TEST_TMPDIR/rc"
  [[ "$output" == *"no-resolv"* ]]
  [[ "$output" == *"no-hosts"* ]]
  [[ "$output" == *"bind-interfaces"* ]]
  [[ "$output" == *"listen-address=127.0.0.1"* ]]
  local d
  while read -r d; do
    [[ "$output" == *"server=/$d/127.0.0.11"* ]]
  done < <(bash "$FW" --print-domains)
  # GitHub arrives by CIDR, not by profile, so its zones must be added explicitly.
  [[ "$output" == *"server=/github.com/127.0.0.11"* ]]
  [[ "$output" == *"server=/githubusercontent.com/127.0.0.11"* ]]
  # And only the whitelisted names: no wildcard/catch-all line.
  [[ "$output" != *"server=/#/"* ]]
  [[ "$output" != *"address=/#/"* ]]
}

@test "print-dnsmasq-conf strips a :port suffix from profile entries" {
  printf 'nameserver 10.0.0.2\n' > "$TEST_TMPDIR/rc"
  mkdir -p "$TEST_TMPDIR/egress"
  printf 'api.anthropic.com\nexample.test:8443\n' > "$TEST_TMPDIR/egress/base.txt"
  CC_EGRESS_DIR="$TEST_TMPDIR/egress" run bash "$FW" --print-dnsmasq-conf "$TEST_TMPDIR/rc"
  [ "$status" -eq 0 ]
  [[ "$output" == *"server=/example.test/10.0.0.2"* ]]
  [[ "$output" != *"8443"* ]]
}

@test "print-dnsmasq-conf with no IPv4 resolver emits zero server lines (everything REFUSED)" {
  # The DNS else-branch must stay fail-closed at the resolver too: no upstream is
  # ever invented, so every name is REFUSED rather than forwarded somewhere.
  printf 'nameserver fd00::1\n' > "$TEST_TMPDIR/rc"
  run bash "$FW" --print-dnsmasq-conf "$TEST_TMPDIR/rc"
  [ "$status" -eq 0 ]
  [[ "$output" == *"no-resolv"* ]]
  run grep -c '^server=' <<< "$output"
  [ "$output" -eq 0 ]
}

@test "print-dnsmasq-conf refuses a non-hostname entry rather than emitting it as config" {
  printf 'nameserver 10.0.0.2\n' > "$TEST_TMPDIR/rc"
  mkdir -p "$TEST_TMPDIR/egress"
  printf 'api.anthropic.com\nbad/entry#\n' > "$TEST_TMPDIR/egress/base.txt"
  CC_EGRESS_DIR="$TEST_TMPDIR/egress" run bash "$FW" --print-dnsmasq-conf "$TEST_TMPDIR/rc"
  [ "$status" -eq 0 ]
  [[ "$output" == *"server=/api.anthropic.com/10.0.0.2"* ]]
  # The entry may appear in the warning, but never as a directive.
  [[ "$output" != *"server=/bad"* ]]
  [[ "$output" == *"WARNING: not a hostname"* ]]
}

@test "inspection hooks (dnsmasq-conf included) never touch iptables or start a daemon" {
  run bash "$FW" --print-dnsmasq-conf /etc/resolv.conf
  [ "$status" -eq 0 ]
  [ ! -s "$CMD_LOG" ]
  [ ! -e "$CC_DNSMASQ_PIDFILE" ]
}

@test "a full run writes the dnsmasq config and starts exactly one instance as the dnsmasq user" {
  run bash "$FW"
  [ "$status" -eq 0 ]
  [ -s "$CC_DNSMASQ_CONF" ]
  grep -q '^no-resolv$' "$CC_DNSMASQ_CONF"
  grep -q '^user=dnsmasq$' "$CC_DNSMASQ_CONF"
  run grep -cE '^server=[^/]' "$CC_DNSMASQ_CONF"
  [ "$output" -eq 0 ]
  run grep -c '^dnsmasq ' "$CMD_LOG"
  [ "$output" -eq 1 ]
  grep -q -- "--conf-file=$CC_DNSMASQ_CONF" "$CMD_LOG"
  grep -q -- "--pid-file=$CC_DNSMASQ_PIDFILE" "$CMD_LOG"
}

@test "upstream port 53 is owner-scoped: only the dnsmasq uid and root, never everyone" {
  run bash "$FW"
  [ "$status" -eq 0 ]
  # nat: every non-exempt flow is REDIRECTed to dnsmasq, inserted AHEAD of the
  # restored Docker DNAT so 127.0.0.11:53 cannot be claimed by the embedded resolver first.
  grep -q "iptables -t nat -N CC_DNS" "$CMD_LOG"
  grep -q "iptables -t nat -A CC_DNS -m owner --uid-owner 999 -j RETURN" "$CMD_LOG"
  grep -q "iptables -t nat -A CC_DNS -m owner --uid-owner 0 -j RETURN" "$CMD_LOG"
  grep -q "iptables -t nat -A CC_DNS -p udp -j REDIRECT --to-ports 53" "$CMD_LOG"
  grep -q "iptables -t nat -A CC_DNS -p tcp -j REDIRECT --to-ports 53" "$CMD_LOG"
  grep -q "iptables -t nat -I OUTPUT 1 -p udp --dport 53 -j CC_DNS" "$CMD_LOG"
  grep -q "iptables -t nat -I OUTPUT 1 -p tcp --dport 53 -j CC_DNS" "$CMD_LOG"
  # filter: any scoped resolver accept carries an owner match; none is unscoped.
  run grep -cE -- "-A OUTPUT -p (udp|tcp) -d [0-9.]+ --dport 53 -j ACCEPT" "$CMD_LOG"
  [ "$output" -eq 0 ]
  if [ -n "$(bash "$FW" --print-resolvers /etc/resolv.conf)" ]; then
    grep -qE -- "-A OUTPUT -p udp -d [0-9.]+ --dport 53 -m owner --uid-owner 0 -j ACCEPT" "$CMD_LOG"
  fi
  # The guard chain rejects everything that is neither dnsmasq nor root.
  grep -q "iptables -N CC_DNS_GUARD" "$CMD_LOG"
  grep -q "iptables -A CC_DNS_GUARD -m owner --uid-owner 999 -j RETURN" "$CMD_LOG"
  grep -q "iptables -A CC_DNS_GUARD -m owner --uid-owner 0 -j RETURN" "$CMD_LOG"
  grep -q "iptables -A CC_DNS_GUARD -j REJECT" "$CMD_LOG"
}

@test "the 127.0.0.11 bypass reject precedes the loopback accept" {
  # Docker DNATs the embedded resolver off port 53, so the guard must cover ALL
  # ports on 127.0.0.11 and must come BEFORE `-o lo -j ACCEPT`, which admits
  # anything loopback-bound.
  run bash "$FW"
  [ "$status" -eq 0 ]
  local guard lo udp53 tcp53
  guard=$(first_line_matching "^iptables -A OUTPUT -d 127.0.0.11 -j CC_DNS_GUARD$")
  udp53=$(first_line_matching "^iptables -A OUTPUT -p udp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD$")
  tcp53=$(first_line_matching "^iptables -A OUTPUT -p tcp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD$")
  lo=$(first_line_matching "^iptables -A OUTPUT -o lo -j ACCEPT$")
  [ -n "$guard" ] && [ -n "$udp53" ] && [ -n "$tcp53" ] && [ -n "$lo" ]
  [ "$guard" -lt "$lo" ]
  [ "$udp53" -lt "$lo" ]
  [ "$tcp53" -lt "$lo" ]
  # And the chain exists before anything jumps to it.
  local chain
  chain=$(first_line_matching "^iptables -N CC_DNS_GUARD$")
  [ "$chain" -lt "$guard" ]
}

@test "a re-run kills the previous dnsmasq by pidfile and does not double-start" {
  # A real process whose comm is `dnsmasq` (a renamed sleep), so the pidfile
  # check that guards against killing an unrelated pid is exercised for real.
  mkdir -p "$TEST_TMPDIR/fake"
  cp "$(command -v sleep)" "$TEST_TMPDIR/fake/dnsmasq"
  "$TEST_TMPDIR/fake/dnsmasq" 300 &
  local old=$!
  echo "$old" > "$CC_DNSMASQ_PIDFILE"
  run bash "$FW"
  [ "$status" -eq 0 ]
  # The old instance is gone ...
  run kill -0 "$old"
  [ "$status" -ne 0 ]
  # ... a stop precedes the single start ...
  local pk st
  pk=$(first_line_matching "^pkill ")
  st=$(first_line_matching "^dnsmasq ")
  [ -n "$pk" ] && [ -n "$st" ] && [ "$pk" -lt "$st" ]
  run grep -c '^dnsmasq ' "$CMD_LOG"
  [ "$output" -eq 1 ]
  # ... and a second consecutive run still starts exactly one more.
  run bash "$FW"
  [ "$status" -eq 0 ]
  run grep -c '^dnsmasq ' "$CMD_LOG"
  [ "$output" -eq 2 ]
}

@test "a missing dnsmasq user aborts before the flush, leaving the live ruleset intact" {
  cat > "$STUB_DIR/id" <<'STUB'
#!/usr/bin/env bash
if [ "${1:-}" = "-u" ] && [ "${2:-}" = "dnsmasq" ]; then exit 1; fi
exec /usr/bin/id "$@"
STUB
  run bash "$FW"
  [ "$status" -ne 0 ]
  [[ "$output" == *"dnsmasq"* ]]
  run grep -c -- "^iptables -F" "$CMD_LOG"
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
