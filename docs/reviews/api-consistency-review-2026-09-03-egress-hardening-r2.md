# API Consistency Review — egress hardening fix wave d53bf6a..2839e59

Commit: 2839e59

**Scope:** `git diff d53bf6a..2839e59 -- devcontainer-config/` — `init-firewall.sh`, `cc-sni-proxy.py`, `cc-isolated.sh`, `install.sh`, `Dockerfile`, `devcontainer.json`, `egress/base.txt`. Re-review pass over the two fix commits (`b708266` review-fix wave, `2839e59` loop-pass fact-check closeout). `test/init-firewall-rules.bats`, `test/cc-isolated-functions.bats`, `guides/cc-isolated-usage.md`, `docs/decisions/log.md` and `docs/working/questions.md` are in the range but were read here as **consumers and baselines**, not as review targets.
**Date:** 2026-09-03
**Based on:** `docs/reviews/api-consistency-review-2026-09-03-egress-hardening.md` (pass 1, at `abbd42d`); `docs/reviews/code-fact-check-report.md` (k=1 loop pass, `b708266`); `docs/reviews/code-review-rubric-2026-09-03-main-egress-hardening.md` (rows A1–A16, C3–C6, R6).

---

## Prior findings status

All fourteen findings from the pass-1 report. "Deferred (logged)" means the item is carried in the rubric and/or `docs/working/questions.md` with an explicit interim decision — a recorded deferral, not a dropped finding.

| Prior # | Finding | Status | Evidence |
|---|---|---|---|
| F1 | `cc-sni-proxy.py` absent from `install.sh` `PAYLOAD` | **Fixed** | `install.sh:25` — `PAYLOAD=(devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py cc-isolated.sh link-claude-home.sh egress claude-home)`. Rubric R1/A20-equivalent; fact-check Claim 20 Verified. |
| F2 | GitHub zone list duplicated in two grammars, divergent membership | **Fixed** | `init-firewall.sh:936-942` now derives the SNI zones with `for zone in $(echo "$GITHUB_DNS_ZONES" \| tr ' ' '\n'); do echo ".$zone"; done`; `.githubassets.com` dropped. One source of truth. Rubric R5 ✅; fact-check Claim 13 Verified. |
| F3 | One profile entry read by three disagreeing grammars | **Fixed (mechanism residue — see N1)** | `parse_entry` emits `canon` (`init-firewall.sh:135-146`) and `compose_dnsmasq_conf`'s regex ends `)*$` (`:212-215`). Re-executed here: `padded.example:0443` → `padded.example<TAB>443`; `multi.example:0080,00443,22` → `80,443,22`; `localhost:11434` → `server=/localhost/127.0.0.11`. Rubric R6 ✅. |
| F4 | Proxy docstring claimed manifest coverage it did not have | **Fixed** | `cc-isolated.sh:59-60` adds `cc-sni-proxy.py` and `link-claude-home.sh`; `cc-sni-proxy.py:25-27` docstring rewritten to "listed in install.sh's payload and in the launcher's bless manifest". `test/cc-isolated-functions.bats:126-127` asserts both. Fact-check Claims 16/19 Verified. |
| F5 | Sibling daemons: asymmetric env granularity, layout, modes, stop protocol | **Partly fixed; remainder deferred (logged)** | Modes unified — `Dockerfile:408-409` now `chown root:root` + `chmod 0555` for all three binaries. Env-override granularity, `/etc` vs `/run` config location, flat-vs-nested pidfiles, and the stop-prior protocol are unchanged. Rubric A9 🟡 Open, "env-override shapes left as-is — noted". The new lock file adds a fourth layout point (N8). |
| F6 | Profile grammar hard-aborts inputs its own documentation implies are accepted | **Deferred (logged)** | Rubric A10 🟡 Open; `docs/working/questions.md` entry "Restore inline `#` comment / trailing-dot / indentation tolerance in `parse_entry` (api A10)? · interim: strict grammar kept". `egress/base.txt:15` header still reads "Blank lines and #-comments ignored" unqualified; `compose_domains` (`init-firewall.sh:70`) still strips full-line comments only. |
| F7 | `--listen` without a colon silently binds every interface | **Deferred (logged)** | Rubric C3 🟢 Open. `cc-sni-proxy.py:294` still `ap.add_argument("--listen", default="127.0.0.1:3443", …)` with `rpartition(":")` unvalidated at `:199-204`. |
| F8 | Proxy log vocabulary diverges from siblings; `FAIL` hardcodes one hypothesis | **Deferred in code; documented in the guide** | Rubric C4 🟢 Open. `cc-sni-proxy.py:192` still `FAIL … (resolved address not in the ipset?)`; `:208` startup line still verb-less; `:245` still `sys.exit("cc-sni-proxy: …")`. The *guide* rendering was corrected instead (`guides/cc-isolated-usage.md`, rubric A16 ✅), so the doc now describes `FAIL` accurately while the message itself does not. |
| F9 | `ccproxy` is the only unhyphenated `cc`-scoped identifier | **Deferred (logged)** | Rubric C4 🟢 Open. `Dockerfile:56-57`, `init-firewall.sh:486`, `:948` unchanged. |
| F10 | `--print-entries` error omits the grammar hint the production path prints | **Deferred (logged)** | Rubric C4 🟢 Open. `init-firewall.sh:154` still `echo "ERROR: malformed egress entry '$entry'"`; `:298-301` still adds `(want domain[:port[,port...]])`. |
| F11 | Two enforcement binaries, two mode conventions in one `RUN` | **Fixed** | `Dockerfile:408-409` — `chown root:root` then `chmod 0555` over `init-firewall.sh link-claude-home.sh cc-sni-proxy.py` uniformly; the "like the firewall script it belongs to" claim at `:386-388` was replaced with plain "root-owned and 0555 (decision log #41)". Fact-check Claims 4/21 Verified. |
| F12 | Launcher self-probe asserts neither new control but claims a full pass | **Deferred (logged)** | Rubric C5 🟢 Open. `cc-isolated.sh` changed only in `enforcement_files()` in this range; `probe_boundary()`'s summary sentence is untouched. |
| F13 | Profile-grammar forward compatibility one-way; ipset name retained across type change | **Deferred (logged)** | Rubric C6 🟢 Open. No code change; `ipset create allowed-domains hash:net,port` unchanged. |
| F14 | Negative SNI probe passes on any `curl` failure | **Fixed** | `init-firewall.sh:1016-1022` — the `else` branch was removed and replaced with `if ! grep -q "REJECT sni=not-allowlisted.invalid " "$SNI_LOG" …` → `ERROR: … did not log a refusal …`. Guarded by `test/init-firewall-rules.bats:870-875` (`SILENT_SNI_NEGATIVE=1`). Rubric A1 ✅. |

Tally: **6 fixed** (F1, F2, F3, F4, F11, F14 — exactly the six targeted), **1 partly fixed** (F5), **7 deferred with a recorded interim** (F6–F10, F12, F13). No prior finding was silently dropped, and every deferral I could trace lands in the rubric with a status cell or in `questions.md` with an `interim:` line. That is the behaviour a review-fix loop is supposed to produce.

---

## Baseline Conventions

Re-surveyed at `2839e59`, since the fix wave moved two of them:

1. **Env seams** — `CC_EGRESS_DIR`, `CC_EGRESS_PROFILE_FILE` (`init-firewall.sh:39-40`), `CC_DNSMASQ_CONF`, `CC_DNSMASQ_PIDFILE` (`:431-432`), `CC_SNI_PROXY_BIN`, `CC_SNI_RUN_DIR`, `CC_SNI_PORT` (`:475-480`). Shape: `CC_<SUBSYSTEM>_<THING>`, `${VAR:-<root-owned default>}`, value is **a filesystem path** in every case but `CC_SNI_PORT`. Every declaration site carries an in-comment annotation stating the seam is for the unit tests only and that `sudo`'s `env_reset` strips it (`:35-37`, `:428-430`, `:470-474`).
2. **Inspection hooks** — four, all `[ "${1:-}" = "--print-<noun>" ]`, all above `trap fail_closed_on_abort EXIT` (`:292`), all side-effect-free. `--print-entries` (`:149`), `--print-dnsmasq-conf` (`:227`) take no env-only inputs.
3. **Operator vocabulary** — `ERROR: <msg>` / `WARNING: <msg>`, stderr, exit 1, for anything the operator must act on; bare imperative-participle status lines on stdout for progress (`Restoring Docker DNS rules...`, `Configuring filtering resolver (dnsmasq)...`, `Processing GitHub IPs...`, `Adding $member`); and the verification block's own `Firewall verification passed - <what>` / `ERROR: Firewall verification failed - <what>` pair on **stdout** (`:986`, `:989`, `:994`, `:997`, `:1003`, `:1006`, `:1013`).
4. **Generated boundary files** — every one gets an explicit mode: `chmod 0644 "$DNSMASQ_CONF"` (`:734`), `chmod 0444 "$SNI_ALLOWLIST"` (`:943`), and in the image `chmod 0444 /usr/local/share/cc-egress/*.txt`, `chmod 0440 /etc/sudoers.d/node-firewall` (`Dockerfile:415`, `:419`).
5. **Registries** — `install.sh:25` `PAYLOAD` (what gets copied to the config dir) and `cc-isolated.sh:55-71` `enforcement_files()` (what gets hashed). The fix wave made these two the *same* set modulo `egress`/`claude-home`, and added a comment saying so.
6. **Interpreter pinning** — in-container root executables use absolute shebangs (`init-firewall.sh` `#!/bin/bash`, `cc-sni-proxy.py` `#!/usr/bin/python3`); host-side scripts use `#!/usr/bin/env bash` (`cc-isolated.sh`, `install.sh`, `link-claude-home.sh`). This split is now clean and intentional.

---

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `CC_FIREWALL_LOCK` | env override | `CC_DNSMASQ_PIDFILE`, `CC_DNSMASQ_CONF` | `init-firewall.sh:431-432` | Mostly consistent — `CC_<SUBSYSTEM>_<THING>`, path-valued, `:-` default. Suffix is a bare noun where the sibling file-valued seams name the file *kind* (`_PIDFILE`, `_CONF`, `_FILE`) — see N3 |
| `CC_FIREWALL_LOCK_WAIT` | env override | none — first non-path, non-port scalar seam | `init-firewall.sh:305` | Shape consistent; **new category** (a timeout). Sibling timeouts (`--connect-timeout 5`, `--max-time 15`, the 30×0.1 s daemon waits) have no overrides — asymmetry noted in N4/N8 |
| `CC_FIREWALL_PATH` | env override | `CC_EGRESS_DIR`, `CC_SNI_PROXY_BIN`, `CC_DNSMASQ_CONF` | `init-firewall.sh:38` | **Deviates in referent** — every other `CC_*` path-valued seam names one filesystem object; this one is a `:`-separated search list (N2) |
| `CC_FIREWALL_*` (the subsystem token) | env-override namespace | `CC_EGRESS_*`, `CC_DNSMASQ_*`, `CC_SNI_*` | `init-firewall.sh:39`, `:431`, `:475` | Consistent — the existing tokens name a subsystem; `FIREWALL` names the script's own scope, which is the correct scope for a whole-run lock and a whole-run PATH |
| `/run/cc-firewall.lock` | runtime path | `/run/cc-dnsmasq.pid`, `/run/cc-sni-proxy/` | `init-firewall.sh:432`, `:476` | Consistent with the *flat* half of an already-split precedent (`cc-`-hyphenated, `/run`, kind-suffixed). It picks a side in an unresolved asymmetry rather than resolving it (N8) |
| `.${zone}` SNI entries from `GITHUB_DNS_ZONES` | generated allowlist line | the proxy's `.zone` grammar | `cc-sni-proxy.py:126-138` | Consistent — `Allowlist.load` reads a leading dot as a zone and `lstrip(".")`s it; derived output matches the consumer's grammar exactly |
| `GITHUB_DNS_ZONES` (role widened) | shell constant | `ALLOWED_DOMAINS`, `ALLOWED_ENTRIES`, `GH_CIDRS` | `init-firewall.sh:162-171` | Name and definition comment now **under-describe** two consumers (N6). Generic-named constants with several consumers are precedented; a `_DNS_`-qualified one is not |
| `"IPv6: default-deny installed (…)"` | stdout status line | `"Restoring Docker DNS rules..."`, `"Processing GitHub IPs..."` | `init-firewall.sh:554`, `:808` | **Deviates** — the only `<Topic>: <message>` stdout line; every sibling is a bare participial phrase (N7) |
| `"WARNING: no usable ip6tables filter table — …"` | stderr warning | `"WARNING: no parseable IPv4 nameserver … — …"` | `init-firewall.sh:637` | Consistent — same prefix, same stderr, same em-dash clause structure, same "here is what is now unprotected" second half |
| `"ERROR: another init-firewall.sh run is still holding $FIREWALL_LOCK"` | stderr error | `"ERROR: composed egress allowlist is empty"` | `init-firewall.sh:310` | Consistent in prefix/stream/exit; over-specific for one of its two triggers (N4) |
| `"ERROR: Firewall verification failed - … did not log a refusal … (is the 443 redirect in place? see $SNI_LOG)"` | verification failure | `"ERROR: Firewall verification failed - a non-allowlisted SNI reached an allowlisted address"` | `init-firewall.sh:1013` | Consistent — same `ERROR: Firewall verification failed - ` stem, same stdout stream as its five siblings, same `(see $SNI_LOG)` pointer as `:1003` |
| `"Firewall verification passed - non-allowlisted SNI refused by the proxy (logged)"` | verification pass | `"Firewall verification passed - <what> as expected"` | `init-firewall.sh:989`, `:997` | Consistent stem; the trailing `(logged)` is new but earns its place — it names the evidence the assertion now rests on |
| `link-claude-home.sh` in `enforcement_files()` | manifest member | `init-firewall.sh`, `cc-isolated.sh` | `cc-isolated.sh:58`, `:61` | Consistent — it runs at postStart inside the container and is `COPY`'d into the image, so it meets the list's own stated rule |

---

## Findings

#### The dnsmasq hostname grammar is still a second, inline copy of `parse_entry`'s label regex

**Severity:** Inconsistent
**Location:** `devcontainer-config/init-firewall.sh:126-134` (`parse_entry`), `:212-215` (`compose_dnsmasq_conf`)
**Move:** 7 (asymmetry) / 3 (consumer contract)
**Confidence:** High
**Evidence:**
> `  local entry="$1" domain ports port label`
> `  label='[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?'`
> …
> `  [[ "$domain" =~ ^${label}(\.${label})*$ ]] || return 1`

> `    # Same label grammar as parse_entry (a single label is allowed there, so it must`
> `    # be allowed here too — otherwise an entry can be ipset-admitted yet unresolvable).`
> `    if [[ ! "$d" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)*$ ]]; then`
> *(remainder of the enclosing `for d in …` body: the `WARNING: not a hostname …` + `continue` at `:216-217`, then the `while read -r ns` loop emitting `server=/$d/$ns` at `:219-222`, closing the function at `:224`.)*

**Legibility-target:** for-author

The fix made the two grammars *equal in behaviour* — I re-executed it: `localhost:11434` now yields both an ipset member and `server=/localhost/127.0.0.11`, which is exactly what F3 asked for. But it did so by editing one character in a literal duplicate, leaving two independently-editable regexes for one contract, one of which is assembled from a named `$label` variable and the other spelled out. The comment now *asserts* the sameness ("Same label grammar as parse_entry") rather than deriving it, which is precisely the shape F2 and F3 were both instances of: one contract, two copies, a comment claiming they agree. This is the residue of the fix, not a regression — the values agree today. Failure mode: *aligned by hand, re-divergeable by hand*.
**Recommendation:** Hoist `label` to a script-level readonly next to `GITHUB_DNS_ZONES` and use `^${label}(\.${label})*$` in both places, so the next edit to the grammar cannot land in only one of them.

---

#### `CC_FIREWALL_PATH` names a search list where every sibling `CC_*` names a filesystem object

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:31-38`
**Move:** 2 (naming)
**Confidence:** High
**Evidence:**
> `# Root-owned helper resolution only. Everything this script runs as root — iptables,`
> `# ipset, dig, curl, runuser, dnsmasq, the proxy — is found via PATH, and `node`'s own`
> `# PATH includes the node-writable /usr/local/share/npm-global/bin. sudo's env_reset`
> `# and secure_path normally protect this, but nothing in the repo asserts that, so`
> `# the script pins PATH itself. CC_FIREWALL_PATH exists only so the unit tests can`
> `# put their stubs first; under sudo env_reset `node` cannot set it.`
> `export PATH="${CC_FIREWALL_PATH:-/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin}"`

**Legibility-target:** for-author
Precedent: `CC_<SUBSYSTEM>_<PATH-TO-ONE-OBJECT>` used in `devcontainer-config/init-firewall.sh:39-40` (`CC_EGRESS_DIR`, `CC_EGRESS_PROFILE_FILE`), `:431-432` (`CC_DNSMASQ_CONF`, `CC_DNSMASQ_PIDFILE`), `:475-476` (`CC_SNI_PROXY_BIN`, `CC_SNI_RUN_DIR`).

Read cold in a `env | grep ^CC_` listing or in a bats `setup()`, `CC_FIREWALL_PATH=<something>` parses as "the path to the firewall" — the same reading `CC_SNI_PROXY_BIN` and `CC_EGRESS_DIR` invite, and the one that would be wrong. Six of the seven existing `CC_*` seams are single-object paths, so the family already trains that reading. The comment three lines above disambiguates it for anyone reading the script; nothing disambiguates it for a test author reading only `test/init-firewall-rules.bats:205`. Failure mode: *a name that reads as a member of a family it is not in*.
**Recommendation:** `CC_FIREWALL_SEARCH_PATH` or `CC_FIREWALL_HELPER_PATH`. Two call sites (`init-firewall.sh:38`, `test/init-firewall-rules.bats:205`) plus the pinned source-text assertion at `test/init-firewall-rules.bats:897`.

---

#### The two lock seams are the only env overrides whose declaration site omits the "unit tests only / `env_reset`" annotation

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:294-311`
**Move:** 3 (consumer contract) / 4 (documentation convention)
**Confidence:** High
**Evidence:**
> `# for the first to finish (or fails closed via the trap if it cannot get the lock).`
> `# The lock is taken AFTER the trap is installed so a lock failure also ends at DROP.`
> `FIREWALL_LOCK="${CC_FIREWALL_LOCK:-/run/cc-firewall.lock}"`
> `exec 9>"$FIREWALL_LOCK"`
> `if ! flock -w "${CC_FIREWALL_LOCK_WAIT:-120}" 9; then`
> `    echo "ERROR: another init-firewall.sh run is still holding $FIREWALL_LOCK" >&2`
> `    exit 1`
> `fi`
> *(the eight comment lines above `FIREWALL_LOCK` — `:294-301` — are the whole rationale block; they describe the interleaving hazard and the trap ordering, and say nothing about the two `CC_*` names.)*

**Legibility-target:** for-author
Precedent: the test-seam annotation is stated at every other declaration site — `init-firewall.sh:35-37` ("CC_FIREWALL_PATH exists only so the unit tests can put their stubs first; under sudo `env_reset` `node` cannot set it"), `:428-430` ("The two paths are env-overridable for the unit tests only: this script runs via sudo (NOPASSWD, no SETENV), whose env_reset strips them, exactly as for CC_EGRESS_DIR above"), `:470-474` ("Paths are overridable for the unit tests only; in the image they are the root-owned defaults").

That annotation is doing real work: it is the only thing in the tree that tells a reader these seams are *not* a supported operator knob, and the only place the `env_reset` argument for why they are safe is recorded. `CC_FIREWALL_LOCK` in particular relocates a **security-relevant serialisation point** — a reader who takes it for a supported setting could point two concurrent runs at different lock files and reintroduce exactly the interleaving the block above it describes. The same commit that added the seam wrote eight lines of rationale for the lock and none for its overrides. Failure mode: *a test seam that does not announce itself as one*.
**Recommendation:** One sentence after the rationale block — "`CC_FIREWALL_LOCK`/`CC_FIREWALL_LOCK_WAIT` are for the unit tests only; `sudo`'s `env_reset` strips them, exactly as for `CC_EGRESS_DIR`" — matching the wording at `:428-430`.

---

#### The lock-failure message names one cause for a branch with two

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:305-308`
**Move:** 4 (error consistency) / 8 (nullability)
**Confidence:** High
**Evidence:**
> `if ! flock -w "${CC_FIREWALL_LOCK_WAIT:-120}" 9; then`
> `    echo "ERROR: another init-firewall.sh run is still holding $FIREWALL_LOCK" >&2`
> `    exit 1`
> `fi`

**Legibility-target:** for-author

`flock` exits non-zero both on timeout and on a bad invocation, so any non-numeric `CC_FIREWALL_LOCK_WAIT` (a typo in a bats `setup()`, or a future operator-facing use) produces `flock: invalid timeout value` on stderr followed by a confident, wrong `ERROR: another init-firewall.sh run is still holding …` — and then the fail-closed trap drops the container's egress. The empty case is closed: `${…:-120}` uses `:-`, so `CC_FIREWALL_LOCK_WAIT=""` falls back to 120 (matching `CC_SNI_PORT`'s handling at `:480`). This is the same shape as prior F14 — a message that hardcodes one hypothesis for a condition with several — which this wave fixed for the SNI probe but reintroduced here. Failure mode: *diagnostic asserts a cause the branch does not establish*.
**Recommendation:** Either widen the message ("could not acquire $FIREWALL_LOCK within ${CC_FIREWALL_LOCK_WAIT:-120}s — another run may still be holding it") or validate the timeout with the `[[ … =~ ^[0-9]+$ ]]` guard already used for `DNSMASQ_UID` (`:439`) and `CCPROXY_UID` (`:488`).

---

#### `enforcement_files()` and `PAYLOAD` are now declared to be in step, but nothing orders or checks them

**Severity:** Minor
**Location:** `devcontainer-config/cc-isolated.sh:45-71`, `devcontainer-config/install.sh:25`
**Move:** 7 (asymmetry) / 3 (consumer contract)
**Confidence:** High
**Evidence:**
> `# Files whose integrity gates a container (re)build. All of them execute host-side`
> `# or define the boundary. Keep this list in step with install.sh's PAYLOAD: a file`
> `# that is installed but not hashed is a boundary artefact nobody blessed (the SNI`
> `# proxy shipped that way once). claude-home/ (the baked skills/hooks payload) is`
> `# the one PAYLOAD item still outside this list — see docs/working/questions.md. Paths are relative to config_dir. The per-project .profile`
> `# files are included deliberately: …`

> `PAYLOAD=(devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py cc-isolated.sh link-claude-home.sh egress claude-home)`

**Legibility-target:** for-author

The comment turns an implicit invariant into a stated one, which is the right move — but the two lists are then written in **different orders** (`… init-firewall.sh, cc-sni-proxy.py, cc-isolated.sh, link-claude-home.sh …` in `PAYLOAD`; `… init-firewall.sh, cc-sni-proxy.py, link-claude-home.sh, cc-isolated.sh …` in `enforcement_files()`), so the eyeball diff the comment asks a reader to perform is harder than it needs to be, and nothing mechanical enforces it: `test/cc-isolated-functions.bats:123-128` asserts membership of four names in the manifest and `:425` greps `PAYLOAD` for `claude-home`, but no test compares the two sets. F1 was exactly a set-difference bug between these two lists. Separately, the insertion left line 49 at 140 characters with `… see docs/working/questions.md. Paths are relative to config_dir. The per-project .profile` run together mid-line, against ~82 for every other line in the block. Failure mode: *a hand-maintained correspondence with a comment instead of a check*.
**Recommendation:** Reorder `enforcement_files()` to match `PAYLOAD` and rewrap line 49; then add one bats assertion that every non-directory `PAYLOAD` member appears in `enforcement_files()` output, with `claude-home` (and `egress`, which is expanded per-file) as the named exceptions.

---

#### `GITHUB_DNS_ZONES` now drives two subsystems; its name and its definition comment still describe one

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:162-171`, consumers `:204` and `:936-942`
**Move:** 2 (naming) / 7 (asymmetry)
**Confidence:** High
**Evidence:**
> `# GitHub zones the filtering resolver must answer for. GitHub is admitted by CIDR`
> `# (phase A ingests api.github.com/meta), so no profile lists these names — but the`
> `# resolver only forwards names it is told about. A `server=/github.com/...` line`
> `# covers github.com AND every subdomain (api., codeload., ssh., pkg., ...); likewise`
> `# githubusercontent.com covers objects./raw./media./github-cloud. — the hosts git,`
> `# gh and git-lfs actually contact. Anything else on GitHub (ghcr.io, github.dev)`
> `# is not in the CIDR ingest either, so it stays unresolved AND unroutable.`
> `GITHUB_DNS_ZONES="github.com githubusercontent.com"`

> `    # GitHub is admitted by CIDR (phase A) rather than by name. The SNI zones are`
> `    # derived from the SAME list the filtering resolver serves (GITHUB_DNS_ZONES),`
> `    # so a name the proxy would admit is always one the resolver will answer for;`
> `    # the two lists cannot drift apart again.`
> `    for zone in $(echo "$GITHUB_DNS_ZONES" | tr ' ' '\n'); do`
> `        echo ".$zone"`
> `    done`

**Legibility-target:** for-author
Precedent: multi-consumer constants in this script carry consumer-neutral names — `ALLOWED_DOMAINS` (`:312`), `ALLOWED_ENTRIES` (`:319`), `GH_CIDRS` — and no other constant embeds one consumer's name in its own.

The fix is right and the use-site comment is excellent — it says exactly why the derivation exists. The definition site was not updated to match: the `_DNS_` infix and the opening sentence ("zones the filtering **resolver** must answer for") both still describe a single consumer, so an editor who reaches this constant from the top of the file has no signal that trimming it also narrows the SNI allowlist. Empty-value behaviour is sound in both consumers — `IFS=$'\n\t'` plus `tr ' ' '\n'` means an empty `GITHUB_DNS_ZONES` iterates zero times rather than emitting a bare `.` — which I confirmed by reading both loops. Failure mode: *a name and a comment that lag the role*.
**Recommendation:** Rename to `GITHUB_ZONES` (as pass-1 F2 suggested) or, if the rename is not worth the churn, add one clause: "…must answer for, and the zones the SNI proxy admits (see the SNI allowlist writer in phase B)".

---

#### `IPv6: default-deny installed …` is the only topic-prefixed status line, and it borrows the shape of the `ERROR:`/`WARNING:` family

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:523-550`
**Move:** 4 (error consistency) / 2 (naming)
**Confidence:** High
**Evidence:**
> `if command -v ip6tables >/dev/null 2>&1 && ip6tables -w 5 -S OUTPUT >/dev/null 2>&1; then`
> …
> `    echo "IPv6: default-deny installed (loopback and established flows only)"`
> `else`
> `    echo "WARNING: no usable ip6tables filter table — IPv6 egress is NOT filtered in this container" >&2`
> `fi`
> *(the block runs `:537-546` — `-P INPUT/FORWARD/OUTPUT DROP`, `-F`, `-X`, then four `-A` accepts for `lo` and `ESTABLISHED,RELATED` on INPUT and OUTPUT — before the echo.)*

**Legibility-target:** for-author

Every other stdout status line in this script is a bare participial or nominal phrase — `Restoring Docker DNS rules...`, `Configuring filtering resolver (dnsmasq)...`, `Processing GitHub IPs...`, `Adding GitHub range $cidr (tcp 443, 22)`, `Bridge gateway detected as: $HOST_IP` — and the only `WORD:` prefixes in the whole vocabulary are `ERROR:` and `WARNING:`. A reader (or a `grep -E '^[A-Z]+:'` over a postStart log, which is the natural way to pull the actionable lines out of ~40 lines of progress) now gets an IPv6 success line mixed into the alert set. The sibling `WARNING:` branch two lines below is exemplary — right prefix, right stream, right "here is what is unprotected" second clause. Failure mode: *a success line wearing the alert vocabulary's prefix*.
**Recommendation:** `echo "Installing IPv6 default-deny (loopback and established flows only)..."`, matching `Configuring filtering resolver (dnsmasq)...` two phases later.

---

#### The lock file is the fourth `/run` layout convention and the only generated boundary file with no explicit mode

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:302-304`; compare `:432`, `:476-479`, `:734`, `:943`
**Move:** 7 (asymmetry)
**Confidence:** High
**Evidence:**
> `FIREWALL_LOCK="${CC_FIREWALL_LOCK:-/run/cc-firewall.lock}"`
> `exec 9>"$FIREWALL_LOCK"`

> `chmod 0644 "$DNSMASQ_CONF"`

> `chmod 0444 "$SNI_ALLOWLIST"`

**Legibility-target:** for-orchestrator-synthesis

Prior F5 / rubric A9 is still open ("env-override shapes left as-is — noted"), and this wave added a third `/run` participant to it: `/run/cc-dnsmasq.pid` (flat, kind-suffixed), `/run/cc-sni-proxy/{allowlist,proxy.pid,proxy.log}` (dir-per-daemon), `/run/cc-firewall.lock` (flat). The lock picks the flat side, which is the right call for a script-scoped artefact, but it does so without the asymmetry being decided. More concretely: it is the only file this script creates whose mode is left to the ambient umask, where `$DNSMASQ_CONF`, `$SNI_ALLOWLIST`, and every image-side generated file get an explicit `chmod`. `/run` is root-owned and `node` cannot create or open the file for write, so nothing is exploitable — the gap is that the "every generated boundary file states its mode" convention now has one exception with no stated reason. Failure mode: *a new participant added to an unresolved asymmetry*.
**Recommendation:** Add `chmod 0600 "$FIREWALL_LOCK"` after the `exec 9>`, and roll the layout question into whatever resolves A9 (or close A9 as "flat for script-scoped, dir for daemon-scoped" and record it — that rule already describes the current state).

---

#### The two profile-reading inspection hooks disagree on what a malformed entry is

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:149-158` (`--print-entries`) vs `:227-230` (`--print-dnsmasq-conf`)
**Move:** 4 (error consistency) / 3 (consumer contract)
**Confidence:** High
**Evidence:**
> `  entries="$(compose_domains)"`
> `  while read -r entry; do`
> `    parse_entry "$entry" || { echo "ERROR: malformed egress entry '$entry'" >&2; exit 1; }`
> `  done < <(echo "$entries")`
> `  exit 0`

> `if [ "${1:-}" = "--print-dnsmasq-conf" ]; then`
> `  compose_dnsmasq_conf "$(compose_dns_resolvers "${2:-/etc/resolv.conf}")" "$(compose_domains)"`
> `  exit 0`
> `fi`

**Legibility-target:** for-author

Both hooks take the *raw* `compose_domains` output, but only one of them routes it through `parse_entry`. Executed here on a fixture containing `bad_host:443`: `--print-entries` prints `ERROR: malformed egress entry 'bad_host:443'` and exits 1, while `--print-dnsmasq-conf` prints `WARNING: not a hostname, omitting …` and exits 0 with a config the production run would never reach — production aborts at `:298-301` long before `compose_dnsmasq_conf` is called. So the resolver hook previews a state the boundary cannot be in, and does it *quietly*. This divergence predates the range; it is worth filing now because the fix wave's whole premise (N1's comment: "same label grammar as parse_entry") is that these two paths agree, and on the error path they do not. Failure mode: *sibling hooks, divergent strictness on the same input*.
**Recommendation:** Have `--print-dnsmasq-conf` run the same `parse_entry` pre-flight loop as `--print-entries` before composing, so both hooks fail on exactly the inputs the production run fails on. Sequence with F10, which is the other half of making the hook family's error behaviour uniform.

---

#### The `9>&-` comment justifies an asymmetry the code does not make

**Severity:** Informational
**Location:** `devcontainer-config/init-firewall.sh:737-740`, `:948-949`
**Move:** 5 (idempotency) / 4 (error consistency)
**Confidence:** High
**Evidence:**
> `# 9>&-: do NOT hand the firewall lock (fd 9, see the flock block) to the daemon —`
> `# a long-lived holder would make every later run wait out CC_FIREWALL_LOCK_WAIT and`
> `# fail closed. The proxy closes inherited fds itself; dnsmasq is not assumed to.`
> `dnsmasq --conf-file="$DNSMASQ_CONF" --pid-file="$DNSMASQ_PIDFILE" 9>&-`

> `if ! "$SNI_PROXY_BIN" --daemon --pidfile "$SNI_PIDFILE" --user ccproxy \`
> `        --listen "127.0.0.1:$SNI_PORT" --allowlist "$SNI_ALLOWLIST" --log "$SNI_LOG" 9>&-; then`

**Legibility-target:** for-author

The two daemon starts are treated **symmetrically** — both get `9>&-` — which is the right call and closes the loop-pass fact-check's E1 (the lock outliving the run through an inheriting child). The comment's last sentence reads as the rationale for an asymmetry, so a reader arriving at `:949` and finding `9>&-` on the proxy too has to work out that the sentence is explaining why belt-and-braces was chosen rather than why the two differ. This is the one place in the fix wave where two sibling daemons *were* aligned and the comment still describes them as different. No behavioural consequence. Failure mode: *comment frames a difference the code removed*.
**Recommendation:** Reword to "Both daemons get it: the proxy closes inherited fds itself, dnsmasq is not assumed to, and one rule for both is cheaper to keep true."

---

## What Looks Good

Scoped to what I checked in this range.

- **`--print-entries`'s output contract changed and no consumer broke.** Canonicalisation is a real contract change for anything that reads the hook's `domain<TAB>ports` lines. `route: code-fact-check` — Verified: I re-executed the hook on a fixture (`api.anthropic.com`, `padded.example:0443`, `localhost:11434`, `multi.example:0080,00443,22`) and got `padded.example	443` and `multi.example	80,443,22`; the two in-repo consumers are `test/init-firewall-rules.bats:338-341` (asserts `host.docker.internal	11434` / `openrouter.ai	443` — already canonical, unaffected) and `:835-846` (the new test, which asserts the *new* form and that `tcp:0443` appears zero times in the command log); `cc-isolated.sh` invokes `init-firewall.sh` only via `sudo` and reads its exit status, never its stdout. Not verified: no consumer outside this repo — the hook is documented in `docs/decisions/log.md:57` as a public inspection surface, so a shell one-liner in an operator's notes could be pinned to `0443`; nothing in the tree can see that.
- **F2's fix is a genuine single-source-of-truth, not a re-synchronised copy.** The SNI zone list is now *computed* from `GITHUB_DNS_ZONES` (`init-firewall.sh:936-942`), and the emitted `.${zone}` form matches `cc-sni-proxy.py:126-138`'s zone grammar exactly (`lstrip(".")` into `al.zones`, matched by `name == z or name.endswith("." + z)`). The two lists cannot drift, which is the strongest form of the fix rather than the cheapest.
- **F14's fix asserts the right observable.** Replacing "curl exited non-zero" with `grep -q "REJECT sni=not-allowlisted.invalid " "$SNI_LOG"` moves the probe from "something failed" to "the proxy saw this name and refused it" — the actual proposition the probe exists to establish — and the trailing space in the grep pattern anchors the field so `not-allowlisted.invalid.evil` cannot satisfy it. `route: code-fact-check` — Verified: the pattern and the log format (`log(f"REJECT sni={sni} orig_dst={orig}: not in allowlist")`, `cc-sni-proxy.py:183`) agree on the space; `test/init-firewall-rules.bats:870-875` exercises the failure branch under `SILENT_SNI_NEGATIVE=1`. Not verified: never run against a live proxy — `docs/working/questions.md` carries the live-container check as an open item.
- **The interpreter-pinning split is now clean.** In-container root executables use absolute shebangs (`init-firewall.sh` `#!/bin/bash`, `cc-sni-proxy.py` `#!/usr/bin/python3`) and host-side scripts use `#!/usr/bin/env bash` (`cc-isolated.sh`, `install.sh`, `link-claude-home.sh`). The fix pinned the one that needed pinning and left the three that did not, which is the distinction that matters rather than a blanket sweep.
- **The IPv6 block's guard condition is the consistent one.** `command -v ip6tables && ip6tables -w 5 -S OUTPUT` tests the *capability* rather than the binary, matching how `stop_dnsmasq` tests `/proc/pid/comm` rather than trusting a pidfile and how the daemon preconditions test `id -u` output rather than `getent`. The `NO_IP6_TABLE` stub at `test/init-firewall-rules.bats:195-198` exercises the branch.
- **`link-claude-home.sh` joining `enforcement_files()` is a correct application of the list's own stated rule** rather than an incidental addition: it is `COPY`'d into the image and runs at postStart, so it "defines the boundary" in the same sense the other five members do. The fix closed a gap the prior review had not spotted.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| N1 | dnsmasq hostname grammar is still an inline duplicate of `parse_entry`'s label regex | Inconsistent | `init-firewall.sh:126-134`, `:212-215` | High |
| N2 | `CC_FIREWALL_PATH` names a search list where every sibling `CC_*` names one filesystem object | Minor | `init-firewall.sh:31-38` | High |
| N3 | `CC_FIREWALL_LOCK`/`_LOCK_WAIT` omit the "unit tests only / `env_reset`" annotation every sibling seam carries | Minor | `init-firewall.sh:294-311` | High |
| N4 | Lock-failure message names one cause for a branch with two (bad timeout → wrong diagnosis → DROP) | Minor | `init-firewall.sh:305-308` | High |
| N5 | `enforcement_files()` / `PAYLOAD` declared "in step" but differently ordered and unchecked; 140-char run-on comment line | Minor | `cc-isolated.sh:45-71`, `install.sh:25` | High |
| N6 | `GITHUB_DNS_ZONES` name and definition comment lag its second (SNI) consumer | Minor | `init-firewall.sh:162-171` | High |
| N7 | `IPv6: …` is the only topic-prefixed stdout status line; collides with the `ERROR:`/`WARNING:` prefix family | Minor | `init-firewall.sh:547` | High |
| N8 | Lock file adds a fourth `/run` layout convention and is the only generated file with no explicit mode | Minor | `init-firewall.sh:302-304` | High |
| N9 | `--print-dnsmasq-conf` warns-and-continues where `--print-entries` hard-fails on the same input | Minor | `init-firewall.sh:149-158` vs `:227-230` | High |
| N10 | `9>&-` comment frames an asymmetry the code does not make | Informational | `init-firewall.sh:737-740`, `:948-949` | High |

Carried forward from pass 1, unresolved: **F5/A9** (sibling-daemon shapes — partly fixed, N8 adds to it), **F6/A10**, **F7/C3**, **F8+F9+F10/C4**, **F12/C5**, **F13/C6**. All are logged with an interim decision; none needs to gate the rebuild.

---

## Overall Assessment

The fix wave hit its targets. All six findings it aimed at are closed, and closed the right way rather than the cheap way: F2 and F14 in particular replaced a hand-synchronised duplicate and a proxy-for-a-proposition with a derivation and a direct observable, which is the difference between a fix and a patch. The eight deferrals are all traceable to a rubric row or a `questions.md` entry with an `interim:` line, so the loop's bookkeeping held.

Nothing in this range breaks a consumer. `--print-entries`'s canonicalisation is the one contract change, and I traced its consumers: both bats call sites and the launcher are unaffected, and the launcher reads only the exit status of `init-firewall.sh` anyway. `compose_dnsmasq_conf` accepting single labels is strictly widening. The new `CC_FIREWALL_*` seams are additive and `env_reset`-neutralised in production. `enforcement_files()` gaining two members changes the blessed manifest, which is expected and is exactly the re-bless the user is planning.

The new findings cluster in two places. First, **the fixes documented their invariants but did not mechanise them**: N1 (a comment asserting two regexes are the same grammar instead of deriving it from one) and N5 (a comment asking a reader to keep two lists in step instead of a test doing it) are the same move, and both are one edit away from being enforced rather than asserted — which matters because F1 and F3 were precisely what happens when a hand-maintained correspondence lapses. Second, **the lock surface is under-annotated relative to every other seam in the script**: N3, N4 and N8 are all small, and all three are the kind of thing the surrounding code already does correctly for `CC_EGRESS_*`, `CC_DNSMASQ_*` and `CC_SNI_*`. N2's rename is worth doing now, while the seam has exactly two call sites.

I would fix N1, N3 and N5 in a cleanup commit before the rebuild — all three are comment-or-one-line changes on files already being re-blessed, so they cost one edit rather than a second bless cycle. N2's rename touches a pinned source-text assertion in the bats suite, so it wants its own commit. The rest can wait for whatever wave closes A9 and C3–C6.

## Goal-Alignment Note

- **Answered:** yes — status recorded for all 14 pass-1 findings (6 fixed as targeted, 1 partly fixed, 7 deferred with a traceable interim), plus a name-pattern audit of the 13 new consumer-facing names and 10 findings on the fixes' new surfaces. Report at `docs/reviews/api-consistency-review-2026-09-03-egress-hardening-r2.md`. Executed the `--print-entries` and `--print-dnsmasq-conf` hooks against fixtures to confirm the canonicalisation and single-label contracts and to reproduce N9. Nothing else written; nothing committed.
- **Out of scope:** `test/*.bats`, `guides/cc-isolated-usage.md`, `docs/decisions/log.md`, `docs/working/questions.md` and the rubric — read as consumers/baselines only. Whether IPv6-closed is the right security posture, whether root's redirect exemption is sound, and whether the proxy needs supervision (A5–A8) are security/performance calls, not consistency ones. Fact-check E5 (the `helpers resolve through the pinned PATH` bats test greps source text rather than exercising resolution — `test/init-firewall-rules.bats:892-898`) is a test-strategy concern; I note it here only because that test is what pins `CC_FIREWALL_PATH`'s spelling, which is why N2's rename needs a matching edit there.
- **Escalate:** (a) **N5's missing check** — a bats assertion that `PAYLOAD` ⊆ `enforcement_files()` (exceptions named) is the durable fix for the class F1 belonged to; it is a `test/cc-isolated-functions.bats` change, outside this pass's file scope. (b) **N2's rename** touches `test/init-firewall-rules.bats:897`'s pinned source-text grep — sequence the two edits together or the suite goes red. (c) **F5/A9 is now four axes wide** (env granularity, `/etc` vs `/run` config location, flat-vs-nested runtime paths, stop-prior protocol) with N8 added; it is cheap to *close by decision* ("flat for script-scoped, dir for daemon-scoped; `/etc` for daemon-read config, `/run` for process-read") and expensive to keep re-deciding per commit. (d) **F8 now has the guide ahead of the code** — `guides/cc-isolated-usage.md` describes `FAIL` as "unresolved or unconnectable" while `cc-sni-proxy.py:192` still says "(resolved address not in the ipset?)"; the guide fix made the code the stale half, so C4 is a little more urgent than it was.
