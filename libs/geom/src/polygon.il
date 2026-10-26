useNamespace("ycGeom")

; Keyhole ring layout:
;
;   +------------------+
;   |   +----------+   |
;   |   |   hole   |   |
;   |   +----------+   |
;   +--------+---------+
;            |
;      seam traversed twice
;
; The seam is an internal bridge, not part of the polygon boundary.

defclass(PolygonData () (
    ; PolygonData 数据桶：只收纳 keyhole 点列，构造后禁写。
    points(
        \@initarg points
        \@initform nil
    )
))

defclass(Polygon () (
    ; Polygon 实例：不可变 keyhole 多边形。
    ; 状态桶（PolygonData：points），构造后禁写
    _data(
        \@initarg _data
        \@initform nil
    )

    points()
    edges()
    area()
    perimeter()
    centroid()
    contains()
    onBoundary()
    bBox()
    toRect()
    isClockwise()
    reverse()
    removeCollinear()
    size()
    or()
    and()
    not()
    xor()
    toSkill()
))
procedure(_CheckPolygon(l_points n_eps "ln")  ; -> t
    ; 校验点列可构成 keyhole 多边形。
    ;
    ; **参数**
    ;   l_points  (list[Point]) - 候选点列
    ;   n_eps     (float)       - 容差
    ;
    ; **返回**
    ;   (t) - 合法；否则 error
    let((n_len n_i n_j g_a g_b g_c g_d t_seams g_prev)
        unless(listp(l_points)
            error("ycGeom::Polygon: expected a list of Points, got %A" l_points)
        )
        n_len = length(l_points)
        unless(n_len >= 3
            error("ycGeom::Polygon: at least 3 points are required")
        )
        for(n_i 1 n_len
            unless(_PointP(_Nth1(n_i l_points))
                error("ycGeom::Polygon: element %d is not a Point: %A" n_i _Nth1(n_i l_points))
            )
            g_prev = _Nth1(if(n_i == 1 n_len (n_i - 1)) l_points)
            when(_Near(g_prev->x() _Nth1(n_i l_points)->x() n_eps)
                && _Near(g_prev->y() _Nth1(n_i l_points)->y() n_eps)
                error("ycGeom::Polygon: consecutive duplicate point at index %d" n_i)
            )
        )
        when(abs(_SignedArea(l_points)) <= _AreaTol(l_points n_eps)
            error("ycGeom::Polygon: zero-area point sequence")
        )
        t_seams = _SeamKeys(l_points)
        for(n_i 1 n_len
            g_a = _Nth1(n_i l_points)
            g_b = _Nth1(if(n_i == n_len 1 (n_i + 1)) l_points)
            when(t_seams[_EdgeKey(g_a g_b)] == 2
                unless(_Near(g_a->x() g_b->x() n_eps)
                    || _Near(g_a->y() g_b->y() n_eps)
                    error("ycGeom::Polygon: seam must be horizontal or vertical")
                )
            )
            unless(t_seams[_EdgeKey(g_a g_b)] == 2
                for(n_j 1 n_len
                    when(n_j > n_i
                        let((g_c g_d)
                            g_c = _Nth1(n_j l_points)
                            g_d = _Nth1(if(n_j == n_len 1 (n_j + 1)) l_points)
                            unless(t_seams[_EdgeKey(g_c g_d)] == 2
                                unless(_SamePoint(g_a g_c n_eps)
                                    || _SamePoint(g_a g_d n_eps)
                                    || _SamePoint(g_b g_c n_eps)
                                    || _SamePoint(g_b g_d n_eps)
                                    when(_SegmentsCross(g_a g_b g_c g_d n_eps)
                                        error("ycGeom::Polygon: non-seam edges intersect")
                                    )
                                )
                            )
                        )
                    )
                )
            )
        )
        t
    )
)
defmethod(printself (self(Polygon))  ; -> str
    ; 返回 Polygon 的打印描述串。
    ;
    ; **返回**
    ;   (str) - <ycGeom::Polygon points=N area=...>
    lsprintf("<%A points=%d area=%A>" className(self)
        length(self->_data->points) abs(_SignedArea(self->_data->points)))
)

procedure(_ShapeOp(g_left g_other g_op n_grid n_eps t_ctx "gggggt")  ; -> Region
    ; 对任意二维图形执行布尔运算并返回 Region（内部实现）。
    ;
    ; **参数**
    ;   g_left   (any)       - 左操作数：Polygon/Rect/Region/点列
    ;   g_other  (any)       - 右操作数：Polygon/Rect/Region/点列
    ;   g_op     (sym)       - union/intersection/difference/xor
    ;   n_grid   (float|nil) - 网格
    ;   n_eps    (float|nil) - 容差
    ;   t_ctx    (str)       - 错误上下文
    ;
    ; **返回**
    ;   (Region) - 结果区域
    let((g_l g_r l_res)
        g_l = _AsRegion(g_left t_ctx)
        g_r = _AsRegion(g_other t_ctx)
        l_res = _Boolean(g_l->polygons() g_r->polygons()
            g_op n_grid n_eps)
        Region(_CleanPolygons(l_res _Eps(n_eps)) ?normalize nil)
    )
)

inScheme(
procedure(_InstallPolygon(self "g")  ; -> t
    ; 把 Polygon 方法安装到 Polygon 类（由 initializeInstance 调用）。
    ;
    ; **返回**
    ;   (t) - 安装完成；调用方忽略
    self->points = lambda(()  ; -> list[Point]
        ; 返回内部 keyhole 点列。
        ;
        ; **返回**
        ;   (list[Point]) - 内部点列，不得原地修改
        self->_data->points
    )
    self->edges = lambda(()  ; -> list[Segment]
        ; 返回相邻点形成的全部边，含切割边。
        ;
        ; **返回**
        ;   (list[Segment]) - 边列表
        let((l_res n_len n_i)
            n_len = length(self->_data->points)
            for(n_i 1 n_len
                l_res = tconc(l_res Segment(
                    _Nth1(n_i self->_data->points)
                    _Nth1(if(n_i == n_len 1 (n_i + 1)) self->_data->points)
                ))
            )
            car(l_res)
        )
    )
    self->area = lambda(()  ; -> float
        ; 返回面积。
        ;
        ; **返回**
        ;   (float) - 绝对面积
        abs(_SignedArea(self->_data->points))
    )
    self->perimeter = lambda((\@key (includeSeams nil) (eps nil) "gg")  ; -> float
        ; 返回周长；默认排除切割线。
        ;
        ; **参数**
        ;   ?includeSeams  (t|nil)   - 是否把切割线计入；默认 nil
        ;   ?eps           (num|nil) - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (float) - 周长
        let((n_eps n_len n_i g_a g_b t_seams n_sum n_seam)
            _Flag(includeSeams "includeSeams")
            n_eps = _Eps(eps)
            t_seams = _SeamKeys(self->_data->points)
            n_len = length(self->_data->points)
            n_sum = 0.0
            for(n_i 1 n_len
                g_a = _Nth1(n_i self->_data->points)
                g_b = _Nth1(if(n_i == n_len 1 (n_i + 1)) self->_data->points)
                n_seam = t_seams[_EdgeKey(g_a g_b)] == 2
                unless(n_seam && !includeSeams
                    n_sum = n_sum + Segment(g_a g_b)->length()
                )
            )
            n_sum
        )
    )
    self->centroid = lambda(()  ; -> Point
        ; 返回面积加权质心。
        ;
        ; **返回**
        ;   (Point) - 质心；零面积 error
        let((n_len n_i g_a g_b n_cross n_a n_cx n_cy n_ox n_oy)
            n_len = length(self->_data->points)
            n_a = 0.0
            n_cx = 0.0
            n_cy = 0.0
            n_ox = car(self->_data->points)->x()
            n_oy = car(self->_data->points)->y()
            for(n_i 1 n_len
                g_a = _Nth1(n_i self->_data->points)
                g_b = _Nth1(if(n_i == n_len 1 (n_i + 1)) self->_data->points)
                n_cross = (g_a->x() - n_ox) * (g_b->y() - n_oy)
                    - (g_b->x() - n_ox) * (g_a->y() - n_oy)
                n_a = n_a + n_cross
                n_cx = n_cx
                    + ((g_a->x() - n_ox) + (g_b->x() - n_ox)) * n_cross
                n_cy = n_cy
                    + ((g_a->y() - n_oy) + (g_b->y() - n_oy)) * n_cross
            )
            n_a = n_a / 2.0
            when(abs(n_a) <= _AreaTol(self->_data->points _Eps(nil))
                error("ycGeom::Polygon->centroid: zero-area polygon")
            )
            Point(n_ox + n_cx / (6.0 * n_a)
                n_oy + n_cy / (6.0 * n_a))
        )
    )
    self->contains = lambda((g_point \@key (boundary "inside") (eps nil) "ggg")  ; -> t | nil
        ; 判断点是否在多边形内。
        ;
        ; **参数**
        ;   g_point   (Point)       - 查询点
        ;   ?boundary (str)         - "inside" 或 "outside"；默认 "inside"
        ;   ?eps      (num|nil)     - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (t|nil) - 在内部或按选项在边界上为 t
        let((g_p n_eps n_len n_i g_a g_b t_seams g_boundary)
            g_p = _AsPoint(g_point "ycGeom::Polygon->contains")
            _BoundaryMode(boundary)
            n_eps = _Eps(eps)
            t_seams = _SeamKeys(self->_data->points)
            n_len = length(self->_data->points)
            for(n_i 1 n_len
                g_a = _Nth1(n_i self->_data->points)
                g_b = _Nth1(if(n_i == n_len 1 (n_i + 1)) self->_data->points)
                unless(t_seams[_EdgeKey(g_a g_b)] == 2
                    when(_OnSegment(g_a g_b g_p n_eps)
                        g_boundary = t
                    )
                )
            )
            if(g_boundary
                boundary == "inside"
                _PointInRing(self->_data->points g_p n_eps)
            )
        )
    )
    self->onBoundary = lambda((g_point \@key (includeSeams nil) (eps nil) "ggg")  ; -> t | nil
        ; 判断点是否在边界上。
        ;
        ; **参数**
        ;   g_point        (Point)   - 查询点
        ;   ?includeSeams  (t|nil)   - 是否把切割线视为边界；默认 nil
        ;   ?eps           (num|nil) - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (t|nil) - 在边界上为 t
        let((g_p n_eps t_seams n_len n_i g_a g_b g_found)
            g_p = _AsPoint(g_point "ycGeom::Polygon->onBoundary")
            _Flag(includeSeams "includeSeams")
            n_eps = _Eps(eps)
            t_seams = _SeamKeys(self->_data->points)
            n_len = length(self->_data->points)
            for(n_i 1 n_len
                when(!g_found
                    g_a = _Nth1(n_i self->_data->points)
                    g_b = _Nth1(if(n_i == n_len 1 (n_i + 1)) self->_data->points)
                    unless(t_seams[_EdgeKey(g_a g_b)] == 2 && !includeSeams
                        when(_OnSegment(g_a g_b g_p n_eps)
                            g_found = t
                        )
                    )
                )
            )
            g_found
        )
    )
    self->bBox = lambda(()  ; -> list[list[float]]
        ; 返回包围盒。
        ;
        ; **返回**
        ;   (list[list[float]]) - ((xmin ymin) (xmax ymax))
        let((n_xmin n_ymin n_xmax n_ymax n_i g_p)
            n_xmin = _Nth1(1 self->_data->points)->x()
            n_ymin = _Nth1(1 self->_data->points)->y()
            n_xmax = n_xmin
            n_ymax = n_ymin
            for(n_i 2 length(self->_data->points)
                g_p = _Nth1(n_i self->_data->points)
                n_xmin = min(n_xmin g_p->x())
                n_ymin = min(n_ymin g_p->y())
                n_xmax = max(n_xmax g_p->x())
                n_ymax = max(n_ymax g_p->y())
            )
            list(list(n_xmin n_ymin) list(n_xmax n_ymax))
        )
    )
    self->toRect = lambda(()  ; -> Rect
        ; 返回包围矩形。
        ;
        ; **返回**
        ;   (Rect) - 由 bBox 构造的轴对齐矩形
        Rect(self->bBox())
    )
    self->isClockwise = lambda((\@key (eps nil) "g")  ; -> t | nil
        ; 判断点列绕行方向。
        ;
        ; **参数**
        ;   ?eps  (num|nil) - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (t|nil) - 顺时针为 t
        let((n_eps)
            n_eps = _Eps(eps)
            _SignedArea(self->_data->points) < -_AreaTol(self->_data->points n_eps)
        )
    )
    self->reverse = lambda(()  ; -> Polygon
        ; 返回反向绕行的新多边形。
        ;
        ; **返回**
        ;   (Polygon) - 新对象
        Polygon(reverse(copy(self->_data->points)))
    )
    self->removeCollinear = lambda((\@key (eps nil) "g")  ; -> Polygon
        ; 返回去除共线中间点后的新多边形。
        ;
        ; **参数**
        ;   ?eps  (num|nil) - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (Polygon) - 新对象；切割边端点保留
        Polygon(_CollinearClean(self->_data->points _Eps(eps)))
    )
    self->size = lambda((n_value \@key (dir 'all) (ratio nil) (corner 'miter) (miterLimit nil) (roundSegments nil) "nggggg")  ; -> Region
        ; 返回方向 offset 后的 Region。
        ;
        ; **参数**
        ;   n_value         (num)      - 距离或倍率
        ;   ?dir            (sym|list) - 方向；默认 'all
        ;   ?ratio          (t|nil)    - 倍率模式；默认 nil
        ;   ?corner         (sym)      - 拐角风格；默认 'miter
        ;   ?miterLimit     (num|nil)  - miter 限制；默认 nil（4.0）
        ;   ?roundSegments  (int|nil)  - 圆角段数；默认 nil（8）
        ;
        ; **返回**
        ;   (Region) - 结果区域
        _SizePolygon(self n_value dir ratio corner miterLimit roundSegments
            "ycGeom::Polygon->size")
    )
    self->or = lambda((g_other \@key (grid nil) (eps nil) "ggg")  ; -> Region
        ; 返回并集。
        ;
        ; **参数**
        ;   g_other  (Polygon|Rect|Region|list) - 另一二维图形或点列
        ;   ?grid    (num|nil)   - 网格；默认 nil
        ;   ?eps     (num|nil)   - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (Region) - 并集区域
        _ShapeOp(self g_other 'union grid eps "ycGeom::Polygon->or")
    )
    self->and = lambda((g_other \@key (grid nil) (eps nil) "ggg")  ; -> Region
        ; 返回交集。
        ;
        ; **参数**
        ;   g_other  (Polygon|Rect|Region|list) - 另一二维图形或点列
        ;   ?grid    (num|nil)   - 网格；默认 nil
        ;   ?eps     (num|nil)   - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (Region) - 交集区域
        _ShapeOp(self g_other 'intersection grid eps "ycGeom::Polygon->and")
    )
    self->not = lambda((g_other \@key (grid nil) (eps nil) "ggg")  ; -> Region
        ; 返回二元差集。
        ;
        ; **参数**
        ;   g_other  (Polygon|Rect|Region|list) - 另一二维图形或点列
        ;   ?grid    (num|nil)   - 网格；默认 nil
        ;   ?eps     (num|nil)   - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (Region) - A-B 区域
        _ShapeOp(self g_other 'difference grid eps "ycGeom::Polygon->not")
    )
    self->xor = lambda((g_other \@key (grid nil) (eps nil) "ggg")  ; -> Region
        ; 返回对称差。
        ;
        ; **参数**
        ;   g_other  (Polygon|Rect|Region|list) - 另一二维图形或点列
        ;   ?grid    (num|nil)   - 网格；默认 nil
        ;   ?eps     (num|nil)   - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (Region) - 对称差区域
        _ShapeOp(self g_other 'xor grid eps "ycGeom::Polygon->xor")
    )
    self->toSkill = lambda(()  ; -> list[list[float]]
        ; 转换为纯坐标点列。
        ;
        ; **返回**
        ;   (list[list[float]]) - ((x1 y1) ...)
        let((l_res)
            foreach(g_p self->_data->points
                l_res = tconc(l_res g_p->toSkill())
            )
            car(l_res)
        )
    )
    t
)
)

inScheme(
defmethod(initializeInstance (self(Polygon) \@rest _args)
    ; 构造 Polygon 实例时安装方法集。
    ;
    ; **参数**
    ;   _args  (list) - 附加初始化参数，本实现忽略
    ;
    ; **返回**
    ;   (t) - 安装完成
    _InstallPolygon(self)
    t
)
)
procedure(Polygon(l_points "l")  ; -> Polygon
    ; 构造不可变 keyhole 多边形。
    ;
    ; **参数**
    ;   l_points  (list) - Point 列表、(x y) 列表或扁平数值坐标
    ;
    ; **返回**
    ;   (Polygon) - 复制外层点列的新多边形；非法点列 error
    let((l_pts)
        l_pts = _AsPointList(l_points "ycGeom::Polygon")
        _CheckPolygon(l_pts _Eps(nil))
        makeInstance('Polygon ?_data
            makeInstance('PolygonData ?points copy(l_pts)))
    )
)

unuseNamespace("ycGeom")

; END
