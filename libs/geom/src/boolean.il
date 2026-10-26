useNamespace("ycGeom")

procedure(_SnapRing(l_pts n_grid n_eps "lgg")  ; -> list[Point]
    ; 吸附、合并并清理一个环。
    ;
    ; **参数**
    ;   l_pts   (list[Point]) - 源点列
    ;   n_grid  (float|nil)   - 网格
    ;   n_eps   (float)       - 容差
    ;
    ; **返回**
    ;   (list[Point]) - 清理后的点列
    let((l_res g_prev g_snap l_clean)
        foreach(g_p l_pts
            g_snap = Point(_Snap(g_p->x() n_grid) _Snap(g_p->y() n_grid))
            unless(g_prev && _Near(g_prev->x() g_snap->x() n_eps)
                && _Near(g_prev->y() g_snap->y() n_eps)
                l_res = tconc(l_res g_snap)
            )
            g_prev = g_snap
        )
        l_clean = _RingPointsClean(car(l_res) n_eps)
        unless(length(l_clean) >= 3
                && abs(_SignedArea(l_clean)) > _AreaTol(l_clean n_eps)
            error("ycGeom::_SnapRing: grid snapping collapsed polygon topology")
        )
        l_clean
    )
)

procedure(_CollectRings(l_polys n_grid n_eps t_reg "lggg")  ; -> list[list[Point]]
    ; 收集多个多边形的所有环。
    ;
    ; **参数**
    ;   l_polys  (list[Polygon]) - 多边形列表
    ;   n_grid   (float|nil)     - 网格
    ;   n_eps    (float)         - 容差
    ;   t_reg    (table)         - 点规范登记表
    ;
    ; **返回**
    ;   (list[list[Point]]) - 环列表
    let((l_res)
        foreach(g_p l_polys
            _AsPolygon(g_p "ycGeom::_Boolean")
            foreach(l_r _Rings(_CanonRing(
                    _SnapRing(g_p->points() n_grid n_eps) n_eps t_reg))
                l_res = tconc(l_res l_r)
            )
        )
        car(l_res)
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
    let((l_res n_len n_i)
        foreach(l_r l_rings
            n_len = length(l_r)
            for(n_i 1 n_len
                l_res = tconc(l_res list(
                    _Nth1(n_i l_r)
                    _Nth1(if(n_i == n_len 1 (n_i + 1)) l_r)
                ))
            )
        )
        car(l_res)
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
    let((n_dx n_dy n_den n_t)
        n_dx = g_b->x() - g_a->x()
        n_dy = g_b->y() - g_a->y()
        n_den = n_dx * n_dx + n_dy * n_dy
        if(n_den <= n_eps * n_eps
        then
            0.0
        else
            n_t = ((g_p->x() - g_a->x()) * n_dx
                + (g_p->y() - g_a->y()) * n_dy) / n_den
            max(0.0 min(1.0 n_t))
        )
    )
)

procedure(_AddCut(g_a g_b g_c g_d n_eps l_t "gggggl")  ; -> list[float]
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
    let((g_x)
        g_x = _SegSegIntersection(g_a g_b g_c g_d n_eps)
        cond(
            (g_x == nil l_t)
            (_PointP(g_x) cons(_EdgeT(g_a g_b g_x n_eps) l_t))
            (_SegmentP(g_x)
                cons(_EdgeT(g_a g_b g_x->start() n_eps)
                    cons(_EdgeT(g_a g_b g_x->end() n_eps) l_t)))
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

procedure(_SortUniqueNums(l_vals n_eps "lg")  ; -> list[float]
    ; 升序排序并删除容差内重复值。
    ;
    ; **参数**
    ;   l_vals  (list[float]) - 参数值
    ;   n_eps   (float)       - 容差
    ;
    ; **返回**
    ;   (list[float]) - 排序去重后的参数
    let((l_sorted l_res g_prev)
        foreach(n_v l_vals
            l_sorted = _InsertNum(l_sorted n_v)
        )
        foreach(n_v l_sorted
            unless(g_prev && _Near(n_v g_prev n_eps)
                l_res = tconc(l_res n_v)
            )
            g_prev = n_v
        )
        car(l_res)
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
    Point(g_a->x() + (g_b->x() - g_a->x()) * n_t
        g_a->y() + (g_b->y() - g_a->y()) * n_t)
)

procedure(_SplitEdges(l_edges n_eps t_reg "lgg")  ; -> list[list[Point]]
    ; 在所有交点处拆分边并去重。
    ;
    ; **参数**
    ;   l_edges  (list[list[Point]]) - 无向边
    ;   n_eps    (float)             - 容差
    ;   t_reg    (table)         - 点规范登记表
    ;
    ; **返回**
    ;   (list[list[Point]]) - 拆分后的无向边
    let((t_seen l_res n_i n_len l_t g_a g_b g_prev g_cur t_key n_edge_len n_tol)
        t_seen = makeTable("geomSplit" nil)
        foreach(l_e l_edges
            g_a = car(l_e)
            g_b = cadr(l_e)
            n_edge_len = sqrt((g_b->x() - g_a->x()) * (g_b->x() - g_a->x())
                + (g_b->y() - g_a->y()) * (g_b->y() - g_a->y()))
            n_tol = if(n_edge_len > n_eps n_eps / n_edge_len 0.0)
            l_t = list(0.0 1.0)
            foreach(l_o l_edges
                unless(l_e == l_o
                    l_t = _AddCut(g_a g_b car(l_o) cadr(l_o) n_eps l_t)
                )
            )
            l_t = _SortUniqueNums(l_t n_tol)
            n_len = length(l_t)
            for(n_i 1 n_len - 1
                g_prev = _CanonPoint(
                    _Lerp(g_a g_b _Nth1(n_i l_t)) n_eps t_reg)
                g_cur = _CanonPoint(
                    _Lerp(g_a g_b _Nth1(n_i + 1 l_t)) n_eps t_reg)
                t_key = _EdgeKey(g_prev g_cur)
                unless(t_seen[t_key]
                    t_seen[t_key] = t
                    l_res = tconc(l_res list(g_prev g_cur))
                )
            )
        )
        car(l_res)
    )
)

procedure(_InsideRings(l_rings g_p n_eps "lgg")  ; -> t | nil
    ; 奇偶判断点是否在环集合内部。
    ;
    ; **参数**
    ;   l_rings  (list[list[Point]]) - 环列表
    ;   g_p      (Point)             - 待判断点
    ;   n_eps    (float)             - 容差
    ;
    ; **返回**
    ;   (t|nil) - 奇偶结果为真
    let((g_in)
        foreach(l_r l_rings
            when(_PointInRing(l_r g_p n_eps)
                g_in = !g_in
            )
        )
        g_in
    )
)

procedure(_ClassifyEdges(l_edges l_ra l_rb g_op n_eps "lllgg")  ; -> list[list[Point]]
    ; 按两侧采样结果保留结果边界的有向边。
    ;
    ; **参数**
    ;   l_edges  (list[list[Point]]) - 拆分后的无向边
    ;   l_ra     (list[list[Point]]) - A 环
    ;   l_rb     (list[list[Point]]) - B 环
    ;   g_op     (sym)               - union/intersection/difference/xor
    ;   n_eps    (float)             - 容差
    ;
    ; **返回**
    ;   (list[list[Point]]) - 结果内部在左侧的有向边
    let((l_res g_a g_b n_dx n_dy n_len n_mx n_my n_nx n_ny n_delta g_left g_right g_la g_lb g_ra g_rb g_lkeep g_rkeep)
        n_delta = if(n_eps * 100.0 > 1e-7 n_eps * 100.0 1e-7)
        foreach(l_e l_edges
            g_a = car(l_e)
            g_b = cadr(l_e)
            n_dx = g_b->x() - g_a->x()
            n_dy = g_b->y() - g_a->y()
            n_len = sqrt(n_dx * n_dx + n_dy * n_dy)
            unless(n_len <= n_eps
                n_mx = (g_a->x() + g_b->x()) / 2.0
                n_my = (g_a->y() + g_b->y()) / 2.0
                n_nx = -n_dy / n_len
                n_ny = n_dx / n_len
                g_left = Point(n_mx + n_nx * n_delta n_my + n_ny * n_delta)
                g_right = Point(n_mx - n_nx * n_delta n_my - n_ny * n_delta)
                g_la = _InsideRings(l_ra g_left n_eps)
                g_lb = _InsideRings(l_rb g_left n_eps)
                g_ra = _InsideRings(l_ra g_right n_eps)
                g_rb = _InsideRings(l_rb g_right n_eps)
                g_lkeep = _InResult(g_op g_la g_lb)
                g_rkeep = _InResult(g_op g_ra g_rb)
                when(g_lkeep != g_rkeep
                    l_res = tconc(l_res
                        if(g_lkeep list(g_a g_b) list(g_b g_a)))
                )
            )
        )
        car(l_res)
    )
)

procedure(_FirstTraceEdge(t_adj l_order "gl")  ; -> list[Point] | nil
    ; 返回第一条未使用的有向边。
    ;
    ; **参数**
    ;   t_adj   (table) - 起点键 → 有向边列表
    ;   l_order (list)  - 起点键顺序
    ;
    ; **返回**
    ;   (list[Point]|nil) - 有向边；用完为 nil
    let((l_found)
        foreach(t_key l_order
            when(t_adj[t_key] && !l_found
                l_found = car(t_adj[t_key])
            )
        )
        l_found
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
    let((l_res t_to)
        t_to = _PtKey(g_to)
        foreach(l_e l_edges
            unless(_PtKey(cadr(l_e)) == t_to
                l_res = tconc(l_res l_e)
            )
        )
        car(l_res)
    )
)

procedure(_ChooseNext(g_prev g_cur l_cands n_eps "gglg")  ; -> Point
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
    let((n_refx n_refy g_best n_best n_dx n_dy n_cross n_dot n_ang n_cw)
        n_refx = g_prev->x() - g_cur->x()
        n_refy = g_prev->y() - g_cur->y()
        foreach(l_e l_cands
            n_dx = cadr(l_e)->x() - g_cur->x()
            n_dy = cadr(l_e)->y() - g_cur->y()
            n_cross = n_refx * n_dy - n_refy * n_dx
            n_dot = n_refx * n_dx + n_refy * n_dy
            n_ang = atan2(n_cross n_dot)
            n_cw = if(n_ang <= 0.0 -n_ang (2.0 * 3.141592653589793 - n_ang))
            when(g_best == nil || n_cw < n_best
                g_best = cadr(l_e)
                n_best = n_cw
            )
        )
        g_best
    )
)

procedure(_TraceLoops(l_edges n_eps "lg")  ; -> list[list[Point]]
    ; 追踪结果边界闭环。
    ;
    ; **参数**
    ;   l_edges  (list[list[Point]]) - 结果内部在左侧的有向边
    ;   n_eps    (float)             - 容差
    ;
    ; **返回**
    ;   (list[list[Point]]) - 闭环点列
    let((t_adj l_order l_res l_e g_start g_cur g_prev g_next l_ring l_cands t_key)
        t_adj = makeTable("geomTrace" nil)
        foreach(l_e l_edges
            t_key = _PtKey(car(l_e))
            unless(t_adj[t_key]
                l_order = tconc(l_order t_key)
            )
            t_adj[t_key] = cons(l_e t_adj[t_key])
        )
        l_order = car(l_order)
        while(_FirstTraceEdge(t_adj l_order)
            l_e = _FirstTraceEdge(t_adj l_order)
            g_start = car(l_e)
            g_cur = cadr(l_e)
            g_prev = g_start
            l_ring = tconc(nil g_start)
            t_adj[_PtKey(g_start)] = _RemoveEdge(
                t_adj[_PtKey(g_start)] g_start g_cur)
            while(_PtKey(g_cur) != _PtKey(g_start)
                l_ring = tconc(l_ring g_cur)
                l_cands = t_adj[_PtKey(g_cur)]
                unless(l_cands
                    error("ycGeom::_TraceLoops: boolean trace lost its boundary")
                )
                g_next = _ChooseNext(g_prev g_cur l_cands n_eps)
                t_adj[_PtKey(g_cur)] = _RemoveEdge(l_cands g_cur g_next)
                g_prev = g_cur
                g_cur = g_next
            )
            l_res = tconc(l_res car(l_ring))
        )
        car(l_res)
    )
)

procedure(_InResult(g_op g_inA g_inB "ggg")  ; -> t | nil
    ; 判断采样点是否属于布尔结果。
    ;
    ; **参数**
    ;   g_op   (sym)   - union/intersection/difference/xor
    ;   g_inA  (t|nil) - 点在 A 内
    ;   g_inB  (t|nil) - 点在 B 内
    ;
    ; **返回**
    ;   (t|nil) - 属于结果为 t
    cond(
        (g_op == 'union g_inA || g_inB)
        (g_op == 'intersection g_inA && g_inB)
        (g_op == 'difference g_inA && !g_inB)
        (g_op == 'xor g_inA != g_inB)
    )
)

procedure(_CleanPolygons(l_polys n_eps "lg")  ; -> list[Polygon]
    ; 去除结果多边形的共线点（内部实现）。
    ;
    ; **参数**
    ;   l_polys  (list[Polygon]) - 多边形列表
    ;   n_eps    (float)         - 容差
    ;
    ; **返回**
    ;   (list[Polygon]) - 清理后的列表；空结果 nil
    let((l_res)
        foreach(g_p l_polys
            l_res = tconc(l_res g_p->removeCollinear(?eps n_eps))
        )
        car(l_res)
    )
)

procedure(_Boolean(l_a l_b g_op n_grid n_eps "llggg")  ; -> list[Polygon]
    ; 计算两个多边形集合的布尔结果。
    ;
    ; **参数**
    ;   l_a     (list[Polygon]) - A
    ;   l_b     (list[Polygon]) - B
    ;   g_op    (sym)           - union/intersection/difference/xor
    ;   n_grid  (float|nil)     - 网格
    ;   n_eps   (float)         - 容差
    ;
    ; **返回**
    ;   (list[Polygon]) - 结果多边形；空结果 nil
    let((n_gridv n_epsv l_ra l_rb l_edges l_kept l_loops l_res t_reg)
        unless(g_op == 'union || g_op == 'intersection || g_op == 'difference || g_op == 'xor
            error("ycGeom::_Boolean: unknown operation %A" g_op)
        )
        foreach(g_p l_a
            _AsPolygon(g_p "ycGeom::_Boolean")
        )
        foreach(g_p l_b
            _AsPolygon(g_p "ycGeom::_Boolean")
        )
        n_gridv = _Grid(n_grid)
        n_epsv = _Eps(n_eps)
        cond(
            (l_a == nil && l_b == nil l_res = nil)
            (l_a == nil && (g_op == 'union || g_op == 'xor) l_res = l_b)
            (l_a == nil l_res = nil)
            (l_b == nil && g_op == 'union l_res = l_a)
            (l_b == nil && (g_op == 'difference || g_op == 'xor)
                l_res = l_a)
            (l_b == nil l_res = nil)
            (t
                t_reg = makeTable("geomCanon" nil)
                l_ra = _CollectRings(l_a n_gridv n_epsv t_reg)
                l_rb = _CollectRings(l_b n_gridv n_epsv t_reg)
                l_edges = _SplitEdges(
                    append(_RingEdgeList(l_ra) _RingEdgeList(l_rb))
                    n_epsv t_reg)
                l_kept = _ClassifyEdges(l_edges l_ra l_rb g_op n_epsv)
                l_loops = _TraceLoops(l_kept n_epsv)
                when(l_loops
                    l_res = _BuildPolygons(
                        _NestLoops(l_loops n_epsv) n_gridv n_epsv)
                )
            )
        )
        l_res
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

procedure(_LoopDepth(l_loops n_idx n_eps "lng")  ; -> int
    ; 计算环被多少个更大的环包含。
    ;
    ; **参数**
    ;   l_loops  (list[list[Point]]) - 环列表
    ;   n_idx    (int)               - 当前环 1-based 下标
    ;   n_eps    (float)             - 容差
    ;
    ; **返回**
    ;   (int) - 包含计数
    let((n_depth n_area_i n_tol_i g_p n_j n_area_j n_tol_j)
        n_depth = 0
        n_area_i = abs(_SignedArea(_Nth1(n_idx l_loops)))
        n_tol_i = _AreaTol(_Nth1(n_idx l_loops) n_eps)
        g_p = car(_Nth1(n_idx l_loops))
        for(n_j 1 length(l_loops)
            unless(n_j == n_idx
                n_area_j = abs(_SignedArea(_Nth1(n_j l_loops)))
                n_tol_j = _AreaTol(_Nth1(n_j l_loops) n_eps)
                when(n_area_j > n_area_i + max(n_tol_i n_tol_j)
                    && _PointInRing(_Nth1(n_j l_loops) g_p n_eps)
                    n_depth++
                )
            )
        )
        n_depth
    )
)

procedure(_NestLoops(l_loops n_eps "lg")  ; -> list
    ; 按包含关系区分外环和洞环，并归组。
    ;
    ; **参数**
    ;   l_loops  (list[list[Point]]) - 闭环列表
    ;   n_eps    (float)             - 容差
    ;
    ; **返回**
    ;   (list) - 每组 (外环 洞环列表)
    let((l_infos l_groups n_i l_loop n_area n_depth l_info l_hole n_owner n_best n_k l_g l_new)
        for(n_i 1 length(l_loops)
            l_loop = _Nth1(n_i l_loops)
            n_area = abs(_SignedArea(l_loop))
            n_depth = _LoopDepth(l_loops n_i n_eps)
            when((_EvenDepth(n_depth) && _SignedArea(l_loop) < 0.0)
                || (!_EvenDepth(n_depth) && _SignedArea(l_loop) > 0.0)
                l_loop = reverse(l_loop)
            )
            l_infos = tconc(l_infos list(l_loop n_area n_depth))
        )
        l_infos = car(l_infos)
        foreach(l_info l_infos
            when(_EvenDepth(caddr(l_info))
                l_groups = tconc(l_groups list(car(l_info) nil cadr(l_info)))
            )
        )
        l_groups = car(l_groups)
        foreach(l_info l_infos
            unless(_EvenDepth(caddr(l_info))
                l_hole = car(l_info)
                n_owner = nil
                n_best = nil
                for(n_k 1 length(l_groups)
                    l_g = _Nth1(n_k l_groups)
                    when(_PointInRing(car(l_g) car(l_hole) n_eps)
                        when(n_owner == nil || caddr(l_g) < n_best
                            n_owner = n_k
                            n_best = caddr(l_g)
                        )
                    )
                )
                unless(n_owner
                    error("ycGeom::_NestLoops: hole has no containing outer loop")
                )
                l_new = nil
                for(n_k 1 length(l_groups)
                    l_g = _Nth1(n_k l_groups)
                    l_new = tconc(l_new
                        if(n_k == n_owner
                            list(car(l_g) cons(l_hole cadr(l_g)) caddr(l_g))
                            l_g
                        )
                    )
                )
                l_groups = car(l_new)
            )
        )
        l_new = nil
        foreach(l_g l_groups
            l_new = tconc(l_new list(car(l_g) cadr(l_g)))
        )
        car(l_new)
    )
)

procedure(_RightmostIndex(l_ring n_eps "lg")  ; -> int
    ; 返回点列最右点的 1-based 下标。
    ;
    ; **参数**
    ;   l_ring  (list[Point]) - 点列
    ;   n_eps   (float)       - 容差
    ;
    ; **返回**
    ;   (int) - 最右点下标；x 在容差内时取 y 更大者
    let((n_best n_bx n_by n_i g_p)
        n_best = 1
        n_bx = _Nth1(1 l_ring)->x()
        n_by = _Nth1(1 l_ring)->y()
        for(n_i 2 length(l_ring)
            g_p = _Nth1(n_i l_ring)
            when(g_p->x() > n_bx + n_eps
                || (abs(g_p->x() - n_bx) <= n_eps
                    && g_p->y() > n_by + n_eps)
                n_best = n_i
                n_bx = g_p->x()
                n_by = g_p->y()
            )
        )
        n_best
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
    let((l_res n_len n_i n_idx)
        n_len = length(l_ring)
        for(n_i 1 n_len
            n_idx = n_start + n_i - 1
            when(n_idx > n_len
                n_idx = n_idx - n_len
            )
            l_res = tconc(l_res _Nth1(n_idx l_ring))
        )
        car(l_res)
    )
)

procedure(_BridgeVisible(l_outer l_hole n_oi n_eps "llxg")  ; -> t | nil
    ; 判断洞右点与外环顶点的桥是否可见。
    ;
    ; **参数**
    ;   l_outer  (list[Point]) - 外环
    ;   l_hole   (list[Point]) - 洞环，首点为 H
    ;   n_oi     (int)         - 外环顶点下标
    ;   n_eps    (float)       - 容差
    ;
    ; **返回**
    ;   (t|nil) - 桥不与边界相交且中点位置正确
    let((g_h g_o n_len n_i g_a g_b g_mid t_oh t_o g_ok)
        g_h = car(l_hole)
        g_o = _Nth1(n_oi l_outer)
        t_oh = _PtKey(g_h)
        t_o = _PtKey(g_o)
        g_ok = t
        n_len = length(l_outer)
        for(n_i 1 n_len
            when(g_ok
                g_a = _Nth1(n_i l_outer)
                g_b = _Nth1(if(n_i == n_len 1 n_i + 1) l_outer)
                unless(_PtKey(g_a) == t_o || _PtKey(g_b) == t_o
                    when(_SegmentsCross(g_h g_o g_a g_b n_eps)
                        g_ok = nil
                    )
                )
            )
        )
        n_len = length(l_hole)
        for(n_i 1 n_len
            when(g_ok
                g_a = _Nth1(n_i l_hole)
                g_b = _Nth1(if(n_i == n_len 1 n_i + 1) l_hole)
                unless(_PtKey(g_a) == t_oh || _PtKey(g_b) == t_oh
                    when(_SegmentsCross(g_h g_o g_a g_b n_eps)
                        g_ok = nil
                    )
                )
            )
        )
        when(g_ok
            g_mid = Point((g_h->x() + g_o->x()) / 2.0
                (g_h->y() + g_o->y()) / 2.0)
            g_ok = _PointInRing(l_outer g_mid n_eps)
                && !_PointInRing(l_hole g_mid n_eps)
        )
        g_ok
    )
)

procedure(_FindBridge(l_outer l_hole n_eps "llg")  ; -> int | nil
    ; 选择距离最近的可见桥。
    ;
    ; **参数**
    ;   l_outer  (list[Point]) - 外环
    ;   l_hole   (list[Point]) - 洞环，首点为 H
    ;   n_eps    (float)       - 容差
    ;
    ; **返回**
    ;   (int|nil) - 外环顶点下标；无可见桥为 nil
    let((n_best n_bestDist n_i n_dist)
        n_bestDist = 0.0
        for(n_i 1 length(l_outer)
            when(_BridgeVisible(l_outer l_hole n_i n_eps)
                n_dist = _Nth1(n_i l_outer)->distanceTo(car(l_hole))
                when(n_best == nil || n_dist < n_bestDist
                    n_best = n_i
                    n_bestDist = n_dist
                )
            )
        )
        n_best
    )
)

procedure(_SpliceHole(l_outer l_hole n_eps "llg")  ; -> list[Point]
    ; 把洞环用切割线接回外环。
    ;
    ; **参数**
    ;   l_outer  (list[Point]) - 外环
    ;   l_hole   (list[Point]) - 洞环
    ;   n_eps    (float)       - 容差
    ;
    ; **返回**
    ;   (list[Point]) - keyhole 点列
    let((n_hi l_h n_oi l_prefix l_suffix g_o g_h n_i)
        n_hi = _RightmostIndex(l_hole n_eps)
        l_h = _Rotate(l_hole n_hi)
        g_h = car(l_h)
        n_oi = _FindBridge(l_outer l_h n_eps)
        unless(n_oi
            error("ycGeom::_SpliceHole: no visible bridge for hole")
        )
        g_o = _Nth1(n_oi l_outer)
        for(n_i 1 n_oi
            l_prefix = tconc(l_prefix _Nth1(n_i l_outer))
        )
        for(n_i n_oi + 1 length(l_outer)
            l_suffix = tconc(l_suffix _Nth1(n_i l_outer))
        )
        append(car(l_prefix)
            cons(g_h
                append(cdr(l_h)
                    cons(g_h
                        cons(g_o car(l_suffix))))))
    )
)

procedure(_BuildPolygons(l_groups n_grid n_eps "lgg")  ; -> list[Polygon]
    ; 把分组环转换为 keyhole Polygon。
    ;
    ; **参数**
    ;   l_groups  (list)       - 每组 (外环 洞环列表)
    ;   n_grid    (float|nil)  - 网格
    ;   n_eps     (float)      - 容差
    ;
    ; **返回**
    ;   (list[Polygon]) - 结果多边形
    let((l_res l_outer l_holes)
        foreach(l_g l_groups
            l_outer = car(l_g)
            l_holes = cadr(l_g)
            foreach(l_h l_holes
                l_outer = _SpliceHole(l_outer l_h n_eps)
            )
            l_outer = _SnapRing(l_outer n_grid n_eps)
            l_res = tconc(l_res Polygon(l_outer))
        )
        car(l_res)
    )
)

unuseNamespace("ycGeom")

; END
