cd /workspace/.claude/wt-agents-md || exit 1
date -u +%FT%TZ
python3 - <<'PY'
import subprocess,re
old=subprocess.run(['git','show','main:AGENTS.md'],capture_output=True,text=True).stdout
paths=re.findall(r'@\./(workflows/[a-z-]+\.md)',old)
tb=tc=hb=hc=0
for p in paths:
    b=subprocess.run(['git','show','main:'+p],capture_output=True).stdout
    tb+=len(b); tc+=len(b.decode('utf-8'))
    h=open(p,'rb').read(); hb+=len(h); hc+=len(h.decode('utf-8'))
print(len(paths),'files; main bytes',tb,'chars',tc,'chars/4',tc/4,'bytes/4',tb/4)
print('HEAD bytes',hb,'chars',hc,'chars/4',hc/4)
PY
echo "== extract_workflows"
sed -n '195,240p' scripts/health-check.sh
echo "== callers"
grep -n 'extract_workflows' scripts/health-check.sh
echo "== CLAUDE.md-ish workflow refs in global"
grep -nE '`[a-z-]+\.md`' global-instructions/CLAUDE.md | head -5
grep -nE '\*\*[a-z-]+\.md\*\*' GEMINI.md | head -3
echo "== log-usage"
grep -n -iE 'Read|workflows|tool_name|file_path' hooks/log-usage.sh | head -30
echo "== shared headings"
grep -n '^## ' AGENTS.md; grep -n '^## \(Context Packing\|Shared Thoughts\|General Principles\)' global-instructions/CLAUDE.md
echo "== prior reports mention README/package.json"
grep -l -iE '@README\b|@package\.json|README for' docs/reviews/*agents* docs/reviews/code-fact-check-report-r*.md docs/reviews/code-fact-check-report.md 2>/dev/null
ls -t docs/reviews | head -15
