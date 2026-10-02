Commit: ba39470 (A) / 36ca12c (B)

# API Consistency Review: dev-cycle pass 23 (pass-22 fix round)

**Scope:** Partial, the pass-22 fix round only. A: `git diff bc98571..ba39470 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree `/workspace/.claude/wt-digest`; HEAD ca8ba77 adds review docs only, `git diff --stat ba39470 HEAD -- scripts test` is empty). B: `git diff 6c8ae91..36ca12c -- skills/dev-cycle/SKILL.md docs/dev-cycle.md` (worktree `/workspace/.claude/wt-devcycle`; HEAD f2843cd merges A in, no further change to the skill or settings doc). Consumer side: the six check modes' interface, output shapes and `--help`; the skill's instructions against what the modes print; `docs/dev-cycle.md`; `--check-answer` against the archive's real answer lines. Everything else is context.
**Date:** 2026-10-02
**Based on:** `docs/reviews/code-fact-check-report-digest-pass22.md` (Stage-1 context, the pass-21 round) and `docs/reviews/api-consistency-review-2026-10-02-digest-pass22.md` (findings this round addresses).

Probes (scratch `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/api23/`): each probe one `set -eu` script that made and entered its own `mktemp -d` dir and checked `$PWD` before any write or `git init`; every process under `timeout`, none outlived its command (the bats processes visible afterwards belong to another session's `wt-devcycle` suite run, not to these probes). `p1.sh`: `--check-answer` over every heading ID in the `wt-devcycle` questions files. `p2.sh`: the same awk program with a debug `END` printing the deciding line, over `main`'s questions files (`git show`, read-only). `p3.sh`: a throwaway repo exercising all new shapes. `p4.sh`: `bats test/scripts/dev-cycle.bats` 33/33 ok, `shellcheck scripts/dev-cycle.sh` clean. Only awk here is mawk 1.3.4 (`/usr/bin/awk -> mawk`; `nawk` is the same alternative); gawk is not installed, so gawk portability is by reading. Nothing was written to either worktree except this file.

Legibility-target values: **agent** (the model running the skill acts on the text), **maintainer** (someone editing the script, skill or tests), **user** (the human answering questions or reading the record).

## Baseline Conventions

- **Check-mode shape** (`scripts/dev-cycle.sh:9-14`, `:107-110`, `:298-310`): `--check-<x> ARG...`, at least one argument (`<mode> needs at least one argument`, exit 1), one line per argument (per match for `--check-path`), exit 0 when every argument was answered. Status token first, subject second: `ok <value>` / `skip <value>: <reason>`. `ok` means "the consumer may use this value" (open it, write it).
- **Skip reasons** are lower-case noun phrases after `skip <value>: `; each names the rule that failed (`not an allowed path form`, `a directory, not a file`, `not a build brief (…)`).
- **Handlers** `check_<mode>`, predicates run-together lower-case (`rawfile`, `inrepo`, `isbrief`, `writable`), upper-case globals (`NAMECHARS`, `DIGIT`, `MAIN_SHA`).
- **The skill** invokes each check as `~/.claude/scripts/dev-cycle.sh --check-<x> '<value>'` (inside claude-workflows, `scripts/dev-cycle.sh`) and acts only on `ok` (`SKILL.md:61-81`).
- **Answer recording in the archive** (`wt-devcycle` `docs/working/questions-archive.md`, 89 entries): a separate bold label line `**Answered <date>[ (<source>)| , run 3]: …**` (bulk), `**ANSWERED …**` (1), `**Answer (<date>[, <source>]): …**` (every answer since 2026-09-28), and, for 12 entries from 2026-09-12 to 2026-09-27, the bold answer **appended to the question line itself** (`:108`, `:117`, `:126`, `:153`, `:162`, `:198`, `:1373`, `:1393`, `:1412`, `:1432`, `:1452`, `:1470`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--check-fix` | CLI flag | `--check-write`, `--check-brief`, `--check-path` | `scripts/dev-cycle.sh:9-12` | Consistent: `--check-<x>`, same arity and exit contract |
| `--check-answer` | CLI flag | `--check-branch`, `--check-path` | `scripts/dev-cycle.sh:9-13` | Consistent flag; output vocabulary differs (below) |
| `check_fix`, `check_answer` | function | `check_path`, `check_write`, `check_branch` | `scripts/dev-cycle.sh:199,225,236` | Consistent |
| `ANSWER_AWK`, `option()` | constant / awk function | `NAMECHARS`, `DIGIT`; `trig()` | `scripts/dev-cycle.sh:172,219,390` | Consistent (upper-case global holding a program; small lower-case helper) |
| `keep\|drop\|open\|unrecognized Q-NNN` | output line | `ok <path>` / `skip <x>: <reason>` | `scripts/dev-cycle.sh:208-213` | Consistent order (token, subject); new token set instead of `ok`. Acceptable: four outcomes do not fit ok/skip, and `skip` is still used for unusable input. Informational, no finding |
| `ok <name> <hash>` / `ok <name> absent` | output line | `ok <path>` | `scripts/dev-cycle.sh:208` | Third field is new and fine for a hash; `absent` in the hash slot under `ok` is Finding 6 |
| `skip …: in-cycle fixes edit only docs/ and README.md; file it instead` | output reason | `skip …: not one of the dev cycle's own files` | `scripts/dev-cycle.sh:229` | Consistent; the only reason that also says what to do, which helps |
| `skip …: not a question ID (Q- and digits)` | output reason | `skip …: not a build brief (docs/working/briefs/…)` | `scripts/dev-cycle.sh:228` | Consistent (expected shape in parentheses) |
| `skip …: no such entry in docs/working/questions.md or questions-archive.md` | output reason | `skip …: no tracked file (or ignored file under docs/working/) matches` | `scripts/dev-cycle.sh:213` | Consistent shape; inaccurate when the files were not read (Finding 7) |

## Findings

#### 1. "Its branch's hash is an ancestor of the default branch → Done" closes a brief whose branch exists but has no commits yet, and makes check 3's own case unreachable

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:249-252`, `:262-264`, `:287` (B, 6db3d8a)
**Move:** 3 (consumer contract: what the agent does with `ok <name> <hash>`), 7 (asymmetry between checks 1 and 3)
**Confidence:** High (mechanism, probed); Medium (how often the precondition occurs)
**Legibility-target:** agent

**Evidence:**
```
  1. Its branch's hash (from `--check-branch`, as in the Rules) is an ancestor of the default
     branch → Done. The user dropped it (closed the brief, or said so) → Ideas, with the
     reason. Either way the brief gets `Status: closed`. A branch the check skips is
     recorded; checks 2 and 3 still run.
```
```
  3. Then, if the brief is still open, no ID on its `Asked:` line is still `open`, its branch
     passed the check, and that branch has no commit beyond the default branch (or is
     `absent`) 14 days after
```
(In-flight list `SKILL.md:247-269` read whole.) and step 6, `SKILL.md:287`: `branch (one `--check-branch` prints `ok` for)`.

A commit is its own ancestor. A branch created from the default branch with no commits yet (the user ran `git switch -c <name>` or made the worktree but has not committed) has a hash that is an ancestor of the default branch, so check 1 sends it to Done and sets `Status: closed`, though no work has landed. Probe `p3.sh`: `git branch feat-a` at main, then `--check-branch feat-a` printed `ok feat-a 5940a29…`, and `git merge-base --is-ancestor 5940a29… main` returned 0 ("is-ancestor: yes"). Check 3 then describes a case check 1 has already consumed: an existing branch with "no commit beyond the default branch" is always an ancestor, so in check 3 only `absent` can ever reach that clause. Step 6 makes this reachable from the cycle's own side as well: it accepts any branch that `--check-branch` prints `ok` for, and that includes existing branches (`ok main <hash>`), so a brief naming `main` or an old merged branch is Done on the next cycle. The old wording ("merged into the default branch") had the same gap in git terms (`git branch --merged` lists a commitless branch), but the new wording turns it into a mechanical instruction. Preconditions: a branch that exists with no commits beyond the default branch when a cycle runs, or a brief naming an existing branch.

**Recommendation:** Make step 6 require `ok <name> absent` (a new branch) and record the default branch's hash in the brief (`Base: <hash>`); check 1 becomes "the hash is an ancestor of the default branch and differs from `Base:`". Check 3's clause then reads "has no commit beyond `Base:`".

#### 2. A merged branch that is then deleted never reaches Done: `absent` sends it to the keep-or-drop question instead

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:249-252`, `:262-269`; `skills/dev-cycle/SKILL.md:146-149` (B)
**Move:** 3 (consumer contract of `ok <name> absent`)
**Confidence:** High (mechanism); Medium (frequency)
**Legibility-target:** agent, user

**Evidence:** check 3 above: `that branch has no commit beyond the default branch (or is `absent`) 14 days after`; check 1 decides Done only from a hash. `workflows/parallel-worktrees.md:56`: `5. Clean up: `git worktree prune` and delete merged item branches (branch deletion needs user approval per Operating Modes).`

Once the user merges a brief's branch and deletes it (the parallel-worktrees cleanup step does exactly this, with approval) before the next cycle runs, `--check-branch` prints `ok <name> absent`. Check 1 has no hash, so not Done; check 3 treats `absent` like "not started" and, 14 days after the brief's date (usually already past), files a `you: judgment` keep-or-drop entry for work that has shipped. Answering `[2]` moves it to Ideas as "dropped" (wrong history); `[1]` sets `Kept:` and the question comes back 14 days later, indefinitely. Step 1 does not cause this itself (it skips branches an open brief names), but nothing stops the user deleting the branch. The brief asked whether this path can reach Done: it cannot. This is not new in this round (the old "or does not exist yet" had the same effect), but this round's `absent` wording is what makes it explicit. Preconditions: a brief's branch merged and deleted between cycles.

**Recommendation:** Record the hash each cycle sees in the brief (`Seen: <hash>`); an `absent` branch whose last `Seen:` hash is an ancestor of the default branch (and differs from `Base:`, Finding 1) is Done. Only a branch never seen with a commit counts as "not started" for check 3.

#### 3. `--check-answer` reads the answer that the archive's 2026-09-12 to 09-27 entries put on the question line as `unrecognized`, three of them clean `[1]` answers

**Severity:** Inconsistent
**Location:** `scripts/dev-cycle.sh:254-262` (comment), `:276-286` (the awk rule) (A, 2008343); test `test/scripts/dev-cycle.bats:598-620`
**Move:** 3 (consumer contract against the archive's real lines)
**Confidence:** High
**Legibility-target:** agent, user, maintainer

**Evidence:**
```
# no such entry. The answer is the first line in the entry that starts with
# "Q-NNN:" or with a bold "**Answer" / "**Answered" label (any case, after an
# optional "- "); only the text after the label's colon counts, and when the
```
(comment `scripts/dev-cycle.sh:254-262` read whole, and the rule `:276-286`). Real lines (`wt-devcycle` archive):
```
:1393  cc-isolated's recommended workflow is … **Answered 2026-09-27: [3] launcher-side scan.
:1412  `hooks/auto-approve-allowed-commands.sh` accepts … **Answered 2026-09-27: [1] supply the backstops.
:1432  The 50 `@needs-reports` suites … **Answered 2026-09-27: [1] narrow the stamp and commit the reports.
:1470  Skill descriptions run 957–2973 characters, … **Answered 2026-09-27: [1] front-load and trim.
```
`p1.sh` output: `unrecognized Q-070 unrecognized Q-071 … unrecognized Q-073`; `p2.sh` shows no deciding line for Q-001, Q-013, Q-068–Q-073 (12 entries carry this shape: archive `:108`–`:1470` listed under Baseline). `p3.sh` with a keep-or-drop entry `keep or drop docs/working/briefs/2026-10-01-b.md? **Answered 2026-10-02: [1].**` and `**Status:** ANSWERED` printed `unrecognized Q-100`.

The rule only looks at lines that *start* with a label, so an answer appended to the question line, a shape the archive used for 12 entries up to five days ago, is missed; the entry is ANSWERED, so it prints `unrecognized` (it fails safe, it never misreads). For a keep-or-drop question the skill then records it as unreadable, adds the ID to `Applied:` and files a new keep-or-drop entry (check 3's 14 days are already past), so the user is asked again in the same cycle. 2008343 says the tests use "the archive's real shapes"; this shape is not among them. Preconditions: a keep-or-drop entry answered in the question-line shape. The other results check out: no non-answer line was read as an answer in either archive copy; `**Answering …**` is excluded; `[3]` answers (Q-037, Q-085) are unrecognized; Q-10 vs Q-100 headings and `Q-10:` vs `Q-100:` lines are kept apart (`p3.sh`: `open Q-10`, `unrecognized Q-100`).

**Recommendation:** Also accept the first bold `**Answer…**`/`**Answered…**` span anywhere in a line of the entry (not only at line start), taking the text from its colon to its closing `**`; add the `:1412` shape to the bats test.

#### 4. `--check-fix` allows more than the skill's own exclusions: gitignored files under `docs/working/`, the user's `docs/human-author/` files, decision records

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:246-253` (A, 2008343); `skills/dev-cycle/SKILL.md:71-74` (B)
**Move:** 3 (contract between the help/skill wording and the mode's behaviour)
**Confidence:** Medium
**Legibility-target:** agent, maintainer

**Evidence:**
```
# An in-cycle fix edits documentation only: anything else (scripts, hooks,
# egress lists, instruction files) is filed, never changed by the cycle itself.
check_fix() {
  local a="$1"
  if ! pathform "$a" || [[ "$a" == *[*?]* ]]; then echo "skip ${a//$'\n'/ }: not an allowed path form"
  elif [[ ! "$a" =~ ^docs/|^README\.md$ ]]; then echo "skip $a: in-cycle fixes edit only docs/ and README.md; file it instead"
  else check_path "$a"; fi
}
```
`p3.sh`: `ok docs/working/local/round.md` (a gitignored file), `ok docs/human-author/a.txt`, `ok docs/decisions/001-x.md`, `ok docs/evaluation-rubric.md`.

Because the last step is `check_path`, the mode inherits its read scope, which includes gitignored files under `docs/working/`. An in-cycle fix to an ignored file cannot land in the "one commit per concern" the skill asks for (`SKILL.md:153`), and the ignored round files are the self-improvement loop's local corpus. Within tracked `docs/` the scope also takes in `docs/human-author/` (the user's own answer files, cited as sources in the archive) and decision records, whose `## Revisit triggers` sections step 2 judges; the skill's "instruction files" exclusion has an in-repo instance under `docs/` too (`docs/evaluation-rubric.md` is self-eval's rubric). The help (`:36-37`, "one --check-path allows, under docs/ or README.md") and the skill (`:72`, "an existing file under `docs/`, or `README.md`") both describe the code accurately, so this is a scope question, not drift. Preconditions: a fix named in repo text that points at one of these paths.

**Recommendation:** Require a tracked file (`git ls-files --error-unmatch`, or skip the ignored listing in `check_fix`) and exclude `docs/human-author/`, and either exclude `docs/decisions/` or state in the skill that decision records count as docs here. If the wide scope is intended, a one-line note in the skill is enough.

#### 5. A brief whose branch fails `--check-branch` is never asked keep-or-drop, so it holds a build slot until the user closes it by hand

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:251-252`, `:262-263`, `:279-282` (B, 6db3d8a)
**Move:** 3
**Confidence:** High (by reading); Low (likelihood: step 6 writes only names that pass)
**Legibility-target:** agent, user

**Evidence:** `A branch the check skips is recorded; checks 2 and 3 still run.` and check 3: `no ID on its `Asked:` line is still `open`, its branch passed the check, and that branch has no commit beyond the default branch`.

Check 3 requires the branch to have passed the check, so a skipped branch never gets a keep-or-drop entry; nothing else ever closes the brief, and it counts toward the limit of 3 open briefs (`:280`). The skip goes only into the record's `## Skipped inputs`, not into the final message, which lists open briefs but not why one is stuck. This resolves pass 22's Finding 5 (checks 2 and 3 now run), but the outcome for check 3 is a brief that is open indefinitely. Preconditions: a brief's `branch` line edited to a name that fails the check.

**Recommendation:** For a skipped branch, file the keep-or-drop entry anyway (14 days after the brief date) with the skip reason in it, or list the brief and the reason in the final message.

#### 6. `ok <name> absent` puts a sentinel word where the hash goes, under the status that means "use this value"

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:32-35`, `:242-243` (A, 2008343); `skills/dev-cycle/SKILL.md:76-78` (B)
**Move:** 2 (naming of an output token), 8 (absent value encoded in-band)
**Confidence:** High
**Legibility-target:** agent

Precedent: `ok <value>` means the consumer may use `<value>` as given, used in `scripts/dev-cycle.sh:208` (`echo "ok $m"`) and `:231` (`echo "ok $a"`), and `SKILL.md:66-70` ("open exactly those paths", "write only on `ok`").

**Evidence:**
```
    sha="$(git show-ref --verify --hash "refs/heads/$a" 2>/dev/null || true)"
    echo "ok $a ${sha:-absent}"
```
`p3.sh`, with a tag named `absent` in the repo: `--check-branch absent` printed `ok absent absent`, and `git rev-parse --verify --quiet absent` printed `5940a29…` (the tag's commit).

The skill does say what `absent` means (`SKILL.md:77-78`), but a consumer that takes field 3 and hands it to git, which is what "reaches git only as the hash … prints" invites, gets either an error or, when any ref named `absent` exists, a real commit. The other modes never put a non-value in the value slot. Precondition: a consumer that does not special-case `absent`, plus a ref named `absent` for the silent case.

**Recommendation:** Print the absent case as its own status, e.g. `absent <name>` (the same token-then-subject order `--check-answer` uses), and keep `ok <name> <hash>` for an existing branch; update help `:32-35` and `SKILL.md:77-78`, check 3's "(or is `absent`)" and step 6.

#### 7. The skip lines of `--check-branch`, `--check-fix` and `--check-answer` are not in `--help`; two reasons say the wrong thing

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:32-40` (help), `:250` (glob reason), `:291-296` (missing-file reason) (A)
**Move:** 3 (documentation drift), 4 (message accuracy)
**Confidence:** High
**Legibility-target:** agent, maintainer

**Evidence:**
```
  --check-answer  "keep|drop|open|unrecognized Q-NNN" for a keep-or-drop
            question, read from docs/working/questions.md or its archive.
```
(`--help` output, `p3.sh`; the help lines for `--check-branch` and `--check-fix` likewise list only `ok` shapes.) And:
```
  for f in docs/working/questions.md docs/working/questions-archive.md; do
    inrepo "$f" || continue
    …
  echo "skip $a: no such entry in docs/working/questions.md or questions-archive.md"
```
`--check-path`'s help defines the `skip <arg or match>: <reason>` line and `--check-write`/`--check-brief` inherit it through "the same"; the three newer modes don't say so, and `--check-answer`'s help does not define `open` or `unrecognized` (only the comment at `:254-262`, which `--help` does not print). `--check-fix 'docs/*.md'` prints `skip docs/*.md: not an allowed path form`, the same reason `--check-path` uses for bad characters, though `--check-path` accepts that form (`p3.sh`); the real rule is "one file, not a glob". `--check-answer` says "no such entry" when a questions file was not read at all (absent, or a symlink skipped by `inrepo`), and the skill then adds the ID to `Applied:`, so the answer is consumed for a reason the record misstates. This carries pass 22's Finding 3 note (`--check-branch` help omits `skip`) over to the two new modes.

**Recommendation:** Add "skip <arg>: <reason> otherwise" to the three help entries and one line defining `open` (no answer, not ANSWERED) and `unrecognized`; give `--check-fix` a glob reason ("a glob; name one file"); make `--check-answer` say "not read: <file> is not a plain file" when a file fails `inrepo`, and let the skill leave such an ID off `Applied:`.

#### 8. A squash- or rebase-merged branch stays In flight indefinitely

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:249-264` (B)
**Move:** 3
**Confidence:** Medium
**Legibility-target:** agent, user

**Evidence:** check 1 `Its branch's hash … is an ancestor of the default branch → Done`; check 3 `that branch has no commit beyond the default branch (or is `absent`)`.

After a squash or rebase merge the branch tip is not an ancestor (no Done) and still has commits beyond the default branch (no keep-or-drop question), so the brief holds a slot until someone closes it by hand. This repo merges with merge commits (`git log` shows `Merge branch …`), so it is unlikely to fire here, but the skill is installed for any project. Precondition: a project that squash-merges.

**Recommendation:** One sentence in check 1: a branch whose changes are on the default branch by another route is closed by the user, or by the `Seen:`/`Base:` record from Findings 1–2.

#### 9. The archive fallback of `--check-answer` has no test

**Severity:** Informational
**Location:** `test/scripts/dev-cycle.bats:598-620` (A)
**Move:** 3 (test drift)
**Confidence:** High
**Legibility-target:** maintainer

**Evidence:** the one `--check-answer` test writes only `docs/working/questions.md` (`} > docs/working/questions.md`); no test writes an entry to `questions-archive.md`, puts a prefix-sharing ID next to another (Q-10 / Q-100), or puts an entry in both files. `p1.sh` shows the fallback works on the real archive, so this is coverage only.

**Recommendation:** Add an archived entry, a Q-10/Q-100 pair and the question-line shape of Finding 3 to the existing test.

## What Looks Good

- **Check-mode contract.** Both new modes follow `--check-<x> ARG...`, at least one argument (`--check-answer needs at least one argument`, exit 1; `p3.sh`), one line per argument, exit 0, `skip <value>: <reason>` for unusable input. The usage error now says "argument" for every mode (pass 22 Finding 4 fixed).
- **`--check-answer` rule, correct and complete for the separate-line shapes.** Labels `Q-NNN:`, `**Answer…**`, `**Answered…**` in any case and after `- `, never `**Answering**` or `**Answers**` (`[^a-z]|ed`); only the bold span counts, so recorder notes cannot flip it (pass 22 Finding 2 fixed: `**ANSWERED …: [2] drop it.** Notes [1].` → drop); `[1]`+`[2]` → unrecognized; "keep both" → unrecognized (pass 22 Finding 8 fixed); ANSWERED without an answer → unrecognized, never `open`. On both archive copies no non-answer line was read as an answer, and every `open` was an OPEN entry. Entry boundaries: `### Q-10` matches only `### Q-10` or `### Q-10 …`, `Q-10:` never matches `Q-100:`, and the entry ends at the next `##`/`###`.
- **awk portability.** No `{n}` intervals; `tolower`, `index`, `substr`, `sub`, `match`/`RLENGTH` are all POSIX; `$` inside the `([.,;:!)]|$)` group works in mawk 1.3.4 (`keep Q-101` for `Q-101: keep`, `keep Q-106` for `Q-106: 1`); `-v id=` is safe because the ID is checked against `^Q-[0123456789]+$` first; `LC_ALL=C` fixes `tolower`. gawk was not available to run.
- **`--check-branch`.** `show-ref --verify --hash refs/heads/<name>` cannot be shadowed by a tag (bats 31; `p3.sh` `ok absent absent` despite a tag `absent`); `check-ref-format --branch` plus the HEAD and `refs/*` refusals reject `HEAD`, `refs/heads/main`, `a..b`, `x.lock`; `@` and `main@x` fail the charset. Correct and complete for its stated rule.
- **Default-branch lookup.** `show-ref --verify` then `rev-parse --verify "$sha^{commit}"`; every later git call uses `MAIN_SHA`, and `MAIN` is only printed (`:372`, `:384`, `:546-547`). Correct.
- **`exact()`** now filters the ignored listing too, so a plain path keeps only itself in both listings (`:191`, `:196`).
- **Help range** `sed -n '2,48p'`: line 47 is the last header comment, line 48 blank. Correct.
- **Skill wiring.** Every place the skill reads an answer (In-flight 2), edits a file in-cycle (Rules `:71-74`, step 1), passes a branch to git (In-flight 1 and 3, by hash) or lists briefs (Rules `:74`, step 1 `:148`, step 6 `:281`) now names the mode that gates it. 36ca12c's count of this cycle's uncommitted briefs is right: `--check-path` lists tracked files and ignored files under `docs/working/`, and a new brief is neither. `docs/dev-cycle.md:27-28` now names the in-repo script as the skill does (pass 22 Finding 7 fixed; wording "in claude-workflows itself" vs the skill's "inside claude-workflows, its own" is a trivial difference).
- **Tests and lint.** 33/33 bats, shellcheck clean, matching 2008343/ba39470's "33/33; shellcheck clean".

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | "hash is an ancestor → Done" closes a commitless branch's brief; step 6 accepts existing branches; check 3's branch case unreachable | Inconsistent | `skills/dev-cycle/SKILL.md:249-252, 262-264, 287` | High |
| 2 | Merged-then-deleted branch (`absent`) never reaches Done; gets keep-or-drop instead | Inconsistent | `skills/dev-cycle/SKILL.md:249-252, 262-269` | High |
| 3 | `--check-answer` misses answers appended to the question line (12 archive entries to 2026-09-27; Q-070/071/073 clean `[1]`) | Inconsistent | `scripts/dev-cycle.sh:254-286` | High |
| 4 | `--check-fix` admits ignored `docs/working/` files, `docs/human-author/`, decision records | Minor | `scripts/dev-cycle.sh:246-253` | Medium |
| 5 | Brief with a skipped branch is never asked keep-or-drop; holds a slot | Minor | `skills/dev-cycle/SKILL.md:251-252, 262-263` | High |
| 6 | `ok <name> absent` puts a sentinel in the hash slot under `ok` | Minor | `scripts/dev-cycle.sh:242-243` | High |
| 7 | Help omits skip lines and `open`/`unrecognized`; glob and missing-file skip reasons misstate the cause | Minor | `scripts/dev-cycle.sh:32-40, 250, 291-296` | High |
| 8 | Squash/rebase-merged branch stays In flight | Informational | `skills/dev-cycle/SKILL.md:249-264` | Medium |
| 9 | No test for the archive fallback, prefix IDs or question-line answers | Informational | `test/scripts/dev-cycle.bats:598-620` | High |

## Overall Assessment

The digest side is consistent: `--check-fix` and `--check-answer` follow the `--check-<x>` contract, `--check-branch` is correct and complete against tag shadowing, and the answer rule reads every separate-line answer in the archive correctly and never reads a non-answer as one. Pass 22's Breaking (answer labels) and its Minors 2, 4, 5, 7 and 8 are fixed. What remains there fails safe: one real recording shape (answer on the question line) reads as `unrecognized`, and the help and two skip reasons lag the new modes. The skill side has one new consumer-contract problem. Now that the In-flight checks are mechanical ("hash is an ancestor"), two outcomes come out wrong: a branch with no commits yet is Done, and a merged-then-deleted one can never be Done. Both can be fixed in place by recording `Base:`/`Seen:` hashes in the brief and requiring a new (`absent`) branch at brief time. No finding is Breaking under this skill's definitions. Findings 1–3 are the ones to fix before a clean pass; 4–7 are wording or scope fixes of a line or two each.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file." This report is saved at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-02-digest-pass23.md`, first line `Commit: ba39470 (A) / 36ca12c (B)`, with the skill's sections (header, Baseline Conventions, Name-Pattern Audit, Findings, What Looks Good, Summary Table, Overall Assessment). Every finding carries Severity, Location, Evidence (verbatim), Confidence and Legibility-target, and the one naming finding (6) carries its `Precedent:` line. It serves the user goal (k=1 delta passes until no known issues remain, then merge) by confirming which pass-22 issues are fixed and naming the three Inconsistent and four Minor issues still open in this round's fixes.
