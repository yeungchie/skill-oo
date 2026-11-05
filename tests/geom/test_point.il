_TestPointDone = nil

let((p)
    p = ycGeom::Point(1:2)
    _Assert(classOf(p) == findClass('ycGeom::Point)  "point: class identity")
    _Assert(floatp(p->x())  "point: x is float for integer input")
    _Assert(floatp(p->y())  "point: y is float for integer input")
    _Assert(p->x() == 1.0  "point: x value")
    _Assert(p->y() == 2.0  "point: y value")
    _Assert(p->toSkill() == list(1.0 2.0)  "point: toSkill")
    _Assert(printself(p) == "<ycGeom::Point x=1.0 y=2.0>"  "point: printself")
)

let((a b)
    a = ycGeom::Point(0:0)
    b = ycGeom::Point(3:4)
    _Assert(a->distanceTo(b) == 5.0  "point: distance")
    _Assert(a->midpoint(b)->toSkill() == list(1.5 2.0)  "point: midpoint")
    _Assert(a->translate(2 -3)->toSkill() == list(2.0 -3.0)  "point: translate")
    _Assert(a->equals(ycGeom::Point(0.0:0.0))  "point: equals")
    _Assert(!a->equals(b)  "point: not equals")
    _Assert(a->equals(ycGeom::Point(1e-10:0.0) ?eps 1e-9)  "point: equals eps")
    _Assert(ycGeom::Point(1e9:0)->equals(ycGeom::Point(list(1e9 + 1e-7 0)) ?eps 1e-9)
        "point: relative tolerance at large coordinate")
    _Assert(!ycGeom::Point(1e9:0)->equals(ycGeom::Point(list(1e9 + 1e-3 0)) ?eps 1e-9)
        "point: relative tolerance upper bound")
)

_AssertError(lambda(() ycGeom::Point(list("a" 2)) t)  "point: string x rejected")
_AssertError(lambda(() ycGeom::Point(list(1 "b")) t)  "point: string y rejected")
_AssertError(lambda(() ycGeom::Point(list(1 t)) t)  "point: symbol y rejected")
_AssertError(lambda(() ycGeom::Point(1:2)->distanceTo(1) t)  "point: non-Point distance rejected")
_AssertError(lambda(() ycGeom::Point(1:2)->equals(1) t)  "point: non-Point equals rejected")

let((p q)
    p = ycGeom::Point(1:2)
    q = ycGeom::Point(list(1 2))
    _Assert(q->toSkill() == list(1.0 2.0)  "point: list form")
    _Assert(q->equals(p)  "point: list form equals")
    _Assert(ycGeom::Point(p->toSkill())->equals(p)  "point: toSkill roundtrip")
)
_AssertError(lambda(() ycGeom::Point(1) t)  "point: one number rejected")
_AssertError(lambda(() ycGeom::Point(list(1 2 3)) t)  "point: long list rejected")
_AssertError(lambda(() ycGeom::Point(list("a" 2)) t)  "point: non-number pair rejected")

_TestChildDone = t

; END
