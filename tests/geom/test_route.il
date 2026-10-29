_TestRouteDone = nil

let((g_r g_c)
    g_r = ycGeom::Route(list(0:0 10:0 10:10))
    _Assert(classOf(g_r) == findClass('ycGeom::Route)  "route: class identity")
    _Assert(!g_r->isClosed()  "route: open")
    _Assert(length(g_r->points()) == 3  "route: point count")
    _Assert(g_r->toSkill() == list(list(0.0 0.0) list(10.0 0.0) list(10.0 10.0))
        "route: open toSkill")

    g_c = ycGeom::Route(list(0:0 10:0 10:10 0:0))
    _Assert(g_c->isClosed()  "route: closed")
    _Assert(length(g_c->points()) == 3  "route: closed drops repeated tail")
    _Assert(g_c->toSkill() == list(list(0.0 0.0) list(10.0 0.0)
        list(10.0 10.0) list(0.0 0.0))  "route: closed toSkill")
)

_AssertError(lambda(() ycGeom::Route(list(0:0)) t)  "route: one point rejected")
_AssertError(lambda(() ycGeom::Route(list(0:0 0:0 10:0)) t)  "route: duplicate rejected")
_AssertError(lambda(() ycGeom::Route(list(0:0 10:0 0:0)) t)
    "route: closed needs three distinct points")
_AssertError(lambda(() ycGeom::Route(list(0 0 10 0)) t)  "route: flat coords rejected")
_AssertError(lambda(() ycGeom::Route(list(0:0 1)) t)  "route: non-point element rejected")


let((g_r g_c)
    g_r = ycGeom::Route(list(0:0 10:0 10:10))
    _Assert(length(g_r->segments()) == 2  "route: open segment count")
    _Assert(g_r->length() == 20.0  "route: open length")
    _Assert(g_r->bBox() == list(list(0.0 0.0) list(10.0 10.0))  "route: open bBox")
    _Assert(g_r->toRect()->toSkill() == list(list(0.0 0.0) list(10.0 10.0))
        "route: open toRect")
    _AssertError(lambda(() g_r->toPolygon() t)  "route: open toPolygon rejected")

    g_c = ycGeom::Route(list(0:0 10:0 10:10 0:0))
    _Assert(length(g_c->segments()) == 3  "route: closed segment count")
    _Assert(abs(g_c->length() - (20.0 + sqrt(200.0))) <= 1e-9  "route: closed length")
    _Assert(abs(g_c->toPolygon()->area() - 50.0) <= 1e-9  "route: closed toPolygon area")
    _Assert(g_c->reverse()->isClosed()  "route: reverse keeps closed")
    _Assert(g_c->reverse()->toSkill() == list(list(10.0 10.0) list(10.0 0.0)
        list(0.0 0.0) list(10.0 10.0))  "route: reverse points")
)

_TestRouteDone = t

; END
