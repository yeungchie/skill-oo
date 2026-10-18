_TestCoreDone = nil

; ---- trim ----
_assert(ycString::trim("  ab  ") == "ab"  "trim: spaces")
_assert(ycString::trim("xxabxx" ?chars "x") == "ab"  "trim: custom chars")
_assert(ycString::trim("xxx" ?chars "x") == ""  "trim: all stripped")
_assert(ycString::trimStart("  ab  ") == "ab  "  "trimStart: leading only")
_assert(ycString::trimEnd("  ab  ") == "  ab"  "trimEnd: trailing only")
_assert(ycString::trim("中中a中中" ?chars "中") == "a"  "trim: cjk chars")

; ---- width ----
_assert(ycString::width("中文") == 4  "width: display")
_assert(ycString::width("中文" ?unit "char") == 2  "width: char unit")
_assert(ycString::width("") == 0  "width: empty")
_assertErrorMsg(
    lambda(() ycString::width("a" ?unit "px"))
    "ycString::width: unknown unit"
    "width: unknown unit"
)

; ---- pad ----
_assert(ycString::pad("ab" 5 ?fill "-") == "ab---"  "pad: end default side")
_assert(ycString::pad("ab" 5 ?side "start" ?fill "-") == "---ab"  "pad: start side")
_assert(ycString::pad("中" 4 ?unit "char" ?fill "-") == "中---"  "pad: char unit")
_assert(ycString::width(ycString::pad("中" 4)) == 4  "pad: display unit")
_assert(ycString::pad("ab" 1) == "ab"  "pad: no truncation")
_assert(ycString::pad("a" 2 ?unit "char" ?fill "中") == "a中"  "pad: wide fill in char mode")
_assertErrorMsg(
    lambda(() ycString::pad("a" -1))
    "ycString::pad: width must be"
    "pad: negative width"
)
_assertErrorMsg(
    lambda(() ycString::pad("a" 2 ?fill "中"))
    "ycString::pad: fill must be single width"
    "pad: wide fill in display mode"
)
_assertErrorMsg(
    lambda(() ycString::pad("a" 2 ?fill ""))
    "ycString::pad: fill must be a single character"
    "pad: empty fill"
)

; ---- split ----
_assert(ycString::strSplit("  a\tb\n c ") == list("a" "b" "c")  "strSplit: default whitespace")
_assert(ycString::strSplit("") == nil  "strSplit: empty input")
_assert(ycString::strSplit("a,,b" ?sep ",") == list("a" "" "b")  "strSplit: literal keeps empties")
_assert(ycString::strSplit(",a," ?sep ",") == list("" "a" "")  "strSplit: literal edge empties")
_assert(ycString::strSplit("a,,b" ?sep "," ?keepEmpty nil) == list("a" "b")  "strSplit: drop empties")
_assert(ycString::strSplit("a1b22c" ?sep "[0-9]+" ?regex t) == list("a" "b" "c")  "strSplit: regex")
_assert(
    ycString::strSplit(" a  b " ?sep "\\s+" ?regex t ?keepEmpty nil) == list("a" "b")
    "strSplit: regex drop empties"
)
_assertErrorMsg(
    lambda(() ycString::strSplit("a" ?sep ""))
    "ycString::strSplit: separator must not be empty"
    "strSplit: empty separator"
)
_assertErrorMsg(
    lambda(() ycString::strSplit("a" ?regex t))
    "ycString::strSplit: regex mode needs a non-empty pattern"
    "strSplit: regex without pattern"
)

; ---- join ----
_assert(ycString::strJoin(list("a" "b" "c")) == "abc"  "strJoin: default")
_assert(ycString::strJoin(list("a" "b") ?sep "-") == "a-b"  "strJoin: custom separator")
_assert(ycString::strJoin(nil) == ""  "strJoin: empty list")
_assertErrorMsg(
    lambda(() ycString::strJoin(list("a" 1)))
    "ycString::strJoin: item #2 is not a string"
    "strJoin: non-string item"
)
_assertErrorMsg(
    lambda(() ycString::strJoin("x"))
    "argument #1 should be a list"
    "strJoin: non-list"
)

; ---- startsWith / endsWith ----
_assert(ycString::startsWith("abc" "ab")  "startsWith: hit")
_assert(ycString::startsWith("abc" "")  "startsWith: empty prefix")
_assert(ycString::startsWith("abc" "abcd") == nil  "startsWith: too long")
_assert(ycString::startsWith("中文abc" "中文")  "startsWith: cjk")
_assert(ycString::endsWith("abc" "bc")  "endsWith: hit")
_assert(ycString::endsWith("abc" "")  "endsWith: empty suffix")
_assert(ycString::endsWith("abc" "abcd") == nil  "endsWith: too long")
_assert(ycString::endsWith("中文abc" "abc")  "endsWith: cjk")

; ---- replace ----
_assert(ycString::replace("aaa" "a" "b") == "bbb"  "replace: literal all")
_assert(ycString::replace("aaa" "aa" "b") == "ba"  "replace: non-overlap")
_assert(ycString::replace("abc" "x" "y") == "abc"  "replace: no match")
_assert(ycString::replace("a1b22c" "[0-9]+" "N" ?regex t) == "aNbNc"  "replace: regex")
_assert(ycString::replace("baaacaa" "a+" "X" ?regex t) == "bXcX"  "replace: regex all")
_assertErrorMsg(
    lambda(() ycString::replace("a" "" "b"))
    "ycString::replace: search string must not be empty"
    "replace: empty search"
)
_assertErrorMsg(
    lambda(() ycString::replace("a" "" "b" ?regex t))
    "ycString::replace: pattern must not be empty"
    "replace: empty pattern"
)

; ---- count ----
_assert(ycString::count("banana" "a") == 3  "count: literal")
_assert(ycString::count("aaaa" "aa") == 2  "count: non-overlap")
_assert(ycString::count("abc" "x") == 0  "count: none")
_assert(ycString::count("banana" "a+" ?regex t) == 3  "count: regex")
_assertErrorMsg(
    lambda(() ycString::count("a" ""))
    "ycString::count: search string must not be empty"
    "count: empty search"
)

_TestCoreDone = t

; END
