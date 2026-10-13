Commit: 4c911717

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u4b1`, branch `feat/build-loop-u4b1`)
**Scope:** `git diff main...HEAD` (458dc170, 0cd86cc0, 4c911717) and the three commit messages; final confirming pass, replicate 2 (role tag `fc2`)
**Checked:** 2026-10-13
**Total claims checked:** 30
**Summary:** 23 verified, 3 mostly accurate, 2 stale, 2 incorrect, 0 unverifiable

Execution provenance. Every probe ran with cwd `/workspace/.claude/wt-build-loop-u4b1` as `timeout N bash <scratch>/fc2/pK-*.sh > <scratch>/fc2/pK-*.txt 2>&1` (wrapper exit 0 for every probe; each command's own exit is printed inside the .txt). Each probe creates its own `mktemp -d /tmp/u4b1-fc2-XXXX` (a clone of /workspace where it runs a script mode) and removes it; no process remained (`ps` checked after the suites). `<scratch>` = `/tmp/claude-1000/-workspace/5f7c1a26-c882-447d-bbc1-af5199ac916b/scratchpad` (the brief allows writing only this report in the repo, so logs and probe scripts stay there). Timestamps (UTC): p1 22:29:11, p2 22:29:25, p3 22:29:46, p4 22:29:56-22:32:36, p5 22:30:09, p6 22:31:14, p7 22:31:50, p8 22:33. Hallucination pattern log read: no claim matches a logged pattern, and neither Incorrect is a fabricated symbol (nothing appended).

Each claim also carries **Severity** and **Legibility-target** (brief's success criterion).

---

## Claim 1: "no commit signing (commit.gpgSign runs gpg.program on a commit or merge: the orchestrator's own commits, SKILL.md's hg; U4b1 i2 security F1)"

**Location:** `scripts/lib/dev-cycle-read.sh:341-343`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `git commit` under a repo-planted `commit.gpgSign=true` + `gpg.program` with the pre-fix hg (no pair); does not establish behaviour for `tag.gpgSign` or `rebase`/`am` signing paths (the orchestrator runs none).

With the hg line minus `-c commit.gpgSign=false` (`hg_old` in p1), a commit in a clone whose `.git/config` holds `commit.gpgSign true`, `user.signingKey ABCDEF`, `gpg.program $T/fakegpg` printed `error: gpg failed to sign the data` and the fake program logged `gpg ran: --status-fd=2 -bsau ABCDEF` (p1-gpg.txt).

**Evidence:** `scripts/lib/dev-cycle-read.sh:341-354`, `<scratch>/fc2/p1-gpg.sh`, `<scratch>/fc2/p1-gpg.txt`

---

## Claim 2: HARDEN gains `commit.gpgSign=false`, and the lib, the snippet's G and SKILL.md's hg carry the same pairs, pinned by the git_harden test (commit 4c911717 B1; 458dc170 "both mutants fail it")

**Location:** `scripts/lib/dev-cycle-read.sh:354`, `test/lib/d6-snippet.bash:45`, `skills/dev-cycle/SKILL.md:65`, `test/scripts/build-loop-orchestrator.bats:355-372`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers equality of the `-c` pair list and the `GIT_*` env list across the three copies and the one-hg-line count; does not establish pair *order* in G/hg against HARDEN beyond the test's space-joined comparison (which is order-sensitive, so order is pinned too).

```bash
HARDEN=(core.useReplaceRefs=false core.hooksPath=/dev/null core.fsmonitor=false core.attributesFile=/dev/null core.commitGraph=false core.multiPackIndex=false log.date=default log.showSignature=false commit.gpgSign=false)
```
(`scripts/lib/dev-cycle-read.sh:354`). The test passed on the branch (`ok 1 git_harden exports ...`). In a copy of `scripts/ test/ skills/`, five mutants each fail it: SKILL.md's hg without the pair (fails at line 369), the snippet's G without it (369), the lib without it (diff `< GIT_CONFIG_KEY_9=commit.gpgSign`), SKILL.md's hg without `GIT_OPTIONAL_LOCKS=0` (370), and a duplicated hg line (367) (p3-bats.txt; its `rc=0` lines are the subshell's pipe status, the `not ok` lines are the result). The commit's "counts 10 pairs" is the test's `GIT_CONFIG_COUNT=10`: the caller's one pair plus HARDEN's nine.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:355-372`, `<scratch>/fc2/p3-bats.sh`, `<scratch>/fc2/p3-bats.txt`

---

## Claim 3: "a caller pair ... setting a key the state gate refuses or one this script's own hardening sets (the lib's HARDEN list: ..., log.showSignature, commit.gpgSign ...)" — and --state never refused a repo-planted commit.gpgSign (4c911717 B1)

**Location:** `scripts/build-loop.sh:134-140`; commit 4c911717 body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `--state` with a caller pair via `GIT_CONFIG_PARAMETERS` and via `GIT_CONFIG_COUNT`, and with the key planted in `.git/config`; does not establish `--main-log`'s or other modes' handling of caller pairs (they skip the caller check by design: p5 shows `--main-log` exit 0 with the same pair).

p5 in a clone: clean `--state` → `ok`, exit 0; `GIT_CONFIG_PARAMETERS='commit.gpgSign'='false'` → `refuse state commit.gpgsign: set by the caller's git -c or GIT_CONFIG_COUNT pairs ...`, exit 2; `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=commit.gpgsign` → same line, exit 2; `git config commit.gpgSign true` in the repo → `ok`, exit 0 (the state gate's `STATE_KEYS_RE='^(filter\.|include|hook\.|merge\.|diff\.|...|gpg\.|log\.showsignature|...)'`, `scripts/build-loop.sh:612`, has no `commit.` key), confirming B1's premise.

**Evidence:** `scripts/build-loop.sh:612`, `scripts/build-loop.sh:660-674`, `<scratch>/fc2/p5-modes.sh`, `<scratch>/fc2/p5-modes.txt`

---

## Claim 4: "No other HARDEN user commits with a signature (build-loop.sh's commit-tree passes --no-gpg-sign; dev-cycle.sh and the snippet never commit)"

**Location:** commit 4c911717 body
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the commit-writing call sites in the three HARDEN users and the six suites passing with the new pair; does not establish that a future caller relying on `commit.gpgSign=true` from its own git -c is unaffected (caller_gate now refuses it, by design).

```bash
    && x="$(gate_git commit-tree --no-gpg-sign -p "$MAIN_SHA" -p "${VERDICT[tip]}" "${VERDICT[tree]}" < "$GATE_TMP/msg")" \
```
(`scripts/build-loop.sh:1558`). A grep for `commit-tree|git commit|g commit` in `scripts/dev-cycle.sh` and `test/lib/d6-snippet.bash` matched only comments (paraphrased — no quote available because the claim covers absence of code: no matching grep results beyond comment lines 265, 289, 450, 468). The suites `build-loop-orchestrator, -merge, -dispatch, -read, -check, dev-cycle` ran `1..288`, 288 `ok`, exit 0 (p4).

**Evidence:** `scripts/build-loop.sh:1558`, `<scratch>/fc2/p4-suites.txt`

---

## Claim 5: (brief item 1) with commit.gpgSign/user.signingKey planted in a clone's .git/config, an hg commit and an hg merge run no gpg

**Location:** `skills/dev-cycle/SKILL.md:65`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `hg commit` and `hg merge --no-edit` with hg evaluated verbatim from SKILL.md's line; does not establish signature *verification* paths (claim 6).

p1 evaluated `grep '^  hg() { env ' SKILL.md` and, with the planted keys, got `hg commit rc=0`, `hg merge rc=0` (`Merge branch 'side'`), and `gpg.log after hg: none`.

**Evidence:** `skills/dev-cycle/SKILL.md:65`, `<scratch>/fc2/p1-gpg.txt`

---

## Claim 6: "`hg` reads no global or system config and runs no hook, fsmonitor command, signing program or replaced object"

**Location:** `skills/dev-cycle/SKILL.md:68-70`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Severity:** Low
**Legibility-target:** for-author
**Scope:** Covers signing and signature verification on `hg merge`; does not establish every other config-named program (diff.external, core.pager on a tty), which the Rule's next sentence leaves to `--state`.

hg switches signing off (claim 5), but `gpg.program` still runs under hg when the repository's config sets `merge.verifySignatures true` and the merged branch has a commit with a `gpgsig` header: p2 printed `fatal: Commit 3a9d42c does not have a GPG signature.` and the fake program logged `gpg ran: --keyid-format=long --status-fd=1 --verify ...`. The program is not run for *signing*, so the sentence is right about signing, but a reader may take "runs no signing program" as "gpg.program never runs". `--state` does refuse both keys (`merge\.` and `gpg\.` in `STATE_KEYS_RE`, `scripts/build-loop.sh:612`), so the Rule's next sentence ("It does not switch off what the repository's own config can still name (a filter, a merge driver): `--state` refuses those") covers the case. Precise version: "... and signs nothing (a planted `merge.verifySignatures` can still run `gpg.program`: `--state` refuses it)".

**Evidence:** `skills/dev-cycle/SKILL.md:68-72`, `scripts/build-loop.sh:612`, `<scratch>/fc2/p2-verify.sh`, `<scratch>/fc2/p2-verify.txt`

---

## Claim 7: "It does not switch off what the repository's own config can still name (a filter, a merge driver): `--state` refuses those, but only when it runs, so run it again (through the D6 block, from WT) right before the iteration's commits"

**Location:** `skills/dev-cycle/SKILL.md:70-73`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the state gate's key set for filters and merge drivers, read in both the common config and config.worktree; does not establish the window between that run and the commit (the Rule names it as Q-103's residual).

`STATE_KEYS_RE='^(filter\.|include|hook\.|merge\.|diff\.|...)'` (`scripts/build-loop.sh:612`) and `for f in config config.worktree; do p="$(git rev-parse --path-format=absolute --git-path "$f" ...)` (`scripts/build-loop.sh:615-616`; excerpt ends :616; enclosing `state_gate` continues to :634 — read). The run from WT reading the common config was executed in i2 (claim 3b there) and `state_gate` is unchanged since.

**Evidence:** `scripts/build-loop.sh:600-634`

---

## Claim 8: "Commits set their identity on the command, as `GIT_AUTHOR_NAME`, ... (these outrank a planted `author.*` or `committer.*` key)"

**Location:** `skills/dev-cycle/SKILL.md:74-77`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `hg commit` with `author.name/email`, `committer.name/email` and `user.name/email` all planted in `.git/config`; does not establish the global-config read's own trust (`git config --global` reads a file a loop can write; the trust model's, not this claim's).

p1: `author=Orch <orch@x> committer=Orch <orch@x>` despite `author.name Planted`, `committer.name PlantedC`, `user.name PU` in the repo config.

**Evidence:** `<scratch>/fc2/p1-gpg.txt`

---

## Claim 9: "Never export these settings: set them per command, as `hg` does (`--state` refuses a caller's config pair for a `HARDEN` key, row 702)"

**Location:** `skills/dev-cycle/SKILL.md:79-80`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers caller pairs (claim 3's runs, now including commit.gpgSign); does not establish that exported variables like `GIT_CONFIG_GLOBAL` are refused (they are not: `stray_vars` lists only `git rev-parse --local-env-vars`, `scripts/build-loop.sh:645`), which is 0cd86cc0's R2 wording.

```bash
    for kv in "${HARDEN[@]}"; do kv="${kv%%=*}"; [[ "$k" != "${kv,,}" ]] || k+=" "; done  # a trailing blank marks a HARDEN key
```
(`scripts/build-loop.sh:668`; excerpt ends :668; enclosing `caller_gate` continues to :674 — read).

**Evidence:** `scripts/build-loop.sh:645`, `scripts/build-loop.sh:660-674`, `<scratch>/fc2/p5-modes.txt`

---

## Claim 10: "A `build-loop.sh` answer is exit 0, or exit 2 with the mode's own refuse lines; any other exit (1 included), or a call the Bash tool timed out, means nothing was decided (a writing mode may have stopped part way)"

**Location:** `skills/dev-cycle/SKILL.md:51-54`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Severity:** Low
**Legibility-target:** for-author
**Scope:** Covers the Exit paragraph and `--state`/`--main-log` as run in step 0; does not establish `--check`/`--merge`/`--land-cycle` exits beyond the header (not executed here).

Exit 1 as "nothing decided" matches the header: "a caller reads any exit but 0 as nothing decided. 1 bad usage, a GIT_CONFIG_COUNT that is not plain decimal, ..." (`scripts/build-loop.sh:517-518`). But exit 2 is not only "with the mode's own refuse lines": "2 any other --check, --merge, --start or --prompt verdict line, --main-log's other or refuse line" (`scripts/build-loop.sh:513-515`). p5 ran `--main-log` from `main~3`: three `other SHA SUBJECT` lines, no refuse line, exit 2. Step 0.2 handles `other` lines explicitly, so the step-0 outcome is right, but the Rule's literal test classifies an exit 2 with no refuse line as neither form. Precise version: "exit 0, or exit 2 with the mode's documented lines (refuse lines, `--main-log`'s `other`, a non-ok verdict)".

**Evidence:** `scripts/build-loop.sh:511-521`, `<scratch>/fc2/p5-modes.txt`

---

## Claim 11: "Each stop ends the iteration there, with no record ...: the line and stderr go in one `agent` entry" (Rules) vs step 0.1 "refuse lines ... are a stop, quoted in one `you: judgment` entry ...; so is an exit 1, with its stderr"

**Location:** `skills/dev-cycle/SKILL.md:52-57`, `skills/dev-cycle/SKILL.md:211-215`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Severity:** Medium
**Legibility-target:** for-author
**Scope:** Covers the route of a `--state` exit 1; does not establish which route is intended (the text gives both).

The Rule names "any other exit (1 included)" as a stop whose "line and stderr go in one `agent` entry". Step 0.1 names `--state`'s exit 1 as a stop "quoted in one `you: judgment` entry". A `--state` exit 1 is both (header: "Exit 1 (stderr only) when a caller's git setting stops git or the script first", `scripts/build-loop.sh:127-129`), so the orchestrator is told to file it under two different routes. i2's api-consistency finding 4 noted routes differing by cause as defensible; this is one cause given two routes. Fix: in step 0.1 either drop "so is an exit 1" (the Rule's `agent` route applies) or make the Rule say "unless the step names its own entry".

**Evidence:** `skills/dev-cycle/SKILL.md:51-57`, `skills/dev-cycle/SKILL.md:211-215`, `scripts/build-loop.sh:122-129`

---

## Claim 12: "`refuse d6: WHY` (exit 2) means nothing ran" and the D6 block section's refusal list ("a replace ref, grafts, a default branch that is not exactly one plain main or master naming a commit, an object it cannot read whole or that does not hash to its id, and more (its header lists every case: ...)")

**Location:** `skills/dev-cycle/SKILL.md:50-51`, `skills/dev-cycle/SKILL.md:182-191`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers agreement with the snippet's header and its `no` calls; does not establish the snippet's runtime (exercised by the orchestrator suite's d6 tests in p4, not re-probed).

"Exit: the script's own status; 2 and one "refuse d6: WHY" line on stdout, with nothing run, for a replace ref, info/grafts, a default branch that is not exactly one plain main or master or whose ref names no commit itself, a first-parent history, tree or file that cannot be read whole or does not hash to its id ..., an image copy that fails the ownership checks, or a git read or temp-dir step that fails" (`test/lib/d6-snippet.bash:29-35`).

**Evidence:** `test/lib/d6-snippet.bash:29-41`, `test/lib/d6-snippet.bash:47-94`

---

## Claim 13: The by-hand fallback: "every `dev-cycle.sh` call ... as `~/.claude/scripts/dev-cycle.sh` ...; WT made as step 0.3 says, from the default branch's commit (`hg -C MAIN_WT rev-parse --verify refs/heads/main`, or master); the Rules' `hg` for every git command; ... With no `--state` run, nothing refuses the repository config `hg` cannot switch off (a filter or merge driver): the by-hand cycle carries that gap."

**Location:** `skills/dev-cycle/SKILL.md:19-26`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the script path's existence, the MAIN substitute for step 0.3 and the gap's statement; does not establish that the gap is fully enumerated (the parenthetical gives examples: claim 6's `merge.verifySignatures`, `diff.external` are in the same class).

`~/.claude/scripts -> /opt/claude-workflows/scripts`, `-r-xr-xr-x 1 root root ... dev-cycle.sh` and `questions.sh` (paraphrased — no quote available because this is an `ls -la` of the host, not repo text). Step 0.3 needs MAIN from `--main-log`, which the fallback does not run; the fallback supplies `rev-parse --verify refs/heads/main` instead. The symlink route is override row 2026-10-13 `feat/build-loop-u4b1` (Q-103 class), not re-flagged.

**Evidence:** `skills/dev-cycle/SKILL.md:19-26`, `skills/dev-cycle/SKILL.md:231-235`, `docs/reviews/override-log.md:775`

---

## Claim 14: "with no such line yet, pass 40 zeros: it prints `main MAIN -` and refuses, and that MAIN is the bootstrap"

**Location:** `skills/dev-cycle/SKILL.md:222-223`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `--main-log` with 40 zeros on a SHA-1 clone; does not establish a SHA-256 repository (64 zeros would be needed: the mode takes 40 or 64 hex, `scripts/build-loop.sh:545`).

p5: `main 596966f015a5f3d061b12f0761b041f3acfdca54 -` then `refuse main-log: 0000000000000000000000000000000000000000 is not on the default branch's first-parent history at 596966f0...`, exit 2.

**Evidence:** `scripts/build-loop.sh:543-545`, `<scratch>/fc2/p5-modes.txt`

---

## Claim 15: Step 0.2's reading: "Its first line `main MAIN N` names MAIN ...; read each later line's class and SHA by position (the subject is data). ... a `refuse main-log:` line other than the bootstrap's own (SINCE is off main's history: main rewritten, or a wrong `Main at:`; or the history could not be listed)"

**Location:** `skills/dev-cycle/SKILL.md:223-232`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the line format and refusal causes against the header and two runs; does not establish SINCE's derivation from the newest record (U4b2's, per the override row).

p5 from `main~3`: `main 596966f0... 3` then `other 413ce9dd... docs(questions): ...` (class, SHA, subject); from main itself `main 596966f0... 0`, exit 0. Header: "or "main MAIN -" and refuse main-log: WHY, when SINCE ... is not on that history (main was rewritten, or SINCE is on another branch) or it cannot be listed" (`scripts/build-loop.sh:180-183`).

**Evidence:** `scripts/build-loop.sh:141-183`, `<scratch>/fc2/p5-modes.txt`

---

## Claim 16: Step 0.3: "`hg -C MAIN_WT worktree add -b chore/dev-cycle-DATE-HHMM WT MAIN` ... WT is removed ... once the iteration's land is verified: every registered worktree costs disk and joins the import walks' reader set."

**Location:** `skills/dev-cycle/SKILL.md:233-235`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the branch name against `--main-log`'s/`--land-cycle`'s pattern and the reader-set reason; does not establish the removal step itself (U4b2's, per the override row).

"chore: ... B being chore/dev-cycle-DATE or chore/dev-cycle-DATE-HHMM" (`scripts/build-loop.sh:162-164`); "Both walks also read the repository's worktree registry (import_readers)" (`scripts/lib/dev-cycle-read.sh:49`).

**Evidence:** `scripts/build-loop.sh:162-164`, `scripts/build-loop.sh:244-246`, `scripts/lib/dev-cycle-read.sh:49`

---

## Claim 17: "It takes a lock in the git common directory, so it waits while a loop's gate runs (it says so once)"

**Location:** `skills/dev-cycle/SKILL.md:264-265`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `take_lock`; does not establish that loops' gates use the same file (they run the same script from their worktrees, which share the common dir).

```bash
    d="$(git -C "$REPO_ROOT" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 0
    lk="$d/health-check.lock"
    ...
    flock -n -E 75 -o "$lk" bash "$REPO_ROOT/scripts/health-check.sh" "$@" || rc=$?
    if [[ "$rc" -eq 75 ]]; then
        yellow "waiting for another health check in this repository (health-check.lock)"
        rc=0; flock -o "$lk" bash "$REPO_ROOT/scripts/health-check.sh" "$@" || rc=$?
```
(`scripts/health-check.sh:1107-1116`; excerpt ends :1116; enclosing `take_lock` continues to :1118 — read).

**Evidence:** `scripts/health-check.sh:1104-1118`

---

## Claim 18: "a wait past an hour is recorded, the run is stopped by its PID (it would still take the lock later), and the step's check is skipped (row 750)" (and 4c911717 "B8: an abandoned health check is stopped by its PID")

**Location:** `skills/dev-cycle/SKILL.md:266-267`; commit 4c911717 body
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Severity:** Medium
**Legibility-target:** for-author
**Scope:** Covers stopping the backgrounded health-check process (the PID the orchestrator's `&` gives) while it waits in `take_lock`; does not establish a process-group kill or `timeout` wrapper (neither is what the text says).

While waiting, the health check is two processes: the script's bash, and its child `flock -o "$lk" bash .../health-check.sh` (`scripts/health-check.sh:1116`). p7 reproduced `take_lock`'s lines with the payload swapped for `echo ran-after-wait`: with the lock held by another process, `ps --ppid <run>` showed `flock -o .../health-check.lock bash -c echo ran-after-wait ...`; stopping the run's PID (`run exit 143`) left that child, which took the lock once the holder released it and ran the payload (`ran file: ran-after-wait`). So stopping "the run ... by its PID" does not prevent the thing the parenthetical says it is for: the orphaned flock still takes the lock later and runs the full health check, holding the lock the loops' gates wait on (i2 performance F2's harm). Precise version: stop the waiting `flock` child too (its PID from `pgrep -P <run PID>`), or start the run under `timeout 3600` / in its own process group and stop the group.

**Evidence:** `scripts/health-check.sh:1104-1118`, `<scratch>/fc2/p7-lockkill.sh`, `<scratch>/fc2/p7-lockkill.txt`

---

## Claim 19: "`hg -C MAIN_WT worktree list` and `hg -C MAIN_WT worktree prune` (a locked worktree, a live loop's, is never pruned)"

**Location:** `skills/dev-cycle/SKILL.md:276-277`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers git's documented prune semantics and that `--start`/`--prompt` lock their worktrees; does not establish (not executed here) that a locked worktree whose directory was deleted survives prune.

"the worktrees and locks --start and --prompt make or replace" (`scripts/build-loop.sh:500-501`); `git worktree prune` skips locked worktrees (paraphrased — no quote available because this is git's own documented behaviour, not repo text).

**Evidence:** `scripts/build-loop.sh:495-503`

---

## Claim 20: "the cycle rules `build-loop.sh --cycle-diff` applies to the chore commit repeat only part of `--check-fix` (a `.md` under `docs/working/` or `docs/reviews/`, a doc an instruction file imports, a new file below a directory named like an instruction file, and a symlink pass them; rows 764, 769, 771)"

**Location:** `skills/dev-cycle/SKILL.md:140-145`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Severity:** Low
**Legibility-target:** for-author
**Scope:** Covers `--cycle-diff` and `--check-fix` on each named class plus a plain new `docs/*.md` in a clone on `chore/dev-cycle-2026-10-13-1200`; does not establish `--land-cycle`'s run of the same `cycle_rules` (same function, not executed).

p6: `--check-fix` printed `skip` for all six (`docs/working/scratch-note.md`, `docs/reviews/new-review.md`: "in-cycle fixes edit only tracked .md documentation ..."; `docs/imp.md`: "an instruction file names it after an @"; `docs/link.md`: "reached through a symlink"; `docs/claude.md/new.md` and `docs/plain-new.md`: "no tracked file ... matches"), and `--cycle-diff` printed `ok`, exit 0, for each staged alone. Every named case holds. The list's qualifier is narrower than the code: any new `.md` under docs/ passes the cycle rules (`if [[ "$TRUTH_WHY" != cycle && "$lp" != docs/*.md && "$lp" != readme.md ]]`, `scripts/build-loop.sh:1938`) and `--check-fix` refuses it (it ends in `check_path`, tracked files only: `scripts/dev-cycle.sh:197`), not only one under an instruction-file-named directory. The paragraph's earlier "anything else (a new file, ...) is filed, not written" (`SKILL.md:139-140`) already rules new files out, so a reader is not misled into staging one. Precise version: "a new file (one below a directory named like an instruction file among them)".

**Evidence:** `scripts/build-loop.sh:1916-1940`, `scripts/dev-cycle.sh:184-198`, `<scratch>/fc2/p6-checkfix.sh`, `<scratch>/fc2/p6-checkfix.txt`

---

## Claim 21: Settings: "**Build-loop slots** (live loops at once, 1-9; else 3: D9), **Self-merge never** (globs ... or `none`) and the optional **Reader roots** and **Reader homes** lines: read only through `build-loop.sh --settings`, from the default branch's commit, never from a working tree; ... A malformed never line turns self-merge off."

**Location:** `skills/dev-cycle/SKILL.md:111-116`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers agreement with `--settings`' header; does not establish the parser (exercised by the read/check suites in p4).

"slots N set|default: WHY / Loops at once: "Build-loop slots: N", N from 1 to 9; else 3." and "Malformed (or a file not read) turns self-merge off." (`scripts/build-loop.sh:30-39`); "five lines from the default branch's commit, never the working tree" (`scripts/build-loop.sh:19-20`).

**Evidence:** `scripts/build-loop.sh:19-60`

---

## Claim 22: Constraints: "`H1: …`, each with a `success:` line ... soft ones (`S1: …`). Every loop prompt quotes it, and every design choice a loop makes runs divergent design seeded with it (D2). ... The orchestrator dispatches only while `--settings` prints `constraints ok`."

**Location:** `skills/dev-cycle/SKILL.md:119-122`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the dispatch refusal and the prompt text; does not establish that a loop obeys the prompt.

`if [[ "$CONSTRAINTS" != ok ]]; then x="no loop is dispatched until --settings reads the constraints as ok ...` (`scripts/build-loop.sh:1637`); `The project's constraints (docs/constraints.md at $MAIN_SHA), quoted:` (`:1683`); `Run every design choice through divergent design seeded with these constraints` (`:1687`).

**Evidence:** `scripts/build-loop.sh:41-49`, `scripts/build-loop.sh:1637-1642`, `scripts/build-loop.sh:1683-1688`

---

## Claim 23: Drift check: "a `--merge` commit, with a `Build-loop-gate:` trailer ... the loop's research doc (`docs/working/research-STEM.md`, which the loop force-adds)"

**Location:** `skills/dev-cycle/SKILL.md:332-337`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the trailer and the prompt's force-add line; does not establish that the research doc exists at a given merge (the loop may not comply).

`printf "Merge branch '%s' (build-loop %s)\n\nBuild-loop-gate: %s\n"` (`scripts/build-loop.sh:1468`); `Force-add your research doc (git add -f docs/working/research-$s.md)` (`:1688`), `$s` the brief stem (`local a="$1" s="$2"`, `:1676`).

**Evidence:** `scripts/build-loop.sh:1468`, `scripts/build-loop.sh:1676-1688`

---

## Claim 24: Step 4b: "a drift finding from step 4" trigger and the "constraints and project guidance still match intent" dimension, checking `Self-merge never:` covers paths that take effect on merge (F57)

**Location:** `skills/dev-cycle/SKILL.md:349-357`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers agreement with the plan; does not establish anything executable.

"**Step 4b, deep audit**: a drift finding is a trigger; the audit gains the "constraints and project guidance still match intent" dimension (it also checks that `Self-merge never:` covers paths that take effect on merge, F57)." (`docs/working/plan-build-loop-handoff.md:256`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:175`, `docs/working/plan-build-loop-handoff.md:256`

---

## Claim 25: pr-prep: "Wait until no subagent this task started is still running; other sessions' agents and build loops share the uid and keep running (dev-cycle D14). ... stop each by its PID once its command line shows it is yours, never by a name or pattern"

**Location:** `workflows/pr-prep.md:333`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers agreement with D14; does not establish that `pgrep -a` command lines always identify the owner.

"The quiesce in step 1, and pr-prep's quiesce before its gate, cover only subagents this task started, and never stop or reap a process this task did not start (by PID)." (`docs/working/plan-build-loop-handoff.md:106`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:106`

---

## Claim 26: Plan split note: "SKILL.md is 397 lines ... **U4b1, the orchestrator's frame** (173 lines as written)"

**Location:** `docs/working/plan-build-loop-handoff.md:341-342`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers main's SKILL.md line count and 458dc170's non-docs numstat; does not establish the line count after the review fixes (148+29 in SKILL.md at HEAD, plus 16 in other code files).

`git show main:skills/dev-cycle/SKILL.md | wc -l` → 397; `git show --numstat 458dc170`: SKILL.md 130/29, the bats file 7/5, pr-prep 1/1 = 173 (paraphrased — no quote available because these are command outputs run inline, not saved to a file; reproducible with the two commands named).

**Evidence:** `docs/working/plan-build-loop-handoff.md:341-342`

---

## Claim 27: "Suites 288 green, run serially; shellcheck clean." (commit 4c911717)

**Location:** commit 4c911717 body
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the six build-loop/dev-cycle suites at HEAD (288 tests) and shellcheck at the health check's flags on the three changed shell files; does not establish the full health check.

p4: `1..288`, 288 `ok`, no `not ok`, `rc=0` (22:29:56-22:32:36Z). p8: `shellcheck -x -e SC1091 -s bash -S warning` (the health check's flags, `scripts/health-check.sh` check 6) on `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `test/lib/d6-snippet.bash`: exit 0 each.

**Evidence:** `<scratch>/fc2/p4-suites.txt`, `<scratch>/fc2/p8-shellcheck.txt`

---

## Claim 28: 0cd86cc0: "R1: hg does not switch off a filter, merge driver or commit signing in the repository's own config; only --state refuses those, when it runs." and "R2: --state refuses a caller's config pair, not an exported variable."

**Location:** commit 0cd86cc0 body
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers R1's "commit signing" atom at HEAD (R2 holds: claim 9); does not establish anything about the commit's state at the time (it was true at 0cd86cc0).

R1's "commit signing" atom was true at 0cd86cc0 and is no longer: 4c911717 added `-c commit.gpgSign=false` to hg, and p1 shows hg signs nothing with commit.gpgSign planted; also "only --state refuses those" was then false for commit signing (claim 3: `--state` does not refuse a repo-planted `commit.gpgSign`), which 4c911717's B1 states. A commit message is history, so this needs no change; it is recorded so the merge message does not repeat it.

**Evidence:** `<scratch>/fc2/p1-gpg.txt`, `<scratch>/fc2/p5-modes.txt`

---

## Claim 29: 458dc170: "Test: the git_harden test also pins SKILL.md's hg line to the lib's HARDEN pairs and the snippet's environment (both mutants fail it)."

**Location:** commit 458dc170 body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** None
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a pair mutant and an env mutant of SKILL.md's hg at HEAD; does not establish the exact two mutants the author ran.

See claim 2: `skill-drop-pair` fails at line 369, `skill-drop-env` at line 370 (p3).

**Evidence:** `<scratch>/fc2/p3-bats.txt`

---

## Claim 30: Rules: "The orchestrator's own git commands (worktrees, staging, its commits, merging main into WT, ancestry checks) run in a `bash -s <<'G'` script that starts with this line, never as bare `git` in its shell" vs step 6's "`git mv` the brief there"

**Location:** `skills/dev-cycle/SKILL.md:59-62`, `skills/dev-cycle/SKILL.md:409`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Severity:** Low
**Legibility-target:** for-author
**Scope:** Covers bare-git mentions left in SKILL.md after U4b1; does not establish whether U4b2's step 6 rewrite (plan split note) already plans to change it.

`create docs/working/briefs/closed/ if it is missing, `git mv` the brief there` (`skills/dev-cycle/SKILL.md:409`) is an orchestrator git command written as bare `git`, which the new Rule forbids; the U4b2 override row's list (step 7's name and land, slots, record date, Flow, `--no-edit`, rerere, `worktree remove`) does not name it, though the plan gives step 6 to U4b2. Line 43's "never `git add -A`" is a prohibition, not a command, and line 78's `git config --global` is the Rule's own named exception.

**Evidence:** `skills/dev-cycle/SKILL.md:43`, `skills/dev-cycle/SKILL.md:59-80`, `skills/dev-cycle/SKILL.md:409`, `docs/reviews/override-log.md:777`

---

## Claims Requiring Attention

### Incorrect
- **Claim 11** (`skills/dev-cycle/SKILL.md:52-57`, `:211-215`): a `--state` exit 1 is routed to an `agent` entry by the Rules and to a `you: judgment` entry by step 0.1; pick one.
- **Claim 18** (`skills/dev-cycle/SKILL.md:266-267`): stopping the waiting health check "by its PID" leaves `take_lock`'s `flock -o ... bash health-check.sh` child, which takes the lock later and runs anyway (executed); stop the flock child too, or bound it with `timeout`/a process group.

### Stale
- **Claim 28** (commit 0cd86cc0): R1's "hg does not switch off ... commit signing" is superseded by 4c911717 (history only).
- **Claim 30** (`skills/dev-cycle/SKILL.md:409`): step 6's bare `git mv` contradicts the new hardened-git Rule; not on the U4b2 override row's list.

### Mostly Accurate
- **Claim 6** (`skills/dev-cycle/SKILL.md:68-70`): hg signs nothing, but a planted `merge.verifySignatures` still runs `gpg.program` on `hg merge` (executed); `--state` refuses it.
- **Claim 10** (`skills/dev-cycle/SKILL.md:51-52`): exit 2 also carries `--main-log`'s `other` lines and non-ok verdicts, not only refuse lines.
- **Claim 20** (`skills/dev-cycle/SKILL.md:140-145`): any new `.md` under docs/ passes the cycle rules and is refused by `--check-fix`, not only one below an instruction-file-named directory.

### Unverifiable
- (none)

## Escalations

- **Claim 18 → performance-reviewer** (an orphaned lock holder runs the full suite and holds `health-check.lock` against the loops' gates; i2 F2's fix does not achieve its purpose) **and security-reviewer** (a health check from a removed or advanced WT runs later, outside the iteration's quiesce).
- **Claim 11 → api-consistency-reviewer** (one cause, two entry routes).
- **Claim 6 → security-reviewer** (confirm `--state`'s re-run before commits is the intended and sufficient cover for `merge.verifySignatures`/`gpg.program`).

## Goal-Alignment Note

The goal is to land U4b1 after a clean review-fix loop, with SKILL.md as the instructions an orchestrator follows. The unit's core fix holds under execution. `commit.gpgSign=false` is in all three copies, the pin test catches every mutant tried, `--state` refuses a caller pair for the key, hg signs nothing with signing planted, planted identities lose to the per-command variables, and the suites (288) and shellcheck pass. Two items would make the orchestrator do the wrong thing if followed literally. Claim 18: the hour-bound stop leaves a health check that runs later anyway. It matters only when a wait passes an hour, and is a one-clause fix. Claim 11: a `--state` exit 1 has two routes. Neither blocks the by-hand fallback, which is what runs until Q-140. Claims 6, 10, 20 and 30 are wording tightenings. 30 could equally go on the U4b2 override row.
