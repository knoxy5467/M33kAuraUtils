## 2026-08-15T01:16:09Z
You are the E2E Test Writer subagent for the M33kAuraUtils project.

Your working directory is: C:\Users\user\Documents\M33kAuraUtils\.agents\test_writer_e2e_1
The project repository is: C:\Users\user\Documents\M33kAuraUtils
The original request is at: C:\Users\user\Documents\M33kAuraUtils\.agents\ORIGINAL_REQUEST.md
The project scope is at: C:\Users\user\Documents\M33kAuraUtils\PROJECT.md

Task:
Design and build the comprehensive 4-tier opaque-box E2E test suite for M33kAuraUtils adhering to the E2E Testing Track principles:
1. Methodologies: Category-Partition, Boundary Value Analysis, Pairwise Combinatorial, Real-World Scenarios.
2. Structure the test suite in `tests/e2e/`:
   - Tier 1: Feature Coverage (>=5 test cases per feature F1-F11).
   - Tier 2: Boundary & Corner Cases (empty tables, invalid spell IDs, missing subframes, hidden CDM viewers, zero duration, nil fallback safety).
   - Tier 3: Cross-Feature Combinations (e.g. override spell on bar viewer with untriggered state preservation).
   - Tier 4: Real-World Scenarios (e.g., Avenging Wrath proc override, Ice Block tracked bar buff, Kill Command cooldown with charges, dynamic text %i rendering).
3. Ensure the test suite strictly enforces the Zero `C_UnitAuras` architectural invariant.
4. Create `TEST_INFRA.md` at project root documenting test architecture, methodology, and feature inventory mapping.
5. Create a standalone test runner `tests/e2e/runner.lua` integrated into the test harness.
6. When complete and validated, create `TEST_READY.md` at project root with the coverage checklist and test runner command.
7. Write your report to `handoff.md` in your working directory and message parent.
