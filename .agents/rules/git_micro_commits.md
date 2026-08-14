# Git Micro Commit Methodology Rule

Always adhere to the **Micro Commit Methodology** when modifying code and managing Git repositories across all projects.

## Micro Commit Guidelines

1. **Atomic & Frequent Commits**:
   - Break work down into small, logical, self-contained changes.
   - Commit as soon as a single fix, feature step, test suite addition, refactor, or configuration update is verified.
   - Never wait until the end of a multi-step task to commit everything at once.

2. **Clear & Conventional Commit Messages**:
   - Structure commit messages using conventional prefixes:
     - `feat:` New features or functionality additions.
     - `fix:` Bug fixes or error resolutions.
     - `test:` Unit test additions, test harness updates, or test runner modifications.
     - `refactor:` Code restructuring or cleanups without behavior changes.
     - `docs:` Documentation, wiki, or inline comment updates.
     - `ci:` Continuous integration workflows, packaging, and release automation.
     - `chore:` Configuration, build scripts, or repository setup.

3. **No Monolithic Commits**:
   - Never combine unrelated bug fixes, architectural updates, test suites, or configuration changes into one giant commit.

4. **Continuous Synchronization**:
   - Push commits to remote Git repositories regularly to preserve incremental history and progress tracking.
