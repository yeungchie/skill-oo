_TestPathDone = nil

let((p s l)
    p = ycGeom::Path(list(0:0 10:0) ?width 2)
    _Assert(classOf(p) == findClass('ycGeom::Path)  "path: class identity")
    _Assert(p->width() == 2.0  "path: width")
    _Assert(!p->isClosed()  "path: open")
    _Assert(abs(p->area() - 20.0) <= 1e-9  "path: butt rectangle area")
    _Assert(p->bBox() == list(list(0.0 -1.0) list(10.0 1.0))
        "path: butt rectangle bBox")

    s = ycGeom::Path(list(0:0 10:0 10:10 0:10 0:0) ?width 2)
    _Assert(s->isClosed()  "path: closed square")
    _Assert(abs(s->area() - 80.0) <= 1e-9  "path: miter ring area")
    _Assert(s->bBox() == list(list(-1.0 -1.0) list(11.0 11.0))
        "path: miter ring bBox")

    l = ycGeom::Path(list(0:0 10:0 10:10) ?width 2)
    _Assert(abs(l->area() - 40.0) <= 1e-9  "path: miter L area")
)

_AssertError(lambda(() ycGeom::Path(list(0:0 10:0)) t)  "path: width required")
_AssertError(lambda(() ycGeom::Path(list(0:0 10:0) ?width 0) t)  "path: zero width rejected")
_AssertError(lambda(() ycGeom::Path(list(0:0 10:0) ?width "2") t)
    "path: string width rejected")
_AssertError(lambda(() ycGeom::Path(list(0:0 10:0) ?width 2 ?eps 0) t)
    "path: bad eps rejected")
_AssertError(lambda(() ycGeom::Path(list(0 0 10 0) ?width 2) t)
    "path: flat coords rejected")

let((p l s circle quarter)
    circle = 16.0 * sin(3.141592653589793 / 16.0)
    quarter = 4.0 * sin(3.141592653589793 / 16.0)
    p = ycGeom::Path(list(0:0 10:0) ?width 2)

    _Assert(abs(p->toRegion(?cap 'square)->area() - 24.0) <= 1e-9
        "path: square cap area")
    _Assert(abs(p->toRegion(?cap 'round)->area() - (20.0 + circle)) <= 1e-9
        "path: round cap area")

    l = ycGeom::Path(list(0:0 10:0 10:10) ?width 2)
    _Assert(abs(l->toRegion(?join 'bevel)->area() - 39.5) <= 1e-9
        "path: bevel join area")
    _Assert(abs(l->toRegion(?join 'round)->area() - (40.0 - 1.0 + quarter)) <= 1e-9
        "path: round join area")

    s = ycGeom::Path(list(0:0 10:0 10:10 0:10 0:0) ?width 2)
    _Assert(abs(s->toRegion(?cap 'round)->area() - 80.0) <= 1e-9
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

let((p s)
    p = ycGeom::Path(list(0:0 10:0) ?width 2)
    _Assert(abs(p->perimeter() - 24.0) <= 1e-9  "path: butt perimeter")
    _Assert(p->centroid()->toSkill() == list(5.0 0.0)  "path: butt centroid")
    _Assert(p->toRect()->toSkill() == list(list(0.0 -1.0) list(10.0 1.0))
        "path: butt toRect")
    _Assert(p->contains(ycGeom::Point(5:0))  "path: contains center")
    _Assert(!p->contains(ycGeom::Point(5:5))  "path: excludes outside")
    _Assert(p->onBoundary(ycGeom::Point(5:1))  "path: boundary point")

    s = ycGeom::Path(list(0:0 10:0 10:10 0:10 0:0) ?width 2)
    _Assert(abs(s->perimeter() - 80.0) <= 1e-9  "path: ring perimeter")
    _Assert(s->centroid()->toSkill() == list(5.0 5.0)  "path: ring centroid")
)

let((p ok open edge)
    p = ycGeom::Path(list(0:0 2:0 2:1 0:1 0:0) ?width 0.2)
    _Assert(p->toLegalPathPoints() == list(
        list(1.0 0.0) list(2.0 0.0) list(2.0 1.0)
        list(0.0 1.0) list(0.0 0.0) list(1.0 0.0))
        "path: seam moved to straight edge")

    ok = ycGeom::Path(list(1:0 2:0 2:1 0:1 0:0 1:0) ?width 0.2)
    _Assert(ok->toLegalPathPoints() == list(
        list(1.0 0.0) list(2.0 0.0) list(2.0 1.0)
        list(0.0 1.0) list(0.0 0.0) list(1.0 0.0))
        "path: legal seam unchanged")

    open = ycGeom::Path(list(0:0 10:0 10:10) ?width 2)
    _Assert(open->toLegalPathPoints() == list(
        list(0.0 0.0) list(10.0 0.0) list(10.0 10.0))
        "path: open points unchanged")

    edge = ycGeom::Path(list(0:0 10:0 10:10 0:10 0:0) ?width 2)
    _Assert(edge->toLegalPathPoints(?edge 2 ?ratio 0.25) == list(
        list(10.0 2.5) list(10.0 10.0) list(0.0 10.0)
        list(0.0 0.0) list(10.0 0.0) list(10.0 2.5))
        "path: edge and ratio options")
)

let((e o bad)
    e = ycGeom::Path(list(0:0 10:0 10:10 0:10 0:0) ?width 2)
    o = ycGeom::Path(list(0:0 10:0 10:10) ?width 2)
    bad = ycGeom::Path(list(0:0 10:10 10:0 0:10 0:0) ?width 2)
    _AssertError(lambda(() e->toLegalPathPoints(?edge 5) t)
        "path: edge out of range")
    _AssertError(lambda(() o->toLegalPathPoints(?ratio 0) t)
        "path: ratio zero rejected")
    _AssertError(lambda(() o->toLegalPathPoints(?ratio "x") t)
        "path: string ratio rejected")
    _AssertError(lambda(() bad->toLegalPathPoints() t)
        "path: self-intersection rejected")
)

let((p s r s2 r2)
    p = ycGeom::Path(list(0:0 10:0) ?width 2)
    s2 = p->toSkill()
    _Assert(s2 == list(list(list(0.0 0.0) list(10.0 0.0)) 2.0)
        "path: open toSkill")
    r = ycGeom::Path(s2)
    _Assert(r->toSkill() == s2  "path: open state round-trip")

    s = ycGeom::Path(list(0:0 10:0 10:10 0:10 0:0) ?width 2)
    s2 = s->toSkill()
    _Assert(s2 == list(list(list(0.0 0.0) list(10.0 0.0)
        list(10.0 10.0) list(0.0 10.0) list(0.0 0.0)) 2.0)
        "path: closed toSkill")
    r = ycGeom::Path(s2)
    _Assert(r->isClosed()  "path: closed state round-trip closed")
    _Assert(r->toSkill() == s2  "path: closed state round-trip")

    r = ycGeom::Path(ycGeom::Route(list(0:0 10:0 10:10)) ?width 2)
    _Assert(r->route()->toSkill() == list(list(0.0 0.0) list(10.0 0.0) list(10.0 10.0))
        "path: Route input")

    r2 = ycGeom::Route(s->route()->toSkill())
    _Assert(r2->isClosed()  "route: state round-trip closed")
)

let((s (ycGeom::Path(list(0:0 10:0) ?width 2)->toSkill()))
    _AssertError(lambda(() ycGeom::Path(s ?width 3) t)
        "path: duplicate width rejected")
)

let((l s value p)
    l = ycGeom::Path(list(0:0 10:0 10:10) ?width 2)
    _Assert(abs(l->toRegion(?miterLimit 1.4142135623730951)->area() - 40.0) <= 1e-9
        "path: miter exactly at limit stays miter")
    _Assert(abs(l->toRegion(?miterLimit 1.414)->area() - 39.5) <= 1e-9
        "path: miter over limit falls back to bevel")

    s = ycGeom::Path(list(0:0 10:0 5:0) ?width 2)
    _Assert(abs(s->area() - 20.0) <= 1e-9  "path: reversal spike area")
    _Assert(s->bBox() == list(list(0.0 -1.0) list(10.0 1.0))
        "path: reversal spike bBox")

    value = ycGeom::Path(list(0:0 1e-6:0 -0.5e-6:0.5e-6 0:0) ?width 1e-7)
    _Assert(length(value->toLegalPathPoints()) == 5
        "path: tiny scale seam is not treated as collinear")

    p = ycGeom::Path(list(0:0 10:0) ?width 2)
    _Assert(abs(p->toRegion(?cap 'round ?roundSegments 1)->area() - 22.0) <= 1e-9
        "path: roundSegments changes cap polygon")
)

_AssertError(lambda(() ycGeom::Path(list(0:0 10:0) ?width 2)->toRegion(?eps "x") t)
    "path: string eps rejected")
_AssertError(lambda(() ycGeom::Path(list(0:0 10:0) ?width 2)->toRegion(?miterLimit "x") t)
    "path: string miter limit rejected")
_AssertError(lambda(() ycGeom::Path(list(0:0 10:0) ?width 2)->toRegion(?roundSegments 1.5) t)
    "path: float round segments rejected")
_AssertError(lambda(() ycGeom::Path(list(0:0 10:0) ?width 2)->toRegion(?grid "x") t)
    "path: string grid rejected")
_AssertError(lambda(() ycGeom::Path(list(0:0 10:0 10:10 0:10 0:0) ?width 2)
    ->toLegalPathPoints(?edge 1.5) t)  "path: float edge rejected")

; ?edge 上界在开放路径上同样校验
let((two three)
    two = ycGeom::Path(list(0:0 10:0) ?width 2)
    three = ycGeom::Path(list(0:0 10:0 10:10) ?width 2)
    _AssertError(lambda(() two->toLegalPathPoints(?edge 2) t)
        "path: open path edge out of range")
    _Assert(three->toLegalPathPoints(?edge 2)
        == list(list(0.0 0.0) list(10.0 0.0) list(10.0 10.0))
        "path: open path edge in range")
)

_TestChildDone = t

; END
