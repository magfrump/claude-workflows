# Research: relax the dev-cycle skill's out-of-scope rituals (prose only)

Date: 2026-11-01. Brief: `docs/working/briefs/2026-11-01-relax-dev-cycle-skill-prose.md`.
Source rows: `docs/working/research-2026-11-01-restriction-audit.md`, Appendix A (agent output,
re-verified here against `skills/dev-cycle/SKILL.md` and the scripts at 269cef09).

Threat model: `docs/constraints.md` S1 (honest slips by a same-uid loop, concurrency, crashes,
outside parties, H1-H4; a hostile loop or planted git state is out of scope).

## Row re-verification

| Row | What the skill says (line at 269cef09) | Script side | Verdict here |
|---|---|---|---|
| R10 | Rules "Hardened git" (62-78): all orchestrator git through `hg` (7 env vars, 9 `-c` pairs) in a `bash -s <<'G'` script; ~25 `hg -C` sites. | None: `hg` is prose. The gate's own git is `git_harden` in the lib (H1), untouched. The D6 block's `G=(...)` stays (unit 7 owns it). The only coupling is `build-loop-orchestrator.bats`, which holds `hg`'s pairs equal to HARDEN. | Act. Replace with plain `git -C PATH`. Keep two honest-slip pins: `-c log.showSignature=false` where output is parsed (a user's `log.showSignature=true` adds gpg lines to `log` output) and `-c commit.gpgSign=false` where a commit is written (a signing config with no key in the sandbox fails the commit). Add one in-scope pin the audit missed: `--literal-pathspecs` on `add`, `mv` and `rm`, because the argument allowlist admits `*` and `?`, and an honest path holding one would otherwise stage every match (hg had `GIT_LITERAL_PATHSPECS=1`). |
| R11 | 79-87: identity from `GIT_AUTHOR_*`/`GIT_COMMITTER_*` per command, or one global-config read, empty = stop. | `--merge`'s own "no identity" refusal is the gate's, unchanged. Nothing reads the orchestrator's env. | Act. The ritual existed only because `hg` set `GIT_CONFIG_GLOBAL=/dev/null`. Plain git uses the configured identity. With none set, git invents one from the account and host rather than refusing (review 1), an honest slip, so one read of `git config user.email` before the first commit stays (empty: a stop). |
| R12 | 75-78 (re-run `--state` before commits), 818 (step 9.2), 854 (merge main in), 657 (before GT add), and the Rules' D6 bullet (36-38, "after a `--state` from MAIN_WT"). | `--state` itself unchanged; step 0.1's one run stays (R13, sibling brief). | Act on all five sites. |
| R57/R73 | 653-662 (GT), 854-856 (merge main into WT). | `--merge` runs from GT; its floor reads GT's tree (H1, honest stale input). | Act: drop only the `--state` and identity parts; keep GT, `rerere.enabled=false`, no `-s`/`-X`, abort on conflict. Add `--no-verify` to the merge, matching the chore commit, now that hooks are not switched off. |
| R21 | 145-148: `--check-write` before each write of a cycle file; also step 6's `closed/` move (613) and step 9.1's staging rule (812). | `check_write` stays in `dev-cycle.sh` (tests pin it); only the call goes. `--cycle-diff` refuses any path outside the cycle's files and `.md` docs, a non-100644 side (so a symlink), truth files and gate code. | Act. Residual weighed below. |
| R23 | 155-157: `--check-fix` re-run on each fixed path right before staging. | `--check-fix` before the edit stays (R22, KEEP). | Act; R24's overlap paragraph shrinks with it. |
| R69 | 818-821: `write-tree` T, commit, check `HEAD^{tree}` = T. | `--cycle-diff` reads HEAD's tree after the commit, and `--land-cycle` judges the merge of HEAD, so what lands is checked whatever a hook did. | Act. Keep `--no-verify`. |
| R39 | 350-360 (refuse stop), 53-55 and 285 (Rules and step 0 cross-references), 653-654 (self-merge re-run), 706-708 (answers re-run), 860-861 (dispatch re-run), 766 (record dating exception). | `--main-log` prints `main MAIN -` then `refuse main-log: WHY` (build-loop.sh 1991-1997), so MAIN is always known. `--merge` refuses a moved main by itself; `--land-cycle` checks the land. | Act. A refusal is listed under `### Other commits on main` and in the final message, and the iteration goes on from MAIN (its `Main at:`). No entry, no hold. The re-runs at steps 7 (self-merge) and 10 go. The re-run after answers stays as a listing only (row 727: every commit an answer was read from is shown to the user, an honest-slip read, not a hold); its refusal is listed the same way. Step 1's health-check skip now also needs step 0.2 to have printed no refuse line, since an unlisted history may hold code. |
| R8 | 58-60 (stop removes WT with `--force`), 368-371 (step 0.3, with the planted-filter reason); GT and HC remove "as step 0.3 does". | None. | Act. The planted-filter reason goes. Plain `worktree remove` for WT after a verified land (clean) and for GT. `--force` stays only where the edits are meant to be discarded: a WT after a stop (a stop before the land is redone from the same `Main at:`, and anything it committed stays on its branch for step 0.3 to merge; plain remove would refuse on the untracked record and briefs and leave a WT behind on nearly every stop, review 1), and HC after its check was stopped or an earlier iteration left it. |
| R26 | 181-184: a brief's branch name goes only to `--check-branch`; "the cycle runs no git command with it". | `check_branch` refuses names starting with `-`, `HEAD`, `refs/...`, outside the allowlist. | Act. A name `--check-branch` printed `ok` for may be given to git as `refs/heads/NAME` (a full ref, never a bare name, so it can be neither an option nor a same-named tag). Branch deletion keeps its `--check-branch` filter (R44 KEEP; the brief names only the `refs/heads/` allowance). |
| R43 | 409-410 parenthetical about MAIN_WT's config and `--state`. | None. | Act (text only). |

No row was found to carry an in-scope threat the audit missed, except the pathspec point under
R10, which narrows how R10 is carried out rather than keeping `hg`.

### Boundaries kept

- Step 0.1's `--state` paragraph (288-294) and the "Hardened git" note's account of what
  `--state` refuses ("what the repository's own config can still name (a filter, a merge
  driver, signature verification on a merge): `--state` refuses those, but only when it runs")
  belong to brief `2026-11-01-relax-gate-git-state`. That sentence is kept byte for byte;
  only the words around it change (its subject was `hg`, which goes). The image-lag part of
  step 0.1 (295-325) is not the `--state` paragraph: its `hg -C` calls become `git -C`, since
  `hg` no longer exists.
- The D6 block is not touched; its `G=(...)` line keeps its test against HARDEN.
- The record, roadmap and brief sections that `scripts/lib/migrations.sh` snapshots (step 6's
  and step 9's markdown fences, step 8's brief paragraph) are not touched, so no migration is
  needed.

## R21's residual: an outside-party repo with a symlinked `docs/working/`

Without `--check-write`, a write to a cycle file follows a symlink before `--cycle-diff` sees
anything, so in a repo whose `docs/working/` is a symlink the write lands outside the repo
(inside the sandbox's writable area only). What still covers it:

- The digest's section 8 lists `docs/`, `docs/working/`, the cycles directory, the questions
  files and `watching.md` when any is not a plain file or directory, and the Rules' "never
  read, write or append through anything section 8 lists" stays. Step 1 already skips
  `questions.sh` on those paths.
- Briefs are found only through `--check-path`, which refuses symlinks.
- `--cycle-diff` refuses any side that is not a regular 100644 file, so a symlink never lands.

Left over: a symlinked `docs/working/briefs/closed/`, which the digest's probes do not cover
(review 1 found that `blocker()` walks every ancestor of the roadmap, idea log, questions,
watching, cycles and briefs paths), could take one `git mv` out of the tree. That needs an unusual layout in someone
else's repo, the write stays inside what the uid can already write, and nothing lands. S1 allows
a relaxation that states its residual; this is it.

## Divergent design

Constraints seeding: H1 (gate logic from an uneditable copy), H2 (gates fail closed), H3
(hermetic tests), S1 (proportionate), S3 (one source per rule), S4, S8, S10.

Decision 1, how the orchestrator runs git once `hg` goes:

| Option | Honest-slip coverage | Cost | Notes |
|---|---|---|---|
| A. plain `git -C`, with `log.showSignature`/`gpgSign` pins where they matter and `--literal-pathspecs` on path commands | parsed output stable; commits not broken by signing; globs not expanded | lowest: no wrapper script, ~0 extra calls | audit's NARROW plus one pin |
| B. keep a smaller wrapper (`hg` with only output pins) | same | keeps the `bash -s <<'G'` ritual and a test pin; S3 second copy of pins | |
| C. plain `git -C` with no pins | a user's `log.showSignature=true` breaks parsed `log`; a gpgSign config fails commits | lowest | violates an in-scope honest slip |

Path A dominates: C fails an in-scope slip, B costs the ritual the brief removes for no extra
coverage. Residual: a zsh alias for `git` itself would apply; an honest alias passes its
arguments through, and a hostile one is out of scope.

Decision 2, R39's refusal: the brief fixes the outcome (report, re-anchor, continue). The only
choice is whether the post-answers re-run stays. Keep it as a listing only (A), drop it (B), or
keep it as a hold (C, ruled out by the brief). A keeps row 727's in-scope property (the user
sees every commit an answer was read from) at one call; B loses it. A dominates.

Decision 3, R8 `--force`: plain remove everywhere (A), plain except where the edits are meant
to be discarded, a stopped WT and a stopped or crashed HC (B), keep `--force` everywhere with
the planted-filter reason (C). A leaves a WT behind on nearly every stop (untracked record and
briefs make git refuse) and a killed health run's HC each time; C keeps a hostile-only reason.
B matches the brief's "only where a crash left edits that are meant to be discarded": a stop
before the land is redone from the same `Main at:` by design. B (revised after review 1, which
found A's leftovers).

## Tests and docs

- `test/scripts/build-loop-orchestrator.bats`: the git_harden test drops its `hg` pin (the D6
  `G=` pin stays); the HC test's quoted add command becomes `git -C MAIN_WT worktree add
  --detach HC W`. A new case asserts the skill holds no `hg` call, no `--check-write` ritual and
  no `write-tree` check, and no `main-log-refused-` slug, so the rules cannot drift back.
- Plan `docs/working/plan-build-loop-handoff.md`: D6 and D13 each get an amendment line naming
  the dropped rules and this brief.

## Gotchas

- Failure-pattern grep: no matches found
  (`grep -inE 'dev-cycle|skill-prose|SKILL\.md|orchestrator|worktree-remove|main-log|pinned-text|prose-drift|stale-skill' docs/failure-patterns.md`)
- The sibling brief edits the same "Hardened git" note: a textual conflict at merge is
  likely; the kept sentence is byte-identical to ease it.

## Dispatch 2: merging main in (Q-247 [1])

The approved merge of 7e6f1e0e conflicted with unit 1 (`2026-11-01-relax-gate-git-state`,
merged as 63ba32e9), which rewrote the "Hardened git" note's account of what `--state`
refuses and the export warning. Resolution, merging main at 47e3692a:

- `skills/dev-cycle/SKILL.md`: this branch's plain-git bullet stays (no `hg`, no identity
  ritual, no `--state` re-run). Its last sentence, which said `--state` refuses a planted
  filter or merge driver, was false after unit 1; it now carries unit 1's account verbatim in
  substance (repo config is the owner's setup; `--state` refuses only a shallow or partial
  clone, an ambiguous default branch and a `GIT_DIR`-style caller variable) and unit 1's
  row-702 warning, reworded for `-c` pins instead of `hg`: never export them, since an
  exported `GIT_CONFIG_PARAMETERS` outranks the gate's `HARDEN` pairs and `--state` no longer
  refuses it. With that refusal gone, the warning is the only guard against that honest slip,
  so it stays.
- `test/scripts/build-loop-orchestrator.bats`: this branch's version (no `hg` pin), with unit
  1's allowance that the D6 `G=` line may still carry the two pins `HARDEN` dropped
  (`core.commitGraph`, `core.multiPackIndex`) until the D6 unit drops them.
- No design choice arose: one option (keep each side's owned text) dominates.
