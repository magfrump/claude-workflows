Commit: 0ae7d801

# Security Review — feat/build-loop-u1b (review-fix iteration 2)

**Scope:** `feat/build-loop-u1a...feat/build-loop-u1b`: `scripts/build-loop.sh` (`--settings`), `test/lib/build-loop-fixtures.bash`, `test/scripts/build-loop-read.bats`; the enclosing `scripts/lib/dev-cycle-read.sh` read for context (unchanged)
**Date:** 2026-10-05
**Based on:** Stage-1 merged fact-check `docs/reviews/code-fact-check-report-build-loop-u1b.md` (escalations E1, E3 addressed here); plan `docs/working/plan-build-loop-handoff.md` D5, D6, F12, F56
**Probes:** all run in a scratch dir outside the worktree against throwaway repos (`git init -b main`, hermetic git env, `bash scripts/build-loop.sh --settings`); outputs quoted below.

## Trust Boundary Map

```
B1: [docs/dev-cycle.md blob on MAIN_SHA]          → [FENCE_AWK + SETTINGS_AWK key count (build-loop.sh:101-117)] → [POLICY / SLOTS / NEVER]
B2: [Self-merge never: line text]                 → [single-space check + globform (build-loop.sh:155-170)]      → [NEVER, consumed by U2's gate]
B3: [git refs: origin/HEAD symref, refs/heads/*, refs/replace/*] → [resolve_main / main_by_name (lib), git cat-file] → [MAIN_SHA "the default branch's commit"]
B4: [repo text reaching stdout/stderr]            → [scrub_reexec / scrub (lib:76-81)]                             → [orchestrator transcript]
```

```
S1: docs/dev-cycle.md on main      — runtime-mutable (user / orchestrator commits; N-denied to loops, plan F12/F56)
                                      — UNTRUSTED for printing (B4); trusted-as-intent for policy, but its
                                        *parse* must fail closed on ambiguity
S2: local git refs (origin/HEAD, refs/heads/*, refs/replace/*) — runtime-mutable by any process with the uid,
                                      including a build loop (the plan treats loop-written refs as in-model: F38)
                                      — UNTRUSTED for "which commit is main" (B3)
S3: environment (DEV_CYCLE_SCRUBBED, GIT_*) — caller-controlled — trusted (orchestrator sets it; settled/documented)
S4: code constants (SETTINGS_AWK, NAMECHARS, key strings) — code-constant — trusted
```

Repo text enters only through S1 and is printed only after validation (NEVER globs) or not at all (policy/slots print fixed strings plus line numbers). The security property the unit claims is: settings come from main's commit, never a loop-writable source, and an ambiguous or malformed setting fails toward `review` / self-merge off. Findings 1–2 are where the *parse* fails open on ambiguity; Finding 3 and the settled-row note are where "main's commit" is decided by loop-writable refs.

## Findings

#### 1. A wrapped or near-miss `Self-merge never:` line silently drops protections while `policy self-merge` stays set

**Severity:** Medium
**Location:** `scripts/build-loop.sh:152`, `scripts/build-loop.sh:106-110`
**Boundary:** B1, B2
**Move:** 3 (error path), 11 (guardrail bypasses)
**Confidence:** High (reproduced); likelihood depends on how the line is written (operator, not attacker — S1 is N-denied to loops)
**Legibility-target:** for-author

Evidence (`:152`; excerpt ends inside read_settings(), which continues to :185 — read):
```
    if [[ -z "${cnt[never]-}" ]]; then NEVER_LINE='never none: no line starts "Self-merge never:"'
```
Evidence (`:106-110`; excerpt ends inside SETTINGS_AWK's main rule, which continues to :112 — read):
```
  if (match(s, /^([ \t>#*_`~]|[-+][ \t]|[0123456789]+[.)][ \t]|\357\273\277)*/)) s = substr(s, RLENGTH + 1)
  s = tolower(s); k = ""
  if (index(s, "build-loop policy:") == 1) k = "policy"
  else if (index(s, "build-loop slots:") == 1) k = "slots"
  else if (index(s, "self-merge never:") == 1) k = "never"
```

The never list is the per-project extension of D5's floor; the header (`:26-27`) promises that a malformed line turns self-merge off. But only an exact key prefix is recognised, and anything else is classed as *absence* (`never none`), not malformed. Reproduced, each with `Build-loop policy: self-merge` on line 1:

| Line(s) as written | Rendered meaning | Output |
|---|---|---|
| `Self-merge never: docs/` + next line `scripts/` (hard wrap; docs/dev-cycle.md is hard-wrapped prose) | one paragraph: never docs/ scripts/ | `never docs/ set` — `scripts/` dropped, `policy self-merge set` |
| `**Self-merge never**: docs/ scripts/` | bold key | `never none`, `policy self-merge set` |
| `Self-merge never : docs/`, `Self-merge-never: docs/`, `Self-merge<NBSP>never: docs/` | the same setting to a reader | `never none`, `policy self-merge set` |
| `- [ ] Self-merge never: docs/`, `\| Self-merge never: docs/ \|`, `[Self-merge never: docs/](x)`, `\# Self-merge never: docs/` | task item / table / link / escaped heading | `never none`, `policy self-merge set` |

The wrap case is the realistic one: a never list long enough to pass the 100-column wrap that this file's prose already uses (`docs/dev-cycle.md:4-5`) loses every glob after the first physical line, and the output reports `set` with no hint. In this repo the interim list is `Self-merge never: workflows/` (D5), whose purpose is exactly the take-effect-on-merge paths; a dropped entry lets U2's gate self-merge them. The fail direction is open (fewer refusals), contradicting the header's fail-closed promise.

**Recommendation:** Treat a non-blank, non-fence line directly after the never line (a paragraph continuation) as making the line malformed. Recognise the key after removing every non-letter from the stripped prefix (`selfmergenever`, `buildlooppolicy`, `buildloopslots` at the start of the letters-only form), so bold-outside-colon, spacing, hyphen, NBSP, `\#`, `[ ]`, `|` and `[` variants are counted and the line becomes a second/inexact line (fail closed). Add the wrap and `**Self-merge never**:` rows to T45.

#### 2. E1: a bold copy with the colon outside the markup is hidden, so an exact `self-merge` line wins over a visible `review`

**Severity:** Low
**Location:** `scripts/build-loop.sh:28-31`, `scripts/build-loop.sh:106-108`
**Boundary:** B1
**Move:** 11
**Confidence:** High (reproduced)
**Legibility-target:** for-author

Evidence (`:28-31`):
```
#             A line outside a fence counts as a settings line when it
#             starts with the key (any case) after any blanks, >, list
#             markers, # * _ ` ~ and byte-order marks, so a quoted, bold,
#             heading or indented copy is a second line, not a hidden one. A
```
Probe: `Build-loop policy: self-merge` + `**Build-loop policy**: review` → `policy self-merge set: line 1`. Same for the E3 shapes (task item, table cell, link text, leading NBSP, `\#`, `&#66;uild-loop policy:`, double space) — see the Untested/Tested bypass list below.

Threat-model reading: the hidden line can only fail to *lower* the policy; it never raises it. Raising requires the exact `Build-loop policy: self-merge` line on main, and `docs/dev-cycle.md` is N-denied to loops under both policies (plan F12, F56), so only the user or the orchestrator commits it. E1 is therefore an operator-confusion / legibility gap, not an attacker path: a person reading the rendered file sees two policy lines and may trust the bold `review`, while the script reads self-merge with no "more than one line" warning. The A2 fix (30676e57) closed the colon-inside shapes (`**Build-loop policy:** review`, tested at `test/scripts/build-loop-read.bats:33`) but the header claims all bold copies. Rated Low, not Medium: the mechanism needs the user to have written the self-merge line themselves; no reachable actor can produce it.

**Recommendation:** The letters-only key match from Finding 1 closes E1 and most of E3 in the same change. If not adopted in U1b, narrow the header to "bold with the colon inside the bold" and file the residual shapes.

#### 3. `--settings` honours `refs/replace`, so a replace ref written by any uid process changes the policy read "from the default branch's commit"

**Severity:** Medium
**Location:** `scripts/build-loop.sh:69`, `scripts/build-loop.sh:89`
**Boundary:** B3
**Move:** 1 (trust boundaries), 12
**Confidence:** Medium (reproduced; impact is bounded once U2/U3b's D6 snippet refuses replace refs before running the gate, but not on paths outside that snippet)
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```
export GIT_LITERAL_PATHSPECS=1
```
```
  FILE_OUT="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk "$FENCE_AWK$2")"
```
Probe: main's blob reads `Build-loop policy: review`; after `git replace <blob> <blob reading self-merge>` the output is `policy self-merge set: line 1 of docs/dev-cycle.md on the default branch`; with `GIT_NO_REPLACE_OBJECTS=1` it is `policy review set`. The plan treats exactly this capability as in-model (F38, pre-mortem rev 3 experiment E1) but guards it only inside D6's gate snippet. `--settings` (and U1c's `--status`) also run on the dispatch and collect paths, where a forged policy/slots/never value routes items and sizes slots, and the printed line falsely says "on the default branch".

**Recommendation:** Add `export GIT_NO_REPLACE_OBJECTS=1` beside `GIT_LITERAL_PATHSPECS` at `:69` (one line; the lib's readers inherit it). This makes the script's own claim true independently of D6.

#### 4. NEVER is a space-joined glob string for U2; an unquoted expansion there would glob against the checkout

**Severity:** Informational
**Location:** `scripts/build-loop.sh:161`, `scripts/build-loop.sh:170`
**Boundary:** B2
**Move:** 2 (implicit sanitization assumption)
**Confidence:** Medium (depends on U2 code not yet written)
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```
        IFS=' ' read -ra parts <<<"$v"  # not a bare $v: the shell would expand * and ? against files
```
```
      else NEVER="$v"; NEVER_LINE="never $v set: line ${first[never]} $where"; fi
```
U1b avoids pathname expansion itself, but hands U2 a string holding `*` and `?`. A gate that writes `for g in $NEVER` expands `hooks/*.sh` against the working directory, which a loop can populate (or that matches nothing and passes the literal) — the refusal set would then depend on loop-writable state. The R1/A1 tab fix guarantees single-space separation, so splitting is deterministic; expansion is the remaining hazard.

**Recommendation:** Expose NEVER to U2 as an array (or document at `:130-132` that consumers must split with `read -ra` and match through git `:(glob)` only). Carry this into U2's brief.

### Settled-row premise note (override-log row 209, not a new finding)

Row 209 (`feat/build-loop-u0b`, 2026-10-05) deferred "origin/HEAD naming a branch a loop created locally is an untested candidate for resolve_main" to U2/U3. Two premises have shifted:
- It is no longer untested. Probe: main reads `review`; branch `loop` reads `self-merge` and `slots: 9`; after `git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/loop` (no remote configured) `--settings` prints `policy self-merge set: line 1 of docs/dev-cycle.md on the default branch` and `slots 9 set`.
- U1b is the first caller that reads *policy* through it (`scripts/build-loop.sh:70-71`), so the reach is no longer only dev-cycle.sh's digest.

A uid that can write refs could also move `refs/heads/main` outright, so the durable fix is at the orchestrator (pin the MAIN_SHA it recorded, or check origin/HEAD resolves to `refs/remotes/origin/<name>` whose name is main/master), as U2/U3 planned. I recommend the orchestrator decide whether the revisit trigger moves up to U1c's `--status`, which judges briefs with POLICY.

## Move 11: guardrail bypass candidates

Guardrail: SETTINGS_AWK key count (B1). Tested (each with an exact `Build-loop policy: self-merge` or relevant exact line):
- `**Build-loop policy**: review` → hidden (Finding 2).
- `**Self-merge never**: …`, `Self-merge never : …`, `Self-merge-never: …`, NBSP in key, `- [ ] …`, `| … |`, `[…](x)`, `\# …` → hidden, `never none` (Finding 1).
- Hard-wrapped continuation of the never line → dropped (Finding 1).
- `Self-merge never:` then next line `docs/` → malformed, self-merge off (fails closed).
- `Build-loop policy:` then next line `self-merge` → `not exactly`, review (fails closed).
- Setext underline `====` under the exact policy line → still self-merge (same text, renders as heading; not a bypass).

Guardrail: never-line form (B2). Tested via T45's rows and code read: tab, VT/FF/CR, double space, `../`, `/`, `-`, non-ASCII, duplicates all malformed; NBSP inside a value fails globform (NAMECHARS has no high bytes). R1/A1 fix holds.

Untested bypass candidates:
- `&#66;uild-loop policy: review` and zero-width characters in the key (E3) — not run; the letters-only match in Finding 1 would not catch entities, so they would stay hidden. Reason: same class as Finding 2, no new consequence.
- A `Self-merge never:` line inside a Markdown list item that continues across lines with indentation — not run; expected same as the wrap row.

## Endorsement Claims

- **Claim:** Policy and slots lines print no repo text besides line numbers; the never line prints the value only after every entry passed globform (NAMECHARS plus `*` `?`).
  **Location:** `scripts/build-loop.sh:150-183`
  **Evidence:** read-static
  **Verified:** every assignment to POLICY_LINE, SLOTS_LINE and NEVER_LINE in read_settings (`:139-185`); T45 no-echo row at `test/scripts/build-loop-read.bats:115`.
  **Not verified:** the `many()` and `oddwhy` strings print only numbers and fixed text — read, not executed with hostile line numbers (awk NR is numeric).
  **route: code-fact-check**
- **Claim:** A tab, VT, FF or CR in the never value makes the line malformed and turns self-merge off (R1/A1).
  **Location:** `scripts/build-loop.sh:157`
  **Evidence:** executed (T45 rows `a\tb`, `\ta`, `a\t`, `a \tb` pass at 0ae7d801 per the fact-check; probe rows above)
  **Verified:** the explicit character class at `:157` and the T45 rows.
  **Not verified:** that either guard alone is pinned (fact-check Claim 39: neither is tested in isolation).
  **route: code-fact-check**
- **Claim:** The working tree and non-default branches do not change `--settings` output while refs are unmodified.
  **Location:** `scripts/build-loop.sh:89`, `test/scripts/build-loop-read.bats:77-85`
  **Evidence:** executed (T4)
  **Verified:** T4's last assertion; probes "before" rows.
  **Not verified:** loop-written refs (Finding 3, settled-row note) — this claim is scoped to unmodified refs.

## Primitive sweep

Primitive: git object read from MAIN_SHA (the trust source)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:89` `git cat-file blob` | S1 via S2 | main_entry blob check; no GIT_NO_REPLACE_OBJECTS | Finding 3 |
| `scripts/lib/dev-cycle-read.sh:261` `git ls-tree` (via main_entry, `:82`) | S2 | fixed path; same replace exposure | Finding 3 (same fix) |
| `scripts/lib/dev-cycle-read.sh:379-389` resolve_main (via `:70`) | S2 | `-*` skip, show-ref --verify | settled row 209 — premise note |

Primitive: shell glob expansion of repo text
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:161` `read -ra parts <<<"$v"` | S1 | here-string, no expansion | cleared |
| `scripts/build-loop.sh:170` `NEVER="$v"` handed to U2 | S1 | none yet (consumer unwritten) | Finding 4 |

Primitive: `sed -n '2,41p' "$0"` (`:60`, help) — S4 constant path, no repo text: cleared.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Wrapped / near-miss never line drops protections; self-merge stays set | Medium | B1, B2 | `scripts/build-loop.sh:152` | High |
| 3 | refs/replace changes the policy read from "main's commit" | Medium | B3 | `scripts/build-loop.sh:69` | Medium |
| 2 | E1: colon-outside bold copy hidden; exact self-merge wins | Low | B1 | `scripts/build-loop.sh:28-31` | High |
| 4 | NEVER handed to U2 as a glob string | Informational | B2 | `scripts/build-loop.sh:170` | Medium |

## Overall Assessment

The iteration-1 fixes hold: R1/A1 (tabs) is closed, A2 closes the colon-inside markup shapes, and A4's `.git*` allowance only adds refusals. No HALT pattern. The remaining issues are fixable in place and small: one line (`GIT_NO_REPLACE_OBJECTS=1`) for Finding 3, and a letters-only key match plus a continuation-line rule for Findings 1–2, which converts the remaining hidden shapes from fail-open to fail-closed. The single most important item is Finding 1's wrap case, because it is the shape a normal edit to this repo's hard-wrapped settings file produces and it weakens the per-project floor silently. No findings beyond these within the code paths read; endorsement claims pending execution verification.

## Goal-Alignment Note

- **Success criterion (verbatim):** a markdown report saved to /workspace/.claude/wt-build-loop-u1b/docs/reviews/security-reviewer-review-2026-10-05-build-loop-u1b.md, structured per the security-reviewer skill.
- **Answered:** E1 (Finding 2: legibility gap, Low — only the user/orchestrator can write the exact self-merge line, F12/F56) and E3 (Findings 1–2: the same uncounted shapes matter more on the never line, where absence fails open — Medium); iteration 1's R1/A1/A2 weighed (hold, with A2 narrower than the header says); new: refs/replace exposure (Finding 3).
- **Out of scope:** E2 (test `&&` enforcement; test-strategy's) — security note only: the A4 regression it unguards fails closed, so its loss is availability, not exposure. U1c (`--status`, constraints line) and U2's gate code.
- **Escalate:** settled row 209's premise no longer holds (origin/HEAD retarget is now reproduced and reaches the policy reader) — orchestrator to decide whether to move its revisit trigger from U2/U3 to U1c.
- **Decisions:** Finding 2 rated Low under the floor rule because no reachable actor can author the winning exact line (S1 N-denied to loops); Finding 1 rated Medium because a single ordinary edit (rewrap) produces it.
