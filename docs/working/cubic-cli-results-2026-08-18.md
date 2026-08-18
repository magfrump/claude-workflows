# cubic CLI results: new arm, full 8-instance sweep (2026-08-18)

**Arm**: the `cubic` code-review CLI tool (v1.10.4, subscription/CLI-billed). Its own
logs (`service=claude-code-acp provider=Claude Code`) show it orchestrates **Claude
Code as its execution backend** via ACP — cubic supplies its own harness/prompts on
top of that provider, not a from-scratch model call. Session-tracking metadata records
`model=gpt-5.6-luna`, which appears to be cubic's own tracking label rather than the
model that actually did the review work (the review durations, tool-call counts, and
provider tag all point to Claude Code). Output format: `review.json` with a flat
`{issues: [...]}` list, each issue tagged `priority: P0-P3`, `file`, `line`, `title`,
`description` — no separate summary/attestation text, no dollar cost recorded (same
untrackable-subscription-cost situation as E6/E7). Wall-clock per cell ranged
4.5–10.8 minutes (`durationMs` in each `stderr.log`).

Scoring: one adjudication agent per cell, each independently re-verifying claims
against the actual code in `external/cc-review-eval/mfc-*` (not just trusting the
tool's self-report), anti-SWR-Bench rules.

## Headline

| Findable | Found | Recall | Confirmed FPs | False attestations |
|---|---|---|---|---|
| 54 | 21 firm + 1 partial (pf-R1) | **38.9% firm, ~40.7% incl. partial** | **1 confirmed** (csp — re-asserts the already-refuted N7 worker-src claim) | **2 confirmed** (both in mfc-postfix — see below) |

This lands cubic-cli below every Claude-Code-based arm on this ledger (E2's 19% is the
only one lower), but its cost profile (subscription, ~5–11 min/cell, comparable to
E5/E7) and its precision-on-what-it-reports pattern (small, focused issue counts,
mostly real when matched) make it a genuinely different tradeoff point, not simply "the
worst arm." See caveats below — one cell (`mfc-postfix`) had a documented sandbox
failure that materially depressed its score.

## Per-cell

| Cell | Score | Notes |
|---|---|---|
| mfc-csp | 4/10 | Hits A1, A3, A4, C1 — the P0 nonce-header bug and its comment/test/dev-mode cascade. Misses R1, R2, A2, C4, N1, N15 — everything requiring cross-consumer tracing (PNG export, matcher regex, markdown images) or a second CSP-vs-comment sweep. 2 new findings: missing `worker-src` (pdf.js) and missing `form-action 'self'`. **The `worker-src` finding is a confirmed false positive** — it re-asserts the exact claim ledger row N7 makes, which was refuted 2026-08-17 by E7r2 with spec + WPT evidence (`'strict-dynamic'` blesses worker creation; the WPT strict-dynamic worker test passes in current Chrome/Firefox/Safari). `form-action` is a genuine new candidate, single sighting. |
| mfc-lean | 4/7 | Hits R1, N3, N4, N5 — the docs-stale row and the full node-mode `unavailable`-collapse cluster, correctly prioritizing N5 as P1. Misses R2, A1, N8 — the fix's own second-order bugs (discarded error body, dropped reason/detail fields) and the live persistence-sanitizer bypass. 2 new findings, both confirmed real, both minor (an app-server-hop network-failure misreport, a missing-tests nit). |
| mfc-hygiene | 2/3 | Hits R1, A1. Misses N14 (the caching/eviction defect — only the adjacent logging half of the same code region was caught). 2 new findings, both confirmed real and minor (a JSDoc/code contradiction on Anthropic `responseFormat` support, an error-class inconsistency between two OpenRouter paths). 0 false positives, notably calibrated hedging on an unverifiable SDK-param claim. |
| mfc-secdeps | 3/5 | Hits R1, A1, C2 — all three static lint-rule-gap findings, with C2's mechanism matched even though its named bypass vector (dynamic import vs `require()`) differs from the ledger's phrasing. Misses N2 and N9 — **both are the "run it and watch it fail" defects** (a failing audit gate, a crashing lint config), independently re-executed and reproduced by the scoring agent but never raised by cubic. Consistent pattern: cubic critiques rule *design* but doesn't execute commands to find *breakage*. |
| mfc-deploy | 1/3 | Only 2 issues reported, both about README.md; never touches CLAUDE.md at all, so dep-R1 and N10 (both CLAUDE.md-sourced) are structurally unreachable this run. Hits dep-R2. 1 new finding, confirmed real and cost-relevant: the LLM cache (`cache.ts`) silently fails to write on Vercel via the same read-only-`cwd()` mechanism as the analytics writes, but the README's Limitations section never mentions it — every repeat request re-bills the LLM API. Did not repeat E7r2's N10 false attestation, but only by never engaging the claim (silence, not correct verification). |
| mfc-fscompat | 2/6 (2/5 live — fsc-A2 already fixed) | Hits R1, A4. Misses A1, A3, D6 (fsc-A2 excluded, not present in this checkout). 1 new finding: bare `/tmp` root with no app-namespaced subdirectory — PLAUSIBLE, distinct mechanism from candidate row N20 (this is a shared-root collision risk, not the `VERCEL=1`-fires-locally trigger). No 3rd sighting of N20. Weakest live-ratio cell alongside deploy. |
| mfc-corpus | 5/11 | Hits A4, D3, D4, D5, N11. Misses A1, A2, A3, C3, N12, N13 — correctly avoided fabricating a build-verification claim on C3 (unlike two prior arm-reps), simply didn't engage it. 5 new findings, all confirmed real and minor: a `workspaceSlug` collision (**2nd independent sighting** — E7r3 also flagged this, PLAUSIBLE at the time; now CONFIRMED twice, different arms), a `manifestVersion` field checked for type but never compared to the expected constant (**2nd independent sighting** — E7r2 also flagged this), plain `Error` instead of `CorpusError` at 3 throw sites, an asymmetric test-fake (`readFile` returns by reference, `writeFile` copies), and an untracked-but-not-gitignored file. |
| mfc-postfix | 0/9 firm + 1 partial (pf-R1) | **Degraded run, not a fair test.** The session's shell was broken (`bwrap` sandbox init failure, confirmed unfixable even with `dangerouslyDisableSandbox`), so `git diff` was never computable; cubic recovered gracefully via git metadata + manual reads of only the 4 known dirty commits' files, spending ~8.5 of its ~10.8 minutes on recovery rather than review. The one issue it did report (pf-R1's mechanism, on one panel) is real and code-verified, just narrower than the ledger row's full scope. **2 confirmed false attestations** in the session summary: (1) certifies the CSP `'unsafe-eval'` dev-only carve-out as "verified with its pinned test suite" — the exact fail-open default ledger row pf-A1 describes, on a code path the cited tests don't even cover (mirroring E7r1's pf-A5 trap in this same historically FP-prone cell); (2) a blanket "all comments verified consistent" claim over a commit that in fact left a stale duplicate comment in place (pf-A8). Both are affirmative, false, and reproducible-by-inspection — not merely unverifiable, unlike the C3 pattern seen elsewhere. |

## New candidate rows added to the ledger

Two corpus findings independently corroborate candidates already surfaced by other arms
— both now have 2 independent sightings from **different arms**, which is a stronger
signal than 2 sightings from the same arm's reps:

- **N23** corpus: `workspaceSlug`/`safeSegment` collision — distinct title strings (e.g.
  "My Workspace", "my workspace!", "MY-WORKSPACE") all reduce to the same folder slug,
  with no collision detection. 2 independent sightings (E7r3, PLAUSIBLE; cubic,
  CONFIRMED — both code-traced the same NFKD/collapse/lowercase pipeline).
- **N24** corpus: `manifest.ts`'s `manifestVersion` field is type-checked
  (`typeof === "number"`) on read but never compared against the expected
  `MANIFEST_VERSION` constant — a future format bump would silently misparse old
  manifests. 2 independent sightings (E7r2, CONFIRMED; cubic, CONFIRMED).

Two new single-sighting candidates, held to the same bar as N17/N21/N22 (code-verified,
mechanism-distinct, not enumeration/convention noise):

- **N25** deploy: the LLM response cache (`cache.ts`) silently fails to write on Vercel
  via the same read-only-`cwd()` mechanism as the analytics writes (dep-R1/dep-R2's
  mechanism), but the docs' Limitations section never mentions the cache — every repeat
  request re-bills the LLM API. CONFIRMED (cubic, single sighting).
- **N26** csp: missing `form-action 'self'` CSP directive — the policy hardens
  `base-uri`, `object-src`, `frame-ancestors` but omits `form-action`, leaving injected
  `<form action="https://evil...">` exfiltration unrestricted. CONFIRMED (cubic, single
  sighting).

The remaining new findings from this pass (hygiene's JSDoc contradiction, lean's
app-server-hop misreport, corpus's plain-`Error`/test-fake-asymmetry/gitignore items,
fscompat's shared-`/tmp`-root risk) are real but stay out of the ledger under the
existing enumeration/convention/minor-nit exclusion policy — recorded in the per-cell
notes above.

## What this arm establishes

1. **A genuinely different tool, same backend.** cubic orchestrates Claude Code
   (confirmed by its own ACP provider tag) with its own harness — so this measures
   harness/prompt design holding the model roughly constant, not a new model. Its
   recall (39-41%) sits well below every Claude-Code arm scored on this ledger,
   suggesting cubic's default review depth/scope is substantially shallower than the
   `code-review` skill's pipeline or the built-in `/code-review`.
2. **Static-only posture.** The secdeps cell is the cleanest signal: cubic caught every
   lint-*rule-design* gap but missed both defects that only surface by *running*
   something (a failing CI gate, a crashing lint config) — both independently
   reproduced by the scoring agent. This is a consistent pattern across cells, not a
   one-off.
3. **Two confirmed false attestations**, both in mfc-postfix, both affirmative and
   false (not the "unverifiable claim" pattern seen elsewhere) — the CSP fail-open
   certification is a close cousin of E7r1's pf-A5 trap in the exact same historically
   FP-prone cell. Worth treating with caution given the cell's documented sandbox
   failure, but the false claims stand regardless of *why* the run was degraded.
4. **One confirmed false positive** (csp's worker-src claim re-asserting refuted N7) —
   the first FP on ledger row N7 recorded from an arm *after* its refutation, i.e. a
   genuinely fresh mistake rather than an artifact of the older E6/E7r1 runs that
   predate the refutation.
5. **Real cross-arm corroboration**, not just within-arm replication: two of cubic's
   new findings (N23, N24) independently confirm candidates first raised by E7 reps —
   different tools, same underlying defects, which is stronger graduation evidence than
   two reps of the same tool.
