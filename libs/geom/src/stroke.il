useNamespace("ycGeom")

procedure(_StrokePolygon(l_pts "l")  ; -> Polygon | nil
    ; 用点列构造有效多边形；退化时返回 nil。
    ;
    ; **参数**
    ;   l_pts  (list[Point]) - 候选点列
    ;
    ; **返回**
    ;   (Polygon|nil) - 非退化多边形；少于 3 点或零面积 nil
    when(l_pts && length(l_pts) >= 3
        && abs(_SignedArea(l_pts)) > _AreaTol(l_pts _Eps(nil))
        Polygon(l_pts)
    )
)

procedure(_StrokeBand(g_a g_b n_half "ggn")  ; -> Polygon | nil
    ; 生成一条线段的矩形带。
    ;
    ; **参数**
    ;   g_a     (Point) - 线段起点
    ;   g_b     (Point) - 线段终点
    ;   n_half  (float) - 半宽
    ;
    ; **返回**
    ;   (Polygon|nil) - 矩形带；零长度 nil
    let((dx dy len ux uy nx ny)
        dx = g_b->x() - g_a->x()
        dy = g_b->y() - g_a->y()
        len = sqrt(dx * dx + dy * dy)
        unless(len <= _Eps(nil)
            ux = dx / len
            uy = dy / len
            nx = -uy
            ny = ux
            _StrokePolygon(list(
                Point(list(g_a->x() + nx * n_half g_a->y() + ny * n_half))
                Point(list(g_b->x() + nx * n_half g_b->y() + ny * n_half))
                Point(list(g_b->x() - nx * n_half g_b->y() - ny * n_half))
                Point(list(g_a->x() - nx * n_half g_a->y() - ny * n_half))
            ))
        )
    )
)

procedure(_StrokeCircle(g_c n_rad n_segments "gnx")  ; -> Polygon
    ; 生成离散圆盘。
    ;
    ; **参数**
    ;   g_c         (Point) - 圆心
    ;   n_rad       (float) - 半径
    ;   n_segments  (int)   - 每 90 度段数
    ;
    ; **返回**
    ;   (Polygon) - 4 * n_segments 边形
    let((count i ang acc)
        count = 4 * n_segments
        for(i2 0 count - 1
            ang = 2.0 * 3.141592653589793 * i2 / count
            acc = tconc(acc Point(list(
                g_c->x() + n_rad * cos(ang)
                g_c->y() + n_rad * sin(ang)
            )))
        )
        Polygon(car(acc))
    )
)

procedure(_StrokeJoin(g_prev g_v g_next n_half g_join n_limit n_segments "gggngnx")  ; -> Polygon | nil
    ; 生成拐角帽。
    ;
    ; **参数**
    ;   g_prev      (Point) - 前一顶点
    ;   g_v         (Point) - 当前顶点
    ;   g_next      (Point) - 后一顶点
    ;   n_half      (float) - 半宽
    ;   g_join      (sym)   - miter/round/bevel
    ;   n_limit     (float) - miter 限制
    ;   n_segments  (int)   - 每 90 度圆角段数
    ;
    ; **返回**
    ;   (Polygon|nil) - 拐角帽；直线穿过或反向折返 nil
    let((dx1 dy1 len1 ux uy dx2 dy2 len2 vx vy
            cross nx1 ny1 nx2 ny2 v1 v2 m)
        dx1 = g_v->x() - g_prev->x()
        dy1 = g_v->y() - g_prev->y()
        len1 = sqrt(dx1 * dx1 + dy1 * dy1)
        dx2 = g_next->x() - g_v->x()
        dy2 = g_next->y() - g_v->y()
        len2 = sqrt(dx2 * dx2 + dy2 * dy2)
        unless(len1 <= _Eps(nil) || len2 <= _Eps(nil)
            ux = dx1 / len1
            uy = dy1 / len1
            vx = dx2 / len2
            vy = dy2 / len2
            cross = ux * vy - uy * vx
            unless(abs(cross) <= _AngleTol()
                if(cross > 0.0
                then
                    nx1 = uy
                    ny1 = -ux
                    nx2 = vy
                    ny2 = -vx
                else
                    nx1 = -uy
                    ny1 = ux
                    nx2 = -vy
                    ny2 = vx
                )
                v1 = Point(list(g_v->x() + nx1 * n_half
                    g_v->y() + ny1 * n_half))
                v2 = Point(list(g_v->x() + nx2 * n_half
                    g_v->y() + ny2 * n_half))
                cond(
                    (g_join == 'round
                        _StrokeCircle(g_v n_half n_segments))
                    (g_join == 'bevel
                        _StrokePolygon(list(v1 g_v v2)))
                    (g_join == 'miter
                        m = _SizeLinePoint(v1 list(ux uy)
                            v2 list(vx vy))
                        if(m && g_v->distanceTo(m)
                                <= n_limit * n_half
                        then
                            _StrokePolygon(list(v1 m v2 g_v))
                        else
                            _StrokePolygon(list(v1 g_v v2))
                        )
                    )
                )
            )
        )
    )
)

procedure(_StrokeCap(g_p g_dir n_half g_cap n_segments "ggngx")  ; -> Polygon | nil
    ; 生成开放端点的端帽。
    ;
    ; **参数**
    ;   g_p         (Point) - 端点
    ;   g_dir       (Point) - 外向单位方向（用 Point 承载 x/y）
    ;   n_half      (float) - 半宽
    ;   g_cap       (sym)   - butt/square/round
    ;   n_segments  (int)   - 每 90 度圆角段数
    ;
    ; **返回**
    ;   (Polygon|nil) - 端帽；butt 为 nil
    let((ux uy nx ny)
        ux = g_dir->x()
        uy = g_dir->y()
        nx = -uy
        ny = ux
        cond(
            (g_cap == 'butt nil)
            (g_cap == 'round
                _StrokeCircle(g_p n_half n_segments))
            (g_cap == 'square
                _StrokePolygon(list(
                    Point(list(g_p->x() + nx * n_half
                        g_p->y() + ny * n_half))
                    Point(list(g_p->x() - nx * n_half
                        g_p->y() - ny * n_half))
                    Point(list(g_p->x() + ux * n_half - nx * n_half
                        g_p->y() + uy * n_half - ny * n_half))
                    Point(list(g_p->x() + ux * n_half + nx * n_half
                        g_p->y() + uy * n_half + ny * n_half))
                ))
            )
        )
    )
)

unuseNamespace("ycGeom")

; END
