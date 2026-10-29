_TestRegionDone = nil

let((g_r)
    g_r = ycGeom::Region(nil)
    _Assert(classOf(g_r) == findClass('ycGeom::Region)  "region: class identity")
    _Assert(g_r->isEmpty()  "region: empty")
    _Assert(g_r->area() == 0.0  "region: empty area")
    _Assert(g_r->perimeter() == 0.0  "region: empty perimeter")
    _Assert(g_r->bBox() == nil  "region: empty bBox")
    _Assert(g_r->toRect() == nil  "region: empty toRect")
    _Assert(g_r->centroid() == nil  "region: empty centroid")
    _Assert(g_r->toSkill() == nil  "region: empty toSkill")
    _Assert(!g_r->contains(ycGeom::Point(0:0))  "region: empty contains")
)

let((g_a g_b g_r)
    g_a = ycGeom::Polygon(list(
        ycGeom::Point(0:0) ycGeom::Point(4:0)
        ycGeom::Point(4:4) ycGeom::Point(0:4)
    ))
    g_b = ycGeom::Polygon(list(
        ycGeom::Point(2:2) ycGeom::Point(6:2)
        ycGeom::Point(6:6) ycGeom::Point(2:6)
    ))
    g_r = ycGeom::Region(list(g_a g_b))
    _Assert(g_r->area() == 28.0  "region: normalized union area")
    _Assert(g_r->contains(ycGeom::Point(1:1))  "region: contains A")
    _Assert(g_r->contains(ycGeom::Point(5:5))  "region: contains B")
    _Assert(g_r->contains(ycGeom::Point(3:3))  "region: contains overlap")
    _Assert(!g_r->contains(ycGeom::Point(9:9))  "region: outside")
    _Assert(g_r->bBox() == list(list(0.0 0.0) list(6.0 6.0))  "region: bBox")
    _Assert(g_r->toRect()->toSkill() == list(list(0.0 0.0) list(6.0 6.0))  "region: toRect")
    _Assert(g_r->perimeter() == 24.0  "region: perimeter")
    _Assert(length(g_r->toSkill()) > 0  "region: toSkill")
    _Assert(car(g_r->centroid()->toSkill()) == 3.0  "region: centroid x")
)

let((g_a g_b g_r)
    g_a = ycGeom::Polygon(list(
        ycGeom::Point(0:0) ycGeom::Point(4:0)
        ycGeom::Point(4:4) ycGeom::Point(0:4)
    ))
    g_b = ycGeom::Polygon(list(
        ycGeom::Point(2:2) ycGeom::Point(6:2)
        ycGeom::Point(6:6) ycGeom::Point(2:6)
    ))
    _Assert(ycGeom::Region(list(g_a g_b) ?normalize nil)->area() == 32.0  "region: trust input area")
    _Assert(ycGeom::Region(list(g_a))->or(ycGeom::Region(list(g_b)))->area() == 28.0  "region: or")
    _Assert(ycGeom::Region(list(g_a))->and(ycGeom::Region(list(g_b)))->area() == 4.0  "region: and")
    _Assert(ycGeom::Region(list(g_a))->not(ycGeom::Region(list(g_b)))->area() == 12.0  "region: not")
    _Assert(ycGeom::Region(list(g_a))->xor(ycGeom::Region(list(g_b)))->area() == 24.0  "region: xor")
    _Assert(ycGeom::Region(list(g_a))->onBoundary(ycGeom::Point(0:0))  "region: on boundary")
    _Assert(!ycGeom::Region(list(g_a))->onBoundary(ycGeom::Point(1:1))  "region: not on boundary")
)

let((g_r)
    g_r = ycGeom::Region(list(ycGeom::Polygon(list(
        ycGeom::Point(0:0) ycGeom::Point(2:0) ycGeom::Point(4:0)
        ycGeom::Point(4:4) ycGeom::Point(0:4)
    ))))
    _Assert(length(car(g_r->polygons())->points()) == 4  "region: normalize cleans collinear")
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

let((g_r g_src)
    g_src = ycGeom::Region(list(ycGeom::Polygon(list(
        ycGeom::Point(0:0) ycGeom::Point(4:0)
        ycGeom::Point(4:4) ycGeom::Point(0:4)
    ))))
    g_r = ycGeom::Region(list('((0 0) (4 0) (4 4) (0 4))))
    _Assert(g_r->area() == g_src->area()  "region: pair list form")
    _Assert(ycGeom::Region(g_src->toSkill())->area() == g_src->area()  "region: toSkill roundtrip")
)
_AssertError(lambda(() ycGeom::Region(list(1)) t)  "region: scalar element rejected")

let((l_polys g_p g_r n_i n_size n_step n_x n_y n_one)
    n_size = 1e6
    n_step = 2e6
    n_x = 1e9
    n_y = 3.7e8
    for(n_i 0 999
        g_p = ycGeom::Polygon(list(
            ycGeom::Point(list(n_x + n_i * n_step n_y))
            ycGeom::Point(list(n_x + n_i * n_step + n_size n_y))
            ycGeom::Point(list(n_x + n_i * n_step n_y + n_size))
        ))
        l_polys = tconc(l_polys g_p)
    )
    g_r = ycGeom::Region(car(l_polys) ?normalize nil)
    n_one = car(g_r->polygons())->perimeter()
    _Assert(abs(g_r->perimeter() - 1000.0 * n_one) <= 1e-6
        "region: perimeter accumulation stable")
)

_TestRegionDone = t

; END
