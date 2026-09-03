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
  for port in $(echo "$ports" | tr ',' '\n'); do
    # 10#: a leading zero would otherwise make bash read the number as octal.
    [ "$((10#$port))" -ge 1 ] && [ "$((10#$port))" -le 65535 ] || return 1
  done
  # Tab-separated, because IFS is \n\t in this script: a space would not split
  # under `read -r domain ports` at the consumer.
  printf '%s\t%s\n' "$domain" "$ports"
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
        for port in $(echo "$ports" | tr ',' '\n'); do
            RESOLVED_MEMBERS="${RESOLVED_MEMBERS}${ip},tcp:${port}"$'\n'
        done
    done < <(echo "$ips")
done < <(echo "$ALLOWED_ENTRIES")

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
# this script installs no ip6tables rules, so the whole
# allowlist — not just DNS — is unenforced for IPv6 (a pre-existing gap).
# (Recursive-forward DNS tunnelling — `<data>.attacker.com` resolved through the
# legitimate resolver — is NOT closed by this; that needs a filtering resolver,
# not an IP firewall. See docs/reviews/security-review-cc-isolated-egress-2026-08-29.md.)
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
    iptables -A OUTPUT -p udp -d "$ns" --dport 53 -j ACCEPT || echo "WARNING: could not add UDP DNS rule for $ns" >&2
    iptables -A OUTPUT -p tcp -d "$ns" --dport 53 -j ACCEPT || echo "WARNING: could not add TCP DNS rule for $ns" >&2
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
  #   - IPv6-only resolv.conf: this script installs no ip6tables rules at all, so
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
iptables -A OUTPUT -p udp -d "$HOST_IP" --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp -d "$HOST_IP" --dport 53 -j ACCEPT

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

# The ruleset is complete and both probes passed. Only now does the EXIT trap stop
# forcing DROP — reaching this line is the sentinel's entire meaning, so it must be
# the last statement in the script and must never be moved above a check.
FIREWALL_COMPLETE=1
