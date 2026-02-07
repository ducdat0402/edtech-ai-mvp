@echo off
echo Stopping all Node.js processes...
taskkill /F /IM node.exe 2>nul
taskkill /F /IM nodemon.exe 2>nul
timeout /t 2 /nobreak >nul
echo Done. Port 3000 should be free now.

