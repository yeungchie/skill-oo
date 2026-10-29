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
    let((n_dx n_dy n_len n_ux n_uy n_nx n_ny)
        n_dx = g_b->x() - g_a->x()
        n_dy = g_b->y() - g_a->y()
        n_len = sqrt(n_dx * n_dx + n_dy * n_dy)
        unless(n_len <= _Eps(nil)
            n_ux = n_dx / n_len
            n_uy = n_dy / n_len
            n_nx = -n_uy
            n_ny = n_ux
            _StrokePolygon(list(
                Point(list(g_a->x() + n_nx * n_half g_a->y() + n_ny * n_half))
                Point(list(g_b->x() + n_nx * n_half g_b->y() + n_ny * n_half))
                Point(list(g_b->x() - n_nx * n_half g_b->y() - n_ny * n_half))
                Point(list(g_a->x() - n_nx * n_half g_a->y() - n_ny * n_half))
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
    let((n_count n_i n_ang l_acc)
        n_count = 4 * n_segments
        for(n_i 0 n_count - 1
            n_ang = 2.0 * 3.141592653589793 * n_i / n_count
            l_acc = tconc(l_acc Point(list(
                g_c->x() + n_rad * cos(n_ang)
                g_c->y() + n_rad * sin(n_ang)
            )))
        )
        Polygon(car(l_acc))
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
    let((n_dx1 n_dy1 n_len1 n_ux n_uy n_dx2 n_dy2 n_len2 n_vx n_vy
            n_cross n_nx1 n_ny1 n_nx2 n_ny2 g_v1 g_v2 g_m)
        n_dx1 = g_v->x() - g_prev->x()
        n_dy1 = g_v->y() - g_prev->y()
        n_len1 = sqrt(n_dx1 * n_dx1 + n_dy1 * n_dy1)
        n_dx2 = g_next->x() - g_v->x()
        n_dy2 = g_next->y() - g_v->y()
        n_len2 = sqrt(n_dx2 * n_dx2 + n_dy2 * n_dy2)
        unless(n_len1 <= _Eps(nil) || n_len2 <= _Eps(nil)
            n_ux = n_dx1 / n_len1
            n_uy = n_dy1 / n_len1
            n_vx = n_dx2 / n_len2
            n_vy = n_dy2 / n_len2
            n_cross = n_ux * n_vy - n_uy * n_vx
            unless(abs(n_cross) <= _AngleTol()
                if(n_cross > 0.0
                then
                    n_nx1 = n_uy
                    n_ny1 = -n_ux
                    n_nx2 = n_vy
                    n_ny2 = -n_vx
                else
                    n_nx1 = -n_uy
                    n_ny1 = n_ux
                    n_nx2 = -n_vy
                    n_ny2 = n_vx
                )
                g_v1 = Point(list(g_v->x() + n_nx1 * n_half
                    g_v->y() + n_ny1 * n_half))
                g_v2 = Point(list(g_v->x() + n_nx2 * n_half
                    g_v->y() + n_ny2 * n_half))
                cond(
                    (g_join == 'round
                        _StrokeCircle(g_v n_half n_segments))
                    (g_join == 'bevel
                        _StrokePolygon(list(g_v1 g_v g_v2)))
                    (g_join == 'miter
                        g_m = _SizeLinePoint(g_v1 list(n_ux n_uy)
                            g_v2 list(n_vx n_vy))
                        if(g_m && g_v->distanceTo(g_m)
                                <= n_limit * n_half
                        then
                            _StrokePolygon(list(g_v1 g_m g_v2 g_v))
                        else
                            _StrokePolygon(list(g_v1 g_v g_v2))
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
    let((n_ux n_uy n_nx n_ny)
        n_ux = g_dir->x()
        n_uy = g_dir->y()
        n_nx = -n_uy
        n_ny = n_ux
        cond(
            (g_cap == 'butt nil)
            (g_cap == 'round
                _StrokeCircle(g_p n_half n_segments))
            (g_cap == 'square
                _StrokePolygon(list(
                    Point(list(g_p->x() + n_nx * n_half
                        g_p->y() + n_ny * n_half))
                    Point(list(g_p->x() - n_nx * n_half
                        g_p->y() - n_ny * n_half))
                    Point(list(g_p->x() + n_ux * n_half - n_nx * n_half
                        g_p->y() + n_uy * n_half - n_ny * n_half))
                    Point(list(g_p->x() + n_ux * n_half + n_nx * n_half
                        g_p->y() + n_uy * n_half + n_ny * n_half))
                ))
            )
        )
    )
)

unuseNamespace("ycGeom")

; END
