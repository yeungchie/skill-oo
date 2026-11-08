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

defclass(_PolygonData () (
    ; _PolygonData 数据桶：只收纳 keyhole 点列，构造后禁写。
    points(
        \@initarg points
        \@initform nil
    )
))

defclass(Polygon () (
    ; Polygon 实例：不可变 keyhole 多边形。
    ; 状态桶（_PolygonData：points），构造后禁写
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
    toPath()
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
    let((len idx prev cur first rest seams scale tol
            edges a b c d seam ei ej
            ex0 ey0 ex1 ey1 fx0 fy0 fx1 fy1)
        unless(listp(l_points)
            error("ycGeom::Polygon: expected a list of Points, got %A" l_points)
        )
        len = length(l_points)
        unless(len >= 3
            error("ycGeom::Polygon: at least 3 points are required")
        )
        idx = 0
        foreach(p l_points
            idx++
            unless(_PointP(p)
                error("ycGeom::Polygon: element %d is not a Point: %A" idx p)
            )
        )
        ; 连续重复点：沿链遍历，最后补首尾相接的一对
        first = car(l_points)
        prev = first
        rest = cdr(l_points)
        idx = 1
        while(rest
            cur = car(rest)
            when(_Near(prev->x() cur->x() n_eps)
                && _Near(prev->y() cur->y() n_eps)
                error("ycGeom::Polygon: consecutive duplicate point at index %d"
                    idx + 1)
            )
            prev = cur
            rest = cdr(rest)
            idx++
        )
        when(_Near(prev->x() first->x() n_eps)
            && _Near(prev->y() first->y() n_eps)
            error("ycGeom::Polygon: consecutive duplicate point at index 1")
        )
        when(abs(_SignedArea(l_points)) <= _AreaTol(l_points n_eps)
            error("ycGeom::Polygon: zero-area point sequence")
        )
        seams = _SeamKeys(l_points)
        ; 端点重合与线段相交的有效容差约 max(eps, 1e-15 * 坐标量级)；
        ; 包围盒按它外扩后预筛，不会漏掉可能相交的边对。
        scale = 0.0
        foreach(p l_points
            scale = max(scale max(abs(p->x()) abs(p->y())))
        )
        tol = max(n_eps 1e-15 * scale)
        ; 一次遍历建立边表：(起点 终点 minX minY maxX maxY 是否切割边)
        a = first
        cur = cdr(l_points)
        idx = 0
        while(idx < len
            b = if(cur car(cur) first)
            seam = seams[_EdgeKey(a b)] == 2
            when(seam
                unless(_Near(a->x() b->x() n_eps)
                    || _Near(a->y() b->y() n_eps)
                    error("ycGeom::Polygon: seam must be horizontal or vertical")
                )
            )
            edges = tconc(edges (list a b
                min(a->x() b->x()) min(a->y() b->y())
                max(a->x() b->x()) max(a->y() b->y())
                seam))
            a = b
            cur = if(cur cdr(cur) nil)
            idx++
        )
        edges = car(edges)
        ; 全体非切割边两两校验：包围盒不相交的边对先跳过
        while(edges
            ei = car(edges)
            unless(nth(6 ei)
                a = car(ei)
                b = cadr(ei)
                ex0 = nth(2 ei)
                ey0 = nth(3 ei)
                ex1 = nth(4 ei)
                ey1 = nth(5 ei)
                foreach(ej cdr(edges)
                    unless(nth(6 ej)
                        fx0 = nth(2 ej)
                        fy0 = nth(3 ej)
                        fx1 = nth(4 ej)
                        fy1 = nth(5 ej)
                        when(ex0 <= fx1 + tol && fx0 <= ex1 + tol
                            && ey0 <= fy1 + tol && fy0 <= ey1 + tol
                            c = car(ej)
                            d = cadr(ej)
                            unless(_SamePoint(a c n_eps)
                                || _SamePoint(a d n_eps)
                                || _SamePoint(b c n_eps)
                                || _SamePoint(b d n_eps)
                                when(_SegmentsCross(a b c d n_eps)
                                    error("ycGeom::Polygon: non-seam edges intersect")
                                )
                            )
                        )
                    )
                )
            )
            edges = cdr(edges)
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

procedure(_ShapePolys(g_left g_other s_op g_grid n_eps t_ctx "ggsgnt")  ; -> list[Polygon]
    ; 布尔运算的公共管线：归一化两侧、计算、清理共线点（内部实现）。
    ;
    ; 两侧各自先按 or 合并（成员重叠时不会退化成奇偶规则），
    ; 方法层 _ShapeOp 与纯数据层 ycGeom::Boolean 都从这里取结果，
    ; 「归一化 + _Boolean + 清理」只有这一份实现。
    ;
    ; **参数**
    ;   g_left   (any)       - 左操作数：Polygon/Rect/Region/点列
    ;   g_other  (any)       - 右操作数：Polygon/Rect/Region/点列
    ;   s_op     (sym)       - union/intersection/difference/xor
    ;   g_grid   (float|nil) - 网格
    ;   n_eps    (float)     - 容差（已规范化）
    ;   t_ctx    (str)       - 错误上下文
    ;
    ; **返回**
    ;   (list[Polygon]) - 结果多边形；空结果 nil
    _CleanPolygons(
        _Boolean(
            _UnionAll(_AsPolygons(g_left t_ctx) g_grid n_eps)
            _UnionAll(_AsPolygons(g_other t_ctx) g_grid n_eps)
            s_op g_grid n_eps)
        _Eps(n_eps)
    )
)

procedure(_ShapeOp(g_left g_other s_op g_grid g_eps t_ctx "ggsggt")  ; -> Region
    ; 把布尔结果包成 Region（内部实现）。
    ;
    ; **参数**
    ;   g_left   (any)       - 左操作数：Polygon/Rect/Region/点列
    ;   g_other  (any)       - 右操作数：Polygon/Rect/Region/点列
    ;   s_op     (sym)       - union/intersection/difference/xor
    ;   g_grid   (float|nil) - 网格
    ;   g_eps    (float|nil) - 容差；nil 用默认值
    ;   t_ctx    (str)       - 错误上下文
    ;
    ; **返回**
    ;   (Region) - 结果区域
    let((grid eps)
        grid = _Grid(g_grid)
        eps = _Eps(g_eps)
        Region(_ShapePolys(g_left g_other s_op grid eps t_ctx)
            ?normalize nil)
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
        let((res len i)
            len = length(self->_data->points)
            for(i2 1 len
                res = tconc(res Segment(list(
                    _Nth1(i2 self->_data->points)
                    _Nth1(if(i2 == len 1 (i2 + 1)) self->_data->points)
                )))
            )
            car(res)
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
        let((eps2 len i a b seams sum comp term next seam)
            _Flag(includeSeams "includeSeams")
            eps2 = _Eps(eps)
            seams = _SeamKeys(self->_data->points)
            len = length(self->_data->points)
            ; Kahan-Babuska-Neumaier 补偿求和：把每步舍入误差留在 comp。
            sum = 0.0
            comp = 0.0
            for(i2 1 len
                a = _Nth1(i2 self->_data->points)
                b = _Nth1(if(i2 == len 1 (i2 + 1)) self->_data->points)
                seam = seams[_EdgeKey(a b)] == 2
                unless(seam && !includeSeams
                    term = Segment(list(a b))->length()
                    next = sum + term
                    if(abs(sum) >= abs(term)
                    then
                        comp = comp + ((sum - next) + term)
                    else
                        comp = comp + ((term - next) + sum)
                    )
                    sum = next
                )
            )
            sum + comp
        )
    )
    self->centroid = lambda(()  ; -> Point
        ; 返回面积加权质心。
        ;
        ; **返回**
        ;   (Point) - 质心；零面积 error
        let((len i a b cross a2 cx cy ox oy)
            len = length(self->_data->points)
            a2 = 0.0
            cx = 0.0
            cy = 0.0
            ox = car(self->_data->points)->x()
            oy = car(self->_data->points)->y()
            for(i2 1 len
                a = _Nth1(i2 self->_data->points)
                b = _Nth1(if(i2 == len 1 (i2 + 1)) self->_data->points)
                cross = (a->x() - ox) * (b->y() - oy)
                    - (b->x() - ox) * (a->y() - oy)
                a2 = a2 + cross
                cx = cx
                    + ((a->x() - ox) + (b->x() - ox)) * cross
                cy = cy
                    + ((a->y() - oy) + (b->y() - oy)) * cross
            )
            a2 = a2 / 2.0
            when(abs(a2) <= _AreaTol(self->_data->points _Eps(nil))
                error("ycGeom::Polygon->centroid: zero-area polygon")
            )
            Point(list(ox + cx / (6.0 * a2)
                oy + cy / (6.0 * a2)))
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
        let((p eps2 len i a b seams boundary2)
            p = _AsPoint(g_point "ycGeom::Polygon->contains")
            _BoundaryMode(boundary)
            eps2 = _Eps(eps)
            seams = _SeamKeys(self->_data->points)
            len = length(self->_data->points)
            for(i2 1 len
                a = _Nth1(i2 self->_data->points)
                b = _Nth1(if(i2 == len 1 (i2 + 1)) self->_data->points)
                unless(seams[_EdgeKey(a b)] == 2
                    when(_OnSegment(a b p eps2)
                        boundary2 = t
                    )
                )
            )
            if(boundary2
                boundary == "inside"
                _PointInRing(self->_data->points p eps2)
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
        let((p eps2 seams len i a b found)
            p = _AsPoint(g_point "ycGeom::Polygon->onBoundary")
            _Flag(includeSeams "includeSeams")
            eps2 = _Eps(eps)
            seams = _SeamKeys(self->_data->points)
            len = length(self->_data->points)
            for(i2 1 len
                when(!found
                    a = _Nth1(i2 self->_data->points)
                    b = _Nth1(if(i2 == len 1 (i2 + 1)) self->_data->points)
                    unless(seams[_EdgeKey(a b)] == 2 && !includeSeams
                        when(_OnSegment(a b p eps2)
                            found = t
                        )
                    )
                )
            )
            found
        )
    )
    self->bBox = lambda(()  ; -> list[list[float]]
        ; 返回包围盒。
        ;
        ; **返回**
        ;   (list[list[float]]) - ((xmin ymin) (xmax ymax))
        let((xmin ymin xmax ymax i p)
            xmin = _Nth1(1 self->_data->points)->x()
            ymin = _Nth1(1 self->_data->points)->y()
            xmax = xmin
            ymax = ymin
            for(i2 2 length(self->_data->points)
                p = _Nth1(i2 self->_data->points)
                xmin = min(xmin p->x())
                ymin = min(ymin p->y())
                xmax = max(xmax p->x())
                ymax = max(ymax p->y())
            )
            list(list(xmin ymin) list(xmax ymax))
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
        let((eps2)
            eps2 = _Eps(eps)
            _SignedArea(self->_data->points) < -_AreaTol(self->_data->points eps2)
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
        let((res)
            foreach(p self->_data->points
                res = tconc(res p->toSkill())
            )
            car(res)
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
    _InstallPolygonToPath(self)
    t
)
)
procedure(Polygon(l_points "l")  ; -> Polygon
    ; 构造不可变 keyhole 多边形。
    ;
    ; **参数**
    ;   l_points  (list) - Point 列表或 (x y) 列表；不接受扁平数值坐标
    ;
    ; **返回**
    ;   (Polygon) - 复制外层点列的新多边形；非法点列 error
    let((pts canon reg eps2)
        eps2 = _Eps(nil)
        pts = _AsPointList(l_points "ycGeom::Polygon")
        _CheckPolygon(pts eps2)
        reg = makeTable("geomPolygonCanon" nil)
        canon = _CanonRing(pts eps2 reg)
        ; 规范化没有改动点列时，等价输入已校验过，跳过第二次全量校验
        unless(equal(canon pts)
            _CheckPolygon(canon eps2)
        )
        makeInstance('Polygon ?_data
            makeInstance('_PolygonData ?points copy(canon)))
    )
)

unuseNamespace("ycGeom")

; END
