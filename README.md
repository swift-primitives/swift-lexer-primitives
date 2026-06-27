# Lexer Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

A byte-cursor lexical scanner and a pull-mode structural-event substrate for turning borrowed UTF-8 bytes into trivia-aware lexemes, with zero platform dependencies.

---

## Quick Start

`Lexer.Scanner` walks a borrowed `Span<Byte>` and emits one ``Lexer.Lexeme`` per call: a token `kind`, the byte `range` of the token text, and the byte lengths of its leading and trailing trivia (whitespace and comments). The scanner always makes progress — malformed input produces `.unknown` lexemes plus diagnostics rather than throwing — so callers drain it in a `while let` loop and inspect the diagnostics afterward.

```swift
import Lexer_Primitives

let source = "let x = 42"
let bytes: [Byte] = source.utf8.map(Byte.init)

bytes.withUnsafeBufferPointer { buffer in
    let span = unsafe Span(_unsafeElements: buffer)
    var scanner = Lexer.Scanner(span)
    var diagnostics: [Lexer.Error] = []

    while let lexeme = scanner.next(diagnostics: &diagnostics) {
        print(lexeme.kind)
        // .keyword(.let), .identifier, .equal, .integerLiteral, .endOfFile
        if lexeme.isAtEnd { break }
    }
}
```

The scanner classifies identifiers and keywords, numeric literals (decimal, `0x` / `0b` / `0o`, and floating-point), string literals with escapes, operators, punctuation, `#`-directives, and `//` / `/* */` (nesting) comments. Line and column are tracked incrementally via `Lexer.Scanner.location` (O(1) on the hot path) or resolved on demand at a cold error site via `location(at:)`.

For structural formats (JSON, XML, CBOR, …) the package also ships `Lexer.Pull` — a generic, `~Copyable & ~Escapable` event cursor. A format supplies a `Lexer.Pull.Tokens` witness describing its token vocabulary, whitespace, and depth rules; `Lexer.Pull.Stream` drives it with depth tracking and a pristine/consumed fast-path gate, and `Lexer.Pull.Assemble` chooses between a wholesale parse and an event-by-event rebuild.

```swift
import Lexer_Primitives

// A format plugs into the substrate by conforming to Lexer.Pull.Tokens,
// then drives events through the generic stream:
var stream = Lexer.Pull.Stream<SomeFormat>(span)
while let kind = try stream.next() {
    // dispatch on the format's structural-token kind
}
```

---

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-lexer-primitives.git", branch: "main")
]
```

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Lexer Primitives", package: "swift-lexer-primitives"),
    ]
)
```

Requires Swift 6.3.1 and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26 (or the matching Linux / Windows toolchain).

---

## Architecture

Two library products. Builds on the `Byte`, `Token`, `Cursor`, and `Text` primitives.

| Product | Target | Purpose |
|---------|--------|---------|
| `Lexer Primitives` | `Sources/Lexer Primitives/` | The `Lexer` namespace: `Lexer.Scanner` (cursor-based byte scanner), `Lexer.Lexeme`, `Lexer.Trivia`, `Lexer.Error`, `Lexer.Position`, and `Lexer.Classify` (ASCII-subset character predicates); the `Lexer.Pull` pull-mode cohort (`Stream`, `Tokens`, `Assemble`, `Assemble.Strategy`); and `Token.Keyword` UTF-8 reverse lookup. |
| `Lexer Primitives Test Support` | `Tests/Support/` | Re-exports the main target for test consumers. |

Foundation-free.

---

## Platform Support

| Platform | Status |
|----------|--------|
| macOS 26 | Full support |
| Linux | Full support |
| Windows | Full support |
| iOS / tvOS / watchOS / visionOS | Supported |

---

## Community

<!-- BEGIN: discussion -->
<!-- Discussion thread created at publication. -->
<!-- END: discussion -->

---

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
