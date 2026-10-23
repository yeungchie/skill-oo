_TestEscapeDone = nil

_Assert(ycString::Escape("a\\b") == "a\\\\b"  "escape: backslash")
_Assert(ycString::Escape("a\"b") == "a\\\"b"  "escape: quote")
_Assert(ycString::Escape("a\nb") == "a\\nb"  "escape: newline")
_Assert(ycString::Escape("a\tb") == "a\\tb"  "escape: tab")
_Assert(ycString::Escape("a\rb") == "a\\rb"  "escape: carriage return")
_Assert(ycString::Escape("ab") == "ab"  "escape: plain")
_Assert(ycString::Escape("ab" ?quote t) == "\"ab\""  "escape: quote wrap")
_Assert(evalstring(ycString::Escape("a\"b\nc" ?quote t)) == "a\"b\nc"  "escape: evalstring roundtrip")

_Assert(ycString::Unescape("a\\\\b") == "a\\b"  "unescape: backslash")
_Assert(ycString::Unescape("a\\nb") == "a\nb"  "unescape: newline")
_Assert(ycString::Unescape("a\\tb") == "a\tb"  "unescape: tab")
_Assert(ycString::Unescape("a\\rb") == "a\rb"  "unescape: carriage return")
_Assert(ycString::Unescape("a\\qb") == "a\\qb"  "unescape: unknown kept")
_Assert(ycString::Unescape("a\\") == "a\\"  "unescape: trailing backslash kept")
_AssertErrorMsg(
    lambda(() ycString::Unescape("a\\qb" ?strict t))
    "ycString::Unescape: unknown escape"
    "unescape: strict unknown"
)
_AssertErrorMsg(
    lambda(() ycString::Unescape("a\\" ?strict t))
    "ycString::Unescape: trailing backslash"
    "unescape: strict trailing"
)
_Assert(ycString::Unescape(ycString::Escape("x\"y\\z")) == "x\"y\\z"  "unescape: escape roundtrip")

_TestEscapeDone = t

; END
