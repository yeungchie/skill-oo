_TestRenderDone = nil

; ---- cells and numeric formats ----
_Assert(ycTabulate::Render(list(list("a" 1))) == "a  1"  "render: basic")
_Assert(ycTabulate::Render(list(list(1.23456 2.0))) == "1.23456  2"  "render: floats default")
_Assert(
    ycTabulate::Render(list(list(1.23456 2.0)) ?floatFmt "%.2f") == "1.23  2.00"
    "render: floats custom"
)
_Assert(
    ycTabulate::Render(list(list(nil 'sym "s")) ?headers list("a" "b" "c") ?missingVal "NA" ?format "grid")
        == "+----+-----+---+\n| a  | b   | c |\n+====+=====+===+\n| NA | sym | s |\n+----+-----+---+"
    "render: missing and symbol"
)

; ---- alignment ----
_Assert(
    ycTabulate::Render(list(list("a" 1) list("bb" 22)) ?headers list("name" "n") ?align list("left" "right"))
        == "name   n\n----  --\na      1\nbb    22"
    "render: right align"
)
_Assert(
    ycTabulate::Render(list(list("a" 1) list("bb" 22)) ?headers list("name" "n") ?align "center")
        == "name  n\n----  --\n a    1\n bb   22"
    "render: center align"
)
_Assert(
    ycTabulate::Render(
        list(list("1.2" "10") list("22.345" "3.4") list("5" "6.78"))
        ?headers list("a" "b")
        ?align "decimal"
    ) == " a       b\n------  -----\n 1.2    10\n22.345   3.4\n 5       6.78"
    "render: decimal align"
)

; ---- wrapping and cjk ----
_Assert(
    ycTabulate::Render(
        list(list("alpha beta" "x") list("c" "y"))
        ?headers list("long" "z")
        ?maxColWidth 5
    ) == "long   z\n-----  -\nalpha  x\nbeta\nc      y"
    "render: maxColWidth"
)
_Assert(
    ycTabulate::Render(list(list("中文" 1) list("a" 2)) ?headers list("名" "值") ?format "grid")
        == "+------+----+\n| 名   | 值 |\n+======+====+\n| 中文 | 1  |\n+------+----+\n| a    | 2  |\n+------+----+"
    "render: cjk widths"
)
_Assert(
    ycTabulate::Render(list(list("中文") list("a")) ?format "grid" ?unit "char")
        == "+----+\n| 中文 |\n+----+\n| a  |\n+----+"
    "render: char unit"
)

_Assert(
    ycTabulate::Render(list(list(1 2)) ?headers list("header" "b") ?maxColWidth 3)
        == buildString(list("hea  b" "der" "---  -" "1    2") intToChar(10))
    "render: header wrap"
)

; ---- empty and no columns ----
_Assert(ycTabulate::Render(nil) == ""  "render: no rows")
_Assert(ycTabulate::Render(nil ?headers nil) == ""  "render: no columns")

; ---- errors ----
_AssertErrorMsg(
    lambda(() ycTabulate::Render("x"))
    "argument #1 should be a list"
    "render: non-list rows"
)
_AssertErrorMsg(
    lambda(() ycTabulate::Render(list("x")))
    "ycTabulate::Render: row 1 is not a list"
    "render: non-list row"
)
_AssertErrorMsg(
    lambda(() ycTabulate::Render(list(list("a") list("b" "c"))))
    "ycTabulate::Render: row 2 has 2 cells, expected 1"
    "render: ragged rows"
)
_AssertErrorMsg(
    lambda(() ycTabulate::Render(list(list("a")) ?headers list("x" "y")))
    "ycTabulate::Render: row 1 has 1 cells, expected 2"
    "render: header width"
)
_AssertErrorMsg(
    lambda(() ycTabulate::Render(list(list("a")) ?format "html"))
    "ycTabulate::Render: unknown format"
    "render: format"
)
_AssertErrorMsg(
    lambda(() ycTabulate::Render(list(list("a")) ?align "justify"))
    "ycTabulate::Render: unknown align"
    "render: align"
)
_AssertErrorMsg(
    lambda(() ycTabulate::Render(list(list("a")) ?align list("left" "right")))
    "ycTabulate::Render: align list has 2 entries"
    "render: align count"
)
_AssertErrorMsg(
    lambda(() ycTabulate::Render(list(list("a")) ?maxColWidth 0))
    "ycTabulate::Render: maxColWidth must be"
    "render: maxColWidth"
)
_AssertErrorMsg(
    lambda(() ycTabulate::Render(list(list("a")) ?maxColWidth 3.5))
    "ycTabulate::Render: maxColWidth must be"
    "render: float maxColWidth"
)

_AssertErrorMsg(
    lambda(() ycTabulate::Render(list(list("a")) ?floatFmt "%d"))
    "ycTabulate::Render: invalid floatFmt"
    "render: floatFmt"
)
_AssertErrorMsg(
    lambda(() ycTabulate::Render(list(list("a")) ?unit "px"))
    "ycTabulate::Render: unknown unit"
    "render: unit"
)
_AssertErrorMsg(
    lambda(() ycTabulate::Render(list(list("a")) ?ambiguous 3))
    "ycTabulate::Render: ambiguous must be"
    "render: ambiguous"
)
_AssertErrorMsg(
    lambda(() ycTabulate::Render(list(list("a")) ?headers "x"))
    "ycTabulate::Render: headers must be"
    "render: headers type"
)
_AssertErrorMsg(
    lambda(() ycTabulate::Render(list(list("a")) ?align 1))
    "ycTabulate::Render: align must be"
    "render: align type"
)
_AssertErrorMsg(
    lambda(() ycTabulate::Render(list(list("a")) ?floatFmt 1))
    "argument for keyword ?floatFmt should be a string"
    "render: floatFmt type"
)
_AssertErrorMsg(
    lambda(() ycTabulate::Render(list(list("a")) ?missingVal 1))
    "argument for keyword ?missingVal should be a string"
    "render: missingVal type"
)

_TestRenderDone = t

; END
