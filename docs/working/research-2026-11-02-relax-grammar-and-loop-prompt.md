# Research: relax the brief, marker and path grammar rules and the loop prompt (restriction audit unit 4)

Brief: `docs/working/briefs/2026-11-02-relax-grammar-and-loop-prompt.md` (policy review).
Branch: `refactor/relax-grammar-and-loop-prompt`, dispatched at 4c410708.
Threat model: `docs/constraints.md` S1 (a hostile loop, branch or author is out of scope), H2
(a gate fails closed on input it cannot parse).

Failure-pattern grep: `overbroad-guard` (FP-030, FP-051, FP-052, FP-055, FP-127, FP-162: a correct check that also rejected legitimate input; fix narrow-the-guard), `stale` (no prior bug in the grammar readers). No entry names FENCE_AWK, `--marker` or pathform.

## Re-verification of each row against today's code

Line numbers are at 4c410708 (after units 1-3).

- **G22 / R65** (lib FENCE_AWK, then lines 249-327): still refused a file for a line
  starting `<` (`rawhtml`), a line starting like a link reference definition behind any
  `>` and list markers (`refdef`), an open `<!--` (`opencomment`), an indented or
  list-item fence (`fenceish`), CR, NUL and a BOM. Every brief (`brief_fields`), questions
  file (`check_answer`, `--cycle-diff`'s QKEYS), `docs/dev-cycle.md` and
  `docs/constraints.md` (`main_file`), the own-blob Status rewrite and the marker body run
  it. Acted on: `rawhtml` and `refdef` removed. Kept, each with its in-scope reason:
  `fenceish` (an honest list-item fence holding an example `Status: done` would otherwise
  be read as the brief's status: the brief's "Status line not inside a fence"),
  `opencomment` (the same for a comment, and questions.sh's index markers: G31's reason),
  CR, NUL, BOM (kept by the brief). Row 69's inline-construct limit is unchanged.
- **G31 / R14b** (`marker()`, build-loop.sh 1001-1005; BODY_RULE 970): still refused the
  heading, `**Needs:**`, `**Status:**`, `**Answer` and `Q-` digit line starts. Confirmed
  first, as the brief asks, that questions.sh's own readers anchor at column 0:
  `parse_entries` matches `/^### Q-[0-9]+ /` and `/^\*\*Needs:\*\*/`, `cmd_check` greps
  `^### Q-`, `next-id` reads `parse_entries`, `archive` splits at `^### Q-` and `^## `; the
  index rows it compares are `^| [Q-` between the markers. None matches a `> `-prefixed
  line. The lib's ANSWER_AWK and build-loop.sh's QKEYS/QDIFF/ANSWERS awks also anchor at
  column 0 (`sub(/^- /...)` strips only a bare list marker). So the quoting is the whole
  defence. Acted on: the line-start refusals dropped. Kept: `<!--` anywhere (questions.sh
  `sed -n "/$INDEX_START/,/$INDEX_END/p"` finds its markers anywhere in a line), strict
  UTF-8, scrub, the 100-line by 300-byte cap and 64 KiB marker cap, the `> ` prefix, and
  the FENCE_AWK pass over both forms (G32, kept: an unclosed fence in a filed body would
  hide every later entry).
- **G39 / G40** (`nrules`, 1133-1137): still denied, under every authority, a path outside
  pathform's set or with a `.git*` part, and any non-file mode. Found in re-checking: the
  brief says "under `--approved`", but a review brief reaches `--approved` only after
  step 7's `--check BRIEF --expect TIP` prints `ok`; a `refuse` there is filed as
  `stopped`, so relaxing `--approved` alone would still never land `.github/` (design
  choice D2 below). Acted on: strict rules only where the S rules apply.
- **R36b** (`skills/dev-cycle/SKILL.md` step 0.1, line 303): still withheld `<`, `>` and
  backticks. Acted on: withholds only `<!--`, controls, bidi, non-UTF-8 bytes. A plain `<`
  or `>` breaks no reader now that FENCE_AWK reads `<` lines as text (and release-entry
  lines start `- ` or a backtick anyway).
- **K24 / K26** (the loop prompt, build-loop.sh 1712): unchanged since the audit. Acted on.
- **Draft-review default** (override-log C9 of unit 2): `skills/draft-review/SKILL.md`'s
  Fact-Check Gate had no unattended default; code-review's (unit 2) is the model.
- **Stale lines from unit 3:** plan D13 line 102 ("`--state` refuses planted `.git`
  state") and the lib comment naming "SKILL.md's hg" (lines 342-343): both stale (the
  `hg` wrapper is gone; `--state` now refuses only a shallow or partial clone, a caller
  repository variable and an ambiguous default branch). Corrected.

No row's in-scope threat was missed by the audit; one kept rule the audit's G22 verdict
would have dropped (indented and list-item fences) is kept for the brief's own reason
(Status inside a fence).

## Design choices

Choices with fewer than 3 viable options (one-line notes):

- Open HTML comments: keep refusing (status quo, the brief's "keep") rather than modelling
  comment state; honest briefs do not leave comments open, and modelling it would add a
  parser state for no reported friction.
- Indented and list-item fences: kept refused (above).
- `.git` part comparison: the lower-cased path, so `.GIT` is refused too (git refuses both).
- Paths under the relaxed rule that are outside pathform's set still print as `?` (the
  output-scrub reason, an outside-party one, stands); the owner reads the branch at its TIP.

### D1. Where a Path C tentative pick's question goes "for the cycle to file" (DD)

Constraints: H2 (loop text reaches questions.md only scrubbed and quoted), S3 (reuse
`--marker`), S10 (owner attention), S2 (no new dispatch), D11 (loops never write the
questions files).

| Option | H2 | S3 reuse | S10 attention | Works for both policies |
|---|---|---|---|---|
| A. Research doc only; the owner finds it in review | ● | ● | ◐ | ○ (a self-merge is never read) |
| B. Ready marker body, read by `--marker` before the merge; review: quoted in the merge entry; self-merge: quoted in the record and final message | ● | ● (one condition widened) | ● (no extra entry under review) | ● |
| C. Ready marker body read by the skill with plain `git log` | ✗ (unscrubbed loop text) | ○ | ● | ● |
| D. A new `--tentative` mode | ● | ○ (second code path) | ● | ● |

C fails H2. B dominates A (A drops self-merge) and D (same result, second mode): Path A,
B. Hypothesis: a loop's tie reaches the owner as one quoted block in an entry they already
answer; counter-evidence would be a ready body `--marker` skips for a body an honest loop
writes.

### D2. Which merges get the relaxed path and mode rules (DD)

| Option | Lands an owner-approved `.github/` | Self-merge safety | Code |
|---|---|---|---|
| A. `--approved` only (the brief's words) | ✗ (`--check` refuses first; step 7 files `stopped`) | ● | small |
| B. Wherever the S rules do not apply: a review brief's `--check`, and `--approved` | ● | ● (self-merge unchanged; the floor's dot rule also catches `.github/`) | small (one argument) |
| C. Relax everywhere, leave `.git*` to the floor | ● | ◐ (symlinks redirect the floor walk: G40's reason) | small |

C fails G40's kept self-merge rule. B dominates A on the brief's own motive ("an
owner-approved branch that adds `.gitignore` or `.github/` can never land"): Path A, B.
A self-merge branch with such a path falls through to review as today, now landable.

## Residual risk (stated, S1)

A key line inside an HTML block or a link-reference title is read though a renderer may
hide it; only a hostile author writes that. A review merge can land a symlink or gitlink,
which the owner sees in the merge entry's `path` lines (marked `(symlink)` or `(gitlink)`).
A self-merge's tentative pick reaches the owner only in the record and final message, not
as an entry whose answer the cycle reads (review i1: an entry filed after the merge has no
`Asked:` brief to read it through); a different pick they name becomes a roadmap item.

## Changes

- `scripts/lib/dev-cycle-read.sh`: FENCE_AWK drops `rawhtml`/`refdef`; comments; `hg` line.
- `scripts/build-loop.sh`: BODY_RULE and `marker()` (ready markers too); `nrules` strict or
  `anyform`; help text; the loop prompt (K24/K26, ready body).
- `scripts/dev-cycle.sh`: help text.
- `skills/dev-cycle/SKILL.md`: steps 0.1, 7 (ready body), 8.
- `skills/draft-review/SKILL.md`; `skills/constraints-builder/references/working-doc-template.md`.
- `docs/working/plan-build-loop-handoff.md`: D2, D3, D5, D11 amendments, D13 line.
- `docs/decisions/log.md`: row 81.
- Tests: orchestrator (marker, quoted readers incl. questions.sh next-id and archive),
  check (path and mode rules, both authorities), merge (`--approved` lands `.github/`,
  `.gitignore`, a symlink; a newline path refuses), read (constraints), dev-cycle (grammar).

## Review-fix loop

Iteration 1 (one review subagent: correctness, scope, prose, tests). Fixed: ready-marker
order (`--marker` before `--merge`, or the merged tip reads as working); the self-merge
tentative question goes to the record and final message instead of an entry nothing reads;
CONSTRAINTS_AWK's near-ID check strips leading HTML tags, so `<b>H2: x</b>` stays
unreadable now that `<` lines are text (H2, Q-112); the loop prompt's "a question goes in a
blocked marker" and its symlink stop now match; `path` lines mark `(symlink)` and
`(gitlink)`; land's refusal text shows `?` for a path outside pathform's set; comment, T12
row and FENCE_AWK divergence wording; tests for DEL and `.git` parts, a ready body with
`<!--`, and an HTML-wrapped near ID. Won't fix: the release entry's double-backtick span for
a path holding a backtick run is cosmetic (no reader is affected).

Iteration 2 (the same reviewer on the fixes): two amber, both from the mode suffix, fixed:
the `--check` help says the suffix shows under either policy, and step 7's GATE_CODE heading
rule reads PATH without the suffix (pinned in build-loop-orchestrator.bats). Clean after.
The health check's one failure in its second run (health-check.bats gate 12, persona
freshness) was a local-versus-UTC midnight flake: it passes on rerun and this branch touches
neither the test nor `scripts/health-check.sh`.
