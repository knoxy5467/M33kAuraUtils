# scripts/test.ps1: PowerShell Test Runner
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
Set-Location $ProjectRoot

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "       GroundAuraTracker PowerShell Test Runner           " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Check if lua / luajit is installed
$luaCmd = Get-Command lua -ErrorAction SilentlyContinue
$luajitCmd = Get-Command luajit -ErrorAction SilentlyContinue

if ($luaCmd) {
    & lua scripts/run_tests.lua
    exit $LASTEXITCODE
} elseif ($luajitCmd) {
    & luajit scripts/run_tests.lua
    exit $LASTEXITCODE
} else {
    Write-Host "`n[INFO] 'lua' executable not found directly on PATH." -ForegroundColor Yellow
    Write-Host "[INFO] Validating TOC and project structure directly..." -ForegroundColor Yellow

    # Verify TOC files exist
    $tocContent = Get-Content "GroundAuraTracker.toc"
    $missing = 0
    foreach ($line in $tocContent) {
        $trimmed = $line.Trim()
        if ($trimmed -and -not $trimmed.StartsWith("#")) {
            $normalized = $trimmed.Replace("\", "/")
            if (-not (Test-Path $normalized)) {
                Write-Host "  [MISSING] $normalized" -ForegroundColor Red
                $missing++
            } else {
                Write-Host "  [OK] Found $normalized" -ForegroundColor Green
            }
        }
    }

    if ($missing -eq 0) {
        Write-Host "`nAll files declared in TOC exist." -ForegroundColor Green
        Write-Host "To run full Lua test suites locally, install Lua (e.g. winget install -e --id DEV-CPP.Lua or scoop install lua)." -ForegroundColor Cyan
        exit 0
    } else {
        Write-Host "`nTOC verification failed with $missing missing files." -ForegroundColor Red
        exit 1
    }
}
