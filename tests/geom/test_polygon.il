_TestPolygonDone = nil

let((sq)
    sq = ycGeom::Polygon(list(
        ycGeom::Point(0:0)
        ycGeom::Point(10:0)
        ycGeom::Point(10:10)
        ycGeom::Point(0:10)
    ))
    _Assert(classOf(sq) == findClass('ycGeom::Polygon)  "polygon: class identity")
    _Assert(length(sq->points()) == 4  "polygon: point count")
    _Assert(length(sq->edges()) == 4  "polygon: edge count")
    _Assert(sq->area() == 100.0  "polygon: area")
    _Assert(sq->perimeter() == 40.0  "polygon: perimeter")
    _Assert(sq->bBox() == list(list(0.0 0.0) list(10.0 10.0))  "polygon: bBox")
    _Assert(sq->toRect()->toSkill() == list(list(0.0 0.0) list(10.0 10.0))  "polygon: toRect")
    _Assert(ycGeom::Polygon('((0 0) (4 0) (1 2)))->toRect()->toSkill() == list(list(0.0 0.0) list(4.0 2.0))  "polygon: toRect triangle")
    _Assert(sq->isClockwise() == nil  "polygon: ccw")
    _Assert(sq->reverse()->isClockwise()  "polygon: reverse cw")
    _Assert(sq->toSkill() == list(
        list(0.0 0.0) list(10.0 0.0) list(10.0 10.0) list(0.0 10.0)
    )  "polygon: toSkill")
)

let((p c)
    p = ycGeom::Polygon('((0 0) (2 0) (4 0) (4 4) (0 4)))
    c = p->removeCollinear()
    _Assert(length(p->points()) == 5  "polygon: collinear original unchanged")
    _Assert(length(c->points()) == 4  "polygon: removeCollinear count")
    _Assert(c->toSkill() == list(
        list(0.0 0.0) list(4.0 0.0) list(4.0 4.0) list(0.0 4.0)
    )  "polygon: removeCollinear points")
)
_AssertError(lambda(() ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))->removeCollinear(?eps "x") t)  "polygon: bad removeCollinear eps")

let((hole clean)
    hole = ycGeom::Polygon('((0 0) (5 0) (10 0) (10 7) (7 7) (7 3)
                              (3 3) (3 7) (7 7) (10 7) (10 10) (0 10)))
    clean = hole->removeCollinear()
    _Assert(length(hole->points()) == 12  "polygon: keyhole collinear original unchanged")
    _Assert(length(clean->points()) == 11  "polygon: keyhole removeCollinear count")
    _Assert(clean->area() == 84.0  "polygon: keyhole removeCollinear area")
    _Assert(clean->perimeter() == 56.0  "polygon: keyhole removeCollinear perimeter")
)

let((hole)
    hole = ycGeom::Polygon(list(
        ycGeom::Point(0:0)
        ycGeom::Point(10:0)
        ycGeom::Point(10:7)
        ycGeom::Point(7:7)
        ycGeom::Point(7:3)
        ycGeom::Point(3:3)
        ycGeom::Point(3:7)
        ycGeom::Point(7:7)
        ycGeom::Point(10:7)
        ycGeom::Point(10:10)
        ycGeom::Point(0:10)
    ))
    _Assert(hole->area() == 84.0  "polygon: keyhole area")
    _Assert(hole->perimeter() == 56.0  "polygon: keyhole perimeter without seam")
    _Assert(hole->perimeter(?includeSeams t) > 56.0  "polygon: keyhole perimeter includes seam")
)

_AssertError(lambda(() ycGeom::Polygon('((0 0) (10 0) (3 3) (3 7) (7 7)
    (7 3) (3 3) (10 0) (10 10) (0 10))) t)
    "polygon: diagonal seam rejected")
let((hole)
    hole = ycGeom::Polygon('((0 0) (10 0) (10 10) (7 10) (7 7)
                              (7 3) (3 3) (3 7) (7 7) (7 10) (0 10)))
    _Assert(hole->area() == 84.0  "polygon: vertical seam area")
    _Assert(hole->perimeter() == 56.0  "polygon: vertical seam perimeter")
)
_AssertError(lambda(() ycGeom::Polygon(nil) t)  "polygon: nil rejected")
_AssertError(lambda(() ycGeom::Polygon(list(ycGeom::Point(0:0) ycGeom::Point(1:1))) t)  "polygon: fewer than 3 rejected")
_AssertError(lambda(() ycGeom::Polygon(list(1 2 3)) t)  "polygon: non-Point rejected")
_AssertError(lambda(() ycGeom::Polygon(list(
    ycGeom::Point(0:0) ycGeom::Point(1:0) ycGeom::Point(1:0) ycGeom::Point(0:1)
)) t)  "polygon: consecutive duplicate rejected")
_AssertError(lambda(() ycGeom::Polygon(list(
    ycGeom::Point(0:0) ycGeom::Point(10:10) ycGeom::Point(10:0) ycGeom::Point(0:10)
)) t)  "polygon: self-intersection rejected")

let((sq hole)
    sq = ycGeom::Polygon(list(
        ycGeom::Point(0:0) ycGeom::Point(10:0)
        ycGeom::Point(10:10) ycGeom::Point(0:10)
    ))
    _Assert(sq->centroid()->toSkill() == list(5.0 5.0)  "polygon: square centroid")
    _Assert(sq->contains(ycGeom::Point(5:5))  "polygon: contains inside")
    _Assert(!sq->contains(ycGeom::Point(15:5))  "polygon: contains outside")
    _Assert(sq->onBoundary(ycGeom::Point(0:5))  "polygon: on boundary")
    _Assert(sq->contains(ycGeom::Point(0:5))  "polygon: boundary defaults inside")
    _Assert(!sq->contains(ycGeom::Point(0:5) ?boundary "outside")  "polygon: boundary outside")
    hole = ycGeom::Polygon(list(
        ycGeom::Point(0:0) ycGeom::Point(10:0) ycGeom::Point(10:7)
        ycGeom::Point(7:7) ycGeom::Point(7:3) ycGeom::Point(3:3)
        ycGeom::Point(3:7) ycGeom::Point(7:7) ycGeom::Point(10:7)
        ycGeom::Point(10:10) ycGeom::Point(0:10)
    ))
    _Assert(hole->centroid()->toSkill() == list(5.0 5.0)  "polygon: keyhole centroid")
    _Assert(!hole->contains(ycGeom::Point(5:5))  "polygon: hole excluded")
    _Assert(hole->onBoundary(ycGeom::Point(3:7))  "polygon: hole boundary")
    _Assert(!hole->onBoundary(ycGeom::Point(8.5:7))  "polygon: seam not boundary")
    _Assert(hole->onBoundary(ycGeom::Point(8.5:7) ?includeSeams t)  "polygon: seam included")
)
_AssertError(lambda(() ycGeom::Polygon(list(
    ycGeom::Point(0:0) ycGeom::Point(1:0) ycGeom::Point(0:1)
))->contains(ycGeom::Point(0:0) ?boundary "bad") t)  "polygon: bad boundary option")

let((tri)
    tri = ycGeom::Polygon(list(
        ycGeom::Point(0:0) ycGeom::Point(1:0) ycGeom::Point(0:1)
    ))
    _AssertError(lambda(() tri->contains(ycGeom::Point(0:0) ?eps 0) t)  "polygon: eps 0 rejected")
    _AssertError(lambda(() tri->contains(ycGeom::Point(0:0) ?eps -1) t)  "polygon: negative eps rejected")
    _AssertError(lambda(() tri->contains(ycGeom::Point(0:0) ?eps "x") t)  "polygon: string eps rejected")
    _AssertError(lambda(() tri->onBoundary(ycGeom::Point(0:0) ?includeSeams "x") t)  "polygon: bad includeSeams")
)

let((sq pairs)
    sq = ycGeom::Polygon(list(
        ycGeom::Point(0:0) ycGeom::Point(4:0)
        ycGeom::Point(4:4) ycGeom::Point(0:4)
    ))
    pairs = ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))
    _Assert(pairs->toSkill() == sq->toSkill()  "polygon: pair list form")
    _AssertError(lambda(() ycGeom::Polygon(list(0 0 4 0 4 4 0 4)) t)
        "polygon: flat number form rejected")
    _Assert(ycGeom::Polygon(sq->toSkill())->toSkill() == sq->toSkill()  "polygon: toSkill roundtrip")
    _Assert(ycGeom::Polygon('((0 0) (0 1) (1 1)))->area() == 0.5  "polygon: user pair example")
)
_AssertError(lambda(() ycGeom::Polygon(list(0 0 4 0 4)) t)  "polygon: odd flat list rejected")
_AssertError(lambda(() ycGeom::Polygon(list(list(0 0) list(4 0))) t)  "polygon: two points rejected")

let((a b r)
    a = ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))
    b = ycGeom::Polygon('((2 2) (6 2) (6 6) (2 6)))
    r = a->or(b)
    _Assert(classOf(r) == findClass('ycGeom::Region)  "polygon: or returns Region")
    _Assert(r->area() == 28.0  "polygon: or area")
    _Assert(a->and(b)->area() == 4.0  "polygon: and area")
    _Assert(a->not(b)->area() == 12.0  "polygon: not area")
    _Assert(a->xor(b)->area() == 24.0  "polygon: xor area")
    _Assert(a->and(ycGeom::Polygon('((10 10) (12 10) (12 12) (10 12))))->isEmpty()  "polygon: disjoint and empty")
    _Assert(a->or('((2 2) (6 2) (6 6) (2 6)))->area() == 28.0  "polygon: raw list operand")
)
_AssertError(lambda(() ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))->or(1) t)  "polygon: bad boolean operand")

let((hole)
    hole = ycGeom::Polygon(list(
        ycGeom::Point(0:0)
        ycGeom::Point(10:0)
        ycGeom::Point(10:7)
        ycGeom::Point(7:7)
        ycGeom::Point(7:3)
        ycGeom::Point(3:3)
        ycGeom::Point(3:7)
        ycGeom::Point(7.000000000000001:7)
        ycGeom::Point(10:7)
        ycGeom::Point(10:10)
        ycGeom::Point(0:10)
    ))
    _Assert(hole->area() == 84.0  "polygon: keyhole near seam area")
    _Assert(hole->perimeter() == 56.0  "polygon: keyhole near seam perimeter")
    _Assert(hole->perimeter(?includeSeams t) == 62.0
        "polygon: keyhole near seam included perimeter")
)

let((p q reg)
    p = ycGeom::Point(list(6500408.894374631 -5659520.731666292))
    q = ycGeom::Point(list(6500408.894374632 -5659520.731666292))
    reg = makeTable("geomCanonTest" nil)
    _Assert(ycGeom::_SamePoint(p q 1e-9)
        "polygon: 1 ulp points compare equal")
    _Assert(ycGeom::_PtKey(ycGeom::_CanonPoint(p 1e-9 reg))
        == ycGeom::_PtKey(ycGeom::_CanonPoint(q 1e-9 reg))
        "polygon: 1 ulp points share a canonical representative")
)

let((p q reg)
    p = ycGeom::Point(list(-1354119.7609392945 1809784.94827771))
    q = ycGeom::Point(list(-1354119.7609392938 1809784.9482777116))
    reg = makeTable("geomCanonTest" nil)
    _Assert(ycGeom::_SamePoint(p q 1e-9)
        "polygon: nearby points with different magnitudes compare equal")
    _Assert(ycGeom::_PtKey(ycGeom::_CanonPoint(p 1e-9 reg))
        == ycGeom::_PtKey(ycGeom::_CanonPoint(q 1e-9 reg))
        "polygon: canonical scale is stable across nearby magnitudes")
)

let((hole)
    hole = ycGeom::Polygon(list(
        ycGeom::Point(1000000:2778.75)
        ycGeom::Point(1000010:2778.75)
        ycGeom::Point(1000010:2785.75)
        ycGeom::Point(1000007:2785.75)
        ycGeom::Point(1000007:2781.75)
        ycGeom::Point(1000003:2781.75)
        ycGeom::Point(1000003:2785.75)
        ycGeom::Point(list(1000007.0000000001 2785.75))
        ycGeom::Point(1000010:2785.75)
        ycGeom::Point(1000010:2788.75)
        ycGeom::Point(1000000:2788.75)
    ))
    _Assert(hole->perimeter() == 56.0
        "polygon: shifted keyhole near seam perimeter")
    _Assert(hole->perimeter(?includeSeams t) == 62.0
        "polygon: shifted keyhole included perimeter")
)

let((hole)
    hole = ycGeom::Polygon(list(
        ycGeom::Point(900000:900000)
        ycGeom::Point(900010:900000)
        ycGeom::Point(list(900010.0000000006 900007.0))
        ycGeom::Point(900007:900007)
        ycGeom::Point(900007:900003)
        ycGeom::Point(900003:900003)
        ycGeom::Point(900003:900007)
        ycGeom::Point(900007:900007)
        ycGeom::Point(list(900010.0000000015 900007.0))
        ycGeom::Point(900010:900010)
        ycGeom::Point(900000:900010)
    ))
    _Assert(hole->perimeter() == 56.0
        "polygon: seam endpoints on cell boundary perimeter")
    _Assert(abs(hole->perimeter(?includeSeams t) - 62.0) <= 1e-6
        "polygon: seam endpoints on cell boundary included perimeter")
)

let((pts i teeth w h2 amp hi p)
    teeth = 997
    w = 1e6
    h2 = 1e6
    amp = 4e5
    pts = tconc(pts ycGeom::Point(list(1e9 3.7e8)))
    for(i2 1 teeth
        pts = tconc(pts ycGeom::Point(list(
            1e9 + w * i2 / (teeth + 1)
            3.7e8 + if(hi h2 - amp amp))))
        hi = !hi
    )
    pts = tconc(pts ycGeom::Point(list(1e9 + w 3.7e8)))
    pts = tconc(pts ycGeom::Point(list(1e9 + w 3.7e8 + h2)))
    pts = tconc(pts ycGeom::Point(list(1e9 3.7e8 + h2)))
    p = ycGeom::Polygon(car(pts))
    ; 该梳形的精确周长（高精度基准）。
    _Assert(abs(p->perimeter() - 203002502.4842986) <= 1e-6
        "polygon: perimeter accumulation stable on long comb")
)

let((sq c)
    sq = ycGeom::Polygon(list(
        ycGeom::Point(100000:100000)
        ycGeom::Point(100000.1:100000)
        ycGeom::Point(100000.1:100000.1)
        ycGeom::Point(100000:100000.1)
    ))
    _Assert(abs(sq->area() - 0.01) <= 1e-9  "polygon: large offset area stable")
    _Assert(abs(sq->centroid()->x() - 100000.05) <= 1e-9
        "polygon: large offset centroid x")
    _Assert(abs(sq->centroid()->y() - 100000.05) <= 1e-9
        "polygon: large offset centroid y")
    c = ycGeom::Polygon('((0 0) (0.0005 1e-6) (0.001 0)
                            (0.001 0.001) (0 0.001)))
    _Assert(length(c->removeCollinear()->points()) == 5
        "polygon: small-angle collinear tolerance is scale independent")
)

let((tiny large)
    tiny = errset(ycGeom::Polygon(list(
        ycGeom::Point(0:0) ycGeom::Point(1e-5:0)
        ycGeom::Point(1e-5:1e-5) ycGeom::Point(0:1e-5)
    )) nil)
    _Assert(tiny  "polygon: tiny polygon constructed")
    large = errset(ycGeom::Polygon(list(
        ycGeom::Point(1e7:1e7) ycGeom::Point(list(1e7 + 0.1 1e7))
        ycGeom::Point(list(1e7 + 0.1 1e7 + 0.1)) ycGeom::Point(list(1e7 1e7 + 0.1))
    )) nil)
    _Assert(large && abs(car(large)->area() - 0.01) <= 1e-9
        "polygon: very large offset area stable")
)

let((a b res r)
    a = ycGeom::Polygon(list(
        ycGeom::Point(10000000:0)
        ycGeom::Point(10000010:0)
        ycGeom::Point(10000010:10)
        ycGeom::Point(10000000:10)
    ))
    b = ycGeom::Polygon(list(
        ycGeom::Point(10000005:0)
        ycGeom::Point(10000015:0)
        ycGeom::Point(10000015:10)
        ycGeom::Point(10000005:10)
    ))
    res = errset(a->or(b ?grid 0.001) nil)
    _Assert(res  "polygon: large-coordinate grid union succeeds")
    when(res
        r = car(res)
        _Assert(abs(r->area() - 150.0) <= 1e-6
            "polygon: large-coordinate grid union area")
        _Assert(r->bBox() == list(list(10000000.0 0.0) list(10000015.0 10.0))
            "polygon: large-coordinate grid union bbox")
    )
)

let((a b r)
    a = ycGeom::Polygon(list(
        ycGeom::Point(0.15:0.15)
        ycGeom::Point(0.35:0.15)
        ycGeom::Point(0.35:0.35)
        ycGeom::Point(0.15:0.35)
    ))
    b = ycGeom::Polygon(list(
        ycGeom::Point(0.15:0.15)
        ycGeom::Point(0.35:0.15)
        ycGeom::Point(0.35:0.35)
        ycGeom::Point(0.15:0.35)
    ))
    r = a->or(b ?grid 0.1)
    _Assert(r->bBox() == list(list(0.2 0.2) list(0.4 0.4))
        "polygon: grid snap corrects half-cell representation error")
)

let((a b r x)
    x = 1.2 / (0.1 + 0.2) + 0.5
    a = ycGeom::Polygon(list(
        ycGeom::Point(list(x 0))
        ycGeom::Point(6:0)
        ycGeom::Point(6:1)
        ycGeom::Point(list(x 1))
    ))
    b = ycGeom::Polygon(list(
        ycGeom::Point(list(x 0))
        ycGeom::Point(6:0)
        ycGeom::Point(6:1)
        ycGeom::Point(list(x 1))
    ))
    r = a->or(b ?grid 1.0)
    _Assert(r->bBox() == list(list(5.0 0.0) list(6.0 1.0))
        "polygon: grid snap uses round2 tie at half cell")
)

let((rect sq p)
    rect = ycGeom::Polygon(list(0:0 10:0 10:4 0:4))
    p = rect->toPath()
    _Assert(p  "polygon: rectangle toPath")
    _Assert(p->width() == 4.0  "polygon: rectangle horizontal width")
    _Assert(p->route()->toSkill() == list(list(0.0 2.0) list(10.0 2.0))
        "polygon: rectangle horizontal route")
    _Assert(rect->xor(p->toRegion())->area() <= 1e-9
        "polygon: rectangle horizontal overlaps")

    p = rect->toPath(?orient 'v)
    _Assert(p->width() == 10.0  "polygon: rectangle vertical width")
    _Assert(p->route()->toSkill() == list(list(5.0 0.0) list(5.0 4.0))
        "polygon: rectangle vertical route")
    _Assert(rect->xor(p->toRegion())->area() <= 1e-9
        "polygon: rectangle vertical overlaps")

    _Assert(rect->toPath(?orient 'h)->toSkill() == rect->toPath()->toSkill()
        "polygon: h alias")
    _Assert(rect->toPath(?orient 'horizontal)->toSkill()
        == rect->toPath()->toSkill()  "polygon: horizontal alias")

    sq = ycGeom::Polygon(list(0:0 4:0 4:4 0:4))
    _Assert(sq->toPath()->width() == 4.0  "polygon: square horizontal")
    _Assert(sq->toPath(?orient 'v)->width() == 4.0  "polygon: square vertical")
)

_Assert(ycGeom::Polygon(list(0:0 4:0 0:4))->toPath() == nil
    "polygon: triangle not a stroke")
_AssertError(lambda(() ycGeom::Polygon(list(0:0 4:0 4:4 0:4))->toPath(?orient 'diagonal) t)
    "polygon: bad orient rejected")
_AssertError(lambda(() ycGeom::Polygon(list(0:0 4:0 4:4 0:4))->toPath(?eps 0) t)
    "polygon: bad eps rejected")

let((src poly back)
    src = ycGeom::Path(list(0:0 10:0 10:10) ?width 2)
    poly = car(src->toRegion()->polygons())
    back = poly->toPath()
    _Assert(back  "polygon: open stroke toPath")
    _Assert(back->width() == 2.0  "polygon: open stroke width")
    _Assert(poly->xor(back->toRegion())->area() <= 1e-6
        "polygon: open stroke overlaps")

    src = ycGeom::Path(list(0:0 10:0 10:10 0:10 0:0) ?width 2)
    poly = car(src->toRegion()->polygons())
    back = poly->toPath()
    _Assert(back  "polygon: closed ring toPath")
    _Assert(back->isClosed()  "polygon: closed ring closed")
    _Assert(back->width() == 2.0  "polygon: closed ring width")
    _Assert(poly->xor(back->toRegion())->area() <= 1e-6
        "polygon: closed ring overlaps")
)

let((rot p)
    rot = ycGeom::Polygon(list(
        ycGeom::Point(0:0)
        ycGeom::Point(list(8.660254037844386 5))
        ycGeom::Point(list(6.660254037844386 8.464101615137753))
        ycGeom::Point(list(-2 3.4641016151377535))
    ))
    p = rot->toPath(?orient 'vertical)
    _Assert(p  "polygon: rotated rectangle toPath")
    _Assert(abs(rot->xor(p->toRegion())->area()) <= 1e-6
        "polygon: rotated rectangle overlaps")
)

let((out in res poly)
    out = ycGeom::Polygon(list(0:0 10:0 10:10 0:10))
    in = ycGeom::Polygon(list(4:1 6:1 6:9 4:9))
    res = out->not(in)
    poly = car(res->polygons())
    _Assert(poly->toPath() == nil  "polygon: non-offset ring not a stroke")
)

; 大坐标偏移下 toPath 的容差必须随坐标量级放大
let((rad cosV sinV acc src poly back trap)
    rad = 37.0 * 3.14159265358979323846 / 180.0
    cosV = cos(rad)
    sinV = sin(rad)
    foreach(p list(0.0:0.0 10.0:0.0 10.0:10.0)
        acc = tconc(acc list(
            cosV * car(p) - sinV * cadr(p) + 5.0e6
            sinV * car(p) + cosV * cadr(p) + 5.0e6
        ))
    )
    src = ycGeom::Path(car(acc) ?width 2)
    poly = car(src->toRegion()->polygons())
    back = poly->toPath()
    _Assert(back  "polygon: open stroke toPath at 5e6 offset")
    ; 用 && 短路而不是 when 包裹：断言数固定，失败时不会连带少跑用例
    _Assert(back && abs(back->width() - 2.0) <= 1e-8
        "polygon: large offset stroke width")
    _Assert(back && poly->xor(back->toRegion())->area() <= 1e-6
        "polygon: large offset stroke roundtrip")
    ; 同量级下「像描边但宽度不等」的四边形必须仍然返回 nil；
    ; 只用三角形会恒为 nil（至少 4 条边才进入等宽判定），测不到容差放大
    trap = ycGeom::Polygon(list(
        ycGeom::Point(5.0e6:5.0e6)
        ycGeom::Point(list(5.0e6 + 10.0 5.0e6))
        ycGeom::Point(list(5.0e6 + 9.0 5.0e6 + 5.0))
        ycGeom::Point(list(5.0e6 + 1.0 5.0e6 + 5.0))
    ))
    _Assert(trap->toPath() == nil  "polygon: trapezoid at 5e6 not a stroke")
)

; 闭合描边环走的是 _PolyToPathRing 分支，失效门槛比开放描边更高
let((rad cosV sinV acc poly back)
    rad = 37.0 * 3.14159265358979323846 / 180.0
    cosV = cos(rad)
    sinV = sin(rad)
    foreach(p list(0.0:0.0 10.0:0.0 10.0:10.0 0.0:10.0 0.0:0.0)
        acc = tconc(acc list(
            cosV * car(p) - sinV * cadr(p) + 1.0e8
            sinV * car(p) + cosV * cadr(p) + 1.0e8
        ))
    )
    poly = car(ycGeom::Path(car(acc) ?width 2)->toRegion()->polygons())
    back = poly->toPath()
    _Assert(back  "polygon: closed ring toPath at 1e8 offset")
)

_TestChildDone = t

; END
