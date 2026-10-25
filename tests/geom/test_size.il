_TestSizeDone = nil

procedure(_SizeBoxNear(l_a l_b "ll")  ; -> t | nil
    ; 判断两个 bbox 是否在容差内相等（测试辅助）。
    ;
    ; **参数**
    ;   l_a  (list[float]) - bbox 一
    ;   l_b  (list[float]) - bbox 二
    ;
    ; **返回**
    ;   (t|nil) - 四项都在 1e-9 内相等为 t
    let((g_ok)
        g_ok = t
        for(n_i 1 4
            when(abs(ycGeom::_Nth1(n_i l_a) - ycGeom::_Nth1(n_i l_b)) > 1e-9
                g_ok = nil
            )
        )
        g_ok
    )
)


let((g_sq)
    g_sq = ycGeom::Polygon('((0 0) (10 0) (10 10) (0 10)))
    _Assert(g_sq->size(1)->area() > 100.0  "size: numeric grow")
    _Assert(g_sq->size(-1)->area() < 100.0  "size: numeric shrink")
    _Assert(g_sq->size(0)->area() == 100.0  "size: zero no-op")
)

_AssertError(lambda(() ycGeom::Polygon('((0 0) (4 0) (0 4)))->size(1 ?dir 'bad) t)  "size: bad direction")
_AssertError(lambda(() ycGeom::Polygon('((0 0) (4 0) (0 4)))->size(1 ?dir '(all right)) t)  "size: all mixed")
_AssertError(lambda(() ycGeom::Polygon('((0 0) (4 0) (0 4)))->size(1 ?ratio -1) t)  "size: negative ratio")
_AssertError(lambda(() ycGeom::Polygon('((0 0) (4 0) (0 4)))->size(1 ?corner 'bad) t)  "size: bad corner")
_AssertError(lambda(() ycGeom::Polygon('((0 0) (4 0) (0 4)))->size(1 ?miterLimit 0) t)  "size: bad miter limit")
_AssertError(lambda(() ycGeom::Polygon('((0 0) (4 0) (0 4)))->size(1 ?roundSegments 0) t)  "size: bad round segments")

let((g_sq)
    g_sq = ycGeom::Polygon('((0 0) (10 0) (10 10) (0 10)))
    _Assert(g_sq->size(1 ?corner 'miter)->bbox() == list(-1.0 -1.0 11.0 11.0)  "size: miter bbox")
    _Assert(g_sq->size(1 ?corner 'miter)->area() == 144.0  "size: miter area")
    _Assert(g_sq->size(1 ?dir 'right ?corner 'miter)->bbox() == list(0.0 0.0 11.0 10.0)  "size: right bbox")
    _Assert(g_sq->size(1 ?dir '(up down) ?corner 'miter)->bbox() == list(0.0 -1.0 10.0 11.0)  "size: vertical bbox")
    _Assert(g_sq->size(1 ?dir '(left up) ?corner 'miter)->bbox() == list(-1.0 0.0 10.0 11.0)  "size: corner directions bbox")
    _Assert(g_sq->size(1 ?corner 'bevel)->area() == 142.0  "size: bevel area")
    _Assert(g_sq->size(1 ?corner 'none)->area() == 140.0  "size: none area")
    _Assert(g_sq->size(1 ?corner 'miter ?miterLimit 1)->area() < 144.0  "size: miter limit")
    _Assert(g_sq->size(1 ?corner 'round)->area() < 144.0  "size: round area")
    _Assert(g_sq->size(1 ?corner 'round)->area() > 100.0  "size: round grows")
    _Assert(_SizeBoxNear(g_sq->size(1.2 ?ratio t)->bbox() list(-1.0 -1.0 11.0 11.0))  "size: ratio all bbox")
    _Assert(_SizeBoxNear(g_sq->size(0.8 ?ratio t)->bbox() list(1.0 1.0 9.0 9.0))  "size: ratio shrink bbox")
    _Assert(g_sq->size(1.2 ?ratio t ?dir 'right)->bbox() == list(0.0 0.0 12.0 10.0)  "size: ratio right bbox")
    _Assert(_SizeBoxNear(g_sq->size(1.2 ?ratio t ?dir '(left right))->bbox() list(-1.0 0.0 11.0 10.0))  "size: ratio both x bbox")
)

let((g_hole g_r g_multi)
    g_hole = ycGeom::Polygon('((0 0) (10 0) (3 3) (3 7) (7 7) (7 3)
                              (3 3) (10 0) (10 10) (0 10)))
    _Assert(g_hole->size(1)->area() > 84.0  "size: hole grows")
    _Assert(g_hole->size(-1)->area() < 84.0  "size: hole shrinks")
    g_r = ycGeom::Region(list(g_hole))
    _Assert(g_r->size(1)->area() > g_r->area()  "size: region hole")
    g_multi = ycGeom::Region(list(
        ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))
        ycGeom::Polygon('((10 0) (14 0) (14 4) (10 4)))
    ))
    _Assert(g_multi->size(1)->area() > g_multi->area()  "size: region independent")
)
_Assert(ycGeom::Region(nil)->size(1)->isEmpty()  "size: empty region")

let((g_tri g_l)
    g_tri = ycGeom::Polygon('((0 0) (10 0) (0 10)))
    _Assert(g_tri->size(1)->area() > 50.0  "size: triangle grow")
    _Assert(g_tri->size(1 ?dir 'right)->area() > 50.0  "size: triangle right")
    _Assert(g_tri->size(1 ?corner 'none)->area() > 50.0  "size: triangle none")
    g_l = ycGeom::Polygon('((0 0) (10 0) (10 4) (4 4) (4 10) (0 10)))
    _Assert(g_l->size(1)->area() > 64.0  "size: concave grow")
    _Assert(g_l->size(-1)->area() < 64.0  "size: concave shrink")
)

_TestSizeDone = t

; END
