# constraints-builder: deferred hardening for untrusted repos

**Status:** open · **Opened:** 2026-10-19 · **Decision:** log row 73 (v1 trusts the operator's own repos)

**Revisit trigger:** before the skill is run on any repo not solely written by the operator and
their own agents (a shared, forked or third-party repo). Also revisit if an agent outside the
operator's own sessions and loops can write a target repo's `.git/config`, `.git/config.worktree`,
`refs/replace/`, or files those include. The operator's own build loops and sessions, running as
the operator's uid, can write git config; that is Q-103's accepted same-uid residual (Q-213 [1]).

v1 of `skills/constraints-builder` declares untrusted target repos out of scope (its "Scope (v1)"
paragraph). Three review iterations of the skill (pr-prep, 2026-10-19) kept finding new ways for
git to run commands a repo chooses. The user chose to ship for sole-author repos first and harden
later. This file is the hardening backlog. Each item names its probe evidence; the probe logs
were in the session scratchpad and were not committed.

## Git runs repo-chosen code (needs a trust boundary, not a denylist)

1. **A config denylist cannot keep up** (iteration 3, security F1 High; fact-check claims 6b/9b/12b,
   all three replicates). `git config --local --get-regexp` misses `include.path`, `includeIf`
   and `config.worktree`. In probes, filters set those ways ran during `git archive`, and
   `gpg.program` with `log.showSignature=true` ran during the skill's own `git log --all` and
   `git show -s`. Candidate fix: an allowlist over `git config --list --show-scope --includes`
   for the local and worktree scopes, plus `-c log.showSignature=false` on log and show.
2. **Tree `.gitattributes` picks the operator's drivers** (iteration 3, security F2). `git archive`
   ran a global smudge filter, and `git blame` ran textconv, on hostile blobs (git-lfs is the
   common case). Candidate fix: build the scratch copy with `cp -RP` of the working tree instead
   of `git archive`, and use `blame --no-textconv`.
3. **Blame provenance can be spoofed** (iteration 3, security F3). `.git-blame-ignore-revs` with
   `blame.ignoreRevsFile`, and `refs/replace/*`, both made agent-written lines read as the
   author's. Candidate fix: `git --no-replace-objects blame --no-textconv --ignore-revs-file ''`,
   and treat a non-empty `refs/replace/` as a finding. v1 already calls provenance "a check,
   not proof" and lists author-backed hard lines in the ratify entry.
4. **"Fresh main" could be read as a fetch** (iteration 3, security F7). That would run
   `core.sshCommand`, `remote.*.uploadpack` and merge hooks. Candidate fix: say "local main, no
   fetch".

## Other edges

5. **rg follows a symlinked search path out of the repo** (iteration 3, security F5). A match from
   outside could land in the working doc. Candidate fix: require `realpath -- PATH` to sit inside
   the repo, the same guard the plant step uses.
6. **The reader brief does not ban network tools** (iteration 3, security F6). An injected reader
   could leak through WebSearch or WebFetch without "running" anything. Candidate fix: "fetch and
   search nothing" in the brief, and choose a tool set without network where the host allows it.
7. **Readers are only instructed, not confined**, where the host offers no read-only agent type
   (iteration 2, security F6). The wording is honest; the fix is a host capability.

## Already fixed in v1 (for the record)

- Corpus success lines are never executed: the agent writes every check, and repo code is
  "author to run".
- Readers run nothing; the main agent extracts off-tree files for them.
- Ref and path names pass an allowlist and go in single quotes.
- The plant step works in a temp copy, under a trap, with a realpath check.
- Only the installed parser and the installed questions script are used.
- A draft is parsed only on exit 0 and the exact `(draft)` ok line.
- Ratification is the author's own commit.
