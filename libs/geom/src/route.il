useNamespace("ycGeom")

defclass(RouteData () (
    ; RouteData 数据桶：收纳折线点列与闭合标记，构造后禁写。
    points(
        \@initarg points
        \@initform nil
    )
    closed(
        \@initarg closed
        \@initform nil
    )
))

defclass(Route () (
    ; Route 实例：不可变零宽度折线。
    ; 状态桶（RouteData：points + closed），构造后禁写
    _data(
        \@initarg _data
        \@initform nil
    )

    points()
    isClosed()
    segments()
    length()
    bBox()
    toRect()
    toPolygon()
    reverse()
    toSkill()
))

defmethod(printself (self(Route))  ; -> str
    ; 返回 Route 的打印描述串。
    ;
    ; **返回**
    ;   (str) - <ycGeom::Route points=N closed=t>
    lsprintf("<%A points=%d closed=%A>" className(self)
        length(self->_data->points) self->_data->closed)
)

inScheme(
procedure(_InstallRoute(self "g")  ; -> t
    ; 把 Route 方法安装到 Route 类（由 initializeInstance 调用）。
    ;
    ; **参数**
    ;   self  (Route) - 目标实例
    ;
    ; **返回**
    ;   (t) - 安装完成；调用方忽略
    self->points = lambda(()  ; -> list[Point]
        ; 返回内部点列。
        ;
        ; **返回**
        ;   (list[Point]) - 不含重复首点的点列，不得原地修改
        self->_data->points
    )
    self->isClosed = lambda(()  ; -> t | nil
        ; 判断折线是否闭合。
        ;
        ; **返回**
        ;   (t|nil) - 闭合为 t
        self->_data->closed
    )
    self->segments = lambda(()  ; -> list[Segment]
        ; 返回逐段线段列表。
        ;
        ; **返回**
        ;   (list[Segment]) - 开放 n-1 段，闭合 n 段
        let((l_res n_len n_i g_a g_b)
            n_len = length(self->_data->points)
            for(n_i 1 if(self->_data->closed n_len (n_len - 1))
                g_a = _Nth1(n_i self->_data->points)
                g_b = _Nth1(if(n_i == n_len 1 (n_i + 1)) self->_data->points)
                l_res = tconc(l_res Segment(list(g_a g_b)))
            )
            car(l_res)
        )
    )
    self->length = lambda(()  ; -> float
        ; 返回中心线总长。
        ;
        ; **返回**
        ;   (float) - 各段长度之和（补偿求和）
        let((n_sum n_comp n_term n_next)
            n_sum = 0.0
            n_comp = 0.0
            foreach(g_seg self->segments()
                n_term = g_seg->length()
                n_next = n_sum + n_term
                if(abs(n_sum) >= abs(n_term)
                then
                    n_comp = n_comp + ((n_sum - n_next) + n_term)
                else
                    n_comp = n_comp + ((n_term - n_next) + n_sum)
                )
                n_sum = n_next
            )
            n_sum + n_comp
        )
    )
    self->bBox = lambda(()  ; -> list[list[float]]
        ; 返回包围盒。
        ;
        ; **返回**
        ;   (list[list[float]]) - ((xmin ymin) (xmax ymax))
        let((n_xmin n_ymin n_xmax n_ymax)
            n_xmin = car(self->_data->points)->x()
            n_xmax = n_xmin
            n_ymin = car(self->_data->points)->y()
            n_ymax = n_ymin
            foreach(g_p self->_data->points
                n_xmin = min(n_xmin g_p->x())
                n_xmax = max(n_xmax g_p->x())
                n_ymin = min(n_ymin g_p->y())
                n_ymax = max(n_ymax g_p->y())
            )
            list(list(n_xmin n_ymin) list(n_xmax n_ymax))
        )
    )
    self->toRect = lambda(()  ; -> Rect
        ; 返回包围盒对应的矩形。
        ;
        ; **返回**
        ;   (Rect) - 零宽或零高合法
        Rect(self->bBox())
    )
    self->toPolygon = lambda(()  ; -> Polygon
        ; 把闭合折线转为多边形。
        ;
        ; **返回**
        ;   (Polygon) - 仅闭合折线；开放或非法自交 error
        unless(self->_data->closed
            error("ycGeom::Route->toPolygon: open route cannot become a Polygon")
        )
        Polygon(self->_data->points)
    )
    self->reverse = lambda(()  ; -> Route
        ; 返回反向折线。
        ;
        ; **返回**
        ;   (Route) - 闭合状态不变
        let((l_acc n_len n_i)
            n_len = length(self->_data->points)
            for(n_i 1 n_len
                l_acc = tconc(l_acc _Nth1((n_len - n_i + 1) self->_data->points))
            )
            when(self->_data->closed
                l_acc = tconc(l_acc car(car(l_acc)))
            )
            Route(car(l_acc))
        )
    )
    self->toSkill = lambda(()  ; -> list[list[float]]
        ; 转换为 SKILL 原生坐标列表。
        ;
        ; **返回**
        ;   (list[list[float]]) - 闭合时末尾补回首点
        let((l_acc)
            foreach(g_p self->_data->points
                l_acc = tconc(l_acc g_p->toSkill())
            )
            when(self->_data->closed
                l_acc = tconc(l_acc car(self->_data->points)->toSkill())
            )
            car(l_acc)
        )
    )
    t
)
)

inScheme(
defmethod(initializeInstance (self(Route) \@rest _args)
    ; 构造 Route 实例时安装方法集。
    ;
    ; **参数**
    ;   _args  (list) - 附加初始化参数，本实现忽略
    ;
    ; **返回**
    ;   (t) - 安装完成
    _InstallRoute(self)
    t
)
)

procedure(Route(l_points \@key (eps nil) "lg")  ; -> Route
    ; 构造不可变折线；首尾重合视为闭合。
    ;
    ; **参数**
    ;   l_points  (list[Point]) - 点列；闭合时末尾重复首点
    ;   ?eps      (num|nil)     - 容差；默认 nil（1e-9）
    ;
    ; **返回**
    ;   (Route) - 新折线；点数不足、重复点或格式非法 error
    let((l_pts n_len n_eps g_closed n_i g_prev g_cur l_acc)
        l_pts = _AsPointList(l_points "ycGeom::Route")
        n_len = length(l_pts)
        unless(n_len >= 1
            error("ycGeom::Route: at least 2 points are required")
        )
        n_eps = _Eps(eps)
        when(n_len == 1
            error("ycGeom::Route: at least 2 points are required")
        )
        g_closed = _SamePoint(car(l_pts) _Nth1(n_len l_pts) n_eps)
        when(g_closed
            for(n_i 1 n_len - 1
                l_acc = tconc(l_acc _Nth1(n_i l_pts))
            )
            l_pts = car(l_acc)
            n_len = length(l_pts)
            unless(n_len >= 3
                error("ycGeom::Route: closed route needs at least 3 distinct points")
            )
        )
        unless(g_closed || n_len >= 2
            error("ycGeom::Route: at least 2 points are required")
        )
        for(n_i 1 n_len
            g_cur = _Nth1(n_i l_pts)
            g_prev = when(!(n_i == 1 && !g_closed)
                _Nth1(if(n_i == 1 n_len (n_i - 1)) l_pts)
            )
            when(g_prev && _Near(g_prev->x() g_cur->x() n_eps)
                && _Near(g_prev->y() g_cur->y() n_eps)
                error("ycGeom::Route: consecutive duplicate point at index %d" n_i)
            )
        )
        makeInstance('Route ?_data makeInstance('RouteData
            ?points l_pts ?closed g_closed))
    )
)

unuseNamespace("ycGeom")

; END
