useNamespace("ycGeom")

defclass(_PathData () (
    ; _PathData 数据桶：收纳中心线与总宽度，构造后禁写。
    route(
        \@initarg route
        \@initform nil
    )
    width(
        \@initarg width
        \@initform 0.0
    )
))

defclass(Path () (
    ; Path 实例：不可变带宽度描边。
    ; 状态桶（_PathData：route + width），构造后禁写
    _data(
        \@initarg _data
        \@initform nil
    )

    route()
    width()
    isClosed()
    toRegion()
    area()
    perimeter()
    centroid()
    bBox()
    toRect()
    contains()
    onBoundary()
    toLegalPathPoints()
    toSkill()
))

defmethod(printself (self(Path))  ; -> str
    ; 返回 Path 的打印描述串。
    ;
    ; **返回**
    ;   (str) - <ycGeom::Path points=N width=... closed=t>
    lsprintf("<%A points=%d width=%A closed=%A>" className(self)
        length(self->_data->route->points())
        self->_data->width
        self->_data->route->isClosed())
)

inScheme(
procedure(_InstallPath(self "g")  ; -> t
    ; 把 Path 方法安装到 Path 类（由 initializeInstance 调用）。
    ;
    ; **参数**
    ;   self  (Path) - 目标实例
    ;
    ; **返回**
    ;   (t) - 安装完成；调用方忽略
    self->route = lambda(()  ; -> Route
        ; 返回中心线折线。
        ;
        ; **返回**
        ;   (Route) - 内部折线，不得原地修改
        self->_data->route
    )
    self->width = lambda(()  ; -> float
        ; 返回总宽度。
        ;
        ; **返回**
        ;   (float) - 总宽度
        self->_data->width
    )
    self->isClosed = lambda(()  ; -> t | nil
        ; 判断中心线是否闭合。
        ;
        ; **返回**
        ;   (t|nil) - 闭合为 t
        self->_data->route->isClosed()
    )
    self->toRegion = lambda((\@key (cap 'butt) (join 'miter) (miterLimit nil) (roundSegments nil) (eps nil) (grid nil) "gggggg")  ; -> Region
        ; 生成描边区域。
        ;
        ; **参数**
        ;   ?cap           (sym)     - butt/square/round；默认 butt
        ;   ?join          (sym)     - miter/round/bevel；默认 miter
        ;   ?miterLimit    (num|nil) - miter 限制；默认 nil（4.0）
        ;   ?roundSegments (int|nil) - 每 90 度圆角段数；默认 nil（8）
        ;   ?eps           (num|nil) - 容差；默认 nil（1e-9）
        ;   ?grid          (num|nil) - 网格；默认 nil
        ;
        ; **返回**
        ;   (Region) - 描边区域
        let((half limit segments eps2 grid2 pieces
                pts len seg i a b prev v next
                piece dx dy dlen dir)
            unless(symbolp(cap) && member(cap '(butt square round))
                error("ycGeom::Path->toRegion: ?cap must be butt, square, or round, got %A"
                    cap)
            )
            unless(symbolp(join) && member(join '(miter round bevel))
                error("ycGeom::Path->toRegion: ?join must be miter, round, or bevel, got %A"
                    join)
            )
            half = self->_data->width / 2.0
            limit = _SizeMiterLimit(miterLimit)
            segments = _SizeRoundSegments(roundSegments)
            eps2 = _Eps(eps)
            grid2 = _Grid(grid)
            pts = self->_data->route->points()
            len = length(pts)

            seg = if(self->_data->route->isClosed() len (len - 1))
            for(i2 1 seg
                a = _Nth1(i2 pts)
                b = _Nth1(if(i2 == len 1 (i2 + 1)) pts)
                piece = _StrokeBand(a b half)
                when(piece
                    pieces = tconc(pieces piece)
                )
            )

            if(self->_data->route->isClosed()
            then
                for(i2 1 len
                    prev = _Nth1(if(i2 == 1 len (i2 - 1)) pts)
                    v = _Nth1(i2 pts)
                    next = _Nth1(if(i2 == len 1 (i2 + 1)) pts)
                    piece = _StrokeJoin(prev v next half
                        join limit segments)
                    when(piece
                        pieces = tconc(pieces piece)
                    )
                )
            else
                for(i2 2 len - 1
                    prev = _Nth1((i2 - 1) pts)
                    v = _Nth1(i2 pts)
                    next = _Nth1((i2 + 1) pts)
                    piece = _StrokeJoin(prev v next half
                        join limit segments)
                    when(piece
                        pieces = tconc(pieces piece)
                    )
                )

                a = car(pts)
                b = _Nth1(2 pts)
                dx = a->x() - b->x()
                dy = a->y() - b->y()
                dlen = sqrt(dx * dx + dy * dy)
                when(dlen > _Eps(nil)
                    dir = Point(list(dx / dlen dy / dlen))
                    piece = _StrokeCap(a dir half cap segments)
                    when(piece
                        pieces = tconc(pieces piece)
                    )
                )

                a = _Nth1(len pts)
                b = _Nth1((len - 1) pts)
                dx = a->x() - b->x()
                dy = a->y() - b->y()
                dlen = sqrt(dx * dx + dy * dy)
                when(dlen > _Eps(nil)
                    dir = Point(list(dx / dlen dy / dlen))
                    piece = _StrokeCap(a dir half cap segments)
                    when(piece
                        pieces = tconc(pieces piece)
                    )
                )
            )

            unless(pieces
                error("ycGeom::Path->toRegion: stroke degraded to an empty region")
            )
            Region(car(pieces) ?normalize t ?grid grid2 ?eps eps2)
        )
    )
    self->area = lambda(()  ; -> float
        ; 返回描边面积。
        ;
        ; **返回**
        ;   (float) - 默认 butt + miter 描边面积
        self->toRegion()->area()
    )
    self->perimeter = lambda((\@key (includeSeams nil) (eps nil) "gg")  ; -> float
        ; 返回描边周长。
        ;
        ; **参数**
        ;   ?includeSeams  (t|nil)   - 是否计入切割线；默认 nil
        ;   ?eps           (num|nil) - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (float) - 默认 butt + miter 描边周长
        self->toRegion()->perimeter(
            ?includeSeams includeSeams ?eps eps)
    )
    self->centroid = lambda(()  ; -> Point | nil
        ; 返回描边质心。
        ;
        ; **返回**
        ;   (Point|nil) - 默认描边的面积加权质心
        self->toRegion()->centroid()
    )
    self->bBox = lambda(()  ; -> list[list[float]] | nil
        ; 返回描边包围盒。
        ;
        ; **返回**
        ;   (list[list[float]]|nil) - 默认描边包围盒
        self->toRegion()->bBox()
    )
    self->toRect = lambda(()  ; -> Rect | nil
        ; 返回描边包围盒矩形。
        ;
        ; **返回**
        ;   (Rect|nil) - 默认描边的包围盒矩形
        self->toRegion()->toRect()
    )
    self->contains = lambda((g_point \@key (boundary "inside") (eps nil) "ggg")  ; -> t | nil
        ; 判断点是否属于描边区域。
        ;
        ; **参数**
        ;   g_point   (Point)       - 查询点
        ;   ?boundary (str)         - "inside" 或 "outside"；默认 "inside"
        ;   ?eps      (num|nil)     - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (t|nil) - 属于默认描边区域为 t
        self->toRegion()->contains(g_point
            ?boundary boundary ?eps eps)
    )
    self->onBoundary = lambda((g_point \@key (includeSeams nil) (eps nil) "ggg")  ; -> t | nil
        ; 判断点是否在描边边界上。
        ;
        ; **参数**
        ;   g_point        (Point)   - 查询点
        ;   ?includeSeams  (t|nil)   - 是否计入切割线；默认 nil
        ;   ?eps           (num|nil) - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (t|nil) - 在默认描边边界上为 t
        self->toRegion()->onBoundary(g_point
            ?includeSeams includeSeams ?eps eps)
    )
    self->toLegalPathPoints = lambda((\@key (edge 1) (ratio 0.5) (eps nil) "xng")  ; -> list[list[float]]
        ; 返回本机可创建的合法 path 点列。
        ;
        ; **参数**
        ;   ?edge   (int)     - 切开接缝的边序号，1-based；默认 1；开放路径只校验范围，不影响结果
        ;   ?ratio  (num)     - 切点在边上的比例；默认 0.5
        ;   ?eps    (num|nil) - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (list[list[float]]) - 闭合时首尾重复；无法单 path 表示 error
        let((pts src res len eps2 tol closed i j a b c d
                cross dot l1 l2 idx p edge2)
            unless(fixp(edge) && edge >= 1
                error("ycGeom::Path->toLegalPathPoints: ?edge must be a positive integer, got %A"
                    edge)
            )
            unless(numberp(ratio) && ratio > 0.0 && ratio < 1.0
                error("ycGeom::Path->toLegalPathPoints: ?ratio must be in (0,1), got %A"
                    ratio)
            )
            eps2 = _Eps(eps)
            tol = max(_AngleTol() eps2)
            pts = self->_data->route->points()
            len = length(pts)
            closed = self->_data->route->isClosed()
            ; 开放路径没有接缝，但 ?edge 仍按 1..边数 校验，
            ; 避免同一个关键字在两类路径上给出不一致的契约。
            edge2 = if(closed len (len - 1))
            when(edge > edge2
                error("ycGeom::Path->toLegalPathPoints: ?edge %d out of range 1..%d"
                    edge edge2)
            )

            for(i2 1 edge2
                for(j2 1 edge2
                    when(j2 > i2
                        && !(j2 == (i2 + 1))
                        && !(closed && i2 == 1 && j2 == edge2)
                        a = _Nth1(i2 pts)
                        b = _Nth1(if(i2 == len 1 (i2 + 1)) pts)
                        c = _Nth1(j2 pts)
                        d = _Nth1(if(j2 == len 1 (j2 + 1)) pts)
                        when(_SegmentsCross(a b c d eps2)
                            error("ycGeom::Path->toLegalPathPoints: path self-intersects; a single native path cannot represent it, use toRegion()")
                        )
                    )
                )
            )

            for(i2 if(closed 1 2) if(closed len (len - 1))
                a = _Nth1(if(i2 == 1 len (i2 - 1)) pts)
                b = _Nth1(i2 pts)
                c = _Nth1(if(i2 == len 1 (i2 + 1)) pts)
                cross = (b->x() - a->x()) * (c->y() - b->y())
                    - (b->y() - a->y()) * (c->x() - b->x())
                dot = (b->x() - a->x()) * (c->x() - b->x())
                    + (b->y() - a->y()) * (c->y() - b->y())
                l1 = sqrt((b->x() - a->x()) * (b->x() - a->x())
                    + (b->y() - a->y()) * (b->y() - a->y()))
                l2 = sqrt((c->x() - b->x()) * (c->x() - b->x())
                    + (c->y() - b->y()) * (c->y() - b->y()))
                when(l1 > 0.0 && l2 > 0.0
                    && abs(cross / (l1 * l2)) <= tol
                    && dot < 0.0
                    error("ycGeom::Path->toLegalPathPoints: path doubles back at a vertex; use toRegion()")
                )
            )

            if(!closed
            then
                self->_data->route->toSkill()
            else
                a = _Nth1(len pts)
                b = car(pts)
                c = _Nth1(2 pts)
                cross = (b->x() - a->x()) * (c->y() - b->y())
                    - (b->y() - a->y()) * (c->x() - b->x())
                dot = (b->x() - a->x()) * (c->x() - b->x())
                    + (b->y() - a->y()) * (c->y() - b->y())
                l1 = sqrt((b->x() - a->x()) * (b->x() - a->x())
                    + (b->y() - a->y()) * (b->y() - a->y()))
                l2 = sqrt((c->x() - b->x()) * (c->x() - b->x())
                    + (c->y() - b->y()) * (c->y() - b->y()))
                if(l1 > 0.0 && l2 > 0.0
                    && abs(cross / (l1 * l2)) <= tol
                    && dot > 0.0
                then
                    self->_data->route->toSkill()
                else
                    src = self->_data->route->points()
                    a = _Nth1(edge src)
                    b = _Nth1(if(edge == len 1 (edge + 1)) src)
                    p = Point(list(
                        a->x() + ratio * (b->x() - a->x())
                        a->y() + ratio * (b->y() - a->y())
                    ))
                    res = tconc(res p->toSkill())
                    for(i2 1 len
                        idx = edge + i2
                        when(idx > len
                            idx = idx - len
                        )
                        res = tconc(res _Nth1(idx src)->toSkill())
                    )
                    res = tconc(res p->toSkill())
                    car(res)
                )
            )
        )
    )
    self->toSkill = lambda(()  ; -> list
        ; 转换为 SKILL 原生状态列表。
        ;
        ; **返回**
        ;   (list) - (点列 宽度)；闭合点列末尾重复首点
        list(self->_data->route->toSkill() self->_data->width)
    )
    t
)
)

inScheme(
defmethod(initializeInstance (self(Path) \@rest _args)
    ; 构造 Path 实例时安装方法集。
    ;
    ; **参数**
    ;   _args  (list) - 附加初始化参数，本实现忽略
    ;
    ; **返回**
    ;   (t) - 安装完成
    _InstallPath(self)
    t
)
)

procedure(Path(g_data \@key width (eps nil) "ggg")  ; -> Path
    ; 构造不可变带宽度描边。
    ;
    ; **参数**
    ;   g_data  (Route|list) - 中心线折线或点列
    ;   ?width  (num)        - 总宽度，必须为正
    ;   ?eps    (num|nil)    - 点列容差；默认 nil（1e-9）
    ;
    ; **返回**
    ;   (Path) - 新描边对象；参数非法 error
    let((route2 width2)
        when(listp(g_data) && length(g_data) == 2 && numberp(cadr(g_data))
            when(width != nil
                error("ycGeom::Path: width given both in state list and ?width")
            )
            width = cadr(g_data)
            g_data = car(g_data)
        )
        cond(
            (classOf(g_data) == findClass('ycGeom::Route)
                route2 = g_data)
            (listp(g_data)
                route2 = Route(g_data ?eps eps))
            (t error("ycGeom::Path: expected a Route or point list, got %A" g_data))
        )
        unless(numberp(width) && width > 0.0
            error("ycGeom::Path: ?width must be a positive number, got %A" width)
        )
        width2 = float(width)
        makeInstance('Path ?_data makeInstance('_PathData
            ?route route2 ?width width2))
    )
)

unuseNamespace("ycGeom")

; END
