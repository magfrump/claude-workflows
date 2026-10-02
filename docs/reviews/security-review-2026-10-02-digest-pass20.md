Commit: 546b86e (A) / 46d3423 (B)

# Security Review — dev-cycle pass 20 (k=1 delta: `--check-path` / `--check-write` and the skill's use of them)

**Scope:** A `git diff 1b0c4ff..546b86e -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (wt-digest); B `git diff 462e561..46d3423 -- skills/dev-cycle/SKILL.md docs/dev-cycle.md` (wt-devcycle). Partial scope: everything else is context only.
**Date:** 2026-10-02
**Based on:** shared brief `digest-pass20-brief-dc1aa358.md`; Stage-1 context `docs/reviews/code-fact-check-report-digest-pass19.md`; prior `security-review-2026-10-02-digest-pass19.md`.

All probes ran under `timeout` in a throwaway repo below `mktemp -d` in `scratchpad/sec20/`, using `git show 546b86e:scripts/dev-cycle.sh` as the script. Nothing was written to either worktree except this report. `bats test/scripts/dev-cycle.bats`: 26/26 ok.

## Pass-19 findings: status

All five pass-19 security findings are addressed at these commits (verified by execution unless marked otherwise):
- #1 (`*` not allowed): `*`/`?` are now allowed, and git matches them through `:(glob)`. The repo's own idea-source row `docs/working/feature-ideas*.md` gives `ok docs/working/feature-ideas.md` in wt-devcycle.
- #2 (directory accepted): `--check-path docs` → `skip docs: no tracked file …`. A plain path must equal a listed file (`m == a`).
- #3 (writes through a symlinked roadmap or idea log): `--check-write` runs the full `blocker` walk. A symlinked file and a symlinked parent are both refused (probe below, and bats 26).
- #4 (index fallback, comment): the fallback now checks `HEAD:<path>` and the comment states the removed-from-HEAD case. Read-static only.
- #5 ("2 more weeks" parsed as drop): the word fallback now needs the whole answer to be exactly `1`/`keep`/`2`/`drop`. Read-static only.

## Trust Boundary Map

```
B1 (new): [repo text: settings row / roadmap brief path / commit msg / plan / question] → [agent charset pre-filter + single quotes (SKILL.md:61-73)] → [dev-cycle.sh argv]
B2 (new): [dev-cycle.sh argv]          → [pathform → git ls-files :(glob)/:(literal) → docs/working filter → pathform(m) → inrepo] → ["ok <path>" line]
B3 (new): ["ok <path>" line]            → [agent "open exactly those paths"]                → [file content read into the cycle / subagents]
B4 (new): [write target: fixed name, or an In-flight brief path taken from the roadmap] → [--check-write: pathform → blocker] → [agent Write/Edit, then commit + land]
B5 (moved): [docs/decisions/NNN-*.md name from working-tree glob] → [git cat-file -e HEAD:$f → git log -1 -- $f] → [digest "last committed" line]
B6: [questions.md / archive answer line] → [skill answer parsing (SKILL.md:241-252)] → [brief Status/Kept/Applied edits]
```

```
S1: repo text naming paths (roadmap, docs/dev-cycle.md rows, commits, plans, questions)
      — runtime-mutable (any merge) — UNTRUSTED for path, read, write and exec sinks
S2: git index + .gitignore (repo-controlled) + working-tree file types (committed symlinks)
      — runtime-mutable — UNTRUSTED for path-resolution sinks; it decides scope only together with the code rule
S3: ignored files under docs/working/ (local loop output) — runtime-mutable — UNTRUSTED for content (evidence only); in scope for reads by design
S4: answer lines in questions.md / archive — runtime-mutable (repo text) — UNTRUSTED toward brief-state edits (low-consequence sink)
S5: caller environment (locale, GIT_* pathspec env, core.ignorecase, filesystem case-sensitivity)
      — deploy-time, user-controlled — trusted, but it changes guard behavior (see Untested bypass candidates)
S6: the skill's fixed write names (record, new brief docs/working/briefs/YYYY-MM-DD-<slug>.md, idea log, roadmap) — code-constant — trusted
```

The new code puts the read rule (B2) in tested code, and it holds against every repo-controlled bypass I tried. The write side (B4) is weaker. `--check-write` applies form and symlink checks but no scope. The skill commit removed the one constraint that tied the only repo-text-derived write target (an In-flight brief path, S1) to `docs/working/briefs/`.

## Findings

#### 1. The brief-path shape rule was removed, so a roadmap In-flight row can point the cycle's brief edits (and its commit) at any tracked file

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:61-73` and `:237-260` (46d3423); `scripts/dev-cycle.sh:176-181` (546b86e)
**Boundary:** B1, B4
**Move:** 1 (trust boundaries), 5 (invert the access model)
**Confidence:** Medium. The mechanism was executed at script level. That an agent follows a non-brief path depends on agent judgment, and the cycle's diff then goes through pr-prep.
**Legibility-target:** the skill's path rule (SKILL.md:61-73), or better a code check (`--check-write` scope / a brief-path form)
**Evidence:**
Removed by 46d3423 (462e561 SKILL.md:74-76):
> `A brief path counts only as`
> `` `docs/working/briefs/YYYY-MM-DD-<slug>.md` (slug of lowercase letters, digits and``
> `` hyphens), written in the roadmap as that repo-root path in backticks.``

Replacement (SKILL.md:61-66):
> `starts open a file named by repo text (a settings row or glob, a brief path in the roadmap,`
> `` … only after `dev-cycle.sh --check-path '<path or glob>' …` prints `ok <path>` ``
> `` for it, and open exactly those paths. Before writing a file (the record, a brief, the idea ``
> `` log, the roadmap), run `dev-cycle.sh --check-write '<path>'` and write only on `ok`.`` [continues: charset and quoting sentence, scope sentence, section-8 sentence]

The write sites the brief path feeds (SKILL.md:239-258): `Either way the brief gets `Status: closed`.`, `sets `Kept: <today>``, `add its ID to `Applied:``, `add its ID to `Asked:``.

`check_write` (dev-cycle.sh:176-181) has no scope test:
> `if ! pathform "$a"; then echo "skip ${a//$'\n'/ }: not an allowed path form"`
> `elif [[ -n "$(blocker "$a" file)" ]]; then echo "skip $a: reached through a symlink, or not a regular file"`
> `else echo "ok $a"; fi`

Probe (throwaway repo, tracked `.cfg/settings.json` standing in for any dot-config dir other than `.git*`, plus tracked `scripts/run.sh`): `--check-path scripts/run.sh` → `ok scripts/run.sh`; `--check-path .cfg/settings.json` → `ok .cfg/settings.json`; `--check-write .cfg/settings.json scripts/run.sh` → `ok` for both.

The roadmap is repo text (S1), and the skill names "a brief path in the roadmap" as such. Any merge that edits `docs/roadmap.md` can therefore add an In-flight item whose "brief path" is any tracked file of allowed form: a script, a skill file, an agent-settings JSON under a dot-directory, or a CI file outside `.github`. Both gates now return `ok` for it, and the skill's only remaining instruction is "write only on `ok`". The cycle then writes `Status: closed`, `Asked:`/`Applied:`/`Kept:` lines into that file, stages it as a named path, commits it and lands it through pr-prep. The injected content is fixed, so this is integrity damage and denial of service (for example, a JSON settings file that no longer parses, or a skill file with stray lines), not code injection. A glob in the brief-path slot (`docs/working/briefs/*.md`) widens it to many files, because the skill says to "open exactly those paths". Before 46d3423 the dated-shape rule refused all of this. The floor rule applies: the mechanism is concrete and reachable through repo text.

**Recommendation:** Put the brief-path form in code, consistent with this round's direction. For example, `--check-write` could accept only the cycle's own targets (`docs/roadmap.md`, `docs/working/idea-log.md`, `docs/working/cycles/cycle-YYYY-MM-DD.md`, `docs/working/briefs/YYYY-MM-DD-<slug>.md`), or a `--check-brief` mode could enforce the old regex. At a minimum, restore the dated-shape sentence in SKILL.md and add a bats case: `--check-write scripts/x.sh` must not print `ok`.

#### 2. The skill describes `--check-write` with `--check-path`'s scope, but the write check allows any untracked or ignored path

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:69-71` (46d3423); `scripts/dev-cycle.sh:143-145` (header comment "scope (reads)")
**Boundary:** B4
**Move:** 2 (implicit sanitization assumption)
**Confidence:** High (executed)
**Legibility-target:** SKILL.md:69-71
**Evidence:** SKILL.md:69-71:
> `The check`
> `allows tracked files and gitignored files under `docs/working/`, never a symlink, a`
> `directory, `..`, `.git*` or any other untracked file;`

This sentence follows the `--check-write` sentence. Probe: `--check-write secret.txt` (ignored, outside docs/working) → `ok secret.txt`; `--check-write newdir/x.sh` → `ok newdir/x.sh`; `--check-write docs/working/ign/nested/q.md` (inside an untracked nested repo) → `ok`.

A reader of the skill would assume writes have the same scope as reads. They do not, and they cannot fully: new briefs and records are untracked when written. On its own this is a legibility gap, because the skill's write targets are fixed names. Its security weight comes through Finding 1. The script header says "(reads)" correctly.

**Recommendation:** Say in the skill that `--check-write` checks form and symlinks only, or add the scope in code as recommended in Finding 1.

#### 3. A broad glob (`**`, `*/*/*`) from a repo-text row has no cap, and the skill reads every match

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:158-175`; `skills/dev-cycle/SKILL.md:64-65`; `docs/dev-cycle.md` idea-source table
**Boundary:** B1, B2, B3
**Move:** 8 (a million of these)
**Confidence:** High (executed); impact is volume only
**Legibility-target:** docs/dev-cycle.md "Idea sources" paragraph
**Evidence:** probe `--check-path '**'` printed `ok` for every tracked file of allowed form, plus the ignored docs/working files (`ok .cfg/settings.json`, `ok scripts/run.sh`, `ok docs/working/ign/z.md`, …). The skill says (SKILL.md:65) `` for it, and open exactly those paths.``

An idea-source row of `**` (docs/dev-cycle.md is repo text, kept by hand) makes step 5 read the whole tracked tree into the brainstorm. Every file stays inside the read scope, so confidentiality and integrity hold. The cost is session budget and attention, and step 5 then takes in skill and settings text as "evidence".

**Recommendation:** Cap the number of matches per argument (for example, after N, print `skip <arg>: matches more than N files`), or tell the skill to skip a glob with no fixed directory prefix.

#### 4. An untracked nested repository under an ignored docs/working directory produces spurious `skip …/: not an allowed path form` lines for unrelated globs

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:158-175`
**Boundary:** B2
**Move:** 11 (bypass enumeration, a by-product)
**Confidence:** High (executed)
**Legibility-target:** `## Skipped inputs` in the cycle record
**Evidence:** with `docs/working/ign/` ignored and holding a nested `git init`: `--check-path '?ocs/a.md'` → `ok docs/a.md` **and** `skip docs/working/ign/nested/: not an allowed path form`; `--check-path '*'` and `'docs/*'` print the same extra line. `git ls-files --others --ignored` reports the nested repo as a directory entry under loose pathspec prefix matching. The trailing `/` gives an empty component, and pathform rejects it.

The guard fails closed, so this is not a bypass. The cost: the record's `## Skipped inputs` gets noise lines, and `n` is incremented, so a glob that matches nothing real prints the noise instead of `no tracked file … matches`.

**Recommendation:** In `matches`, drop entries ending in `/` before they are counted.

#### 5. Tests do not cover several refusals the code relies on

**Severity:** Informational
**Location:** `test/scripts/dev-cycle.bats` (tests 25, 26)
**Boundary:** B2, B4
**Move:** 11
**Confidence:** High
**Legibility-target:** test/scripts/dev-cycle.bats
**Evidence:** test 25 covers a symlinked *file* under docs/working, a directory, ignored-outside, untracked, `.git`/`.GIT`, `..`, `/`, `-x`, a quote, and `.g*`. These were not covered, and I exercised each by probe with a passing result: a tracked file under a working-tree **symlinked parent** (`docs/sub -> outside`: `skip docs/sub/b.md: reached through a symlink`), the same for a glob, `**`, a case variant (`DOCS/a.md` with `core.ignorecase=true` → skip), non-ASCII names (`docs/é.md` → skip under C and C.UTF-8), `--check-write` on an ignored path outside docs/working, and `--check-path --since x`.

**Recommendation:** Add the symlinked-parent case to test 25 and, with Finding 1's fix, a `--check-write` scope case.

#### 6. Keep-or-drop answers are read from repo text (S4); any reply that mentions both options is read as keep

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:245-252`
**Boundary:** B6
**Move:** 2
**Confidence:** Medium (read-static)
**Legibility-target:** SKILL.md step 6 In flight, item 2
**Evidence:** `` The option is the first `[1]` or `[2]` in`` / `` it (as in `Q-NNN: [1]`); with neither, an answer that is exactly `1`, `keep`, `2` or`` / `` `drop` (any case) and nothing else.``

"Not sure between [1] and [2]" parses as keep. That fails toward the brief keeping its slot, which is benign. Anyone who can land repo text can write a `Q-NNN:` line in questions.md, but this is inherent to keeping answers in the repo, and the consequence is limited to keeping or dropping a brief. One injection route is closed: the cycle embeds the brief path in its own entry ("keep or drop <brief path>?"), but a brief path passes the fixed charset, which has no `:`, space or `[`, so it cannot carry a fake `Q-NNN: [2]`.

**Recommendation:** None needed for security. Optionally, treat an answer that holds both `[1]` and `[2]` as unrecognized.

## Tested bypass candidates (move 11)

`--check-path` (pathform → git match → scope filter → pathform(m) → inrepo). Every candidate was executed:

| Candidate | Result |
|---|---|
| `/etc/passwd`, `../x`, `-x`, `a'b`, `docs/é.md` (C and C.UTF-8) | `not an allowed path form` |
| `.git/config`, `.GIT/config`, `.g*` matching `.gitignore` | form refused (pathform on input or on match) |
| `docs` (directory), `docs/working/ign` (ignored dir) | `no tracked file … matches` |
| `secret.txt` (ignored outside docs/working), `docs/untracked.md` | refused (scope) |
| `docs/working/rlink.md` (ignored symlink to a tracked file) | `reached through a symlink` |
| tracked `docs/sub/b.md` with `docs/sub` replaced by a symlink to outside; and `docs/sub/*` | `reached through a symlink` |
| untracked symlinked dir `docs/working/lnkdir/*`, `docs/working/lnkdir/a.md` | no match (git does not descend) |
| nested repo under ignored docs/working | dir entry refused by form (Finding 4 noise) |
| `DOCS/a.md`, `DOCS/*`, `Docs/Working/R1.md`, `docs/WORKING/*` with `core.ignorecase=true` (case-sensitive FS) | refused |
| `docs/*` vs `docs/sub/b.md` (`*` crossing `/`) | not matched (`:(glob)` semantics) |
| `--check-path --since x`; `--check-path a --check-write a` | trailing args treated as paths; `--since`/`--check-write` refused by form |
| `--check-write` with no path | exit 1, message |

`--check-write`: a symlinked parent (`docs/sub/b.md`, `docs/working/lnkdir/new.md`), a symlinked file, `.github/…` and a path into a nested `.git/` are refused. An existing directory (`docs/working`) is refused. A new file under a missing directory is `ok` (intended). Untracked and ignored paths anywhere are `ok` (Finding 2).

## Untested bypass candidates

- **Locale-dependent case folding in the `.git*` test** (`"${c,,}" != .git*`, dev-cycle.sh:155). Under `tr_TR.UTF-8`/`az_AZ.UTF-8`, bash `,,` may lower `I` to dotless `ı`, so `.GIT` would pass pathform. Not tested: those locales are not installed here. On a case-sensitive FS `.GIT` is not `.git`. For `--check-path`, the git scope check refuses it anyway. For `--check-write`, it would also need a case-insensitive FS and a write target from repo text (Finding 1). Fix: run pathform under `LC_ALL=C`, or test `[[ $c == [.][gG][iI][tT]* ]]`.
- **`[A-Za-z]` in the bash regex under a non-C UTF-8 locale.** Rejected `é` under C and C.UTF-8. `en_US.UTF-8` is not installed here, so collation-order ranges were not exercised. The impact is only non-ASCII letters, which still cannot break single quotes.
- **A case-insensitive filesystem** (macOS, NTFS, WSL `/mnt/c`). Untested: whether `realpath -e` returns the given case or the on-disk case. If it returns on-disk case, `rawfile` fails closed. If it returns the given case, `--check-write Docs/roadmap.md` passes the walk.
- **Check-to-open race.** The skill opens the file later. A symlink swapped in between needs local write access (the attacker controls the host), and the cycle does not switch trees between the digest and its reads, because the branch is created from the same HEAD. Not exercised.
- **Caller `GIT_ICASE_PATHSPECS` / `GIT_NOGLOB_PATHSPECS`** in the environment (S5, trusted). Interaction with the explicit `:(glob)`/`:(literal)` magic was not exercised.

Because of these candidates, pathform and the `inrepo`/`blocker` walk are reported as tested, not endorsed.

## Endorsement Claims

- **Claim:** `--check-path` and `--check-write` consume every following argument as a path. An option-looking argument (`--since`, `--check-write`) is reported `skip …: not an allowed path form` and never parsed as an option. No path argument at all exits 1.
  **Location:** `scripts/dev-cycle.sh:87-90`
  **Evidence:** executed
  **Verified:** `--since 2026-01-01 --check-path docs/a.md` → `ok docs/a.md`; `--check-path docs/a.md --check-write docs/a.md` → `ok docs/a.md` / `skip --check-write: not an allowed path form` / `ok docs/a.md`; `--check-write` → `--check-write needs at least one path`, rc=1.
  **Not verified:** `--check-path` given after `-h` (the `-h` arm exits before it; not run).
  **route: code-fact-check**
- **Claim:** The HEAD-tree fallback always passes git a root-relative `HEAD:docs/decisions/…` object name, because `$f` comes from the literal glob `docs/decisions/[0-9][0-9][0-9]-*.md` after `dirok docs/decisions`. A `./` or `../` prefix (cwd-relative in `<rev>:<path>`) cannot occur.
  **Location:** `scripts/dev-cycle.sh:269, 294`
  **Evidence:** read-static
  **Verified:** read the glob assignment (269), the loop (286-300) and the `cat-file -e "HEAD:$f"` line.
  **Not verified:** behavior for a record name containing `:` (allowed by the glob). Read-static: git takes the text after the first colon as the path, but this was not executed.
  **route: code-fact-check**
- **Claim:** The repo's own idea-source glob is admitted: `--check-path 'docs/working/feature-ideas*.md'` in wt-devcycle prints `ok docs/working/feature-ideas.md`, alongside `ok docs/roadmap.md` and `ok docs/dev-cycle.md`.
  **Location:** `docs/dev-cycle.md` idea-source row; `scripts/dev-cycle.sh:163-175`
  **Evidence:** executed
  **Verified:** run in /workspace/.claude/wt-devcycle (read-only).
  **Not verified:** ignored `feature-ideas-*.md` round files (none present in that worktree).

## Primitive sweep

Primitive: git pathspec / object-name evaluation (path traversal / pathspec magic)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `dev-cycle.sh:159` `git ls-files -z -- ":(glob|literal)$a"` | S1 via B1 | pathform(glob) charset (no `:`, `(`, `[`, `\`), explicit magic | cleared: executed probes |
| `dev-cycle.sh:160` `git ls-files --others --ignored …` | S1, S2 | same + `docs/working/*` filter on git's output | cleared; noise only (Finding 4) |
| `dev-cycle.sh:294` `git cat-file -e "HEAD:$f"` | S2 (decision record names) | literal `docs/decisions/` glob prefix | cleared (endorsement 2) |
| `dev-cycle.sh:295` `git log -1 … -- "$f"` | S2 | `GIT_LITERAL_PATHSPECS=1` | cleared: unchanged pre-existing guard |

Primitive: file open/read (agent, B3)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| SKILL.md:61-65 reads of repo-text paths | S1, S3 | `--check-path` ok lines | cleared for scope/symlinks; volume: Finding 3 |
| SKILL.md:237-252 In-flight brief read | S1 (roadmap) | `--check-path` | Finding 1 (any tracked file passes) |

Primitive: file write (agent, B4)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| record / new brief / idea log / roadmap | S6 | `--check-write` | cleared: fixed names, symlinks refused |
| In-flight brief edits (`Status:`, `Asked:`, `Applied:`, `Kept:`) | S1 | `--check-write` (no scope) | Finding 1 |

Primitive: shell command built from a repo-text path (agent → `dev-cycle.sh`)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| SKILL.md:66-68 `dev-cycle.sh --check-path '<path>'` | S1 | agent-side charset filter (no `'`, `$`, backtick, space) + single quotes; the script takes all args as paths | cleared: read-static. It depends on the agent applying the filter before quoting, but the charset leaves no character that can break single quotes |

Out of scope, noted only: SKILL.md:239 "Its branch merged into the default branch" uses a branch name taken from a brief (repo text) in a git command. This is pre-existing, outside this delta, and has no charset rule like the one the script's own `MAIN` handling applies (`dev-cycle.sh` "a branch named `--output=<path>`" comment).

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Brief-path shape rule removed; roadmap In-flight row can direct brief edits and commit to any tracked file | Medium | B1, B4 | `SKILL.md:61-73, 237-260`; `dev-cycle.sh:176-181` | Medium |
| 2 | Skill describes `--check-write` with the read scope; the write check has none | Low | B4 | `SKILL.md:69-71` | High |
| 3 | Unbounded glob (`**`) from a repo-text row; skill reads every match | Low | B1-B3 | `dev-cycle.sh:158-175`; `SKILL.md:64-65` | High |
| 4 | Nested repo under ignored docs/working yields spurious skip lines | Informational | B2 | `dev-cycle.sh:158-175` | High |
| 5 | Test gaps (symlinked parent, `**`, case, write scope) | Informational | B2, B4 | `dev-cycle.bats` 25-26 | High |
| 6 | Answers from repo text; a reply naming both options reads as keep | Informational | B6 | `SKILL.md:245-252` | Medium |

## Overall Assessment

The read gate is a real improvement. It closes all of pass 19's path findings, and every repo-controlled bypass I could construct against `--check-path` was refused: symlinks at file and parent depth, directories, untracked files, files ignored outside docs/working, `.git` in any ASCII case, odd characters, and globs crossing `/`. The remaining read-side candidates depend on the caller's locale or filesystem, not on repo text. The write side is one fix short. 46d3423 dropped the dated brief-path shape, and `--check-write` has no scope, so the one write target derived from repo text (an In-flight brief path in the roadmap) can now name any tracked file (Finding 1, Medium). The fix fits in place and matches this round's direction: put the allowed write targets, or the brief-path form, in code with a bats case. No findings beyond these within the code paths read; endorsement claims are pending execution verification.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."
This report is saved at `/workspace/.claude/wt-digest/docs/reviews/security-review-2026-10-02-digest-pass20.md`. It follows the security-reviewer structure: trust boundary map, source table, findings with the required fields, bypass enumeration, endorsements, primitive sweep, summary and assessment. It serves the user's goal (merge after a clean pass): Finding 1 is a known issue that blocks a clean pass, and Findings 2-6 are non-blocking.
