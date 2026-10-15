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
cp cloudflare/reset-password.html dist/reset-password.html
python3 - <<'PY'
from pathlib import Path
p=Path('dist/admin/admin.js')
s=p.read_text(encoding='utf-8')
needle='    magicLinkBtn.insertAdjacentElement("afterend", help);'
assert needle in s, 'Cannot locate login enhancements'
addition="""    const recoveryBtn = document.createElement("button");
    recoveryBtn.type = "button";
    recoveryBtn.className = "btn btn-secondary";
    recoveryBtn.style.width = "100%";
    recoveryBtn.style.marginTop = "8px";
    recoveryBtn.textContent = "نسيت كلمة المرور؟";
    help.insertAdjacentElement("afterend", recoveryBtn);
    recoveryBtn.addEventListener("click", async () => {
      const email = loginEmail.value.trim();
      if (!email || !loginEmail.checkValidity()) {
        message(loginMessage, "أدخل البريد الإلكتروني الصحيح أولًا."); return;
      }
      recoveryBtn.disabled = true;
      try {
        const redirectTo = new URL("reset-password.html", window.location.origin + "/").href;
        const { error } = await client.auth.resetPasswordForEmail(email, { redirectTo });
        if (error) throw error;
        message(loginMessage, "إذا كان البريد مسجلًا فستصلك رسالة لاستعادة كلمة المرور. افتح الرابط من الرسالة.", "success");
      } catch (error) {
        const limited = /rate limit/i.test(error?.message || "");
        message(loginMessage, limited ? "تم تجاوز حد إرسال الرسائل. انتظر ثم أعد المحاولة." : (error?.message || "تعذر إرسال رابط الاستعادة."));
      } finally { recoveryBtn.disabled = false; }
    });"""
s=s.replace(needle,needle+'\n'+addition)
p.write_text(s,encoding='utf-8')
PY
touch dist/.nojekyll
test -s dist/index.html
test -s dist/admin/index.html
test -s dist/admin/admin.js
echo "Teacher requests website ready in dist/"
