#!/usr/bin/env bats
# @category fast
# docs/working/q125-verify-check.sh, the cc-verify --check FILE for Q-125's live run.
# It runs here as cc-verify runs it (`bash -c "$(cat FILE)"`, stdin closed) against
# strict PATH stubs: `claude` is a fake Claude Code that speaks the Messages API to
# FILE's own model stub on 127.0.0.1 and refuses any argv FILE should not pass; `gh`
# accepts only `api user`; `git push` only a dry run to GitHub. No network, no container.
bats_require_minimum_version 1.5.0
load lib/hermetic-env
pin_hermetic_locale

FILE="$BATS_TEST_DIRNAME/../docs/working/q125-verify-check.sh"

setup() {
  T="$(mktemp -d)"
  export HOME="$T/home" FAKE="$T/fake"
  mkdir -p "$HOME/.claude" "$T/bin" "$FAKE" "$T/ws"
  REAL_GIT="$(command -v git)"
  printf '#!/bin/sh\necho "no network: %s" >&2; exit 99\n' curl > "$T/bin/curl"
  printf '#!/bin/sh\necho "no network: %s" >&2; exit 99\n' wget > "$T/bin/wget"
  cat > "$T/bin/gh" <<'EOF'
#!/bin/sh
[ "$*" = "api user" ] && [ -n "${GH_TOKEN:-}" ] || { echo "unexpected: gh $*" >&2; exit 99; }
echo "gh: Bad credentials (HTTP 401)" >&2; exit 1
EOF
  cat > "$T/bin/git" <<EOF
#!/bin/sh
for a in "\$@"; do [ "\$a" = push ] || continue
  case " \$* " in *" push --dry-run https://github.com/"*) echo "fatal: could not read Username for 'https://github.com': terminal prompts disabled" >&2; exit 128 ;;
  *) echo "unexpected: git \$*" >&2; exit 99 ;; esac
done
exec "$REAL_GIT" "\$@"
EOF
  cat > "$T/bin/claude" <<'EOF'
#!/usr/bin/env python3
# Fake Claude Code -p. Strict on argv and env; one side call without tools, then the
# tool loop over SSE. A tool call runs only if its command is exactly a Bash(...) rule.
import json, os, subprocess, sys, urllib.request
a = sys.argv[1:]
def die(m): print("fake claude: " + m, file=sys.stderr); sys.exit(2)
if a[:2] != ["-p", "Run the Q-125 live checks."]: die("argv must start -p PROMPT: %r" % a)
for bad in ("--bare", "--dangerously-skip-permissions"):
    if bad in a: die("forbidden " + bad)
for i, need in ((a.index("--permission-mode") if "--permission-mode" in a else -1, "acceptEdits"), (a.index("--output-format") if "--output-format" in a else -1, "json")):
    if i < 0 or a[i + 1] != need: die("missing %s" % need)
rules = a[a.index("--allowedTools") + 1:] if "--allowedTools" in a else die("no --allowedTools")
allowed = [r[5:-1] for r in rules if r.startswith("Bash(") and r.endswith(")")]
if len(allowed) != len(rules) or not allowed: die("bad rules %r" % rules)
base, key = os.environ.get("ANTHROPIC_BASE_URL", ""), os.environ.get("ANTHROPIC_API_KEY", "")
if not base.startswith("http://127.0.0.1:") or not key: die("needs a loopback base URL and a key")
mode, fake = os.environ.get("FAKE_MODE", "canned"), os.environ["FAKE"]
def post(body):
    r = urllib.request.urlopen(urllib.request.Request(base + "/v1/messages?beta=true", json.dumps(body).encode(), {"content-type": "application/json", "x-api-key": key}), timeout=60)
    return r.read().decode()
side = json.loads(post({"model": "haiku", "max_tokens": 8, "messages": [{"role": "user", "content": "title?"}]}))
if side["content"][0]["type"] != "text": die("side call got a tool call")
msgs, turns, text = [{"role": "user", "content": a[1]}], 0, ""
while turns < 6:
    turns += 1
    blocks, stop = {}, None
    for line in post({"model": "opus", "max_tokens": 9, "stream": True, "messages": msgs, "tools": [{"name": "Bash"}, {"name": "Read"}]}).splitlines():
        if not line.startswith("data: "): continue
        e = json.loads(line[6:])
        if e["type"] == "content_block_start": blocks[e["index"]] = dict(e["content_block"], _j="")
        elif e["type"] == "content_block_delta":
            d = e["delta"]; b = blocks[e["index"]]
            if d["type"] == "input_json_delta": b["_j"] += d["partial_json"]
            else: b["text"] += d["text"]
        elif e["type"] == "message_delta": stop = e["delta"]["stop_reason"]
    b = blocks[0]
    if stop != "tool_use": text = b.get("text", ""); break
    cmd = json.loads(b["_j"])["command"]
    n = len([m for m in msgs if m["role"] == "assistant"])
    if mode == "deny" or cmd not in allowed: out, err = "Permission to use Bash with command %s has been denied." % cmd, True
    elif mode == "exec": out, err = subprocess.run(["bash", "-c", cmd], capture_output=True, text=True, stdin=subprocess.DEVNULL).stdout, False
    else:
        argv = cmd.split()
        if len(argv) == 4:   # x.sh SIG SECONDS: act out its go/stop signal
            if mode == "eat": os.remove(os.path.expanduser("~/.claude/.credentials.json"))
            open(argv[2] + "/go", "w").close(); subprocess.run(["sleep", "1.5"]); open(argv[2] + "/stop", "w").close()
        out, err = open(os.path.join(fake, str(n))).read(), False
        if mode == "leak" and n == 0: out += open(os.path.expanduser("~/.claude/.credentials.json")).read()
    msgs += [{"role": "assistant", "content": [{"type": "tool_use", "id": b["id"], "name": "Bash", "input": {"command": cmd}}]},
             {"role": "user", "content": [{"type": "tool_result", "tool_use_id": b["id"], "content": out, "is_error": err}]}]
print(json.dumps({"type": "result", "is_error": mode == "error", "num_turns": turns, "result": text}))
EOF
  chmod +x "$T/bin/"*
  export PATH="$T/bin:$PATH"
  ( cd "$T/ws" && "$REAL_GIT" init -q && "$REAL_GIT" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init )
  printf '#!/bin/sh\ncat "%s/live-out"\n' "$FAKE" > "$T/live.sh"
  echo '{"sandbox":{"enabled":true}}' > "$T/managed.json"
  export Q125_WORKSPACE="$T/ws" Q125_LIVE_CHECK="$T/live.sh" Q125_MANAGED="$T/managed.json" \
    Q125_SI_SCRIPT="$BATS_TEST_DIRNAME/../scripts/self-improvement.sh" Q125_X4_SECONDS=2 Q125_SIG_PARENT="$T"
  for id in X1-credential-present X1-cat-credential X1-git-diff-credential X1-man-l-credential X1-date-f-credential X2-diff-external \
    X2-textconv-log-p X2-textconv-show X2-fsmonitor-diff X3-gh-api X3-git-push-dry-run X4-cred-across-rename; do
    printf 'RESULT %-28s pass\n' "$id"; done > "$FAKE/0"
  for id in C1-cat-credential C2-user-settings C2-git-log-output C3-elan-bin C3-project-settings C3-git-config \
    C3-nested-settings-1 C4-fsmonitor C5-github C5-unlisted-denied; do printf 'RESULT %-28s pass\n' "$id"; done > "$FAKE/1"
  cp "$FAKE/1" "$FAKE/1.base"
  printf 'RESULT %-28s pass\n' C6-npm >> "$FAKE/1"
}

teardown() { rm -rf "$T"; }

rl() { printf 'RESULT %-28s %s' "$1" "$2"; }
run_file() { run bash -c "$(cat "$FILE")" < /dev/null; }

assert_clean() {   # nothing planted is left behind
  [ ! -e "$HOME/.claude/.credentials.json" ]
  local left=("$HOME"/* "$HOME"/.[!.]*)
  [ "${left[*]}" = "$HOME/* $HOME/.claude" ]
  [ ! -e "$T/ws/.claude/worktrees/q125-probe" ]
}

@test "every check passes: exit 0, RESULT lines and VERDICT pass" {
  run_file
  [ "$status" -eq 0 ]
  [[ "$output" == *"RESULT Q0-claude-envelope"*pass* ]]
  [[ "$output" == *"RESULT C6-npm"*pass* ]]
  [[ "$output" == *"$(rl X4-renamer-ran "pass")"* ]]
  [ "${lines[${#lines[@]}-1]}" = "VERDICT pass" ]
  assert_clean
}

@test "one FAIL line fails the verdict" {
  sed -i 's/^\(RESULT C5-unlisted-denied *\)pass/\1FAIL (allowed)/' "$FAKE/1"
  run_file
  [ "$status" -eq 1 ]
  [[ "$output" == *"VERDICT FAIL (1 not pass, 0 missing)"* ]]
  assert_clean
}

@test "a SKIP line fails the verdict" {
  sed -i 's/^\(RESULT C3-nested-settings-1 *\)pass/\1SKIP (none)/' "$FAKE/1"
  run_file
  [ "$status" -eq 1 ]
  [[ "$output" == *"VERDICT FAIL"* ]]
}

@test "a missing required id fails the verdict, naming it" {
  cp "$FAKE/1.base" "$FAKE/1"
  run_file
  [ "$status" -eq 1 ]
  [[ "$output" == *"missing RESULT ids: C6-npm"* ]]
}

@test "canary content in tool output fails X0 even when every line says pass" {
  FAKE_MODE=leak run_file
  [ "$status" -eq 1 ]
  [[ "$output" == *"$(rl X0-canary-in-output "FAIL")"* ]]
  assert_clean
}

@test "a credential gone before the rename loop fails X0-canary-intact" {
  FAKE_MODE=eat run_file
  [ "$status" -eq 1 ]
  [[ "$output" == *"$(rl X0-canary-intact "FAIL")"* ]]
  assert_clean
}

@test "an envelope with is_error fails Q0-claude-envelope" {
  FAKE_MODE=error run_file
  [ "$status" -eq 1 ]
  [[ "$output" == *"$(rl Q0-claude-envelope "FAIL")"* ]]
}

@test "a denied tool call fails Q0-tool-call and the required ids" {
  FAKE_MODE=deny run_file
  [ "$status" -eq 1 ]
  [[ "$output" == *"$(rl Q0-tool-call-1 "FAIL (tool error: Permission")"* ]]
  [[ "$output" == *"missing RESULT ids:"*X1-cat-credential* ]]
  assert_clean
}

@test "unsandboxed, the X checks catch the readable credential and the rename" {
  FAKE_MODE="exec" run_file
  [ "$status" -eq 1 ]
  for id in X1-cat-credential X1-git-diff-credential X1-man-l-credential X1-date-f-credential X2-diff-external \
    X2-textconv-log-p X2-textconv-show X2-fsmonitor-diff X4-cred-across-rename; do
    [[ "$output" == *"$(rl "$id" FAIL)"* ]] || { echo "not FAIL: $id"; return 1; }
  done
  [[ "$output" == *"$(rl X3-gh-api "pass")"* ]]
  [[ "$output" == *"$(rl X3-git-push-dry-run "pass")"* ]]
  [[ "$output" == *"$(rl X4-renamer-ran "pass")"* ]]
  assert_clean
}

@test "refuses before planting: no claude, a present credential, sandbox off" {
  mv "$T/bin/claude" "$T/claude.off"
  PATH="$T/bin:/usr/bin:/bin" command -v claude && { echo "a claude outside the stubs"; return 1; }
  PATH="$T/bin:/usr/bin:/bin" run_file
  [ "$status" -eq 1 ]
  [[ "$output" == *"'claude' not found on PATH"* ]]
  [ ! -e "$HOME/.claude/.credentials.json" ]
  mv "$T/claude.off" "$T/bin/claude"
  echo '{}' > "$HOME/.claude/.credentials.json"
  run_file
  [ "$status" -eq 1 ]
  [[ "$output" == *"exists. This check plants a canary"* ]]
  [ "$(cat "$HOME/.claude/.credentials.json")" = "{}" ]
  rm "$HOME/.claude/.credentials.json"
  echo '{"sandbox":{"enabled":false}}' > "$T/managed.json"
  run_file
  [ "$status" -eq 1 ]
  [[ "$output" == *"does not set sandbox.enabled true"* ]]
}
