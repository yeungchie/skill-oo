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
        ycGeom::Point(0:0) ycGeom::Point(4:0)
        ycGeom::Point(4:4) ycGeom::Point(0:4)
    )))
    l_b = list(ycGeom::Polygon(list(
        ycGeom::Point(2:2) ycGeom::Point(6:2)
        ycGeom::Point(6:6) ycGeom::Point(2:6)
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
        ycGeom::Point(0:0) ycGeom::Point(2:0)
        ycGeom::Point(2:2) ycGeom::Point(0:2)
    )))
    l_b = list(ycGeom::Polygon(list(
        ycGeom::Point(10:0) ycGeom::Point(12:0)
        ycGeom::Point(12:2) ycGeom::Point(10:2)
    )))
    _Assert(_BoolArea(ycGeom::_Boolean(l_a l_b 'union nil 1e-9)) == 8.0  "boolean: disjoint union")
    _Assert(ycGeom::_Boolean(l_a l_b 'intersection nil 1e-9) == nil  "boolean: disjoint intersection empty")
)

_AssertError(lambda(() ycGeom::_Boolean(nil nil 'bad nil 1e-9) t)  "boolean: bad operation")
_AssertError(lambda(() ycGeom::_Boolean(list(1) nil 'union nil 1e-9) t)  "boolean: non-Polygon input")

let((g_outer g_inner l_r)
    g_outer = ycGeom::Polygon(list(
        ycGeom::Point(0:0) ycGeom::Point(10:0)
        ycGeom::Point(10:10) ycGeom::Point(0:10)
    ))
    g_inner = ycGeom::Polygon(list(
        ycGeom::Point(3:3) ycGeom::Point(7:3)
        ycGeom::Point(7:7) ycGeom::Point(3:7)
    ))
    l_r = ycGeom::_Boolean(list(g_outer) list(g_inner) 'difference nil 1e-9)
    _AssertAxisSeams(l_r)
    _Assert(_BoolArea(l_r) == 84.0  "boolean: difference creates hole")
    _Assert(length(car(l_r)->points()) > 8  "boolean: keyhole output")
    _Assert(!car(l_r)->contains(ycGeom::Point(5:5))  "boolean: hole excluded")
    _Assert(car(l_r)->contains(ycGeom::Point(1:1))  "boolean: outer included")
)

let((g_outer g_h1 g_h2 g_r)
    g_outer = ycGeom::Polygon('((0 0) (20 0) (20 10) (0 10)))
    g_h1 = ycGeom::Polygon('((1 1) (3 1) (3 3) (1 3)))
    g_h2 = ycGeom::Polygon('((5 1) (7 1) (7 3) (5 3)))
    g_r = ycGeom::_Boolean(list(g_outer) list(g_h1 g_h2) 'difference nil 1e-9)
    _AssertAxisSeams(g_r)
    _Assert(_BoolArea(g_r) == 192.0  "boolean: two holes area")
    _Assert(!car(g_r)->contains(ycGeom::Point(2:2))  "boolean: first hole excluded")
    _Assert(!car(g_r)->contains(ycGeom::Point(6:2))  "boolean: second hole excluded")
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
        ycGeom::Point(0:0) ycGeom::Point(1e-5:0)
        ycGeom::Point(1e-5:1) ycGeom::Point(0:1)
    ))
    g_b = ycGeom::Polygon(list(
        ycGeom::Point(list(1e-5 + 5e-10 0)) ycGeom::Point(1:0)
        ycGeom::Point(1:1) ycGeom::Point(list(1e-5 + 5e-10 1))
    ))
    g_r = errset(g_a->or(g_b) nil)
    _Assert(g_r && length(car(g_r)->polygons()) == 1
        "boolean: near shared edge one polygon")
    _Assert(g_r && abs(car(g_r)->area() - 1.0) <= 1e-9
        "boolean: near shared edge area")
)

_Assert(ycGeom::_PtKey(ycGeom::Point(1e9:0))
    != ycGeom::_PtKey(ycGeom::Point(list(1e9 + 100 0)))
    "point: key keeps distinct large coordinates")

let((g_a g_b g_r)
    g_a = ycGeom::Polygon(list(
        ycGeom::Point(1e3:0) ycGeom::Point(list(1e3 + 1e-5 0))
        ycGeom::Point(list(1e3 + 1e-5 1)) ycGeom::Point(1e3:1)
    ))
    g_b = ycGeom::Polygon(list(
        ycGeom::Point(list(1e3 + 1e-5 + 5e-10 0)) ycGeom::Point(1e4:0)
        ycGeom::Point(1e4:1) ycGeom::Point(list(1e3 + 1e-5 + 5e-10 1))
    ))
    g_r = errset(g_a->or(g_b) nil)
    _Assert(g_r && length(car(g_r)->polygons()) == 1
        "boolean: large cell coordinate one polygon")
    _Assert(g_r && abs(car(g_r)->area() - 9000.0) <= 1e-9
        "boolean: large cell coordinate area")
)
let((n_x n_bx g_a g_b l_r)
    n_x = 1e7 + 10.0
    n_bx = n_x + 4e-9
    g_a = ycGeom::Polygon(list(
        ycGeom::Point(1e7:0)
        ycGeom::Point(n_x:0)
        ycGeom::Point(n_x:10)
        ycGeom::Point(1e7:10)
    ))
    g_b = ycGeom::Polygon(list(
        ycGeom::Point(list(n_bx 0))
        ycGeom::Point(1e7 + 20.0:0)
        ycGeom::Point(1e7 + 20.0:10)
        ycGeom::Point(list(n_bx 10))
    ))
    l_r = errset(g_a->or(g_b) nil)
    _Assert(l_r && length(car(l_r)->polygons()) == 1
        "boolean: relative canonicalization one polygon")
    _Assert(l_r && abs(car(l_r)->area() - 200.0) <= 1e-6
        "boolean: relative canonicalization area")
)
let((g_outer g_h1 g_h2 l_r g_p t_seams)
    g_outer = ycGeom::Polygon('((0 0) (20 0) (20 10) (0 10)))
    g_h1 = ycGeom::Polygon('((1 1) (3 1) (3 3) (1 3)))
    g_h2 = ycGeom::Polygon('((5 1) (7 1) (7 3) (5 3)))
    l_r = ycGeom::_Boolean(list(g_outer) list(g_h1 g_h2)
        'difference nil 1e-9)
    _Assert(l_r && abs(car(l_r)->area() - 192.0) <= 1e-9
        "boolean: multiple holes area")
    g_p = car(l_r)
    t_seams = ycGeom::_SeamKeys(g_p->points())
    _Assert(!t_seams[ycGeom::_EdgeKey(
        ycGeom::Point(3:3) ycGeom::Point(5:3))]
        "boolean: hole bridge avoids sibling hole")
)
_Assert(ycGeom::_OnSegment(
    ycGeom::Point(1e8:1e8)
    ycGeom::Point(1e8 + 1.0:1e8 + 1.0)
    ycGeom::Point(list(1e8 + 0.5 1e8 + 0.5 + 1e-8))
    1e-9)
    "point: relative cross tolerance")
_Assert(ycGeom::_PointInRing(
    list(ycGeom::Point(0:0) ycGeom::Point(1:0)
        ycGeom::Point(1:1) ycGeom::Point(0:1))
    ycGeom::Point(0:1) 1e-9)
    "point: point-in-ring boundary is deterministic")

let((l_a l_b l_r g_poly)
    ; 纯数据入口：单多边形点列（Polygon->toSkill() 形式），运算名在首位
    l_a = '((0.0 0.0) (4.0 0.0) (4.0 4.0) (0.0 4.0))
    l_b = '((2.0 2.0) (6.0 2.0) (6.0 6.0) (2.0 6.0))
    l_r = ycGeom::Boolean('or l_a l_b)
    _Assert(ycGeom::Region(l_r)->area() == 28.0
        "boolean: native or area")
    _Assert(ycGeom::Region(ycGeom::Boolean('and l_a l_b))->area() == 4.0
        "boolean: native and area")
    _Assert(ycGeom::Region(ycGeom::Boolean('not l_a l_b))->area() == 12.0
        "boolean: native not area")
    _Assert(ycGeom::Region(ycGeom::Boolean('xor l_a l_b))->area() == 24.0
        "boolean: native xor area")
    _Assert(equal(ycGeom::Boolean("or" l_a l_b) l_r)
        "boolean: native accepts string operation")
    _AssertError(lambda(() ycGeom::Boolean("union" l_a l_b))
        "boolean: native rejects string union spelling")
    ; 结果形态固定为 Region->toSkill()：点列列表，可直接回构 Polygon
    _Assert(length(l_r) == 1 && listp(car(l_r)) && listp(car(car(l_r)))
        "boolean: native result is polygon list")
    g_poly = ycGeom::Polygon(car(l_r))
    _Assert(abs(g_poly->area() - 28.0) <= 1e-9
        "boolean: native result rebuilds polygon")
)

let((l_a l_b l_r)
    ; 点列列表（Region 形式）输入：B 把两个分离方块连成一块
    l_a = '(((0.0 0.0) (2.0 0.0) (2.0 2.0) (0.0 2.0))
           ((10.0 0.0) (12.0 0.0) (12.0 2.0) (10.0 2.0)))
    l_b = '((1.0 0.0) (11.0 0.0) (11.0 2.0) (1.0 2.0))
    l_r = ycGeom::Boolean('or l_a l_b)
    _Assert(length(l_r) == 1
        "boolean: native region input merges to one polygon")
    _Assert(abs(ycGeom::Region(l_r)->area() - 24.0) <= 1e-9
        "boolean: native region input area")
)

let((l_a l_b l_r)
    ; Region 成员先按 or 合并：两个重叠方块整体面积 28，不与奇偶规则纠缠
    l_a = '(((0.0 0.0) (4.0 0.0) (4.0 4.0) (0.0 4.0))
           ((2.0 2.0) (6.0 2.0) (6.0 6.0) (2.0 6.0)))
    l_b = '((-1.0 -1.0) (7.0 -1.0) (7.0 7.0) (-1.0 7.0))
    l_r = ycGeom::Boolean('and l_a l_b)
    _Assert(length(l_r) == 1
        "boolean: native operands are unioned before the op")
    _Assert(abs(ycGeom::Region(l_r)->area() - 28.0) <= 1e-9
        "boolean: native merged operand area")
)

let((l_a l_r)
    ; l_b 传 nil 表示空集：or 时结果就是 l_a 自身求并
    l_a = '(((0.0 0.0) (4.0 0.0) (4.0 4.0) (0.0 4.0))
           ((2.0 2.0) (6.0 2.0) (6.0 6.0) (2.0 6.0)))
    l_r = ycGeom::Boolean('or l_a nil)
    _Assert(length(l_r) == 1
        "boolean: native or with nil l_b merges overlap")
    _Assert(abs(ycGeom::Region(l_r)->area() - 28.0) <= 1e-9
        "boolean: native or with nil l_b area")
    _AssertError(lambda(() ycGeom::Boolean('and l_a nil))
        "boolean: native and rejects nil l_b")
    _AssertError(lambda(() ycGeom::Boolean('not l_a nil))
        "boolean: native not rejects nil l_b")
    _AssertErrorMsg(lambda(() ycGeom::Boolean('xor l_a nil))
        "only when the operation is or" "boolean: native reports nil l_b on xor")
)

let((l_r)
    ; 两点矩形对角（Rect->toSkill() 形式）输入
    l_r = ycGeom::Boolean('and '((0.0 0.0) (4.0 4.0)) '((2.0 2.0) (6.0 6.0)))
    _Assert(abs(ycGeom::Region(l_r)->area() - 4.0) <= 1e-9
        "boolean: native rect diagonal input")
)

_Assert(ycGeom::Boolean('and
    '((0.0 0.0) (1.0 0.0) (1.0 1.0))
    '((5.0 5.0) (6.0 5.0) (6.0 6.0))) == nil
    "boolean: native empty result is nil")

_Assert(abs(ycGeom::Region(ycGeom::Boolean('or nil
        '((2.0 2.0) (6.0 2.0) (6.0 6.0) (2.0 6.0))))->area() - 16.0) <= 1e-9
    "boolean: native nil operand passes the other side")

_Assert(abs(ycGeom::Region(ycGeom::Boolean('or
        '((0.0 0.0) (4.0 0.0) (4.0 4.0) (0.0 4.0))
        '((2.0 2.0) (6.0 2.0) (6.0 6.0) (2.0 6.0))
        ?grid 0.5 ?eps 1e-6))->area() - 28.0) <= 1e-6
    "boolean: native accepts grid and eps options")

let((g_path l_r)
    ; 带宽度对象没有点列形式：Path 走 toRegion()->toSkill() 后参与运算
    g_path = ycGeom::Path('((0.0 0.0) (10.0 0.0)) ?width 2.0)
    l_r = ycGeom::Boolean('and g_path->toRegion()->toSkill()
        '((0.0 -1.0) (1.0 -1.0) (1.0 1.0) (0.0 1.0)))
    _Assert(abs(ycGeom::Region(l_r)->area() - 2.0) <= 1e-9
        "boolean: path region participates")
)

let((l_a l_b)
    l_a = '((0.0 0.0) (4.0 0.0) (4.0 4.0) (0.0 4.0))
    l_b = '((2.0 2.0) (6.0 2.0) (6.0 6.0) (2.0 6.0))
    _AssertError(lambda(() ycGeom::Boolean('union l_a l_b))
        "boolean: native rejects union spelling")
    _AssertErrorMsg(lambda(() ycGeom::Boolean('union l_a l_b))
        "unknown operation" "boolean: native reports unknown operation")
    _AssertError(lambda(() ycGeom::Boolean('or "abc" l_b))
        "boolean: native rejects string operand")
    _AssertError(lambda(() ycGeom::Boolean('or l_a 42))
        "boolean: native rejects number operand")
    _AssertError(lambda(() ycGeom::Boolean('or
            '((0.0 0.0) (1.0 0.0) ("x" 1.0)) l_b))
        "boolean: native rejects malformed point array")
)

_TestBooleanDone = t

; END
