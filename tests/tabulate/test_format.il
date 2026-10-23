_TestFormatDone = nil

let((l_rows l_head)
    l_rows = list(list("a" 1) list("bb" 22))
    l_head = list("name" "n")

    ; ---- four formats ----
    _Assert(
        ycTabulate::Render(l_rows ?headers l_head)
            == "name  n\n----  --\na     1\nbb    22"
        "format: simple"
    )
    _Assert(
        ycTabulate::Render(l_rows ?headers l_head ?format "plain")
            == "name  n\na     1\nbb    22"
        "format: plain"
    )
    _Assert(
        ycTabulate::Render(l_rows ?headers l_head ?format "grid")
            == "+------+----+\n| name | n  |\n+======+====+\n| a    | 1  |\n+------+----+\n| bb   | 22 |\n+------+----+"
        "format: grid"
    )
    _Assert(
        ycTabulate::Render(l_rows ?headers l_head ?format "pipe")
            == "| name | n   |\n| :--- | :-- |\n| a    | 1   |\n| bb   | 22  |"
        "format: pipe"
    )
)

; ---- pipe alignment markers ----
_Assert(
    ycTabulate::Render(
        list(list("a" 1) list("bb" 22))
        ?headers list("name" "n")
        ?format "pipe"
        ?align list("left" "right")
    ) == "| name |   n |\n| :--- | --: |\n| a    |   1 |\n| bb   |  22 |"
    "format: pipe right"
)
_Assert(
    ycTabulate::Render(
        list(list("a" 1) list("bb" 22))
        ?headers list("name" "n")
        ?format "pipe"
        ?align "center"
    ) == "| name |  n  |\n| :--: | :-: |\n|  a   |  1  |\n|  bb  | 22  |"
    "format: pipe center"
)

; ---- multiline ----
_Assert(
    ycTabulate::Render(list(list("a\nb" "c")) ?headers list("h1" "h2"))
        == "h1  h2\n--  --\na   c\nb"
    "format: multiline simple"
)
_Assert(
    ycTabulate::Render(list(list("a\nb" "c|d")) ?headers list("h1" "h2") ?format "pipe")
        == "| h1     | h2   |\n| :----- | :--- |\n| a<br>b | c\\|d |"
    "format: multiline pipe"
)

_Assert(
    ycTabulate::Render(
        list(list("1.2" 10) list("22.345" 3.4))
        ?headers list("a" "b")
        ?format "pipe"
        ?align "decimal"
    ) == buildString(
        list(
            "|  a     |  b   |"
            "| -----: | ---: |"
            "|  1.2   | 10   |"
            "| 22.345 |  3.4 |"
        )
        intToChar(10)
    )
    "format: pipe decimal"
)

; ---- header only / no header ----
_Assert(
    ycTabulate::Render(nil ?headers list("a" "b"))
        == "a  b\n-  -"
    "format: header only simple"
)
_Assert(
    ycTabulate::Render(nil ?headers list("a" "b") ?format "grid")
        == "+---+---+\n| a | b |\n+===+===+"
    "format: header only grid"
)
_Assert(
    ycTabulate::Render(list(list("a" "b") list("cc" "d")) ?format "grid")
        == "+----+---+\n| a  | b |\n+----+---+\n| cc | d |\n+----+---+"
    "format: grid no header"
)
_Assert(
    ycTabulate::Render(list(list("a" "b"))) == "a  b"
    "format: plain no header"
)
_Assert(
    ycTabulate::Render(list(list("a" "b")) ?format "pipe") == "| a   | b   |"
    "format: pipe no header"
)

_TestFormatDone = t

; END
