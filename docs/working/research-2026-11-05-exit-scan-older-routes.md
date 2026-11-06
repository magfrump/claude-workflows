# Research: the exit scan's two older routes (Q-097)

**Goal:** decide under S1, for each of the two Medium routes the exit scan does not see, whether a fix earns its cost, and close the route or record why it stays open.
**Project state:** guide-only outcome for Q-097 · standalone unit of dev cycle 2026-11-05-2347 · not blocked.
**Task status:** complete (both routes stay open, reasons in the guide; no change to `cc-exit-scan.sh`).

Brief: `docs/working/briefs/2026-11-05-exit-scan-older-routes.md` at db31db8b. Branch: `fix/exit-scan-older-routes`. Workflow: RPI with no plan gate, divergent design inline, then pr-prep's review-fix loop.

## Result

| Route | Who could reach it | Honest path | What `cc-push` bounds | Decision |
|---|---|---|---|---|
| (a) link to a repo outside the checkout | Only a session that writes outside the checkout, on a host where the container's layer or a named volume is readable | None found | The push, in full; not host git you run by hand | Stays open |
| (b) non-standard container-form `.git` at launch | A later session, usually after a first one warned about the leftover (exceptions: an unscanned session, a nested repo launched one level up) | A four-step chain, harmless unless the session's write is itself harmful | The push, in full; not host git you run by hand | Stays open by design |

Neither route has a recorded occurrence. Both A4's and A5's revisit triggers in the Q-094 rubric are unfired: `devcontainer.json` still mounts only the checkout and two named volumes, and a search of `docs/working/` and the commit log since 2026-09-28 finds no report of a leftover container-form `.git` (the hits are design notes and T1's sort).

## Sources read

- `docs/reviews/code-review-rubric-2026-09-28-q094-final-B.md` (A4, A5) and `docs/reviews/security-review-2026-09-28-q094-final-B-fix.md` (F1, experiments E1, E1c, E6).
- `guides/cc-isolated-usage.md`, "Known routes it does not see" and its boundary paragraph.
- Override-log row 135: "Only matters for a state already present at launch, which launch_gitdir_ok now refuses; fold into cc-gitdir.sh at the next scan change." No scan change here, so its trigger does not fire and the fold stays out of scope.
- Q-172 [2] (`docs/working/questions-archive.md`): "Close only routes that need no state planted before launch; list the rest as known routes", with "Routes that need launch-time state stay open by design" under its "If it's wrong" column. Its motive was the scan growing from 761 to 1,364 lines in 18 days. Q-238 applied the same boundary to drop Q-168.
- `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md`, section 1: the sort that reads Q-172 [2] and places T1 (a CR-ended form of route (b)) out, as "an earlier session's leftover".
- `docs/working/research-2026-11-01-restriction-audit.md`: the scope test and classes.
- `devcontainer-config/devcontainer.json:77-79,134`, `devcontainer-config/cc-push.sh` (`:361-368`, `:510-532`), `devcontainer-config/cc-exit-scan.sh`.

## Threat reading

S1 and the owner's 2026-10-30 note put a hostile branch or loop author out of scope. The exit scan was built against something else: Q-069's session whose planted hooks a plain host `git status` would run as you. Q-069's option [4] names the actor: "An injected agent gets your ssh keys at your next push". That is content from outside steering a session, an outside party, which the audit's classes keep. So each route is judged twice below: can an honest mistake reach it, and does an outside party steering a session gain anything from it that a sibling route does not already give?

## Probes

Run on git 2.39.5 against this branch's `cc-exit-scan.sh` with `GIT_EXIT_SCAN_CONTAINER_WS` pointed at a path that does not exist, in a fresh temp dir with its own `HOME`. `scan` is `git_exit_scan` against a launch snapshot; status 0 is silent, 1 is a warning.

| ID | Setup and action | Main | With candidate [b1] |
|---|---|---|---|
| A1 | Link `vendor/x` to an outside repo, added in the session | 0 | 0 |
| A2 | A1, plus a hook in the outside repo | 0 | 0 |
| A3 | Host `git commit` through the link | hook ran | hook ran |
| A4 | Control: the link is named `.git` | 1 | 1 |
| B1 | Bare `foo.git` plus worktree `wtx`, container form at launch; hook planted in `foo.git/hooks` | 0 | 1 |
| B2 | B1, then `git -C foo.git worktree repair wtx` and a checkout | hook ran | hook ran |
| B3 | Control: B1 in host form | 1 | 1 |
| B4 | Bare `foo.git` with no linked worktree; hook planted | 0 | 0 |
| B5 | The B1 layout made during the session | 1 (`+ dotgit`) | 1 |
| B6 | `.git` maps to `foo.git`; hook planted in `other.git`, which holds a `worktrees/wtx` | 0 | 0 |
| B7 | B6, then repair from `other.git`: `.git` now names `other.git/worktrees/wtx` | hook ran | hook ran |
| B8 | `gitdir: <ws>/gone/../.git/worktrees/agent-x` at launch, relative `core.hooksPath`, plant under it | 0 | 0 |
| B9 | Control: standard container form, hook in the common dir | 1 | 1 |

B1 and B3 reproduce E1 and E1c; B8 reproduces E6. B7 adds the by-name case with a plant in a repo other than the mapped one.

The review added and I re-ran two more (`extra.sh`, scratch only):
- **N1, no warning at any step.** A session on repo `a`, nested in repo `P`, adds a standard agent worktree (a note, status 0). You add a relative `core.hooksPath` in `a`. The next launch is on `P`, where `gitdir: /workspace/.git/worktrees/x` maps to nothing. A hook written under that path in the worktree is silent (status 0); host `git worktree repair` from `a` and a checkout run it. Launched on `a` itself, the same write warns.
- **N2, following the guide's old advice.** After B1's plant, host repair, then a new session: the baseline holds the plant, the exit is clean, and host checkout runs the hook. The guide told people to "repair them and start a new session"; this change replaces that advice.

A `python3 -m venv` gives only file links outward (`bin/python3 -> /usr/bin/python3`), which the directory walk would not be asked about.

Not run: no Docker here, so the claim that a rootless daemon keeps volumes under a path the host user can read, and that Docker Desktop's are out of reach of host git, is general knowledge, not a measurement. If Docker Desktop's volumes were reachable from host git, route (a) would be wider than stated, on the default runtime. The decision still holds: the honest-path answer does not depend on it, and the outside-party case stays dominated by simpler routes.

## Route (a): a link to a repository outside the checkout

**Who.** A plant behind the link is a write outside the checkout. The container's bind mount is the checkout alone; its other writable places are its own layer (no `--read-only`) and two named volumes (`devcontainer.json:77-79`). So the plant needs a host where that data sits at a path the host user's git can read.

**Honest path: none found.** Three shapes, none of which lands:
- A link the session makes for itself names a container path (`/home/node/.claude/...`) or a relative one. On the host that path is something else or dangles (the mirror of FP-167).
- A link naming the volume's host path dangles inside the container, so no session has an honest reason to write it.
- A link you made to one of your own repositories leads to content the session cannot write. There is nothing to report, and walking it would record your own repo's changes as session findings.

**Outside party.** A steered session could write such a link on a rootless host; that is the rubric's A4 case, with Low confidence on reach. It also needs you to run git through a link you did not make. A steered session has simpler silent routes in the same list: "A hook that runs a tracked file" needs no outside write at all.

**`cc-push`.** It reads `<checkout>/.git` only, by name, with `git-upload-pack --strict`, and refuses a `.git` that is not a real directory (`cc-push.sh:361-368`, `:510-532`). A link in the working tree is never read. That bounds the push; host git you run by hand through the link is outside it.

**Q-172 [2].** The boundary covers "what a session can write in the checkout". This route's plant is outside the checkout, so the route is outside the boundary.

### Divergent design, route (a)

Candidates:
- [a0] status quo, reason recorded in the guide.
- [a1] follow links to directories outside the checkout and walk any repo there.
- [a2] a finding for every working-tree link whose target leaves the checkout.
- [a3] a finding only when an outward link's target holds a git dir.
- [a4] read the mounts on the host and report only links into writable ones.
- [a5] refuse to launch on rootless Docker.

Constraints that bind: S1, S5, S8, S10, H3, Q-172 [2].

| Candidate | Outcome | Reason |
|---|---|---|
| [a0] | **Chosen (Path A)** | Meets the brief's "stays open, because"; costs nothing; unfired trigger |
| [a1] | Pruned | Records repos the session cannot write, so your own commits there become findings (S10). The scan's "reads the checkout" contract grows to any path a link names |
| [a2] | Pruned | Limited to directory links it stays quiet on virtualenvs, but fires on ordinary outward links such as `npm link` (general knowledge, not probed). Q-094 exists because a warning on ordinary state costs attention every session |
| [a3] | Pruned | Quiet, but a link to your own repo warns with nothing planted, and a plant reached by a link one level up does not match. It also needs a check per link over the whole tree (cost not measured) |
| [a4] | Pruned | The scan would run `docker inspect`, a new dependency for it that must fail closed when the daemon is down, for a route with no occurrence; S1 |
| [a5] | Pruned | Removes a whole runtime (decision 015 names rootless podman as its fallback) over a route with no occurrence; S1 |

Stress test. *Invert the thesis:* the strongest case for acting is that a link makes the scan silent where a plain directory warns (A2 against any embedded repo). That holds only for a target the session can write, and that set is believed empty for host git on Docker Desktop and rootful hosts (not measured; see Probes). *Boring alternative:* [a0] is the boring one. Hypothesis: if [a0] is right, no report of a repository reached through such a link appears, and no launch path gains a writable outside mount; counter-evidence would be either one, which is the revisit trigger.

Revisit triggers: a launch option or mount adds a host path outside the checkout that the container can write; or rootless Docker or podman becomes the supported default (the honest-path answer does not change, but the outside-party reach does).

## Route (b): a non-standard container-form `.git` at launch

**Who.** The state normally draws a warning: made in a session it is a `+ dotgit` finding (B5). The rubric and security review say only a warned session can leave it, which is too strong. Two exceptions: a session that was never scanned (a closed terminal), and a standard worktree whose checkout is later launched one level up, where the path no longer maps (N1). Either way a later session does the writing. The old advice ("Delete such files, or repair them") included step 4 below (N2), so the guide now says to delete.

**Honest path: one chain, four steps** (the usual shape; N1 replaces steps 1 and 2 with nested repos launched at two levels, which is equally unusual).
1. A session makes a bare repository inside the working tree (`foo.git`) and a linked worktree of it. Nothing in this harness does so: agent worktrees belong to the checkout's own `.git` and stay in the standard form, which is walked (B9). `git init --separate-git-dir` with a `/workspace/...` path gives the same `.git` form.
2. That session exits with a warning naming the `.git`, and the file stays.
3. A later session writes a hook there, for example by running `pre-commit install` in the worktree. The scan is silent (B1).
4. You run host git inside `foo.git` to repair it, then commit in the worktree (B2).

Only step 3 needs care to be harmful: an honest tool's hook runs the project's own hook config on your host, which is the "hook that runs a tracked file" risk you already carry for any hook. The standard form, the one ordinary use produces, has no gap.

**Outside party.** A steered session gets nothing here it lacks already. B4 shows a hook planted in a bare repository in the working tree is silent with no container-form `.git` involved; the guide's bullet "A repository in a working-tree directory not named `.git`" lists it. In the bare-repo chain, step 4 is host git run in exactly such a directory. In N1 and B8 repair runs in an ordinary repo, and the plant is under a relative `core.hooksPath` in a worktree, which is the reach "A hook that runs a tracked file" already gives.

**`cc-push`.** The same bound as route (a): it never reads an embedded `.git` or a linked worktree's, and `git worktree repair` is not part of it. It bounds the push, not host `git commit` or `checkout`. It also cannot push a repository other than the checkout's, so the bare-repo layout pushes you toward host git; that is one more reason the guide must not recommend repair.

**Q-172 [2].** The route needs state present at launch, and that state is not ordinary setup, so the boundary says it stays. The 2026-10-25 sort already placed T1, the CR-ended form of this route, out on that reasoning. One precedent pulls the other way and is worth naming: the same sort kept R3 in, an embedded `--separate-git-dir` repo called "rare but ordinary setup". The difference is the origin: R3's state is a repo layout that works on the host as it stands, while a `.git` naming `/workspace/...` can only come from a container, and no ordinary single-level workflow leaves a non-standard one.

### Divergent design, route (b)

Candidates:
- [b0] status quo, reason recorded in the guide.
- [b1] run `_snap_gitdir` on the mapped dir, as the host form does (3 lines, probed).
- [b2] the rubric's fix: [b1], plus walk your config's relative paths for every unresolved `.git` with all `includeIf` conditions matching, plus the inferred `<common>/worktrees/<name>`.
- [b3] refuse the launch on a non-standard container-form `.git`.
- [b4] warn on the leftover itself at every exit, even when it was there at launch, as the scan already does for an invalid git dir.
- [b5] walk every bare-layout directory in the working tree, which also closes the sibling route.

Constraints that bind: Q-172 [2], S1, S5, S8, S10, H3.

| Candidate | Effort | Coverage (B1, B6, B8, CR form) | Key downside |
|---|---|---|---|
| [b0] **Chosen (Path A)** | Guide text | None | The route stays |
| [b1] | ~3 lines, tests, trailer, review panel, owner review | B1 only | B4, B6 and B8 stay silent, so the guide bullet stays and the route is not closed |
| [b2] | Not measured; a few dozen lines by eye | B1, B8; not B6 | Models repair by name, the kind of "resolve like git" work Q-172 [3] was offered and not chosen |
| [b3] | Not measured; about ten lines by eye | All four | A hard stop at launch for a state that may be an honest layout; S10 |
| [b4] | Not measured; about ten lines by eye | All four | Still a new unit on the scan, against Q-172 [2]; warns each exit until the file is cleaned up |
| [b5] | Tree-wide `HEAD` search | B1, B6 and the sibling route (B4); not B8 | Row 133's deferred cost, a family unit Q-172 stopped |

Pruned: [b1] because it does not close the route and its sibling (B4) leaves the same plant silent: S1's "do not add a restriction whose bypass is already allowed". [b2], [b3] and [b5] for the reasons in the table. [b4] is the best of the fixes, because it reports the state and does not need to model what repair would do, so it is the one to build if the trigger fires; the rubric's recommended fix is superseded by it.

Why [b0] dominates rather than ties: the owner set this boundary to stop exactly this kind of unit, the state is not ordinary, no occurrence exists, and every fix pays a review panel and an owner review for a host tool on a 1,361-line file (S8's spirit, Q-172's motive). Under S5 the status quo needs no further case once the benefit is not shown to be real.

Stress test. *Invert the thesis:* [b1] is three lines and gives host-form parity, so why not take it? Because parity with the host form is not what the route is. B6 shows repair can land on a repo the mapped path never named, so a reader of the changed guide would have to keep the bullet anyway, and the cost is not the three lines but the enforcement unit around them. *Failure-driven:* [b0] adds no failure mode. Hypothesis: if [b0] is right, no report of a leftover container-form `.git` from ordinary use appears; counter-evidence is one such report.

Revisit trigger: A5's, narrowed. A5 reads "a container-form `.git` left by an earlier session", which every agent worktree now meets, so this is: a finding or report of a non-standard container-form `.git` left by ordinary use. Then build [b4], not A5's walk.

## Plan

1. Guide: add the reason and the revisit condition to both known-routes bullets, and replace the "repair them" advice (N2). No other file.
2. `devcontainer-config/cc-exit-scan.sh` does not change, so no enforcement trailer applies and no pre-mortem is needed (the brief asks for one only for a plan that changes an enforcement file). Test strategy: no behaviour changes; the review's fact-check against the probes is the verification. No bats case tests guide prose here.
3. No decision record: the choice applies an existing owner decision (Q-172 [2]), and this doc holds the design record the brief asks for.
4. Set the brief's status line to done in the final change.

## Gotchas

Failure-pattern grep: FP-034, FP-146, FP-167

- FP-034 (a fixed temp path followed through a symlink) is the same family of mistake only in name; no bearing here.
- FP-146 (a link hashed by target only, so rewritten content is invisible) is the known shape behind route (a): the scan records a link, not what is behind it. The decision accepts that for outside targets.
- FP-167 (a tracked link to an absolute host path dangles) is the mirror fact this research uses: a link's absolute path means different things on the two sides.

- Q-097's entry says "one enforcement unit each"; the brief's goal allows a recorded "stays open", and that is the result. A branch named `fix/` carries no `fix(...)` commit here, so no failure-pattern entry is owed.
