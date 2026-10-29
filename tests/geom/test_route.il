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

_TestRouteDone = t

; END
