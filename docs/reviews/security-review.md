# Security Review — CRB direction-1 harness, containment reset/void rework

**Scope:** `git diff 59733d8..HEAD -- . ':!docs/reviews'` on `feat/crb-direction1-harness` (commits `cf6e7c9`, `5bd0b09`, `46a5f17`)
**Commit:** 46a5f17
**Date:** 2026-08-18
**Based on:** iteration-2 code-fact-check (5 Incorrect findings, all doc/comment mechanism errors, closed in 46a5f17); prior review item R3 (container egress) treated as known and out of verdict scope
**Position:** iteration 2 of a 3-iteration review-fix loop, ahead of a $50–2000 sweep over 50 third-party repositories

> ⚠️ **No code fact-check report was attached to this invocation.** The orchestrator supplied a
> *summary* of the iteration-2 fact-check's Incorrect findings, which I have taken as given and
> not re-verified. Claims in comments outside those five items are not independently verified;
> where a comment's security claim is load-bearing below, I read or executed the mechanism myself
> and say so.

---

> 🚨 **HALT — ESCALATE TO HUMAN**
>
> **Pattern:** Command execution from untrusted content (escalation pattern 3, extended from
> "injection in user-facing code" to "attacker-influenced repository content executed host-side")
> **Location:** `scripts/crb-materialize.py:348` (`git checkout --force`), `runs/review-arms/crb-pipeline/run-host.sh:344` (`git status`)
> **Detail:** The review container is given a read-write bind mount of the *entire clone including
> `.git`*, runs with `--dangerously-skip-permissions`, and then the host runs `git status`,
> `git checkout --force`, `git reset --hard`, `git clean -qfdx` against that same directory.
> I demonstrated four independent host-side code-execution paths from container-writable
> `.git` content: `.git/hooks/post-checkout`, `.git/hooks/reference-transaction`,
> `core.fsmonitor`, and `core.hooksPath` — all fired as the invoking host user (uid 1000) in a
> local reproduction. A fifth, `core.worktree`, made `git clean -qfdx` delete files in an
> arbitrary host directory.
>
> This finding requires immediate human attention before the remaining review is actionable.
> Do not run the sweep until this is resolved.

> 🚨 **HALT — ESCALATE TO HUMAN**
>
> **Pattern:** Destructive host-side file operation driven by untrusted config (same root cause,
> distinct impact — a fix that only removes hooks does not close it)
> **Location:** `scripts/crb-materialize.py:357` (`git clean -qfdx`)
> **Detail:** With `core.worktree` set in the container-writable `.git/config`, `reset_clone()`'s
> `git checkout --force` / `reset --hard` / `clean -qfdx` operate on the redirected directory.
> In my reproduction this deleted every untracked file under an unrelated host path and wrote the
> clone's tracked files there instead.

---

## Trust Boundary Map

```
B1 (moved):   [third-party repo + reviewing agent, in container]
                → [RW bind mount of $clone INCLUDING .git]
                → [host-side git subprocesses in reset_clone()/harvest]  → [host user account]
B2 (new):     [container-written .git/config, .git/hooks/, .gitattributes]
                → [NO validation — nothing inspects .git before running git]
                → [git's own config/hook/filter resolution on the host]
B3:           [agent network egress + git object store]
                → [fetch_traces() + classify_strays() reset-vs-void verdict]
                → [benchmark score / published recall number]
B4:           [agent-created files in the clone worktree]
                → [porcelain -z parse + `/*|*..*` guard + `cp --no-dereference`]
                → [tracked artifacts dir under runs/]
B5:           [operator argv slug → run-host.sh $@ → --reset SLUG]
                → [`DST_ROOT / slug` + manifest-entry gate]
                → [host filesystem path / shutil-free read-write git ops]
B6:           [run-meta.json + evaluations.json]
                → [attrition() in crb-subset-leaderboard.py]
                → [numbers pasted into a results doc]
```

The diff's central move is on **B3**: what used to be a binary "any stray commit voids" is now a
two-way split (reset benign agent work, void on contamination evidence). That is a genuine
improvement in availability and it is well tested. But the diff also *increases traffic across
B1/B2* — `--verify` was read-only (`rev-list`, `remote`, `diff`), while `--reset` adds
`checkout --force`, `reset --hard`, `branch -f`, `update-ref -d`, `clean -qfdx`, `gc`,
`symbolic-ref -d`. Every one of those is a git command that honours hooks, `core.fsmonitor`,
`core.worktree`, and clean/smudge filters — all of which live inside the directory the container
just had unrestricted write access to. B2 is the boundary the diff created and did not defend.

---

## Findings

#### Host-side arbitrary code execution from container-writable `.git/hooks` and `.git/config`

**Severity:** Critical
**Location:** `scripts/crb-materialize.py:348-361`, `runs/review-arms/crb-pipeline/run-host.sh:344`, mount at `run-host.sh:276`
**Boundary:** B1, B2
**Move:** #1 (trace the trust boundaries), #2 (implicit sanitization assumption)
**Confidence:** High (executed)

The container mounts the whole clone read-write:

```
    -v "$clone":/repo \
```

and runs `--dangerously-skip-permissions` over third-party repository content whose repo-local
instructions load as they would for any real user (`run-host.sh:36`). Nothing restricts writes to
the worktree — `/repo/.git` is equally writable. The host then runs, against that same directory:

```
    sh(["git", "checkout", "--force", "--quiet", "-B", "review", head], cwd=dst)
    sh(["git", "reset", "--hard", "--quiet", head], cwd=dst)
    sh(["git", "branch", "--quiet", "-f", "main", base], cwd=dst)
```

and earlier, in the harvest loop:

```
  done < <(git -C "$clone" status --porcelain=v1 -z --untracked-files=all)
```

I reproduced four execution paths locally, each firing as the invoking host user:

| Mechanism | Trigger in this code | Observed |
|---|---|---|
| `.git/hooks/post-checkout` | `git checkout --force -B review` | `PWNED-post-checkout 1000` |
| `.git/hooks/reference-transaction` | `checkout -B`, `reset --hard`, `branch -f`, `update-ref -d` | fired 8× across the reset sequence |
| `core.fsmonitor = <path>` in `.git/config` | `git status --porcelain` (harvest, and `reset_clone`'s `dirty` probe) | `PWNED-fsmonitor` |
| `core.hooksPath = <dir>` in `.git/config` | any hook-bearing command | `PWNED-hookspath` |
| `filter.X.smudge` + `.gitattributes` | `git checkout --force` repopulating the worktree | `PWNED-smudge` |

The `.gitattributes`/smudge variant is the nastiest, because `.gitattributes` is *tracked content*
— a hostile benchmark fork could carry it without the agent doing anything, and it only needs the
paired `filter.X.smudge` in `.git/config`, which the agent can write.

Reachability is immediate: the harvest `git status` runs the moment the container exits, and the
next cell's pre-run `--reset` (`run-host.sh:262`) runs the full sequence. The host shell has
`ANTHROPIC_API_KEY` exported (`run-host.sh:109`) and write access to the repository, `~/.claude`,
and Docker. This is not "attacker already controls the host" — the attacker controls a *benchmark
repository*, which is exactly the input the harness is designed to ingest 50 of.

**Recommendation:** Do three things, in order of how much they buy. (1) Stop giving the container
`.git`: mount the worktree at `/repo` and keep the git directory outside the container (e.g.
`git --separate-git-dir`, or a bind mount of a `.git` copy that is discarded and rebuilt per cell),
so B2 stops existing. (2) Until then, run *every* host-side git command against these clones with
hardening flags — `git -c core.fsmonitor= -c core.hooksPath=/dev/null -c core.worktree= -c
protocol.file.allow=never -c core.symlinks=false …` — and add `GIT_CONFIG_NOSYSTEM=1`. Note that
`-c` overrides do beat repo config, but this is a denylist and needs re-auditing per git version.
(3) Add a pre-git sanitisation step in `reset_clone()` that runs *before* the first git invocation:
delete `.git/hooks/*`, and reset `.git/config` from a pristine copy stashed at materialize time.
Treat any modification to `.git/config`/`.git/hooks` as a *void* condition, not something to
quietly repair — it is far better evidence of contamination than FETCH_HEAD is.

---

#### `core.worktree` in the mounted `.git/config` redirects `git clean -qfdx` at arbitrary host paths

**Severity:** Critical
**Location:** `scripts/crb-materialize.py:348-357`
**Boundary:** B1, B2
**Move:** #3 (error path / state after the operation), #11 (bypass enumeration)
**Confidence:** High (executed)

Distinct from the finding above because removing hooks does not close it. `reset_clone()` ends with:

```
    sh(["git", "clean", "-qfdx"], cwd=dst)
```

`git` resolves the worktree from `core.worktree` in `.git/config`, which the container can write.
In my reproduction I set `core.worktree` to an unrelated directory containing `docs/notes.md` and
`other.txt`; after the three-command sequence that directory contained only the clone's `f.txt` —
both host files were deleted by `clean -qfdx` and the tracked file was written in their place.

The same config also redirects the harvest's `git status --untracked-files=all`, which then
enumerates the host directory. That *specific* exfiltration is blocked, and the guard that blocks
it is not the traversal check — it is `[ -f "$clone/$f" ]` on `run-host.sh:338`, which resolves
paths relative to `$clone` rather than to git's worktree, so the enumerated host file simply
doesn't exist at the copy source. That is load-bearing safety by accident; it should be made
deliberate.

**Recommendation:** As above — `-c core.worktree=` on every host-side invocation is the one-line
mitigation; not handing the container `.git` at all is the real fix. Separately, add a comment at
`run-host.sh:338` recording that the `[ -f "$clone/$f" ]` test is a security control (it is
currently written as a benign existence check), so a future refactor to `[ -e ]` or to a
`git -C "$clone" show`-based harvest doesn't silently remove it.

---

#### A nested clone of the answer key inside `/repo` is invisible to every containment check and survives `git clean -qfdx`

**Severity:** High
**Location:** `scripts/crb-materialize.py:200-264` (`fetch_traces`), `267-286` (`classify_strays`), `357` (`clean -qfdx`)
**Boundary:** B3
**Move:** #11 (enumerate bypasses)
**Confidence:** High (executed)

`git clean -fdx` with a *single* `-f` deliberately refuses to remove a directory containing its own
`.git`; `-ff` is required. `-q` suppresses the "Skipping repository" warning, and the exit status
is 0. I reproduced the full sequence: `git clone <answer-key-url> ./ak` inside the clone yields

- `git status --porcelain` → one entry, `?? ak/` (the harvest's `*.md|*.json` filter and
  `[ -f ]` test both skip it, so it is never even logged);
- `.git/FETCH_HEAD` → absent (the fetch happened in `ak/.git`, not `dst/.git`);
- `git fsck --unreachable --no-reflogs` → silent;
- `git rev-list --all --not $HEAD` → empty;
- `git clean -qfdx` → exit 0, `ak/fix.txt` still present afterwards.

So the answer key persists in the clone *across cells*, undetected, and the next cell's reviewing
agent finds it sitting in its working directory. Every check in the diff inspects `dst/.git`; a
nested repository is a second git directory the checks never look at.

**Recommendation:** Two cheap changes. (a) Use `git clean -qffdx` so nested repositories are
actually removed. (b) More importantly, treat "a directory containing `.git` exists anywhere under
the worktree" as a **void** condition rather than something to clean — like a modified
`.git/config`, it is strong positive evidence, not noise. A `git status`-visible `?? <dir>/` entry
whose contents include `.git` should raise from `reset_clone()`.

---

#### The reset/void split's only real discriminator is *git-fetch traces*, so any non-git retrieval fails open as "benign agent work"

**Severity:** High
**Location:** `scripts/crb-materialize.py:267-286`, `315-343`
**Boundary:** B3
**Move:** #5 (invert the access-control model), #11
**Confidence:** High (traced through code; not exercised end-to-end)

Asked directly: is the split defensible as a security control, and where does it fail open?

It is defensible *as an availability fix*, and the docstring is admirably honest about its limits:

```
    `foreign` = does not descend from the reviewed head. Descent is NECESSARY
    for a stray to be treated as benign agent work, and it is NOT SUFFICIENT —
```

But invert it. The guard's decision procedure is: *no remote* ∧ *no fetch traces* ∧ *descends from
head* ⇒ benign, reset it, keep the cell. Enumerate what that does **not** cover:

1. **Any non-git retrieval.** `curl`/`gh pr view`/the agent's own WebFetch of the upstream merged
   PR, content written into the working tree and committed on top of `head`. Descends from head;
   no FETCH_HEAD; no unreachable commits; no remote. → **classified benign, cell kept, score
   inflated.** Given the container has unrestricted egress and `--dangerously-skip-permissions`,
   this is the *most likely* incidental-contamination route, not the least — an LLM agent asked to
   review a PR reaches for the PR page far more readily than for `git fetch <URL>`.
2. **Never touching disk at all.** The agent reads the upstream fix and writes it into its review
   prose. `review.md` is harvested at `run-host.sh:294-312`, *before* any containment check runs.
   No git artifact exists to detect. The guard cannot fire, by construction.
3. **Nested clone** — finding above.
4. **Clone outside `/repo`** (e.g. `/tmp/ak`) — acknowledged in the `fetch_traces()` docstring, and
   undetectable by construction since every check is `cwd=dst`.
5. **`.git/objects/info/alternates`** pointing at an out-of-repo object store — the answer-key
   objects become readable with no fetch, no FETCH_HEAD, and nothing unreachable. *Untested.*

The honest framing is that this is a **contamination-evidence detector for one specific route**
(in-place `git fetch`), not a containment control. That is worth having, and the code says so.
What it is not is a reason to believe a passing cell is clean — and the risk is that
`voided_cells: []` in `run-meta.json` reads, to whoever writes the results doc, as "containment
held."

**Recommendation:** Do not change the guard's logic — it is correctly conservative for what it
can see. Change what the artifacts *claim*. Add a `containment_detection_scope` field to
`run-meta.json` naming the routes covered (in-place fetch, re-added remote, foreign-ancestry
commit) and the routes not covered (out-of-band retrieval, nested/external clone, in-context
only), and have `crb-subset-leaderboard.py` print it beside the attrition warning — the same
reasoning the diff already applies to attrition ("a caveat that only ever existed on a terminal is
a caveat that will not survive to the place the number is quoted") applies here with more force.
The real control remains R3.

---

#### `git commit --amend`, squash, or rebase by the reviewing agent voids a clean cell

**Severity:** Medium
**Location:** `scripts/crb-materialize.py:339-343`
**Boundary:** B3
**Move:** #3 (error path), #5
**Confidence:** Medium (traced through code; not exercised)

`classify_strays()` calls a stray benign only when `merge-base --is-ancestor head <c>` succeeds.
The payload's own `CLAUDE.md` — mounted into every container — pushes hard on committing, and its
commit-trigger guidance makes small, frequent commits the norm. Any agent that then amends,
squashes, rebases, or commits from a detached checkout of `base` produces a commit that does
*not* descend from `head`, and the cell is voided as contamination.

This fails *closed*, so it is not a containment hole. It is a **denominator hole**: the same
selection bias `attrition()` was written to expose. Cells lost this way are indistinguishable in
`run-meta.json` from cells lost to real contamination (both land in `voided_cells`), so the
leaderboard's attrition line will report "voided by a post-run containment failure" for what is
actually ordinary agent behaviour, and the reader has no way to tell how much of the loss is
signal.

**Recommendation:** Split the void reason. `reset_clone()` already knows which check raised —
carry that reason into `CONTAINMENT_FAILED` (write the message into the file instead of
`: > "$dest/CONTAINMENT_FAILED"`), surface it in `run-meta.json`'s `voided_cells`, and let
`attrition()` distinguish `remote/fetch-trace` voids from `foreign-ancestry` voids. Consider also
whether a foreign commit whose *tree* is reachable from a descendant of `head` should be reset
rather than voided.

---

#### The pre-run `--reset` widens what the harness will silently repair before a cell

**Severity:** Medium
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:262-264`
**Boundary:** B3
**Move:** #4 (time-of-check to time-of-use)
**Confidence:** Medium

Before the diff, the pre-run gate was `--verify` — read-only, and *any* deviation from the
materialized state skipped the cell. It is now `--reset`, which repairs deviations and proceeds:

```
  python3 "$ROOT/scripts/crb-materialize.py" --reset "$id" || {
```

That is the right call for the intended case (a previous cell's agent commits). But it also means
that anything reaching the clone *between* cells — a stray host process, a partially-completed
prior reset, an interrupted sweep — is now repaired-and-run rather than skipped-and-noticed. The
post-run reset already restored the baseline; the pre-run reset therefore only ever fires on
*unexpected* state, and firing on unexpected state is exactly when you want to stop, not fix.

**Recommendation:** Keep `--reset` post-run, and have the pre-run call report when it actually
had to change something. `reset_clone()` already returns that note (`"; ".join(notes)`); have
run-host.sh treat a non-empty pre-run note as at minimum a loud warning recorded in the cell
directory, since post-run reset means it should be empty on every cell after the first.

---

#### `--reset` writes to the clone even when the manifest gate is the thing protecting the path

**Severity:** Low
**Location:** `scripts/crb-materialize.py:463-496`
**Boundary:** B5
**Move:** #2, #5
**Confidence:** High (read-static)

Asked directly: is anything in the new `--reset` surface reachable with an attacker-influenced
slug? I traced it and the answer is **no, but the protection is indirect**. `dst = DST_ROOT / slug`
does not constrain `slug` (`Path("/a") / "/etc"` is `/etc`), and `run-host.sh` takes instance names
straight from `"$@"`. What saves it is that `reset_clone()` is only called after:

```
            rec = manifest.get(slug) or {}
            head, base = rec.get("head"), rec.get("base")
            if not head or (resetting and not base):
```

and every manifest key was produced by `slug_for()`, which enforces
`re.fullmatch(r"[A-Za-z0-9_-]+", slug)`. So an absolute or `..`-bearing slug can reach the
`(dst/".git").is_dir()` probe but never the destructive branch. The `--reset` addition tightened
this slightly (it now also requires `base`), which is a genuine improvement.

**Recommendation:** Make the protection direct as well as incidental — apply the same
`re.fullmatch(r"[A-Za-z0-9_-]+", slug)` check to `--verify`/`--reset` arguments at the top of the
loop, so the guarantee does not depend on a property of a JSON file on disk that a future
hand-edit could break.

---

### Untested bypass candidates

Per move #11, these were enumerated against the reset/void guardrail and **not** tested:

- **`.git/objects/info/alternates`** pointing at an answer-key object store outside the mount.
  Objects become readable with no fetch, no `FETCH_HEAD`, and nothing unreachable; a commit on top
  of `head` then classifies benign. Not tested because it needs a second object store staged inside
  a container run.
- **`git worktree add` / `GIT_DIR` redirection** creating a second working tree whose refs live in
  `.git/worktrees/*`. Whether `rev-list --all` and `for-each-ref refs/heads` in `reset_clone()` see
  per-worktree refs depends on git version and `extensions.worktreeConfig`; not tested.
- **The three-step defeat named in `fetch_traces()`'s docstring** (remove `FETCH_HEAD` + `reflog
  expire --expire=now --all` + `gc --prune=now`). Asserted in the docstring, and partially pinned by
  `test/crb-containment-reset.bats:186`, but I did not execute the full defeat to confirm it leaves
  the guard silent.
- **Shallow-clone grafting** — `.git/shallow` manipulation so a fetched commit is treated as a
  boundary rather than an unreachable object. Not tested.
- **Timing/TOCTOU on the post-run reset** — a background process left running inside the container
  is killed by `docker run --rm`, but a process the agent started on a *host-visible* path via the
  mount is not reachable from here; I did not look for one.

Because these are untested, the reset/void guardrail does not appear in Endorsement Claims below.

---

## Endorsement Claims

- **Claim:** `--reset`'s destructive branch cannot be reached with a slug that is not a
  `[A-Za-z0-9_-]+` manifest key.
  **Location:** `scripts/crb-materialize.py:463-496`, `73-88`
  **Evidence:** read-static
  **Verified:** Read the `--verify`/`--reset` branch end to end; `reset_clone()` is called only
  after `manifest.get(slug)` yields both `head` and `base`, and every manifest key is produced by
  `slug_for()`, which raises on anything outside `[A-Za-z0-9_-]+`.
  **Not verified:** The contents of the on-disk `runs/review-arms/crb/instances.json` — a
  hand-edited or externally-generated manifest key bypasses `slug_for()` entirely, and I did not
  read the checked-in file's keys.
  **route: code-fact-check**

- **Claim:** The harvest loop's `cp --no-dereference` plus `git status`'s refusal to descend into
  symlinked directories together prevent a symlink planted in the clone from copying host file
  *contents* into the tracked artifacts dir.
  **Location:** `runs/review-arms/crb-pipeline/run-host.sh:324-344`
  **Evidence:** read-static
  **Verified:** Read the loop; a symlinked directory appears in porcelain output as one entry for
  the link itself, so `x/settings.json` never enters the loop, and a symlinked *file* is copied as
  a link by `--no-dereference`.
  **Not verified:** I did not execute a symlink case against `git status --untracked-files=all`;
  and I did not check what a downstream consumer of `$dest/artifacts/` does with an absolute
  dangling symlink it finds there.
  **route: code-fact-check**

- **Claim:** A post-run containment void actually removes the cell from the judged set rather than
  only annotating it.
  **Location:** `runs/review-arms/crb-pipeline/run-host.sh:359-372`, `scripts/crb-pipeline-to-benchmark.py:241-242`
  **Evidence:** read-static
  **Verified:** Grepped and read the injector's `if (cell / "CONTAINMENT_FAILED").exists()` branch,
  which skips the cell; the runner both writes that marker and rewrites `result.json` with
  `is_error=True`, so `crb-cell-status.py` also refuses it.
  **Not verified:** Whether `review.md`, `transcript.jsonl`, and `artifacts/` from a voided cell
  are excluded everywhere they are read — they are left in place on disk and I traced only the
  injector.

- **Claim:** `write_run_meta`'s move into an EXIT trap makes provenance survive the SWEEP_BUDGET
  halt, which exits 2 from inside the loop.
  **Location:** `runs/review-arms/crb-pipeline/run-host.sh:159-220`, `404`
  **Evidence:** read-static
  **Verified:** Read the trap installation, the `META_WRITTEN` idempotence guard, and the
  `exit 2` inside the loop body; the trap replaces the earlier payload-only trap and runs both jobs.
  **Not verified:** Behaviour under `set -e` when `write_run_meta`'s heredoc python fails — the
  `|| true` covers the python call but I did not exercise the trap firing during an active
  `errexit` unwind.

The reset/void guardrail itself (`reset_clone`, `fetch_traces`, `classify_strays`) is deliberately
**absent** from this section: it has five untested bypass candidates listed above.

---

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Host RCE from container-writable `.git/hooks` + `.git/config` (hooks, `core.fsmonitor`, `core.hooksPath`, smudge filters) | Critical | B1, B2 | `crb-materialize.py:348-361`, `run-host.sh:344` | High (executed) |
| 2 | `core.worktree` redirects `git clean -qfdx` at arbitrary host paths | Critical | B1, B2 | `crb-materialize.py:357` | High (executed) |
| 3 | Nested clone of the answer key survives `clean -qfdx` and is invisible to all checks | High | B3 | `crb-materialize.py:200-286, 357` | High (executed) |
| 4 | Reset/void split detects only in-place git fetch; non-git retrieval classifies benign | High | B3 | `crb-materialize.py:267-286, 315-343` | High |
| 5 | Amend/squash/rebase by the agent voids a clean cell, polluting `voided_cells` | Medium | B3 | `crb-materialize.py:339-343` | Medium |
| 6 | Pre-run gate changed from read-only `--verify` to repairing `--reset` | Medium | B3 | `run-host.sh:262-264` | Medium |
| 7 | `--reset` path safety depends indirectly on manifest key hygiene | Low | B5 | `crb-materialize.py:463-496` | High |

---

## Overall Assessment

The containment work in this diff is good at what it set out to do — the reset/void split is
carefully reasoned, honestly documented about its own limits, and unusually well pinned by
`test/crb-containment-reset.bats` (including a non-vacuity test for `scrub_object_store`, which is
the kind of thing most suites never get). Findings 4, 5 and 6 are refinements to that work, and the
most useful of them is 4: the guard should stop being read, by its own artifacts, as evidence that
containment held, because it detects exactly one retrieval route out of at least five.

Findings 1–3 are a different matter and they are not really about the diff's logic — they are about
the *shape* the diff now leans on harder. `--verify` was read-only; `--reset` runs `checkout
--force`, `reset --hard`, `clean -qfdx`, `gc` and `symbolic-ref -d` on the host against a `.git`
directory that a `--dangerously-skip-permissions` agent had unrestricted write access to, and I
demonstrated five distinct host-side execution or destruction paths out of that arrangement. This
is an architectural problem, not an in-place fix: the container needs the worktree, it does not need
`.git`, and separating the two closes B2 entirely. The `-c`-override mitigation is worth applying
today as a stopgap, but it is a denylist against a config surface that grows with each git release.

The single most important thing to address: **do not run the sweep until the container stops having
write access to `.git`, or until every host-side git invocation against these clones is hardened.**
Fifty third-party repositories is fifty chances, and the host shell holds a live
`ANTHROPIC_API_KEY`.

No categorical all-clear is claimed: findings are limited to the code paths read and the five
reproductions executed; endorsement claims are pending execution verification where marked.

---

## Goal-Alignment Note
- **Answered:** yes — all four questions answered, with three of them backed by executed reproductions.
- **Out of scope:** R3 (container egress / API-key blast radius) was treated as known and excluded from verdicts per the brief, though findings 1–3 raise its urgency and finding 4 depends on it as the real control. `docs/human-author/LLM Code Review.md` and `docs/working/crb-direction1-setup.md` (doc-only changes) were read for context but not reviewed for security. `crb-cell-status.py` and the attrition work carry no trust-boundary crossing beyond B6 and produced no findings.
- **Escalate:** (a) Findings 1 and 2 are gating on the sweep and need a host/architecture decision, not an in-file fix — they belong in the same bucket as R3, and arguably outrank it, since they need no attacker-controlled network to land. (b) Finding 4's recommendation is a change to what `run-meta.json` and the leaderboard *claim*, which touches the same provenance surface this diff just reworked — worth folding into the iteration-3 pass rather than filing separately.
