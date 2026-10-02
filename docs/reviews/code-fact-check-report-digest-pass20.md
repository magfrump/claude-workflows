Commit: 546b86e (A) / 46d3423 (B)

# Code Fact-Check Report

**Repository:** claude-workflows. A: `/workspace/.claude/wt-digest` (digest code at 546b86e; HEAD 13b9831 adds review docs only, `git diff --stat 546b86e HEAD -- scripts test` is empty). B: `/workspace/.claude/wt-devcycle` (content at 46d3423; HEAD 284a0cf only merges A in, `git diff --stat 46d3423 HEAD -- skills docs/dev-cycle.md` is empty).
**Scope:** Partial: the pass-19 fix round only. A: `git diff 1b0c4ff..546b86e -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus the message of 546b86e. B: `git diff 462e561..46d3423 -- skills/dev-cycle/SKILL.md docs/dev-cycle.md` plus the message of 46d3423. Everything else is context only.
**Checked:** 2026-10-02
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 26
**Summary:** 22 verified, 4 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

The hallucination pattern log (`docs/reviews/hallucination-patterns.md`, 8 entries) was read first. No claim below matches a logged pattern.

Execution logs (scratch, not committed) are under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc20/` (below, `fc20/`). Throwaway repos were built under one `mktemp -d` directory inside `fc20/` and removed after the probes. Every process ran under `timeout`; none outlived its command. Nothing was written to either worktree except this report.

Executed runs (times UTC):
- E1 `timeout 300 bats test/scripts/dev-cycle.bats` in `/workspace/.claude/wt-digest` at 2026-10-02T08:57:14Z, exit 0, 26/26 ok → `fc20/bats.log`. `timeout 60 shellcheck scripts/dev-cycle.sh` in the same directory at 08:58:55Z, exit 0, empty output → `fc20/shellcheck.log`. `bash scripts/dev-cycle.sh --help`, exit 0 → `fc20/help.log`.
- E2 `timeout 60 bash scripts/dev-cycle.sh --check-path 'docs/working/feature-ideas*.md' docs/working/idea-log.md docs/roadmap.md 'docs/**'` in `/workspace/.claude/wt-devcycle` at 08:57:21Z, exit 0 → `fc20/repo-check.log`.
- E3 probe repo 1 (throwaway, `git init`) at 08:57:42Z, every run exit 0 → `fc20/probe1.log`. Tracked files (including `docs/[ab].md`, `docs/A.MD`, `.gitignore`), ignored files under `docs/working/` (a file, a whole ignored directory, a symlink to `/etc/passwd`, a symlink to a tracked directory), ignored files elsewhere; globs `**`, `docs/*`, `docs/working/*`, `*/*/*`, `docs/?.md`; directory, trailing-slash, `./`, `//` forms; `--check-path --since x`; `--since=… --check-path`; `--check-write` cases.
- E4 probe repo 2 at ~08:58Z, exit 0 → `fc20/probe2.log`. A tracked file under a directory replaced by a symlink in the worktree, a tracked symlink, `docs/-x.md`, `docs?a.md`; the same inputs with `core.ignorecase=true` (`DOCS/F.md`, `docs/f*`, `.GITignore`, `Docs/*`); `:(glob)` and `:` in an argument.
- E5 probe repo 3 at ~08:58Z, `DEV_CYCLE_TODAY=2026-10-02 timeout 60 bash $DC --since=2026-08-01 | grep '^### '` → `fc20/probe3.log`. Records: quoted-name committed, plain committed, quoted-name committed then removed from HEAD, plain committed then removed from HEAD, quoted-name staged but uncommitted.

Legibility-target values: **agent** (the model that runs the skill or digest acts on the text), **maintainer** (someone editing the script or tests), **user** (the human reading the digest, record or commit log).

---

## Claim 1: "scripts/dev-cycle.sh --check-path PATH-OR-GLOB... / scripts/dev-cycle.sh --check-write PATH..." (the modes take every following argument)

**Location:** `scripts/dev-cycle.sh:9-10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers argument parsing for both modes (all following arguments become paths, options before the mode still parse, no paths exits 1); does not establish that the usage line tells a reader that options after the mode are treated as paths.

The parser stops at the mode and hands it the rest of argv:

```bash
# scripts/dev-cycle.sh:87-90
    --check-path|--check-write)
      CHECK="$1"; shift; CHECK_ARGS=("$@")
      [[ ${#CHECK_ARGS[@]} -gt 0 ]] || { echo "$CHECK needs at least one path" >&2; exit 1; }
      break ;;
```

E3: `--check-path --since x` printed `skip --since: not an allowed path form` and `skip x: no tracked file …`, exit 0; `--since=2026-01-01 --check-path docs/a.md` printed `ok docs/a.md`. E1's test 25 asserts that `--check-path` with no path exits 1. `--sample` is still validated first (`scripts/dev-cycle.sh:95`), which only matters if someone passes a bad `--sample` before the mode.

**Evidence:** `scripts/dev-cycle.sh:81-95`, `fc20/probe1.log`, `fc20/bats.log`

---

## Claim 2: "print "ok <path>" for each file that may be read (or written), "skip <arg>: <reason>" otherwise."

**Location:** `scripts/dev-cycle.sh:18-20`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the shape of every line the two modes print; does not establish anything about which paths pass (Claims 5-11).

`ok <path>` is right. A `skip` line names the argument only when the argument itself fails (form, no match). When a glob matches a file that then fails, the line names the match, not the argument:

```bash
# scripts/dev-cycle.sh:170-172
    if ! pathform "$m"; then echo "skip ${m//$'\n'/ }: not an allowed path form"
    elif ! inrepo "$m"; then echo "skip $m: reached through a symlink, or not a regular file"
    else echo "ok $m"; fi
```

(excerpt is inside the `while` loop of `check_path()`, which continues to :175 — read.) E3: `--check-path 'docs/working/*'` printed `skip docs/working/ign-etc: reached through a symlink, or not a regular file`. The precise wording would be "skip <arg or match>: <reason>". Wording only: an agent that reads the line still sees which path was refused.

**Evidence:** `scripts/dev-cycle.sh:163-175`, `fc20/probe1.log`

---

## Claim 3: "Read-only: writes nothing to the repo (one temp file, removed on exit). Exit: 0 digest printed; 1 bad usage, not a git repo, no default branch or no perl"

**Location:** `scripts/dev-cycle.sh:25-27`
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the header's read-only and exit-code lines as they apply to the new modes; does not re-verify the digest path's exit codes (context, not in this round).

Read-only holds for both modes: `check_path` runs only `git ls-files` and file tests, and `check_write` only `blocker` (`scripts/dev-cycle.sh:158-181`). The exit line was not updated: the modes exit 0 with no digest printed, every time they get at least one path:

```bash
# scripts/dev-cycle.sh:182-187
if [[ -n "$CHECK" ]]; then
  for a in "${CHECK_ARGS[@]}"; do
    if [[ "$CHECK" == --check-path ]]; then check_path "$a"; else check_write "$a"; fi
  done
  exit 0
fi
```

The precise wording would be "0 digest (or check lines) printed". Wording only.

**Evidence:** `scripts/dev-cycle.sh:22-27`, `scripts/dev-cycle.sh:158-187`

---

## Claim 4: "The path rule for repo text (commit messages, plans, settings rows, roadmap brief paths), so the skill runs it instead of re-deriving it in prose"

**Location:** `scripts/dev-cycle.sh:140-141`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers that the skill at 46d3423 calls these modes for the listed sources; does not establish that the installed copy (`~/.claude/scripts/dev-cycle.sh`, absent in this sandbox) carries the modes.

The skill's rule now reads: "open a file named by repo text (a settings row or glob, a brief path in the roadmap, any file a commit message, decision-log row, plan or question names …) only after `dev-cycle.sh --check-path '<path or glob>' …` prints `ok <path>`" (`skills/dev-cycle/SKILL.md:61-65`). The old prose checks 1-3 are gone from the skill (`git diff 462e561..46d3423`).

**Evidence:** `scripts/dev-cycle.sh:140-147`, `skills/dev-cycle/SKILL.md:61-73`

---

## Claim 5: "form: only letters, digits, . _ - / (and * ? in a glob), not starting with / or -, no empty or .. component, no component starting .git (any case)"

**Location:** `scripts/dev-cycle.sh:142-143`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers `pathform()` on the argument and on each match; does not establish that `.` components are refused (they pass the form; `./docs/a.md` and `docs/./a.md` then match nothing), nor that `.github/` and `.gitkeep` are wanted refusals (they are refused).

```bash
# scripts/dev-cycle.sh:148-157
pathform() {  # $1 path, $2 "glob" to allow * and ?
  local p="$1" rest c set='^[A-Za-z0-9._/-]+$'
  [[ "${2:-}" == glob ]] && set='^[A-Za-z0-9._/*?-]+$'
  [[ "$p" =~ $set && "$p" != /* && "$p" != -* ]] || return 1
  rest="$p/"
  while [[ -n "$rest" ]]; do
    c="${rest%%/*}"; rest="${rest#*/}"
    [[ -n "$c" && "$c" != ".." && "${c,,}" != .git* ]] || return 1
  done
}
```

E3/E4 refused `docs/working/` and `docs//a.md` (empty component), `.GITignore`, `:(glob)docs/*`, `docs/F.md:x`, and a tracked `docs/[ab].md` reached through a glob. `[` is outside both sets, so git's bracket syntax cannot reach a pathspec. E2: the real repo's `docs/working/rounds/.gitkeep` is refused as `.git*`.

**Evidence:** `scripts/dev-cycle.sh:148-157`, `fc20/probe1.log`, `fc20/probe2.log`, `fc20/repo-check.log`

---

## Claim 6: "scope (reads): a tracked file, or a gitignored file under docs/working/ (the cycle's own working files); never any other untracked or ignored file"

**Location:** `scripts/dev-cycle.sh:144-145`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers `matches()` plus the plain-path filter with `core.ignorecase` false and true on a case-sensitive filesystem; does not establish behavior on a case-insensitive filesystem (macOS, Windows), nor that "tracked" means committed (it means in the index: a staged new file passes).

```bash
# scripts/dev-cycle.sh:158-162
matches() {  # $1 pathspec; NUL-separated tracked files, then ignored ones under docs/working/
  GIT_LITERAL_PATHSPECS=0 git ls-files -z -- "$1"
  GIT_LITERAL_PATHSPECS=0 git ls-files -z --others --ignored --exclude-standard -- "$1" \
    | while IFS= read -r -d '' m; do [[ "$m" == docs/working/* ]] && printf '%s\0' "$m"; done
}
```

E3: ignored `secret.md` and ignored `docs/x/secret-inner.md` were refused ("no tracked file … matches"), even under `**`; ignored `docs/working/ign1.md` and `docs/working/ignd/f.md` (inside a wholly ignored directory) passed. E4 with `core.ignorecase=true`: `docs/f.md`, `DOCS/F.md`, `docs/f*` and `Docs/*` all matched nothing (the tracked file is `docs/F.md`), so case variants do not widen the match.

**Evidence:** `scripts/dev-cycle.sh:158-175`, `fc20/probe1.log`, `fc20/probe2.log`

---

## Claim 7: "plain: a regular file reached without any symlink (inrepo)"

**Location:** `scripts/dev-cycle.sh:146`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers each match that `check_path` prints `ok` for, at the moment of the check; does not establish that the file is still plain when the agent later opens it (a check-then-open gap, outside this script).

Each match goes through `inrepo` (`scripts/dev-cycle.sh:171`), which walks the path with `blocker` and then requires `-f` (`scripts/dev-cycle.sh:115-129`). E4: a tracked `docs/sub/f.md` whose directory was replaced by a symlink in the worktree, and a tracked symlink `docs/l.md`, were both refused. E3: an ignored symlink to `/etc/passwd` and an ignored symlink to a tracked directory were refused, and `docs/working/ignlink/b/c.md` (through that symlink) matched nothing, because `git ls-files --others` does not descend into a symlinked directory.

**Evidence:** `scripts/dev-cycle.sh:115-129`, `scripts/dev-cycle.sh:163-175`, `fc20/probe1.log`, `fc20/probe2.log`

---

## Claim 8: "Globs are matched by git (":(glob)"), never by a shell."

**Location:** `scripts/dev-cycle.sh:147`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers how a glob argument becomes a pathspec and what `*`, `?` and `**` match; does not establish how the calling agent's own shell treats the argument (Claim 21).

```bash
# scripts/dev-cycle.sh:166
  if [[ "$a" == *[*?]* ]]; then spec=":(glob)$a"; else spec=":(literal)$a"; fi
```

The argument is never expanded by bash: it is quoted at every use, and the `[[ == ]]` tests quote their right-hand side where it is the argument (`scripts/dev-cycle.sh:168`). E3: under `:(glob)`, `docs/working/*` did not match `docs/working/sub/deep.md` (`*` stops at `/`), `docs?a.md` matched nothing (`?` stops at `/`), and `**` matched every tracked file and every ignored file under `docs/working/`, each then filtered by form and plainness. `GIT_LITERAL_PATHSPECS=0` is set per call so the `:(glob)` magic is honored even though the script exports `=1` (`scripts/dev-cycle.sh:138`).

**Evidence:** `scripts/dev-cycle.sh:138`, `scripts/dev-cycle.sh:158-175`, `fc20/probe1.log`, `fc20/probe2.log`

---

## Claim 9: "NUL-separated tracked files, then ignored ones under docs/working/"

**Location:** `scripts/dev-cycle.sh:158`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the order and separator of `matches()` output; does not establish de-duplication (none is needed: `--others` excludes tracked files).

Quoted in Claim 6 (`scripts/dev-cycle.sh:158-162`). E3's `**` output lists the tracked files first, then `docs/working/ign1.md`, `ignd/f.md` and the two ignored symlinks.

**Evidence:** `scripts/dev-cycle.sh:158-162`, `fc20/probe1.log`

---

## Claim 10: "a plain path names one file, not a directory" (commit 546b86e: "A plain path must name one file (a tracked directory no longer passes).")

**Location:** `scripts/dev-cycle.sh:168`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers non-glob arguments that name a directory; does not establish behavior for a glob whose pattern names a directory (`ls-files` lists files only, so a directory is never printed `ok` either way).

```bash
# scripts/dev-cycle.sh:168
    [[ "$a" == *[*?]* || "$m" == "$a" ]] || continue  # a plain path names one file, not a directory
```

E3: `docs/working` and `docs` printed "no tracked file … matches"; E1 test 25 asserts `skip docs: no tracked file`.

**Evidence:** `scripts/dev-cycle.sh:163-175`, `fc20/probe1.log`, `test/scripts/dev-cycle.bats:468-493`

---

## Claim 11: "--check-write PATH...: same form, and no symlink or wrong-kind part on the way to the file." (commit 546b86e)

**Location:** `scripts/dev-cycle.sh:176-181`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers form (without `*`/`?`) and the blocker walk; does not establish any scope limit (it allows any plain path in the repo, tracked or not, existing or not: see Claim 22) or that the path is still plain when written.

```bash
# scripts/dev-cycle.sh:176-181
check_write() {
  local a="$1"
  if ! pathform "$a"; then echo "skip ${a//$'\n'/ }: not an allowed path form"
  elif [[ -n "$(blocker "$a" file)" ]]; then echo "skip $a: reached through a symlink, or not a regular file"
  else echo "ok $a"; fi
}
```

E3: `docs/a.md` (existing) and `docs/working/new/x.md` (absent parents) → ok; `docs` (directory), `docs/a.md/x` (file as parent), `docs/working/ignlink/x` (symlinked parent), `docs/*`, `.gitignore` → skip.

**Evidence:** `scripts/dev-cycle.sh:115-125`, `scripts/dev-cycle.sh:176-181`, `fc20/probe1.log`

---

## Claim 12: "instead of a digest" (modes run before any digest work; output still goes through the scrub)

**Location:** `scripts/dev-cycle.sh:18`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the order of the re-exec scrub, argument parsing, the check block and the default-branch lookup; does not establish anything about the scrub's own coverage (context).

The scrub wrapper re-executes the script before any parsing (`if [[ -z "${DEV_CYCLE_SCRUBBED:-}" ]]; then { DEV_CYCLE_SCRUBBED=1 bash "${BASH_SOURCE[0]}" "$@" … | scrub; }`, `scripts/dev-cycle.sh:72-75`), so check output is scrubbed. The check block exits at `scripts/dev-cycle.sh:186`, before `# Pass git only a hash for the default branch` at :188, so no digest step runs. It runs after `cd "$ROOT"` (:99), so paths are taken from the repo root whatever the caller's cwd.

**Evidence:** `scripts/dev-cycle.sh:72-75`, `scripts/dev-cycle.sh:97-99`, `scripts/dev-cycle.sh:182-190`

---

## Claim 13: "A name git still quotes … misses the map and, if it is in HEAD, falls back to its own lookup."

**Location:** `scripts/dev-cycle.sh:272-273`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers quoted names in and out of HEAD; does not establish the date the lookup returns around merges (context, pass 18).

```bash
# scripts/dev-cycle.sh:294-296
  if [[ -z "${last_date[$f]+set}" ]] && git cat-file -e "HEAD:$f" 2>/dev/null; then
    d="$(git log -1 --format=%ad --date=short -- "$f")"
  fi
```

(excerpt is inside the record loop, which continues to :300 — read; `d` is first used at :298.) E5: `001-a"b.md` (committed, in HEAD) printed `2026-09-01`.

**Evidence:** `scripts/dev-cycle.sh:268-300`, `fc20/probe3.log`

---

## Claim 14: "One absent from HEAD prints "never, uncommitted" without a full walk to prove it (~1 s per record on a 220k-commit repo); that is also what a record committed earlier and since removed from HEAD shows."

**Location:** `scripts/dev-cycle.sh:290-293`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers records absent from HEAD with quoted and plain names; does not re-measure the ~1 s figure (pass 18 context).

Both statements hold only for a name that missed the map (a quoted name), which is the only case that reaches the `cat-file` test (Claim 13's excerpt, `scripts/dev-cycle.sh:294`). A plain-named record removed from HEAD is still in the map, built from a walk over all history of `docs/decisions` (`scripts/dev-cycle.sh:280-282`), and prints the date of the map's newest commit touching it. E5: `003-rm"q.md` (quoted, removed) → `never, uncommitted`; `004-rm.md` (plain, removed) → `2026-09-05`, the removal commit's date; `005-st"g.md` (staged, never committed) → `never, uncommitted`. The precise wording would start "A quoted name absent from HEAD …". Wording only: the code path the comment sits on behaves as stated.

**Evidence:** `scripts/dev-cycle.sh:278-298`, `fc20/probe3.log`

---

## Claim 15: "The record-date fallback checks HEAD's tree (one object lookup), so a staged-but-uncommitted record no longer walks all history." (commit 546b86e)

**Location:** `scripts/dev-cycle.sh:294`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers that no `git log` runs for a staged quoted-name record; does not establish timing (not measured) or that any test pins it (none of the 26 stages a quoted record).

The `git log -1` call is guarded by `git cat-file -e "HEAD:$f"` (Claim 13's excerpt), which fails for a staged-only path. E5: `005-st"g.md` printed `never, uncommitted`.

**Evidence:** `scripts/dev-cycle.sh:290-296`, `fc20/probe3.log`

---

## Claim 16: "Tests: both modes, including the security and API cases from pass 19 (glob row, directory, .GIT, untracked/ignored outside docs/working, symlinked ignored file, quotes). 26/26; shellcheck clean." (commit 546b86e)

**Location:** `test/scripts/dev-cycle.bats:468-506`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers that each named case is in the two new tests and that the suite and shellcheck pass; does not establish coverage of `**`, `core.ignorecase`, a symlinked parent of a tracked file, or the HEAD-tree fallback (E3-E5 checked these by hand).

The first test runs `--check-path 'docs/working/*.md' docs/decisions/001-x.md docs .env docs/untracked.md .git/config .GIT/config '../x' /etc/passwd -x "a'b" '.g*' docs/working/round-2.md` and asserts `"skip docs: no tracked file"`, `"skip .GIT/config: not an allowed path form"`, `"skip a'b: not an allowed path form"`, `"skip docs/working/round-2.md: reached through a symlink"` among others (`test/scripts/dev-cycle.bats:479-488`). E1: `1..26`, 26 `ok`, exit 0; shellcheck exit 0, empty output.

**Evidence:** `test/scripts/dev-cycle.bats:468-506`, `fc20/bats.log`, `fc20/shellcheck.log`

---

## Claim 17: "Notes: .gitignore and similar .git* files are refused by design." (commit 546b86e)

**Location:** `scripts/dev-cycle.sh:155`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers files and directories whose component starts `.git` in any case; does not establish whether refusing `.github/…` and `.gitkeep` is wanted (they are refused).

`[[ -n "$c" && "$c" != ".." && "${c,,}" != .git* ]] || return 1` (`scripts/dev-cycle.sh:155`). E3: `skip .gitignore: not an allowed path form` under `**` and `--check-write .gitignore`; E2: `skip docs/working/rounds/.gitkeep: not an allowed path form` in the real repo.

**Evidence:** `scripts/dev-cycle.sh:148-157`, `fc20/probe1.log`, `fc20/repo-check.log`

---

## Claim 18: "Each row is passed to `dev-cycle.sh --check-path`, which allows tracked files and gitignored files under `docs/working/` (so the self-improvement loop's ignored round files count), never a symlink, `..`, `.git*` or any other untracked file. Paths use only letters, digits, `.`, `_`, `-`, `/`, and `*` or `?` in a glob."

**Location:** `docs/dev-cycle.md:27-30`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the summary against the script and the file's own row `docs/working/feature-ideas*.md`; does not establish that ignored round files exist in this checkout (none do in wt-devcycle; the ignored case was run in E3).

The row passes: E2 printed `ok docs/working/feature-ideas.md` for `'docs/working/feature-ideas*.md'`. The round files are ignored by `.gitignore:28` (`docs/working/feature-ideas-round-*.md`) and the glob covers them; E3 shows an ignored file under `docs/working/` printed `ok`. The rest matches Claims 5-7.

**Evidence:** `docs/dev-cycle.md:24-33`, `.gitignore:28`, `fc20/repo-check.log`, `fc20/probe1.log`

---

## Claim 19: "only after `dev-cycle.sh --check-path '<path or glob>' …` prints `ok <path>` for it, and open exactly those paths."

**Location:** `skills/dev-cycle/SKILL.md:61-65`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers that the instruction matches what the mode prints (one `ok <path>` line per allowed file, with the repo-root-relative path); does not establish which `dev-cycle.sh` the agent runs (step 0 names `~/.claude/scripts/dev-cycle.sh`, absent in this sandbox, or the repo's own copy).

The mode prints `ok $m` (`scripts/dev-cycle.sh:172`), where `$m` is the path git listed from the repo root; `$m` has passed the strict form, so the scrub cannot alter it. E2 and E3 show `ok <path>` lines for both single paths and globs.

**Evidence:** `skills/dev-cycle/SKILL.md:61-65`, `scripts/dev-cycle.sh:163-175`, `fc20/repo-check.log`

---

## Claim 20: "Before writing a file (the record, a brief, the idea log, the roadmap), run `dev-cycle.sh --check-write '<path>'` and write only on `ok`."

**Location:** `skills/dev-cycle/SKILL.md:65-66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers that the mode exists and passes the skill's fixed write names under plain directories; does not establish anything about `questions.sh init/archive`, which write through their own script (step 1).

E1 test 26 prints `ok docs/working/cycles/cycle-2026-01-01.md` and refuses a brief path under a symlinked `docs/working/briefs` and a symlinked `docs/roadmap.md` (`test/scripts/dev-cycle.bats:495-506`). All four fixed names (`docs/working/cycles/cycle-YYYY-MM-DD.md`, `docs/working/briefs/YYYY-MM-DD-<slug>.md` with a lowercase-digit-hyphen slug, `docs/working/idea-log.md`, `docs/roadmap.md`) are inside the form.

**Evidence:** `skills/dev-cycle/SKILL.md:65-66`, `skills/dev-cycle/SKILL.md:272`, `test/scripts/dev-cycle.bats:495-506`, `fc20/bats.log`

---

## Claim 21: "Pass a path to the check only if it uses letters, digits, `.`, `_`, `-`, `/`, `*` and `?` and nothing else (otherwise skip it without running anything), in single quotes."

**Location:** `skills/dev-cycle/SKILL.md:66-68`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers that a path meeting the pre-filter, single-quoted, reaches the script as one literal argument and cannot act as an option; does not establish that the agent applies the pre-filter (prose compliance).

Inside single quotes none of the eleven allowed characters is special to the shell (no `'`, `\`, `$`, space or newline can appear), and `*`/`?` are not expanded. A leading `-` cannot act as an option: the mode takes every following argument as a path (Claim 1), and E3 shows `--since` after `--check-path` refused as a form. The script's own form check is a superset of this filter (`scripts/dev-cycle.sh:148-157`), so nothing the pre-filter lets through is misparsed.

**Evidence:** `skills/dev-cycle/SKILL.md:66-68`, `scripts/dev-cycle.sh:87-90`, `scripts/dev-cycle.sh:148-157`, `fc20/probe1.log`

---

## Claim 22: "The check allows tracked files and gitignored files under `docs/working/`, never a symlink, a directory, `..`, `.git*` or any other untracked file"

**Location:** `skills/dev-cycle/SKILL.md:68-71`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the sentence as it applies to each of the two checks it follows; does not establish whether `--check-write` should be scoped (a design question).

For `--check-path` the sentence is exact (Claims 5-7, 10). It follows the `--check-write` sentence, though, and for that mode it is wrong: `check_write` has no scope test (Claim 11's excerpt, `scripts/dev-cycle.sh:176-181`), so it allows any plain path in the repo, untracked and absent ones included (E3: `ok docs/working/new/x.md`), and tracked files outside the cycle's set (E3: `ok docs/a.md`). The precise wording would be "`--check-path` allows …; `--check-write` allows any path in the repo with that form and no symlink or non-directory on the way". Wording: an agent that reads "the check" as covering writes would expect a refusal the script never gives, but the skill only writes its four fixed names.

**Evidence:** `skills/dev-cycle/SKILL.md:61-73`, `scripts/dev-cycle.sh:176-181`, `fc20/probe1.log`

---

## Claim 23: "If the digest says the repo has no `docs/working/questions.md`, step 1 creates it unless section 8 blocks the path."

**Location:** `skills/dev-cycle/SKILL.md:106-107`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers consistency with step 1's skip rule; does not establish what the digest prints in section 8 (context, verified in earlier passes).

Step 1: "If the digest's section 8 lists `docs/`, `docs/working/` or a questions file, skip the next two commands and note why in the record: they would write through that path" (`skills/dev-cycle/SKILL.md:130-131`). Those are exactly the parts that can block `docs/working/questions.md`.

**Evidence:** `skills/dev-cycle/SKILL.md:106-107`, `skills/dev-cycle/SKILL.md:130-135`

---

## Claim 24: "The option is the first `[1]` or `[2]` in it (as in `Q-NNN: [1]`); with neither, an answer that is exactly `1`, `keep`, `2` or `drop` (any case) and nothing else." (commit 46d3423: '"2 more weeks" no longer drops')

**Location:** `skills/dev-cycle/SKILL.md:245-249`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the commit's claim and the rule on bracketed answers; does not establish how an agent strips an `**Answered YYYY-MM-DD:**` label or a trailing period before applying "exactly … and nothing else", nor what happens when an answer mentions `[1]` before the real choice (the first bracket wins).

"2 more weeks" has no bracket and is not exactly `2`, so it is unrecognized, listed in the record and the final message, and added to `Applied:` (`skills/dev-cycle/SKILL.md:250-253`). Real answer lines in this repo carry a label, e.g. `**Answered 2026-09-17: [2] — "option 2 seems good and easy". …**` and `- **Answer (2026-10-01, in chat):** [1].` (`docs/working/questions-archive.md`, grep for `Answer`); the bracketed forms parse as intended. An un-bracketed `**Answered 2026-10-02: keep.**` is "keep" only if the agent drops the label and the period; the rule does not say. Unrecognized answers are re-asked, not misapplied.

**Evidence:** `skills/dev-cycle/SKILL.md:241-253`, `docs/working/questions-archive.md` (Answer lines)

---

## Claim 25: "Then send the final message: list the new `you: judgment` entries by ID and name, any keep-or-drop answer step 6 could not read, and each open build brief by path" (commit 46d3423: "Unread answers go in the final message too.")

**Location:** `skills/dev-cycle/SKILL.md:310-311`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers consistency between step 6 and step 7; does not establish anything about the record's own section for them (step 6 says "list it in the record", with no named heading).

Step 6 already says "anything else is unrecognized: list it in the record and the final message so the user can answer again" (`skills/dev-cycle/SKILL.md:251-252`); step 7's list now names them.

**Evidence:** `skills/dev-cycle/SKILL.md:250-253`, `skills/dev-cycle/SKILL.md:310-313`

---

## Claim 26: "The prose rule is replaced by: open a repo-text path only on `dev-cycle.sh --check-path` "ok", write only on `--check-write` "ok", pass only fixed-charset paths, single-quoted; never touch what section 8 lists; scratch output to $TMPDIR. … Step 0's "step 1 creates it" notes the section-8 exception; docs/dev-cycle.md describes the check and the scope." (commit 46d3423)

**Location:** `skills/dev-cycle/SKILL.md:61-73`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** user
**Scope:** Covers that each listed change is in the diff; does not establish that the dropped brief-path shape rule ("A brief path counts only as `docs/working/briefs/YYYY-MM-DD-<slug>.md` … in backticks", removed by this diff) has a replacement: a roadmap brief path is now read if `--check-path` allows it, wherever it points in scope.

Each item is present: `--check-path` (:64), `--check-write` (:66), the charset and single quotes (:66-68), "Never read, write or append through anything the digest's section 8 lists" (:71-72), "goes to the usual temp directory (`$TMPDIR`), not the repo" (:72-73), the section-8 exception (:107), and the settings-file paragraph (`docs/dev-cycle.md:27-30`).

**Evidence:** `skills/dev-cycle/SKILL.md:61-73`, `skills/dev-cycle/SKILL.md:107`, `docs/dev-cycle.md:27-30`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 2** (`scripts/dev-cycle.sh:18-20`): a `skip` line for a glob match names the match, not the argument; say "skip <arg or match>". Wording.
- **Claim 3** (`scripts/dev-cycle.sh:26-27`): the exit line says "0 digest printed"; the check modes exit 0 with no digest. Wording.
- **Claim 14** (`scripts/dev-cycle.sh:290-293`): "One absent from HEAD prints never, uncommitted" holds only for quoted names; a plain-named record removed from HEAD prints its map date (E5: `2026-09-05`). Wording.
- **Claim 22** (`skills/dev-cycle/SKILL.md:68-71`): "The check allows tracked files and gitignored files under docs/working/" describes `--check-path` only; `--check-write` allows any plain in-repo path, untracked included. Wording.

### Unverifiable
(none)

---

## Goal-Alignment Note

- Success criterion (restated verbatim): a markdown report saved at the path your role instructions give, structured per your skill file.

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass20.md`. It has the required first line, the header fields (including `**Replication:** k=1 (loop pass, decision 031)`), the seven mandatory per-claim fields plus `**Legibility-target:**`, and the attention summary.

Against the brief's priority list:
- **A, getting `ok` for something that should be refused:** no case found. Refused, as they should be: outside the repo, `.git`/`.GIT`, untracked files, ignored files outside `docs/working/` (even under `**`), symlinks at the leaf, at a worktree parent of a tracked file, and as ignored links to files and to directories, directories, odd characters, `[`, `:(glob)` smuggled in, and case variants with `core.ignorecase=true` (E3, E4).
- **A, refusing something that should pass:** tracked files with allowed names, ignored `docs/working` files (including inside a wholly ignored directory) and the repo's own idea-source glob all pass (E2, E3). By design, `.gitignore`, `.github/…` and `.gitkeep` are refused (Claim 17).
- **A, option parsing:** the modes take every following argument; `--check-path --since x` treats both as paths (Claim 1).
- **A, HEAD-tree fallback:** works as the commit says (Claims 13, 15). The comment overstates which removed records print "never" (Claim 14). No test stages a quoted record.
- **A, tests and 546b86e:** 26/26, shellcheck clean, every named case present (Claim 16).
- **B, skill against the modes:** the instructions match what the modes print. The single-quoted, pre-filtered call has no injection or option hole (Claim 21). The scope sentence reads as covering `--check-write` too (Claim 22). The old brief-path shape rule was dropped without replacement (Claim 26 residue).
- **B, answer parsing:** right for bracketed answers and for "2 more weeks". It leaves open how to treat a labelled un-bracketed answer such as `**Answered …: keep.**` (Claim 24 residue). Such answers are re-asked, not misapplied.
