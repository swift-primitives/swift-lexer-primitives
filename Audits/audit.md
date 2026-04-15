# Audit: swift-lexer-primitives

## Code Surface — 2026-04-08

### Scope

- **Target**: swift-lexer-primitives
- **Skill**: code-surface — [API-NAME-001], [API-NAME-002], [API-ERR-001], [API-IMPL-005], [API-IMPL-006], [API-IMPL-007], [API-IMPL-008]
- **Files**: 9 source files
- **Focus**: Compound names and underscore-prefixed items per user request

### Findings

| # | Severity | Rule | Location | Finding | Status |
|---|----------|------|----------|---------|--------|
| 1 | HIGH | [API-NAME-002] | Lexer.Scanner+Lexing.swift | **Systemic compound verb+noun names on internal instance methods.** 10 methods use `_scan{Noun}` or `_skip{Noun}` pattern: `_skipLeadingTrivia`, `_skipTrailingTrivia`, `_skipLineComment`, `_skipBlockComment`, `_scanToken`, `_scanIdentifier`, `_scanDollarIdentifier`, `_scanNumber`, `_scanString`, `_scanOperator`. [IMPL-024] carves out statics only — not instance methods. xylem reference: single-concept nouns (`spaces()`, `comment()`, `text()`, `identifier()`, `markup()`). The type context (Scanner) implies the verb. | OPEN |
| 2 | HIGH | [API-NAME-002] | Lexer.Scanner.swift:107,114,121 | **Compound names on boundary helpers**: `_spanIndex(_:)` (span+index), `_inBounds(_:)` (in+bounds). These are instance methods, not statics. `_inBounds` is also a boolean without `is` prefix. | OPEN |
| 3 | MEDIUM | — | Lexer.Scanner.swift, Lexer.Scanner+Lexing.swift | **Underscore prefix on all 14 internal methods.** No requirement ID mandates underscore prefix; `internal` visibility already conveys non-public status. The underscore creates a "shadow API" pattern that masks naming violations and is not used in the xylem reference. | OPEN |

### Recommended Refactoring (xylem-style)

| Current | Proposed | Rationale |
|---------|----------|-----------|
| `_skipLeadingTrivia(diagnostics:)` | `leading(diagnostics:)` | Noun (trivia kind). Context: inside trivia-scanning group. |
| `_skipTrailingTrivia()` | `trailing()` | Noun (trivia kind). |
| `_skipLineComment()` | `line()` | Noun (comment kind). Called from leading trivia context. |
| `_skipBlockComment(diagnostics:)` | `block(diagnostics:)` | Noun (comment kind). |
| `_scanToken(diagnostics:)` | `token(diagnostics:)` | Noun. Top-level dispatch. |
| `_scanIdentifier()` | `identifier()` | Noun. Mirrors xylem. |
| `_scanDollarIdentifier()` | `dollar()` | Noun. |
| `_scanNumber()` | `number()` | Noun. |
| `_scanString(diagnostics:)` | `string(diagnostics:)` | Noun. |
| `_scanOperator()` | `` `operator`() `` | Noun (keyword, needs backticks). |
| `_spanIndex(_:)` | Inline into `_byte(at:)` and `_inBounds(_:)`, or a single boundary helper named `index(for:)` | The conversion is three call sites. |
| `_inBounds(_:)` | Inline `index(for: position) < source.count` at the 6 call sites, or `isValid(_:)` | Boolean with clear name. |
| `_byte(at:)` | `byte(at:)` | Already single-concept; drop underscore. |
| `_distance(from:to:)` | `distance(from:to:)` | Already single-concept; drop underscore. |

### Summary

3 findings: 0 critical, 2 high, 1 medium.

**Systemic pattern**: Every internal method uses `_verb+Noun` compound naming with underscore prefix. The verb prefix (`_scan`, `_skip`) is mechanism — it describes *how* the method operates, not *what* concept it represents. The xylem reference demonstrates that scanner methods should be named for the *concept they recognize* (noun), with the scanning verb implied by the type context. The underscore prefix is redundant given `internal` visibility.

---

## Implementation — 2026-04-08

### Scope

- **Target**: swift-lexer-primitives
- **Skill**: implementation — [IMPL-002], [IMPL-006], [IMPL-010], [IMPL-024], [IMPL-060], [IMPL-064], [IMPL-065], [PATTERN-017]
- **Files**: 9 source files

### Findings

| # | Severity | Rule | Location | Finding | Status |
|---|----------|------|----------|---------|--------|
| 1 | LOW | [IMPL-010] | Lexer.Scanner.swift:108 | `_spanIndex` uses `Int(bitPattern: position.rawValue)` — one `.rawValue` extraction. Necessary: only `Int(bitPattern: Ordinal)` exists, no `Ordinal.Protocol` overload. Single boundary point per [PATTERN-017]. | DEFERRED — infrastructure gap in swift-ordinal-primitives |

### Summary

1 finding: 0 critical, 0 high, 0 medium, 1 low (deferred).

Typed state (`cursor: Text.Position`), typed arithmetic (`cursor += .one`), typed output (`Text.Range`, `Text.Count`), single boundary point for Span indexing. `ASCII.Byte.*` constants used throughout per [IMPL-060]. `(try! end - start).magnitude` per [INFRA-102].

---

## Memory Safety — 2026-04-08

### Scope

- **Target**: swift-lexer-primitives
- **Skill**: memory-safety — [MEM-COPY-001], [MEM-LIFE-*], [MEM-SAFE-020]
- **Files**: Lexer.Scanner.swift, Lexer.Scanner+Lexing.swift

### Findings

| # | Severity | Rule | Location | Finding | Status |
|---|----------|------|----------|---------|--------|
| — | — | — | — | No violations found | — |

### Summary

0 findings. `~Copyable, ~Escapable` with correct lifetime annotations.
