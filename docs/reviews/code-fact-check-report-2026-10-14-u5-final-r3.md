Commit: b5eaedf6

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u5`, branch `feat/build-loop-u5`)
**Scope:** full branch `git diff main...HEAD` (main b279a2ba, HEAD b5eaedf6; 9 commits, 20 files), checked against `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `scripts/questions.sh`, `scripts/health-check.sh`, `devcontainer-config/install.sh`, `skills/dev-cycle/SKILL.md`, `docs/reviews/override-log.md`, `docs/working/plan-build-loop-handoff.md` and the U5 review reports
**Checked:** 2026-10-14
**Replication:** k=3, replicate r3 (final confirming pass, decision log 63)
**Total claims checked:** 50
**Summary:** 42 verified, 7 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Execution logs are in the scratch dir and are not committed: `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r3/logs/`. They are `settings.txt` (driver `../settings.sh`, 11 throwaway repos `../repo-*`), `bats.txt`, `qcheck.txt`, `q156-paste.txt` (driver `../cases.sh`, paste copy `../paste.sh` with install.sh replaced by an echo, throwaway clone `../clone`), `q156-lists.txt` (`../lists.sh`), `glob.txt` (`../glob.sh`) and `grafts.txt` (`../grafts.sh`). Every git run used `GIT_CONFIG_GLOBAL=/dev/null` under `timeout`. All of them exited, and no process was left running. Tracked files were not edited. The worktree's only new file is this report.

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 5 patterns). Claim 46 (a count in a commit body) resembles the logged "count claimed in a commit message" patterns (59ca38f, 37c5ea9). It is a Mostly accurate miscount, not a fabricated symbol, and this pass edits no tracked file, so the log is not updated.

---

## Claim 1: Decision-log row 72: "D1 ... D14", "What the gate cannot do ... the residual families are listed in Q-103, whose policy stays `review` until answered"

**Location:** `docs/decisions/log.md:95`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each D-summary against the plan's D1–D14 and the built mechanisms named (dispatch cap, markers, merge-entry slugs, floor classes, image-copy gate, merge-tree/commit-tree/CAS, slots default, `--marker`, `--land-cycle`, the health-check flock). Does not establish every sub-rule inside each plan decision.

Plan D1 reads "`Dispatched:` caps a brief at 4 dispatches" and "A live loop with no new commit across 4 consecutive fallback wakeups ... is stopped" (`docs/working/plan-build-loop-handoff.md:39-42`). D5's floor classes match the row: "instruction files ... and their `@`-imports", "any `.`-prefixed component", "the gate's own code", "files the cycle and later loops read as truth", "symlinks and gitlinks" (`:66-73`). D7's CAS is `git update-ref --no-deref -m "$msg" "refs/heads/$MAIN" "$NEW" "$MAIN_SHA"` (`scripts/build-loop.sh:1560`), after `gate_git commit-tree --no-gpg-sign -p "$MAIN_SHA" -p "${VERDICT[tip]}"` (`:1554`). D14 is `flock -n -E 75 -o "$lk" bash "$REPO_ROOT/scripts/health-check.sh"` (`scripts/health-check.sh:1155`). The slots default is `SLOTS_LINE='slots 3 default: ...'` (`scripts/build-loop.sh:822`). D13's "minimal part of roadmap item (d)" matches the plan (`docs/working/plan-build-loop-handoff.md:103`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:31-106`, `scripts/build-loop.sh:785-826`, `scripts/build-loop.sh:1484-1565`, `scripts/health-check.sh:1134-1156`

---

## Claim 2: The three settings lines: `Build-loop policy: review (interim; Q-103)`, `Build-loop slots: 3`, `Self-merge never: workflows/ ... global-instructions/`

**Location:** `docs/dev-cycle.md:7-11`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers what `--settings` prints for this branch's file committed on a throwaway repo's `main`, as written and with the policy line flipped to `Build-loop policy: self-merge`. Does not establish what the image copy prints, since the image runs the same script at C, which predates U5's doc but not its parser.

Run: `bash /home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r3/settings.sh`, cwd one fresh repo per case under that dir, at 2026-10-15T05:13:52Z, every case exit 0. As written it printed `policy review unset: line 7 is not exactly "Build-loop policy: self-merge" or "Build-loop policy: review"`, `slots 3 set: line 9 ...` and `never workflows/ ... global-instructions/ set: line 11 of docs/dev-cycle.md on the default branch`. Flipped, it printed `policy self-merge set: line 7 of docs/dev-cycle.md on the default branch`. No prose line was counted as a second copy. The `main` file (before U5), flipped to self-merge, prints `policy review unset: line 7 reads self-merge, but there is no valid Self-merge never: line`.

**Evidence:** `scripts/build-loop.sh:785-826`, `scripts/lib/dev-cycle-read.sh:614-633`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r3/logs/settings.txt`

---

## Claim 3: "The scripts read the three lines above, and the two reader lines below, from the default branch's commit ...; A line counts only when it is the one line in the file, outside code blocks, that starts with its key; a trailing CR is ignored."

**Location:** `docs/dev-cycle.md:13-17`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `read_settings` and `reader_settings` reading main's blob, the copy count, fence skipping and the CR rule (executed: a CR case and a bold second copy). Does not establish the doc's "starts with its key" as the exact rule: the count folds case and drops every non-letter (`**Build-loop policy:** review` counts as a copy), which the doc delegates to the script header.

`main_file` reads `git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk "$FENCE_AWK$2"` (`scripts/lib/dev-cycle-read.sh:606`). SETTINGS_AWK runs `{ sub(/\r$/, "") }`, `fence($0) { next }`, and `s = tolower($0); gsub(/[^a-z]/, "", s)` with `index(s, "buildlooppolicy") == 1` (`:618-628`). Executed cases (log above): a policy line ending in CR printed `policy self-merge set`, and a second `**Build-loop policy:** review` line printed `policy review unset: more than one line starts "Build-loop policy:" (lines 7 and 9)`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:597-633`, `scripts/lib/dev-cycle-read.sh:655-700`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r3/logs/settings.txt`

---

## Claim 4: "Under `self-merge` ... only when every changed path is listed in the brief's `Paths:` line or is one of the brief's own files (named by its stem), and none is on the gate's fixed floor (...) or matches the never line."

**Location:** `docs/dev-cycle.md:19-25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `srules`' order (floor, never globs, own file, `Paths:`) and `check_line` calling it for self-merge briefs after the N rules. Does not establish the floor's internals (import walk, checkout gate), which are not changed on this branch.

`srules` runs `floor "$2" "$1" "$4" "$3"`, then the `NEVER_RES` loop, then `[[ "$2" != "$3" ]] || ! ownfile "$2" "$1" "$4" || return 0`, then the `PATHS` loop, ending `DENY="neither listed in the brief's Paths: line nor one of its own files"` (`scripts/build-loop.sh:1203-1216`). `check_line` calls it only when no N rule denied and `sm` is set: `[[ -n "$DENY" || -z "$sm" || "$p" == "$a" ]] || srules ...` (`:1412`).

**Evidence:** `scripts/build-loop.sh:1193-1216`, `scripts/build-loop.sh:1349-1424`, `scripts/lib/dev-cycle-read.sh:1945-1955`

---

## Claim 5: "A self-merge refused for a path falls through to review; a conflict is filed as stopped, and an environment refusal is retried."

**Location:** `docs/dev-cycle.md:25-26`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers SKILL.md step 7's routing of `--merge`'s refusal kinds. Does not establish that the orchestrator follows the skill text (prose, not script).

Step 7 reads: "A refusal of the paths ("K of N changed paths refused", `deny` lines following) falls through to review: a merge entry as below ... A conflict is `stopped`. Any other refusal (no identity, MAIN_WT's state, a moved main, a failed read) is the environment's ... tried again next iteration" (`skills/dev-cycle/SKILL.md:584-592`). The script prints the refusal shapes `refuse $a: $br conflicts with the default branch` and `refuse $a: $nd of ${#ps[@]} changed paths refused` (`scripts/build-loop.sh:1366`, `:1415`).

**Evidence:** `skills/dev-cycle/SKILL.md:573-592`, `scripts/build-loop.sh:1366-1424`

---

## Claim 6: "Under `review`, the orchestrator files one merge entry (`merge-STEM-SHA12`, or `merge-gate-STEM-SHA12` when the change touches the gate's own code) holding `--check`'s output, and merges only on your `[1] merge`."

**Location:** `docs/dev-cycle.md:26-29`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the slug shapes, the body, and `approval`'s exact-heading check with option 1. Does not establish the orchestrator's filing behavior beyond the skill text.

`approval` builds `s="merge-"` or `s="merge-gate-"` when `VERDICT[gate]` is set, `s+="${VERDICT[stem]}-${VERDICT[tip]:0:12}"`, accepts only `"keep $1"`, and requires `[[ "$ANSWER_HEADING" == "$1 · $s" ]]` (`scripts/build-loop.sh:1438-1455`). Step 7: "On `ok`, one merge entry, heading `### Q-NNN · merge-STEM-SHA12` ... Its body: the full TIP ..., `--check`'s lines as printed" (`skills/dev-cycle/SKILL.md:593-603`).

**Evidence:** `scripts/build-loop.sh:1431-1456`, `skills/dev-cycle/SKILL.md:593-606`

---

## Claim 7: "Under both policies the N rules refuse a change to `docs/constraints.md`, this file, the cycle's own files (the questions files, the roadmap, the idea log, the cycle records) or any brief beyond the brief's own Status line: under review such a branch is filed as stopped; under self-merge it first comes to you as a merge entry, whose `[1] merge` the gate then refuses, so it ends as stopped."

**Location:** `docs/dev-cycle.md:29-33`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `nrules`' cycle/settings/user words, the own-brief Status rule, and step 7's routes for both policies. This is iteration 2's claim 5b, now fixed. Does not establish the other N rules (path form, modes), which the sentence does not list.

`writable()` is `[[ "$1" =~ ^docs/roadmap\.md$|^docs/working/(questions|questions-archive|idea-log)\.md$ ]] || isrecord "$1" || anybrief "$1"` (`scripts/lib/dev-cycle-read.sh:247-249`). `nrules` maps `cycle|settings` and `user` to DENY, and the own brief to "only its first Status: line outside a fence may change, from open to done" (`scripts/build-loop.sh:1145-1158`). `--check` (review) prints `refuse ...`, which step 7 files as `stopped`. Under `--merge` the same deny falls to a merge entry, and then "a deny from a rule every merge applies refuses again under `--approved`, and is then filed as `stopped`" (`skills/dev-cycle/SKILL.md:586-588`). `--approved` runs the N rules: "approved (--merge --approved) runs the N rules alone" (`scripts/build-loop.sh:1345-1346`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:240-249`, `scripts/lib/dev-cycle-read.sh:1916-1927`, `scripts/build-loop.sh:1131-1165`, `skills/dev-cycle/SKILL.md:584-604`

---

## Claim 8: "A brief self-merges only when its own `Policy:` line also reads `self-merge`. Only the exact line with `self-merge` or `review` sets the policy, and `self-merge` also needs a valid never line (its `none` form for an empty list). Anything else counts as unset, which means `review`"

**Location:** `docs/dev-cycle.md:33-37`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the policy regex, the `never_ok` requirement (no line, then `none`), and `--status`'s brief Policy rule (static). Does not establish `--status` output for a real brief (not run).

`[[ "${text[policy]}" =~ ^Build-loop\ policy:\ (self-merge|review)$ ]]`, then `if [[ "$v" == self-merge && -z "$never_ok" ]]` gives "so self-merge is off" (`scripts/build-loop.sh:816-820`). The header says POLICY is "self-merge only when --settings' policy is self-merge and the brief's first "Policy:" line is exactly "Policy: self-merge"" (`:73-75`). Executed (settings.txt): with the never line deleted and the policy flipped it printed `policy review unset: line 7 reads self-merge, but there is no valid Self-merge never: line`. With `Self-merge never: none` it printed `policy self-merge set` and `never none: line 11 ... lists none`.

**Evidence:** `scripts/build-loop.sh:72-78`, `scripts/build-loop.sh:800-821`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r3/logs/settings.txt`

---

## Claim 9: "From 1 to 9 (anything else, or no line, means 3)"

**Location:** `docs/dev-cycle.md:38`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers 0, 3, 9, 10 and no line. Does not establish values with leading zeros or extra blanks beyond the regex reading.

`[[ "${text[slots]}" =~ ^Build-loop\ slots:\ ([123456789])$ ]]`, else `slots 3 default` (`scripts/build-loop.sh:822-825`). Executed: `0` and `10` printed `slots 3 default: line 9 is not exactly "Build-loop slots: N" with N from 1 to 9`, `9` printed `slots 9 set`, and main's file printed `slots 3 default: no line starts "Build-loop slots:"`.

**Evidence:** `scripts/build-loop.sh:822-825`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r3/logs/settings.txt`

---

## Claim 10: "Step 10 dispatches only into slots no running loop fills, and step 8 writes new briefs only while the queue is shorter than the slots. The queue counts open briefs whose loop is absent (not yet dispatched) or working, plus those sent back to a loop; a blocked, stopped or ready-for-review one waits on you and is not counted."

**Location:** `docs/dev-cycle.md:38-42`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers step 10's free-slot rule and step 8's queue rule. Does not establish behavior for a capped brief or a held stalled loop, which the sentence's "absent or working" would count but step 8 excludes.

Step 8: "open briefs whose loop step 7 read as absent or working, plus those it sends back to a loop, each counted once (a blocked, stopped, capped or ready one, or a stalled one held, waits on the user and is not counted)" (`skills/dev-cycle/SKILL.md:650-654`). A stalled loop keeps LOOP `working` (no marker) while "the session keeps it out of step 10" (`:573-575`), and a capped brief may read absent or working. The doc omits both exclusions, so a reader counting by its rule over-counts the queue. Step 10: "Fill free slots (`--settings`' `slots` less the loops this session runs)" (`:773-774`). It should add "capped" and "a stalled one held" to the not-counted list.

**Evidence:** `skills/dev-cycle/SKILL.md:569-576`, `skills/dev-cycle/SKILL.md:647-654`, `skills/dev-cycle/SKILL.md:767-775`

---

## Claim 11: "`*` and `?` match within one path part, a glob matches the path or any directory above it, and paths compare lower-cased. A malformed line turns self-merge off."

**Location:** `docs/dev-cycle.md:43-45`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `never_res`, extracted verbatim and run against 12 paths, plus the malformed-turns-off rule via `never_ok`. Does not establish `globform`'s acceptance of every entry spelling.

`never_res` emits `'[^/]*'` for `*`, `'[^/]'` for `?`, and `NEVER_RES+=("^$re(/|\$)")` over `lower "${g%/}"` (`scripts/build-loop.sh:1181-1192`). `srules` matches the lower-cased `$3` (`:1206-1208`). Run: `bash .../glob.sh`, cwd the scratch dir, at 2026-10-15T05:19:43Z, exit 0. Results: `Workflows/X.md -> workflows/`, `docs/a.md -> doc?/*.md`, `docs/sub/a.md -> -`, `aXb/c -> a*b`, `scriptsx/y -> -`. A malformed line sets `NEVER_LINE="never malformed: ..."` with `never_ok` unset (`:810`), so self-merge is refused (claim 8).

**Evidence:** `scripts/build-loop.sh:1178-1192`, `scripts/build-loop.sh:1205-1211`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r3/logs/glob.txt`

---

## Claim 12: "sessions in this repo read `workflows/`, `skills/`, `guides/` and `patterns/` from their own checkout, and the health check the orchestrator runs every iteration executes `scripts/`, `test/`, `hooks/` and `devcontainer-config/` from its worktree, while the release paste runs `devcontainer-config/install.sh` on the host before you see its diff."

**Location:** `docs/dev-cycle.md:48-51`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers AGENTS.md's repo-relative pointers, health-check.sh's sourcing and test runner, the bats suites that drive devcontainer-config, and install.sh drawing its own diff. Does not establish every session's actual reads, which depend on the agent, and does not establish `every iteration` beyond step 1's skip rule.

AGENTS.md: "check `workflows/` for applicable process docs" and "Skills are focused, single-purpose process docs in `skills/`" (`AGENTS.md:7`, `:24`). `~/.claude/skills` points at the image (`ls -la ~/.claude`: `skills -> /opt/claude-workflows/skills`). The checkout read is therefore the repo-relative one. health-check.sh runs `source "$REPO_ROOT/scripts/lib/log-format.sh"` (`scripts/health-check.sh:79`), `local runner="${HEALTH_CHECK_RUN_TESTS:-$REPO_ROOT/scripts/run-tests.sh}"` (`:413`) and `for hook in "$REPO_ROOT"/hooks/*.sh` (`:578`). The devcontainer-config part rests on the suites that run its scripts (paraphrased — no quote available because the coupling spans `test/install-host.bats`, `test/cc-isolated-functions.bats` and `test/cc-push.bats`). install.sh shows its review in `review_diff "$DEST" "$stage/" ...` (`devcontainer-config/install.sh:537`), so its own code has run before the diff appears.

**Evidence:** `AGENTS.md:7-37`, `scripts/health-check.sh:79-83`, `scripts/health-check.sh:400-420`, `scripts/health-check.sh:578-592`, `devcontainer-config/install.sh:517-540`

---

## Claim 13: "`templates/` (a snippet other repos copy by hand) and `global-instructions/` (...; the floor already refuses its `CLAUDE.md`) ... So in this repo self-merge can land only files outside those directories and off the floor: docs, `README.md`, `runs/` and `archive/`."

**Location:** `docs/dev-cycle.md:52-55`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the top-level tree at HEAD against the never line and the floor's instruction and dot rules. Does not establish which `docs/` subpaths are on the floor (decisions, thoughts, human-author, cycle files), which the sentence's "off the floor" covers.

`git ls-tree --name-only HEAD` lists dot files, `AGENTS.md`, `GEMINI.md`, `README.md`, `archive`, `docs`, `runs` and the ten never-line directories (paraphrased — no quote available because the claim is about directory layout, not a snippet). `templates/` holds only `templates/gitattributes-snippet.txt`, and `global-instructions/` only `global-instructions/CLAUDE.md`. `isstart` matches instruction basenames: `isstart() { [[ "${1##*/}" =~ $INSTRUCTION_FILE ]] ...` (`scripts/lib/dev-cycle-read.sh:714`). truthrule refuses dot paths: `elif [[ "/$1" == */.* ]]; then TRUTH_WHY="dot"` (`:1921`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:714`, `scripts/lib/dev-cycle-read.sh:1916-1927`, `devcontainer-config/install.sh:135`

---

## Claim 14: "Some of those docs are read as authority too (`docs/evaluation-rubric.md`, which self-eval scores against, and `docs/spikes/`, whose seeds later work loads); Q-149 asks whether to list them."

**Location:** `docs/dev-cycle.md:56-58`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the self-eval skill's stated rubric path and Q-149's text. Does not establish that every spike seed is loaded by later work, which is a workflow convention.

The self-eval skill describes itself as: "Score one skill or workflow against docs/evaluation-rubric.md" (skill listing, `skills/self-eval/SKILL.md` description). Q-149: "Two docs off the floor are also read as authority ...: `docs/evaluation-rubric.md` (self-eval's rubric) and `docs/spikes/` (seeds later work loads); listing them too is a fourth choice" (`docs/working/questions.md:367`). `docs/spikes` exists at HEAD.

**Evidence:** `docs/working/questions.md:361-379`, `skills/self-eval/SKILL.md:1-10`

---

## Claim 15: "**Review handoff.** No line. The pull-request route the design names is not built, and this repo has no PRs, so every review merge is one questions entry."

**Location:** `docs/dev-cycle.md:59-60`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers SETTINGS_AWK's keys (no review-handoff key) and step 7's note. Does not establish anything about a future PR route.

SETTINGS_AWK keys only `policy`, `slots`, `never`, `roots` and `homes` (`scripts/lib/dev-cycle-read.sh:623-627`). Step 7: "(D4's `Review handoff: pull request` route is not built: every review brief gets a merge entry.)" (`skills/dev-cycle/SKILL.md:605-606`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:618-633`, `skills/dev-cycle/SKILL.md:605-606`

---

## Claim 16: Roadmap: Next item 5 (Next at most five); Ideas "audit-dimension menu" ("its only named dimension is D2's constraints one"), "plan D13 built only `--main-log`'s check", "install.sh's archive honors replace refs"; Done "Build-loop handoff"

**Location:** `docs/roadmap.md:49-53`, `docs/roadmap.md:65-80`, `docs/roadmap.md:125-129`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each named claim against SKILL.md, the plan and install.sh. Does not establish the other Ideas entries, which this branch did not touch.

Next holds items 1–5, and the skill says "**Next**: at most five items" (`skills/dev-cycle/SKILL.md:542`). Step 4b: "Every deep audit covers one more dimension: whether the constraints and project guidance still match intent" (`:483-484`). Plan D13: "This is the minimal part of roadmap item (d), moved into this unit" (`docs/working/plan-build-loop-handoff.md:103`). install.sh's `repo_git` is `git --no-optional-locks -C "$REPO_ROOT" -c core.hooksPath=/dev/null -c core.fsmonitor=false "$@"`, with no replace-ref switch (`devcontainer-config/install.sh:180-182`), and `git_state_gate` reads only config keys and info/attributes (`:209-252`). No `replace` or `grafts` appears in install.sh.

**Evidence:** `docs/roadmap.md:24-80`, `skills/dev-cycle/SKILL.md:469-487`, `docs/working/plan-build-loop-handoff.md:97-104`, `devcontainer-config/install.sh:180-252`

---

## Claim 17: Rubric iteration-2 section: A8–A11, C13–C21 with their sources, tiers and statuses

**Location:** `docs/reviews/code-review-rubric-2026-10-14-feat-build-loop-u5.md:97-117`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each row's source finding and severity against the i2 reports, and each "Fixed" status against the branch content. Does not establish the i1 rows, which iteration 2's report already checked (its claim 12).

Security i2's severities are Medium, Medium, Medium and Low for F1–F4 (`docs/reviews/security-review-2026-10-14-u5-i2.md:43`, `:61`, `:74`, `:87`), and F3's confidence is "Low" (`:78`), matching A9–A11 and C15. API i2's F1–F5 headings match C17, C18, C19, C20 and C21 (`docs/reviews/api-consistency-review-2026-10-14-u5-i2.md:36-96`). A9's fix was exercised (claim 36a), A8's is claim 7, C13's is claim 10's step-10 sentence, and C21's is the as-built note's "supersedes ... D5's 'In this repo' interim and F57's `workflows/`" (`docs/working/plan-build-loop-handoff.md:358`).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-14-feat-build-loop-u5.md:97-117`, `docs/reviews/security-review-2026-10-14-u5-i2.md:39-100`, `docs/reviews/api-consistency-review-2026-10-14-u5-i2.md:34-107`

---

## Claim 18: The four override-log rows added on this branch

**Location:** `docs/reviews/override-log.md:828-831`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each row's finding, source and cited line numbers. Does not establish the decision-035 trust model the rows invoke.

Row 831 cites `devcontainer-config/install.sh:180-182`, `:208-252` and `:279`. These are `repo_git() {` at 180, `GIT_EXEC_KEYS_RE=` at 208 through `git_state_gate`'s close, and `if ! repo_git -c tar.umask=022 archive --format=tar "$commit" -- "$@"` at 279. Row 830 matches i2's claims 31 and 34 (Mostly accurate) as recorded in `docs/reviews/code-fact-check-report-2026-10-14-u5-i2.md:530-592`. Rows 828 and 829 match security i1 F7 ("Informational", `docs/reviews/security-review-2026-10-14-u5-i1.md:126`) and i1 claim 42.

**Evidence:** `docs/reviews/override-log.md:828-831`, `devcontainer-config/install.sh:180-280`, `docs/reviews/code-fact-check-report-2026-10-14-u5-i2.md:530-592`

---

## Claim 19: Plan as-built note ("the decision-log row is 72, not 70 ...; Q-150-Q-152 (C1-C3), Q-153 (C4), Q-154 (C5, filed answered and archived), Q-155 ..., Q-156 ...; Roadmap (f) went to Next and (e) to Ideas ...; The pre-answered D10 entry was not filed"); D10's "row 72 (written as row 70 ...)"; brief `Status: done`

**Location:** `docs/working/plan-build-loop-handoff.md:91`, `docs/working/plan-build-loop-handoff.md:358`, `docs/working/briefs/2026-10-02-build-loop-handoff.md:3`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each enumerated fact against the decision log, questions files, roadmap and dev-cycle.md. Does not establish the note's account of why the review widened the line beyond claim 12.

Decision log rows 70 and 71 are dated 2026-10-06 and 2026-10-14, and row 72 is the build-loop handoff (`docs/decisions/log.md:93-95`). The questions files hold Q-150–Q-153, Q-155 and Q-156 open, and Q-154 answered in the archive (`docs/working/questions.md:381-463`, `docs/working/questions-archive.md:2712`). `--settings` reads no review-handoff key (claim 15). The brief's line 3 is `Status: done`.

**Evidence:** `docs/decisions/log.md:93-95`, `docs/working/questions.md:381-500`, `docs/roadmap.md:49-80`

---

## Claim 20: Q-154 archived: "**Answer (2026-10-04, in session; plan D12; filed 2026-10-14):** [1], a full cycle every iteration for now; move to a light pass of steps 7, 8 and 10 ..."

**Location:** `docs/working/questions-archive.md:2712-2727`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the answer against plan D12, and the archive's validity under `questions.sh check`. Does not establish the date of the in-session answer beyond the plan's own record.

Plan: "The cost per iteration (F53) was C5. You answered on 2026-10-04: a full cycle every iteration for now, and a move to a light pass of steps 7, 8 and 10 between full cycles once the costs are visible. U5 files C5 as ANSWERED" (`docs/working/plan-build-loop-handoff.md:96`). Run: `timeout 120 bash scripts/questions.sh check`, cwd `/workspace/.claude/wt-build-loop-u5`, at 2026-10-15T05:14:46Z, exit 0, `✓ questions: structure valid, indexes current`.

**Evidence:** `docs/working/plan-build-loop-handoff.md:24`, `docs/working/plan-build-loop-handoff.md:96`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r3/logs/qcheck.txt`

---

## Claim 21: Q-103 "What the gate can and cannot do": "... the gate that runs is the root-owned image copy, which no loop can edit (D6, Q-140 [1]). Each iteration checks that main moved only by the orchestrator's merges, the gate's merges and answer-only commits (D13)."

**Location:** `docs/working/questions.md:91`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the paragraph against the plan's section and the D6 block. Does not establish the image's ownership on a given host.

The plan's section opens "Loops run as your uid, with a shell, in worktrees that share `/workspace/.git`. No script can contain a loop that turns hostile with its shell" (`docs/working/plan-build-loop-handoff.md:33`). The D6 block reads "It always runs the root-owned image copy under D6_OPT by absolute path" and `own()` refuses a path that is "not root-owned, a plain path and unwritable here" (`skills/dev-cycle/SKILL.md` D6 block). Plan D13 classifies "each first-parent commit on main as `gate`, `chore`, `answers` or `other`" (`docs/working/plan-build-loop-handoff.md:102`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:31-37`, `docs/working/plan-build-loop-handoff.md:97-104`, `skills/dev-cycle/SKILL.md:189-255`

---

## Claim 22: Q-103 residuals F11 ("the gate runs it in a clean checkout at `MAIN_SHA` (`checkout_gate` refuses anything else)"; known issue A5 gaps), F19, F21 and F35

**Location:** `docs/working/questions.md:95-99`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each bullet against its plan row and, for F11, checkout_gate's refusals. Does not establish the import walk's completeness, which A5 lists as gaps.

`checkout_gate` refuses `the checkout's HEAD is $x, not the default branch's commit $MAIN_SHA`, a status difference, skip-worktree entries and conversions (`scripts/build-loop.sh:1241-1295`). The plan rows say the same as the bullets: F19 "A deliberate `git push` or a commit disguised as `answers` is not caught" (`docs/working/plan-build-loop-handoff.md:134`); F21 "What a steered loop *does* outside git is bounded only by the sandbox" (`:136`); F35 "The prompt forbids each (T19); the subagent shares the orchestrator's permission mode" (`:153`); F11's gap list (`:126`).

**Evidence:** `scripts/build-loop.sh:1233-1295`, `docs/working/plan-build-loop-handoff.md:126-153`

---

## Claim 23: F29: "The gate refuses a worktree with main checked out unless it is on main, clean and mid no rebase, bisect or merge. Left: that worktree switches branch between the check and the fast-forward."

**Location:** `docs/working/questions.md:98`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `land()`'s worktree checks and the ff path. Does not establish the residual window's size.

`land` requires `symbolic-ref -q HEAD` to be `refs/heads/$MAIN` at `$MAIN_SHA`. It refuses `MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD BISECT_START rebase-merge rebase-apply sequencer` and a tracked change, then `git -C "$w" ... merge --ff-only -q "$NEW"` and re-reads main (`scripts/build-loop.sh:1527-1563`). Its header says "a refusal after the write leaves NEW set and, but after a racing branch switch in W, unreachable" (`:1477-1479`).

**Evidence:** `scripts/build-loop.sh:1467-1565`

---

## Claim 24: F37: "Two chore branches can mint the same Q-ID; `questions.sh check` catches it, at the land or, after a merge-in of main (which skips step 1's check), at the next health check."

**Location:** `docs/working/questions.md:100`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers step 9's `check` before staging and the health check's questions gate. Does not establish that a merge-in path re-runs check (the bullet says it does not).

Step 9: "after `questions.sh index` and `check` in WT when this iteration filed or edited entries" (`skills/dev-cycle/SKILL.md:727-729`). The health check validates the questions files: `grep -aqF "$INDEX_START" "$file"` and the duplicate and stale-index checks in `cmd_check` (`scripts/questions.sh:280-312`). How health-check.sh reaches it is paraphrased — no quote available because it is invoked through the dev-cycle skill's step 1 and health-check.sh's own checks, which were not traced line by line on this pass.

**Evidence:** `skills/dev-cycle/SKILL.md:725-735`, `scripts/questions.sh:260-313`

---

## Claim 25: F58 ("The release entry (`image-lag`) lists every commit and changed path since the image's commit and flags self-merge subjects. The release paste runs `devcontainer-config/install.sh` before it shows its diff") and F59 ("Step 4's drift check samples one such decision per sampled merge, and a finding triggers the deep audit's constraints dimension")

**Location:** `docs/working/questions.md:101-102`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers SKILL.md step 0.1 and step 4's drift check. Does not establish the orchestrator's execution of either.

Step 0.1: "every first-parent commit after C as a list item ...; flag a subject ending `(build-loop self-merge)`" (`skills/dev-cycle/SKILL.md:300-302`). Step 4: "For each sampled merge a build loop made ..., read one Path A decision ... A finding is a step 4b trigger" (`:462-467`). install.sh's diff is claim 12.

**Evidence:** `skills/dev-cycle/SKILL.md:296-308`, `skills/dev-cycle/SKILL.md:462-487`

---

## Claim 26: R8: "`git/config`, `git/info/`, `git/refs/`, `git/HEAD`, `work/.gitattributes`, `err`, `diff`, and `answer`, the file holding `--approved`'s verdict on the merge entry (override rows 509, 684)"

**Location:** `docs/working/questions.md:103`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the surface list against plan step 13, rows 509 and 684, and `approval`'s read of `answer`. Does not establish that the list is every GATE_TMP file (`status`, `others`, `tree`, `wts`, `msg`, `state` and `ff` also exist).

Plan step 13 lists "its git/config, git/info/, git/refs/, git/HEAD, work/.gitattributes, err and diff; override row 509" (`docs/working/plan-build-loop-handoff.md:357`). Row 684 says the routing "adds `answer` to row 509's surface list". `approval` runs `check_answer "$1" > "$GATE_TMP/answer"; r="$(< "$GATE_TMP/answer")"` (`scripts/build-loop.sh:1445`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:357`, `docs/reviews/override-log.md:509`, `docs/reviews/override-log.md:684`, `scripts/build-loop.sh:1438-1455`

---

## Claim 27: "Also routed here during the build (override-log rows ..., by line)": rows 668, 548, 749, 750, 784, 786, 787, 797, 801, 802, 682, plus the U2b3a, U3a1, U3a2 and U4c items

**Location:** `docs/working/questions.md:104-117`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each row-numbered item against the row at that line, and the unit-tagged items against their sources. Does not establish that no other override row routes to Q-103. Not every unit-tagged item is an override row: U2b3a's is a plan residual.

Each cited line holds the described finding. 668 is "a hand-edited rebase todo holding an `update-ref refs/heads/main` line", 548 is "points origin/HEAD at its own branch", 749 and 750 are the planted hooks and the FIFO lock, 784 is the bootstrap after a rewrite, 786 is the dispatch count after the dispatch, 787 is `--prompt --steal`, 797 is "Merge entries flag floor paths by class", 801 is "`--start`/`--prompt` read main live", 802 is "accept any `--answered` ID", and 682 is health-check.sh self-mergeable (`docs/reviews/override-log.md` at those lines). The U3a1 items are rows 638 and 646, the U3a2 `core.bare` item is row 671, and U4c's same-uid shell is stated in the D6 block ("cannot guard against this uid's own shell (PATH, exported functions): the plan's same-uid residual (Q-103)", `skills/dev-cycle/SKILL.md` D6 header). U2b3a's item is the plan's "Residual: a hostile loop can edit the worktree registry in the shared common dir (Q-103)" (`docs/working/plan-build-loop-handoff.md:293`), not an override row. The list's heading says "override-log rows", so this one item's source differs from the heading (minor).

**Evidence:** `docs/reviews/override-log.md:548`, `docs/reviews/override-log.md:638`, `docs/reviews/override-log.md:646`, `docs/reviews/override-log.md:668-682`, `docs/reviews/override-log.md:749-802`, `docs/working/plan-build-loop-handoff.md:293`

---

## Claim 28: Q-103 option [2]: "A brief with `Policy: self-merge` lands through the gate with no review when every changed path is in its `Paths:` line and off the floor and the never line; anything else falls to [1]'s entry"

**Location:** `docs/working/questions.md:122`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the self-merge route against `srules` and step 7. Does not establish the conflict or environment routes, which "anything else" sweeps in wrongly.

The brief's own files also land unlisted: `[[ "$2" != "$3" ]] || ! ownfile "$2" "$1" "$4" || return 0` (`scripts/build-loop.sh:1209`). Only a path refusal falls to a merge entry: "A conflict is `stopped`. Any other refusal ... tried again next iteration" (`skills/dev-cycle/SKILL.md:589-592`). An N-rule refusal reaches the entry but then ends stopped (claim 7). The precise form is "...in its `Paths:` line or one of its own files ...; a path refusal falls to [1]'s entry".

**Evidence:** `scripts/build-loop.sh:1205-1218`, `skills/dev-cycle/SKILL.md:573-592`

---

## Claim 29: Q-103 "**Interim:** [1] `review`, recorded as `Build-loop policy: review (interim; Q-103)`, which `--settings` reads as unset, which means `review`" and "If the answer differs: ... for [2] the never line must stay valid"

**Location:** `docs/working/questions.md:124-125`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the interim reading and the [2] edit (flipped policy with the current never line). Does not establish the Policy-note prose edit.

Executed in claim 2's run: as written, `policy review unset`. With `Build-loop policy: self-merge`, `policy self-merge set`. With the never line removed, self-merge is off (claim 8).

**Evidence:** `scripts/build-loop.sh:814-821`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r3/logs/settings.txt`

---

## Claim 30: Q-149: "sessions read `skills/` (beyond `SKILL.md`, which the floor already refuses), `guides/` and `patterns/` ...; the health check ... executes `scripts/`, `test/`, `hooks/` and `devcontainer-config/` ...; If the answer differs: a one-line edit to `docs/dev-cycle.md` ... and its test line in `test/scripts/build-loop-read.bats`"

**Location:** `docs/working/questions.md:361-379`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the floor's SKILL.md refusal, the test line's existence, and consistency with claims 12–14. Does not establish option [2]'s and [3]'s consequences beyond the never-line mechanics.

The instruction-file pattern covers `SKILL.md` ("Instruction-file basenames, lower-cased: CLAUDE.md, CLAUDE.local.md, AGENTS.override.md and the like, GEMINI.md, SKILL.md", `scripts/lib/dev-cycle-read.sh:698-700`). The test line is `[[ "$(line never)" == "never workflows/ scripts/ ... global-instructions/ set: line "*" of docs/dev-cycle.md on the default branch" ]]` (`test/scripts/build-loop-read.bats:80`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:700-714`, `test/scripts/build-loop-read.bats:79-81`

---

## Claim 31: Q-150 ([1] "the body quoted line by line (`--marker`)"), Q-152 ([1] "It wakes every 1200–1800 s and runs a full cycle only when main moved past its last land ..., a retry's wait ran out or you wrote"), Q-153 ("deleting branches" needs approval in every mode)

**Location:** `docs/working/questions.md:381-444`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each entry's "built" option against the header or skill and Q-153's quote against the global instructions. Does not establish option costs.

`--marker`'s header: "each line prefixed "> " (an empty one ">")" (`scripts/build-loop.sh:105`). Step 10's wait: "with none, every 1200-1800 s, and only when the default branch moved past this iteration's last land ..., a retry's wait ran out, or the user wrote, run a full iteration" (`skills/dev-cycle/SKILL.md:810-814`). The global CLAUDE.md lists under "Still require user approval (regardless of mode)": "Force-push, `git reset --hard`, deleting branches" (paraphrased — no quote available because the file is the session's global instructions, read from context, not the repo).

**Evidence:** `scripts/build-loop.sh:96-108`, `skills/dev-cycle/SKILL.md:808-815`

---

## Claim 32: Q-151: "[1] Frees the slot (built) | Only a live or queued loop counts against the slots; a blocked item re-enters the queue on its existing branch once answered, ahead of new briefs" and "If the answer differs: [2] is a change to the skill's step 10 slot count."

**Location:** `docs/working/questions.md:405-409`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers option [1] against steps 8 and 10 and the [2] remedy's scope. Does not establish D9's wording, which is the plan's.

Option [1] holds. Step 10 fills "briefs step 7 sends back first, then absent ones" (`skills/dev-cycle/SKILL.md:774-775`). The [2] remedy names only step 10, but the brief queue that limits new briefs is step 8's count: "a blocked, stopped, capped or ready one ... waits on the user and is not counted" (`:653-654`). Holding the slot would change that count too. Precise: "a change to steps 8 and 10's counts".

**Evidence:** `skills/dev-cycle/SKILL.md:647-654`, `skills/dev-cycle/SKILL.md:767-775`

---

## Claim 33: Q-155: "**Interim:** [2]. `--settings` prints `constraints missing`, and step 10 files nothing more while this entry is open."

**Location:** `docs/working/questions.md:446-461`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `--settings`' constraints line (executed, no constraints doc) and step 10's slug-keyed dedupe. Does not establish the orchestrator's dedupe at run time.

Every settings case printed `constraints missing: no docs/constraints.md on the default branch` (settings.txt). Step 10: "else one `you: judgment` entry, slug `constraints-doc-missing`, ... unless an open one with that slug exists" (`skills/dev-cycle/SKILL.md:770-772`), and Q-155's slug is `constraints-doc-missing` (`docs/working/questions.md:446`).

**Evidence:** `scripts/build-loop.sh:827-841`, `skills/dev-cycle/SKILL.md:769-772`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r3/logs/settings.txt`

---

## Claim 34: Q-156: "The image's commit C is `8d0e660e...` (`/opt/claude-workflows/.manifest`, assembled from `/home/magfrump/claude-workflows`), on main's first-parent history. ... The image's dev-cycle skill lacks the D6 block (U4c)"

**Location:** `docs/working/questions.md:470`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the manifest lines, C's place on main's first-parent history, and the image skill's D6 section. Does not establish the host checkout's state.

Run: `bash .../lists.sh`, cwd the u5 worktree, at 2026-10-15T05:16:40Z, exit 0. The manifest reads `commit=8d0e660e2e5a9769200500ac3dcfb4b113a32589` and `assembled_from=/home/magfrump/claude-workflows`, and `git rev-list --first-parent main | grep -c` gives `1`. The image SKILL.md equals C's (`diff` silent). Its `## The D6 block` holds only "Pending: Q-140 (the snippet's trust root). Its canonical copy is `test/lib/d6-snippet.bash`", and no block. U4c (308196e7) is not an ancestor of C.

**Evidence:** `/opt/claude-workflows/.manifest`, `/opt/claude-workflows/skills/dev-cycle/SKILL.md`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r3/logs/q156-lists.txt`

---

## Claim 35: Q-156: "M is `659a1c61...`, the last commit on `feat/build-loop-u5` that changes anything the release installs; the branch's later commits change only `docs/`"; the gate-code list, the 11 first-parent commits ("none is a `(build-loop self-merge)`"), and the 28 paths outside `docs/` ("about 500 paths under `docs/` besides, nearly all `docs/reviews/`")

**Location:** `docs/working/questions.md:470-489`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each list against git from C. Does not establish what main will hold at release time (the paste checks that).

From q156-lists.txt: the branch commits touching `.gitattributes devcontainer-config global-instructions guides hooks patterns scripts skills workflows` are `659a1c61`, `771a5d02` and `92fa6e52`. Files after M are eight paths, all under `docs/`. `git log --first-parent --format='%h %s' 8d0e660e..main` gives the same 11 commits (listed newest first there, oldest first in the entry). The self-merge subject count is `0`. Gate code C..M is `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh` and `skills/dev-cycle/SKILL.md`. `git diff --name-status 8d0e660e 659a1c61 -- . ':!docs/'` gives the same 28 paths, `test/lib/d6-snippet.bash` as `D`, with 505 under `docs/`, 494 of them in `docs/reviews/`.

**Evidence:** `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r3/logs/q156-lists.txt`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r3/lists.sh`

---

## Claim 36a: Q-156 paste: "with only `rev-parse` and `for-each-ref` (neither runs a hook or fsmonitor) and replace refs ignored, it checks that HEAD is main, that no replace ref or graft file exists ..., and that the root `.gitattributes` and every directory the release installs from are the same tree at HEAD as at M; so it refuses when main has moved a released path past what this entry lists"

**Location:** `docs/working/questions.md:491-496`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the paste exactly as committed (cd replaced by `$CLONE`, install.sh replaced by an echo), in a throwaway `--shared` clone across 11 cases. Does not establish install.sh's own run, or a host where `HEAD` is a symbolic ref to another branch at main's commit (a detached HEAD at main's commit passes, by design of "HEAD is main" as a commit compare).

Run: `bash .../cases.sh`, cwd the scratch dir, at 2026-10-15T05:16:17Z, driver exit 0. Results: pre-merge main gave `release refused: skills differs from M` (exit 1); after merging the branch, `PASTE-OK-WOULD-RUN-INSTALL` (exit 0); detached at main's commit passed; another branch ahead gave `HEAD is not main`; a replace ref gave `replace refs present`; `info/grafts` gave `info/grafts present`; a docs-only commit passed; a `scripts/` change gave `scripts differs from M`, a `.gitattributes` change `.gitattributes differs from M`, and an extra `global-instructions/` file `global-instructions differs from M`. Every command in the paste is `rev-parse` or `for-each-ref`: `test -z "$(git for-each-ref refs/replace/)"`, `"$(git rev-parse --git-common-dir)/info/grafts"`, `git rev-parse "HEAD:$p"` (`docs/working/questions.md:494`).

**Evidence:** `docs/working/questions.md:491-498`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r3/logs/q156-paste.txt`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r3/paste.sh`

---

## Claim 36b: "(`git archive` in install.sh would honor either)" — said of a replace ref and a graft file

**Location:** `docs/working/questions.md:491`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers what `git archive <commit>` writes with a replace ref and with `info/grafts`. The replace-ref half holds. Does not establish any other install.sh git call reading history (none does: `repo_git` runs only `rev-parse`, `cat-file`, `status` and `archive`).

Run: `bash .../grafts.sh`, cwd the scratch dir, at 2026-10-15T05:20:06Z, exit 0. A graft rewrote the commit's parent (`parent=3ec4953d...`) but `git archive "$B" f` still printed `evil`, its own blob. A blob replace ref changed the output to `good`, and `GIT_NO_REPLACE_OBJECTS=1` restored `evil`. Grafts change only parents, and install.sh archives one commit's tree: `repo_git -c tar.umask=022 archive --format=tar "$commit" -- "$@"` (`devcontainer-config/install.sh:279`). So a graft cannot change what the release installs. Refusing grafts is harmless and fail-closed (the D6 block refuses them too), but the stated reason holds only for replace refs. The precise version: "a replace ref, which `git archive` in install.sh would honor, or a graft file, refused as the D6 block refuses it".

**Evidence:** `devcontainer-config/install.sh:180-182`, `devcontainer-config/install.sh:277-286`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r3/logs/grafts.txt`

---

## Claim 37: The paste's directory list `.gitattributes devcontainer-config global-instructions guides hooks patterns scripts skills workflows` as "every directory the release installs from"

**Location:** `docs/working/questions.md:494`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers install.sh's CLAUDE_HOME_SRC and PAYLOAD (its own directory). Does not establish that every file in `global-instructions/` is installed (only `CLAUDE.md` is; iteration 2's C14 reworded this as "installs from", which holds).

`CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)` (`devcontainer-config/install.sh:135`), and `PAYLOAD=(devcontainer.json Dockerfile init-firewall.sh ... claude-home)` (`:110`), which install.sh takes from its own `devcontainer-config/` directory. The list adds `.gitattributes`, which `git archive` reads.

**Evidence:** `devcontainer-config/install.sh:110`, `devcontainer-config/install.sh:125-135`

---

## Claim 38: "**If the paste refuses:** main changed a released path after M. That change is not in the lists above"

**Location:** `docs/working/questions.md:498`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the refusal causes the paste can print (claim 36a's cases). Does not establish the user's reading of the printed reason.

The paste refuses for four causes: `HEAD is not main`, `replace refs present`, `info/grafts present` and `$p differs from M` (`docs/working/questions.md:494`). Run before the merge, it also refuses with `skills differs from M` (q156-paste.txt), where main lacks M's change rather than having moved past it. The line covers only the tree case, though each refusal prints its own reason. Precise: "If the paste refuses with `differs from M`: ...".

**Evidence:** `docs/working/questions.md:494-498`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r3/logs/q156-paste.txt`

---

## Claim 39: Research corrections: "`/opt/claude-workflows/scripts/build-loop.sh` is in the image now (its `.manifest` commit was 8d0e660e on 2026-10-14), and since Q-140 [1] the D6 block always runs that root-owned image copy"; "the cycle does spawn loops itself, as background subagents with no isolation, in a worktree `build-loop.sh --start` creates (plan D1)"

**Location:** `docs/working/research-build-loop-handoff.md:23`, `docs/working/research-build-loop-handoff.md:59`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the image file's presence, C's date and step 10's dispatch. Does not establish the image's ownership bits.

`ls /opt/claude-workflows/scripts/build-loop.sh` succeeds. `git log -1 --date=iso 8d0e660e` prints `2026-10-14 00:12:07 -0700`. Step 10: "start one background subagent (Agent tool, no isolation)" (`skills/dev-cycle/SKILL.md:779`).

**Evidence:** `/opt/claude-workflows/.manifest`, `skills/dev-cycle/SKILL.md:776-784`, `docs/working/plan-build-loop-handoff.md:39`

---

## Claim 40: Seed: "**Status:** superseded by decision log row 72 (the build-loop handoff as built, merged with `feat/build-loop-u5`; ...)"

**Location:** `docs/working/seed-build-loop-handoff.md:3`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers row 72's "Supersedes the seed". Does not establish the merge, which is pending (the line reads as true once it lands).

Row 72 ends "Built as stacked units U0a–U5 under the row-62 cap. Supersedes the seed." (`docs/decisions/log.md:95`).

**Evidence:** `docs/decisions/log.md:95`

---

## Claim 41: SKILL.md step 0.1: the `image-lag` entry "is also the release entry ... every first-parent commit after C as a list item (`hg -C MAIN_WT log --first-parent --format='%h %s' C..M`; flag a subject ending `(build-loop self-merge)` ... the flag is a pointer, not proof), every path changed from C to M outside `docs/` on one line ... (the image carries none of `docs/`: give its count)"

**Location:** `skills/dev-cycle/SKILL.md:297-303`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the subject suffix against gate_msg's merge subject and install.sh's payload (no docs/). Does not establish that a hand commit cannot copy the suffix (the text says it can).

`--main-log` parses `^Merge\ branch\ \'(.+)\'\ \(build-loop\ (self-merge|approved merge)\)$` (`scripts/build-loop.sh:1768`), so a self-merge subject ends `(build-loop self-merge)`. Neither CLAUDE_HOME_SRC nor PAYLOAD names `docs` (`devcontainer-config/install.sh:110`, `:135`).

**Evidence:** `scripts/build-loop.sh:1459-1466`, `scripts/build-loop.sh:1766-1775`, `devcontainer-config/install.sh:110-135`

---

## Claim 42: "each subject or path holding `<`, `>`, a backtick, a CR, another control or bidi character, or bytes that are not UTF-8 written as `(withheld: see SHA)` (questions.sh finds its `<!-- index:` markers anywhere in a line, and `--check-answer` refuses an unclosed `<!--`)"

**Location:** `skills/dev-cycle/SKILL.md:303-306`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both stated reasons against questions.sh's marker matching and FENCE_AWK's comment refusal. Does not establish reasons for each other withheld class (backtick, bidi, non-UTF-8), which the parenthetical does not claim to give.

questions.sh matches markers unanchored: `index($0, start) { print; ...` and `index($0, end) { skip = 0 }` (`scripts/questions.sh:340-341`), and `sed -n "/$INDEX_START/,/$INDEX_END/p"` (`:294`). check_answer runs `awk ... "$FENCE_AWK$ANSWER_AWK"` and turns an `odd` result into a skip of the whole file (`scripts/lib/dev-cycle-read.sh:2152-2154`). FENCE_AWK's reasons include `comment) echo "opens an HTML comment that does not close on the same line"` (`:321`). This fixes iteration 2's claim 28.

**Evidence:** `scripts/questions.sh:290-343`, `scripts/lib/dev-cycle-read.sh:255-325`, `scripts/lib/dev-cycle-read.sh:2136-2163`

---

## Claim 43: Step 10: "else one `you: judgment` entry, slug `constraints-doc-missing`, asking for `docs/constraints.md`, unless an open one with that slug exists: D2"

**Location:** `skills/dev-cycle/SKILL.md:770-772`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers consistency with Q-155's slug and plan D2. Does not establish run-time dedupe.

Plan D2: "Without it, or with no hard constraint in it, the orchestrator dispatches nothing in that repo and files one `you: judgment` entry saying so" (`docs/working/plan-build-loop-handoff.md:50`). Q-155's heading is `### Q-155 · constraints-doc-missing` (`docs/working/questions.md:446`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:50`, `docs/working/questions.md:446`

---

## Claim 44: Bats assertion: "The interim never line (every directory that takes effect here without a release: plan D5, F57, Q-149) and the slots line (U5)."

**Location:** `test/scripts/build-loop-read.bats:79-81`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the one changed test. Does not establish the rest of the suite (not run).

Run: `GIT_CONFIG_GLOBAL=/dev/null timeout 300 bats -f "own docs/dev-cycle.md" test/scripts/build-loop-read.bats`, cwd `/workspace/.claude/wt-build-loop-u5`, at 2026-10-15T05:14:46Z, exit 0, `ok 1 --settings on this repo's own docs/dev-cycle.md: review, unset by the interim note (T3, G19)`.

**Evidence:** `test/scripts/build-loop-read.bats:72-82`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r3/logs/bats.txt`

---

## Claim 45: Onboarding step 13: "plus any the project adds to its `Self-merge never:` line, which self-merge requires: `Self-merge never: none` for an empty list"; "a branch that changes `docs/constraints.md` or the cycle's own files ends stopped under either policy"; constraints doc "hard constraints (`H1: …`, each with a `success:` line ...) and soft ones (`S1: …`) ... the dev cycle dispatches no build loop in a repo without one that holds a hard constraint"

**Location:** `workflows/codebase-onboarding.md:453`, `workflows/codebase-onboarding.md:455`, `workflows/codebase-onboarding.md:460`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the never-line requirement (executed), the end state of both-policy refusals (claim 7), and CONSTRAINTS_AWK's grammar with `ok` gating dispatch. Does not establish the constraints grammar's best-effort "near" refusal, which the step does not describe.

Executed in claim 8's cases. CONSTRAINTS_AWK matches `/^(- )?[HS][123456789][0123456789]*: [^ \t]/` and requires `success:` for a hard one (`scripts/build-loop.sh:726-745`). `ok` with `$c -gt 0` hard is the only `constraints ok` line (`:833`), and step 10 runs only "while `--settings` prints `constraints ok`" (`skills/dev-cycle/SKILL.md:770`). The roadmap holds "A process for writing a repo's constraints doc" (`docs/roadmap.md:59`).

**Evidence:** `scripts/build-loop.sh:720-746`, `scripts/build-loop.sh:827-841`, `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-final-r3/logs/settings.txt`

---

## Claim 46: Commit b5eaedf6 body: "Iteration 2's reports, rubric section and three override rows."

**Location:** commit `b5eaedf6`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the count against the commit's own diff. Does not establish the rest of the body, which holds (Q-156 paste changes, Q-149 authority docs, Q-151 and Q-103 terms, the as-built note, the roadmap Idea).

`git show b5eaedf6 -- docs/reviews/override-log.md` adds two rows (i2 claims 31 and 34, and security i2 F2), and `--stat` shows `docs/reviews/override-log.md | 2 +`. The rubric's iteration-2 table names two override rows, A10 and C16. The body should say two. This resembles the logged commit-count patterns (59ca38f, 37c5ea9).

**Evidence:** `docs/reviews/override-log.md:830-831`, `docs/reviews/code-review-rubric-2026-10-14-feat-build-loop-u5.md:105-110`

---

## Claim 47: Commit 659a1c61 body: "Review iteration 2 (fact-check claims 5b, 6, 28, 30b; security F3, F4; api-consistency F4, F5)."

**Location:** commit `659a1c61`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the finding list against the commit's diff. Does not establish the other sentences, which match the diff (settings prose, onboarding naming `docs/constraints.md`, step 0.1's withheld classes).

API i2 F5 is "Plan D5 "In this repo", F57 and step 11 still state the `workflows/`-only interim" (`docs/reviews/api-consistency-review-2026-10-14-u5-i2.md:96`). 659a1c61 touches only `docs/dev-cycle.md`, `skills/dev-cycle/SKILL.md` and `workflows/codebase-onboarding.md` (`git show --stat`). The plan edit that fixes F5 is in b5eaedf6, whose body also claims F5. Drop F5 from this body.

**Evidence:** `docs/reviews/api-consistency-review-2026-10-14-u5-i2.md:96-107`, `docs/working/plan-build-loop-handoff.md:358`

---

## Claim 48: Commit bodies 92fa6e52, 42414307, 57e26f6b and 87ca421e

**Location:** commits `92fa6e52`, `42414307`, `57e26f6b`, `87ca421e`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each body against its own commit's tree (for example, 92fa6e52's `Self-merge never: workflows/` at that commit, and 57e26f6b's M=771a5d02 paste and subshell). Does not establish later supersession, which those bodies do not claim.

`git show 92fa6e52:docs/dev-cycle.md` holds `Build-loop slots: 3` and `Self-merge never: workflows/` (lines 9 and 11). At 2846f9fa Q-153's slug was `merged-branch-deletion-rule`, and the current one is `build-loop-c4-merged-branch-deletion`, as 57e26f6b's body says. 57e26f6b's paste note ("in a subshell so a refusal cannot close the user's shell") matches the `( ... exit 1 ... ) && ...` shape (`docs/working/questions.md:494`). 87ca421e's "Q-149 and Q-103 [2] say the same" matches `docs/working/questions.md:122` and `:373`.

**Evidence:** `docs/working/questions.md:122`, `docs/working/questions.md:373`, `docs/working/questions.md:494`

---

## Claim 49: Commit bodies 2846f9fa ("plus the residuals earlier units routed to it"), 771a5d02 ("sessions read the first group ..., the orchestrator's health check executes the second"; "which files both policies refuse") and c63da94d ("6 Must Address")

**Location:** commits `2846f9fa`, `771a5d02`, `c63da94d`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the defects iterations 1 and 2 found in these bodies are still there and are recorded. Does not call for action: override rows 829 and 830 record them as Won't-Fix (immutable history).

These are i1 claim 42 and i2 claims 31 and 34, unchanged because history is not rewritten. Row 829 records 2846f9fa, and row 830 records 771a5d02 and c63da94d (`docs/reviews/override-log.md:829-830`).

**Evidence:** `docs/reviews/override-log.md:829-830`

---

## Claims Requiring Attention

### Incorrect
- **Claim 36b** (`docs/working/questions.md:491`): "`git archive` in install.sh would honor either": a graft changes only parents, so it cannot change what `git archive <commit>` writes (executed). Only replace refs fit the reason. Refusing grafts stays harmless. Reword the parenthetical.

### Stale
- none

### Mostly Accurate
- **Claim 10** (`docs/dev-cycle.md:40-42`): the not-counted list omits capped briefs and held stalled loops, which step 8 excludes.
- **Claim 28** (`docs/working/questions.md:122`): Q-103 [2] omits the brief's own files, and "anything else falls to [1]'s entry" covers only path refusals (conflicts end stopped, environment refusals retry).
- **Claim 32** (`docs/working/questions.md:409`): Q-151's [2] remedy names only step 10. Step 8's queue count changes too.
- **Claim 38** (`docs/working/questions.md:498`): "If the paste refuses" explains only the `differs from M` refusal.
- **Claim 46** (commit b5eaedf6): "three override rows". The commit adds two.
- **Claim 47** (commit 659a1c61): lists api-consistency F5, whose fix (the plan note) is in b5eaedf6.
- **Claim 49** (commits 2846f9fa, 771a5d02, c63da94d): already recorded Won't-Fix (rows 829, 830). No action.

### Unverifiable
- none

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u5/docs/reviews/code-fact-check-report-2026-10-14-u5-final-rN.md (N as given at the end of this prompt), structured per the code-fact-check skill, first line `Commit: b5eaedf6`. Here N=3.
- Answered: yes. All 11 focus areas were checked. `--settings` was run on the branch's file and on main's file, each as written and with the policy flipped to self-merge, plus five more variants. The Q-156 paste was run across 11 cases in a throwaway clone without install.sh, and its lists were re-derived from git. The changed bats test, `questions.sh check`, `never_res` and git archive's graft and replace behavior were also run.
- Out of scope: the full bats suites and the health check; install.sh itself; the image copy's `--settings` (not run; this branch changes no parser, but the image runs C's script); per-sentence re-verification of every iteration-1 claim outside the focus list.
- Escalate: none blocking. Claim 36b is a wording error in a user-facing paste rationale with no safety effect (the check fails closed). The six actionable Mostly-accurate items are one-phrase fixes, two of them in immutable commit bodies.
- Decisions I made: read "run `--settings` on the file committed on `main`" as the branch's `docs/dev-cycle.md` committed on a throwaway repo's `main` (as the scripts read it), and ran main's own file too. Treated claim 49's known body defects as Mostly accurate rather than Verified, so the replicate verdicts stay honest, and marked them no-action. Did not log claim 46 in the hallucination log (a miscount, and this pass edits no tracked file).
- Questions I would have asked: whether the final pass should re-verdict defects already settled as Won't-Fix (claim 49) or skip them.
