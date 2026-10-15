Commit: b5eaedf6

# Security Review — feat/build-loop-u5 (U5: docs, settings, questions), final confirming pass

**Scope:** `git diff main...HEAD` (full branch, 92fa6e52..b5eaedf6), with the iteration-2 fix range c63da94d..b5eaedf6 (659a1c61, b5eaedf6) checked against iteration 2's findings. Read for context: `devcontainer-config/install.sh` (header no-agent gate, `repo_git`, `git_state_gate`, `extract_commit`, `review_diff`, `assemble`), `scripts/lib/dev-cycle-read.sh` (`HARDEN`, its attributes comment), `skills/dev-cycle/SKILL.md` step 0, `docs/working/questions.md` Q-103, Q-149 to Q-156.
**Date:** 2026-10-14
**Based on:** the final fact-check (k=3) results in the dispatch brief. Its Incorrect and Mostly-accurate items (Q-156's "would honor" a graft, the override-row count in b5eaedf6's body, the "only docs, README.md, runs/ and archive/" breadth, Q-103 [2]'s omissions, Q-149's "one-line edit", the slots wording, "If the paste refuses" naming one cause, Q-103's F11 gap list) are known and not re-reported. Prior: `security-review-2026-10-14-u5-i1.md`, `-i2.md`; rubric `code-review-rubric-2026-10-14-feat-build-loop-u5.md`.

## Trust Boundary Map

```
B1: build-loop branch tree (same-uid loop)        → gate --merge S rules (floor, never line, Paths:) → main
B2: docs/dev-cycle.md on main's commit            → read_settings / never_res                        → never globs, policy, slots
B3: main first-parent subjects + C..M path names  → SKILL.md step 0.1 withheld rule + pinned format  → image-lag entry → questions.sh, ANSWER_AWK
B4: host checkout .git (refs, config, info/)      → Q-156 paste (replace/graft refusal, tree pin) → install.sh git_state_gate → git archive → host image, ~/.claude, .manifest
B5: merged non-floor files                        → sessions / orchestrator health check            → read as instructions, executed
```

Input-source classification:

```
S1: loop branch tree, commit subjects      — request-time    — UNTRUSTED (all sinks)
S2: docs/dev-cycle.md on main              — runtime-mutable — trusted for gate configuration only (floored; both-policy N rules
                                                               refuse it); an F19 main write changes it
S3: main first-parent subjects, C..M paths — runtime-mutable — UNTRUSTED for questions-file / Markdown sinks
S4: host checkout's .git (refs/replace/*, info/, config incl. core.attributesFile) — runtime-mutable (bind-mounted rw into
                                                               sandboxes, per install.sh's header) — UNTRUSTED for host exec and for
                                                               any git read that decides what installs
S5: committed root .gitattributes, released directories at HEAD — runtime-mutable via an F19 main write — UNTRUSTED for
                                                               archive-shaping sinks; now pinned to M by the paste
S6: pinned M = 659a1c61f5b843ef574b90eb99a728ab84cf98d5 — code-constant in the entry — trusted as a name; resolution now
                                                               taken with replace refs off
S7: /opt/claude-workflows/.manifest (C, A) — deploy-time, root-owned image file — trusted for the paste's `cd A`
```

The branch is docs, settings and questions text plus two bats assertion lines. Its security weight sits on B2 (the never line it commits) and B4 (the release paste the user will run on the host). The iteration-2 fixes close the paste's replace-ref and `.gitattributes` bypasses. One archive-shaping input, `core.attributesFile` in the checkout's own git config, is still outside both the paste and install.sh's state gate (Finding 1).

## Findings

#### 1. A `core.attributesFile` in the checkout's git config steers install.sh's `git archive`; neither Q-156's paste nor `git_state_gate` refuses it

**Severity:** Medium
**Location:** `docs/working/questions.md:491`, `:494` (Q-156 paste); `devcontainer-config/install.sh:208` (`GIT_EXEC_KEYS_RE`), `:180-182` (`repo_git`), `:279-280` (archive)
**Boundary:** B4
**Move:** 11 (bypass enumeration), 1 (per-consequence trust), 12 (sweep of the archive primitive)
**Confidence:** High for the mechanism (executed on git 2.39.5 in `/home/node/.claude/jobs/00bcf178/tmp/u5/sec-final/r`). Medium for impact: install.sh's `review_diff` (`diff -ruNa`) shows a dropped file as a whole-file deletion before the y prompt, and the writer needs `.git` write access (a sandbox has it through the bind mount).
**Legibility-target:** for-author

Evidence: the paste's prose says it checks "that no replace ref or graft file exists (`git archive` in install.sh would honor either), and that the root `.gitattributes` and every directory the release installs from are the same tree at HEAD as at M". The state gate refuses only `GIT_EXEC_KEYS_RE='^(filter\.|core\.fsmonitor|include|hook\.)'` keys and a non-empty `info/attributes`. `repo_git` overrides only `core.hooksPath` and `core.fsmonitor`. In the scratch repo, `git config core.attributesFile <file holding "scripts/a.sh export-ignore">` produced:

- `git archive --format=tar HEAD -- scripts | tar -tf -` listed `scripts/` and `scripts/b.sh` only. `a.sh` was dropped.
- The gate's own read (`git config --file .git/config --no-includes --get-regexp '^(filter\.|core\.fsmonitor|include|hook\.)'`) printed nothing, so the gate passes.
- A replica of the Q-156 paste guard printed `PASS -> install.sh would run`. The same replica refused a replace ref (`refused: replace`) and a grafts file (`refused: grafts`), so iteration 2's F1 fix holds.
- With `export-subst` in the same file, `$Format:%H$` in a payload file was rewritten to a commit hash. `ident` and `text`/`eol` attributes route the same way (not run).

The repo's hardened reader already treats this as part of the class: `HARDEN=(core.useReplaceRefs=false … core.attributesFile=/dev/null …)` (`scripts/lib/dev-cycle-read.sh:354`), and its comment lists `core.attributesFile` among the attribute reads. This is the sibling of iteration 2's F1(b) (root `.gitattributes`, now pinned) and F2 (replace refs in `repo_git`, deferred). It is pre-existing in install.sh. Against this branch, Q-156's description of what binds the release is incomplete: an equal tree pin plus no replace refs does not yet mean "installs M's content". Nothing in the payload carries `$Format:` today (not checked exhaustively), so the realistic effect is a dropped payload file (for example a hook script that wiring still names). The payload diff shows that as a removal.

**Recommendation:** In Q-156's paste, add `test -z "$(git config --local --get core.attributesFile)" || { echo "release refused: core.attributesFile set"; exit 1; }` and name it in the prose next to replace refs and grafts. Fold the install.sh half into the deferred roadmap item "install.sh's archive honors replace refs" (`docs/roadmap.md:76`) and its override row: add `-c core.attributesFile=/dev/null` to `repo_git` (matching `HARDEN`), or add `core\.attributesfile` to `GIT_EXEC_KEYS_RE`. That is a decision-035 boundary change, so it is not for this docs unit.

### Untested bypass candidates

- `core.autocrlf` / `core.eol` in the checkout config, which make `git archive` convert line endings. Not run. The effect is loud (every line changes in the payload diff, and CRLF breaks bash scripts), so it is an availability nuisance, not a stealth path.
- A replace ref or `core.attributesFile` written between the paste's check and install.sh's archive (TOCTOU). Not run. install.sh's no-agent gate (running cc-isolated containers, processes with a cwd inside the checkout) narrows the window first. Decision 037 accepts those checks as samples, not a lock.
- `GIT_REPLACE_REF_BASE`, `GIT_GRAFT_FILE` or a `git` function in the host shell. Host-controlled, so they fall outside the reachable-environment bar. Not run.

Tested and cleared by reading: step 0.1's withheld rule now covers backticks, bidi and non-UTF-8 bytes, and it pins the path list to "one line, each in backticks, comma-separated" (`skills/dev-cycle/SKILL.md:303-308`). A path therefore cannot start a line with `#`, `**` or `Q-`, which closes iteration 2's F4 line-start case. Commit lines keep the `- %h ` prefix.

## Endorsement Claims

- **Claim:** At b5eaedf6 the root `.gitattributes` and all eight released directories have the same tree as at M=659a1c61 (resolved with `GIT_NO_REPLACE_OBJECTS=1`), and M..b5eaedf6 changes only `docs/` paths. The paste, run with main at this branch's merge, passes its loop if no other released path moves.
  **Location:** `docs/working/questions.md:470`, `:494`
  **Evidence:** executed
  **Verified:** `git rev-parse b5eaedf6:$p` = `git rev-parse $M:$p` for `.gitattributes devcontainer-config global-instructions guides hooks patterns scripts skills workflows` (all `same`). `git diff --name-only $M b5eaedf6` holds only `docs/`. `.gitattributes` exists at M, so the paste never compares two failed `rev-parse` outputs (a missing path prints `HEAD:nope` and exits 128, which would differ by prefix).
  **Not verified:** the merge commit's trees on main (not yet created), and the host checkout's config and refs state.
- **Claim:** The paste's replace-ref and grafts refusals fire before install.sh runs, and the `( … ) &&` structure skips install.sh on any refusal.
  **Location:** `docs/working/questions.md:494`
  **Evidence:** executed
  **Verified:** a replica of the guard in a scratch repo printed `refused: replace` with one `git replace` ref, `refused: grafts` with `.git/info/grafts` present, and `PASS` only when clean.
  **Not verified:** the host's git version (scratch ran 2.39.5) and the host shell's aliases or functions named `git` or `test`.
  **route: code-fact-check**
- **Claim:** The committed never line parses through `--settings` as written, and the slots line reads 3.
  **Location:** `docs/dev-cycle.md:9-11`; `test/scripts/build-loop-read.bats:79-81`
  **Evidence:** executed
  **Verified:** `timeout 300 bats -f settings test/scripts/build-loop-read.bats` gave 12 ok and 0 not ok.
  **Not verified:** main's committed copy after the merge (the suite reads the fixture repo's commit).
- **Claim:** Iteration 2's F3 is addressed in prose. The Never-line paragraph and Q-149 name `docs/evaluation-rubric.md` and `docs/spikes/` as self-mergeable authority, and leave listing them to the user.
  **Location:** `docs/dev-cycle.md:56-58`; Q-149 body
  **Evidence:** read-static
  **Verified:** the two passages.
  **Not verified:** whether any other off-floor doc outside `docs/`'s floored subtrees is read as authority (no fresh rg sweep this pass).

## Primitive sweep

```
Primitive: host execution of install.sh after a git-read guard / git archive of HEAD
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `docs/working/questions.md:494` (Q-156 paste) | S4, S5, S6 | HEAD==main; no refs/replace, no info/grafts; 9-path tree pin vs M | i2 F1 fixed (executed); Finding 1 (core.attributesFile); working-tree install.sh = i1 F7, Won't-Fix (override row) |
| `skills/dev-cycle/SKILL.md:309-310` (step 0.1 paste, which also rewrites Q-156's body) | S4, S7 | HEAD==main's M | i2 F2 (replace refs at install.sh's archive), deferred: roadmap + override row; Finding 1 applies equally |
| `devcontainer-config/install.sh:279-280` (`archive` in `extract_commit`) | S4, S5 | no-agent gate; git_state_gate | i2 F2 (pre-existing, deferred); Finding 1 (pre-existing) |

Primitive: untrusted text interpolated into questions.md
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| step 0.1 commit list (`SKILL.md:299-302`) | S3 | `- %h ` prefix + withheld rule | cleared: markers, CR, bidi, backtick, non-UTF-8 withheld |
| step 0.1 path list (`SKILL.md:303-308`) | S3 | withheld rule; one line, backticked, comma-separated | cleared: i2 F4 line-start case closed by the pinned format |
| Q-103, Q-149..Q-156 text in this branch | static | hand-written | cleared: no `<!--`, CR, or column-0 answer or heading shapes in the added lines |
```

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `core.attributesFile` in checkout config shapes install.sh's archive; paste and state gate miss it (pre-existing in install.sh) | Medium | B4 | `questions.md:491,494`; `install.sh:180-182,208,279-280` | High (mechanism) / Medium (impact) |

## Overall Assessment

The fixes from iterations 1 and 2 hold across the full branch. The never line covers every directory that takes effect here without a release, and it parses as committed. Q-156's paste now refuses replace refs and grafts and pins the root `.gitattributes` with the released trees, which I confirmed by execution. Step 0.1's withheld rule and pinned format close the questions-file injection residuals. The one new item is a sibling in the same class: a `core.attributesFile` the sandbox can write into `.git/config` still shapes install.sh's `git archive`, and the paste does not check it. install.sh's whole-file payload diff remains the backstop, so it is Medium, not High. The issue sits mostly in pre-existing install.sh code. The in-scope fix is one more `test` in Q-156's paste plus a sentence in its prose. The install.sh half belongs with the already-deferred replace-ref item. There are no other findings within the code paths read. Endorsement claims marked `route: code-fact-check` are pending execution verification.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u5/docs/reviews/security-review-2026-10-14-u5-final.md, first line `Commit: b5eaedf6`, structured per the security-reviewer skill.
- Answered: yes. Prior fixes were confirmed: i1 F1/F3/F4 (never line), i1 F2 and i2 F1 (paste, executed), i2 F3 (prose), and i2 F4 (withheld rule plus format). i2 F2 is deferred with a roadmap item and an override row. A whole-diff pass found one new Medium (Finding 1).
- Out of scope: the known fact-check items listed in the brief, and i1 F7 (Won't-Fix).
- Escalate: Finding 1's paste half is a one-line hardening to Q-156 before the user runs it. Its install.sh half should be added to the deferred roadmap item at `docs/roadmap.md:76`.
- Decisions I made: rated Finding 1 Medium under the floor rule, because it is a concrete mechanism and a sandbox can write `.git` (reachable). Alternative: Low, given the payload-diff backstop. I treated it as new rather than a re-fire of i2 F1, because i2 named replace refs and the committed `.gitattributes`, not config-sourced attributes. The bats PIDs seen afterwards were not started by this review: none had a cwd in the worktree or the scratch dir, and both of my runs finished under `timeout`.
