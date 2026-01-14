# Contributing to Nano

First off, thank you for considering contributing to Nano! Whether you're a human developer or an AI assistant, your help is appreciated. This document will guide you through the process.

## Core Philosophy

Nano is designed to be **minimalist**, **atomic**, and **testable**. Every contribution should align with these principles. For a deep dive into the architecture and coding patterns, please review the [Nano AI Guide](NANO_GUIDE.md).

## Project Structure

Here's a brief overview of the key directories in this repository:

- `lib/`: The core Nano library source code.
- `example/`: Example applications demonstrating how to use Nano. Each is a self-contained Flutter project.
- `packages/`: Supporting packages for the Nano ecosystem, such as `nano_lints`.
- `test/`: Unit and widget tests for the core library.
- `.agent/`: Contains detailed instructions specifically for AI agents working with this codebase.

## Getting Started

1.  **Fork and Clone:** Fork the repository and clone it to your local machine.
2.  **Install Dependencies:** Nano is a multi-package repository. To ensure all dependencies are up to date, run `flutter pub get` in the root directory, as well as in each sub-project within the `example/` and `packages/` directories.

    A simple script to do this is:
    ```bash
    flutter pub get
    for d in example/*/; do (cd "$d" && flutter pub get); done
    for d in packages/*/; do (cd "$d" && flutter pub get); done
    ```

## Development Workflow

To ensure code quality and consistency, please follow this workflow.

### 1. Run the Linter

Before committing any changes, run the analyzer to check for linting errors and warnings. The project uses a combination of `flutter_lints` and custom lints from the `nano_lints` package.

```bash
flutter analyze
```

### 2. Run Tests

All tests must pass before a contribution can be merged. This includes tests for the core library and any example apps.

```bash
# Run tests for the core library
flutter test

# Run tests for all example projects
for d in example/*/; do (cd "$d" && [ -d "test" ] && flutter test); done
```

### 3. Make Your Changes

Adhere to the coding patterns and best practices outlined in the [Nano AI Guide](NANO_GUIDE.md) and the AI instructions in `.agent/instructions.md`.

## AI and Automation

This repository is designed to be AI-friendly. For explicit instructions on code generation, mandatory patterns, and common mistakes to avoid, please refer to the **[AI Agent Instructions](./.agent/instructions.md)**. That document is the source of truth for generating idiomatic Nano code.
