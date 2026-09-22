import importlib.util, os, sys, json
spec = importlib.util.spec_from_file_location("g", "/workspace/hooks/guard-trusted-writes.py")
g = importlib.util.module_from_spec(spec); spec.loader.exec_module(g)
print("HOME", g.HOME, "GLOBAL_DIRS", g.GLOBAL_DIRS)
H = str(g.HOME)
F = "CLAUDE" + ".md"
cmds = [
 'echo x > "$HOME"/F', "echo x > '$HOME'/F", 'echo x > ~//F', 'echo x > ~/./F',
 'echo x > $HOME/.claude/../F', 'echo x > ${HOME:-}/F', 'echo x > ${HOME}/F',
 'echo x > $HOME/F', 'echo x > ~/F', 'echo x > HH/F', 'echo x > HH//F',
 'echo x > HH/./F', 'echo x > ~/claude.md', 'echo x > F', 'cd ~ && echo x > F',
 'echo x > $HOME/x/../F', 'echo x > "${HOME}/F"', 'echo x > ~"/F"',
 'echo x > ~/"F"', 'echo x > $HOME/CLAUDE.m[d]', 'echo x > $HOME/CLAUDE.m?', 'echo x > $HOME/CLAUDE*',
 'echo x > ~root/F', 'echo x > "$HOME/F"', "echo x > $HOME/''F",
 'echo x > /home/../home/node/F', 'echo x > global-instructions/F', 'echo x > ./global-instructions//F',
 'echo x > global-instructions/./F', 'echo x > .claude/settings.json', 'echo x > .claude//settings.json',
 'echo x > .claude/./hooks/a', 'echo x > $HOME/.claude/F', 'echo x > ~/.claude//F',
 'echo x > ~/.claude/./F', 'echo x > $CLAUDE_CONFIG_DIR/F', 'echo x > $CLAUDE_CONFIG_DIR/settings.json',
 'echo x > $CLAUDE_CONFIG_DIR/hooks/a', 'D=~; echo x > $D/F', 'echo x > ~/.claude/Hooks/a',
 'echo x > "$HOME/.claude"/hooks/a', 'echo x > ~/.claude/"hooks"/a', 'echo x > ~/.claude/hook\\s/a',
 'echo x > $HOME/Claude.md', 'echo x > ~/.claude/CLAUDE.local.md', 'git commit -m "edit F" > /dev/null',
]
for c in cmds:
    c = c.replace("HH", H).replace("/F", "/" + F).replace(" F", " " + F).replace('"F"', '"' + F + '"').replace("''F", "''" + F)
    print(repr(c), "->", g.bash_targets(c))
print("--- file tools")
for fp in ["~/.claude/hooks/x", "~/.claude/./hooks/x", "~/.claude//settings.json", "~/.claude/settings.local.json",
           "~/.claude/x/../settings.json", "~/" + F, "~//" + F, "~/./" + F, "~/.claude/../" + F,
           "~/.claude/" + F, "~/.claude/Hooks/x", "~/.claude/SETTINGS.json", "~/.claude/hooks",
           "~/.claude/sub/settings.json", "~/.claude/skills/x/SKILL.md", "/workspace/.claude/settings.json",
           "/workspace/.claude/hooks/x.py", "/workspace/" + F, "relative/.claude/hooks/x", ".claude/hooks/x",
           "~/.claude", "~/.claude/", "~/.claude/managed-settings.json", "/etc/claude-code/managed-settings.json"]:
    print(fp, "->", g.classify_path(fp))
