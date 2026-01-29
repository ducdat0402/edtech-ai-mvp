@echo off
REM Test Placement Test và Roadmap Generation for Windows
REM Usage: scripts\test-placement-roadmap.bat

set BASE_URL=http://localhost:3000/api/v1
set EMAIL=test@example.com
set PASSWORD=Test123!@#

echo 🧪 Testing Placement Test ^& Roadmap Generation
echo ================================================
echo.

echo Step 1: Login...
curl -s -X POST "%BASE_URL%/auth/login" ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"%EMAIL%\",\"password\":\"%PASSWORD%\"}" > temp_login.json

findstr /C:"access_token" temp_login.json >nul
if %errorlevel% neq 0 (
  echo ⚠️  Login failed. Creating new user...
  curl -s -X POST "%BASE_URL%/auth/register" ^
    -H "Content-Type: application/json" ^
    -d "{\"email\":\"%EMAIL%\",\"password\":\"%PASSWORD%\",\"fullName\":\"Test User\"}" > temp_register.json
  findstr /C:"access_token" temp_register.json >nul
  if %errorlevel% neq 0 (
    echo ❌ Registration failed
    type temp_register.json
    del temp_*.json
    exit /b 1
  )
  echo ✅ User registered
) else (
  echo ✅ Login successful
)

echo.
echo Step 2: Get Explorer Subject...
curl -s "%BASE_URL%/subjects/explorer" > temp_subjects.json
findstr /C:"id" temp_subjects.json >nul
if %errorlevel% neq 0 (
  echo ❌ No subjects found. Run seed first!
  del temp_*.json
  exit /b 1
)
echo ✅ Found subjects

echo.
echo Step 3: Start Placement Test...
echo ⚠️  Note: This requires manual testing with Postman or API_TEST.md
echo    - POST %BASE_URL%/test/start
echo    - GET %BASE_URL%/test/current
echo    - POST %BASE_URL%/test/submit
echo    - GET %BASE_URL%/test/result/:testId

echo.
echo Step 4: Generate Roadmap...
echo ⚠️  Note: This requires manual testing with Postman or API_TEST.md
echo    - POST %BASE_URL%/roadmap/generate
echo    - GET %BASE_URL%/roadmap/:roadmapId/today

echo.
echo 💡 For full testing, use Postman or check API_TEST.md
echo    Or use the bash script: scripts\test-placement-roadmap.sh (if using Git Bash)

del temp_*.json 2>nul

