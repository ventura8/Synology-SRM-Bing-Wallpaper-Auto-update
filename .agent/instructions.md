# AI Agent Instructions

These instructions are designed to be AI-agnostic and apply to any automated coding assistant working on this project.

## 1. Quality Assurance Workflow

### Priority Order

1. **Formatting First**: Run and pass all formatter checks before linting.
Code must be consistently formatted before further quality validation.

2. **Linting Second**: Always resolve all linting errors before running tests.
Code that doesn't lint should not be tested.

3. **Testing Third**: Once formatting and linting pass, run the test suite.

4. **Coverage Verification Fourth**: Verify total coverage is at least 90%.

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
