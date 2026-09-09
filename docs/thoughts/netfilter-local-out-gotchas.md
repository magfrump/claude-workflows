# Netfilter LOCAL_OUT gotchas (cc-isolated boundary)

`Last verified`: 2026-09-09
`Relevant paths`: `devcontainer-config/init-firewall.sh`, `test/init-firewall-rules.bats`

Two kernel behaviours cost a multi-day outage in the cc-isolated egress boundary
(decision log #43 refuted, #44). Both are invisible to the bats suite, which stubs
`iptables` and therefore exercises command *sequence* only — there is no kernel behind
it. Anything on this page can only be checked in a live container.

## 1. `REDIRECT` on OUTPUT hardcodes `127.0.0.1`, and those packets die

`REDIRECT` is DNAT with the destination forced to a local address — on the `LOCAL_OUT`
hook that means `127.0.0.1`. The rule matches (the counter increments), and the packet
is then discarded before any socket sees it. `route_localnet=1` does **not** rescue it:
that was tried, verified live, and changed nothing (`IN_DEV_ORCONF` ORs `conf.all` with
the per-device value, so `all=1` already covered every consult site).

**Use `DNAT --to-destination <container-own-address>:<port>` instead**, and have the
daemon bind that address. Derive the address at run time from
`ip -4 route get <default-gateway>`; do not bake it.

## 2. `-o lo` does not match a packet nat rewrote to a local address

This is the subtle one, and it is the one that will bite again.

`__ip_local_out` enters the hook point as:

```c
nf_hook(NFPROTO_IPV4, NF_INET_LOCAL_OUT, net, sk, skb, NULL, skb_dst(skb)->dev, dst_output);
```

The out-device is captured **once, before any chain in that hook point runs**. nat
(priority `-100`) rewrites the destination and calls `ip_route_me_harder()`, which
updates `skb_dst` — but *not* the already-built `nf_hook_state` that filter `OUTPUT`
(priority `0`) is handed. Filter therefore matches against `out = eth0`, the device the
**original** destination routed to.

So `-o lo -j ACCEPT` matches only traffic that was loopback-bound at hook entry. A
locally-generated packet that nat steered to the container's own address will be
delivered over `lo`, will arrive on `INPUT -i lo`, and will still **fail** `-o lo` on
the way out. Accept it on the **destination address**, which survives the rewrite.

### How to recognise it

Diff `iptables-save -c` across exactly one request. The signature is a byte-count
mismatch on the accept rule:

```
CC_DNS      DNAT            +1 / +86    <- query, rewritten
CC_DNS_GUARD  RETURN        +1 / +86    <- guard let it through
OUTPUT      REJECT          +1 / +86    <- query died here
OUTPUT      -o lo ACCEPT    +1 / +114   <- NOT the query
```

The `+114` is the ICMP admin-prohibited the REJECT just generated: 20 (IP) + 8 (ICMP) +
the 86-byte original. Reading `-o lo` as "the DNS is flowing" is the trap — it was
carrying the error, in the opposite direction.

Two more things that mislead here:

- `dig` reports `host unreachable` **from the pre-NAT address** (`192.168.65.7`), because
  conntrack reverses the address in the ICMP payload. It is not evidence the packet went
  un-rewritten.
- ICMP code 13 (`admin-prohibited`) maps to `EHOSTUNREACH`, so a `REJECT
  --reject-with icmp-admin-prohibited` presents as "host unreachable", not as anything
  that sounds like a firewall.

## 3. One `-d` per rule

`! -d A ! -d B` is a **syntax error**, not a conjunction: `iptables v1.8.9 (nf_tables):
multiple -d flags not allowed`. Put the discrimination in a chain with head-of-chain
`RETURN`s instead. The bats `iptables` stub now rejects a repeated single-value selector
(`-s -d -p -i -o --dport --sport`) so this class fails in the suite rather than at
container start.

## 4. Probing rule changes: never flush the table first

The pre-implementation probe for #44 installed a hand-written DNAT rule after
`iptables -F` and `-P OUTPUT ACCEPT`. It proved the nat layer worked and, by
construction, proved nothing about the filter chain — including the guard chain the
same change was restructuring. Gotcha 2 walked straight through it.

**Install the rules under test into the assembled, live ruleset.** A probe against a
cleared table only validates the layer it touches.

## 5. Root is exempt from both steering chains, so root probes prove nothing

`CC_DNS` and `CC_SNI` both `RETURN` on `--uid-owner 0`. Every reachability check has to
run as `node` (`runuser -u node -- …`) or it bypasses the thing being tested. This is
why the boundary looked healthy for six days while no session could resolve a name.
