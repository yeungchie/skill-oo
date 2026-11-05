_TestBooleanDone = nil

procedure(_BoolArea(l_polys "l")  ; -> float
    ; 求 Polygon 列表面积和（测试辅助）。
    ;
    ; **参数**
    ;   l_polys  (list[Polygon]) - 多边形列表
    ;
    ; **返回**
    ;   (float) - 面积和
    let((sum)
        sum = 0.0
        foreach(p l_polys
            sum = sum + p->area()
        )
        sum
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
    let((seams len i a2 b2 seams2)
        seams = 0
        foreach(p l_polys
            seams2 = ycGeom::_SeamKeys(p->points())
            len = length(p->points())
            for(i2 1 len
                a2 = ycGeom::_Nth1(i2 p->points())
                b2 = ycGeom::_Nth1(
                    if(i2 == len 1 (i2 + 1)) p->points())
                when(seams2[ycGeom::_EdgeKey(a2 b2)] == 2
                    seams++
                    _Assert(ycGeom::_Near(a2->x() b2->x() 1e-9)
                        || ycGeom::_Near(a2->y() b2->y() 1e-9)
                        "boolean: keyhole seam is axis-aligned")
                )
            )
        )
        _Assert(seams > 0 "boolean: keyhole seam exists")
        t
    )
)

let((a2 b2 r)
    a2 = list(ycGeom::Polygon(list(
        ycGeom::Point(0:0) ycGeom::Point(4:0)
        ycGeom::Point(4:4) ycGeom::Point(0:4)
    )))
    b2 = list(ycGeom::Polygon(list(
        ycGeom::Point(2:2) ycGeom::Point(6:2)
        ycGeom::Point(6:6) ycGeom::Point(2:6)
    )))
    r = ycGeom::_Boolean(a2 b2 'union nil 1e-9)
    _Assert(_BoolArea(r) == 28.0  "boolean: union area")
    r = ycGeom::_Boolean(a2 b2 'intersection nil 1e-9)
    _Assert(_BoolArea(r) == 4.0  "boolean: intersection area")
    r = ycGeom::_Boolean(a2 b2 'difference nil 1e-9)
    _Assert(_BoolArea(r) == 12.0  "boolean: difference area")
    r = ycGeom::_Boolean(a2 b2 'xor nil 1e-9)
    _Assert(_BoolArea(r) == 24.0  "boolean: xor area")
)

let((a2 b2 r)
    a2 = ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))
    b2 = ycGeom::Polygon('((2 0) (6 0) (6 4) (2 4)))
    r = a2->or(b2)
    _Assert(length(r->polygons()) == 1  "boolean: clean union one polygon")
    _Assert(length(car(r->polygons())->points()) == 4  "boolean: clean collinear union")
)

let((a2 b2 r)
    a2 = list(ycGeom::Polygon(list(
        ycGeom::Point(0:0) ycGeom::Point(2:0)
        ycGeom::Point(2:2) ycGeom::Point(0:2)
    )))
    b2 = list(ycGeom::Polygon(list(
        ycGeom::Point(10:0) ycGeom::Point(12:0)
        ycGeom::Point(12:2) ycGeom::Point(10:2)
    )))
    _Assert(_BoolArea(ycGeom::_Boolean(a2 b2 'union nil 1e-9)) == 8.0  "boolean: disjoint union")
    _Assert(ycGeom::_Boolean(a2 b2 'intersection nil 1e-9) == nil  "boolean: disjoint intersection empty")
)

_AssertError(lambda(() ycGeom::_Boolean(nil nil 'bad nil 1e-9) t)  "boolean: bad operation")
_AssertError(lambda(() ycGeom::_Boolean(list(1) nil 'union nil 1e-9) t)  "boolean: non-Polygon input")

let((outer inner r)
    outer = ycGeom::Polygon(list(
        ycGeom::Point(0:0) ycGeom::Point(10:0)
        ycGeom::Point(10:10) ycGeom::Point(0:10)
    ))
    inner = ycGeom::Polygon(list(
        ycGeom::Point(3:3) ycGeom::Point(7:3)
        ycGeom::Point(7:7) ycGeom::Point(3:7)
    ))
    r = ycGeom::_Boolean(list(outer) list(inner) 'difference nil 1e-9)
    _AssertAxisSeams(r)
    _Assert(_BoolArea(r) == 84.0  "boolean: difference creates hole")
    _Assert(length(car(r)->points()) > 8  "boolean: keyhole output")
    _Assert(!car(r)->contains(ycGeom::Point(5:5))  "boolean: hole excluded")
    _Assert(car(r)->contains(ycGeom::Point(1:1))  "boolean: outer included")
)

let((outer h1 h2 r)
    outer = ycGeom::Polygon('((0 0) (20 0) (20 10) (0 10)))
    h1 = ycGeom::Polygon('((1 1) (3 1) (3 3) (1 3)))
    h2 = ycGeom::Polygon('((5 1) (7 1) (7 3) (5 3)))
    r = ycGeom::_Boolean(list(outer) list(h1 h2) 'difference nil 1e-9)
    _AssertAxisSeams(r)
    _Assert(_BoolArea(r) == 192.0  "boolean: two holes area")
    _Assert(!car(r)->contains(ycGeom::Point(2:2))  "boolean: first hole excluded")
    _Assert(!car(r)->contains(ycGeom::Point(6:2))  "boolean: second hole excluded")
)

let((outer hole r)
    outer = ycGeom::Polygon('((0 0) (10 0) (0 10)))
    hole = ycGeom::Polygon('((1 1) (3 1) (3 3) (1 3)))
    r = ycGeom::_Boolean(list(outer) list(hole) 'difference nil 1e-9)
    _AssertAxisSeams(r)
    _Assert(_BoolArea(r) == 46.0  "boolean: slanted outer area")
)

let((a2 b2 r)
    a2 = ycGeom::Polygon(list(
        ycGeom::Point(0:0) ycGeom::Point(1e-5:0)
        ycGeom::Point(1e-5:1) ycGeom::Point(0:1)
    ))
    b2 = ycGeom::Polygon(list(
        ycGeom::Point(list(1e-5 + 5e-10 0)) ycGeom::Point(1:0)
        ycGeom::Point(1:1) ycGeom::Point(list(1e-5 + 5e-10 1))
    ))
    r = errset(a2->or(b2) nil)
    _Assert(r && length(car(r)->polygons()) == 1
        "boolean: near shared edge one polygon")
    _Assert(r && abs(car(r)->area() - 1.0) <= 1e-9
        "boolean: near shared edge area")
)

_Assert(ycGeom::_PtKey(ycGeom::Point(1e9:0))
    != ycGeom::_PtKey(ycGeom::Point(list(1e9 + 100 0)))
    "point: key keeps distinct large coordinates")

let((a2 b2 r)
    a2 = ycGeom::Polygon(list(
        ycGeom::Point(1e3:0) ycGeom::Point(list(1e3 + 1e-5 0))
        ycGeom::Point(list(1e3 + 1e-5 1)) ycGeom::Point(1e3:1)
    ))
    b2 = ycGeom::Polygon(list(
        ycGeom::Point(list(1e3 + 1e-5 + 5e-10 0)) ycGeom::Point(1e4:0)
        ycGeom::Point(1e4:1) ycGeom::Point(list(1e3 + 1e-5 + 5e-10 1))
    ))
    r = errset(a2->or(b2) nil)
    _Assert(r && length(car(r)->polygons()) == 1
        "boolean: large cell coordinate one polygon")
    _Assert(r && abs(car(r)->area() - 9000.0) <= 1e-9
        "boolean: large cell coordinate area")
)
let((x bx a2 b2 r)
    x = 1e7 + 10.0
    bx = x + 4e-9
    a2 = ycGeom::Polygon(list(
        ycGeom::Point(1e7:0)
        ycGeom::Point(x:0)
        ycGeom::Point(x:10)
        ycGeom::Point(1e7:10)
    ))
    b2 = ycGeom::Polygon(list(
        ycGeom::Point(list(bx 0))
        ycGeom::Point(1e7 + 20.0:0)
        ycGeom::Point(1e7 + 20.0:10)
        ycGeom::Point(list(bx 10))
    ))
    r = errset(a2->or(b2) nil)
    _Assert(r && length(car(r)->polygons()) == 1
        "boolean: relative canonicalization one polygon")
    _Assert(r && abs(car(r)->area() - 200.0) <= 1e-6
        "boolean: relative canonicalization area")
)
let((outer h1 h2 r p seams)
    outer = ycGeom::Polygon('((0 0) (20 0) (20 10) (0 10)))
    h1 = ycGeom::Polygon('((1 1) (3 1) (3 3) (1 3)))
    h2 = ycGeom::Polygon('((5 1) (7 1) (7 3) (5 3)))
    r = ycGeom::_Boolean(list(outer) list(h1 h2)
        'difference nil 1e-9)
    _Assert(r && abs(car(r)->area() - 192.0) <= 1e-9
        "boolean: multiple holes area")
    p = car(r)
    seams = ycGeom::_SeamKeys(p->points())
    _Assert(!seams[ycGeom::_EdgeKey(
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

let((a2 b2 r poly)
    ; 纯数据入口：单多边形点列（Polygon->toSkill() 形式），运算名在首位
    a2 = '((0.0 0.0) (4.0 0.0) (4.0 4.0) (0.0 4.0))
    b2 = '((2.0 2.0) (6.0 2.0) (6.0 6.0) (2.0 6.0))
    r = ycGeom::Boolean('or a2 b2)
    _Assert(ycGeom::Region(r)->area() == 28.0
        "boolean: native or area")
    _Assert(ycGeom::Region(ycGeom::Boolean('and a2 b2))->area() == 4.0
        "boolean: native and area")
    _Assert(ycGeom::Region(ycGeom::Boolean('not a2 b2))->area() == 12.0
        "boolean: native not area")
    _Assert(ycGeom::Region(ycGeom::Boolean('xor a2 b2))->area() == 24.0
        "boolean: native xor area")
    _Assert(equal(ycGeom::Boolean("or" a2 b2) r)
        "boolean: native accepts string operation")
    _Assert(equal(ycGeom::Boolean("OR" a2 b2) r)
        "boolean: native ignores operation case in strings")
    _Assert(equal(ycGeom::Boolean('OR a2 b2) r)
        "boolean: native ignores operation case in symbols")
    _Assert(equal(ycGeom::Boolean('And a2 b2)
            ycGeom::Boolean('and a2 b2))
        "boolean: native mixes operation case freely")
    _AssertError(lambda(() ycGeom::Boolean("union" a2 b2))
        "boolean: native rejects string union spelling")
    ; 结果形态固定为 Region->toSkill()：点列列表，可直接回构 Polygon
    _Assert(length(r) == 1 && listp(car(r)) && listp(car(car(r)))
        "boolean: native result is polygon list")
    poly = ycGeom::Polygon(car(r))
    _Assert(abs(poly->area() - 28.0) <= 1e-9
        "boolean: native result rebuilds polygon")
)

let((a2 b2 r)
    ; 点列列表（Region 形式）输入：B 把两个分离方块连成一块
    a2 = '(((0.0 0.0) (2.0 0.0) (2.0 2.0) (0.0 2.0))
           ((10.0 0.0) (12.0 0.0) (12.0 2.0) (10.0 2.0)))
    b2 = '((1.0 0.0) (11.0 0.0) (11.0 2.0) (1.0 2.0))
    r = ycGeom::Boolean('or a2 b2)
    _Assert(length(r) == 1
        "boolean: native region input merges to one polygon")
    _Assert(abs(ycGeom::Region(r)->area() - 24.0) <= 1e-9
        "boolean: native region input area")
)

let((a2 b2 r)
    ; Region 成员先按 or 合并：两个重叠方块整体面积 28，不与奇偶规则纠缠
    a2 = '(((0.0 0.0) (4.0 0.0) (4.0 4.0) (0.0 4.0))
           ((2.0 2.0) (6.0 2.0) (6.0 6.0) (2.0 6.0)))
    b2 = '((-1.0 -1.0) (7.0 -1.0) (7.0 7.0) (-1.0 7.0))
    r = ycGeom::Boolean('and a2 b2)
    _Assert(length(r) == 1
        "boolean: native operands are unioned before the op")
    _Assert(abs(ycGeom::Region(r)->area() - 28.0) <= 1e-9
        "boolean: native merged operand area")
)

let((a2 r)
    ; l_b 传 nil 表示空集：or 时结果就是 l_a 自身求并
    a2 = '(((0.0 0.0) (4.0 0.0) (4.0 4.0) (0.0 4.0))
           ((2.0 2.0) (6.0 2.0) (6.0 6.0) (2.0 6.0)))
    r = ycGeom::Boolean('or a2 nil)
    _Assert(length(r) == 1
        "boolean: native or with nil l_b merges overlap")
    _Assert(abs(ycGeom::Region(r)->area() - 28.0) <= 1e-9
        "boolean: native or with nil l_b area")
    _AssertError(lambda(() ycGeom::Boolean('and a2 nil))
        "boolean: native and rejects nil l_b")
    _AssertError(lambda(() ycGeom::Boolean('not a2 nil))
        "boolean: native not rejects nil l_b")
    _AssertErrorMsg(lambda(() ycGeom::Boolean('xor a2 nil))
        "only when the operation is or" "boolean: native reports nil l_b on xor")
)

let((r)
    ; 两点矩形对角（Rect->toSkill() 形式）输入
    r = ycGeom::Boolean('and '((0.0 0.0) (4.0 4.0)) '((2.0 2.0) (6.0 6.0)))
    _Assert(abs(ycGeom::Region(r)->area() - 4.0) <= 1e-9
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

let((a b)
    a = '((0.0 0.0) (4.0 0.0) (4.0 4.0) (0.0 4.0))
    b = '((2.0 2.0) (6.0 2.0) (6.0 6.0) (2.0 6.0))
    ; ?grid / ?eps 非 nil 时必须是正数，由 _Grid/_Eps 统一校验
    _AssertError(lambda(() ycGeom::Boolean('and a b ?grid "0.5"))
        "boolean: native rejects string grid")
    _AssertError(lambda(() ycGeom::Boolean('and a b ?grid 0))
        "boolean: native rejects zero grid")
    _AssertError(lambda(() ycGeom::Boolean('and a b ?eps "1e-6"))
        "boolean: native rejects string eps")
    _AssertErrorMsg(lambda(() ycGeom::Boolean('and a b ?eps -1e-9))
        "must be a positive number" "boolean: native reports negative eps")
    _AssertErrorMsg(lambda(() ycGeom::Boolean('and a b ?eps -1e-9))
        "ycGeom: ?eps" "boolean: native eps error names the namespace")
    _AssertErrorMsg(lambda(() ycGeom::Boolean('and a b ?grid -1))
        "ycGeom: ?grid" "boolean: native grid error names the namespace")
)

let((path r)
    ; 带宽度对象没有点列形式：Path 走 toRegion()->toSkill() 后参与运算
    path = ycGeom::Path('((0.0 0.0) (10.0 0.0)) ?width 2.0)
    r = ycGeom::Boolean('and path->toRegion()->toSkill()
        '((0.0 -1.0) (1.0 -1.0) (1.0 1.0) (0.0 1.0)))
    _Assert(abs(ycGeom::Region(r)->area() - 2.0) <= 1e-9
        "boolean: path region participates")
)

let((a2 b2)
    a2 = '((0.0 0.0) (4.0 0.0) (4.0 4.0) (0.0 4.0))
    b2 = '((2.0 2.0) (6.0 2.0) (6.0 6.0) (2.0 6.0))
    _AssertError(lambda(() ycGeom::Boolean('union a2 b2))
        "boolean: native rejects union spelling")
    _AssertErrorMsg(lambda(() ycGeom::Boolean('union a2 b2))
        "unknown operation" "boolean: native reports unknown operation")
    _AssertError(lambda(() ycGeom::Boolean('or "abc" b2))
        "boolean: native rejects string operand")
    _AssertError(lambda(() ycGeom::Boolean('or a2 42))
        "boolean: native rejects number operand")
    _AssertError(lambda(() ycGeom::Boolean('or
            '((0.0 0.0) (1.0 0.0) ("x" 1.0)) b2))
        "boolean: native rejects malformed point array")
)

let((raw norm hole nat)
    ; Region 成员重叠：两条入口都必须按「成员先并集」参与运算，结果一致
    raw = ycGeom::Region(list(
        ycGeom::Rect(list(0:0 4:4))
        ycGeom::Rect(list(2:2 6:6))) ?normalize nil)
    norm = ycGeom::Region(list(
        ycGeom::Rect(list(0:0 4:4))
        ycGeom::Rect(list(2:2 6:6))))
    hole = ycGeom::Rect(list(3:3 4:4))
    nat = list(
        ycGeom::Rect(list(0:0 4:4))->toSkill()
        ycGeom::Rect(list(2:2 6:6))->toSkill())
    ; ?normalize nil 只保留成员分块，面积仍是各块之和
    _Assert(raw->area() == 32.0
        "boolean: unnormalized region keeps both members")
    _Assert(norm->area() == 28.0
        "boolean: normalized region merges members")
    ; 正确值：并集 28、交集 1、差 27、对称差 27
    _Assert(raw->and(hole)->area() == 1.0
        "boolean: raw region intersection uses the union")
    _Assert(raw->or(hole)->area() == 28.0
        "boolean: raw region union ignores member overlap")
    _Assert(raw->not(hole)->area() == 27.0
        "boolean: raw region difference uses the union")
    _Assert(raw->xor(hole)->area() == 27.0
        "boolean: raw region xor uses the union")
    _Assert(raw->and(hole)->area() == norm->and(hole)->area()
        "boolean: raw and normalized regions agree")
    ; 原生入口对同一操作数给同一结果
    _Assert(ycGeom::Region(ycGeom::Boolean('and nat hole->toSkill())
            ?normalize nil)->area() == 1.0
        "boolean: native and matches the method result")
    _Assert(ycGeom::Region(ycGeom::Boolean('or nat hole->toSkill())
            ?normalize nil)->area() == 28.0
        "boolean: native or matches the method result")
    _Assert(ycGeom::Region(ycGeom::Boolean('not nat hole->toSkill())
            ?normalize nil)->area() == 27.0
        "boolean: native not matches the method result")
    _Assert(ycGeom::Region(ycGeom::Boolean('xor nat hole->toSkill())
            ?normalize nil)->area() == 27.0
        "boolean: native xor matches the method result")
)

let((far)
    ; 互不重叠的成员走包围盒短路：并集保持各块，面积按块相加
    far = ycGeom::Region(list(
        ycGeom::Rect(list(0:0 1:1))
        ycGeom::Rect(list(2:0 3:1))
        ycGeom::Rect(list(4:0 5:1))))
    _Assert(far->area() == 3.0  "boolean: disjoint members keep their union")
    _Assert(length(far->polygons()) == 3  "boolean: disjoint members are not merged")
    _Assert(far->or(ycGeom::Rect(list(0:2 1:3)))->area() == 4.0
        "boolean: disjoint region unions with a new member")
)

_TestChildDone = t

; END
