#!/bin/bash
# Shared path-classification helpers for skill / workflow / command files.
#
# These functions encode the "one rule set" for mapping a file path to a
# skill or workflow name. They are kept lightweight (no top-level work) so
# the hook scripts that source this file pay near-zero startup cost.
#
# Layouts recognised:
#   skills/<name>.md           → skill:<name>           (flat / legacy)
#   skills/<name>/SKILL.md     → skill:<name>           (dir / registry layout)
#   workflows/<name>.md        → workflow:<name>
#   commands/<name>.md         → command:<name>
#
# Paths under a /skills/<name>/ subtree other than SKILL.md (references,
# fixtures, README.md, etc.) are NOT classified — they are not skill
# definitions and should not be logged or evaluated as such.

# Extract skill name from a file path, or empty if not a skill definition.
# Handles both layouts above. Anything deeper than one directory under
# /skills/ that is not SKILL.md returns empty.
extract_skill_name() {
    local filepath="$1"
    local after
    if [[ "$filepath" == */skills/* ]]; then
        after="${filepath##*/skills/}"
    elif [[ "$filepath" == skills/* ]]; then
        after="${filepath#skills/}"
    else
        return 0
    fi

    local stripped="${after//[^\/]/}"
    local depth=${#stripped}

    if [[ $depth -eq 0 && "$after" == *.md ]]; then
        printf '%s' "${after%.md}"
    elif [[ $depth -eq 1 ]]; then
        local basename="${after##*/}"
        if [[ "$basename" == "SKILL.md" ]]; then
            printf '%s' "${after%%/*}"
        fi
    fi
}

# Extract workflow name from a file path, or empty if not a workflow file.
# Only direct files under workflows/ count; nested files do not.
extract_workflow_name() {
    local filepath="$1"
    local after
    if [[ "$filepath" == */workflows/* ]]; then
        after="${filepath##*/workflows/}"
    elif [[ "$filepath" == workflows/* ]]; then
        after="${filepath#workflows/}"
    else
        return 0
    fi

    local stripped="${after//[^\/]/}"
    if [[ ${#stripped} -eq 0 && "$after" == *.md ]]; then
        printf '%s' "${after%.md}"
    fi
}

# Extract command name from a file path (user-defined slash commands).
extract_command_name() {
    local filepath="$1"
    local after
    if [[ "$filepath" == */commands/* ]]; then
        after="${filepath##*/commands/}"
    elif [[ "$filepath" == commands/* ]]; then
        after="${filepath#commands/}"
    else
        return 0
    fi

    local stripped="${after//[^\/]/}"
    if [[ ${#stripped} -eq 0 && "$after" == *.md ]]; then
        printf '%s' "${after%.md}"
    fi
}

# Classify a file path. Emits "skill:NAME", "workflow:NAME", or
# "command:NAME" (newline-terminated) when the path is recognised, and
# nothing otherwise. Skills take precedence over workflows when the path
# contains both segments (e.g. claude-workflows/skills/x.md).
classify_skill_path() {
    local filepath="$1"
    local name
    if [[ "$filepath" == */skills/* || "$filepath" == skills/* ]]; then
        name=$(extract_skill_name "$filepath")
        [ -n "$name" ] && { printf 'skill:%s\n' "$name"; return; }
    fi
    if [[ "$filepath" == */workflows/* || "$filepath" == workflows/* ]]; then
        name=$(extract_workflow_name "$filepath")
        [ -n "$name" ] && { printf 'workflow:%s\n' "$name"; return; }
    fi
    if [[ "$filepath" == */commands/* || "$filepath" == commands/* ]]; then
        name=$(extract_command_name "$filepath")
        [ -n "$name" ] && { printf 'command:%s\n' "$name"; return; }
    fi
}
