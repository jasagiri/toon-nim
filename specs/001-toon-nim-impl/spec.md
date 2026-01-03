# Feature Specification: TOON Format Nim Implementation

**Feature Branch**: `001-toon-nim-impl`
**Created**: 2025-12-08
**Status**: Draft
**Input**: User description: "TOON format Nim implementation with encode/decode library and CLI"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Decode TOON to Native Data (Priority: P1)

A developer wants to read TOON-formatted configuration or data files and convert them into native Nim data structures for processing in their application.

**Why this priority**: Decoding is the foundational capability. Without reading TOON data, no other functionality is useful. Most use cases start with consuming existing TOON data.

**Independent Test**: Can be fully tested by providing TOON input strings and verifying the resulting Nim objects match expected values.

**Acceptance Scenarios**:

1. **Given** a valid TOON string with primitive values, **When** the decode function is called, **Then** the correct Nim values (strings, numbers, booleans, null) are returned.
2. **Given** a valid TOON string with nested objects, **When** the decode function is called, **Then** a properly structured nested object is returned.
3. **Given** a valid TOON string with arrays (inline, list, tabular), **When** the decode function is called, **Then** the correct array with all elements is returned.
4. **Given** an invalid TOON string, **When** strict mode decoding is attempted, **Then** a descriptive error with line/position information is raised.

---

### User Story 2 - Encode Native Data to TOON (Priority: P2)

A developer wants to serialize Nim data structures into TOON format for storage, transmission, or display to users/LLMs.

**Why this priority**: Encoding enables round-trip data handling. After decoding works, encoding completes the core library functionality.

**Independent Test**: Can be fully tested by providing Nim objects and verifying the output TOON string matches expected format.

**Acceptance Scenarios**:

1. **Given** a Nim object with primitive values, **When** the encode function is called, **Then** valid TOON output with proper formatting is produced.
2. **Given** a Nim object with nested structures, **When** the encode function is called, **Then** properly indented TOON output is produced.
3. **Given** a Nim array of objects with uniform structure, **When** the encode function is called, **Then** tabular TOON format is produced for compactness.
4. **Given** strings containing special characters (quotes, colons, delimiters), **When** encoded, **Then** proper escaping/quoting is applied.

---

### User Story 3 - CLI Format Conversion (Priority: P3)

A user wants to convert between TOON and JSON formats via command line for scripting, pipeline integration, or quick data inspection.

**Why this priority**: CLI provides accessibility without writing code. Follows the constitution's CLI Interface Standard principle.

**Independent Test**: Can be fully tested by running CLI commands with sample files and verifying output matches expected format.

**Acceptance Scenarios**:

1. **Given** a TOON file, **When** the CLI is invoked with decode command, **Then** JSON output is written to stdout.
2. **Given** a JSON file, **When** the CLI is invoked with encode command, **Then** TOON output is written to stdout.
3. **Given** stdin input, **When** the CLI is invoked with appropriate flags, **Then** the converted output appears on stdout.
4. **Given** invalid input, **When** the CLI is invoked, **Then** a helpful error message appears on stderr with non-zero exit code.

---

### User Story 4 - Round-Trip Data Integrity (Priority: P4)

A developer wants assurance that data encoded to TOON and decoded back produces identical results.

**Why this priority**: Round-trip integrity is essential for data reliability but depends on both encode and decode working correctly first.

**Independent Test**: Can be tested by encoding any valid Nim object, decoding the result, and comparing to original.

**Acceptance Scenarios**:

1. **Given** any valid JSON-compatible Nim data structure, **When** encoded to TOON then decoded back, **Then** the result equals the original input.
2. **Given** edge case values (empty strings, zero, negative numbers, Unicode), **When** round-tripped, **Then** values are preserved exactly.

---

### User Story 5 - Configurable Encoding Options (Priority: P5)

A developer wants control over encoding output format (indentation, delimiters, key folding) to match project conventions or optimize for specific use cases.

**Why this priority**: Configurability is a refinement after core functionality works. Enables advanced use cases like LLM optimization.

**Independent Test**: Can be tested by encoding the same data with different options and verifying output format changes accordingly.

**Acceptance Scenarios**:

1. **Given** an object and custom indent size option, **When** encoded, **Then** output uses the specified indentation.
2. **Given** an array and specific delimiter option (comma, tab, pipe), **When** encoded, **Then** output uses the specified delimiter.
3. **Given** nested single-key objects and key folding enabled, **When** encoded, **Then** output uses dotted path notation.

---

### Edge Cases

- What happens when input contains mixed delimiters within nested structures?
- How does the system handle extremely deep nesting (100+ levels)?
- What happens when array length declaration mismatches actual element count?
- How does the system handle strings with all five escape sequences (\\, \", \n, \r, \t)?
- What happens when numbers exceed standard integer/float ranges?
- How does the system handle empty objects, empty arrays, and null at root level?
- What happens when TOON input has inconsistent indentation?

## Requirements *(mandatory)*

### Functional Requirements

**Decoding:**
- **FR-001**: Library MUST decode all TOON primitive types: strings (quoted/unquoted), numbers, booleans (true/false), and null.
- **FR-002**: Library MUST decode nested objects with proper indentation-based structure recognition.
- **FR-003**: Library MUST decode all three array forms: inline primitives, list items, and tabular objects.
- **FR-004**: Library MUST support all three delimiters: comma (default), tab, and pipe.
- **FR-005**: Library MUST correctly parse array headers with length declarations `[N]` and field specifications `{field1,field2}`.
- **FR-006**: Library MUST handle the five valid escape sequences: `\\`, `\"`, `\n`, `\r`, `\t`.
- **FR-007**: Library MUST provide strict mode (default) that errors on format violations.
- **FR-008**: Library MUST provide lenient mode that attempts best-effort parsing.
- **FR-009**: Decoder MUST report errors with line number and descriptive message.

**Encoding:**
- **FR-010**: Library MUST encode all JSON-compatible Nim types to valid TOON format.
- **FR-011**: Library MUST apply proper quoting when strings contain delimiters, colons, brackets, or control characters.
- **FR-012**: Library MUST format numbers in canonical decimal form (no exponent notation).
- **FR-013**: Library MUST produce consistent indentation (configurable, default 2 spaces).
- **FR-014**: Library MUST support tabular array encoding for uniform object arrays.
- **FR-015**: Library MUST support key folding option for collapsing single-key object chains.

**CLI:**
- **FR-016**: CLI MUST accept input from file path argument or stdin.
- **FR-017**: CLI MUST output to stdout (default) or specified file path.
- **FR-018**: CLI MUST support `--json` flag for JSON output format.
- **FR-019**: CLI MUST support `--toon` flag for TOON output format.
- **FR-020**: CLI MUST output errors to stderr with appropriate exit codes.
- **FR-021**: CLI MUST support `--help` flag showing usage information.
- **FR-022**: CLI MUST support `--version` flag showing version information.

**Validation:**
- **FR-023**: Strict mode MUST error on array count mismatches.
- **FR-024**: Strict mode MUST error on invalid indentation (non-multiples of indent size, tabs).
- **FR-025**: Strict mode MUST error on invalid escape sequences.
- **FR-026**: Strict mode MUST error on unterminated quoted strings.

### Key Entities

- **ToonValue**: Represents any TOON/JSON value - can be string, number, boolean, null, object, or array.
- **EncodeOptions**: Configuration for encoding behavior - indent size, delimiter, key folding settings.
- **DecodeOptions**: Configuration for decoding behavior - strict/lenient mode, path expansion settings.
- **ToonError**: Error information including message, line number, and position for decode failures.
- **ArrayHeader**: Parsed array declaration with length, delimiter type, and optional field names.

### Assumptions

- UTF-8 encoding is assumed for all input/output.
- Numbers follow standard JSON number format (IEEE 754 double precision range).
- Maximum nesting depth follows practical limits (1000 levels is sufficient).
- Default delimiter is comma when not specified.
- Default indent is 2 spaces when not specified.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Library passes all 349 TOON specification test fixtures from the official test suite.
- **SC-002**: Round-trip conversion (encode then decode then compare) succeeds for 100% of valid JSON structures.
- **SC-003**: Error messages include line number and are sufficient for users to locate and fix issues without external tools.
- **SC-004**: CLI processes files under 1MB in under 1 second on standard hardware.
- **SC-005**: Library can be imported and used with a single import statement.
- **SC-006**: Documentation examples compile and run without modification.
- **SC-007**: Zero runtime dependencies beyond Nim standard library.
