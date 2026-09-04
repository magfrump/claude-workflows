# Performance Review — egress hardening pass 3, 2839e59..1434fc9

Commit: 1434fc9

**Scope:** `git diff 2839e59..1434fc9 -- devcontainer-config/` — `init-firewall.sh` (the only file with executable changes of consequence; the lock block, the IPv6 precondition block, the phase-B IPv6 block, the ownership assertion, `parse_entry`/`compose_dnsmasq_conf`, and the verification-probe tail read end to end at HEAD, plus `stop_dnsmasq` and the dnsmasq/proxy start blocks as the other occupants of the new critical section), `cc-sni-proxy.py` (a docstring and one log-message string; `daemonize`/`stop_prior` read at HEAD as critical-section occupants), `Dockerfile` (three `chown`-scoping hunks, build-time only). `test/init-firewall-rules.bats` and the docs in the range are committed context, not under review — the suite was executed to obtain the stubbed baselines below.
**Date:** 2026-09-03
**Based on:** `docs/reviews/performance-review-2026-09-03-egress-hardening-r2.md` (pass 2, on 2839e59) and the loop-pass fact-check at k=1 on 6eaa9a0 (411 bats / 13 python / shellcheck green; lock placement verified after every `curl`/`dig`)

---

### Prior findings status

| Prior # | Finding | Status | Note |
|---|---|---|---|
| r2-1 | Lock wait (120 s) shorter than the run's own worst-case hold, which spanned phase A's network reads | **Fixed in substance; residual re-filed as r3-1 and r3-2** | The lock moved from the top of the script to `:536-544`, immediately before the `iptables-save` at `:551` and after every phase-A read. The hold is no longer N-linear: worst case falls from ≈228 s (union profile, N=24) to a bounded ≈69 s against the unchanged 120 s wait. Two things did not come with it: the critical section still contains 60 s of verification `curl`s and one unbounded wait (r3-2), and phase A is now unserialised, which creates a new failure for the second run (r3-1). |
| r2-2 | IPv6 probe + nine unwaited `ip6tables` calls inside the flush→rebuild window | **Fixed** | The `command -v ip6tables && ip6tables -w 5 -S OUTPUT` probe moved to phase A at `:509-517` and stores `IP6_FILTER`; `:582` now branches on the variable, so the window at `:560-596` contains only the nine enforcement calls. The new `elif` calls `ip -6 addr show scope global` only on the probe-failure path. Regression-guarded at `test/init-firewall-rules.bats:954`. One consequence is re-filed at Informational as r3-3: the probe's `-w 5` now sits outside the flock, where it can contend with a concurrent run's netfilter writes. |
| pass1-1 | Proxy connects to `infos[0]` only; no fallback, no reconciliation with the ipset snapshot | Deferred by decision — tabled, not re-filed | `handle()` is byte-identical in this range; the only `cc-sni-proxy.py` changes are the `log()` docstring and the `FAIL` message wording. |
| pass1-2 | No supervisor: a proxy death after startup is a silent, session-long HTTPS outage | Deferred by decision — tabled, not re-filed | Unchanged. The end-of-run negative probe got stricter (`:1074`, `:1078`), which still only proves the proxy was alive at the end of the run. |
| pass1-3 | `getaddrinfo` per connection, no in-process cache | Deferred by decision — tabled, not re-filed | Unchanged. |
| pass1-4 | No concurrency cap and no idle timeout after the ClientHello | Deferred by decision — tabled, not re-filed | Unchanged. |
| r2-5/6/7 | Proxy log growth; `ESTABLISHED,RELATED` rule depth; ~90–140 `ipset add` forks | Open, unchanged in kind | The log grep at `:1078` got a longer needle (it now pins `orig_dst=`), which does not change its cost over an `O_TRUNC`-fresh file. Rule depth is untouched. `ipset add` count re-measured at HEAD under the stubs: **11** at `base`, and the parse still yields **5** entries at `base` / **24** at the union of all seven profiles. |

---

### Data Flow and Hot Paths

Nothing in this range touches a hot path. `handle()` and `pump()` are unchanged, dnsmasq's per-query path is unchanged, and the one proxy edit that executes per connection — the `FAIL` log line's wording — is on an error path and costs the same `print`.

All of the range's cost lands on the **cold** path: `init-firewall.sh` runs once per container start via `devcontainer.json` `postStartCommand` with `"waitFor": "postStartCommand"`, plus once more on the launcher's re-assert. Both block session start, so added seconds are user-visible; that is the whole reason the lock's scope matters.

**The structural change.** The script's serialisation boundary moved. It used to be:

```
[lock] phase A (curl + N digs, network) → phase B (rebuild + daemons + probes) [unlock at exit]
```

and is now:

```
phase A (curl + N digs, network, UNSERIALISED) → [lock] phase B (rebuild + daemons + probes) [unlock at exit]
```

Everything below follows from that one move: the hold shrank and stopped scaling with N (the win), and phase A gained a concurrency exposure it did not have (findings 1 and 3).

**Measured local floor, this checkout.** Under the suite's stubs (`test/init-firewall-rules.bats` setup, base profile, three repetitions): a complete run is **207 / 214 / 269 ms** wall, and a run that reaches the lock and fails it immediately (`CC_FIREWALL_LOCK_WAIT=0` against an externally held lock) is **89 / 91 / 103 ms**. So phase A is ≈95 ms and **phase B's local work is ≈120–165 ms** with every exec stubbed. Exec census for one stubbed base run: 91 logged commands — 51 `iptables`, 1 `iptables-save`, 13 `ipset` (11 of them `add`), 10 `ip6tables` (the phase-A probe plus the nine enforcement calls), 5 `dig`, 5 `curl`.

**Real-world cost of the same execs.** Measured in this sandbox: `iptables -S OUTPUT` ≈ 9.3 ms, `ip6tables -w 5 -S OUTPUT` **10.46 ms**, `ip -6 addr show scope global` **10.25 ms**, `command -v ip6tables` 0.02 ms, `stat -c '%u'` **0.73 ms**, `find <dir> -maxdepth 0 -perm /022` **2.95 ms**, `mkdir -p` 0.70 ms, `chmod` 0.56 ms, `dirname` 0.56 ms. So the ~75 netfilter execs of a base-profile phase B are **≈0.8 s** of real fork+netlink work, against a stubbed 0.12–0.17 s.

**What the new critical section actually contains,** in order from `:544`:

| Step | Line | Bounded cost |
|---|---|---|
| `iptables-save`, flush, DROP policies, IPv6 block, ipset build, ~75 netfilter execs | `:551-770` | ≈0.8 s at `base`; more at the union profile (more `ipset add`) |
| `stop_dnsmasq` kill-and-wait | `:456-471` | ≤3.0 s |
| dnsmasq pidfile poll (`seq 1 30` × `sleep 0.1`) | `:786-789` | ≤3.0 s |
| SNI proxy `--daemon` readiness handshake | `:993-995` → `cc-sni-proxy.py:249-263` | `stop_prior` ≤3.0 s, then `os.read(r, 4096)` with **no timeout** |
| four verification `curl`s at `--max-time 15` | `:1030`, `:1038`, `:1047`, `:1063` | ≤60.0 s |
| nat `-C` assertion + log `grep` | `:1074`, `:1078` | ≈10 ms |

Bounded total: **≈69 s**, against `CC_FIREWALL_LOCK_WAIT` still defaulting to 120 s. The unbounded term is the readiness read.

**Concurrency sources** are unchanged from r2: `node` has NOPASSWD sudo on this script and can invoke it at will, and two `cc-isolated` launches against the same project each reach the re-assert path. `devcontainer up` + `postStartCommand` cannot overlap the launcher's own re-assert.

---

### Findings

#### Phase A is now unserialised, so a second run does 15 s + 6 s×N of network work inside the winner's egress blackout — and throws it away with a fatal `dig`

**Severity:** Medium
**Location:** `devcontainer-config/init-firewall.sh:523-544` (the complete ONE REBUILD AT A TIME block including its eleven-line rationale, read whole), against the phase-A work it no longer covers at `:336-430` (the `/meta` fetch at `:363`, the `dig` loop at `:390-430`) and the blackout it now overlaps at `:560-571` and `:772-790`
**Move:** #3 — work in the wrong place (the second run's network reads now execute against a ruleset the first run is mid-way through demolishing), #7 — contention, and #1/#5 — a hidden multiplication with no cache (two overlapping runs each pay phase A in full, where one used to wait and pay it once)
**Classification:** Macro (the second run does not slow down, it exits 1 into the fail-closed trap) / **Cold** path (`postStartCommand` with `"waitFor": "postStartCommand"`, plus the launcher re-assert) → matrix Medium
**Confidence:** High on the mechanism and on the blackout's existence; Medium on how often it is hit, since it needs two runs to overlap and the blackout is a few seconds out of a run that lasts tens
**Baseline:** measured, this checkout. Phase A under the stubs is **≈95 ms** (89/91/103 ms across three runs) — i.e. essentially all of its real duration is network, bounded by the code at `15 s` (`curl --max-time 15`, `:363`) `+ 6 s × N` (`dig +time=3 +tries=2`, `:401`), with N measured at HEAD via `--print-entries` = **5** (`base`) / **24** (union of all seven profiles): **45 s** to **159 s** of discardable network work. The blackout window it can land in is phase B from the flush at `:565` until dnsmasq and the `CC_DNS` nat chain are back at `:790`: ≈75 netfilter execs at a measured 9.3–10.5 ms each ≈ **0.8 s**, plus `stop_dnsmasq`'s ≤3 s and the pidfile poll's ≤3 s — call it **1–7 s** of no egress and no resolver.
**Evidence:**
> ```
> # Serialise phase B on a root-owned lock. Phase A (network reads, no rule changes)
> # deliberately runs OUTSIDE the lock: concurrent phase-A runs are harmless, and
> # keeping the critical section to the ~sub-second rebuild means a waiting run is
> # never held for the length of a slow resolution.
> ```
> (`init-firewall.sh:527-530`; the excerpt is four lines of the twelve-line rationale at `:523-535`, all of which was read — the remainder covers the 0700 lock directory, the post-trap ordering, and the test-only env overrides.)
**Legibility-target:** for-author

"Concurrent phase-A runs are harmless" is true of phase A against *phase A*, and false of phase A against *phase B*. Phase B sets the three DROP policies and flushes filter, nat and mangle at `:560-571`, destroys the ipset, and only rebuilds the accepts and restarts dnsmasq several hundred milliseconds later; between those points the container has no egress and no resolver. A second run whose phase A is in flight during that window gets a failed `/meta` fetch — benign, it is `|| true` and merely drops the GitHub CIDRs from *that* run's allowlist, which is itself a silent narrowing worth knowing about — and failed `dig`s. Most of those are warn-and-skip, but `api.anthropic.com` is fatal by design, so the likely outcome is `exit 1` into the EXIT trap. The old placement made this impossible: the second run blocked at the lock and then ran phase A against a complete, healthy ruleset, so it succeeded. The move therefore trades a guaranteed-correct 120 s wait for a probable hard failure, and pays for the failure with up to 159 s of network I/O that is discarded. This is precisely the caveat r2's recommendation (a) named before the trade was taken; recording it is not re-litigating the choice, it is filing the residual the choice left. Failure mode: **unserialised read phase overlapping a serialised destroy-and-rebuild phase, so the reader's inputs are destroyed by the writer and the reader's most important read is fatal.**

**Recommendation:** Keep the lock where it is — the N-linear hold was the worse problem — and close the residual instead, cheapest first. (a) Make the second run's phase A cheap to abandon: take the lock in non-blocking mode (`flock -n 9`) *before* phase A purely as a "someone else is rebuilding" test, release it, and if it was held, wait on the real lock first and then run phase A — so the loser waits idle rather than resolving into a blackout. (b) Failing that, retry the `api.anthropic.com` resolution once after a short sleep before treating it as fatal at `:390-430`; a single retry covers the entire 1–7 s blackout and costs nothing on the uncontended path. (c) Independently, correct `:529-530` — "the ~sub-second rebuild" understates the section by two orders of magnitude (see finding 2), and a reader sizing the 120 s wait against that sentence will size it wrong.

---

#### The critical section is documented as sub-second but is bounded at ≈69 s and unbounded in one place

**Severity:** Low
**Location:** `devcontainer-config/init-firewall.sh:529-530` (the claim) against its occupants: `stop_dnsmasq` at `:456-471`, the dnsmasq pidfile poll at `:786-789`, the proxy readiness handshake at `:993-995` → `devcontainer-config/cc-sni-proxy.py:242-263` (`daemonize` read whole, with `stop_prior` at `:219-239`), and the four probes at `:1030`, `:1038`, `:1047`, `:1063`
**Move:** #7 — contention (the size of the critical section is the thing under review), and #2 — what is the size of N (here N is seconds of timeout budget, not list length)
**Classification:** Macro (an unbounded hold means every later run fails closed after its full wait, which is a failure, not a slowdown) / **Cold** path → matrix Low, because the bounded part now fits inside the wait with 51 s of headroom and the unbounded part needs a hung fork to reach
**Confidence:** High on the arithmetic and on `os.read` having no timeout; Low on the hang ever occurring
**Baseline:** measured, this checkout: phase B's local work is **120–165 ms** stubbed (215/214/269 ms full run minus 91/89/103 ms phase A, three repetitions) and **≈0.8 s** estimated real from the exec census (51 `iptables` + 1 `iptables-save` + 13 `ipset` + 10 `ip6tables` = 75 netfilter execs × 9.3–10.5 ms measured). Added to that from the code: ≤3 s `stop_dnsmasq` + ≤3 s pidfile poll + ≤3 s `stop_prior` + 4 × 15 s probes = **≈69 s bounded**, versus `FIREWALL_LOCK_WAIT` default **120 s**.
**Evidence:**
> ```
>     if pid:
>         os.close(w)
>         os.close(log_fd)
>         msg = os.read(r, 4096)
> ```
> (`cc-sni-proxy.py:253-256`; the excerpt is the parent half of the fork — the rest of `daemonize` at `:242-292`, including the `stop_prior` call, the fd sweep and the child's `setuid`/`asyncio.run`, was read.)
**Legibility-target:** for-author

The r2 defect — a fixed wait shorter than a variable hold — is genuinely closed, and by the better of the two levers: the hold no longer scales with the allowlist at all, so it cannot be pushed past the wait by adding a profile. What remains is that the section is not "sub-second". Sixty of its worst-case seconds are the four verification `curl`s, which are network by nature and hold the lock only because fd 9 is never released before them (there is no `flock -u` and no `exec 9>&-` anywhere in the script — the lock lives until the process exits). Those probes verify a ruleset that is already installed and already global; nothing about them needs mutual exclusion, and a run that reaches them has finished the work the lock exists to protect. The one genuinely unbounded term is the readiness handshake: the parent blocks in `os.read` with no timeout, and a child that hangs after `fork` but before writing `ready` — a wedged `getpwnam` against a slow NSS module, a stall inside `asyncio.run`'s socket setup — parks the parent, and the lock, forever. A dead child is handled (the write end closes and `read` returns empty); a *hung* one is not. This is not a regression — the old placement held the lock across it too — but it is the single line that decides whether "bounded by 69 s" is a guarantee or an expectation. Failure mode: **a documented bound that is two orders of magnitude off, over a section whose real bound depends on one untimed read.**

**Recommendation:** Two one-liners. Release the lock before the verification block — `flock -u 9` immediately after `echo "Firewall configuration complete"` at `:1027` — which cuts the worst case from ≈69 s to ≈9 s and takes all four probes out of the section; the probes read the ruleset they no longer need to own. And bound the readiness read: `select`/`poll` on `r` with a timeout of a few seconds in `cc-sni-proxy.py:256`, treating expiry the same as an empty read. Then restate `:529-530` with the real number rather than "sub-second".

---

#### The phase-A IPv6 probe now waits on the xtables lock outside the flock, where the phase-B calls it must not collide with carry no `-w`

**Severity:** Informational
**Location:** `devcontainer-config/init-firewall.sh:500-518` (the complete IPv6 precondition block, read whole) against the nine bare enforcement calls at `:582-593` and the 51 bare IPv4 calls elsewhere; same root cause as finding 1
**Move:** #7 — contention (a lock that the serialisation boundary no longer covers)
**Classification:** Micro (a bounded 5 s wait, or one failed exec) / **Cold** path → matrix Informational
**Confidence:** High that the probe is now outside the flock and that the enforcement calls are bare; Medium on the xtables lock being taken by a `-S` under the nf_tables backend, which I could not verify in this sandbox
**Baseline:** measured where measurable: `ip6tables -w 5 -S OUTPUT` **10.46 ms/call**, `ip -6 addr show scope global` **10.25 ms/call**, `command -v ip6tables` 0.02 ms — all on this sandbox's permission-denied fast path (`iptables v1.8.9 (nf_tables)`, uid 1000), so a floor rather than the real netlink cost. For the contention itself, **no baseline available — flagged as speculative**: reproducing it needs root, and holding a lock file by hand did not reach the code path (the probe failed on permissions in 1 ms before any locking).
**Evidence:**
> ```
> IP6_FILTER=0
> if command -v ip6tables >/dev/null 2>&1 && ip6tables -w 5 -S OUTPUT >/dev/null 2>&1; then
>     IP6_FILTER=1
> elif [ -n "$(ip -6 addr show scope global 2>/dev/null || true)" ]; then
> ```
> (`init-firewall.sh:509-512`; the excerpt omits the nine-line rationale at `:500-508` and the three-line fatal error at `:513-516`, both read.)
**Legibility-target:** for-author

The placement fix is right and does what r2 asked: the probe is a precondition, it now sits with the other preconditions, the fatal `ip -6 addr` branch runs before anything is flushed, and the window at `:560-596` contains only enforcement. The side effect is that the probe moved from inside the serialised region to outside it. `iptables` and `ip6tables` share one `/run/xtables.lock` across both families, so a second run's phase-A probe — which explicitly waits up to five seconds for it — can now hold that lock while the first run, inside the flock, issues `ip6tables -P INPUT DROP` with no `-w` and gets "another app is currently holding the xtables lock", `set -e`, fail-closed trap, a container at DROP with no accepts. The old placement made this collision impossible because both runs' netfilter access was under one flock. The exposure is small — a 5 ms-scale write against a 5 s-scale wait, needing two overlapping runs — and it matches the file's own convention, since only the trap's four calls carry `-w` out of 61 netfilter invocations. It is worth recording because the flock no longer covers it and the r2 report reasoned that it did.
Failure mode: **a lock-waiting reader moved outside the mutual exclusion that used to make its wait irrelevant, against writers that do not wait at all.**

**Recommendation:** Add `-w 5` to the netfilter calls file-wide (a mechanical `iptables` → `iptables -w 5` sweep plus the same for `ip6tables`), not to this block alone — a partial fix reads as a distinction that is not there. If that is too broad for this wave, finding 1's recommendation (a) closes this one as a side effect, since a loser that never enters phase A never runs the probe.

---

### Endorsements (evidence-gated)

- r2 finding 1 is closed on its stated defect: the hold no longer contains phase A, no longer scales with the allowlist, and its worst case drops from ≈228 s at the union profile to a bounded ≈69 s against an unchanged 120 s wait — the arithmetic no longer inverts for any profile. Phase B's local work measures at 120–165 ms stubbed. `[read: devcontainer-config/init-firewall.sh:523-551, :1027-1082]`
- r2 finding 2 is closed as recommended: the probe is in phase A at `:509-517` storing `IP6_FILTER`, `:582` branches on the variable, and the flush→rebuild window at `:560-596` now contains exactly the nine enforcement calls it should. The `ip -6 addr` addition runs only on the probe-failure path, so the common case pays 10.46 ms, not 20.7 ms. `[read: devcontainer-config/init-firewall.sh:500-518, :572-596]`
- The ownership assertion is free and correctly gated: two `stat -c '%u'` at a measured 0.73 ms and two `find -maxdepth 0 -perm /022` at 2.95 ms is **7.4 ms per run**, against a run whose local floor alone is ~0.2 s stubbed and tens of seconds real — and the whole block is skipped when `CC_EGRESS_DIR` is set, so the test suite never pays it either. `[unverified — submitted as claim]`
- Hoisting `HOST_LABEL`/`HOST_RE` to file scope at `:129-130` is strictly cheaper than the previous per-call `local label=...`: the assignment now happens once instead of once per profile entry (5 at `base`, 24 at the union), and `compose_dnsmasq_conf` swapped an inline literal for the same variable at no cost. The `parse_entry` port-canonicalisation loop is untouched in this range. `[read: devcontainer-config/init-firewall.sh:121-160, :214-226]`
- The strengthened negative probe costs one exec: `iptables -t nat -C` at `:1074` is ≈10 ms, the `-z "$ANTHROPIC_PROBE_IP"` test at `:1056` is a builtin, and the `grep` at `:1078` merely got a longer needle over the same `O_TRUNC`-fresh log. The `Dockerfile` `chown` rescoping is build-time only and runs before `npm install -g` populates `npm-global`, so neither the old nor the new form walks a large tree. `[read: devcontainer-config/init-firewall.sh:1050-1082, devcontainer-config/Dockerfile:56-66, :416-421]`

---

### Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Phase A is unserialised, so a concurrent run resolves into the winner's 1–7 s egress blackout and discards 45–159 s of network work on a fatal `dig` | Medium | `init-firewall.sh:523-544` vs `:336-430`, `:560-571` | High (mechanism) / Medium (frequency) |
| 2 | Critical section documented as "~sub-second" is bounded at ≈69 s (four 15 s probes + three 3 s daemon waits) and unbounded at `cc-sni-proxy.py:256` | Low | `init-firewall.sh:529-530`, `:1027-1064`; `cc-sni-proxy.py:242-263` | High (arithmetic) / Low (hang frequency) |
| 3 | Phase-A `ip6tables -w 5 -S` now waits on the shared xtables lock outside the flock, against 61 bare netfilter writes | Informational | `init-firewall.sh:500-518`, `:582-593` | High (placement) / Medium (lock semantics) |

---

### Overall Assessment

Both r2 findings were answered, and the more important one was answered with the better of the two levers I offered: moving the lock to the head of phase B removes the N-linear term from the hold entirely, so the wait can no longer be outgrown by adding a profile — worst case ≈69 s against a 120 s wait, with 51 s of headroom, where before it was ≈228 s against the same 120 s. The IPv6 fix is exactly the recommended shape: probe in phase A, variable, branch in phase B, and a fatal path for the one genuinely unsafe combination, regression-guarded by two new tests. Nothing in the range touches a hot path, and the added local work measures out as noise — 7.4 ms of ownership assertion, 10 ms of nat-rule assertion, one `ip -6 addr` on a failure path only.

What the move left behind is the mirror image of what it fixed. The lock got smaller, and the thing outside it got exposed: phase A's 45–159 s of network reads now run against a ruleset another run may be demolishing, and the reader's most important read is the one that is fatal. That is worth a five-line guard — a non-blocking probe of the lock before phase A, or one retry on the `api.anthropic.com` resolution — because the symptom, "the second `cc-isolated` launch died resolving Anthropic", will be diagnosed as DNS or as network, and never as contention. Alongside it, two lines of hygiene: release fd 9 before the verification probes, which takes the worst-case hold from ≈69 s to ≈9 s and removes the only reason the section is long; and bound the proxy's readiness read, which is the one place the "bounded" claim is currently an expectation rather than a guarantee. Finally, the comment at `:529-530` should say what the section actually is — it currently reads "~sub-second" for something with a minute of `curl` budget in it, and comments of that kind are how the next reviewer sizes the next timeout wrong.

### Goal-Alignment Note
- Answered: yes — third-pass performance review of `devcontainer-config/` over `2839e59..1434fc9`, with r2 findings 1 and 2 verified as fixed (lock relocated to `:536-544` after every phase-A read and before `iptables-save` at `:551`; IPv6 probe relocated to `:509-517` with the phase-B block branching on `IP6_FILTER`), the four deferred proxy findings tabled without re-argument, the new critical section measured under the bats stubs (phase B = 120–165 ms local; ≈69 s bounded worst case; unbounded at one read), and three residuals filed. Report at `docs/reviews/performance-review-2026-09-03-egress-hardening-r3.md`.
- Out of scope: `test/init-firewall-rules.bats` and the docs in the range (committed context — executed for baselines only); the security questions the range answers (the `/usr/local/share` chown rescoping, the profile-tree ownership assertion, the single-label grammar tightening, the forged-`orig_dst` discriminator) belong to the security critic; the four deferred proxy findings were not re-argued.
- Escalate: (1) Finding 1 is the direct residual of the fix the author chose for r2-1 and is the one item I would not ship without — it turns a guaranteed-correct wait into a probable hard failure for a concurrent run, and the resulting error message names DNS, not contention. (2) Finding 3's `-w` gap is a file-wide convention question (4 of 61 netfilter calls carry `-w`), not a property of the IPv6 block; it needs an explicit decision from the author, and it is the same E2 residual r2 escalated and this range did not close. (3) The claim at `init-firewall.sh:529-530` that the critical section is "the ~sub-second rebuild" is factually wrong by ~2 orders of magnitude and should be routed to the fact-check pass as well as fixed here, since it is the sentence a future reader will use to size `CC_FIREWALL_LOCK_WAIT`.
