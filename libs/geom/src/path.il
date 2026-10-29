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
