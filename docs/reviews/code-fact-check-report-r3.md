# Code Fact-Check Report

**Repository:** `/workspace` (claude-workflows)
**Commit:** 90de392
**Scope:** branch diff `main...feat/crb-direction1-harness` — 7 files, +1209/-0
**Checked:** 2026-08-18
**Total claims checked:** 44
**Summary:** 31 verified, 10 mostly accurate, 0 stale, 2 incorrect, 1 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) was read before
checking; its `## Patterns` section was empty, so no prior pattern applied. One new
entry was appended after this run (see Claim 8).

**Environment note for the orchestrator:** partway through this pass the branch ref
`refs/heads/feat/crb-direction1-harness` disappeared from the repository — `git rev-parse
HEAD` now reports an unborn HEAD, `git cat-file -t 90de392` reports "Not a valid object
name", and `git status` shows all files as staged additions. The seven files' **working-tree
contents are intact and are what this report checked**; the two claims that required
git-history resolution (Claims 12 and 13) were both verified *before* the ref vanished, on
a live `d9234c9` / `main` / `feat/critic-evidence-discipline`. No git-write command was
issued from this session. Flagged as an escalation, not a review finding.

---

## Claim 1: "steps 1 and 3 below are built and dry-run green"

**Location:** `docs/working/crb-arm-plan.md:193-201`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The inserted note says:

```markdown
// docs/working/crb-arm-plan.md:193-194
> **2026-08-18: steps 1 and 3 below are built and dry-run green.** See
> `docs/working/crb-direction1-setup.md` for the four-stage runbook
```

The same note then enumerates four stages, and the commit message describes "Four stages,
all dry-run verified at $0". All four stage scripts exist in the diff
(`scripts/crb-materialize.py`, `runs/review-arms/crb-pipeline/run-host.sh`,
`scripts/crb-pipeline-to-benchmark.py`, `scripts/crb-subset-leaderboard.py`) — so the
"steps 1 and 3" scoping is narrower than what shipped. Also, stage 2 is explicitly *not*
dry-run-green in the sense the note implies: the setup doc lists skill registration under
"Not verified" (`docs/working/crb-direction1-setup.md:197-199`). The count-of-stages
mismatch is the imprecision; the substance is right.

The cost figures in the note (`~$1.5` pilot, `~$13–22` for 50) match
`docs/working/crb-direction1-setup.md:159` verbatim.

**Evidence:** `docs/working/crb-arm-plan.md:193-201`, `docs/working/crb-direction1-setup.md:13-20`, `docs/working/crb-direction1-setup.md:159`, `docs/working/crb-direction1-setup.md:197-199`

---

## Claim 2: "`scripts/crb-materialize.py --list` # 50 PRs, 173 goldens"

**Location:** `docs/working/crb-direction1-setup.md:25`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`--list` prints exactly this footer:

```python
# scripts/crb-materialize.py:239
print(f"\n{len(prs)} PRs, {sum(len(e['golden_comments']) for _, _, e, _ in prs)} goldens")
```

Computed directly from `external/code-review-benchmark/offline/results/benchmark_data.json`:
50 entries, `sum(len(e['golden_comments']))` = 173 (paraphrased — no quote available
because the claim is a computed aggregate over a 50-entry JSON data file, not a code
snippet). `load_prs()` emits one row per entry and skips only entries with no `repo_name`
on any review; zero entries fall in that bucket, so the printed count is 50.

**Evidence:** `scripts/crb-materialize.py:77-90`, `scripts/crb-materialize.py:234-240`, `external/code-review-benchmark/offline/results/benchmark_data.json`

---

## Claim 3: "`scripts/crb-materialize.py --all` # all 50 (~6-7 GB)"

**Location:** `docs/working/crb-direction1-setup.md:27`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** for-author

This figure is a defensible extrapolation from the pilot's own measured `clone_mb` values
(190 + 33 + 125 + 127 + 195 = 670 MB over 5 clones ⇒ ~134 MB/clone ⇒ ~6.7 GB for 50), which
are recorded in the manifest (paraphrased — no quote available because the figures are
spread across five JSON records in `runs/review-arms/crb/instances.json` and read more
clearly summed than quoted). It **contradicts the sibling claim in the script itself**:

```python
# scripts/crb-materialize.py:26
  scripts/crb-materialize.py --all                      # all 50 (~15-25GB)
```

Both cannot be right. The doc's number is the one supported by measured data; the script's
is not. See Claim 21.

**Evidence:** `docs/working/crb-direction1-setup.md:27`, `scripts/crb-materialize.py:26`, `runs/review-arms/crb/instances.json`

---

## Claim 4: "Same contamination discipline as `scripts/prep-cc-review-clones.sh` for the canon instances."

**Location:** `docs/working/crb-direction1-setup.md:36` (mirrored at `scripts/crb-materialize.py:15-16`)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The referenced script exists and does structurally the same job — same two branches, same
ref/remote/reflog scrub, same guard (a):

```bash
# scripts/prep-cc-review-clones.sh:6-11
#   - branch `review` checked out at the instance's reviewed head commit
#   - branch `main` pinned at the instance's context base (so "diff vs main"
#     reproduces the canon range)
#   - NO other refs, NO origin remote, and descendant objects (the later fix
#     commits — the answer key) pruned from the object store, so an agentic
#     reviewer cannot read the future via `git log --all` / `git show`.
```

```bash
# scripts/prep-cc-review-clones.sh:46-48
  # guard (a): nothing reachable outside the reviewed head's ancestry
  local stray; stray=$(git -C "$dst" rev-list --all --not "$head" | wc -l)
  [ "$stray" -eq 0 ] || { echo "$id: $stray stray commit(s) survived the scrub" >&2; exit 1; }
```

Guard (b) differs by design — the canon script checks for self-referencing
`docs/reviews/` files (`prep-cc-review-clones.sh:49-58`), the new script checks range
non-emptiness and blob presence — but the diff's wording ("same contamination
discipline", "does the same job") is accurate at the level asserted.

**Evidence:** `scripts/prep-cc-review-clones.sh:1-59`, `scripts/crb-materialize.py:10-16`, `scripts/crb-materialize.py:174-196`

---

## Claim 5: "33 goldens over 5 PRs" and the per-instance pilot table

**Location:** `docs/working/crb-direction1-setup.md:40-48`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Every cell of the doc's table matches the manifest record for that slug. Example (the
row `cal_com-PR11059 | 9 | 140 | 40 files +375/-119 | 190 MB`):

```json
// runs/review-arms/crb/instances.json — cal_com-PR11059
 "clone_mb": 190,
 "commits": 140,
 "deletions": 119,
 "files_changed": 40,
 "insertions": 375,
 "n_goldens": 9,
```

`sum(n_goldens)` over the five records is 33, matching both the doc and the commit
message's "33 goldens" (paraphrased — no quote available because the sum spans five JSON
records). The other four rows check out identically.

**Evidence:** `docs/working/crb-direction1-setup.md:40-48`, `runs/review-arms/crb/instances.json`

---

## Claim 6: "the injector against a real E8 rubric fixture (16 findings parsed from `mfc-csp`, 9 with `--sections fix address`)"

**Location:** `docs/working/crb-direction1-setup.md:190-191`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

I re-ran the injector's parser against the named fixture. `md_tables` yields four tables
from `runs/review-arms/e8-evidence-pipeline/mfc-csp/code-review-rubric.md`: `🔴 Must Fix`
(1 row), `🟡 Must Address` (8), `🟢 Consider` (7), `✅ Confirmed Good` (5).
`comments_from_rubric(md)` returns 16 comments; `comments_from_rubric(md, ["Must Fix",
"Must Address"])` returns 9 (paraphrased — no quote available because the result is the
observed return value of running the module's own functions, not a source line). This also
independently confirms the `1 red + 8 amber + 7 green` breakdown asserted at
`scripts/crb-pipeline-to-benchmark.py:178-179`.

**Evidence:** `scripts/crb-pipeline-to-benchmark.py:67-129`, `runs/review-arms/e8-evidence-pipeline/mfc-csp/code-review-rubric.md`

---

## Claim 7: "`run-host.sh` passes `bash -n` and its `DRY_RUN=1` path builds and validates the payload (25 skills, `code-review` present)"

**Location:** `docs/working/crb-direction1-setup.md:194-195`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`bash -n runs/review-arms/crb-pipeline/run-host.sh` exits 0 (paraphrased — no quote
available because the claim is about a command's exit status, not a snippet).
`ls skills/*/SKILL.md | wc -l` returns 25, matching the payload's skill count as the script
computes it:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:88-90
echo "Payload:  $PAYLOAD_REF @ ${PAYLOAD_SHA:0:8} ($(find "$PAYLOAD_SRC/skills" -name SKILL.md | wc -l) skills)"
[ -f "$PAYLOAD_SRC/skills/code-review/SKILL.md" ] || {
  echo "payload has no skills/code-review/SKILL.md — wrong ref?" >&2; exit 1; }
```

The DRY_RUN early-exit sits after the payload build and validation, so the claim's ordering
is right:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:92-95
if [ -n "$DRY_RUN" ]; then
  echo "DRY_RUN=1 — payload built and verified, no container started, \$0 spent."
  exit 0
fi
```

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:85-95`

---

## Claim 8: "on the same 2 PRs, different tools' checked-in rows show `total_golden` 11 vs 13 (goldens were revised between tool runs)"

**Location:** `docs/working/crb-direction1-setup.md:172-176`
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

The *phenomenon* is real but both numbers are wrong, and the scale is understated by an
order of magnitude. Scanning
`external/code-review-benchmark/offline/results/anthropic_claude-opus-4-5-20251101/evaluations.json`
for PRs where non-skipped tool rows disagree on `total_golden`: **24 of 50 PRs** disagree,
not 2. The values that actually occur are 1 through 9 — e.g. `pull/11059` shows `[5, 9]`,
`pull/4` shows `[6, 8]`, `pull/36880` shows `[3, 5]`. The maximum golden count for *any*
PR in `benchmark_data.json` is 9, so `11` and `13` do not occur anywhere in the dataset
(paraphrased — no quote available because the finding is an aggregate over a 50-entry
evaluations file and its per-tool result objects, with no single line to quote). The same
24-of-50 pattern holds identically in the `anthropic_claude-sonnet-4-5-20250929` and
`openai_gpt-5.2` evaluations files.

This matters for measurement: the doc frames the denominator non-uniformity as a two-PR
curiosity, when it affects the recall denominator on nearly half the benchmark — including
4 of the 5 pilot PRs (`pull/11059`, `pull/4`, `pull/5`, `pull/36880`). The mitigation the
doc names is genuinely in place — `crb-subset-leaderboard.py` does surface each tool's
`gold`:

```python
# scripts/crb-subset-leaderboard.py:63-64
            a["cand"] += res.get("total_candidates", 0)
            a["gold"] += res.get("total_golden", 0)
```

Logged to `docs/reviews/hallucination-patterns.md`: the specific figures `11` and `13` are
asserted as read out of a named data file and appear nowhere in it.

**Evidence:** `docs/working/crb-direction1-setup.md:172-176`, `scripts/crb-subset-leaderboard.py:54-66`, `external/code-review-benchmark/offline/results/anthropic_claude-opus-4-5-20251101/evaluations.json`

---

## Claim 9: "`offline/analysis/score_profiles.py` implements Strict/Core/All profiles by golden category"

**Location:** `docs/working/crb-direction1-setup.md:180-182`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

The referenced file exists at that path alongside `benchmark_dashboard.py` /
`benchmark_dashboard.json` / `benchmark_dashboard.html` (paraphrased — no quote available
because this is a directory-listing claim, not a snippet). I did not read the profile
implementations in depth, so the "by golden category" mechanism is asserted at medium
confidence on the file's existence and name alone.

**Evidence:** `external/code-review-benchmark/offline/analysis/score_profiles.py`

---

## Claim 10: "docker cannot run inside a session; same constraint as E5/E7/cc-isolated."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:3-4`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

The cross-reference half is checkable and true: `runs/review-arms/e5-cc-builtin/run-host.sh`
and `runs/review-arms/e7-fable-3x/run-host.sh` both carry a run-from-the-host banner
(paraphrased — no quote available because the claim is that a matching directive exists in
two sibling files, established by a `rg -l` sweep returning exactly those two plus this
file). The underlying environmental fact (no docker inside a sandboxed session) is not
statically checkable from the repo; medium confidence reflects that half.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:3-4`, `runs/review-arms/e5-cc-builtin/run-host.sh`, `runs/review-arms/e7-fable-3x/run-host.sh`

---

## Claim 11: "the pipeline, not Claude Code's built-in /code-review (that arm is E5/E7, which deliberately run --bare so the payload does NOT load)"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:14-17`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

This run mounts the payload as `~/.claude` and does *not* pass `--bare`:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:155-166
  docker run --rm -u node -w /repo \
    -e ANTHROPIC_API_KEY \
    -v "$clone":/repo \
    -v "$INST_HOME":/home/node/.claude \
    -v cc-review-npm-cache:/home/node/.npm \
    node:22 \
    npx -y @anthropic-ai/claude-code@"$CC_VERSION" \
      -p "/code-review main" \
      --model "$MODEL" \
      --output-format stream-json --verbose \
      --dangerously-skip-permissions \
      --max-budget-usd "$BUDGET" \
```

The `--bare` characterization of E5/E7 is corroborated by the project memory note "CC
--bare blocks all subscription auth" and by those arms' own run scripts (paraphrased — no
quote available because the assertion is about the *absence* of `--bare` here and its
presence in sibling arms, established by grep).

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:9-17`, `runs/review-arms/crb-pipeline/run-host.sh:155-166`

---

## Claim 12: "87% recall / 0 FPs on the canon, `docs/working/e8-results-2026-08-18.md`" and "MERGED into main at d9234c9"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:19-25`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The results doc's headline row carries exactly those figures:

```markdown
// docs/working/e8-results-2026-08-18.md:18
| **E8 evidence-discipline pipeline** | 54 | 47 | **87%** | **0** | **0 clean** (1 over-broad, scoped-true) |
```

`git log --oneline -1 d9234c9` resolves to `merge: E8 evidence-discipline pipeline +
ledger updates into main` (paraphrased — no quote available because this is git-history
output, not a file). `git diff main feat/critic-evidence-discipline -- skills workflows
CLAUDE.md` produced empty output with exit 0, confirming "main IS the E8 payload"
(paraphrased — same reason). Both git checks were run before the branch ref vanished (see
the header note).

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:19-25`, `docs/working/e8-results-2026-08-18.md:16-18`

---

## Claim 13: "`PAYLOAD_REF="${PAYLOAD_REF:-main}"   # == feat/critic-evidence-discipline (merged, see header)`"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:56`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Same evidence as Claim 12: the payload-scoped diff between the two refs was empty at check
time, so the two refs are interchangeable for the five paths the payload actually contains
(paraphrased — no quote available because the claim is about git-diff output being empty).
The header's own hedge is appropriate:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:24-25
# Pin PAYLOAD_REF=<sha> if the two ever diverge again; run-meta.json records the
# commit that actually ran either way.
```

That hedge is honoured — `PAYLOAD_SHA` is captured and written into `run-meta.json`
(`run-host.sh:87`, `run-host.sh:230-231`).

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:56`, `runs/review-arms/crb-pipeline/run-host.sh:87`, `runs/review-arms/crb-pipeline/run-host.sh:230-231`

---

## Claim 14: "E8's canon sweep ran the orchestrator on Fable 5" and "MODEL=opus is ~1/2 the per-token price"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:57-60`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

First half:

```markdown
// docs/working/e8-results-2026-08-18.md:7
provenance-ruled rubric synthesis. Orchestrated locally (fable-5), k=2
```

Second half, using the repo's own two price statements — Fable 5 at
`docs/working/e8-results-2026-08-18.md:110-111` ("Fable 5 list prices: $10/M input, $50/M
output") and opus-4-5 at `docs/working/crb-direction1-setup.md:159` ("$5/$25 per MTok") —
gives exactly a 2× ratio on both input and output. `runs/review-arms/e7-fable-3x/run-host.sh:10`
independently states "Fable is 2x price". Medium confidence because `MODEL=opus` is a CLI
alias whose resolution to `claude-opus-4-5` cannot be checked statically.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:57-60`, `docs/working/e8-results-2026-08-18.md:7`, `docs/working/e8-results-2026-08-18.md:110-111`, `docs/working/crb-direction1-setup.md:159`

---

## Claim 15: "E8 was orchestrated stage-by-stage by a human-driven session (k=2 fact-check, explicit critic list per instance)"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:28-31`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

```markdown
// docs/working/e8-results-2026-08-18.md:96-97
- **Config deltas vs the historical pipeline**: k=2 not k=3; orchestrator on
  fable-5; the reviewed states are the dirty commits (same as E1/E4/E7 ranges),
```

Combined with line 7's "Orchestrated locally (fable-5), k=2", the k=2 and
human-orchestration halves are both supported. The per-instance critic list is visible in
the E8 run tree, where each instance directory carries a different set of critic reports
(paraphrased — no quote available because the claim is about which files exist per
directory across eight instance dirs under `runs/review-arms/e8-evidence-pipeline/`, not a
snippet).

**Evidence:** `docs/working/e8-results-2026-08-18.md:7`, `docs/working/e8-results-2026-08-18.md:96-97`, `runs/review-arms/e8-evidence-pipeline/mfc-csp/`

---

## Claim 16: "hooks/ and scripts/ are NOT in the payload"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:32-33`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The payload is built by an explicit path allowlist, and neither directory is on it:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:85-86
git -C "$ROOT" archive "$PAYLOAD_REF" skills workflows guides patterns CLAUDE.md \
  | tar -x -C "$PAYLOAD_SRC"
```

`git archive` with explicit pathspecs emits only those five paths, so `hooks/` and
`scripts/` cannot appear in `$PAYLOAD_SRC`, which is the only source for both `$PF_HOME`
and each `$INST_HOME` (`run-host.sh:110`, `run-host.sh:150`).

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:85-86`, `runs/review-arms/crb-pipeline/run-host.sh:110`, `runs/review-arms/crb-pipeline/run-host.sh:150`

---

## Claim 17: "`git archive` (not a bind mount of $ROOT) so a running review cannot edit the skills that are reviewing it"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:79-82`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Two layers of indirection separate the container from `$ROOT`. First, the archive extracts
to a temp dir (`run-host.sh:83-86`, quoted in Claim 16). Second, each container gets its
own *copy* of that temp dir, and `$ROOT` is never passed to `docker run -v`:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:150
  INST_HOME=$(mktemp -d); cp -r "$PAYLOAD_SRC/." "$INST_HOME/"; chmod -R u+w "$INST_HOME"
```

The only host paths mounted are `$clone`, `$INST_HOME`, and the npm cache volume
(`run-host.sh:157-159`). Writes inside the container therefore reach `$INST_HOME`, which is
`rm -rf`'d at `run-host.sh:170`, and never `$PAYLOAD_SRC` or `$ROOT`.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:79-90`, `runs/review-arms/crb-pipeline/run-host.sh:150`, `runs/review-arms/crb-pipeline/run-host.sh:155-170`

---

## Claim 18: "Docker creates a fresh named volume root-owned, but the review container runs as uid 1000 (-u node)"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:98-99`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

The mitigation is implemented as described — an unprivileged-flag-free `docker run` that
chowns the volume before any `-u node` container touches it:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:100-101
docker run --rm -v cc-review-npm-cache:/home/node/.npm node:22 \
  chown -R node:node /home/node/.npm
```

Both later containers do pass `-u node` (`run-host.sh:111`, `run-host.sh:155`). Medium
confidence on the "uid 1000" half: the `node` user's numeric uid in `node:22` is an image
property not checkable from this repo (paraphrased — no quote available because the claim
concerns an external container image's `/etc/passwd`).

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:98-101`, `runs/review-arms/crb-pipeline/run-host.sh:111`, `runs/review-arms/crb-pipeline/run-host.sh:155`

---

## Claim 19: "(a) bad credential — the CLI exits 0 with result 'Not logged in' (E7 note)"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:104-105`, guard at `:126`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The cited E7 note is real and slightly richer than the paraphrase:

```bash
# runs/review-arms/e7-fable-3x/run-host.sh:88
# result "Not logged in · Please run /login" and num_turns=0 (learned the hard
```

The imprecision is in the *detector*, not the description. The new preflight's string test
is:

```python
# runs/review-arms/crb-pipeline/run-host.sh:126
if d.get("num_turns", 0) < 1 or "log in" in r.lower():
```

`"log in" in "not logged in · please run /login".lower()` evaluates to **False** — "logged
in" is not "log in", and "/login" is one token. E7's own preflight tested both spellings:

```python
# runs/review-arms/e7-fable-3x/run-host.sh:103
sys.exit(0 if d.get("num_turns", 0) > 0 and "log in" not in r.lower() and "logged in" not in r.lower() else 1)
```

The new script dropped the `"logged in"` clause. The preflight still fails closed on the
exact E7 case because that case also reports `num_turns=0`, which `num_turns < 1` catches —
so the comment's *conclusion* (this failure mode is detected) holds, but the specific
string it names is not what the string test matches. Tighten by restoring the `"logged in"`
alternative.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:103-108`, `runs/review-arms/crb-pipeline/run-host.sh:119-132`, `runs/review-arms/e7-fable-3x/run-host.sh:88`, `runs/review-arms/e7-fable-3x/run-host.sh:103`

---

## Claim 20: "(b) payload mounted but skills not registered … Decision 022 exists because exactly this happened in cc-isolated."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:106-108`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`docs/decisions/022-claude-workflows-payload-in-cc-isolated.md` exists and records exactly
that failure:

```markdown
// docs/decisions/022-claude-workflows-payload-in-cc-isolated.md:22-25
Those are Claude Code **built-ins**. None of the repo's 25 skills were registered — not
`code-review`, not `security-reviewer`, none. The routing table in `CLAUDE.md`, the
workflow decision tree, the critic panel: absent from every cc-isolated session the repo
has ever run.
```

Decision 022 also names the exact disguise the new preflight defends against ("The built-in
skill list contains `review` and `security-review`, which read like the repo's
`code-review` and `security-reviewer`", `022:...:30-32`) — and the preflight's substring
test `"code-review" not in r` (`run-host.sh:128`) is a correct discriminator for that
specific confusion, since neither built-in name contains the hyphenated string
`code-review`.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:103-132`, `docs/decisions/022-claude-workflows-payload-in-cc-isolated.md:14-33`

---

## Claim 21: The skip-if-complete guard — "completed result exists, skipping (delete to re-run)"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:138-143`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The guard does exactly what the message and the setup doc's "Completed cells are skipped on
re-invocation (`num_turns > 0`), so a sweep resumes" (`crb-direction1-setup.md:87`) say:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:138-144
  if [ -s "$dest/result.json" ] && python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
sys.exit(0 if d.get("num_turns", 0) > 0 else 1)' "$dest/result.json" 2>/dev/null; then
    echo "=== $id — completed result exists, skipping (delete to re-run)"
    continue
  fi
```

`result.json` is only written when a `type: "result"` event was found in the transcript
(`run-host.sh:187-190`), so a crashed instance leaves no `result.json` and is correctly
re-run.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:138-144`, `runs/review-arms/crb-pipeline/run-host.sh:186-191`

---

## Claim 22: "Fresh writable payload copy per instance: … one instance's state must not leak into the next (nor back into the payload source)"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:146-148`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Each loop iteration mints a new temp dir from `$PAYLOAD_SRC` and destroys it after the
container exits:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:150
  INST_HOME=$(mktemp -d); cp -r "$PAYLOAD_SRC/." "$INST_HOME/"; chmod -R u+w "$INST_HOME"
```

```bash
# runs/review-arms/crb-pipeline/run-host.sh:170
  rm -rf "$INST_HOME"
```

`$PAYLOAD_SRC` is only ever a `cp -r` *source*, never a mount target, so the no-leak-back
half holds too. The same pattern is used for the preflight home (`run-host.sh:110`,
`run-host.sh:117`).

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:110`, `runs/review-arms/crb-pipeline/run-host.sh:117`, `runs/review-arms/crb-pipeline/run-host.sh:146-170`

---

## Claim 23: "Artifacts are harvested and the tree reset below, so re-runs start from the same state."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:150-153`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The harvest-then-reset ordering is correct — the copy loop runs before the reset:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:193-201
  mkdir -p "$dest/artifacts"
  (cd "$clone" && git status --porcelain --untracked-files=all) \
    | awk '{print $2}' | grep -E '\.(md|json)$' \
    | while read -r f; do
        mkdir -p "$dest/artifacts/$(dirname "$f")"
        cp "$clone/$f" "$dest/artifacts/$f" 2>/dev/null || true
      done
  git -C "$clone" checkout -- . 2>/dev/null || true
  git -C "$clone" clean -qfd 2>/dev/null || true
```

Two gaps in "the same state", both from what `clean -qfd` does not do:

1. **`-d` without `-x` leaves ignored files.** `git clean -fd` removes untracked
   *non-ignored* files and directories only. Anything the review writes that matches the
   clone's own `.gitignore` (build output, `node_modules/`, tool caches — realistic in
   `cal.com`/`grafana` trees) survives into the next run.
2. **Ignored *and* the harvest misses them too**, since `git status --porcelain
   --untracked-files=all` also excludes ignored paths — so such files are neither collected
   nor cleaned.

Neither breaks the current design (re-runs are gated by Claim 21's skip guard, and
`--force` is not wired), but "the same state" is stronger than what the two commands
guarantee. `git clean -qfdx` would make the comment literally true.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:150-153`, `runs/review-arms/crb-pipeline/run-host.sh:193-201`

---

## Claim 24: "`CC_VERSION="${CC_VERSION:-2.1.232}"   # pin for reproducibility`"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:55`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

The pin matches the two prior arms it is meant to be comparable with:

```bash
# runs/review-arms/e5-cc-builtin/run-host.sh:23
CC_VERSION="2.1.232"   # pin for reproducibility; bump deliberately
```

```bash
# runs/review-arms/e7-fable-3x/run-host.sh:46
CC_VERSION="2.1.232"   # pin for reproducibility; bump deliberately
```

Both sibling arms have *run* at that version, so the version exists on npm. Medium
confidence only because npm availability cannot be re-confirmed offline.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:55`, `runs/review-arms/e5-cc-builtin/run-host.sh:23`, `runs/review-arms/e7-fable-3x/run-host.sh:46`

---

## Claim 25: `runs/review-arms/crb/instances.json` field names match what `crb-materialize.py` writes

**Location:** `runs/review-arms/crb/instances.json:1-82`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The manifest's per-slug key set is exactly the writer's return dict:

```python
# scripts/crb-materialize.py:210-216
    return {
        "url": url, "source_repo": entry["source_repo"], "pr_title": entry["pr_title"],
        "fork": fork, "fork_url": remote, "head": head, "base": base,
        "commits": n_commits, "n_goldens": len(entry["golden_comments"]),
        "files_changed": files, "insertions": ins, "deletions": dels,
        "clone_mb": mb, "depth": depth,
    }
```

The checked-in record for `cal_com-PR11059` carries all 14 keys and no others (quoted in
Claim 5). The two downstream consumers read only keys present here — `rec["url"]` and
`rec["fork"]` in the injector (`crb-pipeline-to-benchmark.py:217`, `:229`) and the top-level
slug list in the runner (`run-host.sh:69-71`).

Note the docstring at `scripts/crb-materialize.py:29-30` lists an abbreviated key set
("slug -> {url, fork, head, base, n_goldens, files_changed, insertions, deletions,
clone_mb}") and omits `source_repo`, `pr_title`, `fork_url`, `commits`, `depth`. That is an
elision in a usage summary rather than a contradiction, but it under-describes the record.

**Evidence:** `runs/review-arms/crb/instances.json`, `scripts/crb-materialize.py:29-33`, `scripts/crb-materialize.py:210-216`, `scripts/crb-pipeline-to-benchmark.py:217-232`

---

## Claim 26: "Every tool's fork of the same original PR carries the same code (they differ only in which bot reviewed it), so one fork per PR suffices."

**Location:** `scripts/crb-materialize.py:7-8`
**Type:** Invariant
**Verdict:** Unverifiable
**Confidence:** Low
**Legibility-target:** for-orchestrator-synthesis

This asserts equality of tree contents across ~49 GitHub repositories, which cannot be
established without cloning them (paraphrased — no quote available because the claim is
about the contents of external remote repositories, of which this repo holds none). What
*is* checkable and consistent with the claim: every one of the 50 `benchmark_data.json`
entries carries a `claude-code` fork whose `repo_name` encodes the same upstream
`<org>__<repo>__<tool>__PR<n>__<date>` tuple modulo the tool segment, and the
benchmark's own fork step (`step0_fork_prs.py`) is a per-tool forking pass rather than a
per-tool code-mutating one. Verifying properly would require cloning two tools' forks of one
PR and diffing `refs/pull/1/head`.

**Evidence:** `scripts/crb-materialize.py:4-8`, `external/code-review-benchmark/offline/results/benchmark_data.json`, `external/code-review-benchmark/offline/code_review_benchmark/step0_fork_prs.py`

---

## Claim 27: "NO other refs and NO origin remote, so a reviewing agent cannot fetch the upstream future (the merged fix — the answer key) via `git log --all`."

**Location:** `scripts/crb-materialize.py:13-14`, implemented at `:174-190`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

The scrub block does what the docstring claims, in an order that makes the guard
meaningful:

```python
# scripts/crb-materialize.py:176-190
    refs = sh(["git", "for-each-ref", "--format=%(refname)",
               "refs/heads", "refs/tags", "refs/remotes"], cwd=dst).splitlines()
    for ref in refs:
        if ref not in ("refs/heads/review", "refs/heads/main"):
            sh(["git", "update-ref", "-d", ref], cwd=dst)
    subprocess.run(["git", "remote", "remove", "origin"], cwd=dst,
                   capture_output=True, text=True)
    sh(["git", "reflog", "expire", "--expire=now", "--all"], cwd=dst)
    sh(["git", "gc", "--quiet", "--prune=now"], cwd=dst)

    # Guard (a): nothing reachable outside the reviewed head's ancestry.
    stray = sh(["git", "rev-list", "--all", "--not", head], cwd=dst)
```

Ordering is correct: refs are deleted first, then reflogs expired (so deleted refs leave no
reflog anchor), then `gc --prune=now` drops the now-unreachable objects, and only then does
the guard run. `for-each-ref` over `refs/heads refs/tags refs/remotes` covers packed refs as
well as loose ones, so a `packed-refs` file cannot hide a survivor.

Two precise limits on what the guard proves, neither of which contradicts the docstring:

- `git rev-list --all --not <head>` enumerates commits reachable from *refs*, so it is a
  reachability check, not an object-database check. Objects still physically present but
  unreferenced would not appear. This is exactly why the `gc --prune=now` on the preceding
  line matters, and it runs unconditionally with `check=True`.
- The clone is shallow (`--depth`, `run-host.sh` never deepens it beyond
  `resolve_base`'s deepen loop at `crb-materialize.py:128-134`), so history beyond the graft
  boundary is absent from the object store entirely — reinforcing rather than weakening the
  claim.

Medium confidence rather than high because the guard's completeness rests on `gc
--prune=now` semantics rather than on an explicit object-store assertion.

**Evidence:** `scripts/crb-materialize.py:10-14`, `scripts/crb-materialize.py:125-136`, `scripts/crb-materialize.py:174-190`

---

## Claim 28: Shallow clones are "~1 order of magnitude smaller on disk than a full clone of grafana/keycloak" — and `--all` is "~15-25GB"

**Location:** `scripts/crb-materialize.py:19-20` and `scripts/crb-materialize.py:26`
**Type:** Performance / Configuration
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

The order-of-magnitude half is **Unverifiable** on its own (it needs a full clone of
`grafana/grafana` to compare against; nothing in the repo records one — paraphrased, no
quote available because the claim concerns the size of an artifact that does not exist
locally). The `--all` figure on line 26 is checkable and wrong:

```python
# scripts/crb-materialize.py:26
  scripts/crb-materialize.py --all                      # all 50 (~15-25GB)
```

The five pilot clones, materialized at the same `--depth=50` default, measured 190 + 33 +
125 + 127 + 195 = 670 MB, i.e. ~134 MB/clone ⇒ ~6.7 GB for 50 (paraphrased — no quote
available because the figures are the `clone_mb` fields of five separate JSON records in
`runs/review-arms/crb/instances.json`). The pilot deliberately includes the two largest
families (`grafana`, `keycloak` at 125 and 127 MB) and the largest diff
(`sentry-greptile-PR5`, 195 MB), so it is not a low-side sample. `docs/working/crb-direction1-setup.md:27`
states "~6-7 GB" for the same command — the two files in this same diff disagree by 2–4×.

This is cosmetic for measurement (disk budgeting only) but the two numbers should be
reconciled to the measured one.

**Evidence:** `scripts/crb-materialize.py:18-26`, `docs/working/crb-direction1-setup.md:27`, `runs/review-arms/crb/instances.json`

---

## Claim 29: "`keycloak__keycloak__claude-code__PR37429__20260310 -> keycloak-PR37429`"

**Location:** `scripts/crb-materialize.py:70`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

```python
# scripts/crb-materialize.py:69-74
def slug_for(repo_name: str) -> str:
    """keycloak__keycloak__claude-code__PR37429__20260310 -> keycloak-PR37429."""
    parts = repo_name.split("__")
    if len(parts) < 4:
        raise ValueError(f"unexpected fork repo name: {repo_name}")
    return f"{parts[1]}-{parts[3]}".replace(".", "_")
```

For the docstring's input, `parts[1]="keycloak"`, `parts[3]="PR37429"` ⇒
`"keycloak-PR37429"`, with `.replace(".", "_")` a no-op. The `.`→`_` branch is exercised by
the real cal.com fork: `cal_dot_com__cal.com__claude-code__PR11059__20260310` ⇒
`"cal.com-PR11059"` ⇒ `"cal_com-PR11059"`, which is the slug actually checked into the
manifest (paraphrased — no quote available because the correspondence is between a
function's computed output and a JSON key, established by evaluating the expression against
the `fork` field of `runs/review-arms/crb/instances.json`).

**Evidence:** `scripts/crb-materialize.py:69-74`, `runs/review-arms/crb/instances.json`

---

## Claim 30: "claude-code is present on all 50 and was cut on one date (20260310), so it is the most uniform choice."

**Location:** `scripts/crb-materialize.py:54-55`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Both halves hold exactly. Scanning `benchmark_data.json` for reviews with
`tool == "claude-code"` and a non-empty `repo_name`: 50 hits, and the trailing `__`-segment
of every one of those `repo_name`s is `20260310` — a single-valued date histogram
`{'20260310': 50}` (paraphrased — no quote available because the result is an aggregate
over a 50-entry JSON file, not a source line). Zero PRs lack a `repo_name` on every review,
so `load_prs`'s fallback branch is dead for this dataset:

```python
# scripts/crb-materialize.py:84
        fork = forks.get(DEFAULT_FORK_TOOL) or (sorted(forks.values())[0] if forks else None)
```

**Evidence:** `scripts/crb-materialize.py:52-56`, `scripts/crb-materialize.py:77-90`, `external/code-review-benchmark/offline/results/benchmark_data.json`

---

## Claim 31: "`--per-repo 1` should yield 5 PRs (one per project), not 7" — and the named mirror repos

**Location:** `scripts/crb-materialize.py:93-98`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The arithmetic conclusion is exactly right; one of the three examples is not a mirror.

```python
# scripts/crb-materialize.py:93-98
def family(source_repo: str) -> str:
    """Upstream project a dataset entry belongs to. The dataset splits a few
    projects across mirror repos (discourse-graphite, sentry-greptile,
    keycloak-greptile); for stratification those are the same codebase, so
    --per-repo 1 should yield 5 PRs (one per project), not 7."""
    return source_repo.split("-")[0]
```

The dataset's `source_repo` histogram is
`{keycloak: 9, keycloak-greptile: 1, sentry: 6, sentry-greptile: 4, grafana: 10,
discourse-graphite: 10, cal.com: 10}` — 7 distinct values. Applying
`source_repo.split("-")[0]` collapses them to `{keycloak: 10, sentry: 10, grafana: 10,
discourse: 10, cal.com: 10}` — 5 families of 10 each, so `--per-repo 1` yields 5
(paraphrased — no quote available because both histograms are aggregates over the 50-entry
JSON data file). The materialized pilot has exactly 5 slugs, one per family.

The imprecision: `keycloak`/`keycloak-greptile` and `sentry`/`sentry-greptile` are genuine
splits (both names present), but **`discourse-graphite` is the only name discourse ever
appears under** — all 10 discourse PRs carry it, and no bare `discourse` value exists. It
is not a mirror-split; it is a single repo whose name happens to contain a hyphen, and
`family()` only needs to strip the suffix. Listing it alongside the two real splits misstates
why it is in the list.

Note also that the collapse is a prefix heuristic, not a mirror-aware map: any future
`source_repo` containing a hyphen would be silently merged into its prefix family.

**Evidence:** `scripts/crb-materialize.py:93-98`, `scripts/crb-materialize.py:114-122`, `runs/review-arms/crb/instances.json`, `external/code-review-benchmark/offline/results/benchmark_data.json`

---

## Claim 32: "--per-repo N: the N PRs with the most golden comments in each source repo… Ties break on slug for determinism."

**Location:** `scripts/crb-materialize.py:111-113`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The sort key implements both halves as stated:

```python
# scripts/crb-materialize.py:114-122
    by_repo = {}
    for p in prs:
        by_repo.setdefault(family(p[2]["source_repo"]), []).append(p)
    sel = []
    for repo in sorted(by_repo):
        ranked = sorted(by_repo[repo],
                        key=lambda p: (-len(p[2]["golden_comments"]), p[0]))
        sel.extend(ranked[: args.per_repo])
    return sorted(sel, key=lambda p: p[0])
```

`-len(golden_comments)` gives most-goldens-first; `p[0]` (the slug) is the secondary key, so
ties are deterministic. The one drift: the comment says "in each **source repo**", but the
grouping key is `family(source_repo)` — the collapsed project, per Claim 31. That is
deliberate (it is the whole point of `family()`), but the comment's wording contradicts it,
and the difference is load-bearing: grouping by raw `source_repo` would give 7 selections,
not 5. Say "in each source project (post-`family()` collapse)".

**Evidence:** `scripts/crb-materialize.py:111-122`

---

## Claim 33: "external/ is gitignored, and the slug -> PR mapping is provenance the results depend on, so it must survive a clone wipe."

**Location:** `scripts/crb-materialize.py:48-50`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

```
# .gitignore:2
external/
```

And the manifest is written outside that path:

```python
# scripts/crb-materialize.py:51
MANIFEST = WORKSPACE / "runs/review-arms/crb/instances.json"
```

`runs/` is not ignored — the manifest is checked in on this branch, which is itself the
proof. Both downstream consumers read it from that tracked location
(`crb-pipeline-to-benchmark.py:55`, `run-host.sh:53`), so the mapping survives a wipe of
`external/crb-eval/`.

**Evidence:** `.gitignore:2`, `scripts/crb-materialize.py:47-51`, `scripts/crb-pipeline-to-benchmark.py:55`, `runs/review-arms/crb-pipeline/run-host.sh:53`

---

## Claim 34: "on forks whose default branch is itself named `main`, HEAD still points at it after --no-checkout, and git refuses to force-update the branch that is checked out."

**Location:** `scripts/crb-materialize.py:168-170`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

The mitigation is ordered exactly as the comment describes — check out `review`, *then*
force-move `main`:

```python
# scripts/crb-materialize.py:168-172
    # Check out `review` FIRST: on forks whose default branch is itself named
    # `main`, HEAD still points at it after --no-checkout, and git refuses to
    # force-update the branch that is checked out.
    sh(["git", "checkout", "--quiet", "review"], cwd=dst)
    sh(["git", "branch", "-f", "main", base], cwd=dst)
```

Both asserted git behaviours are standard and long-standing: `git clone --no-checkout`
still writes `HEAD` as a symref to the remote's default branch (it skips only the
working-tree population), and `git branch -f` errors with "Cannot force update the current
branch" when the target is checked out (paraphrased — no quote available because these are
upstream git semantics, not code in this repo). Medium confidence because I could not
exercise the failing path here — the pilot's five forks would need a default branch literally
named `main` to trigger it, and the clones are gitignored/absent from this checkout.

`sh(..., check=True)` means the ordering is not merely cosmetic: were it reversed, the
`branch -f` failure would raise and the instance would be recorded as FAILED rather than
silently mis-based, so the failure mode is loud either way.

**Evidence:** `scripts/crb-materialize.py:59-66`, `scripts/crb-materialize.py:163-172`

---

## Claim 35: "Guard (b): the range is non-empty and its blobs are present locally (a partial/broken clone shows up here rather than mid-review)."

**Location:** `scripts/crb-materialize.py:191-196`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

```python
# scripts/crb-materialize.py:191-196
    # Guard (b): the range is non-empty and its blobs are present locally (a
    # partial/broken clone shows up here rather than mid-review).
    n_commits = int(sh(["git", "rev-list", "--count", "main..review"], cwd=dst))
    stat = sh(["git", "diff", "--shortstat", "main", "review"], cwd=dst)
    if n_commits == 0 or not stat:
        raise RuntimeError(f"{slug}: empty review range (commits={n_commits}, stat={stat!r})")
```

Both halves hold. Non-emptiness is the explicit `n_commits == 0 or not stat` test.
Blob-presence is enforced *indirectly but really*: `git diff --shortstat` must read the
content of every changed blob on both sides to produce insertion/deletion counts, so a
clone missing those objects makes the command fail, and `sh()` raises on any non-zero exit
by default (`crb-materialize.py:63-65`, quoted in Claim 34's evidence). Critically, this runs
*after* `git remote remove origin` at `:181-182`, so there is no promisor remote for a
partial clone to lazily fetch from — the missing object surfaces as an error rather than a
silent network round-trip.

Medium confidence because the blob-presence property is a side effect of `git diff`'s
implementation rather than an explicit assertion; a future switch to `--stat --raw` or
`diff-tree` would silently weaken it.

**Evidence:** `scripts/crb-materialize.py:59-66`, `scripts/crb-materialize.py:181-196`

---

## Claim 36: "Untouched PRs and every other tool's reviews are preserved verbatim, so the aggregate table at the end of step 3 is a real leaderboard."

**Location:** `scripts/crb-pipeline-to-benchmark.py:13-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The script loads the benchmark's whole file and mutates only our tool's entry:

```python
# scripts/crb-pipeline-to-benchmark.py:196
    data = json.loads(BENCH_DATA.read_text())
```

```python
# scripts/crb-pipeline-to-benchmark.py:225-233
        entry = data[url]
        entry["reviews"] = [r for r in entry.get("reviews", []) if r["tool"] != args.tool_name]
        entry["reviews"].append({
            "tool": args.tool_name,
            ...
        })
```

The filter removes only rows whose `tool` equals `--tool-name`; every other review object is
carried through by reference and re-serialized:

```python
# scripts/crb-pipeline-to-benchmark.py:246
    (out / "results/benchmark_data.json").write_text(json.dumps(data, indent=2) + "\n")
```

PRs with no matching run cell are never indexed at all (the loop iterates over run cells,
not over `data`), so they are untouched. Step 3's aggregate table then sums per tool over
all completed evaluations, which includes the seeded rows — see Claim 41.

**Evidence:** `scripts/crb-pipeline-to-benchmark.py:196`, `scripts/crb-pipeline-to-benchmark.py:210-246`

---

## Claim 37: "Steps 2 and 3 skip any (PR, tool) pair already present, so seeding means the paid judge work is OUR TOOL ONLY"

**Location:** `scripts/crb-pipeline-to-benchmark.py:19-20`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Step 2 skips on the candidates map:

```python
# external/code-review-benchmark/offline/code_review_benchmark/step2_extract_comments.py:215-217
            # Skip if already has candidates for this (golden_url, tool)
            if golden_url in all_candidates and tool in all_candidates[golden_url]:
                continue
```

Step 3 skips on completed evaluations:

```python
# external/code-review-benchmark/offline/code_review_benchmark/step3_judge_comments.py:486-488
            if not args.force and state.is_done(golden_url, tool):
                skipped += 1
```

Step 2.5 has the equivalent guard (`step2_5_dedup_candidates.py:267-276`, a `--tool` filter
plus a "Skip if already done (unless --force)" branch). Both `--tool` filters are also
present (`step2:212-213`, `step3:474-475`), so the seeding + `--tool` combination is
belt-and-braces: either mechanism alone confines paid work to our arm.

**Evidence:** `scripts/crb-pipeline-to-benchmark.py:16-20`, `external/code-review-benchmark/offline/code_review_benchmark/step2_extract_comments.py:208-223`, `external/code-review-benchmark/offline/code_review_benchmark/step2_5_dedup_candidates.py:265-276`, `external/code-review-benchmark/offline/code_review_benchmark/step3_judge_comments.py:474-488`

---

## Claim 38: "Without it step 2 re-extracts the ~52 (PR, tool) pairs the checked-in candidates file happens to be missing, and step 3 would re-judge them"

**Location:** `scripts/crb-pipeline-to-benchmark.py:268-271` (mirrored at `docs/working/crb-direction1-setup.md:143-145`)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The mechanism is right and the number is within 4%. Replaying step 2's own filter against
the checked-in data: of 2449 `(PR, tool)` pairs in `benchmark_data.json`, 216 are absent
from `anthropic_claude-opus-4-5-20251101/candidates.json`, but only **50** of those survive
step 2's minimum-text gate:

```python
# external/code-review-benchmark/offline/code_review_benchmark/step2_extract_comments.py:219-223
            comments = review.get("review_comments", [])
            all_text = get_all_comment_text(comments)

            if all_text and len(all_text.strip()) >= 20:
                extraction_tasks.append((golden_url, tool, all_text))
```

So the extractable count is 50, not ~52 (paraphrased — no quote available because the count
is a replay of the above filter over the full 50-entry dataset). The step-3 half of the
claim needs one correction that strengthens the doc rather than weakening it: the
checked-in `evaluations.json` covers **all 2449 pairs** with zero missing, so without
`--tool`, step 3 would skip everything already judged and only judge whatever step 2 newly
extracted. The "overwrites published numbers with ours" risk therefore comes from step 2's
50 extractions flowing into step 3, which is what the comment says — just via a narrower
path than "re-judge them" suggests.

**Evidence:** `scripts/crb-pipeline-to-benchmark.py:268-271`, `external/code-review-benchmark/offline/code_review_benchmark/step2_extract_comments.py:186-226`, `external/code-review-benchmark/offline/results/anthropic_claude-opus-4-5-20251101/candidates.json`

---

## Claim 39: "'✅ Confirmed Good' rows are never emitted … 'Confirmed Good' and 'Considered Overrides' are deliberately absent [from FINDING_SECTIONS]"

**Location:** `scripts/crb-pipeline-to-benchmark.py:22-26` and `:58-60`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The Confirmed-Good half is **true twice over**. The section filter is a substring test:

```python
# scripts/crb-pipeline-to-benchmark.py:98-103
    for section, header, rows in md_tables(md):
        if not any(s.lower() in section.lower() for s in sections):
            continue
        idx = {h.lower(): i for i, h in enumerate(header)}
        f_i = idx.get("finding")
        if f_i is None:
            continue
```

None of `"must fix"`, `"must address"`, `"consider"` is a substring of `"✅ confirmed
good"`, and that table's header is `| Item | Verdict | Evidence | Source |
Legibility-target |` (`skills/code-review/SKILL.md:1157`) with no `Finding` column, so
`f_i is None` would skip it anyway. Running the parser on the real `mfc-csp` rubric confirms
this — 16 comments out, none from the 5 Confirmed-Good rows (see Claim 6).

The **Considered Overrides** half is where the stated mechanism is wrong. `"consider"` *is*
a substring of `"↩️ considered overrides"`, so that section passes the filter — its
exclusion from `FINDING_SECTIONS` does nothing. It yields zero rows only because the rubric
template names its column `Prior finding`, not `Finding`:

```markdown
// skills/code-review/SKILL.md:1142-1144
| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `#123` / 2026-04-12 | Null check in `auth.ts:42` (security) | 🔴 Must-Fix → Won't-Fix | ... |
```

I confirmed the sensitivity directly: feeding the parser a Considered-Overrides table whose
column is spelled `Finding` emits the override row as a review comment; with the template's
`Prior finding` spelling it emits nothing (paraphrased — no quote available because the
result is the observed return value of `comments_from_rubric` on two synthetic inputs). The
exclusion is therefore an accident of column naming, not the deliberate `FINDING_SECTIONS`
omission the comment claims — a one-word rename in the rubric template would start
injecting inherited overrides as findings and inflate the FP count.

Low practical risk today (`mfc-csp` renders the section as the "No prior overrides matched
this diff." single line, so no table is produced at all), but the comment overstates the
guarantee. Tightening the filter to an exact/anchored match would make it true as written.

**Evidence:** `scripts/crb-pipeline-to-benchmark.py:22-26`, `scripts/crb-pipeline-to-benchmark.py:58-60`, `scripts/crb-pipeline-to-benchmark.py:97-129`, `skills/code-review/SKILL.md:1137-1159`

---

## Claim 40: "The benchmark's 49 tools post a median of 4 findings per PR; an E8 rubric carries ~16 (1 red + 8 amber + 7 green on mfc-csp)."

**Location:** `scripts/crb-pipeline-to-benchmark.py:177-180` (mirrored at `docs/working/crb-direction1-setup.md:114-116`)
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The second half is exactly right (Claim 6: 1 + 8 + 7 = 16, parser-confirmed). The first
half is right only under one of two readings, and the doc does not say which.

Over all 2449 `(PR, tool)` pairs in `benchmark_data.json`, `len(review_comments)` has
**median 3**, mean 3.91. Restricting to the 2282 pairs where the tool posted at least one
comment, the median is **4.0** (paraphrased — no quote available because both statistics
are aggregates over a 50-entry JSON data file). So "median of 4" holds if empty reviews are
excluded and not otherwise.

The distinction matters for the argument the comment is making — the point is the ratio
between a benchmark tool's output volume and an E8 rubric's, and 16/3 vs 16/4 changes the
framing of how precision-poor the all-sections row will look. Recommend stating the reading:
"a median of 4 findings per PR when they post at all (3 including silent reviews)". The
mitigation the comment proposes is real and correctly wired — see Claim 42.

**Evidence:** `scripts/crb-pipeline-to-benchmark.py:177-183`, `docs/working/crb-direction1-setup.md:114-120`, `external/code-review-benchmark/offline/results/benchmark_data.json`

---

## Claim 41: "Benchmark judging is text-only — path/line are carried for human readability, not scored — so a miss is harmless."

**Location:** `scripts/crb-pipeline-to-benchmark.py:136-138`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The only field the benchmark reads off a review comment is `body`:

```python
# external/code-review-benchmark/offline/code_review_benchmark/step2_extract_comments.py:146-149
def get_all_comment_text(review_comments: list[dict]) -> str:
    """Combine all comment bodies into a single text for extraction."""
    bodies = [c["body"] for c in review_comments if c.get("body")]
    return "\n\n---\n\n".join(bodies)
```

That concatenation is the sole input to step 2's extraction task tuple
(`step2_extract_comments.py:219-223`, quoted in Claim 38), and step 3 judges the extracted
candidates rather than the original comment objects (`step3_judge_comments.py:210-214`). No
`path` or `line` key is read anywhere in the three steps. The injector's own belt-and-braces
also holds: it appends the location to the body text, so a `parse_location` miss loses
nothing the judge sees:

```python
# scripts/crb-pipeline-to-benchmark.py:126-127
                "body": (f"[{prefix}] " if prefix else "") + body
                        + (f"\n\nLocation: {loc}" if loc and loc != "—" else ""),
```

**Evidence:** `scripts/crb-pipeline-to-benchmark.py:132-144`, `external/code-review-benchmark/offline/code_review_benchmark/step2_extract_comments.py:146-149`, `external/code-review-benchmark/offline/code_review_benchmark/step3_judge_comments.py:205-215`

---

## Claim 42: Judge-directory naming — `jdir` / `src` / `MARTIAN_MODEL` / `DEFAULT_EVALS` all agree

**Location:** `scripts/crb-pipeline-to-benchmark.py:249-253` and `:282`; `scripts/crb-subset-leaderboard.py:26-27`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

All four sites resolve to the same directory name. The vendored steps derive it from
`MARTIAN_MODEL` with the identical sanitizer:

```python
# external/code-review-benchmark/offline/code_review_benchmark/step3_judge_comments.py:88-96
def sanitize_model_name(model: str) -> str:
    """Sanitize model name for use as directory name."""
    return model.strip().replace("/", "_")
...
    model = os.environ.get("MARTIAN_MODEL", "openai/gpt-4o-mini")
    model_dir = RESULTS_DIR / sanitize_model_name(model)
```

(the same function body appears verbatim in `step2_extract_comments.py:64-70` and
`step2_5_dedup_candidates.py:82-88`, and `RESULTS_DIR = Path("results")` is CWD-relative in
all three — hence the runbook's `cd {out}` at `crb-pipeline-to-benchmark.py:278`).

The injector's copy is byte-identical in behaviour:

```python
# scripts/crb-pipeline-to-benchmark.py:63-64
def sanitize_model(model: str) -> str:
    return model.strip().replace("/", "_")
```

With `--judge claude-opus-4-5-20251101` (the default), `MARTIAN_MODEL={args.judge}` at
`:282` ⇒ the steps write `results/claude-opus-4-5-20251101/`; `jdir` at `:249` is the same
path; and `DEFAULT_EVALS` hardcodes it:

```python
# scripts/crb-subset-leaderboard.py:26-27
DEFAULT_EVALS = (WORKSPACE / "runs/review-arms/crb/offline-work-50/results"
                 / "claude-opus-4-5-20251101/evaluations.json")
```

The `src` seed path correctly uses the *other* convention, because the checked-in results
dir is named for the provider-prefixed id:

```python
# scripts/crb-pipeline-to-benchmark.py:251-253
    src = BENCH / "results" / sanitize_model(f"anthropic/{args.judge}")
    if not src.exists():
        src = BENCH / "results" / sanitize_model(args.judge)
```

`external/code-review-benchmark/offline/results/anthropic_claude-opus-4-5-20251101/` exists,
so the first branch hits. `docs/working/crb-direction1-setup.md:137-142` describes this
asymmetry correctly.

One coupling worth noting (not a false claim): `DEFAULT_EVALS` is hardcoded, so
`--judge <other>` on the injector silently desynchronizes the leaderboard's default —
mitigated because `RUN.md` always emits an explicit `--evaluations` path
(`crb-pipeline-to-benchmark.py:291-293`).

**Evidence:** `scripts/crb-pipeline-to-benchmark.py:56`, `scripts/crb-pipeline-to-benchmark.py:63-64`, `scripts/crb-pipeline-to-benchmark.py:249-253`, `scripts/crb-pipeline-to-benchmark.py:277-293`, `scripts/crb-subset-leaderboard.py:26-27`, `external/code-review-benchmark/offline/code_review_benchmark/step3_judge_comments.py:21-96`

---

## Claim 43: "Step 3's own aggregate table sums each tool over every PR it has results for" and "Metrics are MICRO-averaged … the same convention step 3 uses"

**Location:** `scripts/crb-subset-leaderboard.py:4-11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Step 3 iterates the whole completed-state map, per tool, with no PR restriction:

```python
# external/code-review-benchmark/offline/code_review_benchmark/step3_judge_comments.py:539-549
    for golden_url, tools in state.completed.items():
        for tool, result in tools.items():
            if result.get("skipped"):
                continue
            if tool not in tool_metrics:
                tool_metrics[tool] = {"tp": 0, "fp": 0, "fn": 0, "errors": 0, "count": 0}
            tool_metrics[tool]["tp"] += result.get("tp", 0)
```

and divides once at the end — the definition of micro-averaging:

```python
# external/code-review-benchmark/offline/code_review_benchmark/step3_judge_comments.py:557-559
        m = tool_metrics[tool]
        precision = m["tp"] / (m["tp"] + m["fp"]) if (m["tp"] + m["fp"]) > 0 else 0
        recall = m["tp"] / (m["tp"] + m["fn"]) if (m["tp"] + m["fn"]) > 0 else 0
```

The new script reproduces both the accumulation and the divide-at-the-end shape, including
the same `skipped` exclusion:

```python
# scripts/crb-subset-leaderboard.py:56-70
        for tool, res in evals[url].items():
            if res.get("skipped"):
                continue
            a = agg.setdefault(tool, {"tp": 0, "fp": 0, "fn": 0, "n": 0, "cand": 0, "gold": 0})
            ...
        p = a["tp"] / (a["tp"] + a["fp"]) if (a["tp"] + a["fp"]) else 0.0
```

The only difference is the URL set it accumulates over, which is the script's entire point.

**Evidence:** `scripts/crb-subset-leaderboard.py:1-11`, `scripts/crb-subset-leaderboard.py:49-71`, `external/code-review-benchmark/offline/code_review_benchmark/step3_judge_comments.py:536-562`

---

## Claim 44: "`scripts/crb-subset-leaderboard.py --all-prs` # full 50-PR leaderboard"

**Location:** `scripts/crb-subset-leaderboard.py:16`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The flag ranks over every PR *in the evaluations file*, which is 50 only when that file is
the seeded copy:

```python
# scripts/crb-subset-leaderboard.py:49-50
    urls = sorted(evals) if args.all_prs else sorted(
        u for u, tools in evals.items() if args.tool in tools)
```

The `--help` text is precise where the usage line is not:

```python
# scripts/crb-subset-leaderboard.py:39-40
    ap.add_argument("--all-prs", action="store_true",
                    help="rank over every PR in the file instead of our tool's subset")
```

In the default flow the two coincide: the seeded `evaluations.json` covers all 50 PRs and
2449 pairs, so `--all-prs` genuinely yields 50 (paraphrased — no quote available because the
coverage figure is an aggregate over the checked-in evaluations file). But with `--no-seed`
(`crb-pipeline-to-benchmark.py:254-255`) the file starts empty and `--all-prs` would rank
over only our own PRs, silently. The header string the script prints under `--all-prs` is
already honest — `f"all {len(urls)} PRs"` (`:77`) — so only the docstring's "50" is
overstated.

**Evidence:** `scripts/crb-subset-leaderboard.py:13-18`, `scripts/crb-subset-leaderboard.py:39-40`, `scripts/crb-subset-leaderboard.py:49-52`, `scripts/crb-subset-leaderboard.py:74-77`

---

## Claims Requiring Attention

### Incorrect
- **Claim 8** (`docs/working/crb-direction1-setup.md:172-176`): the golden-denominator caveat says "the same 2 PRs" show `total_golden` "11 vs 13"; in fact **24 of 50 PRs** disagree, values range 1–9, and 11/13 occur nowhere (max golden count is 9). 4 of the 5 pilot PRs are affected. Understates a measurement-relevant caveat by ~12×.
- **Claim 28** (`scripts/crb-materialize.py:26`): `--all` annotated "~15-25GB"; the pilot's own measured `clone_mb` values extrapolate to ~6.7 GB, and `docs/working/crb-direction1-setup.md:27` in the same diff says "~6-7 GB". Reconcile to the measured figure. (The companion "~1 order of magnitude smaller than a full clone" claim at `:19-20` is separately unverifiable — no full clone exists locally to compare against.)

### Stale
- None.

### Mostly Accurate
- **Claim 1** (`docs/working/crb-arm-plan.md:193`): says "steps 1 and 3 … built"; four stages shipped, and stage 2's key assumption is explicitly unverified. Restate as "stages 1, 3 and 4 built; stage 2 built but unrun".
- **Claim 3** (`docs/working/crb-direction1-setup.md:27`): "~6-7 GB" is the well-supported number but contradicts the script's own annotation — fix the script, not the doc.
- **Claim 19** (`runs/review-arms/crb-pipeline/run-host.sh:104-105`, `:126`): the preflight's `"log in" in r.lower()` test does **not** match E7's documented `"Not logged in · Please run /login"`; E7's own preflight tested `"logged in"` too and that clause was dropped. Detection survives via `num_turns < 1`. Restore the `"logged in"` alternative.
- **Claim 23** (`runs/review-arms/crb-pipeline/run-host.sh:150-153`): "re-runs start from the same state" — `git clean -qfd` (no `-x`) leaves gitignored files the review created, and the harvest misses them too. Use `-qfdx` or soften the comment.
- **Claim 31** (`scripts/crb-materialize.py:93-98`): the 5-not-7 conclusion is exactly right, but `discourse-graphite` is not a mirror-split (it is the only name discourse appears under) — only keycloak and sentry are genuinely split.
- **Claim 32** (`scripts/crb-materialize.py:111`): says "in each source repo"; the grouping key is `family(source_repo)`, and the difference is what makes it 5 rather than 7. Say "source project".
- **Claim 38** (`scripts/crb-pipeline-to-benchmark.py:268-271`): "~52 (PR, tool) pairs" is 50 after step 2's ≥20-char gate (216 are missing from candidates; 166 are too short to extract). Step 3's evaluations file is complete at 2449 pairs, so the re-judge risk flows through step 2's new extractions rather than a direct re-judge.
- **Claim 39** (`scripts/crb-pipeline-to-benchmark.py:22-26`, `:58-60`): `✅ Confirmed Good` exclusion is solid, but `↩️ Considered Overrides` **passes** the substring filter (`"consider"` ⊂ `"considered overrides"`) and is excluded only because the rubric template's column is named `Prior finding`. Anchor the section match.
- **Claim 40** (`scripts/crb-pipeline-to-benchmark.py:177-178`): "median of 4 findings per PR" holds only excluding silent reviews; median over all 2449 pairs is 3 (mean 3.91). State the reading.
- **Claim 44** (`scripts/crb-subset-leaderboard.py:16`): `--all-prs` = "full 50-PR leaderboard" is true only for a seeded evaluations file; with `--no-seed` it silently reduces to our own PRs.

### Unverifiable
- **Claim 26** (`scripts/crb-materialize.py:7-8`): "every tool's fork carries the same code" needs two forks of one PR cloned and their `refs/pull/1/head` diffed. Nothing in-repo can settle it, and the whole one-fork-per-PR design rests on it — worth a one-off spot check before the sweep.
- **Claim 28, first half** (`scripts/crb-materialize.py:19-20`): "~1 order of magnitude smaller than a full clone of grafana/keycloak" needs a full clone to measure.
- **Claim 9** (`docs/working/crb-direction1-setup.md:180-182`): `score_profiles.py` exists; the "Strict/Core/All by golden category" mechanism was confirmed only at the filename level.

## Goal-Alignment Note
- Answered: yes — all 36 orchestrator-flagged claims checked against the vendored benchmark data, the referenced results docs, and git history.
- Out of scope: code quality, error handling, and shell-quoting robustness (e.g. `awk '{print $2}'` on `git status` output truncates paths containing spaces at `run-host.sh:195`) — noted here only because it was encountered while verifying Claim 23; it is a critic-stage concern, not a documentation-accuracy one.
- Escalate: (1) **the branch ref `feat/crb-direction1-harness` disappeared mid-review** — `git rev-parse HEAD` is unborn and commit `90de392` is no longer a valid object, though all seven files' working-tree contents are intact; the orchestrator should confirm the branch is recoverable before the critic stages run. (2) Claim 8's golden-denominator error is measurement-relevant and should reach the author before any paid judge run, since it governs how recall numbers get caveated. (3) Claim 26 (identical code across tool forks) is the experiment's single unverified structural premise and is cheap to spot-check with two clones.
