# Architecture Review — egress hardening fix wave d53bf6a..2839e59

Commit: 2839e59

**Scope:** `git diff d53bf6a..2839e59 -- devcontainer-config/` — `init-firewall.sh` (+79 lines net, 948 → 1027), `cc-sni-proxy.py` (shebang + docstring only), `cc-isolated.sh` (`enforcement_files()`), `install.sh` (`PAYLOAD`), `Dockerfile`, `devcontainer.json`, `egress/base.txt`. Read as committed context but not themselves reviewed: `test/init-firewall-rules.bats`, `test/cc-isolated-functions.bats`, `guides/cc-isolated-usage.md`, `docs/decisions/log.md` rows 40–42, `docs/working/questions.md`.
**Date:** 2026-09-03
**Based on:** `docs/reviews/architecture-review-2026-09-03-egress-hardening.md` (on `abbd42d`, findings F1–F9) and `docs/reviews/code-fact-check-report.md` (loop-pass k=1, on `b708266`; all six rubric reds verified closed, E1 lock-fd and E2 bare-ip6tables fixed in 2839e59).

**Trust-boundary cross-reference:** `docs/reviews/security-review-2026-09-03-egress-hardening-r2.md` does not exist at the time of this review (`ls docs/reviews/` shows only the non-r2 `security-review-2026-09-03-egress-hardening.md`). No r2 Trust Boundary Map was available, so no finding below carries a boundary label; the two `**Security implication:**` lines are my own reading and the security critic should overrule me if their map disagrees.

---

## Prior findings status

| Prior # | Finding | Status | Evidence |
|---|---|---|---|
| F1 | `install.sh`'s `PAYLOAD` omits `cc-sni-proxy.py` — build context lacks the file the `Dockerfile` copies | **closed (instance) / open (mechanism, see A1)** | `install.sh:25` now reads `PAYLOAD=(devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py cc-isolated.sh link-claude-home.sh egress claude-home)`; every `COPY` source in `Dockerfile:384-398` (`egress/`, `init-firewall.sh`, `cc-sni-proxy.py`, `link-claude-home.sh`, `claude-home/`) is now present in it. No test or derivation enforces the relation. |
| F2 | Bless manifest covers 4 of 7 installed artefacts | **partially closed** | `enforcement_files()` (`cc-isolated.sh:53-70`) gained `cc-sni-proxy.py` and `link-claude-home.sh`; `claude-home/` is still excluded, now explicitly, with a pointer to `docs/working/questions.md`. See A2. |
| F3 | One profile grammar, three parsers, two languages — divergent on single-label entries | **partially closed** | `compose_dnsmasq_conf`'s regex at `:214` changed `)+$` → `)*$` so it matches `parse_entry:135`; `parse_entry` now emits canonical port numbers (`:142`). The two regexes are still two literals kept equal by a comment, `compose_dnsmasq_conf` still re-derives its domain from the raw entry rather than from `parse_entry` output, and `Allowlist.load` (`cc-sni-proxy.py:129-138`) is unchanged and still validates nothing. See A4. |
| F4 | Two "GitHub zones" lists 700 lines apart, drifted on `.githubassets.com` | **closed** | The SNI writer at `init-firewall.sh:936-942` now loops over `GITHUB_DNS_ZONES` (`:167`), the same variable `compose_dnsmasq_conf:204` consumes; `.githubassets.com` is gone, and `test/init-firewall-rules.bats:746-748` was flipped from pinning it to asserting its absence. One declaration, two consumers. |
| F5 | Start-time script owns two run-time daemon lifetimes, two divergent restart paths, no supervisor | **open** | No `start_or_restart` helper; `stop_dnsmasq` (`:468`) and `stop_prior` (`cc-sni-proxy.py:212`) are unchanged and still differ. The deferral is logged in `questions.md` ("Proxy resilience … add a supervisor or liveness re-check (A6)"). The non-fix now costs something concrete — see A6. |
| F6 | Eight responsibilities in one 948-line privileged script; split blocked by F1/F2 | **open, moved slightly both ways** | The script is now 1027 lines with three more responsibilities (PATH policy `:33-37`, run serialisation `:295-308`, IPv6 policy `:523-550`). The `--print-*` hook seam is intact and gained no new work. F1's close makes the prerequisite for a split cheaper; the added mass makes the split larger. See A8. |
| F7 | Extensions are parallel edits, not registry entries (exempt-uid pair spelled out six times) | **open** | `iptables -t nat -A CC_SNI -m owner --uid-owner … -j RETURN` / `--uid-owner 0 -j RETURN` still appear literally at `:957-958` and `:967-968`, alongside the DNS-side pairs. No `exempt_chain` helper. The IPv6 block added a seventh place where a policy decision is spelled out inline. |
| F8 | Comments cite mutable decision-log row numbers; `Dockerfile:47` already stale | **partially closed** | `Dockerfile:47` now says `#40` (correct). Every other citation is still a row number, and this range demonstrates the mutability again from the other side: row 41's *text* was retro-edited in `docs/decisions/log.md` to describe what #42 changed. |
| F9 | Env-override surface: `CC_SNI_RUN_DIR` derives three paths, `CC_DNSMASQ_*` names each file | **open, widened** | A fourth family arrived — `CC_FIREWALL_PATH` (`:37`), `CC_FIREWALL_LOCK` and `CC_FIREWALL_LOCK_WAIT` (`:303-305`) — in the file-naming shape, and one of them is of a different risk class from the rest. See A5. |

---

## Dependency Map

**Build time (host → image).** Unchanged in shape, corrected in content. `install.sh` copies `PAYLOAD` (8 items, `:25`) to `~/.config/claude-devcontainer/`, then calls `cc-isolated.sh --bless`, which hashes `enforcement_files()` (6 names + two globs, `:53-70`). `devcontainer.json:26` anchors the Docker build context there; `Dockerfile:384-398` `COPY`s five of the items. The three lists are still independent literals, and `test/cc-isolated-functions.bats:26-33`/`:121-129` now restates the same set a fourth time as a fixture. Nothing derives one from another; nothing compares them (`grep -rn PAYLOAD test/` returns one hit, `test/cc-isolated-functions.bats:425`, which only checks that `claude-home` appears).

**Start time.** `sudo init-firewall.sh && link-claude-home.sh`, unchanged. New dependencies acquired in this range:

- `flock` and a root-owned lock file `/run/cc-firewall.lock` on fd 9 (`:303-308`);
- `ip6tables` (optional, capability-probed at `:537`);
- a pinned `PATH` the script sets for itself (`:37`), replacing whatever sudo hands it;
- **the SNI proxy's log-line grammar** — `grep -q "REJECT sni=not-allowlisted.invalid "` at `:1018`.

**Firewall ↔ proxy.** The contract widened. It was: six CLI flags plus "exit 0 only once LISTENING". It is now those, plus the `REJECT sni=<name> ` log format, plus truncate-the-log-on-start semantics (`cc-sni-proxy.py:247`, `O_TRUNC`), plus (belt-and-braces) tolerating `9>&-` on the command line. The allowlist-file grammar is unchanged and still bash-written / Python-read. The proxy is still a leaf that knows nothing of the firewall; the firewall now knows one more thing about the proxy than before.

**Firewall ↔ resolver.** Improved. `GITHUB_DNS_ZONES` (`:167`) is now a single declaration with two consumers (`compose_dnsmasq_conf:204`, the SNI writer `:940`), where it previously had one consumer and one duplicate. It reaches `compose_dnsmasq_conf` as a global, not as a parameter, while that function's other two inputs are parameters.

**Layering.** Root-owned enforcement above node-writable state, unchanged and now asserted rather than assumed: the PATH pin (`:33-37`) removes the script's dependence on sudo's `secure_path`, and `Dockerfile:408-409` chowns/chmods all three `/usr/local/bin` scripts uniformly instead of `chmod +x`-ing two and 0555-ing one. Build-time layering still does not hold for `claude-home/` (A2).

---

## Findings

#### The registry that produced F1 and F2 is unchanged — four hand-maintained copies of one file list, none cross-checked

**Severity:** Structural
**Location:** `devcontainer-config/install.sh:25`, `devcontainer-config/cc-isolated.sh:45-70`, `devcontainer-config/Dockerfile:384-398`, `test/cc-isolated-functions.bats:26-33`
**Move:** 2 (responsibility boundaries), 8 (extension points)
**Confidence:** High
**Evidence:**
> ```
> # Files whose integrity gates a container (re)build. All of them execute host-side
> # or define the boundary. Keep this list in step with install.sh's PAYLOAD: a file
> # that is installed but not hashed is a boundary artefact nobody blessed (the SNI
> # proxy shipped that way once). claude-home/ (the baked skills/hooks payload) is
> # the one PAYLOAD item still outside this list — see docs/working/questions.md. Paths are relative to config_dir.
> ```

(`cc-isolated.sh:45-49`; the enclosing comment runs to `:52` and the function it documents to `:70` — read in full, with `compute_manifest()` `:72-83` and `check_manifest()` `:93-111`.) Against the other declaration of the same set:

> `PAYLOAD=(devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py cc-isolated.sh link-claude-home.sh egress claude-home)`

(`install.sh:25`; the enclosing script runs to `:119` — read, including the copy loop `:98-101` and `chmod +x "$DEST/cc-isolated.sh" "$DEST/init-firewall.sh"` at `:103`, which still names two of the three executables.)

**Legibility-target:** for-orchestrator-synthesis

Both defects F1 and F2 named are gone: `cc-sni-proxy.py` is in the payload, so the `COPY` at `Dockerfile:388` will find it, and it is in the manifest, so host-side tampering with it is caught. What is not gone is the thing that produced them. The fix took the "keep them in step" branch explicitly — the new comment instructs a future author to maintain the duplication by hand — and the duplication grew from three lists to four, because `test/cc-isolated-functions.bats:26-33` now seeds a fixture whose file set is a fifth literal restatement and `:123-128` greps for four of the names. `grep -rn PAYLOAD test/` finds exactly one assertion, and it checks only that `claude-home` is mentioned. So the next enforcement file added to the boundary still defaults to unprotected in whichever list its author forgets, and the diff that adds it still will not show the omission. The cheap single source of truth exists and is one test, not a refactor: a bats case that runs `enforcement_files` against `PAYLOAD` (expanded for `egress/`, excluding `claude-home/` with a named reason) and against the `COPY` sources parsed out of the `Dockerfile` would have failed on `abbd42d` and would fail on the next omission. That is materially cheaper than deriving one list from another across a bash array, a shell function and a Dockerfile.

**Security implication:** the invariant "every enforcement file is hashed into a manifest a human approves" is currently upheld by author discipline plus one comment. Decision 016 (`cc-isolated.sh:15-22`) rests the whole defence-in-depth story on that invariant.

**Recommendation:** Add the cross-check test rather than the derivation. One bats case in `test/cc-isolated-functions.bats` asserting `PAYLOAD ∖ {claude-home} ⊆ enforcement_files()` (with `egress` expanded to its glob) and `{COPY sources in Dockerfile} ⊆ PAYLOAD`, with the `claude-home` exclusion spelled as a named constant so removing it later is a one-line change. Keep the new comment; it is what makes the test's intent legible.

---

#### The manifest's stated invariant is false for the largest executable payload it names

**Severity:** Structural
**Location:** `devcontainer-config/cc-isolated.sh:45-70`, `devcontainer-config/Dockerfile:398`, `:410-413`
**Move:** 3 (module boundary), 4 (layer violations)
**Confidence:** High
**Evidence:**
> ```
>   echo "devcontainer.json"
>   echo "Dockerfile"
>   echo "init-firewall.sh"
>   echo "cc-sni-proxy.py"
>   echo "link-claude-home.sh"
>   echo "cc-isolated.sh"
> ```

(`cc-isolated.sh:56-61`; the function continues with the `egress/*.txt` and `projects/*.profile` globs in the subshell at `:65-69` and closes at `:70` — read.) Against what the payload actually contains:

> ```
>   find /opt/claude-workflows -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod 0555 {} + && \
> ```

(`Dockerfile:413`; the enclosing `RUN` runs `:408-419` — read, along with the `COPY claude-home/ /opt/claude-workflows/` at `:398` and its comment `:391-397`.)

**Legibility-target:** for-orchestrator-synthesis

The comment above `enforcement_files()` says the list is "files whose integrity gates a container (re)build … all of them execute host-side or define the boundary", and now also says `claude-home/` is the one payload item outside it. Both sentences are true and together they falsify the first: `/opt/claude-workflows` is `COPY`ed from the same blessed config directory, and the `Dockerfile` explicitly makes its `*.sh` and `*.py` files executable at 0555 — these are the hooks and skills that run in every session under decision 022. So the largest set of *executables* baked from the blessed config is the one set the bless step does not hash, and a host-side rewrite of a hook there (the npm-postinstall threat decision 016 names) passes `check_manifest()` silently. Unlike F1's failure mode, this one is quiet by construction. The exclusion is a deliberate, logged deferral (`questions.md`, "Should `claude-home/` … join the bless manifest? … `compute_manifest` hashes files by name"), which is why it is not a blocker — but it is logged as an open *question*, not as an accepted risk in `docs/decisions/`, so nothing records that the invariant is knowingly partial.

**Security implication:** this is the residual half of prior F2 and of fact-check E1. `compute_manifest` already `cd`s into the config dir and shells out to `sha256sum` per line (`cc-isolated.sh:81`), so a sorted file walk under `claude-home/` is a shape the existing code supports; the cost is bless-time seconds, not a redesign.

**Recommendation:** Either extend `enforcement_files()` with a sorted `find`-style walk of `claude-home/` (the `.manifest` provenance stamp `install.sh:55-59` writes is already a per-install file, so it hashes naturally), or promote the exclusion from a question to a one-row entry in `docs/decisions/log.md` stating what it costs. Do not leave the comment asserting full coverage while a question mark holds the exception.

---

#### The negative probe made the firewall a parser of the proxy's log format

**Severity:** Coupling
**Location:** `devcontainer-config/init-firewall.sh:1016-1022`, `devcontainer-config/cc-sni-proxy.py:183`, `:247`, `:300`
**Move:** 3 (module boundary), 6 (substitutability), 7 (coupling surface)
**Confidence:** High
**Evidence:**
> ```
> # A failed curl alone is not proof: a missing redirect, a dead proxy, or a broken
> # runuser all fail the same way. The proxy must have SEEN and REFUSED the name.
> if ! grep -q "REJECT sni=not-allowlisted.invalid " "$SNI_LOG" 2>/dev/null; then
>     echo "ERROR: Firewall verification failed - the SNI proxy did not log a refusal for not-allowlisted.invalid (is the 443 redirect in place? see $SNI_LOG)"
>     exit 1
> fi
> ```

(`init-firewall.sh:1016-1021`; the enclosing verification block runs from the `example.com` probe at `:985` to `FIREWALL_COMPLETE=1` at `:1027` — read in full.) The producer:

> `            log(f"REJECT sni={sni} orig_dst={orig}: not in allowlist")`

(`cc-sni-proxy.py:183`; the enclosing `handle()` decision ladder runs `:176-194` and emits `REJECT` without an `sni=` field at `:180`, `FAIL` at `:192`, `ALLOW` at `:194` — read, with `log()` `:157` and `daemonize()`'s `O_TRUNC` open at `:247`.)

**Legibility-target:** for-author

The verification strengthening is right — a curl that fails for the wrong reason was genuinely indistinguishable from a working boundary, and this is the check that makes the SNI proxy's *presence* observable. The structural cost is that it consumes the one part of the proxy nobody had declared as an interface. Prior review's What-Looks-Good entry said, verbatim, that "nothing in the firewall … reads the proxy's log format"; that is no longer true, and the substitutability claim shrank with it: a replacement SNI filter must now honour six flags, the exit-status contract, `REJECT sni=<name> ` with a trailing space, *and* truncate its log on start — because a log that appended across runs would let a stale line from the previous run satisfy the grep. Three of those four are documented on the proxy side (`--log` help text at `:300` says "truncated on start"); none is documented on the firewall side, where the grep reads as an implementation detail. `guides/cc-isolated-usage.md:296-304` now documents the same vocabulary for humans, making it a three-consumer format.

**Recommendation:** Name the contract where it is depended on. A one-line comment at `:1016` ("the proxy's log grammar is a contract: `REJECT sni=<name> `, log truncated per start — see `cc-sni-proxy.py:183`/`:247`") is enough; better, have the proxy expose the refusal count or a machine-readable line the firewall greps, so the human-facing wording can change without breaking the boundary check.

---

#### F3's grammar residue: one grammar, still three implementations, now equal by comment

**Severity:** Coupling
**Location:** `devcontainer-config/init-firewall.sh:135`, `:212-217`, `:204`, `devcontainer-config/cc-sni-proxy.py:129-138`
**Move:** 5 (interface segregation), 7 (coupling surface), 8 (extension points)
**Confidence:** High
**Evidence:**
> ```
>     # Same label grammar as parse_entry (a single label is allowed there, so it must
>     # be allowed here too — otherwise an entry can be ipset-admitted yet unresolvable).
>     if [[ ! "$d" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)*$ ]]; then
> ```

(`init-firewall.sh:212-214`; the enclosing `compose_dnsmasq_conf()` runs `:187-223` — read in full, including the `for d in $(printf '%s\n' "$domains"; echo "$GITHUB_DNS_ZONES" | tr ' ' '\n')` at `:204` and the `d="${d%%:*}"` port strip at `:210`.) Against the canonicalisation the other consumers get:

> ```
>     canon="${canon:+$canon,}$((10#$port))"
> ```

(`init-firewall.sh:142`; the enclosing `parse_entry()` runs `:116-147` and ends at the tab-separated `printf` at `:146` — read.)

**Legibility-target:** for-author

The observable divergence F3 named is fixed, and the port canonicalisation is a real improvement: `0443` now becomes `443` once, at the single place that parses, instead of failing textual comparisons in two downstream consumers. But the two regexes are still two literals in two functions, kept identical by a comment that asks the reader to check — the third-copy problem became a second-copy problem with a note. More telling, `compose_dnsmasq_conf` still takes `compose_domains` output (raw entries) and re-derives the domain with `${d%%:*}` at `:210`, while the ipset loop and the SNI writer both consume `ALLOWED_ENTRIES` (`parse_entry` output). So of three consumers, two now share a canonical form and one re-parses; a future grammar change (the `udp/1234` suffix `:113-115` anticipates) still needs edits in two bash functions and one Python reader, and `Allowlist.load` (`cc-sni-proxy.py:129-138`) is unchanged, still accepts a bare `.` line as an empty zone, and still validates nothing. Separately, `compose_dnsmasq_conf` reads `GITHUB_DNS_ZONES` as a global while its other two inputs arrive as parameters, so the `--print-dnsmasq-conf` hook's output depends on state its signature does not mention.

**Recommendation:** Feed `compose_dnsmasq_conf` the parsed entries (or a `domains-only` projection of them) instead of the raw ones, which deletes the second regex and the `${d%%:*}` strip in one move; pass `GITHUB_DNS_ZONES` as a third parameter so the function is total in its arguments. Leave `Allowlist.load` for the fixture round-trip test the prior review recommended.

---

#### `CC_FIREWALL_PATH` joins the "tests only" override family but is not the same kind of switch

**Severity:** Coupling
**Location:** `devcontainer-config/init-firewall.sh:31-37`, `:303-305`, `:475-480`, `:395-396`
**Move:** 3 (module boundary), 5 (interface segregation)
**Confidence:** High
**Evidence:**
> ```
> # Root-owned helper resolution only. Everything this script runs as root — iptables,
> # ipset, dig, curl, runuser, dnsmasq, the proxy — is found via PATH, and `node`'s own
> # PATH includes the node-writable /usr/local/share/npm-global/bin. sudo's env_reset
> # and secure_path normally protect this, but nothing in the repo asserts that, so
> # the script pins PATH itself. CC_FIREWALL_PATH exists only so the unit tests can
> # put their stubs first; under sudo env_reset `node` cannot set it.
> export PATH="${CC_FIREWALL_PATH:-/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin}"
> ```

(`init-firewall.sh:31-37`; the enclosing prologue is `:29-40`, immediately after `set -euo pipefail` and before the first `EGRESS_DIR` assignment — read.) Against the family it joins:

> ```
> FIREWALL_LOCK="${CC_FIREWALL_LOCK:-/run/cc-firewall.lock}"
> exec 9>"$FIREWALL_LOCK"
> if ! flock -w "${CC_FIREWALL_LOCK_WAIT:-120}" 9; then
> ```

(`init-firewall.sh:303-305`; the enclosing block is the comment `:295-302` plus the error exit `:306-308` — read.)

**Legibility-target:** for-author

The pin itself is the right call and the right layer: the script is the only privileged entry point, so it should not depend on a sudo configuration that lives in a `Dockerfile` line 380 lines away and is asserted nowhere. The interface problem is that the override family now spans two risk classes with one convention. `CC_EGRESS_DIR`, `CC_DNSMASQ_CONF`, `CC_SNI_RUN_DIR`, `CC_FIREWALL_LOCK` all relocate one artefact; if the "sudo strips it" premise ever failed for one of them the blast radius is one file. `CC_FIREWALL_PATH` selects *every binary the script executes as root* — `iptables`, `ipset`, `dig`, `curl`, `runuser`, `dnsmasq` and the proxy — so the same premise failing there is total. Nothing in the interface distinguishes them: same `CC_` prefix, same "for the unit tests only" comment, same silent-default shape. The premise is currently asserted only in prose (`:34-37`, `:86`, `:429`, `Dockerfile:404`); the sudoers line written at `Dockerfile:418` is `node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh` with no `SETENV` and no `env_keep`, so the premise does hold today. F9's original complaint (two shapes for one job) is untouched: the SNI side still derives three paths from one directory override, the dnsmasq side still names two files, and the firewall side now names three independent scalars.

**Security implication:** if any future `Defaults env_keep` or a non-sudo invocation path is added, `CC_FIREWALL_PATH` is the one override that converts to arbitrary root code execution. It deserves a defence the others do not need — e.g. honouring it only when `[ -n "${BATS_TEST_FILENAME:-}" ]`, or refusing it when `$SUDO_USER` is set.

**Recommendation:** Gate `CC_FIREWALL_PATH` on an explicit test marker rather than on the absence of an attacker, and add the missing assertion the comment says does not exist: a bats case that greps the generated sudoers line for the absence of `SETENV`/`env_keep`. Separately, converge the three override shapes on `*_RUN_DIR` when F9 is eventually taken.

---

#### Two daemon start sites each carry their own fd-9 hygiene, because F5's helper was never factored

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:734-740`, `:948-952`, `:303-308`
**Move:** 2 (responsibility boundaries), 8 (extension points)
**Confidence:** High
**Evidence:**
> ```
> stop_dnsmasq
> # 9>&-: do NOT hand the firewall lock (fd 9, see the flock block) to the daemon —
> # a long-lived holder would make every later run wait out CC_FIREWALL_LOCK_WAIT and
> # fail closed. The proxy closes inherited fds itself; dnsmasq is not assumed to.
> dnsmasq --conf-file="$DNSMASQ_CONF" --pid-file="$DNSMASQ_PIDFILE" 9>&-
> ```

(`init-firewall.sh:734-738`; the enclosing resolver block continues with the pidfile wait `:739-746` — read, along with `stop_dnsmasq()` at `:468` and the proxy start at `:948-952` where the same `9>&-` is appended.)

**Legibility-target:** for-author

Closing the lock fd at each daemon start is correct — fact-check E1 was a real bug, and the comment's claim about the proxy is accurate (`cc-sni-proxy.py:270-276` closes every inherited fd above 2 in the child). But it is now a per-call-site obligation attached to a magic fd number, and the reason it is per-site is that prior F5's `start_or_restart <pidfile> <uid> <cmd...>` helper was not built. A third long-running process started from this script inherits fd 9 by default and its author has to know about a `flock` 400 lines earlier; the failure is not a crash but a 120-second stall followed by a fail-closed run, i.e. "the container has no network" reported at the wrong layer. The same non-factoring keeps the two restart paths divergent, which is F5 as filed and remains open.

**Recommendation:** When F5 is taken, make the helper own both the `9>&-` and the pidfile/uid-sweep logic, so neither can be forgotten per site. Until then, note the obligation next to the `exec 9>` line at `:304`, not only at the two consumers.

---

#### The IPv6 policy is a phase-B decision whose precondition is checked in phase B

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:523-550`, `:389-407`, `:475-491`
**Move:** 2 (responsibility boundaries), 4 (layer violations)
**Confidence:** Medium
**Evidence:**
> ```
> if command -v ip6tables >/dev/null 2>&1 && ip6tables -w 5 -S OUTPUT >/dev/null 2>&1; then
>     ip6tables -P INPUT DROP
> ```

(`init-firewall.sh:537-538`; the enclosing block is the comment `:523-536` plus the rule installs `:539-546`, the confirmation `:547` and the warning else-branch `:548-550` — read, in the context of the phase-B header at `:493-495` and the IPv4 policy/flush at `:510-521`.)

**Legibility-target:** for-orchestrator-synthesis

The IPv6 close is the right design decision and the guard is the right guard — a bare `ip6tables -P` on a kernel without an IPv6 filter table would abort into the fail-closed trap and leave a working container with no egress, which is a worse outcome than the gap being closed. Two placement notes. First, the script's own convention is that preconditions are hoisted into phase A precisely so a broken environment aborts with the live ruleset intact (`:389-407` for dnsmasq, `:475-491` for the proxy); this capability probe is a purely local read that could sit with them but does not, so the phase split now has one exception and a reader cannot infer the rule from the code. Second, this is the only control in the script that degrades to a `WARNING` and continues — everything else is fail-closed — and the warning goes to stderr in a `postStartCommand` chain nobody reads on a successful launch, so a container silently running with unfiltered IPv6 looks exactly like one that is fully protected. Neither is a break of phase A's actual contract ("no network reads past this point"), which is why this is Minor.

**Recommendation:** Move the `command -v ip6tables && ip6tables -S OUTPUT` probe into the phase-A precondition block and set a `HAVE_IP6=1` flag the phase-B block consumes, so the phase split has no exception. Consider surfacing the degraded case in the final success line (`:1022`) rather than only on stderr, so "IPv6 unfiltered" is visible where the operator looks.

---

#### The future split of `init-firewall.sh` got cheaper in its prerequisite and larger in its subject

**Severity:** Informational
**Location:** `devcontainer-config/init-firewall.sh` (whole file), `devcontainer-config/install.sh:25`, `devcontainer-config/cc-isolated.sh:53-70`
**Move:** 2 (responsibility boundaries), 8 (extension points)
**Confidence:** Medium
**Evidence:**
> `if [ "${1:-}" = "--print-dnsmasq-conf" ]; then`

(`init-firewall.sh:225`; the last of the four early-exit hooks, closing at `:228`, all still ahead of the `trap` at `:292` and the lock at `:304` — read through both.)

**Legibility-target:** for-orchestrator-synthesis

Answering the prior review's own question: net, the split is slightly easier. Prior F6 said the blocker was that a new sourced file must be added to three lists and this range proved all three do not reliably happen; that specific failure has now happened once, been caught, and been fixed, and the same three lists are the same three lists — so the cost is unchanged in mechanism but the risk is now visible and one cheap test (A1) removes it. Against that, the script grew 79 lines and three responsibilities, and the two new ones that would *not* move into a pure-composition lib — the lock and the PATH pin — are correctly placed at the top of the privileged script, so they do not complicate the extraction of `compose_domains` / `compose_dns_resolvers` / `parse_entry` / `compose_dnsmasq_conf`. The hook seam is intact: all four `--print-*` hooks still exit before both the trap and the lock, so a test invocation still cannot take the lock or alter the boundary. One new wrinkle for the eventual split: the PATH pin at `:37` runs before the hooks, so any extracted lib must be sourced after it or tests will resolve helpers differently from the script.

**Recommendation:** No action now. When F6 is taken, extract the four composition functions only, and source the lib after the PATH pin.

---

## What Looks Good

- **F4 is closed the way a coupling finding should be closed — by deletion, not by synchronisation.** `GITHUB_DNS_ZONES` at `:167` is now the single declaration, consumed by `compose_dnsmasq_conf:204` and by the SNI writer's `for zone in $(echo "$GITHUB_DNS_ZONES" | tr ' ' '\n')` at `:940`; the dead `.githubassets.com` entry is gone and the bats assertion that pinned it was inverted to assert its absence (`test/init-firewall-rules.bats:746-748`). The resolver list is the right direction of dependency: a name the proxy admits can now never be one the resolver refuses, and the reverse (a resolvable zone the proxy rejects) fails safe. *(route: code-fact-check — Verified: Claim 13 covers the derivation and the drift-impossibility. Not verified: that `GITHUB_DNS_ZONES` is still the right *content* for git/gh/git-lfs, which is an allowlist-completeness question, not a structural one.)*
- **The lock is in the right layer.** `init-firewall.sh` is the only entry in `/etc/sudoers.d/node-firewall` and is reached from three directions (`devcontainer.json`'s `postStartCommand`, `cc-isolated.sh`'s re-assert path, and a manual `sudo` by `node`), so serialising in the launcher would have covered one of the three. Taking it in the script covers all of them, and taking it *after* the trap at `:292` and *before* any iptables call at `:510` means a lock failure ends at DROP rather than at an untouched half-state. *(route: code-fact-check — Verified: Claims 1a and 1b cover both the ordering and the fail-closed exit. Not verified: that the described interleaving is the real one — the fact-check explicitly scopes that out as rationale.)*
- **The `Dockerfile` permission fix removed an asymmetry rather than adding a case.** `:408-409` now chowns and 0555s all three `/usr/local/bin` scripts in one pair of commands, where the prior form `chmod +x` on two and a separate `chown`/`chmod 0555` on the third left `init-firewall.sh` and `link-claude-home.sh` at whatever mode the build context carried. One rule for one class of artefact.
- **Canonicalising ports at the parser is the correct owner.** `parse_entry:142` emits `$((10#$port))` once, so the two textual comparisons downstream (`ipset add … tcp:$port`, and `case ",$ports," in *,443,*` at `:934`) cannot disagree with the profile. This is the small version of the fix A4 asks for on the domain half. *(route: code-fact-check — Verified: Claims 10 and 11 cover the canonicalisation and the textual-comparison premise.)*
- **The proxy's docstring now describes the boundary it actually sits in** — root exemption, dnsmasq-not-resolv.conf resolution, IPv6 default-deny, and its own registry membership (`cc-sni-proxy.py:1-30`). It remains a leaf with no knowledge of the firewall, which is the one direction that matters.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| A1 | F1/F2's mechanism unchanged: four hand-maintained copies of the enforcement file list, no cross-check | Structural | `install.sh:25`, `cc-isolated.sh:45-70`, `Dockerfile:384-398`, `test/cc-isolated-functions.bats:26-33` | High |
| A2 | `claude-home/` (`/opt/claude-workflows`, executable hooks at 0555) is outside the bless manifest while the manifest's comment asserts full coverage | Structural | `cc-isolated.sh:45-70`, `Dockerfile:398`, `:410-413` | High |
| A3 | The negative probe made the firewall a parser of the proxy's log grammar and of its truncate-on-start semantics — undeclared contract, narrower substitutability | Coupling | `init-firewall.sh:1016-1022`, `cc-sni-proxy.py:183`, `:247` | High |
| A4 | F3 residue: two identical regexes kept equal by comment; `compose_dnsmasq_conf` still re-parses raw entries and reads `GITHUB_DNS_ZONES` as a global; `Allowlist.load` unvalidated | Coupling | `init-firewall.sh:135`, `:204`, `:212-217`, `cc-sni-proxy.py:129-138` | High |
| A5 | `CC_FIREWALL_PATH` shares the "tests only" override convention with file-relocation overrides but selects every root-executed binary | Coupling | `init-firewall.sh:31-37`, `:303-305` | High |
| A6 | `9>&-` is a per-call-site obligation at two daemon starts because F5's lifecycle helper was never factored | Minor | `init-firewall.sh:734-740`, `:948-952` | High |
| A7 | IPv6 capability probe sits in phase B, breaking the phase-A precondition convention; the degraded path is the script's only warn-and-continue control | Minor | `init-firewall.sh:523-550` | Medium |
| A8 | The eventual F6 split: prerequisite unchanged in mechanism but de-risked; subject grew 79 lines / 3 responsibilities; hook seam intact | Informational | `init-firewall.sh` (whole file) | Medium |

---

## Overall Assessment

**Both prior Structural findings are closed as filed.** F1's build failure is gone — `cc-sni-proxy.py` is in `PAYLOAD` and every `Dockerfile` `COPY` source is now covered, so the rebuild this review gates will not fail at `COPY`. F2's headline instance is gone too: the proxy and `link-claude-home.sh` are hashed, and `test/cc-isolated-functions.bats:123-128` now asserts both appear in the manifest. F4 is fully closed and closed well, by collapsing two lists into one declaration rather than by keeping them in sync. F3 is genuinely improved (the observable single-label divergence is fixed; ports canonicalise at the parser). The two fixes the fact-check escalated — the inherited lock fd and the bare `ip6tables` calls in the trap — are both handled.

**Two Structural findings remain open, and neither blocks the rebuild.** A1 is the generalisation of F1/F2: the fix took the "keep the lists in step by hand" branch, wrote that instruction into a comment, and the duplication grew to four restatements with nothing comparing them — so the *next* enforcement file still defaults to unprotected and the omission is still invisible in the diff that causes it. This is latent, not active: every list is correct at `2839e59`. A2 is F2's residual half — `/opt/claude-workflows`, the executable skills-and-hooks payload that governs every session, is `COPY`ed from blessed config but never hashed, while the comment above `enforcement_files()` claims the list covers everything that defines the boundary. That exclusion is deliberate and logged, but logged as an open question rather than as an accepted risk, so nothing on the record says the invariant is knowingly partial.

My read for the gate: **proceed with `install.sh` → rebuild → `--bless`.** Neither open Structural finding is a defect in the shipped state; both are about what happens to the *next* change. The cheapest close for A1 is one bats case (`PAYLOAD ⊆ enforcement_files ⊆ COPY sources`, with `claude-home` a named exclusion), which would have caught the original F1 and F2 on `abbd42d` and is materially cheaper than deriving one list from another across a bash array, a shell function and a `Dockerfile`. A2 wants either the file walk or a one-row decision entry — and the comment should stop asserting coverage it does not have either way.

Among the new coupling, A3 is the one to watch: it is the only place this wave made the architecture *more* coupled rather than less. The verification strengthening was right and needed, but it turned the proxy's human-facing log wording into a boundary contract, and the prior review's "nothing in the firewall reads the proxy's log format" is no longer true. Declare it or replace it with something machine-readable before someone rewords a log line. A4 and A5 are residues to take when F3/F9 are taken; A6 and A7 are small and both fold into work already scheduled (F5, and the phase-A convention).

Recommended order: A1's test (cheap, closes the mechanism behind both prior Structural findings) → A3's contract declaration → A2's decision-or-walk → A5's test-marker gate → A4/A6/A7 with the F3/F5/F9 pass.

## Goal-Alignment Note
- Answered: yes. F1 and F2 verified closed as filed with evidence (the gate for the "block on architectural review" next-action); all nine prior findings given a status row; the five specific structural questions answered — (1) registry patched not solved, one cheap test named, `claude-home/` treated as a Structural residue rather than an accepted one because the acceptance is only a question; (2) the three new responsibilities respect phase A/B and the trap ordering, with the IPv6 probe the one placement exception (A7), and the lock is in the right layer; (3) the override pattern is coherent in naming but now spans two risk classes (A5); (4) resolver → proxy is the right direction and F4 is fully closed, with the residual duplication being `compose_dnsmasq_conf`'s raw-entry re-parse, not the port filter (A4); (5) the split got net easier, hook seam intact (A8).
- Out of scope: verification *strength* of the new negative probe (whether a logged REJECT proves the redirect — security's call), IPv6 default-deny as a policy choice, ClientHello parsing, allowlist content, the test suite's own design (the new "helpers resolve through the pinned PATH" case asserts by grepping a literal source line, which is test-strategy's concern), and the decision-log row-collision process issue. No r2 Trust Boundary Map existed, so no finding carries a boundary label.
- Escalate: (1) **A3 is a new coupling introduced by a fix** — the firewall now greps the proxy's log grammar and depends on its truncate-on-start behaviour; this contradicts a positive from the prior pass and should be declared before the next proxy change. (2) **A1 is one bats case away from closing the mechanism behind both prior Structural findings** — recommend it as the single follow-up rather than a registry refactor. (3) **A2 needs a decision, not a question** — `claude-home/`'s exclusion should move from `questions.md` to `docs/decisions/log.md`, or the comment at `cc-isolated.sh:45-49` should stop claiming full coverage. (4) A5 has a security dimension (`CC_FIREWALL_PATH` selects every root-executed binary) that the security re-review should confirm or overrule.
