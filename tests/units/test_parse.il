_TestParseDone = nil

procedure(_Near(g_a g_b n_tol "ggn")  ; -> t | nil
    ; 判断两数值是否在容差内（测试辅助）。
    ;
    ; **参数**
    ;   g_a    (num) - 值一
    ;   g_b    (num) - 值二
    ;   n_tol  (num) - 容差
    ;
    ; **返回**
    ;   (t|nil) - 差值不超过容差为 t
    abs(g_a - g_b) <= n_tol
)

; ---- 数值与前缀 ----
_Assert(_Near(car(ycUnits::Parse("1k")) 1000.0 1e-12)  "parse: k")
_Assert(_Near(car(ycUnits::Parse("2.5u")) 2.5e-6 1e-15)  "parse: u")
_Assert(_Near(car(ycUnits::Parse("4.7meg")) 4.7e6 1e-6)  "parse: meg")
_Assert(_Near(car(ycUnits::Parse("1e3")) 1000.0 1e-12)  "parse: exponent")
_Assert(_Near(car(ycUnits::Parse(".5k")) 500.0 1e-12)  "parse: leading dot")
_Assert(_Near(car(ycUnits::Parse("+1.5k")) 1500.0 1e-12)  "parse: plus")
_Assert(_Near(car(ycUnits::Parse("-2.5u")) -2.5e-6 1e-15)  "parse: negative")
_Assert(_Near(car(ycUnits::Parse("1.")) 1.0 1e-12)  "parse: trailing dot")
_Assert(_Near(car(ycUnits::Parse(" 1k ")) 1000.0 1e-12)  "parse: spaces")
_Assert(_Near(car(ycUnits::Parse("1e-3k")) 1.0 1e-12)  "parse: exponent prefix")
_Assert(_Near(car(ycUnits::Parse("1e3k")) 1e6 1e-6)  "parse: exponent kilo")
_Assert(_Near(car(ycUnits::Parse("1f")) 1e-15 1e-24)  "parse: femto")
_Assert(_Near(car(ycUnits::Parse("1T")) 1e12 1e-3)  "parse: tera")
_Assert(_Near(car(ycUnits::Parse("1G")) 1e9 1e-3)  "parse: giga")
_Assert(_Near(car(ycUnits::Parse("1milliF")) 0.001 1e-15)  "parse: milli alias")
_Assert(_Near(car(ycUnits::Parse("1megaHz")) 1e6 1e-6)  "parse: mega alias")

_Assert(_Near(car(ycUnits::Parse("1K")) 1000.0 1e-12)  "parse: K alias")
_Assert(_Near(car(ycUnits::Parse("5%")) 0.05 1e-15)  "parse: percent")
_Assert(cadr(ycUnits::Parse("5%")) == ""  "parse: percent unit")
_Assert(_Near(car(ycUnits::Parse("1 K")) 1.0 1e-12)  "parse: spaced K")
_Assert(cadr(ycUnits::Parse("1 K")) == "K"  "parse: spaced K unit")
_Assert(_Near(car(ycUnits::Parse("1uF")) 1e-6 1e-15)  "parse: uF")

; ---- 单位与歧义 ----
_Assert(cadr(ycUnits::Parse("1k")) == ""  "parse: no unit")
_Assert(cadr(ycUnits::Parse("1kHz")) == "Hz"  "parse: unit after prefix")
_Assert(cadr(ycUnits::Parse("1.5mF")) == "F"  "parse: mF")
_Assert(_Near(car(ycUnits::Parse("1.5mF")) 0.0015 1e-15)  "parse: mF value")
_Assert(cadr(ycUnits::Parse("1F")) == "F"  "parse: farad")
_Assert(_Near(car(ycUnits::Parse("1F")) 1.0 1e-12)  "parse: farad value")
_Assert(cadr(ycUnits::Parse("1 F")) == "F"  "parse: spaced unit")
_Assert(_Near(car(ycUnits::Parse("1 m")) 1.0 1e-12)  "parse: spaced meter")
_Assert(_Near(car(ycUnits::Parse("1m")) 0.001 1e-15)  "parse: milli")
_Assert(_Near(car(ycUnits::Parse("1 T")) 1.0 1e-12)  "parse: spaced tesla")
_Assert(cadr(ycUnits::Parse("1 T")) == "T"  "parse: spaced tesla unit")
_Assert(cadr(ycUnits::Parse("1x")) == "x"  "parse: unknown unit")
_Assert(_Near(car(ycUnits::Parse("1x")) 1.0 1e-12)  "parse: unknown unit value")

; ---- 便捷入口 ----
_Assert(_Near(ycUnits::ToNumber("2.5uF") 2.5e-6 1e-15)  "ToNumber")
_Assert(ycUnits::ToUnit("2.5uF") == "F"  "toUnit")

; ---- errors ----
_AssertErrorMsg(
    lambda(() ycUnits::Parse(""))
    "ycUnits::Parse: expected a number"
    "parse: empty"
)
_AssertErrorMsg(
    lambda(() ycUnits::Parse("abc"))
    "ycUnits::Parse: expected a number"
    "parse: non-number"
)
_AssertErrorMsg(
    lambda(() ycUnits::Parse("1e"))
    "ycUnits::Parse: invalid exponent"
    "parse: missing exponent"
)
_AssertErrorMsg(
    lambda(() ycUnits::Parse("1e+"))
    "ycUnits::Parse: invalid exponent"
    "parse: empty exponent"
)
_AssertErrorMsg(
    lambda(() ycUnits::Parse("1.2.3"))
    "ycUnits::Parse: invalid number"
    "parse: double dot"
)
_AssertErrorMsg(
    lambda(() ycUnits::Parse("1k F"))
    "ycUnits::Parse: whitespace inside unit"
    "parse: unit whitespace"
)
_AssertErrorMsg(
    lambda(() ycUnits::Parse(5))
    "argument #1 should be a string"
    "parse: non-string"
)
_AssertErrorMsg(
    lambda(() ycUnits::ToNumber(5))
    "argument #1 should be a string"
    "ToNumber: non-string"
)
_AssertErrorMsg(
    lambda(() ycUnits::ToUnit(5))
    "argument #1 should be a string"
    "toUnit: non-string"
)

_TestParseDone = t

; END
