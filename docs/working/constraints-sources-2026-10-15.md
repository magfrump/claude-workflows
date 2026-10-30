# Sources for docs/constraints.md (Q-155)

Date: 2026-10-15. Input for the user's answer to Q-155, not the constraints doc itself. Plan D2 says the constraints doc is the user's to write.
Read: decision records 001–037 (the ones that exist), `docs/decisions/log.md` rows 1–72, `docs/working/dd-*.md` (7), `archive/docs/*-dd-*.md` (12). Three parallel read-only passes, merged and deduplicated here.

Grammar the gate checks (`scripts/build-loop.sh` header, `constraints` line): `H<n>: text` at column 0 (or after `- `), each followed by a `success: <observable>` line before the next constraint or `#` heading; `S<n>: text` for soft; no repeated ID; fences skipped; a near-miss like `H1a:` makes the file unreadable. Every loop prompt quotes the file, and every design choice a loop makes alone runs divergent design seeded with it, so each line costs prompt tokens in every loop.

## How to read this

- **Draft** below is copy-ready: lines in the gate's grammar, ordered by how many independent sources carry the rule. Delete, merge or reword freely; IDs can be renumbered.
- **Sources** gives each draft line's citations (file:line, short quote) so you can check the reading.
- **Choices** lists where sources disagree, which only you can settle.
- **Excluded** lists what was judged feature-specific.

All 19 sources are older than the build loop, so none of them was written as a loop constraint. Each draft line restates a rule the repo already follows so that it can bind an unattended loop.

## Draft

Revision 2, 2026-10-15, after the user's first read. This doc is for design-level constraints that steer the choices a loop makes on its own. Coding rules (argv, credentials, host actions, live verification, questions-file ownership, docs) now appear under "Moved out" below. Most of them are already enforced by code here, so no prompt needs to restate them.

H1: Code that gates, reviews or bounds a change runs from a copy that change cannot edit (the root-owned image payload or the host); what an agent session writes is input to those checks, not a source of their logic.
success: no new hook, gate, launcher or reviewer invocation reads its code or policy from the working tree; security-reviewer reports no "the reviewed branch can change its reviewer or gate" finding.

H2: Fail closed and loudly: a missing dependency, unparseable input, absent verdict or degraded primitive exits non-zero (or refuses) and names what went unenforced; nothing ships present-but-inert, and degradation only ever narrows access.
success: each new failure path has a bats case asserting a non-zero exit or refusal plus a message naming the gap; no `|| exit 0` or silent skip on a missing dependency.

H3: Every behavioural change is verifiable inside the sandbox with hermetic tests (no network, no live `claude`, no Docker, no host); a host check can add to that, never replace it.
success: `bats` passes in the sandbox with new cases for the change; `scripts/hermeticity-lint --root .` passes.

H4: An LLM judgment is a detector, never an enforcement primitive: a blocking gate keys on something re-checkable from the artifact (an exit code, a verbatim quote with file:line), and a new judgment-based check ships advisory until a recorded falsifier passes.
success: the design names the deterministic channel that carries any model output into a blocking decision; a new judgment check is capped at amber.

S1: Security measures are proportionate: weigh a restriction's friction (egress profile work, denied tools, extra host steps) against the risk it removes given what is already permitted, and do not add a restriction whose bypass is already allowed; a relaxation that states its residual risk is a valid design.
S2: Cost scales by passes, tasks and rounds: add no new mandatory agent dispatch per pass and no more than about 30 lines to always-loaded context (no `@` imports in instruction files) unless the design states the measured delta and why it pays.
S3: Reuse the existing reviewed mechanism (launcher, installer, gate, helper) before adding a second; one trust regime and one code path per job, and one source of truth per rule or grammar, never restated.
S4: Put mechanical steps in tested scripts rather than prose; prose that must guide behaviour arrives at the moment it is needed.
S5: Establish the motive before comparing options; the status quo and deciding against a feature are valid outcomes, and value in real use outside this repo outranks loop-internal metrics.
S6: A new script, skill or workflow needs a call site something actually runs and a claimed benefit with an observable that could come out negative.
S7: Measure before budgeting a saving; a cost cut in the review pipeline is recall-neutral by construction or gated on a measured recall check.
S8: Keep units small and dependency-free: under the ~400-line cap (log row 62), no growth of the 500-plus-line files (`cc-isolated.sh`, `install.sh`), python3 stdlib and bash, no new image package.
S9: Prefer the minimal change one `git revert` undoes, staged so the cheaper step is checked first; after repeated mechanism errors, escalate to a decision instead of another patch.
S10: Spend the user's attention last: at most one host paste per verification, no new recurring host chore or trust decision, nothing left behind to clean up, and no safety that depends on the user remembering a flag.
S11: Portable where it costs little: AGENTS.md-readable instructions over Claude-Code-only hooks, pure-text mechanisms over kernel or platform primitives.

### Moved out (revision 1's IDs)

| Rev 1 | Rule | Enforced today by | Proposed home |
|---|---|---|---|
| H2 | Never widen permission, egress or isolation; allowlists over denylists | Permissions, egress profiles, launcher probes | Replaced by S1 (proportionate). Relaxing existing restrictions is separate work (Choices, C9) |
| H3 | Untrusted text reaches a subprocess only as argv or a quoted heredoc | Nothing automatic; record 018 | `skills/security-reviewer`: its injection item names only "user-facing code", and the argv rule is general enough for every project the skill serves |
| H5 (test half) | Stub `claude`/`curl`/`gh`/`wget`; stubs as strict as the tool; no skip on in-repo files | `scripts/hermeticity-lint`, `test/fixture-hermeticity.bats` | The lint covers stubbing; stub strictness and no-skip could go in AGENTS.md's testing notes |
| H6 | Label unexecuted verification; `Live-verified:` trailer; state residual risk | `hooks/live-verify-gate.sh`; log row 61(4) pre-mortem | Already enforced; residual risk could go in `skills/security-reviewer` |
| H7 | No host install or bless from a loop; host git never trusts container `.git` | install.sh's no-agent check (Q-058); D6 runs the image copy | Already enforced |
| H8 | No host credentials in the boundary; no third-party LLM provider; one headless helper | `permissions.deny`; log row 48; `test/claude-headless-flags.bats` | Already enforced |
| H10 | Non-interactive; questions only through the blocked marker | The build-loop prompt and gate (log row 72, D5/D7/D11) | Already enforced |
| H11 | Undocumented is broken; no doc drift | Dev-cycle digest (log row 68); `test/cross-reference-integrity.bats` | Already enforced |
| S10 | Probes self-contained, `timeout`, stop by PID | Memory notes only | AGENTS.md or a guide |

## Sources

This table uses revision 1's IDs. In revision 2: H1 = rev 1 H1 (reworded), H2 = H4, H3 = H5 (design half), H4 = H9, S1 is new, S2–S9 = rev 1 S1–S8, S10 = S9, S11 = S11.

| Draft | Sources (file:line, quote) | Count |
|---|---|---|
| H1 | 014:90-93 "must ship inside the deployed hook copy, not be read live from the agent-writable repo"; 016:58-59 "no session can edit the boundary it runs under"; 022:64-66 "would let a session rewrite the critics that review it"; 023:53-57 "a default, not a boundary"; log row 72 (D6: the gate runs the image copy); DDs: review-gate-signal:55, code-intent-claims:214, polyglot:145, secure-tool:120, W/dd-install-sh-gating:53, W/dd-branch-verify:52, cc-process:90, multi-project:83, W/dd-015:98 | 4 records, 1 row, 9 DDs |
| H2 | 014:3 "without expanding the security surface", 014:77 [5]; 015:84; log row 64 "An allowlist over finite sets ... converges where the denylists did not"; 019:41-43; 034:58; log row 52 (no profile suggestion from repo contents); log row 42 (IPv6 needs a designed allowlist); DDs: polyglot:143, secure-tool:91, W/dd-arith-eval:52, W/dd-015:97,99,100, cc-process:89, multi-project:112 | 5 records, 3 rows, 6 DDs |
| H3 | 018:32-34 "must reach a subprocess as a distinct argv element, never interpolated into a string that a shell re-parses"; 018:40-43; 019:31-33 quoted heredoc; reference pattern scripts/confine-tests.sh:220 | 2 records |
| H4 | 015:82 "a boundary that silently degrades is worse than none"; 017:102-103, 136-138; 018:57 "fail closed; never guess"; 023:118-120 present-but-inert (three instances); 035:58; log rows 24, 39, 51 ("degrades to 'stays blocked', never to a wider allowlist"), 53→64, 56; DDs: review-gate:57, polyglot:150, loopback:113,139, W/repo-split:115 | 6 records, 5 rows, 4 DDs |
| H5 | 017:9-12 (commit 4d39475 ran a live, billable `claude -p`); 017:105-109 lint is triage, `confine-tests.sh` is ground truth; 014:48-51; log row 17; log row 44 (an `iptables` stub accepted any argv); log row 50; 023:135-137 (skips removed); DDs: W/install-sh:59, W/arith-eval:54, loopback:119, W/repo-split:108, polyglot:156 | 3 records, 3 rows, 5 DDs |
| H6 | 016:185-188 "Verify the artifact, not just the input"; 019:63 "Residual risk is documented, not hidden"; 034:89-90; 035:44; 037:79-88; log rows 44 "probe ... against the assembled ruleset", 45 "Blessed ≠ verified", 60, 61(4) pre-mortem with bypass families, 71; DDs: W/dd-015:103, W/repo-split:101 | 6 records, 5 rows, 2 DDs |
| H7 | 037:31 "Host target never installs non-interactively", 037:62 "no agent may run during an install", 037:81; 022:60-61 "Landing a change requires a human on the host"; 034:34 "The host never reads a container-written `.git`"; Q-162's paste text (the guard's reasoning) | 3 records |
| H8 | 015:84 "forbids real host credentials inside the boundary"; 016:23,74-75; log row 48 "OpenRouter is out of scope for this repo"; 021:156, 030:104 secret screening; 023:158-159 `.credentials.json` deny; log rows 24, 37 (one helper; never `--bare`; judge by the JSON envelope) | 5 records, 3 rows |
| H9 | 028:112 "a detector, not an enforcement primitive", 028:48-49, 028:161-162 "advisory first"; 010:51 and 012:25 (autonomous REFUTED verdicts were misleading; only the user marks REFUTED); log row 25; DDs: code-intent:220, review-gate:69, escalation:119 | 3 records, 1 row, 3 DDs |
| H10 | 010:24 "Fully non-interactive"; 012:108 questions.md is the channel; log rows 61, 67, 72 (D2 Path A or blocked; D5/D7/D11 orchestrator is the only questions writer); DDs: code-intent:191, escalation:107, review-gate:54, polyglot:154, secure-tool:98, cc-process:93 | 2 records, 3 rows, 6 DDs |
| H11 | log row 68 "'undocumented is broken' is a rule"; DDs: SI-loop:160, W/repo-split:130, W/install-sh:57 | 1 row, 3 DDs |
| S1 | log rows 47 (~8K tokens per request), 65 (~89K tokens of `@` imports); 014:39, 014:77 [9],[13]; DDs: review-gate:65, code-intent:224, escalation:136, synthesis:70, secure-tool:105, lightweight:81, token-reduction:65 | 1 record, 2 rows, 7 DDs |
| S2 | 016:60-62; 035:47-49; 028:136-138; 036:90; 037:46; log rows 49, 56, and the "defined once" row; DDs: W/install-sh:62, W/repo-split:95,126, W/branch-verify:59 | 5 records, 3 rows, 3 DDs |
| S3 | log rows 67, 68, 72 ("the prose-only seed failed review passes 6–9"); DDs: code-intent:232, escalation:154, review-gate:76, secure-tool:95 | 3 rows, 4 DDs |
| S4 | 036:36-39, 74-77 "A restructure with no live motive is churn"; 009:11-13, 17-18; 008:69-73; memory "Eval metrics: real-world value" | 3 records |
| S5 | SI-loop DD:140, 147, 165 (the lesson of its three-month dormancy); 010:12 (features never communicated); DDs code-intent:239, review-gate:73, escalation:157 | 1 record, 4 DDs |
| S6 | 032:121-129 (cache measured ~5%, "NOT 20–40%"); 031:160; log row 12; 028:110 "data without a consumer" | 3 records, 1 row |
| S7 | log row 62 (size cap; only the user waives); 017:92-93; 014:102-103; DDs: W/branch-verify:58, W/arith-eval:60, loopback:135,137, polyglot:168 | 2 records, 1 row, 4 DDs |
| S8 | 011:64, 82-84; 034:28-30 "a decision, not a fourth patch"; 021:134-136; DDs: SI-loop:176, W/repo-split:128 | 3 records, 2 DDs |
| S9 | 037:28 "I *will* forget to add flags"; DDs: W/dd-015:110-111, W/arith-eval:56, W/branch-verify:50,57 | 1 record, 3 DDs |
| S10 | 019:55-59; log rows 60, 61(3); memories "Probes must fail without their temp dir" and "Stop processes by PID" | 1 record, 2 rows |
| S11 | 014:63-68; 017:111-114 "pure text processing"; 017:125 hook sprawl; DDs: secure-tool:111, polyglot:163, multi-project:138, W/dd-015:109 | 2 records, 4 DDs |

## Choices only you can make

| # | Question | Sources disagree how | Draft's interim |
|---|---|---|---|
| C1 | Is cost hard or soft, and is the limit numeric? | 7 DDs treat cost as hard, with thresholds from "≤ one extra dispatch" (code-intent:224) through "delta = 0" (escalation:136) to "≥15% reduction" (token-reduction:65); fact-check:109 treats it as soft | Soft (S1): no new mandatory dispatch unless justified. A hard numeric limit would stop loops whose briefs exist to add a review pass |
| C2 | Is the falsifiable payoff / exercise site rule hard? | Hard in the SI-loop DD (H1, H2, H5); soft or "prefer" in three others | Soft (S5): as a hard rule it would block docs-only and exploratory units |
| C3 | Fail loud everywhere, or only at gates and boundaries? | Hard in polyglot:150 and repo-split:115; soft in loopback:139 (beside a hard fail-closed rule) | Hard everywhere (H4). The narrower form would read "a gate, guard or boundary fails closed" |
| C4 | Repeat process rules the gate already enforces? | Review-fix loop 0R + 0A (031:12-14, log row 63) and the size cap (log row 62) are both enforced outside the doc | Left out as hard lines (the build loop's own prompt and pr-prep carry them); the size cap appears inside S7 |
| C5 | Scope devcontainer-only rules? | Egress exact names, pinned and checksummed toolchains (log rows 19, 26, 38, 52) and the host-tool exit convention (row 58) apply only to `devcontainer-config/` | Folded into H2 and H7 in general form; the pinning and checksum rule left out. It could return as "S12: when touching devcontainer-config, …" |
| C6 | Is "nothing left to forget" hard? | Hard in W/branch-verify:50 (H3 there); soft in W/dd-015, arith-eval | Soft (S9) |
| C7 | Host checks as supplement or replacement? | "At most one host paste" (W/dd-015:110, soft) against sandbox verifiability (W/install-sh:59, hard) | H5 and H6 together: sandbox tests are required, and a host check only adds to them |
| C8 | How long may the doc be? | Every loop prompt carries it (log row 72) | Revision 2: 4 hard + 11 soft, roughly 30 lines |
| C9 | Relax existing restrictions too? | The user (2026-10-15): egress profile work has been costly, and existing permissions often allow arbitrary execution already, so some restrictions are theatre | Not in this doc. A roadmap idea would audit which restrictions buy nothing, given what is already allowed |

## Excluded as feature-specific

Override any of these by adding a line.

- Review pipeline internals: critic structure (002), the verdict scale (001, 033), k values and tier carve-outs (031, 032), the Soundness-Contradiction trigger (028), true-positive deference and coherent-doc replays, tier glyph keys, and the cap at yellow for unvalidated channels. The general rule is kept as H9.
- Benchmarks: byte-identical prompts, per-review dollar bands, and recall classes (021, 030, the lightweight and reviewer-context DDs). These belong to the SWRBench fork.
- Isolation mechanics: Docker against podman, `--id-label`, firewall, DNS and SNI internals (log rows 39–44, 55; loopback C1–C10), WSL2 facts, symlink against merge for `~/.claude` (022), `wiring.json` merging (023), and payload provenance stamping (036).
- Skill-specific: arithmetic-eval's AST and sandbox tiers (019; only its argv/heredoc rule is kept as H3), the hermeticity adapter schema and Go recipe (017), the hypothesis grammar and screening (008, 012), and the feedback.md format (009).
- Process docs: the pr-prep step list (007) and divergent-design stress-test moves (003). The decision-record conventions (Pruned, Revisit triggers, log row against record) are well documented already, so repeating them here would only add prompt cost.
- Superseded, so don't cite them as current: 020's skip-on-unparseable choice (amended to fail closed); 022's "hooks not wired" (superseded by 023); 031's all-k=1 setting (row 63); row 53's accepted gaps (row 64); rows 43 (by 44), 67 (by 68) and 48 (partly by 49); and row 45's scope (row 71). cc-process DD's soft egress rule was superseded by W/dd-015's hard one.
