Commit: c143b929

# Security Review — feat/build-loop-u1c, final confirming pass (iteration 2)

**Scope:** `git diff feat/build-loop-u1b...feat/build-loop-u1c` at c143b929 (scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh header, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats)
**Date:** 2026-10-05
**Based on:** docs/reviews/code-fact-check-report-build-loop-u1c.md (Stage-1 merged, k=3), Escalation on Claim 8; iteration-1 rubric at 553a50d5; fix commit c143b929
**Threat model:** a build loop can write any branch and working tree but not main; `--settings`/`--status` output gates dispatch and (later) self-merge.

All probes ran in throwaway repos under `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i2/security/` against `bash scripts/build-loop.sh` from this worktree. `bats test/scripts/build-loop-read.bats`: 16/16 pass at HEAD.

## Trust Boundary Map

```
B1: [loop-written branch tip (refs/heads/<Branch:>)] → [check_branch show-ref --verify; marker_kind via git's own parse] → [--status LOOP field (ready|blocked|stopped|working|skip)]
B2: [docs/constraints.md on main's commit]          → [main_file + FENCE_AWK + CONSTRAINTS_AWK]                       → [--settings "constraints ok|missing|none-hard|unreadable" (dispatch gate)]
B3: [brief files on main (briefs/ and briefs/closed/)] → [brief_fields / shared_branches (F31)]                        → [--status ok/skip per brief]
B4: [argument path + working tree]                  → [check_brief pathform/isbrief/blocker]                          → [main-commit read of the brief]
```

| Label | Source | Mutability | Trust classification (per sink) |
|---|---|---|---|
| S1 | Branch tip commit object (tree, parents, message, encoding header) | request-time (any loop can write) | UNTRUSTED for the LOOP verdict and printed REASON; the loop is entitled to write a marker, so "ready" itself is not an escalation, but divergence from git's parse is |
| S2 | docs/constraints.md blob on main | runtime-mutable by the owner only (F54: N-denied for loops; read from main's commit) | trusted author, UNTRUSTED as to shape (owner mistakes must fail closed per Q-112 [1]) |
| S3 | Brief blobs on main (Status/Branch/Policy/Dispatched) | owner-written | trusted author; shape-checked before use as a git ref name |
| S4 | Repo object store / .git (shared by every worktree) | writable by any process with the uid | outside this unit's model (rows 252, 273); noted only where a read failure fails open |
| S5 | CLI argument BRIEF paths | request-time (orchestrator) | pathform + blocker before any read |

What enters: loop-controlled commit objects (S1) and owner-written repo files read only from main's commit (S2, S3). The diff's trust assumption is that main's files are owner-authored and that every shape the readers cannot classify fails closed; iteration 1's fixes move the marker parse to git (B1) and widen the constraint refusal (B2). The residue below is all on B2/B3's fail-closed promise.

## Iteration-1 fixes: do they hold?

- **A1 (marker read through git)** — holds. `marker_kind` (`scripts/build-loop.sh:273-293`) takes parents from `git rev-list --parents -n 1`, the tree from `rev-parse ^{tree}`, the message from `git log -1 --format=%B`, and counts NUL bytes in the raw object. Executed: duplicate `parent` lines → "it has 2 parents"; two-tree object → "it has no parent" (T7); `encoding UTF-7` with `handoff: +AHI-eady` → skip; `encoding ISO-8859-1` `stopped: café` → skip; message starting with a blank line → `working`; whitespace-only second line → skip; `encoding UTF-16` and a stray `gpgsig` header with the plain subject → `ready` (raw and git's reading agree). No regression found.
- **R1 (near-miss constraint lines)** — narrowed, not closed: see Finding 1 (shapes that still drop a hard constraint under `ok`) and Finding 2 (help text).
- **A4/A5 (closed/ counts; set computed on first use)** — holds for readable briefs (executed: an open brief in closed/ naming the same branch makes the briefs/ one skip; `status_line` calls `shared_branches` at `:326`; it only clobbers `BRIEF` after the last `BRIEF` read at `:325`). Residue in Finding 3 (Informational).
- **A8 (C-locale grep)** — holds: `LC_ALL=C grep -qxE` at `:291`; the non-ASCII reasons in T7 and my latin1/UTF-7 probes skip.

## Findings

#### 1. A hard constraint behind a checked task box, a letter or roman list marker, or a leading word is still uncounted while the line reads `constraints ok`

**Severity:** Medium
**Location:** `scripts/build-loop.sh:172-173` (near-miss rule), `:164` (exact form)
**Boundary:** B2
**Move:** 11 (enumerate bypasses for every guardrail), 3 (error path)
**Confidence:** High (mechanism, executed); impact Medium
**Legibility-target:** for-orchestrator-synthesis

Evidence (`scripts/build-loop.sh:172-173`):
```
{ s = $0; sub(/^[^a-zA-Z]*/, "", s); s = tolower(s); gsub(/[^a-z0123456789]/, "", s) }
s ~ /^[hs][0123456789]/ { if (bad == "") bad = "near " NR; next }  # looks like an ID but is not exact
```

The near-miss rule starts at the line's first ASCII letter, so any marker that contains a letter hides the ID. Executed with `- H1: a` / `  success: b` / then the third line below, each printed `constraints ok 1-hard 0-soft`: `- [x] H2: never push`, `- [X] H2: c`, `a. H2: never push`, `i. H2: x`, `Hard H2: never push`, `**Hard:** H2: never push`, `Note - H2: x`. The unchecked box `- [ ] H2: c` is refused (unreadable), so ticking a box in a constraints checklist turns a refused line into a silently uncounted one. This is the exact report trigger Q-112 [1] names ("a hard constraint can still be silently dropped while the line reads `constraints ok`"), and the help (`:35-37`) describes the first-letter rule accurately, so it is a design residue, not a doc error. Impact: the dropped line is still quoted whole in every loop prompt (plan :227), so the loop sees the text; what is lost is the gate's guarantee that every hard constraint carries a `success:` line and the count the orchestrator reports. No loop can author the file (F54), so the trigger is an owner's ordinary Markdown, not an attacker; I keep Medium under the floor rule because the mechanism is concrete and the environment (an owner writing a GFM checklist) is the normal one. Override-log: no row covers this (row 256 covers settings-key copies, whose premise "only an exact line ever sets a value" does not transfer: here an uncounted line removes a check rather than failing to set a value).

**Recommendation:** Strip a leading task box (`[ ]`, `[x]`, `[X]`) and a short list label (`[a-zA-Z]{1,4}[.)]`) before folding, or apply the near-miss test to any `[hs]<digit>` token preceded by a non-alphanumeric within the line's first few words; Q-112 accepts the extra false positives. Add `- [x] H2:` and `a. H2:` to T44's near-miss loop.

#### 2. The constraints help states the near-miss and heading rules more broadly than the code applies them (fences, non-ASCII look-alikes, Setext and indented headings)

**Severity:** Low
**Location:** `scripts/build-loop.sh:33-37` (help), `:163`, `:172`, `:174`
**Boundary:** B2
**Move:** 2 (implicit sanitization assumption), 11
**Confidence:** High (executed)
**Legibility-target:** for-author

Evidence (`scripts/build-loop.sh:33-37`):
```
#                 leading 0; a hard one needs a "success: <observable>" line
#                 (any indent, optionally after "- ") before the next
#                 constraint or heading, and no ID may repeat. Any other line
#                 whose letters and digits, from its first letter, start like
#                 "h1" or "s1" makes the file unreadable. Only "ok" lets the orchestrator dispatch.
```
and (`:174`):
```
/^#/ { if (bad == "" && pend != "") bad = "nosuccess " pend " " pendl; pend = ""; next }  # a heading ends a pending one
```

Executed, each printed `constraints ok 1-hard 0-soft`: a fenced block holding `H2: never push`; Cyrillic `Н2:`, fullwidth `Ｈ2:`, `H²:`, and `&#72;2:` (renders as `H2:`). And `- H1: ...` followed by a Setext heading (`Other section` / `---`) or an indented ATX heading (`  ## Other`) and then `- success: unrelated` printed `ok`, so a success line from another section satisfies H1. The help says "Any other line" and "letters and digits" (no "outside a fence", no "ASCII") and "heading" (only column-0 `#` counts). Fence-skipping is intended (plan :204, "read under FENCE_AWK"), and the look-alikes are Q-112's accepted best effort, so this is the second Q-112 trigger (the help misdescribes the rule), not a code defect. Escalated Claim 8: my severity is Low for the fence/look-alike part, because the fenced or look-alike line is still carried verbatim to the loop and no loop can write the file; the fix is wording.

**Recommendation:** Say "outside a code fence", "ASCII letters and digits (best effort)", and "a heading (a line starting #)" in the help; optionally treat a Setext underline (`^(=+|-+)[ \t]*$` after a non-blank line) as a heading.

#### 3. shared_branches treats a brief it cannot read as not open, so F31 fails open when another brief's blob or tree cannot be read

**Severity:** Informational
**Location:** `scripts/build-loop.sh:301-303`
**Boundary:** B3 (S4)
**Move:** 3 (error path)
**Confidence:** High (executed); reachability depends on S4
**Legibility-target:** for-author

Evidence (`scripts/build-loop.sh:301-304`, remainder of the function `:305-309` builds the set):
```
  list="$(git ls-tree --full-tree --name-only "$MAIN_SHA" -- docs/working/briefs/ docs/working/briefs/closed/)"
  while IFS= read -r f; do
    if ! isbrief "${f/closed\//}" || ! brief_fields "$f"; then continue; fi
    [[ "${BRIEF[status]-}" == "Status: open" && "${BRIEF[branch]-}" =~ ^Branch:\ ([^\ ]+)$ ]] || continue
```

Executed: two open briefs name `feat/x` (one in briefs/, one in closed/); before damage the queried one skips. After deleting the closed/ brief's loose blob, `--status` prints `ok … open review feat/x absent - - 0`, exit 0 (stderr carries cat-file's `fatal:`). Deleting the closed/ tree object instead exits 1 with no line (fails closed). A brief FENCE_AWK refuses is also not counted, which is harmless (that brief is itself a skip). Only `BRIEF_ODD=error` is the fail-open case, and reaching it needs write access to the shared object store, which is outside this unit's model (rows 252/273 class). Not a regression of A4/A5; it is the residue of A5's "fail closed" intent.

**Recommendation:** When `brief_fields` returns 1 with `BRIEF_ODD == error` inside `shared_branches`, mark the set unusable (e.g. a sentinel that makes every open brief skip with "the default branch's briefs could not all be read").

## Untested bypass candidates

- Repo config that changes `git log --format=%B` output (`log.showSignature`, `i18n.logOutputEncoding`) — not tested; needs write access to the shared `.git/config`, where the loop could do worse (core.fsmonitor); plan D6/U3b own config hygiene.
- `refs/heads/<Branch:>` as a symref to another loop's branch (not main) — row 247/209 class; not re-tested here.

## Endorsement Claims

- **Claim:** For the crafted tip objects tested, `marker_kind` reads parents, tree and subject as git does: duplicate-parent, two-tree, orphan, merge, non-empty, NUL, UTF-7 and Latin-1 encoded `handoff:` tips are skips, and a leading-blank message reads `working`.
  **Location:** `scripts/build-loop.sh:273-293`
  **Evidence:** executed
  **Verified:** T7 plus nine `hash-object --literally` probes in scratch repo `m1`.
  **Not verified:** how U3b's `--marker` and the D7 gate read the same tip (separate code, not yet written).
  **route: code-fact-check**
- **Claim:** An open brief stored under `docs/working/briefs/closed/` that names the same branch (case-folded) as an open brief in `briefs/` makes the latter skip, and `status_line` builds the shared set itself on first use.
  **Location:** `scripts/build-loop.sh:298-309`, `:326-329`
  **Evidence:** executed
  **Verified:** T28 and probe repo `f1` (before damage).
  **Not verified:** a brief whose blob cannot be read (Finding 3).
  **route: code-fact-check**
- **Claim:** The STOPPED reason printed on a `--status` line is limited to 1-120 printable ASCII bytes with no blank at either end, checked in the C locale.
  **Location:** `scripts/build-loop.sh:289-292`
  **Evidence:** executed
  **Verified:** T6/T7 (escape, UTF-8, bidi, 121 chars) and Latin-1/UTF-7 encoded probes.
  **Not verified:** the scrub's handling downstream of this line in the orchestrator.
  **route: code-fact-check**

## Primitive sweep

Primitive: git invocation with repo-derived arguments (ref/revision injection)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:378` `show-ref --verify refs/heads/$a` | S3 Branch: name | NAMECHARS, no leading `-`, check-ref-format, not HEAD/refs/*, not main | cleared |
| `scripts/build-loop.sh:276-282` rev-list/log/cat-file/rev-parse `$1`, `${p[1]}` | S1 tip SHA | 40-hex from show-ref + `^{commit}`; parent from git's own parse | cleared |
| `scripts/build-loop.sh:301` `ls-tree $MAIN_SHA -- …` | code constants | GIT_LITERAL_PATHSPECS | cleared |
| `scripts/build-loop.sh:128` `cat-file blob $MAIN_SHA:$f` | code constant paths | main_entry blob check | cleared |
| `scripts/lib/dev-cycle-read.sh:297` brief_fields `cat-file blob $MAIN_SHA:$1` | S5 / ls-tree names | pathform + main_entry | cleared |

Primitive: bash arithmetic / associative subscripts on repo text
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:305` `n[$b]=$(( ${n[$b]-0} + 1 ))` | S3 Branch: value | value expanded once as a key; arithmetic sees only stored counts | cleared |
| `scripts/build-loop.sh:308` `[[ "${n[$b]}" -lt 2 ]]` | own counts | numeric values only | cleared |
| `scripts/build-loop.sh:337` `[[ "$ahead" -gt 0 ]]` | rev-list --count output | git-produced integer | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Hard constraint behind `- [x]`, `a.`, `i.` or a leading word is uncounted under `constraints ok` | Medium | B2 | `scripts/build-loop.sh:172-173` | High |
| 2 | Help omits "outside a fence", ASCII-only, and column-0-`#`-only headings | Low | B2 | `scripts/build-loop.sh:33-37`, `:174` | High |
| 3 | shared_branches skips an unreadable brief, so F31 fails open on object damage | Informational | B3 | `scripts/build-loop.sh:301-303` | High |

## Overall Assessment

The iteration-1 security fixes hold: marker parsing now goes through git and every crafted object I built either reads as git reads it or skips, the closed/ scope and first-use computation of the shared-branch set work, and no regression turned up in the probes or the 16 tests. The remaining issue is R1's residue: the near-miss rule anchors on the first ASCII letter, so a ticked task box or a letter-labelled list item still leaves a hard constraint uncounted while the gate line reads `ok` (Finding 1). That is the case Q-112 [1] asked to be reported, and it can be fixed in place with a small marker-strip plus two test cases. Findings 2 and 3 are wording and hardening. No findings within the other code paths read; endorsement claims pending execution verification by code-fact-check.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved at the output path your task names, structured per your skill, with a `Commit: c143b929` first line.
- Answered: security design review of the U1c unit diff at c143b929; R1/A1/A4/A5/A8 fixes checked by execution; escalated Claim 8 weighed against Q-112 [1] (fence and look-alike residue: Low, help wording; checked-box/letter-label residue: Medium, silent drop under `ok`); override-log filter applied (no settled row re-filed; row 256's premise judged not to transfer to Finding 1).
- Out of scope: U2/U3b gate, `--marker`, `--start` and D6 snippet behaviour; review-artifact docs; repo config and object-store tampering beyond noting Finding 3.
- Escalate: Finding 1 to the orchestrator: whether the Q-112 [1] residue (ticked task box / letter list labels) is fixed now or recorded as an accepted best-effort shape in the help and the override log.
