-- scripts/run_tests.lua: Master Test Runner and CI Simulation
package.path = package.path .. ";./?.lua;./tests/?.lua"

print("==========================================================")
print("       GroundAuraTracker Local Build & Test Runner        ")
print("==========================================================")

local totalPassed = 0
local totalFailed = 0

-- 1. Validate TOC References
print("\n[STEP 1/3] Validating TOC File & Asset References...")
local tocFile = io.open("GroundAuraTracker.toc", "r")
if not tocFile then
    print("  [FAIL] GroundAuraTracker.toc not found!")
    os.exit(1)
else
    local tocLines = 0
    local referencedFiles = {}
    for line in tocFile:lines() do
        tocLines = tocLines + 1
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
        -- Normalize windows slashes
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
print("\n[STEP 2/3] Checking Lua Syntax Across Codebase...")
local luaFiles = {
    "Locales/Locales.lua",
    "Spells.lua",
    "Database.lua",
    "Engine.lua",
    "UI.lua",
    "Options.lua",
    "Core.lua",
    "tests/test_harness.lua",
    "tests/test_engine.lua",
    "tests/test_database.lua",
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
print("\n[STEP 3/3] Executing Unit Test Suites...")

local Harness = require("tests.test_harness")

-- Suite 1: Engine Tests
dofile("tests/test_engine.lua")

-- Suite 2: Database Tests
dofile("tests/test_database.lua")

-- Suite 3: Secret Access Tests
dofile("tests/test_secret_access.lua")

local passed, failed = Harness.GetSummary()

print("\n==========================================================")
print(string.format(" TEST RESULTS: %d Passed, %d Failed", passed, failed))
print("==========================================================")

if failed > 0 then
    print("❌ Build Status: FAILED")
    os.exit(1)
else
    print("✅ Build Status: SUCCESS - All tests and validations passed!")
    os.exit(0)
end
