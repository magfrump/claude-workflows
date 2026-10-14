Commit: 1bc823ea

# Security Review — feat/build-loop-u4c (loop pass i1)

**Scope:** `git diff main...feat/build-loop-u4c` (SKILL.md's D6 block and Rules, `scripts/build-loop.sh` and `scripts/lib/dev-cycle-read.sh` comments, the deleted `test/lib/d6-snippet.bash`, `test/scripts/build-loop-orchestrator.bats`, the plan), plus the code the block runs: `/opt/claude-workflows/scripts/*` (image 774a0eef), `scripts/questions.sh`, `scripts/dev-cycle.sh`.
**Date:** 2026-10-13
**Based on:** `docs/reviews/code-fact-check-report-2026-10-13-u4c-i1.md` (Stage 1, k=1)
**Threat model applied:** plan "What the gate can and cannot do", Q-103, Q-133, Q-140's answer. A deliberately hostile same-uid loop is out of scope. In scope: honest slips, a loop that games the gate by editing it, and quiet routes (invisible to `--main-log`) by which a loop substitutes the gate or the digest.

## Trust Boundary Map

```
B1 (moved):   [repository data: refs/heads/main, first-parent root, WT's .git entry] → [snippet's script choice]  → [what runs as gate/digest]   — choice removed; now a code constant
B2 (new):     [/opt/claude-workflows tree, root-owned, image 774a0eef]                 → [own() + directory walk]   → [bash runs D6_OPT/scripts/SCRIPT]
B3:           [orchestrator's process env: PATH, exported BASH_FUNC_*, settings env]  → [outer `bash -s`, env/git/stat lookups in d6()] → [what actually executes]
B4:           [WT's .git entry + repo config (uid-writable)]                          → [git in snippet and scripts] → [the repository the image gate/digest reads and writes]
B5 (moved):   [questions.sh, now via the D6 block, not ~/.claude/scripts]              → [unhardened `git -C $PWD rev-parse`] → [writes to PROJECT_ROOT/docs/working/]
B6 (new):     [main's reviewed gate code]                                              → [image rebuild (manual, out of band)] → [/opt copy that runs]
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | `D6_OPT=/opt/claude-workflows`, the SCRIPT allowlist | code-constant (SKILL.md from the image) | trusted for the exec path |
| S2 | `/opt/claude-workflows/**` files and directories | deploy-time (root, image build) | trusted for exec **once own() holds**; own() itself depends on S3 |
| S3 | PATH (`/home/node/.elan/bin` first, node-owned 755; `/usr/local/share/npm-global/bin` node-owned), exported shell functions, `~/.claude/settings.json` env/hooks | runtime-mutable by the uid | UNTRUSTED for command resolution (exec sink) |
| S4 | WT's `.git` gitfile, `.git/config`, `~/.gitconfig` | runtime-mutable by the uid (any loop) | UNTRUSTED for repo-location and config-driven exec; HARDEN covers config-driven exec only for the snippet's and the scripts' hardened git |
| S5 | `QUESTIONS_LIVE` / `QUESTIONS_ARCHIVE` in env | runtime-mutable | UNTRUSTED for write destination |
| S6 | SCRIPT ARG... from the orchestrator | request-time (orchestrator-authored) | trusted for the allowlist test; arguments are the scripts' own input |

The diff removes the only place where repository data (S4, refs) chose the code that runs (B1): that is the Q-140 fix and it holds. What remains is that the code path from the orchestrator's shell to `/opt` is resolved through S3, which the snippet's prose now claims is not the case, and that the repository the image code acts on is still chosen by S4 (formerly disclosed in the header, now not).

## Findings

#### F1. "Nothing this uid can write chooses or changes what runs" is false: PATH and exported functions choose what runs, and an exported function defeats own()

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:41-42`, `:196-199`, `:220-222`, `:241`; call form `:194`
**Boundary:** B3
**Move:** 11 (bypasses for every guardrail), 1
**Confidence:** High (executed)

Evidence: `:198-199` "so nothing this uid / can write chooses or changes what runs"; `:42` "nothing a build loop can write chooses or changes what runs as the gate"; `:222` `own() { [[ ! -L "$1" && -e "$1" && "$(stat -c %u -- "$1")" == 0 && ! -w "$1" ]] || no ...; }`; `:241` `env -u BASH_ENV -u ENV -u DEV_CYCLE_SCRUBBED bash "$D6_OPT/scripts/$s" "$@"`.

The fact-check's PATH finding is confirmed and is broader than PATH. Three uid-writable inputs decide what executes, all quiet to `--main-log`: (a) PATH, whose first entry `/home/node/.elan/bin` is node-owned — a planted `bash` there replaces the outer `bash -s` (resolved by the orchestrator's shell before the snippet exists, so no in-snippet fix reaches it), and a planted `env`, `git` or `stat` replaces the snippet's own calls and every git/perl call the image scripts make; (b) exported shell functions (`BASH_FUNC_name%%` in the environment), which bash imports and which outrank PATH: executed here, `env 'BASH_FUNC_stat%%=() { echo 0; }'` made the real block's own() pass uid-owned files and directories (the walk proceeded up to the first writable directory; with an `env` function the whole launch line is replaced); `env -u BASH_ENV -u ENV` strips the two env-borne code vectors it names but not this one; (c) `~/.claude/settings.json` (env, PreToolUse hooks), which can rewrite the orchestrator's command before it runs. These are the same class Q-140 [1] closed (hostile, same-uid, quiet), and its answer's rationale ("they are the only quiet ones") was incomplete. Under the stated threat model this is out of scope — every one of these needs a loop to plant executable state outside the repository on purpose, which is the Q-103 hostile class, not an honest slip or an edit of the gate — so by the floor rule's own exemption (the attacker already controls the uid) it stays Low. It is filed because the two sentences are security-property claims the orchestrator and later reviewers rely on, and they are false as written.

Fix is **wording, not code.** No code in the snippet can close the route: the outer `bash -s` is PATH-resolved by the orchestrator's shell (and hooks/shell init sit before that), and function import can override `unset`, `builtin` and `set` in a non-POSIX bash. Cheap narrowing exists (call form `/usr/bin/bash -s`, `PATH=/usr/bin:/bin` exported at the top of d6(), absolute `/usr/bin/env`/`/usr/bin/stat`), but it leaves (b) and (c) open, and it would break the T26 hardening test that puts a `shim` git on PATH through the snippet; not worth it unless the user wants the planted-binary case closed specifically.

**Recommendation:** Reword `:41-42` and `:198-199` to the plan's own scope (`plan:33-35`): nothing a loop writes in a repository, a working tree or main chooses or changes what runs; the uid's PATH, environment (exported functions) and Claude Code settings remain the Q-103 hostile class. Add one line to Q-140's archived answer or the plan's U4c as-built note that the "only quiet routes" premise did not hold, so the decision record is not cited for a guarantee it does not give.

#### F2. The header no longer says the scripts act on whatever repository WT's `.git` entry names; that route still steers the digest, `--land-cycle` and questions.sh

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:196-203` (deleted text: `test/lib/d6-snippet.bash` old header)
**Boundary:** B4
**Move:** 1, 4
**Confidence:** Medium

Evidence (deleted): "its git finds the repository through the checkout's .git entry, which it does not check. It trusts refs/heads/main and that entry: a moved main is --main-log's to report". New header: "a choice read from the repository let a loop that moved main, or rewrote the checkout's .git entry, pick its own scripts" and "Run it from the checkout the script is to read".

Q-140's gitfile route is closed for *which scripts run*. It is not closed for *what they read and write*: WT (`.claude/wt-dev-cycle-*` inside MAIN_WT) has a uid-writable gitfile; rewritten to a crafted gitdir, the image digest (step 0.4, from WT) describes the crafted repository's history, `--land-cycle` (from WT) lands into it, and questions.sh's `--show-toplevel` (honouring a `core.worktree` there) moves its write root. Real main is not written (its CAS is on the crafted repo's ref), so `--main-log` from MAIN_WT later sees the missing landing, but the digest substitution itself is quiet. This is pre-existing and hostile-class; the finding is that the diff deletes the disclosure while adding a broader claim (F1), so a reader of the new header would conclude the gitfile route is gone.

**Recommendation:** Restore one sentence to the header: its git, and the scripts', find the repository through the checkout's `.git` entry, which nothing checks; a rewritten entry changes what the image copy reads (Q-103 class), not which copy runs.

#### F3. Version skew: a reviewed gate change on main is silently not what runs until a manual rebuild, and nothing reports which image runs

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:196-202`; `docs/working/plan-build-loop-handoff.md:344` (as-built note)
**Boundary:** B6
**Move:** 1
**Confidence:** High (for the skew), Medium (for impact)

Evidence: plan `:344` "Consequence: in claude-workflows a merged gate change runs only after an image rebuild, and the image at the time of writing (774a0eef) predates U4a's `--land-cycle`". `/opt/claude-workflows/.manifest`: `commit=774a0eef…`; `git diff --stat 774a0eef HEAD -- scripts/build-loop.sh scripts/lib/dev-cycle-read.sh` is 274+/56- (U4a's `--land-cycle`, the Asked:/cycle rules, `isrecord`, HARDEN's `commit.gpgSign=false`).

The consequence is documented, and the current skew is internally consistent (the installed skill `~/.claude/skills -> /opt/.../skills` is also 774a0eef and has no D6 block, so nothing runs the new snippet against old scripts). I checked the one fix that looked security-relevant: the image's `--merge` already runs `commit-tree --no-gpg-sign` and `--state` refuses `gpg.*` (`/opt/.../build-loop.sh:552`, `:1495`), so HARDEN's later `commit.gpgSign=false` opens no exec gap in the image gate. The remaining risk is legibility: after any future rebuild lag, a floor or refusal rule merged under a `merge-gate-` review is believed active while the older image decides, and no line in `--settings`, `--state` or the record names the image commit. No loop can widen this (the image is root-owned), so it is not a substitution route.

**Recommendation:** Have one mode the orchestrator already runs each iteration (`--settings` or `--state`) print `image: <.manifest commit>` (the file is root-owned 0444), and have step 0 note in the record when `hg -C MAIN_WT log IMAGE..main -- <GATE_CODE paths>` is non-empty. A `trigger` entry is enough if this is not built in U4c.

#### F4. questions.sh through the block runs unhardened git and honours QUESTIONS_LIVE/ARCHIVE from the caller's environment

**Severity:** Informational
**Location:** `scripts/questions.sh:80`, `:84`, `:85-86`; `skills/dev-cycle/SKILL.md:58-59`, `:360-361`
**Boundary:** B5
**Move:** 2
**Confidence:** High

Evidence: `PROJECT_ROOT="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || pwd)"`; `LIVE="${QUESTIONS_LIVE:-$PROJECT_ROOT/docs/working/questions.md}"`. The dev-cycle.sh comment "Every git call from here on, the lib's and questions.sh's included, runs hardened" holds only when dev-cycle.sh runs it; run directly through the block, its two `rev-parse` calls read `~/.gitconfig` and repo config with no HARDEN pairs. `rev-parse` triggers no hook, fsmonitor, filter or gpg, so there is no config-driven exec here; config can only move the toplevel (F2). This is strictly better than before (same bytes, now reached without the uid-owned `~/.claude/scripts` link). The env overrides are exempt from questions.sh's containment check by design; an honest leftover `QUESTIONS_LIVE` in the orchestrator's environment would make step 1's `archive` rewrite a different file than the WT one `--cycle-diff` later checks.

**Recommendation:** Optional: add `-u QUESTIONS_LIVE -u QUESTIONS_ARCHIVE` to the block's launch `env` (no caller of the block needs them). Leave the git unhardened; nothing it runs can execute config.

## Untested bypass candidates (own() and the directory walk, B2)

Tested: a symlinked directory between the files and `/` (D6_OPT whose `scripts` is a symlink to the real `/opt/.../scripts`: refused at `…/x/scripts is not root-owned, a plain path and unwritable here`, executed); a uid-owned 0555 stand-in tree (refused at the first file, executed); an exported `stat` function (bypassed, F1, executed).
Untested:
- A planted `stat`/`env`/`bash` earlier on PATH — not executed (it would mean writing into a PATH directory, which the review rules forbid); same mechanism as the executed function case.
- Mount or user namespaces (an unprivileged userns remap, a bind mount over `/opt/claude-workflows` in a namespace the orchestrator then runs in) — not tested; needs privileges or namespace tooling outside the review's sandbox.
- A run as root (the header says `-w` refuses unless the mount is read-only) — unverifiable without root (fact-check: Unverifiable).

Because of these, own() and the walk do not appear in Endorsement Claims.

## Endorsement Claims

- **Claim:** The block chooses the script directory from a code constant only; no repository read feeds `D6_OPT` or the script path.
  **Location:** `skills/dev-cycle/SKILL.md:217-241`
  **Evidence:** read-static
  **Verified:** read every line of d6(): `D6_OPT` is assigned once, `s` is tested against a three-name allowlist, and the git reads (`for-each-ref`, `rev-parse`, `show-ref`, `symbolic-ref`, `cat-file -t`) feed only refusal tests, never a path.
  **Not verified:** what the orchestrator substitutes for SCRIPT and WT when it pastes the block (S6), and S3's resolution of `bash`/`env` (F1).
  **route: code-fact-check**

- **Claim:** Run through the block with the current image, `build-loop.sh --help` prints `/opt/claude-workflows/scripts/build-loop.sh`'s header, not main's or the working tree's.
  **Location:** `skills/dev-cycle/SKILL.md:194-245`
  **Evidence:** executed
  **Verified:** extracted the block from SKILL.md with the test's own awk and ran it from this worktree; output began "The build-loop handoff's state and checks…", the image copy's header (bats T37 asserts the same equality).
  **Not verified:** the gated modes (`--merge`, `--land-cycle`) through the block against the real image.

- **Claim:** Under the block, dev-cycle.sh's fallback to `$HOME/.claude/scripts/questions.sh` is not taken, and the image scripts source nothing but `lib/dev-cycle-read.sh` from their own directory.
  **Location:** `scripts/dev-cycle.sh:389-390`, `:100-103`; `scripts/build-loop.sh:528-531`
  **Evidence:** read-static
  **Verified:** `QS="$SCRIPT_DIR/questions.sh"; [[ -f "$QS" ]] || QS="$HOME/..."` and the block refuses unless `$D6_OPT/scripts/questions.sh` is a regular file in a root-owned unwritable directory; a grep for `source`/`.`/`SCRIPT_DIR`/`HOME/` across the three files finds only these uses.
  **Not verified:** the `/opt` copies' lines (the image's dev-cycle.sh and questions.sh are byte-equal to HEAD's; build-loop.sh and the lib differ, and were grepped only for `gpg`/`commit-tree`).

## Primitive sweep

Primitive: process exec / command resolution
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `SKILL.md:194` outer `bash -s` | S3 PATH, functions, settings | none possible in-snippet | F1 (wording) |
| `SKILL.md:220-221` `"${G[@]}"` → `env … git` | S3 | none | F1 |
| `SKILL.md:222` `stat -c %u` in own() | S3 | none | F1 (executed bypass via function) |
| `SKILL.md:241` `env -u … bash "$D6_OPT/scripts/$s"` | S1 path, S3 for `env`/`bash` | own() + walk on S2; allowlist on `s` | path cleared; resolution F1 |
| `dev-cycle-read.sh:158` scrub_reexec `bash "$self"` | S3 for `bash`, `$self` from BASH_SOURCE under S1 | inherited | F1 class; path cleared |
| `dev-cycle.sh:389-390` questions.sh exec | S1/S2 (fallback S4-adjacent `$HOME`) | `-f` test; block guarantees the file | cleared (Endorsement 3) |
| `questions.sh:80,84` `git -C "$PWD" rev-parse` | S3 for `git`, S4 config | none (unhardened) | F4 (no exec surface), F2 (toplevel) |

Primitive: file write
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `questions.sh` `replace_with` / init (via block, step 1) | S4 toplevel, S5 env overrides | symlink checks; containment only for default paths | F4 (env), F2 (toplevel) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | PATH, exported functions and settings choose what runs; the "nothing this uid can write" claims are false; fix is wording | Low | B3 | `SKILL.md:41-42, 196-199, 222, 241` | High |
| 2 | Header drops the disclosure that WT's `.git` entry chooses the repository the image reads and writes | Low | B4 | `SKILL.md:196-203` | Medium |
| 3 | Image/main skew is silent; no mode names the image commit | Low | B6 | `SKILL.md:196-202`, plan `:344` | High |
| 4 | questions.sh via the block: unhardened rev-parse (no exec surface), env-overridable write paths | Informational | B5 | `questions.sh:80-86` | High |

## Overall Assessment

The change does what Q-140 [1] asked: repository data no longer chooses which scripts run, both named routes (a forged root, a rewritten gitfile) lose their script-substitution effect, and deleting the reader removes nothing the image path needed — its hash checks guarded main's bytes, which no longer run. I found no new quiet substitution route introduced by the diff. What the diff does introduce is a stronger security claim than the code supports: PATH (first entry uid-owned), exported shell functions (executed: they defeat own()) and Claude Code settings still choose what runs, invisibly to `--main-log`. These are the same hostile same-uid class Q-140 ruled on, so they are out of scope and rated Low, and the outer `bash -s` being PATH-resolved by the orchestrator's shell means the fix is wording, not code. The single most important thing to address is F1's rewording of SKILL.md `:41-42` and `:198-199` to the plan's scope, with F2's disclosure restored beside it. No findings within the code paths read rise above Low; endorsement claims pending execution verification except the one marked executed.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to /workspace/.claude/wt-build-loop-u4c/docs/reviews/security-review-2026-10-13-u4c-i1.md (first line `Commit: 1bc823ea`), structured per the security-reviewer skill.
- Answered: the two Q-140 routes are closed for script choice (B1), with no new quiet route introduced by the diff; the ownership/directory walk refuses a symlinked or uid-owned component (executed) but is bypassed by an exported `stat` function (F1); questions.sh through the block (F4, F2); the PATH finding's severity (Low, hostile same-uid class) and its fix (wording; code narrowing optional and incomplete because the outer `bash -s` and function import sit outside the snippet's reach) (F1); version skew (F3, with the gpgSign gap checked and cleared); what the deleted reader protected (nothing the image path needs; the deleted gitfile disclosure is F2).
- Out of scope: hostile same-uid containment (Q-103); the image build pipeline's integrity (`assembled_from` the host checkout); the stale plan lines and row 738/739 citation (fact-check's).
- Escalate: none for HALT. For the user: whether Q-140's decision record should note that its "only quiet routes" premise did not hold (F1), since nothing in the design changes either way.
