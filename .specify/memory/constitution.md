<!--
SYNC IMPACT REPORT
==================
Version change: 0.0.0 → 0.0.1
Bump rationale: Initial draft of constitution (pre-release: 0.0.x series)

Modified principles: N/A (initial creation)
Added sections:
  - 7 Core Principles (I-VII)
  - Technology Constraints section
  - Development Workflow section
  - Governance section

Removed sections: N/A (initial creation)

Templates validation:
  ✅ .specify/templates/plan-template.md - Constitution Check section present
  ✅ .specify/templates/spec-template.md - Aligns with user story requirements
  ✅ .specify/templates/tasks-template.md - TDD workflow supported

Follow-up TODOs: None
-->

# Toon-Nim Constitution

## Core Principles

### I. Library-First Architecture

All functionality MUST be implemented as standalone library modules before CLI integration.
Libraries MUST be self-contained, independently testable, and well-documented.
Each library MUST have a clear, single purpose—no organizational-only modules.

**Rationale**: Ensures reusability, testability, and clean separation of concerns.

### II. CLI Interface Standard

Every library MUST expose its functionality via CLI commands.
The CLI MUST follow the text I/O protocol: stdin/args → stdout, errors → stderr.
All commands MUST support both JSON and human-readable output formats via flags.

**Rationale**: Enables composability with Unix tools, scripting, and automated pipelines.

### III. Test-Driven Development (NON-NEGOTIABLE)

TDD is mandatory for all code changes. The workflow MUST be:
1. Write test(s) that define expected behavior
2. Verify test(s) fail (Red phase)
3. Implement minimum code to pass (Green phase)
4. Refactor while keeping tests green (Refactor phase)

No implementation code MUST be written without a failing test first.

**Rationale**: Prevents regressions, ensures design quality, and provides living documentation.

### IV. Integration Testing

Integration tests MUST be written for:
- New library contract boundaries
- Changes to existing contracts
- Inter-module communication
- Shared data schemas and types

Unit tests alone are insufficient for validating system behavior.

**Rationale**: Catches integration failures that unit tests miss.

### V. Observability

All modules MUST implement structured logging with configurable verbosity levels.
Text I/O ensures debuggability—logs MUST be human-readable by default.
Error messages MUST include context sufficient for debugging without source access.

**Rationale**: Production issues require clear visibility into system behavior.

### VI. Versioning and Breaking Changes

Version format MUST follow MAJOR.MINOR.PATCH (SemVer).
Breaking changes to public APIs MUST:
- Increment MAJOR version
- Be documented in CHANGELOG
- Provide migration guidance

Deprecation MUST precede removal by at least one MINOR release.

**Rationale**: Downstream consumers depend on predictable compatibility.

### VII. Simplicity

Start with the simplest solution that works. YAGNI (You Aren't Gonna Need It) applies.
Complexity MUST be justified in writing before introduction.
Prefer composition over inheritance; prefer data over abstraction.

**Rationale**: Unnecessary complexity compounds maintenance burden.

## Technology Constraints

**Language**: Nim (latest stable release)
**Build System**: Nimble
**Testing Framework**: Nim's built-in `unittest` or `testament`
**CLI Framework**: Standard library `parseopt` or `argparse` package
**Output Formats**: JSON via `std/json`, human-readable via structured print

All dependencies MUST be pinned to specific versions in `.nimble` file.
External dependencies MUST be justified—prefer standard library when adequate.

## Development Workflow

### Code Review Requirements

All changes MUST be reviewed before merge. Reviews MUST verify:
- Compliance with TDD (tests written first)
- Adherence to library-first architecture
- CLI commands follow text I/O protocol
- Adequate test coverage for the change scope

### Quality Gates

Before merge:
1. All tests MUST pass
2. No compiler warnings (treat warnings as errors)
3. Code MUST be formatted with `nimpretty` or equivalent
4. Documentation updated for public API changes

### Branch Strategy

Feature branches MUST follow pattern: `###-feature-name`
Main branch MUST always be in a deployable state.
Direct commits to main are prohibited.

## Governance

This constitution supersedes all other development practices and guidelines.
All pull requests and code reviews MUST verify compliance with these principles.

### Amendment Process

1. Propose amendment with rationale in writing
2. Discuss impact on existing code and workflows
3. Obtain approval from project maintainers
4. Document migration plan if breaking existing code
5. Update constitution version per SemVer rules

### Version Policy

- MAJOR: Principle removal, redefinition, or backward-incompatible governance change
- MINOR: New principle added or existing principle materially expanded
- PATCH: Clarifications, wording improvements, non-semantic refinements

### Compliance Review

Quarterly reviews SHOULD assess:
- Adherence to TDD across recent changes
- Library architecture health
- Test coverage trends
- Breaking change management

**Version**: 0.0.1 | **Ratified**: 2025-12-08 | **Last Amended**: 2025-12-08
