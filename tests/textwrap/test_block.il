_TestBlockDone = nil

; ---- dedent ----
_Assert(ycTextwrap::Dedent("  a\n    b\n  c") == "a\n  b\nc"  "dedent: common")
_Assert(ycTextwrap::Dedent("a\n  b") == "a\n  b"  "dedent: first unindented")
_Assert(ycTextwrap::Dedent(" a\n  b") == "a\n b"  "dedent: one space")
_Assert(ycTextwrap::Dedent("\t\ta\n\t\t\tb\n\tc") == "\ta\n\t\tb\nc"  "dedent: tabs")
_Assert(ycTextwrap::Dedent("  a\n\n  b") == "a\n\nb"  "dedent: blank")
_Assert(ycTextwrap::Dedent("  a\n   \n  b") == "a\n\nb"  "dedent: whitespace line")
_Assert(ycTextwrap::Dedent("  a\n  b\n") == "a\nb\n"  "dedent: trailing newline")
_Assert(ycTextwrap::Dedent("   \n\t") == "\n"  "dedent: all blank")
_Assert(ycTextwrap::Dedent("") == ""  "dedent: empty")
_Assert(ycTextwrap::Dedent("  a\r\n  b") == "a\nb"  "dedent: crlf")
_Assert(
    ycTextwrap::Dedent(strcat(intToChar(9) "a" intToChar(10) "  b"))
        == strcat(intToChar(9) "a" intToChar(10) "  b")
    "dedent: mixed no common"
)

; ---- indent ----
_Assert(ycTextwrap::Indent("a\n\n b" ?prefix "- ") == "- a\n\n-  b"  "indent: prefix")
_Assert(ycTextwrap::Indent("a\n b") == "  a\n   b"  "indent: default")
_Assert(ycTextwrap::Indent("a\n \nb" ?prefix "- ") == "- a\n \n- b"  "indent: blank")
_Assert(ycTextwrap::Indent("" ?prefix "- ") == ""  "indent: empty")
_Assert(ycTextwrap::Indent("a\r\nb" ?prefix "- ") == "- a\n- b"  "indent: crlf")
_Assert(ycTextwrap::Indent("a" ?prefix "") == "a"  "indent: empty prefix")

; ---- shorten ----
_Assert(ycTextwrap::Shorten("hello world" 12) == "hello world"  "shorten: fits")
_Assert(ycTextwrap::Shorten("hello world" 8) == "hello..."  "shorten: word boundary")
_Assert(ycTextwrap::Shorten("abcdefghij" 5) == "ab..."  "shorten: hard cut")
_Assert(ycTextwrap::Shorten("ab cd" 4) == "a..."  "shorten: narrow word break")
_Assert(ycTextwrap::Shorten("abcd ef" 5) == "ab..."  "shorten: exact room")
_Assert(ycTextwrap::Shorten("中文测试" 4) == "..."  "shorten: cjk placeholder")
_Assert(ycTextwrap::Shorten("中文测试" 5 ?unit "char") == "中文测试"  "shorten: char fits")
_Assert(ycTextwrap::Shorten("abcdefgh" 5 ?placeholder "…") == "abcd…"  "shorten: wide placeholder")
_Assert(ycTextwrap::Shorten("abc" 2) == ".."  "shorten: placeholder wider")
_Assert(ycTextwrap::Shorten("  a   b  " 20) == "a b"  "shorten: collapse")
_Assert(ycTextwrap::Shorten("" 5) == ""  "shorten: empty")
_Assert(ycTextwrap::Shorten("abc" 3) == "abc"  "shorten: exact fit")
_Assert(ycTextwrap::Shorten("ab cd" 4 ?placeholder "") == "ab"  "shorten: empty placeholder")
_Assert(ycTextwrap::Shorten("a b" 1 ?placeholder "") == "a"  "shorten: empty placeholder cut")
_Assert(ycTextwrap::Shorten("abc" 1) == "."  "shorten: placeholder truncated")

; ---- errors ----
_AssertErrorMsg(
    lambda(() ycTextwrap::Dedent(5))
    "argument #1 should be a string"
    "dedent: non-string"
)
_AssertErrorMsg(
    lambda(() ycTextwrap::Indent("a" ?prefix 5))
    "argument for keyword ?prefix should be a string"
    "indent: prefix type"
)
_AssertErrorMsg(
    lambda(() ycTextwrap::Shorten("a" 0))
    "ycTextwrap::Shorten: width must be"
    "shorten: zero width"
)
_AssertErrorMsg(
    lambda(() ycTextwrap::Shorten("a" 2 ?placeholder 5))
    "argument for keyword ?placeholder should be a string"
    "shorten: placeholder type"
)
_AssertErrorMsg(
    lambda(() ycTextwrap::Shorten("a" 2 ?unit "px"))
    "ycTextwrap::Shorten: unknown unit"
    "shorten: unit"
)

_TestBlockDone = t

; END
