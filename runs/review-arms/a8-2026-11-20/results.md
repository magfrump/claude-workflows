# A8 settling runs: csp self-read control and corpus inline (2026-11-19/20)

Brief: `docs/working/briefs/2026-11-19-a8-settling-runs.md`. Method and deviations:
`docs/working/research-2026-11-19-a8-settling-runs.md`. Per-agent rows: `token-ledger.md`;
totals: `manifest.json`; review artifacts: `csp/`, `corpus/`.

**What A8 is.** Row A8 of `docs/reviews/code-review-rubric-2026-08-07-main.md` asks whether
inlining the shared review context into every review agent's prompt (decision 032 lever #3) is
worth its cost. The first A8 pass (`runs/review-arms/a8-2026-11-19/results.md`) and its cache
probe (`cache-probe.md` there) showed that the saving the lever was adopted for, sibling agents
reading the block from the prompt cache, is zero on the Agent-tool path. Its "Three things would
tell" named two more runs, which are these: a self-read control on the same cell, to get the net
cost of inlining, and the corpus cell, the largest block, to test the 25k-token budget.

**Setup.** Both passes use `skills/code-review/SKILL.md` as merged by d383a484 (the lever #3
correction, Q-315), at base 14d450d9. The critic and fact-check skill files are byte-identical
to the first pass's (no change under those skill dirs since 4330e303). Terminal passes (no
`--loop-pass`): k=3 fact-check, every gated critic in parallel, Stage 2.5 on routed claims, all
on opus. Passes ran one after the other. Total 2,171,680 tokens over 19 agents, under the 2.5M
stop line. The instrument is the task notification's `subagent_tokens`. For all 19 agents it
equals the transcript's last API call (input + cache creation + cache read + output), the same
check the first pass made. It measures the final context, not tokens processed over the run.

## 1. csp: self-read against the first pass's inline figures

Same cell (d86d2dc..d90d6bb), same skill texts, same prompts except delivery. Self-read prompts
are the first pass's prompts with the `## The diff` and `## Enclosing-file context` sections
replaced by a section naming the `git diff` command and the two files to read in full. The
fact-check brief is the first pass's, verbatim.

| Slice | Self-read (today) | Inline (first pass) | Change |
|---|---|---|---|
| Fact-check, k=3 total | 335,650 (103,630 / 122,438 / 109,582) | 311,975 (100,755 / 90,196 / 121,024) | +23,675 (+7.6%) |
| 4 baseline-comparable critics | 358,744 | 352,090 | +6,654 (+1.9%) |
| — security / performance / api / architecture | 108,306 / 79,122 / 84,931 / 86,385 | 103,326 / 78,987 / 88,378 / 81,399 | +4.8% / +0.2% / −3.9% / +6.1% |
| test-strategy | 77,354 | 79,690 | −2.9% |
| **Core total (Stage 1 + Stage 2)** | **771,748** (8 agents) | **743,755** (8 agents) | **+27,993 (+3.8%)** |
| Stage 2.5 submitted claims | 126,985 (7 claims) | 108,530 (6 claims) | outside core |
| All agents | 898,733 | 852,285 | +46,448 |

- Prompt size. Each self-read agent's first call wrote 31.2k-32.6k tokens to cache, against
  32.8k-33.8k inline. The diff and the two files (about 5.0k bytes) left the prompt, replaced by
  an 837-byte read instruction, so the shared block shrank by 4,179 bytes in Stage 1 and 3,535 in
  Stage 2 (about 1.0k and 0.9k tokens; Stage 2 less, because this pass's fact-check summary is
  645 bytes longer). The preamble, intent and Stage-2 summary stay inline in both arms. Every agent
  in both arms read 18,900 cached tokens on its first call (system prompt and tools only).
- Where it went back. Self-read agents spend tool calls fetching the diff and the two files,
  so the same content reaches their context as tool results. The core came out 3.8% **higher**
  self-read. That is inside the noise of one draw: the first pass's three identical fact-check
  replicates alone spanned 90k-121k, and today's 104k-122k.
- Labels hit (canon `docs/working/canon-issue-ledger.md:92-97`, 2 red, 4 amber): **6/6**, the
  same as inline. The gold R1 (`connect-src 'self'` blocks the `fetch(data:)` export in
  `exportGraph.ts`) was **caught**: fact-check Claim 10 Incorrect 3/3, api-consistency Breaking
  High (so 🔴), security Low, architecture Coupling, test-strategy G7. R2 (Edge runtime) Claim
  11 3/3; A1 (CSP only on the response, dead `x-nonce`) Claims 3 and 13, security Medium,
  api Breaking Medium, architecture Coupling; A2 (Tailwind) Claim 7 3/3; A3 (`await headers()`
  comment) Claims 2 and 20 3/3, performance Medium; A4 (directive list untested) test G1.
  Beyond the labels, security re-found canon N1 (`purpose: prefetch` HTML with no CSP).
- One difference from the first pass, not about delivery: no replicate ran `next build` this
  time (the first pass's r3 did). r2 ran vitest (221/221) and eslint; Stage 2.5 executed 5 of
  its 8 entries in 4 probe runs (Claims 28 and 29 on `next dev`). Rubric: `csp/code-review-rubric-2026-11-19-csp.md`, 2 red, 7 amber.

## 2. corpus: inline as the skill says

Range dc6dfb0..2dc403e, scope `-- app/` (15 files, +1166/−33), the baseline's scope.

**The 25k budget, and the mode the ladder gave.** Part 5 assembled as the skill defines it (the
diff plus the post-change contents of the touched files) is 123,423 bytes, **≈30.9k tokens at
bytes/4, over the 25k budget**. So the skill's ladder degrades to **inline-diff-only**: the
shared block is preamble + partial-scope label + intent + the 53,682-byte diff, 57,328 bytes
(≈14.3k tokens, 57% of budget) in Stage 1 and 61,902 bytes (≈15.5k, 62%) in Stage 2 with the
fact-check summary. This is the first cell measured above the budget. The skill's calibration
note ("the largest measured cell was ~17.4k tokens, so every measured cell inlines with ~45%
headroom", `SKILL.md:343-345`) counts diff + fact-check report, not diff + enclosing files,
which is what the budget is measured on, so on its own measure corpus does not inline. The
ladder worked as written: no cliff, and the run below still found the cell's red.

| Slice | Inline-diff-only (today, k=3) | Baseline 2026-08-06 (self-read, k=1) | Change |
|---|---|---|---|
| Fact-check, total | 435,604 (149,652 / 146,785 / 139,167) | 93,966 | ×4.64 |
| Fact-check, per replicate (mean) | 145,201 | 93,966 | +54.5% |
| 6 critics | 698,163 | 521,600 | +33.9% |
| — security / performance / api / architecture | 123,116 / 104,995 / 135,606 / 119,906 | 94,922 / 82,991 / 91,492 / 87,879 | +29.7% / +26.5% / +48.2% / +36.4% |
| — tech-debt-triage / test-strategy | 106,520 / 108,020 | 76,227 / 88,089 | +39.7% / +22.6% |
| **Core total** | **1,133,767** (9 agents) | **615,566** (7 agents) | **×1.84** |
| Core at k=1-equivalent (mean replicate + 6 critics) | 843,364 | 615,566 | +37.0% |
| Stage 2.5 submitted claims | 139,180 (7 claims) | — | outside core |
| All agents | 1,272,947 (10) | — | |

How much of the growth the block can account for. The block is ≈14.3k tokens per fact-check
agent and ≈15.5k per critic: 135,849 tokens over the 9 core agents, **≈12.0% of the core**
(≈13.1% as delivered, since the Read tool's output is line-numbered). Each critic grew
19.9k-44.1k over August, so the block is at most 35% to 78% of each critic's growth. "At most", because a self-reading agent must also pull the diff into its
context to review it. The baseline's critics did exactly that, so most of the block is bytes
they also carried. The csp control (§1) found no net cost from inlining on a small cell; corpus
had no self-read arm, so its net cannot be read off this pass. One delivery detail differs from
pasting: each agent Read the byte-identical block file as its first step (research doc, design
choices). The context holds the same content either way, plus the Read calls (two for each
Stage-2 critic, whose first Read stopped at line 1068) and the Read tool's line numbers, about
1.4k tokens per agent.

**Labels hit** against corpus's canon labels (`docs/working/canon-issue-ledger.md:112-115`, all
amber, plus the D3 red at `:161`):

| Label | Today | Baseline |
|---|---|---|
| cor-A1 `customTypeIds` naming vs `customArtifactTypeIds` | **partial**: api F4 flags the field's type (`string` vs `CustomArtifactTypeId`), not its name | miss (no naming finding in the baseline reports; the canon ledger's E4 column calls it enumeration class) |
| cor-A2 `state/` blob path bypasses the `paths.ts` choke point | **HIT**, 🟡 A4 (fact-check Claim 6 3/3, api F10, architecture Minor, tech-debt TD7) | miss on this reading: the baseline architecture critic called `paths.ts` "the sole producer of corpus paths" (`baseline-2026-08-06/corpus/critic-architecture.md:81`); baseline results used a different A1-A4 reading |
| cor-A3 stale comments (`layout.ts`, `workspaceStore:44-46`) | **HIT**, 🟡 A5 (Claims 7, 8, 3/3) | HIT |
| cor-A4 manifest docstring drift (silent defaults; phantom `browser-storage-cleared`) | **HIT**, 🟡 A2 (Claim 3 executed 3/3; Claim 4 I/MA/MA; api F1, F11) | HIT |
| D3 rehydration seam re-fires `migrateFromV2` over corpus state | **HIT**, 🔴 R1 (architecture Structural; security, api F9, TD4, test G12) | HIT (architecture Structural) |

So 3 of 4 canon ambers hit and 1 partial, and the red hit at 🔴, against the baseline's own
reading of "all 4 + the seam". Under the baseline's own A1-A4 reading (slug collision, bare
Error vs CorpusError, stale docstrings, manifest silent drop), all four hit again: security Low
#5, api F2, Claims 7/8, Claim 3. The baseline's extra performance-High (debounce dropped on the
corpus path) is today's 🟡 A6. The pass also hit these canon rows:
N11 (flag enableable in production, security Medium), N12 (write rejections unhandled), N13
(failed hydrate then defaults written over the file), N18 (`close()` masks quota), N23 (slug
collisions), N24 (`manifestVersion` unchecked), D4 (false "fresh ArrayBuffer" comment) and D5
(unordered writes); C3 (`process.env?.` inlining) is flagged Unverifiable. The baseline also had
N23 (its security Medium), D4 (its fact-check Claim 8) and D5 (its performance report's
last-writer-wins race); I did not adjudicate the others against the baseline's reports. As on csp, k=3, the
newer skill texts and Stage 2.5 all changed since August, so none of this is evidence about
lever #3 by itself. Rubric: `corpus/code-review-rubric-2026-11-19-corpus.md`, 1 red, 9 amber.

## 3. A8

**Holds as a cost-neutral default; fails as the skill once worded it; the budget's trade still
cannot be told.** On csp the control arm gives the net cost the first pass lacked: dropping the
inline block saved nothing. Self-read cost 3.8% more over the 8 core agents (inside one-draw
noise), because agents fetch the same diff and files with tools. Recall did not move (6/6 both
ways, gold R1 caught both ways). So on a small diff inlining is neither a saving nor a cost:
"free" holds on net tokens, while the cache saving it was adopted for stays at zero (first pass,
cache probe). On corpus the ladder applied as written. The full material (≈30.9k) was over it, the
ladder fell back to diff-only (≈14-15k per agent, 12% of core), and the pass still caught the
cell's structural red and 3 of 4 ambers. What still cannot be told is whether the budget is set
right. No run has inlined a block between ~15k and 25k, or compared diff-only with full inline
or self-read on a large cell, so the budget's context-versus-recall trade is unmeasured. Its
calibration note in the skill describes a different quantity from the one it gates (§2). The
cheapest next evidence, if anyone wants it, is a self-read arm on corpus. It would tell whether
diff-only inlining on a large cell costs anything net, as csp says it does not on a small one.

## 4. Run notes

- No `tokens` map is empty; every agent is a row in `token-ledger.md` and in `manifest.json`.
- Three csp critic dispatches were refused by a harness working-directory check and re-sent
  about a minute later. Self-read agents share no prompt cache, so the stagger cannot move
  their figures.
- The merged fact-check reports are cluster-level. Replicates split claims more finely (corpus:
  33, 35 and 22 claims), and the merge keeps a row for every assertion on csp (24, plus
  Stage 2.5's 8 entries) and for all but five on corpus (25, plus Stage 2.5's 7). The five single-replicate Verified assertions without a row are
  r1 Claims 14, 22, 23 and r2 Claims 21, 23; every non-Verified verdict has one. Per-replicate reports are beside them.
- Stage 2.5 refuted one endorsement on csp: the performance critic's "constant work per
  request" (Claim 27b, executed: cost grows with request header count). It went in as 🟢 C6.
- Reviewing this write-up cost 768,441 tokens outside the measured passes: a k=3 fact-check
  (212,561 / 222,883 / 185,251), then a k=1 pass over its corrections (147,746), plus two
  lite fix-drift checks with no findings. Loop rubric:
  `docs/reviews/code-review-rubric-2026-11-19-measure-a8-settling-runs.md`.
- No agent process was left running; the two scratch worktrees of the benchmark repo are removed
  after this write-up (research doc).
