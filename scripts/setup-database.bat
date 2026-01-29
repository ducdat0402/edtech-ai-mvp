@echo off
echo ========================================
echo Setup PostgreSQL Database for EdTech MVP
echo ========================================
echo.

REM Tìm psql trong các đường dẫn phổ biến
set PSQL_PATH=
if exist "C:\Program Files\PostgreSQL\18\bin\psql.exe" (
    set PSQL_PATH=C:\Program Files\PostgreSQL\18\bin\psql.exe
) else if exist "C:\Program Files\PostgreSQL\17\bin\psql.exe" (
    set PSQL_PATH=C:\Program Files\PostgreSQL\17\bin\psql.exe
) else if exist "C:\Program Files\PostgreSQL\16\bin\psql.exe" (
    set PSQL_PATH=C:\Program Files\PostgreSQL\16\bin\psql.exe
) else if exist "C:\Program Files\PostgreSQL\15\bin\psql.exe" (
    set PSQL_PATH=C:\Program Files\PostgreSQL\15\bin\psql.exe
) else if exist "C:\Program Files (x86)\PostgreSQL\18\bin\psql.exe" (
    set PSQL_PATH=C:\Program Files (x86)\PostgreSQL\18\bin\psql.exe
) else (
    echo Khong tim thay psql.exe
    echo Vui long chay thu cong bang pgAdmin hoac tim psql trong:
    echo C:\Program Files\PostgreSQL\[version]\bin\psql.exe
    pause
    exit /b 1
)

echo Tim thay psql tai: %PSQL_PATH%
echo.
echo Nhap password cho user postgres:
echo.

"%PSQL_PATH%" -U postgres -f scripts\create-database.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo Database da duoc tao thanh cong!
    echo ========================================
) else (
    echo.
    echo ========================================
    echo Co loi xay ra. Vui long kiem tra lai.
    echo ========================================
)

pause

