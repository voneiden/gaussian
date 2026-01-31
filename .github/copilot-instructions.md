# Copilot Instructions for Gaussian

## Project Overview

This is a Gleam project with Lustre (a web framework for Gleam). The project targets both Erlang and JavaScript runtimes.

## Build, Test, and Lint Commands

### Running the full test suite
```sh
gleam test
```

### Running tests for a specific target
```sh
gleam test --target erlang
gleam test --target javascript
```

### Type checking
```sh
gleam check
```

### Formatting code
```sh
gleam format src test
```

### Checking if code is formatted (CI)
```sh
gleam format --check src test
```

### Building the project
```sh
gleam build
```

### Running the development entry point
```sh
gleam dev
```

### Running the project
```sh
gleam run
```

## Architecture

- **Entry point**: `src/gaussian.gleam` - main module with the application entry point
- **Tests**: All test files go in `test/` directory and must end with `_test.gleam`
- **Test functions**: Individual test functions must end with `_test` suffix (gleeunit convention)
- **Multi-target support**: The project is configured to compile to both Erlang and JavaScript targets

## Key Conventions

### Testing with gleeunit
- Test files belong in the `test/` directory with the `_test.gleam` suffix
- Test functions must end with `_test` (e.g., `hello_world_test`)
- Use `gleeunit.main()` in the test module's main function to run tests
- Use `assert` for test assertions (e.g., `assert greeting == "Hello, Joe!"`)

### Dependencies
- The project uses Lustre for web framework capabilities
- `lustre_dev_tools` is included for development tooling
- Standard library version: `>= 0.44.0 and < 2.0.0`

### Code Style
- Always run `gleam format` before committing
- The CI pipeline checks formatting with `gleam format --check src test`

## CI/CD

The project uses GitHub Actions (`.github/workflows/test.yml`):
- Runs on: Ubuntu latest
- OTP version: 28
- Gleam version: 1.13.0
- Steps: dependency download → test → format check
