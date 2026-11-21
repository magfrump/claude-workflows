# Research: the write guard's `.claude/wt-*` worktree exemption

Brief: docs/working/briefs/2026-11-20-write-guard-wt-exemption.md
Date: 2026-11-20 · Branch: fix/write-guard-wt-exemption · Policy: review

## Change

Comments only, plus one pinning bats case. `hooks/guard-trusted-writes.py` keeps
judging a verified linked worktree at `.claude/wt-*/` relative to its root; its
header (Worktrees paragraph, the Bash no-exemption paragraph), the section comment
above `_is_soft_parts` and the `_worktree_root` docstring now say the harness no
longer creates that shape (7b46a90e moved the self-improvement loop to
`.worktrees/si-wt-*`; b3e25cf1 moved the build loops to `.worktrees/`) and that the
case stays for worktrees left from before, in this repo or another.
New test: "worktree taint: a leftover .claude/wt-x worktree is still judged relative
to its root" in `test/hooks/guard-trusted-writes.bats`.

## Findings

- What creates `.claude/wt-*` today: nothing. `rg -n "\.claude/wt-" scripts/ skills/
  workflows/ hooks/ guides/` hits only the guard itself, a history comment in
  `scripts/self-improvement.sh` (line ~493, "It used to be .claude/wt-<task>") and
  an example in `scripts/lib/dev-cycle-read.sh` (line ~815). Tests in
  `test/scripts/build-loop-*.bats` use the shape as fixtures for leftover handling.
- Live leftovers in the main checkout: `.claude/wt-q096b` (a real linked worktree,
  branch fix/q096b-exit-scan-remote-names) and `.claude/wt-egress-dnsmasq-ipset` (a
  stale worktree: its `.git` file points at a gitdir that no longer exists, so it
  is not in `git worktree list`, fails verification and is judged by the blanket
  `.claude` rule under every option).
- History of the case: ccda554e (exempt agent worktrees), 835f99dd (verify at hook
  time, Q-048), 3e9e448b (withdraw the Bash exemption), f2829bcf (file tools judge a
  `.claude/` worktree path relative to its root), 5070403e (no-cwd fail closed).
- The exemption only relaxes a path under a root verified from git's own files
  (`.git` file -> `worktrees/` gitdir -> back-pointer), not a symlink, not near the
  config dir or home; the worktree's own policy files (CLAUDE.md, `.claude/`, root
  hooks/ and settings*.json, `.git`) still ask when the session is web-tainted.
  Bash has no exemption at all.

What a write inside `.claude/wt-q096b/` is judged as, session web-tainted:

| Option | `notes.md` there | `CLAUDE.md` there |
|---|---|---|
| Drop the case | ask (blanket `.claude` SOFT) | ask |
| Keep, correct comments | no opinion (as in a main checkout) | ask |
| No change | no opinion | ask |

Untainted session: no opinion for both under every option.

## Divergent design (three options)

Constraints in play: S1 (proportionate: a restriction must remove real risk), S5
(motive first; status quo valid), H2 (fail closed), S8 (small, one-revert units).

- Drop the case. Removes no real risk: the relaxation applies only to a verified
  git worktree and leaves its policy files asking, the same treatment a main
  checkout and `.claude/worktrees/<name>/` get (S1). It adds asks in the leftover
  worktree and any such worktree in another repo using this harness, and it would
  force re-pointing about a dozen existing tests (11 fail with the `wt-` branch
  disabled) that use `.claude/wt-foo` as the
  main fixture (S8).
- Keep, correct the comments. No behaviour change; the comments stop claiming the
  shape is the harness's current one. Smallest diff; one revert undoes it.
- No change. Leaves comments that describe a layout the harness no longer makes,
  which is the defect the brief names.

Path A: keep the case and correct the comments dominates. The stale comment is the
whole motive (S5); dropping trades asks for no removed risk (S1).

Other choices (one line each):
- Test location: next to "Bash in a worktree is unchanged", reusing `worktree_layout`.
- The test also pins that a plain `.claude/wt-*` directory (no git worktree) asks,
  the fail-closed side (H2). A mutation check (disabling the `wt-` branch in
  `_worktree_root`) made the new test fail with "want defer, got ask"; reverted.

## Live-verify gate

`hooks/live-verify-gate.sh` lists only `devcontainer-config/` files (its
`enforcement` and `host_tools` patterns), not this hook, so no `Live-verified:`
trailer is required; none is carried.

## Gotchas

- Failure-pattern grep: FP-011, FP-013, FP-014, FP-062, FP-068, FP-185 (see Prior failures section)
- Bash writes naming `.claude` plus a policy name are denied by this very guard,
  so the hook was edited with the Edit tool, not a shell script.

### Prior failures

`grep -inE 'guard-trusted|write-guard|exemption|stale-doc|stale-comment|worktree|wt-' docs/failure-patterns.md`
matched on "worktree" (an earlier grep without that word matched nothing):

- FP-185 (2026-11-19): the web-taint guard asked on every edit in a worktree under
  `.claude/` because the blanket `.claude` segment rule caught whole checkouts;
  fixed by narrowing the guard (f2829bcf). This is the exemption itself, and it
  is the reason against dropping the case: dropping it brings FP-185's symptom
  back for any `.claude/wt-*` worktree still in use.
- FP-011, FP-013, FP-014, FP-062, FP-068: worktree lifecycle and base-path bugs
  in the loops (partial add, exit trap, stale `.git/worktrees` entry, relative
  base override, artifacts deleted with a worktree). None bears on path judging
  in the guard.

Failure-pattern skip: no fix(...) commits on this branch; the change is comments and a test.

## Tests

- `test/hooks/guard-trusted-writes.bats`: 108/108 ok (with the new case).
- `test/hooks/web-taint-mark.bats` + `test/link-claude-home-wiring.bats`: 34/34 ok.
- `scripts/hermeticity-lint --root .`: exit 0.
- `scripts/confine-tests.sh --probe`: exit 3, first line "confine-tests: NO
  CONFINEMENT PRIMITIVE AVAILABLE — refusing to run." So the suites ran
  unconfined, with the hermeticity lint as the check.
- Review round 1 (one reviewer, code-fact-check focus): no red findings. The
  ambers were in this doc (an incomplete FP grep, a missing test record, an
  overstated test count) and are fixed here. The comment wording is widened to
  "any such worktree" and long lines are rewrapped.
