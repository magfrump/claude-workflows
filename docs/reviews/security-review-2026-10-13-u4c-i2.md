Commit: f2cc21e6

# Security Review — feat/build-loop-u4c (loop pass i2, fix range)

**Scope:** `git diff 1bc823ea..f2cc21e6` (SKILL.md's Rules, D6 block header, own(), launch line, step 0.1's image-lag check, step 1; the orchestrator bats; plan text; override rows 812-817), plus what the new check reads: `/opt/claude-workflows/.manifest`, `devcontainer-config/install.sh`'s `assemble`, MAIN_WT's refs and config through `hg`.
**Date:** 2026-10-13
**Based on:** `docs/reviews/code-fact-check-report-2026-10-13-u4c-i2.md`, rubric `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md`, i1 `docs/reviews/security-review-2026-10-13-u4c-i1.md`
**Threat model applied:** a deliberately hostile same-uid loop is out of scope (plan "What the gate can and cannot do", Q-103); in scope are honest slips, gate-gaming, and quiet routes by which repository data substitutes the gate.

## Trust Boundary Map

```
B1:          [repository data: refs, gitfile]                     → [d6() script choice]                      → [what runs]           — unchanged since i1: code constant
B2 (moved):  [/opt/claude-workflows/** files and directories]      → [own(): missing test, then owner/link/-w] → [bash D6_OPT/scripts/SCRIPT]
B3:          [orchestrator env: PATH, BASH_FUNC_*, settings]       → [outer bash -s, env/stat/git lookups]     → [what executes]       — now disclosed (i1 F1)
B5 (moved):  [QUESTIONS_LIVE / QUESTIONS_ARCHIVE in caller env]    → [launch env -u]                           → [questions.sh write targets]
B6 (new):    [/opt/.../.manifest commit= (C)]                      → [step 0.1: cat-file -e, diff --quiet]     → [image-lag entry or a record note]
B7 (new):    [MAIN_WT refs/heads/main, objects, repo config]       → [hg diff --quiet C main -- GATE_CODE]     → [image-lag entry or a record note]
B8 (new):    [host checkout HEAD at install time (bind-mounted)]   → [install.sh assemble: git archive HEAD]   → [the image, hence C and the gate that runs]
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | `D6_OPT`, the SCRIPT allowlist, step 0.1's literal path list | code-constant | trusted (all sinks) |
| S2 | `/opt/claude-workflows/**`, `.manifest` (root 0444 in a root 0555 dir) | deploy-time (root, image build) | trusted for exec once own() holds; `.manifest` trusted as "the image's commit" only as far as S6 is |
| S3 | PATH, exported functions, settings | runtime-mutable by the uid | UNTRUSTED for command resolution (the Q-103 residual, now named) |
| S4 | MAIN_WT's refs, object store, `.git/config`, `info/attributes` | runtime-mutable by any loop | UNTRUSTED for the advisory verdict; hg's flags cover config-driven exec |
| S5 | QUESTIONS_LIVE / QUESTIONS_ARCHIVE | runtime-mutable | UNTRUSTED for write destination; now stripped at launch |
| S6 | the host checkout's HEAD when the user runs install.sh (`/workspace` is that checkout, bind-mounted; sessions switch its branch) | runtime-mutable by any session | UNTRUSTED as "main's reviewed code" toward the image (and so the gate) |

What the fix range newly trusts is `.manifest`'s `commit=` as a statement of what the image runs (B6) and MAIN_WT's `refs/heads/main` as the reviewed code to compare against (B7). The first is sound (`install.sh` stages `git archive HEAD` only, so the image is exactly C's content, and the file is root-owned); the second inherits main's existing trust, with `--main-log` reporting a moved main one step later. The gap is in what C is *relative to main*: the check does not ask whether C is on main at all (S6).

## Closure of i1 F1-F4

- **F1 (PATH / functions / settings, wording):** closed in the header and plan; the Rule is narrower but still slightly overbroad (Finding 3). Header `SKILL.md:200-206`: "so no repository data chooses which script runs ... it cannot guard against this uid's own shell (PATH, exported functions): the plan's same-uid residual (Q-103)".
- **F2 (gitfile disclosure):** closed. `SKILL.md:203-204`: "It still trusts that entry and the default branch's ref for which repository and branch the script reads".
- **F3 (silent image skew):** closed in substance by step 0.1 (`SKILL.md:283-290`); i1's other half (a mode printing the image commit) was not taken, and the entry is the visible signal instead. New gap: Finding 1.
- **F4 (QUESTIONS_* env):** closed. `SKILL.md:247`: `env -u BASH_ENV -u ENV -u DEV_CYCLE_SCRUBBED -u QUESTIONS_LIVE -u QUESTIONS_ARCHIVE bash "$D6_OPT/scripts/$s" "$@"`; executed log `u4c-i2-questions-env.log` shows `QUESTIONS_LIVE=fake` through the block prints `Q-144` (the real file) and direct prints `Q-001`. questions.sh reads no other env override (grep of `${NAME:-` in questions.sh: only those two).

## own(): old vs new, every present path

Old: `[[ ! -L "$1" && -e "$1" && "$(stat -c %u -- "$1")" == 0 && ! -w "$1" ]] || no ...`
New: `[[ -e "$1" || -L "$1" ]] || no "$1 is missing"; [[ ! -L "$1" && "$(stat -c %u -- "$1")" == 0 && ! -w "$1" ]] || no ...`

For a path where `-e` is true, the new second test is the old test minus a conjunct that is already true, so the accept set is identical; for a dangling link the first test passes on `-L` and the second refuses on `! -L`, as before. Executed side by side (scratch repo, both functions): `/usr/bin/env`, `/opt/claude-workflows`, `.manifest`, `/` accepted by both; `/dev/null`, `/proc/1`, a fifo, a live link to a root file, a dangling link refused by both with the same message. The only change is wording: an absent path, and a path that exists but sits under an unsearchable directory (`locked/f` with the parent 000), now read "is missing". `no` exits, so the two-statement body cannot fall through. As strict as before for every present path.

## Findings

#### 1. The image-lag check cannot tell an image built off main from one behind main, and its remedy rebuilds from whatever the shared checkout has checked out

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:283-290`; `devcontainer-config/install.sh:328-336`
**Boundary:** B8, B6
**Move:** 1 (trust boundaries), 5 (invert the model)
**Confidence:** Medium

Evidence: step 0.1, "when `hg -C MAIN_WT cat-file -e 'C^{commit}'` succeeds ... and `hg -C MAIN_WT diff --quiet C refs/heads/main -- ...` (GATE_CODE) exits 1, the gate that runs is older than main's: file or update one `you: terminal` entry `image-lag` (the release: the host's `./devcontainer-config/install.sh`, then the next sandbox launch rebuilds the image)"; install.sh, "`commit="$(head_commit)"` ... the payload is `git archive HEAD`", and its own note "An agent can write .git, and so can a cc-isolated container through its bind mount".

Since Q-140 [1] the image *is* the gate in this repo, and the image is the host checkout's HEAD, not main. `/workspace` is that checkout and sessions switch its branch (the user's memory records this happening). So an honest slip is reachable: the user runs the `image-lag` paste while `/workspace` is on a loop's or a feature branch, and the image then runs that branch's gate code, which no `merge-gate-` review passed. The fix range's check sees the difference but files it as "older than main's" with the same remedy, so the entry neither names the actual state (the gate is code not on main) nor prevents a repeat; and a branch whose GATE_CODE happens to equal main's while other image content differs is reported clean. This is not a loop substituting the gate quietly (install.sh prints the commit it stages), but the entry is now the skill's prompt to cut the release, and it routes it as a mechanical `you: terminal` paste with no "from main" precondition. The i2 fact-check already ran the ancestry test (`u4c-i2-image-lag.log`: "is C on main's history: ancestor exit=0"), so the missing branch is one line.

**Recommendation:** Add `hg -C MAIN_WT merge-base --is-ancestor C refs/heads/main` to step 0.1: on exit 1, file a `you: judgment` entry (the gate that runs is commit C, which is not on main) rather than `image-lag`; and have the `image-lag` entry's command say to run install.sh with the host checkout on main at the commit it names (or `git -C <checkout> rev-parse HEAD` equals main's before the paste).

#### 2. The `image-lag` entry is a release prompt without the release listing (F58)

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:287-289`; plan `docs/working/plan-build-loop-handoff.md:28`, `:356`
**Boundary:** B6
**Move:** 1
**Confidence:** Medium

Evidence: plan `:28`, "So the release is the real gate, and the release entry lists every commit and changed path since the image's `.manifest` commit"; step 0.1 files "one `you: terminal` entry `image-lag` (the release: ...)" and says nothing of what the entry lists.

A rebuild ships everything committed since C, including self-merged non-floor code (`hooks/`, `guides/`, `scripts/` outside GATE_CODE), which reaches running sessions only through this release. The listing that makes the release a gate is U5's (step 12), not built yet, so today the first in-skill release prompt is this entry, and it fires right after a reviewed gate merge, when a reader is least likely to look for unrelated self-merged content in the same rebuild. Not a substitution route (no loop chooses what C..main holds beyond what the gate admitted), so Low.

**Recommendation:** Have the `image-lag` entry carry the F58 list (commits and changed paths `C..refs/heads/main`, flagging `Build-loop-gate:` self-merges), or say that the release entry U5 adds does and point to it; otherwise note the gap in U5's row.

#### 3. The Rule's narrowed claim is still broader than the header's

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:41-45`
**Boundary:** B3
**Move:** 1
**Confidence:** High

Evidence: "no file or repository state a build loop writes chooses which script runs as the gate (a hostile process of this uid still reaches the shell itself, through PATH, exported functions or the session's settings ...)"; header: "no repository data chooses which script runs". A planted `bash` in `/home/node/.elan/bin` or a `~/.claude/settings.json` hook *is* a file a build loop writes; the parenthetical then names exactly those, so the sentence contradicts itself rather than overclaims silently. The plan's as-built note says "the Rule and header now claim only that no repository data chooses the script", which the Rule does not quite say.

**Recommendation:** "no repository file or state a build loop writes ..." matches the header and the plan note.

#### 4. Step 0.1's path list is GATE_CODE by hand, with no test pinning it

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:285-287`; `scripts/lib/dev-cycle-read.sh:1970`
**Boundary:** B7
**Move:** 11
**Confidence:** High

Evidence: `GATE_CODE='^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'` vs step 0.1's `scripts/build-loop.sh scripts/dev-cycle.sh scripts/questions.sh scripts/lib/ skills/dev-cycle/`. Equal today; the merge-entry slug rule has a pin test (bats `:347`), this list does not. A GATE_CODE addition left out here would hide that path's lag (advisory only).

**Recommendation:** Extend the `:347` test to grep step 0.1's list, or leave a row.

## Bypass candidates for the image-lag check (B6, B7)

Tested:
- A ref named with C's 40 hex (`refs/heads/<C>`, `refs/tags/<C>` pointing elsewhere): executed in a scratch repo; `rev-parse 'C^{commit}'` resolves to the object, with an ambiguity warning on stderr. C cannot be steered by ref names (`.manifest` holds the full 40 hex).
- Planted repo config to hide a difference or run code: executed with `hg` on a scratch repo holding `diff.external`, `diff.x.textconv` via `info/attributes`, `diff.relative=true`, `diff.ignoreSubmodules=all`: `diff --quiet` still exit 1, nothing executed.
- Replace refs swapping main's tree: `hg` sets `GIT_NO_REPLACE_OBJECTS=1` and `core.useReplaceRefs=false`, and `--state` refuses replace refs just before (read-static).
- Moving `refs/heads/main` to a commit whose GATE_CODE equals C's: hides the lag for that iteration, but is a moved main, which step 0.2's `--main-log` stops on (read-static; hostile class).
- A dirty host checkout making the image differ from C: cleared; `install.sh` stages `git archive HEAD` only and always writes `dirty=no` (read-static, `install.sh:324-361`).

Untested:
- Deleting C's objects from MAIN_WT so `cat-file -e` fails and the check degrades to a record note: needs destroying reachable objects (hostile class); not run.
- A repository that is not claude-workflows but holds C (a fork or vendored clone): the check would compare unrelated GATE_CODE and file an `image-lag` a rebuild cannot clear; not run (no such repo here). Advisory noise, not a substitution.

## Endorsement Claims

- **Claim:** For every path that exists, the new own() accepts exactly the paths the old one accepted.
  **Location:** `skills/dev-cycle/SKILL.md:228`
  **Evidence:** executed
  **Verified:** both bodies run side by side over 11 paths (root files and dirs, `/dev/null`, `/proc/1`, fifo, live and dangling links, an absent path, a path under a 000 directory); identical exit codes, message differs only for absent/unsearchable paths.
  **Not verified:** the snippet's own() under a run as root (`-w`), and under an exported `stat` function (i1 F1, residual).

- **Claim:** Through the block, questions.sh writes the repository's default files whatever QUESTIONS_LIVE/ARCHIVE the caller exported.
  **Location:** `skills/dev-cycle/SKILL.md:247`; `scripts/questions.sh:85-86`
  **Evidence:** executed (fact-check log `u4c-i2-questions-env.log`), read-static for the full override list
  **Verified:** the log; a grep showing questions.sh reads no other `${NAME:-}` override.
  **Not verified:** dev-cycle.sh's own `DEV_CYCLE_TODAY` passthrough (pre-existing, digest window only).

- **Claim:** `.manifest`'s `commit=` describes the image's content exactly.
  **Location:** `devcontainer-config/install.sh:328-361`
  **Evidence:** read-static
  **Verified:** `assemble` extracts the payload from `head_commit` with `extract_commit` and writes `commit=$commit`, `dirty=no`.
  **Not verified:** the step from the host's staged payload to `/opt` in the next sandbox image (the image build itself).
  **route: code-fact-check**

The orchestrator bats ran 25/25 at f2cc21e6 (`timeout 300 bats test/scripts/build-loop-orchestrator.bats`).

## Primitive sweep

Primitive: process exec / command resolution (fix-range call sites)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `SKILL.md:228` own() `stat -c %u` | S3 | none in-snippet | cleared for this range (i1 F1 residual, now disclosed) |
| `SKILL.md:247` `env -u ... bash "$D6_OPT/scripts/$s"` | S1, S2, S3 | own() + walk, allowlist, two more `-u`s | cleared (F4 closed) |
| `SKILL.md:284-285` `hg -C MAIN_WT cat-file -e 'C^{commit}'` | S2 (C), S4 | hg flags; C full hex | cleared (ref-name steering executed) |
| `SKILL.md:285-287` `hg -C MAIN_WT diff --quiet C refs/heads/main -- ...` | S2 (C, unquoted in the prose), S4, S1 paths | hg flags, literal pathspecs, `--state` before | cleared (config hiding/exec executed); C unquoted is safe only because `.manifest` is root 0444 |
| `SKILL.md:288` install.sh (the entry's paste, run by the user on the host) | S6 | none on branch | Finding 1 |

Primitive: file write
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| questions.sh `init`/`archive` via the block (step 1) | S5 | `env -u` | cleared (F4) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Image built off main reads as "older"; the remedy rebuilds from the shared checkout's HEAD | Medium | B8, B6 | `SKILL.md:283-290`, `install.sh:328-336` | Medium |
| 2 | `image-lag` prompts a release without F58's listing | Low | B6 | `SKILL.md:287-289` | Medium |
| 3 | Rule says "no file ... a build loop writes", header says "no repository data" | Informational | B3 | `SKILL.md:41-45` | High |
| 4 | Step 0.1's path list not pinned to GATE_CODE | Informational | B7 | `SKILL.md:285-287` | High |

## Overall Assessment

The fix range closes i1 F2 and F4 fully, F1 in the header and plan (the Rule is one word broad, Finding 3), and F3 in substance. The new own() is as strict as the old for every present path (executed); only its message changed. The image-lag check's inputs hold up against the steering tried: a 40-hex ref cannot redirect C, planted diff config neither hides a difference nor executes, replace refs are off, and a moved main is `--main-log`'s stop. The one thing worth fixing is what the check does not ask. Since Q-140 [1] the image is the gate, and the image is built from the bind-mounted checkout's HEAD, which sessions switch. The check reports an image built off main as "older" and prescribes the same rebuild, so a release cut from the wrong branch runs unreviewed gate code with no entry saying so (Finding 1; one `merge-base --is-ancestor` line and a "from main" precondition). The check is advisory and never stops the iteration. That limits the harm to what the user does with the entry. It also means the entry's wording carries the whole safeguard. No findings within the code paths read rise above Medium. Endorsement claims are executed except the `.manifest` one, which is pending execution verification.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to /workspace/.claude/wt-build-loop-u4c/docs/reviews/security-review-2026-10-13-u4c-i2.md (first line `Commit: f2cc21e6`), per the skill.
- Answered: i1 F1-F4 closure (F2, F4 closed; F1 closed but for the Rule's wording, Finding 3; F3 closed in substance, with a new gap, Finding 1); own() strictness (identical accept set, executed); whether the image-lag inputs can be steered to hide a lag (not by refs, ref names, config or replace refs; a moved main hides it for one iteration and is stopped by `--main-log`) or into a harmful entry (an off-main image is mislabeled and its remedy repeats the problem, Finding 1; the entry lacks the release listing, Finding 2); what the range newly trusts (`.manifest` commit, sound; main as the comparison, inherited; the checkout's HEAD through install.sh, Finding 1).
- Out of scope: hostile same-uid containment (Q-103); the image build from staged payload to `/opt`.
- Escalate: none for HALT. Finding 1 is the item for the loop's fix decision.
