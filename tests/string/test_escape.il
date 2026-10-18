_TestEscapeDone = nil

_assert(ycString::escape("a\\b") == "a\\\\b"  "escape: backslash")
_assert(ycString::escape("a\"b") == "a\\\"b"  "escape: quote")
_assert(ycString::escape("a\nb") == "a\\nb"  "escape: newline")
_assert(ycString::escape("a\tb") == "a\\tb"  "escape: tab")
_assert(ycString::escape("a\rb") == "a\\rb"  "escape: carriage return")
_assert(ycString::escape("ab") == "ab"  "escape: plain")
_assert(ycString::escape("ab" ?quote t) == "\"ab\""  "escape: quote wrap")
_assert(evalstring(ycString::escape("a\"b\nc" ?quote t)) == "a\"b\nc"  "escape: evalstring roundtrip")

_assert(ycString::unescape("a\\\\b") == "a\\b"  "unescape: backslash")
_assert(ycString::unescape("a\\nb") == "a\nb"  "unescape: newline")
_assert(ycString::unescape("a\\tb") == "a\tb"  "unescape: tab")
_assert(ycString::unescape("a\\rb") == "a\rb"  "unescape: carriage return")
_assert(ycString::unescape("a\\qb") == "a\\qb"  "unescape: unknown kept")
_assert(ycString::unescape("a\\") == "a\\"  "unescape: trailing backslash kept")
_assertErrorMsg(
    lambda(() ycString::unescape("a\\qb" ?strict t))
    "ycString::unescape: unknown escape"
    "unescape: strict unknown"
)
_assertErrorMsg(
    lambda(() ycString::unescape("a\\" ?strict t))
    "ycString::unescape: trailing backslash"
    "unescape: strict trailing"
)
_assert(ycString::unescape(ycString::escape("x\"y\\z")) == "x\"y\\z"  "unescape: escape roundtrip")

_TestEscapeDone = t

; END
