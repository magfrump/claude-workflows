# Performance Review — egress hardening fix wave d53bf6a..2839e59

Commit: 2839e59

**Scope:** `git diff d53bf6a..2839e59 -- devcontainer-config/` — `init-firewall.sh` (the only file with executable changes of any size; read whole around every hunk, and the flock, IPv6, dnsmasq-start, proxy-start and probe blocks read end to end at HEAD), `cc-sni-proxy.py` (shebang + docstring only), `cc-isolated.sh`, `install.sh`, `Dockerfile`, `devcontainer.json`, `egress/base.txt`. `test/init-firewall-rules.bats` and the docs in the range are committed context, not under review; `docs/reviews/code-fact-check-report.md` (b708266) was read in full for the escalation rows.
**Date:** 2026-09-03
**Based on:** `docs/reviews/performance-review-2026-09-03-egress-hardening.md` (pass 1, on abbd42d) and `docs/reviews/code-fact-check-report.md` (loop-pass, k=1, at b708266)

---

## Prior findings status

The pass-1 findings 1–4 were deliberately deferred by the author and logged in `docs/working/questions.md`; they are recorded here, not re-filed.

| Prior # | Finding | Status | Note |
|---|---|---|---|
| 1 | Proxy connects to `infos[0]` only; no fallback, no reconciliation with the phase-A ipset snapshot | Deferred (not fixed, as expected) | `cc-sni-proxy.py`'s only changes in this range are the shebang (`/usr/bin/env python3` → `/usr/bin/python3`) and the module docstring. `handle()` is byte-identical. |
| 2 | No supervisor: a proxy death after startup is a silent, session-long HTTPS outage | Deferred (not fixed, as expected) | Unchanged. One adjacent improvement: the negative probe now requires a `REJECT` line in the proxy log (`init-firewall.sh:1017-1021`), so a proxy that is dead **at the end of the run** is now caught. Nothing still watches it after that. |
| 3 | `getaddrinfo` per connection, no in-process cache | Deferred (not fixed, as expected) | Unchanged. |
| 4 | No concurrency cap and no idle timeout after the ClientHello | Deferred (not fixed, as expected) | Unchanged. |
| 5 | Proxy log grows for the whole session, one line per connection, no rotation | Open, unchanged in kind; slightly more load-bearing | The log is now *read* by the run itself (`grep -q "REJECT sni=…" "$SNI_LOG"`, `:1018`). At that point the file is a handful of lines old (`O_TRUNC` at daemon start), so the grep is free — but the log has moved from "diagnostic output" to "an input the verification depends on", which is an argument against ever truncating or rotating it naively. |
| 6 | `ESTABLISHED,RELATED` accept sits behind ~10 rules in filter OUTPUT | Open, unchanged | The IPv6 block adds no IPv4 OUTPUT rules; per-packet IPv4 traversal cost is identical. Pass 1 recommended no change; still no change. |
| 7 | ~90–140 `ipset add` forks per rebuild | Open, marginally smaller | `base.txt` lost entries this range: measured at HEAD via `--print-entries`, N is now **5** (base) and **21** (union of every profile), down from 5 and 24. The loop structure is untouched. Still no change recommended. |

---

## Data Flow and Hot Paths

Nothing in this range touches a hot path. The proxy's per-connection path (`handle()`, `pump()`) and dnsmasq's per-query path are unchanged; the only executable proxy change is a shebang, which is paid once per daemon start. The two effects on the hot path are both negative-cost: the SNI zone list shrank from three entries to two (`.githubassets.com` dropped, since it was never resolvable — the zones are now derived from `GITHUB_DNS_ZONES` at `:940-942`), so `Allowlist.allows` scans one fewer zone per connection; and `/usr/bin/python3` saves one `env` exec at start.

All of the range's cost lands on the **cold** path — `init-firewall.sh`, once per container start via `devcontainer.json:121` `postStartCommand` with `"waitFor": "postStartCommand"`, plus once more on the launcher's re-assert (`cc-isolated.sh:415-433`) when the boundary probe fails. Both block session start, so added seconds are user-visible.

What the range adds to that path, in execution order:

| Step | Line | Added cost |
|---|---|---|
| `export PATH=` pin | `:37` | none (a shorter PATH, if anything) |
| `exec 9>` + `flock -w 120` | `:304-308` | **0 ms uncontended** (measured, below); up to 120 s then `exit 1` when contended |
| `parse_entry` port canonicalisation | `:135-142` | none — the same single loop, now also concatenating a string; N ports per entry is 1–2 |
| `compose_dnsmasq_conf` regex `+` → `*` | `:214` | none |
| IPv6 default-deny: 1 probe + 9 `ip6tables` calls | `:537-546` | ~10 execs ≈ 100 ms, **inside the flush→rebuild window**; the probe can wait up to 5 s on the xtables lock |
| trap: 3 guarded `ip6tables -P` | `:269-273` | abort path only |
| `9>&-` on dnsmasq and the proxy | `:740`, `:949` | none; removes a 120 s wait from every *subsequent* run |
| SNI zone loop over `GITHUB_DNS_ZONES` | `:940-942` | one `echo | tr` for a two-word string |
| negative-probe `grep` on `$SNI_LOG` | `:1018` | one grep over a file a few lines long |

**Measured local floor.** A complete stubbed run (`bats -f "IPv6 is default-denied" test/init-firewall-rules.bats`, which executes the script end to end against the suite's stubs) takes **0.38 s wall including bats startup**. Every real second of a real run is therefore network: one `curl` to `api.github.com/meta`, N serial `dig`s, and four verification `curl`s. That single fact drives both findings below.

**Concurrency sources.** Two runs can overlap: `node` has NOPASSWD sudo on this script and can invoke it at will, and two `cc-isolated` launches against the same project would each reach the re-assert path. `devcontainer up` + `postStartCommand` cannot overlap the launcher's own re-assert (they are sequential within `main`, `cc-isolated.sh:410-433`), so the launcher does not race itself.

**fd-9 inheritance audit (fact-check escalation E1).** I grepped `init-firewall.sh` for every backgrounding construct — `&` at end of line, `nohup`, `setsid`, `disown` — and found none. The only children that outlive the script are `dnsmasq` (`:740`) and `cc-sni-proxy.py --daemon` (`:948-949`), and both invocations now carry `9>&-`. Every other child (`iptables`, `ipset`, `dig`, `curl`, `jq`, `aggregate`, `runuser -u node -- curl`, `pkill`) inherits fd 9 but is short-lived and bounded (the longest, the probe curls, by `--max-time 15`), and the parent holds the lock for their whole lifetime anyway, so their inheritance is inert. **E1 is closed for both daemons.**

---

## Findings

#### The firewall lock's 120 s wait is shorter than the run's own worst-case hold time, and the whole hold sits on the session-start critical path

**Severity:** Medium
**Location:** `devcontainer-config/init-firewall.sh:295-308` (the complete ONE-RUN-AT-A-TIME block, read whole), against the work it now encloses at `:310-464` (phase A) and the probes at `:985-1021`; consumers `devcontainer.json:121-122`, `cc-isolated.sh:415-433`
**Move:** #3 — work in the wrong place (the critical section spans network I/O that never touches the ruleset), and #2 — what is the size of N (the wait is a constant; the hold time scales with N)
**Classification:** Macro (the whole run fails, and session start fails with it — not a slowdown that tuning shrinks) / **Cold** path (evidence: `postStartCommand` at `devcontainer.json:121` with `"waitFor": "postStartCommand"`, plus the launcher's re-assert at `cc-isolated.sh:425`) → matrix Medium
**Confidence:** High on the arithmetic and on the failure shape; Medium on how often the worst case is reached, since the per-`dig` and per-`curl` ceilings are worst cases, not typical values
**Baseline:** measured, this checkout: a complete stubbed run is **0.38 s** wall, so essentially none of the hold time is local work; N measured via `--print-entries` at HEAD = **5** (base) / **21** (union of every profile). Bounded from the code, the lock is held for at most `15 s` (`curl --max-time 15`, `:356`) `+ 6 s × N` (`dig +time=3 +tries=2`, `:394`) `+ 3 s` (`stop_dnsmasq`'s kill wait, `:455-459`) `+ 3 s` (the dnsmasq pidfile poll, `:741-744`) `+ 60 s` (four probes at `--max-time 15`, `:985`, `:993`, `:1002`, `:1011`) `+` the proxy's readiness wait — i.e. **≈111 s at N=5 and ≈207 s at N=21**, against a `CC_FIREWALL_LOCK_WAIT` default of **120 s**. Separately measured in this sandbox: uncontended `flock -w 120` on fd 9 costs **0.96 ms** per run including the `bash` fork.
**Evidence:**
> ```
> FIREWALL_LOCK="${CC_FIREWALL_LOCK:-/run/cc-firewall.lock}"
> exec 9>"$FIREWALL_LOCK"
> if ! flock -w "${CC_FIREWALL_LOCK_WAIT:-120}" 9; then
>     echo "ERROR: another init-firewall.sh run is still holding $FIREWALL_LOCK" >&2
>     exit 1
> fi
> ```
> (`init-firewall.sh:303-308`; the excerpt omits the eleven-line rationale comment immediately above at `:295-302`, which was read — it explains the interleaving race the lock closes and notes that the lock is taken after the trap so a lock failure also ends at DROP.)
**Legibility-target:** for-author

The lock is acquired at `:305`, *before* `compose_domains`, so the critical section covers all of phase A — a `curl` to GitHub and N serial `dig`s — even though phase A reads only the network and touches no rule, no chain and no ipset until `:510`. The result is a hold time that is 100% network-bound and grows linearly with the allowlist, while the wait that guards it is a fixed 120 s: for any profile beyond bare `base` the worst-case hold exceeds the wait, and `base` itself clears it by nine seconds. When the wait is exhausted the second run does not degrade, it fails — `exit 1` into the EXIT trap, which is harmless in itself (the final ruleset is DROP-policy anyway, `:869-871`, so the trap's forced DROP does not damage the run still in progress) but is fatal upstream: on `postStartCommand` it fails container start, and on the launcher path it prints the "this container may now have DROP policies with no accept rules and be unable to rebuild them" message (`cc-isolated.sh:426-430`) — a bricked-container diagnosis for what is actually a healthy container with a busy neighbour. So the user-visible worst case is two minutes of blocked session start followed by a misleading error. Failure mode: **a fixed lock timeout guarding a variable, network-bound critical section that can outlast it, on a path where the failure is reported as corruption.**

**Recommendation:** Two independent levers; either alone closes it, and they compose. (a) Narrow the critical section: take the lock after phase A, immediately before the flush at `:510`, so the hold drops from up to ~207 s to the sub-second local work plus the daemon starts and probes. The caveat to weigh is that a second run's phase A would then execute against a first run's half-built ruleset and could fail its `dig`s — which is a warn-and-skip for every domain except `api.anthropic.com`, so it trades a hard 120 s failure for a possible silent narrowing; if that trade is unacceptable, prefer (b). (b) Set the wait from the same arithmetic that bounds the run rather than a round number — `15 + 6N + 66` plus margin — or make it `flock` without `-w` (wait indefinitely) and rely on the existing `INT TERM` trap for the operator's escape, since "another run is finishing" is exactly the case where waiting is correct. Whichever is chosen, distinguish the lock-timeout exit from a real failure in the launcher's message at `cc-isolated.sh:426-430`, which today reports it as a bricked container.

---

#### The IPv6 default-deny block puts a lock-taking probe and nine unguarded netfilter calls inside the flush→rebuild window that phase A exists to keep empty

**Severity:** Informational
**Location:** `devcontainer-config/init-firewall.sh:524-551` (the complete IPv6 block including its rationale comment, read whole), in the context of the phase-A contract stated at `:330-347` and the precondition blocks it should have joined at `:425-464`
**Move:** #3 — work in the wrong place, and #7 — contention (the xtables lock)
**Classification:** Micro (tens of milliseconds, or a bounded 5 s in the contended case) / **Cold** path (evidence: `devcontainer.json:121`) → matrix Informational
**Confidence:** High on the placement and the missing `-w`; Medium on the contention ever being observed, since the flock now removes the most likely second `iptables` writer in this container
**Baseline:** measured in this sandbox: `ip6tables -w 5 -S OUTPUT` = **10.7 ms/call**, `iptables -S OUTPUT` = **9.3 ms/call**, `command -v ip6tables` = **0.8 ms** (these are the permission-denied fast path — `id -u` is 1000 here — so they are a *floor* on the real cost, which adds netlink work). Ten added execs ≈ **100 ms** against a stubbed whole-run local floor of **0.38 s**. Counted at HEAD: 51 IPv4 `iptables` invocations in the script, of which only the trap's 4 carry `-w`.
**Evidence:**
> ```
> if command -v ip6tables >/dev/null 2>&1 && ip6tables -w 5 -S OUTPUT >/dev/null 2>&1; then
>     ip6tables -P INPUT DROP
>     ip6tables -P FORWARD DROP
>     ip6tables -P OUTPUT DROP
>     ip6tables -F
>     ip6tables -X
> ```
> (`init-firewall.sh:537-542`; the excerpt ends mid-block — the remainder is the four `-A` accepts for loopback and `ESTABLISHED,RELATED`, the success `echo`, and the `else` branch's warning, `:543-551` — read.)
**Legibility-target:** for-author

Two small things, one placement. The block sits at `:537`, after the flush and the DROP policies at `:510-520`, which puts a probe that may wait up to five seconds on the xtables lock plus nine more netfilter execs inside the window the script's own phase-A design comment (`:341-347`) advertises as shrinking "to microseconds"; the widening is an outage, not an exposure — egress is DROPped throughout — but the *usability* half of this check is a precondition exactly like `command -v dnsmasq` and the `DNSMASQ_UID` test, both of which the author deliberately put in phase A at `:425-443` so a broken image aborts with the live ruleset intact. Second, the guard uses `-w 5` while the nine calls it guards use no `-w` at all, so a run that wins the probe can still lose the lock one line later and abort into the fail-closed trap; that is the shape fact-check escalation E2 named, and the probe closes E2's stated cause (no IPv6 filter table) but not this one. In fairness this matches the file's existing convention — 47 of the 51 IPv4 `iptables` calls are equally bare — so it is consistency, not a regression, and the flock added in this same wave removes the most plausible competing writer inside the container. Failure mode: **a precondition check performed inside the window that the precondition convention exists to protect, on an unwaited lock.**

**Recommendation:** Move the `command -v ip6tables && ip6tables -w 5 -S OUTPUT` probe up into the phase-A precondition block at `:425-464`, store the answer in a variable, and have `:537` branch on that variable — the window then contains only the nine enforcement calls, and an unusable table is reported before anything is flushed. If the `-w` inconsistency is worth closing, close it file-wide rather than in this block alone; a one-block fix would read as a distinction that is not there.

---

## Endorsements (evidence-gated)

- The fd-9 escalation is genuinely closed and the mechanism is the right one: `9>&-` closes the child's copy of the lock's open file description before `exec`, so the daemon holds no reference and the lock releases when the script exits. I reproduced both shapes in this sandbox with a detached child: without `9>&-` a second run reported `TIMEOUT` after the full wait; with `9>&-` it reported `ACQUIRED` after **0.00 s**. `[read: devcontainer-config/init-firewall.sh:737-740, :948-949]`
- The `9>&-` coverage is complete for long-lived children: no `&`, `nohup`, `setsid` or `disown` appears anywhere in the script, so `dnsmasq` and the SNI proxy are the only two processes that outlive the run, and both invocations carry it. `[read: devcontainer-config/init-firewall.sh:1-1030]`
- The uncontended lock costs nothing measurable — **0.96 ms** per run including the `bash` fork, against a run whose local work alone is 0.38 s and whose real duration is tens of seconds of network. The normal case is genuinely zero-wait. `[unverified — submitted as claim]`
- The negative-probe `grep` is free and correctly placed: `daemonize` opens `$SNI_LOG` `O_TRUNC` once per daemon start, so at `:1018` the file holds only this run's own probe lines — the grep is over a handful of lines, not a session's worth. `[read: devcontainer-config/cc-sni-proxy.py:243, devcontainer-config/init-firewall.sh:1017-1021]`
- `parse_entry`'s port canonicalisation adds no work: the `10#$port` arithmetic already ran in the same loop for the range check, and the change only concatenates the result into `canon` instead of discarding it. N ports per entry is 1–2 in every shipped profile. `[read: devcontainer-config/init-firewall.sh:130-146]`

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Lock wait (120 s) is shorter than the run's own worst-case hold (~111 s at N=5, ~207 s at N=21), and the hold spans phase A's network reads | Medium | `init-firewall.sh:295-308` | High (arithmetic) / Medium (frequency) |
| 2 | IPv6 block's probe + nine unwaited `ip6tables` calls sit inside the flush→rebuild window instead of phase A | Informational | `init-firewall.sh:524-551` | High (placement) / Medium (contention) |

---

## Overall Assessment

This wave is almost entirely comment, doc and manifest work; the executable surface is small and the hot path is untouched, so the pass-1 picture stands unchanged — the interesting risk still lives in the unsupervised SNI proxy, and the four deferred findings are all still open exactly as filed. Of what is new, the `9>&-` fix is correct and complete: I verified both the mechanism and the coverage, and the normal case is now a sub-millisecond lock acquisition rather than a 120 s wait ending in a fail-closed container. The one thing I would change before blessing is the lock's *scope and timeout*, not its existence: holding it across phase A makes the hold time network-bound and N-linear, which pushes the worst case past the fixed 120 s wait for every profile beyond `base`, and the resulting failure is reported to the user as a bricked container rather than as contention. That is a five-line fix in either of two directions and worth taking now, because the symptom it produces — a two-minute stall followed by a scary and wrong error message — is precisely the kind that gets diagnosed as something else. The IPv6 block's placement is a smaller version of the same "work in the wrong place" instinct and can ride along with it. Everything else measured out as free: ten added netfilter execs against a 0.38 s local floor, a grep over a four-line file, and a hot path that got marginally cheaper by losing a dead zone from the SNI allowlist.

## Goal-Alignment Note
- Answered: yes — performance re-review of `devcontainer-config/` over `d53bf6a..2839e59`, with the seven pass-1 findings carried in a status table rather than re-filed, the E1 fd-9 fix verified for coverage on both daemons and reproduced empirically, and the flock's critical-path behaviour quantified. Report at `docs/reviews/performance-review-2026-09-03-egress-hardening-r2.md`.
- Out of scope: `test/init-firewall-rules.bats` and the docs in the range (committed context only); the security and correctness questions raised by the wave (IPv6 default-deny's completeness, the `.githubassets.com` removal, the bless-manifest additions in `cc-isolated.sh`/`install.sh`) belong to the security and API-consistency critics; the four deferred proxy findings were not re-argued.
- Escalate: (1) Finding 1's lock-timeout exit is indistinguishable from a real failure at `cc-isolated.sh:426-430`, which tells the user their container may be bricked — that message is a diagnosability bug for the orchestrator to route, independent of which perf lever is chosen. (2) Fact-check escalation E2 is only half-closed: the new probe covers "no IPv6 filter table", but the nine `ip6tables` calls remain bare of both `-w` and `|| true`, so xtables-lock contention still aborts the run — the author should decide explicitly whether that abort is intended. (3) Prior findings 1–4 remain open by decision; if `docs/working/questions.md` is the record, the two cheap measurements pass 1 named (container-side `getaddrinfo` timing, and a `FAIL`-line count over a real session log) are still the fastest way to retire 1 and 3.
