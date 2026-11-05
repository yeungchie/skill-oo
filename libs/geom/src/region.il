useNamespace("ycGeom")

defclass(_RegionData () (
    ; _RegionData 数据桶：收纳互不重叠的 Polygon 列表，构造后禁写。
    polygons(
        \@initarg polygons
        \@initform nil
    )
))

defclass(Region () (
    ; Region 实例：0..n 个 Polygon 的并集。
    ; 状态桶（_RegionData：polygons），构造后禁写
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

procedure(_BBoxNear(l_a l_b n_eps "lln")  ; -> t | nil
    ; 判断两个包围盒是否相交或间距小于容差（内部实现）。
    ;
    ; **参数**
    ;   l_a    (list)  - 包围盒 ((xmin ymin) (xmax ymax))
    ;   l_b    (list)  - 同上
    ;   n_eps  (float) - 容差
    ;
    ; **返回**
    ;   (t|nil) - 可能相交为 t；任一轴分离超过 eps 为 nil
    !(car(cadr(l_a)) + n_eps < car(car(l_b))
        || car(cadr(l_b)) + n_eps < car(car(l_a))
        || cadr(cadr(l_a)) + n_eps < cadr(car(l_b))
        || cadr(cadr(l_b)) + n_eps < cadr(car(l_a)))
)


procedure(_AllApart(l_polys n_eps "ln")  ; -> t | nil
    ; 保守判断多边形集合是否两两分离（内部实现）。
    ;
    ; 包围盒分离则多边形必不相交；任一对包围盒相交或间距小于容差就返回 nil，
    ; 由调用方走完整布尔合并。
    ;
    ; **参数**
    ;   l_polys  (list[Polygon]) - 输入
    ;   n_eps    (float)         - 容差
    ;
    ; **返回**
    ;   (t|nil) - 两两分离为 t
    let((ok boxes)
        ok = t
        boxes = mapcar(lambda((g_p "g") g_p->bBox()) l_polys)
        while(ok && cdr(boxes)
            foreach(b cdr(boxes)
                when(_BBoxNear(car(boxes) b n_eps)
                    ok = nil
                )
            )
            boxes = cdr(boxes)
        )
        ok
    )
)


procedure(_UnionAll(l_polys g_grid n_eps "lgn")  ; -> list[Polygon]
    ; 逐块合并多边形集合。
    ;
    ; **参数**
    ;   l_polys  (list[Polygon]) - 输入
    ;   g_grid   (float|nil)     - 网格
    ;   n_eps    (float)         - 容差
    ;
    ; **返回**
    ;   (list[Polygon]) - 互不重叠的结果
    let((res)
        when(l_polys
            if(_AllApart(l_polys n_eps)
            then
                ; 两两分离：并集就是原集合，省去逐对布尔合并
                res = copy(l_polys)
            else
                res = list(car(l_polys))
                foreach(p cdr(l_polys)
                    res = _Boolean(res list(p) 'union g_grid n_eps)
                )
            )
        )
        res
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
        let((sum comp term next)
            ; 与 perimeter 相同的 Kahan-Babuska-Neumaier 补偿求和：
            ; 小面积多边形不会在大面积累加中被舍入吞掉。
            sum = 0.0
            comp = 0.0
            foreach(p self->_data->polygons
                term = p->area()
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
    self->perimeter = lambda((\@key (includeSeams nil) (eps nil) "gg")  ; -> float
        ; 返回周长和。
        ;
        ; **参数**
        ;   ?includeSeams  (t|nil)   - 是否计入切割线；默认 nil
        ;   ?eps           (num|nil) - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (float) - 周长
        let((sum comp term next eps2)
            _Flag(includeSeams "includeSeams")
            eps2 = _Eps(eps)
            ; Kahan-Babuska-Neumaier 补偿求和：把每步舍入误差留在 n_comp。
            sum = 0.0
            comp = 0.0
            foreach(p self->_data->polygons
                term = p->perimeter(
                    ?includeSeams includeSeams ?eps eps2)
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
    self->centroid = lambda(()  ; -> Point | nil
        ; 返回面积加权质心。
        ;
        ; **返回**
        ;   (Point|nil) - 质心；空区域为 nil
        let((total totalc sx sxc sy syc c p a term next)
            total = 0.0
            totalc = 0.0
            sx = 0.0
            sxc = 0.0
            sy = 0.0
            syc = 0.0
            ; 面积、a*x、a*y 三者量级差极大：共用同一个补偿量会把小项
            ; 的残差混进别的量里，等于没补偿，因此三路各自独立累加与并回。
            foreach(p2 self->_data->polygons
                a = p2->area()
                c = p2->centroid()
                term = a
                next = total + term
                if(abs(total) >= abs(term)
                then
                    totalc = totalc + ((total - next) + term)
                else
                    totalc = totalc + ((term - next) + total)
                )
                total = next
                term = a * c->x()
                next = sx + term
                if(abs(sx) >= abs(term)
                then
                    sxc = sxc + ((sx - next) + term)
                else
                    sxc = sxc + ((term - next) + sx)
                )
                sx = next
                term = a * c->y()
                next = sy + term
                if(abs(sy) >= abs(term)
                then
                    syc = syc + ((sy - next) + term)
                else
                    syc = syc + ((term - next) + sy)
                )
                sy = next
            )
            total = total + totalc
            sx = sx + sxc
            sy = sy + syc
            when(total > 0.0
                Point(list(sx / total sy / total))
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
        let((p eps2 found)
            p = _AsPoint(g_point "ycGeom::Region->contains")
            _BoundaryMode(boundary)
            eps2 = _Eps(eps)
            foreach(poly self->_data->polygons
                when(!found
                    when(poly->contains(p ?boundary boundary ?eps eps2)
                        found = t
                    )
                )
            )
            found
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
        let((p eps2 found)
            p = _AsPoint(g_point "ycGeom::Region->onBoundary")
            _Flag(includeSeams "includeSeams")
            eps2 = _Eps(eps)
            foreach(poly self->_data->polygons
                when(!found
                    when(poly->onBoundary(p
                        ?includeSeams includeSeams ?eps eps2)
                        found = t
                    )
                )
            )
            found
        )
    )
    self->bBox = lambda(()  ; -> list[list[float]] | nil
        ; 返回包围盒并集。
        ;
        ; **返回**
        ;   (list[list[float]]|nil) - ((xmin ymin) (xmax ymax))；空区域 nil
        let((box b)
            foreach(p self->_data->polygons
                b = p->bBox()
                if(box == nil
                    box = copy(b)
                    box = list(
                        list(
                            min(car(car(box)) car(car(b)))
                            min(cadr(car(box)) cadr(car(b)))
                        )
                        list(
                            max(car(cadr(box)) car(cadr(b)))
                            max(cadr(cadr(box)) cadr(cadr(b)))
                        )
                    )
                )
            )
            box
        )
    )
    self->toRect = lambda(()  ; -> Rect | nil
        ; 返回包围矩形。
        ;
        ; **返回**
        ;   (Rect|nil) - 由 bBox 构造的轴对齐矩形；空区域 nil
        let((box)
            box = self->bBox()
            when(box Rect(box))
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
        _ShapeOp(self g_other 'union grid eps "ycGeom::Region->or")
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
        _ShapeOp(self g_other 'intersection grid eps "ycGeom::Region->and")
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
        _ShapeOp(self g_other 'difference grid eps "ycGeom::Region->not")
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
        _ShapeOp(self g_other 'xor grid eps "ycGeom::Region->xor")
    )
    self->toSkill = lambda(()  ; -> list | nil
        ; 转换为 SKILL 原生区域列表。
        ;
        ; **返回**
        ;   (list|nil) - 每个 Polygon 一个坐标点列；空区域 nil
        let((res)
            foreach(p self->_data->polygons
                res = tconc(res p->toSkill())
            )
            car(res)
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
    ; ?normalize nil 时成员原样保留，面积按各块求和；布尔运算不受影响，
    ; 两侧成员在运算前一律按 or 合并。
    ;
    ; **参数**
    ;   l_polygons  (list[Polygon]|nil) - 多边形列表或点列；nil 表示空区域
    ;   ?normalize  (t|nil)             - 是否归一化为互不重叠；默认 t
    ;   ?grid       (num|nil)           - 布尔网格；默认 nil
    ;   ?eps        (num|nil)           - 容差；默认 nil（1e-9）
    ;
    ; **返回**
    ;   (Region) - 新区域；非法参数 error
    let((polys grid2 eps2)
        _Flag(normalize "normalize")
        grid2 = _Grid(grid)
        eps2 = _Eps(eps)
        polys = _AsPolygonList(l_polygons "ycGeom::Region")
        when(normalize && polys
            polys = _UnionAll(polys grid2 eps2)
            polys = _CleanPolygons(polys eps2)
        )
        makeInstance('Region ?_data
            makeInstance('_RegionData ?polygons polys))
    )
)

unuseNamespace("ycGeom")

; END
