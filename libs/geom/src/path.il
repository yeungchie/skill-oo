useNamespace("ycGeom")

defclass(PathData () (
    ; PathData 数据桶：收纳中心线与总宽度，构造后禁写。
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
    ; 状态桶（PathData：route + width），构造后禁写
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
        let((n_half n_limit n_segments n_eps n_grid l_pieces
                l_pts n_len n_seg n_i g_a g_b g_prev g_v g_next
                g_piece n_dx n_dy n_dlen g_dir)
            unless(symbolp(cap) && member(cap '(butt square round))
                error("ycGeom::Path->toRegion: ?cap must be butt, square, or round, got %A"
                    cap)
            )
            unless(symbolp(join) && member(join '(miter round bevel))
                error("ycGeom::Path->toRegion: ?join must be miter, round, or bevel, got %A"
                    join)
            )
            n_half = self->_data->width / 2.0
            n_limit = _SizeMiterLimit(miterLimit)
            n_segments = _SizeRoundSegments(roundSegments)
            n_eps = _Eps(eps)
            n_grid = _Grid(grid)
            l_pts = self->_data->route->points()
            n_len = length(l_pts)

            n_seg = if(self->_data->route->isClosed() n_len (n_len - 1))
            for(n_i 1 n_seg
                g_a = _Nth1(n_i l_pts)
                g_b = _Nth1(if(n_i == n_len 1 (n_i + 1)) l_pts)
                g_piece = _StrokeBand(g_a g_b n_half)
                when(g_piece
                    l_pieces = tconc(l_pieces g_piece)
                )
            )

            if(self->_data->route->isClosed()
            then
                for(n_i 1 n_len
                    g_prev = _Nth1(if(n_i == 1 n_len (n_i - 1)) l_pts)
                    g_v = _Nth1(n_i l_pts)
                    g_next = _Nth1(if(n_i == n_len 1 (n_i + 1)) l_pts)
                    g_piece = _StrokeJoin(g_prev g_v g_next n_half
                        join n_limit n_segments)
                    when(g_piece
                        l_pieces = tconc(l_pieces g_piece)
                    )
                )
            else
                for(n_i 2 n_len - 1
                    g_prev = _Nth1((n_i - 1) l_pts)
                    g_v = _Nth1(n_i l_pts)
                    g_next = _Nth1((n_i + 1) l_pts)
                    g_piece = _StrokeJoin(g_prev g_v g_next n_half
                        join n_limit n_segments)
                    when(g_piece
                        l_pieces = tconc(l_pieces g_piece)
                    )
                )

                g_a = car(l_pts)
                g_b = _Nth1(2 l_pts)
                n_dx = g_a->x() - g_b->x()
                n_dy = g_a->y() - g_b->y()
                n_dlen = sqrt(n_dx * n_dx + n_dy * n_dy)
                when(n_dlen > n_eps
                    g_dir = Point(list(n_dx / n_dlen n_dy / n_dlen))
                    g_piece = _StrokeCap(g_a g_dir n_half cap n_segments)
                    when(g_piece
                        l_pieces = tconc(l_pieces g_piece)
                    )
                )

                g_a = _Nth1(n_len l_pts)
                g_b = _Nth1((n_len - 1) l_pts)
                n_dx = g_a->x() - g_b->x()
                n_dy = g_a->y() - g_b->y()
                n_dlen = sqrt(n_dx * n_dx + n_dy * n_dy)
                when(n_dlen > n_eps
                    g_dir = Point(list(n_dx / n_dlen n_dy / n_dlen))
                    g_piece = _StrokeCap(g_a g_dir n_half cap n_segments)
                    when(g_piece
                        l_pieces = tconc(l_pieces g_piece)
                    )
                )
            )

            Region(car(l_pieces) ?normalize t ?grid n_grid ?eps n_eps)
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
        ;   ?edge   (int)     - 切开接缝的边序号，1-based；默认 1
        ;   ?ratio  (num)     - 切点在边上的比例；默认 0.5
        ;   ?eps    (num|nil) - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (list[list[float]]) - 闭合时首尾重复；无法单 path 表示 error
        let((l_pts l_src l_res n_len n_eps g_closed n_i n_j g_a g_b g_c g_d
                n_cross n_dot n_idx g_p n_edge)
            unless(fixp(edge) && edge >= 1
                error("ycGeom::Path->toLegalPathPoints: ?edge must be a positive integer, got %A"
                    edge)
            )
            unless(numberp(ratio) && ratio > 0.0 && ratio < 1.0
                error("ycGeom::Path->toLegalPathPoints: ?ratio must be in (0,1), got %A"
                    ratio)
            )
            n_eps = _Eps(eps)
            l_pts = self->_data->route->points()
            n_len = length(l_pts)
            g_closed = self->_data->route->isClosed()
            when(g_closed && edge > n_len
                error("ycGeom::Path->toLegalPathPoints: ?edge %d out of range 1..%d"
                    edge n_len)
            )

            n_edge = if(g_closed n_len (n_len - 1))
            for(n_i 1 n_edge
                for(n_j 1 n_edge
                    when(n_j > n_i
                        && !(n_j == (n_i + 1))
                        && !(g_closed && n_i == 1 && n_j == n_edge)
                        g_a = _Nth1(n_i l_pts)
                        g_b = _Nth1(if(n_i == n_len 1 (n_i + 1)) l_pts)
                        g_c = _Nth1(n_j l_pts)
                        g_d = _Nth1(if(n_j == n_len 1 (n_j + 1)) l_pts)
                        when(_SegmentsCross(g_a g_b g_c g_d n_eps)
                            error("ycGeom::Path->toLegalPathPoints: path self-intersects; a single native path cannot represent it, use toRegion()")
                        )
                    )
                )
            )

            for(n_i if(g_closed 1 2) if(g_closed n_len (n_len - 1))
                g_a = _Nth1(if(n_i == 1 n_len (n_i - 1)) l_pts)
                g_b = _Nth1(n_i l_pts)
                g_c = _Nth1(if(n_i == n_len 1 (n_i + 1)) l_pts)
                n_cross = (g_b->x() - g_a->x()) * (g_c->y() - g_b->y())
                    - (g_b->y() - g_a->y()) * (g_c->x() - g_b->x())
                n_dot = (g_b->x() - g_a->x()) * (g_c->x() - g_b->x())
                    + (g_b->y() - g_a->y()) * (g_c->y() - g_b->y())
                when(abs(n_cross) <= _AngleTol() && n_dot < 0.0
                    error("ycGeom::Path->toLegalPathPoints: path doubles back at a vertex; use toRegion()")
                )
            )

            if(!g_closed
            then
                self->_data->route->toSkill()
            else
                g_a = _Nth1(n_len l_pts)
                g_b = car(l_pts)
                g_c = _Nth1(2 l_pts)
                n_cross = (g_b->x() - g_a->x()) * (g_c->y() - g_b->y())
                    - (g_b->y() - g_a->y()) * (g_c->x() - g_b->x())
                n_dot = (g_b->x() - g_a->x()) * (g_c->x() - g_b->x())
                    + (g_b->y() - g_a->y()) * (g_c->y() - g_b->y())
                if(abs(n_cross) <= _AngleTol() && n_dot > 0.0
                then
                    self->_data->route->toSkill()
                else
                    l_src = self->_data->route->points()
                    g_a = _Nth1(edge l_src)
                    g_b = _Nth1(if(edge == n_len 1 (edge + 1)) l_src)
                    g_p = Point(list(
                        g_a->x() + ratio * (g_b->x() - g_a->x())
                        g_a->y() + ratio * (g_b->y() - g_a->y())
                    ))
                    l_res = tconc(l_res g_p->toSkill())
                    for(n_i 1 n_len
                        n_idx = edge + n_i
                        when(n_idx > n_len
                            n_idx = n_idx - n_len
                        )
                        l_res = tconc(l_res _Nth1(n_idx l_src)->toSkill())
                    )
                    l_res = tconc(l_res g_p->toSkill())
                    car(l_res)
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

procedure(Path(l_data \@key width (eps nil) "ggg")  ; -> Path
    ; 构造不可变带宽度描边。
    ;
    ; **参数**
    ;   l_data  (Route|list) - 中心线折线或点列
    ;   ?width  (num)        - 总宽度，必须为正
    ;   ?eps    (num|nil)    - 点列容差；默认 nil（1e-9）
    ;
    ; **返回**
    ;   (Path) - 新描边对象；参数非法 error
    let((g_route n_width)
        when(listp(l_data) && length(l_data) == 2 && numberp(cadr(l_data))
            when(width != nil
                error("ycGeom::Path: width given both in state list and ?width")
            )
            width = cadr(l_data)
            l_data = car(l_data)
        )
        cond(
            (classOf(l_data) == findClass('ycGeom::Route)
                g_route = l_data)
            (listp(l_data)
                g_route = Route(l_data ?eps eps))
            (t error("ycGeom::Path: expected a Route or point list, got %A" l_data))
        )
        unless(numberp(width) && width > 0.0
            error("ycGeom::Path: ?width must be a positive number, got %A" width)
        )
        n_width = float(width)
        makeInstance('Path ?_data makeInstance('PathData
            ?route g_route ?width n_width))
    )
)

unuseNamespace("ycGeom")

; END
