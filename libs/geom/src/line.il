useNamespace("ycGeom")

defclass(LineData () (
    ; LineData 数据桶：收纳规范化直线方程 a/b/c，构造后禁写。
    a(
        \@initarg a
        \@initform 0.0
    )
    b(
        \@initarg b
        \@initform 0.0
    )
    c(
        \@initarg c
        \@initform 0.0
    )
))

defclass(Line () (
    ; Line 实例：不可变无限直线。
    ; 状态桶（LineData：a + b + c），构造后禁写
    _data(
        \@initarg _data
        \@initform nil
    )

    a()
    b()
    c()
    anchor()
    direction()
    normal()
    project()
    distanceTo()
    contains()
    isParallel()
    intersection()
    toSkill()
))

defmethod(printself (self(Line))  ; -> str
    ; 返回 Line 的打印描述串。
    ;
    ; **返回**
    ;   (str) - <ycGeom::Line a=... b=... c=...>
    lsprintf("<%A a=%A b=%A c=%A>" className(self)
        self->_data->a self->_data->b self->_data->c)
)

inScheme(
procedure(_InstallLine(self "g")  ; -> any
    ; 把 Line 方法安装到 Line 类（由 initializeInstance 调用）。
    ;
    ; **返回**
    ;   (any) - 最后一条安装赋值结果，调用方忽略
    self->a = lambda(()  ; -> float
        ; 返回方程系数 a。
        ;
        ; **返回**
        ;   (float) - a
        self->_data->a
    )
    self->b = lambda(()  ; -> float
        ; 返回方程系数 b。
        ;
        ; **返回**
        ;   (float) - b
        self->_data->b
    )
    self->c = lambda(()  ; -> float
        ; 返回方程系数 c。
        ;
        ; **返回**
        ;   (float) - c
        self->_data->c
    )
    self->anchor = lambda(()  ; -> Point
        ; 返回直线上离原点最近的点。
        ;
        ; **返回**
        ;   (Point) - anchor
        Point(-self->_data->a * self->_data->c
            -self->_data->b * self->_data->c)
    )
    self->direction = lambda(()  ; -> list[float]
        ; 返回单位方向向量。
        ;
        ; **返回**
        ;   (list[float]) - (-b a)
        list(-self->_data->b self->_data->a)
    )
    self->normal = lambda(()  ; -> list[float]
        ; 返回单位法向量。
        ;
        ; **返回**
        ;   (list[float]) - (a b)
        list(self->_data->a self->_data->b)
    )
    self->project = lambda((g_point "g")  ; -> Point
        ; 返回到直线的投影点。
        ;
        ; **参数**
        ;   g_point  (Point) - 待投影点
        ;
        ; **返回**
        ;   (Point) - 投影点
        let((g_p n_d)
            g_p = _AsPoint(g_point "ycGeom::Line->project")
            n_d = self->_data->a * g_p->x()
                + self->_data->b * g_p->y() + self->_data->c
            Point(g_p->x() - n_d * self->_data->a
                g_p->y() - n_d * self->_data->b)
        )
    )
    self->distanceTo = lambda((g_point "g")  ; -> float
        ; 返回到直线的距离。
        ;
        ; **参数**
        ;   g_point  (Point) - 查询点
        ;
        ; **返回**
        ;   (float) - 距离
        let((g_p)
            g_p = _AsPoint(g_point "ycGeom::Line->distanceTo")
            abs(self->_data->a * g_p->x()
                + self->_data->b * g_p->y() + self->_data->c)
        )
    )
    self->contains = lambda((g_point \@key (eps nil) "gg")  ; -> t | nil
        ; 判断点是否在直线上。
        ;
        ; **参数**
        ;   g_point  (Point)   - 查询点
        ;   ?eps     (num|nil) - 容差
        ;
        ; **返回**
        ;   (t|nil) - 在直线上为 t
        let((g_p n_eps)
            g_p = _AsPoint(g_point "ycGeom::Line->contains")
            n_eps = _Eps(eps)
            abs(self->_data->a * g_p->x()
                + self->_data->b * g_p->y() + self->_data->c) <= n_eps
        )
    )
    self->isParallel = lambda((g_line \@key (eps nil) "gg")  ; -> t | nil
        ; 判断两直线是否平行。
        ;
        ; **参数**
        ;   g_line  (Line)     - 另一条直线
        ;   ?eps    (num|nil)  - 容差
        ;
        ; **返回**
        ;   (t|nil) - 平行或重合为 t
        let((n_eps n_det)
            unless(_LineP(g_line)
                error("ycGeom::Line->isParallel: expected a Line, got %A" g_line)
            )
            n_eps = _Eps(eps)
            n_det = self->_data->a * g_line->b()
                - self->_data->b * g_line->a()
            abs(n_det) <= n_eps
        )
    )
    self->intersection = lambda((g_other \@key (eps nil) "gg")  ; -> Point | Segment | nil
        ; 计算与 Line 或 Segment 的交点。
        ;
        ; **参数**
        ;   g_other  (Line|Segment) - 另一对象
        ;   ?eps     (num|nil)      - 容差
        ;
        ; **返回**
        ;   (Point|Segment|nil) - 唯一交点、重叠线段或无交
        let((n_eps n_det n_x n_y)
            n_eps = _Eps(eps)
            cond(
                (_LineP(g_other)
                    n_det = self->_data->a * g_other->b()
                        - self->_data->b * g_other->a()
                    if(abs(n_det) <= n_eps
                        nil
                        progn(
                            n_x = (self->_data->b * g_other->c()
                                - g_other->b() * self->_data->c) / n_det
                            n_y = (self->_data->c * g_other->a()
                                - g_other->c() * self->_data->a) / n_det
                            Point(n_x n_y)
                        )
                    )
                )
                (_SegmentP(g_other)
                    _LineSegmentIntersection(self g_other n_eps))
                (t
                    error("ycGeom::Line->intersection: expected a Line or Segment, got %A"
                        g_other))
            )
        )
    )
    self->toSkill = lambda(()  ; -> list[list[float]]
        ; 转换为 anchor + 单位方向的两个点。
        ;
        ; **返回**
        ;   (list[list[float]]) - ((ax ay) (bx by))
        let((g_a g_d)
            g_a = self->anchor()
            g_d = self->direction()
            list(g_a->toSkill()
                Point(g_a->x() + car(g_d) g_a->y() + cadr(g_d))->toSkill())
        )
    )
    t
)
)

inScheme(
defmethod(initializeInstance (self(Line) \@rest _args)
    ; 构造 Line 实例时安装方法集。
    ;
    ; **参数**
    ;   _args  (list) - 附加初始化参数，本实现忽略
    ;
    ; **返回**
    ;   (t) - 安装完成
    _InstallLine(self)
    t
)
)

procedure(Line(\@rest l_args "g")  ; -> Line
    ; 构造不可变无限直线。
    ;
    ; **参数**
    ;   l_args  (list) - 两个点、两点列表、四个坐标，或点列
    ;
    ; **返回**
    ;   (Line) - 规范化 a*x+b*y+c=0；重合点或格式不合法 error
    let((l_pts g_p1 g_p2 n_a n_b n_c n_norm)
        l_pts = _TwoPoints(l_args "ycGeom::Line")
        g_p1 = _Nth1(1 l_pts)
        g_p2 = _Nth1(2 l_pts)
        when(g_p1->equals(g_p2 ?eps 1e-9)
            error("ycGeom::Line: construction points must differ")
        )
        n_a = g_p2->y() - g_p1->y()
        n_b = g_p1->x() - g_p2->x()
        n_c = -(n_a * g_p1->x() + n_b * g_p1->y())
        n_norm = sqrt(n_a * n_a + n_b * n_b)
        makeInstance('Line ?_data
            makeInstance('LineData
                ?a n_a / n_norm
                ?b n_b / n_norm
                ?c n_c / n_norm))
    )
)

unuseNamespace("ycGeom")

; END
