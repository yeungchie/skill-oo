useNamespace("ycGeom")

procedure(_Eps(g_eps "g")  ; -> float
    ; 规范 ?eps 选项。
    ;
    ; **参数**
    ;   g_eps  (num|nil) - 容差；nil 用默认值
    ;
    ; **返回**
    ;   (float) - 正 flonum；非法值 error
    cond(
        (g_eps == nil 1e-9)
        (numberp(g_eps) && g_eps > 0.0 float(g_eps))
        (t error("ycGeom: ?eps must be a positive number, got %A" g_eps))
    )
)

procedure(_AngleTol()  ; -> float
    ; 返回方向与角度判定的容差。
    ;
    ; **返回**
    ;   (float) - 弧度容差 1e-12
    1e-12
)

procedure(_Grid(g_grid "g")  ; -> float | nil
    ; 规范 ?grid 选项。
    ;
    ; **参数**
    ;   g_grid  (num|nil) - 网格间距；nil 表示不吸附
    ;
    ; **返回**
    ;   (float|nil) - 正 flonum 或 nil；非法值 error
    cond(
        (g_grid == nil nil)
        (numberp(g_grid) && g_grid > 0.0 float(g_grid))
        (t error("ycGeom: ?grid must be a positive number, got %A" g_grid))
    )
)

procedure(_SnapRound(n_q "n")  ; -> float
    ; 返回 double 精度的最近整数，平局远离零并修正表示误差。
    ;
    ; **参数**
    ;   n_q  (num) - 待取整值
    ;
    ; **返回**
    ;   (float) - 最近整数；全程不经过 fixnum，避免大数截断
    let((qv base frac adj)
        qv = float(n_q)
        ; %.0f 先给出 double 整数（半偶）；只有落在向零一侧的
        ; 近半格值时，再用 round2(小数部分) 修正到远离零一侧。
        ; 已知边界：round2 的半格判定窗口约 2e-7，表示误差使极靠近
        ; 半格的值仍按较远一侧取整；double 下不可细分，故不加额外修正。
        base = atof(lsprintf("%.0f" qv))
        frac = qv - base
        when(abs(base) < abs(qv)
            adj = round2(frac)
            when(adj != 0
                base = base + float(adj)
            )
        )
        if(base == 0.0 0.0 base)
    )
)

procedure(_Snap(n_val g_grid "ng")  ; -> float
    ; 将数值吸附到网格。
    ;
    ; **参数**
    ;   n_val   (num)        - 原值
    ;   g_grid  (float|nil)  - 网格间距；nil 原样转 float
    ;
    ; **返回**
    ;   (float) - 吸附后的 flonum
    if(g_grid == nil
        float(n_val)
        float(_SnapRound(float(n_val) / g_grid) * g_grid)
    )
)

procedure(_Nth1(n_idx l_list "xl")  ; -> any
    ; 返回列表的 1-based 元素（内部实现）。
    ;
    ; **参数**
    ;   n_idx   (int)  - 1-based 下标
    ;   l_list  (list) - 源列表
    ;
    ; **返回**
    ;   (any) - 元素；越界为 nil
    nth(n_idx - 1 l_list)
)

procedure(_Near(n_a n_b n_eps "nnn")  ; -> t | nil
    ; 判断两个数值是否在绝对或相对容差内。
    ;
    ; **参数**
    ;   n_a    (num) - 值一
    ;   n_b    (num) - 值二
    ;   n_eps  (num) - 绝对容差
    ;
    ; **返回**
    ;   (t|nil) - 差值不超过绝对容差或机器精度相对容差为 t
    let((fa fb diff rel)
        fa = float(n_a)
        fb = float(n_b)
        diff = abs(fa - fb)
        rel = 1e-15 * max(abs(fa) abs(fb))
        diff <= max(float(n_eps) rel)
    )
)

procedure(_SamePoint(g_a g_b n_eps "ggn")  ; -> t | nil
    ; 判断两个点是否在容差内重合。
    ;
    ; **参数**
    ;   g_a    (Point) - 点一
    ;   g_b    (Point) - 点二
    ;   n_eps  (float) - 容差
    ;
    ; **返回**
    ;   (t|nil) - 两点坐标均在容差内为 t
    _Near(g_a->x() g_b->x() n_eps)
        && _Near(g_a->y() g_b->y() n_eps)
)

procedure(_PointP(g_x "g")  ; -> t | nil
    ; 判断对象是否为 Point（内部实现）。
    ;
    ; **参数**
    ;   g_x  (any) - 待判断对象
    ;
    ; **返回**
    ;   (t|nil) - 是 Point 为 t
    classOf(g_x) == findClass('ycGeom::Point)
)

procedure(_SegmentP(g_x "g")  ; -> t | nil
    ; 判断对象是否为 Segment（内部实现）。
    ;
    ; **参数**
    ;   g_x  (any) - 待判断对象
    ;
    ; **返回**
    ;   (t|nil) - 是 Segment 为 t
    classOf(g_x) == findClass('ycGeom::Segment)
)

procedure(_LineP(g_x "g")  ; -> t | nil
    ; 判断对象是否为 Line（内部实现）。
    ;
    ; **参数**
    ;   g_x  (any) - 待判断对象
    ;
    ; **返回**
    ;   (t|nil) - 是 Line 为 t
    classOf(g_x) == findClass('ycGeom::Line)
)

procedure(_RectP(g_x "g")  ; -> t | nil
    ; 判断对象是否为 Rect（内部实现）。
    ;
    ; **参数**
    ;   g_x  (any) - 待判断对象
    ;
    ; **返回**
    ;   (t|nil) - 是 Rect 为 t
    classOf(g_x) == findClass('ycGeom::Rect)
)

procedure(_PolygonP(g_x "g")  ; -> t | nil
    ; 判断对象是否为 Polygon（内部实现）。
    ;
    ; **参数**
    ;   g_x  (any) - 待判断对象
    ;
    ; **返回**
    ;   (t|nil) - 是 Polygon 为 t
    classOf(g_x) == findClass('ycGeom::Polygon)
)

procedure(_RegionP(g_x "g")  ; -> t | nil
    ; 判断对象是否为 Region（内部实现）。
    ;
    ; **参数**
    ;   g_x  (any) - 待判断对象
    ;
    ; **返回**
    ;   (t|nil) - 是 Region 为 t
    classOf(g_x) == findClass('ycGeom::Region)
)

procedure(_PairP(g_x "g")  ; -> t | nil
    ; 判断是否为二元数值列表（内部实现）。
    ;
    ; **参数**
    ;   g_x  (any) - 待判断对象
    ;
    ; **返回**
    ;   (t|nil) - 长度为 2 且两项都是数值为 t
    listp(g_x) && length(g_x) == 2
        && numberp(car(g_x)) && numberp(cadr(g_x))
)

procedure(_PointAt(n_x n_y "nn")  ; -> Point
    ; 用已校验坐标直接构造 Point（内部实现）。
    ;
    ; **参数**
    ;   n_x  (num) - x 坐标
    ;   n_y  (num) - y 坐标
    ;
    ; **返回**
    ;   (Point) - 新点
    makeInstance('Point ?_data
        makeInstance('_PointData ?x float(n_x) ?y float(n_y)))
)

procedure(_AsPoint(g_x t_ctx "gt")  ; -> Point
    ; 归一化为 Point：接受 Point、(x y) 或任意层嵌套列表。
    ;
    ; **参数**
    ;   g_x    (any) - Point 或 (x y)
    ;   t_ctx  (str) - 错误上下文
    ;
    ; **返回**
    ;   (Point) - 归一化后的点；无法识别时 error
    cond(
        (_PointP(g_x) g_x)
        (_PairP(g_x) _PointAt(car(g_x) cadr(g_x)))
        ((listp(g_x) && length(g_x) == 1)
            _AsPoint(car(g_x) t_ctx))
        (t error("%s: expected a Point or (x y) list, got %A" t_ctx g_x))
    )
)

procedure(_AsPointList(l_data t_ctx "lt")  ; -> list[Point]
    ; 归一化点列：只接受 Point/(x y) 与任意层嵌套列表。
    ;
    ; **参数**
    ;   l_data  (list) - 点列或嵌套列表
    ;   t_ctx   (str)  - 错误上下文
    ;
    ; **返回**
    ;   (list[Point]) - 归一化点列；格式不合法时 error
    let((res2 rest)
        when(l_data
            unless(listp(l_data)
                error("%s: expected a point list, got %A" t_ctx l_data)
            )
            if(length(l_data) == 1
                    && listp(car(l_data))
                    && !_PairP(car(l_data))
                    && !_PointP(car(l_data))
            then
                _AsPointList(car(l_data) t_ctx)
            else
                rest = l_data
                while(rest
                    cond(
                        (_PointP(car(rest))
                            res2 = tconc(res2 car(rest))
                            rest = cdr(rest)
                        )
                        (_PairP(car(rest))
                            res2 = tconc(res2
                                _PointAt(car(car(rest))
                                    cadr(car(rest))))
                            rest = cdr(rest)
                        )
                        (t
                            error("%s: expected a Point or (x y) list, got %A"
                                t_ctx car(rest))
                        )
                    )
                )
                car(res2)
            )
        )
    )
)

procedure(_TwoPoints(l_data t_ctx "lt")  ; -> list[Point]
    ; 归一化“两点”构造参数：只接受一个点列表。
    ;
    ; **参数**
    ;   l_data  (list) - 两点列表或任意层嵌套列表
    ;   t_ctx   (str)  - 错误上下文
    ;
    ; **返回**
    ;   (list[Point]) - 两个点；格式不合法时 error
    let((pts2)
        pts2 = errset(_AsPointList(l_data t_ctx) nil)
        cond(
            ((pts2 && car(pts2) && length(car(pts2)) == 2)
                car(pts2)
            )
            (t
                error("%s: expected a two-point list, got %A"
                    t_ctx l_data)
            )
        )
    )
)

procedure(_AsPolygonList(l_data t_ctx "lt")  ; -> list[Polygon]
    ; 归一化多边形列表：接受 Polygon/Rect/Region/点列或任意层嵌套列表。
    ;
    ; **参数**
    ;   l_data  (list) - Polygon 列表或点列列表
    ;   t_ctx   (str)  - 错误上下文
    ;
    ; **返回**
    ;   (list[Polygon]) - 归一化多边形列表；格式不合法时 error
    let((res2 pts2 nested poly2)
        when(l_data
            unless(listp(l_data)
                error("%s: expected a Polygon list, got %A" t_ctx l_data)
            )
            foreach(item l_data
                cond(
                    (_PolygonP(item)
                        res2 = tconc(res2 item)
                    )
                    (_RectP(item)
                        poly2 = _RectPolygon(item)
                        when(poly2
                            res2 = tconc(res2 poly2)
                        )
                    )
                    (_RegionP(item)
                        foreach(poly3 item->polygons()
                            res2 = tconc(res2 poly3)
                        )
                    )
                    (listp(item)
                        pts2 = errset(_AsPointList(item t_ctx) nil)
                        cond(
                            ((pts2 && car(pts2))
                                pts2 = car(pts2)
                                cond(
                                    ((length(pts2) == 2)
                                        poly2 = _RectPolygon(Rect(pts2))
                                        when(poly2
                                            res2 = tconc(res2 poly2)
                                        )
                                    )
                                    ((length(pts2) >= 3)
                                        res2 = tconc(res2 Polygon(pts2))
                                    )
                                    (t
                                        error("%s: expected a Polygon, Rect, Region, or point list, got %A"
                                            t_ctx item)
                                    )
                                )
                            )
                            (t
                                nested = errset(_AsPolygonList(item t_ctx) nil)
                                if(nested && car(nested)
                                then
                                    foreach(poly3 car(nested)
                                        res2 = tconc(res2 poly3)
                                    )
                                else
                                    error("%s: expected a Polygon, Rect, Region, or point list, got %A"
                                        t_ctx item)
                                )
                            )
                        )
                    )
                    (t
                        error("%s: expected a Polygon, Rect, Region, or point list, got %A"
                            t_ctx item)
                    )
                )
            )
            car(res2)
        )
    )
)

procedure(_AsSegment(g_x t_ctx "gt")  ; -> Segment
    ; 归一化为 Segment：接受 Segment 或两点数组。
    ;
    ; **参数**
    ;   g_x    (any) - 待校验对象
    ;   t_ctx  (str) - 错误上下文
    ;
    ; **返回**
    ;   (Segment) - 原对象或新线段；非法时 error
    cond(
        (_SegmentP(g_x) g_x)
        (listp(g_x) Segment(g_x))
        (t error("%s: expected a Segment or two-point array, got %A" t_ctx g_x))
    )
)

procedure(_AsLine(g_x t_ctx "gt")  ; -> Line
    ; 归一化为 Line：接受 Line 或两点数组。
    ;
    ; **参数**
    ;   g_x    (any) - 待校验对象
    ;   t_ctx  (str) - 错误上下文
    ;
    ; **返回**
    ;   (Line) - 原对象或新直线；非法时 error
    cond(
        (_LineP(g_x) g_x)
        (listp(g_x) Line(g_x))
        (t error("%s: expected a Line or two-point array, got %A" t_ctx g_x))
    )
)

procedure(_AsLineOrSegment(g_x g_as t_ctx "ggt")  ; -> Line | Segment
    ; 归一化为 Line 或 Segment：对象直接返回，数组需 ?as 指定。
    ;
    ; **参数**
    ;   g_x    (any)     - Line、Segment 或两点数组
    ;   g_as   (sym|nil) - 目标类型；nil 表示未指定
    ;   t_ctx  (str)     - 错误上下文
    ;
    ; **返回**
    ;   (Line|Segment) - 归一化对象；数组歧义或类型非法时 error
    let((as2)
        when(g_as
            unless(symbolp(g_as)
                error("%s: ?as must be 'Line or 'Segment, got %A" t_ctx g_as)
            )
            as2 = symbolToString(g_as)
            unless(member(as2 '("Line" "Segment"))
                error("%s: ?as must be 'Line or 'Segment, got %A" t_ctx g_as)
            )
        )
        cond(
            (_LineP(g_x)
                when(g_as && as2 != "Line"
                    error("%s: expected %s, got %A" t_ctx as2 g_x)
                )
                g_x
            )
            (_SegmentP(g_x)
                when(g_as && as2 != "Segment"
                    error("%s: expected %s, got %A" t_ctx as2 g_x)
                )
                g_x
            )
            (listp(g_x)
                when(g_as == nil
                    error("%s: ?as is required for array input ('Line or 'Segment)"
                        t_ctx)
                )
                cond(
                    ((as2 == "Line") _AsLine(g_x t_ctx))
                    ((as2 == "Segment") _AsSegment(g_x t_ctx))
                    (t
                        error("%s: ?as must be 'Line or 'Segment, got %A"
                            t_ctx g_as)
                    )
                )
            )
            (t
                error("%s: expected a Line, Segment, or two-point array, got %A"
                    t_ctx g_x)
            )
        )
    )
)

procedure(_GeomKind(g_x "g")  ; -> sym | nil
    ; 返回图形对象的类别符号（内部实现）。
    ;
    ; **参数**
    ;   g_x  (any) - 待判断对象
    ;
    ; **返回**
    ;   (sym|nil) - Point/Segment/Line/Rect/Polygon/Region；非图形为 nil
    cond(
        (_PointP(g_x) 'Point)
        (_SegmentP(g_x) 'Segment)
        (_LineP(g_x) 'Line)
        (_RectP(g_x) 'Rect)
        (_PolygonP(g_x) 'Polygon)
        (_RegionP(g_x) 'Region)
    )
)

procedure(_AsPolygon(g_x t_ctx "gt")  ; -> Polygon
    ; 校验并返回 Polygon。
    ;
    ; **参数**
    ;   g_x    (any) - 待校验对象
    ;   t_ctx  (str) - 错误上下文
    ;
    ; **返回**
    ;   (Polygon) - 原对象或由点列构造的新对象；非法时 error
    cond(
        (_PolygonP(g_x) g_x)
        (listp(g_x) Polygon(g_x))
        (t error("%s: expected a Polygon or point list, got %A" t_ctx g_x))
    )
)

procedure(_AsPolygons(g_x t_ctx "gt")  ; -> list[Polygon]
    ; 归一化为多边形列表：接受 Region、Polygon、Rect、点列或点列列表。
    ;
    ; 「任意二维图形 → 多边形列表」只在本函数派发一次：_AsRegion 在其上包一层
    ; Region，布尔管线 _ShapePolys 直接取用，两处不会各写一份转换逻辑。
    ;
    ; **参数**
    ;   g_x    (any) - 待归一化对象
    ;   t_ctx  (str) - 错误上下文
    ;
    ; **返回**
    ;   (list[Polygon]) - 多边形列表；空集 nil；非法时 error
    let((pts res poly)
        cond(
            (_RegionP(g_x) g_x->polygons())
            (_PolygonP(g_x) list(g_x))
            (_RectP(g_x)
                poly = _RectPolygon(g_x)
                when(poly list(poly))
            )
            (listp(g_x)
                pts = errset(_AsPointList(g_x t_ctx) nil)
                cond(
                    ((pts && car(pts))
                        pts = car(pts)
                        cond(
                            ((length(pts) == 2)
                                poly = _RectPolygon(Rect(pts))
                                when(poly list(poly))
                            )
                            ((length(pts) >= 3) list(Polygon(pts)))
                            (t
                                error("%s: expected a Region, Polygon, Rect, or point list, got %A"
                                    t_ctx g_x)
                            )
                        )
                    )
                    (t
                        res = errset(_AsPolygonList(g_x t_ctx) nil)
                        if(res
                        then
                            car(res)
                        else
                            error("%s: expected a Region, Polygon, Rect, or point list, got %A"
                                t_ctx g_x)
                        )
                    )
                )
            )
            (t error("%s: expected a Region, Polygon, Rect, or point list, got %A" t_ctx g_x))
        )
    )
)

procedure(_AsRegion(g_x t_ctx "gt")  ; -> Region
    ; 归一化为 Region：接受 Region、Polygon、Rect 或点列。
    ;
    ; 派发统一走 _AsPolygons；Region 输入原样返回，不复制。
    ;
    ; **参数**
    ;   g_x    (any) - 待归一化对象
    ;   t_ctx  (str) - 错误上下文
    ;
    ; **返回**
    ;   (Region) - 原 Region，或由二维图形/点列构造的 Region；非法时 error
    if(_RegionP(g_x)
    then
        g_x
    else
        Region(_AsPolygons(g_x t_ctx) ?normalize nil)
    )
)

procedure(_ConvertToGeomObject(g_value t_ctx g_as "gtg")  ; -> any
    ; 按目标类型转换原始数组或返回已有图形对象（内部实现）。
    ;
    ; **参数**
    ;   g_value  (any)     - 图形对象或原始数组
    ;   t_ctx    (str)     - 错误上下文
    ;   g_as     (sym|nil) - 目标类型；nil 表示自动推断
    ;
    ; **返回**
    ;   (any) - Point/Segment/Line/Rect/Polygon/Region
    let((kind as2 actual pts2 res2)
        when(g_as && !symbolp(g_as)
            error("%s: ?as must be a symbol, got %A" t_ctx g_as)
        )
        when(g_as
            as2 = symbolToString(g_as)
            unless(member(as2 '("Point" "Segment" "Line" "Rect" "Polygon" "Region"))
                error("%s: ?as must be Point, Segment, Line, Rect, Polygon, or Region, got %A"
                    t_ctx g_as)
            )
        )
        kind = _GeomKind(g_value)
        cond(
            (kind
                actual = symbolToString(kind)
                if(as2 == nil || as2 == actual
                then
                    cond(
                        ((actual == "Point") Point(g_value->toSkill()))
                        ((actual == "Segment") Segment(g_value->toSkill()))
                        ((actual == "Line") Line(g_value->toSkill()))
                        ((actual == "Rect") Rect(g_value->toSkill()))
                        ((actual == "Polygon") Polygon(g_value->toSkill()))
                        ((actual == "Region") Region(g_value->toSkill()))
                    )
                else
                    error("%s: expected %s, got %A" t_ctx as2 g_value)
                )
            )
            ((as2 == "Point") _AsPoint(g_value t_ctx))
            ((as2 == "Segment") Segment(g_value))
            ((as2 == "Line") Line(g_value))
            ((as2 == "Rect") Rect(g_value))
            ((as2 == "Polygon") Polygon(g_value))
            ((as2 == "Region") _AsRegion(g_value t_ctx))
            (t
                res2 = errset(_AsPoint(g_value t_ctx) nil)
                if(res2
                then
                    car(res2)
                else
                    pts2 = errset(_AsPointList(g_value t_ctx) nil)
                    cond(
                        ((pts2 && car(pts2))
                            pts2 = car(pts2)
                            cond(
                                ((length(pts2) == 1) car(pts2))
                                ((length(pts2) == 2)
                                    error("%s: ambiguous two-point array; specify ?as 'Segment, 'Line, 'Rect, or 'Region"
                                        t_ctx)
                                )
                                (t Polygon(pts2))
                            )
                        )
                        (t
                            res2 = errset(_AsRegion(g_value t_ctx) nil)
                            if(res2
                            then
                                car(res2)
                            else
                                error("%s: expected a geometry object or coordinate array, got %A"
                                    t_ctx g_value)
                            )
                        )
                    )
                )
            )
        )
    )
)

procedure(ConvertToGeomObject(g_value \@key (as nil) "gg")  ; -> any
    ; 把图形对象或原始坐标数组统一转换为几何对象。
    ;
    ; **参数**
    ;   g_value  (any)     - 图形对象或坐标数组
    ;   ?as      (sym|nil) - 目标类型；nil 表示自动推断
    ;
    ; **返回**
    ;   (any) - Point/Segment/Line/Rect/Polygon/Region；无法确定时 error
    _ConvertToGeomObject(g_value "ycGeom::ConvertToGeomObject" as)
)

procedure(_BoundaryMode(g_boundary "g")  ; -> str
    ; 规范 ?boundary 选项。
    ;
    ; **参数**
    ;   g_boundary  (str) - "inside" 或 "outside"
    ;
    ; **返回**
    ;   (str) - 规范值；非法值 error
    unless(stringp(g_boundary) && (g_boundary == "inside" || g_boundary == "outside")
        error("ycGeom: ?boundary must be \"inside\" or \"outside\", got %A" g_boundary)
    )
    g_boundary
)

procedure(_Flag(g_value t_name "gt")  ; -> t | nil
    ; 规范 t/nil 选项。
    ;
    ; **参数**
    ;   g_value  (any) - 选项值
    ;   t_name   (str) - 选项名
    ;
    ; **返回**
    ;   (t|nil) - 原值；非 t/nil 时 error
    unless(g_value == t || g_value == nil
        error("ycGeom: ?%s must be t or nil, got %A" t_name g_value)
    )
    g_value
)

procedure(_NumKey(n_v "n")  ; -> str
    ; 生成数值的稳定文本键（保留双精度有效位）。
    ;
    ; **参数**
    ;   n_v  (num) - 数值
    ;
    ; **返回**
    ;   (str) - 规范化的数值文本；零统一为 "0"
    if(n_v == 0.0 "0" lsprintf("%.17g" float(n_v)))
)

procedure(_PtKey(g_p "g")  ; -> str
    ; 生成点坐标的稳定键。
    ;
    ; **参数**
    ;   g_p  (Point) - 点
    ;
    ; **返回**
    ;   (str) - x 与 y 的稳定文本键
    lsprintf("%s|%s" _NumKey(g_p->x()) _NumKey(g_p->y()))
)

procedure(_EdgeKey(g_a g_b "gg")  ; -> str
    ; 生成无向边的稳定键。
    ;
    ; **参数**
    ;   g_a  (Point) - 端点一
    ;   g_b  (Point) - 端点二
    ;
    ; **返回**
    ;   (str) - 两端点键按字典序拼接
    let((a b)
        a = _PtKey(g_a)
        b = _PtKey(g_b)
        if(alphalessp(a b)
            lsprintf("%s|%s" a b)
            lsprintf("%s|%s" b a)
        )
    )
)

procedure(_CellNumKey(n_q "n")  ; -> str
    ; 生成容差网格单元的文本键。
    ;
    ; **参数**
    ;   n_q  (num) - 坐标除以容差后的单元坐标
    ;
    ; **返回**
    ;   (str) - 四舍五入的单元键；零统一为 "0"
    let((key)
        key = lsprintf("%.0f" float(n_q))
        if(key == "-0" "0" key)
    )
)

procedure(_CanonPoint(g_p n_eps g_reg "gng")  ; -> Point
    ; 在容差网格中查找或登记点的规范代表。
    ;
    ; **参数**
    ;   g_p      (Point) - 输入点
    ;   n_eps    (float) - 容差
    ;   g_reg    (table) - 单元键到规范点列表的登记表
    ;
    ; **返回**
    ;   (Point) - 容差内已登记的规范点，或新登记的原点
    let((eff cx cy dx dy key found q)
        eff = g_reg["_canonScale"]
        unless(eff
            eff = max(n_eps 1e-15 * max(abs(g_p->x()) abs(g_p->y())))
            g_reg["_canonScale"] = eff
        )
        ; 先取整格号，再在整数格号上做 ±2 探测；直接对未取整
        ; 商偏移会让 round-half-even 跳过一格。两个 _SamePoint
        ; 为真的点格号差最多 2，±1 会漏掉两者都落在 .5 边界的情况。
        ; atof 保留 double，不能用返回 fixnum 的取整函数。
        cx = atof(_CellNumKey(g_p->x() / eff))
        cy = atof(_CellNumKey(g_p->y() / eff))
        for(dx2 -2 2
            for(dy2 -2 2
                key = lsprintf("%s|%s"
                    _CellNumKey(cx + dx2)
                    _CellNumKey(cy + dy2))
                foreach(q2 g_reg[key]
                    when(!found && _SamePoint(g_p q2 n_eps)
                        found = q2
                    )
                )
            )
        )
        unless(found
            key = lsprintf("%s|%s"
                _CellNumKey(cx) _CellNumKey(cy))
            g_reg[key] = cons(g_p g_reg[key])
            found = g_p
        )
        found
    )
)

procedure(_CanonRing(l_pts n_eps g_reg "lng")  ; -> list[Point]
    ; 把点列中的点替换为容差登记表中的规范代表。
    ;
    ; **参数**
    ;   l_pts    (list[Point]) - 源点列
    ;   n_eps    (float)       - 容差
    ;   g_reg    (table)       - 规范点登记表
    ;
    ; **返回**
    ;   (list[Point]) - 规范化并去除连续重复后的点列
    let((res2 mag)
        unless(g_reg["_canonScale"]
            mag = 0.0
            foreach(p l_pts
                mag = max(mag max(abs(p->x()) abs(p->y())))
            )
            g_reg["_canonScale"] = max(n_eps 1e-15 * mag)
        )
        foreach(p l_pts
            res2 = tconc(res2 _CanonPoint(p n_eps g_reg))
        )
        _RingPointsClean(car(res2) n_eps)
    )
)

procedure(_Cross(g_a g_b g_c "ggg")  ; -> float
    ; 计算 (b-a) × (c-a)。
    ;
    ; **参数**
    ;   g_a  (Point) - 起点
    ;   g_b  (Point) - 点二
    ;   g_c  (Point) - 点三
    ;
    ; **返回**
    ;   (float) - 二维叉积
    (g_b->x() - g_a->x()) * (g_c->y() - g_a->y())
        - (g_b->y() - g_a->y()) * (g_c->x() - g_a->x())
)

procedure(_AreaTol(l_pts n_eps "ln")  ; -> float
    ; 计算与坐标尺度相关的面积容差。
    ;
    ; **参数**
    ;   l_pts  (list[Point]) - 点列
    ;   n_eps  (float)       - 长度容差
    ;
    ; **返回**
    ;   (float) - 容差面积；取 bbox 长边乘 n_eps
    let((xmin ymin xmax ymax)
        xmin = car(l_pts)->x()
        xmax = xmin
        ymin = car(l_pts)->y()
        ymax = ymin
        foreach(p l_pts
            xmin = min(xmin p->x())
            xmax = max(xmax p->x())
            ymin = min(ymin p->y())
            ymax = max(ymax p->y())
        )
        n_eps * max(xmax - xmin ymax - ymin)
    )
)

procedure(_SignedArea(l_pts "l")  ; -> float
    ; 计算点列的有符号面积（shoelace，先平移到首点消除大数抵消）。
    ;
    ; **参数**
    ;   l_pts  (list[Point]) - 闭合点列（不重复首点）
    ;
    ; **返回**
    ;   (float) - 有符号面积
    let((len sum i a b ox oy)
        len = length(l_pts)
        sum = 0.0
        ox = car(l_pts)->x()
        oy = car(l_pts)->y()
        for(i2 1 len
            a = _Nth1(i2 l_pts)
            b = _Nth1(if(i2 == len 1 (i2 + 1)) l_pts)
            sum = sum
                + (a->x() - ox) * (b->y() - oy)
                - (b->x() - ox) * (a->y() - oy)
        )
        sum / 2.0
    )
)

procedure(_PointInRing(l_pts g_p n_eps "lgn")  ; -> t | nil
    ; 奇偶规则判断点是否在环内；边界点按内部处理。
    ;
    ; **参数**
    ;   l_pts  (list[Point]) - 闭合点列
    ;   g_p    (Point)       - 待判断点
    ;   n_eps  (float)       - 容差
    ;
    ; **返回**
    ;   (t|nil) - 在环内或边界上为 t
    let((len x y i a b in boundary xint)
        len = length(l_pts)
        x = g_p->x()
        y = g_p->y()
        for(i2 1 len
            a = _Nth1(i2 l_pts)
            b = _Nth1(if(i2 == len 1 (i2 + 1)) l_pts)
            when(_OnSegment(a b g_p n_eps)
                boundary = t
            )
            when((a->y() > y) != (b->y() > y)
                xint = a->x()
                    + (y - a->y()) * (b->x() - a->x())
                        / (b->y() - a->y())
                when(x < xint
                    in = !in
                )
            )
        )
        if(boundary t in)
    )
)

procedure(_OnSegment(g_a g_b g_p n_eps "gggn")  ; -> t | nil
    ; 判断点是否在线段上（含端点）。
    ;
    ; **参数**
    ;   g_a    (Point) - 线段起点
    ;   g_b    (Point) - 线段终点
    ;   g_p    (Point) - 待判断点
    ;   n_eps  (float) - 容差
    ;
    ; **返回**
    ;   (t|nil) - 在线段上为 t
    let((dx dy apx apy cross dot len2 len scale tol)
        dx = g_b->x() - g_a->x()
        dy = g_b->y() - g_a->y()
        apx = g_p->x() - g_a->x()
        apy = g_p->y() - g_a->y()
        cross = dx * apy - dy * apx
        dot = dx * apx + dy * apy
        len2 = dx * dx + dy * dy
        len = sqrt(len2)
        if(len <= n_eps
        then
            abs(apx) <= n_eps && abs(apy) <= n_eps
        else
            scale = max(abs(g_a->x()) abs(g_a->y()))
            scale = max(scale max(abs(g_b->x()) abs(g_b->y())))
            scale = max(scale max(abs(g_p->x()) abs(g_p->y())))
            tol = max(n_eps * len 1e-15 * len * scale)
            abs(cross) <= tol
                && dot >= -tol
                && dot <= len2 + tol
        )
    )
)

procedure(_Orient(g_a g_b g_c "ggg")  ; -> float
    ; 三点方向值。
    ;
    ; **参数**
    ;   g_a  (Point) - 点一
    ;   g_b  (Point) - 点二
    ;   g_c  (Point) - 点三
    ;
    ; **返回**
    ;   (float) - 叉积；正、负、零表示左转、右转、共线
    _Cross(g_a g_b g_c)
)

procedure(_SegmentsCross(g_a g_b g_c g_d n_eps "ggggn")  ; -> t | nil
    ; 判断两条线段是否相交或接触（内部实现）。
    ;
    ; **参数**
    ;   g_a    (Point) - 第一段起点
    ;   g_b    (Point) - 第一段终点
    ;   g_c    (Point) - 第二段起点
    ;   g_d    (Point) - 第二段终点
    ;   n_eps  (float) - 容差
    ;
    ; **返回**
    ;   (t|nil) - 有交点、端点接触或共线重叠为 t
    let((o1 o2 o3 o4 len_ab len_cd scale tol_ab tol_cd)
        o1 = _Orient(g_a g_b g_c)
        o2 = _Orient(g_a g_b g_d)
        o3 = _Orient(g_c g_d g_a)
        o4 = _Orient(g_c g_d g_b)
        len_ab = sqrt((g_b->x() - g_a->x()) * (g_b->x() - g_a->x())
            + (g_b->y() - g_a->y()) * (g_b->y() - g_a->y()))
        len_cd = sqrt((g_d->x() - g_c->x()) * (g_d->x() - g_c->x())
            + (g_d->y() - g_c->y()) * (g_d->y() - g_c->y()))
        scale = max(abs(g_a->x()) abs(g_a->y()))
        scale = max(scale max(abs(g_b->x()) abs(g_b->y())))
        scale = max(scale max(abs(g_c->x()) abs(g_c->y())))
        scale = max(scale max(abs(g_d->x()) abs(g_d->y())))
        tol_ab = max(n_eps * len_ab 1e-15 * len_ab * scale)
        tol_cd = max(n_eps * len_cd 1e-15 * len_cd * scale)
        if(((o1 > tol_ab && o2 < -tol_ab)
                || (o1 < -tol_ab && o2 > tol_ab))
            && ((o3 > tol_cd && o4 < -tol_cd)
                || (o3 < -tol_cd && o4 > tol_cd))
            t
            (_OnSegment(g_a g_b g_c n_eps)
                || _OnSegment(g_a g_b g_d n_eps)
                || _OnSegment(g_c g_d g_a n_eps)
                || _OnSegment(g_c g_d g_b n_eps))
        )
    )
)

procedure(_SeamKeys(l_pts "l")  ; -> table
    ; 统计无向边出现次数，供切割边识别。
    ;
    ; **参数**
    ;   l_pts  (list[Point]) - 闭合点列
    ;
    ; **返回**
    ;   (table) - 无向边键 → 次数
    let((len i cnt key)
        len = length(l_pts)
        cnt = makeTable("geomSeams" nil)
        for(i2 1 len
            key = _EdgeKey(_Nth1(i2 l_pts) _Nth1(if(i2 == len 1 (i2 + 1)) l_pts))
            cnt[key] = if(cnt[key] (cnt[key] + 1) 1)
        )
        cnt
    )
)

procedure(_CollinearClean(l_pts n_eps "ln")  ; -> list[Point]
    ; 删除非切割边上的共线中间点（内部实现）。
    ;
    ; **参数**
    ;   l_pts  (list[Point]) - 闭合点列
    ;   n_eps  (float)       - 容差
    ;
    ; **返回**
    ;   (list[Point]) - 去除共线点后的点列；切割边端点保留
    let((len changed seams res2 i prev cur next dot line_len scale tol)
        len = length(l_pts)
        changed = t
        while(changed && len > 3
            changed = nil
            seams = _SeamKeys(l_pts)
            res2 = nil
            for(i2 1 len
                prev = _Nth1(if(i2 == 1 len (i2 - 1)) l_pts)
                cur = _Nth1(i2 l_pts)
                next = _Nth1(if(i2 == len 1 (i2 + 1)) l_pts)
                dot = (cur->x() - prev->x())
                        * (next->x() - cur->x())
                    + (cur->y() - prev->y())
                        * (next->y() - cur->y())
                line_len = sqrt(
                    (next->x() - prev->x())
                        * (next->x() - prev->x())
                    + (next->y() - prev->y())
                        * (next->y() - prev->y()))
                scale = max(abs(prev->x()) abs(prev->y()))
                scale = max(scale max(abs(cur->x()) abs(cur->y())))
                scale = max(scale max(abs(next->x()) abs(next->y())))
                tol = max(n_eps * line_len
                    1e-15 * line_len * scale)
                cond(
                    (seams[_EdgeKey(prev cur)] == 2
                        || seams[_EdgeKey(cur next)] == 2
                        res2 = tconc(res2 cur)
                    )
                    ((abs(_Cross(prev cur next)) <= tol
                        && dot >= 0.0)
                        changed = t
                    )
                    (t
                        res2 = tconc(res2 cur)
                    )
                )
            )
            l_pts = car(res2)
            len = length(l_pts)
        )
        l_pts
    )
)

procedure(_RemovePoint(l_list g_p "lg")  ; -> list
    ; 从点列表中删除坐标键相同的点（内部实现）。
    ;
    ; **参数**
    ;   l_list  (list[Point]) - 源列表
    ;   g_p     (Point)       - 待删除点
    ;
    ; **返回**
    ;   (list[Point]) - 删除后的新列表
    let((res2 key)
        key = _PtKey(g_p)
        foreach(x l_list
            unless(_PtKey(x) == key
                res2 = tconc(res2 x)
            )
        )
        car(res2)
    )
)

procedure(_FirstAdjPoint(g_adj l_order "gl")  ; -> Point | nil
    ; 返回邻接表中第一个尚有余边的点。
    ;
    ; **参数**
    ;   g_adj   (table) - 点键 → 邻接点列表
    ;   l_order (list)  - 点键的首次出现顺序
    ;
    ; **返回**
    ;   (Point|nil) - 仍有边的点；没有时为 nil
    let((found)
        foreach(key l_order
            when(g_adj[key] && !found
                found = car(g_adj[key])
            )
        )
        found
    )
)

procedure(_Rings(l_pts "l")  ; -> list[list[Point]]
    ; 从 keyhole 点列中移除切割边并追踪外环/洞环。
    ;
    ; **参数**
    ;   l_pts  (list[Point]) - 闭合点列
    ;
    ; **返回**
    ;   (list[list[Point]]) - 环列表；无法闭合时 error
    let((len i a b seams adj order res2 start cur next ring nei sk nk)
        len = length(l_pts)
        seams = _SeamKeys(l_pts)
        adj = makeTable("geomAdj" nil)
        for(i2 1 len
            a = _Nth1(i2 l_pts)
            b = _Nth1(if(i2 == len 1 (i2 + 1)) l_pts)
            sk = _EdgeKey(a b)
            unless(seams[sk] == 2
                nk = _PtKey(a)
                unless(adj[nk]
                    order = tconc(order nk)
                )
                adj[nk] = cons(b adj[nk])
                nk = _PtKey(b)
                unless(adj[nk]
                    order = tconc(order nk)
                )
                adj[nk] = cons(a adj[nk])
            )
        )
        order = car(order)
        while(_FirstAdjPoint(adj order)
            start = _FirstAdjPoint(adj order)
            cur = start
            ring = tconc(nil start)
            while(cur
                nei = adj[_PtKey(cur)]
                unless(nei
                    error("ycGeom: cannot close polygon ring")
                )
                next = car(nei)
                adj[_PtKey(cur)] = cdr(nei)
                adj[_PtKey(next)] = _RemovePoint(adj[_PtKey(next)] cur)
                when(_PtKey(next) == _PtKey(start)
                    res2 = tconc(res2 car(ring))
                    cur = nil
                    ring = nil
                )
                when(cur
                    ring = tconc(ring next)
                    cur = next
                )
            )
        )
        car(res2)
    )
)

procedure(_RingPointsClean(l_pts n_eps "ln")  ; -> list[Point]
    ; 删除连续重复点。
    ;
    ; **参数**
    ;   l_pts  (list[Point]) - 源点列
    ;   n_eps  (float)       - 容差
    ;
    ; **返回**
    ;   (list[Point]) - 清理后的点列
    let((res2 prev)
        foreach(p l_pts
            unless(prev && _Near(prev->x() p->x() n_eps) && _Near(prev->y() p->y() n_eps)
                res2 = tconc(res2 p)
            )
            prev = p
        )
        car(res2)
    )
)

unuseNamespace("ycGeom")

; END
