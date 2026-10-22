;--------------------------
; Program  : ycCsv tests(test_render.il)
; Language : Cadence Skill
;--------------------------

let((t_v t_expected)
    t_v = ycCsv::decode("name,qty\napple,3\n" ?header t)
    t_expected = ycTabulate::render(list(list("apple" "3")) ?headers list("name" "qty"))
    _assert(t_v->render() == t_expected  "render: basic table")
    _assert(t_v->render(?format "grid" ?align "right") ==
        ycTabulate::render(list(list("apple" "3")) ?headers list("name" "qty") ?format "grid" ?align "right")
        "render: format and align"
    )
)

let((t_v)
    t_v = ycCsv::decode("a,b\n1\n" ?header t)
    _assert(t_v->cell(1 2) == ycCodec:::Missing  "render: fixture has Missing cell")
    _assert(t_v->render(?missingVal "-") ==
        ycTabulate::render(list(list("1" "-")) ?headers list("a" "b") ?missingVal "-")
        "render: pads Missing cells"
    )
)

let((t_v)
    t_v = ycCsv::decode("a,b\nc\n")
    _assert(t_v->render() ==
        ycTabulate::render(list(list("a" "b") list("c" "")))
        "render: pads ragged rows"
    )
)

let((t_v)
    t_v = ycCsv::decode("a\nlong text\n" ?header t)
    _assert(t_v->render(?maxColWidth 4) ==
        ycTabulate::render(list(list("long text")) ?headers list("a") ?maxColWidth 4)
        "render: forwards maxColWidth"
    )
)

_assert(ycCsv::decode("")->render() == ""  "render: empty table")
_assert(ycCsv::decode("")->print() == t  "print: empty table returns t")
_assertError(lambda(() ycCsv::decode("a\n1\n" ?header t)->render(?format "xml"))
    "render: invalid format forwards")
_assertError(lambda(() ycCsv::decode("a\n1\n" ?header t)->print(?format "xml"))
    "print: options forward to render")

_TestRenderDone = t

; END
