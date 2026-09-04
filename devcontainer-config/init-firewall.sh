#!/bin/bash
# Adapted from Anthropic's reference devcontainer for Claude Code
# (anthropics/claude-code .devcontainer/init-firewall.sh).
#
# Local changes (decisions 015, 016):
#   - the allowlist is no longer hardcoded here; it is composed from the egress
#     profile files baked into the image at /usr/local/share/cc-egress/ (decision
#     016, H5: a Python project reaches PyPI without opening PyPI to every other
#     project). `base` is always applied; extra profiles come from
#     /etc/cc-egress-profile, which is written root-owned at BUILD time from the
#     CC_EGRESS_PROFILE build arg.
#   - non-critical resolution failures warn-and-skip instead of hard-failing
#     (statsig.anthropic.com went NXDOMAIN in 2026-07 and bricked session start).
#   - the allowlist is PORT-SCOPED (security review 2026-08-29, finding 5). The
#     ipset is `hash:net,port` and the OUTPUT accept matches `dst,dst`, so a
#     destination is admitted only on the ports its profile entry names. Profile
#     entries are `domain[:port[,port...]]` — TCP ports, default 443 when the
#     suffix is absent — and GitHub's published CIDRs get tcp 443 + tcp 22. This
#     does not close the IP-vs-SNI overreach itself (a CDN neighbour on the same IP
#     and port is still reachable) but it removes every OTHER port on every
#     admitted address: an allowlisted host no longer doubles as a wildcard for
#     whatever else listens on it.
#
# Why the profile is baked at build time rather than read from the environment:
# `node` has NOPASSWD sudo for exactly this script and nothing else, and sudo's
# env_reset strips the environment, so an in-container agent cannot re-run this
# with a wider profile. Changing a project's egress requires a host-side
# `cc-isolated --register`, a re-bless, and a rebuild — i.e. a human.
set -euo pipefail  # Exit on error, undefined vars, and pipeline failures
IFS=$'\n\t'       # Stricter word splitting

# Root-owned helper resolution only. Everything this script runs as root — iptables,
# ipset, dig, curl, runuser, dnsmasq, the proxy — is found via PATH, and `node`'s own
# PATH includes the node-writable /usr/local/share/npm-global/bin. sudo's env_reset
# and secure_path normally protect this, but nothing in the repo asserts that, so
# the script pins PATH itself. CC_FIREWALL_PATH exists only so the unit tests can
# put their stubs first; under sudo env_reset `node` cannot set it.
export PATH="${CC_FIREWALL_PATH:-/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin}"

EGRESS_DIR="${CC_EGRESS_DIR:-/usr/local/share/cc-egress}"
PROFILE_FILE="${CC_EGRESS_PROFILE_FILE:-/etc/cc-egress-profile}"

# Compose the allowlist from `base` plus whatever profiles this image was built
# with. Emits one entry per line, deduplicated, exactly as written in the profile
# files: `domain[:port[,port...]]` (see the header). The port suffix is parsed and
# validated later by parse_entry, not here — this hook prints the raw composition
# so a test can see precisely what a profile grants. Unknown profile = hard
# failure: a typo must not silently degrade to a narrower-than-intended allowlist
# that then looks like a mysterious network outage.
compose_domains() {
  local profiles="base" extra p f
  local -a files=()
  if [ -r "$PROFILE_FILE" ]; then
    extra="$(tr -d '[:space:]' < "$PROFILE_FILE")"
    [ -n "$extra" ] && profiles="base,$extra"
  fi
  # Resolve every profile to a file FIRST, and only then read them. A `return 1`
  # inside a `for ... done | sort` pipeline would run in a subshell and be masked
  # by sort's exit status, so a typo'd profile would silently yield a narrower
  # allowlist that reads as a mysterious network outage rather than an error.
  # IFS is \n\t here, so split the comma-separated list via tr, not word-splitting.
  for p in $(echo "$profiles" | tr ',' '\n' | sort -u); do
    f="$EGRESS_DIR/$p.txt"
    if [ ! -r "$f" ]; then
      echo "ERROR: unknown egress profile '$p' (no $f)" >&2
      return 1
    fi
    files+=("$f")
  done
  grep -hvE '^[[:space:]]*(#|$)' "${files[@]}" | sort -u
}

# Inspection hook: print the composed allowlist and exit without touching the
# firewall. Lets the unit tests exercise profile composition with no root and no
# Docker (test/cc-isolated-functions.bats).
if [ "${1:-}" = "--print-domains" ]; then
  compose_domains
  exit 0
fi

# Parse the IPv4 nameservers out of a resolv.conf. Factored into a function so the
# parsing — which has now regressed twice under review — is directly testable, via
# the --print-resolvers hook below, exactly as compose_domains is via --print-domains.
#
# The file is a positional ARGUMENT, deliberately not an environment variable. This
# script runs through `sudo` (NOPASSWD, no SETENV) whose env_reset would strip an env
# seam anyway, but the stronger reason is that an agent-controllable resolver path is
# precisely the trust inversion the block below warns about: point it at a file you
# own containing `nameserver <attacker_ip>` and earn a scoped accept to it. The hook
# only ever PRINTS and exits before any rule is touched, so passing a path to it
# cannot influence the firewall; the real path below passes no argument and gets
# /etc/resolv.conf.
compose_dns_resolvers() {
  local f="${1:-/etc/resolv.conf}" octet
  # A real 0-255 alternation, not a `[0-9]{1,3}` shape check: a shape check passes
  # `999.999.999.999`, which iptables then treats as a hostname, fails to resolve,
  # and exits non-zero — aborting the rebuild. Reject out-of-range octets here so a
  # malformed entry never reaches iptables at all.
  octet='(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])'
  # `|| true` is load-bearing: under `set -euo pipefail` the pipeline's status
  # propagates to the caller's assignment, and grep exits 1 when it matches zero
  # resolvers — which would abort the script instead of reaching the empty-result
  # branch. Swallowing the status makes "no resolvers" a value, not a fatal error.
  awk '/^[[:space:]]*nameserver/ {print $2}' "$f" 2>/dev/null \
    | grep -E "^${octet}(\.${octet}){3}$" | sort -u || true
}

if [ "${1:-}" = "--print-resolvers" ]; then
  compose_dns_resolvers "${2:-/etc/resolv.conf}"
  exit 0
fi

# Split one allowlist entry into `<domain> <comma-separated tcp ports>`, applying
# the 443 default, or return 1 on a malformed entry. Validation is strict on
# purpose: an entry that passes here is later interpolated into `ipset add`
# arguments, and the domain half into a `dig` argument, so both halves are
# constrained to their literal grammar (hostname labels; 1-65535 integers) and
# nothing else. A profile file is root-owned boundary config, but "trusted" is not
# a reason to hand its bytes to a command line unparsed.
#
# Only TCP ports are expressible. Nothing in any profile needs UDP today; when
# something does, extend the grammar (e.g. `udp/1234`) rather than widening the
# default. The `--print-entries` hook below exposes this parse for the unit tests.
parse_entry() {
  local entry="$1" domain ports port label
  label='[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?'
  domain="${entry%%:*}"
  if [ "$domain" = "$entry" ]; then
    ports="443"
  else
    ports="${entry#*:}"
  fi
  [[ "$domain" =~ ^${label}(\.${label})*$ ]] || return 1
  [[ "$ports" =~ ^[0-9]{1,5}(,[0-9]{1,5})*$ ]] || return 1
  local canon=""
  for port in $(echo "$ports" | tr ',' '\n'); do
    # 10#: a leading zero would otherwise make bash read the number as octal.
    [ "$((10#$port))" -ge 1 ] && [ "$((10#$port))" -le 65535 ] || return 1
    # Emit the CANONICAL number, not the raw string: every downstream consumer
    # (ipset members, the SNI allowlist's `,443,` filter) compares ports textually,
    # so `0443` must become `443` here or it silently matches nothing.
    canon="${canon:+$canon,}$((10#$port))"
  done
  # Tab-separated, because IFS is \n\t in this script: a space would not split
  # under `read -r domain ports` at the consumer.
  printf '%s\t%s\n' "$domain" "$canon"
}

if [ "${1:-}" = "--print-entries" ]; then
  # Inspection hook: the composed allowlist after parsing — `domain<TAB>ports` per
  # line, defaults applied. Exits non-zero on the first malformed entry (and, via
  # set -e on the assignment, on an unknown profile exactly like --print-domains).
  entries="$(compose_domains)"
  while read -r entry; do
    parse_entry "$entry" || { echo "ERROR: malformed egress entry '$entry'" >&2; exit 1; }
  done < <(echo "$entries")
  exit 0
fi

# GitHub zones the filtering resolver must answer for. GitHub is admitted by CIDR
# (phase A ingests api.github.com/meta), so no profile lists these names — but the
# resolver only forwards names it is told about. A `server=/github.com/...` line
# covers github.com AND every subdomain (api., codeload., ssh., pkg., ...); likewise
# githubusercontent.com covers objects./raw./media./github-cloud. — the hosts git,
# gh and git-lfs actually contact. Anything else on GitHub (ghcr.io, github.dev)
# is not in the CIDR ingest either, so it stays unresolved AND unroutable.
GITHUB_DNS_ZONES="github.com githubusercontent.com"

# Compose the dnsmasq config that turns the container's resolver into an ALLOWLIST
# resolver. $1 = newline-separated upstream resolvers (compose_dns_resolvers output),
# $2 = newline-separated allowlisted domains (compose_domains output). Emits the
# whole config on stdout; the --print-dnsmasq-conf hook below makes it testable.
#
# The load-bearing property is what is ABSENT: there is no bare `server=` line and
# `no-resolv` stops dnsmasq reading /etc/resolv.conf, so the daemon has no default
# upstream at all. A name that matches no `server=/<domain>/` line has nowhere to
# go and dnsmasq answers REFUSED — it is never forwarded, which is exactly the
# recursive-forward tunnel (`<data>.attacker.com` through the legitimate resolver,
# finding 6 of docs/reviews/security-review-cc-isolated-egress-2026-08-29.md).
# `server=/<domain>/` matches the domain and every name under it, so an allowlisted
# `api.anthropic.com` resolves api.anthropic.com and *.api.anthropic.com, and
# nothing else under anthropic.com.
#
# With NO upstream (the resolver-scoping else branch: nothing in resolv.conf parsed
# as IPv4) the config has zero server lines and EVERY query is REFUSED — the
# resolver fails closed exactly as the firewall does, rather than inventing one.
compose_dnsmasq_conf() {
  local resolvers="$1" domains="$2" d ns
  printf '%s\n' \
    '# Generated by init-firewall.sh on every firewall run. DO NOT EDIT.' \
    '# Allowlist resolver: names without a server= line below are REFUSED, never forwarded.' \
    'no-resolv' \
    'no-hosts' \
    'no-poll' \
    'bind-interfaces' \
    'listen-address=127.0.0.1' \
    'port=53' \
    'user=dnsmasq'
  if [ -z "$resolvers" ]; then
    echo '# NO UPSTREAM: no IPv4 nameserver parsed from /etc/resolv.conf, so nothing is forwarded.'
    return 0
  fi
  # `$GITHUB_DNS_ZONES` is space-separated; IFS is \n\t, so split it explicitly.
  for d in $(printf '%s\n' "$domains"; echo "$GITHUB_DNS_ZONES" | tr ' ' '\n'); do
    # Profile entries may carry a `:port` suffix (see cc-isolated --register); the
    # resolver only wants the name. Then refuse anything that is not a plain
    # hostname: a `/` or `#` here would be read by dnsmasq as config syntax, and the
    # profiles are root-owned but this is the one place a stray line becomes a
    # directive rather than a blocked destination.
    d="${d%%:*}"
    [ -n "$d" ] || continue
    # Same label grammar as parse_entry (a single label is allowed there, so it must
    # be allowed here too — otherwise an entry can be ipset-admitted yet unresolvable).
    if [[ ! "$d" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)*$ ]]; then
      echo "WARNING: not a hostname, omitting from resolver allowlist (stays unresolvable): $d" >&2
      continue
    fi
    while read -r ns; do
      [ -n "$ns" ] || continue
      echo "server=/$d/$ns"
    done < <(printf '%s\n' "$resolvers")
  done
}

if [ "${1:-}" = "--print-dnsmasq-conf" ]; then
  compose_dnsmasq_conf "$(compose_dns_resolvers "${2:-/etc/resolv.conf}")" "$(compose_domains)"
  exit 0
fi

# FAIL CLOSED ON ANY INCOMPLETE RUN.
#
# Installed here — immediately after the --print-domains early exit, and BEFORE
# anything else — because "abort before touching iptables" is only safe on a re-run.
# On a FRESH container, not flushing leaves Docker's default all-ACCEPT state, which
# is exactly as wide open as a half-built ruleset. So every abort path from this line
# onward, pre-flush ones included, must end at DROP.
#
# The guard is a COMPLETION SENTINEL, not `$?`. Trusting the exit status is subtly
# wrong: when the shell is terminated by a signal, `$?` inside the EXIT trap is the
# last *completed* command's status (0), so a status-based guard silently no-ops and
# leaves the container open — the exact failure the trap exists to prevent. Keying on
# "did the script reach its end" instead makes every incomplete path fail closed,
# whatever the status says. The paired `trap ... INT TERM HUP QUIT` below converts a
# signal into a normal exit so the EXIT trap runs at all (bash skips it for untrapped
# signals).
#
# Setting DROP is safe even on a pre-flush abort with an intact firewall from a
# previous run: the policy is already DROP there and the accept RULES are untouched,
# so the container keeps working. It only bites on a genuinely half-built ruleset,
# where closed is the only acceptable answer.
#
# The policy calls are VERIFIED, not trusted. `|| true` is still required (the trap
# must never abort itself), but it also means the last line of defence can silently
# not happen — realistically by losing the xtables lock to another iptables process
# (`-w 5` waits for it rather than failing instantly). So the trap re-reads the live
# policies with `iptables -S` afterwards and says which of two very different things
# happened: the container is closed, or it may be OPEN and a human must act. The
# "forced DROP" line is printed only AFTER the read-back confirms it, so the log never
# claims a DROP that was not applied.
FIREWALL_COMPLETE=0
fail_closed_on_abort() {
  local chain policies open=0
  if [ "${FIREWALL_COMPLETE:-0}" != "1" ]; then
    echo "ERROR: init-firewall.sh did not complete." >&2
    iptables -w 5 -P OUTPUT DROP || true
    iptables -w 5 -P INPUT DROP || true
    iptables -w 5 -P FORWARD DROP || true
    # IPv6 too (best effort — see the IPv6 block in phase B for why it is enforced).
    if command -v ip6tables >/dev/null 2>&1; then
        ip6tables -w 5 -P OUTPUT DROP || true
        ip6tables -w 5 -P INPUT DROP || true
        ip6tables -w 5 -P FORWARD DROP || true
    fi
    policies="$(iptables -w 5 -S 2>/dev/null || true)"
    for chain in OUTPUT INPUT FORWARD; do
      if ! grep -q "^-P $chain DROP" <<< "$policies"; then
        open=1
        echo "ERROR: could not force DROP policy on $chain — container may be OPEN." >&2
      fi
    done
    if [ "$open" = "1" ]; then
      echo "       Verify with \`iptables -S\` and set the policies by hand, or recreate" >&2
      echo "       the container. Do NOT start a session in this container as-is." >&2
    else
      echo "       Forced DROP policies (verified): the container fails CLOSED (no" >&2
      echo "       egress), never wide open." >&2
    fi
    echo "       If this container can no longer bootstrap, recreate it from the host:" >&2
    echo "         devcontainer up --remove-existing-container --workspace-folder <repo>" >&2
  fi
}
trap fail_closed_on_abort EXIT
trap 'exit 143' INT TERM HUP QUIT

# ONE RUN AT A TIME. `node` can start this script whenever it likes (NOPASSWD sudo),
# including twice at once. Two interleaved runs can each pass their own probes while
# one of them has flushed the other's half-built guard chains out from under it —
# the second run's `iptables -F` lands between the first run's guard-jump appends
# and its `-o lo` accept, and the first run then completes "successfully" with the
# DNS guards missing. Serialise on a root-owned lock so a second invocation waits
# for the first to finish (or fails closed via the trap if it cannot get the lock).
# The lock is taken AFTER the trap is installed so a lock failure also ends at DROP.
FIREWALL_LOCK="${CC_FIREWALL_LOCK:-/run/cc-firewall.lock}"
exec 9>"$FIREWALL_LOCK"
if ! flock -w "${CC_FIREWALL_LOCK_WAIT:-120}" 9; then
    echo "ERROR: another init-firewall.sh run is still holding $FIREWALL_LOCK" >&2
    exit 1
fi

ALLOWED_DOMAINS="$(compose_domains)"
if [ -z "$ALLOWED_DOMAINS" ]; then
  echo "ERROR: composed egress allowlist is empty" >&2
  exit 1
fi
# Parse every entry NOW, before any network read, so a malformed profile line is a
# hard, immediate error rather than something discovered mid-rebuild. Same stance
# as the unknown-profile check: boundary config that does not parse must not
# silently narrow (or widen) the allowlist.
ALLOWED_ENTRIES=""
while read -r entry; do
  parsed="$(parse_entry "$entry")" || {
    echo "ERROR: malformed egress entry '$entry' (want domain[:port[,port...]])" >&2
    exit 1
  }
  ALLOWED_ENTRIES="${ALLOWED_ENTRIES}${parsed}"$'\n'
done < <(echo "$ALLOWED_DOMAINS")
echo "Egress profiles: $(cat "$PROFILE_FILE" 2>/dev/null || echo '(base only)')"

# ===========================================================================
# PHASE A — RESOLVE EVERYTHING FIRST, WHILE THE OLD FIREWALL IS STILL UP.
#
# Every network read the rebuild depends on (GitHub's published CIDRs, plus one
# A lookup per allowlisted domain) happens HERE, before a single rule is
# touched. That ordering is what makes failing closed safe:
#
#   - On a RE-RUN the previous ruleset is still installed and already permits
#     exactly these destinations, so the reads succeed under the live boundary.
#     If one fails anyway (a GitHub 5xx, a DNS blip) the script exits with the
#     WORKING firewall untouched: a transient outage can no longer half-build a
#     ruleset, and — with the fail-closed trap above — can no longer leave the
#     container bricked with DROP policies over empty chains.
#   - PHASE B below then needs no egress whatsoever. The flush→DROP window
#     therefore contains only local iptables/ipset calls: it shrinks from
#     "seconds to minutes of unrestricted egress while curl and N digs run" to
#     microseconds, and nothing inside it can fail on the network.
#
# This is what lets the DROP policies move up to immediately after the flush.
# ===========================================================================
echo "Fetching GitHub IP ranges..."
# `|| true`: a bare `var=$(cmd)` assignment propagates cmd's status to `set -e`,
# so without it a failed curl aborts here and the -z check below — the error path
# this script explicitly wrote — is unreachable dead code. The timeouts bound the
# wait so a blocked SYN fails fast rather than hitting the kernel's ~127s SYN-retry
# ceiling (cc-isolated.sh re-runs this script automatically, so an unbounded stall
# would surface as a multi-minute hang before an error that could be immediate).
gh_ranges=$(curl -s --connect-timeout 5 --max-time 15 https://api.github.com/meta || true)
if [ -z "$gh_ranges" ]; then
    echo "ERROR: Failed to fetch GitHub IP ranges" >&2
    exit 1
fi

if ! echo "$gh_ranges" | jq -e '.web and .api and .git' >/dev/null; then
    echo "ERROR: GitHub API response missing required fields" >&2
    exit 1
fi

# Validate every CIDR NOW, so phase B's population loop cannot abort on bad input.
GH_CIDRS="$(echo "$gh_ranges" | jq -r '(.web + .api + .git)[]' | aggregate -q)"
while read -r cidr; do
    [ -n "$cidr" ] || continue
    if [[ ! "$cidr" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
        echo "ERROR: Invalid CIDR range from GitHub meta: $cidr" >&2
        exit 1
    fi
done < <(echo "$GH_CIDRS")

# Resolve the composed allowlist. Collected into a variable rather than added to
# the ipset directly, because the ipset does not exist yet — it is created in
# phase B, after the flush destroys the old one. Each collected line is a
# ready-made `hash:net,port` member, `<ip>,tcp:<port>` — one per (address, port)
# pair the entry grants.
RESOLVED_MEMBERS=""
ANTHROPIC_PROBE_IP=""
while read -r domain ports; do
    [ -n "$domain" ] || continue
    echo "Resolving $domain (tcp $ports)..."
    # `|| true` for the same reason as the GitHub fetch: a dig failure (e.g. exit 9,
    # no server reached) would otherwise abort here instead of reaching the
    # warn-and-skip below — the very handling the statsig incident added.
    # +time/+tries bound the wait, but deliberately NOT at their most aggressive:
    # on failure a domain is skipped and stays blocked, which reads as a mysterious
    # outage, so allow 2 tries x 3s rather than a single 2s attempt a merely-slow
    # resolver would lose.
    ips=$(dig +time=3 +tries=2 +noall +answer A "$domain" | awk '$4 == "A" {print $5}' || true)
    if [ -z "$ips" ]; then
        # A dead domain must not brick session start (statsig.anthropic.com went
        # NXDOMAIN in 2026-07 and did exactly that). Failing closed is safe here —
        # the domain just stays unreachable — except api.anthropic.com, without
        # which CC cannot run at all.
        if [ "$domain" = "api.anthropic.com" ]; then
            echo "ERROR: Failed to resolve critical domain $domain" >&2
            exit 1
        fi
        echo "WARNING: Failed to resolve $domain - skipping (stays blocked)"
        continue
    fi

    while read -r ip; do
        if [[ ! "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            echo "ERROR: Invalid IP from DNS for $domain: $ip" >&2
            exit 1
        fi
        echo "Resolved $ip for $domain"
        # Remembered for the SNI-proxy negative probe at the end: an address that IS
        # in the ipset, reached with a name that is NOT allowlisted, must fail.
        if [ "$domain" = "api.anthropic.com" ] && [ -z "${ANTHROPIC_PROBE_IP:-}" ]; then
            ANTHROPIC_PROBE_IP="$ip"
        fi
        for port in $(echo "$ports" | tr ',' '\n'); do
            RESOLVED_MEMBERS="${RESOLVED_MEMBERS}${ip},tcp:${port}"$'\n'
        done
    done < <(echo "$ips")
done < <(echo "$ALLOWED_ENTRIES")

# --- dnsmasq preconditions (see the FILTERING RESOLVER block in phase B) --------
# Checked HERE, before the flush, so a broken image (no binary, no service user)
# aborts with the live ruleset intact instead of failing closed mid-rebuild.
# The two paths are env-overridable for the unit tests only: this script runs via
# sudo (NOPASSWD, no SETENV), whose env_reset strips them, exactly as for
# CC_EGRESS_DIR above.
DNSMASQ_CONF="${CC_DNSMASQ_CONF:-/etc/dnsmasq.d/cc-allowlist.conf}"
DNSMASQ_PIDFILE="${CC_DNSMASQ_PIDFILE:-/run/cc-dnsmasq.pid}"
if ! command -v dnsmasq >/dev/null 2>&1; then
    echo "ERROR: dnsmasq is not installed (Dockerfile installs dnsmasq-base)" >&2
    exit 1
fi
# Numeric, so the iptables owner rules never depend on a name lookup at rule time,
# and never 0: the whole design rests on dnsmasq NOT being root.
DNSMASQ_UID="$(id -u dnsmasq 2>/dev/null || true)"
if [[ ! "$DNSMASQ_UID" =~ ^[0-9]+$ ]] || [ "$DNSMASQ_UID" -eq 0 ]; then
    echo "ERROR: no unprivileged 'dnsmasq' user (got '${DNSMASQ_UID:-none}')" >&2
    exit 1
fi

# Stop a previous instance so a re-run never double-starts. By pidfile first,
# and only if that pid is actually a dnsmasq (a stale file must not kill whatever
# now owns the number); then a sweep by uid, because nothing else in this
# container ever runs as the dnsmasq user, so any survivor is an orphan of ours.
stop_dnsmasq() {
    local pid _
    if [ -r "$DNSMASQ_PIDFILE" ]; then
        pid="$(tr -dc '0-9' < "$DNSMASQ_PIDFILE")"
        if [ -n "$pid" ] && [ "$(cat "/proc/$pid/comm" 2>/dev/null)" = "dnsmasq" ]; then
            kill "$pid" 2>/dev/null || true
            for _ in $(seq 1 30); do
                kill -0 "$pid" 2>/dev/null || break
                sleep 0.1
            done
            if kill -0 "$pid" 2>/dev/null; then kill -9 "$pid" 2>/dev/null || true; fi
        fi
        rm -f "$DNSMASQ_PIDFILE"
    fi
    pkill -x -U "$DNSMASQ_UID" dnsmasq 2>/dev/null || true
}

# --- SNI proxy preconditions (see the SNI PROXY block in phase B) ---------------
# Same stance as dnsmasq: every "is the machinery there" check runs in phase A so a
# missing piece aborts before the flush, leaving the live ruleset intact. Paths are
# overridable for the unit tests only; in the image they are the root-owned
# defaults. The proxy binary is executed directly (root-owned, 0555, hashed by the
# launcher's manifest) with a shebang pinned to /usr/bin/python3 — NOT `env python3`,
# which would be a PATH lookup — and this script fixes its own PATH to root-owned
# directories at the top (see CC_FIREWALL_PATH), so neither the interpreter nor any
# helper this script runs as root can be substituted from a node-writable directory.
SNI_PROXY_BIN="${CC_SNI_PROXY_BIN:-/usr/local/bin/cc-sni-proxy.py}"
SNI_RUN_DIR="${CC_SNI_RUN_DIR:-/run/cc-sni-proxy}"
SNI_ALLOWLIST="$SNI_RUN_DIR/allowlist"
SNI_PIDFILE="$SNI_RUN_DIR/proxy.pid"
SNI_LOG="$SNI_RUN_DIR/proxy.log"
SNI_PORT="${CC_SNI_PORT:-3443}"
if [ ! -x "$SNI_PROXY_BIN" ]; then
    echo "ERROR: SNI proxy $SNI_PROXY_BIN is missing or not executable (Dockerfile installs it)" >&2
    exit 1
fi
# The proxy runs as its own unprivileged uid so the owner-match rules can tell its
# egress apart from the agent's. Numeric, non-zero, and distinct from dnsmasq.
CCPROXY_UID="$(id -u ccproxy 2>/dev/null || true)"
if [[ ! "$CCPROXY_UID" =~ ^[0-9]+$ ]] || [ "$CCPROXY_UID" -eq 0 ] || [ "$CCPROXY_UID" = "$DNSMASQ_UID" ]; then
    echo "ERROR: no distinct unprivileged 'ccproxy' user (got '${CCPROXY_UID:-none}')" >&2
    exit 1
fi

# ===========================================================================
# PHASE B — REBUILD. No network reads past this point.
# ===========================================================================

# 1. Extract Docker DNS info BEFORE any flushing
DOCKER_DNS_RULES=$(iptables-save -t nat | grep "127\.0\.0\.11" || true)

# Close the window BEFORE it opens: set the DROP policies first, then flush. Chain
# policies survive `iptables -F` (a flush removes rules, not policies), so ordering
# them ahead of the flush means there is no instant — not even the microseconds
# between two local iptables calls — at which the chains are empty AND the policy is
# ACCEPT. Phase A already did every network read, so nothing between here and the
# finished ruleset needs egress. Previously these policies were set only at the very
# end, leaving a fresh container fully open (empty chains, default-ACCEPT policy) for
# as long as the GitHub fetch and the per-domain digs took — a window `node` could
# re-enter on demand via its NOPASSWD sudo. Accept rules added below still take
# effect: a policy applies only when no rule matches.
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# Flush existing rules and delete existing ipsets (policies set above persist)
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
ipset destroy allowed-domains 2>/dev/null || true

# IPv6: DEFAULT-DENY, no allowlist. Every control in this script — the address+port
# ipset, the filtering resolver's redirect, the SNI proxy's redirect, the guard
# chains — is IPv4-only, so an unfiltered IPv6 path would be a single bypass for all
# of them (security review 2026-09-03, finding 1). Rather than duplicate the whole
# allowlist for a family nothing here needs, IPv6 is closed outright: loopback and
# already-established flows only. A container that genuinely needs IPv6 egress needs
# an IPv6 allowlist designed for it, not this rule set relaxed. If ip6tables is
# absent the kernel has no IPv6 filter to configure and the check is skipped — that
# is the one case this cannot close, and the probe at the end reports it.
if command -v ip6tables >/dev/null 2>&1; then
    ip6tables -P INPUT DROP
    ip6tables -P FORWARD DROP
    ip6tables -P OUTPUT DROP
    ip6tables -F
    ip6tables -X
    ip6tables -A INPUT -i lo -j ACCEPT
    ip6tables -A OUTPUT -o lo -j ACCEPT
    ip6tables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    ip6tables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    echo "IPv6: default-deny installed (loopback and established flows only)"
else
    echo "WARNING: ip6tables not found — IPv6 egress is NOT filtered in this container" >&2
fi

# 2. Selectively restore ONLY internal Docker DNS resolution
if [ -n "$DOCKER_DNS_RULES" ]; then
    echo "Restoring Docker DNS rules..."
    iptables -t nat -N DOCKER_OUTPUT 2>/dev/null || true
    iptables -t nat -N DOCKER_POSTROUTING 2>/dev/null || true
    echo "$DOCKER_DNS_RULES" | xargs -L 1 iptables -t nat
else
    echo "No Docker DNS rules to restore"
fi

# First allow DNS and localhost before any restrictions
#
# Outbound DNS is scoped to the container's CONFIGURED resolvers (from
# /etc/resolv.conf), not to 0.0.0.0/0. A blanket `--dport 53 ACCEPT` lets a
# compromised session point a UDP socket straight at an attacker-controlled
# authoritative nameserver (attacker_ip:53) and stream data out in the query
# names — a clean, high-bandwidth exfil channel that bypasses the whole
# allowlist. Scoping to the real resolvers removes that direct path: the agent
# must go through the embedded/host resolver, which only does name recursion.
# PRECISION: the hardening here is the DELETION of the old blanket accept, not the
# addition of these scoped rules — where the resolver is loopback or the bridge
# gateway, the `-o lo` accept and the gateway-DNS accept below already admit it and
# these rules are redundant. They are load-bearing only for a resolver that is
# neither. The effective outbound-53 scope is therefore resolvers ∪ loopback ∪
# gateway, not resolvers alone (it was resolvers ∪ loopback ∪ the whole host /24 on
# every port until the host-network accept was narrowed; see below). IPv4 only:
# IPv6 is closed outright by the ip6tables default-deny block in phase B, so
# nothing here needs an IPv6 counterpart.
# (Recursive-forward DNS tunnelling — `<data>.attacker.com` resolved through the
# legitimate resolver — is NOT closed by this scoping alone; it is closed by the
# FILTERING RESOLVER block that follows, which is why these accepts are now
# owner-scoped to that resolver. See
# docs/reviews/security-review-cc-isolated-egress-2026-08-29.md finding 6.)
#
# TRUST ASSUMPTION: this scoping is only as trustworthy as /etc/resolv.conf. In
# practice Docker writes that file root-owned, so `node` (which can re-run this
# script via its NOPASSWD sudo, see Dockerfile) cannot modify it — but that is a
# Docker runtime default this repo does NOT enforce or assert anywhere. If it ever
# ceases to hold — an
# agent-writable resolv.conf via a mount or a `--dns` value the agent influences —
# a session could inject `nameserver <attacker_ip>` and get a *scoped* accept to
# it, restoring the direct-exfil channel through the front door. Keep resolv.conf
# root-owned and not agent-writable, or this control inverts.
#
# Parsing and octet validation live in compose_dns_resolvers (see its comments, and
# the --print-resolvers hook that makes this logic testable).
dns_resolvers="$(compose_dns_resolvers)"
if [ -n "$dns_resolvers" ]; then
  while read -r ns; do
    echo "Allowing DNS to configured resolver $ns"
    # `|| echo` (not a bare call): a failed add must not abort the script in the
    # post-flush/pre-DROP wide-open window — skipping a resolver fails CLOSED for
    # that resolver, which is the safe direction; aborting fails OPEN for everything.
    # OWNER-SCOPED (FILTERING RESOLVER block below): only dnsmasq and root may talk
    # to the upstream. Everything else is REDIRECTed to dnsmasq in nat OUTPUT
    # before it gets here, and the CC_DNS_GUARD jumps reject whatever is not.
    for owner in "$DNSMASQ_UID" 0; do
      iptables -A OUTPUT -p udp -d "$ns" --dport 53 -m owner --uid-owner "$owner" -j ACCEPT || echo "WARNING: could not add UDP DNS rule for $ns (uid $owner)" >&2
      iptables -A OUTPUT -p tcp -d "$ns" --dport 53 -m owner --uid-owner "$owner" -j ACCEPT || echo "WARNING: could not add TCP DNS rule for $ns (uid $owner)" >&2
    done
  done < <(echo "$dns_resolvers")
else
  # NO IPv4 DNS ACCEPT IS INSTALLED HERE — deliberately, and this branch adds no
  # rules at all. Reaching it means no line in resolv.conf parsed as an IPv4
  # address, so by construction we do not know what to scope to; there is no
  # address that is both safe and useful to name. The two candidates both fail:
  # a blanket 0.0.0.0/0 accept would re-grant exactly the attacker_ip:53 exfil
  # channel this change exists to remove, and pinning 127.0.0.11 would be inert —
  # 127.0.0.11 parses as a valid IPv4, so had it been the resolver we would have
  # taken the `if` branch and never arrived here.
  #
  # Failing closed for IPv4 DNS is safe in every case that actually reaches this
  # branch, because the paths that matter are not on it:
  #   - IPv6-only resolv.conf: IPv6 is default-denied in phase B (no allowlist), so
  #     such a resolver is unreachable and resolution fails closed — a container with
  #     only an IPv6 resolver needs an IPv6 allowlist, which this script does not
  #     provide. (The line below predates that block and describes the old state:)
  #     IPv6 DNS is unfiltered and resolution keeps working.
  #   - a loopback resolver: already admitted unconditionally by `-o lo` below,
  #     independent of anything here (and Docker's embedded resolver is DNAT'd off
  #     port 53 in nat OUTPUT before filter OUTPUT sees it, so a --dport 53 filter
  #     rule would not match that traffic regardless).
  #   - the bridge gateway as resolver: admitted by the gateway-DNS accept below.
  # What is left is a malformed resolv.conf naming a non-loopback IPv4 resolver we
  # could not parse — a broken configuration, which should fail loudly and closed
  # rather than be papered over by opening DNS to the world.
  echo "WARNING: no parseable IPv4 nameserver in /etc/resolv.conf — installing NO IPv4 DNS" >&2
  echo "         accept. Loopback/host-network/IPv6 resolution is unaffected (see comment);" >&2
  echo "         a non-loopback IPv4 resolver would fail to resolve. Fix resolv.conf." >&2
fi

# ===========================================================================
# FILTERING RESOLVER — closes recursive-forward DNS tunnelling (finding 6 of
# docs/reviews/security-review-cc-isolated-egress-2026-08-29.md; decision log #40).
#
# THE HOLE. Resolver scoping (above) stops a session sending UDP straight at
# attacker_ip:53, but the legitimate resolver is itself recursive: ask it for
# `<base32-data>.attacker.com` and it dutifully forwards the query to the
# attacker's authoritative nameserver. No IP rule can tell that query from a
# lookup of api.anthropic.com — both go to the same resolver. Only something that
# reads the NAME can, so the fix is a resolver, not a rule.
#
# THE FIX. dnsmasq runs in the container as its own unprivileged uid, listening
# on 127.0.0.1:53 only, with `no-resolv` and NO default upstream: it carries one
# `server=/<domain>/<upstream>` line per allowlisted domain (plus the GitHub
# zones that arrive by CIDR) and answers REFUSED to every other name — nothing
# unlisted is ever forwarded. The upstreams are the same resolvers the block
# above parsed from /etc/resolv.conf (Docker's 127.0.0.11 or the host's), so the
# else branch composes to the same fail-closed answer: no upstream, everything
# REFUSED. compose_dnsmasq_conf (top of file) builds the config; the
# --print-dnsmasq-conf hook prints it without touching anything.
#
# HOW TRAFFIC IS STEERED — nat REDIRECT, not a rewritten resolv.conf. Two ways
# to make the container use 127.0.0.1: (a) write `nameserver 127.0.0.1` into
# /etc/resolv.conf, or (b) REDIRECT port-53 traffic to 127.0.0.1 in nat OUTPUT.
# (b) is chosen because:
#   - /etc/resolv.conf is Docker's. Both Docker Desktop and Docker Engine
#     bind-mount it from the daemon's per-container state and regenerate it on
#     every start (Engine additionally rewrites it when the host's resolvers
#     change), so a rewrite is at best re-applied by every postStartCommand and
#     at worst silently reverted underneath a running session. A REDIRECT lives
#     in the same nat table this script already flushes and rebuilds
#     atomically, and Docker's own 127.0.0.11 DNAT is proof that nat OUTPUT works
#     under both runtimes.
#   - Rewriting would also destroy the very upstream list compose_dns_resolvers
#     needs on the next re-run (it would parse 127.0.0.1 and nothing else),
#     forcing a second root-owned state file to remember the real resolvers.
#   - A REDIRECT is enforced by the kernel for every process, including one that
#     ignores resolv.conf and hardcodes 8.8.8.8:53 — strictly stronger than a
#     file a library may or may not honour.
#
# WHO IS EXEMPT, AND WHY. Two uids bypass the redirect and keep the upstream
# accepts above: dnsmasq itself (it must reach the upstream or nothing resolves)
# and root. Root is exempt so phase A keeps working on a RE-RUN: its `dig`s and
# the GitHub /meta curl run as root against resolv.conf's resolvers, and steering
# them through the *previous* instance would make the rebuild depend on that
# instance being alive and current. Exempting root costs nothing in the threat
# model: `node` reaches root only through this root-owned script (NOPASSWD sudo
# for this path alone), and a session that already has container root owns the
# firewall outright. Consequence to be aware of: root's own lookups are NOT
# filtered — root is not the boundary being defended.
# iptables takes one --uid-owner per rule, so "neither uid" is expressed as a
# chain that RETURNs for the two exempt uids and acts on everything else.
#
# THE BYPASS THIS MUST ALSO CLOSE. Docker's embedded resolver at 127.0.0.11 does
# not listen on 53: nat OUTPUT DNATs 127.0.0.11:53 to 127.0.0.11:<random port>,
# and that port is readable from /proc/net/udp. A session sending straight to
# 127.0.0.11:<port> never carries dport 53, so a port-53 match never sees it and
# the unconditional `-o lo` accept below would wave it through to a recursive
# resolver. Hence the CC_DNS_GUARD jump on 127.0.0.11 for ALL ports, installed
# BEFORE the loopback accept (a `-m conntrack --ctorigdstport 53` match would
# catch the DNAT'd flow, but an all-port match on that address subsumes it and
# is not fooled by a flow whose original port was never 53). Node's redirected
# queries arrive in filter with dst 127.0.0.1, so they still pass on `-o lo`.
#
# ORDER OF OPERATIONS. The nat rules are INSERTED at position 1, ahead of the
# `-d 127.0.0.11 -j DOCKER_OUTPUT` jump restored above: were they appended, a
# node query to 127.0.0.11:53 would be DNAT'd to the embedded resolver before the
# redirect could claim it. Filter-side, this block only creates CC_DNS_GUARD; the
# jumps into it are placed immediately before the `-o lo` accept further down.
# Every call here is bare (no `|| true`): the DROP policies are already in place,
# so an iptables failure aborts to the fail-closed trap — the safe direction — and
# a boundary that could not install its resolver steering is not a boundary.
#
# RESIDUAL. dnsmasq matches zones by suffix. An attacker who controls an
# authoritative subdomain UNDER an allowlisted zone (a third-party delegation
# inside a listed domain) can still tunnel through it. None of the base zones
# (api.anthropic.com, claude.ai, console.anthropic.com, platform.claude.com,
# registry.npmjs.org, github.com, githubusercontent.com) hand out delegations to
# third parties; a profile that adds a zone which does (e.g. a bare CDN apex)
# re-opens this, so keep entries as specific as the hostnames actually needed.
# Bandwidth is further bounded by the upstream's caching. IPv6 remains
# unfiltered end to end (pre-existing).
# ===========================================================================
echo "Configuring filtering resolver (dnsmasq)..."
mkdir -p "$(dirname "$DNSMASQ_CONF")"
compose_dnsmasq_conf "$dns_resolvers" "$ALLOWED_DOMAINS" > "$DNSMASQ_CONF"
chmod 0644 "$DNSMASQ_CONF"

# Idempotent restart: kill by pidfile, then start exactly one instance. dnsmasq's
# parent only exits after the daemon has bound its socket, and exits non-zero if
# it could not (port in use, bad config), so under set -e a failed start aborts
# to the fail-closed trap rather than leaving node with no resolver and no error.
# --conf-file REPLACES the packaged /etc/dnsmasq.conf, so nothing but the file
# generated above (which drops to `user=dnsmasq` after binding) is ever read.
stop_dnsmasq
dnsmasq --conf-file="$DNSMASQ_CONF" --pid-file="$DNSMASQ_PIDFILE"
for _ in $(seq 1 30); do
    [ -s "$DNSMASQ_PIDFILE" ] && break
    sleep 0.1
done
dnsmasq_pid="$(tr -dc '0-9' < "$DNSMASQ_PIDFILE" 2>/dev/null || true)"
if [ -z "$dnsmasq_pid" ] || ! kill -0 "$dnsmasq_pid" 2>/dev/null; then
    echo "ERROR: dnsmasq did not start (no live pid in $DNSMASQ_PIDFILE)" >&2
    exit 1
fi
echo "dnsmasq running as uid $DNSMASQ_UID (pid $dnsmasq_pid), config $DNSMASQ_CONF"

# nat: steer every non-exempt port-53 flow to 127.0.0.1:53.
iptables -t nat -N CC_DNS
iptables -t nat -A CC_DNS -m owner --uid-owner "$DNSMASQ_UID" -j RETURN
iptables -t nat -A CC_DNS -m owner --uid-owner 0 -j RETURN
iptables -t nat -A CC_DNS -p udp -j REDIRECT --to-ports 53
iptables -t nat -A CC_DNS -p tcp -j REDIRECT --to-ports 53
iptables -t nat -I OUTPUT 1 -p tcp --dport 53 -j CC_DNS
iptables -t nat -I OUTPUT 1 -p udp --dport 53 -j CC_DNS

# filter: the guard chain. Jumped to (before the loopback accept) for the
# embedded resolver on any port and for any port-53 flow not aimed at dnsmasq —
# defence in depth behind the redirect, so a flow that somehow escaped nat
# (conntrack exhaustion, a future rule ordering slip) is still refused.
iptables -N CC_DNS_GUARD
iptables -A CC_DNS_GUARD -m owner --uid-owner "$DNSMASQ_UID" -j RETURN
iptables -A CC_DNS_GUARD -m owner --uid-owner 0 -j RETURN
iptables -A CC_DNS_GUARD -j REJECT --reject-with icmp-admin-prohibited
# ===================== end FILTERING RESOLVER block =========================
# NOTE: no inbound `--sport 53` accept. DNS replies to the scoped OUTPUT rules above
# are already admitted by the `INPUT -m state --state ESTABLISHED,RELATED` accept near
# the end, so a blanket `-A INPUT -p udp --sport 53 -j ACCEPT` added nothing
# legitimate — and what it did add was an unsolicited-inbound path: any host that can
# address the container and sets its source port to 53 walked straight through the
# INPUT DROP policy, a one-way command channel to an already-compromised process.
# NOTE: no blanket outbound-SSH accept. A `--dport 22 -j ACCEPT` to 0.0.0.0/0 is
# an unconditional tunnel out of the sandbox: an attacker runs C2/SSH on port 22
# and the agent can `ssh -L`/`-D` arbitrary TCP through it, defeating the entire
# default-deny allowlist. SSH to ALLOWLISTED hosts still works — GitHub's SSH
# endpoints sit inside the `.web + .api + .git` CIDRs phase A ingests from
# api.github.com/meta (only those three keys, not every GitHub service), and those
# CIDRs go into the allowed-domains ipset on tcp 443 AND tcp 22, which the OUTPUT
# accept near the end matches on dst address+port; the ESTABLISHED,RELATED accept
# covers the return path. A project that must reach a NON-GitHub SSH host adds
# `that.host:22` to its egress profile (a host-side --register + re-bless), exactly
# like any other destination — SSH is not a silent exception to the boundary.
# Allow localhost
iptables -A INPUT -i lo -j ACCEPT
# FILTERING RESOLVER: these must precede the loopback accept (see that block).
# 127.0.0.11 on ALL ports — the embedded resolver's real port is not 53 — and any
# port-53 flow that is not to dnsmasq at 127.0.0.1; both RETURN for dnsmasq/root.
iptables -A OUTPUT -d 127.0.0.11 -j CC_DNS_GUARD
iptables -A OUTPUT -p udp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD
iptables -A OUTPUT -p tcp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD
iptables -A OUTPUT -o lo -j ACCEPT

# Create the ipset. `hash:net,port` (not plain `hash:net`) so every member is an
# (address-or-CIDR, proto:port) pair and the OUTPUT match below is on `dst,dst` —
# destination address AND destination port. A plain hash:net admitted any port on
# a matched address, which turned every allowlisted host into a wildcard for
# whatever else listens on it (the `llm` profile's host.docker.internal exposed
# every host port, not just the model server's).
ipset create allowed-domains hash:net,port

# Populate the ipset from what phase A already fetched and validated. Every value
# here has passed its regex check, so these loops cannot abort on bad input; and
# nothing in them touches the network.
echo "Processing GitHub IPs..."
while read -r cidr; do
    [ -n "$cidr" ] || continue
    echo "Adding GitHub range $cidr (tcp 443, 22)"
    # -exist: tolerate duplicates — under set -e a duplicate add would otherwise
    # kill the script mid-rebuild.
    # 443 for HTTPS (api/web/git-over-https), 22 for git-over-SSH. Nothing else:
    # these are the only ports git and gh use against GitHub.
    ipset add -exist allowed-domains "$cidr,tcp:443"
    ipset add -exist allowed-domains "$cidr,tcp:22"
done < <(echo "$GH_CIDRS")

while read -r member; do
    [ -n "$member" ] || continue
    echo "Adding $member"
    # -exist: domains sharing a CDN can resolve to identical IPs
    # (claude.ai / console.anthropic.com are both on Cloudflare).
    ipset add -exist allowed-domains "$member"
done < <(echo "$RESOLVED_MEMBERS")

# Get host IP from default route
HOST_IP=$(ip route | grep default | cut -d" " -f3)
if [ -z "$HOST_IP" ]; then
    echo "ERROR: Failed to detect host IP"
    exit 1
fi
echo "Bridge gateway detected as: $HOST_IP"

# Bridge-gateway DNS only. The upstream script accepted the whole bridge /24 in both
# directions on every port (`-A INPUT -s <net>/24` / `-A OUTPUT -d <net>/24`), with
# the stated purpose of keeping Docker-internal DNS and sidecar traffic working.
# That was far wider than the purpose: any container on the same bridge — another
# project's sandbox, a sidecar, anything the host happens to attach — was reachable
# on every port, and could reach this container on every port, bypassing the
# allowlist entirely. What the purpose actually needs is one thing: name resolution
# via the gateway when Docker hands the container the gateway as its resolver.
# Loopback resolvers (Docker's embedded 127.0.0.11) are covered by `-o lo`, and any
# resolver named in /etc/resolv.conf already has its own scoped accept above, so
# this rule is usually redundant with those — it is kept as belt-and-braces for the
# gateway specifically, on udp/tcp 53 and nothing else. There is no inbound
# counterpart: replies are ESTABLISHED,RELATED, which the INPUT accept below admits,
# and nothing on the bridge needs to OPEN a connection into the sandbox.
# Under Docker Desktop the host itself is not in the bridge /24 anyway (it sits at
# the VM gateway, 192.168.65.x — see egress/llm.txt), so host-side services such as
# a local model server were never admitted by the old rule and are admitted now
# only by a port-scoped allowlist entry (`host.docker.internal:11434`). Under
# Docker Engine on Linux, where the host IS the bridge gateway, that is the
# behaviour change to be aware of: host ports other than 53 now need an allowlist
# entry too, which is the point.
# Owner-scoped like the resolver accepts above: only the filtering resolver (and
# root, for this script's own phase-A reads) may talk to the gateway on 53.
# Everyone else's port-53 traffic is redirected to dnsmasq by the CC_DNS chain.
for uid in "$DNSMASQ_UID" 0; do
    iptables -A OUTPUT -p udp -d "$HOST_IP" --dport 53 -m owner --uid-owner "$uid" -j ACCEPT
    iptables -A OUTPUT -p tcp -d "$HOST_IP" --dport 53 -m owner --uid-owner "$uid" -j ACCEPT
done

# Idempotent re-assert. The policies were already set immediately after the flush
# (see there for why); setting a policy twice is a no-op, and keeping this here means
# the finished ruleset states its own default-deny explicitly rather than relying on
# a reader tracing back 200 lines.
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# First allow established connections for already approved traffic
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# ===========================================================================
# SNI PROXY — closes the shared-IP overreach of address matching (finding 5 of
# docs/reviews/security-review-cc-isolated-egress-2026-08-29.md; decision log #41).
#
# THE HOLE. The ipset admits ADDRESSES. A CDN front puts thousands of unrelated
# names behind one address, so "api.anthropic.com:443" also admits everything
# else Cloudflare serves from that IP, and the android profile's Google Front End
# addresses admit writable storage.googleapis.com. No address rule can tell those
# apart; only the name the client asks for can — and for TLS that name travels in
# the clear in the ClientHello's server_name (SNI).
#
# THE FIX. cc-sni-proxy.py (single-file, stdlib-only Python, root-owned in the
# image) runs as its own unprivileged uid. nat OUTPUT REDIRECTs every tcp/443
# connection that is not the proxy's own (and not root's — see below) to it. The
# proxy reads the ClientHello, admits the connection only if the SNI is on the
# allowlist written here, RESOLVES THE SNI NAME ITSELF and connects there, then
# splices bytes. Nothing is decrypted: peek, then splice. Because the proxy
# connects to what the NAME resolves to and never to the client's chosen address,
# a forged SNI cannot steer a connection to an arbitrary IP; and because the
# proxy's own egress still traverses the address+port ipset below, the IP layer
# remains as defence in depth. Its name lookups go through the container resolver
# (the filtering dnsmasq above), so an SNI that is not allowlisted for DNS is
# doubly dead.
#
# SCOPE. Only tcp/443 is redirected. Other allowlisted ports (GitHub ssh on 22,
# a host model server on 11434) are not TLS-to-a-CDN and stay address+port
# matched. Root is exempt from the redirect exactly as it is for dnsmasq: this
# script's own phase-A fetch and the root-run probes must work on a fresh
# container before any proxy exists, and root is reachable only through this
# root-owned script. The consequence is that the SNI check applies to the agent,
# not to root — which is the boundary that matters.
#
# ALLOWLIST. Exact names from every profile entry admitted on 443, plus the
# GitHub zones the CIDR ingest admits by address (`.github.com` etc. — a leading
# dot means "the zone and every subdomain"). Entries not on 443 are omitted: a
# name is only meaningful here on the port that is redirected.
#
# FAIL-CLOSED. If the proxy does not come up, this script exits non-zero and the
# trap forces DROP — a REDIRECT to nothing would otherwise be a silent outage
# that looks like "the network is down", and a missing REDIRECT would be the
# old overreach back. Both are refused.
#
# RESIDUAL. Same shape as the resolver's: an attacker who can obtain a name under
# an allowlisted ZONE (a github.com subdomain is not obtainable; a hosted
# `<org>.ingest.sentry.io`-style name would be, were such a zone allowlisted —
# base no longer carries one) still gets through by name. Exact-name entries have
# no such residual.
echo "Configuring SNI-filtering proxy..."
mkdir -p "$SNI_RUN_DIR"
chmod 0755 "$SNI_RUN_DIR"
# The previous run left the allowlist read-only; replace it rather than open it.
rm -f "$SNI_ALLOWLIST"
{
    echo "# Generated by init-firewall.sh on every firewall run. DO NOT EDIT."
    echo "# Exact names, one per line; a leading dot means the zone and all subdomains."
    while read -r domain ports; do
        [ -n "$domain" ] || continue
        case ",$ports," in *,443,*) echo "$domain" ;; esac
    done < <(echo "$ALLOWED_ENTRIES")
    # GitHub is admitted by CIDR (phase A) rather than by name. The SNI zones are
    # derived from the SAME list the filtering resolver serves (GITHUB_DNS_ZONES),
    # so a name the proxy would admit is always one the resolver will answer for;
    # the two lists cannot drift apart again.
    for zone in $(echo "$GITHUB_DNS_ZONES" | tr ' ' '\n'); do
        echo ".$zone"
    done
} > "$SNI_ALLOWLIST"
chmod 0444 "$SNI_ALLOWLIST"
# --daemon: forks, drops to --user, binds, and exits 0 only once LISTENING (a prior
# instance named by the pidfile is terminated first, so re-runs are idempotent).
# Any other status means "no proxy" → set -e → trap → DROP.
if ! "$SNI_PROXY_BIN" --daemon --pidfile "$SNI_PIDFILE" --user ccproxy \
        --listen "127.0.0.1:$SNI_PORT" --allowlist "$SNI_ALLOWLIST" --log "$SNI_LOG"; then
    echo "ERROR: SNI proxy failed to start (see $SNI_LOG)" >&2
    exit 1
fi
echo "SNI proxy running as uid $CCPROXY_UID on 127.0.0.1:$SNI_PORT, allowlist $SNI_ALLOWLIST"

# nat: redirect tcp/443 to the proxy for every uid except the proxy's and root's.
iptables -t nat -N CC_SNI
iptables -t nat -A CC_SNI -m owner --uid-owner "$CCPROXY_UID" -j RETURN
iptables -t nat -A CC_SNI -m owner --uid-owner 0 -j RETURN
iptables -t nat -A CC_SNI -p tcp -j REDIRECT --to-ports "$SNI_PORT"
iptables -t nat -A OUTPUT -p tcp --dport 443 -j CC_SNI

# filter: belt-and-braces. A tcp/443 flow that somehow escaped the redirect (a
# future rule-ordering slip, conntrack exhaustion) is refused unless it is the
# proxy's or root's — the ipset accept below must never be reachable by the agent
# for 443 directly.
iptables -N CC_SNI_GUARD
iptables -A CC_SNI_GUARD -m owner --uid-owner "$CCPROXY_UID" -j RETURN
iptables -A CC_SNI_GUARD -m owner --uid-owner 0 -j RETURN
iptables -A CC_SNI_GUARD -j REJECT --reject-with icmp-admin-prohibited
iptables -A OUTPUT -p tcp --dport 443 -j CC_SNI_GUARD
# ========================= end SNI PROXY block =============================

# Then allow only specific outbound traffic to allowed domains — matched on
# destination address AND destination port (`dst,dst` against the hash:net,port
# set), so an admitted address is open only on the ports its entry named.
iptables -A OUTPUT -m set --match-set allowed-domains dst,dst -j ACCEPT

# Explicitly REJECT all other outbound traffic for immediate feedback
iptables -A OUTPUT -j REJECT --reject-with icmp-admin-prohibited

echo "Firewall configuration complete"
echo "Verifying firewall rules..."
# --max-time on both probes for the same reason as the phase-A fetch: a probe that
# connects but then stalls would otherwise hang session start indefinitely.
if curl --connect-timeout 5 --max-time 15 https://example.com >/dev/null 2>&1; then
    echo "ERROR: Firewall verification failed - was able to reach https://example.com"
    exit 1
else
    echo "Firewall verification passed - unable to reach https://example.com as expected"
fi

# Verify GitHub API access
if ! curl --connect-timeout 5 --max-time 15 https://api.github.com/zen >/dev/null 2>&1; then
    echo "ERROR: Firewall verification failed - unable to reach https://api.github.com"
    exit 1
else
    echo "Firewall verification passed - able to reach https://api.github.com as expected"
fi

# SNI proxy probes, run AS NODE so they traverse the redirect (root is exempt).
# Positive: an allowlisted name through the proxy must work end to end.
if ! runuser -u node -- curl --connect-timeout 5 --max-time 15 https://api.anthropic.com/ >/dev/null 2>&1; then
    echo "ERROR: Firewall verification failed - node cannot reach https://api.anthropic.com through the SNI proxy (see $SNI_LOG)"
    exit 1
else
    echo "Firewall verification passed - node reaches https://api.anthropic.com through the SNI proxy"
fi
# Negative: an address that IS in the ipset, asked for with a name that is NOT
# allowlisted, must be refused — this is the one check that distinguishes the
# SNI proxy from address matching alone.
if runuser -u node -- curl --connect-timeout 5 --max-time 15 \
        --resolve "not-allowlisted.invalid:443:$ANTHROPIC_PROBE_IP" https://not-allowlisted.invalid/ >/dev/null 2>&1; then
    echo "ERROR: Firewall verification failed - a non-allowlisted SNI reached an allowlisted address"
    exit 1
fi
# A failed curl alone is not proof: a missing redirect, a dead proxy, or a broken
# runuser all fail the same way. The proxy must have SEEN and REFUSED the name.
if ! grep -q "REJECT sni=not-allowlisted.invalid " "$SNI_LOG" 2>/dev/null; then
    echo "ERROR: Firewall verification failed - the SNI proxy did not log a refusal for not-allowlisted.invalid (is the 443 redirect in place? see $SNI_LOG)"
    exit 1
fi
echo "Firewall verification passed - non-allowlisted SNI refused by the proxy (logged)"

# The ruleset is complete and all probes passed. Only now does the EXIT trap stop
# forcing DROP — reaching this line is the sentinel's entire meaning, so it must be
# the last statement in the script and must never be moved above a check.
FIREWALL_COMPLETE=1
