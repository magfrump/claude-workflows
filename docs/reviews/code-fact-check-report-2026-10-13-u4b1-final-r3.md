Commit: 4c911717

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u4b1`, branch `feat/build-loop-u4b1`)
**Scope:** branch diff `git diff main...HEAD` (HEAD 4c911717; commits 458dc170, 0cd86cc0, 4c911717) and their commit messages; final confirming pass, replicate 3. Brief: `u4b1-i3/shared.md`.
**Checked:** 2026-10-13
**Total claims checked:** 31
**Summary:** 24 verified, 5 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). The one family that could recur here is a wrong test-count claim in a commit message, as in "All 85 tests ... pass" and "mode1-equiv 33". The branch's "Suites 288 green" was executed and holds (claim 27), so it does not match that pattern.

Execution logs are in `docs/reviews/execution-logs/`, all prefixed `u4b1-final-r3-fc-`. Every probe ran in its own `mktemp -d /tmp/u4b1-fc3-XXXX` directory, inside a clone of /workspace or a fresh repo, and removed that directory when it finished. No gated mode was run in /workspace or in the worktree.

| Log | Command (cwd `/tmp`) | Exit | Timestamp (UTC) |
|---|---|---|---|
| `u4b1-final-r3-fc-probe1.log` | `timeout 300 bash scratchpad/fc3-probe1.sh`: hg against planted signing and identity; `--state` caller pairs; `--main-log`; worktree add/remove | 0 | 2026-10-13T22:29:57Z |
| `u4b1-final-r3-fc-mutants.log` | `timeout 900 bash scratchpad/fc3-probe2.sh`: git_harden pin test at 4c911717 and 6 mutants | 0 | 2026-10-13T22:30:31Z |
| `u4b1-final-r3-fc-bats.log` | `TMPDIR=<tmp> timeout 1500 bats test/scripts/{build-loop-check,build-loop-dispatch,build-loop-merge,build-loop-orchestrator,build-loop-read,dev-cycle}.bats` (cwd: the worktree) | 0 (1..288, 288 ok) | 2026-10-13T22:30:43Z to 22:33:31Z |
| `u4b1-final-r3-fc-hclock.log` | `timeout 60 bash scratchpad/fc3-probe3.sh`: take_lock's process tree, with the started PID stopped | 0 | 2026-10-13T22:31:07Z |
| `u4b1-final-r3-fc-checkfix.log` | `timeout 600 bash scratchpad/fc3-probe4.sh`: `--check-fix` before staging, then `--cycle-diff` per path | 0 | 2026-10-13T22:33:06Z |
| `u4b1-final-r3-fc-shellcheck.log` | `shellcheck -S warning -x scripts/build-loop.sh scripts/lib/dev-cycle-read.sh test/lib/d6-snippet.bash scripts/dev-cycle.sh` (cwd: the worktree) | 0 (empty) | 2026-10-13T22:33:43Z |
| `u4b1-final-r3-fc-verifysig.log` | `timeout 120 bash scratchpad/fc3-probe5.sh`: hg merge with `merge.verifySignatures` and `gpg.program` in `.git/config` | 0 | 2026-10-13T22:34:43Z |

(The probe scripts are in the session scratchpad, `/tmp/claude-1000/-workspace/5f7c1a26-.../scratchpad/fc3-probe{1..5}.sh`.)

Tags used on every claim: **Legibility-target** says who misreads the claim if it is wrong (orchestrator = the session that follows SKILL.md; maintainer = a reader of code or commits). **Verification mode** and **Scope** follow the skill.

---

## Claim 1: "SKILL.md is 397 lines ... U4b1, the orchestrator's frame (173 lines as written)"

**Location:** `docs/working/plan-build-loop-handoff.md:341-342`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers main's SKILL.md line count and the changed-line count at 458dc170, counted as the note counts it (added plus removed lines, in code outside `docs/`). It does not establish the branch's count at HEAD, which is now 205 lines counted the same way and still under the cap of 400.

`git show main:skills/dev-cycle/SKILL.md | wc -l` → `397`. At 458dc170, `git diff --numstat main 458dc170` gives `130 29 skills/dev-cycle/SKILL.md`, `7 5 test/scripts/build-loop-orchestrator.bats` and `1 1 workflows/pr-prep.md`, which sum to 173. At HEAD the same files plus the three script lines sum to 205 (148+29, 9+7, 1+1, 1+1, 4+2, 1+1). Command run in the worktree at 2026-10-13T22:3xZ, exit 0. The output is quoted here in place of a log file.

**Evidence:** `docs/working/plan-build-loop-handoff.md:341-342`; `git diff --numstat` output above

---

## Claim 2: "(the lib's HARDEN list: ... log.date, log.showSignature, commit.gpgSign; a git -c pair would win over it), whatever the value"

**Location:** `scripts/build-loop.sh:133-139`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers `--state` refusing a caller's `commit.gpgSign` pair through `GIT_CONFIG_COUNT` and through `GIT_CONFIG_PARAMETERS` (git -c). It does not establish that `--state` refuses a `commit.gpgSign` set in `.git/config`: it does not, by design, and hg's own pair overrides it there (claim 10a).

`caller_gate` marks a HARDEN key: "`for kv in "${HARDEN[@]}"; do kv="${kv%%=*}"; [[ "$k" != "${kv,,}" ]] || k+=" "; done`" (`scripts/build-loop.sh:668`). Executed (probe1):
- `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=commit.gpgSign GIT_CONFIG_VALUE_0=false` → `refuse state commit.gpgsign: set by the caller's git -c or GIT_CONFIG_COUNT pairs ...`, rc=2. The value was `false`, so the refusal holds whatever the value.
- The same key through `GIT_CONFIG_PARAMETERS` → same line, rc=2.
- `commit.gpgSign true` in the repo's `.git/config` → `ok`, rc=0.

**Evidence:** `scripts/build-loop.sh:660-675`; `docs/reviews/execution-logs/u4b1-final-r3-fc-probe1.log`

---

## Claim 3: "and no commit signing (commit.gpgSign runs gpg.program on a commit or merge: the orchestrator's own commits, SKILL.md's hg ...)" and the HARDEN array gaining `commit.gpgSign=false`

**Location:** `scripts/lib/dev-cycle-read.sh:341-343, 354`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the claim that a planted `commit.gpgSign` runs gpg.program on a plain commit and a plain merge, and that the HARDEN pair (as carried by hg) prevents it. It does not establish that HARDEN switches off every gpg.program route: claim 10b shows `merge.verifySignatures` still runs it, and only `--state` refuses that.

`HARDEN=(... log.showSignature=false commit.gpgSign=false)` (`scripts/lib/dev-cycle-read.sh:354`). Probe1 planted `commit.gpgSign true` and `user.signingKey DEADBEEF` in a clone's `.git/config`, with a shim `gpg` first on PATH:
- Plain `git commit`: `rc=128 gpgran=yes`.
- Plain `git merge`: `rc=128 gpgran=yes`.
- `hg commit`: `rc=0 gpgran=no`.
- `hg merge --no-edit side`: `rc=0 gpgran=no parents=2`.

No other HARDEN user broke: all 288 tests in the six build-loop and dev-cycle suites passed (bats log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:329-366`; `docs/reviews/execution-logs/u4b1-final-r3-fc-probe1.log`; `docs/reviews/execution-logs/u4b1-final-r3-fc-bats.log`

---

## Claim 4: "every `dev-cycle.sh` call ... as `~/.claude/scripts/dev-cycle.sh` ...; WT made as step 0.3 says, from the default branch's commit (`hg -C MAIN_WT rev-parse --verify refs/heads/main`, or master); the Rules' `hg` for every git command"

**Location:** `skills/dev-cycle/SKILL.md:19-24`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers that the fallback names an allowed form for every dev-cycle.sh call (the digest and the check modes), and that hg's `rev-parse --verify refs/heads/main` and step 0.3's `worktree add -b ... WT MAIN` and `worktree remove` work under hg. It does not establish what the fallback leaves unchecked (claim 5), nor whether `~/.claude/scripts` is trustworthy (override row, Q-103 class).

Probe1 ran these under hg in a clone:
- `hg -C "$T/r" rev-parse --verify refs/heads/main` → a 40-hex id, rc=0.
- `hg -C "$T/r" worktree add -q -b chore/dev-cycle-2026-10-13-2200 "$T/r/.claude/wt-dev-cycle-2026-10-13-2200" "$M"` → rc=0, on branch `chore/dev-cycle-2026-10-13-2200`.
- `worktree remove` → rc=0.

The fallback's own text: "every `dev-cycle.sh` call (the digest and every check mode) as `~/.claude/scripts/dev-cycle.sh`" (`SKILL.md:20-21`).

**Evidence:** `skills/dev-cycle/SKILL.md:19-24, 232-235`; `docs/reviews/execution-logs/u4b1-final-r3-fc-probe1.log`

---

## Claim 5: "With no `--state` run, nothing refuses the repository config `hg` cannot switch off (a filter or merge driver): the by-hand cycle carries that gap."

**Location:** `skills/dev-cycle/SKILL.md:25-26`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator, and the user reading the gap
**Scope:** Covers that a filter and a merge driver are config hg does not switch off and that only `--state` refuses. It does not establish that this is the whole gap, and it is not.

`--state` refuses more than filters and merge drivers, and with no `--state` run all of these go unchecked. `STATE_KEYS_RE='^(filter\.|include|hook\.|merge\.|diff\.|core\.fsmonitor|core\.attributesfile|core\.hookspath|gpg\.|log\.showsignature|extensions\.partialclone$|remote\..*\.promisor$)'` (`scripts/build-loop.sh:612`), and the state gate's file checks: "`for f in info/attributes info/grafts shallow objects/info/alternates`" (`scripts/build-loop.sh:626`).

Two of these matter to hg:
- Config: `merge.verifySignatures` with `gpg.program` made hg's merge run the planted program. Probe5: `rc=128 gpgran=yes`, and `--state` refused both keys.
- Non-config state that hg does not switch off: grafts change the merge base, and info/attributes can name a built-in merge or diff driver.

Precise version: "nothing refuses repository state hg cannot switch off (filters, merge and diff drivers, merge.verifySignatures with gpg.program, includes, grafts, info/attributes, alternates)".

**Evidence:** `scripts/build-loop.sh:599-633`; `docs/reviews/execution-logs/u4b1-final-r3-fc-verifysig.log`

---

## Claim 6: "In claude-workflows it runs main's own committed scripts, elsewhere the root-owned image copy, so nothing a build loop edits runs as the gate."

**Location:** `skills/dev-cycle/SKILL.md:48-50`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers which copy the snippet runs, per its header and code. It does not establish the conclusion "nothing a build loop edits runs as the gate", which the snippet's own header contradicts for a loop that moves main or rewrites `.git` (Q-140, the reason the block is pending).

The snippet picks main's copy when "`if ($c ne $root) { print "other\n"; exit 0 }`" does not fire (`test/lib/d6-snippet.bash:75`). Its header says: "Known gap (final security F1, Q-140): the choice of main's copy rests on the repository's own data, so in another project a loop that moves main onto a copy of D6_ROOT, or rewrites the .git entry, gets that project's scripts run instead of the image copy" (`test/lib/d6-snippet.bash:25-28`). It also says "It trusts refs/heads/main and that entry" (`:24`). The mechanism is right. The absolute conclusion should carry "(but Q-140's gap)". The block is pending, so no orchestrator runs it today.

**Evidence:** `test/lib/d6-snippet.bash:11-40, 75-95`

---

## Claim 7: "`refuse d6: WHY` (exit 2) means nothing ran."

**Location:** `skills/dev-cycle/SKILL.md:50-51`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers every `refuse d6:` path in the snippet. It does not establish that a script's own exit 2 (no `refuse d6:` line) means nothing ran.

`no() { echo "refuse d6: $*"; exit 2; }` (`test/lib/d6-snippet.bash:44`). Every `no` call comes before the line "`env -u BASH_ENV -u ENV -u DEV_CYCLE_SCRUBBED bash "$d/scripts/$s" "$@"`" (`:95`), the only line that runs a script. The header agrees: "2 and one "refuse d6: WHY" line on stdout, with nothing run" (`:30-31`).

**Evidence:** `test/lib/d6-snippet.bash:41-97`

---

## Claim 8: "A `build-loop.sh` answer is exit 0, or exit 2 with the mode's own refuse lines; any other exit (1 included), or a call the Bash tool timed out, means nothing was decided"

**Location:** `skills/dev-cycle/SKILL.md:51-54`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers the modes steps 0-1 use (`--state`, `--main-log`). It does not establish the reading for `--check`, `--merge`, `--land-cycle`, `--start` or `--prompt`, which U4b2's steps will use.

The header's Exit paragraph: "2 any other --check, --merge, --start or --prompt verdict line, --main-log's other or refuse line, a --cycle-diff refuse line, or the state gate (--state's included) not ok" (`scripts/build-loop.sh:513-516`).

So exit 2 also carries lines that are not refuse lines. Probe1: `--main-log` three commits back printed `main ... 3` and three `other ...` lines, with no refuse line, and exited 2 (`MAINLOG 3 back: rc=2`). Read literally, "exit 2 with the mode's own refuse lines" leaves that answer unclassified. Step 0.2 does handle `other` lines, so an orchestrator that reads both is not misled. The rest holds:
- A bootstrap `refuse main-log:` exits 2.
- A short SINCE exits 1, which is a usage error.
- The header's "a caller reads any exit but 0 as nothing decided" (`:518`) matches "nothing was decided".

Precise version: "exit 0, or exit 2 with the mode's documented lines (refuse lines, `--main-log`'s `other`, `--check`'s verdicts)".

**Evidence:** `scripts/build-loop.sh:511-521`; `docs/reviews/execution-logs/u4b1-final-r3-fc-probe1.log`

---

## Claim 9: "Each stop ends the iteration there, with no record ...: the line and stderr go in one `agent` entry" vs step 0.1 "refuse lines ... are a stop, quoted in one `you: judgment` entry ...; so is an exit 1, with its stderr"

**Location:** `skills/dev-cycle/SKILL.md:54-57`, `skills/dev-cycle/SKILL.md:216-219`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers the two rules' agreement on "stop, no record". It does not establish which entry route a `--state` exit 1 takes: the two texts disagree.

After the i2 fix (B6), the Rule makes every exit 1 a stop whose line and stderr go in "one `agent` entry" (`:56`). Step 0.1 sends `--state`'s exit 1 to "one `you: judgment` entry" (`:218-219`).

Both say stop with no record, so the iteration's outcome is the same. The entry's `Needs:` route differs, and a judgment entry spends the user's attention. Step 0.1's text may be meant as the more specific rule (a `--state` exit 1 is a caller-environment fault, `scripts/build-loop.sh:126-128`). If so, the Rule should say so, or step 0.1 should name `agent`. This is unit-introduced: the Rule's agent routing was added in 4c911717.

**Evidence:** `skills/dev-cycle/SKILL.md:51-57, 214-219`; `scripts/build-loop.sh:122-128`

---

## Claim 10a: "`hg` reads no global or system config and runs no hook, fsmonitor command, signing program [on commit] or replaced object"

**Location:** `skills/dev-cycle/SKILL.md:65, 68-70`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers commit signing and merge-commit signing with commit.gpgSign and user.signingKey planted, and that the hg line in SKILL.md is byte-identical to the one probed. It does not establish signature verification on merge (claim 10b).

Probe1 printed `HG_LINE identical to SKILL.md` (a `grep -qxF` of the literal line), then `HG commit rc=0 gpgran=no` and `HG merge rc=0 gpgran=no`. The controls with plain git ran gpg. The pairs for global and system config, hooks and fsmonitor are `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 ... -c core.hooksPath=/dev/null -c core.fsmonitor=false`, and `GIT_NO_REPLACE_OBJECTS=1 ... -c core.useReplaceRefs=false` (`SKILL.md:65`).

**Evidence:** `skills/dev-cycle/SKILL.md:65`; `docs/reviews/execution-logs/u4b1-final-r3-fc-probe1.log`

## Claim 10b: "runs no ... signing program" (read broadly: no gpg.program run)

**Location:** `skills/dev-cycle/SKILL.md:68-70`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers hg's merge with `merge.verifySignatures` and `gpg.program` planted in `.git/config`. It does not establish whether a hostile loop can make main's tip carry a signature header in practice; the probe forged one.

Probe5 forged a `gpgsig` header onto the merged commit, set `merge.verifySignatures true` and `gpg.program <shim>`, and ran `hg merge -q --no-edit side`. The result was `rc=128 gpgran=yes` (`fatal: Commit 7878757 does not have a GPG signature.`), so hg ran the planted program. `--state` refused both keys (`refuse state merge.verifysignatures`, `refuse state gpg.program`). The next sentence's re-run of `--state` therefore covers it. The case belongs in the "does not switch off" list, which names only "a filter, a merge driver" (`:71`). Precise version: "runs no ... commit signing".

**Evidence:** `skills/dev-cycle/SKILL.md:68-74`; `scripts/build-loop.sh:612`; `docs/reviews/execution-logs/u4b1-final-r3-fc-verifysig.log`

---

## Claim 11: "It does not switch off what the repository's own config can still name (a filter, a merge driver): `--state` refuses those, but only when it runs, so run it again (through the D6 block, from WT) right before the iteration's commits"

**Location:** `skills/dev-cycle/SKILL.md:70-73`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers `--state` refusing a planted filter and merge driver, and that hg has no pair for either. It does not establish what the re-run misses between the check and the commit (named in the text as Q-103's residual) or the wider list in claims 5 and 10b.

Probe1 planted `filter.x.clean cat` and `merge.y.driver true`. `--state` gave rc=2 with `refuse state filter.x.clean: ...` and `refuse state merge.y.driver: ...`. hg's `-c` list (`SKILL.md:65`) holds no `filter.` or `merge.` key.

**Evidence:** `skills/dev-cycle/SKILL.md:65-74`; `docs/reviews/execution-logs/u4b1-final-r3-fc-probe1.log`

---

## Claim 12: "Commits set their identity on the command, as `GIT_AUTHOR_NAME`, `GIT_AUTHOR_EMAIL`, `GIT_COMMITTER_NAME` and `GIT_COMMITTER_EMAIL` (these outrank a planted `author.*` or `committer.*` key)"

**Location:** `skills/dev-cycle/SKILL.md:75-79`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers env identity against planted `author.*`, `committer.*` and `user.*` in `.git/config`, on a commit and on a merge (git 2.39.5). It does not establish anything about the global-config read (`git config --global --get user.name`), which reads the loop-writable `~/.gitconfig` by design.

Probe1 planted `author.name EVILA`, `committer.name EVILC` and `user.name EVILU`. With the four `GIT_*` variables on the command, `HG commit ident: Good <good@x> / GoodC <goodc@x>` and `HG merge ident: Good <good@x> / GoodC <goodc@x>`.

**Evidence:** `docs/reviews/execution-logs/u4b1-final-r3-fc-probe1.log`

---

## Claim 13: "Never export these settings: set them per command, as `hg` does (`--state` refuses a caller's config pair for a `HARDEN` key, row 702)."

**Location:** `skills/dev-cycle/SKILL.md:79-80`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers that `--state` refuses a HARDEN-key pair and accepts hg's exported environment variables. It does not establish that exported variables are harmless to other tools.

Probe1: `env GIT_NO_REPLACE_OBJECTS=1 GIT_LITERAL_PATHSPECS=1 GIT_OPTIONAL_LOCKS=0 ... --state` → `ok`, rc=0. A `commit.gpgSign` pair → refused, rc=2 (claim 2). The parenthetical names only pairs, which matches.

**Evidence:** `scripts/build-loop.sh:660-675`; `docs/reviews/execution-logs/u4b1-final-r3-fc-probe1.log`

---

## Claim 14: Settings: "Build-loop slots (live loops at once, 1-9; else 3: D9), Self-merge never (globs ... or `none`) and the optional Reader roots and Reader homes lines: read only through `build-loop.sh --settings`, from the default branch's commit ...; A malformed never line turns self-merge off."

**Location:** `skills/dev-cycle/SKILL.md:111-116`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers agreement with `--settings`' header. It does not establish the parser's behaviour on each malformed form.

Header: "five lines from the default branch's commit, never the working tree" (`scripts/build-loop.sh:19-20`); "Loops at once: "Build-loop slots: N", N from 1 to 9; else 3" (`:31`); "Malformed (or a file not read) turns self-merge off" (`:38-39`); "readers N-roots M-homes ... "Reader roots: PATH ..." ... "Reader homes: PATH ..."" (`:50-53`).

**Evidence:** `scripts/build-loop.sh:19-60`

---

## Claim 15: "Every loop prompt quotes it [docs/constraints.md] ... The orchestrator dispatches only while `--settings` prints `constraints ok`."

**Location:** `skills/dev-cycle/SKILL.md:119-122`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers the loop prompt's quote and `--start`'s precondition. It does not establish D2's "files one `you: judgment` entry" when the file is missing, which the paragraph does not claim.

`loop_prompt` prints "The project's constraints (docs/constraints.md at $MAIN_SHA), quoted:" and then `printf '%s\n' "$3" | sed 's/\r$//; s/^/> /'` (`scripts/build-loop.sh:1683-1685`). `--start` runs "with --settings' constraints line ok" (`:460`).

**Evidence:** `scripts/build-loop.sh:455-475, 1671-1696`

---

## Claim 16: "the cycle rules `build-loop.sh --cycle-diff` applies ... repeat only part of `--check-fix` (a `.md` under `docs/working/` or `docs/reviews/`, a doc an instruction file imports, a new file below a directory named like an instruction file, and a symlink pass them ...)"

**Location:** `skills/dev-cycle/SKILL.md:140-145`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers each of the five named path kinds, with `--check-fix` run before staging (as the paragraph orders) and `--cycle-diff` after. It does not establish that the list is exhaustive.

Probe4, on a chore branch in a clone, ran `--check-fix` before staging and `--cycle-diff` after:

| Path kind | `--check-fix` | `--cycle-diff` |
|---|---|---|
| `docs/working/fc3-w.md` | `skip ... not working/` | `rc=0: ok` |
| `docs/reviews/fc3-r.md` | skip | ok |
| `docs/fc3-imported.md` (AGENTS.md has `@docs/fc3-imported.md`) | `skip ... an instruction file names it after an @` | ok |
| new `docs/claude.md/new.md` | `skip ... no tracked file ... matches` | ok |
| symlink `docs/fc3-link.md` | skip | ok |

A tracked `docs/claude.md/tracked.md` gets `ok` from `--check-fix`, which is why the text says "new" (B10).

**Evidence:** `scripts/dev-cycle.sh:184-199`; `scripts/build-loop.sh:1920-1938`; `docs/reviews/execution-logs/u4b1-final-r3-fc-checkfix.log`

---

## Claim 17: "It refuses (`refuse d6: WHY`, exit 2, nothing run) a replace ref, grafts, a default branch that is not exactly one plain main or master naming a commit, an object it cannot read whole or that does not hash to its id, and more (its header lists every case ...)"

**Location:** `skills/dev-cycle/SKILL.md:184-191`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers the listed refusals against the snippet's code. It does not establish T33's equality test, which is pending.

The code makes each named refusal:
- `[[ -z "$x" ]] || no "a replace ref exists (F38)"` (`test/lib/d6-snippet.bash:53`)
- `no "info/grafts exists (F38)"` (`:55`)
- `no "the default branch is not exactly one of main and master"` (`:57`)
- `no "refs/heads/$m names no commit"` (`:59`)
- the perl reader's `die "$id does not hash to its id\n"` (`:70`), which becomes `no ...` (`:86`)

**Evidence:** `test/lib/d6-snippet.bash:29-97`

---

## Claim 18: "`ok` goes on; refuse lines (planted `.git` state: replace refs, grafts, hooks or filter config, a default branch that is not one plain main or master...) are a stop"

**Location:** `skills/dev-cycle/SKILL.md:214-218`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers the refusal causes named. It does not establish the route of an exit 1 (claim 9).

The state gate prints "`refuse state refs/replace: ...`" (`scripts/build-loop.sh:630`), refuses "info/grafts" (`:626-628`), refuses "`hook\.`" and "`core\.hookspath`" keys and "`filter\.`" (`:612`), and `default_gate` prints "both main and master exist" (`:681`). Executed: the filter plant was refused (claim 11).

**Evidence:** `scripts/build-loop.sh:599-700`; `docs/reviews/execution-logs/u4b1-final-r3-fc-probe1.log`

---

## Claim 19: "with no such line yet, pass 40 zeros: it prints `main MAIN -` and refuses, and that MAIN is the bootstrap. Its first line `main MAIN N` names MAIN ...; read each later line's class and SHA by position ... Any `other` line, or a `refuse main-log:` line other than the bootstrap's own (SINCE is off main's history ...; or the history could not be listed), blocks this iteration's dispatch"

**Location:** `skills/dev-cycle/SKILL.md:220-231`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers the bootstrap output, the line formats, the classes and the refusal causes against the header. It does not establish a `refuse state` line from `--main-log`'s own state gate (a race after step 0.1), which step 0.2 does not name. It also does not cover where SINCE comes from: the newest record's `Main at:` line is U4b2's to write (override row).

Probe1 output, with timestamp and exit codes in the log:
- `--main-log 0000...0000` → `main 2fde50d9... -` / `refuse main-log: 0000000000000000000000000000000000000000 is not on the default branch's first-parent history at 2fde50d9...`, rc=2.
- Three commits back → `main 2fde50d9... 3` and three `other SHA SUBJECT` lines, rc=2.
- At main → `main ... 0`, rc=0.

The header gives the causes: "when SINCE ... is not on that history (main was rewritten, or SINCE is on another branch) or it cannot be listed" (`scripts/build-loop.sh:179-182`).

**Evidence:** `scripts/build-loop.sh:141-182`; `docs/reviews/execution-logs/u4b1-final-r3-fc-probe1.log`

---

## Claim 20: "`hg -C MAIN_WT worktree add -b chore/dev-cycle-DATE-HHMM WT MAIN` ... WT is removed (`hg -C MAIN_WT worktree remove WT`) once the iteration's land is verified: every registered worktree ... joins the import walks' reader set."

**Location:** `skills/dev-cycle/SKILL.md:232-235`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers that both commands work under hg and that the walks read the worktree registry. It does not establish that `worktree remove` succeeds on a WT holding untracked files, or when the land is verified (U4b2's step).

Both commands succeeded in probe1 (claim 4). The lib says: "Both walks also read the repository's worktree registry (import_readers)" (`scripts/lib/dev-cycle-read.sh:49`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:49`; `docs/reviews/execution-logs/u4b1-final-r3-fc-probe1.log`

---

## Claim 21a: "It takes a lock in the git common directory, so it waits while a loop's gate runs (it says so once)"

**Location:** `skills/dev-cycle/SKILL.md:264-265`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers take_lock's lock path and its single message. It does not establish anything about a loop's own gate, beyond D14's statement that the loop runs the same health check.

`lk="$d/health-check.lock"` with `d` from `--git-common-dir`. Then `flock -n -E 75 ...` and, on 75, one `yellow "waiting for another health check in this repository (health-check.lock)"` followed by a blocking `flock -o "$lk" ...` (`scripts/health-check.sh:1107-1116`). The simulation printed the message once (hclock log).

**Evidence:** `scripts/health-check.sh:1104-1119`; `docs/reviews/execution-logs/u4b1-final-r3-fc-hclock.log`

## Claim 21b: "a wait past an hour is recorded, the run is stopped by its PID (it would still take the lock later), and the step's check is skipped (row 750)"; commit 4c911717 "B8: ... an abandoned health check is stopped by its PID."

**Location:** `skills/dev-cycle/SKILL.md:266-267`; commit 4c911717 message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers stopping the PID the orchestrator started (the health-check bash, `$!` of the background run) while it waits in take_lock. It does not establish the outcome of stopping its whole process group or the `flock` child as well; the text does not ask for either.

While waiting, the started bash runs a child: "`rc=0; flock -o "$lk" bash "$REPO_ROOT/scripts/health-check.sh" "$@" || rc=$?`" (`scripts/health-check.sh:1116`).

Probe3 copied take_lock's process tree, with a cheap inner command, into a temp dir. A holder kept the lock for 6 s, and the probe then stopped the started PID:

```
tree before kill:
1294627 1294623 flock -o /tmp/u4b1-fc3-WerX/health-check.lock bash /tmp/u4b1-fc3-WerX/hc.sh
after kill of 1294623: alive? no
remaining flock waiters from this probe:
1294627 flock -o /tmp/u4b1-fc3-WerX/health-check.lock bash /tmp/u4b1-fc3-WerX/hc.sh
ran marker after lock released: yes
```

The orphaned `flock` keeps waiting and, once the holder releases the lock, runs the health check. That is exactly what the parenthetical says the stop prevents. In the real script, the late run is a full fast and slow suite in WT, and it would hold the lock against the next gate. Stopping by PID has to cover the `flock` child (and its health-check child): its process group, or each PID from `pgrep -P`.

**Evidence:** `scripts/health-check.sh:1104-1119`; `docs/reviews/execution-logs/u4b1-final-r3-fc-hclock.log`

---

## Claim 22: "`hg -C MAIN_WT worktree list` and `hg -C MAIN_WT worktree prune` (a locked worktree, a live loop's, is never pruned)."

**Location:** `skills/dev-cycle/SKILL.md:276-277`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers that `--start`/`--prompt` lock the loop's worktree, and git's documented rule that prune skips locked worktrees. It does not cover a loop worktree whose lock was removed.

`git worktree add -q --lock --reason "$reason" "$DIR" "$br"` (`scripts/build-loop.sh:1662`). git-worktree(1) says a locked worktree is not pruned (paraphrased — no quote available because the source is git's man page, not repo code; not executed).

**Evidence:** `scripts/build-loop.sh:1662`

---

## Claim 23: "For each sampled merge a build loop made (a `--merge` commit, with a `Build-loop-gate:` trailer), read one Path A decision from ... the loop's research doc (`docs/working/research-STEM.md`, which the loop force-adds)"

**Location:** `skills/dev-cycle/SKILL.md:332-337`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers the trailer `--merge` writes and the prompt's force-add instruction. It does not establish that a loop obeys the prompt.

`printf "Merge branch '%s' (build-loop %s)\n\nBuild-loop-gate: %s\n"` (`scripts/build-loop.sh:1468`). The prompt says: "Force-add your research doc (git add -f docs/working/research-$s.md)" (`:1688`).

**Evidence:** `scripts/build-loop.sh:1468, 1688`

---

## Claim 24: Step 4b: "a drift finding from step 4" trigger, and the dimension "whether the constraints and project guidance still match intent ... checks that `Self-merge never:` covers the paths that take effect on merge in this repo (F57)"

**Location:** `skills/dev-cycle/SKILL.md:349-357`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers agreement with the plan. It does not establish what the deep-audit task itself does.

Plan: "Step 4b, deep audit: a drift finding is a trigger; the audit gains the "constraints and project guidance still match intent" dimension (it also checks that `Self-merge never:` covers paths that take effect on merge, F57)" (`docs/working/plan-build-loop-handoff.md:256`). The F57 row is at `:175`.

**Evidence:** `docs/working/plan-build-loop-handoff.md:175, 256`

---

## Claim 25: The git_harden test "the D6 snippet's git and SKILL.md's hg carry the same"; 458dc170 "(both mutants fail it)"; 4c911717 "the pin test now counts 10 pairs"

**Location:** `test/scripts/build-loop-orchestrator.bats:355-372`; commit messages 458dc170, 4c911717
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the test passing at 4c911717 and failing on six mutants. It does not establish pinning of tokens other than `-c` pairs and `GIT_*=` variables beyond the one-line shape (the i1 C4 Won't-Fix).

Probe2 ran a clone at 4c911717:
- Baseline: `bats rc=0; ok 1`.
- `bats rc=1; not ok 1` for each of: (A) hg drops `commit.gpgSign`, (B) lib HARDEN drops it, (C) snippet drops it, (D) hg drops `GIT_NO_REPLACE_OBJECTS`, (E) a second `hg()` line, (F) hg's pair order swapped.

"10 pairs" is `GIT_CONFIG_COUNT=10`: one caller pair and HARDEN's nine (`want+=... "GIT_CONFIG_COUNT=10"`, `:363`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:355-372`; `docs/reviews/execution-logs/u4b1-final-r3-fc-mutants.log`

---

## Claim 26: "Wait until no subagent this task started is still running; other sessions' agents and build loops share the uid and keep running (dev-cycle D14) ... stop each by its PID ..., never by a name or pattern"

**Location:** `workflows/pr-prep.md:333`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer, and the pr-prep runner
**Scope:** Covers agreement with D14. It does not establish the reaping of a process tree (see claim 21b's parent-child caveat, which applies equally here).

D14: "The quiesce in step 1, and pr-prep's quiesce before its gate, cover only subagents this task started, and never stop or reap a process this task did not start (by PID)" (`docs/working/plan-build-loop-handoff.md:106`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:106`; `workflows/pr-prep.md:333`

---

## Claim 27: Commit 4c911717: "No other HARDEN user commits with a signature (build-loop.sh's commit-tree passes --no-gpg-sign; dev-cycle.sh and the snippet never commit)" and "Suites 288 green, run serially; shellcheck clean."

**Location:** commit 4c911717 message
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the six build-loop and dev-cycle suites (288 tests) and shellcheck at warning severity on the four changed scripts. It does not establish the full health-check gate, nor shellcheck's info and style notes (present, below the warning threshold).

`gate_git commit-tree --no-gpg-sign -p "$MAIN_SHA" ...` (`scripts/build-loop.sh:1558`) is shared by `--merge` and `--land-cycle` (`if [[ "$1" == cycle ]]; then chore_msg ...`, `:1557`). A fast-forward (`merge --ff-only`) writes no commit. A grep for `commit|merge|tag|rebase|cherry-pick` git subcommands in `scripts/dev-cycle.sh` and `test/lib/d6-snippet.bash` found none (paraphrased — no quote available because the claim covers the absence of code). Bats: `1..288`, 288 `ok`. Shellcheck `-S warning -x`: exit 0, empty output.

**Evidence:** `scripts/build-loop.sh:1555-1560`; `docs/reviews/execution-logs/u4b1-final-r3-fc-bats.log`; `docs/reviews/execution-logs/u4b1-final-r3-fc-shellcheck.log`

---

## Claim 28: Commit 0cd86cc0: "R1: hg does not switch off a filter, merge driver or commit signing in the repository's own config; only --state refuses those, when it runs."

**Location:** commit 0cd86cc0 message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer (`git log` reader)
**Scope:** Covers the commit-signing atom of this historical message. It does not concern the current text: 4c911717 fixed the behaviour (B1) and its message says so. The filter and merge-driver atoms hold (claim 11).

`--state` gave `ok` with `commit.gpgSign true` in `.git/config` (probe1, `STATE repo commit.gpgSign: rc=0 ... ok`), so it never refused commit signing. At HEAD, hg does switch signing off (claim 10a). The message cannot be amended without a rewrite. Its successor 4c911717 records the correction ("B1: --state never refused commit.gpgSign"), so a log reader who reads both is not misled. This entry needs no action and is reported for completeness.

**Evidence:** `scripts/build-loop.sh:612`; `docs/reviews/execution-logs/u4b1-final-r3-fc-probe1.log`

---

## Claim 29: Commit 0cd86cc0: "R2: --state refuses a caller's config pair, not an exported variable."

**Location:** commit 0cd86cc0 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers hg's exported variables (accepted) and a HARDEN-key pair (refused). It does not cover repo-local variables such as `GIT_DIR`, which `--state` does refuse when exported (`stray_vars`). The message means hg's variables.

Executed in probe1 (claims 2 and 13).

**Evidence:** `scripts/build-loop.sh:640-675`; `docs/reviews/execution-logs/u4b1-final-r3-fc-probe1.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 21b** (`skills/dev-cycle/SKILL.md:266-267`; 4c911717 B8): stopping the health check by the PID the orchestrator started leaves take_lock's `flock` child waiting, and once the lock frees it runs the full check anyway (executed). The stop must cover the `flock` child and its child (its process group, or the PIDs from `pgrep -P`).
- **Claim 28** (commit 0cd86cc0): "only --state refuses ... commit signing" is false. 4c911717 already corrects it; no action.

### Mostly Accurate
- **Claim 5** (`SKILL.md:25-26`): the by-hand gap is wider than "a filter or merge driver": merge.verifySignatures with gpg.program (executed), diff drivers, includes, grafts, info/attributes and alternates.
- **Claim 6** (`SKILL.md:48-50`): "nothing a build loop edits runs as the gate" overstates; the snippet header's Q-140 gap (a moved main or a rewritten .git entry) applies.
- **Claim 8** (`SKILL.md:51-54`): exit 2 also carries `--main-log`'s `other` lines (executed: rc=2, no refuse line) and `--check`'s verdicts, not only refuse lines.
- **Claim 9** (`SKILL.md:54-57` vs `:216-219`): `--state` exit 1 goes to a `you: judgment` entry in step 0.1 but to an `agent` entry under the Rule. Pick one.
- **Claim 10b** (`SKILL.md:68-70`): hg does run gpg.program when `.git/config` sets merge.verifySignatures (executed). Narrow the text to "commit signing", or add verification to the list of things only `--state` refuses.

### Unverifiable
- None.

## Escalations

- **security-reviewer:** claim 21b. A stopped health check can still take the lock later and run repo test code; a hung holder then blocks the next gate. Also claim 10b and claim 5: merge.verifySignatures with gpg.program runs a planted program under hg when `--state` is skipped (the by-hand fallback) or raced.
- **api-consistency-reviewer:** claim 9 (two routes for one stop) and claim 8 (the exit-2 definition is narrower than the header's Exit paragraph).
- **performance-reviewer:** claim 21b. The orphaned `flock` runs a full fast and slow suite in WT after the hour bound.

## Goal-Alignment Note

The brief's goal is to land U4b1 after a clean review-fix loop. What U4b1 most needs to be true holds and was executed:
- commit.gpgSign=false is in the lib, the snippet and hg, pinned by a test that fails on six mutants.
- hg commits and merges run no gpg against planted signing config.
- Env identity beats planted author/committer keys.
- The `--check-fix` paragraph is exact for all five path kinds.
- Step 0's `--state` and `--main-log` behaviour, the bootstrap included, matches the script.
- 288 suite tests pass and shellcheck is clean.

One behavioural defect remains in SKILL.md text this unit wrote (claim 21b): the hour-bound stop of the health check does not do what its parenthetical promises, so an orchestrator following it gets a late full health-check run holding the lock. Four wording imprecisions remain (claims 5, 8, 9, 10b), each a one-sentence fix in place. Claim 9 is a direct contradiction between two rules on the same event. Nothing here needs script code, and none of it falls under U4b2's override row.
