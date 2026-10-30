Commit: b5eaedf6

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u5 (claude-workflows, branch `feat/build-loop-u5`)
**Scope:** full branch, `git diff main...HEAD` (main b279a2ba, HEAD b5eaedf6), 20 files; claims checked against `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `scripts/questions.sh`, `scripts/health-check.sh`, `devcontainer-config/install.sh`, `skills/dev-cycle/SKILL.md`, `docs/reviews/override-log.md`, `docs/working/plan-build-loop-handoff.md`. Final confirming pass, replicate r2 of k=3 (decision log 63).
**Checked:** 2026-10-14
**Total claims checked:** 47
**Summary:** 40 verified, 7 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 5 entries) read first. No claim here matches a logged pattern, and no Incorrect verdict is a fabrication, so the log needs no new entry (and this pass edits no tracked file).

Execution logs (all under `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r2/`, the replicate's scratch dir; every process ran under `timeout` and exited before this report):

- `settings-runs.log`: `--settings` on main's and the branch's `docs/dev-cycle.md`, each also with the policy line flipped to `Build-loop policy: self-merge`, each committed as `main` of a throwaway repo (`GIT_CONFIG_GLOBAL=/dev/null`).
- `settings-variants.log`: nine variants of the branch file (slots 9/0/10, a prose copy, a bold copy, a CRLF policy line, `none` never list, a malformed never line, a fenced copy).
- `glob-harness.log`: `never_res` extracted verbatim from `scripts/build-loop.sh:1181-1193` and the `srules` match loop, run over sample paths.
- `paste-runs.log`: Q-156's paste with only `install.sh` swapped for an echo (`paste-check.sh`, core text byte-identical to the entry's, checked by diff), run in a bare clone whose `main` is a commit-tree merge of `feat/build-loop-u5` into `b279a2ba`, plus five mutations.
- `bats-real-settings.log`: `bats test/scripts/build-loop-read.bats -f "own docs/dev-cycle.md"`.
- `questions-check.log`: `scripts/questions.sh check` in the worktree.

---

## Claim 1: Decision-log row 72's D1–D14 summary matches the plan and the built code

**Location:** `docs/decisions/log.md:95`
**Type:** Architectural / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each D-item's one-line summary against the plan's D-bullets and the code it names (4-dispatch cap, constraints gate on dispatch, merge entry slugs, `--merge --approved`, floor, D6 image copy, merge-tree/commit-tree/CAS, slots default 3, `--state`/`--main-log`/`--land-cycle`, health-check flock); does not establish the plan's own F-table claims or the D10 quotes beyond their presence in the handoff doc.
**Legibility-target:** for-orchestrator-synthesis

The row's D1 cap and D2 constraints gate are in the code: `DISPATCH_CAP=4; STEAL_AGE=7200` (`scripts/build-loop.sh:1593`) and `if [[ "$CONSTRAINTS" != ok ]]; then x="no loop is dispatched until --settings reads the constraints as ok` (`scripts/build-loop.sh:1633`). D4's slugs and approval: `[[ "$ANSWER_HEADING" == "$1 · $s" ]]` with `s="merge-"` or `"merge-gate-"` (`scripts/build-loop.sh:1440-1461`, `approval`). D7's compare-and-swap: `git update-ref --no-deref -m "$msg" "refs/heads/$MAIN" "$NEW" "$MAIN_SHA"` inside `land` (`scripts/build-loop.sh:1484-1575`, read whole). D9: `^Build-loop\ slots:\ ([123456789])$` else `slots 3 default` (`scripts/build-loop.sh:824-825`). The D10 quotes appear verbatim in `docs/working/handoff-build-loop-handoff.md:30,37,38` (`"start a cycle should be kick off a loop, not assumed stopping after one cycle"`). "The user walked D1–D14 on 2026-10-04 (plan revision 4)": `- **Task status**: in progress (revision 4, 2026-10-04: you walked through D1–D14` (`docs/working/plan-build-loop-handoff.md:5`). D13's "minimal part" of the audit: `This is the minimal part of roadmap item (d), moved into this unit.` (`docs/working/plan-build-loop-handoff.md:103`).

**Evidence:** `docs/decisions/log.md:95`, `docs/working/plan-build-loop-handoff.md:5,39-106`, `scripts/build-loop.sh:785-845,1440-1461,1484-1575,1593,1626-1669`, `docs/working/handoff-build-loop-handoff.md:29-38`

---

## Claim 2: Row 72's "What the gate cannot do" ("loops run as the user's uid with a shell; no script contains a hostile one ... the residual families are listed in Q-103, whose policy stays `review` until answered")

**Location:** `docs/decisions/log.md:95`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the plan's "What the gate can and cannot do" section and Q-103 holding the residual list and the interim policy; does not establish that the residual list is complete (Claims 27-30 check it item by item).
**Legibility-target:** for-orchestrator-synthesis

The plan's section exists (`## What the gate can and cannot do (read first)`, `docs/working/plan-build-loop-handoff.md:31`) and its summary line reads `**Not covered: F35. Partly: F11, F19, F21, F29, F37, F58, F59.** None of them blocks self-merge mechanically.` (`:179`). Q-103 carries those families (`docs/working/questions.md:95-103`) and its interim is review (`:124`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:31,179`, `docs/working/questions.md:83-126`

---

## Claim 3: The three settings lines parse as intended: "Build-loop policy: review (interim; Q-103)", "Build-loop slots: 3", "Self-merge never: workflows/ ... global-instructions/"

**Location:** `docs/dev-cycle.md:7-11`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--settings` on the branch file and on main's current file, each with the policy line as committed and flipped to `self-merge`, committed as a throwaway repo's `main`; does not establish behavior when the repo's real `origin/HEAD` names another branch (the throwaway repo has no remote).
**Legibility-target:** for-orchestrator-synthesis

Command (per variant, cwd `.../fc-final-r2/{mainfile,branchfile,branchselfmerge,mainselfmerge}`, 2026-10-15T05:13:37Z-05:13:38Z, every exit 0): `GIT_CONFIG_GLOBAL=/dev/null timeout 60 bash /workspace/.claude/wt-build-loop-u5/scripts/build-loop.sh --settings`. Branch file: `policy review unset: line 7 is not exactly ...`, `slots 3 set: line 9 ...`, `never workflows/ scripts/ test/ hooks/ devcontainer-config/ skills/ guides/ patterns/ templates/ global-instructions/ set: line 11 ...`, `readers 2-roots 2-homes set`. Flipped: `policy self-merge set: line 7`. So no prose line in the new file counts as a second copy of any key. Main's file flipped: `policy review unset: line 7 reads self-merge, but there is no valid Self-merge never: line`, which is why U5 adds the never line before the policy can ever be flipped.

**Evidence:** `docs/dev-cycle.md:7-11`, `scripts/build-loop.sh:785-845`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r2/settings-runs.log`

---

## Claim 4: "The scripts read the three lines above, and the two reader lines below, from the default branch's commit, never from a working tree ...; the orchestrator reads them through `scripts/build-loop.sh --settings`, whose header gives each line's exact form. A line counts only when it is the one line in the file, outside code blocks, that starts with its key; a trailing CR is ignored."

**Location:** `docs/dev-cycle.md:13-17`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the read source (main's blob), the copy rule as `SETTINGS_AWK` implements it, the fence skip and the CR drop; "starts with its key" is verified in the script's sense (letters only, case folded, best effort, as the header states), not as a literal byte prefix: a bold `**Build-loop policy: ...**` line also counts as a copy.
**Legibility-target:** for-orchestrator-synthesis

`main_file` reads `git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk "$FENCE_AWK$2"` (`scripts/lib/dev-cycle-read.sh:606`), so no working tree is read. `SETTINGS_AWK` starts `{ sub(/\r$/, "") }` / `fence($0) { next }` and keys a line by `s = tolower($0); gsub(/[^a-z]/, "", s)` then `index(s, "buildlooppolicy") == 1` (`scripts/lib/dev-cycle-read.sh:618-635`). `read_settings` turns a count above 1 into `more than one line starts "Build-loop policy:"` (`scripts/build-loop.sh:814-815`). Executed (`settings-variants.log`, 2026-10-15T05:19:53Z-05:19:54Z, all exit 0): a prose line starting "Build-loop policy prose." gives `policy review unset: more than one line starts "Build-loop policy:" (lines 7 and 38)`; a bold copy gives the same (lines 7 and 9); a CRLF policy line (od shows `\r \n`) still gives `policy self-merge set`; a fenced copy is ignored (`policy self-merge set`).

**Evidence:** `docs/dev-cycle.md:13-17`, `scripts/lib/dev-cycle-read.sh:597-635`, `scripts/build-loop.sh:785-845`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r2/settings-variants.log`

---

## Claim 5: "Under `self-merge` ... the orchestrator lands it through the gate (`build-loop.sh --merge`) with no review, but only when every changed path is listed in the brief's `Paths:` line or is one of the brief's own files (named by its stem), and none is on the gate's fixed floor (instruction files and what they `@`-import, any dot path, the gate's own code, files later runs read as truth such as `docs/decisions/` and `docs/constraints.md`, symlinks and gitlinks) or matches the never line."

**Location:** `docs/dev-cycle.md:19-25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the S rules' three tests (floor, never glob, allowlist) and where symlinks/gitlinks and `docs/constraints.md` are refused (the N rules' mode test and `user` word, which run first); does not establish the floor's full list (it also refuses non-own `docs/working/` and `docs/reviews/` files and `docs/thoughts/`, covered by "such as"), nor the self-merge checkout precondition (`checkout_gate`), which the prose does not mention.
**Legibility-target:** for-orchestrator-synthesis

`srules` (`scripts/build-loop.sh:1202-1218`, read whole): `if [[ -z "$5" ]] && floor "$2" "$1" "$4" "$3"; then DENY=...`, then each `NEVER_RES`, then `ownfile`, then `PATHS` entries, else `DENY="neither listed in the brief's Paths: line nor one of its own files"`. `floor` (`scripts/lib/dev-cycle-read.sh:1997-2017`) refuses `truthrule`'s words (`instr`, `dot`, `cycle`, `settings`, `user`, `record` for `^docs/(decisions|human-author)/`, `:1916-1928`), then `elif [[ "$lp" =~ $GATE_CODE ]]; then FLOOR_WHY=gate`, then non-own `docs/working/*` and `docs/reviews/*`, then the main walk's imports. Symlinks and gitlinks fall to the N rules first: `DENY="a symlink, gitlink or other non-file entry on one side (only modes 100644 and 100755 land)"` (`scripts/build-loop.sh:1145`). Own files by stem: `ownfile` (`scripts/lib/dev-cycle-read.sh:1956-1961`).

**Evidence:** `docs/dev-cycle.md:19-25`, `scripts/build-loop.sh:1141-1166,1202-1218,1349-1423`, `scripts/lib/dev-cycle-read.sh:1916-1928,1956-2017`

---

## Claim 6: "A self-merge refused for a path falls through to review; a conflict is filed as stopped, and an environment refusal is retried."

**Location:** `docs/dev-cycle.md:25-26`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the skill's step 7 handling of `--merge`'s three refusal classes; does not establish that the orchestrator follows the skill (skill text, not code).
**Legibility-target:** for-orchestrator-synthesis

`skills/dev-cycle/SKILL.md:579-587`: "A refusal of the paths ("K of N changed paths refused", `deny` lines following) falls through to review: a merge entry as below ... A conflict is `stopped`. Any other refusal (no identity, MAIN_WT's state, a moved main, a failed read) is the environment's, not the loop's: recorded, named in the final message, and tried again next iteration." The conflict line comes from `check_line`: `1) echo "refuse $a: $br conflicts with the default branch"` (`scripts/build-loop.sh:1371`).

**Evidence:** `docs/dev-cycle.md:25-26`, `skills/dev-cycle/SKILL.md:571-587`, `scripts/build-loop.sh:1349-1423`

---

## Claim 7: "Under `review`, the orchestrator files one merge entry (`merge-STEM-SHA12`, or `merge-gate-STEM-SHA12` when the change touches the gate's own code) holding `--check`'s output, and merges only on your `[1] merge`."

**Location:** `docs/dev-cycle.md:26-29`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the slug rule in step 7 and `approval`, and that `--approved` needs option 1; does not establish the branch where `--check` refuses under review (filed as stopped, Claim 8).
**Legibility-target:** for-orchestrator-synthesis

Step 7: "On `ok`, one merge entry, heading `### Q-NNN · merge-STEM-SHA12` ... or `merge-gate-STEM-SHA12` when a `path` or `deny` line's PATH, lower-cased, matches the lib's GATE_CODE" (`skills/dev-cycle/SKILL.md:588-591`). `approval` accepts only `"keep $1"` and the exact heading (`scripts/build-loop.sh:1446-1461`); `GATE_CODE='^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'` (`scripts/lib/dev-cycle-read.sh:1970`).

**Evidence:** `docs/dev-cycle.md:26-29`, `skills/dev-cycle/SKILL.md:588-599`, `scripts/build-loop.sh:1440-1461`, `scripts/lib/dev-cycle-read.sh:1970`

---

## Claim 8: "Under both policies the N rules refuse a change to `docs/constraints.md`, this file, the cycle's own files (the questions files, the roadmap, the idea log, the cycle records) or any brief beyond the brief's own Status line: under review such a branch is filed as stopped; under self-merge it first comes to you as a merge entry, whose `[1] merge` the gate then refuses, so it ends as stopped."

**Location:** `docs/dev-cycle.md:29-33`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `nrules` (run for every brief and under `--approved`) and the skill's routing of each outcome; does not establish the other N-rule refusals not listed here (pathform, modes), which the sentence does not claim to enumerate.
**Legibility-target:** for-orchestrator-synthesis

`nrules` (`scripts/build-loop.sh:1141-1166`, read whole): the brief's own file passes only when `own_blob` matches (Status open to done), otherwise `cycle|settings) DENY="one of the dev cycle's own files"` and `user) DENY="the user's constraints doc..."` (`:1156-1157`); `writable` covers the roadmap, both questions files, the idea log, records and any brief (`scripts/lib/dev-cycle-read.sh:247-249`). `check_line` runs `nrules` for every path regardless of `AUTH` (`scripts/build-loop.sh:1410-1413`), so an `--approved` run refuses again. Step 7: review `refuse` "is filed as `stopped`" (`skills/dev-cycle/SKILL.md:597-598`); self-merge path refusal goes to a merge entry, "a deny from a rule every merge applies refuses again under `--approved`, and is then filed as `stopped`" (`:582-583`); the merge-entry `keep` branch files "any other refusal ... as `stopped`" (`:631-633`).

**Evidence:** `docs/dev-cycle.md:29-33`, `scripts/build-loop.sh:1141-1166,1349-1423`, `scripts/lib/dev-cycle-read.sh:247-249`, `skills/dev-cycle/SKILL.md:579-598,629-633`

---

## Claim 9: "A brief self-merges only when its own `Policy:` line also reads `self-merge`. Only the exact line with `self-merge` or `review` sets the policy, and `self-merge` also needs a valid never line (its `none` form for an empty list). Anything else counts as unset, which means `review`: the "(interim; Q-103)" above keeps it unset until Q-103 is answered."

**Location:** `docs/dev-cycle.md:33-37`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `read_settings`' policy and never-line coupling and the brief-level `Policy:` rule as the `--status` header states it; does not establish `status_fields`' parse of a brief's `Policy:` line beyond its header contract (no brief was run).
**Legibility-target:** for-orchestrator-synthesis

`elif [[ "${text[policy]}" =~ ^Build-loop\ policy:\ (self-merge|review)$ ]]` then `if [[ "$v" == self-merge && -z "$never_ok" ]]; then POLICY_LINE="policy review unset: ..."` (`scripts/build-loop.sh:816-822`). The `--status` header: "POLICY: self-merge only when --settings' policy is self-merge and the brief's first "Policy:" line is exactly "Policy: self-merge"" (`scripts/build-loop.sh:73-76`). Executed (`settings-variants.log`): `Self-merge never: none` gives `never none: ... lists none` with `policy self-merge set`; a double space after the key gives `never malformed` and `policy review unset: line 7 reads self-merge, but there is no valid Self-merge never: line`; the interim line gives `policy review unset` (`settings-runs.log`).

**Evidence:** `docs/dev-cycle.md:33-37`, `scripts/build-loop.sh:73-76,795-822`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r2/settings-runs.log`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r2/settings-variants.log`

---

## Claim 10: "**Slots.** From 1 to 9 (anything else, or no line, means 3)"

**Location:** `docs/dev-cycle.md:38`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 0, 3, 9 and 10 and an absent line; does not establish multi-digit forms with a leading zero (the regex admits one digit only, so they default too).
**Legibility-target:** for-orchestrator-synthesis

`elif [[ "${text[slots]}" =~ ^Build-loop\ slots:\ ([123456789])$ ]]` else `slots 3 default` (`scripts/build-loop.sh:824-825`). Executed: `slots 9 set`, `slots 3 default: line 9 is not exactly "Build-loop slots: N" with N from 1 to 9` for 0 and 10 (`settings-variants.log`); `slots 3 default: no line starts "Build-loop slots:"` on main's file (`settings-runs.log`).

**Evidence:** `scripts/build-loop.sh:823-826`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r2/settings-variants.log`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r2/settings-runs.log`

---

## Claim 11: "Step 10 dispatches only into slots no running loop fills, and step 8 writes new briefs only while the queue is shorter than the slots. The queue counts open briefs whose loop is absent (not yet dispatched) or working, plus those sent back to a loop; a blocked, stopped or ready-for-review one waits on you and is not counted."

**Location:** `docs/dev-cycle.md:39-42`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the slot arithmetic in steps 8 and 10 as written; does not establish what a running orchestrator actually counts.
**Legibility-target:** for-author

Step 10 fills "free slots (`--settings`' `slots` less the loops this session runs)" (`skills/dev-cycle/SKILL.md:773-774`), so "slots no running loop fills" is broader than the skill: a loop another (or an ended) session started that is still running is not subtracted. Step 8's exclusion list is "a blocked, stopped, capped or ready one, or a stalled one held" (`skills/dev-cycle/SKILL.md:651-653`); the prose omits capped (and stalled, which step 7 files as stopped). Precise version: "Step 10 fills the slots less the loops this session runs ... a blocked, stopped, capped or ready one waits on you".

**Evidence:** `docs/dev-cycle.md:38-42`, `skills/dev-cycle/SKILL.md:647-653,767-775`

---

## Claim 12: "**Never line.** Globs that self-merge never lands, even when a brief lists them: `*` and `?` match within one path part, a glob matches the path or any directory above it, and paths compare lower-cased. A malformed line turns self-merge off."

**Location:** `docs/dev-cycle.md:43-45`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `never_res`' translation and the `srules` match (before the allowlist) and the never_ok coupling; does not establish matching of non-ASCII paths (pathform refuses them earlier).
**Legibility-target:** for-orchestrator-synthesis

`never_res` (`scripts/build-loop.sh:1181-1193`): `'*') re+='[^/]*' ;; '?') re+='[^/]'` and `NEVER_RES+=("^$re(/|\$)")` over `lower "${g%/}"`; `srules` tests the never globs before the `Paths:` allowlist (`:1210-1212`). Executed (`glob-harness.log`, cwd scratch, 2026-10-15T05:20:08Z, exit 0): `Workflows/x.md -> workflows/`, `scrxpts/b -> scr?pts`, `docs/a.md -> docs/*.md`, `docs/sub/a.md -> -`, `templatesX/y -> -`. Malformed turns self-merge off: Claim 9's execution.

**Evidence:** `docs/dev-cycle.md:43-45`, `scripts/build-loop.sh:1181-1218`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r2/glob-harness.log`

---

## Claim 13: "sessions in this repo read `workflows/`, `skills/`, `guides/` and `patterns/` from their own checkout, and the health check the orchestrator runs every iteration executes `scripts/`, `test/`, `hooks/` and `devcontainer-config/` from its worktree, while the release paste runs `devcontainer-config/install.sh` on the host before you see its diff."

**Location:** `docs/dev-cycle.md:48-51`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the project instruction files' checkout references, step 1's health-check run, the health check's suites and the release paste's order; does not establish every file under those directories that a session or suite reaches.
**Legibility-target:** for-orchestrator-synthesis

`AGENTS.md:7` "check `workflows/`", `:24` "process docs in `skills/` ... read the skill file", `:63` "See `guides/doc-freshness.md`"; `patterns/` is cited from checkout skills and workflows (paraphrased — no quote available because the claim covers grep hits across 11 files: `workflows/pr-prep.md`, `skills/self-eval/SKILL.md` and others). Step 1: "run the repo's health check from WT ... (e.g. `scripts/health-check.sh` in claude-workflows" (`skills/dev-cycle/SKILL.md:384-385`); health-check sources `scripts/lib/*` (`scripts/health-check.sh:78-83`), runs every suite through `scripts/run-tests.sh` (`:413`) and checks `hooks/*.sh` (`:578`); suites such as `test/cc-push.bats` and `test/install-host.bats` exercise `devcontainer-config/` (paraphrased — no quote available because it is a grep over test files). The paste is `cd A && test ... && ./devcontainer-config/install.sh` (`skills/dev-cycle/SKILL.md:310-311`), and install.sh draws its own payload diff after starting.

**Evidence:** `docs/dev-cycle.md:48-51`, `AGENTS.md:7,24,63`, `skills/dev-cycle/SKILL.md:380-395,310-315`, `scripts/health-check.sh:78-83,400-420,571-600`

---

## Claim 14: "`templates/` (a snippet other repos copy by hand) and `global-instructions/` (every session's global instructions after a release; the floor already refuses its `CLAUDE.md`) take effect outside the gate's view too. So in this repo self-merge can land only files outside those directories and off the floor: docs, `README.md`, `runs/` and `archive/`."

**Location:** `docs/dev-cycle.md:52-55`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the top-level tree at HEAD against the never list and the floor; "docs" is verified as "docs off the floor" (much of `docs/` is floor: working, reviews, decisions, thoughts, roadmap, settings), as the sentence's own qualifier says.
**Legibility-target:** for-orchestrator-synthesis

`git ls-tree --name-only HEAD` lists `.apir5-probe.sh .apir5-probe2.sh .evidence-config.example .gitattributes .gitignore .shellcheckrc AGENTS.md GEMINI.md README.md archive devcontainer-config docs global-instructions guides hooks patterns runs scripts skills templates test workflows` (paraphrased — no quote available because it is a command's listing, not a file). Dot paths are floor (`dot`), `AGENTS.md`/`GEMINI.md` match `INSTRUCTION_FILE` (`scripts/lib/dev-cycle-read.sh:701`), leaving `README.md`, `archive`, `docs`, `runs`. install.sh installs `global-instructions/CLAUDE.md` only: `CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)` (`devcontainer-config/install.sh:135`); `templates/` holds one file, `gitattributes-snippet.txt`.

**Evidence:** `docs/dev-cycle.md:52-55`, `devcontainer-config/install.sh:135`, `scripts/lib/dev-cycle-read.sh:701,1916-1928`, `templates/gitattributes-snippet.txt:1-3`

---

## Claim 15: "Some of those docs are read as authority too (`docs/evaluation-rubric.md`, which self-eval scores against, and `docs/spikes/`, whose seeds later work loads); Q-149 asks whether to list them."

**Location:** `docs/dev-cycle.md:56-58`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both are off the floor and read by later work; does not establish how many skills read `docs/spikes/`.
**Legibility-target:** for-orchestrator-synthesis

`skills/self-eval/SKILL.md:4`: "Score one skill or workflow against docs/evaluation-rubric.md". Neither path matches `truthrule` (no `docs/decisions|human-author`, not a cycle file), and no instruction file `@`-imports them (paraphrased — no quote available because the claim covers absence of `@` imports in `AGENTS.md`, `GEMINI.md`, `global-instructions/CLAUDE.md`). `docs/spikes/` exists with spike records. Q-149 names both (`docs/working/questions.md:369`).

**Evidence:** `skills/self-eval/SKILL.md:4,48`, `scripts/lib/dev-cycle-read.sh:1916-1928`, `docs/working/questions.md:369`

---

## Claim 16: "**Review handoff.** No line. The pull-request route the design names is not built, and this repo has no PRs, so every review merge is one questions entry."

**Location:** `docs/dev-cycle.md:59-60`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that no script reads a `Review handoff:` key and the skill states the route unbuilt; does not establish the repo's PR state beyond the user's memory note.
**Legibility-target:** for-orchestrator-synthesis

`SETTINGS_AWK` keys only `buildlooppolicy`, `buildloopslots`, `selfmergenever`, `readerroots`, `readerhomes` (`scripts/lib/dev-cycle-read.sh:624-628`). Step 7: "(D4's `Review handoff: pull request` route is not built: every review brief gets a merge entry.)" (`skills/dev-cycle/SKILL.md:598-599`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:618-635`, `skills/dev-cycle/SKILL.md:598-599`

---

## Claim 17: The rubric's mapping of findings to the review reports (iteration 1: R1, A1–A7, C1–C12; iteration 2: A8–A11, C13–C21; counts 16 code lines / 12 files / ~300 lines; Confirmed Good lists)

**Location:** `docs/reviews/code-review-rubric-2026-10-14-feat-build-loop-u5.md:13-117`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each row's cited source against the report headings and verdicts (fact-check i1/i2 claim numbers, security i1 F1-F7 and i2 F1-F4, api-consistency i1 F1-F8 and i2 F1-F5) and the diff counts at 42414307; does not re-judge the findings themselves.
**Legibility-target:** for-orchestrator-synthesis

Each cited claim carries the stated verdict (paraphrased — no quote available because it is an awk listing of every `## Claim`/`**Verdict:**` pair in both fact-check reports): i1 claims 6, 8, 10, 24, 42 Mostly accurate; 12, 18, 25, 26, 28 Incorrect; i2 5b Incorrect; 6, 26, 28, 30b, 31, 34 Mostly accurate. Security i1 headings 1-7 and i2 1-4, api i1 F1-F8 and i2 F1-F5 map one to one onto R1/A1/A2/C10/C11/C12, A9-A11/C15, A6/C3/A2/C5-C9, C17-C21. `git diff --numstat main...42414307`: 12 files, 268+33 lines, 16 lines outside `docs/` (6+2, 3+0, 4+1).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-14-feat-build-loop-u5.md:13-117`, `docs/reviews/code-fact-check-report-2026-10-14-u5-i1.md`, `docs/reviews/code-fact-check-report-2026-10-14-u5-i2.md`, `docs/reviews/security-review-2026-10-14-u5-i1.md`, `docs/reviews/security-review-2026-10-14-u5-i2.md`, `docs/reviews/api-consistency-review-2026-10-14-u5-i1.md`, `docs/reviews/api-consistency-review-2026-10-14-u5-i2.md`

---

## Claim 18: "**Status: 🟡 PASSES WITH CONDITIONS at c63da94d** — 0 red; iteration 2's Must Address rows fixed in 659a1c61 and the Q-156 commit after it"

**Location:** `docs/reviews/code-review-rubric-2026-10-14-feat-build-loop-u5.md:5`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the status line against the rubric's own iteration-2 table; does not re-judge whether deferring A10 was right.
**Legibility-target:** for-author

The iteration-2 table has four Must Address rows; three are Fixed but `| A10 | install.sh's archive honors replace refs; state gate misses them (pre-existing) | 🟡 (Medium) | security i2 F2 | Deferred: override row, roadmap Idea; Q-156 refuses for this release |` (`docs/reviews/code-review-rubric-2026-10-14-feat-build-loop-u5.md:105`). Precise version: "iteration 2's Must Address rows fixed in 659a1c61 and b5eaedf6, but A10 deferred (override row 831)".

**Evidence:** `docs/reviews/code-review-rubric-2026-10-14-feat-build-loop-u5.md:5,97-117`, `docs/reviews/override-log.md:831`

---

## Claim 19: The four override-log rows added on this branch (security i1 F7 Won't-Fix; fact-check i1 claim 42; fact-check i2 claims 31, 34; security i2 F2 Defer)

**Location:** `docs/reviews/override-log.md:828-831`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each row's finding, severity and source against the reports and the install.sh lines it cites; does not establish the merits of each override.
**Legibility-target:** for-orchestrator-synthesis

Row 831 cites `devcontainer-config/install.sh:180-182`, `:208-252`, `:279`: `repo_git() { git --no-optional-locks -C "$REPO_ROOT" -c core.hooksPath=/dev/null -c core.fsmonitor=false "$@"; }` (`:180-182`) sets no replace-ref switch, and `git_state_gate` (`:209-252`, read whole) checks config keys `'^(filter\.|core\.fsmonitor|include|hook\.)'` and `info/attributes` only, never `refs/replace/`. Rows 828-830 match security i1 heading 7, fact-check i1 claim 42 (Mostly accurate), i2 claims 31 and 34 (Mostly accurate), and 829-830's "immutable history" fits commits already on the branch.

**Evidence:** `docs/reviews/override-log.md:828-831`, `devcontainer-config/install.sh:172-252`, `docs/reviews/security-review-2026-10-14-u5-i1.md`, `docs/reviews/security-review-2026-10-14-u5-i2.md`

---

## Claim 20: Roadmap Next item 5 "Revisit the light pass between full cycles (C5, Q-154)" and the plan's "Next holds at most five"

**Location:** `docs/roadmap.md:49-53`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the item count and the skill's cap; does not establish the ranking.
**Legibility-target:** for-orchestrator-synthesis

Next holds items 1-5 (`docs/roadmap.md:26,33,37,43,49`); step 6: "- **Next**: at most five items, ranked." (`skills/dev-cycle/SKILL.md:542`). The C5 answer it tracks: `You answered on 2026-10-04: a full cycle every iteration for now, and a move to a light pass of steps 7, 8 and 10` (`docs/working/plan-build-loop-handoff.md:96`).

**Evidence:** `docs/roadmap.md:24-53`, `skills/dev-cycle/SKILL.md:542`, `docs/working/plan-build-loop-handoff.md:96`

---

## Claim 21: Roadmap Ideas: "step 4b names triggers, and its only named dimension is D2's constraints one"; "plan D13 built only `--main-log`'s check of what moved main"; "`repo_git` does not switch replace refs off and `git_state_gate` does not check `refs/replace/`"

**Location:** `docs/roadmap.md:65-80`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three code-facing signals; does not establish the other Ideas' signals beyond their answers in the handoff doc (answers 2, 3, 4 at `docs/working/handoff-build-loop-handoff.md:31-33`, which match).
**Legibility-target:** for-orchestrator-synthesis

Step 4b: "Every deep audit covers one more dimension: whether the constraints and project guidance still match intent ... and checks that `Self-merge never:` covers the paths" (`skills/dev-cycle/SKILL.md:482-487`), one dimension. Plan D13: `This is the minimal part of roadmap item (d), moved into this unit.` (`docs/working/plan-build-loop-handoff.md:103`). install.sh: Claim 19's quotes.

**Evidence:** `docs/roadmap.md:59-80`, `skills/dev-cycle/SKILL.md:469-487`, `docs/working/plan-build-loop-handoff.md:97-105`, `devcontainer-config/install.sh:180-252`

---

## Claim 22: Done entry: "Runs here only after the release (Q-156) and once `docs/constraints.md` exists (Q-155); Q-103 (the policy) is yours."

**Location:** `docs/roadmap.md:125-129`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the dispatch gate on constraints and the image lacking the D6 block; does not establish when the release happens.
**Legibility-target:** for-orchestrator-synthesis

`dispatch` refuses without `constraints ok` (`scripts/build-loop.sh:1633`); `--settings` here prints `constraints missing` (`settings-runs.log`). The image's skill still reads `**Until the D6 block is written** (below; Q-140), no script can run as the Rules require.` (`/opt/claude-workflows/skills/dev-cycle/SKILL.md:19`).

**Evidence:** `scripts/build-loop.sh:1633`, `/opt/claude-workflows/skills/dev-cycle/SKILL.md:19`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r2/settings-runs.log`

---

## Claim 23: Plan D10 "recorded instead as decision-log row 72 (written as row 70 before rows 70 and 71 were taken)" and the U5 as-built note (row 72; slots line; wide never line and its sources; no `Review handoff:` line; Q-149..Q-156; (f) to Next, (e) to Ideas; D10 entry not filed)

**Location:** `docs/working/plan-build-loop-handoff.md:91,358`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the note's facts against the branch's files; does not establish the plan's pre-U5 content.
**Legibility-target:** for-orchestrator-synthesis

Row 72 exists (`docs/decisions/log.md:95`) after rows 70 and 71 (`:93-94`). The note's entry list matches the questions files (Q-149..Q-153, Q-155, Q-156 in `docs/working/questions.md:361-498`; Q-154 in `docs/working/questions-archive.md:2712`), no pre-answered D10 entry exists (paraphrased — no quote available because the claim covers absence of such an entry in both files), and the never line's cited sources are override row 682 and security i1 F1/F3/F4 (headings 1, 3, 4 of the i1 report). Roadmap (f) is Next 5 and (e) the constraints-process Idea (`docs/roadmap.md:49,59`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:91,353-358`, `docs/decisions/log.md:93-95`, `docs/reviews/override-log.md:682`, `docs/roadmap.md:49,59`

---

## Claim 24: Q-154 filed answered and archived: "[1], a full cycle every iteration for now; move to a light pass of steps 7, 8 and 10 between full cycles once the costs are visible"

**Location:** `docs/working/questions-archive.md:2712-2727`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the answer against the plan's record of the 2026-10-04 answer and the files' structure; does not establish the in-session answer itself.
**Legibility-target:** for-orchestrator-synthesis

The plan records `You answered on 2026-10-04: a full cycle every iteration for now, and a move to a light pass of steps 7, 8 and 10 between full cycles once the costs are visible. U5 files C5 as ANSWERED` (`docs/working/plan-build-loop-handoff.md:96`). The archive index carries the row (`:141`). `timeout 60 bash scripts/questions.sh check` (cwd the worktree, 2026-10-15T05:21:07Z, exit 0): `✓ questions: structure valid, indexes current`.

**Evidence:** `docs/working/questions-archive.md:141,2712-2727`, `docs/working/plan-build-loop-handoff.md:96`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r2/questions-check.log`

---

## Claim 25: Q-103's "What the gate can and cannot do" paragraph (same uid with a shell; wrong-directory slips fail loudly; gate decides from main's committed state; root-owned image copy; main moved only by the three classes; no human reads briefs)

**Location:** `docs/working/questions.md:93`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each sentence against the D6 block, `--main-log`'s classes and D13's isolation; does not establish that the image copy is root-owned beyond `stat` of two files.
**Legibility-target:** for-orchestrator-synthesis

The D6 block "always runs the root-owned image copy under D6_OPT by absolute path, never main's copy, a working-tree copy or ~/.claude/scripts" (`skills/dev-cycle/SKILL.md:197-200`); `stat` shows `/opt/claude-workflows/.manifest` and `scripts/build-loop.sh` owned by root. `--main-log` prints `gate|chore|answers|other SHA SUBJECT` (`scripts/build-loop.sh:148`). D13: "a loop's forgotten `cd` fails with "not a git repository" instead of committing to main (F43)" (`docs/working/plan-build-loop-handoff.md:98`).

**Evidence:** `docs/working/questions.md:93`, `skills/dev-cycle/SKILL.md:189-210`, `scripts/build-loop.sh:139-182`, `docs/working/plan-build-loop-handoff.md:97-105`

---

## Claim 26: "**F11, `@`-imports (partly).** ... Precondition: ... the gate runs it in a clean checkout at `MAIN_SHA` (`checkout_gate` refuses anything else). Known gaps (known issue A5): start files under a symlinked directory, in a submodule or in an untracked nested repo; case-insensitive names; checkout conversions; prompt files read by a session started outside the top level; instruction files outside the repo ..."

**Location:** `docs/working/questions.md:95`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the precondition and the gap list against `checkout_gate` and known issue A5; does not establish the walk's grammar coverage.
**Legibility-target:** for-author

The precondition holds: `[[ "$x" == "$MAIN_SHA" ]] || { CHECKOUT_WHY="the checkout's HEAD is $x, not the default branch's commit $MAIN_SHA"; return 1; }` (`scripts/build-loop.sh:1242`, in `checkout_gate`, `:1233-1298`, read whole). But two listed gaps are closed for the gate by that same function: it refuses `core.ignoreCase true` (`:1244`) and any checkout conversion by effect (`a file's checked-out bytes are not the default branch's blob (a filter, working-tree-encoding, ident or eol conversion)`, `:1295`), and an untracked nested repository (`:1271-1273`). A5 itself says so: "U2b2 closes several of these for the gate ... Still open there: start files under a symlinked directory, a FIFO start, other names one file has on a case-insensitive filesystem whose `core.ignoreCase` is false, and a checkout file swapped between the gate's check and the walk's read" (`docs/working/known-issues-dev-cycle.md:18`). Precise version: drop "checkout conversions" and "untracked nested repo", narrow "case-insensitive names" to a case-insensitive filesystem with `core.ignoreCase` false, add the FIFO start and the check-to-read swap. The error is conservative (the gate is stronger than listed).

**Evidence:** `docs/working/questions.md:95`, `scripts/build-loop.sh:1233-1298`, `docs/working/known-issues-dev-cycle.md:18`

---

## Claim 27: Q-103 residuals F19, F21, F29, F35, F37, F58, F59 as stated

**Location:** `docs/working/questions.md:96-102`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers F29's worktree checks in `land`, F35's prompt text, F37's lock and atomic create and the questions check, F58's listing and paste order, F59's drift check, F19's main-log reach; does not establish the claimed race windows by execution.
**Legibility-target:** for-orchestrator-synthesis

F29: `land` (`scripts/build-loop.sh:1484-1575`, read whole) requires the worktree with main "on it at $MAIN_SHA", refuses `MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD BISECT_START rebase-merge rebase-apply sequencer` (`:1535`) and a tracked change (`:1539-1540`), then fast-forwards later (`:1566`), leaving the stated window. F35: `Never start build loops, background agents or schedules; never send your branch to a remote, merge, open a pull request or publish.` (`:1689`). F37: `git update-ref "refs/heads/$br" "$MAIN_SHA" ""` (`:1657`) and `git worktree add -q --lock` (`:1658`); step 9 runs `questions.sh index` and `check` before staging (`skills/dev-cycle/SKILL.md:727-729`). F19: `--main-log` "catches an honest slip, not a commit made to look like one of the others (F19)" (`scripts/build-loop.sh:177-178`). F59: "A finding is a step 4b trigger." (`skills/dev-cycle/SKILL.md:467`).

**Evidence:** `docs/working/questions.md:96-102`, `scripts/build-loop.sh:139-182,1484-1575,1626-1669,1671-1693`, `skills/dev-cycle/SKILL.md:298-311,462-467,727-729`

---

## Claim 28: "**R8, racing the gate's temp files.** ... `git/config`, `git/info/`, `git/refs/`, `git/HEAD`, `work/.gitattributes`, `err`, `diff`, and `answer`, the file holding `--approved`'s verdict on the merge entry (override rows 509, 684)."

**Location:** `docs/working/questions.md:103`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each named file against `gate_repo`, `gate_git`, `check_line` and `approval`, and the two rows; does not establish that the list is every file under GATE_TMP (`status`, `others`, `tree`, `wts`, `msg` also exist there).
**Legibility-target:** for-orchestrator-synthesis

`gate_repo` writes `printf 'ref: refs/heads/none\n' > "$GATE_TMP/git/HEAD"` and the config (`scripts/build-loop.sh:1013-1014`) and makes `git/refs` and `work` (`:1012`); `gate_git` runs in `$GATE_TMP/work` with stderr to `$GATE_TMP/err` (`:1022`); `check_line` writes `$GATE_TMP/diff` (`:1375`); `approval` writes `check_answer "$1" > "$GATE_TMP/answer"; r="$(< "$GATE_TMP/answer")"` (`:1445`). Row 509 is the R8 race row; row 684 is the `answer` file row ("adds `answer` to row 509's surface list").

**Evidence:** `docs/working/questions.md:103`, `scripts/build-loop.sh:1007-1026,1375,1440-1461`, `docs/reviews/override-log.md:509,684`

---

## Claim 29a: Q-103's "also routed here" items that cite override-log rows (668, 548, 749, 750, 784, 786, 787, 797, 801, 802, 682) and units with rows (U3a1, U3a2)

**Location:** `docs/working/questions.md:105-117`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each item's paraphrase against the row at the cited line, and the U3a1/U3a2 items against rows 638, 646, 671; does not establish that no other row routes to Q-103.
**Legibility-target:** for-orchestrator-synthesis

Each row at the cited line holds the item (paraphrased — no quote available because the claim spans 13 table rows; each was read in full): 668 hand-edited rebase todo `update-ref refs/heads/main`; 548 a loop pointing origin/HEAD, read by `reader_settings`; 749 planted pre-commit hook around the orchestrator's commit; 750 FIFO swapped for the health-check lock; 784 rewrite of main to a history with no record; 786 dispatch count written after the dispatch; 787 `--prompt --steal` after a restart; 797 merge entries flag floor paths by class; 801 `--start`/`--prompt` read main after `--main-log`; 802 any `--answered` ID; 682 health-check self-mergeable. U3a1: row 646 ("a rewrite of one of main's objects in place after startup") and row 638 ("the tip's parent ... the merge bases"); U3a2: row 671 (planted `core.bare=true` with the index deleted, "Must Address (Low)").

**Evidence:** `docs/working/questions.md:104-117`, `docs/reviews/override-log.md:548,638,646,668,671,682,749,750,784,786,787,797,801,802`

---

## Claim 29b: "**Also routed here during the build** (override-log rows in `docs/reviews/override-log.md`, by line):" as the source of every item, including "a loop editing the worktree registry in the shared common dir (U2b3a)" and "a same-uid shell's PATH, exported functions or settings around the D6 block (U4c)"

**Location:** `docs/working/questions.md:104-108`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether the U2b3a and U4c items have an override-log row; does not establish that the residuals themselves are wrong (both are real and stated elsewhere).
**Legibility-target:** for-author

No U2b3a or U4c override row routes these to Q-103 (paraphrased — no quote available because the claim covers absence: every `u2b3a` and `u4c` row was grepped for registry, PATH, exported functions and Q-103). Their sources are the plan and the skill: `- Residual: a hostile loop can edit the worktree registry in the shared common dir (Q-103).` (`docs/working/plan-build-loop-handoff.md:293`) and `a hostile process of this uid still reaches the shell itself, through PATH, exported functions or the session's settings: the residual the plan and Q-103 accept` (`skills/dev-cycle/SKILL.md:43-44`). The nearest row, 705 (U3b1, `caller_gate` and PATH), is Won't-Fix, not routed. Precise version: "(override-log rows by line, or the unit whose doc states it)", or cite plan:293 and SKILL.md's D6 Rule.

**Evidence:** `docs/working/questions.md:104-108`, `docs/working/plan-build-loop-handoff.md:293`, `skills/dev-cycle/SKILL.md:43-44,205-206`, `docs/reviews/override-log.md:533-545,705,812-823`

---

## Claim 30: Q-103 options, interim and "If the answer differs" ([1] N-rule-passing ready branches get one merge entry; [2] only docs, `README.md`, `runs/`, `archive/` off the floor can self-merge; interim read as unset; for [2] the never line must stay valid)

**Location:** `docs/working/questions.md:119-125`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the options against step 7 and `srules`, and the interim and the [2] precondition by `--settings`; does not establish the "If it's wrong" consequences.
**Legibility-target:** for-orchestrator-synthesis

[1] matches step 7's review branch (Claim 7); [2] matches Claim 14. Executed: the interim line gives `policy review unset`; with `self-merge` and a valid never line, `policy self-merge set`; with a malformed never line, `policy review unset ... so self-merge is off` (`settings-runs.log`, `settings-variants.log`).

**Evidence:** `docs/working/questions.md:119-125`, `scripts/build-loop.sh:795-822`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r2/settings-runs.log`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r2/settings-variants.log`

---

## Claim 31a: Q-149's body and options (what review found; the two authority docs; [2] "a self-merged script or test runs in the next health check, and a self-merged `install.sh` runs on your host at the next release"; Blocks nothing while the policy is review)

**Location:** `docs/working/questions.md:361-378`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the body against Claims 13-15 and the "Blocks" line against the S rules running only for self-merge briefs; does not establish the options' costs.
**Legibility-target:** for-orchestrator-synthesis

`[[ "$pol" != self-merge || "$AUTH" == approved ]] || sm=1  # the S rules and the checkout` (`scripts/build-loop.sh:1362`) and `srules` runs only when `sm` is set (`:1412`), so the never line has no effect under review.

**Evidence:** `docs/working/questions.md:361-378`, `scripts/build-loop.sh:1362,1412`

---

## Claim 31b: Q-149 "**If the answer differs:** a one-line edit to `docs/dev-cycle.md` ... and its test line in `test/scripts/build-loop-read.bats`."

**Location:** `docs/working/questions.md:379`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what else in the branch states the never line's width; does not establish whether the user would want the prose kept.
**Legibility-target:** for-author

The settings line is one line, and the test pins it (`test/scripts/build-loop-read.bats:80`). But the Never-line bullet's prose also states the width: "Here it holds every code and process directory whose files take effect in this repo without a release ... So in this repo self-merge can land only files outside those directories and off the floor: docs, `README.md`, `runs/` and `archive/`." (`docs/dev-cycle.md:45-55`), and Q-103 [2] repeats the docs-only consequence (`docs/working/questions.md:122`). Precise version: "the never line, its prose in the Never-line bullet, and its test line".

**Evidence:** `docs/working/questions.md:379`, `docs/dev-cycle.md:45-55`, `docs/working/questions.md:122`, `test/scripts/build-loop-read.bats:79-81`

---

## Claim 32: Q-150..Q-153 ([1] built defaults: orchestrator the only writer with `--marker` quoting; a blocked loop frees its slot and is re-sent ahead of new briefs; poll every 1200–1800 s; global rule forbids deleting branches)

**Location:** `docs/working/questions.md:381-444`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each [1] against SKILL.md and build-loop.sh and Q-153's quote against the global instructions; does not establish the [2]/[3] consequences.
**Legibility-target:** for-orchestrator-synthesis

`--marker` prints the body "each line prefixed "> "" (`scripts/build-loop.sh:97-101`); step 8 counts "those it sends back to a loop" and step 10 fills "briefs step 7 sends back first, then absent ones" (`skills/dev-cycle/SKILL.md:650,774-775`); the wait rule "with none, every 1200-1800 s, and only when the default branch moved past this iteration's last land ... a retry's wait ran out, or the user wrote" (`:806-810`). The global instructions list "deleting branches" under "Still require user approval (regardless of mode)" (paraphrased — no quote available because the file is the session's injected `/home/node/.claude/CLAUDE.md`, outside the repo).

**Evidence:** `docs/working/questions.md:381-444`, `scripts/build-loop.sh:93-123`, `skills/dev-cycle/SKILL.md:647-653,767-775,804-811`

---

## Claim 33: Q-155 "Interim: [2]. `--settings` prints `constraints missing`, and step 10 files nothing more while this entry is open."

**Location:** `docs/working/questions.md:446-461`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the printed line on this repo's files and the step-10 slug match; does not establish an orchestrator run.
**Legibility-target:** for-orchestrator-synthesis

Executed: `constraints missing: no docs/constraints.md on the default branch` (`settings-runs.log`). Step 10: "else one `you: judgment` entry, slug `constraints-doc-missing`, ... unless an open one with that slug exists" (`skills/dev-cycle/SKILL.md:770-772`); the entry's heading is `### Q-155 · constraints-doc-missing` (`docs/working/questions.md:446`).

**Evidence:** `docs/working/questions.md:446-461`, `skills/dev-cycle/SKILL.md:767-772`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r2/settings-runs.log`

---

## Claim 34: Q-156's C (from `.manifest`, on main's first-parent history), M = 659a1c61 as the last branch commit touching released paths, the gate-code list, the eleven first-parent commits and the 28 paths outside `docs/` (about 500 under `docs/`, nearly all `docs/reviews/`)

**Location:** `docs/working/questions.md:470-489`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each list against git at HEAD b5eaedf6 and main b279a2ba; does not establish main's state when the paste runs.
**Legibility-target:** for-orchestrator-synthesis

`/opt/claude-workflows/.manifest`: `commit=8d0e660e2e5a9769200500ac3dcfb4b113a32589`, `assembled_from=/home/magfrump/claude-workflows`; `git rev-list --first-parent main | grep -c 8d0e660e...` printed 1. `git log --first-parent --format='%h %s' 8d0e660e..main` printed the same eleven commits, newest first (b279a2ba ... 308196e7), none ending `(build-loop self-merge)`. `git log -1 -- .gitattributes devcontainer-config global-instructions guides hooks patterns scripts skills workflows` on the branch gives `659a1c61`; `b5eaedf6` touches only `docs/`. `git diff --name-only 8d0e660e 659a1c61 | grep -v '^docs/'` printed exactly the entry's 28 paths (`test/lib/d6-snippet.bash` status `D`); 505 under `docs/`, 494 of them `docs/reviews/`. Gate paths changed: `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `skills/dev-cycle/SKILL.md`. Commands run in the worktree on 2026-10-15 (paraphrased — no quote available because the outputs were read in-session and are reproduced here, not logged to a file; each is a deterministic read of committed history).

**Evidence:** `docs/working/questions.md:470-489`, `/opt/claude-workflows/.manifest`

---

## Claim 35: Q-156's paste: "with only `rev-parse` and `for-each-ref` ... and replace refs ignored, it checks that HEAD is main, that no replace ref or graft file exists ..., and that the root `.gitattributes` and every directory the release installs from are the same tree at HEAD as at M; so it refuses when main has moved a released path past what this entry lists"

**Location:** `docs/working/questions.md:491-496`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the paste's checks (install.sh swapped for an echo) on a simulated post-merge main and five mutations, and its directory list against install.sh; "HEAD is main" is verified as "HEAD's commit equals main's commit" (another branch or a detached HEAD at that commit passes); does not establish install.sh's own run or a `GIT_GRAFT_FILE` pointing elsewhere.
**Legibility-target:** for-orchestrator-synthesis

The paste calls only `git rev-parse` and `git for-each-ref` inside a subshell that exports `GIT_NO_REPLACE_OBJECTS=1` (`docs/working/questions.md:494`). The directory list is `CLAUDE_HOME_SRC`'s directories (`global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts`, `devcontainer-config/install.sh:135`) plus install.sh's own `devcontainer-config` (its `PAYLOAD`, `:110`) and `.gitattributes`. Executed (`paste-runs.log`; cwd `.../fc-final-r2/bare.git`, a bare clone whose `main` is a commit-tree merge of b5eaedf6 into b279a2ba; 2026-10-15T05:16:38Z; cmd `timeout 60 bash .../paste-check.sh`): post-merge main `PASS-would-run-install.sh` exit 0; replace ref `release refused: replace refs present` exit 1; `info/grafts` `release refused: info/grafts present` exit 1; HEAD on another branch `release refused: HEAD is not main` exit 1; a commit adding `scripts/zz-new` on main `release refused: scripts differs from M` exit 1; a docs-only commit on main `PASS` exit 0.

**Evidence:** `docs/working/questions.md:491-496`, `devcontainer-config/install.sh:110,135`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r2/paste-check.sh`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r2/paste-runs.log`

---

## Claim 36: "**If the paste refuses:** main changed a released path after M. That change is not in the lists above; read `git log --first-parent M..main` before rewriting this entry with a new M."

**Location:** `docs/working/questions.md:498`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the paste's refusal reasons as executed; does not establish what the user should do for the other three.
**Legibility-target:** for-author

The paste has four refusals, each printing its reason (Claim 35's runs): `HEAD is not main`, `replace refs present`, `info/grafts present` and `<dir> differs from M`. Only the last means "main changed a released path after M"; the other three are fixed by checking out main or removing planted state, not by rewriting the entry. Precise version: "If the paste refuses with `differs from M`: main changed a released path after M ...; on any other refusal, fix what it names".

**Evidence:** `docs/working/questions.md:494-498`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r2/paste-runs.log`

---

## Claim 37: Q-156 "The image's dev-cycle skill lacks the D6 block (U4c), so the orchestrator loop cannot run as written until this release."

**Location:** `docs/working/questions.md:470`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the installed image skill's text; does not establish that no other copy is installed.
**Legibility-target:** for-orchestrator-synthesis

`/opt/claude-workflows/skills/dev-cycle/SKILL.md:19`: `**Until the D6 block is written** (below; Q-140), no script can run as the Rules require.` The branch's skill has `## The D6 block` (`skills/dev-cycle/SKILL.md:189`).

**Evidence:** `/opt/claude-workflows/skills/dev-cycle/SKILL.md:19,47-51`, `skills/dev-cycle/SKILL.md:189-210`

---

## Claim 38: Research corrections: "`/opt/claude-workflows/scripts/build-loop.sh` is in the image now (its `.manifest` commit was 8d0e660e on 2026-10-14), and since Q-140 [1] the D6 block always runs that root-owned image copy, in this repo too"; "the cycle does spawn loops itself, as background subagents with no isolation, in a worktree `build-loop.sh --start` creates (plan D1)"

**Location:** `docs/working/research-build-loop-handoff.md:23,59`
**Type:** Staleness / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file's presence and ownership, the commit date and step 10's launch; does not establish when the image was built.
**Legibility-target:** for-orchestrator-synthesis

`/opt/claude-workflows/scripts/build-loop.sh` exists, owned by root; `git log -1 8d0e660e` is dated `2026-10-14 00:12:07 -0700`. Step 10: "start one background subagent (Agent tool, no isolation)" after `--start BRIEF` (`skills/dev-cycle/SKILL.md:777-780`), and `dispatch` creates the worktree with `git worktree add -q --lock` (`scripts/build-loop.sh:1658`).

**Evidence:** `docs/working/research-build-loop-handoff.md:23,59`, `skills/dev-cycle/SKILL.md:197-200,777-783`, `scripts/build-loop.sh:1626-1669`

---

## Claim 39: Seed "**Status:** superseded by decision log row 72 (the build-loop handoff as built, merged with `feat/build-loop-u5`; plan `docs/working/plan-build-loop-handoff.md`)"

**Location:** `docs/working/seed-build-loop-handoff.md:3`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the referenced row and plan; "merged with" is prospective (true once this branch merges).
**Legibility-target:** for-orchestrator-synthesis

Row 72's last column reads "Supersedes the seed." (`docs/decisions/log.md:95`).

**Evidence:** `docs/working/seed-build-loop-handoff.md:3`, `docs/decisions/log.md:95`

---

## Claim 40: Step 0.1's release listing: "every first-parent commit after C as a list item (`hg -C MAIN_WT log --first-parent --format='%h %s' C..M`; flag a subject ending `(build-loop self-merge)` ... the flag is a pointer, not proof), every path changed from C to M outside `docs/` on one line ... (the image carries none of `docs/`: give its count), each subject or path holding `<`, `>`, a backtick, a CR, another control or bidi character, or bytes that are not UTF-8 written as `(withheld: see SHA)` (questions.sh finds its `<!-- index:` markers anywhere in a line, and `--check-answer` refuses an unclosed `<!--`)"

**Location:** `skills/dev-cycle/SKILL.md:298-310`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the self-merge subject form, the image's lack of `docs/`, and the withheld rule's stated reason against questions.sh and the lib; does not establish that every line shape the rule lets through is safe (the iteration-2 security review's F4 covers that).
**Legibility-target:** for-orchestrator-synthesis

`gate_msg` writes `"Merge branch '%s' (build-loop %s)"` with WHAT `self-merge` (`scripts/build-loop.sh:1463-1466`). `/opt/claude-workflows/` holds `CLAUDE.md guides hooks patterns scripts skills workflows`, no `docs`. questions.sh: `sed -n "/$INDEX_START/,/$INDEX_END/p"` (`scripts/questions.sh:294`, an unanchored regex) and `grep -aqF "$INDEX_START"` (`:312`) with `INDEX_START='<!-- index:start -->'` (`:140`). `check_answer` reads through `"$FENCE_AWK$ANSWER_AWK"` (`scripts/lib/dev-cycle-read.sh:2149`), whose `fence()` does `if (opencomment(l)) { refuse("comment"); return 1 }` (`:313`).

**Evidence:** `skills/dev-cycle/SKILL.md:296-315`, `scripts/build-loop.sh:1463-1466`, `scripts/questions.sh:140,294,312`, `scripts/lib/dev-cycle-read.sh:276-316,2136-2160`

---

## Claim 41: Step 10: "else one `you: judgment` entry, slug `constraints-doc-missing`, asking for `docs/constraints.md`, unless an open one with that slug exists: D2"

**Location:** `skills/dev-cycle/SKILL.md:770-772`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency with Q-155's heading and the `constraints` line the step keys on; does not establish an orchestrator run.
**Legibility-target:** for-orchestrator-synthesis

Q-155's heading is `### Q-155 · constraints-doc-missing` (`docs/working/questions.md:446`); the step keys on `constraints ok`, which `read_settings` prints only when `[[ "$c" -gt 0 ]]` hard constraints exist (`scripts/build-loop.sh:835`).

**Evidence:** `skills/dev-cycle/SKILL.md:767-772`, `docs/working/questions.md:446`, `scripts/build-loop.sh:829-842`

---

## Claim 42: The real-settings test asserts the interim never line and the slots line ("The interim never line (every directory that takes effect here without a release: plan D5, F57, Q-149) and the slots line (U5).")

**Location:** `test/scripts/build-loop-read.bats:79-81`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the one test against the branch's `docs/dev-cycle.md`; does not run the rest of the suite.
**Legibility-target:** for-orchestrator-synthesis

Command (cwd the worktree, 2026-10-15T05:19:41Z): `TMPDIR=<scratch> timeout 300 bats test/scripts/build-loop-read.bats -f 'own docs/dev-cycle.md'`, exit 0: `ok 1 --settings on this repo's own docs/dev-cycle.md: review, unset by the interim note (T3, G19)`.

**Evidence:** `test/scripts/build-loop-read.bats:71-82`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r2/bats-real-settings.log`

---

## Claim 43: Onboarding step 13: self-merge "covers only paths a brief lists that are outside what takes effect on merge with no later review, such as instruction files, dot paths and the gate's own code, plus any the project adds to its `Self-merge never:` line, which self-merge requires: `Self-merge never: none` for an empty list"; review is "one "merge?" entry ... per finished branch; a branch that changes `docs/constraints.md` or the cycle's own files ends stopped under either policy"; the constraints doc's form and dispatch gate

**Location:** `workflows/codebase-onboarding.md:453-460`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each clause against `srules`, `read_settings`, Claim 8's routing, `CONSTRAINTS_AWK` and `dispatch`; "per finished branch" is verified for branches `--check` passes (a refused one is filed as stopped, which the sentence's second half covers).
**Legibility-target:** for-orchestrator-synthesis

`CONSTRAINTS_AWK` reads `/^(- )?[HS][123456789][0123456789]*: [^ \t]/` and requires a `success:` line per hard one (`scripts/build-loop.sh:720-741`); `dispatch` refuses unless `CONSTRAINTS` is `ok` (`:1633`), which needs at least one hard constraint (`:835`). The never-line requirement: Claim 9. Both-policy refusals: Claim 8. The roadmap item it names exists (`docs/roadmap.md:59`).

**Evidence:** `workflows/codebase-onboarding.md:453-460`, `scripts/build-loop.sh:716-741,816-822,829-842,1633`, `docs/roadmap.md:59`

---

## Claim 44: Commit bodies 92fa6e52, 2846f9fa, 42414307, 771a5d02, 57e26f6b, 87ca421e, c63da94d and 659a1c61, as of each commit

**Location:** `git log main..HEAD` (92fa6e52, 2846f9fa, 42414307, 771a5d02, 57e26f6b, 87ca421e, c63da94d, 659a1c61)
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers each body's what-changed claims against its own diff stat and the files at HEAD; the three already-recorded imprecisions (2846f9fa's "residuals earlier units routed", 771a5d02's group order, c63da94d's "6 Must Address") are covered by override rows 829-830 and not re-verdicted; does not re-check superseded details (2846f9fa's HEAD-vs-main paste, 57e26f6b's M=771a5d02), which were true of their commits.
**Legibility-target:** for-orchestrator-synthesis

659a1c61's stat is `docs/dev-cycle.md`, `skills/dev-cycle/SKILL.md`, `workflows/codebase-onboarding.md`, matching "Settings prose ... Onboarding names docs/constraints.md ... SKILL.md step 0.1 puts the path list on one backticked line"; 87ca421e's "eight of its ten directories" fixed by the templates/global-instructions sentence (`docs/dev-cycle.md:52-55`); 2846f9fa's "items (a)-(g); (f) is Next 5" matches seven roadmap additions then (Next 5 plus six Ideas; the install.sh Idea came in b5eaedf6). (paraphrased — no quote available because the claim spans eight commit messages, each read in full with `git log --format='%h %s%n%b' main..HEAD`.)

**Evidence:** `docs/dev-cycle.md:52-55`, `docs/roadmap.md:49-80`, `docs/reviews/override-log.md:829-830`

---

## Claim 45: Commit b5eaedf6 body: "Iteration 2's reports, rubric section and three override rows."

**Location:** `git log -1 b5eaedf6`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the override-log lines the commit adds; does not establish the rest of the body (Q-156's M, GIT_NO_REPLACE_OBJECTS, replace refs, grafts, `.gitattributes`, Q-149's two docs, the plan note and the roadmap Idea, all verified in Claims 15, 21, 23, 35).
**Legibility-target:** for-author

`git show --format= b5eaedf6 -- docs/reviews/override-log.md` adds two rows, not three: the "Commit 771a5d02's body ... commit c63da94d's body" row (`docs/reviews/override-log.md:830`) and the install.sh replace-ref row (`:831`); the first row covers three findings (fact-check i2 claims 31 and 34, and the earlier i1 pair is c63da94d's). Precise version: "two override rows". Immutable history; this belongs in an override row if acted on.

**Evidence:** `docs/reviews/override-log.md:828-831`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 11** (`docs/dev-cycle.md:39-42`): step 10 subtracts only "the loops this session runs", and step 8's uncounted list also names capped (and stalled) briefs; tighten the Slots bullet to the skill's wording.
- **Claim 18** (`docs/reviews/code-review-rubric-2026-10-14-feat-build-loop-u5.md:5`): status says iteration 2's Must Address rows are fixed, but A10 is deferred (override row 831).
- **Claim 26** (`docs/working/questions.md:95`): F11's gap list still names checkout conversions, an untracked nested repo and case-insensitive names, which `checkout_gate` closes for the gate (A5 says so); omits the FIFO start and the check-to-read swap A5 lists as still open.
- **Claim 29b** (`docs/working/questions.md:104-108`): the "override-log rows ... by line" header does not hold for the U2b3a registry item (plan:293) or the U4c PATH/functions item (SKILL.md's D6 Rule); neither has a routing row.
- **Claim 31b** (`docs/working/questions.md:379`): changing the never line is more than a one-line edit, since the Never-line bullet's prose (`docs/dev-cycle.md:45-55`) and Q-103 [2] state its width.
- **Claim 36** (`docs/working/questions.md:498`): "If the paste refuses" names only the `differs from M` cause; the paste also refuses for HEAD not main, replace refs and grafts.
- **Claim 45** (commit b5eaedf6): "three override rows" where the commit adds two (immutable history).

### Unverifiable
- None.

---

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u5/docs/reviews/code-fact-check-report-2026-10-14-u5-final-rN.md (N as given at the end of this prompt), structured per the code-fact-check skill, first line `Commit: b5eaedf6`.
- Answered: yes; all eleven focus areas checked, the settings, paste, glob, test and questions-check claims executed; no Incorrect, seven Mostly accurate (all doc wording, none blocking).
- Out of scope: the hallucination-pattern log update (no fabrication found, and the brief forbids editing tracked files); the review reports' own internal claims beyond the rubric's mapping.
- Escalate: Claim 26 is the most substantive: Q-103 asks the user to weigh F11 with a gap list that overstates what the gate misses (conservative, but it is the input to the policy decision).
- Decisions I made: split the Q-103 "also routed" claim into the row-cited items (Verified) and the header's provenance (Mostly accurate) rather than one compound verdict; ran Q-156's paste in a bare clone with a commit-tree merge instead of checking out main, to honor "never check out branches anywhere".
