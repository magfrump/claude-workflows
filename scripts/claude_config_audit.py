#!/usr/bin/env python3
"""
claude_config_audit.py (v3) — audit Claude Code trusted-policy files for
prompt-injection and sandbox-escape risks.

Scope principle: only TRUSTED-POLICY files matter here — skills, memories,
CLAUDE.md / AGENTS.md, settings*.json, *.mdc rules. Those are read as
INSTRUCTIONS. Ordinary source code is read as DATA; its mitigation is the
sandbox, not this scanner. Default mode restricts to policy files. Use
--all-files to scan everything (noisy; for spot checks only).

Detectors:
  ESCAPE   — sandbox/permission bypass flags, split DIRECTIVE (sets/runs it →
             HIGH) vs MENTION (names it in prose → low).
  HIDDEN   — invisible/format Unicode, EMOJI-AWARE: BOM and emoji ZWJ/variation
             selectors are ignored; bidi overrides, Tags block, supplementary
             variation selectors, and zero-width chars in text are HIGH.
  SEMANTIC — plain-language exfil/exec red flags; only run on policy files.

Skips by default: .git, node_modules, vendored/build dirs, lockfiles, minified
JS, and disabled plugin dirs (plugins/, marketplace/). Follows symlinks (with a
cycle guard) so policy dirs symlinked into ~/.claude are covered.

Exit nonzero iff any HIGH-severity finding. Usage:
    python3 claude_config_audit.py [path ...]        # policy files under roots
    python3 claude_config_audit.py --summary PATH    # aggregated counts only
    python3 claude_config_audit.py --all-files PATH  # every text file (noisy)
    python3 claude_config_audit.py --include-plugins PATH
"""
from __future__ import annotations
import argparse, os, re, sys, unicodedata
from pathlib import Path
from collections import Counter

# ---------- policy-file classification --------------------------------------
POLICY_NAMES = {"claude.md", "agents.md", "claude.local.md"}
def is_policy_file(p: Path) -> bool:
    name = p.name.lower()
    if name in POLICY_NAMES:
        return True
    if name.startswith("settings") and p.suffix == ".json":
        return True
    if p.suffix.lower() == ".mdc":            # cursor/rules
        return True
    parts = {seg.lower() for seg in p.parts}
    if ".claude" in parts and p.suffix.lower() in {".md", ".json", ".yaml", ".yml", ".toml", ".txt", ""}:
        return True
    if ("skills" in parts or "memories" in parts or "commands" in parts or "agents" in parts) \
       and p.suffix.lower() in {".md", ".txt", ""}:
        return True
    if "rule" in name:
        return True
    return False

# ---------- ESCAPE ----------------------------------------------------------
ESCAPE_ANY = re.compile(
    r"dangerouslyDisableSandbox|--no-sandbox\b|--(allow-)?dangerously-skip-permissions"
    r"|bypassPermissions|allowUnsandboxedCommands|\bIS_SANDBOX=1\b", re.I)
ESCAPE_DIRECTIVE = re.compile(
    r'"(default|permission)Mode"\s*:\s*"bypassPermissions"'      # config set
    r'|"(allowUnsandboxedCommands|dangerouslyDisableSandbox)"\s*:\s*true'
    r'|dangerouslyDisableSandbox\s*[:=]\s*true'
    r'|(claude|npx|node|vite|bash|sh|yolo)\b[^\n]*'
    r'(--(allow-)?dangerously-skip-permissions|--no-sandbox)'    # actual invocation
    r'|IS_SANDBOX=1\b', re.I)

# ---------- HIDDEN (emoji-aware) --------------------------------------------
EMOJI_RANGES = [(0x1F000,0x1FAFF),(0x2600,0x27BF),(0x2190,0x21FF),(0x2300,0x23FF),
                (0x2B00,0x2BFF),(0x1F1E6,0x1F1FF),(0xFE00,0xFE0F),(0x20D0,0x20FF),
                (0x2000,0x206F)]  # last incl general punctuation used near emoji/keycaps
def is_picto(ch: str) -> bool:
    if not ch:
        return False
    cp = ord(ch)
    if 0x1F300 <= cp <= 0x1FAFF or 0x2600 <= cp <= 0x27BF or 0x1F1E6 <= cp <= 0x1F1FF:
        return True
    if cp in (0x2764, 0x2705, 0x26A0, 0x2B50, 0x2714, 0x2757, 0x203C, 0x2049):
        return True
    return 0x2300 <= cp <= 0x23FF or 0x2B00 <= cp <= 0x2BFF

ALLOWED_CONTROL = {"\t", "\n", "\r"}
def hidden_reason(prev: str, ch: str, nxt: str):
    """Return (reason, severity) or None. severity in {'HIGH','MED'}."""
    cp = ord(ch)
    if ch in ALLOWED_CONTROL or cp == 0xFEFF:          # tab/newline/BOM: ignore
        return None
    def _ectx(c):
        return bool(c) and (unicodedata.category(c).startswith("S") or is_picto(c) or c in "\u200d\ufe0f")
    emoji_ctx = _ectx(prev) or _ectx(nxt)
    # emoji construction chars in emoji context: benign
    if 0xFE00 <= cp <= 0xFE0F:
        return None                                   # emoji/text presentation selector — benign
    if 0x2060 <= cp <= 0x2064:
        return ("invisible math/word-joiner (often LaTeX/paste cruft)", "MED")
    if cp == 0x200D:
        return None if emoji_ctx else ("zero-width joiner outside emoji context", "HIGH")
    if 0xE0000 <= cp <= 0xE007F:
        return None if emoji_ctx else ("Unicode Tags block (invisible ASCII smuggling)", "HIGH")
    if 0xE0100 <= cp <= 0xE01EF:
        return ("supplementary variation selector (stego)", "HIGH")
    if 0x202A <= cp <= 0x202E or 0x2066 <= cp <= 0x2069:
        return ("bidi override/isolate (Trojan-Source)", "HIGH")
    cat = unicodedata.category(ch)
    if cat == "Cf":
        return ("invisible format char (zero-width/joiner/mark)", "HIGH")
    if cat in ("Cc", "Co", "Cs", "Cn"):
        return (f"control/unusual char (category {cat})", "MED")
    return None

def char_name(ch): 
    try: return unicodedata.name(ch)
    except ValueError: return "UNNAMED"

# ---------- SEMANTIC (policy files only) ------------------------------------
SEMANTIC = [(re.compile(p, re.I), why) for p, why in [
    (r"ignore (all |the )?(previous|prior|above)", "instruction-override"),
    (r"disregard (all |the )?(previous|prior|above|instructions)", "instruction-override"),
    (r"\bcurl\b[^\n]*\|\s*(bash|sh|zsh)", "pipe-to-shell"),
    (r"\bwget\b[^\n]*\|\s*(bash|sh|zsh)", "pipe-to-shell"),
    (r"base64\s+(-d|--decode)", "base64 decode"),
    (r"~/\.(ssh|aws|gnupg)", "credential-dir reference"),
    (r"\b(email|send|post|upload|exfiltrat)\w*\b[^\n]{0,40}\b(to|http)", "exfil verb"),
    (r"https?://(?!(docs\.|code\.|www\.)?(claude|anthropic)\.com)", "external URL"),
]]

# ---------- traversal -------------------------------------------------------
SKIP_DIRS = {".git", "node_modules", "dist", "build", "vendor", ".venv", "venv",
             "env", "target", ".next", "out", "coverage", "__pycache__",
             ".cache", ".pytest_cache", "file-history"}
PLUGIN_DIRS = {"plugins", "marketplace"}
SKIP_FILES = {"package-lock.json", "yarn.lock", "pnpm-lock.yaml", "cargo.lock"}
TEXT_EXTS = {".md", ".txt", ".json", ".yaml", ".yml", ".toml", ".sh", ".py",
             ".js", ".ts", ".mdx", ".mdc", ""}

def is_texty(p: Path) -> bool:
    if p.name.lower() in SKIP_FILES or p.name.endswith(".min.js"):
        return False
    return p.suffix.lower() in TEXT_EXTS

def iter_targets(roots, policy_only, include_plugins):
    seen = set()
    for root in roots:
        root = Path(root).expanduser()
        if root.is_file():
            yield root; continue
        for dirpath, dirnames, files in os.walk(root, followlinks=True):
            real = os.path.realpath(dirpath)
            if real in seen:
                dirnames[:] = []; continue
            seen.add(real)
            dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS
                           and (include_plugins or d not in PLUGIN_DIRS)]
            for f in files:
                p = Path(dirpath) / f
                if p.suffix.lower() == ".jsonl":
                    continue
                if not is_texty(p):
                    continue
                if policy_only and not is_policy_file(p):
                    continue
                yield p

# ---------- scan ------------------------------------------------------------
def scan_file(p: Path, policy: bool):
    out = []
    try:
        raw = p.read_text(encoding="utf-8", errors="surrogatepass")
    except (OSError, UnicodeError):
        return out
    for ln, line in enumerate(raw.splitlines(), 1):
        for m in ESCAPE_ANY.finditer(line):
            hi = bool(ESCAPE_DIRECTIVE.search(line))
            out.append((ln, m.start()+1, "ESCAPE", "HIGH" if hi else "LOW",
                        ("DIRECTIVE" if hi else "mention") + f"  ›  {line.strip()[:90]!r}"))
        for i, ch in enumerate(line):
            r = hidden_reason(line[i-1] if i else "", ch, line[i+1] if i+1 < len(line) else "")
            if r:
                out.append((ln, i+1, "HIDDEN", r[1],
                            f"U+{ord(ch):04X} {char_name(ch)} — {r[0]}"))
        if policy:
            for rx, why in SEMANTIC:
                m = rx.search(line)
                if m:
                    out.append((ln, m.start()+1, "SEMANTIC", "LOW",
                                f"{why}  ›  {line.strip()[:90]!r}"))
    return out

TAG = {("ESCAPE","HIGH"): "\033[41m\033[97m ESCAPE! \033[0m",
       ("ESCAPE","LOW"):  "\033[2mescape·mention\033[0m",
       ("HIDDEN","HIGH"): "\033[31mHIDDEN\033[0m",
       ("HIDDEN","MED"):  "\033[33mhidden·med\033[0m",
       ("SEMANTIC","LOW"):"\033[2msemantic\033[0m"}

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("paths", nargs="*")
    ap.add_argument("--all-files", action="store_true", help="scan all text files, not just policy files")
    ap.add_argument("--include-plugins", action="store_true")
    ap.add_argument("--summary", action="store_true", help="aggregated counts only")
    args = ap.parse_args()
    roots = args.paths or [".claude", str(Path.home()/".claude"), "CLAUDE.md"]
    policy_only = not args.all_files

    cat = Counter(); sev = Counter(); per_file = Counter(); scanned = 0
    high_lines = []
    for p in iter_targets(roots, policy_only, args.include_plugins):
        scanned += 1
        fnd = scan_file(p, is_policy_file(p))
        if not fnd:
            continue
        per_file[str(p)] += len(fnd)
        for ln, col, kind, s, msg in fnd:
            cat[kind] += 1; sev[s] += 1
            if s == "HIGH":
                high_lines.append((str(p), ln, col, kind, msg))
        if not args.summary:
            print(f"\n\033[1m{p}\033[0m")
            for ln, col, kind, s, msg in sorted(fnd):
                print(f"  {ln}:{col}  [{TAG[(kind,s)]}] {msg}")

    print(f"\n{'='*60}\nscanned {scanned} files"
          f"  ({'policy-only' if policy_only else 'ALL files'})")
    print(f"by category : ESCAPE {cat['ESCAPE']}  HIDDEN {cat['HIDDEN']}  SEMANTIC {cat['SEMANTIC']}")
    print(f"by severity : HIGH {sev['HIGH']}  MED {sev['MED']}  LOW {sev['LOW']}")
    if high_lines:
        print(f"\n\033[1mHIGH-severity — review these first ({len(high_lines)}):\033[0m")
        for f, ln, col, kind, msg in high_lines[:40]:
            print(f"  {kind:7} {f}:{ln}:{col}  {msg}")
        if len(high_lines) > 40:
            print(f"  … +{len(high_lines)-40} more")
    else:
        print("\nNo HIGH-severity findings. LOW/MED are mentions & typography — spot-check only.")
    if per_file:
        print("\ntop files by finding count:")
        for f, n in per_file.most_common(8):
            print(f"  {n:5}  {f}")
    sys.exit(1 if sev["HIGH"] else 0)

if __name__ == "__main__":
    main()