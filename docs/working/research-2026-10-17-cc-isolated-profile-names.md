# Research and plan: cc-isolated validates profile names and refuses an empty grant

Brief: `docs/working/briefs/2026-10-17-cc-isolated-profile-names.md` (at d2cd20c3).
Source of the defects: `docs/reviews/independent-review-2026-10-15-one-workspace.md`,
"Out-of-family observations".

## What the code does today

- `register_project` (`devcontainer-config/cc-isolated.sh`) splits `--profile` with an
  unquoted `for p in $(echo "$profiles" | tr ',' ' ')`. That is word splitting on
  whitespace plus pathname expansion, and the only check is that
  `$(config_dir)/egress/$p.txt` is readable. So `../egress/python` and
  `./python` pass and are written verbatim into `projects/<id>.profile`. A `*` is expanded
  against `$PWD` first. An empty value (`--register DIR` with no `--profile`, or
  `--profile ''`) skips the loop, writes an empty file and re-blesses.
- `init-firewall.sh`'s `compose_domains` re-checks each name inside the container against
  `/usr/local/share/cc-egress/NAME.txt` and fails closed, so the bad value cannot widen
  egress. It can only produce a registration that breaks the next launch, after a re-bless.
  That is a bug, not a bypass of the boundary.
- `project_profile` strips all whitespace from the file, and `""` means unregistered:
  the launch then prints the "unregistered" NOTE with suggestions.
- `base.txt` is a file in `egress/`, so `base` is a valid name today. `compose_domains`
  always prepends `base` and runs `sort -u`, so `--profile base` already works as
  "base egress only": it is the existing way to narrow a project back to base.
- The unregistered NOTE prints `--register '$ws'`. A path holding `'` gives a broken
  command. `rebuild_hint` already uses `%q`.

## Empty grant: is it the documented way to narrow to base?

No. Neither guide, the launcher header, the decisions log nor the decision records
documents `--register DIR` with no `--profile`. The only narrowing text is "`--profile`
sets the grant" (re-register with a shorter list). Also, an empty grant is
indistinguishable from "unregistered" (`project_profile` returns `""` for both), so the
launch would go on suggesting profiles for a project the user deliberately narrowed.
`--profile base` already narrows to base and is recorded as a registration. So the empty
grant is refused, and the refusal names `--profile base` as the way to narrow.

## Divergent design (seeded with H1-H4, S1-S11 and the brief)

Choice 1, the empty grant:
1. Refuse it and point at `--profile base`. This fails closed (H2), adds no new mechanism
   (S3), and the narrowing path stays available.
2. Accept it as the documented way to narrow. No documented reason exists, and it is
   ambiguous with "unregistered" (the NOTE keeps suggesting a grant).
3. Refuse it with no narrowing hint. Same lines as 1, but the user has to work out how to
   narrow.
Option 1 dominates (Path A).

Choice 2, where the name check sits:
A. Inside `register_project`, its only caller. It needs the fewest lines in a file over
   500 lines (S8), the existing function tests reach it, and it covers `main` too.
B. A new `egress_profile_names` helper. More lines, and only one caller today (S6).
C. In `main`'s argument parser. That misses direct calls, and the function tests would
   need the whole launch path.
A dominates (Path A). The list of available names is built once, from the same glob the
error message already printed, so the check and the error cannot drift apart (S3).

Choice 3, the matching rule. Exact string equality against the base names of regular,
non-symlink `egress/*.txt` files. A character-class allowlist (`[a-z0-9-]`) would restate
the egress file names as a second grammar (S3), so it is not used.
Splitting uses parameter expansion (`${rest%%,*}`), never word splitting or `read`. A
here-string `read` stops at the first newline, so `$'python\n../x'` would validate only
`python`.

## Pre-mortem: bypass families (before any code)

Assume the change shipped and a bad name still reached a `.profile` file. These are the
ways it could happen:

| Family | Example | Covered? | How |
|---|---|---|---|
| Path parts | `../egress/python`, `./python`, `egress/python`, `python.txt` | covered | not equal to any base name |
| Empty items between commas | `,python`, `python,`, `python,,lean` | covered | the empty item equals no name; error prints `''` |
| Empty whole list | `--register DIR`, `--profile ''` | covered | refused, names `--profile base` |
| Whitespace | `python, lean`, `' python'`, `$'python\nlean'` | covered | expansion-based split keeps the blank; no name holds one |
| Leading `-` or `#` | `python,-x`, `python,#x` (the first item is already refused by `main`) | covered | equals no name (the review found no egress name starts so) |
| Case | `Python`, `PYTHON` | covered | string equality, not a case-folding filesystem lookup |
| Glob characters | `*`, `pyth*`, `?ython`, `[p]ython` | covered | no pathname expansion, and literal equality |
| Symlink in `egress/` | `egress/py.txt -> python.txt` | covered for the name | only `-f` and not `-L` files are names. Out of scope: a planted *regular* file in `egress/` is blessed by any re-bless; that is the manifest's trust model, not this check |
| Control characters in the error | name holding an escape | covered | the refused value is printed with `%q` |

Not a family here: the firewall's own re-check stays as it is (out of scope), so even a
missed case fails closed at container start.

## Plan

1. `register_project`: collect the names; refuse `""` with a message naming
   `--profile base`; split on commas with parameter expansion; refuse any item that is
   not exactly a name, printing it with `%q` and listing the names. All of this happens
   before anything is written or re-blessed.
2. The unregistered NOTE: `--register $(printf %q "$ws")`.
3. Bats in `test/cc-isolated-functions.bats`: one case per family above, valid single
   and comma lists (including `base`), the empty grant through `main` (non-zero, message,
   nothing written, no re-bless), and the NOTE quoting through a stubbed launch.
4. Guide: the `--profile` paragraph in `guides/cc-isolated-usage.md` states the accepted
   names, the empty-grant refusal and `--profile base`.
5. Commit with `Live-verified: no — REASON`. Host check for the ready marker: one
   `--register` with a bad and a good profile.

Line budget: about +12 net in `cc-isolated.sh`. The whole unit is well under 400.
