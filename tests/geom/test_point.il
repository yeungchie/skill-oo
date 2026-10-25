_TestPointDone = nil

let((g_p)
    g_p = ycGeom::Point(1 2)
    _Assert(classOf(g_p) == findClass('ycGeom::Point)  "point: class identity")
    _Assert(floatp(g_p->x())  "point: x is float for integer input")
    _Assert(floatp(g_p->y())  "point: y is float for integer input")
    _Assert(g_p->x() == 1.0  "point: x value")
    _Assert(g_p->y() == 2.0  "point: y value")
    _Assert(g_p->toSkill() == list(1.0 2.0)  "point: toSkill")
    _Assert(printself(g_p) == "<ycGeom::Point x=1.0 y=2.0>"  "point: printself")
)

let((g_a g_b)
    g_a = ycGeom::Point(0 0)
    g_b = ycGeom::Point(3 4)
    _Assert(g_a->distanceTo(g_b) == 5.0  "point: distance")
    _Assert(g_a->midpoint(g_b)->toSkill() == list(1.5 2.0)  "point: midpoint")
    _Assert(g_a->translate(2 -3)->toSkill() == list(2.0 -3.0)  "point: translate")
    _Assert(g_a->equals(ycGeom::Point(0.0 0.0))  "point: equals")
    _Assert(!g_a->equals(g_b)  "point: not equals")
    _Assert(g_a->equals(ycGeom::Point(1e-10 0.0) ?eps 1e-9)  "point: equals eps")
)

_AssertError(lambda(() ycGeom::Point("a" 2) t)  "point: string x rejected")
_AssertError(lambda(() ycGeom::Point(1 "b") t)  "point: string y rejected")
_AssertError(lambda(() ycGeom::Point(1 t) t)  "point: symbol y rejected")
_AssertError(lambda(() ycGeom::Point(1 2)->distanceTo(1) t)  "point: non-Point distance rejected")
_AssertError(lambda(() ycGeom::Point(1 2)->equals(1) t)  "point: non-Point equals rejected")

_TestPointDone = t

; END
