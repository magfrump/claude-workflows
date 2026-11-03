#!/usr/bin/env bash
# q125-verify-check.sh: the `cc-verify --check` FILE for Q-125's live run (brief
# docs/working/briefs/2026-11-03-q125-verify-check.md; design and residuals in
# docs/working/research-2026-11-03-q125-verify-check.md, force-added on its branch).
#
# RUN it on the HOST, from your claude-workflows checkout at main:
#   cc-verify --check docs/working/q125-verify-check.sh . feat/q125-cc-isolated-sandbox
# cc-verify builds main + the branch in a throwaway container and runs this text there
# as `bash -c`, stdin closed. Exit 0 is pass (cc-verify exits 0); anything else is a
# failed check (cc-verify exits 3).
#
# WHAT IT CHECKS. Only Claude Code's Bash tool is sandboxed, so this starts a headless
# `claude -p` whose "model" is a stub on 127.0.0.1 (ANTHROPIC_BASE_URL; no login, no
# LLM, nothing sent off the container). The stub asks for exactly two Bash tool calls:
#   1. this file's own checks (X lines): the credential read four ways and judged by
#      CONTENT (cat, git diff --no-index, man -l, date -f); Q-098's leak-list git drivers
#      (diff.external, textconv under log -p and show, core.fsmonitor under diff);
#      `gh api user` and `git push --dry-run` reaching GitHub with no prompt (a 401 or
#      a username refusal is GitHub answering); and a read loop while the credential is
#      replaced by rename every half second, as a token refresh does;
#   2. the branch's docs/working/live-check-q125.sh, unmodified (C lines).
# The credential is a canary this file plants with a per-run marker; tool output that
# holds the marker is a leak. A nested worktree is added so the C3 nested checks run.
#
# OUTPUT. `RESULT <id> pass|FAIL|SKIP ...` lines (cc-verify indents them `  | `), then
# one `VERDICT pass|FAIL` line. VERDICT pass needs every RESULT line to say pass and
# every id in REQUIRED to appear. Paste back everything from the first RESULT line to
# cc-verify's own closing RESULT line.
# Test-only overrides: Q125_WORKSPACE, Q125_LIVE_CHECK, Q125_SI_SCRIPT, Q125_MANAGED,
# Q125_X4_SECONDS (test/q125-verify-check.bats).
set -u

WS="${Q125_WORKSPACE:-/workspace}"
LIVE="${Q125_LIVE_CHECK:-$WS/docs/working/live-check-q125.sh}"
SI="${Q125_SI_SCRIPT:-$WS/scripts/self-improvement.sh}"
MANAGED="${Q125_MANAGED:-/etc/claude-code/managed-settings.json}"
X4S="${Q125_X4_SECONDS:-20}"
CRED="$HOME/.claude/.credentials.json"
REQUIRED=(Q0-claude-envelope Q0-tool-call-1 Q0-tool-call-2 X0-canary-in-output X4-renamer-ran
  X1-cat-credential X1-git-diff-credential X1-man-l-credential X1-date-f-credential
  X2-diff-external X2-textconv-log-p X2-textconv-show X2-fsmonitor-diff X3-gh-api
  X3-git-push-dry-run X4-cred-across-rename C1-cat-credential C2-user-settings
  C2-git-log-output C3-elan-bin C3-project-settings C3-git-config C3-nested-settings-1
  C4-fsmonitor C5-github C5-unlisted-denied C6-npm)
D="" SIG="" STUB_PID="" REN_PID="" WT=""
fail() { printf 'ERROR: %s\n' "$*" >&2; echo "VERDICT FAIL (setup: $*)"; exit 1; }
# shellcheck disable=SC2317  # run by the EXIT trap
cleanup() {
  local p
  for p in "$REN_PID" "$STUB_PID"; do [ -z "$p" ] || kill "$p" 2>/dev/null; done
  wait 2>/dev/null
  [ -z "$WT" ] || git -C "$WS" worktree remove --force "$WT" >/dev/null 2>&1
  rm -f -- "$CRED" "$CRED.q125tmp"
  [ -z "$D" ] || rm -rf -- "$D"
  [ -z "$SIG" ] || rm -rf -- "$SIG"
}

# --- preflight: refuse before planting anything --------------------------------
for c in claude python3 jq git timeout; do command -v "$c" >/dev/null || fail "'$c' not found on PATH."; done
[ -f "$LIVE" ] || fail "no $LIVE: is this container built from the Q-125 branch's merge tree?"
[ "$(jq -r '.sandbox.enabled' "$MANAGED" 2>/dev/null)" = true ] || fail "$MANAGED does not set sandbox.enabled true."
[ -d "$HOME/.claude" ] || fail "no $HOME/.claude volume."
[ ! -e "$CRED" ] || fail "$CRED exists. This check plants a canary there, so it runs only in a fresh verify volume."
# The headless flags come from their one source, claude_headless_flags(); the check
# below catches a silent failure inside the process substitution (FP-147).
# shellcheck source=scripts/self-improvement.sh
mapfile -t HF < <(source "$SI" >/dev/null 2>&1 && claude_headless_flags)
[ "${#HF[@]}" -gt 0 ] || fail "claude_headless_flags in $SI printed nothing."
[[ " ${HF[*]} " != *" --bare "* ]] || fail "claude_headless_flags passes --bare."

trap cleanup EXIT
trap 'exit 130' INT TERM HUP
D="$(mktemp -d "$HOME/q125-verify.XXXXXX")" || fail "mktemp in $HOME failed."   # not sandbox-writable
SIG="$(mktemp -d /tmp/q125-sig.XXXXXX)" || fail "mktemp in /tmp failed."     # sandbox-writable: x.sh signals here
M="q125canary-$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n')"
plant() { printf '{"q125Canary":"%s-%s"}\n' "$M" "$1" > "$CRED.q125tmp" && chmod 600 "$CRED.q125tmp" && mv -f -- "$CRED.q125tmp" "$CRED"; }
plant 0 || fail "could not plant the canary at $CRED."
if [ -z "$(find "$WS/.claude/worktrees" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)" ]; then
  WT="$WS/.claude/worktrees/q125-probe"
  if ! { mkdir -p -- "$WS/.claude/worktrees" && git -C "$WS" worktree add -q --detach "$WT" HEAD >/dev/null 2>&1; }; then
    WT=""; fail "could not add the nested worktree the C3 checks need."
  fi
fi

# Renamer: waits for x.sh's go, then replaces the credential by rename until stop.
( for _ in $(seq 1200); do [ -e "$SIG/go" ] && break; sleep 0.5; done
  n=0; while [ -e "$SIG/go" ] && [ ! -e "$SIG/stop" ] && [ "$n" -lt 400 ]; do
    n=$((n + 1)); plant "$n" && echo "$n" > "$D/renames"; sleep 0.5; done ) &
REN_PID=$!

# --- the sandboxed half, run by Claude Code's Bash tool ---------------------------
cat > "$D/x.sh" <<'XEOF'
set -u
sig="$1" x4s="$2" cred="$HOME/.claude/.credentials.json"
t="$(mktemp -d)" || { echo "RESULT X0-tempdir FAIL (mktemp)"; exit 1; }
trap 'rm -rf "$t"' EXIT
res() { printf 'RESULT %-28s %s\n' "$1" "$2"; }
leaks() { grep -q 'q125canary-' "$@" 2>/dev/null; }
# X1: judged by content. denyRead binds /dev/null over the file, so a refused read can
# exit 0 and print nothing; a control file proves the tool would have shown content.
echo '{"q125Control":"shown"}' > "$t/control"
x1() {
  local id="$1"; shift
  "$@" "$t/control" > "$t/o" 2>&1
  if ! grep -q q125Control "$t/o"; then res "$id" "FAIL (control: $* shows no content)"; return; fi
  "$@" "$cred" > "$t/o" 2>&1
  if leaks "$t/o"; then res "$id" "FAIL (credential content read: $*)"; else res "$id" pass; fi
}
x1 X1-cat-credential cat
x1 X1-git-diff-credential git diff --no-index /dev/null
x1 X1-man-l-credential env MANPAGER=cat PAGER=cat man -l
x1 X1-date-f-credential date -f
# X2: Q-098's leak list, git drivers from repo config the agent can edit.
h="$t/h.sh"
printf '#!/bin/sh\necho ran >> "%s/ran"\ncat "%s" >> "%s/leak" 2>/dev/null\nexit 0\n' "$t" "$cred" "$t" > "$h" && chmod +x "$h"
r="$t/r"
( git init -q "$r" && cd "$r" && git config user.email q125@localhost && git config user.name q125 \
  && echo a > f && echo 'f diff=q125' > .gitattributes && git add -A && git commit -qm a && echo b > f ) >/dev/null 2>&1 \
  || echo "INFO the X2 scratch repo could not be made"
x2() {
  local id="$1"; shift
  rm -f "$t/ran" "$t/leak"
  ( cd "$r" && "$@" ) >/dev/null 2>&1
  if [ ! -s "$t/ran" ]; then res "$id" "FAIL (the driver never ran: $*)"
  elif leaks "$t/leak"; then res "$id" "FAIL (credential copied: $*)"
  else res "$id" pass; fi
}
x2 X2-diff-external git -c diff.external="$h" diff
x2 X2-textconv-log-p git -c diff.q125.textconv="$h" log -p -1
x2 X2-textconv-show git -c diff.q125.textconv="$h" show HEAD
x2 X2-fsmonitor-diff git -c core.fsmonitor="$h" diff
# X3: GitHub reachable without a prompt. In -p mode a prompt cannot be answered, so a
# reply from GitHub (a 401, or git asking for a username) is the pass.
o="$(GH_TOKEN=q125-invalid-token GH_PROMPT_DISABLED=1 GH_NO_UPDATE_NOTIFIER=1 timeout 60 gh api user 2>&1)"
case "$o" in *"HTTP 401"*) res X3-gh-api "pass (GitHub answered 401)" ;; *) res X3-gh-api "FAIL ($(printf '%s' "$o" | head -1 | cut -c1-90))" ;; esac
o="$(cd "$r" && GIT_TERMINAL_PROMPT=0 timeout 60 git -c credential.helper= push --dry-run https://github.com/git/git HEAD:refs/heads/q125-probe 2>&1)"
if printf '%s' "$o" | grep -qE 'could not read Username|terminal prompts disabled|Authentication failed|HTTP 40[13]|denied to'; then
  res X3-git-push-dry-run "pass (GitHub asked for credentials)"
else res X3-git-push-dry-run "FAIL ($(printf '%s' "$o" | head -1 | cut -c1-90))"; fi
# X4: the credential replaced by rename while this command runs (the plan's C10).
touch "$sig/go"; bad=0; end=$((SECONDS + x4s))
while [ "$SECONDS" -lt "$end" ]; do cat "$cred" > "$t/o" 2>/dev/null; leaks "$t/o" && bad=1; sleep 0.2; done
touch "$sig/stop"
[ "$bad" = 0 ] && res X4-cred-across-rename pass || res X4-cred-across-rename "FAIL (read after a rename)"
XEOF

# --- the model stub ------------------------------------------------------------
cat > "$D/stub.py" <<'PYEOF'
import http.server, json, os, sys
D, CMDS, PFX = sys.argv[1], sys.argv[2:], "toolu_q125_"
def log(s):
    with open(os.path.join(D, "stub.log"), "a") as f: f.write(s + "\n")
class H(http.server.BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def send(self, code, obj, ctype="application/json"):
        b = (obj if isinstance(obj, str) else json.dumps(obj)).encode()
        self.send_response(code); self.send_header("content-type", ctype)
        self.send_header("content-length", str(len(b))); self.end_headers(); self.wfile.write(b)
    def do_GET(self):
        log("GET " + self.path)
        self.send(200, {"data": [], "has_more": False}) if self.path.startswith("/v1/models") else self.send(404, {"type": "error", "error": {"type": "not_found_error", "message": "q125 stub"}})
    def do_POST(self):
        log("POST " + self.path)
        try: req = json.loads(self.rfile.read(int(self.headers.get("content-length") or 0)) or b"{}")
        except ValueError: req = {}
        path = self.path.split("?")[0]
        if path.endswith("/count_tokens"): return self.send(200, {"input_tokens": 1})
        if path != "/v1/messages": return self.send(404, {"type": "error", "error": {"type": "not_found_error", "message": "q125 stub"}})
        done = {}
        for m in req.get("messages", []):
            for b in (m.get("content") if isinstance(m, dict) and isinstance(m.get("content"), list) else []):
                if isinstance(b, dict) and b.get("type") == "tool_result" and str(b.get("tool_use_id", "")).startswith(PFX):
                    done[b["tool_use_id"]] = b
        for k, b in done.items():
            if not os.path.exists(os.path.join(D, k + ".json")):
                with open(os.path.join(D, k + ".json"), "w") as f: json.dump(b, f)
        bash = any(isinstance(t, dict) and t.get("name") == "Bash" for t in req.get("tools", []))
        i = len(done)
        if bash and i < len(CMDS):
            block, stop = {"type": "tool_use", "id": PFX + str(i), "name": "Bash", "input": {"command": CMDS[i], "description": "Q-125 live checks, part %d" % (i + 1), "timeout": 600000}}, "tool_use"
            log("TOOL_USE %d" % i)
        else:
            block, stop = {"type": "text", "text": "q125 stub: done" if bash else "ok"}, "end_turn"
        msg = {"id": "msg_q125_%d" % i, "type": "message", "role": "assistant", "model": req.get("model", "q125-stub"), "content": [block], "stop_reason": stop, "stop_sequence": None, "usage": {"input_tokens": 1, "output_tokens": 1}}
        if not req.get("stream"): return self.send(200, msg)
        if block["type"] == "tool_use": cb, delta = dict(block, input={}), {"type": "input_json_delta", "partial_json": json.dumps(block["input"])}
        else: cb, delta = dict(block, text=""), {"type": "text_delta", "text": block["text"]}
        ev = [("message_start", {"type": "message_start", "message": dict(msg, content=[], stop_reason=None)}),
              ("content_block_start", {"type": "content_block_start", "index": 0, "content_block": cb}),
              ("content_block_delta", {"type": "content_block_delta", "index": 0, "delta": delta}),
              ("content_block_stop", {"type": "content_block_stop", "index": 0}),
              ("message_delta", {"type": "message_delta", "delta": {"stop_reason": stop, "stop_sequence": None}, "usage": {"output_tokens": 1}}),
              ("message_stop", {"type": "message_stop"})]
        self.send(200, "".join("event: %s\ndata: %s\n\n" % (e, json.dumps(d)) for e, d in ev), "text/event-stream")
srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), H)
with open(os.path.join(D, "port.tmp"), "w") as f: f.write(str(srv.server_address[1]))
os.replace(os.path.join(D, "port.tmp"), os.path.join(D, "port"))
srv.serve_forever()
PYEOF

C1="bash $D/x.sh $SIG $X4S" C2="bash $LIVE"
python3 -I "$D/stub.py" "$D" "$C1" "$C2" &
STUB_PID=$!
for _ in $(seq 100); do [ -s "$D/port" ] && break; sleep 0.1; done
[ -s "$D/port" ] || fail "the model stub did not start."

# --- the headless run: judged by its envelope and the stub's record, not its exit code
echo "== claude -p against the stub (two sandboxed tool calls; up to 30 minutes)"
( cd "$WS" && ANTHROPIC_BASE_URL="http://127.0.0.1:$(cat "$D/port")" ANTHROPIC_API_KEY=q125-stub-not-a-key \
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 DISABLE_AUTOUPDATER=1 \
    timeout 1800 claude -p "Run the Q-125 live checks." "${HF[@]}" --output-format json --max-turns 6 \
    --allowedTools "Bash($C1)" "Bash($C2)" ) < /dev/null > "$D/envelope.json" 2> "$D/claude.err"
echo "INFO claude -p exit $? (not the verdict)"
kill "$REN_PID" 2>/dev/null; wait "$REN_PID" 2>/dev/null; REN_PID=""

res() { printf 'RESULT %-28s %s\n' "$1" "$2"; }
{
  if jq -e '.is_error == false and (.num_turns // 0) >= 3' "$D/envelope.json" >/dev/null 2>&1; then res Q0-claude-envelope pass
  else res Q0-claude-envelope "FAIL ($(head -c 200 "$D/envelope.json" "$D/claude.err" 2>/dev/null | tr '\n' ' '))"; fi
  for i in 0 1; do
    f="$D/toolu_q125_$i.json"
    if [ ! -f "$f" ]; then res "Q0-tool-call-$((i + 1))" "FAIL (no tool result reached the stub)"; continue; fi
    jq -r 'if (.content | type) == "string" then .content else ([.content[]? | .text? // empty] | join("\n")) end' "$f" > "$D/out$i" 2>/dev/null
    if jq -e '.is_error == true' "$f" >/dev/null 2>&1; then res "Q0-tool-call-$((i + 1))" "FAIL (tool error: $(head -1 "$D/out$i" | cut -c1-90))"
    else res "Q0-tool-call-$((i + 1))" pass; fi
  done
  if cat "$D"/out* 2>/dev/null | grep -qF -- "$M" || grep -qF -- "$M" "$D/envelope.json" "$D/claude.err" 2>/dev/null; then
    res X0-canary-in-output "FAIL (a tool output holds the credential's content)"
  else res X0-canary-in-output pass; fi
  n="$(cat "$D/renames" 2>/dev/null || echo 0)"
  if [ "$n" -ge 2 ]; then res X4-renamer-ran "pass ($n renames)"
  else res X4-renamer-ran "FAIL ($n renames: x.sh never signalled, or plant failed)"; fi
  cat "$D"/out* 2>/dev/null | grep -E '^(RESULT|INFO|ABORT)'
} > "$D/report"
grep -E '^(INFO|ABORT)' "$D/report"
grep '^RESULT ' "$D/report"
bad="$(awk '$1 == "RESULT" && $3 != "pass" { n++ } END { print n + 0 }' "$D/report")"
missing=()
for id in "${REQUIRED[@]}"; do awk -v id="$id" '$1 == "RESULT" && $2 == id { f = 1 } END { exit !f }' "$D/report" || missing+=("$id"); done
[ "${#missing[@]}" -eq 0 ] || echo "INFO missing RESULT ids: ${missing[*]}"
if [ "$bad" = 0 ] && [ "${#missing[@]}" -eq 0 ]; then echo "VERDICT pass"; exit 0; fi
[ -s "$D/stub.log" ] && echo "INFO stub requests: $(sort "$D/stub.log" | uniq -c | tr '\n' ';' | cut -c1-300)"
echo "VERDICT FAIL ($bad not pass, ${#missing[@]} missing)"
exit 1
