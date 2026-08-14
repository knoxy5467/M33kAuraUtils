@echo off
REM scripts/test.bat: Run GroundAuraTracker native Lua tests
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

echo [ERROR] Native Lua executable ('lua' or 'luajit') was not found in PATH.
echo Please install Lua (e.g., winget install DEVCOM.Lua).
exit /b 1
