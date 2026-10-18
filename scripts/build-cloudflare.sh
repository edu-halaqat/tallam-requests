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

python3 - <<'PY'
from pathlib import Path
p=Path('dist/admin/admin.js')
s=p.read_text(encoding='utf-8')
s=s.replace('''    } catch (e) {
      // الاعتماد على البيانات المحلية في حال تعذر جلب الخادم التفاصيل الكاملة
    }

    const app =''','''    } catch (e) {
      detailGrid.innerHTML = '<div class="empty" style="grid-column:1/-1">تعذر تحميل التفاصيل الكاملة والمرفقات. يرجى إعادة فتح الطلب أو الضغط على تحديث. ' + escapeHtml(e?.message || "") + '</div>';
      attachmentsGrid.innerHTML = '<div class="empty">المرفقات غير متاحة حتى يكتمل تحميل تفاصيل الطلب.</div>';
      document.getElementById("detailTitle").textContent = "تعذر فتح تفاصيل الطلب";
      deleteApplicationBtn.disabled = true;
      if (whatsappRevisionBtn) whatsappRevisionBtn.disabled = true;
      currentId = null;
      return;
    }

    const app =''')
s=s.replace('''    const attachments = app.attachments || [];''','''    const attachments = Array.isArray(app.attachments) ? app.attachments : [];''')
p.write_text(s,encoding='utf-8')
p=Path('dist/admin/index.html')
s=p.read_text(encoding='utf-8')
style="""<style id="teacher-requests-compact-table">
@media(min-width:801px){
 .admin-shell{max-width:1540px}
 .applications-table{min-width:0!important;width:100%;table-layout:fixed}
 .applications-table th,.applications-table td{padding:9px 5px;font-size:.77rem;white-space:normal;overflow-wrap:anywhere;vertical-align:middle}
 .applications-table th:nth-child(1),.applications-table td:nth-child(1){width:34px}
 .applications-table th:nth-child(2),.applications-table td:nth-child(2){width:14%}
 .applications-table th:nth-child(3),.applications-table td:nth-child(3){width:20%}
 .applications-table th:nth-child(4),.applications-table td:nth-child(4){width:9%}
 .applications-table th:nth-child(5),.applications-table td:nth-child(5){width:9%}
 .applications-table th:nth-child(6),.applications-table td:nth-child(6){width:11%}
 .applications-table th:nth-child(7),.applications-table td:nth-child(7){width:14%}
 .applications-table th:nth-child(8),.applications-table td:nth-child(8){width:8%}
 .applications-table th:nth-child(9),.applications-table td:nth-child(9){display:none}
 .applications-table th:nth-child(10),.applications-table td:nth-child(10){width:61px;white-space:nowrap;text-align:center;position:sticky;left:0;background:#fff;z-index:2}
 .applications-table th:nth-child(10){background:#f3f8f7;z-index:3}
 .applications-table .row-btn{padding:6px 8px}
}
@media(max-width:800px){
 .applications-table th:last-child,.applications-table td:last-child{position:sticky;left:0;background:#fff;z-index:2}
 .applications-table th:last-child{background:#f3f8f7;z-index:3}
}
</style>"""
s=s.replace('</head>',style+'\n</head>')
p.write_text(s,encoding='utf-8')
PY
# Keep attachment cards compact even with arbitrarily long percent-encoded names.
cp cloudflare/attachment-layout.css dist/admin/attachment-layout.css
cp cloudflare/attachment-filenames.js dist/admin/attachment-filenames.js
python3 - <<'PY'
from pathlib import Path
p = Path('dist/admin/index.html')
s = p.read_text(encoding='utf-8')
assert '</head>' in s and '</body>' in s, 'Cannot safely inject attachment layout'
s = s.replace('</head>', '<link rel="stylesheet" href="attachment-layout.css?v=20261018-long-filenames-v1">\n</head>', 1)
s = s.replace('</body>', '<script defer src="attachment-filenames.js?v=20261018-long-filenames-v1"></script>\n</body>', 1)
p.write_text(s, encoding='utf-8')
PY
test -s dist/admin/attachment-layout.css
test -s dist/admin/attachment-filenames.js
touch dist/.nojekyll
test -s dist/index.html
test -s dist/admin/index.html
test -s dist/admin/admin.js
echo "Teacher requests website ready in dist/"
