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

_TestPathDone = t

; END
