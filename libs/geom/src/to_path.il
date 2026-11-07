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

procedure(_PolyToPathVerify(g_poly g_path n_eps "ggn")  ; -> t | nil
    ; 校验 Path 描边区域与原 Polygon 是否重合。
    ;
    ; **参数**
    ;   g_poly  (Polygon) - 原多边形
    ;   g_path  (Path)    - 候选路径
    ;   n_eps   (float)   - 容差
    ;
    ; **返回**
    ;   (t|nil) - 对称差面积在容差内为 t
    let((box w h2 tol res)
        box = g_poly->bBox()
        w = abs(car(cadr(box)) - car(car(box)))
        h2 = abs(cadr(cadr(box)) - cadr(car(box)))
        tol = max(1e-12 n_eps * max(w h2) * 4.0)
        res = errset(g_poly->xor(g_path->toRegion() ?eps n_eps) nil)
        when(res
            car(res)->area() <= tol
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
    let((pts len ok p0 p1 p2 p3
            x0 y0 x1 y1 x2 y2
            l0 l1 l2 l3 a0 a1 use0
            width m1 m2 path)
        pts = _CollinearClean(l_ring n_eps)
        len = length(pts)
        ok = (len == 4)
        when(ok
            p0 = _Nth1(1 pts)
            p1 = _Nth1(2 pts)
            p2 = _Nth1(3 pts)
            p3 = _Nth1(4 pts)
            x0 = p1->x() - p0->x()
            y0 = p1->y() - p0->y()
            x1 = p2->x() - p1->x()
            y1 = p2->y() - p1->y()
            x2 = p3->x() - p2->x()
            y2 = p3->y() - p2->y()
            l0 = sqrt(x0 * x0 + y0 * y0)
            l1 = sqrt(x1 * x1 + y1 * y1)
            l2 = sqrt(x2 * x2 + y2 * y2)
            l3 = sqrt((p0->x() - p3->x()) * (p0->x() - p3->x())
                + (p0->y() - p3->y()) * (p0->y() - p3->y()))
            when(l0 <= n_eps || l1 <= n_eps || l2 <= n_eps || l3 <= n_eps
                ok = nil
            )
            when(ok && !(_Near(l0 l2 n_eps) && _Near(l1 l3 n_eps))
                ok = nil
            )
            when(ok && abs(x0 * x1 + y0 * y1) > n_eps * l0 * l1
                ok = nil
            )
            when(ok && abs(x0 * y2 - y0 * x2) > n_eps * l0 * l2
                ok = nil
            )
            when(ok
                a0 = abs(y0) / l0
                a1 = abs(y1) / l1
                use0 = if(g_horiz
                    if(abs(a0 - a1) <= 1e-12
                        l0 >= l1
                        a0 < a1)
                    if(abs(a0 - a1) <= 1e-12
                        l0 >= l1
                        a0 > a1)
                )
                if(use0
                then
                    m1 = _PolyMid(p1 p2)
                    m2 = _PolyMid(p3 p0)
                    width = l1
                else
                    m1 = _PolyMid(p0 p1)
                    m2 = _PolyMid(p2 p3)
                    width = l0
                )
                path = Path(list(m1 m2) ?width width)
                unless(_PolyToPathVerify(g_poly path n_eps)
                    path = nil
                )
            )
        )
        path
    )
)

procedure(_PolyToPathOpenAt(g_poly l_ring l_edges n_w n_eps "gllnn")  ; -> Path | nil
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
    ;   (Path|nil) - 成功路径；无法配对 nil
    prog((len len0 pair free i j ei ej ai bi aj bj
            uix uiy ujx ujy leni dot dist
            t1 t2 lo hi ov best score
            cap1 cap2 cur done key seen order
            start end route lines m1 m2 x path)
        len0 = length(l_edges)
        pair = makeTable("geomToPathPair" nil)
        for(i2 1 len0
            ei = _Nth1(i2 l_edges)
            ai = car(ei)
            bi = cadr(ei)
            uix = caddr(ei)
            uiy = cadddr(ei)
            leni = nth(4 ei)
            best = nil
            score = nil
            for(j2 1 len0
                when(j2 != i2
                    ej = _Nth1(j2 l_edges)
                    aj = car(ej)
                    bj = cadr(ej)
                    ujx = caddr(ej)
                    ujy = cadddr(ej)
                    dot = uix * ujx + uiy * ujy
                    when(dot < -1.0 + 1e-9
                        dist = _PolyLineDist(ai aj uix uiy)
                        when(_Near(dist n_w n_eps)
                            t1 = (aj->x() - ai->x()) * uix
                                + (aj->y() - ai->y()) * uiy
                            t2 = (bj->x() - ai->x()) * uix
                                + (bj->y() - ai->y()) * uiy
                            lo = min(t1 t2)
                            hi = max(t1 t2)
                            ov = min(hi leni) - max(lo 0.0)
                            when(ov > n_eps
                                && (score == nil || ov > score)
                                best = j2
                                score = ov
                            )
                        )
                    )
                )
            )
            when(best
                pair[i2] = best
            )
        )
        done = t
        for(i2 1 len0
            when(pair[i2]
                unless(pair[pair[i2]] == i2
                    done = nil
                )
            )
        )
        unless(done
            return(nil)
        )
        free = nil
        for(i2 1 len0
            unless(pair[i2]
                free = tconc(free i2)
            )
        )
        free = car(free)
        unless(length(free) == 2
            return(nil)
        )
        cap1 = car(free)
        cap2 = cadr(free)
        ei = _Nth1(cap1 l_edges)
        start = _PolyMid(car(ei) cadr(ei))
        ej = _Nth1(cap2 l_edges)
        end = _PolyMid(car(ej) cadr(ej))
        cur = cap1
        done = nil
        for(i2 1 len0
            unless(done
                cur = cur + 1
                when(cur > len0 cur = 1)
                if(cur == cap2
                then
                    done = t
                else
                    when(pair[cur]
                        key = min(cur pair[cur])
                        unless(member(key seen)
                            seen = tconc(seen key)
                            order = tconc(order key)
                        )
                    )
                )
            )
        )
        order = car(order)
        unless(order
            return(nil)
        )
        lines = nil
        foreach(key2 order
            i = key2
            j = pair[i]
            ei = _Nth1(i l_edges)
            ej = _Nth1(j l_edges)
            m1 = _PolyMid(car(ei) car(ej))
            m2 = _PolyMid(cadr(ei) cadr(ej))
            lines = tconc(lines list(
                _PolyMid(m1 m2)
                caddr(ei)
                cadddr(ei)))
        )
        lines = car(lines)
        route = tconc(nil start)
        for(i2 1 length(lines) - 1
            ei = _Nth1(i2 lines)
            ej = _Nth1((i2 + 1) lines)
            x = _SizeLinePoint(car(ei)
                list(cadr(ei) caddr(ei))
                car(ej)
                list(cadr(ej) caddr(ej)))
            unless(x
                return(nil)
            )
            route = tconc(route x)
        )
        route = tconc(route end)
        path = Path(car(route) ?width n_w)
        when(_PolyToPathVerify(g_poly path n_eps)
            return(path)
        )
        return(nil)
    )
)

procedure(_PolyToPathOpen(g_poly l_ring n_eps "gln")  ; -> Path | nil
    ; 尝试把开放等宽折线环还原为 Path。
    ;
    ; **参数**
    ;   g_poly  (Polygon)     - 原多边形
    ;   l_ring  (list[Point]) - 单环点列
    ;   n_eps   (float)       - 容差
    ;
    ; **返回**
    ;   (Path|nil) - 唯一成功路径；无或多候选 nil
    prog((pts edges len i j ei ej uxi uyi uxj uyj
            dot dist cands new found ok path)
        pts = _CollinearClean(l_ring n_eps)
        len = length(pts)
        unless(len >= 4
            return(nil)
        )
        for(i2 1 len
            ei = list(_Nth1(i2 pts)
                _Nth1(if(i2 == len 1 (i2 + 1)) pts))
            uxi = cadr(ei)->x() - car(ei)->x()
            uyi = cadr(ei)->y() - car(ei)->y()
            dist = sqrt(uxi * uxi + uyi * uyi)
            unless(dist <= n_eps
                edges = tconc(edges list(car(ei) cadr(ei)
                    uxi / dist uyi / dist dist))
            )
        )
        edges = car(edges)
        len = length(edges)
        unless(len >= 4
            return(nil)
        )
        for(i2 1 len
            ei = _Nth1(i2 edges)
            uxi = caddr(ei)
            uyi = cadddr(ei)
            for(j2 (i2 + 1) len
                ej = _Nth1(j2 edges)
                uxj = caddr(ej)
                uyj = cadddr(ej)
                dot = uxi * uxj + uyi * uyj
                when(dot < -1.0 + 1e-9
                    dist = _PolyLineDist(car(ei) car(ej)
                        uxi uyi)
                    when(dist > n_eps
                        found = nil
                        new = nil
                        foreach(co cands
                            if(_Near(car(co) dist n_eps)
                            then
                                found = t
                                new = tconc(new list(car(co)
                                    cadr(co) + 1))
                            else
                                new = tconc(new co)
                            )
                        )
                        new = car(new)
                        unless(found
                            new = append(new list(list(dist 1)))
                        )
                        cands = new
                    )
                )
            )
        )
        cands = cands
        ok = nil
        foreach(co cands
            path = _PolyToPathOpenAt(g_poly pts edges
                car(co) n_eps)
            when(path
                ok = tconc(ok path)
            )
        )
        ok = car(ok)
        when(ok && length(ok) == 1
            return(car(ok))
        )
        return(nil)
    )
)

procedure(_PolyToPathRing(g_poly l_outer l_inner n_eps "glln")  ; -> Path | nil
    ; 尝试把闭合等距环还原为 Path。
    ;
    ; **参数**
    ;   g_poly   (Polygon)     - 原多边形
    ;   l_outer  (list[Point]) - 外环
    ;   l_inner  (list[Point]) - 内环
    ;   n_eps    (float)       - 容差
    ;
    ; **返回**
    ;   (Path|nil) - 成功路径；两环点数不等或非等宽环 nil
    prog((out in in_use len i j off ori
            oa ob ia ib uxo uyo uxi uyi
            lo li cross width mid ok path)
        out = _CollinearClean(l_outer n_eps)
        in = _CollinearClean(l_inner n_eps)
        len = length(out)
        unless(len == length(in) && len >= 3
            return(nil)
        )
        path = nil
        for(ori2 0 1
            unless(path
                in_use = if(ori2 == 0 in reverse(in))
                for(off2 0 len - 1
                    unless(path
                        width = nil
                        mid = nil
                        ok = t
                        for(i2 1 len
                            j = off2 + i2
                            while(j > len
                                j = j - len
                            )
                            oa = _Nth1(i2 out)
                            ob = _Nth1(if(i2 == len 1 (i2 + 1)) out)
                            ia = _Nth1(j in_use)
                            ib = _Nth1(if(j == len 1 (j + 1)) in_use)
                            uxo = ob->x() - oa->x()
                            uyo = ob->y() - oa->y()
                            uxi = ib->x() - ia->x()
                            uyi = ib->y() - ia->y()
                            lo = sqrt(uxo * uxo + uyo * uyo)
                            li = sqrt(uxi * uxi + uyi * uyi)
                            when(lo <= n_eps || li <= n_eps
                                ok = nil
                            )
                            when(ok
                                cross = (uxo * uyi - uyo * uxi)
                                    / (lo * li)
                                when(abs(cross) > 1e-6
                                    ok = nil
                                )
                            )
                            when(ok
                                cross = _PolyLineDist(oa ia
                                    uxo / lo uyo / lo)
                                if(width == nil
                                then
                                    width = cross
                                else
                                    unless(_Near(width cross n_eps)
                                        ok = nil
                                    )
                                )
                            )
                            when(ok
                                mid = tconc(mid _PolyMid(oa ia))
                            )
                        )
                        when(ok && width > n_eps
                            mid = car(mid)
                            mid = append(mid list(car(mid)))
                            path = Path(mid ?width width)
                            unless(_PolyToPathVerify(g_poly path n_eps)
                                path = nil
                            )
                        )
                    )
                )
            )
        )
        return(path)
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
        ;   ?eps     (num|nil) - 容差下限，实际比较值随坐标量级放大；默认 nil（1e-9）
        ;
        ; **返回**
        ;   (Path|nil) - 描边区域与原多边形重合的路径；无法还原 nil
        let((eps2 horiz rings path mag)
            eps2 = _Eps(eps)
            ; 逆推宽度由坐标差得出，绝对误差随坐标量级增长（≈ ulp(坐标)）；
            ; 与 _CanonRing 的 _canonScale 一致地把容差下限抬到量级相关值，
            ; 否则大偏移处两次垂距测量之差的符号会翻转，配对失败返回 nil。
            ; 量级取 toSkill() 的全体坐标（含内环点），覆盖整张图；
            ; 只放大有量纲的距离判据，单位向量点积与叉积符号等无量纲判据不动。
            mag = 0.0
            foreach(p self->toSkill()
                mag = max(mag abs(car(p)) abs(cadr(p)))
            )
            eps2 = max(eps2 1e-15 * mag)
            cond(
                ((orient == 'horizontal || orient == 'h)
                    horiz = t)
                ((orient == 'vertical || orient == 'v)
                    horiz = nil)
                (t
                    error("ycGeom::Polygon->toPath: ?orient must be horizontal, vertical, h, or v, got %A"
                        orient)
                )
            )
            rings = _Rings(self->_data->points)
            cond(
                ((length(rings) == 1)
                    path = _PolyToPathRect(self car(rings)
                        eps2 horiz)
                    unless(path
                        path = _PolyToPathOpen(self car(rings) eps2)
                    )
                )
                ((length(rings) == 2)
                    path = _PolyToPathRing(self car(rings)
                        cadr(rings) eps2)
                )
            )
            path
        )
    )
    t
)
)

unuseNamespace("ycGeom")

; END
