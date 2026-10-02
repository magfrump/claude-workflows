Commit: cbfdf35 (A) / 77e21af (B)

# API Consistency Review — dev-cycle pass 25 (pass-24 fix round)

**Scope:** A: `git diff c1d0a80..cbfdf35 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree `wt-digest`). B: `git diff fb643e2..77e21af -- skills/dev-cycle/SKILL.md` (worktree `wt-devcycle`, merge 60fb513). Partial scope: only the pass-24 fix round is under review. The rest of each branch is context.
**Date:** 2026-10-02
**Based on:** `docs/reviews/code-fact-check-report-digest-pass24.md` (Stage-1 context, loop pass 24); the pass-24 rubric section of `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md`.

Every probe was a single `set -eu` script that made its own `mktemp -d` under `scratchpad/api25/` and checked `$PWD` before any write. Scripts were `p1.sh`–`p5.sh`. All commands ran under `timeout`. Both worktrees' `git status --short` were clean afterwards. Nothing of mine was still running when I reported. (The bats processes visible in `ps` belong to another session's full-suite run in `wt-devcycle`.) The 39 tests pass at cbfdf35, run on a `git archive` export with `TMPDIR` set to the temp dir.

## Baseline Conventions

The check modes' existing contract (precedent: `scripts/dev-cycle.sh:22-49` at c1d0a80, and `scripts/questions.sh`):

- **Output:** one line per argument. Each line is `ok <subject> [fields…]`, `absent <subject>`, a verdict token followed by `<subject>` (`--check-answer`), or `skip <subject>: <reason>`. Exit 0 whenever every argument got an answer. Fields are space-separated and positional.
- **Verdict tokens** are lowercase single words: `keep`, `drop`, `open`, `unrecognized`.
- **Skip reasons** are prose and name the rule that refused the input.
- **Question entry status** is read by `scripts/questions.sh parse_entries` (`scripts/questions.sh:171-181`), and only from the `**Needs:**` line's `Status:` field. The value is exact (`OPEN|ANSWERED`), and `check` rejects anything else.
- **The policy file-name set** used by the repo's guards: `{"claude.md", "agents.md", "claude.local.md"}` (`scripts/claude_config_audit.py:36`, `hooks/guard-trusted-writes.py:201`, `hooks/claude-config-audit.sh:83`).
- **The skill** (`skills/dev-cycle/SKILL.md`) restates each check's output shape in prose and acts only on those tokens.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `ok <path> new` | output shape | `ok <path>` (`--check-write`), `absent <name>` (`--check-branch`) | `scripts/dev-cycle.sh:26-39` | Consistent in shape. Its meaning is wider than the skill says: see Finding 6 |
| `ok <path> open\|done\|dropped <commit>` | output shape | `ok <name> <commit>` (`--check-branch`, c1d0a80) | `scripts/dev-cycle.sh:34` | Consistent: state, then commit, positional |
| `dropped` (state) / `drop` (answer) | verdict token | `keep`/`drop`/`open` | `scripts/dev-cycle.sh:44-47` | Consistent. The state is a past participle and the answer is the option, two separate domains. `done` serves as both, which is fine |
| `ok <name> <commit> <n>` | output shape | `ok <name> <commit>` | `scripts/dev-cycle.sh:34-39` | Consistent: a field appended at the end, so positional readers of the first three fields keep working |
| `done` (`--check-answer` option) | verdict token | `keep`, `drop` | `scripts/dev-cycle.sh:44-49`, `:308-321` | Consistent: `[3]`/`3`/`done` mirrors `[1]`/`1`/`keep` |
| `skip <p>: one of the cycle's own files (use --check-write)` | skip reason | `skip <p>: not one of the dev cycle's own files` | `scripts/dev-cycle.sh:241` | Consistent: it names the mode to use instead |
| `skip Q: an entry with this heading in both <f> and <g>` / `… more than one entry with this heading in <f>` | skip reason | the c1d0a80 combined reason | `scripts/dev-cycle.sh:360-361` | Consistent. Each now names its file(s), which fixes pass-24 Informational 10 |
| `skip <p>: no line that is exactly Status: open, done or dropped` | skip reason | other `skip` reasons | `scripts/dev-cycle.sh:258` | Consistent |
| `check_brief` (function) | function | `check_write`, `check_branch`, `check_fix` | `scripts/dev-cycle.sh:238-292` | Consistent: `check_<mode>` |
| `MAIN_BY_NAME` | variable | `MAIN`, `MAIN_SHA` | `scripts/dev-cycle.sh:369` | Consistent |
| `Status: dropped` (brief field) | brief schema | `Status: open`, `Status: done` | `skills/dev-cycle/SKILL.md:257-261, 303-306` | Consistent. It replaces the overloaded `closed` (pass-24 Minor 4) |
| `**[3] done**` (question option) | entry option | `**[1] keep**`, `**[2] drop**` | `skills/dev-cycle/SKILL.md:282-283` | Consistent. The slug `keep-or-drop-…` keeps its old name: Informational, below |

## Findings

#### 1. The ANSWERED test matches `**Status:** answered` anywhere in an entry, so one mention in an OPEN entry's prose makes its answer lines readable

**Severity:** Inconsistent
**Location:** `scripts/dev-cycle.sh:333` (cbfdf35)
**Move:** 1 (baseline), 3 (consumer contract)
**Confidence:** High on the mechanism. Low–Medium on likelihood.
**Legibility-target:** the `--check-answer` reader of `**Status:**` (the awk rule at line 333) and its header comment at `:296-297`.

Evidence (verbatim, the whole rule):
```
tolower($0) ~ /\*\*status:\*\* *answered/ { answered = 1 }
```
The header comment at `:296-297` says: "An entry whose "**Status:**" is not ANSWERED is open, whatever it contains". The precedent reads the field only from the `**Needs:**` header line, as one exact field value (`scripts/questions.sh:171-181`: `/^\*\*Needs:\*\*/ { … if (f[i] ~ /^Status:/) { status = substr(f[i], 9) } }`).

Probe `p4.sh` used an entry whose header is `**Status:** OPEN`, whose prose contains `(Q-150 was **Status:** ANSWERED earlier.)`, and which has the line `Q-200: [2]`. It printed `drop Q-200`. A control entry with the same header and no such mention printed `open Q-201`. The rule is unanchored, case-insensitive and prefix-matching. So any line in the entry can set `answered`, including a quoted header line from another entry (a "Original entry:" style quote that includes its `**Needs:**` line), and `ANSWERED-ish` would also count. That reopens, narrowly, the A3 class this round set out to close: lines in an entry that has not been answered are read as its answer. A quoted earlier `**Answered …: [n]**` line at line start, plus any `**Status:** answered` substring, is enough. No live entry triggers it today (`grep -i '\*\*status:\*\* *answered' docs/working/questions.md` is empty on /workspace), so this is a latent divergence from the questions.sh parse, not a current misread.

**Recommendation:** Set `answered` only on a line matching `^\*\*Needs:\*\*`, and only when its `Status:` field (split on ` · `, with `**` removed) is exactly `ANSWERED`, as `parse_entries` does. Add a test with an OPEN entry that mentions `**Status:** ANSWERED` in its prose.

#### 2. The Rules and In flight step 1 disagree on whether a `--check-brief` skip holds a slot

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:80-82` vs `:265` and `:296-299` (77e21af)
**Move:** 7 (asymmetry)
**Confidence:** High
**Legibility-target:** the dev-cycle skill's slot rule (Rules paragraph, In flight step 1, Build briefs).

Evidence (verbatim):
- Rules, `:80-82`: "a roadmap brief path counts as a brief (and holds a slot) only when that prints `open` or `new` and `--check-path` prints `ok`."
- In flight 1, `:265`: "A skip from `--check-brief` is recorded and the brief keeps its slot."
- Build briefs, `:296-299`: "while fewer than 3 briefs are open: the ones the Rules' glob lists plus any this cycle has written that it does not list yet (a new brief is untracked until it is staged), each counted once."

One sentence says a skip is not a brief and holds no slot, and another says it keeps its slot. Take a brief on the default branch whose status line is not exact, such as a legacy `Status: closed` or `Status: Done`. `--check-brief` prints `skip …: no line that is exactly Status: open, done or dropped`. The Rules would not count the brief, step 1 would, and Build briefs counts whatever the `briefs/*.md` glob lists, which includes it. So there are three slot definitions, and two of them agree. A cycle following the Rules writes a fourth brief, and one following step 1 or Build briefs does not.

**Recommendation:** Pick one rule. The step-1 and Build-briefs reading (a skip keeps its slot until it is resolved) is the conservative one. Rewrite the Rules sentence to say "holds a slot unless `--check-brief` prints `done` or `dropped`", and keep the "counts as a brief" condition only for being *treated* as one (read and written).

#### 3. The ANSWERED gate silently parks a user's one-line `Q-NNN: <answer>` until some session flips the status, and the cycle has no step that does

**Severity:** Inconsistent
**Location:** `scripts/dev-cycle.sh:296-297, 350` (cbfdf35); `skills/dev-cycle/SKILL.md:270, 278-286, 342-343` (77e21af)
**Move:** 3 (subtle breaking change: narrowed accepted input)
**Confidence:** Medium
**Legibility-target:** the keep-or-drop answer path, from the user's reply through `--check-answer` to the final message.

Evidence (verbatim):
- Script `:350`: `else if (count) print (!answered ? "open" : done ? result : "unrecognized")`
- Skill `:270`: "`open` is not answered yet: leave the ID."
- Skill `:278`: "Then, if the brief is still open and no ID on its `Asked:` line is still `open` or skipped, …"
- Skill `:342-343`: "list the new `you: judgment` entries by ID and name, any keep-or-drop answer step 6 could not read, and each open build brief by path"

The questions-doc contract in the global instructions says: "The user writes `Q-NNN: <answer>` anywhere … and the ID is the whole handle." At c1d0a80, `--check-answer` read that line in an OPEN entry. At cbfdf35 it prints `open` until `**Status:**` is flipped (probe `p4.sh`: `Q-201: [3]` under `**Status:** OPEN` → `open Q-201`). That narrowing is deliberate: it is the A3 fix. But no step of the cycle records answers or flips status. Step 3 covers only `trigger`, `deferred` and `agent` entries, and step 1's `questions.sh archive` moves entries that are already ANSWERED. An `open` ID blocks re-asking (`:278`), and the final message does not list it, because `open` is not "an answer step 6 could not read". So a user who answers in-file in the documented one-line form leaves the brief holding its slot with nothing printed. Real answers have so far been transcribed by a session (e.g. `**Answered 2026-09-20: [1].**`), which is why this is Medium and not Breaking.

**Recommendation:** Pick one, in a sentence. (a) Add to In flight step 2 or Watched questions: "an `open` keep-or-drop entry whose body has a line starting `Q-NNN:` is surfaced in the final message as 'answered in place, not recorded'". Or (b) state in the skill that keep-or-drop answers count only once recorded and ANSWERED, and list `open` keep-or-drop IDs older than one cycle in the final message.

#### 4. In flight step 1 names "the commit it prints" as the Done merge, but `--check-brief` prints the brief-branch commit, not the merge

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:257-258, 291`; `scripts/dev-cycle.sh:247-248, 256`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** the Done line's commit (In flight step 1, Done bullet, the `check_brief` comment).

Evidence (verbatim):
- Skill `:257-258`: "`--check-brief` prints `done` … → Done, naming the commit it prints."
- Skill `:291`: "**Done**: items finished since the last cycle, with the merge."
- Script `:247-248`: "The commit that last changed the file on the default branch is printed, so a Done entry can name it."
- Script `:256`: `c="$(git log -1 --format=%H "$MAIN_SHA" -- "$a")"`

Probe `p3.sh` set `Status: done` on `feat/foo` (commit `fc4f8a9…`) and merged with `--no-ff` (merge `c9123ff…`). The check then printed `ok docs/working/briefs/2026-10-01-foo.md done fc4f8a903888ea3a275c4e541e999e797b98c961`. History simplification drops the merge commit, which is TREESAME to its side parent, so the side commit is printed. For squash merges the two are the same commit. The help text ("the commit that last changed it there") is accurate. The skill's Done bullet ("with the merge") is not. If a later cycle commit on the default branch touches the brief before it is moved (an `Applied:` or `Kept:` line from a concurrent cycle), that commit is printed instead.

**Recommendation:** Change the Done bullet to "with the commit `--check-brief` printed (the change that set its status)". Or, if the merge is wanted, document that it is not what the check gives.

#### 5. `--check-fix`'s instruction-file set omits `claude.local.md`, which the repo's own policy-name set includes

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:279-280, 286-289`
**Move:** 2 (naming against the grain)
**Confidence:** High on the gap. Low on impact.
**Legibility-target:** `check_fix`'s basename list and its comment.

Precedent: `{"claude.md", "agents.md", "claude.local.md"}` used in `scripts/claude_config_audit.py:36`, `hooks/guard-trusted-writes.py:201`, `hooks/claude-config-audit.sh:83`

Evidence (verbatim, `:289`): `|| "$a" == docs/dev-cycle.md || "$a" == */.* || "$low" =~ ^(claude|agents|gemini|skill)\.md$ ]]; then`

Probe `p4.sh` gave `ok docs/CLAUDE.local.md`, `ok docs/AGENTS.override.md` and `ok docs/a/copilot-instructions.md`, all tracked. The other basename tests are correct and complete for what they list: `docs/a/CLAUDE.md` and `docs/a/Skill.md` are refused case-insensitively; `docs/.hidden/n.md` and `docs/x/.y.md` are refused by `*/.*`, because `*` crosses `/` in `[[ == ]]`; `docs/a.b.md` is allowed, correctly, since it contains no `/.`; `docs/decisions/log.md` and `docs/dev-cycle.md` are refused. The only gap against the repo's own guard set is `claude.local.md`. `AGENTS.override.md` (read by Codex per directory) is outside that precedent and is noted only.

**Recommendation:** Add `claude.local` to the alternation, and a row for it in the bats test.

#### 6. `ok <path> new` also means "moved away to `closed/`", and the skill reads it only as "before it has landed"

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:29-33, 254`; `skills/dev-cycle/SKILL.md:79-82, 302-303`
**Move:** 8 (nullability: an absent file has two causes)
**Confidence:** High on the behavior. Low on reach.
**Legibility-target:** the meaning of `new` in `--check-brief` help and in the skill's Rules.

Evidence (verbatim):
- Script `:254`: `if [[ "$(git cat-file -t "$MAIN_SHA:$a" 2>/dev/null || true)" != blob ]]; then echo "ok $a new"; return; fi`
- Skill `:80`: "or `ok <path> new` before it has landed"

Probe `p3.sh`: after the closing cycle's `git mv` landed on main, `--check-brief docs/working/briefs/2026-10-01-foo.md` printed `ok … new`. The skill handles the two cases where this matters. For name uniqueness, `--check-path` on the `closed/` twin catches it (`:302-303`). For a slot, `new` also needs `--check-path ok`, and that fails for a moved file. So no wrong action follows. But a stale In-flight line (a roadmap edit missed when the brief moved) gets `new` plus a `check-path` skip, and nothing in the skill says what that combination means. It falls under none of the step-1 cases.

**Recommendation:** Either print a distinct state when `MAIN_SHA:docs/working/briefs/closed/<name>` is a blob (for example `ok <path> closed <commit>`), or add one skill sentence: "`new` with a `--check-path` skip: the brief is not on either branch; record it and drop the line from In flight."

#### 7. With no `origin/HEAD`, `main` or `master`, `--check-brief` reads the cycle branch, not the default branch

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:382-388, 245-248`; `skills/dev-cycle/SKILL.md:79-80`
**Move:** 3 (contract under a fallback)
**Confidence:** High (narrow precondition)
**Legibility-target:** the help and skill wording "on the default branch".

Evidence (verbatim):
- Script `:383-386`: "# A repo on some other branch name: use the current branch." … `MAIN="$cur"; MAIN_SHA="$(git rev-parse --verify --quiet HEAD 2>/dev/null || true)"`
- Skill `:79-80`: "which reads its `Status:` line on the default branch"

The check modes run on `chore/dev-cycle-<date>` (Rules, "Its own branch"). In a repo whose default branch is, say, `trunk`, with no `origin/HEAD`, `MAIN_SHA` is the cycle branch's HEAD. Probe `p3.sh` (repo `r2`, default `trunk`, on `chore/dev-cycle-x`) printed `ok trunk ceb755b… 0` and `ok chore/dev-cycle-x ceb755b… 0`: neither is refused, and both count against the cycle branch. Once the cycle commits its own `Status: dropped` edit, or a brief it wrote, `--check-brief` reads those commits. That is the "never the working tree, only the default branch" property, weakened to "the cycle branch's last commit". The round made the branch refusal conditional on `MAIN_BY_NAME` but left the brief source unconditional, and the help does not mention the fallback for either. The installed copy serves any project, so a `trunk` or `develop` repo without a remote HEAD is plausible.

**Recommendation:** When `MAIN_BY_NAME` is empty, have `--check-brief` and `--check-branch` print a skip ("default branch not found by name"). Or state in the help that both then read the current branch.

#### 8. A squash-merged branch with a forgotten status line is never asked keep-or-drop-or-done

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:262-263, 274`; `skills/dev-cycle/SKILL.md:278-286`
**Move:** 3 (count semantics)
**Confidence:** High
**Legibility-target:** the `<n>` field's meaning and the "shows no work" rule.

Evidence (verbatim):
- Script `:262-263`: "The last field counts the branch's commits not on the default branch (0: no work yet)."
- Skill `:285-286`: "\"Shows no work\": `--check-branch` prints `absent`, skips the name (recorded), or prints `ok <name> <commit> 0`."

Probe `p3.sh` results:
- `feat/foo` before its merge: `ok feat/foo … 2`.
- After a `--no-ff` merge: `ok feat/foo … 0`. "No work yet" is wrong here, since the work is merged. The skill still behaves well: if the build forgot the status line, `[3] done` is offered.
- `feat/sq` after `merge --squash`: `ok feat/sq … 1`. This stays above 0 for as long as the branch exists.

So a squash or rebase merge that forgot the status line counts as "work" forever, keep-or-drop-or-done is never filed, and the brief holds a slot until someone deletes the branch. This is the case the new `[3] done` option was added for. Step 1's "a squash, a rebase or a deleted branch does not matter" is true of Done, but not of the outlet for a forgotten Done. The same rule also treats a branch with one stale commit from months ago as live.

**Recommendation:** Reword the `n` comment to "0: no commits beyond the default branch (none yet, or merged)". In the skill, base "shows no work" on the branch's last commit date: no commit in 14 days, where `--check-branch` would need to print the date. Or ask keep-or-drop-or-done on a fixed age regardless of `n`.

#### 9. A line-start `**Answer (…)**` written by an agent is read as the user's answer

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:338`
**Move:** 3
**Confidence:** High
**Legibility-target:** the label set in `--check-answer`'s comment (`:298-300`).

Evidence (verbatim, `:338`): `if (low !~ /^\*\*answer(:|ed| \()/) next`

Probe `p4.sh`: in an ANSWERED entry, the line `**Answer (agent recommendation): [1] keep**` comes before `**Answered 2026-10-02: [2].**`, and the probe printed `keep Q-202`. A mid-line `**Answer (agent default): [1]**` after `- **Interim:** keep.` was correctly ignored. `**Answer (` is the recording form some sessions use (Q-091–Q-095), so the rule is consistent with the data. The residual risk is an agent's own labelled line, which now needs an ANSWERED entry *and* a line-start position. That is narrow.

**Recommendation:** Optional: document in the skill's keep-or-drop entry text that only the recorded answer may use an `**Answer…**` label at line start.

#### 10. The question slug keeps `keep-or-drop-` while the question is now keep, drop or done

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:281-283`
**Move:** 2
**Confidence:** High
**Legibility-target:** the entry slug.

No existing precedent in `skills/dev-cycle/SKILL.md`, `scripts/dev-cycle.sh` and `docs/working/questions*.md`: no slug elsewhere encodes its option set. Severity downgraded one tier, to the floor.

Evidence (verbatim): "slug `keep-or-drop-<brief file name without .md>-<n>` … asking \"keep, drop or mark done <brief path>?\" with options **[1] keep**, **[2] drop** and **[3] done**"

Keeping the slug stable is defensible, because existing `Asked:` IDs and the `<n>` count read on. The script's comment already calls the rule "the keep-or-drop answer rule" (`:293`), while the help says "keep-or-drop-or-done question" (`:44`).

**Recommendation:** None required. Leave the slug as is, and if anything align the `:293` comment with the help.

### Checked and correct (no finding)

- **`--check-answer` on every real entry.** I ran 99 IDs from /workspace's `questions.md` and `questions-archive.md` through c1d0a80 and cbfdf35. Exactly six differ: Q-070, Q-071 and Q-073 go `keep` → `unrecognized` (their answers are mid-line); Q-019, Q-037 and Q-085 go `unrecognized` → `done`. Q-019's line is `**Answered …:** done, and I observed the result`; Q-037 and Q-085 are `[3]` answers to questions whose [3] is not "done". These are not keep-or-drop entries, so the corpus check is only a parser check. I printed the decisive line for every keep and drop result (`p2.sh`) and found no wrong keep or drop. The "Original entry:" quotes in Q-070, Q-071, Q-081 and Q-083 come after the recorded answer line and are never reached. Their table rows start with `|`, and their bullet labels (`- **Interim:**`) do not match.
- **Fence reset per entry** (`:328`, `fence = 0` on the heading) and fence handling only inside the entry: correct.
- **`--check-brief` reads only `MAIN_SHA`**, never the working tree (`p3.sh`). It gives `new` before landing, `open <c>` after, and `done <c>` after the build merge, and the cycle branch's `git mv` does not change it before landing. A closed/ path is skipped as "not an open build brief". GIT_LITERAL_PATHSPECS=1 is exported for the `git log` pathspec.
- **`--check-branch`** refuses `main` by name and still refuses `HEAD`. `absent` and `ok … <n>` are as documented.
- **Help range** `sed -n '2,58p'`: line 57 is the last comment line, 58 is blank and 59 is `set -euo pipefail`. Output ends with the Exit paragraph and one blank line, and nothing is cut off.
- **The skill's git commands with a brief's branch:** none remain. `<default-commit>` and the `git rev-list` line are gone. The commands left are `git branch --show-current`, `git worktree list/prune`, the merged-branch listing, `git mv` (source and destination checked) and named-path staging.
- **`briefs/closed/`** is created before the first `git mv` (`:262`). `Status: closed` no longer appears anywhere in the branch outside reviews.
- **The acceptance criterion** no longer contains the literal `Status: done` (`:305-306`), so `grep -m1 '^Status: …$'` cannot match criteria text.

## What Looks Good

- Every new output shape extends an existing one at the end of the line (`<n>`, the state and commit fields), so positional consumers of the earlier fields still work.
- The answer parser is simpler and stricter. There is one leading-token rule, no bracket fallback, labels only at line start, and fences reset per entry. On the real corpus it changes exactly the six intended entries.
- Brief state moved from a prose self-report into a tested check that reads committed default-branch content. That matches the user's direction that mechanical rules live in tested code.
- Each skip reason now names what to do (`use --check-write`, "file it instead") and names the files involved (duplicate headings).
- The skill restates each check's shape exactly as the help prints it (`ok <name> <commit> <n>`, `ok <path> open|done|dropped <commit>`, `ok <path> new`).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | ANSWERED detected anywhere in the entry, not from the `**Needs:**` field | Inconsistent | `scripts/dev-cycle.sh:333` | High (mechanism) / Low–Med (likelihood) |
| 2 | Rules vs In flight 1 / Build briefs: does a `--check-brief` skip hold a slot | Inconsistent | `skills/dev-cycle/SKILL.md:80-82, 265, 296-299` | High |
| 3 | In-place `Q-NNN:` answers stay `open` with no step recording them, and are not surfaced | Inconsistent | `scripts/dev-cycle.sh:350`; `skills/dev-cycle/SKILL.md:270, 278, 342-343` | Medium |
| 4 | Done "with the merge" but the check prints the side-branch commit | Minor | `skills/dev-cycle/SKILL.md:257-258, 291`; `scripts/dev-cycle.sh:256` | High |
| 5 | `claude.local.md` missing from the instruction-file set | Minor | `scripts/dev-cycle.sh:289` | High |
| 6 | `new` also means "moved to closed/"; stale In-flight line unhandled | Minor | `scripts/dev-cycle.sh:254`; `skills/dev-cycle/SKILL.md:80` | High / Low reach |
| 7 | Fallback default branch: `--check-brief` reads the cycle branch | Minor | `scripts/dev-cycle.sh:382-388` | High (narrow) |
| 8 | Squash-merged branch with forgotten status never asked; `n` comment says "no work yet" | Minor | `scripts/dev-cycle.sh:262-263`; `skills/dev-cycle/SKILL.md:285-286` | High |
| 9 | Line-start agent `**Answer (…)**` read as the answer | Informational | `scripts/dev-cycle.sh:338` | High |
| 10 | Slug stays `keep-or-drop-` | Informational | `skills/dev-cycle/SKILL.md:281` | High |

## Overall Assessment

The round's interface changes follow the check-mode conventions, and every new field and token extends an existing shape. The two pass-24 Incorrect fixes hold:
- **Worded answer flipped by a later bracket (A1):** a bracket no longer flips a worded answer.
- **`git mv` into a missing `briefs/closed/` (A2):** the directory is created first.

The two Medium fixes this review covers hold in their main path:
- **Answers read from unanswered entries (A3):** only ANSWERED entries and line-start labels are read.
- **Done as an unchecked self-report (A4):** brief state comes from committed default-branch content.

The A3 fix has one leak (Finding 1). Its ANSWERED test is looser than the questions.sh field parse it should match, and a one-line anchor to the `**Needs:**` line fixes it. Finding 2 is a direct contradiction in the skill's slot rule and needs one sentence. Finding 3 is the consumer-side cost of A3. The documented one-line answer form is now ignored until a session records it, and the cycle neither records nor reports such answers. Either outcome is defensible, but the skill should say which. Findings 4–8 are drift and edge gaps, each fixable in place with a sentence or a field. No finding breaks an existing consumer.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

Saved at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-02-digest-pass25.md`. Its first line is `Commit: cbfdf35 (A) / 77e21af (B)`. It follows the api-consistency-reviewer structure: header, Baseline Conventions, Name-Pattern Audit, Findings with Severity/Location/Evidence/Confidence/Legibility-target, What Looks Good, Summary Table and Overall Assessment. It covers the brief's named items:
- the check modes' interface, output shapes and help
- the skill text against what the checks print
- the brief lifecycle new → open → done/dropped → `closed/`, plus the roadmap line
- the keep/drop/done entry
- `--check-answer` against every real answer line

Not committed. The probe rule was followed, and nothing was written outside `scratchpad/api25/` except this file.
