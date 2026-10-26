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
    ; 判断两个数值是否在容差内。
    ;
    ; **参数**
    ;   n_a    (num) - 值一
    ;   n_b    (num) - 值二
    ;   n_eps  (num) - 容差
    ;
    ; **返回**
    ;   (t|nil) - 差值不超过容差为 t
    abs(float(n_a) - float(n_b)) <= n_eps
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

procedure(_AsPoint(g_x t_ctx "gt")  ; -> Point
    ; 归一化为 Point：接受 Point 或 (x y) 数值列表。
    ;
    ; **参数**
    ;   g_x    (any) - Point 或 (x y)
    ;   t_ctx  (str) - 错误上下文
    ;
    ; **返回**
    ;   (Point) - 归一化后的点；无法识别时 error
    cond(
        (_PointP(g_x) g_x)
        (_PairP(g_x) Point(g_x))
        (t error("%s: expected a Point or (x y) list, got %A" t_ctx g_x))
    )
)

procedure(_AsPointList(l_data t_ctx "lt")  ; -> list[Point]
    ; 归一化点列：接受 Point/(x y) 列表，或扁平数值列表。
    ;
    ; **参数**
    ;   l_data  (list) - 点列或扁平坐标
    ;   t_ctx   (str)  - 错误上下文
    ;
    ; **返回**
    ;   (list[Point]) - 归一化点列；格式不合法时 error
    let((l_res n_len n_i)
        when(l_data
            unless(listp(l_data)
                error("%s: expected a point list, got %A" t_ctx l_data)
            )
            if(numberp(car(l_data))
                progn(
                    n_len = length(l_data)
                    unless(n_len - int(n_len / 2) * 2 == 0
                        error("%s: coordinate list must have an even length" t_ctx)
                    )
                    n_i = 1
                    while(n_i <= n_len
                        unless(numberp(_Nth1(n_i l_data))
                            && numberp(_Nth1(n_i + 1 l_data))
                            error("%s: coordinate list contains non-numbers" t_ctx)
                        )
                        l_res = tconc(l_res Point(
                            _Nth1(n_i l_data) _Nth1(n_i + 1 l_data)))
                        n_i = n_i + 2
                    )
                    car(l_res)
                )
                progn(
                    foreach(g_item l_data
                        l_res = tconc(l_res _AsPoint(g_item t_ctx))
                    )
                    car(l_res)
                )
            )
        )
    )
)

procedure(_TwoPoints(l_args t_ctx "lt")  ; -> list[Point]
    ; 归一化“两点”构造参数。
    ;
    ; **参数**
    ;   l_args  (list) - 构造实参
    ;   t_ctx   (str)  - 错误上下文
    ;
    ; **返回**
    ;   (list[Point]) - 两个点；格式不合法时 error
    let((l_data n_len)
        cond(
            (length(l_args) == 2
                list(_AsPoint(_Nth1(1 l_args) t_ctx)
                    _AsPoint(_Nth1(2 l_args) t_ctx)))
            (length(l_args) == 4
                unless(numberp(_Nth1(1 l_args)) && numberp(_Nth1(2 l_args))
                    && numberp(_Nth1(3 l_args)) && numberp(_Nth1(4 l_args))
                    error("%s: four coordinates must be numbers" t_ctx)
                )
                list(Point(_Nth1(1 l_args) _Nth1(2 l_args))
                    Point(_Nth1(3 l_args) _Nth1(4 l_args)))
            )
            (length(l_args) == 1
                l_data = _Nth1(1 l_args)
                unless(listp(l_data)
                    error("%s: expected two points or four coordinates" t_ctx)
                )
                n_len = length(l_data)
                cond(
                    ((n_len == 2 && !numberp(car(l_data)))
                        list(_AsPoint(car(l_data) t_ctx)
                            _AsPoint(cadr(l_data) t_ctx)))
                    ((n_len == 4 && numberp(car(l_data)))
                        unless(numberp(cadr(l_data))
                            && numberp(_Nth1(3 l_data))
                            && numberp(_Nth1(4 l_data))
                            error("%s: four coordinates must be numbers" t_ctx)
                        )
                        list(Point(car(l_data) cadr(l_data))
                            Point(_Nth1(3 l_data) _Nth1(4 l_data)))
                    )
                    (t error("%s: expected two points or four coordinates" t_ctx))
                )
            )
            (t error("%s: expected two points or four coordinates" t_ctx))
        )
    )
)

procedure(_AsPolygonList(l_data t_ctx "lt")  ; -> list[Polygon]
    ; 归一化多边形列表：接受 Polygon 或点列。
    ;
    ; **参数**
    ;   l_data  (list) - Polygon 列表或点列列表
    ;   t_ctx   (str)  - 错误上下文
    ;
    ; **返回**
    ;   (list[Polygon]) - 归一化多边形列表；格式不合法时 error
    let((l_res)
        when(l_data
            unless(listp(l_data)
                error("%s: expected a Polygon list, got %A" t_ctx l_data)
            )
            foreach(g_item l_data
                if(_PolygonP(g_item)
                    l_res = tconc(l_res g_item)
                    progn(
                        unless(listp(g_item)
                            error("%s: expected a Polygon or point list, got %A"
                                t_ctx g_item)
                        )
                        l_res = tconc(l_res Polygon(g_item))
                    )
                )
            )
            car(l_res)
        )
    )
)

procedure(_AsSegment(g_x t_ctx "gt")  ; -> Segment
    ; 校验并返回 Segment。
    ;
    ; **参数**
    ;   g_x    (any) - 待校验对象
    ;   t_ctx  (str) - 错误上下文
    ;
    ; **返回**
    ;   (Segment) - 原对象；非 Segment 时 error
    unless(_SegmentP(g_x)
        error("%s: expected a Segment, got %A" t_ctx g_x)
    )
    g_x
)

procedure(_AsLine(g_x t_ctx "gt")  ; -> Line
    ; 校验并返回 Line。
    ;
    ; **参数**
    ;   g_x    (any) - 待校验对象
    ;   t_ctx  (str) - 错误上下文
    ;
    ; **返回**
    ;   (Line) - 原对象；非 Line 时 error
    unless(_LineP(g_x)
        error("%s: expected a Line, got %A" t_ctx g_x)
    )
    g_x
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
    cond(
        (_RegionP(g_x) g_x)
        (_PolygonP(g_x) Region(list(g_x) ?normalize nil))
        (_RectP(g_x)
            let((g_poly)
                g_poly = _RectPolygon(g_x)
                if(g_poly
                    Region(list(g_poly) ?normalize nil)
                    Region(nil)
                )
            )
        )
        (listp(g_x) Region(list(Polygon(g_x)) ?normalize nil))
        (t error("%s: expected a Region, Polygon, Rect, or point list, got %A"
            t_ctx g_x))
    )
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

procedure(_PtKey(g_p "g")  ; -> str
    ; 生成点坐标的稳定键。
    ;
    ; **参数**
    ;   g_p  (Point) - 点
    ;
    ; **返回**
    ;   (str) - x 与 y 的字面量键
    lsprintf("%A|%A" g_p->x() g_p->y())
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

procedure(_SignedArea(l_pts "l")  ; -> float
    ; 计算点列的有符号面积（shoelace）。
    ;
    ; **参数**
    ;   l_pts  (list[Point]) - 闭合点列（不重复首点）
    ;
    ; **返回**
    ;   (float) - 有符号面积
    let((n_len n_sum n_i g_a g_b)
        n_len = length(l_pts)
        n_sum = 0.0
        for(n_i 1 n_len
            g_a = _Nth1(n_i l_pts)
            g_b = _Nth1(if(n_i == n_len 1 (n_i + 1)) l_pts)
            n_sum = n_sum + g_a->x() * g_b->y() - g_b->x() * g_a->y()
        )
        n_sum / 2.0
    )
)

procedure(_PointInRing(l_pts g_p n_eps "lgg")  ; -> t | nil
    ; 奇偶规则判断点是否在环内；边界行为由调用方处理。
    ;
    ; **参数**
    ;   l_pts  (list[Point]) - 闭合点列
    ;   g_p    (Point)       - 待判断点
    ;   n_eps  (float)       - 容差
    ;
    ; **返回**
    ;   (t|nil) - 在环内为 t
    let((n_len n_x n_y n_i g_a g_b g_in n_xint)
        n_len = length(l_pts)
        n_x = g_p->x()
        n_y = g_p->y()
        for(n_i 1 n_len
            g_a = _Nth1(n_i l_pts)
            g_b = _Nth1(if(n_i == n_len 1 (n_i + 1)) l_pts)
            when((g_a->y() > n_y) != (g_b->y() > n_y)
                n_xint = g_a->x()
                    + (n_y - g_a->y()) * (g_b->x() - g_a->x())
                        / (g_b->y() - g_a->y())
                when(n_x < n_xint
                    g_in = !g_in
                )
            )
        )
        g_in
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
    let((n_dx n_dy n_apx n_apy n_cross n_dot n_len2)
        n_dx = g_b->x() - g_a->x()
        n_dy = g_b->y() - g_a->y()
        n_apx = g_p->x() - g_a->x()
        n_apy = g_p->y() - g_a->y()
        n_cross = n_dx * n_apy - n_dy * n_apx
        n_dot = n_dx * n_apx + n_dy * n_apy
        n_len2 = n_dx * n_dx + n_dy * n_dy
        if(n_len2 <= n_eps * n_eps
            abs(n_apx) <= n_eps && abs(n_apy) <= n_eps
            abs(n_cross) <= n_eps
                && n_dot >= -n_eps
                && n_dot <= n_len2 + n_eps
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
    let((n_o1 n_o2 n_o3 n_o4)
        n_o1 = _Orient(g_a g_b g_c)
        n_o2 = _Orient(g_a g_b g_d)
        n_o3 = _Orient(g_c g_d g_a)
        n_o4 = _Orient(g_c g_d g_b)
        if(((n_o1 > n_eps && n_o2 < -n_eps) || (n_o1 < -n_eps && n_o2 > n_eps))
            && ((n_o3 > n_eps && n_o4 < -n_eps) || (n_o3 < -n_eps && n_o4 > n_eps))
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
    let((n_len n_changed t_seams l_res n_i g_prev g_cur g_next n_dot)
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
                cond(
                    (t_seams[_EdgeKey(g_prev g_cur)] == 2
                        || t_seams[_EdgeKey(g_cur g_next)] == 2
                        l_res = tconc(l_res g_cur)
                    )
                    ((abs(_Cross(g_prev g_cur g_next)) <= n_eps
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
                if(_PtKey(g_next) == _PtKey(g_start)
                    progn(
                        l_res = tconc(l_res car(l_ring))
                        g_cur = nil
                        l_ring = nil
                    )
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
