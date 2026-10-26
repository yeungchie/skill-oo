useNamespace("ycGeom")

; Directional offset model:
;
;   unselected edge (stays)
;   +------------------+
;   |                  |
;   |     original     |======> selected edge strip
;   |                  |
;   +------------------+
;
; Edge strips are unioned; corner caps fill the gaps between them.

procedure(_SizeDirP(g_dir "g")  ; -> t | nil
    ; 判断方向符号是否合法（内部实现）。
    ;
    ; **参数**
    ;   g_dir  (any) - 待判断值
    ;
    ; **返回**
    ;   (t|nil) - left/right/up/down/all 为 t
    symbolp(g_dir) && member(g_dir '(left right up down all))
)

procedure(_SizeDirs(g_dir "g")  ; -> list[sym]
    ; 规范 ?dir 为方向列表。
    ;
    ; **参数**
    ;   g_dir  (sym|list) - 方向或方向列表
    ;
    ; **返回**
    ;   (list[sym]) - 去重后的方向；非法值 error
    let((l_res)
        cond(
            (g_dir == 'all list('left 'right 'up 'down))
            (_SizeDirP(g_dir) list(g_dir))
            (listp(g_dir)
                unless(g_dir
                    error("ycGeom::_SizeDirs: ?dir must not be an empty list")
                )
                foreach(g_item g_dir
                    unless(_SizeDirP(g_item)
                        error("ycGeom::_SizeDirs: invalid ?dir element %A" g_item)
                    )
                )
                when(member('all g_dir) && length(g_dir) > 1
                    error("ycGeom::_SizeDirs: ?dir 'all cannot be combined with other directions")
                )
                foreach(g_item g_dir
                    unless(member(g_item l_res)
                        l_res = tconc(l_res g_item)
                    )
                )
                car(l_res)
            )
            (t error("ycGeom::_SizeDirs: ?dir must be a direction or list, got %A" g_dir))
        )
    )
)

procedure(_SizeCorner(g_corner "g")  ; -> sym
    ; 规范拐角风格。
    ;
    ; **参数**
    ;   g_corner  (sym) - 拐角风格
    ;
    ; **返回**
    ;   (sym) - miter/round/bevel/none
    unless(symbolp(g_corner) && member(g_corner '(miter round bevel none))
        error("ycGeom::_SizeCorner: ?corner must be miter, round, bevel, or none, got %A"
            g_corner)
    )
    g_corner
)

procedure(_SizeMiterLimit(g_value "g")  ; -> float
    ; 规范 miter 限制。
    ;
    ; **参数**
    ;   g_value  (num|nil) - 限制值
    ;
    ; **返回**
    ;   (float) - 正数；nil 为 4.0
    cond(
        (g_value == nil 4.0)
        (numberp(g_value) && g_value > 0.0 float(g_value))
        (t error("ycGeom::_SizeMiterLimit: ?miterLimit must be a positive number, got %A"
            g_value))
    )
)

procedure(_SizeRoundSegments(g_value "g")  ; -> int
    ; 规范圆角段数。
    ;
    ; **参数**
    ;   g_value  (int|nil) - 每 90 度线段数
    ;
    ; **返回**
    ;   (int) - 正整数；nil 为 8
    cond(
        (g_value == nil 8)
        (fixp(g_value) && g_value > 0 g_value)
        (t error("ycGeom::_SizeRoundSegments: ?roundSegments must be a positive integer, got %A"
            g_value))
    )
)

procedure(_SizeCheck(n_value g_dir g_ratio g_corner g_limit g_segments t_ctx "ngggggt")  ; -> list
    ; 校验并规范 size 参数（内部实现）。
    ;
    ; **参数**
    ;   n_value     (num)      - 距离或倍率
    ;   g_dir       (sym|list) - 方向
    ;   g_ratio     (t|nil)    - 倍率模式
    ;   g_corner    (sym)      - 拐角风格
    ;   g_limit     (num|nil)  - miter 限制
    ;   g_segments  (int|nil)  - 圆角段数
    ;   t_ctx       (str)      - 错误上下文
    ;
    ; **返回**
    ;   (list) - (方向列表 倍率标志)
    let((l_dirs g_ratioMode)
        unless(numberp(n_value)
            error("%s: value must be a number, got %A" t_ctx n_value)
        )
        l_dirs = _SizeDirs(g_dir)
        g_ratioMode = _Flag(g_ratio "ratio")
        _SizeCorner(g_corner)
        _SizeMiterLimit(g_limit)
        _SizeRoundSegments(g_segments)
        when(g_ratioMode && n_value <= 0.0
            error("%s: ratio value must be positive, got %A" t_ctx n_value)
        )
        list(l_dirs g_ratioMode)
    )
)

procedure(_SizeOrientRings(l_rings "l")  ; -> list[list[Point]]
    ; 外环调整为 CCW，洞环调整为 CW（内部实现）。
    ;
    ; **参数**
    ;   l_rings  (list[list[Point]]) - 原始环
    ;
    ; **返回**
    ;   (list[list[Point]]) - 定向后的环
    let((n_max l_infos l_res)
        foreach(l_ring l_rings
            let((n_area)
                l_ring = _CollinearClean(l_ring _Eps(nil))
                n_area = abs(_SignedArea(l_ring))
                l_infos = tconc(l_infos list(l_ring n_area))
                when(n_max == nil || n_area > n_max
                    n_max = n_area
                )
            )
        )
        l_infos = car(l_infos)
        foreach(l_info l_infos
            let((l_ring n_area)
                l_ring = car(l_info)
                n_area = cadr(l_info)
                if(n_area == n_max
                    when(_SignedArea(l_ring) < 0.0
                        l_ring = reverse(l_ring)
                    )
                    when(_SignedArea(l_ring) > 0.0
                        l_ring = reverse(l_ring)
                    )
                )
                l_res = tconc(l_res l_ring)
            )
        )
        car(l_res)
    )
)

procedure(_SizeRingEdges(l_ring "l")  ; -> list
    ; 生成带材料外法线的边记录（内部实现）。
    ;
    ; **参数**
    ;   l_ring  (list[Point]) - 已定向环
    ;
    ; **返回**
    ;   (list) - (a b nx ny) 记录
    let((l_res n_len n_i g_a g_b n_dx n_dy n_lenr)
        n_len = length(l_ring)
        for(n_i 1 n_len
            g_a = _Nth1(n_i l_ring)
            g_b = _Nth1(if(n_i == n_len 1 (n_i + 1)) l_ring)
            n_dx = g_b->x() - g_a->x()
            n_dy = g_b->y() - g_a->y()
            n_lenr = sqrt(n_dx * n_dx + n_dy * n_dy)
            unless(n_lenr <= _Eps(nil)
                l_res = tconc(l_res list(g_a g_b
                    n_dy / n_lenr (-n_dx) / n_lenr))
            )
        )
        car(l_res)
    )
)

procedure(_SizeEdgeSelected(n_nx n_ny l_dirs n_eps "nnlg")  ; -> t | nil
    ; 判断边是否被方向选中。
    ;
    ; **参数**
    ;   n_nx    (float)     - 外法线 x
    ;   n_ny    (float)     - 外法线 y
    ;   l_dirs  (list[sym]) - 方向
    ;   n_eps   (float)     - 法线阈值
    ;
    ; **返回**
    ;   (t|nil) - 选中为 t
    (member('left l_dirs) && n_nx < -n_eps)
        || (member('right l_dirs) && n_nx > n_eps)
        || (member('down l_dirs) && n_ny < -n_eps)
        || (member('up l_dirs) && n_ny > n_eps)
        || member('all l_dirs)
)

procedure(_SizeEdgeDistance(n_nx n_ny n_width n_height l_dirs n_value g_ratio "nnnnlng")  ; -> float
    ; 计算选中边的 offset 距离。
    ;
    ; **参数**
    ;   n_nx      (float)     - 外法线 x
    ;   n_ny      (float)     - 外法线 y
    ;   n_width   (float)     - 原 bBox 宽度
    ;   n_height  (float)     - 原 bBox 高度
    ;   l_dirs    (list[sym]) - 方向
    ;   n_value   (num)       - 距离或倍率
    ;   g_ratio   (t|nil)     - 倍率模式
    ;
    ; **返回**
    ;   (float) - 带符号距离
    if(!g_ratio
        float(n_value)
        let((n_halfx n_halfy)
            n_halfx = if(member('left l_dirs) && member('right l_dirs)
                0.5 1.0)
            n_halfy = if(member('up l_dirs) && member('down l_dirs)
                0.5 1.0)
            (float(n_value) - 1.0)
                * (abs(n_nx) * n_width * n_halfx
                    + abs(n_ny) * n_height * n_halfy)
        )
    )
)

procedure(_SizeLinePoint(g_p g_u g_q g_v "gggg")  ; -> Point | nil
    ; 计算两条无限直线的交点。
    ;
    ; **参数**
    ;   g_p  (Point) - 直线一上的点
    ;   g_u  (list[float]) - 直线一方向
    ;   g_q  (Point) - 直线二上的点
    ;   g_v  (list[float]) - 直线二方向
    ;
    ; **返回**
    ;   (Point|nil) - 交点；平行时为 nil
    let((n_ux n_uy n_vx n_vy n_det n_t)
        n_ux = car(g_u)
        n_uy = cadr(g_u)
        n_vx = car(g_v)
        n_vy = cadr(g_v)
        n_det = n_ux * n_vy - n_uy * n_vx
        unless(abs(n_det) <= _AngleTol()
            n_t = ((g_q->x() - g_p->x()) * n_vy
                - (g_q->y() - g_p->y()) * n_vx) / n_det
            Point(list(g_p->x() + n_ux * n_t
                g_p->y() + n_uy * n_t))
        )
    )
)

procedure(_SizeStrip(g_a g_b n_nx n_ny n_d "ggggn")  ; -> Polygon | nil
    ; 生成一条选中边的矩形带。
    ;
    ; **参数**
    ;   g_a  (Point) - 边起点
    ;   g_b  (Point) - 边终点
    ;   n_nx (float) - 外法线 x
    ;   n_ny (float) - 外法线 y
    ;   n_d  (float) - 带符号距离
    ;
    ; **返回**
    ;   (Polygon|nil) - 边带；零距离为 nil
    unless(abs(n_d) <= _Eps(nil)
        Polygon(list(
            g_a
            g_b
            Point(list(g_b->x() + n_nx * n_d g_b->y() + n_ny * n_d))
            Point(list(g_a->x() + n_nx * n_d g_a->y() + n_ny * n_d))
        ))
    )
)

procedure(_SizeRoundCap(g_v g_v1 g_v2 n_d1 n_d2 n_segments "gggnnx")  ; -> Polygon | nil
    ; 生成圆角扇面。
    ;
    ; **参数**
    ;   g_v         (Point) - 原顶点
    ;   g_v1        (Point) - 前一偏移端点
    ;   g_v2        (Point) - 后一偏移端点
    ;   n_d1        (float) - 前一边距离
    ;   n_d2        (float) - 后一边距离
    ;   n_segments  (int)   - 每 90 度段数
    ;
    ; **返回**
    ;   (Polygon|nil) - 圆角扇面
    let((n_a1 n_a2 n_delta n_steps n_rad n_i l_res)
        n_a1 = atan2(g_v1->y() - g_v->y() g_v1->x() - g_v->x())
        n_a2 = atan2(g_v2->y() - g_v->y() g_v2->x() - g_v->x())
        n_delta = n_a2 - n_a1
        while(n_delta > 3.141592653589793
            n_delta = n_delta - 6.283185307179586
        )
        while(n_delta < -3.141592653589793
            n_delta = n_delta + 6.283185307179586
        )
        when(abs(n_delta) <= _AngleTol()
            nil
        )
        n_steps = int(abs(n_delta) / 1.570796326794897 * n_segments)
        when(n_steps < 1 n_steps = 1)
        n_rad = max(abs(n_d1) abs(n_d2))
        l_res = tconc(l_res g_v1)
        for(n_i 1 n_steps - 1
            l_res = tconc(l_res Point(list(
                g_v->x() + n_rad * cos(n_a1 + n_delta * n_i / n_steps)
                g_v->y() + n_rad * sin(n_a1 + n_delta * n_i / n_steps)
            )))
        )
        l_res = tconc(l_res g_v2)
        l_res = tconc(l_res g_v)
        Polygon(car(l_res))
    )
)

procedure(_SizeCapSelected(g_v g_pa g_nb l_e1 l_e2 n_limit n_segments g_corner "gggllnxs")  ; -> Polygon | nil
    ; 生成两条选中边的拐角帽。
    ;
    ; **参数**
    ;   g_v         (Point) - 顶点
    ;   g_pa        (Point) - 前一边起点
    ;   g_nb        (Point) - 后一边终点
    ;   l_e1        (list)  - 前一边记录
    ;   l_e2        (list)  - 后一边记录
    ;   n_limit     (float) - miter 限制
    ;   n_segments  (int)   - 圆角段数
    ;   g_corner    (sym)   - 拐角风格
    ;
    ; **返回**
    ;   (Polygon|nil) - 拐角帽
    let((n_nx1 n_ny1 n_d1 n_nx2 n_ny2 n_d2 g_v1 g_v2 g_m)
        n_nx1 = _Nth1(3 l_e1)
        n_ny1 = _Nth1(4 l_e1)
        n_d1 = _Nth1(6 l_e1)
        n_nx2 = _Nth1(3 l_e2)
        n_ny2 = _Nth1(4 l_e2)
        n_d2 = _Nth1(6 l_e2)
        g_v1 = Point(list(g_v->x() + n_nx1 * n_d1
            g_v->y() + n_ny1 * n_d1))
        g_v2 = Point(list(g_v->x() + n_nx2 * n_d2
            g_v->y() + n_ny2 * n_d2))
        cond(
            (g_corner == 'none nil)
            (g_corner == 'bevel Polygon(list(g_v1 g_v g_v2)))
            (g_corner == 'round
                _SizeRoundCap(g_v g_v1 g_v2 n_d1 n_d2 n_segments))
            (g_corner == 'miter
                g_m = _SizeLinePoint(g_v1
                    list(g_v->x() - g_pa->x() g_v->y() - g_pa->y())
                    g_v2
                    list(g_nb->x() - g_v->x() g_nb->y() - g_v->y()))
                if(g_m && g_v->distanceTo(g_m)
                        <= n_limit * max(abs(n_d1) abs(n_d2))
                    Polygon(list(g_v1 g_m g_v2 g_v))
                    Polygon(list(g_v1 g_v g_v2))
                )
            )
        )
    )
)

procedure(_SizeExtendCap(g_v g_pa g_nb l_e1 l_e2 g_corner "gggllg")  ; -> Polygon | nil
    ; 生成选中边与未选中边之间的延伸帽。
    ;
    ; **参数**
    ;   g_v        (Point) - 顶点
    ;   g_pa       (Point) - 前一边起点
    ;   g_nb       (Point) - 后一边终点
    ;   l_e1       (list)  - 前一边记录
    ;   l_e2       (list)  - 后一边记录
    ;   g_corner   (sym)   - 拐角风格
    ;
    ; **返回**
    ;   (Polygon|nil) - 延伸帽
    let((n_sel1 n_sel2 n_nx1 n_ny1 n_d1 n_nx2 n_ny2 n_d2 g_v1 g_v2 g_q g_cap)
        unless(g_corner == 'none
            n_sel1 = _Nth1(5 l_e1)
            n_sel2 = _Nth1(5 l_e2)
            n_nx1 = _Nth1(3 l_e1)
            n_ny1 = _Nth1(4 l_e1)
            n_d1 = _Nth1(6 l_e1)
            n_nx2 = _Nth1(3 l_e2)
            n_ny2 = _Nth1(4 l_e2)
            n_d2 = _Nth1(6 l_e2)
            when(n_sel1 && !n_sel2
                progn(
                    g_v1 = Point(list(g_v->x() + n_nx1 * n_d1
                        g_v->y() + n_ny1 * n_d1))
                    g_q = _SizeLinePoint(g_v1
                        list(g_v->x() - g_pa->x() g_v->y() - g_pa->y())
                        g_v
                        list(g_nb->x() - g_v->x() g_nb->y() - g_v->y()))
                    when(g_q && !g_q->equals(g_v1 ?eps _Eps(nil))
                        && !g_q->equals(g_v ?eps _Eps(nil))
                        g_cap = Polygon(list(g_v1 g_q g_v))
                    )
                )
            )
            when(!n_sel1 && n_sel2
                progn(
                    g_v2 = Point(list(g_v->x() + n_nx2 * n_d2
                        g_v->y() + n_ny2 * n_d2))
                    g_q = _SizeLinePoint(g_v
                        list(g_v->x() - g_pa->x() g_v->y() - g_pa->y())
                        g_v2
                        list(g_nb->x() - g_v->x() g_nb->y() - g_v->y()))
                    when(g_q && !g_q->equals(g_v2 ?eps _Eps(nil))
                        && !g_q->equals(g_v ?eps _Eps(nil))
                        g_cap = Polygon(list(g_v g_q g_v2))
                    )
                )
            )
            g_cap
        )
    )
)

procedure(_SizePolygon(self n_value g_dir g_ratio g_corner g_miterLimit g_roundSegments t_ctx "gngggggt")  ; -> Region
    ; 对单个 Polygon 执行方向 offset。
    ;
    ; **参数**
    ;   self              (Polygon)   - 源多边形
    ;   n_value           (num)       - 距离或倍率
    ;   g_dir             (sym|list)  - 方向
    ;   g_ratio           (t|nil)     - 倍率模式
    ;   g_corner          (sym)       - 拐角风格
    ;   g_miterLimit      (num|nil)   - miter 限制
    ;   g_roundSegments   (int|nil)   - 圆角段数
    ;   t_ctx             (str)       - 错误上下文
    ;
    ; **返回**
    ;   (Region) - 涨缩结果
    let((l_check l_dirs g_ratioMode l_box n_width n_height n_limit n_segments
         l_ops l_region l_rings l_enh g_src)
        l_check = _SizeCheck(n_value g_dir g_ratio g_corner g_miterLimit
            g_roundSegments t_ctx)
        l_dirs = car(l_check)
        g_ratioMode = cadr(l_check)
        g_src = self->removeCollinear()
        l_box = g_src->bBox()
        n_width = car(cadr(l_box)) - car(car(l_box))
        n_height = cadr(cadr(l_box)) - cadr(car(l_box))
        n_limit = _SizeMiterLimit(g_miterLimit)
        n_segments = _SizeRoundSegments(g_roundSegments)
        l_region = Region(list(g_src) ?normalize nil)
        unless((_Near(n_value 0.0 _Eps(nil))
                || (g_ratioMode && _Near(n_value 1.0 _Eps(nil))))
            progn(
            l_rings = _SizeOrientRings(_Rings(g_src->points()))
            foreach(l_ring l_rings
                let((l_recs n_len n_i l_e n_sel n_d g_a g_b n_nx n_ny)
                    l_recs = _SizeRingEdges(l_ring)
                    l_enh = nil
                    foreach(l_e l_recs
                        g_a = _Nth1(1 l_e)
                        g_b = _Nth1(2 l_e)
                        n_nx = _Nth1(3 l_e)
                        n_ny = _Nth1(4 l_e)
                        n_sel = _SizeEdgeSelected(n_nx n_ny l_dirs _Eps(nil))
                        n_d = _SizeEdgeDistance(n_nx n_ny n_width n_height
                            l_dirs n_value g_ratioMode)
                        l_enh = tconc(l_enh list(g_a g_b n_nx n_ny n_sel n_d))
                        when(n_sel
                            l_ops = tconc(l_ops
                                _SizeStrip(g_a g_b n_nx n_ny n_d))
                        )
                    )
                    l_enh = car(l_enh)
                    n_len = length(l_enh)
                    for(n_i 1 n_len
                        let((l_e1 l_e2 g_v g_cap)
                            l_e1 = _Nth1(n_i l_enh)
                            l_e2 = _Nth1(if(n_i == n_len 1 (n_i + 1)) l_enh)
                            g_v = _Nth1(2 l_e1)
                            when(_Nth1(5 l_e1) && _Nth1(5 l_e2)
                                progn(
                                    g_cap = _SizeCapSelected(g_v _Nth1(1 l_e1)
                                        _Nth1(2 l_e2) l_e1 l_e2 n_limit
                                        n_segments g_corner)
                                    when(g_cap
                                        l_ops = tconc(l_ops g_cap)
                                    )
                                )
                            )
                            unless(_Nth1(5 l_e1) == _Nth1(5 l_e2)
                                progn(
                                    g_cap = _SizeExtendCap(g_v _Nth1(1 l_e1)
                                        _Nth1(2 l_e2) l_e1 l_e2 g_corner)
                                    when(g_cap
                                        l_ops = tconc(l_ops g_cap)
                                    )
                                )
                            )
                        )
                    )
                )
            )
            foreach(l_op car(l_ops)
                when(l_op
                    l_region = Region(_Boolean(
                        l_region->polygons() list(l_op)
                        if(if(g_ratioMode n_value > 1.0 n_value > 0.0)
                            'union 'difference)
                        nil _Eps(nil))
                        ?normalize nil)
                )
            )
            )
        )
        Region(_CleanPolygons(l_region->polygons() _Eps(nil)) ?normalize nil)
    )
)

procedure(_SizeRegion(l_polys n_value g_dir g_ratio g_corner g_miterLimit g_roundSegments "lnggggg")  ; -> Region
    ; 对 Region 的每个 Polygon 独立执行 size。
    ;
    ; **参数**
    ;   l_polys          (list[Polygon]) - 源多边形
    ;   n_value          (num)           - 距离或倍率
    ;   g_dir            (sym|list)      - 方向
    ;   g_ratio          (t|nil)        - 倍率模式
    ;   g_corner         (sym)           - 拐角风格
    ;   g_miterLimit     (num|nil)       - miter 限制
    ;   g_roundSegments  (int|nil)       - 圆角段数
    ;
    ; **返回**
    ;   (Region) - 合并后的结果
    let((l_res)
        _SizeCheck(n_value g_dir g_ratio g_corner g_miterLimit g_roundSegments
            "ycGeom::Region->size")
        foreach(g_poly l_polys
            foreach(g_part _SizePolygon(g_poly n_value g_dir g_ratio
                    g_corner g_miterLimit g_roundSegments
                    "ycGeom::Region->size")->polygons()
                l_res = tconc(l_res g_part)
            )
        )
        Region(car(l_res))
    )
)

unuseNamespace("ycGeom")

; END
