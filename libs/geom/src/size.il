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
    let((res)
        cond(
            (g_dir == 'all list('left 'right 'up 'down))
            (_SizeDirP(g_dir) list(g_dir))
            (listp(g_dir)
                unless(g_dir
                    error("ycGeom: ?dir must not be an empty list")
                )
                foreach(item g_dir
                    unless(_SizeDirP(item)
                        error("ycGeom: invalid ?dir element %A" item)
                    )
                )
                when(member('all g_dir) && length(g_dir) > 1
                    error("ycGeom: ?dir 'all cannot be combined with other directions")
                )
                foreach(item g_dir
                    unless(member(item res)
                        res = tconc(res item)
                    )
                )
                car(res)
            )
            (t error("ycGeom: ?dir must be a direction or list, got %A" g_dir))
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
        error("ycGeom: ?corner must be miter, round, bevel, or none, got %A"
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
        (t error("ycGeom: ?miterLimit must be a positive number, got %A"
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
        (t error("ycGeom: ?roundSegments must be a positive integer, got %A"
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
    let((dirs ratioMode)
        unless(numberp(n_value)
            error("%s: value must be a number, got %A" t_ctx n_value)
        )
        dirs = _SizeDirs(g_dir)
        ratioMode = _Flag(g_ratio "ratio")
        _SizeCorner(g_corner)
        _SizeMiterLimit(g_limit)
        _SizeRoundSegments(g_segments)
        when(ratioMode && n_value <= 0.0
            error("%s: ratio value must be positive, got %A" t_ctx n_value)
        )
        list(dirs ratioMode)
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
    let((max infos res)
        foreach(ring l_rings
            let((area)
                ring = _CollinearClean(ring _Eps(nil))
                area = abs(_SignedArea(ring))
                infos = tconc(infos list(ring area))
                when(max == nil || area > max
                    max = area
                )
            )
        )
        infos = car(infos)
        foreach(info infos
            let((ring area)
                ring = car(info)
                area = cadr(info)
                if(area == max
                    when(_SignedArea(ring) < 0.0
                        ring = reverse(ring)
                    )
                    when(_SignedArea(ring) > 0.0
                        ring = reverse(ring)
                    )
                )
                res = tconc(res ring)
            )
        )
        car(res)
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
    let((res len i a b dx dy lenr)
        len = length(l_ring)
        for(i2 1 len
            a = _Nth1(i2 l_ring)
            b = _Nth1(if(i2 == len 1 (i2 + 1)) l_ring)
            dx = b->x() - a->x()
            dy = b->y() - a->y()
            lenr = sqrt(dx * dx + dy * dy)
            unless(lenr <= _Eps(nil)
                res = tconc(res list(a b
                    dy / lenr (-dx) / lenr))
            )
        )
        car(res)
    )
)

procedure(_SizeEdgeSelected(n_nx n_ny l_dirs n_eps "nnln")  ; -> t | nil
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
        let((halfx halfy)
            halfx = if(member('left l_dirs) && member('right l_dirs)
                0.5 1.0)
            halfy = if(member('up l_dirs) && member('down l_dirs)
                0.5 1.0)
            (float(n_value) - 1.0)
                * (abs(n_nx) * n_width * halfx
                    + abs(n_ny) * n_height * halfy)
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
    let((ux uy vx vy det value)
        ux = car(g_u)
        uy = cadr(g_u)
        vx = car(g_v)
        vy = cadr(g_v)
        det = ux * vy - uy * vx
        unless(abs(det) <= _AngleTol()
            value = ((g_q->x() - g_p->x()) * vy
                - (g_q->y() - g_p->y()) * vx) / det
            Point(list(g_p->x() + ux * value
                g_p->y() + uy * value))
        )
    )
)

procedure(_SizeStrip(g_a g_b n_nx n_ny n_d "ggnnn")  ; -> Polygon | nil
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
    let((a1 a2 delta steps rad i res)
        a1 = atan2(g_v1->y() - g_v->y() g_v1->x() - g_v->x())
        a2 = atan2(g_v2->y() - g_v->y() g_v2->x() - g_v->x())
        delta = a2 - a1
        while(delta > 3.141592653589793
            delta = delta - 6.283185307179586
        )
        while(delta < -3.141592653589793
            delta = delta + 6.283185307179586
        )
        when(abs(delta) <= _AngleTol()
            nil
        )
        steps = int(abs(delta) / 1.570796326794897 * n_segments)
        when(steps < 1 steps = 1)
        rad = max(abs(n_d1) abs(n_d2))
        res = tconc(res g_v1)
        for(i2 1 steps - 1
            res = tconc(res Point(list(
                g_v->x() + rad * cos(a1 + delta * i2 / steps)
                g_v->y() + rad * sin(a1 + delta * i2 / steps)
            )))
        )
        res = tconc(res g_v2)
        res = tconc(res g_v)
        Polygon(car(res))
    )
)

procedure(_SizeCapSelected(g_v g_pa g_nb l_e1 l_e2 n_limit n_segments s_corner "gggllnxs")  ; -> Polygon | nil
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
    ;   s_corner    (sym)   - 拐角风格
    ;
    ; **返回**
    ;   (Polygon|nil) - 拐角帽
    let((nx1 ny1 d1 nx2 ny2 d2 v1 v2 m)
        nx1 = _Nth1(3 l_e1)
        ny1 = _Nth1(4 l_e1)
        d1 = _Nth1(6 l_e1)
        nx2 = _Nth1(3 l_e2)
        ny2 = _Nth1(4 l_e2)
        d2 = _Nth1(6 l_e2)
        v1 = Point(list(g_v->x() + nx1 * d1
            g_v->y() + ny1 * d1))
        v2 = Point(list(g_v->x() + nx2 * d2
            g_v->y() + ny2 * d2))
        cond(
            (s_corner == 'none nil)
            (s_corner == 'bevel Polygon(list(v1 g_v v2)))
            (s_corner == 'round
                _SizeRoundCap(g_v v1 v2 d1 d2 n_segments))
            (s_corner == 'miter
                m = _SizeLinePoint(v1
                    list(g_v->x() - g_pa->x() g_v->y() - g_pa->y())
                    v2
                    list(g_nb->x() - g_v->x() g_nb->y() - g_v->y()))
                if(m && g_v->distanceTo(m)
                        <= n_limit * max(abs(d1) abs(d2))
                    Polygon(list(v1 m v2 g_v))
                    Polygon(list(v1 g_v v2))
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
    let((sel1 sel2 nx1 ny1 d1 nx2 ny2 d2 v1 v2 q cap)
        unless(g_corner == 'none
            sel1 = _Nth1(5 l_e1)
            sel2 = _Nth1(5 l_e2)
            nx1 = _Nth1(3 l_e1)
            ny1 = _Nth1(4 l_e1)
            d1 = _Nth1(6 l_e1)
            nx2 = _Nth1(3 l_e2)
            ny2 = _Nth1(4 l_e2)
            d2 = _Nth1(6 l_e2)
            when(sel1 && !sel2
                progn(
                    v1 = Point(list(g_v->x() + nx1 * d1
                        g_v->y() + ny1 * d1))
                    q = _SizeLinePoint(v1
                        list(g_v->x() - g_pa->x() g_v->y() - g_pa->y())
                        g_v
                        list(g_nb->x() - g_v->x() g_nb->y() - g_v->y()))
                    when(q && !q->equals(v1 ?eps _Eps(nil))
                        && !q->equals(g_v ?eps _Eps(nil))
                        cap = Polygon(list(v1 q g_v))
                    )
                )
            )
            when(!sel1 && sel2
                progn(
                    v2 = Point(list(g_v->x() + nx2 * d2
                        g_v->y() + ny2 * d2))
                    q = _SizeLinePoint(g_v
                        list(g_v->x() - g_pa->x() g_v->y() - g_pa->y())
                        v2
                        list(g_nb->x() - g_v->x() g_nb->y() - g_v->y()))
                    when(q && !q->equals(v2 ?eps _Eps(nil))
                        && !q->equals(g_v ?eps _Eps(nil))
                        cap = Polygon(list(g_v q v2))
                    )
                )
            )
            cap
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
    let((check dirs ratioMode box width height limit segments
         ops region rings enh src)
        check = _SizeCheck(n_value g_dir g_ratio g_corner g_miterLimit
            g_roundSegments t_ctx)
        dirs = car(check)
        ratioMode = cadr(check)
        src = self->removeCollinear()
        box = src->bBox()
        width = car(cadr(box)) - car(car(box))
        height = cadr(cadr(box)) - cadr(car(box))
        limit = _SizeMiterLimit(g_miterLimit)
        segments = _SizeRoundSegments(g_roundSegments)
        region = Region(list(src) ?normalize nil)
        unless((_Near(n_value 0.0 _Eps(nil))
                || (ratioMode && _Near(n_value 1.0 _Eps(nil))))
            progn(
            rings = _SizeOrientRings(_Rings(src->points()))
            foreach(ring rings
                let((recs len i e sel d a b nx ny)
                    recs = _SizeRingEdges(ring)
                    enh = nil
                    foreach(e2 recs
                        a = _Nth1(1 e2)
                        b = _Nth1(2 e2)
                        nx = _Nth1(3 e2)
                        ny = _Nth1(4 e2)
                        sel = _SizeEdgeSelected(nx ny dirs _Eps(nil))
                        d = _SizeEdgeDistance(nx ny width height
                            dirs n_value ratioMode)
                        enh = tconc(enh list(a b nx ny sel d))
                        when(sel
                            ops = tconc(ops
                                _SizeStrip(a b nx ny d))
                        )
                    )
                    enh = car(enh)
                    len = length(enh)
                    for(i2 1 len
                        let((e1 e2 v cap)
                            e1 = _Nth1(i2 enh)
                            e2 = _Nth1(if(i2 == len 1 (i2 + 1)) enh)
                            v = _Nth1(2 e1)
                            when(_Nth1(5 e1) && _Nth1(5 e2)
                                progn(
                                    cap = _SizeCapSelected(v _Nth1(1 e1)
                                        _Nth1(2 e2) e1 e2 limit
                                        segments g_corner)
                                    when(cap
                                        ops = tconc(ops cap)
                                    )
                                )
                            )
                            unless(_Nth1(5 e1) == _Nth1(5 e2)
                                progn(
                                    cap = _SizeExtendCap(v _Nth1(1 e1)
                                        _Nth1(2 e2) e1 e2 g_corner)
                                    when(cap
                                        ops = tconc(ops cap)
                                    )
                                )
                            )
                        )
                    )
                )
            )
            foreach(op car(ops)
                when(op
                    region = Region(_Boolean(
                        region->polygons() list(op)
                        if(if(ratioMode n_value > 1.0 n_value > 0.0)
                            'union 'difference)
                        nil _Eps(nil))
                        ?normalize nil)
                )
            )
            )
        )
        Region(_CleanPolygons(region->polygons() _Eps(nil)) ?normalize nil)
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
    let((res)
        _SizeCheck(n_value g_dir g_ratio g_corner g_miterLimit g_roundSegments
            "ycGeom::Region->size")
        foreach(poly l_polys
            foreach(part _SizePolygon(poly n_value g_dir g_ratio
                    g_corner g_miterLimit g_roundSegments
                    "ycGeom::Region->size")->polygons()
                res = tconc(res part)
            )
        )
        Region(car(res))
    )
)

unuseNamespace("ycGeom")

; END
