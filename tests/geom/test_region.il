_TestRegionDone = nil

let((r)
    r = ycGeom::Region(nil)
    _Assert(classOf(r) == findClass('ycGeom::Region)  "region: class identity")
    _Assert(r->isEmpty()  "region: empty")
    _Assert(r->area() == 0.0  "region: empty area")
    _Assert(r->perimeter() == 0.0  "region: empty perimeter")
    _Assert(r->bBox() == nil  "region: empty bBox")
    _Assert(r->toRect() == nil  "region: empty toRect")
    _Assert(r->centroid() == nil  "region: empty centroid")
    _Assert(r->toSkill() == nil  "region: empty toSkill")
    _Assert(!r->contains(ycGeom::Point(0:0))  "region: empty contains")
)

let((a b r)
    a = ycGeom::Polygon(list(
        ycGeom::Point(0:0) ycGeom::Point(4:0)
        ycGeom::Point(4:4) ycGeom::Point(0:4)
    ))
    b = ycGeom::Polygon(list(
        ycGeom::Point(2:2) ycGeom::Point(6:2)
        ycGeom::Point(6:6) ycGeom::Point(2:6)
    ))
    r = ycGeom::Region(list(a b))
    _Assert(r->area() == 28.0  "region: normalized union area")
    _Assert(r->contains(ycGeom::Point(1:1))  "region: contains A")
    _Assert(r->contains(ycGeom::Point(5:5))  "region: contains B")
    _Assert(r->contains(ycGeom::Point(3:3))  "region: contains overlap")
    _Assert(!r->contains(ycGeom::Point(9:9))  "region: outside")
    _Assert(r->bBox() == list(list(0.0 0.0) list(6.0 6.0))  "region: bBox")
    _Assert(r->toRect()->toSkill() == list(list(0.0 0.0) list(6.0 6.0))  "region: toRect")
    _Assert(r->perimeter() == 24.0  "region: perimeter")
    _Assert(length(r->toSkill()) > 0  "region: toSkill")
    _Assert(car(r->centroid()->toSkill()) == 3.0  "region: centroid x")
)

let((a b r)
    a = ycGeom::Polygon(list(
        ycGeom::Point(0:0) ycGeom::Point(4:0)
        ycGeom::Point(4:4) ycGeom::Point(0:4)
    ))
    b = ycGeom::Polygon(list(
        ycGeom::Point(2:2) ycGeom::Point(6:2)
        ycGeom::Point(6:6) ycGeom::Point(2:6)
    ))
    _Assert(ycGeom::Region(list(a b) ?normalize nil)->area() == 32.0  "region: trust input area")
    _Assert(ycGeom::Region(list(a))->or(ycGeom::Region(list(b)))->area() == 28.0  "region: or")
    _Assert(ycGeom::Region(list(a))->and(ycGeom::Region(list(b)))->area() == 4.0  "region: and")
    _Assert(ycGeom::Region(list(a))->not(ycGeom::Region(list(b)))->area() == 12.0  "region: not")
    _Assert(ycGeom::Region(list(a))->xor(ycGeom::Region(list(b)))->area() == 24.0  "region: xor")
    _Assert(ycGeom::Region(list(a))->onBoundary(ycGeom::Point(0:0))  "region: on boundary")
    _Assert(!ycGeom::Region(list(a))->onBoundary(ycGeom::Point(1:1))  "region: not on boundary")
)

let((r)
    r = ycGeom::Region(list(ycGeom::Polygon(list(
        ycGeom::Point(0:0) ycGeom::Point(2:0) ycGeom::Point(4:0)
        ycGeom::Point(4:4) ycGeom::Point(0:4)
    ))))
    _Assert(length(car(r->polygons())->points()) == 4  "region: normalize cleans collinear")
)

_AssertError(lambda(() ycGeom::Region("bad") t)  "region: non-list rejected")
_AssertError(lambda(() ycGeom::Region(list(1)) t)  "region: non-Polygon rejected")
_AssertError(lambda(() ycGeom::Region(list(0 0 1 0 1 1)) t)
    "region: flat number list rejected")
_AssertError(lambda(() ycGeom::Region(nil ?normalize "bad") t)  "region: bad normalize")
_AssertError(lambda(() ycGeom::Region(list(ycGeom::Polygon(list(
    ycGeom::Point(0:0) ycGeom::Point(1:0) ycGeom::Point(0:1)
))) ?grid 0) t)  "region: bad grid")
_AssertError(lambda(() ycGeom::Region(list())->or(1) t)  "region: bad or type")

let((r src)
    src = ycGeom::Region(list(ycGeom::Polygon(list(
        ycGeom::Point(0:0) ycGeom::Point(4:0)
        ycGeom::Point(4:4) ycGeom::Point(0:4)
    ))))
    r = ycGeom::Region(list('((0 0) (4 0) (4 4) (0 4))))
    _Assert(r->area() == src->area()  "region: pair list form")
    _Assert(ycGeom::Region(src->toSkill())->area() == src->area()  "region: toSkill roundtrip")
)
_AssertError(lambda(() ycGeom::Region(list(1)) t)  "region: scalar element rejected")

let((polys p r i size step x y one)
    size = 1e6
    step = 2e6
    x = 1e9
    y = 3.7e8
    for(i2 0 999
        p = ycGeom::Polygon(list(
            ycGeom::Point(list(x + i2 * step y))
            ycGeom::Point(list(x + i2 * step + size y))
            ycGeom::Point(list(x + i2 * step y + size))
        ))
        polys = tconc(polys p)
    )
    r = ycGeom::Region(car(polys) ?normalize nil)
    one = car(r->polygons())->perimeter()
    _Assert(abs(r->perimeter() - 1000.0 * one) <= 1e-6
        "region: perimeter accumulation stable")
)

; 大面积 + 大量小面积混合时，小项不得被朴素累加吞掉
let((polys big tiny r i tiny2 exact)
    big = ycGeom::Polygon(list(0:0 32000:0 32000:32000 0:32000))
    tiny = ycGeom::Polygon(list(
        ycGeom::Point(40000:0) ycGeom::Point(40000.0001:0)
        ycGeom::Point(40000.0001:0.0001) ycGeom::Point(40000:0.0001)
    ))
    tiny2 = tiny->area()
    polys = tconc(nil big)
    for(i2 1 1000
        polys = tconc(polys tiny)
    )
    r = ycGeom::Region(car(polys) ?normalize nil)
    exact = 1024000000.0 + 1000.0 * tiny2
    _Assert(abs(r->area() - exact) <= 1e-6
        "region: area keeps small terms")
)

; 质心的三个加权和各自量级差别极大，必须独立补偿
let((polys big tiny r c i tiny2 exact exact_y)
    big = ycGeom::Polygon(list(
        ycGeom::Point(984000:984000) ycGeom::Point(1016000:984000)
        ycGeom::Point(1016000:1016000) ycGeom::Point(984000:1016000)
    ))
    ; 小方形放在与大方形的 y 不同的位置，让 Σa·y 那一路也产生可见位移
    tiny = ycGeom::Polygon(list(
        ycGeom::Point(3000000:2000000) ycGeom::Point(3000000.0001:2000000)
        ycGeom::Point(3000000.0001:2000000.0001)
        ycGeom::Point(3000000:2000000.0001)
    ))
    tiny2 = tiny->area()
    polys = tconc(nil big)
    for(i2 1 1000
        polys = tconc(polys tiny)
    )
    r = ycGeom::Region(car(polys) ?normalize nil)
    exact = (1024000000.0 * 1.0e6 + 1000.0 * tiny2 * 3.0e6)
        / (1024000000.0 + 1000.0 * tiny2)
    exact_y = (1024000000.0 * 1.0e6 + 1000.0 * tiny2 * 2.0e6)
        / (1024000000.0 + 1000.0 * tiny2)
    c = r->centroid()
    _Assert(abs(c->x() - exact) <= 1e-9
        "region: centroid keeps small weights")
    _Assert(abs(c->y() - exact_y) <= 1e-9
        "region: centroid y keeps small weights")
)

_TestChildDone = t

; END
