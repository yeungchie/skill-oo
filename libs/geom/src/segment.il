useNamespace("ycGeom")

defclass(SegmentData () (
    ; SegmentData 数据桶：收纳线段起终点，构造后禁写。
    start(
        \@initarg start
        \@initform nil
    )
    end(
        \@initarg end
        \@initform nil
    )
))

defclass(Segment () (
    ; Segment 实例：不可变线段。
    ; 状态桶（SegmentData：start + end），构造后禁写
    _data(
        \@initarg _data
        \@initform nil
    )

    start()
    end()
    length()
    midpoint()
    direction()
    project()
    nearestPoint()
    distanceTo()
    contains()
    bBox()
    intersection()
    toLine()
    toSkill()
))

defmethod(printself (self(Segment))  ; -> str
    ; 返回 Segment 的打印描述串。
    ;
    ; **返回**
    ;   (str) - <ycGeom::Segment (x y)-(x y)>
    lsprintf("<%A (%A %A)-(%A %A)>" className(self)
        self->_data->start->x() self->_data->start->y()
        self->_data->end->x() self->_data->end->y())
)

procedure(_SegPointAt(g_a g_b n_t "ggn")  ; -> Point
    ; 返回线段参数 t 处的点。
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

procedure(_LineSegmentIntersection(g_line g_seg n_eps "ggg")  ; -> Point | Segment | nil
    ; 计算直线与线段交点。
    ;
    ; **参数**
    ;   g_line  (Line)  - 无限直线
    ;   g_seg   (Segment) - 线段
    ;   n_eps   (float) - 容差
    ;
    ; **返回**
    ;   (Point|Segment|nil) - 唯一交点、重叠线段或无交
    let((n_a n_b n_c g_s g_e n_dx n_dy n_x0 n_y0 n_den n_t)
        n_a = g_line->a()
        n_b = g_line->b()
        n_c = g_line->c()
        g_s = g_seg->start()
        g_e = g_seg->end()
        if(g_s->equals(g_e ?eps n_eps)
            when(g_line->contains(g_s ?eps n_eps) g_s)
            if(g_line->contains(g_s ?eps n_eps) && g_line->contains(g_e ?eps n_eps)
                g_seg
                if(g_line->contains(g_s ?eps n_eps)
                    g_s
                    if(g_line->contains(g_e ?eps n_eps)
                        g_e
                        progn(
                            n_dx = g_e->x() - g_s->x()
                            n_dy = g_e->y() - g_s->y()
                            n_den = n_a * n_dx + n_b * n_dy
                            if(abs(n_den) <= n_eps
                                nil
                                progn(
                                    n_x0 = g_s->x()
                                    n_y0 = g_s->y()
                                    n_t = -(n_a * n_x0 + n_b * n_y0 + n_c) / n_den
                                    if(n_t >= -n_eps && n_t <= 1.0 + n_eps
                                        _SegPointAt(g_s g_e n_t)
                                        nil
                                    )
                                )
                            )
                        )
                    )
                )
            )
        )
    )
)

procedure(_SegSegIntersection(g_a g_b g_c g_d n_eps "ggggg")  ; -> Point | Segment | nil
    ; 计算两条线段交点。
    ;
    ; **参数**
    ;   g_a    (Point) - 第一段起点
    ;   g_b    (Point) - 第一段终点
    ;   g_c    (Point) - 第二段起点
    ;   g_d    (Point) - 第二段终点
    ;   n_eps  (float) - 容差
    ;
    ; **返回**
    ;   (Point|Segment|nil) - 唯一交点、重叠线段或无交
    let((n_rx n_ry n_sx n_sy n_qx n_qy n_qpx n_qpy n_rxs n_qpxr
         n_rr n_t0 n_t1 n_min n_max n_t n_u)
        if(g_a->equals(g_b ?eps n_eps) && g_c->equals(g_d ?eps n_eps)
            when(g_a->equals(g_c ?eps n_eps) g_a)
            if(g_a->equals(g_b ?eps n_eps)
                when(_OnSegment(g_c g_d g_a n_eps) g_a)
                if(g_c->equals(g_d ?eps n_eps)
                    when(_OnSegment(g_a g_b g_c n_eps) g_c)
                    progn(
                    n_rx = g_b->x() - g_a->x()
        n_ry = g_b->y() - g_a->y()
        n_sx = g_d->x() - g_c->x()
        n_sy = g_d->y() - g_c->y()
        n_qpx = g_c->x() - g_a->x()
        n_qpy = g_c->y() - g_a->y()
        n_rxs = n_rx * n_sy - n_ry * n_sx
        n_qpxr = n_qpx * n_ry - n_qpy * n_rx
        n_rr = n_rx * n_rx + n_ry * n_ry
        if(abs(n_rxs) <= n_eps
            if(abs(n_qpxr) <= n_eps
                progn(
                    n_t0 = (n_qpx * n_rx + n_qpy * n_ry) / n_rr
                    n_t1 = ((g_d->x() - g_a->x()) * n_rx
                        + (g_d->y() - g_a->y()) * n_ry) / n_rr
                    n_min = min(n_t0 n_t1)
                    n_max = max(n_t0 n_t1)
                    if(n_max < -n_eps || n_min > 1.0 + n_eps
                        nil
                        progn(
                            n_min = max(n_min 0.0)
                            n_max = min(n_max 1.0)
                            if(_Near(n_min n_max n_eps)
                                _SegPointAt(g_a g_b n_min)
                                Segment(_SegPointAt(g_a g_b n_min)
                                    _SegPointAt(g_a g_b n_max))
                            )
                        )
                    )
                )
                nil
            )
            progn(
                n_t = (n_qpx * n_sy - n_qpy * n_sx) / n_rxs
                n_u = (n_qpx * n_ry - n_qpy * n_rx) / n_rxs
                if(n_t >= -n_eps && n_t <= 1.0 + n_eps
                    && n_u >= -n_eps && n_u <= 1.0 + n_eps
                    _SegPointAt(g_a g_b n_t)
                    nil
                )
            )
        )
                    )
                )
            )
        )
    )
)

inScheme(
procedure(_InstallSegment(self "g")  ; -> t
    ; 把 Segment 方法安装到 Segment 类（由 initializeInstance 调用）。
    ;
    ; **返回**
    ;   (t) - 安装完成；调用方忽略
    self->start = lambda(()  ; -> Point
        ; 返回起点。
        ;
        ; **返回**
        ;   (Point) - 起点引用
        self->_data->start
    )
    self->end = lambda(()  ; -> Point
        ; 返回终点。
        ;
        ; **返回**
        ;   (Point) - 终点引用
        self->_data->end
    )
    self->length = lambda(()  ; -> float
        ; 返回长度。
        ;
        ; **返回**
        ;   (float) - 欧氏长度
        let((n_dx n_dy)
            n_dx = self->_data->end->x() - self->_data->start->x()
            n_dy = self->_data->end->y() - self->_data->start->y()
            sqrt(n_dx * n_dx + n_dy * n_dy)
        )
    )
    self->midpoint = lambda(()  ; -> Point
        ; 返回中点。
        ;
        ; **返回**
        ;   (Point) - 中点
        self->_data->start->midpoint(self->_data->end)
    )
    self->direction = lambda(()  ; -> list[float] | nil
        ; 返回单位方向向量。
        ;
        ; **返回**
        ;   (list[float]|nil) - 单位方向；零长度为 nil
        let((n_dx n_dy n_len)
            n_dx = self->_data->end->x() - self->_data->start->x()
            n_dy = self->_data->end->y() - self->_data->start->y()
            n_len = sqrt(n_dx * n_dx + n_dy * n_dy)
            unless(n_len <= 1e-9
                list(n_dx / n_len n_dy / n_len)
            )
        )
    )
    self->project = lambda((g_point "g")  ; -> Point | nil
        ; 返回线段上的正交投影点。
        ;
        ; **参数**
        ;   g_point  (Point) - 待投影点
        ;
        ; **返回**
        ;   (Point|nil) - 垂足落在线段内为投影点，落在线段外为 nil；零长度返回起点
        let((g_p n_dx n_dy n_den n_t)
            g_p = _AsPoint(g_point "ycGeom::Segment->project")
            n_dx = self->_data->end->x() - self->_data->start->x()
            n_dy = self->_data->end->y() - self->_data->start->y()
            n_den = n_dx * n_dx + n_dy * n_dy
            if(n_den <= 1e-18
                self->_data->start
                progn(
                    n_t = ((g_p->x() - self->_data->start->x()) * n_dx
                        + (g_p->y() - self->_data->start->y()) * n_dy) / n_den
                    when(n_t >= 0.0 && n_t <= 1.0
                        _SegPointAt(self->_data->start self->_data->end n_t)
                    )
                )
            )
        )
    )
    self->nearestPoint = lambda((g_point "g")  ; -> Point
        ; 返回线段上的最近点。
        ;
        ; **参数**
        ;   g_point  (Point) - 查询点
        ;
        ; **返回**
        ;   (Point) - 线段上的最近点；零长度返回起点
        let((g_p n_dx n_dy n_den n_t)
            g_p = _AsPoint(g_point "ycGeom::Segment->nearestPoint")
            n_dx = self->_data->end->x() - self->_data->start->x()
            n_dy = self->_data->end->y() - self->_data->start->y()
            n_den = n_dx * n_dx + n_dy * n_dy
            if(n_den <= 1e-18
                self->_data->start
                progn(
                    n_t = ((g_p->x() - self->_data->start->x()) * n_dx
                        + (g_p->y() - self->_data->start->y()) * n_dy) / n_den
                    n_t = if(n_t < 0.0 0.0 if(n_t > 1.0 1.0 n_t))
                    _SegPointAt(self->_data->start self->_data->end n_t)
                )
            )
        )
    )
    self->distanceTo = lambda((g_point "g")  ; -> float
        ; 返回到线段的距离。
        ;
        ; **参数**
        ;   g_point  (Point) - 查询点
        ;
        ; **返回**
        ;   (float) - 最近距离
        let((g_p)
            g_p = _AsPoint(g_point "ycGeom::Segment->distanceTo")
            g_p->distanceTo(self->nearestPoint(g_p))
        )
    )
    self->contains = lambda((g_point \@key (eps nil) "gg")  ; -> t | nil
        ; 判断点是否在线段上。
        ;
        ; **参数**
        ;   g_point  (Point)   - 查询点
        ;   ?eps     (num|nil) - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (t|nil) - 在线段上为 t
        let((g_p n_eps)
            g_p = _AsPoint(g_point "ycGeom::Segment->contains")
            n_eps = _Eps(eps)
            _OnSegment(self->_data->start self->_data->end g_p n_eps)
        )
    )
    self->bBox = lambda(()  ; -> list[list[float]]
        ; 返回包围盒。
        ;
        ; **返回**
        ;   (list[list[float]]) - ((xmin ymin) (xmax ymax))
        list(
            list(
                min(self->_data->start->x() self->_data->end->x())
                min(self->_data->start->y() self->_data->end->y())
            )
            list(
                max(self->_data->start->x() self->_data->end->x())
                max(self->_data->start->y() self->_data->end->y())
            )
        )
    )
    self->intersection = lambda((g_other \@key (eps nil) "gg")  ; -> Point | Segment | nil
        ; 计算与 Line 或 Segment 的交点。
        ;
        ; **参数**
        ;   g_other  (Line|Segment) - 另一对象
        ;   ?eps     (num|nil)      - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (Point|Segment|nil) - 唯一交点、重叠线段或无交
        let((n_eps)
            n_eps = _Eps(eps)
            cond(
                (_LineP(g_other)
                    _LineSegmentIntersection(g_other self n_eps))
                (_SegmentP(g_other)
                    _SegSegIntersection(self->_data->start self->_data->end
                        g_other->start() g_other->end() n_eps))
                (t
                    error("ycGeom::Segment->intersection: expected a Line or Segment, got %A"
                        g_other))
            )
        )
    )
    self->toLine = lambda(()  ; -> Line | nil
        ; 返回对应的无限直线。
        ;
        ; **返回**
        ;   (Line|nil) - 经过起终点的无限直线；零长度线段为 nil
        unless(self->_data->start->equals(self->_data->end)
            Line(self->_data->start self->_data->end)
        )
    )
    self->toSkill = lambda(()  ; -> list[list[float]]
        ; 转换为纯坐标列表。
        ;
        ; **返回**
        ;   (list[list[float]]) - ((sx sy) (ex ey))
        list(self->_data->start->toSkill() self->_data->end->toSkill())
    )
    t
)
)

inScheme(
defmethod(initializeInstance (self(Segment) \@rest _args)
    ; 构造 Segment 实例时安装方法集。
    ;
    ; **参数**
    ;   _args  (list) - 附加初始化参数，本实现忽略
    ;
    ; **返回**
    ;   (t) - 安装完成
    _InstallSegment(self)
    t
)
)

procedure(Segment(\@rest l_args "g")  ; -> Segment
    ; 构造不可变线段。
    ;
    ; **参数**
    ;   l_args  (list) - 两个点、两点列表、四个坐标，或点列
    ;
    ; **返回**
    ;   (Segment) - 新线段；零长度合法；格式不合法 error
    let((l_pts)
        l_pts = _TwoPoints(l_args "ycGeom::Segment")
        makeInstance('Segment ?_data
            makeInstance('SegmentData
                ?start _Nth1(1 l_pts)
                ?end _Nth1(2 l_pts)))
    )
)

unuseNamespace("ycGeom")

; END
