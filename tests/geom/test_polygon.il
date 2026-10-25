_TestPolygonDone = nil

let((g_sq)
    g_sq = ycGeom::Polygon(list(
        ycGeom::Point(0 0)
        ycGeom::Point(10 0)
        ycGeom::Point(10 10)
        ycGeom::Point(0 10)
    ))
    _Assert(classOf(g_sq) == findClass('ycGeom::Polygon)  "polygon: class identity")
    _Assert(length(g_sq->points()) == 4  "polygon: point count")
    _Assert(length(g_sq->edges()) == 4  "polygon: edge count")
    _Assert(g_sq->area() == 100.0  "polygon: area")
    _Assert(g_sq->perimeter() == 40.0  "polygon: perimeter")
    _Assert(g_sq->bbox() == list(0.0 0.0 10.0 10.0)  "polygon: bbox")
    _Assert(g_sq->isClockwise() == nil  "polygon: ccw")
    _Assert(g_sq->reverse()->isClockwise()  "polygon: reverse cw")
    _Assert(g_sq->toSkill() == list(
        list(0.0 0.0) list(10.0 0.0) list(10.0 10.0) list(0.0 10.0)
    )  "polygon: toSkill")
)

let((g_hole)
    g_hole = ycGeom::Polygon(list(
        ycGeom::Point(0 0)
        ycGeom::Point(10 0)
        ycGeom::Point(3 3)
        ycGeom::Point(3 7)
        ycGeom::Point(7 7)
        ycGeom::Point(7 3)
        ycGeom::Point(3 3)
        ycGeom::Point(10 0)
        ycGeom::Point(10 10)
        ycGeom::Point(0 10)
    ))
    _Assert(g_hole->area() == 84.0  "polygon: keyhole area")
    _Assert(g_hole->perimeter() == 56.0  "polygon: keyhole perimeter without seam")
    _Assert(g_hole->perimeter(?includeSeams t) > 56.0  "polygon: keyhole perimeter includes seam")
)

_AssertError(lambda(() ycGeom::Polygon(nil) t)  "polygon: nil rejected")
_AssertError(lambda(() ycGeom::Polygon(list(ycGeom::Point(0 0) ycGeom::Point(1 1))) t)  "polygon: fewer than 3 rejected")
_AssertError(lambda(() ycGeom::Polygon(list(1 2 3)) t)  "polygon: non-Point rejected")
_AssertError(lambda(() ycGeom::Polygon(list(
    ycGeom::Point(0 0) ycGeom::Point(1 0) ycGeom::Point(1 0) ycGeom::Point(0 1)
)) t)  "polygon: consecutive duplicate rejected")
_AssertError(lambda(() ycGeom::Polygon(list(
    ycGeom::Point(0 0) ycGeom::Point(10 10) ycGeom::Point(10 0) ycGeom::Point(0 10)
)) t)  "polygon: self-intersection rejected")

let((g_sq g_hole)
    g_sq = ycGeom::Polygon(list(
        ycGeom::Point(0 0) ycGeom::Point(10 0)
        ycGeom::Point(10 10) ycGeom::Point(0 10)
    ))
    _Assert(g_sq->centroid()->toSkill() == list(5.0 5.0)  "polygon: square centroid")
    _Assert(g_sq->contains(ycGeom::Point(5 5))  "polygon: contains inside")
    _Assert(!g_sq->contains(ycGeom::Point(15 5))  "polygon: contains outside")
    _Assert(g_sq->onBoundary(ycGeom::Point(0 5))  "polygon: on boundary")
    _Assert(g_sq->contains(ycGeom::Point(0 5))  "polygon: boundary defaults inside")
    _Assert(!g_sq->contains(ycGeom::Point(0 5) ?boundary "outside")  "polygon: boundary outside")
    g_hole = ycGeom::Polygon(list(
        ycGeom::Point(0 0) ycGeom::Point(10 0) ycGeom::Point(3 3)
        ycGeom::Point(3 7) ycGeom::Point(7 7) ycGeom::Point(7 3)
        ycGeom::Point(3 3) ycGeom::Point(10 0) ycGeom::Point(10 10)
        ycGeom::Point(0 10)
    ))
    _Assert(g_hole->centroid()->toSkill() == list(5.0 5.0)  "polygon: keyhole centroid")
    _Assert(!g_hole->contains(ycGeom::Point(5 5))  "polygon: hole excluded")
    _Assert(g_hole->onBoundary(ycGeom::Point(3 7))  "polygon: hole boundary")
    _Assert(!g_hole->onBoundary(ycGeom::Point(6.5 1.5))  "polygon: seam not boundary")
    _Assert(g_hole->onBoundary(ycGeom::Point(6.5 1.5) ?includeSeams t)  "polygon: seam included")
)
_AssertError(lambda(() ycGeom::Polygon(list(
    ycGeom::Point(0 0) ycGeom::Point(1 0) ycGeom::Point(0 1)
))->contains(ycGeom::Point(0 0) ?boundary "bad") t)  "polygon: bad boundary option")

let((g_tri)
    g_tri = ycGeom::Polygon(list(
        ycGeom::Point(0 0) ycGeom::Point(1 0) ycGeom::Point(0 1)
    ))
    _AssertError(lambda(() g_tri->contains(ycGeom::Point(0 0) ?eps 0) t)  "polygon: eps 0 rejected")
    _AssertError(lambda(() g_tri->contains(ycGeom::Point(0 0) ?eps -1) t)  "polygon: negative eps rejected")
    _AssertError(lambda(() g_tri->contains(ycGeom::Point(0 0) ?eps "x") t)  "polygon: string eps rejected")
    _AssertError(lambda(() g_tri->onBoundary(ycGeom::Point(0 0) ?includeSeams "x") t)  "polygon: bad includeSeams")
)

_TestPolygonDone = t

; END
