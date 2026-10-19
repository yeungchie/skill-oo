_TestParseDone = nil

procedure(_near(g_a g_b n_tol "ggn")  ; -> t | nil
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
_assert(_near(car(ycUnits::parse("1k")) 1000.0 1e-12)  "parse: k")
_assert(_near(car(ycUnits::parse("2.5u")) 2.5e-6 1e-15)  "parse: u")
_assert(_near(car(ycUnits::parse("4.7meg")) 4.7e6 1e-6)  "parse: meg")
_assert(_near(car(ycUnits::parse("1e3")) 1000.0 1e-12)  "parse: exponent")
_assert(_near(car(ycUnits::parse(".5k")) 500.0 1e-12)  "parse: leading dot")
_assert(_near(car(ycUnits::parse("+1.5k")) 1500.0 1e-12)  "parse: plus")
_assert(_near(car(ycUnits::parse("-2.5u")) -2.5e-6 1e-15)  "parse: negative")
_assert(_near(car(ycUnits::parse("1.")) 1.0 1e-12)  "parse: trailing dot")
_assert(_near(car(ycUnits::parse(" 1k ")) 1000.0 1e-12)  "parse: spaces")
_assert(_near(car(ycUnits::parse("1e-3k")) 1.0 1e-12)  "parse: exponent prefix")
_assert(_near(car(ycUnits::parse("1e3k")) 1e6 1e-6)  "parse: exponent kilo")
_assert(_near(car(ycUnits::parse("1f")) 1e-15 1e-24)  "parse: femto")
_assert(_near(car(ycUnits::parse("1T")) 1e12 1e-3)  "parse: tera")
_assert(_near(car(ycUnits::parse("1G")) 1e9 1e-3)  "parse: giga")
_assert(_near(car(ycUnits::parse("1milliF")) 0.001 1e-15)  "parse: milli alias")
_assert(_near(car(ycUnits::parse("1megaHz")) 1e6 1e-6)  "parse: mega alias")

; ---- 单位与歧义 ----
_assert(cadr(ycUnits::parse("1k")) == ""  "parse: no unit")
_assert(cadr(ycUnits::parse("1kHz")) == "Hz"  "parse: unit after prefix")
_assert(cadr(ycUnits::parse("1.5mF")) == "F"  "parse: mF")
_assert(_near(car(ycUnits::parse("1.5mF")) 0.0015 1e-15)  "parse: mF value")
_assert(cadr(ycUnits::parse("1F")) == "F"  "parse: farad")
_assert(_near(car(ycUnits::parse("1F")) 1.0 1e-12)  "parse: farad value")
_assert(cadr(ycUnits::parse("1 F")) == "F"  "parse: spaced unit")
_assert(_near(car(ycUnits::parse("1 m")) 1.0 1e-12)  "parse: spaced meter")
_assert(_near(car(ycUnits::parse("1m")) 0.001 1e-15)  "parse: milli")
_assert(_near(car(ycUnits::parse("1 T")) 1.0 1e-12)  "parse: spaced tesla")
_assert(cadr(ycUnits::parse("1 T")) == "T"  "parse: spaced tesla unit")
_assert(cadr(ycUnits::parse("1x")) == "x"  "parse: unknown unit")
_assert(_near(car(ycUnits::parse("1x")) 1.0 1e-12)  "parse: unknown unit value")

; ---- 便捷入口 ----
_assert(_near(ycUnits::toNumber("2.5uF") 2.5e-6 1e-15)  "toNumber")
_assert(ycUnits::toUnit("2.5uF") == "F"  "toUnit")

; ---- errors ----
_assertErrorMsg(
    lambda(() ycUnits::parse(""))
    "ycUnits::parse: expected a number"
    "parse: empty"
)
_assertErrorMsg(
    lambda(() ycUnits::parse("abc"))
    "ycUnits::parse: expected a number"
    "parse: non-number"
)
_assertErrorMsg(
    lambda(() ycUnits::parse("1e"))
    "ycUnits::parse: invalid exponent"
    "parse: missing exponent"
)
_assertErrorMsg(
    lambda(() ycUnits::parse("1e+"))
    "ycUnits::parse: invalid exponent"
    "parse: empty exponent"
)
_assertErrorMsg(
    lambda(() ycUnits::parse("1.2.3"))
    "ycUnits::parse: invalid number"
    "parse: double dot"
)
_assertErrorMsg(
    lambda(() ycUnits::parse("1k F"))
    "ycUnits::parse: whitespace inside unit"
    "parse: unit whitespace"
)
_assertErrorMsg(
    lambda(() ycUnits::parse(5))
    "argument #1 should be a string"
    "parse: non-string"
)
_assertErrorMsg(
    lambda(() ycUnits::toNumber(5))
    "argument #1 should be a string"
    "toNumber: non-string"
)
_assertErrorMsg(
    lambda(() ycUnits::toUnit(5))
    "argument #1 should be a string"
    "toUnit: non-string"
)

_TestParseDone = t

; END
