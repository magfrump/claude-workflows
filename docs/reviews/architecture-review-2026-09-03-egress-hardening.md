# Architecture Review — egress hardening bd41aef..abbd42d

Commit: abbd42d

**Scope:** `git diff bd41aef..HEAD -- devcontainer-config/` — `init-firewall.sh` (664/948 lines changed, evaluated as greenfield), `cc-sni-proxy.py` (new), `Dockerfile`, `devcontainer.json`, `egress/base.txt`, `egress/llm.txt`. Read for context but not reviewed: `cc-isolated.sh`, `install.sh`, `link-claude-home.sh`, `test/init-firewall-rules.bats`, `test/test_cc_sni_proxy.py`, decision records 016/022/023/034 and `docs/decisions/log.md` rows 39–41. Pass 1 of a split review (enforcement files); tests/docs are a later pass.
**Date:** 2026-09-03
**Based on:** docs/reviews/code-fact-check-report.md (k=3 merged)

**Trust-boundary cross-reference:** `docs/reviews/security-review-2026-09-03-egress-hardening.md` does not exist at the time of this review (`ls docs/reviews/security-review-*.md` returns only the 2026-07-30/07-31/08-19 files and the two 2026-08-29 cc-isolated files). No Trust Boundary Map was available, so no finding below carries a boundary label. Where a recommendation would move a crossing I have added a `**Security implication:**` line on my own reading; the security critic should overrule me if their map disagrees.

---

## Dependency Map

**Build time (host → image).** `install.sh` copies a fixed `PAYLOAD` list from the repo to `~/.config/claude-devcontainer/`, then calls `cc-isolated.sh --bless`, which hashes a *second* fixed list (`enforcement_files()`). `devcontainer.json` anchors the Docker build context to that directory; the `Dockerfile` `COPY`s a *third* set of names out of it. The three lists are independent literals — nothing derives one from another, and no test compares them.

**Start time (postStartCommand).** `sudo init-firewall.sh && link-claude-home.sh`. `init-firewall.sh` is the only path in `/etc/sudoers.d/node-firewall`, so it is the single privileged entry point. Its new outbound dependencies:

- binaries: `curl`, `jq`, `aggregate`, `dig`, `ip`, `iptables`, `ipset`, plus **new**: `dnsmasq`, `pkill`, `runuser`, and the proxy executable at a fixed path (`SNI_PROXY_BIN`, `:437`), invoked directly rather than through `python3` on PATH;
- system users: `dnsmasq` and `ccproxy`, resolved to numeric uids at `:403` and `:449` (created in the `Dockerfile` at `:51-57`), plus `node` for the two probes;
- filesystem layout: `/etc/dnsmasq.d/`, `/run/cc-sni-proxy/`, `/etc/resolv.conf`, `/etc/cc-egress-profile`, `/usr/local/share/cc-egress/`;
- Docker's own nat state, captured by `iptables-save -t nat | grep 127.0.0.11` (`:460`) and replayed after the flush.

**Who depends on `init-firewall.sh`.** `cc-isolated.sh` (invokes it as the re-assert path at `:420` and reads only its exit status); `devcontainer.json`'s `postStartCommand`; and `test/init-firewall-rules.bats`, which depends on four `--print-*` hooks *and* on the exact argv strings the script passes to stubbed `iptables`/`ipset`/`dnsmasq`/`cc-sni-proxy`.

**Firewall ↔ proxy.** The coupling is bidirectional and neither direction is declared anywhere:

- firewall → proxy: the CLI contract (`--daemon --pidfile --user --listen --allowlist --log`) and the exit-status contract ("0 only once LISTENING", `cc-sni-proxy.py:236-239`);
- proxy → firewall: the generated allowlist file at `$SNI_RUN_DIR/allowlist`, whose grammar (`name` / `.zone`) is written by bash at `init-firewall.sh:857-869` and parsed by Python at `cc-sni-proxy.py:129-138`. The same shape recurs for dnsmasq: `compose_dnsmasq_conf` (`:174-208`) generates a config whose consumer is an external binary.

The stable direction is the proxy: it is a leaf that takes a file and a port and knows nothing about profiles, ipsets, or iptables. The firewall is the unstable side, and it currently owns both halves of both generated contracts.

**Layering.** Root-owned enforcement (`/usr/local/bin/*`, `/usr/local/share/cc-egress`, `/etc/cc-egress-profile`, all 0444/0555) sits above node-writable state (`/workspace`, `/home/node/.claude`, `/home/node/.cargo`). The two generated files are root-written into root-owned directories, so the layering holds at run time. It does **not** hold at bless time — see F2.

---

## Findings

#### The new module never reaches the build context: `install.sh`'s `PAYLOAD` omits `cc-sni-proxy.py`

**Severity:** Structural
**Location:** `devcontainer-config/install.sh:25`, `devcontainer-config/Dockerfile:389`
**Move:** 1 (dependency direction), 3 (module boundary)
**Confidence:** High
**Evidence:**
> `PAYLOAD=(devcontainer.json Dockerfile init-firewall.sh cc-isolated.sh link-claude-home.sh egress claude-home)`

(`install.sh:25`; the enclosing script continues to `:119` — read in full, including the copy loop at `:98-101` and the `chmod +x` at `:103`, which also names only `cc-isolated.sh` and `init-firewall.sh`.) Against:

> `COPY cc-sni-proxy.py /usr/local/bin/`

(`Dockerfile:389`; the enclosing `COPY` group runs `:384-399` — read.)

**Legibility-target:** for-author

`install.sh` is the only writer of `~/.config/claude-devcontainer/`, and `devcontainer.json:26` sets that directory as the Docker build context. A file absent from `PAYLOAD` is absent from the context, so `COPY cc-sni-proxy.py` fails the build outright on any host that installs from a clean state — which is exactly the "rebuild the image and re-bless" step this review precedes. `install.sh` is unchanged in this range, so this is not a stale-file artefact: the new module was added to the consumer (`Dockerfile`) without being added to the producer. The failure mode is *docker build: file not found*, not a silent boundary weakening, so it is loud — but it means the enforcement pipeline's file set has no single owner, and the same omission repeated on a file that *is* already present host-side would be silent. Failure mode in one phrase: **three hand-maintained copies of one file list**.

**Recommendation:** Add `cc-sni-proxy.py` to `PAYLOAD`. Better, derive the three lists from one: have `install.sh` and `cc-isolated.sh` read a single `enforcement-files` manifest (a plain list file in `devcontainer-config/`) that `enforcement_files()` also consumes, and add a test asserting every `COPY` source in the `Dockerfile` appears in it.

---

#### The bless manifest covers four of the seven artefacts it is supposed to gate

**Severity:** Structural
**Location:** `devcontainer-config/cc-isolated.sh:50-65`
**Move:** 3 (module boundary)
**Confidence:** High
**Evidence:**
> ```
>   echo "devcontainer.json"
>   echo "Dockerfile"
>   echo "init-firewall.sh"
>   echo "cc-isolated.sh"
> ```

(`cc-isolated.sh:53-56`; excerpt ends mid-function — the remainder of `enforcement_files()` is the `local f` declaration and the subshell globbing `egress/*.txt` and `projects/*.profile`, closing at `:65` — read, along with `compute_manifest()` `:67-78` and `check_manifest()` `:88-106`.)

**Legibility-target:** for-orchestrator-synthesis

Fact-check Claim 10 (Incorrect, High) reports that `cc-sni-proxy.py` is outside the manifest, and escalation E1 addresses it here. The architectural reading is that the proxy is not an exception — it is the third instance of the same gap. `PAYLOAD` ships seven items into the build context; `enforcement_files()` hashes four of them. `link-claude-home.sh` (a start-time executable that runs as `node` and populates `~/.claude`) and `claude-home/` (which becomes `/opt/claude-workflows` — the skills and hooks that govern every in-container session, per decision 022) are both installed, both unhashed. So the boundary the whole design rests on — "every enforcement file is hashed into a manifest a human approves" — is in practice "every file someone remembered to list", and the list is a literal in a function that no test constrains. The consequence for changeability is that each new enforcement artefact silently defaults to *unprotected*, and the defect is invisible in the diff that adds it (this range's diff touches no file that would show the omission).

**Security implication:** widening `enforcement_files()` moves a trust crossing — host-side tampering with `cc-sni-proxy.py`, `link-claude-home.sh` or `/opt/claude-workflows` currently passes `check_manifest()` unnoticed. Decision 016 (`:118-123`) is explicit that the manifest is defence-in-depth against *host-side* tampering, which is precisely the threat these three omissions leave open.

**Recommendation:** Make the manifest derive from the install payload rather than restate it — hash every installed path (recursing `claude-home/`) with an explicit, commented exclusion list for genuinely host-owned state (`projects/` is already handled by a glob, and `manifest.sha256` itself must be excluded). Re-bless afterwards. If a full recursion over `claude-home/` is too slow, hash the `.manifest` provenance stamp `install.sh:55-59` already writes plus a tree digest.

---

#### One profile grammar, three parsers, two languages — and they already disagree

**Severity:** Coupling
**Location:** `devcontainer-config/init-firewall.sh:116-134`, `:191-206`, `devcontainer-config/cc-sni-proxy.py:129-138`
**Move:** 7 (coupling surface), 8 (extension points)
**Confidence:** High
**Evidence:**
> ```
>   label='[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?'
>   domain="${entry%%:*}"
> ```

(`init-firewall.sh:118-119`; excerpt ends inside `parse_entry()`, which continues through the port-range loop to the `printf` at `:133` and the closing brace at `:134` — read.) Against the second grammar:

> `    if [[ ! "$d" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)+$ ]]; then`

(`init-firewall.sh:199`; enclosing `compose_dnsmasq_conf()` runs `:174-208` — read.) And the third:

> `                (al.zones if line.startswith(".") else al.exact).add(line.lstrip("."))`

(`cc-sni-proxy.py:137`; enclosing `Allowlist.load` runs `:129-138`, returning `al` at `:138` — read.)

**Legibility-target:** for-author

Escalation E7 flags this as a code-quality cluster; structurally it is a coupling surface with a demonstrated divergence. `parse_entry`'s domain regex is `label(\.label)*` — a single label passes. `compose_dnsmasq_conf`'s is `label(\.label)+` — a single label is rejected with a warning. So a one-label profile entry (`localhost`, an internal short name) is admitted into the ipset and written into the SNI allowlist but gets no `server=` line, i.e. it is routable and SNI-approved yet unresolvable: three components disagree about whether the same line is valid. `Allowlist.load` is a third grammar with no validation at all — it accepts whatever bash wrote, including a bare `.` line, which becomes an empty zone that `allows()` would match against `name.endswith(".")`. The evolvability cost is that a change to the entry grammar (adding `udp/1234`, as `:113-115` anticipates) requires three coordinated edits in two languages, and nothing fails if you make only two.

**Recommendation:** Give the grammar one owner. Have `parse_entry` emit the *canonical* triple (`domain`, `ports`, `dns-eligible`) once, and make both generators consume that output rather than re-deriving the domain from the raw entry; then reduce `Allowlist.load` to a reader of a format the firewall promises, with an assertion (or a shared fixture test) that the firewall-generated file round-trips through it.

---

#### Two "GitHub zones" lists 700 lines apart, already drifted

**Severity:** Coupling
**Location:** `devcontainer-config/init-firewall.sh:154`, `:864-869`
**Move:** 7 (coupling surface), 8 (extension points)
**Confidence:** High
**Evidence:**
> `GITHUB_DNS_ZONES="github.com githubusercontent.com"`

(`init-firewall.sh:154`; the preceding comment block `:147-153` explains the list, and the variable's only consumer is the loop at `:191` — read.) Against:

> ```
>     echo ".github.com"
>     echo ".githubusercontent.com"
>     echo ".githubassets.com"
> } > "$SNI_ALLOWLIST"
> ```

(`init-firewall.sh:866-869`; excerpt ends at the redirect closing the group command opened at `:857`; the enclosing SNI block continues through `chmod 0444` at `:870` and the daemon start at `:874-879` — read.)

**Legibility-target:** for-author

Fact-check Claim 36 (Incorrect, Medium) establishes the behavioural consequence: `.githubassets.com` is SNI-allowlisted but has no resolver zone, so it can never resolve and the entry is dead config. Architecturally the interesting part is that the drift appeared *in the same commit range that created the second list* — the two lists were never simultaneously correct. They encode one concept ("the GitHub zones this boundary admits by name") and are separated by 700 lines, one as a space-separated shell variable, the other as literal `echo`s with a `.` prefix convention the other list does not use. A third representation of the same concept — the CIDR ingest from `api.github.com/meta` at `:332` — decides what is *routable*, so "GitHub reachability" is now spread across three mechanisms with no single place to read it off. `test/init-firewall-rules.bats:727` pins the current (inert) entry, so the drift is now load-bearing on a test.

**Recommendation:** Collapse to one declaration — e.g. `GITHUB_ZONES="github.com githubusercontent.com"` consumed by both the dnsmasq loop (bare) and the SNI writer (dot-prefixed) — and decide `.githubassets.com` in that one place (drop it, or add it and correct the "git, gh and git-lfs contact" attribution, which `:150-153` already contradicts). Update the pinned bats assertion in the same change.

---

#### The start-time script has become a process supervisor with no run-time owner

**Severity:** Coupling
**Location:** `devcontainer-config/init-firewall.sh:661-678`, `:852-879`, `devcontainer-config/cc-sni-proxy.py:212-232`
**Move:** 2 (responsibility boundaries), 4 (layer violations)
**Confidence:** Medium
**Evidence:**
> ```
> stop_dnsmasq
> dnsmasq --conf-file="$DNSMASQ_CONF" --pid-file="$DNSMASQ_PIDFILE"
> ```

(`init-firewall.sh:667-668`; the enclosing block continues through the pid-liveness check at `:669-677` and the confirmation echo at `:678` — read, as was `stop_dnsmasq()` `:413-428`.) The proxy's equivalent lifecycle lives in Python:

> `def stop_prior(pidfile):`

(`cc-sni-proxy.py:212`; the function runs to the `os.unlink` in the trailing `try` at `:229-232` — read, together with `daemonize()` `:235-286`.)

**Legibility-target:** for-orchestrator-synthesis

Fact-check Claims 13 and 31 record that neither daemon is supervised after start and that the two restart mechanisms differ (dnsmasq: pidfile + `/proc/<pid>/comm` check + a `pkill -U` uid sweep; proxy: pidfile + `/proc/<pid>/cmdline` check, no sweep). The structural point is the layer: `init-firewall.sh` runs once at container start and exits, but it now owns the *lifetime* of two long-running processes whose death has boundary-visible consequences — if the proxy dies mid-session the nat REDIRECT at `:886` points at a closed port and every tcp/443 flow from `node` fails, which presents as "the network is broken" with no component responsible for noticing. The container has no init or supervisor, so this responsibility has nowhere to live today; the design fails closed (good) but has no recovery path short of a human re-running the script. Duplicating the restart logic in two languages also means the two daemons will keep drifting in robustness — the uid sweep that catches an orphaned dnsmasq has no proxy counterpart, and an orphaned proxy holding `127.0.0.1:3443` would make the next run's `--daemon` fail to bind. Failure mode in one phrase: **run-time lifetime owned by a start-time script**.

**Recommendation:** Either give the proxy the same uid-sweep fallback `stop_dnsmasq` has (cheapest, keeps the current shape), or factor daemon lifecycle into one helper the script uses for both — `start_or_restart <pidfile> <uid> <cmd...>` — so the two paths cannot diverge again. A real supervisor is out of scope for this design; if one is ever added, the `postStartCommand` chain in `devcontainer.json:117` is the seam.

---

#### The four `--print-*` hooks and the daemon machinery share one `set -euo pipefail` prologue and one 948-line file

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:29-30`, `:68-71`, `:100-103`, `:136-145`, `:210-213`
**Move:** 2 (responsibility boundaries), 5 (interface segregation)
**Confidence:** Medium
**Evidence:**
> ```
> if [ "${1:-}" = "--print-dnsmasq-conf" ]; then
>   compose_dnsmasq_conf "$(compose_dns_resolvers "${2:-/etc/resolv.conf}")" "$(compose_domains)"
>   exit 0
> fi
> ```

(`init-firewall.sh:210-213`; this is the last of the four early-exit hooks, all of which precede the `trap` installation at `:271` — read through to that trap.)

**Legibility-target:** for-orchestrator-synthesis

The script now holds eight distinct reasons to change: profile composition, entry parsing, resolver parsing, dnsmasq config generation, GitHub CIDR ingest, ipset/iptables construction, daemon supervision, and verification probing. The hook design is a genuinely good mitigation — the four inspection hooks exit before the trap, so a test consumer pays for nothing beyond the prologue and the composition functions it wants, which is why `test/init-firewall-rules.bats` can exercise the parsers with no root and no Docker. That keeps this a Minor rather than a Structural finding. But the pure functions (`compose_domains`, `compose_dns_resolvers`, `parse_entry`, `compose_dnsmasq_conf`) are ~130 lines of testable logic embedded in an 948-line privileged script, and they are exactly the parts F3 says need a single owner shared with a Python consumer.

The obvious refactor — a `cc-egress-lib.sh` sourced by the script — is blocked less by the NOPASSWD constraint (sudo runs the script as root; the script may source a root-owned file without a sudoers change) than by F1/F2: a new file must be added to `PAYLOAD`, to `enforcement_files()`, and to a `COPY`, and this range demonstrates that all three do not reliably happen. So the split's cost is currently higher than it should be, and fixing the registry is the prerequisite that makes it cheap.

**Recommendation:** Do not split yet. Fix F1 and F2 first; once adding a file to the boundary is a one-line change to one list, extract the four composition functions into a sourced lib and let the bats suite target the lib directly instead of the script's hooks.

---

#### Adding anything to the pipeline is a chain of parallel edits, not a registry entry

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:541-544`, `:681-696`, `:788-791`, `:882-896`
**Move:** 8 (extension points)
**Confidence:** High
**Evidence:**
> ```
>     for owner in "$DNSMASQ_UID" 0; do
> ```

(`init-firewall.sh:541`; the enclosing loop body adds the udp and tcp accepts at `:542-543` and closes at `:544`, inside the `if [ -n "$dns_resolvers" ]` branch that runs to `:571` — read.) The same two-uid pair recurs literally at `:682-683`, `:694-695`, `:788`, `:883-884` and `:893-894`.

**Legibility-target:** for-orchestrator-synthesis

Counting the edits each extension needs today: a new exempt uid = six sites (two nat chains, two filter guard chains, two accept loops); a new GitHub zone = two sites (F4); a new redirected port = a new nat chain, a new filter guard chain, a new listener, and a proxy CLI change; a new profile port = three parsers (F3); a new probe = an ad-hoc `if curl … else … fi` block appended to `:908-943`. None of these has a registry shape — the exempt-uid set in particular is a genuine list (`{dnsmasq, root}` today, `{dnsmasq, ccproxy, root}` for the SNI chain) that is spelled out six times as literal rule pairs. This is the cost that accrues if the pipeline gains a third daemon, and questions.md already carries an open question ("Should root inside the container also traverse dnsmasq and the SNI proxy?") whose answer would touch every one of those six sites.

**Recommendation:** Introduce one helper — `exempt_chain <table> <chain> <uid...>` emitting the `RETURN` rules — and call it from all six sites. That also makes the bats assertions (which pin each rule string individually) collapse to one per chain.

---

#### Code comments cite mutable decision-log row numbers, and one is already wrong

**Severity:** Minor
**Location:** `devcontainer-config/Dockerfile:47`, `devcontainer-config/init-firewall.sh:575`, `:807`
**Move:** 7 (coupling surface)
**Confidence:** High
**Evidence:**
> `# every firewall run (decision log #39: the filtering resolver that closes`

(`Dockerfile:47`; the enclosing comment block runs `:44-50` and is followed by the `useradd` at `:51-52` — read.)

**Legibility-target:** for-author

Fact-check Claim 2 (Stale) and escalation E6 record the mechanism: rows appended from parallel worktrees collided, the resolver decision landed as row 40, and the comment written against row 39 was never updated. `init-firewall.sh:575` and `:807` cite #40 and #41 correctly *today*. This is content coupling from enforcement code to a mutable, append-ordered document — the code names a position in a list that a concurrent branch can renumber, so correctness of the comment depends on merge order.

**Recommendation:** Cite the decision by title or by a stable slug (`decision log: filtering resolver`), or promote the two designs to numbered records under `docs/decisions/` and cite the filename. Fix the `#39` in `Dockerfile:47` regardless.

---

#### The env-override surface is two inconsistent shapes for the same job

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:395-396`, `:437-442`
**Move:** 3 (module boundary), 5 (interface segregation)
**Confidence:** High
**Evidence:**
> ```
> SNI_PROXY_BIN="${CC_SNI_PROXY_BIN:-/usr/local/bin/cc-sni-proxy.py}"
> SNI_RUN_DIR="${CC_SNI_RUN_DIR:-/run/cc-sni-proxy}"
> SNI_ALLOWLIST="$SNI_RUN_DIR/allowlist"
> ```

(`init-firewall.sh:437-439`; the block continues with `SNI_PIDFILE`, `SNI_LOG`, `SNI_PORT` at `:440-442` and the executability check at `:443-446` — read.) Against the dnsmasq pair:

> ```
> DNSMASQ_CONF="${CC_DNSMASQ_CONF:-/etc/dnsmasq.d/cc-allowlist.conf}"
> DNSMASQ_PIDFILE="${CC_DNSMASQ_PIDFILE:-/run/cc-dnsmasq.pid}"
> ```

(`init-firewall.sh:395-396`; the enclosing precondition block runs `:389-407` — read.)

**Legibility-target:** for-author

The SNI side exposes one directory override from which three paths are derived; the dnsmasq side exposes each file independently, with no directory override. Both are documented as "for the unit tests only", so this is the script's *public surface* to its only non-production consumer, and it is two conventions for one need. The consequence is small but compounding: a third daemon will pick one of the two by coin flip, and a test that wants to relocate dnsmasq's runtime state has to know two variable names where the SNI side needs one.

**Recommendation:** Pick the `*_RUN_DIR` shape for both (`CC_DNSMASQ_RUN_DIR`, deriving conf and pidfile), keeping the existing individual variables as deprecated fallbacks if the bats suite is expensive to update.

---

## What Looks Good

- **The proxy is genuinely substitutable.** Its entire contract with the firewall is a six-flag CLI plus "exit 0 once listening" (`cc-sni-proxy.py:236-239`, invoked at `init-firewall.sh:874-878`). Nothing in the firewall imports Python, reads the proxy's log format, or depends on its internals; a different SNI filter that honours the same flags and the same allowlist file grammar would drop in. That is the right dependency direction for a leaf. *(route: code-fact-check — Verified: the flag set and exit-status contract, per Claim 13 and Claim 31. Not verified: that the contract is sufficient in a live container, which needs the REDIRECT check already tracked in `docs/working/questions.md`.)*
- **Phase A / phase B is a real architectural boundary, not a comment.** Every network read is hoisted above the flush (`:293-453`), and the preconditions for both new daemons — binary present, uid exists, uid non-zero, uid distinct — are checked in phase A precisely so a broken image aborts with the live ruleset intact (`:389-407`, `:430-453`). The new subsystems respect the split that prior findings A3/A6 introduced rather than eroding it. *(route: code-fact-check — Verified: the pre-flush placement of the dnsmasq and proxy preconditions and of every `dig`/`curl`, per Claims 26 and 27 and the bats tests at `test/init-firewall-rules.bats:363-409`. Not verified: that no library called in phase B performs a lookup of its own.)*
- **The four `--print-*` hooks are the right seam.** They let the pure composition logic be tested with no root, no Docker, and no iptables, and they exit before the fail-closed trap is installed so a test invocation cannot alter the boundary (`:68-71`, `:100-103`, `:136-145`, `:210-213`). This is what keeps the single-file design defensible at 948 lines.
- **The generated files are root-written into root-owned directories, and the allowlist is replaced rather than reopened** (`rm -f "$SNI_ALLOWLIST"` before the write, `chmod 0444` after, `:856`/`:870`). The build-time/start-time layering holds for run-time state even though it does not hold at bless time.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `install.sh`'s `PAYLOAD` omits `cc-sni-proxy.py` — the build context lacks the file the `Dockerfile` copies | Structural | `install.sh:25`, `Dockerfile:389` | High |
| 2 | Bless manifest covers 4 of 7 installed artefacts (proxy, `link-claude-home.sh`, `claude-home/` unhashed) | Structural | `cc-isolated.sh:50-65` | High |
| 3 | One profile grammar, three parsers, two languages — already divergent on single-label entries | Coupling | `init-firewall.sh:116-134`, `:191-206`, `cc-sni-proxy.py:129-138` | High |
| 4 | Two GitHub-zone lists 700 lines apart, drifted on `.githubassets.com` | Coupling | `init-firewall.sh:154`, `:864-869` | High |
| 5 | Start-time script owns two run-time daemon lifetimes, with two divergent restart paths and no supervisor | Coupling | `init-firewall.sh:661-678`, `:852-879`, `cc-sni-proxy.py:212-232` | Medium |
| 6 | Eight responsibilities in one 948-line privileged script; split blocked by findings 1–2 | Minor | `init-firewall.sh:29-213` | Medium |
| 7 | Extensions are parallel edits, not registry entries (exempt-uid pair spelled out six times) | Minor | `init-firewall.sh:541-544`, `:681-696`, `:788-791`, `:882-896` | High |
| 8 | Comments cite mutable decision-log row numbers; `Dockerfile:47` already stale | Minor | `Dockerfile:47`, `init-firewall.sh:575`, `:807` | High |
| 9 | Env-override surface: `CC_SNI_RUN_DIR` derives three paths, `CC_DNSMASQ_*` names each file | Minor | `init-firewall.sh:395-396`, `:437-442` | High |

---

## Overall Assessment

The two new subsystems are well-placed. The SNI proxy is a proper leaf with a narrow, substitutable contract; the filtering resolver is a generated-config consumer of an off-the-shelf binary; both preconditions were correctly hoisted into phase A so the fail-closed design still holds; and the `--print-*` hooks keep the composition logic testable despite living inside a privileged 948-line script. Nothing here inverts a dependency or breaks the root-owned-enforcement / node-writable-state layering at run time.

The structural weakness is not inside either new module — it is the **registry** that admits files to the boundary. One conceptual set ("the files that constitute the enforcement boundary") is written out by hand in three places (`install.sh:25`, `cc-isolated.sh:50-65`, the `Dockerfile`'s `COPY` group), and this range added a new enforcement executable to exactly one of them. That produced both a hard build failure (F1, which will surface the moment the rebuild is attempted) and an unhashed enforcement file (F2, fact-check Claim 10 / E1) — and F2 generalises: `link-claude-home.sh` and the whole `/opt/claude-workflows` payload have been outside the manifest since decision 022, so the "every enforcement file is hashed" invariant the architecture rests on is weaker than the docs assert. Fix that registry before the rebuild-and-bless: it is a small change, it is a prerequisite for F1, and it is what makes the F6 refactor cheap later.

The rest is coupling that compounds rather than blocks. Three parsers for one grammar (F3) and two lists for one set of GitHub zones (F4) both already show observable divergence, and in each case the drift appeared in the same range that created the duplicate — that is the signal that these are not hypothetical maintenance costs. The daemon-lifecycle duplication (F5) is the one to watch if a third daemon is ever added.

Recommended order: F1 → F2 (both before the rebuild), then F4 and F3 (both cheap, both already wrong), then F5/F7 as a single "one helper per repeated pattern" pass. F6's split should wait until F1/F2 make adding a file to the boundary a one-line change.

## Goal-Alignment Note
- Answered: yes — dependency map, nine ordered findings, all eight cognitive moves covered.
- Out of scope: correctness of the ClientHello parser, TLS/QUIC/IPv6 coverage, whether the negative probe verifies the right thing (fact-check Claim 37 / E3 — verification strength, security's call), allowlist completeness (E4), and the test suite itself (pass 2). Trust Boundary Map unavailable — `docs/reviews/security-review-2026-09-03-egress-hardening.md` does not exist yet, so no finding carries a boundary label and the two `**Security implication:**` lines are my own reading.
- Escalate: (1) **F1 blocks the rebuild** — `install.sh` has no `cc-sni-proxy.py`, so `docker build` will fail at `COPY` on a clean install; fix before attempting the rebuild-and-bless this review precedes. (2) **F2 widens E1** — the manifest gap is not one file; `link-claude-home.sh` and `/opt/claude-workflows` have the same exposure and should be re-blessed together. (3) F4 overlaps fact-check E2 and touches `test/init-firewall-rules.bats:727`, so it needs to be sequenced with the pass-2 test review. (4) E6 (decision-log row collisions from parallel worktrees) is a process fix the orchestrator owns; F8 is only its code-side symptom.
