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
  # No other rule names the gateway (2 uids x udp/tcp), and no INPUT accept keys on a source address at all.
  run grep -cE -- '192\.168\.65\.1( |$)' "$CMD_LOG"
  [ "$output" -eq 4 ]
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
  local out="$TEST_TMPDIR/signal.out" pid i
  SLOW_DIG=1 setsid bash "$FW" >"$out" 2>&1 </dev/null &
  pid=$!
  # Poll for the dig stub to have started (it logs before sleeping); ~10s ceiling.
  for i in $(seq 1 100); do
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

@test "the SNI proxy is started as ccproxy with the generated allowlist, before the REDIRECT" {
  run bash "$FW"
  [ "$status" -eq 0 ]
  grep -q "^cc-sni-proxy --daemon --pidfile $CC_SNI_RUN_DIR/proxy.pid --user ccproxy --listen 127.0.0.1:3443 --allowlist $CC_SNI_RUN_DIR/allowlist --log $CC_SNI_RUN_DIR/proxy.log$" "$CMD_LOG"
  start=$(grep -n '^cc-sni-proxy ' "$CMD_LOG" | head -1 | cut -d: -f1)
  redirect=$(grep -n 'REDIRECT --to-ports 3443' "$CMD_LOG" | head -1 | cut -d: -f1)
  [ "$start" -lt "$redirect" ]
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
  grep -q "^iptables -t nat -A CC_SNI -p tcp -j REDIRECT --to-ports 3443$" "$CMD_LOG"
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
  run grep -c 'REDIRECT --to-ports 3443' "$CMD_LOG"
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

@test "the lock lives in a 0700 directory and is 0600" {
  run bash "$FW"
  [ "$status" -eq 0 ]
  [ "$(stat -c '%a' "$(dirname "$CC_FIREWALL_LOCK")")" = "700" ]
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
  [[ "$output" != *"fails CLOSED"* ]]
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
  grep -q "^iptables -w 5 -C OUTPUT -p udp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD$" "$CMD_LOG"
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
