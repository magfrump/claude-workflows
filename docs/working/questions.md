# Running questions

Questions raised during autonomous work that did not justify stopping.

**To answer:** write `Q-0NN: <your answer>` anywhere — a reply, a file, a commit.
The ID is the whole handle; you never have to restate the question. Answers move
the entry to `questions-archive.md`, so this file only ever holds what is still open.

**Needs** is the route — who or what actually discharges the item, from
`docs/working/triage-2026-09-17-backlog.md` §3.1:

| Route | Meaning |
|---|---|
| `you: judgment` | Needs your taste or authority. The only real attention spend. |
| `you: terminal` | Needs your machine, not your mind. Collected into one paste below. |
| `agent` | Mechanical. Should not be here long. |
| `trigger` | Not a question yet — a condition being watched. Costs you nothing. |
| `deferred` | Scheduled behind an event that has not happened. |

Maintained by `scripts/questions.sh` (`check` · `index` · `archive` · `next-id` · `open`).
The index below is generated — edit entries, not the table.

## Index

<!-- index:start -->
| ID | Needs | Question | Opened |
|---|---|---|---|
| [Q-049](#q-049--deny-rule-absolute-path-form) | you: terminal | Do the live deny rules match at all? `link-claude-home.sh` writes them as `Edit(/home/node/.claude/settings... | 2026-09-21 |
<!-- index:end -->

## Open

### Q-049 · deny-rule-absolute-path-form
**Needs:** you: terminal · **Opened:** 2026-09-21 · **Status:** OPEN

Do the live deny rules match at all? `link-claude-home.sh` writes them as `Edit(/home/node/.claude/settings*.json)`, with one leading slash. If Claude Code reads `/path` as relative to the settings file and needs `//path` for an absolute path (which is my recollection of its docs, unverified because the sandbox has no egress), every global-dir deny rule matches nothing. `guard-trusted-writes.py` then defers to rules that aren't there, so file-tool edits to global settings, hooks and CLAUDE.md get no gate. This predates this branch. The 2026-09-21 iteration-2 review raised it as N3.

- **Read:** `hooks/wiring.json` deny block, `devcontainer-config/link-claude-home.sh:137` (the `{{CLAUDE_DIR}}` substitution), `~/.claude/settings.json` (live rules)
- **Run 1 (2026-09-23): INCONCLUSIVE.** Untrusted project settings dropped the `allow` rule.
- **Run 2 (2026-09-23): `control`, `single` and `double` all wrote the file.** The control worked, so `--settings` loaded and the allow applied. But neither `Write(/abs)` nor `Write(//abs)` stopped a Write. There are two readings, and this run can't tell them apart: (a) `Write(<path>)` is not a path-matched rule, and file paths are matched only by `Edit(<path>)`, which is also the form the live rules use; or (b) deny rules from `--settings` are not applied. Run 2 therefore tested the wrong form. It says nothing yet about the live `Edit(...)` rules.
- **Run 3 paste** (on the host; five tiny headless calls). `denyall` denies Write outright, which proves deny rules from `--settings` apply at all. `edit1`/`edit2` are the live form, with one and two leading slashes:

```bash
for form in control denyall edit1 edit2 edithome; do
  d=$(mktemp -d); td=$(mktemp -d); t=$td/target.txt
  case $form in
    control) deny='' ;;
    denyall) deny='"Write"' ;;
    edit1) deny="\"Edit($t)\"" ;;
    edit2) deny="\"Edit(/$t)\"" ;;
    edithome) td=$(mktemp -d "$HOME/.q049.XXXXXX"); t=$td/target.txt; deny="\"Edit(~/${td#$HOME/}/target.txt)\"" ;;
  esac
  printf '{"permissions":{"allow":["Write"],"deny":[%s]}}\n' "$deny" > "$d/s.json"
  out=$(cd "$d" && claude -p "Use the Write tool to create the file $t containing: hi" --settings "$d/s.json" --add-dir "$td" --output-format json 2>"$d/err")
  turns=$(printf '%s' "$out" | jq -r '.num_turns // 0' 2>/dev/null); turns=${turns:-0}
  if [ -e "$t" ]; then r="file written"; elif [ "$turns" -ge 2 ]; then r="not written (claude ran $turns turns)"; else r="INCONCLUSIVE, claude did not run: $(head -c 200 "$d/err")"; fi
  echo "$form: $r"
  case $form in edithome) rm -rf "$td" ;; esac
done
```

- **How to read it:** `control` must say "file written" and `denyall` "not written". Otherwise the run proves nothing, so paste it back. With those two good:
  - `edit1: not written` → the live single-slash rules work. N3 is closed.
  - `edit1: file written`, `edit2: not written` → only `//` is absolute, so the live rules match nothing today.
  - `edit1` and `edit2` both "file written" → no absolute form works in `--settings`. `edithome` (the `~/` form) is the fallback to try.
- **What I do with it:** single-slash works → close N3. Otherwise `link-claude-home.sh` emits the form that works, a test pins it, and you re-install and re-bless. **Whatever the result, I recommend the guard redesign the review proposed:** the hook returns `deny` itself for HARD paths instead of deferring to rules. Run 2 already shows how easily a rule can silently match nothing.
- **Interim:** unchanged. The devcontainer's `/opt` payload is read-only, which bounds the hooks and CLAUDE.md exposure there. `~/.claude/settings*.json` is not bounded that way.

