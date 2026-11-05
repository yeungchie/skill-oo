_TestRouteDone = nil

let((r c)
    r = ycGeom::Route(list(0:0 10:0 10:10))
    _Assert(classOf(r) == findClass('ycGeom::Route)  "route: class identity")
    _Assert(!r->isClosed()  "route: open")
    _Assert(length(r->points()) == 3  "route: point count")
    _Assert(r->toSkill() == list(list(0.0 0.0) list(10.0 0.0) list(10.0 10.0))
        "route: open toSkill")

    c = ycGeom::Route(list(0:0 10:0 10:10 0:0))
    _Assert(c->isClosed()  "route: closed")
    _Assert(length(c->points()) == 3  "route: closed drops repeated tail")
    _Assert(c->toSkill() == list(list(0.0 0.0) list(10.0 0.0)
        list(10.0 10.0) list(0.0 0.0))  "route: closed toSkill")
)

_AssertError(lambda(() ycGeom::Route(list(0:0)) t)  "route: one point rejected")
_AssertError(lambda(() ycGeom::Route(list(0:0 0:0 10:0)) t)  "route: duplicate rejected")
_AssertError(lambda(() ycGeom::Route(list(0:0 10:0 0:0)) t)
    "route: closed needs three distinct points")
_AssertError(lambda(() ycGeom::Route(list(0 0 10 0)) t)  "route: flat coords rejected")
_AssertError(lambda(() ycGeom::Route(list(0:0 1)) t)  "route: non-point element rejected")


let((r c)
    r = ycGeom::Route(list(0:0 10:0 10:10))
    _Assert(length(r->segments()) == 2  "route: open segment count")
    _Assert(r->length() == 20.0  "route: open length")
    _Assert(r->bBox() == list(list(0.0 0.0) list(10.0 10.0))  "route: open bBox")
    _Assert(r->toRect()->toSkill() == list(list(0.0 0.0) list(10.0 10.0))
        "route: open toRect")
    _AssertError(lambda(() r->toPolygon() t)  "route: open toPolygon rejected")

    c = ycGeom::Route(list(0:0 10:0 10:10 0:0))
    _Assert(length(c->segments()) == 3  "route: closed segment count")
    _Assert(abs(c->length() - (20.0 + sqrt(200.0))) <= 1e-9  "route: closed length")
    _Assert(abs(c->toPolygon()->area() - 50.0) <= 1e-9  "route: closed toPolygon area")
    _Assert(c->reverse()->isClosed()  "route: reverse keeps closed")
    _Assert(c->reverse()->toSkill() == list(list(10.0 10.0) list(10.0 0.0)
        list(0.0 0.0) list(10.0 10.0))  "route: reverse points")
)

let((c)
    c = ycGeom::Route(list(0:0 10:0 10:10 list(1e-10 1e-10)) ?eps 1e-9)
    _Assert(c->isClosed()  "route: near-equal tail closes")
    _Assert(car(c->toSkill()) == car(reverse(c->toSkill()))
        "route: near-equal tail snaps to first point")
)

_TestChildDone = t

; END
