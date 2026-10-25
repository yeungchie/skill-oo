useNamespace("ycGeom")

defclass(PointData () (
    ; PointData 数据桶：收纳 Point 的 x/y 坐标，构造后禁写。
    x(
        \@initarg x
        \@initform 0.0
    )
    y(
        \@initarg y
        \@initform 0.0
    )
))

defclass(Point () (
    ; Point 实例：不可变平面点。
    ; 状态桶（PointData：x + y），构造后禁写
    _data(
        \@initarg _data
        \@initform nil
    )

    x()
    y()
    distanceTo()
    midpoint()
    translate()
    equals()
    toSkill()
))

defmethod(printself (self(Point))  ; -> str
    ; 返回 Point 的打印描述串。
    ;
    ; **返回**
    ;   (str) - <ycGeom::Point x=... y=...>
    lsprintf("<%A x=%A y=%A>" className(self) self->_data->x self->_data->y)
)

inScheme(
procedure(_InstallPoint(self "g")  ; -> any
    ; 把 Point 方法安装到 Point 类（由 initializeInstance 调用）。
    ;
    ; **返回**
    ;   (any) - 最后一条安装赋值结果，调用方忽略
    self->x = lambda(()  ; -> float
        ; 返回 x 坐标。
        ;
        ; **返回**
        ;   (float) - x 坐标
        self->_data->x
    )
    self->y = lambda(()  ; -> float
        ; 返回 y 坐标。
        ;
        ; **返回**
        ;   (float) - y 坐标
        self->_data->y
    )
    self->distanceTo = lambda((g_other "g")  ; -> float
        ; 返回与另一点的距离。
        ;
        ; **参数**
        ;   g_other  (Point) - 另一点
        ;
        ; **返回**
        ;   (float) - 欧氏距离
        let((g_o n_dx n_dy)
            g_o = _AsPoint(g_other "ycGeom::Point->distanceTo")
            n_dx = g_o->x() - self->_data->x
            n_dy = g_o->y() - self->_data->y
            sqrt(n_dx * n_dx + n_dy * n_dy)
        )
    )
    self->midpoint = lambda((g_other "g")  ; -> Point
        ; 返回与另一点的中点。
        ;
        ; **参数**
        ;   g_other  (Point) - 另一点
        ;
        ; **返回**
        ;   (Point) - 中点
        let((g_o)
            g_o = _AsPoint(g_other "ycGeom::Point->midpoint")
            Point((self->_data->x + g_o->x()) / 2.0
                (self->_data->y + g_o->y()) / 2.0)
        )
    )
    self->translate = lambda((n_dx n_dy "nn")  ; -> Point
        ; 返回平移后的点。
        ;
        ; **参数**
        ;   n_dx  (num) - x 位移
        ;   n_dy  (num) - y 位移
        ;
        ; **返回**
        ;   (Point) - 新点
        Point(self->_data->x + float(n_dx)
            self->_data->y + float(n_dy))
    )
    self->equals = lambda((g_other \@key (eps nil) "gg")  ; -> t | nil
        ; 判断与另一点是否在容差内相等。
        ;
        ; **参数**
        ;   g_other  (Point)   - 另一点
        ;   ?eps     (num|nil) - 容差，默认 nil（1e-9）
        ;
        ; **返回**
        ;   (t|nil) - 坐标均在容差内为 t
        let((g_o n_eps)
            g_o = _AsPoint(g_other "ycGeom::Point->equals")
            n_eps = _Eps(eps)
            _Near(self->_data->x g_o->x() n_eps)
                && _Near(self->_data->y g_o->y() n_eps)
        )
    )
    self->toSkill = lambda(()  ; -> list[float]
        ; 转换为 SKILL 原生坐标列表。
        ;
        ; **返回**
        ;   (list[float]) - (x y)
        list(self->_data->x self->_data->y)
    )
    t
)
)

inScheme(
defmethod(initializeInstance (self(Point) \@rest _args)
    ; 构造 Point 实例时安装方法集。
    ;
    ; **参数**
    ;   _args  (list) - 附加初始化参数，本实现忽略
    ;
    ; **返回**
    ;   (t) - 安装完成
    _InstallPoint(self)
    t
)
)

procedure(Point(\@rest l_args "g")  ; -> Point
    ; 构造不可变平面点。
    ;
    ; **参数**
    ;   l_args  (list) - (x y) 或两个数值实参
    ;
    ; **返回**
    ;   (Point) - 坐标已转 flonum 的新点；格式不合法 error
    let((n_x n_y g_pair)
        cond(
            (length(l_args) == 2
                n_x = _Nth1(1 l_args)
                n_y = _Nth1(2 l_args)
                unless(numberp(n_x) && numberp(n_y)
                    error("ycGeom::Point: coordinates must be numbers, got %A"
                        l_args)
                )
            )
            (length(l_args) == 1
                g_pair = _Nth1(1 l_args)
                unless(_PairP(g_pair)
                    error("ycGeom::Point: expected (x y) or two numbers, got %A"
                        g_pair)
                )
                n_x = car(g_pair)
                n_y = cadr(g_pair)
            )
            (t
                error("ycGeom::Point: expected (x y) or two numbers, got %A"
                    l_args)
            )
        )
        makeInstance('Point ?_data
            makeInstance('PointData ?x float(n_x) ?y float(n_y)))
    )
)

unuseNamespace("ycGeom")

; END
