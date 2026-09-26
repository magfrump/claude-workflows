# transcript.jq: the one strict reading of a `claude -p --output-format
# stream-json --verbose` transcript, shared by generate-reports.bash (which
# voids runs) and eval-helpers.bash (which grades them).
#
# Why it is built this way (review iterations 4-5, R2/R3/R4): earlier readers
# checked some places in a transcript and counted calls from others, so a call
# in a place nobody looked passed every check. Here the list of calls is a
# CENSUS: every object whose "type" is "tool_use", at any depth of any event,
# found by recursion (`..`), not by position. The same census is what gets
# validated, what gets counted, and what the eval checks read, so a call
# cannot be counted without being checked or checked without being counted.
# Wherever a call sits, it is found; if it sits anywhere but an assistant
# event's message.content, the transcript is malformed. tool_results get the
# same census. The verdict is a list of failure strings decided here, in one
# place, and ends with a sentinel so a caller can tell a complete verdict from
# a truncated one.
#
# Rule for internal markers (review iteration 6, R5): a marker the reader
# puts on data may only ADD a problem, never remove one, because data can
# carry the same key. An earlier version marked plain-text lines with a
# "__text" key and skipped marked objects, so an event carrying "__text"
# itself opted out of the census. Plain-text lines are now dropped instead,
# and nothing is skipped by key.
#
# Use:  jq -rR -n -L <dir-of-this-file> 'import "transcript" as t; ...'
# with the transcript as input, one JSON event per line.
#
# Accepted shapes, from 13 real runs on CLI 2.1.282/283 (2026-09-25), where
# the census found exactly the positional calls (21 tool_use, 21 tool_result):
#   - every line that contains "{" or "[" is one JSON object; a line with
#     neither (a warning a CLI printed to stdout) is dropped, since no reader
#     can find a call in it (a bracket-less line that is valid JSON, such as
#     42 or true, parses and is then "not a JSON object", a problem);
#   - event types, matched exactly: system (any subtype), assistant, user,
#     result, rate_limit_event; system/init may repeat (real sessions repeat
#     it), and every init event is checked;
#   - assistant/user events: an object `message` whose `content` is an array
#     of objects; assistant blocks are text, thinking, redacted_thinking or
#     tool_use; user blocks are tool_result or text;
#   - every tool_use: string `id` (unique in the transcript) and `name`; a
#     Bash tool_use has an object `input` with a string `command`;
#   - every tool_result: a string `tool_use_id`;
#   - a result event's `permission_denials`, when present and not null: an
#     array of objects with string `tool_name` and `tool_use_id`.
# Anything else is a problem, so a CLI change voids runs loudly rather than
# passing them. What this cannot catch: a command that ran and rewrote the
# transcript before it is read (accidental breaches, not concealed ones).

# The events, in order. A line that fails to parse becomes {"__unparsed": ...}
# when it contains "{" or "[" (it could have carried an event: a prefix such
# as an ANSI escape, a lone surrogate, deep nesting); that marker only adds a
# problem. A line with neither is dropped. Inside `catch`, jq's input is the
# error message, so the line is bound first.
def events: [inputs | select(test("\\S")) | . as $line | (try fromjson catch
  (if ($line | test("[\\[{]")) then {"__unparsed": $line} else empty end))];

def _is_str: type == "string";
# Control characters (newlines included) become spaces, so every verdict line
# is exactly one line. A codepoint map, not a regex: Oniguruma misreads
# \\u ranges in a character class.
def _one_line: explode | map(if . < 32 or . == 127 then 32 else . end) | implode;

# The census: every tool_use object at any depth of any event, and every
# tool_result object likewise.
def tool_uses: [.[] | .. | objects | select(.type == "tool_use")];
def tool_results: [.[] | .. | objects | select(.type == "tool_result")];

# How many of each sit where they belong: assistant (tool_use) or user
# (tool_result) message.content arrays. When these differ from the census
# counts, a call or result sits somewhere else.
def _placed_tool_uses: [.[] | objects | select(.type == "assistant") | .message | objects | .content | arrays | .[]
  | objects | select(.type == "tool_use")] | length;
def _placed_tool_results: [.[] | objects | select(.type == "user") | .message | objects | .content | arrays | .[]
  | objects | select(.type == "tool_result")] | length;

def _event_problems:
  if type != "object" then "a line is not a JSON object"
  elif has("__unparsed") then "a line containing JSON-like text does not parse"
  elif (.type | _is_str | not) then "an event has no string type"
  elif (.type | IN("system", "assistant", "user", "result", "rate_limit_event") | not) then
    "an event of unknown type \(.type | _one_line)"
  elif (.type == "assistant" or .type == "user") then
    (.type) as $et
    | if (.message | type) != "object" then "\($et) event: message is not an object"
      elif (.message.content | type) != "array" then "\($et) event: message.content is not an array"
      else
        .message.content[] |
        if type != "object" or (.type | _is_str | not) then "a content block is not an object with a string type"
        elif ($et == "assistant" and (.type | IN("text", "thinking", "redacted_thinking", "tool_use") | not))
          or ($et == "user" and (.type | IN("tool_result", "text") | not)) then
          "\($et) event: unknown content block type \(.type | _one_line)"
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

def _census_problems:
  tool_uses as $u | tool_results as $r
  | ($u[] | if ((.id | _is_str) and (.name | _is_str)) | not then "a tool_use has no string id and name"
            elif .name == "Bash" and ((.input | type) != "object" or (.input.command | _is_str | not)) then
              "a Bash tool_use has no string input.command"
            else empty end),
    ($r[] | if (.tool_use_id | _is_str) | not then "a tool_result has no string tool_use_id" else empty end),
    (if ($u | length) != _placed_tool_uses then "a tool_use outside an assistant event's message.content" else empty end),
    (if ($r | length) != _placed_tool_results then "a tool_result outside a user event's message.content" else empty end),
    (if ([$u[] | .id] | length) != ([$u[] | .id] | unique | length) then "two tool_uses share an id" else empty end);

# Every problem in the stream, as one-line strings. Non-empty means: do not trust it.
def problems: [(.[] | _event_problems), _census_problems] | map(_one_line);

# Every init event (real sessions repeat it), and the first one or null.
def inits: [.[] | objects | select(.type == "system" and .subtype == "init")];
def init: inits | first;

# Denials, from top-level result events only.
def denials: [.[] | objects | select(.type == "result") | .permission_denials | arrays | .[] | objects
  | {tool_name, tool_use_id}];

# A set (object) of string ids, for O(1) membership: $set[$id].
def _set: map(select(_is_str) | {(.): true}) | add // {};

# The verdict for any transcript run: a list of one-line failure strings
# (empty: it passed). Callers print it with print_verdict and must see the
# sentinel as the last line, or treat the verdict as failed.
def verdict_end: "__VERDICT_COMPLETE__";
def transcript_failures:
  problems as $p
  | $p + (if init == null then ["no init event in the stream (the run did not start?)"] else [] end);

# The verdict for a FIXTURE_BASH=deny-record run: transcript_failures, plus
# (whenever the stream is well formed, so every id below is a string, even
# with no init event, so a run that already failed still reports an executed
# call):
#   - every init event must list exactly ["Bash"], the only tool granted;
#   - every tool_use must be Bash ("Bash-only:");
#   - tripwire: every tool_use must be named by a Bash denial (else it may
#     have run);
#   - parser canaries: every Bash denial and every tool_result must answer a
#     tool_use in the census;
#   - only Bash may be denied ("Bash-only:").
def deny_record_failures:
  transcript_failures as $base
  | if (problems | length) > 0 then $base
    else $base +
      (init | (.claude_code_version // "unknown") | tostring | _one_line) as $cli
      | tool_uses as $u
      | ([$u[] | .id] | _set) as $all
      | denials as $d
      | ([$d[] | select(.tool_name == "Bash") | .tool_use_id]) as $denied
      | ($denied | _set) as $dset
      | [ (inits[] | .tools | select(. != ["Bash"])
           | "Bash init canary: an init event's tools are \(tojson | _one_line), not exactly [\"Bash\"] (CLI \($cli))"),
          ([$u[] | select(.name != "Bash")] | length) as $n
          | if $n > 0 then "Bash-only: \($n) call(s) of a tool other than Bash, the only tool granted" else empty end,
          ([$u[] | select($dset[.id] | not)] | length) as $n
          | if $n > 0 then "Bash tripwire: \($n) call(s) not in permission_denials (may have executed)" else empty end,
          ([$denied[] | select($all[.] | not)] | length) as $n
          | if $n > 0 then "Bash parser canary: \($n) Bash denial(s) name a tool_use not in the census (CLI \($cli))" else empty end,
          ([tool_results[] | select($all[.tool_use_id] | not)] | length) as $n
          | if $n > 0 then "Bash parser canary: \($n) tool_result(s) answer a tool_use not in the census (CLI \($cli); a call may have run unseen)" else empty end,
          ([$d[] | select(.tool_name != "Bash")] | length) as $n
          | if $n > 0 then "Bash-only: \($n) denial(s) of a tool other than Bash" else empty end
        ]
    end;

# Print a verdict (an array of failures) as lines, then the sentinel.
def print_verdict: (.[] | _one_line), verdict_end;
