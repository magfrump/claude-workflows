# Code Fact-Check Report

**Commit:** b708266
**Replication:** k=1 (loop pass, decision 031)
**Repository:** claude-workflows (/workspace)
**Scope:** `git diff d53bf6a..b708266 -- devcontainer-config/` (`init-firewall.sh`, `cc-sni-proxy.py`, `cc-isolated.sh`, `install.sh`, `Dockerfile`, `devcontainer.json`, `egress/base.txt`), plus the commit message of `b708266`, the new `docs/decisions/log.md` row 42, and the edited paragraphs in `guides/cc-isolated-usage.md`. `test/*.bats`, `docs/working/questions.md` and the rubric are in the range but read as context only. Fixes are verified against their own comments AND against the intent recorded in `docs/reviews/code-review-rubric-2026-09-03-main-egress-hardening.md` and the previous merged fact-check (`git show d53bf6a:docs/reviews/code-fact-check-report.md`).
**Checked:** 2026-09-03
**Total claims checked:** 31
**Summary:** 24 verified, 3 mostly accurate, 2 stale, 1 incorrect, 1 unverifiable

`docs/reviews/hallucination-patterns.md` was read first. No claim in this pass matched a logged pattern, and no new fabrication was found — the one `Incorrect` verdict is a wrong *mechanism* for a real branch, not an invented symbol, so nothing is appended to that log.

---

## Claim 1a: "Serialise on a root-owned lock so a second invocation waits for the first to finish (or fails closed via the trap if it cannot get the lock)."

**Location:** `devcontainer-config/init-firewall.sh:300-301`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that a second concurrent invocation is blocked from reaching the flush, and that failure to acquire the lock exits non-zero into the fail-closed trap. Does not establish that the lock is held for the *whole* critical section against a daemon that inherits fd 9 (see Claim 1c and Escalation E1), nor that the specific interleaving described two lines above (`iptables -F` between guard-jump appends and the `-o lo` accept) is the real one — that is rationale, not a checkable claim.
**Legibility-target:** for-orchestrator-synthesis

The block is:

```
FIREWALL_LOCK="${CC_FIREWALL_LOCK:-/run/cc-firewall.lock}"
exec 9>"$FIREWALL_LOCK"
if ! flock -w "${CC_FIREWALL_LOCK_WAIT:-120}" 9; then
    echo "ERROR: another init-firewall.sh run is still holding $FIREWALL_LOCK" >&2
    exit 1
fi
```

(`init-firewall.sh:302-307`; the enclosing region was read from the trap installation at `:292-294` through the first post-lock statement `ALLOWED_DOMAINS="$(compose_domains)"` at `:309`, so nothing between the lock and its first use is elided.) `flock -w N 9` blocks up to N seconds for the exclusive lock on the open descriptor, which is exactly "waits for the first to finish"; on timeout it returns non-zero and the `exit 1` fires.

Executed evidence rather than inference: `test/init-firewall-rules.bats:"the run takes a lock so concurrent invocations serialise"` holds the lock from outside with `exec 8>"$CC_FIREWALL_LOCK"; flock -n 8`, re-runs the script with `CC_FIREWALL_LOCK_WAIT=1`, and asserts both a non-zero status and `grep -c -- "^iptables -F" "$CMD_LOG"` equal to 0 — i.e. the blocked run never reaches the flush. That test passes in the full-suite run (`ok 234`).

**Evidence:** `docs/reviews/execution-logs/cfc-lp1-bats-b708266.txt` (cwd `/workspace`, `LC_ALL=C bats test/`, exit 0, 2026-09-04T00:17Z, 404 ok / 0 not ok); extract in `docs/reviews/execution-logs/cfc-lp1-targeted-tests-b708266.txt` (`ok 234 the run takes a lock so concurrent invocations serialise`).

---

## Claim 1b: "The lock is taken AFTER the trap is installed so a lock failure also ends at DROP."

**Location:** `devcontainer-config/init-firewall.sh:301`
**Type:** Error-handling (raise → observe)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ordering (trap before lock) and that both the `exit 1` path and an `exec 9>` redirection failure reach `fail_closed_on_abort` with `FIREWALL_COMPLETE=0`. Does not establish that the `iptables -P … DROP` calls inside the trap succeed on a live kernel — the trap's own read-back handles that and is unchanged by this commit.
**Legibility-target:** for-orchestrator-synthesis

Ordering is literal: `trap fail_closed_on_abort EXIT` / `trap 'exit 143' INT TERM HUP QUIT` at `:293-294`, then the lock block at `:302-307`. `FIREWALL_COMPLETE=1` is set only at the very last line of the file, so any exit from the lock block runs the trap on the `!= "1"` branch and forces the DROP policies (`:265-268`).

Two raise paths, both observed:
- `flock` timeout → `exit 1` → trap. Exercised by the bats test above, which additionally asserts nothing was flushed first.
- `exec 9>"$FIREWALL_LOCK"` failing (unwritable `/run`, missing directory). Bash exits the script on a failed `exec` redirection in a non-interactive shell, which is still an EXIT and still runs the trap. This half is static, not executed.

**Evidence:** `init-firewall.sh:293-294`, `:302-307`, `:265-268`, `:1040` (`FIREWALL_COMPLETE=1`); `docs/reviews/execution-logs/cfc-lp1-bats-b708266.txt`.

---

## Claim 1c: "root-owned lock" (`/run/cc-firewall.lock`)

**Location:** `devcontainer-config/init-firewall.sh:300`, `:302`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that the file is created by a root-run script in a directory the image does not make `node`-writable, so it is root-owned on a fresh container. Does not establish `/run`'s mode in the *running* container (that is Docker/base-image behaviour, not asserted anywhere in this repo), and does not establish that a pre-existing `node`-owned file at that path is impossible if `/run` were ever loosened.
**Legibility-target:** for-orchestrator-synthesis

The script only ever runs as root (`node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh`, `Dockerfile:418`), so `exec 9>` creates the file root-owned under the default umask. Nothing in `Dockerfile` or `devcontainer.json` chowns or chmods `/run`; the only `/run` path the image touches is `/run/cc-sni-proxy`, created by the script itself at 0755 (`init-firewall.sh:923-924`). Paraphrased — no quote available because the absence of a `/run` chown is a negative result over the whole Dockerfile.

**Evidence:** `devcontainer-config/Dockerfile:418`; `devcontainer-config/init-firewall.sh:302`, `:923-924`.

---

## Claim 2a: "CC_FIREWALL_PATH exists only so the unit tests can put their stubs first; under sudo env_reset `node` cannot set it."

**Location:** `devcontainer-config/init-firewall.sh:36-37`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that the repo's own sudoers entry grants no `SETENV` and adds no `env_keep`, so on a stock Debian sudo configuration (`env_reset` on by default) an env var set by `node` does not survive into the script. Does not establish sudo's defaults themselves — the comment's own next sentence concedes the repo asserts nothing about them, and this verdict endorses the comment's *stated* position, not an independent guarantee.
**Legibility-target:** for-orchestrator-synthesis

The sudoers line is exactly:

```
echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
  chmod 0440 /etc/sudoers.d/node-firewall
```

(`Dockerfile:418-419`.) No `SETENV:` tag, and no `Defaults` line anywhere in the repo adds `CC_FIREWALL_PATH` to `env_keep` (grep over `devcontainer-config/` for `env_keep`/`secure_path`/`SETENV` returns only the two prose comments at `Dockerfile:402-404` and `init-firewall.sh:26-28`). With `env_reset` — sudo's compiled-in default on Debian/Ubuntu — the child environment is rebuilt from a small keep-list that does not include an arbitrary `CC_*` name, so `node` cannot inject a PATH override. This is the reason confidence is Medium rather than High: the load-bearing half is sudo's documented default, verified against the packaging convention rather than against this container.

**Evidence:** `devcontainer-config/Dockerfile:418-419`; absence of `SETENV`/`env_keep` grep hits in `devcontainer-config/`.

---

## Claim 2b: The PATH pin precedes every helper invocation, including the `--print-*` hooks.

**Location:** `devcontainer-config/init-firewall.sh:37`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `export PATH=…` executes before the first hook early-exit and before any external command. Does not establish that the pinned directory list is itself free of `node`-writable entries in the built image (`/usr/local/bin` is root-owned by the Dockerfile's own chowns, but the pin's safety rests on that, not on the pin).
**Legibility-target:** for-orchestrator-synthesis

`export PATH="${CC_FIREWALL_PATH:-/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin}"` is at `:37`, immediately after `set -euo pipefail` / `IFS=` at `:29-30`. The earliest hook exit is `--print-domains` at `:78-81`, and the earliest external command is the `tr`/`grep`/`sort` inside `compose_domains` at `:54-71`; every one is below `:37`. The `--print-entries` and `--print-dnsmasq-conf` hooks (`:149`, `:225`) are lower still.

Executed corroboration: the `--print-entries` and `--print-dnsmasq-conf` runs in `cfc-lp1-canon-fixture-b708266.txt` complete normally with `CC_FIREWALL_PATH` unset, i.e. the pinned default resolves the helpers the hooks need.

**Evidence:** `init-firewall.sh:29-37`, `:54-71`, `:78-81`, `:149`, `:225`; `docs/reviews/execution-logs/cfc-lp1-canon-fixture-b708266.txt` and `docs/reviews/execution-logs/cfc-lp1-print-entries-b708266.txt`.

---

## Claim 3: "with a shebang pinned to /usr/bin/python3 — NOT `env python3`, which would be a PATH lookup"

**Location:** `devcontainer-config/init-firewall.sh:472-473`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the shebang's current value and that it is an absolute path rather than an `env` lookup. Does not establish that `/usr/bin/python3` in the node:22 base is the 3.11 the docstring names — unchanged by this commit and not re-checked here.
**Legibility-target:** for-orchestrator-synthesis

`cc-sni-proxy.py:1` is `#!/usr/bin/python3` (was `#!/usr/bin/env python3`). Pinned by a bats assertion that greps for the exact line, which passes.

**Evidence:** `devcontainer-config/cc-sni-proxy.py:1`; `docs/reviews/execution-logs/cfc-lp1-targeted-tests-b708266.txt` (`ok 235 helpers resolve through the pinned PATH, not the caller's`).

---

## Claim 4: "IPv6 is closed outright: loopback and already-established flows only."

**Location:** `devcontainer-config/init-firewall.sh:527-528`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the only ip6tables ACCEPT rules installed are `-i lo` / `-o lo` and `ESTABLISHED,RELATED` on INPUT and OUTPUT, under DROP policies on all three chains, and that the block runs before the DNS resolver-scoping section. Does not establish live-kernel behaviour (no Docker/netfilter in this sandbox — the same gap the commit body flags), and does not establish that nothing in the container actually needs IPv6.
**Legibility-target:** for-orchestrator-synthesis

The whole block (`:532-545`) is DROP policies → `-F` → `-X` → four ACCEPTs → an echo, with the DROP-before-flush ordering matching the IPv4 rationale two blocks above. Nothing else in the file issues an `ip6tables` command except the trap. The bats test asserts the negative directly — `grep -cE '^ip6tables -A OUTPUT (-p|-d|-m set)' "$CMD_LOG"` must be 0, i.e. no protocol-, address- or ipset-matched IPv6 accept exists — and passes.

Ordering: the IPv6 block sits at `:523-546`, immediately after the nat/mangle flush at `:512-521` and *before* the resolver-scoping section that begins at `:548`. Nothing IPv6-dependent is broken by it: dnsmasq is configured `listen-address=127.0.0.1` + `bind-interfaces` (`init-firewall.sh:196-197`, confirmed in the generated config), the SNI proxy binds `127.0.0.1:$SNI_PORT` and resolves `family=socket.AF_INET` (`cc-sni-proxy.py:176-178`, `:196`), and `::1` traffic is covered by the `-i lo`/`-o lo` accepts.

**Evidence:** `init-firewall.sh:512-546`; `docs/reviews/execution-logs/cfc-lp1-targeted-tests-b708266.txt` (`ok 232 IPv6 is default-denied: DROP policies, flush, loopback and established only`); `docs/reviews/execution-logs/cfc-lp1-canon-fixture-b708266.txt` (generated dnsmasq config shows `listen-address=127.0.0.1`).

---

## Claim 5: "IPv6 too (best effort — see the IPv6 block in phase B for why it is enforced)." [the trap]

**Location:** `devcontainer-config/init-firewall.sh:268`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the trap does force ip6tables DROP policies on all three chains, guarded by `command -v` and each with `|| true` so the trap cannot abort itself. Does not establish that the read-back verification applies to IPv6 — it deliberately does not, and "best effort" is the comment's own accurate hedge.
**Legibility-target:** for-orchestrator-synthesis

```
    if command -v ip6tables >/dev/null 2>&1; then
        ip6tables -w 5 -P OUTPUT DROP || true
        ip6tables -w 5 -P INPUT DROP || true
        ip6tables -w 5 -P FORWARD DROP || true
    fi
```

(`:269-273`; the enclosing `fail_closed_on_abort` was read in full, `:262-291` — the IPv4 read-back at `:274-282` covers only `iptables -S`, which is why "best effort" is the right word for the IPv6 half.) The `command -v ip6tables` lookup runs under the pinned PATH from `:37`, which is inherited by the trap since the trap executes in the same shell.

**Evidence:** `init-firewall.sh:262-291`, `:37`.

---

## Claim 6: "If ip6tables is absent the kernel has no IPv6 filter to configure and the check is skipped — that is the one case this cannot close"

**Location:** `devcontainer-config/init-firewall.sh:529-531`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the stated mechanism (binary absence implies no kernel IPv6 filter) and the claim that binary-absence is the *one* case the block cannot close. Does not dispute the conclusion that the `else` branch skips the configuration and warns — that part is correct.
**Legibility-target:** for-author

**Consequence: comment-only** — the code does the right thing; the comment misstates why, and understates the failure set.

The guard is `command -v ip6tables`, a PATH lookup for a userspace binary. Binary presence and kernel `ip6_tables`/`ip6table_filter` availability are independent facts:

- **Binary absent, kernel filter present.** The block is skipped and IPv6 goes unfiltered even though there was an IPv6 filter to configure. The comment asserts the opposite ("the kernel has no IPv6 filter to configure"), which does not follow from the guard.
- **Binary present, kernel table unavailable** (a common Docker Desktop shape — `iptables` and `ip6tables` ship together in the same Debian package, so the binary is effectively always there). `ip6tables -P INPUT DROP` then fails with `can't initialize ip6tables table 'filter'`. These calls are *bare* — no `|| true`, unlike the trap's — so under `set -e` the script aborts into the fail-closed trap and the container gets no egress at all. That is a second case the block "cannot close", and it is a harder failure than the one the comment names.

The `else` branch's own warning text is accurate (`WARNING: ip6tables not found — IPv6 egress is NOT filtered in this container`, `:544`); it is the preceding sentence's causal claim that is refuted. Per the mechanism rule, a refuted mechanism is Incorrect even where the conclusion (the branch is skipped) holds.

Precise version: "If the `ip6tables` binary is not on PATH the block is skipped and IPv6 is left unfiltered — the warning says so. Note that the binary being present does not guarantee the kernel's IPv6 filter table is available; where it is not, these bare calls abort the run into the fail-closed trap."

**Evidence:** `init-firewall.sh:529-546` (guard, bare calls, else-branch warning); contrast with the trap's `|| true` form at `:269-273`.

---

## Claim 7: "IPv6 is closed outright by the ip6tables default-deny block in phase B, so nothing here needs an IPv6 counterpart."

**Location:** `devcontainer-config/init-firewall.sh:573-574`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the IPv6 block precedes this comment's section and that the DNS resolver-scoping rules therefore need no ip6tables analogue. Does not establish the Claim-6 caveat about kernel-table availability.
**Legibility-target:** for-orchestrator-synthesis

The IPv6 block is at `:523-546`; the resolver-scoping section this comment heads runs from `:548` to `:637`. Under the IPv6 DROP policies with only loopback and established accepts, an IPv6 upstream resolver is unreachable, so a scoped IPv6 accept would be dead rule. This replaces the previous, now-false text ("this script installs no ip6tables rules, so the whole allowlist — not just DNS — is unenforced for IPv6").

**Evidence:** `init-firewall.sh:523-546`, `:568-574`; `git show d53bf6a:devcontainer-config/init-firewall.sh` for the replaced text.

---

## Claim 8: "IPv6 remains unfiltered end to end (pre-existing)."

**Location:** `devcontainer-config/init-firewall.sh:718-719`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers this one sentence at the end of the FILTERING RESOLVER block's RESIDUAL paragraph. Does not dispute the rest of that paragraph (the suffix-delegation residual and the base-zone list), which Claim 15 confirms.
**Legibility-target:** for-author

The commit rewrote three other IPv6 statements in this file (`:268`, `:573-574`, `:620-624`) but left this one, which still asserts the exact state the commit's headline change abolished:

```
# Bandwidth is further bounded by the upstream's caching. IPv6 remains
# unfiltered end to end (pre-existing).
```

(`:717-719`; the enclosing RESIDUAL paragraph runs `:710-719` and ends here.) After `:523-546`, IPv6 is DROP-policy default-denied with loopback and established accepts only, so "unfiltered end to end" is false, and "(pre-existing)" now points at nothing. This is exactly the drift class the rubric's amber doc-drift items were meant to sweep; it was missed.

Precise version: "Bandwidth is further bounded by the upstream's caching. IPv6 is default-denied outright (see the ip6tables block above), so this residual has no IPv6 counterpart."

**Evidence:** `init-firewall.sh:717-719` vs `:523-546`; `docs/reviews/execution-logs/cfc-lp1-env-b708266.txt` is not needed here — the contradiction is internal to one file.

---

## Claim 9: "Loopback/host-network/IPv6 resolution is unaffected (see comment);"

**Location:** `devcontainer-config/init-firewall.sh:634`
**Type:** Staleness (operator-visible message)
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "IPv6" element of this runtime WARNING string. The loopback and host-network elements remain accurate.
**Legibility-target:** for-author

**Consequence: comment-only in effect, but the text is printed to the operator**, not a source comment — a person debugging a container that reached this branch is told IPv6 resolution still works when the ip6tables block has just denied it. The commit updated the *explanatory comment* four lines above (`:620-624`, which now says IPv6-only resolv.conf fails closed) but not the `echo` that summarises it:

```
  echo "         accept. Loopback/host-network/IPv6 resolution is unaffected (see comment);" >&2
```

(`:634`; the else-branch runs `:610-636` and this is its second of three lines.) The two now disagree with each other in the same branch.

Precise version: `"accept. Loopback and host-network resolution are unaffected (see comment); IPv6 is default-denied;"`.

**Evidence:** `init-firewall.sh:620-624` vs `:634`.

---

## Claim 10: "Emit the CANONICAL number, not the raw string: … `0443` must become `443` here or it silently matches nothing."

**Location:** `devcontainer-config/init-firewall.sh:137-140`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `parse_entry` now emits `$((10#$port))` per port and that a zero-padded input yields the canonical form on the wire. Does not establish that any shipped profile actually contains a padded port (none does — this is defensive).
**Legibility-target:** for-orchestrator-synthesis

Executed against a purpose-built fixture (`padded.example:0443`, `localhost:11434`, `multi.example:0080,00443,22`):

```
localhost^I11434$
multi.example^I80,443,22$
padded.example^I443$
```

— every padded port canonicalised, order within the list preserved, tab separator intact (`cat -A` rendering; `^I` is TAB, `$` is EOL). The `--print-entries` run over the real `egress/base.txt` is unchanged from the pre-commit form (`api.anthropic.com`, `claude.ai`, `console.anthropic.com`, `platform.claude.com`, `registry.npmjs.org`, all `443`), so no shipped behaviour moved.

**Evidence:** `docs/reviews/execution-logs/cfc-lp1-canon-fixture-b708266.txt` (cwd `/workspace`, 2026-09-04T00:18Z, exit 0); `docs/reviews/execution-logs/cfc-lp1-print-entries-b708266.txt`; `docs/reviews/execution-logs/cfc-lp1-targeted-tests-b708266.txt` (`ok 230`).

---

## Claim 11: "every downstream consumer (ipset members, the SNI allowlist's `,443,` filter) compares ports textually"

**Location:** `devcontainer-config/init-firewall.sh:138-139`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers all four consumers of the `canon` field — the `--print-entries` hook, `ALLOWED_ENTRIES`, the ipset member construction, and the SNI allowlist's 443 filter — and confirms each is a textual comparison or textual interpolation. Does not establish that `ipset` itself would reject `tcp:0443` (it may well accept it); the claim's force is that the SNI filter would not match, which is established.
**Legibility-target:** for-orchestrator-synthesis

`parse_entry` prints `printf '%s\t%s\n' "$domain" "$canon"` (`:146`), which flows to exactly three places:

1. `--print-entries` (`:149-158`) — prints the parse directly; the hook the tests read.
2. `ALLOWED_ENTRIES` (`:319-326`), consumed by the ipset loop at `:384-423`, where members are built by string interpolation (`ipset add -exist allowed-domains "$member"`, `:818`).
3. The SNI allowlist writer at `:925-928`: `while read -r domain ports; do … case ",$ports," in *,443,*) echo "$domain" ;; esac; done`.

Consumer 3 is the one that makes the claim load-bearing: `case ",0443," in *,443,*)` does not match, so a padded 443 entry would have been admitted by the ipset and silently omitted from the SNI allowlist — a fail-closed but confusing outcome. Consumers 1 and 2 are string paths too. The bats test name for `ok 230` names both ("before it reaches ipset and the SNI allowlist").

**Evidence:** `init-firewall.sh:146`, `:149-158`, `:319-326`, `:384-423`, `:818`, `:925-928`.

---

## Claim 12: "Same label grammar as parse_entry (a single label is allowed there, so it must be allowed here too — otherwise an entry can be ipset-admitted yet unresolvable)."

**Location:** `devcontainer-config/init-firewall.sh:211-212`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the two regexes are now the same grammar and that a single-label entry gets both an ipset member and a `server=` line. Does not establish dnsmasq's own acceptance of a single-label `server=/localhost/…` directive on a live daemon (no dnsmasq in this sandbox — see Escalation E2); dnsmasq's `--server=/<domain>/<ip>` syntax places no label-count constraint on `<domain>`, so this is expected to hold, but it is not executed here.
**Legibility-target:** for-orchestrator-synthesis

`parse_entry` builds `label='[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?'` and matches `^${label}(\.${label})*$` (`:127`, `:133`). `compose_dnsmasq_conf` now matches `^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)*$` (`:213`) — the same expression with `label` expanded, `+` changed to `*`. Character-for-character identical after substitution.

Executed: the fixture containing the single-label entry `localhost:11434` produced `server=/localhost/10.0.0.53` alongside its ipset admission, with no `WARNING: not a hostname` line. Before the change the `+` quantifier would have emitted the warning and dropped the zone.

**Evidence:** `init-firewall.sh:127`, `:133`, `:211-216`; `docs/reviews/execution-logs/cfc-lp1-canon-fixture-b708266.txt` (`server=/localhost/10.0.0.53`); `docs/reviews/execution-logs/cfc-lp1-targeted-tests-b708266.txt` (`ok 231 a single-label entry gets a resolver line as well as an ipset member`).

---

## Claim 13: "The SNI zones are derived from the SAME list the filtering resolver serves (GITHUB_DNS_ZONES), so a name the proxy would admit is always one the resolver will answer for; the two lists cannot drift apart again."

**Location:** `devcontainer-config/init-firewall.sh:929-932`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the SNI allowlist's GitHub zones are now generated from `GITHUB_DNS_ZONES`, that the split works under `IFS=$'\n\t'`, and that `.githubassets.com` is gone from the boundary code. Does not establish the same for the *exact-name* half of the allowlist (profile entries) — those come from `ALLOWED_ENTRIES`, and `compose_dnsmasq_conf` is fed the same `compose_domains` output, so they share a source too, but that is a pre-existing property this claim does not assert.
**Legibility-target:** for-orchestrator-synthesis

This closes rubric row R5 (escalated 🟡→🔴), which the previous merged fact-check raised as Claim 36 / escalation E2.

```
    for zone in $(echo "$GITHUB_DNS_ZONES" | tr ' ' '\n'); do
        echo ".$zone"
    done
```

(`:933-935`, inside the `{ … } > "$SNI_ALLOWLIST"` group that runs `:919-936` and is followed by `chmod 0444` at `:937` — read through the group's close.) `IFS` is `$'\n\t'` for the whole script, so word-splitting on `$(…)` splits on newlines; `tr ' ' '\n'` converts the space-separated constant into exactly that. The identical idiom is already used for the same variable in `compose_dnsmasq_conf` (`:203`), with the comment "`$GITHUB_DNS_ZONES` is space-separated; IFS is `\n\t`, so split it explicitly."

`.githubassets.com` no longer appears anywhere in `devcontainer-config/` (repo-wide grep hits are confined to `docs/reviews/*` prior-review prose, `docs/decisions/log.md` row 41 — see Claim 27 — a corpus artifact under `runs/`, and the new bats assertion that it is *absent*). The corresponding bats test asserts `grep -c 'githubassets' "$al"` equals 0 and passes.

**Evidence:** `init-firewall.sh:203`, `:929-937`; `docs/reviews/execution-logs/cfc-lp1-targeted-tests-b708266.txt` (`ok 221 the SNI allowlist holds every 443 entry as an exact name plus the GitHub zones`); repo-wide `githubassets` grep (no hits under `devcontainer-config/`).

---

## Claim 14: "A failed curl alone is not proof: a missing redirect, a dead proxy, or a broken runuser all fail the same way. The proxy must have SEEN and REFUSED the name."

**Location:** `devcontainer-config/init-firewall.sh:1008-1009`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the grep pattern matches the proxy's actual not-in-allowlist log line for this specific name, that a missing or unwritten log fails the check rather than passing it, and that the failure exits into the fail-closed trap. Does not establish the live-container leg (`curl --resolve` through a real REDIRECT), which remains the open question in `docs/working/questions.md`.
**Legibility-target:** for-orchestrator-synthesis

This closes the rubric's false-passing-negative-probe item (previous fact-check Claim 37 / escalation (b)).

The check is `if ! grep -q "REJECT sni=not-allowlisted.invalid " "$SNI_LOG" 2>/dev/null; then … exit 1; fi` (`:1010-1013`), and the proxy's matching log call is:

```
        if not allow.allows(sni):
            log(f"REJECT sni={sni} orig_dst={orig}: not in allowlist")
            return
```

(`cc-sni-proxy.py:187-189`, inside `handle()`, which was read in full `:179-208` — the SNI-rejection path returns immediately and nothing downstream rewrites the line.) `log()` emits `print(time.strftime(...), msg, flush=True)` (`:154-155`), so the rendered line is `<timestamp> REJECT sni=not-allowlisted.invalid orig_dst=<ip>:443: not in allowlist`. The grep pattern's **trailing space** is satisfied by the space before `orig_dst=`, and it is what stops the pattern from matching a longer name with the same prefix. `not-allowlisted.invalid` survives `normalise_name` (`:60-67`): two labels, both matching `^[a-z0-9]([a-z0-9-]*[a-z0-9])?$`.

The `2>/dev/null` covers only grep's *stderr* (a missing `$SNI_LOG`); grep still exits non-zero in that case, so a missing log fails the probe — the safe direction, not a silent pass. The bats test drives this with a `SILENT_SNI_NEGATIVE=1` stub, asserts non-zero status, asserts the `did not log a refusal` message, and asserts the trap's `iptables -w 5 -P OUTPUT DROP` fired. It passes.

**Evidence:** `init-firewall.sh:1005-1015`; `cc-sni-proxy.py:154-155`, `:179-208`, `:60-67`; `docs/reviews/execution-logs/cfc-lp1-targeted-tests-b708266.txt` (`ok 233 the negative SNI probe requires a logged refusal, not just a failed curl`).

---

## Claim 15: "None of the base zones (api.anthropic.com, claude.ai, console.anthropic.com, platform.claude.com, registry.npmjs.org, github.com, githubusercontent.com) hand out delegations to third parties"

**Location:** `devcontainer-config/init-firewall.sh:714-716`
**Type:** Configuration (the enumeration half)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the enumerated list now matches the actual composed base allowlist plus `GITHUB_DNS_ZONES`. Does not endorse the delegation assertion itself — that is a claim about third-party DNS behaviour, outside repo evidence and unchanged by this commit.
**Legibility-target:** for-orchestrator-synthesis

The list previously read `… console.anthropic.com, sentry.io, statsig.com, registry.npmjs.org …`, naming two hosts removed from `base.txt` in the earlier wave and omitting `platform.claude.com`, which was added. Executed `--print-entries` over the real `egress/base.txt` returns exactly `api.anthropic.com`, `claude.ai`, `console.anthropic.com`, `platform.claude.com`, `registry.npmjs.org`; `GITHUB_DNS_ZONES="github.com githubusercontent.com"` (`:154`) supplies the last two. Set equality holds.

**Evidence:** `docs/reviews/execution-logs/cfc-lp1-print-entries-b708266.txt`; `init-firewall.sh:154`, `:714-716`.

---

## Claim 16: "listed in install.sh's payload and in the launcher's bless manifest (cc-isolated.sh enforcement_files) like every other enforcement file."

**Location:** `devcontainer-config/cc-sni-proxy.py:26-29`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both registrations for `cc-sni-proxy.py`. Does not establish that the installed host-side config dir has actually been re-blessed — that is the operator action already tracked in `docs/working/questions.md`.
**Legibility-target:** for-orchestrator-synthesis

This closes rubric R1 / previous fact-check Claim 5b, the one earlier finding with a boundary consequence rather than a documentation one.

`install.sh:25`: `PAYLOAD=(devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py cc-isolated.sh link-claude-home.sh egress claude-home)`.
`cc-isolated.sh:59-60`: `echo "cc-sni-proxy.py"` / `echo "link-claude-home.sh"` inside `enforcement_files()` (read in full, `:55-73`, through the sorted-glob block and its closing subshell).

**Evidence:** `devcontainer-config/install.sh:25`; `devcontainer-config/cc-isolated.sh:55-73`.

---

## Claim 17: "NOT made by this proxy's own uid or by root (root runs the firewall script itself and its probes)"

**Location:** `devcontainer-config/cc-sni-proxy.py:4-6`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the parenthetical's characterisation of who runs the probes. The redirect-exemption half (the `CC_SNI` chain RETURNs for `ccproxy` and uid 0) is exactly right and is not in question.
**Legibility-target:** for-author

The mechanism and conclusion are right; "its probes" is imprecise, and imprecise in the direction that matters for this file. Four probes run at the end of the script: two as root (`curl https://example.com`, `curl https://api.github.com/zen`, `:1000-1004` region) and two as `node` via `runuser`, *deliberately so they traverse this proxy's redirect*:

```
# SNI proxy probes, run AS NODE so they traverse the redirect (root is exempt).
```

(`init-firewall.sh:995`; the probe section runs `:986-1015` and was read to its end.) A reader of the docstring alone would conclude the SNI proxy is never exercised by the script's own verification, which is the opposite of the design. The guide's rewritten paragraph gets this right (Claim 25), so the two now differ in precision on the same point.

Precise version: "…or by root (root runs the firewall script itself and its two general reachability probes; the two SNI probes are run as `node` on purpose, so they do traverse this proxy)."

**Evidence:** `cc-sni-proxy.py:4-6`; `init-firewall.sh:986-1015`, especially `:995`; `guides/cc-isolated-usage.md:296-299`.

---

## Claim 18: "Resolution goes to the container's filtering dnsmasq — this process's port-53 traffic is REDIRECTed there by the firewall, whatever /etc/resolv.conf says — and is IPv4-only, matching the IPv4-only ipset (IPv6 is default-denied outright)."

**Location:** `devcontainer-config/cc-sni-proxy.py:21-24`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers all three sub-claims: the proxy's uid is not exempt from the DNS redirect; its resolution is `AF_INET`-only; IPv6 is default-denied. Does not establish the kernel-level REDIRECT behaviour on a live container (the standing live-check gap).
**Legibility-target:** for-orchestrator-synthesis

The `CC_DNS` nat chain RETURNs for exactly two uids — `"$DNSMASQ_UID"` and `0` — then REDIRECTs udp and tcp to port 53 (`init-firewall.sh:742-748`). `ccproxy` is asserted at `:490-494` to be numeric, non-zero and *distinct from* `DNSMASQ_UID`, so it is neither exempt uid and its port-53 traffic is redirected. "whatever /etc/resolv.conf says" is the correct characterisation of a kernel nat REDIRECT versus a resolver-config file, and the FILTERING RESOLVER block argues the same point at `:679-683`.

IPv4-only: `getaddrinfo(sni, upstream_port, family=socket.AF_INET, type=socket.SOCK_STREAM)` (`cc-sni-proxy.py:195-196`, inside `handle()` read in full). The IPv6 parenthetical is Claim 4.

**Evidence:** `init-firewall.sh:490-494`, `:742-748`, `:679-683`; `cc-sni-proxy.py:194-198`.

---

## Claim 19: "Keep this list in step with install.sh's PAYLOAD … claude-home/ (the baked skills/hooks payload) is the one PAYLOAD item still outside this list"

**Location:** `devcontainer-config/cc-isolated.sh:45-49`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the set difference PAYLOAD ∖ enforcement_files. Does not cover the reverse direction (`projects/*.profile` is hashed but not a PAYLOAD item), which the comment does not claim.
**Legibility-target:** for-orchestrator-synthesis

PAYLOAD is 8 items: `devcontainer.json`, `Dockerfile`, `init-firewall.sh`, `cc-sni-proxy.py`, `cc-isolated.sh`, `link-claude-home.sh`, `egress`, `claude-home` (`install.sh:25`). `enforcement_files()` emits the first six by name, then `egress/*.txt` and `projects/*.profile` via sorted globs (`cc-isolated.sh:55-73`). Set difference is exactly `{claude-home}`. The pointer to `docs/working/questions.md` resolves: the open entry there records the directory-hashing question and the interim decision.

**Formatting note (not a claim defect):** the inserted sentence runs into the pre-existing text on one line — `… see docs/working/questions.md. Paths are relative to config_dir.` at `:49` — leaving that comment line ~40 columns past the file's wrap width. Cosmetic.

**Evidence:** `devcontainer-config/install.sh:25`; `devcontainer-config/cc-isolated.sh:45-73`; `docs/working/questions.md` (claude-home entry).

---

## Claim 20: "rebuild would have failed at the Dockerfile COPY; manifest was incomplete"

**Location:** commit message body, `b708266`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that a rebuild from a freshly installed config dir would have failed, and that the bless manifest omitted the file. Does not establish that any *existing* installed config dir was actually missing the file (an operator may have copied it by hand).
**Legibility-target:** for-orchestrator-synthesis

`install.sh` copies only PAYLOAD items into `$DEST` (`for item in "${PAYLOAD[@]}"` at `:68` for the diff preview and `:98` for the copy), and the Dockerfile's build context is that config dir. `Dockerfile:388` is `COPY cc-sni-proxy.py /usr/local/bin/`. With `cc-sni-proxy.py` absent from PAYLOAD before this commit, the file would not be in the context and `docker build` would fail at that COPY. The manifest half is Claim 16.

**Evidence:** `devcontainer-config/install.sh:25`, `:68`, `:98`; `devcontainer-config/Dockerfile:388`.

---

## Claim 21: Dockerfile — "root-owned and 0555" for both binaries; "decision log #40" for `dnsmasq-base`; "decision log #41" for the proxy.

**Location:** `devcontainer-config/Dockerfile:47`, `:386-387`, `:408-410`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file modes actually applied, that `link-claude-home.sh` remains executable by `node` at 0555, and that both decision-log cites resolve to the right rows. Does not establish that 0555 survives any later layer (nothing after `:408-412` touches these paths).
**Legibility-target:** for-orchestrator-synthesis

```
RUN chown root:root /usr/local/bin/init-firewall.sh /usr/local/bin/link-claude-home.sh /usr/local/bin/cc-sni-proxy.py && \
  chmod 0555 /usr/local/bin/init-firewall.sh /usr/local/bin/link-claude-home.sh /usr/local/bin/cc-sni-proxy.py && \
```

(`:408-409`; the `RUN` continues to `:412` with the `/opt/claude-workflows` chowns — read to the end of the command.) The previous form used a bare `chmod +x` on the two shell scripts, leaving owner-write set. 0555 is `r-xr-xr-x`: world read + execute.

`link-claude-home.sh` runs as `node` from `"postStartCommand": "sudo /usr/local/bin/init-firewall.sh && /usr/local/bin/link-claude-home.sh"` with `"remoteUser": "node"` (`devcontainer.json:120`, `:51`). It needs read + execute on itself (both present at 0555) and write only into `/home/node/.claude`, the node-owned per-project volume — never into its own path. The mode change is safe.

Decision-log cites: row 40 is the filtering resolver / dnsmasq design, row 41 is the SNI proxy including "root-owned 0555" verbatim (`docs/decisions/log.md:63`, `:62`). The `#39`→`#40` fix at `Dockerfile:47` corrects the renumbering the previous fact-check flagged.

**Evidence:** `devcontainer-config/Dockerfile:44-48`, `:386-388`, `:405-412`; `devcontainer-config/devcontainer.json:51`, `:120`; `docs/decisions/log.md:62-63`.

---

## Claim 22: "Operational telemetry is therefore still ATTEMPTED, to a Datadog intake host the docs list; that host is not allowlisted, so the firewall rejects it."

**Location:** `devcontainer-config/devcontainer.json:78-81`; parallel text at `devcontainer-config/egress/base.txt:8-11`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the network-config docs name a Datadog telemetry intake host, that the container's settings do not disable that telemetry, and that the host is absent from the composed allowlist. Does not establish what the client does at runtime (no live session run here).
**Legibility-target:** for-orchestrator-synthesis

The docs' Network access requirements table lists `http-intake.logs.us5.datadoghq.com` — "Operational telemetry events, sent only when the CLI uses the Anthropic API directly … Optional: disable with `DISABLE_TELEMETRY` or `DO_NOT_TRACK`" — and `browser-intake-us5-datadoghq.com` for error reports, "disable with `DISABLE_ERROR_REPORTING` or `DISABLE_TELEMETRY`". The container sets `"DISABLE_ERROR_REPORTING": "1"` and nothing else, so the error-report host is off and the *telemetry* intake host remains attempted — exactly what the comment now says, and a correction of the prior text ("The remaining telemetry events go to api.anthropic.com"), which the previous fact-check flagged.

Not allowlisted: executed `--print-entries` over `egress/base.txt` returns five hosts, none of them a datadoghq.com name; the composed allowlist admits nothing else by name, and the final `iptables -A OUTPUT -j REJECT` (`init-firewall.sh:947`) is the disposition for anything unmatched. "the firewall rejects it" is literally right — REJECT, not DROP.

The docs also corroborate the retained caution: "Setting `DISABLE_TELEMETRY` or `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` also disables the feature-flag evaluation that Remote Control depends on; `DISABLE_ERROR_REPORTING` doesn't."

**Evidence:** WebFetch `https://code.claude.com/docs/en/network-config.md` and `https://code.claude.com/docs/en/data-usage#telemetry-services` (2026-09-04); `docs/reviews/execution-logs/cfc-lp1-print-entries-b708266.txt`; `devcontainer-config/devcontainer.json:82`; `devcontainer-config/init-firewall.sh:947`.

---

## Claim 23: "Do NOT reach for DISABLE_TELEMETRY, DO_NOT_TRACK, DISABLE_GROWTHBOOK, or CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC: each of those also disables feature-flag evaluation"

**Location:** `devcontainer-config/devcontainer.json:76-79`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed (documentation fetch)
**Scope:** Covers only the newly added `DISABLE_GROWTHBOOK` and the "each of those" universal. `DISABLE_TELEMETRY` and `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` are confirmed by the docs; those two are not in question.
**Legibility-target:** for-orchestrator-synthesis

**Blocker:** `DISABLE_GROWTHBOOK` does not appear on either page the file names as its source of truth. `base.txt:4` states "Source of truth for the Claude Code hosts: code.claude.com/docs/en/network-config", and that page does not mention it; neither does `/docs/en/data-usage#telemetry-services` nor `/docs/en/env-vars` (fetched and searched — the env-vars page's set-ness note lists `DISABLE_TELEMETRY`, `DISABLE_ERROR_REPORTING` and `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`, and no GrowthBook variable at all). GrowthBook is a real feature-flag product and a plausible successor to the Statsig path this repo already removed, so the name is not obviously fabricated — but nothing available here confirms the variable exists or that setting it disables feature-flag evaluation.

The universal "each of those" is also broader than the docs support: the telemetry-services page attributes the feature-flag side effect to `DISABLE_TELEMETRY` and `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` specifically, and says `DISABLE_ERROR_REPORTING` "doesn't". `DO_NOT_TRACK` is documented only as a `DISABLE_TELEMETRY` equivalent for the Datadog intake host, not for feature-flag evaluation.

Not logged to `hallucination-patterns.md`: absence from three doc pages is not the same as a refuted symbol, and the log is reserved for confirmed fabrications.

**Evidence:** WebFetch `https://code.claude.com/docs/en/env-vars` (2026-09-04, "DISABLE_GROWTHBOOK does not appear anywhere on this page"), `https://code.claude.com/docs/en/data-usage#telemetry-services`, `https://code.claude.com/docs/en/network-config.md`; `devcontainer-config/egress/base.txt:4`.

---

## Claim 24: "platform.claude.com — per the network-config docs; the docs' stated symptom of omitting it is a first-run connectivity-check failure"

**Location:** `devcontainer-config/egress/base.txt:24-25`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed (documentation fetch)
**Scope:** Covers the attributed symptom. Does not establish that a mid-session re-login (the claim this replaced) never happens — the correction is that the docs do not *state* that symptom, not that it is impossible.
**Legibility-target:** for-orchestrator-synthesis

The docs say: "The first-run setup connectivity check points here when it can't reach `api.anthropic.com` or `platform.claude.com`; see Unable to connect to Anthropic services for the check's messages and recovery steps." The table row reads: "Anthropic Console account authentication. OAuth token exchange, refresh, and revocation also go to this host for claude.ai accounts, so both Console and claude.ai sign-ins require it" — which also supports the surrounding "OAuth token exchange/refresh" attribution. The previous text asserted a mid-session re-login symptom the docs nowhere state; that is now corrected.

**Evidence:** WebFetch `https://code.claude.com/docs/en/network-config.md` (2026-09-04); `devcontainer-config/egress/base.txt:21-29`.

---

## Claim 25: "its two general reachability probes run as root and bypass the redirect; its two SNI probes are run as `node` on purpose so they do not."

**Location:** `guides/cc-isolated-usage.md:296-299`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count and uid of each probe pair. Does not establish that the redirect actually applies on a live kernel.
**Legibility-target:** for-orchestrator-synthesis

Four probes, in order: `curl https://example.com` (must fail) and `curl https://api.github.com/zen` (must succeed), both bare and therefore root; then `runuser -u node -- curl … https://api.anthropic.com/` and `runuser -u node -- curl … --resolve not-allowlisted.invalid:443:$ANTHROPIC_PROBE_IP …`, both explicitly `node` (`init-firewall.sh:986-1015`, read from the "Verifying firewall rules" echo to `FIREWALL_COMPLETE=1`). Two and two, exactly as the guide now says — and more precise than the proxy docstring's version of the same fact (Claim 17).

**Evidence:** `init-firewall.sh:986-1015`; `guides/cc-isolated-usage.md:293-300`.

---

## Claim 26: the guide's rewritten proxy-log vocabulary (`REJECT` with and without an `sni=` field; `FAIL` as unresolved-or-unconnectable)

**Location:** `guides/cc-isolated-usage.md:301-307`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the three documented shapes correspond one-to-one with the proxy's `log()` call sites and that `FAIL`'s described causes match the exception set actually caught. Does not cover the startup `listening on …` line, which the guide does not mention and which lacks a leading verb token (a pre-existing API-consistency note, not a defect in this claim).
**Legibility-target:** for-orchestrator-synthesis

Three `log()` calls in `handle()` (read in full, `cc-sni-proxy.py:179-208`):

- `log(f"REJECT orig_dst={orig}: {e}")` (`:185`) — the no-`sni=` form, reached from `except (HelloError, asyncio.IncompleteReadError, asyncio.TimeoutError, OSError)` around `read_client_hello`/`parse_sni`, i.e. "the bytes were not a parseable TLS ClientHello". Matches.
- `log(f"REJECT sni={sni} orig_dst={orig}: not in allowlist")` (`:188`). Matches.
- `log(f"FAIL sni={sni} orig_dst={orig}: {e} (resolved address not in the ipset?)")` (`:199`) — the `except (OSError, asyncio.TimeoutError)` wrapping *both* `getaddrinfo` and `open_connection` (`:194-198`), so it covers a dnsmasq REFUSED (name could not be resolved) *and* a connect failure/timeout. The guide's "the name could not be resolved — the filtering resolver refused it — or the address it resolved to could not be connected to, typically because the ipset does not admit it" is the accurate two-cause rendering; the previous single-cause text ("the name resolved to an address the ipset does not admit") was the incomplete one. Note the proxy's own inline `(resolved address not in the ipset?)` still names only one cause — that is a pre-existing message the commit did not change, and is not part of this claim.
- `ALLOW` at `:201`. Matches.

**Evidence:** `cc-sni-proxy.py:179-208`; `guides/cc-isolated-usage.md:300-307`.

---

## Claim 27: decision-log row 41 — "admits exact names from every 443 profile entry plus `.github.com`/`.githubusercontent.com`/`.githubassets.com` zones"

**Location:** `docs/decisions/log.md:62`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `.githubassets.com` element of row 41's description of current behaviour. Does not argue that a decision record must be rewritten when superseded — only that this row now describes code that no longer exists, and row 42 does not say so.
**Legibility-target:** for-author

**Consequence: comment-only.**

Row 41 still asserts the three-zone allowlist. The commit removed the third zone from the code (Claim 13), and new row 42 records the derivation change ("the SNI allowlist's GitHub zones are derived from `GITHUB_DNS_ZONES`") without noting that `.githubassets.com` was dropped — even though the commit *message* says so explicitly ("drops the unresolvable `.githubassets.com`"). A reader of the log alone gets no signal that row 41's zone list is superseded. The same file's rows 39/40 renumbering was flagged and fixed in this wave; this is the residue of the same class.

Precise version: add "(superseded by #42: `.githubassets.com` dropped)" to row 41, or carry the phrase from the commit message into row 42's summary.

**Evidence:** `docs/decisions/log.md:61` (row 42), `:62` (row 41); `devcontainer-config/init-firewall.sh:929-935`; `docs/reviews/execution-logs/cfc-lp1-targeted-tests-b708266.txt` (`ok 221`, which asserts `githubassets` count 0 in the generated allowlist).

---

## Claim 28: decision-log row 42 — "Guarded by 6 new bats tests (104 in the two suites)."

**Location:** `docs/decisions/log.md:61`
**Type:** Behavioral (count)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both numbers. Does not assess whether the six tests are individually strong — one of them (`helpers resolve through the pinned PATH`) is a grep assertion over the script text rather than a behavioural run, which its own comment states.
**Legibility-target:** for-orchestrator-synthesis

`@test` counts at `b708266`: `test/init-firewall-rules.bats` 52, `test/cc-isolated-functions.bats` 52 → 104. At the parent `d53bf6a`: 46 and 52 → 98. Difference is exactly 6, all in `init-firewall-rules.bats`: canonical port, single-label resolver line, IPv6 default-deny, negative-probe logged refusal, the lock, the pinned PATH. The 4-line diff in `cc-isolated-functions.bats` extends existing tests rather than adding new ones, consistent with its unchanged count.

**Evidence:** `grep -c '^@test '` over both files at HEAD and at `d53bf6a` (executed, cwd `/workspace`, 2026-09-04T00:22Z); `git diff d53bf6a..b708266 -- test/` shows exactly six added `@test` lines.

---

## Claim 29: commit body — "404/404 bats, 13/13 python, shellcheck clean"

**Location:** commit message body, `b708266` (`Notes:` line)
**Type:** Behavioral (executable guarantee — mandatory execution)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all three figures as reproduced in this sandbox at HEAD = `b708266`. Does not extend to anything requiring a live kernel, Docker, iptables, dnsmasq, or a real container — the commit body's own "still no live-kernel run" caveat stands and is accurate.
**Legibility-target:** for-orchestrator-synthesis

| Command (cwd `/workspace`, `LC_ALL=C`) | Exit | Result | Log |
|---|---|---|---|
| `bats test/` | 0 | `1..404`, 404 `ok`, 0 `not ok` | `cfc-lp1-bats-b708266.txt` |
| `python3 test/test_cc_sni_proxy.py` | 0 | `Ran 13 tests … OK` | `cfc-lp1-pytest-b708266.txt` |
| `shellcheck -S warning devcontainer-config/{init-firewall.sh,cc-isolated.sh,install.sh}` | 0 | no output | `cfc-lp1-shellcheck-b708266.txt` |

Timestamps 2026-09-04T00:17:26Z–00:17:31Z. All three figures match the commit body exactly.

**Evidence:** the three logs named above.

---

## Claim 30: commit body — "Amber design items (proxy supervision/first-address, OPENROUTER gating, grammar tolerance) deliberately not changed."

**Location:** commit message body, `b708266`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the named items are unchanged in the diff and are recorded as deferred with an interim decision. Does not assess whether deferring them is correct.
**Legibility-target:** for-orchestrator-synthesis

`cc-sni-proxy.py`'s `handle()` still takes `infos[0][4][0]` with no iteration over `getaddrinfo` results and no re-resolve (`:195-198`), `daemonize()` gains no supervisor (`:236-284`), `parse_entry`'s grammar is unchanged apart from the port canonicalisation (`:126-147`), and `devcontainer.json`'s `OPENROUTER_API_KEY` entry is untouched. Each has a matching new entry in `docs/working/questions.md` with an `interim:` field, as the /away running-questions convention requires; five entries were added, matching "five new questions logged".

**Evidence:** `git diff d53bf6a..b708266 -- devcontainer-config/cc-sni-proxy.py` (docstring + shebang only); `docs/working/questions.md:14-18`.

---

## Claim 31: "Two interleaved runs can each pass their own probes while one of them has flushed the other's half-built guard chains out from under it"

**Location:** `devcontainer-config/init-firewall.sh:292-297`
**Type:** Behavioral (the hazard the lock addresses)
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that concurrent invocation is possible and that an interleaved flush can destroy a partially built ruleset. Does not establish the specific interleaving window named ("the second run's `iptables -F` lands between the first run's guard-jump appends and its `-o lo` accept") — that is a plausible instance, not a demonstrated one, and it is not the only one.
**Legibility-target:** for-author

Mechanism and conclusion are right, the illustration is imprecise. `node` can invoke the script concurrently (`Dockerfile:418`, NOPASSWD sudo with no concurrency guard), and phase B's `iptables -F` at `:513` unconditionally removes every rule any concurrent run has appended. The result — a run that reaches `FIREWALL_COMPLETE=1` over a ruleset another run has since flushed — follows.

The named window is narrower than reality: the `CC_DNS_GUARD` jumps are inserted at `:770-772` and the `-o lo` accept follows at `:779`, but a concurrent flush anywhere between `:513` and `:1040` produces the same class of outcome, and the probes at `:986-1015` would pass or fail on whatever ruleset happens to be live at that instant rather than on the one this run built. Stating one window as *the* mechanism reads as more specific than the evidence supports; the fix is correct regardless.

Precise version: "…a concurrent run's `iptables -F` can remove rules this run already appended at any point after the flush, so a run can reach its probes — and its completion sentinel — over a ruleset it did not build."

**Evidence:** `init-firewall.sh:513`, `:770-779`, `:986-1015`, `:1040`; `devcontainer-config/Dockerfile:418`.

---

## Claims Requiring Attention

### Incorrect

- **Claim 6** (`devcontainer-config/init-firewall.sh:529-531`): "If ip6tables is absent the kernel has no IPv6 filter to configure and the check is skipped — that is the one case this cannot close." The guard is a PATH lookup for a userspace binary; binary absence does not imply the kernel has no IPv6 filter, and binary *presence* does not imply the filter table is usable. Where the table is unavailable, the block's bare `ip6tables -P` calls abort the run into the fail-closed trap — a second uncloseable case the comment does not name, and a harsher one. **Consequence: comment-only** (the code path is correct; the stated reason is not).

### Stale

- **Claim 8** (`devcontainer-config/init-firewall.sh:717-719`): "IPv6 remains unfiltered end to end (pre-existing)" survives in the FILTERING RESOLVER residual paragraph after the commit made IPv6 default-denied and rewrote three sibling IPv6 statements. Comment-only.
- **Claim 9** (`devcontainer-config/init-firewall.sh:634`): the no-parseable-resolver WARNING still tells the operator "Loopback/host-network/IPv6 resolution is unaffected", contradicting the explanatory comment ten lines above (`:620-624`) that the same commit updated. Operator-visible text.
- **Claim 27** (`docs/decisions/log.md:62`): row 41 still describes a three-zone SNI allowlist including `.githubassets.com`; row 42 records the derivation change but not the drop, though the commit message does. Comment-only.

### Mostly Accurate

- **Claim 17** (`devcontainer-config/cc-sni-proxy.py:4-6`): "root runs the firewall script itself and its probes" — two of the four probes are run as `node` via `runuser` precisely so they traverse this proxy. The guide's parallel paragraph (Claim 25) states this correctly; the docstring should match it.
- **Claim 31** (`devcontainer-config/init-firewall.sh:295-297`): the concurrency hazard is real, but the single interleaving window named is one instance of a broader class (any concurrent flush after `:513`), stated with more specificity than the evidence carries.

### Unverifiable

- **Claim 23** (`devcontainer-config/devcontainer.json:76-79`): `DISABLE_GROWTHBOOK` appears on none of the three Claude Code doc pages checked, including the page `base.txt:4` names as the source of truth. Blocker: no available source confirms the variable exists or that it disables feature-flag evaluation. The "each of those" universal is also broader than the docs support for `DO_NOT_TRACK`.

---

## Escalations

| # | Entry | path:line | Addressee |
|---|---|---|---|
| E1 | The firewall lock is held on fd 9, which **is** inherited across `exec` (verified in this sandbox). `cc-sni-proxy.py` closes every fd > 2 in its daemon child (`:267-275`), so the proxy is safe. `dnsmasq` is started directly (`init-firewall.sh:735`) and its fd-closing behaviour could not be executed here (no `dnsmasq` binary in the sandbox). If dnsmasq retains fd 9, every subsequent run blocks for `CC_FIREWALL_LOCK_WAIT` (120s) and then fails closed — a container that cannot re-run its own firewall. Worth one live-container check, or a defensive `flock -o`/`9>&-` before the daemon starts. | `devcontainer-config/init-firewall.sh:302-307`, `:735` | orchestrator (author action) |
| E2 | Claim 6's second failure case: `ip6tables -P/-F/-X/-A` are called **bare** (no `\|\| true`), unlike the trap's guarded copies. On a host where the binary exists but the kernel's IPv6 filter table does not — a known Docker Desktop shape, and the `iptables` Debian package ships both binaries together — the run aborts into the fail-closed trap and the container gets no egress at all. Decide between guarding the calls and treating an ip6tables failure as fatal on purpose; either way the comment at `:529-531` should say which. | `devcontainer-config/init-firewall.sh:529-546` | orchestrator (author action) |
| E3 | Three IPv6 doc-drift residues from one change (Claims 8, 9, and the deliberately-preserved "(The line below predates that block…)" construction at `:620-624`). The last is honest but awkward — a comment that narrates its own obsolescence rather than being rewritten. One sweep over the file's IPv6 statements would close all three. | `devcontainer-config/init-firewall.sh:620-624`, `:634`, `:717-719` | orchestrator (author action) |
| E4 | `DISABLE_GROWTHBOOK` (Claim 23) was added to a documented do-not-use list without a citable source. Either confirm it against a source the file can name, or drop it — an unsourced env-var name in boundary config invites a later reader to set it. | `devcontainer-config/devcontainer.json:76-79` | orchestrator (author action) |
| E5 | The `helpers resolve through the pinned PATH` bats test asserts by grepping the script's source text for the literal `export PATH=…` line, not by exercising resolution. Its own comment says why. It will pass if the pin is reformatted and fail if the default list is reordered for a good reason — a brittle guard for a real control. Context-only (tests are outside this pass's scope) but worth the test-strategy critic's attention. | `test/init-firewall-rules.bats` (`helpers resolve through the pinned PATH, not the caller's`) | orchestrator |

---

## Goal-Alignment Note

- **Answered:** All twelve directed items. The six rubric-red fixes verify: registry (Claim 16, 19, 20), lock (1a/1b/1c, 31), IPv6 default-deny (4, 5, 7), `.githubassets.com`/zone derivation (13), the negative probe's logged-refusal requirement (14), and the PATH+shebang pin (2a, 2b, 3). The amber doc-drift sweep verifies for telemetry (22), platform.claude.com (24), base zones (15), Dockerfile modes and decision cites (21), the guide (25, 26) and decision row 42 (28) — but is **incomplete**: three IPv6 statements and one decision-log row were left behind (Claims 8, 9, 27). The mandatory executable guarantee reproduces exactly (29): 404/404 bats, 13/13 python, shellcheck clean, all at exit 0. Port canonicalisation and single-label resolver lines were executed against a purpose-built fixture (10, 11, 12), not merely read.
- **Out of scope:** `test/*.bats`, `docs/working/questions.md`, and the rubric itself — read as context to check counts and to confirm nothing was called "missing" that the commit in fact ships. Design questions the commit deliberately defers (proxy supervision, first-address selection, OPENROUTER gating, grammar tolerance) are logged with interim decisions and are not re-litigated here (30). Nothing requiring a live kernel, Docker, iptables or dnsmasq could be executed — the same gap the commit body states.
- **Escalate:** E1 is the only entry with a possible behavioral consequence and the one to settle first — if `dnsmasq` inherits fd 9, the lock added by this commit makes the *second* firewall run fail closed, converting a concurrency fix into a re-run outage. E2 is the second-order risk of the IPv6 block's bare calls. E3 and E4 are documentation; E5 is a test-quality note for the orchestrator to route.
