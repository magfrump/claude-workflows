Commit: 1c5fd04f

# Code Fact-Check Report

**Repository:** claude-workflows, worktree `.claude/wt-2026-11-05-d6-block-into-image`, branch `refactor/d6-block-into-image`
**Scope:** `git diff 5b20d4bd..1c5fd04f -- . ':!docs/reviews'` (9 files), the whole branch, plus the code that exercises each named claim
**Checked:** 2026-11-05
**Replication:** k=3 (final confirming pass, replicate r3)
**Total claims checked:** 68
**Summary:** 60 verified, 6 mostly accurate, 1 stale, 0 incorrect, 1 unverifiable

No claim is Incorrect, and every item the two earlier passes raised is fixed at this commit. The d6.sh header, the four 127 sites' behaviour, the plan rows F38, F39, T33, T36 and T37, the pre-mortem and every d6 test title match what the code does, by run.

Four residues are new to this pass. Each is wording, not behaviour:

- "a ref nothing reads" holds for the three scripts but not for the orchestrator's plain git (Claim 14).
- Option [2]'s steps leave the plan's amendment and rows false (Claims 29, 67). This one touches a choice put to the owner.
- Step 0.1's "either entry" names no entry for the 127 stop, which the Rules route to an agent work item (Claim 50).
- "it alone needs no enforcement-file change" is also true of the pruned no-wrapper option (Claim 10).

No claim in scope matches a pattern in `docs/reviews/hallucination-patterns.md`, and with no Incorrect verdict nothing qualifies for that log.

## Execution provenance

Each row ran under `timeout`. FC3 is `/tmp/claude-1000/-workspace/47403b7b-5fcb-4e13-8807-c539081df064/scratchpad/2026-11-05-d6-block-into-image/fc3-r3/`. Logs and probe scripts stay there because the dispatch allowed no edit but this report, so `docs/reviews/execution-logs/` was not used. Temp trees were removed by each probe, no probe of this pass is running, and nothing was added to the repository's worktree list (option [2] ran on `git archive` exports, the revert on a scratch clone). git is 2.39.5. The image at `/opt/claude-workflows` is commit c214970a and holds no `d6.sh`. Clock stamps are the sandbox's UTC.

| Id | Command | Cwd | Exit | Start (UTC) | Output |
|---|---|---|---|---|---|
| E1 | `timeout 120 bash probe1.sh` (HEAD's d6.sh with one literal changed: every refusal, broken refs and libs, working-tree copy, env, 127, zsh and bash, BASH_ENV, grafts and replace under git_harden) | FC3 | 0 | 2026-11-06T07:27:03Z | FC3/probe1.log |
| E2 | `TMPDIR=FC3/tmpD timeout 280 bats -f 'd6\|GATE_CODE\|git_harden' test/scripts/build-loop-orchestrator.bats` (15 of 15 ok, none skipped) | worktree | 0 | 2026-11-06T07:27:04Z | FC3/bats-head-d6.log |
| E3 | `TMPDIR=FC3/tmpD timeout 150 bats -f 'floor' test/scripts/build-loop-check.bats` (9 of 9 ok) | worktree | 0 | 2026-11-06T07:27:06Z | FC3/bats-head-floor.log |
| E4 | `timeout 560 bash probe2.sh` (d6.sh and the orchestrator tests from da07a77c over an export of HEAD: 14 of 15, then 15 of 15 with one phrase changed) | FC3 | 0 | 2026-11-06T07:27:07Z | FC3/probe2.log, FC3/bats-optionA.log, FC3/bats-optionA-patched.log |
| E5 | `timeout 400 bash probe3.sh` (the same over both test files, 16 of 16; `shellcheck -x -e SC1091 -s bash -S warning` at 2b0838bb and 9f80368a; the image's own build-loop.sh `--check` of a self-merge naming `scripts/d6.sh`) | FC3 | 0 | 2026-11-06T07:28:14Z | FC3/probe3.log, FC3/bats-optionA-wide.log, FC3/sc-2b0838bb-abs.log, FC3/sc-9f80368a-abs.log, FC3/bats-image-selfmerge.log |
| E6 | `timeout 100 bash probe4.sh` (`git revert --no-edit 2b0838bb` at HEAD on a scratch clone; the old pasted block run against the live root-owned image) | FC3 | 0 | 2026-11-06T07:29:59Z | FC3/probe4.log |

---

## Claim 1: "A change to the gate's own files (`scripts/{build-loop,d6,dev-cycle,questions}.sh`, ...) gets its own slug, `merge-gate-…`" and D5 item 3's "since brief `2026-11-05-d6-block-into-image` `scripts/d6.sh`"

**Location:** `docs/working/plan-build-loop-handoff.md:63`, `docs/working/plan-build-loop-handoff.md:73`
**Type:** Configuration
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers GATE_CODE, the floor and the gate flag that picks the slug; does not establish a run of `--approved` on a `scripts/d6.sh` path, which rests on the same regex at `:1485`.

`GATE_CODE='^scripts/(build-loop|d6|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'` (`scripts/lib/dev-cycle-read.sh:1035`), read at `[[ ! "${lps[$i]}" =~ $GATE_CODE ]] || gc=1` (`scripts/build-loop.sh:1485`). The floor test, whose list holds `scripts/d6.sh "$GATE"` (`test/scripts/build-loop-check.bats:262`), passed in E3.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1035`, `scripts/build-loop.sh:1485`, `test/scripts/build-loop-check.bats:262`, FC3/bats-head-floor.log

---

## Claim 2: The D6 amendment bullet ("no longer inline ... d6.sh keeps ... it drops ... Its git is the image lib's `git_harden` ... T33, T36 and T37 test the file; T37's uid-owned case and T36's replace and graft cases went, and a new case pins that d6.sh now passes them.")

**Location:** `docs/working/plan-build-loop-handoff.md:88`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed keep, drop and test against HEAD's d6.sh and tests; does not establish the release itself, since the image holds no d6.sh yet.

d6.sh keeps `have="${have% }"; [[ "$have" == main || "$have" == master ]] || no ...` (`scripts/d6.sh:59`), `[[ -f "$x" && ! -L "$x" ]] || no "$x is not a regular file"` (`:48`) and the six `env -u` names (`:60`). It holds no `for-each-ref`, `grafts`, `symbolic-ref`, `cat-file` or `stat` call (paraphrased — no quote available because the claim covers absence of code, and d6.sh's only git call is `:55`). Test `:352` is the new case; it passed in E2. "from one commit" rests on `Both targets install COMMITTED content (HEAD, via git archive)` (`devcontainer-config/install.sh:57`).

**Evidence:** `scripts/d6.sh:45-60`, `test/scripts/build-loop-orchestrator.bats:352-366`, `devcontainer-config/install.sh:57`, FC3/bats-head-d6.log

---

## Claim 3: F38 "`git_harden` ignores replace refs; d6.sh refuses a default branch that is not exactly one of main and master (T36 ...). Grafts are an accepted hostile-only residual"

**Location:** `docs/working/plan-build-loop-handoff.md:166`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git under `git_harden`, which build-loop.sh and dev-cycle.sh run; does not establish questions.sh, which is unhardened and reads no object, or the orchestrator's plain git (Claim 14).

E1 on a replaced blob: `replaced blob plain: fake`, `replaced blob hardened: real`. `[both] rc=2 stdout=<refuse d6: the default branch is not exactly one of main and master>`. The residual is stated at `docs/working/research-2026-11-05-d6-block-into-image.md:64`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:333-347`, `scripts/build-loop.sh:704`, `scripts/dev-cycle.sh:128`, FC3/probe1.log

---

## Claim 4: F39 "`/opt/...` by absolute path, in every repository (...); the image's own ownership, not a runtime check, since 2026-11-05 (D6) (T37)"

**Location:** `docs/working/plan-build-loop-handoff.md:167`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the absolute path and the absence of an ownership test; does not establish that the Dockerfile's chown ran on a future image, only that it is there and pinned.

`exec env ... bash "$D6_OPT/scripts/$s" "$@" </dev/null` (`scripts/d6.sh:60`), with `D6_OPT=/opt/claude-workflows` (`:34`). The chown is `chown -R root:root /opt/claude-workflows` (`devcontainer-config/Dockerfile:525`). T37's two tests passed in E2, the first against the real `/opt`.

**Evidence:** `scripts/d6.sh:34`, `scripts/d6.sh:60`, `devcontainer-config/Dockerfile:525-528`, `test/scripts/build-loop-orchestrator.bats:392-404`, FC3/bats-head-d6.log

---

## Claim 5: T27 "the D6 snippet's copy refuses the same tip"

**Location:** `docs/working/plan-build-loop-handoff.md:406`
**Type:** Staleness
**Verdict:** Mostly accurate
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the row's behaviour, which holds, and its name for the thing; does not cover history bullets such as `:338`, which rightly keep the old name.

The behaviour holds (test `:379` passed in E2), but the test now reads "d6.sh's image copy refuses the same tip" while the row keeps the old name, as does `| The gate runs a loop's bytes | D6 snippet; T27, T33, T36, T37 |` (`:431`). T33, T36 and T37 were renamed. Precise wording: "d6.sh's copy refuses the same tip" and "d6.sh; T27, ...".

**Evidence:** `docs/working/plan-build-loop-handoff.md:406`, `docs/working/plan-build-loop-handoff.md:431`, `test/scripts/build-loop-orchestrator.bats:379`, FC3/bats-head-d6.log

---

## Claim 6: T33 "runs the image copy's four files (build-loop.sh and dev-cycle.sh with their own lib, dev-cycle.sh with its own `questions.sh`); main's and the working tree's copies have no effect; SKILL.md states the one-line call once"

**Location:** `docs/working/plan-build-loop-handoff.md:408`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test at `:313` and the `-cxF` count at `:275`; does not establish dev-cycle.sh's lib by the path line, which the test reads only for `--settings`; for dev-cycle.sh it follows because main's and the working tree's libs `exit 9`.

Test `:313` overwrites all four files with `echo main copy; exit 9` and `echo working copy; exit 9`, then passes all of `--settings`, `--state`, `dev-cycle.sh` and `questions.sh open`.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:275`, `test/scripts/build-loop-orchestrator.bats:313-330`, FC3/bats-head-d6.log

---

## Claim 7: T36 "not exactly one of main and master, a repository git cannot read, an image file missing or not a regular file, an image lib that does not load, another first argument → d6.sh refuses before running anything; a replace ref or `info/grafts` no longer refuses"

**Location:** `docs/working/plan-build-loop-handoff.md:411`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed input by test and by E1; does not establish a commit replace ref, as the test now plants a blob one only.

E1: `[not-a-repo] rc=2 stdout=<refuse d6: refs/heads/main could not be read>`, `[lib-return1] rc=2`, `[lib-syntax] rc=2`, `[bad-arg] rc=1`. Tests `:332` and `:352` passed in E2.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:332-366`, FC3/probe1.log, FC3/bats-head-d6.log

---

## Claim 8: T37 "→ d6.sh runs the real `/opt` copy (skipped without one), not main's; a missing file → refuse (a uid-owned stub dir no longer refuses ...)"

**Location:** `docs/working/plan-build-loop-handoff.md:412`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both tests here, where a real `/opt` exists and the test ran rather than skipped; does not establish the test's post-release branch `D6="$O/scripts/d6.sh"`, which needs an image holding d6.sh.

`[[ -f "$O/scripts/build-loop.sh" && "$(stat -c %u "$O/scripts")" == 0 ]] || skip ...` (`test/scripts/build-loop-orchestrator.bats:394`). E2 shows `ok 10` with no skip directive, and `ok 11` for the missing file.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:392-404`, FC3/bats-head-d6.log

---

## Claim 9: Design 1's table: `scripts/d6.sh` "already a payload item, `.sh` is 0555"; `bin/d6` "no suffix, so 0444 unless the Dockerfile changes", "touches enforcement files"; `/usr/local/bin/d6` by `COPY` "outside the commit-pinned payload"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:48-51`
**Type:** Configuration
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the payload list, the chmod lines and the enforcement regex; does not establish a built image holding d6.sh.

`CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)` (`devcontainer-config/install.sh:146`). `find /opt/claude-workflows -type f -exec chmod 0444 {} +` then `-name '*.sh' -o -name '*.py' ... -exec chmod 0555` (`devcontainer-config/Dockerfile:527-528`). `enforcement='^devcontainer-config/(Dockerfile|...|install\.sh$|egress/)'` (`hooks/live-verify-gate.sh:83`). Test `:284` pins the first two and passed in E2; `scripts/d6.sh` is not in that regex, so the branch's commits need no trailer.

**Evidence:** `devcontainer-config/install.sh:146`, `devcontainer-config/Dockerfile:525-528`, `hooks/live-verify-gate.sh:83`, FC3/bats-head-d6.log

---

## Claim 10: "One option dominates: it alone needs no enforcement-file change, and it ships in the same payload as the skill."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:53`
**Type:** Architectural
**Verdict:** Mostly accurate
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the four rows of the table above it; does not reopen the choice, which stands because the no-wrapper row was pruned for another reason.

The table's fourth row, `No wrapper: bash /opt/.../scripts/SCRIPT | nothing new`, also needs no enforcement-file change and also ships in the payload. It lost on `loses R6f's scrub (KEEP) and the default-branch check on two scripts` (`:51`). Precise wording: "of the options that keep the scrub, it alone".

**Evidence:** `docs/working/research-2026-11-05-d6-block-into-image.md:48-53`

---

## Claim 11: "Its call is `bash PATH`, not a bare `PATH`: the same message under zsh and bash, and independent of the mode bit."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:53`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a missing path under both shells and a 0444 file; does not establish other shells.

E1, `bash /nonexistent/d6.sh x` under both: `bash: /nonexistent/d6.sh: No such file or directory`, `rc=127`. The bare path differs: bash `line 3: /nonexistent/d6.sh: No such file or directory`, zsh `no such file or directory: /nonexistent/d6.sh`. A 0444 copy: `[mode-0444-bash] rc=7` (it ran), bare `mode-0444-bare rc=126`.

**Evidence:** FC3/probe1.log, `docs/working/research-2026-11-05-d6-block-into-image.md:53`

---

## Claim 12: "D6_OPT stays a literal ... A test pins the literal and forbids `BASH_SOURCE`, `$0` and `dirname`."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:55`
**Type:** Invariant
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the file at HEAD and honest runs; does not establish anything against a same-uid BASH_ENV, the residual the header states.

`[ "$(grep -c '^D6_OPT=' "$S")" -eq 1 ] && grep -qxF 'D6_OPT=/opt/claude-workflows' "$S"` and the pattern ending `BASH_SOURCE|\$0|dirname` (`test/scripts/build-loop-orchestrator.bats:279-280`). E1: `D6_OPT=/evil` in the caller's environment still ran the stand-in's questions.sh (`[env-D6_OPT] rc=7`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:277-280`, `scripts/d6.sh:34`, FC3/probe1.log

---

## Claim 13: Design 2's framing: the brief's Goal against its criteria, the audit's unit rule, "restoring ... gives A, after updating one test phrase ... and two comments in the lib (a review probe: 16 of 16 filtered tests green with those)", and "a plain revert of the narrowing commit no longer applies alone"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:59`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers green tests under `-f 'd6|GATE_CODE|git_harden|image-lag'` over the two suites, and the revert; does not establish that documents stay true after restoring (Claim 29).

The brief reads `The block's checks keep running, now from that script` (`docs/working/briefs/2026-11-05-d6-block-into-image.md:10`) and `which of rows R6c, R6d and R6e keep their checks` (`:18`). The audit reads `records in its research doc any row it keeps after all` (`docs/working/research-2026-11-01-restriction-audit.md:47`). E4: restored tests fail one case, `# missing: a ${q}refuse d6:${q} naming a missing image file, or the exit 127 above, ...`; with that phrase changed, E5 gives `optionA wide patched exit 0 ok=16`. E6: `revert 2b0838bb alone at HEAD: exit 1`, with conflicts in `scripts/d6.sh` and the test file.

**Evidence:** `docs/working/briefs/2026-11-05-d6-block-into-image.md:10`, `docs/working/briefs/2026-11-05-d6-block-into-image.md:18`, `docs/working/research-2026-11-01-restriction-audit.md:47`, FC3/probe2.log, FC3/probe3.log, FC3/probe4.log

---

## Claim 14: "The gate's git ignores it (the probe above); `git_harden` sets both pins. The refusal stopped a repo for a ref nothing reads." and option [2]'s "a replace ref stops a repo for a ref nothing reads"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:63`, `docs/working/research-2026-11-05-d6-block-into-image.md:118`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three scripts (true) and the orchestrator's plain git (not true); does not rate the drop itself, which S1 and the plan's F51 row govern.

The first sentence and the mechanism hold: `HARDEN=(core.useReplaceRefs=false ...` and `GIT_NO_REPLACE_OBJECTS=1` (`scripts/lib/dev-cycle-read.sh:333`, `:343`). "Nothing reads" is too wide. The orchestrator's git is plain: `is plain `git -C PATH …`, with the user's normal config` and `H1 binds the gate's own git ... not these calls` (`skills/dev-cycle/SKILL.md:66-73`), and step 0.2 reads records with `git -C MAIN_WT show`. E1: `replaced blob plain: fake`, `replaced blob hardened: real`. Precise wording: "a ref none of the three scripts reads".

**Evidence:** `scripts/lib/dev-cycle-read.sh:333-343`, `skills/dev-cycle/SKILL.md:66-73`, FC3/probe1.log

---

## Claim 15: Grafts: "hardened git does follow grafts ... `--state` dropped it (unit 1, G5) ... git has deprecated the file and prints a hint on reading one"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:64`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 and build-loop.sh's text; does not establish the hint in later git versions.

E1, three commits and one cut: `graft plain 2`, `graft hardened 2`, each with `hint: Support for <GIT_DIR>/info/grafts is deprecated`; `replace-graft plain 2`, `replace-graft hardened 3`. `| G5 | info/attributes, grafts, shallow, alternates |` with `grafts: hostile-only` (`docs/working/research-2026-11-01-relax-gate-git-state.md:31`). `grafts` does not occur in `scripts/build-loop.sh` (paraphrased — no quote available because the claim covers absence of code; the grep returned nothing).

**Evidence:** `docs/working/research-2026-11-01-relax-gate-git-state.md:31`, FC3/probe1.log

---

## Claim 16: "H2: an ambiguous default, and the only such check `dev-cycle.sh` and `questions.sh` have."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:65`
**Type:** Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both scripts' source; does not cover build-loop.sh, which has its own.

`resolve_main` takes the first name found: `if [[ -n "$sha" ]]; then MAIN="$c"; MAIN_SHA="$sha"; MAIN_BY_NAME=1; break; fi` (`scripts/lib/dev-cycle-read.sh:560`), and neither script calls `default_gate` (paraphrased — no quote available because the claim covers absence of code; `grep default_gate scripts/dev-cycle.sh scripts/questions.sh` returned nothing).

**Evidence:** `scripts/lib/dev-cycle-read.sh:548-570`, `scripts/dev-cycle.sh:196`

---

## Claim 17: "`default_gate` refuses both in `--state` [observed: `scripts/build-loop.sh`; a new test pins it through d6], and `--state` opens every iteration."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:66`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--state` through d6.sh on a symbolic and a tag-valued main; does not establish a dangling symbolic main, which show-ref counts as absent (Claim 27).

`if git symbolic-ref -q "refs/heads/$MAIN" >/dev/null; then echo "refuse state default-branch: refs/heads/$MAIN is a symbolic ref"` and `... names an object that is not a commit` (`scripts/build-loop.sh:773-779`). Test `:352` passed in E2. `Start every iteration in this order` with `--state` first (`skills/dev-cycle/SKILL.md:208-211`).

**Evidence:** `scripts/build-loop.sh:765-790`, `test/scripts/build-loop-orchestrator.bats:358-364`, `skills/dev-cycle/SKILL.md:208-211`, FC3/bats-head-d6.log

---

## Claim 18a: "file present, regular, not a symlink" kept; ownership walk dropped; "The Dockerfile's chown and chmod hold H1 (pinned in `test/cc-isolated-functions.bats`)"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:67-68`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the symlink and directory cases and the grep pins; does not establish the pins as behaviour, since they read the Dockerfile's text.

Test `:332` plants a directory, a dangling link and a link to a real file; each gives `is not a regular file`, and it passed in E2. `run grep -E 'chown -R root:root /opt/claude-workflows' "$CONFIG_SRC/Dockerfile"` (`test/cc-isolated-functions.bats:778`), with the chmods at `:780`, `:785`.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:338-342`, `test/cc-isolated-functions.bats:778-785`, FC3/bats-head-d6.log

---

## Claim 18b: "It also refused a run as root."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:68`
**Type:** Behavioral
**Verdict:** Unverifiable
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the old block's text only; does not establish a run, because this sandbox has no root; the claim is about removed code and bears on nothing live.

The removed block's `own()` held `! -w "$1"`, and its header said `the -w test makes a run as root refuse unless the mount is read-only` (`git show 5b20d4bd:skills/dev-cycle/SKILL.md`). Execution required, blocked by the uid: a run as real root.

**Evidence:** `docs/working/research-2026-11-05-d6-block-into-image.md:68`

---

## Claim 19: "Dropping the walk also lets the tests run the shipped file with one literal changed and no `own()` substitution"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:70`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `d6_copy`; does not cover the 127 test, which needs no d6.sh at all.

`cp "$REPO_ROOT/scripts/d6.sh" "$D6"` then the one `sed -i "s|^D6_OPT=/opt/claude-workflows\$|D6_OPT=$1|" "$D6"` (`test/scripts/build-loop-orchestrator.bats:255-256`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:252-257`, FC3/bats-head-d6.log

---

## Claim 20: "d6.sh's only git call is now `show-ref`, run through the image lib's `git_harden` in a subshell ..., so nothing is exported to the script."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:74`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers d6.sh's own exports; does not establish a caller's exports, which pass through by design (`env-caller` below).

`g() { ( harden && git "$@" ); }` (`scripts/d6.sh:38`) and `g show-ref --verify -q "refs/heads/$n"` (`:55`). E1: `[env-none] rc=7 stdout=<count=unset k0=unset nr=unset>`; `[env-caller] rc=7 stdout=<count=1 k0=user.name nr=unset>`.

**Evidence:** `scripts/d6.sh:37-38`, `scripts/d6.sh:55`, FC3/probe1.log

---

## Claim 21: Design 4's four-row table (old/old, new/new, old block on a new image "Works", new skill on an old image: `bash` prints the path, "exit 127, empty stdout, nothing ran")

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:78-85`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old block on the live image, which holds the same four files a new one will, and the 127 path; does not establish a real new image.

E6 extracted the 56-line block from 5b20d4bd and ran it from a scratch repo: it passed the ownership walk and reached the image's questions.sh (`old block on the live image: exit 1`, stderr `✗ missing: .../docs/working/questions.md`, which is questions.sh's own message). E1: `[no-d6] rc=127 stdout=<> stderr=<bash: .../nod6.sh: No such file or directory>`. Row one's mechanism is the old PATHS line, which holds `skills/dev-cycle/` (`/opt/claude-workflows/skills/dev-cycle/SKILL.md`, by the GATE_CODE at `/opt/claude-workflows/scripts/lib/dev-cycle-read.sh:2017`).

**Evidence:** FC3/probe4.log, FC3/probe1.log, `skills/dev-cycle/SKILL.md:230`, `devcontainer-config/install.sh:57`

---

## Claim 22: "H2's 'a missing script refuses and names the gap' is met by that line and the Rules ... a state the payload makes unreachable through the installed skill."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:87`
**Type:** Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the installed skill in this container, a symlink into the image; does not establish a project-level skill copy in another repository.

`readlink` gives `/opt/claude-workflows/skills` and `/opt/claude-workflows/scripts` for the home directories, so skill and script come from one image. The test at `:291` pins the line and the Rules' phrases; it passed in E2.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:291-304`, FC3/bats-head-d6.log

---

## Claim 23: Pre-mortem 1: "The root is a literal, so it still runs the image's scripts; the reach is that copy's own pre-checks."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:100`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an unmodified working-tree copy; a copy with its literal edited is the hostile case, out of scope by S1.

E1: `[wt-copy] rc=7 stdout=<ran .../opt/scripts/questions.sh>`, with the working tree's `scripts/questions.sh` holding `echo WORKING TREE; exit 9`.

**Evidence:** `scripts/d6.sh:34`, FC3/probe1.log

---

## Claim 24: Pre-mortem 2: "D6_OPT is assigned, never read. BASH_ENV applies to `bash d6.sh` as it did to `bash -s` ... The scrub is pinned by a new test."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:101`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both invocation forms and all six names; "never read" means never read from the environment, not that the script does not use the value.

E1 prints `BASH_ENV-RAN` then `body` for both `bash FILE` and `bash -s`. Test `:306` sets all six and expects `live=unset arch=unset watch=unset scrub=unset env=unset benv=unset in=`; it passed in E2.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:306-311`, FC3/probe1.log

---

## Claim 25: Pre-mortem 3: the window, its bound, the remedy, "this branch may not edit that file", "The security review rated the window Medium."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:102`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the image's own build-loop.sh on a fixture brief and the image's skill text; does not establish a whole `--merge`, only the `--check` verdict that decides it.

The image's list is `GATE_CODE='^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'` (`/opt/claude-workflows/scripts/lib/dev-cycle-read.sh:2017`). E5 with the image's scripts: with `Self-merge never: none`, `status=0 output=[ok ...]` and `path ... A scripts/d6.sh`; with `Self-merge never: scripts/d6.sh`, `status=2` and `deny ... A scripts/d6.sh: matched by scripts/d6.sh in the Self-merge never: line of docs/dev-cycle.md`. The image's skill says `every path changed from C to M outside `docs/` on one` (`/opt/claude-workflows/skills/dev-cycle/SKILL.md:300`). `**Severity:** Medium` (`docs/reviews/security-review-2026-11-05-d6-block-into-image.md:44`). `docs/dev-cycle.md` sits on the floor as a cycle-owned file (`docs/working/plan-build-loop-handoff.md`, D5 item 4).

**Evidence:** FC3/bats-image-selfmerge.log, FC3/probe3.log, `docs/reviews/security-review-2026-11-05-d6-block-into-image.md:44`

---

## Claim 26: Pre-mortem 4: "The 127 path has empty stdout ... The Rules state it, step 1b's 'if either fails, go on' names it as still a stop, and a test pins those phrases. Step 0.1 comes first in every iteration"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:103`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the text and the pin; a test of prose cannot establish that an orchestrator obeys it.

`a ${q}refuse d6:${q} line, its exit 127 or a timed-out call is still a stop` is one of four phrases the loop at `test/scripts/build-loop-orchestrator.bats:300-303` requires, and it sits at `skills/dev-cycle/SKILL.md:358-359`. E1: `[no-d6] rc=127 stdout=<>`.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:300-303`, `skills/dev-cycle/SKILL.md:357-359`, FC3/probe1.log

---

## Claim 27: Pre-mortem 5: "so exit 1 in the loop comes from `show-ref`. That exit also covers a ref git cannot use (a junk file, a dangling symbolic ref, an unreadable file): it counts as absent, as it did in the block. Beside a good name that passes; alone it refuses as 'not exactly one'. A test proves no pair reaches the script and every git call carries the pins."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:104`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all three broken-ref shapes beside main, and a junk ref alone; "the pins" is three of seven HARDEN pairs and three environment variables in the test, though all seven apply by construction; "as it did" covers exit 1 only, since the block also counted exit 128 as absent, where d6.sh now refuses.

E1: `show-ref junk exit 1`, `show-ref dangling exit 1`, `show-ref unreadable exit 1`; each `[...-beside-good]` ran the script (`rc=1`, questions.sh's usage); `[junk-alone] rc=2 stdout=<refuse d6: the default branch is not exactly one of main and master>`. The block's line: `m=""; for n in main master; do g show-ref --verify -q "refs/heads/$n" && m+="$n "; done` (`git show 5b20d4bd:skills/dev-cycle/SKILL.md`). This item is fixed since i2's Claims 12b and 14b.

**Evidence:** `scripts/d6.sh:50-59`, `test/scripts/build-loop-orchestrator.bats:368-377`, FC3/probe1.log

---

## Claim 28: Pre-mortem 6: "A planted `info/grafts` now reaches `--main-log`. Hostile-only (S1); `--state` already accepted it in unit 1."

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:105`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers hardened `rev-list` and d6.sh's pass; does not run `--main-log` itself on a graft, which reads through the same git.

E1: `graft hardened 2` of three commits. Test `:352` writes `.git/info/grafts` and expects status 0 from d6.sh; it passed in E2.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:358`, FC3/probe1.log

---

## Claim 29: Option [2]: "restore `scripts/d6.sh` and the D6 tests from da07a77c, the move with every check kept, plus one test phrase and two lib comments"

**Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:118`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what turns tests green (one phrase, confirmed by E4 and E5) and which other text goes false; does not establish the full health check after restoring.

Code and tests are as stated: 16 of 16. The list stops short of the documents. After the restore these say the opposite of the code: the plan's `it drops the replace-ref and `info/grafts` refusals` (`docs/working/plan-build-loop-handoff.md:88`), F38's and F39's "since 2026-11-05" text (`:166-167`), T36's `a replace ref or `info/grafts` no longer refuses` (`:411`) and T37's `a uid-owned stub dir no longer refuses` (`:412`). Precise wording: add "and the plan's amendment and rows F38, F39, T36, T37". The owner's cost column ("one small branch") still fits, at about five more edits.

**Evidence:** `docs/working/plan-build-loop-handoff.md:88`, `docs/working/plan-build-loop-handoff.md:166-167`, `docs/working/plan-build-loop-handoff.md:411-412`, FC3/probe3.log

---

## Claim 30: build-loop.sh's two edits: "the lib's GATE_CODE: scripts/build-loop.sh, d6.sh, dev-cycle.sh, questions.sh, anything under scripts/lib/ or skills/dev-cycle/" and "a name d6.sh does not take"

**Location:** `scripts/build-loop.sh:454`, `scripts/build-loop.sh:760`
**Type:** Configuration
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both comments against GATE_CODE and d6.sh's name check; does not cover other header text.

The list matches `scripts/lib/dev-cycle-read.sh:1035`. `[[ "$have" == main || "$have" == master ]]` (`scripts/d6.sh:59`) takes no other name.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1035`, `scripts/d6.sh:59`

---

## Claim 31: "d6.sh (plan D6; Q-140 [1]): the one way the orchestrator runs build-loop.sh (the gate), dev-cycle.sh (the digest) and questions.sh. The dev-cycle skill calls the root-owned image copy by absolute path: cd CHECKOUT && bash /opt/claude-workflows/scripts/d6.sh SCRIPT ARG..."

**Location:** `scripts/d6.sh:2-5`
**Type:** Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skill's Rules and its every mention; does not establish that a live orchestrator obeys prose.

`  `cd WT && bash /opt/claude-workflows/scripts/d6.sh SCRIPT ARG...`` (`skills/dev-cycle/SKILL.md:39`), once, by the `-cxF` count at test `:275`. No `bash -s` remains in the skill (`:276`). Both passed in E2.

**Evidence:** `skills/dev-cycle/SKILL.md:36-41`, `test/scripts/build-loop-orchestrator.bats:273-276`, FC3/bats-head-d6.log

---

## Claim 32: "It always runs the root-owned image copy under D6_OPT by absolute path, never main's copy, a working-tree copy or ~/.claude/scripts, so no repository data chooses which script runs"

**Location:** `scripts/d6.sh:6-10`
**Type:** Invariant
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the script and its children: dev-cycle.sh's fallback to `~/.claude/scripts/questions.sh` cannot fire because d6.sh checks the file first; "no repository data" covers which script runs, not whether d6.sh refuses (it reads refs for that).

dev-cycle.sh holds `[[ -f "$QS" ]] || QS="$HOME/.claude/scripts/questions.sh"` (`scripts/dev-cycle.sh:385`). E1: `[no-questions] rc=2 stdout=<refuse d6: .../opt/scripts/questions.sh is missing>` for `dev-cycle.sh`.

**Evidence:** `scripts/d6.sh:45-49`, `scripts/d6.sh:60`, `scripts/dev-cycle.sh:384-385`, FC3/probe1.log

---

## Claim 33: "D6_OPT is a literal, never read from the environment or from this file's own path: a working-tree copy of this file still runs the image's scripts."

**Location:** `scripts/d6.sh:10-12`
**Type:** Invariant
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an unmodified copy and an exported D6_OPT; a `readonly` planted through BASH_ENV is the same-uid residual at `:14`.

`D6_OPT=/opt/claude-workflows` (`:34`); E1 `[wt-copy] rc=7` and `[env-D6_OPT] rc=7`, both running the stand-in's script.

**Evidence:** `scripts/d6.sh:34`, FC3/probe1.log

---

## Claim 34: "It still trusts that entry and the default branch's ref for which repository and branch the script reads (a moved main is --main-log's to report), and it cannot guard against this uid's own shell (PATH, exported functions): the plan's same-uid residual (Q-103)."

**Location:** `scripts/d6.sh:12-15`
**Type:** Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers d6.sh's lack of any check on `.git` or on what main names, and `bash`, `git` and `env` resolved through PATH; "that entry" refers back to line 9's `.git` entry.

d6.sh's reads of the repository stop at `g show-ref --verify -q` (`:55`), and it calls `bash`, `git` and `env` by bare name (`:38`, `:60`). `--main-log` reports moves (`main_log`, `scripts/build-loop.sh:1867`).

**Evidence:** `scripts/d6.sh:38`, `scripts/d6.sh:55`, `scripts/d6.sh:60`, `scripts/build-loop.sh:1865-1867`

---

## Claim 35: "In claude-workflows a gate change runs from the next image release. Run it from the checkout the script is to read (each step names MAIN_WT, WT or GT). Arguments: build-loop.sh, dev-cycle.sh or questions.sh, then that script's own."

**Location:** `scripts/d6.sh:15-18`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the argument rule and the step text; does not establish a release.

`runs from WT (step 0's first two from MAIN_WT; step 7's self-merge from its GT)` (`skills/dev-cycle/SKILL.md:37`). `shift` then `"$@"` (`scripts/d6.sh:41`, `:60`). E1 `[own-status] rc=7` passed the argument through.

**Evidence:** `skills/dev-cycle/SKILL.md:37`, `scripts/d6.sh:39-41`, `scripts/d6.sh:60`, FC3/probe1.log

---

## Claim 36: "Exit: the script's own status; 2 and one 'refuse d6: WHY' line on stdout, with nothing run, for an image-copy file that is missing or not a regular file (a partial image), an image lib that does not load or whose git_harden refuses the caller's environment, a default branch that is not exactly one of main and master, or a git read that exits above 1 (git may add a line on stderr); 1 for another first argument."

**Location:** `scripts/d6.sh:19-24`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every listed branch, by E1 and tests; the stderr note names only git, and the lib-syntax and `GIT_CONFIG_COUNT` cases also add a stderr line (from bash and from git_harden), which leaves stdout's one line true.

E1: `[own-status] rc=7`; `[both] rc=2`; `[not-a-repo] rc=2 stdout=<refuse d6: refs/heads/main could not be read> stderr=<fatal: not a git repository ...>`; `[lib-return1]`, `[lib-syntax]`, `[count-010]` and `[count-abc]`, each `rc=2` with the `did not load, or its git_harden refused this environment` line; `[bad-arg] rc=1 stdout=<>`; `[no-arg] rc=1`.

**Evidence:** `scripts/d6.sh:35`, `scripts/d6.sh:40`, `scripts/d6.sh:47-48`, `scripts/d6.sh:52-59`, FC3/probe1.log

---

## Claim 37: "An image with no d6.sh at all prints nothing of this: bash exits 127 naming the path, which the skill's Rules read as this refusal."

**Location:** `scripts/d6.sh:24-25`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the call's behaviour and the Rules' text; does not establish a whole image missing, which gives the same message.

E1 `[no-d6] rc=127`, with `bash: ...: No such file or directory`. Rules: `So does exit 127 with `bash`'s `No such file or directory` line naming d6.sh` (`skills/dev-cycle/SKILL.md:47-48`).

**Evidence:** `skills/dev-cycle/SKILL.md:47-49`, `test/scripts/build-loop-orchestrator.bats:291-304`, FC3/probe1.log

---

## Claim 38: "Its git is the image lib's git_harden, in a subshell, so the script starts from the caller's environment, not with d6.sh's pairs."

**Location:** `scripts/d6.sh:26-27`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the empty and one-pair caller; does not cover a caller's `GIT_CONFIG_PARAMETERS`, which SKILL.md forbids exporting.

See E1 `[env-none]` and `[env-caller]`, quoted under Claim 20; test `:368` asserts `count=unset` and passed in E2.

**Evidence:** `scripts/d6.sh:37-38`, `test/scripts/build-loop-orchestrator.bats:368-377`, FC3/probe1.log

---

## Claim 39: "These checks come before, not instead of, build-loop.sh's own state and default-branch gates in its gated modes, which also refuse a symbolic or non-commit default branch (dev-cycle.sh, questions.sh and the read modes have none; row 548 for dev-cycle.sh)."

**Location:** `scripts/d6.sh:27-31`
**Type:** Architectural / Reference
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every mode in the dispatch by reading and `--state` by run; the other seven gated modes reach `default_gate` by `state_start` or `gate_start` and were not each run on a symbolic ref.

`GATED=""; [[ "$MODE" =~ ^(settings|status|marker)$ ]] || GATED=1` (`scripts/build-loop.sh:798`). `state_start() { default_gate || exit 2 ...` (`:1292-1293`); `state`, `main-log`, `cycle-diff` and `land-cycle` call it (`:2321-2334`), and `check`, `merge`, `start` and `prompt` call `gate_start` (`:2346-2370`), which calls it (`:1297-1298`). `--check-constraints` leaves before any of this (`:680`) and reads no git object. Row 548: `R3 — dev-cycle.sh runs no state_gate or default_gate: **row 548**` (`docs/reviews/security-review-2026-10-12-u3b3-i2.md:155`).

**Evidence:** `scripts/build-loop.sh:798-801`, `scripts/build-loop.sh:1292-1299`, `scripts/build-loop.sh:2320-2370`, `docs/reviews/security-review-2026-10-12-u3b3-i2.md:155`, FC3/bats-head-d6.log

---

## Claim 40: "What it no longer checks, and why, is rows R6c to R6e of the restriction audit, in docs/working/research-2026-11-05-d6-block-into-image.md."

**Location:** `scripts/d6.sh:31-32`
**Type:** Reference
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file and the rows' presence; the audit itself is `docs/working/research-2026-11-01-restriction-audit.md`, and the named doc holds its re-check, which is where the reasons live.

The table at `docs/working/research-2026-11-05-d6-block-into-image.md:61-68` has one row per check, headed `| Row | Check | Re-check | Decision |`.

**Evidence:** `docs/working/research-2026-11-05-d6-block-into-image.md:61-68`

---

## Claim 41: "The four files the scripts run (build-loop.sh and dev-cycle.sh source the lib from their own directory; dev-cycle.sh runs questions.sh beside it). lib/migrations.sh is left out: both scripts check it themselves before use."

**Location:** `scripts/d6.sh:42-44`
**Type:** Architectural / Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers dev-cycle.sh by run and build-loop.sh by reading; does not cover `--migrated` run with no registry, which refuses per `:2067-2068`.

`if [[ ! -f "$MIG_LIB" || -L "$MIG_LIB" ]]; then` (`scripts/dev-cycle.sh:578`) and `if [[ ! -f "$SCRIPT_DIR/lib/migrations.sh" || -L "$SCRIPT_DIR/lib/migrations.sh" ]] || ! bash -n -- ...` (`scripts/build-loop.sh:2067`). E1 with no migrations.sh in the stand-in: exit 0 and `**Migrations were NOT checked** — lib/migrations.sh is missing beside this script`.

**Evidence:** `scripts/dev-cycle.sh:576-583`, `scripts/build-loop.sh:2067-2072`, `scripts/dev-cycle.sh:97`, `scripts/dev-cycle.sh:384`, FC3/probe1.log

---

## Claim 42: "Tried alone first, so that exit 1 below comes from show-ref, which counts as absent a ref it cannot use (a junk or dangling one), as the block did."

**Location:** `scripts/d6.sh:50-51`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a lib stable between the three subshells and exit 1; "as the block did" is exit 1 only (Claim 27).

`( harden ) || no ...` (`:52`) runs before the loop, so a `git_harden` `exit 1` or lib failure never reaches `rc`. The rest is Claim 27's E1 output. This is the wording i2 asked for.

**Evidence:** `scripts/d6.sh:50-59`, FC3/probe1.log

---

## Claim 43: "scripts/d6.sh is the exception to what follows: it sources the image copy in a subshell for git_harden alone, with no -e and no ROOT_REAL."

**Location:** `scripts/lib/dev-cycle-read.sh:13-14`
**Type:** Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers d6.sh's use of the lib; d6.sh also does not cd to the root, which the comment leaves unsaid and "the exception" covers.

`set -u -o pipefail` (`scripts/d6.sh:33`) and `harden() { source "$D6_OPT/scripts/lib/dev-cycle-read.sh" && git_harden; }` (`:37`), used only in subshells (`:38`, `:52`).

**Evidence:** `scripts/d6.sh:33`, `scripts/d6.sh:37-38`, `scripts/d6.sh:52`

---

## Claim 44: "d6.sh calls it in a subshell for its own git"

**Location:** `scripts/lib/dev-cycle-read.sh:311`
**Type:** Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers d6.sh's calls; the three subshells each run it once, so the lib's "once" holds per process.

`g() { ( harden && git "$@" ); }` (`scripts/d6.sh:38`). Test `:368` logged two calls with the pins; it passed in E2.

**Evidence:** `scripts/d6.sh:38`, `test/scripts/build-loop-orchestrator.bats:368-377`, FC3/bats-head-d6.log

---

## Claim 45: "scripts/d6.sh because it runs the gate; skills/dev-cycle/ because its SKILL.md states the call (U4c; plan D4, F52). Both reach a session only from a release, so here the floor is stricter than D5."

**Location:** `scripts/lib/dev-cycle-read.sh:1030-1032`
**Type:** Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the installed skill's link and d6.sh's image path; does not cover a project-level skill copy elsewhere.

The skill's Rules hold the call at `skills/dev-cycle/SKILL.md:39`, and the home skills directory is a link into the image (Claim 22).

**Evidence:** `skills/dev-cycle/SKILL.md:39`, `scripts/lib/dev-cycle-read.sh:1028-1035`

---

## Claim 46: "through d6.sh (the image copy; this file sits in its root-owned lib/)"

**Location:** `scripts/lib/migrations.sh:35-36`
**Type:** Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the live image; does not cover a future one beyond the payload's `scripts` item.

`ls -la /opt/claude-workflows/scripts/lib/` shows `-r-xr-xr-x 1 root root 10300 Nov  2 10:48 migrations.sh`.

**Evidence:** `devcontainer-config/install.sh:146`, `scripts/lib/migrations.sh:35-36`

---

## Claim 47: Rules bullet: "Every ... call runs ... as this one line ... d6.sh is the root-owned image copy, and it runs the image's SCRIPT (Q-140 [1]), so no repository file or state a build loop writes chooses which script runs as the gate"

**Location:** `skills/dev-cycle/SKILL.md:36-45`
**Type:** Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the call, the literal and the scripts it reaches, once released; before the release the image holds no d6.sh, which is Claim 48's case.

Claims 31 to 33 carry the mechanism; every other mention in the skill reads "through d6" (paraphrased — no quote available because the claim spans `:134`, `:211`, `:297`, `:356`, `:389`). Test `:273` passed in E2.

**Evidence:** `skills/dev-cycle/SKILL.md:36-45`, `scripts/d6.sh:34`, `scripts/d6.sh:60`, FC3/bats-head-d6.log

---

## Claim 48: 127 site 1: "`refuse d6: WHY` (exit 2; d6.sh's header lists them) or a usage line on stderr (exit 1, a first argument that is none of the three) means nothing ran. So does exit 127 with `bash`'s `No such file or directory` line naming d6.sh: that is the same refusal from an image older than this skill, which has no d6.sh to print it."

**Location:** `skills/dev-cycle/SKILL.md:46-49`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each exit; a 127 from inside a script is told apart only by the named-d6.sh line, which the sentence requires.

E1 `[both] rc=2`, `[bad-arg] rc=1 stdout=<> stderr=<d6: the first argument is ...>`, `[no-d6] rc=127 stdout=<>`. Test `:291` also asserts `[ ! -e "$BATS_TEST_TMPDIR/ran" ]`.

**Evidence:** `scripts/d6.sh:19-25`, `test/scripts/build-loop-orchestrator.bats:291-304`, FC3/probe1.log

---

## Claim 49: 127 site 2: "a call of any script that the Bash tool timed out, and a `refuse d6:` line or that exit 127, are stops too."

**Location:** `skills/dev-cycle/SKILL.md:53-54`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the text's presence and its fit with the sentence before it; a rule in prose has no code to check against.

The phrase `a ${q}refuse d6:${q} line or that exit 127, are stops too` is required by test `:300` (E2).

**Evidence:** `skills/dev-cycle/SKILL.md:53-54`, `test/scripts/build-loop-orchestrator.bats:300-303`, FC3/bats-head-d6.log

---

## Claim 50: 127 site 3: "Any other exit is a stop as the Rules say (the exit 127 above means an image older than this skill, and a `refuse d6:` naming a missing image file a partial image: either entry also gives the release paste below)."

**Location:** `skills/dev-cycle/SKILL.md:216-218`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Legibility-target:** for-author
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the two meanings (Verified by E1 and Claim 36) and how the stop is filed; does not establish how an orchestrator reads it, and the same looseness was in the pre-branch sentence; i2's Claim 17 read it as Verified on the meanings alone.

The meanings hold. "Either entry" has no referent for these two stops. The Rules file a stop `in the `you: judgment` entry the step names, if it names one (step 0's `--state` refusals and its lost `Main at:` line), else the line and stderr go in one agent work item` (`:56-58`). Step 0.1 names its entry for refuse lines, and these two are "any other exit", so they read as an agent work item, while the release paste is an owner action. Research `:85` repeats it as "its entry". Precise wording: name the record, for example "file one `you: terminal` entry holding the paste".

**Evidence:** `skills/dev-cycle/SKILL.md:55-58`, `skills/dev-cycle/SKILL.md:211-218`, `docs/working/research-2026-11-05-d6-block-into-image.md:85`

---

## Claim 51: PATHS line and slug regex: "PATHS being GATE_CODE's (a test pins the line)"; "a test holds this copy to it"

**Location:** `skills/dev-cycle/SKILL.md:230`, `skills/dev-cycle/SKILL.md:618`
**Type:** Configuration
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both copies against the lib; does not cover the old image's copy, which is Claim 25's window.

E2's `ok 13` and `ok 14` are the two pins.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:437-443`, FC3/bats-head-d6.log

---

## Claim 52: 127 site 4: "(a `refuse d6:` line, its exit 127 or a timed-out call is still a stop, as the Rules say)"

**Location:** `skills/dev-cycle/SKILL.md:358-359`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the text, the Rules' agreement and the pin; "its" has `refuse d6:` as antecedent, which reads as d6's.

Rules `:53-54` say the same, and test `:300` requires this phrase (E2).

**Evidence:** `skills/dev-cycle/SKILL.md:53-54`, `skills/dev-cycle/SKILL.md:357-359`, FC3/bats-head-d6.log

---

## Claim 53: Helper comments: "the file itself, with one literal changed, runs in these tests"; "a uid-owned OPT stands in for the root-owned image, as d6.sh checks presence, not owner"; "main holds this branch's four scripts, and so does a stand-in at $U"; "In its real place beside the scripts, where the stand-in can hold it"; "d6.sh refused with exactly WANT, exit 2, before running anything"

**Location:** `test/scripts/build-loop-orchestrator.bats:247-253`, `test/scripts/build-loop-orchestrator.bats:264`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers helpers as used here; `-w` is true of `/opt` under root, a case not run; "four scripts" counts the lib; the 127 test uses `opt_copy` alone, so its stand-in has no d6.sh, as it needs.

`D6="$BATS_TEST_TMPDIR/d6.bash"; [[ ! -w "$1/scripts" ]] || D6="$1/scripts/d6.sh"` (`:254`); `[ "$status" -eq 2 ] && [ "$output" = "$1" ]` (`:265`), an exact stdout that a run script would not match. All users passed in E2.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:247-265`, FC3/bats-head-d6.log

---

## Claim 54: Title: "SKILL.md states d6.sh's one-line call once, by absolute path, with no pasted block; d6.sh names no other copy to run: no root test, no read of main's scripts" and comment "Where the image copy is comes from one literal, never the environment or the file's own path."

**Location:** `test/scripts/build-loop-orchestrator.bats:273`, `test/scripts/build-loop-orchestrator.bats:277`
**Type:** Invariant
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the greps, and d6.sh by reading; "no root test" is the absence of `D6_ROOT` and of any root-commit code, not of the word.

Lines `:275-281` hold each check; `ok 1` in E2.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:273-282`, FC3/bats-head-d6.log

---

## Claim 55: Title: "d6.sh reaches the image with no installer or Dockerfile change: scripts/ is a payload item, and a .sh file is made 0555"

**Location:** `test/scripts/build-loop-orchestrator.bats:284`
**Type:** Configuration
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the text pins and an empty `devcontainer-config` diff; does not build an image.

`git diff 5b20d4bd..1c5fd04f --stat -- devcontainer-config` printed nothing. `ok 2` in E2. Live image files show the mode: `-r-xr-xr-x 1 root root 150787 ... build-loop.sh`.

**Evidence:** `devcontainer-config/install.sh:146`, `devcontainer-config/Dockerfile:528`, FC3/bats-head-d6.log

---

## Claim 56: Title: "the skill's d6 call on an image with no d6.sh (an image older than the skill): exit 127, bash names the path, nothing runs, and the Rules read it as a refusal"

**Location:** `test/scripts/build-loop-orchestrator.bats:291`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skill's own line taken as argv; two of the four phrases it requires sit in steps 0.1 and 1b, not the Rules.

`read -r -a w <<<"$l"; run -127 --separate-stderr "${w[@]}"` (`:297`), the stderr match and `[ ! -e "$BATS_TEST_TMPDIR/ran" ]` (`:298`). `ok 3` in E2.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:291-304`, FC3/bats-head-d6.log

---

## Claim 57: Title: "d6.sh scrubs the caller's variables and closes stdin before it runs the image's script; a caller's stdin never reaches it"

**Location:** `test/scripts/build-loop-orchestrator.bats:306`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all six names and a piped stdin; does not name other variables, which pass through.

`echo piped | QUESTIONS_LIVE=x ... bash "$1" questions.sh --probe` against the exact line ending `in=` (`:309-310`). `ok 4` in E2.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:306-311`, `scripts/d6.sh:60`, FC3/bats-head-d6.log

---

## Claim 58: Title: "d6.sh runs the image copy's scripts by absolute path, with the image's own lib and questions.sh, never main's or the working tree's", and comments at `:315`, `:325`

**Location:** `test/scripts/build-loop-orchestrator.bats:313`, `test/scripts/build-loop-orchestrator.bats:315`, `test/scripts/build-loop-orchestrator.bats:325`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** See Claim 6; the bare comment "--state through d6.sh passes." is the replacement i1 asked for.

`[ "$l" = "lib at $U/scripts/lib/dev-cycle-read.sh" ]` (`:324`). `ok 5` in E2.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:313-330`, FC3/bats-head-d6.log

---

## Claim 59: Title: "d6.sh refuses before running anything: ..." and comment "A lib that does not load, or a git_harden that refuses, is named as that, never as an absent branch."

**Location:** `test/scripts/build-loop-orchestrator.bats:332`, `test/scripts/build-loop-orchestrator.bats:344`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test's cases and E1's lib-syntax and `abc` cases, whose stderr the test does not read; "never" assumes a lib that behaves the same across subshells.

`ok 6` in E2; E1 gives `[lib-syntax] rc=2` and `[count-abc] rc=2` with the same line.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:332-350`, FC3/probe1.log, FC3/bats-head-d6.log

---

## Claim 60: Title: "d6.sh runs the script past what audit rows R6c to R6e dropped: a replace ref, info/grafts, a symbolic or tag default branch, a uid-owned image; --state still refuses the two default-branch shapes", comments at `:354`, `:362`

**Location:** `test/scripts/build-loop-orchestrator.bats:352`, `test/scripts/build-loop-orchestrator.bats:354`, `test/scripts/build-loop-orchestrator.bats:362`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a blob replace ref and an empty-parent graft line; the symbolic and tag cases show d6.sh passing by reaching build-loop.sh's own refusal; "uid-owned image" holds through the fixture, as every test here does.

`[[ "$output" == *"refuse state default-branch: refs/heads/main is a symbolic ref"* ]]` (`:361`) and `... names an object that is not a commit` (`:364`), neither a `refuse d6:` line. Row 656 is cited at `scripts/build-loop.sh:775`. `ok 7` in E2.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:352-366`, `scripts/build-loop.sh:773-779`, FC3/bats-head-d6.log

---

## Claim 61: Title: "d6.sh's own git is hardened by the image lib's git_harden, and no pair reaches the script (T26, ...)" and shim comment "(T26's)"

**Location:** `test/scripts/build-loop-orchestrator.bats:368`, `test/scripts/build-loop-orchestrator.bats:266`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers two calls and six of fourteen settings by name; all fourteen apply since they come from one function.

`[ "$(wc -l < "$BATS_TEST_TMPDIR/calls")" -eq 2 ]` and the `for w in core.hooksPath=/dev/null ... S=1` loop (`:373-375`). F25's row cites `D7 hardening and state gate (T26)` (`docs/working/plan-build-loop-handoff.md:150`). `ok 8` in E2.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:266-271`, `test/scripts/build-loop-orchestrator.bats:368-377`, `docs/working/plan-build-loop-handoff.md:150`, FC3/bats-head-d6.log

---

## Claim 62: Titles at `:379`, `:392`, `:400` (T27, T37)

**Location:** `test/scripts/build-loop-orchestrator.bats:379`, `test/scripts/build-loop-orchestrator.bats:392`, `test/scripts/build-loop-orchestrator.bats:400`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all three as run here; `:396`'s `D6="$O/scripts/d6.sh"` branch waits for a release (Claim 8); "never runs main's" at `:400` holds by exact stdout.

`ok 9`, `ok 10`, `ok 11` in E2, none skipped.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:379-404`, FC3/bats-head-d6.log

---

## Claim 63: "d6.sh repeats neither list: it runs the lib's git_harden (its own test above)." and the shortened git_harden title

**Location:** `test/scripts/build-loop-orchestrator.bats:406`, `test/scripts/build-loop-orchestrator.bats:417`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two tokens the grep names and d6.sh by reading.

`! grep -nE '^[^#]*(GIT_NO_REPLACE_OBJECTS|core\.hooksPath)' "$REPO_ROOT/scripts/d6.sh"` (`:418`). The "own test above" is `:368`. `ok 12` in E2.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:406-419`, FC3/bats-head-d6.log

---

## Claim 64: Commit messages da07a77c ("the move alone"), 9f80368a ("The lib's array named m made shellcheck read d6.sh's string as one"), 4dd68cdc ("The scrub test pins all six variables")

**Location:** commits da07a77c, 9f80368a, 4dd68cdc
**Type:** Reference / Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these three statements; the shellcheck result is from a root or absolute path, as `scripts/health-check.sh:525` runs it; run from inside `scripts/` it exits 0 at both commits.

da07a77c's d6.sh holds every check of the block in order, with `d6 "$@" </dev/null` and `exit "$?"` folded into one `exec ... </dev/null`. E5: `shellcheck 2b0838bb (from root) exit 1` with `SC2178 (warning): Variable was used as an array but is now assigned a string`, on `m=""`; `shellcheck 9f80368a (from root) exit 0`.

**Evidence:** `scripts/health-check.sh:525`, FC3/sc-2b0838bb-abs.log, FC3/sc-9f80368a-abs.log, FC3/probe3.log

---

## Claim 65: Commit message b8722aba: "so exit 1 in the loop can only be git's 'no such ref'."

**Location:** commit b8722aba
**Type:** Error-handling
**Verdict:** Stale
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the message only; the code comment and research doc it described are corrected at HEAD, and 1c5fd04f says so in history.

E1's `show-ref junk exit 1` and its two siblings refute it, as i2 found. Same class as 2b0838bb's known-stale revert line: nothing to do unless the branch is rewritten.

**Evidence:** `scripts/d6.sh:50-51`, FC3/probe1.log

---

## Claim 66: Commit message 1c5fd04f: "show-ref's exit 1 also covers a ref git cannot use ... behaviour matches the old block ... the plan's T36 and T37 rows match." and "comment and doc changes only; code path unchanged."

**Location:** commit 1c5fd04f
**Type:** Reference
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exit 1 against the block, and the commit's stat; does not cover "Option [2] names its full steps" (Claim 67).

`git show --stat` lists `scripts/d6.sh | 3 +-`, and that change is to the comment at `:50-51`. See Claims 7, 8, 27.

**Evidence:** `scripts/d6.sh:50-51`, FC3/probe1.log

---

## Claim 67: Commit message 1c5fd04f: "Option [2] names its full steps"

**Location:** commit 1c5fd04f
**Type:** Reference
**Verdict:** Mostly accurate
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers code, tests and comments, which are full; the plan's rows are not named (Claim 29).

It names the steps that make the tests pass, and leaves out the plan edits in Claim 29. Fix the research doc; the message need not change.

**Evidence:** `docs/working/research-2026-11-05-d6-block-into-image.md:118`, FC3/probe3.log

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- **Claim 65** (commit b8722aba): "can only be git's 'no such ref'" is superseded by 1c5fd04f; history only, nothing to fix.

### Mostly Accurate
- **Claim 5** (`docs/working/plan-build-loop-handoff.md:406`, `:431`): T27 and the coverage row still say "D6 snippet".
- **Claim 10** (`docs/working/research-2026-11-05-d6-block-into-image.md:53`): "it alone" is also true of the pruned no-wrapper row; say "of the options that keep the scrub".
- **Claim 14** (`docs/working/research-2026-11-05-d6-block-into-image.md:63`, `:118`): the orchestrator's plain git does read a replace ref; say "none of the three scripts reads". `:118` is in the owner's option table.
- **Claim 29** (`docs/working/research-2026-11-05-d6-block-into-image.md:118`): option [2] also leaves the plan's amendment and F38, F39, T36, T37 false; add them. The owner sees this line.
- **Claim 50** (`skills/dev-cycle/SKILL.md:216-218`): "either entry" has no referent, since the Rules route these stops to an agent work item while the paste is the owner's.
- **Claim 67** (commit 1c5fd04f): "full steps" as Claim 29.

### Unverifiable
- **Claim 18b** (`docs/working/research-2026-11-05-d6-block-into-image.md:68`): "refused a run as root" needs a run as real root; about removed code, so nothing live rests on it.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to docs/reviews/code-fact-check-report-final-r3-2026-11-05-d6-block-into-image.md, first line `Commit: 1c5fd04f`, every claim tagged Legibility-target, ending with a Goal-Alignment Note (patterns/orchestrated-review.md). Do not commit.
- Answered: yes; every named claim was checked and run where it could be, except the T37 post-release branch and the run-as-root line.
- Out of scope: hostile-author cases (S1), such as a `readonly D6_OPT` through BASH_ENV; 2b0838bb's revert line (known stale); whether any dropped check should return, which is a design question.
- Escalate: Claims 14 and 29 before the owner reads option [2]; Claim 50 for the skill's author.
- Decisions I made: kept logs in scratch, as i1 and i2 did, since the dispatch allowed no other edit; the alternative was `docs/reviews/execution-logs/`. Rated Claim 50 Mostly accurate where i2's Claim 17 gave Verified, because I traced the filing route, not only the two meanings; the alternative was Verified, as the looseness predates the branch. Rated Claim 14 Mostly accurate where i1's Claim 14 gave Verified on the three scripts; the alternative was Verified with the same scope line.
