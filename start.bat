@echo off
echo ========================================
echo  EdTech AI MVP - Backend Starter
echo ========================================
echo.

echo [1/3] Checking port 3000...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3000 ^| findstr LISTENING') do (
    echo Found process %%a on port 3000, killing it...
    taskkill /F /PID %%a >nul 2>&1
    timeout /t 2 /nobreak >nul
)

echo [2/3] Port 3000 is free
echo.

echo [3/3] Starting backend...
cd /d %~dp0
npm start

