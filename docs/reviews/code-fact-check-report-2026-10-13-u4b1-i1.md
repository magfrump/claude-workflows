Commit: 458dc170
# Code Fact-Check Report

**Repository:** claude-workflows (worktree /workspace/.claude/wt-build-loop-u4b1, branch feat/build-loop-u4b1)
**Scope:** `git diff main...HEAD` (one commit, 458dc170): skills/dev-cycle/SKILL.md, workflows/pr-prep.md, test/scripts/build-loop-orchestrator.bats, docs/working/plan-build-loop-handoff.md, and the commit message
**Checked:** 2026-10-13
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 33
**Summary:** 24 verified, 4 mostly accurate, 1 stale, 4 incorrect, 0 unverifiable (split claims 5a/5b, 9a/9b, 11a/11b/11c counted per atom)

Execution logs (captured output, one file per probe; the probe scripts sit beside them) are in the session scratchpad, not the repo (the brief allows writing only this report): `/tmp/claude-1000/-workspace/5f7c1a26-c882-447d-bbc1-af5199ac916b/scratchpad/u4b1-i1/cfc-*.out`. Every probe ran in its own `mktemp -d /tmp/u4b1-cfc*-XXXX` dir (a clone of /workspace or a fresh `git init`), removed at its end. Hallucination pattern log read; no claim below matches a logged pattern, and no Incorrect verdict is a fabricated symbol (none is appended).

---

## Claim 1: "SKILL.md is 397 lines"

**Location:** `docs/working/plan-build-loop-handoff.md:341`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main's copy of skills/dev-cycle/SKILL.md (the one U4b rewrites); does not establish the branch's length.
**Legibility-target:** for-orchestrator-synthesis

`git show main:skills/dev-cycle/SKILL.md | wc -l` printed `397`. Command, cwd /workspace/.claude/wt-build-loop-u4b1, exit 0, 2026-10-13T22:06:55Z.

**Evidence:** `scratchpad/u4b1-i1/cfc-misc.out`

---

## Claim 2: "U4b1, the orchestrator's frame (173 lines as written)"

**Location:** `docs/working/plan-build-loop-handoff.md:342`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers changed lines outside docs/ (the plan's log-row-62 measure: SKILL.md 130+29, the bats file 7+5, pr-prep 1+1 = 173); does not establish any other counting rule.

`git diff --numstat main...HEAD` gave `130 29 skills/dev-cycle/SKILL.md`, `7 5 test/scripts/build-loop-orchestrator.bats`, `1 1 workflows/pr-prep.md`; python3 summed them to `173`. cwd the worktree, exit 0, 2026-10-13T22:06:55Z.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scratchpad/u4b1-i1/cfc-misc.out`

---

## Claim 3: "Until the D6 block is written (below; Q-140), no script can run as the Rules require."

**Location:** `skills/dev-cycle/SKILL.md:19-23`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that SKILL.md holds no snippet body yet (the section reads `Pending: Q-140`); does not establish that the by-hand fallback's own text is consistent with the rest of the file (see Claims 24-25).
**Legibility-target:** for-orchestrator-synthesis

```
## The D6 block

Pending: Q-140 (the snippet's trust root). Its canonical copy is
```
(`skills/dev-cycle/SKILL.md:168-170`). The Rules require every script call through that block (`:42-45`), so with the block absent the rule cannot be followed.

**Evidence:** `skills/dev-cycle/SKILL.md:19-23`, `skills/dev-cycle/SKILL.md:42-45`, `skills/dev-cycle/SKILL.md:168-176`

---

## Claim 4: "`cd WT && bash -s -- SCRIPT ARG... <<'D6'` ... In claude-workflows it runs main's own committed scripts, elsewhere the root-owned image copy" (run from MAIN_WT whatever branch it has out)

**Location:** `skills/dev-cycle/SKILL.md:42-47`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the call form (heredoc on stdin, script name then its args), the root test that picks main's copy vs `/opt/claude-workflows`, and that it works from a checkout on a branch other than main (it reads `refs/heads/main`, not HEAD); does not establish the trust of that choice (the snippet's own "Known gap", Q-140) or the image copy's path checks in a non-claude-workflows repo (no root-owned copy was exercised).

The snippet chooses by first-parent root:
```bash
    if ($c ne $root) { print "other\n"; exit 0 }
```
(`test/lib/d6-snippet.bash:75`), then `d="$t"` for main's verified copy or `d="$D6_OPT"` with the ownership checks (`:88-94`), and runs `env -u BASH_ENV -u ENV -u DEV_CYCLE_SCRUBBED bash "$d/scripts/$s" "$@"` (`:95`). It reads `refs/heads/$m` (`:56-59`), never HEAD. Executed in a clone of /workspace checked out on branch `notmain`: `bash -s -- build-loop.sh --state < test/lib/d6-snippet.bash` printed `ok`, exit 0; `--main-log` with 40 zeros printed `main 596966f0... -` then the refusal, exit 2; `dev-cycle.sh --check-path 'docs/roadmap.md'` printed `ok docs/roadmap.md`, exit 0; first argument `other.sh` printed `d6: the first argument is build-loop.sh or dev-cycle.sh`, exit 1 (cwd the clone, 2026-10-13T22:02:48Z).

**Evidence:** `test/lib/d6-snippet.bash:41-100`, `scratchpad/u4b1-i1/cfc-probe2.out`

---

## Claim 5a: "`refuse d6: WHY` (exit 2) means nothing ran"

**Location:** `skills/dev-cycle/SKILL.md:47-48`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the snippet's own refusals (each `no` exits before line 95 runs the script); does not establish the reading of a script's own output that might start with the same text (none of build-loop.sh's lines do).

```bash
  no() { echo "refuse d6: $*"; exit 2; }
```
(`test/lib/d6-snippet.bash:44`); every check calls `no` before the one `bash "$d/scripts/$s"` line (`:95`). Executed with a planted replace ref: `refuse d6: a replace ref exists (F38)`, exit 2 (fresh `git init` repo, 2026-10-13T22:06:47Z).

**Evidence:** `test/lib/d6-snippet.bash:44-95`, `scratchpad/u4b1-i1/cfc-probe7.out`

---

## Claim 5b: "... and so do an exit the mode does not document and a call the Bash tool timed out" (i.e. they too mean nothing ran)

**Location:** `skills/dev-cycle/SKILL.md:48-49`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Severity:** Low
**Scope:** Covers what build-loop.sh's header says a non-0 exit means; does not establish whether any mode actually hangs after a write (not executed).
**Legibility-target:** for-author

The script's own contract says a run can stop part way after doing work, and asks callers to read that as "nothing decided", not "nothing ran":
```
# --merge can also stop part way, after the lines of the briefs before, with 1
# (need_root) or a failed command's own status: a caller reads any exit but 0
# as nothing decided.
```
(`scripts/build-loop.sh:516-518`). A timed-out call is killed at an unknown point: `--land-cycle`, `--merge`, `--start` and `--prompt` write (a branch move, a worktree, a lock: header `:501-508`), so after a timeout some of that may have happened. The practical effect (a stop) holds, but the stated mechanism would mislead a reader deciding what to clean up or whether a land happened. Precise version: "...mean nothing was decided; a writing mode may have written part of its work: read main and the worktrees before retrying".

**Evidence:** `scripts/build-loop.sh:501-521`, `skills/dev-cycle/SKILL.md:47-51`

---

## Claim 6: "a full disk reads like planted state, so it is not called hostile" (environmental failures print `refuse d6:` too, row 742)

**Location:** `skills/dev-cycle/SKILL.md:50-51`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a temp-dir failure (mktemp) printing the same `refuse d6:` line and exit 2; does not establish every environmental failure (a perl missing Digest::SHA was not run).

`t="$(mktemp -d)" || no "mktemp failed"` (`test/lib/d6-snippet.bash:80`). Executed with `TMPDIR` pointing at a missing dir: mktemp's stderr line, then `refuse d6: mktemp failed`, exit 2 (2026-10-13T22:06:47Z).

**Evidence:** `test/lib/d6-snippet.bash:80-86`, `scratchpad/u4b1-i1/cfc-probe7.out`

---

## Claim 7: "The orchestrator's own git commands (worktrees, staging, its commits, merging main into WT, ancestry checks) run in a `bash -s <<'G'` script that starts with this line, never as bare `git` in its shell"

**Location:** `skills/dev-cycle/SKILL.md:53-56`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Severity:** Low
**Scope:** Covers the skill's own git calls named in this diff; does not establish whether the bare read is safe (escalated to security-reviewer below).
**Legibility-target:** for-author

Step 0.3 itself prescribes a bare git call: "read `user.name` and `user.email` with `git config --global --get` (a read; empty: stop)" (`skills/dev-cycle/SKILL.md:215-216`). It must be bare: hg's `GIT_CONFIG_GLOBAL=/dev/null` (`:59`) would make `hg config --global` read nothing. So the rule has one named exception the text does not state. Precise version: "...never as bare `git`, except step 0's read of the global identity". The value read (which the Rule's next paragraph says a loop can write) is then pasted as `-c user.name=NAME` into a heredoc script (`:66`); how it is quoted is not specified.

**Evidence:** `skills/dev-cycle/SKILL.md:53-67`, `skills/dev-cycle/SKILL.md:215-218`

---

## Claim 8: "`hg() { env GIT_NO_REPLACE_OBJECTS=1 ... "$@"; }` ... A test holds these pairs to the lib's `HARDEN` list" (and the snippet's environment; "both mutants fail it", commit 458dc170)

**Location:** `skills/dev-cycle/SKILL.md:59-64`
**Type:** Configuration / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `-c` pairs (order and values) against `HARDEN` and the `GIT_*=` assignments (as a sorted set) against git_harden's exported environment, and that exactly one `  hg() { env ... "$@"; }` line exists; does not establish that a non-`GIT_` assignment or another git option added to the line (say `--exec-path=X`) fails the test, since it greps only `-c ` tokens and `GIT_[A-Z_]*=` tokens.

The test (`test/scripts/build-loop-orchestrator.bats:367-371`):
```bash
    [ "$(grep -c '^  hg() { env .* "\$@"; }$' "$REPO_ROOT/skills/dev-cycle/SKILL.md")" -eq 1 ] || ...
    for g in "$(grep '^  G=(env ' ...d6-snippet.bash")" "$(grep '^  hg() { env ' ...SKILL.md")"; do
        [ "$(grep -o -- '-c [^ )]*' <<<"$g" | cut -c4- | tr '\n' ' ')" = "$H " ] || ...
        [ "$(grep -o 'GIT_[A-Z_]*=[^ ]*' <<<"$g" | LC_ALL=C sort | tr '\n' ' ')" = "$E " ] || ...
    done
```
Executed: `bats -f 'git_harden exports HARDEN' test/scripts/build-loop-orchestrator.bats` in the worktree: `ok 1`, exit 0. In a clone of the branch, five mutants of the hg line each failed it (exit 1): A one pair dropped (`log.showSignature`), B one env var dropped (`GIT_ATTR_NOSYSTEM`), C a value changed (`log.date=iso`), D an extra pair (`core.pager=cat`), E an extra env var (`GIT_PAGER=cat`). 2026-10-13T22:02:48Z.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:355-372`, `scripts/lib/dev-cycle-read.sh:352-362`, `test/lib/d6-snippet.bash:45`, `scratchpad/u4b1-i1/cfc-probe2.out`

---

## Claim 9a: "so neither runs anything here: no hook, fsmonitor ... and no replaced object"

**Location:** `skills/dev-cycle/SKILL.md:62-64`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a planted repo-config `core.hooksPath`, a `.git/hooks/pre-commit`, a planted `core.fsmonitor`, and a replace ref under `hg status`/`hg commit`/`hg cat-file`; does not establish the properties in 9b.

With all four planted in a fresh repo, the hg script's `status`, `commit` and `cat-file -p HEAD~2:f.txt` ran no planted program (`programs run under hg: (none)`) and read the original object (`replaced object read: base`). 2026-10-13T22:06:47Z.

**Evidence:** `skills/dev-cycle/SKILL.md:59`, `scratchpad/u4b1-i1/cfc-probe7.out`

---

## Claim 9b: "A build loop can write `.git/config` and `~/.gitconfig` as easily as a file, so neither runs anything here: no ... filter or signature program"

**Location:** `skills/dev-cycle/SKILL.md:62-64`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Severity:** Medium (behavioural: the skill tells the orchestrator its own git is safe from repo config, and the orchestrator runs `worktree add`, commits and merges with it)
**Scope:** Covers what hg's line itself switches off against the repository's own `.git/config` (the common config, which a loop's worktree shares); does not establish whether `--state` at step 0.1 catches the same keys (it does, as a snapshot: `STATE_KEYS_RE` refuses `filter.`, `merge.`, `diff.`, `gpg.`, `scripts/build-loop.sh:629`), nor the merge-driver case (that probe step failed for an unrelated dirty index).
**Legibility-target:** for-author

hg's line switches off the global and system config (`GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`) and sets only the eight `HARDEN` pairs (`skills/dev-cycle/SKILL.md:59`); none of them overrides `filter.*`, `commit.gpgSign`/`gpg.program` or `merge.*.driver` in the repository's own config, and `.git/info/attributes` is still read (`core.attributesFile=/dev/null` and `GIT_ATTR_NOSYSTEM` cover the global and system files only). Executed: with `filter.x.smudge/clean`, `commit.gpgSign=true`, `gpg.program` set in `.git/config` and `* filter=x merge=y` in `.git/info/attributes`, the hg script's `worktree add` ran the smudge filter, `add` ran the clean filter, and `commit` ran `gpg.program` (`gpg --status-fd=2 -bsau C <c@x>` logged). 2026-10-13T22:04:24Z. The claim holds only together with step 0.1's `--state`, and only as of that snapshot; a live loop shares `.git/config` and can write it after `--state`. Precise version: hg stops hooks, fsmonitor, replaced objects and the global/system config; repo-config filters, merge drivers and signing are stopped only by `--state`'s refusal at the iteration's start.

**Evidence:** `skills/dev-cycle/SKILL.md:59-64`, `scripts/build-loop.sh:617-650`, `scratchpad/u4b1-i1/cfc-probe3.out`

---

## Claim 10: "Commits take their identity from the environment's `GIT_AUTHOR_*` and `GIT_COMMITTER_*` names and emails, or else add `-c user.name=NAME -c user.email=EMAIL`"

**Location:** `skills/dev-cycle/SKILL.md:64-66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers commits under hg (`GIT_CONFIG_GLOBAL=/dev/null`) with the four env vars, with none (refused), and with `-c` pairs; does not establish `EMAIL`/host-guess behaviour or `--land-cycle`'s own identity rule (`merge_ident`, which also reads the caller's global config).

With the four vars set: `commit with env identity ok`, `A <a@x> / C <c@x>`; with none: `Author identity unknown ... commit without identity refused`; with `-c user.name=N -c user.email=e@x`: `commit with -c identity ok`. 2026-10-13T22:01:44Z.

**Evidence:** `scratchpad/u4b1-i1/cfc-probe1.out`

---

## Claim 11a: "Never export these settings: `--state` refuses a caller that sets one (row 702)" (the `-c` pairs)

**Location:** `skills/dev-cycle/SKILL.md:66-67`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers HARDEN keys passed as exported `GIT_CONFIG_COUNT` pairs and as `GIT_CONFIG_PARAMETERS` (git -c's carrier); does not establish 11b.

```bash
    for kv in "${HARDEN[@]}"; do kv="${kv%%=*}"; [[ "$k" != "${kv,,}" ]] || k+=" "; done  # a trailing blank marks a HARDEN key
```
(`scripts/build-loop.sh:666-667`, inside `caller_gate`, `:660-675`, read whole). Executed: `GIT_CONFIG_COUNT=1 ... core.hooksPath=/dev/null` → `refuse state core.hookspath: ...` exit 2; the same with `log.date=default` → exit 2; `GIT_CONFIG_PARAMETERS='core.commitGraph'='false'` → `refuse state core.commitgraph`, exit 2. 2026-10-13T22:01:44Z.

**Evidence:** `scripts/build-loop.sh:645-675`, `scratchpad/u4b1-i1/cfc-probe1.out`

---

## Claim 11b: "Never export these settings: `--state` refuses a caller that sets one" (hg's environment variables)

**Location:** `skills/dev-cycle/SKILL.md:66-67`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Severity:** Low (the advice stays sound; the stated guard does not exist for half of "these settings")
**Scope:** Covers the seven `GIT_*` assignments on hg's line exported to `--state`; does not establish harm from exporting them (one effect: `--land-cycle`/`--merge`'s identity reads the caller's `GIT_CONFIG_GLOBAL`, `scripts/build-loop.sh:593`, which would then be `/dev/null`).
**Legibility-target:** for-author

`caller_gate` refuses only repo-local variables (`git rev-parse --local-env-vars`, less `GIT_CONFIG_PARAMETERS`, `GIT_CONFIG_COUNT`, `GIT_NO_REPLACE_OBJECTS`, `GIT_PREFIX`) and caller pairs:
```bash
callervar() { [[ "$1" == GIT_CONFIG_PARAMETERS || "$1" == GIT_CONFIG_COUNT || "$1" == GIT_NO_REPLACE_OBJECTS ]]; }
```
(`scripts/build-loop.sh:640`). `GIT_CONFIG_GLOBAL`, `GIT_CONFIG_NOSYSTEM`, `GIT_ALLOW_PROTOCOL`, `GIT_LITERAL_PATHSPECS`, `GIT_OPTIONAL_LOCKS`, `GIT_ATTR_NOSYSTEM` are not local-env vars. Executed: all seven of hg's assignments exported → `ok`, exit 0 (2026-10-13T22:01:44Z). Precise version: "`--state` refuses a caller whose `-c` or `GIT_CONFIG_COUNT` pairs set one of these keys". (A one-command `hg` does not leak: a later `bash -c env` showed none of hg's variables; Claim 11c.)

**Evidence:** `scripts/build-loop.sh:636-675`, `scratchpad/u4b1-i1/cfc-probe1.out`

---

## Claim 11c: hg's settings apply to "that git process only" (no leak into a later `bash -s` call of build-loop.sh)

**Location:** `skills/dev-cycle/SKILL.md:53-60`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers hg defined as a function inside a separate `bash -s` script using `env ... git`; does not establish an orchestrator that defines hg in its own (zsh) shell, which the Rule forbids.

`env VAR=... git ...` sets the variables for the git child only; the probe's next process listed only the session's own `GIT_AUTHOR_*`/`GIT_COMMITTER_*`/`GIT_EDITOR` (none of hg's), and `--state` from a clean environment printed `ok`. 2026-10-13T22:01:44Z.

**Evidence:** `skills/dev-cycle/SKILL.md:59`, `scratchpad/u4b1-i1/cfc-probe1.out`

---

## Claim 12: Settings "Build-loop slots (live loops at once, 1-9; else 3: D9) ... read only through `build-loop.sh --settings`, from the default branch's commit ... A malformed never line turns self-merge off."

**Location:** `skills/dev-cycle/SKILL.md:98-103`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the slots rule, the never-line rule and the commit-not-working-tree read as the header and its tests state them; does not establish the Reader roots/homes lines' forms (named, not described).

Header: `slots N set|default: WHY ... "Build-loop slots: N", N from 1 to 9; else 3` and `Malformed (or a file not read) turns self-merge off` (`scripts/build-loop.sh:31-39`); `five lines from the default branch's commit, never the working tree` (`:19-20`). Executed: `bats -f "slots are 1 to 9|turns self-merge off" test/scripts/build-loop-read.bats` → `ok 1`, `ok 2`, exit 0 (2026-10-13T22:04:56Z).

**Evidence:** `scripts/build-loop.sh:19-61`, `test/scripts/build-loop-read.bats:96-150`, `scratchpad/u4b1-i1/cfc-probe4.out`

---

## Claim 13: "Every loop prompt quotes it ... The orchestrator dispatches only while `--settings` prints `constraints ok`." (and `--start` itself refuses otherwise)

**Location:** `skills/dev-cycle/SKILL.md:106-109`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--start` (and by the header `--prompt`, "under the same rules") refusing unless the constraints word is `ok`, and the prompt quoting docs/constraints.md at MAIN_SHA; does not establish that the orchestrator itself checks the line before calling (the gate enforces it either way).

```bash
  if [[ "$CONSTRAINTS" != ok ]]; then x="no loop is dispatched until --settings reads the constraints as ok (${CONSTRAINTS_LINE#constraints })"
```
(`scripts/build-loop.sh:1637`); prompt `The project's constraints (docs/constraints.md at $MAIN_SHA), quoted:` (`:1683`). Executed: `bats -f "without ok constraints" test/scripts/build-loop-dispatch.bats` → `ok 1`, exit 0 (2026-10-13T22:04:56Z).

**Evidence:** `scripts/build-loop.sh:1637-1642`, `scripts/build-loop.sh:1683-1687`, `test/scripts/build-loop-dispatch.bats:51-56`, `scratchpad/u4b1-i1/cfc-probe4.out`

---

## Claim 14: "`build-loop.sh`'s cycle rules (step 9) admit any `.md` under `docs/` and repeat only part of `--check-fix` (a doc an instruction file imports, a directory at an instruction file's name and a symlink pass them; rows 764, 769, 771)"

**Location:** `skills/dev-cycle/SKILL.md:128-131`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Severity:** Low
**Scope:** Covers `--cycle-diff`'s verdict on staged docs paths (`cycle_rules`, read whole, `:1916-2001`); does not establish `--land-cycle`'s run of the same rules on a merge (same function, `:2074`, not executed) or the import-walk case (row 764; static only: cycle_rules has no walk).
**Legibility-target:** for-author

The three named non-refusals hold, but "any `.md` under `docs/`" is too broad: `truthrule` paths refuse first.
```bash
    if truthrule "$lp" && [[ "$TRUTH_WHY" != cycle ]]; then
```
(`scripts/build-loop.sh:1926`), with `truthrule` refusing docs/dev-cycle.md, docs/constraints.md, `docs/(decisions|human-author)/`, dot paths and instruction/prompt files (`scripts/lib/dev-cycle-read.sh:1914-1923`). Executed `--cycle-diff` on a chore branch in a clone: `docs/agents.md/x.md` → `ok`; symlink `docs/link.md` → `ok`; `docs/working/scratch-note.md` → `ok`; `docs/reviews/new-review.md` → `ok`; `docs/decisions/log.md` → `refuse ... a record later runs read as truth`, exit 2; `docs/constraints.md` → refuse, exit 2 (2026-10-13T22:06:09Z). Precise version: "admit any `.md` under `docs/` but the truth files `--check-fix` also refuses (decision records, human-author, the settings and constraints docs, dot paths, instruction files)". The skill's wider instruction (run `--check-fix` again before staging) is the right reading of rows 764/769/771.

**Evidence:** `scripts/build-loop.sh:1916-2001`, `scripts/lib/dev-cycle-read.sh:1914-1924`, `scratchpad/u4b1-i1/cfc-probe5.out`

---

## Claim 15: "It refuses (`refuse d6: WHY`, exit 2, nothing run) a replace ref, grafts, a default branch that is not exactly one plain main or master, and any object it cannot read whole or that does not hash to its id."

**Location:** `skills/dev-cycle/SKILL.md:173-176`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Severity:** Low
**Scope:** Covers the snippet's refusal list against its code and header; does not establish the refusals for the image copy (not exercised: no non-claude-workflows repo with `/opt/claude-workflows` checks was run beyond the replace-ref case, which refuses first).
**Legibility-target:** for-author

The list omits refusals the snippet makes, which an orchestrator reading this section would not expect from `refuse d6:`: the image copy failing the ownership checks (`own`, `test/lib/d6-snippet.bash:47`, `:92-93`), a script on main that is not a regular file (`entry ... qr/\A100(644|755)\z/`, `:78`), `refs/heads/$m names no commit` (`:59`), and any git read or temp-dir step that fails (`:52`, `:54`, `:80`, `:82`, `:83`) — the header lists all of these (`:30-36`). "Any object" is also only the objects it reads (main's first-parent commits, the trees down to scripts/lib/, the four files). Executed: replace ref → `refuse d6: a replace ref exists (F38)`; mktemp failure → `refuse d6: mktemp failed` (2026-10-13T22:06:47Z). Precise version: append "...or an image copy that is not root-owned and unwritable, or a git read or temp-dir step that fails (an environmental cause)".

**Evidence:** `test/lib/d6-snippet.bash:29-95`, `scratchpad/u4b1-i1/cfc-probe7.out`

---

## Claim 16: "**`--state`**, run through the D6 block from the main worktree (MAIN_WT ...), before any other git command."

**Location:** `skills/dev-cycle/SKILL.md:199-204`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--state` from a checkout on a non-main branch, and the order against step 0.2 (`hg -C MAIN_WT show` comes after `--state`, before `--main-log`) and step 0.3; does not establish the snippet's own git reads, which run before `--state` (hardened, `test/lib/d6-snippet.bash:45-59`), nor `--state` as more than a snapshot (its header says so, `scripts/build-loop.sh:124-127`).

Executed in a clone on branch `someother` directly and through the snippet on `notmain`: `ok`, exit 0 (2026-10-13T22:01:44Z, 22:02:48Z). `--main-log` "runs --state's gate but its caller check" (`scripts/build-loop.sh:143-144`), so `--state` first is what keeps the caller check (row 726's note).

**Evidence:** `scripts/build-loop.sh:122-144`, `scripts/build-loop.sh:711-712`, `scratchpad/u4b1-i1/cfc-probe1.out`, `scratchpad/u4b1-i1/cfc-probe2.out`

---

## Claim 17: "with no such line yet, pass 40 zeros: it prints `main MAIN -` and refuses, and that MAIN is the bootstrap. Its first line `main MAIN N` names MAIN ... read each later line's class and SHA by position (the subject is data). `gate` and `chore` lines are this design's own merges"

**Location:** `skills/dev-cycle/SKILL.md:205-211`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the bootstrap output, the `main MAIN N` first line and the `CLASS SHA SUBJECT` layout; does not establish SINCE's source (the record template has no `Main at:` line yet: Claim 25) or the bootstrap refusal's handling (Claim 18).

Executed `--main-log 0000000000000000000000000000000000000000` in a clone: `main 596966f015a5f3d061b12f0761b041f3acfdca54 -`, then `refuse main-log: 0000... is not on the default branch's first-parent history at 596966f0...`, exit 2; with `HEAD~3`: `main 596966f0... 3` and three `other SHA SUBJECT` lines (2026-10-13T22:01:44Z). Header: `gate|chore|answers|other SHA SUBJECT` (`scripts/build-loop.sh:150`).

**Evidence:** `scripts/build-loop.sh:140-185`, `scratchpad/u4b1-i1/cfc-probe1.out`

---

## Claim 18: "Any `other` line, or a `refuse main-log:` line (main rewritten), blocks step 10's dispatch this iteration and gets one `you: judgment` entry naming its SHA"

**Location:** `skills/dev-cycle/SKILL.md:212-214`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Severity:** Medium (behavioural: as written the first iteration files a judgment entry and blocks dispatch on its own bootstrap)
**Scope:** Covers the causes of `refuse main-log:` and the bootstrap's interaction with this rule; does not establish U4b2's step 10 (absent: Claim 24).
**Legibility-target:** for-author

The header gives three causes, not one: `when SINCE ... is not on that history (main was rewritten, or SINCE is on another branch) or it cannot be listed` (`scripts/build-loop.sh:183-185`). And the bootstrap two sentences earlier is itself a `refuse main-log:` line (Claim 17, executed), which this sentence does not exempt; the line names SINCE (40 zeros) and MAIN, not a rewritten commit's SHA. Precise version: "...or a `refuse main-log:` line other than the bootstrap's (main rewritten, SINCE off main, or a failed read) ...".

**Evidence:** `scripts/build-loop.sh:180-185`, `skills/dev-cycle/SKILL.md:205-214`, `scratchpad/u4b1-i1/cfc-probe1.out`

---

## Claim 19: "`hg -C MAIN_WT worktree add -b chore/dev-cycle-DATE-HHMM WT MAIN`, with WT at `.claude/wt-dev-cycle-DATE-HHMM` in MAIN_WT" (and `--main-log`'s chore class and `--land-cycle` accept that name)

**Location:** `skills/dev-cycle/SKILL.md:215-218`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the worktree add under hg's environment and both regexes accepting the HHMM form; does not establish `--land-cycle` end to end (not run; it is gated and needs a record U4b2 writes).

The hg script's `worktree add -q -b chore/dev-cycle-2026-10-13-1200 "$R/.claude/wt-dev-cycle-2026-10-13-1200" "$MAIN"` succeeded and committed in it (2026-10-13T22:01:44Z). Regexes: `^Merge\ branch\ \'(chore/dev-cycle-[0123456789]{4}-[0123456789]{2}-[0123456789]{2}(-[0123456789]{4})?)\'` (`scripts/build-loop.sh:1781`) and `^refs/heads/(chore/dev-cycle-$DIGIT{4}-$DIGIT{2}-$DIGIT{2}(-$DIGIT{4})?)$` (`:2051`).

**Evidence:** `scripts/build-loop.sh:1781`, `scripts/build-loop.sh:2051`, `scratchpad/u4b1-i1/cfc-probe1.out`

---

## Claim 20: "It takes a lock in the git common directory, so it waits while a loop's gate runs (it says so once)"

**Location:** `skills/dev-cycle/SKILL.md:247-248`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers health-check.sh's `take_lock` (read whole, `:1104-1119`) waiting on a held `health-check.lock` and printing one line; does not establish that a loop's gate is health-check.sh in every repo, or the hour bound (the skill's own rule, unenforced by the script: row 750).

```bash
        yellow "waiting for another health check in this repository (health-check.lock)"
        rc=0; flock -o "$lk" bash "$REPO_ROOT/scripts/health-check.sh" "$@" || rc=$?
```
(`scripts/health-check.sh:1115-1116`). Executed with the lock held by `flock ... sleep 30`: `timeout 8 bash scripts/health-check.sh` printed exactly that one line and was killed at 8 s (exit 124). 2026-10-13T22:02:48Z.

**Evidence:** `scripts/health-check.sh:1096-1119`, `scratchpad/u4b1-i1/cfc-probe2.out`

---

## Claim 21: "`hg -C MAIN_WT worktree prune` (a locked worktree, a live loop's, is never pruned)"

**Location:** `skills/dev-cycle/SKILL.md:258-259`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git's prune skipping a locked worktree whose directory is gone, and `--start`/`--prompt` locking a loop's worktree (header); does not establish a loop worktree left unlocked after a failed relock (`--prompt`'s header names that case, `scripts/build-loop.sh:470-472`).

Executed: two worktrees removed from disk, one locked; after `git worktree prune`, `git worktree list` still showed the locked one (`.../wl ... locked`) and not the other (2026-10-13T22:02:48Z). `--start` adds the worktree "locked with the reason ..." (`scripts/build-loop.sh:450-452`).

**Evidence:** `scripts/build-loop.sh:446-472`, `scratchpad/u4b1-i1/cfc-probe2.out`

---

## Claim 22: "a build loop made (a `--merge` commit, with a `Build-loop-gate:` trailer) ... the loop's research doc (`docs/working/research-STEM.md`, which the loop force-adds)"

**Location:** `skills/dev-cycle/SKILL.md:314-316`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both `--merge` paths writing the trailer and the loop prompt's force-add instruction; does not establish that a loop obeys it (a prompt instruction, not enforced).

Header: `the trailer "Build-loop-gate: STEM"` for self-merge, and the approved merge adds a second trailer (`scripts/build-loop.sh:404-418`); prompt: `Force-add your research doc (git add -f docs/working/research-$s.md)` (`:1688`). Executed: `bats -f "parents, tree, message, trailer|message, trailers, reflog" test/scripts/build-loop-merge.bats` → `ok 1`, `ok 2` (2026-10-13T22:06:09Z).

**Evidence:** `scripts/build-loop.sh:400-418`, `scripts/build-loop.sh:1688`, `scratchpad/u4b1-i1/cfc-probe6.out`

---

## Claim 23: "Every deep audit covers one more dimension ... and checks that `Self-merge never:` covers the paths that take effect on merge in this repo (F57)"; "a drift finding from step 4" (D2)

**Location:** `skills/dev-cycle/SKILL.md:331-339`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the plan's step 4b text and F57 row; does not establish anything executable.

Plan: `**Step 4b, deep audit**: a drift finding is a trigger; the audit gains the "constraints and project guidance still match intent" dimension (it also checks that \`Self-merge never:\` covers paths that take effect on merge, F57).` (`docs/working/plan-build-loop-handoff.md:256`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:175`, `docs/working/plan-build-loop-handoff.md:256`

---

## Claim 24: "`build-loop.sh`'s cycle rules (step 9)" and "blocks step 10's dispatch"

**Location:** `skills/dev-cycle/SKILL.md:129`, `skills/dev-cycle/SKILL.md:213`
**Type:** Reference / Staleness
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Severity:** Medium (the file is the orchestrator's instructions; two rules point at steps that are not in it)
**Scope:** Covers the step numbers the file defines at 458dc170; does not establish U4b2's planned text (plan `:344` lists steps 6-10 there).
**Legibility-target:** for-author

The file's steps are `### 0.` to `### 7.` (paraphrased — no quote available because the claim is about the absence of `### 8`-`### 10` headings: `grep -n '^### ' skills/dev-cycle/SKILL.md` lists 0, 1, 2, 3, 4, 4b, 5, 6, 7). The Flow diagram ends `6 roadmap and build briefs → 7 close (lands the branch)` (`:185`). So "step 9" and "step 10's dispatch" name nothing; the cycle rules run at `--cycle-diff`/`--land-cycle`, which no step here calls. Either say "U4b2's land step"/"the dispatch step (pending)" or land with U4b2.

**Evidence:** `skills/dev-cycle/SKILL.md:129`, `skills/dev-cycle/SKILL.md:183-186`, `skills/dev-cycle/SKILL.md:213`, `docs/working/plan-build-loop-handoff.md:343-344`

---

## Claim 25: Step 7 "land `chore/dev-cycle-<date>` on the default branch through `pr-prep`" and its record template, against the new Rules and step 0

**Location:** `skills/dev-cycle/SKILL.md:461-489`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Severity:** Medium
**Scope:** Covers consistency of unchanged step 7 with the changed Rules and step 0; does not establish whether U4b2 is meant to land before anyone runs this text (the intro's by-hand fallback, `:19-23`, keeps pr-prep landing for now).
**Legibility-target:** for-author

The Rules now name the branch `chore/dev-cycle-DATE-HHMM` (`:38`), step 0 builds SINCE from "the newest `Main at:` line of the newest record" (`:205-206`) and says "a stop below ends the iteration with no record, so the next one starts from the same `Main at:`" (`:196-197`), and `--main-log`'s chore class needs a record "holding the line \"Branch: B\"" (`scripts/build-loop.sh:166-169`). Step 7 is unchanged: it lands `chore/dev-cycle-<date>` "through `pr-prep`" (`:488`), and its template (`:465-482`) has neither a `Main at:` nor a `Branch:` line. As written, SINCE is always the bootstrap and a pr-prep land reads `other` on the next `--main-log`. The plan assigns the template and the land to U4b2 (`docs/working/plan-build-loop-handoff.md:344`, "record template with `Branch:` and `Main at:` per iteration"); until then the file contradicts itself.

**Evidence:** `skills/dev-cycle/SKILL.md:38`, `skills/dev-cycle/SKILL.md:196-213`, `skills/dev-cycle/SKILL.md:461-489`, `scripts/build-loop.sh:160-170`

---

## Claim 26: "Neither the snippet (it runs before anything is checked) nor SKILL.md's hg, the orchestrator's own git (rows 704, 736), can source the lib: each repeats both lists, on one line."

**Location:** `test/scripts/build-loop-orchestrator.bats:366`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both lines carry both lists on one line and the rows' rationale; does not establish more than the test's token checks (Claim 8's scope).

`G=(env GIT_NO_REPLACE_OBJECTS=1 ... -c log.showSignature=false)` (`test/lib/d6-snippet.bash:45`) and `hg() { env GIT_NO_REPLACE_OBJECTS=1 ... "$@"; }` (`skills/dev-cycle/SKILL.md:59`) are each one line; row 736: "the lib cannot be sourced before it is checked ... U4 ... adds a third copy of HARDEN pinned by the equality test" (`docs/reviews/override-log.md:736`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:366-371`, `docs/reviews/override-log.md:704`, `docs/reviews/override-log.md:736`

---

## Claim 27: "Wait until no subagent this task started is still running; other sessions' agents and build loops share the uid and keep running (dev-cycle D14). ... stop each by its PID ... never by a name or pattern (`pkill -f` can stop another session's run)."

**Location:** `workflows/pr-prep.md:333`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with D14 and that `pkill -f` matches by full command line across the uid's processes; does not establish anything about install.sh's guard (unchanged text).

D14: "The quiesce in step 1, and pr-prep's quiesce before its gate, cover only subagents this task started, and never stop or reap a process this task did not start (by PID)." (`docs/working/plan-build-loop-handoff.md:106`). `pkill -f PATTERN` signals every process of the caller's permitted set whose full command line matches (paraphrased — no quote available because this is procps' documented behaviour, not repo code).

**Evidence:** `workflows/pr-prep.md:333`, `docs/working/plan-build-loop-handoff.md:106`

---

## Claim 28: Commit 458dc170's row citations ("`refuse d6:`, an undocumented exit or a timed-out call (rows 735, 742, 744)", "hg line (rows 704, 736)", "rows 720, 726, 727", "rows 764, 769, 771", "row 750")

**Location:** commit 458dc170 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that each cited override-log line is the row on that topic with a U4/U4b revisit trigger; does not establish that every trigger is fully discharged (see Claims 9b, 11b, 18).

Row 735: "match a first line starting `refuse d6: ` before parsing"; 742: "an environmental failure ... also prints `refuse d6:`"; 744: "say how a timed-out snippet is read: as a stop"; 704/736: the hardened wrapper; 720/726/727: `--main-log` other/answers handling and the bootstrap; 750: the unbounded lock wait; 764/769/771: cycle_rules' three gaps (`docs/reviews/override-log.md`, those line numbers).

**Evidence:** `docs/reviews/override-log.md:702-771`

---

## Claim 29: Commit 458dc170 "Test: the git_harden test also pins SKILL.md's hg line to the lib's HARDEN pairs and the snippet's environment (both mutants fail it)."

**Location:** commit 458dc170 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a pair mutant and an env mutant (plus three more); does not establish the residue in Claim 8's scope.

See Claim 8: mutants A (pair) and B (env var) each made the test fail, exit 1 (2026-10-13T22:02:48Z).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:355-372`, `scratchpad/u4b1-i1/cfc-probe2.out`

---

## Claims Requiring Attention

### Incorrect
- **Claim 5b** (`skills/dev-cycle/SKILL.md:48-49`): an undocumented exit or a timed-out call does not mean "nothing ran"; the header says "nothing decided", and writing modes may have written part of their work. Say so, and say to read main/worktrees before retrying.
- **Claim 9b** (`skills/dev-cycle/SKILL.md:62-64`): hg does not stop repo-config filters or commit signing (executed: smudge/clean and `gpg.program` ran under hg); only `--state`'s snapshot refuses them. Narrow the sentence, or add `-c commit.gpgSign=false` and similar (a security-reviewer call).
- **Claim 11b** (`skills/dev-cycle/SKILL.md:66-67`): `--state` does not refuse hg's exported environment variables (executed: `ok`); it refuses only `-c`/`GIT_CONFIG_COUNT` pairs on the HARDEN and state keys.
- **Claim 24** (`skills/dev-cycle/SKILL.md:129`, `:213`): "step 9" and "step 10's dispatch" name steps the file does not have (0-7 only).

### Stale
- **Claim 25** (`skills/dev-cycle/SKILL.md:461-489`): step 7 still lands `chore/dev-cycle-<date>` through pr-prep with a template lacking `Main at:`/`Branch:`, contradicting the new Rules and step 0 (U4b2's work).

### Mostly Accurate
- **Claim 7** (`skills/dev-cycle/SKILL.md:53-56`): "never as bare git" has an unstated exception, step 0.3's `git config --global --get` read.
- **Claim 14** (`skills/dev-cycle/SKILL.md:128-131`): cycle rules do not admit "any .md under docs/": truth files (decisions, human-author, settings, constraints, dot paths, instruction files) refuse.
- **Claim 15** (`skills/dev-cycle/SKILL.md:173-176`): the refusal list omits the image-copy ownership checks, a non-regular script, a ref naming no commit, and git/temp-dir failures.
- **Claim 18** (`skills/dev-cycle/SKILL.md:212-214`): `refuse main-log:` has three causes, and the bootstrap's own refusal is not exempted from "blocks dispatch and gets a judgment entry".

### Unverifiable
- (none)

## Escalations

- **security-reviewer:** Claim 9b (repo-config filter, merge driver and signing programs run under hg between `--state`'s snapshot and the orchestrator's `worktree add`/commit/merge, since a live loop shares `.git/config`); Claim 7 (step 0.3's bare `git config --global --get` reads a value a loop can write and pastes it as `-c user.name=NAME` into a script, with no quoting rule).
- **api-consistency-reviewer:** Claims 24-25 (step numbering and the step 7 land/record contract against the new Rules and step 0).

## Goal-Alignment Note

The goal is a clean landing of U4b1, whose product is instructions an orchestrator follows. The executable contracts the frame leans on hold under execution: the hg line is pinned (five mutants fail the test), `--state`/`--main-log`/the snippet work from a non-main checkout, the bootstrap prints `main MAIN -` then refuses, the health-check lock waits and says so once, locked worktrees survive prune, `--start` refuses without `constraints ok`, and the cycle rules admit the three row-764/769/771 paths. The four Incorrect findings are wording that would make an orchestrator trust or do the wrong thing: hg is described as stopping filters and signing (it does not), `--state` as refusing exported env settings (it does not), undocumented exits and timeouts as "nothing ran", and references to steps 9 and 10 that do not exist yet. The Stale step 7 and the step 9/10 references come from the U4b1/U4b2 split; they matter less while the intro's by-hand fallback applies, but the file is internally contradictory until U4b2 lands, which the author may prefer to flag in the text rather than leave.
