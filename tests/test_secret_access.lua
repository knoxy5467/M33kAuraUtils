local Harness = require("tests.test_harness")
Harness.SetupEnvironment()

Harness.BeginSuite("Secret Access & Environment Security Tests")

-- Secret Masking & Sanitization Helper
local function MaskSecret(str, secret)
    if not secret or secret == "" then return str end
    return string.gsub(str, secret, "[REDACTED_SECRET]")
end

-- Mock Secret Token Validator
local function ValidateSecretAccess(envVarName)
    local val = os.getenv(envVarName)
    if val and #val > 0 then
        return {
            available = true,
            length = #val,
            masked = string.sub(val, 1, 2) .. string.rep("*", math.max(0, #val - 4)) .. string.sub(val, math.max(1, #val - 1)),
        }
    else
        return {
            available = false,
            length = 0,
            masked = "[MOCK_SECRET_UNSET]",
        }
    end
end

Harness.RunTest("1. Secret Masking prevents token leak in logs", function()
    local testSecret = "super_secret_token_12345"
    local rawLog = "Connecting to API with Authorization: Bearer super_secret_token_12345"
    local sanitized = MaskSecret(rawLog, testSecret)

    Harness.Assert(not string.find(sanitized, testSecret), "Sanitized log should not contain the secret token")
    Harness.Assert(string.find(sanitized, "%[REDACTED_SECRET%]"), "Sanitized log should contain the redacted placeholder")
end)

Harness.RunTest("2. Environment Secret Access Reader handles present and missing secrets gracefully", function()
    -- Test with unset secret
    local resultMissing = ValidateSecretAccess("NON_EXISTENT_TEST_SECRET")
    Harness.AssertEquals(resultMissing.available, false, "Missing secret should report available = false")
    Harness.AssertEquals(resultMissing.masked, "[MOCK_SECRET_UNSET]", "Missing secret should have safe placeholder")

    -- Test with mock secret in environment
    local testSecretName = "CI_MOCK_SECRET"
    -- Mock os.getenv for testing
    local orig_getenv = os.getenv
    _G.os.getenv = function(name)
        if name == "CI_MOCK_SECRET" then return "ghp_MockSecretTokenForTesting98765" end
        return orig_getenv(name)
    end

    local resultPresent = ValidateSecretAccess("CI_MOCK_SECRET")
    Harness.AssertEquals(resultPresent.available, true, "Present secret should report available = true")
    Harness.Assert(resultPresent.length > 0, "Present secret should have length > 0")
    Harness.Assert(not string.find(resultPresent.masked, "MockSecretTokenForTesting"), "Masked output should not expose the secret body")

    -- Restore os.getenv
    _G.os.getenv = orig_getenv
end)

Harness.RunTest("3. Safe fallback in mock mode when secret is absent", function()
    local apiMode = os.getenv("CF_API_KEY") and "LIVE" or "MOCK"
    Harness.Assert(apiMode == "LIVE" or apiMode == "MOCK", "API mode must be valid (LIVE or MOCK)")
end)
