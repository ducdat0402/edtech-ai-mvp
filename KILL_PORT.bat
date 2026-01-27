@echo off
echo Killing process on port 3000...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3000 ^| findstr LISTENING') do (
    echo Found process %%a
    taskkill /F /PID %%a
    echo Process killed!
)
timeout /t 2 /nobreak >nul
echo Starting backend...
cd /d %~dp0
npm start

