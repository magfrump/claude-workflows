# Experiment: Stage-1 context enrichment FP-kill validation (D3/D4 re-run), 2026-07-31

**Question:** does decision 021's Stage-1 enrichment (`--context-base`: labelled
sibling-branch diff + inlined enclosing files) stop the two most severe false positives
of the 2026-07-30 diff-only sweep — Result 3c (heredoc-merge Critical) and Result 5
(sibling-commit "missing work" consensus)?
**Answer: yes, both. 0/8 replicates reproduced either FP class, on the same four
families swept diff-only (three of which produced Result 5; one, Gemini, produced
Result 3c).** Cost and portability guardrails hold.

**Harness:** `scripts/cross-model-review.py --context-base` (Stage 1 as built,
default `--max-inline-kb 64`).
**Baseline:** `docs/working/experiment-cross-model-review-2026-07-30.md` (Results 3c, 5).
**Cost model:** `docs/working/stage1-context-cost-2026-07-31.md`.
**Raw data:** `runs/cross-model/s1-31e2d3a/`, `runs/cross-model/s1-7ceba3f/`
(findings.jsonl + overlap.json committed; prompt.txt is local-only and reproducible
via `--dry-run` — verify with the stamped `prompt_sha`).

## Setup

Same four families as the baseline sweep — `moonshotai/kimi-k3`, `openai/gpt-5.6-sol`,
`anthropic/claude-sonnet-5`, `google/gemini-3.1-pro-preview` — 2 replicates each,
judge pinned `anthropic/claude-sonnet-4.5`.

Context bases chosen to reproduce review-time branch state (the cost doc's † pitfall):

| Cell | Range | `--context-base` | Sibling section contains |
|---|---|---|---|
| D3 | `31e2d3a~1..31e2d3a` | `4582f97` (= `8ef9d52~1`, chain start) | chain-start hardening + tiered-confinement feature + review-fix rounds 1–5 (7 commits, 27 KB) |
| D4 | `7ceba3f~1..7ceba3f` | `45bea51` (= `5e67ab5~1`) | Tier A + Tier B (11 KB) — exactly the work Result 5 called "missing" |

Prompt SHAs `bfc998d0be1c` (D3, ~20k tokens) / `e106076c4ce1` (D4, ~12k tokens);
byte-identical across models, plain chat-completions, no tools (H2/H3 preserved).
All 16 calls returned `parse_ok=True`; zero abstentions except Sonnet D4 r1.

**Known cap-relevant detail:** on D4 the enclosing-file section omitted
`scripts/self-improvement.sh` (72 KB by the harness's chars÷1024 accounting; the blob
is 74,876 bytes — either way over the 64 KB cap) — the very file whose `file_scope`
line refutes Kimi's baseline escalation. The FP-kill therefore tests the **sibling-diff
label alone** on the file-scope claim.

## Result A — D4: the Result-5 sibling-commit consensus FP is gone (0/8, was 6/11 replicates across 3 of 4 families)

Baseline: three of four families — Kimi 2/2, Gemini 3/3, Sonnet 1/3, all at High —
flagged Tier A/B work as missing (Sol filed it in 0/3 replicates; the baseline doc's
"all four families" line overstates its own data). Kimi escalated it to a functional
bug ("gate 1c only permits docs/working/ → every task rejected").

Stage 1: **no finding in any replicate claims Tier A/B work is missing** — no
`file_scope` FP, no "si-functions.sh doesn't exist", no High findings at all.
The sibling-diff section alone sufficed despite the 72 KB inline omission.

The failure inverted into correct use of the context: Sonnet r2's decision-020 finding
*cites* gate 1h as "already committed" and instead makes the sharper (grounded) claim
that no gate verifies Tier-C compliance — i.e. the model read the labelled sibling
context and reasoned about it correctly rather than flagging it as absent.

The 15 findings shifted to real Tier-C-diff issues, including two independent
rediscoveries of the live Result-3 pipefail bug (Sol r1 Low, Gemini r1 Medium) —
previously found only by Kimi. Recurrent cluster (2 families — Kimi and Sol, 4/8
replicates; 3 families in the baseline): fix-task detection reads only the branch
**tip** commit subject, missing multi-commit task branches.

## Result B — D3: the Result-3c heredoc-merge Critical is gone (0/8)

Baseline: Gemini r1 raised **Critical** "check.py evaluates payload natively on host"
by merging two adjacent `<<'PYEOF'` heredocs into one file.

Stage 1: the full `SKILL.md` is inlined (heredoc boundaries visible); **no replicate of
any family reports the runpy/check.py misattribution**. Gemini's findings are now the
real `np.load` positional fail-open (Result 3b; High in r2) and the bwrap `/tmp` CWD
issue. 23 findings total, every one citing constructs that exist in the reviewed files
(deeper reachability arguments inside findings remain unexecuted claims).

Persistent cross-family consensus finding (all 4 families here, Medium except Sonnet r2
at Low; already a 4-family finding in the diff-only baseline, 8/12 replicates): the
bwrap invocation `--tmpfs /tmp … --chdir "$PWD"` fails when the caller's CWD is under
`/tmp` outside `$AE` (the tmpfs leaves nothing to chdir into), and the probe doesn't
mirror the real run's `--chdir`. Spot-checked against
`31e2d3a:skills/arithmetic-eval/SKILL.md:268` — the flags are as described; this is a
plausible real edge that **survived the context enrichment that killed the
misattribution FPs**, which is the strongest signal in the run that it is not itself a
misattribution. Candidate follow-up, not yet triaged.

## Result C — cross-family overlap rises with shared context; Sonnet stops abstaining on D3

Issue-level Jaccard (judge-matched), D3: the Sonnet↔Gemini↔Sol pairs now sit at
0.28–0.40 (Sonnet-involving pairs were 0.000–0.119 in the baseline); the change is a
redistribution, not a uniform rise — the two largest Kimi-involving pairs fell
(0.258→0.042, 0.382→0.103; the third rose 0.000→0.036) and so did the baseline
maximum Gemini↔Sol (0.513→0.375).
The non-Kimi trio converges on the same real issues (np.load, bwrap `/tmp`); Kimi
diverges further (J_cross 0.036–0.103) — it still finds things nobody else does.
D4 J_cross stays low (0.0–0.267; the three baseline-comparable pairs fell,
Sonnet↔Gemini to 0.0): a docs+script diff spreads attention more.

Notable recall change: **Sonnet found the Result-3b `np.load` positional issue in 2/2
D3 replicates** — diff-only, no Sonnet replicate found it (0/3). One run is not a
recall measurement, but it is consistent with enrichment helping the incumbent too,
not just suppressing FPs.

D4 abstention: Sonnet 1/2 replicates empty (r1) — the abstention-rate line (follow-up 4
fix) now surfaces this instead of scoring it J_self=1.0.

## Cost — guardrails hold

Actual spend (review calls, from `usage.cost`): D3 $2.08 + D4 $1.45 = **$3.53** /16
calls, plus judge matching. Median per-call **$0.226** — under the ~$0.33 band trigger;
worst call $0.388 (Kimi D3 r1, 636 s, reasoning-heavy — the known estimator blind
spot). Sweep total well under the $10 trigger. Latency: Sol 48–76 s, Gemini 110–143 s,
Sonnet 93–263 s, Kimi 287–636 s.

## Verdict and follow-ups

Decision 021 Stage 1 is **validated on its target FP classes** (n=1 sweep, 8
replicates/cell): both revisit-trigger conditions ("still reproduces 3c or 5") came
back negative, and cost triggers did not fire.

1. Triage the bwrap `/tmp`-CWD consensus finding (real-looking; the evidence is its
   *persistence* — 4-family agreement in both the diff-only baseline and the enriched
   re-run, surviving the context change that killed the misattribution FPs).
2. The 72 KB `self-improvement.sh` omission didn't matter *here* because the decisive
   evidence sat in the sibling diff; a claim refuted only by unchanged code in a
   >64 KB file would still FP. The function-body fallback (021's designated large-file
   path) remains unbuilt — build only if such an FP is actually observed.
3. Sonnet's D3 2/2 on np.load suggests re-running D1/D2 under Stage 1 to see whether
   the incumbent's Result-4 abstention softens with context — separate question from
   FP-kill, not started.
4. (From the 2026-07-31 security review of this branch.) The Stage-2 judge prompt
   splices untrusted model finding text without delimiters and verdicts on a
   `"YES" in upper()` check — the Jaccard figures above flow through it; harden
   before leaning further on judge-matched overlap numbers. The committed
   findings.jsonl files were scanned for credential shapes (none found).
