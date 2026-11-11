#!/usr/bin/env bash
# Probe every exact name on the SNI allowlist on a loop, recording what DNS
# answers and whether the proxy could reach it, then summarise which upstream
# addresses the ipset refused. Read-only: HEAD requests, no downloads.
# Usage: probe.sh OUTDIR DURATION_SECONDS INTERVAL_SECONDS
set -u
out="$1"; duration="${2:-1800}"; interval="${3:-20}"
log=/run/cc-sni-proxy/proxy.log
mkdir -p "$out"
start_iso="$(date -u +%Y-%m-%dT%H:%M:%S)"
start_line=$(( $(wc -l < "$log") + 1 ))
# Exact names only: a .zone entry has no single name to probe.
mapfile -t names < <(grep -v '^#' /run/cc-sni-proxy/allowlist | grep -v '^\.' | grep -v '^$')
printf 'start\t%s\tnames\t%s\n' "$start_iso" "${names[*]}" > "$out/meta.tsv"
: > "$out/dns.tsv"; : > "$out/curl.tsv"

end=$(( $(date +%s) + duration ))
while [ "$(date +%s)" -lt "$end" ]; do
  ts="$(date -u +%H:%M:%S)"
  for n in "${names[@]}"; do
    # dig goes through the container's filtering dnsmasq (port 53 is DNATed there).
    for ip in $(dig +short +time=3 +tries=1 A "$n" | grep -E '^[0-9.]+$'); do
      printf '%s\t%s\t%s\n' "$ts" "$n" "$ip" >> "$out/dns.tsv"
    done
    code=$(curl -s -o /dev/null -I --max-time 10 -w '%{http_code}' "https://$n/" 2>/dev/null)
    printf '%s\t%s\t%s\n' "$ts" "$n" "${code:-000}" >> "$out/curl.tsv"
  done
  sleep "$interval"
done

# Proxy outcomes during the window. FAIL lines name the address the proxy
# itself tried (the one the ipset refused); ALLOW lines name the one it reached.
tail -n +"$start_line" "$log" > "$out/proxy-window.log"
{
  echo "# Rejected upstream addresses (ipset refused): count name ip"
  sed -nE "s/.*FAIL sni=([^ ]+) .*Connect call failed \('([0-9.]+)', ([0-9]+)\).*/\1 \2:\3/p" "$out/proxy-window.log" | sort | uniq -c | sort -k2,2 -k1,1nr
  echo
  echo "# Allowed upstream addresses: count name ip"
  sed -nE 's/.*ALLOW sni=([^ ]+) -> ([0-9.]+:[0-9]+) .*/\1 \2/p' "$out/proxy-window.log" | sort | uniq -c | sort -k2,2 -k1,1nr
  echo
  echo "# Distinct DNS answers per name over the window: n_distinct name"
  cut -f2,3 "$out/dns.tsv" | sort -u | cut -f1 | uniq -c | sort -rn
  echo
  echo "# Probe HTTP codes per name (000 = connection failed): count name code"
  cut -f2,3 "$out/curl.tsv" | sort | uniq -c | sort -k2,2 -k1,1nr
} > "$out/summary.txt"
# The rejected list in ipset-member form, for pasting into a profile or ipset restore.
sed -nE "s/.*FAIL sni=[^ ]+ .*Connect call failed \('([0-9.]+)', ([0-9]+)\).*/\1,tcp:\2/p" "$out/proxy-window.log" | sort -u -t. -k1,1n -k2,2n -k3,3n -k4,4n > "$out/rejected-members.txt"
echo "done: $(wc -l < "$out/rejected-members.txt") rejected addresses; summary at $out/summary.txt"
