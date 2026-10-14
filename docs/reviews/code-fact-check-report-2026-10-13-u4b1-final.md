Commit: 4c911717

# Code Fact-Check Report

**Commit:** 4c911717
**Replication:** k=3
**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u4b1`, branch `feat/build-loop-u4b1`)
**Scope:** branch diff `git diff main...HEAD` at 4c911717 (commits 458dc170, 0cd86cc0, 4c911717) and their commit messages; final confirming pass, merged from `code-fact-check-report-2026-10-13-u4b1-final-r{1,2,3}.md` (r1 29, r2 30, r3 31 claim sections), clustered by file, line range (±5) and substance, at the finest granularity any replicate used (decision 033).
**Checked:** 2026-10-13
**Total claims checked:** 37
**Summary:** 25 verified, 8 mostly accurate, 1 stale, 3 incorrect, 0 unverifiable

Merge: most-severe-wins on the verdict, evidence carried from the winning replicate (ties broken by the most specific `Scope:` line, then lowest replicate number), annotations merged by union. Orchestrator collation only: no claim, verdict or evidence was added. Execution logs and probe scripts are those cited by each replicate (`docs/reviews/execution-logs/u4b1-final-r1-fc-*.log`, `u4b1-final-r3-fc-*.log`; r2's under the session scratchpad `fc2/`).

Two cluster-membership notes. r2's Claim 6 quotes the whole `SKILL.md:68-70` sentence, but its Scope ("Covers signing and signature verification on `hg merge`") and its text ("the sentence is right about signing") confine it to the broad-signing reading, so it clusters with Claim 13 below, and r2's Claim 5 (hg commit/merge run no gpg) carries r2's verdict on Claim 12. r2's Claim 28 names R1 and R2 of 0cd86cc0, but its Scope covers R1's commit-signing atom only ("R2 holds: claim 9"), so it clusters with Claim 35 alone. r2's Claim 20 is a true compound over the whole `--check-fix` list, so its Mostly accurate is recorded `(compound)` on both Claims 19 and 20 and, by most-severe-wins, sets both.

---

## Claim 1: "SKILL.md is 397 lines ... U4b1, the orchestrator's frame (173 lines as written)"

**Location:** `docs/working/plan-build-loop-handoff.md:341-342`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers main's SKILL.md line count and the changed-line count at 458dc170, counted as the note counts it (added plus removed lines, in code outside `docs/`). It does not establish the branch's count at HEAD, which is now 205 lines counted the same way and still under the cap of 400.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish the count after the two fix commits (177 in SKILL.md alone on the full branch) or the 400-line cap's own rule" · r2: "does not establish the line count after the review fixes (148+29 in SKILL.md at HEAD, plus 16 in other code files)" · r3: "at HEAD ... 205 lines counted the same way and still under the cap of 400"

`git show main:skills/dev-cycle/SKILL.md | wc -l` → `397`. At 458dc170, `git diff --numstat main 458dc170` gives `130 29 skills/dev-cycle/SKILL.md`, `7 5 test/scripts/build-loop-orchestrator.bats` and `1 1 workflows/pr-prep.md`, which sum to 173 (r3).

**Evidence:** `docs/working/plan-build-loop-handoff.md:341-342`; `git diff --numstat` output quoted inline in r1, r2 and r3

---

## Claim 2: "(the lib's HARDEN list: ... log.showSignature, commit.gpgSign; a git -c pair would win over it), whatever the value"

**Location:** `scripts/build-loop.sh:133-140`; commit 4c911717 body (B1: `--state` never refused a repo-planted `commit.gpgSign`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers `--state`'s caller gate refusing a caller `commit.gpgSign` pair by `git -c` (GIT_CONFIG_PARAMETERS) and by GIT_CONFIG_COUNT, value true or false; does not establish the other gated modes (only `--state` runs caller_gate: `scripts/build-loop.sh:711`).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish `--main-log`'s or other modes' handling of caller pairs (they skip the caller check by design: p5 shows `--main-log` exit 0 with the same pair)" · r2+r3: a `commit.gpgSign true` planted in the repo's `.git/config` gets `ok`, exit 0 (`STATE_KEYS_RE`, `scripts/build-loop.sh:612`, has no `commit.` key), confirming B1's premise; "hg's own pair overrides it there" (r3)

```bash
# scripts/build-loop.sh:668-669 (enclosing caller_gate() :660-674 — read)
    for kv in "${HARDEN[@]}"; do kv="${kv%%=*}"; [[ "$k" != "${kv,,}" ]] || k+=" "; done  # a trailing blank marks a HARDEN key
    if [[ "$k" == *" " || "$k" =~ $STATE_KEYS_RE ]]; then
```

Run in a clone: `env GIT_CONFIG_PARAMETERS="'commit.gpgsign'='true'" bash build-loop.sh --state` and `env GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=commit.gpgSign GIT_CONFIG_VALUE_0=false bash build-loop.sh --state` each printed `refuse state commit.gpgsign: set by the caller's git -c or GIT_CONFIG_COUNT pairs, ...` and exit 2; the plain run printed `ok`, exit 0 (r1).

**Evidence:** `scripts/build-loop.sh:135-140`, `scripts/build-loop.sh:660-674`, `scripts/lib/dev-cycle-read.sh:354`; `docs/reviews/execution-logs/u4b1-final-r1-fc-state.log`

---

## Claim 3: "and no commit signing (commit.gpgSign runs gpg.program on a commit or merge: the orchestrator's own commits, SKILL.md's hg ...)" and HARDEN gaining `commit.gpgSign=false`

**Location:** `scripts/lib/dev-cycle-read.sh:341-343, 354`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers a planted `commit.gpgSign=true`, `user.signingKey` and `gpg.program` in `.git/config`: plain git runs the program on commit, `hg` runs it on neither a commit nor a non-fast-forward merge; does not establish `tag.gpgSign` paths (the orchestrator makes no tags) or `git merge -S` given explicitly.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish behaviour for `tag.gpgSign` or `rebase`/`am` signing paths (the orchestrator runs none)" · r3: "It does not establish that HARDEN switches off every gpg.program route: claim 10b shows `merge.verifySignatures` still runs it, and only `--state` refuses that" (see Claim 13)

Control: `git commit` printed `error: gpg failed to sign the data`, exit 128, and the fake gpg wrote its marker. With SKILL.md's `hg` line (byte-compared to `skills/dev-cycle/SKILL.md:65`, `cmp` equal): `hg commit` exit 0, `hg merge -q --no-edit side` exit 0, `%G?` = `N` on all three commits, marker empty: "hg: gpg did not run" (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:338-354`, `skills/dev-cycle/SKILL.md:65`; `docs/reviews/execution-logs/u4b1-final-r1-fc-gpg.log`

---

## Claim 4: "the git_harden test also pins SKILL.md's hg line to the lib's HARDEN pairs and the snippet's environment (both mutants fail it)"

**Location:** `test/scripts/build-loop-orchestrator.bats:355-372`; commit 458dc170 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the test failing on six mutants (SKILL hg without commit.gpgSign, hg without GIT_NO_REPLACE_OBJECTS, snippet G without commit.gpgSign, lib HARDEN without it, a second hg line, two pairs swapped) and passing at HEAD; does not establish that the test notices an extra argument added after `"$@"` or a changed `bash -s <<'G'` wrapper text (it greps only the one-line `hg() { env ... "$@"; }` shape).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: "does not establish the exact two mutants the author ran"; r2's run used five mutants (incl. hg without `GIT_OPTIONAL_LOCKS=0`) · r3: "does not establish pinning of tokens other than `-c` pairs and `GIT_*=` variables beyond the one-line shape (the i1 C4 Won't-Fix)"

```bash
# test/scripts/build-loop-orchestrator.bats:367-371 (excerpt ends :371; enclosing @test continues to :372 — read)
    [ "$(grep -c '^  hg() { env .* "\$@"; }$' "$REPO_ROOT/skills/dev-cycle/SKILL.md")" -eq 1 ] || { grep -n 'hg()' "$REPO_ROOT/skills/dev-cycle/SKILL.md"; return 1; }
```

Each mutant run in a clone at 4c911717 (`bats -f 'git_harden exports HARDEN'`): baseline `ok 1`, exit 0; M1-M6 each `not ok 1`, exit 1 (r1).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:355-372`; `docs/reviews/execution-logs/u4b1-final-r1-fc-mutants.log`

---

## Claim 5: by-hand fallback: "every `dev-cycle.sh` call ... as `~/.claude/scripts/dev-cycle.sh`; WT made as step 0.3 says, from the default branch's commit (`hg -C MAIN_WT rev-parse --verify refs/heads/main`, or master); the Rules' `hg` for every git command"

**Location:** `skills/dev-cycle/SKILL.md:19-24`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers the rev-parse and the step 0.3 worktree add working with `hg` from a main checkout, and the fallback naming every dev-cycle.sh call; does not establish the step texts that still say "through the D6 block" (`SKILL.md:127-128`, `:236`), which the fallback overrides only by precedence of reading.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: `~/.claude/scripts -> /opt/claude-workflows/scripts`, root-owned `dev-cycle.sh`; "The symlink route is override row 2026-10-13 `feat/build-loop-u4b1` (Q-103 class), not re-flagged" · r3: "does not establish ... whether `~/.claude/scripts` is trustworthy (override row, Q-103 class)"

Executed: `MAIN="$(hg -C "$MAIN_WT" rev-parse --verify refs/heads/main)"` printed `596966f0...`; `hg -C "$MAIN_WT" worktree add -q -b chore/dev-cycle-2026-10-13-2231 "$WT" "$MAIN"` exit 0, branch `chore/dev-cycle-2026-10-13-2231` (r1).

**Evidence:** `skills/dev-cycle/SKILL.md:19-26`, `:232-235`; `docs/reviews/execution-logs/u4b1-final-r1-fc-worktree.log`

---

## Claim 6: "With no `--state` run, nothing refuses the repository config `hg` cannot switch off (a filter or merge driver): the by-hand cycle carries that gap."

**Location:** `skills/dev-cycle/SKILL.md:25-26`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers the named config gap being real (`--state` is what refuses filters and merge drivers) and the gap being wider; does not establish which of the extra classes matter for the by-hand steps beyond ancestry checks.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r1: grafts executed: with `info/grafts` planted, `hg rev-list --count HEAD` fell from 3 to 1 and `hg merge-base --is-ancestor` flipped; shallow, alternates, include and diff config also go unrefused · r2: "does not establish that the gap is fully enumerated (the parenthetical gives examples: claim 6's `merge.verifySignatures`, `diff.external` are in the same class)" · r3: `merge.verifySignatures` with `gpg.program` made hg's merge run the planted program (probe5, `rc=128 gpgran=yes`); info/attributes can name a built-in merge or diff driver; precise version "nothing refuses repository state hg cannot switch off (filters, merge and diff drivers, merge.verifySignatures with gpg.program, includes, grafts, info/attributes, alternates)" · r1+r3 (escalation): route to security-reviewer (see Escalations)

`--state` refuses `filter.x.clean` and `merge.y.driver` (state log, exit 2), and `hg` sets no filter or merge override (`SKILL.md:65`). But the by-hand cycle also runs neither `--state` nor the D6 snippet, and both are what refuse `.git` state that is not config: `info/grafts` (`test/lib/d6-snippet.bash:54-55`; state gate `scripts/build-loop.sh:276-279`), shallow, alternates, and config `--state` refuses that `hg` does not override (include, diff drivers: `STATE_KEYS_RE`, `scripts/build-loop.sh:612`). Precise version: "nothing refuses the `.git` state `hg` does not switch off (a filter, merge driver or include in config; grafts, shallow or alternates)" (r1).

**Evidence:** `skills/dev-cycle/SKILL.md:25-26`, `scripts/build-loop.sh:274-281`, `scripts/build-loop.sh:612`, `test/lib/d6-snippet.bash:52-55`; `docs/reviews/execution-logs/u4b1-final-r1-fc-graft.log`, `docs/reviews/execution-logs/u4b1-final-r3-fc-verifysig.log`

---

## Claim 7: "In claude-workflows it runs main's own committed scripts, elsewhere the root-owned image copy, so nothing a build loop edits runs as the gate."

**Location:** `skills/dev-cycle/SKILL.md:48-50`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers which copy the snippet runs, per its header and code. It does not establish the conclusion "nothing a build loop edits runs as the gate", which the snippet's own header contradicts for a loop that moves main or rewrites `.git` (Q-140, the reason the block is pending).
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=Mostly accurate
**Replicate annotations:** r1: "does not establish the Q-140 gap the snippet header names (a moved main onto a copy of D6_ROOT in another project), which SKILL.md leaves to its pending section" · r3: "The block is pending, so no orchestrator runs it today"

The snippet header says: "Known gap (final security F1, Q-140): the choice of main's copy rests on the repository's own data, so in another project a loop that moves main onto a copy of D6_ROOT, or rewrites the .git entry, gets that project's scripts run instead of the image copy" (`test/lib/d6-snippet.bash:25-28`). It also says "It trusts refs/heads/main and that entry" (`:24`). The mechanism is right. The absolute conclusion should carry "(but Q-140's gap)" (r3).

**Evidence:** `test/lib/d6-snippet.bash:11-40, 75-95`

---

## Claim 8: "`refuse d6: WHY` (exit 2) means nothing ran."

**Location:** `skills/dev-cycle/SKILL.md:50-51`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers every `refuse d6:` path in the snippet. It does not establish that a script's own exit 2 (no `refuse d6:` line) means nothing ran.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: "does not establish the snippet's runtime (exercised by the orchestrator suite's d6 tests in p4, not re-probed)"

`no() { echo "refuse d6: $*"; exit 2; }` (`test/lib/d6-snippet.bash:44`). Every `no` call comes before the line `env -u BASH_ENV -u ENV -u DEV_CYCLE_SCRUBBED bash "$d/scripts/$s" "$@"` (`:95`), the only line that runs a script. The header agrees: "2 and one "refuse d6: WHY" line on stdout, with nothing run" (`:30-31`) (r3).

**Evidence:** `test/lib/d6-snippet.bash:41-97`

---

## Claim 9: "A `build-loop.sh` answer is exit 0, or exit 2 with the mode's own refuse lines; any other exit (1 included), or a call the Bash tool timed out, means nothing was decided"

**Location:** `skills/dev-cycle/SKILL.md:51-54`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers `--state` and `--main-log` (steps 0-1) against the header's Exit paragraph; does not establish `--check`/`--merge`/`--start` (U4b2's steps), whose exit 2 also carries `skip` and `deny` lines rather than only refuse lines.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2+r3: step 0.2 handles `other` lines explicitly, so an orchestrator reading both is not misled · r2: precise version "exit 0, or exit 2 with the mode's documented lines (refuse lines, `--main-log`'s `other`, a non-ok verdict)" · r3: a bootstrap `refuse main-log:` exits 2; a short SINCE exits 1 (usage); escalation to api-consistency-reviewer (exit-2 definition narrower than the header's Exit paragraph)

The header's Exit paragraph: "2 any other --check, --merge, --start or --prompt verdict line, --main-log's other or refuse line, a --cycle-diff refuse line, or the state gate (--state's included) not ok" (`scripts/build-loop.sh:513-516`). Executed: `--main-log` from three commits back printed `main 596966f0... 3` and three `other ...` lines and no refuse line, exit 2. Precise version: "exit 2 with the mode's own lines (--main-log's `other`, a refuse line)" (r1).

**Evidence:** `scripts/build-loop.sh:510-521`, `skills/dev-cycle/SKILL.md:51-57`, `:220-231`; `docs/reviews/execution-logs/u4b1-final-r1-fc-state.log`

---

## Claim 10: Rules "the line and stderr go in one `agent` entry" vs step 0.1 "refuse lines ... are a stop, quoted in one `you: judgment` entry ...; so is an exit 1, with its stderr"

**Location:** `skills/dev-cycle/SKILL.md:51-57`, `skills/dev-cycle/SKILL.md:211-219`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers the routing of a `--state` exit 1 between the D6 Rule and step 0.1; does not establish the `refuse state` route (only step 0.1 names one for it, so no conflict there).
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Mostly accurate
**Replicate annotations:** r1: "This is item 10 of the brief (a contradiction this unit leaves), not listed in the U4b2 override row" · r2: "does not establish which route is intended (the text gives both)"; "i2's api-consistency finding 4 noted routes differing by cause as defensible; this is one cause given two routes"; fix: drop "so is an exit 1" in step 0.1, or make the Rule say "unless the step names its own entry" · r3 (Medium): "Both say stop with no record, so the iteration's outcome is the same. The entry's `Needs:` route differs, and a judgment entry spends the user's attention"; "unit-introduced: the Rule's agent routing was added in 4c911717" · r1+r2+r3 (escalation): api-consistency-reviewer

The D6 Rule says an exit 1 is a stop whose "line and stderr go in one `agent` entry and the final message (a full disk reads like planted state, so it is not called hostile)" (`SKILL.md:52-57`); step 0.1 routes the same `--state` exit 1 to "one `you: judgment` entry" (`SKILL.md:218-219`). `--state`'s exit 1 cases are environmental or caller-side (`scripts/build-loop.sh:122-125`, `:517-520`) — the row-742 class the Rule routes to `agent`. An orchestrator meets two different instructions for one event (r1).

**Evidence:** `skills/dev-cycle/SKILL.md:51-57`, `:214-219`; `scripts/build-loop.sh:120-125`, `:510-521`

---

## Claim 11: Rules: the orchestrator's own git commands "run in a `bash -s <<'G'` script that starts with this line, never as bare `git` in its shell" vs step 6's "`git mv` the brief there"

**Location:** `skills/dev-cycle/SKILL.md:59-62`, `skills/dev-cycle/SKILL.md:409`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers bare-git mentions left in SKILL.md after U4b1; does not establish whether U4b2's step 6 rewrite (plan split note) already plans to change it.
**Replicate verdicts:** r1=— · r2=Stale · r3=— · single-replicate detection
**Replicate annotations:** r2: "Line 43's 'never `git add -A`' is a prohibition, not a command, and line 78's `git config --global` is the Rule's own named exception"; "30 could equally go on the U4b2 override row" (escalation: orchestrator)

`create docs/working/briefs/closed/ if it is missing, `git mv` the brief there` (`skills/dev-cycle/SKILL.md:409`) is an orchestrator git command written as bare `git`, which the new Rule forbids; the U4b2 override row's list does not name it, though the plan gives step 6 to U4b2 (r2).

**Evidence:** `skills/dev-cycle/SKILL.md:43`, `skills/dev-cycle/SKILL.md:59-80`, `skills/dev-cycle/SKILL.md:409`, `docs/reviews/override-log.md:777`

---

## Claim 12: "`hg` reads no global or system config and runs no hook, fsmonitor command, signing program [on commit or merge] or replaced object; a test holds its pairs to the lib's `HARDEN` list."

**Location:** `skills/dev-cycle/SKILL.md:65, 68-70`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers a `.git/hooks/pre-commit` file (control: plain git ran it; hg did not), commit signing and the test pin; does not establish config-based hooks (`hook.*`, absent from git 2.39.5 here; `--state` refuses `hook.` keys) or grafts, which `hg` honours (Claim 6) — the sentence does not claim grafts.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish signature *verification* paths" (see Claim 13) · r3: "the hg line in SKILL.md is byte-identical to the one probed"; "It does not establish signature verification on merge (claim 10b)"

Executed: plain `git commit` printed `filehook`; `hg commit` gave "hg ran no hook". `hg` carries `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_NO_REPLACE_OBJECTS=1 ... -c core.hooksPath=/dev/null -c core.fsmonitor=false ... -c commit.gpgSign=false` (`SKILL.md:65`). With commit.gpgSign and user.signingKey planted, `hg commit` and `hg merge` ran no gpg (r1 Claim 3, r2 Claim 5, r3 Claim 10a).

**Evidence:** `skills/dev-cycle/SKILL.md:65-70`; `docs/reviews/execution-logs/u4b1-final-r1-fc-hook.log`, `docs/reviews/execution-logs/u4b1-final-r1-fc-gpg.log`

---

## Claim 13: "runs no ... signing program" (read broadly: no gpg.program run)

**Location:** `skills/dev-cycle/SKILL.md:68-70`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers signing and signature verification on `hg merge`; does not establish every other config-named program (diff.external, core.pager on a tty), which the Rule's next sentence leaves to `--state`.
**Replicate verdicts:** r1=Verified (compound) · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r3: "It does not establish whether a hostile loop can make main's tip carry a signature header in practice; the probe forged one"; "The case belongs in the 'does not switch off' list, which names only 'a filter, a merge driver' (`:71`)"; precise version "runs no ... commit signing" · r2+r3: `--state` refuses both keys (`merge.verifysignatures`, `gpg.program`), so the next sentence's re-run covers it · r2+r3 (escalation): security-reviewer

hg switches signing off, but `gpg.program` still runs under hg when the repository's config sets `merge.verifySignatures true` and the merged branch has a commit with a `gpgsig` header: p2 printed `fatal: Commit 3a9d42c does not have a GPG signature.` and the fake program logged `gpg ran: --keyid-format=long --status-fd=1 --verify ...`. The program is not run for *signing*, so the sentence is right about signing, but a reader may take "runs no signing program" as "gpg.program never runs". Precise version: "... and signs nothing (a planted `merge.verifySignatures` can still run `gpg.program`: `--state` refuses it)" (r2).

**Evidence:** `skills/dev-cycle/SKILL.md:68-72`, `scripts/build-loop.sh:612`; r2 `<scratch>/fc2/p2-verify.txt`; `docs/reviews/execution-logs/u4b1-final-r3-fc-verifysig.log`

---

## Claim 14: "It does not switch off what the repository's own config can still name (a filter, a merge driver): `--state` refuses those, but only when it runs"

**Location:** `skills/dev-cycle/SKILL.md:70-74`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers `--state` refusing a planted filter and merge driver (exit 2) and passing a planted `commit.gpgSign`/`user.signingKey`/`author.name` (exit 0, which HARDEN or the command-line identity now cover); does not establish the race between the re-run and the commit (named as Q-103's residual).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: the state gate's key set is read "in both the common config and config.worktree" (`scripts/build-loop.sh:615-616`) · r3: "or the wider list in claims 5 and 10b" (see Claims 6 and 13)

State log: `refuse state filter.x.clean: set in config, ...` exit 2; `refuse state merge.y.driver: ...` exit 2; repo `commit.gpgSign`+`user.signingKey`: `ok` exit 0; repo `author.name`: `ok` exit 0 (r1).

**Evidence:** `scripts/build-loop.sh:605-612`; `docs/reviews/execution-logs/u4b1-final-r1-fc-state.log`

---

## Claim 15: "Commits set their identity on the command, as `GIT_AUTHOR_NAME`, ... (these outrank a planted `author.*` or `committer.*` key)"

**Location:** `skills/dev-cycle/SKILL.md:75-79`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers env identity against planted `author.*`, `committer.*` and `user.*` in `.git/config`, on a commit and on a merge (git 2.39.5). It does not establish anything about the global-config read (`git config --global --get user.name`), which reads the loop-writable `~/.gitconfig` by design.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: the fallback `git config --global` read is not established as trusted (a loop can write `~/.gitconfig`) · r1: control: without the env vars, the planted keys win

Probe1 planted `author.name EVILA`, `committer.name EVILC` and `user.name EVILU`. With the four `GIT_*` variables on the command, `HG commit ident: Good <good@x> / GoodC <goodc@x>` and `HG merge ident: Good <good@x> / GoodC <goodc@x>` (r3).

**Evidence:** `skills/dev-cycle/SKILL.md:75-80`; `docs/reviews/execution-logs/u4b1-final-r3-fc-probe1.log`

---

## Claim 16: "Never export these settings: set them per command, as `hg` does (`--state` refuses a caller's config pair for a `HARDEN` key, row 702)."

**Location:** `skills/dev-cycle/SKILL.md:79-80`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers caller pairs (now including commit.gpgSign); does not establish that exported variables like `GIT_CONFIG_GLOBAL` are refused (they are not: `stray_vars` lists only `git rev-parse --local-env-vars`, `scripts/build-loop.sh:645`), which is 0cd86cc0's R2 wording.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish exported environment variables such as `GIT_NO_REPLACE_OBJECTS`, which caller_gate explicitly sets aside" · r3: hg's exported variables give `ok`, rc=0; "It does not establish that exported variables are harmless to other tools"

```bash
    for kv in "${HARDEN[@]}"; do kv="${kv%%=*}"; [[ "$k" != "${kv,,}" ]] || k+=" "; done  # a trailing blank marks a HARDEN key
```
(`scripts/build-loop.sh:668`; excerpt ends :668; enclosing `caller_gate` continues to :674 — read) (r2).

**Evidence:** `scripts/build-loop.sh:645`, `scripts/build-loop.sh:660-674`, r2 `<scratch>/fc2/p5-modes.txt`

---

## Claim 17: settings lines "read only through `build-loop.sh --settings`, from the default branch's commit ... A malformed never line turns self-merge off." Slots "1-9; else 3"

**Location:** `skills/dev-cycle/SKILL.md:111-116`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers the header's contract for policy, slots, never, readers; does not establish the parser against the header (U3's tests own that).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: parser "exercised by the read/check suites in p4" · r3: "does not establish the parser's behaviour on each malformed form"

Header: "five lines from the default branch's commit, never the working tree"; "Loops at once: "Build-loop slots: N", N from 1 to 9; else 3."; "Malformed (or a file not read) turns self-merge off." (`scripts/build-loop.sh:18-39`) (r1).

**Evidence:** `scripts/build-loop.sh:18-61`

---

## Claim 18: "Every loop prompt quotes it [constraints.md], and every design choice a loop makes runs divergent design seeded with it (D2) ... The orchestrator dispatches only while `--settings` prints `constraints ok`."

**Location:** `skills/dev-cycle/SKILL.md:119-122`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers loop_prompt's quote and DD line and the header's dispatch rule; does not establish that `--start` reads the same constraints line at its own time (its header says it does: `:465-467`).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish that a loop obeys the prompt"; dispatch refusal at `scripts/build-loop.sh:1637` · r3: "does not establish D2's 'files one `you: judgment` entry' when the file is missing, which the paragraph does not claim"

```bash
# scripts/build-loop.sh:1681,1687 (enclosing loop_prompt() :1675-1696 — read)
The project's constraints (docs/constraints.md at $MAIN_SHA), quoted:
Run every design choice through divergent design seeded with these constraints and your brief's own. One option dominates (Path A): decide and continue. ...
```

Header: "Only "ok" lets the orchestrator dispatch." (`scripts/build-loop.sh:49`) (r1).

**Evidence:** `scripts/build-loop.sh:40-49`, `scripts/build-loop.sh:1675-1696`

---

## Claim 19: "the cycle rules `build-loop.sh --cycle-diff` applies ... repeat only part of `--check-fix` (a `.md` under `docs/working/` or `docs/reviews/`, a doc an instruction file imports, ... and a symlink pass them)"

**Location:** `skills/dev-cycle/SKILL.md:140-145`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers `--cycle-diff` and `--check-fix` on each named class plus a plain new `docs/*.md` in a clone on `chore/dev-cycle-2026-10-13-1200`; does not establish `--land-cycle`'s run of the same `cycle_rules` (same function, not executed).
**Replicate verdicts:** r1=Verified · r2=Mostly accurate (compound) · r3=Verified (compound)
**Replicate annotations:** r1: "Covers four of the five named classes passing `--cycle-diff` (ok, exit 0) while `--check-fix` skips each; does not establish other `--check-fix` refusals outside the list" · r2: "Every named case holds"; its Mostly accurate is on the list's new-file qualifier (Claim 20) · r3: `--check-fix` run before staging, as the paragraph orders; "does not establish that the list is exhaustive"

p6: `--check-fix` printed `skip` for all six (`docs/working/scratch-note.md`, `docs/reviews/new-review.md`: "in-cycle fixes edit only tracked .md documentation ..."; `docs/imp.md`: "an instruction file names it after an @"; `docs/link.md`: "reached through a symlink"; `docs/claude.md/new.md` and `docs/plain-new.md`: "no tracked file ... matches"), and `--cycle-diff` printed `ok`, exit 0, for each staged alone. Every named case holds. The list's qualifier is narrower than the code: any new `.md` under docs/ passes the cycle rules (`scripts/build-loop.sh:1938`) and `--check-fix` refuses it (`scripts/dev-cycle.sh:197`), not only one under an instruction-file-named directory (r2).

**Evidence:** `scripts/build-loop.sh:1916-1940`, `scripts/dev-cycle.sh:184-198`; `docs/reviews/execution-logs/u4b1-final-r1-fc-checkfix.log`, r2 `<scratch>/fc2/p6-checkfix.txt`

---

## Claim 20: "... a new file below a directory named like an instruction file ... pass them"

**Location:** `skills/dev-cycle/SKILL.md:144-145`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers what `--check-fix` does with paths below `docs/agents.md/` and `docs/gemini.md/`; does not establish the floor's "below" class (S rules), which does refuse them.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate (compound) · r3=Verified (compound)
**Replicate annotations:** r1: "The order the paragraph already prescribes ('right before staging it') is what makes the refusal hold" · r2: "The paragraph's earlier 'anything else (a new file, ...) is filed, not written' (`SKILL.md:139-140`) already rules new files out, so a reader is not misled into staging one"; precise version "a new file (one below a directory named like an instruction file among them)" · r3: "A tracked `docs/claude.md/tracked.md` gets `ok` from `--check-fix`, which is why the text says 'new' (B10)"

Such a file passes the cycle rules (`--cycle-diff` ok with `docs/agents.md/new.md` staged) and `--check-fix` refuses it before staging, but only as untracked (`skip docs/agents.md/new.md: no tracked file (or ignored file under docs/working/) matches`), the same as any new file. The directory name plays no part: a tracked `docs/agents.md/old.md` got `ok` from `--check-fix` and passes the cycle rules; and once staged, `--check-fix` printed `ok docs/agents.md/new.md` and `ok docs/gemini.md/unstaged.md`. Precise version: "a new file (any; `--check-fix` takes only tracked files, so run it before staging)" (r1).

**Evidence:** `skills/dev-cycle/SKILL.md:134-145`; `docs/reviews/execution-logs/u4b1-final-r1-fc-checkfix.log`

---

## Claim 21: D6 block section: "It refuses (`refuse d6: WHY`, exit 2, nothing run) a replace ref, grafts, a default branch that is not exactly one plain main or master naming a commit, an object it cannot read whole or that does not hash to its id, and more"

**Location:** `skills/dev-cycle/SKILL.md:182-191`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers the listed refusals against the snippet's code and header; does not establish the byte-equality test (pending, U4c).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: "does not establish the snippet's runtime (exercised by the orchestrator suite's d6 tests in p4, not re-probed)" · r3: names T33's equality test as pending; the hash refusal is the perl reader's `die "$id does not hash to its id\n"` (`:70`) → `no ...` (`:86`)

```bash
# test/lib/d6-snippet.bash:53,55,57-59 (enclosing d6() :41-end — read)
  [[ -z "$x" ]] || no "a replace ref exists (F38)"
  [[ ! -e "$x" && ! -L "$x" ]] || no "info/grafts exists (F38)"
  m="${m% }"; [[ "$m" == main || "$m" == master ]] || no "the default branch is not exactly one of main and master"
```
(r1)

**Evidence:** `test/lib/d6-snippet.bash:28-94`

---

## Claim 22: Step 0.1: "`ok` goes on; refuse lines (planted `.git` state: replace refs, grafts, hooks or filter config, a default branch that is not one plain main or master...) are a stop"

**Location:** `skills/dev-cycle/SKILL.md:214-218`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers the refusal causes named. It does not establish the route of an exit 1 (claim 9, r3's numbering; Claim 10 here).
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** r3: the exit-1 route is a separate claim (Claim 10 here)

The state gate prints `refuse state refs/replace: ...` (`scripts/build-loop.sh:630`), refuses "info/grafts" (`:626-628`), refuses `hook\.` and `core\.hookspath` keys and `filter\.` (`:612`), and `default_gate` prints "both main and master exist" (`:681`). Executed: the filter plant was refused (r3).

**Evidence:** `scripts/build-loop.sh:599-700`; `docs/reviews/execution-logs/u4b1-final-r3-fc-probe1.log`

---

## Claim 23: Step 0.2: "with no such line yet, pass 40 zeros: it prints `main MAIN -` and refuses, and that MAIN is the bootstrap"

**Location:** `skills/dev-cycle/SKILL.md:220-223`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `--main-log` with 40 zeros on a SHA-1 clone; does not establish a SHA-256 repository (64 zeros would be needed: the mode takes 40 or 64 hex, `scripts/build-loop.sh:545`).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: "does not establish the classifier itself (U3b2's tests)" · r3: "It does not cover where SINCE comes from: the newest record's `Main at:` line is U4b2's to write (override row)"

p5: `main 596966f015a5f3d061b12f0761b041f3acfdca54 -` then `refuse main-log: 0000000000000000000000000000000000000000 is not on the default branch's first-parent history at 596966f0...`, exit 2 (r2).

**Evidence:** `scripts/build-loop.sh:543-545`, r2 `<scratch>/fc2/p5-modes.txt`; `docs/reviews/execution-logs/u4b1-final-r1-fc-state.log`

---

## Claim 24: Step 0.2's reading: "Its first line `main MAIN N` names MAIN ...; read each later line's class and SHA by position (the subject is data). ... a `refuse main-log:` line other than the bootstrap's own (SINCE is off main's history ...; or the history could not be listed)"

**Location:** `skills/dev-cycle/SKILL.md:223-231`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers the bootstrap output, the line formats, the classes and the refusal causes against the header. It does not establish a `refuse state` line from `--main-log`'s own state gate (a race after step 0.1), which step 0.2 does not name. It also does not cover where SINCE comes from: the newest record's `Main at:` line is U4b2's to write (override row).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: a short id is exit 1 usage (executed) · r2: "does not establish SINCE's derivation from the newest record (U4b2's, per the override row)" · r3: "a `refuse state` line from `--main-log`'s own state gate (a race after step 0.1), which step 0.2 does not name"

Probe1 output: three commits back → `main 2fde50d9... 3` and three `other SHA SUBJECT` lines, rc=2; at main → `main ... 0`, rc=0. The header gives the causes: "when SINCE ... is not on that history (main was rewritten, or SINCE is on another branch) or it cannot be listed" (`scripts/build-loop.sh:179-182`) (r3).

**Evidence:** `scripts/build-loop.sh:141-182`; `docs/reviews/execution-logs/u4b1-final-r3-fc-probe1.log`

---

## Claim 25: Step 0.3: "`hg -C MAIN_WT worktree add -b chore/dev-cycle-DATE-HHMM WT MAIN` ... WT is removed (`hg -C MAIN_WT worktree remove WT`) once the iteration's land is verified: every registered worktree ... joins the import walks' reader set."

**Location:** `skills/dev-cycle/SKILL.md:232-235`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers the commands as written under `hg` and prune keeping a locked worktree whose directory is gone (removing an unlocked one); does not establish that `--start`'s lock reason survives prune (lock file kept, so it does by construction) or that `worktree remove` succeeds with untracked files in WT (it refuses without --force).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r2: branch name matches `--main-log`'s/`--land-cycle`'s pattern (`scripts/build-loop.sh:162-164`); "does not establish the removal step itself (U4b2's, per the override row)" · r3: "does not establish ... when the land is verified (U4b2's step)"; the walks read the worktree registry (`scripts/lib/dev-cycle-read.sh:49`)

Executed: add exit 0 on `chore/dev-cycle-2026-10-13-2231`; `worktree remove "$WT"` exit 0 (r1).

**Evidence:** `skills/dev-cycle/SKILL.md:232-235`; `docs/reviews/execution-logs/u4b1-final-r1-fc-worktree.log`

---

## Claim 26: Step 1: "It takes a lock in the git common directory, so it waits while a loop's gate runs (it says so once)"

**Location:** `skills/dev-cycle/SKILL.md:264-265`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers take_lock's lock location, wait and single message; does not establish anything about `build-loop.sh`, which takes no health-check lock.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish that loops' gates use the same file (they run the same script from their worktrees, which share the common dir)" · r3: "does not establish anything about a loop's own gate, beyond D14's statement that the loop runs the same health check"; the simulation printed the message once

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

It waits only for another health-check run (a loop's pr-prep gate). SKILL.md's own intro calls `scripts/build-loop.sh` "the gate" (`SKILL.md:15-16`), and a loop's `build-loop.sh --check` takes no such lock. Precise version: "it waits while another health check (a loop's pr-prep gate) runs" (r1).

**Evidence:** `scripts/health-check.sh:1096-1123`, `skills/dev-cycle/SKILL.md:15-16`

---

## Claim 27: Step 1: "a wait past an hour is recorded, the run is stopped by its PID (it would still take the lock later), and the step's check is skipped (row 750)"; commit 4c911717 "B8: ... an abandoned health check is stopped by its PID"

**Location:** `skills/dev-cycle/SKILL.md:266-267`; commit 4c911717 body
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers stopping the backgrounded health-check process (the PID the orchestrator's `&` gives) while it waits in `take_lock`; does not establish a process-group kill or `timeout` wrapper (neither is what the text says).
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r1 (Medium): "the probe is a mimic of take_lock's code, not the real script, hence Medium"; the late run is "concurrent with steps 2-4b's tests" · r3: "In the real script, the late run is a full fast and slow suite in WT, and it would hold the lock against the next gate"; "The stop must cover the `flock` child and its child (its process group, or the PIDs from `pgrep -P`)" · r1+r2+r3 (escalation): performance-reviewer and security-reviewer

While waiting, the health check is two processes: the script's bash, and its child `flock -o "$lk" bash .../health-check.sh` (`scripts/health-check.sh:1116`). p7 reproduced `take_lock`'s lines with the payload swapped for `echo ran-after-wait`: with the lock held by another process, `ps --ppid <run>` showed `flock -o .../health-check.lock bash -c echo ran-after-wait ...`; stopping the run's PID (`run exit 143`) left that child, which took the lock once the holder released it and ran the payload (`ran file: ran-after-wait`). So stopping "the run ... by its PID" does not prevent the thing the parenthetical says it is for: the orphaned flock still takes the lock later and runs the full health check, holding the lock the loops' gates wait on (i2 performance F2's harm). Precise version: stop the waiting `flock` child too (its PID from `pgrep -P <run PID>`), or start the run under `timeout 3600` / in its own process group and stop the group (r2).

**Evidence:** `scripts/health-check.sh:1104-1118`, r2 `<scratch>/fc2/p7-lockkill.txt`; `docs/reviews/execution-logs/u4b1-final-r1-fc-lock.log`, `docs/reviews/execution-logs/u4b1-final-r3-fc-hclock.log`

---

## Claim 28: Step 1: "`hg -C MAIN_WT worktree list` and `hg -C MAIN_WT worktree prune` (a locked worktree, a live loop's, is never pruned)"

**Location:** `skills/dev-cycle/SKILL.md:276-277`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers the commands as written under `hg` and prune keeping a locked worktree whose directory is gone (removing an unlocked one); does not establish that `--start`'s lock reason survives prune (lock file kept, so it does by construction) or that `worktree remove` succeeds with untracked files in WT (it refuses without --force).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r2 (Medium, static): "does not establish (not executed here) that a locked worktree whose directory was deleted survives prune" · r3 (Medium, static): "It does not cover a loop worktree whose lock was removed"; `--start` locks with `git worktree add -q --lock --reason` (`scripts/build-loop.sh:1662`)

Executed: after deleting both directories, `worktree prune` kept `.../lk ... [lk] locked` and dropped `ul`. `--start` locks its worktree: header `scripts/build-loop.sh:465-470` (r1).

**Evidence:** `skills/dev-cycle/SKILL.md:276-277`; `docs/reviews/execution-logs/u4b1-final-r1-fc-worktree.log`

---

## Claim 29: Step 4 drift check: "a `--merge` commit, with a `Build-loop-gate:` trailer ... the loop's research doc (`docs/working/research-STEM.md`, which the loop force-adds)"

**Location:** `skills/dev-cycle/SKILL.md:332-337`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers the trailer `--merge` writes and the loop prompt's force-add and Path A wording; does not establish that a loop obeys the prompt (a prompt, not a gate).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish that the research doc exists at a given merge (the loop may not comply)"

```bash
# scripts/build-loop.sh:1468 (enclosing gate_msg() :1467-1470 — read)
  printf "Merge branch '%s' (build-loop %s)\n\nBuild-loop-gate: %s\n" "$1" "$2" "$3"
```

The prompt: "Force-add your research doc (git add -f docs/working/research-$s.md)" (`:1688`) (r1).

**Evidence:** `scripts/build-loop.sh:1467-1470`, `:1675-1696`

---

## Claim 30: Step 4b: "a drift finding from step 4" is a trigger; the dimension "checks that `Self-merge never:` covers the paths that take effect on merge in this repo (F57)"

**Location:** `skills/dev-cycle/SKILL.md:348-357`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers agreement with the plan's step 4b note and F57 row; does not establish any code (none exists for it).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not establish what the deep-audit task itself does"

Plan: "Step 4b, deep audit: a drift finding is a trigger; the audit gains the "constraints and project guidance still match intent" dimension (it also checks that `Self-merge never:` covers paths that take effect on merge, F57)" (`docs/working/plan-build-loop-handoff.md:256`) (r1).

**Evidence:** `docs/working/plan-build-loop-handoff.md:175`, `:256`

---

## Claim 31: pr-prep: "Wait until no subagent this task started is still running; other sessions' agents and build loops share the uid and keep running (dev-cycle D14) ... stop each by its PID ..., never by a name or pattern"

**Location:** `workflows/pr-prep.md:333`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers agreement with D14; does not establish the Claim 23 defect (r1's numbering; Claim 27 here), which is in SKILL.md's health-check stop, not here (pr-prep stops leftover probes, not a lock waiter).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: the health-check stop defect (Claim 27 here) "is in SKILL.md's health-check stop, not here" · r2: "does not establish that `pgrep -a` command lines always identify the owner" · r3: "It does not establish the reaping of a process tree (see claim 21b's parent-child caveat, which applies equally here)"

D14: "The quiesce in step 1, and pr-prep's quiesce before its gate, cover only subagents this task started, and never stop or reap a process this task did not start (by PID)." (`docs/working/plan-build-loop-handoff.md:106`) (r1).

**Evidence:** `docs/working/plan-build-loop-handoff.md:106`, `workflows/pr-prep.md:333`

---

## Claim 32: "commit.gpgSign=false joins the lib's HARDEN, the D6 snippet's G and SKILL.md's hg (the pin test now counts 10 pairs)"

**Location:** commit 4c911717 message; `scripts/lib/dev-cycle-read.sh:354`, `test/lib/d6-snippet.bash:45`, `skills/dev-cycle/SKILL.md:65`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** reviewer
**Scope:** Covers the three copies carrying the pair and the test's count; does not establish anything beyond the message's wording.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: "The commit's 'counts 10 pairs' is the test's `GIT_CONFIG_COUNT=10`: the caller's one pair plus HARDEN's nine"; the test's comparison is order-sensitive, so pair order is pinned too · r3: "'10 pairs' is `GIT_CONFIG_COUNT=10`: one caller pair and HARDEN's nine (`:363`)"

The pair is in all three (`scripts/lib/dev-cycle-read.sh:354`, `test/lib/d6-snippet.bash:45`, `skills/dev-cycle/SKILL.md:65`). HARDEN holds 9 pairs; the test's 10 is GIT_CONFIG_COUNT, the caller's one pair plus HARDEN's nine:

```bash
# test/scripts/build-loop-orchestrator.bats:357,364
    run env -i PATH="$PATH" GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=user.name GIT_CONFIG_VALUE_0=c bash -c ...
    want+=$'\n'"$(printf '%s\n' $E "GIT_CONFIG_COUNT=10" "$keys" "$vals" | LC_ALL=C sort)"
```

Precise version: "HARDEN now holds 9 pairs (the test's GIT_CONFIG_COUNT is 10 with the caller's one)" (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:354`, `test/scripts/build-loop-orchestrator.bats:355-372`

---

## Claim 33: "No other HARDEN user commits with a signature (build-loop.sh's commit-tree passes --no-gpg-sign; dev-cycle.sh and the snippet never commit)"

**Location:** commit 4c911717 message; `scripts/build-loop.sh:1558`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** reviewer
**Scope:** Covers every commit-writing git call in build-loop.sh, dev-cycle.sh and d6-snippet.bash (one: commit-tree), and the six suites that exercise HARDEN's users passing with the new pair; does not establish behaviour of `questions.sh` (not a HARDEN user) or of git versions other than 2.39.5.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: "does not establish that a future caller relying on `commit.gpgSign=true` from its own git -c is unaffected (caller_gate now refuses it, by design)" · r1+r3: `--land-cycle` shares the same `commit-tree` (`:1557`); a fast-forward (`merge --ff-only`) writes no commit

```bash
# scripts/build-loop.sh:1558 (excerpt ends :1558; enclosing land() continues to its move — read)
    && x="$(gate_git commit-tree --no-gpg-sign -p "$MAIN_SHA" -p "${VERDICT[tip]}" "${VERDICT[tree]}" < "$GATE_TMP/msg")" \
```

A grep for `(g|git|gate_git) (commit|merge|commit-tree|tag|am|cherry-pick|revert|rebase)` over the three files, comments excluded, returns only that line (paraphrased — no quote available because the claim covers absence of code) (r1).

**Evidence:** `scripts/build-loop.sh:1467-1470`, `scripts/build-loop.sh:1540-1565`, `test/lib/d6-snippet.bash:41-94`; `docs/reviews/execution-logs/u4b1-final-r1-fc-suites.log`

---

## Claim 34: "Suites 288 green, run serially; shellcheck clean."

**Location:** commit 4c911717 message; `scripts/health-check.sh:480-490`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** reviewer
**Scope:** Covers the six build-loop/dev-cycle bats files (146+4+12+27+20+79 = 288 tests) and shellcheck at the health check's severity (`-S warning`) on the four changed shell files and the bats file; does not establish the full health check (other suites, install-host) or info-level shellcheck notes (174 lines of SC2015/SC2016/SC2004/SC2153 info, all excluded by the gate's `-S warning`, `scripts/health-check.sh:485`).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r3: hallucination-pattern family "wrong test-count claim in a commit message" checked; the count was executed and holds · r3: "nor shellcheck's info and style notes (present, below the warning threshold)"

`TMPDIR=<own temp> bats test/scripts/build-loop-{check,dispatch,merge,orchestrator,read}.bats test/scripts/dev-cycle.bats` in the worktree: `ok 288`, 0 `not ok`, exit 0. `shellcheck -S warning` on build-loop.sh, the lib, dev-cycle.sh and d6-snippet.bash: exit 0; `shellcheck -x -S warning` on the orchestrator bats: exit 0 (r1).

**Evidence:** `scripts/health-check.sh:480-490`; `docs/reviews/execution-logs/u4b1-final-r1-fc-suites.log`, `docs/reviews/execution-logs/u4b1-final-r1-fc-shellcheck.log`, `docs/reviews/execution-logs/u4b1-final-r3-fc-bats.log`

---

## Claim 35: commit 0cd86cc0: "R1: hg does not switch off a filter, merge driver or commit signing in the repository's own config; only --state refuses those, when it runs."

**Location:** commit 0cd86cc0 message; `scripts/build-loop.sh:612`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer (`git log` reader)
**Scope:** Covers the commit-signing atom of this historical message. It does not concern the current text: 4c911717 fixed the behaviour (B1) and its message says so. The filter and merge-driver atoms hold (claim 11, r3's numbering; Claim 14 here).
**Replicate verdicts:** r1=— · r2=Stale · r3=Incorrect
**Replicate annotations:** r2: "R1's 'commit signing' atom was true at 0cd86cc0 and is no longer"; "A commit message is history, so this needs no change; it is recorded so the merge message does not repeat it" (escalation: orchestrator) · r3: "Its successor 4c911717 records the correction ('B1: --state never refused commit.gpgSign'), so a log reader who reads both is not misled. This entry needs no action"

`--state` gave `ok` with `commit.gpgSign true` in `.git/config` (probe1, `STATE repo commit.gpgSign: rc=0 ... ok`), so it never refused commit signing. At HEAD, hg does switch signing off. The message cannot be amended without a rewrite (r3).

**Evidence:** `scripts/build-loop.sh:612`; `docs/reviews/execution-logs/u4b1-final-r3-fc-probe1.log`

---

## Claim 36: commit 0cd86cc0: "R2: --state refuses a caller's config pair, not an exported variable."

**Location:** commit 0cd86cc0 message; `scripts/build-loop.sh:660-674`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** reviewer
**Scope:** Covers R2 against caller_gate (pairs refused; `GIT_NO_REPLACE_OBJECTS`/`GIT_PREFIX` set aside); does not establish R2's broader reading for repo-local variables such as `GIT_DIR`, which caller_gate does refuse as stray variables (`scripts/build-loop.sh:662-664`) — "exported variable" must be read as an exported identity or hardening setting.
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=Verified
**Replicate annotations:** r2 (Claim 28 scope): "R2 holds: claim 9" · r3 (High): "The message means hg's variables"

Executed in r1's state log and r3's probe1: a HARDEN-key pair refused (exit 2), hg's exported variables accepted (`ok`, exit 0).

**Evidence:** `skills/dev-cycle/SKILL.md:227-231`, `scripts/build-loop.sh:660-674`; `docs/reviews/execution-logs/u4b1-final-r1-fc-state.log`

---

## Claim 37: commit 0cd86cc0: "A3: the bootstrap's own --main-log refusal is exempt; the other causes named."

**Location:** commit 0cd86cc0 message; `skills/dev-cycle/SKILL.md:227-231`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** reviewer
**Scope:** Covers A3 against step 0.2's text and the executed bootstrap (Claim 23 here); does not establish anything beyond that text.
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

Step 0.2 exempts the bootstrap's own refusal and names the other causes (SINCE off main's history, or the history could not be listed); the bootstrap run printed `main MAIN -` and its refuse line, exit 2 (r1).

**Evidence:** `skills/dev-cycle/SKILL.md:227-231`; `docs/reviews/execution-logs/u4b1-final-r1-fc-state.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 10** (`skills/dev-cycle/SKILL.md:52-57` vs `:214-219`): a `--state` exit 1 is routed to an `agent` entry by the Rules and to a `you: judgment` entry by step 0.1; pick one.
- **Claim 27** (`skills/dev-cycle/SKILL.md:266-267`; 4c911717 B8): stopping the health check "by its PID" leaves take_lock's waiting `flock` child, which takes the lock later and runs the health check anyway (executed by all three replicates).
- **Claim 35** (commit 0cd86cc0 R1): "only --state refuses ... commit signing" was false; 4c911717 records the correction (history only, no action).

### Stale
- **Claim 11** (`skills/dev-cycle/SKILL.md:409`): step 6's bare `git mv` contradicts the new hardened-git Rule; not on the U4b2 override row's list.

### Mostly Accurate
- **Claim 6** (`skills/dev-cycle/SKILL.md:25-26`): the by-hand gap is wider than filters and merge drivers (grafts, merge.verifySignatures with gpg.program, include/diff config, info/attributes, shallow, alternates).
- **Claim 7** (`skills/dev-cycle/SKILL.md:48-50`): "nothing a build loop edits runs as the gate" overstates; the snippet header's Q-140 gap applies.
- **Claim 9** (`skills/dev-cycle/SKILL.md:51-54`): exit 2 also carries `--main-log`'s `other` lines and non-ok verdicts, not only refuse lines.
- **Claim 13** (`skills/dev-cycle/SKILL.md:68-70`): hg signs nothing, but a planted `merge.verifySignatures` still runs `gpg.program` on `hg merge`; `--state` refuses it.
- **Claim 19** (`skills/dev-cycle/SKILL.md:140-145`): set by r2's compound verdict; every named class holds, the list's new-file qualifier is narrower than the code (see Claim 20).
- **Claim 20** (`skills/dev-cycle/SKILL.md:144-145`): `--check-fix` refuses any new file (untracked), not only one below an instruction-named directory.
- **Claim 26** (`skills/dev-cycle/SKILL.md:264-265`): the lock waits on another health check, not on "a loop's gate" in the skill's own sense of build-loop.sh.
- **Claim 32** (commit 4c911717): HARDEN has 9 pairs; 10 is the test's GIT_CONFIG_COUNT with the caller's pair.

### Unverifiable
- None.

---

## Escalations

- `skills/dev-cycle/SKILL.md:266-267` (Claim 27) — raised by r1, r2, r3 → **performance-reviewer**: the orphaned `flock` runs a full fast and slow suite after the hour bound and holds `health-check.lock` against the loops' gates (i2 F2's fix does not achieve its purpose).
- `skills/dev-cycle/SKILL.md:266-267` (Claim 27) — raised by r1, r2, r3 → **security-reviewer**: an unbounded orphan runs repository test code later, from a removed or advanced WT, outside the iteration's quiesce.
- `skills/dev-cycle/SKILL.md:52-57` / `:214-219` (Claim 10) — raised by r1, r2, r3 → **api-consistency-reviewer**: one cause (`--state` exit 1), two entry routes.
- `skills/dev-cycle/SKILL.md:51-54` (Claim 9) — raised by r3 → **api-consistency-reviewer**: the exit-2 definition is narrower than the header's Exit paragraph.
- `skills/dev-cycle/SKILL.md:68-70` (Claim 13) — raised by r2, r3 → **security-reviewer**: confirm `--state`'s re-run before commits is the intended and sufficient cover for `merge.verifySignatures`/`gpg.program`, which runs a planted program under hg when `--state` is skipped or raced.
- `skills/dev-cycle/SKILL.md:25-26` (Claim 6) — raised by r1, r3 → **security-reviewer**: the by-hand fallback's wider gap (grafts change hg's ancestry checks; merge.verifySignatures with gpg.program) to weigh against Q-140's interim.
- `skills/dev-cycle/SKILL.md:409` (Claim 11) — raised by r2 → **orchestrator**: the bare `git mv` could equally go on the U4b2 override row.
- commit 0cd86cc0 R1 (Claim 35) — raised by r2 → **orchestrator**: recorded so the merge message does not repeat the superseded "commit signing" wording.

---

## Verdict stability

37 clusters (sub-claim rows counted; r1 29, r2 30, r3 31 claim sections). All reporting replicates agreed on the verdict in 28 clusters, 3 of them single-replicate detections (Claims 11, 22, 37). Verdicts disagreed in 9 clusters:

- Claim 6: r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate
- Claim 7: r1=Verified (compound) · r2=— · r3=Mostly accurate
- Claim 10: r1=Incorrect · r2=Incorrect · r3=Mostly accurate
- Claim 13: r1=Verified (compound) · r2=Mostly accurate · r3=Mostly accurate
- Claim 19: r1=Verified · r2=Mostly accurate (compound) · r3=Verified (compound)
- Claim 20: r1=Mostly accurate · r2=Mostly accurate (compound) · r3=Verified (compound)
- Claim 26: r1=Mostly accurate · r2=Verified · r3=Verified
- Claim 32: r1=Mostly accurate · r2=Verified (compound) · r3=Verified (compound)
- Claim 35: r1=— · r2=Stale · r3=Incorrect

Agreement rate: 28/37 = 75.7% (25/34 = 73.5% excluding the three single-replicate clusters). Claim 27 counts as agreed on the verdict (Incorrect from all three) with a confidence split: r1 Medium, r2 and r3 High. Claim 36 also splits on confidence (r1 Medium, r3 High). Seven disagreements are between adjacent wording verdicts (Mostly accurate/Verified, Stale/Incorrect); Claim 10 is the one Incorrect-vs-Mostly accurate split, on a behavioral routing instruction. Claim 19's Mostly accurate comes only from r2's compound verdict, whose own text says every named class holds; its substance is Claim 20's.

---

## Goal-Alignment Note

- Success criterion: merge the three replicate reports for 4c911717 into one report per code-review's most-severe-wins procedure.
- Answered: yes (orchestrator collation; no verdicts or evidence added).
- Out of scope: none.
- Escalate: see Escalations (Claims 27, 10, 9, 13, 6, 11, 35).
