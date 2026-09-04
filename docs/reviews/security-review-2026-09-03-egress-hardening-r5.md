# Security Review — egress hardening pass 5, f313de7..294a6c2

Commit: 294a6c2

**Scope:** `git diff f313de7..294a6c2 -- devcontainer-config/` — two files touched, `cc-isolated.sh` (+32/−9) and `init-firewall.sh` (+45/−13). Fifth review pass, confirming pass over the fourth fix round. Statuses the four r4 findings and reviews the new code as attack surface. `test/*.bats`, `guides/cc-isolated-usage.md`, `docs/working/questions.md` and the four r4 critic reports in the same range are committed context: read as evidence about the scripts, not adjudicated as code. Threat model unchanged: a compromised in-container agent (uid `node`, NOPASSWD sudo for exactly `/usr/local/bin/init-firewall.sh ""`) trying to exfiltrate or reach an attacker host; secondarily, host-side drift of boundary config between blessings.
**Date:** 2026-09-03
**Based on:** `docs/reviews/security-review-2026-09-03-egress-hardening-r4.md`.
**Fact-check status:** the concurrent pass-5 fact-check was **not** available at this commit — `docs/reviews/code-fact-check-report.md` carries `**Commit:** 563448a`, two commits behind HEAD. This review therefore proceeds on direct code reading plus its own executions, and claims no fact-check corroboration. Every claim below that is marked *executed* was executed by this review in this sandbox and the command is named.

No HALT-class pattern in the diff: no plaintext credential, no TLS verification disabled, no unauthenticated privileged endpoint, no new user-facing SQL/command-injection sink.

**Framing.** This is a small, well-aimed round. All four r4 findings are addressed, three of them by construction rather than by comment, and the two that mattered most operationally — the manifest walk silently dropping `claude-home/` on a fresh install, and a lock waiter tearing down the holder's boundary — are closed with executed evidence. 120/120 bats pass here and `shellcheck` is clean on both files (executed). Nothing in this range is above Low.

The one thing I would not ship silently is N1: the symlink fix hashes the **link text** and not the **content behind the link**, and for a symlink that resolves this is *strictly weaker* than f313de7's behaviour, because `sha256sum` dereferences. That regression is executed below. It is Low — it needs a host-side actor to have created the link before a bless — but it is a coverage loss introduced by a commit whose stated purpose was to close a coverage loss, and it lands on `devcontainer.json`, which the host CLI dereferences.

**Floor rule:** only Low-and-above is filed as a finding. Sub-Low observations (the `(cd && sha256sum)` set-e exemption, bless truncating the manifest on failure, `sort -k2` on paths with blanks, `readlink` on names containing newlines, `CC_EGRESS_OWNER_CHECK` narrowing from `-n` to `= "1"`) are recorded in the Primitive sweep rather than padding the findings list.

---

### Prior findings status

| r4 # | Finding | Status | Evidence |
|---|---|---|---|
| 1 | The claude-home hash walk covered regular files only, so a symlink in the payload was installed, baked and served unblessed | **closed for the filed threat, new residual in N1** — the walk is now `find claude-home \( -type f -o -type l \)` (`cc-isolated.sh:76`), `compute_manifest` routes symlinks to a `links[]` array and emits `sha256(readlink target)  path` in sha256sum's own format (`:100-105`). **Executed:** repointing `claude-home/workflows` changes the manifest. The same execution shows the separate, *new* gap: content behind a resolving link is no longer hashed at all — N1. The r4 sub-finding it also fixed is real and larger than it looks: at f313de7 the `[ -e ] &&` idiom killed the subshell under `set -e`+`pipefail` when `projects/` was empty, so **the entire claude-home walk was dropped on every fresh install** — executed side by side, the f313de7 manifest of my fixture emits 7 lines with no `claude-home/` entry, the 294a6c2 manifest emits 9 including them. | `cc-isolated.sh:69-76`, `:80-106`; `test/cc-isolated-functions.bats` cases 119, 120; executions below |
| 2 | The `-C` loop asserted five of eleven OUTPUT rules, with no `-w` | **closed as filed** — nine rules now, adding both external-resolver DNS guards, the ipset ACCEPT and the catch-all REJECT; every call carries `-w 5`; the loop moved *below* the "Firewall configuration complete"/"Verifying firewall rules…" banners so the log ordering matches reality; the comment's universal ("every rule the boundary depends on") is replaced by the honest "load-bearing rules … presence only". All nine `-C` literals are byte-identical to their `-A`/`-I` (`:832-833`, `:866-868`, `:1034`, `:1044`, `:1050`, `:1053`) — compared field by field here. Residual about *presence-only* and *stub-only* verification in N2. | `init-firewall.sh:1056-1078` vs `:832-833`, `:866-868`, `:1034`, `:1044`, `:1050`, `:1053`; bats cases 980, 971, 1011 |
| 3 | A lock-wait timeout fired the boundary-destroying trap, so `node` could time out its way to a DROP-policy container | **closed** — `LOCK_TIMED_OUT=0` at `:273`, set to `1` at `:384` immediately before the `exit 1`, and checked *first* in `fail_closed_on_abort` (`:276-280`), which prints "not forced to DROP — this run changed nothing" and returns 0. This is r4's recommendation (a) taken verbatim. The sentinel is assigned unconditionally at top level **before** the trap is armed at `:310`, so it cannot be seeded from the environment even in the absence of `env_reset`. My own attempt to find a node-reachable stand-down over an open boundary failed; the residual is stated precisely in N3. | `init-firewall.sh:273`, `:276-280`, `:384`; bats case 944 (with the caveat in N3) |
| 4 | The ownership assertion's trigger was an unnormalised string compare, and `CC_EGRESS_OWNER_CHECK` was `-n`-tested | **partially closed; residual open and carried, not re-filed** — the baked path is now the named constant `EGRESS_DIR_DEFAULT=/usr/local/share/cc-egress` (`:44`) rather than a literal repeated between the comment and the test, and the opt-in is `= "1"` instead of `-n`. Both are legibility wins. The comparison at `:323` is still `[ "$EGRESS_DIR" = "$EGRESS_DIR_DEFAULT" ]`, a byte compare with no normalisation, so a trailing slash or a `//` prefix still skips the assertion. r4 already rated this Low-and-unreachable-by-`node` (the grant is `""`-restricted with `env_reset, !setenv`); nothing in this range changes its reachability, so it is carried forward here rather than re-filed, the way r4 carried r3 #3. | `init-firewall.sh:44-45`, `:313-330`; bats case 992 |
| r3 #3 | IPv6 posture is point-in-time; phase-B `ip6tables` calls take no `-w` | **open, unchanged** — nothing in this range touches the IPv6 block. Carried forward for the third pass, not re-filed. | `init-firewall.sh:611-613` (unchanged) |

No prior finding regressed **in the sense r4 filed it**. N1 is a regression against f313de7 on an axis r4 did not file (content-behind-link), introduced by r4 #1's fix.

---

### Trust Boundary Map

```
B1: host shell env (GH_TOKEN, OPENROUTER_API_KEY)
      → devcontainer.json containerEnv → every process env, incl. `node`     (unchanged)

B2: host-side config dir (~/.config/claude-devcontainer, NOT bind-mounted)
      → cc-isolated.sh check_manifest() → devcontainer --override-config
                                        → docker build context
      ✓ CLOSED THIS RANGE: the claude-home walk no longer dies on an empty
        projects/ — at f313de7 a fresh install hashed NONE of claude-home/
      ✓ CLOSED THIS RANGE: a symlink's TARGET PATH is now hashed, so a repoint
        trips the manifest
      → but the CONTENT behind a resolving symlink is now hashed by nothing,
        where at f313de7 sha256sum dereferenced and caught it                 (N1, new)

B3: agent (uid node) → `sudo /usr/local/bin/init-firewall.sh ""`
      → what remains inside the grant: starting the script, arbitrarily often
      ✓ NARROWED THIS RANGE: a queued run that times out no longer forces DROP
        over the holder's work — the DoS r4 filed as N3 is gone
      → new question: can a stand-down leave the boundary OPEN?               (N3)

B3a: agent (uid node) → /usr/local/share
      ✓ asserted at every run; trigger now a named constant, still a byte
        compare                                                     (r4 #4, carried)

B4: agent network syscalls → nat/filter OUTPUT → outside world
      → 11 OUTPUT-chain rules/jumps make the boundary; 9 are now asserted
        PRESENT (not positioned) before completion, all with -w 5
      → the two unasserted are `-o lo` and ESTABLISHED,RELATED: permissive
        rules whose absence fails closed. Correct set.
      → ordering (guards before the ipset ACCEPT) is pinned by a bats case on
        install order, not by the runtime loop                                (N2)

B5: attacker-influenced ClientHello on 127.0.0.1:3443 → parse_sni →
      Allowlist.allows → getaddrinfo → open_connection                        (unchanged)

B6: /run/cc-firewall/lock (0700 dir, 0600 file, root-only)
      → serialises every run; held to process exit; release is by fd close,
        i.e. by process death, which is what makes N3's argument work

B7: iptables/xtables lock → now contended-safe at all nine -C sites (-w 5)
```

---

### Findings

#### Blessing a symlink by its target *text* is strictly weaker than the behaviour it replaced for any link that resolves — `sha256sum` dereferenced, and `devcontainer.json` is dereferenced by the host CLI too

**Severity:** Low
**Location:** `devcontainer-config/cc-isolated.sh:85-105` (the `-L` branch and the link-hash loop), against `:58-63` (the six unconditional top-level entries) and `:125` (`check_manifest`'s consumer)
**Boundary:** B2
**Move:** 2 (implicit sanitization assumption), 3 (check the error path), 11 (enumerate bypasses), 12 (sweep call sites)
**Confidence:** High — executed both directions against the real functions extracted from both commits
**Evidence:**
> ```
>   while read -r f; do
>     [ -n "$f" ] || continue
>     if [ -L "$cfg/$f" ]; then
>       links+=("$f")
>     elif [ ! -f "$cfg/$f" ]; then
> ```
> …
> ```
>     for f in "${links[@]}"; do
>       printf '%s  %s\n' "$(printf '%s' "$(readlink "$f")" | sha256sum | cut -d' ' -f1)" "$f"
>     done
> ```

against the list the `-L` branch now intercepts, which is not only `claude-home/`:
> ```
>   echo "devcontainer.json"
>   echo "Dockerfile"
>   echo "init-firewall.sh"
>   echo "cc-sni-proxy.py"
>   echo "link-claude-home.sh"
>   echo "cc-isolated.sh"
> ```

**Legibility-target:** for-author

The `-L` test precedes the `-f` test, and `-f` follows symlinks. So the branch does not only capture the `claude-home/` links it was written for — it captures **any** enforcement file that happens to be a symlink, including the six top-level boundary artefacts, and diverts them from content hashing to target-text hashing.

Executed, three ways, using the real `config_dir`/`enforcement_files`/`compute_manifest` lifted out of each commit into a fixture config dir:

1. *The fix works as advertised.* `claude-home/workflows` repointed from one directory to another → manifest line changes → `check_manifest` would refuse. **Repoint DETECTED.**
2. *The new blindness.* With `cfg/init-firewall.sh` a symlink to `canon/init-firewall.sh`, rewriting `canon/init-firewall.sh` from `v1 firewall ORIGINAL` to `v2 firewall PWNED` and `canon/workflows/w.md` from `benign` to `PWNED` produced a **byte-identical manifest** — `diff` reports the two runs identical. The boundary script's content changed; the manifest did not move.
3. *It is a regression, not a pre-existing gap.* The same fixture under the f313de7 functions: editing the symlinked `init-firewall.sh` target **changed its manifest line** (`b0a102ad…` → `4b1b8ea8…`), because at f313de7 the path went `[ ! -f ]` → false (a link to a file is `-f`) → `files+=` → `sha256sum`, which dereferences (verified separately: `sha256sum link.txt real.txt` prints the same digest twice). So f313de7 caught this and 294a6c2 does not.

The same fixture run also produced the incidental confirmation for r4 #1's other half: the f313de7 manifest contains **no `claude-home/` entries at all** when `projects/` is empty, exactly the empty-glob death the commit message describes.

How bad is this, honestly? It needs an actor who can (a) put a symlink in the installed config dir before a bless and (b) write the link's target afterwards. `node` can do neither — the config dir is deliberately in no bind mount, which is the whole point of decision 016 — so this is not agent-reachable and stays Low. But (a) and (b) are precisely what B2 exists for: the manifest's own header names "a malicious npm postinstall running as you" as the threat, and a dev who symlinks `devcontainer.json` or `init-firewall.sh` into a git checkout for convenience is an ordinary thing to do (this repo already tracks `workflows/workflows` as a symlink into `/home/magfrump/…`, so the author's environment demonstrably contains links of this shape). The sharpest instance is `devcontainer.json`: `cc-isolated.sh:265`/`:424` pass it to `devcontainer --override-config`, a **host-side read that dereferences the link**, and that file carries `containerEnv`, the mount list and `postStartCommand`. Content-behind-link therefore reaches a consumer in full, unhashed. (For `init-firewall.sh` and the rest of `claude-home/`, the consumer is `COPY` into the image, where a link to an absolute host path lands dangling — that path is a correctness break, not a silent substitution, and is already tracked in `questions.md`.)

Failure mode: **a fix for an integrity gap that silently narrows the integrity property for the cases that already worked** — the commit traded content coverage for path coverage, where it needed both.

**Recommendation:** Hash both. Emit two facts per link, or one fact over both: keep the `readlink` line (it catches the repoint) and, when the link resolves to a regular file, also hash the resolved content — e.g. append the resolved file to `files[]` as well, or emit `printf '%s %s  %s\n' "$(sha256 target-text)" "$(sha256sum -- "$f" | cut -d' ' -f1)" "$f"` (`sha256sum` on the link path dereferences; guard the dangling case with `[ -e "$f" ]`). Two lines. Better still, and the recommendation r4 already made: have `install.sh` refuse to stage a symlink into `PAYLOAD`/`CLAUDE_HOME_SRC` at all, so the manifest never has to reason about them — a symlink into the host's home directory is never what a baked image payload wants. Then delete `workflows/workflows`.

---

#### The nine-rule `-C` loop is presence-only by design and stub-only by test: it cannot see the ordering invariant that makes the guards load-bearing, and no test ever runs its literals past a real iptables parser

**Severity:** Low
**Location:** `devcontainer-config/init-firewall.sh:1056-1078`; `test/init-firewall-rules.bats:48-56` (the `iptables` PATH stub), `:780-790` (the ordering case)
**Boundary:** B4, B7
**Move:** 3 (check the error path), 11 (enumerate bypasses), 12 (sweep call sites)
**Confidence:** Medium-High — the literal comparison and the coverage arithmetic are executed by grep here; the real-kernel `-C` matching semantics could **not** be executed in this sandbox (`unshare -rn` → `Operation not permitted`, no CAP_NET_ADMIN), so that half is reasoned from documented behaviour and marked Listed
**Evidence:**
> ```
> # The load-bearing rules must actually be present (presence only — the position of
> # the two `-I OUTPUT 1` DNS redirects is by construction, not re-checked). `-C`
> # queries what `-A`/`-I` installed; drift between the two literals is
> # self-detecting (the run aborts into DROP).
> ```
> …
> ```
>     if ! iptables -w 5 "${rule_args[@]}" 2>/dev/null; then
> ```

against the stub every `-C` in the suite actually reaches:
> ```
> #!/usr/bin/env bash
> echo "iptables $*" >> "$CMD_LOG"
> # NO_REDIRECT models a missing CC_SNI jump: `-C` (rule-exists check) reports absent.
> if [ -n "${NO_REDIRECT:-}" ] && printf '%s\n' "$@" | grep -qx -- '-C' && printf '%s\n' "$@" | grep -qx -- 'CC_SNI'; then exit 1; fi
> ```

**Legibility-target:** for-author

Taking the three questions in turn.

*Can a broader rule mask a narrower rule's absence via `-C`?* **No — confirmed, and the loop is fine on this axis.** `iptables -C` succeeds only when a rule matching the given spec exactly (after the parser's own canonicalisation) exists in the chain; it is not a subset test. `-C OUTPUT -p udp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD` is not satisfied by a hypothetical broader `-p udp --dport 53 -j CC_DNS_GUARD`, nor the reverse. So none of the nine can be satisfied by a sibling, and the newly added external-resolver guards genuinely close r4 #2. I could not execute the negative (no netns available), so this is Listed rather than Tested — but all nine literals *are* byte-identical to their installers, checked field by field against `:832-833`, `:866-868`, `:1034`, `:1044`, `:1050`, `:1053`, which removes the drift risk the comment claims to be self-detecting.

*Does `-w 5` plus `2>/dev/null` fail in the right direction?* **Yes — confirmed.** Before this range a contended xtables lock made `-C` fail instantly and read as "rule missing"; now it waits 5 s first, and a genuine timeout still exits non-zero into `exit 1` → EXIT trap → forced DROP. Fail-closed, and the noisy `Another app is currently holding the xtables lock` line no longer pollutes the verification banner. The cost of `2>/dev/null` is that a *malformed* spec (a future edit with a typo, or a match module the kernel lacks) is indistinguishable in the log from a missing rule: the operator is told "expected rule missing" when the truth is "iptables rejected my query". That is a diagnosis cost on a fail-closed path, not a hole.

The two residuals are what I file.

**(a) Presence is not position, and one of the eleven rules' security value is entirely positional.** `-A OUTPUT -p tcp --dport 443 -j CC_SNI_GUARD` (`:1044`) is load-bearing *because it is appended before* `-A OUTPUT -m set --match-set allowed-domains dst,dst -j ACCEPT` (`:1050`) — the file's own comment says so ("the ipset accept below must never be reachable by the agent for 443 directly"). Both are now asserted present; neither is asserted ordered. Swap the two `-A` lines and all nine `-C` calls still pass while every allowlisted *address* becomes reachable on 443 without an SNI check — the exact overreach the proxy exists to close. Mitigations that keep this Low, not Medium: the order is fixed by a linear script running under `set -e` in a 0555 root-owned file baked into the image, so there is no runtime path that reorders it; and `test/init-firewall-rules.bats:785-790` **does** pin `guard < accept` by install order in `$CMD_LOG`. So the invariant is defended — just not by the mechanism a maintainer reading the loop will assume defends it. The comment now names one positional exemption (the two `-I OUTPUT 1` DNS redirects, "by construction") and by naming only that one implies the rest are order-free, which is the misleading part.

**(b) Nine `-C` literals, zero of them ever parsed by iptables.** The suite's `iptables` is a PATH stub that logs its argv and returns 0 unless a `FAIL_*`/`NO_*` knob fires. The positive case (`:980`) greps `$CMD_LOG` for the exact strings the script emitted — i.e. it asserts the script says what the test says it says, which is a tautology with respect to whether real iptables would accept the spec. Nothing in the repo would catch a literal that the kernel's parser canonicalises differently from the `-A` that installed it — the plausible candidate being the `! -d 127.0.0.1` negation on the two new DNS-guard entries, since negation placement is one of the few places `iptables-save` output diverges from the input spec. If that drift exists, the symptom is a container that fails verification on **every** run and forces DROP: fail-closed, but a hard brick on first live use, recoverable only by `devcontainer up --remove-existing-container`. The suite cannot tell you this in advance, and the r4 report's endorsement of the five-rule loop rested on the same stub. This is the single strongest argument for the live-container check before the next bless.

Failure mode: **a completion gate verified against a mock of the thing it is gating, asserting a property (presence) weaker than the one that matters (position)**.

**Recommendation:** Three cheap steps, in priority order. (1) Run the boundary once in a real container before blessing and confirm all nine `-C` calls return 0 — this is the one residual the unit suite structurally cannot retire, and it is a single `devcontainer up` away. (2) Replace the positional claim in the comment with the real one: say that the loop asserts presence, that `-o lo` and ESTABLISHED,RELATED are deliberately unasserted because their absence fails closed, and that **the guard-before-ACCEPT ordering is enforced by construction and pinned by the bats case at `:785`, not by this loop** — so the next person adding rule twelve knows which file to edit. (3) If you want the ordering asserted at runtime too, one `iptables -S OUTPUT` read and an index comparison of the `CC_SNI_GUARD` and `--match-set` lines is four lines and covers it; `-P OUTPUT DROP` is worth reading back in the same breath, since the completion gate currently never confirms the policy it depends on.

---

#### The lock stand-down is right, and its safety rests on an unstated invariant (a timeout implies a live holder) that no test pins — and the test that looks like it pins the stand-down contains a vacuous assertion

**Severity:** Low
**Location:** `devcontainer-config/init-firewall.sh:272-280` (the sentinel and the trap branch), `:377-386` (the lock and the timeout path), `:588-593` (phase B's DROP-before-flush); `test/init-firewall-rules.bats:944-958`
**Boundary:** B3, B6
**Move:** 3 (check the error path), 4 (resource exhaustion on a shared primitive), 11 (enumerate bypasses)
**Confidence:** High on the mechanism (read-static and unambiguous, cross-checked against the fd semantics and phase-B ordering); Medium on the residual (a wedged-holder scenario is constructed, not executed — it needs real daemons)
**Evidence:**
> ```
> FIREWALL_COMPLETE=0
> LOCK_TIMED_OUT=0
> fail_closed_on_abort() {
>   local chain policies open=0
>   if [ "${LOCK_TIMED_OUT:-0}" = "1" ]; then
>     echo "ERROR: init-firewall.sh gave up waiting for the lock; the ruleset was left as the" >&2
>     echo "       concurrent run leaves it (not forced to DROP — this run changed nothing)." >&2
>     return 0
>   fi
> ```

and the test that is supposed to hold it:
> ```
>   # A lock timeout must NOT tear down the boundary the holder is building.
>   run grep -c -- "-P OUTPUT DROP" "$CMD_LOG"
>   [ "$output" -eq 0 ]
>   [[ "$output" != *"fails CLOSED"* ]]
> ```

**Legibility-target:** for-author

I went looking for a node-reachable sequence that ends in a stand-down while the boundary is open. I did not find one, and the reason is worth writing down because it is load-bearing and currently implicit.

**Why the stand-down is safe.** Four facts compose:

1. *The sentinel cannot be attacker-supplied.* `LOCK_TIMED_OUT=0` is an unconditional top-level assignment at `:273`, evaluated *before* `trap fail_closed_on_abort EXIT` at `:310` and before any `exit` that could reach the trap. Unlike every `CC_*` in the file it is not `${…:-default}`, so an inherited environment value is overwritten rather than honoured. The `${LOCK_TIMED_OUT:-0}` in the trap is belt-and-braces. `env_reset` would strip it anyway; this holds even without sudo. The only assignment to `1` is at `:384`, on the single `flock` failure path, two lines before its `exit 1`.
2. *A timeout implies the lock was held for the whole window by a live process.* `flock -w N` on fd 9 returns failure only after N seconds of the lock being continuously held. The lock is released by closing the fd, and the kernel closes it when the holder dies — including on `SIGKILL`, and including on an OOM kill. So a holder that dies at second 3 releases at second 3 and the waiter *acquires* rather than times out. A timeout therefore means: at the moment of the timeout, some process still held the lock.
3. *Any process holding that lock has an armed fail-closed trap.* The trap is installed at `:310`; the lock is taken at `:379`. There is no path that takes the lock without first arming the trap.
4. *`node` cannot make a holder die silently, and cannot make one hold longer.* The holder runs as root under `sudo`; `node` cannot signal it. `node` cannot set `CC_FIREWALL_LOCK_WAIT` (the grant is `""`-restricted with `env_reset, !setenv`). Every network read the holder performs inside the lock is time-bounded — `curl --connect-timeout 5 --max-time 15`, `dig` with its own timeout, the proxy's 30 s readiness bound — so `node` has no lever on hold length beyond queueing more runs.

And the case that actually worried me — a stand-down landing during another run's **flush** — is answered by `:578-590`: phase B sets `-P INPUT/FORWARD/OUTPUT DROP` **before** `iptables -F`, precisely so the chains are never empty under an ACCEPT policy. So a waiter that stands down while the holder is anywhere in phase B leaves a container whose policy is already DROP. A waiter that stands down while the holder is in phase A leaves the *previous* run's intact ruleset. Neither is open.

The fresh-container question specifically: on a first start the only run is `postStartCommand`'s (`devcontainer.json:121`), which executes before any agent session exists, so there is no `node` process available to queue a second run against a never-built boundary. By the time `node` can call `sudo init-firewall.sh` at all, a boundary has been built (or the container failed to start and `cc-isolated.sh:448-453` refuses to launch a session). `node` queueing four runs now produces at worst: run 1 completes, runs 2–3 rebuild, run 4 times out and **stands down quietly** — where at f313de7 it would have forced DROP over run 3's finished work. The r4 N3 self-DoS is genuinely gone and nothing replaced it.

**The residual, stated precisely.** The stand-down is safe *because* a timeout implies a live holder with an armed trap. That invariant is broken by exactly one class of event: a lock holder that is alive, will never finish, and never built the boundary — a process wedged on something unbounded inside the lock, or a root operator's shell holding `/run/cc-firewall/lock` by hand. In that state a waiter prints "the ruleset was left as the concurrent run leaves it", exits 1, and on a fresh container "as the concurrent run leaves it" means empty chains under the default ACCEPT policy — an open container, with the previous behaviour (force DROP) removed. This is not `node`-reachable: `node` cannot open the lock file (the directory is 0700 root, checked by bats case 937) and cannot wedge a root process. It is reachable by operator error and by a future edit that adds an unbounded call inside the lock. The message is also slightly over-confident for that case — it asserts what the holder is doing rather than what this run observed.

**Separately: the test does not hold what it says it holds.** At `:953-956` the second assertion reuses `$output` from the immediately preceding `run grep -c …`, whose output is the string `0`. So it evaluates `[[ "0" != *"fails CLOSED"* ]]`, which is true regardless of what the script printed. The intended check — that the run's own output does not claim a forced DROP — is not performed. The first assertion (no `-P OUTPUT DROP` in `$CMD_LOG`) is real and does pin the important half, so the behaviour is covered; but an endorsement of the form "the stand-down message is pinned by a test" would be false, and this is the kind of `run`-clobbers-`$output` slip that silently spreads.

Failure mode: **a safety property that holds only because of an invariant stated nowhere, guarded by a test whose second assertion is a no-op**.

**Recommendation:** (1) Write the invariant into the comment at `:381-383`: *a `flock -w` timeout implies the lock was held for the full window; the fd closes on process death, so the holder is alive and — because the trap is armed at `:310`, before the lock is taken at `:379` — will itself fail closed. This run therefore changes nothing.* That is the whole safety argument in three lines and it is currently nowhere in the repo. (2) Soften the message from an assertion about the holder to an observation about this run: "another run has held the lock for ${FIREWALL_LOCK_WAIT}s; this run changed nothing and is not forcing DROP. If no other run is in fact active, the boundary may be unbuilt — check `iptables -S`." (3) Fix the vacuous assertion: capture the run's output into a named variable (`local out="$output"` immediately after `run bash "$FW"`) and test that, or simply move the `fails CLOSED` check above the `run grep`. (4) Optional and cheap: have the stand-down path read back `iptables -S | grep '^-P OUTPUT'` and say which policy it is standing down over — that converts the one unsafe scenario above from silent to loud without reintroducing the DoS.

---

### Endorsement Claims

Claims I am willing to be held to, each with the strongest evidence I have and the scope it covers.

1. **The empty-`projects/` manifest bug is real and is fixed.** At f313de7, `enforcement_files` emitted no `claude-home/` lines at all when `projects/` was empty — the fresh-install state — so ~100 baked payload files were installed and blessed by nothing. At 294a6c2 they are hashed. *Executed:* the same fixture through both commits' functions, 7 lines vs 9, `claude-home/` present only in the latter. Scope: covers the function pair in a fixture config dir; does not cover the real installed dir, which I cannot see from here.
2. **A symlink repoint in `claude-home/` now trips the manifest.** *Executed:* `ln -sfn` to a different target changed the manifest line; `check_manifest` compares string equality, so this refuses the build. Scope: target-path changes only — see finding N1 for target *content*.
3. **`compute_manifest` cannot silently produce an empty manifest.** `[ "${#files[@]}" -gt 0 ]` at `:96` returns 1 with a message; and on the `bless` path a non-zero `compute_manifest` aborts `bless_manifest` under `set -e`. The all-symlinks degenerate case (every regular file replaced by a link) hits this guard rather than blessing a link-only manifest. Scope: read-static plus the guard's own arithmetic; the degenerate case is not in the suite.
4. **All nine `-C` literals are byte-identical to the `-A`/`-I` that install them**, so the loop cannot drift from the ruleset by transcription. *Executed:* grep of both sides, compared field by field. Scope: string identity only — it does **not** establish that real iptables accepts or canonicalises them the same way (N2b).
5. **A `-C` failure, from a missing rule or from a 5-second xtables-lock timeout, aborts into forced DROP.** `exit 1` inside the loop reaches the EXIT trap with `FIREWALL_COMPLETE=0` and `LOCK_TIMED_OUT=0`. *Executed:* bats cases 971 and 1011 both assert non-zero status and `iptables -w 5 -P OUTPUT DROP` in the command log. Scope: against the PATH stub.
6. **`LOCK_TIMED_OUT` cannot be seeded from the environment**, in this script, with or without sudo's `env_reset`: it is unconditionally assigned at `:273` before the trap is armed at `:310`, and the only other write is at `:384`. Scope: read-static, exhaustive over the three occurrences in the file (grep).
7. **A lock-wait timeout no longer forces DROP over the holder's boundary.** *Executed:* bats case 944 asserts zero `-P OUTPUT DROP` in the command log on the timeout path — the exact inversion of the assertion it replaces. Scope: the DROP half is genuinely pinned; the message half is not (the `fails CLOSED` assertion is vacuous — N3).
8. **The flush window is closed regardless of concurrency.** Phase B sets all three DROP policies at `:588-590` before `iptables -F` at `:593`, so no interleaving of runs exposes empty chains under an ACCEPT policy. Scope: read-static, corroborated by bats case 413.
9. **The suite and linter are green at this commit.** *Executed here:* `bats test/init-firewall-rules.bats test/cc-isolated-functions.bats` → 120 ok, 0 not ok; `shellcheck devcontainer-config/cc-isolated.sh devcontainer-config/init-firewall.sh` → clean. Scope: this sandbox, this commit. Note the commit message says 420/420 bats across the whole suite; I ran only the two files in scope.

Claims I explicitly decline to make: that the nine `-C` specs are accepted by a real kernel (N2b, unexecutable here); that content behind a symlink is protected (N1, executed to the contrary); that the ownership trigger resists path aliasing (r4 #4, carried).

---

### Untested bypass candidates

Three per touched guardrail, as briefed. **Tested** = executed in this sandbox. **Listed** = reasoned, not executed.

**Against the lock stand-down (`LOCK_TIMED_OUT`)**

| # | Candidate | Status | Result |
|---|---|---|---|
| L1 | Seed `LOCK_TIMED_OUT=1` in the environment so *any* abort stands down instead of forcing DROP | **Tested** (read-static, exhaustive grep: 3 occurrences) | Refuted. `:273` overwrites unconditionally before the trap arms at `:310`; no `${LOCK_TIMED_OUT:-…}` read of the environment exists. `env_reset` is a second layer, not the only one. |
| L2 | Queue N runs so a later one times out and stands down over a torn-down boundary | **Listed** (the interleaving is constructed from the timeouts and phase ordering; a live 4-run pile-up is not executed) | Refuted as an opening. Phase B DROPs before it flushes (`:588-593`), so a stand-down during a rebuild leaves DROP; a stand-down during phase A leaves the previous intact ruleset. What it *does* achieve is quiet failure of runs 4+ — which is the correct outcome. |
| L3 | Kill the lock holder mid-phase-B so the waiter stands down over a half-built ruleset | **Listed** (root-signalling is not attemptable as `node` here) | Refuted twice over. `node` cannot signal a root process; and even an external `SIGKILL` closes fd 9, releasing the lock immediately, so the waiter *acquires* instead of timing out. A timeout structurally implies a live holder. |
| L4 | Hold the lock as `node` so every re-assert stands down | **Listed** (pinned by bats case 937) | Refuted. `/run/cc-firewall` is 0700 root; `node` cannot open the file, and `flock` needs an fd. |
| L5 | Wedge a holder forever inside the lock so the waiter stands down over an unbuilt boundary | **Listed** | **Not refuted** — this is N3's residual. Not `node`-reachable (needs a root process wedged on an unbounded call inside the lock, or a root operator holding the file by hand), but it is the one interleaving where the stand-down is worse than the behaviour it replaced. |

**Against symlink hashing**

| # | Candidate | Status | Result |
|---|---|---|---|
| S1 | Repoint a `claude-home/` symlink at attacker content after a bless | **Tested** | Refuted. Manifest line changes; `check_manifest` refuses. This is the control working. |
| S2 | Leave the link path alone and rewrite the **content behind it** | **Tested** | **Confirmed** — byte-identical manifest across a content change to both a `claude-home/` link target and the symlinked `init-firewall.sh`. This is N1. |
| S3 | Point a `claude-home/` link at a node-writable in-container path (`/home/node/…`, `/workspace/…`) so the agent controls "baked" payload | **Listed** (the `COPY` semantics half is documented behaviour, not executed) | Refuted for the agent, residual for the host. Creating or repointing the link changes the manifest (S1), so it requires a bless — a human host action by someone who could edit the payload files directly and re-bless anyway, i.e. no privilege gained. And the config dir is in no bind mount, so `node` cannot author the link. The link's *target text* being hashed is what closes this; note that if such a link were ever blessed, N1 means its content would then be permanently unhashed. Treat "a link whose target is inside the container" as a bless-time review item. |
| S4 | Swap a regular enforcement file for a symlink whose target text collides with the file's content hash | **Listed** | Refuted. Requires a sha256 preimage. The manifest line changes on any type swap in either direction (regular↔link), because the two branches hash different bytes. |
| S5 | Add a file to `claude-home/` that the walk's type filter still misses (fifo, socket, device, or a directory whose *contents* are only reachable through a link) | **Listed** | Partially open, sub-Low. `\( -type f -o -type l \)` still excludes fifos/sockets/devices — none of which carry executable payload, and `install.sh`'s `cp -r` does not usefully reproduce them. `find` without `-L` does not descend *through* a link to a directory, so files under a linked directory are represented only by the one link line; combined with N1 that is the same gap, not a new one. |
| S6 | Make `enforcement_files`' subshell fail so `compute_manifest` emits a short manifest that a bless then freezes | **Tested** (the `set -e` exemption executed: `( cd /nonexistent && echo A; echo B )` prints `B` and returns 0) | Refuted as reachable. The `cd "$cfg" &&` failure is exempt from `set -e` and would skip `sha256sum` while the link loop still ran — but `enforcement_files`' own `cd "$cfg" || return 0` plus the `[ ! -f "$cfg/$f" ]` check at `:89` turn an unreachable `cfg` into a hard error first. Recorded in the sweep as a latent shape, not a live path. |

**Against the `-C` loop**

| # | Candidate | Status | Result |
|---|---|---|---|
| C1 | Have a broader installed rule satisfy a narrower `-C`, masking a real absence | **Listed** (`unshare -rn` denied here; documented `-C` semantics) | Refuted. `-C` is an exact-spec match, not a subset test. No pair among the nine can satisfy another. |
| C2 | Reorder the OUTPUT chain so the ipset ACCEPT precedes `CC_SNI_GUARD`, keeping all nine rules present | **Listed** | **Confirmed as a blind spot** of the loop (N2a) — all nine `-C` still pass. Not reachable at runtime (linear script, 0555 root-owned, baked) and pinned by bats `:785-790` on install order, so it is a maintenance hazard rather than a live bypass. |
| C3 | Exploit `2>/dev/null` to hide a real iptables error as a benign "rule missing" | **Listed** | Refuted as an opening: with `-w 5`, a contended lock becomes a timeout → non-zero → `exit 1` → forced DROP. Correct direction. The cost is diagnostic only: a malformed spec and a missing rule produce the same operator-facing line. |
| C4 | Drop the OUTPUT **policy** while keeping all nine rules present | **Listed** | Open, sub-Low → folded into N2's recommendation (3). The loop never reads back `-P OUTPUT DROP`; the policy is set at `:590` and re-asserted at `:945` under `set -e`, so absence implies an abort, which the trap catches. Defence in depth only. |
| C5 | Exploit `-w` before `-t` argument ordering (`iptables -w 5 -t nat -C …`) to make the call a silent no-op | **Listed** (real-kernel parse not executable here) | Not refuted, low likelihood. iptables option parsing is order-independent and the same `-w 5 -P` form is already used in the trap, but `-w`'s optional-argument getopt handling is a known rough edge and no test parses these strings with a real binary. Covered by N2's recommendation (1), the live-container check. |
| C6 | Add rule twelve without adding its `-C`, so the loop's "load-bearing rules" set silently falls behind | **Listed** | Open by design and correctly so after this range — the comment no longer claims exhaustiveness. The mitigation is documentation, not code: N2's recommendation (2). |

---

### Primitive sweep

Sub-Low observations, recorded rather than filed.

- **`(cd "$cfg" && sha256sum …)` is exempt from `set -e`.** Executed: a failing `cd` in a `&&` list inside a subshell does not abort the subshell, and following commands run. Here that would mean the link loop running `readlink` in the wrong cwd while `sha256sum` was skipped, with the subshell exiting 0. Unreachable (see S6), and the outcome would be a manifest mismatch → refuse to build → fail-closed, unless bless and check both hit it identically. Cheap hardening: `cd "$cfg" || return 1` as its own statement before the subshell body.
- **A failed `bless_manifest` leaves an empty manifest file.** `compute_manifest > "$(manifest_path)"` truncates before it runs, so a mid-bless failure leaves a zero-byte `manifest.sha256`. `check_manifest`'s "no blessed manifest" branch (`[ ! -f ]`) then never fires; the user gets the diff error instead. Fail-closed, cosmetic. Write to a temp file and `mv` if you want the error message to stay accurate.
- **`sort -k2` on paths containing blanks.** `-k2` runs field 2 to end of line, so a path with spaces still sorts and compares deterministically under `LC_ALL=C`. No issue found; noted because the sort key is new in this range.
- **`readlink` / `while read -r f` on a name containing a newline.** A payload filename with an embedded newline splits into two manifest entries and, for a symlink, `$(readlink "$f")` strips trailing newlines from the target. The config dir is host-side and human-controlled, so this is a note, not a hole — as r4 also recorded.
- **`CC_EGRESS_OWNER_CHECK` narrowed from `-n` to `= "1"`.** `CC_EGRESS_OWNER_CHECK=0` or `=yes` no longer forces the check. The change can only *remove an extra* assertion, never a required one, and the variable is test-only and env-stripped under sudo. Correct direction; noted for completeness.
- **`EGRESS_DIR_DEFAULT` is a plain assignment, not `${…:-}`.** Confirmed at `:44` — `node` cannot redefine the constant the ownership trigger keys on, which was the point of extracting it.
- **Test gap: the tcp twin of the new DNS-guard `-C` is unasserted.** Bats case 980 greps for `-C OUTPUT -p udp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD` but not its `-p tcp` sibling, though both are in the loop. Harmless asymmetry; one more `grep -q` closes it.
- **`run` clobbering `$output`** at `test/init-firewall-rules.bats:954-956` — the vacuous assertion described in N3. Worth a grep across the suite for the same shape.
- **Log ordering fixed.** Moving the `-C` loop below the "Firewall configuration complete" / "Verifying firewall rules…" banners means the verification failures now print under the verification banner instead of before it. Small, real operator-legibility win from this range.

---

### Summary Table

| # | Finding | Severity | Boundary | Confidence | Evidence mode |
|---|---|---|---|---|---|
| N1 | Symlinks blessed by target text, not content — strictly weaker than f313de7 for links that resolve; `devcontainer.json` is dereferenced by the host CLI | Low | B2 | High | Executed (both commits, fixture) |
| N2 | The nine-rule `-C` loop is presence-only (blind to the guard-before-ACCEPT ordering) and its literals are never parsed by a real iptables | Low | B4, B7 | Medium-High | Static + executed grep; real-kernel half not executable here |
| N3 | The stand-down's safety rests on an unstated invariant (timeout ⇒ live holder); one wedged-holder residual; the test's second assertion is vacuous | Low | B3, B6 | High (mechanism) / Medium (residual) | Static + executed fd/`set -e` semantics |
| r4 #4 | Ownership trigger is still an unnormalised byte compare | Low | B3a | High | Carried forward, not re-filed |
| r3 #3 | IPv6 posture point-in-time; phase-B `ip6tables` takes no `-w` | Low | B4 | High | Carried forward, not re-filed |

Counts for this range: **0 Critical, 0 High, 0 Medium, 3 Low new, 2 Low carried.**

---

### Overall Assessment

**Nothing in this range is above Low.** No Critical, High or Medium finding; three new Low findings and two Low findings carried forward unchanged from earlier passes. All four r4 findings are addressed — three closed as filed (the manifest walk, the `-C` coverage, the lock stand-down), one narrowed with its residual carried (the ownership string compare).

The two fixes that carried real weight are demonstrably correct. The empty-`projects/` bug was worse than the r4 report's framing suggested — at f313de7 a fresh install blessed *none* of the ~100-file baked payload, and I executed both versions side by side to confirm the fix. The lock stand-down does exactly what r4 recommended and I could not construct a node-reachable sequence that ends with a stand-down over an open boundary; the argument turns on phase B setting DROP before it flushes, and on a `flock` timeout structurally implying a live holder with an armed trap, since the lock is released by process death.

**Ship pending the live-container check.** That qualifier is not a formality and it is not about N1 or N3 — it is N2b. Nine `-C` specs are asserted at every run, all nine gate completion, and *not one of them has ever been parsed by a real iptables binary*: the suite's `iptables` is a PATH stub that logs argv and returns 0, and the positive test greps the log for the strings the script emitted. If any literal — most plausibly the `! -d 127.0.0.1` negation on the two newly added DNS-guard entries, or `-w 5` preceding `-t nat` — is canonicalised differently by the kernel's parser than by the `-A` that installed it, every run fails verification and forces DROP: safe, but a hard brick recoverable only by `devcontainer up --remove-existing-container`. One `devcontainer up` retires that risk and no amount of unit testing can.

Of the three new findings, **N1 is the one I would fix before the next bless**, for the same reason r4 said it of its own N1: it is a coverage loss in a control this commit touched, it moves a property *backwards* relative to the commit it replaces, and the fix is two lines (hash the resolved content alongside the link text). N2 and N3 are documentation and test-quality work — real, but they defend invariants that are currently held by construction rather than by the mechanism a maintainer will read.

120/120 bats and clean `shellcheck` at this commit, executed here.

---

### Goal-Alignment Note

The stated goal was a confirming pass: status the four r4 findings and examine the new code as attack surface. I read that as a request for a genuine adversarial pass, not a sign-off, so where the brief's framing and the code disagreed I followed the code — most consequentially on the symlink fix. The brief describes r4 finding 1 as "now hashed by target", which is accurate and which I confirmed; but hashing *by target* is the whole of what the fix does, and because `sha256sum` dereferences, a symlink that resolves was better covered before this commit than after. I filed that as N1 with the regression executed against both commits rather than recording finding 1 as simply closed. If the intended reading was that content-behind-link is explicitly out of scope, N1 collapses to a note.

Two limits on this pass worth naming. First, the fact-check for this round was not available: `docs/reviews/code-fact-check-report.md` is pinned to `563448a`, two commits behind, so — per the brief's instruction — I proceeded on code reading and executed anything load-bearing myself rather than importing conclusions about a different commit. Nothing here rests on a fact-check claim. Second, this sandbox has `iptables` but no `CAP_NET_ADMIN` and `unshare -rn` is denied, so the `-C` matching semantics that N2's second half turns on could not be executed. I marked those candidates **Listed** rather than Tested and escalated the gap into the Overall Assessment as the one thing standing between this range and an unqualified ship, instead of quietly reasoning past it.

I also did the reverse where it was warranted: the brief flagged the stand-down as "examine as new attack surface" and pre-loaded a specific worry (a fresh container with ACCEPT policy). I chased it and it does not hold — phase B DROPs before it flushes, and on a fresh container no `node` process exists to race the only run. Rather than manufacture a finding to match the prompt's shape, N3 states why the guardrail is sound, files the narrow residual that survives (a wedged holder), and adds the one thing I found that the brief did not anticipate: the bats assertion that appears to pin the new behaviour reuses `$output` from the preceding `run` and is therefore a no-op. Nothing was inflated to reach a Medium; the floor rule was applied as written, and eight sub-Low observations went to the Primitive sweep instead of the findings list.
