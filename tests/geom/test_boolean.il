_TestBooleanDone = nil

procedure(_BoolArea(l_polys "l")  ; -> float
    ; 求 Polygon 列表面积和（测试辅助）。
    ;
    ; **参数**
    ;   l_polys  (list[Polygon]) - 多边形列表
    ;
    ; **返回**
    ;   (float) - 面积和
    let((n_sum)
        n_sum = 0.0
        foreach(g_p l_polys
            n_sum = n_sum + g_p->area()
        )
        n_sum
    )
)

procedure(_AssertAxisSeams(l_polys "l")  ; -> t
    ; 断言 keyhole 切割边都是水平或垂直方向（测试辅助）。
    ;
    ; **参数**
    ;   l_polys  (list[Polygon]) - 多边形列表
    ;
    ; **返回**
    ;   (t) - 全部通过；否则测试失败
    let((n_seams n_len n_i g_a g_b t_seams)
        n_seams = 0
        foreach(g_p l_polys
            t_seams = ycGeom::_SeamKeys(g_p->points())
            n_len = length(g_p->points())
            for(n_i 1 n_len
                g_a = ycGeom::_Nth1(n_i g_p->points())
                g_b = ycGeom::_Nth1(
                    if(n_i == n_len 1 (n_i + 1)) g_p->points())
                when(t_seams[ycGeom::_EdgeKey(g_a g_b)] == 2
                    n_seams++
                    _Assert(ycGeom::_Near(g_a->x() g_b->x() 1e-9)
                        || ycGeom::_Near(g_a->y() g_b->y() 1e-9)
                        "boolean: keyhole seam is axis-aligned")
                )
            )
        )
        _Assert(n_seams > 0 "boolean: keyhole seam exists")
        t
    )
)

let((l_a l_b l_r)
    l_a = list(ycGeom::Polygon(list(
        ycGeom::Point(list(0 0)) ycGeom::Point(list(4 0))
        ycGeom::Point(list(4 4)) ycGeom::Point(list(0 4))
    )))
    l_b = list(ycGeom::Polygon(list(
        ycGeom::Point(list(2 2)) ycGeom::Point(list(6 2))
        ycGeom::Point(list(6 6)) ycGeom::Point(list(2 6))
    )))
    l_r = ycGeom::_Boolean(l_a l_b 'union nil 1e-9)
    _Assert(_BoolArea(l_r) == 28.0  "boolean: union area")
    l_r = ycGeom::_Boolean(l_a l_b 'intersection nil 1e-9)
    _Assert(_BoolArea(l_r) == 4.0  "boolean: intersection area")
    l_r = ycGeom::_Boolean(l_a l_b 'difference nil 1e-9)
    _Assert(_BoolArea(l_r) == 12.0  "boolean: difference area")
    l_r = ycGeom::_Boolean(l_a l_b 'xor nil 1e-9)
    _Assert(_BoolArea(l_r) == 24.0  "boolean: xor area")
)

let((g_a g_b g_r)
    g_a = ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))
    g_b = ycGeom::Polygon('((2 0) (6 0) (6 4) (2 4)))
    g_r = g_a->or(g_b)
    _Assert(length(g_r->polygons()) == 1  "boolean: clean union one polygon")
    _Assert(length(car(g_r->polygons())->points()) == 4  "boolean: clean collinear union")
)

let((l_a l_b l_r)
    l_a = list(ycGeom::Polygon(list(
        ycGeom::Point(list(0 0)) ycGeom::Point(list(2 0))
        ycGeom::Point(list(2 2)) ycGeom::Point(list(0 2))
    )))
    l_b = list(ycGeom::Polygon(list(
        ycGeom::Point(list(10 0)) ycGeom::Point(list(12 0))
        ycGeom::Point(list(12 2)) ycGeom::Point(list(10 2))
    )))
    _Assert(_BoolArea(ycGeom::_Boolean(l_a l_b 'union nil 1e-9)) == 8.0  "boolean: disjoint union")
    _Assert(ycGeom::_Boolean(l_a l_b 'intersection nil 1e-9) == nil  "boolean: disjoint intersection empty")
)

_AssertError(lambda(() ycGeom::_Boolean(nil nil 'bad nil 1e-9) t)  "boolean: bad operation")
_AssertError(lambda(() ycGeom::_Boolean(list(1) nil 'union nil 1e-9) t)  "boolean: non-Polygon input")

let((g_outer g_inner l_r)
    g_outer = ycGeom::Polygon(list(
        ycGeom::Point(list(0 0)) ycGeom::Point(list(10 0))
        ycGeom::Point(list(10 10)) ycGeom::Point(list(0 10))
    ))
    g_inner = ycGeom::Polygon(list(
        ycGeom::Point(list(3 3)) ycGeom::Point(list(7 3))
        ycGeom::Point(list(7 7)) ycGeom::Point(list(3 7))
    ))
    l_r = ycGeom::_Boolean(list(g_outer) list(g_inner) 'difference nil 1e-9)
    _AssertAxisSeams(l_r)
    _Assert(_BoolArea(l_r) == 84.0  "boolean: difference creates hole")
    _Assert(length(car(l_r)->points()) > 8  "boolean: keyhole output")
    _Assert(!car(l_r)->contains(ycGeom::Point(list(5 5)))  "boolean: hole excluded")
    _Assert(car(l_r)->contains(ycGeom::Point(list(1 1)))  "boolean: outer included")
)

let((g_outer g_h1 g_h2 g_r)
    g_outer = ycGeom::Polygon('((0 0) (20 0) (20 10) (0 10)))
    g_h1 = ycGeom::Polygon('((1 1) (3 1) (3 3) (1 3)))
    g_h2 = ycGeom::Polygon('((5 1) (7 1) (7 3) (5 3)))
    g_r = ycGeom::_Boolean(list(g_outer) list(g_h1 g_h2) 'difference nil 1e-9)
    _AssertAxisSeams(g_r)
    _Assert(_BoolArea(g_r) == 192.0  "boolean: two holes area")
    _Assert(!car(g_r)->contains(ycGeom::Point(list(2 2)))  "boolean: first hole excluded")
    _Assert(!car(g_r)->contains(ycGeom::Point(list(6 2)))  "boolean: second hole excluded")
)

let((g_outer g_hole g_r)
    g_outer = ycGeom::Polygon('((0 0) (10 0) (0 10)))
    g_hole = ycGeom::Polygon('((1 1) (3 1) (3 3) (1 3)))
    g_r = ycGeom::_Boolean(list(g_outer) list(g_hole) 'difference nil 1e-9)
    _AssertAxisSeams(g_r)
    _Assert(_BoolArea(g_r) == 46.0  "boolean: slanted outer area")
)

let((g_a g_b g_r)
    g_a = ycGeom::Polygon(list(
        ycGeom::Point(list(0 0)) ycGeom::Point(list(1e-5 0))
        ycGeom::Point(list(1e-5 1)) ycGeom::Point(list(0 1))
    ))
    g_b = ycGeom::Polygon(list(
        ycGeom::Point(list(1e-5 + 5e-10 0)) ycGeom::Point(list(1 0))
        ycGeom::Point(list(1 1)) ycGeom::Point(list(1e-5 + 5e-10 1))
    ))
    g_r = errset(g_a->or(g_b) nil)
    _Assert(g_r && length(car(g_r)->polygons()) == 1
        "boolean: near shared edge one polygon")
    _Assert(g_r && abs(car(g_r)->area() - 1.0) <= 1e-9
        "boolean: near shared edge area")
)

_Assert(ycGeom::_PtKey(ycGeom::Point(list(1e9 0)))
    != ycGeom::_PtKey(ycGeom::Point(list(1e9 + 100 0)))
    "point: key keeps distinct large coordinates")

let((g_a g_b g_r)
    g_a = ycGeom::Polygon(list(
        ycGeom::Point(list(1e3 0)) ycGeom::Point(list(1e3 + 1e-5 0))
        ycGeom::Point(list(1e3 + 1e-5 1)) ycGeom::Point(list(1e3 1))
    ))
    g_b = ycGeom::Polygon(list(
        ycGeom::Point(list(1e3 + 1e-5 + 5e-10 0)) ycGeom::Point(list(1e4 0))
        ycGeom::Point(list(1e4 1)) ycGeom::Point(list(1e3 + 1e-5 + 5e-10 1))
    ))
    g_r = errset(g_a->or(g_b) nil)
    _Assert(g_r && length(car(g_r)->polygons()) == 1
        "boolean: large cell coordinate one polygon")
    _Assert(g_r && abs(car(g_r)->area() - 9000.0) <= 1e-9
        "boolean: large cell coordinate area")
)
_Assert(ycGeom::_PointInRing(
    list(ycGeom::Point(list(0 0)) ycGeom::Point(list(1 0))
        ycGeom::Point(list(1 1)) ycGeom::Point(list(0 1)))
    ycGeom::Point(list(0 1)) 1e-9)
    "point: point-in-ring boundary is deterministic")

_TestBooleanDone = t

; END
