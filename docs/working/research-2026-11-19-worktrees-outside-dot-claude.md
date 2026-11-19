# Research: worktrees outside `.claude/` (F-019)

Brief: `docs/working/briefs/2026-11-19-worktrees-outside-dot-claude.md` (at a5223578).
Branch: feat/worktrees-outside-dot-claude. Dispatch 1.

## Question 1: what Claude Code treats as protected

Source: Claude Code docs, "Permission modes", section "Protected paths"
(https://code.claude.com/docs/en/permission-modes.md, fetched 2026-11-19 with WebFetch;
this session had egress, so the quotes below come from the live page, not from
memory). Also "Configure permissions" (https://code.claude.com/docs/en/permissions).

- **`.claude/` as a whole is protected, not just its settings files.** The page lists
  "Protected directories: `.git`, ... `.claude`, with a few exceptions, such as: Claude's
  own git worktrees under `.claude/worktrees/`, ..." (plan files, background-session
  scratch, auto-memory and subagent-memory Markdown). `.claude/wt-*` is not one of the
  exceptions.
- **Per mode:** `default` and `acceptEdits` prompt; `auto` hands the write to the
  classifier; `dontAsk` denies; `bypassPermissions` allows. So the asks F-019 saw are
  what the docs say should happen in default or acceptEdits mode, and a headless
  `dontAsk` loop would be denied outright.
- **An allow rule does not help.** Quote: "`permissions.allow` rules in settings files do
  not pre-approve protected-path writes. The safety check runs before Claude Code
  evaluates allow rules from settings, so an entry such as `Edit(.claude/**)` ... does not
  change the per-mode outcome." So an allow rule scoped to `.claude/wt-*/**` would not stop
  the asks.
- **Bash redirects are checked as well.** The permissions page: for `> file` the check
  "covers your `Edit` allow and deny rules, protected paths, and the working
  directories"; the same goes for `tee` targets. So a shell redirect into `.claude/wt-*`
  can prompt too. A script that writes (git, a `bash script.sh`) is not a redirect the
  check sees.
- **Writes outside the working directories** need approval in the modes that prompt (the
  working-directories section). The session temp directory is outside them unless it is
  added with `--add-dir`.
- Not settled from inside the sandbox: which Claude Code version the owner's host runs,
  and so whether the page matches it exactly. A secondary web source says the
  bypass-mode behaviour changed across versions (unverified). The conclusion does not
  depend on that: default and acceptEdits prompt on `.claude/` in every version the
  sources describe. The marker lists one host check that confirms it.

## Question 2: what `hooks/guard-trusted-writes.py` refuses

Read its header (lines 1-70) and `test/hooks/guard-trusted-writes.bats` 519-745.

- The HARD tier is the user's real policy files: `{{CLAUDE_DIR}}/hooks/**`,
  `{{CLAUDE_DIR}}/settings*.json`, `{{CLAUDE_DIR}}/CLAUDE.md` and `~/CLAUDE.md`. For Bash it
  works on the command's text: any `.claude/hooks` or `.claude/settings` fragment; a
  CLAUDE.md mention together with a home or global indicator, and `.claude` counts as one;
  or a settings*.json or hooks mention together with `.claude`. A match is a deny.
- It has no worktree exemption on purpose. Q-048 [2] tried one for `.claude/wt-*` and
  `.claude/worktrees/*`. Three review passes each found a bypass (quote-split `..`,
  `cd ..`, brace expansion, `env -C` and others; see
  `docs/reviews/code-review-rubric-2026-09-23-ans-guard-q048-q050.md`), so it was
  withdrawn. The tests at bats 544-745 pin that a Bash write into `.claude/wt-foo/hooks/`
  or `.claude/wt-foo/settings.json` is denied.
- Why it bit the brief write: the worktree path holds `.claude`, and the brief text names
  `hooks/guard-trusted-writes.py`. Together they make the "hooks mention plus `.claude`"
  co-occurrence, so the whole heredoc was denied.
- Consequence: moving worktrees out of `.claude/` changes nothing in the guard. A Bash
  write to `/workspace/.worktrees/wt-x/hooks/x.sh` then gets the same no-opinion that
  `/workspace/hooks/x.sh` in the main checkout gets today. The real policy files keep
  their protection: `~/.claude/...` still holds `.claude`, and a worktree's own
  `.claude/settings.json` still matches `.claude/settings`.

## Today's layout (and who reads it)

- `scripts/build-loop.sh` `--start` defaults DIR to `$MAINWT/.claude/wt-$stem` (line 1820).
- `skills/dev-cycle/SKILL.md`: WT at step 0.3, HC at step 1, GT at step 7, each
  `.claude/wt-dev-cycle-*-DATE-HHMM` in MAIN_WT.
- `workflows/parallel-worktrees.md` 42-43: `.claude/wt-item-*`.
- `--prompt`, `--free-worktrees` and the gate find a loop's worktree by branch, or by its
  lock reason, through `git worktree list --porcelain` (`wt_of`, `free_worktrees`).
  None of them reads the path's prefix, so a worktree at the old path is still found,
  collected and freed. That is criterion 3's compatibility, and it comes with no extra
  code. Tests pin it.
- Out of scope, but noted: `scripts/self-improvement.sh` puts its own worktrees under
  `$REPO_DIR/.claude/wt` (`WORKTREE_BASE`, overridable). That is a different loop that
  the brief does not name. It can follow later.
- Not in this repo: F-019's `.claude/lake-build-warm-*` caches belong to
  philosophy-research's own setup, and no harness file names them.

## Design: where the worktrees go (divergent design)

Seeded with `docs/constraints.md` (H1-H4, S1-S11) and the brief's own: writes allowed,
`git worktree add` works, survives the session, does not widen access, spends no owner
attention.

| Option | Write asks (CC docs) | Guard Bash deny | `worktree add` works | Survives session | Widens access | Owner attention |
|---|---|---|---|---|---|---|
| A. Status quo `.claude/wt-*` | prompts in default/acceptEdits | yes, with `.claude` plus a policy name | yes | yes | no | an ask per write (F-019: about 18 in a session) |
| B. Scoped allow rule `.claude/wt-*/**` | still prompts: the docs say allow rules don't pre-approve | yes | yes | yes | yes, a new allow surface | a host paste, and it still asks |
| C. `.claude/worktrees/<name>` (CC's exception) | maybe none, if "Claude's own" covers worktrees a script made (not settled in the sandbox) | yes, path still holds `.claude` | yes | yes | no | a host check, and the guard still denies the brief heredocs |
| D. Session temp dir (`$TMPDIR`, scratchpad) | prompts: outside the working directories | no | yes | no: cleared on reboot or cleanup, path is per session | no | asks, and loops lost on reboot |
| E. Repo sibling `.worktrees/` (self-ignored) | none: in the working dir, not on the protected list | no (no `.claude` in the path) | yes: an ordinary directory in the checkout (row 88: no CC sandbox in cc-isolated) | yes: in the repo's volume | no more than the main checkout already has | none |
| F. Outside the repo (`/workspace/../wt`) | prompts: outside the working directories | no | yes | no in cc-isolated (only `/workspace` is a volume) | no | asks |

**Path A: E dominates.** It is the only option that removes both walls (Claude Code's
protected-path ask and the guard's `.claude` co-occurrence) and survives the session. It
also needs no host step (S10) and adds no allow rule (H2, S1). B is out on the docs alone.
C still fails on the guard, and its exemption is uncertain. D and F fail survival and
still prompt.

Sub-choices, each with one viable answer, noted rather than designed:

- **Name `.worktrees/`.** It is F-019's own suggestion and a common convention. No
  protected list names it, and the `.claude` and `.git` dot dirs are the ones to avoid.
- **Ignoring it in every repo without editing that repo's `.gitignore`.**
  `.worktrees/.gitignore` holding `*` ignores the directory's contents and itself, so the
  main worktree's `git status` and `git add -A` never see a loop's checkout (without
  this, `add -A` would add each checkout as an embedded repository). Nothing in other
  repos' files changes, so no `guides/convention-changes.md` migration is needed (none of
  the fingerprinted sources, step 6, 8 or 9's templates or `questions.sh`'s grammar, is
  touched). An existing `.worktrees/.gitignore` is left alone, but the code checks with
  `git check-ignore` that the base is still ignored, and refuses if not (H2: never
  present-but-inert).
- **One place each (criterion 3).** `build-loop.sh` gets `WT_BASE_NAME` and `wt_base()`,
  used by `--start`'s default and by a small new read-and-make mode `--worktree-base`
  that prints `ok DIR`. The skill defines WTB once in its Rules, from that mode, and
  steps 0.3, 1 and 7 name `WTB/wt-dev-cycle-...`. S4 puts the mechanical
  make-and-ignore step in a tested script, not prose. S3: the skill and `--start` share
  one helper.
- **Old-path worktrees.** No code: they are found by branch and lock reason. The skill
  says that its earlier-iteration HC and other sessions' `wt-dev-cycle-*` are matched by
  name in `worktree list` at either base.
- **Half-landed iterations (criterion 4).** One Rules sentence: a file write (brief,
  record, roadmap) and any command that depends on it go in separate responses.

Residual risk, stated (S1 lets a relaxation that names its residual stand):
"worktree-hooks-bash". A Bash write into a loop worktree's `hooks/` or `settings`-named
file is no longer denied by the guard; today it is denied only because the path holds
`.claude`. It gets what the same write in the main checkout gets. Those are repo source
files, which the merge gate and review read, and not the installed policy files, which
stay HARD.

## Gotchas

- Failure-pattern grep: FP-011, FP-014, FP-062
  - FP-011 (orphaned worktree after a partial add, ordering): make the base before the
    branch, so a failed base leaves no branch behind.
  - FP-014 (a stale `.git/worktrees` entry breaks the next add): unchanged here. Old-path
    entries stay in git's list and are freed as before.
  - FP-062 (a relative override resolved against the wrong directory): the base is built
    from MAINWT, git's absolute main-worktree path, never from `$PWD`.
- `wt_of` needs a branch argument. `--worktree-base` passes an empty one only to read
  MAINWT.
- The `.gitignore` write uses noclobber (`set -C`), so a link planted between the check
  and the write is not followed (an honest race, S1).

## Plan

1. `scripts/build-loop.sh`: `WT_BASE_NAME`, `wt_base()`, the `--start` default and its
   message, the `--worktree-base` mode with usage, header and exit docs.
2. Tests in `test/scripts/build-loop-dispatch.bats`: the new default, the self-ignore, a
   symlinked base refused, `--worktree-base`. In `test/scripts/build-loop-free.bats`: an
   old-path `.claude/wt-*` worktree collected by `--prompt` and freed by
   `--free-worktrees`.
3. `skills/dev-cycle/SKILL.md`: WTB in the Rules, steps 0.3, 1 and 7, the
   separate-responses rule.
4. `workflows/parallel-worktrees.md` 42-43.
5. bats for those suites, hermeticity-lint, health check.
