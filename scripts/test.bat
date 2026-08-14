@echo off
REM scripts/test.bat: Run GroundAuraTracker local tests
cd /d "%~dp0\.."

where lua >nul 2>nul
if %ERRORLEVEL% equ 0 (
    lua scripts\run_tests.lua
    exit /b %ERRORLEVEL%
)

where luajit >nul 2>nul
if %ERRORLEVEL% equ 0 (
    luajit scripts\run_tests.lua
    exit /b %ERRORLEVEL%
)

where python >nul 2>nul
if %ERRORLEVEL% equ 0 (
    python scripts\run_tests.py
    exit /b %ERRORLEVEL%
)

echo [ERROR] No Lua or Python interpreter found in PATH.
exit /b 1
