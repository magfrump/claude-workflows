# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u4c`)
**Scope:** `git diff main...feat/build-loop-u4c` (6 files: `docs/working/plan-build-loop-handoff.md`, `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `skills/dev-cycle/SKILL.md`, `test/lib/d6-snippet.bash` (deleted), `test/scripts/build-loop-orchestrator.bats`) plus the commit message of 1bc823ea
**Commit:** 1bc823ea
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-10-13
**Total claims checked:** 33
**Summary:** 21 verified, 6 mostly accurate, 1 stale, 4 incorrect, 1 unverifiable

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`) read first; no claim below matches a logged pattern, and no Incorrect verdict is a fabricated symbol (all four are a row mis-citation or an overbroad guarantee), so the log is not updated.

Execution logs (all run from `/workspace/.claude/wt-build-loop-u4c`, every process under `timeout`, none left running):
- `docs/reviews/execution-logs/u4c-i1-orchestrator-bats.log`: `timeout 300 bats test/scripts/build-loop-orchestrator.bats`, exit 0, 2026-10-14T05:48:35Z (UTC; local date 2026-10-13). 25/25 ok; test 15 (the real /opt run) ran, not skipped.
- `docs/reviews/execution-logs/u4c-i1-d6-zsh.log`: the fenced block extracted from SKILL.md (awk from `## The D6 block`'s ```` ```bash ```` fence to its closing fence), first line rewritten only in `WT`/`SCRIPT ARG...`, run with `zsh -f`; 2026-10-14T05:49:12Z. The as-run script for `--help` is `docs/reviews/execution-logs/u4c-i1-d6-run.zsh.txt`.
- `docs/reviews/execution-logs/u4c-i1-d6-path.log`: the block body under `/usr/bin/bash -s` with a uid-owned `bash` stub first in PATH; 2026-10-14T05:50:45Z, exit 0.

---

## Claim 1: "D6 runs the image copy built from main (Q-140 [1]), so it is live at the next release."

**Location:** `docs/working/plan-build-loop-handoff.md:71`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which copy the snippet runs (the /opt image) and that a merged gate-code change does not run until the image is rebuilt; does not establish how or when releases are cut.
**Legibility-target:** for-orchestrator-synthesis

The snippet runs only `bash "$D6_OPT/scripts/$s"` with `D6_OPT=/opt/claude-workflows` (`skills/dev-cycle/SKILL.md:218`, `:241`), so a change merged to main's `scripts/` is not what runs until the image under /opt is rebuilt.

**Evidence:** `skills/dev-cycle/SKILL.md:218`, `skills/dev-cycle/SKILL.md:241`

---

## Claim 2: "the snippet always runs the root-owned image copy ... it extracts nothing from MAIN_SHA, so the two bullets above and the root-commit test below no longer apply"

**Location:** `docs/working/plan-build-loop-handoff.md:81`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the snippet's behavior and which D6 bullets it voids; does not establish the rest of the plan's D6-dependent text (Claim 3).
**Legibility-target:** for-author

The behavior is right: the block has no `cat-file blob`, `ls-tree` or `mktemp` (`SKILL.md:216-243`; the T33 test greps for them, `test/scripts/build-loop-orchestrator.bats:258`). "The two bullets above" correctly names the extraction bullet (`:79`) and the hash-object bullet (`:80`), leaving the F38 bullet (`:78`) live, which matches `SKILL.md:226-229`. But "the root-commit test below" is in this same bullet ("As first written: it used main's copy only when main's first-parent root commit is claude-workflows'"), not below it. A precise version: "the two bullets above and the root-commit test described next no longer apply".

**Evidence:** `docs/working/plan-build-loop-handoff.md:77-83`, `skills/dev-cycle/SKILL.md:216-243`

---

## Claim 3: The plan's other D6 text: "D6. The gate runs from main's commit" (`:77`); F39 "covered | Root-commit identity" (`:157`); F40 "`questions.sh` extracted too (T33)" (`:158`); T33 "extracts the four files into `$T/scripts/{,lib/}` ... the SKILL.md block and `test/lib/d6-snippet.bash` are byte-equal" (`:396`); "The gate itself does not wait (D6)" (`:432`)

**Location:** `docs/working/plan-build-loop-handoff.md:77`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers these five lines in the plan, which this diff edits elsewhere but leaves unchanged; does not cover dated step text that only records history (`:322`, `:327`).
**Legibility-target:** for-author

Each line describes the pre-Q-140 snippet. Under U4c, D6 runs no copy from main's commit (`SKILL.md:197-198`: "never main's copy"); there is no root-commit identity test (no `D6_ROOT` in the block, asserted at `test/scripts/build-loop-orchestrator.bats:258`); nothing is extracted, so `questions.sh` is checked in place at `/opt` (`SKILL.md:237-238`); T33 now asserts the block appears once and reads no other copy (`bats:254-260`), with no second file to compare; and the gate does wait for a release, as the edited `:71` and the U4c as-built note (`:344`) both say ("a merged gate change runs only after an image rebuild"). The Superseded bullet at `:81` covers only `:79-80` inside D6, so these lines still read as current.

**Evidence:** `docs/working/plan-build-loop-handoff.md:77`, `:157`, `:158`, `:396`, `:432`, `:344`; `skills/dev-cycle/SKILL.md:197-198`, `:237-238`; `test/scripts/build-loop-orchestrator.bats:254-260`

---

## Claim 4: "the snippet always runs `/opt/claude-workflows/scripts/SCRIPT` once the four files are regular, root-owned, not symlinks and not writable, and so is every directory up to `/`; the verified reader, D6_ROOT, the temp dir and the SHA-1 branch are gone ... It keeps the replace-ref, grafts and default-branch checks."

**Location:** `docs/working/plan-build-loop-handoff.md:344`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the block's checks and run line as written in SKILL.md, and that it runs end to end against the real /opt image; does not establish what the checks catch beyond their stated tests (see Claims 15b, 18).
**Legibility-target:** for-orchestrator-synthesis

```bash
# skills/dev-cycle/SKILL.md:237-241
  for f in build-loop.sh dev-cycle.sh questions.sh lib/dev-cycle-read.sh; do
    own "$D6_OPT/scripts/$f"; [[ -f "$D6_OPT/scripts/$f" ]] || no "$D6_OPT/scripts/$f is not a regular file"
  done
  x="$D6_OPT/scripts/lib"; while own "$x"; [[ "$x" != / ]]; do x="${x%/*}"; x="${x:-/}"; done
  env -u BASH_ENV -u ENV -u DEV_CYCLE_SCRUBBED bash "$D6_OPT/scripts/$s" "$@"
```
`own` (`:222`) is `! -L && -e && stat %u == 0 && ! -w`. The walk visits `scripts/lib`, `scripts`, `/opt/claude-workflows`, `/opt`, `/`. Replace-ref, grafts and default-branch checks are at `:226-233`. Test 15 in the bats log ran the unstubbed block against /opt and passed, and the zsh run printed the /opt copy's `--help`.

**Evidence:** `skills/dev-cycle/SKILL.md:216-243`, `docs/reviews/execution-logs/u4c-i1-orchestrator-bats.log`, `docs/reviews/execution-logs/u4c-i1-d6-zsh.log`

---

## Claim 5: "(rows 741, 742 discharged with them)" and "SCRIPT may now also be `questions.sh` (row 775: SKILL.md runs it through the block, not `~/.claude/scripts`)"

**Location:** `docs/working/plan-build-loop-handoff.md:344`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers rows 741, 742 and 775 of `docs/reviews/override-log.md` (rows are line numbers) against the new code; for 742, does not establish that every remaining environmental `refuse d6:` (a failed git read) is gone; it is not, but SKILL.md's stop rule handles it.
**Legibility-target:** for-orchestrator-synthesis

Row 741 is "The verified reader is perl in a bash string, tested only end to end" (`override-log.md:741`), and the reader no longer exists. Row 742 names "a missing TMPDIR, a perl without Digest::SHA" printing `refuse d6:` (`:742`). Both causes are gone with the temp dir and perl. A failed git read still refuses (`SKILL.md:211`), and the Rule says "A full disk reads like planted state, so a stop is not called hostile" (`SKILL.md:57-58`). Row 775 asks for questions.sh by its /opt path (`:775`), which `SKILL.md:58-59`, `:224` and `:360-361` now provide.

**Evidence:** `docs/reviews/override-log.md:741`, `:742`, `:775`; `skills/dev-cycle/SKILL.md:57-59`, `:211`, `:224`, `:360-361`

---

## Claim 6: "The one canonical copy is the block in SKILL.md's "The D6 block" section (row 739)"

**Location:** `docs/working/plan-build-loop-handoff.md:344`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which override-log row the canonical-copy decision answers; does not dispute that the canonical copy is in SKILL.md (Claim 13 verifies that).
**Legibility-target:** for-author

Row 739 is the trust-root row: "The snippet chooses main's copy from the repository's own data ... Q-140" (`docs/reviews/override-log.md:739`). The canonical-home row is 738: "The canonical D6 source sits in test/lib/ beside fixtures ... U4 writes the SKILL.md block, names one canonical copy ... moving the file out of test/lib/ is its call" (`:738`). So this cites 739 for 738's subject, and the note never says that 739 itself, the selector, is discharged by Q-140 [1]. Fix: "(row 738)", and name row 739 as discharged by the removed selector.

**Evidence:** `docs/reviews/override-log.md:738`, `docs/reviews/override-log.md:739`, `docs/working/plan-build-loop-handoff.md:344`

---

## Claim 7: "T33 asserts it appears once and reads no main or home copy"

**Location:** `docs/working/plan-build-loop-handoff.md:344`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what test 11 checks; does not cover test 12, which supplies the behavior proof.
**Legibility-target:** for-author

```bash
# test/scripts/build-loop-orchestrator.bats:258
    ! grep -v '^ *#' "$D6" | grep -nE 'D6_ROOT|cat-file (blob|--batch)|ls-tree|mktemp|\$HOME|~/' || return 1
```
This is a denylist. A read of main through `git show main:scripts/...`, or a relative `bash "scripts/$s"`, would pass it. "Asserts ... reads no main or home copy" is right only for the listed spellings. Test 12 (`bats:262-279`) is what shows that main's and the working tree's copies are not run.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:254-260`, `:262-279`

---

## Claim 8: "the image at the time of writing (774a0eef) predates U4a's `--land-cycle`, so the cycle cannot land until the image is rebuilt from a main holding U4c"

**Location:** `docs/working/plan-build-loop-handoff.md:344`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the image manifest's commit and whether `--land-cycle` is in its build-loop.sh; does not establish when a rebuild happens.
**Legibility-target:** for-orchestrator-synthesis

`/opt/claude-workflows/.manifest` reads `commit=774a0eef3ff85beb69695e014ab840f70648f193`. `grep -c -- '--land-cycle' /opt/claude-workflows/scripts/build-loop.sh` gives 0, against 13 in the branch. `git merge-base --is-ancestor 774a0eef 722c2e10` (the commit "--land-cycle lands the chore branch") succeeds, and 722c2e10 is not an ancestor of 774a0eef. Also, the image's SKILL.md predates the D6 block, so "a main holding U4c" is the right bar (run 2026-10-14T05:4xZ in this worktree, interactive; output in the session, not captured to a file. Paraphrased — no quote available because these were one-line command outputs).

**Evidence:** `/opt/claude-workflows/.manifest`, `/opt/claude-workflows/scripts/build-loop.sh`, `scripts/build-loop.sh`

---

## Claim 9: store_check comment no longer refers to the D6 snippet's reader ("(The D6 snippet, test/lib/d6-snippet.bash, runs a narrower reader ...)" removed)

**Location:** `scripts/build-loop.sh:1042`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the edited comment; does not re-verify store_check's unchanged claims.
**Legibility-target:** for-orchestrator-synthesis

The comment now reads "and have one copy each (rows 492, 503). git checks no hash when it reads an object" (`scripts/build-loop.sh:1042-1044`), and nothing in it names the deleted file or reader.

**Evidence:** `scripts/build-loop.sh:1042-1050`

---

## Claim 10: "The scripts because the image copy built from main runs every merge after the next release (plan D6, D5 item 3; Q-140 [1]); skills/dev-cycle/ because its SKILL.md holds the D6 snippet that runs the gate (U4c; plan D4, F52). Both reach a session only from a release, so here the floor is stricter than D5."

**Location:** `scripts/lib/dev-cycle-read.sh:1962-1967`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the gate path (D6 runs /opt; the skill loads from the image); does not cover a loop's own advisory `--check` from its branch, which runs a working-tree copy and decides nothing.
**Legibility-target:** for-orchestrator-synthesis

The snippet runs only `$D6_OPT/scripts/$s` (`SKILL.md:241`), and `~/.claude/scripts` resolves to `/opt/claude-workflows/scripts` (`readlink -f`, observed). GATE_CODE below it is `'^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'` (`:1970`). The plan's D5 "In this repo" (`plan:75`) says code reaches sessions only through a release, so flooring it anyway is stricter.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1962-1970`, `skills/dev-cycle/SKILL.md:241`, `docs/working/plan-build-loop-handoff.md:75`

---

## Claim 11a: "In every repository, claude-workflows too, it runs the root-owned image copy (Q-140 [1]), so nothing a build loop can write chooses ... what runs as the gate"

**Location:** `skills/dev-cycle/SKILL.md:40-42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which script file is chosen; does not cover what interprets it (Claim 11b).
**Legibility-target:** for-orchestrator-synthesis

The script path is a constant (`D6_OPT=/opt/claude-workflows`, `:218`) with no branch on repository data. Test 12 (main and the working tree hold `echo main copy; exit 9` / `echo working copy; exit 9`) passed, and the lib reported `lib at $U/scripts/lib/dev-cycle-read.sh`.

**Evidence:** `skills/dev-cycle/SKILL.md:218`, `:241`; `test/scripts/build-loop-orchestrator.bats:262-279`; `docs/reviews/execution-logs/u4c-i1-orchestrator-bats.log`

---

## Claim 11b: "so nothing a build loop can write ... changes what runs as the gate"

**Location:** `skills/dev-cycle/SKILL.md:41-42`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the interpreters the block runs; does not dispute the plan's stated threat model (a hostile same-uid loop with a shell is out of scope, `plan:33`; override-log row 775 accepts the shell-profile route), only the absolute wording.
**Legibility-target:** for-author

Same finding as Claim 15b, here in the Rule. The block resolves `bash`, `env`, `git` and `stat` through PATH (`SKILL.md:220`, `:222`, `:241`). In this container PATH's first entry is `/home/node/.elan/bin`, owned by node and writable, and the uid also owns `~/.zshrc`, which initializes the Bash tool's shell. With a uid-owned `bash` stub first in PATH, the block's inner run executed the stub: `planted bash ran with: /opt/claude-workflows/scripts/build-loop.sh --help` (exit 0, `u4c-i1-d6-path.log`). A same-uid loop writing such a file changes what runs as the gate. A precise version: "nothing a build loop can write to the repository chooses which gate script runs" (the interpreter comes from the caller's PATH, trusted as the caller's environment).

**Evidence:** `skills/dev-cycle/SKILL.md:220-241`, `docs/reviews/execution-logs/u4c-i1-d6-path.log`, `docs/working/plan-build-loop-handoff.md:33`, `docs/reviews/override-log.md:775`

---

## Claim 12: "`questions.sh` runs through the D6 block too (its first argument), never as `~/.claude/scripts/questions.sh`, a uid-owned link."

**Location:** `skills/dev-cycle/SKILL.md:58-59`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the block accepting and running questions.sh, every questions.sh mention in SKILL.md, and the link's ownership in this container; does not establish questions.sh's own git hardening (Claim 21).
**Legibility-target:** for-orchestrator-synthesis

`ls -la ~/.claude/scripts` shows `lrwxrwxrwx 1 node node ... /home/node/.claude/scripts -> /opt/claude-workflows/scripts`, and `~/.claude` is node-owned 755, so the uid can repoint the link. The block accepts `questions.sh` (`:224`). Run from zsh as `bash -s -- questions.sh next-id`, it printed `Q-144` with exit 0 (`u4c-i1-d6-zsh.log`). Every other mention is consistent: `:191`, `:196`, `:203`, `:360-361` ("through the D6 block from WT"), `:689` ("`questions.sh index` and `check` in WT", no other form named) and `:409` (the digest's own message text). No line tells the orchestrator to run `~/.claude/scripts/questions.sh`.

**Evidence:** `skills/dev-cycle/SKILL.md:58-59`, `:191`, `:224`, `:360-361`, `:409`, `:689`; `docs/reviews/execution-logs/u4c-i1-d6-zsh.log`

---

## Claim 13: "The canonical copy: every run pastes the lines between the `bash -s` line and the `D6` line below, byte for byte (a test reads them from this file)."

**Location:** `skills/dev-cycle/SKILL.md:189-191`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers there being one copy and the tests extracting it; does not establish that orchestrator sessions paste it faithfully.
**Legibility-target:** for-orchestrator-synthesis

`d6_copy` extracts with `awk '/^## The D6 block$/ { s = 1 } s && b && /^D6$/ { exit } b { print } s && /^cd WT && bash -s -- SCRIPT ARG\.\.\. <<.D6.$/ { b = 1 }' "$REPO_ROOT/skills/dev-cycle/SKILL.md"` (`bats:235`). `test/lib/d6-snippet.bash` is deleted, and test 11 asserts it is absent (`bats:259`). All 25 tests pass.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:233-238`, `:259`; `docs/reviews/execution-logs/u4c-i1-orchestrator-bats.log`

---

## Claim 14: The call form `cd WT && bash -s -- SCRIPT ARG... <<'D6'` with the block and a last `D6` line runs as written, from a zsh caller, the quoted heredoc preserving the block

**Location:** `skills/dev-cycle/SKILL.md:194`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `zsh -f` and bash callers with WT/SCRIPT substituted; does not cover a caller whose profile alters PATH or aliases (Claim 11b).
**Legibility-target:** for-orchestrator-synthesis

With the first line rewritten to `cat > received.txt <<'D6'`, the heredoc bash receives is byte-identical to the block's 52 body lines (`cmp` silent; 3922 bytes, 18 lines holding `$`). Run under `zsh -f`, `build-loop.sh --help` exits 0 with output equal to `/opt/.../build-loop.sh --help`; the only diff is a locale warning on the merged stderr. `questions.sh next-id` exits 0, `nope` exits 1 with the documented message, and the same file run by bash exits 0.

**Evidence:** `docs/reviews/execution-logs/u4c-i1-d6-zsh.log`, `docs/reviews/execution-logs/u4c-i1-d6-run.zsh.txt`

---

## Claim 15a: "It always runs the root-owned image copy under D6_OPT by absolute path, never main's copy, a working-tree copy or ~/.claude/scripts"

**Location:** `skills/dev-cycle/SKILL.md:197-198`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the script file run; does not cover the interpreter (Claim 15b).
**Legibility-target:** for-orchestrator-synthesis

`bash "$D6_OPT/scripts/$s"` (`:241`), with `D6_OPT=/opt/claude-workflows` (`:218`). Tests 12, 15 and 16 pass.

**Evidence:** `skills/dev-cycle/SKILL.md:218`, `:241`; `docs/reviews/execution-logs/u4c-i1-orchestrator-bats.log`

---

## Claim 15b: "so nothing this uid can write chooses or changes what runs"

**Location:** `skills/dev-cycle/SKILL.md:198-199`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the block's PATH-resolved commands; does not establish that the project must defend against this (the plan, `:33`, and row 775 accept a same-uid shell as out of reach).
**Legibility-target:** for-author

The block resolves `env`/`bash` by name: `env -u BASH_ENV -u ENV -u DEV_CYCLE_SCRUBBED bash "$D6_OPT/scripts/$s" "$@"` (`:241`), and `G=(env ... git ...)` (`:220`). The scripts it runs also call `perl`, `python3` and `git` by name (`scripts/lib/dev-cycle-read.sh:129`, `:1278`; `scripts/build-loop.sh:1081`). This uid can write `/home/node/.elan/bin`, the first PATH entry here. Executed: with a uid-owned `bash` stub first in PATH, the stub ran in place of the interpreter (`planted bash ran with: /opt/claude-workflows/scripts/build-loop.sh --help`, exit 0). The "this uid" wording is broader than the Rule's (Claim 11b) and is refuted outright. Precise version: "so no repository data chooses which script runs; the interpreters come from the caller's PATH".

**Evidence:** `skills/dev-cycle/SKILL.md:220`, `:241`; `scripts/lib/dev-cycle-read.sh:129`; `scripts/build-loop.sh:1081`; `docs/reviews/execution-logs/u4c-i1-d6-path.log`

---

## Claim 16: "Run it from the checkout the script is to read (each step names MAIN_WT or WT)."

**Location:** `skills/dev-cycle/SKILL.md:202-203`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the checkouts SKILL.md names for D6 calls; does not check each step's call site individually.
**Legibility-target:** for-author

The Rule names a third checkout: "step 7's self-merge from its GT, after a `--state` from MAIN_WT" (`SKILL.md:37-38`), and step 7 makes GT at "`.claude/wt-dev-cycle-gate-DATE-HHMM` in MAIN_WT" (`:541-542`). Precise version: "(each step names MAIN_WT, WT or step 7's GT)".

**Evidence:** `skills/dev-cycle/SKILL.md:37-38`, `:202-203`, `:540-542`

---

## Claim 17: The header's refusal list ("a replace ref, info/grafts, a default branch that is not exactly one plain main or master or whose ref names no commit itself, an image-copy file that is not a regular file, or one of those files or a directory above them that is not root-owned, a plain path and unwritable here ..., or a git read that fails ...; 1 for another first argument") is complete and exact

**Location:** `skills/dev-cycle/SKILL.md:205-212`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `no` call and the one `exit 1` in the block; does not cover a failure of `cd WT` (outside the block) or a missing `bash` (exit 127, "the script's own status" in effect).
**Legibility-target:** for-orchestrator-synthesis

The `no` calls are `:222` (own), `:226` and `:228` (git reads fail), `:227` (replace ref), `:229` (grafts), `:231` (not exactly one), `:232` (symbolic ref, "names no commit itself"), `:233` (no commit) and `:238` (not a regular file). The only `exit 1` is `:224`. Each item in the list maps to one of them, and no `no` call is left out. A missing file refuses through `own`'s `-e` with the ownership message, not the regular-file one (`:222` before `:238`), which the list's "or" covers. Executed: test 13 passes; `nope` gives exit 1 and `d6: the first argument is build-loop.sh, dev-cycle.sh or questions.sh` on stderr.

**Evidence:** `skills/dev-cycle/SKILL.md:216-243`, `test/scripts/build-loop-orchestrator.bats:281-296`, `docs/reviews/execution-logs/u4c-i1-d6-zsh.log`

---

## Claim 18: "(the -w test makes a run as root refuse unless the mount is read-only)"

**Location:** `skills/dev-cycle/SKILL.md:210`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the static reading of `[[ ! -w ]]` under euid 0; does not establish the runtime result, which needs a root run (execution required, blocked).
**Legibility-target:** for-author

Blocker: the sandbox runs as `uid=1000(node)` with no root, so the runtime guarantee could not be run. Statically, `own` is `[[ ! -L "$1" && -e "$1" && "$(stat -c %u -- "$1")" == 0 && ! -w "$1" ]]` (`:222`). Bash's `-w` uses an effective-uid access check that grants root write access except where the kernel refuses it, so a root run refuses on a read-write mount, as claimed (here `/` is an `overlay ... rw` mount per `/proc/mounts`). The kernel also refuses write on immutable (`chattr +i`) files, so "unless the mount is read-only" may omit one case (paraphrased — no quote available because this is kernel/bash behavior outside the repository).

**Evidence:** `skills/dev-cycle/SKILL.md:222`, `/proc/mounts`

---

## Claim 19: "Its git carries the lib's HARDEN pairs and git_harden's environment (G; a test pins the lists equal)."

**Location:** `skills/dev-cycle/SKILL.md:212-213`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the snippet's own `g` calls; does not cover git run by the scripts it starts (they call git_harden themselves, except questions.sh: Claim 21).
**Legibility-target:** for-orchestrator-synthesis

G's seven `GIT_*` settings and nine `-c` pairs (`:220`) equal `HARDEN=(...)` and git_harden's `export GIT_CONFIG_COUNT=... GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1 GIT_OPTIONAL_LOCKS=0 GIT_ATTR_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_ALLOW_PROTOCOL=none` (`scripts/lib/dev-cycle-read.sh:354`, `:365`). Test 17 now reads `G=(env` from SKILL.md, asserts it appears once (`bats:338`), and checks it against the same `H`/`E` literals the lib's output is checked against. It passes.

**Evidence:** `skills/dev-cycle/SKILL.md:220`, `scripts/lib/dev-cycle-read.sh:354-366`, `test/scripts/build-loop-orchestrator.bats:325-345`, `docs/reviews/execution-logs/u4c-i1-orchestrator-bats.log`

---

## Claim 20: "These checks come before, not instead of, build-loop.sh's own state and default-branch gates in its gated modes (dev-cycle.sh, questions.sh and the read modes have none: row 548)."

**Location:** `skills/dev-cycle/SKILL.md:213-215`
**Type:** Architectural / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which scripts and modes run state_gate/default_gate; does not cover dev-cycle.sh's resolve_main, which is not a gate.
**Legibility-target:** for-author

The behavior holds. `GATED=""; [[ "$MODE" =~ ^(settings|status|marker)$ ]] || GATED=1` and `if [[ -n "$GATED" ]]; then state_gate || exit 2; fi` (`scripts/build-loop.sh:707`, `:710`). `default_gate` runs only in `state_start` (`:1316`) and `--merge` (`:1557`), never for settings, status or marker (dispatch `:2080-2135`). `rg 'state_gate|default_gate'` finds nothing in dev-cycle.sh or questions.sh. But row 548 covers only dev-cycle.sh: "dev-cycle.sh runs neither state_gate nor default_gate" (`override-log.md:548`). It is cited for all three.

**Evidence:** `scripts/build-loop.sh:707-710`, `:1315-1316`, `:1557`, `:2080-2135`; `docs/reviews/override-log.md:548`

---

## Claim 21: "The four files the scripts run (each sources the lib from its own directory; dev-cycle.sh runs questions.sh beside it)"

**Location:** `skills/dev-cycle/SKILL.md:234-236`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers how each of the three scripts finds the lib and questions.sh, and whether they read any other file under scripts/ that the checks miss; does not cover interpreters (Claim 15b).
**Legibility-target:** for-author

build-loop.sh and dev-cycle.sh each do `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` and `source "$SCRIPT_DIR/lib/dev-cycle-read.sh"` (`scripts/build-loop.sh:524-531`, `scripts/dev-cycle.sh:95-103`). dev-cycle.sh runs `QS="$SCRIPT_DIR/questions.sh"` (`:389`); its fallback `[[ -f "$QS" ]] || QS="$HOME/.claude/scripts/questions.sh"` (`:390`) is unreachable once the block has checked that file is regular. The lib sources nothing further, and no script reads another file under scripts/, so the four files plus their directories are the whole set (paraphrased — no quote available because this is a claim of absence: `rg 'SCRIPT_DIR|source'` over the four files finds only the lines quoted here). But "each" is inexact: questions.sh sources no lib. When the block runs it directly (new in U4c), its `git -C "$PWD" rev-parse` calls (`scripts/questions.sh:80`, `:84`) run without git_harden, whereas under dev-cycle.sh they inherit its hardened environment (`scripts/dev-cycle.sh:127-130`). Precise version: "(build-loop.sh and dev-cycle.sh source the lib from their own directory; dev-cycle.sh runs questions.sh beside it)".

**Evidence:** `scripts/build-loop.sh:524-532`, `scripts/dev-cycle.sh:95-104`, `:389-390`, `:127-130`; `scripts/questions.sh:80-84`

---

## Claim 22: "Under bash -s the script is the heredoc on stdin: bash has read this whole line before it runs, and no child reads the rest of it."

**Location:** `skills/dev-cycle/SKILL.md:244-246`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `d6 "$@" </dev/null` line being the block's last; does not cover a block edited to add lines after it.
**Legibility-target:** for-orchestrator-synthesis

`d6 "$@" </dev/null` is the last line (test 11 asserts it, `bats:257`), so children read /dev/null. Under zsh and bash callers the run completed with the script's own exit status.

**Evidence:** `skills/dev-cycle/SKILL.md:246`, `docs/reviews/execution-logs/u4c-i1-d6-zsh.log`

---

## Claim 23: "Here and above, a cycle you know ran is one that reached step 9's land; an iteration that stopped does not count (U4b2 confirm3 F1)."

**Location:** `skills/dev-cycle/SKILL.md:335-336`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cited finding's subject; does not establish that the wording fully closes it.
**Legibility-target:** for-orchestrator-synthesis

F1 is "The session's own window check rewinds the digest past the gap c8d90d62 closes", conditional on "the orchestrator counting a stop iteration as 'a cycle you know ran'" (`docs/reviews/security-review-2026-10-13-u4b2-confirm3.md:49-55`). The step 0.4 text (as the commit names it) addresses exactly that reading.

**Evidence:** `docs/reviews/security-review-2026-10-13-u4b2-confirm3.md:49-55`, `skills/dev-cycle/SKILL.md:319-336`

---

## Claim 24: "d6_copy OPT [trust]: D6, that copy with D6_OPT set to OPT; with trust its ownership check passes any path that exists, so a uid-owned OPT stands in for the root-owned image. d6_setup: main holds this branch's four scripts, and so does a trusted stand-in at $U."

**Location:** `test/scripts/build-loop-orchestrator.bats:227-243`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the helpers' behavior; does not establish which properties a stubbed run still tests (see Claims 26-27).
**Legibility-target:** for-orchestrator-synthesis

The trust branch rewrites own to `own() { [[ -e "$1" ]] || no "$1 is missing"; }` and greps that the rewrite took (`:237`). The OPT substitution is likewise grep-guarded (`:236`), so a drifted SKILL.md fails the helper rather than silently running /opt. `d6_setup` commits the four scripts and runs `opt_copy "$U" && d6_copy "$U" trust` (`:240-242`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:233-243`, `docs/reviews/execution-logs/u4c-i1-orchestrator-bats.log`

---

## Claim 25: Test name "SKILL.md holds the D6 snippet once, and it names no other copy to run: no root test, no read of main's scripts (T33, U4c)"

**Location:** `test/scripts/build-loop-orchestrator.bats:254`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test's assertions establish; does not cover test 12's behavioral proof.
**Legibility-target:** for-author

"Once" is established: one `^cd WT && bash -s -- ...` line and one `^D6$` line (`:256`). "No root test" is established for the `D6_ROOT` spelling. "Names no other copy to run" rests on the denylist at `:258` (Claim 7): `git show`, `rev-parse ...:path`, or a relative `scripts/$s` path would pass it. The name is right about what the current block does, but this test alone does not hold it there. Test 12 is what does.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:254-260`

---

## Claim 26: Test name "the D6 snippet runs the image copy's scripts by absolute path, each with its own lib and questions.sh, never main's or the working tree's (T33, U3b3, U4c)"

**Location:** `test/scripts/build-loop-orchestrator.bats:262`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers path selection, lib sourcing and questions.sh lookup with the ownership check stubbed; does not test ownership (tests 15-16 do), nor any directory-walk refusal: no test makes an ancestor directory writable, uid-owned or a symlink, so `:240`'s walk has only the /opt success path.
**Legibility-target:** for-author

The stub replaces only `own`. Path selection (`:241`) is unchanged, so the stub makes nothing here vacuous. Main and the working tree hold `echo main copy; exit 9` / `echo working copy; exit 9` (`bats:265-268`). The lib must print exactly `lib at $U/scripts/lib/dev-cycle-read.sh` (`:273`), and `dev-cycle.sh` and `questions.sh open` must show `from-opt` (`:277-278`). It passes.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:262-279`, `docs/reviews/execution-logs/u4c-i1-orchestrator-bats.log`

---

## Claim 27: Test "the D6 snippet refuses before running anything: a blob or commit replace ref, info/grafts, not exactly one plain main or master (T36, U3b3)" with U4c's added assertions

**Location:** `test/scripts/build-loop-orchestrator.bats:281-296`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the named refusals and the regular-file and first-argument checks; does not test the real `own` message for a missing file: `refuse d6: $U/scripts/questions.sh is missing` (`:293`) is the stub's text, which the real block never prints (it prints "... is not root-owned, a plain path and unwritable here").
**Legibility-target:** for-orchestrator-synthesis

The added lines (`:293-295`) establish that questions.sh is in the checked list, that `-f` refuses a directory at `lib/dev-cycle-read.sh` (a real-code path, since the stubbed `own` passes an existing directory), and the new exit-1 message. The test name covers only the original refusals, and they are unchanged. It passes.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:281-296`, `skills/dev-cycle/SKILL.md:222`, `:238`

---

## Claim 28: Test names "the D6 snippet runs the root-owned image copy at /opt by absolute path, not main's copy (T37, U3b3)" and "the D6 snippet refuses an image copy the uid owns, and never runs main's (T37, U3b3)"

**Location:** `test/scripts/build-loop-orchestrator.bats:311`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both unstubbed tests; does not cover a root-owned-but-writable or symlinked image (no test).
**Legibility-target:** for-orchestrator-synthesis

Both use `d6_copy` without `trust` (`:315`, `:321`), so the real `own` applies. Test 15 ran rather than skipping (it skips without a root-owned /opt), and its `--help` output equals the /opt copy's. Test 16 gets exactly `refuse d6: $U/scripts/build-loop.sh is not root-owned, a plain path and unwritable here`. These are the "unstubbed refusal and the real /opt run" the commit cites.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:311-323`, `docs/reviews/execution-logs/u4c-i1-orchestrator-bats.log`

---

## Claim 29: No stale reference remains to `test/lib/d6-snippet.bash`, `D6_ROOT`, the verified reader or the by-hand fallback (outside `docs/reviews/`, dated `docs/working/merge-msg-*`)

**Location:** `skills/dev-cycle/SKILL.md:16`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers those four terms (and `640cf007`) repo-wide; does not cover the plan's broader D6 descriptions (Claim 3).
**Legibility-target:** for-orchestrator-synthesis

`rg 'd6-snippet|D6_ROOT|verified reader|by-hand fallback|by-hand cycle|640cf007'` (excluding the two dated sets) finds only T33's own absence assertions (`bats:258-259`), the answered Q-140 entry in `docs/working/questions-archive.md`, and dated lines in `docs/working/checkpoint-build-loop-handoff.md`; all are history. The by-hand fallback paragraph and the Rule's pointer to it are removed from SKILL.md (diff hunks at `:16-28` and `:66-71`; paraphrased — no quote available because this is a claim of absence).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:258-259`, `docs/working/questions-archive.md:2606`, `docs/working/checkpoint-build-loop-handoff.md:10`

---

## Claim 30a: Commit 1bc823ea body: "the verified reader, D6_ROOT and the temp dir go ... It keeps the replace-ref, grafts and default-branch checks, and the ownership checks on the four files and every directory above them. It also takes questions.sh (row 775). ... test/lib/d6-snippet.bash is deleted and the tests extract the block from SKILL.md. The by-hand fallback is gone. Step 0.4: a stopped iteration is not a cycle that ran (U4b2 confirm3 F1). ... the tests stand in for the root-owned image with a uid-owned copy whose ownership check is stubbed in the test's copy only, and the unstubbed refusal and the real /opt run are tested as before."

**Location:** `git log -1 --format=%B 1bc823ea`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these sentences against the diff and test run; "so no repository data ... can choose the scripts that run" is Verified as Claims 11a/15a scope it (interpreters excluded).
**Legibility-target:** for-orchestrator-synthesis

Each sentence matches Claims 4, 5, 12, 13, 23, 24 and 28 (paraphrased — no quote available because this cross-references the evidence already quoted in those claims).

**Evidence:** `skills/dev-cycle/SKILL.md:216-243`, `test/scripts/build-loop-orchestrator.bats:227-323`, `docs/reviews/execution-logs/u4c-i1-orchestrator-bats.log`

---

## Claim 30b: Commit 1bc823ea Notes: "the one canonical copy is SKILL.md, not a file under test/lib/ (row 739 left the home to U4)"

**Location:** `git log -1 --format=%B 1bc823ea`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row number only; the commit is history, so the fix is in the plan note (Claim 6) or an Accepted-immutable row.
**Legibility-target:** for-author

The row that "left the home to U4" is 738 ("moving the file out of test/lib/ is its call", `docs/reviews/override-log.md:738`). Row 739 is the trust-root selector (`:739`). This is the same mis-citation as Claim 6.

**Evidence:** `docs/reviews/override-log.md:738-739`

---

## Claims Requiring Attention

### Incorrect
- **Claim 6** (`docs/working/plan-build-loop-handoff.md:344`): the canonical-copy row is 738, not 739. Cite 738 and name 739 (the selector) as discharged by Q-140 [1].
- **Claim 11b** (`skills/dev-cycle/SKILL.md:41-42`): "nothing a build loop can write ... changes what runs as the gate" is overbroad. `bash`, `env`, `git` and `stat` come from PATH, whose first entry here is uid-writable (executed: a stub ran). Narrow it to which script runs.
- **Claim 15b** (`skills/dev-cycle/SKILL.md:198-199`): the same, with the broader "nothing this uid can write" wording.
- **Claim 30b** (commit 1bc823ea Notes): "row 739 left the home to U4" should be row 738. The commit is immutable, so record it as an Accepted-immutable row.

### Stale
- **Claim 3** (`docs/working/plan-build-loop-handoff.md:77`, `:157`, `:158`, `:396`, `:432`): the D6 heading ("runs from main's commit"), F39 ("Root-commit identity"), F40 ("questions.sh extracted"), the T33 row (extraction, byte-equality with test/lib) and "The gate itself does not wait (D6)" all predate Q-140 [1].

### Mostly Accurate
- **Claim 2** (`plan:81`): "the root-commit test below" is in the same bullet, not below.
- **Claim 7** (`plan:344`): T33's "reads no main or home copy" is a denylist grep; test 12 carries the behavior.
- **Claim 16** (`SKILL.md:202-203`): "each step names MAIN_WT or WT" leaves out step 7's GT.
- **Claim 20** (`SKILL.md:213-215`): the behavior is right, but row 548 covers only dev-cycle.sh.
- **Claim 21** (`SKILL.md:234-236`): questions.sh sources no lib, and run directly through the block its two `git rev-parse` calls are unhardened.
- **Claim 25** (`bats:254`): "names no other copy to run" is held only by the denylist.

### Unverifiable
- **Claim 18** (`SKILL.md:210`): "the -w test makes a run as root refuse unless the mount is read-only" needs a root run, which the sandbox can't do. Statically it also misses immutable files.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to docs/reviews/code-fact-check-report-2026-10-13-u4c-i1.md, structured per the code-fact-check skill, with `**Commit:** 1bc823ea` and `**Replication:** k=1 (loop pass, decision 031)` in its header.
- Answered: yes. All seven claim groups checked; claims 2, 4 and 7 executed (the block from zsh, bats 25/25, a PATH probe).
- Out of scope: running as root (Claim 18); scripts/health-check.sh (not run, per instruction); code-quality judgments on the test gaps (no ancestor-directory refusal test), noted only as Scope residue.
- Escalate: Claims 11b/15b (PATH-resolved interpreters vs the header's absolute guarantee) for the security critic; Claim 21's unhardened questions.sh git when the block runs it directly; Claim 30b as an Accepted-immutable row.
- Decisions I made: rows cited as "row N" are read as line N of docs/reviews/override-log.md (their content matches each citation's subject except 739); verdicted 11b/15b Incorrect, not Mostly accurate, because the stated mechanism ("nothing ... changes what runs") is refuted by execution, despite the plan's accepted same-uid threat model.
