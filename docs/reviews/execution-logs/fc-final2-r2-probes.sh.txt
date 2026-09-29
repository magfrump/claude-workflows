#!/usr/bin/env bash
# Probes find_imports as committed in test/agents-gemini-sync.bats (extracted verbatim).
set -u
cd "$(dirname "$0")/../../.."
eval "$(sed -n '/^find_imports() {/,/^}/p' test/agents-gemini-sync.bats)"
T=$(mktemp -d)
probe() { printf '%b' "$2" > "$T/p.md"; out=$(find_imports "$T/p.md"); printf '%-22s %s\n' "$1" "${out:--}"; }
echo "== adversarial probes (label | finder output, '-' = no match)"
probe tab-before          '\t@./x.md\n'
probe strong              '**@x**\n'
probe em-underscore       '_@x_\n'
probe em-star             '*@x*\n'
probe strike              '~~@x~~\n'
probe snake-intraword     'snake_@x\n'
probe star-intraword      'a*@x\n'
probe link-text           '[@./x.md](http://e)\n'
probe after-link          '[a](b)@x\n'
probe blockquote-nospace  '>@x\n'
probe table-cell          '|@x|\n'
probe inline-html         '<b>@x</b>\n'
probe html-comment        '<!-- @x -->\n'
probe after-codespan      '`a`@x\n'
probe tilde-fence         '~~~\n@./in/tilde.md\n~~~\n'
probe indented-code       'para\n\n    @./in/indented.md\n'
probe nested-triple-span  'a ```@x``` b\n'
probe span-multiline      'a `b\n@x` c\n'
probe unmatched-tick      'it`s @x\n'
probe mismatched-ticks    '`x`` @y\n'
probe crlf                '@./x.md\r\nline\r\n'
probe crlf-fence          '```\r\n@./in/fence.md\r\n```\r\n'
probe fence-info-inside   '````\n```js\n@./a.md\n````\n'
probe at-slash-alone      'see @/ here\n'
probe at-at               '@@x\n'
probe at-hash             '@#x\n'
probe at-paren            '@(x)\n'
probe escaped             '\\\\@x\n'
probe nonascii            '@\xc3\xa9t\xc3\xa9\n'
probe hash-fragment       '@x.md#sec\n'
echo "== synthetic pos/neg from the bats file"
sed -n "/cat > \"\$pos\" <<'EOF'/,/^EOF/p" test/agents-gemini-sync.bats | sed '1d;$d' > "$T/pos.md"
sed -n "/cat > \"\$neg\" <<'EOF'/,/^EOF/p" test/agents-gemini-sync.bats | sed '1d;$d' > "$T/neg.md"
echo "pos lines: $(wc -l < "$T/pos.md"); matched: $(find_imports "$T/pos.md" | grep -c .)"
find_imports "$T/pos.md"
echo "neg lines: $(wc -l < "$T/neg.md") (non-fence-marker lines: $(grep -vc '^```' "$T/neg.md")); matched: $(find_imports "$T/neg.md" | grep -c .)"
echo "== real files (match counts)"
for f in AGENTS.md GEMINI.md README.md global-instructions/CLAUDE.md workflows/*.md; do printf '%s: %s\n' "$f" "$(find_imports "$f" | grep -c .)"; done
git show main:AGENTS.md > "$T/old.md"; echo "main:AGENTS.md: $(find_imports "$T/old.md" | grep -c .)"
echo "== token figure: main's imported workflow files"
tot_b=0; tot_c=0; n=0
for w in $(git show main:AGENTS.md | grep -oE '@\./workflows/[a-z-]+\.md' | sed 's|@\./||'); do
  n=$((n+1)); b=$(git show "main:$w" | wc -c); c=$(git show "main:$w" | LC_ALL=C.UTF-8 wc -m)
  tot_b=$((tot_b+b)); tot_c=$((tot_c+c))
done
echo "files: $n bytes: $tot_b chars: $tot_c chars/4: $((tot_c/4))"
rm -rf "$T"
