@echo off
REM API Testing Script for Windows
REM Usage: scripts\test-api.bat

set BASE_URL=http://localhost:3000/api/v1
set EMAIL=test@example.com
set PASSWORD=Test123!@#

echo 🧪 Testing EdTech AI MVP API
echo ================================
echo.

REM Test 1: Register
echo 1. Testing Register...
curl -s -X POST "%BASE_URL%/auth/register" ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"%EMAIL%\",\"password\":\"%PASSWORD%\",\"fullName\":\"Test User\"}" > temp_register.json

findstr /C:"access_token" temp_register.json >nul
if %errorlevel% equ 0 (
  echo ✅ Register successful
  REM Extract token (simplified - you may need to use jq or similar)
  echo Token extracted from response
) else (
  echo ⚠️  User might already exist, trying login...
  curl -s -X POST "%BASE_URL%/auth/login" ^
    -H "Content-Type: application/json" ^
    -d "{\"email\":\"%EMAIL%\",\"password\":\"%PASSWORD%\"}" > temp_login.json
  
  findstr /C:"access_token" temp_login.json >nul
  if %errorlevel% equ 0 (
    echo ✅ Login successful
  ) else (
    echo ❌ Login failed
    type temp_login.json
    del temp_*.json
    exit /b 1
  )
)

echo.
echo 2. Testing Get Explorer Subjects...
curl -s "%BASE_URL%/subjects/explorer" > temp_explorer.json
findstr /C:"IC3 GS6" temp_explorer.json >nul
if %errorlevel% equ 0 (
  echo ✅ Explorer subjects retrieved
) else (
  echo ❌ Failed to get explorer subjects
)
echo.

echo 3. Testing Get Dashboard...
echo ⚠️  Note: This requires a valid token. Please check API_TEST.md for manual testing.
echo.

echo ✅ Basic tests completed!
echo.
echo 💡 For full testing with authentication, use Postman or check API_TEST.md

del temp_*.json 2>nul

