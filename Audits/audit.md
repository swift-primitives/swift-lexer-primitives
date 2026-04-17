# Audit: swift-lexer-primitives

## Code Surface — 2026-04-16

### Scope

- **Target**: swift-lexer-primitives
- **Skill**: code-surface — [API-NAME-001], [API-NAME-002], [API-ERR-001], [API-IMPL-005], [API-IMPL-006], [API-IMPL-007], [API-IMPL-008]
- **Files**: 9 source files

### Findings

| # | Severity | Rule | Location | Finding | Status |
|---|----------|------|----------|---------|--------|
| 1 | HIGH | [API-NAME-002] | Lexer.Scanner+Lexing.swift | Systemic compound verb+noun internal method names | RESOLVED 2026-04-08 |
| 2 | HIGH | [API-NAME-002] | Lexer.Scanner.swift | Compound boundary helper names | RESOLVED 2026-04-08 |
| 3 | MEDIUM | — | Lexer.Scanner.swift, Lexer.Scanner+Lexing.swift | Underscore prefix on internal methods | RESOLVED 2026-04-08 |

### Summary

0 open, 3 resolved.

---

## Implementation — 2026-04-16

### Scope

- **Target**: swift-lexer-primitives
- **Skill**: implementation — [IMPL-002], [IMPL-006], [IMPL-010], [IMPL-060], [IMPL-064], [IMPL-065], [PATTERN-017]
- **Files**: 9 source files

### Findings

| # | Severity | Rule | Location | Finding | Status |
|---|----------|------|----------|---------|--------|
| 1 | LOW | [IMPL-010] | Lexer.Scanner.swift | Three boundary methods each contain `Int(bitPattern: position.rawValue)`. No `Ordinal.Protocol` overload exists. | DEFERRED — infrastructure gap in swift-ordinal-primitives |
| 2 | LOW | [IMPL-060] | Lexer.Scanner+Lexing.swift | `ASCII.Byte.` → `.ascii.` alignment with swift-parsers | RESOLVED 2026-04-16 |

### Summary

1 open (deferred), 1 resolved.

---

## Memory Safety — 2026-04-16

### Findings

No violations. `~Copyable, ~Escapable` with correct lifetime annotations throughout.

---

## Outstanding Work — Xylem Assignment — 2026-04-16

### Completed (this session)

| Item | Commit |
|------|--------|
| Wire `Text.Location.Tracker` into Scanner | `e493c62` — stored property, newline tracking in `leading()` and `comment()`, public `location` accessor |
| Hex/binary/octal integer literals | `e493c62` — `0x`, `0b`, `0o` prefixes with `digits(_:)` helper |
| Floating-point literals | `e493c62` — fractional `.` and `e`/`E` exponent |
| `#if`/`#else`/`#elseif`/`#endif` directives | `e493c62` — `directive()` with span-based keyword matching |
| Align `.ascii.` form | `e493c62` — 40 occurrences |

### Remaining

| # | Item | Difficulty | Blocker | Notes |
|---|------|-----------|---------|-------|
| 4 | SIMD/SWAR tiered bulk scanning | Hard | `/benchmark` harness required | Largest performance gap vs xylem. Needs `.timed()` validation before committing. |
| — | Prefix/postfix operator disambiguation | Moderate | Ordinal position subtraction + spacing heuristic design | Requires checking byte before operator start (partial arithmetic on `Text.Position`) and defining what constitutes "spacing context." |
| — | String interpolation `\(...)` | Hard | Mode stack / recursive scanner | Requires splitting string tokens into segments with re-entrant lexing for interpolation expressions. Architectural change beyond method additions. |
| — | Flat `Lexer.Buffer` | **Already realized** | — | `[Lexer.Lexeme]` is contiguous flat storage; source `Span<UInt8>` is the single byte buffer. Lexemes reference source via `Text.Range`. This IS xylem's flat-storage pattern — no additional type needed. |

### Infrastructure Gaps (cross-cutting)

| Gap | Location | Impact |
|-----|----------|--------|
| No `Int(bitPattern: some Ordinal.Protocol)` | swift-ordinal-primitives | 3 boundary methods need `.rawValue` |
| No typed increment on `Text.Line.Number` | swift-text-primitives | Tracker uses `rawValue + 1` |
| `Cardinal.+` shadows `Cardinal.Protocol.+` | swift-cardinal-primitives | Tracker requires explicit type annotations |
