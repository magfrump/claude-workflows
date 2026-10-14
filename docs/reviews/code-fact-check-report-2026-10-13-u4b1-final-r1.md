Commit: 4c911717

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u4b1 (feat/build-loop-u4b1)
**Scope:** branch diff `git diff main...HEAD` at 4c911717 and commits 458dc170, 0cd86cc0, 4c911717 (final confirming pass, replicate r1)
**Checked:** 2026-10-13
**Total claims checked:** 29
**Summary:** 22 verified, 5 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`); no claim below matches a logged pattern, and neither Incorrect is a fabricated symbol, so the log is not extended.

Execution logs (all under `docs/reviews/execution-logs/`, each starts with its UTC timestamp; probe scripts in the session scratchpad, each in its own `mktemp -d /tmp/u4b1-fc1-XXXX` dir, removed at exit):
`u4b1-final-r1-fc-gpg.log`, `-state.log`, `-mutants.log`, `-suites.log`, `-lock.log`, `-checkfix.log`, `-hook.log`, `-worktree.log`, `-graft.log`, `-shellcheck.log` (prefix `u4b1-final-r1-fc`).

Legibility-target per claim: **orchestrator** (a session following SKILL.md), **maintainer** (a reader of code comments, header or tests), **reviewer** (commit messages, plan notes).

---

## Claim 1: "U4b1, the orchestrator's frame (173 lines as written)"

**Location:** `docs/working/plan-build-loop-handoff.md:342`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** reviewer
**Scope:** Covers the changed-line count outside `docs/` in commit 458dc170 (the unit as first written); does not establish the count after the two fix commits (177 in SKILL.md alone on the full branch) or the 400-line cap's own rule.

`git diff --numstat 458dc170~1 458dc170` (cwd the worktree, exit 0, 2026-10-13T22:35Z) printed `130 29 skills/dev-cycle/SKILL.md`, `7 5 test/scripts/build-loop-orchestrator.bats`, `1 1 workflows/pr-prep.md` (plus 3 docs lines): 130+29+7+5+1+1 = 173.

**Evidence:** `docs/working/plan-build-loop-handoff.md:342`; command output inline (paraphrased — no captured file because the full numstat is quoted above).

---

## Claim 2: "the lib's HARDEN list: ... log.showSignature, commit.gpgSign; a git -c pair would win over it), whatever the value"

**Location:** `scripts/build-loop.sh:135-140`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers `--state`'s caller gate refusing a caller `commit.gpgSign` pair by `git -c` (GIT_CONFIG_PARAMETERS) and by GIT_CONFIG_COUNT, value true or false; does not establish the other gated modes (only `--state` runs caller_gate: `scripts/build-loop.sh:711`).

```bash
# scripts/build-loop.sh:668-669 (enclosing caller_gate() :660-674 — read)
    for kv in "${HARDEN[@]}"; do kv="${kv%%=*}"; [[ "$k" != "${kv,,}" ]] || k+=" "; done  # a trailing blank marks a HARDEN key
    if [[ "$k" == *" " || "$k" =~ $STATE_KEYS_RE ]]; then
```

Run in a clone: `env GIT_CONFIG_PARAMETERS="'commit.gpgsign'='true'" bash build-loop.sh --state` and `env GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=commit.gpgSign GIT_CONFIG_VALUE_0=false bash build-loop.sh --state` each printed `refuse state commit.gpgsign: set by the caller's git -c or GIT_CONFIG_COUNT pairs, ...` and exit 2; the plain run printed `ok`, exit 0.

**Evidence:** `scripts/build-loop.sh:135-140`, `scripts/build-loop.sh:660-674`, `scripts/lib/dev-cycle-read.sh:354`; `docs/reviews/execution-logs/u4b1-final-r1-fc-state.log` (cwd a clone in /tmp/u4b1-fc1-EE8R, script exit 0, 2026-10-13T22:29:38Z)

---

## Claim 3: "and no commit signing (commit.gpgSign runs gpg.program on a commit or merge: the orchestrator's own commits, SKILL.md's hg ...)"

**Location:** `scripts/lib/dev-cycle-read.sh:341-343`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers a planted `commit.gpgSign=true`, `user.signingKey` and `gpg.program` in `.git/config`: plain git runs the program on commit, `hg` runs it on neither a commit nor a non-fast-forward merge; does not establish `tag.gpgSign` paths (the orchestrator makes no tags) or `git merge -S` given explicitly.

Control: `git commit` printed `error: gpg failed to sign the data`, exit 128, and the fake gpg wrote its marker. With SKILL.md's `hg` line (byte-compared to `skills/dev-cycle/SKILL.md:65`, `cmp` equal): `hg commit` exit 0, `hg merge -q --no-edit side` exit 0, `%G?` = `N` on all three commits, marker empty: "hg: gpg did not run".

**Evidence:** `scripts/lib/dev-cycle-read.sh:338-354`, `skills/dev-cycle/SKILL.md:65`; `docs/reviews/execution-logs/u4b1-final-r1-fc-gpg.log` (script exit 0, 2026-10-13T22:29:14Z)

---

## Claim 4: "No other HARDEN user commits with a signature (build-loop.sh's commit-tree passes --no-gpg-sign; dev-cycle.sh and the snippet never commit)"

**Location:** commit 4c911717 message
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** reviewer
**Scope:** Covers every commit-writing git call in build-loop.sh, dev-cycle.sh and d6-snippet.bash (one: commit-tree), and the six suites that exercise HARDEN's users passing with the new pair; does not establish behaviour of `questions.sh` (not a HARDEN user) or of git versions other than 2.39.5.

```bash
# scripts/build-loop.sh:1558 (excerpt ends :1558; enclosing land() continues to its move — read)
    && x="$(gate_git commit-tree --no-gpg-sign -p "$MAIN_SHA" -p "${VERDICT[tip]}" "${VERDICT[tree]}" < "$GATE_TMP/msg")" \
```

A grep for `(g|git|gate_git) (commit|merge|commit-tree|tag|am|cherry-pick|revert|rebase)` over the three files, comments excluded, returns only that line (paraphrased — no quote available because the claim covers absence of code). `--land-cycle` writes through the same `land()` (`chore_msg` branch at `:1557`); its worktree path is `merge --ff-only`, which writes no commit. The six suites (288 tests) pass: Claim 5.

**Evidence:** `scripts/build-loop.sh:1467-1470`, `scripts/build-loop.sh:1540-1565`, `test/lib/d6-snippet.bash:41-94`; `docs/reviews/execution-logs/u4b1-final-r1-fc-suites.log`

---

## Claim 5: "Suites 288 green, run serially; shellcheck clean."

**Location:** commit 4c911717 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** reviewer
**Scope:** Covers the six build-loop/dev-cycle bats files (146+4+12+27+20+79 = 288 tests) and shellcheck at the health check's severity (`-S warning`) on the four changed shell files and the bats file; does not establish the full health check (other suites, install-host) or info-level shellcheck notes (174 lines of SC2015/SC2016/SC2004/SC2153 info, all excluded by the gate's `-S warning`, `scripts/health-check.sh:485`).

`TMPDIR=<own temp> bats test/scripts/build-loop-{check,dispatch,merge,orchestrator,read}.bats test/scripts/dev-cycle.bats` in the worktree: `ok 288`, 0 `not ok`, exit 0 (22:30:12Z to 22:32:54Z). `shellcheck -S warning` on build-loop.sh, the lib, dev-cycle.sh and d6-snippet.bash: exit 0; `shellcheck -x -S warning` on the orchestrator bats: exit 0.

**Evidence:** `scripts/health-check.sh:480-490`; `docs/reviews/execution-logs/u4b1-final-r1-fc-suites.log`, `docs/reviews/execution-logs/u4b1-final-r1-fc-shellcheck.log`

---

## Claim 6: "the git_harden test also pins SKILL.md's hg line to the lib's HARDEN pairs and the snippet's environment (both mutants fail it)"

**Location:** `test/scripts/build-loop-orchestrator.bats:355-372`; commit 458dc170 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the test failing on six mutants (SKILL hg without commit.gpgSign, hg without GIT_NO_REPLACE_OBJECTS, snippet G without commit.gpgSign, lib HARDEN without it, a second hg line, two pairs swapped) and passing at HEAD; does not establish that the test notices an extra argument added after `"$@"` or a changed `bash -s <<'G'` wrapper text (it greps only the one-line `hg() { env ... "$@"; }` shape).

```bash
# test/scripts/build-loop-orchestrator.bats:367-371 (excerpt ends :371; enclosing @test continues to :372 — read)
    [ "$(grep -c '^  hg() { env .* "\$@"; }$' "$REPO_ROOT/skills/dev-cycle/SKILL.md")" -eq 1 ] || { grep -n 'hg()' "$REPO_ROOT/skills/dev-cycle/SKILL.md"; return 1; }
    for g in "$(grep '^  G=(env ' "$REPO_ROOT/test/lib/d6-snippet.bash")" "$(grep '^  hg() { env ' "$REPO_ROOT/skills/dev-cycle/SKILL.md")"; do
        [ "$(grep -o -- '-c [^ )]*' <<<"$g" | cut -c4- | tr '\n' ' ')" = "$H " ] || { echo "$g"; return 1; }
        [ "$(grep -o 'GIT_[A-Z_]*=[^ ]*' <<<"$g" | LC_ALL=C sort | tr '\n' ' ')" = "$E " ] || { echo "$g"; return 1; }
    done
```

Each mutant run in a clone at 4c911717 (`bats -f 'git_harden exports HARDEN'`): baseline `ok 1`, exit 0; M1-M6 each `not ok 1`, exit 1.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:355-372`; `docs/reviews/execution-logs/u4b1-final-r1-fc-mutants.log` (script exit 0, 2026-10-13T22:29:52Z)

---

## Claim 7: "commit.gpgSign=false joins the lib's HARDEN, the D6 snippet's G and SKILL.md's hg (the pin test now counts 10 pairs)"

**Location:** commit 4c911717 message
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** reviewer
**Scope:** Covers the three copies carrying the pair and the test's count; does not establish anything beyond the message's wording.

The pair is in all three (`scripts/lib/dev-cycle-read.sh:354`, `test/lib/d6-snippet.bash:45`, `skills/dev-cycle/SKILL.md:65`). HARDEN holds 9 pairs; the test's 10 is GIT_CONFIG_COUNT, the caller's one pair plus HARDEN's nine:

```bash
# test/scripts/build-loop-orchestrator.bats:357,364
    run env -i PATH="$PATH" GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=user.name GIT_CONFIG_VALUE_0=c bash -c ...
    want+=$'\n'"$(printf '%s\n' $E "GIT_CONFIG_COUNT=10" "$keys" "$vals" | LC_ALL=C sort)"
```

Precise version: "HARDEN now holds 9 pairs (the test's GIT_CONFIG_COUNT is 10 with the caller's one)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:354`, `test/scripts/build-loop-orchestrator.bats:355-372`

---

## Claim 8a: by-hand fallback: "WT made as step 0.3 says, from the default branch's commit (`hg -C MAIN_WT rev-parse --verify refs/heads/main`, or master); ... every `dev-cycle.sh` call ... as `~/.claude/scripts/dev-cycle.sh`"

**Location:** `skills/dev-cycle/SKILL.md:19-24`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers the rev-parse and the step 0.3 worktree add working with `hg` from a main checkout, and the fallback naming every dev-cycle.sh call; does not establish the step texts that still say "through the D6 block" (`SKILL.md:127-128`, `:236`), which the fallback overrides only by precedence of reading.

Executed: `MAIN="$(hg -C "$MAIN_WT" rev-parse --verify refs/heads/main)"` printed `596966f0...`; `hg -C "$MAIN_WT" worktree add -q -b chore/dev-cycle-2026-10-13-2231 "$WT" "$MAIN"` exit 0, branch `chore/dev-cycle-2026-10-13-2231`.

**Evidence:** `skills/dev-cycle/SKILL.md:19-26`, `:232-235`; `docs/reviews/execution-logs/u4b1-final-r1-fc-worktree.log` (exit 0, 2026-10-13T22:34:06Z)

---

## Claim 8b: "With no `--state` run, nothing refuses the repository config `hg` cannot switch off (a filter or merge driver): the by-hand cycle carries that gap."

**Location:** `skills/dev-cycle/SKILL.md:25-26`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers the named config gap being real (`--state` is what refuses filters and merge drivers) and the gap being wider; does not establish which of the extra classes matter for the by-hand steps beyond ancestry checks.

`--state` refuses `filter.x.clean` and `merge.y.driver` (state log, exit 2), and `hg` sets no filter or merge override (`SKILL.md:65`). But the by-hand cycle also runs neither `--state` nor the D6 snippet, and both are what refuse `.git` state that is not config: `info/grafts` (`test/lib/d6-snippet.bash:54-55`; state gate `scripts/build-loop.sh:276-279`), shallow, alternates, and config `--state` refuses that `hg` does not override (include, diff drivers: `STATE_KEYS_RE`, `scripts/build-loop.sh:612`). Executed: with `info/grafts` planted, `hg rev-list --count HEAD` fell from 3 to 1 and `hg merge-base --is-ancestor C1 C3` went from yes to no — the ancestry check the Rules give `hg`. Precise version: "nothing refuses the `.git` state `hg` does not switch off (a filter, merge driver or include in config; grafts, shallow or alternates)".

**Evidence:** `skills/dev-cycle/SKILL.md:25-26`, `scripts/build-loop.sh:274-281`, `scripts/build-loop.sh:612`, `test/lib/d6-snippet.bash:52-55`; `docs/reviews/execution-logs/u4b1-final-r1-fc-graft.log` (exit 0, 2026-10-13T22:34:36Z), `docs/reviews/execution-logs/u4b1-final-r1-fc-state.log`

---

## Claim 9: "In claude-workflows it runs main's own committed scripts, elsewhere the root-owned image copy ... `refuse d6: WHY` (exit 2) means nothing ran."

**Location:** `skills/dev-cycle/SKILL.md:48-51`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers the snippet's two branches and its `no()` exiting 2 before any script runs; does not establish the Q-140 gap the snippet header names (a moved main onto a copy of D6_ROOT in another project), which SKILL.md leaves to its pending section.

```bash
# test/lib/d6-snippet.bash:46
  no() { echo "refuse d6: $*"; exit 2; }
```

The header: "In claude-workflows (main's first-parent root commit is D6_ROOT) it runs main's own scripts ... In any other repository ... it runs the image copy under D6_OPT ... once those files and every directory above them are root-owned" (`test/lib/d6-snippet.bash:11-22`). Every `no` call precedes the run at the end of `d6()` (paraphrased — no quote available because the checks span `:52-94`).

**Evidence:** `test/lib/d6-snippet.bash:1-94`

---

## Claim 10: "A `build-loop.sh` answer is exit 0, or exit 2 with the mode's own refuse lines; any other exit (1 included), or a call the Bash tool timed out, means nothing was decided"

**Location:** `skills/dev-cycle/SKILL.md:51-54`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers `--state` and `--main-log` (steps 0-1) against the header's Exit paragraph; does not establish `--check`/`--merge`/`--start` (U4b2's steps), whose exit 2 also carries `skip` and `deny` lines rather than only refuse lines.

The header's Exit paragraph: "2 any other --check, --merge, --start or --prompt verdict line, --main-log's other or refuse line, a --cycle-diff refuse line, or the state gate (--state's included) not ok" (`scripts/build-loop.sh:513-516`). Executed: `--main-log` from three commits back printed `main 596966f0... 3` and three `other ...` lines and **no refuse line**, exit 2. Under the Rule's wording that output is neither "exit 0" nor "exit 2 with the mode's own refuse lines", while step 0.2 (`SKILL.md:227-231`) treats `other` as an answer that blocks dispatch only. Precise version: "exit 2 with the mode's own lines (--main-log's `other`, a refuse line)".

**Evidence:** `scripts/build-loop.sh:510-521`, `skills/dev-cycle/SKILL.md:51-57`, `:220-231`; `docs/reviews/execution-logs/u4b1-final-r1-fc-state.log`

---

## Claim 11: "`hg` reads no global or system config and runs no hook, fsmonitor command, signing program or replaced object; a test holds its pairs to the lib's `HARDEN` list."

**Location:** `skills/dev-cycle/SKILL.md:68-70`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers a `.git/hooks/pre-commit` file (control: plain git ran it; hg did not), commit signing (Claim 3) and the test pin (Claim 6); does not establish config-based hooks (`hook.*`, absent from git 2.39.5 here; `--state` refuses `hook.` keys) or grafts, which `hg` honours (Claim 8b) — the sentence does not claim grafts.

Executed: plain `git commit` printed `filehook`; `hg commit` gave "hg ran no hook". `hg` carries `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_NO_REPLACE_OBJECTS=1 ... -c core.hooksPath=/dev/null -c core.fsmonitor=false ... -c commit.gpgSign=false` (`SKILL.md:65`).

**Evidence:** `skills/dev-cycle/SKILL.md:65-70`; `docs/reviews/execution-logs/u4b1-final-r1-fc-hook.log` (exit 0, 2026-10-13T22:31:53Z), `docs/reviews/execution-logs/u4b1-final-r1-fc-gpg.log`

---

## Claim 12: "It does not switch off what the repository's own config can still name (a filter, a merge driver): `--state` refuses those, but only when it runs"

**Location:** `skills/dev-cycle/SKILL.md:70-74`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers `--state` refusing a planted filter and merge driver (exit 2) and passing a planted `commit.gpgSign`/`user.signingKey`/`author.name` (exit 0, which HARDEN or the command-line identity now cover); does not establish the race between the re-run and the commit (named as Q-103's residual).

State log: `refuse state filter.x.clean: set in config, ...` exit 2; `refuse state merge.y.driver: ...` exit 2; repo `commit.gpgSign`+`user.signingKey`: `ok` exit 0; repo `author.name`: `ok` exit 0.

**Evidence:** `scripts/build-loop.sh:605-612`; `docs/reviews/execution-logs/u4b1-final-r1-fc-state.log`

---

## Claim 13: "Commits set their identity on the command, as `GIT_AUTHOR_NAME`, ... (these outrank a planted `author.*` or `committer.*` key)"

**Location:** `skills/dev-cycle/SKILL.md:75-79`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers env identity beating planted `author.name/email` and `committer.name/email` in `.git/config` (and the control: without the env vars, the planted keys win); does not establish the trust of the fallback `git config --global --get user.name` read (a loop can write `~/.gitconfig`, which the Rule itself notes).

Executed: with `author.name=PLANT` etc. planted, `GIT_AUTHOR_NAME=Real ... hg commit` gave `author=Real <r@r> committer=Real <r@r>`; with those variables unset, `author=PLANT committer=PLANT`.

**Evidence:** `skills/dev-cycle/SKILL.md:75-80`; `docs/reviews/execution-logs/u4b1-final-r1-fc-gpg.log`

---

## Claim 14: "Never export these settings ... (`--state` refuses a caller's config pair for a `HARDEN` key, row 702)."

**Location:** `skills/dev-cycle/SKILL.md:79-80`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers an exported `GIT_CONFIG_COUNT` / `GIT_CONFIG_PARAMETERS` pair for a HARDEN key making `--state` exit 2; does not establish exported environment variables such as `GIT_NO_REPLACE_OBJECTS`, which caller_gate explicitly sets aside.

See Claim 2: both forms refused with `refuse state commit.gpgsign: ...`, exit 2.

**Evidence:** `scripts/build-loop.sh:654-674`; `docs/reviews/execution-logs/u4b1-final-r1-fc-state.log`

---

## Claim 15: settings lines "read only through `build-loop.sh --settings`, from the default branch's commit ... A malformed never line turns self-merge off." Slots "1-9; else 3"

**Location:** `skills/dev-cycle/SKILL.md:111-116`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers the header's contract for policy, slots, never, readers; does not establish the parser against the header (U3's tests own that).

Header: "five lines from the default branch's commit, never the working tree"; "Loops at once: "Build-loop slots: N", N from 1 to 9; else 3."; "Malformed (or a file not read) turns self-merge off." (`scripts/build-loop.sh:18-39`).

**Evidence:** `scripts/build-loop.sh:18-61`

---

## Claim 16: "Every loop prompt quotes it [constraints.md], and every design choice a loop makes runs divergent design seeded with it (D2) ... The orchestrator dispatches only while `--settings` prints `constraints ok`."

**Location:** `skills/dev-cycle/SKILL.md:119-122`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers loop_prompt's quote and DD line and the header's dispatch rule; does not establish that `--start` reads the same constraints line at its own time (its header says it does: `:465-467`).

```bash
# scripts/build-loop.sh:1681,1687 (enclosing loop_prompt() :1675-1696 — read)
The project's constraints (docs/constraints.md at $MAIN_SHA), quoted:
Run every design choice through divergent design seeded with these constraints and your brief's own. One option dominates (Path A): decide and continue. ...
```

Header: "Only "ok" lets the orchestrator dispatch." (`scripts/build-loop.sh:49`).

**Evidence:** `scripts/build-loop.sh:40-49`, `scripts/build-loop.sh:1675-1696`

---

## Claim 17a: "the cycle rules `build-loop.sh --cycle-diff` applies ... repeat only part of `--check-fix` (a `.md` under `docs/working/` or `docs/reviews/`, a doc an instruction file imports, ... and a symlink pass them)"

**Location:** `skills/dev-cycle/SKILL.md:140-145`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers four of the five named classes passing `--cycle-diff` (ok, exit 0) while `--check-fix` skips each; does not establish other `--check-fix` refusals outside the list.

Clone with `@docs/imported-x.md` added to AGENTS.md on the base: staged edits to `docs/imported-x.md`, `docs/working/fc1-notes.md`, `docs/reviews/fc1-rev.md` and a new symlink `docs/fc1-link.md` → `--cycle-diff` `ok`, exit 0. `--check-fix` printed `skip docs/imported-x.md: an instruction file names it after an @ ...`, `skip docs/working/fc1-notes.md: in-cycle fixes edit only ...`, the same for the review, and `skip docs/fc1-link.md: reached through a symlink, or not a regular file`.

**Evidence:** `scripts/build-loop.sh:1916-1940`; `docs/reviews/execution-logs/u4b1-final-r1-fc-checkfix.log` (exit 0, 2026-10-13T22:33:02Z)

---

## Claim 17b: "... a new file below a directory named like an instruction file ... pass them"

**Location:** `skills/dev-cycle/SKILL.md:144-145`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers what `--check-fix` does with paths below `docs/agents.md/` and `docs/gemini.md/`; does not establish the floor's "below" class (S rules), which does refuse them.

Such a file passes the cycle rules (`--cycle-diff` ok with `docs/agents.md/new.md` staged) and `--check-fix` refuses it before staging, but only as untracked (`skip docs/agents.md/new.md: no tracked file (or ignored file under docs/working/) matches`), the same as any new file. The directory name plays no part: a **tracked** `docs/agents.md/old.md` got `ok` from `--check-fix` and passes the cycle rules; and once staged, `--check-fix` printed `ok docs/agents.md/new.md` and `ok docs/gemini.md/unstaged.md`. Precise version: "a new file (any; `--check-fix` takes only tracked files, so run it before staging)". The order the paragraph already prescribes ("right before staging it") is what makes the refusal hold.

**Evidence:** `skills/dev-cycle/SKILL.md:134-145`; `docs/reviews/execution-logs/u4b1-final-r1-fc-checkfix.log`

---

## Claim 18: The D6 block section: "It refuses (`refuse d6: WHY`, exit 2, nothing run) a replace ref, grafts, a default branch that is not exactly one plain main or master naming a commit, an object it cannot read whole or that does not hash to its id, and more"

**Location:** `skills/dev-cycle/SKILL.md:184-191`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers the listed refusals against the snippet's code and header; does not establish the byte-equality test (pending, U4c).

```bash
# test/lib/d6-snippet.bash:53,55,57-59 (enclosing d6() :41-end — read)
  [[ -z "$x" ]] || no "a replace ref exists (F38)"
  [[ ! -e "$x" && ! -L "$x" ]] || no "info/grafts exists (F38)"
  m="${m% }"; [[ "$m" == main || "$m" == master ]] || no "the default branch is not exactly one of main and master"
  ! g symbolic-ref -q "refs/heads/$m" >/dev/null || no "refs/heads/$m is a symbolic ref"
  sha="$(g rev-parse --verify -q "refs/heads/$m")" && [[ "$(g cat-file -t "$sha")" == commit ]] || no "refs/heads/$m names no commit"
```

**Evidence:** `test/lib/d6-snippet.bash:28-94`

---

## Claim 19: Step 0.1: "`--state` ... refuse lines (planted `.git` state ...) are a stop, quoted in one `you: judgment` entry ...; so is an exit 1, with its stderr."

**Location:** `skills/dev-cycle/SKILL.md:214-219` (against `:51-57`)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers the routing of a `--state` exit 1 between the D6 Rule and step 0.1; does not establish the `refuse state` route (only step 0.1 names one for it, so no conflict there).

The D6 Rule says an exit 1 is a stop whose "line and stderr go in one `agent` entry and the final message (a full disk reads like planted state, so it is not called hostile)" (`SKILL.md:52-57`); step 0.1 routes the same `--state` exit 1 to "one `you: judgment` entry" (`SKILL.md:218-219`). `--state`'s exit 1 cases are environmental or caller-side: "Exit 1 (stderr only) when a caller's git setting stops git or the script first (a GIT_CONFIG_COUNT not plain decimal, a GIT_DIR naming no repository...)", plus no perl, no lib, a failed mktemp (`scripts/build-loop.sh:122-125`, `:517-520`) — the row-742 class the Rule routes to `agent`. An orchestrator meets two different instructions for one event. This is item 10 of the brief (a contradiction this unit leaves), not listed in the U4b2 override row.

**Evidence:** `skills/dev-cycle/SKILL.md:51-57`, `:214-219`; `scripts/build-loop.sh:120-125`, `:510-521`

---

## Claim 20: Step 0.2: "with no such line yet, pass 40 zeros: it prints `main MAIN -` and refuses, and that MAIN is the bootstrap. Its first line `main MAIN N` names MAIN ...; read each later line's class and SHA by position"

**Location:** `skills/dev-cycle/SKILL.md:220-231`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers the bootstrap output and exit, the `main MAIN N` first line, the `CLASS SHA SUBJECT` layout, and the refusal causes against the header; does not establish the classifier itself (U3b2's tests).

`--main-log 0000000000000000000000000000000000000000`: `main 596966f0... -`, `refuse main-log: 0000... is not on the default branch's first-parent history at 596966f0...`, exit 2. From HEAD~3: `main 596966f0... 3` then `other 413ce9dd... docs(questions): ...` (three lines). Header: refuses "when SINCE ... is not on that history (main was rewritten, or SINCE is on another branch) or it cannot be listed" (`scripts/build-loop.sh:197-200`); a short id is exit 1 usage (executed: exit 1).

**Evidence:** `scripts/build-loop.sh:141-200`; `docs/reviews/execution-logs/u4b1-final-r1-fc-state.log`

---

## Claim 21: Step 0.3 and step 1: "`hg -C MAIN_WT worktree add -b chore/dev-cycle-DATE-HHMM WT MAIN` ... WT is removed (`hg -C MAIN_WT worktree remove WT`) ..."; "`hg -C MAIN_WT worktree prune` (a locked worktree, a live loop's, is never pruned)"

**Location:** `skills/dev-cycle/SKILL.md:232-235`, `:276-277`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers the commands as written under `hg` and prune keeping a locked worktree whose directory is gone (removing an unlocked one); does not establish that `--start`'s lock reason survives prune (lock file kept, so it does by construction) or that `worktree remove` succeeds with untracked files in WT (it refuses without --force).

Executed: add exit 0 on `chore/dev-cycle-2026-10-13-2231`; after deleting both directories, `worktree prune` kept `.../lk ... [lk] locked` and dropped `ul`; `worktree remove "$WT"` exit 0. `--start` locks its worktree: header `scripts/build-loop.sh:465-470`.

**Evidence:** `skills/dev-cycle/SKILL.md:232-235`, `:276-277`; `docs/reviews/execution-logs/u4b1-final-r1-fc-worktree.log`

---

## Claim 22: Step 1: "It takes a lock in the git common directory, so it waits while a loop's gate runs (it says so once)"

**Location:** `skills/dev-cycle/SKILL.md:264-265`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers take_lock's lock location, wait and single message; does not establish anything about `build-loop.sh`, which takes no health-check lock.

```bash
# scripts/health-check.sh:1107-1117 (enclosing take_lock() :1104-1119 — read)
    d="$(git -C "$REPO_ROOT" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 0
    lk="$d/health-check.lock"
    ...
    flock -n -E 75 -o "$lk" bash "$REPO_ROOT/scripts/health-check.sh" "$@" || rc=$?
    if [[ "$rc" -eq 75 ]]; then
        yellow "waiting for another health check in this repository (health-check.lock)"
        rc=0; flock -o "$lk" bash "$REPO_ROOT/scripts/health-check.sh" "$@" || rc=$?
```

It waits only for another health-check run (a loop's pr-prep gate). SKILL.md's own intro calls `scripts/build-loop.sh` "the gate" (`SKILL.md:15-16`), and a loop's `build-loop.sh --check` takes no such lock. Precise version: "it waits while another health check (a loop's pr-prep gate) runs".

**Evidence:** `scripts/health-check.sh:1096-1123`, `skills/dev-cycle/SKILL.md:15-16`

---

## Claim 23: Step 1: "a wait past an hour is recorded, the run is stopped by its PID (it would still take the lock later), and the step's check is skipped"

**Location:** `skills/dev-cycle/SKILL.md:266-267`; commit 4c911717 ("B8: ... an abandoned health check is stopped by its PID")
**Type:** Behavioral / Error-handling
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers stopping the health check's own process by its PID while take_lock waits; does not establish a process-group stop (`kill -- -PGID`) or a Bash-tool task stop, which the text does not name.

While waiting, `health-check.sh` is a parent whose child is `flock -o health-check.lock bash health-check.sh` (`scripts/health-check.sh:1116`, quoted in Claim 22). Executed with a copy of take_lock's shape: the process list showed `1261471 bash .../hc.sh` with child `1261475 flock -o .../health-check.lock bash .../hc.sh`; after `kill 1261471`, once the holder released, the result was "child ran after the parent was stopped by its PID: child ran (took the lock)". So stopping "its PID" leaves the orphaned `flock` to take the lock later and run the suites — the outcome the parenthetical says the stop prevents — concurrent with steps 2-4b's tests. The stop needs the waiting `flock` (and anything under it), e.g. the process group, stopped too.

**Evidence:** `scripts/health-check.sh:1104-1119`; `docs/reviews/execution-logs/u4b1-final-r1-fc-lock.log` (cwd scratchpad, temp /tmp/u4b1-fc1-uTeL, exit 0, 2026-10-13T22:30:51Z; the probe is a mimic of take_lock's code, not the real script, hence Medium)

---

## Claim 24: Step 4 drift check: "a `--merge` commit, with a `Build-loop-gate:` trailer ... the loop's research doc (`docs/working/research-STEM.md`, which the loop force-adds)"

**Location:** `skills/dev-cycle/SKILL.md:332-337`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers the trailer `--merge` writes and the loop prompt's force-add and Path A wording; does not establish that a loop obeys the prompt (a prompt, not a gate).

```bash
# scripts/build-loop.sh:1468 (enclosing gate_msg() :1467-1470 — read)
  printf "Merge branch '%s' (build-loop %s)\n\nBuild-loop-gate: %s\n" "$1" "$2" "$3"
# scripts/build-loop.sh:1688 (in loop_prompt() :1675-1696 — read)
Force-add your research doc (git add -f docs/working/research-$s.md), so your design records land with your work. ...
```

**Evidence:** `scripts/build-loop.sh:1467-1470`, `:1675-1696`

---

## Claim 25: Step 4b: "a drift finding from step 4" is a trigger; the dimension "checks that `Self-merge never:` covers the paths that take effect on merge in this repo (F57)"

**Location:** `skills/dev-cycle/SKILL.md:348-357`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers agreement with the plan's step 4b note and F57 row; does not establish any code (none exists for it).

Plan: "Step 4b, deep audit: a drift finding is a trigger; the audit gains the "constraints and project guidance still match intent" dimension (it also checks that `Self-merge never:` covers paths that take effect on merge, F57)" (`docs/working/plan-build-loop-handoff.md:256`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:175`, `:256`

---

## Claim 26: pr-prep: "Wait until no subagent this task started is still running; other sessions' agents and build loops share the uid and keep running (dev-cycle D14) ... stop each by its PID ..., never by a name or pattern"

**Location:** `workflows/pr-prep.md:333`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers agreement with D14; does not establish the Claim 23 defect, which is in SKILL.md's health-check stop, not here (pr-prep stops leftover probes, not a lock waiter).

D14: "The quiesce in step 1, and pr-prep's quiesce before its gate, cover only subagents this task started, and never stop or reap a process this task did not start (by PID)." (`docs/working/plan-build-loop-handoff.md:106`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:106`, `workflows/pr-prep.md:333`

---

## Claim 27: commit 0cd86cc0: "A3: the bootstrap's own --main-log refusal is exempt; the other causes named." and "R2: --state refuses a caller's config pair, not an exported variable."

**Location:** commit 0cd86cc0 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** reviewer
**Scope:** Covers A3 against step 0.2's text and the executed bootstrap (Claim 20), and R2 against caller_gate (pairs refused; `GIT_NO_REPLACE_OBJECTS`/`GIT_PREFIX` set aside); does not establish R2's broader reading for repo-local variables such as `GIT_DIR`, which caller_gate does refuse as stray variables (`scripts/build-loop.sh:662-664`) — "exported variable" must be read as an exported identity or hardening setting.

**Evidence:** `skills/dev-cycle/SKILL.md:227-231`, `scripts/build-loop.sh:660-674`; `docs/reviews/execution-logs/u4b1-final-r1-fc-state.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 19** (`skills/dev-cycle/SKILL.md:218-219`): step 0.1 routes a `--state` exit 1 to `you: judgment`; the D6 Rule (`:52-57`) routes every exit-1 stop to `agent`. Pick one (the Rule's row-742 reasoning fits `--state`'s environmental exit-1 causes).
- **Claim 23** (`skills/dev-cycle/SKILL.md:266-267`): stopping the health check "by its PID" leaves take_lock's waiting `flock` child, which later takes the lock and runs the suites (executed). Name the process group, or the `flock` child too.

### Mostly Accurate
- **Claim 7** (commit 4c911717): HARDEN has 9 pairs; 10 is the test's GIT_CONFIG_COUNT with the caller's pair.
- **Claim 8b** (`skills/dev-cycle/SKILL.md:25-26`): the by-hand gap is wider than filters and merge drivers: grafts (executed: `hg` honours them, ancestry checks change), shallow, alternates, include/diff config are refused only by `--state`/the snippet.
- **Claim 10** (`skills/dev-cycle/SKILL.md:51-52`): `--main-log`'s exit 2 on `other` lines carries no refuse line; say "the mode's own lines".
- **Claim 17b** (`skills/dev-cycle/SKILL.md:144-145`): `--check-fix` refuses any new file (untracked), not one below an instruction-named directory; a tracked file there, or a staged new one, gets `ok`.
- **Claim 22** (`skills/dev-cycle/SKILL.md:264-265`): the lock waits on another health check, not on "a loop's gate" in the skill's own sense of build-loop.sh.

### Unverifiable
- None.

---

## Goal-Alignment Note

Goal: land U4b1 after a clean review-fix loop; SKILL.md is the product, so a wrong statement is a behavioural defect. The brief's claim 1 (commit.gpgSign) holds end to end by execution: present in all three copies, pinned by a test that fails on six mutants, no HARDEN user broken (288 tests green, shellcheck clean at the gate's severity), caller pairs refused, and a planted signing config runs no gpg under `hg` for a commit or a merge. Claims 2, 5, 7, 8, 9 also hold, with wording gaps (Claims 8b, 10, 17b, 22). Two findings affect what an orchestrator does: the health-check stop by PID (Claim 23) does not stop the lock waiter, so an abandoned run can still start later, overlapping the iteration's own tests — worth the **performance-reviewer** (contention) and **security-reviewer** (an unbounded orphan running repository code) a look; and the exit-1 routing contradiction (Claim 19, brief item 10) — **api-consistency-reviewer**. Neither is covered by an existing override row. Claim 8b's grafts residue in the by-hand fallback is for **security-reviewer** to weigh against Q-140's interim.
