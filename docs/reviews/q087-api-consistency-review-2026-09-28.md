Commit: 21d4eb8

# API Consistency Review — `review/q087` iteration 2 (fix commit 21d4eb8)

**Scope:** `git diff 27d483b..21d4eb8` (PARTIAL: fix commit 21d4eb8; 09d62ad review artifacts and 27d483b are context only)
**Date:** 2026-09-28
**Based on:** `docs/reviews/q087-code-fact-check-report.md` (iteration 2, k=1 loop pass)

## Baseline Conventions

The consumer-facing surface here is the `code-review` skill contract and the repo's decision/override record conventions:

- **k selection.** `--loop-pass` → k=1 with header `**Replication:** k=1 (loop pass, decision 031)` (`skills/code-review/SKILL.md:448`); every other run → k=3 protocol, merged report header `**Replication:** k=3` (`skills/code-review/SKILL.md:609`). Gate 1h reads that field with `sed -n 's/^\*\*Replication:\*\* *//p'` (`scripts/self-improvement.sh:1581`). Callers: pr-prep 3d invokes `/code-review --loop-pass --range <sha>..HEAD` and says "`--loop-pass` also sets the fact-check replicate count … code-review's SKILL.md owns both" (`workflows/pr-prep.md:244`); review-fix-loop.md defers ownership of `--loop-pass` to the skill (`workflows/review-fix-loop.md:7`).
- **Decision-record header amendments.** A bullet in the header list: `- **Superseded in part (noted 2026-09-26)**: …` (`docs/decisions/030-*.md:11`); `**Superseded in part (noted 2026-09-26)**: …` (`docs/decisions/021-*.md:24`).
- **Decision-log in-place row amendments.** A bold marker in the row: `**SUPERSEDED BY #44 — …**` (log.md:66, row 43, full supersession); `**Superseded in part by row 49**` (log.md:71, row 48); `**Amended 2026-09-27 (Q-070 [1], Q-077):**` (log.md:76, row 53).
- **Override-log retirement.** "never delete entries even when they become stale (mark them with a `~` strikethrough in the `Finding` cell if a reviewer judges them no longer applicable, but keep the row for audit purposes)" (`skills/code-review/SKILL.md:1260`). Row format: `references/override-log.md` § Capture format (Date, PR ref, Finding with `path:line` + critic, Original verdict, Override verdict, Reason); newest rows at top.

## Name-Pattern Audit

No new public names. The fix commit introduces no flags, header values, marker lines, or verdict vocabulary; it rewords the k-selection rule (SKILL.md:451-456), the Dependencies bullet (:20), two log rows, one decision-record header note, and three override-log rows, all using existing vocabulary (`--loop-pass`, `k=3`, `Loop closed at`, `Defer`, `Won't-Fix`, `🟡 Must-Address`, `🟢 Consider`).

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `**Amended in part (noted 2026-09-28)**` | decision header note label | `**Superseded in part (noted 2026-09-26)**` | `docs/decisions/030-*.md:11`, `docs/decisions/021-*.md:24` | Consistent — same `(noted DATE)` shape; "Amended" is the right verb for a narrowing rather than a replacement, and log.md:76 already uses "Amended" |

## Findings

#### Row 60's in-place amendment carries no amendment marker

**Severity:** Minor
**Location:** `docs/decisions/log.md:83`
**Move:** 1 (baseline conventions), 3 (documentation drift)
**Confidence:** High

Precedent: bold in-row amendment marker used in `docs/decisions/log.md:66` (`**SUPERSEDED BY #44 — …**`), `:71` (`**Superseded in part by row 49**`), `:76` (`**Amended 2026-09-27 (Q-070 [1], Q-077):**`)

Evidence (log.md:83, excerpt; row continues to its `| 032 #4; …` sources cell — read):
> "the mitigation is that the final confirming pass reviews the full branch (at 031's k=1, unchanged); raising it to k=3 was open as Q-087, since answered [2]: the final pass now runs k=3 (row 63)."

The commit body says row 60 "was edited in place, following the row-43 precedent of marking superseded rows", but the edit adds no marker: the change is unbolded prose mid-sentence, and the parenthetical before it still asserts the superseded state in the present tense ("at 031's k=1, unchanged"; fact-check claim 8). The log's three existing in-place amendments each use a bold, greppable marker, so a reader scanning for amended rows (or grepping `Amended`/`Superseded`) misses row 60. Consumer impact is small (row 63 is adjacent and the pointer is correct), hence Minor.

**Recommendation:** Rewrite the tail as e.g. "…reviews the full branch (at 031's k=1 when written). **Amended 2026-09-28 (Q-087 [2]):** the final pass now runs k=3 (row 63)." This also resolves fact-check claim 8.

#### Struck override row: follows the documented convention, but Step 3.5 does not say how struck rows match

**Severity:** Informational
**Location:** `docs/reviews/override-log.md:129`; `skills/code-review/SKILL.md:173-181`, `:1260`; `skills/code-review/references/override-log.md` § Capture format
**Move:** 1 (baseline conventions), 3 (consumer contract)
**Confidence:** High

Evidence (override-log.md:129, Finding cell):
> "~~A second standalone review of a branch finds a canonical rubric with no `Loop closed at` line … — fact-check iter3 claim 10~~ (moot since decision log 63: every run without `--loop-pass` is k=3)"

Answer to the fact-check escalation: the retirement form is documented, at `skills/code-review/SKILL.md:1260` ("mark them with a `~` strikethrough in the `Finding` cell … but keep the row"), and the fix commit follows it: `Finding` cell struck, row kept, verdict/Reason cells unchanged as audit history. The appended unstruck "(moot since decision log 63 …)" reason is not part of the stated convention but is a harmless extension and makes the retirement self-explaining. This is the first struck row in the log (no other `~~` in `docs/reviews/override-log.md`), so it sets the in-practice form. The residual gap is pre-existing and not introduced by this commit: Step 3.5's three match rules (SKILL.md:177-179) never say a struck row is excluded, and `references/override-log.md` (which declares itself the place to edit the format: "Edit here, not in the skill") does not mention strikethrough at all. A future run could match this row substantively and surface a moot `Defer`.

**Recommendation:** No change needed on this branch. As a follow-up, move the strikethrough rule into `references/override-log.md` § Capture format and add one sentence to Step 3.5 ("a row whose `Finding` is struck through is retired: surface it only if it is location-matched, marked retired"). File as a follow-up rather than expanding this PR's scope.

## What Looks Good

- **k selection is now keyed on the flag alone** (SKILL.md:451-456: "The **k=3 protocol below applies to every run without `--loop-pass`** … The flag alone sets k, so no rubric check is needed to tell the two apart"). This matches what callers already rely on: pr-prep 3d (`workflows/pr-prep.md:244`) says `--loop-pass` sets the replicate count, and the final confirming pass runs "without it and without `--range`" (pr-prep "First-red short-circuit" paragraph). Dropping the `Loop closed at` recognition clause removes a hidden second input to k and closes the old standalone-rerun k=1 hole (the struck override row). `Loop closed at` remains only in its scope role (SKILL.md:121, :128, :739, :744), which is unchanged. route: code-fact-check
- **Gate 1h contract unchanged.** Final passes now take the standard k=3 path, which writes `**Replication:** k=3` (SKILL.md:609), a value Gate 1h already treats as the full case (`scripts/self-improvement.sh:1581`, `:1609-1614`). No new header value is introduced. route: code-fact-check
- **Dependencies bullet (SKILL.md:20)** now says "the loop's final confirming pass runs k=3, decision log 63", consistent with Stage 1 and with "the rationale lives in one place — Stage 1's **Why three**".
- **031 header note** (`031-…md:28-31`) matches the `(noted DATE)` header-note convention of 030:11 and 021:24 and points to "decision log #63" in the same form 030 uses ("decision log #37").
- **Row 63** now cites the falsifier's real source ("the state doc §1.1 k-reduction falsifier behind log row 27, `docs/thoughts/code-review-evaluation-state.md`") and names the action ("Revisit, lowering this pass's k"), matching the log's "Revisit if …" trigger form.
- **New override-log rows** (override-log.md:80-81) use the Capture-format columns, the tier vocabulary (`🟡 Must-Address` → `Defer`, `🟢 Consider` → `Won't-Fix`), `path:line` plus source attribution, and sit at the top of the table per the reverse-chronological rule. (Fact-check claim 11b's `:232` → `:235` line-pointer error in row 80 is a fact-check matter, not a format one.)
- **Replication test** pins the new positive contract with two greps (`k=3 protocol below applies to every run without .--loop-pass.` and `standalone single-pass reviews and a loop.s final confirming pass`); the suite runs 17/17 ok on this commit.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Row 60's in-place amendment has no bold amendment marker, and its "(at 031's k=1, unchanged)" still reads as current | Minor | `docs/decisions/log.md:83` | High |
| 2 | Struck override row follows SKILL.md:1260; Step 3.5 and `references/override-log.md` don't define struck-row matching (pre-existing gap) | Informational | `docs/reviews/override-log.md:129`; `skills/code-review/SKILL.md:173-181` | High |

## Overall Assessment

The fix commit keeps the `code-review` contract coherent. k is now determined by `--loop-pass` alone, which is what pr-prep and review-fix-loop already assume. The Gate-1h-parsed `**Replication:**` header gains no new values. The decision-record and override-log edits follow repo conventions, and the strikethrough follows the documented SKILL.md:1260 rule. The one convention miss is small and fixable in place: row 60's amendment lacks the bold dated marker the log's other in-place amendments use. That fix would also clear fact-check claim 8. No consumer-breaking change.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your role section names, structured per your role skill, every finding/claim carrying verbatim Evidence with `path:line`, and a Goal-Alignment Note appended.
- Answered: yes
- Out of scope: 27d483b's original change and the 09d62ad review artifacts (context only per the shared block); Step 3.5 struck-row matching rule (pre-existing, recommended as a follow-up).
- Escalate: nothing
- Decisions I made: resolved the fact-check's strikethrough escalation as "convention followed" using SKILL.md:1260 (per the orchestrator note), and rated the Step 3.5 gap Informational because this commit did not introduce it.
