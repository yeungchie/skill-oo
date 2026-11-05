useNamespace("ycGeom")

defclass(_RectData () (
    ; _RectData 数据桶：收纳轴对齐矩形的 xmin/ymin/xmax/ymax，构造后禁写。
    xmin(
        \@initarg xmin
        \@initform 0.0
    )
    ymin(
        \@initarg ymin
        \@initform 0.0
    )
    xmax(
        \@initarg xmax
        \@initform 0.0
    )
    ymax(
        \@initarg ymax
        \@initform 0.0
    )
))

defclass(Rect () (
    ; Rect 实例：不可变轴对齐矩形。
    ; 状态桶（_RectData：xmin + ymin + xmax + ymax），构造后禁写
    _data(
        \@initarg _data
        \@initform nil
    )

    xmin()
    ymin()
    xmax()
    ymax()
    width()
    height()
    area()
    perimeter()
    size()
    center()
    centroid()
    contains()
    onBoundary()
    bBox()
    or()
    and()
    not()
    xor()
    toPolygon()
    toSkill()
))

defmethod(printself (self(Rect))  ; -> str
    ; 返回 Rect 的打印描述串。
    ;
    ; **返回**
    ;   (str) - <ycGeom::Rect ((xmin ymin) (xmax ymax))>
    lsprintf("<%A ((%A %A) (%A %A))>" className(self)
        self->_data->xmin self->_data->ymin
        self->_data->xmax self->_data->ymax)
)

procedure(_RectPolygon(g_rect "g")  ; -> Polygon | nil
    ; 把非退化 Rect 转为四点 Polygon（内部实现）。
    ;
    ; **参数**
    ;   g_rect  (Rect) - 源矩形
    ;
    ; **返回**
    ;   (Polygon|nil) - 逆时针四角 Polygon；退化时 nil；非法对象 error
    unless(_RectP(g_rect)
        error("ycGeom: expected a Rect, got %A" g_rect)
    )
    let((eps2 scale)
        eps2 = _Eps(nil)
        scale = max(g_rect->width() g_rect->height())
        unless(g_rect->width() <= 0.0 || g_rect->height() <= 0.0
                || g_rect->area() <= eps2 * scale
            Polygon(list(
                Point(list(g_rect->xmin() g_rect->ymin()))
                Point(list(g_rect->xmax() g_rect->ymin()))
                Point(list(g_rect->xmax() g_rect->ymax()))
                Point(list(g_rect->xmin() g_rect->ymax()))
            ))
        )
    )
)

inScheme(
procedure(_InstallRect(self "g")  ; -> t
    ; 把 Rect 方法安装到 Rect 类（由 initializeInstance 调用）。
    ;
    ; **返回**
    ;   (t) - 安装完成；调用方忽略
    self->xmin = lambda(()  ; -> float
        ; 返回左边界。
        ;
        ; **返回**
        ;   (float) - xmin
        self->_data->xmin
    )
    self->ymin = lambda(()  ; -> float
        ; 返回下边界。
        ;
        ; **返回**
        ;   (float) - ymin
        self->_data->ymin
    )
    self->xmax = lambda(()  ; -> float
        ; 返回右边界。
        ;
        ; **返回**
        ;   (float) - xmax
        self->_data->xmax
    )
    self->ymax = lambda(()  ; -> float
        ; 返回上边界。
        ;
        ; **返回**
        ;   (float) - ymax
        self->_data->ymax
    )
    self->width = lambda(()  ; -> float
        ; 返回宽度。
        ;
        ; **返回**
        ;   (float) - xmax - xmin
        self->_data->xmax - self->_data->xmin
    )
    self->height = lambda(()  ; -> float
        ; 返回高度。
        ;
        ; **返回**
        ;   (float) - ymax - ymin
        self->_data->ymax - self->_data->ymin
    )
    self->area = lambda(()  ; -> float
        ; 返回面积。
        ;
        ; **返回**
        ;   (float) - 宽度乘高度；退化矩形为 0
        (self->_data->xmax - self->_data->xmin)
            * (self->_data->ymax - self->_data->ymin)
    )
    self->perimeter = lambda(()  ; -> float
        ; 返回周长。
        ;
        ; **返回**
        ;   (float) - 2 * (宽 + 高)；退化矩形为 0
        2.0 * (self->width() + self->height())
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
        ;   (Region) - 结果区域；退化 Rect 为空 Region
        let((poly)
            poly = _RectPolygon(self)
            if(poly
                _SizePolygon(poly n_value dir ratio corner miterLimit
                    roundSegments "ycGeom::Rect->size")
                Region(nil)
            )
        )
    )
    self->center = lambda(()  ; -> Point
        ; 返回中心点。
        ;
        ; **返回**
        ;   (Point) - 中心点
        Point(list((self->_data->xmin + self->_data->xmax) / 2.0
            (self->_data->ymin + self->_data->ymax) / 2.0))
    )
    self->centroid = lambda(()  ; -> Point
        ; 返回中心点，语义与 center() 相同。
        ;
        ; **返回**
        ;   (Point) - 中心点
        self->center()
    )
    self->contains = lambda((g_point \@key (boundary "inside") (eps nil) "ggg")  ; -> t | nil
        ; 判断点是否属于矩形。
        ;
        ; **参数**
        ;   g_point   (Point)       - 查询点
        ;   ?boundary (str)         - "inside" 或 "outside"；默认 "inside"
        ;   ?eps      (num|nil)     - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (t|nil) - 属于矩形为 t；边界按 ?boundary 处理
        let((p eps2 on)
            p = _AsPoint(g_point "ycGeom::Rect->contains")
            _BoundaryMode(boundary)
            eps2 = _Eps(eps)
            on = self->onBoundary(p ?eps eps2)
            if(on
                boundary == "inside"
                p->x() >= self->_data->xmin
                    && p->x() <= self->_data->xmax
                    && p->y() >= self->_data->ymin
                    && p->y() <= self->_data->ymax
            )
        )
    )
    self->onBoundary = lambda((g_point \@key (eps nil) "gg")  ; -> t | nil
        ; 判断点是否在矩形边界上。
        ;
        ; **参数**
        ;   g_point  (Point)       - 查询点
        ;   ?eps     (num|nil)     - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (t|nil) - 在边界上为 t
        let((p eps2 x y minx miny maxx maxy on_v on_h inside)
            p = _AsPoint(g_point "ycGeom::Rect->onBoundary")
            eps2 = _Eps(eps)
            x = p->x()
            y = p->y()
            minx = self->_data->xmin
            miny = self->_data->ymin
            maxx = self->_data->xmax
            maxy = self->_data->ymax
            on_v = _Near(x minx eps2) || _Near(x maxx eps2)
            on_h = _Near(y miny eps2) || _Near(y maxy eps2)
            inside = (x >= minx || _Near(x minx eps2))
                && (x <= maxx || _Near(x maxx eps2))
                && (y >= miny || _Near(y miny eps2))
                && (y <= maxy || _Near(y maxy eps2))
            inside && (on_v || on_h)
        )
    )
    self->bBox = lambda(()  ; -> list[list[float]]
        ; 返回包围盒。
        ;
        ; **返回**
        ;   (list[list[float]]) - ((xmin ymin) (xmax ymax))
        list(
            list(self->_data->xmin self->_data->ymin)
            list(self->_data->xmax self->_data->ymax)
        )
    )
    self->or = lambda((g_other \@key (grid nil) (eps nil) "ggg")  ; -> Region
        ; 返回并集。
        ;
        ; **参数**
        ;   g_other  (Polygon|Rect|Region|list) - 另一二维图形或点列
        ;   ?grid    (num|nil)                  - 网格；默认 nil
        ;   ?eps     (num|nil)                  - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (Region) - 并集区域
        _ShapeOp(self g_other 'union grid eps "ycGeom::Rect->or")
    )
    self->and = lambda((g_other \@key (grid nil) (eps nil) "ggg")  ; -> Region
        ; 返回交集。
        ;
        ; **参数**
        ;   g_other  (Polygon|Rect|Region|list) - 另一二维图形或点列
        ;   ?grid    (num|nil)                  - 网格；默认 nil
        ;   ?eps     (num|nil)                  - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (Region) - 交集区域
        _ShapeOp(self g_other 'intersection grid eps "ycGeom::Rect->and")
    )
    self->not = lambda((g_other \@key (grid nil) (eps nil) "ggg")  ; -> Region
        ; 返回二元差集。
        ;
        ; **参数**
        ;   g_other  (Polygon|Rect|Region|list) - 另一二维图形或点列
        ;   ?grid    (num|nil)                  - 网格；默认 nil
        ;   ?eps     (num|nil)                  - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (Region) - A-B 区域
        _ShapeOp(self g_other 'difference grid eps "ycGeom::Rect->not")
    )
    self->xor = lambda((g_other \@key (grid nil) (eps nil) "ggg")  ; -> Region
        ; 返回对称差。
        ;
        ; **参数**
        ;   g_other  (Polygon|Rect|Region|list) - 另一二维图形或点列
        ;   ?grid    (num|nil)                  - 网格；默认 nil
        ;   ?eps     (num|nil)                  - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (Region) - 对称差区域
        _ShapeOp(self g_other 'xor grid eps "ycGeom::Rect->xor")
    )
    self->toPolygon = lambda(()  ; -> Polygon | nil
        ; 转换为四点多边形。
        ;
        ; **返回**
        ;   (Polygon|nil) - 逆时针四角 Polygon；退化矩形 nil
        _RectPolygon(self)
    )
    self->toSkill = lambda(()  ; -> list[list[float]]
        ; 转换为纯坐标列表。
        ;
        ; **返回**
        ;   (list[list[float]]) - ((xmin ymin) (xmax ymax))
        list(
            list(self->_data->xmin self->_data->ymin)
            list(self->_data->xmax self->_data->ymax)
        )
    )
    t
)
)

inScheme(
defmethod(initializeInstance (self(Rect) \@rest _args)
    ; 构造 Rect 实例时安装方法集。
    ;
    ; **参数**
    ;   _args  (list) - 附加初始化参数，本实现忽略
    ;
    ; **返回**
    ;   (t) - 安装完成
    _InstallRect(self)
    t
)
)

procedure(Rect(l_data "l")  ; -> Rect
    ; 构造不可变轴对齐矩形。
    ;
    ; **参数**
    ;   l_data  (list) - 两个对角点、包一层的两点列表或 Point 列表
    ;
    ; **返回**
    ;   (Rect) - 新矩形；两个对角点自动规范化；零宽或零高合法
    let((pts p1 p2 xmin2 ymin2 xmax2 ymax2)
        pts = _TwoPoints(l_data "ycGeom::Rect")
        p1 = _Nth1(1 pts)
        p2 = _Nth1(2 pts)
        xmin2 = min(p1->x() p2->x())
        ymin2 = min(p1->y() p2->y())
        xmax2 = max(p1->x() p2->x())
        ymax2 = max(p1->y() p2->y())
        makeInstance('Rect ?_data
            makeInstance('_RectData
                ?xmin xmin2
                ?ymin ymin2
                ?xmax xmax2
                ?ymax ymax2))
    )
)

unuseNamespace("ycGeom")

; END
