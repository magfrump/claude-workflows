Commit: f47de85 (A) / cb2e5f9 (B)

# Security Review — dev-cycle pass 15 (pass-14 fix round)

**Scope:** Partial. A: `git diff 096042b..f47de85 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` in `/workspace/.claude/wt-digest` (commits f920f0d, f47de85). B: `git diff 374d559..cb2e5f9 -- skills/dev-cycle/SKILL.md` in `/workspace/.claude/wt-devcycle` (commit cb2e5f9). Everything else on both branches is context only.
**Date:** 2026-10-01
**Based on:** Stage-1 context `docs/reviews/code-fact-check-report-digest-pass14.md` (loop pass 14, at 096042b / 374d559; it predates this round, so claims new in f920f0d/f47de85/cb2e5f9 were checked here directly).
**Replication:** k=1 (loop pass)

Execution logs (scratch, not committed) are under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/sec15/` (below, `sec15/`). Every repo was built under its own `mktemp -d`, removed on exit; every process ran under `timeout`.
- `timeout 600 bats test/scripts/dev-cycle.bats`, cwd `/workspace/.claude/wt-digest` (HEAD a3e2fea; `git diff --stat f47de85 HEAD -- scripts test` empty): 23/23 ok.
- `sec15/probe.sh` → `sec15/probe.log`, exit 0: section 3 and section 8 for questions.md × archive each absent / plain / symlinked-outside, with questions.sh present and absent (18 runs), plus a symlinked `docs/working/`; `bash -x` trace counts whether `questions.sh open` ran.
- `sec15/probe2.sh` → `sec15/probe2.log`: every trace line naming a path below a symlinked `docs/working/`.

Legibility-target values: **agent** (the model running the skill acts on the text), **maintainer** (someone editing the script or tests), **user** (the human reading the digest or record).

## Trust Boundary Map

```
B1: [repo tree: docs/working/questions.md, questions-archive.md (committed, may be symlinks)] → [blocker/inrepo/skipped walk in section 3] → [questions.sh open (runs only after the walk passes)]
B2: [questions.sh existence test on $ARCHIVE ([[ -f ]], follows symlinks)]                    → [dev-cycle's prior `skipped "$QA"` gate]       → [host filesystem existence oracle]
B3: [repo text: answers in questions.md / questions-archive.md, brief Kept:/date lines]        → [skill In-flight step 2 date bounds]            → [agent action: add Kept:, close brief (Status: closed)]
B4: [digest output (sections 0, 3)]                                                           → [skill step 0 / step 3 text match]              → [agent action: file agent entry, rerun, fix-or-report]
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | `docs/working/questions.md`, `questions-archive.md` path kinds | runtime-mutable (any committer) | UNTRUSTED for path-resolution / read sinks (may point outside the checkout); trusted for nothing below a non-plain part |
| S2 | questions/archive entry text, incl. answers and their dates | runtime-mutable (user, agents, any committer) | UNTRUSTED as instructions; accepted by design as the user's recorded decision for the keep/drop sink, bounded by step 2's date rules |
| S3 | brief `Kept:` lines and brief date | runtime-mutable (agent-written) | same as S2 |
| S4 | `$SCRIPT_DIR/questions.sh` / `$HOME/.claude/scripts/questions.sh` | deploy-time | trusted for exec (pre-existing, not in this diff) |
| S5 | digest's own fixed strings (banner, Window text) | code-constant | trusted |

What enters from outside: committed path kinds (S1) and committed/recorded text (S2, S3). The diff moves the archive gate so it only runs when questions.md is plain and questions.sh exists, keeps `questions.sh` from running whenever the archive is non-plain, and (B) adds date bounds on applying a recorded answer.

## Findings

#### 1. Undated answers bypass step 2's "each answer counts once" bound (re-applied every cycle; an old item's answer applies to a new brief)

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:227-233` (B, cb2e5f9)
**Boundary:** B3
**Move:** #11 (bypass enumeration on the new date guard), #4
**Confidence:** Medium (depends on whether a project records answers undated; this repo's archive dates them by convention, the global answer protocol `Q-NNN: <answer>` does not)
**Legibility-target:** agent
**Evidence (verbatim):** "An answer's date is the one written with it, else today. Apply it only if it is dated after the brief's last `Kept:` date (no `Kept:` yet: on or after the brief's own date) and not after today, so each answer counts once and an older brief's answer never applies. \"Keep\" adds `Kept: <the answer's date>`; \"drop\" closes the brief as in 1."

The "else today" fallback re-dates an undated answer at every cycle, so the guard's two stated properties fail for it. (a) Keep: cycle N applies it with date N and writes `Kept: N`; cycle N+1 finds the same answer again (step 2 searches both files every cycle), dates it N+1 > `Kept: N`, applies it again. `Kept:` therefore advances every cycle, step 3's 14-day clock never runs out, and the brief holds one of the 3 brief slots forever without the user being asked again. (b) Drop: an undated "drop" left in the archive for item X is dated today, which is on or after any later brief's own date, so a new brief for X is closed in its first cycle on an answer the user gave about an earlier brief. Both read as the user's authority applied outside the decision it was given for. Preconditions: an answer recorded without a date (likely wherever the one-line `Q-NNN: [n]` protocol is used and the agent does not stamp it), and for (b) a brief reopened for the same `<item>` text. Impact is limited to working-doc state (reversible; no data leaves the repo), which is why this is not higher. A dated answer on the same day a new brief for the same item is written also passes "on or after the brief's own date" (lower likelihood; see untested/edge note below).

**Recommendation:** Do not let "today" stand in for an answer's date across cycles: when an answer is first applied, write its date into the entry (or the brief, e.g. `Kept: <date> (Q-NNN)`) and match on the Q-ID thereafter, or treat an undated answer as applying only when its entry is newer than the brief (compare the entry's `Opened:` date to the brief's date and its last `Kept:`).

#### 2. A symlinked archive is not listed in section 8 when questions.md is absent or questions.sh is missing

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:249-274` (A, f47de85)
**Boundary:** B1
**Move:** #3
**Confidence:** High (executed: `sec15/probe.log`, runs `q=absent a=link qs=1`, `q=plain a=link qs=0`, `q=absent a=link qs=0`)
**Legibility-target:** user
**Evidence (verbatim):** `elif inrepo docs/working/questions.md && [[ -f "$QS" ]] && skipped "$QA"; then` … `else` / `  echo "No docs/working/questions.md (or questions.sh) in this repo."`

The `&&` short-circuit means `skipped "$QA"` never runs in these three combinations, so a planted archive symlink is neither read nor reported; section 3 prints only the "No docs/working/questions.md (or questions.sh)" line and section 8 omits it. Nothing is read or probed through it (questions.sh does not run), so no information crosses B2; the gap is visibility only, and it is inconsistent with line 251's stated intent that a skipped archive "still listed in section 8, so it shows this cycle". The brief's design ("reports a missing questions.md / questions.sh before the archive check") chose this ordering deliberately; if that ordering stays, the next cycle (after `questions.sh init`, which refuses a symlinked target) surfaces it.

**Recommendation:** Optional: in the final `else`, add `skipped "$QA" || true` as line 251 does, so the archive shows in section 8 in every combination.

## Untested bypass candidates

None for the section 3 gate (A); all candidates below were tested. For B's date guard, candidate 3 below was traced by reading only.

Bypass candidates for the section 3 archive gate (move #11), each tested:
1. Archive symlinked outside, questions.md plain, questions.sh present → banner printed, `questions.sh open` not run (trace count 0), archive in section 8 (`probe.log`, `q=plain a=link qs=1`). Held.
2. `docs/working/` itself symlinked → questions.md skipped at `docs/working/`; the archive's `blocker` walk stops at the same part; the only trace lines naming paths below it are variable assignments and the function arguments (`probe2.log` lines 237-241, 270-273), no `[[ -e/-f/-d/-L ]]` or `realpath` on them; section 8 lists `docs/working/` once. Held.
3. Both files symlinked → questions.md note, both in section 8, questions.sh not run (`q=link a=link`). Held.
4. Archive absent, questions.md plain → questions.sh runs and its `require_files` reports the missing archive (`[[ -f ]]` on an in-repo path). Not a bypass: the archive path's parents passed the walk and the leaf is absent, so the existence answer is about the repo.
5. Swapping the archive to a symlink between dev-cycle's check and questions.sh's `[[ -f ]]` (TOCTOU) → needs a concurrent local writer in the checkout; does not meet the reachable-environment bar. Cleared.

Bypass candidates for B's step 2 date guard:
1. Undated answer → Finding 1 (traced by reading; bypasses).
2. Future-dated answer → blocked by "not after today". Held (read).
3. Old dated "drop" for the same `<item>` written the same day as a new brief → admitted by "on or after the brief's own date". Read only; folded into Finding 1 as low likelihood.
4. Substring item names ("auth" vs "auth-ui") → the searched question ends in `<item>?`, so "brief for auth?" does not match "brief for auth-ui?". Held (read).

## Endorsement Claims

- **Claim:** At f47de85, `questions.sh open` does not run when docs/working/questions-archive.md (or `docs/working/`) is a symlink, in any of the nine questions.md × archive combinations with questions.sh present or absent.
  **Location:** `scripts/dev-cycle.sh:249-274`
  **Evidence:** executed
  **Verified:** `sec15/probe.log`, 18 combinations plus a symlinked `docs/working/`, `bash -x` trace count of `questions.sh open` is 0 in every run with a symlinked archive or questions.md.
  **Not verified:** a non-symlink non-regular archive (a directory) — routed through the same `rawfile` leaf check, not run.
  **route: code-fact-check**
- **Claim:** The new comment's account of questions.sh matches its code: `open` touches the archive only through `require_files`' `[[ -f "$file" ]]`, which follows a symlink, and never reads its content.
  **Location:** `scripts/dev-cycle.sh:246-248`; `scripts/questions.sh:132-138, 408-414`
  **Evidence:** read-static
  **Verified:** `cmd_open` calls `require_files`, then `parse_entries "$LIVE"` only.
  **Not verified:** the installed `$HOME/.claude/scripts/questions.sh` fallback copy, which may differ from the repo's.
  **route: code-fact-check**
- **Claim:** With `docs/working/` symlinked, no filesystem test or `realpath` names a path below it during section 3.
  **Location:** `scripts/dev-cycle.sh:103-113, 249-251`
  **Evidence:** executed
  **Verified:** `sec15/probe2.log`: the only matching trace lines are assignments, `blocker` arguments and the `*/*` string match.
  **Not verified:** a symlinked `docs/` (covered at 096042b by the pass-14 fact-check trace, not rerun here).
- **Claim:** Skill step 0's quoted Window text matches the digest's string byte for byte.
  **Location:** `skills/dev-cycle/SKILL.md:103`; `scripts/dev-cycle.sh:174`
  **Evidence:** read-static
  **Verified:** grep of f47de85 shows "records, or a directory above them, were skipped" inside `source_note` at :174.
  **Not verified:** the scrubbed output path (the string contains no characters the scrub removes, by reading).
- **Claim:** Skill step 3's "watched questions were NOT checked" phrase matches both digest failure lines (the new bold banner at :253 and the questions.sh-failure line at :268) as a case-insensitive substring.
  **Location:** `skills/dev-cycle/SKILL.md:156-157`
  **Evidence:** read-static
  **Verified:** the two echo strings at `scripts/dev-cycle.sh:253, 268`.
  **Not verified:** that an agent matches case-insensitively (the banner capitalises "Watched").

## Primitive sweep

Primitive: path resolution / file read through a possibly symlinked repo path (engaged in section 3)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/dev-cycle.sh:249` `skipped docs/working/questions.md` | S1 | `blocker` walk | cleared — probe runs, no probe below a blocking part |
| `scripts/dev-cycle.sh:251` `skipped "$QA"` | S1 | `blocker` walk | cleared — same walk; dedup in section 8 |
| `scripts/dev-cycle.sh:252` `inrepo … && skipped "$QA"` | S1 | `blocker` walk, then `rawfile` | cleared — banner, no exec |
| `scripts/dev-cycle.sh:256` `bash "$QS" open` (reads questions.md, `-f` on archive) | S1, S4 | :249 and :252 gates | cleared — runs only with both plain (or archive absent) |
| `scripts/dev-cycle.sh:273` else branch | S1 | none needed (no read) | Finding 2 (visibility only) |

Primitive: process exec — only `bash "$QS" open` at :256 (S4, deploy-time, unchanged by this diff); cleared.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Undated answers bypass step 2's once-only date bound | Medium | B3 | `skills/dev-cycle/SKILL.md:227-233` | Medium |
| 2 | Symlinked archive unlisted when questions.md / questions.sh absent | Informational | B1 | `scripts/dev-cycle.sh:249-274` | High |

## Overall Assessment

The digest side (A) of this round is sound within the paths run: in all 18 questions.md × archive × questions.sh combinations and a symlinked `docs/working/`, questions.sh never runs against a non-plain archive and nothing is probed below a blocking part; the only gap is that a symlinked archive goes unlisted when questions.md or questions.sh is absent (Informational, visibility only). The skill side (B) adds date bounds that hold for dated answers but not for undated ones: "else today" re-dates an undated answer every cycle, so a "keep" renews itself forever and an old "drop" can close a new brief for the same item. That is fixable in place (stamp the date or match on the Q-ID when first applying) and is the single most important thing to address. No findings within the code paths read beyond these two; endorsement claims marked `route: code-fact-check` are pending execution verification there.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."
This report is saved at `/workspace/.claude/wt-digest/docs/reviews/security-review-2026-10-01-digest-pass15.md` with the skill's header, Trust Boundary Map with source table, findings (each with Severity, Location, Evidence, Confidence, Legibility-target), untested-bypass section, endorsement claims with routing, primitive sweep, summary table and overall assessment. It serves the user goal (reach a clean pass, then merge both branches) by naming one Medium on B that a further delta pass should fix before the clean full review; A has no blocking finding.
