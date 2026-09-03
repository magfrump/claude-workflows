# Tech Debt Triage — egress hardening bd41aef..abbd42d

**Commit:** abbd42d
**Scope:** `git diff bd41aef..HEAD -- devcontainer-config/` — `init-firewall.sh` (664/948 lines changed; the resulting file assessed), `cc-sni-proxy.py` (new, 308 lines), `Dockerfile`, `devcontainer.json`, `egress/base.txt`, `egress/llm.txt`. Read for context and not under review: `devcontainer-config/cc-isolated.sh`, `devcontainer-config/install.sh` (both unchanged in the range), `test/init-firewall-rules.bats`, `test/test_cc_sni_proxy.py`, `docs/working/questions.md`, `docs/decisions/log.md` rows 39–41.
**Date:** 2026-09-03
**Based on:** docs/reviews/code-fact-check-report.md (k=3 merged)

Advisory output (🟢 Consider tier). Two items below (A, C) are cheap enough that the cost of *not* fixing them before the rebuild-and-bless exceeds the cost of fixing them, and item A is a build break rather than debt in the ordinary sense — flagged for the orchestrator accordingly.

---

## Tech Debt Triage: the new enforcement file is registered in neither the install payload nor the bless manifest

**Location:** `devcontainer-config/install.sh:25`; `devcontainer-config/cc-isolated.sh:50-65`; `devcontainer-config/Dockerfile:386` (`COPY cc-sni-proxy.py /usr/local/bin/`); `devcontainer-config/cc-sni-proxy.py:25`
**Nature:** process / structural
**Cost of Deferral:** `+1 unregistered boundary file per new enforcement component` — and, until fixed, `+1 failed image build per rebuild attempt`
**Failure Cost:** `High × Med` — the file is the tcp/443 SNI decision point for every non-root process in the container; a host-side rewrite of it changes what the boundary admits and trips no check. Blast radius is the whole 443 allowlist; likelihood is bounded by the same host-compromise assumption the manifest exists to cover (`cc-isolated.sh:18-22`).
**Evidence:**
> `PAYLOAD=(devcontainer.json Dockerfile init-firewall.sh cc-isolated.sh link-claude-home.sh egress claude-home)` — `install.sh:25`
> `echo "init-firewall.sh"` / `echo "cc-isolated.sh"` — `cc-isolated.sh:55-56` (the four fixed names; the two globs that follow are `egress/*.txt` and `projects/*.profile`)
> `# SNI-filtering splice proxy started by init-firewall.sh. […] root-owned and 0555 like the firewall script it belongs to (decision log #41).` — `Dockerfile:383-385`
> `Single file, stdlib only […] root-owned in the image and hashed by the launcher's trust manifest.` — `cc-sni-proxy.py:24-25`
**Legibility-target:** for-author

### Carrying Cost: High
There are now three hand-maintained lists of boundary files — `install.sh`'s `PAYLOAD`, `cc-isolated.sh`'s `enforcement_files()`, and the Dockerfile's `COPY` lines — and adding a file requires editing all three with nothing to catch a miss. This change edited one. The immediate consequence is worse than the documentation defect the fact-check found (Claim 10): `devcontainer.json:26` sets the build context to `${localEnv:CC_CONFIG_DIR}`, and `install.sh` is what populates that directory, so `COPY cc-sni-proxy.py /usr/local/bin/` has no source file and the image build fails outright. The manifest gap is the residual once that is fixed: the proxy's own docstring claims a protection that `enforcement_files()` does not provide.

### Fix Cost
- **Scope:** two one-line edits — add `cc-sni-proxy.py` to `PAYLOAD` (`install.sh:25`) and to `enforcement_files()` (`cc-isolated.sh:53-56`) — plus `cc-isolated --bless`. Optionally correct `chmod +x` at `Dockerfile:409` to cover the proxy consistently (Claim 4).
- **Effort:** minutes.
- **Risk:** low. Adding a name to `enforcement_files()` invalidates the existing `manifest.sha256`, so the re-bless is mandatory and not optional — that is the intended gate, not a regression.
- **Incremental?** Yes, and it is a prerequisite for the rebuild that follows.

### Urgency Triggers
The stated next step is "rebuild the image and re-bless". The rebuild cannot succeed until `PAYLOAD` carries the file, and re-blessing without touching `enforcement_files()` blesses a manifest that omits the boundary's newest component.

### Recommendation
**Recommendation:** Fix now — trivial (two single-line edits, <50 LOC), fix in place. The build break makes this gating rather than advisory; the manifest half restores the invariant the proxy's docstring already asserts. Escalating to the orchestrator because it sits outside the reviewed diff and no critic scoped to `devcontainer-config/`'s changed files would have found the `install.sh` half.

---

## Tech Debt Triage: two GitHub zone lists that drifted on the first commit that created the second one

**Location:** `devcontainer-config/init-firewall.sh:154` and `:864-869`; pinned by `test/init-firewall-rules.bats:727`
**Nature:** structural
**Cost of Deferral:** `+0 — inert` (the entry cannot be exercised), but `+1 misleading allowlist line per reader who audits the SNI allowlist`
**Failure Cost:**
**Evidence:**
> `GITHUB_DNS_ZONES="github.com githubusercontent.com"` — `init-firewall.sh:154`
> `    echo ".github.com"` / `    echo ".githubusercontent.com"` / `    echo ".githubassets.com"` — `init-firewall.sh:866-868`
> `  grep -qx '.githubassets.com' "$al"` — `test/init-firewall-rules.bats:727`
**Legibility-target:** for-author

### Carrying Cost: Low
The same conceptual set — "the GitHub zones this boundary knows about" — is written twice in one file, 710 lines apart, in two different syntaxes (space-separated shell string vs. dotted heredoc lines), and the two disagreed in the commit that introduced the second. The practical effect today is nil: `.githubassets.com` has no `server=/…/` line, so no client using the container resolver can obtain an address for it and the SNI entry is unreachable (fact-check Claim 36, executed against `--print-dnsmasq-conf` by two replicates). The cost is that an auditor reading the SNI allowlist believes a zone is admitted that is not, and that the accompanying comment attributes `githubassets.com` to `git`/`gh`/`git-lfs`, contradicting the file's own note at `:150-153`.

### Fix Cost
- **Scope:** decide add-vs-drop, then either extend `GITHUB_DNS_ZONES` and correct the attribution comment, or delete line `:868`. Either way `test/init-firewall-rules.bats:727` changes — the test pins the drift rather than catching it.
- **Effort:** ~15 minutes including the test.
- **Risk:** low, but the two directions are not equivalent: adding the zone widens what the container can resolve; dropping the line narrows nothing (the entry is already dead). Dropping is the conservative default.
- **Incremental?** Yes.

### Urgency Triggers
None mechanical. Worth doing before the rebuild only because it is in the same file the rebuild is validating and costs almost nothing.

### Recommendation
**Recommendation:** Fix now — trivial, fix in place. Drop `.githubassets.com` and its test assertion unless someone can name a `gh`/`git` operation that needs it; the deeper fix (one list, derived) is item D's territory and does not need to happen here.

---

## Tech Debt Triage: the negative SNI probe passes on any curl failure

**Location:** `devcontainer-config/init-firewall.sh:937-943`
**Nature:** testing
**Cost of Deferral:** `+1 false "verification passed" per broken-boundary rebuild` — the check reports success in exactly the states it exists to detect
**Failure Cost:** `Med × Med` — a container whose REDIRECT never installed passes this probe and starts a session; the positive probe at `:928` bounds it (it must succeed through the same proxy), so the undetected state is narrow but not empty.
**Evidence:**
> `if runuser -u node -- curl --connect-timeout 5 --max-time 15 \` — `init-firewall.sh:937`
> `        --resolve "not-allowlisted.invalid:443:$ANTHROPIC_PROBE_IP" https://not-allowlisted.invalid/ >/dev/null 2>&1; then` — `:938`
> `    echo "Firewall verification passed - non-allowlisted SNI refused as expected"` — `:942`
**Legibility-target:** for-author

### Carrying Cost: Medium
This is the one check in the script that distinguishes the SNI proxy from address matching alone — the entire justification for decision log #41 — and it cannot fail for the wrong reason because it cannot distinguish reasons at all. Any non-zero curl exit lands in the `else` branch: DNS failure, connect timeout, a proxy that crashed, a REDIRECT that was never installed. The rest of this script is unusually careful about exactly this class of mistake (the fail-closed trap re-reads `iptables -S` rather than trusting `$?`, `:237-244`), which makes the probe an outlier rather than a house-style artefact.

### Fix Cost
- **Scope:** after the curl, assert the expected `REJECT sni=not-allowlisted.invalid` line appears in `$SNI_LOG`; the proxy already logs it (`cc-sni-proxy.py:179`).
- **Effort:** a few lines plus one bats assertion.
- **Risk:** low; the failure direction is toward a hard `exit 1` and the fail-closed trap, which is the safe side. Needs the log path to be readable at that point in the run — it is (`SNI_LOG` at `:441`, passed at `:875`).
- **Incremental?** Yes.

### Urgency Triggers
The live-container check (item E) is the first time this probe runs for real. Fixing it beforehand means that run actually tests something.

### Recommendation
**Recommendation:** Fix now — trivial, fix in place, ideally in the same commit as item E's runbook. Fact-check r2 escalated this to the security critic as a verification-strength question (E3); from a debt standpoint it is cheap enough that the strength question does not need adjudicating first.

---

## Tech Debt Triage: one profile-line format, three independent grammars

**Location:** `devcontainer-config/init-firewall.sh:116-134` (`parse_entry`), `:189-204` (`compose_dnsmasq_conf`'s hostname regex), `devcontainer-config/cc-sni-proxy.py:129-138` (`Allowlist.load`) and `:44` (`LABEL`)
**Nature:** structural
**Cost of Deferral:** `+1 divergence class per new consumer of a profile line` — three consumers today, three observed divergences
**Failure Cost:** `Low × Med` — every divergence found so far narrows (a name gets no resolver line, an SNI entry is unreachable) rather than widens; a future divergence in the other direction would not be caught by anything.
**Evidence:**
> `  [[ "$domain" =~ ^${label}(\.${label})*$ ]] || return 1` — `init-firewall.sh:125`
> `    if [[ ! "$d" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)+$ ]]; then` — `init-firewall.sh:199`
> `                (al.zones if line.startswith(".") else al.exact).add(line.lstrip("."))` — `cc-sni-proxy.py:137`
**Legibility-target:** for-author

### Carrying Cost: Medium
A profile entry is now read by three parsers that were written independently and agree only approximately. `parse_entry`'s domain grammar admits a bare single label (`(\.${label})*` — zero dots allowed); the resolver's regex requires at least one dot (`(\.…)+`), so a single-label entry is silently ipset-admitted with no resolver line. `parse_entry` validates ports numerically with `10#` but emits the raw string, so `good.example:0443` reaches `ipset add` as `tcp:0443` rather than `tcp:443` — the validator and the emitter disagree about what the value *is*. The proxy's `Allowlist.load` applies `lstrip(".")` and so folds `..foo` into the zone `foo`, and maps a bare `.` to the empty-string zone (replicates disagreed on what `allows()` then does — see Claim 12, which is itself a sign nobody can predict the third grammar from the first two). None of these is exploitable today because `init-firewall.sh` generates every input to the second and third parsers, but that is a property of the current generator, not an enforced invariant.

### Fix Cost
- **Scope:** normalise once in `parse_entry` (strip leading zeros, reject single-label domains or decide deliberately to keep them), then let the two downstream consumers assume canonical input; document the canonical form at the top of `egress/base.txt` where the grammar is already described (`base.txt:12-19`).
- **Effort:** half a day including tests for each divergence.
- **Risk:** medium. `parse_entry` is upstream of the ipset, the resolver config, and the SNI allowlist simultaneously; a normalisation bug narrows or widens all three at once. Every change is covered by the `--print-entries` / `--print-dnsmasq-conf` hooks, which is what makes it tractable.
- **Incremental?** Yes — the zero-padded port and the single-label case are independent fixes.

### Urgency Triggers
A fourth consumer of the profile format. The pattern so far is one new consumer per hardening wave (ipset → resolver → proxy in three commits), so the trigger is the next security review finding that needs the allowlist by name.

### Recommendation
**Recommendation:** Fix opportunistically — take the normalisation the next time a profile-format change is needed for another reason. Nothing here is reachable through a root-owned profile file today, and the three divergences all fail in the narrowing direction, so the payoff is future-consumer safety rather than a present hole.

---

## Tech Debt Triage: no verification against a real kernel, Docker, or dnsmasq — every guarantee is stub-asserted

**Location:** `test/init-firewall-rules.bats:12-19` (suite preamble), `test/test_cc_sni_proxy.py`; the affected assertions at `devcontainer-config/init-firewall.sh:161-173`, `:462-471`, `:561-563`, `:817-835`
**Nature:** testing
**Cost of Deferral:** `+3 unverifiable behavioural claims per hardening wave` (this wave: Claims 1, 23b, 28) — and the whole boundary is unproven until one live run happens
**Failure Cost:** `High × Med` — the three controls added here (port-scoped ipset, filtering resolver, SNI proxy) all depend on kernel behaviours asserted from documentation: `xt_owner` in nat OUTPUT, REDIRECT of locally generated packets under Docker Desktop, dnsmasq answering with zero `server=` lines, policies surviving `iptables -F`. If any is wrong the failure is silent in the safe direction (no egress) or the unsafe one (redirect never fires, ipset accept reachable directly) depending on which.
**Evidence:**
> `# HOW IT RUNS WITHOUT ROOT. The script is executed for real, with `iptables`,` — `test/init-firewall-rules.bats:12`
> `# and `id` replaced by PATH stubs that append their argv to $CMD_LOG and return` — `:14`
> `# Kernel/netfilter semantics are out of scope here and need a privileged container` — `:17-18`
> `- [ ] 2026-09-03 Live-container check of the filtering resolver: does `xt_owner` in nat OUTPUT and REDIRECT of locally generated packets behave under Docker Desktop's kernel […] · interim: shipped on stub tests only` — `docs/working/questions.md:10`
**Legibility-target:** for-orchestrator-synthesis

### Carrying Cost: High
The 98 bats tests and 13 Python tests are genuinely good at what they cover — command sequences, ordering, parse grammars, the fail-closed trap's read-back, a loopback splice — and they caught real defects in earlier passes. What no test in the repo does is run one packet through one rule. The commit bodies say so, `docs/decisions/log.md` rows 40 and 41 say so ("needs a live-container check on Docker Desktop … before bless"), and the fact-check's three Unverifiable verdicts all reduce to the same missing run (escalation E5). The debt is not that the live check hasn't happened — it is that there is no *artefact* that performs it, so every future hardening wave re-incurs the same manual, undocumented, easily-skipped step, and the pre-bless checklist lives only in a questions-doc checkbox.

### Fix Cost
- **Scope:** a scripted post-build smoke check. `cc-isolated.sh` already has the right shape at `probe_boundary()` (`:232-323`) — five `devcontainer exec` assertions, each with a named failure message. Adding three more (as `node`: `dig example.com` expects REFUSED; a `curl --resolve` forged-SNI attempt expects failure *and* a matching `REJECT` line in `/run/cc-sni-proxy/proxy.log`; `iptables -S -t nat` shows the `CC_SNI`/`CC_DNS` jumps) turns the manual checklist into the existing launch gate.
- **Effort:** half a day, most of it iterating against a real container.
- **Risk:** low for the harness; the risk lives in what it finds. A probe that fails on Docker Engine but not Docker Desktop (or vice versa) needs an explicit runtime split, which does not exist today.
- **Incremental?** Yes — one assertion at a time, each independently useful.

### Urgency Triggers
Immediate and explicit: the rebuild-and-bless this review precedes. `questions.md:13` already lists the manual sequence as the action item.

### Recommendation
**Recommendation:** Fix now — non-trivial; hand to research-plan-implement, scoped to extending `probe_boundary()` rather than building a new harness. The one-off manual run must happen before the bless regardless; doing it once through a scripted probe costs little more than doing it by hand and stops the next wave from starting from zero.

---

## Tech Debt Triage: the rule tests are pinned to the exact command vocabulary

**Location:** `test/init-firewall-rules.bats` (77 `grep -q` assertions against `$CMD_LOG`), e.g. `:351-353`, `:562-565`, `:727`
**Nature:** testing
**Cost of Deferral:** `+~5 test edits per rule-syntax change` (measured: the four hardening commits in this range added 592 lines of test for 664 lines of script)
**Failure Cost:**
**Evidence:**
> `  grep -q "^iptables -A OUTPUT -p udp -d 192.168.65.1 --dport 53 -m owner --uid-owner 999 -j ACCEPT$" "$CMD_LOG"` — `test/init-firewall-rules.bats:351`
> `  guard=$(first_line_matching "^iptables -A OUTPUT -d 127.0.0.11 -j CC_DNS_GUARD$")` — `:562`
**Legibility-target:** for-orchestrator-synthesis

### Carrying Cost: Medium
Anchored full-line matches on rendered `iptables` argv mean any change to how a rule is *spelled* — reordering `-p udp` and `-d`, switching `-m state` to `-m conntrack`, adding a `-w` — breaks tests that were asserting a property that did not change. The suite deliberately trades this off (its preamble explains that command sequence is the only observable available without root), and the ordering assertions via `first_line_matching` genuinely encode semantics that nothing else can check. But the cost is real and visible in the change cadence: `git log --follow` shows four hardening commits on `init-firewall.sh` in a week, each carrying a proportionally large test delta.

### Fix Cost
- **Scope:** helper predicates over a parsed `$CMD_LOG` (`rule_exists --chain OUTPUT --proto udp --dport 53 …`) so assertions name properties, not strings.
- **Effort:** 1–2 days to build and migrate 77 assertions.
- **Risk:** medium and mostly downside — a parser abstraction over the log can itself be wrong, and a wrong abstraction silently weakens 77 tests at once. The current form's blunt literalness is why the suite is trustworthy.
- **Incremental?** Yes, but a half-migrated suite is worse than either endpoint.

### Urgency Triggers
None. Would flip if the rule set were being restructured wholesale — e.g. a move to `nft` or to `iptables-restore` batching, which would invalidate the vocabulary entirely.

### Recommendation
**Recommendation:** Carry intentionally. This is the cost of testing a root-only subsystem without root, and the suite's own preamble makes the trade explicit. Item E's live probe is the better place to spend testing effort: it adds coverage the stubs structurally cannot, where a helper-predicate refactor only makes existing coverage cheaper to maintain.

---

## Tech Debt Triage: two daemons, two restart mechanisms, no supervision after start

**Location:** `devcontainer-config/init-firewall.sh:413-428` (`stop_dnsmasq`), `:661-678`; `devcontainer-config/cc-sni-proxy.py:212-232` (`stop_prior`), `:240-256`
**Nature:** structural
**Cost of Deferral:** `+0 — inert while both daemons stay up`; `+1 whole-container outage per unnoticed daemon death`
**Failure Cost:** `Low × High` — a dead proxy means every tcp/443 flow is REDIRECTed to a closed port: total egress outage, no security exposure. A dead dnsmasq is the same for DNS. Both fail in the safe direction; the cost is availability and diagnosis time, not exposure.
**Evidence:**
> `    pkill -x -U "$DNSMASQ_UID" dnsmasq 2>/dev/null || true` — `init-firewall.sh:427`
> `def stop_prior(pidfile):` / `    """Kill the instance named by the pidfile, if it is one of us and alive."""` — `cc-sni-proxy.py:212-213`
> `# FAIL-CLOSED. If the proxy does not come up, this script exits non-zero and the` — `init-firewall.sh:842`
**Legibility-target:** for-orchestrator-synthesis

### Carrying Cost: Low
Two long-lived processes were added to a container that has no process supervisor, started by a script that runs once at `postStartCommand` and then exits. They use different stop strategies for the same problem: dnsmasq stops by pidfile *and* sweeps by uid (justified at `:409-412` — nothing else runs as that uid); the proxy stops by pidfile only, so an orphan with a lost pidfile survives, the new child's bind fails, and the run fails closed with `exit 1` (Claim 31). That asymmetry is defensible per-daemon but reads as inconsistency, and neither daemon is watched after start — a crash at hour three of a session is invisible until the user notices that nothing resolves or nothing reaches 443. The fail-closed direction is what keeps this Low.

### Fix Cost
- **Scope:** either give the proxy the same uid sweep dnsmasq has (small, symmetric), or add supervision (large: a supervisor process, or restart-on-exit wrappers, in a container that deliberately has neither).
- **Effort:** ~1 hour for the sweep; multi-day for real supervision.
- **Risk:** the sweep is low-risk and mirrors an already-reviewed pattern. Supervision is a genuine design change — anything that restarts the proxy must also re-read the allowlist, and the allowlist is generated per firewall run.
- **Incremental?** Yes; the sweep stands alone.

### Urgency Triggers
The first observed mid-session daemon death. Nothing today reports one, which is itself the gap.

### Recommendation
**Recommendation:** Defer and monitor. Take the uid-sweep symmetry when the file is next open (item D's neighbourhood); do not build supervision on speculation. The monitor is cheap and already half-present: the proxy log path is documented in `guides/cc-isolated-usage.md`, so a health-check line that asserts both pids are alive would surface the failure mode before deciding what to do about it.

---

## Tech Debt Triage: a 948-line script whose comments are the documentation of record, and drift accordingly

**Location:** `devcontainer-config/init-firewall.sh` (948 lines, ~60% comment); staleness instances at `:648-651` (Claim 30), `:150-153` vs `:864-868` (Claim 36), `devcontainer-config/Dockerfile:47-48` (Claim 2), `devcontainer-config/cc-sni-proxy.py:20-21` (Claim 7), `devcontainer-config/devcontainer.json:78-79` (Claim 16)
**Nature:** structural / process
**Cost of Deferral:** `+~4 stale or imprecise comment claims per hardening wave` (this wave: 4 Stale + 7 Mostly-accurate across 44 checked claims)
**Failure Cost:**
**Evidence:**
> `# RESIDUAL. dnsmasq matches zones by suffix. […] None of the base zones` — `init-firewall.sh:646-648`
> `# (api.anthropic.com, claude.ai, console.anthropic.com, sentry.io, statsig.com,` — `:649` (names two hosts this same range deleted from `base.txt` and omits the one it added)
> `# (decision log #39: the filtering resolver that closes recursive-forward DNS tunnelling).` — `Dockerfile:47-48` (the resolver is row 40; row 39 is port scoping)
**Legibility-target:** for-orchestrator-synthesis

### Carrying Cost: Medium
The prose in this file is unusually good — it records rejected alternatives, states residual risks, and explains why each `|| true` is load-bearing — and it is the only place several of those rationales exist. That is exactly why the drift matters: there is no second copy to disagree with, so a stale comment is simply wrong documentation. The observed drift is concentrated in comments that *enumerate* things maintained elsewhere (the base-zone list, decision-log row numbers, which tools contact which GitHub host) rather than in comments that explain mechanism, which held up under fact-check. The decision-log row numbers additionally collided because parallel worktrees each appended a row 39 (fact-check E6); citing a mutable row number from an immutable comment is a guaranteed future defect, not a maintenance slip.

The 948-line single-file shape is not itself the debt: the NOPASSWD-sudo-on-one-path design and the bless manifest both depend on it, and splitting the script would widen the sudo grant. Bounded fix options follow from that, correctly.

### Fix Cost
- **Scope:** two narrow, durable rules rather than a rewrite — (1) stop citing decision-log row numbers from code; cite the decision title or the security-review finding number, both of which are stable; (2) delete the enumerations that duplicate `egress/base.txt` and `GITHUB_DNS_ZONES` and point at them instead. Then fix the five instances above.
- **Effort:** 1–2 hours for the instances; the rules cost nothing ongoing.
- **Risk:** very low — comment-only, except item B's `.githubassets.com` decision which is tracked separately.
- **Incremental?** Yes, per instance.

### Urgency Triggers
None mechanical. Every future fact-check pass on this file re-finds this class, which is a slow, predictable tax rather than a trigger.

### Recommendation
**Recommendation:** Fix opportunistically. Sweep the five stale instances alongside items B and C (same file, same commit) and adopt the no-row-numbers rule; leave the file's size and comment density alone — they are load-bearing given the single-path sudo constraint, and the fact-check found the *explanatory* comments accurate.

---

## Tech Debt Triage: three new IPv4-only controls in front of an unfiltered IPv6 path

**Location:** `devcontainer-config/init-firewall.sh:510-512` (the acknowledgement), `:731` (`hash:net,port`, IPv4 members only), `:886` (`iptables`-only redirect); `devcontainer-config/cc-sni-proxy.py:183` (`family=socket.AF_INET`)
**Nature:** structural
**Cost of Deferral:** `+1 control with a documented total bypass per hardening wave` — three added in this wave
**Failure Cost:** `High × Low` — if the container ever gets working IPv6 egress, the port-scoped ipset, the filtering resolver, and the SNI proxy are all bypassed at once by any process that prefers AAAA. Likelihood is Low only because Docker's default bridge does not provide IPv6, which this repo asserts nowhere.
**Evidence:**
> `# allowlist — not just DNS — is unenforced for IPv6 (a pre-existing gap).` — `init-firewall.sh:512`
> `                sni, upstream_port, family=socket.AF_INET, type=socket.SOCK_STREAM)` — `cc-sni-proxy.py:183`
> `# unfiltered (pre-existing).` — `init-firewall.sh:653-654`
**Legibility-target:** for-orchestrator-synthesis

### Carrying Cost: Medium
The gap is pre-existing and honestly documented in three separate places — but its weight changed in this range. Before, one control (an IPv4 ipset) had an IPv6 hole. Now three controls do, and the two new ones are precisely the name-aware checks that the whole hardening effort was about; an AAAA-preferring client bypasses the SNI proxy and the filtering resolver together. The controlling assumption — the container has no usable IPv6 route — is stated nowhere and asserted nowhere, which is the same shape as the `/etc/resolv.conf` trust assumption the script *does* call out at `:519-527`.

### Fix Cost
- **Scope:** cheapest useful step is an assertion, not a port: a phase-A check that no global IPv6 route exists, failing closed (or at minimum warning) if one appears. Full parity means `ip6tables` rules, an IPv6 ipset, `AF_UNSPEC` in the proxy, and IPv6 upstreams in `compose_dns_resolvers` — a fourth hardening wave.
- **Effort:** ~1 hour for the assertion; multi-day for parity.
- **Risk:** the assertion is low-risk but must not brick a container on a link-local address; parity is a substantial change to every component touched in this range.
- **Incremental?** Yes — assertion first, parity later if ever.

### Urgency Triggers
Any change to the container's network mode: Docker IPv6 enablement, host networking, a custom bridge, or a corporate environment that hands out IPv6. None planned, which is the only reason this is not Fix now.

### Recommendation
**Recommendation:** Defer and monitor, with the assertion as the monitor. Add the "no global IPv6 route" check to item E's live probe while that work is open — it converts an undocumented environmental assumption into a checked one for roughly the cost of one `devcontainer exec`, and leaves the parity question for when something actually changes.

---

## Not debt

- **Claim 16 — "the remaining telemetry events go to api.anthropic.com"** (`devcontainer.json:78-79`, `egress/base.txt:9-10`): a one-line comment imprecision (CC still attempts a Datadog intake host, which the terminal REJECT drops). No structural consequence and no maintenance cost — a wording fix, routed with item H's sweep.
- **Allowlist completeness vs. the network-config docs** (fact-check E4: `console.anthropic.com` retained, `claude.com` / `downloads.claude.ai` / `mcp-proxy.anthropic.com` / `raw.githubusercontent.com` / `storage.googleapis.com` absent): an open configuration question awaiting a live session, already in `questions.md:6`. It is a decision the author has not made yet, not a shortcut taken to save time.
- **The root exemption from both redirects** (`init-firewall.sh:613-622`, `:830-835`): a deliberate, twice-documented design choice with its consequence stated ("root is not the boundary being defended") and its own tracked question (`questions.md:12`). The only defect is that `cc-sni-proxy.py:4-5` omits it from the docstring — item H's sweep.
- **`chmod +x` vs `0555` on `init-firewall.sh`** (Claim 4, `Dockerfile:409`): a permission inconsistency worth one character of fix, folded into item A.

---

## Triage Summary

| # | Debt Item | Carrying Cost | Cost of Deferral | Failure Cost | Fix Cost | Urgency | Recommendation |
|---|---|---|---|---|---|---|---|
| A | Proxy in neither install payload nor bless manifest | High | +1 unregistered boundary file per component; +1 failed build per rebuild | High × Med | Minutes | Rebuild + bless is next | **Fix now** (trivial, in place) |
| B | Two GitHub zone lists, drifted; drift pinned by a test | Low | +0 inert; +1 misleading line per auditor | — | ~15 min | Same-file convenience | **Fix now** (trivial, in place) |
| C | Negative SNI probe passes on any curl failure | Medium | +1 false pass per broken-boundary rebuild | Med × Med | A few lines | Live check is imminent | **Fix now** (trivial, in place) |
| D | Three grammars for one profile-line format | Medium | +1 divergence class per new consumer | Low × Med | ~0.5 day | 4th consumer | **Fix opportunistically** |
| E | No live-kernel/Docker/dnsmasq verification at all | High | +3 unverifiable claims per wave | High × Med | ~0.5 day | Pre-bless gate, now | **Fix now** (non-trivial → RPI) |
| F | Bats suite pinned to exact command strings | Medium | +~5 test edits per rule-syntax change | — | 1–2 days | Wholesale rule restructure | **Carry intentionally** |
| G | Two daemons, two restart paths, no supervision | Low | +0 inert; +1 outage per unnoticed death | Low × High | 1 hr / multi-day | First observed death | **Defer and monitor** |
| H | 948-line script; comments are the docs, and drift | Medium | +~4 stale claims per wave | — | 1–2 hrs | None | **Fix opportunistically** |
| I | Three IPv4-only controls, IPv6 unfiltered | Medium | +1 control with total bypass per wave | High × Low | 1 hr (assertion) | Network-mode change | **Defer and monitor** |

## Recommended Order

1. **A** — blocks the rebuild outright (`COPY` has no source file) and closes the manifest gap in the same edit. Nothing else can be validated until this lands.
2. **C** — few lines, and it must precede E or E's first real run tests a probe that cannot fail.
3. **E** — the pre-bless live-container check, scripted into `probe_boundary()` rather than run by hand. Fold I's IPv6-route assertion in while the probe is open.
4. **B + H** — one comment-and-consistency sweep over `init-firewall.sh`, `Dockerfile`, `cc-sni-proxy.py`, and `devcontainer.json`; includes the `.githubassets.com` decision, its bats assertion, the stale base-zone list, the decision-log row numbers, the proxy docstring's missing root exemption, and the telemetry wording.
5. **D** — next time the profile format is touched for another reason.
6. **G, F, I (parity)** — carry; revisit on their named triggers.

Items 1–3 are the pre-bless set. Item 4 is comment-only and can follow the rebuild without affecting what the image does.

## Goal-Alignment Note

- **Answered:** yes — nine debt items triaged from the `bd41aef..abbd42d` `devcontainer-config/` diff, with four non-debt candidates dropped and reasons given.
- **Out of scope:** kernel/netfilter correctness (no privileged container here — that is item E's subject, not something this triage could settle); whether the allowlist is *complete* against the current network-config docs (fact-check E4 — an author decision, not debt); the security-strength adjudication of the root exemption and the negative probe (fact-check E3 — routed to the security critic, though item C's fix is cheap enough to take regardless of how it is adjudicated).
- **Escalate:** **item A's `install.sh` half is a build break, not advisory debt** — `devcontainer-config/install.sh:25`'s `PAYLOAD` array omits `cc-sni-proxy.py`, and `devcontainer.json:26` makes the installed config dir the build context, so `Dockerfile:386`'s `COPY cc-sni-proxy.py /usr/local/bin/` has no source. The rebuild this review precedes will fail until that array is updated. This is outside the reviewed diff (`install.sh` is unchanged in the range) and extends fact-check Claim 10, which found only the `enforcement_files()` half. Both need fixing before `cc-isolated --bless`.
