_TestWrapDone = nil

; ---- wrap: basic ----
_assert(ycTextwrap::wrap("hello world" ?width 11) == list("hello world")  "wrap: fits")
_assert(ycTextwrap::wrap("hello world" ?width 7) == list("hello" "world")  "wrap: split")
_assert(ycTextwrap::wrap("one two three" ?width 13) == list("one two three")  "wrap: exact width")
_assert(ycTextwrap::wrap("one two three" ?width 9) == list("one two" "three")  "wrap: greedy")
_assert(ycTextwrap::wrap("abc def" ?width 5) == list("abc" "def")  "wrap: no room")
_assert(ycTextwrap::wrap("  a   b  " ?width 10) == list("a b")  "wrap: collapse")
_assert(ycTextwrap::wrap("a\tb" ?width 10) == list("a b")  "wrap: tab")
_assert(ycTextwrap::wrap("a\r\nb\rc" ?width 10) == list("a" "b" "c")  "wrap: newline forms")
_assert(ycTextwrap::wrap("a\n" ?width 10) == list("a")  "wrap: trailing newline")
_assert(ycTextwrap::wrap("a\n\n" ?width 10) == list("a" "")  "wrap: trailing blank")
_assert(ycTextwrap::wrap("\na" ?width 10) == list("" "a")  "wrap: leading blank")
_assert(ycTextwrap::wrap("" ?width 10) == nil  "wrap: empty")
_assert(ycTextwrap::wrap("   " ?width 10) == nil  "wrap: whitespace only")

; ---- wrap: display width ----
_assert(ycTextwrap::wrap("中文测试" ?width 4) == list("中文" "测试")  "wrap: cjk")
_assert(ycTextwrap::wrap("中" ?width 1) == list("中")  "wrap: wide char overflow")
_assert(ycTextwrap::wrap("中文" ?width 2 ?unit "char") == list("中文")  "wrap: char unit")
_assert(ycTextwrap::wrap("中文" ?width 2) == list("中" "文")  "wrap: display unit")

; ---- wrap: indent ----
_assert(
    ycTextwrap::wrap("one two three" ?width 9 ?initialIndent "> " ?subsequentIndent "  ")
        == list("> one two" "  three")
    "wrap: indent"
)
_assert(
    ycTextwrap::wrap("one two three" ?width 10 ?initialIndent "    ")
        == list("    one" "two three")
    "wrap: initial width"
)
_assert(
    ycTextwrap::wrap("a\n\nb" ?width 10 ?initialIndent "> " ?subsequentIndent "  ")
        == list("> a" "" "  b")
    "wrap: blank no indent"
)

_assert(
    ycTextwrap::wrap("one two three" ?width 10 ?subsequentIndent "    ")
        == list("one two" "    three")
    "wrap: subsequent width"
)
_assert(
    ycTextwrap::wrap("abcdefgh" ?width 6 ?subsequentIndent "  ")
        == list("abcdef" "  gh")
    "wrap: long word indent"
)
_assert(
    ycTextwrap::wrap("one two" ?width 3 ?maxLines 1 ?placeholder "")
        == list("one")
    "wrap: empty placeholder"
)

; ---- wrap: long words ----
_assert(ycTextwrap::wrap("abcdefgh" ?width 4) == list("abcd" "efgh")  "wrap: hard break")
_assert(ycTextwrap::wrap("abcdefgh" ?width 3) == list("abc" "def" "gh")  "wrap: hard break rest")
_assert(ycTextwrap::wrap("abcdefgh" ?width 4 ?breakLongWords nil) == list("abcdefgh")  "wrap: no long break")
_assert(ycTextwrap::wrap("ab-cdefgh" ?width 4) == list("ab-" "cdef" "gh")  "wrap: hyphen")
_assert(
    ycTextwrap::wrap("ab-cdefgh" ?width 4 ?breakOnHyphens nil) == list("ab-c" "defg" "h")
    "wrap: no hyphen"
)

; ---- wrap: maxLines ----
_assert(
    ycTextwrap::wrap("one two three four" ?width 7 ?maxLines 2)
        == list("one two" "thre...")
    "wrap: maxLines"
)
_assert(
    ycTextwrap::wrap("one two three" ?width 8 ?maxLines 1 ?initialIndent "> ")
        == list("> one...")
    "wrap: maxLines indent"
)
_assert(
    ycTextwrap::wrap("one two three four" ?width 7 ?maxLines 2 ?placeholder "…")
        == list("one two" "three…")
    "wrap: placeholder"
)
_assert(
    ycTextwrap::wrap("a\n\nb" ?width 10 ?maxLines 2) == list("a" "")
    "wrap: maxLines blank"
)

; ---- fill ----
_assert(ycTextwrap::fill("one two three" ?width 7) == "one two\nthree"  "fill: newline")
_assert(ycTextwrap::fill("one two" ?width 20 ?sep "|") == "one two"  "fill: sep unused")
_assert(ycTextwrap::fill("one two three" ?width 7 ?sep "|") == "one two|three"  "fill: sep")
_assert(ycTextwrap::fill("" ?width 7) == ""  "fill: empty")

; ---- errors ----
_assertErrorMsg(
    lambda(() ycTextwrap::wrap(5))
    "argument #1 should be a string"
    "wrap: non-string text"
)
_assertErrorMsg(
    lambda(() ycTextwrap::wrap("a" ?width 0))
    "ycTextwrap::wrap: width must be"
    "wrap: zero width"
)
_assertErrorMsg(
    lambda(() ycTextwrap::wrap("a" ?width 2 ?initialIndent "   "))
    "ycTextwrap::wrap: initialIndent leaves no room"
    "wrap: indent overflow"
)
_assertErrorMsg(
    lambda(() ycTextwrap::wrap("a" ?maxLines 0))
    "ycTextwrap::wrap: maxLines must be"
    "wrap: zero maxLines"
)
_assertErrorMsg(
    lambda(() ycTextwrap::wrap("a" ?placeholder 5))
    "argument for keyword ?placeholder should be a string"
    "wrap: placeholder type"
)
_assertErrorMsg(
    lambda(() ycTextwrap::wrap("a" ?unit "px"))
    "ycTextwrap::wrap: unknown unit"
    "wrap: unit"
)
_assertErrorMsg(
    lambda(() ycTextwrap::wrap("a" ?ambiguous 3))
    "ycTextwrap::wrap: ambiguous must be"
    "wrap: ambiguous"
)
_assertErrorMsg(
    lambda(() ycTextwrap::fill("a" ?sep 5))
    "argument for keyword ?sep should be a string"
    "fill: sep type"
)

_TestWrapDone = t

; END
