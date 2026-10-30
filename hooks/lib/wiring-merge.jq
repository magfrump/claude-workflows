# wiring-merge.jq — merge hooks/wiring.json into a Claude Code settings.json.
#
# The one copy of this program. Two callers run it:
#   - devcontainer-config/link-claude-home.sh, at every container start
#     (decision 023), from the image's root-owned payload;
#   - devcontainer-config/install.sh's host target (Q-106 [2]), from the
#     reviewed, hash-checked copy it is about to install, before the y.
#
# Usage: jq --arg dir <config dir> --slurpfile w <wiring.json> -f wiring-merge.jq <settings.json>
# <config dir> is the directory whose hooks/ the wiring runs (the {{CLAUDE_DIR}}
# token resolves to it). jq has no builtin that runs a command or writes a file;
# the caller writes the output. Callers run jq with HOME and the environment
# emptied: jq 1.6 loads $HOME/.jq as a library, which would let unreviewed
# code redefine builtins such as walk (Q-106 review A3).
#
# Semantics, per event key (hooks) and per mode (permissions):
# (existing - ours) + ours, so a rerun is exactly idempotent and everything we
# did not author stays in place. `_comment` never lands in settings.
# - A hook group is "ours" by PROVENANCE: every command in it runs something
#   under $dir/hooks/. Deep equality left a stale group beside its new version
#   the first time a group gained a hook, so shared hooks fired twice (FP-161).
# - A permission rule is removed only when it equals one of ours (re-added) or
#   is the legacy single-slash form of one of our Read/Edit/Write rules under
#   $dir, which matched nothing (Q-049), or the Write(path) twin of one of our
#   Edit(path) rules, which Claude Code never matches; any other rule the
#   wiring no longer carries is never removed. The deny rules are what blocks
#   guard-trusted-writes.py's HARD tier for the file tools (decision 023
#   amendment B). A wiring mode whose value is not an array (e.g.
#   "defaultMode"), or a settings value that is not an array for a mode the
#   wiring also carries, makes jq fail, and both callers then leave the
#   settings file alone. A user's own "defaultMode" is kept.
($w[0]
 | with_entries(select(.key | startswith("_") | not))
 | walk(if type == "string"
        then gsub("\\{\\{CLAUDE_DIR\\}\\}"; $dir)
        else . end)) as $wiring
| .hooks //= {}
| reduce (($wiring.hooks // {}) | keys_unsorted[]) as $ev (
    .;
    .hooks[$ev] = (((.hooks[$ev] // [])
                    | map(select(((.hooks // []) | length) > 0
                                 and ((.hooks // [])
                                      | all((.command // "")
                                            | contains($dir + "/hooks/")))
                                 | not)))
                   + $wiring.hooks[$ev])
  )
| .permissions //= {}
| reduce (($wiring.permissions // {}) | keys_unsorted[]) as $mode (
    .;
    # Also drop the legacy single-slash form (relative to the settings file,
    # so it matched nothing; wiring.json emits //abs) of each file-tool rule
    # under $dir only: a branch's Read(//x) or Bash(//...) must not delete a
    # user's own Read(/x) or Bash(/...), which may be real rules.
    # And drop the Write(path) twin of each of our Edit(path) rules, in either
    # slash form: Claude Code matches paths only through Edit(), so those never
    # matched and it warns about each at startup. wiring.json no longer emits
    # them.
    .permissions[$mode] =
      (((.permissions[$mode] // []) - $wiring.permissions[$mode]
        - ($wiring.permissions[$mode]
           | map(select(test("^(Read|Edit|Write)\\(//") and contains("(/" + $dir + "/"))
                 | sub("\\(//"; "(/")))
        - ($wiring.permissions[$mode]
           | map(select(startswith("Edit("))
                 | sub("^Edit\\("; "Write(")
                 | ., sub("\\(//"; "(/"))))
       + $wiring.permissions[$mode])
  )
