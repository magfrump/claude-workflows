# API Consistency Review — egress hardening pass 3, 2839e59..1434fc9

Commit: 1434fc9

**Scope:** `git diff 2839e59..1434fc9 -- devcontainer-config/` — `init-firewall.sh`, `Dockerfile`, `cc-sni-proxy.py`. Third pass of the review-fix loop, over the second fix round (`6eaa9a0` pass-2 re-review closeout, `1434fc9` loop-pass follow-ups). `test/init-firewall-rules.bats`, `test/cc-isolated-functions.bats`, `devcontainer-config/egress/*.txt`, `guides/cc-isolated-usage.md`, `docs/working/questions.md` and the pass-2 rubric are in the range but were read here as **consumers and baselines**, not as review targets.
**Date:** 2026-09-03
**Based on:** `docs/reviews/api-consistency-review-2026-09-03-egress-hardening-r2.md` (pass 2, at `2839e59`, findings N1–N10); `docs/reviews/api-consistency-review-2026-09-03-egress-hardening.md` (pass 1, at `abbd42d`, F1–F14); `docs/reviews/code-fact-check-report.md` (k=1 loop pass, at `6eaa9a0`); `docs/reviews/code-review-rubric-2026-09-03-main-egress-hardening.md` (pass-2 rows R7, A17–A25, C16–C18).

---

### Prior findings status

All ten findings from the r2 report. "Open" means the item survives unchanged in the range and remains carried by rubric row C16; "Partly fixed" means the mechanical half of the recommendation landed and the cosmetic half did not.

| Prior # | Finding | Status | Evidence |
|---|---|---|---|
| N1 | dnsmasq hostname grammar is an inline duplicate of `parse_entry`'s label regex | **Fixed** | `init-firewall.sh:129-130` defines `HOST_LABEL`/`HOST_RE` once; `:141` and `:220` both test `[[ … =~ $HOST_RE ]]`. The duplicate literal at the old `:214` is gone. Residue in new findings 1 and 2 (the prefix collides with `HOST_IP`; the "one grammar" claim is scoped to the shell). Rubric A17 ✅. |
| N2 | `CC_FIREWALL_PATH` names a search list where every sibling `CC_*` names one object | **Open (accepted)** | `init-firewall.sh:38` unchanged. Rubric A25 records the acceptance with the `env_reset` argument; the name was not changed and the annotation at `:35-37` already existed. |
| N3 | The two lock seams omit the "unit tests only / `env_reset`" annotation every sibling carries | **Fixed** | `init-firewall.sh:534-535`: "CC_FIREWALL_LOCK / CC_FIREWALL_LOCK_WAIT exist for the unit tests only; under sudo env_reset `node` cannot set them." Same wording shape as `:428-430`. |
| N4 | Lock-failure message names one cause for a branch with two | **Fixed — both halves** | `init-firewall.sh:538` validates the timeout (`[[ … =~ ^[0-9]+$ ]]`) and `:540` reports the condition rather than a hypothesis: "could not take $FIREWALL_LOCK within ${FIREWALL_LOCK_WAIT}s — another init-firewall.sh rebuild is still running". Rubric A21 ✅. The silent-repair posture the guard chose is new finding 4. |
| N5 | `enforcement_files()` / `PAYLOAD` declared "in step" but differently ordered and unchecked | **Partly fixed** | The mechanical half landed: `test/cc-isolated-functions.bats:496-509` asserts every regular `PAYLOAD` member appears in `enforcement_files()` (rubric A22 ✅). The cosmetic half did not: `cc-isolated.sh:54-59` still orders the list differently from `install.sh:25`, and line 49 is still the 140-char run-on. Out of this pass's file scope; recorded for the loop. |
| N6 | `GITHUB_DNS_ZONES` name and definition comment lag its second (SNI) consumer | **Open** | `init-firewall.sh:165-174` is byte-identical to the r2 quote — the opening sentence still reads "zones the filtering **resolver** must answer for" and the `_DNS_` infix is unchanged. |
| N7 | `IPv6: …` is the only topic-prefixed stdout status line | **Open** | `init-firewall.sh:592` still `echo "IPv6: default-deny installed (loopback and established flows only)"`. The neighbouring `WARNING:` branch was reworded (see finding 9) but the status line was not. |
| N8 | Lock file: fourth `/run` layout convention, only generated file with no explicit mode | **Partly fixed — and the layout question resolved the other way** | Mode half closed: `:542` `chmod 0600 "$FIREWALL_LOCK"`, dir `chmod 0700` at `:539`, both pinned by `test/init-firewall-rules.bats:933-938`. Layout half: the lock moved *into* a directory (`/run/cc-firewall/lock`), joining `/run/cc-sni-proxy/…` — so the convention is now dir-per-subsystem with `/run/cc-dnsmasq.pid` (`:439`) as the lone flat outlier. A9 is now a one-file question rather than a three-way split. |
| N9 | `--print-dnsmasq-conf` warns where `--print-entries` hard-fails on the same input | **Open — and now more reachable** | Re-executed at HEAD on a `localhost:11434` fixture: `--print-entries` → `ERROR: malformed egress entry 'localhost:11434'`, exit 1; `--print-dnsmasq-conf` → `WARNING: not a hostname, omitting …: localhost`, exit **0**. The grammar tightening moved every single-label name into this divergence. See finding 7 — the new test at `test/init-firewall-rules.bats:853-865` dropped its exit-status assertion, so the divergence is now exercised and deliberately not asserted. |
| N10 | The `9>&-` comment justifies an asymmetry the code does not make | **Open — targeted but not landed** | `init-firewall.sh:782-784` is unchanged in the range: "The proxy closes inherited fds itself; dnsmasq is not assumed to." Both daemons still get `9>&-` (`:785`, `:994`). The comment also now names `CC_FIREWALL_LOCK_WAIT`, which the flock call no longer reads directly (`:541` uses the validated `$FIREWALL_LOCK_WAIT`). |

---

### Baseline Conventions

Surveyed across `init-firewall.sh` (1087 lines), `cc-sni-proxy.py`, `Dockerfile`, `cc-isolated.sh`, and the two bats suites.

- **Script-level constants**: `UPPER_SNAKE`, no `readonly` anywhere in the tree (`rg 'readonly|declare -r'` over `devcontainer-config/*.sh` → 0 hits). Shape is `<SUBSYSTEM>_<THING>`: `EGRESS_DIR`, `PROFILE_FILE`, `GITHUB_DNS_ZONES`, `DNSMASQ_CONF`, `DNSMASQ_PIDFILE`, `SNI_PROXY_BIN`, `SNI_RUN_DIR`, `SNI_PORT`, `FIREWALL_LOCK`, `HOST_IP`.
- **Test seams**: `CC_<SUBSYSTEM>_<OBJECT>` with a `${CC_X:-default}` expansion at the declaration site, and a comment at that site stating "for the unit tests only; under sudo `env_reset` `node` cannot set them" (`:35-37`, `:428-430`, `:470-474`, and now `:534-535`). Nine seams: `CC_FIREWALL_PATH`, `CC_EGRESS_DIR`, `CC_EGRESS_PROFILE_FILE`, `CC_DNSMASQ_CONF`, `CC_DNSMASQ_PIDFILE`, `CC_SNI_PROXY_BIN`, `CC_SNI_RUN_DIR`, `CC_SNI_PORT`, `CC_FIREWALL_LOCK(_WAIT)`.
- **Value validation**: a bad value **aborts with an `ERROR:` naming the observed value** — `DNSMASQ_UID` (`:447-449`), `CCPROXY_UID` (`:495-497`), GitHub CIDRs (`:378`), resolved IPs (`:416`), profile entries (`parse_entry` → `:159`). No sibling repairs a bad value in place.
- **Error vocabulary**: exactly two prefixes, `ERROR:` and `WARNING:`, both on **stderr** for preconditions and composition; the verification block at the end is the one family on **stdout**, with the fixed stems `ERROR: Firewall verification failed - <what>` and `Firewall verification passed - <what>`. Multi-line errors indent continuations by 7 spaces (`fail_closed_on_abort`, `:288-296`).
- **Capability probes**: test the capability, not the binary, and suppress the probe's own output — `command -v ip6tables >/dev/null 2>&1 && ip6tables -w 5 -S OUTPUT >/dev/null 2>&1`, `ipset destroy … 2>/dev/null || true`, `id -u dnsmasq 2>/dev/null || true`, `grep -q … 2>/dev/null`.
- **`/run` layout**: `/run/cc-sni-proxy/{allowlist,proxy.pid,proxy.log}` (dir-per-subsystem, leaf names repeat the daemon), `/run/cc-dnsmasq.pid` (flat, kind-suffixed), and now `/run/cc-firewall/lock` (dir-per-subsystem, bare leaf).
- **Generated boundary files carry an explicit mode**: `chmod 0644 "$DNSMASQ_CONF"`, `chmod 0444 "$SNI_ALLOWLIST"`, and the image-side `chmod 0555`/`0444` on `/usr/local/share/cc-egress`.
- **Phase discipline**: every "is the machinery there" check lives in phase A, above the `PHASE B — REBUILD` banner, with a `# --- <thing> preconditions (see the <X> block in phase B) ---` header and a comment saying why the check is early.
- **Inspection hooks**: `--print-domains`, `--print-resolvers`, `--print-entries`, `--print-dnsmasq-conf` — each an early `if [ "${1:-}" = … ]; then … exit 0; fi` before the trap, documented in `docs/decisions/log.md` as the public inspection surface.
- **Profile grammar as consumer-facing spec**: `egress/base.txt`'s header block is where a profile author reads the format; `init-firewall.sh`'s file header restates it.
- **Python side** (`cc-sni-proxy.py`): module constants `UPPER_SNAKE` with a `_TIMEOUT` suffix for durations (`HELLO_TIMEOUT`, `CONNECT_TIMEOUT`); log lines are `<VERB> <k>=<v> …` with three verbs, `REJECT` / `FAIL` / `ALLOW`; docstrings describe the function's own job.

---

### Name-Pattern Audit

Every new public name in the range. "Public" here = script-level constant, env seam, on-disk path, or operator-visible message string, since those are what the bats suite, the profile authors, and the postStart log consume.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `HOST_LABEL` | shell constant | `HOST_IP`, `GITHUB_DNS_ZONES`, `EGRESS_DIR` | `init-firewall.sh:874`, `:174`, `:40` | **Inconsistent** — `HOST_` already means "the Docker host" in this script (`HOST_IP` = bridge gateway); this is "hostname" (finding 1) |
| `HOST_RE` | shell constant | `HOST_LABEL` (same commit), `GITHUB_DNS_ZONES` | `init-firewall.sh:129`, `:174` | **Inconsistent** — same prefix collision, plus a `_RE` type suffix on one of the two regex constants and not the other (finding 1). First `_RE`-suffixed name in the tree — `rg '_RE=|_REGEX|_PATTERN'` over `devcontainer-config/` returns only this line |
| `IP6_FILTER` | shell constant (0/1 flag) | `FIREWALL_COMPLETE` (`0`/`1`), local `open` (`0`/`1`), `DNSMASQ_UID` | `init-firewall.sh:267`/`:1087`, `:288`, `:446` | **Minor deviation** — the one existing 0/1 flag is predicate-shaped (`FIREWALL_COMPLETE`); this one is a bare noun that reads as "the filter" (finding 10) |
| `FIREWALL_LOCK_WAIT` / `CC_FIREWALL_LOCK_WAIT` | shell constant + env seam | `SNI_PORT`/`CC_SNI_PORT`, `FIREWALL_LOCK`/`CC_FIREWALL_LOCK`; duration siblings `HELLO_TIMEOUT`, `CONNECT_TIMEOUT` | `init-firewall.sh:487`, `:536`; `cc-sni-proxy.py:46-47` | **Consistent** — `<SUBSYSTEM>_<THING>` shape holds, and `_WAIT` matches `flock`'s own `-w`/`--wait` vocabulary. The Python `_TIMEOUT` divergence is across a language boundary and the tool's word wins. Its *validation* posture is finding 4, not its name |
| `/run/cc-firewall/` (dir 0700) + `lock` (0600) | on-disk path | `/run/cc-sni-proxy/{allowlist,proxy.pid,proxy.log}`, `/run/cc-dnsmasq.pid` | `init-firewall.sh:483-486`, `:439` | **Consistent** — joins the dir-per-subsystem majority and closes N8's mode half; leaves `/run/cc-dnsmasq.pid` as the sole flat file. Leaf naming differs from the SNI dir (bare `lock` vs `proxy.pid`), which is the better of the two |
| `"ERROR: this container has a global IPv6 address but no usable ip6tables filter table — …"` (3 lines) | stderr error | `fail_closed_on_abort`'s multi-line block; `ERROR: no distinct unprivileged 'ccproxy' user (got …)` | `init-firewall.sh:288-296`, `:496` | **Consistent** — right prefix, right stream, 7-space continuation indent, and a "what to do" third line matching the trap's `Verify with …` / `recreate it from the host:` shape |
| `"WARNING: no usable ip6tables filter table and no global IPv6 address — IPv6 left unconfigured"` | stderr warning | `WARNING: no parseable IPv4 nameserver … — …`, `WARNING: Failed to resolve $domain - skipping (stays blocked)` | `init-firewall.sh` resolver-scoping branch, `:411` | **Consistent prefix/stream** — but it is now the only `WARNING:` describing a state the script has just *proven* benign, so the em-dash clause carries no consequence (finding 9) |
| `"ERROR: could not take $FIREWALL_LOCK within ${FIREWALL_LOCK_WAIT}s — another init-firewall.sh rebuild is still running"` | stderr error | `ERROR: composed egress allowlist is empty`; the message it replaces | `init-firewall.sh:319`, r2 N4 | **Consistent** — states the observation, then the likely cause, in the order the r2 recommendation asked for |
| `"ERROR: $d must be root-owned and not group/world-writable (the egress profiles live under it)"` | stderr error | `ERROR: SNI proxy $SNI_PROXY_BIN is missing or not executable (Dockerfile installs it)` | `init-firewall.sh:489` | **Consistent** — `ERROR: <subject> <problem> (<why it matters>)` with the same parenthetical-context convention |
| `"ERROR: Firewall verification failed - the tcp/443 redirect to the SNI proxy is not installed"` | stdout verification failure | `… - a non-allowlisted SNI reached an allowlisted address`, `… - unable to reach https://api.github.com` | `init-firewall.sh:1065`, `:1039` | **Consistent** — same stem, same stream, no `(see …)` pointer because the evidence is a rule not a log |
| `"ERROR: Firewall verification failed - the SNI proxy did not log a redirected refusal for not-allowlisted.invalid (see $SNI_LOG)"` | stdout verification failure | the message it replaces (`did not log a refusal … (is the 443 redirect in place? see $SNI_LOG)`) | `init-firewall.sh:1079` | **Consistent — improved** — the speculative "(is the 443 redirect in place?)" clause is gone now that the redirect is asserted separately, which is the N4 lesson applied a second time |
| `"ERROR: Firewall verification failed - no api.anthropic.com address recorded for the SNI probe"` | stdout verification failure | same family | `init-firewall.sh:1057` | **Consistent** |
| `log()` docstring `CONTRACT:` block | Python docstring | `Allowlist` (`"…`name` lines match exactly; `.zone` lines…"`), `normalise_name`, `read_client_hello` | `cc-sni-proxy.py:126-127`, `:59`, `:106-107` | **Inconsistent placement** — every other docstring describes its own function; this one pins a cross-file grep contract that only one of `log()`'s three call sites satisfies (finding 5) |
| `"FAIL sni=… (name unresolvable, or address not admitted by the ipset)"` | Python log line | `REJECT sni=… : not in allowlist`, `ALLOW sni=… -> …` | `cc-sni-proxy.py:186`, `:197` | **Consistent** — same `<VERB> k=v` shape; the parenthetical drops the r2-era question mark for a statement, though the branch has a third cause (finding 5) |
| `HOST_RE` ≥2-label grammar as a *profile-file* contract | consumer-facing spec | `egress/base.txt` "Format:" header block; `guides/cc-isolated-usage.md` | `devcontainer-config/egress/base.txt:13-20`, `guides/cc-isolated-usage.md:46-85` | **Undocumented** — the tightened grammar is stated only in a source comment and one bats test name (finding 3) |

No new routes, exported functions, CLI flags, or config fields were introduced; `Dockerfile` adds no new build args or ENV.

---

### Findings

#### 1. `HOST_LABEL` / `HOST_RE` claim a prefix that already means something else in this script

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:129-130`; collides with `:874`
**Move:** 2 (naming)
**Confidence:** High
**Evidence:**
> `HOST_LABEL='[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?'`
> `HOST_RE="^${HOST_LABEL}(\.${HOST_LABEL})+\$"`

> `HOST_IP=$(ip route | grep default | cut -d" " -f3)`

**Legibility-target:** for-author

Precedent: `HOST_<THING>` meaning *the Docker host machine* used in `devcontainer-config/init-firewall.sh:874` (`HOST_IP`, the bridge gateway address, echoed as "Bridge gateway detected as: $HOST_IP"); the `<SUBSYSTEM>_<THING>` family generally in `init-firewall.sh:40` (`EGRESS_DIR`), `:174` (`GITHUB_DNS_ZONES`), `:483-486` (`SNI_*`).

`rg '^HOST_' init-firewall.sh` now returns three names in two unrelated senses: two about *hostname syntax* and one about *the host machine*. That is exactly the grep a future editor runs before touching either. The second half of the same issue: both new constants are regex fragments, but only one carries the `_RE` type suffix — `HOST_LABEL` is no less a regex than `HOST_RE`, so the suffix reads as a distinction where none exists. This is residue of an otherwise clean N1 fix (the deduplication itself is right and is the strongest available form). Failure mode: *a prefix overloaded across two domains in one 1087-line file*.

**Recommendation:** `HOSTNAME_LABEL_RE` and `HOSTNAME_RE` (or `ENTRY_HOST_RE`), suffixing both or neither. Three call sites: `init-firewall.sh:129-130`, `:141`, `:220`. No test pins the constant names — `rg 'HOST_RE|HOST_LABEL' test/` returns nothing — so the rename is free.

---

#### 2. "One hostname grammar … so the two consumers cannot disagree" is scoped to the shell; a third label grammar lives in the proxy

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:124-130`; `devcontainer-config/cc-sni-proxy.py:48`, `:65`
**Move:** 7 (asymmetry) / 3 (consumer contract)
**Confidence:** High
**Evidence:**
> `# One hostname grammar, shared by parse_entry (ipset/SNI side) and`
> `# compose_dnsmasq_conf (resolver side) so the two consumers cannot disagree. Two`
> `# or more labels are REQUIRED: a single label is either a TLD — which as a dnsmasq`
> `# `server=/com/` line would forward every .com name upstream and re-open the`
> `# tunnel the resolver exists to close — or a bare host that no profile needs.`

> `LABEL = re.compile(r"^[a-z0-9]([a-z0-9-]*[a-z0-9])?$")`
> `    if not name or len(name) > 253 or not all(LABEL.match(l) for l in name.split(".")):`
> `        raise HelloError("server_name is not a valid hostname")`

**Legibility-target:** for-author

The proxy's `LABEL` differs from `HOST_RE` on three axes: lowercase-only (safe — `Allowlist.load` lower-cases at `cc-sni-proxy.py:137`, so no admitted name can mismatch), **single-label accepted**, and a 253-byte total cap that `HOST_RE` has no analogue for. The divergence is *correct*: `normalise_name` validates untrusted wire bytes where a client may legitimately send `localhost`, while `HOST_RE` validates root-owned profile config where a single label is a TLD-zone hazard. The problem is only that the comment asserts a uniqueness one file wider than it holds, in a file whose reviewers have now twice found a duplicated grammar (pass-1 F3, r2 N1). A reader who greps for the "one grammar" and finds `cc-sni-proxy.py:48` has no way to tell whether it is the bug the comment says cannot exist. This is also where the loop-pass fact-check's unclaimed Escalation 4 lands: neither grammar enforces the 63-octet per-label limit, and only the Python side caps total length — unclaimed on both sides, so not a drift, but the asymmetry is now visible in one sentence's worth of comment. Failure mode: *a uniqueness claim whose scope is narrower than its wording*.

**Recommendation:** One clause on `:124-125`: "…shared by the two *profile-grammar* consumers. The proxy's wire-side `normalise_name` (`cc-sni-proxy.py:65`) is deliberately separate and looser — it validates client-supplied SNI, not profile config." Neither regex needs to change.

---

#### 3. The grammar tightened for profile authors, and the profile-author-facing spec does not say so

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:126-130`; spec at `devcontainer-config/egress/base.txt:13-20`, `guides/cc-isolated-usage.md:46-85`
**Move:** 3 (consumer contract) / 6 (versioning)
**Confidence:** High
**Evidence:**
> `# Format: one entry per line, `domain[:port[,port...]]`. Blank lines and #-comments`
> `# ignored. The optional suffix is a comma-separated list of TCP ports; when absent the`
> `# entry is admitted on tcp 443 only. … init-firewall.sh rejects a line that does not`
> `# parse, so a typo fails the rebuild loudly rather than silently changing what is admitted.`

**Legibility-target:** for-orchestrator-synthesis

This is a **narrowing** of a consumer contract: entries that parsed at `2839e59` now abort the run. `route: code-fact-check` — **Verified:** I ran `--print-entries` at HEAD once per shipped profile (`base` alone, then each of `android`, `dotnet`, `lean`, `llm`, `python`, `rust`, `vscode` via `CC_EGRESS_PROFILE_FILE`); all eight exit 0 with no `ERROR`/`WARNING` line, so no in-repo profile breaks. I also confirmed by inspection that no entry in `devcontainer-config/egress/*.txt` lacks a dot. **Not verified:** per-project profiles under `projects/*.profile` on any host — those are host-side registrations outside this repo, and `enforcement_files()` hashes them precisely because they are boundary config that this repo cannot see. A host with a registered `host.docker.internal`-style single-label entry (say a LAN hostname) would now fail the rebuild, and the only place that requirement is written down is a source comment and the name of a bats test. Note that the r2 pass praised the *opposite* behaviour as F3's fix ("a single-label entry gets a resolver line as well as an ipset member"), so the contract has flipped inside one review loop — one more reason to state it where authors read it. Failure mode: *a contract narrowed in code and not in the spec its authors read*.

**Recommendation:** One sentence in `egress/base.txt`'s Format block — "A domain needs at least two labels (`example.com`, not `example`): a single label would become a whole-TLD resolver zone." Mirror it in `guides/cc-isolated-usage.md`'s egress-profiles section and in `init-firewall.sh`'s file header, which restates the format at `:16-18`.

---

#### 4. `FIREWALL_LOCK_WAIT` silently repairs a bad value; every sibling numeric validation aborts

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:537-538`
**Move:** 4 (error consistency) / 8 (nullability)
**Confidence:** High
**Evidence:**
> `FIREWALL_LOCK_WAIT="${CC_FIREWALL_LOCK_WAIT:-120}"`
> `[[ "$FIREWALL_LOCK_WAIT" =~ ^[0-9]+$ ]] || FIREWALL_LOCK_WAIT=120`

> `if [[ ! "$DNSMASQ_UID" =~ ^[0-9]+$ ]] || [ "$DNSMASQ_UID" -eq 0 ]; then`
> `    echo "ERROR: no unprivileged 'dnsmasq' user (got '${DNSMASQ_UID:-none}')" >&2`

**Legibility-target:** for-author

The guard is the right *fix* for N4 — a non-numeric wait can no longer produce `flock: invalid timeout value` followed by a confident wrong diagnosis and a fail-closed DROP. But it picks a third validation posture for this script: `DNSMASQ_UID` (`:447`), `CCPROXY_UID` (`:495`), GitHub CIDRs (`:378`), resolved IPs (`:416`) and `parse_entry` all **abort naming the observed value**; `SNI_PORT` (`:487`) is **unvalidated**; and this one **substitutes a default without a word**. A bats author who typos `CC_FIREWALL_LOCK_WAIT=1s` gets a silent 120-second wait — the exact hang the seam exists to avoid — with nothing in the output to explain it. `test/init-firewall-rules.bats:924` relies on `CC_FIREWALL_LOCK_WAIT=1` taking effect, so a typo there degrades that test into a two-minute stall rather than a failure. Failure mode: *a repaired input that never announces the repair*.

**Recommendation:** Match the family — `echo "WARNING: CC_FIREWALL_LOCK_WAIT='$CC_FIREWALL_LOCK_WAIT' is not a number, using 120" >&2` before the fallback, or abort like the two uid checks. One line either way.

---

#### 5. The log-format contract sits on `log()`, not on the line that emits it, and only one direction of the reference exists

**Severity:** Minor
**Location:** `devcontainer-config/cc-sni-proxy.py:157-160`; the contract's real site is `:186`; the consumer is `devcontainer-config/init-firewall.sh:1078`
**Move:** 3 (consumer contract) / 7 (asymmetry)
**Confidence:** High
**Evidence:**
> `def log(msg):`
> `    """One line per decision. CONTRACT: init-firewall.sh's verification probe greps`
> `    this log for `REJECT sni=<name> orig_dst=<ip>:<port>` — keep that field order and`
> `    spelling stable, or change the probe in the same commit."""`
> `    print(time.strftime("%Y-%m-%dT%H:%M:%S"), msg, flush=True)`

> `            log(f"REJECT orig_dst={orig}: {e}")`
> `            log(f"REJECT sni={sni} orig_dst={orig}: not in allowlist")`
> `            log(f"FAIL sni={sni} orig_dst={orig}: {e} (name unresolvable, or address not admitted by the ipset)")`
> `            log(f"ALLOW sni={sni} -> {ip}:{upstream_port} orig_dst={orig}")`

**Legibility-target:** for-author

Declaring the coupling at all is the right response to rubric A24, and the wording is precise. But `log()` is a two-line `print` wrapper called from four sites emitting three verbs, and the contract binds exactly one of them (`:186`). The editor who breaks the probe is the one editing the f-string at `:186`, and that line carries no marker; the docstring they *would* see if they opened `log()` says "one line per decision" without saying which decisions exist. The reference is also one-directional: `init-firewall.sh:1074-1080`'s comment explains what the `orig_dst` discriminator proves but never names `cc-sni-proxy.py`, where the sibling convention in this script is to name the other file explicitly ("Dockerfile installs it", `:489`; "see the SNI PROXY block in phase B", `:473`). Failure mode: *a contract documented one call frame away from the code that satisfies it*.

**Recommendation:** Move the `CONTRACT:` sentence to a comment directly above `:186`, leave `log()`'s docstring as the format description ("`<ISO ts> <VERB> k=v …`; verbs are REJECT / FAIL / ALLOW"), and add "(see `cc-sni-proxy.py`'s REJECT contract)" to the shell-side comment at `:1074-1077`. While there: the `FAIL` parenthetical names two causes for a branch that also catches `asyncio.TimeoutError` on an admitted-but-slow host — "(name unresolvable, address not admitted by the ipset, or the connect timed out)" closes the same gap N4 closed for the lock.

---

#### 6. `CC_EGRESS_DIR` now doubles as an off-switch for a security assertion, and its declaration site says nothing

**Severity:** Inconsistent
**Location:** `devcontainer-config/init-firewall.sh:302-312`; declaration at `:40`
**Move:** 3 (consumer contract) / 7 (asymmetry)
**Confidence:** High
**Evidence:**
> `# Asserted on the image default only; CC_EGRESS_DIR is a test override`
> `# that `node` cannot pass through sudo env_reset.`
> `if [ -z "${CC_EGRESS_DIR:-}" ]; then`
> `    for d in "$EGRESS_DIR" "$(dirname "$EGRESS_DIR")"; do`
> `        if [ "$(stat -c '%u' "$d")" != "0" ] || [ -n "$(find "$d" -maxdepth 0 -perm /022)" ]; then`

> `EGRESS_DIR="${CC_EGRESS_DIR:-/usr/local/share/cc-egress}"`

**Legibility-target:** for-author

Eight of the nine test seams mean one thing: "read this path instead". `CC_EGRESS_DIR` now means "read this path instead **and skip the root-ownership check**" — the only seam in the script that gates a check rather than redirecting one, and it gates the check that closed the pass-2 **Critical** (rubric R7). Two consequences. First, `:40` — the line a reader or test author actually lands on — carries no annotation at all, not even the "unit tests only" one that N3 just added to the lock seam and that `:428-430` cites as existing "exactly as for `CC_EGRESS_DIR` above" (there is no such note above; `:32-37` annotates `CC_FIREWALL_PATH`). Second, because every bats test sets `CC_EGRESS_DIR` (`test/init-firewall-rules.bats:33`, and per-test at `:332`, `:358`, `:764`, `:845`, `:860`), the assertion is never executed by the suite: `rg 'must be root-owned' test/` returns nothing. The Critical fix is untested. Failure mode: *a test seam that silently widens beyond redirection*.

**Recommendation:** Annotate `:40-41` in the family wording, and say the second meaning out loud: "`CC_EGRESS_DIR`/`CC_EGRESS_PROFILE_FILE` are for the unit tests only (sudo `env_reset` strips them); setting `CC_EGRESS_DIR` also skips the root-ownership assertion below, because a test fixture lives under `$BATS_TMPDIR`." Then add a bats case that invokes the assertion — e.g. a second seam `CC_EGRESS_OWNER_CHECK=1` forced on with a node-owned fixture dir, asserting the `must be root-owned` message and that no `iptables -F` was issued — so the Critical fix has a regression test like A17–A21 do.

---

#### 7. `--print-dnsmasq-conf` still diverges from `--print-entries`, and the new test now encodes the divergence by omission

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:156-161` vs `:232-235`; consumer `test/init-firewall-rules.bats:853-865`
**Move:** 4 (error consistency) / 3 (consumer contract)
**Confidence:** High
**Evidence:**
> `  CC_EGRESS_DIR="$dir" run bash "$FW"`
> `  [ "$status" -ne 0 ]`
> `  [[ "$output" == *"malformed egress entry"* ]]`
> `  printf 'nameserver 127.0.0.11\n' > "$TEST_TMPDIR/rc"`
> `  CC_EGRESS_DIR="$dir" run bash "$FW" --print-dnsmasq-conf "$TEST_TMPDIR/rc"`
> `  [[ "$output" != *"server=/com/"* ]]`

**Legibility-target:** for-author

This is r2's N9 re-raised with new evidence, not a new problem. Two things changed. First, the tightening moved every single-label name into the divergence, so the class of inputs on which the two hooks disagree grew; re-executed at HEAD on a `localhost:11434` fixture, `--print-entries` exits 1 with `ERROR: malformed egress entry`, `--print-dnsmasq-conf` exits **0** with a `WARNING:` and a config the production path can never reach (production aborts at `:317` long before `compose_dnsmasq_conf` runs). Second, the rewritten test at `:853` **dropped the `[ "$status" -eq 0 ]` assertion** its predecessor carried — reasonable, since asserting either value would pin a behaviour the author does not want to promise, but the effect is that the hook family's one documented public surface now has an exit status that no test constrains in either direction. Separately, the warning's own text is inaccurate for the input that now dominates it: `localhost` *is* a hostname; it is rejected for having one label. That is the N4 shape again — a message naming a cause the branch does not establish. Failure mode: *sibling hooks, divergent strictness, and a test that documents the divergence by declining to assert*.

**Recommendation:** Run the same `parse_entry` pre-flight loop in `--print-dnsmasq-conf` that `--print-entries` runs, then restore `[ "$status" -ne 0 ]` to the test; and reword `:222` to "WARNING: not a valid allowlist hostname (needs two or more labels), omitting from resolver allowlist (stays unresolvable): $d". If the warn-and-continue behaviour is wanted deliberately, say so in the hook's comment and assert the status anyway.

---

#### 8. The ownership comment states an invariant two levels wider than the loop checks

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:302-312`
**Move:** 3 (consumer contract)
**Confidence:** High
**Evidence:**
> `# The profile directory must be root-owned all the way up: directory WRITE`
> `# permission on a parent lets its owner rename or unlink a child regardless of the`
> `# child's own ownership, …`
> `    for d in "$EGRESS_DIR" "$(dirname "$EGRESS_DIR")"; do`

**Legibility-target:** for-author

"All the way up" from `/usr/local/share/cc-egress` is four levels; the loop checks two. In the shipped image the remaining two (`/usr/local`, `/`) are root-owned by the base image and nothing in the Dockerfile touches them, so the check is sufficient in practice — but the sentence states the *requirement* and the code enforces a *subset*, which is the class of gap that produced R7 in the first place (a comment describing a stronger ownership posture than the build actually established: `Dockerfile:109-110`, fixed in this same range). The script's own convention is to say what it checks: `:492` ("Numeric, non-zero, and distinct from dnsmasq") enumerates exactly the three conditions the next line tests. Failure mode: *stated invariant broader than the assertion*.

**Recommendation:** Either walk to `/` (a three-line `while [ "$d" != "/" ]` loop), or scope the sentence: "must be root-owned at both the profile directory and its parent — the two levels this image creates; `/usr/local` and `/` are root-owned by the base image and untouched by the Dockerfile."

---

#### 9. The IPv6 `WARNING:` now labels a state the script has proven safe

**Severity:** Informational
**Location:** `devcontainer-config/init-firewall.sh:594`; paired with `:509-518` and the still-open N7 at `:592`
**Move:** 4 (error consistency)
**Confidence:** High
**Evidence:**
> `    echo "IPv6: default-deny installed (loopback and established flows only)"`
> `else`
> `    echo "WARNING: no usable ip6tables filter table and no global IPv6 address — IPv6 left unconfigured" >&2`

**Legibility-target:** for-author

Moving the posture decision into phase A is the right restructuring and the message correctly stops claiming a bypass exists. What is left is a prefix question the phase move created: the dangerous case now aborts at `:513-517`, so this branch fires only when the script has *established* there is nothing to filter. Every other `WARNING:` in the file reports a real degradation with a consequence clause — `WARNING: Failed to resolve $domain - skipping (stays blocked)`, `WARNING: not a hostname, omitting … (stays unresolvable)`, `WARNING: no parseable IPv4 nameserver …`. This one's clause ("IPv6 left unconfigured") is a non-event. Anyone pulling actionable lines out of a postStart log with `grep -E '^(ERROR|WARNING):'` gets a line with nothing to do — which is the mirror image of N7 two lines above, where a status line wears an alert prefix. The two sit in the same `if/else`, so they are worth fixing together. Failure mode: *alert vocabulary applied to a proven-benign outcome*.

**Recommendation:** Fix the pair: `echo "Installing IPv6 default-deny (loopback and established flows only)..."` on stdout (N7's recommendation) and `echo "IPv6 not configured: no filter table and no global IPv6 address (nothing to filter)"` on stdout for the else branch — reserving `WARNING:`/stderr for degradations that leave something exposed.

---

#### 10. `IP6_FILTER` is a 0/1 flag with a noun's name

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:509`, `:511`, `:583`
**Move:** 2 (naming)
**Confidence:** Medium
**Evidence:**
> `IP6_FILTER=0`
> `if command -v ip6tables >/dev/null 2>&1 && ip6tables -w 5 -S OUTPUT >/dev/null 2>&1; then`
> `    IP6_FILTER=1`

> `if [ "$IP6_FILTER" = "1" ]; then`

**Legibility-target:** for-author

Precedent: predicate-shaped names for 0/1 flags used in `devcontainer-config/init-firewall.sh:267` and `:1087` (`FIREWALL_COMPLETE=0` / `=1`, tested as `[ "${FIREWALL_COMPLETE:-0}" != "1" ]` at `:270`) and `:288` (local `open=1`). Every other `<SUBSYSTEM>_<NOUN>` constant in the script holds a *value* of that noun — `SNI_PORT` is a port, `DNSMASQ_CONF` is a path, `GH_CIDRS` are CIDRs — so `IP6_FILTER` reads at the `:583` test site as "the IPv6 filter", and `[ "$IP6_FILTER" = "1" ]` reads as comparing a filter to a string. The 74-line gap between the phase-A assignment and the phase-B test is exactly the distance over which the name has to carry its own meaning; the comment at `:580-582` does that work today, but the name works against it. Confidence is Medium rather than High because the codebase has only one prior 0/1 flag, so the pattern rests on a single precedent. Failure mode: *a boolean named as the thing it is a fact about*.

**Recommendation:** `IP6_FILTER_USABLE` (matching `FIREWALL_COMPLETE`'s adjective shape) with the same `= "1"` comparison. Three sites, no test pins the name (`rg 'IP6_FILTER' test/` → no hits; the suite drives the branch through the `NO_IP6_TABLE` / `HAS_GLOBAL_V6` stub variables instead).

---

#### 11. The new `iptables -t nat -C` probe is the only capability check whose stderr is not suppressed

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:1074-1077`
**Move:** 4 (error consistency)
**Confidence:** Medium
**Evidence:**
> `if ! iptables -t nat -C OUTPUT -p tcp --dport 443 -j CC_SNI; then`
> `    echo "ERROR: Firewall verification failed - the tcp/443 redirect to the SNI proxy is not installed"`

**Legibility-target:** for-author

Precedent for the convention is uniform: every other probe in this script swallows the tool's own output before reporting in the script's vocabulary — `command -v ip6tables >/dev/null 2>&1 && ip6tables -w 5 -S OUTPUT >/dev/null 2>&1` (`:510`), `ipset destroy allowed-domains 2>/dev/null || true` (`:571`), `id -u ccproxy 2>/dev/null || true` (`:494`), `grep -q … "$SNI_LOG" 2>/dev/null` (`:1078`), and all five `curl … >/dev/null 2>&1` probes in this same block. `route: code-fact-check` — **Not verified by execution:** the bats `iptables` stub echoes to `$CMD_LOG` and exits 0 (or 1 under `NO_REDIRECT`) without writing to stderr, so the suite cannot show this; the claim rests on documented `iptables -C` behaviour (it prints `iptables: Bad rule (does a matching rule exist in that chain?)` to stderr when the rule is absent). If that holds, the failure path emits iptables' own diagnostic immediately before the script's `ERROR:` line, which is the one thing this block's five siblings are all careful to prevent — and it lands during the most alarming moment in the run, where a reader is trying to tell a missing rule from a broken probe. Failure mode: *a probe that lets the tool speak over the script's own diagnosis*.

**Recommendation:** `if ! iptables -t nat -C OUTPUT -p tcp --dport 443 -j CC_SNI 2>/dev/null; then`. Verify against a real `iptables` before landing, or fold into the next live-container check already carried in `docs/working/questions.md`.

---

### What Looks Good

Scoped to what I read and ran in this range.

- **N4 was fixed with both halves of the recommendation, not the cheaper one.** The message now states the observation before the likely cause *and* the timeout is validated numeric (`:538`), so the "bad timeout → `flock: invalid timeout value` → confident wrong diagnosis → DROP" chain is closed at the source rather than papered over in prose. The posture the guard chose is finding 4, but the substance is right.
- **The lock's phase placement is the correct seam and is now pinned by a test that asserts the seam, not the symptom.** `test/init-firewall-rules.bats:920-929` holds the lock from outside, then asserts `curl … api.github.com/meta` appears in the command log (phase A ran) and `iptables -F` does not (phase B did not). That is a test of the *boundary*, which is the property rubric A21 actually bought.
- **N8's mode half is closed with a test that reads the filesystem rather than the command log.** `:933-938` asserts `stat -c '%a'` is `700` on the directory and `600` on the file. Combined with the move into `/run/cc-firewall/`, the lock now matches the dominant `/run` convention instead of adding a fourth one — the layout question in A9 shrank from a three-way split to "should `/run/cc-dnsmasq.pid` move too?".
- **The negative probe's hardening closes the loop-pass fact-check's Escalation 2 in the same commit that raised it.** Escalation 2 observed that the bats `iptables` stub returned 0 for every invocation including `-C`, so the redirect assertion proved only that the command was *issued*. `1434fc9` adds `NO_REDIRECT` to the stub (`test/init-firewall-rules.bats:51-52`) and a test asserting the run fails with "redirect to the SNI proxy is not installed", plus `FORGED_SNI_LOG` (`:132-134`) proving a refusal logged with `orig_dst=127.0.0.1:3443` does *not* satisfy the probe. `route: code-fact-check` — **Verified:** I ran the suite at HEAD; 59/59 pass, including all five new cases.
- **The `ANTHROPIC_PROBE_IP` guard is safe under `set -u` and its comment is honest about being belt-and-braces.** The variable is initialised to `""` at `:390` before the resolution loop, so the `[ -z "$ANTHROPIC_PROBE_IP" ]` test at `:1056` cannot trip the `set -u` trap — the stated error is genuinely reachable rather than shadowed by an "unbound variable" abort. The comment says plainly that the condition "cannot be empty" and that the check exists to state the guarantee, which is the right framing for an assertion rather than a handler.
- **The tightened grammar is a narrowing with a named threat, a regression test, and no in-repo casualties.** `route: code-fact-check` — **Verified:** `--print-entries` exits 0 on all eight shipped profile combinations at HEAD (see finding 3); `test/init-firewall-rules.bats:853` pins the `com:443` case with a `REGRESSION:` comment naming the `server=/com/` hazard. The comment at `:126-128` explains *why* two labels are required rather than asserting the rule, which is the pattern the rest of this file follows.
- **The Dockerfile's stale ownership parenthetical was fixed in the same range it was reported.** The fact-check's single Stale verdict (`Dockerfile:109-110`, "chowned to node above for npm") is corrected to "(as is `/usr/local/share` — only npm-global beneath it is node's)". `route: code-fact-check` — **Verified:** `rg '/usr/local/share' devcontainer-config/` shows node-ownership scoped to `npm-global` (`:65-66`) and `NPM_CONFIG_PREFIX` (`:359`) as the only consumer, with `cc-egress` explicitly `chown -R root:root` at `:419`.
- **Phase A now holds every precondition, with no exceptions left.** The IPv6 posture joined dnsmasq, the SNI proxy, and the uid checks above the `PHASE B — REBUILD` banner, under the same `# --- <thing> preconditions (see the <X> block in phase B) ---` header the other two use, with `IP6_FILTER` carrying the decision forward and `:580-582` explaining what each value means at the use site. The phase-discipline convention is now uniform rather than nearly-uniform.

---

### Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 6 | `CC_EGRESS_DIR` doubles as an off-switch for the ownership assertion; unannotated at its declaration, and the assertion is never exercised by the suite | Inconsistent | `init-firewall.sh:302-312`, `:40` | High |
| 1 | `HOST_LABEL`/`HOST_RE` collide with `HOST_IP`'s sense of "host"; `_RE` suffix on one of two regex constants | Minor | `init-firewall.sh:129-130`, `:874` | High |
| 2 | "One hostname grammar … cannot disagree" is scoped to the shell; `cc-sni-proxy.py:48` holds a third, deliberately different label grammar | Minor | `init-firewall.sh:124-130`, `cc-sni-proxy.py:48`,`:65` | High |
| 3 | Grammar narrowed for profile authors; `egress/base.txt` and the usage guide never state the ≥2-label rule | Minor | `egress/base.txt:13-20`, `init-firewall.sh:126-130` | High |
| 4 | `FIREWALL_LOCK_WAIT` silently repairs a bad value where every sibling numeric check aborts | Minor | `init-firewall.sh:537-538` | High |
| 5 | Log-format contract documented on `log()` rather than the emitting line; no reciprocal pointer from the shell probe | Minor | `cc-sni-proxy.py:157-160`, `:186`; `init-firewall.sh:1074-1080` | High |
| 7 | N9 re-raised: hook strictness still diverges, over a larger input class, and the new test drops the status assertion | Minor | `init-firewall.sh:156-161` vs `:232-235`; `test/init-firewall-rules.bats:853-865` | High |
| 8 | Ownership comment claims "all the way up"; the loop checks two levels | Minor | `init-firewall.sh:302-312` | High |
| 10 | `IP6_FILTER` is a 0/1 flag named as a noun, tested 74 lines from its assignment | Minor | `init-firewall.sh:509`, `:583` | Medium |
| 11 | The new `iptables -t nat -C` probe is the only capability check not suppressing the tool's own stderr | Minor | `init-firewall.sh:1074-1077` | Medium |
| 9 | The IPv6 `WARNING:` now labels a state phase A has proven benign; pairs with the still-open N7 | Informational | `init-firewall.sh:592-594` | High |

**Prior-finding roll-up:** N1, N3, N4 **Fixed**; N5, N8 **Partly fixed**; N2 **Open (accepted, rubric A25)**; N6, N7, N9 **Open**; N10 **Open — targeted but not landed** (`init-firewall.sh:782-784` is unchanged in the range).

---

### Overall Assessment

**No Breaking findings, and none of the eleven items above is a regression of anything this loop has already fixed.** Three of the four targeted r2 items landed cleanly — N1's deduplication is the strong form (one constant, two consumers, comment explaining the threat rather than asserting agreement), N3's annotation copies the sibling wording verbatim, and N4 was fixed with both halves rather than the cheaper prose-only one. N10 is the exception: it was named as targeted and the code at `:782-784` is byte-identical to what r2 quoted, so it should be re-queued rather than treated as closed. The one Inconsistent item, finding 6, is worth the author's attention out of proportion to its severity label: `CC_EGRESS_DIR` acquiring a second meaning is a naming/contract issue, but the consequence — the pass-2 **Critical** fix has no regression test because every bats case sets the seam that disables it — is the kind of gap the two-consecutive-clean rule exists to catch, and it sits alongside A17–A21, all of which *do* have one.

The rest is residue of good fixes rather than new debt: three naming items (1, 10, and the `_RE` half of 1) that are free to change because no test pins the names, three documentation-placement items (2, 5, 8) where the code is right and the sentence around it over- or under-claims, and one spec-drift item (3) that is the only finding with a consumer outside this repo — a host with a single-label entry in a per-project `.profile` now fails the rebuild, and nothing an author reads says why. Finding 7 is r2's N9 with a larger blast radius and a test that now documents the divergence by declining to assert it; that pairing (widen the input class, drop the assertion) is the one place in this wave where a fix made an open item slightly harder to close later. Consumer impact overall is small and local: the postStart log gains one alert-prefixed non-event (9) and possibly one duplicated iptables diagnostic (11); the profile grammar is the only contract that actually narrowed, and all eight shipped profiles were re-executed clean. Everything here is fixable in place — no finding suggests the author needs to re-survey conventions, and several show the conventions being applied deliberately (the phase-A move, the `/run` layout convergence, the `ERROR: Firewall verification failed - ` stem held across three new messages).

---

### Goal-Alignment Note

The stated goal is a review-fix loop on locally-reviewed, locally-merged work in a solo repo — no PR, no external consumers, and the pass bar is "two consecutive clean passes", not "zero findings". Read against that bar: this pass produces **no Breaking findings and one Inconsistent**, so it does not by itself block the loop on severity. What it does surface is one item the loop's own bookkeeping would otherwise mis-record — **N10 is marked as targeted but did not land** — and one that bears directly on whether a pass should count as clean: **finding 6 shows the pass-2 Critical fix (root-owned profile tree, rubric R7) is not covered by any test**, because every bats case sets the `CC_EGRESS_DIR` seam that switches the assertion off. A17 through A21 each got a regression test in this wave; R7, the most severe of the set, did not. My suggestion is to treat finding 6 and N10 as this pass's fix list, take findings 3 and 5 if the wave is still open (both are one-sentence edits with real reader value), and log the seven remaining Minor/Informational naming and wording items to rubric row C16 alongside N2/N6/N7/N9 rather than churning `init-firewall.sh` again — the file has now been edited in four consecutive review rounds, and each edit is itself a source of the residue this report keeps finding.
