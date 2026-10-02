Commit: d5d9121 (A) / fbc7101 (B)

# Security Review: dev-cycle pass 21 (pass-20 fix round)

**Scope:** A `git diff 546b86e..d5d9121 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (wt-digest); B `git diff 46d3423..fbc7101 -- skills/dev-cycle/SKILL.md` (wt-devcycle). Partial scope: the rest is context only.
**Date:** 2026-10-02
**Based on:** shared brief `digest-pass21-brief-dc1aa358.md`; Stage-1 context `docs/reviews/code-fact-check-report-digest-pass20.md`; prior `security-review-2026-10-02-digest-pass20.md` (Findings 1 and 2 there are what this round fixes).

Tests: `bats test/scripts/dev-cycle.bats` gave 26/26 ok, run in wt-digest (scripts/ and test/ at HEAD c227581 are byte-identical to d5d9121). All probes ran under `timeout` in a `mktemp -d` repo under the scratchpad. That repo was removed afterwards.

## Trust Boundary Map

```
B1: [repo text: roadmap brief path / settings glob / commit msg / plan / question] → [agent charset pre-filter + single quotes (SKILL.md:71-73)] → [dev-cycle.sh argv]
B2: [argv path or glob] → [--check-path: pathform(glob) → git ls-files (tracked; ignored only if prefix can reach docs/working/, grep -z filter) → pathform(match) → inrepo; cap 50] → [agent file read]
B3 (moved): [write target: fixed name, or an In-flight brief path from the roadmap] → [--check-write: pathform → writable() (new) → blocker] → [agent Write/Edit, commit, land]
B4: [questions.md / archive answer line] → [skill answer parsing (SKILL.md:248-258, changed)] → [brief Status/Kept/Applied edits]
B5: [brief file's branch line (repo text)] → [none on read; charset only when the cycle writes a brief (SKILL.md:281, new)] → [agent-composed git command (SKILL.md:242, 260)]
```

```
S1: roadmap / briefs / questions / commit text      — runtime-mutable (any merged commit) — UNTRUSTED toward path, write and git-argv sinks
S2: git index + repo .gitignore + working-tree types — runtime-mutable (repo-controlled)     — UNTRUSTED toward the scope decision; trusted for "is tracked"
S3: answer lines in questions.md / archive          — runtime-mutable (repo text)          — UNTRUSTED toward brief-state edits (low-consequence sink)
S4: caller environment (LC_ALL, GIT_* vars, PATH)   — deploy-time (host)                   — trusted (an attacker who sets it controls the host)
S5: the skill's fixed write names and writable() regexes — code-constant                   — trusted
```

What enters from outside is repo text: paths, globs, brief paths, branch names and answers. This round moves the write scope into code (`writable()`), which closes pass-20 Finding 1 for any file outside the cycle's own set. The remaining untrusted-to-sink hop that has no code or prose gate is B5: a brief's branch line on the read side.

## Findings

#### 1. A brief's branch line reaches an agent-composed git command unchecked; the new charset rule covers only briefs the cycle writes

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:242, 259-261` (use); `skills/dev-cycle/SKILL.md:281` (the new write-side rule)
**Boundary:** B5
**Move:** 2 (implicit sanitization assumption), 11
**Confidence:** Medium. The mechanism is concrete. Whether the value becomes an option or shell text depends on how the agent writes the command, which the skill does not specify.
**Legibility-target:** SKILL.md's In-flight steps 1 and 3 (a read-side rule), or a code check: `dev-cycle.sh --check-branch`, mirroring the script's own `MAIN` handling

**Evidence (verbatim):**
> `included), branch (letters, digits, `.`, `_`, `-`, `/`, not starting with `-`), and` (SKILL.md:281, step 6, "For each, write `docs/working/briefs/…`")
> `1. Its branch merged into the default branch → Done.` (SKILL.md:242)
> `the branch has no commit beyond the default branch (or does not exist yet) 14 days after` (SKILL.md:260; the sentence continues to 265 with the keep-or-drop filing)
> script comparison, dev-cycle.sh:209-210: `# Pass git only a hash for the default branch: origin/HEAD comes from the remote,` / `# and a branch named `--output=<path>` would reach `git log` as an option.`

The charset sentence is in step 6's "write" paragraph. It constrains what the cycle puts in a new brief. Briefs are committed files, and any later merged commit can edit one (S1). In-flight steps 1 and 3 then read "its branch" and run git against it (merged? commits beyond default?) with no rule on the value read. A brief edited to `branch: --output=docs/x` reaches a `git log <branch> --not <default>`-shaped command as an option. `git log --output=<file>` writes a file outside the cycle's write gate. A branch value carrying shell metacharacters (`$(…)`, `;`) becomes command injection if the agent interpolates it without quoting. The script already guards this exact primitive for its own branch name. The pass-20 review recorded this as out of scope ("pre-existing, outside this delta"). This round's diff now adds a branch-name rule, but only on the side that does not reach a sink. Floor rule: the mechanism is concrete and reachable through repo text, so Medium. Confidence carries the uncertainty about agent behavior.

**Recommendation:** Add a read-side rule to In-flight step 1: "a branch that does not match the step-6 charset, or starts with `-`, is skipped and recorded". Have git receive it only as `refs/heads/<branch>` after `rev-parse --verify --quiet` (the script's pattern), inside single quotes. Better: add a `--check-branch` mode to dev-cycle.sh, so the rule lives in tested code like the path rule.

#### 2. "Counts as a brief only if `--check-write` prints `ok`" still admits the cycle's five non-brief files as briefs

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:70-71`; `scripts/dev-cycle.sh:191-195`
**Boundary:** B3
**Move:** 5 (invert the access model), 11
**Confidence:** High that the gate admits them (executed). Low that the cycle does harm with one.
**Legibility-target:** the SKILL.md brief-path sentence, or a brief-specific check in code

**Evidence (verbatim):**
> `` `ok`; it allows only those files. A roadmap brief path counts as a brief only if `` / `` `--check-write` prints `ok` for it. `` (SKILL.md:70-71)
> `[[ "$1" =~ ^docs/roadmap\.md$|^docs/working/(questions|questions-archive|idea-log)\.md$ \` … `|| "$1" =~ ^docs/working/briefs/[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9-]+\.md$ ]]` (dev-cycle.sh:192-194, `writable()` complete)

Probe output: `--check-write docs/working/questions.md docs/roadmap.md docs/working/questions-archive.md docs/working/idea-log.md docs/working/cycles/cycle-2026-99-99.md` → `ok` for all five. So a roadmap In-flight row whose "brief" is `docs/working/questions.md` passes the stated gate. The cycle would then write `Status: closed` / `Asked:` / `Applied:` / `Kept:` lines into its questions file or roadmap, and could list that file as an "open build brief" in the final message. This is much narrower than pass-20 Finding 1. Writes stay inside files the cycle owns, and an attacker who can land repo text can already edit those files, or plant a real dated brief. That is why it is Low: it adds no capability, and the floor rule's "security property violated" is only brief identity. It is still a stated gate that does not do what the sentence implies. The pass-20 recommendation was the dated-shape rule, and that is what `writable()`'s third alternative already encodes.

**Recommendation:** Change the sentence to "counts as a brief only if it is `docs/working/briefs/YYYY-MM-DD-<slug>.md` and `--check-write` prints `ok`". Alternatively, add `--check-brief` (just the third regex plus the blocker walk), with a bats case where `docs/working/questions.md` must not print `ok`.

#### 3. A `LC_ALL` naming an uninstalled locale makes every `pathform` call print setlocale warnings to stderr

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:152-163` (`local LC_ALL=C …`)
**Boundary:** Internal, no boundary. This is S4 (host environment), not attacker-reachable. It is listed because the noise reaches the agent that reads the check output.
**Move:** 3 (error path)
**Confidence:** High (executed)
**Legibility-target:** the script (e.g. `LC_ALL=C` once at check-mode entry, or `2>/dev/null` scoping), or a Not-covered note

**Evidence (verbatim):** with `LC_ALL=en_US.UTF-8` (not installed here, as in this container's default env), each probe argument printed `dc.sh: line 176: warning: setlocale: LC_ALL: cannot change locale (en_US.UTF-8)` (and line 182 per match). The bats run shows the same lines. stdout `ok`/`skip` answers were unaffected.

The local scope's exit restores the caller's `LC_ALL` through `setlocale`. That restore is what proves the `local` assignment takes effect (see Endorsement 2). When the caller's locale is missing, the restore fails noisily on every call. This is not a security issue. The stdout contract holds, but an agent reading the merged output gets dozens of warnings per run.

## Rules checked and found correct and complete

- **`writable()` against every file the skill writes.** I enumerated SKILL.md's write targets. The record is `docs/working/cycles/cycle-YYYY-MM-DD.md` (step 7). A brief is `docs/working/briefs/YYYY-MM-DD-<slug>.md` with slug `[a-z0-9-]`, including the `-2`/`-3` suffix (step 6). Then the idea log (Seeding; step 5), `docs/roadmap.md` (step 6), and `questions.md` / `questions-archive.md` (Attention rule; step 6 In-flight). Every one matches a `writable()` alternative. Nothing extra is admitted except the questions-archive, which `questions.sh archive` writes. `docs/dev-cycle.md` is read only and is correctly refused (probe: `skip docs/dev-cycle.md: not one of the files the dev cycle writes`). The regexes are anchored and use `\.`. An uppercase slug, a trailing `/` and `..` are refused (probes). `2026-99-99` and a `--` slug are admitted. That is harmless: the name stays inside the cycles or briefs directory. Out of the gate's reach by design: in-cycle mechanical fixes (step 1 "Fix what is mechanical now", step 3 `agent` entries, step 4 "fix it if mechanical") write arbitrary repo files. The skill's parenthetical scopes `--check-write` to the cycle's own files, so those writes go through pr-prep, not this gate. This is noted, not a finding.
- **Cap at 50.** It counts matches after the plain-path filter, skip lines included, and cuts on the 51st. With 49 tracked plus 3 ignored files, two runs produced byte-identical output (md5 equal). Tracked files come first (index order), then ignored ones, so the cut is deterministic and falls on the ignored tail first. At 50 or fewer, no cap line appears. The failure mode is fail-closed (fewer reads). A merged PR could pad a glob to hide later files, but the agent sees `skip <glob>: matches more than 50 files; the rest are not listed`, which the skill sends to `## Skipped inputs`.
- **Ignored-query prefix test.** `fixed` is the literal prefix before the first `*`/`?`, so every git match starts with `fixed`. A match under `docs/working/` therefore satisfies one of the two disjuncts. The test is complete for case-sensitive pathspecs. Probes that reached the ignored files: `*/working/*`, `d*/working/s*`, `docs/*/a.log`, `?ocs/working/secret.txt`, `**`, and the plain paths. Correctly skipped (no ignored match possible): `*.log` (`*` does not cross `/` under `:(glob)`) and `Docs/Working/a.log`. Skipping fails closed in any case.
- **The `grep -z '^docs/working/'` filter.** `printf 'evil\ndocs/working/f\0docs/working/ok\0xdocs/working/n\0' | grep -z '^docs/working/'` printed only `docs/working/ok`: `^` does not anchor after an embedded newline. A newline-bearing match would be refused by `pathform(match)` regardless.

## Untested bypass candidates

- **A case-insensitive filesystem** (macOS, NTFS, WSL `/mnt/c`): whether `realpath -e` returns the given case or the on-disk case is still unexercised (carried from pass 20). `writable()` now requires lowercase names, which shrinks this to a differently cased symlinked parent of a lowercase target. Not tested.
- **A non-C locale where `[A-Za-z]` collates non-ASCII letters.** Only C and C.UTF-8 are installed. `pathform` now runs under `LC_ALL=C` (the restore warning shows it takes effect). `writable()` and `check_path` do not, but they only see strings `pathform` already restricted to ASCII.
- **Caller `GIT_ICASE_PATHSPECS` / `core.ignorecase`** interacting with the prefix test. If git matched case-insensitively, the `Docs/...` prefix would skip the ignored query, which is fail-closed. Not exercised.
- **Check-to-write race** (symlink swapped in after `--check-write`): needs local write access, so it is out of the reachable-environment bar. Not exercised.

Because of these candidates, `pathform`, `writable()` and the blocker walk are reported as tested, not endorsed, except for the narrow claims below.

## Endorsement Claims

- **Claim:** `--check-write` refuses every path outside the seven-shape set (roadmap, questions, questions-archive, idea log, dated cycle record, dated brief) with `skip <path>: not one of the files the dev cycle writes`. This holds for tracked, untracked and ignored paths alike.
  **Location:** `scripts/dev-cycle.sh:191-202`
  **Evidence:** executed
  **Verified:** bats test 26 (`AGENTS.md`, `scripts/x.sh`, `.env`, `docs/working/briefs/x.md`), plus probes `docs/dev-cycle.md` and `docs/working/briefs/2026-01-01-X.md`.
  **Not verified:** a lowercase target reached through a differently cased symlinked parent on a case-insensitive FS.
  **route: code-fact-check**
- **Claim:** In bash 5.2.15, `local LC_ALL=C` inside `pathform` invokes `setlocale` on entry and on return. The function's `=~` and `[[ == ]]` therefore compile under C, and the caller's locale is restored afterwards.
  **Location:** `scripts/dev-cycle.sh:152-163`
  **Evidence:** executed
  **Verified:** with `LC_ALL=en_US.UTF-8` (uninstalled), a warning `cannot change locale (en_US.UTF-8)` appears only after `f` returns (the restore), and `pathform` callers print it per call. Under `C.UTF-8`, `é` is rejected by the range regex inside and outside the function.
  **Not verified:** a locale where the ranges differ observably (none installed). That `.git*` matching no longer depends on locale is shown separately: `.Git/x`, `.gIT`, `a/.GiT/b` and `.git.` all print `not an allowed path form`.
  **route: code-fact-check**
- **Claim:** `pathform` now refuses `.` components: `./docs/working/secret.txt` and `docs/./working/a.log` print `skip …: not an allowed path form`.
  **Location:** `scripts/dev-cycle.sh:159-162`
  **Evidence:** executed
  **Verified:** probe output.
  **Not verified:** none of the `.`-component forms git itself normalizes in `:(glob)` (e.g. `docs/*/./x`). All are refused by the same component loop, but none was run.
  **route: code-fact-check**

## Primitive sweep

Primitive: git pathspec evaluation
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `dev-cycle.sh:166` `git ls-files -z -- "$1"` | S1 via B1/B2 | pathform(glob), explicit `:(glob)`/`:(literal)` | cleared: probes |
| `dev-cycle.sh:169-171` `ls-files --others --ignored …` + `grep -z` | S1, S2 | prefix test + `^docs/working/` filter + pathform(match) | cleared: probes, prefix proof above |

Primitive: file write (agent)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| record / new brief / idea log / roadmap / questions files | S5 | `--check-write` (`writable()` + blocker) | cleared (Endorsement 1) |
| In-flight brief edits (`Status:`, `Asked:`, `Applied:`, `Kept:`) | S1 (roadmap) | `--check-write` | Finding 2 (non-brief own files pass) |

Primitive: git argv / shell built from repo text (agent)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| SKILL.md:64-73 `dev-cycle.sh --check-path/--check-write '<path>'` | S1 | charset filter + single quotes | cleared: the charset has no `'`, `$`, backtick or space |
| SKILL.md:242, 260 brief branch → git | S1 (brief file) | none on read | Finding 1 |
| SKILL.md:64-65, 101-102 the installed script vs the repo's own `scripts/dev-cycle.sh` | the agent's judgment of "inside claude-workflows" | none | cleared: the cycle already runs repo code by design (health check, tests: SKILL.md:25, 128-130). Repo *code* is in the trusted set, so this adds nothing. |

Answer parsing (B4, SKILL.md:248-258): the label-colon rule handles the archive's real forms (`**Answered 2026-09-17 (probe, `docs/…`): keep both`, `**Answered 2026-09-20: [1].**`, `**Answered 2026-09-18 (…):** v4.2.4…`). A colon inside the parenthetical (a URL, a time) moves the cut earlier, but `[1]`/`[2]` is still found after it. Answer lines are S3. Anyone who can land repo text can write one, which is inherent to keeping answers in the repo, and the consequence stays at keep or drop. No finding.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Brief branch line reaches agent git command unchecked; charset only on write | Medium | B5 | `SKILL.md:242, 260, 281` | Medium |
| 2 | Brief gate = `--check-write ok` admits the five non-brief own files | Low | B3 | `SKILL.md:70-71`; `dev-cycle.sh:191-195` | High (gate) / Low (harm) |
| 3 | setlocale warnings per `pathform` call under an uninstalled `LC_ALL` | Informational | Internal | `dev-cycle.sh:152-163` | High |

## Overall Assessment

The pass-20 fixes hold. `--check-write` is now scoped in tested code to the cycle's own files, which closes pass-20 Finding 1's any-tracked-file write path. The 50-file cap is deterministic and fails closed. The C-locale change takes effect for `=~` and `[[ == ]]`, and the `.git*` test no longer depends on case folding. The ignored-query prefix test misses no argument that can reach a docs/working ignored file. What remains is outside the script. The skill's new branch-name charset guards the write side only, and the read side, where a brief's branch line reaches a git command, has no rule (Finding 1, Medium). That is the single most important thing to fix: put the script's own `MAIN` treatment on it, ideally as a code check. The brief-path sentence should also name the briefs shape (Finding 2, Low). Both are fixable in place. No findings within the code paths read beyond these; endorsement claims pending execution verification.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/security-review-2026-10-02-digest-pass21.md`, with first line `Commit: d5d9121 (A) / fbc7101 (B)`. It follows security-reviewer's structure: trust boundary map and source table, findings with Severity/Location/Evidence/Confidence/Legibility-target, untested bypass candidates, endorsement claims routed to code-fact-check, primitive sweep, summary table and overall assessment. It attacks `--check-path` and `--check-write` directly against claims 1 and 2 of the brief. Not committed.
