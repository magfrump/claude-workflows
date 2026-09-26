[inputs | fromjson? | objects] as $ev
        | ([$ev[] | select(.type == "system" and .subtype == "init")] | first) as $init
        | ([$ev[] | select(.type == "result") | .permission_denials[]?
            | select(type == "object" and .tool_name == "Bash") | .tool_use_id]) as $denied
        | ($denied | map(select(. != null) | {(tostring): true}) | add // {}) as $dset
        | [$ev[] | select(.type == "assistant") | .message.content[]? | objects
           | select(.type == "tool_use" and .name == "Bash") | .id] as $calls
        | ($calls | map(select(. != null) | {(tostring): true}) | add // {}) as $cset
        | [ ($calls | map(select(. == null or ($dset[tostring] | not))) | length),
            ($denied | map(select(. == null or ($cset[tostring] | not))) | length),
            (if $init == null then "none" elif (($init.tools // []) | index("Bash")) then "bash" else "nobash" end),
            ($init.claude_code_version // "unknown") ] | @tsv