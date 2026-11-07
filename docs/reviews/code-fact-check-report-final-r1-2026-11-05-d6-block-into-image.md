Commit: 1c5fd04f

# Code Fact-Check Report

**Repository:** claude-workflows, worktree `.claude/wt-2026-11-05-d6-block-into-image`, branch `refactor/d6-block-into-image`
**Scope:** `git diff 5b20d4bd..1c5fd04f -- . ':!docs/reviews'` (9 files, full branch), plus the code that exercises the claims the dispatch named
**Checked:** 2026-11-05
**Replication:** k=3, replicate r1 (final confirming pass)
**Total claims checked:** 52
**Summary:** 45 verified, 5 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

The code does what its comments say. d6.sh's header, the Rules bullet, the four 127 sites, the plan's amendment and rows, and every d6 test title hold, and 12 of 12 mutants of d6.sh were killed.

One new error, in the research doc, stated twice. `--main-log` does not read `info/grafts`: it lists history through `gate_git`, in a repository with no `info/` directory (Claims 12b, 21). So "a planted `info/grafts` now reaches `--main-log`" and "everything then reads consistently" are both false. The real exposure is smaller and elsewhere. The sentence sits in the owner's option table (`:117`), so it should be fixed before the owner answers. The first fact-check pass Verified it (its Claim 24) because it saw `--main-log` answer, not what it read. The security review repeats it at line 103.

Five small imprecisions remain (Claims 2, 9, 11, 19, 35). No finding touches code behaviour: all seven edits are to prose or comments.

No claim matches a pattern in `docs/reviews/hallucination-patterns.md`. Neither Incorrect verdict is a fabricated symbol, option or API, and the dispatch allows no edit but this report, so the log is unchanged.

## Execution provenance

Each row ran under `timeout`. FC3 is `/tmp/claude-1000/-workspace/47403b7b-5fcb-4e13-8807-c539081df064/scratchpad/2026-11-05-d6-block-into-image/fc3-r1/`. Logs stay there because the dispatch allowed no edit but this report, so `docs/reviews/execution-logs/` was not used. The probes' scratch repositories are removed and no probe is running. git is 2.39.5. The image at `/opt/claude-workflows` is commit c214970a and holds no `d6.sh`. Mutants ran in a `git archive` copy, so the review worktree was not touched.

| Id | Command | Cwd | Exit | Start (UTC) | Output |
|---|---|---|---|---|---|
| E1 | `timeout 120 bash probe1.sh` (HEAD's d6.sh with one literal changed: exits, broken refs, broken libs, symlink, every default-branch shape by mode, grafts, replace, BASH_ENV, exported function, the live 127, zsh and bash messages) | FC3 | 0 | 2026-11-06T07:26:00Z | FC3/probe1.log |
| E2 | `TMPDIR=FC3/tmpD timeout 400 bats -f 'd6\|GATE_CODE\|git_harden exports' test/scripts/build-loop-orchestrator.bats` (14 of 14 ok, none skipped) | worktree | 0 | 2026-11-06T07:26:02Z | FC3/bats-d6.log |
| E3 | `TMPDIR=FC3/tmpD timeout 200 bats -f 'floor' test/scripts/build-loop-check.bats` (9 of 9 ok) | worktree | 0 | right after E2, 2026-11-06T07:26:03Z | FC3/bats-floor.log |
| E4 | `timeout 500 bash probe2.sh` (GIT_ names reaching the script, `--main-log` under a graft, junk HEAD, the old block on the real image, 12 mutants of d6.sh) | FC3 | 0 | 2026-11-06T07:28:08Z | FC3/probe2.log |
| E5 | `timeout 60 bash probe3.sh` (a graft read in the real repository and in a gate-shaped one, `--main-log` with and without it, two controls) | FC3 | 0 | 2026-11-06T07:29:45Z | FC3/probe3.log |
| E6 | `timeout 120 bash probeB.sh` (a copy of pass i2's probe: the real image's `--check` and `--merge` of a self-merge brief naming `scripts/d6.sh`, never line none and set) | FC3/fc2 | 0 | 2026-11-06T07:30:21Z | FC3/probeB.log |
| E7 | `timeout 30 shellcheck scripts/d6.sh` | worktree | 0 | 2026-11-06T07:30:53Z | FC3/shellcheck.log |

---

## Claim 1: The D6 amendment bullet ("the snippet is no longer inline ... It is the file `scripts/d6.sh` ... d6.sh keeps ... it drops ... Its git is the image lib's `git_harden` ... T33, T36 and T37 test the file ...")

**Location:** `docs/working/plan-build-loop-handoff.md:88`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each kept and dropped check, the 127 sentence, the payload route and the test moves; does not establish that the bullet lists everything d6.sh does, since it says "keeps" and omits the new lib-load refusal, which T36's row carries.

`scripts/d6.sh:45-49` is the presence loop, `:53-59` the exactly-one check, and `:60` the scrub, `exec env -u BASH_ENV -u ENV -u DEV_CYCLE_SCRUBBED -u QUESTIONS_LIVE -u QUESTIONS_ARCHIVE -u QUESTIONS_WATCHING bash "$D6_OPT/scripts/$s" "$@" </dev/null`. No replace, grafts, symbolic-ref, cat-file or ownership check remains (paraphrased — no quote available because the claim covers absence of code: all 60 lines were read). E1 ran the live call: `rc=127 stdout-bytes=0 stderr: bash: /opt/claude-workflows/scripts/d6.sh: No such file or directory`. `default_gate` keeps both refusals (Claim 29). The payload route is Claim 8.

**Evidence:** `scripts/d6.sh:33-60`, `scripts/build-loop.sh:764-790`, `test/scripts/build-loop-orchestrator.bats:332-366`, FC3/probe1.log, FC3/bats-d6.log

---

## Claim 2: "the D6 snippet's copy refuses the same tip" (T27), "the hardened snippet" (F26), "D6 snippet; T27, T33, T36, T37"

**Location:** `docs/working/plan-build-loop-handoff.md:406`
**Type:** Staleness
**Verdict:** Mostly accurate
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the name in three live table rows at `:151`, `:406` and `:431`; does not cover the plan's dated build history (`:325-355`), where "snippet" is correct for its time.

The behaviour stands and the test passes, but the name went with this branch: `:406` still reads `the D6 snippet's copy refuses the same tip`, while the same test is now titled `d6.sh's image copy refuses the same tip` (`test/scripts/build-loop-orchestrator.bats:379`). This is the class of item i2's Claim 7 raised on T37, which was fixed; T33, T36 and T37 now say d6.sh and these three rows do not. Say `d6.sh` in all three.

**Evidence:** `docs/working/plan-build-loop-handoff.md:151`, `docs/working/plan-build-loop-handoff.md:406`, `docs/working/plan-build-loop-handoff.md:431`, `test/scripts/build-loop-orchestrator.bats:379`

---

## Claim 3: F38 "`git_harden` ignores replace refs; d6.sh refuses a default branch that is not exactly one of main and master (T36 ...). Grafts are an accepted hostile-only residual"

**Location:** `docs/working/plan-build-loop-handoff.md:166`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both pins, the refusal and that grafts stay unrefused; does not say which reads a graft reaches, which Claim 21 settles.

`scripts/lib/dev-cycle-read.sh:333` holds `core.useReplaceRefs=false` and `:343` exports `GIT_NO_REPLACE_OBJECTS=1`. E1 printed `plain show: R; hardened: x` for a blob replace ref, and `--state` answered `ok` with the ref present. T36's refusal passed in E2.

**Evidence:** `scripts/lib/dev-cycle-read.sh:333-344`, `scripts/d6.sh:53-59`, FC3/probe1.log, FC3/bats-d6.log

---

## Claim 4: F39 "`/opt/...` by absolute path, in every repository ...; the image's own ownership, not a runtime check, since 2026-11-05 (D6) (T37)"

**Location:** `docs/working/plan-build-loop-handoff.md:167`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the absolute path and the absent ownership check; does not establish the image's modes at runtime beyond the Dockerfile lines and the current `/opt` listing.

`scripts/d6.sh:34` is `D6_OPT=/opt/claude-workflows` and `:60` runs `bash "$D6_OPT/scripts/$s"`. `devcontainer-config/Dockerfile:525` reads `chown -R root:root /opt/claude-workflows`. T37's first case passed un-skipped against the real `/opt` in E2.

**Evidence:** `scripts/d6.sh:34`, `scripts/d6.sh:60`, `devcontainer-config/Dockerfile:525-528`, `test/scripts/build-loop-orchestrator.bats:392-398`, FC3/bats-d6.log

---

## Claim 5: T33 "runs the image copy's four files (build-loop.sh and dev-cycle.sh with their own lib, dev-cycle.sh with its own `questions.sh`); main's and the working tree's copies have no effect; SKILL.md states the one-line call once"

**Location:** `docs/working/plan-build-loop-handoff.md:408`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed property through the T33 tests; does not establish the "own lib" part for `questions.sh`, which sources no lib.

The test plants `echo main copy; exit 9` and `echo working copy; exit 9` in all four paths (`test/scripts/build-loop-orchestrator.bats:316-319`), then checks every stderr line equals `lib at $U/scripts/lib/dev-cycle-read.sh` (`:324`). The one-line count is `:275`. Both passed in E2.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:273-282`, `test/scripts/build-loop-orchestrator.bats:313-330`, FC3/bats-d6.log

---

## Claim 6: T36 "not exactly one of main and master, a repository git cannot read, an image file missing or not a regular file, an image lib that does not load, another first argument → d6.sh refuses before running anything; a replace ref or `info/grafts` no longer refuses"

**Location:** `docs/working/plan-build-loop-handoff.md:411`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed case; the test's "cannot read" fixture is a directory that is no repository, and the case of a real repository with a junk `HEAD` was this pass's probe, not a test.

E4 with a junk `.git/HEAD`: `rc=2 out=refuse d6: refs/heads/main could not be read`. The five mutants against these refusals failed test 6 alone (Evidence). The "no longer refuses" half lives in the separate test at `:352`, not under a T36 tag.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:332-350`, `test/scripts/build-loop-orchestrator.bats:352-366`, FC3/probe2.log, FC3/bats-d6.log

---

## Claim 7: T37 "d6.sh runs the real `/opt` copy (skipped without one), not main's; a missing file → refuse (a uid-owned stub dir no longer refuses ...)"

**Location:** `docs/working/plan-build-loop-handoff.md:412`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pre-release path, where a temp copy of d6.sh runs against the real `/opt`; does not cover the branch that runs `/opt`'s own d6.sh, which cannot run until an image holds it.

`test/scripts/build-loop-orchestrator.bats:396` reads `d6_copy "$O"; [[ ! -f "$O/scripts/d6.sh" ]] || D6="$O/scripts/d6.sh"; d6 build-loop.sh --help`. Every test but T37's first runs on a uid-owned stand-in, so "no longer refuses" is exercised throughout. E1 also ran the worktree's unedited d6.sh: `same-as-image`, `differs-from-wt`.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:392-404`, FC3/probe1.log, FC3/bats-d6.log

---

## Claim 8: Design 1's table: `scripts/d6.sh` "already a payload item, `.sh` is 0555"; `bin/d6` "no suffix, so 0444 unless the Dockerfile changes"; both pruned options touch enforcement files

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:48`
**Type:** Configuration
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the payload list, the two chmod lines and the enforcement regex; does not establish a built image holding d6.sh, which needs a release.

`devcontainer-config/install.sh:146` reads `CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)`. `devcontainer-config/Dockerfile:527-528` makes every file 0444, then `-name '*.sh' -o -name '*.py'` 0555. The gate's regex names both changed files: `enforcement='^devcontainer-config/(Dockerfile|devcontainer\.json|init-firewall\.sh|cc-sni-proxy\.py|link-claude-home\.sh|cc-isolated\.sh|install\.sh$|egress/)'` (`hooks/live-verify-gate.sh:83`). S8 reads `no growth of the 500-plus-line files (`cc-isolated.sh`, `install.sh`)` (`docs/constraints.md:22`). `git ls-files -s` gives mode 100755 for `scripts/d6.sh`.

**Evidence:** `devcontainer-config/install.sh:146`, `devcontainer-config/Dockerfile:525-528`, `hooks/live-verify-gate.sh:83`, `docs/constraints.md:22`

---

## Claim 9: "One option dominates: it alone needs no enforcement-file change, and it ships in the same payload as the skill."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:53`
**Type:** Architectural
**Verdict:** Mostly accurate
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the sentence against its own table; does not reopen the choice, which stands on the scrub and default-branch grounds.

The table's fourth option needs none either: `| No wrapper: `bash /opt/.../scripts/SCRIPT` | nothing new | loses R6f's scrub (KEEP) and the default-branch check on two scripts | pruned |` (`:51`). "Alone" holds among the three wrapper options. Precise version: "of the options that keep the scrub, it alone needs no enforcement-file change". The call-form sentence after it holds: E1 printed `zsh:1: no such file or directory: ...` for a bare path under zsh, `bash: line 1: ...` under bash, and `bash: /opt/...: No such file or directory` for `bash PATH` under zsh.

**Evidence:** `docs/working/research-2026-11-05-d6-block-into-image.md:48-53`, FC3/probe1.log

---

## Claim 10: "D6_OPT stays a literal ... A test pins the literal and forbids `BASH_SOURCE`, `$0` and `dirname`."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:55`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the literal, the test's grep and one mutant; the grep skips comment lines by design and does not see other ways of deriving a path.

`test/scripts/build-loop-orchestrator.bats:279-280` pins `^D6_OPT=` to one line and greps non-comment lines for `BASH_SOURCE|\$0|dirname`. The mutant `opt-from-env` failed test 1. E1 with `D6_OPT=/nonexistent` in the environment ran the stand-in normally, rc 0.

**Evidence:** `scripts/d6.sh:34`, `test/scripts/build-loop-orchestrator.bats:277-280`, FC3/probe1.log, FC3/probe2.log

---

## Claim 11: R6c replace ref: "The gate's git ignores it (the probe above); `git_harden` sets both pins. The refusal stopped a repo for a ref nothing reads."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:63`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the gate's git and the orchestrator's plain git; does not rate an honest replace ref's effect on any one plain-git read.

The first two sentences hold (Claim 3). "Nothing reads" is too wide: the orchestrator's own git is plain since brief `2026-11-01-relax-dev-cycle-skill-prose`, and step 0.2 reads the last record `with `git -C MAIN_WT ls-tree` and read with `git -C MAIN_WT show`` (`skills/dev-cycle/SKILL.md:259`). E1's plain `git show` printed the replacement, `plain show: R`. `questions.sh` also runs unhardened, but its only git calls are `rev-parse` (`scripts/questions.sh:84`, `:88`). Precise version: "a ref no gate read follows".

**Evidence:** `skills/dev-cycle/SKILL.md:73`, `skills/dev-cycle/SKILL.md:259`, `scripts/questions.sh:84-88`, FC3/probe1.log

---

## Claim 12a: R6c `info/grafts`: "hardened git does follow grafts ... `--state` dropped it (unit 1, G5) and that research accepts the residual; git has deprecated the file and prints a hint on reading one"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:64`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git in the real repository under `git_harden`, `--state` and the hint; "hardened git" does not extend to the gate repository, which is Claim 12b.

E5: `real repo, git_harden: 2 commits` of 3 with the graft. E1: `--state` answered `ok` with the graft, and the hint read `Support for <GIT_DIR>/info/grafts is deprecated`. `docs/working/research-2026-11-01-relax-gate-git-state.md:31` reads `grafts: hostile-only`, and the audit lists `REMOVE: G4 G5 ...` (`docs/working/research-2026-11-01-restriction-audit.md:369`).

**Evidence:** `docs/working/research-2026-11-01-relax-gate-git-state.md:31`, `docs/working/research-2026-11-01-restriction-audit.md:369`, FC3/probe1.log, FC3/probe3.log

---

## Claim 12b: "honest use is a deliberate history splice that everything then reads consistently"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:64`
**Type:** Behavioral
**Verdict:** Incorrect
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the first-parent history as read in the real repository and in the gate repository; does not establish what an honest graft would break in a run, and the decision to drop the check does not rest on this clause alone.

The gate's history reads and the real repository's disagree under a graft. `gate_repo` builds its own git directory and shares only the objects:

```bash
# scripts/build-loop.sh:1069-1072
    && [[ "$fmt" == sha1 || "$fmt" == sha256 ]] && mkdir "$GATE_TMP/git" "$GATE_TMP/git/refs" "$GATE_TMP/work" || return 1
  printf 'ref: refs/heads/none\n' > "$GATE_TMP/git/HEAD"
  printf '[core]\n\trepositoryformatversion = 1\n[extensions]\n\tobjectformat = %s\n' "$fmt" > "$GATE_TMP/git/config"
  GATE_ENV+=(GIT_DIR="$GATE_TMP/git" GIT_OBJECT_DIRECTORY="$v")
```
(excerpt ends :1072; enclosing gate_repo() ends :1073 — read)

E5, same three commits, one cut: `real repo, plain: 2 commits`, `real repo, git_harden: 2 commits`, `gate-shaped repo (gate_repo's layout), git_harden: 3 commits, stderr bytes 0`. So `gate_git`'s reads (`--main-log`, merge bases, `:1121`, `:1412`, `:1870`, `:2291`) see the true history, while dev-cycle.sh's `git log` (`scripts/dev-cycle.sh:262`, `:265`) and the orchestrator's plain git see the splice. Say that the gate's merge and history reads ignore the graft and the digest and plain git follow it.

**Evidence:** `scripts/build-loop.sh:1064-1082`, `scripts/build-loop.sh:1870`, `scripts/dev-cycle.sh:262-265`, FC3/probe3.log

---

## Claim 13: R6d: exactly-one is "the only such check `dev-cycle.sh` and `questions.sh` have"; symbolic and non-commit: "`default_gate` refuses both in `--state` ... a new test pins it through d6 ..., and `--state` opens every iteration"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:65`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both scripts' lack of a default-branch refusal and `--state`'s two refusals; does not establish refusal for an iteration that skips step 0.1, which the skill does not allow.

`scripts/dev-cycle.sh` has no `state_gate` or `default_gate` (paraphrased — no quote available because the claim covers absence: grep found none), and `resolve_main` takes the first candidate that resolves (`scripts/lib/dev-cycle-read.sh:554-561`). E1 ran through d6 on a symbolic main: `--state` gave `refuse state default-branch: refs/heads/main is a symbolic ref`, and `dev-cycle.sh` gave rc 0. `skills/dev-cycle/SKILL.md:211` puts `--state` first.

**Evidence:** `scripts/build-loop.sh:764-790`, `scripts/lib/dev-cycle-read.sh:548-570`, `skills/dev-cycle/SKILL.md:211`, FC3/probe1.log

---

## Claim 14: R6e: "file present, regular, not a symlink" kept; ownership walk: "a uid able to write `/opt` rewrites d6.sh too ... The Dockerfile's chown and chmod hold H1 (pinned in `test/cc-isolated-functions.bats`). It also refused a run as root."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:67`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the kept check, the pins and the old block's own comment on root; a run as root was not executed.

E1 refused a symlink to a good file with `is not a regular file`, and the mutant `symlink-allowed` failed test 6. `test/cc-isolated-functions.bats:778-785` greps the chown and both chmod lines. The old block's header read `the -w test makes a run as root refuse unless the mount is read-only` (`git show 5b20d4bd:skills/dev-cycle/SKILL.md`).

**Evidence:** `scripts/d6.sh:45-49`, `test/cc-isolated-functions.bats:778-785`, FC3/probe1.log, FC3/probe2.log

---

## Claim 15: Design 3: "d6.sh's only git call is now `show-ref`, run through the image lib's `git_harden` in a subshell ..., so nothing is exported to the script."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:74`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers d6.sh's own git calls and what the child inherits; does not cover what the child scripts then export themselves.

`scripts/d6.sh:38` reads `g() { ( harden && git "$@" ); }` and `:55` is its one caller. E4 listed the same `GIT_` names reaching `questions.sh` with and without d6. The mutant `harden-leaks` failed test 8.

**Evidence:** `scripts/d6.sh:37-38`, `scripts/d6.sh:55`, FC3/probe2.log

---

## Claim 16: Design 4's table: old skill with new image "Works: the block's four files stay in the image"; new skill with old image: "`bash` prints `/opt/claude-workflows/scripts/d6.sh: No such file or directory`, exit 127, empty stdout, nothing ran"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:82`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old block run on today's image, whose layout the new image keeps, and the live 127; no image with d6.sh exists here, so the new-new row and a real new image under the old block were not run.

E4 extracted the old block from 5b20d4bd (56 lines) and ran it on the real image: `rc=0`, first line of `--help`. E1 is the live 127 (Claim 1). The home `skills` link resolves to `/opt/claude-workflows/skills`, as the "one payload" rows assume. H2's quoted wording is in the constraint: `a missing dependency ... refuses and names what went unenforced` (`docs/constraints.md:6`), and "a missing script refuses and names the gap" is its paraphrase.

**Evidence:** `docs/working/research-2026-11-05-d6-block-into-image.md:78-87`, `docs/constraints.md:6`, FC3/probe1.log, FC3/probe2.log

---

## Claim 17: Pre-mortem 1 and 2: a working-tree `bash scripts/d6.sh` "still runs the image's scripts"; "D6_OPT is assigned, never read. BASH_ENV applies to `bash d6.sh` as it did to `bash -s` ... The scrub is pinned by a new test."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:100`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an unedited working-tree copy, BASH_ENV under both forms and the scrub test; an edited working-tree copy is a different script and out of scope.

E1: `same-as-image`, `differs-from-wt`, and `BASHENV-RAN` printed under both `bash FILE` and a `bash -s` heredoc. Mutants `scrub-watching` and `scrub-bash-env` failed test 4.

**Evidence:** `scripts/d6.sh:34`, `scripts/d6.sh:60`, `test/scripts/build-loop-orchestrator.bats:306-311`, FC3/probe1.log, FC3/probe2.log

---

## Claim 18: Pre-mortem 3: "the image's floor does not list `scripts/d6.sh`, so a self-merge naming it in `Paths:` would pass unflagged ... the `image-lag` entry this merge opens lists every changed path outside `docs/` ... the cycle can add `scripts/d6.sh` to `Self-merge never:` ... The security review rated the window Medium."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:102`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the real image's verdict with the never line unset and set, the entry's wording and the rating; the never line was tried as the one entry `scripts/d6.sh`, and pass i2 tried it beside another glob.

`/opt/claude-workflows/scripts/lib/dev-cycle-read.sh:2017` reads `GATE_CODE='^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'`. E6, real image: never none, `old-image --merge rc=0`; never `scripts/d6.sh`, `old-image --merge rc=2` with `deny ... A scripts/d6.sh: matched by scripts/d6.sh in the Self-merge never: line`. `skills/dev-cycle/SKILL.md:237` reads `every path changed from C to M outside `docs/` on one line`. `docs/reviews/security-review-2026-11-05-d6-block-into-image.md:9` reads `One Medium (a window the design already states`.

**Evidence:** `skills/dev-cycle/SKILL.md:228-240`, `docs/reviews/security-review-2026-11-05-d6-block-into-image.md:9`, FC3/probeB.log

---

## Claim 19: Pre-mortem 4: "The 127 path has empty stdout ... The Rules state it, step 1b's 'if either fails, go on' names it as still a stop, and a test pins those phrases. Step 0.1 comes first in every iteration"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:103`
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the live 127, the pinned phrases and the order of steps; the one error is the step's name, and no behaviour depends on it.

The behaviour holds (Claims 16, 38), but the phrase is not in step 1b. `If either fails, note it in the record and go on:` is `skills/dev-cycle/SKILL.md:357`, under `### 1. Health and cleanup` (`:320`); `### 1b. Migrations` starts at `:377`. Say "step 1's".

**Evidence:** `skills/dev-cycle/SKILL.md:320`, `skills/dev-cycle/SKILL.md:354-359`, `skills/dev-cycle/SKILL.md:377`, `test/scripts/build-loop-orchestrator.bats:300-303`, FC3/probe1.log

---

## Claim 20: Pre-mortem 5: "exit 1 in the loop comes from `show-ref`. That exit also covers a ref git cannot use (a junk file, a dangling symbolic ref, an unreadable file): it counts as absent, as it did in the block. Beside a good name that passes; alone it refuses as 'not exactly one'. A test proves no pair reaches the script and every git call carries the pins."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:104`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three broken-ref shapes beside a good main, junk alone, and the old block's `&&` form; "the pins" in that test is a sample of 3 of 7 config pairs and 3 of 7 variables, the full lists being pinned on `git_harden` by the test at `:406`.

E1: junk, dangling and unreadable `master` beside `main` each gave rc 0; junk `main` alone gave `refuse d6: the default branch is not exactly one of main and master`. The old block read `g show-ref --verify -q "refs/heads/$n" && m+="$n "`, which treats any failure as absent. `test/scripts/build-loop-orchestrator.bats:375` loops `core.hooksPath=/dev/null core.fsmonitor=false core.useReplaceRefs=false G=/dev/null P=none S=1`.

**Evidence:** `scripts/d6.sh:50-59`, `test/scripts/build-loop-orchestrator.bats:368-377`, `test/scripts/build-loop-orchestrator.bats:406-419`, FC3/probe1.log

---

## Claim 21: "A planted `info/grafts` now reaches `--main-log`." (and option [1]: "a planted graft reaches `--main-log`: hostile-only, S1")

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:105`
**Type:** Behavioral
**Verdict:** Incorrect
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `.git/info/grafts` against `--main-log`'s listing and its per-commit class, at both places it is said (`:105`, `:117`); does not establish every real-repository read a graft does reach, of which the sites below are those a grep found, read but not each run; the "hostile-only" label and the decision to drop the check stand.

`--main-log` reads history only through `gate_git`:

```bash
# scripts/build-loop.sh:1870-1871
  gate_git rev-list --first-parent "$MAIN_SHA" > "$GATE_TMP/fp" \
    || { echo "main $MAIN_SHA -"; echo "refuse main-log: the default branch's first-parent history could not be listed"; return 1; }
```
(excerpt ends :1871; enclosing main_log() continues to :1883 — read)

`log_class` reads each commit the same way: `gate_git cat-file commit "$c" > "$GATE_TMP/c"` (`:1835`), and takes its parents from that text (`:1836`). That repository has no `info/` (Claim 12b).

E5 with a graft cutting the root off main. Real-repository git lists 2 commits, so the root is off first-parent history; `--main-log ROOT` still accepts it, byte for byte as with no graft, stderr empty:

```
main c56ff79fc634f64bbe94b1cdbfb4ed2bc7bb865b 2
other 4307c20eb1eeca86f0704ff82dafacc7ec67303b two
other c56ff79fc634f64bbe94b1cdbfb4ed2bc7bb865b three
```

The control shows the refusal is live: a SINCE truly off first-parent gave `refuse main-log: ... is not on the default branch's first-parent history`. `git replace --graft` gave the same three lines, as the gate repository has no refs.

What a graft does reach is reads in the real repository: dev-cycle.sh's `git log` (`scripts/dev-cycle.sh:262`, `:265`), the lib's (`scripts/lib/dev-cycle-read.sh:486-487`, `:512`), `marker_kind`'s `git rev-list --parents -n 1` (`scripts/build-loop.sh:907`), `merge-base` at `:1692` and `:2016`, and the orchestrator's plain git. Replace `--main-log` with those in both sentences. The first pass's Claim 24 and `docs/reviews/security-review-2026-11-05-d6-block-into-image.md:103` carry the same sentence.

**Evidence:** `scripts/build-loop.sh:1064-1082`, `scripts/build-loop.sh:1832-1836`, `scripts/build-loop.sh:1867-1883`, `docs/working/research-2026-11-05-d6-block-into-image.md:117`, FC3/probe3.log, FC3/probe2.log

---

## Claim 22: "d6.sh (plan D6; Q-140 [1]): the one way the orchestrator runs build-loop.sh (the gate), dev-cycle.sh (the digest) and questions.sh. The dev-cycle skill calls the root-owned image copy by absolute path: cd CHECKOUT && bash /opt/claude-workflows/scripts/d6.sh SCRIPT ARG..."

**Location:** `scripts/d6.sh:2`
**Type:** Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the skill's stated rule and call line; it is a rule the orchestrator follows, not something a mechanism forces.

`skills/dev-cycle/SKILL.md:36-39` states it: `Every `build-loop.sh`, `dev-cycle.sh` and `questions.sh` call runs from WT ... as this one line`, then `cd WT && bash /opt/claude-workflows/scripts/d6.sh SCRIPT ARG...`.

**Evidence:** `skills/dev-cycle/SKILL.md:36-41`

---

## Claim 23: "It always runs the root-owned image copy under D6_OPT by absolute path, never main's copy, a working-tree copy or ~/.claude/scripts, so no repository data chooses which script runs (Q-140: ...). D6_OPT is a literal, never read from the environment or from this file's own path: a working-tree copy of this file still runs the image's scripts."

**Location:** `scripts/d6.sh:6`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which script path is run, with main's and the working tree's copies planted, the environment set and an unedited working-tree d6.sh; dev-cycle.sh's fallback to `~/.claude/scripts/questions.sh` is unreachable through d6, which requires the image's copy first.

`scripts/d6.sh:60` is the one exec; the fallback is `[[ -f "$QS" ]] || QS="$HOME/.claude/scripts/questions.sh"` (`scripts/dev-cycle.sh:385`). The parenthesis matches Q-140's text in `docs/working/questions-archive.md`: `a loop that moves main onto a copy ... a loop that rewrites the orchestrator worktree's `.git` file`. Runs: Claims 5, 10, 17.

**Evidence:** `scripts/d6.sh:34`, `scripts/d6.sh:60`, `scripts/dev-cycle.sh:384-385`, FC3/probe1.log, FC3/bats-d6.log

---

## Claim 24: "It still trusts that entry and the default branch's ref for which repository and branch the script reads (a moved main is --main-log's to report), and it cannot guard against this uid's own shell (PATH, exported functions): the plan's same-uid residual (Q-103)."

**Location:** `scripts/d6.sh:12`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an exported `git` function and the reading of cwd's repository; a PATH `bash` was not run, and it follows from the same bare-name lookup.

E1 with `git` exported as a function: `FUNC-GIT` twice, then d6's refusal, so the function replaced d6's git. `scripts/d6.sh:60` names `bash` and `env` bare.

**Evidence:** `scripts/d6.sh:38`, `scripts/d6.sh:60`, `docs/working/plan-build-loop-handoff.md:448`, FC3/probe1.log

---

## Claim 25: "In claude-workflows a gate change runs from the next image release. Run it from the checkout the script is to read (each step names MAIN_WT, WT or GT). Arguments: build-loop.sh, dev-cycle.sh or questions.sh, then that script's own."

**Location:** `scripts/d6.sh:15`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the skill's steps and the argument handling; steps that name no checkout inherit the Rules' default of WT rather than naming one.

`skills/dev-cycle/SKILL.md:37` reads `runs from WT (step 0's first two from MAIN_WT; step 7's self-merge from its GT)`. Step 0's first two are `:211` and `:256`, and the self-merge is `:598-601`, under `### 7. Collect`. `scripts/d6.sh:39-41` takes `$1` and shifts.

**Evidence:** `skills/dev-cycle/SKILL.md:37`, `skills/dev-cycle/SKILL.md:211`, `skills/dev-cycle/SKILL.md:256`, `skills/dev-cycle/SKILL.md:598-601`, `scripts/d6.sh:39-41`

---

## Claim 26: "Exit: the script's own status; 2 and one 'refuse d6: WHY' line on stdout, with nothing run, for an image-copy file that is missing or not a regular file (a partial image), an image lib that does not load or whose git_harden refuses the caller's environment, a default branch that is not exactly one of main and master, or a git read that exits above 1 (git may add a line on stderr); 1 for another first argument."

**Location:** `scripts/d6.sh:19`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every listed exit; "nothing run" means no gate script (the lib is sourced and `show-ref` may have run), and the two lib refusals also put bash's or `git_harden`'s line on stderr, which the parenthesis names only for git.

E1: script status `rc=42`; no argument and `nope.sh` rc 1, stdout empty; a bad first argument wins over a partial image; syntax-error lib, truncated lib and `GIT_CONFIG_COUNT=010` each one `refuse d6:` line, rc 2, with stderr such as `d6.sh: GIT_CONFIG_COUNT is not a plain decimal count`; non-repository `rc=2`, `fatal: not a git repository`. Mutants `no-exec-status`, `no-harden-trial`, `rc-above-1-ignored`, `dir-allowed` and `both-allowed` were each killed.

**Evidence:** `scripts/d6.sh:33-60`, `scripts/lib/dev-cycle-read.sh:338`, FC3/probe1.log, FC3/probe2.log

---

## Claim 27: "An image with no d6.sh at all prints nothing of this: bash exits 127 naming the path, which the skill's Rules read as this refusal."

**Location:** `scripts/d6.sh:24`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the live call on this image and the Rules' sentence; the observer of the failure is the orchestrator following the skill, so nothing mechanical reads the 127.

E1 live: `rc=127 stdout-bytes=0 stderr: bash: /opt/claude-workflows/scripts/d6.sh: No such file or directory`. `skills/dev-cycle/SKILL.md:47-49` reads `So does exit 127 with `bash`'s `No such file or directory` line naming d6.sh`.

**Evidence:** `skills/dev-cycle/SKILL.md:45-49`, FC3/probe1.log

---

## Claim 28: "Its git is the image lib's git_harden, in a subshell, so the script starts from the caller's environment, not with d6.sh's pairs."

**Location:** `scripts/d6.sh:26`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exported pairs and variables at the exec; the scrub's six names are the deliberate change to the caller's environment.

See Claim 15. Mutant `g-unhardened` failed test 8, so the pins are checked on the call, and `harden-leaks` failed it too, so the subshell is. E4's listing is identical with and without d6.

**Evidence:** `scripts/d6.sh:37-38`, `test/scripts/build-loop-orchestrator.bats:368-377`, FC3/probe2.log

---

## Claim 29: "These checks come before, not instead of, build-loop.sh's own state and default-branch gates in its gated modes, which also refuse a symbolic or non-commit default branch (dev-cycle.sh, questions.sh and the read modes have none; row 548 for dev-cycle.sh)."

**Location:** `scripts/d6.sh:27`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all eight gated modes by reading the dispatch and `--state`, `--main-log` and `--check` by running; `--check-constraints` also runs no gate and is not in `GATED`'s read list, but it exits at `:680` before any git, so it reads as a read mode.

The dispatch sends `state`, `main-log`, `cycle-diff`, `land-cycle` to `state_start` and `check`, `merge`, `start`, `prompt` to `gate_start` (`scripts/build-loop.sh:2315-2383`), and `state_start` opens with `default_gate || exit 2` (`:1293`). E1 on a symbolic main: `--state`, `--main-log` and `--check` refused, `--settings` rc 0, `dev-cycle.sh` rc 0; on a tag main `--state` and `--main-log` gave `names an object that is not a commit`. Row 548 is `| 548 | dev-cycle.sh runs no state_gate/default_gate |` (`docs/reviews/api-consistency-review-2026-10-12-u3b3-final.md:81`).

**Evidence:** `scripts/build-loop.sh:680`, `scripts/build-loop.sh:798-801`, `scripts/build-loop.sh:1292-1300`, `scripts/build-loop.sh:2315-2383`, FC3/probe1.log

---

## Claim 30: "What it no longer checks, and why, is rows R6c to R6e of the restriction audit, in docs/working/research-2026-11-05-d6-block-into-image.md."

**Location:** `scripts/d6.sh:31`
**Type:** Reference
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the table exists at that path; the table's content is Claims 11-14.

`docs/working/research-2026-11-05-d6-block-into-image.md:61-68` is the table, with rows R6c, R6d and R6e.

**Evidence:** `docs/working/research-2026-11-05-d6-block-into-image.md:61-68`

---

## Claim 31: "The four files the scripts run (build-loop.sh and dev-cycle.sh source the lib from their own directory; dev-cycle.sh runs questions.sh beside it). lib/migrations.sh is left out: both scripts check it themselves before use."

**Location:** `scripts/d6.sh:42`
**Type:** Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `source` in both scripts and a run with migrations.sh removed; `questions.sh` sources nothing.

`scripts/dev-cycle.sh:97` is `READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"`, `:384` is `QS="$SCRIPT_DIR/questions.sh"`, and `:576` is `MIG_LIB="$SCRIPT_DIR/lib/migrations.sh"`. `scripts/build-loop.sh:2067` checks it before `:2071` sources it. E1 with the file gone: d6 rc 0, and the digest printed `**Migrations were NOT checked** — lib/migrations.sh is missing beside this script`.

**Evidence:** `scripts/dev-cycle.sh:92-100`, `scripts/dev-cycle.sh:576-584`, `scripts/build-loop.sh:2067-2072`, FC3/probe1.log

---

## Claim 32: "Tried alone first, so that exit 1 below comes from show-ref, which counts as absent a ref it cannot use (a junk or dangling one), as the block did."

**Location:** `scripts/d6.sh:50`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order of the trial and the loop, and both shapes; a lib that changes between the trial and the loop is not modelled, the image being read-only.

`scripts/d6.sh:52` reads `( harden ) || no "$D6_OPT/scripts/lib/dev-cycle-read.sh did not load, or its git_harden refused this environment"`, before the loop at `:54`. Mutant `no-harden-trial` failed test 6. Runs: Claim 20. This closes i2's Claim 14b.

**Evidence:** `scripts/d6.sh:50-58`, FC3/probe1.log, FC3/probe2.log

---

## Claim 33: "scripts/d6.sh is the exception to what follows: it sources the image copy in a subshell for git_harden alone, with no -e and no ROOT_REAL."

**Location:** `scripts/lib/dev-cycle-read.sh:13`
**Type:** Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers d6.sh's options and use of the lib; the sentence before it ("sources it from its own directory") is true of the image copy only, and an unedited working-tree d6.sh sources the image's lib instead, by design.

`scripts/d6.sh:33` is `set -u -o pipefail`, and `:37` is `harden() { source "$D6_OPT/scripts/lib/dev-cycle-read.sh" && git_harden; }`, used only at `:38` and `:52`, both in subshells. The lib loads under `-u`, since E1's pass path ran.

**Evidence:** `scripts/d6.sh:33-38`, `scripts/d6.sh:52`, `scripts/lib/dev-cycle-read.sh:10-15`, FC3/probe1.log

---

## Claim 34: "(D6 runs both as gate code: rows 281, 495; d6.sh calls it in a subshell for its own git)"

**Location:** `scripts/lib/dev-cycle-read.sh:311`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the added clause; each subshell is a fresh `CALLER_COUNT`, so "once" in the sentence before it stays true of the two scripts only.

`scripts/d6.sh:38` as quoted in Claim 15. E2's test 8 counts two git calls, both carrying the sampled pins.

**Evidence:** `scripts/d6.sh:37-38`, `scripts/lib/dev-cycle-read.sh:335-344`, `test/scripts/build-loop-orchestrator.bats:368-377`, FC3/bats-d6.log

---

## Claim 35: "The scripts because the image copy ... runs every merge after the next release ...; scripts/d6.sh because it runs the gate; skills/dev-cycle/ because its SKILL.md states the call (U4c; plan D4, F52). Both reach a session only from a release"

**Location:** `scripts/lib/dev-cycle-read.sh:1031`
**Type:** Architectural
**Verdict:** Mostly accurate
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the comment and the GATE_CODE list it explains; the one issue is a count word.

Each reason holds, and GATE_CODE matches: `^scripts/(build-loop|d6|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/` (`:1035`), with `scripts/d6.sh "$GATE"` passing the floor in E3 and the three restatements pinned in E2. The comment now gives three groups, so `Both` should be `All three`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1027-1035`, `scripts/build-loop.sh:454-457`, `skills/dev-cycle/SKILL.md:230`, `skills/dev-cycle/SKILL.md:618`, `test/scripts/build-loop-check.bats:262`, FC3/bats-floor.log, FC3/bats-d6.log

---

## Claim 36: Rules: "as this one line ... Never `~/.claude/scripts/`, a working-tree copy, or a `source`. In every repository, claude-workflows too, d6.sh is the root-owned image copy, and it runs the image's SCRIPT (Q-140 [1]), so no repository file or state a build loop writes chooses which script runs as the gate ... and a gate change merged here runs from the next image release"

**Location:** `skills/dev-cycle/SKILL.md:36`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the call form and the choice of script; "d6.sh is the root-owned image copy" holds after the release, as today's image has none (Claims 16, 27).

Runs: Claims 5, 7, 23. The residual sentence matches d6.sh's header (Claim 24).

**Evidence:** `skills/dev-cycle/SKILL.md:36-45`, FC3/bats-d6.log, FC3/probe1.log

---

## Claim 37: Rules: "`refuse d6: WHY` (exit 2; d6.sh's header lists them) or a usage line on stderr (exit 1, a first argument that is none of the three) means nothing ran."

**Location:** `skills/dev-cycle/SKILL.md:46`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both d6 exits; the later "any other exit (1 included)" sentence covers `build-loop.sh`'s answers and does not conflict, as both read as no decision.

Runs: Claim 26. An absent first argument also gives rc 1 with the usage line, and is "none of the three".

**Evidence:** `scripts/d6.sh:39-41`, `skills/dev-cycle/SKILL.md:45-52`, FC3/probe1.log

---

## Claim 38: The four 127 sites: "So does exit 127 with `bash`'s `No such file or directory` line naming d6.sh: that is the same refusal from an image older than this skill"; "a `refuse d6:` line or that exit 127, are stops too"; "the exit 127 above means an image older than this skill, and a `refuse d6:` naming a missing image file a partial image: either entry also gives the release paste below"; "a `refuse d6:` line, its exit 127 or a timed-out call is still a stop"

**Location:** `skills/dev-cycle/SKILL.md:47`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four sites at `:47`, `:54`, `:217-218` and `:358-359`, their agreement, the live exit and the test that pins them; prose read by an orchestrator, so no execution shows a session obeying them.

The bash line matches E1's live output. `refuse d6:` naming a missing file means a partial image, matching d6.sh's header `:20-21`. The "release paste below" exists at `:243-244`. `test/scripts/build-loop-orchestrator.bats:300-301` pins all four phrases, and that test passed in E2.

**Evidence:** `skills/dev-cycle/SKILL.md:47-54`, `skills/dev-cycle/SKILL.md:217-218`, `skills/dev-cycle/SKILL.md:243-244`, `skills/dev-cycle/SKILL.md:358-359`, `test/scripts/build-loop-orchestrator.bats:291-304`, FC3/probe1.log, FC3/bats-d6.log

---

## Claim 39: The helper comments: "the file itself, with one literal changed, runs in these tests"; "a uid-owned OPT stands in for the root-owned image, as d6.sh checks presence, not owner"; "main holds this branch's four scripts, and so does a stand-in at $U"; "In its real place beside the scripts, where the stand-in can hold it."; "d6.sh refused with exactly WANT, exit 2, before running anything"

**Location:** `test/scripts/build-loop-orchestrator.bats:247`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `d6_copy`, `d6_setup` and `d6_is`; `d6_is` accepts stderr only for "could not be read" refusals, which matches the header's parenthesis.

`:254` picks `$1/scripts/d6.sh` when that directory is writable, and a temp file otherwise (`/opt`). `:255-256` copies the file and changes one line. `:265` compares `$output` exactly, so any script output would fail it.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:247-265`, FC3/bats-d6.log

---

## Claim 40: Title "SKILL.md states d6.sh's one-line call once, by absolute path, with no pasted block; d6.sh names no other copy to run: no root test, no read of main's scripts" and comment "Where the image copy is comes from one literal, never the environment or the file's own path."

**Location:** `test/scripts/build-loop-orchestrator.bats:273`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the greps; the "no read of main's scripts" half is the pattern list, with the behaviour proved by T33.

Lines `:275-281` check each. Mutant `opt-from-env` failed this test.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:273-282`, FC3/probe2.log, FC3/bats-d6.log

---

## Claim 41: Title "d6.sh reaches the image with no installer or Dockerfile change: scripts/ is a payload item, and a .sh file is made 0555"

**Location:** `test/scripts/build-loop-orchestrator.bats:284`
**Type:** Configuration
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two source lines; no image was built, and the branch's diff touches neither file.

The test greps `^CLAUDE_HOME_SRC=\(.* scripts\)$` and the chmod line, which match Claim 8's quotes. Neither `install.sh` nor `Dockerfile` is in the diff stat.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:284-289`, FC3/bats-d6.log

---

## Claim 42: Title "the skill's d6 call on an image with no d6.sh (an image older than the skill): exit 127, bash names the path, nothing runs, and the Rules read it as a refusal"

**Location:** `test/scripts/build-loop-orchestrator.bats:291`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skill's own call words run on a stand-in with no d6.sh; the `cd WT &&` prefix is not part of the extracted words.

`:293` reads the call from SKILL.md, `:297` runs it with `run -127`, and `:298` checks empty stdout, the path and no `ran` file.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:291-304`, FC3/bats-d6.log

---

## Claim 43: Title "d6.sh scrubs the caller's variables and closes stdin before it runs the image's script; a caller's stdin never reaches it"

**Location:** `test/scripts/build-loop-orchestrator.bats:306`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all six variables and piped stdin; BASH_ENV is `/dev/null` in the test, so the value's effect on d6.sh's own bash is not tested (Claim 17 ran that).

Mutants `stdin-open`, `scrub-watching` and `scrub-bash-env` each failed this test alone.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:306-311`, FC3/probe2.log

---

## Claim 44: Title "d6.sh runs the image copy's scripts by absolute path, with the image's own lib and questions.sh, never main's or the working tree's", comments "main and the working tree each hold scripts that say where they ran; the image copy's lib says where it was sourced from." and "--state through d6.sh passes."

**Location:** `test/scripts/build-loop-orchestrator.bats:313`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test's four scripts in turn; as Claim 5.

Bodies quoted in Claim 5. `:326` asserts `[ "$output" = ok ]`.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:313-330`, FC3/bats-d6.log

---

## Claim 45: Title "d6.sh refuses before running anything: not exactly one of main and master, a repository git cannot read, an image file missing or not a regular file, another first argument", and comment "A lib that does not load, or a git_harden that refuses, is named as that, never as an absent branch."

**Location:** `test/scripts/build-loop-orchestrator.bats:332`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named case; the title's list is a subset, as the body also tests the lib refusals, and the plan's row now names them.

Mutants `no-harden-trial`, `rc-above-1-ignored`, `symlink-allowed`, `dir-allowed` and `both-allowed` each failed this test alone.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:332-350`, FC3/probe2.log

---

## Claim 46: Title "d6.sh runs the script past what audit rows R6c to R6e dropped: a replace ref, info/grafts, a symbolic or tag default branch, a uid-owned image; --state still refuses the two default-branch shapes", comments "A replace ref: no refusal, and the image's script runs." and "git refuses to update-ref a branch to a tag: write the ref file (row 656's case)."

**Location:** `test/scripts/build-loop-orchestrator.bats:352`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a blob replace ref, one graft file and both shapes under `--state`; the old test's commit replace ref is not carried over, and d6.sh has no replace logic that would tell the two apart.

`:356` and `:358` assert `status` 0 on `--settings`, which only the exec can give. `:361` and `:364` assert the two `refuse state default-branch:` lines. No new branch of d6.sh sits under these.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:352-366`, FC3/bats-d6.log

---

## Claim 47: Title "d6.sh's own git is hardened by the image lib's git_harden, and no pair reaches the script (T26, ...)" and "shim: a git ahead of the real one on PATH that logs each call's config pairs and environment (T26's)."

**Location:** `test/scripts/build-loop-orchestrator.bats:368`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both d6 git calls, the sampled pins and `GIT_CONFIG_COUNT`; the shim logs three variables, so "environment" means those, and T26 is the plan's hardening test named at `:150` and `:283`.

`:373` counts 2 calls and `:375` checks each line. Mutants `g-unhardened` and `harden-leaks` failed this test alone.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:266-270`, `test/scripts/build-loop-orchestrator.bats:368-377`, `docs/working/plan-build-loop-handoff.md:150`, FC3/probe2.log

---

## Claim 48: Title "a gate copy patched in the loop's worktree prints ok for its tip; d6.sh's image copy refuses the same tip (T27, U3b3)"

**Location:** `test/scripts/build-loop-orchestrator.bats:379`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the one patched rule in the test.

`:385-386` expects `ok`, and `:387-389` expects rc 2 and `deny $B A ?: not a path a checkout can hold` from d6.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:379-390`, FC3/bats-d6.log

---

## Claim 49: Title "d6.sh runs the root-owned image copy at /opt by absolute path, not main's copy (T37, U3b3)"

**Location:** `test/scripts/build-loop-orchestrator.bats:392`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers today's path, as in Claim 7; the test skips where no root-owned image exists, which `/opt` here is not.

The test ran, not skipped: `ok 10` in E2.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:392-398`, FC3/bats-d6.log

---

## Claim 50: Title "d6.sh refuses an image copy missing a file (a partial image), and never runs main's (T37, U3b3, U4c)"

**Location:** `test/scripts/build-loop-orchestrator.bats:400`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one missing file with a main copy present; T36 covers the others.

`:403` reads `rm "$U/scripts/build-loop.sh"; d6_is "refuse d6: $U/scripts/build-loop.sh is missing"`, and main's copy would print `main copy`.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:400-404`, FC3/bats-d6.log

---

## Claim 51: Title "git_harden exports HARDEN's pairs after the caller's and a fixed environment, once however often it is called" and comment "d6.sh repeats neither list: it runs the lib's git_harden (its own test above)."

**Location:** `test/scripts/build-loop-orchestrator.bats:406`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the full lists in the lib and d6.sh's non-comment lines for two sample names; the grep is a sample, and the file was read whole.

`:418` greps `^[^#]*(GIT_NO_REPLACE_OBJECTS|core\.hooksPath)` in d6.sh. "Its own test above" is `:368`, which comes first.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:406-419`, `scripts/d6.sh:33-60`, FC3/bats-d6.log

---

## Claims Requiring Attention

### Incorrect
- **Claim 21** (`docs/working/research-2026-11-05-d6-block-into-image.md:105`, `:117`): `--main-log` reads through `gate_git`, in a repository with no `info/`, so a graft does not reach it. Name the real-repository reads instead, in both sentences; `:117` is in the owner's option table.
- **Claim 12b** (`docs/working/research-2026-11-05-d6-block-into-image.md:64`): "everything then reads consistently" is false: the gate's reads ignore a graft, and the digest and plain git follow it.

### Stale
- None.

### Mostly Accurate
- **Claim 2** (`docs/working/plan-build-loop-handoff.md:151`, `:406`, `:431`): three live rows still say "snippet".
- **Claim 9** (`docs/working/research-2026-11-05-d6-block-into-image.md:53`): "it alone" also fits the no-wrapper row; say "of the options that keep the scrub".
- **Claim 11** (`docs/working/research-2026-11-05-d6-block-into-image.md:63`): "nothing reads" should be "no gate read follows": the orchestrator's plain git honours a replace ref.
- **Claim 19** (`docs/working/research-2026-11-05-d6-block-into-image.md:103`): the phrase is in step 1, not step 1b.
- **Claim 35** (`scripts/lib/dev-cycle-read.sh:1031`): "Both" now follows three groups.

### Unverifiable
- None.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to docs/reviews/code-fact-check-report-final-r1-2026-11-05-d6-block-into-image.md, first line `Commit: 1c5fd04f`, every claim tagged Legibility-target, ending with a Goal-Alignment Note (patterns/orchestrated-review.md). Do not commit.
- Answered: yes; every named claim was checked and run where it could be. Only T37's post-release branch and a real new image could not run.
- Out of scope: hostile-author cases (S1); the commit messages, including 2b0838bb's, per the dispatch; whether the graft residual should change the decision, which is the owner's.
- Escalate: Claims 12b and 21 before the owner answers the research doc's question, since `:117` misnames the residual; the first pass's Claim 24 and the security review's line 103 carry the same error, in the safe direction.
- Decisions I made: kept probe logs in scratch, as i1 and i2 did, since the dispatch allowed no other edit; the alternative was `docs/reviews/execution-logs/`. Left the hallucination log unedited, reading "reaches `--main-log`" as a wrong trace rather than a fabricated symbol; the alternative was to log it as a claimed behaviour.
