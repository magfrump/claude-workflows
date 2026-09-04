# Code Fact-Check Report

**Commit:** 6eaa9a0
**Replication:** k=1 (loop pass, decision 031)
**Repository:** claude-workflows (/workspace)
**Scope:** Range `2839e59..6eaa9a0` (HEAD = 6eaa9a0), restricted to `devcontainer-config/` enforcement files — `init-firewall.sh`, `Dockerfile`, `cc-sni-proxy.py` — plus the commit message of `6eaa9a0` and the "Pass 2" rows added to `docs/reviews/code-review-rubric-2026-09-03-main-egress-hardening.md`. `test/*.bats` and `docs/` in the same range are sibling context, consulted as evidence but not themselves under review.
**Checked:** 2026-09-03
**Total claims checked:** 18
**Summary:** 16 Verified, 1 Stale (comment-only), 1 Mostly accurate. No behavioral Incorrect. The three executable guarantees in the commit body (411/411 bats, 13/13 python, shellcheck clean) all reproduce exactly. The security-relevant claims — root-owned profile tree assertion, shared two-label `HOST_RE`, redirect-scoped negative probe, phase-B lock in a 0700 dir, phase-A IPv6 posture — are all correct as described in the code that is present. The single defect is a comment in `Dockerfile:109-110` that still says `/usr/local/share` is "chowned to node above for npm"; the commit's own change made that false. One scope limitation is material to how much the new tests prove: the bats `iptables` stub returns 0 for every invocation including `-C`, so the new redirect-rule assertion test proves the command is *issued*, not that a missing rule aborts the run.

No claim in this pass matched a pattern in `docs/reviews/hallucination-patterns.md`; no new entry is appended (the one Stale finding is a drifted comment, not a fabrication).

---

## Claim 1: "`node` needs a writable npm prefix — and ONLY that … `chown -R node:node /usr/local/share/npm-global`"
**Location:** `devcontainer-config/Dockerfile:59-66` **Type:** behavior / ownership **Verdict:** Verified **Confidence:** High **Verification mode:** static **Scope:** Covers the Dockerfile source text; does not establish the resulting image's runtime ownership (no Docker daemon in this sandbox — `command -v docker` → not found). **Legibility-target:** reviewer auditing the privilege boundary

The blanket `chown -R node:node /usr/local/share` is gone; the recursive chown now targets `/usr/local/share/npm-global` only, which `mkdir -p` on the same line creates. `grep -n 'chown\|chmod' devcontainer-config/Dockerfile` returns no other line that touches `/usr/local/share` or any ancestor of it: the remaining recursive chowns are `/commandhistory` (:74), `/workspace /home/node/.claude` (:81), `$ANDROID_HOME` (:231), `/opt/rustup /opt/cargo` (:297), `/opt/dotnet` (:352), `/opt/claude-workflows` (:415), and `/usr/local/share/cc-egress` (:419, to root).

**Evidence:** `devcontainer-config/Dockerfile:65-66`; exhaustive `chown`/`chmod` grep over the file (7 other recursive chowns, none an ancestor of `/usr/local/share`).

---

## Claim 2: "`cc-egress` chowned root" (commit body)
**Location:** `devcontainer-config/Dockerfile:419` **Type:** behavior **Verdict:** Verified **Confidence:** High **Verification mode:** static **Scope:** Covers the added instruction and the `USER` context it runs under; does not establish image state. **Legibility-target:** reviewer

`chown -R root:root /usr/local/share/cc-egress` is added inside the `RUN` block at `:413-425`, which is preceded by `USER root` (`:405`), so the chown has the privilege it needs. It is followed by the pre-existing `chmod 0555` on the directory and `chmod 0444` on `*.txt`. Note this is belt-and-braces rather than a fix in itself: `COPY egress/ /usr/local/share/cc-egress/` (`:389`) writes as uid 0 regardless of the active `USER`, so the tree was already root-owned; the *parent* was the actual hole, and Claim 1 is what closes it.

**Evidence:** `devcontainer-config/Dockerfile:389`, `:405`, `:419-421`.

---

## Claim 3: "`init-firewall.sh` asserts the profile dir and its parent are root-owned and not group/world-writable"
**Location:** `devcontainer-config/init-firewall.sh:302-315` **Type:** behavior **Verdict:** Verified **Confidence:** High **Verification mode:** executed **Scope:** Covers the `stat`/`find` predicates and the loop's two-element domain; does not establish behaviour against a real image (no Docker). **Legibility-target:** reviewer

The loop iterates `"$EGRESS_DIR"` and `"$(dirname "$EGRESS_DIR")"` — i.e. `/usr/local/share/cc-egress` and `/usr/local/share` on the image default — and aborts unless `stat -c '%u'` is `0` and `find "$d" -maxdepth 0 -perm /022` produces no output. I confirmed `-perm /022` is the "any of these bits" form, not "all of":

| mode | `find … -perm /022` output |
|---|---|
| 0755 | (empty) |
| 0775 (group-write) | matches |
| 0757 (other-write) | matches |
| 0700 | (empty) |

Both helpers are on the pinned PATH: `command -v find` → `/usr/bin/find` (GNU findutils 4.9.0), `command -v stat` → `/usr/bin/stat`, and `init-firewall.sh:38` pins PATH to `/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin`.

**Fail-closed ordering is correct.** The assertion sits at `:302`, *after* `trap fail_closed_on_abort EXIT` at `:299` and `trap 'exit 143' INT TERM HUP QUIT` at `:300`. So on a fresh container whose ownership is wrong, `exit 1` runs the EXIT trap, which forces `iptables -P {OUTPUT,INPUT,FORWARD} DROP` and reads the policies back — the container ends closed, not at Docker's default all-ACCEPT.

**Evidence:** `docs/reviews/execution-logs/cfc-lp2-find-perm-6eaa9a0.txt` — `bash` one-shot creating 0755/0775/0757/0700 dirs under `mktemp -d`, cwd `/workspace`, `LC_ALL=C`, exit 0, 2026-09-03T18:0x-07:00. Code: `init-firewall.sh:38`, `:299-315`.

---

## Claim 4: "Asserted on the image default only; `CC_EGRESS_DIR` is a test override that `node` cannot pass through sudo `env_reset`"
**Location:** `devcontainer-config/init-firewall.sh:305-308` **Type:** security rationale **Verdict:** Mostly accurate **Confidence:** Medium **Verification mode:** static **Scope:** Covers the sudoers line this repo writes; does not establish that the base image's `/etc/sudoers` sets `Defaults env_reset` (unreadable here — the claim rests on the Debian default). **Legibility-target:** reviewer

The guard `if [ -z "${CC_EGRESS_DIR:-}" ]` does skip the assertion whenever the variable is set, so the whole protection depends on `node` being unable to set it across the one `sudo` grant. `Dockerfile:424` writes exactly `node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh` with no `SETENV` tag, so `sudo` will not accept `-E` or `VAR=… ` from `node` for this command; `env_reset` itself is sudo's compiled-in default and Debian's `/etc/sudoers` default, but nothing in this repo asserts it. The same reasoning is already relied on for `CC_FIREWALL_PATH`, `CC_DNSMASQ_CONF`, `CC_SNI_*` and `CC_FIREWALL_LOCK`, so this is a consistent-with-the-file claim rather than a new exposure. Split from Claim 3 because the two halves diverge: the assertion's mechanics are executable-verified, its bypass-resistance is not.

**Evidence:** `init-firewall.sh:305-308`; `Dockerfile:424`; parallel overrides at `init-firewall.sh:38`, `:437-441`, `:481-487`, `:536-538`.

---

## Claim 5: "One shared `HOST_RE` … Two or more labels are REQUIRED"
**Location:** `devcontainer-config/init-firewall.sh:124-130` **Type:** behavior (regex semantics) **Verdict:** Verified **Confidence:** High **Verification mode:** executed **Scope:** Covers label-count and label-shape enforcement; does not establish label-length enforcement (see the note below). **Legibility-target:** reviewer

`HOST_RE="^${HOST_LABEL}(\.${HOST_LABEL})+\$"` is inside double quotes, where `\.` is left verbatim (backslash is not special before `.`) and `\$` collapses to a literal `$`. The resulting string is exactly:

```
^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)+$
```

so `[[ … =~ $HOST_RE ]]` (unquoted RHS, correctly) anchors at both ends and requires at least one `.`-joined extra label. Direct fixture run:

| input | result |
|---|---|
| `com` | FAIL ✓ |
| `a.b` | PASS ✓ |
| `host.docker.internal` | PASS ✓ |
| `xn--e1afmkfd.xn--p1ai` | PASS ✓ |
| `a-.b` | FAIL ✓ |
| `.b` / `a.` / `a..b` | FAIL ✓ |
| `A.B` | PASS (case-insensitive by class) |
| 63-char label + `.com` | PASS |
| 64-char label + `.com` | PASS |

The 64-char case is a scope note, not a defect against this claim: the grammar has never enforced the DNS 63-octet label limit and the commit does not claim it does.

**Evidence:** `docs/reviews/execution-logs/cfc-lp2-host-re-6eaa9a0.txt` — `LC_ALL=C bash -c '…'` in `/workspace`, exit 0, 2026-09-03T18:0x-07:00.

---

## Claim 6: "so a single-label entry can no longer become a TLD forwarding zone" (commit body); "nothing single-label can become a zone" (`:220-221`)
**Location:** `devcontainer-config/init-firewall.sh:216-224`, commit `6eaa9a0` body **Type:** behavior **Verdict:** Verified **Confidence:** High **Verification mode:** executed **Scope:** Covers both consumers through the script's own inspection hooks; does not establish dnsmasq's parsing of the emitted file. **Legibility-target:** reviewer

Both `parse_entry` (`:130`) and `compose_dnsmasq_conf` (`:221`) now test `$HOST_RE`, and the duplicated literal regex at the old `:212` is gone. Executed against fixture profiles:

- `--print-entries` with `com:443` → `ERROR: malformed egress entry 'com:443'`, exit 1.
- `--print-dnsmasq-conf` with a mixed profile → `WARNING: not a hostname, omitting from resolver allowlist (stays unresolvable): com` and **no** `server=/com/` line; `a.b`, `host.docker.internal`, `xn--e1afmkfd.xn--p1ai` each got `server=/<name>/10.0.0.1`, plus the two `GITHUB_DNS_ZONES` lines. `a-.b` was likewise warned-and-omitted.
- `--print-entries` with only valid entries → `a.b␉443`, `host.docker.internal␉11434`, `xn--e1afmkfd.xn--p1ai␉443`, exit 0 (the `:11434` port suffix survives the stricter grammar).

Note the asymmetry the two hooks show: `--print-entries` treats a bad entry as fatal, `--print-dnsmasq-conf` warns and skips. That is pre-existing and is already tracked as rubric row C16.

**Evidence:** `docs/reviews/execution-logs/cfc-lp2-print-hooks-6eaa9a0.txt` — two `LC_ALL=C bash -c` runs in `/workspace` invoking `devcontainer-config/init-firewall.sh --print-entries` / `--print-dnsmasq-conf` with `CC_EGRESS_DIR` fixtures, exits as tabulated, 2026-09-03T18:0x-07:00.

---

## Claim 7: "the negative SNI probe asserts the nat redirect rule"
**Location:** `devcontainer-config/init-firewall.sh:1067-1070` **Type:** behavior **Verdict:** Verified **Confidence:** High **Verification mode:** static **Scope:** Covers the exactness of the `-C` predicate against the rule the script installs; does **not** establish that the check fails when the rule is absent (see Claim 15). **Legibility-target:** reviewer

`iptables -t nat -C OUTPUT -p tcp --dport 443 -j CC_SNI` is character-for-character the rule appended at `:1005` (`iptables -t nat -A OUTPUT -p tcp --dport 443 -j CC_SNI`), so a real iptables `-C` — which exits 0 iff the rule exists in the chain and 1 otherwise — will match it. The check is placed after the curl probe and before the log grep, and its failure branch `exit 1`s into the fail-closed trap.

**Evidence:** `init-firewall.sh:1005`, `:1067-1070`.

---

## Claim 8: "greps the proxy log for `REJECT sni=not-allowlisted.invalid orig_dst=<probe ip>:443`" / proxy `log()` CONTRACT docstring
**Location:** `devcontainer-config/init-firewall.sh:1071`, `devcontainer-config/cc-sni-proxy.py:157-161` **Type:** cross-file contract **Verdict:** Verified **Confidence:** High **Verification mode:** static **Scope:** Covers string-level agreement between producer and consumer; does not establish end-to-end behaviour (needs a privileged container). **Legibility-target:** reviewer

The proxy emits the refusal at `cc-sni-proxy.py:186` as `log(f"REJECT sni={sni} orig_dst={orig}: not in allowlist")`, and `original_dst()` (`:149-153`) returns `f"{socket.inet_ntoa(ip)}:{port}"`. For a redirected connection to the probe address the line therefore reads `… REJECT sni=not-allowlisted.invalid orig_dst=<ip>:443: not in allowlist`. The script's `grep -q "REJECT sni=not-allowlisted.invalid orig_dst=$ANTHROPIC_PROBE_IP:443"` is an unanchored substring match that ends at `443`, immediately before the `:` — so the colon-terminated tail does not break the match. (The dots in the interpolated IP are unescaped BRE metacharacters, so the pattern is very slightly over-permissive — `203.0.113.7` would also match `203x0y113z7`. Harmless: the IP is not attacker-controlled, it comes from the script's own `dig` of `api.anthropic.com`.)

The `log()` docstring's assertion — "init-firewall.sh's verification probe greps this log for `REJECT sni=<name> orig_dst=<ip>:<port>`" — is literally true of `:1071`. A placement nit worth naming: the field order it asks callers to preserve is constructed at the four call sites (`:183`, `:186`, `:195`, `:197`), not in `log()` itself, so the contract sits one level away from the code it constrains.

**Evidence:** `cc-sni-proxy.py:149-161`, `:186`; `init-firewall.sh:1071`.

---

## Claim 9: "a direct connection to 127.0.0.1:3443 … would log orig_dst=127.0.0.1:3443, so the original-destination field is the discriminator"
**Location:** `devcontainer-config/init-firewall.sh:1062-1066` **Type:** behavior rationale **Verdict:** Verified **Confidence:** Medium-High **Verification mode:** static **Scope:** Covers the mechanism as described in Python; does not establish `SO_ORIGINAL_DST` behaviour on an un-redirected socket without a kernel run. **Legibility-target:** reviewer

`original_dst()` reads `SO_ORIGINAL_DST` and falls back to the string `"unknown"` on `OSError`/`struct.error`/`AttributeError`. On Linux, `getsockopt(SOL_IP, SO_ORIGINAL_DST)` on a socket that was *not* NAT-redirected returns the socket's own local address — `127.0.0.1:3443` for a direct connection to the listener — rather than erroring, which is exactly what the comment predicts and what the new `FORGED_SNI_LOG` bats fixture models. Either way (`127.0.0.1:3443` or `unknown`) the scoped grep fails, so the probe's conclusion holds under both readings.

**Evidence:** `cc-sni-proxy.py:149-153`; `init-firewall.sh:1062-1066`; `test/init-firewall-rules.bats:130-131`, `:925-931`.

---

## Claim 10: "the lock moves to the start of phase B" / "Phase A (network reads, no rule changes) deliberately runs OUTSIDE the lock"
**Location:** `devcontainer-config/init-firewall.sh:536-547` **Type:** ordering **Verdict:** Verified **Confidence:** High **Verification mode:** static **Scope:** Covers statement ordering in the file. **Legibility-target:** reviewer

Every phase-A network read precedes the lock: the `curl` of `api.github.com/meta` and its CIDR loop end at `:382`, the per-domain `dig` loop at `:384-431`, and the dnsmasq / SNI-proxy / IPv6 preconditions at `:433-518`. The `PHASE B — REBUILD` banner is at `:520-523`; the lock block is `:536-547`; the first rule-mutating call, `iptables-save -t nat` at `:548`, and then `iptables -P INPUT DROP` at `:560` and the flush, all follow it. The old lock site (previously just after the traps at ~`:299`) is now occupied by the ownership assertion, so nothing takes a lock in phase A.

**Evidence:** `init-firewall.sh:299-315`, `:382-431`, `:520-547`, `:548`, `:560`.

---

## Claim 11: "lives in a 0700 dir as a 0600 file"
**Location:** `devcontainer-config/init-firewall.sh:536-547` **Type:** behavior / permissions **Verdict:** Verified **Confidence:** High **Verification mode:** static (+ suite evidence) **Scope:** Covers the code path and the modes the bats suite observes; does not establish the state of a pre-existing `/run/cc-firewall` in a real container. **Legibility-target:** reviewer

`mkdir -p "$(dirname …)" && chmod 0700 "$(dirname …)"`, then `exec 9>"$FIREWALL_LOCK"`, then `chmod 0600`. The default path moved from `/run/cc-firewall.lock` to `/run/cc-firewall/lock`, so the file is inside the 0700 directory. The bats test "the lock lives in a 0700 directory and is 0600" asserts both modes and passes.

**One real window, and it is not exploitable.** Between `exec 9>` and `chmod 0600` the file exists at `0666 & ~umask` (typically 0644). But the enclosing directory is already 0700 root-owned by the immediately preceding `chmod`, so `node` has neither search nor open access to the path during that window — which is precisely the defence the comment claims ("The lock lives in a 0700 root directory so `node` cannot open the file"), with 0600 as depth. `node` also cannot pre-create `/run/cc-firewall` (`/run` is root-owned 0755), so the `mkdir -p`→`chmod` gap is likewise closed.

**Evidence:** `init-firewall.sh:536-541`; `test/init-firewall-rules.bats:933-938`; suite run in `docs/reviews/execution-logs/cfc-lp2-bats-6eaa9a0.txt`.

---

## Claim 12: "validates its wait" / "wait validated numeric"
**Location:** `devcontainer-config/init-firewall.sh:537-538` **Type:** behavior **Verdict:** Verified **Confidence:** High **Verification mode:** static **Scope:** Covers the validation predicate and its fallback. **Legibility-target:** reviewer

`FIREWALL_LOCK_WAIT="${CC_FIREWALL_LOCK_WAIT:-120}"` followed by `[[ "$FIREWALL_LOCK_WAIT" =~ ^[0-9]+$ ]] || FIREWALL_LOCK_WAIT=120`. Empty is caught twice (`:-` substitutes 120 for empty as well as unset, and `^[0-9]+$` rejects the empty string anyway), and any non-numeric value silently falls back to 120 rather than reaching `flock -w` — which previously would have made `flock` reject its argument and abort. The validated value is reused verbatim in the error message, so the diagnostic can never name a wait that was not used. Two acceptable-but-unstated edges: `0` passes validation and means non-blocking, and a bad value is corrected silently rather than warned about.

**Evidence:** `init-firewall.sh:537-538`, `:542-545`.

---

## Claim 13: "IPv6 posture is decided in phase A and a global v6 address without a usable filter table aborts before the flush"
**Location:** `devcontainer-config/init-firewall.sh:509-518`, `:576-596` **Type:** behavior **Verdict:** Verified **Confidence:** High **Verification mode:** executed (partial) **Scope:** Covers the three-way posture logic, `set -u` safety, and command availability; does not establish real-kernel ip6tables behaviour. **Legibility-target:** reviewer

The three outcomes match the claim exactly:

1. `command -v ip6tables` **and** `ip6tables -w 5 -S OUTPUT` succeed → `IP6_FILTER=1` → phase B's `if [ "$IP6_FILTER" = "1" ]` installs the DROP policies, flush, loopback and ESTABLISHED accepts.
2. No usable table **and** `ip -6 addr show scope global` non-empty → `exit 1` at `:513-517`, which is at `:517` — well before `iptables -P INPUT DROP` (`:560`) and the flush. The bats test "a global IPv6 address with no usable v6 filter table aborts before the flush" asserts `grep -c -- "^iptables -F" "$CMD_LOG"` is 0 and passes.
3. Neither → `IP6_FILTER` stays 0 and phase B's else branch warns `no usable ip6tables filter table and no global IPv6 address — IPv6 left unconfigured`.

`IP6_FILTER=0` is assigned unconditionally at `:509` before the `if`, so no path reads it unbound under `set -u`. `iproute2` is installed (`Dockerfile:32`), so `ip -6 addr show scope global` exists; executed locally in this sandbox it exits 0 and emits 0 bytes when no global v6 address is present, which is the emptiness the `[ -n "$(…)" ]` test depends on and which the bats `ip` stub models. The trap's own `ip6tables -P … || true` calls (`:275-279`) are each `|| true`-guarded inside a `command -v` block, so they cannot abort the trap under `set -e`.

**Evidence:** `ip -6 addr show scope global` in `/workspace`, `LC_ALL=C`, exit 0, 0 bytes of output, 2026-09-03T18:0x-07:00 (recorded in `docs/reviews/execution-logs/cfc-lp2-find-perm-6eaa9a0.txt` companion run). Code: `init-firewall.sh:275-279`, `:509-518`, `:560`, `:576-596`; `Dockerfile:32`; `test/init-firewall-rules.bats:951-956`.

---

## Claim 14: "the proxy log contract is declared and its FAIL text fixed"
**Location:** `devcontainer-config/cc-sni-proxy.py:157-161`, `:195` **Type:** documentation accuracy **Verdict:** Verified **Confidence:** High **Verification mode:** static **Scope:** Covers the message's fidelity to the exception it reports. **Legibility-target:** reviewer

The `except (OSError, asyncio.TimeoutError)` at `:194` wraps *both* `getaddrinfo(sni, …)` (`:189-190`) and `open_connection(ip, …)` (`:192-193`), so the old text "(resolved address not in the ipset?)" attributed every failure to the second cause and misdescribed an NXDOMAIN. The new "(name unresolvable, or address not admitted by the ipset)" names both. The log-file lifecycle is also as the argparse help says: `daemonize()` opens it `os.O_WRONLY | os.O_CREAT | os.O_TRUNC` (`:250`), matching `--log`'s "(truncated on start)" (`:303`) — which is why a stale refusal from a previous run cannot satisfy the probe.

**Evidence:** `cc-sni-proxy.py:186-197`, `:250`, `:303`.

---

## Claim 15: rubric row A18 — "✅ Fixed — grep is scoped to `orig_dst=<probe ip>:443` and `iptables -t nat -C … -j CC_SNI` is asserted"
**Location:** `docs/reviews/code-review-rubric-2026-09-03-main-egress-hardening.md` (Pass 2 table, row A18) **Type:** status claim **Verdict:** Verified **Confidence:** High **Verification mode:** executed **Scope:** Covers the code change and the *grep-scoping* half of the test evidence; **does not establish** that the `-C` assertion is behaviourally exercised. **Legibility-target:** reviewer weighing how much the new tests prove

Both code changes are present (Claims 7 and 8). The forged-log half of the fix has real negative-test evidence: `FORGED_SNI_LOG=1` makes the curl stub write `orig_dst=127.0.0.1:3443` and the run fails with "did not log a redirected refusal" — a test that would fail if the grep were unscoped.

The `-C` half does not have equivalent evidence. The bats `iptables` stub (`test/init-firewall-rules.bats:44-70`) logs its argv and falls through to `exit 0` for every invocation that is not `-P` or `-S`; `-C` is neither, so it always succeeds. The new test "the negative probe asserts the nat redirect rule, not just log evidence" therefore asserts only that the *command line is issued* (`grep -q "^iptables -t nat -C OUTPUT -p tcp --dport 443 -j CC_SNI$" "$CMD_LOG"`); there is no fixture in which the rule is absent and the run must abort. That is a real limit on the evidence, not on the fix — the fix is correct by inspection against `:1005` — and it is consistent with the suite's own stated scope ("Kernel/netfilter semantics are out of scope here and need a privileged container", `test/init-firewall-rules.bats:17-18`).

**Evidence:** `test/init-firewall-rules.bats:44-70` (stub), `:917-922` and `:925-931` (new tests); `init-firewall.sh:1005`, `:1067-1074`. Suite run: `docs/reviews/execution-logs/cfc-lp2-bats-6eaa9a0.txt`.

---

## Claim 16: rubric rows R7, A17, A19, A20, A21, A22 — "✅ Fixed"
**Location:** `docs/reviews/code-review-rubric-2026-09-03-main-egress-hardening.md` (Pass 2 table) **Type:** status claims **Verdict:** Verified **Confidence:** High **Verification mode:** executed **Scope:** Covers each row's stated remedy against the code and the passing test that pins it; does not establish the *original* findings' severity ratings. **Legibility-target:** reviewer

| row | stated remedy | check |
|---|---|---|
| R7 | only `npm-global` node-owned; `cc-egress` root; script asserts dir + parent | Claims 1–3 — all present. Cited locations `Dockerfile:59-61`, `:405-419`, `init-firewall.sh:40` are accurate. |
| A17 | one shared `HOST_RE` (≥2 labels) for both grammars | Claims 5–6 — executed-verified, both consumers. |
| A19 | lock in a 0700 root dir, file 0600 | Claim 11 — code + passing mode-assertion test. |
| A20 | posture decided in phase A; addressed + no table aborts pre-flush; no address → warn | Claim 13 — all three branches, plus the pre-flush test. |
| A21 | lock taken at the start of phase B; wait validated numeric | Claims 10 and 12; the test "the lock is taken after phase A: a held lock still lets phase A run" asserts the `api.github.com/meta` curl *did* run and `iptables -F` did *not*. |
| A22 | bats test asserts every regular file in `PAYLOAD` is in `enforcement_files()` | `test/cc-isolated-functions.bats:496-509` parses `PAYLOAD=(` out of `install.sh`, skips directories, and requires an exact-line match from `enforcement_files` for each remaining item. Present and passing. |

Row A24's "✅ Addressed — contract declared in the proxy's `log()` docstring" is also fair, with the placement nit from Claim 8; the docstring declares the grammar but not the truncate-on-start half of the coupling, which lives in the `--log` argparse help instead. Rows A23, A25, C16, C17, C18 are marked Open/partly-fixed and are consistent with the code.

**Evidence:** as tabulated; suite run `docs/reviews/execution-logs/cfc-lp2-bats-6eaa9a0.txt` (411 ok, 0 not ok).

---

## Claim 17: "411/411 bats, 13/13 python, shellcheck clean" (commit body)
**Location:** commit `6eaa9a0` body, `Notes:` line **Type:** executable guarantee **Verdict:** Verified **Confidence:** High **Verification mode:** executed **Scope:** Covers reproduction at HEAD in this sandbox; does not establish CI parity. **Legibility-target:** reviewer

All three reproduce exactly, at HEAD = 6eaa9a0, cwd `/workspace`, `LC_ALL=C`, 2026-09-03T18:0x-07:00:

| command | exit | result | log |
|---|---|---|---|
| `bats test/` | 0 | `1..411`, 411 `ok`, 0 `not ok` | `docs/reviews/execution-logs/cfc-lp2-bats-6eaa9a0.txt` |
| `python3 test/test_cc_sni_proxy.py` | 0 | `Ran 13 tests … OK` | `docs/reviews/execution-logs/cfc-lp2-python-6eaa9a0.txt` |
| `shellcheck -S warning devcontainer-config/{init-firewall.sh,cc-isolated.sh,install.sh}` | 0 | no output | `docs/reviews/execution-logs/cfc-lp2-shellcheck-6eaa9a0.txt` |

The commit's own caveat "no live kernel/Docker run" is also accurate for this pass: `command -v docker` finds nothing in this sandbox, so nothing here exercises netfilter or a built image.

**Evidence:** the three log files above.

---

## Claim 18: "Installed to /usr/local/bin, which is root-owned. Unlike /usr/local/share (chowned to node above for npm), `node` cannot rewrite the toolchain binary it runs."
**Location:** `devcontainer-config/Dockerfile:109-110` **Type:** ownership description **Verdict:** Stale **Confidence:** High **Verification mode:** static **Scope:** Covers the comment's parenthetical against the Dockerfile as of this commit. **Legibility-target:** future editor of this Dockerfile

This comment (introduced with the `uv` block, untouched by `6eaa9a0`) still describes the pre-fix world. As of this commit `/usr/local/share` is **not** chowned to node — `:65-66` narrows the chown to `/usr/local/share/npm-global`, and `:59-64` explains at length that the blanket chown was the security defect. So the parenthetical's premise is now false, and the contrast it draws ("unlike /usr/local/share") no longer distinguishes `/usr/local/bin` from anything: both are root-owned.

The conclusion it supports — `node` cannot rewrite `/usr/local/bin/uv` — remains true, and more strongly than before. **Consequence: comment-only, no behavioral effect.** The risk is legibility: a future reader auditing ownership could take `:109-110` as current fact and re-derive the wrong threat model for `/usr/local/share`, which is exactly the reasoning error pass-1's security review made about R7. Suggested fix: change the parenthetical to "(as is `/usr/local/share` apart from `npm-global` — see the note above)".

**Evidence:** `devcontainer-config/Dockerfile:59-66` vs `:109-110`; `grep -rn 'usr/local/share' devcontainer-config/ docs/decisions/` confirms this is the only surviving stale reference — `cc-isolated.sh:302,312,316`, `init-firewall.sh:7,40`, and the guides all describe `cc-egress` or `npm-global` accurately.

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
- **Claim 18** — `devcontainer-config/Dockerfile:109-110`. `/usr/local/share` is described as "chowned to node above for npm"; this commit made that false. Consequence is **comment-only**; the surrounding conclusion about `/usr/local/bin` still holds. One-line fix.

### Mostly Accurate
- **Claim 4** — `init-firewall.sh:305-308`. The `CC_EGRESS_DIR` bypass rationale is correct as far as this repo's sudoers line goes (no `SETENV`), but rests on the base image's `Defaults env_reset`, which nothing in the repo asserts. Same standing as the four other `CC_*` test-override seams; not a regression introduced here.

### Unverifiable
- Nothing was verdicted Unverifiable, but two scope boundaries limit this pass and should travel with it: (a) **no Docker daemon** in this sandbox, so every Dockerfile claim is verified against source text, not against a built image's actual ownership and modes; (b) **no privileged container**, so no netfilter, dnsmasq, or proxy behaviour is exercised — the bats suite stubs all of it, as its own header states.

---

## Escalations

| # | Entry | path:line | Addressee |
|---|---|---|---|
| 1 | Stale ownership parenthetical: "/usr/local/share (chowned to node above for npm)" is false after this commit; comment-only, but it re-states the exact threat model R7 corrected | `devcontainer-config/Dockerfile:109-110` | author (one-line comment fix) |
| 2 | The new `iptables -t nat -C` assertion has no negative test — the bats `iptables` stub returns 0 for `-C`, so the test proves the command is issued, not that a missing redirect aborts. Rubric A18's "✅ Fixed" is right about the code; the evidence is weaker than the forged-log half | `test/init-firewall-rules.bats:44-70`, `:917-922` | test-strategy / next review pass |
| 3 | `ANTHROPIC_PROBE_IP` is never asserted non-empty before use at `:1057`/`:1071`. It fails closed today (an empty value makes the grep pattern `orig_dst=:443`, which cannot match, so the run aborts), and `api.anthropic.com` is in `egress/base.txt:26` with a hard-fail on resolution failure — but the safety is incidental rather than stated | `devcontainer-config/init-firewall.sh:390`, `:423-425`, `:1057`, `:1071` | author (optional hardening / comment) |
| 4 | `HOST_RE` does not enforce the DNS 63-octet label limit (a 64-char label passes). Not claimed anywhere, and no profile is near the limit; noted so the shared-grammar rationale is not later over-read | `devcontainer-config/init-firewall.sh:124-130` | tech-debt-triage (informational) |

---

## Goal-Alignment Note

- **Answered** — all seven "what the commit claims to do" items and all eight "claims that particularly need checking" items were checked, with the specific mechanics the brief called out (`-perm /022` semantics, `\.`/`\$` inside double quotes, lock placement relative to phase-A reads and the `exec 9>`→`chmod` window, `IP6_FILTER` under `set -u`, colon-terminated grep match, `-C` exit semantics, Dockerfile chown tracing, and the three executable guarantees) each executed or traced rather than asserted.
- **Answered** — rubric Pass-2 rows R7 and A17–A22 all verify against the code; A18 verifies with a named evidence limitation (Escalation 2) rather than a downgrade, since the code change itself is correct by inspection.
- **Out of scope** — whether the *original* pass-2 findings were correctly severity-rated, and whether the open rows (A23, A25, C16, C17) should block a bless. Those are the critics' and the loop's calls, not a fact-check's.
- **Out of scope** — real-image and real-kernel confirmation. Every Dockerfile and netfilter claim here is source-level; a privileged-container run remains the only way to close that gap, and the commit body already says so.
- **Escalate** — Escalation 1 is the only change this pass asks for before the next clean pass; it is a comment edit with no behavioral consequence, so it should not by itself reset the two-consecutive-clean counter unless the loop's rules say a Stale verdict does.
