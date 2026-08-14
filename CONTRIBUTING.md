# Contributing to M33kAuraUtils

Thank you for your interest in contributing to **M33kAuraUtils**! We welcome bug reports, feature suggestions, and code contributions.

---

## Development Setup

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/example/M33kAuraUtils.git
   cd M33kAuraUtils
   ```

2. **Prerequisites:**
   - Standard Lua 5.1, LuaJIT, or Lua 5.4 interpreter (for running local test suites and build scripts).

---

## Testing Guidelines

Before submitting any Pull Request, you **must** ensure that all local tests pass with 0 failures.

### Running Tests Locally
```bash
# Run full build and test runner
lua build.lua

# Or run the master test runner directly
lua scripts/run_tests.lua

# On Windows:
.\scripts\test.bat
# or
.\scripts\test.ps1
```

### Adding New Tests
- **Engine Tests:** Add test cases in `tests/test_engine.lua` when adding spell tracking behaviors or state machine logic.
- **Database Tests:** Add test cases in `tests/test_database.lua` when adding configuration options or default profiles (`M33kAuraUtilsDB`).
- **UI Tests:** Add test cases in `tests/test_ui.lua` when updating visual elements, frames, or positioning logic.
- **Injection Tests:** Add test cases in `tests/test_injection.lua` when extending integrations with WeakAuras or ThisWeeksAuras.
- **Security Tests:** Add test cases in `tests/test_secret_access.lua` if modifying environment variables, API keys, or secret handling.

---

## Code Style & Best Practices

- **Zero External Dependencies:** Keep the core addon lightweight without forcing external library requirements.
- **Taint Safety:** Never call protected APIs inside insecure execution paths. Always respect combat lockdown (`InCombatLockdown()`).
- **Clean Namespace:** Keep all exported tables encapsulated under the addon namespace `M33K` and global table `_G.M33kAuraUtils` (with `_G.M33K` alias).
- **Localization:** Add new user-facing strings to `Locales/Locales.lua`.

---

## Pull Request Workflow

1. Fork the repository and create a feature branch (`git checkout -b feature/my-new-feature`).
2. Implement your changes and add corresponding unit tests.
3. Run `lua build.lua` to verify all tests pass.
4. Commit your changes with clear, descriptive commit messages adhering to the micro-commit methodology.
5. Push to your branch and open a Pull Request against `main`.
6. Ensure all GitHub Actions CI checks pass.
