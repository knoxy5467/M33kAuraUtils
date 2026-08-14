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

echo [ERROR] Lua or LuaJIT executable not found in PATH.
echo Running tests using PowerShell fallback runner...
powershell -ExecutionPolicy Bypass -File scripts\test.ps1
exit /b %ERRORLEVEL%
