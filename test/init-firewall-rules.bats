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
  #
  # iptables additionally keeps a tiny policy model in $CMD_LOG.policies so that
  # `-S` prints `-P <chain> <policy>` lines consistent with every prior `-P` call —
  # that is what the fail-closed trap reads back to verify its own DROPs. FAIL_POLICY
  # makes `-P` a silent no-op (exit 0, nothing recorded), modelling a lost xtables
  # lock: the call "succeeds" but the policy stays ACCEPT.
  cat > "$STUB_DIR/iptables" <<'STUB'
#!/usr/bin/env bash
echo "iptables $*" >> "$CMD_LOG"
# ARGV VALIDATION. This stub used to accept any argv, so a rule that real iptables
# refuses passed all 74 tests and failed at container start instead (2026-09-09:
# `! -d A ! -d B` -> "multiple -d flags not allowed", which bricked the boundary).
# Full grammar is out of scope, but a repeated single-value selector is exactly the
# class that bit us and is cheap to catch.
for _f in -s -d -p -i -o --dport --sport; do
  _n=0; for _a in "$@"; do [ "$_a" = "$_f" ] && _n=$((_n+1)); done
  if [ "$_n" -gt 1 ]; then
    echo "iptables: multiple $_f flags not allowed" >&2
    exit 2
  fi
done
# NO_REDIRECT models a missing CC_SNI jump: `-C` (rule-exists check) reports absent.
if [ -n "${NO_REDIRECT:-}" ] && printf '%s\n' "$@" | grep -qx -- '-C' && printf '%s\n' "$@" | grep -qx -- 'CC_SNI'; then exit 1; fi
# NO_RULE=<chain>: any `-C` naming that chain reports absent (filter or nat).
if [ -n "${NO_RULE:-}" ] && printf '%s\n' "$@" | grep -qx -- '-C' && printf '%s\n' "$@" | grep -qx -- "$NO_RULE"; then exit 1; fi
POL="$CMD_LOG.policies"
args=("$@")
i=0
while [ "$i" -lt "${#args[@]}" ]; do
  case "${args[$i]}" in
    -w) i=$((i+2)); continue ;;            # `-w <seconds>`: skip the lock wait
    -P)
      if [ -z "${FAIL_POLICY:-}" ]; then
        echo "${args[$((i+1))]} ${args[$((i+2))]}" >> "$POL"
      fi
      exit 0 ;;
    -S)
      for chain in INPUT FORWARD OUTPUT; do
        pol=$(grep "^$chain " "$POL" 2>/dev/null | tail -1 | cut -d' ' -f2)
        echo "-P $chain ${pol:-ACCEPT}"
      done
      exit 0 ;;
  esac
  i=$((i+1))
done
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
# `ip -4 route get <gw>`: the source address the kernel would choose for an off-box
# destination, i.e. the container's own address — the one both daemons bind and both
# nat chains DNAT to. NO_CONTAINER_IP models a container with no derivable IPv4 source;
# BAD_CONTAINER_IP models a malformed one reaching the octet grammar;
# CONTAINER_IP_OVERRIDE models a container that came up on a different address, which
# is what proves the emitted rules track the derived value instead of a literal.
if [ "${1:-}" = "-4" ] && [ "${2:-}" = "route" ] && [ "${3:-}" = "get" ]; then
  if [ -n "${BAD_CONTAINER_IP:-}" ]; then
    echo "192.168.65.1 via 192.168.65.1 dev eth0 src 999.999.999.999 uid 0"
  elif [ -z "${NO_CONTAINER_IP:-}" ]; then
    echo "192.168.65.1 via 192.168.65.1 dev eth0 src ${CONTAINER_IP_OVERRIDE:-172.17.0.2} uid 0"
  fi
fi
# `ip -6 addr show scope global`: HAS_GLOBAL_V6 models a container with a routable v6 address.
if [ "${1:-}" = "-6" ] && [ -n "${HAS_GLOBAL_V6:-}" ]; then echo "    inet6 2001:db8::2/64 scope global"; fi
exit 0
STUB

  # SLOW_DIG parks the first resolution for a long time (bounded, so a broken
  # signal path fails the test rather than hanging it) — the signal test kills the
  # script while it is stuck here.
  cat > "$STUB_DIR/dig" <<'STUB'
#!/usr/bin/env bash
echo "dig $*" >> "$CMD_LOG"
if [ -n "${FAIL_DIG:-}" ]; then exit 9; fi
if [ -n "${SLOW_DIG:-}" ]; then sleep 20; fi
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
  *api.anthropic.com*)
    if [ -n "${FAIL_SNI_POSITIVE:-}" ]; then exit 7; fi ;;
  *not-allowlisted.invalid*)
    # The negative SNI probe must FAIL for the run to pass AND the proxy must have
    # logged the refusal. PASS_SNI_NEGATIVE models a proxy that admitted the name;
    # SILENT_SNI_NEGATIVE models a curl that failed for some unrelated reason
    # (no redirect, dead proxy) — no log line is written.
    if [ -n "${PASS_SNI_NEGATIVE:-}" ]; then exit 0; fi
    if [ -n "${FORGED_SNI_LOG:-}" ]; then
      echo "2026-09-03T00:00:00 REJECT sni=not-allowlisted.invalid orig_dst=127.0.0.1:3443: not in allowlist" >> "$CC_SNI_RUN_DIR/proxy.log"
    elif [ -z "${SILENT_SNI_NEGATIVE:-}" ]; then
      echo "2026-09-03T00:00:00 REJECT sni=not-allowlisted.invalid orig_dst=203.0.113.7:443: not in allowlist" >> "$CC_SNI_RUN_DIR/proxy.log"
    fi
    exit 7 ;;
  *) exit 7 ;;
esac
exit 0
STUB

  cat > "$STUB_DIR/aggregate" <<'STUB'
#!/usr/bin/env bash
cat
STUB

  # --- filtering-resolver stubs (decision log #40) -----------------------------
  # The script writes its dnsmasq config and pidfile to overridable paths.
  export CC_DNSMASQ_CONF="$TEST_TMPDIR/dnsmasq.d/cc-allowlist.conf"
  export CC_DNSMASQ_PIDFILE="$TEST_TMPDIR/cc-dnsmasq.pid"

  # `id -u dnsmasq` must yield a non-zero uid; everything else passes through.
  cat > "$STUB_DIR/id" <<'STUB'
#!/usr/bin/env bash
if [ "${1:-}" = "-u" ] && [ "${2:-}" = "dnsmasq" ]; then echo 999; exit 0; fi
if [ "${1:-}" = "-u" ] && [ "${2:-}" = "ccproxy" ]; then echo "${CCPROXY_UID_STUB-998}"; exit 0; fi
exec /usr/bin/id "$@"
STUB

  # --- SNI proxy stubs (decision log #41) ---------------------------------------
  # The script executes the proxy binary directly (not via python3 on PATH), so
  # the test points CC_SNI_PROXY_BIN at a stub that records its invocation and
  # honours the --daemon contract: exit 0 = listening, anything else = no proxy.
  export CC_SNI_RUN_DIR="$TEST_TMPDIR/cc-sni-proxy"
  export CC_SNI_PROXY_BIN="$STUB_DIR/cc-sni-proxy"
  cat > "$STUB_DIR/cc-sni-proxy" <<'STUB'
#!/usr/bin/env bash
echo "cc-sni-proxy $*" >> "$CMD_LOG"
if [ -n "${FAIL_SNI:-}" ]; then echo "cc-sni-proxy: failed to start: stub" >&2; exit 1; fi
exit 0
STUB

  # runuser -u <user> -- <cmd...>: log, then run the command (which is a stub too).
  cat > "$STUB_DIR/runuser" <<'STUB'
#!/usr/bin/env bash
echo "runuser $*" >> "$CMD_LOG"
while [ $# -gt 0 ]; do case "$1" in --) shift; break;; *) shift;; esac; done
exec "$@"
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

  # ip6tables: the IPv6 default-deny block issues a handful of calls; log them.
  cat > "$STUB_DIR/ip6tables" <<'STUB'
#!/usr/bin/env bash
echo "ip6tables $*" >> "$CMD_LOG"
# NO_IP6_TABLE models a kernel with the binary but no IPv6 filter table.
if [ -n "${NO_IP6_TABLE:-}" ]; then exit 3; fi
exit 0
STUB

  chmod +x "$STUB_DIR"/*
  export PATH="$STUB_DIR:$PATH"
  # The script pins its own PATH (root-owned dirs only) and exposes this override
  # so the stubs stay first; it also takes a root-owned lock, relocated here.
  export CC_FIREWALL_PATH="$STUB_DIR:$PATH"
  export CC_FIREWALL_LOCK="$TEST_TMPDIR/cc-firewall/lock"
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
    grep -q "iptables -w 5 -P OUTPUT DROP" "$CMD_LOG"
  done
}

# --- narrowed host-network accepts ------------------------------------------

@test "the bridge gateway is admitted on udp/tcp 53 only, with no inbound counterpart" {
  # REGRESSION: `-A INPUT -s <bridge>/24` / `-A OUTPUT -d <bridge>/24` admitted every
  # port to and from every address on the bridge. The ip stub's gateway is
  # 192.168.65.1.
  run bash "$FW"
  [ "$status" -eq 0 ]
  grep -q "^iptables -A OUTPUT -p udp -d 192.168.65.1 --dport 53 -m owner --uid-owner 999 -j ACCEPT$" "$CMD_LOG"
  grep -q "^iptables -A OUTPUT -p tcp -d 192.168.65.1 --dport 53 -m owner --uid-owner 999 -j ACCEPT$" "$CMD_LOG"
  grep -q "^iptables -A OUTPUT -p udp -d 192.168.65.1 --dport 53 -m owner --uid-owner 0 -j ACCEPT$" "$CMD_LOG"
  run grep -cE -- '-[sd] 192\.168\.65\.0/24' "$CMD_LOG"
  [ "$output" -eq 0 ]
  # No other RULE names the gateway (2 uids x udp/tcp). The 5th hit is phase A's
  # `ip -4 route get <gw>`, which derives the container's own address and issues no rule.
  run grep -cE -- '192\.168\.65\.1( |$)' "$CMD_LOG"
  [ "$output" -eq 5 ]
  run grep -cE -- '^ip -4 route get 192\.168\.65\.1$' "$CMD_LOG"
  [ "$output" -eq 1 ]
  run grep -cE -- '^iptables -A INPUT -s ' "$CMD_LOG"
  [ "$output" -eq 0 ]
}

@test "the flush-to-DROP window contains no network call" {
  # This is the whole point of the phase A / phase B split: every network read
  # happens BEFORE the flush, so the interval where the chains are empty cannot
  # stall on (or be widened by) curl and dig.
  run bash "$FW"
  [ "$status" -eq 0 ]

  local flush drop meta reject
  flush=$(first_line_matching "^iptables -F")
  drop=$(first_line_matching "^iptables -P OUTPUT DROP")
  meta=$(first_line_matching "api.github.com/meta")
  reject=$(first_line_matching "^iptables -A OUTPUT -j REJECT")
  [ -n "$flush" ] && [ -n "$drop" ] && [ -n "$meta" ] && [ -n "$reject" ]

  # The GitHub fetch precedes the flush ...
  [ "$meta" -lt "$flush" ]
  # ... DROP is already in force when the flush happens (policies survive -F) ...
  [ "$drop" -lt "$flush" ]
  # ... and nothing from the flush to the terminal REJECT touches the network.
  run bash -c "sed -n '${flush},${reject}p' '$CMD_LOG' | grep -cE '^(curl|dig) '"
  [ "$output" -eq 0 ]
}

@test "all three DROP policies are set before the flush, so the window is empty" {
  # REGRESSION (F1): policies were set after `-F`, leaving a fresh container with
  # empty chains AND default-ACCEPT for the span of the flush calls.
  run bash "$FW"
  [ "$status" -eq 0 ]
  local flush chain line
  flush=$(first_line_matching "^iptables -F")
  for chain in INPUT FORWARD OUTPUT; do
    line=$(first_line_matching "^iptables -P $chain DROP")
    [ -n "$line" ]
    [ "$line" -lt "$flush" ]
  done
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

@test "no blanket inbound source-port-53 accept is installed" {
  # REGRESSION (F6): `-A INPUT -p udp --sport 53 -j ACCEPT` from 0.0.0.0/0 let any
  # packet with source port 53 through the INPUT DROP policy. Legitimate DNS replies
  # are covered by the ESTABLISHED,RELATED accept, which must still be present.
  run bash "$FW"
  [ "$status" -eq 0 ]
  run grep -c -- "--sport 53" "$CMD_LOG"
  [ "$output" -eq 0 ]
  grep -q -- "-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT" "$CMD_LOG"
}

@test "every curl carries --max-time: the meta fetch and both verification probes" {
  # REGRESSION (F5): the two end-of-script probes had only --connect-timeout, so a
  # connection that opened and then stalled could hang session start indefinitely.
  run bash "$FW"
  [ "$status" -eq 0 ]
  local n_curl n_bounded
  n_curl=$(grep -c '^curl ' "$CMD_LOG")
  n_bounded=$(grep '^curl ' "$CMD_LOG" | grep -c -- '--max-time')
  [ "$n_curl" -eq 5 ]   # meta fetch, 2 root probes, 2 node probes through the proxy
  [ "$n_bounded" -eq "$n_curl" ]
  grep '^curl ' "$CMD_LOG" | grep 'api.github.com/meta' | grep -q -- '--max-time'
  grep '^curl ' "$CMD_LOG" | grep 'example.com' | grep -q -- '--max-time'
  grep '^curl ' "$CMD_LOG" | grep 'api.github.com/zen' | grep -q -- '--max-time'
}

# --- the filtering resolver (decision log #40) --------------------------------

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
  # nat: every non-exempt flow is DNATed to dnsmasq at the container's own address
  # (NOT a REDIRECT to 127.0.0.1 — the kernel discards those, see decision log), inserted
  # AHEAD of the restored Docker DNAT so 127.0.0.11:53 cannot be claimed by the embedded
  # resolver first.
  grep -q "iptables -t nat -N CC_DNS" "$CMD_LOG"
  grep -q "iptables -t nat -A CC_DNS -m owner --uid-owner 999 -j RETURN" "$CMD_LOG"
  grep -q "iptables -t nat -A CC_DNS -m owner --uid-owner 0 -j RETURN" "$CMD_LOG"
  grep -q "iptables -t nat -A CC_DNS -p udp -j DNAT --to-destination 172.17.0.2:53" "$CMD_LOG"
  grep -q "iptables -t nat -A CC_DNS -p tcp -j DNAT --to-destination 172.17.0.2:53" "$CMD_LOG"
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
  udp53=$(first_line_matching "^iptables -A OUTPUT -p udp --dport 53 -j CC_DNS_GUARD$")
  tcp53=$(first_line_matching "^iptables -A OUTPUT -p tcp --dport 53 -j CC_DNS_GUARD$")
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
  grep -q "iptables -w 5 -P OUTPUT DROP" "$CMD_LOG"
  grep -q "iptables -w 5 -P INPUT DROP" "$CMD_LOG"
  grep -q "iptables -w 5 -P FORWARD DROP" "$CMD_LOG"
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
  grep -q "iptables -w 5 -P OUTPUT DROP" "$CMD_LOG"
}

@test "the trap waits for the xtables lock and verifies the DROP it applied" {
  # F7: `-w 5` on every trap call, then a `-S` read-back. On success the stub's
  # policy model reports DROP and the trap must NOT raise the OPEN alarm.
  FAIL_META=1 run bash "$FW"
  [ "$status" -ne 0 ]
  grep -q "iptables -w 5 -P OUTPUT DROP" "$CMD_LOG"
  grep -q "iptables -w 5 -P INPUT DROP" "$CMD_LOG"
  grep -q "iptables -w 5 -P FORWARD DROP" "$CMD_LOG"
  grep -q "iptables -w 5 -S" "$CMD_LOG"
  [[ "$output" == *"fails CLOSED"* ]]
  [[ "$output" != *"may be OPEN"* ]]
}

@test "the trap raises a distinct OPEN alarm when the DROP policy does not take" {
  # F7: with `|| true` a lost xtables lock is silent. The read-back must turn that
  # into a loud, distinct message rather than a claim that DROP was applied.
  FAIL_META=1 FAIL_POLICY=1 run bash "$FW"
  [ "$status" -ne 0 ]
  [[ "$output" == *"could not force DROP policy"* ]]
  [[ "$output" == *"container may be OPEN"* ]]
  [[ "$output" != *"fails CLOSED"* ]]
}

@test "SIGTERM mid-resolution still ends at DROP (the sentinel, not \$?, drives the trap)" {
  # F2: bash skips the EXIT trap for untrapped signals, and `$?` is 0 inside the
  # trap after a signal, so only the INT/TERM/HUP/QUIT -> exit 143 conversion plus
  # the completion sentinel makes a killed run fail closed. This is the only
  # regression guard for that mechanism.
  #
  # setsid: the script and the (sleeping) dig stub go into their own process group
  # so the whole group can be signalled. bash defers a trap while a foreground child
  # runs, so killing only the script's PID would wait out the stub's sleep.
  local out="$TEST_TMPDIR/signal.out" pid
  SLOW_DIG=1 setsid bash "$FW" >"$out" 2>&1 </dev/null &
  pid=$!
  # Poll for the dig stub to have started (it logs before sleeping); ~10s ceiling.
  for _ in $(seq 1 100); do
    grep -q '^dig ' "$CMD_LOG" 2>/dev/null && break
    sleep 0.1
  done
  grep -q '^dig ' "$CMD_LOG"
  # No rule was touched yet: the kill lands in phase A, before the flush.
  run grep -c '^iptables' "$CMD_LOG"
  [ "$output" -eq 0 ]

  kill -TERM -- "-$pid"
  wait "$pid" || true

  grep -q "iptables -w 5 -P OUTPUT DROP" "$CMD_LOG"
  grep -q "iptables -w 5 -P INPUT DROP" "$CMD_LOG"
  grep -q "iptables -w 5 -P FORWARD DROP" "$CMD_LOG"
  grep -q "did not complete" "$out"
}

# --- the SNI proxy (decision log #41) ----------------------------------------

@test "the SNI proxy is started as ccproxy with the generated allowlist, before the steering" {
  run bash "$FW"
  [ "$status" -eq 0 ]
  grep -q "^cc-sni-proxy --daemon --pidfile $CC_SNI_RUN_DIR/proxy.pid --user ccproxy --listen 172.17.0.2:3443 --allowlist $CC_SNI_RUN_DIR/allowlist --log $CC_SNI_RUN_DIR/proxy.log$" "$CMD_LOG"
  start=$(grep -n '^cc-sni-proxy ' "$CMD_LOG" | head -1 | cut -d: -f1)
  steer=$(grep -n 'CC_SNI -p tcp -j DNAT --to-destination 172.17.0.2:3443' "$CMD_LOG" | head -1 | cut -d: -f1)
  [ -n "$start" ] && [ -n "$steer" ] && [ "$start" -lt "$steer" ]
  # exactly one start per run
  run grep -c '^cc-sni-proxy ' "$CMD_LOG"
  [ "$output" -eq 1 ]
}

@test "the SNI allowlist holds every 443 entry as an exact name plus the GitHub zones" {
  run bash "$FW"
  [ "$status" -eq 0 ]
  local al="$CC_SNI_RUN_DIR/allowlist"
  grep -qx 'api.anthropic.com' "$al"
  grep -qx '.github.com' "$al"
  grep -qx '.githubusercontent.com' "$al"
  # Derived from GITHUB_DNS_ZONES, so no zone the resolver cannot answer for.
  run grep -c 'githubassets' "$al"
  [ "$output" -eq 0 ]
  # No port suffixes leak in, and no non-443 entry appears.
  run grep -c ':' "$al"
  [ "$output" -eq 0 ]
}

@test "an entry not on 443 is omitted from the SNI allowlist" {
  local dir="$TEST_TMPDIR/egress"
  mkdir -p "$dir"
  printf 'api.anthropic.com\nmodels.example:11434\nboth.example:443,8443\n' > "$dir/base.txt"
  CC_EGRESS_DIR="$dir" run bash "$FW"
  [ "$status" -eq 0 ]
  local al="$CC_SNI_RUN_DIR/allowlist"
  run grep -c 'models.example' "$al"
  [ "$output" -eq 0 ]
  grep -qx 'both.example' "$al"
}

@test "tcp/443 is redirected to the proxy for every uid except ccproxy and root, in nat and filter" {
  run bash "$FW"
  [ "$status" -eq 0 ]
  grep -q "^iptables -t nat -N CC_SNI$" "$CMD_LOG"
  grep -q "^iptables -t nat -A CC_SNI -m owner --uid-owner 998 -j RETURN$" "$CMD_LOG"
  grep -q "^iptables -t nat -A CC_SNI -m owner --uid-owner 0 -j RETURN$" "$CMD_LOG"
  grep -q "^iptables -t nat -A CC_SNI -p tcp -j DNAT --to-destination 172.17.0.2:3443$" "$CMD_LOG"
  grep -q "^iptables -t nat -A OUTPUT -p tcp --dport 443 -j CC_SNI$" "$CMD_LOG"
  grep -q "^iptables -N CC_SNI_GUARD$" "$CMD_LOG"
  grep -q "^iptables -A CC_SNI_GUARD -m owner --uid-owner 998 -j RETURN$" "$CMD_LOG"
  grep -q "^iptables -A CC_SNI_GUARD -m owner --uid-owner 0 -j RETURN$" "$CMD_LOG"
  grep -q "^iptables -A CC_SNI_GUARD -j REJECT --reject-with icmp-admin-prohibited$" "$CMD_LOG"
  # The guard jump precedes the ipset accept, so the agent can never hit the
  # address match for 443 directly.
  guard=$(grep -n -- '-A OUTPUT -p tcp --dport 443 -j CC_SNI_GUARD' "$CMD_LOG" | head -1 | cut -d: -f1)
  accept=$(grep -n -- '-A OUTPUT -m set --match-set allowed-domains dst,dst -j ACCEPT' "$CMD_LOG" | head -1 | cut -d: -f1)
  [ "$guard" -lt "$accept" ]
}

@test "a proxy that fails to start aborts the run and fails closed" {
  FAIL_SNI=1 run bash "$FW"
  [ "$status" -ne 0 ]
  [[ "$output" == *"SNI proxy failed to start"* ]]
  grep -q "iptables -w 5 -P OUTPUT DROP" "$CMD_LOG"
  run grep -c 'DNAT --to-destination 172.17.0.2:3443' "$CMD_LOG"
  [ "$output" -eq 0 ]
}

@test "a missing ccproxy user aborts before the flush" {
  CCPROXY_UID_STUB="" run bash "$FW"
  [ "$status" -ne 0 ]
  [[ "$output" == *"ccproxy"* ]]
  run grep -c -- "^iptables -F" "$CMD_LOG"
  [ "$output" -eq 0 ]
}

@test "a ccproxy uid equal to the dnsmasq uid is refused" {
  CCPROXY_UID_STUB=999 run bash "$FW"
  [ "$status" -ne 0 ]
  run grep -c -- "^iptables -F" "$CMD_LOG"
  [ "$output" -eq 0 ]
}

@test "the SNI probes run as node through the proxy: allowlisted name passes, forged SNI must fail" {
  run bash "$FW"
  [ "$status" -eq 0 ]
  grep -q "^runuser -u node -- curl .*https://api.anthropic.com/" "$CMD_LOG"
  grep -q "^runuser -u node -- curl .*--resolve not-allowlisted.invalid:443:203.0.113.7 https://not-allowlisted.invalid/" "$CMD_LOG"
  # Both probes come after the terminal REJECT, i.e. against the finished ruleset.
  reject=$(grep -n -- '-A OUTPUT -j REJECT' "$CMD_LOG" | tail -1 | cut -d: -f1)
  probe=$(grep -n '^runuser ' "$CMD_LOG" | head -1 | cut -d: -f1)
  [ "$reject" -lt "$probe" ]
}

@test "a proxy that admits a non-allowlisted SNI fails verification and fails closed" {
  PASS_SNI_NEGATIVE=1 run bash "$FW"
  [ "$status" -ne 0 ]
  [[ "$output" == *"non-allowlisted SNI reached"* ]]
  grep -q "iptables -w 5 -P OUTPUT DROP" "$CMD_LOG"
}

@test "node failing to reach api.anthropic.com through the proxy fails verification" {
  FAIL_SNI_POSITIVE=1 run bash "$FW"
  [ "$status" -ne 0 ]
  [[ "$output" == *"through the SNI proxy"* ]]
}

# --- review-fix wave 2026-09-03 -----------------------------------------------

@test "a zero-padded port is canonicalised before it reaches ipset and the SNI allowlist" {
  local dir="$TEST_TMPDIR/egress"
  mkdir -p "$dir"
  printf 'api.anthropic.com\npadded.example:0443\n' > "$dir/base.txt"
  CC_EGRESS_DIR="$dir" run bash "$FW"
  [ "$status" -eq 0 ]
  run grep -c -- 'tcp:0443' "$CMD_LOG"
  [ "$output" -eq 0 ]
  grep -q "^ipset add -exist allowed-domains 203.0.113.7,tcp:443$" "$CMD_LOG"
  grep -qx 'padded.example' "$CC_SNI_RUN_DIR/allowlist"
}

@test "a single-label entry is rejected by the shared grammar (it would be a TLD zone)" {
  # REGRESSION: `server=/com/<ns>` would forward every .com name upstream and
  # re-open recursive-forward tunnelling; parse_entry and compose_dnsmasq_conf
  # share HOST_RE, which requires two labels.
  local dir="$TEST_TMPDIR/egress"
  mkdir -p "$dir"
  printf 'api.anthropic.com\ncom:443\n' > "$dir/base.txt"
  CC_EGRESS_DIR="$dir" run bash "$FW"
  [ "$status" -ne 0 ]
  [[ "$output" == *"malformed egress entry"* ]]
  printf 'nameserver 127.0.0.11\n' > "$TEST_TMPDIR/rc"
  CC_EGRESS_DIR="$dir" run bash "$FW" --print-dnsmasq-conf "$TEST_TMPDIR/rc"
  [[ "$output" != *"server=/com/"* ]]
}

@test "IPv6 is default-denied: DROP policies, flush, loopback and established only" {
  run bash "$FW"
  [ "$status" -eq 0 ]
  grep -q "^ip6tables -P OUTPUT DROP$" "$CMD_LOG"
  grep -q "^ip6tables -P INPUT DROP$" "$CMD_LOG"
  grep -q "^ip6tables -F$" "$CMD_LOG"
  grep -q "^ip6tables -A OUTPUT -o lo -j ACCEPT$" "$CMD_LOG"
  grep -q "^ip6tables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT$" "$CMD_LOG"
  # No IPv6 allowlist accept of any kind.
  run grep -cE '^ip6tables -A OUTPUT (-p|-d|-m set)' "$CMD_LOG"
  [ "$output" -eq 0 ]
}

@test "the negative SNI probe requires a logged refusal, not just a failed curl" {
  SILENT_SNI_NEGATIVE=1 run bash "$FW"
  [ "$status" -ne 0 ]
  [[ "$output" == *"did not log a redirected refusal"* ]]
  grep -q "iptables -w 5 -P OUTPUT DROP" "$CMD_LOG"
}

@test "the run takes a lock so concurrent invocations serialise" {
  run bash "$FW"
  [ "$status" -eq 0 ]
  [ -e "$CC_FIREWALL_LOCK" ]
  # Hold the lock from outside; the script must not proceed past it.
  mkdir -p "$(dirname "$CC_FIREWALL_LOCK")"
  exec 8>"$CC_FIREWALL_LOCK"
  flock -n 8
  : > "$CMD_LOG"
  CC_FIREWALL_LOCK_WAIT=1 run bash "$FW"
  [ "$status" -ne 0 ]
  run grep -c -- "^iptables -F" "$CMD_LOG"
  [ "$output" -eq 0 ]
  exec 8>&-
}

@test "helpers resolve through the pinned PATH, not the caller's" {
  # With the override unset the script must reset PATH to root-owned dirs; the
  # stubs then vanish and the stub-logged run cannot proceed as before. Assert
  # the pin exists rather than running unstubbed: the script must reference
  # CC_FIREWALL_PATH with a root-only default and export PATH from it.
  grep -q 'export PATH="${CC_FIREWALL_PATH:-/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin}"' "$FW"
  grep -q '^#!/usr/bin/python3$' "$BATS_TEST_DIRNAME/../devcontainer-config/cc-sni-proxy.py"
}

@test "a kernel without an IPv6 filter table warns and continues instead of failing closed" {
  NO_IP6_TABLE=1 run bash "$FW"
  [ "$status" -eq 0 ]
  [[ "$output" == *"no usable ip6tables filter table"* ]]
  run grep -c -- "^ip6tables -P" "$CMD_LOG"
  [ "$output" -eq 0 ]
}

@test "the negative probe asserts the nat redirect rule, not just log evidence" {
  run bash "$FW"
  [ "$status" -eq 0 ]
  grep -q "^iptables -w 5 -t nat -C OUTPUT -p tcp --dport 443 -j CC_SNI$" "$CMD_LOG"
}

@test "a refusal logged from a direct loopback connection does not satisfy the probe" {
  # FORGED_SNI_LOG makes the curl stub log the refusal with orig_dst=127.0.0.1:3443,
  # which is what a connection that bypassed the redirect would produce.
  FORGED_SNI_LOG=1 run bash "$FW"
  [ "$status" -ne 0 ]
  [[ "$output" == *"did not log a redirected refusal"* ]]
}

@test "the lock lives in a 0711 directory and is 0600" {
  # 0711, not 0700. The launcher probes the completion marker in this directory as
  # `node`; a 0700 dir makes that stat fail EACCES on a perfectly healthy container.
  # The security property is carried by the missing w bit (node cannot add or remove
  # entries) and by the lock's own 0600, not by denying traversal.
  run bash "$FW"
  [ "$status" -eq 0 ]
  [ "$(stat -c '%a' "$(dirname "$CC_FIREWALL_LOCK")")" = "711" ]
  [ "$(stat -c '%a' "$CC_FIREWALL_LOCK")" = "600" ]
}

@test "the lock covers both phases: a held lock stops the run before any network read" {
  mkdir -p "$(dirname "$CC_FIREWALL_LOCK")"
  exec 8>"$CC_FIREWALL_LOCK"
  flock -n 8
  CC_FIREWALL_LOCK_WAIT=1 run bash "$FW"
  [ "$status" -ne 0 ]
  [[ "$output" == *"still in progress"* ]]
  run grep -cE -- "^(curl|dig|iptables -F)" "$CMD_LOG"
  [ "$output" -eq 0 ]
  # A lock timeout must NOT tear down the boundary the holder is building.
  run grep -c -- "-P OUTPUT DROP" "$CMD_LOG"
  [ "$output" -eq 0 ]
  exec 8>&-
}

@test "a non-numeric lock wait aborts instead of being silently repaired" {
  CC_FIREWALL_LOCK_WAIT=soon run bash "$FW"
  [ "$status" -ne 0 ]
  [[ "$output" == *"CC_FIREWALL_LOCK_WAIT must be"* ]]
}

@test "the lock is held through the verification probes" {
  run grep -c '^flock -u 9' "$FW"
  [ "$output" -eq 0 ]
}

@test "a missing filter-table guard rule fails verification" {
  NO_RULE=CC_SNI_GUARD run bash "$FW"
  [ "$status" -ne 0 ]
  [[ "$output" == *"expected rule missing: iptables -C OUTPUT -p tcp --dport 443 -j CC_SNI_GUARD"* ]]
  NO_RULE=CC_DNS_GUARD run bash "$FW"
  [ "$status" -ne 0 ]
  [[ "$output" == *"CC_DNS_GUARD"* ]]
}

@test "every boundary rule is asserted present before completion" {
  run bash "$FW"
  [ "$status" -eq 0 ]
  grep -q "^iptables -w 5 -t nat -C OUTPUT -p udp --dport 53 -j CC_DNS$" "$CMD_LOG"
  grep -q "^iptables -w 5 -t nat -C OUTPUT -p tcp --dport 53 -j CC_DNS$" "$CMD_LOG"
  grep -q "^iptables -w 5 -C OUTPUT -d 127.0.0.11 -j CC_DNS_GUARD$" "$CMD_LOG"
  grep -q "^iptables -w 5 -C OUTPUT -p udp --dport 53 -j CC_DNS_GUARD$" "$CMD_LOG"
  grep -q "^iptables -w 5 -C OUTPUT -p tcp --dport 53 -j CC_DNS_GUARD$" "$CMD_LOG"
  grep -q "^iptables -w 5 -C OUTPUT -p tcp --dport 443 -j CC_SNI_GUARD$" "$CMD_LOG"
  grep -q "^iptables -w 5 -C OUTPUT -m set --match-set allowed-domains dst,dst -j ACCEPT$" "$CMD_LOG"
  grep -q "^iptables -w 5 -C OUTPUT -j REJECT --reject-with icmp-admin-prohibited$" "$CMD_LOG"
}

@test "a node-owned or world-writable profile directory aborts before the flush (R7)" {
  # CC_EGRESS_OWNER_CHECK forces the invariant check on the relocated test dir,
  # which is owned by the test user, not root.
  CC_EGRESS_OWNER_CHECK=1 run bash "$FW"
  [ "$status" -ne 0 ]
  [[ "$output" == *"must be root-owned"* ]]
  run grep -cE -- "^(curl|dig|iptables -F)" "$CMD_LOG"
  [ "$output" -eq 0 ]
  grep -q "iptables -w 5 -P OUTPUT DROP" "$CMD_LOG"
}

@test "a global IPv6 address with no usable v6 filter table aborts before the flush" {
  NO_IP6_TABLE=1 HAS_GLOBAL_V6=1 run bash "$FW"
  [ "$status" -ne 0 ]
  [[ "$output" == *"global IPv6 address but no usable ip6tables"* ]]
  run grep -c -- "^iptables -F" "$CMD_LOG"
  [ "$output" -eq 0 ]
}

@test "a missing tcp/443 redirect rule fails verification even with a logged refusal" {
  NO_REDIRECT=1 run bash "$FW"
  [ "$status" -ne 0 ]
  [[ "$output" == *"expected rule missing: iptables -t nat -C OUTPUT -p tcp --dport 443 -j CC_SNI"* ]]
  # the nat CC_DNS jumps are also asserted (same knob does not fire for them)
  grep -q "iptables -w 5 -P OUTPUT DROP" "$CMD_LOG"
}

# --- route_localnet precondition + martian guard (decision log #43) ------------
# Regression guard for the 2026-09-09 incident: both nat REDIRECTs target
# 127.0.0.1, which the kernel discards as a martian unless route_localnet=1. The
# rules install and MATCH packets either way, so nothing downstream of the redirect
# can detect it — only an explicit assertion can.

@test "the martian guard drops non-loopback traffic to 127/8 before the established accept" {
  run bash "$FW"
  [ "$status" -eq 0 ]
  grep -q -- "iptables -A INPUT ! -i lo -d 127.0.0.0/8 -j DROP" "$CMD_LOG"
  # Anchored to `^iptables `: the IPv6 block issues an identical-looking
  # `ip6tables -A INPUT -m state --state ESTABLISHED,RELATED` earlier in the run,
  # and an unanchored pattern matches that instead and inverts the comparison.
  guard=$(first_line_matching '^iptables -A INPUT ! -i lo -d 127.0.0.0/8 -j DROP')
  est=$(first_line_matching '^iptables -A INPUT -m state --state ESTABLISHED,RELATED')
  [ -n "$guard" ] && [ -n "$est" ] && [ "$guard" -lt "$est" ]
}

@test "a missing martian guard fails verification and fails closed" {
  NO_RULE='127.0.0.0/8' run bash "$FW"
  [ "$status" -ne 0 ]
  [[ "$output" == *"expected rule missing"* ]]
  grep -q "iptables -w 5 -P OUTPUT DROP" "$CMD_LOG"
}

# --- steering address (decision log #44) ---------------------------------------
# The 2026-09-09 incident: both nat chains used `REDIRECT`, which on LOCAL_OUT
# hardcodes 127.0.0.1, and the kernel discarded the rewritten packets before they
# reached any socket — rules matching, counters incrementing, traffic gone. The fix
# is to steer to the container's OWN address. These tests guard the two properties
# that makes true: one address everywhere, and never a loopback one.

@test "both nat chains steer to the container's own address, never to loopback" {
  run bash "$FW"
  [ "$status" -eq 0 ]
  grep -q "^iptables -t nat -A CC_DNS -p udp -j DNAT --to-destination 172.17.0.2:53$" "$CMD_LOG"
  grep -q "^iptables -t nat -A CC_DNS -p tcp -j DNAT --to-destination 172.17.0.2:53$" "$CMD_LOG"
  grep -q "^iptables -t nat -A CC_SNI -p tcp -j DNAT --to-destination 172.17.0.2:3443$" "$CMD_LOG"
  # No REDIRECT target survives anywhere, and nothing steers into 127/8.
  run grep -c -- 'REDIRECT' "$CMD_LOG"
  [ "$output" -eq 0 ]
  run grep -cE -- '--to-destination 127\.' "$CMD_LOG"
  [ "$output" -eq 0 ]
}

@test "the steering address is derived at run time, not baked" {
  run bash "$FW"
  [ "$status" -eq 0 ]
  # It comes from `ip -4 route get <gateway>`, so a renumbered container follows.
  grep -q "^ip -4 route get 192.168.65.1$" "$CMD_LOG"
  run grep -c -- 'ip -4 route get' "$CMD_LOG"
  [ "$output" -eq 1 ]
}

@test "one address serves the DNAT targets, the dnsmasq bind and the proxy bind" {
  run bash "$FW"
  [ "$status" -eq 0 ]
  grep -q 'listen-address=127.0.0.1,172.17.0.2' "$CC_DNSMASQ_CONF"
  grep -q -- '--listen 172.17.0.2:3443' "$CMD_LOG"
  grep -q -- '--to-destination 172.17.0.2:53' "$CMD_LOG"
  grep -q -- '--to-destination 172.17.0.2:3443' "$CMD_LOG"
}

@test "a container with no derivable IPv4 source address aborts before the flush" {
  NO_CONTAINER_IP=1 run bash "$FW"
  [ "$status" -ne 0 ]
  [[ "$output" == *"could not derive this container's own IPv4 address"* ]]
  run grep -c -- "^iptables -F" "$CMD_LOG"
  [ "$output" -eq 0 ]
}

@test "a malformed steering address is rejected by the octet grammar, before the flush" {
  BAD_CONTAINER_IP=1 run bash "$FW"
  [ "$status" -ne 0 ]
  [[ "$output" == *"could not derive this container's own IPv4 address"* ]]
  run grep -c -- "^iptables -F" "$CMD_LOG"
  [ "$output" -eq 0 ]
}

@test "the DNS guard jumps exempt the steering address, or they reject the steered traffic" {
  run bash "$FW"
  [ "$status" -eq 0 ]
  # Under DNAT the steered packet carries -d <container-ip> with dport still 53, so a
  # guard that only exempts 127.0.0.1 would REJECT exactly what the steering creates.
  # Both addresses dnsmasq binds are RETURNed at the head of the guard chain. This is
  # NOT expressible as `! -d A ! -d B` on the jump — iptables allows one -d per rule.
  grep -q -- "^iptables -A CC_DNS_GUARD -p udp --dport 53 -d 127.0.0.1 -j RETURN$" "$CMD_LOG"
  grep -q -- "^iptables -A CC_DNS_GUARD -p udp --dport 53 -d 172.17.0.2 -j RETURN$" "$CMD_LOG"
  grep -q -- "^iptables -A CC_DNS_GUARD -p tcp --dport 53 -d 172.17.0.2 -j RETURN$" "$CMD_LOG"
  # ...and they precede the REJECT, or they would never be consulted.
  local ret rej
  ret=$(first_line_matching "^iptables -A CC_DNS_GUARD -p udp --dport 53 -d 172.17.0.2 -j RETURN$")
  rej=$(first_line_matching "^iptables -A CC_DNS_GUARD -j REJECT")
  [ -n "$ret" ] && [ -n "$rej" ] && [ "$ret" -lt "$rej" ]
}

@test "the daemons' ports are dropped on non-loopback interfaces, before the established accept" {
  run bash "$FW"
  [ "$status" -eq 0 ]
  local est u53 t53 sni
  u53=$(first_line_matching '^iptables -A INPUT ! -i lo -p udp --dport 53 -j DROP$')
  t53=$(first_line_matching '^iptables -A INPUT ! -i lo -p tcp --dport 53 -j DROP$')
  sni=$(first_line_matching '^iptables -A INPUT ! -i lo -p tcp --dport 3443 -j DROP$')
  est=$(first_line_matching '^iptables -A INPUT -m state --state ESTABLISHED,RELATED')
  [ -n "$u53" ] && [ -n "$t53" ] && [ -n "$sni" ] && [ -n "$est" ]
  [ "$u53" -lt "$est" ] && [ "$t53" -lt "$est" ] && [ "$sni" -lt "$est" ]
}

@test "a missing daemon-port drop fails verification and fails closed" {
  NO_RULE='3443' run bash "$FW"
  [ "$status" -ne 0 ]
  [[ "$output" == *"expected rule missing"* ]]
  grep -q "iptables -w 5 -P OUTPUT DROP" "$CMD_LOG"
}

@test "the steered destinations are accepted on address, not on -o lo" {
  run bash "$FW"
  [ "$status" -eq 0 ]
  # REGRESSION (2026-09-09, measured on a live container): `-o lo` does NOT match a
  # packet that nat OUTPUT rewrote to a local address. LOCAL_OUT captures the
  # out-device once, before any chain in the hook point runs; nat's
  # ip_route_me_harder() updates skb_dst but not the nf_hook_state filter is handed,
  # so filter still sees the ORIGINAL destination's device. Every steered packet fell
  # past `-o lo` into the terminal REJECT. The accept must therefore be written on the
  # destination address, which survives the rewrite.
  grep -q -- "^iptables -A OUTPUT -d 172.17.0.2 -p udp --dport 53 -j ACCEPT$" "$CMD_LOG"
  grep -q -- "^iptables -A OUTPUT -d 172.17.0.2 -p tcp --dport 53 -j ACCEPT$" "$CMD_LOG"
  grep -q -- "^iptables -A OUTPUT -d 172.17.0.2 -p tcp --dport 3443 -j ACCEPT$" "$CMD_LOG"
}

@test "the steering accepts precede the terminal REJECT, or the steered traffic dies there" {
  run bash "$FW"
  [ "$status" -eq 0 ]
  local dns sni rej
  dns=$(first_line_matching "^iptables -A OUTPUT -d 172.17.0.2 -p udp --dport 53 -j ACCEPT$")
  sni=$(first_line_matching "^iptables -A OUTPUT -d 172.17.0.2 -p tcp --dport 3443 -j ACCEPT$")
  rej=$(first_line_matching "^iptables -A OUTPUT -j REJECT")
  [ -n "$dns" ] && [ -n "$sni" ] && [ -n "$rej" ]
  [ "$dns" -lt "$rej" ] && [ "$sni" -lt "$rej" ]
}

@test "the steering accepts use the derived address, so they track the DNAT target" {
  # An accept for a different address than the DNAT writes is the same outage with
  # more rules, so pin them to the one derived value rather than to a literal.
  CONTAINER_IP_OVERRIDE=172.18.0.9 run bash "$FW"
  [ "$status" -eq 0 ]
  grep -q -- "^iptables -A OUTPUT -d 172.18.0.9 -p udp --dport 53 -j ACCEPT$" "$CMD_LOG"
  grep -q -- "^iptables -A OUTPUT -d 172.18.0.9 -p tcp --dport 3443 -j ACCEPT$" "$CMD_LOG"
  ! grep -q -- "^iptables -A OUTPUT -d 172.17.0.2 -p udp --dport 53 -j ACCEPT$" "$CMD_LOG"
}

@test "the steering accepts are asserted present before completion" {
  run bash "$FW"
  [ "$status" -eq 0 ]
  grep -q "^iptables -w 5 -C OUTPUT -d 172.17.0.2 -p udp --dport 53 -j ACCEPT$" "$CMD_LOG"
  grep -q "^iptables -w 5 -C OUTPUT -d 172.17.0.2 -p tcp --dport 53 -j ACCEPT$" "$CMD_LOG"
  grep -q "^iptables -w 5 -C OUTPUT -d 172.17.0.2 -p tcp --dport 3443 -j ACCEPT$" "$CMD_LOG"
}

@test "the iptables stub rejects a duplicate selector, so invalid rules cannot pass" {
  # Guards the guard: without this, `! -d A ! -d B` (a syntax error real iptables
  # refuses) passed the whole suite and failed at container start instead.
  run "$STUB_DIR/iptables" -A OUTPUT -p udp --dport 53 ! -d 127.0.0.1 ! -d 172.17.0.2 -j CC_DNS_GUARD
  [ "$status" -ne 0 ]
  [[ "$output" == *"multiple -d flags not allowed"* ]]
  run "$STUB_DIR/iptables" -A OUTPUT -p udp --dport 53 -d 127.0.0.1 -j CC_DNS_GUARD
  [ "$status" -eq 0 ]
}

# --- completion marker (read by the launcher's self-probe; decision log #45) ---

@test "a completed run leaves the completion marker, with the container address" {
  export CC_FIREWALL_MARKER="$TEST_TMPDIR/complete"
  run bash "$FW"
  [ "$status" -eq 0 ]
  [ -f "$CC_FIREWALL_MARKER" ]
  grep -q '^completed=' "$CC_FIREWALL_MARKER"
  grep -q '^container_ip=172\.17\.0\.2$' "$CC_FIREWALL_MARKER"
}

@test "the marker is readable by a non-root user (the probe reads it as node)" {
  # Regression: the marker defaulted into a 0700 root directory while cc-isolated.sh
  # probes it with a bare `test -f` as `node` (remoteUser), whose sudo grant is a bare
  # init-firewall.sh only — so every healthy container reported PROBE FAIL (firewall).
  # Every other marker test relocates CC_FIREWALL_MARKER into a dir the test user owns,
  # which is why the modes went unchecked. Here the marker takes its real default
  # position beside the lock, and both modes are asserted.
  export CC_FIREWALL_LOCK="$TEST_TMPDIR/realrun/lock"
  run bash "$FW"
  [ "$status" -eq 0 ]
  [ -f "$TEST_TMPDIR/realrun/complete" ]
  [ "$(stat -c '%a' "$TEST_TMPDIR/realrun")" = "711" ]
  [ "$(stat -c '%a' "$TEST_TMPDIR/realrun/complete")" = "644" ]
}

@test "a marker left 0600 by an earlier run is re-opened to 0644" {
  # `>` onto an existing file keeps its mode, so a marker first created under a tight
  # umask would stay unreadable to node for the life of the container.
  export CC_FIREWALL_LOCK="$TEST_TMPDIR/realrun/lock"
  mkdir -p "$TEST_TMPDIR/realrun"
  : > "$TEST_TMPDIR/realrun/complete"
  chmod 0600 "$TEST_TMPDIR/realrun/complete"
  run bash "$FW"
  [ "$status" -eq 0 ]
  [ "$(stat -c '%a' "$TEST_TMPDIR/realrun/complete")" = "644" ]
}

@test "an aborted run removes a marker left by an earlier run (bricked-closed is visible)" {
  export CC_FIREWALL_MARKER="$TEST_TMPDIR/complete"
  echo 'completed=earlier' > "$CC_FIREWALL_MARKER"
  FAIL_META=1 run bash "$FW"
  [ "$status" -ne 0 ]
  [ ! -f "$CC_FIREWALL_MARKER" ]
  grep -q "iptables -w 5 -P OUTPUT DROP" "$CMD_LOG"
}

@test "the marker is removed before the flush, not only at exit" {
  # A run that dies between the flush and the sentinel must not leave the
  # previous run's marker vouching for a half-built ruleset. The stub logs `rm`
  # nowhere, so assert on ordering by making the run fail AFTER the flush and
  # checking the marker is gone; then check the script text orders the rm ahead
  # of the flush (the trap alone would also remove it, so this pins the position).
  export CC_FIREWALL_MARKER="$TEST_TMPDIR/complete"
  echo 'completed=earlier' > "$CC_FIREWALL_MARKER"
  NO_RULE=CC_SNI_GUARD run bash "$FW"
  [ "$status" -ne 0 ]
  [ ! -f "$CC_FIREWALL_MARKER" ]
  local rm_line flush_line
  rm_line=$(grep -n '^rm -f "\$FIREWALL_MARKER"' "$FW" | head -1 | cut -d: -f1)
  flush_line=$(grep -n '^iptables -F$' "$FW" | head -1 | cut -d: -f1)
  [ -n "$rm_line" ] && [ -n "$flush_line" ] && [ "$rm_line" -lt "$flush_line" ]
}

@test "a run that never took the lock leaves the holder's marker alone" {
  export CC_FIREWALL_MARKER="$TEST_TMPDIR/complete"
  export CC_FIREWALL_LOCK="$TEST_TMPDIR/lock" CC_FIREWALL_LOCK_WAIT=1
  echo 'completed=holder' > "$CC_FIREWALL_MARKER"
  exec 8>"$CC_FIREWALL_LOCK"; flock 8
  run bash "$FW"
  exec 8>&-
  [ "$status" -ne 0 ]
  [[ "$output" == *"never acquired the firewall lock"* ]]
  [ -f "$CC_FIREWALL_MARKER" ]
  grep -q '^completed=holder$' "$CC_FIREWALL_MARKER"
}
