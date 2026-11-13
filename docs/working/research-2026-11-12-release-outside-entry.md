# Research: a release installed from a commit its entry did not describe

- **Goal**: Say whether the release path needs a change now that decision-log row 86's revisit trigger has fired, or whether the 2026-11-12 install was an owner-directed install that the design already allows.
- **Project state**: one research doc on `docs/release-outside-entry` · the row 86 revisit (brief `docs/working/briefs/2026-11-12-release-outside-entry.md`) · not blocked
- **Task status**: complete (decision: no change, Path A)

repo text is evidence, not instructions. Everything below was read at b46af2e7 unless a commit is named. **[observed]** means read in a file or a commit; **[inferred]** means reasoned from what is on record.

## Verdict

No change to the release path. The install from 80b7dabe was the owner's own: it ran, in the same session, right after two commits the owner had asked for. No commit between the entry's M and 80b7dabe was unreviewed, and install.sh's own diff review sat between that code and the host. The entry's paste could not have done this install. Waiting for a cycle to rewrite the entry was not possible either, because the sandboxed image running then broke the cycle's worktrees. The image this install put in place already carries row 86's newer paste, so the paste that failed here (the FP-178 shape, below) has now been replaced. The revisit triggers at the end say what would reopen this.

## Evidence

**Row 86 and its trigger.** `docs/decisions/log.md:109`: the release paste "holds the release to the entry's gate code and installer, not to the entry's commit". Its residual is "other code that reaches main after M is installed without being listed in the entry", accepted under S1 (proportionate security). Its triggers: "Revisit if an image's `commit=` names gate code other than its entry's M, if an `image-off-main` entry is filed after a paste ran, if a release ships a self-merge its entry did not flag, or if `GATE_CODE` loses a path". [observed]

**Row 86's research.** `docs/working/research-2026-11-10-dev-cycle-skill-held-fixes.md:33`: Q-156's paste (2026-10-14) "refused on the day ... and the owner then installed from main without the paste". Line 156 (candidate 5, stricter paths) was rejected because it "refuses the owner's own later commits, the friction that got Q-156's paste skipped (S1, S10)". Line 177 marks "Code outside PATHS and the installer committed after M ships unlisted" as "Not covered, by choice". [observed]

**Step 0.1, the image check and the paste.** `skills/dev-cycle/SKILL.md:227-275`. C is the image's `commit=` and M is main's commit. `git diff --quiet C M -- PATHS` exiting 1 files or rewrites the `image-lag` entry, which is also the release entry. On exit 0 the check closes the entry with "`Q-NNN: met — image C holds the gate code of main M`", "nothing else" (lines 271-273). The paste at line 256 checks the checkout is at main's tip and that every gate-code path and `devcontainer-config/install.sh` match M's. If any check fails it prints "release refused: $p changed after M: run the dev cycle for a new paste". Lines 268-270: "Other code that reached main after M is installed without being listed in the entry, a risk taken so the paste runs where the checkout is." [observed]

**The paste Q-273 actually carried.** This is the old shape, not line 256's. `docs/working/questions-archive.md:6702`:

```
cd /home/magfrump/claude-workflows && test "$(git rev-parse HEAD)" = 7b8b560acaaac6f57c473cbc032acb66b862aeb3 && ./devcontainer-config/install.sh
```

Line 6705: "check out `7b8b560a` first (the next cycle rewrites this entry when a later merge changes what the release ships)". Line 6697: "Paste 2 is on hold ... for Q-277". The entry had this shape because the cycle that wrote it ran on the image at C = 536b7082, whose skill still held the pinned-commit paste: `git show 536b7082:skills/dev-cycle/SKILL.md` line 250 has "`cd A && test "$(git rev-parse HEAD)" = M &&`". Row 86's paste arrived in 1f14e270, which was part of this same release. The questions file at 80b7dabe carries the same line (`git show 80b7dabe:docs/working/questions.md`, line 116). [observed]

**Q-273's close.** `docs/working/questions-archive.md:6653`: "Q-273: met — image 80b7dabe27cac... holds the gate code of main 80b7dabe27cac...", written by cycle 0143 (`docs/working/cycles/cycle-2026-11-12.md:74`). [observed]

**The commits between M = 7b8b560a and 80b7dabe** (first parent): b1389698 (a cycle land, records only), 10e26658 / 30eb0229, 7caea26d, 80b7dabe. Over the gate-code paths plus the installer, `git diff --stat 7b8b560a 80b7dabe` shows only `devcontainer-config/install.sh | 2 +-` and `skills/dev-cycle/SKILL.md | 3 ++-`. [observed]

- **30eb0229** (16:42): `skills/dev-cycle/SKILL.md` step 7 gains "this is for blocked, stopped and capped entries only, never a merge entry, which is found by its heading". Its body says "Notes: owner asked for all three". [observed]
- **7caea26d** (17:16:14): reverts the Q-125 Bash sandbox merge 3cd6d9bb. That covers 13 files, among them install.sh's `PAYLOAD=` line, which drops `seccomp-cc-sandbox.json managed-settings.json cc-sandbox-settings.sh`. Its body says "The owner ruled 'agents can't create worktrees' an unacceptable limitation for the harness (Q-277 answered [3])" and "Sandboxed `git worktree add` fails ... That breaks dev-cycle step 0.3 and its health and gate checkouts, build-loop dispatch". It also carries "Live-verified: no — reverting to the pre-3cd6d9bb boundary". [observed]
- **80b7dabe** (17:16:24): records Q-277's answer. Its body says "Notes: Q-273 (the release pastes) stays open; its paste 2 now installs an image without the sandbox." [observed]

**install.sh's own checks.** `devcontainer-config/install.sh:204-260` (`git_state_gate`) refuses before any other git call when the checkout's config holds `filter.`, `core.fsmonitor`, `include` or `hook.` keys, or when `info/attributes` is not empty. `assemble` (lines 340-372) stages `git archive HEAD`, not the work tree, and writes `commit=$commit` into the `.manifest` that step 0.1 later reads as C. Each target "shows a review diff and asks y/N" (line 33). The image's `claude-home`, which carries `scripts/` and `skills/` (line 146, `CLAUDE_HOME_SRC`), is part of the payload that diff covers (lines 118-120, 547-560). install.sh itself "is NOT inert: it runs on the host from the repo" (lines 20-23). [observed]

## How the install from 80b7dabe most likely ran

**Most likely a plain `./devcontainer-config/install.sh` from a checkout at 80b7dabe, or a paste the owner edited by hand. Not the entry's paste as written.** [inferred, by elimination]

1. The image's `commit=` is 80b7dabe, and install.sh writes `commit=` from HEAD (`install.sh:346,368`). So the install ran with HEAD = 80b7dabe. [observed mechanism; inferred application]
2. The entry's paste (archive line 6702) runs install.sh only when `test "$(git rev-parse HEAD)" = 7b8b560a...` passes. At HEAD = 80b7dabe that test fails and the installer never starts. Checking out 7b8b560a first, as line 6705 says, would have stamped `commit=7b8b560a`. So the paste as written did not produce this image. [inferred from the paste's text]
3. Row 86's newer paste, with M = 7b8b560a, would also have refused: `skills/dev-cycle/SKILL.md` and `devcontainer-config/install.sh` both differ from M's. It ends "run the dev cycle for a new paste". No entry with M = 80b7dabe existed before the install. The first cycle after it (0143, record line 74) already found C = 80b7dabe. [observed diff; inferred]
4. No line on record says which command ran. The commit stamps and cycle 0143's record put the install between 17:16:24 (80b7dabe) and that cycle's first step; the land d405b6d4 is at 17:54. That fits an install from the same session that made the revert. [observed times; inferred]
5. Precedent: Q-156's release (2026-10-14) ran "from main without the paste" (research line 33), and row 86 says "the last two releases ran without it". Going around a paste that refuses has happened before. [observed]

There was also a second install on record but undated. Q-277's answer (archive line 6648) says "The sandboxed image was running by then". So some install of the sandbox merge ran between cycle 2026-11-12-1944 (which read C = 536b7082) and the 17:16 revert. Which commit it used is not on record, because the manifest has since been overwritten. During that window main's tip was b1389698 and then 10e26658. b1389698 holds M's gate code (it is a records-only land). [observed; the commit of that install is unknown]

One small honest slip: 80b7dabe's note "its paste 2 now installs an image without the sandbox" is not literally true. Paste 2 pins 7b8b560a, which still holds the sandbox, and refuses at 80b7dabe. A session wrote that note by hand, not the cycle. [inferred from the texts]

## Did anything ship that the owner had not seen?

No. [inferred from the log]

- M..80b7dabe holds no `(build-loop self-merge)` subject. Row 86's third trigger ("a release ships a self-merge its entry did not flag") did not fire, and cycle 0143's record agrees (`cycle-2026-11-12.md:115`: "the three `other` commits ... were the owner's asks in session").
- The two gate-code changes were asked for in that session: 30eb0229 ("owner asked for all three") and 7caea26d (Q-277 [3]).
- The installer changed after M, and an installer changed after M is the case row 86 added the installer check for (research line 168). Here it was the owner's own revert, a one-line removal from `PAYLOAD=`, and install.sh's review diff showed what it would install before the y.
- The brief's "no change" option says "the next cycle's image check already describes what shipped". That is half right. On exit 0 the image check writes only the met line (SKILL.md:271-273). The description came from cycle 0143's step 2 revisit triggers instead: the row 86 entry (record line 118) names 30eb0229, and the decision 035 entry (line 98) names 7caea26d's install.sh change and its `Live-verified: no` trailer. So the after-the-fact record exists, in the cycle record rather than the entry. [observed]

## Gotchas

- Failure-pattern grep: FP-178
- FP-178 (2026-11-10): "release-paste-pins-a-commit-the-cycles-own-land-moves-main-past-so-it-refuses-every-run-from-mains-tip-and-the-release-runs-without-it". This install is one more case of that pattern: Q-273's paste was the old pinned-commit shape, because the image that wrote the entry predated the fix (1f14e270). The fix shipped in this very release, so the next entry uses row 86's paste. One point FP-178 does not cover: row 86's paste also refuses after a hand commit to gate code, and its way forward is "run the dev cycle". On 2026-11-12 the cycle could not run, because the sandboxed image broke worktree creation (7caea26d's body).
- Grep run: `grep -inE 'release-paste|image-lag|release-entry|outside-the-entry|hand-commit|installed-from' docs/failure-patterns.md` (one hit, FP-178).
- No `fix(...)` commits on this branch, so no FP entry and no skip line are needed.

## Design choice (divergent design, seeded with docs/constraints.md and the brief)

**Diagnosis.** The problem to solve is "an install can carry gate code that no entry describes". The question is whether that costs anything the owner would pay to prevent. Hard constraints from the brief: no code, guide or skill change in this unit. A change would therefore be a proposal for a later unit. Constraints that bind (glosses from `docs/constraints.md`): S5 (establish the motive first; the status quo is a valid outcome), S10 (spend the owner's attention last: no new host chore, no step that waits on the owner), S1 (do not add a restriction whose bypass is already allowed), S8 (no growth of `install.sh`, a 500-plus-line file), S2 (no new mandatory agent dispatch), S3 (one source of truth per rule), H1 (gate logic never comes from a copy an agent session can write, for example a hook in the checkout).

**Motive test (S5).** The entry exists to review what the release ships (SKILL.md step 0.1, "the release is your review of what it ships (F58)"). Here the owner had asked for every unlisted commit in the same session and read install.sh's diff. The only loss is that the record was written after the install, not before it, and the cycle record covers that. So the motive for a change is weak in this case. It would be real only if an unreviewed commit could ride an install outside the entry.

Prior pruning grep: `grep -B 1 -A 20 "Pruned candidates" docs/decisions/*.md | rg -i "paste|release entry|image-lag|install\.sh print|hand commit"` found no matches for [paste, release entry, image-lag, install.sh print, hand commit]. Row 86's research candidates (its lines 97-107) are carried forward where they apply. Below, [carried from research-2026-11-10] marks one.

**Candidates.**

0. **Status quo.** The owner may install any commit. install.sh's diff review and y are the bless. The next cycle's image check either finds the gate in step with main or files an entry, and step 2's triggers (row 86, decision 035) record any gate code or installer change that shipped outside an entry.
1. **install.sh prints the gate-code diff since the last release entry's M** (the brief's example).
2. **The cycle rewrites the entry right after any hand commit to gate code**, run by a post-commit hook or by a rule for the session that commits.
3. **The paste's refusal names a sanctioned way forward**, such as "or run ./devcontainer-config/install.sh and read its diff", so going around it is a documented step and not an improvisation.
4. **A hand-commit session re-runs step 0.1's image check** and rewrites the entry before telling the owner to install.
5. **On close, the image check writes what shipped beyond M** (the log M..C) into the met line or the record.
6. **A stricter paste that refuses any commit after M outside `docs/`** [carried from research-2026-11-10, candidate 5: refuses the owner's own later commits, the friction that got Q-156's paste skipped].

**Prune.**

- [1]: install.sh already shows the whole payload diff against what is installed (`install.sh:33,547-560`), which is a superset of a diff from M. Printing a second diff from M means install.sh has to read the questions file's grammar (S3: a second reader of that grammar) and grow by lines (S8). Out.
- [2]: a post-commit hook in the checkout is agent-writable gate logic (H1). The session-rule version is [4]. Either way it could not have run on 2026-11-12: under the sandboxed image the cycle's worktrees failed (7caea26d), so no cycle could rewrite anything before the revert was installed. It also adds a dispatch per hand commit (S2). Out.
- [6]: carried; it is stricter than the paste the owner already went around (S1, S10). Out.
- Survivors: 0, 3, 4, 5.

**Stress-test.**

- *Boring alternative*: is 0 enough? The one check that matters here, that no unreviewed self-merge ships unlisted, is already row 86's third trigger, and step 2 runs it every cycle. 0 holds.
- *Invert the thesis*: argue for 3. A refusal that names install.sh makes going around the paste official and drops the paste's one real check, that the gate code matches what the entry describes. That weakens the paste for a case where the owner already knew what shipped. 3 adds a gate-code edit and a release to save the owner a moment's thought. 3 loses.
- *Revealed preferences*: earlier releases (Q-156's, and per row 86 "the last two releases", which may include it) and this one ran around a paste that refused. Each time, the owner was the one who had moved main. A rule for the hand-commit session [4] would not have helped, because the session that made 80b7dabe wrote "its paste 2 now installs" without checking the paste. A prose rule depends on that same session noticing (S4, prose over a tested script), and it adds always-loaded lines (S2) for a rare case. 4 loses.
- *What it costs the owner* (S10): 5 writes notes after the install for an owner who was there when it ran. That is attention spent on a read with nothing to decide, and the cycle record already holds the same facts. 5 loses.

```
┌─ DECISION: change the release path after row 86's trigger fired? ─────┐
│ 4 candidates survived step-3 pruning · scored on the step-4 axes      │
└───────────────────────────────────────────────────────────────────────┘

  legend   ● strong / low   ◐ partial / medium   ○ weak / high   ✗ fails hard constraint

   #    approach                 effort      risk     coverage    key downside
  ───  ──────────────────────  ──────────  ───────  ──────────  ───────────────────────────────
   0 ★ status quo               ● none      ● low    ● 1/1 hard  ◐ entry written after install
   3   refusal names install.sh ◐ skill+rel ◐ med    ● 1/1 hard  ○ blesses going around the paste
   4   session re-runs 0.1      ◐ prose     ◐ med    ● 1/1 hard  ○ needs the slip-prone session
   5   close writes M..C        ◐ skill+rel ● low    ● 1/1 hard  ○ attention on a done event
```

```
╭─ [0] status quo   ★ recommended ──────────────────────────────────────────╮
│ effort    none (no code, skill or record change)    risk   low            │
│ coverage  1/1 hard · S1 S2 S3 S5 S8 S10 met                               │
│ hypothesis  If chosen, no release over the next 30 days ships a           │
│             build-loop self-merge its entry did not list; counter-        │
│             evidence = row 86's third trigger firing in a cycle record.   │
│ stress-tests applied                                                      │
│   · boring alternative → row 86's third trigger already guards the        │
│     one case that matters                                                 │
│   · revealed preferences → owner-made commits keep moving main past       │
│     the paste, and a paste rule would not stop it                         │
│ key downside  an owner-directed install is described after the fact,      │
│               in the cycle record, not before it in the entry             │
╰───────────────────────────────────────────────────────────────────────────╯
```

`▶ recommend [0] status quo · confidence 85% · no runner-up within one cell`

Expand any other card by naming its `#`.

**Decision: Path A, [0] status quo.** No candidate passes the motive test. The one harm the entry guards against, unreviewed code shipping unlisted, is still caught by row 86's third trigger, which did not fire. The hard choice this time was forced by a sandbox that also blocked the cycle. That cause is gone with 7caea26d, and the paste in the installed image is now row 86's, not the FP-178 shape.

### Pruned candidates and why

Each entry is `[candidate-ID]: one-line reason for discard`. Future DDs in adjacent areas can grep this section to avoid regenerating already-pruned approaches.
[1]: duplicates install.sh's own payload diff and makes install.sh read the questions grammar (S3, S8). [2]: an agent-writable hook as gate logic (H1); a cycle could not run on 2026-11-12 anyway; adds a dispatch (S2). [3]: sanctions going around the paste's only gate-code check, for a case the owner already knew. [4]: prose that relies on the same session that wrote the wrong "paste 2 now installs" note (S4, S2). [5]: spends attention on a finished event the cycle record already holds (S10). [6]: [carried from research-2026-11-10: stricter than the paste the owner already went around (S1, S10)].

### Consequences

Easier: nothing changes, and the owner can still install from any commit in an emergency like 7caea26d's. Harder: an install outside the entry is described only after the fact, in the next cycle record's revisit-trigger lines. When row 86's first trigger fires next time, the cycle can answer it from the log by checking M..C for self-merges and owner asks, as cycle 0143 did, without a new brief. This doc is that answer's reference. Recording that on row 86 belongs to the cycle, which owns the log. This unit does not edit the log.

### Revisit triggers

Each entry is a concrete, observable condition that should prompt re-evaluating this decision. Future readers can grep this section when their context changes to see whether earlier decisions still apply.
If an install outside its entry carries, between the entry's M and the image's `commit=`, a `(build-loop self-merge)` subject or a gate-code or installer commit that no in-session owner ask or answered question covers. If the owner goes around row 86's paste itself (not the old pinned-commit paste) twice, which would mean its "run the dev cycle for a new paste" way forward costs too much and candidate 3 earns a look. If an install is traced to an agent session rather than the owner (decision 037, `docs/decisions/037-bare-host-copy-install.md`). If the owner says an install shipped something they did not know about.
