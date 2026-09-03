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
  #
  # iptables additionally keeps a tiny policy model in $CMD_LOG.policies so that
  # `-S` prints `-P <chain> <policy>` lines consistent with every prior `-P` call —
  # that is what the fail-closed trap reads back to verify its own DROPs. FAIL_POLICY
  # makes `-P` a silent no-op (exit 0, nothing recorded), modelling a lost xtables
  # lock: the call "succeeds" but the policy stays ACCEPT.
  cat > "$STUB_DIR/iptables" <<'STUB'
#!/usr/bin/env bash
echo "iptables $*" >> "$CMD_LOG"
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
  grep -q "match-set allowed-domains dst -j ACCEPT" "$CMD_LOG"
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
    grep -qE "iptables -A OUTPUT -p udp -d [0-9.]+ --dport 53 -j ACCEPT" "$CMD_LOG"
    grep -qE "iptables -A OUTPUT -p tcp -d [0-9.]+ --dport 53 -j ACCEPT" "$CMD_LOG"
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
  [ "$n_curl" -eq 3 ]
  [ "$n_bounded" -eq "$n_curl" ]
  grep '^curl ' "$CMD_LOG" | grep 'api.github.com/meta' | grep -q -- '--max-time'
  grep '^curl ' "$CMD_LOG" | grep 'example.com' | grep -q -- '--max-time'
  grep '^curl ' "$CMD_LOG" | grep 'api.github.com/zen' | grep -q -- '--max-time'
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
