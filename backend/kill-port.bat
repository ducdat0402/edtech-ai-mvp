@echo off
echo Killing process on port 3000...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3000 ^| findstr LISTENING') do (
    echo Killing process %%a
    taskkill /PID %%a /F
)
echo Done!
timeout /t 2 /nobreak >nul

