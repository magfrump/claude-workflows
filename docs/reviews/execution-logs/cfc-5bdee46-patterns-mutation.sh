#!/usr/bin/env bash
# Mutation check of test/skills/arithmetic-eval-after-denial-patterns.bats:
# each mutation of the patterns file or helpers should make at least one test fail.
S=$(mktemp -d)
mk(){ rm -rf "$S/w"; mkdir -p "$S/w"; cp /workspace/test/skills/arithmetic-eval-after-denial-patterns.bats /workspace/test/skills/eval-helpers.bash "$S/w/"; cp -R /workspace/test/skills/arithmetic-eval "$S/w/"; }
res(){ local name="$1"; out=$(bats "$S/w/arithmetic-eval-after-denial-patterns.bats" 2>&1); rc=$?; printf '%-60s bats rc=%s failing: %s\n' "$name" "$rc" "$(echo "$out" | grep '^not ok' | sed 's/not ok //' | tr '\n' ';')"; }
P=arithmetic-eval/after-denial-patterns.bash
mk; res "M0 unmutated"
mk; python3 - "$S/w/$P" <<'PY'
import sys;p=sys.argv[1];s=open(p).read();s=s.replace("VERDICT_RE='","VERDICT_RE='correct|",1);open(p,'w').write(s)
PY
res "M1 VERDICT_RE also matches bare 'correct' (the hedge)"
mk; python3 - "$S/w/$P" <<'PY'
import sys;p=sys.argv[1];s=open(p).read();s=s.replace("|unverified|not (been )?verified","|not (been )?verified",1);open(p,'w').write(s)
PY
res "M2 NOT_VERIFIED_RE drops 'unverified'"
mk; python3 - "$S/w/$P" <<'PY'
import sys;p=sys.argv[1];s=open(p).read();s=s.replace("NOT_VERIFIED_RE='","NOT_VERIFIED_RE='.|",1);open(p,'w').write(s)
PY
res "M3 NOT_VERIFIED_RE matches everything"
mk; python3 - "$S/w/$P" <<'PY'
import sys;p=sys.argv[1];s=open(p).read();s=s.replace("""FIGURE_RE["tc-ae1-inference-tokens-tenfold.md"]='(^|[^0-9.])1[.,]90?""","""FIGURE_RE["tc-ae1-inference-tokens-tenfold.md"]='1[.,]90?""",1);open(p,'w').write(s)
PY
res "M4 ae1 FIGURE_RE loses its left anchor"
mk; python3 - "$S/w/$P" <<'PY'
import sys;p=sys.argv[1];s=open(p).read();s=s.replace("""'(^|[^0-9.])29(""","""'29(""",1);open(p,'w').write(s)
PY
res "M5 ae2 FIGURE_RE loses its left anchor"
mk; python3 - "$S/w/$P" <<'PY'
import sys;p=sys.argv[1];s=open(p).read();s=s.replace("""'(^|[^0-9.])42(""","""'42(""",1);open(p,'w').write(s)
PY
res "M6 ae3 FIGURE_RE loses its left anchor"
mk; python3 - "$S/w/$P" <<'PY'
import sys;p=sys.argv[1];s=open(p).read();s=s.replace("|✓|✅","|✅",1);open(p,'w').write(s)
PY
res "M7 VERDICT_RE drops the check mark"
mk; python3 - "$S/w/eval-helpers.bash" <<'PY'
import sys;p=sys.argv[1];s=open(p).read();s=s.replace('''  if ! echo "$REPORT_CONTENT" | grep -qiE "$pattern"; then''','''  if false; then''',1);open(p,'w').write(s)
PY
res "M8 assert_report_matches can never fail"
mk; python3 - "$S/w/eval-helpers.bash" <<'PY'
import sys;p=sys.argv[1];s=open(p).read();s=s.replace('''  hits=$(echo "$REPORT_CONTENT" | grep -iE "$pattern" || true)''','''  hits=""''',1);open(p,'w').write(s)
PY
res "M9 assert_report_not_matches can never fail"
mk; python3 - "$S/w/$P" <<'PY'
import sys;p=sys.argv[1];s=open(p).read();s=s.replace("""FIGURE_RE["tc-ae3-marathon-km-wrong.md"]=""","""FIGURE_RE["tc-ae3-marathon-km-wrongX.md"]=""",1);open(p,'w').write(s)
PY
res "M10 ae3 FIGURE_RE key misspelled (empty pattern used)"
rm -rf "$S"
