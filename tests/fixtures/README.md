# TOON conformance fixtures

`encode/`, `decode/` and `../fixtures.schema.json` are copied unchanged from the
official specification repository:

- Source: https://github.com/toon-format/spec, directory `tests/`
- Commit: d09c3d3 (release v4.4.0, 2026-10-08)
- License: MIT, Copyright (c) 2025-PRESENT Johann Schopplich

Each file holds language-agnostic cases: `input`, `expected`, optional `options`
(`delimiter`, `indentSize`, `strict`), `shouldError` and `minSpecVersion`.
`run_fixtures.nim` runs every case against this library; each case is one
external specification test, named by its file and `name`.

To update, replace both directories and the schema with those of a newer
release, record the commit here, and run `nimble conformance`.
