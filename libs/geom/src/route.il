useNamespace("ycGeom")

defclass(_RouteData () (
    ; _RouteData 数据桶：收纳折线点列与闭合标记，构造后禁写。
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
    ; 状态桶（_RouteData：points + closed），构造后禁写
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
        let((res len i a b)
            len = length(self->_data->points)
            for(i2 1 if(self->_data->closed len (len - 1))
                a = _Nth1(i2 self->_data->points)
                b = _Nth1(if(i2 == len 1 (i2 + 1)) self->_data->points)
                res = tconc(res Segment(list(a b)))
            )
            car(res)
        )
    )
    self->length = lambda(()  ; -> float
        ; 返回中心线总长。
        ;
        ; **返回**
        ;   (float) - 各段长度之和（补偿求和）
        let((sum comp term next)
            sum = 0.0
            comp = 0.0
            foreach(seg self->segments()
                term = seg->length()
                next = sum + term
                if(abs(sum) >= abs(term)
                then
                    comp = comp + ((sum - next) + term)
                else
                    comp = comp + ((term - next) + sum)
                )
                sum = next
            )
            sum + comp
        )
    )
    self->bBox = lambda(()  ; -> list[list[float]]
        ; 返回包围盒。
        ;
        ; **返回**
        ;   (list[list[float]]) - ((xmin ymin) (xmax ymax))
        let((xmin ymin xmax ymax)
            xmin = car(self->_data->points)->x()
            xmax = xmin
            ymin = car(self->_data->points)->y()
            ymax = ymin
            foreach(p self->_data->points
                xmin = min(xmin p->x())
                xmax = max(xmax p->x())
                ymin = min(ymin p->y())
                ymax = max(ymax p->y())
            )
            list(list(xmin ymin) list(xmax ymax))
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
        let((acc len i)
            len = length(self->_data->points)
            for(i2 1 len
                acc = tconc(acc _Nth1((len - i2 + 1) self->_data->points))
            )
            when(self->_data->closed
                acc = tconc(acc car(car(acc)))
            )
            Route(car(acc))
        )
    )
    self->toSkill = lambda(()  ; -> list[list[float]]
        ; 转换为 SKILL 原生坐标列表。
        ;
        ; **返回**
        ;   (list[list[float]]) - 闭合时末尾补回首点
        let((acc)
            foreach(p self->_data->points
                acc = tconc(acc p->toSkill())
            )
            when(self->_data->closed
                acc = tconc(acc car(self->_data->points)->toSkill())
            )
            car(acc)
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
    let((pts len eps2 closed2 i prev cur acc)
        pts = _AsPointList(l_points "ycGeom::Route")
        len = length(pts)
        unless(len >= 1
            error("ycGeom::Route: at least 2 points are required")
        )
        eps2 = _Eps(eps)
        when(len == 1
            error("ycGeom::Route: at least 2 points are required")
        )
        closed2 = _SamePoint(car(pts) _Nth1(len pts) eps2)
        when(closed2
            for(i2 1 len - 1
                acc = tconc(acc _Nth1(i2 pts))
            )
            pts = car(acc)
            len = length(pts)
            unless(len >= 3
                error("ycGeom::Route: closed route needs at least 3 distinct points")
            )
        )
        unless(closed2 || len >= 2
            error("ycGeom::Route: at least 2 points are required")
        )
        for(i2 1 len
            cur = _Nth1(i2 pts)
            prev = when(!(i2 == 1 && !closed2)
                _Nth1(if(i2 == 1 len (i2 - 1)) pts)
            )
            when(prev && _Near(prev->x() cur->x() eps2)
                && _Near(prev->y() cur->y() eps2)
                error("ycGeom::Route: consecutive duplicate point at index %d" i2)
            )
        )
        makeInstance('Route ?_data makeInstance('_RouteData
            ?points pts ?closed closed2))
    )
)

unuseNamespace("ycGeom")

; END
