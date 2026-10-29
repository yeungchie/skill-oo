_TestPathDone = nil

let((g_p g_s g_l)
    g_p = ycGeom::Path(list(0:0 10:0) ?width 2)
    _Assert(classOf(g_p) == findClass('ycGeom::Path)  "path: class identity")
    _Assert(g_p->width() == 2.0  "path: width")
    _Assert(!g_p->isClosed()  "path: open")
    _Assert(abs(g_p->area() - 20.0) <= 1e-9  "path: butt rectangle area")
    _Assert(g_p->bBox() == list(list(0.0 -1.0) list(10.0 1.0))
        "path: butt rectangle bBox")

    g_s = ycGeom::Path(list(0:0 10:0 10:10 0:10 0:0) ?width 2)
    _Assert(g_s->isClosed()  "path: closed square")
    _Assert(abs(g_s->area() - 80.0) <= 1e-9  "path: miter ring area")
    _Assert(g_s->bBox() == list(list(-1.0 -1.0) list(11.0 11.0))
        "path: miter ring bBox")

    g_l = ycGeom::Path(list(0:0 10:0 10:10) ?width 2)
    _Assert(abs(g_l->area() - 40.0) <= 1e-9  "path: miter L area")
)

_AssertError(lambda(() ycGeom::Path(list(0:0 10:0)) t)  "path: width required")
_AssertError(lambda(() ycGeom::Path(list(0:0 10:0) ?width 0) t)  "path: zero width rejected")
_AssertError(lambda(() ycGeom::Path(list(0:0 10:0) ?width "2") t)
    "path: string width rejected")
_AssertError(lambda(() ycGeom::Path(list(0:0 10:0) ?width 2 ?eps 0) t)
    "path: bad eps rejected")
_AssertError(lambda(() ycGeom::Path(list(0 0 10 0) ?width 2) t)
    "path: flat coords rejected")

let((g_p g_l g_s n_circle n_quarter)
    n_circle = 16.0 * sin(3.141592653589793 / 16.0)
    n_quarter = 4.0 * sin(3.141592653589793 / 16.0)
    g_p = ycGeom::Path(list(0:0 10:0) ?width 2)

    _Assert(abs(g_p->toRegion(?cap 'square)->area() - 24.0) <= 1e-9
        "path: square cap area")
    _Assert(abs(g_p->toRegion(?cap 'round)->area() - (20.0 + n_circle)) <= 1e-9
        "path: round cap area")

    g_l = ycGeom::Path(list(0:0 10:0 10:10) ?width 2)
    _Assert(abs(g_l->toRegion(?join 'bevel)->area() - 39.5) <= 1e-9
        "path: bevel join area")
    _Assert(abs(g_l->toRegion(?join 'round)->area() - (40.0 - 1.0 + n_quarter)) <= 1e-9
        "path: round join area")

    g_s = ycGeom::Path(list(0:0 10:0 10:10 0:10 0:0) ?width 2)
    _Assert(abs(g_s->toRegion(?cap 'round)->area() - 80.0) <= 1e-9
        "path: closed ignores cap")
)

_AssertError(lambda(() ycGeom::Path(list(0:0 10:0) ?width 2)->toRegion(?cap 'bogus) t)
    "path: bad cap rejected")
_AssertError(lambda(() ycGeom::Path(list(0:0 10:0) ?width 2)->toRegion(?join 'bogus) t)
    "path: bad join rejected")
_AssertError(lambda(() ycGeom::Path(list(0:0 10:0) ?width 2)->toRegion(?miterLimit 0) t)
    "path: bad miter limit rejected")
_AssertError(lambda(() ycGeom::Path(list(0:0 10:0) ?width 2)->toRegion(?roundSegments 0) t)
    "path: bad round segments rejected")
_AssertError(lambda(() ycGeom::Path(list(0:0 10:0) ?width 2)->toRegion(?eps 0) t)
    "path: bad region eps rejected")
_AssertError(lambda(() ycGeom::Path(list(0:0 10:0) ?width 2)->toRegion(?grid 0) t)
    "path: bad grid rejected")

let((g_p g_s)
    g_p = ycGeom::Path(list(0:0 10:0) ?width 2)
    _Assert(abs(g_p->perimeter() - 24.0) <= 1e-9  "path: butt perimeter")
    _Assert(g_p->centroid()->toSkill() == list(5.0 0.0)  "path: butt centroid")
    _Assert(g_p->toRect()->toSkill() == list(list(0.0 -1.0) list(10.0 1.0))
        "path: butt toRect")
    _Assert(g_p->contains(ycGeom::Point(5:0))  "path: contains center")
    _Assert(!g_p->contains(ycGeom::Point(5:5))  "path: excludes outside")
    _Assert(g_p->onBoundary(ycGeom::Point(5:1))  "path: boundary point")

    g_s = ycGeom::Path(list(0:0 10:0 10:10 0:10 0:0) ?width 2)
    _Assert(abs(g_s->perimeter() - 80.0) <= 1e-9  "path: ring perimeter")
    _Assert(g_s->centroid()->toSkill() == list(5.0 5.0)  "path: ring centroid")
)

_TestPathDone = t

; END
