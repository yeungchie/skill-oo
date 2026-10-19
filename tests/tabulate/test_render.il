_TestRenderDone = nil

; ---- cells and numeric formats ----
_assert(ycTabulate::render(list(list("a" 1))) == "a  1"  "render: basic")
_assert(ycTabulate::render(list(list(1.23456 2.0))) == "1.23456  2"  "render: floats default")
_assert(
    ycTabulate::render(list(list(1.23456 2.0)) ?floatFmt "%.2f") == "1.23  2.00"
    "render: floats custom"
)
_assert(
    ycTabulate::render(list(list(nil 'sym "s")) ?headers list("a" "b" "c") ?missingVal "NA" ?format "grid")
        == "+----+-----+---+\n| a  | b   | c |\n+====+=====+===+\n| NA | sym | s |\n+----+-----+---+"
    "render: missing and symbol"
)

; ---- alignment ----
_assert(
    ycTabulate::render(list(list("a" 1) list("bb" 22)) ?headers list("name" "n") ?align list("left" "right"))
        == "name   n\n----  --\na      1\nbb    22"
    "render: right align"
)
_assert(
    ycTabulate::render(list(list("a" 1) list("bb" 22)) ?headers list("name" "n") ?align "center")
        == "name  n\n----  --\n a    1\n bb   22"
    "render: center align"
)
_assert(
    ycTabulate::render(
        list(list("1.2" "10") list("22.345" "3.4") list("5" "6.78"))
        ?headers list("a" "b")
        ?align "decimal"
    ) == " a       b\n------  -----\n 1.2    10\n22.345   3.4\n 5       6.78"
    "render: decimal align"
)

; ---- wrapping and cjk ----
_assert(
    ycTabulate::render(
        list(list("alpha beta" "x") list("c" "y"))
        ?headers list("long" "z")
        ?maxColWidth 5
    ) == "long   z\n-----  -\nalpha  x\nbeta\nc      y"
    "render: maxColWidth"
)
_assert(
    ycTabulate::render(list(list("中文" 1) list("a" 2)) ?headers list("名" "值") ?format "grid")
        == "+------+----+\n| 名   | 值 |\n+======+====+\n| 中文 | 1  |\n+------+----+\n| a    | 2  |\n+------+----+"
    "render: cjk widths"
)
_assert(
    ycTabulate::render(list(list("中文") list("a")) ?format "grid" ?unit "char")
        == "+----+\n| 中文 |\n+----+\n| a  |\n+----+"
    "render: char unit"
)

_assert(
    ycTabulate::render(list(list(1 2)) ?headers list("header" "b") ?maxColWidth 3)
        == buildString(list("hea  b" "der" "---  -" "1    2") intToChar(10))
    "render: header wrap"
)

; ---- empty and no columns ----
_assert(ycTabulate::render(nil) == ""  "render: no rows")
_assert(ycTabulate::render(nil ?headers nil) == ""  "render: no columns")

; ---- errors ----
_assertErrorMsg(
    lambda(() ycTabulate::render("x"))
    "argument #1 should be a list"
    "render: non-list rows"
)
_assertErrorMsg(
    lambda(() ycTabulate::render(list("x")))
    "ycTabulate::render: row 1 is not a list"
    "render: non-list row"
)
_assertErrorMsg(
    lambda(() ycTabulate::render(list(list("a") list("b" "c"))))
    "ycTabulate::render: row 2 has 2 cells, expected 1"
    "render: ragged rows"
)
_assertErrorMsg(
    lambda(() ycTabulate::render(list(list("a")) ?headers list("x" "y")))
    "ycTabulate::render: row 1 has 1 cells, expected 2"
    "render: header width"
)
_assertErrorMsg(
    lambda(() ycTabulate::render(list(list("a")) ?format "html"))
    "ycTabulate::render: unknown format"
    "render: format"
)
_assertErrorMsg(
    lambda(() ycTabulate::render(list(list("a")) ?align "justify"))
    "ycTabulate::render: unknown align"
    "render: align"
)
_assertErrorMsg(
    lambda(() ycTabulate::render(list(list("a")) ?align list("left" "right")))
    "ycTabulate::render: align list has 2 entries"
    "render: align count"
)
_assertErrorMsg(
    lambda(() ycTabulate::render(list(list("a")) ?maxColWidth 0))
    "ycTabulate::render: maxColWidth must be"
    "render: maxColWidth"
)
_assertErrorMsg(
    lambda(() ycTabulate::render(list(list("a")) ?floatFmt "%d"))
    "ycTabulate::render: invalid floatFmt"
    "render: floatFmt"
)
_assertErrorMsg(
    lambda(() ycTabulate::render(list(list("a")) ?unit "px"))
    "ycTabulate::render: unknown unit"
    "render: unit"
)
_assertErrorMsg(
    lambda(() ycTabulate::render(list(list("a")) ?ambiguous 3))
    "ycTabulate::render: ambiguous must be"
    "render: ambiguous"
)

_TestRenderDone = t

; END
