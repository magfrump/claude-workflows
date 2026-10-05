Commit: 1d79ffef

# Security Review — feat/build-loop-u1b (review-fix iteration 3, final)

**Scope:** `feat/build-loop-u1a...feat/build-loop-u1b` at 1d79ffef: `scripts/build-loop.sh` (`--settings`), `test/lib/build-loop-fixtures.bash`, `test/scripts/build-loop-read.bats`; `scripts/lib/dev-cycle-read.sh` read for context (unchanged)
**Date:** 2026-10-05
**Based on:** Stage-1 merged fact-check `docs/reviews/code-fact-check-report-build-loop-u1b.md` at 1d79ffef (escalations E1 and E3 are answered here); plan `docs/working/plan-build-loop-handoff.md` D5, D6, F38, F56; override-log rows C18 and C19
**Probes:** run in `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i3/security/` against throwaway repos (`git init -b main`, hermetic git env, `bash scripts/build-loop.sh --settings`), git 2.39.5. `bats test/scripts/build-loop-read.bats` passes 9/9 at 1d79ffef.

## Trust Boundary Map

```
B1: [docs/dev-cycle.md blob on MAIN_SHA]   → [FENCE_AWK + SETTINGS_AWK letters-only key count (build-loop.sh:96-111)] → [POLICY / SLOTS / NEVER]
B2: [Self-merge never: line text]          → [single-space check + next-line check + globform (build-loop.sh:148-164)] → [NEVER array, consumed by U2's gate]
B3: [git refs and repo config: origin/HEAD, refs/heads/*, refs/replace/*, .git/config core.useReplaceRefs] → [resolve_main / main_by_name (lib), GIT_NO_REPLACE_OBJECTS (build-loop.sh:63)] → [MAIN_SHA, "the default branch's commit"]
B4: [repo text reaching stdout/stderr]     → [scrub_reexec / scrub (lib:48-81)] → [orchestrator transcript]
```

```
S1: docs/dev-cycle.md on main   — runtime-mutable (the user's or orchestrator's commits; N-denied to
                                   loops by the floor, plan F12/F56, so a loop reaches it only through a
                                   human-merged review-mode change)
                                — UNTRUSTED for printing (B4); trusted as the author's intent for the
                                   policy, but its parse must fail closed wherever the rendered file and
                                   the parsed value can disagree (B1, B2)
S2: local refs and .git/config (origin/HEAD, refs/heads/*, refs/replace/*, core.useReplaceRefs)
                                — runtime-mutable by any process with the uid, a build loop included
                                   (in-model: plan F38, override row C18)
                                — UNTRUSTED for "which commit and which blob is main" (B3)
S3: caller environment (DEV_CYCLE_SCRUBBED, GIT_*, LC_ALL) — set by the orchestrator — trusted (documented)
S4: code constants (SETTINGS_AWK, NAMECHARS, the key strings) — code-constant — trusted
```

Repo text enters only through S1 and is printed only after validation (the never globs) or not at all (policy and slots print fixed text plus line numbers). The unit's security claims are: settings come from main's own objects, never a loop-writable source (B3), and any ambiguity in the file fails toward review, or toward self-merge off (B1, B2). Finding 1 is a B3 gap in the replace-ref guard added by 1d79ffef. Finding 2 is a B1/B2 fail-open that remains after the letters-only match. Finding 3 is the E1 second-copy shape, which is a legibility gap.

## Findings

#### 1. A repo-config `core.useReplaceRefs=true` overrides `GIT_NO_REPLACE_OBJECTS=1`, so the A6 replace-ref guard can be bypassed by anyone who can write `.git/`

**Severity:** Medium
**Location:** `scripts/build-loop.sh:62-63`
**Boundary:** B3
**Move:** 11 (guardrail bypass), 1
**Confidence:** High that the mechanism works on git 2.39.5 (reproduced). Medium on reach: the same actor can already retarget origin/HEAD (C18, deferred to U3b), and git ≥2.42's replace-refs refactor may let the environment variable win (not verified here).
**Legibility-target:** for-orchestrator-synthesis

Evidence (`:62-63`):
```
# Read main's own objects: a replace ref could swap in any settings blob.
export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1
```

On git 2.39, `GIT_NO_REPLACE_OBJECTS` is applied when git sets up its environment, and the repo config is read after that. `core.useReplaceRefs` in `.git/config` therefore turns replacement back on. I reproduced it in a throwaway repo. Main's blob reads `Build-loop policy: review`, and `git replace <blob> <blob reading self-merge>` is in place:

| Repo config | `--settings` policy line |
|---|---|
| none | `policy review set: line 1 of docs/dev-cycle.md on the default branch` (the guard works) |
| `git config core.useReplaceRefs true` | `policy self-merge set: line 1 of docs/dev-cycle.md on the default branch` |

The same happens with a commit replace (main's commit replaced by a loop commit) once the config line is set. Raw git confirms it: `GIT_NO_REPLACE_OBJECTS=1 git cat-file blob HEAD:docs/dev-cycle.md` and `git --no-replace-objects cat-file ...` both print the replacement. Two forms do print main's own blob: `git -c core.useReplaceRefs=false cat-file ...` and `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.useReplaceRefs GIT_CONFIG_VALUE_0=false` with the environment variable. The comment at `:62` therefore claims more than the code delivers, and the printed "on the default branch" is false in this state. The impact is the same as iteration 2's Finding 3: on the dispatch and collect paths, a forged policy, slots value or never list routes items and sizes slots. The gate is less exposed, because D6's snippet refuses any `refs/replace/` entry by existence (plan :78, T36), so the config does not affect it. This is not a new class of actor. A uid that can write `.git/config` can also retarget origin/HEAD, and C18 already defers that to U3b's `--state`. What is new is that the A6 fix is bypassable, so the iteration-2 item cannot be closed as resolved.

**Recommendation:** Pin the setting at command-line config precedence for every git call the script and its lib make. One option is `export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.useReplaceRefs GIT_CONFIG_VALUE_0=false` beside `:63`, which I verified reads `review`; note that it overwrites any GIT_CONFIG_COUNT the caller set. Another is to refuse to run when `git for-each-ref refs/replace/` prints anything, as D6 does. Either way, fix the comment at `:62` to match. If the orchestrator would rather not spend lines at the 400 cap, log it as an extension of C18 (same actor, same revisit trigger: U3b's `--state` already refuses `refs/replace/`, plan T42), with this probe as evidence.

#### 2. A sole `Self-merge never:` line whose key letters are changed (homoglyph, entity, checked task box, mid-line HTML, link inside the key) reads `never none`, and self-merge stays on

**Severity:** Medium
**Location:** `scripts/build-loop.sh:101-104`, `scripts/build-loop.sh:145`
**Boundary:** B1, B2
**Move:** 11, 3 (fail direction)
**Confidence:** High on the mechanism (reproduced). Low on likelihood: the shape has to reach main's `docs/dev-cycle.md`, which loops cannot self-merge (F56), so it needs the author's own edit or a human-approved review-mode change.
**Legibility-target:** for-orchestrator-synthesis

Evidence (`:101-104`; excerpt ends inside SETTINGS_AWK's main rule, which continues to :106, read):
```
  s = tolower($0); gsub(/[^a-z]/, "", s); k = ""
  if (index(s, "buildlooppolicy") == 1) k = "policy"
  else if (index(s, "buildloopslots") == 1) k = "slots"
  else if (index(s, "selfmergenever") == 1) k = "never"
```
Evidence (`:145`; excerpt ends inside read_settings(), which continues to :179, read):
```
    if [[ -z "${cnt[never]-}" ]]; then NEVER_LINE='never none: no line starts "Self-merge never:"'
```

For the never key, absence is the permissive state: `never_ok` stays 1, and `Build-loop policy: self-merge` is honoured with no never list. The letters-only match fixed every iteration-2 near-miss shape (see "Iteration-2 items" below). It cannot catch a shape that adds letters before the key, adds letters inside it, or replaces a key letter with something that is not ASCII. Each of these probes has `Build-loop policy: self-merge` on line 1 and the shown line 2 as the only never line. Each renders as, or reads to a person as, `Self-merge never: workflows/`:

| Line 2 | `--settings` |
|---|---|
| `Self-merge nev` + U+0435 (Cyrillic е) + `r: workflows/` | `never none`, `policy self-merge set` |
| `Self-merge n&#101;ver: workflows/` | `never none`, `policy self-merge set` |
| `- [x] Self-merge never: workflows/` (also `[X]`) | `never none`, `policy self-merge set` |
| `Self-<b>merge</b> never: workflows/` | `never none`, `policy self-merge set` |
| `[Self-merge](x) never: workflows/` | `never none`, `policy self-merge set` |

These shapes fail closed: a zero-width space or U+2011 inside the key, `Self-merge *never*:`, `**n**ever`, `<br>` after the key, `&#45;` for the hyphen, `- [ ]`, `1.`, a table cell, an indented code block and a wrap (all `never malformed`, self-merge off).

Concrete failure mode: in this repo the interim list is `Self-merge never: workflows/` (D5), which protects exactly the paths that take effect on merge. A review-mode loop change to `docs/dev-cycle.md` that swaps one `e` for U+0435 is a near-invisible diff. Once a human merges it, the list is gone and self-merge is still on. The only trace is the output's `never none` line. A careless `- [x]` on the line has the same effect. The floor and the `Paths:` allowlist still apply, so the damage is bounded to `workflows/`-class paths a brief lists.

**E1/E3 judgment and the C19 premise:** C19's Won't-Fix rests on "the hidden copy cannot raise the policy" and "only an exact line sets anything". That holds for the policy and slots keys: a hidden sole policy line reads `policy review unset` (probe: Cyrillic о in `policy`), which fails closed. It does not hold for the never key, where nothing is the permissive setting, so hiding the line lowers protection without any exact line. C19's other premise, "does not render as the key", does not hold for a homoglyph or a `- [x]` item, which do render as the key. C19's zero-width half has also changed for the better: a zero-width character inside a key is now counted and reads `malformed` (probe), so only the entity half of C19 is still hidden. My severity for the exposure: Medium on the never key (floor rule: a reproduced mechanism, and a human-merged review change is a reachable path), and Low on the policy and slots keys (Finding 3).

**Recommendation:** The orchestrator decides between two fixes. (a) The design-level close: under `Build-loop policy: self-merge`, require a never line, so `never none` also turns self-merge off. Hiding the only never line could then only fail closed, whatever the shape. It costs one line per self-merge repo, and this repo's interim `workflows/` line is already planned for U5. (b) The minimal close for E1's markup shapes: before the letters pass, drop `<...>` tags, a leading `[x]` or `[X]` box, and `](...)` link destinations. That leaves the homoglyph and entity shapes as a C19 extension with the premise corrected for the never key. Don't use a "contains" match, which would count prose mentions of the key that U5's rewrite of `docs/dev-cycle.md` will add, and turn self-merge off.

#### 3. E1: a hidden second copy is ignored, so the exact first line wins over a rendered `- [x]` / inline-HTML / homoglyph copy; the header says markup "cannot hide one"

**Severity:** Low
**Location:** `scripts/build-loop.sh:25-27`, `scripts/build-loop.sh:90-92`, `scripts/build-loop.sh:105`
**Boundary:** B1
**Move:** 11
**Confidence:** High (reproduced)
**Legibility-target:** for-author

Evidence (`:25-27`):
```
#             A line counts as a copy when its letters alone, case folded,
#             start with the key's ("buildlooppolicy"), so markup, a table or
#             a misplaced colon cannot hide one.
```
Probes: `Build-loop policy: self-merge` followed by `- [x] Build-loop policy: review` gives `policy self-merge set: line 1` with no "more than one line" warning. `Self-merge never: a/`, a blank line, then `- [x] Self-merge never: workflows/` gives `never a/ set`, so a reader of the rendered file believes `workflows/` is protected and it is not. The winning line is exact and sits on main, so only main's author can produce the state. That makes this an operator-legibility gap rather than an attacker path, which is why it is rated Low, consistent with iteration 2's Finding 2. The header and the `:91-92` comment state the guarantee categorically (fact-check Claims 8 and 14, Incorrect).

**Recommendation:** Option (b) in Finding 2 also closes this. If neither fix lands in U1b, narrow the two comments to the shapes that are counted ("markup that adds no letters before or inside the key").

## Iteration-2 items in my domain (status at 1d79ffef, verified by running)

| Item | Status | Evidence |
|---|---|---|
| R3 (copy with markup closing before the colon was hidden) | **Resolved** | `Build-loop policy: self-merge` + `**Build-loop policy**: review` gives `policy review unset: more than one line starts "Build-loop policy:" (lines 1 and 2)`. T2 covers it (`build-loop-read.bats:33-37`). |
| A5 (wrapped never line dropped; near-miss keys absent, not malformed) | **Resolved for the iteration-2 shapes; residual open as Finding 2** | Every one of these gives `never malformed`, self-merge off: wrap (`a/` then `  b/`), setext `===`, `**Self-merge never**: docs/ scripts/`, `Self-merge never :`, `Self-merge-never:`, NBSP in the key, `\#`, `- [ ]`, table cell, `[Self-merge never](x):`. The letter-changing shapes in Finding 2 still read `never none`. |
| A6 (`--settings` honoured refs/replace) | **Partly resolved; bypass open as Finding 1** | With no repo config, both the blob replace and the commit replace read `policy review set`. With `core.useReplaceRefs=true` in `.git/config`, both read `policy self-merge set`. No test pins the guard (fact-check E4). |
| C18 (origin/HEAD symref to a loop branch is read as the default) | **Covered by override row C18 (Defer U3b); premise still holds** | `git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/loop` gives `policy self-merge set ... on the default branch`. So does pointing it at `refs/heads/loop` directly. Not re-raised. Finding 1 belongs to the same actor class and can join this row's revisit trigger. |

A8 (NEVER as an array) is resolved at `:164`: `NEVER=("${parts[@]}")` hands U2 checked entries with no shell expansion. Iteration 2's Finding 4 is closed.

## Move 11: guardrail bypass candidates

Guardrail: the SETTINGS_AWK key count (B1). All of these were tested by probe:
- Sole never line: Cyrillic е, `&#101;`, `- [x]`, `- [X]`, `Self-<b>merge</b>`, `[Self-merge](x) never` stay hidden (Finding 2). Zero-width, U+2011, NBSP, `*never*`, `**n**ever`, `<br>`, `&#45;`, `- [ ]`, `1.`, `|…|`, `[…](x):`, ` :`, `-never`, `\#`, indented code, wrap and setext all fail closed.
- Second copy: `- [x]` copies of the policy and never keys stay hidden (Finding 3). R3's bold shape is counted.
- Sole policy line with a homoglyph gives `unset`, which fails closed.
- Prose `Note: Self-merge never: workflows/` reads `never none`. It is not a key line: it renders as prose.

Guardrail: the replace-ref guard (B3). The blob and commit replace are refused without the config. `core.useReplaceRefs=true` bypasses the guard (Finding 1), and so does `--no-replace-objects` in the raw check.

Guardrail: the never-line form (B2). T45's rows (tab, double space, `..`, `/`, `-`, non-ASCII, duplicate, `./`) pass in the 9/9 bats run.

Untested bypass candidates:
- An exact key line inside a multi-line inline construct (a link title, a code span or an open tag attribute spanning lines). Not run: it is the lib's accepted limit (decision log 69, settled for U1a), and only main's author can write it.
- The precedence of `GIT_NO_REPLACE_OBJECTS` over `core.useReplaceRefs` on git ≥2.42. Not run: only git 2.39.5 is installed in the sandbox.
- Caller-set `GIT_DIR`, `GIT_CONFIG_*` and similar environment variables. Not run: S3 is trusted (set by the orchestrator).

## Endorsement Claims

- **Claim:** The policy and slots lines print no repo text besides line numbers. The never line prints the value only after every entry has passed globform (NAMECHARS plus `*` `?`, with single spaces).
  **Location:** `scripts/build-loop.sh:143-177`
  **Evidence:** read-static, plus the T45 no-echo assertion executed (`build-loop-read.bats:117-118`, passing)
  **Verified:** every assignment to POLICY_LINE, SLOTS_LINE and NEVER_LINE in read_settings, read in full, and T45's malformed rows.
  **Not verified:** that `many()`'s line numbers are numeric for any input. They come from awk's NR, which was read, not fuzzed.
  **route: code-fact-check**
- **Claim:** A never line followed by a non-blank, non-fence line (a wrap, an indented continuation, a setext underline) is malformed and turns self-merge off (A5 wrap).
  **Location:** `scripts/build-loop.sh:100`, `scripts/build-loop.sh:152`
  **Evidence:** executed (probes `wrap` and `setext`; T45 `build-loop-read.bats:132-133`)
  **Verified:** both probes print `never malformed: line 2 is followed by a non-blank line`, together with `policy review unset`.
  **Not verified:** a continuation that starts after a fenced block that follows the never line. I read the awk logic (`fence($0) { next }` runs before the NEXT update), but did not run it.
  **route: code-fact-check**
- **Claim:** When refs and `.git/config` are not modified, the working tree, the current branch and a linked worktree do not change `--settings` output.
  **Location:** `scripts/build-loop.sh:63-65`, `test/scripts/build-loop-read.bats:78-88`, `:169-178`
  **Evidence:** executed (T4 and test 9 pass)
  **Verified:** the T4 and test-9 assertions.
  **Not verified:** loop-written refs or config (Finding 1, C18). This claim is scoped to unmodified refs and config.

## Primitive sweep

Primitive: a git object read meant as "main's own object" (the trust source)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:82` `git cat-file blob "$MAIN_SHA:$f"` | S1 via S2 | main_entry blob check; GIT_NO_REPLACE_OBJECTS (`:63`) | Finding 1 (config override) |
| `scripts/lib/dev-cycle-read.sh:263` `git ls-tree` (main_entry, via `:74`) | S2 | the same environment variable | Finding 1 (same fix) |
| `scripts/lib/dev-cycle-read.sh:387-409` resolve_main (via `:64`) | S2 | `-*` skip, `show-ref --verify`; `rev-parse ^{commit}` under the same environment variable | C18 (settled, premise holds); commit replace is covered by Finding 1 |

Primitive: shell glob expansion of repo text
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:155` `IFS=' ' read -ra parts <<<"$v"` | S1 | here-string, no expansion | cleared |
| `scripts/build-loop.sh:164` `NEVER=("${parts[@]}")` | S1 | quoted array, entries passed globform | cleared (A8 resolved) |

Primitive: `sed -n '2,34p' "$0"` (help, `:53`). Its path is the S4 script itself and it reads no repo text: cleared.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `core.useReplaceRefs=true` overrides `GIT_NO_REPLACE_OBJECTS`; the A6 guard is bypassable | Medium | B3 | `scripts/build-loop.sh:62-63` | High (git 2.39.5) / Medium reach |
| 2 | A sole never line hidden by a homoglyph, an entity, `- [x]`, inline HTML or a link inside the key reads `never none`; self-merge stays on | Medium | B1, B2 | `scripts/build-loop.sh:101-104`, `:145` | High mechanism / Low likelihood |
| 3 | E1: a hidden second copy is ignored; the header says markup "cannot hide one" | Low | B1 | `scripts/build-loop.sh:25-27`, `:90-92` | High |

## Overall Assessment

1d79ffef closes most of what iteration 2 raised in my domain. R3 and A8 are resolved, and so is every iteration-2 A5 shape, the wrap included. No HALT pattern. Two Medium items remain, and each fixes in place or routes to an existing row:

- **Finding 1:** the A6 guard is defeated by one repo-config line. Same actor as C18, so the fix can be one exported config pair or a C18 extension.
- **Finding 2:** for the never key, hiding the only line is fail-open. C19's "cannot raise the policy" premise does not cover that.

Neither suggests an architectural problem. The most important item is Finding 2, because it is the last way an edit that renders as the protective line can silently disable it. Option (a), requiring a never line under self-merge, closes every shape at once. The orchestrator may instead file the residual as a corrected-premise C19 extension. There are no further findings in the code paths read. The first two endorsement claims are pending execution verification.

## Goal-Alignment Note

- **Success criterion (verbatim):** A markdown report saved to docs/reviews/security-reviewer-review-2026-10-05-build-loop-u1b.md, structured per the security-reviewer skill.
- **Answered:**
  - Security design review of U1b at 1d79ffef, with 3 findings (2 Medium, 1 Low).
  - E1: the second-copy shapes are Low, an operator-legibility gap (Finding 3). The sole-line shapes on the never key are Medium (Finding 2).
  - E3: a homoglyph is the same exposure as Finding 2. It is Medium on the never key and fails closed on policy and slots.
  - Status of R3, A5, A6 and C18, each verified by probe.
- **Out of scope:** E2 and E4 (test gaps; test-strategy's). U1c (`--status`, the constraints line) and U2's gate code, apart from noting that D6's existence check is unaffected by Finding 1.
- **Escalate:**
  - The C19 premise ("the hidden copy cannot raise the policy") does not hold for the never key, where absence is the permissive state. Its zero-width half no longer applies, because such a copy is now counted.
  - A6 cannot be closed as resolved while `core.useReplaceRefs` overrides the guard. The orchestrator decides between a fix and a C18 extension.
- **Decisions:**
  - Finding 2 is rated Medium under the floor rule: the mechanism is reproduced, and a human-merged review-mode change is a reachable path. Likelihood went to Confidence.
  - Finding 3 is kept at Low, as in iteration 2, because the winning exact line needs main's author.
