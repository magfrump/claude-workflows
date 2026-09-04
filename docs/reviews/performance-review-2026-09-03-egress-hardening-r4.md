# Performance Review — egress hardening pass 4, 1434fc9..f313de7

Commit: f313de7

**Scope:** `git diff 1434fc9..f313de7 -- devcontainer-config/` — two commits (`563448a` "close the pass-3 review findings", `f313de7` "pass-4 fact-check residuals"). Five files changed: `init-firewall.sh` (the lock block relocated to `:339-370` and rewritten, the new five-rule `-C` assertion loop at `:1042-1055`, the ownership-assertion gate at `:302-315`, the `9>&-` comment), `cc-isolated.sh` (`enforcement_files()` `:55-72`, `compute_manifest()` `:75-90`), `cc-sni-proxy.py` (`READY_TIMEOUT` + the `select` in `daemonize`), `Dockerfile` (sudoers hardening, build-time only), `egress/base.txt` (a comment). Read complete at HEAD, not as hunks: `enforcement_files` / `compute_manifest` / `bless_manifest` / `check_manifest` and `main`'s call site (`cc-isolated.sh:33-118`, `:397-410`); the ONE RUN AT A TIME block with its whole 20-line rationale (`init-firewall.sh:339-370`); `fail_closed_on_abort` (`:280-298`); `stop_dnsmasq` (`:781-795`) and the dnsmasq start/poll (`:798-807`); the SNI-proxy start (`:1007-1012`); the `-C` loop and the four verification probes (`:1042-1108`); `daemonize` and `stop_prior` whole (`cc-sni-proxy.py:221-303`). `test/init-firewall-rules.bats` and `test/cc-isolated-functions.bats` are committed context, not under review — executed for the baselines below.
**Date:** 2026-09-03
**Based on:** `docs/reviews/performance-review-2026-09-03-egress-hardening-r3.md` (pass 3, on 1434fc9) and the pass-4 fact-check at k=1 on 563448a (all executable guarantees reproduce; measured worst-case hold **209 s at N=25** against the then-current 300 s wait, exhausting at N≈40)

---

### Prior findings status

| Prior # | Finding | Status | Note |
|---|---|---|---|
| r3-1 | Phase A unserialised, so a second run resolves into the winner's 1–7 s blackout and discards 45–159 s of network work on a fatal `dig` | **Fixed, by the stronger of the two options offered** | The lock moved *up* rather than the guard being bolted on: `:339-370` now sits before `# PHASE A` at `:373`, so both phases are inside it. The r3 recommendation (a) — non-blocking probe, then wait, then phase A — would have left a race window; taking the real lock first removes the failure entirely rather than shrinking it. Regression-guarded at `test/init-firewall-rules.bats:944` ("the lock covers both phases"), which asserts no `curl`, no `dig` and no `iptables -F` reach `$CMD_LOG` when the lock is held externally. The cost side — the waiter now waits for the winner's whole run — is the deliberate trade, and it is the right one (see Overall Assessment); its one residual is filed below as finding 1. |
| r3-2 | Critical section documented as "~sub-second", actually ≈69 s bounded and unbounded at `cc-sni-proxy.py:256` | **Fixed on both halves** | The comment no longer claims sub-second: `:347-352` states the sizing term by term ("a 15 s meta fetch, up to 6 s per allowlisted name (~25 today), up to 39 s of daemon starts (the proxy's readiness bound is 30 s), and four 15 s probes: ~270 s"). The arithmetic checks out — 15 + 6×25 + 39 + 60 = 264 s, and the 39 s decomposes exactly as `stop_dnsmasq` 3 s + pidfile poll 3 s + `stop_prior` 3 s + `READY_TIMEOUT` 30 s. The wait rose 120 → 600 s and a non-numeric value now aborts instead of being silently repaired (`:360-363`). The unbounded read is bounded: `select.select([r], [], [], READY_TIMEOUT)` with SIGKILL + `waitpid` on expiry (`cc-sni-proxy.py:258-264`). I re-walked the remaining terms inside the lock for a second unbounded one and found none — `stop_prior` is a 30×0.1 s poll then SIGKILL, the child's error path is `os.write` immediately followed by `os._exit(1)` so the non-ready `waitpid` at `:270` cannot park, and all five network calls carry `--max-time 15`. The r3 recommendation to release fd 9 before the probes was **deliberately not taken**, and correctly so — `test/init-firewall-rules.bats:963` now pins `flock -u 9` at zero occurrences, with `:1103-1105` stating why. That is a correctness win that costs a waiter up to 60 s; see the Assessment. |
| r3-3 | Phase-A `ip6tables -w 5 -S` waits on the shared xtables lock outside the flock, against 61 bare netfilter writes | **Unchanged in code; accepted. Exposure narrowed as a side effect of r3-1** | No `-w` was added; 4 of 61 netfilter calls still carry it (the trap's). The escalation stands as a file-wide convention question. But the specific collision r3-3 described is now **impossible**: the probe at `:546` is downstream of the `flock` at `:367`, so no two `init-firewall.sh` runs can have one inside the probe and the other inside the bare phase-B writes. What remains is the generic residual — a bare write losing the xtables lock to *any* other netfilter user in the container — which is the pre-existing condition, not something this range introduced or worsened. This is exactly the close r3's own recommendation named as the side effect of fixing finding 1. |
| pass1-1 | Proxy connects to `infos[0]` only; no fallback, no reconciliation with the ipset snapshot | Deferred by decision — tabled, not re-filed | `handle()`, `pump()` and `serve()` are byte-identical in this range. |
| pass1-2 | No supervisor: a proxy death after startup is a silent, session-long HTTPS outage | Deferred by decision — tabled, not re-filed | Unchanged. `READY_TIMEOUT` bounds *startup*, not lifetime. |
| pass1-3 | `getaddrinfo` per connection, no in-process cache | Deferred by decision — tabled, not re-filed | Unchanged. |
| pass1-4 | No concurrency cap and no idle timeout after the ClientHello | Deferred by decision — tabled, not re-filed | Unchanged. |
| r2-5/6/7 | Proxy log growth; `ESTABLISHED,RELATED` rule depth; ~90–140 `ipset add` forks | Open, unchanged in kind | Rule depth grew by nothing (the five `-C` are queries, not rules). `ipset add` count re-measured at HEAD: **11** at `base`. Parse still yields **5** entries at `base` / **24** at the union of all seven profiles — identical to r3. |

---

### Data Flow and Hot Paths

**Nothing in this range touches a hot path.** `handle()` and `pump()` — the proxy's per-connection path — are untouched; the only `cc-sni-proxy.py` edit is in `daemonize`, which runs once per firewall run. dnsmasq's per-query path is untouched. The per-connection cost of an allowed HTTPS request is byte-for-byte what it was at 1434fc9.

All of the range's cost lands on two **cold** paths, and this range adds a second one that r3 did not have to consider:

**Cold path 1 — session start, in-container.** `init-firewall.sh` runs once per container start (`postStartCommand`, `"waitFor": "postStartCommand"`) and once more on the launcher's re-assert at `cc-isolated.sh:434`. The serialisation boundary moved again, and this time outward:

```
r3 (1434fc9):  phase A (curl + N digs, UNSERIALISED) → [lock] phase B + probes [unlock at exit]
r4 (f313de7):  [lock] phase A (curl + N digs) → phase B → probes [unlock at exit]
```

So the whole run is now one critical section. Two consequences, and they pull in opposite directions: the *winner* is unaffected (a `flock` on an uncontended file costs ≈1.0 ms measured), while the *loser* now waits for a full run — 15 s meta + 6 s×N + ≈39 s daemons + 60 s probes — instead of waiting for phase B alone and overlapping its own phase A with the winner's rebuild. That overlap was r3-1's defect, so the extra wait buys the loser's correctness.

**What the critical section contains at HEAD**, in order from `:370`:

| Step | Line | Bounded cost |
|---|---|---|
| `/meta` fetch (`curl --connect-timeout 5 --max-time 15`) | `:399` | ≤15.0 s |
| `dig +time=3 +tries=2` per allowlisted name | `:437` | ≤6.0 s × N (N = 5 base / 24 union) |
| IPv6 precondition probe | `:545-548` | ≈10.5 ms, or `ip -6 addr` on the failure path only |
| flush, DROP policies, ipset build, ~75 netfilter execs | `:560-780` | ≈0.8 s at `base` |
| `stop_dnsmasq` kill-and-wait | `:781-795` | ≤3.0 s |
| dnsmasq pidfile poll (`seq 1 30` × `sleep 0.1`) | `:799-802` | ≤3.0 s |
| SNI proxy `--daemon` handshake | `:1007` → `cc-sni-proxy.py:250-270` | `stop_prior` ≤3.0 s + `READY_TIMEOUT` **30.0 s** (was unbounded) |
| five `iptables -C` boundary assertions | `:1042-1055` | ≈81 ms real (3 nat @ 20.2 ms + 2 filter @ 10.1 ms) |
| four verification `curl`s at `--max-time 15` | `:1060`, `:1068`, `:1077`, `:1093` | ≤60.0 s |
| log `grep` | `:1103` | ≈1 ms over an `O_TRUNC`-fresh file |

**Bounded total: ≈264 s at N=25, ≈258 s at today's measured N=24**, against `FIREWALL_LOCK_WAIT` = 600 s. There is no longer an unbounded term.

**Cold path 2 — the launcher, host-side.** New in this range. `check_manifest` is called exactly once per launch (`cc-isolated.sh:405`, on the `up` and `--probe` paths; `--bless`/`--register`/`--list` exit before it), and `compute_manifest` is called once from it. `rg` over the repo confirms no other caller of any of the three functions. It now hashes **121 files** (6 fixed + 8 `egress/*.txt` + N `projects/*.profile` + 104 under `claude-home/`, 1.79 MB) where it hashed 17. The hypothesis this pass was asked to test — that the new `find claude-home -type f | sort` is a hidden per-check multiplication — is **refuted**: it runs once, costs 2 ms, and the accompanying switch from a fork-per-file to one batched `sha256sum` more than pays for it (see Endorsements).

**Concurrency sources**, unchanged: `node` has NOPASSWD sudo on the script and can invoke it at will; two `cc-isolated` launches against the *same project* share a container and can both reach the re-assert. Different projects get different containers and different `/run`, so they cannot contend. `devcontainer up`'s `postStartCommand` and the launcher's re-assert are ordered by `waitFor`, so those two cannot overlap.

---

### Findings

#### `FIREWALL_LOCK_WAIT` is a hardcoded constant against a hold that is N-linear again, and nothing defends the margin

**Severity:** Low
**Location:** `devcontainer-config/init-firewall.sh:347-359` (the sizing sentence and the `FIREWALL_LOCK_WAIT="${CC_FIREWALL_LOCK_WAIT:-600}"` it justifies, read as part of the complete `:339-370` block) against the N-linear term it must cover at `:427-465` (the `dig` loop) and the profile inputs at `devcontainer-config/egress/*.txt`
**Move:** #2 — what is the size of N (N is the composed allowlist, and it is the only variable term in the hold), #7 — contention, and #5 — a coupling with no cache and no assertion (two constants in two files that must stay in a ratio, with nothing checking it)
**Classification:** Macro (a waiter that outgrows the wait does not slow down, it exits 1) / **Cold** path (session start) → matrix Low, because today's margin is 3.4× and the consequence is a failed launch, not a bricked container
**Confidence:** High on the arithmetic and on the absence of any test pinning the relationship; Medium on the growth rate that would consume the margin
**Baseline:** measured and derived, this checkout. N at HEAD via `--print-entries`: **5** (`base`) / **24** (union of all seven profiles) — unchanged from r3, so the comment's "~25 today" is accurate. Code-sized hold at N=25: 15 + 6×25 + 39 + 60 = **264 s**; the pass-4 fact-check's *measured* worst case at the same N was **209 s** (real `dig`s mostly resolve well inside `+time=3`, and on a re-assert they are answered by the previous run's dnsmasq). Against 600 s that is a margin of **336 s code-sized / 391 s measured**, i.e. exhaustion at **N ≈ 81** (code-sized) or **N ≈ 90** (measured, at the fact-check's ~6 s marginal per name) — **3.4× today's allowlist**. Full stubbed run at HEAD: **239–270 ms** (bats `-T`, tests 7/8/9/61/64), against r3's 207/214/269 ms; uncontended `flock`: **1.0 ms** (20-call mean).
**Evidence:**
> ```
> # then does its own reads against the finished ruleset. The lock is held through
> # the verification probes too, so no rebuild can start under them. The wait is
> # sized to the longest legitimate hold — a 15 s meta fetch, up to 6 s per
> # allowlisted name (~25 today), up to 39 s of daemon starts (the proxy's readiness
> # bound is 30 s), and four 15 s probes: ~270 s at today's largest allowlist —
> # with headroom for growth; a hold longer than the wait is a stuck run, not a slow
> # one.
> ```
> (`init-firewall.sh:345-352`; the excerpt is seven lines of the twenty-line rationale at `:339-358`, all of which was read — the remainder covers the two-interleaved-runs failure, the 0700 lock directory, the post-trap ordering and the test-only env overrides.)
**Legibility-target:** for-author

This is the r2-1 shape returning in a much better-defended form, and it should be recorded as such rather than left to be rediscovered. r2-1 was "a fixed wait shorter than an N-linear hold". r3 closed it by removing the N-linear term from the hold; r4 has put the N-linear term back — deliberately, because `6 s × N` of `dig` is exactly the phase-A work the lock now has to cover — and compensated by multiplying the constant by five. The compensation is generous today (3.4×), and the sentence at `:345-352` is the first version of this comment whose arithmetic a reader can actually check. What is missing is any mechanism that keeps the two numbers in step. The bats suite pins where the lock is taken (`:944`), that it is never released early (`:963`), the directory mode (`:937`) and the non-numeric guard (`:957`) — four properties of the lock, and not the one that governs whether it works. Adding a profile is a routine, low-ceremony act (drop a `.txt` in `egress/`, `--register`, re-bless); nothing in that path recomputes the hold or compares it to 600.

Two calibrations keep this at Low rather than higher. First, the margin is genuinely large and growth is slow: eight profiles have produced 24 entries, so reaching 81 means roughly tripling the whole allowlist. Second, the consequence of exhausting the wait is milder than it looks. The waiter exits 1 into `fail_closed_on_abort`, which sets **policies** only (`:284-286`) — it does not flush. On a container the winner has just finished configuring, the winner's accept rules survive, and the winner's own terminal `REJECT` already made OUTPUT effectively closed; so the visible outcome is a failed launch with a clear message, not the terminal bricked-closed state `cc-isolated.sh:425-432` warns about. That state needs a *first* run to fail, which is a different scenario.

The one place the 600 s does cost something new: when a holder is genuinely wedged rather than slow, every subsequent run now blocks for **ten minutes** before saying so, where at 1434fc9 it blocked for two. That is the price of covering a legitimately longer hold, and it is unavoidable with a fixed wait — but it is the reason the number should be derived rather than chosen. Failure mode: **two constants in different files that must maintain a ratio, with the one that varies changed by a routine operation and the relationship asserted nowhere.**

**Recommendation:** Derive the wait instead of hardcoding it, in one line at `:359`. `ALLOWED_ENTRIES` is fully composed by `:337`, before the lock block, so the count is already in hand: `FIREWALL_LOCK_WAIT="${CC_FIREWALL_LOCK_WAIT:-$(( 120 + 6 * $(printf '%s' "$ALLOWED_ENTRIES" | grep -c . ) + 60 ))}"` — a fixed 120 s (meta + daemons + slack) plus the measured per-name term plus the probe budget — makes the wait track the allowlist by construction and turns the comment's arithmetic into the code's. Failing that, one bats case: compute the sized hold from `--print-entries | wc -l` and assert it is below the default wait with a stated margin. Either closes the finding; the derived form also removes the ten-minute wedged-holder wait at small N, since at `base` it would compute to ≈210 s rather than 600.

---

### Endorsements (evidence-gated)

- **The manifest widened 7× at zero measured cost, which is the rare version of this trade.** `compute_manifest` went from ~17 subshell-plus-`sha256sum` forks over 17 files to one `sha256sum` over 121 files (1.79 MB). Measured on a temp config dir mirroring the real layout: end-to-end `check_manifest` is **14/14/14/14/15 ms** at r4 against **13/17/15/15/15 ms** for the pre-range shape — statistically the same number for 7× the coverage. The two components: the `find claude-home -type f | LC_ALL=C sort` walk is **2 ms** (5 runs, no variance) and the `sha256sum` over the 104 claude-home files is **7–10 ms**. Had the walk been added without the batching, the same list would cost **86–92 ms** per launch, so the two halves of this change had to ship together and did. This is also the close of the architecture critic's A2. `[read: devcontainer-config/cc-isolated.sh:45-118, :397-410]`
- **The `select` bound is the right shape and the last unbounded term inside the lock.** `select.select([r], [], [], READY_TIMEOUT)` at `cc-sni-proxy.py:258` costs nothing on the success path (the child writes 5 bytes and the parent wakes immediately), and on expiry it SIGKILLs and reaps rather than leaving an orphan holding port 3443. I walked the rest of the section looking for a second one and there is none: `stop_prior` is a bounded 30×0.1 s poll with a SIGKILL fallback (`:230-238`), the child's failure path is `os.write(w, ...)` immediately followed by `os._exit(1)` (`:298-302`) so the `waitpid` at `:270` cannot park, and every network call in the script carries `--max-time 15`. The 30 s figure also lands correctly in the comment's 39 s daemon term. `[read: devcontainer-config/cc-sni-proxy.py:221-303]`
- **Holding the lock through the probes is worth the ≤60 s it costs a waiter.** r3 recommended releasing fd 9 before the verification block to cut the hold from ≈69 s to ≈9 s; the author declined and pinned the refusal with a test. That is the better call: the four probes assert that *this* boundary is installed and working, and a concurrent run that started its rebuild under them would invalidate the assertion between the check and its reporting — the probes would pass against a ruleset that no longer exists. The waiter's extra ≤60 s buys the probe result its meaning. `[read: devcontainer-config/init-firewall.sh:1056-1108; test/init-firewall-rules.bats:962-965]`
- **The five `-C` assertions are free at this scale, and the `NO_RULE` knob is free in production.** Measured on this sandbox (uid 1000, `iptables v1.8.9 (nf_tables)`, permission-denied fast path, so a floor): `iptables -t nat -C` **20.2 ms/call**, `iptables -C` **10.1 ms/call**, `iptables -S OUTPUT` **10.2 ms/call** (20-call means). Five new assertions minus the one pre-existing `-t nat -C` they absorbed is **net ≈ +71 ms** on a run whose own bound is 264 s — 0.03%. The loop adds no rules, so `ESTABLISHED,RELATED` depth (r2-6) is untouched. `NO_RULE`'s two `printf | grep` pipelines in the stub are guarded by `[ -n "${NO_RULE:-}" ] &&`, so they never execute in the 62 tests that do not set it. `[read: devcontainer-config/init-firewall.sh:1036-1055; test/init-firewall-rules.bats:52-54, :967-975]`
- **The suites are green at HEAD and the ownership-assertion re-gate did not make it more expensive.** 64 bats in `init-firewall-rules.bats`, 54 in `cc-isolated-functions.bats` (including two new cases pinning `PAYLOAD ⊆ enforcement_files` and the claude-home walk), 13 python — all pass. The `:302` gate changed from "skip when `CC_EGRESS_DIR` is set" to "run when the directory is the image's baked one, or `CC_EGRESS_OWNER_CHECK` is set", which keys on the invariant instead of on a test override; it still costs the same two `stat -c '%u'` (0.73 ms) and two `find -maxdepth 0 -perm /022` (2.95 ms) — **7.4 ms** — and still costs the suite nothing on the 63 tests that do not set the knob. `[unverified — submitted as claim]` (the 0.73/2.95 ms figures are carried forward from r3's measurement, not re-measured this pass)

---

### Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `FIREWALL_LOCK_WAIT` hardcoded at 600 s against a hold that is N-linear again (264 s code-sized / 209 s measured at N=25, exhausting at N≈81–90 vs. today's N=24); no test or derivation keeps the two in step | Low | `init-firewall.sh:347-359` vs `:427-465`, `egress/*.txt` | High (arithmetic, absence of assertion) / Medium (growth rate) |

Prior r3-1 and r3-2 are closed; prior r3-3 is unchanged in code, accepted, and narrowed in exposure. The four deferred proxy findings and r2-5/6/7 are tabled above without re-argument.

---

### Overall Assessment

**This is a clean pass.** Both r3 findings that named a defect are closed, and both were closed by the stronger option rather than the cheaper one. r3-1 offered a five-line guard (non-blocking lock probe, or one `dig` retry) as the cheap close and "move the lock" as the expensive one; the author moved the lock, which removes the failure rather than narrowing its window, and pinned it with a test that asserts no `curl`, `dig` or `iptables -F` executes while the lock is held elsewhere. r3-2 offered two one-liners; one was taken (`select` with a 30 s bound, which removes the section's only unbounded term — I re-walked the rest and found no second one) and the other, releasing fd 9 before the probes, was *declined with a test pinning the refusal*. Declining was right: probes that assert a boundary must own that boundary while they assert it, and the ≤60 s this costs a waiting run is the correct price. r3-3's `-w` gap is unchanged and accepted, and its concrete exposure shrank for free — the phase-A `ip6tables -w 5 -S` is now downstream of the `flock`, so the cross-run collision r3 described cannot occur at all; what remains is the pre-existing generic case.

The launcher change is the pass's quiet success. Widening `check_manifest` from 17 files to 121 (the whole `claude-home` payload — the executable skills and hooks that govern every session, and the architecture critic's longest-standing open item) is the kind of coverage increase that usually shows up on the cold path as a visible cost. Here it measures at **14 ms against a prior 14 ms**, because the walk shipped together with the switch from a fork-per-file to one batched `sha256sum`. Split across two commits it would have been an 86 ms regression on every launch; shipped together it is free. The `find` walk that this review was asked to suspect of being a hidden per-check multiplication runs exactly once per launch and costs 2 ms.

**What remains is one Low finding and it is a maintenance property, not a defect in the shipped state.** The wait is now correctly sized for today's allowlist — the comment's arithmetic is checkable and checks out, and the margin is 3.4× — but it is sized by a constant that a routine act (adding an egress profile) erodes silently, with the relationship asserted in no test. The consequence of eventually crossing it is milder than it first appears: the waiter's abort sets policies without flushing, so on an already-configured container it is a failed launch with a clear message rather than the terminal bricked state. The fix is one line that derives the wait from the entry count the script has already composed, which would also cut the ten-minute wedged-holder wait back to ~3.5 minutes at the base profile. That is worth doing, and it is not worth blocking a merge over.

Nothing in this range touches a hot path. The proxy's per-connection path is byte-identical; the four deferred proxy findings (single-address connect, no supervisor, per-connection `getaddrinfo`, no concurrency cap) remain deferred by decision and were not re-argued.

### Goal-Alignment Note
- Answered: yes — fourth-pass performance review of `devcontainer-config/` over `1434fc9..f313de7`, with r3 findings 1 and 2 verified closed against the code at HEAD (lock relocated to `:339-370` ahead of `# PHASE A` at `:373`, with `test/init-firewall-rules.bats:944` guarding it; the sizing comment rewritten with checkable arithmetic and the wait raised to 600 s; `READY_TIMEOUT`/`select` bounding the last unbounded term, with the rest of the section re-walked for a second one), r3-3 statused as unchanged-and-accepted with its exposure correctly narrowed, the deferred proxy findings tabled without re-argument, the launcher's new manifest work measured on a temp fixture (121 files, 14 ms end-to-end, 2 ms walk, versus 86–92 ms had the batching not shipped with it), and one new Low finding filed. Report at `docs/reviews/performance-review-2026-09-03-egress-hardening-r4.md`.
- Out of scope: `test/*.bats` and `test/test_cc_sni_proxy.py` (committed context — executed for baselines and to confirm what is pinned); the `Dockerfile` sudoers hardening and the `egress/base.txt` grammar comment (security and fact-check respectively — build-time and documentation, no runtime cost); the absence of any test covering `READY_TIMEOUT` expiry (test-strategy's call, noted only because it bears on whether the new bound is defended); `find -type f` skipping symlinks in the claude-home walk (a coverage question for security, not a cost).
- Escalate: (1) Finding 1 is the only open item and I would ship with it — but the derived-wait one-liner is cheap enough that deferring it means accepting that the next profile addition erodes an undefended margin. (2) r3-3's `-w` convention question (4 of 61 netfilter calls carry `-w`) is now in its third pass unanswered; its risk is lower than r3 assessed, but it still wants an explicit accept-or-fix from the author so it stops being re-derived each round. (3) No new escalation from this range: the two r3 items that were escalated as "would not ship without" are both closed.
