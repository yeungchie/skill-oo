useNamespace("ycGeom")

procedure(_PolyMid(g_a g_b "gg")  ; -> Point
    ; 返回两点中点。
    ;
    ; **参数**
    ;   g_a  (Point) - 点一
    ;   g_b  (Point) - 点二
    ;
    ; **返回**
    ;   (Point) - 中点
    Point(list((g_a->x() + g_b->x()) / 2.0
        (g_a->y() + g_b->y()) / 2.0))
)

procedure(_PolyLineDist(g_p g_q n_ux n_uy "ggnn")  ; -> float
    ; 返回到过 g_p 方向 (ux,uy) 的直线的垂距。
    ;
    ; **参数**
    ;   g_p   (Point) - 直线上一点
    ;   g_q   (Point) - 查询点
    ;   n_ux  (float) - 方向 x
    ;   n_uy  (float) - 方向 y
    ;
    ; **返回**
    ;   (float) - 垂距
    abs((g_q->x() - g_p->x()) * n_uy
        - (g_q->y() - g_p->y()) * n_ux)
)

procedure(_PolyToPathVerify(g_poly g_path n_eps "ggg")  ; -> t | nil
    ; 校验 Path 描边区域与原 Polygon 是否重合。
    ;
    ; **参数**
    ;   g_poly  (Polygon) - 原多边形
    ;   g_path  (Path)    - 候选路径
    ;   n_eps   (float)   - 容差
    ;
    ; **返回**
    ;   (t|nil) - 对称差面积在容差内为 t
    let((l_box n_w n_h n_tol l_res)
        l_box = g_poly->bBox()
        n_w = abs(car(cadr(l_box)) - car(car(l_box)))
        n_h = abs(cadr(cadr(l_box)) - cadr(car(l_box)))
        n_tol = max(1e-12 n_eps * max(n_w n_h) * 4.0)
        l_res = errset(g_poly->xor(g_path->toRegion() ?eps n_eps) nil)
        when(l_res
            car(l_res)->area() <= n_tol
        )
    )
)

procedure(_PolyToPathRect(g_poly l_ring n_eps g_horiz "glng")  ; -> Path | nil
    ; 尝试把矩形环还原为 2 点开放 Path。
    ;
    ; **参数**
    ;   g_poly   (Polygon)     - 原多边形
    ;   l_ring   (list[Point]) - 单环点列
    ;   n_eps    (float)       - 容差
    ;   g_horiz  (t|nil)       - t 选水平方向，nil 选垂直方向
    ;
    ; **返回**
    ;   (Path|nil) - 成功路径；非矩形 nil
    let((l_pts n_len g_ok g_p0 g_p1 g_p2 g_p3
            n_x0 n_y0 n_x1 n_y1 n_x2 n_y2
            n_l0 n_l1 n_l2 n_l3 n_a0 n_a1 g_use0
            n_width g_m1 g_m2 g_path)
        l_pts = _CollinearClean(l_ring n_eps)
        n_len = length(l_pts)
        g_ok = (n_len == 4)
        when(g_ok
            g_p0 = _Nth1(1 l_pts)
            g_p1 = _Nth1(2 l_pts)
            g_p2 = _Nth1(3 l_pts)
            g_p3 = _Nth1(4 l_pts)
            n_x0 = g_p1->x() - g_p0->x()
            n_y0 = g_p1->y() - g_p0->y()
            n_x1 = g_p2->x() - g_p1->x()
            n_y1 = g_p2->y() - g_p1->y()
            n_x2 = g_p3->x() - g_p2->x()
            n_y2 = g_p3->y() - g_p2->y()
            n_l0 = sqrt(n_x0 * n_x0 + n_y0 * n_y0)
            n_l1 = sqrt(n_x1 * n_x1 + n_y1 * n_y1)
            n_l2 = sqrt(n_x2 * n_x2 + n_y2 * n_y2)
            n_l3 = sqrt((g_p0->x() - g_p3->x()) * (g_p0->x() - g_p3->x())
                + (g_p0->y() - g_p3->y()) * (g_p0->y() - g_p3->y()))
            when(n_l0 <= n_eps || n_l1 <= n_eps || n_l2 <= n_eps || n_l3 <= n_eps
                g_ok = nil
            )
            when(g_ok && !(_Near(n_l0 n_l2 n_eps) && _Near(n_l1 n_l3 n_eps))
                g_ok = nil
            )
            when(g_ok && abs(n_x0 * n_x1 + n_y0 * n_y1) > n_eps * n_l0 * n_l1
                g_ok = nil
            )
            when(g_ok && abs(n_x0 * n_y2 - n_y0 * n_x2) > n_eps * n_l0 * n_l2
                g_ok = nil
            )
            when(g_ok
                n_a0 = abs(n_y0) / n_l0
                n_a1 = abs(n_y1) / n_l1
                g_use0 = if(g_horiz
                    if(abs(n_a0 - n_a1) <= 1e-12
                        n_l0 >= n_l1
                        n_a0 < n_a1)
                    if(abs(n_a0 - n_a1) <= 1e-12
                        nil
                        n_a0 > n_a1)
                )
                if(g_use0
                then
                    g_m1 = _PolyMid(g_p1 g_p2)
                    g_m2 = _PolyMid(g_p3 g_p0)
                    n_width = n_l1
                else
                    g_m1 = _PolyMid(g_p0 g_p1)
                    g_m2 = _PolyMid(g_p2 g_p3)
                    n_width = n_l0
                )
                g_path = Path(list(g_m1 g_m2) ?width n_width)
                unless(_PolyToPathVerify(g_poly g_path n_eps)
                    g_path = nil
                )
            )
        )
        g_path
    )
)

procedure(_PolyToPathOpenAt(g_poly l_ring l_edges n_w n_eps "gllng")  ; -> Path | nil
    ; 在给定候选宽度下尝试还原开放等宽折线。
    ;
    ; **参数**
    ;   g_poly   (Polygon)     - 原多边形
    ;   l_ring   (list[Point]) - 边界环
    ;   l_edges  (list)        - 边记录 (a b ux uy len)
    ;   n_w      (float)       - 候选宽度
    ;   n_eps    (float)       - 容差
    ;
    ; **返回**
    ;   (Path|nil) - 成功路径
    let((n_len n_len0 t_pair l_free n_i n_j l_ei l_ej g_ai g_bi g_aj g_bj
            n_uix n_uiy n_ujx n_ujy n_leni n_dot n_dist
            n_t1 n_t2 n_lo n_hi n_ov n_best n_score
            n_cap1 n_cap2 n_cur g_done n_key l_seen l_order
            g_start g_end l_route l_lines g_m1 g_m2 g_x g_path)
        n_len0 = length(l_edges)
        t_pair = makeTable("geomToPathPair" nil)
        for(n_i 1 n_len0
            l_ei = _Nth1(n_i l_edges)
            g_ai = car(l_ei)
            g_bi = cadr(l_ei)
            n_uix = caddr(l_ei)
            n_uiy = cadddr(l_ei)
            n_leni = nth(4 l_ei)
            n_best = nil
            n_score = nil
            for(n_j 1 n_len0
                when(n_j != n_i
                    l_ej = _Nth1(n_j l_edges)
                    g_aj = car(l_ej)
                    g_bj = cadr(l_ej)
                    n_ujx = caddr(l_ej)
                    n_ujy = cadddr(l_ej)
                    n_dot = n_uix * n_ujx + n_uiy * n_ujy
                    when(n_dot < -1.0 + 1e-9
                        n_dist = _PolyLineDist(g_ai g_aj n_uix n_uiy)
                        when(_Near(n_dist n_w n_eps)
                            n_t1 = (g_aj->x() - g_ai->x()) * n_uix
                                + (g_aj->y() - g_ai->y()) * n_uiy
                            n_t2 = (g_bj->x() - g_ai->x()) * n_uix
                                + (g_bj->y() - g_ai->y()) * n_uiy
                            n_lo = min(n_t1 n_t2)
                            n_hi = max(n_t1 n_t2)
                            n_ov = min(n_hi n_leni) - max(n_lo 0.0)
                            when(n_ov > n_eps
                                && (n_score == nil || n_ov > n_score)
                                n_best = n_j
                                n_score = n_ov
                            )
                        )
                    )
                )
            )
            when(n_best
                t_pair[n_i] = n_best
            )
        )
        g_done = t
        for(n_i 1 n_len0
            when(t_pair[n_i]
                unless(t_pair[t_pair[n_i]] == n_i
                    g_done = nil
                )
            )
        )
        unless(g_done nil)
        l_free = nil
        for(n_i 1 n_len0
            unless(t_pair[n_i]
                l_free = tconc(l_free n_i)
            )
        )
        l_free = car(l_free)
        unless(length(l_free) == 2 nil)
        n_cap1 = car(l_free)
        n_cap2 = cadr(l_free)
        l_ei = _Nth1(n_cap1 l_edges)
        g_start = _PolyMid(car(l_ei) cadr(l_ei))
        l_ej = _Nth1(n_cap2 l_edges)
        g_end = _PolyMid(car(l_ej) cadr(l_ej))
        n_cur = n_cap1
        g_done = nil
        for(n_i 1 n_len0
            unless(g_done
                n_cur = n_cur + 1
                when(n_cur > n_len0 n_cur = 1)
                if(n_cur == n_cap2
                then
                    g_done = t
                else
                    when(t_pair[n_cur]
                        n_key = min(n_cur t_pair[n_cur])
                        unless(member(n_key l_seen)
                            l_seen = tconc(l_seen n_key)
                            l_order = tconc(l_order n_key)
                        )
                    )
                )
            )
        )
        l_order = car(l_order)
        unless(l_order nil)
        l_lines = nil
        foreach(n_key l_order
            n_i = n_key
            n_j = t_pair[n_i]
            l_ei = _Nth1(n_i l_edges)
            l_ej = _Nth1(n_j l_edges)
            g_m1 = _PolyMid(car(l_ei) car(l_ej))
            g_m2 = _PolyMid(cadr(l_ei) cadr(l_ej))
            l_lines = tconc(l_lines list(
                _PolyMid(g_m1 g_m2)
                caddr(l_ei)
                cadddr(l_ei)))
        )
        l_lines = car(l_lines)
        l_route = tconc(nil g_start)
        for(n_i 1 length(l_lines) - 1
            l_ei = _Nth1(n_i l_lines)
            l_ej = _Nth1((n_i + 1) l_lines)
            g_x = _SizeLinePoint(car(l_ei)
                list(cadr(l_ei) caddr(l_ei))
                car(l_ej)
                list(cadr(l_ej) caddr(l_ej)))
            unless(g_x nil)
            l_route = tconc(l_route g_x)
        )
        l_route = tconc(l_route g_end)
        g_path = Path(car(l_route) ?width n_w)
        when(_PolyToPathVerify(g_poly g_path n_eps) g_path)
    )
)

procedure(_PolyToPathOpen(g_poly l_ring n_eps "glg")  ; -> Path | nil
    ; 尝试把开放等宽折线环还原为 Path。
    ;
    ; **参数**
    ;   g_poly  (Polygon)     - 原多边形
    ;   l_ring  (list[Point]) - 单环点列
    ;   n_eps   (float)       - 容差
    ;
    ; **返回**
    ;   (Path|nil) - 唯一成功路径；无或多候选 nil
    let((l_pts l_edges n_len n_i n_j l_ei l_ej n_uxi n_uyi n_uxj n_uyj
            n_dot n_dist l_cands l_new g_found l_ok g_path)
        l_pts = _CollinearClean(l_ring n_eps)
        n_len = length(l_pts)
        unless(n_len >= 4 nil)
        for(n_i 1 n_len
            l_ei = list(_Nth1(n_i l_pts)
                _Nth1(if(n_i == n_len 1 (n_i + 1)) l_pts))
            n_uxi = cadr(l_ei)->x() - car(l_ei)->x()
            n_uyi = cadr(l_ei)->y() - car(l_ei)->y()
            n_dist = sqrt(n_uxi * n_uxi + n_uyi * n_uyi)
            unless(n_dist <= n_eps
                l_edges = tconc(l_edges list(car(l_ei) cadr(l_ei)
                    n_uxi / n_dist n_uyi / n_dist n_dist))
            )
        )
        l_edges = car(l_edges)
        n_len = length(l_edges)
        unless(n_len >= 4 nil)
        for(n_i 1 n_len
            l_ei = _Nth1(n_i l_edges)
            n_uxi = caddr(l_ei)
            n_uyi = cadddr(l_ei)
            for(n_j (n_i + 1) n_len
                l_ej = _Nth1(n_j l_edges)
                n_uxj = caddr(l_ej)
                n_uyj = cadddr(l_ej)
                n_dot = n_uxi * n_uxj + n_uyi * n_uyj
                when(n_dot < -1.0 + 1e-9
                    n_dist = _PolyLineDist(car(l_ei) car(l_ej)
                        n_uxi n_uyi)
                    when(n_dist > n_eps
                        g_found = nil
                        l_new = nil
                        foreach(l_co l_cands
                            if(_Near(car(l_co) n_dist n_eps)
                            then
                                g_found = t
                                l_new = tconc(l_new list(car(l_co)
                                    cadr(l_co) + 1))
                            else
                                l_new = tconc(l_new l_co)
                            )
                        )
                        l_new = car(l_new)
                        unless(g_found
                            l_new = append(l_new list(list(n_dist 1)))
                        )
                        l_cands = l_new
                    )
                )
            )
        )
        l_cands = l_cands
        l_ok = nil
        foreach(l_co l_cands
            g_path = _PolyToPathOpenAt(g_poly l_pts l_edges
                car(l_co) n_eps)
            when(g_path
                l_ok = tconc(l_ok g_path)
            )
        )
        l_ok = car(l_ok)
        when(l_ok && length(l_ok) == 1
            car(l_ok)
        )
    )
)

procedure(_PolyToPathRing(g_poly l_outer l_inner n_eps "gllg")  ; -> Path | nil
    ; 尝试把闭合等距环还原为 Path。
    ;
    ; **参数**
    ;   g_poly   (Polygon)     - 原多边形
    ;   l_outer  (list[Point]) - 外环
    ;   l_inner  (list[Point]) - 内环
    ;   n_eps    (float)       - 容差
    ;
    ; **返回**
    ;   (Path|nil) - 成功路径；非等距环 nil
    let((l_out l_in l_in_use n_len n_i n_j n_off n_ori
            g_oa g_ob g_ia g_ib n_uxo n_uyo n_uxi n_uyi
            n_lo n_li n_cross n_width l_mid g_ok g_path)
        l_out = _CollinearClean(l_outer n_eps)
        l_in = _CollinearClean(l_inner n_eps)
        n_len = length(l_out)
        unless(n_len == length(l_in) && n_len >= 3 nil)
        g_path = nil
        for(n_ori 0 1
            unless(g_path
                l_in_use = if(n_ori == 0 l_in reverse(l_in))
                for(n_off 0 n_len - 1
                    unless(g_path
                        n_width = nil
                        l_mid = nil
                        g_ok = t
                        for(n_i 1 n_len
                            n_j = n_off + n_i
                            while(n_j > n_len
                                n_j = n_j - n_len
                            )
                            g_oa = _Nth1(n_i l_out)
                            g_ob = _Nth1(if(n_i == n_len 1 (n_i + 1)) l_out)
                            g_ia = _Nth1(n_j l_in_use)
                            g_ib = _Nth1(if(n_j == n_len 1 (n_j + 1)) l_in_use)
                            n_uxo = g_ob->x() - g_oa->x()
                            n_uyo = g_ob->y() - g_oa->y()
                            n_uxi = g_ib->x() - g_ia->x()
                            n_uyi = g_ib->y() - g_ia->y()
                            n_lo = sqrt(n_uxo * n_uxo + n_uyo * n_uyo)
                            n_li = sqrt(n_uxi * n_uxi + n_uyi * n_uyi)
                            when(n_lo <= n_eps || n_li <= n_eps
                                g_ok = nil
                            )
                            when(g_ok
                                n_cross = (n_uxo * n_uyi - n_uyo * n_uxi)
                                    / (n_lo * n_li)
                                when(abs(n_cross) > 1e-6
                                    g_ok = nil
                                )
                            )
                            when(g_ok
                                n_cross = _PolyLineDist(g_oa g_ia
                                    n_uxo / n_lo n_uyo / n_lo)
                                if(n_width == nil
                                then
                                    n_width = n_cross
                                else
                                    unless(_Near(n_width n_cross n_eps)
                                        g_ok = nil
                                    )
                                )
                            )
                            when(g_ok
                                l_mid = tconc(l_mid _PolyMid(g_oa g_ia))
                            )
                        )
                        when(g_ok && n_width > n_eps
                            l_mid = car(l_mid)
                            l_mid = append(l_mid list(car(l_mid)))
                            g_path = Path(l_mid ?width n_width)
                            unless(_PolyToPathVerify(g_poly g_path n_eps)
                                g_path = nil
                            )
                        )
                    )
                )
            )
        )
        g_path
    )
)

inScheme(
procedure(_InstallPolygonToPath(self "g")  ; -> t
    ; 把 Polygon->toPath 方法安装到 Polygon 类。
    ;
    ; **参数**
    ;   self  (Polygon) - 目标实例
    ;
    ; **返回**
    ;   (t) - 安装完成
    self->toPath = lambda((\@key (orient 'horizontal) (eps nil) "gg")  ; -> Path | nil
        ; 尝试把多边形逆推为等宽描边路径。
        ;
        ; **参数**
        ;   ?orient  (sym)     - horizontal/h 或 vertical/v；默认 horizontal
        ;   ?eps     (num|nil) - 容差；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (Path|nil) - 描边区域与原多边形重合的路径；无法还原 nil
        let((n_eps g_horiz l_rings g_path)
            n_eps = _Eps(eps)
            cond(
                ((orient == 'horizontal || orient == 'h)
                    g_horiz = t)
                ((orient == 'vertical || orient == 'v)
                    g_horiz = nil)
                (t
                    error("ycGeom::Polygon->toPath: ?orient must be horizontal, vertical, h, or v, got %A"
                        orient)
                )
            )
            l_rings = _Rings(self->_data->points)
            cond(
                ((length(l_rings) == 1)
                    g_path = _PolyToPathRect(self car(l_rings)
                        n_eps g_horiz)
                    unless(g_path
                        g_path = _PolyToPathOpen(self car(l_rings) n_eps)
                    )
                )
                ((length(l_rings) == 2)
                    g_path = _PolyToPathRing(self car(l_rings)
                        cadr(l_rings) n_eps)
                )
            )
            g_path
        )
    )
    t
)
)

unuseNamespace("ycGeom")

; END
