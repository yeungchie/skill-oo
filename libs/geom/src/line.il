useNamespace("ycGeom")

defclass(_LineData () (
    ; _LineData 数据桶：收纳规范化直线方程 a/b/c，构造后禁写。
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
    ; 状态桶（_LineData：a + b + c），构造后禁写
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
procedure(_InstallLine(self "g")  ; -> t
    ; 把 Line 方法安装到 Line 类（由 initializeInstance 调用）。
    ;
    ; **返回**
    ;   (t) - 安装完成；调用方忽略
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
        Point(list(-self->_data->a * self->_data->c
            -self->_data->b * self->_data->c))
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
        let((p d)
            p = _AsPoint(g_point "ycGeom::Line->project")
            d = self->_data->a * p->x()
                + self->_data->b * p->y() + self->_data->c
            Point(list(p->x() - d * self->_data->a
                p->y() - d * self->_data->b))
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
        let((p)
            p = _AsPoint(g_point "ycGeom::Line->distanceTo")
            abs(self->_data->a * p->x()
                + self->_data->b * p->y() + self->_data->c)
        )
    )
    self->contains = lambda((g_point \@key (eps nil) "gg")  ; -> t | nil
        ; 判断点是否在直线上。
        ;
        ; **参数**
        ;   g_point  (Point)   - 查询点
        ;   ?eps     (num|nil) - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (t|nil) - 在直线上为 t
        let((p eps2)
            p = _AsPoint(g_point "ycGeom::Line->contains")
            eps2 = _Eps(eps)
            abs(self->_data->a * p->x()
                + self->_data->b * p->y() + self->_data->c) <= eps2
        )
    )
    self->isParallel = lambda((g_line \@key (eps nil) "gg")  ; -> t | nil
        ; 判断两直线是否平行。
        ;
        ; **参数**
        ;   g_line  (Line|list) - 另一条直线或两点数组
        ;   ?eps    (num|nil)   - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (t|nil) - 平行或重合为 t
        let((eps2 det o)
            o = _AsLine(g_line "ycGeom::Line->isParallel")
            eps2 = _Eps(eps)
            det = self->_data->a * o->b()
                - self->_data->b * o->a()
            abs(det) <= eps2
        )
    )
    self->intersection = lambda((g_other \@key (eps nil) (as nil) "ggg")  ; -> Point | Segment | nil
        ; 计算与 Line 或 Segment 的交点。
        ;
        ; **参数**
        ;   g_other  (Line|Segment|list) - 另一对象或两点数组
        ;   ?eps     (num|nil)           - 容差；默认 nil（1e-9）
        ;   ?as      (sym|nil)           - 数组目标类型 'Line/'Segment；默认 nil
        ;
        ; **返回**
        ;   (Point|Segment|nil) - 唯一交点、重叠线段或无交
        let((eps2 o det x y)
            eps2 = _Eps(eps)
            o = _AsLineOrSegment(g_other as "ycGeom::Line->intersection")
            cond(
                (_LineP(o)
                    det = self->_data->a * o->b()
                        - self->_data->b * o->a()
                    unless(abs(det) <= eps2
                        x = (self->_data->b * o->c()
                            - o->b() * self->_data->c) / det
                        y = (self->_data->c * o->a()
                            - o->c() * self->_data->a) / det
                        Point(list(x y))
                    )
                )
                (_SegmentP(o)
                    _LineSegmentIntersection(self o eps2))
                (t
                    error("ycGeom::Line->intersection: expected a Line or Segment, got %A"
                        o))
            )
        )
    )
    self->toSkill = lambda(()  ; -> list[list[float]]
        ; 转换为 anchor + 单位方向的两个点。
        ;
        ; **返回**
        ;   (list[list[float]]) - ((ax ay) (bx by))
        let((a2 d)
            a2 = self->anchor()
            d = self->direction()
            list(a2->toSkill()
                Point(list(a2->x() + car(d) a2->y() + cadr(d)))->toSkill())
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

procedure(Line(l_data "l")  ; -> Line
    ; 构造不可变无限直线。
    ;
    ; **参数**
    ;   l_data  (list) - 两点列表、包一层的两点列表或 Point 列表
    ;
    ; **返回**
    ;   (Line) - 规范化 a*x+b*y+c=0；重合点或格式不合法 error
    let((pts p1 p2 a2 b2 c2 norm)
        pts = _TwoPoints(l_data "ycGeom::Line")
        p1 = _Nth1(1 pts)
        p2 = _Nth1(2 pts)
        when(p1->equals(p2 ?eps _Eps(nil))
            error("ycGeom::Line: construction points must differ")
        )
        a2 = p2->y() - p1->y()
        b2 = p1->x() - p2->x()
        c2 = -(a2 * p1->x() + b2 * p1->y())
        norm = sqrt(a2 * a2 + b2 * b2)
        makeInstance('Line ?_data
            makeInstance('_LineData
                ?a a2 / norm
                ?b b2 / norm
                ?c c2 / norm))
    )
)

unuseNamespace("ycGeom")

; END
