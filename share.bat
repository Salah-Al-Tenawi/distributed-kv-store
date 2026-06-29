@echo off
cd /d "%~dp0backend"

echo Starting gateway (cluster + web UI)...
start "KV Gateway" cmd /k "npm start"

echo Waiting for the gateway to boot...
timeout /t 6 /nobreak >nul

echo Opening public tunnel... (the link appears in the box below)
echo.
"%USERPROFILE%\cloudflared.exe" tunnel --url http://localhost:8080 --protocol http2 --no-autoupdate
