_TestRectDone = nil

let((g_r)
    g_r = ycGeom::Rect(ycGeom::Point(10 4) ycGeom::Point(2 0))
    _Assert(classOf(g_r) == findClass('ycGeom::Rect)  "rect: class identity")
    _Assert(g_r->xmin() == 2.0  "rect: xmin")
    _Assert(g_r->ymin() == 0.0  "rect: ymin")
    _Assert(g_r->xmax() == 10.0  "rect: xmax")
    _Assert(g_r->ymax() == 4.0  "rect: ymax")
    _Assert(g_r->width() == 8.0  "rect: width")
    _Assert(g_r->height() == 4.0  "rect: height")
    _Assert(g_r->area() == 32.0  "rect: area")
    _Assert(g_r->center()->toSkill() == list(6.0 2.0)  "rect: center")
    _Assert(g_r->bBox() == list(list(2.0 0.0) list(10.0 4.0))  "rect: bBox")
    _Assert(g_r->toSkill() == list(list(2.0 0.0) list(10.0 4.0))  "rect: toSkill")
    _Assert(g_r->contains(ycGeom::Point(2 0))  "rect: contains min corner")
    _Assert(g_r->contains(ycGeom::Point(10 4))  "rect: contains max corner")
    _Assert(g_r->contains(ycGeom::Point(6 2))  "rect: contains inside")
    _Assert(!g_r->contains(ycGeom::Point(2.1 5))  "rect: outside")
)

let((g_r)
    g_r = ycGeom::Rect(list(list(0 0) list(5 3)))
    _Assert(g_r->toSkill() == list(list(0.0 0.0) list(5.0 3.0))  "rect: nested pair form")
)

let((g_r)
    g_r = ycGeom::Rect(0 0 5 3)
    _Assert(g_r->width() == 5.0  "rect: four-number form")
)

let((g_r)
    g_r = ycGeom::Rect(ycGeom::Point(1 1) ycGeom::Point(1 1))
    _Assert(g_r->width() == 0.0  "rect: degenerate width")
    _Assert(g_r->height() == 0.0  "rect: degenerate height")
    _Assert(g_r->area() == 0.0  "rect: degenerate area")
)

_AssertError(lambda(() ycGeom::Rect(1 2 3) t)  "rect: three coordinates rejected")
_AssertError(lambda(() ycGeom::Rect("a" "b") t)  "rect: non-point rejected")
_AssertError(lambda(() ycGeom::Rect(1 2 3 "x") t)  "rect: nonnumeric coordinate rejected")
_AssertError(lambda(() ycGeom::Rect(0 0 1 1)->contains(1) t)  "rect: bad contains type")

_TestRectDone = t

; END
