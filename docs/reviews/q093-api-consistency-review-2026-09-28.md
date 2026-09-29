# API Consistency Review — branch `q093-cc-push-self-commondir`

**Scope:** `git diff dfe4c0d..HEAD` (2c9ebf3, 2c8163f): `devcontainer-config/cc-push.sh`, `guides/cc-isolated-usage.md`, `test/cc-push.bats`, `docs/working/plan-q093-cc-push-self-commondir.md`
**Date:** 2026-09-28
**Based on:** Stage-1 code-fact-check findings relayed by the orchestrator (die-message wording; test-comment spellings claim; plan's `../../elsewhere` reference)

Public surface touched: the `check_checkout` refusal text for `.git/commondir`, the header comment (printed verbatim by `usage()` / `--help`, `cc-push.sh:144-146`), the "What it refuses in the checkout" paragraph of `guides/cc-isolated-usage.md`, and one new internal helper, `commondir_is_self`. No flags, exit codes or output formats change. The change narrows a refusal (it accepts strictly more inputs than before), so no existing caller breaks.

## Baseline Conventions

- **Die messages in `check_checkout`** (`cc-push.sh:288-334`) follow one shape: `<path> <what it is>: <why git would misbehave>. <remedy>.` The remedy is either the shared `$run_main` ("Run it on the main checkout") or a specific action ("Remove it ..., then rerun", "delete the section with a text editor ..., then rerun"). None uses a parenthesized aside sentence. Tests match on a stable leading fragment (`"commondir exists"`, `"http-alternates exists"`).
- **Helper split between files.** `cc-gitdir.sh` holds *git-modelling* predicates shared by `cc-push.sh` and `cc-exit-scan.sh` (`gitdir_head_kind`, `gitdir_common`, `gitdir_valid`, `looks_like_gitdir`); its header says it reproduces "what git itself would accept", and it is part of the install payload and trust manifest. `cc-push.sh` holds its own *policy* helpers (`git_version_ok`, `project_id`, `check_git_version`, `check_checkout`).
- **Helper doc comments** use `# name <args>: 0 when ...` (e.g. `git_version_ok`, `gitdir_valid`), cite the git source function they mirror (`setup.c get_common_dir_noenv`), and cite the Q-number that motivated them.
- **Header / guide / die text** name refused things concretely and are kept in sync (header `cc-push.sh:74-97` and guide `cc-isolated-usage.md:248-266` enumerate the same list).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `commondir_is_self` | internal function (predicate) | `looks_like_gitdir`, `gitdir_valid`, `git_version_ok` | `devcontainer-config/cc-gitdir.sh`, `devcontainer-config/cc-push.sh:193-208` | Consistent — snake_case predicate returning 0/1, `# name <file>: 0 when ...` doc form. The `gitdir_` prefix in cc-gitdir.sh marks git-modelling helpers; this one deliberately does *not* model git (it refuses `./`, `.\r\n`, absolute self), so omitting the prefix and keeping it in cc-push.sh is correct. |

No flags, env vars, exit codes or output fields are added.

## Findings

#### 1. Refusal message names one accepted spelling where header and guide name two

**Severity:** Minor
**Location:** `devcontainer-config/cc-push.sh:295`
**Move:** 3 (documentation drift) / 4 (error consistency)
**Confidence:** High
**Legibility target:** operator reading the refusal on the host

Evidence (verbatim):
```
die "$g/commondir exists (a linked worktree's layout): it names another repository, which git would read. (Only a regular file holding just \`.\`, a self-reference, is accepted.) $run_main"
```
The header (`cc-push.sh:87-89`: "a regular file holding exactly `.` or `.\n`") and the guide (`cc-isolated-usage.md:258-259`: "exactly `.` (or `.` and a newline)") both state two accepted forms; the message states one, and says "just" rather than "exactly". An operator whose tool wrote `./` or `.\r\n` reads "holding just `.`" and may think a trailing newline is also refused, or that whitespace variants are fine. Separately, the lead clause "it names another repository" is now false for several refused inputs (`./`, `.\r\n`, the absolute path of `.git`), which git reads as self; the fact-check flagged the same wording. The message is otherwise in the established `<path> <what>: <why>. <remedy>` shape, and the leading `commondir exists` fragment that tests and users match on is kept.

**Recommendation:** Say "holding exactly `.` or `.` and a newline", matching the guide, and soften the lead to "it can name another repository". Optionally drop the parentheses so the added sentence reads like its siblings.

#### 2. The remedy (`$run_main`) points at the checkout the user is already on

**Severity:** Informational
**Location:** `devcontainer-config/cc-push.sh:284, 295`
**Move:** 4 (error consistency)
**Confidence:** Medium
**Legibility target:** operator deciding what to do next

Evidence (verbatim): `local run_main="cc-push reads only a checkout whose .git is a real directory. Run it on the main checkout (the one the session was launched on)."`

This existed before the branch; the branch edits the line but does not fix it. Q-093's case is a stray `commondir` *in* the main checkout, so "run it on the main checkout" doesn't help. Sibling refusals for files planted inside `.git` give a concrete action instead (`cc-push.sh:310`: "Remove it (it is not something git creates), then rerun."; `:319`: "delete the section ..., then rerun"). With self-references now accepted, most commondir refusals are either a real linked worktree (where `$run_main` fits) or some other stray spelling (where "remove it" fits).

**Recommendation:** Optional: add "If this is the main checkout, remove .git/commondir (git does not need it there), then rerun." before `$run_main`. Not a blocker.

#### 3. The new test's comment contradicts the helper comment on which spellings git reads as self

**Severity:** Minor
**Location:** `test/cc-push.bats:262-265`
**Move:** 3 (documentation/test drift)
**Confidence:** High (the fact-check confirmed it)
**Legibility target:** maintainer extending the accepted set later

Evidence (verbatim), test: `git reads the other spellings refused below either as elsewhere or (./) as self too`. Helper (`cc-push.sh:266-267`): `Nothing else passes, not even other spellings git also reads as self (`./`, `.\r\n`, `.\0...`, the absolute path).` The helper comment is right. `gitdir_common` in cc-gitdir.sh, which trims CR/LF, agrees with it. The test comment is wrong for `.\n\n`, `.\r\n`, `.\0` and the absolute path. A maintainer who trusts the test comment would conclude that only `./` is a strict-policy choice and the rest are genuinely foreign.

**Recommendation:** Reword the test comment: "git also reads `./`, `.\n\n`, `.\r\n`, `.\0` and the absolute path as self; cc-push refuses them anyway (only these two byte strings are accepted)."

#### 4. Q-number cross-references differ between surfaces

**Severity:** Informational
**Location:** `cc-push.sh:89` (Q-093), `cc-push.sh:264-265` (Q-093 + Q-091), `guides/cc-isolated-usage.md:260` (Q-093)
**Move:** 3
**Confidence:** Medium
**Legibility target:** future reader tracing why the exception exists

The header and guide say "some host tool" / "a host tool" and cite Q-093. The helper comment adds that the writer was traced in Q-091, which found it in the Claude Code sandbox according to commit b91f921. The surfaces don't contradict each other, but only the helper comment points at the trace. The plan's reference to a `../../elsewhere` case "in the new list" (the fact-check finding) is a working-doc slip, not public surface, and is not scored here.

**Recommendation:** Optional: cite Q-091 alongside Q-093 in the guide sentence.

## Cross-file consistency checks (no conflict found)

- **`cc-gitdir.sh`**: `gitdir_common` (`:54-68`) resolves `.` to `"$d/."`, so `gitdir_valid` (called later in `check_checkout`, `:330`) validates `.git` itself, which matches the acceptance. `looks_like_gitdir` still refuses *any* root-level `commondir` (`:89`). The header (`cc-push.sh:80-81`) and guide (`:264`) still say that, and the new exception is scoped to `.git/commondir` in both texts. Consistent.
- **`cc-exit-scan.sh`**: it follows `commondir` rather than refusing it (`:123-126`, `:555-561`). A `.` resolves to the same dir and is de-duplicated by `_snap_seen`. Its prose (`:49-51`, `:707`, `:796`) describes following and recording the file, not refusing it, so nothing there conflicts with the relaxed cc-push policy.
- **`cc-isolated.sh`**: no mention of `commondir`.
- **`--help`**: the edited header lines are inside the block `usage()` prints; the existing `--help` test (`test/cc-push.bats:435`) still passes on its anchored fragments, which the edit doesn't touch.

## What Looks Good

- The helper sits in cc-push.sh, not cc-gitdir.sh. That is the right call: cc-gitdir.sh's contract is "model what git accepts" and it is shared with the exit scan, while `commondir_is_self` is a stricter cc-push *policy* (it refuses spellings git reads as self). Moving it would blur that line and put a policy helper in the trust-manifested shared file that the exit scan has no use for.
- The helper's name, doc-comment form, git-source citation and 0/1 predicate contract match `gitdir_valid` / `git_version_ok`.
- The refusal keeps its leading `commondir exists` fragment, so existing tests and anyone grepping for it are unaffected. The older `../../elsewhere` test (`test/cc-push.bats:249-258`) still passes unchanged.
- The header and the guide describe the exception in the same terms (a regular file, exactly `.` or `.\n`, names `.git` itself).
- The narrowing is backward-compatible: nothing that was accepted is now refused.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| 1 | Die message says "just `.`"; header and guide say `.` or `.\n`; "names another repository" is false for refused self spellings | Minor | `cc-push.sh:295` | High |
| 3 | Test comment wrongly says only `./` among refused spellings is self to git | Minor | `test/cc-push.bats:262-265` | High |
| 2 | `$run_main` remedy doesn't help a stray commondir in the main checkout | Informational | `cc-push.sh:284,295` | Medium |
| 4 | Q-091 trace cited only in the helper comment | Informational | `cc-push.sh:89`, `cc-isolated-usage.md:260` | Medium |

## Goal-Alignment Note

The branch's goal is narrow: let cc-push run on a main checkout that carries the 1-byte self-`commondir` a host tool keeps writing, and refuse every other `commondir` as before. The public surface serves that goal. Help, guide and tests agree on the accepted set. The helper is placed and named in line with the codebase's split between modelling git and cc-push policy. Nothing in cc-exit-scan.sh or cc-isolated.sh conflicts. The two Minor findings are wording drift and don't change behaviour: the refusal text under-describes the accepted set, and a test comment misstates git's behaviour. Both can be fixed in place in a few lines before the local merge. Neither blocks the merge.

## Overall Assessment

The change is consistent with cc-push's conventions and is a backward-compatible narrowing of a refusal. There's no consumer impact beyond the wording of one error message. Findings 1 and 3 are quick text fixes worth making before the merge, so the error, help, guide and tests state the same rule. Findings 2 and 4 are optional polish.
