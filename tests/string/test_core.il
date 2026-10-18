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

_TestCoreDone = t

; END
