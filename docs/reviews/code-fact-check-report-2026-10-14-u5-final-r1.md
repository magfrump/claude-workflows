Commit: b5eaedf6

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u5`, branch `feat/build-loop-u5`)
**Scope:** full branch, `git diff main...HEAD` (merge base b279a2ba; 20 files), plus commit messages main..HEAD; code read: `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `scripts/questions.sh`, `scripts/health-check.sh`, `devcontainer-config/install.sh`, `skills/dev-cycle/SKILL.md`, `docs/reviews/override-log.md`, `docs/working/plan-build-loop-handoff.md`
**Checked:** 2026-10-14 (final confirming pass, decision log 63)
**Replication:** k=3, this is replicate r1
**Total claims checked:** 44
**Summary:** 34 verified, 9 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). The one Incorrect (Claim 41, a count in a commit body) resembles the logged "count claimed in a commit message" entries (e.g. "All 85 tests ... but the suites hold 97") but is a miscount, not a fabricated symbol, so it does not qualify for the log. (This run must not edit tracked files in any case.)

Execution logs are in the scratch dir `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r1/` (abbreviated `$S` below). Every executed command ran with `GIT_CONFIG_GLOBAL=/dev/null` under `timeout`; all processes exited before this report was written.

---

## Claim 1: Decision-log row 72's D1–D14 summary

**Location:** `docs/decisions/log.md:95`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each D-item's summary in row 72 against the plan's D1–D14 and the scripts' behavior for D1 (cap 4, dispatch), D2 (no dispatch without a hard constraint), D4 (merge entry slugs, `--approved`), D5 (floor + never line), D6 (image copy), D7, D9 (default 3) and D14; does not establish the plan's own F-table claims that row 72 does not repeat.

Row 72 says D2: "a repo without a hard constraint there gets no dispatch". Dispatch refuses unless the constraints word is ok: `if [[ "$CONSTRAINTS" != ok ]]; then x="no loop is dispatched until --settings reads the constraints as ok ..."` (`scripts/build-loop.sh:1633`), and ok needs a hard constraint: `ok) if [[ "$c" -gt 0 ]]; then CONSTRAINTS_LINE="constraints ok ..." else CONSTRAINTS_LINE="constraints none-hard: ..."` (`scripts/build-loop.sh:830-831`). D4's slugs match `approval()`: `s="merge-"` / `s="merge-gate-"` then `s+="${VERDICT[stem]}-${VERDICT[tip]:0:12}"` (`scripts/build-loop.sh:1440-1462`, read whole). D5's floor + never line matches `srules()` (`scripts/build-loop.sh:1202-1217`, read whole) and the lib's `floor()` (`scripts/lib/dev-cycle-read.sh:1997-2017`). D9 "default 3" matches `slots 3 default` (`scripts/build-loop.sh:818-821`). D7 "merge-tree ... commit-tree, compare-and-swap" matches `land()`: `gate_git commit-tree --no-gpg-sign -p "$MAIN_SHA" -p "${VERDICT[tip]}"` and `git update-ref --no-deref -m "$msg" "refs/heads/$MAIN" "$NEW" "$MAIN_SHA"` (`scripts/build-loop.sh:1554-1565`, enclosing `land()` 1484-1575 read). The D-items' wording otherwise tracks the plan's headings (paraphrased — no quote available because the comparison spans fourteen plan bullets at `docs/working/plan-build-loop-handoff.md:39-106`, each read).

**Evidence:** `docs/decisions/log.md:95`, `docs/working/plan-build-loop-handoff.md:39-106`, `scripts/build-loop.sh:785-838`, `:1202-1217`, `:1440-1462`, `:1484-1575`, `:1626-1665`, `scripts/lib/dev-cycle-read.sh:1997-2017`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 2: Row 72's D10 rationale: the user's answers 1, 5, 8, 9 quoted; "The prose-only seed failed review passes 6–9 (log row 68)"

**Location:** `docs/decisions/log.md:95`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three verbatim quotes against the handoff doc and the passes-6–9 reference against row 68; does not establish answer 5's paraphrase beyond its gist.

The quotes appear verbatim: `1. "start a cycle should be kick off a loop, not assumed stopping after one cycle"`, `8. "next loop should start autonomously; the point is to work through all threads ..."`, `9. ... "then tasks deferred rather than blocking the loop"` (`docs/working/handoff-build-loop-handoff.md:30,37,38`). Row 68 says "passes 6–9 kept finding reds in its prose-only protocol" (`docs/decisions/log.md:91`).

**Evidence:** `docs/working/handoff-build-loop-handoff.md:30-38`, `docs/decisions/log.md:91`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 3: "The scripts read the three lines above, and the two reader lines below, from the default branch's commit, never from a working tree ...; the orchestrator reads them through `scripts/build-loop.sh --settings`"

**Location:** `docs/dev-cycle.md:13-16`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `read_settings` and `reader_settings` read the file from `$MAIN_SHA` and that `--settings` prints the five lines; does not establish every other script consumer beyond build-loop.sh and the lib.

`main_file` reads `git cat-file blob "$MAIN_SHA:$f"` (`scripts/lib/dev-cycle-read.sh:597-616`, read whole); `read_settings` and `reader_settings` both call `main_file "$f" "$SETTINGS_AWK"` (`scripts/build-loop.sh:790`, `scripts/lib/dev-cycle-read.sh:663`). Executed: the branch's file committed on `main` in a throwaway repo printed the five lines (policy, slots, never, constraints, readers).

Command: `cd $S/repo && GIT_CONFIG_GLOBAL=/dev/null timeout 60 bash /workspace/.claude/wt-build-loop-u5/scripts/build-loop.sh --settings`; cwd `$S/repo` (one commit on `main` holding the branch's `docs/dev-cycle.md`); exit 0; 2026-10-15T05:13:35Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:597-616`, `:663`, `scripts/build-loop.sh:785-838`, `$S/settings-review.out`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 4: "A line counts only when it is the one line in the file, outside code blocks, that starts with its key; a trailing CR is ignored."

**Location:** `docs/dev-cycle.md:16-17`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the copy-counting rule in SETTINGS_AWK and the next-line rule in read_settings/reader_settings; does not establish anything about lines inside fences beyond FENCE_AWK skipping them.

Copies are counted on letters alone, case folded, not on "starts with its key": `s = tolower($0); gsub(/[^a-z]/, "", s); ... if (index(s, "buildlooppolicy") == 1) k = "policy"` (`scripts/lib/dev-cycle-read.sh:618-635`, read whole). So a line such as `**Build-loop policy:** self-merge` or `- Build-loop policy: x` also counts as a copy and unsets the policy, though it does not "start with its key". The never and reader lines also need the next unfenced line blank: `if [[ "$LIST_BAD" != form && "${next[never]}" != 1 ]]; then why="is followed by a non-blank line outside a fence ..."` (`scripts/build-loop.sh:808-809`). The effect of both differences is fail-closed (more cases read as unset or malformed), and the sentence defers to `--settings`' header for exact forms. Precise version: "A line counts only when it is the only line, outside code blocks, whose letters (case folded) start with its key, and it reads exactly as `--settings`' header gives; the never and reader lines must be followed by a blank line."

**Evidence:** `scripts/lib/dev-cycle-read.sh:618-635`, `scripts/build-loop.sh:793-809`, `scripts/build-loop.sh:57-61` (header: "a line counts as one when its letters alone, case folded, start with the key's")
**Legibility-target:** for-author

---

## Claim 5: Policy: self-merge lands "only when every changed path is listed in the brief's `Paths:` line or is one of the brief's own files (named by its stem), and none is on the gate's fixed floor (instruction files and what they `@`-import, any dot path, the gate's own code, files later runs read as truth such as `docs/decisions/` and `docs/constraints.md`, symlinks and gitlinks) or matches the never line"

**Location:** `docs/dev-cycle.md:19-25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers srules' order (floor, never globs, allowlist) and the floor's listed classes; does not establish the floor's unlisted classes (other briefs' working docs, reviews, docs/thoughts/), which the sentence's "such as" leaves open.

`srules()`: `if [[ -z "$5" ]] && floor "$2" "$1" "$4" "$3"; then DENY=...; return 0; fi` then the never regexes, then `ownfile`, then `PATHS` (`scripts/build-loop.sh:1202-1217`, read whole). `floor()` refuses `truthrule` words (instr, dot, cycle, settings, user, record = `docs/(decisions|human-author)/`), `GATE_CODE`, and `truthwalk main` (imports) (`scripts/lib/dev-cycle-read.sh:1997-2017`, read whole; truthrule at `:1916-1926`). Symlinks and gitlinks are refused by the mode rule in `nrules`: `DENY="a symlink, gitlink or other non-file entry on one side ..."` (`scripts/build-loop.sh:1145`), which the lib's floor comment calls "floor item 5, symlinks and gitlinks, is the caller's mode rule" (`scripts/lib/dev-cycle-read.sh:1988-1989`), so listing them under the floor matches the plan's D5 numbering.

**Evidence:** `scripts/build-loop.sh:1141-1217`, `scripts/lib/dev-cycle-read.sh:1916-2017`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 6: "A self-merge refused for a path falls through to review; a conflict is filed as stopped, and an environment refusal is retried."

**Location:** `docs/dev-cycle.md:25-26`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers SKILL.md step 7's routing of `--merge` refusals and check_line's refusal texts; does not establish the orchestrator's runtime adherence.

SKILL.md step 7: "A refusal of the paths ("K of N changed paths refused", `deny` lines following) falls through to review ... A conflict is `stopped`. Any other refusal (no identity, MAIN_WT's state, a moved main, a failed read) is the environment's ... tried again next iteration." (`skills/dev-cycle/SKILL.md:584-594`). check_line prints `refuse $a: $br conflicts with the default branch` and `refuse $a: $nd of ${#ps[@]} changed paths refused` (`scripts/build-loop.sh:1349-1418`, read whole).

**Evidence:** `skills/dev-cycle/SKILL.md:584-594`, `scripts/build-loop.sh:1349-1418`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 7: Under review, one merge entry (`merge-STEM-SHA12`, or `merge-gate-STEM-SHA12` when the change touches the gate's own code) holding `--check`'s output; merges only on `[1] merge`

**Location:** `docs/dev-cycle.md:26-29`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the slug rule in approval() and step 7's entry; does not establish the answer parser beyond check_answer's keep/drop/done words.

`approval()` requires `"keep $1"` and `[[ "$ANSWER_HEADING" == "$1 · $s" ]]`, `s` being `merge-` or `merge-gate-` + stem + 12 hex (`scripts/build-loop.sh:1440-1462`); `VERDICT[gate]` is set when `[[ ! "${lps[$i]}" =~ $GATE_CODE ]] || gc=1` (`scripts/build-loop.sh:1411`). Step 7 files "`### Q-NNN · merge-STEM-SHA12` ... Its body: the full TIP (row 673), `--check`'s lines as printed" (`skills/dev-cycle/SKILL.md:595-605`).

**Evidence:** `scripts/build-loop.sh:1411`, `:1440-1462`, `skills/dev-cycle/SKILL.md:595-605`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 8: "Under both policies the N rules refuse a change to `docs/constraints.md`, this file, the cycle's own files (...) or any brief beyond the brief's own Status line: under review such a branch is filed as stopped; under self-merge it first comes to you as a merge entry, whose `[1] merge` the gate then refuses, so it ends as stopped."

**Location:** `docs/dev-cycle.md:29-33`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers nrules' file list and both routes through step 7; does not establish the N rules' other refusals (path form, modes), which the sentence does not claim to list.

`nrules()`: `case "$TRUTH_WHY" in cycle|settings) DENY="one of the dev cycle's own files" ;; user) DENY="the user's constraints doc ..." ;; *) [[ ! "$7" =~ ^docs/working/(briefs|cycles)(/|$) ]] || DENY=...` and the own brief only if `"$5" == M && "$2" == "$3" ... "$4" == "$ob"` (`scripts/build-loop.sh:1141-1168`, read whole). Under review, step 7: "A `refuse` verdict is filed as `stopped`" (`skills/dev-cycle/SKILL.md:606-607`). Under self-merge: path refusal → merge entry, "(a deny from a rule every merge applies refuses again under `--approved`, and is then filed as `stopped`)" (`skills/dev-cycle/SKILL.md:587-589`); `--approved` runs `AUTH=approved`, N rules alone (`scripts/build-loop.sh:1355`).

**Evidence:** `scripts/build-loop.sh:1141-1168`, `:1355`, `skills/dev-cycle/SKILL.md:584-607`, `:629-633`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 9: "A brief self-merges only when its own `Policy:` line also reads `self-merge`. Only the exact line with `self-merge` or `review` sets the policy, and `self-merge` also needs a valid never line (its `none` form for an empty list). Anything else counts as unset, which means `review`"

**Location:** `docs/dev-cycle.md:33-37`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers status_fields' policy rule and read_settings' policy/never coupling, exercised on the branch's file, its flipped copy, main's file flipped, and a file with `Self-merge never: none` followed by a non-blank line; does not establish every malformed-never shape (the bats suite T45 covers those).

`[[ "$POLICY" == self-merge && "${BRIEF[policy]-}" == "Policy: self-merge" ]] && pol=self-merge` (`scripts/build-loop.sh:906`, `status_fields` 886-928 read). `if [[ "$v" == self-merge && -z "$never_ok" ]]; then POLICY_LINE="policy review unset: ... no valid Self-merge never: line ..."` (`scripts/build-loop.sh:813-815`). Executed results: branch file → `policy review unset: line 7 is not exactly ...`; flipped to `Build-loop policy: self-merge` → `policy self-merge set: line 7`; main's file (no never line) flipped → `policy review unset: line 7 reads self-merge, but there is no valid Self-merge never: line`.

Commands: `GIT_CONFIG_GLOBAL=/dev/null timeout 60 bash /workspace/.claude/wt-build-loop-u5/scripts/build-loop.sh --settings`, cwd `$S/repo`, after commits flipping the line; each exit 0; 2026-10-15T05:13:35Z and following.

**Evidence:** `scripts/build-loop.sh:785-838`, `:886-928`, `$S/settings-review.out`, `$S/settings-selfmerge.out`, `$S/settings-mainfile.out`, `$S/settings-mainfile-selfmerge.out`, `$S/settings-none.out`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 10a: "From 1 to 9 (anything else, or no line, means 3)"

**Location:** `docs/dev-cycle.md:38`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers read_settings' slots regex, `slots 3 set` on the branch file, `slots 3 default` on main's file and on `Build-loop slots: 10`; does not establish consumers' use of the value (Claim 10b).

`elif [[ "${text[slots]}" =~ ^Build-loop\ slots:\ ([123456789])$ ]]; then SLOTS_LINE="slots ${BASH_REMATCH[1]} set: ..."` else `slots 3 default` (`scripts/build-loop.sh:818-821`). Executed (same runs as Claim 9): `slots 3 set: line 9`, `slots 3 default: no line starts "Build-loop slots:"`, `slots 3 default: line 1 is not exactly "Build-loop slots: N" with N from 1 to 9`.

**Evidence:** `scripts/build-loop.sh:818-821`, `$S/settings-review.out`, `$S/settings-mainfile.out`, `$S/settings-none.out`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 10b: "Step 10 dispatches only into slots no running loop fills, and step 8 writes new briefs only while the queue is shorter than the slots. The queue counts ... absent ... or working, plus those sent back to a loop; a blocked, stopped or ready-for-review one waits on you and is not counted."

**Location:** `docs/dev-cycle.md:39-42`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers SKILL.md steps 8 and 10's counting rules; does not establish runtime behavior.

Step 10 subtracts only this session's loops: "Fill free slots (`--settings`' `slots` less the loops this session runs)" (`skills/dev-cycle/SKILL.md:772-773`), so a loop another live session runs does not reduce the free slots; "no running loop fills" is broader than the skill. Step 8's uncounted list is wider than the doc's: "(a blocked, stopped, capped or ready one, or a stalled one held, waits on the user and is not counted)" (`skills/dev-cycle/SKILL.md:649-653`): capped and held-stalled briefs are also uncounted, and "ready" is any ready brief, not only ready-for-review. Precise version: "Step 10 fills the slots less the loops this session runs ... a blocked, stopped, capped, ready or held-stalled one is not counted."

**Evidence:** `skills/dev-cycle/SKILL.md:647-653`, `:767-774`
**Legibility-target:** for-author

---

## Claim 11: "Globs that self-merge never lands, even when a brief lists them: `*` and `?` match within one path part, a glob matches the path or any directory above it, and paths compare lower-cased. A malformed line turns self-merge off."

**Location:** `docs/dev-cycle.md:43-45`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers never_res' regex construction, srules' order (never before the allowlist), and the malformed → off coupling; does not establish behavior for globs outside globform (they are malformed by construction).

`never_res()`: `'*') re+='[^/]*' ;; '?') re+='[^/]' ;; ...; NEVER_RES+=("^$re(/|\$)")` on `lower "${g%/}"` (`scripts/build-loop.sh:1181-1193`, read whole); srules tests it on `$3`, the lower-cased path, before `PATHS` (`:1208-1210`). Executed: bats test "a Self-merge never: glob refuses a listed path under self-merge, by part and in any case; review ignores it (T45, U2c1)" passed; the read suite (20 tests, including T45's malformed-never cases) passed.

Commands: `timeout 600 bats -f "Self-merge never: glob refuses" test/scripts/build-loop-check.bats`, cwd the worktree, exit 0, 2026-10-15T05:20:03Z; `timeout 600 bats test/scripts/build-loop-read.bats`, exit 0, 2026-10-15T05:19:02Z.

**Evidence:** `scripts/build-loop.sh:1181-1217`, `test/scripts/build-loop-check.bats:2146-2156`, `$S/bats-never-glob.out`, `$S/bats-build-loop-read.out`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 12: "sessions in this repo read `workflows/`, `skills/`, `guides/` and `patterns/` from their own checkout, and the health check the orchestrator runs every iteration executes `scripts/`, `test/`, `hooks/` and `devcontainer-config/` from its worktree, while the release paste runs `devcontainer-config/install.sh` on the host before you see its diff"

**Location:** `docs/dev-cycle.md:48-51`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the repo instruction files' references, the health check's test run and what the bats files source, and step 1's run from WT; does not establish which files a given session actually opens at runtime.

`AGENTS.md:7` "check `workflows/` for applicable process docs", `AGENTS.md:24` "Skills ... in `skills/`", `AGENTS.md:63` "See `guides/doc-freshness.md`"; skills link `../../patterns/orchestrated-review.md` (`skills/ai-personas-critique/SKILL.md:24`). Step 1: "run the repo's health check from WT" (`skills/dev-cycle/SKILL.md:384-385`); health-check.sh check 5 runs the bats suites (`scripts/health-check.sh:52-53`), and those source `devcontainer-config/` scripts (`test/cc-isolated-functions.bats:19` `source "$CONFIG_SRC/cc-isolated.sh"`) and hooks (`test/hooks/*.bats`). install.sh draws its diff only after staging (paraphrased — no quote available because the stage→diff→prompt order spans `devcontainer-config/install.sh` assemble and its caller, ~800 lines; the paste runs install.sh, so its code executes before any diff by construction).

**Evidence:** `AGENTS.md:7,24,63`, `skills/dev-cycle/SKILL.md:380-395`, `scripts/health-check.sh:46-60`, `test/cc-isolated-functions.bats:19`, `devcontainer-config/install.sh:328-360`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 13: "`templates/` (a snippet other repos copy by hand) and `global-instructions/` (every session's global instructions after a release; the floor already refuses its `CLAUDE.md`)"

**Location:** `docs/dev-cycle.md:52-54`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the directories' contents, install.sh's payload entry and the floor's instruction-file rule; does not establish who copies the template.

`templates/` holds only `gitattributes-snippet.txt`; `global-instructions/` holds only `CLAUDE.md` (paraphrased — no quote available because the claim is about directory layout; `ls` output). `CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)` (`devcontainer-config/install.sh:135`). `INSTRUCTION_FILE='^(claude|agents?|gemini)(\.[...]+)?\.md$|^skill\.md$'` (`scripts/lib/dev-cycle-read.sh`, `:701`) feeds `isstart` → `truthrule` instr.

**Evidence:** `devcontainer-config/install.sh:135`, `scripts/lib/dev-cycle-read.sh:1916-1926`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 14: "So in this repo self-merge can land only files outside those directories and off the floor: docs, `README.md`, `runs/` and `archive/`."

**Location:** `docs/dev-cycle.md:54-55`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers today's top-level entries against the never line and the floor; does not establish anything about paths a future brief might create.

Today's top level is dot files (floor: dot), `AGENTS.md`/`GEMINI.md` (floor: instr), `README.md`, `archive`, `docs`, `runs` and the ten never-line directories (paraphrased — no quote available because the claim is about directory layout; `git ls-tree --name-only HEAD`). But the colon-list is narrower than the rule: a path at a new top-level name (e.g. `foo.md` or `newdir/x`) matches no never glob and no floor class (`floor()` falls through to `return 1` when no `truthrule`, `GATE_CODE`, `docs/thoughts|working|reviews`, import or below-start rule fires: `scripts/lib/dev-cycle-read.sh:2000-2016`), so a brief listing it in `Paths:` can self-merge it. "Only files outside those directories and off the floor" is exact; the enumeration should read "e.g. docs, `README.md`, `runs/`, `archive/` and any new top-level path". The same enumeration recurs in Q-103 [2] and Q-149 [1] (Claims 26, 27).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1997-2017`, `scripts/build-loop.sh:1202-1217`
**Legibility-target:** for-author

---

## Claim 15: "Some of those docs are read as authority too (`docs/evaluation-rubric.md`, which self-eval scores against, and `docs/spikes/`, whose seeds later work loads)"

**Location:** `docs/dev-cycle.md:56-58`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both paths exist, are referenced as authority and are off the floor (not truthrule, not @-imported); does not establish a complete list of other authority docs.

`skills/self-eval/SKILL.md:4` "Score one skill or workflow against docs/evaluation-rubric.md"; `workflows/spike.md` references `docs/spikes`. No instruction file @-imports a docs path (grep of `AGENTS.md GEMINI.md global-instructions skills/*/SKILL.md` for `@docs/` and `@...evaluation-rubric` returned nothing; paraphrased — no quote available because the claim covers absence of matches), and truthrule's record class is only `^docs/(decisions|human-author)/` (`scripts/lib/dev-cycle-read.sh:1924`).

**Evidence:** `skills/self-eval/SKILL.md:4`, `workflows/spike.md`, `scripts/lib/dev-cycle-read.sh:1916-1926`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 16: "**Review handoff.** No line. The pull-request route the design names is not built, and this repo has no PRs, so every review merge is one questions entry."

**Location:** `docs/dev-cycle.md:59-60`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers SKILL.md step 7 and read_settings (no such key); does not establish the repo's PR practice beyond the user's memory note.

"(D4's `Review handoff: pull request` route is not built: every review brief gets a merge entry.)" (`skills/dev-cycle/SKILL.md:607-608`); SETTINGS_AWK knows only policy, slots, never, roots, homes (`scripts/lib/dev-cycle-read.sh:624-629`).

**Evidence:** `skills/dev-cycle/SKILL.md:607-608`, `scripts/lib/dev-cycle-read.sh:618-635`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 17: Rubric status line: "0 red; iteration 2's Must Address rows fixed in 659a1c61 and the Q-156 commit after it; final confirming pass pending", and its rows vs the review reports

**Location:** `docs/reviews/code-review-rubric-2026-10-14-feat-build-loop-u5.md:5`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the status line against the iteration-2 table and each row's source against the i1/i2 security, api-consistency and fact-check reports' headings and verdicts; does not re-judge the findings themselves.

The rows match the reports: security i1 F1–F7 severities (`security-review-2026-10-14-u5-i1.md:184-194`), security i2 F1–F4 (`security-review-2026-10-14-u5-i2.md:154-161`), api i2 F1–F5 (`api-consistency-review-2026-10-14-u5-i2.md:36,52,68,82,96`), fact-check i1 claims 6, 8, 10, 12, 18, 24–28, 42 and i2 claims 5b, 6, 26, 28, 30b, 31, 34 with the verdicts the rubric names. But the status line says iteration 2's Must Address rows were fixed, while row A10 in the same section reads "| A10 | install.sh's archive honors replace refs ... | 🟡 (Medium) | security i2 F2 | Deferred: override row, roadmap Idea ..." (rubric, iteration-2 table). Precise version: "fixed, but A10 deferred (override row 831)".

**Evidence:** `docs/reviews/code-review-rubric-2026-10-14-feat-build-loop-u5.md:5`, iteration-2 table rows A8–A11; `docs/reviews/security-review-2026-10-14-u5-i2.md:154-161`; `docs/reviews/code-fact-check-report-2026-10-14-u5-i2.md:98-102,114-118,434-440,466-470,514-518,530-536,578-582`
**Legibility-target:** for-author

---

## Claim 18: Override-log rows 828–831 (the four rows this branch adds)

**Location:** `docs/reviews/override-log.md:828-831`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each row's finding, source, severity and verdict against the cited report, and row 831's install.sh line references; does not establish the Won't-Fix/Defer judgments' merit.

Row 828 = security i1 F7 "Informational" (`security-review-2026-10-14-u5-i1.md:194`); row 829 = fact-check i1 claim 42 "Mostly accurate" (`code-fact-check-report-2026-10-14-u5-i1.md:692-696`); row 830 = i2 claims 31 and 34, both "Mostly accurate" (`code-fact-check-report-2026-10-14-u5-i2.md:530-536, 578-582`), and "6 Must Address where the rubric has 7" matches rubric rows A1–A7; row 831 = security i2 F2 "Medium", and its references hold: `repo_git()` at `devcontainer-config/install.sh:180`, `git_state_gate()` at `:209` (its comment from `:208`), `archive --format=tar` at `:279`.

**Evidence:** `docs/reviews/override-log.md:828-831`, `devcontainer-config/install.sh:180-182,208-252,279`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 19: Roadmap Next item 5 "Revisit the light pass between full cycles (C5, Q-154)" and "Next holds at most five"

**Location:** `docs/roadmap.md:49-53`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Next list's count and item 5 against plan D12 and step 6's rule; does not establish ranking.

Next holds items 1–5 (`docs/roadmap.md`, Next section); step 6: "**Next**: at most five items, ranked" (`skills/dev-cycle/SKILL.md:542`). Plan: "You answered on 2026-10-04: a full cycle every iteration for now, and a move to a light pass of steps 7, 8 and 10 between full cycles once the costs are visible" (`docs/working/plan-build-loop-handoff.md:96`).

**Evidence:** `docs/roadmap.md:20-53`, `skills/dev-cycle/SKILL.md:542-543`, `docs/working/plan-build-loop-handoff.md:96`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 20: Roadmap Ideas: "step 4b names triggers, and its only named dimension is D2's constraints one"; "plan D13 built only `--main-log`'s check of what moved main"; "install.sh's archive honors replace refs ... `repo_git` does not switch replace refs off and `git_state_gate` does not check `refs/replace/`, so `.manifest` can record a commit whose content the image does not hold"

**Location:** `docs/roadmap.md:65-80`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers step 4b's text, plan D13's "minimal part of roadmap item (d)", install.sh's repo_git/git_state_gate and git's archive behavior under a replace ref; does not establish that the image build path uses only install.sh.

Step 4b: "Every deep audit covers one more dimension: whether the constraints and project guidance still match intent" (`skills/dev-cycle/SKILL.md:483-485`). Plan D13: "Any `other` stops dispatch ... This is the minimal part of roadmap item (d), moved into this unit." (`docs/working/plan-build-loop-handoff.md:102`). `repo_git() { git --no-optional-locks -C "$REPO_ROOT" -c core.hooksPath=/dev/null -c core.fsmonitor=false "$@"; }` (`devcontainer-config/install.sh:180-182`: no `core.useReplaceRefs`), and `git_state_gate` checks only config keys and `info/attributes` (`:209-252`, read whole). Executed: a blob replace ref changed `git archive HEAD` output to the planted content; `GIT_NO_REPLACE_OBJECTS=1` restored it.

Command: `timeout 60 bash $S/replace-archive.sh`, cwd `$S` (creates `$S/ra`), exit 0, 2026-10-15T05:21:14Z.

**Evidence:** `skills/dev-cycle/SKILL.md:469-487`, `docs/working/plan-build-loop-handoff.md:97-105`, `devcontainer-config/install.sh:180-252,279,337`, `$S/replace-archive.out`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 21: Plan as-built note (row 72 not 70; wider never line and its reasons; no `Review handoff:` line; entries; step 0.1; roadmap (f)/(e); D10 entry not filed)

**Location:** `docs/working/plan-build-loop-handoff.md:358`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each listed fact against the branch's files; does not establish that the note supersedes every stale plan sentence.

Row 72 exists (`docs/decisions/log.md:95`); D10 now reads "decision-log row 72 (written as row 70 before rows 70 and 71 were taken)" (`docs/working/plan-build-loop-handoff.md:91`); the seed's Status names row 72 (`docs/working/seed-build-loop-handoff.md:3`); entries Q-149..Q-156 and Q-154 archived (Claims 22, 27–30); roadmap item (f) is Next 5 and (e) in Ideas (Claim 19, `docs/roadmap.md:59`); no `Review handoff:` line (`docs/dev-cycle.md:59`); the cited override row 682 and security i1 F1, F3, F4 exist (`docs/reviews/override-log.md:682`, `security-review-2026-10-14-u5-i1.md:44,72,85`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:91,353,358`, `docs/decisions/log.md:95`, `docs/reviews/override-log.md:682`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 22: Q-154 filed answered and archived: "[1], a full cycle every iteration for now; move to a light pass of steps 7, 8 and 10 between full cycles once the costs are visible ... roadmap Next "Revisit the light pass" tracks it"

**Location:** `docs/working/questions-archive.md:2712-2726`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the answer against plan D12, the roadmap item, and the archive index/entry structure via `questions.sh check`; does not establish the in-session answer's date beyond the plan's record.

Plan D12: "You answered on 2026-10-04: a full cycle every iteration for now ..." (`docs/working/plan-build-loop-handoff.md:96`); roadmap item at `docs/roadmap.md:49`. `questions.sh check` printed "✓ questions: structure valid, indexes current".

Command: `timeout 60 bash scripts/questions.sh check`, cwd the worktree, exit 0, between 2026-10-15T05:21:14Z and 05:26:02Z.

**Evidence:** `docs/working/questions-archive.md:141,2712-2726`, `$S/questions-check.out`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 23: Q-103 "What the gate can and cannot do"

**Location:** `docs/working/questions.md:91`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the paragraph against the plan's "What the gate can and cannot do" and D6/D13's built mechanisms; does not establish anything about a hostile loop's capabilities beyond what the paragraph concedes.

The paragraph tracks the plan's section ("Loops run as your uid, with a shell, in worktrees that share `/workspace/.git`. No script can contain a loop that turns hostile ...", `docs/working/plan-build-loop-handoff.md:33-35`), updated for Q-140 [1]: the D6 block "always runs the root-owned image copy under D6_OPT by absolute path, never main's copy" (`skills/dev-cycle/SKILL.md`, D6 block header). D13's main check is `--main-log`'s gate/chore/answers/other classes (`scripts/build-loop.sh:139-180`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:31-35`, `skills/dev-cycle/SKILL.md:189-255`, `scripts/build-loop.sh:139-180`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 24: Q-103's residual families F11, F19, F21, F29, F35, F37, F58, F59 and R8 (incl. `answer`)

**Location:** `docs/working/questions.md:95-103`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each bullet against the plan's F-table row and the code it names; does not establish completeness of known issue A5's gap list.

F11: `checkout_gate` refuses "the checkout --check runs from ... has its HEAD at another commit" (`scripts/build-loop.sh:333-337` header; `checkout_gate` 1233-1298), and floor_why's imported says "(on the default branch, or only in the checkout)". F19: `--main-log` "catches an honest slip, not a commit made to look like one of the others" (`scripts/build-loop.sh:175-177`). F21: plan row "Briefs are written from main's commit ... and read from main's commit" (`plan:136`). F29: `land()` refuses unless W is on main at `MAIN_SHA`, clean, with no `MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD BISECT_START rebase-merge rebase-apply sequencer` (`scripts/build-loop.sh:1525-1538`); the comment names "after a racing branch switch in W" (`:1478`). F35: the prompt says "Never start build loops, background agents or schedules; never send your branch to a remote, merge, open a pull request or publish." (`scripts/build-loop.sh:1689`). F37: `git update-ref "refs/heads/$br" "$MAIN_SHA" ""` and `worktree add -q --lock` (`:1655-1658`); step 9.1 runs `questions.sh check` only "when this iteration filed or edited entries", and a merge-in returns to step 3 (`skills/dev-cycle/SKILL.md:727-730, 763`); health-check check 14 is the questions gate (`scripts/health-check.sh:60`). F58: step 0.1's listing (Claim 36). F59: step 4's drift check "A finding is a step 4b trigger" (`skills/dev-cycle/SKILL.md:462-467`). R8: plan step 13 lists the GATE_TMP files (`plan:357`), and row 684 adds `answer`: `r="$(< "$GATE_TMP/answer")"` (`scripts/build-loop.sh:1446`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:126-177,357`, `scripts/build-loop.sh:175-177,1233-1298,1440-1462,1478,1525-1538,1626-1665,1689`, `skills/dev-cycle/SKILL.md:452-467,730-765`, `docs/reviews/override-log.md:509,684`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 25: Q-103 "Also routed here during the build" items vs the override-log rows cited by line

**Location:** `docs/working/questions.md:104-117`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each cited line number (548, 668, 682, 749, 750, 784, 786, 787, 797, 801, 802) and the unit-cited items (U2b3a: plan `:293`; U3a1: rows 638, 646; U3a2: row 671; U4c: the D6 header); does not establish that rows which only call a gap "Q-103 family" without routing it (694, 696, 705, 782, 819, 820) belong in the list — they are dispositioned Defer/Won't-Fix with their own triggers.

Each cited line holds the described row: 548 "a loop that points origin/HEAD at its own branch", 668 "a hand-edited rebase todo holding an `update-ref refs/heads/main` line", 682 "`scripts/health-check.sh` ... matches neither GATE_CODE nor the floor", 749 "a planted pre-commit hook", 750 "a FIFO swapped in", 784 "a rewrite of main to a history that never held a record", 786 "The dispatch count is written after the dispatch", 787 "`--prompt --steal` can take another live session's loop", 797 "Merge entries flag floor paths by class", 801 "`--start`/`--prompt` read main live after step 10's `--main-log MAIN` re-read", 802 "`--cycle-diff`/`--land-cycle` accept any `--answered` ID" (`docs/reviews/override-log.md` at those lines). Row 775 (questions.sh via the `~/.claude/scripts` symlink) is not listed; its trigger offered "U4c, which could run questions.sh by its /opt path", and the D6 block now runs questions.sh from `/opt` (SKILL.md D6 header: "SCRIPT is `build-loop.sh`, `dev-cycle.sh` or `questions.sh`").

**Evidence:** `docs/reviews/override-log.md:548,638,646,668,671,682,749,750,775,784,786,787,797,801,802`, `docs/working/plan-build-loop-handoff.md:293`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 26: Q-103 options [1] and [2]

**Location:** `docs/working/questions.md:121-122`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers [1]'s route and [2]'s conditions and fallback against step 7; does not establish the cost columns.

[1] matches step 7's review route (Claim 7). [2] "lands through the gate with no review when every changed path is in its `Paths:` line and off the floor and the never line; anything else falls to [1]'s entry": the brief's own files land without being listed (`[[ "$2" != "$3" ]] || ! ownfile "$2" "$1" "$4" || return 0`, `scripts/build-loop.sh:1211`), and not everything else becomes an entry: a conflict is filed as `stopped` and an environment refusal is retried (`skills/dev-cycle/SKILL.md:589-594`). Its "only docs, `README.md`, `runs/` and `archive/` off the floor can self-merge" carries Claim 14's gap (new top-level paths). Precise version: "... in its `Paths:` line or one of its own files ...; a path refusal falls to [1]'s entry".

**Evidence:** `scripts/build-loop.sh:1202-1217`, `skills/dev-cycle/SKILL.md:578-608`
**Legibility-target:** for-author

---

## Claim 27: Q-149 (premise, two authority docs, options, "If the answer differs: a one-line edit to `docs/dev-cycle.md` ... and its test line")

**Location:** `docs/working/questions.md:361-379`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the premise (Claims 12, 15), [1]'s never list (executed in Claim 9), [3]'s `none` form, the empty-line refusal and the redo cost; does not establish the cost columns.

The premise, the two docs and option [1]'s list match the code and the file (`docs/dev-cycle.md:11`; `SKILL.md` floor refusal via `^skill\.md$`). An empty `Self-merge never:` fails `list_entries`' form check (`if [[ "$1" != "$2: "* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]`, `scripts/build-loop.sh:757`), so "`none`, not an empty line, keeps self-merge possible" holds. But [2] or [3] would also leave the Never-line prose stale ("Here it holds every code and process directory ... So in this repo self-merge can land only ...", `docs/dev-cycle.md:45-58`), so the redo is the settings line, its prose bullet and the test line, not "a one-line edit". [1]'s "self-merge lands only docs, `README.md`, `runs/` and `archive/`" carries Claim 14's gap.

**Evidence:** `docs/dev-cycle.md:11,43-58`, `scripts/build-loop.sh:752-768`, `test/scripts/build-loop-read.bats:79-81`
**Legibility-target:** for-author

---

## Claim 28a: Q-150, Q-152, Q-153 (built defaults and their descriptions)

**Location:** `docs/working/questions.md:381-395`, `:411-445`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers Q-150 [1] vs `--marker` and D11, Q-152 [1] vs the wait rule, Q-153's quote of the global rule and answer 2; does not establish the cost columns.

Q-150: `--marker` prefixes every body line `> ` (`scripts/build-loop.sh:93-101`); F41 is "(E2, E3, reproduced)" (`plan:159`). Q-152 [1] matches "with none, every 1200-1800 s, and only when the default branch moved past this iteration's last land ..., a retry's wait ran out, or the user wrote, run a full iteration" (`skills/dev-cycle/SKILL.md:810-814`). Q-153: the global instructions list "deleting branches" under "Still require user approval (regardless of mode)"; answer 2 is quoted from `docs/working/handoff-build-loop-handoff.md:31`.

**Evidence:** `scripts/build-loop.sh:89-110`, `docs/working/plan-build-loop-handoff.md:92,159`, `skills/dev-cycle/SKILL.md:808-815`, `docs/working/handoff-build-loop-handoff.md:31,92-95`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 28b: Q-151 "[1] Frees the slot (built) ... a blocked item re-enters the queue on its existing branch once answered, ahead of new briefs" / "If the answer differs: [2] is a change to the skill's step 10 slot count"

**Location:** `docs/working/questions.md:396-410`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers [1] against steps 8 and 10 and the redo line; does not establish the cost columns.

[1] matches: step 10 fills "briefs step 7 sends back first, then absent ones" (`skills/dev-cycle/SKILL.md:773-774`), and step 8 does not count a blocked brief (`:649-653`). The redo line names only step 10, but the queue that caps new briefs is step 8's ("while the queue is shorter than `--settings`' `slots` line ... (a blocked, stopped, capped or ready one ... is not counted)", `:648-653`), so [2] changes step 8's count as well.

**Evidence:** `skills/dev-cycle/SKILL.md:647-653`, `:767-774`
**Legibility-target:** for-author

---

## Claim 29: Q-155 constraints-doc-missing (slug, interim "`--settings` prints `constraints missing`, and step 10 files nothing more while this entry is open", constraint format)

**Location:** `docs/working/questions.md:446-462`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `constraints missing` on this repo's committed state, step 10's slug and dedupe rule, and CONSTRAINTS_AWK's format; does not establish the cost columns.

Executed `--settings` printed `constraints missing: no docs/constraints.md on the default branch` (Claim 3's run). Step 10: "else one `you: judgment` entry, slug `constraints-doc-missing`, ... unless an open one with that slug exists" (`skills/dev-cycle/SKILL.md:770-772`). CONSTRAINTS_AWK: `/^(- )?[HS][123456789][0123456789]*: [^ \t]/` and `/^[ \t]*(- )?success: [^ \t]/` (`scripts/build-loop.sh:722-745`). The "Read:" pointer `SKILL.md "Constraints"` exists (`skills/dev-cycle/SKILL.md:126`).

**Evidence:** `skills/dev-cycle/SKILL.md:126,770-772`, `scripts/build-loop.sh:720-745,823-837`, `$S/settings-review.out`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 30: Q-156 C, M, gate-code list, commit list and path list

**Location:** `docs/working/questions.md:470-489`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers C against `/opt/claude-workflows/.manifest` and main's first-parent history, M as the last branch commit touching the released set, the gate-code diff, the 11 first-parent commits (none a self-merge subject), the 28 non-docs paths (one deletion), the docs count, and "the branch's later commits change only `docs/`"; does not establish main's state after this report (the paste re-checks it).

`.manifest`: `commit=8d0e660e2e5a9769200500ac3dcfb4b113a32589`, `assembled_from=/home/magfrump/claude-workflows`; `git rev-list --first-parent main | grep -c 8d0e660e2e5a` → 1. `git log --format='%h %s' -1 HEAD -- .gitattributes devcontainer-config global-instructions guides hooks patterns scripts skills workflows` → `659a1c61`, full id `659a1c61f5b843ef574b90eb99a728ab84cf98d5`; `git diff --name-only 659a1c61 HEAD | grep -v '^docs/'` → empty; merge base = main = `b279a2ba`, so the merge's tree equals HEAD's. `git log --first-parent --format='%h %s' 8d0e660e..main` lists the same 11 commits (oldest first in the entry). `git diff --name-only 8d0e660e 659a1c61` outside `docs/` gives exactly the 28 listed paths, `D test/lib/d6-snippet.bash`; 505 under `docs/`, 494 of them `docs/reviews/`. Gate-code pathspec diff → the three listed files.

Commands: the git commands above, cwd the worktree, each exit 0, 2026-10-15 ~05:15Z (outputs captured in this session's tool log; summary in `$S/paste-checks.out` header for M).

**Evidence:** `/opt/claude-workflows/.manifest`, `skills/dev-cycle/SKILL.md:286-310`, `devcontainer-config/install.sh:135`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 31: Q-156 paste: "with only `rev-parse` and `for-each-ref` ... and replace refs ignored, it checks that HEAD is main, that no replace ref or graft file exists ..., and that the root `.gitattributes` and every directory the release installs from are the same tree at HEAD as at M; so it refuses when main has moved a released path past what this entry lists"

**Location:** `docs/working/questions.md:491-495`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the paste's checks (install.sh replaced by an echo) in a throwaway clone at the branch tip as main, under nine states; "HEAD is main" is verified as HEAD's commit equal to main's (a detached HEAD at main's commit passes, and install.sh stages HEAD's commit, so the guard's purpose holds); the directory list is CLAUDE_HOME_SRC's directories plus install.sh's own `devcontainer-config`; does not establish install.sh's behavior after the checks.

The paste's git calls are `rev-parse` (HEAD, refs/heads/main, `--git-common-dir`, `HEAD:$p`, `$M:$p`) and `for-each-ref refs/replace/`, inside a subshell exporting `GIT_NO_REPLACE_OBJECTS=1` (`docs/working/questions.md:494`). Results: main = branch tip → WOULD-RUN-INSTALL; detached at main's commit → passes; HEAD on another commit → "release refused: HEAD is not main"; replace ref → "replace refs present"; `info/grafts` → "info/grafts present"; a `scripts/` change after M → "scripts differs from M"; a root `.gitattributes` change → ".gitattributes differs from M"; a docs-only or test-only change → passes (neither is installed).

Command: `timeout 300 bash $S/run-paste.sh` (runs `$S/paste-checks.sh`, the paste's subshell verbatim with `./devcontainer-config/install.sh` replaced by `echo WOULD-RUN-INSTALL`), cwd `$S` (clone at `$S/clone`), exit 0, 2026-10-15T05:15:51Z–05:15:54Z.

**Evidence:** `docs/working/questions.md:491-495`, `devcontainer-config/install.sh:135`, `$S/paste-checks.sh`, `$S/run-paste.sh`, `$S/paste-checks.out`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 32: Q-156: "no replace ref or graft file exists (`git archive` in install.sh would honor either)"

**Location:** `docs/working/questions.md:491`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git archive's output under a blob replace ref and under a graft; does not establish behavior with `export-subst` attributes, which this repo does not use.

A replace ref changes the archived content (planted blob archived); a graft is read by git (its deprecation hint printed) but changes only parent links, so `git archive HEAD` produced the same files and tree. Archived content could depend on a graft only through `export-subst` placeholders such as parent hashes, and `.gitattributes` holds only `* text=auto eol=lf` and `docs/working/** linguist-generated`. Refusing grafts is a sound conservative check, but "would honor" overstates a graft's effect on what install.sh stages. Precise version: "a replace ref would change what `git archive` stages; a graft cannot today, and is refused as planted state".

Command: `timeout 60 bash $S/replace-archive.sh`, cwd `$S`, exit 0, 2026-10-15T05:21:14Z.

**Evidence:** `.gitattributes:1-2`, `devcontainer-config/install.sh:279`, `$S/replace-archive.sh`, `$S/replace-archive.out`
**Legibility-target:** for-author

---

## Claim 33: Q-156: "The image's dev-cycle skill lacks the D6 block (U4c), so the orchestrator loop cannot run as written until this release."

**Location:** `docs/working/questions.md:470`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the image copy's "The D6 block" section text; does not establish whether the image's older skill could run any part of the loop.

The image copy's section reads "Pending: Q-140 (the snippet's trust root). Its canonical copy is `test/lib/d6-snippet.bash` in claude-workflows; once Q-140 is answered, that file goes here byte for byte" (`/opt/claude-workflows/skills/dev-cycle/SKILL.md:199-207`) with no snippet, while the branch's section holds the full `d6()` block (`skills/dev-cycle/SKILL.md:189-255`).

**Evidence:** `/opt/claude-workflows/skills/dev-cycle/SKILL.md:199-207`, `skills/dev-cycle/SKILL.md:189-255`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 34: Research corrections: "`/opt/claude-workflows/scripts/build-loop.sh` is in the image now (its `.manifest` commit was 8d0e660e on 2026-10-14), and since Q-140 [1] the D6 block always runs that root-owned image copy, in this repo too"; "the cycle does spawn loops itself, as background subagents with no isolation, in a worktree `build-loop.sh --start` creates (plan D1)"

**Location:** `docs/working/research-build-loop-handoff.md:23`, `:59`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the image file's presence, C's date, the D6 block's `D6_OPT` and step 10's dispatch; does not establish the image's root ownership beyond what the D6 block checks at run time.

`ls /opt/claude-workflows/scripts/build-loop.sh` exists; `git log -1 8d0e660e` → `2026-10-14`. D6: `D6_OPT=/opt/claude-workflows` ... `bash "$D6_OPT/scripts/$s" "$@"` (`skills/dev-cycle/SKILL.md` D6 block). Step 10: "start one background subagent (Agent tool, no isolation)" after `--start BRIEF` (`skills/dev-cycle/SKILL.md:776-779`).

**Evidence:** `skills/dev-cycle/SKILL.md:189-255,776-779`, `scripts/build-loop.sh:1626-1665`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 35: Seed Status: "superseded by decision log row 72 (... merged with `feat/build-loop-u5`; plan `docs/working/plan-build-loop-handoff.md`)"

**Location:** `docs/working/seed-build-loop-handoff.md:3-4`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers row 72's "Supersedes the seed" and the plan path; does not establish the merge, which has not happened yet.

Row 72 ends "Built as stacked units U0a–U5 under the row-62 cap. Supersedes the seed." (`docs/decisions/log.md:95`).

**Evidence:** `docs/decisions/log.md:95`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 36: Step 0.1: the `image-lag` entry "is also the release entry ... every first-parent commit after C as a list item (...; flag a subject ending `(build-loop self-merge)`, which no one reviewed: a hand commit with that subject reads the same, so the flag is a pointer, not proof), every path changed from C to M outside `docs/` on one line, each in backticks, comma-separated (the image carries none of `docs/`: give its count)"

**Location:** `skills/dev-cycle/SKILL.md:298-306`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the self-merge subject against gate_msg and the image payload against CLAUDE_HOME_SRC; does not establish the orchestrator's runtime output.

`gate_msg`: `printf "Merge branch '%s' (build-loop %s)\n\nBuild-loop-gate: %s\n"` with `what=self-merge` (`scripts/build-loop.sh:1463-1466`, `land()` 1484-1489), so a self-merge subject ends `(build-loop self-merge)`; nothing stops a hand commit from using it. CLAUDE_HOME_SRC holds no `docs/` entry (`devcontainer-config/install.sh:135`).

**Evidence:** `scripts/build-loop.sh:1463-1489`, `devcontainer-config/install.sh:135`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 37: Step 0.1's withheld rule and its reason: "each subject or path holding `<`, `>`, a backtick, a CR, another control or bidi character, or bytes that are not UTF-8 written as `(withheld: see SHA)` (questions.sh finds its `<!-- index:` markers anywhere in a line, and `--check-answer` refuses an unclosed `<!--`)"

**Location:** `skills/dev-cycle/SKILL.md:304-308`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two stated reasons against questions.sh and FENCE_AWK; does not establish a reason for each other withheld character (backtick, bidi, non-UTF-8), which the parenthesis does not claim to give.

questions.sh: `have_ids="$(sed -n "/$INDEX_START/,/$INDEX_END/p" "$file" ...` and `grep -aqF "$INDEX_START"` with `INDEX_START='<!-- index:start -->'` (`scripts/questions.sh:140,294,312`): unanchored, so a marker anywhere in a line matches. FENCE_AWK: `function opencomment(l, n, p) { # the last <!-- on the line has no --> after it` and the refusal "opens an HTML comment it does not close" (`scripts/lib/dev-cycle-read.sh:257-259,277-280`), which check_answer applies to the whole file.

**Evidence:** `scripts/questions.sh:140-141,294,312`, `scripts/lib/dev-cycle-read.sh:250-300`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 38: Step 10: "one `you: judgment` entry, slug `constraints-doc-missing`, asking for `docs/constraints.md`, unless an open one with that slug exists: D2"

**Location:** `skills/dev-cycle/SKILL.md:770-772`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the slug's consistency with Q-155's heading; does not establish runtime dedupe.

Q-155's heading is `### Q-155 · constraints-doc-missing` (`docs/working/questions.md:446`).

**Evidence:** `skills/dev-cycle/SKILL.md:770-772`, `docs/working/questions.md:446`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 39: Test comment and assertions: "The interim never line (every directory that takes effect here without a release: plan D5, F57, Q-149) and the slots line (U5)"

**Location:** `test/scripts/build-loop-read.bats:79-81`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the two assertions pass against the repo's own file; does not establish the test's coverage of other settings shapes.

Executed: `timeout 600 bats test/scripts/build-loop-read.bats`, cwd the worktree, exit 0, 2026-10-15T05:19:02Z; all 20 tests ok, including test 4 "--settings on this repo's own docs/dev-cycle.md" that holds the new assertions.

**Evidence:** `test/scripts/build-loop-read.bats:71-82`, `$S/bats-build-loop-read.out`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 40: Onboarding step 13's policy text, never-line requirement, both-policy stop, and constraints doc

**Location:** `workflows/codebase-onboarding.md:453-460`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers "self-merge ... which self-merge requires: `Self-merge never: none` for an empty list", "a branch that changes `docs/constraints.md` or the cycle's own files ends stopped under either policy", "the dev cycle dispatches no build loop in a repo without one that holds a hard constraint", and the roadmap item's name; does not establish the template reference that predates this branch.

Never requirement: `read_settings` (Claim 9). Both-policy stop: Claim 8. Dispatch gate and format: Claims 1 and 29. Roadmap item "A process for writing a repo's constraints doc" exists (`docs/roadmap.md:59`).

**Evidence:** `scripts/build-loop.sh:720-745,813-815,1141-1168,1633`, `docs/roadmap.md:59`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 41: Commit b5eaedf6 body: "Iteration 2's reports, rubric section and three override rows."

**Location:** commit `b5eaedf6`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count of override-log rows the commit adds; does not establish the other parts of the body (checked in Claims 30–32 and 17).

`git show --format= b5eaedf6 -- docs/reviews/override-log.md` adds two lines and removes none: "+| 2026-10-14 | `feat/build-loop-u5` | Commit 771a5d02's body: ..." and "+| 2026-10-14 | `feat/build-loop-u5` | install.sh's `repo_git` honors `refs/replace/` ..." (rows 830, 831; stat `docs/reviews/override-log.md | 2 +`). Row 830 covers two commit bodies (fact-check i2 claims 31 and 34) in one row, which is likely why three were counted. The body is immutable; the precedent (rows 829, 830) is an override row.

**Evidence:** `docs/reviews/override-log.md:830-831`, `git show --stat b5eaedf6`
**Legibility-target:** for-author

---

## Claim 42: Commit bodies 92fa6e52, 2846f9fa, 42414307, 771a5d02, 57e26f6b, 87ca421e, c63da94d, 659a1c61

**Location:** commits `92fa6e52`..`659a1c61` (main..HEAD less b5eaedf6)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each body against its own diff at that commit; the known errors in 2846f9fa, 771a5d02 and c63da94d are those override rows 829–830 already record; does not re-litigate them.

Checked true at their commits: 92fa6e52 (row 72, slots 3, interim `workflows/`, "rows 70 and 71 were taken"); 42414307 (brief Status done, as-built note); 57e26f6b ("Q-156's paste pins M (771a5d02, the last commit touching released paths)": `git log 42414307..57e26f6b -- <released set>` → only 771a5d02; rows 548 ... 802 match Claim 25); 87ca421e ("named eight of its ten directories"; Q-149 and Q-103 [2] now say the same); 659a1c61 (onboarding names `docs/constraints.md`; step 0.1 withholds backticks, bidi, non-UTF-8; Q-149 names the two docs). c63da94d's "two override-log rows" is right (rows 828, 829: `git show c63da94d -- docs/reviews/override-log.md`). The residual inaccuracies are 2846f9fa's incomplete residual list (row 829), and 771a5d02's group order and c63da94d's "6 Must Address" (row 830), each Won't-Fix as immutable history.

**Evidence:** `git log --format='%h %s%n%b' main..HEAD`, `docs/reviews/override-log.md:829-830`
**Legibility-target:** for-orchestrator-synthesis

---

## Claims Requiring Attention

### Incorrect
- **Claim 41** (commit `b5eaedf6`): the body says "three override rows"; the commit adds two (rows 830, 831). Immutable, so an override row (as for rows 829–830) is the fix.

### Stale
- None.

### Mostly Accurate
- **Claim 4** (`docs/dev-cycle.md:16-17`): copies are counted on letters alone, case folded ("**Build-loop policy:** x" counts too), and the never/reader lines need a blank next line; "starts with its key" understates both (fail-closed).
- **Claim 10b** (`docs/dev-cycle.md:39-42`): step 10 subtracts only this session's loops; step 8 also leaves capped, held-stalled and any ready brief uncounted.
- **Claim 14** (`docs/dev-cycle.md:54-55`): "only ... docs, `README.md`, `runs/` and `archive/`" omits paths at a new top-level name, which neither the never line nor the floor refuses; the same list recurs in Q-103 [2] and Q-149 [1].
- **Claim 17** (rubric `:5`): status says iteration 2's Must Address rows were fixed; A10 is deferred.
- **Claim 26** (`questions.md:122`): Q-103 [2] omits own files from what lands unlisted, and "anything else falls to [1]'s entry" omits conflicts (stopped) and environment refusals (retried).
- **Claim 27** (`questions.md:379`): Q-149's "one-line edit" would leave the Never-line prose (`docs/dev-cycle.md:45-58`) stale.
- **Claim 28b** (`questions.md:410`): Q-151's redo names step 10 only; step 8's queue count changes too.
- **Claim 32** (`questions.md:491`): a graft does not change what `git archive` stages (parents only; no export-subst here); only replace refs do.
- **Claim 42** (commits): the three known body errors stand, already recorded in override rows 829–830.

### Unverifiable
- None.

---

## Goal-Alignment Note

The user goal is to land U5 with docs that match the built code. Against that goal the branch is in good shape: every settings line, policy route, residual list, release listing and paste check I could execute behaved as the docs say (`--settings` on the branch file, its flipped copy, and main's file flipped; the never-glob and read bats suites; Q-156's paste in nine clone states; git's replace and graft behavior). No finding here affects what the gate does or would let anything land. All nine Mostly-accurate items are wording that is narrower or broader than the code. The one with a practical edge is Claim 14 (repeated in Claims 26 and 27): readers of `docs/dev-cycle.md`, Q-103 [2] and Q-149 [1] could conclude that self-merge can never land a new top-level file or directory, when it can if a brief lists one. That has no effect while the policy is `review` (Q-103), but it bears on the very choice Q-103 and Q-149 put to the user. The one Incorrect (Claim 41) is a row count in an immutable commit body and needs only an override row. Nothing found blocks the merge if the pass is meant to confirm that behavior matches the docs; the Claim 14 wording is the one fix worth making before the user answers Q-103/Q-149.
