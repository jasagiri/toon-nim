# G2 mutation testing: not measured

| Module | Status | Since |
|---|---|---|
| `src/toon/encoder.nim` | not measured | 2026-10-17 (rewritten for specification 4.4) |
| `src/toon/decoder.nim` | not measured | 2026-10-17 (rewritten for specification 4.4) |
| `src/toon/text.nim` | not measured | 2026-10-17 (new) |
| `src/toon/types.nim` | not measured | 2026-10-17 (equality and JSON conversion changed) |

Run nim-muter on these against `tests/fixtures/run_fixtures.nim` and
`tests/external/test_host_rules.nim` before the next release, and list each
surviving mutant with its reason here.

A hand check on 2026-10-17 (not a G2 run): four single mutations, one each in
string quoting, duplicate field names, blank lines in header spans and
declared counts, were each caught by the fixtures (5, 2, 10 and 12 failing
cases).
