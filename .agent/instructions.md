# AI Agent Instructions

These instructions are designed to be AI-agnostic and apply to any automated coding assistant working on this project.

## 1. Quality Assurance Workflow

### Priority Order
1.  **Linting First**: Always resolve all linting errors (flake8, mypy, etc.) BEFORE running tests.
    - Code that doesn't lint shouldn't be tested.
2.  **Testing Second**: Once linting passes, run the test suite.

### Efficiency
- **Single Pass**: When addressing issues, attempt to apply both lint fixes and test fixes in a single iteration/pass to minimize round-trips.

## 2. Code Coverage Standards

- **Threshold**: Maintain code coverage at **90% or higher**.
- **Badge Generation**:
    - **Always** generate the coverage badge locally after a successful test run.
    - Path: `assets/coverage.svg`.
    - Verification: Check the generated badge to ensure it says >= 90%.

## 3. Cross-Platform Compatibility

- **Mocks & Tests**:
    - Ensure all mocks are compatible with **both Windows and Linux**.
    - Avoid hardcoding platform-specific paths (e.g., using `\` or `/` manually). Always use `os.path.join`.
    - Be aware of `CRLF` (Windows) vs `LF` (Linux) line endings in file operations.
