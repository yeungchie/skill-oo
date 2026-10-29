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
