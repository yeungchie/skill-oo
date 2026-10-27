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
        (t error("ycGeom::_Eps: ?eps must be a positive number, got %A" g_eps))
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
        (t error("ycGeom::_Grid: ?grid must be a positive number, got %A" g_grid))
    )
)

procedure(_Snap(n_val n_grid "ng")  ; -> float
    ; 将数值吸附到网格。
    ;
    ; **参数**
    ;   n_val   (num)        - 原值
    ;   n_grid  (float|nil)  - 网格间距；nil 原样转 float
    ;
    ; **返回**
    ;   (float) - 吸附后的 flonum
    if(n_grid == nil
        float(n_val)
        float(round(float(n_val) / n_grid) * n_grid)
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
    let((n_fa n_fb n_diff n_rel)
        n_fa = float(n_a)
        n_fb = float(n_b)
        n_diff = abs(n_fa - n_fb)
        n_rel = 1e-15 * max(abs(n_fa) abs(n_fb))
        n_diff <= max(float(n_eps) n_rel)
    )
)

procedure(_SamePoint(g_a g_b n_eps "ggg")  ; -> t | nil
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
        makeInstance('PointData ?x float(n_x) ?y float(n_y)))
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
    ; 归一化点列：接受 Point/(x y)、扁平数值与任意层嵌套列表。
    ;
    ; **参数**
    ;   l_data  (list) - 点列、坐标或嵌套列表
    ;   t_ctx   (str)  - 错误上下文
    ;
    ; **返回**
    ;   (list[Point]) - 归一化点列；格式不合法时 error
    let((l_res l_rest)
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
                l_rest = l_data
                while(l_rest
                    cond(
                        (_PointP(car(l_rest))
                            l_res = tconc(l_res car(l_rest))
                            l_rest = cdr(l_rest)
                        )
                        (_PairP(car(l_rest))
                            l_res = tconc(l_res
                                _PointAt(car(car(l_rest))
                                    cadr(car(l_rest))))
                            l_rest = cdr(l_rest)
                        )
                        (numberp(car(l_rest))
                            unless(cadr(l_rest) && numberp(cadr(l_rest))
                                error("%s: coordinate list contains non-numbers"
                                    t_ctx)
                            )
                            l_res = tconc(l_res
                                _PointAt(car(l_rest) cadr(l_rest)))
                            l_rest = cddr(l_rest)
                        )
                        (t
                            error("%s: expected a Point or (x y) list, got %A"
                                t_ctx car(l_rest))
                        )
                    )
                )
                car(l_res)
            )
        )
    )
)

procedure(_TwoPoints(l_data t_ctx "lt")  ; -> list[Point]
    ; 归一化“两点”构造参数：只接受一个列表。
    ;
    ; **参数**
    ;   l_data  (list) - 两点列表、任意层嵌套列表或四个坐标
    ;   t_ctx   (str)  - 错误上下文
    ;
    ; **返回**
    ;   (list[Point]) - 两个点；格式不合法时 error
    let((l_pts)
        l_pts = errset(_AsPointList(l_data t_ctx) nil)
        cond(
            ((l_pts && car(l_pts) && length(car(l_pts)) == 2)
                car(l_pts)
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
    let((l_res l_pts l_nested g_poly)
        when(l_data
            unless(listp(l_data)
                error("%s: expected a Polygon list, got %A" t_ctx l_data)
            )
            foreach(g_item l_data
                cond(
                    (_PolygonP(g_item)
                        l_res = tconc(l_res g_item)
                    )
                    (_RectP(g_item)
                        g_poly = _RectPolygon(g_item)
                        when(g_poly
                            l_res = tconc(l_res g_poly)
                        )
                    )
                    (_RegionP(g_item)
                        foreach(g_poly g_item->polygons()
                            l_res = tconc(l_res g_poly)
                        )
                    )
                    (listp(g_item)
                        l_pts = errset(_AsPointList(g_item t_ctx) nil)
                        cond(
                            ((l_pts && car(l_pts))
                                l_pts = car(l_pts)
                                cond(
                                    ((length(l_pts) == 2)
                                        g_poly = _RectPolygon(Rect(l_pts))
                                        when(g_poly
                                            l_res = tconc(l_res g_poly)
                                        )
                                    )
                                    ((length(l_pts) >= 3)
                                        l_res = tconc(l_res Polygon(l_pts))
                                    )
                                    (t
                                        error("%s: expected a Polygon, Rect, Region, or point list, got %A"
                                            t_ctx g_item)
                                    )
                                )
                            )
                            (t
                                l_nested = errset(_AsPolygonList(g_item t_ctx) nil)
                                if(l_nested && car(l_nested)
                                then
                                    foreach(g_poly car(l_nested)
                                        l_res = tconc(l_res g_poly)
                                    )
                                else
                                    error("%s: expected a Polygon, Rect, Region, or point list, got %A"
                                        t_ctx g_item)
                                )
                            )
                        )
                    )
                    (t
                        error("%s: expected a Polygon, Rect, Region, or point list, got %A"
                            t_ctx g_item)
                    )
                )
            )
            car(l_res)
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
    let((t_as)
        when(g_as
            unless(symbolp(g_as)
                error("%s: ?as must be 'Line or 'Segment, got %A" t_ctx g_as)
            )
            t_as = symbolToString(g_as)
            unless(member(t_as '("Line" "Segment"))
                error("%s: ?as must be 'Line or 'Segment, got %A" t_ctx g_as)
            )
        )
        cond(
            (_LineP(g_x)
                when(g_as && t_as != "Line"
                    error("%s: expected %s, got %A" t_ctx t_as g_x)
                )
                g_x
            )
            (_SegmentP(g_x)
                when(g_as && t_as != "Segment"
                    error("%s: expected %s, got %A" t_ctx t_as g_x)
                )
                g_x
            )
            (listp(g_x)
                when(g_as == nil
                    error("%s: ?as is required for array input ('Line or 'Segment)"
                        t_ctx)
                )
                cond(
                    ((t_as == "Line") _AsLine(g_x t_ctx))
                    ((t_as == "Segment") _AsSegment(g_x t_ctx))
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

procedure(_AsRegion(g_x t_ctx "gt")  ; -> Region
    ; 归一化为 Region：接受 Region、Polygon、Rect 或点列。
    ;
    ; **参数**
    ;   g_x    (any) - 待归一化对象
    ;   t_ctx  (str) - 错误上下文
    ;
    ; **返回**
    ;   (Region) - 原 Region，或由二维图形/点列构造的 Region；非法时 error
    let((l_pts g_poly l_res)
        cond(
            (_RegionP(g_x) g_x)
            (_PolygonP(g_x) Region(list(g_x) ?normalize nil))
            (_RectP(g_x)
                g_poly = _RectPolygon(g_x)
                if(g_poly
                    Region(list(g_poly) ?normalize nil)
                    Region(nil)
                )
            )
            (listp(g_x)
                l_pts = errset(_AsPointList(g_x t_ctx) nil)
                cond(
                    ((l_pts && car(l_pts))
                        l_pts = car(l_pts)
                        cond(
                            ((length(l_pts) == 2)
                                g_poly = _RectPolygon(Rect(l_pts))
                                if(g_poly
                                    Region(list(g_poly) ?normalize nil)
                                    Region(nil)
                                )
                            )
                            ((length(l_pts) >= 3)
                                Region(list(Polygon(l_pts)) ?normalize nil)
                            )
                            (t
                                error("%s: expected a Region, Polygon, Rect, or point list, got %A"
                                    t_ctx g_x)
                            )
                        )
                    )
                    (t
                        l_res = errset(Region(g_x ?normalize nil) nil)
                        if(l_res
                        then
                            car(l_res)
                        else
                            error("%s: expected a Region, Polygon, Rect, or point list, got %A"
                                t_ctx g_x)
                        )
                    )
                )
            )
            (t error("%s: expected a Region, Polygon, Rect, or point list, got %A"
                t_ctx g_x))
        )
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
    let((t_kind t_as t_actual l_pts l_res)
        when(g_as && !symbolp(g_as)
            error("%s: ?as must be a symbol, got %A" t_ctx g_as)
        )
        when(g_as
            t_as = symbolToString(g_as)
            unless(member(t_as '("Point" "Segment" "Line" "Rect" "Polygon" "Region"))
                error("%s: ?as must be Point, Segment, Line, Rect, Polygon, or Region, got %A"
                    t_ctx g_as)
            )
        )
        t_kind = _GeomKind(g_value)
        cond(
            (t_kind
                t_actual = symbolToString(t_kind)
                if(t_as == nil || t_as == t_actual
                then
                    cond(
                        ((t_actual == "Point") Point(g_value->toSkill()))
                        ((t_actual == "Segment") Segment(g_value->toSkill()))
                        ((t_actual == "Line") Line(g_value->toSkill()))
                        ((t_actual == "Rect") Rect(g_value->toSkill()))
                        ((t_actual == "Polygon") Polygon(g_value->toSkill()))
                        ((t_actual == "Region") Region(g_value->toSkill()))
                    )
                else
                    error("%s: expected %s, got %A" t_ctx t_as g_value)
                )
            )
            ((t_as == "Point") _AsPoint(g_value t_ctx))
            ((t_as == "Segment") Segment(g_value))
            ((t_as == "Line") Line(g_value))
            ((t_as == "Rect") Rect(g_value))
            ((t_as == "Polygon") Polygon(g_value))
            ((t_as == "Region") _AsRegion(g_value t_ctx))
            (t
                l_pts = errset(_AsPointList(g_value t_ctx) nil)
                cond(
                    ((l_pts && car(l_pts))
                        l_pts = car(l_pts)
                        cond(
                            ((length(l_pts) == 1) car(l_pts))
                            ((length(l_pts) == 2)
                                error("%s: ambiguous two-point array; specify ?as 'Segment, 'Line, 'Rect, or 'Region"
                                    t_ctx)
                            )
                            (t Polygon(l_pts))
                        )
                    )
                    (t
                        l_res = errset(_AsRegion(g_value t_ctx) nil)
                        if(l_res
                        then
                            car(l_res)
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
        error("ycGeom::_BoundaryMode: ?boundary must be \"inside\" or \"outside\", got %A" g_boundary)
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
        error("ycGeom::_Flag: ?%s must be t or nil, got %A" t_name g_value)
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
    let((t_a t_b)
        t_a = _PtKey(g_a)
        t_b = _PtKey(g_b)
        if(alphalessp(t_a t_b)
            lsprintf("%s|%s" t_a t_b)
            lsprintf("%s|%s" t_b t_a)
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
    let((t_key)
        t_key = lsprintf("%.0f" float(n_q))
        if(t_key == "-0" "0" t_key)
    )
)

procedure(_CanonPoint(g_p n_eps t_reg "ggg")  ; -> Point
    ; 在容差网格中查找或登记点的规范代表。
    ;
    ; **参数**
    ;   g_p      (Point) - 输入点
    ;   n_eps    (float) - 容差
    ;   t_reg    (table) - 单元键到规范点列表的登记表
    ;
    ; **返回**
    ;   (Point) - 容差内已登记的规范点，或新登记的原点
    let((n_eff n_cx n_cy n_dx n_dy t_key g_found g_q)
        n_eff = max(n_eps 1e-15 * max(abs(g_p->x()) abs(g_p->y())))
        n_cx = g_p->x() / n_eff
        n_cy = g_p->y() / n_eff
        for(n_dx -1 1
            for(n_dy -1 1
                t_key = lsprintf("%s|%s"
                    _CellNumKey(n_cx + n_dx)
                    _CellNumKey(n_cy + n_dy))
                foreach(g_q t_reg[t_key]
                    when(!g_found && _SamePoint(g_p g_q n_eps)
                        g_found = g_q
                    )
                )
            )
        )
        unless(g_found
            t_key = lsprintf("%s|%s"
                _CellNumKey(n_cx) _CellNumKey(n_cy))
            t_reg[t_key] = cons(g_p t_reg[t_key])
            g_found = g_p
        )
        g_found
    )
)

procedure(_CanonRing(l_pts n_eps t_reg "lgg")  ; -> list[Point]
    ; 把点列中的点替换为容差登记表中的规范代表。
    ;
    ; **参数**
    ;   l_pts    (list[Point]) - 源点列
    ;   n_eps    (float)       - 容差
    ;   t_reg    (table)       - 规范点登记表
    ;
    ; **返回**
    ;   (list[Point]) - 规范化并去除连续重复后的点列
    let((l_res)
        foreach(g_p l_pts
            l_res = tconc(l_res _CanonPoint(g_p n_eps t_reg))
        )
        _RingPointsClean(car(l_res) n_eps)
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

procedure(_AreaTol(l_pts n_eps "lg")  ; -> float
    ; 计算与坐标尺度相关的面积容差。
    ;
    ; **参数**
    ;   l_pts  (list[Point]) - 点列
    ;   n_eps  (float)       - 长度容差
    ;
    ; **返回**
    ;   (float) - 容差面积；取 bbox 长边乘 n_eps
    let((n_xmin n_ymin n_xmax n_ymax)
        n_xmin = car(l_pts)->x()
        n_xmax = n_xmin
        n_ymin = car(l_pts)->y()
        n_ymax = n_ymin
        foreach(g_p l_pts
            n_xmin = min(n_xmin g_p->x())
            n_xmax = max(n_xmax g_p->x())
            n_ymin = min(n_ymin g_p->y())
            n_ymax = max(n_ymax g_p->y())
        )
        n_eps * max(n_xmax - n_xmin n_ymax - n_ymin)
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
    let((n_len n_sum n_i g_a g_b n_ox n_oy)
        n_len = length(l_pts)
        n_sum = 0.0
        n_ox = car(l_pts)->x()
        n_oy = car(l_pts)->y()
        for(n_i 1 n_len
            g_a = _Nth1(n_i l_pts)
            g_b = _Nth1(if(n_i == n_len 1 (n_i + 1)) l_pts)
            n_sum = n_sum
                + (g_a->x() - n_ox) * (g_b->y() - n_oy)
                - (g_b->x() - n_ox) * (g_a->y() - n_oy)
        )
        n_sum / 2.0
    )
)

procedure(_PointInRing(l_pts g_p n_eps "lgg")  ; -> t | nil
    ; 奇偶规则判断点是否在环内；边界点按内部处理。
    ;
    ; **参数**
    ;   l_pts  (list[Point]) - 闭合点列
    ;   g_p    (Point)       - 待判断点
    ;   n_eps  (float)       - 容差
    ;
    ; **返回**
    ;   (t|nil) - 在环内或边界上为 t
    let((n_len n_x n_y n_i g_a g_b g_in g_boundary n_xint)
        n_len = length(l_pts)
        n_x = g_p->x()
        n_y = g_p->y()
        for(n_i 1 n_len
            g_a = _Nth1(n_i l_pts)
            g_b = _Nth1(if(n_i == n_len 1 (n_i + 1)) l_pts)
            when(_OnSegment(g_a g_b g_p n_eps)
                g_boundary = t
            )
            when((g_a->y() > n_y) != (g_b->y() > n_y)
                n_xint = g_a->x()
                    + (n_y - g_a->y()) * (g_b->x() - g_a->x())
                        / (g_b->y() - g_a->y())
                when(n_x < n_xint
                    g_in = !g_in
                )
            )
        )
        if(g_boundary t g_in)
    )
)

procedure(_OnSegment(g_a g_b g_p n_eps "gggg")  ; -> t | nil
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
    let((n_dx n_dy n_apx n_apy n_cross n_dot n_len2 n_len n_scale n_tol)
        n_dx = g_b->x() - g_a->x()
        n_dy = g_b->y() - g_a->y()
        n_apx = g_p->x() - g_a->x()
        n_apy = g_p->y() - g_a->y()
        n_cross = n_dx * n_apy - n_dy * n_apx
        n_dot = n_dx * n_apx + n_dy * n_apy
        n_len2 = n_dx * n_dx + n_dy * n_dy
        n_len = sqrt(n_len2)
        if(n_len <= n_eps
        then
            abs(n_apx) <= n_eps && abs(n_apy) <= n_eps
        else
            n_scale = max(abs(g_a->x()) abs(g_a->y()))
            n_scale = max(n_scale max(abs(g_b->x()) abs(g_b->y())))
            n_scale = max(n_scale max(abs(g_p->x()) abs(g_p->y())))
            n_tol = max(n_eps * n_len 1e-15 * n_len * n_scale)
            abs(n_cross) <= n_tol
                && n_dot >= -n_tol
                && n_dot <= n_len2 + n_tol
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

procedure(_SegmentsCross(g_a g_b g_c g_d n_eps "ggggg")  ; -> t | nil
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
    let((n_o1 n_o2 n_o3 n_o4 n_len_ab n_len_cd n_scale n_tol_ab n_tol_cd)
        n_o1 = _Orient(g_a g_b g_c)
        n_o2 = _Orient(g_a g_b g_d)
        n_o3 = _Orient(g_c g_d g_a)
        n_o4 = _Orient(g_c g_d g_b)
        n_len_ab = sqrt((g_b->x() - g_a->x()) * (g_b->x() - g_a->x())
            + (g_b->y() - g_a->y()) * (g_b->y() - g_a->y()))
        n_len_cd = sqrt((g_d->x() - g_c->x()) * (g_d->x() - g_c->x())
            + (g_d->y() - g_c->y()) * (g_d->y() - g_c->y()))
        n_scale = max(abs(g_a->x()) abs(g_a->y()))
        n_scale = max(n_scale max(abs(g_b->x()) abs(g_b->y())))
        n_scale = max(n_scale max(abs(g_c->x()) abs(g_c->y())))
        n_scale = max(n_scale max(abs(g_d->x()) abs(g_d->y())))
        n_tol_ab = max(n_eps * n_len_ab 1e-15 * n_len_ab * n_scale)
        n_tol_cd = max(n_eps * n_len_cd 1e-15 * n_len_cd * n_scale)
        if(((n_o1 > n_tol_ab && n_o2 < -n_tol_ab)
                || (n_o1 < -n_tol_ab && n_o2 > n_tol_ab))
            && ((n_o3 > n_tol_cd && n_o4 < -n_tol_cd)
                || (n_o3 < -n_tol_cd && n_o4 > n_tol_cd))
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
    let((n_len n_i t_cnt t_key)
        n_len = length(l_pts)
        t_cnt = makeTable("geomSeams" nil)
        for(n_i 1 n_len
            t_key = _EdgeKey(_Nth1(n_i l_pts) _Nth1(if(n_i == n_len 1 (n_i + 1)) l_pts))
            t_cnt[t_key] = if(t_cnt[t_key] (t_cnt[t_key] + 1) 1)
        )
        t_cnt
    )
)

procedure(_CollinearClean(l_pts n_eps "lg")  ; -> list[Point]
    ; 删除非切割边上的共线中间点（内部实现）。
    ;
    ; **参数**
    ;   l_pts  (list[Point]) - 闭合点列
    ;   n_eps  (float)       - 容差
    ;
    ; **返回**
    ;   (list[Point]) - 去除共线点后的点列；切割边端点保留
    let((n_len n_changed t_seams l_res n_i g_prev g_cur g_next n_dot n_line_len n_scale n_tol)
        n_len = length(l_pts)
        n_changed = t
        while(n_changed && n_len > 3
            n_changed = nil
            t_seams = _SeamKeys(l_pts)
            l_res = nil
            for(n_i 1 n_len
                g_prev = _Nth1(if(n_i == 1 n_len (n_i - 1)) l_pts)
                g_cur = _Nth1(n_i l_pts)
                g_next = _Nth1(if(n_i == n_len 1 (n_i + 1)) l_pts)
                n_dot = (g_cur->x() - g_prev->x())
                        * (g_next->x() - g_cur->x())
                    + (g_cur->y() - g_prev->y())
                        * (g_next->y() - g_cur->y())
                n_line_len = sqrt(
                    (g_next->x() - g_prev->x())
                        * (g_next->x() - g_prev->x())
                    + (g_next->y() - g_prev->y())
                        * (g_next->y() - g_prev->y()))
                n_scale = max(abs(g_prev->x()) abs(g_prev->y()))
                n_scale = max(n_scale max(abs(g_cur->x()) abs(g_cur->y())))
                n_scale = max(n_scale max(abs(g_next->x()) abs(g_next->y())))
                n_tol = max(n_eps * n_line_len
                    1e-15 * n_line_len * n_scale)
                cond(
                    (t_seams[_EdgeKey(g_prev g_cur)] == 2
                        || t_seams[_EdgeKey(g_cur g_next)] == 2
                        l_res = tconc(l_res g_cur)
                    )
                    ((abs(_Cross(g_prev g_cur g_next)) <= n_tol
                        && n_dot >= 0.0)
                        n_changed = t
                    )
                    (t
                        l_res = tconc(l_res g_cur)
                    )
                )
            )
            l_pts = car(l_res)
            n_len = length(l_pts)
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
    let((l_res t_key)
        t_key = _PtKey(g_p)
        foreach(g_x l_list
            unless(_PtKey(g_x) == t_key
                l_res = tconc(l_res g_x)
            )
        )
        car(l_res)
    )
)

procedure(_FirstAdjPoint(t_adj l_order "gl")  ; -> Point | nil
    ; 返回邻接表中第一个尚有余边的点。
    ;
    ; **参数**
    ;   t_adj   (table) - 点键 → 邻接点列表
    ;   l_order (list)  - 点键的首次出现顺序
    ;
    ; **返回**
    ;   (Point|nil) - 仍有边的点；没有时为 nil
    let((g_found)
        foreach(t_key l_order
            when(t_adj[t_key] && !g_found
                g_found = car(t_adj[t_key])
            )
        )
        g_found
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
    let((n_len n_i g_a g_b t_seams t_adj l_order l_res g_start g_cur g_next l_ring l_nei t_sk t_nk)
        n_len = length(l_pts)
        t_seams = _SeamKeys(l_pts)
        t_adj = makeTable("geomAdj" nil)
        for(n_i 1 n_len
            g_a = _Nth1(n_i l_pts)
            g_b = _Nth1(if(n_i == n_len 1 (n_i + 1)) l_pts)
            t_sk = _EdgeKey(g_a g_b)
            unless(t_seams[t_sk] == 2
                t_nk = _PtKey(g_a)
                unless(t_adj[t_nk]
                    l_order = tconc(l_order t_nk)
                )
                t_adj[t_nk] = cons(g_b t_adj[t_nk])
                t_nk = _PtKey(g_b)
                unless(t_adj[t_nk]
                    l_order = tconc(l_order t_nk)
                )
                t_adj[t_nk] = cons(g_a t_adj[t_nk])
            )
        )
        l_order = car(l_order)
        while(_FirstAdjPoint(t_adj l_order)
            g_start = _FirstAdjPoint(t_adj l_order)
            g_cur = g_start
            l_ring = tconc(nil g_start)
            while(g_cur
                l_nei = t_adj[_PtKey(g_cur)]
                unless(l_nei
                    error("ycGeom::_Rings: cannot close polygon ring")
                )
                g_next = car(l_nei)
                t_adj[_PtKey(g_cur)] = cdr(l_nei)
                t_adj[_PtKey(g_next)] = _RemovePoint(t_adj[_PtKey(g_next)] g_cur)
                when(_PtKey(g_next) == _PtKey(g_start)
                    l_res = tconc(l_res car(l_ring))
                    g_cur = nil
                    l_ring = nil
                )
                when(g_cur
                    l_ring = tconc(l_ring g_next)
                    g_cur = g_next
                )
            )
        )
        car(l_res)
    )
)

procedure(_RingPointsClean(l_pts n_eps "lg")  ; -> list[Point]
    ; 删除连续重复点。
    ;
    ; **参数**
    ;   l_pts  (list[Point]) - 源点列
    ;   n_eps  (float)       - 容差
    ;
    ; **返回**
    ;   (list[Point]) - 清理后的点列
    let((l_res g_prev)
        foreach(g_p l_pts
            unless(g_prev && _Near(g_prev->x() g_p->x() n_eps) && _Near(g_prev->y() g_p->y() n_eps)
                l_res = tconc(l_res g_p)
            )
            g_prev = g_p
        )
        car(l_res)
    )
)

unuseNamespace("ycGeom")

; END
