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

# Compose the domain list from `base` plus whatever profiles this image was built
# with. Emits one domain per line, deduplicated. Unknown profile = hard failure:
# a typo must not silently degrade to a narrower-than-intended allowlist that
# then looks like a mysterious network outage.
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

# Only the firewall path needs root; composing the list does not. Fail before
# flushing anything if the profile is bad, so a typo can't leave us wide open.
ALLOWED_DOMAINS="$(compose_domains)"
if [ -z "$ALLOWED_DOMAINS" ]; then
  echo "ERROR: composed egress allowlist is empty" >&2
  exit 1
fi
echo "Egress profiles: $(cat "$PROFILE_FILE" 2>/dev/null || echo '(base only)')"

# 1. Extract Docker DNS info BEFORE any flushing
DOCKER_DNS_RULES=$(iptables-save -t nat | grep "127\.0\.0\.11" || true)

# Flush existing rules and delete existing ipsets
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
# Allow outbound DNS
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
# Allow inbound DNS responses
iptables -A INPUT -p udp --sport 53 -j ACCEPT
# Allow outbound SSH
iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT
# Allow inbound SSH responses
iptables -A INPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
# Allow localhost
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Create ipset with CIDR support
ipset create allowed-domains hash:net

# Fetch GitHub meta information and aggregate + add their IP ranges
echo "Fetching GitHub IP ranges..."
gh_ranges=$(curl -s https://api.github.com/meta)
if [ -z "$gh_ranges" ]; then
    echo "ERROR: Failed to fetch GitHub IP ranges"
    exit 1
fi

if ! echo "$gh_ranges" | jq -e '.web and .api and .git' >/dev/null; then
    echo "ERROR: GitHub API response missing required fields"
    exit 1
fi

echo "Processing GitHub IPs..."
while read -r cidr; do
    if [[ ! "$cidr" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
        echo "ERROR: Invalid CIDR range from GitHub meta: $cidr"
        exit 1
    fi
    echo "Adding GitHub range $cidr"
    # -exist: tolerate duplicates — under set -e a duplicate add would kill
    # the script mid-loop, after the flush but before the DROP policies,
    # leaving the container wide open.
    ipset add -exist allowed-domains "$cidr"
done < <(echo "$gh_ranges" | jq -r '(.web + .api + .git)[]' | aggregate -q)

# Resolve and add the composed allowlist
for domain in $ALLOWED_DOMAINS; do
    echo "Resolving $domain..."
    ips=$(dig +noall +answer A "$domain" | awk '$4 == "A" {print $5}')
    if [ -z "$ips" ]; then
        # A dead domain must not brick session start (statsig.anthropic.com went
        # NXDOMAIN in 2026-07 and did exactly that). Failing closed is safe here —
        # the domain just stays unreachable — except api.anthropic.com, without
        # which CC cannot run at all.
        if [ "$domain" = "api.anthropic.com" ]; then
            echo "ERROR: Failed to resolve critical domain $domain"
            exit 1
        fi
        echo "WARNING: Failed to resolve $domain - skipping (stays blocked)"
        continue
    fi

    while read -r ip; do
        if [[ ! "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            echo "ERROR: Invalid IP from DNS for $domain: $ip"
            exit 1
        fi
        echo "Adding $ip for $domain"
        # -exist: domains sharing a CDN can resolve to identical IPs
        # (claude.ai / console.anthropic.com are both on Cloudflare).
        ipset add -exist allowed-domains "$ip"
    done < <(echo "$ips")
done

# Get host IP from default route
HOST_IP=$(ip route | grep default | cut -d" " -f3)
if [ -z "$HOST_IP" ]; then
    echo "ERROR: Failed to detect host IP"
    exit 1
fi

HOST_NETWORK=$(echo "$HOST_IP" | sed "s/\.[0-9]*$/.0\/24/")
echo "Host network detected as: $HOST_NETWORK"

# Set up remaining iptables rules
iptables -A INPUT -s "$HOST_NETWORK" -j ACCEPT
iptables -A OUTPUT -d "$HOST_NETWORK" -j ACCEPT

# Set default policies to DROP first
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# First allow established connections for already approved traffic
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Then allow only specific outbound traffic to allowed domains
iptables -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT

# Explicitly REJECT all other outbound traffic for immediate feedback
iptables -A OUTPUT -j REJECT --reject-with icmp-admin-prohibited

echo "Firewall configuration complete"
echo "Verifying firewall rules..."
if curl --connect-timeout 5 https://example.com >/dev/null 2>&1; then
    echo "ERROR: Firewall verification failed - was able to reach https://example.com"
    exit 1
else
    echo "Firewall verification passed - unable to reach https://example.com as expected"
fi

# Verify GitHub API access
if ! curl --connect-timeout 5 https://api.github.com/zen >/dev/null 2>&1; then
    echo "ERROR: Firewall verification failed - unable to reach https://api.github.com"
    exit 1
else
    echo "Firewall verification passed - able to reach https://api.github.com as expected"
fi
