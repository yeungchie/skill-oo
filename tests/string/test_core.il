_TestCoreDone = nil

; ---- trim ----
_Assert(ycString::Trim("  ab  ") == "ab"  "trim: spaces")
_Assert(ycString::Trim("xxabxx" ?chars "x") == "ab"  "trim: custom chars")
_Assert(ycString::Trim("xxx" ?chars "x") == ""  "trim: all stripped")
_Assert(ycString::TrimStart("  ab  ") == "ab  "  "trimStart: leading only")
_Assert(ycString::TrimEnd("  ab  ") == "  ab"  "trimEnd: trailing only")
_Assert(ycString::Trim("中中a中中" ?chars "中") == "a"  "trim: cjk chars")

; ---- width ----
_Assert(ycString::Width("中文") == 4  "width: display")
_Assert(ycString::Width("中文" ?unit "char") == 2  "width: char unit")
_Assert(ycString::Width("") == 0  "width: empty")
_AssertErrorMsg(
    lambda(() ycString::Width("a" ?unit "px"))
    "ycString::Width: unknown unit"
    "width: unknown unit"
)

; ---- pad ----
_Assert(ycString::Pad("ab" 5 ?fill "-") == "ab---"  "pad: end default side")
_Assert(ycString::Pad("ab" 5 ?side "start" ?fill "-") == "---ab"  "pad: start side")
_Assert(ycString::Pad("中" 4 ?unit "char" ?fill "-") == "中---"  "pad: char unit")
_Assert(ycString::Width(ycString::Pad("中" 4)) == 4  "pad: display unit")
_Assert(ycString::Pad("ab" 1) == "ab"  "pad: no truncation")
_Assert(ycString::Pad("a" 2 ?unit "char" ?fill "中") == "a中"  "pad: wide fill in char mode")
_AssertErrorMsg(
    lambda(() ycString::Pad("a" -1))
    "ycString::Pad: width must be"
    "pad: negative width"
)
_AssertErrorMsg(
    lambda(() ycString::Pad("a" 2 ?fill "中"))
    "ycString::Pad: fill must be single width"
    "pad: wide fill in display mode"
)
_AssertErrorMsg(
    lambda(() ycString::Pad("a" 2 ?fill ""))
    "ycString::Pad: fill must be a single character"
    "pad: empty fill"
)

; ---- split ----
_Assert(ycString::Split("  a\tb\n c ") == list("a" "b" "c")  "Split: default whitespace")
_Assert(ycString::Split("") == nil  "Split: empty input")
_Assert(ycString::Split("a,,b" ?sep ",") == list("a" "" "b")  "Split: literal keeps empties")
_Assert(ycString::Split(",a," ?sep ",") == list("" "a" "")  "Split: literal edge empties")
_Assert(ycString::Split("a,,b" ?sep "," ?keepEmpty nil) == list("a" "b")  "Split: drop empties")
_Assert(ycString::Split("a1b22c" ?sep "[0-9]+" ?regex t) == list("a" "b" "c")  "Split: regex")
_Assert(
    ycString::Split(" a  b " ?sep "\\s+" ?regex t ?keepEmpty nil) == list("a" "b")
    "Split: regex drop empties"
)
_AssertErrorMsg(
    lambda(() ycString::Split("a" ?sep ""))
    "ycString::Split: separator must not be empty"
    "Split: empty separator"
)
_AssertErrorMsg(
    lambda(() ycString::Split("a" ?regex t))
    "ycString::Split: regex mode needs a non-empty pattern"
    "Split: regex without pattern"
)

; ---- join ----
_Assert(ycString::Join(list("a" "b" "c")) == "abc"  "Join: default")
_Assert(ycString::Join(list("a" "b") ?sep "-") == "a-b"  "Join: custom separator")
_Assert(ycString::Join(nil) == ""  "Join: empty list")
_AssertErrorMsg(
    lambda(() ycString::Join(list("a" 1)))
    "ycString::Join: item #2 is not a string"
    "Join: non-string item"
)
_AssertErrorMsg(
    lambda(() ycString::Join("x"))
    "argument #1 should be a list"
    "Join: non-list"
)

; ---- startsWith / endsWith ----
_Assert(ycString::StartsWith("abc" "ab")  "startsWith: hit")
_Assert(ycString::StartsWith("abc" "")  "startsWith: empty prefix")
_Assert(ycString::StartsWith("abc" "abcd") == nil  "startsWith: too long")
_Assert(ycString::StartsWith("中文abc" "中文")  "startsWith: cjk")
_Assert(ycString::EndsWith("abc" "bc")  "endsWith: hit")
_Assert(ycString::EndsWith("abc" "")  "endsWith: empty suffix")
_Assert(ycString::EndsWith("abc" "abcd") == nil  "endsWith: too long")
_Assert(ycString::EndsWith("中文abc" "abc")  "endsWith: cjk")

; ---- replace ----
_Assert(ycString::Replace("aaa" "a" "b") == "bbb"  "replace: literal all")
_Assert(ycString::Replace("aaa" "aa" "b") == "ba"  "replace: non-overlap")
_Assert(ycString::Replace("abc" "x" "y") == "abc"  "replace: no match")
_Assert(ycString::Replace("a1b22c" "[0-9]+" "N" ?regex t) == "aNbNc"  "replace: regex")
_Assert(ycString::Replace("baaacaa" "a+" "X" ?regex t) == "bXcX"  "replace: regex all")
_AssertErrorMsg(
    lambda(() ycString::Replace("a" "" "b"))
    "ycString::Replace: search string must not be empty"
    "replace: empty search"
)
_AssertErrorMsg(
    lambda(() ycString::Replace("a" "" "b" ?regex t))
    "ycString::Replace: pattern must not be empty"
    "replace: empty pattern"
)

; ---- count ----
_Assert(ycString::Count("banana" "a") == 3  "count: literal")
_Assert(ycString::Count("aaaa" "aa") == 2  "count: non-overlap")
_Assert(ycString::Count("abc" "x") == 0  "count: none")
_Assert(ycString::Count("banana" "a+" ?regex t) == 3  "count: regex")
_AssertErrorMsg(
    lambda(() ycString::Count("a" ""))
    "ycString::Count: search string must not be empty"
    "count: empty search"
)

_TestCoreDone = t

; END
