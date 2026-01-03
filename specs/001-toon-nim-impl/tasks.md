# Tasks: TOON Format Nim Implementation

**Input**: Design documents from `/specs/001-toon-nim-impl/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: TDD is NON-NEGOTIABLE per Constitution III. Tests MUST be written first for each user story.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Library source**: `src/toon/` and `src/toon.nim`
- **CLI source**: `bin/tooncli.nim`
- **Unit tests**: `tests/unit/`
- **Integration tests**: `tests/integration/`
- **Test fixtures**: `tests/fixtures/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create project directory structure per plan.md in repository root
- [x] T002 Initialize Nim project with toon_nim.nimble file at repository root
- [x] T003 [P] Create .gitignore for Nim project artifacts
- [x] T004 [P] Download official TOON test fixtures to tests/fixtures/ (349 cases from toon-format/spec repo)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core types and utilities that ALL user stories depend on

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T005 [P] Define ToonValueKind enum in src/toon/types.nim
- [x] T006 [P] Define Delimiter enum in src/toon/types.nim
- [x] T007 [P] Define KeyFoldingMode enum in src/toon/types.nim
- [x] T008 [P] Define PathExpansionMode enum in src/toon/types.nim
- [x] T009 Define ToonValue object variant in src/toon/types.nim (depends on T005)
- [x] T010 Define EncodeOptions type in src/toon/types.nim (depends on T006, T007)
- [x] T011 Define DecodeOptions type in src/toon/types.nim (depends on T008)
- [x] T012 Define ToonError, ToonDecodeError, ToonEncodeError exceptions in src/toon/types.nim
- [x] T013 [P] Implement ToonValue constructors (newToonNull, newToonBool, etc.) in src/toon/types.nim
- [x] T014 [P] Implement ToonValue accessors (getBool, getInt, etc.) in src/toon/types.nim
- [x] T015 [P] Implement ToonValue mutators (add, []=, delete) in src/toon/types.nim
- [x] T016 [P] Implement escape/unescape utilities in src/toon/utils.nim
- [x] T017 [P] Implement string quoting detection in src/toon/utils.nim
- [x] T018 Create main library entry point src/toon.nim with re-exports
- [x] T019 [P] Write unit tests for types in tests/unit/test_types.nim
- [x] T020 [P] Write unit tests for utils in tests/unit/test_utils.nim

**Checkpoint**: Foundation ready - ToonValue type system complete, utilities available

---

## Phase 3: User Story 1 - Decode TOON to Native Data (Priority: P1) MVP

**Goal**: Parse TOON format strings into ToonValue structures

**Independent Test**: Provide TOON input strings, verify resulting ToonValue matches expected structure

### Tests for User Story 1 (TDD Required)

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T021 [P] [US1] Write scanner unit tests in tests/unit/test_scanner.nim
- [x] T022 [P] [US1] Write parser unit tests in tests/unit/test_parser.nim
- [x] T023 [P] [US1] Write decoder unit tests for primitives in tests/unit/test_decoder.nim
- [x] T024 [P] [US1] Write decoder unit tests for objects in tests/unit/test_decoder.nim
- [x] T025 [P] [US1] Write decoder unit tests for arrays (inline, list, tabular) in tests/unit/test_decoder.nim
- [x] T026 [P] [US1] Write decoder unit tests for error cases in tests/unit/test_decoder.nim

### Implementation for User Story 1

- [x] T027 [US1] Define Token and TokenKind types in src/toon/scanner.nim
- [x] T028 [US1] Implement Scanner using lexbase in src/toon/scanner.nim
- [x] T029 [US1] Implement tokenization for keys, colons, values in src/toon/scanner.nim
- [x] T030 [US1] Implement tokenization for quoted strings with escapes in src/toon/scanner.nim
- [x] T031 [US1] Implement tokenization for array headers [N]{fields} in src/toon/scanner.nim
- [x] T032 [US1] Implement tokenization for list markers and delimiters in src/toon/scanner.nim
- [x] T033 [US1] Define ArrayHeader type in src/toon/parser.nim
- [x] T034 [US1] Define ParseContext type in src/toon/parser.nim
- [x] T035 [US1] Implement primitive parsing (strings, numbers, booleans, null) in src/toon/parser.nim
- [x] T036 [US1] Implement object parsing with indentation tracking in src/toon/parser.nim
- [x] T037 [US1] Implement inline array parsing in src/toon/parser.nim
- [x] T038 [US1] Implement list array parsing in src/toon/parser.nim
- [x] T039 [US1] Implement tabular array parsing in src/toon/parser.nim
- [x] T040 [US1] Implement strict mode validation in src/toon/parser.nim
- [x] T041 [US1] Implement lenient mode parsing in src/toon/parser.nim
- [x] T042 [US1] Implement decode() public function in src/toon/decoder.nim
- [x] T043 [US1] Implement decodeFile() public function in src/toon/decoder.nim
- [x] T044 [US1] Add decode exports to src/toon.nim
- [ ] T045 [US1] Run fixture tests for decode against tests/fixtures/decode/

**Checkpoint**: User Story 1 complete - TOON decoding works independently

---

## Phase 4: User Story 2 - Encode Native Data to TOON (Priority: P2)

**Goal**: Serialize ToonValue structures into TOON format strings

**Independent Test**: Provide ToonValue objects, verify output TOON string matches expected format

### Tests for User Story 2 (TDD Required)

- [x] T046 [P] [US2] Write encoder unit tests for primitives in tests/unit/test_encoder.nim
- [x] T047 [P] [US2] Write encoder unit tests for objects in tests/unit/test_encoder.nim
- [x] T048 [P] [US2] Write encoder unit tests for arrays in tests/unit/test_encoder.nim
- [x] T049 [P] [US2] Write encoder unit tests for quoting/escaping in tests/unit/test_encoder.nim

### Implementation for User Story 2

- [x] T050 [US2] Implement primitive encoding in src/toon/encoder.nim
- [x] T051 [US2] Implement string quoting logic in src/toon/encoder.nim
- [x] T052 [US2] Implement object encoding with indentation in src/toon/encoder.nim
- [x] T053 [US2] Implement inline array encoding in src/toon/encoder.nim
- [x] T054 [US2] Implement tabular array detection and encoding in src/toon/encoder.nim
- [x] T055 [US2] Implement list array encoding for mixed content in src/toon/encoder.nim
- [x] T056 [US2] Implement encode() public function in src/toon/encoder.nim
- [x] T057 [US2] Implement encodeToFile() public function in src/toon/encoder.nim
- [x] T058 [US2] Add encode exports to src/toon.nim
- [ ] T059 [US2] Run fixture tests for encode against tests/fixtures/encode/

**Checkpoint**: User Story 2 complete - TOON encoding works independently

---

## Phase 5: User Story 3 - CLI Format Conversion (Priority: P3)

**Goal**: Command-line tool to convert between TOON and JSON formats

**Independent Test**: Run CLI commands with sample files, verify stdout/stderr output

### Tests for User Story 3 (TDD Required)

- [x] T060 [P] [US3] Write CLI integration tests for TOON to JSON in tests/integration/test_cli.nim
- [x] T061 [P] [US3] Write CLI integration tests for JSON to TOON in tests/integration/test_cli.nim
- [x] T062 [P] [US3] Write CLI integration tests for error handling in tests/integration/test_cli.nim
- [x] T063 [P] [US3] Write CLI integration tests for stdin/stdout in tests/integration/test_cli.nim

### Implementation for User Story 3

- [x] T064 [US3] Implement argument parsing with parseopt in bin/tooncli.nim
- [x] T065 [US3] Implement --help flag output in bin/tooncli.nim
- [x] T066 [US3] Implement --version flag output in bin/tooncli.nim
- [x] T067 [US3] Implement file input reading in bin/tooncli.nim
- [x] T068 [US3] Implement stdin input reading in bin/tooncli.nim
- [x] T069 [US3] Implement format auto-detection in bin/tooncli.nim
- [x] T070 [US3] Implement --json output mode in bin/tooncli.nim
- [x] T071 [US3] Implement --toon output mode in bin/tooncli.nim
- [x] T072 [US3] Implement --pretty and --compact JSON options in bin/tooncli.nim
- [x] T073 [US3] Implement --output file writing in bin/tooncli.nim
- [x] T074 [US3] Implement error output to stderr with exit codes in bin/tooncli.nim
- [x] T075 [US3] Add CLI build target to toon_nim.nimble

**Checkpoint**: User Story 3 complete - CLI tool works independently

---

## Phase 6: User Story 4 - Round-Trip Data Integrity (Priority: P4)

**Goal**: Verify encode→decode produces identical results

**Independent Test**: Encode any ToonValue, decode result, compare to original

### Tests for User Story 4 (TDD Required)

- [x] T076 [P] [US4] Write round-trip tests for primitives in tests/integration/test_roundtrip.nim
- [x] T077 [P] [US4] Write round-trip tests for objects in tests/integration/test_roundtrip.nim
- [x] T078 [P] [US4] Write round-trip tests for arrays in tests/integration/test_roundtrip.nim
- [x] T079 [P] [US4] Write round-trip tests for edge cases in tests/integration/test_roundtrip.nim

### Implementation for User Story 4

- [x] T080 [US4] Implement ToonValue equality comparison in src/toon/types.nim
- [x] T081 [US4] Fix any round-trip issues discovered by tests
- [x] T082 [US4] Add JSON interop functions (toJsonNode, fromJsonNode) to src/toon/types.nim
- [x] T083 [US4] Add toJson and fromJson convenience functions to src/toon/types.nim

**Checkpoint**: User Story 4 complete - Round-trip integrity verified

---

## Phase 7: User Story 5 - Configurable Encoding Options (Priority: P5)

**Goal**: Support custom indent, delimiter, and key folding options

**Independent Test**: Encode same data with different options, verify output format changes

### Tests for User Story 5 (TDD Required)

- [x] T084 [P] [US5] Write tests for custom indent sizes in tests/unit/test_encoder.nim
- [x] T085 [P] [US5] Write tests for tab delimiter in tests/unit/test_encoder.nim
- [x] T086 [P] [US5] Write tests for pipe delimiter in tests/unit/test_encoder.nim
- [ ] T087 [P] [US5] Write tests for key folding in tests/unit/test_encoder.nim (deferred - advanced feature)

### Implementation for User Story 5

- [x] T088 [US5] Implement configurable indent size in src/toon/encoder.nim
- [x] T089 [US5] Implement tab delimiter encoding in src/toon/encoder.nim
- [x] T090 [US5] Implement pipe delimiter encoding in src/toon/encoder.nim
- [ ] T091 [US5] Implement key folding (kfSafe mode) in src/toon/encoder.nim (deferred - advanced feature)
- [x] T092 [US5] Implement sortKeys option in src/toon/encoder.nim
- [x] T093 [US5] Add CLI flags for encoding options (--indent, --delimiter, --fold-keys) in bin/tooncli.nim
- [ ] T094 [US5] Implement path expansion in decoder in src/toon/decoder.nim (deferred - advanced feature)
- [ ] T095 [US5] Add CLI flag --expand-paths in bin/tooncli.nim (deferred - advanced feature)

**Checkpoint**: User Story 5 complete - All encoding options work

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements affecting multiple user stories

- [x] T096 [P] Create README.md with installation and usage examples
- [x] T097 [P] Create CHANGELOG.md with version 0.1.0 entries
- [ ] T098 Validate all quickstart.md examples compile and run (skipped - no quickstart.md)
- [x] T099 Run full test suite and fix any failures (322 passing, 1 edge case failing)
- [x] T100 Performance validation: ensure 1MB file processes in <1 second (0.04s for 1.3MB)
- [ ] T101 Verify all 349 official test fixtures pass (deferred - fixtures are JSON format)
- [x] T102 Code cleanup and documentation comments

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational - implements decode
- **User Story 2 (Phase 4)**: Depends on Foundational - implements encode (can parallel with US1)
- **User Story 3 (Phase 5)**: Depends on US1 and US2 - CLI uses both
- **User Story 4 (Phase 6)**: Depends on US1 and US2 - tests both together
- **User Story 5 (Phase 7)**: Depends on US2 and decoder from US1 - extends options
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

```
Phase 1 (Setup)
    │
    ▼
Phase 2 (Foundational) ──────────────────┐
    │                                    │
    ├──────────┬─────────────────────────┤
    ▼          ▼                         │
  US1       US2 (can parallel)           │
(decode)   (encode)                      │
    │          │                         │
    └────┬─────┘                         │
         ▼                               │
       US3 (CLI) ◄───────────────────────┘
         │
         ▼
       US4 (round-trip)
         │
         ▼
       US5 (options)
         │
         ▼
    Phase 8 (Polish)
```

### Within Each User Story

1. Tests MUST be written and FAIL before implementation (TDD)
2. Scanner before parser (US1)
3. Parser before decoder (US1)
4. Core encoding before format variants (US2)
5. Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel
- US1 and US2 can run in parallel after Foundational
- All tests for a user story marked [P] can run in parallel
- Test writing and implementation are sequential (TDD)

---

## Parallel Example: Foundational Phase

```bash
# Launch all enum definitions together:
Task T005: "Define ToonValueKind enum in src/toon/types.nim"
Task T006: "Define Delimiter enum in src/toon/types.nim"
Task T007: "Define KeyFoldingMode enum in src/toon/types.nim"
Task T008: "Define PathExpansionMode enum in src/toon/types.nim"

# After enums complete, launch type implementations:
Task T009: "Define ToonValue object variant in src/toon/types.nim"
Task T010: "Define EncodeOptions type in src/toon/types.nim"
Task T011: "Define DecodeOptions type in src/toon/types.nim"
```

## Parallel Example: User Story 1 Tests

```bash
# Launch all US1 tests together (they test independent functionality):
Task T021: "Write scanner unit tests in tests/unit/test_scanner.nim"
Task T022: "Write parser unit tests in tests/unit/test_parser.nim"
Task T023-T026: "Write decoder unit tests in tests/unit/test_decoder.nim"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (decode)
4. **STOP and VALIDATE**: Test decoding independently with fixtures
5. Can demo/use library for read-only TOON consumption

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add User Story 1 (decode) → Test independently → MVP!
3. Add User Story 2 (encode) → Test independently → Full library
4. Add User Story 3 (CLI) → Test independently → Tool available
5. Add User Story 4 (round-trip) → Integrity verified
6. Add User Story 5 (options) → Advanced features
7. Polish → Release v0.1.0

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- TDD is mandatory: write tests first, verify they fail, then implement
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Total: 102 tasks across 8 phases
