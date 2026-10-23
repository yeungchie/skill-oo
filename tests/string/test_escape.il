_TestEscapeDone = nil

_assert(ycString::Escape("a\\b") == "a\\\\b"  "escape: backslash")
_assert(ycString::Escape("a\"b") == "a\\\"b"  "escape: quote")
_assert(ycString::Escape("a\nb") == "a\\nb"  "escape: newline")
_assert(ycString::Escape("a\tb") == "a\\tb"  "escape: tab")
_assert(ycString::Escape("a\rb") == "a\\rb"  "escape: carriage return")
_assert(ycString::Escape("ab") == "ab"  "escape: plain")
_assert(ycString::Escape("ab" ?quote t) == "\"ab\""  "escape: quote wrap")
_assert(evalstring(ycString::Escape("a\"b\nc" ?quote t)) == "a\"b\nc"  "escape: evalstring roundtrip")

_assert(ycString::Unescape("a\\\\b") == "a\\b"  "unescape: backslash")
_assert(ycString::Unescape("a\\nb") == "a\nb"  "unescape: newline")
_assert(ycString::Unescape("a\\tb") == "a\tb"  "unescape: tab")
_assert(ycString::Unescape("a\\rb") == "a\rb"  "unescape: carriage return")
_assert(ycString::Unescape("a\\qb") == "a\\qb"  "unescape: unknown kept")
_assert(ycString::Unescape("a\\") == "a\\"  "unescape: trailing backslash kept")
_assertErrorMsg(
    lambda(() ycString::Unescape("a\\qb" ?strict t))
    "ycString::Unescape: unknown escape"
    "unescape: strict unknown"
)
_assertErrorMsg(
    lambda(() ycString::Unescape("a\\" ?strict t))
    "ycString::Unescape: trailing backslash"
    "unescape: strict trailing"
)
_assert(ycString::Unescape(ycString::Escape("x\"y\\z")) == "x\"y\\z"  "unescape: escape roundtrip")

_TestEscapeDone = t

; END
