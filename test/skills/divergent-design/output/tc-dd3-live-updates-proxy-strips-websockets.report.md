I read `workflows/divergent-design.md` from this repo, lines 1–471, which cover the main process. The installed copy at `~/.claude/workflows/` is outside the directory I'm allowed to read. This repo contains only that one file, so I'm treating it as the right workflow; the variant sections I didn't read weren't needed. There is no `docs/decisions/` or `docs/constraints.md` here, so the check for past decisions found nothing. I can't write files, so everything the workflow would save is printed below.

## Bottom line

**Build Server-Sent Events (SSE), with automatic fallback to polling every 4 seconds. Build the polling part first.**

- **WebSockets are out.** You already know they fail silently for about 30% of your customers.
- **Polling every 15 seconds is out.** It can't meet a 5-second freshness target, since a change could wait up to 15 seconds before the next poll.
- **SSE alone is risky.** It needs no `Upgrade` header, but the proxies that strip it often also hold back streamed responses until they finish. Those sites would get the same silent failure you saw with the chat widget.
- **So the dashboard checks itself.** If no message arrives within 8 seconds, it switches to polling and reports that it did.
- **Polling every 4 seconds meets the target by itself.** Built first, it works for every customer within days, and SSE becomes the faster, cheaper path for sites where streaming works.

This is a tentative pick at about 70% confidence. The close second is polling every 4 seconds with nothing else. The choice is really **simplicity vs. latency and server load**, and you haven't said which matters more. Details below.

---

```
◇ step 1 diverge    15 candidates → docs/working/dd-live-dashboard-counts.md
                      1 do-nothing  2 poll 15s  3 poll 3–4s+ETag  4 long-poll  5 SSE-only
                      6 SSE+poll-fallback  7 WS via LB  8 Socket.IO  9 wss-only  10 fetch-stream
                      11 managed realtime  12 customer allowlist  13 threshold alerts  14 adaptive poll  15 WebTransport
◇ step 2 diagnose    9 constraints (4 hard · 5 soft) → docs/working/dd-live-dashboard-counts.md
◇ step 3 match       4 of 15 survived → [6] [3] [8] [4]
```

```
��─ DECISION: Live dashboard counts, ≤5s fresh, for 100% of sites incl. Upgrade-stripping proxies ─┐
│ 4 candidates survived step-3 pruning · scored on the step-4 axes                                │
└─────────────────────────────────────────────────────────────────────────────────────────────────┘

  legend   ● strong / low   ◐ partial / medium   ○ weak / high   ✗ fails hard constraint

   #    approach                  effort      risk      coverage    key downside
  ───  ───────────────────────  ──────────  ────────  ──────────  ──────────────────────────────────────
   6  ★ SSE + 4s poll fallback   ◐ 4–6 d     ◐ med     ● 4/4 hard  ◐ two transports to maintain (mitig.)
   3    Short poll 4s + ETag     ● 1–2 d     ● low     ● 4/4 hard  ◐ ~1,000 req/s steady load; ~2s avg lag
   8    Socket.IO (WS+fallback)  ◐ 3–5 d     ◐ med     ● 4/4 hard  ○ needs LB sticky sessions; 2-way unused
   4    Long polling             ◐ 3–5 d     ◐ med     ● 4/4 hard  ○ SSE-level complexity, poll-level overhead

  Say a # to open that candidate's card; [6] is open below.
```

```
╭─ [6] SSE + 4s poll fallback   ★ recommended ──────────────────────────────────╮
│ effort    4–6 dev-days (poll endpoint 1–2d, SSE+fan-out 2–3d, watchdog 1d)    │
│ risk      med → low once spike passes                                         │
│ coverage  4/4 hard · 4/5 soft (misses S5 multi-tab w/o HTTP/2 or shared tab)  │
│ hypothesis  "If chosen, p95 change→screen ≤2s on SSE sites and ≤5s on         │
│             fallback sites within 2 weeks of rollout; counter-evidence = any  │
│             dashboard with last-update age >30s that did not fall back."      │
│ stress-tests applied                                                          │
│   · Boring alternative → polling alone meets target; build it FIRST as the    │
│     fallback, then add SSE (effort split, risk lowered)                       │
│   · Failure-driven → buffering proxy = silent fail; added 8s watchdog +       │
│     transport telemetry (risk ○→◐)                                            │
│   · Scale test → at 40k dashboards polling = ~10k req/s, SSE stays cheap      │
│ key downside  two code paths; mitigated: both serve the same snapshot cache   │
╰───────────────────────────────────────────────────────────────────────────────╯
```

```
▶ recommend [6] SSE + 4s poll fallback · confidence 70% · runner-up [3], axis = simplicity vs latency/load
```

This is Path C (no one is around to answer), so I'm going ahead with the tentative pick and filing the question below.

---

### `docs/working/dd-live-dashboard-counts.md` (would have been written)

```markdown
# DD working doc — live dashboard counts

## Step 1 — Diverge
Prior pruning grep: no matches found for [realtime, websocket, polling, SSE, dashboard] (docs/decisions/ absent). No candidate 0.

1. Do nothing — keep refresh, add a "refresh" button / meta-refresh.
2. Short polling every 15s (as discussed).
3. Short polling every 3–4s against a cached per-site snapshot with ETag/304.
4. Long polling: hanging GET held ≤25s, returns on change.
5. SSE only (EventSource, heartbeat comments).
6. SSE + client watchdog that falls back to 4s short polling if no event within 8s.
7. WebSockets through existing LB.
8. Socket.IO/engine.io: starts on HTTP long-poll, upgrades to WS when possible.
9. WebSockets over wss:// only, betting TLS tunnels preserve Upgrade (unconventional).
10. fetch() + ReadableStream over HTTP/2 (custom streaming instead of EventSource).
11. Managed realtime vendor (Pusher/Ably) with built-in transport fallback (ideal-if-effort-free).
12. Ask affected customers' IT to allowlist our domain from inspection (social).
13. Reframe: push threshold alerts (email/SMS) instead of live counts (naive/reframe).
14. Adaptive polling: 2s when tab visible and recently changed, 15s when hidden (time-shifted).
15. WebTransport over HTTP/3 (unconventional).

Health check: clustering on "persistent connection" (5,6,7,8,9,10,15) → added 12, 13, 14 on other dimensions
(organizational, reframe, cadence). Lenses: technical, interface, social, time-shifted, reframe. OK.

## Step 2 — Diagnose
H1 Works for the ~30% of sites behind Upgrade-stripping (and possibly buffering) proxies.
   success: from a staging client behind Squid set to strip Upgrade and buffer responses, AND from ≥2 real
   affected customer sites (support's chat-widget list), a count change appears ≤5s.
H2 Freshness ≤5s.
   success: synthetic probe mutates a count every minute; p95 change→DOM ≤5s over 24h, per transport.
H3 Holds 4,000 concurrent dashboards on Node.
   success: load test at 6,000 clients (1.5×): event-loop lag p99 <100ms, API p99 regression <20%.
H4 No silent failure (the chat-widget lesson).
   success: client reports transport + last-update age; alert fires when any dashboard's age >30s.
S1 Low build/maintenance effort (≤1 sprint).
S2 Through the existing LB without new infra (watch the idle timeout, e.g. ALB default 60s).
S3 Server→client only; bidirectional capability is unused weight.
S4 No customer data via third parties (B2B security reviews).
S5 Multiple tabs per manager don't exhaust the HTTP/1.1 limit of 6 connections per origin.

## Step 3 — Match
| #  | H1 | H2 | H3 | H4 | notes |
|----|----|----|----|----|-------|
| 1  | ✓  | ✗  | ✓  | ~  | prune |
| 2  | ✓  | ✗  | ✓  | ~  | prune: 15s > 5s target |
| 3  | ✓  | ✓  | ✓  | ~  | survive; fix H4 with last-update telemetry |
| 4  | ~  | ✓  | ✓  | ~  | survive; held requests may hit proxy timeouts → cap hold at 25s |
| 5  | ~  | ✓  | ✓  | ⚠  | prune: a buffering proxy makes it fail silently → folded into 6 |
| 6  | ✓  | ✓  | ✓  | ~  | survive; watchdog + telemetry fixes H4 |
| 7  | ⚠  | ✓  | ✓  | ⚠  | prune: known silent failure for 30% |
| 8  | ✓  | ✓  | ~  | ~  | survive; needs sticky sessions for multi-instance polling |
| 9  | ~  | ✓  | ✓  | ⚠  | prune: unverified; TLS-inspecting proxies still strip Upgrade |
| 10 | ~  | ✓  | ✓  | ⚠  | prune: same buffering risk as 5, more custom code |
| 11 | ✓  | ✓  | ✓  | ~  | prune on S4 + cost; needs are too simple to justify a vendor |
| 12 | ~  | ✗  | ✓  | ✗  | prune: we can't control customer IT |
| 13 | ✓  | ✗  | ✓  | ✗  | prune: doesn't deliver live counts |
| 14 | ✓  | ~  | ✓  | ~  | folded into 3 (visibility-aware back-off becomes an option on 3/6) |
| 15 | ✗  | ✓  | ~  | ✗  | prune: UDP/HTTP3 is blocked by corporate proxies |

Shared server design for all survivors: DB writes publish per-site change events (Redis pub/sub or
Postgres LISTEN/NOTIFY) → each Node instance keeps a per-site snapshot {orders_waiting, pickers_active,
trucks_at_dock, version}, coalesced to ≤1 push/site/sec. SSE sends the full snapshot (so reconnects
need no replay); the poll endpoint returns the same snapshot with an ETag.

## Step 4 — Stress tests
[6] Boring alternative → build polling first; Failure-driven → 8s watchdog; Scale test → SSE wins at 10×.
[3] Invert thesis → honestly enough for 4k dashboards: 4,000/4s ≈ 1,000 req/s of cheap 304s. Scale test → ~10k req/s at 10×.
[8] Implementation org chart → adds LB sticky-session config + a library for a 2-way channel we don't use.
[4] Boring alternative → dominated: [3] is simpler at equal coverage, [6] is cheaper at equal latency.
Spike before full SSE rollout: open an SSE stream from 2 affected customer sites; check that the first
event arrives ≤2s (headers: Cache-Control: no-cache, no-transform; X-Accel-Buffering: no; 2KB padding comment).
```

### `docs/working/questions.md` entry (would have been appended)

```markdown
### Q-001 — Live dashboard counts: SSE+fallback or polling only?
**Needs:** you: judgment
**Question:** Live dashboard counts, ≤5s fresh, for 100% of sites including Upgrade-stripping proxies — which transport?
**Read:** docs/decisions/001-live-dashboard-transport.md

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| [6] SSE + 4s poll fallback | Stream where possible, poll where proxies block it | 4–6 dev-days | Two transports to maintain |
| [3] Short poll 4s + ETag | Every dashboard asks every 4s | 1–2 dev-days | ~1,000 req/s steady; ~2s avg lag; cost grows linearly |
| [8] Socket.IO | Library handles WS/long-poll fallback | 3–5 dev-days | LB sticky sessions; unused 2-way channel |
| [4] Long polling | Held requests return on change | 3–5 dev-days | Complexity of SSE, overhead of polling |

**Interim:** [6], built polling-first. Tiebreaker: no stated preference on simplicity vs latency/load, so I picked the option whose first milestone *is* the runner-up. Nothing is wasted either way.
**If the answer differs:** choose [3] → stop after the polling milestone and skip the SSE work.
```

### `docs/decisions/001-live-dashboard-transport.md` (would have been written)

```markdown
# 001 — Live dashboard transport

**Goal**: Pick how Tallyboard dashboard counts update live within 5s for every customer site.
**Project state**: Live-count dashboard transport · standalone · not blocked (SSE stage gated on proxy spike)
**Task status**: in-progress (tentative pick, awaiting Q-001)

## Context
Counts update only on refresh. About 30% of sites sit behind proxies that strip `Upgrade` (the chat-widget WS
rollout failed silently). Data flows server→client only. Target ≤5s; about 4,000 concurrent dashboards on Node.

## Options considered
SSE+polling fallback [6], short polling 4s [3], Socket.IO [8], long polling [4]; 11 others pruned (below).

## Decision and rationale
[6]: ship 4s ETag polling first (it alone meets ≤5s for 100% of sites), then layer SSE on top with an 8s
first-event watchdog that drops back to polling and reports which transport is in use. SSE needs no Upgrade
header and fits one-way data, and this design protects against proxies that buffer streams.
See alternatives considered →

## Pruned candidates and why
How to read: each entry is `[candidate-ID]: one-line reason for discard`. Future DDs in adjacent areas can grep this section to avoid regenerating already-pruned approaches.
[1]: no live updates. [2]: 15s interval breaks the 5s target. [5]: fails silently on buffering proxies (folded into 6). [7]: Upgrade stripped at 30% of sites. [9]: TLS-inspecting proxies still strip Upgrade. [10]: same buffering risk as 5, more code. [11]: third-party data flow, vendor cost. [12]: can't control customer IT. [13]: not live counts. [14]: folded into 3/6 as visibility back-off. [15]: UDP/HTTP3 blocked by proxies. Prior pruning grep: no matches found for [realtime, websocket, polling, SSE, dashboard].

## Stress-test mitigations
How to read: *Boring alternative* — reordered the build so polling (runner-up [3]) ships first as the fallback.
How to read: *Failure-driven* — added an 8s first-event watchdog + transport telemetry against silent failure from buffering proxies; risk ○→◐.

## Consequences
Easier: 100% coverage in days; sub-second updates where streaming works; scales to 10×. Harder: two
delivery paths; SSE needs heartbeats every 15s under the LB idle timeout; tabs share one connection via HTTP/2 or BroadcastChannel.

## Revisit triggers
How to read: each entry is a concrete, observable condition that should prompt re-evaluating this decision. Future readers can grep this section when their context changes to see whether earlier decisions still apply.
if fallback share >50% of dashboards (SSE not earning its keep → drop to [3]). if any dashboard's last-update age >30s without fallback. if concurrent dashboards >20k. if the dashboard needs to send data to the server (reconsider [8]).
```

## Before you build the SSE part

1. **Test SSE from two affected customer sites.** Support has the list from the chat-widget rollout. The first message should arrive within about 2 seconds. Send these headers: `Cache-Control: no-cache, no-transform` and `X-Accel-Buffering: no`. Also send a ~2KB comment at the start so buffering proxies pass the stream through.
2. **Settle the trade-off (Q-001).** If you'd rather keep things simple, stop after the polling milestone. At 4,000 dashboards, polling every 4 seconds is about 1,000 cheap requests per second, which is perfectly reasonable.
