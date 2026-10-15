#!/usr/bin/env bash
# Hook to allow piped commands where ALL components are in the allowed Bash permissions.
# Claude Code's prefix matching doesn't handle pipes - this hook fixes that.
# Dynamically reads allow rules from (SETTINGS SOURCES below):
#   1. ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json (global)
#   2. <git root>/.claude/settings.json (project shared)
#   3. <git root>/.claude/settings.local.json (project local)
#
# Dependencies: shfmt, jq
#
# Usage: echo '{"tool_input":{"command":"ls | grep foo"}}' | auto-approve-allowed-commands.sh [OPTIONS]
#
# Options:
#   --debug                 Enable debug output to stderr
#   --permissions JSON      Use custom permissions instead of reading from settings files
#                           JSON format: '["Bash(ls:*)", "Bash(grep:*)"]'
#
# Examples:
#   # Normal usage (reads permissions from settings files)
#   echo '{"tool_input":{"command":"ls | grep foo"}}' | auto-approve-allowed-commands.sh
#
#   # Testing with custom permissions
#   echo '{"tool_input":{"command":"ls | grep foo"}}' | auto-approve-allowed-commands.sh --permissions '["Bash(ls:*)", "Bash(grep:*)"]'
#
# CLOSED GAPS (2026-09-28, decision log row 64; row 53 had accepted them):
# approval is prefix-matching over the commands the extraction filter finds,
# and the filter does not descend into every construct bash can execute. These
# used to get "allow" when only the outer command was allow-listed:
#   echo $((1 + $(cmd)))     arithmetic expansion was not searched for $(...)
#   cat <<EOF / $(cmd) / EOF heredoc bodies were not searched
#   PATH=/x ls, LD_PRELOAD=  assignment prefixes were dropped before matching
#   ls > ~/.bashrc           redirect targets were not checked
# Row 53 found that closing them one at a time does not converge, and so did
# two review rounds on a class-based fix (let 'a[$(cmd)]=1', export PATH=,
# escaped backticks in bash -c, `tr < secret`, `read 'a[$(cmd)]'`). The hook
# now approves only an allowlist of AST SHAPES (refuses_construct): literal
# words, plain $NAME, pipes and && || ;, no VAR= assignment, no background &,
# a literal command name that is neither an interpreter or wrapper (bash, sh,
# env, xargs, sudo, ...) nor a bash builtin other than cd, pwd, echo, true,
# false and type, and redirects that neither write nor read a path. Any other
# construct prompts, including ones nobody has listed. Parse failures and
# commands that extract to nothing fail closed too.
# Cost: compound one-liners (`echo "$(git rev-parse HEAD)"`, `for ...`, `[[ ]]`,
# `test`, `export`, `< file`) prompt even when allow-listed, and so does any
# command run through `bash` (a `Bash(bash scripts/x.sh:*)` rule no longer
# approves a pipeline; Claude Code's own matching still sees the rule).
# Each approved call spawns one more jq process than before: about +25 ms
# (mean of 20 approved `git status` calls, 110 -> 136 ms, 2026-09-28).
#
# ROLE: AN ALLOW-ONLY CONVENIENCE LAYER (Q-092). The hook emits one decision,
# "allow", or nothing (exit 0 with no output, so Claude Code's own rules and
# prompt decide). It never emits "ask", "deny" or "defer". That is what lets it
# leave deny rules to Claude Code: a hook "ask" overrides permissions.deny
# (Claude Code issue #39344), but a hook "allow" does not (host test Q-082,
# 2026-09-28; decision log row 53). Q-082 did not record the Claude Code
# version (Q-091 saw 2.1.284 on the host that day) and the image installs
# @latest: re-run Q-082's test when a Claude Code release changes how a
# PreToolUse permissionDecision combines with permission rules, or before
# relying on this after a major version. cc-isolated has no sandbox (Q-081, Q-125),
# so there the shape allowlist above still decides which allow-listed commands
# run without a prompt.
#
# DENY RULES ARE CLAUDE CODE'S (Q-092). The hook used to read Bash deny rules
# itself and never approve a match, raw or de-quoted. Q-082 made that redundant
# for "allow", so it is gone and each deny rule has one interpreter. Left to
# Claude Code's matcher, not verified on a host: whether a rule catches a
# quote or backslash spelling (`.cred""entials.json`, `.c\redentials.json`,
# `git "push"`, `cat "secret"` against `Bash(cat secret)`) or a denied
# subcommand inside a list (`ls && rm -rf x` against `Bash(rm -rf:*)`). The
# hook used to send both to the prompt. A spelling that never contains the
# denied string (`~/.claude/.c*`, a variable set by an earlier command) got
# past both matchers before and still does (Q-070 [1]; a sandbox is the fix).
#
# FAILS CLOSED on its inputs: if any settings file below exists but cannot be
# read, does not hold exactly one JSON object, or has a permissions that is not
# an object, or a permissions.allow, .deny or .ask (present at all) that is not
# an array of NUL-free strings, no command is approved on that call. deny and
# ask are shape-checked, never read: Claude Code can ignore a whole settings
# file for an invalid value, and a file it drops should not feed allow rules
# here. RESIDUAL: a value the hook does not check (another key, a BOM) can
# still make Claude Code drop the file, and its deny rules with it, while its
# allow rules approve here; the deny reader used to cover that case.
#
# SETTINGS SOURCES. ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json, resolved
# like devcontainer-config/link-claude-home.sh's DEST (an empty value falls
# back; a relative value approves nothing), then <git root>/.claude/settings.json
# and settings.local.json (the cwd's .claude/ outside a repo). One jq call reads
# all of them (SETTINGS_RULES_JQ). --permissions replaces all three. Managed
# settings and --settings files are not read, so their allow rules approve
# nothing here.
#
# RULE SYNTAX. parse_bash_rule reads `Bash(BODY)`, with a trailing legacy `:*`
# stripped from BODY, or a bare `Bash`; anything else (another tool, no closing
# paren) is not a Bash rule. An allow rule is a literal command prefix:
#   Bash(ls)     prefix: `ls`, `ls -la` (not `ls/x`: a bare name never covers a
#                path under it; `Bash(a/b)` and `Bash(python3 d)` do cover
#                `a/b/x` and `python3 d/x`)
#   Bash(rm:*)   word prefix: `rm x`, not `rmdir`
#   Bash(ls *)   literal prefix, not a glob: `ls *` and `ls * -la` (bash then
#                expands that `*`), never `ls -la` (use `Bash(ls:*)`)
#   Bash         ignored

set -euo pipefail

# Debug mode
DEBUG=false
NUL_DELIM=false
# Set by main only: the hook refuses constructs (refuses_construct) that the
# parse_commands extractor must still be able to list.
REFUSE_CONSTRUCTS=false
# Custom permissions for testing (JSON array like: '["Bash(ls:*)", "Bash(cat:*)"]')
CUSTOM_PERMISSIONS=""

debug() {
  if $DEBUG; then
    echo "[DEBUG] $*" >&2
  fi
}

# --- Rules: one settings-file list, one jq pass, one Bash(...) parser ---

# Allow prefixes, filled by load_rules. Left empty when a settings file could
# not be read, so the hook then approves nothing (fail closed).
ALLOW_PREFIXES=()

# The settings files the allow rules come from, in order (header: SETTINGS
# SOURCES). The global path is resolved exactly as
# devcontainer-config/link-claude-home.sh resolves DEST, so the file the linker
# merges into is the one read here.
settings_files() {
  local root
  root=$(git rev-parse --show-toplevel 2>/dev/null) || root=""
  printf '%s\0' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json" \
    "${root:-.}/.claude/settings.json" "${root:-.}/.claude/settings.local.json"
}

# One jq program over every existing settings file. The file names are passed
# twice: as input files, and after --args as $ARGS.positional, so the program
# can check that each file yielded exactly one document (an empty file yields
# none, `{}{}` yields two). Any parse error, wrong shape or missing document is
# a jq error, and the caller then approves nothing. Output records are
# NUL-terminated allow rules, so a rule string containing a newline stays one
# record. permissions.allow, .deny and .ask, when present (even as null or
# false), must each be an array of strings with no NUL; only allow is emitted.
# Deny rules are Claude Code's (header: DENY RULES ARE CLAUDE CODE'S).
read -r -d '' SETTINGS_RULES_JQ << 'JQEOF' || true
[inputs | [input_filename, .]] as $docs
| if ($docs | map(.[0])) != $ARGS.positional
  then error("each settings file must hold exactly one JSON document") else . end
| $docs[] | .[1]
| if type != "object" then error("settings file is not a JSON object") else . end
| if has("permissions") then .permissions else empty end
| if type != "object" then error("permissions is not an object")
  else
    (["allow", "deny", "ask"][] as $k | select(has($k)) | .[$k]
     | if type == "array" and all(.[]; type == "string" and (explode | any(. == 0) | not))
       then empty else error("permissions.\($k) is not an array of NUL-free strings") end),
    (.allow // [])[]
  end
| . + "\u0000"
JQEOF

# Emit the allow rules of every settings file that exists. Exit non-zero on
# any read, parse or shape failure (the caller then approves nothing).
read_settings_rules() {
  local -a candidates files=()
  local f
  # A relative CLAUDE_CONFIG_DIR resolves against this hook's cwd, not the
  # linker's, so it could name some other directory's settings.json and add
  # its allow rules: fail closed.
  if [[ -n "${CLAUDE_CONFIG_DIR:-}" && "$CLAUDE_CONFIG_DIR" != /* ]]; then
    debug "CLAUDE_CONFIG_DIR is relative: approving nothing"
    return 1
  fi
  mapfile -d '' candidates < <(settings_files)
  for f in "${candidates[@]}"; do
    # A newline in a settings path would split it in `--args` bookkeeping
    # and in debug output; treat it as unreadable rather than missing.
    if [[ "$f" == *$'\n'* ]]; then
      debug "A settings path contains a newline: approving nothing"
      return 1
    fi
    if [[ -e "$f" ]]; then
      files+=("$f")
    else
      debug "Settings file not found: $f"
    fi
  done
  [[ ${#files[@]} -eq 0 ]] && return 0
  debug "Reading rules from: ${files[*]}"
  jq -nj "$SETTINGS_RULES_JQ" "${files[@]}" --args "${files[@]}" 2>/dev/null
}

# The parser for `Bash(...)` rule strings. Sets RULE_BARE (the rule is a bare
# `Bash`) and RULE_BODY (the text inside the parens, with a trailing legacy
# `:*` removed). Returns 1 for anything that is not a Bash rule.
parse_bash_rule() {
  local rule="$1"
  RULE_BARE=false RULE_BODY=""
  if [[ "$rule" == "Bash" ]]; then
    RULE_BARE=true
    return 0
  fi
  [[ "$rule" == "Bash("*")" ]] || return 1
  RULE_BODY=${rule#Bash\(}
  RULE_BODY=${RULE_BODY%\)}
  RULE_BODY=${RULE_BODY%:\*}
  return 0
}

# Allow rule -> literal command prefix (is_command_allowed). A bare `Bash` is
# ignored, as it always was on the allow side.
add_allow_rule() {
  parse_bash_rule "$1" || return 0
  $RULE_BARE && return 0
  ALLOW_PREFIXES+=("$RULE_BODY")
}

# Fill ALLOW_PREFIXES. --permissions replaces the settings files (testing), and
# then they are not read. The reader's status comes from `wait $!`, as for the
# command parser in main (mapfile's own status is always 0); bash older than
# 4.4 makes that `wait` fail, which also fails closed. On failure no rule is
# kept, not even the records jq printed before its error.
load_rules() {
  local -a records=()
  local rec
  if [[ -n "$CUSTOM_PERMISSIONS" ]]; then
    debug "Using custom permissions: $CUSTOM_PERMISSIONS"
    # Unreadable --permissions fails safe: no allow rules.
    mapfile -d '' records < <(printf '%s' "$CUSTOM_PERMISSIONS" \
      | jq -j '.[]? | select(type == "string" and (explode | any(. == 0) | not)) | . + "\u0000"' 2>/dev/null)
  else
    mapfile -d '' records < <(read_settings_rules)
    if ! wait $!; then
      debug "A settings file could not be read or parsed: approving nothing"
      return 0
    fi
  fi
  for rec in "${records[@]}"; do add_allow_rule "$rec"; done
}

# Check if a command matches any allowed prefix
# full_command: the extracted command with all args (e.g., "git log --oneline")
# allowed_prefixes: array of allowed prefixes from settings (e.g., "git log", "grep")
is_command_allowed() {
  local full_command="$1"
  local -n prefixes_ref=$2  # nameref to array

  for allowed in "${prefixes_ref[@]}"; do
    # Check if command starts with the allowed prefix
    # "git log --oneline" matches "git log" and "git"
    # "grep -E pattern" matches "grep"
    # "python3 .claude/skills/foo/bar.py" matches "python3 .claude/skills:*"
    # The "$allowed/" form is for path-prefix rules ("python3 .claude/skills",
    # "scripts/tools"). It does not apply to a bare name like "ls": "ls/x" is
    # a different program, which bash runs from a directory named ls
    # (decision log row 64). A rule that has an argument or is itself a path
    # keeps it.
    if [[ "$full_command" == "$allowed" ]] || [[ "$full_command" == "$allowed "* ]] \
       || { [[ "$allowed" == *[\ /]* ]] && [[ "$full_command" == "$allowed/"* ]]; }; then
      debug "ALLOWED: '$full_command' (matches '$allowed')"
      return 0
    fi
  done

  debug "BLOCKED: '$full_command' (no matching prefix)"
  return 1
}

main() {
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --debug)
        DEBUG=true
        shift
        ;;
      --permissions)
        CUSTOM_PERMISSIONS="$2"
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done

  # Check for required dependencies
  if ! command -v jq &>/dev/null; then
    debug "jq not found, falling through to normal permission check"
    exit 0
  fi

  # Read the command from stdin (hook input is JSON)
  input=$(cat)
  debug "Input JSON: $input"
  command=$(echo "$input" | jq -r '.tool_input.command // empty')
  debug "Extracted command:"
  debug "$command"

  # Exit early if no command
  if [[ -z "$command" ]]; then
    debug "No command found, exiting"
    exit 0
  fi

  load_rules
  debug "Loaded ${#ALLOW_PREFIXES[@]} allowed prefixes"

  # If no prefixes (no Bash permissions, or a settings file could not be
  # read), exit without allowing
  if [[ ${#ALLOW_PREFIXES[@]} -eq 0 ]]; then
    debug "No Bash permissions found, exiting"
    exit 0
  fi

  # Extract commands using built-in parser (NUL-delimited for multi-line command support)
  NUL_DELIM=true
  REFUSE_CONSTRUCTS=true
  # FAIL CLOSED on a parse failure, and on any AST shape refuses_construct does
  # not allow: extraction fails for both, so the command falls through to the
  # normal prompt.
  # mapfile's own status is always 0, so the parser's status has to be read from the process substitution via `wait $!`
  # (bash >= 4.4; older bash makes `wait` fail, which also falls through).
  # Without this, an unparseable command extracted to an empty list and hit the
  # "no commands found, allowing" branch below — and bash still runs every line
  # before the syntax error. Capturing with $(...) instead would strip the NULs.
  mapfile -d '' extracted_commands < <(extract_commands_from_string "$command")
  if ! wait $!; then
    debug "Command parsing failed"
    debug "Falling through to normal permission check"
    exit 0
  fi
  debug "Extracted ${#extracted_commands[@]} commands:"
  for cmd in "${extracted_commands[@]}"; do
    debug "  - $cmd"
  done

  # Check if no commands were found (empty input or only comments)
  # Not approved: `let 'a[$(cmd)]=1'` extracted to nothing and used to be
  # approved here, while bash ran the substitution (decision log row 64).
  if [[ ${#extracted_commands[@]} -eq 0 ]] || [[ -z "${extracted_commands[0]}" ]]; then
    debug "No commands found in input; falling through to normal permission check"
    exit 0
  fi

  # Check each command against allowed prefixes
  all_allowed=true
  for full_command in "${extracted_commands[@]}"; do
    [[ -z "$full_command" ]] && continue

    if ! is_command_allowed "$full_command" ALLOW_PREFIXES; then
      all_allowed=false
      break
    fi
  done

  if $all_allowed; then
    debug "Decision: ALLOW (all commands passed)"
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
  else
    debug "Decision: BLOCK (falling through to normal permission check)"
  fi

  exit 0
}
# shell-commands - Extract individual commands from a shell command string
#
# DESCRIPTION
#   Parses a shell command string and outputs each individual command on a
#   separate line. Uses shfmt for proper shell parsing, handling all shell
#   syntax correctly.
#
# USAGE
#   shell-commands [OPTIONS] [COMMAND]
#   echo "COMMAND" | shell-commands [OPTIONS]
#
# OPTIONS
#   -h, --help     Show this help message
#   -d, --debug    Enable debug output to stderr
#   -0, --null     Use NUL character as delimiter instead of newline
#                  (for programmatic use with: mapfile -d '' array < <(...))
#
# SUPPORTED SYNTAX
#   - Pipes:              cmd1 | cmd2 | cmd3
#   - And/Or:             cmd1 && cmd2 || cmd3
#   - Semicolons:         cmd1; cmd2; cmd3
#   - Newlines:           cmd1
#                         cmd2
#   - Line continuations: cmd1 \
#                           --flag | cmd2
#   - Pipe continuations: cmd1 |
#                           cmd2
#   - Comments:           cmd1  # inline comment
#                         # standalone comment
#   - Quoted strings:     grep -E "pattern|with|pipes" file
#   - Single quotes:      grep -E 'pattern' file
#   - Subshells:          (cmd1; cmd2) | cmd3
#   - Command substitution: echo $(cmd1 | cmd2)
#   - Variable expansion: echo $HOME
#   - bash -c / sh -c:    bash -c 'cmd1 | cmd2' (recursively expanded)
#
# QUOTE PRESERVATION
#   Quoted strings are preserved in output exactly as they appear in input.
#   Double quotes: grep -E "(int|long)" -> grep -E "(int|long)"
#   Single quotes: grep 'pattern' -> grep 'pattern'
#
# MALFORMED INPUT
#   If a newline breaks a command in the wrong place (e.g., between a flag
#   and its argument), shfmt will parse it as separate statements. This is
#   correct behavior - the input is invalid shell syntax.
#
#   Example of malformed input:
#     grep -E
#        "pattern"    <- This becomes a separate "command"
#
#   Correct alternatives:
#     grep -E "pattern"              <- single line
#     grep -E \
#        "pattern"                   <- backslash continuation
#     grep -E |
#        other_cmd                   <- pipe at end continues
#
# OUTPUT
#   Each command is printed on a separate line with all its arguments.
#   Only the command and arguments are printed, not the operators.
#
# EXAMPLES
#   $ shell-commands 'ls -la | grep foo | head -5'
#   ls -la
#   grep foo
#   head -5
#
#   $ shell-commands 'git status && git add . && git commit -m "msg"'
#   git status
#   git add .
#   git commit -m "msg"
#
#   $ echo 'grep -E "(int|long)" file.cs | head' | shell-commands
#   grep -E "(int|long)" file.cs
#   head
#
# DEPENDENCIES
#   - shfmt (brew install shfmt)
#   - jq (brew install jq)
#
# EXIT CODES
#   0 - Success
#   1 - Parse error or invalid input
#   2 - Missing dependencies
#

show_help() {
  sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
}

# Check dependencies
check_deps() {
  local missing=()
  command -v shfmt &>/dev/null || missing+=(shfmt)
  command -v jq &>/dev/null || missing+=(jq)

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Error: Missing dependencies: ${missing[*]}" >&2
    echo "Install with: brew install ${missing[*]}" >&2
    exit 2
  fi
}

# jq filter to extract commands from shfmt AST
# This walks the entire AST and extracts all CallExpr nodes
# Preserves quoting style from the original command
read -r -d '' JQ_FILTER << 'JQEOF' || true
# Recursively get string value from any word part, preserving quotes
def get_part_value:
  if (type == "object" | not) then ""
  elif .Type == "Lit" then .Value // ""
  elif .Type == "DblQuoted" then
    "\"" + ([.Parts[]? | get_part_value] | join("")) + "\""
  elif .Type == "SglQuoted" then
    "'" + (.Value // "") + "'"
  elif .Type == "ParamExp" then
    "$" + (.Param.Value // "")
  elif .Type == "CmdSubst" then
    # Represent command substitution as placeholder - nested commands extracted separately
    "$(..)"
  else
    ""
  end;

# Recursively find all CmdSubst and ProcSubst nodes in word parts
# Handles: DblQuoted, ParamExp (defaults, replacements), Array elements, etc.
def find_cmd_substs:
  if type == "object" then
    if .Type == "CmdSubst" or .Type == "ProcSubst" then .
    elif .Type == "DblQuoted" then .Parts[]? | find_cmd_substs
    elif .Type == "ParamExp" then
      # Parameter expansion: ${var:-$(cmd)}, ${var:=$(cmd)}, ${var/$(old)/$(new)}
      (.Exp?.Word | find_cmd_substs),
      (.Repl?.Orig | find_cmd_substs),
      (.Repl?.With | find_cmd_substs)
    elif .Parts then .Parts[]? | find_cmd_substs
    else empty
    end
  elif type == "array" then .[] | find_cmd_substs
  else empty
  end;

# Get full argument value (may have multiple parts concatenated)
def get_arg_value:
  [.Parts[]? | get_part_value] | join("");

# Get full command string from CallExpr
def get_command_string:
  if .Type == "CallExpr" and .Args then
    [.Args[] | get_arg_value] | map(select(length > 0)) | join(" ")
  else
    empty
  end;

# Recursively find and extract all commands
def extract_commands:
  if type == "object" then
    if .Type == "CallExpr" then
      get_command_string,
      # Extract nested command substitutions from arguments
      (.Args[]? | find_cmd_substs | .Stmts[]? | extract_commands),
      # Extract from variable assignments: var=$(cmd1 | cmd2)
      (.Assigns[]?.Value | find_cmd_substs | .Stmts[]? | extract_commands),
      # Extract from array assignments: arr=($(cmd1) $(cmd2))
      (.Assigns[]?.Array?.Elems[]?.Value | find_cmd_substs | .Stmts[]? | extract_commands),
      # Extract from redirects with process substitution: cmd < <(other_cmd)
      (.Redirs[]?.Word | find_cmd_substs | .Stmts[]? | extract_commands)
    elif .Type == "BinaryCmd" then
      (.X | extract_commands),
      (.Y | extract_commands)
    elif .Type == "Subshell" or .Type == "Block" then
      (.Stmts[]? | extract_commands)
    elif .Type == "CmdSubst" then
      (.Stmts[]? | extract_commands)
    elif .Type == "IfClause" then
      (.Cond[]? | extract_commands),
      (.Then[]? | extract_commands),
      (.Else | extract_commands)
    elif .Type == "WhileClause" or .Type == "UntilClause" then
      (.Cond[]? | extract_commands),
      (.Do[]? | extract_commands)
    elif .Type == "ForClause" then
      # Extract from loop iterator (e.g., `for i in $(cmd)`)
      (.Loop.Items[]? | find_cmd_substs | .Stmts[]? | extract_commands),
      (.Do[]? | extract_commands)
    elif .Type == "CaseClause" then
      (.Items[]?.Stmts[]? | extract_commands)
    elif .Cmd then
      (.Cmd | extract_commands),
      # Also extract from redirects at statement level: cmd < <(other_cmd)
      (.Redirs[]?.Word | find_cmd_substs | .Stmts[]? | extract_commands)
    elif .Stmts then
      (.Stmts[] | extract_commands)
    else
      (.[] | extract_commands)
    end
  elif type == "array" then
    (.[] | extract_commands)
  else
    empty
  end;

extract_commands | select(length > 0)
JQEOF

# jq filter for refuses_construct: prints the first reason the AST is not an
# approvable shape, or nothing. A command name is the first Arg's literal text
# (Lit, SglQuoted and literal-only DblQuoted parts joined, backslashes and any
# leading path dropped, so 'ba''sh', \bash and /bin/bash all read as bash); any
# other part (e.g. $X) makes it non-literal. The marker is \u0001, not \u0000:
# jq 1.6's contains() treats a NUL-led needle as empty and matches everything.
read -r -d '' SHAPE_FILTER << 'JQEOF' || true
def lit_word:
  [ .Parts[]?
    | if .Type == "Lit" or .Type == "SglQuoted" then .Value
      elif .Type == "DblQuoted" then
        ([.Parts[]? | if .Type == "Lit" then .Value else "\u0001" end] | join(""))
      else "\u0001" end ]
  | join("");
def plain_param:
  (del(.Pos, .End, .Type, .Dollar, .Param, .Rbrace, .Short, .Length)
   | with_entries(select(.value != null and .value != false)) | length) == 0;
# External programs that run their arguments as code.
def wrappers:
  ["bash","sh","zsh","dash","ksh","fish","env","xargs","sudo","nohup","nice",
   "timeout","stdbuf","watch","parallel","script","su"];
# Every bash 5.2 builtin (`compgen -b`), except the few that evaluate nothing
# (safe_builtins). A finite, known set, so refusing all of it converges where
# naming dangerous ones did not: read/printf -v/test -v evaluate an array
# subscript `a[$(cmd)]`, mapfile -C / compgen -C / bind -x run a command,
# hash -p redefines what a name runs, unset/getopts/wait -p take names too.
def builtins:
  [".",":","[","alias","bg","bind","break","builtin","caller","cd","command",
   "compgen","complete","compopt","continue","declare","dirs","disown","echo",
   "enable","eval","exec","exit","export","false","fc","fg","getopts","hash",
   "help","history","jobs","kill","let","local","logout","mapfile","popd",
   "printf","pushd","pwd","read","readarray","readonly","return","set","shift",
   "shopt","source","suspend","test","times","trap","true","type","typeset",
   "ulimit","umask","unalias","unset","wait"];
def safe_builtins: ["cd","pwd","echo","true","false","type"];
([ .. | objects
  | if has("Type") then
      if (.Type | IN("File","CallExpr","BinaryCmd","Lit","SglQuoted","DblQuoted","ParamExp") | not)
        then "node type \(.Type)"
      elif .Type == "ParamExp" and (plain_param | not)
        then "parameter expansion with an operator"
      elif .Type == "CallExpr" and ((.Assigns // []) | length) > 0
        then "assignment"
      elif .Type == "CallExpr" then
        ((.Args[0] // {}) | lit_word | gsub("\\\\"; "") | sub(".*/"; "")) as $name
        | if $name == "" or ($name | index("\u0001") != null) then "non-literal command name"
          elif ($name | IN(wrappers[])) then "interpreter or wrapper: \($name)"
          elif ($name | IN(builtins[])) and ($name | IN(safe_builtins[]) | not)
            then "shell builtin: \($name)"
          else empty end
      else empty end
    elif (.Background // false) or (.Coprocess // false) then "background statement"
    else empty end ]
| first) as $reason
# One jq pass for both answers (performance review: each extra jq process is
# ~20 ms on every approved call): "REFUSE <reason>", or else one line of byte
# offsets per redirect for refuses_construct's operator check.
| if $reason != null then "REFUSE \($reason)"
  else (.. | objects | select(has("Redirs")) | .Redirs[]?
        | "\(.OpPos.Offset) \(.Word.Pos.Offset) \(.Word.End.Offset)")
  end
JQEOF

# Normalize shfmt-incompatible patterns
# shfmt can't parse [[ ! X =~ Y ]] but can parse ! [[ X =~ Y ]]
normalize_for_shfmt() {
  local cmd="$1"
  # Transform [[ ! ... =~ ... ]] to ! [[ ... =~ ... ]]
  # Also handle \! (escaped bang from some shells)
  # Use perl for more reliable regex with non-greedy matching
  echo "$cmd" | perl -pe 's/\[\[\s*\\?!\s+(.+?)\s+=~\s*/! [[ $1 =~ /g'
}

# Extract raw commands from AST (internal, always newline-separated)
extract_commands_raw() {
  local cmd="$1"
  local ast

  debug "Parsing: $cmd"

  # Normalize patterns that shfmt can't handle
  cmd=$(normalize_for_shfmt "$cmd")
  debug "Normalized: $cmd"

  # Parse with shfmt (use bash dialect for bash-specific syntax like =~)
  if ! ast=$(echo "$cmd" | shfmt -ln bash -tojson 2>&1); then
    debug "Parse error: $ast"
    echo "Parse error: $ast" >&2
    return 1
  fi

  debug "AST parsed successfully"

  # Shapes the hook must never approve (see refuses_construct). Returning 1
  # makes main treat it like a parse failure: fall through to the normal
  # prompt. bash -c / sh -c never reach the inner recursion with approval
  # possible: refuses_construct already refuses those command names at the
  # outer level. Gated on REFUSE_CONSTRUCTS so the parse_commands extractor
  # still lists commands.
  if $REFUSE_CONSTRUCTS && refuses_construct "$cmd" "$ast"; then
    return 1
  fi

  # Extract commands using jq (always newline-separated internally)
  echo "$ast" | jq -r "$JQ_FILTER" 2>/dev/null
}

# True unless the parsed command has a SHAPE the hook may approve (decision log
# row 64). This is an allowlist of AST shapes, not a list of bad constructs:
# row 53, and then two rounds of review on this function, found that listing
# bad constructs does not converge (arithmetic strings such as
# `let 'a[$(cmd)]=1'`, `export PATH=...`, escaped backticks inside bash -c ...).
# Anything not named here makes the hook fall through to the normal prompt,
# including constructs nobody has thought of yet. Approvable:
#   - node types File, CallExpr, BinaryCmd (| |& && ||), Lit, SglQuoted,
#     DblQuoted, and ParamExp that is a plain $NAME / ${NAME} / ${#NAME}
#     (no ${x:-}, ${!x}, ${x@P}, ${a[i]}, ${x/a/b}, ${x:1}: several of those
#     evaluate code). So no $(...), `...`, <(...), $((...)), [[ ]], (( )),
#     let, export/declare/local/readonly, subshells, { }, if/for/while/case,
#     functions, time, coproc;
#   - statements that are not backgrounded (&);
#   - simple commands with no VAR= assignment (LD_PRELOAD=, PATH=) and whose
#     command name is literal (not $X) and is not an interpreter or wrapper
#     that runs its arguments as code (bash -c, eval, source, env, xargs, ...);
#   - redirects that cannot write or read a file: any operator containing '>'
#     (>, >>, &>, &>>, >|, <>, >&) is refused unless its target is exactly
#     /dev/null or it duplicates an fd (>&N, >&-); an input redirect `<` or
#     `<&` is refused unless it reads /dev/null or duplicates an fd.
#     Here-docs and here-strings (<<, <<<) pass: their text is inline.
#   - a command name that is not a bash builtin, other than cd, pwd, echo,
#     true, false and type (SHAPE_FILTER's builtins list says why).
# Any one allowed command is an outer command for these constructs, so they
# matter wherever an allow list exists: every project's own rules today, and a
# global list in hooks/wiring.json if one ships (shelved until a sandbox: Q-098).
#
# WHY SOURCE TEXT, NOT shfmt's Op FIELD: Op is a numeric token code (63 is `>`
# in shfmt 3.13.1) with no stability promise across versions. The operator is
# read instead from the command text between the redirect's OpPos and its
# Word's Pos. Those are byte offsets into the string shfmt parsed, so $1 must be
# that same (normalized) string, and slicing is done under LC_ALL=C (bytes).
refuses_construct() {
  local cmd="$1" ast="$2" op_off word_off word_end op word out
  local LC_ALL=C
  if ! out=$(jq -r "$SHAPE_FILTER" <<<"$ast"); then
    debug "Refusing: shape check failed"
    return 0
  fi
  if [[ "$out" == 'REFUSE '* ]]; then
    debug "Refusing: ${out#REFUSE }"
    return 0
  fi
  while read -r op_off word_off word_end; do
    [[ -n "$op_off" ]] || continue
    op=${cmd:op_off:word_off-op_off}
    op=${op//[[:space:]]/}
    word=${cmd:word_off:word_end-word_off}
    # Here-docs and here-strings (<<, <<-, <<<) carry their text inline. A
    # plain `<` (or `<&`) opens a path, and any approved command that prints its
    # input would print that file (`tr -d x < ~/.claude/.c*`), so it passes only
    # from /dev/null or as an fd duplication.
    if [[ "$op" == '<<'* ]]; then continue; fi
    if [[ "$op" == '<&' && "$word" =~ ^([0-9]+|-)$ ]]; then continue; fi
    if [[ "$op" == '<' && "$word" == /dev/null ]]; then continue; fi
    if [[ "$op" == '<'* && "$op" != *'>'* ]]; then
      debug "Refusing input redirect: '$op' '$word'"
      return 0
    fi
    if [[ "$op" == '>&' && "$word" =~ ^([0-9]+|-)$ ]]; then continue; fi
    if [[ "$op" != '>&' && "$word" == /dev/null ]]; then continue; fi
    debug "Refusing redirect: '$op' '$word'"
    return 0
  done <<<"$out"
  return 1
}

# Check if a command is "bash -c" or "sh -c" and extract the inner command
# Returns the inner command string if it matches, empty otherwise
# Handles:
#   - bash -c 'cmd' / sh -c 'cmd'
#   - /bin/bash -c 'cmd' / /usr/bin/bash -c 'cmd' (absolute paths)
#   - env bash -c 'cmd' / env sh -c 'cmd' (env prefix)
#   - env /bin/bash -c 'cmd' (env with absolute path)
get_shell_c_inner() {
  local cmd="$1"

  # Pattern components:
  # - Optional 'env ' prefix
  # - Optional path prefix (e.g., /bin/, /usr/bin/)
  # - bash or sh
  # - -c flag with optional space
  # - quoted string
  # Note: Using separate checks for clarity and to avoid complex regex escaping

  # Strip optional 'env ' prefix first
  local stripped="$cmd"
  if [[ "$cmd" =~ ^env[[:space:]]+ ]]; then
    stripped="${cmd#env }"
    stripped="${stripped# }"  # Remove any extra spaces
  fi

  # Strip optional path prefix (e.g., /bin/, /usr/bin/)
  if [[ "$stripped" =~ ^/[^[:space:]]*/(.+)$ ]]; then
    stripped="${BASH_REMATCH[1]}"
  fi

  # Now match: bash -c '...' or sh -c '...'
  if [[ "$stripped" =~ ^(bash|sh)[[:space:]]+-c[[:space:]]*[\'\"](.*)[\'\"]$ ]]; then
    echo "${BASH_REMATCH[2]}"
  elif [[ "$stripped" =~ ^(bash|sh)[[:space:]]+-c[\'\"](.*)[\'\"]$ ]]; then
    echo "${BASH_REMATCH[2]}"
  fi
}

# Main extraction function - handles bash -c recursively
extract_commands_from_string() {
  local cmd="$1"
  local raw_commands

  debug "Input command: $cmd"

  # Get raw commands
  raw_commands=$(extract_commands_raw "$cmd") || return 1

  # Process each command, recursively expanding bash -c / sh -c
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue

    local inner
    inner=$(get_shell_c_inner "$line")

    if [[ -n "$inner" ]]; then
      debug "Found shell -c, recursing into: $inner"
      # Recursively extract commands from the inner script; an inner parse
      # failure must fail the whole extraction, not vanish (see main).
      extract_commands_from_string "$inner" || return 1
    else
      # Output the command with appropriate delimiter
      if $NUL_DELIM; then
        printf '%s\0' "$line"
      else
        echo "$line"
      fi
    fi
  done <<< "$raw_commands"
}

parse_commands() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        show_help
        exit 0
        ;;
      -d|--debug)
        DEBUG=true
        shift
        ;;
      -0|--null)
        NUL_DELIM=true
        shift
        ;;
      --)
        shift
        break
        ;;
      -*)
        echo "Unknown option: $1" >&2
        exit 1
        ;;
      *)
        break
        ;;
    esac
  done

  check_deps

  # Get command from argument or stdin
  if [[ $# -gt 0 ]]; then
    command_str="$*"
  else
    command_str=$(cat)
  fi

  if [[ -z "$command_str" ]]; then
    echo "Error: No command provided" >&2
    exit 1
  fi

  extract_commands_from_string "$command_str"
}

case "${1:-}" in
	parse_commands)
		shift
		parse_commands "$@"
		;;
	*)
		main "$@"
		;;
esac
