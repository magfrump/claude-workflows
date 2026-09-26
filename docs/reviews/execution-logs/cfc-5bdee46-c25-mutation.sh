#!/usr/bin/env bash
# C25 mutation check: hard-code mode1_equiv's checker / SKILL.md path back to arithmetic-eval
S=$(mktemp -d)
mk(){ rm -rf "$S/w"; mkdir -p "$S/w/test"; cp -R /workspace/test/skills "$S/w/test/"; mkdir -p "$S/w/skills"; cp -R /workspace/skills/arithmetic-eval "$S/w/skills/"; }
res(){ out=$(bats -f "mode1_equiv runs the fixture's own skill's checker|mode1_equiv resolves by skill" "$S/w/test/skills/mode1-equiv.bats" 2>&1); printf '%-62s rc=%s %s\n' "$1" "$?" "$(echo "$out" | grep -E '^(ok|not ok)' | tr '\n' ';')"; }
E=test/skills/eval-helpers.bash
mk; res "M0 unmutated"
mk; sed -i 's|checker="${BATS_TEST_DIRNAME}/${skill}/mode1-equiv.py"|checker="${BATS_TEST_DIRNAME}/arithmetic-eval/mode1-equiv.py"|' "$S/w/$E"; grep -c 'arithmetic-eval/mode1-equiv.py"' "$S/w/$E" >/dev/null && res "M1 checker path hard-coded (relative)"
mk; sed -i "s|checker=\"\${BATS_TEST_DIRNAME}/\${skill}/mode1-equiv.py\"|checker=\"$S/w/test/skills/arithmetic-eval/mode1-equiv.py\"|" "$S/w/$E"; res "M2 checker path hard-coded (absolute)"
mk; sed -i 's|skills/${skill}/SKILL.md|skills/arithmetic-eval/SKILL.md|' "$S/w/$E"; res "M3 SKILL.md path hard-coded"
rm -rf "$S"
