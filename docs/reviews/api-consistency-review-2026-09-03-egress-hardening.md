# API Consistency Review — egress hardening bd41aef..abbd42d

Commit: abbd42d

**Scope:** `git diff bd41aef..HEAD -- devcontainer-config/` — `init-firewall.sh`, `cc-sni-proxy.py` (new), `Dockerfile`, `devcontainer.json`, `egress/base.txt`, `egress/llm.txt`. Pass 1 of a split review (enforcement files); `test/`, `guides/`, `docs/` are a later pass and were read here only as consumers/baselines.
**Date:** 2026-09-03
**Based on:** docs/reviews/code-fact-check-report.md (k=3 merged)

---

## Baseline Conventions

Surveyed before reviewing:

1. **`init-firewall.sh` at `bd41aef`** (`git show bd41aef:devcontainer-config/init-firewall.sh`) — two inspection hooks, `--print-domains` (:56) and `--print-resolvers` (:88), both matched as `[ "${1:-}" = "--flag" ]`, both exiting before the fail-closed trap is installed. Two env overrides, `CC_EGRESS_DIR` and `CC_EGRESS_PROFILE_FILE` (:23-24), shaped `CC_<SUBSYSTEM>_<THING>` and justified in-comment as "for the unit tests only; sudo's `env_reset` strips them". Errors are `ERROR: <msg>` / `WARNING: <msg>` on stderr, exit 1. The ipset was `hash:net` matched `dst` (:344, :393).
2. **`cc-isolated.sh`** — the launcher. It invokes `sudo /usr/local/bin/init-firewall.sh` and reads only the **exit status** (:420); it greps nothing out of the script's stdout, so echo-line wording is not a machine contract. `enforcement_files()` (:50-65) enumerates the files whose sha256 gates a build; `probe_boundary()` (:231-323) asserts the in-container boundary and prints a single summary sentence naming what it verified.
3. **`install.sh`** — the host-side installer. `PAYLOAD` (:25) is the explicit list of files copied from the repo into `~/.config/claude-devcontainer/`, which `devcontainer.json` (:25-26) makes the Docker build **context**. Anything the Dockerfile `COPY`s must be in `PAYLOAD`.
4. **Existing egress profiles** (`egress/*.txt`) — a comment block explaining *why* each host is granted, then bare one-per-line entries; full-line `#` comments only.
5. **`devcontainer.json` `containerEnv`** — literals for tool settings, `"${localEnv:NAME}"` for opt-in host passthrough (`CC_PROJECT_ID`, `OPENROUTER_API_KEY`), each passthrough carrying a comment stating the default-unset stance and the credential risk.

Two conventions the diff mostly honours and that are worth stating up front: **every inspection hook is side-effect-free and exits before the trap**, and **every env seam is a test seam that `sudo env_reset` neutralises in production**. The new hooks and `CC_*` vars both hold to these.

---

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--print-entries` | hook flag | `--print-domains`, `--print-resolvers` | `init-firewall.sh@bd41aef:56,88` | Consistent — same `--print-<noun>` shape, same early-exit placement |
| `--print-dnsmasq-conf` | hook flag | `--print-domains`, `--print-resolvers` | `init-firewall.sh@bd41aef:56,88` | Consistent — names the artifact it emits rather than a concept, which is accurate here |
| `CC_DNSMASQ_CONF`, `CC_DNSMASQ_PIDFILE` | env override | `CC_EGRESS_DIR`, `CC_EGRESS_PROFILE_FILE` | `init-firewall.sh@bd41aef:23-24` | Consistent |
| `CC_SNI_PROXY_BIN`, `CC_SNI_RUN_DIR`, `CC_SNI_PORT` | env override | `CC_EGRESS_DIR`, `CC_DNSMASQ_CONF` | `init-firewall.sh@bd41aef:23-24`, `init-firewall.sh:395-396` | Naming consistent; **granularity deviates** — dir-scoped where the sibling is file-scoped (F5) |
| `CC_DNS`, `CC_DNS_GUARD`, `CC_SNI`, `CC_SNI_GUARD` | iptables chain | `DOCKER_OUTPUT`, `DOCKER_POSTROUTING` | `init-firewall.sh:488-489` | Establishes a new pattern (`CC_<AREA>[_GUARD]`), internally consistent across both blocks — good |
| `dnsmasq` (system user) | service uid | Debian `dnsmasq` package convention | `Dockerfile:51-52` | Consistent with upstream; matches `user=dnsmasq` in the generated conf |
| `ccproxy` (system user) | service uid | `cc-egress`, `cc-isolated`, `cc-sni-proxy`, `cc-dnsmasq.pid`, `cc-allowlist.conf` | `Dockerfile:384-390`, `init-firewall.sh:395-396` | **Deviates** — every other `cc`-scoped identifier in this system is hyphenated (F9) |
| `--listen`, `--allowlist`, `--daemon`, `--pidfile`, `--user`, `--log` | proxy CLI flag | `--register`, `--profile`, `--bless`, `--probe-only` | `cc-isolated.sh:6-13` | Consistent — long flags, lowercase, noun-shaped |
| `--upstream-port` (SUPPRESS'd) | hidden CLI test seam | env-var test seams (`CC_*`) | `init-firewall.sh@bd41aef:23-24` | Deviates in mechanism (hidden flag vs env var) but the rationale differs; acceptable, noted only |
| `GITHUB_DNS_ZONES` | shell constant | `ALLOWED_DOMAINS`, `GH_CIDRS`, `RESOLVED_MEMBERS` | `init-firewall.sh:274,332,346` | Naming consistent; **the value is duplicated inline elsewhere with different membership** (F2) |
| `allowed-domains` (ipset, type changed) | ipset name | itself at `bd41aef` | `init-firewall.sh@bd41aef:344` | Name retained across a type change — see F14 |
| `/run/cc-sni-proxy/{allowlist,proxy.pid,proxy.log}` | runtime paths | `/run/cc-dnsmasq.pid`, `/etc/dnsmasq.d/cc-allowlist.conf` | `init-firewall.sh:395-396` | **Deviates** — dir-per-daemon vs flat, and generated-config location differs (F5) |
| `DISABLE_ERROR_REPORTING`, `GH_TOKEN` | `containerEnv` key | `OPENROUTER_API_KEY`, `NODE_OPTIONS` | `devcontainer.json:62,92` | Consistent — literal for a tool setting, `${localEnv:}` + risk comment for the passthrough |
| `ALLOW` / `REJECT` / `FAIL` | log verb | `ERROR:` / `WARNING:` (shell), `PROBE FAIL` (launcher) | `init-firewall.sh:249`, `cc-isolated.sh:254` | Partly deviates — a new vocabulary, and one line in it carries no verb (F8) |

---

## Findings

#### `cc-sni-proxy.py` is absent from `install.sh`'s `PAYLOAD`, so the Dockerfile `COPY` has no source in the build context

**Severity:** Breaking
**Location:** `devcontainer-config/install.sh:25`, `devcontainer-config/Dockerfile:389`
**Move:** 3 (consumer contract) / 6 (versioning)
**Confidence:** High
**Evidence:**
> `PAYLOAD=(devcontainer.json Dockerfile init-firewall.sh cc-isolated.sh link-claude-home.sh egress claude-home)`

> `COPY cc-sni-proxy.py /usr/local/bin/`

> `"dockerfile": "${localEnv:CC_CONFIG_DIR}/Dockerfile",`
> `"context": "${localEnv:CC_CONFIG_DIR}",`

**Legibility-target:** for-author

`install.sh` is the only path from the repo to `~/.config/claude-devcontainer/`, and `devcontainer.json:25-26` makes that directory the build context. `PAYLOAD` enumerates every file that gets copied; `cc-sni-proxy.py` is not on it. On a clean host the next `install.sh` + rebuild fails at `COPY cc-sni-proxy.py` with "file not found in build context"; on a host that happens to have a stale copy at `$DEST`, the build silently bakes **the stale proxy**, since nothing re-copies it. The established pattern is that every Dockerfile-`COPY`'d boundary file is a `PAYLOAD` member (`init-firewall.sh`, `link-claude-home.sh`, `egress`). Failure mode in one phrase: *new enforcement binary outside the install payload*.
**Recommendation:** Add `cc-sni-proxy.py` to `PAYLOAD` in `install.sh:25`. This must land before the rebuild-and-re-bless the user is planning.

---

#### The GitHub zone list is duplicated in two grammars with divergent membership; `.githubassets.com` is SNI-allowlisted but never resolvable

**Severity:** Inconsistent
**Location:** `devcontainer-config/init-firewall.sh:154`, `devcontainer-config/init-firewall.sh:864-868`
**Move:** 7 (asymmetry)
**Confidence:** High
**Evidence:**
> `GITHUB_DNS_ZONES="github.com githubusercontent.com"`

> `    # GitHub is admitted by CIDR (phase A) rather than by name; these are the zones`
> `    # git, gh and git-lfs actually contact over 443.`
> `    echo ".github.com"`
> `    echo ".githubusercontent.com"`
> `    echo ".githubassets.com"`
> `} > "$SNI_ALLOWLIST"`
> *(remainder of the enclosing block: `chmod 0444 "$SNI_ALLOWLIST"` at :870, then the `--daemon` start at :874-878.)*

**Legibility-target:** for-author

One concept — "the GitHub zones this boundary admits by name" — is expressed twice: once as a named space-separated constant consumed by `compose_dnsmasq_conf` (:191), once as three inline `echo` literals in the SNI allowlist heredoc. The two lists disagree. Because the proxy resolves the SNI *through the container resolver* (`cc-sni-proxy.py:20-21`, :182-183) and dnsmasq REFUSES any name without a `server=/…/` line, a `githubassets.com` request is admitted by the proxy's allowlist and then dies in `getaddrinfo` — logged as `FAIL … (resolved address not in the ipset?)`, which points the operator at the wrong subsystem. Fact-check E2 flagged this and noted the fix touches the pinned assertion at `test/init-firewall-rules.bats:727`. Failure mode: *one contract, two hardcoded copies, silently out of sync*.
**Recommendation:** Make one list the source of truth — e.g. `GITHUB_ZONES="github.com githubusercontent.com githubassets.com"`, consumed by both `compose_dnsmasq_conf` (bare) and the SNI allowlist writer (dot-prefixed) — and decide add-vs-drop for `githubassets.com` once, in one place.

---

#### One profile entry is read by three grammars that disagree on what it means

**Severity:** Inconsistent
**Location:** `devcontainer-config/init-firewall.sh:116-134` (`parse_entry`), `:199` (`compose_dnsmasq_conf` regex), `:862` (SNI 443 filter)
**Move:** 7 (asymmetry) / 3 (consumer contract)
**Confidence:** High
**Evidence:**
> `  [[ "$domain" =~ ^${label}(\.${label})*$ ]] || return 1`

> `    if [[ ! "$d" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)+$ ]]; then`

> `        case ",$ports," in *,443,*) echo "$domain" ;; esac`

**Legibility-target:** for-author

The profile grammar is the surface project owners write, and three consumers parse it differently. Reproduced against the shipped script:

- **Single-label entry** (`localhost`): `parse_entry` accepts it (`(\.label)*` — zero dots allowed), so it becomes an ipset member; `compose_dnsmasq_conf`'s regex requires `(\.label)+` — at least one dot — so it emits `WARNING: not a hostname, omitting from resolver allowlist` and the name is never resolvable. Admitted at the IP layer, blocked at the DNS layer.
- **Zero-padded port** (`api.anthropic.com:0443`): `parse_entry` validates it via `10#$port` but prints `ports` **verbatim**, so `0443` reaches `ipset add … tcp:0443` *and* fails the `*,443,*` case match at :862, so the host is silently omitted from the SNI allowlist — and since tcp/443 is REDIRECTed to the proxy, the entry grants nothing at all. Confirmed by running `--print-entries` on a fixture (`api.anthropic.com<TAB>0443`).

This is fact-check escalation E7, routed to this pass. Failure mode: *non-canonicalised entry, three divergent readings*.
**Recommendation:** Canonicalise in `parse_entry` — emit `$((10#$port))` rather than `$port`, and require at least one dot in `domain` so the ipset and resolver grammars coincide. Then the `*,443,*` match and the resolver regex are both operating on the one canonical form.

---

#### `cc-sni-proxy.py` claims manifest coverage it does not have

**Severity:** Inconsistent
**Location:** `devcontainer-config/cc-sni-proxy.py:24-25`, consumer `devcontainer-config/cc-isolated.sh:50-65`
**Move:** 6 (versioning) / 3 (consumer contract)
**Confidence:** High
**Evidence:**
> `Single file, stdlib only (python3.11 ships in the node:22 base — no apt package,`
> `no pip), root-owned in the image and hashed by the launcher's trust manifest.`

> `  echo "devcontainer.json"`
> `  echo "Dockerfile"`
> `  echo "init-firewall.sh"`
> `  echo "cc-isolated.sh"`
> *(remainder of `enforcement_files()`: the sorted `egress/*.txt` and `projects/*.profile` globs at :61-63, then the closing subshell — no other literal filenames.)*

**Legibility-target:** for-author

`enforcement_files()`'s own comment states the rule — "Files whose integrity gates a container (re)build. All of them execute host-side or define the boundary" — and every other file matching that description is listed. The proxy is now an enforcement binary on par with `init-firewall.sh`, so host-side tampering with it (the threat the manifest exists for) goes undetected while its docstring asserts the opposite. Confirms fact-check Claim 10 / E1. Failure mode: *docstring asserts a gate the gate does not implement*. Note the fix is co-dependent with F1: adding it to `enforcement_files()` without adding it to `PAYLOAD` makes `compute_manifest` fail with `ERROR: enforcement file missing`.
**Recommendation:** Add `echo "cc-sni-proxy.py"` to `enforcement_files()` alongside the `PAYLOAD` fix, then re-bless. Both changes are outside this pass's file scope but gate the same rebuild.

---

#### The two daemons managed by the same script use asymmetric env-override granularity, file layout, and modes

**Severity:** Inconsistent
**Location:** `devcontainer-config/init-firewall.sh:395-396`, `:437-442`, `:659`, `:870`
**Move:** 7 (asymmetry)
**Confidence:** High
**Evidence:**
> `DNSMASQ_CONF="${CC_DNSMASQ_CONF:-/etc/dnsmasq.d/cc-allowlist.conf}"`
> `DNSMASQ_PIDFILE="${CC_DNSMASQ_PIDFILE:-/run/cc-dnsmasq.pid}"`

> `SNI_PROXY_BIN="${CC_SNI_PROXY_BIN:-/usr/local/bin/cc-sni-proxy.py}"`
> `SNI_RUN_DIR="${CC_SNI_RUN_DIR:-/run/cc-sni-proxy}"`
> `SNI_ALLOWLIST="$SNI_RUN_DIR/allowlist"`
> `SNI_PIDFILE="$SNI_RUN_DIR/proxy.pid"`
> `SNI_LOG="$SNI_RUN_DIR/proxy.log"`
> `SNI_PORT="${CC_SNI_PORT:-3443}"`

**Legibility-target:** for-orchestrator-synthesis

Four axes diverge for two sibling daemons started by the same script in the same phase: (a) dnsmasq exposes one env var **per file**, the proxy exposes one for the **directory** and derives three paths from it, so a consumer cannot relocate the proxy pidfile independently the way it can dnsmasq's; (b) the generated dnsmasq config lives under `/etc`, the generated SNI allowlist under `/run`, though both are per-run generated boundary config with identical "DO NOT EDIT" headers; (c) the pidfiles are flat-vs-nested (`/run/cc-dnsmasq.pid` vs `/run/cc-sni-proxy/proxy.pid`); (d) modes differ — `chmod 0644 "$DNSMASQ_CONF"` (:659) against `chmod 0444 "$SNI_ALLOWLIST"` (:870). Related: `stop_dnsmasq` (:413-428) identifies its prior instance by `/proc/pid/comm` *plus* a uid sweep, while the proxy's `stop_prior` (`cc-sni-proxy.py:212-232`) uses a cmdline substring with no sweep fallback. None of this is wrong; it is four gratuitous differences a reader must hold in mind. Failure mode: *sibling subsystems, no shared shape*.
**Recommendation:** Pick one per axis and align — most cheaply, add `CC_SNI_PIDFILE`/`CC_SNI_ALLOWLIST` defaults derived from `CC_SNI_RUN_DIR` (keeping the dir var), and make the two generated configs share a mode. Low priority; do it while the code is fresh or not at all.

---

#### The profile grammar now hard-aborts inputs the profile files' own documentation implies are accepted

**Severity:** Inconsistent
**Location:** `devcontainer-config/egress/base.txt:12-13`, `devcontainer-config/init-firewall.sh:62`, `:284-290`
**Move:** 3 (breaking changes) / 8 (nullability)
**Confidence:** High
**Evidence:**
> `# Format: one entry per line, `domain[:port[,port...]]`. Blank lines and #-comments`
> `# ignored. The optional suffix is a comma-separated list of TCP ports; when absent the`

> `  grep -hvE '^[[:space:]]*(#|$)' "${files[@]}" | sort -u`

**Legibility-target:** for-author

`compose_domains` strips only **full-line** comments, but the header says "#-comments ignored" without qualification, and the sibling grammar in `cc-sni-proxy.py:134` (`line.split("#", 1)[0]`) *does* support inline comments — so a project owner writing `pypi.org  # the index` reasonably expects it to work. It does not: `parse_entry` sees the whole string as the domain and `init-firewall.sh:286` aborts the firewall rebuild. Enumerating what previously-valid input now fails (verified by running `--print-entries` on fixtures): inline `#` comments, a trailing-dot FQDN (`example.com.` — a legal absolute name that `dig` resolved fine at `bd41aef`), an indented entry, and any name with an underscore. At `bd41aef` each of these produced a `WARNING: Failed to resolve … skipping`; now each aborts the whole rebuild into the fail-closed trap. **None of the eight shipped profiles trip this** — I ran `--print-entries` over all of them (combined: exit 0, 24 entries), so this is a latent contract change, not an active break. Failure mode: *grammar tightened past its own documentation*.
**Recommendation:** Either strip inline comments and trailing dots in `compose_domains`, or amend the header of `egress/base.txt` to say "full-line `#` comments only; a trailing dot is not accepted". The documented-vs-actual gap is the part worth closing.

---

#### `--listen` without a colon silently binds every interface

**Severity:** Minor
**Location:** `devcontainer-config/cc-sni-proxy.py:199-204`, `:291`
**Move:** 8 (nullability) / 4 (error consistency)
**Confidence:** High
**Evidence:**
> `    host, _, port = args.listen.rpartition(":")`
> `    server = await asyncio.start_server(`
> `        lambda r, w: handle(r, w, allow, args.upstream_port), host, int(port), reuse_address=True)`

**Legibility-target:** for-author

`"3443".rpartition(":")` returns `('', '', '3443')`, and `asyncio.start_server(host='')` binds **`0.0.0.0` and `::`** — verified by running it. So `--listen 3443` turns a loopback-only interception proxy into an all-interfaces listener with no warning, on a process whose entire purpose is to be a boundary. A non-numeric port is the mirror case: `int(port)` raises `ValueError` as an uncaught traceback rather than argparse's `error: argument --listen: …`, which is the shape every other bad argument produces (`ap.error("--daemon requires --pidfile")` at :301). `init-firewall.sh:875` always passes `127.0.0.1:$SNI_PORT`, so nothing live is affected. Failure mode: *permissive parse of a security-relevant argument*.
**Recommendation:** Validate `--listen` in `main()` — require a `host:port` shape and reject an empty host via `ap.error(...)`, keeping the failure in argparse's vocabulary.

---

#### The proxy's operator-visible vocabulary diverges from the rest of the boundary, and `FAIL` hardcodes one hypothesis

**Severity:** Minor
**Location:** `devcontainer-config/cc-sni-proxy.py:176-190`, `:204`, `:241`, `:255`
**Move:** 4 (error consistency)
**Confidence:** High
**Evidence:**
> `            log(f"FAIL sni={sni} orig_dst={orig}: {e} (resolved address not in the ipset?)")`

> `    log(f"listening on {args.listen}; {len(allow.exact)} exact names, {len(allow.zones)} zones")`

> `        sys.exit("cc-sni-proxy: refusing to run as root; pass --user")`

**Legibility-target:** for-author

Three small divergences on the one surface humans read while debugging a blocked connection. (a) `FAIL` names a single cause parenthetically, but the `except` clause it sits in catches `OSError` *and* `asyncio.TimeoutError`, which also covers a dnsmasq `REFUSED` (the actual outcome for `githubassets.com`, F2), a connection refused, and a connect timeout — the message points the operator away from the DNS layer. (b) Every other log line leads with a verb token (`ALLOW`/`REJECT`/`FAIL`) but the startup line does not, so `grep -E '^\S+ (ALLOW|REJECT|FAIL)'` silently drops it. (c) Stderr messages use the Python `prog: message` convention while every sibling script in `devcontainer-config/` uses `ERROR: ` / `WARNING: ` (`init-firewall.sh:249`, `cc-isolated.sh:92`). Fact-check 38a/38b found the guide's rendering of this vocabulary incomplete on the same points. Failure mode: *log grammar drifts from its siblings and over-claims a cause*.
**Recommendation:** Drop the parenthetical or widen it ("resolution refused, or the resolved address is not in the ipset"), and prefix the startup line with a verb such as `START`. The stderr prefix is a judgement call — note it, don't churn it.

---

#### `ccproxy` is the only unhyphenated `cc`-scoped identifier in the system

**Severity:** Minor
**Location:** `devcontainer-config/Dockerfile:56-57`, `devcontainer-config/init-firewall.sh:449`, `:874`
**Move:** 2 (naming)
**Confidence:** High
**Evidence:**
> `RUN id -u ccproxy >/dev/null 2>&1 || \`
> `  useradd --system --no-create-home --home-dir /nonexistent --shell /usr/sbin/nologin ccproxy`

**Legibility-target:** for-author
Precedent: hyphenated `cc-` prefix used in `devcontainer-config/` (`cc-isolated`, `cc-egress`, `cc-sni-proxy.py`, `cc-dnsmasq.pid`, `cc-allowlist.conf`, `cc-<project-id>-claude-config`)

Every other identifier this project namespaces with `cc` is hyphenated, including the proxy's own binary, run dir, and pidfile path. `ccproxy` is the lone exception, so grepping the codebase for `cc-` misses the uid that the owner-match rules key on. Debian's default `NAME_REGEX` (`^[a-z][-a-z0-9_]*$`) permits `cc-proxy`, so the constraint is not the reason. Failure mode: *namespace prefix applied inconsistently*.
**Recommendation:** Rename to `cc-proxy` (or `cc-sni`) in `Dockerfile:56-57`, `init-firewall.sh:449`/`:874`, and the bats fixtures — cheap now, since no image has been blessed with the current name. If you'd rather not touch it, that's defensible; record it.

---

#### `--print-entries` prints a less helpful error than the code path it exists to preview

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:142` vs `:285-288`
**Move:** 4 (error consistency)
**Confidence:** High
**Evidence:**
> `    parse_entry "$entry" || { echo "ERROR: malformed egress entry '$entry'" >&2; exit 1; }`

> `  parsed="$(parse_entry "$entry")" || {`
> `    echo "ERROR: malformed egress entry '$entry' (want domain[:port[,port...]])" >&2`
> `    exit 1`
> `  }`

**Legibility-target:** for-author

The hook exists so a human can preview the parse without touching the firewall — it is the *debugging* surface — yet it drops the `(want domain[:port[,port...]])` hint that the production path prints. Both fail on the same input at the same exit code, so only the message diverges. The four hooks are otherwise pleasingly uniform in their failure behaviour. Failure mode: *the diagnostic path is less diagnostic than the production path*.
**Recommendation:** Use the same string in both, or factor the message into a one-line helper alongside `parse_entry`.

---

#### Two enforcement binaries, two mode conventions in the same `RUN`

**Severity:** Minor
**Location:** `devcontainer-config/Dockerfile:409-410`
**Move:** 2 (naming/convention) / 7 (asymmetry)
**Confidence:** High
**Evidence:**
> `RUN chmod +x /usr/local/bin/init-firewall.sh /usr/local/bin/link-claude-home.sh && \`
> `  chown root:root /usr/local/bin/cc-sni-proxy.py && chmod 0555 /usr/local/bin/cc-sni-proxy.py && \`

**Legibility-target:** for-author

The Dockerfile comment at :386-388 says the proxy is "root-owned and 0555 **like the firewall script it belongs to**", but the adjacent line gives the firewall script `chmod +x` (0755 from the `COPY`), not 0555 — the two most security-relevant executables in the image get different explicit modes on consecutive lines of one `RUN`. Confirms fact-check Claim 4. Both are root-owned so the practical difference is nil; the inconsistency is that the comment asserts a symmetry the code does not have. Failure mode: *stated symmetry, asymmetric implementation*.
**Recommendation:** Apply `chmod 0555` to all three scripts (or reword the comment). Prefer the former — it makes the claim true and costs nothing.

---

#### The launcher's boundary self-probe does not assert either new control

**Severity:** Informational
**Location:** consumer `devcontainer-config/cc-isolated.sh:250-256`, `:322`
**Move:** 3 (consumer contract)
**Confidence:** Medium
**Evidence:**
> `  echo "Boundary self-probe passed (canary invisible · egress default-deny · workspace identity · volume not shared · image from central Dockerfile)."`

**Legibility-target:** for-orchestrator-synthesis

`probe_boundary()` is the launcher's pre-flight contract, and its summary line enumerates exactly what it verified. This diff adds two enforcement components — a filtering resolver and an SNI proxy — that the probe neither checks nor names, so a container where dnsmasq died after `init-firewall.sh` completed, or where the REDIRECT was removed, still prints "Boundary self-probe passed". `init-firewall.sh` does run its own in-script probes (`:928-943`), but those run once at postStart, not at each launch, which is the gap the launcher probe exists to fill. Failure mode: *probe vocabulary lags the boundary it certifies*.
**Recommendation:** Out of scope for this pass — escalate. A one-line addition (assert `curl` to a non-allowlisted SNI on an allowlisted address fails, as `init-firewall.sh:937-943` already does) would restore the correspondence.

---

#### Profile-grammar forward compatibility is one-way, and the ipset name was retained across a type change

**Severity:** Informational
**Location:** `devcontainer-config/init-firewall.sh:731`, `:902`, `devcontainer-config/egress/llm.txt:24`
**Move:** 6 (versioning)
**Confidence:** Medium
**Evidence:**
> `ipset create allowed-domains hash:net,port`

> `iptables -A OUTPUT -m set --match-set allowed-domains dst,dst -j ACCEPT`

**Legibility-target:** for-orchestrator-synthesis

New image + old profile is fully compatible (bare entries default to 443, as decision-log #39 claims). The reverse is not: an *old* baked `init-firewall.sh` fed the new `host.docker.internal:11434` line passes the whole string to `dig`, which fails, and the entry is silently dropped with `WARNING: Failed to resolve` — a widened profile that reads as a network outage rather than an error. This is bounded in practice, because the manifest + rebuild flow means image and profiles move together, but it is worth knowing during the rebuild the user is about to do: profiles and image must be re-blessed as a pair, not independently. Separately, `allowed-domains` keeps its name across the `hash:net` → `hash:net,port` type change, so anything inspecting the set by name (`ipset list allowed-domains`) now gets `<ip>,tcp:<port>` members where it previously got bare addresses. I found no automated consumer of that output in the range; a human reading it will notice. Failure mode: *silent downgrade on a version skew*.
**Recommendation:** No code change. Note in the rebuild checklist that the image and the profile files must be re-blessed together.

---

#### The negative SNI probe passes on any `curl` failure, including one caused by an empty probe IP

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:934-943`, `:347`, `:380-382`
**Move:** 8 (nullability) / 9 (safety semantics)
**Confidence:** Medium
**Evidence:**
> `if runuser -u node -- curl --connect-timeout 5 --max-time 15 \`
> `        --resolve "not-allowlisted.invalid:443:$ANTHROPIC_PROBE_IP" https://not-allowlisted.invalid/ >/dev/null 2>&1; then`
> `    echo "ERROR: Firewall verification failed - a non-allowlisted SNI reached an allowlisted address"`
> `    exit 1`
> `else`
> `    echo "Firewall verification passed - non-allowlisted SNI refused as expected"`
> `fi`
> *(the enclosing section ends at `FIREWALL_COMPLETE=1`, :948 — this is the last check before the sentinel.)*

**Legibility-target:** for-author

This is the one probe that distinguishes the SNI proxy from address matching alone, and its success criterion is "curl exited non-zero" — which is also satisfied by a malformed `--resolve` argument, a missing `runuser`, or any unrelated curl failure. `ANTHROPIC_PROBE_IP` cannot in fact be empty here (`:364-367` exits when `api.anthropic.com` does not resolve, and `:380-382` sets it from the first A record), so the null case is closed; the broader "any failure counts as a pass" shape is not, and it matches the pre-existing `example.com` probe at `:911-916`, so it is *consistent* with precedent rather than a deviation. Confirms fact-check Claim 37. Failure mode: *negative test that cannot fail for the right reason*.
**Recommendation:** Optional: assert on curl's exit code (`52`/`56`, empty reply from the proxy's close) or grep `$SNI_LOG` for the matching `REJECT sni=not-allowlisted.invalid`, which is the observable this probe actually means to assert.

---

## What Looks Good

- **The four inspection hooks are uniform and side-effect-free.** All four match `[ "${1:-}" = "--flag" ]`, exit before `trap fail_closed_on_abort EXIT` is installed at `:271`, and touch no state; `--print-resolvers` and `--print-dnsmasq-conf` both take the resolv.conf path as `${2:-/etc/resolv.conf}`, so the "argument, deliberately not an environment variable" rationale recorded at `:77-84` in the prior review is carried forward correctly into the new hook. `route: code-fact-check` — Verified: the `--print-dnsmasq-conf` branch at `:210-213` sits above the trap installation at `:271` and I ran it against fixtures with no side effect. Not verified: that no future hook is added below the trap; nothing enforces the ordering mechanically.
- **The `CC_<AREA>[_GUARD]` chain-naming scheme is new but applied identically to both blocks** (`CC_DNS`/`CC_DNS_GUARD`, `CC_SNI`/`CC_SNI_GUARD`), with the same three-rule shape — two `--uid-owner … -j RETURN` exemptions then the action. A reader who learns one block reads the other for free.
- **`GH_TOKEN` follows the `OPENROUTER_API_KEY` template precisely** — `${localEnv:}`, default-unset, and a comment that states both the threat it does *not* close and the narrowest useful configuration. This is the established shape for an opt-in credential in `containerEnv` and it was reused rather than reinvented.
- **The `:port` suffix is a genuinely backward-compatible extension of the profile grammar** for every entry form actually in use: I ran `--print-entries` across all eight shipped profiles individually and combined — exit 0, 24 entries, every pre-existing bare line resolving to `<domain><TAB>443`.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| 1 | `cc-sni-proxy.py` absent from `install.sh` `PAYLOAD`; Dockerfile `COPY` has no source in the build context | Breaking | `install.sh:25`, `Dockerfile:389` | High |
| 2 | GitHub zone list duplicated in two grammars, divergent membership (`.githubassets.com` unresolvable) | Inconsistent | `init-firewall.sh:154`, `:864-868` | High |
| 3 | One profile entry read by three disagreeing grammars (single-label, zero-padded port) | Inconsistent | `init-firewall.sh:116-134`, `:199`, `:862` | High |
| 4 | Proxy docstring claims manifest coverage `enforcement_files()` does not provide | Inconsistent | `cc-sni-proxy.py:24-25`, `cc-isolated.sh:50-65` | High |
| 5 | Sibling daemons: asymmetric env granularity, file layout, modes, stop-prior protocol | Inconsistent | `init-firewall.sh:395-396`, `:437-442`, `:659`, `:870` | High |
| 6 | Profile grammar hard-aborts inputs its own documentation implies are accepted | Inconsistent | `egress/base.txt:12-13`, `init-firewall.sh:62`, `:284-290` | High |
| 7 | `--listen` without a colon silently binds all interfaces | Minor | `cc-sni-proxy.py:199-204`, `:291` | High |
| 8 | Log vocabulary diverges from siblings; `FAIL` hardcodes one hypothesis | Minor | `cc-sni-proxy.py:176-190`, `:204`, `:241` | High |
| 9 | `ccproxy` is the only unhyphenated `cc`-scoped identifier | Minor | `Dockerfile:56-57`, `init-firewall.sh:449` | High |
| 10 | `--print-entries` error omits the grammar hint the production path prints | Minor | `init-firewall.sh:142` vs `:285-288` | High |
| 11 | Two enforcement binaries, two mode conventions in one `RUN` | Minor | `Dockerfile:409-410` | High |
| 12 | Launcher self-probe asserts neither new control, but claims a full pass | Informational | `cc-isolated.sh:250-256`, `:322` | Medium |
| 13 | Profile-grammar forward compatibility is one-way; ipset name retained across type change | Informational | `init-firewall.sh:731`, `:902` | Medium |
| 14 | Negative SNI probe passes on any `curl` failure | Minor | `init-firewall.sh:934-943` | Medium |

---

## Overall Assessment

The consumer-facing surfaces this diff adds are, with one exception, well-matched to the conventions already in the tree. The four inspection hooks, the `CC_*` env seams, the new iptables chain names, and the `GH_TOKEN` passthrough all reuse an existing template rather than inventing one, and the `:port` profile extension is genuinely backward-compatible for every entry form in use. The proxy's CLI reads like a sibling of the existing scripts.

The exception is worth stopping on: **`cc-sni-proxy.py` is not wired into either host-side mechanism that moves and gates boundary files** — not `install.sh`'s `PAYLOAD` (so the rebuild the user is about to run will fail at `COPY`, or silently bake a stale copy) and not `cc-isolated.sh`'s `enforcement_files()` (so it is outside the bless manifest whose protection its own docstring claims). These two are co-dependent — fixing only the second makes `compute_manifest` fail — and both must land before the rebuild-and-re-bless.

Below that, the recurring shape is **the same contract expressed twice and allowed to diverge**: the GitHub zone list (F2), the profile-entry grammar across three consumers (F3), the two daemons' file conventions (F5), the documented-vs-actual comment grammar (F6). None of these is a design error; each is a place where one authoritative definition would have prevented a divergence that has already occurred once (`.githubassets.com`) and can occur again silently. F2 and F3 are the two I would fix in this pass; F5, F6 and the Minors are worth a cleanup commit but do not gate the rebuild.

Nothing in the diff breaks an existing consumer's contract other than F1. `--print-domains` output semantics are unchanged for its two bats consumers (both substring matches), `cc-isolated.sh` reads only the exit status so the new echo lines are safe, and the ipset type change has no automated reader in this range.

## Goal-Alignment Note

- **Answered:** yes — API-consistency pass over `devcontainer-config/` at `bd41aef..abbd42d`, 14 findings, name-pattern audit, report written to `docs/reviews/api-consistency-review-2026-09-03-egress-hardening.md`.
- **Out of scope:** `test/init-firewall-rules.bats`, `test/test_cc_sni_proxy.py`, `guides/cc-isolated-usage.md`, `docs/working/questions.md` — read as consumers/baselines only, per the pass-1 brief. `install.sh` and `cc-isolated.sh` are unchanged in the range but are the consumers of two new surfaces, so F1/F4/F12 cite them deliberately. Security judgements (whether root exemption is right, whether SNI peeking is sufficient) belong to `security-reviewer`; I only checked whether the surfaces are self-consistent.
- **Escalate:** (a) **F1 gates the rebuild** — `install.sh:25` must gain `cc-sni-proxy.py` before the user re-installs, and F4 must land with it or `--bless` fails; (b) F2's fix touches the pinned assertion at `test/init-firewall-rules.bats:727`, which is the later pass's file — sequence them together; (c) F12 (launcher probe coverage) is a `cc-isolated.sh` change outside both passes; (d) fact-check 38a/38b/38c (guide's log-vocabulary gloss) is the guide pass's, and F8 is its in-scope counterpart — fix the proxy's message and the guide's rendering in one go.
