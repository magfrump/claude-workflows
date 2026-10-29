# Changing a convention

Every repo that runs this harness keeps files in shapes the harness defines: the questions
files' entry grammar and routes, the roadmap's sections, a build brief's lines and a cycle
record's layout. A change to one of those shapes reaches every such repo at the next
install, so it ships a **migration**: a line saying how to tell that a repo's file still has
the old shape, and the command that brings it up to date. The dev cycle looks for pending
migrations before it continues any other work (`skills/dev-cycle/SKILL.md`, step 1b).

## When you need one

`test/scripts/convention-migrations.bats` fingerprints each covered convention's source:

| Convention | Source |
|---|---|
| `questions` | `scripts/questions.sh`: its "Entry grammar" header block, and the files `init` writes |
| `roadmap` | `skills/dev-cycle/SKILL.md` step 6: the roadmap template |
| `brief` | the same file, step 8: the paragraph on a brief's lines |
| `record` | the same file, step 9: the record template |

When a change alters one of those sources, the test fails, printing the new fingerprint and
the line to add. So a convention change cannot pass the health check, and so cannot merge,
without a registry line. Other places that read these files (the readers in
`scripts/build-loop.sh` and `scripts/lib/dev-cycle-read.sh`) are not fingerprinted: when you
change a reader's grammar, change its source above too, or add the line by hand.

## How to declare one

Add one `mig` line at the end of the registry in `scripts/lib/migrations.sh`, above its
run-directly block. Its header is the grammar; in short:

```
mig ID CONVENTION FP PATH ERE 'REMEDY'
```

- **Existing files need changing**: PATH is the repo file that can hold the old shape, ERE
  a `grep -E` pattern that matches a line only the old shape has, and REMEDY the command
  the repo's owner runs from its root (then commits). Example, for a route that left the
  questions file: `mig questions-x questions FP docs/working/questions.md
  '^\*\*Needs:\*\* x( |$)' '~/.claude/scripts/questions.sh migrate'`.
- **No existing file needs changing** (a new optional section, a wording change): `mig ID
  CONVENTION FP - - 'none: WHY'`.

`bash scripts/lib/migrations.sh fingerprint` prints each convention's current FP, and
`bash scripts/lib/migrations.sh check` runs the test's check. Never edit or remove an old
line: a repo that has not migrated yet still needs it. The bats check holds the registry
append-only against the default branch's copy, and allows only `mig` lines and comments
in it (a branch's change; a commit made directly on the default branch is not compared). The remedy must exist in the same
change (or already be on main), since the dev cycle hands it to the owner as soon as the
change is installed.

## What the dev cycle does with it

The digest's section 7b prints `pending ID (CONVENTION): PATH line N; remedy: REMEDY` for
each migration whose ERE still matches. The cycle cannot run the remedy itself: migrations
rewrite questions entries or roadmap headings, which its own commits may not change without
the owner. So it files one `you: terminal` entry per pending migration (slug `migrate-ID`),
lists it first in its final message, and carries on with the rest of the iteration.

Two branches that change the same convention in parallel each add a line; whichever merges
second fails the check after merging main in, and adds a line with the combined fingerprint.
