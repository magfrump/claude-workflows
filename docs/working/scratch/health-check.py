"""Health check: verify skill-trigger-guide.md is in sync with skills/."""
import re, os, glob

skill_files = {os.path.basename(f).replace('.md','') for f in glob.glob('skills/*.md')}

with open('guides/skill-trigger-guide.md') as f:
    content = f.read()
referenced = set(re.findall(r'`([a-z][-a-z]+)`', content))

missing_from_guide = skill_files - referenced
missing_from_skills = {r for r in referenced if not os.path.exists(f'skills/{r}.md')}

if missing_from_guide:
    print('MISSING from guide:', missing_from_guide)
if missing_from_skills:
    print('REFERENCED but not in skills/:', missing_from_skills)
if not missing_from_guide and not missing_from_skills:
    print('Health check passed: all', len(skill_files), 'skills accounted for, no phantom references.')
