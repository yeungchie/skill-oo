;--------------------------
; Program  : ycCsv tests(test_render.il)
; Language : Cadence Skill
;--------------------------

let((t_v t_expected)
    t_v = ycCsv::Decode("name,qty\napple,3\n" ?header t)
    t_expected = ycTabulate::Render(list(list("apple" "3")) ?headers list("name" "qty"))
    _Assert(t_v->render() == t_expected  "render: basic table")
    _Assert(t_v->render(?format "grid" ?align "right") ==
        ycTabulate::Render(list(list("apple" "3")) ?headers list("name" "qty") ?format "grid" ?align "right")
        "render: format and align"
    )
)

let((t_v)
    t_v = ycCsv::Decode("a,b\n1\n" ?header t)
    _Assert(t_v->cell(1 2) == ycCodec::Missing  "render: fixture has Missing cell")
    _Assert(t_v->render(?missingVal "-") ==
        ycTabulate::Render(list(list("1" "-")) ?headers list("a" "b") ?missingVal "-")
        "render: pads Missing cells"
    )
)

let((t_v)
    t_v = ycCsv::Decode("a,b\nc\n")
    _Assert(t_v->render() ==
        ycTabulate::Render(list(list("a" "b") list("c" "")))
        "render: pads ragged rows"
    )
)

let((t_v)
    t_v = ycCsv::Decode("a\nlong text\n" ?header t)
    _Assert(t_v->render(?maxColWidth 4) ==
        ycTabulate::Render(list(list("long text")) ?headers list("a") ?maxColWidth 4)
        "render: forwards maxColWidth"
    )
)

let((t_v)
    t_v = ycCsv::Decode("name,qty\n中,3\n" ?header t)
    _Assert(t_v->render(?unit "char") ==
        ycTabulate::Render(list(list("中" "3")) ?headers list("name" "qty") ?unit "char")
        "render: forwards unit"
    )
    _Assert(t_v->render(?ambiguous 2) ==
        ycTabulate::Render(list(list("中" "3")) ?headers list("name" "qty") ?ambiguous 2)
        "render: forwards ambiguous"
    )
)

_Assert(ycCsv::Decode("")->render() == ""  "render: empty table")
_Assert(ycCsv::Decode("")->print() == t  "print: empty table returns t")
_AssertError(lambda(() ycCsv::Decode("a\n1\n" ?header t)->render(?format "xml"))
    "render: invalid format forwards")
_AssertError(lambda(() ycCsv::Decode("a\n1\n" ?header t)->print(?format "xml"))
    "print: options forward to render")

_TestRenderDone = t

; END
