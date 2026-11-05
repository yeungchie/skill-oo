# 第 5 章 区域布尔流水线

[返回目录](README.md) ｜ [上一章：多边形规范化与 keyhole](04-polygon-normalization.md) ｜ [下一章：面积与质心的稳定计算](06-area-and-centroid.md)

![布尔流水线的六个阶段](img/boolean-pipeline.svg)

## 5.1 问题：集合运算比想象中难

给定两个区域 A、B，求并、交、差、对称差。直觉上「留下想要的边」就够了，实际要处理：

- 边与边相交，交点把边切成多段；
- 两条边共线重叠，既不能算两个交点，也不能丢掉；
- 一个区域可能有多个连通分量和多个洞；
- 端点接触、退化边、近似重合；
- 输出必须是规范化、互不重叠的多边形集合。

## 5.2 表示：区域是多边形的并集

```text
Region = {P1, P2, ...}，语义是 P1 ∪ P2 ∪ ...
```

集合运算的结果也用同样形式返回，并且已经规范化：成员之间互不重叠、每个成员是规范形。洞用第 4 章的 keyhole 表示，所以「一个多边形」仍然是一个环。

## 5.3 流水线

```text
输入环 A、环 B
   │
   ├─ 1. 拆边：求所有交点，按交点把边切成小段
   ├─ 2. 分类：每段边取左右采样点，判断落在结果内还是外
   ├─ 3. 追踪：把保留下来的有向边接成闭环
   ├─ 4. 嵌套：按包含深度区分外环与洞
   ├─ 5. 拼接：洞用切割线并入外环
   └─ 6. 规范化：去重复、去共线、统一方向
```

下面用两个交叠的正方形演示前三个阶段。为了专注于流程，示例做了两个简化：只处理两个环、每个顶点最多一条出边；完整实现还要处理多分量、多出边选择与洞。

## 5.4 拆边

先把环拆成无向边，再对每条边求它与另一环所有边的交点参数。交点参数必须同时落在两条边上（`0 <= t <= 1` 且 `0 <= u <= 1`），否则是延长线相交，不能算。

```lisp
; 可运行
procedure(_RingEdges(l_pts "l")  ; -> list[list[Point]]
    let((res n)
        n = length(l_pts)
        for(i 0 n - 1
            res = tconc(res list(nth(i l_pts)
                nth(if(i == n - 1 0 i + 1) l_pts)))
        )
        car(res)
    )
)

procedure(_SnapPt(g_p n_grid "gn")  ; -> Point
    ycGeom::Point(list(
        round(g_p->x() / n_grid) * n_grid
        round(g_p->y() / n_grid) * n_grid))
)

procedure(_CutEdge(g_a g_b l_other n_grid "ggln")  ; -> list[list[Point]]
    let((rx ry ts res prev)
        rx = g_b->x() - g_a->x()
        ry = g_b->y() - g_a->y()
        ts = list(0.0 1.0)
        foreach(o l_other
            let((sx sy qx qy den tt uu)
                sx = cadr(o)->x() - car(o)->x()
                sy = cadr(o)->y() - car(o)->y()
                qx = car(o)->x() - g_a->x()
                qy = car(o)->y() - g_a->y()
                den = rx * sy - ry * sx
                unless(abs(den) <= 1e-12
                    tt = (qx * sy - qy * sx) / den
                    uu = (qx * ry - qy * rx) / den
                    when(tt > 0.0 && tt < 1.0 && uu >= 0.0 && uu <= 1.0
                        ts = cons(tt ts))
                )
            )
        )
        ts = sort(ts 'lessp)
        prev = car(ts)
        foreach(tt cdr(ts)
            when(tt - prev > 1e-9
                res = tconc(res list(
                    _SnapPt(ycGeom::Point(list(
                        g_a->x() + prev * rx
                        g_a->y() + prev * ry)) n_grid)
                    _SnapPt(ycGeom::Point(list(
                        g_a->x() + tt * rx
                        g_a->y() + tt * ry)) n_grid)))
                prev = tt
            )
        )
        car(res)
    )
)

procedure(_SplitAll(l_ringA l_ringB n_grid "lln")  ; -> list[list[Point]]
    let((res)
        foreach(e _RingEdges(l_ringA)
            foreach(sub _CutEdge(car(e) cadr(e) _RingEdges(l_ringB) n_grid)
                res = tconc(res sub)
            )
        )
        foreach(e _RingEdges(l_ringB)
            foreach(sub _CutEdge(car(e) cadr(e) _RingEdges(l_ringA) n_grid)
                res = tconc(res sub)
            )
        )
        car(res)
    )
)
```

两处细节：

- **交点要吸附到网格。** 同一条交点分别从 A 的边和 B 的边算出，浮点结果可能差最后几位；不吸附，后面按端点配对就会失败。
- **共线重叠的边要特殊处理。** 本节示例没有重叠边；完整实现会把重叠区间也当作切分参数。

## 5.5 分类：看边的两侧

一条边是否属于结果边界，取决于它两侧的点是否属于结果：

1. 取边中点，沿法线向两侧各偏一点，得到 `left`、`right`；
2. 分别判断这两个点是否在 A、B 内；
3. 按运算决定左右是否属于结果；
4. 两侧归属不同，这条边就是结果边界；把「结果内部」放在左侧，决定边的方向。

```lisp
; 可运行
procedure(_ResultMember(s_op g_inA g_inB "sgg")  ; -> t | nil
    case(s_op
        ('or g_inA || g_inB)
        ('and g_inA && g_inB)
        ('not g_inA && !g_inB)
        ('xor (g_inA && !g_inB) || (!g_inA && g_inB))
    )
)

procedure(_Classify(l_edges l_ringA l_ringB s_op n_grid "lllsn")  ; -> list[list[Point]]
    let((res delta)
        delta = n_grid
        foreach(e l_edges
            let((a b dx dy len mx my nx ny left right inL inR)
                a = car(e)
                b = cadr(e)
                dx = b->x() - a->x()
                dy = b->y() - a->y()
                len = sqrt(dx * dx + dy * dy)
                when(len > 0.0
                    mx = (a->x() + b->x()) / 2.0
                    my = (a->y() + b->y()) / 2.0
                    nx = -dy / len
                    ny = dx / len
                    left = ycGeom::Point(list(mx + nx * delta my + ny * delta))
                    right = ycGeom::Point(list(mx - nx * delta my - ny * delta))
                    inL = _ResultMember(s_op
                        _RayInside(l_ringA left) _RayInside(l_ringB left))
                    inR = _ResultMember(s_op
                        _RayInside(l_ringA right) _RayInside(l_ringB right))
                    when(inL != inR
                        res = tconc(res if(inL list(a b) list(b a)))
                    )
                )
            )
        )
        car(res)
    )
)
```

`delta` 是采样偏移，必须**小于最小特征尺寸**：太大，采样点会跨过邻近的边；太小，又会被浮点误差淹没。示例用 `delta = n_grid`，实际实现通常取最短边的一个小比例。

## 5.6 追踪：把有向边接成环

分类后得到一组有向边，每条边都保证「左侧是结果内部」。从一个端点出发，沿着同起点的下一条边继续走，直到回到起点：

```lisp
; 可运行
procedure(_TraceLoops(l_directed n_grid "ln")  ; -> list[list[Point]]
    let((tab order res e start cur next ring key)
        tab = makeTable("tutorialTrace" nil)
        foreach(e l_directed
            key = _PointKey(car(e) n_grid)
            unless(tab[key] order = tconc(order key))
            tab[key] = e
        )
        order = car(order)
        while(order
            start = tab[car(order)]
            ring = tconc(nil car(start))
            cur = cadr(start)
            tab[_PointKey(car(start) n_grid)] = nil
            while(_PointKey(cur n_grid) != _PointKey(car(start) n_grid)
                ring = tconc(ring cur)
                next = tab[_PointKey(cur n_grid)]
                unless(next
                    error("tutorial trace: open chain at %s" _PointKey(cur n_grid))
                )
                tab[_PointKey(cur n_grid)] = nil
                cur = cadr(next)
            )
            res = tconc(res car(ring))
            order = nil
            foreach(k tab when(tab[k] order = tconc(order k)))
            order = car(order)
        )
        car(res)
    )
)
```

一般情况一个顶点可能有多条出边（例如两个洞在同一处接入外环），这时要按转角选「最靠左」的一条，保证环不自交、内部分配一致。示例里每个顶点最多一条出边，所以直接取唯一一条。

## 5.7 跑一遍

```lisp
; 可运行
A = list(ycGeom::Point(0:0) ycGeom::Point(4:0)
    ycGeom::Point(4:4) ycGeom::Point(0:4))
B = list(ycGeom::Point(2:2) ycGeom::Point(6:2)
    ycGeom::Point(6:6) ycGeom::Point(2:6))

edges = _SplitAll(A B 0.25)
length(edges)                                   ; => 12

dirs = _Classify(edges A B 'or 0.25)
length(dirs)                                    ; => 8
unionRings = _TraceLoops(dirs 0.25)
length(unionRings)                              ; => 1
_SignedArea(car(unionRings))                    ; => 28.0
```

结果是 8 个顶点的外轮廓：两个正方形各贡献 3 条外边，两个交点各贡献 1 个拐角。面积 `16 + 16 - 4 = 28`。

交集同样一条流水线，只改分类规则：

```lisp
; 可运行
dirsAnd = _Classify(edges A B 'and 0.25)
andRings = _TraceLoops(dirsAnd 0.25)
length(andRings)                                ; => 1
_SignedArea(car(andRings))                      ; => 4.0
```

`ycGeom` 的对应接口：

```lisp
; 可运行
ra = ycGeom::Region(list(ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))))
rb = ycGeom::Region(list(ycGeom::Polygon('((2 2) (6 2) (6 6) (2 6)))))

ra->or(rb)->area()    ; => 28.0
ra->and(rb)->area()   ; => 4.0
ra->not(rb)->area()   ; => 12.0
ra->xor(rb)->area()   ; => 24.0
```

## 5.8 洞与嵌套

多个环追出来后，要判断谁包含谁：

- 用一条射线穿过所有环，按交点个数得到深度；
- 深度为偶数的环是实心区外环，深度为奇数的环是洞；
- 把每个洞挂到包含它的最近外环上，用切割线拼接（第 4 章）。

这一步决定了「一个顶点多条出边」时必须选最左转：只有保持内部分配一致，追踪出的环才能正确嵌套。

## 5.9 边界与常见误解

- **结果一定被规范化。** 输入的多个多边形可能重叠，输出的成员互不重叠。
- **近重合的边必须给网格。** 拆边、配对、追踪都依赖精确端点，容差判断救不了。
- **采样偏移有上限。** 布尔实现里，边两侧的采样距离通常有上限；特征尺寸小于该上限时分类可能出错。网格能消除这类问题，这也是 `?grid` 存在的原因。
- **教学实现不是通用实现。** 本节代码省略了多分量、多出边、重叠边与洞；库里的实现把这些都做了。

## 小结

- 布尔运算 = 拆边 + 分类 + 追踪 + 嵌套 + 规范化。
- 拆边靠交点参数，分类靠边两侧采样，追踪靠有向边首尾相接。
- 精确键与网格是流水线能跑稳的前提。
- 洞在最后一步用 keyhole 拼进外环。

下一章回到数值：面积和质心怎么算才不会被大坐标毁掉。

[返回目录](README.md) ｜ [下一章](06-area-and-centroid.md)
