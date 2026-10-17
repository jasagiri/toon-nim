# Specification traceability (G0)

Source document: TOON specification 4.4 (toon-format/spec d09c3d3). Its
normative obligations for an implementation are the checklists of §13.1 and
§13.2 and the error list of §14; each line below ties one of them to the
tests that check it.

- **Fixtures** are the official cases in `tests/fixtures`, run by
  `tests/fixtures/run_fixtures.nim`, named here by category and `specSection`.
- **HOST-nn** are the tests in `tests/external/test_host_rules.nim`, for rules
  the fixtures cannot express because their inputs are JSON.

## §13.1 Encoder

| Obligation | Tests |
|---|---|
| UTF-8 output with LF line endings (§1.2) | encode §1.2 |
| Consistent indentation, default 2, no tabs (§12) | encode §12, §10 (indentSize 4) |
| Escape per §7.1, no other escapes | encode §7.1 |
| Declare the document delimiter in every header (§11.1) | encode §11, §11.1 |
| Quote strings per §7.2 | encode §7.2 |
| Quote exactly the keys that fail §7.3 | encode §7.3 |
| Form from shape and position (§1.4, §9) | encode §9.1–§9.5, §10 |
| Declared lengths match (§6, §9) | encode §9.1–§9.5 |
| Preserve key order, except tabular reordering (§2) | encode §9.3, §9.5; HOST-06 |
| Numbers per §2 | encode §2; HOST-06 |
| Lowercase booleans and null (§2) | encode §2 |
| NaN and ±Infinity to null (§3) | HOST-01 |
| Error on an unpaired surrogate (§3) | HOST-02 |
| No trailing spaces, blank lines or trailing newline (§12) | encode §12, and every encode case compares the whole output |
| No comment lines (§5.1) | encode §7.2 (strings starting with `#` are quoted) |

## §13.2 Decoder

| Obligation | Tests |
|---|---|
| Line preparation order of §12 | decode §12, §5.1 |
| Only SP and HTAB are whitespace; trim spaces only (§1.2, §12) | decode §1.2, §12 |
| Headers per §6 | decode §6 |
| Empty arrays in all forms (§9.1, §9.2) | decode §9.1, §9.2 |
| Split on the active delimiter only (§11) | decode §11, §11.2 |
| Unescape per §7.1 | decode §7.1 |
| Type unquoted primitives (§4) | decode §4 |
| Accept any unquoted key token (§7.4) | decode §7.4 |
| Every key, including `__proto__`, as an own entry (§15) | decode §15 |
| Error on §14; with `strict=false` only the recoveries of §14.4 | decode §14.1–§14.4 |
| Preserve order, except tabular reordering (§2, §9.3, §9.5) | decode §9.3, §9.5 (the runner compares ordered keys) |
| Byte input as UTF-8, error on ill-formed sequences (§4) | HOST-03 |
| Document the numeric out-of-range policy and object-model deviations (§4, §2, §15) | README "Conformance"; HOST-04, HOST-05 |

## §14 Errors

| Condition | Tests |
|---|---|
| §14.1 Count and width mismatches | decode §14.1, §9.3, §9.5 |
| §14.2 Syntax and structural errors | decode §14.2, §6, §7.1, §7.4, §8, §12 |
| §14.3 Duplicate keys | decode §14.3 |
| §14.4 The five non-strict recoveries | decode §14.4 |

## Outside this implementation

- §13.3 (validators): toon-nim has no validator.
- §3 serialization hooks (MAY): not offered; values are built as `ToonValue`
  or converted from `JsonNode`.
- §2 lossless stringification of out-of-domain numbers (SHOULD): not offered;
  the policy in README applies (float64 approximation).
