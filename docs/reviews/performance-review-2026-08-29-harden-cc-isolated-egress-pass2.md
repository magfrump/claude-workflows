# Performance Review — cc-isolated egress hardening, round 3

**Commit:** 6edaa21 + working-tree pass-2 fixes
**Scope:** `devcontainer-config/init-firewall.sh` (round-3 delta only: EXIT trap, DNS fail-open branch removal, two `|| true` guards)
**Date:** 2026-08-29
**Based on:** no code fact-check report provided (see warning below)

> ⚠️ **No code fact-check report provided.** Performance claims in comments and documentation
> have not been independently verified. For full verification, run the `code-fact-check` skill
> first or use the code-review orchestrator.

---

## Data Flow and Hot Paths

`init-firewall.sh` runs **once per container start**, via `postStartCommand` in
`devcontainer-config/devcontainer.json:93`, and a second time on the recovery path in
`devcontainer-config/cc-isolated.sh:412` when the post-start boundary probe fails. It is a
**cold path** by the skill's hot-path gate — no request handler, no per-item loop at scale, no
recurring callback. It does, however, sit on the critical path of a latency-sensitive operation
the user personally waits on: `cc-isolated.sh:405-416` blocks on `devcontainer up` → probe →
optional re-assert → `exec … claude`. Every second here is a second before the agent session
starts.

Work performed per run, in order:

| Step | Cost driver | Count |
|---|---|---|
| `compose_domains` | file reads + `sort -u` | 1–8 small files |
| `iptables-save`, flush, ipset destroy/create | local netlink | ~10 syscall-ish calls |
| DNS resolver rules | `iptables -A` | 2 × resolvers (typically 1 resolver → 2 calls) |
| `curl -s https://api.github.com/meta` | **network round trip, no timeout set** | 1 |
| GitHub CIDR ingest | `ipset add` per CIDR | ~30–40 CIDRs after `aggregate -q` |
| `dig` per allowlisted domain | **network round trip, serial** | 6–25 (measured below) |
| Final rules + 2 verification `curl`s | network, `--connect-timeout 5` each | 2 |

Data sizes are small and bounded by files checked into the repo — there is no N that grows with
users, requests, or time. The only unbounded quantity in the script is **wall-clock wait on
network calls that have no timeout ceiling**, which is where the one finding lands.

### Round-3 delta, assessed

1. **`fail_closed_on_abort` EXIT trap (`init-firewall.sh:89-99`).** Zero steady-state cost. On
   the success path the trap body runs once, evaluates `[ "$rc" -ne 0 ]` false, and returns —
   one comparison. On the failure path it issues three `iptables -P` calls, which are local
   netlink operations in the low-milliseconds range. No latency concern.
2. **DNS fail-open `else` branch now installs no rules (`:174-199`).** Strictly *less* work than
   before (two `iptables -A` calls removed). Not a regression; see the finding for the one
   second-order latency consequence, which is small and mostly pre-existing.
3. **Two `|| true` guards (`:228`, `:258`).** `|| true` is a shell builtin on the failure branch
   only. Immeasurable. Their effect is to make previously-dead error-handling code reachable —
   a correctness improvement with no cost.

### Re-entrancy and subshell interaction of the EXIT trap — checked, clean

The brief asks specifically whether the trap fires per-subshell or interacts with the
`while read … done < <(…)` process substitutions at `:173`, `:250`, and `:281`. It does not.
Verified empirically on `GNU bash 5.2.15`:

```
$ bash -c 'f(){ echo "TRAP rc=$?"; }; trap f EXIT
  while read -r x; do echo "read $x"; done < <(echo a; echo b)
  ( exit 3 ) || echo "subshell returned 3"
  v=$( exit 4 ) || echo "cmdsub returned 4"'
read a
read b
subshell returned 3
cmdsub returned 4
TRAP rc=0        ← exactly once, main shell only
```

Bash resets trapped signals to their default in subshell environments, so neither the process
substitutions, the `$(…)` command substitutions, nor the `xargs`/`jq`/`aggregate` pipeline
children can trigger the trap. There is **no re-entrancy, no repeated `iptables -P` storm, and
no per-iteration cost**. A confirming case: a failing command *inside* a process substitution
does not fire the trap or abort the parent, since the parent sees `read`'s status, not the
producer's — that is a pre-existing correctness nuance of `:250`, not a performance one.

Also worth noting for completeness: the trap is installed at `:99`, *after* the
`--print-domains` early exit at `:56-59`, so the unit-test path (`test/cc-isolated-functions.bats`)
never installs it and pays nothing.

---

## Findings

#### Bootstrap network calls have no timeout ceiling, and the new trap routes the recovery path through them while egress is denied

**Severity:** Low
**Location:** `devcontainer-config/init-firewall.sh:228` (`curl`), `:258` (`dig`), interacting with `:89-99` (trap) and `devcontainer-config/cc-isolated.sh:410-413` (re-run)
**Move:** #3 — work that moved to the wrong place (the *abort* path moved from fail-fast to fail-slow)
**Classification:** Macro (unbounded wait, cost independent of invocation frequency) / **Cold path** (once per container start) — matrix default Medium, adjusted **down to Low** because it manifests only on the abort-then-retry path, not on any successful start
**Confidence:** High on the mechanism, Medium on the magnitude
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** a reviewer with a container and a stopwatch. The claim is falsifiable in one command: force an abort (e.g. point `PROFILE_FILE` at a bad profile after the flush, or block api.github.com), then time the `cc-isolated.sh:412` re-assert.

The trap correctly leaves `OUTPUT` policy `DROP` after any abort. `iptables -F` does not reset
policies, so the **next** run of the script starts inside a default-deny netns with empty chains.
It then reaches `curl -s https://api.github.com/meta` at `:228` before any rule that could permit
it: the `allowed-domains` ipset was destroyed and recreated empty at `:108`/`:219`, and the
`HOST_NETWORK` accept is not added until `:296`. The SYN is silently dropped (policy `DROP`, not
the `REJECT` rule, which was flushed), and `curl -s` carries **no `--connect-timeout`** — unlike
the two verification probes at `:315` and `:323`, which correctly pass `--connect-timeout 5`. The
wait is therefore the kernel SYN-retry ceiling; at the observed `net.ipv4.tcp_syn_retries = 6`
that is roughly 127 s before `curl` returns empty, `|| true` swallows the status, and the `-z`
check at `:229` exits 1. `cc-isolated.sh:410-413` runs exactly this re-assert whenever the
post-start probe fails, so the user-visible symptom is a ~2-minute stall at
"Re-asserting firewall via baked init-firewall.sh" before a failure they could have been shown
immediately.

This is **mostly pre-existing** — a re-run after a *successful* run already hit it, since the
prior run's DROP policies survive the flush. What round 3 changes is that the *first-run abort*
case now also lands here: previously a fresh container aborted with policy still at `ACCEPT`, so
the retry had working egress and completed or failed fast. That is the correct security tradeoff
and should not be reverted; the cost is simply that the retry is now slow, and the fix is to bound
the waits rather than to weaken the trap. The same missing ceiling applies to `dig` at `:258`:
defaults are `+timeout=5 +tries=3`, i.e. up to ~15 s per unresolvable-and-unreachable domain, and
the loop is serial, so a denied-DNS re-run compounds to `domains × 15 s` on top of the `curl` stall.

**Recommendation:** Add `--connect-timeout 5 --max-time 15` to the meta fetch at `:228` (matching
the ceilings already used at `:315`/`:323`) and `+time=2 +tries=1` to the `dig` at `:258`. Both are
one-token changes that convert a multi-minute silent stall into a prompt, correctly-failing-closed
error, with no effect on the success path. Capture one timing of the `cc-isolated.sh:412` re-assert
before and after, so the change has a number attached.

---

### Considered and explicitly dismissed

**The serial `dig` loop (`:253-282`) is not worth parallelizing.** The brief invites a finding
here if one is real; it is not, and the arithmetic says so. Counting non-comment lines in
`devcontainer-config/egress/`:

| Profile | Domains | Composed with `base` |
|---|---|---|
| `base` | 6 | 6 |
| `dotnet` | 1 | 7 |
| `lean`, `llm`, `python` | 2 each | 8 |
| `rust`, `vscode` | 3 each | 9 |
| `android` | 6 | 12 |
| *union of every profile* (not a real configuration) | — | **25** |

So a realistic run resolves **6–12 domains**, and even the pathological "every profile at once"
case is 25 — not the ~20-per-run figure the brief hypothesised as typical. Against a responsive
resolver (Docker's embedded 127.0.0.11, forwarding to a warm host resolver) each `dig` is on the
order of 5–30 ms, putting the whole loop at roughly **0.1–0.4 s** — one to two orders of magnitude
below the single `curl` to api.github.com it follows, and negligible against `devcontainer up`
itself. Parallelising it would mean backgrounding jobs, collecting per-domain output safely, and
preserving the `api.anthropic.com`-is-critical semantics at `:264-267` — real complexity, in a
security-critical script, for a saving the user cannot perceive. Do not do it. The loop's only
genuine latency exposure is the missing `dig` timeout on the *degraded* path, which the finding
above covers as a bounding change rather than a restructuring.

**`ipset add` per CIDR/IP (`:249`, `:280`).** ~30–40 GitHub CIDRs after `aggregate -q`, plus a
handful of A records per domain. Each is a fork+netlink call in the single-digit milliseconds.
`ipset restore` batching would shave perhaps 100–200 ms once per container start, at the cost of
losing the per-entry validation and `|| `-guard structure that the security review deliberately
built. Micro × Cold → Informational, and not worth raising as a finding.

**`compose_domains` (`:30-51`).** Reads at most 8 small files and one `sort -u`. Immeasurable.

---

## What Looks Good

- **The trap is the cheapest possible implementation of its guarantee.** One `$?` capture, one
  integer comparison on the success path, three local netlink calls on the failure path. It adds
  no work to any loop, no per-iteration cost, and no subshell fan-out. Installing it *after* the
  `--print-domains` early exit keeps the test path free of it.
- **Removing the two `iptables -A` calls from the DNS `else` branch is a strict reduction in work**
  as well as an attack-surface reduction — the rare case where the secure choice is also the
  cheaper one.
- **The `|| true` guards make previously-unreachable error paths reachable.** From a latency
  standpoint this is an improvement: the script now reaches its own explicit error messages
  instead of dying two lines earlier with a bare `set -e` abort, which means failure diagnosis
  costs the operator less time.
- **The verification probes at `:315` and `:323` already carry `--connect-timeout 5`.** That is the
  right pattern; the finding above is only that the two bootstrap calls did not adopt it.
- **All data volumes are bounded by files in the repo.** There is no N that grows with users,
  sessions, or elapsed time anywhere in this script.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Bootstrap `curl`/`dig` lack timeout ceilings; new trap routes the retry path through denied egress → ~2 min silent stall on the recovery path | Low | `init-firewall.sh:228,258` | High (mechanism) / Medium (magnitude) |

Round-3 items with **no** finding: the EXIT trap itself, the DNS `else`-branch rule removal, and
both `|| true` guards.

---

## Overall Assessment

**Round 3 introduces no material performance concern, and that is the honest result — not a pass
manufactured to justify the review.** All three changes are either zero-cost on the success path
(the trap, the `|| true` guards) or a strict reduction in work (the `else` branch). The specific
worries the brief raised are cleanly disposed of: the EXIT trap fires exactly once in the main
shell, is not inherited by any of the script's process substitutions or command substitutions
(verified on bash 5.2.15), and cannot interact with the `while read` loops; and the serial `dig`
loop resolves 6–12 domains in a realistic configuration for an estimated 0.1–0.4 s, which does not
justify parallelisation in a security-critical script.

The one finding is Low and is best understood as *pre-existing tech debt that round 3 newly
exposes*: the bootstrap `curl` and `dig` have no timeout ceiling, and the trap's (correct)
decision to leave `DROP` policies after an abort now routes `cc-isolated.sh`'s automatic re-assert
through a denied-egress path where that missing ceiling costs roughly two minutes of silent stall.
The fix is additive and one-line-per-call — bound the waits, keep the trap. No profiling is needed
to act on it; a single stopwatch reading of the re-assert path before and after would attach the
number this review could not.

Out of lane but cheap to mention, since it bears on whether the trap achieves its stated goal
rather than on its cost: bash does not run an `EXIT` trap when the shell is killed by an untrapped
`SIGTERM` or `SIGHUP`. If `postStartCommand` or `devcontainer exec` can be torn down that way
mid-run, the fail-closed guarantee has a hole. That belongs to `security-reviewer`, not here.

---

## Goal-Alignment Note

The goal of this review was to assess the round-3 delta for performance impact, calibrated to a
script that runs once per container start, without restating the prior round's "no material
findings" verdict and without manufacturing findings to justify the pass.

The review is aligned with that goal, with these qualifications the caller should weigh:

- **The pass is genuine.** Two of the brief's three round-3 items produced no finding at all, and
  the third (the trap) produced none on its own — the single Low finding is about a *pre-existing*
  missing timeout that the trap newly routes traffic through. I have said so explicitly rather
  than attributing the whole cost to round 3.
- **The one finding is speculative on magnitude.** The ~127 s figure is derived from
  `net.ipv4.tcp_syn_retries = 6` read on this machine, not measured inside a cc-isolated container,
  and the container's netns may differ. The mechanism (SYN dropped by policy, `curl -s` with no
  `--connect-timeout`) is High confidence and readable directly from the code; the number is not.
  No baseline exists for this repo, so the finding carries the speculative disclaimer.
- **The dismissal of the `dig` loop rests on a counted N and an estimated per-call latency.** The
  domain counts (6–25) are measured from the repo. The 5–30 ms per `dig` is an estimate, not a
  measurement. Even at 10× that estimate the loop stays under 4 s and the conclusion holds, so the
  dismissal is robust to the estimate being wrong.
- **Scope was respected but narrow.** I read the whole file for context as instructed, and I did
  not re-litigate the earlier rounds' DNS-scoping or SSH decisions. The `SIGTERM`-vs-`EXIT`-trap
  observation is flagged as out-of-lane rather than smuggled in as a performance finding.
