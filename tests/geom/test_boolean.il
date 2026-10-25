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

let((l_a l_b l_r)
    l_a = list(ycGeom::Polygon(list(
        ycGeom::Point(0 0) ycGeom::Point(4 0)
        ycGeom::Point(4 4) ycGeom::Point(0 4)
    )))
    l_b = list(ycGeom::Polygon(list(
        ycGeom::Point(2 2) ycGeom::Point(6 2)
        ycGeom::Point(6 6) ycGeom::Point(2 6)
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
        ycGeom::Point(0 0) ycGeom::Point(2 0)
        ycGeom::Point(2 2) ycGeom::Point(0 2)
    )))
    l_b = list(ycGeom::Polygon(list(
        ycGeom::Point(10 0) ycGeom::Point(12 0)
        ycGeom::Point(12 2) ycGeom::Point(10 2)
    )))
    _Assert(_BoolArea(ycGeom::_Boolean(l_a l_b 'union nil 1e-9)) == 8.0  "boolean: disjoint union")
    _Assert(ycGeom::_Boolean(l_a l_b 'intersection nil 1e-9) == nil  "boolean: disjoint intersection empty")
)

_AssertError(lambda(() ycGeom::_Boolean(nil nil 'bad nil 1e-9) t)  "boolean: bad operation")
_AssertError(lambda(() ycGeom::_Boolean(list(1) nil 'union nil 1e-9) t)  "boolean: non-Polygon input")

let((g_outer g_inner l_r)
    g_outer = ycGeom::Polygon(list(
        ycGeom::Point(0 0) ycGeom::Point(10 0)
        ycGeom::Point(10 10) ycGeom::Point(0 10)
    ))
    g_inner = ycGeom::Polygon(list(
        ycGeom::Point(3 3) ycGeom::Point(7 3)
        ycGeom::Point(7 7) ycGeom::Point(3 7)
    ))
    l_r = ycGeom::_Boolean(list(g_outer) list(g_inner) 'difference nil 1e-9)
    _Assert(_BoolArea(l_r) == 84.0  "boolean: difference creates hole")
    _Assert(length(car(l_r)->points()) > 8  "boolean: keyhole output")
    _Assert(!car(l_r)->contains(ycGeom::Point(5 5))  "boolean: hole excluded")
    _Assert(car(l_r)->contains(ycGeom::Point(1 1))  "boolean: outer included")
)

_TestBooleanDone = t

; END
