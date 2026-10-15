Commit: c63da94d

# Security Review — feat/build-loop-u5 (U5: docs, settings, questions), iteration 2

**Scope:** `git diff 42414307..c63da94d` (the iteration-1 fix range: 771a5d02, 57e26f6b, 87ca421e, c63da94d). Read for context: `devcontainer-config/install.sh` (`CLAUDE_HOME_SRC`, `PAYLOAD`, `repo_git`, `git_state_gate`, `extract_commit`, `assemble`), `scripts/lib/dev-cycle-read.sh` (`truthrule`, `floor`, `ownfile`, `writable`, `GATE_CODE`, `HARDEN`, `ANSWER_AWK`), `scripts/build-loop.sh` (`BODY_RULE`), `scripts/questions.sh` (`check`), `scripts/health-check.sh`, `skills/code-review/SKILL.md`, `skills/self-eval/SKILL.md`, `workflows/review-fix-loop.md`. Iteration 1's review and rubric are context only.
**Date:** 2026-10-14
**Based on:** the iteration-2 fact-check results in the dispatch brief (k=1). The dev-cycle.md:29-31 Incorrect, the slots wording, the global-instructions/ fail-closed note, the questions.sh marker note and the two commit-message items are not re-reported.

## Trust Boundary Map

```
B1: build-loop branch tree (same-uid loop)        → gate --merge S rules (floor, never line, Paths:) → main
B2: docs/dev-cycle.md on main's commit            → read_settings / never_res                        → never globs, policy, slots
B3: main first-parent subjects + C..M path names  → SKILL.md step 0.1 withheld rule (moved)          → image-lag entry → questions.sh, ANSWER_AWK
B4: host checkout .git + refs (sandbox-writable)  → Q-156 paste tree pin (new) → install.sh state gate → git archive → host image, ~/.claude, .manifest
B5: merged non-floor files                        → sessions / orchestrator health check            → read as instructions, executed
```

Input-source classification:

```
S1: loop branch tree, commit subjects      — request-time    — UNTRUSTED (all sinks)
S2: docs/dev-cycle.md on main              — runtime-mutable — trusted for gate configuration only (floored); an F19
                                                               main write changes it
S3: main first-parent subjects, C..M paths — runtime-mutable — UNTRUSTED for questions-file / Markdown sinks
S4: host checkout's .git (refs/replace/*, objects, config, info/) — runtime-mutable (bind-mounted rw into
                                                               sandboxes, per install.sh's own header) — UNTRUSTED for
                                                               host exec and for any git read that decides what installs
S5: host checkout's committed root files (.gitattributes, README.md) — runtime-mutable via an F19 main write —
                                                               UNTRUSTED for archive-shaping sinks
S6: pinned M = 771a5d028e8ef8a61253ad2f167ab421225d5af2 — code-constant in the entry — trusted as a name; what it
                                                               resolves to depends on S4
S7: docs/evaluation-rubric.md, docs/spikes/** — runtime-mutable via self-merge (off the floor and the never line) —
                                                               UNTRUSTED for instruction sinks (read as authority)
```

The fix range widens the never line (B2), moves step 0.1's subject copy behind a withheld rule (B3), and adds a tree pin to Q-156's paste (B4). The pin assumes that "the trees named by `HEAD:$p` equal M's" means "install.sh installs M's content". Findings 1 and 2 show that this does not hold while git honors replace refs and the root `.gitattributes`. Finding 3 shows two docs surfaces the widened never line's prose still leaves out. Finding 4 covers what the withheld rule leaves to formatting.

## Findings

#### 1. Q-156's tree pin is bypassed by a replace ref or a root `.gitattributes`, both outside what it compares

**Severity:** Medium
**Location:** `docs/working/questions.md:491`, `:494`
**Boundary:** B4
**Move:** 11 (bypass enumeration), 4 (TOCTOU), 1 (per-consequence trust)
**Confidence:** High for the mechanism (executed in a scratch repo). Medium for impact: install.sh still shows its payload diff before the y prompt, and both bypasses need an F19-class writer (one who can write main or `.git`).
**Legibility-target:** for-author

Evidence: the paste is `( M=771a5d02…; test "$(git rev-parse HEAD)" = "$(git rev-parse refs/heads/main)" || …; for p in devcontainer-config global-instructions guides hooks patterns scripts skills workflows; do test "$(git rev-parse "HEAD:$p")" = "$(git rev-parse "$M:$p")" || …; done ) && ./devcontainer-config/install.sh`. The prose claims that "it refuses when main has moved those paths past what this entry lists". This does close iteration 1's F2 tautology against a plain move of main. In a scratch repo, the planted-commit case is refused when no replace ref exists (`no-replace: refused scripts`). Two bypasses remain, both executed in `/home/node/.claude/jobs/00bcf178/tmp/u5/sec-i2/`:

- **(a) Replace ref.** `git replace $M $X`, with main moved to X (attacker trees), makes `git rev-parse "$M:$p"` resolve through X. Both sides are equal, and the output was `paste check B passed`. `rev-parse` honors `refs/replace/` by default. The repo's own hardened reader turns this off (`HARDEN=(core.useReplaceRefs=false …)`, `scripts/lib/dev-cycle-read.sh:354`), and the paste does not. Writing `refs/replace/*` needs only `.git` write access, which install.sh's header says "an agent or a cc-isolated container can write".
- **(b) Root `.gitattributes`.** A commit on main that changes only the root `.gitattributes` (adding `scripts/a.sh export-ignore`) leaves every compared tree equal (`same scripts`, `same devcontainer-config`). `git archive HEAD -- scripts devcontainer-config` then omitted `scripts/a.sh`. `git archive` reads attributes from the archived commit, so `export-ignore` drops payload files and `export-subst` rewrites their contents. `extract_commit` checks only that each top-level item exists (`cat-file -e "$commit:$item"`). Because `.gitattributes` is a dot path, the floor refuses it for self-merge, so (b) needs a plain write to main (F19).

In both cases install.sh shows the result as a payload diff, so a careful human still sees it. What fails is the entry's claim that the reviewed listing binds what installs. Iteration 1's F2 asked for exactly that binding.

**Recommendation:** Run the paste's git calls as `git -c core.useReplaceRefs=false rev-parse …`, or prefix the subshell with `GIT_NO_REPLACE_OBJECTS=1`, and add `.gitattributes` to the compared paths (`git rev-parse HEAD:.gitattributes` is empty on both sides when the file is absent, so the comparison still works). Alternatively, refuse when `git for-each-ref refs/replace` prints anything. Finding 2 is needed as well, because install.sh's own archive honors replace refs.

#### 2. install.sh's archive honors `refs/replace/`, which `git_state_gate` does not check, so committed-content installs and the `.manifest` stamp can diverge (pre-existing, outside the range)

**Severity:** Medium
**Location:** `devcontainer-config/install.sh:180-182` (`repo_git`), `:208-252` (`git_state_gate`), `:279` (`archive`)
**Boundary:** B4
**Move:** 1, 4, 12
**Confidence:** High for the git behavior (executed: `git archive HEAD -- scripts` printed `EVIL` after `git replace <good blob> <evil blob>`, with main unmoved and the paste's tree pin passing). install.sh itself was not run. Its `archive` call uses the same git with only `core.hooksPath` and `core.fsmonitor` overridden.
**Legibility-target:** for-author

Evidence: `repo_git() { git --no-optional-locks -C "$REPO_ROOT" -c core.hooksPath=/dev/null -c core.fsmonitor=false "$@"; }`. The state gate refuses only `^(filter\.|core\.fsmonitor|include|hook\.)` keys and a non-empty `info/attributes`. A replace ref on any blob or tree under M changes what `git archive` writes, and it leaves every tree name intact. So this defeats step 0.1's fixed pin (`test HEAD = M`) as well as Q-156's. install.sh then stamps `.manifest` with `commit=M`. The next cycle's step 0.1 compares C to main through `hg`, which sets `GIT_NO_REPLACE_OBJECTS=1`, and reads the true objects. It can answer "Exit 0: the image holds main's gate code" while the image carries the replaced content. The payload diff before y is the remaining control. This is the same container-to-host persistence class that `git_state_gate` exists for ("the state persists after the writer has stopped"), and replace refs are a gap in it. U5 does not introduce this, but verify item (1) depends on it: the Q-156 pin cannot bind what install.sh archives until this is fixed.

**Recommendation:** Add `-c core.useReplaceRefs=false` to `repo_git`, matching `HARDEN`. Have `git_state_gate` also name any `refs/replace/*` ref. Under decision 035 this is a boundary change to install.sh, so route it to a questions entry or a follow-up unit, not to this docs unit.

#### 3. The never line's prose says it covers everything that takes effect without a release, but `docs/evaluation-rubric.md` and `docs/spikes/` stay self-mergeable and are read as authority

**Severity:** Medium
**Location:** `docs/dev-cycle.md:42-51`; `docs/working/questions.md:122` (Q-103 [2]), Q-149 [1]
**Boundary:** B1, B5
**Move:** 5 (invert the access model), 1
**Confidence:** Low (reachable only after Q-103 [2], and only when a brief's `Paths:` lists these files. Self-eval output feeds a human review of skill and workflow changes, which the never line already routes to the user.)
**Legibility-target:** for-author

Evidence: the prose reads: "Here it holds every directory whose files take effect in this repo without a release … So in this repo self-merge can land only files outside those directories and off the floor: docs, `README.md`, `runs/` and `archive/`." The floor covers most of `docs/` (`truthrule`: roadmap, questions, briefs, `docs/dev-cycle.md`, `docs/constraints.md`, `docs/decisions/`, `docs/human-author/`; `floor`: `docs/thoughts/*`, plus `docs/working/*` and `docs/reviews/*` other than a brief's own files). So the override log and failure patterns are protected. Two files it leaves open are still read as authority. `skills/self-eval/SKILL.md:53` says: "Read `docs/evaluation-rubric.md` in full — authoritative source for dimension definitions and scoring criteria". Spike records under `docs/spikes/` carry the "RPI seed section; load it when transitioning to implementation". Nothing `@`-imports either file (rg found no `@…evaluation-rubric`), so the floor's import walk does not reach them. A self-merged edit to the rubric lowers the bar for every later self-eval, which is the harm iteration 1's F3 named for `skills/code-review/references/rubric.md`.

**Recommendation:** Add `docs/evaluation-rubric.md` (and `docs/spikes/`, if spike seeds are meant to steer) to the never line. The glob syntax accepts files. Alternatively, narrow the prose to "every directory … sessions read or execute, besides `docs/evaluation-rubric.md` and `docs/spikes/`" and let Q-149 say so.

#### 4. Step 0.1's withheld rule closes iteration 1's F5 breakage but leaves line-start shapes, bidi and non-UTF-8 to the entry's formatting

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:300-306`
**Boundary:** B3
**Move:** 2 (implicit sanitization), 11
**Confidence:** Medium
**Legibility-target:** for-author

Evidence: "each subject or path holding `<`, `>`, a CR or another control byte written as `(withheld: see SHA)` (questions.sh reads `<!--` anywhere in a line)". This prevents F5's two failure modes. A `<!-- index:…` marker cannot appear without `<`, and a CR or an unclosed `<!--` cannot reach FENCE_AWK. Iteration 1's recommendation followed `BODY_RULE` (`scripts/build-loop.sh:933`), which has two more clauses. The withheld rule drops both:

- **Line-start shapes.** BODY_RULE refuses lines starting with "#", `**Needs:**`, `**Status:**`, `**Answer`, or `Q-` and a digit. Commit lines are safe because the `- %h ` prefix puts the hash first. Step 0.1 does not fix the path list's format, though. Q-156 writes paths inline, mid-line (`:489`), which is safe. If an orchestrator writes one path per line, a path named `### Q-157 x` splits the entry. A path named `Q-156: done` becomes the first answer-shaped line in the entry, which `ANSWER_AWK` reads once the entry is marked ANSWERED ("a note above it would be read first").
- **Strict UTF-8.** `questions.sh check` refuses a file that is not valid UTF-8. An LLM transcription probably turns invalid bytes into U+FFFD, so this is unlikely to bite.
- **Bidi.** Bidi controls (U+202E and similar) are not "control bytes", but `--marker` scrubs them. The listing is what the user reads as their release review (F58), so a reordered path name can mislead that review.

The prerequisite is the same one iteration 1 described: a free-text commit on main's first-parent history (F19, or a user commit).

**Recommendation:** Pin the format in step 0.1 ("paths inline on one line, each in backticks"), and add "a bidi control, or a path starting with `#`, `*` or `Q-`" to the withheld set. A script-emitted listing would remove the reliance on prose.

### Untested bypass candidates

- `export-subst` in a root `.gitattributes`, which rewrites `$Format:…$` placeholders in a payload file. Not run. It follows from (b) in Finding 1, where `export-ignore` was executed, and the same fix covers it.
- `objects/info/alternates` and a planted pack supplying a different object under M's name. Not tested: a pinned full SHA-1 cannot be matched without a collision. This is reasoning, not execution.
- A `.git` gitfile in the host checkout that redirects to an attacker git dir. Not tested. It falls under install.sh's existing trust model (decision 035) and is not specific to this range.

Tested and cleared: a forged `objects/info/commit-graph` that swaps M's root tree. Executed: after the byte edit, `rev-parse "$M:scripts"` and `git archive "$M"` still returned the real tree and blob (`good`), so the commit-graph does not steer these reads.

## Endorsement Claims

- **Claim:** At c63da94d every directory the Q-156 paste compares has the same tree as at M=771a5d02, and M..c63da94d changes no path outside `docs/`. So the paste, run with main at the U5 merge, passes its loop.
  **Location:** `docs/working/questions.md:470`, `:494`
  **Evidence:** executed
  **Verified:** `git rev-parse c63da94d:$p` = `git rev-parse $M:$p` for all eight directories, and `git diff --name-only $M c63da94d` holds only `docs/` paths.
  **Not verified:** the merge commit's trees on main (not yet created), and the host checkout's refs/replace state.
- **Claim:** The paste runs only `cd`, `test` and `git rev-parse` before `./devcontainer-config/install.sh`. Every refusal exits the subshell with status 1, and `&&` then skips install.sh.
  **Location:** `docs/working/questions.md:494`
  **Evidence:** read-static
  **Verified:** the paste text, and the `( … exit 1 … ) && ./…` structure.
  **Not verified:** the host shell's aliases or functions named `git` or `test` (host-controlled).
  **route: code-fact-check**
- **Claim:** The compared directory list includes every path install.sh archives from the commit (`CLAUDE_HOME_SRC` = `global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts`, plus `PAYLOAD` under `devcontainer-config/`). The root `.gitattributes`, which shapes the archive, is not in it (Finding 1b).
  **Location:** `devcontainer-config/install.sh:110`, `:135`
  **Evidence:** read-static
  **Verified:** both arrays, and `extract_commit`'s `archive "$commit" -- "$@"`.
  **Not verified:** whether the Dockerfile build reads anything from outside the config dir at image build time.
- **Claim:** The widened never line parses through `--settings` exactly as committed, and the settings suite passes.
  **Location:** `docs/dev-cycle.md:11`; `test/scripts/build-loop-read.bats:79-81`
  **Evidence:** executed
  **Verified:** `timeout 300 bats -f settings test/scripts/build-loop-read.bats` gave 12 ok and 0 not ok.
  **Not verified:** main's committed copy after the merge (the suite reads the fixture).

## Primitive sweep

```
Primitive: host execution of a checkout script (install.sh) after a git-read guard
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `docs/working/questions.md:494` (Q-156 paste) | S4, S5, S6 | HEAD==main, eight-tree pin vs M | Finding 1 (replace ref; root .gitattributes); working-tree install.sh = i1 F7, Won't-Fix (override row) |
| `skills/dev-cycle/SKILL.md:306-307` (step 0.1 paste) | S4, S6 | HEAD==fixed M | Finding 2 (replace refs act at install.sh's archive) |
| `devcontainer-config/install.sh:279` (`git archive` of HEAD) | S4, S5 | git_state_gate (no replace-ref check) | Finding 2 (pre-existing) |

Primitive: untrusted text interpolated into questions.md
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| step 0.1 commit list (`SKILL.md:300-302`) | S3 | `- %h ` prefix + withheld rule | cleared for F5 (markers, CR); bidi part of Finding 4 |
| step 0.1 path list (`SKILL.md:303-305`) | S3 | withheld rule; format unpinned | Finding 4 |
| Q-156 / Q-149 / Q-103 text as written in this range | static | hand-written | cleared: no `<!--`, CR or column-0 answer or heading shapes in the added lines |
```

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Q-156 tree pin bypassed by replace ref or root .gitattributes | Medium | B4 | `questions.md:491,494` | High (mechanism) |
| 2 | install.sh archive honors refs/replace; state gate misses it (pre-existing) | Medium | B4 | `install.sh:180-182,208-252,279` | High (git behavior) |
| 3 | Never-line prose omits docs/evaluation-rubric.md and docs/spikes/ | Medium | B1, B5 | `docs/dev-cycle.md:42-51` | Low |
| 4 | Withheld rule leaves line-start shapes, bidi, non-UTF-8 to formatting | Low | B3 | `SKILL.md:300-306` | Medium |

## Overall Assessment

The fix range closes iteration 1's findings in substance. The never line now covers `devcontainer-config/`, `scripts/`, `test/`, `hooks/`, `skills/`, `guides/` and `patterns/` (F1, F3, F4). Q-103's F58 bullet names the install.sh exception. The withheld rule stops the F5 index truncation. The Q-156 paste is no longer a tautology: in a scratch repo it refuses a plainly moved main. Before install.sh's state gate it runs only `rev-parse`. What it binds is tree names, not archive output. A replace ref (a `.git` write) or a root `.gitattributes` change (a main write) gets past it. Finding 2, a pre-existing gap, means the replace-ref route reaches install.sh's archive and its `.manifest` stamp, and defeats step 0.1's fixed-M pin too. install.sh's payload diff remains the backstop in every case, so nothing here is High. The most important fix is to switch replace refs off in the paste (`-c core.useReplaceRefs=false`), add `.gitattributes` to its compared paths, and route the matching `repo_git` hardening to a follow-up. Finding 3 is a prose and coverage gap that only matters after Q-103 [2]. Within the code paths read there are no other findings. Endorsement claims marked `route: code-fact-check` are pending execution verification.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u5/docs/reviews/security-review-2026-10-14-u5-i2.md, first line `Commit: c63da94d`, structured per the security-reviewer skill.
- Answered: yes. (1) Q-156 closes F2 against a plainly moved main. It adds no git call besides rev-parse before the state gate. Its tree comparison does not bind what install.sh archives (Findings 1, 2). (2) The never line covers every executed or session-read directory. `docs/evaluation-rubric.md` and `docs/spikes/` remain (Finding 3). README.md, runs/ and archive/ have no reader that treats them as instructions or executes them (searched `test/` and `scripts/`). (3) The withheld rule prevents F5's breakage, with residuals in Finding 4.
- Out of scope: the known fact-check items, and i1 F7 (working-tree install.sh, settled Won't-Fix in the override log).
- Escalate: Finding 1 should be fixed in Q-156's paste before the user runs it. Finding 2 needs a decision-035 boundary change to install.sh, so it belongs in its own unit or questions entry.
- Decisions I made: reported Finding 2 although it is pre-existing and outside the range, because verify item (1) asked how the comparison relates to what install.sh archives. Alternative: an Informational note only. Rated Finding 3 Medium under the floor rule, with Low confidence. Alternative: Low, since self-eval is advisory and its subjects are already never-listed.
