useNamespace("ycGeom")

procedure(_SnapRing(l_pts g_grid n_eps "lgn")  ; -> list[Point]
    ; 吸附、合并并清理一个环。
    ;
    ; **参数**
    ;   l_pts   (list[Point]) - 源点列
    ;   g_grid  (float|nil)   - 网格
    ;   n_eps   (float)       - 容差
    ;
    ; **返回**
    ;   (list[Point]) - 清理后的点列
    let((res prev snap clean)
        foreach(p l_pts
            snap = Point(list(_Snap(p->x() g_grid) _Snap(p->y() g_grid)))
            unless(prev && _Near(prev->x() snap->x() n_eps)
                && _Near(prev->y() snap->y() n_eps)
                res = tconc(res snap)
            )
            prev = snap
        )
        clean = _RingPointsClean(car(res) n_eps)
        unless(length(clean) >= 3
                && abs(_SignedArea(clean)) > _AreaTol(clean n_eps)
            error("ycGeom: grid snapping collapsed polygon topology")
        )
        clean
    )
)

procedure(_CollectRings(l_polys g_grid n_eps g_reg "lgng")  ; -> list[list[Point]]
    ; 收集多个多边形的所有环。
    ;
    ; **参数**
    ;   l_polys  (list[Polygon]) - 多边形列表
    ;   g_grid   (float|nil)     - 网格
    ;   n_eps    (float)         - 容差
    ;   g_reg    (table)         - 点规范登记表
    ;
    ; **返回**
    ;   (list[list[Point]]) - 环列表
    let((res mag pt)
        unless(g_reg["_canonScale"]
            mag = 0.0
            foreach(p l_polys
                _AsPolygon(p "ycGeom::Boolean")
                foreach(pt2 p->points()
                    mag = max(mag max(abs(pt2->x()) abs(pt2->y())))
                )
            )
            g_reg["_canonScale"] = max(n_eps 1e-15 * mag)
        )
        foreach(p l_polys
            _AsPolygon(p "ycGeom::Boolean")
            foreach(r _Rings(_CanonRing(
                    _SnapRing(p->points() g_grid n_eps) n_eps g_reg))
                res = tconc(res r)
            )
        )
        car(res)
    )
)

procedure(_RingEdgeList(l_rings "l")  ; -> list[list[Point]]
    ; 把环列表展开为无向边列表。
    ;
    ; **参数**
    ;   l_rings  (list[list[Point]]) - 环列表
    ;
    ; **返回**
    ;   (list[list[Point]]) - 边列表，每项为 (a b)
    let((res len i)
        foreach(r l_rings
            len = length(r)
            for(i2 1 len
                res = tconc(res list(
                    _Nth1(i2 r)
                    _Nth1(if(i2 == len 1 (i2 + 1)) r)
                ))
            )
        )
        car(res)
    )
)

procedure(_EdgeT(g_a g_b g_p n_eps "gggn")  ; -> float
    ; 返回点在线段上的参数 t，并夹到 0..1。
    ;
    ; **参数**
    ;   g_a    (Point) - 起点
    ;   g_b    (Point) - 终点
    ;   g_p    (Point) - 点
    ;   n_eps  (float) - 容差
    ;
    ; **返回**
    ;   (float) - 0..1 的参数
    let((dx dy den value)
        dx = g_b->x() - g_a->x()
        dy = g_b->y() - g_a->y()
        den = dx * dx + dy * dy
        if(den <= n_eps * n_eps
        then
            0.0
        else
            value = ((g_p->x() - g_a->x()) * dx
                + (g_p->y() - g_a->y()) * dy) / den
            max(0.0 min(1.0 value))
        )
    )
)

procedure(_AddCut(g_a g_b g_c g_d n_eps l_t "ggggnl")  ; -> list[float]
    ; 把两条边的交点参数追加到 t 列表。
    ;
    ; **参数**
    ;   g_a    (Point) - 边一始点
    ;   g_b    (Point) - 边一终点
    ;   g_c    (Point) - 边二始点
    ;   g_d    (Point) - 边二终点
    ;   n_eps  (float) - 容差
    ;   l_t    (list[float]) - 已有参数
    ;
    ; **返回**
    ;   (list[float]) - 追加后的参数列表
    let((x2)
        x2 = _SegSegIntersection(g_a g_b g_c g_d n_eps)
        cond(
            (x2 == nil l_t)
            (_PointP(x2) cons(_EdgeT(g_a g_b x2 n_eps) l_t))
            (_SegmentP(x2)
                cons(_EdgeT(g_a g_b x2->start() n_eps)
                    cons(_EdgeT(g_a g_b x2->end() n_eps) l_t)))
            (t l_t)
        )
    )
)

procedure(_InsertNum(l_vals n_v "ln")  ; -> list[float]
    ; 把数值插入升序列表。
    ;
    ; **参数**
    ;   l_vals  (list[float]) - 已排序列表
    ;   n_v     (float)       - 新值
    ;
    ; **返回**
    ;   (list[float]) - 插入后的列表
    cond(
        (l_vals == nil list(n_v))
        (n_v < car(l_vals) cons(n_v l_vals))
        (t cons(car(l_vals) _InsertNum(cdr(l_vals) n_v)))
    )
)

procedure(_SortUniqueNums(l_vals n_eps "ln")  ; -> list[float]
    ; 升序排序并删除容差内重复值。
    ;
    ; **参数**
    ;   l_vals  (list[float]) - 参数值
    ;   n_eps   (float)       - 容差
    ;
    ; **返回**
    ;   (list[float]) - 排序去重后的参数
    let((sorted res prev)
        foreach(v l_vals
            sorted = _InsertNum(sorted v)
        )
        foreach(v sorted
            unless(prev && _Near(v prev n_eps)
                res = tconc(res v)
            )
            prev = v
        )
        car(res)
    )
)

procedure(_Lerp(g_a g_b n_t "ggn")  ; -> Point
    ; 在两点间线性插值。
    ;
    ; **参数**
    ;   g_a  (Point) - 起点
    ;   g_b  (Point) - 终点
    ;   n_t  (float) - 参数
    ;
    ; **返回**
    ;   (Point) - 插值点
    Point(list(g_a->x() + (g_b->x() - g_a->x()) * n_t
        g_a->y() + (g_b->y() - g_a->y()) * n_t))
)

procedure(_SplitEdges(l_edges n_eps g_reg "lng")  ; -> list[list[Point]]
    ; 在所有交点处拆分边并去重。
    ;
    ; **参数**
    ;   l_edges  (list[list[Point]]) - 无向边
    ;   n_eps    (float)             - 容差
    ;   g_reg    (table)         - 点规范登记表
    ;
    ; **返回**
    ;   (list[list[Point]]) - 拆分后的无向边
    let((seen res i len value a b prev cur key edge_len tol)
        seen = makeTable("geomSplit" nil)
        foreach(e l_edges
            a = car(e)
            b = cadr(e)
            edge_len = sqrt((b->x() - a->x()) * (b->x() - a->x())
                + (b->y() - a->y()) * (b->y() - a->y()))
            tol = if(edge_len > n_eps n_eps / edge_len 0.0)
            value = list(0.0 1.0)
            foreach(o l_edges
                unless(e == o
                    value = _AddCut(a b car(o) cadr(o) n_eps value)
                )
            )
            value = _SortUniqueNums(value tol)
            len = length(value)
            for(i2 1 len - 1
                prev = _CanonPoint(
                    _Lerp(a b _Nth1(i2 value)) n_eps g_reg)
                cur = _CanonPoint(
                    _Lerp(a b _Nth1(i2 + 1 value)) n_eps g_reg)
                key = _EdgeKey(prev cur)
                unless(seen[key]
                    seen[key] = t
                    res = tconc(res list(prev cur))
                )
            )
        )
        car(res)
    )
)

procedure(_InsideRings(l_rings g_p n_eps "lgn")  ; -> t | nil
    ; 奇偶判断点是否在环集合内部。
    ;
    ; **参数**
    ;   l_rings  (list[list[Point]]) - 环列表
    ;   g_p      (Point)             - 待判断点
    ;   n_eps    (float)             - 容差
    ;
    ; **返回**
    ;   (t|nil) - 奇偶结果为真
    let((in)
        foreach(r l_rings
            when(_PointInRing(r g_p n_eps)
                in = !in
            )
        )
        in
    )
)

procedure(_EdgeClearance(l_edges g_edge "lg")  ; -> float | nil
    ; 计算边中点到其余边的最短距离。
    ;
    ; **参数**
    ;   l_edges  (list[list[Point]]) - 全部拆分边
    ;   g_edge   (list[Point])       - 当前边
    ;
    ; **返回**
    ;   (float|nil) - 最短距离；没有其他边时为 nil
    let((mx my res dx dy len2 u qx qy d)
        mx = (car(g_edge)->x() + cadr(g_edge)->x()) / 2.0
        my = (car(g_edge)->y() + cadr(g_edge)->y()) / 2.0
        foreach(o l_edges
            unless(o == g_edge
                dx = cadr(o)->x() - car(o)->x()
                dy = cadr(o)->y() - car(o)->y()
                len2 = dx * dx + dy * dy
                if(len2 <= 0.0
                then
                    qx = car(o)->x()
                    qy = car(o)->y()
                else
                    u = ((mx - car(o)->x()) * dx
                        + (my - car(o)->y()) * dy) / len2
                    u = max(0.0 min(1.0 u))
                    qx = car(o)->x() + dx * u
                    qy = car(o)->y() + dy * u
                )
                d = sqrt((mx - qx) * (mx - qx) + (my - qy) * (my - qy))
                res = if(res == nil d min(res d))
            )
        )
        res
    )
)

procedure(_ClassifyEdges(l_edges l_ra l_rb s_op n_eps "lllsn")  ; -> list[list[Point]]
    ; 按两侧采样结果保留结果边界的有向边。
    ;
    ; **参数**
    ;   l_edges  (list[list[Point]]) - 拆分后的无向边
    ;   l_ra     (list[list[Point]]) - A 环
    ;   l_rb     (list[list[Point]]) - B 环
    ;   s_op     (sym)               - union/intersection/difference/xor
    ;   n_eps    (float)             - 容差
    ;
    ; **返回**
    ;   (list[list[Point]]) - 结果内部在左侧的有向边
    let((res a b dx dy len scale mx my nx ny delta clear left right la lb ra rb lkeep rkeep)
        scale = 0.0
        foreach(e l_edges
            dx = cadr(e)->x() - car(e)->x()
            dy = cadr(e)->y() - car(e)->y()
            len = sqrt(dx * dx + dy * dy)
            scale = if(scale == 0.0 len min(scale len))
        )
        foreach(e l_edges
            a = car(e)
            b = cadr(e)
            dx = b->x() - a->x()
            dy = b->y() - a->y()
            len = sqrt(dx * dx + dy * dy)
            unless(len <= n_eps
                ; 采样偏移：至多最短边的千分之一，且不超过最近邻边距离的一半；
                ; 后者防止采样点跨过窄缝落到另一侧边界上。下限 100 eps 抗浮点噪声。
                clear = _EdgeClearance(l_edges e)
                delta = max(n_eps * 100.0
                    if(clear min(scale * 1e-3 clear * 0.5) scale * 1e-3))
                mx = (a->x() + b->x()) / 2.0
                my = (a->y() + b->y()) / 2.0
                nx = -dy / len
                ny = dx / len
                left = Point(list(mx + nx * delta my + ny * delta))
                right = Point(list(mx - nx * delta my - ny * delta))
                la = _InsideRings(l_ra left n_eps)
                lb = _InsideRings(l_rb left n_eps)
                ra = _InsideRings(l_ra right n_eps)
                rb = _InsideRings(l_rb right n_eps)
                lkeep = _InResult(s_op la lb)
                rkeep = _InResult(s_op ra rb)
                when(lkeep != rkeep
                    res = tconc(res
                        if(lkeep list(a b) list(b a)))
                )
            )
        )
        car(res)
    )
)

procedure(_FirstTraceEdge(g_adj l_order "gl")  ; -> list[Point] | nil
    ; 返回第一条未使用的有向边。
    ;
    ; **参数**
    ;   g_adj   (table) - 起点键 → 有向边列表
    ;   l_order (list)  - 起点键顺序
    ;
    ; **返回**
    ;   (list[Point]|nil) - 有向边；用完为 nil
    let((found)
        foreach(key l_order
            when(g_adj[key] && !found
                found = car(g_adj[key])
            )
        )
        found
    )
)

procedure(_RemoveEdge(l_edges g_from g_to "lgg")  ; -> list[list[Point]]
    ; 删除一条指定起终点的有向边。
    ;
    ; **参数**
    ;   l_edges  (list[list[Point]]) - 候选边
    ;   g_from   (Point)             - 起点
    ;   g_to     (Point)             - 终点
    ;
    ; **返回**
    ;   (list[list[Point]]) - 删除后的列表
    let((res to)
        to = _PtKey(g_to)
        foreach(e l_edges
            unless(_PtKey(cadr(e)) == to
                res = tconc(res e)
            )
        )
        car(res)
    )
)

procedure(_ChooseNext(g_prev g_cur l_cands n_eps "ggln")  ; -> Point
    ; 从多条出边中选择最顺时针的一条。
    ;
    ; **参数**
    ;   g_prev   (Point)             - 上一顶点
    ;   g_cur    (Point)             - 当前顶点
    ;   l_cands  (list[list[Point]]) - 候选有向边
    ;   n_eps    (float)             - 容差
    ;
    ; **返回**
    ;   (Point) - 下一条边的终点
    let((refx refy best best2 dx dy cross dot ang cw)
        refx = g_prev->x() - g_cur->x()
        refy = g_prev->y() - g_cur->y()
        foreach(e l_cands
            dx = cadr(e)->x() - g_cur->x()
            dy = cadr(e)->y() - g_cur->y()
            cross = refx * dy - refy * dx
            dot = refx * dx + refy * dy
            ang = atan2(cross dot)
            cw = if(ang <= 0.0 -ang (2.0 * 3.141592653589793 - ang))
            when(best == nil || cw < best2
                best = cadr(e)
                best2 = cw
            )
        )
        best
    )
)

procedure(_TraceLoops(l_edges n_eps "ln")  ; -> list[list[Point]]
    ; 追踪结果边界闭环。
    ;
    ; **参数**
    ;   l_edges  (list[list[Point]]) - 结果内部在左侧的有向边
    ;   n_eps    (float)             - 容差
    ;
    ; **返回**
    ;   (list[list[Point]]) - 闭环点列
    let((adj order res e start cur prev next ring cands key)
        adj = makeTable("geomTrace" nil)
        foreach(e2 l_edges
            key = _PtKey(car(e2))
            unless(adj[key]
                order = tconc(order key)
            )
            adj[key] = cons(e2 adj[key])
        )
        order = car(order)
        while(_FirstTraceEdge(adj order)
            e = _FirstTraceEdge(adj order)
            start = car(e)
            cur = cadr(e)
            prev = start
            ring = tconc(nil start)
            adj[_PtKey(start)] = _RemoveEdge(
                adj[_PtKey(start)] start cur)
            while(_PtKey(cur) != _PtKey(start)
                ring = tconc(ring cur)
                cands = adj[_PtKey(cur)]
                unless(cands
                    error("ycGeom: boolean trace lost its boundary")
                )
                next = _ChooseNext(prev cur cands n_eps)
                adj[_PtKey(cur)] = _RemoveEdge(cands cur next)
                prev = cur
                cur = next
            )
            res = tconc(res car(ring))
        )
        car(res)
    )
)

procedure(_InResult(s_op g_inA g_inB "sgg")  ; -> t | nil
    ; 判断采样点是否属于布尔结果。
    ;
    ; **参数**
    ;   s_op   (sym)   - union/intersection/difference/xor
    ;   g_inA  (t|nil) - 点在 A 内
    ;   g_inB  (t|nil) - 点在 B 内
    ;
    ; **返回**
    ;   (t|nil) - 属于结果为 t
    cond(
        (s_op == 'union g_inA || g_inB)
        (s_op == 'intersection g_inA && g_inB)
        (s_op == 'difference g_inA && !g_inB)
        (s_op == 'xor g_inA != g_inB)
    )
)

procedure(_CleanPolygons(l_polys n_eps "ln")  ; -> list[Polygon]
    ; 去除结果多边形的共线点（内部实现）。
    ;
    ; **参数**
    ;   l_polys  (list[Polygon]) - 多边形列表
    ;   n_eps    (float)         - 容差
    ;
    ; **返回**
    ;   (list[Polygon]) - 清理后的列表；空结果 nil
    let((res)
        foreach(p l_polys
            res = tconc(res p->removeCollinear(?eps n_eps))
        )
        car(res)
    )
)

procedure(_Boolean(l_a l_b s_op g_grid n_eps "llsgn")  ; -> list[Polygon]
    ; 计算两个多边形集合的布尔结果。
    ;
    ; **参数**
    ;   l_a     (list[Polygon]) - A
    ;   l_b     (list[Polygon]) - B
    ;   s_op    (sym)           - union/intersection/difference/xor
    ;   g_grid  (float|nil)     - 网格
    ;   n_eps   (float)         - 容差
    ;
    ; **返回**
    ;   (list[Polygon]) - 结果多边形；空结果 nil
    let((gridv epsv ra rb edges kept loops res reg)
        unless(s_op == 'union || s_op == 'intersection || s_op == 'difference || s_op == 'xor
            error("ycGeom: unknown operation %A" s_op)
        )
        foreach(p l_a
            _AsPolygon(p "ycGeom::Boolean")
        )
        foreach(p l_b
            _AsPolygon(p "ycGeom::Boolean")
        )
        gridv = _Grid(g_grid)
        epsv = _Eps(n_eps)
        cond(
            (l_a == nil && l_b == nil res = nil)
            (l_a == nil && (s_op == 'union || s_op == 'xor) res = l_b)
            (l_a == nil res = nil)
            (l_b == nil && s_op == 'union res = l_a)
            (l_b == nil && (s_op == 'difference || s_op == 'xor)
                res = l_a)
            (l_b == nil res = nil)
            (t
                reg = makeTable("geomCanon" nil)
                ra = _CollectRings(l_a gridv epsv reg)
                rb = _CollectRings(l_b gridv epsv reg)
                edges = _SplitEdges(
                    append(_RingEdgeList(ra) _RingEdgeList(rb))
                    epsv reg)
                kept = _ClassifyEdges(edges ra rb s_op epsv)
                loops = _TraceLoops(kept epsv)
                when(loops
                    res = _BuildPolygons(
                        _NestLoops(loops epsv) gridv epsv)
                )
            )
        )
        res
    )
)


procedure(_EvenDepth(n_depth "x")  ; -> t | nil
    ; 判断嵌套深度是否为偶数。
    ;
    ; **参数**
    ;   n_depth  (int) - 嵌套深度
    ;
    ; **返回**
    ;   (t|nil) - 偶数为 t
    int(n_depth / 2) * 2 == n_depth
)

procedure(_LoopDepth(l_loops n_idx n_eps "lnn")  ; -> int
    ; 计算环被多少个更大的环包含。
    ;
    ; **参数**
    ;   l_loops  (list[list[Point]]) - 环列表
    ;   n_idx    (int)               - 当前环 1-based 下标
    ;   n_eps    (float)             - 容差
    ;
    ; **返回**
    ;   (int) - 包含计数
    let((depth area_i tol_i p j area_j tol_j)
        depth = 0
        area_i = abs(_SignedArea(_Nth1(n_idx l_loops)))
        tol_i = _AreaTol(_Nth1(n_idx l_loops) n_eps)
        p = car(_Nth1(n_idx l_loops))
        for(j2 1 length(l_loops)
            unless(j2 == n_idx
                area_j = abs(_SignedArea(_Nth1(j2 l_loops)))
                tol_j = _AreaTol(_Nth1(j2 l_loops) n_eps)
                when(area_j > area_i + max(tol_i tol_j)
                    && _PointInRing(_Nth1(j2 l_loops) p n_eps)
                    depth++
                )
            )
        )
        depth
    )
)

procedure(_NestLoops(l_loops n_eps "ln")  ; -> list
    ; 按包含关系区分外环和洞环，并归组。
    ;
    ; **参数**
    ;   l_loops  (list[list[Point]]) - 闭环列表
    ;   n_eps    (float)             - 容差
    ;
    ; **返回**
    ;   (list) - 每组 (外环 洞环列表)
    let((infos groups i loop area depth info hole owner best k g new)
        for(i2 1 length(l_loops)
            loop = _Nth1(i2 l_loops)
            area = abs(_SignedArea(loop))
            depth = _LoopDepth(l_loops i2 n_eps)
            when((_EvenDepth(depth) && _SignedArea(loop) < 0.0)
                || (!_EvenDepth(depth) && _SignedArea(loop) > 0.0)
                loop = reverse(loop)
            )
            infos = tconc(infos list(loop area depth))
        )
        infos = car(infos)
        foreach(info2 infos
            when(_EvenDepth(caddr(info2))
                groups = tconc(groups list(car(info2) nil cadr(info2)))
            )
        )
        groups = car(groups)
        foreach(info2 infos
            unless(_EvenDepth(caddr(info2))
                hole = car(info2)
                owner = nil
                best = nil
                for(k2 1 length(groups)
                    g = _Nth1(k2 groups)
                    when(_PointInRing(car(g) car(hole) n_eps)
                        when(owner == nil || caddr(g) < best
                            owner = k2
                            best = caddr(g)
                        )
                    )
                )
                unless(owner
                    error("ycGeom: hole has no containing outer loop")
                )
                new = nil
                for(k2 1 length(groups)
                    g = _Nth1(k2 groups)
                    new = tconc(new
                        if(k2 == owner
                            list(car(g) cons(hole cadr(g)) caddr(g))
                            g
                        )
                    )
                )
                groups = car(new)
            )
        )
        new = nil
        foreach(g2 groups
            new = tconc(new list(car(g2) cadr(g2)))
        )
        car(new)
    )
)

procedure(_RightmostIndex(l_ring n_eps "ln")  ; -> int
    ; 返回点列最右点的 1-based 下标。
    ;
    ; **参数**
    ;   l_ring  (list[Point]) - 点列
    ;   n_eps   (float)       - 容差
    ;
    ; **返回**
    ;   (int) - 最右点下标；x 在容差内时取 y 更大者
    let((best bx by i p)
        best = 1
        bx = _Nth1(1 l_ring)->x()
        by = _Nth1(1 l_ring)->y()
        for(i2 2 length(l_ring)
            p = _Nth1(i2 l_ring)
            when(p->x() > bx + n_eps
                || (abs(p->x() - bx) <= n_eps
                    && p->y() > by + n_eps)
                best = i2
                bx = p->x()
                by = p->y()
            )
        )
        best
    )
)

procedure(_Rotate(l_ring n_start "lx")  ; -> list[Point]
    ; 把点列旋转到指定起点。
    ;
    ; **参数**
    ;   l_ring   (list[Point]) - 点列
    ;   n_start  (int)         - 新起点 1-based
    ;
    ; **返回**
    ;   (list[Point]) - 旋转后的点列
    let((res len i idx)
        len = length(l_ring)
        for(i2 1 len
            idx = n_start + i2 - 1
            when(idx > len
                idx = idx - len
            )
            res = tconc(res _Nth1(idx l_ring))
        )
        car(res)
    )
)

procedure(_AxisHit(l_outer g_h n_eps g_blocked "lgng")  ; -> list | nil
    ; 从洞右点向右投射水平线，找最近的实际边界交点。
    ;
    ; **参数**
    ;   l_outer   (list[Point]) - 当前 keyhole 点列
    ;   g_h       (Point)       - 洞的最右点
    ;   n_eps     (float)       - 容差
    ;   g_blocked (table)       - 已拼接洞的顶点表，这些边不参与桥接
    ;
    ; **返回**
    ;   (list(num int)|nil) - 交点 x 与所在边下标；无交点为 nil
    let((seams len i a b x2 bestX bestI ay by)
        seams = _SeamKeys(l_outer)
        len = length(l_outer)
        for(i2 1 len
            a = _Nth1(i2 l_outer)
            b = _Nth1(if(i2 == len 1 (i2 + 1)) l_outer)
            unless(seams[_EdgeKey(a b)] == 2
                    || (g_blocked[_PtKey(a)] || g_blocked[_PtKey(b)])
                ay = a->y()
                by = b->y()
                cond(
                    (_Near(ay g_h->y() n_eps)
                        && _Near(by g_h->y() n_eps)
                        x2 = min(a->x() b->x())
                        when(x2 > g_h->x() + n_eps
                            when(bestX == nil || x2 < bestX
                                bestX = x2
                                bestI = i2
                            )
                        )
                    )
                    (((ay < g_h->y() - n_eps
                            && by > g_h->y() + n_eps)
                        || (ay > g_h->y() + n_eps
                            && by < g_h->y() - n_eps))
                        x2 = a->x()
                            + (g_h->y() - ay) * (b->x() - a->x())
                            / (by - ay)
                        when(x2 > g_h->x() + n_eps
                            when(bestX == nil || x2 < bestX
                                bestX = x2
                                bestI = i2
                            )
                        )
                    )
                    (_Near(ay g_h->y() n_eps)
                        x2 = a->x()
                        when(x2 > g_h->x() + n_eps
                            when(bestX == nil || x2 < bestX
                                bestX = x2
                                bestI = i2
                            )
                        )
                    )
                    (_Near(by g_h->y() n_eps)
                        x2 = b->x()
                        when(x2 > g_h->x() + n_eps
                            when(bestX == nil || x2 < bestX
                                bestX = x2
                                bestI = i2
                            )
                        )
                    )
                )
            )
        )
        when(bestX list(bestX bestI))
    )
)

procedure(_SpliceHole(l_outer l_hole n_eps g_blocked "llng")  ; -> list[Point]
    ; 把洞环用水平切割线接回当前 keyhole 点列。
    ;
    ; **参数**
    ;   l_outer   (list[Point]) - 外环或已拼接的 keyhole 点列
    ;   l_hole    (list[Point]) - 洞环
    ;   n_eps     (float)       - 容差
    ;   g_blocked (table)       - 已拼接洞的顶点表，这些边不参与桥接
    ;
    ; **返回**
    ;   (list[Point]) - 新增水平切割线的 keyhole 点列
    let((hi h h2 hit x2 ei len i a b o oi new prefix suffix)
        hi = _RightmostIndex(l_hole n_eps)
        h = _Rotate(l_hole hi)
        h2 = car(h)
        hit = _AxisHit(l_outer h2 n_eps g_blocked)
        unless(hit
            error("ycGeom: no axis-aligned bridge for hole")
        )
        x2 = car(hit)
        ei = cadr(hit)
        a = _Nth1(ei l_outer)
        b = _Nth1(if(ei == length(l_outer) 1 (ei + 1)) l_outer)
        o = Point(list(x2 h2->y()))
        cond(
            (_SamePoint(o a n_eps)
                oi = ei
            )
            (_SamePoint(o b n_eps)
                oi = if(ei == length(l_outer) 1 (ei + 1))
            )
            (t
                new = nil
                len = length(l_outer)
                for(i2 1 len
                    new = tconc(new _Nth1(i2 l_outer))
                    when(i2 == ei
                        new = tconc(new o)
                    )
                )
                l_outer = car(new)
                oi = ei + 1
            )
        )
        o = _Nth1(oi l_outer)
        for(i2 1 oi
            prefix = tconc(prefix _Nth1(i2 l_outer))
        )
        for(i2 oi + 1 length(l_outer)
            suffix = tconc(suffix _Nth1(i2 l_outer))
        )
        append(car(prefix)
            cons(h2
                append(cdr(h)
                    cons(h2
                        cons(o car(suffix))))))
    )
)

procedure(_BuildPolygons(l_groups g_grid n_eps "lgn")  ; -> list[Polygon]
    ; 把分组环转换为 keyhole Polygon。
    ;
    ; **参数**
    ;   l_groups  (list)       - 每组 (外环 洞环列表)
    ;   g_grid    (float|nil)  - 网格
    ;   n_eps     (float)      - 容差
    ;
    ; **返回**
    ;   (list[Polygon]) - 结果多边形
    let((res outer holes blocked)
        foreach(g l_groups
            outer = car(g)
            holes = cadr(g)
            blocked = makeTable("geomHolePoints" nil)
            foreach(h holes
                outer = _SpliceHole(outer h n_eps blocked)
                foreach(p h
                    blocked[_PtKey(p)] = t
                )
            )
            outer = _SnapRing(outer g_grid n_eps)
            res = tconc(res Polygon(outer))
        )
        car(res)
    )
)

procedure(Boolean(S_op l_a l_b \@key (grid nil) (eps nil) "Sllgg")  ; -> list | nil
    ; 纯数据布尔运算：两侧输入与结果都是 toSkill() 形式的点列。
    ;
    ; 运算名在首位，符号或字符串均可，且不分大小写。操作数若是点列列表（Region 形式），
    ; 其成员先按 or 合并成一个整体再参与运算，因此成员重叠不会退化成奇偶规则。
    ; l_b 传 nil 表示 B 为空集，只有 or 允许（结果就是 l_a 自身求并）。
    ; 带宽度对象没有点列形式，Path 需先 ->toRegion()->toSkill()。
    ;
    ; **参数**
    ;   S_op    (sym|str)   - or / and / not / xor
    ;   l_a     (list)      - A 的点列：单个多边形、两点矩形对角、或点列列表
    ;   l_b     (list)      - B，同上；nil 只有 or 允许（即只对 A 求并）
    ;   ?grid   (num|nil)   - 网格；默认 nil
    ;   ?eps    (num|nil)   - 容差；默认 nil（1e-9）
    ;
    ; **返回**
    ;   (list|nil) - 结果点列列表；空结果为 nil
    let((op polys)
        op = case(lowerCase(S_op)
            ("or"   'union)
            ("and"  'intersection)
            ("not"  'difference)
            ("xor"  'xor)
            (t
                error("ycGeom::Boolean: unknown operation %A; expected or, and, not, or xor" S_op)
            )
        )
        unless(l_b || op == 'union
            error("ycGeom::Boolean: l_b may be nil only when the operation is or")
        )
        grid = _Grid(grid)
        eps = _Eps(eps)
        polys = _ShapePolys(l_a l_b op grid eps "ycGeom::Boolean")
        foreach(mapcar x polys x->toSkill())
    )
)

unuseNamespace("ycGeom")

; END
