_TestWrapDone = nil

; ---- wrap: basic ----
_Assert(ycTextwrap::Wrap("hello world" ?width 11) == list("hello world")  "wrap: fits")
_Assert(ycTextwrap::Wrap("hello world" ?width 7) == list("hello" "world")  "wrap: split")
_Assert(ycTextwrap::Wrap("one two three" ?width 13) == list("one two three")  "wrap: exact width")
_Assert(ycTextwrap::Wrap("one two three" ?width 9) == list("one two" "three")  "wrap: greedy")
_Assert(ycTextwrap::Wrap("abc def" ?width 5) == list("abc" "def")  "wrap: no room")
_Assert(ycTextwrap::Wrap("  a   b  " ?width 10) == list("a b")  "wrap: collapse")
_Assert(ycTextwrap::Wrap("a\tb" ?width 10) == list("a b")  "wrap: tab")
_Assert(ycTextwrap::Wrap("a\r\nb\rc" ?width 10) == list("a" "b" "c")  "wrap: newline forms")
_Assert(ycTextwrap::Wrap("a\n" ?width 10) == list("a")  "wrap: trailing newline")
_Assert(ycTextwrap::Wrap("a\n\n" ?width 10) == list("a" "")  "wrap: trailing blank")
_Assert(ycTextwrap::Wrap("\na" ?width 10) == list("" "a")  "wrap: leading blank")
_Assert(ycTextwrap::Wrap("" ?width 10) == nil  "wrap: empty")
_Assert(ycTextwrap::Wrap("   " ?width 10) == nil  "wrap: whitespace only")

; ---- wrap: display width ----
_Assert(ycTextwrap::Wrap("中文测试" ?width 4) == list("中文" "测试")  "wrap: cjk")
_Assert(ycTextwrap::Wrap("中" ?width 1) == list("中")  "wrap: wide char overflow")
_Assert(ycTextwrap::Wrap("中文" ?width 2 ?unit "char") == list("中文")  "wrap: char unit")
_Assert(ycTextwrap::Wrap("中文" ?width 2) == list("中" "文")  "wrap: display unit")

; ---- wrap: indent ----
_Assert(
    ycTextwrap::Wrap("one two three" ?width 9 ?initialIndent "> " ?subsequentIndent "  ")
        == list("> one two" "  three")
    "wrap: indent"
)
_Assert(
    ycTextwrap::Wrap("one two three" ?width 10 ?initialIndent "    ")
        == list("    one" "two three")
    "wrap: initial width"
)
_Assert(
    ycTextwrap::Wrap("a\n\nb" ?width 10 ?initialIndent "> " ?subsequentIndent "  ")
        == list("> a" "" "  b")
    "wrap: blank no indent"
)

_Assert(
    ycTextwrap::Wrap("one two three" ?width 10 ?subsequentIndent "    ")
        == list("one two" "    three")
    "wrap: subsequent width"
)
_Assert(
    ycTextwrap::Wrap("abcdefgh" ?width 6 ?subsequentIndent "  ")
        == list("abcdef" "  gh")
    "wrap: long word indent"
)
_Assert(
    ycTextwrap::Wrap("one two" ?width 3 ?maxLines 1 ?placeholder "")
        == list("one")
    "wrap: empty placeholder"
)

; ---- wrap: long words ----
_Assert(ycTextwrap::Wrap("abcdefgh" ?width 4) == list("abcd" "efgh")  "wrap: hard break")
_Assert(ycTextwrap::Wrap("abcdefgh" ?width 3) == list("abc" "def" "gh")  "wrap: hard break rest")
_Assert(ycTextwrap::Wrap("abcdefgh" ?width 4 ?breakLongWords nil) == list("abcdefgh")  "wrap: no long break")
_Assert(ycTextwrap::Wrap("ab-cdefgh" ?width 4) == list("ab-" "cdef" "gh")  "wrap: hyphen")
_Assert(
    ycTextwrap::Wrap("ab-cdefgh" ?width 4 ?breakOnHyphens nil) == list("ab-c" "defg" "h")
    "wrap: no hyphen"
)

; ---- wrap: maxLines ----
_Assert(
    ycTextwrap::Wrap("one two three four" ?width 7 ?maxLines 2)
        == list("one two" "thre...")
    "wrap: maxLines"
)
_Assert(
    ycTextwrap::Wrap("one two three" ?width 8 ?maxLines 1 ?initialIndent "> ")
        == list("> one...")
    "wrap: maxLines indent"
)
_Assert(
    ycTextwrap::Wrap("one two three four" ?width 7 ?maxLines 2 ?placeholder "…")
        == list("one two" "three…")
    "wrap: placeholder"
)
_Assert(
    ycTextwrap::Wrap("a\n\nb" ?width 10 ?maxLines 2) == list("a" "")
    "wrap: maxLines blank"
)

; ---- fill ----
_Assert(ycTextwrap::Fill("one two three" ?width 7) == "one two\nthree"  "fill: newline")
_Assert(ycTextwrap::Fill("one two" ?width 20 ?sep "|") == "one two"  "fill: sep unused")
_Assert(ycTextwrap::Fill("one two three" ?width 7 ?sep "|") == "one two|three"  "fill: sep")
_Assert(ycTextwrap::Fill("" ?width 7) == ""  "fill: empty")

; ---- errors ----
_AssertErrorMsg(
    lambda(() ycTextwrap::Wrap(5))
    "argument #1 should be a string"
    "wrap: non-string text"
)
_AssertErrorMsg(
    lambda(() ycTextwrap::Wrap("a" ?width 0))
    "ycTextwrap::Wrap: width must be"
    "wrap: zero width"
)
_AssertErrorMsg(
    lambda(() ycTextwrap::Wrap("a" ?width 7.5))
    "argument for keyword ?width should be an integer"
    "wrap: float width"
)

_AssertErrorMsg(
    lambda(() ycTextwrap::Wrap("a" ?width 2 ?initialIndent "   "))
    "ycTextwrap::Wrap: initialIndent leaves no room"
    "wrap: indent overflow"
)
_AssertErrorMsg(
    lambda(() ycTextwrap::Wrap("a" ?maxLines 0))
    "ycTextwrap::Wrap: maxLines must be"
    "wrap: zero maxLines"
)
_AssertErrorMsg(
    lambda(() ycTextwrap::Wrap("a" ?placeholder 5))
    "argument for keyword ?placeholder should be a string"
    "wrap: placeholder type"
)
_AssertErrorMsg(
    lambda(() ycTextwrap::Wrap("a" ?unit "px"))
    "ycTextwrap::Wrap: unknown unit"
    "wrap: unit"
)
_AssertErrorMsg(
    lambda(() ycTextwrap::Wrap("a" ?ambiguous 3))
    "ycTextwrap::Wrap: ambiguous must be"
    "wrap: ambiguous"
)
_AssertErrorMsg(
    lambda(() ycTextwrap::Fill("a" ?sep 5))
    "argument for keyword ?sep should be a string"
    "fill: sep type"
)

_TestWrapDone = t

; END
