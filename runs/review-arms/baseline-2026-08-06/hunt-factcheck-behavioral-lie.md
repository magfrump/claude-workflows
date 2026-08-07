# Hunt: a mfc commit that fires #4's fact-check-gate (a behavioral contract lie)

**Why**: #4 (first-red short-circuit) only fires when **fact-check** confirms a *behavioral* 🔴.
On the canon reviewed states that never happened (0/8 — fact-check found only comment/doc drift →
🟡 under T). To measure #4 empirically we need a commit whose defect is a **comment/doc/contract
that actively misdescribes live behavior, with a dependent consumer** (→ Incorrect-high, behavioral
subject → 🔴). Scanned all 225 commits reachable from HEAD via a 3-way subsystem fan-out.

## Result: rare. 2 candidates cleared the bar (both historical); HEAD is clean.

### Candidate A (best fact-check trigger) — `throttle.ts` "last call always delivered"
- **Exhibiting commit**: `e59c7ed` (feat: SSE streaming partial-JSON previews, #94) — introduced the
  utility + the false comment; the comment persists **unchanged at HEAD**.
- **Location**: `app/lib/utils/throttle.ts:2` — `* The last call is always delivered (trailing edge).`
- **Contradiction**: `throttle.ts:19-25` schedules the trailing timer only when none is set and
  captures the **first** blocked call's args; later calls in the window are silently dropped. The
  actual *last* call is never delivered.
- **Consumer**: `useFormalizationPipeline.ts:66-68` (+ `:96,:188`, `useDecomposition.ts:130`,
  `useArtifactGeneration.ts:73`) — `throttle(accumulated => setSemiformal(accumulated), 50)` for
  live streaming previews.
- **Why it's the best fact-check trigger**: classic *comment-directly-above-contradicting-code* —
  the fact-check sweet spot. A fact-check pass should rate it Incorrect(high).
- **Caveat (why it may still land 🟡 not 🔴)**: current callers pass **cumulative** snapshots and do
  a final authoritative `setSemiformal(proof)` + `onToken.cancel()` at stream end, so the end-state
  is masked — the live consequence is a laggy/regressed preview mid-stream, not a persistent wrong
  result. An orchestrator applying T could reasonably read the subject as behavioral (utility
  contract consumers rely on → 🔴) OR as comment-drift with muted impact (→ 🟡). **This ambiguity is
  the point**: even the best candidate in 225 commits is a judgment call at the T boundary.

### Candidate B (most clearly feature-breaking, but the lie is a prompt string) — evidence-integrate `counterexamples` vs `scenarios`
- **Exhibiting commit**: `c2f5e8c` (smallest pre-fix state); introduced by `6cf4b0d`, **fixed by
  `2493d2a`** (fix: rename counterexamples→scenarios in evidence-integrate schema docs). Any commit
  in `6cf4b0d..2493d2a^` exhibits it.
- **Location**: `app/api/evidence-integrate/route.ts:46-58` — schema doc says the artifact field is
  `counterexamples[i].scenario`.
- **Contradiction**: the real artifact type is `scenarios` (`app/lib/types/artifacts.ts:118`; the
  counterexamples route emits `"scenarios"`). The key `counterexamples` does not exist on the data.
- **Consumer**: `integrateValidation.ts:51` → `resolveFieldPath(artifact, fieldPath)` returns null
  for the non-existent leading key → every LLM-proposed `counterexamples[i].*` proposal is dropped →
  `applyProposals` never edits. **Evidence integration for counterexample artifacts silently
  no-ops** — unmasked, feature-breaking. The fix-commit message says so outright.
- **Why it's not the cleaner #4 trigger**: the false claim lives in a **prompt/schema string
  constant**, and the mismatch is **cross-file** (prompt vs artifacts.ts vs the emitting route). That
  is more naturally an **api-consistency critic** catch than a fact-check catch — so it might fire
  the *critic-stage* path (no panel-skip savings) rather than the fact-check gate. Strong defect,
  weaker fit for the #4 *fact-check* gate specifically.

### Near-misses excluded (all 3 agents) — the instructive part
- Lean silent mock-pass, evidence-score neutral-0.5 mock: real bugs but the **comment accurately
  describes the code** — honest-but-bad-design, not a lie. (Defect is a missing *consumer* check.)
- `sanitizeVerificationStatus` "strip verifying" omits "unavailable": type-protected (`"none"|"valid"|"invalid"`
  return) + intended behavior + tested → cosmetic.
- corpus `manifest.ts` fail-loud header + `mirrorFs` "never swallowed" + `opfsAdapter` "fresh
  ArrayBuffer view" + `CorpusError` kind `browser-storage-cleared`: genuine contract drift but **no
  live consumer** (latent until S4/S5) or no dependent switch → cosmetic/latent, not behavioral-now.

## Bearing on the #4 measurement
- **The scarcity IS the result.** One clean fact-check trigger (throttle) and one cross-file/prompt
  case (evidence-integrate) in 225 commits, both already fixed, HEAD clean. In a maintained repo the
  condition that fires #4's high-value path is rare — matching the canon's 0/8. #4 stays a
  loop-safety option, not a reliable token reducer.
- **If we run the empirical #4 fire**: use **Candidate A (`throttle.ts`)** as the fact-check trigger.
  Set up a `--loop-pass` review of a diff touching `throttle.ts` at/after `e59c7ed`; if fact-check
  returns Incorrect-high-behavioral (🔴), #4 skips the critic panel — measure the skipped tokens;
  then fix (make it true trailing-edge) and re-review clean. **Risk**: if the orchestrator classifies
  the throttle claim as comment/doc (🟡, plausible given the masked impact), #4 does **not** fire —
  which would be a *third* independent confirmation that the trigger is hard to hit, not a failure.
