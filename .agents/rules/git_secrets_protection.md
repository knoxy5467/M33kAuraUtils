# Git Secrets Scanning & Protection Rule

Always ensure that secrets, tokens, private keys, and sensitive environment variables are strictly protected and scanned before staging or committing changes with Git.

## Secret Scanning Guidelines

1. **Mandatory Secret Scanning**:
   - Always run secret detection (`git-secrets`, regex scanner, or test suite secret verification) before committing code.
   - Scan for:
     - API Keys & Tokens (`CF_API_KEY`, `WAGO_API_TOKEN`, `GITHUB_TOKEN`, OAuth secrets, Bearer tokens).
     - Private keys (`*.pem`, `*.key`, RSA/SSH keys).
     - Database passwords, authentication credentials, and connection strings.
     - Cloud credentials (AWS Access Keys, GCP Service Account keys, Azure tokens).

2. **Zero Secrets in Version Control**:
   - Never commit sensitive keys or plaintext tokens to any branch or repository.
   - Ensure all `.env`, `*.secret`, and sensitive local configuration files are listed in `.gitignore`.

3. **Pre-Commit Enforcement**:
   - Maintain pre-commit checks or automated unit test verification (`tests/test_secret_access.lua`) to guarantee that sensitive environment variables are masked and sanitized in all console outputs and logs.

4. **Remediation on Leak Detection**:
   - If a secret is detected in staged files, immediately unstage and sanitize the file before proceeding with the commit.
