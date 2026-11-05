useNamespace("ycGeom")

defclass(_SegmentData () (
    ; _SegmentData 数据桶：收纳线段起终点，构造后禁写。
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
    ; 状态桶（_SegmentData：start + end），构造后禁写
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
    toRect()
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
    Point(list(g_a->x() + (g_b->x() - g_a->x()) * n_t
        g_a->y() + (g_b->y() - g_a->y()) * n_t))
)

procedure(_LineSegmentIntersection(g_line g_seg n_eps "ggn")  ; -> Point | Segment | nil
    ; 计算直线与线段交点。
    ;
    ; **参数**
    ;   g_line  (Line)  - 无限直线
    ;   g_seg   (Segment) - 线段
    ;   n_eps   (float) - 容差
    ;
    ; **返回**
    ;   (Point|Segment|nil) - 唯一交点、重叠线段或无交
    let((a b c s e dx dy x0 y0 den value len tol)
        a = g_line->a()
        b = g_line->b()
        c = g_line->c()
        s = g_seg->start()
        e = g_seg->end()
        cond(
            (s->equals(e ?eps n_eps)
                when(g_line->contains(s ?eps n_eps) s)
            )
            (g_line->contains(s ?eps n_eps)
                && g_line->contains(e ?eps n_eps)
                g_seg
            )
            (g_line->contains(s ?eps n_eps) s)
            (g_line->contains(e ?eps n_eps) e)
            (t
                dx = e->x() - s->x()
                dy = e->y() - s->y()
                len = sqrt(dx * dx + dy * dy)
                den = a * dx + b * dy
                unless(abs(den) <= n_eps
                    x0 = s->x()
                    y0 = s->y()
                    value = -(a * x0 + b * y0 + c) / den
                    tol = n_eps / len
                    when(value >= -tol && value <= 1.0 + tol
                        _SegPointAt(s e value)
                    )
                )
            )
        )
    )
)

procedure(_SegSegIntersection(g_a g_b g_c g_d n_eps "ggggn")  ; -> Point | Segment | nil
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
    let((rx ry sx sy qx qy qpx qpy rxs qpxr
         rr lenr lens tolr tols t0 t1 min max value u)
        cond(
            (g_a->equals(g_b ?eps n_eps) && g_c->equals(g_d ?eps n_eps)
                when(g_a->equals(g_c ?eps n_eps) g_a)
            )
            (g_a->equals(g_b ?eps n_eps)
                when(_OnSegment(g_c g_d g_a n_eps) g_a)
            )
            (g_c->equals(g_d ?eps n_eps)
                when(_OnSegment(g_a g_b g_c n_eps) g_c)
            )
            (t
                rx = g_b->x() - g_a->x()
                ry = g_b->y() - g_a->y()
                sx = g_d->x() - g_c->x()
                sy = g_d->y() - g_c->y()
                qpx = g_c->x() - g_a->x()
                qpy = g_c->y() - g_a->y()
                rxs = rx * sy - ry * sx
                qpxr = qpx * ry - qpy * rx
                rr = rx * rx + ry * ry
                lenr = sqrt(rr)
                lens = sqrt(sx * sx + sy * sy)
                tolr = n_eps / lenr
                tols = n_eps / lens
                if(abs(rxs) <= n_eps * lenr * lens
                then
                    when(abs(qpxr) <= n_eps * lenr
                        t0 = (qpx * rx + qpy * ry) / rr
                        t1 = ((g_d->x() - g_a->x()) * rx
                            + (g_d->y() - g_a->y()) * ry) / rr
                        min = min(t0 t1)
                        max = max(t0 t1)
                        unless(max < -tolr || min > 1.0 + tolr
                            min = max(min 0.0)
                            max = min(max 1.0)
                            if(_Near(min max tolr)
                                _SegPointAt(g_a g_b min)
                                Segment(list(_SegPointAt(g_a g_b min)
                                    _SegPointAt(g_a g_b max)))
                            )
                        )
                    )
                else
                    value = (qpx * sy - qpy * sx) / rxs
                    u = (qpx * ry - qpy * rx) / rxs
                    when(value >= -tolr && value <= 1.0 + tolr
                        && u >= -tols && u <= 1.0 + tols
                        _SegPointAt(g_a g_b value)
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
        let((dx dy)
            dx = self->_data->end->x() - self->_data->start->x()
            dy = self->_data->end->y() - self->_data->start->y()
            sqrt(dx * dx + dy * dy)
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
        let((dx dy len)
            dx = self->_data->end->x() - self->_data->start->x()
            dy = self->_data->end->y() - self->_data->start->y()
            len = sqrt(dx * dx + dy * dy)
            unless(len <= _Eps(nil)
                list(dx / len dy / len)
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
        let((p dx dy den value)
            p = _AsPoint(g_point "ycGeom::Segment->project")
            dx = self->_data->end->x() - self->_data->start->x()
            dy = self->_data->end->y() - self->_data->start->y()
            den = dx * dx + dy * dy
            if(den <= _Eps(nil) * _Eps(nil)
            then
                self->_data->start
            else
                value = ((p->x() - self->_data->start->x()) * dx
                    + (p->y() - self->_data->start->y()) * dy) / den
                when(value >= 0.0 && value <= 1.0
                    _SegPointAt(self->_data->start self->_data->end value)
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
        let((p dx dy den value)
            p = _AsPoint(g_point "ycGeom::Segment->nearestPoint")
            dx = self->_data->end->x() - self->_data->start->x()
            dy = self->_data->end->y() - self->_data->start->y()
            den = dx * dx + dy * dy
            if(den <= _Eps(nil) * _Eps(nil)
            then
                self->_data->start
            else
                value = ((p->x() - self->_data->start->x()) * dx
                    + (p->y() - self->_data->start->y()) * dy) / den
                value = max(0.0 min(1.0 value))
                _SegPointAt(self->_data->start self->_data->end value)
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
        let((p)
            p = _AsPoint(g_point "ycGeom::Segment->distanceTo")
            p->distanceTo(self->nearestPoint(p))
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
        let((p eps2)
            p = _AsPoint(g_point "ycGeom::Segment->contains")
            eps2 = _Eps(eps)
            _OnSegment(self->_data->start self->_data->end p eps2)
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
    self->toRect = lambda(()  ; -> Rect
        ; 返回包围矩形。
        ;
        ; **返回**
        ;   (Rect) - 由 bBox 构造；水平、垂直或零长度线段可为退化矩形
        Rect(self->bBox())
    )
    self->intersection = lambda((g_other \@key (eps nil) (as nil) "ggg")  ; -> Point | Segment | nil
        ; 计算与 Line 或 Segment 的交点。
        ;
        ; **参数**
        ;   g_other  (Line|Segment|list) - 另一对象或两点数组
        ;   ?eps     (num|nil)           - 容差；默认 nil（1e-9）
        ;   ?as      (sym|nil)           - 数组目标类型 'Line/'Segment；默认 nil
        ;
        ; **返回**
        ;   (Point|Segment|nil) - 唯一交点、重叠线段或无交
        let((eps2 o)
            eps2 = _Eps(eps)
            o = _AsLineOrSegment(g_other as "ycGeom::Segment->intersection")
            cond(
                (_LineP(o)
                    _LineSegmentIntersection(o self eps2))
                (_SegmentP(o)
                    _SegSegIntersection(self->_data->start self->_data->end
                        o->start() o->end() eps2))
                (t
                    error("ycGeom::Segment->intersection: expected a Line or Segment, got %A"
                        o))
            )
        )
    )
    self->toLine = lambda(()  ; -> Line | nil
        ; 返回对应的无限直线。
        ;
        ; **返回**
        ;   (Line|nil) - 经过起终点的无限直线；零长度线段为 nil
        unless(self->_data->start->equals(self->_data->end)
            Line(list(self->_data->start self->_data->end))
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

procedure(Segment(l_data "l")  ; -> Segment
    ; 构造不可变线段。
    ;
    ; **参数**
    ;   l_data  (list) - 两点列表、包一层的两点列表或 Point 列表
    ;
    ; **返回**
    ;   (Segment) - 新线段；零长度合法；格式不合法 error
    let((pts)
        pts = _TwoPoints(l_data "ycGeom::Segment")
        makeInstance('Segment ?_data
            makeInstance('_SegmentData
                ?start _Nth1(1 pts)
                ?end _Nth1(2 pts)))
    )
)

unuseNamespace("ycGeom")

; END
