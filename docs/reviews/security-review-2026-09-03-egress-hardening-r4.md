# Security Review — egress hardening pass 4, 1434fc9..f313de7

Commit: f313de7

**Scope:** `git diff 1434fc9..f313de7 -- devcontainer-config/` — `init-firewall.sh`, `cc-isolated.sh`, `Dockerfile`, `cc-sni-proxy.py`, `egress/base.txt`. Fourth review pass over the third fix round (563448a, f313de7), statusing the five r3 findings and reviewing the new code as attack surface. `test/*.bats`, `docs/reviews/*` and `docs/working/questions.md` in the range are committed context: read to avoid false "missing" claims, executed as evidence about the scripts, not adjudicated as code. Threat model unchanged: a compromised in-container agent (uid `node`, NOPASSWD sudo for exactly `/usr/local/bin/init-firewall.sh`) trying to exfiltrate or reach an attacker host; secondarily, host-side drift of boundary config between blessings.
**Date:** 2026-09-03
**Based on:** `docs/reviews/security-review-2026-09-03-egress-hardening-r3.md` and the k=1 pass-4 `docs/reviews/code-fact-check-report.md` (21 claims on 563448a: 0 Incorrect, 5 Mostly accurate, four of those corrected in f313de7).

No HALT-class pattern in the diff: no plaintext credential, no TLS verification disabled, no unauthenticated privileged endpoint, no new user-facing SQL/command-injection sink.

Framing before the tables. This round closes the two r3 findings that carried the most weight — the argument-unbounded sudo grant (r3 #5) and the phase-A-outside-the-lock split (r3 #1) — and it closes them by construction rather than by comment: the grant is now `… init-firewall.sh ""`, which sudoers reads as "no arguments", and the lock now wraps both phases and is held to process exit. r3 #4's skip condition was inverted from "skip when the env var is set" to "run when the path is the baked one", which is the right polarity. r3 #2 went from one asserted rule to five. Sixty-four cases in `test/init-firewall-rules.bats` and fifty-four in `test/cc-isolated-functions.bats` pass in this sandbox. Everything filed below is Low, and the one finding I would fix before the next bless is N1, which is a coverage hole in a control **added in this range** — the claude-home hash walk — reproduced here with an executed demonstration.

**Floor rule:** only Low-and-above is filed as a finding. Sub-Low observations (argv-length limits on `sha256sum`, newline-in-filename handling, the fail-closed trap mutating policy outside the lock) are recorded in the Primitive sweep instead of padding the findings list.

---

### Prior findings status

| r3 # | Finding | Status | Evidence |
|---|---|---|---|
| 1 | Phase A ran outside the lock; a concurrent rebuild could silently narrow a legitimate run's allowlist | **closed** — the lock block moved to `:339-370`, above the PHASE A banner, and is held to process exit (no `flock -u` anywhere in the file). A second invocation now waits for the first to finish *entirely*, then reads against a settled ruleset. Wait raised 120 → 600 s and a non-numeric value now aborts instead of being silently repaired. New residual from the longer hold in N3. | `init-firewall.sh:339-370`, `:1110-1112`; `test/init-firewall-rules.bats` cases 57, 58, 59 |
| 2 | Completion gate asserted one of five boundary rules | **closed for the filed rules, residual for their siblings** — a five-element `-C` loop at `:1039-1052` now asserts the nat `CC_SNI` jump, both nat `CC_DNS` jumps, the `127.0.0.11` `CC_DNS_GUARD` jump and the `CC_SNI_GUARD` jump, each byte-identical to its `-A`/`-I`. The two external-resolver DNS guards and the catch-all `REJECT` are still unasserted — N2. | `init-firewall.sh:1039-1052` vs `:816-817`, `:850`, `:1018`, `:1028`; bats cases 60, 61, 64 |
| 3 | IPv6 posture is a point-in-time decision; phase-B `ip6tables` calls take no `-w` | **open, unchanged** — nothing in this range touches the IPv6 block or adds `-w`. Carried forward, not re-filed. | `init-firewall.sh:500-518`, `:576-594` (unchanged) |
| 4 | Ownership assertion scoped to two directories and skipped whenever `CC_EGRESS_DIR` was set | **substantially closed** — the skip condition is inverted: the check now runs when `EGRESS_DIR` **is** the baked literal, so setting `CC_EGRESS_DIR` to the real path no longer disables it, and `CC_EGRESS_OWNER_CHECK` is an *opt-in* whose worst case is an extra check. The `/usr/local`-and-up gap is now stated in the comment rather than silent. Residual (unreachable by `node`) in N4. | `init-firewall.sh:302-317`; bats case 62 |
| 5 | Sudo grant named no arguments, so the `--print-*` hooks were a root-privileged arbitrary-path read | **closed** — `/etc/sudoers.d/node-firewall` is now two lines: `Defaults:node env_reset, !setenv` and `node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh ""`. The `""` restricts the grant to a bare invocation, so the hooks are no longer root-runnable, and `!setenv` blocks `sudo CC_X=1 …` / `sudo -E`, which the `""` alone would not (an env assignment is not an argument). Parsed by `visudo -c` here; no caller passes arguments. | `Dockerfile:407-411`, `:429-430`; `devcontainer.json:121`; `cc-isolated.sh:432` |

No prior finding regressed. Three of the five are closed outright, one substantially, one is unchanged-and-carried.

---

### Trust Boundary Map

```
B1: host shell env (GH_TOKEN, OPENROUTER_API_KEY)
      → devcontainer.json containerEnv → every process env, incl. `node`     (unchanged)

B2: host-side config dir (~/.config/claude-devcontainer, NOT bind-mounted)
      → cc-isolated.sh check_manifest() → image build
      ✓ WIDENED THIS RANGE: claude-home/ (skills, hooks, workflows, the wiring
        that link-claude-home.sh merges into settings.json) is now hashed
      → but only its REGULAR FILES; a symlink in the payload is copied to the
        install dir and into the image and hashed by nothing                  (N1, new)

B3: agent (uid node) → `sudo /usr/local/bin/init-firewall.sh`
      ✓ NARROWED: the grant is now bare-invocation-only (`""`) with
        `env_reset, !setenv` stated in the same file, so the --print-* hooks
        are outside the grant and no CC_* can be passed through it            (was r3 #5)
      → what remains inside the grant: starting the script, arbitrarily often  (N3)

B3a: agent (uid node) → /usr/local/share
      ✓ CLOSED (r2-F1): asserted at every run, and the assertion now keys on
        the baked path rather than on the absence of a test env var           (was r3 #4)

B4: agent network syscalls → nat/filter OUTPUT → outside world
      → 11 OUTPUT-chain rules/jumps make the boundary; 5 are now asserted
        present before completion, 6 are not                                  (N2)

B5: attacker-influenced ClientHello on 127.0.0.1:3443 → parse_sni →
      Allowlist.allows → getaddrinfo → open_connection                        (unchanged)

B6: /run/cc-firewall/lock (root 0600 in a root 0700 dir)
      ✓ CLOSED to `node` (r2-F4) and the critical section now spans phase A,
        phase B and the probes, released only at exit                         (was r3 #1)
      → the hold is now ~4.5 min worst case against a 600 s wait, and `node`
        can queue holds without limit                                         (N3, new)

B7: /run/cc-sni-proxy/proxy.log (root 0644, dir 0755) → the completion gate
      ✓ orig_dst= discriminator unchanged; the nat-rule assertion it was
        paired with moved into the -C loop, semantics identical               (unchanged)

B8: cc-sni-proxy daemonize() parent ← readiness pipe ← child
      ✓ NEW BOUND: 30 s select(2), then SIGKILL + waitpid; no pidfile is
        written on that path, so no stale pidfile survives                    (new, sound)
```

| S | Source | Mutability class | Trust per sink class |
|---|--------|------------------|----------------------|
| S1 | `/etc/resolv.conf` | Docker-runtime-mutable, root-owned | Unchanged toward `iptables -d` / `server=`. **No longer reachable as an arbitrary path through sudo** — the `--print-*` hooks are outside the grant (r3 #5 closed). |
| S2 | `/usr/local/share/cc-egress/*.txt` | Root 0444 in root 0555, root parent | Grammar-validated by `parse_entry`; provenance asserted at `:302-317`, now on the invariant rather than on env-var absence. File modes still unchecked (N4). |
| S3 | `api.github.com/meta` JSON | Remote | Unchanged: shape- and regex-validated before `ipset add`. Now fetched under the lock. |
| S4 | DNS A records | Remote, cache-lifetime | Now resolved **under** the lock, so no rebuild can blank them mid-flight (r3 #1 closed). |
| S5 | SNI in a ClientHello at 127.0.0.1:3443 | Fully attacker-controlled | Unchanged. |
| S6 | `/run/cc-sni-proxy/*`, `/run/cc-dnsmasq.pid` | Root-written, node-readable | Unchanged. The readiness-timeout path writes no pidfile, so `stop_prior`'s unlink is the last word. |
| S7 | `CC_*` env vars | Caller-controlled | Neutralised by `env_reset` **and** `!setenv`, now written in this repo's own sudoers file rather than inherited from a base-image default. This is the r3 #4 escalation, closed. |
| S8 | `/run/cc-firewall/lock` and its directory | Root-created, 0600 in 0700 | Sound against `node`; the *hold time* is now the interesting quantity (N3). |
| S9 | Argument vector of the sudo grant | **No longer agent-controlled** — `""` permits the command only with no arguments | Closed (r3 #5). |
| S10 | `claude-home/` payload in the host config dir | Host-side mutable; not bind-mounted, so out of `node`'s reach | Newly hashed — for regular files. Symlinks (and therefore their targets) are outside the hash and outside the diff install.sh shows (N1). |

Every boundary this range touches moved the right way. The two that widened did so deliberately: B6's hold time in exchange for a race that no longer exists, and B2's *coverage* in exchange for a walk that is one `-type f` narrower than the invariant it advertises.

---

### Findings

#### The claude-home hash walk covers regular files only, so a symlink in the payload is installed, baked and served without ever being blessed — and one is in the tree right now

**Severity:** Low
**Location:** `devcontainer-config/cc-isolated.sh:71` (the walk), `:82-89` (`compute_manifest`), against `install.sh:25` (`PAYLOAD`), `:46-52` (`cp -r` staging) and `Dockerfile:403` (`COPY claude-home/ /opt/claude-workflows/`)
**Boundary:** B2, S10
**Move:** 2 (implicit sanitization assumption), 12 (sweep call sites), 11 (enumerate bypasses)
**Confidence:** High (the gap is executed below; the live artefact is observed in this working tree)
**Evidence:**
> `    if [ -d claude-home ]; then find claude-home -type f | LC_ALL=C sort; fi`

against the claim the same commit added directly above it:
> `# Keep this list in step with install.sh's PAYLOAD: a file`
> `# that is installed but not hashed is a boundary artefact nobody blessed (the SNI`
> `# proxy shipped that way once; a bats test now pins PAYLOAD ⊆ this list).`
> `# claude-home/ — the baked skills/hooks payload (scripts 0555, the rest 0444 inside`
> `# the image) — is hashed file by file via a sorted walk; that includes the`
> `# .manifest install.sh writes, so re-running install.sh re-blesses by design.`

and what is actually in `devcontainer-config/claude-home` at f313de7:
> `lrwxrwxrwx 1 node node 41 Sep  3 16:21 workflows -> /home/magfrump/claude-workflows/workflows`
> (`find claude-home -type f | wc -l` → 104; `find claude-home | wc -l` → 143. The link's target does not exist in this sandbox.)

**Legibility-target:** for-author
`find -type f` matches regular files. It does not match symlinks, and — with no `-L` — it does not descend through a symlink to a directory either. `install.sh` stages `claude-home` with `cp -r`, which preserves symlinks rather than dereferencing them (executed: a dangling link in the source is a dangling link in the copy), and installs it with `cp -r` again. So any `CLAUDE_HOME_SRC` item that is a symlink on the host — and `workflows` evidently was one on the author's host, which is why a `/home/magfrump/...` link is sitting in this tree — travels source → staging → `$DEST` → `COPY … /opt/claude-workflows/` → `link-claude-home.sh` → the session's `~/.claude/workflows`, and the manifest never sees it. Executed reproduction: a `claude-home/workflows` symlink pointing at a directory containing `benign` content, blessed; the link repointed at a directory containing `PWNED`; `compute_manifest` output byte-identical, and `cat claude-home/workflows/w.md` → `PWNED`. Neither the link's *target string* nor anything behind it is hashed.

What this is not: a path `node` can reach. `$DEST` is not bind-mounted (install.sh's own header is explicit that this is the point), so the agent cannot repoint the link — hence Low, not Medium. What it is: a hole in the control this commit added, against the threat the control names in its own comment ("installed but not hashed is a boundary artefact nobody blessed"), and the payload behind it is not inert — it is the skills, the hooks, and `hooks/wiring.json`, which `link-claude-home.sh` merges into `settings.json` including `permissions.deny` rules that the file itself says are load-bearing because the guard hook defers on its HARD tier. There is also a plain-correctness face: the dangling link means the whole workflows payload is *silently absent* from any image built from this tree, and nothing — not `check_manifest`, not bats case 53's PAYLOAD ⊆ test, not the install diff — says so. Failure mode: **an integrity walk whose file-type filter is narrower than the set of things it installs**.

**Recommendation:** Hash the payload the way it is installed. Cheapest correct form: `find claude-home \( -type f -o -type l \) | LC_ALL=C sort` in `enforcement_files`, and in `compute_manifest` emit, for each symlink, a line derived from `readlink` (`printf '%s  %s\n' "$(readlink "$f")" "$f"`) alongside the `sha256sum` lines for regular files — the target string is the thing that must not change unnoticed. Better still, refuse them: have `install.sh` abort if any staged `CLAUDE_HOME_SRC` item is a symlink, since a symlink into the host's home directory is never what the baked payload wants (it becomes a dangling link the moment it enters the image). Do both, and delete the stale `devcontainer-config/claude-home/workflows` link before the next install run. While the walk is open, note that `sha256sum "${files[@]}"` puts ~110 paths in one argv today; keep an eye on it if the payload grows by an order of magnitude, and that `while read -r f` over the walk splits a filename containing a newline (config dir is human-controlled, so this is a note, not a hole).

---

#### The `-C` loop asserts five of the eleven OUTPUT rules that make the boundary — the external-resolver DNS guards and the catch-all REJECT are not among them

**Severity:** Low
**Location:** `devcontainer-config/init-firewall.sh:1039-1052`, against the rules installed at `:816-817`, `:850-853`, `:933`, `:1018`, `:1028`, `:1034`, `:1037`
**Boundary:** B4, B7
**Move:** 3 (check the error path), 12 (sweep call sites), 11 (enumerate bypasses)
**Confidence:** High (both sides enumerated by grep over the file; the five asserted literals compared character-by-character with their `-A`/`-I`; the negative behaviour executed by bats cases 60, 61, 64)
**Evidence:**
> `# Every rule the boundary depends on must actually be present — not just the one`
> `# the SNI probe needs. `-C` queries what `-A`/`-I` installed; drift between the`
> `# two literals is self-detecting (the run aborts into DROP).`
> `for rule in \`
> `    "-t nat -C OUTPUT -p tcp --dport 443 -j CC_SNI" \`
> `    "-t nat -C OUTPUT -p udp --dport 53 -j CC_DNS" \`
> `    "-t nat -C OUTPUT -p tcp --dport 53 -j CC_DNS" \`
> `    "-C OUTPUT -d 127.0.0.11 -j CC_DNS_GUARD" \`
> `    "-C OUTPUT -p tcp --dport 443 -j CC_SNI_GUARD"; do`

against the six OUTPUT rules the loop does not name:
> `iptables -A OUTPUT -p udp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD`
> `iptables -A OUTPUT -p tcp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD`
> `iptables -A OUTPUT -o lo -j ACCEPT`
> `iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT`
> `iptables -A OUTPUT -m set --match-set allowed-domains dst,dst -j ACCEPT`
> `iptables -A OUTPUT -j REJECT --reject-with icmp-admin-prohibited`

**Legibility-target:** for-author
The loop is well built. `IFS=' ' read -r -a rule_args <<< "$rule"` is the correct split given the script's `IFS=$'\n\t'`, all five strings are fixed literals with nothing needing quoting, the herestring's trailing newline keeps `read`'s status at 0 under `set -e`, and a non-zero `-C` takes the explicit `exit 1` into the fail-closed trap — bats case 60 pins that for both guard chains and case 64 for the nat redirect. The five literals are byte-identical to the rules at `:816`, `:817`, `:850`, `:1018` and `:1028` (`-C` matches a rule spec regardless of position, so the `-I OUTPUT 1` form is fine).

The gap is between the comment's "every rule the boundary depends on" and the five. Two of the six omissions matter. `-p udp/tcp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD` (`:851-852`) is the filter-side backstop for exactly the recursive-forward tunnelling that d598bda in this branch's history was written to close — the nat `CC_DNS` redirect is the primary control and it *is* asserted, but the belt is checked and the braces are not. And `-A OUTPUT -j REJECT` (`:1037`) is the default-deny itself: if it were absent, everything not matched above falls through to the `OUTPUT` policy, and the policy at that point in phase B is not asserted either. In practice all of these are installed under `set -e`, and the interleaving that could leave a half-built chain behind is precisely what the now-full-span lock prevents, so this is defence in depth rather than a live hole — Low is the honest severity. It is filed because the comment states a universal and the loop implements five sixths of a subset, and because a maintainer adding rule twelve will read the loop as the place that keeps the set honest. Failure mode: **a verification step whose comment claims exhaustiveness the enumeration does not deliver**.

**Recommendation:** Add `"-C OUTPUT -p udp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD"`, its tcp twin, and `"-C OUTPUT -j REJECT --reject-with icmp-admin-prohibited"` to the loop (the `!` splits on space like everything else, so no quoting change is needed), and assert `-P OUTPUT` while you are there. Give every `-C` a `-w 5` so a contended xtables lock reads as a wait rather than "rule missing" — that is r2-F6's accepted residual, and this loop is now five more call sites of it. Then either enumerate in the comment what is deliberately unasserted (`-o lo`, `ESTABLISHED,RELATED`, the ipset ACCEPT, which are permissive rules whose absence fails closed) or drop the universal from the prose.

---

#### Holding the lock to exit makes a queued run's own fail-closed trap the DoS: `node` can time out its way to a DROP-policy container with four concurrent invocations

**Severity:** Low
**Location:** `devcontainer-config/init-firewall.sh:339-370` (the lock and the 600 s wait), `:265-297` (the trap it aborts into), reachable via `Dockerfile:429` (unmetered NOPASSWD)
**Boundary:** B6, B3
**Move:** 4 (resource exhaustion on a shared primitive), 3 (check the error path), 11 (enumerate bypasses)
**Confidence:** Medium (the hold arithmetic is read from the timeouts in the file and the comment's own budget; the pile-up itself is not executed — it needs a live resolver and real daemons)
**Evidence:**
> `# sized to the longest legitimate hold — a 15 s meta fetch, up to 6 s per`
> `# allowlisted name (~25 today), up to 39 s of daemon starts (the proxy's readiness`
> `# bound is 30 s), and four 15 s probes: ~270 s at today's largest allowlist —`
> `# with headroom for growth; a hold longer than the wait is a stuck run, not a slow`
> `# one.`

and the failure path a waiter takes:
> `if ! flock -w "$FIREWALL_LOCK_WAIT" 9; then`
> `    echo "ERROR: could not take $FIREWALL_LOCK within ${FIREWALL_LOCK_WAIT}s — another init-firewall.sh run is still in progress" >&2`
> `    exit 1`
> `fi`

which reaches, because the trap is installed at `:298` — thirty lines earlier:
> `    iptables -w 5 -P OUTPUT DROP || true`
> `    iptables -w 5 -P INPUT DROP || true`
> `    iptables -w 5 -P FORWARD DROP || true`

**Legibility-target:** for-author
The arithmetic in the comment is right and the wait is correctly sized *for one hold*. It is not sized for N of them, and N is chosen by the attacker: the sudo grant is unmetered, so `for i in $(seq 4); do sudo /usr/local/bin/init-firewall.sh & done` queues four holds. Runs one through three finish inside 600 s (≈270, 540, 810 — the third already loses); every run whose wait expires prints the error, exits 1, and its EXIT trap — which fires because `FIREWALL_COMPLETE` is unset — forces `-P OUTPUT/INPUT/FORWARD DROP` **outside the lock**, on top of whatever boundary the successful run just finished building. The container ends with a correct ruleset under a DROP policy: no egress, and no session.

Three things keep this at Low. The direction is fail-closed in every interleaving I can construct — the trap's only mutations are policy-to-DROP, which is monotone toward safety, so a trap firing under another run's phase B cannot open anything. The victim is the agent itself; a compromised `node` cutting its own network is not an attacker win. And it is not new in kind: the r3 design had a 120 s wait, so the pile-up threshold was *lower* before, not higher — this range made the failure less likely, not more. It is filed because the comment now reasons explicitly about hold length and wait length and stops one step short of the queue, and because the recovery (`devcontainer up --remove-existing-container`) is a host action the user must be told about. Failure mode: **a timeout budgeted for one holder of a serialised resource that any caller may hold repeatedly**.

**Recommendation:** Two cheap options, either sufficient. (a) Make a lock-wait timeout *not* fire the boundary-destroying trap: it is the one abort that happens with certainty that another run owns the ruleset, so `exit` through a path that leaves policies alone (set `FIREWALL_COMPLETE=1` is wrong — add an explicit `LOCK_TIMEOUT=1` the trap checks, and print "another run is in progress; this one did nothing"). (b) Bound the queue: take the lock with `flock -n` first and, on failure, wait once — a second waiter is a caller doing something unusual and can be refused immediately. Independently, state in the comment that the wait covers a single hold, so the next person raising it knows what the number means.

---

#### The ownership assertion's new trigger is an unnormalised string compare, and it still does not cover the profile files' own modes

**Severity:** Low
**Location:** `devcontainer-config/init-firewall.sh:302-317`
**Boundary:** B3a, S2, S7
**Move:** 1 (trust boundaries), 2 (implicit sanitization assumption), 11 (enumerate bypasses)
**Confidence:** High (read-static and unambiguous; the `stat`/`find -perm /022` symlink semantics were executed in r3 and are unchanged here)
**Evidence:**
> `# construction of the base image and are not re-checked.) The assertion keys on`
> `# the INVARIANT — the directory is the image's baked one — not on whether a test`
> `# override is present; CC_EGRESS_OWNER_CHECK=1 lets the unit tests exercise it`
> `# against a relocated directory.`
> `if [ "$EGRESS_DIR" = "/usr/local/share/cc-egress" ] || [ -n "${CC_EGRESS_OWNER_CHECK:-}" ]; then`
> `    for d in "$EGRESS_DIR" "$(dirname "$EGRESS_DIR")"; do`
> `        if [ "$(stat -c '%u' "$d")" != "0" ] || [ -n "$(find "$d" -maxdepth 0 -perm /022)" ]; then`

**Legibility-target:** for-author
This is a real improvement and the polarity is now correct: r3's form skipped the check whenever `CC_EGRESS_DIR` was set at all, including when it was set to the true path; this form runs the check on the default and treats `CC_EGRESS_OWNER_CHECK` as an opt-in whose worst case is an *extra* assertion. Bats case 62 exercises it against a relocated, non-root directory and pins the abort before any `curl`/`dig`/`iptables -F`.

Two residuals, both narrow. The trigger is a literal string equality with no path normalisation, so `CC_EGRESS_DIR=/usr/local/share/cc-egress/` (trailing slash), `//usr/local/share/cc-egress`, or `/usr/local/share/./cc-egress` all name the same directory and all skip the assertion. That is only reachable by someone who can set `CC_EGRESS_DIR` in the script's environment, and after this range `node` demonstrably cannot: the grant is `""`-restricted, `env_reset` and `!setenv` are stated in the repo's own sudoers file, and `visudo -c` parses it — so the residual is a legibility and future-maintenance matter, not a live path. And the loop still asserts the directory and one parent, not the `*.txt` files' own ownership and modes; with the directory root-owned 0555 those files cannot be replaced, so this stays defence in depth. Failure mode: **an invariant expressed as a string literal rather than as a resolved identity**.

**Recommendation:** Compare resolved paths, not strings: `[ "$(readlink -f "$EGRESS_DIR")" = "/usr/local/share/cc-egress" ]`. While the loop is open, add the two `stat`/`-perm` calls for `/usr/local` and `/usr` the comment now waives, and check the files' modes (`find "$EGRESS_DIR" -maxdepth 1 -name '*.txt' \( ! -user root -o -perm /022 \)` must be empty) — three lines that finish the chain the rest of which is asserted.

---

### Endorsement Claims

- **Claim:** The sudo grant now permits only a bare invocation of `/usr/local/bin/init-firewall.sh`, and no `CC_*` variable can be passed through it.
  **Location:** `devcontainer-config/Dockerfile:429`; consumed at `devcontainer.json:121` and `cc-isolated.sh:432`
  **Evidence:** executed
  **Verified:** `visudo -c` parses the exact two-line text (`Defaults:node env_reset, !setenv` / `node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh ""`) as valid — "parsed OK" in this sandbox. Per sudoers(5), a command whose only sudoers argument is `""` may be run *only* with no arguments, so `sudo … --print-resolvers /etc/shadow` is now outside the grant (r3 #5). `!setenv` is not redundant with it: an environment assignment on the sudo command line is not a command argument, so `sudo CC_EGRESS_DIR=/tmp/evil /usr/local/bin/init-firewall.sh` would still match the `""` form — `setenv` (default off, and now explicitly off for `node`) is what refuses it, as does `sudo -E`. Grepped every caller in the repo: `devcontainer.json:121` and `cc-isolated.sh:432` invoke it bare; the only `--print-*` callers are the bats suites, which run `bash "$FW" --print-…` directly as the test user, so nothing breaks.
  **Not verified:** That the built image's `/etc/sudoers.d/node-firewall` has these contents and mode 0440, and that no `env_keep +=` in the base image's `/etc/sudoers` survives `env_reset` for a `CC_*`-shaped name — the Dockerfile adds none, and the compiled-in defaults name none, but no image was built here.
  **route: code-fact-check**

- **Claim:** The lock now covers phase A, phase B and the verification probes, and is released only at process exit.
  **Location:** `devcontainer-config/init-firewall.sh:339-370`, `:1110-1112`
  **Evidence:** executed
  **Verified:** The `flock` block sits above the PHASE A banner; `grep -c '^flock -u 9'` over the file is 0 (bats case 59 pins exactly this); fd 9 is closed on both daemon starts (`dnsmasq … 9>&-` at `:798`, the proxy at `:1007`), and the proxy additionally closes every inherited fd above 2 in its child. Bats case 57 holds the lock from the test and confirms the run performs *no* `curl`, `dig` or `iptables -F` and ends at `iptables -w 5 -P OUTPUT DROP`. Case 58 confirms a non-numeric `CC_FIREWALL_LOCK_WAIT` aborts rather than being silently repaired to a default. All 64 cases pass here.
  **Not verified:** That no *future* long-lived child inherits fd 9 — the two current daemons are covered by explicit `9>&-`, which is a convention, not an enforcement.

- **Claim:** The five `-C` assertions are byte-identical to the rules the script installs, and any one of them missing aborts into the fail-closed trap.
  **Location:** `devcontainer-config/init-firewall.sh:1039-1052` vs `:816`, `:817`, `:850`, `:1018`, `:1028`
  **Evidence:** executed (behaviour) / read-static (string identity)
  **Verified:** Each `-C` spec compared character-by-character with its `-A`/`-I` counterpart, including the `-t nat` prefix on the three nat entries. Bats case 61 asserts all four new `-C` invocations appear in the command log of a successful run; case 60 (`NO_RULE=CC_SNI_GUARD`, `NO_RULE=CC_DNS_GUARD`) and case 64 (`NO_REDIRECT`) confirm the run aborts with `expected rule missing: …` and ends at `-P OUTPUT DROP`.
  **Not verified:** That real `iptables -C` matches these specs on a live kernel, and that a matching rule is in the *position* the boundary needs — the suite's stub answers by fiat. This remains the live-container check tracked in `docs/working/questions.md`.
  **route: code-fact-check**

- **Claim:** `claude-home`'s regular files are hashed individually and a content change breaks the bless.
  **Location:** `devcontainer-config/cc-isolated.sh:71`, `:82-89`
  **Evidence:** executed
  **Verified:** Bats case 54 writes `claude-home/hooks/h.sh`, confirms the path appears in `compute_manifest`, blesses, edits the file, and confirms `check_manifest` returns non-zero. `compute_manifest`'s `while read … done < <(…)` runs in the current shell, so `files+=()` accumulates correctly; the `[ ! -f "$cfg/$f" ]` pre-check keeps a missing entry from reaching `sha256sum`, and the six unconditional literals mean the `files[]`-empty case (where `sha256sum` would read stdin) is unreachable. `enforcement_files` no longer returns non-zero when `claude-home` is absent — the guarded `if` is the subshell's last command.
  **Not verified — and materially so:** the walk covers *regular files only*. Executed counter-demonstration: a symlink inside `claude-home` is absent from the walk, and repointing it at different content leaves `compute_manifest` byte-identical while the served content changes. This claim therefore does **not** extend to the payload as installed. See N1.
  **route: code-fact-check**

- **Claim:** The SNI proxy's bounded readiness wait cannot leave a stale pidfile or a surviving child.
  **Location:** `devcontainer-config/cc-sni-proxy.py:49`, `:255-269`
  **Evidence:** read-static
  **Verified:** `stop_prior(args.pidfile)` unlinks any prior pidfile before the fork; the parent writes a pidfile only on the `msg == b"ready"` branch, which the timeout path does not reach; the timeout path does `os.kill(pid, SIGKILL)` then `os.waitpid(pid, 0)`, so the child is dead and reaped before `return 1`. `log_fd` is closed in the parent before `select`, and the child's copies die with it. `select` also returns ready on child EOF, which falls to the pre-existing error branch. `init-firewall.sh` treats the non-zero exit as "no proxy" and fails closed rather than installing a REDIRECT to nothing.
  **Not verified:** The timeout's behaviour on a live kernel, including the race where the child signals readiness at exactly 30 s and is killed anyway (fail-closed, but it turns a slow start into an aborted firewall run).

Guardrails deliberately **not** endorsed here because they carry untested bypass candidates: the IPv6 gate (r3 #3, unchanged), the two unasserted DNS filter guards and the catch-all REJECT (N2), the `claude-home` walk as an integrity control (N1), `parse_sni` / `Allowlist.allows` (r1-F6, unchanged), and live ipset/redirect behaviour generally.

---

### Untested bypass candidates

**Lock held to exit (`:339-370`, `:1110-1112`)** — (1) `node` opens `/run/cc-firewall/lock` read-only and takes the advisory lock itself → **Tested (traced)**: the 0700 root directory denies `open(2)` to uid 1000; `/run` is root 0755, so `node` cannot pre-create the directory either (executed in this sandbox for `/run`'s mode). (2) A long-lived child inherits fd 9 and holds the lock past the parent → **Tested (traced)**: `9>&-` on `dnsmasq` (`:798`) and on the proxy (`:1007`), and the proxy's `daemonize` closes every inherited fd > 2; **Listed** for any child added later without the redirection. (3) `node` queues enough concurrent invocations that a waiter exceeds 600 s and its trap DROPs a healthy boundary → **Listed**, N3 (fail-closed; availability only). (4) A run killed with `SIGKILL` mid-hold leaving the lock stuck → **Tested (traced)**: `flock` on an fd is released by the kernel at process death, and `SIGINT/TERM/HUP/QUIT` are trapped to `exit 143`, which runs the EXIT trap; only `SIGKILL` skips the DROP, and it still frees the lock. (5) `CC_FIREWALL_LOCK` redirected to a node-writable path so the lock is taken somewhere harmless → **Listed**: blocked by `""` + `env_reset` + `!setenv` (now asserted in-repo, which is the r3 #4 upgrade). (6) `CC_FIREWALL_LOCK_WAIT=0` turning every contended run into an instant fail-closed abort → **Listed**: numerically validated and accepted; same env-reachability answer as (5).

**`claude-home` hashing (`cc-isolated.sh:71`)** — (1) A symlink inside `claude-home` whose target is outside the walk → **Tested (executed)**: absent from the walk, repointable without changing the manifest, and one such link (`workflows -> /home/magfrump/claude-workflows/workflows`, dangling) is in this tree. N1. (2) A directory whose *mode* changes (0555 → 0777 in the staging dir) → **Listed**: `sha256sum` hashes content, not modes, and the Dockerfile re-chmods on `COPY` anyway, so this is contained by the image build rather than by the manifest. (3) A file added to `claude-home` after bless → **Tested**: it appears in the walk, `check_manifest`'s string compare differs, and the launcher refuses (bats case 54 proves the edit case; the add case follows from the same compare). (4) A filename containing a newline splitting the `while read -r f` loop → **Listed**: config dir is human-controlled; the failure mode is "enforcement file missing" → `compute_manifest` returns 1 → `set -euo pipefail` in `cc-isolated.sh` aborts the launch, i.e. fail-closed. (5) `find` failing partway at *bless* time, blessing a short list that then matches forever → **Listed**: process-substitution status is discarded, but `bless_manifest` prints the manifest it wrote and blessing is human-gated. (6) `.manifest`'s `commit=`/`dirty=` lines making every install re-bless → **Tested (traced)**: intended and documented; it is a provenance stamp inside the hashed set, so a re-install is a re-bless by construction.

**Ownership assertion (`:302-317`)** — (1) `node` renames or replaces `cc-egress` via a writable parent → **Tested (traced)**: `Dockerfile:65-66`/`:419` leave it root-owned and the runtime assertion rejects a non-root parent. (2) A symlink substituted for `EGRESS_DIR` or its parent → **Tested** (r3, unchanged): `stat -c '%u'` does not dereference and `find -P … -perm /022` matches the link's 0777 mode; either condition aborts. (3) `CC_EGRESS_DIR` set to a trailing-slash or `//`-prefixed spelling of the baked path to skip the trigger → **Listed**, N4; unreachable by `node` after the `""`/`!setenv` change. (4) `CC_EGRESS_OWNER_CHECK` set to force the check on the real image → **Tested (traced)**: opt-in to an assertion, worst case an extra pass; no bypass exists in this direction. (5) An unchecked `/usr/local` or `/` → **Listed**: root by construction of `node:22`, now stated in the comment rather than silent. (6) A node-owned or 0666 `*.txt` inside the root 0555 directory → **Listed**: unreachable while the directory mode holds; the loop does not cover file modes. N4.

**Sudoers grant (`Dockerfile:429`)** — (1) `sudo init-firewall.sh --print-resolvers /root/.ssh/id_rsa` → **Tested (traced + parsed)**: outside the `""` grant; `visudo -c` accepts the text and sudoers(5) defines `""` as "no arguments". (2) `sudo CC_EGRESS_DIR=/tmp/evil init-firewall.sh` → **Tested (traced)**: an env assignment is not an argument, so the command still matches, but `!setenv` (and the default-off `setenv`, and the absent `SETENV` tag) refuses the assignment. (3) `sudo -E init-firewall.sh` with `CC_*` exported → **Tested (traced)**: same gate; `env_reset` strips what `-E` would have preserved. (4) A `CC_*` name landing in the base image's `env_keep` and surviving `env_reset` → **Listed**: the Dockerfile adds no `env_keep` and the compiled-in defaults are `LANG`/`LC_*`/`TERM`/`DISPLAY`-shaped, but the built image's `/etc/sudoers` was not read here. (5) A second sudoers.d file granting `node` more → **Listed**: only `node-firewall` is written; not enumerated in the built image. (6) A syntax error in the two-line file disabling `sudo` entirely → **Tested (traced)**: `visudo -c` passes on the exact text, mode is 0440, and sudo's refusal would fail the `postStartCommand` (`waitFor: postStartCommand`), so the failure is loud and pre-session.

**The `-C` loop (`:1039-1052`)** — (1) A rule whose spec needs quoting being mangled by `IFS=' ' read -r -a` → **Tested (traced)**: all five are fixed literals with single-space separators and no embedded quotes; case 61 shows the reconstructed command lines verbatim in the log. (2) `-C` succeeding against a rule in the wrong *position* (e.g. the REJECT ahead of the ipset ACCEPT) → **Listed**: `-C` is position-insensitive; nothing in the script asserts ordering. (3) `-C` failing spuriously on a contended xtables lock (no `-w`) → **Listed**: fail-closed, but a false alarm; r2-F6's accepted residual, now with five more call sites. N2. (4) A guard chain present but *empty* (jump installed, `-j REJECT` inside it missing) → **Listed**: the loop checks the jump, not the chain's contents. (5) `CC_DNS_GUARD` reachable only via `127.0.0.11` because `:851-852` are missing → **Listed**, N2 — this is the recursive-forward path. (6) The catch-all `REJECT` missing with an `ACCEPT` policy → **Listed**, N2; the `-P OUTPUT` policy in phase B is likewise unasserted.

---

### Primitive sweep

#### Content-hash manifest as a host-side integrity gate

| Call site | Source (S-label) | Guard | Disposition |
|---|---|---|---|
| `cc-isolated.sh:55-72` `enforcement_files` | S10, S2 | Six literals + two sorted globs + `find claude-home -type f` | Coverage widened this range; symlinks (and their targets) fall outside it while `cp -r` and `COPY` carry them through — N1. |
| `cc-isolated.sh:74-90` `compute_manifest` | S10 | Missing-file pre-check, one batched `sha256sum` | Correct and materially faster. `files[]`-empty is unreachable; newline-in-name and argv length are noted, not filed. |
| `cc-isolated.sh:99-116` `check_manifest` | S10 | Whole-string compare + `diff` on mismatch | Fail-closed; inherits exactly the coverage `enforcement_files` defines. |

#### Advisory file lock as a mutual-exclusion primitive

| Call site | Source (S-label) | Guard | Disposition |
|---|---|---|---|
| `init-firewall.sh:358-370` | S8 | 0700 root dir, 0600 file, `[[ =~ ^[0-9]+$ ]]` abort, taken after the trap, `9>&-` on both daemons, held to exit | r3 #1 closed: reads and rules are now under one critical section. Hold length vs an unmetered caller is the new residual — N3. |
| `init-firewall.sh:265-297` fail-closed trap | — | Runs on every non-completing exit, including a lock timeout | Mutates policy *outside* the lock, but only monotonically toward DROP, so no interleaving opens anything. Sub-Low; recorded here rather than filed. |

#### Rule-presence assertion as a completion gate

| Call site | Source (S-label) | Guard | Disposition |
|---|---|---|---|
| `init-firewall.sh:1042-1052` (5 × `-C`) | S9 (indirect) | Exact-string match with each `-A`/`-I`; non-zero → `exit 1` → trap | r3 #2 largely closed. Five of eleven OUTPUT rules; the external-resolver DNS guards and the catch-all REJECT are outside it, and no `-w` — N2. |
| `init-firewall.sh:1102` `grep -q … orig_dst=$ANTHROPIC_PROBE_IP:443` | S5 → S6 | Kernel-supplied `orig_dst`; probe IP asserted non-empty; log `O_TRUNC` per proxy start | Unchanged and still sound; its paired nat assertion simply moved into the loop above. |

#### Privilege grant scoped to an invocation

| Call site | Source (S-label) | Guard | Disposition |
|---|---|---|---|
| `Dockerfile:429` sudoers | S7, S9 | `""` (no arguments) + `Defaults:node env_reset, !setenv`, mode 0440, `visudo -c` clean | r3 #5 closed and r3 #4's escalation closed with it: the `CC_*` control-plane switches are now guarded by a rule this repo writes, not by an inherited default. |

#### Bounded wait on a forked helper

| Call site | Source (S-label) | Guard | Disposition |
|---|---|---|---|
| `cc-sni-proxy.py:255-269` | S6 | 30 s `select`, SIGKILL + `waitpid`, no pidfile on the timeout path | Sound. Converts "proxy hangs at start" from an unbounded lock hold into a fail-closed firewall abort. |

---

### Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `claude-home` walk hashes regular files only; a symlink in the payload is installed, baked and served unblessed — and one is present (dangling) today | Low | B2, S10 | `cc-isolated.sh:71`, `:82-89`; `install.sh:25`, `:46-52`; `Dockerfile:403` | High |
| 2 | `-C` loop asserts 5 of 11 OUTPUT rules; the external-resolver DNS guards and the catch-all REJECT are unasserted, and none of the `-C` calls take `-w` | Low | B4, B7 | `init-firewall.sh:1039-1052` vs `:851-852`, `:1037` | High |
| 3 | Lock held to exit + unmetered sudo: four concurrent invocations make a waiter's own fail-closed trap DROP a healthy boundary | Low | B6, B3 | `init-firewall.sh:339-370`, `:265-297` | Medium |
| 4 | Ownership assertion triggers on an unnormalised string compare and still ignores the profile files' own modes | Low | B3a, S2, S7 | `init-firewall.sh:302-317` | High |

Carried forward unchanged and not re-filed: the IPv6 point-in-time posture and missing `-w` on `ip6tables` (r3 #3), `-w` on main-path `iptables`/`ipset` (r2-F6, accepted), ECH/multi-SNI (r1-F6), `OPENROUTER_API_KEY` exposure (r1-F7), proxy log readability and unboundedness (r1-F8), the proxy as a single choke point (r1-F9), GitHub CIDRs on tcp/22 (r1-F11).

---

### Overall Assessment

**Nothing filed this round is above Low, and none of the four opens an egress path for `node`.** Three of the five r3 findings are closed outright, one substantially, and one (the IPv6 residual) is untouched and carried. The two closures that matter most are closed properly rather than cheaply: the sudo grant is now scoped to an invocation instead of to a program, with the `env_reset`/`!setenv` premise written into this repo's own sudoers file instead of assumed from a base image — which retires the single assumption r3 said was carrying the most weight — and the lock spans both phases and the probes, which deletes the r3 #1 race rather than documenting it. The five `-C` assertions, the 600 s wait with a hard abort on a non-numeric value, the batched `sha256sum`, and the proxy's bounded readiness wait are all improvements in the same direction. Sixty-four plus fifty-four bats cases pass here, and the new negative cases (`NO_RULE`, held-lock, non-numeric wait, `CC_EGRESS_OWNER_CHECK`) pin exactly the behaviours the r3 findings described.

This was intended as a confirming clean pass, and on the diff-as-reviewed it very nearly is: N2, N3 and N4 are all "the comment claims slightly more than the code delivers", each with a two-to-five-line fix and each fail-closed in the meantime. N1 is the exception and the reason this is not a clean pass. It is a coverage hole in a control introduced *by this range*, it is reproduced by execution rather than argued, and the artefact that proves the shape occurs in practice — a dangling `claude-home/workflows -> /home/magfrump/claude-workflows/workflows` — is sitting in the working tree at f313de7. Its blast radius is bounded by the fact that `node` cannot reach the host config dir, which is why it is Low and not Medium; but the payload behind that link is the skills, the hooks and `hooks/wiring.json`, whose `permissions.deny` entries `link-claude-home.sh` itself describes as load-bearing. It also has a plain-correctness face that has nothing to do with attackers: an image built from this tree today ships *no* workflows and nothing notices.

**Would I ship it, pending the live-container check? Yes, with one prerequisite.** The code in this range is sound as read and I would merge it locally. Before the next `--bless`, delete the stale `claude-home/workflows` symlink and either extend the walk to symlinks or make `install.sh` refuse them — otherwise the bless that follows this merge would record a manifest that omits a payload directory, which is precisely the state the walk was added to prevent. Everything else can follow. The review remains static with respect to a live kernel and a built image: `iptables -C` semantics for five specs, `SO_ORIGINAL_DST` on an un-NATed socket, the built image's `/etc/sudoers.d/node-firewall` contents and mode, and `ls -ld /usr/local/share /usr/local/share/cc-egress` are all still stub- or trace-backed, and the pre-`--bless` live-container check tracked in `docs/working/questions.md` is what converts them.

---

### Goal-Alignment Note
- **Answered:** yes — security design review of `1434fc9..f313de7` restricted to `devcontainer-config/`, with per-finding status for all five r3 findings (three closed, one substantially closed, one carried unchanged), the new code reviewed as attack surface, and six enumerated bypass candidates for each of the five touched guardrails (lock-to-exit, `claude-home` hashing, ownership check, sudoers grant, `-C` loop), each marked Tested or Listed. Report at `docs/reviews/security-review-2026-09-03-egress-hardening-r4.md`. Executed in this sandbox: both bats suites (64/64 and 54/54), `visudo -c` on the exact sudoers text, `cp -r` symlink-preservation, `find -type f` symlink exclusion, and an end-to-end reproduction showing a `claude-home` symlink repoint leaving `compute_manifest` byte-identical while the served content changes. Everything else is marked read-static or traced. Each of the four Examine questions is answered in the body: fd 9 is closed on both daemon starts and `node` cannot open the lock file (endorsement 2, bypass list 1); `link-claude-home.sh` creates symlinks in the container's `~/.claude`, never in the config dir, and the config-dir symlink that *does* exist came from `install.sh`'s `cp -r` of a host-side link (N1); `CC_EGRESS_OWNER_CHECK` is an opt-in and the trailing-slash skip is unreachable by `node` (N4); no caller passes an argument, so the `""` grant breaks nothing, and `!setenv` is load-bearing rather than redundant (endorsement 1); the proxy's SIGKILL path writes no pidfile and leaves the log fd handling unchanged (endorsement 5).
- **Out of scope:** `test/*.bats`, `docs/reviews/*`, `docs/working/questions.md` and the execution logs in the range — read as committed context and executed as evidence about the scripts, not reviewed as code. `install.sh`, `link-claude-home.sh` and `devcontainer.json` are outside the diff but were read because N1's mechanism runs through them; nothing in them is filed. The r3 IPv6 finding is statused, not re-argued. Nothing was committed; only this report was written.
- **Escalate:** (a) **N1 before the next bless** — the stale `claude-home/workflows` link must go, and the walk must either cover symlinks or the installer must reject them; this is the one item I would not defer past the merge, and it is also a silent-payload-loss bug independent of security. (b) **N2's three remaining `-C` entries plus `-w 5` on all of them** — five lines, and they finish r2-F3's recommendation as originally written. (c) **N3's lock-timeout path** — make a wait timeout exit without firing the boundary-destroying trap; it is the one abort that *knows* another run owns the ruleset. (d) The **live-container check** (questions.md, decision log #40/#41) now gates five specific read-static → executed conversions, listed in the Overall Assessment.
- **Questions I would have asked:** Was `devcontainer-config/claude-home/workflows` a symlink on the host where `install.sh` last ran, and is `$REPO_ROOT/workflows` a symlink there today? If yes, N1 has already shipped a payload nobody blessed and the fix is urgent rather than tidy. And: is the 600 s wait meant to absorb a queue of legitimate re-asserts (launcher probe + `postStartCommand` + a manual run), or exactly one hold? The answer decides whether N3's fix is (a) or (b).
