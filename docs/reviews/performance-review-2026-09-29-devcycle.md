Commit: 89a3d3b

# Performance Review — feat/dev-cycle

**Scope:** `git diff main...HEAD` (scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, test/dev-cycle.bats, docs/roadmap.md, one-line doc edits)
**Date:** 2026-09-29
**Based on:** critic-brief-c.md (shared context); no code-fact-check report was handed to this critic.

> ⚠️ **No code fact-check report provided.** Performance claims in comments and documentation
> have not been independently verified. For full verification, run the `code-fact-check` skill
> first or use the code-review orchestrator.

## Data Flow and Hot Paths

`scripts/dev-cycle.sh` runs once per dev cycle, started by hand (no timer). It is a **cold path**
for CPU and I/O: it does a few `git log` calls, one `git log -1` per decision record, one
`questions.sh open`, an awk pass per decision record, and a `shuf`. I measured it in this
worktree (1,887 commits, 385 first-parent merges, 33 decision files, 66 log rows):

- `--since 2025-01-01` (the whole history): `real 0m0.021s`, exit 0.
- Output: 155 lines, 20,127 bytes with the whole history as the window, and 20,086 bytes with
  `--since 2026-09-15`.

The script's CPU cost does not matter. What does matter is its **output**, because an agent
reads the digest into context and must then act on every item (skill step 2). So I review the
digest's size and the per-cycle agent work it creates as the hot path.
Section sizes (window 2026-09-15): §2 Revisit triggers = 15,825 bytes (79% of the digest),
§3 Watched questions = 327 bytes, and §1 is capped at 30 merges by `head -30`.

## Findings

#### 1. Revisit-trigger section is unwindowed and grows with every decision ever recorded

**Severity:** Medium
**Location:** `scripts/dev-cycle.sh:71-93`, `skills/dev-cycle/SKILL.md:47-53`
**Move:** Count the hidden multiplications / what's the size of N
**Classification:** Macro (output and agent work linear in all-time decision count, not in window activity) / Cold path by frequency, but its output is fed to a context-bound agent every cycle
**Confidence:** High (measured)
**Baseline:** digest §2 = 15,825 bytes of a 20,086-byte digest, measured 2026-09-29 by running `scripts/dev-cycle.sh --since 2026-09-15` at 89a3d3b in this worktree
**Legibility-target:** the agent running a cycle, and the user who reads the cycle record

**Evidence:**
```
for f in docs/decisions/[0-9][0-9][0-9]-*.md; do
  [[ -f "$f" ]] || continue
  grep -q '^## Revisit triggers' "$f" || continue
```
and in the skill: "For every trigger in the digest, decide **fired / not fired / cannot tell** and write the evidence (a command and its output, a count, a commit)."

Everything else in the digest is scoped by `--since`. §2 is not. It prints every trigger from
every decision record and every matching log row. The two runs above (whole history and a
two-week window) differ by 41 bytes, and §2 is identical in both. Today that is 12 sources
and roughly 45 individual triggers (31 backtick `if …` entries across the 11 records, plus 14
log rows). The skill asks for each one to get a verdict backed by evidence. That is about 45
evidence commands per cycle, and the count only rises: decisions are append-only, and each new
record adds ~0.8–1.4 KB (range measured over the 11 current records: 786–1,388 bytes). The
digest adds ~4–5K tokens of context today. The larger cost is the agent turns spent
re-verifying triggers that were "not fired" last cycle and whose inputs have not changed. On a
project with a few hundred decisions, the cycle's step 2 would take up most of the budget the
skill says it protects ("Attention is the budget").

**Recommendation:** Carry verdicts forward. Have the script read the previous
`docs/working/cycles/cycle-*.md` and mark triggers already judged "not fired" whose decision
file (and, where recorded, `Relevant paths`) is unchanged since then. Print those as a single
collapsed count ("N triggers unchanged since last cycle, not fired"). Print in full only the
new ones, the changed ones, and the ones judged "cannot tell". Or, more simply, have the
skill's step 2 re-check in depth only the triggers whose subject changed in the window, and
record the rest as "unchanged, carried".

#### 2. Health check runs in the background while later steps run tests (contention with the quiesce rule)

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:36-39` and `:64-66`
**Move:** Find the contention point
**Classification:** Macro (shared-machine contention invalidates the gate result, not a constant factor) / Cold path (once per cycle)
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** the agent running step 1 and step 4

**Evidence:**
```
- Start the project's full check in the background, output to a file (in claude-workflows:
  `scripts/health-check.sh`). Quiesce first: no subagents running, no stray probe processes.
```
```
For each sampled merge, pick the one or two claims the merge rests on ... and re-verify them
against today's code: run the test it cites, reproduce the number, read the code path. Use
`code-fact-check` at k=1 for a merge with many claims.
```
Step 1 quiesces the machine before starting the full check, then leaves the check running in
the background. Nothing tells the agent to wait for it before steps 2–4, and step 4 then runs
cited tests and may dispatch code-fact-check subagents. pr-prep 5a gives the reason quiescing
matters here: install.sh's no-agent guard reads the real process table, and in Q-076 stray
probes made install-host T33/T83/T6 fail in full runs while each passed alone. The full suite
is ~1,200 tests (the `ok 1180 …` numbering in recent health-check logs). Running it alongside
step 4's probes can yield failures that step 1 then wrongly triages as "caused by recent work"
or "flaky". Either outcome wastes the cycle's attention, or it files a bogus entry.

**Recommendation:** Say that step 1's result must be read, and its background run finished,
before step 4 starts any test or subagent. Or run the health check last, just before step 7,
on a quiet machine. The skill does not need the check backgrounded for correctness; it only
saves wall-clock time.

#### 3. Log-row trigger filter matches the dev-cycle row itself and truncates long rows

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:81-89`
**Move:** Identify the serialization tax (output that costs context and carries no signal)
**Classification:** Micro / Cold path
**Confidence:** High (observed in the digest)
**Baseline:** 14 log-row lines in digest §2, measured 2026-09-29 (`grep -c 'row '` on the whole-history digest)
**Legibility-target:** the agent reading §2

**Evidence:**
```
rows="$(grep -E '^\| [0-9]+ \|' docs/decisions/log.md | grep -i 'revisit' || true)"
...
text="$(printf '%s' "$row" | grep -oiE 'revisit[^|]*' | head -1 | cut -c1-400)"
```
Digest output: `- row 67: revisit-trigger verdicts (fired / not fired / cannot tell, with evidence) → watched questions → …`

Any row that contains the word "revisit" is listed as a trigger. Row 67 (this feature)
describes the cycle's steps and has no trigger, so every cycle will spend a verdict on it.
Row 53 is cut at 400 characters mid-sentence ("…inside `$(( ))`"), so the agent has to open
log.md anyway to judge that row. The false-positive rate is small today (1 of 14). But the
word is common in this repo's prose, and the rate rises as rows that mention "revisit" in
passing accumulate.

**Recommendation:** Match the conventional phrasing only (`[Rr]evisit (if|when|at)`), and pick
the match from the rationale column rather than the first hit anywhere in the row. For
truncated rows, print `… (truncated; see log.md row N)` so the agent knows the text is partial.

#### 4. Per-decision `git log -1 -- path` is one history walk per record

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:77`
**Move:** What's the size of N
**Classification:** Micro / Cold path
**Confidence:** Medium
**Baseline:** whole script 0.021 s real on 1,887 commits × 11 matching records, measured 2026-09-29 in this worktree
**Legibility-target:** maintainers porting the script to large repos

**Evidence:**
```
echo "### $f (last changed $(git log -1 --format=%ad --date=short -- "$f"))"
```
Each call walks history until it reaches the file's last change. That is negligible here. On a
100k-commit repo with hundreds of old, rarely touched decision records it becomes records ×
depth. Because the script runs once per cycle, this is not worth changing now. I note it only
because the script is installed globally and runs in arbitrary projects.

**Recommendation:** None needed now. If it ever shows up, one
`git log --name-only --format=%ad -- docs/decisions/` pass can collect every date at once.

## Endorsements

- The merge listing is capped for context: `printf '%s\n' "$merges" | head -30` bounds §1 no matter how long the window is. [read: scripts/dev-cycle.sh:61-65]
- The spot-check sample is bounded by `--sample` (default 2) and seeded by date, so reruns on the same day do not widen the audit. [read: scripts/dev-cycle.sh:119-121]
- The script's CPU cost is negligible on this repo: 0.021 s real over the whole history. This is a single measurement, not a claim about every repo. [unverified — submitted as claim]
- The per-session description cost is small: the `description:` block is 264 bytes (~65 tokens), in line with the other router skills. [read: skills/dev-cycle/SKILL.md:3-5]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Revisit-trigger section unwindowed; digest and step-2 work grow with all-time decision count | Medium | `scripts/dev-cycle.sh:71-93`, `SKILL.md:47-53` | High |
| 2 | Background health check overlaps step-4 tests/subagents, contrary to quiesce rule | Medium | `SKILL.md:36-39,64-66` | Medium |
| 3 | Log-row filter false positive (row 67) and silent 400-char truncation | Low | `scripts/dev-cycle.sh:81-89` | High |
| 4 | One `git log -1` history walk per decision record | Informational | `scripts/dev-cycle.sh:77` | Medium |

## Overall Assessment

The script is cheap to run: 21 ms and a 20 KB digest on this repo. Its output is well bounded
everywhere except the revisit-trigger section, which is ~80% of the digest and is the one part
not scoped to the cycle window. The real cost of a cycle is agent attention, and step 2 as
written re-verifies every trigger ever recorded, each cycle, with evidence. That cost rises
monotonically, and it cuts against the skill's own "attention is the budget" framing (finding 1).
The fix fits the existing design: carry forward last cycle's "not fired" verdicts for decisions
that have not changed. The second issue to fix is ordering: finish or read the background
health check before step 4 runs tests, so contention cannot distort its triage (finding 2). Both
changes are local; neither points to a structural problem. The per-session description cost
(~65 tokens) is not a concern.

## Goal-Alignment Note
- **Answered:** script runtime and output size (measured on this repo, including the whole-history window); how the digest's size splits by section, as agent context; the skill's per-cycle cost (health check contention, trigger-verification fan-out, code-fact-check at k=1 bounded by `--sample`); per-session description cost.
- **Out of scope:** security of printing decision text verbatim into agent context (a security-reviewer concern); whether the skill's steps actually execute (Q-074), apart from its cost; full health-check wall time was not measured (the brief forbids running it).
- **Escalate:** none. Finding 1's carry-forward design is a small judgment call for the author (collapse in the script vs. in skill prose).
