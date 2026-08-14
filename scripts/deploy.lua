-- scripts/deploy.lua: Pure Lua distribution deployer to WoW AddOns directory
local Deployer = {}

function Deployer.LoadEnv(filePath)
    filePath = filePath or ".env"
    local envVars = {}
    local f = io.open(filePath, "r")
    if not f then return envVars end

    for line in f:lines() do
        -- Trim comments and whitespace
        local cleanLine = string.gsub(line, "#.*$", "")
        cleanLine = string.gsub(cleanLine, "^%s*(.-)%s*$", "%1")
        if cleanLine ~= "" then
            local k, v = string.match(cleanLine, "^([%w_]+)%s*=%s*(.*)$")
            if k and v then
                -- Strip surrounding quotes if present
                v = string.gsub(v, '^["\']', "")
                v = string.gsub(v, '["\']$', "")
                envVars[k] = v
            end
        end
    end
    f:close()
    return envVars
end

function Deployer.CopyFile(src, dst)
    local infile, inErr = io.open(src, "rb")
    if not infile then return false, inErr end
    local content = infile:read("*all")
    infile:close()

    local outfile, outErr = io.open(dst, "wb")
    if not outfile then return false, outErr end
    outfile:write(content)
    outfile:close()
    return true
end

function Deployer.CreateDirectory(dirPath)
    -- Normalize for Windows / OS
    local cleanPath = string.gsub(dirPath, "/", "\\")
    os.execute(string.format('if not exist "%s" mkdir "%s" >nul 2>nul', cleanPath, cleanPath))
end

function Deployer.Deploy(customPath)
    local env = Deployer.LoadEnv(".env")
    local targetBase = customPath or env["WOW_ADDONS_PATH"] or os.getenv("WOW_ADDONS_PATH")

    if not targetBase or targetBase == "" then
        print("  [DEPLOY SKIPPED] WOW_ADDONS_PATH not defined in .env or environment.")
        return true
    end

    -- Normalize target path
    targetBase = string.gsub(targetBase, "\\", "/")
    targetBase = string.gsub(targetBase, "/$", "")
    local targetAddonDir = targetBase .. "/M33kAuraUtils"

    print(string.format("  -> Target WoW AddOns Path: %s", targetAddonDir))

    -- Create target directories
    Deployer.CreateDirectory(targetAddonDir)
    Deployer.CreateDirectory(targetAddonDir .. "/Locales")
    Deployer.CreateDirectory(targetAddonDir .. "/Media")

    -- List of distribution files
    local distFiles = {
        { src = "M33kAuraUtils.toc", dst = targetAddonDir .. "/M33kAuraUtils.toc" },
        { src = "Locales/Locales.lua", dst = targetAddonDir .. "/Locales/Locales.lua" },
        { src = "Spells.lua", dst = targetAddonDir .. "/Spells.lua" },
        { src = "Database.lua", dst = targetAddonDir .. "/Database.lua" },
        { src = "Engine.lua", dst = targetAddonDir .. "/Engine.lua" },
        { src = "UI.lua", dst = targetAddonDir .. "/UI.lua" },
        { src = "Options.lua", dst = targetAddonDir .. "/Options.lua" },
        { src = "Injection.lua", dst = targetAddonDir .. "/Injection.lua" },
        { src = "Core.lua", dst = targetAddonDir .. "/Core.lua" },
        { src = "Media/logo.jpg", dst = targetAddonDir .. "/Media/logo.jpg" },
    }

    local copied = 0
    for _, file in ipairs(distFiles) do
        local ok, err = Deployer.CopyFile(file.src, file.dst)
        if ok then
            copied = copied + 1
            print(string.format("     [COPIED] %s -> %s", file.src, file.dst))
        else
            print(string.format("     [WARN] Could not copy %s: %s", file.src, tostring(err)))
        end
    end

    print(string.format("  -> Deployment Complete: %d distribution files deployed.", copied))
    return true
end

return Deployer
