_TestCoreDone = nil

; ---- trim ----
_assert(ycString::Trim("  ab  ") == "ab"  "trim: spaces")
_assert(ycString::Trim("xxabxx" ?chars "x") == "ab"  "trim: custom chars")
_assert(ycString::Trim("xxx" ?chars "x") == ""  "trim: all stripped")
_assert(ycString::TrimStart("  ab  ") == "ab  "  "trimStart: leading only")
_assert(ycString::TrimEnd("  ab  ") == "  ab"  "trimEnd: trailing only")
_assert(ycString::Trim("中中a中中" ?chars "中") == "a"  "trim: cjk chars")

; ---- width ----
_assert(ycString::Width("中文") == 4  "width: display")
_assert(ycString::Width("中文" ?unit "char") == 2  "width: char unit")
_assert(ycString::Width("") == 0  "width: empty")
_assertErrorMsg(
    lambda(() ycString::Width("a" ?unit "px"))
    "ycString::Width: unknown unit"
    "width: unknown unit"
)

; ---- pad ----
_assert(ycString::Pad("ab" 5 ?fill "-") == "ab---"  "pad: end default side")
_assert(ycString::Pad("ab" 5 ?side "start" ?fill "-") == "---ab"  "pad: start side")
_assert(ycString::Pad("中" 4 ?unit "char" ?fill "-") == "中---"  "pad: char unit")
_assert(ycString::Width(ycString::Pad("中" 4)) == 4  "pad: display unit")
_assert(ycString::Pad("ab" 1) == "ab"  "pad: no truncation")
_assert(ycString::Pad("a" 2 ?unit "char" ?fill "中") == "a中"  "pad: wide fill in char mode")
_assertErrorMsg(
    lambda(() ycString::Pad("a" -1))
    "ycString::Pad: width must be"
    "pad: negative width"
)
_assertErrorMsg(
    lambda(() ycString::Pad("a" 2 ?fill "中"))
    "ycString::Pad: fill must be single width"
    "pad: wide fill in display mode"
)
_assertErrorMsg(
    lambda(() ycString::Pad("a" 2 ?fill ""))
    "ycString::Pad: fill must be a single character"
    "pad: empty fill"
)

; ---- split ----
_assert(ycString::StrSplit("  a\tb\n c ") == list("a" "b" "c")  "strSplit: default whitespace")
_assert(ycString::StrSplit("") == nil  "strSplit: empty input")
_assert(ycString::StrSplit("a,,b" ?sep ",") == list("a" "" "b")  "strSplit: literal keeps empties")
_assert(ycString::StrSplit(",a," ?sep ",") == list("" "a" "")  "strSplit: literal edge empties")
_assert(ycString::StrSplit("a,,b" ?sep "," ?keepEmpty nil) == list("a" "b")  "strSplit: drop empties")
_assert(ycString::StrSplit("a1b22c" ?sep "[0-9]+" ?regex t) == list("a" "b" "c")  "strSplit: regex")
_assert(
    ycString::StrSplit(" a  b " ?sep "\\s+" ?regex t ?keepEmpty nil) == list("a" "b")
    "strSplit: regex drop empties"
)
_assertErrorMsg(
    lambda(() ycString::StrSplit("a" ?sep ""))
    "ycString::StrSplit: separator must not be empty"
    "strSplit: empty separator"
)
_assertErrorMsg(
    lambda(() ycString::StrSplit("a" ?regex t))
    "ycString::StrSplit: regex mode needs a non-empty pattern"
    "strSplit: regex without pattern"
)

; ---- join ----
_assert(ycString::StrJoin(list("a" "b" "c")) == "abc"  "strJoin: default")
_assert(ycString::StrJoin(list("a" "b") ?sep "-") == "a-b"  "strJoin: custom separator")
_assert(ycString::StrJoin(nil) == ""  "strJoin: empty list")
_assertErrorMsg(
    lambda(() ycString::StrJoin(list("a" 1)))
    "ycString::StrJoin: item #2 is not a string"
    "strJoin: non-string item"
)
_assertErrorMsg(
    lambda(() ycString::StrJoin("x"))
    "argument #1 should be a list"
    "strJoin: non-list"
)

; ---- startsWith / endsWith ----
_assert(ycString::StartsWith("abc" "ab")  "startsWith: hit")
_assert(ycString::StartsWith("abc" "")  "startsWith: empty prefix")
_assert(ycString::StartsWith("abc" "abcd") == nil  "startsWith: too long")
_assert(ycString::StartsWith("中文abc" "中文")  "startsWith: cjk")
_assert(ycString::EndsWith("abc" "bc")  "endsWith: hit")
_assert(ycString::EndsWith("abc" "")  "endsWith: empty suffix")
_assert(ycString::EndsWith("abc" "abcd") == nil  "endsWith: too long")
_assert(ycString::EndsWith("中文abc" "abc")  "endsWith: cjk")

; ---- replace ----
_assert(ycString::Replace("aaa" "a" "b") == "bbb"  "replace: literal all")
_assert(ycString::Replace("aaa" "aa" "b") == "ba"  "replace: non-overlap")
_assert(ycString::Replace("abc" "x" "y") == "abc"  "replace: no match")
_assert(ycString::Replace("a1b22c" "[0-9]+" "N" ?regex t) == "aNbNc"  "replace: regex")
_assert(ycString::Replace("baaacaa" "a+" "X" ?regex t) == "bXcX"  "replace: regex all")
_assertErrorMsg(
    lambda(() ycString::Replace("a" "" "b"))
    "ycString::Replace: search string must not be empty"
    "replace: empty search"
)
_assertErrorMsg(
    lambda(() ycString::Replace("a" "" "b" ?regex t))
    "ycString::Replace: pattern must not be empty"
    "replace: empty pattern"
)

; ---- count ----
_assert(ycString::Count("banana" "a") == 3  "count: literal")
_assert(ycString::Count("aaaa" "aa") == 2  "count: non-overlap")
_assert(ycString::Count("abc" "x") == 0  "count: none")
_assert(ycString::Count("banana" "a+" ?regex t) == 3  "count: regex")
_assertErrorMsg(
    lambda(() ycString::Count("a" ""))
    "ycString::Count: search string must not be empty"
    "count: empty search"
)

_TestCoreDone = t

; END
