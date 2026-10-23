_TestBlockDone = nil

; ---- dedent ----
_assert(ycTextwrap::Dedent("  a\n    b\n  c") == "a\n  b\nc"  "dedent: common")
_assert(ycTextwrap::Dedent("a\n  b") == "a\n  b"  "dedent: first unindented")
_assert(ycTextwrap::Dedent(" a\n  b") == "a\n b"  "dedent: one space")
_assert(ycTextwrap::Dedent("\t\ta\n\t\t\tb\n\tc") == "\ta\n\t\tb\nc"  "dedent: tabs")
_assert(ycTextwrap::Dedent("  a\n\n  b") == "a\n\nb"  "dedent: blank")
_assert(ycTextwrap::Dedent("  a\n   \n  b") == "a\n\nb"  "dedent: whitespace line")
_assert(ycTextwrap::Dedent("  a\n  b\n") == "a\nb\n"  "dedent: trailing newline")
_assert(ycTextwrap::Dedent("   \n\t") == "\n"  "dedent: all blank")
_assert(ycTextwrap::Dedent("") == ""  "dedent: empty")
_assert(ycTextwrap::Dedent("  a\r\n  b") == "a\nb"  "dedent: crlf")
_assert(
    ycTextwrap::Dedent(strcat(intToChar(9) "a" intToChar(10) "  b"))
        == strcat(intToChar(9) "a" intToChar(10) "  b")
    "dedent: mixed no common"
)

; ---- indent ----
_assert(ycTextwrap::Indent("a\n\n b" ?prefix "- ") == "- a\n\n-  b"  "indent: prefix")
_assert(ycTextwrap::Indent("a\n b") == "  a\n   b"  "indent: default")
_assert(ycTextwrap::Indent("a\n \nb" ?prefix "- ") == "- a\n \n- b"  "indent: blank")
_assert(ycTextwrap::Indent("" ?prefix "- ") == ""  "indent: empty")
_assert(ycTextwrap::Indent("a\r\nb" ?prefix "- ") == "- a\n- b"  "indent: crlf")
_assert(ycTextwrap::Indent("a" ?prefix "") == "a"  "indent: empty prefix")

; ---- shorten ----
_assert(ycTextwrap::Shorten("hello world" 12) == "hello world"  "shorten: fits")
_assert(ycTextwrap::Shorten("hello world" 8) == "hello..."  "shorten: word boundary")
_assert(ycTextwrap::Shorten("abcdefghij" 5) == "ab..."  "shorten: hard cut")
_assert(ycTextwrap::Shorten("ab cd" 4) == "a..."  "shorten: narrow word break")
_assert(ycTextwrap::Shorten("abcd ef" 5) == "ab..."  "shorten: exact room")
_assert(ycTextwrap::Shorten("中文测试" 4) == "..."  "shorten: cjk placeholder")
_assert(ycTextwrap::Shorten("中文测试" 5 ?unit "char") == "中文测试"  "shorten: char fits")
_assert(ycTextwrap::Shorten("abcdefgh" 5 ?placeholder "…") == "abcd…"  "shorten: wide placeholder")
_assert(ycTextwrap::Shorten("abc" 2) == ".."  "shorten: placeholder wider")
_assert(ycTextwrap::Shorten("  a   b  " 20) == "a b"  "shorten: collapse")
_assert(ycTextwrap::Shorten("" 5) == ""  "shorten: empty")
_assert(ycTextwrap::Shorten("abc" 3) == "abc"  "shorten: exact fit")
_assert(ycTextwrap::Shorten("ab cd" 4 ?placeholder "") == "ab"  "shorten: empty placeholder")
_assert(ycTextwrap::Shorten("a b" 1 ?placeholder "") == "a"  "shorten: empty placeholder cut")
_assert(ycTextwrap::Shorten("abc" 1) == "."  "shorten: placeholder truncated")

; ---- errors ----
_assertErrorMsg(
    lambda(() ycTextwrap::Dedent(5))
    "argument #1 should be a string"
    "dedent: non-string"
)
_assertErrorMsg(
    lambda(() ycTextwrap::Indent("a" ?prefix 5))
    "argument for keyword ?prefix should be a string"
    "indent: prefix type"
)
_assertErrorMsg(
    lambda(() ycTextwrap::Shorten("a" 0))
    "ycTextwrap::Shorten: width must be"
    "shorten: zero width"
)
_assertErrorMsg(
    lambda(() ycTextwrap::Shorten("a" 2 ?placeholder 5))
    "argument for keyword ?placeholder should be a string"
    "shorten: placeholder type"
)
_assertErrorMsg(
    lambda(() ycTextwrap::Shorten("a" 2 ?unit "px"))
    "ycTextwrap::Shorten: unknown unit"
    "shorten: unit"
)

_TestBlockDone = t

; END
