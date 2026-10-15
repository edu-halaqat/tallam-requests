#!/usr/bin/env bash
set -euo pipefail
rm -rf dist .teacher-requests-source
git clone --depth 1 https://github.com/edu-halaqat/edu-halaqat.github.io.git .teacher-requests-source
mkdir -p dist
cp -a .teacher-requests-source/tallam/. dist/
python3 - <<'PY'
from pathlib import Path
p = Path('dist/admin/admin.js')
s = p.read_text(encoding='utf-8')
old = 'https://edu-halaqat.github.io/tallam/admin/'
if old not in s:
    raise SystemExit('Expected original teacher-admin redirect URL was not found; refusing to deploy')
s = s.replace('adminRedirectUrl: "' + old + '"', 'adminRedirectUrl: null')
s = s.replace('const redirectTo = CONFIG.adminRedirectUrl;', 'const redirectTo = new URL("admin/", window.location.origin + "/").href;')
p.write_text(s, encoding='utf-8')
PY
touch dist/.nojekyll
test -s dist/index.html
test -s dist/admin/index.html
test -s dist/admin/admin.js
echo "Teacher requests website ready in dist/"
