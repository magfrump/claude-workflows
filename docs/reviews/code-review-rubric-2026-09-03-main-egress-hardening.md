# Code Review Rubric

Commit: abbd42d

**Scope:** `bd41aef..abbd42d` on `main`, pass 1 of 2 — `devcontainer-config/` enforcement files (`init-firewall.sh`, `cc-sni-proxy.py`, `Dockerfile`, `devcontainer.json`, `egress/base.txt`, `egress/llm.txt`); tests and docs in the same range are sibling context, pass 2 pending | **Reviewed:** 2026-09-03 | **Status: 🔴 DOES NOT PASS** — 6 red item(s) unresolved

Pipeline: fact-check k=3 (44 clusters, 82% agreement) → 5 critics in parallel (security, performance, api-consistency, architecture-review, tech-debt-triage) → Stage 2.5 submitted-claims fact-check (8 claims, 7 executed-Verified). Delivery mode: self-read. `dependency-upgrade` was not run: it evaluates version transitions and this diff adds a package rather than bumping one; security-reviewer's dependency move covered the addition.

---

## 🔴 Must Fix

Issues that must be resolved before merge. Draft cannot pass review with any red items
unresolved.

| # | Finding | Domain | Severity | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|
| R1 | `install.sh`'s `PAYLOAD` array omits `cc-sni-proxy.py`, and `devcontainer.json` makes the installed config dir the Docker build context, so `COPY cc-sni-proxy.py /usr/local/bin/` (`Dockerfile:389`) has no source on a clean install — the planned rebuild fails at that step (or silently bakes a stale copy if one is already present). Copy loop at `install.sh:98-100` iterates `PAYLOAD` only (orchestrator confirmed statically; `install.sh` prompts interactively so a staged run was not executed). Convergence: api-consistency (Breaking) + architecture (Structural) + tech-debt A. | API consistency / Architecture | Breaking / Structural | `devcontainer-config/install.sh:25`, `Dockerfile:389`, `devcontainer.json:25-26` | for-author | — | 🔴 Unresolved |
| R2 | The bless manifest hashes 4 of the 7 artefacts `PAYLOAD` installs: `cc-sni-proxy.py` (new enforcement executable), `link-claude-home.sh`, and `claude-home/` (→ `/opt/claude-workflows`) are outside `enforcement_files()`, so a host-side edit to any of them does not trip `check_manifest()`. The proxy's own docstring claims the coverage it lacks (fact-check Claim 10, Incorrect, High). Convergence: architecture (Structural) + fact-check Incorrect + security (Medium) + api-consistency; corroboration: fact-check Incorrect. Must land with R1 — adding the file to the manifest without adding it to `PAYLOAD` makes `--bless` fail with "enforcement file missing". | Architecture / Security | Structural | `devcontainer-config/cc-isolated.sh:50-65`, `cc-sni-proxy.py:24-25` | for-author | — | 🔴 Unresolved |
| R3 | `init-firewall.sh` has no mutual exclusion and no `-w` on main-path `iptables` calls, and `node` can invoke it at will via NOPASSWD sudo. Traced interleaving: run B's flush lands while run A sits between the guard-jump appends and the `-o lo -j ACCEPT` at `:722-723`; A's `CC_DNS_GUARD` jumps are deleted, A appends the loopback accept as OUTPUT rule 1, wins the `ipset create` race, passes all four probes and sets `FIREWALL_COMPLETE=1` while B aborts — a "verified complete" ruleset in which `node` reaches `127.0.0.11:<embedded port>` for unfiltered recursion. Failure mode: agent-triggerable race removes the DNS guards. | Security | High | `devcontainer-config/init-firewall.sh:472-483`, `:715-723`, `:731` | for-author | — | 🔴 Unresolved |
| R4 | IPv6 egress is entirely unenforced: every control in this range — DROP policies, the `dst,dst` ipset accept, `CC_DNS`/`CC_SNI` REDIRECTs, both guard chains — is `iptables`-only, `ip6tables` is never invoked, and the proxy resolves `AF_INET` only. Where the container has routable IPv6 the DNS filter and SNI filter are bypassed wholesale. Pre-existing gap (`:510-512` says so) and accepted as residual in the 2026-08-29 review's prose, but it is now the single bypass for three controls. Decision needed: disable IPv6 at the runtime, or fail it closed in the script (`ip6tables -P OUTPUT DROP` if present). | Security | High | `devcontainer-config/init-firewall.sh:510-512`, `:558-559`; `cc-sni-proxy.py:182-183` | for-author | — (not in override log; prior acceptance was prose in `security-review-cc-isolated-egress-2026-08-29.md` "Residual risks", not a logged override) | 🔴 Unresolved |
| R5 | `.githubassets.com` is written into the SNI allowlist (`:866-868`) but absent from `GITHUB_DNS_ZONES` (`:154`), so the filtering resolver REFUSES it and the entry can never be exercised — dead config whose failure surfaces as `FAIL … (resolved address not in the ipset?)`, pointing at the wrong subsystem; the two "GitHub zones" lists live 700 lines apart and drifted in the commit that created the second. `test/init-firewall-rules.bats:727` pins the current form. Convergence: fact-check Incorrect (executed, two replicates) + api-consistency (Inconsistent) + architecture (Coupling) + tech-debt B; **escalated 🟡→🔴 under the Escalation Rule** (corroboration: fact-check Incorrect, executed). Fail-closed defect — inert, not exploitable. | Fact-check / API consistency / Architecture | Incorrect (medium) / Inconsistent / Coupling — escalated | `devcontainer-config/init-firewall.sh:154`, `:864-869`; `test/init-firewall-rules.bats:727` | for-author | — | 🔴 Unresolved |
| R6 | One profile line is read by three disagreeing grammars: `parse_entry` (accepts single labels and zero-padded ports, emits the port string verbatim), `compose_dnsmasq_conf`'s hostname regex (requires a dot), and the proxy's `Allowlist.load` (`name`/`.zone`). Reproduced by executing `--print-entries` on fixtures: `localhost` gets an ipset member but no resolver line; `api.anthropic.com:0443` reaches `ipset add … tcp:0443` *and* misses the `*,443,*` SNI filter, so it grants nothing at all. Convergence: api-consistency (Inconsistent) + architecture (Coupling) + security (Low) + tech-debt D; **escalated 🟡→🔴 under the Escalation Rule** (corroboration: critic-executed reproduction; fact-check Claims 21/24 scope residues, executed). Fail-closed — silent blackholing, not exposure. | API consistency / Architecture / Security | Inconsistent / Coupling / Low — escalated | `devcontainer-config/init-firewall.sh:116-134`, `:191-206`, `:857-869`; `cc-sni-proxy.py:129-138` | for-author | — | 🔴 Unresolved |

---

## 🟡 Must Address

Issues that must be fixed or acknowledged by the author with justification for why they
stand. Each must carry a resolution or author note.

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | The negative SNI probe passes on any non-zero curl exit, not on a proxy refusal: a missing redirect, a dead proxy, a `runuser` failure, or a transport error all print "non-allowlisted SNI refused as expected". Stated intent (`:934-936`: "an address that IS in the ipset, asked for with a name that is NOT allowlisted, must be refused") is defeated by the mechanism (`:937-943`: `if runuser … curl …; then ERROR … else passed`); R3 supplies a route to the exact state this probe would greenlight. Fix: grep `$SNI_LOG` for `REJECT sni=not-allowlisted.invalid` (or check curl's exit code is the empty-reply class). Convergence: security (Medium) + api-consistency (Minor) + fact-check Claim 37 (Mostly accurate) + tech-debt C. | Security | Medium · **Contested-Soundness** (Soundness cross-check; found by security-reviewer) | Security + API consistency + Fact-check | for-author | — | 🟡 Open | — |
| A2 | Every root-run helper — `dig`, `curl`, `runuser`, `dnsmasq`, `ipset`, and the proxy via its `#!/usr/bin/env python3` shebang — resolves through `PATH`; `/usr/local/share/npm-global/bin` is node-writable and on node's PATH; immunity rests on sudo's `secure_path`, which nothing in the repo asserts. The `:434-436` comment states the wrong reason ("executed directly … so a PATH hijack cannot substitute the interpreter" — `env python3` is exactly a PATH lookup). Fix: hard-code `#!/usr/bin/python3`, and assert or set `PATH` at the top of the script. | Security | Medium · **Contested-Soundness** (Soundness cross-check; found by security-reviewer) | Security | for-author | — | 🟡 Open | — |
| A3 | SNI filtering is bypassable by a client that hides or duplicates the server name: `parse_sni` returns the first `host_name` and stops (multi-entry ServerNameList / duplicate-extension differential against the upstream TLS stack), and TLS 1.3 ECH hides the name entirely. The proxy still connects only to the allowlisted name's address, so the residual is a CDN-edge routing differential, not an arbitrary destination. Low confidence on exploitability. | Security | Medium | Security | for-author | — | 🟡 Open | — |
| A4 | `OPENROUTER_API_KEY` is injected into every session whenever the host exports it, regardless of egress profile; the comment scopes the risk to `llm` ("otherwise … the key is inert"), but the exfiltration channel is base egress (GitHub CIDRs on 443/22, `.github.com` SNI-allowlisted), so the key is stealable from any project. Pre-existing lines (unchanged in this range; `devcontainer.json` was edited nearby). Fix: gate injection on the `llm` profile or move to a host-side broker; correct the "inert" sentence. | Security | Medium | Security | for-author | — | 🟡 Open | — |
| A5 | The proxy connects to `getaddrinfo`'s first address only, with no fallback and no reconciliation with the phase-A ipset snapshot; on divergence (CDN rotation mid-session) the kernel REJECTs, `handle()` logs `FAIL`, and dnsmasq's cache pins the failing answer until TTL expiry. Failure mode: HTTPS to an allowlisted host fails deterministically for the TTL. Security should rule whether iterating addresses is acceptable (it widens what the proxy attempts) or whether re-resolving the ipset is the right fix. | Performance | High (Medium confidence) | Performance | for-author | — | 🟡 Open | — |
| A6 | Nothing supervises the proxy after start: `daemonize()` returns 0 on readiness and nothing watches the daemon afterwards (dnsmasq gets a `kill -0` re-check at `:674`; the proxy gets none), so a post-startup death is a silent, session-long HTTPS outage for the agent. Convergence: performance (High) + architecture (Coupling) + tech-debt G + Stage 2.5 escalation. | Performance / Architecture | High / Coupling | Performance + Architecture | for-author | — | 🟡 Open | — |
| A7 | `getaddrinfo` per connection with no in-process cache; measured 10.1 ms/lookup here, and 200 concurrent identical lookups took 2.03 s (no parallel speedup — a connection burst to one host serialises on DNS in the default thread pool). | Performance | Medium | Performance | for-author | — | 🟡 Open | — |
| A8 | No concurrency cap and no idle timeout once the ClientHello is read; a wedged upstream holds a splice open indefinitely. Only client is the local agent, so availability-only. Convergence: performance (Medium) + security (Low). | Performance | Medium | Performance + Security | for-author | — | 🟡 Open | — |
| A9 | The two daemons managed by the same script follow different conventions: `CC_SNI_RUN_DIR` derives three paths while `CC_DNSMASQ_CONF`/`CC_DNSMASQ_PIDFILE` name files; different file layouts (`/run/cc-sni-proxy/` vs `/run/cc-dnsmasq.pid`); proxy `0555` vs firewall `chmod +x`; dnsmasq stop = pidfile + uid sweep, proxy stop = pidfile only. Convergence: api-consistency (Inconsistent) + architecture (Minor). | API consistency | Inconsistent | API consistency + Architecture | for-author | — | 🟡 Open | — |
| A10 | The stricter profile grammar hard-aborts inputs the profile files' own header implies are accepted — inline `#` comments (`base.txt:12`: "#-comments ignored"), trailing-dot FQDNs, indented lines — all previously warn-and-skip; the proxy's own allowlist parser *does* strip inline comments. Latent: all eight shipped profiles pass today (`--print-entries` combined: exit 0, 24 entries). | API consistency | Inconsistent | API consistency | for-author | — | 🟡 Open | — |
| A11 | Comment claims remaining telemetry "goes to api.anthropic.com"; the documented operational-telemetry host (`http-intake.logs.us5.datadoghq.com`) is not switched off by `DISABLE_ERROR_REPORTING` and is firewalled, not un-emitted. Comment-only consequence (code is correct). | Fact-check | Incorrect (high) on a comment only | Fact-check | for-author | — | 🟡 Open | — |
| A12 | `cc-sni-proxy.py:20-21` still says "a filtering dnsmasq once that lands"; it landed in this range and the proxy's port-53 traffic is REDIRECTed to it (fact-check Claim 7). | Fact-check | Stale | Fact-check | for-author | — | 🟡 Open | — |
| A13 | `init-firewall.sh:648-651` base-zone list still names `sentry.io`/`statsig.com` and omits `platform.claude.com` (fact-check Claim 30). | Fact-check | Stale | Fact-check | for-author | — | 🟡 Open | — |
| A14 | `Dockerfile:47-48` cites "decision log #39" for the filtering resolver; it is row 40 (fact-check Claim 2). Root cause: rows appended from parallel worktrees collided (also `d598bda`'s body — immutable, route to override log). | Fact-check | Stale | Fact-check | for-author | — | 🟡 Open | — |
| A15 | Doc imprecisions to tighten: `Dockerfile:386-388` "0555 like the firewall script" (firewall is `chmod +x`, Claim 4); `cc-sni-proxy.py:4-5` omits root's redirect exemption (Claim 5); `base.txt:22-24` "mid-session re-login" is inference (Claim 19); `init-firewall.sh:152-153` "unroutable" not established (Claim 22b); `devcontainer.json:75-78` do-not-set list omits `DISABLE_GROWTHBOOK` (Claim 15 scope). | Fact-check | Mostly accurate | Fact-check | for-author | — | 🟡 Open | — |
| A16 | `guides/cc-isolated-usage.md:296-305`: `FAIL` also covers DNS refusal and connect timeout (Claim 38b); "probes run as root" is wrong for the two SNI probes, which run as `node` on purpose (Claim 38c); a fourth log shape `REJECT orig_dst=…` with no `sni=` field is undocumented (Claim 38a scope). Guide is a pass-2 file; listed here because the fact-check verdicted it. | Fact-check | Mostly accurate | Fact-check | for-author | — | 🟡 Open | — |

---

## 🟢 Consider

Advisory findings from contextual critics, single-critic suggestions, and improvement
opportunities. Not required to pass review.

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Proxy log at `/run/cc-sni-proxy/proxy.log` is world-readable (0644) and unbounded; records every SNI and original destination for the session. (`/run` is the overlay layer, not tmpfs — per performance review.) | Security (Low) + Performance (Low) | Low | for-author | — | 🟢 Open |
| C2 | GitHub CIDRs admitted on tcp/22 with no name-layer check — SSH to any GitHub address passes the ipset with neither SNI nor DNS filtering. | Security | Informational | for-author | — | 🟢 Open |
| C3 | `--listen 3443` (no colon) makes `rpartition` yield `host=''` and `asyncio.start_server` binds `0.0.0.0` and `::` (critic executed). The firewall always passes `127.0.0.1:$PORT`, so unreachable in production; guard the flag anyway. | API consistency | Minor (executed) | for-author | — | 🟢 Open |
| C4 | Proxy log/stderr vocabulary diverges from sibling scripts' `ERROR:`/`WARNING:` prefixes; `--print-entries` error omits the grammar hint the production path prints; `ccproxy` is the only unhyphenated `cc`-scoped identifier. | API consistency | Minor | for-author | — | 🟢 Open |
| C5 | The launcher's boundary self-probe (`cc-isolated.sh:250-256`) asserts neither new control (dnsmasq REFUSED, SNI refusal) yet reports a full pass — extend `probe_boundary()` with a `dig example.com` REFUSED check and a `--resolve` SNI check as `node`. Also the tech-debt E recommendation: script the live-container check rather than doing it by hand. | API consistency (Informational) + Tech-debt E | Informational | for-author | — | 🟢 Open |
| C6 | Profile-grammar forward compatibility is one-way (new profiles on old images abort); the ipset name `allowed-domains` was retained across the `hash:net` → `hash:net,port` type change, so anything inspecting it by name sees a different shape. | API consistency | Informational | for-orchestrator-synthesis | — | 🟢 Open |
| C7 | Eight responsibilities in one 948-line privileged script; a split is blocked by R1/R2 (any new file must join both registries). Extensions are parallel edits, not registry entries (exempt-uid pair spelled out at six sites). Comments cite mutable decision-log row numbers. | Architecture (Minor ×3) + Tech-debt H | Minor | for-author | — | 🟢 Open |
| C8 | `ESTABLISHED,RELATED` accept sits behind ~10 OUTPUT rules and the splice doubles traversals; ~90–140 `ipset add` forks per rebuild where one `ipset restore` would do. Cold-path / micro. | Performance | Informational | for-author | — | 🟢 Open |
| C9 | Bats suite is pinned to exact `iptables`/`ipset` command strings (77 `grep -q` assertions) — the only observable without root; carry intentionally (tech-debt F). | Tech-debt | advisory | for-orchestrator-synthesis | — | 🟢 Open |
| C10 | Live-container verification gap: fact-check Claims 1 (dnsmasq-base package split), 23b (dnsmasq REFUSED RCODE), 28 (Docker DNAT port rewrite) and Stage 2.5 Claim 2b (kernel refuses UDP against `tcp:` ipset members) are all Unverifiable here and reduce to one privileged-container run already listed in `docs/working/questions.md`. None carries a crash/data-loss failure mode (the design's security properties hold independently of each: "never forwarded" follows from the config; the all-ports guard subsumes the DNAT question; QUIC denial is the one that matters most — check it first). | Fact-check (Unverifiable) + Tech-debt E | Unverifiable | for-orchestrator-synthesis | — | 🟢 Open |
| C11 | Allowlist completeness vs `network-config.md`: `console.anthropic.com` is no longer in the documented requirements; documented hosts absent from base: `claude.com`, `downloads.claude.ai`, `mcp-proxy.anthropic.com`, `raw.githubusercontent.com`, `storage.googleapis.com` (fact-check E4). Author decision, not a defect — the current base evidently works for CC's core loop. | Fact-check (escalation E4) | advisory | for-author | — | 🟢 Open |
| C12 | Stage 2.5 wording: architecture's "entire contract is six flags" omits the allowlist `.zone` grammar, the `ccproxy` uid, the run-dir layout and direct executability (Claim 7); "every network read is hoisted above the flush" is true for reads the rebuild depends on but the three post-build probes issue six network calls after it (Claim 8b). Adjust the What-Looks-Good wording; no code change. | Fact-check (Stage 2.5) | Mostly accurate | for-orchestrator-synthesis | — | 🟢 Open |
| C13 | Degenerate allowlist lines: `..foo` normalises to zone `foo`; a bare `.` becomes the empty zone (replicates disagree on whether `allows()` then matches names ending in `.`). Never generated by the firewall; harden `Allowlist.load` anyway. `useradd --system` uids are not stable across rebuilds (rules key on the run-time uid, so fine). | Fact-check (scope residues) | advisory | for-author | — | 🟢 Open |
| C14 | Decision-log row numbers collide when appended from parallel worktrees (fact-check E6, architecture F8) — reserve numbers before dispatch or switch to a merge-time renumbering step. Process, not code. | Fact-check + Architecture | process | for-orchestrator-synthesis | — | 🟢 Open |
| C15 | Three IPv4-only controls now share one IPv6 bypass — if R4 is waived, add at minimum an assertion that the container has no global IPv6 address, so the waiver is checked rather than assumed (tech-debt I). | Tech-debt | advisory | for-author | — | 🟢 Open |

---

## ↩️ Considered Overrides

No prior overrides matched this diff. (`docs/reviews/override-log.md` has one entry, on `hooks/batch-feedback-routing-reminder.sh`; no location, category, or substantive match.)

---

## ✅ Confirmed Good

Patterns, implementations, or claims confirmed correct by fact-check and/or critics.
Every row carries `Evidence` and has passed the Confirmed-Good cross-check.

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| The SNI proxy is started and its readiness handshake completes before any `CC_SNI` chain or REDIRECT rule is issued; a start failure aborts with zero `REDIRECT --to-ports 3443` rules and forced DROP. (Scope: does not cover a child dying after readiness — see A6.) | ✅ Confirmed | `init-firewall.sh:874-886` — `if ! "$SNI_PROXY_BIN" --daemon … then … exit 1; fi` precedes `iptables -t nat -N CC_SNI`; Stage 2.5 submitted claim 1 (executed: real `daemonize()` run both ways, `cfc-sc-1-*`) | security-reviewer → fact-check | for-orchestrator-synthesis |
| Every `allowed-domains` member the script emits carries a `tcp:` prefix (11/11 in a full stubbed run; three `ipset add` call sites, no other path), and the single consuming accept is `-m set --match-set allowed-domains dst,dst`. (Scope: script side only; kernel UDP-vs-tcp matching is C10.) | ✅ Confirmed | `init-firewall.sh:383-385`, `:744-745`, `:902`; Stage 2.5 claim 2a (executed, `cfc-sc-2-*`) | security-reviewer → fact-check | for-orchestrator-synthesis |
| Every rule naming the dnsmasq uid is an address-scoped `--dport 53` ACCEPT (to the parsed resolvers and the detected gateway) or a RETURN inside a chain that ends in REDIRECT/REJECT; zero unscoped accepts. | ✅ Confirmed | `init-firewall.sh:541-544`, `:788-791`, `:682-683`, `:694-695`; Stage 2.5 claim 3 (executed over the complete emitted rule sequence, `cfc-sc-3-*`) | security-reviewer → fact-check | for-orchestrator-synthesis |
| The proxy does not terminate TLS: no `ssl` import or certificate material; the bytes the upstream receives are byte-identical to the client's ClientHello in five fragmentation shapes (split records, split writes, 50 ms gap, trailing application data). | ✅ Confirmed | `cc-sni-proxy.py:157-165`, `:190-192`; Stage 2.5 claim 4 (executed fragmentation harness, `cfc-sc-4-*`) | security-reviewer → fact-check | for-orchestrator-synthesis |
| The splice (`pump()`) is not the throughput bottleneck: 512 MiB relayed over loopback in 0.66–0.76 s (670–775 MiB/s) on this host. (Scope: one long-lived connection; per-connection `getaddrinfo`/connect cost is A7.) | ✅ Confirmed | `cc-sni-proxy.py:157-165`; Stage 2.5 claim 5 (executed 3×, `cfc-sc-5-*`) | performance-reviewer → fact-check | for-orchestrator-synthesis |
| All four `--print-*` hooks are uniform, sit above the fail-closed trap in file order, and are side-effect-free: zero privileged-binary invocations and no files created across both argument forms under a logging PATH stub. | ✅ Confirmed | `init-firewall.sh:68-71`, `:100-103`, `:136-145`, `:210-213`, `:271`; Stage 2.5 claim 6 (executed, `cfc-sc-6-*`) | api-consistency-reviewer → fact-check | for-orchestrator-synthesis |
| All four daemon preconditions (dnsmasq binary, dnsmasq uid, proxy executable, ccproxy uid distinct and non-zero) are checked above the flush; each failure aborts with zero `iptables -F` issued. | ✅ Confirmed | `init-firewall.sh:389-407`, `:430-453`; Stage 2.5 claim 8a (executed, 4/4 abort tests, `cfc-sc-8-*`) | architecture-review → fact-check | for-orchestrator-synthesis |
| The flush→terminal-REJECT interval contains zero network calls (all 64 emitted commands classified: iptables/ipset, `ip route`, `pkill`, two loopback daemon starts). (Scope: the post-build probes issue network calls after the interval by design.) | ✅ Confirmed | `init-firewall.sh:472-483` … `:905`; Stage 2.5 claim 8b (executed enumeration + 3 bats tests, `cfc-sc-8-*`) | architecture-review → fact-check | for-orchestrator-synthesis |
| Both named test suites pass at `abbd42d` (`1..98`, 0 failures; 13/13 Python) and `shellcheck -S warning init-firewall.sh` is clean. (Scope: the two suites named, not every bats file.) | ✅ Confirmed | fact-check Claim 40a (executed by all three replicates; `r1-bats.log`, `cfc-r2-bats-abbd42d.txt`, `cfc-r2-pytests-abbd42d.txt`, `cfc-r2-shellcheck-abbd42d.txt`) | fact-check | for-orchestrator-synthesis |
| `parse_entry` rejects `port 0`, `65536`, non-numeric, trailing-comma, underscore-host and extra-token lines with a hard pre-flush abort and forced DROP. (Scope: the six malformed shapes tested; `0443` and single labels are accepted — see R6.) | ✅ Confirmed | `init-firewall.sh:105-133`, `:283-295`; fact-check Claims 18/21 (executed via `--print-entries` and the bats malformed-entry test) | fact-check | for-orchestrator-synthesis |
| `DISABLE_TELEMETRY`, `DO_NOT_TRACK` and `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` each disable the feature-flag evaluation Remote Control depends on, and `DISABLE_ERROR_REPORTING` does not. (Scope: the three named variables; the docs also name `DISABLE_GROWTHBOOK` — A15.) | ✅ Confirmed | `devcontainer.json:73-80`; fact-check Claim 15 (executed WebFetch of `code.claude.com/docs/en/remote-control.md`, 2026-09-03, r2) | fact-check | for-orchestrator-synthesis |

Rows considered and **not** promoted: proxy substitutability (Stage 2.5 claim 7, Mostly accurate — narrowed into C12); "every network read hoisted" (claim 8b — narrowed to the interval row above); UDP/QUIC denial (claim 2b, Unverifiable — C10); the `hash:net,port` port-scoping "admits exactly the model server" (fact-check Claim 20, static — residues on Docker Desktop resolution and other paths).

---

## ⚠️ Unverified Findings

All findings' evidence resolved. (Every `Evidence` quote in the five critic reports was located in the cited file; one apparent miss was a quoting artifact.)

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied. (Contextual `dependency-upgrade` was not dispatched — see the scope note at the top.)

---

## 🧩 Composition check

Multi-source co-located clusters found by the Fragment-Composition cross-check, with
the forced question's disposition for each.

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `install.sh:25` + `cc-isolated.sh:50-65` + `cc-sni-proxy.py:24-25` | FC-10, sec-4, api-1, api-4, arch-1, arch-2, debt-A | distinct defects: the joint root ("no single registry of enforcement artefacts; `PAYLOAD` and `enforcement_files()` are maintained by hand and both missed the new file") is already stated by arch-2 and debt-A; R1 and R2 have different fixes |
| 2 | `init-firewall.sh:154` + `:864-869` | FC-36, api-2, arch-4, debt-B | distinct defects: every fragment states the same complete mechanism and fix (R5) |
| 3 | `init-firewall.sh:116-134` + `:191-206` + `:857-869` + `cc-sni-proxy.py:129-138` | FC-21, FC-24, sec-10, api-3, arch-3, debt-D | distinct defects: each fragment states the three-grammar mechanism; api-3 already names both consequences (R6) |
| 4 | `init-firewall.sh:926-948` | FC-37, sec-5, api-14, debt-C | distinct defects: same finding, same fix (A1) |
| 5 | `cc-sni-proxy.py:181-189` | perf-1, perf-3, FC-6 (nsswitch caveat) | distinct defects: perf-1 states the first-address/no-reconciliation root completely; FC-6's caveat (lookup may not traverse dnsmasq if `/etc/hosts` answers) is a separate residue |
| 6 | `cc-sni-proxy.py:235-286` + `init-firewall.sh:874-886` | perf-2, arch-5, debt-G, SC-1 (residue), SC-escalation-b | distinct defects: A6 already states "readiness-only contract, no liveness re-check, no supervisor" |
| 7 | `init-firewall.sh:472-483` + `:715-723` | sec-2, FC-27 (Verified: chain idempotency) | distinct defects: FC-27 covers sequential re-runs, sec-2 concurrent ones — not contradictory (FC-27's scope excludes concurrency) |
| 8 | `devcontainer.json:73-80` | FC-15, FC-16, A15 (GROWTHBOOK) | distinct defects |

No cluster composed a root that no fragment stated.

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry an author note. 🟢 items are optional.
