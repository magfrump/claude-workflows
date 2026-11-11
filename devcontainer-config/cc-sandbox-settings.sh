#!/usr/bin/env bash
# cc-sandbox-settings.sh — render Claude Code's managed settings for cc-isolated
# (Q-125). Runs at image BUILD time, in the per-project tail of the Dockerfile:
#
#   init-firewall.sh --print-entries | cc-sandbox-settings.sh <template> > managed-settings.json
#
# stdin is the firewall's own parsed allowlist (`domain<TAB>ports`, one per line),
# so the sandbox's allowedDomains and the firewall cannot disagree about grammar or
# about which profiles a project has. The sandbox proxy filters by name, the
# firewall by address and port; the firewall stays the port boundary, so ports are
# dropped here. A ZONE entry (`.zone`) becomes the sandbox's `*.zone`. GitHub is
# admitted by CIDR rather than by a profile line, so its two resolver zones are
# added here in both forms (`*.x` does not match `x` itself in the sandbox).
#
# Output is the template with allowedDomains replaced and `_comment` removed.
# Fails (non-zero, nothing on stdout) on an empty allowlist, on an entry that is
# not a hostname or zone, or on a template that is not JSON — an image must not
# bake a sandbox that admits nothing, or a name the firewall never parsed.
set -euo pipefail

template="${1:?usage: cc-sandbox-settings.sh <template.json> < entries}"
jq -e '.sandbox.network | type == "object"' "$template" >/dev/null \
  || { echo "cc-sandbox-settings: $template has no sandbox.network object" >&2; exit 1; }

label='[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?'
domains=()
while IFS=$'\t' read -r domain _ports; do
  [ -n "$domain" ] || continue
  if [[ "$domain" =~ ^\.${label}(\.${label}){2,}$ ]]; then
    domain="*$domain"
  elif ! [[ "$domain" =~ ^${label}(\.${label})+$ ]]; then
    echo "cc-sandbox-settings: refusing entry '$domain'" >&2
    exit 1
  fi
  domains+=("$domain")
done

[ "${#domains[@]}" -gt 0 ] \
  || { echo "cc-sandbox-settings: empty allowlist on stdin" >&2; exit 1; }

printf '%s\n' "${domains[@]}" github.com '*.github.com' githubusercontent.com '*.githubusercontent.com' \
  | LC_ALL=C sort -u \
  | jq -R . \
  | jq -s --slurpfile t "$template" \
      '. as $d | $t[0] | del(._comment) | .sandbox.network.allowedDomains = $d'
