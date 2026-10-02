Commit: d503a43 (A) / 1ae9b21 (B)

# Code Fact-Check Report

**Repository:** claude-workflows — A: `/workspace/.claude/wt-digest` (digest code at d503a43), B: `/workspace/.claude/wt-devcycle` (skill/docs content at 1ae9b21; HEAD 70df147 has identical content for the scoped files, checked with `git diff --quiet 1ae9b21 HEAD -- <files>`)
**Scope:** Partial, the pass-8 fix round only. A: `git diff ab8ec06..d503a43 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus commit message d503a43. B: `git diff cfe4b51..1ae9b21 -- skills/dev-cycle/SKILL.md docs/dev-cycle.md docs/working/questions.md` plus commit message 1ae9b21. Everything else on both branches is context only.
**Checked:** 2026-10-01
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 29
**Summary:** 15 verified, 10 mostly accurate, 0 stale, 3 incorrect, 1 unverifiable

Execution logs (scratch, not committed): `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc9/` holds `bats-A.log`, `probe1.sh` + `probe1.log`, `time1200.out` + `time1200.time`, `shellcheck.log`.

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read. No claim matches a logged pattern, and no new fabrication was found.

Legibility-target values: **agent** (the model running the skill or a build loop acts on the text), **maintainer** (someone editing the script or tests), **user** (the human answering Q-103 or reading the docs).

---

## Claim 1: "The skill counts the setting as made only when one line reads exactly `Build-loop policy: self-merge` or `Build-loop policy: review`; the interim marker above keeps it unset (so `review`) until Q-103 is answered."

**Location:** `docs/dev-cycle.md:12-14`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the skill's rule on the value set and the interim line; does not establish that the doc carries the skill's "exactly one", "outside code blocks", "both lines" and trailing-CR qualifiers.
**Legibility-target:** user

Both values and the interim outcome match. The skill's rule is narrower than this sentence: it requires "exactly one line, outside code blocks", ignores a trailing CR, and treats "both lines" as unset (`skills/dev-cycle/SKILL.md:55-58`: "set when the file has exactly one line, outside code blocks, reading exactly ... (a trailing CR is ignored) ... Unset (no file, no such line, both lines, or any other text ..."). "Only when one line reads exactly" can be read as "at least one line", which would accept both lines. That reading never matters in practice, because the skill text decides. The interim line `Build-loop policy: review (interim; Q-103)` (`docs/dev-cycle.md:7`) has extra text, so under the skill rule it is unset and the policy is `review`, as the doc says. **Wording.**

**Evidence:** `docs/dev-cycle.md:7`, `docs/dev-cycle.md:12-14`, `skills/dev-cycle/SKILL.md:54-59`

---

## Claim 2: "Plain paths only: the skill never reads through a symlink."

**Location:** `docs/dev-cycle.md:18-19`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the skill's stated rule for idea sources; does not establish that an agent following the skill performs the check (that is procedure, see Claim 11).
**Legibility-target:** user

The skill says: "The cycle reads and writes repo files (idea sources and their glob matches, ...) only by plain paths" (`skills/dev-cycle/SKILL.md:62-63`). The doc names reads only, which is the part that applies to idea sources.

**Evidence:** `docs/dev-cycle.md:18-19`, `skills/dev-cycle/SKILL.md:62-67`

---

## Claim 3: "afterwards the next cycle's health check, spot-check (2 sampled merges by default) and code-without-docs check might catch it"

**Location:** `docs/working/questions.md:56`
**Type:** Architectural / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of the three named checks and the default sample of 2; does not establish how likely they are to catch a bad change.
**Legibility-target:** user

The three checks exist. Step 1 is "run the repo's health check" (`skills/dev-cycle/SKILL.md:111`). The default sample is `SAMPLE=2` (`scripts/dev-cycle.sh:72`). Step 4 checks "every merge the digest lists under \"Merges with code but no docs\"" (`skills/dev-cycle/SKILL.md:154-155`).

**Evidence:** `docs/working/questions.md:56`, `scripts/dev-cycle.sh:72`, `skills/dev-cycle/SKILL.md:111,151-157`

---

## Claim 4: "the skill counts that line as unset (so `review`) and does not re-ask while this entry is open."

**Location:** `docs/working/questions.md:58`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the interim line's parse and the no-re-ask condition; does not establish behavior after Q-103 is archived without the line being edited.
**Legibility-target:** user

The skill treats "any other text such as `review (interim; Q-103)`" as unset, uses `review`, and files a question "unless an open `you: judgment` entry already asks for the setting" (`skills/dev-cycle/SKILL.md:57-59`). Q-103 is `**Needs:** you: judgment · ... **Status:** OPEN` (`docs/working/questions.md:46`).

**Evidence:** `docs/working/questions.md:46,58`, `skills/dev-cycle/SKILL.md:54-59`

---

## Claim 5: "replace that line with `Build-loop policy: self-merge` (or `review` for [1]) and drop the interim sentence below it in `docs/dev-cycle.md`."

**Location:** `docs/working/questions.md:59`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the replacement line; does not establish where the "interim sentence" boundary is.
**Legibility-target:** user

Replacing the line works under the exact-line rule (Claim 10). No standalone interim sentence exists, though. The interim text is the second clause of one sentence: "The skill counts the setting as made only when one line reads exactly ... ; the interim marker above keeps it unset (so `review`) until Q-103 is answered." (`docs/dev-cycle.md:12-14`). Dropping the whole sentence would also remove the exact-line statement. The precise instruction is "drop the clause after the semicolon". **Wording.**

**Evidence:** `docs/working/questions.md:59`, `docs/dev-cycle.md:12-14`

---

## Claim 6: "Every revisit trigger is printed every run (a printed line over 4096 bytes is cut)" / "a printed line over 4096 bytes is cut: read the record itself then"

**Location:** `scripts/dev-cycle.sh:16`, `scripts/dev-cycle.sh:151`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the cut measures; does not establish anything about lines under 4096 bytes.
**Legibility-target:** agent

The cut measures the line the body emits, including the `> ` prefix, before any byte is deleted:

```perl
# scripts/dev-cycle.sh:44-47
    my $nl = s/\n\z//;
    $_ = substr($_, 0, 4096) . " [line cut at 4096 bytes]" if length($_) > 4096;
    $_ .= "\n" if $nl;
    tr/\000-\010\013-\037\177//d;
```
(excerpt ends :47; the enclosing `scrub()` perl body continues to :56 with the sequence-deletion loop and `print`, all read.)

The cut runs before the control deletions. A line of more than 4096 emitted bytes whose control or bidi bytes would bring the printed text under 4096 is still cut. "A printed line over 4096 bytes" is therefore slightly imprecise. The header comment's own wording, "cuts lines longer than 4096 input bytes" (`:30`), is the precise one. The prefix part of the commit message ("the cut counts the printed line, prefix included") holds: `trig < "$f" | sed 's/^/> /'` (`:162`) feeds stdout, and stdout goes through scrub. **Wording.**

**Evidence:** `scripts/dev-cycle.sh:16,30,40-57,151,162`

---

## Claim 7: "A regular file reached without any symlink: its real path must be exactly the repo root plus the path as given, so a committed symlink (to the file or to a parent directory, pointing outside the checkout or into .git) is never read."

**Location:** `scripts/dev-cycle.sh:89-92`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the file-symlink and parent-directory-symlink cases, in-repo and out-of-repo, for every `inrepo` call site; does not establish behavior when ROOT_REAL is `/`, or for paths with `.`/`..` components (none are passed), or TOCTOU races.
**Legibility-target:** maintainer

```bash
# scripts/dev-cycle.sh:92
inrepo() { local r; [[ -f "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL/$1" ]]; }
```

`ROOT_REAL="$(pwd -P)"` comes after `cd "$ROOT"` (`:87-88`), and the right-hand side is quoted, so the comparison is literal. Every working-tree read is gated: the cycle-record glob (`:119`), decision records (`:155`), log (`:164`), questions (`:181`), roadmap (`:214,262`) and idea log (`:271`). Execution with `probe1.sh` gave these results. Case D, `docs/decisions` as a symlink to an in-repo directory: "D: dirlink skipped". Case E, `docs` itself as a symlink: all six inputs missing. Case F, symlinked `questions.md`, `idea-log.md`, `log.md` and cycle record: each skipped. Bats test 6 covers the file symlink to `.git` and to outside the repo.

Command: `timeout 120 bash .../fc9/probe1.sh > .../fc9/probe1.log 2>&1`. Cwd: `/workspace/.claude/wt-digest`. Exit: 0. Timestamp: 2026-10-01T21:46:39-07:00.

**Evidence:** `scripts/dev-cycle.sh:85-92,117-122,154-175,181,214,262,271`; `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc9/probe1.log`

---

## Claim 8: (brief item 1) `inrepo` "accepts every plain path the digest reads (cycle-record glob, decision records, log, questions, roadmap, idea log), including when the repo root itself sits under a symlinked directory or the script runs from a subdirectory"

**Location:** `scripts/dev-cycle.sh:92`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the six input kinds from the root, from a subdirectory, from a symlinked ancestor path, and from a subdirectory through that symlinked path; does not establish behavior when `GIT_WORK_TREE`/`GIT_DIR` force a logical toplevel, or for file names ending in a newline (command substitution strips it; such names cannot match the `.md` globs anyway).
**Legibility-target:** maintainer

`probe1.log` cases A (root), B (`sub/x`), C (`cd $T/link/repo`, where `link` is a symlink to `real`) and C2 (a subdirectory through the link) each print "present" for all six markers: PLAIN-RECORD, PLAIN-LOG, PLAIN-ROADMAP, "Ideas seeded since: 1", cycle-2026-01-02 and PLAIN-QUESTIONS. Under the symlinked ancestor, `git rev-parse --show-toplevel` printed the physical path (`/tmp/tmp.vFShV0IpkZ/real/repo`). Even with a logical toplevel, `pwd -P` (`:88`) would make the comparison physical. Bats 20/20 pass (`bats-A.log`, exit 0, 2026-10-01T21:46:18-07:00, cwd `/workspace/.claude/wt-digest`, command `timeout 300 bats test/scripts/dev-cycle.bats`), including test 13 "runs from a subdirectory with a relative script path".

**Evidence:** `scripts/dev-cycle.sh:86-92`; `.../fc9/probe1.log`; `.../fc9/bats-A.log`

---

## Claim 9: Absence messages for skipped inputs: "No docs/roadmap.md yet — create it this cycle", "No docs/working/questions.md (or questions.sh) in this repo.", "- No $LOG: no ideas seeded ...", "no cycle record found ..."

**Location:** `scripts/dev-cycle.sh:129,200,220,285`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what these lines print when the input is a symlink (now true for in-repo symlinks as well); does not establish how often committed symlinks occur.
**Legibility-target:** agent

Since d503a43, an in-repo symlink also fails `inrepo`. The fallback branch then claims the file is absent. In `probe1.log` case F, a symlinked `questions.md` printed "No docs/working/questions.md (or questions.sh) in this repo." and a symlinked idea log printed "- No docs/working/idea-log.md: no ideas seeded, no brainstorm recorded". The symlinked cycle record produced "no cycle record found, so the default of 14 days (the previous cycle, if any, did not write its record)". The conclusion holds: nothing was read. The stated reason is wrong for a present-but-skipped file, and the roadmap line tells the agent to "create it" when the path is already taken. The skill's step 0 likewise says to run `questions.sh init` when the digest reports no questions.md (`skills/dev-cycle/SKILL.md:98-99`). The skill's own `## Skipped paths` record section does not receive these skips from the digest. **Wording** (edge case: needs a committed symlink at one of these paths).

**Evidence:** `scripts/dev-cycle.sh:123-130,181,199-201,214-221,270-286`; `.../fc9/probe1.log` (case F lines)

---

## Claim 10: Build-loop policy is "set when the file has exactly one line, outside code blocks, reading exactly `Build-loop policy: self-merge` or `Build-loop policy: review` (a trailing CR is ignored). Set: use that value. Unset (no file, no such line, both lines, or any other text ...): use `review`, and unless an open `you: judgment` entry already asks for the setting, file one."

**Location:** `skills/dev-cycle/SKILL.md:54-59`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers completeness and fail-safety of the rule as text: every case not matching exactly one exact line resolves to `review`, and a deliberate `review` no longer re-asks. Does not establish that an agent applies it correctly. It also does not establish handling of a line hidden in an HTML comment (that line counts as set, since only code blocks are excluded) or two identical `self-merge` lines (unset by "exactly one", which is fail-safe).
**Legibility-target:** agent

Each failure mode (missing, duplicated, conflicting, decorated, inside a fence) falls to "Unset → `review`", the fail-safe value. A set `review` takes the "Set: use that value" branch, so the pass-8 R1 re-ask loop is closed. The repo's own `docs/dev-cycle.md:7` is unset by the "any other text" clause, as intended. (paraphrased — no quote available because the claim concerns the absence of an unhandled case across the rule's enumerated branches.)

**Evidence:** `skills/dev-cycle/SKILL.md:54-59`, `docs/dev-cycle.md:7`

---

## Claim 11: "before each read or write, check that no part of the path below the repo root is a symlink (`test -L` on each component; a file not yet created is checked through its directories). A path that fails is skipped and listed in the record under `## Skipped paths`. The digest applies the same rule to everything it reads."

**Location:** `skills/dev-cycle/SKILL.md:62-67`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the procedure is runnable with `test -L`, that the record template has the section, and that the digest's `inrepo` is equivalent for the normalized relative paths it passes. Does not establish that `scripts/questions.sh` (run by the cycle in step 1) refuses an in-repo symlinked ancestor on write: its header says ancestors are caught only by the "never land outside the git toplevel" check (`scripts/questions.sh:47-50`). The agent's own `test -L` check must cover that.
**Legibility-target:** agent

The procedure needs only `test -L` per component, which is an ordinary tool. The template carries `## Skipped paths` (`SKILL.md:269`). The digest-side equivalence was executed in Claims 7 and 8 (`probe1.log`). Through the digest, `questions.sh open` reads only the live file's contents. `cmd_open` calls `require_files` (a `-f` test on both files) and then `parse_entries "$LIVE"` (`scripts/questions.sh:408-414`), so the archive is existence-tested, not read.

**Evidence:** `skills/dev-cycle/SKILL.md:62-67,269`; `scripts/questions.sh:47-50,132-138,408-414`; `.../fc9/probe1.log`

---

## Claim 12: "The digest prints every trigger in full (a printed line over 4096 bytes is cut; read the record itself then)."

**Location:** `skills/dev-cycle/SKILL.md:128-129`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Same as Claim 6; covers the cut's measure only.
**Legibility-target:** agent

Same imprecision as Claim 6. The cut counts emitted bytes before control and bidi removal (`scripts/dev-cycle.sh:45-47`, quoted in Claim 6), not the printed length. **Wording.**

**Evidence:** `skills/dev-cycle/SKILL.md:128`, `scripts/dev-cycle.sh:44-47`

---

## Claim 13a: In flight's outcomes are exhaustive and cannot loop: stays / merged → Done / "ended any other way ... → Ideas"; "An item that came back from a build loop returns to Now only when the user puts it there"

**Location:** `skills/dev-cycle/SKILL.md:213-224`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers exhaustiveness (a catch-all third branch) and the absence of an automatic Ideas→Now or In-flight→Now path. Does not establish that the catch-all routes every case sensibly (Claim 13c) or that the branches are disjoint (Claim 13b).
**Legibility-target:** agent

"ended any other way (...) → Ideas" is a catch-all, so every state has an outcome. The handoff queue draws only from Now (`SKILL.md:233`: "Take the Now items whose first step needs no open choice"). A returned item reaches Now only "when the user puts it there" (`:222-224`), so no cycle can re-queue it on its own.

**Evidence:** `skills/dev-cycle/SKILL.md:212-224,233-235`

---

## Claim 13b: "running, or finished and waiting on the user's merge decision ... → stays, however long" vs "still building with no commit on its branch for 7 days → Ideas"

**Location:** `skills/dev-cycle/SKILL.md:215-220`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the disjointness of the "stays" and "stalled" branches; does not establish how an agent decides that a loop is "running".
**Legibility-target:** agent

A loop "still building with no commit on its branch for 7 days" is also "running" under the plain reading. The first bullet says it "stays, however long", and the third sends it to Ideas. The branches are disjoint only if "running" is read as "with a commit in the last 7 days". The precise version is "running (a commit on its branch within 7 days)". **Wording** (the third bullet's specificity resolves it for most readers).

**Evidence:** `skills/dev-cycle/SKILL.md:215-220`

---

## Claim 13c: "finished and waiting on the user's merge decision (an open PR or an open `merge <branch>?` entry) → stays"; "ended any other way ... → Ideas ...". "Either way out, its brief gets `Status: closed`."

**Location:** `skills/dev-cycle/SKILL.md:215-222`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the review-policy case where the user has approved a merge (entry answered yes, or PR approved) but the branch is not yet merged when the next cycle runs. Does not establish who is meant to perform an approved merge. Nothing in the skill says, and that absence is the defect.
**Legibility-target:** agent

Under `review` in a repo with no PRs, the loop "files one `you: judgment` entry, \"merge <branch>?\"" and stops (`SKILL.md:296-298`). Once the user answers yes, the entry is no longer open: step 1 runs `questions.sh archive` (`SKILL.md:115-116`), and the In-flight check already allows for "answers to its entries may already be in `questions-archive.md`" (`:214`). The item is now neither merged nor waiting on an open entry, so it falls to "ended any other way → Ideas", and its brief is closed. Nothing in the skill performs the approved merge. An agent following the rule demotes approved work to Ideas and closes its brief, and only the user can bring it back (`:222-224`). The stays branch should also cover "approved, merge pending", or the skill should name who merges after a yes. **Behavioral (procedure).** Preconditions: `review` policy, an approval recorded in the questions file (or a PR approved but not merged), and a cycle between the approval and the merge.

**Evidence:** `skills/dev-cycle/SKILL.md:115-116,213-224,295-298`

---

## Claim 14: "`Status: open` and `Policy: self-merge` or `Policy: review` (the setting's value now)"

**Location:** `skills/dev-cycle/SKILL.md:239`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency between line 239 and line 247; does not establish anything about 6b.
**Legibility-target:** agent

Eight lines later the same list says that under self-merge, work touching instruction files or `skills/`, `workflows/` or `scripts/` "gets `Policy: review`" (`SKILL.md:245-247`). So the `Policy:` line is not always "the setting's value now". The precise version is "the setting's value now, or `review` when Paths needs a self-merge exclusion". The direction is fail-safe. **Wording.**

**Evidence:** `skills/dev-cycle/SKILL.md:239,242-247`

---

## Claim 15: "**Paths**: the files and directories the work may change. Changing anything else is a stop condition. The list never includes ... the roadmap, the questions files, ... ; work that needs one of them is not handed to a loop."

**Location:** `skills/dev-cycle/SKILL.md:242-245`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the conflict between this rule and the filings 6b requires of every loop; does not establish where the skill means a loop's question entries to be committed, because it never says.
**Legibility-target:** agent

The skill requires every loop to change a questions file, and those files are never in Paths. Under `review` with no PRs (this repo, per Q-103 [1] "no PRs here", `docs/working/questions.md:55`), the loop "files one `you: judgment` entry, \"merge <branch>?\"" (`SKILL.md:296-298`). Any loop that hits a stop condition "files a `you: judgment` entry" (`:300-301`). Entries live in `docs/working/questions.md`, and the global instructions have autonomous runs append questions there too. That file is a "questions file" that "the list never includes", and "Changing anything else is a stop condition". Read literally, filing the merge entry is itself a stop condition whose handling is to file another entry. Every review-policy item in this repo needs a questions file, yet "work that needs one of them is not handed to a loop". The rule is self-defeating unless the filings are exempted, for example "the loop's own question entries, filed on the default branch, are not work". The same gap applies, more mildly, to the RPI and pr-prep artifacts a loop always writes (`docs/working/` plans, `docs/reviews/` reports). Those are not excluded, but the brief author must remember to list them. **Behavioral (procedure).** Preconditions: any build loop under `review` in a no-PR repo, or any loop that hits a stop condition.

**Evidence:** `skills/dev-cycle/SKILL.md:242-248,295-301`; `docs/working/questions.md:55`

---

## Claim 16: "With `Policy: self-merge` it also never includes what later runs follow unreviewed: instruction files (`CLAUDE.md`, `AGENTS.md`) and anything under `skills/`, `workflows/` or `scripts/`"

**Location:** `skills/dev-cycle/SKILL.md:245-247`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether the enumeration matches what later runs in this repo follow or execute; does not establish exploitability or whether a brief author would list these paths.
**Legibility-target:** agent

The enumeration is presented as the definition of "what later runs follow unreviewed", but it leaves out several things later runs do follow or execute:
- **`test/`**: the cycle's first step runs the health check (`SKILL.md:110-112`), which runs the whole test tree (`scripts/health-check.sh:301`: `for skill_dir in "$REPO_ROOT"/test/skills/*/; do`, and `:351-352` on the ~40 suites under `test/` and `test/scripts/`). The Rules also authorize "tests that exist in the repo's test tree" (`SKILL.md:23`). A self-merged test file is executed, unreviewed, by the next cycle.
- **`guides/`**: 39 files under `skills/` and `workflows/` point at it (`grep -rln 'guides/' skills workflows | wc -l` → 39, run in `/workspace/.claude/wt-devcycle`), for example `SKILL.md:7` "On bad output, see guides/skill-recovery.md".
- **`GEMINI.md`** (repo root) and **`global-instructions/CLAUDE.md`**: the parenthetical names only `CLAUDE.md` and `AGENTS.md`. The latter file is caught by name; `GEMINI.md` is caught only if the parenthetical is read as examples.

The precise version adds `test/` and `guides/` (and names `GEMINI.md`), or states the rule as "anything a later run executes or reads as instructions". **Behavioral.** Preconditions: the user answers Q-103 with self-merge (currently interim `review`), and a brief lists `test/` or `guides/` in Paths.

**Evidence:** `skills/dev-cycle/SKILL.md:7,23,110-112,245-247`; `scripts/health-check.sh:301,351-352`; repo root listing (`GEMINI.md`, `global-instructions/CLAUDE.md`, `guides/`, `test/`)

---

## Claim 17: "## Skipped paths" record section; final message lists "every open PR a build loop opened"

**Location:** `skills/dev-cycle/SKILL.md:269`, `skills/dev-cycle/SKILL.md:304-306`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency with the rules that reference them (`:66`, `:296-297`); does not establish anything about runtime.
**Legibility-target:** agent

`:66` says skipped paths are "listed in the record under `## Skipped paths`", and the template has `## Skipped paths` at `:269`. The review branch "opens a PR where the project uses them" (`:296-297`), and the final message now lists those PRs.

**Evidence:** `skills/dev-cycle/SKILL.md:66,269,296-297,304-306`

---

## Claim 18: "What happens at the end follows the stricter of two values: the brief's `Policy:` line as landed (anything but `self-merge` counts as `review`) and the build-loop policy in the default branch's `docs/dev-cycle.md` at the moment the loop would merge. A loop cannot raise its own policy, and the user can lower it for loops already running"

**Location:** `skills/dev-cycle/SKILL.md:290-293`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers fail-safety of the combination: `self-merge` requires both values to be `self-merge`, and a loop's Paths can never include `docs/dev-cycle.md` or `docs/working/handoffs/`. Does not establish that the loop applies the never-through-symlink rule when it reads `docs/dev-cycle.md` (the brief is not told to carry that rule), and does not establish what "raise" and "lower" mean beyond context.
**Legibility-target:** agent

Missing, unparsable or decorated values become `review` on both sides (`:291`, and Claim 10). The setting is read from the default branch at merge time, so a user edit to `review` takes effect for running loops. The loop cannot edit the setting or its brief: "The list never includes ... `docs/dev-cycle.md` or `docs/working/handoffs/`" (`:243-244`), and it reads its brief "from that commit" (`:288`). (paraphrased — no quote available because fail-safety is inferred across four separate passages.)

**Evidence:** `skills/dev-cycle/SKILL.md:54-59,239,243-244,286-293`

---

## Claim 19a: "... against about 1 s with the resume."

**Location:** `test/scripts/dev-cycle.bats:110-111`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the current code's time on the test's 1200-line input on this host; does not establish the old code's time.
**Legibility-target:** maintainer

I rebuilt the test's input with the same perl command (1200 lines of 1300×`\xC2` + 1300×`\x9B`) and ran the digest. It took `1.056 total`, exit 0, and all 1200 lines scrubbed to `> if .`.

Command: `time timeout 30 bash /workspace/.claude/wt-digest/scripts/dev-cycle.sh` in a `mktemp -d` repo. Exit: 0. Timestamp: 2026-10-01T21:48:53-07:00.

**Evidence:** `test/scripts/dev-cycle.bats:110-113`; `.../fc9/time1200.time`; `.../fc9/time1200.out`

---

## Claim 19b: "restarting each line per layer took ~35 s on the authoring host for these 1200 lines"

**Location:** `test/scripts/dev-cycle.bats:110-111`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing beyond the claim's self-scoping to "the authoring host"; does not establish the old algorithm's time here.
**Legibility-target:** maintainer

This is a measurement on a named other host, of code no longer in the tree. Verifying it needs the pre-resume scrub (from before the resume change) timed on the same input. I did not run that here.

**Evidence:** `test/scripts/dev-cycle.bats:110-111`

---

## Claim 20: Test title "no input is read through a symlink, inside or outside the repo"

**Location:** `test/scripts/dev-cycle.bats:126`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which inputs the test exercises; does not establish anything about the inputs it omits (my probe covered those; see Claim 7).
**Legibility-target:** maintainer

The test plants symlinks only at two decision records and at `docs/roadmap.md` (`:130-133`). It does not cover the log, questions, idea log, cycle record or a symlinked parent directory, so "no input" is broader than what the test proves. The behavior itself holds for all of these (`probe1.log` cases D–F). The precise title is "decision records and the roadmap are not read through a symlink ...". **Wording.**

**Evidence:** `test/scripts/dev-cycle.bats:126-138`; `.../fc9/probe1.log`

---

## Claim 21: "An in-repo symlink (here into .git) is skipped too."

**Location:** `test/scripts/dev-cycle.bats:132`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the decision-record symlink into `.git`; does not establish other in-repo targets (covered by probe case D).
**Legibility-target:** maintainer

`ln -s ../../.git/x.md docs/decisions/003-git.md` (`:134`) resolves to `$ROOT_REAL/.git/x.md`. The pre-fix test `[[ "$r" == "$ROOT_REAL"/* ]]` (diff `-` line) would have accepted it, and the new exact-match test rejects it. Test 6 passes (`bats-A.log`, `ok 6`), with no `SECRET` in the output.

**Evidence:** `test/scripts/dev-cycle.bats:132-137`; `scripts/dev-cycle.sh:92`; `.../fc9/bats-A.log`

---

## Claim 22: "Heading case and suffixes do not hide items."

**Location:** `test/scripts/dev-cycle.bats:316`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers section 7's counts for `## Now (current)` (suffix with a space) and `## In Flight` (case); does not establish the `## now(` no-space suffix form.
**Legibility-target:** maintainer

The input is `'## Now (current)\r\n- a\r\n\r\n## In Flight\r\n- b\r\n- c'` (`:317`). The asserts "Roadmap Now: 1 item(s)" and "Roadmap In flight: 2 item(s)" (`:325`) pass (`bats-A.log`, `ok 20`).

**Evidence:** `test/scripts/dev-cycle.bats:316-327`; `scripts/dev-cycle.sh:264`; `.../fc9/bats-A.log`

---

## Claim 23: "Section 5 uses the same heading rule (CRLF, case, suffix; \"## Nextgen\" is not Next)."

**Location:** `test/scripts/dev-cycle.bats:320`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which parts of section 5's rule the test exercises; does not establish anything about section 5's code, which does handle suffixes (`scripts/dev-cycle.sh:218`).
**Legibility-target:** maintainer

After d503a43 the Next heading is a bare `## Next\r\n` (`:317`; diff: `-## Next (ranked)` → `+## Next`). Section 5 is now tested for CRLF, case (capital N), and the `## Nextgen` exclusion, but no longer for a suffix. The code's suffix branch (`index(t, "## next ") == 1 || index(t, "## next(") == 1`, `scripts/dev-cycle.sh:218`) is exercised only by section 7's `Now (current)`, which is a different awk. The precise comment drops "suffix" for section 5. **Wording** (test coverage).

**Evidence:** `test/scripts/dev-cycle.bats:317-322`; `scripts/dev-cycle.sh:218`

---

## Claim 24: Commit d503a43: "Test 6 adds an in-repo symlink into .git"; "Test 20's roadmap puts the CRLF on a bare \"## Next\" heading (section 5 previously matched through the suffix) and the suffix case on Now."; "20/20; shellcheck clean."

**Location:** commit `d503a43` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these three statements; the inrepo and printed-line statements are verdicted in Claims 7 and 6, and the timing statement in Claims 19a/19b.
**Legibility-target:** maintainer

The diff matches both test descriptions (`test/scripts/dev-cycle.bats:132-134,317`). The old heading `## Next (ranked)` was matched by `index(t, "## next ") == 1` (`scripts/dev-cycle.sh:218`). The tests ran with `timeout 300 bats test/scripts/dev-cycle.bats`: 20 `ok`, exit 0, at 2026-10-01T21:46:18-07:00. Shellcheck ran with `timeout 60 shellcheck scripts/dev-cycle.sh`: exit 0, 0-byte output, at 2026-10-01T21:49:04-07:00. Both ran in cwd `/workspace/.claude/wt-digest`.

**Evidence:** `test/scripts/dev-cycle.bats:132-134,317`; `scripts/dev-cycle.sh:218`; `.../fc9/bats-A.log`; `.../fc9/shellcheck.log`

---

## Claim 25a: Commit 1ae9b21: "a deliberate `review` is no longer re-asked"; "Matches the digest's stricter inrepo() (d503a43)"; "A returned item re-enters Now only by the user. Answers may be in the archive."

**Location:** commit `1ae9b21` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers these statements against the landed text; the In-flight and Paths defects are in Claims 13c, 15 and 16.
**Legibility-target:** maintainer

All three statements match the landed text. "Set: use that value" (`SKILL.md:57`) stops the re-ask. The per-component `test -L` rule (`:64-65`) is equivalent to `realpath == ROOT_REAL/path` for the relative paths the digest passes (Claim 7). The returned-item and archive statements are at `:214` and `:222-224`.

**Evidence:** `skills/dev-cycle/SKILL.md:57,62-67,214,222-224`; `scripts/dev-cycle.sh:92`

---

## Claim 25b: Commit 1ae9b21: "docs/dev-cycle.md states the exact-line rule."

**Location:** commit `1ae9b21` message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Same as Claim 1.
**Legibility-target:** maintainer

The doc states the exact-value part but not "exactly one", code blocks, both lines, or CR (`docs/dev-cycle.md:12-14`, quoted in Claim 1). **Wording.**

**Evidence:** `docs/dev-cycle.md:12-14`, `skills/dev-cycle/SKILL.md:54-59`

---

## Claims Requiring Attention

### Incorrect
- **Claim 13c** (`skills/dev-cycle/SKILL.md:215-222`): **behavioral.** An approved but not yet merged review-policy item (entry answered yes and archived) matches no "stays" condition, so it goes to Ideas and its brief is closed. No step performs the approved merge.
- **Claim 15** (`skills/dev-cycle/SKILL.md:242-245`): **behavioral.** Paths never includes the questions files, and changing anything outside Paths is a stop condition. Yet 6b requires every review-policy loop in a no-PR repo, and every stopped loop, to file a `you: judgment` entry in `docs/working/questions.md`. Exempt the loop's own entries, and say on which branch they land.
- **Claim 16** (`skills/dev-cycle/SKILL.md:245-247`): **behavioral.** The "what later runs follow unreviewed" list omits `test/` (executed by the next cycle's health check), `guides/` (followed via 39 skill and workflow pointers) and `GEMINI.md`.

### Stale
- None.

### Mostly Accurate
- **Claim 1** (`docs/dev-cycle.md:12-14`): wording. It omits "exactly one", code blocks, both lines and CR.
- **Claim 5** (`docs/working/questions.md:59`): wording. The "interim sentence" is a clause of the exact-line sentence.
- **Claim 6** (`scripts/dev-cycle.sh:16,151`): wording. The cut counts emitted bytes before control removal, not the printed length.
- **Claim 9** (`scripts/dev-cycle.sh:129,200,220,285`): wording. A symlinked input is reported as absent ("create it", "no cycle record found").
- **Claim 12** (`skills/dev-cycle/SKILL.md:128`): wording. Same as Claim 6.
- **Claim 13b** (`skills/dev-cycle/SKILL.md:215-220`): wording. "running" overlaps "still building with no commit for 7 days".
- **Claim 14** (`skills/dev-cycle/SKILL.md:239`): wording. `Policy:` is not always "the setting's value now" (see :247).
- **Claim 20** (`test/scripts/dev-cycle.bats:126`): wording. The title says "no input", but the test covers records and the roadmap only.
- **Claim 23** (`test/scripts/dev-cycle.bats:320`): wording. Section 5's suffix case is no longer exercised.
- **Claim 25b** (commit 1ae9b21): wording. Same as Claim 1.

### Unverifiable
- **Claim 19b** (`test/scripts/dev-cycle.bats:110-111`): the ~35 s needs the pre-resume scrub timed on the same input.

Rules checked and found correct and complete: the policy parse (Claim 10), stricter-of-two fail-safety (Claim 18), the In-flight catch-all and no-loop property (Claim 13a), and digest `inrepo` acceptance and rejection across all six input kinds, a symlinked root and a subdirectory (Claims 7, 8).

---

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass9.md` (the path the role instructions give), first line `Commit: d503a43 (A) / 1ae9b21 (B)`, with the `**Replication:** k=1 (loop pass, decision 031)` header field and the code-fact-check structure: header fields, seven mandatory per-claim fields plus Legibility-target, Claims Requiring Attention. It serves the loop's goal (reach a clean pass) by naming three behavioral defects in 1ae9b21's new rules (Claims 13c, 15, 16) that keep this delta pass from being clean. The digest half (A) has no behavioral finding.
