@echo off
REM ============================================================
REM share.bat - يشغّل المشروع ويعطيك رابطاً عاماً عبر Cloudflare Tunnel
REM ============================================================
REM 1) يفتح البوّابة (العنقود + الواجهة) في نافذة منفصلة على المنفذ 8080
REM 2) يشغّل النفق ويطبع الرابط العام (https://xxx.trycloudflare.com)
REM    أرسل هذا الرابط للأستاذ. أبقِ هذه النافذة مفتوحة أثناء التجربة.
REM ============================================================

cd /d "%~dp0backend"

echo [1/2] تشغيل البوابة (العنقود + الواجهة)...
start "KV Gateway" cmd /k "npm start"

echo بانتظار اقلاع البوابة...
timeout /t 6 /nobreak >nul

echo [2/2] فتح النفق العام...
echo     ابحث عن الرابط داخل الصندوق ادناه: https://xxxx.trycloudflare.com
echo.
REM --protocol http2 يتجنب اخطاء QUIC/UDP على الشبكات التي تحجبها
"%USERPROFILE%\cloudflared.exe" tunnel --url http://localhost:8080 --protocol http2 --no-autoupdate
