# transcript.jq: the one strict reading of a `claude -p --output-format
# stream-json --verbose` transcript, shared by generate-reports.bash (which
# voids runs) and eval-helpers.bash (which grades them). Review iteration 4
# (R2, A21): each consumer used to parse the stream its own way and skip
# whatever it could not read, so an event of an unexpected shape could carry a
# Bash call past every check. Here an unexpected shape is a problem, never
# skipped, and "a Bash call", "denied" and "seen" are defined once.
#
# Use:  jq -rR -n -L <dir-of-this-file> 'import "transcript" as t; ...'
# with the transcript as input, one JSON event per line (blank lines ignored).
#
# Shapes accepted, matching 13 real runs of CLI 2.1.283 (2026-09-25): every
# line a JSON object; assistant and user events carry an object `message`
# whose `content` is an array of objects, each with a string `type`; a
# tool_use has string `id` and `name`, and a Bash tool_use an object `input`
# with a string `command`; a tool_result has a string `tool_use_id`; a result
# event's `permission_denials`, when present, is an array of objects with
# string `tool_name` and `tool_use_id`. Other event types (system, rate-limit
# and the like) need only be objects.

# The events, in order. A line that fails to parse becomes {"__unparsed": ...}
# (a problem) when it starts like JSON, "{" or "[": that is how a model-chosen
# input jq cannot read (a lone surrogate escape, deep nesting) would otherwise
# vanish with the call it carries. A plain-text line (a warning a CLI printed
# to stdout) cannot carry a tool call for any reader, so it becomes
# {"__text": ...} and is ignored.
# Note: inside `catch`, jq's input is the error message, so the line is bound
# first (an earlier version tested the message and let a JSON-like line through).
def events: [inputs | select(test("\\S")) | . as $line | (try fromjson catch
  (if ($line | test("^\\s*[\\[{]")) then {"__unparsed": $line} else {"__text": $line} end))];

def _is_str: type == "string";

# A description of what is wrong with one event, or empty when it is well formed.
def _event_problems:
  if type != "object" then "a line is not a JSON object"
  elif has("__unparsed") then "a line starting like JSON does not parse"
  elif (.type == "assistant" or .type == "user") then
    if (.message | type) != "object" then "\(.type) event: message is not an object"
    elif (.message.content | type) != "array" then "\(.type) event: message.content is not an array"
    else
      .message.content[] |
      if type != "object" or ((.type // null) | _is_str | not) then "a content block is not an object with a string type"
      elif .type == "tool_use" then
        if ((.id | _is_str) and (.name | _is_str)) | not then "a tool_use has no string id and name"
        elif .name == "Bash" and ((.input | type) != "object" or ((.input.command // null) | _is_str | not)) then
          "a Bash tool_use has no string input.command"
        else empty end
      elif .type == "tool_result" and ((.tool_use_id // null) | _is_str | not) then "a tool_result has no string tool_use_id"
      else empty end
    end
  elif .type == "result" and has("permission_denials") and .permission_denials != null then
    if (.permission_denials | type) != "array" then "result event: permission_denials is not an array"
    else
      .permission_denials[] |
      if type != "object" or ((.tool_name | _is_str) and (.tool_use_id | _is_str) | not) then
        "a permission denial has no string tool_name and tool_use_id"
      else empty end
    end
  else empty end;

# Every problem in the stream, as strings. Non-empty means: do not trust it.
def problems: [.[] | _event_problems];

# The first init event, or null.
def init: [.[] | objects | select(.type == "system" and .subtype == "init")] | first;

# Tool calls: {id, name, input} for every tool_use, at any depth (sub-agents'
# events are assistant events too).
def tool_uses:
  [.[] | objects | select(.type == "assistant") | .message.content[]? | objects | select(.type == "tool_use")
   | {id, name, input}];

# Every denial as {tool_name, tool_use_id}.
def denials: [.[] | objects | select(.type == "result") | .permission_denials[]? | objects | {tool_name, tool_use_id}];

# tool_use ids that have a tool_result (a call that got an answer, denied or run).
def tool_result_ids: [.[] | objects | select(.type == "user") | .message.content[]? | objects
  | select(.type == "tool_result") | .tool_use_id];

# A set (object) of the given string ids, for O(1) membership: $set[$id].
def _set: map({(.): true}) | add // {};

# Deny-record verdict counts (see generate-reports.bash's generate_one). Only
# meaningful when `problems` is empty, which guarantees every id is a string.
#   undenied   Bash tool_uses whose id no Bash denial names (may have run)
#   unseen     Bash denials naming a tool_use the parser did not see
#   orphans    tool_results answering a tool_use the parser did not see
#   foreign    denials of a tool other than Bash (only Bash is granted)
def deny_record_counts:
  (tool_uses) as $uses
  | ([$uses[] | select(.name == "Bash") | .id]) as $bash
  | ($bash | _set) as $bash_set
  | ([$uses[] | .id] | _set) as $all_set
  | (denials) as $d
  | ([$d[] | select(.tool_name == "Bash") | .tool_use_id]) as $denied
  | ($denied | _set) as $denied_set
  | { undenied: ([$bash[] | select($denied_set[.] | not)] | length),
      unseen:   ([$denied[] | select($bash_set[.] | not)] | length),
      orphans:  ([tool_result_ids[] | select($all_set[.] | not)] | length),
      foreign:  ([$d[] | select(.tool_name != "Bash")] | length) };
