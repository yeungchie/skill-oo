useNamespace("ycGeom")

defclass(RegionData () (
    ; RegionData 数据桶：收纳互不重叠的 Polygon 列表，构造后禁写。
    polygons(
        \@initarg polygons
        \@initform nil
    )
))

defclass(Region () (
    ; Region 实例：0..n 个 Polygon 的并集。
    ; 状态桶（RegionData：polygons），构造后禁写
    _data(
        \@initarg _data
        \@initform nil
    )

    polygons()
    area()
    perimeter()
    centroid()
    contains()
    onBoundary()
    bBox()
    toRect()
    isEmpty()
    size()
    or()
    and()
    not()
    xor()
    toSkill()
))

defmethod(printself (self(Region))  ; -> str
    ; 返回 Region 的打印描述串。
    ;
    ; **返回**
    ;   (str) - <ycGeom::Region polygons=N>
    lsprintf("<%A polygons=%d>" className(self) length(self->_data->polygons))
)

procedure(_UnionAll(l_polys n_grid n_eps "lgg")  ; -> list[Polygon]
    ; 逐块合并多边形集合。
    ;
    ; **参数**
    ;   l_polys  (list[Polygon]) - 输入
    ;   n_grid   (float|nil)     - 网格
    ;   n_eps    (float)         - 容差
    ;
    ; **返回**
    ;   (list[Polygon]) - 互不重叠的结果
    let((l_res)
        when(l_polys
            l_res = list(car(l_polys))
            foreach(g_p cdr(l_polys)
                l_res = _Boolean(l_res list(g_p) 'union n_grid n_eps)
            )
        )
        l_res
    )
)

inScheme(
procedure(_InstallRegion(self "g")  ; -> t
    ; 把 Region 方法安装到 Region 类（由 initializeInstance 调用）。
    ;
    ; **返回**
    ;   (t) - 安装完成；调用方忽略
    self->polygons = lambda(()  ; -> list[Polygon]
        ; 返回内部 Polygon 列表。
        ;
        ; **返回**
        ;   (list[Polygon]) - 内部列表，不得原地修改
        self->_data->polygons
    )
    self->area = lambda(()  ; -> float
        ; 返回面积和。
        ;
        ; **返回**
        ;   (float) - 面积
        let((n_sum)
            n_sum = 0.0
            foreach(g_p self->_data->polygons
                n_sum = n_sum + g_p->area()
            )
            n_sum
        )
    )
    self->perimeter = lambda((\@key (includeSeams nil) (eps nil) "gg")  ; -> float
        ; 返回周长和。
        ;
        ; **参数**
        ;   ?includeSeams  (t|nil)   - 是否计入切割线；默认 nil
        ;   ?eps           (num|nil) - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (float) - 周长
        let((n_sum n_eps)
            _Flag(includeSeams "includeSeams")
            n_eps = _Eps(eps)
            n_sum = 0.0
            foreach(g_p self->_data->polygons
                n_sum = n_sum + g_p->perimeter(
                    ?includeSeams includeSeams ?eps n_eps)
            )
            n_sum
        )
    )
    self->centroid = lambda(()  ; -> Point | nil
        ; 返回面积加权质心。
        ;
        ; **返回**
        ;   (Point|nil) - 质心；空区域为 nil
        let((n_total n_sx n_sy g_c g_p n_a)
            n_total = 0.0
            n_sx = 0.0
            n_sy = 0.0
            foreach(g_p self->_data->polygons
                n_a = g_p->area()
                g_c = g_p->centroid()
                n_total = n_total + n_a
                n_sx = n_sx + n_a * g_c->x()
                n_sy = n_sy + n_a * g_c->y()
            )
            when(n_total > 0.0
                Point(n_sx / n_total n_sy / n_total)
            )
        )
    )
    self->contains = lambda((g_point \@key (boundary "inside") (eps nil) "ggg")  ; -> t | nil
        ; 判断点是否属于区域。
        ;
        ; **参数**
        ;   g_point   (Point)       - 待判断点
        ;   ?boundary (str)         - "inside" 或 "outside"；默认 "inside"
        ;   ?eps      (num|nil)     - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (t|nil) - 属于区域为 t
        let((g_p n_eps g_found)
            g_p = _AsPoint(g_point "ycGeom::Region->contains")
            _BoundaryMode(boundary)
            n_eps = _Eps(eps)
            foreach(g_poly self->_data->polygons
                when(!g_found
                    when(g_poly->contains(g_p ?boundary boundary ?eps n_eps)
                        g_found = t
                    )
                )
            )
            g_found
        )
    )
    self->onBoundary = lambda((g_point \@key (includeSeams nil) (eps nil) "ggg")  ; -> t | nil
        ; 判断点是否在区域边界上。
        ;
        ; **参数**
        ;   g_point        (Point)   - 查询点
        ;   ?includeSeams  (t|nil)   - 是否计入切割线；默认 nil
        ;   ?eps           (num|nil) - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (t|nil) - 在边界上为 t
        let((g_p n_eps g_found)
            g_p = _AsPoint(g_point "ycGeom::Region->onBoundary")
            _Flag(includeSeams "includeSeams")
            n_eps = _Eps(eps)
            foreach(g_poly self->_data->polygons
                when(!g_found
                    when(g_poly->onBoundary(g_p
                        ?includeSeams includeSeams ?eps n_eps)
                        g_found = t
                    )
                )
            )
            g_found
        )
    )
    self->bBox = lambda(()  ; -> list[list[float]] | nil
        ; 返回包围盒并集。
        ;
        ; **返回**
        ;   (list[list[float]]|nil) - ((xmin ymin) (xmax ymax))；空区域 nil
        let((l_box l_b)
            foreach(g_p self->_data->polygons
                l_b = g_p->bBox()
                if(l_box == nil
                    l_box = copy(l_b)
                    l_box = list(
                        list(
                            min(car(car(l_box)) car(car(l_b)))
                            min(cadr(car(l_box)) cadr(car(l_b)))
                        )
                        list(
                            max(car(cadr(l_box)) car(cadr(l_b)))
                            max(cadr(cadr(l_box)) cadr(cadr(l_b)))
                        )
                    )
                )
            )
            l_box
        )
    )
    self->toRect = lambda(()  ; -> Rect | nil
        ; 返回包围矩形。
        ;
        ; **返回**
        ;   (Rect|nil) - 由 bBox 构造的轴对齐矩形；空区域 nil
        let((l_box)
            l_box = self->bBox()
            when(l_box Rect(l_box))
        )
    )
    self->isEmpty = lambda(()  ; -> t | nil
        ; 判断是否为空区域。
        ;
        ; **返回**
        ;   (t|nil) - 无 Polygon 为 t
        self->_data->polygons == nil
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
        _SizeRegion(self->_data->polygons n_value dir ratio corner
            miterLimit roundSegments)
    )
    self->or = lambda((g_other \@key (grid nil) (eps nil) "ggg")  ; -> Region
        ; 返回并集。
        ;
        ; **参数**
        ;   g_other  (Region|Polygon|Rect|list) - 另一二维图形或点列
        ;   ?grid    (num|nil)    - 网格；默认 nil
        ;   ?eps     (num|nil)    - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (Region) - 新区域
        let((g_o l_res)
            g_o = _AsRegion(g_other "ycGeom::Region->or")
            l_res = _Boolean(self->_data->polygons g_o->polygons()
                'union _Grid(grid) _Eps(eps))
            Region(l_res ?normalize nil)
        )
    )
    self->and = lambda((g_other \@key (grid nil) (eps nil) "ggg")  ; -> Region
        ; 返回交集。
        ;
        ; **参数**
        ;   g_other  (Region|Polygon|Rect|list) - 另一二维图形或点列
        ;   ?grid    (num|nil)    - 网格；默认 nil
        ;   ?eps     (num|nil)    - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (Region) - 新区域
        let((g_o l_res)
            g_o = _AsRegion(g_other "ycGeom::Region->and")
            l_res = _Boolean(self->_data->polygons g_o->polygons()
                'intersection _Grid(grid) _Eps(eps))
            Region(l_res ?normalize nil)
        )
    )
    self->not = lambda((g_other \@key (grid nil) (eps nil) "ggg")  ; -> Region
        ; 返回 A-B。
        ;
        ; **参数**
        ;   g_other  (Region|Polygon|Rect|list) - 另一二维图形或点列
        ;   ?grid    (num|nil)    - 网格；默认 nil
        ;   ?eps     (num|nil)    - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (Region) - 新区域
        let((g_o l_res)
            g_o = _AsRegion(g_other "ycGeom::Region->not")
            l_res = _Boolean(self->_data->polygons g_o->polygons()
                'difference _Grid(grid) _Eps(eps))
            Region(l_res ?normalize nil)
        )
    )
    self->xor = lambda((g_other \@key (grid nil) (eps nil) "ggg")  ; -> Region
        ; 返回对称差。
        ;
        ; **参数**
        ;   g_other  (Region|Polygon|Rect|list) - 另一二维图形或点列
        ;   ?grid    (num|nil)    - 网格；默认 nil
        ;   ?eps     (num|nil)    - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (Region) - 新区域
        let((g_o l_res)
            g_o = _AsRegion(g_other "ycGeom::Region->xor")
            l_res = _Boolean(self->_data->polygons g_o->polygons()
                'xor _Grid(grid) _Eps(eps))
            Region(l_res ?normalize nil)
        )
    )
    self->toSkill = lambda(()  ; -> list | nil
        ; 转换为 SKILL 原生区域列表。
        ;
        ; **返回**
        ;   (list|nil) - 每个 Polygon 一个坐标点列；空区域 nil
        let((l_res)
            foreach(g_p self->_data->polygons
                l_res = tconc(l_res g_p->toSkill())
            )
            car(l_res)
        )
    )
    t
)
)

inScheme(
defmethod(initializeInstance (self(Region) \@rest _args)
    ; 构造 Region 实例时安装方法集。
    ;
    ; **参数**
    ;   _args  (list) - 附加初始化参数，本实现忽略
    ;
    ; **返回**
    ;   (t) - 安装完成
    _InstallRegion(self)
    t
)
)

procedure(Region(l_polygons \@key (normalize t) (grid nil) (eps nil) "lggg")  ; -> Region
    ; 构造不可变区域。
    ;
    ; **参数**
    ;   l_polygons  (list[Polygon]|nil) - 多边形列表；nil 表示空区域
    ;   ?normalize  (t|nil)             - 是否归一化为互不重叠；默认 t
    ;   ?grid       (num|nil)           - 布尔网格；默认 nil
    ;   ?eps        (num|nil)           - 容差；默认 nil（1e-9）
    ;
    ; **返回**
    ;   (Region) - 新区域；非法参数 error
    let((t_polys n_grid n_eps)
        _Flag(normalize "normalize")
        n_grid = _Grid(grid)
        n_eps = _Eps(eps)
        t_polys = _AsPolygonList(l_polygons "ycGeom::Region")
        when(normalize && t_polys
            t_polys = _UnionAll(t_polys n_grid n_eps)
        )
        makeInstance('Region ?_data
            makeInstance('RegionData ?polygons t_polys))
    )
)

unuseNamespace("ycGeom")

; END
