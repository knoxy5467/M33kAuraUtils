# scripts/test.ps1: Native Lua Test Runner for M33kAuraUtils
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
Set-Location $ProjectRoot

# Refresh environment path to pick up newly installed Lua
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

$luaCmd = Get-Command lua -ErrorAction SilentlyContinue
$luajitCmd = Get-Command luajit -ErrorAction SilentlyContinue

if ($luaCmd) {
    & lua scripts/run_tests.lua
    exit $LASTEXITCODE
} elseif ($luajitCmd) {
    & luajit scripts/run_tests.lua
    exit $LASTEXITCODE
} else {
    Write-Host "[ERROR] Native Lua executable ('lua' or 'luajit') was not found in PATH." -ForegroundColor Red
    Write-Host "Install Lua using: winget install DEVCOM.Lua" -ForegroundColor Yellow
    exit 1
}
