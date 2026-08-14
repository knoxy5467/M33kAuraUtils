# scripts/test.ps1: PowerShell Test Runner
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
Set-Location $ProjectRoot

# Check if lua / luajit or python with lupa is available
$luaCmd = Get-Command lua -ErrorAction SilentlyContinue
$luajitCmd = Get-Command luajit -ErrorAction SilentlyContinue
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue

if ($luaCmd) {
    & lua scripts/run_tests.lua
    exit $LASTEXITCODE
} elseif ($luajitCmd) {
    & luajit scripts/run_tests.lua
    exit $LASTEXITCODE
} elseif ($pythonCmd) {
    & python scripts/run_tests.py
    exit $LASTEXITCODE
} else {
    Write-Host "[ERROR] Neither 'lua', 'luajit', nor 'python' was found on PATH." -ForegroundColor Red
    exit 1
}
