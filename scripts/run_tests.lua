-- scripts/run_tests.lua: Master Test Runner, CI Simulation, and Distribution Deployer
package.path = package.path .. ";./?.lua;./tests/?.lua;./Locales/?.lua;./scripts/?.lua"

print("==========================================================")
print("       M33kAuraUtils Local Build & Test Runner        ")
print("==========================================================")

local totalPassed = 0
local totalFailed = 0

-- 1. Validate TOC References
print("\n[STEP 1/4] Validating TOC File & Asset References...")
local tocFile = io.open("M33kAuraUtils.toc", "r")
if not tocFile then
    print("  [FAIL] M33kAuraUtils.toc not found!")
    os.exit(1)
else
    local referencedFiles = {}
    for line in tocFile:lines() do
        -- Strip comments and whitespace
        local cleanLine = string.gsub(line, "#.*$", "")
        cleanLine = string.gsub(cleanLine, "^%s*(.-)%s*$", "%1")
        if cleanLine ~= "" and not string.find(cleanLine, "^##") then
            table.insert(referencedFiles, cleanLine)
        end
    end
    tocFile:close()

    local missingFiles = 0
    for _, path in ipairs(referencedFiles) do
        local normPath = string.gsub(path, "\\", "/")
        local f = io.open(normPath, "r")
        if f then
            f:close()
            print(string.format("  [OK] Found %s", normPath))
        else
            print(string.format("  [ERROR] Missing file declared in TOC: %s", normPath))
            missingFiles = missingFiles + 1
        end
    end

    if missingFiles == 0 then
        print("  -> TOC Validation Passed: All declared files exist.")
    else
        print(string.format("  -> TOC Validation Failed: %d missing files.", missingFiles))
        os.exit(1)
    end
end

-- 2. Syntax Check All Lua Files
print("\n[STEP 2/4] Checking Lua Syntax Across Codebase...")
local luaFiles = {
    "Locales/Locales.lua",
    "Spells.lua",
    "Database.lua",
    "Engine.lua",
    "UI.lua",
    "Options.lua",
    "Injection.lua",
    "Core.lua",
    "scripts/deploy.lua",
    "tests/test_harness.lua",
    "tests/test_engine.lua",
    "tests/test_database.lua",
    "tests/test_ui.lua",
    "tests/test_injection.lua",
    "tests/test_secret_access.lua",
}

local syntaxErrors = 0
for _, filePath in ipairs(luaFiles) do
    local f, err = loadfile(filePath)
    if f then
        print(string.format("  [SYNTAX OK] %s", filePath))
    else
        print(string.format("  [SYNTAX ERROR] %s: %s", filePath, tostring(err)))
        syntaxErrors = syntaxErrors + 1
    end
end

if syntaxErrors > 0 then
    print(string.format("  -> Syntax check failed with %d error(s).", syntaxErrors))
    os.exit(1)
else
    print("  -> Lua Syntax Validation Passed.")
end

-- 3. Execute Test Suites
print("\n[STEP 3/4] Executing Unit Test Suites...")

local Harness = require("tests.test_harness")

-- Suite 1: Engine Tests
dofile("tests/test_engine.lua")

-- Suite 2: Database Tests
dofile("tests/test_database.lua")

-- Suite 3: UI & Visual Handler Tests
dofile("tests/test_ui.lua")

-- Suite 4: Cross-Addon Injection & Hook Tests
dofile("tests/test_injection.lua")

-- Suite 5: Secret Access Tests
dofile("tests/test_secret_access.lua")

local passed, failed = Harness.GetSummary()

print("\n==========================================================")
print(string.format(" TEST RESULTS: %d Passed, %d Failed", passed, failed))
print("==========================================================")

if failed > 0 then
    print("❌ Build Status: FAILED")
    os.exit(1)
end

-- 4. Deploy Distribution Files to WoW AddOns Directory
print("\n[STEP 4/4] Deploying Distribution Files to WoW AddOns...")
local Deployer = require("scripts.deploy")
Deployer.Deploy()

print("\n==========================================================")
print("✅ Build & Deploy Status: SUCCESS")
print("==========================================================")
os.exit(0)
