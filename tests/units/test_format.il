_TestFormatDone = nil

; ---- 基本 ----
_Assert(ycUnits::Format(1234) == "1.234k"  "format: kilo")
_Assert(ycUnits::Format(0) == "0"  "format: zero")
_Assert(ycUnits::Format(-2.5e-6) == "-2.5u"  "format: negative micro")
_Assert(ycUnits::Format(1000) == "1k"  "format: exact kilo")
_Assert(ycUnits::Format(1e6) == "1M"  "format: mega")
_Assert(ycUnits::Format(1e-6) == "1u"  "format: micro")
_Assert(ycUnits::Format(1e-3) == "1m"  "format: milli")
_Assert(ycUnits::Format(1e-4) == "100u"  "format: engineering exponent")
_Assert(ycUnits::Format(999) == "999"  "format: below kilo")
_Assert(ycUnits::Format(1e-24) == "1y"  "format: yocto")
_Assert(ycUnits::Format(1e24) == "1Y"  "format: yotta")
_Assert(ycUnits::Format(1e-30) == "1e-30"  "format: below range")
_Assert(ycUnits::Format(1e30) == "1e+30"  "format: above range")

; ---- 精度与进位 ----
_Assert(ycUnits::Format(1.23456789) == "1.23457"  "format: default precision")
_Assert(ycUnits::Format(1234 ?precision 3) == "1.23k"  "format: precision")
_Assert(ycUnits::Format(12345 ?precision 3) == "12.3k"  "format: precision two digits")
_Assert(ycUnits::Format(999.9 ?precision 3) == "1k"  "format: carry")
_Assert(ycUnits::Format(999900 ?precision 3) == "1M"  "format: carry twice")
_Assert(ycUnits::Format(0.0009999 ?precision 3) == "1m"  "format: carry down")
_Assert(ycUnits::Format(999.9) == "999.9"  "format: no carry default")

; ---- 单位 ----
_Assert(ycUnits::Format(2.5e-6 ?unit "F") == "2.5uF"  "format: unit")
_Assert(ycUnits::Format(0 ?unit "F") == "0F"  "format: zero unit")
_Assert(ycUnits::Format(1234 ?unit "Ω") == "1.234kΩ"  "format: cjk unit")
_Assert(ycUnits::Format(-1234) == "-1.234k"  "format: negative")

; ---- errors ----
_AssertErrorMsg(
    lambda(() ycUnits::Format("x"))
    "argument #1 should be a number"
    "format: non-number"
)
_AssertErrorMsg(
    lambda(() ycUnits::Format(1 ?unit 5))
    "argument for keyword ?unit should be a string"
    "format: unit type"
)
_AssertErrorMsg(
    lambda(() ycUnits::Format(1 ?precision 0))
    "ycUnits::Format: precision must be"
    "format: precision zero"
)
_AssertErrorMsg(
    lambda(() ycUnits::Format(1 ?precision 16))
    "ycUnits::Format: precision must be"
    "format: precision high"
)
_AssertErrorMsg(
    lambda(() ycUnits::Format(1 ?precision 2.5))
    "argument for keyword ?precision should be an integer"
    "format: precision float"
)

_TestFormatDone = t

; END
