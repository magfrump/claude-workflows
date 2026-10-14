Commit: 0cd86cc0
# Code Fact-Check Report

**Repository:** claude-workflows (worktree /workspace/.claude/wt-build-loop-u4b1, branch feat/build-loop-u4b1)
**Scope:** fix range `git diff 458dc170..0cd86cc0 -- skills/ workflows/ test/` (only `skills/dev-cycle/SKILL.md` changed; `workflows/` and `test/` have no diff in the range) and the commit message of 0cd86cc0; the rubric and i1 report it adds are context
**Checked:** 2026-10-13
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 15
**Summary:** 12 verified, 2 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable (claim 3 split into 3a/3b/3c, counted per atom)

Execution logs (captured output; the probe scripts sit beside them) are in the session scratchpad, not the repo (the brief allows writing only this report): `/tmp/claude-1000/-workspace/5f7c1a26-c882-447d-bbc1-af5199ac916b/scratchpad/u4b1-i2/cfc-*.out`. Each probe ran from that scratchpad dir as `bash cfc-probeN.sh > cfc-probeN.out 2>&1` (wrapper exit 0; each command's own exit is printed in the .out), in its own `mktemp -d /tmp/u4b1-cfc*-XXXX` clone of /workspace, removed afterwards. `scripts/` is unchanged in the fix range, so script behaviour is that of 458dc170 and HEAD alike. Hallucination pattern log read; no claim below matches a logged pattern, and neither Incorrect verdict is a fabricated symbol (none appended).

## Iteration-1 Incorrect findings: resolution

| i1 | Status at 0cd86cc0 | Claim here |
|---|---|---|
| R1 (i1 claim 9b: hg stops filters/signing) | **Partly resolved.** The wording no longer says hg stops them, and filter/merge driver are refused by `--state` (executed). The new text says `--state` refuses "commit signing" too; it does not refuse `commit.gpgSign=true`, and `hg commit` then runs `gpg` (executed). | 3c (Incorrect) |
| R2 (i1 claim 11b: `--state` refuses exported env) | Resolved: now "a caller's config pair for a `HARDEN` key". | 8 |
| A1 (i1 claim 5b: undocumented exit = nothing ran) | Resolved: "nothing was decided". | 1 |
| A2 (i1 claim 24: steps 9/10) | Resolved: no "step 9"/"step 10" left in SKILL.md (grep, 0 hits). | 13 |
| A3 (i1 claim 18: bootstrap refusal not exempt) | Resolved, causes named and executed. | 11 |
| A4 (i1 escalation: identity pasted into scripts) | Resolved: read into variables in the committing script; quotes, `$(...)` and backticks stay data (executed). | 6 |

---

## Claim 1: "`refuse d6: WHY` (exit 2) means nothing ran; an exit the mode does not document, or a call the Bash tool timed out, means nothing was decided (a writing mode may have stopped part way)."

**Location:** `skills/dev-cycle/SKILL.md:48-50`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the wording against build-loop.sh's Exit paragraph and the D6 snippet's Exit line; does not establish which writes a timed-out or part-way `--land-cycle`/`--start` actually leaves behind (not executed: a timeout mid-write is not cheap to reproduce).

build-loop.sh's contract says a partial stop is possible and reads non-zero as undecided:
```
# --merge can also stop part way, after the lines of the briefs before, with 1
# (need_root) or a failed command's own status: a caller reads any exit but 0
# as nothing decided.
```
(`scripts/build-loop.sh:513-518`). The snippet's "with nothing run" is limited to its own `refuse d6:` lines: "Exit: the script's own status; 2 and one "refuse d6: WHY" line on stdout, with nothing run, for a replace ref, ..." (`test/lib/d6-snippet.bash:29-30`). The i1 wording ("nothing ran") is gone.

**Evidence:** `scripts/build-loop.sh:511-521`, `test/lib/d6-snippet.bash:29-40`

---

## Claim 2: "`hg` reads no global or system config and runs no hook, fsmonitor command or replaced object; a test holds its pairs to the lib's `HARDEN` list."

**Location:** `skills/dev-cycle/SKILL.md:63-65`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers hg's env/`-c` pairs (`GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`, `core.hooksPath=/dev/null`, `core.fsmonitor=false`, `GIT_NO_REPLACE_OBJECTS=1`/`core.useReplaceRefs=false`, `SKILL.md:60`) and the pin test passing at HEAD; does not establish what repo-local config hg still honours (claims 3a-3c).

The pin test passes at HEAD: command `TMPDIR=$(mktemp -d /tmp/u4b1-cfc4-XXXX) timeout 300 bats -f "SKILL.md.s hg carry the same" test/scripts/build-loop-orchestrator.bats`, cwd the worktree, 2026-10-13T22:14:48Z, `ok 1 git_harden exports HARDEN's pairs ... the D6 snippet's git and SKILL.md's hg carry the same (rows 281, 311, 495, 704, 736, U3b3, U4b1)`, exit 0. The hook/fsmonitor/replace part was executed in i1 (claim 9a, Verified) and the line is unchanged in the range.

**Evidence:** `skills/dev-cycle/SKILL.md:60`, `test/scripts/build-loop-orchestrator.bats:355`, `scratchpad/u4b1-i2/cfc-bats.out`

---

## Claim 3a: "It does not switch off what the repository's own config can still name (a filter, a merge driver, commit signing)"

**Location:** `skills/dev-cycle/SKILL.md:65-66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers commit signing (executed here) and filters (executed in i1, claim 9b); does not establish the merge-driver case under hg by execution (static: hg sets no `merge.*` pair).

Probe 1 planted `commit.gpgSign true` in a clone's `.git/config`, put a shim `gpg` (touches `GPGRAN`, exits 1) first on PATH, and ran `hg -c user.name=a -c user.email=a@b commit -q -m probe` in a linked worktree: `error: gpg failed to sign the data`, `fatal: failed to write commit object`, exit 128, and `/tmp/u4b1-cfc-oPSX/GPGRAN` exists, so hg ran the signing program (2026-10-13T22:12:52Z run).

**Evidence:** `skills/dev-cycle/SKILL.md:60`, `scratchpad/u4b1-i2/cfc-probe1.out`

---

## Claim 3b: "`--state` refuses those" (a filter, a merge driver)

**Location:** `skills/dev-cycle/SKILL.md:66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `filter.*`, `merge.*`, `gpg.*` keys in the common config, run from a linked worktree; does not establish keys outside `STATE_KEYS_RE` (claim 3c) or a plant after the run (claim 5).

```bash
STATE_KEYS_RE='^(filter\.|include|hook\.|merge\.|diff\.|core\.fsmonitor|core\.attributesfile|core\.hookspath|gpg\.|log\.showsignature|extensions\.partialclone$|remote\..*\.promisor$)'
```
(`scripts/build-loop.sh:612`). Executed `bash build-loop.sh --state` from the linked worktree `.claude/wt-x` of a clone: baseline `ok` exit 0; `filter.x.clean` → `refuse state filter.x.clean: set in config, ...` exit 2; `merge.x.driver` → `refuse state merge.x.driver: ...` exit 2; `gpg.program` → `refuse state gpg.program: ...` exit 2.

**Evidence:** `scripts/build-loop.sh:600-635`, `scratchpad/u4b1-i2/cfc-probe1.out`

---

## Claim 3c: "`--state` refuses those" (commit signing); also the commit message: "R1: hg does not switch off a filter, merge driver or commit signing in the repository's own config; only --state refuses those"

**Location:** `skills/dev-cycle/SKILL.md:66`; commit 0cd86cc0 message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Severity:** Medium
**Legibility-target:** for-author
**Scope:** Covers `commit.gpgSign`, `tag.gpgSign` and `user.signingKey` in the repository's config against `--state`, and `hg commit` under `commit.gpgSign=true`; does not establish what a real `gpg` with the user's keyring does (it would sign with the user's default or loop-chosen `user.signingKey`, or fail the commit).

`--state` refuses only `gpg.*` keys (the program and format), not the switch that turns signing on: `commit.gpgsign` does not match `^(...|gpg\.|...)` (`scripts/build-loop.sh:612`). Executed: `commit.gpgSign true` planted → `--state` prints `ok`, exit 0; `tag.gpgSign true` → `ok`; `user.signingKey X` → `ok`. With `commit.gpgSign` still set, `hg ... commit` ran `gpg` from PATH (claim 3a: shim ran, commit failed exit 128). So re-running `--state` before the commits does not catch commit signing: a loop that writes `commit.gpgSign=true` (and `user.signingKey`) into the shared `.git/config` gets the orchestrator's commits signed with the user's key, or failed. A fix is either `-c commit.gpgSign=false` (and `tag.gpgSign=false`) in hg (and HARDEN, which the pin test would then require in the lib and snippet too), or `commit\.gpgsign|tag\.gpgsign|user\.signingkey` in `STATE_KEYS_RE`, or narrowing the sentence to "a signing program".

**Evidence:** `scripts/build-loop.sh:612`, `skills/dev-cycle/SKILL.md:60`, `scratchpad/u4b1-i2/cfc-probe1.out`

---

## Claim 4: "so run it again (through the D6 block, from WT) right before the iteration's commits, and treat a refusal there as step 0 does"

**Location:** `skills/dev-cycle/SKILL.md:67-68`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `--state` run from a linked worktree reading the shared common config (it refuses a plant there) and step 0.1's handling being a stop with a judgment entry; does not establish running it through the D6 block (pending, Q-140; the intro's by-hand fallback applies) or coverage of keys `--state` does not check (claim 3c).

Executed from `.claude/wt-x`, a worktree on `chore/dev-cycle-2026-10-13-0000`: the plants in the common `.git/config` were refused (claim 3b). `state_gate` reads both config files via `--git-path`: "`for f in config config.worktree; do p="$(git rev-parse --path-format=absolute --git-path "$f" ...`" (`scripts/build-loop.sh:615-616`). Step 0.1: "refuse lines ... are a stop, quoted in one `you: judgment` entry unless an open one quotes the same lines; so is an exit 1, with its stderr" (`skills/dev-cycle/SKILL.md:210-213`).

**Evidence:** `scripts/build-loop.sh:613-635`, `skills/dev-cycle/SKILL.md:207-213`, `scratchpad/u4b1-i2/cfc-probe1.out`

---

## Claim 5: "A loop that plants one between that check and the commit is the residual Q-103 names."

**Location:** `skills/dev-cycle/SKILL.md:68-69`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Severity:** Low
**Legibility-target:** for-author
**Scope:** Covers Q-103's current text and the plan's U5 list of what Q-103 will name; does not establish U5's final wording (not written).

Q-103 today names no residual: it is the deferred self-merge policy question ("Once the build-loop handoff exists, may its build loops merge their own branches in claude-workflows, or must each stop for your review?", `docs/working/questions.md:78`). The plan makes it the home of same-uid trust ("**F35 rests on same-uid trust**, stated in Q-103.", `docs/working/plan-build-loop-handoff.md:436`) and U5 re-routes it "listing F11 ..., F19, F21, F29, F35, F37, F58 and F59, U2b1a2's R8 (a same-uid writer racing the gate's GATE_TMP ...)" (`docs/working/plan-build-loop-handoff.md:357`); a config plant between `--state` and the orchestrator's commit is not on that list. Precise version: "the same-uid residual U5 lists in Q-103", with this case added to U5's list.

**Evidence:** `docs/working/questions.md:75-90`, `docs/working/plan-build-loop-handoff.md:357`, `docs/working/plan-build-loop-handoff.md:436`

---

## Claim 6: "without them, the same script reads `N="$(git config --global --get user.name)"` and `E=…user.email…` ... and commits with `hg -c user.name="$N" -c user.email="$E" …`, never pasting the values into the script's text"

**Location:** `skills/dev-cycle/SKILL.md:70-74`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the recipe in a `bash -s` script under hg's `GIT_CONFIG_GLOBAL=/dev/null`, with a hostile name (a quote, `$(touch ...)`, backticks, `;`), and the empty case; does not establish a name holding a newline or the `GIT_AUTHOR_*` path.

Probe 1 set `HOME` to a dir whose `.gitconfig` held `name = "Ev\"il $(touch /tmp/u4b1-cfc-oPSX/PWNED) \`id\` ;x"`, cleared every `GIT_*` variable, and ran the recipe in a `bash -s <<G` script (cwd the linked worktree): the commit printed `author=Ev"il $(touch /tmp/u4b1-cfc-oPSX/PWNED) \`id\` ;x <e@x> committer=...` (same), exit 0, and `ls PWNED` failed (no such file): the value stayed data and hg's `/dev/null` global did not lose the identity. With an empty `HOME`, `N="$(git config --global --get user.name)"` gave `rc=1 N=[]`, the "empty: stop" case.

**Evidence:** `skills/dev-cycle/SKILL.md:60`, `scratchpad/u4b1-i2/cfc-probe1.sh`, `scratchpad/u4b1-i2/cfc-probe1.out`

---

## Claim 7: "(a read, the one plain `git` here; either empty: stop)"

**Location:** `skills/dev-cycle/SKILL.md:72`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers "here" as the hardened-git Rule (the `bash -s <<'G'` script); does not establish the rest of the file: step 7's `git mv` (`SKILL.md:401`, U4b2's step) is another plain git.

Grep of SKILL.md for plain git commands: `:40` ("never `git add -A`", a prohibition), `:71` (this read), `:271` (prose, "git allows"), `:401` ("`git mv` the brief there", step 7, unchanged and deferred to U4b2 per the brief) (paraphrased — no quote available because the claim is about absence across the file; the grep lines are named).

**Evidence:** `skills/dev-cycle/SKILL.md:40`, `skills/dev-cycle/SKILL.md:71`, `skills/dev-cycle/SKILL.md:401`

---

## Claim 8: "Never export these settings: set them per command, as `hg` does (`--state` refuses a caller's config pair for a `HARDEN` key, row 702)."

**Location:** `skills/dev-cycle/SKILL.md:74-75`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `caller_gate`'s refusal of `git -c`/`GIT_CONFIG_COUNT` pairs on HARDEN (and state) keys, executed in i1 (claim 11a) with the script unchanged since; makes no claim that exported variables such as `GIT_CONFIG_GLOBAL` are refused (they are not: i1 claim 11b), which is R2's fix.

```bash
    for kv in "${HARDEN[@]}"; do kv="${kv%%=*}"; [[ "$k" != "${kv,,}" ]] || k+=" "; done  # a trailing blank marks a HARDEN key
    if [[ "$k" == *" " || "$k" =~ $STATE_KEYS_RE ]]; then
```
(`scripts/build-loop.sh:668-669`; excerpt ends :669; enclosing `caller_gate` continues to :674 — read).

**Evidence:** `scripts/build-loop.sh:660-674`

---

## Claim 9: "the cycle rules `build-loop.sh --cycle-diff` applies to the chore commit repeat only part of `--check-fix` (a `.md` under `docs/working/` or `docs/reviews/`, a doc an instruction file imports, a directory at an instruction file's name and a symlink pass them; rows 764, 769, 771)"

**Location:** `skills/dev-cycle/SKILL.md:137-140`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Severity:** Low
**Legibility-target:** for-author
**Scope:** Covers `--cycle-diff` and `dev-cycle.sh --check-fix` on each named class in a clone; does not establish `--land-cycle`'s run of the same rules (same `cycle_rules`, not executed).

All five pass `--cycle-diff` (`ok`, exit 0, each staged alone on `chore/dev-cycle-2026-10-13-1200`: `docs/working/scratch-note.md`, `docs/reviews/new-review.md`, `docs/imp.md` imported by `@docs/imp.md` in AGENTS.md, `docs/agents.md/x.md`, a symlink `docs/link.md`; probes 2-3, 2026-10-13T22:13:44Z and 22:14:21Z). `--check-fix` refuses four of them: `skip docs/working/scratch-note.md: in-cycle fixes edit only ...`, the same for `docs/reviews/`, `skip docs/imp.md: an instruction file names it after an @ ...`, `skip docs/link.md: reached through a symlink, or not a regular file`. The directory case is not one `--check-fix` refuses as such: a tracked `docs/AGENTS.md/x.md`, `docs/CLAUDE.md/x.md` or `docs/agents.md/x.md` prints `ok` (it reads only the basename: `isstart() { [[ "${1##*/}" =~ $INSTRUCTION_FILE ]] ...`, `scripts/lib/dev-cycle-read.sh:712`); only a new file there is refused, as any untracked path is (`skip docs/CLAUDE.md/new.md: no tracked file ... matches`). Row 769's own rationale is the creation case ("it blocks creating that file"). Precise version: "... and a new file under a directory at an instruction file's name pass them" (a tracked one passes both).

**Evidence:** `scripts/build-loop.sh:1916-1945`, `scripts/dev-cycle.sh:183-198`, `scripts/lib/dev-cycle-read.sh:712`, `scripts/lib/dev-cycle-read.sh:1914-1923`, `scratchpad/u4b1-i2/cfc-probe2.out`, `scratchpad/u4b1-i2/cfc-probe3.out`

---

## Claim 10: "It refuses (`refuse d6: WHY`, exit 2, nothing run) a replace ref, grafts, a default branch that is not exactly one plain main or master naming a commit, an object it cannot read whole or that does not hash to its id, and more (its header lists every case: the image copy's ownership checks, a failed git read or temp dir)."

**Location:** `skills/dev-cycle/SKILL.md:182-186`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the summary against the snippet's header and its first checks; does not re-execute each refusal (i1 claims 4-5a executed the snippet; it is unchanged in the range).

```
# with nothing run, for a replace ref, info/grafts, a default branch that is
# not exactly one plain main or master or whose ref names no commit itself, a
# first-parent history, tree or file that cannot be read whole or does not hash
# to its id (a shallow history among them), a script on main that is not a
# regular file, an image copy that fails the ownership checks, or a git read or
# temp-dir step that fails
```
(`test/lib/d6-snippet.bash:30-35`). i1's omission (claim 15) is covered by "and more (its header lists every case ...)".

**Evidence:** `test/lib/d6-snippet.bash:29-60`

---

## Claim 11: "Any `other` line, or a `refuse main-log:` line other than the bootstrap's own (SINCE is off main's history: main rewritten, or a wrong `Main at:`; or the history could not be listed), blocks this iteration's dispatch ..."

**Location:** `skills/dev-cycle/SKILL.md:222-226`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the refusal causes and the bootstrap's refusal shape; does not establish the dispatch step itself (U4b2's).

```bash
    || { echo "main $MAIN_SHA -"; echo "refuse main-log: the default branch's first-parent history could not be listed"; return 1; }
  ...
    || { echo "main $MAIN_SHA -"; echo "refuse main-log: $1 is not on the default branch's first-parent history at $MAIN_SHA"; return 1; }
```
(`scripts/build-loop.sh:1802`, `:1805`; `main_log` runs `:1798-1815`, read). Executed in a clone: 40 zeros → `main 596966f0... -`, `refuse main-log: 0000...0000 is not on the default branch's first-parent history at 596966f0...`, exit 2 (the bootstrap's own); a chore-branch commit as SINCE → the same refusal naming it, exit 2 (the "wrong `Main at:`" case). The orchestrator knows the bootstrap's refusal because it passed the zeros.

**Evidence:** `scripts/build-loop.sh:141-183`, `scripts/build-loop.sh:1796-1815`, `scratchpad/u4b1-i2/cfc-probe1.out`

---

## Claim 12: Commit message: "no script change" and "Rubric and fact-check report included"

**Location:** commit 0cd86cc0 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the diffstat of 458dc170..0cd86cc0; does not establish the rubric's content.

`git diff --stat 458dc170..0cd86cc0`: `docs/reviews/code-fact-check-report-2026-10-13-u4b1-i1.md | 602 +`, `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4b1.md | 45 +`, `skills/dev-cycle/SKILL.md | 48 +-`, 3 files; no `scripts/` or `test/` path.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4b1.md`, `docs/reviews/code-fact-check-report-2026-10-13-u4b1-i1.md`

---

## Claim 13: Commit message: "A2: no references to steps U4b2 has not written."

**Location:** commit 0cd86cc0 message; `skills/dev-cycle/SKILL.md:137`, `:224`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers "step 8/9/10" text in SKILL.md; does not establish step 7's internal consistency with the new Rules (i1 claim 25, Stale, deferred to U4b2 per the brief).

`grep -n "step 9\|step 10\|steps 9\|step 8" skills/dev-cycle/SKILL.md` returns nothing (paraphrased — no quote available because the claim covers absence of text). The former references now read "the cycle rules `build-loop.sh --cycle-diff` applies to the chore commit" (`:137`) and "blocks this iteration's dispatch" (`:224`).

**Evidence:** `skills/dev-cycle/SKILL.md:137`, `skills/dev-cycle/SKILL.md:224`

---

## Claims Requiring Attention

### Incorrect
- **Claim 3c** (`skills/dev-cycle/SKILL.md:66`, and the commit message): `--state` does not refuse commit signing; `commit.gpgSign`, `tag.gpgSign` and `user.signingKey` in `.git/config` print `ok`, and `hg commit` then runs `gpg` (executed). Add `-c commit.gpgSign=false` (and `tag.gpgSign=false`) to hg/HARDEN, add the keys to `STATE_KEYS_RE`, or narrow the text to "a signing program".

### Mostly Accurate
- **Claim 5** (`skills/dev-cycle/SKILL.md:68-69`): Q-103 names no residual today, and U5's planned list for it does not include a config plant between `--state` and the commit; say "the same-uid residual U5 lists in Q-103" and add it to U5's list.
- **Claim 9** (`skills/dev-cycle/SKILL.md:137-140`): `--check-fix` prints `ok` for a tracked file under `docs/AGENTS.md/`; it refuses only a new one (as any untracked path). Say "a new file under a directory at an instruction file's name".

## Escalations

- **security-reviewer:** Claim 3c: a loop-writable `commit.gpgSign=true` (with an optional `user.signingKey`) in the shared `.git/config` passes `--state` and makes the orchestrator's hg commits invoke `gpg` with the user's keyring (signing with the user's key, or failing every commit); also the merge-driver path through an in-tree `.gitattributes` is only as safe as `--state`'s `merge.*` check at that moment (the time-of-check gap claim 5 names).
- **api-consistency-reviewer:** none new.

## Goal-Alignment Note

The goal is landing U4b1 after a clean loop; SKILL.md is instructions an orchestrator executes. Five of the six i1 Incorrect/Attention items are resolved, each checked by execution where it is executable (identity recipe with a hostile name, `--main-log` bootstrap, `--state` from the iteration's worktree, the hg pin test). R1 is only partly resolved: the new sentence moved the over-claim from hg to `--state`, which refuses filters, merge drivers and `gpg.*` but not the `commit.gpgSign` switch, so the "re-run `--state` before the commits" remedy does not cover commit signing, one of the three things it names. That is a one-line fix in either the script or the text, and the choice (hardening vs wording) is the security reviewer's. The two Mostly-accurate items are wording that tracks residuals and check-fix coverage slightly more broadly than the code and the questions file do.
